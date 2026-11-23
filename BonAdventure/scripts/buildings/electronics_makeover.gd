extends RefCounted
## Electronics store clay makeover (user, 18 Nov 2026: the store "needs a huge makeover"; design
## approved in chat; record: docs/guides/TOWN_DESIGN_BRIEF.md "Electronics store makeover —
## 18 November 2026"). Run once by the step `clay_makeover` in electronics.gd, then baked.
## Same shell, door, windows and footprint. Every old fixture, sign and price tag under Interior
## goes; the room is rebuilt in the game palette (cream, wood, one accent: sky) with rounded
## clay-like models from electronics_products.gd and lit screens. The 24 word roots keep their
## nodes, names, keys and pick areas (refitted to the new models); the `sign` plaque (RoomPlaque)
## becomes the CHECKOUT sign. Six signs in all, each a world sign. No prices. A plush clerk
## (salesperson) stands behind the checkout, and ClerkGameSpot marks the clear floor in front of
## the counter for a future clerk minigame.
## Store-local units (the store is scaled 1.3): door gap |x| < 1.8 at z -7.6, rear wall z 7.6,
## side walls x +-5.66; seen from the door +X is on the LEFT.
const Products := preload("res://scripts/buildings/electronics_products.gd")
const WorldSign := preload("res://scripts/world/world_sign.gd")
const Palette := preload("res://scripts/core/game_palette.gd")
const STORE := "Buildings/ElectronicsStore"
const SITE := "RelocatedSites/Electronics"
const Y0 := .085          # floor top
const TOP := .99          # display table top
const CEILING := 5.22
const KEEP := ["Checkout counter", "Cash register", "Shopping bag"]
## [parent: L LearningDisplays, I Interior, S site; node; word; origin (store-local); yaw (the
## model's front, local -Z, turned by it: -PI/2 faces +X, PI/2 faces -X); stands on the floor]
const ROOTS := [
	["L", "Television", "television", Vector3(-5.27, .5, -6.05), -PI / 2, false],
	["L", "Computer", "computer", Vector3(-2.46, TOP, -4.15), -PI / 2, false],
	["L", "Keyboard", "keyboard", Vector3(-2.2, TOP, -4.15), -PI / 2, false],
	["L", "Mouse", "mouse", Vector3(-2.22, TOP, -3.55), -PI / 2, false],
	["L", "Laptop", "laptop", Vector3(-2.38, TOP, -2.65), -PI / 2, false],
	["L", "Smartphone", "smartphone", Vector3(-2.36, TOP, .55), -PI / 2, false],
	["L", "Tablet", "tablet", Vector3(-2.38, TOP, 1.4), -PI / 2, false],
	["S", "Smartwatch", "smartwatch", Vector3(-2.36, TOP, 2.3), -PI / 2, false],
	["L", "Camera", "camera", Vector3(2.4, TOP, -3.45), PI / 2, false],
	["L", "Headphones", "headphones", Vector3(2.4, TOP, .6), PI / 2, false],
	["L", "Speaker", "speaker", Vector3(2.4, TOP, 1.75), PI / 2, false],
	["L", "Refrigerator", "refrigerator", Vector3(5.1, .15, -6.9), PI / 2, true],
	["L", "Washing_Machine", "washing machine", Vector3(5.1, .15, -5.6), PI / 2, true],
	["L", "Dryer", "dryer", Vector3(5.1, .15, -4.5), PI / 2, true],
	["L", "Microwave", "microwave", Vector3(5.2, 1.0, -3.05), PI / 2, false],
	["L", "Fan", "fan", Vector3(5.05, Y0, 3.0), PI / 2, true],
	["S", "Game Console", "game console", Vector3(-5.27, .82, 5.6), -PI / 2, false],
	["L", "Game_Controller", "game controller", Vector3(-5.24, .82, 6.55), -PI / 2 + .25, false],
	["I", "Checkout counter", "checkout counter", Vector3(3.9, Y0 + .41, 5.9), 0.0, false],
	["I", "Cash register", "cash register", Vector3(3.45, Y0 + .82, 5.92), 0.0, false],
	["I", "Shopping bag", "shopping bag", Vector3(4.45, Y0 + .82, 5.95), .3, false],
]
## Sign plaques that are word roots: [parent (S site, T store), node, its label (on the site, or ""
## for a new one), origin, yaw, width, height, icon, posts below the centre, reading distance (m),
## English text of a new label]
const PLAQUES := [
	["S", "Electronics plaque", "ELECTRONICS upgrade sign", Vector3(-.9, 4.15, 7.52), 0.0, 4.3, .8, "plug", 0.0, 16.0, ""],
	["S", "Tech plaque", "TECH upgrade sign", Vector3(-2.93, 1.7, -3.45), -PI / 2, 2.4, .5, "chip", .46, 8.0, ""],
	["S", "Gaming plaque", "GAMING upgrade sign", Vector3(-5.585, 3.1, 6.2), -PI / 2, 2.7, .62, "pad", 0.0, 10.0, ""],
	["T", "RoomPlaque", "", Vector3(4.1, 3.05, 7.56), 0.0, 2.0, .6, "", 0.0, 10.0, "CHECKOUT"],
]
## Department boards (no word): [English, origin, yaw, width, height, reading distance]
const BOARDS := [
	["TELEVISIONS", Vector3(-5.59, 3.05, -6.05), -PI / 2, 2.6, .55, 10.0],
	["APPLIANCES", Vector3(5.59, 3.0, -5.7), PI / 2, 3.4, .55, 10.0],
]
## Display islands: [name, centre x, centre z, length, wall side (the riser's side)]
const ISLANDS := [["Computers island", -2.6, -3.45, 2.9, -1], ["Phones island", -2.6, 1.45, 2.9, -1],
	["Cameras island", 2.6, -3.45, 2.9, 1], ["Audio island", 2.6, 1.3, 2.6, 1]]
const LAMPS := [Vector3(-2.6, 4.55, -4.6), Vector3(-2.6, 4.55, -.2), Vector3(-2.6, 4.55, 4.2),
	Vector3(2.6, 4.55, -4.6), Vector3(2.6, 4.55, -.2), Vector3(2.6, 4.55, 4.2)]
const CLERK_SPOT := Vector3(3.9, Y0, 6.66)
## Clear floor in front of the counter kept for a future clerk minigame (centre; 2 x 2 units).
const GAME_SPOT := Vector3(3.7, Y0, 4.3)

## Small products and display decor 20% bigger (user, 23 Nov 2026; step `bigger_products`, run by
## bigger() below): word roots in BIGGER, the island decor and the small appliances.
const SMALL := 1.2
const BIGGER := ["Computer", "Keyboard", "Mouse", "Laptop", "Smartphone", "Tablet", "Smartwatch",
	"Camera", "Headphones", "Speaker", "Microwave", "Game Console", "Game_Controller", "Cash register",
	"Shopping bag"]
## Grown roots moved so they keep clear of each other and of the islands' risers (store units).
const NUDGE := {"Computer": Vector3(.04, 0, .1), "Keyboard": Vector3(.03, 0, .1),
	"Mouse": Vector3(0, 0, .1), "Laptop": Vector3(.04, 0, 0)}
## The small appliances unit as words (user, 23 Nov 2026): word per shelf (bottom to top) and slot
## (z -1.1, -.37, .37, 1.1); blenders, the tallest, are not on the low bottom shelf.
const SHELF_WORDS := [["toaster", "rice cooker", "kettle", "toaster"],
	["blender", "kettle", "rice cooker", "blender"],
	["rice cooker", "blender", "toaster", "kettle"]]

var kit
var store: Node3D
var interior: Node3D
## Scale of the islands' small decor (1.0 in the 18 Nov makeover, SMALL since 23 Nov).
var small := 1.0

func build(town: Node3D, _game) -> void:
	store = town.get_node(STORE)
	interior = store.get_node("Interior")
	var site: Node3D = town.get_node(SITE)
	var displays: Node3D = store.get_node("LearningDisplays")
	kit = Products.new()
	var freed := 0
	for child in interior.get_children():
		if str(child.name) in KEEP:
			continue
		interior.remove_child(child)
		child.free()
		freed += 1
	var old_label := store.get_node_or_null("Sign_ELECTRONICS")
	if old_label != null:
		store.remove_child(old_label)
		old_label.free()
	# Word roots: new models, same nodes.
	for spec in ROOTS:
		var parent: Node3D = {"L": displays, "I": interior, "S": site}[spec[0]]
		var root := parent.get_node(spec[1]) as Node3D
		_refit(root, kit.model_of(spec[2]), spec[3], spec[4], spec[5])
	# Sign plaques that are words, and the two department boards.
	var deep := Palette.accent("sky", 2).to_html(false)
	for spec in PLAQUES:
		var root: Node3D = (site if spec[0] == "S" else store).get_node(spec[1])
		_refit(root, kit.plaque(spec[5], spec[6], deep, spec[7], spec[8]), spec[3], spec[4], false)
		var label: Label3D
		if spec[2] != "":
			label = site.get_node(spec[2])
		else:
			label = WorldSign.make(store, "Sign_" + spec[10], spec[10], Vector3.ZERO, {"read": spec[9]})
		_letter(label, root.global_transform, spec[5], spec[6], spec[7] != "", spec[9])
	for spec in BOARDS:
		var mesh := MeshInstance3D.new()
		mesh.name = str(spec[0]).capitalize() + " board"
		mesh.mesh = kit.plaque(spec[3], spec[4], deep, "")
		interior.add_child(mesh)
		mesh.transform = Transform3D(Basis(Vector3.UP, spec[2]), spec[1])
		var label := WorldSign.make(interior, spec[0] + " sign", spec[0], Vector3.ZERO, {"read": spec[5]})
		_letter(label, mesh.global_transform, spec[3], spec[4], false, spec[5])
	_room()
	_islands()
	_walls_right()
	_walls_left()
	_rear()
	_lamps()
	# The clerk, and the spot kept for a clerk minigame.
	var characters = preload("res://scripts/characters/house_characters.gd").new()
	characters.worker("res://scenes/characters/golden_plush.tscn", "electronics_shopkeeper", "salesperson",
		interior, "Electronics clerk", store.to_global(CLERK_SPOT), store.global_basis * Vector3(0, 0, -1))
	var spot := Marker3D.new()
	spot.name = "ClerkGameSpot"
	spot.position = GAME_SPOT
	spot.set_meta("clear_size", Vector2(2.0, 2.0))
	spot.set_meta("clerk", "Electronics clerk")
	spot.set_meta("counter", "Checkout counter")
	interior.add_child(spot)
	print("electronics clay_makeover: %d old pieces removed, %d word roots, %d plaques" % [freed, ROOTS.size(), PLAQUES.size()])

## New model for a word root: meshes replaced by one, pick areas refitted (a solid word body is
## fitted exactly), placed at `at` (store-local) facing `yaw`; floor items get a footprint body.
func _refit(root: Node3D, mesh: ArrayMesh, at: Vector3, yaw: float, floor_item: bool) -> void:
	for child in root.get_children():
		if not child is CollisionObject3D or str(child.name) == "Footprint":
			root.remove_child(child)
			child.free()
	root.global_transform = Transform3D(store.global_basis * Basis(Vector3.UP, yaw), store.to_global(at))
	var model := MeshInstance3D.new()
	model.name = "Model"
	model.mesh = mesh
	root.add_child(model)
	var box := mesh.get_aabb()
	for body in root.get_children():
		if not body is CollisionObject3D:
			continue
		body.transform = Transform3D.IDENTITY
		for holder in body.get_children():
			if holder is CollisionShape3D:
				var shape := BoxShape3D.new()
				shape.size = box.size + (Vector3.ONE * .04 if body is Area3D else Vector3.ZERO)
				holder.shape = shape
				holder.transform = Transform3D(Basis.IDENTITY, box.get_center())
	if floor_item:
		var foot := StaticBody3D.new()
		foot.name = "Footprint"
		foot.collision_mask = 0
		var holder := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(box.size.x, minf(.8, box.size.y), box.size.z)
		holder.shape = shape
		holder.position = Vector3(box.get_center().x, shape.size.y * .5, box.get_center().z)
		foot.add_child(holder)
		root.add_child(foot)

## Cream lettering on a sky-deep board whose global transform is `xf`, centred in the space the
## icon leaves (the icon is at the viewer's left end).
func _letter(label: Label3D, xf: Transform3D, w: float, h: float, icon: bool, read: float) -> void:
	var dx := -h * .55 if icon else 0.0
	var free := w - (h * 1.1 if icon else 0.0) - .24
	label.double_sided = false
	label.global_transform = Transform3D(xf.basis * Basis(Vector3.UP, PI), xf * Vector3(dx, 0, -.045))
	WorldSign.restyle(label, {"read": read, "colour": Palette.TRIM, "board": Palette.accent("sky", 2),
		"fit_width": free * xf.basis.get_scale().x})

## One merged mesh of the parts drawn since kit.begin(), under Interior.
func _mesh(title: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.mesh = kit.finish(title)
	interior.add_child(mesh)
	return mesh

## A solid box (store-local centre and size) that blocks the player.
func _solid(title: String, centre: Vector3, size: Vector3, player_only := false) -> void:
	var body := StaticBody3D.new()
	body.name = title + " body"
	if player_only:  # word items stand inside it: stops BonBon, not the pointer
		body.collision_layer = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER
		body.collision_mask = 0
	var holder := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	holder.shape = shape
	body.add_child(holder)
	interior.add_child(body)
	body.position = centre

## A cabinet from `lo` to `hi` (store-local corners): cream body, wood top, sky door fronts with
## knobs on the `face` side (a unit +-X or +-Z vector).
func _cabinet(title: String, lo: Vector3, hi: Vector3, face: Vector3, solid := true) -> void:
	var c := (lo + hi) * .5
	var s := hi - lo
	kit.rbox(Vector3(c.x, lo.y + (s.y - .03) * .5, c.z), Vector3(s.x, s.y - .03, s.z), kit.trim, Products.MATTE, Vector3.ZERO, .04)
	kit.rbox(Vector3(c.x, hi.y - .02, c.z), Vector3(s.x + .04, .04, s.z + .04), kit.wood, Products.MATTE, Vector3.ZERO, .018)
	var along := s.z if face.x != 0 else s.x
	var doors := maxi(1, roundi(along / .8))
	var front := Vector3(c.x + face.x * (s.x * .5 + .004), lo.y + (s.y - .03) * .5, c.z + face.z * (s.z * .5 + .004))
	for k in doors:
		var o := (k - (doors - 1) * .5) * along / doors
		var size := Vector3(.008, s.y - .2, along / doors - .08) if face.x != 0 else Vector3(along / doors - .08, s.y - .2, .008)
		var off := Vector3(0, 0, o) if face.x != 0 else Vector3(o, 0, 0)
		kit.rbox(front + off, size, kit.sky_light, Products.MATTE, Vector3.ZERO, .02)
		kit.ball(front + off + face * .015 + Vector3(0, s.y * .25 - .08, 0), Vector3(.04, .04, .04), kit.sky, Products.SATIN, Vector3.ZERO, 8)
	if solid:
		_solid(title, c, s)

## Floor tiles, the sky walkway and mat, wall bands, skirting and the ceiling.
func _room() -> void:
	kit.begin()
	var tile_a: String = kit.cream_deep
	var tile_b: String = Palette.WALL_CREAM.darkened(.035).to_html(false)
	var nx := 12
	var nz := 16
	var tw := 11.28 / nx
	var td := 15.18 / nz
	for i in nx:
		for j in nz:
			kit.bx(Vector3(-5.64 + (i + .5) * tw, Y0 + .005, -7.59 + (j + .5) * td), Vector3(tw, .01, td), tile_a if (i + j) % 2 == 0 else tile_b)
	kit.bx(Vector3(0, .0975, -.55), Vector3(2.1, .005, 14.0), kit.sky_light)
	for side in [-1, 1]:
		kit.bx(Vector3(side * 1.02, .1005, -.55), Vector3(.07, .004, 14.0), kit.sky)
	kit.rbox(Vector3(0, .106, -7.05), Vector3(2.6, .012, .9), kit.sky_deep, Products.MATTE, Vector3.ZERO, .006)
	# Walls: a sky band at 3.95 and wood skirting (the door gap |x| < 1.8 on the front wall left open).
	for side in [-1, 1]:
		kit.bx(Vector3(side * 5.645, 3.95, 0), Vector3(.03, .2, 15.2), kit.sky)
		kit.bx(Vector3(side * 5.6475, Y0 + .06, 0), Vector3(.025, .12, 15.2), kit.wood)
		kit.bx(Vector3(side * 3.765, 3.95, -7.595), Vector3(3.73, .2, .03), kit.sky)
		kit.bx(Vector3(side * 3.73, Y0 + .06, -7.5975), Vector3(3.8, .12, .025), kit.wood)
	kit.bx(Vector3(0, 3.95, 7.595), Vector3(11.26, .2, .03), kit.sky)
	kit.bx(Vector3(0, Y0 + .06, 7.5975), Vector3(11.26, .12, .025), kit.wood)
	kit.bx(Vector3(0, CEILING + .01, 0), Vector3(11.32, .02, 15.22), kit.trim)
	_mesh("Showroom room")

## Four display islands: rounded cream tables with wood tops, a sky band on the aisle face and
## a raised sky step on the wall side for the decor.
func _islands() -> void:
	for spec in ISLANDS:
		var cx: float = spec[1]
		var cz: float = spec[2]
		var length: float = spec[3]
		var side: int = spec[4]
		kit.begin()
		kit.rbox(Vector3(cx, Y0 + .06, cz), Vector3(1.0, .12, length - .1), kit.stone, Products.MATTE, Vector3.ZERO, .03)
		kit.rbox(Vector3(cx, .5575, cz), Vector3(1.1, .765, length), kit.trim, Products.MATTE, Vector3.ZERO, .06)
		kit.rbox(Vector3(cx, .9625, cz), Vector3(1.16, .055, length + .06), kit.wood, Products.MATTE, Vector3.ZERO, .025)
		kit.rbox(Vector3(cx - side * .556, .66, cz), Vector3(.02, .16, length - .2), kit.sky, Products.SATIN, Vector3.ZERO, .008)
		var rx := cx + side * .33
		kit.rbox(Vector3(rx, 1.115, cz), Vector3(.36, .25, length - .3), kit.sky_light, Products.MATTE, Vector3.ZERO, .05)
		var face := -PI / 2 if side < 0 else PI / 2
		match spec[0]:
			"Computers island":
				pass  # the TECH sign stands on this riser
			"Phones island":
				var tints := [kit.pig, kit.mint, kit.sky_light, kit.coral_light, kit.sun, kit.rose]
				for k in 6:
					kit.rbox(Vector3(rx + side * .03, 1.25 + .13 * small, cz - 1.15 + k * .2), Vector3(.025, .26, .13) * small, tints[k], Products.SATIN, Vector3(0, 0, side * .15), .02)
				for k in 3:
					kit.rbox(Vector3(rx, 1.24 + .05 * small, cz + .5 + k * .3), Vector3(.1, .1, .1) * small, kit.rim, Products.SATIN, Vector3.ZERO, .025)
					kit.ring(Vector3(rx, 1.24 + .005 * small, cz + .5 + k * .3), Vector3(.2, .02, .2) * small, kit.iron, Products.SATIN, Vector3.ZERO, .75, 12)
			"Cameras island":
				var head := Vector3(rx, 1.9, cz - 1.0)
				for k in 3:
					var a := k * TAU / 3
					var foot := Vector3(rx + cos(a) * .14, 1.24, cz - 1.0 + sin(a) * .14)
					kit.cyl((foot + head) * .5, Vector3(.025, (head - foot).length(), .025), kit.iron, Products.SATIN, _euler_up_to((head - foot).normalized()), 6)
				kit.rbox(head + Vector3(0, .03, 0), Vector3(.1, .06, .1), kit.iron, Products.SATIN, Vector3.ZERO, .02)
				for k in 3:
					kit.cyl(Vector3(cx - side * .2, TOP + .08 * small, cz - 1.15 + k * .17), Vector3(.12, .16, .12) * small, kit.iron, Products.SATIN, Vector3.ZERO, 14)
					kit.ring(Vector3(cx - side * .2, TOP + .16 * small, cz - 1.15 + k * .17), Vector3(.13, .02, .13) * small, kit.sky, Products.SATIN, Vector3.ZERO, .7, 14)
				kit.carton(Vector3(rx, 1.24 + .15 * small, cz + .95), Vector3(.28, .3, .22) * small, kit.meadow, face)
				kit.carton(Vector3(rx, 1.24 + .12 * small, cz + .45), Vector3(.24, .24, .2) * small, kit.sky, face)
			"Audio island":
				kit.carton(Vector3(rx, 1.24 + .17 * small, cz - .8), Vector3(.3, .34, .24) * small, kit.sky, face)
				kit.carton(Vector3(rx, 1.24 + .14 * small, cz - .2), Vector3(.26, .28, .22) * small, kit.coral, face)
				for k in 3:
					var at := Vector3(rx, 1.24 + .035 * small, cz + .45 + k * .25)
					kit.rbox(at, Vector3(.1, .07, .14) * small, kit.rim, Products.SATIN, Vector3.ZERO, .034)
					kit.ball(at + Vector3(-side * .05 * small, 0, 0), Vector3(.008, .015, .015) * small, [kit.meadow, kit.sky, kit.coral][k], Products.GLOW, Vector3.ZERO, 8)
		_mesh(spec[0])
		_solid(spec[0], Vector3(cx, (Y0 + TOP) * .5, cz), Vector3(1.1, TOP - Y0, length))

## Euler angles (YXZ) that turn +Y onto `dir`.
func _euler_up_to(dir: Vector3) -> Vector3:
	var axis := Vector3.UP.cross(dir)
	if axis.length() < 1e-5:
		return Vector3.ZERO
	return Basis(axis.normalized(), Vector3.UP.angle_to(dir)).get_euler()

## Right wall (-X): TV wall, soundbar bench, accessories pegboard, plants, gaming corner.
func _walls_right() -> void:
	kit.begin()
	# TV wall: a sky panel, the console under the television and two lit screens above it.
	kit.rbox(Vector3(-5.635, 1.775, -6.05), Vector3(.04, 3.35, 2.9), kit.sky_light, Products.MATTE, Vector3.ZERO, .02)
	_cabinet("TV console", Vector3(-5.62, Y0, -7.35), Vector3(-5.02, .5, -4.75), Vector3(1, 0, 0))
	for z in [-6.65, -5.45]:
		kit._mark_now()
		kit.rbox(Vector3(0, 0, .03), Vector3(1.0, .62, .06), kit.iron, Products.SATIN, Vector3.ZERO, .03)
		kit.screen_landscape(Vector3(0, 0, -.004), .92, .54)
		kit.place(Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(-5.585, 2.45, z)))
	# Soundbar bench under the first window.
	_cabinet("Soundbar bench", Vector3(-5.62, Y0, -4.45), Vector3(-5.22, .5, -2.35), Vector3(1, 0, 0))
	kit.rbox(Vector3(-5.42, .55, -3.75), Vector3(.13, .09, 1.0), kit.iron, Products.SATIN, Vector3.ZERO, .04)
	kit.ball(Vector3(-5.354, .55, -3.4), Vector3(.01, .02, .02), kit.meadow, Products.GLOW, Vector3.ZERO, 8)
	kit.plant(Vector3(-5.42, .5, -2.75), .6)
	# Accessories: a cream pegboard in a sky frame over a low cabinet with the router.
	kit.rbox(Vector3(-5.645, 1.85, 0), Vector3(.02, 1.6, 2.9), kit.sky, Products.MATTE, Vector3.ZERO, .008)
	kit.rbox(Vector3(-5.635, 1.85, 0), Vector3(.03, 1.5, 2.8), kit.trim, Products.MATTE, Vector3.ZERO, .01)
	var tints := [kit.coral, kit.sky, kit.meadow, kit.rose, kit.sun, kit.teal]
	for row in 4:
		for col in 6:
			kit._mark_now()
			kit.blister(row + col, tints[(row * 2 + col) % tints.size()])
			kit.place(Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(-5.6, 1.33 + row * .35, -1.1 + col * .44)))
	_cabinet("Accessories cabinet", Vector3(-5.62, Y0, -1.35), Vector3(-5.16, .92, 1.35), Vector3(1, 0, 0))
	kit.rbox(Vector3(-5.4, .95, .3), Vector3(.22, .06, .34), kit.trim, Products.SATIN, Vector3.ZERO, .025)
	for z in [.18, .42]:
		kit.cyl(Vector3(-5.47, 1.12, z), Vector3(.025, .3, .025), kit.iron, Products.SATIN, Vector3.ZERO, 6)
	for k in 3:
		kit.ball(Vector3(-5.288, .95, .22 + k * .06), Vector3(.008, .015, .015), kit.meadow, Products.GLOW, Vector3.ZERO, 6)
	kit.carton(Vector3(-5.4, .92 + .14, -.6), Vector3(.26, .28, .2), kit.sky, -PI / 2)
	# Plants under the second window.
	for z in [2.55, 4.35]:
		kit.plant(Vector3(-5.25, Y0, z), 1.0)
	# Gaming corner: a deep sky panel, a lit game screen and the console cabinet.
	kit.rbox(Vector3(-5.635, 1.85, 6.2), Vector3(.04, 3.5, 2.7), kit.sky_deep, Products.MATTE, Vector3.ZERO, .02)
	kit._mark_now()
	kit.rbox(Vector3(0, 0, .03), Vector3(1.32, .8, .06), kit.iron, Products.SATIN, Vector3.ZERO, .03)
	kit.screen_game(Vector3(0, 0, -.004), 1.22, .7)
	kit.place(Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(-5.585, 1.75, 6.2)))
	_cabinet("Gaming cabinet", Vector3(-5.62, Y0, 5.0), Vector3(-4.95, .82, 7.35), Vector3(1, 0, 0))
	for k in 5:
		kit.rbox(Vector3(-5.45, .82 + .1, 6.98 + k * .055), Vector3(.17, .2, .035), [kit.coral, kit.sky, kit.meadow, kit.sun, kit.rose][k], Products.SATIN, Vector3.ZERO, .012)
	_mesh("Right wall displays")

## Left wall (+X): appliances on a stone plinth, the microwave counter, the small appliances
## unit, the corner plant by the fan. With `appliance_words` the unit's appliances are left out
## of the merged mesh (bigger() makes them word roots) and its blocker lets the pointer through.
func _walls_left(appliance_words := false) -> void:
	kit.begin()
	kit.rbox(Vector3(5.085, .1175, -5.725), Vector3(1.07, .065, 3.55), kit.stone, Products.MATTE, Vector3.ZERO, .02)
	_solid("Appliance plinth", Vector3(5.085, .1175, -5.725), Vector3(1.07, .065, 3.55))
	_cabinet("Microwave counter", Vector3(4.85, Y0, -3.75), Vector3(5.62, 1.0, -2.35), Vector3(-1, 0, 0))
	# Small appliances: an open wall unit, three shelves of four.
	kit.rbox(Vector3(5.635, 1.05, 0), Vector3(.03, 1.9, 3.0), kit.trim, Products.MATTE, Vector3.ZERO, .01)
	for z in [-1.49, 1.49]:
		kit.rbox(Vector3(5.37, 1.05, z), Vector3(.5, 1.9, .04), kit.trim, Products.MATTE, Vector3.ZERO, .015)
	kit.rbox(Vector3(5.37, .14, 0), Vector3(.5, .11, 3.0), kit.stone, Products.MATTE, Vector3.ZERO, .02)
	for y in [.72, 1.32, 1.98]:
		kit.rbox(Vector3(5.37, y - .02, 0), Vector3(.5, .04, 2.98), kit.wood, Products.MATTE, Vector3.ZERO, .015)
	var tints := [kit.coral_light, kit.mint, kit.pig, kit.sky_light, kit.sun, kit.trim]
	var n := 0
	for y in [.195, .72, 1.32]:
		for z in [-1.1, -.37, .37, 1.1]:
			if not appliance_words:
				kit._mark_now()
				kit.small_appliance(n + n / 4, tints[n % tints.size()])
				kit.place(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(5.37, y, z)))
			n += 1
	_solid("Small appliances unit", Vector3(5.37, 1.05, 0), Vector3(.5, 1.9, 3.0), appliance_words)
	kit.plant(Vector3(5.2, Y0, 4.4), 1.0)
	_mesh("Left wall displays")

## Rear: the home theatre (BonBon on the big screen) and the checkout's stock wall.
func _rear() -> void:
	kit.begin()
	kit.rbox(Vector3(-.9, 1.75, 7.585), Vector3(5.0, 3.3, .04), kit.sky_light, Products.MATTE, Vector3.ZERO, .02)
	kit.rbox(Vector3(-.9, 1.95, 7.51), Vector3(2.92, 1.66, .08), kit.iron, Products.SATIN, Vector3.ZERO, .04)
	kit.screen_bonbon(Vector3(-.9, 1.95, 7.466), 2.78, 1.52)
	_cabinet("Theatre cabinet", Vector3(-3.0, Y0, 6.95), Vector3(1.2, .5, 7.56), Vector3(0, 0, -1))
	kit.rbox(Vector3(-.9, .56, 7.2), Vector3(1.6, .1, .14), kit.iron, Products.SATIN, Vector3.ZERO, .045)
	kit.ball(Vector3(-.9, .56, 7.128), Vector3(.03, .012, .006), kit.sky, Products.GLOW, Vector3.ZERO, 8)
	kit.rbox(Vector3(.5, .525, 7.25), Vector3(.2, .05, .2), kit.trim, Products.SATIN, Vector3.ZERO, .02)
	kit.plant(Vector3(-2.6, .5, 7.25), .55)
	# Checkout stock wall: a back counter and two shelves of boxed products.
	_cabinet("Back counter", Vector3(2.6, Y0, 7.05), Vector3(5.62, .955, 7.59), Vector3(0, 0, -1))
	var tints := [kit.sky, kit.coral, kit.meadow, kit.rose, kit.teal, kit.sun]
	for y in [1.7, 2.3]:
		kit.rbox(Vector3(4.11, y, 7.44), Vector3(2.9, .04, .32), kit.wood, Products.MATTE, Vector3.ZERO, .015)
		var tall := .36 if y < 2.0 else .28
		for k in 6:
			kit.carton(Vector3(2.88 + k * .47, y + .02 + tall * .5, 7.45), Vector3(.34, tall, .24), tints[(k + (2 if y > 2.0 else 0)) % tints.size()])
	for k in 3:
		kit.carton(Vector3(4.6 + k * .32, .955 + .13, 7.32), Vector3(.26, .26, .22), tints[k + 3])
	_mesh("Rear displays")

## Six pendant lamps over the islands, each with a light (no shadows) as before.
func _lamps() -> void:
	kit.begin()
	for at in LAMPS:
		kit.pendant(at, CEILING)
	_mesh("Pendant lamps")
	for at in LAMPS:
		var light := OmniLight3D.new()
		light.name = "Showroom light"
		light.position = at + Vector3(0, -.35, 0)
		light.light_energy = .5
		light.omni_range = 7.5
		light.light_color = Color(1.0, .96, .9)
		light.shadow_enabled = false
		interior.add_child(light, true)

## Step `bigger_products` (user, 23 Nov 2026: make the small items 20% bigger, keep the design;
## the rice cookers, toasters and blenders become words). The roots in BIGGER get their model at
## SMALL (pick areas refitted, NUDGE keeps them clear), the four islands and the left wall are
## rebuilt with the decor at SMALL, and the twelve small appliances become word roots under
## LearningDisplays, each SMALL x its 18 Nov size, standing on its shelf.
func bigger(town: Node3D) -> String:
	store = town.get_node(STORE)
	interior = store.get_node("Interior")
	var site: Node3D = town.get_node(SITE)
	var displays: Node3D = store.get_node("LearningDisplays")
	kit = Products.new()
	var grown := 0
	for spec in ROOTS:
		if not str(spec[1]) in BIGGER:
			continue
		var parent: Node3D = {"L": displays, "I": interior, "S": site}[spec[0]]
		var root := parent.get_node(spec[1]) as Node3D
		_refit(root, kit.model_of(spec[2], SMALL), spec[3] + NUDGE.get(spec[1], Vector3.ZERO), spec[4], spec[5])
		grown += 1
	for title in ["Computers island", "Phones island", "Cameras island", "Audio island", "Left wall displays"]:
		_drop(title)
		_drop(title + " body")
	for title in ["Appliance plinth", "Microwave counter", "Small appliances unit"]:
		_drop(title + " body")
	small = SMALL
	_islands()
	_walls_left(true)
	var items = preload("res://scripts/buildings/sports.gd").new()
	var tints := [kit.coral_light, kit.mint, kit.pig, kit.sky_light, kit.sun, kit.trim]
	var counts := {}
	var n := 0
	for level in 3:
		for slot in 4:
			var word: String = SHELF_WORDS[level][slot]
			counts[word] = counts.get(word, 0) + 1
			var title := word.capitalize() + ("" if counts[word] == 1 else " %d" % counts[word])
			var root: Node3D = items.item(title, word, kit.appliance(word, tints[n % tints.size()], SMALL), Vector3.ZERO, 0.0, displays)
			root.global_transform = Transform3D(store.global_basis * Basis(Vector3.UP, PI / 2),
				store.to_global(Vector3(5.37, [.195, .72, 1.32][level], [-1.1, -.37, .37, 1.1][slot])))
			n += 1
	return "%d roots grown, %d appliance words %s" % [grown, n, counts]

func _drop(title: String) -> void:
	var node := interior.get_node_or_null(title)
	if node != null:
		interior.remove_child(node)
		node.free()
