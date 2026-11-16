extends RefCounted
## Home interiors refit (user review, 13 Nov 2026: "go through the house ... make the interior
## feel consistent and nice"; record: docs/guides/REFERENCE_HOME.md "Bigger home"). Used once by the
## home step `house_furnishing` (scripts/buildings/home.gd), after `house_expansion` (layout and
## the 1.8x height). Site coordinates as in home_expansion.gd (+Z street side, -Z backyard).
##   - Bathrooms (guest suite x -11..-5 z -3..3, family x -11..-5 z 3..11, east wing x 18.4..26
##     z 7.5..14): the box-built tubs, vanities, tiles and showers are replaced by BathFixtures
##     models in the toilets' rounded look: an alcove tub with water, a brass tub faucet and
##     shower set, and a shower curtain on an L-rail that E / a click draws and pulls back
##     (door_animator.gd "curtain"); a wall-hung vanity with vessel basin, faucet and mirror; a
##     towel rail, roll holder, bath mat and tiled floor. The family and east baths keep a walk-in
##     shower (framed glass). Every fixture stands clear of the door swings.
##   - Bedrooms: the box beds, bedside cabinets and cylinder lamps become the game's bed,
##     nightstand, bedside lamp and pillow models with a soft blanket; the yellow bedroom's box
##     wardrobe becomes the wardrobe model on its solid front wall.
##   - Curtains (word curtain) at the bedroom and study windows; a ceiling lamp under each room light.
const BathFixtures := preload("res://scripts/world/bath_fixtures.gd")
const Geo := preload("res://scripts/buildings/monument_plaza.gd").Geo
const Expansion := preload("res://scripts/buildings/home_expansion.gd")
const VOCAB := "res://scenes/props/vocabulary/%s.tscn"
const HOME_PROPS := "res://scenes/props/home/%s.tscn"
const TOP := Expansion.HOUSE_TOP
const BRASS := BathFixtures.BRASS
const TUB := Vector3(2.6, .7, 1.5)
## Curtain rail height (the plush characters stand about 3 tall).
const ROD_Y := 3.9
const VANITY := Vector3(1.5, .55, .7)
const VANITY_TOP := 1.05
const BASIN_SCALE := .75

var game
var site: Node3D
var removed := 0

func build(town: Node3D, main) -> void:
	game = main
	site = town.get_node("RelocatedSites/Home")
	suite_bath()
	family_bath()
	east_bath()
	BathFixtures.rebuild_toilets(site)
	for spot in [[-8.0, 14.0, 1.9, Color("e9c95c"), false], [-6.75, -10.25, 2.7, Color("7cabb2"), true], [20.5, -1.25, 2.7, Color("b9a3d6"), true]]:
		bed_set(spot[0], spot[1], spot[2], spot[3], spot[4])
	yellow_wardrobe()
	window_curtains()
	ceiling_lamps()
	raise_porch(town)
	clear_glass_shadows()
	print("house_furnishing: removed %d old nodes" % removed)

## Window glass lets the sun through: the older window parts (glazing boxes) cast a hard dark
## shadow over the sunny patch under the window (seen in the guest-suite bathroom).
func clear_glass_shadows() -> void:
	var count := 0
	for child in site.get_children():
		var title := String(child.name)
		if str(child.get_meta("word_key", "")) != "window" and not title.contains("lazing"): continue
		for mesh in child.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				count += 1
	print("house_furnishing: %d glass meshes no longer cast shadows" % count)

## The entrance porch (Map facades/HOME: canopy, lintel, two posts) was sized for the old
## 3 m front door; the door is now 5.4 m tall, so the lintel and canopy move up above its
## casing (cap top 5.37) and the posts grow to carry them. Bottoms stay on the ground.
func raise_porch(town: Node3D) -> void:
	var facade := town.get_node_or_null("Map facades/HOME")
	if facade == null: return
	var lift := 2.42
	for child in facade.get_children():
		if not child is Node3D: continue
		var node := child as Node3D
		var title := String(node.name)
		var mesh: MeshInstance3D = null
		for part in node.get_children():
			if part is MeshInstance3D: mesh = part
		if mesh == null: continue
		var box: AABB = mesh.transform * mesh.get_aabb()
		if title.contains("canopy") or title.contains("lintel"):
			node.position.y += lift
		elif box.size.y > 3.0 and box.size.x < .3 and box.size.z < .3 and box.size.y < 3.6:
			# A porch post (named or not): stretch from its foot to the raised canopy.
			var foot: float = node.position.y + box.position.y * node.scale.y
			var factor := (box.size.y + lift) / box.size.y
			node.scale.y *= factor
			node.position.y = foot - box.position.y * node.scale.y

# ------------------------------------------------------------------ bathrooms

## Guest suite bathroom (inside x -10.91..-5.09, z -2.91..2.91; door at z -3, x -8.86..-7.14,
## opening into the room): tub on the back wall with its taps at the west wall, vanity and
## toilet on the east wall, towel rail beside the door.
func suite_bath() -> void:
	var room := Rect2(-10.91, -2.91, 5.82, 5.82)
	clear_room(room)
	tile_floor(room)
	bathtub("Suite bathtub", Vector3(-9.61, 0, 2.91), PI, 1, Color("9fd3cf"), Color("f4f1e8"))
	bath_mat(Vector3(-9.6, 0, .8), 0.0, Color("8fc7c2"))
	BathFixtures.add_toilet(site, "Suite bathroom toilet", Vector3(-5.10, .03, 1.0), -PI / 2, "home")
	roll_holder(Vector3(-5.09, .95, 1.85), -PI / 2)
	vanity("Suite vanity", Vector3(-5.09, VANITY_TOP, -1.55), -PI / 2, Color("8fb9b5"))
	towel_rail(Vector3(-10.0, 1.75, -2.91), 0.0, Color("8fc7c2"))
	plant(Vector3(-6.3, 0, -2.4), .8)

## Family bathroom (inside x -10.91..-5.09, z 3.09..10.91; door at x -5, z 8.64..10.36): tub
## on the back wall (its shower set on that wall, clear of the west windows), vanity on the
## new partition, toilet on the west wall, walk-in shower in the east corner.
func family_bath() -> void:
	var room := Rect2(-10.91, 3.09, 5.82, 7.82)
	clear_room(room)
	tile_floor(room)
	bathtub("Family bathtub", Vector3(-9.61, 0, 10.91), PI, 1, Color("f0c86a"), Color("fbf6e9"), true)
	bath_mat(Vector3(-9.6, 0, 8.85), 0.0, Color("e8c46e"))
	var toilet: Node3D = site.get_node("Family bathroom toilet")
	toilet.position = Vector3(-10.90, .03, 3.9)
	toilet.rotation = Vector3(0, PI / 2, 0)
	roll_holder(Vector3(-10.91, .95, 4.75), PI / 2)
	vanity("Family vanity", Vector3(-8.4, VANITY_TOP, 3.09), 0.0, Color("d9b26a"))
	walk_in_shower("Family shower", Rect2(-6.81, 3.09, 1.72, 1.72), [[Vector2(-6.81, 3.09), Vector2(-6.81, 4.81)], [Vector2(-6.81, 4.81), Vector2(-6.0, 4.81)]], Vector3(-5.95, 1.2, 3.09), 0.0)
	towel_rail(Vector3(-5.09, 1.75, 6.4), -PI / 2, Color("e8c46e"))
	plant(Vector3(-5.6, 0, 7.6), .8)

## Family bathroom re-laid (user, 13 Nov 2026: in the tutorial's bathroom the shower curtain was
## seen edge-on from the doorway and the toilet was squeezed into the corner by the vanity). Used
## by the home step `family_bath_layout`, after `house_furnishing`. The tub moves to the west wall
## (under the north window, z 8.4..10.6; its taps and shower set at the north wall), so its
## curtain hangs across the room facing the door (x -5, z 8.64..10.36); the toilet stands with
## its cistern on the solid wall between the two west windows (z 6.6..8.4) facing the room, its
## roll holder beside it (it was in the corner by the vanity, z 3.9); the bath mat lies in front of the tub. The vanity, walk-in shower, towel rail
## and plant stay. Everything is clear of the door swing (x -6.72..-5, z 8.64..10.36).
const FAMILY_TOILET := Vector3(-10.90, .03, 6.9)
func relay_family_bath(town: Node3D, main) -> void:
	game = main
	site = town.get_node("RelocatedSites/Home")
	for title in ["Family bathtub", "Bath mat2"]:
		var old: Node = site.get_node_or_null(title)
		if old == null:
			push_error("family_bath_layout: no " + title)
			continue
		if game.get("doors") is Dictionary:
			for door in old.find_children("*", "", true, false):
				game.doors.erase(door)
		_free(old)
	bathtub("Family bathtub", Vector3(-10.91, 0, 9.61), PI / 2, -1, Color("f0c86a"), Color("fbf6e9"))
	bath_mat(Vector3(-8.9, 0, 9.6), PI / 2, Color("e8c46e"))
	var toilet: Node3D = site.get_node("Family bathroom toilet")
	toilet.position = FAMILY_TOILET
	toilet.rotation = Vector3(0, PI / 2, 0)
	var holder: Node3D = site.get_node("Toilet roll holder2")
	holder.position = Vector3(-10.91, .95, FAMILY_TOILET.z + .85)
	holder.rotation = Vector3(0, PI / 2, 0)
	print("family_bath_layout: tub on the west wall, toilet at z %.2f" % FAMILY_TOILET.z)

## The family bathroom's south-west window removed (user, 13 Nov 2026: "fix the issue with the
## toilet by removing the window"; the toilet's cistern touched that window's frame). Used by the
## home step `family_bath_window`. The window's parts in the opening (west wall x -11,
## z 4.4..6.6: glazing, three mullions, deep sill, the wall below and above it) are freed and the
## wall piece and skirting just south of it (z 3.0..4.4) are copied and stretched across the
## opening, so the wall is solid from z 3.0 to 8.4. The toilet moves to the middle of that wall
## (z 5.6) with its roll holder beside it. The north window over the tub stays.
const FAMILY_TOILET_SOLID := Vector3(-10.90, .03, 5.6)
func remove_family_bath_window(town: Node3D, main) -> void:
	game = main
	site = town.get_node("RelocatedSites/Home")
	var opening := Rect2(-11.25, 4.29, .5, 2.42)
	var doomed: Array = []
	var wall_piece: Node3D = null
	var skirting: Node3D = null
	for child in site.get_children():
		if not child is Node3D: continue
		var box := _site_bounds(child)
		if box.size == Vector3.ZERO: continue
		if box.position.x >= opening.position.x and box.end.x <= opening.end.x \
				and box.position.z >= opening.position.y and box.end.z <= opening.end.y:
			doomed.append(child)
		elif absf(box.position.z - 3.0) < .02 and absf(box.end.z - 4.4) < .02 and absf(box.get_center().x + 11.0) < .1:
			if str(child.get_meta("word_key", "")) == "wall": wall_piece = child
			elif box.end.y < .3: skirting = child
	if wall_piece == null or skirting == null or doomed.size() != 7:
		push_error("family_bath_window: expected 7 window parts and the wall south of it, found %d / %s / %s" % [doomed.size(), wall_piece, skirting])
		return
	for node in doomed:
		_free(node)
	for template in [wall_piece, skirting]:
		var copy: Node3D = template.duplicate()
		site.add_child(copy, true)
		copy.position.z = 5.5
		copy.scale.z = template.scale.z * 2.2 / 1.4
	var toilet: Node3D = site.get_node("Family bathroom toilet")
	toilet.position = FAMILY_TOILET_SOLID
	var holder: Node3D = site.get_node("Toilet roll holder2")
	holder.position = Vector3(-10.91, .95, FAMILY_TOILET_SOLID.z + .85)
	print("family_bath_window: %d window parts removed, wall closed, toilet at z %.2f" % [doomed.size(), FAMILY_TOILET_SOLID.z])

## East wing bathroom (inside x 18.49..25.91, z 7.59..13.91; door at x 18.4, z 9.64..11.36,
## opening into the room): tub on the bedroom wall with its taps at the east wall, toilet and
## vanity on the same wall beside it, walk-in shower in the hall corner, laundry on the study wall.
func east_bath() -> void:
	var room := Rect2(18.49, 7.59, 7.42, 6.32)
	clear_room(room, func(n): return String(n.name) in ["Washing machine", "Dryer", "Guest bathroom toilet"])
	tile_floor(room)
	bathtub("East bathtub", Vector3(24.61, 0, 7.59), 0.0, 1, Color("c9b8e6"), Color("f6f2fa"))
	bath_mat(Vector3(24.6, 0, 9.7), 0.0, Color("b9a3d6"))
	var toilet: Node3D = site.get_node("Guest bathroom toilet")
	toilet.position = Vector3(21.7, .03, 7.60)
	toilet.rotation = Vector3.ZERO
	roll_holder(Vector3(22.45, .95, 7.59), 0.0)
	vanity("East vanity", Vector3(19.95, VANITY_TOP, 7.59), 0.0, Color("a996c9"))
	walk_in_shower("East shower", Rect2(18.49, 12.19, 1.72, 1.72), [[Vector2(20.21, 12.19), Vector2(20.21, 13.91)], [Vector2(19.3, 12.19), Vector2(20.21, 12.19)]], Vector3(19.35, 1.2, 13.91), PI)
	towel_rail(Vector3(21.6, 1.75, 13.91), PI, Color("b9a3d6"))
	plant(Vector3(25.5, 0, 13.4), .8)

## Frees a bathroom's old furnishings: everything standing in `room` except walls, windows,
## doors, signs, lights, toilets (moved by the caller), the floor and what `keep` accepts.
func clear_room(room: Rect2, keep := func(_n): return false) -> void:
	var inner := room.grow(-.02)
	var doomed: Array = []
	for child in site.get_children():
		if not child is Node3D: continue
		var node := child as Node3D
		if not inner.has_point(Vector2(node.position.x, node.position.z)): continue
		if node is Light3D or Expansion.is_wall_piece(node) or Expansion.is_sign(node) or keep.call(node): continue
		if str(node.get_meta("word_key", "")) == "toilet" or String(node.name).ends_with("toilet"): continue
		if node.has_meta("door_state") or node.find_children("*", "", true, false).any(func(n): return n.has_meta("door_state")): continue
		var size := Expansion._box_size(node)
		if size != Vector3.ZERO and node.position.y + size.y / 2 < .031: continue
		doomed.append(node)
	for node in doomed:
		_free(node)

func _free(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()
	removed += 1

## Square tiles with grout over `room` (visual: the floor slab below stays the collider).
func tile_floor(room: Rect2) -> void:
	var g := Geo.new()
	var size := .6
	g.color = Color("c9cfcc")
	g.flat(Vector3(room.position.x, .032, room.position.y), Vector3(room.end.x, .032, room.position.y), Vector3(room.end.x, .032, room.end.y), Vector3.UP)
	g.flat(Vector3(room.position.x, .032, room.position.y), Vector3(room.end.x, .032, room.end.y), Vector3(room.position.x, .032, room.end.y), Vector3.UP)
	var cols := ceili(room.size.x / size)
	var rows := ceili(room.size.y / size)
	for i in cols:
		for j in rows:
			var x0 := room.position.x + i * size + .015
			var z0 := room.position.y + j * size + .015
			var x1 := minf(room.position.x + (i + 1) * size - .015, room.end.x)
			var z1 := minf(room.position.y + (j + 1) * size - .015, room.end.y)
			g.color = Color("f4f2ec") if (i + j) % 2 == 0 else Color("e9ece8")
			var y := .038
			g.flat(Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3.UP)
			g.flat(Vector3(x0, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1), Vector3.UP)
	var mesh := MeshInstance3D.new()
	mesh.name = "Bathroom tiles"
	mesh.mesh = g.commit()
	mesh.material_override = BathFixtures.finish("porcelain")
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	site.add_child(mesh, true)

## Root node at `pos` / `yaw` in the site.
func _root(title: String, pos: Vector3, yaw: float) -> Node3D:
	var root := Node3D.new()
	root.name = title
	site.add_child(root, true)
	root.position = pos
	root.rotation.y = yaw
	return root

func _mesh(parent: Node3D, title: String, mesh: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

## A collider box (centre, size in the parent's space); `word` makes the parent a word object.
func _body(parent: Node3D, center: Vector3, size: Vector3, word := "", solid := true) -> void:
	var body: CollisionObject3D = StaticBody3D.new() if solid else Area3D.new()
	parent.add_child(body)
	body.position = center
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = size
	body.add_child(shape)
	body.set_meta("object_name", String(parent.name))
	body.set_meta("root", parent)
	if word != "":
		parent.set_meta("word_key", word)
		body.set_meta("word", word)

## Alcove bathtub with its back edge's middle at `pos`; `head` (+1 / -1) is the local x end with
## the taps, shower set and the curtain's fixed end (against a side wall). `shower_on_back` puts
## the shower set on the back wall instead (when the end wall is a window).
func bathtub(title: String, pos: Vector3, yaw: float, head: int, curtain: Color, stripe: Color, shower_on_back := false) -> void:
	var root := _root(title, pos, yaw)
	root.set_meta("word_key", "bathtub")
	_mesh(root, "Tub", BathFixtures.bathtub_body(TUB), BathFixtures.finish("porcelain"))
	_body(root, Vector3(0, TUB.y / 2, TUB.z / 2), TUB, "bathtub")
	var water_y := TUB.y - .17
	var water := _mesh(root, "Bath water", BathFixtures.tub_water(TUB), BathFixtures.water_finish(), Vector3(0, water_y, TUB.z / 2))
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var end_x := head * (TUB.x / 2)
	BathFixtures.add_faucet(root, title + " faucet", Vector3(end_x - head * BathFixtures.TUB_WALL / 2, TUB.y, TUB.z / 2), -head * PI / 2, "home_basin", water_y)
	var shower := _mesh(root, "Shower set", BathFixtures.shower_set(ROD_Y - .2 - 1.25), BathFixtures.metal_finish(BRASS))
	if shower_on_back:
		shower.position = Vector3(end_x - head * .55, 1.25, 0)
	else:
		shower.position = Vector3(end_x, 1.25, TUB.z / 2)
		shower.rotation.y = -head * PI / 2
	# Bottles on the back rim at the foot end (one is the word "shampoo").
	for i in 2:
		var bottle := MeshInstance3D.new()
		bottle.name = "Shampoo bottle"
		var shape := CylinderMesh.new()
		shape.top_radius = .045
		shape.bottom_radius = .05
		shape.height = .24 - i * .05
		bottle.mesh = shape
		bottle.material_override = game.material_for([Color("f29e8e"), Color("7fb8d8")][i])
		var spot := Vector3(-head * (TUB.x / 2 - .22 - i * .14), TUB.y + shape.height / 2, BathFixtures.TUB_WALL / 2)
		if i == 0:
			var holder := Node3D.new()
			holder.name = "Shampoo"
			root.add_child(holder)
			holder.position = spot
			holder.add_child(bottle)
			_body(holder, Vector3.ZERO, Vector3(.12, shape.height, .12), "shampoo", false)
		else:
			root.add_child(bottle)
			bottle.position = spot
	# L-shaped rail: along the front from the head wall, then back to the wall at the foot.
	var front := TUB.z - BathFixtures.TUB_WALL / 2
	var g := Geo.new()
	g.color = Color.WHITE
	var r := Vector2(.025, .025)
	g.loft([Vector3(end_x, ROD_Y, front), Vector3(-end_x + head * .06, ROD_Y, front), Vector3(-end_x, ROD_Y, front - .06), Vector3(-end_x, ROD_Y, 0)], [r, r, r, r], Vector3.UP, 8)
	g.lathe(Vector3(end_x, ROD_Y - .06, front), [Vector2(0, 0), Vector2(.06, 0), Vector2(.06, .12), Vector2(0, .12)], 10)
	_mesh(root, "Curtain rail", g.commit(), BathFixtures.metal_finish(BathFixtures.CHROME))
	# The curtain: origin at the head wall, cloth along +X (turned round when the head is +X).
	var cloth := Node3D.new()
	cloth.name = "Shower curtain"
	root.add_child(cloth)
	cloth.position = Vector3(end_x, ROD_Y - .05, front)
	cloth.rotation.y = PI if head > 0 else 0.0
	var length := TUB.x - .04
	var height := ROD_Y - .05 - (TUB.y - .25)
	_mesh(cloth, "Curtain cloth", BathFixtures.shower_curtain(length, height, curtain, stripe), BathFixtures.cloth_finish())
	_body(cloth, Vector3(length / 2, -height / 2, 0), Vector3(length, height, .14))
	var state := {"open": false, "type": "curtain", "rest": .17, "drawn": 1.0}
	cloth.scale.x = state["rest"]
	cloth.set_meta("door_state", state)
	if game.get("doors") is Dictionary:
		game.doors[cloth] = state.duplicate(true)

func bath_mat(pos: Vector3, yaw: float, color: Color) -> void:
	var g := Geo.new()
	g.color = color
	BathFixtures._rounded_box(g, Vector3(0, .05, 0), Vector3(1.3, .025, .8), .012)
	var root := _root("Bath mat", pos, yaw)
	_mesh(root, "Mat", g.commit(), BathFixtures.cloth_finish())

## Wall-hung vanity: `pos` is on the wall face at the counter's height; its basin, faucet,
## toothbrush cup and perfume, and the mirror above.
func vanity(title: String, pos: Vector3, yaw: float, paint: Color) -> void:
	var root := _root(title, pos, yaw)
	_mesh(root, "Cabinet", BathFixtures.vanity_body(VANITY, paint), BathFixtures.finish("matte"))
	_mesh(root, "Knobs", BathFixtures.vanity_knobs(VANITY), BathFixtures.metal_finish(BRASS))
	_body(root, Vector3(0, -VANITY.y / 2, VANITY.z / 2), VANITY, "cabinet")
	var basin := Node3D.new()
	basin.name = title + " basin"
	root.add_child(basin)
	basin.position = Vector3(0, 0, .4)
	basin.scale = Vector3.ONE * BASIN_SCALE
	_mesh(basin, "Vessel basin", BathFixtures.vessel_basin(), BathFixtures.finish("porcelain"))
	_body(basin, Vector3(0, .09, 0), Vector3(.84, .18, .84), "sink", false)
	BathFixtures.add_faucet(root, title + " faucet", Vector3(0, 0, .07), 0.0, "home_basin", BathFixtures.VESSEL_FLOOR * BASIN_SCALE)
	var cup := Node3D.new()
	cup.name = "Toothbrush cup"
	root.add_child(cup)
	cup.position = Vector3(VANITY.x / 2 - .2, 0, .22)
	var glass := CylinderMesh.new()
	glass.top_radius = .05
	glass.bottom_radius = .045
	glass.height = .13
	_mesh(cup, "Cup", glass, game.material_for(Color("e7f2f4")), Vector3(0, .065, 0))
	var brush := BoxMesh.new()
	brush.size = Vector3(.025, .2, .025)
	var stick := _mesh(cup, "Toothbrush", brush, game.material_for(Color("3fa7d6")), Vector3(.01, .17, 0))
	stick.rotation.z = .2
	_body(cup, Vector3(0, .12, 0), Vector3(.12, .24, .12), "toothbrush", false)
	var perfume := Node3D.new()
	perfume.name = "Perfume"
	root.add_child(perfume)
	perfume.position = Vector3(-VANITY.x / 2 + .2, 0, .22)
	var bottle := BoxMesh.new()
	bottle.size = Vector3(.09, .13, .06)
	_mesh(perfume, "Bottle", bottle, game.material_for(Color("f0b7c8")), Vector3(0, .065, 0))
	var cap := CylinderMesh.new()
	cap.top_radius = .025
	cap.bottom_radius = .025
	cap.height = .05
	_mesh(perfume, "Cap", cap, BathFixtures.metal_finish(BRASS), Vector3(0, .155, 0))
	_body(perfume, Vector3(0, .09, 0), Vector3(.12, .18, .1), "perfume", false)
	# The mirror above.
	var mirror := Node3D.new()
	mirror.name = title + " mirror"
	root.add_child(mirror)
	mirror.position = Vector3(0, 1.05, 0)
	var size := Vector2(1.15, 1.55)
	_mesh(mirror, "Frame", BathFixtures.mirror_frame(size), BathFixtures.metal_finish(BRASS))
	var pane := BoxMesh.new()
	pane.size = Vector3(size.x - .1, size.y - .1, .02)
	_mesh(mirror, "Glass", pane, BathFixtures.mirror_glass_finish(), Vector3(0, 0, .025))
	_body(mirror, Vector3(0, 0, .03), Vector3(size.x, size.y, .06), "mirror", false)

func towel_rail(pos: Vector3, yaw: float, color: Color) -> void:
	var root := _root("Towel rail", pos, yaw)
	_mesh(root, "Rail", BathFixtures.towel_rail(.9), BathFixtures.metal_finish(BRASS))
	var towel := Node3D.new()
	towel.name = "Towel"
	root.add_child(towel)
	_mesh(towel, "Cloth", BathFixtures.hanging_towel(.7, .75, color), BathFixtures.cloth_finish())
	_body(towel, Vector3(0, -.3, .12), Vector3(.7, .75, .2), "towel", false)

func roll_holder(pos: Vector3, yaw: float) -> void:
	var root := _root("Toilet roll holder", pos, yaw)
	_mesh(root, "Holder", BathFixtures.roll_holder(), BathFixtures.metal_finish(BRASS))
	var roll := Node3D.new()
	roll.name = "Toilet paper"
	root.add_child(roll)
	_mesh(roll, "Roll", BathFixtures.toilet_roll(), BathFixtures.finish("matte"))
	_body(roll, Vector3(.07, 0, .1), Vector3(.16, .16, .16), "toilet paper", false)

## Walk-in shower: tray over `tray`, framed glass along `panes` (pairs of x/z points), shower
## set on the wall at `set_pos` facing yaw.
func walk_in_shower(title: String, tray: Rect2, panes: Array, set_pos: Vector3, yaw: float) -> void:
	var root := _root(title, Vector3(tray.get_center().x, 0, tray.get_center().y), 0.0)
	_mesh(root, "Tray", BathFixtures.shower_tray(tray.size), BathFixtures.finish("porcelain"))
	_body(root, Vector3(0, .05, 0), Vector3(tray.size.x, .1, tray.size.y))
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(.72, .87, .9, .28)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = .05
	glass_mat.metallic_specular = .9
	var frame_mat := BathFixtures.metal_finish(BathFixtures.CHROME)
	var height := ROD_Y - .1
	for pane in panes:
		var a: Vector2 = pane[0] - tray.get_center()
		var b: Vector2 = pane[1] - tray.get_center()
		var mid := (a + b) / 2
		var length := a.distance_to(b)
		var along_x := absf(b.x - a.x) > absf(b.y - a.y)
		var glass := BoxMesh.new()
		glass.size = Vector3(length, height - .1, .03) if along_x else Vector3(.03, height - .1, length)
		var pane_mesh := _mesh(root, "Shower glass", glass, glass_mat, Vector3(mid.x, .1 + (height - .1) / 2, mid.y))
		pane_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_body(root, Vector3(mid.x, height / 2, mid.y), glass.size)
		var top := BoxMesh.new()
		top.size = Vector3(length, .05, .06) if along_x else Vector3(.06, .05, length)
		_mesh(root, "Glass frame", top, frame_mat, Vector3(mid.x, height, mid.y))
		for end in [a, b]:
			var post := BoxMesh.new()
			post.size = Vector3(.05, height, .05)
			_mesh(root, "Glass frame", post, frame_mat, Vector3(end.x, height / 2, end.y))
	var fittings := _mesh(site, title + " set", BathFixtures.shower_set(ROD_Y - .2 - set_pos.y), BathFixtures.metal_finish(BRASS))
	fittings.position = set_pos
	fittings.rotation.y = yaw

func plant(pos: Vector3, size: float) -> void:
	var pot: Node3D = game.cylinder("Indoor ceramic planter", pos + Vector3(0, .22, 0) * size, .28 * size, .44 * size, Color("f7f3e9"), "", false)
	pot.reparent(site, false)
	for offset in [Vector3(-.17, .65, 0), Vector3(.16, .8, .08), Vector3(0, 1, -.1)]:
		var leaf: Node3D = game.sphere("Indoor foliage", pos + offset * size, .27 * size, Color("4e863e"), "", false)
		leaf.reparent(site, false)
		leaf.scale = Vector3(.65, 1.6, .65)

# ------------------------------------------------------------------ bedrooms

## Replaces a box bed set (home_expansion bed() / reference_home: bed centred at x, z, `width`
## wide, headboard toward -Z) by the bed, nightstand, bedside lamp and pillow models and a soft
## blanket in `color`, the head where the old head was.
func bed_set(x: float, z: float, width: float, color: Color, double: bool) -> void:
	var parts := [Vector3(0, .35, 0), Vector3(0, .72, 0), Vector3(0, .9, .35), Vector3(0, 1.05, -1.55)]
	for side in [-1.0, 1.0]:
		parts.append(Vector3(side * width * .23, .96, -1.02))
		parts.append(Vector3(side * (width / 2 + .5), .48, -1.1))
		parts.append(Vector3(side * (width / 2 + .5), 1.14, -1.1))
	var doomed: Array = []
	for child in site.get_children():
		if child is Node3D and parts.any(func(p): return (child as Node3D).position.distance_to(Vector3(x, 0, z) + p) < .04):
			doomed.append(child)
	if doomed.size() != parts.size():
		push_error("house_furnishing: bed at %s: %d of %d old parts found" % [Vector2(x, z), doomed.size(), parts.size()])
	for node in doomed:
		_free(node)
	var head := z - 1.625
	var s := 1.4 if double else 1.15
	var bed := _prefab(VOCAB % "bed", "Bed", Vector3(x, 0, 0), PI, s)
	var b := _site_bounds(bed)
	bed.position.z += head + .02 - b.position.z
	var mattress := _site_bounds(bed.get_node("Mattress"))
	var top := mattress.end.y
	var w := b.size.x
	var length := b.size.z
	for side in [-1.0, 1.0]:
		var pillow := _prefab(VOCAB % "pillow", "Pillow", Vector3(x + side * w * .23, top - .03, head + .2 * s + .42), PI, 1.1 if double else 1.0)
		pillow.rotation.x = -.18
		var stand := _prefab(VOCAB % "nightstand", "Nightstand", Vector3(x + side * (w / 2 + .62), 0, head + .52), PI, 1.25)
		var stand_top := _site_bounds(stand).end.y
		_prefab(HOME_PROPS % "bedside_lamp", "Bedside lamp", Vector3(x + side * (w / 2 + .62), stand_top, head + .5), PI, 1.4)
	# Blanket over the foot of the bed, with its folded-back top edge.
	var g := Geo.new()
	var blanket_len := length * .56
	g.color = color
	BathFixtures._rounded_box(g, Vector3(0, .06, 0), Vector3(w * .97, .12, blanket_len), .05)
	g.color = color.lightened(.25)
	BathFixtures._rounded_box(g, Vector3(0, .1, -blanket_len / 2 + .2), Vector3(w * .975, .12, .42), .05)
	var blanket := _root("Blanket", Vector3(x, top - .02, head + length - .06 - blanket_len / 2), 0.0)
	_mesh(blanket, "Cloth", g.commit(), BathFixtures.cloth_finish())
	_body(blanket, Vector3(0, .08, 0), Vector3(w * .97, .16, blanket_len), "blanket", false)

## Places a scene with uniform scale `s`, origin at `pos` (its bottom at pos.y), turned `yaw`.
func _prefab(path: String, title: String, pos: Vector3, yaw: float, s: float) -> Node3D:
	var node: Node3D = load(path).instantiate()
	node.name = title
	site.add_child(node, true)
	node.scale = Vector3.ONE * s
	node.rotation.y = yaw
	node.position = pos
	var b := _site_bounds(node)
	node.position.y += pos.y - b.position.y
	return node

## Bounds of a node's meshes in site space.
func _site_bounds(node: Node3D) -> AABB:
	var to_site := site.global_transform.affine_inverse()
	var result := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		var box: AABB = (to_site * mesh.global_transform) * mesh.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result

## The yellow bedroom's box wardrobe (in front of its window) becomes the wardrobe model on the
## solid front wall (z 17), clear of the bed and the door swing.
func yellow_wardrobe() -> void:
	var old: Node3D = site.get_node("Bedroom wardrobe")
	_free(old)
	var wardrobe := _prefab(VOCAB % "wardrobe", "Bedroom wardrobe", Vector3(-9.7, 0, 0), 0.0, 1.0)
	var b := _site_bounds(wardrobe)
	wardrobe.scale *= 2.6 / b.size.y
	b = _site_bounds(wardrobe)
	wardrobe.position += Vector3(0, -b.position.y, 16.9 - b.end.z)

# ------------------------------------------------------------------ curtains and lamps

## Window curtains (the curtain model, word curtain) inside the bedroom and study windows:
## wall point, inward direction, bottom height.
const WINDOWS := [
	[Vector2(-11, -7.5), Vector2(1, 0), 1.85], [Vector2(-6.75, -12), Vector2(0, 1), 2.25], [Vector2(-2.5, -9.0), Vector2(-1, 0), 1.85],
	[Vector2(24, -3), Vector2(0, 1), 1.85], [Vector2(26, 2.0), Vector2(-1, 0), 1.85],
	[Vector2(-11, 14.0), Vector2(1, 0), 1.85],
	[Vector2(21, 23), Vector2(0, -1), 1.85], [Vector2(26, 18.5), Vector2(-1, 0), 1.95],
]
func window_curtains() -> void:
	for spec in WINDOWS:
		var wall: Vector2 = spec[0]
		var inward: Vector2 = spec[1]
		var bottom: float = spec[2]
		var node: Node3D = load(HOME_PROPS % "curtains").instantiate()
		node.name = "Window curtains"
		site.add_child(node, true)
		node.rotation.y = atan2(-inward.x, -inward.y)
		node.scale = Vector3(3.0 / 2.25, (5.35 - bottom) / 1.95, 1.3)
		var p := wall + inward * .26
		node.position = Vector3(p.x, 0, p.y)
		var b := _site_bounds(node)
		node.position.y = bottom - b.position.y

## A flush ceiling lamp (warm glowing dome on a brass ring) above every room light.
func ceiling_lamps() -> void:
	for p in [Vector3(-8, 0, 7), Vector3(17.2, 0, 10.5)]:
		var light := OmniLight3D.new()
		light.name = "Room light"
		site.add_child(light, true)
		light.position = Vector3(p.x, TOP - 1.0, p.z)
		light.light_color = Color("ffe8be")
		light.light_energy = .8
		light.omni_range = 11
	var g := Geo.new()
	g.color = Color.WHITE
	g.lathe(Vector3.ZERO, [Vector2(0, -.2), Vector2(.3, -.17), Vector2(.42, -.08), Vector2(.46, 0)], 20)
	var dome := g.commit()
	var ring := Geo.new()
	ring.color = Color.WHITE
	ring.lathe(Vector3.ZERO, [Vector2(.46, 0), Vector2(.5, -.02), Vector2(.5, -.05), Vector2(.46, -.06)], 20)
	var ring_mesh := ring.commit()
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("fff3da")
	glow.emission_enabled = true
	glow.emission = Color("ffe9c4")
	glow.emission_energy_multiplier = 1.4
	var footprint := Rect2(-11.7, -12.7, 38.4, 36.4)
	for light in site.get_children().filter(func(n): return n is OmniLight3D):
		var spot: Vector3 = (light as Node3D).position
		if not footprint.has_point(Vector2(spot.x, spot.z)): continue
		var lamp := _root("Ceiling lamp", Vector3(spot.x, TOP - .005, spot.z), 0.0)
		for part in [_mesh(lamp, "Shade", dome, glow), _mesh(lamp, "Ring", ring_mesh, BathFixtures.metal_finish(BRASS))]:
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
