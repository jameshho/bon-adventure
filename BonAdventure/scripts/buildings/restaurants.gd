extends RefCounted
## Restaurants own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## restaurants unit (scenes/town/restaurants.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- restaurants
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["solid_roofs", "dining_room_refresh", "pizza_burger_refit", "coplanar_gaps", "coplanar_gaps_2", "dining_game_tables", "glass_windows", "glass_windows_2", "fine_dining_dark_glass", "fine_dining_dark_glass_2", "fine_dining_real_windows", "fine_dining_real_windows_2", "fine_dining_real_windows_3", "fine_dining_single_glass", "fine_dining_single_glass_2", "facade_sign_padding", "pizza_burger_door", "taqueria_tray", "door_sounds", "palette_snap"]

## Alta Cocina dining room (Restaurants/Pizza, local frame): inside faces of the walls at
## x = ±14.70 and z = ±7.70, floor y .09, ceiling y 6.44. Front wall (entrance, z < 0) has the
## door gap x -1.8..1.8 and two arched windows centred x = ±8.5 (x ±6.42..±10.58, from y .55);
## the rear wall (z > 0) has the bar's bottle cabinet (x < -3.2), the kitchen pass
## (x 2.5..8.5, y 1.15..2.45) and the kitchen door (x 12.4..13.8, up to y 2.7).
const ROOM := "Restaurants/Pizza"
const WALL_X := 14.70
const WALL_Z := 7.70
const WOOD := Color("4a2f1e")
const RAIL := Color("b8924f")

## Collision for the decorative roofs and canopies (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, [
		"Map facades/FINE DINING/Dining hip roof",
		"Map facades/FINE DINING/Kitchen hip roof",
	])

## User request, 8 Nov 2026 (docs/guides/TOWN_DESIGN_BRIEF.md "Alta Cocina dining room refresh"):
## 1. the window glass sat in the wall's inside face (z -7.72, both 4 cm thick), so they
##    flickered; the glass becomes a thin sheet just in front of the wall and the painted view
##    pieces are layered apart;
## 2. the table by the west window (and its chandelier) and Twinkle with the host stand move
##    further into the room;
## 3. the plain cream walls get a plaster texture, dark wood corner posts, a crown moulding and
##    a wainscot on the front and rear walls, matching the side walls, so corners read;
## 4. the four word posters move to the rear wall, in one row above the kitchen pass and door
##    (the MENÚ board right above the kitchen door).
func dining_room_refresh(town: Node3D, game) -> void:
	var room: Node3D = town.get_node(ROOM)
	_window_layers(room)
	_move_table_and_host(room)
	_wall_finish(room, game)
	_rear_wall_posters(room)

func _window_layers(room: Node3D) -> void:
	var panes := 0
	for child in room.get_children():
		var node := child as Node3D
		if node == null or node.get_child_count() != 1 or not node.get_child(0) is MeshInstance3D:
			continue
		var mesh := node.get_child(0) as MeshInstance3D
		var tint := (mesh.material_override as BaseMaterial3D).albedo_color.to_html(false) if mesh.material_override is BaseMaterial3D else ""
		if absf(absf(node.position.x) - 8.5) > 2.2:
			continue
		if tint == "b5d9f2" and is_equal_approx(node.position.z, -7.72):
			# Glass: 8 mm thick, its face 1 cm in front of the wall. The arch pane is a cylinder
			# turned 90° about x, so its thickness is the local y axis.
			node.position.z = -7.694
			if mesh.mesh is CylinderMesh:
				node.scale.y = .2
			else:
				node.scale.z = .2
			panes += 1
		elif tint == "b9b2a6":
			# Bridge: face -7.655, in front of the towers and park tree (faces -7.66), which it
			# overlapped at the same depth. Lawn and river faces (-7.675) stay as they are.
			node.position.z = -7.67
	if panes != 4:
		push_error("restaurants: expected 4 window panes, moved %d" % panes)

## Every part whose centre lies over the west window table's footprint (table, settings, food,
## four chairs, the chandelier above) moves by TABLE_SHIFT; the host stand, its top, menu and
## lamp and Twinkle (BeagleWaiter) move by HOST_SHIFT.
const TABLE_AREA := Rect2(-6.3, -5.95, 2.5, 2.7)
const TABLE_SHIFT := Vector3(-2.8, 0, 2.2)
const HOST_PARTS := ["Host stand", "Host stand top", "Menu board", "Menu gold edge", "Host lamp", "BeagleWaiter"]
const HOST_SHIFT := Vector3(0, 0, 3.0)

func _move_table_and_host(room: Node3D) -> void:
	var moved := 0
	for child in room.get_children():
		var node := child as Node3D
		if node == null or node is Light3D or HOST_PARTS.has(String(node.name)):
			continue
		var bounds = _bounds(node, room)
		if bounds == null:
			continue
		var centre: Vector3 = (bounds as AABB).get_center()
		if TABLE_AREA.has_point(Vector2(centre.x, centre.z)):
			node.position += TABLE_SHIFT
			moved += 1
	for title in HOST_PARTS:
		var part := room.get_node_or_null(title) as Node3D
		if part == null:
			push_error("restaurants: host part %s not found" % title)
			continue
		part.position += HOST_SHIFT
	print("RESTAURANTS dining_room_refresh: table parts moved %d" % moved)

func _bounds(node: Node3D, room: Node3D):
	var out = null
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		var box: AABB = room.global_transform.affine_inverse() * (mesh as Node3D).global_transform * (mesh as MeshInstance3D).get_aabb()
		out = box if out == null else (out as AABB).merge(box)
	return out

func _wall_finish(room: Node3D, game) -> void:
	# Plaster: a soft, seamless cream mottle (triplanar, about 6 m a repeat) on the four inside
	# wall faces only; other cream parts keep the shared colour material.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = .012
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, Color("ddcca9"))
	ramp.set_color(1, Color("f6eedb"))
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = ramp
	var plaster := StandardMaterial3D.new()
	plaster.albedo_texture = texture
	plaster.uv1_triplanar = true
	plaster.uv1_scale = Vector3.ONE * .16
	plaster.roughness = .92
	var faces := 0
	for child in room.get_children():
		var node := child as Node3D
		if node == null or node.get_child_count() != 1 or not node.get_child(0) is MeshInstance3D:
			continue
		var mesh := node.get_child(0) as MeshInstance3D
		if not mesh.mesh is BoxMesh or not mesh.material_override is BaseMaterial3D:
			continue
		var size: Vector3 = (mesh.mesh as BoxMesh).size
		var cream: bool = (mesh.material_override as BaseMaterial3D).albedo_color.to_html(false) == "eee2c6"
		var side: bool = is_equal_approx(size.x, .04) and is_equal_approx(absf(node.position.x), 14.72)
		var end: bool = is_equal_approx(size.z, .04) and is_equal_approx(absf(node.position.z), 7.72)
		if cream and (side or end):
			mesh.material_override = plaster
			faces += 1
	if faces < 10:
		push_error("restaurants: only %d inside wall faces found" % faces)
	var top := 6.44
	# Corner posts.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_part(room, game, "Corner post", Vector3(sx * (WALL_X - .12), top * .5 + .045, sz * (WALL_Z - .12)), Vector3(.26, top - .09, .26), WOOD)
	# Crown moulding (the beams run under it at y 6.31..6.45).
	_part(room, game, "Crown moulding", Vector3(0, 6.35, -(WALL_Z - .05)), Vector3(2 * WALL_X, .18, .1), WOOD)
	_part(room, game, "Crown moulding", Vector3(0, 6.35, WALL_Z - .05), Vector3(2 * WALL_X, .18, .1), WOOD)
	_part(room, game, "Crown moulding", Vector3(-(WALL_X - .05), 6.35, 0), Vector3(.1, .18, 2 * WALL_Z), WOOD)
	_part(room, game, "Crown moulding", Vector3(WALL_X - .05, 6.35, 0), Vector3(.1, .18, 2 * WALL_Z), WOOD)
	# Wainscot on the front and rear walls, as on the side walls (panel to y 1.1, rail 1.1..1.2),
	# left out at the windows, the entrance (and its open door leaves) and the kitchen door; the
	# bar's bottle cabinet covers the rear wall west of x -3.2.
	var spans := {
		-1.0: [[-14.44, -10.78], [-6.32, -3.55], [3.55, 6.32], [10.78, 14.44]],
		1.0: [[-3.2, 12.4], [13.8, 14.44]],
	}
	for sz in spans:
		for span in spans[sz]:
			var mid: float = (span[0] + span[1]) * .5
			var width: float = span[1] - span[0]
			_part(room, game, "Wainscot panel", Vector3(mid, .55 + .045, sz * (WALL_Z - .03)), Vector3(width, 1.1, .06), WOOD)
			_part(room, game, "Wainscot rail", Vector3(mid, 1.15 + .045, sz * (WALL_Z - .03)), Vector3(width, .1, .07), RAIL)

func _part(room: Node3D, game, title: String, at: Vector3, size: Vector3, color: Color) -> void:
	var part: Node3D = game.box(title, Vector3.ZERO, size, color, "", false)
	part.reparent(room, false)
	part.position = at

## The four posters in one row on the rear wall, between the bottle cabinet and the east
## corner post, clear of the rear sconces (x 1.0 and, moved here, 10.05), above the kitchen
## pass (top y 2.45) and door (top 2.7), facing into the room (rotation 0: a poster's face is
## its local -z). Seen from the room, left to right: MENÚ, textures, tastes, ingredients.
const POSTERS := {
	"Restaurant poster ingredients": -1.1,
	"Restaurant poster tastes": 3.49,
	"Restaurant poster textures": 7.6,
	"Restaurant menu board": 12.37,
}
const POSTER_Y := 4.6
const POSTER_Z := 7.62

func _rear_wall_posters(room: Node3D) -> void:
	for title in POSTERS:
		var poster := room.get_node_or_null(title) as Node3D
		if poster == null:
			push_error("restaurants: %s not found" % title)
			continue
		poster.transform = Transform3D(Basis.IDENTITY, Vector3(POSTERS[title], POSTER_Y, POSTER_Z))
	# The rear sconce at x 10.45 (shade, cap and base) moves west, between two posters.
	for child in room.get_children():
		var node := child as Node3D
		if node != null and is_equal_approx(node.position.x, 10.45) and is_equal_approx(node.position.z, 7.55):
			node.position.x = 10.05

# ---------------------------------------------------------------- Pizza and Burger refit

## 9 Nov 2026 (docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"): the Pizza and Burger dining room
## and patio are refurnished in tidy rows and every visible food, tray, drink, chair and table
## teaches its word (the old builder taught only the first copy of each, and its soda bottle
## sat inside the fridge's collision). Burger-local frame (Restaurants/Burger, scale 1.3,
## turned 180 degrees): door gap x 1.3..4.7 in the front glass at z -7.875; dining wing x -15..15,
## z -8..2 (inside faces x +-14.75, z -7.75 and 1.75); service counter x -14.9..-1.1, front at
## z 1.08; kitchen behind it (x -15..-1, z 2..10); patio x 1..15, z 2..10. Floor top y .10
## (patio .075). Shell, counter, kitchen, staff and menus stay; only look-alikes there are tagged.
const PB := "Restaurants/Burger"
const PB_FLOOR := .10
const PB_PATIO := .075
const PB_TABLE_TOP := .76
const PB_RED := "c62f24"
const PB_GREEN := "3f8a52"
const PB_CREAM := "f4ead6"
const PB_WHITE := "f7f4ee"
const PB_CHROME := "c9d1d6"
const PB_DARK := "2e2f33"
const PB_BUN := "d9923a"
const PB_SODAS := ["d9423a", "3c9a4f", "f2a531", "3a7bd5"]
const PB_ART := preload("res://scripts/buildings/supermarket_products.gd")
## The sports store's step helpers (word items with fitted pick areas, fixtures with
## player-only blockers) are reused rather than copied.
const PB_KIT := preload("res://scripts/buildings/sports.gd")

var kit
var art
var pb_meshes := {}

## One mesh per model and colour, shared by every copy (keeps the baked scene small).
func _pb_cached(key: String, draw: Callable) -> ArrayMesh:
	if not pb_meshes.has(key):
		pb_meshes[key] = kit.mesh_of(key, draw)
	return pb_meshes[key]

func pizza_burger_refit(town: Node3D, game) -> void:
	var burger := town.get_node_or_null(PB) as Node3D
	if burger == null:
		push_error("restaurants: %s not found" % PB)
		return
	kit = PB_KIT.new()
	kit.g = game
	kit.room = burger
	kit.art = PB_ART.new()
	art = kit.art
	var removed := _pb_clear(burger)
	_pb_tag_kitchen(burger)
	var dining := _pb_group(burger, "Dining room")
	for row in [[-5.6, 0], [-2.4, 3]]:
		var k := 0
		for x in [-12.4, -8.6, -4.8]:
			_pb_table_set(dining, "Table %d" % (row[1] + k + 1), Vector3(x, PB_FLOOR, row[0]), row[1] + k, true)
			k += 1
	var k2 := 6
	for z in [-5.0, -1.6]:
		for x in [6.6, 9.9]:
			_pb_table_set(dining, "Table %d" % (k2 + 1), Vector3(x, PB_FLOOR, z), k2, true)
			k2 += 1
	var booths := _pb_group(burger, "Booths")
	var b := 0
	for z in [-6.4, -4.2, -2.0, .2]:
		_pb_booth(booths, "Booth %d" % (b + 1), Vector3(14.07, PB_FLOOR, z), b)
		b += 1
	_pb_drinks_fridge(burger)
	_pb_entrance(burger, game)
	_pb_order_sign(burger)
	var patio := _pb_group(burger, "Patio furniture")
	_pb_table_set(patio, "Patio table 1", Vector3(4.5, PB_PATIO, 5.2), 0, false)
	_pb_table_set(patio, "Patio table 2", Vector3(11.0, PB_PATIO, 5.2), 1, false)
	print("restaurants: Pizza and Burger refit, %d old parts removed" % removed)

func _pb_group(parent: Node3D, title: String) -> Node3D:
	var group := Node3D.new()
	group.name = title
	parent.add_child(group)
	return group

## Removes the old dining furniture, food, booths, drinks fridge and patio tables and chairs.
func _pb_clear(burger: Node3D) -> int:
	var chair_parts := [Vector3(.46, .06, .46), Vector3(.46, .62, .06), Vector3(.05, .42, .05), Vector3(.12, .74, .12)]
	var doomed: Array = []
	for child in burger.get_children():
		if not child is Node3D or child is Light3D or child is Label3D:
			continue
		var p: Vector3 = child.position
		var dining: bool = absf(p.x) < 14.7 and p.z > -7.7 and p.z < 1.85 and p.y > .1 and p.y < 2.6
		var counter_side: bool = p.x < -1.0 and p.z > .9
		var patio := false
		if p.x > -.9 and p.z > 2.0 and p.y > .1 and p.y < 1.3:
			var size := _pb_size(child)
			patio = str(child.get_meta("word_key", "")) == "table"
			for part in chair_parts:
				patio = patio or size.is_equal_approx(part)
		if (dining and not counter_side) or patio:
			doomed.append(child)
	for child in doomed:
		burger.remove_child(child)
		child.free()
	return doomed.size()

func _pb_size(node: Node3D) -> Vector3:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			return (child.mesh.get_aabb().size * 100.0).round() / 100.0
	return Vector3.ZERO

## Kitchen, counter and patio look-alikes that the old builder left untaught (by their baked
## position): two display pizzas, two menu boards, a fridge, the sink, two shelves, the back
## door, and the patio planters, shrubs and hedges.
func _pb_tag_kitchen(burger: Node3D) -> void:
	var spots := [
		[Vector3(-9.0, 1.28, 1.5), "pizza"], [Vector3(-7.8, 1.28, 1.5), "pizza"],
		[Vector3(-11.0, 3.5, 1.9), "menu"], [Vector3(-5.0, 3.5, 1.9), "menu"],
		[Vector3(-14.1, 1.08, 6.1), "refrigerator"], [Vector3(-12.2, .53, 9.2), "sink"],
		[Vector3(-1.45, 1.78, 5.0), "shelf"], [Vector3(-1.45, 2.68, 5.0), "shelf"],
		[Vector3(-1.1, 1.28, 8.7), "door"],
		[Vector3(1.5, .35, 9.5), "planter"], [Vector3(14.2, .35, 9.5), "planter"],
		[Vector3(1.5, .9, 9.5), "shrub"], [Vector3(14.2, .9, 9.5), "shrub"],
		[Vector3(8.0, .5, 9.85), "hedge"], [Vector3(14.9, .5, 6.0), "hedge"],
	]
	for spot in spots:
		var found: Node3D = null
		for child in burger.get_children():
			if child is Node3D and child.position.distance_to(spot[0]) < .03:
				found = child
				break
		if found == null:
			push_error("restaurants: no part at %s for %s" % [spot[0], spot[1]])
			continue
		found.set_meta("word_key", spot[1])
		if found.find_children("*", "CollisionObject3D", false, false).is_empty():
			# Like Main.box's word parts: a non-solid area the size of the mesh.
			var area := Area3D.new()
			var shape := CollisionShape3D.new()
			var cube := BoxShape3D.new()
			cube.size = _pb_size(found)
			shape.shape = cube
			area.add_child(shape)
			area.set_meta("object_name", String(found.name))
			area.set_meta("root", found)
			area.set_meta("word", spot[1])
			found.add_child(area)

# ---------------------------------------------------------------- furniture models

## Diner chair: chrome legs and back posts, padded back (origin on the floor, front -Z).
## The seat cushion is a separate mesh (seat_mesh) so the seating controller finds the seat.
func _pb_chair_mesh(tint: String) -> ArrayMesh:
	return _pb_cached("Diner chair " + tint, func() -> void:
		for x in [-.19, .19]:
			for z in [-.18, .19]:
				art.cyl(Vector3(x, .22, z), Vector3(.032, .44, .032), PB_CHROME, PB_ART.METAL, Vector3.ZERO, 8)
			art.cyl(Vector3(x, .72, .2), Vector3(.03, .56, .03), PB_CHROME, PB_ART.METAL, Vector3(-.08, 0, 0), 8)
		art.bx(Vector3(0, .44, 0), Vector3(.46, .03, .44), PB_DARK, PB_ART.SATIN)
		art.bx(Vector3(0, .8, .22), Vector3(.44, .3, .07), tint, PB_ART.SATIN, Vector3(-.08, 0, 0))
		art.cyl(Vector3(0, .95, .23), Vector3(.07, .44, .07), tint, PB_ART.SATIN, Vector3(0, 0, PI / 2), 10))

func _pb_seat_mesh(size: Vector3, y: float, tint: String) -> ArrayMesh:
	return _pb_cached("Seat cushion %s %s %s" % [size, y, tint], func() -> void:
		art.bx(Vector3(0, y, .0), size, tint, PB_ART.MATTE)
		art.cyl(Vector3(0, y, -size.z * .5), Vector3(size.y, size.x, size.y), tint, PB_ART.MATTE, Vector3(0, 0, PI / 2), 10))

## A seat word (chair, bench): the frame item plus a "Seat" cushion mesh, facing -Z.
func _pb_seat(parent: Node3D, title: String, word: String, frame: ArrayMesh, cushion: ArrayMesh, p: Vector3, yaw: float) -> Node3D:
	var root: Node3D = kit.item(title, word, frame, p, yaw, parent)
	var seat := MeshInstance3D.new()
	seat.name = "Seat"
	seat.mesh = cushion
	root.add_child(seat)
	root.set_meta("sit_enabled", true)
	root.set_meta("sit_forward", Vector3(0, 0, -1))
	return root

func _pb_table_mesh(size: Vector2) -> ArrayMesh:
	return _pb_cached("Diner table %s" % size, func() -> void:
		art.cyl(Vector3(0, .02, 0), Vector3(.56, .04, .56), PB_DARK, PB_ART.SATIN, Vector3.ZERO, 16)
		art.cyl(Vector3(0, .38, 0), Vector3(.1, .7, .1), PB_CHROME, PB_ART.METAL, Vector3.ZERO, 10)
		art.cyl(Vector3(0, .69, 0), Vector3(.3, .03, .3), PB_DARK, PB_ART.SATIN, Vector3.ZERO, 10)
		art.bx(Vector3(0, .72, 0), Vector3(size.x + .02, .03, size.y + .02), PB_RED, PB_ART.SATIN)
		art.bx(Vector3(0, .745, 0), Vector3(size.x, .03, size.y), PB_CREAM, PB_ART.SATIN))

## Booth bench: red upholstered base and tall tufted back at +Z, length along x.
func _pb_bench_mesh(length: float) -> ArrayMesh:
	return _pb_cached("Booth bench %s" % length, func() -> void:
		art.bx(Vector3(0, .2, -.02), Vector3(length, .4, .46), "8f2119", PB_ART.SATIN)
		art.bx(Vector3(0, .84, .2), Vector3(length, .88, .14), PB_RED, PB_ART.SATIN)
		art.bx(Vector3(0, 1.3, .2), Vector3(length + .02, .06, .18), PB_CREAM, PB_ART.SATIN)
		var n := int(length / .32)
		for k in range(1, n):
			art.bx(Vector3(-length * .5 + k * length / n, .84, .128), Vector3(.016, .74, .01), "8f2119", PB_ART.MATTE)
		art.bx(Vector3(0, .03, -.24), Vector3(length, .06, .02), PB_CHROME, PB_ART.METAL))

## Pendant lamp: cord from the ceiling, red dome shade, warm bulb (origin at the shade's rim).
func _pb_pendant_mesh(drop: float) -> ArrayMesh:
	return _pb_cached("Pendant lamp %s" % drop, func() -> void:
		art.cyl(Vector3(0, drop * .5 + .2, 0), Vector3(.02, drop, .02), PB_DARK, PB_ART.SATIN, Vector3.ZERO, 6)
		art.cyl(Vector3(0, drop + .2, 0), Vector3(.12, .03, .12), PB_DARK, PB_ART.SATIN, Vector3.ZERO, 10)
		art.dome(Vector3(0, .1, 0), Vector3(.46, .2, .46), PB_RED, PB_ART.SATIN, Vector3.ZERO, 16)
		art.ring(Vector3(0, .0, 0), Vector3(.47, .03, .47), PB_CREAM, PB_ART.SATIN, Vector3.ZERO, .9, 16)
		art.ball(Vector3(0, .0, 0), Vector3(.12, .12, .12), "fff2c4", PB_ART.SATIN, Vector3.ZERO, 10))

# ---------------------------------------------------------------- food models (origin at the bottom)

func _pb_food_mesh(kind: String, tint := "") -> ArrayMesh:
	return _pb_cached(kind.capitalize() + " " + tint, func() -> void: _pb_draw_food(kind, tint))

func _pb_draw_food(kind: String, tint: String) -> void:
	match kind:
		"tray":
			art.bx(Vector3(0, .012, 0), Vector3(.46, .024, .34), PB_RED, PB_ART.SATIN)
			for side in [-1.0, 1.0]:
				art.bx(Vector3(0, .03, side * .164), Vector3(.46, .02, .012), PB_RED, PB_ART.SATIN)
				art.bx(Vector3(side * .224, .03, 0), Vector3(.012, .02, .34), PB_RED, PB_ART.SATIN)
		"hamburger":
			art.cyl(Vector3(0, .025, 0), Vector3(.17, .05, .17), PB_BUN, PB_ART.MATTE, Vector3.ZERO, 14)
			art.cyl(Vector3(0, .065, 0), Vector3(.18, .03, .18), "5a321e", PB_ART.MATTE, Vector3.ZERO, 14)
			art.bx(Vector3(0, .083, 0), Vector3(.16, .01, .16), "f2c231", PB_ART.SATIN, Vector3(0, .4, 0))
			art.cyl(Vector3(0, .094, 0), Vector3(.19, .014, .19), "6fae3c", PB_ART.MATTE, Vector3.ZERO, 12)
			art.cyl(Vector3(0, .106, 0), Vector3(.15, .012, .15), "d8452f", PB_ART.SATIN, Vector3.ZERO, 12)
			art.dome(Vector3(0, .148, 0), Vector3(.17, .075, .17), PB_BUN, PB_ART.SATIN, Vector3.ZERO, 14)
			for k in 6:
				var a := TAU * k / 6.0
				art.bx(Vector3(cos(a) * .045, .181 - .006 * (k % 2), sin(a) * .045), Vector3(.012, .005, .007), "f6ecd0", PB_ART.MATTE, Vector3(0, a, 0))
		"french fries":
			art.bx(Vector3(0, .06, 0), Vector3(.11, .12, .075), PB_RED, PB_ART.SATIN)
			art.bx(Vector3(0, .07, -.04), Vector3(.05, .03, .003), "f2c231", PB_ART.MATTE)
			for k in 7:
				art.bx(Vector3(-.04 + k * .013, .14 + .012 * (k % 3), (k % 2) * .012 - .006), Vector3(.012, .09, .012), "f0c24a", PB_ART.MATTE, Vector3(0, 0, (k - 3) * .05))
		"soda":
			art.cyl(Vector3(0, .1, 0), Vector3(.1, .2, .1), PB_WHITE, PB_ART.SATIN, Vector3.ZERO, 12, 1.12)
			art.cyl(Vector3(0, .11, 0), Vector3(.108, .07, .108), PB_RED, PB_ART.SATIN, Vector3.ZERO, 12)
			art.cyl(Vector3(0, .208, 0), Vector3(.114, .016, .114), PB_WHITE, PB_ART.SATIN, Vector3.ZERO, 12)
			art.cyl(Vector3(.02, .26, 0), Vector3(.012, .12, .012), "f2c231", PB_ART.SATIN, Vector3(0, 0, -.15), 6)
		"pizza":
			art.cyl(Vector3(0, .008, 0), Vector3(.44, .016, .44), PB_CHROME, PB_ART.METAL, Vector3.ZERO, 18)
			art.cyl(Vector3(0, .027, 0), Vector3(.4, .024, .4), "e0a050", PB_ART.MATTE, Vector3.ZERO, 18)
			art.cyl(Vector3(0, .04, 0), Vector3(.36, .006, .36), "d1402a", PB_ART.MATTE, Vector3.ZERO, 18)
			art.cyl(Vector3(0, .044, 0), Vector3(.33, .006, .33), "f2c75c", PB_ART.SATIN, Vector3.ZERO, 18)
			for k in 3:
				art.bx(Vector3(0, .048, 0), Vector3(.36, .004, .008), "c98a3e", PB_ART.MATTE, Vector3(0, k * PI / 3, 0))
			for k in 7:
				var a := TAU * k / 6.0 + .5
				var r := .0 if k == 6 else .1
				art.cyl(Vector3(cos(a) * r, .05, sin(a) * r), Vector3(.05, .008, .05), "a8261d", PB_ART.SATIN, Vector3.ZERO, 10)
		"napkin":
			art.bx(Vector3(0, .006, 0), Vector3(.13, .012, .13), PB_WHITE, PB_ART.MATTE)
			art.bx(Vector3(.01, .015, .01), Vector3(.11, .006, .11), "ece8e0", PB_ART.MATTE)
		"bottle":
			art.cyl(Vector3(0, .1, 0), Vector3(.1, .2, .1), tint, PB_ART.SATIN, Vector3.ZERO, 10)
			art.cyl(Vector3(0, .1, 0), Vector3(.104, .08, .104), PB_WHITE, PB_ART.SATIN, Vector3.ZERO, 10)
			art.cyl(Vector3(0, .225, 0), Vector3(.1, .05, .1), tint, PB_ART.SATIN, Vector3.ZERO, 10, .45)
			art.cyl(Vector3(0, .27, 0), Vector3(.045, .05, .045), tint, PB_ART.SATIN, Vector3.ZERO, 8)
			art.cyl(Vector3(0, .3, 0), Vector3(.05, .022, .05), "e8e8e8", PB_ART.METAL, Vector3.ZERO, 8)

func _pb_food(parent: Node3D, kind: String, word: String, p: Vector3, yaw: float, tint := "") -> Node3D:
	return kit.item(word.capitalize(), word, _pb_food_mesh(kind, tint), p, yaw, parent)

## One customer's meal: a tray with a burger, fries and a soda, or a pizza and a soda; a napkin
## beside it. `p` is the tray centre on the table top; the tray's long side runs along local x.
func _pb_meal(parent: Node3D, p: Vector3, yaw: float, kind: String) -> void:
	var at := func(offset: Vector3) -> Vector3: return p + offset.rotated(Vector3.UP, yaw)
	if kind == "pizza":
		_pb_food(parent, "pizza", "pizza", at.call(Vector3(-.03, 0, 0)), yaw)
		_pb_food(parent, "soda", "soda", at.call(Vector3(.27, 0, -.14)), yaw)
	else:
		_pb_food(parent, "tray", "tray", p, yaw)
		var top: Vector3 = at.call(Vector3(0, .024, 0)) - p
		_pb_food(parent, "hamburger", "hamburger", at.call(Vector3(-.1, 0, -.02)) + top, yaw)
		_pb_food(parent, "french fries", "french fries", at.call(Vector3(.09, 0, -.07)) + top, yaw)
		_pb_food(parent, "soda", "soda", at.call(Vector3(.13, 0, .08)) + top, yaw)
	_pb_food(parent, "napkin", "napkin", at.call(Vector3(-.32, 0, .02)), yaw + .3)

# ---------------------------------------------------------------- dining room

## A square table for four (two on the patio, across x) with a meal at the two x-side places.
func _pb_table_set(parent: Node3D, title: String, c: Vector3, n: int, food: bool) -> void:
	var group := _pb_group(parent, title)
	group.position = c
	var table: Node3D = kit.item("Table", "table", _pb_table_mesh(Vector2(1.0, 1.0)), Vector3.ZERO, 0.0, group)
	kit.solid(table, AABB(Vector3(-.5, 0, -.5), Vector3(1.0, PB_TABLE_TOP, 1.0)), true)
	var places := [Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	if food:
		places += [Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var k := 0
	for d in places:
		var tint: String = PB_RED if (n + k) % 2 == 0 else PB_GREEN
		_pb_seat(group, "Chair", "chair", _pb_chair_mesh(tint), _pb_seat_mesh(Vector3(.44, .07, .42), .49, tint), d * .78, atan2(d.x, d.z))
		k += 1
	if food:
		var kinds: Array = [["hamburger", "pizza"], ["pizza", "hamburger"], ["hamburger", "hamburger"]][n % 3]
		_pb_meal(group, Vector3(.25, PB_TABLE_TOP, 0), PI / 2, kinds[0])
		_pb_meal(group, Vector3(-.25, PB_TABLE_TOP, 0), -PI / 2, kinds[1])

## A booth against the east glass: a table between two facing benches and a pendant lamp.
func _pb_booth(parent: Node3D, title: String, c: Vector3, n: int) -> void:
	var group := _pb_group(parent, title)
	group.position = c
	var table: Node3D = kit.item("Table", "table", _pb_table_mesh(Vector2(1.25, .8)), Vector3.ZERO, 0.0, group)
	kit.solid(table, AABB(Vector3(-.625, 0, -.4), Vector3(1.25, PB_TABLE_TOP, .8)), true)
	for side in [-1.0, 1.0]:
		var bench := _pb_seat(group, "Bench", "bench", _pb_bench_mesh(1.3), _pb_seat_mesh(Vector3(1.26, .1, .44), .45, PB_RED), Vector3(0, 0, side * .78), atan2(0.0, side))
		kit.solid(bench, AABB(Vector3(-.65, 0, -.25), Vector3(1.3, 1.33, .52)), true)
	_pb_meal(group, Vector3(0, PB_TABLE_TOP, -.19), PI, "pizza" if n % 2 == 0 else "hamburger")
	_pb_meal(group, Vector3(0, PB_TABLE_TOP, .19), 0.0, "hamburger")
	kit.item("Ceiling light", "ceiling light", _pb_pendant_mesh(1.75), Vector3(0, 2.38, 0), 0.0, group)

## A glass-door drinks fridge on the rear wall, sodas on three shelves (each one a word). The
## fridge's pick areas cover its frame only and its blocker stops the player only, so the
## pointer reaches the bottles through the glass.
func _pb_drinks_fridge(burger: Node3D) -> void:
	var body := "2a2d33"
	var fridge: Node3D = kit.item("Drinks fridge", "refrigerator", kit.mesh_of("Drinks fridge", func() -> void:
		for side in [-1.0, 1.0]:
			art.bx(Vector3(side * .62, 1.05, 0), Vector3(.06, 2.1, .7), body, PB_ART.SATIN)
			art.bx(Vector3(side * .57, 1.0, -.34), Vector3(.04, 1.66, .03), PB_CHROME, PB_ART.METAL)
		art.bx(Vector3(0, 1.97, 0), Vector3(1.3, .26, .7), PB_RED, PB_ART.SATIN)
		art.bx(Vector3(0, .09, 0), Vector3(1.3, .18, .7), body, PB_ART.SATIN)
		art.bx(Vector3(0, 1.05, .32), Vector3(1.18, 1.7, .04), "e4eaee", PB_ART.SATIN)
		for y in [.2, .62, 1.1, 1.58]:
			art.bx(Vector3(0, y, 0), Vector3(1.18, .025, .6), PB_CHROME, PB_ART.METAL)
		art.bx(Vector3(0, .19, -.34), Vector3(1.18, .03, .03), PB_CHROME, PB_ART.METAL)
		art.bx(Vector3(0, 1.83, -.34), Vector3(1.18, .03, .03), PB_CHROME, PB_ART.METAL)
		art.bx(Vector3(.48, 1.0, -.37), Vector3(.03, .5, .03), PB_CHROME, PB_ART.METAL)), Vector3(0, PB_FLOOR, 1.4), 0.0, burger)
	# Pick areas on the frame only: replace the whole-body area from kit.item.
	var whole := fridge.get_node("Interaction")
	fridge.remove_child(whole)
	whole.free()
	for part in [AABB(Vector3(-.65, 1.84, -.36), Vector3(1.3, .26, .72)), AABB(Vector3(-.65, 0, -.36), Vector3(1.3, .19, .72)),
			AABB(Vector3(-.66, 0, -.36), Vector3(.08, 2.1, .72)), AABB(Vector3(.58, 0, -.36), Vector3(.08, 2.1, .72))]:
		kit.pick_area(fridge, part)
	kit.solid(fridge, AABB(Vector3(-.65, 0, -.35), Vector3(1.3, 2.1, .7)), true)
	var pane := MeshInstance3D.new()
	pane.name = "Glass door"
	var sheet := BoxMesh.new()
	sheet.size = Vector3(1.1, 1.62, .01)
	pane.mesh = sheet
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(.8, .92, .95, .18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = .1
	pane.material_override = glass
	pane.position = Vector3(0, 1.01, -.345)
	fridge.add_child(pane)
	var label := Label3D.new()
	label.name = "DRINKS sign"
	label.text = "DRINKS"
	label.font_size = 48
	label.pixel_size = .22 / 48.0
	label.outline_size = 0
	label.modulate = Color("ffffff")
	label.position = Vector3(0, 1.97, -.356)
	label.rotation.y = PI
	fridge.add_child(label)
	var k := 0
	for y in [.2125, .6325, 1.1125]:
		for x in [-.42, -.14, .14, .42]:
			_pb_food(fridge, "bottle", "soda", Vector3(x, y, -.05), 0.0, PB_SODAS[k % 4])
			k += 1

## Entry mat and two planters inside the door, two more by the rear wall.
func _pb_entrance(burger: Node3D, game) -> void:
	kit.box("Entry mat", Vector3(3.0, PB_FLOOR + .008, -7.05), Vector3(3.0, .016, 1.3), "55595f")
	for spot in [Vector3(.55, 0, -7.25), Vector3(5.45, 0, -7.25), Vector3(1.4, 0, 1.25), Vector3(12.5, 0, 1.25)]:
		var pot: Node3D = game.cylinder("Planter", Vector3(spot.x, PB_FLOOR + .3, spot.z), .3, .6, Color("c96f4a"), "planter", true)
		pot.reparent(burger, false)
		var leaves: Node3D = game.sphere("Plant", Vector3(spot.x, PB_FLOOR + 1.0, spot.z), .42, Color("4f8f3a"), "plant", false)
		leaves.reparent(burger, false)
		leaves.scale = Vector3(1, 1.25, 1)

## ORDER HERE board hanging over the register.
func _pb_order_sign(burger: Node3D) -> void:
	var board := Node3D.new()
	board.name = "ORDER HERE sign board"
	burger.add_child(board)
	board.position = Vector3(-2.4, 3.05, 1.0)
	var panel := MeshInstance3D.new()
	panel.mesh = kit.mesh_of("Order sign", func() -> void:
		art.bx(Vector3(0, 0, 0), Vector3(1.7, .42, .05), PB_RED, PB_ART.SATIN)
		art.bx(Vector3(0, -.2, 0), Vector3(1.7, .03, .06), "f2c231", PB_ART.SATIN)
		for x in [-.7, .7]:
			art.cyl(Vector3(x, .75, 0), Vector3(.015, 1.1, .015), PB_DARK, PB_ART.SATIN, Vector3.ZERO, 6))
	board.add_child(panel)
	var label := Label3D.new()
	label.name = "ORDER HERE sign"
	label.text = "ORDER HERE"
	label.font_size = 48
	label.pixel_size = .26 / 48.0
	label.outline_size = 0
	label.modulate = Color("ffffff")
	label.position = Vector3(0, .02, -.03)
	label.rotation.y = PI
	board.add_child(label)

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "restaurants")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "restaurants", 2)

# ---------------------------------------------------------------- Alta Cocina game tables

## User request, 11 Nov 2026 (docs/guides/TOWN_DESIGN_BRIEF.md "Restaurant game: reception, tables and
## order tablet"), in the Alta Cocina frame (Restaurants/Pizza, entrance side -Z):
## 1. the "textures and more" poster comes down (the game no longer asks for textures or
##    extras); the tastes poster moves to x 5.5, centred over the kitchen pass;
## 2. a menu table beside the host stand, west of it and clear of the entrance path, with an
##    open menu book on a tilted stand facing the room (RestaurantMenuBook, word "menu";
##    restaurant_session.gd opens the menu book screen when it is used);
## 3. a second customer place, RestaurantCustomerSeat2, on the chair north of the east
##    table (5, -4.6), facing the table and the entrance (the first stays in the west booth).
const MENU_TABLE := Vector3(-5.7, .09, -5.3)
const MENU_TABLE_YAW := -PI / 2
const SEAT_2 := Vector3(5.0, .56, -3.65)
const TASTES_POSTER_X := 5.5

func dining_game_tables(town: Node3D, game) -> void:
	var room: Node3D = town.get_node(ROOM)
	var textures := room.get_node_or_null("Restaurant poster textures")
	if textures != null:
		room.remove_child(textures)
		textures.free()
	else:
		push_error("restaurants: textures poster not found")
	var tastes := room.get_node_or_null("Restaurant poster tastes") as Node3D
	if tastes != null:
		tastes.position.x = TASTES_POSTER_X
	kit = PB_KIT.new()
	kit.g = game
	kit.room = room
	kit.art = PB_ART.new()
	art = kit.art
	_menu_table(room)
	var seat := Node3D.new()
	seat.name = "RestaurantCustomerSeat2"
	seat.set_meta("back_distance", .2)
	room.add_child(seat)
	seat.position = SEAT_2

## A dark wood bistro table with a brass rim and, on a tilted stand, an open burgundy menu book
## with four ribbon bookmarks (the course colours of the menu book screen). Local front (the
## reader's side) is -Z; the yaw turns it to face east, where the reader stands between it and
## the host stand.
func _menu_table(room: Node3D) -> void:
	var group := Node3D.new()
	group.name = "Menu table"
	room.add_child(group)
	group.position = MENU_TABLE
	group.rotation.y = MENU_TABLE_YAW
	var table_mesh: ArrayMesh = kit.mesh_of("Menu table", func() -> void:
		art.cyl(Vector3(0, .02, 0), Vector3(.62, .04, .62), "2a1a12", PB_ART.SATIN, Vector3.ZERO, 20)
		art.cyl(Vector3(0, .07, 0), Vector3(.34, .06, .34), "c9a25a", PB_ART.METAL, Vector3.ZERO, 16)
		art.cyl(Vector3(0, .46, 0), Vector3(.1, .76, .1), "3a2418", PB_ART.SATIN, Vector3.ZERO, 12)
		art.cyl(Vector3(0, .86, 0), Vector3(.2, .04, .2), "3a2418", PB_ART.SATIN, Vector3.ZERO, 14)
		art.cyl(Vector3(0, .9, 0), Vector3(.84, .045, .84), WOOD.to_html(false), PB_ART.SATIN, Vector3.ZERO, 28)
		art.ring(Vector3(0, .9, 0), Vector3(.86, .05, .86), RAIL.to_html(false), PB_ART.METAL, Vector3.ZERO, .96, 28))
	var table: Node3D = kit.item("Table", "table", table_mesh, Vector3.ZERO, 0.0, group)
	kit.solid(table, AABB(Vector3(-.42, 0, -.42), Vector3(.84, .93, .84)), true)
	# The stand and book: the stand's ledge at the front, the book leaning back 28 degrees.
	var tilt := Vector3(deg_to_rad(28.0), 0, 0)
	var book_mesh: ArrayMesh = kit.mesh_of("Menu book on stand", func() -> void:
		art.bx(Vector3(0, .935, -.12), Vector3(.5, .03, .05), "c9a25a", PB_ART.METAL)
		art.bx(Vector3(0, 1.04, .03), Vector3(.06, .22, .03), "c9a25a", PB_ART.METAL, Vector3(deg_to_rad(28.0), 0, 0))
		var centre := Vector3(0, 1.06, -.04)
		var lean := Basis.from_euler(tilt)
		# Cover (burgundy, gold edge), then the two page blocks in a shallow V.
		art.bx(centre + lean * Vector3(0, 0, .0), Vector3(.62, .4, .016), "6e2a22", PB_ART.SATIN, tilt)
		art.bx(centre + lean * Vector3(0, 0, -.006), Vector3(.635, .415, .008), "d9b26a", PB_ART.METAL, tilt)
		for side in [-1.0, 1.0]:
			art.bx(centre + lean * Vector3(side * .148, 0, -.024), Vector3(.28, .37, .022), "fbf5e6", PB_ART.MATTE, tilt + Vector3(0, side * .1, 0))
			# Text lines and a picture on each page (dark ink strokes).
			for k in 5:
				art.bx(centre + lean * Vector3(side * .148, .12 - k * .055, -.037), Vector3(.2 if k % 2 == 0 else .15, .012, .004), "8b7a64", PB_ART.MATTE, tilt + Vector3(0, side * .1, 0))
		art.bx(centre + lean * Vector3(0, 0, -.03), Vector3(.012, .38, .012), "d8ccb0", PB_ART.MATTE, tilt)
		# Ribbon bookmarks hanging over the bottom edge, in the screen's course colours.
		var ribbons := ["9fd39a", "f0c96a", "e8a0a0", "8fc3e8"]
		for k in 4:
			art.bx(centre + lean * Vector3(.05 + k * .035, -.23, -.026), Vector3(.022, .1, .004), ribbons[k], PB_ART.SATIN, tilt))
	kit.item("RestaurantMenuBook", "menu", book_mesh, Vector3.ZERO, 0.0, group)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "restaurants")


## Transparent panes the first pass missed (auto-named under a room; 12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate_leftovers(town, "restaurants")


## The Alta Cocina facade's two arched windows are dark glass (user, 12 Nov 2026: "i like the
## black"). glass_windows turned one of them ("Window pane/Glass") into the shared light blue-gray glass;
## the other, auto-named, kept its original colour. Give the window that colour back: opaque (it sits
## on the front wall), tint = the original pane colour, transparency 0 so the tint is used as is.
const FINE_DINING_GLASS := Color(0.1686, 0.1961, 0.2196)

func fine_dining_dark_glass(town: Node3D, _game) -> void:
	var window := town.get_node_or_null("Map facades/FINE DINING/Window pane/Glass")
	if window == null or not "tint" in window:
		push_error("restaurants: fine dining facade window not found")
		return
	window.see_through = false
	window.transparency = 0.0
	window.tint = FINE_DINING_GLASS


## The first bake of fine_dining_dark_glass looked for the window one level too high and changed
## nothing (it is recorded as applied); this step runs it again with the corrected path.
func fine_dining_dark_glass_2(town: Node3D, game) -> void:
	fine_dining_dark_glass(town, game)


## Real arched windows in the Alta Cocina front (user, 12 Nov 2026: "i want real window";
## docs/guides/WINDOWS.md). Before: the facade's dark glass sat on the solid front wall, and inside a
## painted view (lawn, river, bridge, towers, tree) hung on the wall behind clear glass.
## Room frame (Restaurants/Pizza): windows centred x = ±8.5, glass x ±6.5..±10.5, y .6..3.9 plus
## a half disc of radius 2 centred y 3.9; front wall z -8.0..-7.75, its lining z -7.74..-7.70,
## facade glass z -8.12..-8.08, inside glass z -7.698..-7.69.
## 1. arched holes through the front wall and its lining (meshes only: the wall collision stays,
##    so the closed windows still block walking and pointing);
## 2. the painted view pieces are removed (12 meshes, no words);
## 3. one-way glass: the facade panes are dark (the black the user likes), drawn only from the
##    street; the inside panes are the shared clear glass, drawn only from the room.
const WINDOW_CENTRES := [-8.5, 8.5]
const VIEW_COLOURS := ["8fbf6b", "8fb8d6", "b9b2a6", "a39a8e", "4f8a3c"]
## 0 = solid colour: the street side stays nearly black, with the lit room faintly behind it.
const FACADE_GLASS_TRANSPARENCY := 0.25

## First bake: the CSG cut built no mesh (CSG updates a frame later) and the painted-view loop
## stopped after freeing a holder, so only part of the view was removed; step _2 does the rest.
func fine_dining_real_windows(town: Node3D, _game) -> void:
	_real_windows(town)

## Second bake: holes cut and the view gone, but the glass loop measured a pane that replace() had
## just freed and stopped; step _3 sets up the glass alone.
func fine_dining_real_windows_2(town: Node3D, _game) -> void:
	_real_windows(town)

func fine_dining_real_windows_3(town: Node3D, _game) -> void:
	_one_way_glass(town)

func _real_windows(town: Node3D) -> void:
	var room: Node3D = town.get_node(ROOM)
	var facade: Node3D = town.get_node("Map facades/FINE DINING")
	var to_room := room.global_transform.affine_inverse()
	var in_room := func(node: GeometryInstance3D) -> AABB:
		return to_room * (node.global_transform * node.get_aabb())
	# 1. Holes.
	var walls := []
	for mesh in room.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = in_room.call(mesh)
		if mesh.mesh is BoxMesh and box.size.x > 12.0 and box.size.y > 6.4 and box.position.z > -8.01 and box.end.z < -7.69:
			walls.append(mesh)
	if walls.size() != 4:
		push_error("restaurants: expected 4 front wall meshes (wall and lining), found %d" % walls.size())
		return
	for mesh in walls:
		_cut_arch_windows(mesh, room)
	# 2. Painted view (holders collected first: freeing one frees the meshes under it).
	var view := {}
	for mesh in room.find_children("*", "MeshInstance3D", true, false):
		var mat := mesh.material_override as BaseMaterial3D
		var box: AABB = in_room.call(mesh)
		if mat == null or not mat.albedo_color.to_html(false) in VIEW_COLOURS:
			continue
		if box.position.z < -7.71 or box.end.z > -7.65 or absf(box.get_center().x) < 6.4 or absf(box.get_center().x) > 10.6:
			continue
		view[mesh.get_parent() if String(mesh.name).begins_with("@") and mesh.get_parent() != room else mesh] = true
	for holder in view:
		holder.get_parent().remove_child(holder)
		holder.free()
	print("restaurants: removed %d painted view pieces" % view.size())
	_one_way_glass(town)


## 3. One-way glass. Panes not yet windows (auto-named) become windows first.
func _one_way_glass(town: Node3D) -> void:
	var room: Node3D = town.get_node(ROOM)
	var facade: Node3D = town.get_node("Map facades/FINE DINING")
	var to_room := room.global_transform.affine_inverse()
	var GlassWindows := preload("res://scripts/buildings/glass_windows.gd")
	var GlassWindow := preload("res://scripts/world/glass_window.gd")
	for side in [[room, -7.694, true], [facade, -8.1, false]]:
		var holder: Node3D = side[0]
		# Found first, replaced after: replace() frees the pane and its arch disc.
		var panes := []
		for mesh in holder.find_children("*", "MeshInstance3D", true, false):
			if not mesh.mesh is BoxMesh or mesh.has_meta(GlassWindow.PART_META):
				continue
			var box: AABB = to_room * (mesh.global_transform * mesh.get_aabb())
			if absf(box.get_center().z - side[1]) < 0.02 and is_equal_approx(box.size.x, 4.0) and absf(box.size.y - 3.3) < 0.01:
				panes.append(mesh)
		for mesh in panes:
			GlassWindows.replace(mesh, true)
		var windows := []
		for w in holder.find_children("*", "Node3D", true, false):
			if w.get_script() == GlassWindow:
				var at: Vector3 = to_room * w.global_position
				if absf(at.z - side[1]) < 0.03 and WINDOW_CENTRES.any(func(x: float) -> bool: return absf(at.x - x) < 0.1):
					windows.append(w)
		if windows.size() != 2:
			push_error("restaurants: expected 2 arched windows at z %.3f, found %d" % [side[1], windows.size()])
			continue
		for w in windows:
			w.see_through = true
			# (Baked 12 Nov 2026 with the export one_way = true, removed 13 Nov: see fine_dining_single_glass.)
			if side[2]:
				w.tint = GlassWindow.DEFAULT_TINT
				w.transparency = GlassWindow.DEFAULT_TRANSPARENCY
			else:
				w.tint = FINE_DINING_GLASS
				w.transparency = FACADE_GLASS_TRANSPARENCY
			# +Z (the drawn side) faces the room for the inside panes, the street for the facade.
			var facing: float = (to_room.basis * w.global_transform.basis.z).z
			if (facing < 0.0) == side[2]:
				w.transform.basis = w.transform.basis * Basis(Vector3.UP, PI)


## Cuts the two arched window holes out of one front wall box (its material kept).
func _cut_arch_windows(mesh: MeshInstance3D, room: Node3D) -> void:
	var size: Vector3 = (mesh.mesh as BoxMesh).size
	var csg := CSGCombiner3D.new()
	mesh.add_child(csg)
	var body := CSGBox3D.new()
	body.size = size
	csg.add_child(body)
	# Hole shapes are placed in the room frame, then expressed in the mesh's frame.
	var from_room := mesh.global_transform.affine_inverse() * room.global_transform
	for x in WINDOW_CENTRES:
		var rect := CSGBox3D.new()
		rect.operation = CSGShape3D.OPERATION_SUBTRACTION
		rect.size = Vector3(4.0, 3.3, 1.0)
		rect.transform = from_room * Transform3D(Basis.IDENTITY, Vector3(x, 2.25, -7.85))
		csg.add_child(rect)
		var arch := CSGCylinder3D.new()
		arch.operation = CSGShape3D.OPERATION_SUBTRACTION
		arch.radius = 2.0
		arch.height = 1.0
		arch.sides = 32
		arch.transform = from_room * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, 3.9, -7.85))
		csg.add_child(arch)
	csg.call("_update_shape")   # CSG builds its mesh a frame later otherwise
	var baked: ArrayMesh = csg.bake_static_mesh()
	mesh.remove_child(csg)
	csg.free()
	if baked == null or baked.get_surface_count() == 0:
		push_error("restaurants: window cut failed on " + str(mesh.name))
		return
	baked.resource_name = "Alta Cocina front wall with windows"
	mesh.mesh = baked


## One glass sheet per arched window (user, 13 Nov 2026; docs/guides/WINDOWS.md): the shared glass shader
## now draws the outdoors face dark and reflective and the room face clear, so the two one-way
## layers become one. The room-side panes (z -7.694) are removed; the facade panes (z -8.1, +Z
## already toward the street) keep the dark tint as their outdoors face.
## The first bake set the facade panes and removed one room pane, then stopped on the freed parts
## of that pane; _2 runs it again (now collecting the windows first) to remove the other.
func fine_dining_single_glass(town: Node3D, _game) -> void:
	_single_glass(town)

func fine_dining_single_glass_2(town: Node3D, _game) -> void:
	_single_glass(town)

func _single_glass(town: Node3D) -> void:
	var GlassWindow := preload("res://scripts/world/glass_window.gd")
	var room: Node3D = town.get_node(ROOM)
	var to_room := room.global_transform.affine_inverse()
	var kept := 0
	var removed := 0
	var windows := (town.get_node("Map facades/FINE DINING").find_children("*", "Node3D", true, false)
		+ room.find_children("*", "Node3D", true, false)).filter(func(n: Node) -> bool: return n.get_script() == GlassWindow)
	for w in windows:
		var at: Vector3 = to_room * w.global_position
		if not WINDOW_CENTRES.any(func(x: float) -> bool: return absf(at.x - x) < 0.1):
			continue
		if absf(at.z + 7.694) < 0.02:
			w.get_parent().remove_child(w)
			w.free()
			removed += 1
		elif absf(at.z + 8.1) < 0.02:
			var to_street: bool = (to_room.basis * w.global_transform.basis.z).z < 0.0
			w.see_through = true
			w.tint = GlassWindow.DEFAULT_TINT
			w.transparency = GlassWindow.DEFAULT_TRANSPARENCY
			w.outside = GlassWindow.Outside.FRONT if to_street else GlassWindow.Outside.BACK
			w.outside_tint = FINE_DINING_GLASS
			w.outside_transparency = GlassWindow.DEFAULT_OUTSIDE_TRANSPARENCY
			kept += 1
	print("restaurants: single glass: %d facade panes set, %d room panes removed" % [kept, removed])
	if kept != 2:
		push_error("restaurants: expected 2 facade panes, got %d" % kept)

## Facade signs too short for their lettering (user, 23 Nov 2026: letters ran over the edges of
## the Pizza and Burger and Taquería boards). The lettering becomes a world sign
## (scripts/world/world_sign.gd) with a street-reading letter height, and the board grows
## (WorldSign.fit_board) so there is free board above and below the text; the frame keeps its
## border round the face and stays under the cornice. Town units; world metres in the specs.
const FACADE_SIGNS := [
	# facade, face, frame, lettering, frame top limit (town y), icon x range (town, free width)
	["Map facades/PIZZA AND BURGER", "Sign face", "Sign frame", "PIZZA AND BURGER lettering", 3.99, 11.0],
	["Map facades/TAQUERÍA", "Sign face", "Sign frame", "Facade lettering", 4.70, 11.6],
]
const SIGN_EM := 0.9          # letter height, world metres (readable from about 27 m)
const SIGN_MARGIN := 0.08     # free board above and below the line box, world metres
const SIGN_BORDER := 0.1      # frame border round the face, town units

func facade_sign_padding(town: Node3D, _game) -> void:
	var WorldSign := preload("res://scripts/world/world_sign.gd")
	for spec in FACADE_SIGNS:
		var facade: Node3D = town.get_node(spec[0])
		var face := _mesh_in(facade.get_node(spec[1]))
		var frame := _mesh_in(facade.get_node(spec[2]))
		var label := facade.get_node(spec[3]) as Label3D
		var scale := label.global_transform.basis.get_scale().y
		WorldSign.restyle(label, {"read": SIGN_EM * WorldSign.READ_RATIO, "em": SIGN_EM,
			"board": WorldSign.board_colour(face), "fit_width": float(spec[5]) * scale})
		WorldSign.fit_board(face, label, SIGN_MARGIN)
		var face_h := face.get_aabb().size.y * face.scale.y
		var frame_mesh_h := frame.get_aabb().size.y
		var centre: float = (frame.get_parent() as Node3D).position.y
		var frame_h := minf(face_h + 2.0 * SIGN_BORDER, 2.0 * (float(spec[4]) - centre))
		frame.scale.y = frame_h / frame_mesh_h
		print("restaurants: %s face %.2f high, frame %.2f, letters %.2f m" % [spec[0], face_h, frame_h, WorldSign.em_of(label)])

func _mesh_in(node: Node) -> MeshInstance3D:
	return node if node is MeshInstance3D else node.find_children("*", "MeshInstance3D", false, false)[0]

## The Pizza and Burger entrance was an open gap behind two decorative glass doors (user, 23 Nov
## 2026). The shared double door (scenes/props/double_door.tscn, docs/guides/DOORS.md) now fills
## it: glass leaves in the facade green, swinging into the shop. Opening in Burger coordinates:
## x 1.32..4.68 (the facade posts' inner faces), floor y .10 to the header at 3.0, from the inner
## wall face (z -7.75) to the facade face (z -8.17). The old facade door parts are removed.
const PB_DOOR_GREEN := Color("0d4a37")

func pizza_burger_door(town: Node3D, game) -> void:
	var facade: Node3D = town.get_node("Map facades/PIZZA AND BURGER")
	var removed := 0
	for part in facade.get_children():
		var at := (part as Node3D).position if part is Node3D else Vector3.ZERO
		var door_part := String(part.name).begins_with("Door ") and not String(part.name).begins_with("Door lantern")
		var unnamed_door_part := String(part.name).begins_with("@") and at.x > -105.9 and at.x < -102.1 and at.y < 3.3 and absf(at.z - 76.9) < 0.05
		if door_part or unnamed_door_part:
			game.doors.erase(part)
			facade.remove_child(part)
			part.free()
			removed += 1
	var burger: Node3D = town.get_node(PB)
	var door: Node3D = preload("res://scenes/props/double_door.tscn").instantiate()
	door.name = "Pizza and Burger entrance"
	door.width = 3.36
	door.height = 2.9
	door.wall_thickness = 0.42
	door.leaf_name = "Pizza and Burger entrance door"
	door.leaf_color = PB_DOOR_GREEN
	door.frame_color = PB_DOOR_GREEN
	door.frame_width = 0.14
	door.handle_color = Color(PB_CHROME)
	door.vision_glass = true
	door.swing_to_front = true   # +z: into the shop
	door.position = Vector3(3.0, PB_FLOOR, -7.96)
	burger.add_child(door, true)
	door.owner = burger.owner
	print("restaurants: Pizza and Burger entrance door, %d old facade door parts removed" % removed)

## The taquería waiter (CatWaiter) held a serving tray and a glass in front of his face (user,
## 23 Nov 2026). No carried pose exists for plush staff, so the tray and glass are removed (the
## words tray and glass stay in the town elsewhere).
func taqueria_tray(town: Node3D, game) -> void:
	var taqueria: Node3D = town.get_node("Restaurants/Cafe/Taqueria")
	for title in ["Serving tray", "Tray glass"]:
		var node := taqueria.get_node_or_null(title)
		if node == null:
			push_error("restaurants: no %s in the Taqueria" % title)
			continue
		taqueria.remove_child(node)
		node.free()

## Door sounds (user, 25 Nov 2026: "each door should have different sound"): the Pizza and
## Burger glass double door rings a shop bell (door.gd sound "glass"; cues door.glass.* in
## data/sounds.json).
func door_sounds(town: Node3D, game) -> void:
	var DoorAnimator := preload("res://scripts/core/door_animator.gd")
	var door := town.get_node(PB).get_node_or_null("Pizza and Burger entrance")
	if not DoorAnimator.set_sound_kind(game, door, "glass"):
		push_error("restaurants door_sounds: no Pizza and Burger entrance")
		return
	print("RESTAURANTS door_sounds: 1 door")


## Colours snapped to the game palette with the hue guard (P3-22, decision D14: approved by the
## user 26 Nov 2026 after the library/police trial; scripts/buildings/palette_snap.gd,
## docs/evidence/pastel-20261125/).
func palette_snap(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/palette_snap.gd").snap(town, "restaurants")
