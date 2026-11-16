extends Node
## The movable goods of one Warehouse Worker game (Phase 5, 5 Nov 2026; simplified 14 Nov 2026;
## guide: docs/guides/WAREHOUSE.md#minigame-14-nov-2026). Built into the minigame copy when a game
## starts and freed with it; nothing here touches the town warehouse.
##
##  - Goods (user, 14 Nov 2026: basic spatial words): five boxes of one size (word *cardboard
##    box*), red, green, blue, yellow and a plain cardboard one. The green box stands in the
##    wall bay as the reference for "beside" and "to the right of"; the others start on the
##    floor, the table and the shelf of the left section. Each is a RigidBody3D whose rotation
##    is locked except about the vertical axis, so it slides and turns but never tumbles.
##    Walking into one nudges it. E (a click, a tap) on one within reach picks it up; it floats
##    in front of the player, a faint ghost shows where it will land, and E puts it down there
##    (or in front of the player when the aim is not a surface).
##  - The wall bay (one, on the west wall of the left section): a painted floor rectangle. A
##    thing in the bay has a front (away from the wall) and left / right as seen by the player
##    standing in front of it, facing it and the wall (`side_axis()`).
##  - The supply cabinet's doors swing open and shut with E (interaction only, not a task).
##  - A green marker that "points out" a place or a thing (hints, wrong attempts).
##
## Physics bodies cannot sit under the town's 1.3 scale, so they live under `bodies`, a
## top-level node in world space; everything else (the bay, markers) is built in hall-local
## units under the copy's `Session` node. Positions in the queries below are hall-local
## (warehouse.gd's coordinates: +x west, +z north); `to_world` / `to_hall` convert.
const Warehouse := preload("res://scripts/world/warehouse.gd")
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const Interactable := preload("res://scripts/core/interactable.gd")

## Reach for picking up and opening, in hall units (horizontal), and how far away a put-down
## may be aimed.
const REACH := 3.3
## A put-down may be aimed (clicked) this far away: the thing goes exactly where clicked
## (user, 8 Nov 2026: "on that specific spot as opposed to right in front of me").
const PLACE_REACH := 10.0
## Where carried goods float: ahead of and above the player's feet, in hall units; high
## enough to show above the player's head from the camera behind.
## (plus half the carried thing's depth, so big goods float clear of the pig).
const CARRY_AHEAD := .65
const CARRY_HEIGHT := 1.75
const CABINET_OPEN := deg_to_rad(100.0)

## Floor spots for goods in the left section, clear of the table, the shelf, the cabinet, the
## bay and its sides, Ramón and the way in through the divider's opening.
const FLOOR_SPOTS := [Vector2(5.0, 1.7), Vector2(7.3, 1.7), Vector2(9.6, 1.7), Vector2(11.9, 1.7), Vector2(7.2, 10.4), Vector2(11.4, 10.4)]
## The wall bay: [centre, outward direction] in hall x/z, painted on the floor from the wall
## out (user, 5 Nov 2026: a reference box stands by a wall, so "to the right of the green box"
## is not confusing). On the west wall of the left section, so facing it the player looks west.
const BAYS := [[Vector2(13.6, 6.6), Vector2(-1, 0)]]
const BAY_SIZE := Vector2(2.2, 1.9)
## Free height between the two shelf decks: taller goods never go on the bottom shelf.
const SHELF_CLEAR := .74
## Goods on one shelf level (three places: Warehouse.SHELF_SLOTS).
const SHELF_CAPACITY := 3
const WORK_TABLE := Warehouse.WORK_TABLE
const WORK_TABLE_SIZE := Warehouse.WORK_TABLE_SIZE
const TABLE_HEIGHT := Warehouse.TABLE_HEIGHT

## Goods (user, 14 Nov 2026). Item ids name their phrase: "box_<colour>" (warehouse_tasks.gd
## thing()), "box_plain" is the plain cardboard box. One size for all, in hall units (length ×
## height × depth; the pig is 1.71 tall, 1.10 wide); it fits three to a shelf level.
const BOX_COLORS := ["red", "blue", "yellow", "plain"]
## The reference box in the wall bay.
const REFERENCE := "box_green"
const BOX_SIZE := Vector3(.92, .66, .68)
## Weights in whole kilos, drawn per game (walking into a box pushes it by its weight).
const WEIGHTS := [6, 12]

var main
var copy_root: Node3D
var player: CharacterBody3D
var interaction
var rng: RandomNumberGenerator
var hall: Node3D
var bodies: Node3D
var scale_factor := 1.3
## This game's box ids.
var boxes: Array = []

## id -> RigidBody3D (meta: warehouse_item, size, weight).
var items := {}
var cabinet_open := false
var _cabinet_pivots: Array = []
var _cabinet_body: Node3D

var carried: RigidBody3D
var _ghost: MeshInstance3D
var _marker: MeshInstance3D
var _marker_material: StandardMaterial3D

signal item_picked(id: String)
signal item_put(id: String)

func setup(game, root: Node3D, explorer: CharacterBody3D, picking, random: RandomNumberGenerator) -> void:
	name = "Goods"
	main = game
	copy_root = root
	player = explorer
	interaction = picking
	rng = random
	process_physics_priority = 10
	scale_factor = copy_root.global_basis.get_scale().x
	hall = copy_root.get_node("Session")
	bodies = Node3D.new()
	bodies.name = "Bodies"
	bodies.top_level = true
	hall.add_child(bodies)
	bodies.global_transform = Transform3D.IDENTITY
	_marker_material = StandardMaterial3D.new()
	_marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker_material.albedo_color = Color(.3, .95, .45, .35)
	_marker_material.no_depth_test = true
	_hinge_cabinet()
	_arrange()

# --- Coordinates ---------------------------------------------------------------------------

func to_world(p: Vector3) -> Vector3:
	return copy_root.to_global(p)

func to_hall(p: Vector3) -> Vector3:
	return copy_root.to_local(p)

func _world_basis() -> Basis:
	return copy_root.global_basis.orthonormalized()

## An item's centre in hall units.
func center(id: String) -> Vector3:
	return to_hall(items[id].global_position)

## Half extents along the hall axes, for the thing as it is turned now (goods may turn about
## the vertical when pushed).
func half(id: String) -> Vector3:
	var size: Vector3 = items[id].get_meta("size") * .5
	if not is_instance_valid(copy_root):
		return size
	var b: Basis = _world_basis().inverse() * (items[id] as Node3D).global_basis.orthonormalized()
	return Vector3(
		absf(b.x.x) * size.x + absf(b.y.x) * size.y + absf(b.z.x) * size.z,
		absf(b.x.y) * size.x + absf(b.y.y) * size.y + absf(b.z.y) * size.z,
		absf(b.x.z) * size.x + absf(b.y.z) * size.y + absf(b.z.z) * size.z)

func bottom(id: String) -> float:
	return center(id).y - half(id).y

func top(id: String) -> float:
	return center(id).y + half(id).y

# --- Building ------------------------------------------------------------------------------

## A fresh random arrangement: the green box in the wall bay; the other four boxes in random
## places among the floor spots, the table (at most one) and the shelf (at most one per level),
## the cabinet open or shut.
func _arrange() -> void:
	for bay in BAYS:
		_paint_bay(bay)
	var weights: Array = range(WEIGHTS[0], WEIGHTS[1] + 1)
	weights.shuffle()
	for tint in [REFERENCE.trim_prefix("box_")] + BOX_COLORS:
		var id: String = "box_" + tint
		boxes.append(id)
		var paint: String = Warehouse.CARDBOARD if tint == "plain" else Warehouse.BOX_COLORS[tint]
		_item(id, BOX_SIZE, paint, "cardboard box", weights.pop_back())
	_place_in_bay(REFERENCE, 0)
	var spots: Array = FLOOR_SPOTS.duplicate()
	spots.shuffle()
	var order: Array = boxes.filter(func(id): return id != REFERENCE)
	order.shuffle()
	var places: Array = ["table", "shelf_0", "shelf_1", "floor", "floor", "floor"]
	places.shuffle()
	for i in order.size():
		var id: String = order[i]
		match str(places[i]):
			"table":
				place_at(id, Vector3(WORK_TABLE.x + rng.randf_range(-.8, .8), Warehouse.FLOOR + TABLE_HEIGHT + half(id).y + .02, WORK_TABLE.z))
			"shelf_0", "shelf_1":
				var level := int(str(places[i]).get_slice("_", 1))
				var slot: float = Warehouse.SHELF_SLOTS[rng.randi() % Warehouse.SHELF_SLOTS.size()]
				place_at(id, Vector3(Warehouse.SHELF_AT.x + slot, Warehouse.FLOOR + Warehouse.RACK_LEVELS[level] + .02 + half(id).y, Warehouse.SHELF_AT.z))
			_:
				var spot: Vector2 = spots.pop_back()
				place_at(id, Vector3(spot.x, Warehouse.FLOOR + half(id).y + .01, spot.y))
	if rng.randf() < .5:
		set_cabinet(true)

## Every thing's place is known here (the task planner's view, warehouse_plan.gd, says "no"
## for a thing whose place after a planned task cannot be predicted).
func known(_id: String) -> bool:
	return true

## Low enough for the gap between the two shelf decks.
func fits_shelf(id: String) -> bool:
	return float(items[id].get_meta("size").y) < SHELF_CLEAR

func _place_in_bay(id: String, bay: int) -> void:
	var at: Vector2 = BAYS[bay][0]
	place_at(id, Vector3(at.x, Warehouse.FLOOR + half(id).y + .01, at.y))

## A bay's outline, painted from the wall out past the reference spot.
func _paint_bay(bay: Array) -> void:
	var at: Vector2 = bay[0]
	var out: Vector2 = bay[1]
	var wall_gap := Warehouse.HW - Warehouse.T - absf(at.x) if out.x != 0 else 0.0
	var inner := at - out * wall_gap
	var outer := at + out * BAY_SIZE.y * .5
	var mid := (inner + outer) * .5
	var long := inner.distance_to(outer)
	var y := Warehouse.FLOOR + .004
	var size := Vector3(long, .006, BAY_SIZE.x) if out.x != 0 else Vector3(BAY_SIZE.x, .006, long)
	_visual_box(hall, "Bay floor", Vector3(mid.x, y - .001, mid.y), size, "c9cdd1")
	for side in [-1.0, 1.0]:
		var across: Vector2 = Vector2(out.y, out.x) * side * BAY_SIZE.x * .5
		var line_size := Vector3(long, .008, .08) if out.x != 0 else Vector3(.08, .008, long)
		_visual_box(hall, "Bay line", Vector3(mid.x + across.x, y, mid.y + across.y), line_size, "eef0f2")
	var front_size := Vector3(.08, .008, BAY_SIZE.x) if out.x != 0 else Vector3(BAY_SIZE.x, .008, .08)
	_visual_box(hall, "Bay line", Vector3(outer.x, y, outer.y), front_size, "eef0f2")

## The wall bay a reference stands in (-1 when none).
func bay_of(ref: String) -> int:
	if not items.has(ref):
		return -1
	var c := center(ref)
	for b in BAYS.size():
		if Vector2(c.x, c.z).distance_to(BAYS[b][0]) < .45 and on_floor(ref):
			return b
	return -1

func _visual_box(parent: Node3D, title: String, center_at: Vector3, size: Vector3, tint: String) -> Node3D:
	var node: Node3D = main.box(title, center_at, size, Color(tint), "", false)
	node.reparent(parent, false)
	return node

func _item(id: String, size: Vector3, tint: String, word: String, weight: int) -> void:
	var body := RigidBody3D.new()
	body.name = id
	body.set_meta("word_key", word)
	body.set_meta("warehouse_item", id)
	body.set_meta("size", size)
	body.set_meta("weight", weight)
	_interactable(body, Vector3(0, size.y * 0.5 + 0.25, 0))
	body.mass = maxf(weight, 1)
	body.axis_lock_angular_x = true
	body.axis_lock_angular_z = true
	body.linear_damp = 1.5
	body.angular_damp = 4.0
	var surface := PhysicsMaterial.new()
	surface.friction = .9
	body.physics_material_override = surface
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size * scale_factor
	shape_node.shape = shape
	body.add_child(shape_node)
	var look := Node3D.new()
	look.name = "Look"
	look.scale = Vector3.ONE * scale_factor
	body.add_child(look)
	_carton_look(look, size, tint)
	bodies.add_child(body)
	items[id] = body

## A cardboard carton (8 Nov 2026, user: "improve the looks of the boxes"): a slightly darker
## shell with lighter faces inset (so the edges read), the top flaps' seam and the ends of the
## flaps, tape over the seam and down both ends, a darker band along the bottom, a white
## shipping label with a barcode, hand holes and "this way up" arrows on the ends. All in the
## item's own units under its Look node, centred on the body.
func _carton_look(look: Node3D, size: Vector3, tint: String) -> void:
	var base := Color(tint)
	var edge := base.darkened(.22).to_html(false)
	var face := base.lightened(.04).to_html(false)
	var print_ink := base.darkened(.45).to_html(false)
	var tape := base.lightened(.45).to_html(false)
	var h := size * .5
	_visual_box(look, "Goods", Vector3.ZERO, size, edge)
	var inset := minf(.025, size.y * .08)
	var band := minf(size.y * .12, .06)
	for side in [-1.0, 1.0]:
		_visual_box(look, "Carton face", Vector3(0, band * .5, side * (h.z + .002)), Vector3(size.x - inset * 2, size.y - inset * 2 - band, .004), face)
		_visual_box(look, "Carton face", Vector3(side * (h.x + .002), band * .5, 0), Vector3(.004, size.y - inset * 2 - band, size.z - inset * 2), face)
	_visual_box(look, "Carton top", Vector3(0, h.y + .002, 0), Vector3(size.x - inset * 2, .004, size.z - inset * 2), face)
	var tape_w := clampf(size.z * .22, .06, .14)
	_visual_box(look, "Flap seam", Vector3(0, h.y + .005, 0), Vector3(size.x - inset * 2, .003, .012), edge)
	for side in [-1.0, 1.0]:
		_visual_box(look, "Flap edge", Vector3(side * (h.x - size.x * .18), h.y + .005, 0), Vector3(.01, .003, size.z - inset * 2), edge)
	_visual_box(look, "Packing tape", Vector3(0, h.y + .007, 0), Vector3(size.x + .01, .006, tape_w), tape)
	for side in [-1.0, 1.0]:
		_visual_box(look, "Packing tape", Vector3(side * (h.x + .005), h.y - size.y * .15, 0), Vector3(.006, size.y * .3, tape_w), tape)
	var label := Vector2(minf(size.x * .32, .3), minf(size.y * .34, .2))
	var at := Vector3(size.x * .2, size.y * .08, -h.z - .006)
	_visual_box(look, "Shipping label", at, Vector3(label.x, label.y, .004), "fbfaf5")
	for i in 3:
		_visual_box(look, "Label line", at + Vector3(-label.x * .1, label.y * (.28 - i * .2), -.003), Vector3(label.x * .65, label.y * .07, .002), "8a919a")
	_visual_box(look, "Barcode", at + Vector3(0, -label.y * .33, -.003), Vector3(label.x * .8, label.y * .16, .002), "2d3138")
	var arrow := minf(size.y * .22, .16)
	for side in [-1.0, 1.0]:
		var x: float = side * (h.x + .006)
		_visual_box(look, "Hand hole", Vector3(x, h.y * .3, 0), Vector3(.006, minf(size.y * .1, .07), size.z * .35), "3a2a1c")
		for offset in [-1.0, 1.0]:
			var z: float = offset * size.z * .2
			var y := -h.y * .35
			_visual_box(look, "Arrow stem", Vector3(x, y, z), Vector3(.004, arrow, arrow * .14), print_ink)
			for lean in [-1.0, 1.0]:
				var head := _visual_box(look, "Arrow head", Vector3(x, y + arrow * .36, z + lean * arrow * .12), Vector3(.004, arrow * .45, arrow * .14), print_ink)
				head.rotation.x = lean * deg_to_rad(40)

## Puts an item at a hall-local centre, at rest and turned like the hall.
func place_at(id: String, p: Vector3) -> void:
	var body: RigidBody3D = items[id]
	body.global_transform = Transform3D(_world_basis(), to_world(p))
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO

## The copy's cabinet doors (static parts of warehouse.gd supply_cabinet()) get hinge pivots
## on their outer edges so they can swing.
func _hinge_cabinet() -> void:
	_cabinet_body = copy_root.get_node_or_null("Hall/Supply cabinet") as Node3D
	if _cabinet_body == null:
		push_warning("warehouse_goods: no Hall/Supply cabinet in the copy")
		return
	_interactable(_cabinet_body, preload("res://scripts/ui/interact_badge.gd").local_center(_cabinet_body))
	var doors: Array = []
	var handles: Array = []
	for child in _cabinet_body.get_children():
		# "Cabinet door west/east" and "Cabinet handle west/east" (warehouse.gd).
		if str(child.name).contains("Cabinet door"):
			doors.append(child)
		elif str(child.name).contains("Cabinet handle"):
			handles.append(child)
	for door in doors:
		var side := signf((door as Node3D).position.x)
		var pivot := Node3D.new()
		pivot.name = "Cabinet hinge"
		pivot.position = Vector3(side * .88, 0, -.305)
		pivot.set_meta("side", side)
		_cabinet_body.add_child(pivot)
		door.reparent(pivot, true)
		for handle in handles:
			if signf((handle as Node3D).position.x) == side:
				handle.reparent(pivot, true)
		_cabinet_pivots.append(pivot)

func set_cabinet(open_it: bool) -> void:
	cabinet_open = open_it
	for pivot: Node3D in _cabinet_pivots:
		var tween := pivot.create_tween()
		tween.tween_property(pivot, "rotation:y", -float(pivot.get_meta("side")) * CABINET_OPEN if open_it else 0.0, .35)

# --- Where things are (hall-local tests) -----------------------------------------------------

func resting(id: String) -> bool:
	var body: RigidBody3D = items[id]
	return body != carried and body.linear_velocity.length() < .15 * scale_factor

func on_floor(id: String) -> bool:
	return bottom(id) < Warehouse.FLOOR + .08

## The shelf index (always 0: one shelf) and level an item stands on, or [] when it is not on
## the shelf.
func rack_spot(id: String) -> Array:
	var c := center(id)
	if absf(c.z - Warehouse.SHELF_AT.z) > Warehouse.RACK_DEPTH * .5 + .05:
		return []
	if absf(c.x - Warehouse.SHELF_AT.x) > Warehouse.RACK_LENGTH * .5 - .02:
		return []
	for level in Warehouse.RACK_LEVELS.size():
		if absf(bottom(id) - (Warehouse.FLOOR + Warehouse.RACK_LEVELS[level] + .02)) < .12:
			return [0, level]
	return []

## How many goods stand on a shelf level.
func on_level(level: int) -> int:
	return items.keys().filter(func(id): return items[id] != carried and rack_spot(id) == [0, level]).size()

## On the table.
func on_table(id: String) -> bool:
	var c := center(id)
	return absf(c.x - WORK_TABLE.x) < WORK_TABLE_SIZE.x * .5 + .05 and absf(c.z - WORK_TABLE.z) < WORK_TABLE_SIZE.y * .5 + .05 and absf(bottom(id) - (Warehouse.FLOOR + TABLE_HEIGHT)) < .15

## The centre and half size of a reference (an item).
func ref_center(ref: String) -> Vector3:
	return center(ref)

func ref_half(ref: String) -> Vector3:
	return half(ref)

## The hall x/z direction of a side of a reference. In the wall bay: front = away from the
## wall, behind = toward it, left / right as seen by the player standing in front of it and
## facing it (and the wall): for the west-wall bay the player looks west, so right is north
## (+z). Elsewhere the view from the front of the building looking in (north): left = +x.
func side_axis(ref: String, side: String) -> Vector2:
	var b := bay_of(ref)
	var out: Vector2 = BAYS[b][1] if b >= 0 else Vector2(0, -1)
	var facing := -out
	var left := Vector2(facing.y, -facing.x)
	match side:
		"front":
			return out
		"behind":
			return -out
		"left":
			return left
	return -left

## Beside a reference on the floor: on its `side` (front/behind/left/right), or any side for
## "next_to"; within about 2 m, not on it.
func beside(id: String, ref: String, side: String) -> bool:
	if not on_floor(id):
		return false
	var c := center(id)
	var r := ref_center(ref)
	var rh := ref_half(ref)
	var h := half(id)
	var d := Vector2(c.x - r.x, c.z - r.z)
	if side == "next_to":
		var gap := Vector2(absf(d.x) - rh.x - h.x, absf(d.y) - rh.z - h.z)
		return maxf(gap.x, gap.y) < 1.2 and (absf(d.x) > rh.x or absf(d.y) > rh.z)
	var axis := side_axis(ref, side)
	var along := d.dot(axis)
	var across := absf(d.dot(Vector2(axis.y, axis.x)))
	var reach_along := reach(rh, h, axis)
	var reach_across := (rh.z if axis.x != 0 else rh.x) + .4
	return along > reach_along - .1 and along < reach_along + 1.8 and across < reach_across

## Centre-to-centre distance at which two things touch along an x or z axis.
static func reach(ref_half_size: Vector3, own_half: Vector3, axis: Vector2) -> float:
	return (ref_half_size.x + own_half.x) if axis.x != 0 else (ref_half_size.z + own_half.z)

# --- Using: E ----------------------------------------------------------------------------------

## Goods and the cabinet are interactables (12 Nov 2026, interaction system): E, a click or a
## tap on one in reach uses it; while carrying, the session's input claim puts down.
func _interactable(body: Node3D, badge: Vector3) -> void:
	Interactable.attach(body, {
		# World metres (the hall is town scale 1.3); _within_reach() is the exact test.
		"prompt_distance": (REACH + .6) * 1.3,
		"badge_offset": badge,
		"on_check": func() -> Variant: return holding() == false and _within_reach(body.global_position),
		"on_use": func() -> void: use(body, null),
	})

## Carrying an item.
func holding() -> bool:
	return is_instance_valid(carried)

## E in the game: puts down what is carried, picks up an aimed item or opens / shuts the
## cabinet. False when E should do its usual thing (talk to the aimed Ramón, for example).
func use(aimed: Node3D, boss: Node3D) -> bool:
	if is_instance_valid(carried):
		if aimed == boss:
			return false
		put_down()
		return true
	if not is_instance_valid(aimed) or not _within_reach(aimed.global_position):
		return false
	if aimed is RigidBody3D and aimed.has_meta("warehouse_item"):
		pick_up(aimed)
		return true
	if aimed == _cabinet_body:
		set_cabinet(not cabinet_open)
		return true
	return false

func _within_reach(world_point: Vector3) -> bool:
	var d := to_hall(world_point) - to_hall(player.global_position)
	return Vector2(d.x, d.z).length() < REACH + .6 and d.y < 2.6

func pick_up(body: RigidBody3D) -> void:
	carried = body
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	body.collision_layer = 0
	body.collision_mask = 0
	_show_ghost(body.get_meta("size"))
	item_picked.emit(str(body.get_meta("warehouse_item")))

## Puts the carried item where the ghost is.
func put_down() -> void:
	if is_instance_valid(carried):
		_release_at(_drop_point(carried))

func _release_at(spot: Vector3) -> void:
	var body := carried
	var id := str(body.get_meta("warehouse_item"))
	carried = null
	_ghost.visible = false
	place_at(id, spot)
	body.collision_layer = 1
	body.collision_mask = 1
	body.freeze = false
	body.sleeping = false
	item_put.emit(id)

## Lets go without placing (the game ends or a task takes the item).
func drop_carried() -> void:
	if is_instance_valid(carried):
		put_down()

## The surface under the pointer (or the screen centre while the mouse is captured), seen
## past the player AND the carried thing (the floating thing used to catch the click, so the
## put-down fell back to "in front of the player"). Bodies only, not word areas.
func _aim_hit() -> Dictionary:
	var camera: Camera3D = interaction.camera
	if not is_instance_valid(camera):
		return {}
	var pointer: Vector2 = interaction.pointer_position
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pointer = camera.get_viewport().get_visible_rect().size * .5
	var origin := camera.project_ray_origin(pointer)
	var ray := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(pointer) * 60.0)
	ray.exclude = [player.get_rid()] + ([carried.get_rid()] if is_instance_valid(carried) else [])
	ray.collision_mask = 0xFFFFFFFF & ~Interaction.FIGURE_LAYER
	return camera.get_world_3d().direct_space_state.intersect_ray(ray)

## Where a put-down lands (hall-local centre): where the pointer is, within PLACE_REACH: on a
## level surface there, or on the floor in front of an aimed side (a wall, a box's side);
## else on the floor in front of the player.
func _drop_point(body: RigidBody3D) -> Vector3:
	var size: Vector3 = body.get_meta("size")
	var hit: Dictionary = _aim_hit()
	var feet := to_hall(player.global_position)
	if not hit.is_empty() and (hit.normal as Vector3).dot(copy_root.global_basis.y.normalized()) <= .6:
		# A side: stand the thing on the floor just off it.
		var p := to_hall(hit.position)
		var n := to_hall(hit.position + hit.normal) - p
		var flat := Vector2(n.x, n.z).normalized()
		var off := maxf(size.x, size.z) * .5 + .05
		p = Vector3(p.x + flat.x * off, Warehouse.FLOOR + size.y * .5 + .02, p.z + flat.y * off)
		if Vector2(p.x - feet.x, p.z - feet.z).length() < PLACE_REACH:
			return p
	elif not hit.is_empty():
		var p := to_hall(hit.position)
		if Vector2(p.x - feet.x, p.z - feet.z).length() < PLACE_REACH and p.y < feet.y + 2.4:
			return p + Vector3(0, size.y * .5 + .02, 0)
	var ahead := _forward()
	var out := CARRY_AHEAD + size.z * .5
	return Vector3(feet.x + ahead.x * out, Warehouse.FLOOR + size.y * .5 + .02, feet.z + ahead.y * out)

## The player's facing in hall x/z.
func _forward() -> Vector2:
	var f := to_hall(player.global_position - player.global_basis.z) - to_hall(player.global_position)
	var flat := Vector2(f.x, f.z)
	return flat.normalized() if flat.length() > .001 else Vector2(0, 1)

func _show_ghost(size: Vector3) -> void:
	if _ghost == null:
		_ghost = MeshInstance3D.new()
		_ghost.name = "Put-down ghost"
		var ghost_material := StandardMaterial3D.new()
		ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost_material.albedo_color = Color(1, 1, 1, .22)
		_ghost.material_override = ghost_material
		_ghost.mesh = BoxMesh.new()
		hall.add_child(_ghost)
	(_ghost.mesh as BoxMesh).size = size
	_ghost.visible = true

# --- The green marker ------------------------------------------------------------------------

## Shows a translucent green box at a hall-local centre and size (Ramón "points out").
func mark(at: Vector3, size: Vector3) -> void:
	if _marker == null:
		_marker = MeshInstance3D.new()
		_marker.name = "Hint marker"
		_marker.mesh = BoxMesh.new()
		_marker.material_override = _marker_material
		hall.add_child(_marker)
	(_marker.mesh as BoxMesh).size = size
	_marker.position = at
	_marker.visible = true

func mark_item(id: String) -> void:
	mark(center(id), items[id].get_meta("size") + Vector3.ONE * .2)

func clear_mark() -> void:
	if _marker != null:
		_marker.visible = false

# --- Each physics frame ------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(copy_root):
		return
	if is_instance_valid(carried):
		var ahead := _forward()
		var feet := to_hall(player.global_position)
		var out := CARRY_AHEAD + float(carried.get_meta("size").z) * .5
		var float_at := Vector3(feet.x + ahead.x * out, feet.y + CARRY_HEIGHT, feet.z + ahead.y * out)
		carried.global_transform = Transform3D(_world_basis(), to_world(float_at))
		_ghost.position = _drop_point(carried)
	_nudge()
	_recover()

## Walking into goods pushes them by weight (user, 8 Nov 2026: "more realistic"; the player is
## a CharacterBody3D, which does not push rigid bodies by itself, so a speed is set here): the
## boxes (6-12 kg) move at about half walking speed, sliding aside little by little, so the
## player is held up until it is out of the way.
func _nudge() -> void:
	var walk: float = player.walk_speed
	for i in player.get_slide_collision_count():
		var hit := player.get_slide_collision(i)
		var body := hit.get_collider() as RigidBody3D
		var push := -hit.get_normal()
		push.y = 0.0
		if push.length() < .01 or body == null or not body.has_meta("warehouse_item") or body == carried or body.freeze:
			continue
		var dir := push.normalized()
		var speed := walk * .45
		# Off the player's path: sideways, away from the line the player walks along.
		var side := body.global_position - player.global_position
		side -= dir * side.dot(dir)
		side.y = 0.0
		var want := dir * speed + (side.normalized() * walk * .3 if side.length() > .01 else Vector3.ZERO)
		if body.linear_velocity.dot(dir) < speed:
			body.sleeping = false
			body.linear_velocity = Vector3(want.x, body.linear_velocity.y, want.z)

## Anything that falls through or out of the hall comes back to a free floor spot.
func _recover() -> void:
	for id in items:
		if items[id] == carried:
			continue
		var c := center(id)
		if c.y < Warehouse.FLOOR - 1.0 or c.x > Warehouse.HW or c.x < Warehouse.RX or c.z < Warehouse.HALL_Z0 or c.z > Warehouse.HALL_Z1:
			var spot: Vector2 = FLOOR_SPOTS[rng.randi() % FLOOR_SPOTS.size()]
			place_at(id, Vector3(spot.x, Warehouse.FLOOR + half(id).y + .3, spot.y))

## Ends cleanly before the copy is freed.
func shutdown() -> void:
	drop_carried()
