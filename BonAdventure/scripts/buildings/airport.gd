extends RefCounted
## Airport and control tower own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## airport unit (scenes/town/airport.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- airport
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["solid_roofs", "move_pilot_awoo", "restrooms", "remove_pilot_awoo", "toilet_flush_control", "radar_patrol_screens", "coplanar_gaps", "coplanar_gaps_2", "widen_tower_elevator", "remove_tower_void_guard", "glass_windows", "tower_deck", "glass_windows_2", "interaction_metas"]
const BathFixtures := preload("res://scripts/world/bath_fixtures.gd")

## Collision for the decorative roofs and canopies (7 Nov 2026; scripts/buildings/roof_solids.gd).
## The tower cap is a frustum open at its 0.5 m apex (the mast passes through) standing on the
## cabin top slab: it gets a filled shape, so the roof has no hole.
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, [
		"Airport/ControlTower/Interior/Faceted roof cap",
		"Map facades/AIRPORT/Terminal canopy",
	], ["Airport/ControlTower/Interior/Faceted roof cap"])

## Pilot Awoo (the samoyed plush in the pilot outfit, word "pilot") sat across the front of the
## middle waiting row (seats x 2.2 / 2.8, z -4.38, terminal-local) and her FigureBlocker kept
## the learner from those two seats (check_seats_and_swan_boats, 37/39). She moves 1.9 units
## toward the information desk, to the open floor at the row's end, keeping her pose, facing,
## word and outfit, and now sits on the floor (7 Nov 2026, user decision).
const AWOO_SPOT := Vector2(0.3, -3.95)

func move_pilot_awoo(town: Node3D, _game) -> void:
	var terminal: Node3D = town.get_node("Airport/Terminal")
	var awoo: Node3D = terminal.get_node("Interior/PilotAwoo")
	var local: Transform3D = terminal.global_transform.affine_inverse() * awoo.global_transform
	local.origin.x = AWOO_SPOT.x
	local.origin.z = AWOO_SPOT.y
	awoo.global_transform = terminal.global_transform * local
	# Rest her lowest visible point on the terminal floor under the new spot.
	var lowest := INF
	for mesh in awoo.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		lowest = minf(lowest, box.position.y)
	var top := terminal.to_global(Vector3(AWOO_SPOT.x, 3.0, AWOO_SPOT.y))
	var ray := PhysicsRayQueryParameters3D.create(top, top - Vector3.UP * 6.0)
	ray.exclude = awoo.find_children("*", "CollisionObject3D", true, false).map(func(body): return body.get_rid())
	var hit := town.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or lowest == INF:
		push_error("move_pilot_awoo: no floor under the new spot")
		return
	awoo.global_position.y += hit.position.y - lowest
	print("move_pilot_awoo: lowered %.3f onto %s" % [hit.position.y - lowest, town.get_path_to(hit.collider)])

## Restrooms (user decision, 8 Nov 2026, option A: inside the unchanged terminal, from baggage
## claim; docs/guides/TOWN_DESIGN_BRIEF.md "Bathroom fixtures"). The two painted doors on the east wall
## become an open-topped block in claim's rear corner against the gate glass: women's (west) and
## men's (east) rooms, each 2.7 x 2.6 with a hinged door (E), a wall-hung toilet and a basin with
## a faucet. The carousel, its suitcases, its ceiling light and the hanging BAGGAGE CLAIM sign move
## 1.2 toward the front wall to keep a 2.25 walkway; the RESTROOMS sign moves above the new doors.
## Terminal-local coordinates (x east to the wall at 16.85, z front -8.87 to rear 8.87).
const RESTROOM_X := Vector2(11.0, 16.84)
const RESTROOM_FRONT := -1.9
const RESTROOM_BACK := .85
const RESTROOM_WALL := .12
const RESTROOM_HEIGHT := 3.3
const RESTROOM_FLOOR := .1
const DOOR_WIDTH := 1.6
const DOOR_HEIGHT := 2.5
const CAROUSEL_SHIFT := -1.2

func restrooms(town: Node3D, game) -> void:
	var terminal: Node3D = town.get_node("Airport/Terminal")
	var interior: Node3D = terminal.get_node("Interior")
	var to_interior: Transform3D = interior.transform.affine_inverse()
	# Doors animate rotation.y absolutely (door_animator.gd), so the pivots need an unrotated parent.
	if not interior.transform.basis.is_equal_approx(Basis()):
		push_error("restrooms: Airport/Terminal/Interior is rotated or scaled; door pivots would turn wrongly")
		return
	# Old painted doors (frames, leaves, icons, heads) on the east wall; keep their colours.
	var frame_color := Color("1f3a5f")
	var leaf_color := Color("c9d1d6")
	var icons := []
	for child in interior.get_children():
		var box := _local_box(terminal, child)
		if box.size == Vector3.ZERO or box.position.x < 16.6 or box.end.y > 2.9 or box.position.z < -2.7 or box.end.z > .3:
			continue
		var colour := _colour(child)
		if box.size.y > 2.6: frame_color = colour
		elif box.size.y > 2.4: leaf_color = colour
		elif box.size.y > .3: icons.append([box.get_center().z, colour])
		print("restrooms: removed ", child.name)
		_free(child)
	icons.sort_custom(func(a, b): return a[0] < b[0])
	var women_icon: Color = icons[0][1] if icons.size() >= 2 else Color("c9667f")
	var men_icon: Color = icons[-1][1] if icons.size() >= 2 else Color("4f7fb5")
	# Carousel group and the hanging claim sign move toward the front wall.
	for child in interior.get_children():
		var box := _local_box(terminal, child)
		var centre: Vector3 = box.get_center() if box.size != Vector3.ZERO else (terminal.global_transform.affine_inverse() * child.global_transform).origin
		var carousel: bool = centre.x > 7.3 and centre.x < 14.7 and centre.z > -5.5 and centre.z < -2.9 and box.size.x < 8 and box.size.z < 8
		var sign: bool = centre.x > 9.1 and centre.x < 12.9 and centre.z > -1.3 and centre.z < -1.1 and centre.y > 4.0
		if carousel or sign:
			child.position += to_interior.basis * Vector3(0, 0, CAROUSEL_SHIFT)
			print("restrooms: moved ", child.name)
	var wall_color: Color = _colour(terminal.get_node("Interior/Rear wall paint")) if interior.has_node("Rear wall paint") else Color("ece3d2")
	var put := func(title: String, centre: Vector3, size: Vector3, colour: Color, word := "", solid := true) -> Node3D:
		var node: Node3D = game.box(title, Vector3.ZERO, size, colour, word, solid)
		node.reparent(interior, false)
		node.transform = to_interior * Transform3D(Basis(), centre)
		return node
	var x0 := RESTROOM_X.x
	var x1 := RESTROOM_X.y
	var h := RESTROOM_HEIGHT
	var y := RESTROOM_FLOOR - .02 + h * .5
	var f := RESTROOM_FRONT
	var b := RESTROOM_BACK
	var t := RESTROOM_WALL
	put.call("Restroom floor", Vector3((x0 + x1) * .5, RESTROOM_FLOOR - .01, (f + b) * .5), Vector3(x1 - x0, .02, b - f), Color("dfe6e8"), "", false)
	put.call("Restroom back wall", Vector3((x0 + x1) * .5, y, b), Vector3(x1 - x0, h, t), wall_color)
	put.call("Restroom side wall", Vector3(x0 + t * .5, y, (f + b) * .5), Vector3(t, h, b - f + t), wall_color)
	var split := 13.92
	put.call("Restroom partition", Vector3(split, y, (f + b) * .5), Vector3(t, h, b - f - t), wall_color)
	# Front: two doorways, women's from the side wall, men's to the terminal wall.
	var w_open := Vector2(x0 + t, x0 + t + DOOR_WIDTH)
	var m_open := Vector2(x1 - .11 - DOOR_WIDTH, x1 - .11)
	put.call("Restroom front wall", Vector3((w_open.y + m_open.x) * .5, y, f), Vector3(m_open.x - w_open.y, h, t), wall_color)
	put.call("Restroom front wall end", Vector3((m_open.y + x1) * .5, y, f), Vector3(x1 - m_open.y, h, t), wall_color)
	var head_h := h - (DOOR_HEIGHT + .02)
	for opening in [w_open, m_open]:
		put.call("Restroom door head", Vector3((opening.x + opening.y) * .5, RESTROOM_FLOOR + DOOR_HEIGHT + head_h * .5, f), Vector3(opening.y - opening.x, head_h, t), wall_color)
		for jx in [opening.x + .03, opening.y - .03]:
			put.call("Restroom door jamb", Vector3(jx, RESTROOM_FLOOR + DOOR_HEIGHT * .5, f), Vector3(.06, DOOR_HEIGHT, t + .04), frame_color, "", false)
		put.call("Restroom door lintel", Vector3((opening.x + opening.y) * .5, RESTROOM_FLOOR + DOOR_HEIGHT + .03, f), Vector3(opening.y - opening.x, .06, t + .04), frame_color, "", false)
	# Navy cap along the top of the block, like the terminal's blue band.
	put.call("Restroom wall cap", Vector3((x0 + x1) * .5, RESTROOM_FLOOR + h - .02 + .03, f), Vector3(x1 - x0 + .02, .06, t + .04), frame_color, "", false)
	put.call("Restroom wall cap", Vector3(x0 + t * .5, RESTROOM_FLOOR + h - .02 + .03, (f + b) * .5), Vector3(t + .04, .06, b - f), frame_color, "", false)
	put.call("Restroom wall cap", Vector3(split, RESTROOM_FLOOR + h - .02 + .03, (f + b) * .5), Vector3(t + .04, .06, b - f), frame_color, "", false)
	put.call("Restroom wall cap", Vector3((x0 + x1) * .5, RESTROOM_FLOOR + h - .02 + .03, b), Vector3(x1 - x0 + .02, .06, t + .04), frame_color, "", false)
	# Doors swing into the rooms (+Z) and lie along the outer walls when open.
	_restroom_door(game, interior, to_interior, "Women's restroom door", Vector3(w_open.x + .02, RESTROOM_FLOOR, f), 1.0, -1.5, leaf_color, women_icon)
	_restroom_door(game, interior, to_interior, "Men's restroom door", Vector3(m_open.y - .02, RESTROOM_FLOOR, f), -1.0, 1.5, leaf_color, men_icon)
	# The RESTROOMS board and its label move above the doors, facing the claim (-Z).
	var board: Node3D = interior.get_node_or_null("Restroom sign")
	var label: Node3D = interior.get_node_or_null("RESTROOMS sign")
	var sign_y := RESTROOM_FLOOR + DOOR_HEIGHT + head_h * .5
	if board != null:
		board.transform = to_interior * Transform3D(Basis(Vector3.UP, PI * .5), Vector3(split, sign_y, f - t * .5 - .03))
		board.set_meta("word_key", "bathroom")
		var area := Area3D.new()
		area.name = "Pick"
		board.add_child(area)
		var shape := CollisionShape3D.new()
		var pick := BoxShape3D.new()
		pick.size = Vector3(.06, .45, 2.4)
		shape.shape = pick
		area.add_child(shape)
	if label != null:
		label.transform = to_interior * Transform3D(Basis(Vector3.UP, PI), Vector3(split, sign_y, f - t * .5 - .075))
	# Fixtures: toilets against the back wall (facing -Z), basins beside them.
	var back_face := b - t * .5
	for room in [["Women's restroom", 13.2, 11.85], ["Men's restroom", 14.62, 16.1]]:
		BathFixtures.add_toilet(interior, room[0] + " toilet", _to(to_interior, Vector3(room[1], RESTROOM_FLOOR, back_face)), PI, "public")
		var rim := Vector3(room[2], RESTROOM_FLOOR + .86, back_face)
		var basin := Node3D.new()
		basin.name = room[0] + " sink"
		basin.set_meta("word_key", "sink")
		interior.add_child(basin, true)
		basin.transform = to_interior * Transform3D(Basis(Vector3.UP, PI), rim)
		var bowl := MeshInstance3D.new()
		bowl.name = "Wall basin"
		bowl.mesh = BathFixtures.wall_basin()
		bowl.material_override = BathFixtures.finish("porcelain")
		basin.add_child(bowl)
		var solid := StaticBody3D.new()
		solid.name = "Solid"
		basin.add_child(solid)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(.58, .2, .46)
		shape.shape = box
		shape.position = Vector3(0, -.08, .23)
		solid.add_child(shape)
		solid.set_meta("object_name", basin.name)
		var deck := rim + Vector3(0, 0, -.07)
		BathFixtures.add_faucet(interior, room[0] + " faucet", _to(to_interior, deck), PI, "public_basin", (to_interior * (rim + Vector3(0, BathFixtures.WALL_BASIN_FLOOR, 0))).y)

func _restroom_door(game, interior: Node3D, to_interior: Transform3D, title: String, hinge: Vector3, side: float, angle: float, leaf_color: Color, icon_color: Color) -> void:
	var width := DOOR_WIDTH - .04
	var pivot := Node3D.new()
	pivot.name = title
	interior.add_child(pivot, true)
	pivot.transform = to_interior * Transform3D(Basis(), hinge)
	pivot.set_meta("word_key", "door")
	pivot.set_meta("door_state", {"open": false, "type": "hinge", "angle": angle})
	var leaf: Node3D = game.box(title + " leaf", Vector3.ZERO, Vector3(width, DOOR_HEIGHT - .04, .05), leaf_color, "door")
	leaf.reparent(pivot, false)
	leaf.position = Vector3(side * width * .5, (DOOR_HEIGHT - .04) * .5, 0)
	for body in leaf.find_children("*", "CollisionObject3D", true, false):
		body.set_meta("root", pivot)
		body.set_meta("object_name", title)
	# Figure icon on the claim side (-Z) and handles on both faces.
	var icon: Node3D = game.box(title + " icon", Vector3.ZERO, Vector3(.25, .4, .01), icon_color, "", false)
	icon.reparent(pivot, false)
	icon.position = Vector3(side * width * .5, 1.75, -.03)
	var head: Node3D = game.sphere(title + " icon head", Vector3.ZERO, .08, icon_color)
	head.reparent(pivot, false)
	head.position = Vector3(side * width * .5, 2.04, -.03)
	head.scale = Vector3(1, 1, .15)
	for face in [-.05, .05]:
		var handle: Node3D = game.box(title + " handle", Vector3.ZERO, Vector3(.2, .04, .04), Color("c9d1d6"), "", false)
		handle.reparent(pivot, false)
		handle.position = Vector3(side * (width - .18), 1.05, face)
	if game.get("doors") is Dictionary:
		game.doors[pivot] = pivot.get_meta("door_state").duplicate(true)

static func _to(to_interior: Transform3D, terminal_point: Vector3) -> Vector3:
	return to_interior * terminal_point

## A node's mesh bounds in terminal space (empty when it has no mesh).
static func _local_box(terminal: Node3D, node: Node) -> AABB:
	var inverse := terminal.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		if mesh.mesh == null: continue
		var part: AABB = (inverse * mesh.global_transform) * mesh.mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box

static func _colour(node: Node) -> Color:
	for mesh in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		if mesh.material_override is StandardMaterial3D:
			return (mesh.material_override as StandardMaterial3D).albedo_color
	return Color.WHITE

static func _free(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()

## Pilot Awoo (the samoyed in the middle of the terminal) removed (user decision, 8 Nov 2026).
func remove_pilot_awoo(town: Node3D, _game) -> void:
	var awoo := town.get_node_or_null("Airport/Terminal/Interior/PilotAwoo")
	if awoo == null:
		push_error("remove_pilot_awoo: PilotAwoo not found")
		return
	awoo.get_parent().remove_child(awoo)
	awoo.free()

## Toilets get a separate flush control (9 Nov 2026, user: E near the toilet sits, E or a click on
## the lever / push plate flushes): rebuilds each baked toilet's parts from bath_fixtures.gd.
func toilet_flush_control(town: Node3D, _game) -> void:
	BathFixtures.rebuild_toilets(town.get_node("Airport/Terminal/Interior"))

## Radar Patrol (pastime, 9 Nov 2026, user; docs/guides/RADAR_PATROL.md): both control-tower radars start
## the game and look like it. The old screen parts (glass discs, rings, sweep bar, blips; on the
## wall display they stood edge-on out of the frame) are replaced by one quad with the animated
## radar shader and a bright bezel ring. The housings stay. Each word root keeps "radar" and gets
## radar_console.gd: an interactable pastime station (E, a click or a tap plays; no word card).
const RADAR_SHADER := preload("res://shaders/radar_screen.gdshader")
const RADAR_CONSOLE := preload("res://scripts/objects/radar_console.gd")

func radar_patrol_screens(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node("Airport/ControlTower/Interior")
	# name: [screen radius, screen centre, faces +Y (scope) or +Z (wall display)]
	var radars := {
		"Radar scope": [0.405, Vector3(0, 0.972, 0), true],
		"Radar display": [0.6, Vector3(0, 0, 0.046), false],
	}
	var screen_material := ShaderMaterial.new()
	screen_material.shader = RADAR_SHADER
	var bezel_material := StandardMaterial3D.new()
	bezel_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bezel_material.albedo_color = Color("5fd86a")
	for radar_name in radars:
		var root := interior.get_node_or_null(radar_name) as Node3D
		if root == null:
			push_error("radar_patrol_screens: %s not found" % radar_name)
			continue
		var spec: Array = radars[radar_name]
		var radius: float = spec[0]
		var centre: Vector3 = spec[1]
		var flat: bool = spec[2]
		var removed := 0
		for child in root.get_children():
			if not child is MeshInstance3D:
				continue
			# Keep the housing: the scope's pedestal and top (below 0.95), the display's frame box.
			var keep: bool = child.position.y < 0.95 if flat else child.mesh is BoxMesh and child.position.z == 0.0
			if not keep:
				_free(child)
				removed += 1
		var screen := MeshInstance3D.new()
		screen.name = "RadarScreen"
		var quad := QuadMesh.new()
		quad.size = Vector2(radius, radius) * 2.0
		screen.mesh = quad
		screen.material_override = screen_material
		screen.position = centre
		if flat:
			screen.rotation_degrees = Vector3(-90, 0, 0)
		root.add_child(screen)
		var bezel := MeshInstance3D.new()
		bezel.name = "RadarBezel"
		var ring := TorusMesh.new()
		ring.inner_radius = radius * 0.985
		ring.outer_radius = radius * 1.06
		ring.rings = 48
		ring.ring_segments = 8
		bezel.mesh = ring
		bezel.material_override = bezel_material
		bezel.position = centre
		bezel.scale = Vector3(1, 0.35, 1)
		if not flat:
			bezel.rotation_degrees = Vector3(90, 0, 0)
		root.add_child(bezel)
		var metas := {}
		for key in root.get_meta_list():
			metas[key] = root.get_meta(key)
		root.set_script(RADAR_CONSOLE)
		for key in metas:
			root.set_meta(key, metas[key])
		print("radar_patrol_screens: %s: removed %d parts, added screen and bezel" % [radar_name, removed])

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "airport")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "airport", 2)

## The control tower's elevator fills its alcove (10 Nov 2026, user: "make the elevator in the
## watchtower wider so it fills the gap"). The 3 x 3 shaft stood 1.3 clear of the stair wall on its
## west (-x) side; it now runs from the room's east wall (2 cm gap, as before) into the stair wall:
## 4.24 wide, centre 0.62 west, door leaves 0.9 -> 1.1 (a 2.2 opening). The floors the wider shaft
## passes through are cut back to its door wall or outer face (the empty level's west strip, the
## control-room slab's piece by the shaft, split in three), the empty level's front strip now
## reaches the door wall (it stopped 6 cm short), the two control-room displays on the shaft's
## west face move with that face, and the picking box that rides with the car fits the new car.
## Interior-local coordinates (the elevator was at x 2.3, z 2.3; doors face -Z).
const TOWER_SHAFT_W := 4.24
const TOWER_LEAF := 1.1
const TOWER_SHIFT := -0.62
## New shaft outer faces: west x, front (door wall) z; a slab is cut 1 cm into them.
const TOWER_WEST := 2.3 + TOWER_SHIFT - TOWER_SHAFT_W / 2.0 - 0.08
const TOWER_FRONT := 2.3 - 1.5 - 0.09

func widen_tower_elevator(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node("Airport/ControlTower/Interior")
	var lift: Node3D = interior.get_node("Elevator")
	if not (is_equal_approx(lift.shaft_w, 3.0) and is_equal_approx(lift.leaf, 0.9) and lift.position.is_equal_approx(Vector3(2.3, 0, 2.3))):
		push_error("widen_tower_elevator: the elevator is not the 3 m shaft at (2.3, 0, 2.3)")
		return
	var strip := _slab(interior, "Empty level floor", Vector3(0, 16.3, 0))
	var front_strip := _slab(interior, "Empty level floor", Vector3(2.3, 16.3, -1.625))
	var west_slab := _slab(interior, "Floor slab", Vector3(-0.95, 21.8, 0))
	var front_slab := _slab(interior, "Floor slab", Vector3(2.3, 21.8, -2.475))
	var rear_slab := _slab(interior, "Floor slab", Vector3(2.3, 21.8, 4.75))
	var displays: Array[Node3D] = [interior.get_node_or_null("Radar display"), interior.get_node_or_null("@Node3D@18676")]
	if [strip, front_strip, west_slab, front_slab, rear_slab].has(null) or displays.has(null):
		push_error("widen_tower_elevator: a floor slab or a control-room display was not found")
		return
	lift.position.x += TOWER_SHIFT
	lift.shaft_w = TOWER_SHAFT_W
	lift.leaf = TOWER_LEAF
	# Empty level (16.5): both strips end 1 cm inside the door wall.
	_resize_slab(strip, 2, -3.9, TOWER_FRONT + 0.01)
	_resize_slab(front_strip, 2, -3.9, TOWER_FRONT + 0.01)
	# Control room (22): the west slab keeps x -2.6 .. the new west face; the piece between that
	# face and the old hole becomes a front and a rear slab like the ones beside the old hole.
	var hole_x := 2.3 - 1.6
	_resize_slab(west_slab, 0, -2.6, TOWER_WEST + 0.01)
	for slab in [front_slab, rear_slab]:
		var piece: Node3D = slab.duplicate()
		slab.get_parent().add_child(piece)
		piece.name = slab.name + " west"
		for body in piece.find_children("*", "StaticBody3D", false, false):
			if body.has_meta("root__ref"):
				body.set_meta("root__ref", str(town.get_path_to(piece)))
		_resize_slab(piece, 0, TOWER_WEST + 0.01, hole_x)
	for display in displays:
		display.position.x += TOWER_WEST - (2.3 - 1.5 - 0.08)
	# The tower's picking box (Interaction, from the deleted tower_interior.gd) rides with the car.
	for area in lift.find_children("*", "Area3D", true, false):
		if area.has_meta("ride_with_car"):
			for shape in area.find_children("*", "CollisionShape3D", false, false):
				var cube: BoxShape3D = shape.shape.duplicate()
				cube.size = Vector3(lift.cw() - 0.2, cube.size.y, lift.cd() - 0.2)
				shape.shape = cube
	print("widen_tower_elevator: shaft %.2f x %.2f at x %.2f, leaf %.2f; slabs cut, displays moved" % [lift.shaft_w, lift.shaft_d, lift.position.x, lift.leaf])

## A floor slab (a Node3D holding a box mesh and a static body named `object_name`) at `at`.
func _slab(interior: Node3D, object_name: String, at: Vector3) -> Node3D:
	for child in interior.get_children():
		if child is Node3D and child.position.is_equal_approx(at):
			for body in child.find_children("*", "StaticBody3D", false, false):
				if str(body.get_meta("object_name", "")) == object_name:
					return child
	return null

## Sets a slab's extent along `axis` (0 x, 2 z; interior-local) to from..to: its node moves, its
## box mesh and every box shape below it get the new length (each mesh's small offset and the
## difference between mesh and shape lengths, left by coplanar_gaps.gd, are kept).
func _resize_slab(slab: Node3D, axis: int, from: float, to: float) -> void:
	var old_centre: float = slab.position[axis]
	var old_length := 0.0
	for shape_node in slab.find_children("*", "CollisionShape3D", true, false):
		old_length = shape_node.shape.size[axis]
	var length := absf(to - from)
	slab.position[axis] = (from + to) / 2.0
	for mesh_node in slab.find_children("*", "MeshInstance3D", false, false):
		var box: BoxMesh = mesh_node.mesh.duplicate()
		box.size[axis] += length - old_length
		mesh_node.mesh = box
	for shape_node in slab.find_children("*", "CollisionShape3D", true, false):
		var cube: BoxShape3D = shape_node.shape.duplicate()
		cube.size[axis] = length
		shape_node.shape = cube
	print("widen_tower_elevator: %s %s %.3f..%.3f (was centre %.3f, length %.3f)" % [slab.name, "xz"[axis / 2], minf(from, to), maxf(from, to), old_centre, old_length])

## The invisible "Void guard" wall (1.5 wide, 12.3 high, 20 cm in front of the lift's door wall)
## closed the old alcove beside the lift at the open levels. The widened shaft fills that alcove
## (widen_tower_elevator), so the guard only stood in front of the lobby call button and the
## doorway's west edge: clicks and E aimed at the button hit it (user, 10 Nov 2026: "i should be
## able to press the elevator with not just e but also a click"). Removed.
func remove_tower_void_guard(town: Node3D, _game) -> void:
	var guard := town.get_node_or_null("Airport/ControlTower/Interior/Void guard collision")
	if guard == null:
		push_error("remove_tower_void_guard: Void guard collision not found")
		return
	_free(guard)
	print("remove_tower_void_guard: removed")


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "airport")


## Control tower roof, observation deck and deck door (12 Nov 2026, user: keep the look; a cleaner,
## slightly overhanging roof of one thickness; no flicker on the roof trim, frames and railing; a
## working door on the west side of the control room onto a walkable deck all round the tower;
## docs/guides/TOWN_DESIGN_BRIEF.md "Control tower roof and observation deck"). Interior-local
## coordinates (x +west, z +north, control-room floor at y 22.0; the town's 1.3 scale is outside).
## Flicker came from faces sharing a plane: the red fascia's underside on the white top slab's
## underside, and the red rail posts' outer faces on the grey ledge's edge (5 mm `coplanar_gaps`
## offsets are not enough at tower distance). Those parts are replaced; no new face shares a plane
## with a different-looking face (pieces meet face to face or overlap by at least 2 cm).
const DECK_FLOOR := 22.0          # control-room floor = deck walking surface
const DECK_IN := 5.6              # cabin floor slab edge (deck starts here)
const DECK_OUT := 7.6             # deck slab edge; clear walk 5.75 (corner posts) .. 7.46 (rail)
const DECK_SLAB_BOTTOM := 21.6    # same 0.4 thickness as the cabin floor slab
const DECK_SKIN := .06            # light deck surface on the slab
const RAIL_LINE := 7.5            # railing centre line
const RAIL_TOP := 23.05           # 1.05 above the deck (1.37 m)
const RAIL_POSTS := 6             # intervals per side (2.5 apart)
const RAIL_GUARD := 1.4           # height of the railing's collision above the deck
const ROOF_BOTTOM := 26.4         # top of the cabin header
const ROOF_TOP := 26.8            # 0.4 thick, as the old top slab
const ROOF_EDGE := 6.5            # overhang 0.85 past the header face (5.65)
const FASCIA := .08               # red edge band, 0.04 proud of the slab above and below
const CAP_BASE := 6.2             # hip cap base (0.3 inside the roof edge) ...
const CAP_TOP := .25              # ... rising to the mast at the old apex height
const CAP_APEX := 28.7
const DOOR_Z := Vector2(.08, 1.68)   # opening between the z 0 mullion and a new one at 1.76
const DOOR_TOP := 24.5
const DOOR_SLIDE := 1.5           # the leaf slides south (−z) outside the next pane

func tower_deck(town: Node3D, game) -> void:
	var room: Node3D = town.get_node("Airport/ControlTower/Interior")
	if not room.transform.basis.is_equal_approx(Basis()):
		push_error("tower_deck: ControlTower/Interior is rotated or scaled")
		return
	# Find the old parts by place and look (most are auto-named).
	var found := {"ledge": [], "rail": [], "post": [], "slab": [], "fascia": [], "lamp": [], "parapet": [], "sill": [], "glass": [], "glass wall": []}
	for child in room.get_children():
		var b := _local_box(room, child)
		var outer := maxf(maxf(-b.position.x, b.end.x), maxf(-b.position.z, b.end.z))
		var tone := _colour(child).to_html(false)
		if b.size == Vector3.ZERO:
			if child is StaticBody3D and child.position.x > 5.4 and child.position.y > 23.0 and child.position.y < 25.5:
				found["glass wall"].append(child)
			continue
		if tone == "a9a898" and absf(b.position.y - 21.9) < .01 and outer > 5.84 and outer < 5.86:
			found.ledge.append(child)
		elif tone == "d8453a" and b.position.y > 21.9 and b.end.y < 22.6 and outer > 5.84 and outer < 5.86:
			found["rail" if b.size.y < .1 else "post"].append(child)
		elif String(child.name) == "Cabin top slab" or (tone == "eef1f2" and absf(b.position.y - 26.4) < .01 and b.size.x > 11.8):
			found.slab.append(child)
		elif tone == "b7473c" and absf(b.position.y - 26.4) < .01 and b.size.x > 11.8:
			found.fascia.append(child)
		elif tone == "f2c231" and absf(b.position.y - 26.8) < .01 and outer > 5.9:
			found.lamp.append(child)
		elif b.position.x > 5.3 and b.size.z > 11.0 and b.size.x < .4:
			if tone == "2f5f8f": found.parapet.append(child)
			elif tone == "eef1f2" and b.size.y < .1: found.sill.append(child)
			elif child.has_meta("part") and b.size.y > 2.8: found.glass.append(child)
	var cap: Node3D = room.get_node_or_null("Faceted roof cap")
	var expect := {"ledge": 4, "rail": 4, "post": 20, "slab": 1, "fascia": 1, "lamp": 4, "parapet": 1, "sill": 1, "glass": 1, "glass wall": 1}
	for key in expect:
		if found[key].size() != expect[key]:
			push_error("tower_deck: expected %d %s, found %d" % [expect[key], key, found[key].size()])
			return
	if cap == null:
		push_error("tower_deck: Faceted roof cap not found")
		return
	var slab_mat := _material(room.get_node("Floor slab"))
	var deck_mat := _material(found.ledge[0])
	var rail_mat := _material(found.rail[0])
	var white_mat := _material(room.get_node("Cabin header"))
	var roof_mat := _material(found.fascia[0])
	var blue_mat := _material(found.parapet[0])
	var add := func(title: String, from: Vector3, to: Vector3, mat: Material, solid := false) -> Node3D:
		var node: Node3D = game.box(title, Vector3.ZERO, to - from, Color.WHITE, "", solid)
		node.reparent(room, false)
		node.transform = Transform3D(Basis(), (from + to) * .5)
		for mesh in node.find_children("*", "MeshInstance3D", false, false):
			mesh.material_override = mat
		return node
	var wall := func(title: String, from: Vector3, to: Vector3) -> void:
		var body := StaticBody3D.new()
		body.name = title
		room.add_child(body, true)
		body.position = (from + to) * .5
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = to - from
		shape.shape = box
		body.add_child(shape)
		body.set_meta("object_name", title)

	# 1. Old ledge, thin rail and posts, top slab and fascia, cap: removed.
	for key in ["ledge", "rail", "post", "slab", "fascia"]:
		for node in found[key]:
			_free(node)
	var old_cap_mat: Material = cap.material_override
	_free(cap)

	# 2. Observation deck: four slab pieces meeting the cabin slab edge, light surface on top.
	var o := DECK_OUT
	var i := DECK_IN
	var skin := DECK_FLOOR - DECK_SKIN
	for side in [[Vector2(-o, -o), Vector2(o, -i)], [Vector2(-o, i), Vector2(o, o)], [Vector2(i, -i), Vector2(o, i)], [Vector2(-o, -i), Vector2(-i, i)]]:
		var a: Vector2 = side[0]
		var c: Vector2 = side[1]
		add.call("Observation deck slab", Vector3(a.x, DECK_SLAB_BOTTOM, a.y), Vector3(c.x, skin, c.y), slab_mat)
		add.call("Observation deck floor", Vector3(a.x, skin, a.y), Vector3(c.x, DECK_FLOOR, c.y), deck_mat)
		wall.call("Observation deck solid", Vector3(a.x, DECK_SLAB_BOTTOM, a.y), Vector3(c.x, DECK_FLOOR, c.y))

	# 3. Railing: posts every 2.5, a top rail and a mid rail (red, as before, thicker), one solid
	# guard per side. North/south rails run corner to corner, east/west ones between them.
	var r := RAIL_LINE
	var top_rail := Vector2(.1, .06)
	var mid_rail := .05
	var post_w := .08
	var post_top := RAIL_TOP - top_rail.y
	for s in [-1.0, 1.0]:
		var ns_top := r + top_rail.x * .5
		add.call("Observation deck rail", Vector3(-ns_top, post_top, s * r - top_rail.x * .5), Vector3(ns_top, RAIL_TOP, s * r + top_rail.x * .5), rail_mat)
		add.call("Observation deck rail", Vector3(s * r - top_rail.x * .5, post_top, -r + top_rail.x * .5), Vector3(s * r + top_rail.x * .5, RAIL_TOP, r - top_rail.x * .5), rail_mat)
		var mid_y := DECK_FLOOR + (post_top - DECK_FLOOR) * .5
		add.call("Observation deck mid rail", Vector3(-r - mid_rail * .5, mid_y - mid_rail * .5, s * r - mid_rail * .5), Vector3(r + mid_rail * .5, mid_y + mid_rail * .5, s * r + mid_rail * .5), rail_mat)
		add.call("Observation deck mid rail", Vector3(s * r - mid_rail * .5, mid_y - mid_rail * .5, -r + mid_rail * .5), Vector3(s * r + mid_rail * .5, mid_y + mid_rail * .5, r - mid_rail * .5), rail_mat)
		wall.call("Observation deck guard", Vector3(-r - .06, DECK_FLOOR, s * r - .06), Vector3(r + .06, DECK_FLOOR + RAIL_GUARD, s * r + .06))
		wall.call("Observation deck guard", Vector3(s * r - .06, DECK_FLOOR, -r + .06), Vector3(s * r + .06, DECK_FLOOR + RAIL_GUARD, r - .06))
		for k in range(RAIL_POSTS + 1):
			var t := -r + 2.0 * r * k / RAIL_POSTS
			add.call("Observation deck post", Vector3(t - post_w * .5, DECK_FLOOR, s * r - post_w * .5), Vector3(t + post_w * .5, post_top, s * r + post_w * .5), rail_mat)
			if k > 0 and k < RAIL_POSTS:
				add.call("Observation deck post", Vector3(s * r - post_w * .5, DECK_FLOOR, t - post_w * .5), Vector3(s * r + post_w * .5, post_top, t + post_w * .5), rail_mat)

	# 4. Roof: one 0.4 slab overhanging to 6.5, a red band round its edge (proud by 0.04 above
	# and below, so no face lies on the slab's), a low hip cap up to the mast, lamps at the corners.
	var e := ROOF_EDGE
	var f := FASCIA
	add.call("Tower roof slab", Vector3(-e, ROOF_BOTTOM, -e), Vector3(e, ROOF_TOP, e), white_mat, true)
	for s in [-1.0, 1.0]:
		var lo := ROOF_BOTTOM - .04
		var hi := ROOF_TOP + .04
		add.call("Tower roof fascia", Vector3(-e - f, lo, minf(s * e, s * (e + f))), Vector3(e + f, hi, maxf(s * e, s * (e + f))), roof_mat)
		add.call("Tower roof fascia", Vector3(minf(s * e, s * (e + f)), lo, -e), Vector3(maxf(s * e, s * (e + f)), hi, e), roof_mat)
	var new_cap := MeshInstance3D.new()
	new_cap.name = "Faceted roof cap"
	new_cap.mesh = _hip_cap(CAP_BASE, CAP_TOP, ROOF_TOP, CAP_APEX)
	new_cap.material_override = old_cap_mat if old_cap_mat != null else roof_mat
	room.add_child(new_cap, true)
	new_cap.add_child(preload("res://scripts/buildings/roof_solids.gd").body_for(new_cap.mesh, true))
	var lamp_at := e - .18
	for lamp in found.lamp:
		lamp.position.x = signf(lamp.position.x) * lamp_at
		lamp.position.z = signf(lamp.position.z) * lamp_at
		lamp.position.y += ROOF_TOP - 26.8

	# 5. West door: the parapet, sill, pane and glass-wall collision open between z 0.08 and 1.68.
	var a0 := DOOR_Z.x
	var a1 := DOOR_Z.y
	var cut := func(node: Node3D, gap: Vector2, title: String) -> void:
		var b := AABB() if node is StaticBody3D else _local_box(room, node)
		if node is StaticBody3D:
			var shape: BoxShape3D = node.get_child(0).shape
			b = AABB(node.position - shape.size * .5, shape.size)
		var mat := _material(node)
		var solid := node is StaticBody3D
		for piece in [Vector2(b.position.z, gap.x), Vector2(gap.y, b.end.z)]:
			var from := Vector3(b.position.x, b.position.y, piece.x)
			var to := Vector3(b.end.x, b.end.y, piece.y)
			if solid:
				wall.call("Cabin glass wall collision", from, to)
			else:
				add.call(title, from, to, mat)
		_free(node)
	cut.call(found.parapet[0], Vector2(a0, a1), "Cabin parapet")
	cut.call(found.sill[0], Vector2(a0, a1), "Cabin sill")
	var wall_body: StaticBody3D = found["glass wall"][0]
	var wall_box: BoxShape3D = wall_body.get_child(0).shape
	var wall_x := Vector2(wall_body.position.x - wall_box.size.x * .5, wall_body.position.x + wall_box.size.x * .5)
	var wall_top := wall_body.position.y + wall_box.size.y * .5
	cut.call(wall_body, Vector2(a0, a1), "Cabin glass wall collision")
	wall.call("Cabin glass wall collision", Vector3(wall_x.x, DOOR_TOP, a0), Vector3(wall_x.y, wall_top, a1))
	# Glass: the pane splits at the mullion centres (z 0 and 1.76); a transom above the door.
	var pane: MeshInstance3D = found.glass[0]
	var pb := _local_box(room, pane)
	var mullion := Vector2(a1, a1 + .16)
	var glass_template: MeshInstance3D = pane.duplicate()
	for piece in [[pb.position.z, 0.0, pb.position.y], [0.0, mullion.y - .08, DOOR_TOP + .06], [mullion.y - .08, pb.end.z, pb.position.y]]:
		var glass: MeshInstance3D = pane.duplicate()
		glass.name = "Cabin glass"
		var size := Vector3(pb.size.x, pb.end.y - piece[2], piece[1] - piece[0])
		var mesh := BoxMesh.new()
		mesh.size = size
		glass.mesh = mesh
		room.add_child(glass, true)
		glass.transform = Transform3D(Basis(), Vector3(pb.get_center().x, piece[2] + size.y * .5, (piece[0] + piece[1]) * .5))
	_free(pane)
	# Frame: jambs, a head under the transom and a mullion for the fixed pane (white, as the others).
	var fx := Vector2(5.38, 5.62)
	add.call("Deck door jamb", Vector3(fx.x, DECK_FLOOR, a0), Vector3(fx.y, DOOR_TOP, a0 + .08), white_mat)
	add.call("Deck door jamb", Vector3(fx.x, DECK_FLOOR, a1 - .08), Vector3(fx.y, DOOR_TOP, a1), white_mat)
	add.call("Deck door head", Vector3(fx.x, DOOR_TOP, a0), Vector3(fx.y, DOOR_TOP + .12, a1), white_mat)
	add.call("Cabin mullion", Vector3(5.4, pb.position.y, mullion.x), Vector3(5.6, pb.end.y + .0038, mullion.y), white_mat)
	# Sliding leaf on the outside, on a track above it: E opens it 1.5 to the south.
	var leaf_x := Vector2(5.69, 5.75)
	var leaf_z := Vector2(a0 + .04, a1 - .04)
	var leaf_top := DOOR_TOP - .02
	add.call("Deck door track", Vector3(5.66, DOOR_TOP + .02, a0 - DOOR_SLIDE - .1), Vector3(5.8, DOOR_TOP + .14, a1 + .05), white_mat)
	var pivot := Node3D.new()
	pivot.name = "Deck door"
	room.add_child(pivot, true)
	var centre := Vector3((leaf_x.x + leaf_x.y) * .5, DECK_FLOOR, (leaf_z.x + leaf_z.y) * .5)
	pivot.position = centre
	pivot.set_meta("word_key", "door")
	pivot.set_meta("door_state", {"open": false, "type": "slide", "shift": Vector3(0, 0, -DOOR_SLIDE), "origin": centre, "safe_slide": true})
	var half := (leaf_z.y - leaf_z.x) * .5
	var leaf_t := leaf_x.y - leaf_x.x
	var part := func(title: String, from: Vector3, to: Vector3, mat: Material) -> void:
		var node: Node3D = add.call(title, from, to, mat)
		node.reparent(pivot, false)
		node.position = (from + to) * .5
	part.call("Deck door stile", Vector3(-leaf_t * .5, .02, -half), Vector3(leaf_t * .5, leaf_top - DECK_FLOOR, -half + .1), white_mat)
	part.call("Deck door stile", Vector3(-leaf_t * .5, .02, half - .1), Vector3(leaf_t * .5, leaf_top - DECK_FLOOR, half), white_mat)
	part.call("Deck door rail", Vector3(-leaf_t * .5, .02, -half + .1), Vector3(leaf_t * .5, .2, half - .1), white_mat)
	part.call("Deck door rail", Vector3(-leaf_t * .5, leaf_top - DECK_FLOOR - .12, -half + .1), Vector3(leaf_t * .5, leaf_top - DECK_FLOOR, half - .1), white_mat)
	var leaf_glass: MeshInstance3D = glass_template
	leaf_glass.name = "Deck door glass"
	leaf_glass.remove_meta("part")
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(.02, leaf_top - DECK_FLOOR - .28, half * 2.0 - .16)
	leaf_glass.mesh = glass_mesh
	pivot.add_child(leaf_glass)
	leaf_glass.transform = Transform3D(Basis(), Vector3(0, .2 + glass_mesh.size.y * .5 - .02, 0))
	for face in [-1.0, 1.0]:
		part.call("Deck door handle", Vector3(face * (leaf_t * .5 + .02) - .02, 1.0, half - .22), Vector3(face * (leaf_t * .5 + .02) + .02, 1.25, half - .16), white_mat)
	var leaf_body := StaticBody3D.new()
	leaf_body.name = "Deck door leaf"
	pivot.add_child(leaf_body)
	leaf_body.position = Vector3(0, (leaf_top - DECK_FLOOR) * .5, 0)
	var leaf_shape := CollisionShape3D.new()
	var leaf_box := BoxShape3D.new()
	leaf_box.size = Vector3(leaf_t, leaf_top - DECK_FLOOR, half * 2.0)
	leaf_shape.shape = leaf_box
	leaf_body.add_child(leaf_shape)
	leaf_body.set_meta("root", pivot)
	leaf_body.set_meta("object_name", "Deck door")
	leaf_body.set_meta("word", "door")
	# Pointer picking (layer 2), as the tower's other word roots; after the leaf body, so the
	# door animator's safe-slide test finds the leaf's shape first.
	var pick := Area3D.new()
	pick.name = "Interaction"
	pick.collision_layer = 2
	pick.collision_mask = 0
	pivot.add_child(pick)
	pick.position = leaf_body.position
	var pick_shape := CollisionShape3D.new()
	var pick_box := BoxShape3D.new()
	pick_box.size = leaf_box.size + Vector3(.1, 0, 0)
	pick_shape.shape = pick_box
	pick.add_child(pick_shape)
	if game.get("doors") is Dictionary:
		game.doors[pivot] = pivot.get_meta("door_state").duplicate(true)
	print("tower_deck: deck %.1f x %.1f, roof %.1f x %.1f, door z %.2f..%.2f, removed %d old rail/ledge parts" % [2 * o, 2 * o, 2 * (e + f), 2 * (e + f), a0, a1, found.ledge.size() + found.rail.size() + found.post.size()])

## A square hip cap from half-width `base` at y `y0` to half-width `top` at `y1`, closed on top,
## flat-shaded, faces outward.
static func _hip_cap(base: float, top: float, y0: float, y1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lo := [Vector3(-base, y0, -base), Vector3(base, y0, -base), Vector3(base, y0, base), Vector3(-base, y0, base)]
	var hi := [Vector3(-top, y1, -top), Vector3(top, y1, -top), Vector3(top, y1, top), Vector3(-top, y1, top)]
	var tri := func(a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
		# Godot front faces wind clockwise seen from outside: (b - a) x (c - a) points inward.
		if (b - a).cross(c - a).dot(outward) > 0.0:
			var swap := b
			b = c
			c = swap
		var n := (c - a).cross(b - a).normalized()
		for p in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(p)
	for k in 4:
		var a: Vector3 = lo[k]
		var b: Vector3 = lo[(k + 1) % 4]
		var mid := (a + b) * .5
		var outward := Vector3(mid.x, 0, mid.z).normalized()
		tri.call(a, b, hi[(k + 1) % 4], outward)
		tri.call(a, hi[(k + 1) % 4], hi[k], outward)
	tri.call(hi[0], hi[1], hi[2], Vector3.UP)
	tri.call(hi[0], hi[2], hi[3], Vector3.UP)
	return st.commit()

static func _material(node: Node) -> Material:
	for mesh in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		if mesh.material_override != null:
			return mesh.material_override
	return null


## Transparent panes the first pass missed: the terminal's auto-named gate panes, the tower's
## windows and cabin sides, and the tower deck's cabin glass and door glass (12 Nov 2026,
## docs/guides/WINDOWS.md).
func glass_windows_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate_leftovers(town, "airport")

## The old hover-hint and click metas baked on this unit's nodes go (12 Nov 2026, interaction
## system; scripts/buildings/interaction_metas.gd): their objects have Interactables now.
func interaction_metas(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/interaction_metas.gd").strip(town, "airport")
