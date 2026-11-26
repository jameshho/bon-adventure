extends RefCounted
## Sports store own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); the store is saved in
## scenes/town/sports.scn. Shell 14 x 24 (unchanged since 28 Oct 2026): store-local walls
## x = +-6.9, z = +-11.9, door gap |x| < 1.8 on -Z, floor top 0.04, ceiling 4.57. Seen from the
## door, +X is on the LEFT.
##
## interior_refit (9 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"): the 28 Oct fit-out
## (625 loose parts) is replaced by zoned fixtures. Every visible sports item is a word root
## with its own pick area; repeated items reuse the vocabulary prefabs (scenes/props/vocabulary,
## models in sports_props.gd); shelving and table blockers are on FIGURE_LAYER (they stop the
## player but not the pointer), so goods on and in fixtures can all be clicked.
const STEPS := ["interior_refit", "second_pass", "coplanar_gaps", "coplanar_gaps_2", "glass_windows", "shop_row_style", "palette_snap"]

const Art := preload("res://scripts/buildings/supermarket_products.gd")
const Props := preload("res://scripts/buildings/sports_props.gd")
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER
const PROPS := "res://scenes/props/vocabulary/%s.tscn"

const F := .04
const W := 6.9
const D := 11.9
const CEILING := 4.57
## Seen from the door: +X is on the left. Yaw that turns a fixture's front (-Z) into the room.
const FACE_FROM_LEFT_WALL := PI / 2
const FACE_FROM_RIGHT_WALL := -PI / 2
const WOOD := "d9a560"
const WOOD_DARK := "9c6b34"
const SHELF := "f1ead9"
const NAVY := "2c4f86"
const PAINT := "cfe5f6"
const CREAM := "f3ecdc"
## Display sizes of the vocabulary prefabs (balls as the hospital shows its soccer ball).
const BALL := .35
const DUMBBELL := .36

var g
var store: Node3D
var room: Node3D
var art

func interior_refit(town: Node3D, game) -> void:
	g = game
	store = town.get_node_or_null("Buildings/SportsStore")
	if store == null:
		push_error("sports: store not found")
		return
	room = store.get_node("Interior")
	var keep := ["GoldenSalesperson"]
	for child in room.get_children():
		if not String(child.name) in keep:
			room.remove_child(child)
			child.free()
	# The original prefab roots on the store itself: their words come back below on the new
	# fixtures; baseball, bat, glove and barbell (words retired 28 Oct 2026) are not shown.
	for title in ["Basketball", "Soccer_Ball", "Volleyball", "Tennis_Racket", "Bicycle", "Skateboard", "Helmet",
			"Dumbbell", "Jump_Rope", "Basketball_Hoop", "Goal", "Barbell", "Baseball", "Baseball_Bat",
			"Baseball_Glove", "Tennis_Ball"]:
		var old := store.get_node_or_null(title)
		if old != null:
			store.remove_child(old)
			old.free()
	art = Art.new()
	shell_finish()
	entrance()
	left_wall()
	right_wall()
	rear_wall()
	islands()
	checkout()
	signs()
	lights()

# ---------------------------------------------------------------- helpers

func mesh_of(title: String, draw: Callable) -> ArrayMesh:
	art.begin()
	draw.call()
	return art.finish(title)

func box(title: String, p: Vector3, size: Vector3, tint: String, word := "", solid := false, parent: Node3D = null) -> Node3D:
	var node: Node3D = g.box(title, p, size, Color(tint), word, solid)
	node.reparent(room if parent == null else parent, false)
	return node

## A fixture: one merged mesh and a blocker that stops the player only (FIGURE_LAYER), so the
## pointer reaches the goods on it. `block` is the blocker box (centre, size) in fixture space.
func fixture(title: String, mesh: ArrayMesh, p: Vector3, yaw: float, block: AABB, parent: Node3D = null) -> Node3D:
	var root := Node3D.new()
	root.name = title
	(room if parent == null else parent).add_child(root)
	root.position = p
	root.rotation.y = yaw
	var view := MeshInstance3D.new()
	view.name = "Model"
	view.mesh = mesh
	root.add_child(view)
	if block.size != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = "Blocker"
		body.collision_layer = FIGURE_LAYER
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cube := BoxShape3D.new()
		cube.size = block.size
		shape.shape = cube
		shape.position = block.get_center()
		body.add_child(shape)
		root.add_child(body)
	return root

## A word item drawn with the mesh kit: one root with the word, the mesh and a pick area fitted
## to the mesh (collision layer 2, like the vocabulary prefabs).
func item(title: String, word: String, mesh: ArrayMesh, p: Vector3, yaw: float, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = title
	parent.add_child(root)
	root.position = p
	root.rotation.y = yaw
	root.set_meta("word_key", word)
	root.set_meta("learning_object", true)
	var view := MeshInstance3D.new()
	view.name = "Model"
	view.mesh = mesh
	root.add_child(view)
	pick_area(root, mesh.get_aabb().grow(.02))
	return root

func pick_area(root: Node3D, bounds: AABB, title := "Interaction") -> void:
	var area := Area3D.new()
	area.name = title
	area.collision_layer = 2
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = bounds.size
	shape.shape = cube
	shape.position = bounds.get_center()
	area.add_child(shape)
	root.add_child(area)

## A vocabulary prefab instance (its word, pick area and footprint come with it).
func prefab(file: String, title: String, p: Vector3, yaw: float, size: float, parent: Node3D, turn := Vector3.ZERO) -> Node3D:
	var node: Node3D = load(PROPS % file).instantiate()
	node.name = title
	parent.add_child(node)
	node.position = p
	node.rotation = Vector3(turn.x, yaw, turn.z)
	node.scale = Vector3.ONE * size
	return node

# ---------------------------------------------------------------- shell

func shell_finish() -> void:
	# Warm two-tone checker floor as one textured plane (kept from the 28 Oct design).
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, Color("f6e3ae"))
	image.set_pixel(1, 1, Color("f6e3ae"))
	image.set_pixel(1, 0, Color("efd493"))
	image.set_pixel(0, 1, Color("efd493"))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.uv1_scale = Vector3(6.9, 11.9, 1)
	material.roughness = .9
	var plane := MeshInstance3D.new()
	plane.name = "Checker floor"
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(13.8, 23.8)
	plane.mesh = floor_mesh
	plane.material_override = material
	plane.position = Vector3(0, .035, 0)
	room.add_child(plane)
	box("Ceiling finish", Vector3(0, CEILING, 0), Vector3(13.8, .06, 23.8), CREAM)
	for side in [-1.0, 1.0]:
		box("Wall paint", Vector3(side * 6.895, F + 1.8, 0), Vector3(.02, 3.0, 23.8), PAINT)
		box("Front wall paint", Vector3(side * 4.35, F + 1.8, -11.895), Vector3(5.1, 3.0, .02), PAINT)
		box("Side skirting", Vector3(side * 6.88, F + .12, 0), Vector3(.04, .24, 23.8), WOOD_DARK)
		box("Front skirting", Vector3(side * 4.35, F + .12, -11.88), Vector3(5.1, .24, .04), WOOD_DARK)
		box("Side band", Vector3(side * 6.88, 3.55, 0), Vector3(.04, .22, 23.8), NAVY)
	box("Rear wall paint", Vector3(0, F + 1.8, 11.895), Vector3(13.8, 3.0, .02), PAINT)
	box("Rear skirting", Vector3(0, F + .12, 11.88), Vector3(13.8, .24, .04), WOOD_DARK)
	box("Rear band", Vector3(0, 3.55, 11.88), Vector3(13.8, .22, .04), NAVY)
	# Four ceiling light panels over the centre aisle.
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("fffaf0")
	glow.emission_enabled = true
	glow.emission = Color("fff6e0")
	glow.emission_energy_multiplier = .6
	for z in [-8.0, -2.5, 3.0, 8.5]:
		var panel := box("Ceiling light panel", Vector3(0, CEILING - .04, z), Vector3(1.6, .03, 1.0), "fffaf0")
		(panel.get_child(0) as MeshInstance3D).material_override = glow

func entrance() -> void:
	box("Entry mat", Vector3(0, F + .008, -10.9), Vector3(3.0, .016, 1.6), NAVY)
	for side in [-1.0, 1.0]:
		var pot: Node3D = g.cylinder("Planter", Vector3(side * 2.55, F + .3, -11.25), .32, .6, Color("c96f4a"), "planter", true)
		pot.reparent(room, false)
		var leaves: Node3D = g.sphere("Plant", Vector3(side * 2.55, F + 1.0, -11.25), .45, Color("4f8f3a"), "plant", false)
		leaves.reparent(room, false)
		leaves.scale = Vector3(1, 1.25, 1)

# ---------------------------------------------------------------- fixtures

## Wall shelving `length` long (along x), front -Z, back against the wall at +Z; shelves at
## `tiers` heights (top surfaces). Origin on the floor at the front-centre of the footprint.
func wall_unit_mesh(length: float, depth: float, height: float, tiers: Array) -> ArrayMesh:
	return mesh_of("Sports wall unit", func() -> void:
		art.bx(Vector3(0, height * .5, depth - .03), Vector3(length, height, .06), "e8dfca")
		for x in [-length * .5 + .03, length * .5 - .03]:
			art.bx(Vector3(x, height * .5, depth * .5), Vector3(.06, height, depth), WOOD)
		art.bx(Vector3(0, height - .03, depth * .5), Vector3(length, .06, depth), WOOD)
		art.bx(Vector3(0, .06, depth * .5), Vector3(length, .12, depth), WOOD_DARK)
		for y in tiers:
			art.bx(Vector3(0, y - .02, depth * .5), Vector3(length - .1, .04, depth - .06), SHELF)
			art.bx(Vector3(0, y - .03, .01), Vector3(length - .1, .05, .02), NAVY, Art.SATIN))

func wall_unit(title: String, z0: float, z1: float, side: float, depth: float, height: float, tiers: Array) -> Node3D:
	var length := z1 - z0
	var yaw := FACE_FROM_LEFT_WALL if side > 0 else FACE_FROM_RIGHT_WALL
	var p := Vector3(side * (W - depth), F, (z0 + z1) * .5)
	return fixture(title, wall_unit_mesh(length, depth, height, tiers), p, yaw,
		AABB(Vector3(-length * .5, 0, 0), Vector3(length, height, depth)))

## A display table `size.x` wide, `size.z` deep, top at `size.y`, with a lower shelf.
func table_mesh(size: Vector3) -> ArrayMesh:
	return mesh_of("Sports display table", func() -> void:
		art.bx(Vector3(0, size.y - .03, 0), Vector3(size.x, .06, size.z), WOOD)
		art.bx(Vector3(0, size.y - .065, 0), Vector3(size.x - .04, .02, size.z - .04), SHELF)
		art.bx(Vector3(0, .3, 0), Vector3(size.x - .12, .04, size.z - .12), SHELF)
		for x in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				art.bx(Vector3(x * (size.x * .5 - .06), size.y * .5, z * (size.z * .5 - .06)), Vector3(.07, size.y, .07), WOOD_DARK))

func table(title: String, p: Vector3, size: Vector3) -> Node3D:
	return fixture(title, table_mesh(size), p, 0.0, AABB(Vector3(-size.x * .5, 0, -size.z * .5), size))

## A wire ball bin: posts, rims and bars around a solid floor.
func bin_mesh(size: Vector3) -> ArrayMesh:
	return mesh_of("Ball bin", func() -> void:
		var steel := "8a949c"
		art.bx(Vector3(0, .08, 0), Vector3(size.x, .04, size.z), "5b6470", Art.SATIN)
		for x in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				art.bx(Vector3(x * size.x * .5, size.y * .5, z * size.z * .5), Vector3(.04, size.y, .04), steel, Art.METAL)
				art.ball(Vector3(x * size.x * .5, .02, z * size.z * .5), Vector3(.07, .04, .07), Props.RUBBER, Art.SATIN)
		for y in [.3, size.y * .55, size.y]:
			for s in [-1.0, 1.0]:
				art.bx(Vector3(0, y, s * size.z * .5), Vector3(size.x, .025, .025), steel, Art.METAL)
				art.bx(Vector3(s * size.x * .5, y, 0), Vector3(.025, .025, size.z), steel, Art.METAL)
		for k in range(1, 5):
			var t := -size.x * .5 + size.x * k / 5.0
			for s in [-1.0, 1.0]:
				art.bx(Vector3(t, size.y * .5 + .1, s * size.z * .5), Vector3(.015, size.y - .2, .015), steel, Art.METAL)
				art.bx(Vector3(s * size.x * .5, size.y * .5 + .1, t * size.z / size.x), Vector3(.015, size.y - .2, .015), steel, Art.METAL))

## Balls heaped in a bin: a full bottom layer and a few on top, every one a clickable prefab.
func fill_bin(bin: Node3D, file: String, title: String, size: Vector3) -> void:
	var d := .86 * BALL
	var n := 0
	for layer in 2:
		for i in 3:
			for j in 3:
				if layer == 1 and (i + j) % 2 == 1:
					continue
				var p := Vector3((i - 1) * d * 1.02 + (layer * .1), .1 + layer * d * .8, (j - 1) * d * 1.02 - (layer * .06))
				if absf(p.x) > size.x * .5 - d * .45 or absf(p.z) > size.z * .5 - d * .45:
					continue
				prefab(file, "%s %d" % [title, n + 1], p, n * 1.3, BALL, bin)
				n += 1

func mirror_mesh() -> ArrayMesh:
	return mesh_of("Mirror", func() -> void:
		art.bx(Vector3(0, 1.15, .03), Vector3(1.0, 1.9, .06), WOOD_DARK)
		art.bx(Vector3(0, 1.15, -.005), Vector3(.86, 1.76, .02), "cfe6f2", Art.METAL)
		art.bx(Vector3(.2, 1.5, -.018), Vector3(.12, .9, .005), "eef7fb", Art.METAL, Vector3(0, 0, -.5)))

func bench_mesh() -> ArrayMesh:
	return mesh_of("Fitting bench", func() -> void:
		art.bx(Vector3(0, .43, 0), Vector3(1.6, .1, .5), NAVY, Art.MATTE)
		art.bx(Vector3(0, .36, 0), Vector3(1.6, .04, .5), WOOD)
		for x in [-.7, .7]:
			art.bx(Vector3(x, .17, 0), Vector3(.08, .34, .44), WOOD_DARK))

func weight_bench_mesh() -> ArrayMesh:
	return mesh_of("Weight bench", func() -> void:
		art.bx(Vector3(0, .5, .1), Vector3(.42, .12, 1.3), "2b2f36", Art.SATIN)
		art.bx(Vector3(0, .43, .1), Vector3(.3, .04, 1.2), Props.CHROME, Art.METAL)
		for z in [-.4, .6]:
			art.bx(Vector3(0, .22, z), Vector3(.08, .42, .08), Props.CHROME, Art.METAL)
			art.bx(Vector3(0, .03, z), Vector3(.6, .06, .1), "2b2f36", Art.SATIN))

# ---------------------------------------------------------------- left wall (+x)

func left_wall() -> void:
	# OUTDOOR, front: two bicycles side on to the aisle, then backpacks, bottles and helmets.
	for k in 2:
		prefab("bicycle", "Bicycle" if k == 0 else "Bicycle %d" % (k + 1), Vector3(6.15, F, -10.15 + k * 2.0), PI / 2, .6, room)
	var outdoor := wall_unit("Outdoor shelves", -6.6, -3.4, 1.0, .6, 2.3, [.62, 1.32, 2.02])
	var bag_colors := ["d8453a", "3a74c4", "3f9a45"]
	for k in 3:
		var bag := prefab("backpack", "Backpack" if k == 0 else "Backpack %d" % (k + 1), Vector3(-1.0 + k * 1.0, 1.32, .3), 0.0, .42, outdoor)
		tint(bag, bag_colors[k])
	for k in 6:
		var bottle := prefab("water_bottle", "Water bottle" if k == 0 else "Water bottle %d" % (k + 1), Vector3(-1.25 + k * .5, .62, .25), 0.0, .38, outdoor)
		tint(bottle, ["3a74c4", "3f9a45", "ec7b2c"][k % 3])
	for k in 3:
		prefab("helmet", "Helmet" if k == 0 else "Helmet %d" % (k + 1), Vector3(-1.0 + k * 1.0, 2.02, .3), 0.0, .42, outdoor)
	# FITNESS, middle: a two-tier dumbbell rack and jump ropes on a hook rail.
	var rack := fixture("Dumbbell rack", mesh_of("Dumbbell rack", func() -> void:
		for y in [.42, .82]:
			art.bx(Vector3(0, y, .3 if y > .5 else .1), Vector3(3.0, .04, .36), "3a3f46", Art.SATIN, Vector3(-.25, 0, 0))
		for x in [-1.45, 0.0, 1.45]:
			art.bx(Vector3(x, .45, .25), Vector3(.06, .9, .5), "3a3f46", Art.SATIN)
			art.bx(Vector3(x, .03, .25), Vector3(.12, .06, .7), "2b2f36", Art.SATIN)),
		Vector3(W - .62, F, -1.1), FACE_FROM_LEFT_WALL, AABB(Vector3(-1.5, 0, -.1), Vector3(3.0, .95, .7)))
	var n := 0
	for tier in [[.82, .38, 4], [.42, .1, 3]]:
		for pair in tier[2]:
			for k in 2:
				var x: float = -1.2 + pair * (2.4 / maxf(1.0, tier[2] - 1)) + (k - .5) * .26
				prefab("dumbbell", "Dumbbell" if n == 0 else "Dumbbell %d" % (n + 1), Vector3(x, tier[0] - .01, tier[1]), PI / 2, DUMBBELL + (.06 if tier[2] == 3 else 0.0), rack)
				n += 1
	var hooks := fixture("Jump rope hooks", mesh_of("Hook rail", func() -> void:
		art.bx(Vector3(0, 1.9, .02), Vector3(1.8, .1, .04), WOOD)
		for x in [-.6, 0.0, .6]:
			art.bx(Vector3(x, 1.9, -.05), Vector3(.03, .03, .12), Props.CHROME, Art.METAL)),
		Vector3(W - .02, F, 1.6), FACE_FROM_LEFT_WALL, AABB())
	for k in 3:
		var rope := prefab("jump_rope", "Jump_Rope" if k == 0 else "Jump rope %d" % (k + 1), Vector3(-.6 + k * .6, 1.05, -.06), 0.0, .7, hooks)
		tint(rope, ["d8453a", "3a74c4", "f2c231"][k])
	# Court corner at the rear: a hoop and a small goal on a green sports floor.
	box("Court floor", Vector3(5.65, F + .006, 6.9), Vector3(2.5, .012, 5.6), "5f9e6e")
	box("Court line", Vector3(5.65, F + .014, 6.9), Vector3(2.5, .006, .06), "f6f1e6")
	prefab("basketball_hoop", "Basketball_Hoop", Vector3(6.3, F, 5.0), PI / 2, .82, room)
	prefab("goal", "Goal", Vector3(6.2, F, 8.4), PI / 2, 1.0, room)
	prefab("basketball", "Court basketball", Vector3(5.2, F, 5.5), 0.0, BALL, room)
	prefab("soccer_ball", "Court soccer ball", Vector3(5.3, F, 8.4), 0.0, BALL, room)

# ---------------------------------------------------------------- right wall (-x)

func right_wall() -> void:
	# BALLS, front: three shelves of balls, one kind per shelf.
	var balls := wall_unit("Ball shelves", -11.3, -6.4, -1.0, .6, 2.3, [.55, 1.2, 1.85])
	var rows := [["soccer_ball", "Soccer_Ball", 1.85], ["basketball", "Basketball", 1.2], ["volleyball", "Volleyball", .55]]
	for row in rows:
		for k in 8:
			var title: String = row[1] if k == 0 else "%s %d" % [String(row[1]).replace("_", " "), k + 1]
			prefab(row[0], title, Vector3(-2.1 + k * .6, row[2], .3), k * .7, BALL, balls)
	# RACKETS: a pegboard with four rackets and a bin of tennis balls below.
	var board := fixture("Racket board", mesh_of("Pegboard", func() -> void:
		art.bx(Vector3(0, 1.45, .03), Vector3(2.6, 1.5, .05), "e9dcc0")
		art.bx(Vector3(0, 2.23, .03), Vector3(2.7, .06, .07), WOOD)
		art.bx(Vector3(0, .67, .03), Vector3(2.7, .06, .07), WOOD)
		for k in 4:
			art.bx(Vector3(-.9 + k * .6, 2.08, -.04), Vector3(.03, .03, .12), Props.CHROME, Art.METAL)),
		Vector3(-W + .02, F, -4.0), FACE_FROM_RIGHT_WALL, AABB())
	var frames := ["3a74c4", "d8453a", "2d2f3a", "3f9a45"]
	for k in 4:
		var racket := prefab("tennis_racket", "Tennis_Racket" if k == 0 else "Tennis racket %d" % (k + 1), Vector3(-.9 + k * .6, .78, -.08), 0.0, .78, board)
		tint(racket, frames[k], "OvalFrame")
	var ball_bin := fixture("Tennis ball bin", bin_mesh(Vector3(.7, .55, .7)), Vector3(-W + .75, F, -4.0), 0.0,
		AABB(Vector3(-.35, 0, -.35), Vector3(.7, .55, .7)))
	for k in 7:
		var p := Vector3((k % 3 - 1) * .2, .14 + (k / 3) * .12, (k / 3 - 1) * .18 + (k % 2) * .05)
		prefab("tennis_ball", "Tennis ball" if k == 0 else "Tennis ball %d" % (k + 1), p, k * .9, .42, ball_bin)
	# APPAREL: a full-length mirror and a bench, then a wall rail of shirts.
	var mirror := item("Mirror", "mirror", mirror_mesh(), Vector3(-W + .02, F, -.6), FACE_FROM_RIGHT_WALL, room)
	mirror.position.y = F
	var bench := item("Bench", "bench", bench_mesh(), Vector3(-5.55, F, -.6), FACE_FROM_RIGHT_WALL, room)
	solid(bench, AABB(Vector3(-.8, 0, -.25), Vector3(1.6, .48, .5)))
	var rail := fixture("Shirt rail", mesh_of("Wall rail", func() -> void:
		art.cyl(Vector3(0, 1.75, -.32), Vector3(.04, 3.0, .04), Props.CHROME, Art.METAL, Vector3(0, 0, PI / 2), 8)
		for x in [-1.45, 1.45]:
			art.bx(Vector3(x, 1.75, -.16), Vector3(.04, .04, .34), Props.CHROME, Art.METAL)),
		Vector3(-W + .02, F, 2.9), FACE_FROM_RIGHT_WALL, AABB())
	var shirt_colors := ["e8e8e8", "3a74c4", "d8453a", "3f9a45", "f2c231"]
	for k in 5:
		var shirt := prefab("shirt", "Shirt" if k == 0 else "Shirt %d" % (k + 1), Vector3(-1.2 + k * .6, 1.22, -.32), 0.0, .62, rail)
		tint(shirt, shirt_colors[k])

## The prefab's look in another colour: the meshes in its main colour (that of the first plain
## material, or only meshes named `only`) get a tinted copy of their material. Mesh-kit models
## (vertex colours) keep their own colours.
func tint(node: Node3D, hex: String, only := "") -> void:
	var main := Color(0, 0, 0, 0)
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if only != "" and not String(mesh.name).begins_with(only):
			continue
		var source := mesh.material_override as StandardMaterial3D
		if source == null or source.vertex_color_use_as_albedo:
			continue
		if only == "":
			if main.a == 0.0:
				main = source.albedo_color
			elif not source.albedo_color.is_equal_approx(main):
				continue
		var own := source.duplicate() as StandardMaterial3D
		own.albedo_color = Color(hex)
		mesh.material_override = own

## A solid body for a word item; `player_only` (FIGURE_LAYER) when other words sit inside it.
func solid(root: Node3D, bounds: AABB, player_only := false) -> void:
	var body := StaticBody3D.new()
	body.name = "Footprint"
	if player_only:
		body.collision_layer = FIGURE_LAYER
		body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = bounds.size
	shape.shape = cube
	shape.position = bounds.get_center()
	body.add_child(shape)
	root.add_child(body)

# ---------------------------------------------------------------- rear wall: winter sports

func rear_wall() -> void:
	box("Snow floor", Vector3(-.2, F + .008, 10.95), Vector3(8.8, .016, 1.9), "f3f6f8")
	# Ski rack: three pairs of skis standing in a trough.
	var skis := fixture("Ski rack", mesh_of("Ski rack", func() -> void:
		art.bx(Vector3(0, .1, .1), Vector3(1.7, .2, .3), WOOD_DARK)
		art.bx(Vector3(0, 1.6, .25), Vector3(1.7, .08, .1), WOOD)
		for x in [-.82, .82]:
			art.bx(Vector3(x, .85, .2), Vector3(.06, 1.7, .2), WOOD)),
		Vector3(-3.55, F, D - .45), 0.0, AABB(Vector3(-.85, 0, -.1), Vector3(1.7, 1.8, .45)))
	for k in 3:
		item("Skis" if k == 0 else "Skis %d" % (k + 1), "skis", mesh_of("Skis", func() -> void: Props.skis(art, ["d8453a", "3a74c4", "f2c231"][k])),
			Vector3(-.5 + k * .5, .05, .12), 0.0, skis)
	# Ski poles in a bin.
	var poles := fixture("Pole bin", mesh_of("Pole bin", func() -> void:
		art.cyl(Vector3(0, .3, 0), Vector3(.6, .6, .45), "5b6470", Art.SATIN, Vector3.ZERO, 12)
		art.cyl(Vector3(0, .6, 0), Vector3(.62, .04, .47), Props.CHROME, Art.METAL, Vector3.ZERO, 12)),
		Vector3(-2.05, F, D - .5), 0.0, AABB(Vector3(-.3, 0, -.25), Vector3(.6, .6, .5)))
	for k in 3:
		item("Ski poles" if k == 0 else "Ski poles %d" % (k + 1), "ski poles", mesh_of("Ski poles", func() -> void: Props.ski_poles(art, ["2d2f3a", "d8453a", "3a74c4"][k])),
			Vector3(-.14 + k * .14, .05, (k % 2) * .08 - .04), k * .6, poles)
	# Snowboard wall: three boards on brackets.
	var boards := fixture("Snowboard wall", mesh_of("Snowboard brackets", func() -> void:
		for x in [-.62, 0.0, .62]:
			art.bx(Vector3(x, .25, .05), Vector3(.3, .06, .14), "3a3f46", Art.SATIN)
			art.bx(Vector3(x, 1.7, .05), Vector3(.1, .06, .12), "3a3f46", Art.SATIN)),
		Vector3(-.4, F, D - .12), 0.0, AABB())
	var board_colors := [["3a74c4", "f2c231"], ["2d2f3a", "ec7b2c"], ["3f9a45", "f4f2ec"]]
	for k in 3:
		item("Snowboard" if k == 0 else "Snowboard %d" % (k + 1), "snowboard",
			mesh_of("Snowboard", func() -> void: Props.snowboard(art, board_colors[k][0], board_colors[k][1])),
			Vector3(-.62 + k * .62, .2, 0.0), 0.0, boards)
	# Accessory shelves: goggles and hats, gloves and helmets, ski boots.
	var shelves := wall_unit_mesh(3.1, .55, 2.1, [.55, 1.15, 1.75])
	var acc := fixture("Winter accessory shelves", shelves, Vector3(2.65, F, D - .55), 0.0,
		AABB(Vector3(-1.55, 0, 0), Vector3(3.1, 2.1, .55)))
	for k in 3:
		item("Ski goggles" if k == 0 else "Ski goggles %d" % (k + 1), "ski goggles", mesh_of("Ski goggles", func() -> void: Props.goggles(art, ["2d2f3a", "f4f2ec", "d8453a"][k])),
			Vector3(-1.2 + k * .45, 1.75, .25), 0.0, acc)
		item("Winter hat" if k == 0 else "Winter hat %d" % (k + 1), "winter hat", mesh_of("Winter hat", func() -> void: Props.winter_hat(art, ["d8453a", "3a74c4", "3f9a45"][k], "f4f2ec")),
			Vector3(.3 + k * .45, 1.75, .27), 0.0, acc)
		item("Gloves" if k == 0 else "Gloves %d" % (k + 1), "gloves", mesh_of("Gloves", func() -> void: Props.gloves(art, ["2d2f3a", "d8453a", "3a74c4"][k])),
			Vector3(-1.15 + k * .5, 1.15, .27), 0.0, acc)
		item("Ski boots" if k == 0 else "Ski boots %d" % (k + 1), "ski boots", mesh_of("Ski boots", func() -> void: Props.ski_boots(art, ["f4f2ec", "d8453a", "3a74c4"][k])),
			Vector3(-1.0 + k * 1.0, .55, .27), 0.0, acc)
	for k in 2:
		prefab("helmet", "Ski helmet %d" % (k + 1), Vector3(.55 + k * .55, 1.15, .27), 0.0, .38, acc)
	# The dressed skier and the sled in front of the wall.
	skier(Vector3(.55, F, 10.0))
	item("Sled", "sled", mesh_of("Sled", func() -> void: Props.sled(art)), Vector3(2.7, F, 9.9), .4, room)

func skier(p: Vector3) -> void:
	var stand := Node3D.new()
	stand.name = "Skier mannequin"
	room.add_child(stand)
	stand.position = p
	stand.rotation.y = 0.0
	stand.set_meta("word_key", "mannequin")
	stand.set_meta("learning_object", true)
	var body := MeshInstance3D.new()
	body.name = "Model"
	body.mesh = mesh_of("Mannequin", func() -> void: Props.mannequin(art))
	stand.add_child(body)
	# The mannequin is picked by its head and base; the clothes on it are their own words.
	pick_area(stand, AABB(Vector3(-.16, 1.66, -.16), Vector3(.32, .4, .32)), "Interaction")
	pick_area(stand, AABB(Vector3(-.27, 0, -.27), Vector3(.54, .3, .54)), "Base")
	solid(stand, AABB(Vector3(-.3, 0, -.3), Vector3(.6, 1.9, .6)), true)
	var jacket := item("Ski jacket", "jacket", mesh_of("Ski jacket", func() -> void:
		var red := "d8453a"
		art.cyl(Vector3(0, 1.38, 0), Vector3(.5, .62, .3), red, Art.MATTE, Vector3.ZERO, 12, .82)
		for side in [-1.0, 1.0]:
			art.cyl(Vector3(side * .29, 1.3, 0), Vector3(.14, .58, .14), red, Art.MATTE, Vector3(0, 0, side * .14), 8)
			art.bx(Vector3(side * .29, 1.42, -.075), Vector3(.1, .04, .01), "f4f2ec", Art.MATTE, Vector3(0, 0, side * .14))
		art.cyl(Vector3(0, 1.7, 0), Vector3(.2, .1, .2), "2d2f3a", Art.MATTE, Vector3.ZERO, 10)
		art.bx(Vector3(0, 1.38, -.152), Vector3(.02, .58, .01), Props.CHROME, Art.METAL)
		art.bx(Vector3(0, 1.12, 0), Vector3(.5, .06, .3), "2d2f3a", Art.MATTE)), Vector3.ZERO, 0.0, stand)
	jacket.position = Vector3.ZERO
	item("Snow pants", "pants", mesh_of("Snow pants", func() -> void:
		for side in [-1.0, 1.0]:
			art.cyl(Vector3(side * .11, .8, 0), Vector3(.18, .66, .2), "2d2f3a", Art.MATTE, Vector3.ZERO, 10, .9)
		art.bx(Vector3(0, 1.1, 0), Vector3(.42, .12, .26), "2d2f3a", Art.MATTE)), Vector3.ZERO, 0.0, stand)
	prefab("helmet", "Skier helmet", Vector3(0, 1.76, .02), 0.0, .34, stand)

# ---------------------------------------------------------------- islands

func islands() -> void:
	# OUTDOOR island: skateboards on top, one more helmet.
	var outdoor := table("Skate table", Vector3(3.3, F, -8.6), Vector3(1.4, .8, 2.4))
	for k in 3:
		var deck := prefab("skateboard", "Skateboard" if k == 0 else "Skateboard %d" % (k + 1), Vector3(0, .8, -.75 + k * .75), 0.0, .48, outdoor)
		tint(deck, ["d9a560", "3a74c4", "d8453a"][k], "Deck")
	# BALLS island: two bins, soccer balls and basketballs.
	for k in 2:
		var bin := fixture("Ball bin %d" % (k + 1), bin_mesh(Vector3(1.0, .7, 1.0)), Vector3(-3.3, F, -9.3 + k * 1.4), 0.0,
			AABB(Vector3(-.5, 0, -.5), Vector3(1.0, .7, 1.0)))
		fill_bin(bin, ["soccer_ball", "basketball"][k], ["Bin soccer ball", "Bin basketball"][k], Vector3(1.0, .7, 1.0))
	# RUNNING: a stepped sneaker display.
	var shoes := fixture("Sneaker display", mesh_of("Stepped display", func() -> void:
		art.bx(Vector3(0, .25, 0), Vector3(2.6, .5, 1.4), WOOD)
		art.bx(Vector3(0, .62, .3), Vector3(2.4, .24, .7), SHELF)
		art.bx(Vector3(0, .51, -.35), Vector3(2.58, .02, .66), SHELF)),
		Vector3(-3.3, F, -2.0), -PI / 2, AABB(Vector3(-1.3, 0, -.7), Vector3(2.6, .74, 1.4)))
	for k in 6:
		var row := k / 3
		var pair := prefab("sneakers", "Sneakers" if k == 0 else "Sneakers %d" % (k + 1),
			Vector3(-.85 + (k % 3) * .85, .52 if row == 0 else .74, -.38 if row == 0 else .3), 0.0, .48, shoes)
	# Weight bench on a rubber mat, beside the fitness wall.
	box("Rubber mat", Vector3(3.6, F + .008, -1.1), Vector3(1.8, .016, 3.0), "3a3f46")
	var lift := item("Weight bench", "bench", weight_bench_mesh(), Vector3(3.6, F, -1.3), 0.0, room)
	solid(lift, AABB(Vector3(-.3, 0, -.6), Vector3(.6, .56, 1.4)))
	for k in 2:
		prefab("dumbbell", "Floor dumbbell %d" % (k + 1), Vector3(3.0, F, -1.6 + k * .5), 0.0, DUMBBELL, room)
	# APPAREL: a jacket rail (left) and a table of shorts (right).
	var jackets := fixture("Jacket rail", mesh_of("Clothes rail", func() -> void:
		art.cyl(Vector3(0, 1.55, 0), Vector3(.045, 2.6, .045), Props.CHROME, Art.METAL, Vector3(PI / 2, 0, 0), 8)
		for z in [-1.25, 1.25]:
			art.cyl(Vector3(0, .78, z), Vector3(.045, 1.56, .045), Props.CHROME, Art.METAL, Vector3.ZERO, 8)
			art.bx(Vector3(0, .02, z), Vector3(.6, .04, .08), "5b6470", Art.SATIN)),
		Vector3(3.3, F, 4.6), 0.0, AABB(Vector3(-.3, 0, -1.3), Vector3(.6, 1.6, 2.6)))
	var coat_colors := ["d8453a", "3a74c4", "2d2f3a", "3f9a45"]
	for k in 4:
		var coat := prefab("jacket", "Jacket" if k == 0 else "Jacket %d" % (k + 1), Vector3(0, 1.1, -.9 + k * .6), PI / 2, .44, jackets)
		tint(coat, coat_colors[k])
	var shorts := table("Shorts table", Vector3(-3.3, F, 4.6), Vector3(1.4, .8, 2.4))
	for k in 4:
		var pair := prefab("shorts", "Shorts" if k == 0 else "Shorts %d" % (k + 1), Vector3(0, .8, -.85 + k * .57), -PI / 2, .5, shorts)
		tint(pair, ["3a74c4", "2d2f3a", "d8453a", "3f9a45"][k])

# ---------------------------------------------------------------- checkout

func checkout() -> void:
	var counter := item("Checkout counter", "checkout counter", mesh_of("Checkout counter", func() -> void:
		art.bx(Vector3(0, .53, 0), Vector3(.9, 1.06, 3.2), WOOD_DARK)
		art.bx(Vector3(0, 1.08, 0), Vector3(1.0, .05, 3.3), SHELF)
		art.bx(Vector3(.452, .55, 0), Vector3(.01, .3, 3.0), NAVY, Art.SATIN)), Vector3(-6.0, F, 8.8), 0.0, room)
	solid(counter, AABB(Vector3(-.45, 0, -1.6), Vector3(.9, 1.1, 3.2)))
	item("Cash register", "cash register", mesh_of("Cash register", func() -> void:
		art.bx(Vector3(0, .07, 0), Vector3(.42, .14, .38), "2d2f3a", Art.SATIN)
		art.bx(Vector3(0, .17, .05), Vector3(.36, .06, .24), "3a3f46", Art.SATIN)
		art.bx(Vector3(.05, .3, -.1), Vector3(.3, .2, .03), "2d2f3a", Art.SATIN, Vector3(0, 0, 0))
		art.bx(Vector3(.05, .3, -.118), Vector3(.26, .16, .005), "7fb8d9", Art.SATIN)), Vector3(-6.0, F + 1.105, 8.2), PI / 2, room)

# ---------------------------------------------------------------- signs and lights

## A department sign on a wall: a navy panel with white lettering, facing into the room.
func wall_sign(text: String, p: Vector3, yaw: float, width: float) -> void:
	var board := Node3D.new()
	board.name = text + " sign board"
	room.add_child(board)
	board.position = p
	board.rotation.y = yaw
	var panel := MeshInstance3D.new()
	panel.mesh = mesh_of("Sign board", func() -> void:
		art.bx(Vector3(0, 0, .02), Vector3(width, .5, .04), NAVY, Art.SATIN)
		art.bx(Vector3(0, -.22, .0), Vector3(width, .04, .02), "f2c231", Art.SATIN))
	board.add_child(panel)
	var label := Label3D.new()
	label.name = text + " sign"
	label.text = text
	label.font_size = 48
	label.pixel_size = .3 / 48.0
	label.outline_size = 0
	label.modulate = Color("ffffff")
	label.position = Vector3(0, .02, -.005)
	label.rotation.y = PI
	board.add_child(label)

func signs() -> void:
	wall_sign("OUTDOOR", Vector3(W - .02, 3.05, -5.0), FACE_FROM_LEFT_WALL, 2.0)
	wall_sign("FITNESS", Vector3(W - .02, 3.05, .2), FACE_FROM_LEFT_WALL, 2.0)
	wall_sign("BALLS", Vector3(-W + .02, 3.05, -8.85), FACE_FROM_RIGHT_WALL, 1.8)
	wall_sign("RACKETS", Vector3(-W + .02, 3.05, -4.0), FACE_FROM_RIGHT_WALL, 2.0)
	wall_sign("APPAREL", Vector3(-W + .02, 3.05, 2.9), FACE_FROM_RIGHT_WALL, 2.0)
	wall_sign("CHECKOUT", Vector3(-W + .02, 3.05, 8.8), FACE_FROM_RIGHT_WALL, 2.2)
	wall_sign("WINTER SPORTS", Vector3(-.4, 3.1, D - .02), 0.0, 3.6)

func lights() -> void:
	for z in [-8.0, -2.5, 3.0, 8.5]:
		var light := OmniLight3D.new()
		light.name = "Sports store light"
		light.position = Vector3(0, 4.1, z)
		light.light_color = Color("fff3dc")
		light.light_energy = .85
		light.omni_range = 9.0
		light.omni_attenuation = .8
		light.shadow_enabled = false
		room.add_child(light)

# ---------------------------------------------------------------- second pass (9 Nov 2026)

## second_pass (9 Nov 2026, user review of the refit: tidy but empty and plain; docs/guides/TOWN_DESIGN_BRIEF.md
## "Interiors polish"): the islands become two rows down the middle (x = +-2.7) with a red
## running-track runner in the centre aisle between them; hanging department signs (navy, like
## the wall signs), two lines of bunting, posters; every department gets a full fixture (fitness
## and apparel wall units, more stock on the outdoor shelves, jacket rail and shorts table, a
## running-shoe table, bike display, dumbbell table); a feature wall with product shelves behind
## the checkout and impulse items on the counter. The racket pegboard stood half inside the wall
## paint (it read as crooked) and the jacket rail stood at the edge of the court: both moved.
const ROW := 2.7

func second_pass(town: Node3D, game) -> void:
	g = game
	store = town.get_node_or_null("Buildings/SportsStore")
	if store == null:
		push_error("sports: store not found")
		return
	room = store.get_node("Interior")
	art = Art.new()
	# 1. Island rows: move the floating islands into two rows, then add the missing ones.
	for move in [["Skate table", Vector3(ROW, F, -8.6)], ["Rubber mat", Vector3(ROW, F + .008, -1.1)],
			["Weight bench", Vector3(ROW, F, -1.3)], ["Floor dumbbell 1", Vector3(ROW - .6, F, -1.6)],
			["Floor dumbbell 2", Vector3(ROW - .6, F, -1.1)], ["Ball bin 1", Vector3(-ROW, F, -9.3)],
			["Ball bin 2", Vector3(-ROW, F, -7.9)], ["Sneaker display", Vector3(-ROW, F, -2.0)],
			["Jacket rail", Vector3(-ROW, F, 1.9)], ["Shorts table", Vector3(-ROW, F, 5.0)]]:
		var node := room.get_node_or_null(str(move[0])) as Node3D
		if node == null:
			push_error("sports: %s not found" % move[0])
			continue
		node.position = move[1]
	runner()
	shoe_table()
	bike_display()
	dumbbell_table()
	stock_islands()
	# 3/4. Full department fixtures and wall decoration.
	stock_outdoor()
	fitness_unit()
	apparel_unit()
	posters()
	# 5. The racket pegboard (and its rackets) off the wall paint.
	var board := room.get_node_or_null("Racket board") as Node3D
	if board:
		board.position.x = -W + .1
	# 7. Checkout feature wall and impulse items.
	checkout_wall()
	# 2. Hanging signs and bunting.
	for spec in [["OUTDOOR", Vector3(ROW, 0, -6.8)], ["FITNESS", Vector3(ROW, 0, .6)], ["BALLS", Vector3(-ROW, 0, -8.6)],
			["RUNNING", Vector3(-ROW, 0, -3.5)], ["APPAREL", Vector3(-ROW, 0, 3.5)], ["CHECKOUT", Vector3(-5.1, 0, 7.0)],
			["WINTER SPORTS", Vector3(0, 0, 9.4)]]:
		hanging_sign(spec[0], spec[1])
	for z in [-5.6, 4.6]:
		bunting(z)

## The red running-track runner down the centre aisle (lane lines in white).
func runner() -> void:
	var track := fixture("Running track runner", mesh_of("Track runner", func() -> void:
		art.bx(Vector3(0, .006, 0), Vector3(1.6, .012, 19.0), "c8483a", Art.MATTE)
		for x in [-.74, -.25, .25, .74]:
			art.bx(Vector3(x, .013, 0), Vector3(.04, .004, 19.0), "f6f1e6", Art.MATTE)),
		Vector3(0, F, -.45), 0.0, AABB())
	track.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## RUNNING: a second shoe table in the right row, sneakers facing both aisles.
func shoe_table() -> void:
	var shoes := table("Running shoe table", Vector3(-ROW, F, -5.0), Vector3(1.4, .8, 2.4))
	for k in 8:
		var side := -1.0 if k < 4 else 1.0
		prefab("sneakers", "Table sneakers %d" % (k + 1), Vector3(side * .34, .8, -.84 + (k % 4) * .56), side * -PI / 2, .44, shoes)

## OUTDOOR: a bicycle on a low plinth in the left row, a helmet on the plinth.
func bike_display() -> void:
	var plinth := fixture("Bike display", mesh_of("Bike plinth", func() -> void:
		art.bx(Vector3(0, .09, 0), Vector3(1.2, .18, 2.4), WOOD)
		art.bx(Vector3(0, .185, 0), Vector3(1.1, .01, 2.3), "2c4f86", Art.SATIN)),
		Vector3(ROW, F, -5.0), 0.0, AABB(Vector3(-.6, 0, -1.2), Vector3(1.2, .4, 2.4)))
	prefab("bicycle", "Bicycle 3", Vector3(.1, .19, 0), PI / 2, .6, plinth)
	prefab("helmet", "Display helmet", Vector3(-.38, .19, .85), PI / 2, .36, plinth)

## FITNESS: a table of dumbbell pairs in the left row.
func dumbbell_table() -> void:
	var weights := table("Dumbbell table", Vector3(ROW, F, 2.3), Vector3(1.4, .8, 2.4))
	for k in 8:
		prefab("dumbbell", "Table dumbbell %d" % (k + 1), Vector3((k % 2 - .5) * .62, .8, -.9 + (k / 2) * .6), PI / 2, DUMBBELL, weights)

## More stock on the jacket rail (eight jackets) and the shorts table (eight pairs).
func stock_islands() -> void:
	var rail := room.get_node_or_null("Jacket rail") as Node3D
	if rail:
		var colors := ["d8453a", "3a74c4", "2d2f3a", "3f9a45", "f2c231", "ec7b2c", "6a4fa0", "e8e8e8"]
		for k in 8:
			var title := "Jacket" if k == 0 else "Jacket %d" % (k + 1)
			var coat := rail.get_node_or_null(title) as Node3D
			if coat == null:
				coat = prefab("jacket", title, Vector3.ZERO, PI / 2, .44, rail)
				tint(coat, colors[k])
			coat.position = Vector3(0, 1.1, -1.05 + k * .3)
	var table_node := room.get_node_or_null("Shorts table") as Node3D
	if table_node:
		var tints := ["3a74c4", "2d2f3a", "d8453a", "3f9a45", "f2c231", "e8e8e8", "ec7b2c", "6a4fa0"]
		for k in 8:
			var title := "Shorts" if k == 0 else "Shorts %d" % (k + 1)
			var pair := table_node.get_node_or_null(title) as Node3D
			if pair == null:
				pair = prefab("shorts", title, Vector3.ZERO, -PI / 2, .5, table_node)
				tint(pair, tints[k])
			pair.position = Vector3((k / 4 - .5) * .62, .8, -.85 + (k % 4) * .57)

## OUTDOOR shelves: six backpacks, eight bottles, five helmets.
func stock_outdoor() -> void:
	var unit := room.get_node_or_null("Outdoor shelves") as Node3D
	if unit == null:
		push_error("sports: outdoor shelves not found")
		return
	var bags := ["d8453a", "3a74c4", "3f9a45", "f2c231", "2d2f3a", "ec7b2c"]
	for k in 6:
		var title := "Backpack" if k == 0 else "Backpack %d" % (k + 1)
		var bag := unit.get_node_or_null(title) as Node3D
		if bag == null:
			bag = prefab("backpack", title, Vector3.ZERO, 0.0, .42, unit)
			tint(bag, bags[k])
		bag.position = Vector3(-1.25 + k * .5, 1.32, .3)
	for k in 8:
		var title := "Water bottle" if k == 0 else "Water bottle %d" % (k + 1)
		var bottle := unit.get_node_or_null(title) as Node3D
		if bottle == null:
			bottle = prefab("water_bottle", title, Vector3.ZERO, 0.0, .38, unit)
			tint(bottle, ["3a74c4", "3f9a45", "ec7b2c"][k % 3])
		bottle.position = Vector3(-1.4 + k * .4, .62, .25)
	for k in 5:
		var title := "Helmet" if k == 0 else "Helmet %d" % (k + 1)
		var hat := unit.get_node_or_null(title) as Node3D
		if hat == null:
			hat = prefab("helmet", title, Vector3.ZERO, 0.0, .42, unit)
		hat.position = Vector3(-1.2 + k * .6, 2.02, .3)

## FITNESS wall unit (left wall, behind the dumbbell table): jump ropes, dumbbells, bottles,
## volleyballs. The ropes leave the old hook rail (removed) and lie coiled on the bottom shelf.
func fitness_unit() -> void:
	var unit := wall_unit("Fitness shelves", .6, 3.9, 1.0, .55, 2.6, [.5, 1.1, 1.7, 2.3])
	var hooks := room.get_node_or_null("Jump rope hooks")
	var colors := ["d8453a", "3a74c4", "f2c231", "3f9a45", "ec7b2c", "2d2f3a"]
	for k in 6:
		var title := "Jump_Rope" if k == 0 else "Jump rope %d" % (k + 1)
		var rope: Node3D = hooks.get_node_or_null(title) if hooks else null
		if rope:
			rope.reparent(unit, false)
		else:
			rope = prefab("jump_rope", title, Vector3.ZERO, 0.0, .5, unit)
			tint(rope, colors[k])
		rope.scale = Vector3.ONE * .5
		rope.rotation = Vector3(-PI / 2, 0, 0)
		rope.position = Vector3(-1.35 + k * .54, .52, .02)
	if hooks:
		room.remove_child(hooks)
		hooks.free()
	for k in 8:
		prefab("dumbbell", "Shelf dumbbell %d" % (k + 1), Vector3(-1.35 + k * .385, 1.1, .27), PI / 2, .3, unit)
	for k in 7:
		var bottle := prefab("water_bottle", "Fitness bottle %d" % (k + 1), Vector3(-1.35 + k * .45, 1.7, .27), 0.0, .36, unit)
		tint(bottle, ["d8453a", "3a74c4", "f2c231"][k % 3])
	for k in 6:
		prefab("volleyball", "Shelf volleyball %d" % (k + 1), Vector3(-1.35 + k * .54, 2.3, .27), k * .7, BALL, unit)

## APPAREL wall unit (right wall, between the shirt rail and the checkout): backpacks, shorts,
## gloves and winter hats.
func apparel_unit() -> void:
	var unit := wall_unit("Apparel shelves", 4.5, 6.75, -1.0, .55, 2.6, [.5, 1.1, 1.7, 2.3])
	for k in 3:
		var bag := prefab("backpack", "Apparel backpack %d" % (k + 1), Vector3(-.75 + k * .75, .5, .3), 0.0, .4, unit)
		tint(bag, ["3a74c4", "d8453a", "2d2f3a"][k])
	for k in 5:
		var pair := prefab("shorts", "Shelf shorts %d" % (k + 1), Vector3(-.84 + k * .42, 1.1, .3), 0.0, .44, unit)
		tint(pair, ["2d2f3a", "3a74c4", "d8453a", "3f9a45", "f2c231"][k])
	for k in 4:
		item("Shelf gloves %d" % (k + 1), "gloves", mesh_of("Gloves", func() -> void: Props.gloves(art, ["2d2f3a", "d8453a", "3a74c4", "3f9a45"][k])),
			Vector3(-.8 + k * .53, 1.7, .27), 0.0, unit)
		item("Shelf winter hat %d" % (k + 1), "winter hat", mesh_of("Winter hat", func() -> void: Props.winter_hat(art, ["3a74c4", "d8453a", "f2c231", "3f9a45"][k], "f4f2ec")),
			Vector3(-.8 + k * .53, 2.3, .27), 0.0, unit)

## Posters: a framed print with a big ball and stripes (no lettering), facing into the room.
func poster(title: String, p: Vector3, yaw: float, size: Vector2, paper: String, accent: String, ball: String) -> void:
	fixture(title, mesh_of("Sports poster", func() -> void:
		art.bx(Vector3(0, 0, -.015), Vector3(size.x + .08, size.y + .08, .03), "2d2f3a", Art.SATIN)
		art.bx(Vector3(0, 0, -.032), Vector3(size.x, size.y, .005), paper, Art.MATTE)
		art.bx(Vector3(0, -size.y * .3, -.037), Vector3(size.x, size.y * .14, .005), accent, Art.MATTE)
		art.bx(Vector3(0, -size.y * .42, -.037), Vector3(size.x, size.y * .05, .005), "f6f1e6", Art.MATTE)
		var d := minf(size.x, size.y) * .5
		art.cyl(Vector3(0, size.y * .1, -.04), Vector3(d, d, .01), ball, Art.MATTE, Vector3(PI / 2, 0, 0), 16)
		art.bx(Vector3(0, size.y * .1, -.047), Vector3(d * .96, .025, .004), "2d2f3a", Art.MATTE)
		art.bx(Vector3(0, size.y * .1, -.047), Vector3(.025, d * .96, .004), "2d2f3a", Art.MATTE)),
		p, yaw, AABB())

func posters() -> void:
	poster("Poster basketball", Vector3(4.6, 2.3, -D + .02), PI, Vector2(1.2, 1.6), "2c4f86", "ec7b2c", "e07a2c")
	poster("Poster soccer", Vector3(-4.6, 2.3, -D + .02), PI, Vector2(1.2, 1.6), "3f9a45", "f2c231", "f4f2ec")
	poster("Poster fitness", Vector3(W - .02, 1.95, -1.6), FACE_FROM_LEFT_WALL, Vector2(1.2, 1.3), "d8453a", "2c4f86", "f2c231")
	poster("Poster court", Vector3(W - .02, 2.95, 6.9), FACE_FROM_LEFT_WALL, Vector2(1.4, .9), "2c4f86", "d8453a", "e07a2c")
	poster("Poster tennis", Vector3(-W + .02, 2.6, -.6), FACE_FROM_RIGHT_WALL, Vector2(1.1, .75), "f3ecdc", "3f9a45", "d4e04a")

## CHECKOUT: a navy feature wall with a stripe, product shelves behind the counter, impulse
## items (bottles, tennis balls) on the counter.
func checkout_wall() -> void:
	var wall := fixture("Checkout feature wall", mesh_of("Feature wall", func() -> void:
		# Below the CHECKOUT wall sign (bottom at 2.8).
		art.bx(Vector3(0, 1.37, -.01), Vector3(4.1, 2.66, .02), NAVY, Art.SATIN)
		art.bx(Vector3(0, 2.62, -.025), Vector3(4.1, .1, .01), "f2c231", Art.SATIN)
		art.bx(Vector3(0, 2.5, -.025), Vector3(4.1, .04, .01), "f6f1e6", Art.SATIN)
		for y in [1.45, 1.95, 2.45]:
			art.bx(Vector3(0, y - .02, -.15), Vector3(3.1, .04, .26), SHELF)
			art.bx(Vector3(0, y - .03, -.28), Vector3(3.1, .05, .02), "f2c231", Art.SATIN)
		for x in [-1.5, 0.0, 1.5]:
			for y in [1.45, 1.95, 2.45]:
				art.bx(Vector3(x, y - .12, -.06), Vector3(.03, .16, .1), Props.CHROME, Art.METAL)),
		Vector3(-W + .01, F, 8.85), FACE_FROM_RIGHT_WALL, AABB())
	for k in 6:
		var bottle := prefab("water_bottle", "Checkout bottle %d" % (k + 1), Vector3(-1.3 + k * .52, 1.45, -.15), 0.0, .34, wall)
		tint(bottle, ["3a74c4", "d8453a", "3f9a45"][k % 3])
	for k in 7:
		prefab("tennis_ball", "Checkout tennis ball %d" % (k + 1), Vector3(-1.35 + k * .45, 1.95, -.15), k * .9, .42, wall)
	for k in 4:
		prefab("sneakers", "Checkout sneakers %d" % (k + 1), Vector3(-1.2 + k * .8, 2.45, -.15), 0.0, .38, wall)
	# Impulse items at the customer end of the counter (top at F + 1.105).
	var top := F + 1.105
	box("Impulse tray", Vector3(-5.85, top + .015, 9.75), Vector3(.5, .03, .7), "2d2f3a")
	for k in 3:
		var bottle := prefab("water_bottle", "Counter bottle %d" % (k + 1), Vector3(-5.85, top + .03, 9.5 + k * .25), 0.0, .26, room)
		tint(bottle, ["d8453a", "3a74c4", "3f9a45"][k])
	for k in 3:
		prefab("tennis_ball", "Counter tennis ball %d" % (k + 1), Vector3(-5.85 + (k - 1) * .14, top, 8.95), k * .9, .42, room)

## A hanging department sign: navy board with a yellow edge, the name on both faces, on two cords.
func hanging_sign(text: String, p: Vector3) -> void:
	var width := maxf(1.6, text.length() * .2 + .5)
	var y := 3.55
	var board := fixture(text + " hanging sign", mesh_of("Hanging sign", func() -> void:
		art.bx(Vector3(0, 0, 0), Vector3(width, .5, .06), NAVY, Art.SATIN)
		art.bx(Vector3(0, -.22, 0), Vector3(width, .06, .07), "f2c231", Art.SATIN)
		for x in [-width * .4, width * .4]:
			art.cyl(Vector3(x, (CEILING - y) * .5 + .12, 0), Vector3(.015, CEILING - y - .25, .015), "2d2f3a", Art.SATIN, Vector3.ZERO, 6)),
		Vector3(p.x, y, p.z), 0.0, AABB())
	for face in [-1.0, 1.0]:
		var label := Label3D.new()
		label.name = text + (" sign" if face < 0 else " sign back")
		label.text = text
		label.font_size = 48
		label.pixel_size = .3 / 48.0
		label.outline_size = 0
		label.modulate = Color("ffffff")
		label.position = Vector3(0, .02, face * .035)
		label.rotation.y = PI if face < 0 else 0.0
		board.add_child(label)

## A line of diamond pennants across the store, just under the ceiling.
func bunting(z: float) -> void:
	var line := fixture("Bunting", mesh_of("Bunting", func() -> void:
		art.cyl(Vector3(0, 0, 0), Vector3(.012, 12.6, .012), "2d2f3a", Art.SATIN, Vector3(0, 0, PI / 2), 6)
		var colors := ["d8453a", "2c4f86", "f2c231", "3f9a45", "ec7b2c", "f6f1e6"]
		for k in 21:
			art.bx(Vector3(-6.0 + k * .6, -.13, 0), Vector3(.18, .18, .015), colors[k % colors.size()], Art.MATTE, Vector3(0, 0, PI / 4))),
		Vector3(0, 4.25, z), 0.0, AABB())
	line.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "sports")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "sports", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "sports")


## Game palette and shop row (user, 18 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Game palette and
## shop row"): the storefront recoloured by role from scripts/core/game_palette.gd, accent "meadow".
## Also striped awnings over the two shop windows, like the other storefronts.
func shop_row_style(town: Node3D, game) -> void:
	var ShopRow := preload("res://scripts/buildings/shop_row.gd")
	print("shop_row sports: ", ShopRow.restyle(town, game, "sports"))
	print("shop_row sports awning pieces: ", ShopRow.add_awnings(town, game, "sports"))


## Colours snapped to the game palette with the hue guard (P3-22, decision D14: approved by the
## user 26 Nov 2026 after the library/police trial; scripts/buildings/palette_snap.gd,
## docs/evidence/pastel-20261125/).
func palette_snap(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/palette_snap.gd").snap(town, "sports")
