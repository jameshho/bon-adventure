extends RefCounted
## Bigger home (user request and floor-plan sketch, 12 Nov 2026; docs/guides/REFERENCE_HOME.md "Bigger
## home"). Used once by the home step `house_expansion` (scripts/buildings/home.gd). Site
## coordinates (RelocatedSites/Home, town scale 1.3 applied by Main): +Z is the street side, -Z the
## backyard, the west bedroom column at x -11..-5 (as in the original reference_home.gd).
##   - East wing x 16..26, z -3..14: master bedroom (back, to z 7.5), a hallway along the kitchen
##     wall from a new kitchen doorway to the study, and a big bathroom (the old guest bath's
##     fixtures, a shower and the laundry) at x 18.4..26, z 7.5..14.
##   - Study x 16..26, z 14..23 beside the garage (user review, 12 Nov 2026: the office space went to
##     the master bedroom and bathroom, the garage's planned second half became the study). The
##     garage keeps its size, door and driveway; a workbench, shelves and a bicycle at its back.
##   - Guest suite x -11..-2.5, z -12..-3 in place of the old guest bath, entered from the living room.
##   - West column (user review, 12 Nov 2026): the blue and middle bedrooms (z -3..8) become the
##     guest suite's bathroom (z -3..3, door from the suite) and a bigger family bathroom (z 3..11);
##     the yellow bedroom stays.
##   - Outside walls rise to meet the roof (eave_walls()); the roof is ROOF_RISE taller.
##   - The whole house is HOUSE_SCALE taller (user, 13 Nov 2026; raise_house()): walls, door and
##     window openings, glazing and the roof's rise; furniture keeps its size. The doors went back
##     to their old height the same day (home step `door_heights`, scripts/buildings/home.gd).
##   - Backyard: the pool (same basin) moves POOL_SHIFT east; a raised round hot tub at its west end
##     spills into it; loungers move beside the new wing. The base step `home_expansion_ground`
##     cuts the ground under the moved pool; solid slabs cover the rest of the old opening.
## Footprint 624 -> 925 site units² (+48 %).

const OAK := Color("c58f4e")
const IVORY := Color("f7f3e9")
const TEAL := Color("287f9f")
const TERRACE := Color("c6c2b4")
const LIFT := .8
const WALL_TOP := 3.2 + LIFT
const POOL_SHIFT := 11.6
## The old pool opening the base ground still has a hole for (site x, z).
const OLD_OPENING := Rect2(-9.0, -13.9, 16.0, 5.8)
## The moved pool's opening (the base step cuts it; town z = site z + 29).
const POOL_OPENING := Rect2(-9.0 + POOL_SHIFT, -13.9, 16.0, 5.8)
const HOT_TUB := Vector2(0.2, -11.0)
const HOT_TUB_OUTER := 2.0
const HOT_TUB_RIM := 1.75
const HOT_TUB_BENCH := 1.25
const HOT_TUB_TOP := .5
const HOT_TUB_SEAT := 0.0
const HOT_TUB_FLOOR := -.45
## Wall lines the roof lift uses (scripts/core/vehicle_controls.gd keeps the same list).
const ROOF_WINGS := [[Vector2(-11.6, -3.6), Vector2(26.6, 17.6), 6.6 + LIFT], [Vector2(5.7, 16.8), Vector2(26.6, 23.6), 4.65 + LIFT], [Vector2(-11.6, -12.6), Vector2(-1.9, -3.1), 4.8 + LIFT]]
const CEILINGS := [[Vector2(-11.6, -3.6), Vector2(26.6, 17.6)], [Vector2(5.7, 17.6), Vector2(26.6, 23.6)], [Vector2(-11.6, -12.6), Vector2(-1.9, -3.6)]]
## The user asked for a 20 % taller roof (12 Nov 2026): rise above the eaves times 1.2.
const ROOF_RISE := 1.2
## The whole house 80 % taller (user, 13 Nov 2026): walls and ceilings 4.0 -> 7.2, the doors,
## windows and roof rise in proportion (raise_house()).
const HOUSE_SCALE := 1.8
const HOUSE_TOP := WALL_TOP * HOUSE_SCALE
## Outside wall lines that rise to meet the roof (site x/z).
const OUTER_WALLS := [[Vector2(-11, -12), Vector2(-11, 17)], [Vector2(-11, -12), Vector2(-2.5, -12)], [Vector2(-2.5, -12), Vector2(-2.5, -3)], [Vector2(-2.5, -3), Vector2(26, -3)], [Vector2(26, -3), Vector2(26, 23)], [Vector2(6, 23), Vector2(26, 23)], [Vector2(6, 17), Vector2(6, 23)], [Vector2(-11, 17), Vector2(6, 17)]]
const PROPS := "res://scenes/props/vocabulary/%s.tscn"

var game
var town: Node3D
var site: Node3D
var door_template: Node3D
var removed := 0

func build(town_root: Node3D, main) -> void:
	game = main
	town = town_root
	site = town.get_node("RelocatedSites/Home")
	door_template = site.get_node("Blue bedroom door frame").duplicate()
	west_column()
	move_guest_bath()
	backyard()
	guest_suite()
	east_wing()
	garage()
	study()
	for p in [Vector3(21, 0, 2), Vector3(22, 0, 10.75), Vector3(21, 0, 18.5), Vector3(-6.75, 0, -7.5)]:
		var light := OmniLight3D.new()
		light.name = "Room light"
		site.add_child(light, true)
		light.position = p
		light.light_color = Color("ffe8be")
	raise_house()
	roof_and_ceiling()
	door_template.free()
	print("house_expansion: removed %d old nodes" % removed)

# ------------------------------------------------------------------ helpers

func box(n: String, p: Vector3, s: Vector3, c: Color, word := "", solid := true) -> Node3D:
	var node: Node3D = game.box(n, p, s, c, word, solid)
	node.reparent(site, false)
	return node

func round_piece(n: String, p: Vector3, r: float, h: float, c: Color, word := "") -> Node3D:
	var node: Node3D = game.cylinder(n, p, r, h, c, word, false)
	node.reparent(site, false)
	return node

func wall(a: Vector2, b: Vector2) -> void:
	box("Ivory wall", Vector3((a.x + b.x) / 2, 1.6 + LIFT / 2, (a.y + b.y) / 2), Vector3(maxf(absf(b.x - a.x), .18), 3.2 + LIFT, maxf(absf(b.y - a.y), .18)), IVORY, "wall")
	box("Oak skirting", Vector3((a.x + b.x) / 2, .14, (a.y + b.y) / 2), Vector3(maxf(absf(b.x - a.x), .23), .22, maxf(absf(b.y - a.y), .23)), OAK, "", false)

## A wall from `start` to `finish` along one axis with a 2.2-wide window centred at `centre`
## (the reference_home.gd window: sill wall, lintel, glazing, oak mullions, deep sill).
func window_wall(along_x: bool, line: float, start: float, finish: float, centre := INF) -> void:
	var c: float = (start + finish) / 2 if centre == INF else centre
	var pos3 := func(u: float, y: float) -> Vector3: return Vector3(u, y, line) if along_x else Vector3(line, y, u)
	var size3 := func(u: float, y: float, t: float) -> Vector3: return Vector3(u, y, t) if along_x else Vector3(t, y, u)
	var pt2 := func(u: float) -> Vector2: return Vector2(u, line) if along_x else Vector2(line, u)
	wall(pt2.call(start), pt2.call(c - 1.1))
	wall(pt2.call(c + 1.1), pt2.call(finish))
	box("Window sill wall", pos3.call(c, .48), size3.call(2.2, .96, .18), IVORY, "wall")
	box("Window lintel", pos3.call(c, 2.95 + LIFT / 2), size3.call(2.2, .5 + LIFT, .18), IVORY, "wall")
	var glass := box("Window glazing", pos3.call(c, 1.83), size3.call(2.2, 1.74, .05), Color("b6d5d9"), "window")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.65, .82, .86, .25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(glass.get_child(0) as MeshInstance3D).material_override = mat
	for edge in [-1.1, 0.0, 1.1]:
		box("Window oak mullion", pos3.call(c + edge, 1.83), size3.call(.06, 1.8, .14), OAK, "", false)
	box("Deep window sill", pos3.call(c, 1), size3.call(2.4, .1, .42), OAK, "", false)

## Walls a..b with a door opening (1.72 wide) centred at `at` along the wall; `mount` (a door
## frame + leaf from door()) is placed in the opening.
func doorway(a: Vector2, b: Vector2, at: float, mount: Node3D) -> void:
	var vertical := absf(a.x - b.x) < .01
	var center := Vector2(a.x, at) if vertical else Vector2(at, a.y)
	var axis := Vector2(0, 1) if vertical else Vector2(1, 0)
	if a.distance_to(center - axis * .86) > .01: wall(a, center - axis * .86)
	if b.distance_to(center + axis * .86) > .01: wall(center + axis * .86, b)
	box("Ivory wall header", Vector3(center.x, 3.0 + (LIFT + .2) / 2, center.y), Vector3(.18 if vertical else 1.72, LIFT + .2, 1.72 if vertical else .18), IVORY, "wall")
	mount.position = Vector3(center.x, 0, center.y)
	mount.rotation.y = -PI / 2 if vertical else 0.0

## A hinged door like the bedroom doors (a copy of the blue bedroom's frame and leaf), registered
## with Main's doors; `angle` is the open angle (its sign picks the side it swings to).
func door(label: String, angle: float) -> Node3D:
	var mount: Node3D = door_template.duplicate()
	mount.name = label + " frame"
	site.add_child(mount, true)
	for child in mount.find_children("Interactable", "", true, false):
		child.free()
	var leaf: Node3D = mount.get_node("Blue bedroom door")
	leaf.name = label
	mount.get_node("Blue bedroom door frame").name = label + " frame"
	for body in leaf.find_children("*", "StaticBody3D", true, false):
		body.set_meta("root", leaf)
	var state := {"open": false, "type": "hinge", "angle": angle}
	leaf.set_meta("door_state", state)
	if game.get("doors") is Dictionary:
		game.doors[leaf] = state.duplicate(true)
	return mount

func remove_door(mount_name: String) -> void:
	var mount: Node3D = site.get_node(mount_name)
	for leaf in game.doors.keys():
		if is_instance_valid(leaf) and mount.is_ancestor_of(leaf):
			game.doors.erase(leaf)
	_free(mount)

## Frees the site's direct children that `keep` rejects... (positions in site units).
func free_where(test: Callable) -> int:
	var hits: Array = []
	for child in site.get_children():
		if child is Node3D and test.call(child):
			hits.append(child)
	for node in hits:
		_free(node)
	return hits.size()

func _free(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()
	removed += 1

static func at(node: Node3D, x: float, z: float, tol := .06) -> bool:
	return absf(node.position.x - x) < tol and absf(node.position.z - z) < tol

static func inside(node: Node3D, x0: float, x1: float, z0: float, z1: float) -> bool:
	return node.position.x > x0 and node.position.x < x1 and node.position.z > z0 and node.position.z < z1

## Walls, skirtings and window parts (duplicates are saved with generated names, so the
## sizes reference_home.gd gave them identify them too).
static func is_wall_piece(node: Node) -> bool:
	return str(node.get_meta("word_key", "")) in ["wall", "window"] or String(node.name).begins_with("Oak skirting") or String(node.name).contains("indow") or _is_skirting_size(_box_size(node))

## Skirting boxes: 0.22 high, 0.23 thick (pillows are 0.22 high too, but wider).
static func _is_skirting_size(size: Vector3) -> bool:
	return absf(size.y - .22) < .005 and (absf(size.x - .23) < .005 or absf(size.z - .23) < .005)

static func size_is(node: Node, size: Vector3) -> bool:
	return _box_size(node).distance_to(size) < .01

static func is_sign(node: Node) -> bool:
	return node.get_children().any(func(c): return c is Label3D)

static func _box_size(node: Node) -> Vector3:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			return (child.mesh as BoxMesh).size
	return Vector3.ZERO

func floor_slab(title: String, rect: Rect2) -> void:
	box(title, Vector3(rect.get_center().x, -.12, rect.get_center().y), Vector3(rect.size.x, .24, rect.size.y), OAK, "floor")
	var planks := int(round(rect.size.x / .5))
	for i in planks:
		box("Oak floor plank", Vector3(rect.position.x + .25 + i * .5, .015, rect.get_center().y), Vector3(.5, .025, rect.size.y - .2), OAK.lightened((i % 4) * .012), "", false)

func terrace(rect: Rect2, solid: bool) -> void:
	box("Pool terrace", Vector3(rect.get_center().x, .025, rect.get_center().y), Vector3(rect.size.x, .05, rect.size.y), TERRACE, "", solid)

## A vocabulary prefab standing on y `floor` at (x, z), its front (the prefab's -Z) facing
## `facing` (site x/z), scaled to `height`.
func prefab(file: String, title: String, x: float, z: float, floor: float, facing: Vector2, height: float) -> Node3D:
	var yaw := atan2(-facing.x, -facing.y)
	var node: Node3D = load(PROPS % file).instantiate()
	node.name = title
	site.add_child(node, true)
	var bounds := _bounds(node)
	var s := height / bounds.size.y
	node.scale = Vector3.ONE * s
	node.rotation.y = yaw
	node.position = Vector3(x, floor - bounds.position.y * s, z)
	return node

static func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.get_aabb()
		var xf: Transform3D = node.global_transform.affine_inverse() * mesh.global_transform
		for i in 8:
			var p: Vector3 = xf * b.get_endpoint(i)
			if first:
				result = AABB(p, Vector3.ZERO)
				first = false
			else:
				result = result.expand(p)
	return result

func bed(x: float, z: float, color: Color, double := false) -> void:
	var w := 2.7 if double else 1.9
	box("Oak bed", Vector3(x, .35, z), Vector3(w, .6, 3.25), OAK, "bed")
	box("Linen mattress", Vector3(x, .72, z), Vector3(w - .1, .28, 3.1), IVORY, "", false)
	box("Duvet", Vector3(x, .9, z + .35), Vector3(w - .12, .17, 2.3), color, "blanket", false)
	box("Upholstered headboard", Vector3(x, 1.05, z - 1.55), Vector3(w + .12, 1.4, .18), Color("a58e70"))
	for side in [-1, 1]:
		box("Pillow", Vector3(x + side * w * .23, .96, z - 1.02), Vector3(w * .42, .22, .6), IVORY, "pillow", false)
		box("Bedside cabinet", Vector3(x + side * (w / 2 + .5), .48, z - 1.1), Vector3(.7, .9, .75), OAK, "cabinet")
		round_piece("Bedside lamp", Vector3(x + side * (w / 2 + .5), 1.14, z - 1.1), .22, .4, IVORY, "lamp")

func houseplant(p: Vector3, size := 1.0) -> void:
	round_piece("Indoor ceramic planter", p + Vector3(0, .22, 0) * size, .28 * size, .44 * size, IVORY)
	for offset in [Vector3(-.17, .65, 0), Vector3(.16, .8, .08), Vector3(0, 1, -.1)]:
		var leaf: Node3D = game.sphere("Indoor foliage", p + offset * size, .27 * size, Color("4e863e"), "", false)
		leaf.reparent(site, false)
		leaf.scale = Vector3(.65, 1.6, .65)

func room_sign(text: String, word: String, p: Vector3, yaw: float) -> void:
	var pivot := Node3D.new()
	pivot.name = text.capitalize() + " sign"
	site.add_child(pivot, true)
	pivot.position = p
	pivot.rotation.y = yaw
	box(text.capitalize() + " sign board", Vector3.ZERO, Vector3(text.length() * .17 + .4, .4, .05), IVORY, word, false).reparent(pivot, false)
	box("Sign board trim", Vector3(0, 0, -.012), Vector3(text.length() * .17 + .5, .5, .03), OAK, "", false).reparent(pivot, false)
	var label := Label3D.new()
	label.name = text + " label"
	label.text = text
	label.font_size = 48
	label.pixel_size = .24 / 48.0
	label.modulate = Color("2d4a52")
	label.outline_size = 0
	label.position = Vector3(0, 0, .03)
	pivot.add_child(label)

func move_where(test: Callable, delta: Vector3) -> int:
	var count := 0
	for child in site.get_children():
		if child is Node3D and test.call(child):
			child.position += delta
			count += 1
	return count

# ------------------------------------------------------------------ rooms

## The blue bedroom (z -3..3) and middle bedroom (z 3..8) become two bathrooms: the guest
## suite's (z -3..3, a copy of the family bath's tub, toilet and vanity; door in the suite's wall,
## guest_suite()) and the family bathroom, now z 3..11 with a walk-in shower.
func west_column() -> void:
	# Partitions z 3 and z 8; both bedrooms' doors, headers, plaques and furniture.
	free_where(func(n): return (at(n, -8, 3) or at(n, -8, 8)) and is_wall_piece(n))
	free_where(func(n): return (at(n, -5, 6.5) or at(n, -5, 1.6)) and absf(n.position.y - 3.5) < .1)
	free_where(func(n): return (at(n, -4.88, 6.5, .1) or at(n, -4.88, 1.6, .1)) and is_sign(n))
	remove_door("Guest bedroom door frame")
	remove_door("Blue bedroom door frame")
	free_where(func(n): return inside(n, -10.95, -5.2, -2.9, 7.9) and not is_wall_piece(n) and n.position.y < 1.7)
	wall(Vector2(-5, .74), Vector2(-5, 2.46))
	wall(Vector2(-5, 5.64), Vector2(-5, 7.36))
	wall(Vector2(-11, 3), Vector2(-5, 3))
	# Both bathrooms are furnished by home_furnishing.gd (the family bath's old fixtures go there).

## The guest bath's fixtures and everyday items move, unchanged, to the east wing's bathroom
## (x 18.4..26, z 7.5..14; door on its hall side x 18.4): bathtub against the east wall, toilet
## against the bedroom wall (z 7.5, cistern face 7.59 like the old wall at -6.91), vanity beside it.
func move_guest_bath() -> void:
	move_where(func(n): return inside(n, -10.8, -9.0, -6.3, -3.9) and n.position.y < 1.2, Vector3(35.1, 0, 14.5))
	move_where(func(n): return inside(n, -8.25, -7.3, -7.1, -5.8) and n.position.y < 1.2, Vector3(30.8, 0, 14.5))
	move_where(func(n): return inside(n, -7.1, -5.9, -6.7, -5.0) and n.position.y < 1.5, Vector3(27.4, 0, 14.2))
	free_where(func(n): return at(n, -8.3, -5) and absf(n.position.y - .045) < .01)

## The old guest bath becomes part of a guest suite reached from the living room.
func guest_suite() -> void:
	# Guest bath walls (x -11 and -5 from z -7 to -3, z -7 from x -11 to -5) and foundation.
	free_where(func(n): return (at(n, -8, -7) or at(n, -11, -5) or at(n, -5, -5)) and is_wall_piece(n))
	free_where(func(n): return String(n.name) == "Guest bath foundation")
	free_where(func(n): return at(n, -6.2, -2.88, .1) and is_sign(n))
	# Its doorway in the blue bedroom's back wall: stub and header go, the wall is closed.
	free_where(func(n): return (at(n, -5.17, -3) and is_wall_piece(n)) or (at(n, -6.2, -3) and absf(n.position.y - 3.5) < .1))
	# Pool-facing glazing x -5..2.14 (the terrace door keeps its frame at 3).
	free_where(func(n): return absf(n.position.z + 3) < .06 and n.position.x > -5.1 and n.position.x < 2.2 and (String(n.name).begins_with("Glazing") or String(n.name).begins_with("Pool-facing") or size_is(n, Vector3(.075, 4.0, .16)) or size_is(n, Vector3(7.14, .18, .22)) or size_is(n, Vector3(7.14, 1.04, .22)) or size_is(n, Vector3(7.14, 2.86, .06))))
	# The suite's old topiary stood where its wall now is.
	move_where(func(n): return at(n, -4.6, -3.75, .1), Vector3(2.7, 0, 0))
	# The suite's south wall gets the door to its bathroom (west_column()); it opens into the bath.
	free_where(func(n): return at(n, -9.03, -3) and is_wall_piece(n))
	doorway(Vector2(-11, -3), Vector2(-5, -3), -8.0, door("Guest suite bathroom door", -PI / 2))
	room_sign("BATHROOM", "bathroom", Vector3(-8, 2.55, -3.12), PI)
	var mount: Node3D = site.get_node("Guest bath door frame")
	doorway(Vector2(-5, -3), Vector2(-2.5, -3), -3.75, mount)
	terrace_glazing(-2.5, 2.14)
	window_wall(false, -11, -12, -3)
	window_wall(true, -12, -11, -2.5)
	window_wall(false, -2.5, -12, -3, -9.0)
	floor_slab("Guest suite foundation", Rect2(-11, -12, 8.5, 9))
	box("Bedroom rug", Vector3(-6.75, .05, -9.2), Vector3(5.0, .03, 4.6), Color("d8c7a4"), "rug", false)
	bed(-6.75, -10.25, Color("7cabb2"), true)
	box("Bed bench", Vector3(-6.75, .3, -7.4), Vector3(2.6, .5, .7), Color("6d929a"), "bench")
	prefab("dresser", "Guest suite dresser", -10.5, -5.0, 0.0, Vector2(1, 0), 1.25)
	houseplant(Vector3(-10.3, 0, -3.8))
	room_sign("BEDROOM", "bedroom", Vector3(-3.75, 2.55, -2.88), 0)

func terrace_glazing(a: float, b: float) -> void:
	var width := b - a
	var center: float = (a + b) / 2
	box("Glazing sill", Vector3(center, .09, -3), Vector3(width, .18, .22), OAK)
	box("Glazing header", Vector3(center, 3.08 + LIFT / 2, -3), Vector3(width, .24 + LIFT, .22), IVORY)
	var glass := box("Pool-facing glazing", Vector3(center, 1.57, -3), Vector3(width, 2.86, .06), Color("b6d5d9"), "window")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.65, .82, .86, .14)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(glass.get_child(0) as MeshInstance3D).material_override = mat
	var bays := ceili(width / 2.1)
	for i in range(bays + 1):
		box("Glazing oak frame", Vector3(a + width * i / bays, 1.6 + LIFT / 2, -3), Vector3(.075, 3.2 + LIFT, .16), OAK, "", false)

## Pool moves east, hot tub at its west end, terrace re-laid, loungers and a patio set moved.
func backyard() -> void:
	free_where(func(n): return String(n.name).begins_with("Pool terrace") or (absf(n.position.y - .025) < .002 and (at(n, 2.5, -5.3) or at(n, -10.25, -10.8) or at(n, 11.75, -10.8))))
	# Loungers first (the moved pool would fall in their box), then the pool, then a patio set.
	move_where(func(n): return inside(n, 9.0, 14.6, -13.6, -7.4), Vector3(10.5, 0, 0))
	var pool_part := func(n): return (inside(n, -9.6, 7.6, -14.5, -7.5) and n.position.y < 1.2) or String(n.name) == "Pool basin"
	var moved := move_where(pool_part, Vector3(POOL_SHIFT, 0, 0))
	move_where(func(n): return inside(n, -4.3, 0.3, -5.9, -4.3), Vector3(2.0, 0, 0))
	# Terrace: solid where the old opening is, plain stone (on the ground) elsewhere.
	terrace(Rect2(-11, -15, 37, 1.1), false)
	terrace(Rect2(-11, -13.9, 2, 1.9), false)
	terrace(Rect2(-9, -13.9, 6.5, 1.9), true)
	terrace(Rect2(-2.5, -13.9, .7, 5.8), true)
	terrace(Rect2(-1.8, -13.9, 4, .9), true)
	terrace(Rect2(-1.8, -9.0, 4, .9), true)
	terrace(Rect2(2.2, -13.9, .4, 5.8), true)
	terrace(Rect2(18.6, -13.9, 7.4, 5.8), false)
	terrace(Rect2(-2.5, -8.1, 28.5, 5.1), false)
	hot_tub()
	print("house_expansion: moved %d pool parts" % moved)

func hot_tub() -> void:
	var root := Node3D.new()
	root.name = "Hot tub"
	site.add_child(root, true)
	root.position = Vector3(HOT_TUB.x, 0, HOT_TUB.y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 32
	var deck := TERRACE
	var stone := Color("b9b2a2")
	var tile := Color("9fdde4")
	var deep := Color("4f9fb5")
	var ring := func(r: float, a: float) -> Vector2: return Vector2(cos(a), sin(a)) * r
	var square := func(a: float) -> Vector2:
		var d := Vector2(cos(a), sin(a))
		var t := minf(2.0 / maxf(absf(d.x), 1e-6), 2.0 / maxf(absf(d.y), 1e-6))
		return d * t
	var quad := func(p: Array, normal: Vector3, color: Color) -> void:
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(normal)
			st.set_color(color)
			st.add_vertex(p[i])
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var s0: Vector2 = square.call(a0)
		var s1: Vector2 = square.call(a1)
		var o0: Vector2 = ring.call(HOT_TUB_OUTER, a0)
		var o1: Vector2 = ring.call(HOT_TUB_OUTER, a1)
		var r0: Vector2 = ring.call(HOT_TUB_RIM, a0)
		var r1: Vector2 = ring.call(HOT_TUB_RIM, a1)
		var b0: Vector2 = ring.call(HOT_TUB_BENCH, a0)
		var b1: Vector2 = ring.call(HOT_TUB_BENCH, a1)
		var mid := Vector3(cos((a0 + a1) / 2), 0, sin((a0 + a1) / 2))
		var v := func(p: Vector2, y: float) -> Vector3: return Vector3(p.x, y, p.y)
		quad.call([v.call(o0, .05), v.call(s0, .05), v.call(s1, .05), v.call(o1, .05)], Vector3.UP, deck)
		quad.call([v.call(o0, .05), v.call(o1, .05), v.call(o1, HOT_TUB_TOP), v.call(o0, HOT_TUB_TOP)], mid, stone)
		quad.call([v.call(r0, HOT_TUB_TOP), v.call(o0, HOT_TUB_TOP), v.call(o1, HOT_TUB_TOP), v.call(r1, HOT_TUB_TOP)], Vector3.UP, IVORY)
		quad.call([v.call(r0, HOT_TUB_TOP), v.call(r1, HOT_TUB_TOP), v.call(r1, HOT_TUB_SEAT), v.call(r0, HOT_TUB_SEAT)], -mid, tile)
		quad.call([v.call(b0, HOT_TUB_SEAT), v.call(r0, HOT_TUB_SEAT), v.call(r1, HOT_TUB_SEAT), v.call(b1, HOT_TUB_SEAT)], Vector3.UP, tile)
		quad.call([v.call(b0, HOT_TUB_SEAT), v.call(b1, HOT_TUB_SEAT), v.call(b1, HOT_TUB_FLOOR), v.call(b0, HOT_TUB_FLOOR)], -mid, deep)
		for i in [[Vector2.ZERO, b0, b1]]:
			for p in i:
				st.set_normal(Vector3.UP)
				st.set_color(deep)
				st.add_vertex(v.call(p, HOT_TUB_FLOOR))
	var mesh := MeshInstance3D.new()
	mesh.name = "Hot tub shell"
	mesh.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	root.add_child(mesh)
	var body := StaticBody3D.new()
	body.name = "Hot tub collision"
	var shape := CollisionShape3D.new()
	var concave: ConcavePolygonShape3D = mesh.mesh.create_trimesh_shape()
	concave.backface_collision = true
	shape.shape = concave
	body.add_child(shape)
	body.set_meta("object_name", "Hot tub")
	mesh.add_child(body)
	# Water (word: the swimming pool, as the pool water; no new word, user 12 Nov 2026).
	var pool_water: MeshInstance3D = site.get_node("Swimming pool").get_child(0)
	var water: Node3D = game.cylinder("Hot tub water", Vector3(0, HOT_TUB_TOP - .08, 0), HOT_TUB_RIM - .01, .02, Color("1ab4c5"), "swimming pool", false)
	water.reparent(root, false)
	water.position = Vector3(0, HOT_TUB_TOP - .08, 0)
	for child in water.get_children():
		if child is MeshInstance3D:
			child.material_override = pool_water.material_override
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rng := RandomNumberGenerator.new()
	rng.seed = 1112
	for i in 14:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * (HOT_TUB_RIM - .25)
		var bubble: Node3D = game.sphere("Hot tub bubble", Vector3.ZERO, rng.randf_range(.05, .1), Color("f4fbfc"), "", false)
		bubble.reparent(root, false)
		bubble.position = Vector3(cos(a) * r, HOT_TUB_TOP - .06, sin(a) * r)
		bubble.scale = Vector3(1, .45, 1)
	# A sheet of water spilling from the rim into the pool's west end (pool starts at x 2.6).
	var lip := Vector2(HOT_TUB_OUTER, HOT_TUB_TOP)
	var drop := Vector2(POOL_OPENING.position.x - HOT_TUB.x + .15, -.08)
	var sheet := MeshInstance3D.new()
	sheet.name = "Hot tub spill"
	var sheet_mesh := BoxMesh.new()
	sheet_mesh.size = Vector3(lip.distance_to(drop), .02, 1.0)
	sheet.mesh = sheet_mesh
	sheet.material_override = pool_water.material_override
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sheet)
	sheet.position = Vector3((lip.x + drop.x) / 2, (lip.y + drop.y) / 2, 0)
	sheet.rotation.z = atan2(drop.y - lip.y, drop.x - lip.x)
	root.set_meta("pool_opening", POOL_OPENING)

## Master bedroom, hallway, bathroom (the old guest bath's fixtures) and office.
func east_wing() -> void:
	# The kitchen's outer wall (x 16) becomes an inside wall: its windows go, a hall door comes.
	free_where(func(n): return absf(n.position.x - 16) < .25 and n.position.z > -2.95 and n.position.z < 22.9 and not String(n.name).contains("sign") and not String(n.name).begins_with("Glazing") and not String(n.name).begins_with("Pool-facing") and n.position.y < 4.2 and _box_size(n) != Vector3.ZERO)
	var fridge: Node3D = site.get_node("Refrigerator")
	fridge.position.z = 2.9
	# It opens into the kitchen (into the hall its leaf would block the hallway).
	doorway(Vector2(16, -3), Vector2(16, 14), 12.8, door("Hall door", -PI / 2))
	floor_slab("East wing foundation", Rect2(16, -3, 10, 17))
	# Outside walls.
	window_wall(true, -3, 16, 26, 24.0)
	window_wall(false, 26, -3, 7.5, 2.0)
	window_wall(false, 26, 7.5, 14, 10.75)
	# Inside walls: master/hall (z 7.5), hall/bath (x 18.4), wing/study (z 14).
	doorway(Vector2(16, 7.5), Vector2(26, 7.5), 17.2, door("Master bedroom door", PI / 2))
	doorway(Vector2(18.4, 7.5), Vector2(18.4, 14), 10.5, door("Bathroom door", PI / 2))
	doorway(Vector2(16, 14), Vector2(26, 14), 17.2, door("Study door", -PI / 2))
	# Master bedroom (x 16..26, z -3..7.5).
	box("Bedroom rug", Vector3(20.5, .05, .2), Vector3(5.2, .03, 4.8), Color("cdbfe0"), "rug", false)
	bed(20.5, -1.25, Color("b9a3d6"), true)
	prefab("wardrobe", "Master wardrobe", 25.45, 5.9, 0.0, Vector2(-1, 0), 2.6)
	prefab("dresser", "Master dresser", 16.55, 1.5, 0.0, Vector2(1, 0), 1.25)
	box("Bed bench", Vector3(20.5, .3, 1.6), Vector3(2.6, .5, .7), Color("8e7bb0"), "bench")
	prefab("armchair", "Master armchair", 22.6, 6.6, 0.0, Vector2(-.6, -1), 1.0)
	houseplant(Vector3(25.3, 0, -2.3))
	houseplant(Vector3(19.0, 0, 6.9), .8)
	room_sign("BEDROOM", "bedroom", Vector3(17.2, 2.55, 7.62), 0)
	# Bathroom (x 18.4..26, z 7.5..14): furnished by home_furnishing.gd; the laundry stays here.
	room_sign("BATHROOM", "bathroom", Vector3(18.28, 2.55, 10.5), -PI / 2)
	prefab("washing_machine", "Washing machine", 23.4, 13.45, .05, Vector2(0, -1), 1.2)
	prefab("dryer", "Dryer", 24.7, 13.45, .05, Vector2(0, -1), 1.2)
	houseplant(Vector3(16.4, 0, 9.0), .8)

## The garage keeps its own size (x 6..16; its east wall, removed with the kitchen wall in
## east_wing(), comes back in study()): a workbench, shelves and a bicycle along its back wall,
## clear of the cars, the door corridor and the house door near the back of the west wall.
func garage() -> void:
	var wood := Color("9a7048")
	box("Workbench top", Vector3(9.8, 1.0, 14.6), Vector3(2.5, .1, 1.0), wood)
	for x in [8.65, 10.95]:
		box("Workbench leg", Vector3(x, .5, 14.6), Vector3(.1, .95, .9), wood, "", false)
	box("Workbench shelf", Vector3(9.8, .3, 14.6), Vector3(2.4, .06, .9), wood, "", false)
	box("Pegboard", Vector3(9.8, 1.9, 14.12), Vector3(2.4, 1.2, .04), Color("c9a77a"), "", false)
	for i in 5:
		box("Hanging tool", Vector3(8.85 + i * .48, 1.85, 14.17), Vector3(.08, .45 - (i % 2) * .15, .05), Color("4b5257"), "", false)
	var steel := Color("8f989c")
	var shelf := box("Garage shelf", Vector3(15.45, 1.2, 16.0), Vector3(.8, .06, 3.0), steel, "shelf", false)
	for y in [.35, 1.2, 2.05]:
		box("Shelf board", Vector3(15.45, y, 16.0), Vector3(.8, .05, 3.0), steel, "", false).reparent(shelf, true)
	for z in [14.55, 17.45]:
		box("Shelf post", Vector3(15.45, 1.2, z), Vector3(.8, 2.4, .05), steel, "", false).reparent(shelf, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2311
	for y in [.38, 1.23, 2.08]:
		for z in [14.9, 15.75, 16.6, 17.3]:
			if rng.randf() < .25: continue
			var h := rng.randf_range(.3, .55)
			box("Storage box", Vector3(15.45, y + h / 2, z), Vector3(.6, h, .55), Color("c8a46e").darkened(rng.randf() * .15), "", false).reparent(shelf, true)
	prefab("bicycle", "Garage bicycle", 13.0, 14.6, .05, Vector2(1, 0), 1.4)

## Study x 16..26, z 14..23 (where the garage's second half was planned), entered from the hall.
func study() -> void:
	floor_slab("Study foundation", Rect2(16, 14, 10, 9))
	wall(Vector2(16, 14), Vector2(16, 23))
	window_wall(true, 23, 16, 26, 21.0)
	window_wall(false, 26, 14, 23, 18.5)
	box("Study rug", Vector3(21, .05, 18.5), Vector3(4.6, .03, 4.0), Color("b9c7a8"), "rug", false)
	prefab("desk", "Study desk", 25.3, 18.5, 0.0, Vector2(-1, 0), 1.0)
	prefab("computer", "Study computer", 25.4, 18.5, 1.0, Vector2(-1, 0), .75)
	prefab("chair", "Study chair", 24.0, 18.5, 0.0, Vector2(1, 0), 1.1)
	prefab("bookshelf", "Study bookshelf", 16.45, 19.0, 0.0, Vector2(1, 0), 2.5)
	prefab("bookshelf", "Study bookshelf", 16.45, 21.4, 0.0, Vector2(1, 0), 2.5)
	prefab("sofa", "Study sofa", 21.0, 22.35, 0.0, Vector2(0, -1), .95)
	prefab("lamp", "Study lamp", 25.4, 22.4, 0.0, Vector2(-1, -1), 1.8)
	prefab("globe", "Study globe", 25.2, 14.7, 0.0, Vector2(-1, 1), .9)
	houseplant(Vector3(19.6, 0, 14.6))
	houseplant(Vector3(18.6, 0, 22.4), .8)
	room_sign("STUDY", "", Vector3(17.2, 2.55, 13.88), PI)

## The whole house HOUSE_SCALE taller, from the floor up (user, 13 Nov 2026): walls, headers,
## lintels, window and glazing parts and door mounts stretch (node scale; handles keep their
## shape); sills, caps and room signs move up with them; room lights go under the new ceiling.
## Furniture keeps its size. The garage door, its opener and tracks keep their car-sized opening:
## its header and the opener's hanger grow up to the new ceiling.
func raise_house() -> void:
	var footprint := Rect2(-11.7, -12.7, 38.4, 36.4)
	var counts := {"stretched": 0, "doors": 0, "moved": 0}
	for child in site.get_children():
		if not child is Node3D or not footprint.has_point(Vector2(child.position.x, child.position.z)):
			continue
		var node := child as Node3D
		var title := String(node.name)
		if title in ["Home roof", "Home ceiling", "Eave walls"]:
			continue
		if node is Light3D:
			var light := node as OmniLight3D
			light.position.y = HOUSE_TOP - 1.0
			light.light_energy = .8
			light.omni_range = 11
			light.shadow_enabled = false
			continue
		if title == "Garage door header" or title == "Opener hanger":
			var span := _span(node)
			_stretch(node, span.x, HOUSE_TOP, span)
			counts["stretched"] += 1
			continue
		if title.begins_with("Garage door") or title.begins_with("Opener") or title.begins_with("Garage door opener"):
			continue
		if is_sign(node):
			node.position.y *= HOUSE_SCALE
			counts["moved"] += 1
			continue
		if title.ends_with("door frame") and node.find_children("*", "", true, false).any(func(n): return n.has_meta("door_state")):
			node.scale.y *= HOUSE_SCALE
			for part in node.find_children("*", "Node3D", true, false):
				var lower := String(part.name).to_lower()
				if lower.contains("handle") or lower.contains("knob") or lower.contains("lever"):
					part.scale.y /= HOUSE_SCALE
			counts["doors"] += 1
			continue
		var span := _span(node)
		if span.y == -INF:
			continue
		var size := _box_size(node)
		var word := str(node.get_meta("word_key", ""))
		# Deep window sills and the outline caps along the wall tops move; they keep their size.
		if (absf(size.y - .1) < .005 and (absf(size.x - .42) < .005 or absf(size.z - .42) < .005)) or title.begins_with("Deep window sill"):
			node.position.y *= HOUSE_SCALE
			counts["moved"] += 1
			continue
		if span.x > 3.9 and span.y < 4.15:
			node.position.y += HOUSE_TOP - WALL_TOP
			counts["moved"] += 1
			continue
		var part_of_wall := word in ["wall", "window"] or title.contains("indow") or title.begins_with("Glazing") or title.begins_with("Pool-facing") \
			or (absf(span.y - WALL_TOP) < .03 and span.x < 3.05) or (absf(span.x - .93) < .02 and absf(span.y - 2.73) < .02)
		if part_of_wall and span.x > -.05:
			node.position.y *= HOUSE_SCALE
			node.scale.y *= HOUSE_SCALE
			counts["stretched"] += 1
	print("house_expansion: raise_house ", counts)

## (bottom, top) of a node's meshes in site space.
func _span(node: Node3D) -> Vector2:
	var result := Vector2(INF, -INF)
	var to_site := site.global_transform.affine_inverse()
	for mesh in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		var b: AABB = (to_site * mesh.global_transform) * mesh.get_aabb()
		result = Vector2(minf(result.x, b.position.y), maxf(result.y, b.end.y))
	return result

## Stretches a node vertically so its meshes span bottom..top (was `span`).
func _stretch(node: Node3D, bottom: float, top: float, span: Vector2) -> void:
	var k := (top - bottom) / maxf(span.y - span.x, .001)
	node.scale.y *= k
	node.position.y = bottom + (node.position.y - span.x) * k

func roof_and_ceiling() -> void:
	for title in ["Home roof", "Home ceiling"]:
		_free(site.get_node(title))
	var cover := Node3D.new()
	cover.name = "Home ceiling"
	site.add_child(cover)
	for rect in CEILINGS:
		var a: Vector2 = rect[0]
		var b: Vector2 = rect[1]
		var plane := PlaneMesh.new()
		plane.size = b - a
		plane.flip_faces = true
		var mesh := MeshInstance3D.new()
		mesh.name = "Ceiling panel"
		mesh.mesh = plane
		mesh.material_override = game.material_for(Color("f3eee2"))
		# It blocks the sun (user, 13 Nov 2026): rooms are lit by their windows and lamps, and the
		# roof (hidden while the player is inside) no longer throws stripes across them.
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		mesh.position = Vector3((a.x + b.x) / 2, HOUSE_TOP - .002, (a.y + b.y) / 2)
		cover.add_child(mesh, true)
	var roof := Node3D.new()
	roof.name = "Home roof"
	site.add_child(roof)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b85b3e")
	material.roughness = .9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for spec in ROOF_WINGS:
		var a: Vector2 = spec[0]
		var b: Vector2 = spec[1]
		var e: float = HOUSE_TOP
		var peak: float = e + (float(spec[2]) - WALL_TOP) * ROOF_RISE * HOUSE_SCALE
		var mid: float = (a.y + b.y) / 2
		var inset: float = minf((b.y - a.y) * .38, (b.x - a.x) * .3)
		var v: Array[Vector3] = [Vector3(a.x, e, a.y), Vector3(b.x, e, a.y), Vector3(b.x, e, b.y), Vector3(a.x, e, b.y), Vector3(a.x + inset, peak, mid), Vector3(b.x - inset, peak, mid)]
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for triangle in [[0, 4, 5], [0, 5, 1], [1, 5, 2], [2, 5, 4], [2, 4, 3], [3, 4, 0]]:
			for index in triangle: surface.add_vertex(v[index])
		surface.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.name = "Terracotta hip roof"
		mesh.mesh = surface.commit()
		mesh.material_override = material
		roof.add_child(mesh, true)
		for edge in [[0, 1], [1, 2], [2, 3], [3, 0], [0, 4], [3, 4], [1, 5], [2, 5], [4, 5]]:
			var start: Vector3 = v[edge[0]]
			var end: Vector3 = v[edge[1]]
			var ridge: bool = edge[0] >= 4 or edge[1] >= 4
			var trim := box("Roof ridge cap" if ridge else "Ivory roof fascia", (start + end) / 2, Vector3(.18, .18, start.distance_to(end) + .12), Color("cb7752") if ridge else IVORY, "", false)
			trim.basis = Basis.looking_at(end - start, Vector3.UP)
			trim.reparent(roof, false)
		for side in [0, 1]:
			var left: Vector3 = v[0 if side == 0 else 3]
			var right: Vector3 = v[1 if side == 0 else 2]
			for course in range(1, 14):
				var t := course / 14.0
				var start := left.lerp(v[4], t) + Vector3(0, .025, 0)
				var end := right.lerp(v[5], t) + Vector3(0, .025, 0)
				var tile := box("Terracotta tile course", (start + end) / 2, Vector3(start.distance_to(end), .055, .07), Color("c46b49"), "", false)
				tile.reparent(roof, false)
	preload("res://scripts/buildings/roof_solids.gd").add(town, ["RelocatedSites/Home/Home roof"])
	eave_walls()

## Roof surface height at site (x, z): the highest wing's hip roof there (-INF outside them all).
static func roof_height(x: float, z: float) -> float:
	var best := -INF
	for spec in ROOF_WINGS:
		var a: Vector2 = spec[0]
		var b: Vector2 = spec[1]
		if x < a.x or x > b.x or z < a.y or z > b.y: continue
		var mid: float = (a.y + b.y) / 2
		var inset: float = minf((b.y - a.y) * .38, (b.x - a.x) * .3)
		var t := minf(minf((z - a.y) / (mid - a.y), (b.y - z) / (b.y - mid)), minf((x - a.x) / inset, (b.x - x) / inset))
		best = maxf(best, HOUSE_TOP + (float(spec[2]) - WALL_TOP) * ROOF_RISE * HOUSE_SCALE * clampf(t, 0, 1))
	return best

## The outside walls continue above the ceiling up to the roof's underside (user, 12 Nov 2026:
## no open gap between the wall tops and the eaves). One mesh, both faces of each wall line.
func eave_walls() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for line in OUTER_WALLS:
		var a: Vector2 = line[0]
		var b: Vector2 = line[1]
		var along := (b - a).normalized()
		var side := Vector2(-along.y, along.x)
		var steps := maxi(1, ceili(a.distance_to(b) / .25))
		for i in steps:
			var p := a.lerp(b, float(i) / steps)
			var q := a.lerp(b, float(i + 1) / steps)
			var hp := roof_height(p.x, p.y) - .02
			var hq := roof_height(q.x, q.y) - .02
			if maxf(hp, hq) <= HOUSE_TOP: continue
			hp = maxf(hp, HOUSE_TOP)
			hq = maxf(hq, HOUSE_TOP)
			for face in [-1.0, 1.0]:
				var o: Vector2 = side * .09 * face
				var n := Vector3(o.x, 0, o.y).normalized()
				var quad := [Vector3(p.x + o.x, HOUSE_TOP - .01, p.y + o.y), Vector3(q.x + o.x, HOUSE_TOP - .01, q.y + o.y), Vector3(q.x + o.x, hq, q.y + o.y), Vector3(p.x + o.x, hp, p.y + o.y)]
				var order := [0, 2, 1, 0, 3, 2] if face > 0 else [0, 1, 2, 0, 2, 3]
				for k in order:
					st.set_normal(n)
					st.add_vertex(quad[k])
	var mesh := MeshInstance3D.new()
	mesh.name = "Eave walls"
	mesh.mesh = st.commit()
	var mat: StandardMaterial3D = game.material_for(IVORY).duplicate()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
	site.add_child(mesh, true)
