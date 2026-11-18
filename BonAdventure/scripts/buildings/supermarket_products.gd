extends RefCounted
## Grocery product models (8 Nov 2026; style guide and record:
## docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket product art"). Used by scripts/buildings/supermarket.gd.
##
## Every product unit is ONE MeshInstance3D whose mesh is a cached ArrayMesh merged from
## low-poly primitives with vertex colours, in up to three shared finishes (matte paper/bread/
## meat, satin skins/plastic/glass, metal lids/cans). All units of a kind and variant share one
## mesh, so render_culling.gd batches them into a MultiMesh per cell, and the whole store uses
## three product materials. Models are authored in market units at the 2 Nov 2026 footprint
## (FOOT: across, deep, height; base on y = 0, front facing -Z) and grown by goods_scale() as
## before, so every unit still fits inside its word root's pick area.

const MATTE := 0
const SATIN := 1
const METAL := 2

## Spacing across, spacing deep and height of one unit (market units, before goods_scale).
## Unchanged from the 2 Nov 2026 refit, so the restocked groups match their pick areas.
const FOOT = {
	"apple":Vector3(.15,.15,.15), "orange":Vector3(.16,.16,.15), "lemon":Vector3(.15,.13,.12), "lime":Vector3(.11,.11,.1),
	"pear":Vector3(.14,.14,.2), "peach":Vector3(.14,.14,.14), "cherry":Vector3(.08,.08,.08), "strawberry":Vector3(.08,.08,.09),
	"grapes":Vector3(.16,.16,.13), "banana":Vector3(.2,.34,.07), "pineapple":Vector3(.2,.2,.36), "mango":Vector3(.17,.14,.13),
	"coconut":Vector3(.17,.17,.17), "watermelon":Vector3(.52,.4,.38), "avocado":Vector3(.12,.12,.14),
	"tomato":Vector3(.14,.14,.13), "carrot":Vector3(.08,.3,.06), "broccoli":Vector3(.14,.14,.16), "potato":Vector3(.16,.12,.1),
	"lettuce":Vector3(.2,.2,.18), "onion":Vector3(.13,.13,.16), "garlic":Vector3(.1,.1,.1), "corn":Vector3(.1,.3,.08),
	"chili pepper":Vector3(.06,.2,.045), "mushroom":Vector3(.1,.1,.08), "cucumber":Vector3(.08,.32,.07), "bell pepper":Vector3(.15,.15,.16),
	"cereal":Vector3(.22,.1,.3), "rice":Vector3(.18,.1,.22), "beans":Vector3(.17,.09,.18), "flour":Vector3(.18,.11,.24),
	"sugar":Vector3(.16,.1,.2), "pasta":Vector3(.1,.08,.24), "tortilla":Vector3(.22,.22,.12), "oil":Vector3(.1,.1,.29),
	"salt":Vector3(.1,.1,.15), "pepper":Vector3(.07,.07,.15), "honey":Vector3(.11,.11,.13), "jam":Vector3(.1,.1,.12),
	"salsa":Vector3(.11,.11,.13), "olive":Vector3(.1,.1,.14), "jar":Vector3(.12,.12,.15), "can":Vector3(.1,.1,.12),
	"tuna":Vector3(.11,.11,.05), "soup":Vector3(.1,.1,.12), "coffee":Vector3(.08,.08,.22), "tea":Vector3(.18,.1,.1),
	"cookie":Vector3(.2,.09,.06), "cracker":Vector3(.15,.07,.19), "snack":Vector3(.17,.09,.23), "chocolate":Vector3(.07,.05,.13), "candy":Vector3(.09,.05,.1),
	"milk":Vector3(.11,.11,.21), "yogurt":Vector3(.085,.085,.07), "butter":Vector3(.13,.08,.045), "cheese":Vector3(.14,.1,.07),
	"eggs":Vector3(.22,.12,.09), "ham":Vector3(.18,.14,.05), "sausage":Vector3(.18,.14,.06), "salad":Vector3(.16,.08,.2),
	"chicken":Vector3(.2,.15,.08), "meat":Vector3(.2,.15,.06), "steak":Vector3(.25,.17,.05), "fish":Vector3(.14,.38,.08),
	"shrimp":Vector3(.1,.1,.05), "water bottle":Vector3(.08,.08,.25), "juice":Vector3(.1,.1,.22), "soda":Vector3(.08,.08,.23),
	"soap":Vector3(.11,.08,.04), "sponge":Vector3(.12,.08,.05), "detergent":Vector3(.15,.1,.26), "toothbrush":Vector3(.06,.04,.2),
	"toothpaste":Vector3(.18,.06,.05), "shampoo":Vector3(.1,.07,.23), "toilet paper":Vector3(.23,.23,.13),
	"bread":Vector3(.22,.2,.13), "baguette":Vector3(.5,.08,.06), "croissant":Vector3(.18,.12,.06), "cake":Vector3(.3,.3,.14),
	"cupcake":Vector3(.1,.1,.08), "donut":Vector3(.12,.12,.05)
}

## Loose produce is piled (layers from the pick height, small random turn, size and offset);
## everything else stands in neat front-facing rows.
const PILED := ["apple", "orange", "lemon", "lime", "pear", "peach", "cherry", "strawberry", "grapes", "banana",
	"pineapple", "mango", "coconut", "watermelon", "avocado", "tomato", "carrot", "broccoli", "potato", "lettuce",
	"onion", "garlic", "corn", "chili pepper", "mushroom", "cucumber", "bell pepper", "shrimp", "bread", "croissant",
	"donut", "cupcake"]
## Most units in one group (the 2 Nov groups held at most 30).
const CAP := 30

## Shared colours (style guide). Brand colours are saturated mid-tones; labels are cream or
## white so the front picture reads; produce keeps natural hues.
const WHITE := "f7f4ee"
const CREAM := "f3ead6"
const KRAFT := "c9a477"
const NAVY := "2b5a8c"
const GOLD := "e8b04b"
const LEAF := "4f8f3a"
const DARK_LEAF := "2f6b2f"
const STEM := "6b4a2b"
const SILVER := "c3cbd1"
const TRAY := "f4f1ea"
const DARK_TRAY := "3a4044"

var _prims := {}
var _models := {}
var _materials: Array[StandardMaterial3D] = []
## The mesh being built: per finish, vertices, normals, colours and indices.
var _v: Array = []
var _n: Array = []
var _c: Array = []
var _i: Array = []

func _init() -> void:
	for spec in [[.85, 0.0], [.5, 0.0], [.32, .45]]:
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		material.roughness = spec[0]
		material.metallic = spec[1]
		_materials.append(material)

## Products are drawn larger than life so they read from across the aisle (3 Nov 2026).
func goods_scale(kind: String) -> float:
	var foot: Vector3 = FOOT[kind]
	var biggest := maxf(foot.x, maxf(foot.y, foot.z))
	var want := 1.9 if biggest <= .12 else (1.7 if biggest <= .2 else 1.4)
	return clampf(minf(want, .4 / foot.z), 1.0, want)

func variants(kind: String) -> int:
	return int({"apple":3, "pear":2, "peach":1, "grapes":2, "banana":2, "mango":2, "coconut":2, "watermelon":2,
		"avocado":2, "onion":2, "mushroom":2, "bell pepper":3, "cereal":4, "rice":2, "pasta":2, "oil":2, "jam":3,
		"can":3, "coffee":2, "tea":2, "snack":4, "chocolate":3, "candy":4, "milk":3, "yogurt":3, "cheese":2,
		"eggs":2, "water bottle":1, "soda":3, "juice":3, "soap":3, "sponge":2, "detergent":3, "toothbrush":3,
		"toothpaste":2, "shampoo":3, "bread":3, "cake":3, "cupcake":3, "donut":3, "fish":2, "cookie":2, "cracker":2}.get(kind, 1))

## The cached mesh of one product unit.
func model(kind: String, variant := 0) -> ArrayMesh:
	var key := "%s:%d" % [kind, variant]
	if not _models.has(key):
		begin()
		call("_" + kind.replace(" ", "_"), variant)
		_models[key] = finish("Product " + key)
	return _models[key]

## Start a merged mesh; add parts with bx(), ball(), cyl() ... and close it with finish().
func begin() -> void:
	_v = []; _n = []; _c = []; _i = []
	for f in 3:
		_v.append(PackedVector3Array()); _n.append(PackedVector3Array())
		_c.append(PackedColorArray()); _i.append(PackedInt32Array())

func finish(title: String) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	mesh.resource_name = title
	for f in 3:
		if _i[f].is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = _v[f]
		arrays[Mesh.ARRAY_NORMAL] = _n[f]
		arrays[Mesh.ARRAY_COLOR] = _c[f]
		arrays[Mesh.ARRAY_INDEX] = _i[f]
		# Compressed positions and normals: about half the vertex data in the saved scene.
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _materials[f])
	return mesh

## Shelf-edge price tags for a double-sided gondola (2 Nov 2026 frame: gold price channels at
## x = +-.545, y = .12 + level x .45; `bays` equal bays along z), one white tag per bay.
func shelf_tags(length: float, bays: int, levels: int) -> ArrayMesh:
	begin()
	for level in levels:
		var y := .12 + level * .45
		for side in [-1, 1]:
			for b in bays:
				var z := -length * .5 + length / bays * (b + .5)
				bx(Vector3(side * .557, y, z), Vector3(.004, .04, .075), WHITE, MATTE)
				bx(Vector3(side * .5595, y + .006, z + .015), Vector3(.002, .016, .03), "c62828", MATTE)
				bx(Vector3(side * .5595, y - .01, z - .012), Vector3(.002, .008, .036), "37474f", MATTE)
	return finish("Shelf price tags")

## Replace the meshes of one goods group (a word root with one pick Area3D) with new units.
## The root, its name, word_key and pick area stay exactly as they were; the footprint is read
## back from the pick area (size = w + .02, h + .02, d + .02 + pad; turned to the goods' yaw).
## Returns the number of units placed.
func restock(root: Node3D) -> int:
	var kind := str(root.get_meta("word_key"))
	var area: Area3D
	for child in root.get_children():
		if child is Area3D:
			area = child
	var box: Vector3 = ((area.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
	var yaw := area.rotation.y
	var pad := Vector2(area.position.x, area.position.z).length() * 2.0
	var w := box.x - .02
	var h := box.y - .02
	var d := box.z - .02 - pad
	for child in root.get_children():
		if child is MeshInstance3D:
			root.remove_child(child)
			child.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(root.name) + kind)
	var grow := goods_scale(kind)
	var foot: Vector3 = FOOT[kind] * grow
	# Never taller than the pick area: shrink the rare unit that would poke out of it.
	if foot.z > h + .005:
		grow *= h / foot.z
		foot = FOOT[kind] * grow
	var piled := kind in PILED
	var layers := clampi(roundi((h / foot.z - 1.0) / .75) + 1, 1, 2) if piled else 1
	var cols := maxi(1, int(w / foot.x))
	# Shelf goods (gondolas, end caps, racks: no front reach, at most .45 deep) stand one row deep
	# as before; fridges, the cooler and service counters show two rows; produce fills its bin.
	var deep_max := 5 if piled else (1 if pad < .01 and d <= .45 else 2)
	var deep := clampi(int(d / foot.y), 1, deep_max)
	while cols * deep * layers > CAP and deep > 1:
		deep -= 1
	while cols * deep * layers > CAP and cols > 1:
		cols -= 1
	var step := Vector2(w / cols, d / deep)
	var placed := 0
	# Small groups (a few cakes) step through the variants so each one shows; larger groups
	# pick at random like a mixed shelf.
	var cycle := cols * deep * layers <= 2 * variants(kind)
	var first := rng.randi()
	for layer in range(layers):
		var row_deep := maxi(1, deep - layer)
		for i in range(cols - layer):
			for j in range(row_deep):
				var o := Vector3((i - (cols - 1 - layer) * .5) * step.x, layer * foot.z * .75, (j - (row_deep - 1) * .5) * step.y)
				var turn := 0.0
				var size := 1.0
				if piled:
					o += Vector3(rng.randf_range(-.015, .015), 0, rng.randf_range(-.015, .015))
					turn = rng.randf_range(-.3, .3)
					size = rng.randf_range(.92, 1.0)
				var unit := MeshInstance3D.new()
				unit.name = "%s %d" % [kind.capitalize(), placed + 1]
				unit.mesh = model(kind, (first + placed if cycle else rng.randi()) % variants(kind))
				unit.transform = Transform3D(Basis(Vector3.UP, yaw + turn).scaled(Vector3.ONE * grow * size), o.rotated(Vector3.UP, yaw))
				root.add_child(unit)
				placed += 1
	return placed

# ---------------------------------------------------------------------------------------------
# Primitive building. Every primitive is normalised to a unit bounding box centred on the origin,
# so `s` is always the part's size (diameter, height) before `r` (Euler, YXZ) turns it.

func _prim(kind: String, sides: int, top: float) -> Array:
	var key := "%s:%d:%s" % [kind, sides, top]
	if _prims.has(key):
		return _prims[key]
	var mesh: PrimitiveMesh
	match kind:
		"box":
			mesh = BoxMesh.new()
		"ball", "half":
			var ball := SphereMesh.new()
			ball.radial_segments = sides
			ball.rings = maxi(3, sides / 2)
			ball.is_hemisphere = kind == "half"
			mesh = ball
		"cyl":
			var tube := CylinderMesh.new()
			tube.top_radius = .5 * top
			tube.bottom_radius = .5
			tube.height = 1.0
			tube.radial_segments = sides
			tube.rings = 0
			mesh = tube
		"prism":
			mesh = PrismMesh.new()
		"ring":
			var ring := TorusMesh.new()
			ring.inner_radius = .5 * top
			ring.outer_radius = .5
			ring.rings = sides
			ring.ring_segments = 6
			mesh = ring
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bounds := AABB(verts[0], Vector3.ZERO)
	for v in verts:
		bounds = bounds.expand(v)
	var fit := Transform3D(Basis.from_scale(Vector3(1.0 / bounds.size.x, 1.0 / bounds.size.y, 1.0 / bounds.size.z)), Vector3.ZERO)
	fit.origin = -(fit.basis * bounds.get_center())
	var normal_basis := fit.basis.inverse().transposed()
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for k in verts.size():
		verts[k] = fit * verts[k]
		normals[k] = (normal_basis * normals[k]).normalized()
	_prims[key] = [verts, normals, arrays[Mesh.ARRAY_INDEX]]
	return _prims[key]

func _add(kind: String, c: Vector3, s: Vector3, tint: String, f: int, r: Vector3, sides := 10, top := 1.0) -> void:
	# Vertex budget (8 Nov 2026): round parts drawn with 10+ sides lose two; at shelf distance
	# the outline is unchanged and the store's product vertices drop by about a quarter.
	var source: Array = _prim(kind, sides - 2 if sides >= 10 else sides, top)
	var xf := Transform3D(Basis.from_euler(r) * Basis.from_scale(s), c)
	var normal_basis := xf.basis.inverse().transposed()
	var base: int = _v[f].size()
	var colour := Color(tint)
	for v in source[0]:
		_v[f].append(xf * v)
		_c[f].append(colour)
	for nrm in source[1]:
		_n[f].append((normal_basis * nrm).normalized())
	for k in source[2]:
		_i[f].append(base + k)

func bx(c: Vector3, s: Vector3, tint: String, f := MATTE, r := Vector3.ZERO) -> void:
	_add("box", c, s, tint, f, r)

func ball(c: Vector3, s: Vector3, tint: String, f := SATIN, r := Vector3.ZERO, sides := 10) -> void:
	_add("ball", c, s, tint, f, r, sides)

## Dome: the upper half of a ball (flat face down); turn it with r.x = PI for a bowl.
func dome(c: Vector3, s: Vector3, tint: String, f := SATIN, r := Vector3.ZERO, sides := 10) -> void:
	_add("half", c, s, tint, f, r, sides)

## Upright cylinder (top radius = top x bottom); r turns it.
func cyl(c: Vector3, s: Vector3, tint: String, f := MATTE, r := Vector3.ZERO, sides := 10, top := 1.0) -> void:
	_add("cyl", c, s, tint, f, r, sides, top)

## Triangle in the xy plane with its apex at +y, extruded along z.
func prism(c: Vector3, s: Vector3, tint: String, f := MATTE, r := Vector3.ZERO) -> void:
	_add("prism", c, s, tint, f, r)

func ring(c: Vector3, s: Vector3, tint: String, f := SATIN, r := Vector3.ZERO, hole := .5, sides := 12) -> void:
	_add("ring", c, s, tint, f, r, sides, hole)

## Small flat picture on a package front (z = front face), a disc facing -Z.
func badge(c: Vector3, diameter: float, tint: String, f := MATTE) -> void:
	cyl(c, Vector3(diameter, .004, diameter), tint, f, Vector3(PI / 2, 0, 0), 10)

func pick(variant: int, tints: Array) -> String:
	return tints[variant % tints.size()]

func darker(tint: String, amount := .25) -> String:
	return Color(tint).darkened(amount).to_html(false)

func lighter(tint: String, amount := .3) -> String:
	return Color(tint).lightened(amount).to_html(false)

## Department pictogram for a wall band (8 Nov 2026): a cream silhouette about 1 unit wide in
## the xy plane, facing -Z, with details cut out in the department colour `cut`.
func pictogram(kind: String, cut: String) -> ArrayMesh:
	begin()
	var ink := WHITE
	match kind:
		"fish":
			ball(Vector3(-.08, 0, 0), Vector3(.72, .34, .02), ink, MATTE, Vector3.ZERO, 16)
			prism(Vector3(.36, 0, 0), Vector3(.34, .24, .02), ink, MATTE, Vector3(0, 0, PI / 2))
			ball(Vector3(-.3, .05, -.012), Vector3(.07, .07, .01), cut, MATTE, Vector3.ZERO, 10)
			bx(Vector3(-.16, 0, -.012), Vector3(.02, .24, .01), cut, MATTE, Vector3(0, 0, .15))
		"drumstick":
			ball(Vector3(-.12, .08, 0), Vector3(.58, .42, .02), ink, MATTE, Vector3(0, 0, -.6), 16)
			bx(Vector3(.17, -.16, 0), Vector3(.28, .09, .02), ink, MATTE, Vector3(0, 0, -.6))
			for o in [Vector3(.27, -.2, 0), Vector3(.22, -.29, 0)]:
				ball(Vector3(.06, .1, 0) + o, Vector3(.12, .12, .02), ink, MATTE, Vector3.ZERO, 10)
			ball(Vector3(-.2, .14, -.012), Vector3(.1, .16, .01), cut, MATTE, Vector3(0, 0, -.6), 8)
		"bread":
			dome(Vector3(0, .02, 0), Vector3(.86, .4, .02), ink, MATTE, Vector3.ZERO, 16)
			bx(Vector3(0, -.09, 0), Vector3(.86, .22, .02), ink, MATTE)
			for k in 3:
				bx(Vector3(-.2 + k * .2, .06, -.012), Vector3(.04, .2, .01), cut, MATTE, Vector3(0, 0, -.5))
		"apple":
			ball(Vector3(0, -.04, 0), Vector3(.62, .58, .02), ink, MATTE, Vector3.ZERO, 16)
			bx(Vector3(0, .3, 0), Vector3(.04, .16, .02), ink, MATTE, Vector3(0, 0, -.2))
			ball(Vector3(.13, .32, 0), Vector3(.22, .1, .02), ink, MATTE, Vector3(0, 0, .45), 10)
			ball(Vector3(-.14, .06, -.012), Vector3(.08, .14, .01), cut, MATTE, Vector3(0, 0, .5), 8)
		"jar":
			bx(Vector3(0, -.06, 0), Vector3(.46, .58, .02), ink, MATTE)
			bx(Vector3(0, .3, 0), Vector3(.52, .12, .02), ink, MATTE)
			bx(Vector3(0, -.06, -.012), Vector3(.36, .22, .01), cut, MATTE)
			bx(Vector3(0, .225, -.012), Vector3(.5, .025, .01), cut, MATTE)
		"candy":  # a wrapped sweet (SNACKS, 17 Nov 2026)
			ball(Vector3.ZERO, Vector3(.4, .34, .02), ink, MATTE, Vector3.ZERO, 16)
			for side in [-1, 1]:
				prism(Vector3(side * .3, 0, 0), Vector3(.3, .22, .02), ink, MATTE, Vector3(0, 0, side * PI / 2))
			bx(Vector3(-.05, .02, -.012), Vector3(.05, .22, .01), cut, MATTE, Vector3(0, 0, .5))
			bx(Vector3(.07, -.02, -.012), Vector3(.05, .22, .01), cut, MATTE, Vector3(0, 0, .5))
	return finish("Department pictogram " + kind)

# ---------------------------------------------------------------------------------------------
# Fruit

func _apple(v: int) -> void:
	var skin := pick(v, ["c8312b", "a8242a", "8cbf3f"])
	ball(Vector3(0, .068, 0), Vector3(.14, .13, .14), skin, SATIN, Vector3.ZERO, 12)
	ball(Vector3(-.02, .075, -.03), Vector3(.1, .1, .09), lighter(skin, .12), SATIN)
	ball(Vector3(0, .13, 0), Vector3(.045, .012, .045), darker(skin, .35), SATIN, Vector3.ZERO, 8)
	cyl(Vector3(.003, .148, 0), Vector3(.01, .04, .01), STEM, MATTE, Vector3(0, 0, .25), 5)
	ball(Vector3(.025, .152, 0), Vector3(.045, .01, .022), LEAF, SATIN, Vector3(0, 0, -.35), 6)

func _orange(_v: int) -> void:
	ball(Vector3(0, .072, 0), Vector3(.15, .14, .15), "f08a24", SATIN, Vector3.ZERO, 12)
	ball(Vector3(0, .141, 0), Vector3(.022, .006, .022), "b8651a", MATTE, Vector3.ZERO, 6)
	ball(Vector3(.016, .146, 0), Vector3(.04, .008, .02), LEAF, SATIN, Vector3(0, .4, -.25), 6)

func _lemon(_v: int) -> void:
	ball(Vector3(0, .055, 0), Vector3(.12, .1, .1), "f4d23c", SATIN, Vector3.ZERO, 12)
	for side in [-1, 1]:
		ball(Vector3(side * .062, .055, 0), Vector3(.03, .028, .028), "e8c22e", SATIN, Vector3.ZERO, 6)

func _lime(_v: int) -> void:
	ball(Vector3(0, .047, 0), Vector3(.095, .088, .088), "6fb03a", SATIN, Vector3.ZERO, 10)
	for side in [-1, 1]:
		ball(Vector3(side * .048, .047, 0), Vector3(.018, .018, .018), "5a9a2e", SATIN, Vector3.ZERO, 6)

func _pear(v: int) -> void:
	var skin := pick(v, ["c3cf4f", "d9b84a"])
	ball(Vector3(0, .055, 0), Vector3(.125, .11, .125), skin, SATIN, Vector3.ZERO, 12)
	ball(Vector3(0, .115, 0), Vector3(.085, .09, .085), skin, SATIN)
	ball(Vector3(0, .158, 0), Vector3(.05, .05, .05), skin, SATIN, Vector3.ZERO, 8)
	ball(Vector3(-.025, .06, -.035), Vector3(.06, .05, .04), "d8834a" if v == 1 else "a9b843", SATIN, Vector3.ZERO, 8)
	cyl(Vector3(.005, .193, 0), Vector3(.01, .035, .01), STEM, MATTE, Vector3(0, 0, -.3), 5)

func _peach(_v: int) -> void:
	ball(Vector3(0, .065, 0), Vector3(.13, .125, .13), "f7b27a", SATIN, Vector3.ZERO, 12)
	ball(Vector3(-.008, .066, -.014), Vector3(.115, .11, .11), "ef8a68", SATIN)
	ball(Vector3(.018, .13, 0), Vector3(.04, .008, .02), LEAF, SATIN, Vector3(0, 0, -.3), 6)

func _cherry(_v: int) -> void:
	for side in [-1, 1]:
		ball(Vector3(side * .02, .022, 0), Vector3(.044, .042, .044), "9e1b32", SATIN, Vector3.ZERO, 8)
		cyl(Vector3(side * .011, .062, 0), Vector3(.005, .055, .005), "5d7a2a", MATTE, Vector3(0, 0, side * -.35), 4)
	ball(Vector3(.012, .09, 0), Vector3(.035, .008, .018), LEAF, SATIN, Vector3(0, 0, -.3), 6)

func _strawberry(_v: int) -> void:
	cyl(Vector3(0, .027, 0), Vector3(.064, .05, .064), "d7263d", SATIN, Vector3(PI, 0, 0), 8, 0.0)
	ball(Vector3(0, .055, 0), Vector3(.068, .045, .068), "d7263d", SATIN, Vector3.ZERO, 8)
	for k in 4:
		var a := k * TAU / 4 + .4
		ball(Vector3(cos(a) * .028, .042, sin(a) * .028), Vector3(.007, .007, .007), "f6e27a", MATTE, Vector3.ZERO, 4)
	for k in 4:
		bx(Vector3(0, .078, 0), Vector3(.055, .006, .012), "3f7d3a", MATTE, Vector3(0, k * PI / 4, 0))
	cyl(Vector3(0, .085, 0), Vector3(.008, .014, .008), "3f7d3a", MATTE, Vector3.ZERO, 4)

func _grapes(v: int) -> void:
	var tint := pick(v, ["6b3d8f", "9cc04a"])
	var shade := darker(tint, .2)
	var rows := [[.025, 1, 0.0], [.052, 3, .022], [.08, 5, .036], [.105, 4, .03]]
	var n := 0
	for row in rows:
		for k in int(row[1]):
			var a: float = k * TAU / row[1] + row[0] * 20.0
			ball(Vector3(cos(a) * row[2], row[0], sin(a) * row[2]), Vector3(.034, .036, .034), tint if n % 3 else shade, SATIN, Vector3.ZERO, 6)
			n += 1
	cyl(Vector3(0, .127, 0), Vector3(.008, .03, .008), STEM, MATTE, Vector3.ZERO, 4)
	ball(Vector3(.02, .125, 0), Vector3(.05, .008, .035), LEAF, SATIN, Vector3(0, 0, -.2), 6)

func _banana(v: int) -> void:
	var skin := pick(v, ["f5d142", "c9d64a"])
	for b in 3:
		var x := (b - 1) * .05
		var y := .03 + (.008 if b == 1 else 0.0)
		for seg in 3:
			var bend := (seg - 1) * .32
			cyl(Vector3(x + absf(seg - 1) * .02, y, (seg - 1) * .095), Vector3(.042, .105, .038), skin, SATIN, Vector3(PI / 2, bend, 0), 7)
		cyl(Vector3(x + .03, y, .155), Vector3(.016, .03, .016), STEM, MATTE, Vector3(PI / 2, .3, 0), 5)
		cyl(Vector3(x + .03, y, -.152), Vector3(.012, .02, .012), "4a3a28", MATTE, Vector3(PI / 2, -.3, 0), 5)
	ball(Vector3(.03, .035, .168), Vector3(.07, .03, .03), "8a7a3a", MATTE, Vector3.ZERO, 6)

func _pineapple(_v: int) -> void:
	ball(Vector3(0, .125, 0), Vector3(.16, .24, .16), "c8962e", MATTE, Vector3.ZERO, 10)
	for row in 3:
		for k in 6:
			var a := k * TAU / 6 + row * .5
			var rad := .074 if row == 1 else .066
			ball(Vector3(cos(a) * rad, .07 + row * .055, sin(a) * rad), Vector3(.03, .03, .03), "8a5f1f", MATTE, Vector3.ZERO, 4)
	for k in 6:
		prism(Vector3(0, .29, 0), Vector3(.035, .13, .012), "3f7d3a" if k % 2 else DARK_LEAF, MATTE, Vector3(.35, k * TAU / 6, 0))
	prism(Vector3(0, .29, 0), Vector3(.03, .14, .012), "4f8f3a", MATTE)

func _mango(v: int) -> void:
	var skin := pick(v, ["f2a03d", "8fb33a"])
	ball(Vector3(0, .06, 0), Vector3(.16, .115, .12), skin, SATIN, Vector3(0, 0, .15), 12)
	ball(Vector3(.03, .066, -.012), Vector3(.1, .095, .09), "e0573b" if v == 0 else "e0a03b", SATIN)
	cyl(Vector3(.07, .1, 0), Vector3(.01, .02, .01), STEM, MATTE, Vector3.ZERO, 5)

func _coconut(v: int) -> void:
	if v == 0:
		ball(Vector3(0, .08, 0), Vector3(.16, .155, .16), "6d4c3d", MATTE, Vector3.ZERO, 10)
		ball(Vector3(0, .1, -.02), Vector3(.13, .11, .13), "7e5a46", MATTE, Vector3(.4, 0, 0), 8)
		for k in 3:
			var a := k * TAU / 3
			ball(Vector3(cos(a) * .022, .155, sin(a) * .022 - .01), Vector3(.016, .008, .016), "3a2a22", MATTE, Vector3.ZERO, 5)
	else:
		# A halved coconut, cut face up.
		dome(Vector3(0, .042, 0), Vector3(.16, .085, .16), "6d4c3d", MATTE, Vector3(PI, 0, 0))
		cyl(Vector3(0, .085, 0), Vector3(.158, .006, .158), "5a3e30", MATTE, Vector3.ZERO, 12)
		cyl(Vector3(0, .088, 0), Vector3(.13, .006, .13), "f8f4ea", MATTE, Vector3.ZERO, 12)

func _watermelon(v: int) -> void:
	if v == 0:
		ball(Vector3(0, .18, 0), Vector3(.5, .36, .38), "6fae4a", SATIN, Vector3.ZERO, 12)
		for k in 4:
			ball(Vector3(0, .18, 0), Vector3(.505, .366, .07), "2f6b2f", SATIN, Vector3(k * PI / 4, 0, 0), 12)
	else:
		# Half a melon, cut face up: rind, pale band, red flesh and seeds.
		dome(Vector3(0, .09, 0), Vector3(.5, .18, .38), "2f6b2f", SATIN, Vector3(PI, 0, 0), 12)
		cyl(Vector3(0, .182, 0), Vector3(.49, .008, .37), "e9f0c4", MATTE, Vector3.ZERO, 14)
		cyl(Vector3(0, .186, 0), Vector3(.44, .008, .32), "e5484d", SATIN, Vector3.ZERO, 14)
		for k in 7:
			var a := k * TAU / 7
			ball(Vector3(cos(a) * .12, .19, sin(a) * .08), Vector3(.018, .006, .011), "2a1f1a", SATIN, Vector3(0, a, 0), 4)

func _avocado(v: int) -> void:
	if v == 0:
		ball(Vector3(0, .05, 0), Vector3(.1, .1, .1), "3e5b2a", MATTE, Vector3.ZERO, 10)
		ball(Vector3(0, .095, 0), Vector3(.072, .085, .072), "3e5b2a", MATTE, Vector3.ZERO, 8)
		cyl(Vector3(0, .14, 0), Vector3(.012, .015, .012), STEM, MATTE, Vector3.ZERO, 5)
	else:
		# Halved, lying cut face up with the stone.
		dome(Vector3(0, .028, 0), Vector3(.1, .056, .14), "3e5b2a", MATTE, Vector3(PI, 0, 0))
		cyl(Vector3(0, .057, 0), Vector3(.096, .006, .136), "c5d97a", SATIN, Vector3.ZERO, 12)
		cyl(Vector3(0, .059, 0), Vector3(.075, .006, .11), "e3eda0", SATIN, Vector3.ZERO, 12)
		ball(Vector3(0, .066, .01), Vector3(.045, .03, .045), "7a4a2a", SATIN, Vector3.ZERO, 8)

# Vegetables

func _tomato(_v: int) -> void:
	ball(Vector3(0, .058, 0), Vector3(.135, .115, .135), "e0402f", SATIN, Vector3.ZERO, 12)
	ball(Vector3(-.02, .065, -.03), Vector3(.08, .07, .07), "eb5a45", SATIN, Vector3.ZERO, 8)
	for k in 5:
		bx(Vector3(0, .115, 0), Vector3(.055, .006, .012), "4f8a3a", MATTE, Vector3(0, k * PI / 5, 0))
	cyl(Vector3(0, .122, 0), Vector3(.01, .018, .01), "4f8a3a", MATTE, Vector3.ZERO, 4)

func _carrot(_v: int) -> void:
	cyl(Vector3(0, .028, .02), Vector3(.055, .22, .055), "ee7d21", SATIN, Vector3(PI / 2, 0, 0), 8, .18)
	for k in 3:
		ring(Vector3(0, .028, -.03 + k * .05), Vector3(.05 - k * .01, .006, .05 - k * .01), "d96a14", SATIN, Vector3(PI / 2, 0, 0), .8, 8)
	for k in 3:
		prism(Vector3((k - 1) * .016, .034, -.135), Vector3(.022, .1, .008), "5a9a3c" if k != 1 else "3f7d3a", MATTE, Vector3(-PI / 2 + .15, (k - 1) * .3, 0))

func _broccoli(_v: int) -> void:
	cyl(Vector3(0, .04, 0), Vector3(.045, .08, .045), "9cbf6a", MATTE, Vector3.ZERO, 6, .8)
	for o in [Vector3(0, .12, 0), Vector3(.04, .1, .02), Vector3(-.04, .1, -.02), Vector3(.015, .1, -.042), Vector3(-.02, .105, .04)]:
		ball(o, Vector3(.06, .05, .06), "3f7d3a" if o.x >= 0 else DARK_LEAF, MATTE, Vector3.ZERO, 7)

func _potato(_v: int) -> void:
	ball(Vector3(0, .045, 0), Vector3(.14, .085, .1), "b48a5a", MATTE, Vector3.ZERO, 8)
	ball(Vector3(.035, .05, .01), Vector3(.08, .075, .075), "a87d4f", MATTE, Vector3.ZERO, 7)
	for o in [Vector3(-.03, .07, -.04), Vector3(.02, .08, -.03), Vector3(-.05, .05, .03)]:
		ball(o, Vector3(.01, .01, .01), "6e5134", MATTE, Vector3.ZERO, 4)

func _lettuce(_v: int) -> void:
	ball(Vector3(0, .08, 0), Vector3(.15, .145, .15), "a7d16b", SATIN, Vector3.ZERO, 10)
	for k in 6:
		var a := k * TAU / 6
		ball(Vector3(cos(a) * .055, .07, sin(a) * .055), Vector3(.11, .13, .035), "6fae3a" if k % 2 else "5a9a2e", SATIN, Vector3(.35, -a + PI / 2, 0), 8)
	ball(Vector3(0, .145, 0), Vector3(.09, .05, .09), "d4eaa0", SATIN, Vector3.ZERO, 8)

func _onion(v: int) -> void:
	var skin := pick(v, ["c98b4b", "8e3b5a"])
	ball(Vector3(0, .058, 0), Vector3(.12, .11, .12), skin, SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .128, 0), Vector3(.04, .05, .04), darker(skin, .15), SATIN, Vector3.ZERO, 6, 0.0)
	cyl(Vector3(0, .004, 0), Vector3(.025, .008, .025), "e8d9b5", MATTE, Vector3.ZERO, 5)

func _garlic(_v: int) -> void:
	ball(Vector3(0, .038, 0), Vector3(.09, .072, .09), "f0ead6", SATIN, Vector3.ZERO, 8)
	for k in 5:
		var a := k * TAU / 5
		ball(Vector3(cos(a) * .022, .04, sin(a) * .022), Vector3(.035, .068, .035), "e6dcc4" if k % 2 else "f5f0e2", SATIN, Vector3.ZERO, 6)
	cyl(Vector3(0, .085, 0), Vector3(.022, .04, .022), "e0d6bd", MATTE, Vector3.ZERO, 5, .2)

func _corn(_v: int) -> void:
	cyl(Vector3(0, .036, -.01), Vector3(.062, .22, .062), "f2c94c", SATIN, Vector3(PI / 2, 0, 0), 8, .75)
	for k in 4:
		ring(Vector3(0, .036, -.09 + k * .055), Vector3(.064, .008, .064), "e0b23a", SATIN, Vector3(PI / 2, 0, 0), .85, 8)
	for side in [-1, 1]:
		ball(Vector3(side * .03, .032, .06), Vector3(.03, .05, .2), "8bb35a", MATTE, Vector3(0, side * .2, 0), 7)
	cyl(Vector3(0, .036, -.13), Vector3(.02, .03, .02), "b58a4a", MATTE, Vector3(PI / 2, 0, 0), 5, .3)

func _chili_pepper(_v: int) -> void:
	cyl(Vector3(0, .02, -.02), Vector3(.036, .085, .034), "c62828", SATIN, Vector3(PI / 2, .25, 0), 7)
	cyl(Vector3(.016, .02, .05), Vector3(.034, .075, .03), "c62828", SATIN, Vector3(PI / 2, -.35, 0), 7, .15)
	ball(Vector3(-.006, .022, -.065), Vector3(.03, .022, .02), "2e7d32", MATTE, Vector3.ZERO, 6)
	cyl(Vector3(-.01, .025, -.082), Vector3(.008, .025, .008), "2e7d32", MATTE, Vector3(PI / 2, .3, 0), 4)

func _mushroom(v: int) -> void:
	var cap := pick(v, ["a07856", "efe6d8"])
	cyl(Vector3(0, .02, 0), Vector3(.032, .04, .032), "f2ece0", MATTE, Vector3.ZERO, 7)
	dome(Vector3(0, .055, 0), Vector3(.095, .045, .095), cap, SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .035, 0), Vector3(.088, .006, .088), "d9ccb6", MATTE, Vector3.ZERO, 10)

func _cucumber(_v: int) -> void:
	ball(Vector3(0, .033, 0), Vector3(.066, .062, .3), "2e6b30", SATIN, Vector3.ZERO, 8)
	for side in [-1, 1]:
		ball(Vector3(side * .02, .036, 0), Vector3(.018, .06, .28), "5a8f3c", SATIN, Vector3.ZERO, 6)
	cyl(Vector3(0, .033, -.152), Vector3(.012, .012, .012), "8a9a4a", MATTE, Vector3(PI / 2, 0, 0), 5)

func _bell_pepper(v: int) -> void:
	var skin := pick(v, ["d32f2f", "f9b825", "43a047"])
	for k in 4:
		var a := k * TAU / 4 + PI / 4
		ball(Vector3(cos(a) * .026, .064, sin(a) * .026), Vector3(.08, .122, .08), skin if k % 2 else darker(skin, .08), SATIN, Vector3.ZERO, 8)
	ball(Vector3(0, .125, 0), Vector3(.05, .018, .05), "3f6e2a", SATIN, Vector3.ZERO, 6)
	cyl(Vector3(.004, .142, 0), Vector3(.016, .035, .016), "3f6e2a", MATTE, Vector3(0, 0, .2), 5)

# ---------------------------------------------------------------------------------------------
# Pantry and snacks (packages show a picture of what is inside on their front, -Z)

func _cereal(v: int) -> void:
	var brand := pick(v, ["d84a3a", "3a7bd5", "6d9c3d", "e0a030"])
	bx(Vector3(0, .15, 0), Vector3(.2, .3, .07), brand, MATTE)
	bx(Vector3(0, .262, 0), Vector3(.202, .05, .072), WHITE, MATTE)
	bx(Vector3(0, .262, -.0005), Vector3(.12, .028, .072), "f2c230" if v != 3 else "c62828", MATTE)
	badge(Vector3(0, .12, -.037), .13, WHITE)
	dome(Vector3(0, .1, -.038), Vector3(.1, .04, .006), "8fc7e8", SATIN, Vector3(0, 0, PI))
	for o in [Vector3(-.025, .128, -.041), Vector3(.0, .134, -.042), Vector3(.025, .127, -.041), Vector3(-.01, .12, -.043), Vector3(.015, .118, -.043)]:
		ball(o, Vector3(.026, .018, .006), "e8b04b", MATTE, Vector3(0, 0, o.x * 20.0), 5)

func _rice(v: int) -> void:
	var band := pick(v, ["c62828", "2e7d32"])
	bx(Vector3(0, .1, 0), Vector3(.15, .19, .075), "f3efe6", SATIN)
	bx(Vector3(0, .203, 0), Vector3(.15, .022, .03), "e0dccf", SATIN)
	bx(Vector3(0, .09, 0), Vector3(.152, .075, .077), band, SATIN)
	for k in 6:
		ball(Vector3(-.04 + k * .016, .09 + (k % 2) * .014 - .007, -.039), Vector3(.007, .016, .004), WHITE, MATTE, Vector3(0, 0, .5 - (k % 3) * .4), 4)

func _beans(_v: int) -> void:
	bx(Vector3(0, .085, 0), Vector3(.14, .17, .06), "f3efe6", SATIN)
	bx(Vector3(0, .17, 0), Vector3(.142, .025, .062), "c62828", SATIN)
	bx(Vector3(0, .075, -.03), Vector3(.105, .095, .003), "5c3a24", SATIN)
	for o in [Vector3(-.03, .1, 0), Vector3(.01, .105, 0), Vector3(.035, .09, 0), Vector3(-.015, .07, 0), Vector3(.02, .06, 0), Vector3(-.035, .05, 0), Vector3(.0, .045, 0)]:
		ball(o + Vector3(0, 0, -.033), Vector3(.026, .016, .008), "8a4a2e" if int(o.y * 100) % 2 else "a65a34", SATIN, Vector3(0, 0, o.x * 15.0), 5)

func _flour(_v: int) -> void:
	bx(Vector3(0, .105, 0), Vector3(.16, .21, .09), "efe6d2", MATTE)
	prism(Vector3(0, .222, 0), Vector3(.09, .025, .16), "e3d8bf", MATTE, Vector3(0, PI / 2, 0))
	bx(Vector3(0, .035, 0), Vector3(.162, .05, .092), NAVY, MATTE)
	cyl(Vector3(0, .12, -.047), Vector3(.005, .11, .003), "b58a3a", MATTE, Vector3.ZERO, 4)
	for k in 4:
		for side in [-1, 1]:
			ball(Vector3(side * .011, .13 + k * .02, -.048), Vector3(.012, .022, .005), "d9a640", MATTE, Vector3(0, 0, side * -.5), 5)

func _sugar(_v: int) -> void:
	bx(Vector3(0, .1, 0), Vector3(.14, .2, .08), "fafafa", MATTE)
	bx(Vector3(0, .085, 0), Vector3(.142, .09, .082), "e57399", MATTE)
	for o in [Vector3(-.022, .065, 0), Vector3(.022, .065, 0), Vector3(0, .1, 0)]:
		bx(o + Vector3(0, 0, -.045), Vector3(.032, .032, .012), "ffffff", SATIN, Vector3(0, 0, .1))
	bx(Vector3(0, .17, -.0005), Vector3(.09, .02, .081), "e57399", MATTE)

func _pasta(v: int) -> void:
	var brand := pick(v, ["2c4f86", "c62828"])
	bx(Vector3(0, .12, 0), Vector3(.08, .24, .06), brand, MATTE)
	bx(Vector3(0, .12, -.0305), Vector3(.045, .15, .002), "f2d47a", SATIN)
	for k in 5:
		cyl(Vector3(-.016 + k * .008, .12, -.0325), Vector3(.004, .145, .004), "e8bf4f", SATIN, Vector3.ZERO, 4)
	bx(Vector3(0, .225, 0), Vector3(.082, .02, .062), "f2c230", MATTE)

func _tortilla(_v: int) -> void:
	for k in 6:
		cyl(Vector3(0, .008 + k * .013, 0), Vector3(.2, .012, .2), "f2dfb3" if k % 2 else "eed6a3", MATTE, Vector3.ZERO, 14)
	for o in [Vector3(.04, 0, .03), Vector3(-.05, 0, -.02), Vector3(.01, 0, -.06), Vector3(-.02, 0, .06)]:
		cyl(o + Vector3(0, .083, 0), Vector3(.022, .003, .022), "c49a5a", MATTE, Vector3.ZERO, 6)
	bx(Vector3(0, .045, -.1), Vector3(.1, .05, .01), "2e7d32", SATIN)
	bx(Vector3(0, .045, -.104), Vector3(.06, .016, .004), "f2c230", SATIN)

func _oil(v: int) -> void:
	var liquid := pick(v, ["c9b83a", "f2c230"])
	var label := pick(v, ["2e7d32", "e07b24"])
	cyl(Vector3(0, .1, 0), Vector3(.075, .2, .075), liquid, SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .215, 0), Vector3(.075, .03, .075), liquid, SATIN, Vector3.ZERO, 10, .4)
	cyl(Vector3(0, .25, 0), Vector3(.03, .045, .03), liquid, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .28, 0), Vector3(.035, .02, .035), label, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .1, 0), Vector3(.077, .075, .077), CREAM, MATTE, Vector3.ZERO, 10)
	cyl(Vector3(0, .07, 0), Vector3(.078, .015, .078), label, MATTE, Vector3.ZERO, 10)
	if v == 0:
		ball(Vector3(-.008, .11, -.039), Vector3(.018, .024, .006), "55652b", SATIN, Vector3.ZERO, 6)
		ball(Vector3(.012, .108, -.039), Vector3(.016, .022, .006), "6b7d3a", SATIN, Vector3.ZERO, 6)
	else:
		badge(Vector3(0, .11, -.04), .03, "f9a825")
		badge(Vector3(0, .11, -.042), .014, "5d4037")

func _salt(_v: int) -> void:
	cyl(Vector3(0, .05, 0), Vector3(.065, .1, .065), "f2f4f6", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .035, 0), Vector3(.066, .045, .066), "fdfdfd", MATTE, Vector3.ZERO, 10)
	cyl(Vector3(0, .113, 0), Vector3(.068, .028, .068), SILVER, METAL, Vector3.ZERO, 10)
	dome(Vector3(0, .127, 0), Vector3(.066, .022, .066), SILVER, METAL, Vector3.ZERO, 10)
	for k in 3:
		var a := k * TAU / 3
		ball(Vector3(cos(a) * .013, .139, sin(a) * .013), Vector3(.007, .003, .007), "4a5056", MATTE, Vector3.ZERO, 4)
	badge(Vector3(0, .035, -.034), .03, NAVY)

func _pepper(_v: int) -> void:
	cyl(Vector3(0, .012, 0), Vector3(.05, .024, .05), "4e342e", SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .055, 0), Vector3(.036, .065, .036), "5d4037", SATIN, Vector3.ZERO, 8, .8)
	ball(Vector3(0, .1, 0), Vector3(.05, .04, .05), "5d4037", SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .127, 0), Vector3(.012, .02, .012), SILVER, METAL, Vector3.ZERO, 6)
	ball(Vector3(0, .14, 0), Vector3(.018, .014, .018), SILVER, METAL, Vector3.ZERO, 6)
	for k in 3:
		ball(Vector3(-.008 + k * .008, .05 + (k % 2) * .008, -.019), Vector3(.007, .007, .004), "1e1a18", SATIN, Vector3.ZERO, 4)

func _honey(_v: int) -> void:
	for k in 3:
		ball(Vector3(0, .022 + k * .033, 0), Vector3(.098 - k * .008, .042, .098 - k * .008), "e0a030" if k % 2 == 0 else "d48e22", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .112, 0), Vector3(.056, .02, .056), "8d5a2b", MATTE, Vector3.ZERO, 8)
	cyl(Vector3(.006, .135, 0), Vector3(.008, .04, .008), "c49a5a", MATTE, Vector3(0, 0, .5), 4)
	ball(Vector3(.016, .152, 0), Vector3(.018, .022, .018), "c49a5a", MATTE, Vector3.ZERO, 6)
	badge(Vector3(0, .055, -.046), .03, "fff3c4")
	ball(Vector3(0, .055, -.048), Vector3(.016, .012, .005), "2b2b2b", MATTE, Vector3.ZERO, 5)
	ball(Vector3(0, .055, -.049), Vector3(.008, .012, .004), "f9c623", MATTE, Vector3.ZERO, 5)

func _jam(v: int) -> void:
	var fruit := pick(v, ["a8233a", "e8742a", "6b2d5c"])
	cyl(Vector3(0, .045, 0), Vector3(.085, .09, .085), fruit, SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .04, 0), Vector3(.087, .04, .087), CREAM, MATTE, Vector3.ZERO, 10)
	badge(Vector3(0, .04, -.044), .026, darker(fruit, .0) if v != 1 else "f08a24", SATIN)
	cyl(Vector3(0, .098, 0), Vector3(.088, .018, .088), "d84a3a", SATIN, Vector3.ZERO, 10)
	dome(Vector3(0, .107, 0), Vector3(.105, .016, .105), WHITE, MATTE, Vector3.ZERO, 10)
	for o in [Vector3(-.022, 0, -.022), Vector3(.022, 0, .022), Vector3(.022, 0, -.022), Vector3(-.022, 0, .022), Vector3.ZERO]:
		bx(o + Vector3(0, .113, 0), Vector3(.016, .004, .016), "d84a3a", MATTE)

func _salsa(_v: int) -> void:
	cyl(Vector3(0, .052, 0), Vector3(.09, .104, .09), "c0392b", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .048, 0), Vector3(.092, .045, .092), "f2c94c", MATTE, Vector3.ZERO, 10)
	cyl(Vector3(0, .114, 0), Vector3(.093, .022, .093), "2e7d32", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(-.004, .048, -.047), Vector3(.012, .03, .006), "c62828", SATIN, Vector3(0, 0, .5), 6, .2)
	ball(Vector3(.006, .064, -.047), Vector3(.008, .008, .004), "2e7d32", MATTE, Vector3.ZERO, 4)

func _olive(_v: int) -> void:
	cyl(Vector3(0, .06, 0), Vector3(.08, .12, .08), "8a9a5a", SATIN, Vector3.ZERO, 10)
	for k in 7:
		var a := -PI / 2 + (k % 4 - 1.5) * .45
		var y := .03 + (k / 4) * .045 + (k % 2) * .015
		ball(Vector3(cos(a) * .035, y, sin(a) * .035), Vector3(.022, .03, .022), "55652b" if k % 2 else "6b7d3a", SATIN, Vector3.ZERO, 6)
	cyl(Vector3(0, .07, 0), Vector3(.082, .028, .082), CREAM, MATTE, Vector3.ZERO, 10)
	ball(Vector3(0, .07, -.042), Vector3(.016, .02, .005), "55652b", SATIN, Vector3.ZERO, 5)
	cyl(Vector3(0, .13, 0), Vector3(.084, .02, .084), "c9a640", METAL, Vector3.ZERO, 10)

func _jar(_v: int) -> void:
	cyl(Vector3(0, .06, 0), Vector3(.1, .12, .1), "cfe3e6", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .125, 0), Vector3(.085, .014, .085), "b8d4d8", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .14, 0), Vector3(.09, .02, .09), SILVER, METAL, Vector3.ZERO, 10)
	cyl(Vector3(0, .06, 0), Vector3(.102, .045, .102), KRAFT, MATTE, Vector3.ZERO, 10)

## Metal can with rims, a coloured label and a picture of the contents.
func _can_body(label: String, height: float, diameter: float) -> void:
	cyl(Vector3(0, height * .5, 0), Vector3(diameter, height - .01, diameter), SILVER, METAL, Vector3.ZERO, 10)
	cyl(Vector3(0, height * .5, 0), Vector3(diameter + .003, height * .74, diameter + .003), label, SATIN, Vector3.ZERO, 10)
	for y in [.004, height - .004]:
		cyl(Vector3(0, y, 0), Vector3(diameter + .004, .008, diameter + .004), "aab3ba", METAL, Vector3.ZERO, 10)

func _can(v: int) -> void:
	var label := pick(v, ["c62828", "2e7d32", "f9a825"])
	_can_body(label, .12, .088)
	badge(Vector3(0, .06, -.046), .045, WHITE)
	match v:
		0:
			ball(Vector3(0, .06, -.049), Vector3(.028, .024, .008), "e0402f", SATIN, Vector3.ZERO, 6)
		1:
			for o in [Vector3(-.01, .066, 0), Vector3(.01, .066, 0), Vector3(0, .052, 0)]:
				ball(o + Vector3(0, 0, -.049), Vector3(.014, .014, .006), "6fae3a", SATIN, Vector3.ZERO, 5)
		_:
			ball(Vector3(0, .06, -.049), Vector3(.014, .032, .006), "f2c94c", SATIN, Vector3.ZERO, 6)

func _tuna(_v: int) -> void:
	_can_body("1e88e5", .045, .1)
	ring(Vector3(.02, .047, 0), Vector3(.03, .004, .022), SILVER, METAL, Vector3.ZERO, .6, 8)
	ball(Vector3(-.006, .023, -.051), Vector3(.04, .016, .005), "b0bec5", SATIN, Vector3.ZERO, 6)
	prism(Vector3(.022, .023, -.051), Vector3(.016, .016, .005), "b0bec5", SATIN, Vector3(0, 0, PI / 2))

func _soup(_v: int) -> void:
	cyl(Vector3(0, .06, 0), Vector3(.088, .11, .088), SILVER, METAL, Vector3.ZERO, 10)
	cyl(Vector3(0, .083, 0), Vector3(.091, .045, .091), "c62828", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .038, 0), Vector3(.091, .045, .091), WHITE, SATIN, Vector3.ZERO, 10)
	badge(Vector3(0, .04, -.047), .026, "d9a640", METAL)
	dome(Vector3(0, .078, -.047), Vector3(.03, .012, .006), WHITE, SATIN, Vector3(PI, 0, 0), 8)
	for y in [.004, .116]:
		cyl(Vector3(0, y, 0), Vector3(.092, .008, .092), "aab3ba", METAL, Vector3.ZERO, 10)

## Iced coffee in a bottle (17 Nov 2026, user: coffee moves to the drinks cooler): dark coffee
## behind a cream label with a coffee-cup badge, a brown or black cap.
func _coffee(v: int) -> void:
	var cap := pick(v, ["4e342e", "1e1a18"])
	cyl(Vector3(0, .075, 0), Vector3(.07, .15, .07), "4a2c1a", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .17, 0), Vector3(.07, .04, .07), "4a2c1a", SATIN, Vector3.ZERO, 10, .45)
	cyl(Vector3(0, .197, 0), Vector3(.032, .016, .032), "4a2c1a", SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .211, 0), Vector3(.036, .018, .036), cap, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .08, 0), Vector3(.072, .075, .072), CREAM, MATTE, Vector3.ZERO, 10)
	cyl(Vector3(0, .074, -.037), Vector3(.026, .022, .004), "6d4c41", MATTE, Vector3(PI / 2, 0, 0), 8)
	ring(Vector3(.016, .076, -.038), Vector3(.012, .004, .012), "6d4c41", MATTE, Vector3(PI / 2, 0, 0), .5, 8)
	bx(Vector3(0, .1, -.037), Vector3(.03, .004, .002), cap, MATTE)

func _tea(v: int) -> void:
	var brand := pick(v, ["2e7d32", "b03030"])
	bx(Vector3(0, .045, 0), Vector3(.16, .09, .08), brand, MATTE)
	bx(Vector3(0, .06, 0), Vector3(.162, .025, .082), "f2d47a", MATTE)
	cyl(Vector3(-.03, .04, -.043), Vector3(.03, .022, .006), WHITE, SATIN, Vector3(PI / 2, 0, 0), 8, .8)
	ring(Vector3(-.012, .043, -.043), Vector3(.014, .004, .014), WHITE, SATIN, Vector3(PI / 2, 0, 0), .5, 8)
	bx(Vector3(.035, .035, -.042), Vector3(.02, .025, .002), "f2d47a", MATTE)
	bx(Vector3(.035, .058, -.042), Vector3(.002, .025, .002), WHITE, MATTE)

func _cookie(v: int) -> void:
	var brand := pick(v, ["1e88e5", "c62828"])
	bx(Vector3(0, .03, .01), Vector3(.18, .06, .05), brand, SATIN)
	for k in 4:
		cyl(Vector3(-.06 + k * .04, .03, -.018), Vector3(.05, .012, .05), "c08850", MATTE, Vector3(PI / 2, 0, 0), 10)
		for o in [Vector3(-.01, .008, 0), Vector3(.01, -.006, 0)]:
			ball(Vector3(-.06 + k * .04, .03, -.025) + o, Vector3(.008, .008, .004), "4a2a18", MATTE, Vector3.ZERO, 4)
	bx(Vector3(-.085, .03, -.003), Vector3(.012, .06, .03), brand, SATIN)

## A box of crackers (17 Nov 2026, snacks section): an upright box with square salted crackers
## on its front, so it reads apart from the cookie sleeve.
func _cracker(v: int) -> void:
	var box := pick(v, ["d84315", "1565c0"])
	bx(Vector3(0, .095, 0), Vector3(.14, .19, .06), box, MATTE)
	bx(Vector3(0, .17, -.0305), Vector3(.12, .03, .001), CREAM, MATTE)
	for k in 3:
		var c := Vector3(-.035 + k * .035, .085 - absf(k - 1) * .012, -.033)
		bx(c, Vector3(.042, .042, .004), "e3b866", MATTE, Vector3(0, 0, .12 * (k - 1)))
		for o in [Vector3(-.01, .01, 0), Vector3(.01, .01, 0), Vector3(0, -.01, 0)]:
			ball(c + o + Vector3(0, 0, -.003), Vector3(.005, .005, .002), "a8743a", MATTE, Vector3.ZERO, 4)

func _snack(v: int) -> void:
	var bag := pick(v, ["f9a825", "c62828", "43a047", "8e24aa"])
	ball(Vector3(0, .11, 0), Vector3(.15, .2, .07), bag, SATIN, Vector3.ZERO, 10)
	for y in [.012, .21]:
		bx(Vector3(0, y, 0), Vector3(.15, .022, .02), SILVER, METAL)
	dome(Vector3(0, .15, -.03), Vector3(.08, .01, .04), WHITE, SATIN, Vector3(-PI / 2, 0, 0), 8)
	ball(Vector3(-.01, .085, -.034), Vector3(.05, .035, .008), "f2c94c", SATIN, Vector3(0, 0, .5), 7)
	ball(Vector3(.022, .07, -.032), Vector3(.04, .03, .008), "e0b23a", SATIN, Vector3(0, 0, -.4), 7)

func _chocolate(v: int) -> void:
	var wrap := pick(v, ["6d2c91", "c62828", "1565c0"])
	bx(Vector3(0, .065, 0), Vector3(.05, .13, .015), "5d3a1a", SATIN)
	for k in 2:
		bx(Vector3(0, .1 + k * .018, -.008), Vector3(.048, .002, .002), "3e2412", SATIN)
	bx(Vector3(0, .045, 0), Vector3(.053, .09, .018), wrap, SATIN)
	bx(Vector3(0, .089, 0), Vector3(.054, .006, .019), SILVER, METAL)
	bx(Vector3(0, .05, -.0095), Vector3(.034, .016, .001), GOLD, METAL)

func _candy(v: int) -> void:
	var tint := pick(v, ["ec407a", "fdd835", "26c6da", "ab47bc"])
	for k in 2:
		var x := -.022 + k * .044
		var y := .07 - k * .01
		cyl(Vector3(x, y * .5 - .005, 0), Vector3(.006, y, .006), WHITE, MATTE, Vector3.ZERO, 4)
		cyl(Vector3(x, y + .012, 0), Vector3(.045, .012, .045), tint if k == 0 else lighter(tint, .2), SATIN, Vector3(PI / 2, 0, 0), 10)
		ring(Vector3(x, y + .012, -.007), Vector3(.03, .003, .03), WHITE, SATIN, Vector3(PI / 2, 0, 0), .55, 10)
	bx(Vector3(0, .008, 0), Vector3(.085, .016, .045), lighter(tint, .4), SATIN)

# ---------------------------------------------------------------------------------------------
# Dairy and deli

func _milk(v: int) -> void:
	var band := pick(v, ["1e88e5", "e53935", "64b5f6"])
	bx(Vector3(0, .075, 0), Vector3(.09, .15, .09), WHITE, MATTE)
	prism(Vector3(0, .172, 0), Vector3(.09, .045, .09), WHITE, MATTE)
	bx(Vector3(0, .2, 0), Vector3(.008, .015, .09), "e9e5dc", MATTE)
	bx(Vector3(0, .08, 0), Vector3(.092, .055, .092), band, MATTE)
	ball(Vector3(0, .085, -.047), Vector3(.022, .03, .004), WHITE, SATIN, Vector3.ZERO, 6)
	cyl(Vector3(.022, .178, -.012), Vector3(.022, .014, .022), band, SATIN, Vector3(-.45, 0, 0), 8)

func _yogurt(v: int) -> void:
	var fruit := pick(v, ["e91e63", "f9a825", "5e35b1"])
	cyl(Vector3(0, .03, 0), Vector3(.072, .06, .072), WHITE, SATIN, Vector3.ZERO, 10, 1.18)
	cyl(Vector3(0, .028, 0), Vector3(.074, .025, .074), fruit, SATIN, Vector3.ZERO, 10, 1.1)
	cyl(Vector3(0, .062, 0), Vector3(.088, .005, .088), "d0d6da", METAL, Vector3.ZERO, 10)
	ball(Vector3(0, .045, -.04), Vector3(.016, .016, .006), lighter(fruit, .1), SATIN, Vector3.ZERO, 5)

func _butter(_v: int) -> void:
	bx(Vector3(0, .022, 0), Vector3(.11, .044, .06), "f6d55c", SATIN)
	for side in [-1, 1]:
		bx(Vector3(side * .045, .022, 0), Vector3(.022, .046, .062), "d9a640", METAL)
	bx(Vector3(0, .022, 0), Vector3(.045, .046, .062), WHITE, MATTE)
	bx(Vector3(0, .026, -.0315), Vector3(.03, .006, .001), NAVY, MATTE)

func _cheese(v: int) -> void:
	if v == 0:
		prism(Vector3(0, .033, 0), Vector3(.13, .09, .062), "f2c14e", SATIN, Vector3(PI / 2, PI, 0))
		bx(Vector3(0, .033, .044), Vector3(.13, .064, .006), "e3a93a", SATIN)
		for o in [Vector3(-.022, .065, .022), Vector3(.024, .065, .028), Vector3(.0, .065, .0)]:
			cyl(o, Vector3(.016, .003, .016), "d9a536", MATTE, Vector3.ZERO, 6)
	else:
		# A small wheel in red wax with a wedge-shaped label.
		cyl(Vector3(0, .032, 0), Vector3(.12, .064, .12), "c62828", SATIN, Vector3.ZERO, 12)
		cyl(Vector3(0, .065, 0), Vector3(.1, .003, .1), "a91f1f", SATIN, Vector3.ZERO, 12)
		badge(Vector3(0, .035, -.061), .035, CREAM)

func _eggs(v: int) -> void:
	var tray := "d8cbb0" if v == 0 else "9fb7c4"
	bx(Vector3(0, .022, 0), Vector3(.2, .044, .1), tray, MATTE)
	bx(Vector3(0, .046, 0), Vector3(.2, .006, .1), darker(tray, .1), MATTE)
	for i in 4:
		for j in 2:
			ball(Vector3(-.072 + i * .048, .06, -.024 + j * .048), Vector3(.04, .048, .04), "f5efe1" if v == 0 else "e8c9a0", SATIN, Vector3.ZERO, 8)
	bx(Vector3(0, .028, -.0505), Vector3(.08, .02, .002), "f2c230", MATTE)

## Shallow tray for deli and meat goods (white for poultry and ham, dark for red meat).
func _tray(tint: String, size := Vector2(.17, .13)) -> void:
	bx(Vector3(0, .008, 0), Vector3(size.x, .016, size.y), tint, SATIN)
	bx(Vector3(-size.x * .3, .017, -size.y * .5 + .012), Vector3(.04, .003, .018), "7cb342", MATTE)

func _ham(_v: int) -> void:
	_tray(TRAY)
	for k in 3:
		cyl(Vector3(-.04 + k * .04, .022 + k * .004, 0), Vector3(.1, .008, .1), "f0a0a0" if k % 2 else "e88e90", SATIN, Vector3(0, 0, .12), 12)
		ring(Vector3(-.04 + k * .04, .022 + k * .004, 0), Vector3(.1, .006, .1), "f8d4cc", SATIN, Vector3(0, 0, .12), .86, 12)

func _sausage(_v: int) -> void:
	_tray(TRAY)
	for k in 3:
		ball(Vector3(0, .03, -.04 + k * .04), Vector3(.15, .034, .034), "a0522d" if k != 1 else "8e4526", SATIN, Vector3.ZERO, 8)
		for side in [-1, 1]:
			cyl(Vector3(side * .078, .03, -.04 + k * .04), Vector3(.008, .01, .008), "f0e2c8", MATTE, Vector3(0, 0, PI / 2), 4)

func _chicken(_v: int) -> void:
	_tray(TRAY, Vector2(.19, .14))
	for k in 3:
		var z := -.045 + k * .045
		var flip := 1.0 if k % 2 == 0 else -1.0
		ball(Vector3(flip * -.02, .035, z), Vector3(.1, .045, .045), "edc49a", SATIN, Vector3.ZERO, 8)
		cyl(Vector3(flip * .05, .03, z), Vector3(.012, .05, .012), "f7f0e1", MATTE, Vector3(0, 0, PI / 2), 5)
		ball(Vector3(flip * .078, .03, z), Vector3(.022, .02, .02), "f7f0e1", MATTE, Vector3.ZERO, 6)

func _meat(_v: int) -> void:
	_tray(DARK_TRAY, Vector2(.18, .13))
	ball(Vector3(0, .028, 0), Vector3(.15, .04, .11), "b0413e", MATTE, Vector3.ZERO, 10)
	for o in [Vector3(-.03, .045, -.02), Vector3(.03, .045, .015), Vector3(0, .047, -.005), Vector3(-.015, .043, .03)]:
		ball(o, Vector3(.025, .012, .025), "c55a52" if o.x > 0 else "9a3532", MATTE, Vector3.ZERO, 5)

func _steak(_v: int) -> void:
	_tray(DARK_TRAY, Vector2(.23, .16))
	ball(Vector3(0, .022, 0), Vector3(.205, .022, .135), "f3e5d8", SATIN, Vector3.ZERO, 12)
	ball(Vector3(-.005, .026, -.004), Vector3(.185, .024, .118), "a83232", SATIN, Vector3.ZERO, 12)
	for o in [Vector3(.04, .036, .02), Vector3(-.05, .036, -.02)]:
		bx(o, Vector3(.03, .002, .005), "e8c8b8", MATTE, Vector3(0, .5, 0))
	bx(Vector3(.015, .032, 0), Vector3(.012, .016, .11), "f7f0e1", MATTE)
	bx(Vector3(.015, .032, -.05), Vector3(.07, .016, .012), "f7f0e1", MATTE)

func _salad(_v: int) -> void:
	ball(Vector3(0, .1, 0), Vector3(.14, .19, .055), "dceedd", SATIN, Vector3.ZERO, 10)
	for o in [Vector3(-.03, .07, 0), Vector3(.025, .09, 0), Vector3(-.01, .115, 0), Vector3(.03, .13, 0), Vector3(-.035, .135, 0)]:
		ball(o + Vector3(0, 0, -.022), Vector3(.05, .035, .012), ["7cb342", "4f8f3a", "a8d26b", "8e3b5a", "7cb342"][int(o.y * 100) % 5], SATIN, Vector3(0, 0, o.x * 12.0), 6)
	bx(Vector3(0, .19, 0), Vector3(.13, .02, .02), "2e7d32", SATIN)
	bx(Vector3(0, .04, -.026), Vector3(.08, .02, .004), WHITE, MATTE)

func _fish(v: int) -> void:
	var skin := pick(v, ["9fb4c0", "c48a7a"])
	ball(Vector3(0, .03, -.02), Vector3(.1, .05, .26), skin, SATIN, Vector3.ZERO, 10)
	ball(Vector3(0, .022, -.03), Vector3(.085, .03, .22), "e6edf0", SATIN, Vector3.ZERO, 8)
	ball(Vector3(0, .046, -.01), Vector3(.03, .02, .2), darker(skin, .25), SATIN, Vector3.ZERO, 6)
	prism(Vector3(0, .03, .15), Vector3(.1, .06, .012), darker(skin, .1), SATIN, Vector3(-PI / 2, 0, 0))
	prism(Vector3(0, .055, -.02), Vector3(.05, .025, .006), darker(skin, .2), SATIN, Vector3(0, PI / 2, 0))
	for side in [-1, 1]:
		ball(Vector3(side * .03, .036, -.12), Vector3(.016, .016, .012), WHITE, SATIN, Vector3.ZERO, 6)
		ball(Vector3(side * .036, .037, -.123), Vector3(.008, .008, .007), "1e1a18", SATIN, Vector3.ZERO, 4)

func _shrimp(_v: int) -> void:
	for k in 5:
		var a := -.4 + k * .7
		var size := .03 - k * .003
		ball(Vector3(cos(a) * .028, .02, sin(a) * .028), Vector3(size, .026 - k * .002, size), "f08070" if k % 2 else "f49a84", SATIN, Vector3.ZERO, 6)
	prism(Vector3(cos(3.0) * .035, .016, sin(3.0) * .035), Vector3(.026, .022, .006), "e86a58", SATIN, Vector3(-PI / 2, 1.2, 0))
	ball(Vector3(cos(-.4) * .03 + .01, .03, sin(-.4) * .03), Vector3(.005, .005, .005), "1e1a18", SATIN, Vector3.ZERO, 4)

# ---------------------------------------------------------------------------------------------
# Drinks

func _water_bottle(_v: int) -> void:
	cyl(Vector3(0, .1, 0), Vector3(.064, .2, .064), "a9dcf2", SATIN, Vector3.ZERO, 10)
	for y in [.04, .16]:
		ring(Vector3(0, y, 0), Vector3(.066, .012, .066), "c7ebf7", SATIN, Vector3.ZERO, .9, 10)
	cyl(Vector3(0, .215, 0), Vector3(.064, .03, .064), "a9dcf2", SATIN, Vector3.ZERO, 10, .4)
	cyl(Vector3(0, .236, 0), Vector3(.024, .014, .024), "a9dcf2", SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .247, 0), Vector3(.028, .012, .028), "1565c0", SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .1, 0), Vector3(.066, .05, .066), NAVY, SATIN, Vector3.ZERO, 10)
	dome(Vector3(0, .1, -.034), Vector3(.03, .004, .012), "8fd3f5", SATIN, Vector3(-PI / 2, 0, 0), 6)

func _soda(v: int) -> void:
	var liquid := pick(v, ["4e342e", "8bc34a", "ef6c00"])
	var label := pick(v, ["c62828", "f2c230", "1565c0"])
	cyl(Vector3(0, .07, 0), Vector3(.064, .14, .064), liquid, SATIN, Vector3.ZERO, 10)
	ring(Vector3(0, .11, 0), Vector3(.066, .03, .066), liquid, SATIN, Vector3.ZERO, .85, 10)
	cyl(Vector3(0, .17, 0), Vector3(.064, .06, .064), liquid, SATIN, Vector3.ZERO, 10, .38)
	cyl(Vector3(0, .212, 0), Vector3(.024, .026, .024), liquid, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .226, 0), Vector3(.028, .01, .028), WHITE if v == 0 else "e53935", METAL, Vector3.ZERO, 8)
	cyl(Vector3(0, .065, 0), Vector3(.066, .055, .066), label, SATIN, Vector3.ZERO, 10)
	ball(Vector3(0, .065, -.034), Vector3(.035, .012, .004), WHITE, SATIN, Vector3(0, 0, .25), 6)

func _juice(v: int) -> void:
	var fruit := pick(v, ["f39c12", "7cb342", "8e44ad"])
	bx(Vector3(0, .09, 0), Vector3(.08, .18, .08), fruit, MATTE)
	prism(Vector3(0, .195, 0), Vector3(.08, .03, .08), fruit, MATTE)
	bx(Vector3(0, .09, -.0405), Vector3(.06, .08, .001), WHITE, MATTE)
	cyl(Vector3(.018, .206, -.012), Vector3(.02, .016, .02), WHITE, SATIN, Vector3(-.36, 0, 0), 8)
	match v:
		0:
			ball(Vector3(0, .09, -.044), Vector3(.042, .042, .008), "f08a24", SATIN, Vector3.ZERO, 8)
			ball(Vector3(.012, .114, -.044), Vector3(.016, .008, .004), LEAF, SATIN, Vector3.ZERO, 5)
		1:
			ball(Vector3(0, .088, -.044), Vector3(.04, .038, .008), "c8312b", SATIN, Vector3.ZERO, 8)
			bx(Vector3(0, .112, -.044), Vector3(.003, .012, .003), STEM, MATTE)
		_:
			for o in [Vector3(-.01, .1, 0), Vector3(.01, .1, 0), Vector3(0, .083, 0), Vector3(-.012, .085, 0), Vector3(.012, .085, 0), Vector3(0, .068, 0)]:
				ball(o + Vector3(0, 0, -.044), Vector3(.016, .016, .006), "6b3d8f", SATIN, Vector3.ZERO, 5)

# ---------------------------------------------------------------------------------------------
# Household

func _soap(v: int) -> void:
	var tint := pick(v, ["f8bbd0", "b3e5fc", "dcedc8"])
	ball(Vector3(0, .014, 0), Vector3(.095, .028, .064), tint, SATIN, Vector3.ZERO, 10)
	bx(Vector3(0, .012, 0), Vector3(.08, .024, .05), tint, SATIN)
	ball(Vector3(0, .026, 0), Vector3(.05, .006, .03), darker(tint, .12), SATIN, Vector3.ZERO, 8)
	for o in [Vector3(.028, .034, .012), Vector3(.036, .03, -.01), Vector3(.018, .031, -.016)]:
		ball(o, Vector3.ONE * (.014 if o.x > .03 else .01), "ffffff", SATIN, Vector3.ZERO, 6)

func _sponge(v: int) -> void:
	var body := pick(v, ["f9e04b", "f48fb1"])
	bx(Vector3(0, .017, 0), Vector3(.1, .034, .065), body, MATTE)
	bx(Vector3(0, .04, 0), Vector3(.1, .012, .065), "2e7d32", MATTE)
	for o in [Vector3(-.03, .012, 0), Vector3(.0, .02, 0), Vector3(.03, .01, 0), Vector3(-.012, .026, 0), Vector3(.022, .027, 0)]:
		badge(o + Vector3(0, 0, -.033), .008, darker(body, .2))

func _detergent(v: int) -> void:
	var jug := pick(v, ["1e88e5", "ef6c00", "7e57c2"])
	bx(Vector3(0, .1, 0), Vector3(.13, .2, .08), jug, SATIN)
	ball(Vector3(-.01, .2, 0), Vector3(.11, .04, .08), jug, SATIN, Vector3.ZERO, 8)
	bx(Vector3(.048, .205, 0), Vector3(.018, .06, .028), jug, SATIN)
	bx(Vector3(.03, .232, 0), Vector3(.05, .014, .028), jug, SATIN)
	cyl(Vector3(-.035, .224, 0), Vector3(.036, .03, .036), "ff7043" if v != 1 else "1e88e5", SATIN, Vector3.ZERO, 8)
	bx(Vector3(-.005, .095, -.0405), Vector3(.09, .1, .002), WHITE, MATTE)
	for o in [Vector3(-.02, .1, 0), Vector3(.01, .115, 0), Vector3(.012, .08, 0)]:
		badge(o + Vector3(0, 0, -.043), .02 if o.x < 0 else .014, "8fd3f5", SATIN)

func _toothbrush(v: int) -> void:
	var handle := pick(v, ["29b6f6", "66bb6a", "ef5350"])
	bx(Vector3(0, .1, .006), Vector3(.05, .2, .004), "e3f2fd", MATTE)
	bx(Vector3(0, .17, .004), Vector3(.05, .05, .004), handle, MATTE)
	cyl(Vector3(0, .085, -.004), Vector3(.014, .15, .008), handle, SATIN, Vector3.ZERO, 6)
	bx(Vector3(0, .172, -.003), Vector3(.015, .03, .008), handle, SATIN)
	bx(Vector3(0, .172, -.011), Vector3(.012, .026, .008), WHITE, MATTE)
	bx(Vector3(0, .18, -.0115), Vector3(.012, .008, .008), "4fc3f7", MATTE)
	bx(Vector3(0, .1, -.008), Vector3(.03, .19, .002), "e8f6fd", SATIN)

func _toothpaste(v: int) -> void:
	var stripe := pick(v, ["c62828", "1e88e5"])
	ball(Vector3(-.01, .022, 0), Vector3(.14, .036, .045), WHITE, SATIN, Vector3.ZERO, 8)
	bx(Vector3(.065, .022, 0), Vector3(.012, .008, .046), WHITE, SATIN)
	ball(Vector3(-.02, .024, 0), Vector3(.06, .038, .047), stripe, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(-.085, .022, 0), Vector3(.026, .022, .026), stripe, SATIN, Vector3(0, 0, PI / 2), 8)
	ball(Vector3(-.02, .025, -.022), Vector3(.03, .01, .004), WHITE, SATIN, Vector3.ZERO, 5)

func _shampoo(v: int) -> void:
	var bottle := pick(v, ["7e57c2", "26a69a", "ec407a"])
	cyl(Vector3(0, .09, 0), Vector3(.08, .18, .05), bottle, SATIN, Vector3.ZERO, 10)
	ball(Vector3(0, .18, 0), Vector3(.08, .03, .05), bottle, SATIN, Vector3.ZERO, 10)
	cyl(Vector3(0, .205, 0), Vector3(.036, .03, .028), WHITE, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .085, 0), Vector3(.082, .07, .052), lighter(bottle, .45), MATTE, Vector3.ZERO, 10)
	ball(Vector3(0, .088, -.026), Vector3(.018, .026, .004), bottle, SATIN, Vector3.ZERO, 6)

func _toilet_paper(_v: int) -> void:
	for dx in [-.052, .052]:
		for dz in [-.052, .052]:
			cyl(Vector3(dx, .055, dz), Vector3(.1, .11, .1), "fbfbf8", MATTE, Vector3.ZERO, 12)
			cyl(Vector3(dx, .111, dz), Vector3(.035, .003, .035), "b08a5a", MATTE, Vector3.ZERO, 8)
	bx(Vector3(0, .055, 0), Vector3(.212, .035, .212), "64b5f6", SATIN)
	bx(Vector3(0, .056, -.107), Vector3(.08, .018, .002), WHITE, MATTE)

# ---------------------------------------------------------------------------------------------
# Bakery

func _bread(v: int) -> void:
	var crust := pick(v, ["c58a4a", "a8683a", "d9a566"])
	ball(Vector3(0, .04, 0), Vector3(.2, .08, .125), darker(crust, .08), MATTE, Vector3.ZERO, 10)
	ball(Vector3(0, .072, 0), Vector3(.19, .09, .12), crust, MATTE, Vector3.ZERO, 10)
	for k in 3:
		bx(Vector3(-.05 + k * .05, .114, 0), Vector3(.012, .006, .09), lighter(crust, .35), MATTE, Vector3(0, .5, 0))

func _baguette(_v: int) -> void:
	cyl(Vector3(0, .03, 0), Vector3(.055, .36, .055), "d39b55", MATTE, Vector3(0, 0, PI / 2), 8)
	for side in [-1, 1]:
		ball(Vector3(side * .19, .03, 0), Vector3(.12, .05, .05), "c98a45", MATTE, Vector3.ZERO, 8)
	for k in 5:
		bx(Vector3(-.14 + k * .07, .057, 0), Vector3(.04, .004, .014), "f0cf93", MATTE, Vector3(0, .6, 0))

func _croissant(_v: int) -> void:
	for k in 5:
		var a := -1.1 + k * .55
		var size := .07 - absf(k - 2) * .013
		ball(Vector3(sin(a) * .06, .028 - absf(k - 2) * .004, -cos(a) * .035 + .02), Vector3(size, size * .8, size * .85), "d79a45" if k % 2 == 0 else "c07f2f", SATIN, Vector3(0, a, 0), 8)

func _cake(v: int) -> void:
	var sponge := pick(v, ["f8e1e7", "fff3e0", "8d6e63"])
	var icing := pick(v, ["f48fb1", WHITE, "6d4c41"])
	cyl(Vector3(0, .004, 0), Vector3(.28, .008, .28), "fafafa", SATIN, Vector3.ZERO, 14)
	cyl(Vector3(0, .05, 0), Vector3(.24, .088, .24), sponge, MATTE, Vector3.ZERO, 14)
	cyl(Vector3(0, .05, 0), Vector3(.242, .012, .242), icing, MATTE, Vector3.ZERO, 14)
	cyl(Vector3(0, .1, 0), Vector3(.245, .016, .245), icing, MATTE, Vector3.ZERO, 14)
	for k in 8:
		var a := k * TAU / 8
		ball(Vector3(cos(a) * .121, .085, sin(a) * .121), Vector3(.03, .04, .03), icing, MATTE, Vector3.ZERO, 6)
		ball(Vector3(cos(a) * .095, .115, sin(a) * .095), Vector3(.03, .025, .03), WHITE if v != 1 else "f48fb1", MATTE, Vector3.ZERO, 6)
	ball(Vector3(0, .122, 0), Vector3(.03, .03, .03), "c62828", SATIN, Vector3.ZERO, 8)

func _cupcake(v: int) -> void:
	var cream := pick(v, ["fff3e0", "f8bbd0", "6d4c41"])
	cyl(Vector3(0, .02, 0), Vector3(.05, .04, .05), "4fc3f7" if v != 1 else "f48fb1", MATTE, Vector3.ZERO, 8, 1.25)
	ball(Vector3(0, .046, 0), Vector3(.066, .026, .066), cream, MATTE, Vector3.ZERO, 8)
	ball(Vector3(0, .06, 0), Vector3(.048, .022, .048), cream, MATTE, Vector3.ZERO, 8)
	ball(Vector3(0, .072, 0), Vector3(.026, .018, .026), cream, MATTE, Vector3.ZERO, 6)
	ball(Vector3(0, .083, 0), Vector3(.016, .016, .016), "c62828", SATIN, Vector3.ZERO, 6)

func _donut(v: int) -> void:
	var icing := pick(v, ["f48fb1", "5d4037", "fff3e0"])
	ring(Vector3(0, .02, 0), Vector3(.11, .04, .11), "c68642", MATTE, Vector3.ZERO, .4, 12)
	ring(Vector3(0, .03, 0), Vector3(.104, .024, .104), icing, MATTE, Vector3.ZERO, .45, 12)
	var sprinkles := ["fdd835", "4fc3f7", "ef5350", "66bb6a", WHITE]
	for k in 6:
		var a := k * TAU / 6 + .3
		bx(Vector3(cos(a) * .037, .043, sin(a) * .037), Vector3(.012, .004, .004), sprinkles[k % 5], SATIN, Vector3(0, a * 2.0, 0))

# ---------------------------------------------------------------------------------------------
# Store fittings (8 Nov 2026): carts, baskets, checkout props and the seafood ice. Each fitting is
# ONE merged mesh in its word root's own frame, drawn inside the root's existing pick or collision
# box (the 2 Nov 2026 sizes), in the same three finishes as the products. `side` is +1 or -1:
# the x direction of a checkout lane's customers (lane 1 +1, lane 2 -1).

const CHROME := "d5dbe0"
const RED := "d93a32"
const CHARCOAL := "2c3237"
const SCREEN := "e3f2fd"
const LASER := "ff3b30"

func fitting(kind: String, side := 1.0) -> ArrayMesh:
	var key := "fit:%s:%d" % [kind, int(side)]
	if not _models.has(key):
		begin()
		call("_fit_" + kind.replace(" ", "_"), side)
		_models[key] = finish("Fitting " + key)
	return _models[key]

## Flat triangle; `up` says which way it faces (the winding follows it).
func tri(a: Vector3, b: Vector3, c: Vector3, tint: String, f := SATIN, up := Vector3.UP) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.dot(up) < 0.0:
		var t := b
		b = c
		c = t
		n = -n
	var base: int = _v[f].size()
	for p in [a, b, c]:
		_v[f].append(p)
		_n[f].append(n)
		_c[f].append(Color(tint))
	_i[f].append_array(PackedInt32Array([base, base + 2, base + 1]))

## Round bar of diameter d from a to b.
func rod(a: Vector3, b: Vector3, d: float, tint: String, f := METAL, sides := 6) -> void:
	var y := (b - a).normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < .9 else Vector3.RIGHT).normalized()
	var basis := Basis(x, y, x.cross(y))
	cyl((a + b) * .5, Vector3(d, a.distance_to(b), d), tint, f, basis.get_euler(), sides)

## Parts on a tilted panel: p is in the panel's frame (centre c, Euler r).
func _on(c: Vector3, r: Vector3, p: Vector3) -> Vector3:
	return c + Basis.from_euler(r) * p

## Wire shopping cart, origin at the 2 Nov basket box centre (1.1 x .65 x 1.5, push handle at +Z).
## The casters are separate "wheel" roots (_fit_caster); the chassis reaches down to them.
func _fit_cart(_side: float) -> void:
	var top := .3
	var low := -.3
	var span := 14
	for s in [-1, 1]:
		# Long sides: tapered wire walls between the top rim and the narrower floor frame.
		for k in span + 1:
			var t := k / float(span)
			rod(Vector3(s * .5, top, lerpf(-.7, .7, t)), Vector3(s * .4, low, lerpf(-.55, .62, t)), .014, CHROME)
		for y in [-.1, .1]:
			var u: float = (y - low) / (top - low)
			rod(Vector3(s * lerpf(.4, .5, u), y, lerpf(-.55, -.7, u)), Vector3(s * lerpf(.4, .5, u), y, lerpf(.62, .7, u)), .012, CHROME)
		rod(Vector3(s * .5, top, -.7), Vector3(s * .5, top, .7), .028, CHROME)
		rod(Vector3(s * .4, low, -.55), Vector3(s * .4, low, .62), .022, CHROME)
	# Front and back ends, top and floor rails.
	for e in [[-.7, -.55], [.7, .62]]:
		for k in 11:
			var t := k / 10.0
			rod(Vector3(lerpf(-.5, .5, t), top, e[0]), Vector3(lerpf(-.4, .4, t), low, e[1]), .012, CHROME)
		rod(Vector3(-.5, top, e[0]), Vector3(.5, top, e[0]), .028, CHROME)
		rod(Vector3(-.4, low, e[1]), Vector3(.4, low, e[1]), .022, CHROME)
	for k in 7:
		var x := -.36 + k * .12
		rod(Vector3(x, low, -.55), Vector3(x, low, .62), .012, CHROME)
	# Folding child seat on the back gate and the red push handle.
	bx(Vector3(0, .08, .63), Vector3(.7, .34, .02), RED, SATIN, Vector3(-.13, 0, 0))
	bx(Vector3(0, .24, .655), Vector3(.5, .05, .025), lighter(RED, .2), SATIN, Vector3(-.13, 0, 0))
	for s in [-1, 1]:
		rod(Vector3(s * .5, top, .7), Vector3(s * .5, .42, .84), .03, CHROME)
	cyl(Vector3(0, .42, .84), Vector3(.055, 1.08, .055), RED, SATIN, Vector3(0, 0, PI / 2), 8)
	for s in [-1, 1]:
		cyl(Vector3(s * .55, .42, .84), Vector3(.065, .03, .065), CHARCOAL, SATIN, Vector3(0, 0, PI / 2), 8)
	# Chassis: legs from the floor frame down to a base frame over the casters, and a lower tray.
	var base := -.51
	for s in [-1, 1]:
		rod(Vector3(s * .45, base, -.55), Vector3(s * .45, base, .55), .03, "8a949b")
		rod(Vector3(s * .4, low, -.55), Vector3(s * .45, base, -.55), .028, "8a949b")
		rod(Vector3(s * .4, low, .62), Vector3(s * .45, base, .55), .028, "8a949b")
		rod(Vector3(s * .45, base, .55), Vector3(s * .5, top, .7), .03, "8a949b")
	for z in [-.55, .55]:
		rod(Vector3(-.45, base, z), Vector3(.45, base, z), .03, "8a949b")
	for k in 5:
		rod(Vector3(-.3 + k * .15, base + .03, -.45), Vector3(-.3 + k * .15, base + .03, .45), .012, CHROME)
	bx(Vector3(0, base + .03, -.55), Vector3(.8, .05, .04), CHARCOAL, SATIN)

## Swivel caster, origin at the old wheel-ball centre (tyre resting .17 below it).
func _fit_caster(_side: float) -> void:
	cyl(Vector3(0, -.08, 0), Vector3(.18, .055, .18), "33393e", MATTE, Vector3(0, 0, PI / 2), 14)
	cyl(Vector3(0, -.08, 0), Vector3(.09, .062, .09), "b0bac1", METAL, Vector3(0, 0, PI / 2), 10)
	cyl(Vector3(0, -.08, 0), Vector3(.03, .08, .03), CHROME, METAL, Vector3(0, 0, PI / 2), 6)
	for s in [-1, 1]:
		bx(Vector3(s * .042, -.035, -.012), Vector3(.01, .12, .07), "8a949b", METAL, Vector3(-.25, 0, 0))
	bx(Vector3(0, .025, 0), Vector3(.1, .016, .09), "8a949b", METAL)
	cyl(Vector3(0, .055, 0), Vector3(.035, .05, .035), "8a949b", METAL, Vector3.ZERO, 8)

## Stack of four nested red baskets, origin on the floor (2 Nov basket stack).
func _fit_basket(_side: float) -> void:
	for k in 4:
		var y := .03 + k * .09
		bx(Vector3(0, y, 0), Vector3(.56, .02, .36), darker(RED, .1), SATIN)
		for s in [-1, 1]:
			bx(Vector3(0, y + .1, s * .195), Vector3(.62, .2, .016), RED, SATIN, Vector3(s * -.15, 0, 0))
			bx(Vector3(s * .295, y + .1, 0), Vector3(.016, .2, .4), RED, SATIN, Vector3(0, 0, s * .15))
			# Lip and a row of drainage slots on each wall.
			bx(Vector3(0, y + .2, s * .212), Vector3(.66, .02, .03), lighter(RED, .12), SATIN)
			bx(Vector3(s * .312, y + .2, 0), Vector3(.03, .02, .45), lighter(RED, .12), SATIN)
			for j in 6:
				bx(Vector3(-.225 + j * .09, y + .13, s * .207), Vector3(.05, .05, .004), "8e1f1a", MATTE, Vector3(s * -.15, 0, 0))
			for j in 3:
				bx(Vector3(s * .307, y + .13, -.11 + j * .11), Vector3(.004, .05, .06), "8e1f1a", MATTE, Vector3(0, 0, s * .15))
	# Folded handles and a label on the top basket.
	var rim := .03 + 3 * .09 + .2
	for dx in [-.13, .13]:
		for s in [-1, 1]:
			rod(Vector3(dx, rim, s * .21), Vector3(dx, rim + .035, s * .06), .02, CHARCOAL, SATIN)
		rod(Vector3(dx, rim + .035, -.06), Vector3(dx, rim + .035, .06), .026, CHARCOAL, SATIN)
	bx(Vector3(0, rim - .07, -.21), Vector3(.18, .06, .004), WHITE, MATTE, Vector3(.15, 0, 0))
	bx(Vector3(0, rim - .07, -.2125), Vector3(.1, .015, .002), NAVY, MATTE, Vector3(.15, 0, 0))

## Belt, origin at the belt box centre (.56 x .03 x 2.3 along Z), with a divider bar.
func _fit_conveyor_belt(_side: float) -> void:
	bx(Vector3(0, .004, 0), Vector3(.52, .02, 2.24), "2b2f33", MATTE)
	for k in 16:
		bx(Vector3(0, .0145, -1.05 + k * .14), Vector3(.5, .002, .014), "3d4348", MATTE)
	for s in [-1, 1]:
		bx(Vector3(s * .285, .005, 0), Vector3(.03, .04, 2.32), "9aa3a8", METAL)
		cyl(Vector3(s * .285, .028, 0), Vector3(.034, 2.32, .034), CHROME, METAL, Vector3(PI / 2, 0, 0), 8)
	for z in [-1.13, 1.13]:
		cyl(Vector3(0, .0, z), Vector3(.05, .52, .05), "9aa3a8", METAL, Vector3(0, 0, PI / 2), 8)
	for k in 4:
		prism(Vector3(-.18 + k * .12, .04, -.6), Vector3(.05, .045, .12), RED if k % 2 == 0 else WHITE, SATIN, Vector3(0, PI / 2, 0))

## Flatbed scanner in the counter top with its tower on the cashier's side.
func _fit_scanner(side: float) -> void:
	bx(Vector3.ZERO, Vector3(.4, .012, .36), "9aa3a8", METAL)
	bx(Vector3(0, .006, 0), Vector3(.28, .004, .24), "35606e", SATIN)
	for a in [0.0, .6, -.6]:
		bx(Vector3(0, .0085, 0), Vector3(.2, .001, .005), LASER, MATTE, Vector3(0, a, 0))
	bx(Vector3(-side * .2, .11, 0), Vector3(.06, .22, .32), CHARCOAL, SATIN)
	cyl(Vector3(-side * .2, .22, 0), Vector3(.06, .32, .06), CHARCOAL, SATIN, Vector3(PI / 2, 0, 0), 8)
	bx(Vector3(-side * .168, .12, 0), Vector3(.004, .14, .24), "35606e", SATIN)
	bx(Vector3(-side * .1655, .12, 0), Vector3(.002, .004, .2), LASER, MATTE)
	ball(Vector3(-side * .2, .25, -.12), Vector3(.022, .022, .022), "7bd88f", SATIN, Vector3.ZERO, 6)

## Cash register: drawer base and a keypad sloping toward the cashier (-side).
func _fit_cash_register(side: float) -> void:
	bx(Vector3(0, -.035, 0), Vector3(.36, .07, .34), "3c4650", SATIN)
	bx(Vector3(-side * .181, -.035, 0), Vector3(.004, .05, .3), "55606b", SATIN)
	bx(Vector3(-side * .184, -.03, 0), Vector3(.004, .012, .1), CHROME, METAL)
	bx(Vector3(side * .06, .03, 0), Vector3(.22, .06, .3), "3c4650", SATIN)
	var c := Vector3(-side * .08, .04, 0)
	var r := Vector3(0, 0, side * .3)
	bx(c, Vector3(.16, .03, .26), "2a3138", SATIN, r)
	for i in 4:
		for j in 4:
			var tint := "dfe3e6"
			if i == 3 and j == 3:
				tint = "43a047"
			elif i == 3 and j == 0:
				tint = "e53935"
			bx(_on(c, r, Vector3(-.054 + i * .036, .017, -.075 + j * .05)), Vector3(.026, .008, .034), tint, SATIN, r)
	bx(Vector3(side * .12, .07, -.1), Vector3(.1, .02, .1), "2a3138", SATIN)

## Cashier's monitor (screen toward -side) on a neck, and the customer display on its own pole.
func _fit_screen(side: float) -> void:
	bx(Vector3(side * .005, 0, 0), Vector3(.045, .25, .35), CHARCOAL, SATIN)
	bx(Vector3(-side * .0245, 0, 0), Vector3(.004, .21, .31), SCREEN, MATTE)
	bx(Vector3(-side * .027, .085, 0), Vector3(.002, .03, .3), NAVY, MATTE)
	for k in 4:
		bx(Vector3(-side * .027, .045 - k * .03, -.03), Vector3(.002, .012, .22), "90a4ae", MATTE)
	bx(Vector3(-side * .027, -.08, .08), Vector3(.002, .03, .11), "43a047", MATTE)
	cyl(Vector3(side * .01, -.19, 0), Vector3(.03, .16, .03), "5b646c", METAL, Vector3.ZERO, 8)
	bx(Vector3(side * .01, -.275, 0), Vector3(.12, .012, .12), "5b646c", METAL)
	var d := Vector3(side * .62, -.12, -.3)
	bx(d, Vector3(.03, .14, .22), CHARCOAL, SATIN)
	bx(d + Vector3(side * .016, 0, 0), Vector3(.004, .11, .18), "16301f", MATTE)
	bx(d + Vector3(side * .0185, .02, 0), Vector3(.002, .022, .12), "8bc34a", MATTE)
	bx(d + Vector3(side * .0185, -.025, .03), Vector3(.002, .02, .07), "8bc34a", MATTE)
	cyl(d + Vector3(0, -.185, 0), Vector3(.025, .23, .025), "5b646c", METAL, Vector3.ZERO, 8)
	cyl(d + Vector3(0, -.295, 0), Vector3(.1, .01, .1), "5b646c", METAL, Vector3.ZERO, 10)

## Card terminal on a short stand, keys toward the customer (+side).
func _fit_card_reader(side: float) -> void:
	var c := Vector3(0, .005, 0)
	var r := Vector3(0, 0, side * .22)
	bx(c, Vector3(.05, .13, .075), CHARCOAL, SATIN, r)
	bx(_on(c, r, Vector3(side * .026, .035, 0)), Vector3(.004, .035, .056), "a5d6a7", MATTE, r)
	for i in 4:
		for j in 3:
			bx(_on(c, r, Vector3(side * .026, -.005 - i * .014, -.018 + j * .018)), Vector3(.004, .009, .012), "43a047" if i == 3 and j == 2 else "cfd8dc", SATIN, r)
	bx(_on(c, r, Vector3(0, .066, 0)), Vector3(.03, .004, .06), "111417", MATTE, r)
	cyl(Vector3(0, -.11, 0), Vector3(.02, .1, .02), "5b646c", METAL, Vector3.ZERO, 6)
	cyl(Vector3(0, -.157, 0), Vector3(.07, .008, .07), "5b646c", METAL, Vector3.ZERO, 10)

## Printed till receipt (the root is tilted back), lines on both faces and a torn foot.
func _fit_receipt(_side: float) -> void:
	bx(Vector3.ZERO, Vector3(.06, .14, .003), "fbfbf6", MATTE)
	cyl(Vector3(0, .07, .004), Vector3(.012, .06, .012), "f1efe6", MATTE, Vector3(0, 0, PI / 2), 6)
	for s in [-1, 1]:
		bx(Vector3(0, .052, s * .0018), Vector3(.03, .007, .001), "37474f", MATTE)
		for k in 6:
			bx(Vector3(-.004 + (k % 2) * .004, .032 - k * .012, s * .0018), Vector3(.04 - (k % 2) * .008, .003, .001), "9aa0a6", MATTE)
		bx(Vector3(0, -.045, s * .0018), Vector3(.044, .006, .001), "37474f", MATTE)
	for k in 4:
		prism(Vector3(-.0225 + k * .015, -.074, 0), Vector3(.015, .008, .003), "fbfbf6", MATTE, Vector3(0, 0, PI))

## Two kraft carrier bags (wide face to the customer) on a bag-well mat, a baguette in one.
func _fit_shopping_bag(side: float) -> void:
	bx(Vector3(0, .004, 0), Vector3(.3, .008, .74), "e6e2d8", MATTE)
	for bz in [-.18, .18]:
		bx(Vector3(0, .155, bz), Vector3(.16, .29, .26), KRAFT, MATTE)
		bx(Vector3(0, .29, bz), Vector3(.166, .02, .266), darker(KRAFT, .12), MATTE)
		for s in [-1, 1]:
			bx(Vector3(s * .0815, .15, bz), Vector3(.002, .27, .004), darker(KRAFT, .08), MATTE)
		ball(Vector3(side * .081, .17, bz), Vector3(.004, .07, .05), LEAF, MATTE, Vector3(0, 0, .3), 8)
		bx(Vector3(side * .081, .09, bz), Vector3(.003, .014, .15), NAVY, MATTE)
		for dx in [-.05, .05]:
			ring(Vector3(dx, .3, bz), Vector3(.13, .012, .13), "8d6e4a", MATTE, Vector3(0, 0, PI / 2), .8, 12)
	cyl(Vector3(-.02, .36, -.14), Vector3(.055, .26, .055), "d39b55", MATTE, Vector3(.35, 0, .2), 8)
	ball(Vector3(-.045, .49, -.095), Vector3(.05, .05, .05), "c98a45", MATTE, Vector3.ZERO, 6)

## Two queue stanchions with a red belt and floor footprints, origin on the floor.
func _fit_queue(_side: float) -> void:
	for dz in [-.8, .8]:
		cyl(Vector3(0, .012, dz), Vector3(.3, .024, .3), CHARCOAL, SATIN, Vector3.ZERO, 14)
		dome(Vector3(0, .024, dz), Vector3(.24, .05, .24), CHARCOAL, SATIN, Vector3.ZERO, 12)
		cyl(Vector3(0, .48, dz), Vector3(.05, .9, .05), CHROME, METAL, Vector3.ZERO, 10)
		cyl(Vector3(0, .92, dz), Vector3(.075, .08, .075), CHROME, METAL, Vector3.ZERO, 10)
		dome(Vector3(0, .96, dz), Vector3(.075, .025, .075), CHROME, METAL, Vector3.ZERO, 10)
	bx(Vector3(0, .88, 0), Vector3(.012, .055, 1.52), "c62828", SATIN)
	bx(Vector3(0, .88, 0), Vector3(.014, .008, 1.52), "f2c94c", SATIN)
	for dz in [-.5, .4]:
		cyl(Vector3(.75, .002, dz), Vector3(.28, .003, .28), "f2c94c", MATTE, Vector3.ZERO, 14)
		for s in [-1, 1]:
			ball(Vector3(.75 + s * .045, .004, dz + .01), Vector3(.055, .002, .1), "37474f", MATTE, Vector3.ZERO, 8)
			ball(Vector3(.75 + s * .045, .004, dz - .065), Vector3(.045, .002, .035), "37474f", MATTE, Vector3.ZERO, 8)

## Cash tray: notes in three compartments at the back, coins in four cups at the front.
func _fit_money(_side: float) -> void:
	bx(Vector3(0, .008, 0), Vector3(.32, .016, .24), "3c4650", SATIN)
	for s in [-1, 1]:
		bx(Vector3(s * .155, .03, 0), Vector3(.01, .06, .24), "3c4650", SATIN)
		bx(Vector3(0, .03, s * .115), Vector3(.32, .06, .01), "3c4650", SATIN)
	bx(Vector3(0, .025, .03), Vector3(.3, .05, .008), "3c4650", SATIN)
	var notes := ["8bc48a", "7fb3d5", "e9a3b5"]
	for k in 3:
		var x := -.09 + k * .09
		if k > 0:
			bx(Vector3(x - .045, .03, -.04), Vector3(.006, .05, .13), "3c4650", SATIN)
		bx(Vector3(x, .03, -.04), Vector3(.075, .03, .12), notes[k], MATTE)
		bx(Vector3(x, .046, -.04), Vector3(.064, .002, .108), lighter(notes[k], .12), MATTE)
		ball(Vector3(x, .048, -.04), Vector3(.034, .002, .046), darker(notes[k], .3), MATTE, Vector3.ZERO, 8)
	for k in 4:
		var x := -.105 + k * .07
		var coin := GOLD if k < 2 else "c9ced3"
		cyl(Vector3(x, .03, .075), Vector3(.034, .028 - k * .004, .034), coin, METAL, Vector3.ZERO, 10)
		cyl(Vector3(x, .045 - k * .002, .075), Vector3(.03, .002, .03), lighter(coin, .2), METAL, Vector3.ZERO, 10)

## Payment card: chip, a lighter band and embossed number groups.
func _fit_credit_card(_side: float) -> void:
	bx(Vector3.ZERO, Vector3(.13, .006, .08), "1e88e5", SATIN)
	bx(Vector3(0, .0032, -.026), Vector3(.13, .001, .014), "64b5f6", SATIN)
	bx(Vector3(-.035, .0036, -.002), Vector3(.022, .001, .018), GOLD, METAL)
	for k in 4:
		bx(Vector3(-.045 + k * .026, .0035, .018), Vector3(.018, .001, .006), "e3f2fd", MATTE)
	bx(Vector3(.042, .0035, -.004), Vector3(.026, .001, .012), WHITE, MATTE)

## Crushed ice over a seafood slab (size x by z, top at y = 0): a jittered, flat-shaded grid
## that falls to the slab edge, with lemon halves and parsley along the front (-Z) edge.
func crushed_ice(size: Vector2, seed_text: String) -> ArrayMesh:
	begin()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	var nx := maxi(2, roundi(size.x / .038))
	var nz := maxi(2, roundi(size.y / .038))
	var points := []
	for i in nx + 1:
		var column := []
		for j in nz + 1:
			var p := Vector3(-size.x * .5 + size.x * i / nx, 0, -size.y * .5 + size.y * j / nz)
			if i > 0 and i < nx and j > 0 and j < nz:
				p += Vector3(rng.randf_range(-.008, .008), .006 + rng.randf() * .024 + .01 * j / nz, rng.randf_range(-.008, .008))
			column.append(p)
		points.append(column)
	var tints := ["eef6fa", "d8e9f1", "c2dce8", "a9cadb", "e3f0f6", "93bccf"]
	for i in nx:
		for j in nz:
			var a: Vector3 = points[i][j]
			var b: Vector3 = points[i + 1][j]
			var c: Vector3 = points[i + 1][j + 1]
			var d: Vector3 = points[i][j + 1]
			tri(a, b, c, tints[rng.randi() % tints.size()])
			tri(a, c, d, tints[rng.randi() % tints.size()])
	var count := maxi(2, int(size.x / .45))
	for k in count:
		var x := -size.x * .5 + size.x * (k + .5) / count + rng.randf_range(-.05, .05)
		var z := -size.y * .5 + .07
		cyl(Vector3(x, .016, z), Vector3(.07, .03, .07), "f2d43b", SATIN, Vector3.ZERO, 10)
		cyl(Vector3(x, .032, z), Vector3(.058, .004, .058), "fbf0a6", MATTE, Vector3.ZERO, 10)
		for s in 4:
			var a := s * TAU / 4 + rng.randf() * .5
			ball(Vector3(x + .07 + cos(a) * .025, .025, z + sin(a) * .025), Vector3(.035, .025, .035), DARK_LEAF if s % 2 == 0 else LEAF, MATTE, Vector3.ZERO, 6)
	return finish("Crushed ice " + seed_text)

# ---------------------------------------------------------------------------------------------
# Featured fruit (13 Nov 2026, user: the welcome tutorial's apple and banana easy to see, a bit
# bigger and nicer). Smooth lathed apples with a stem and leaf in a glossy finish, a fanned bunch
# of ridged bananas, a wicker basket and a round pedestal table with a cloth; supermarket.gd
# tutorial_fruit places them inside the door. Market units, origin on the surface each stands on.

const FeatureGeo := preload("res://scripts/buildings/monument_plaza.gd").Geo
## Featured apple diameter and banana length (the shelf goods: .26 and .48).
const FEATURE_APPLE := .34
const FEATURE_BANANA := .72
## Featured table: top height and radius.
const FEATURE_TABLE_TOP := .85
const FEATURE_TABLE_RADIUS := .66

## A finish for the featured fruit: vertex colours, its own roughness (apples shine).
static func feature_finish(roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = roughness
	return material

## Indexed and compressed like the shelf goods (finish()), so the saved scene stays small.
static func _feature_mesh(g, roughness: float, title: String) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = g.verts
	arrays[Mesh.ARRAY_NORMAL] = g.norms
	arrays[Mesh.ARRAY_COLOR] = g.cols
	var tool := SurfaceTool.new()
	tool.create_from_arrays(arrays)
	tool.index()
	var mesh: ArrayMesh = tool.commit(null, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
	mesh.resource_name = title
	mesh.surface_set_material(0, feature_finish(roughness))
	return mesh

## Transforms the vertices (and normals) appended to `g` since index `from`.
static func _feature_shape(g, from: int, xform: Transform3D) -> void:
	var normal_basis := xform.basis.inverse().transposed()
	for i in range(from, g.verts.size()):
		g.verts[i] = xform * g.verts[i]
		g.norms[i] = (normal_basis * g.norms[i]).normalized()

## One apple of diameter `d` standing at the origin (shaped, then placed by `xform`).
static func _feature_apple(g, d: float, skin: Color, xform: Transform3D) -> void:
	var from: int = g.verts.size()
	var profile := []
	for p in [[0, .1], [.12, .05], [.26, .02], [.4, .08], [.49, .22], [.52, .4], [.5, .58], [.44, .74], [.33, .86], [.2, .9], [.1, .86], [0, .8]]:
		profile.append(Vector2(p[0], p[1]) * d)
	g.color = skin
	g.lathe(Vector3.ZERO, profile, 14)
	g.color = Color("6b4a2b")
	g.loft([Vector3(0, .8 * d, 0), Vector3(.02 * d, .95 * d, 0), Vector3(.05 * d, 1.06 * d, 0)], [Vector2(.03, .03) * d, Vector2(.028, .028) * d, Vector2(.025, .025) * d], Vector3.RIGHT, 5)
	g.color = Color("4f9a3a")
	g.ellipsoid(Vector3(.15 * d, .99 * d, .02 * d), Vector3(.16, .018, .075) * d, Basis(Vector3.BACK, -.35) * Basis(Vector3.UP, .4), 8, 4)
	_feature_shape(g, from, xform)

## Four big apples heaped in the basket (three around, one on top).
static func featured_apples() -> ArrayMesh:
	var g = FeatureGeo.new()
	var d := FEATURE_APPLE
	var skins := [Color("c8312b"), Color("d23f2a"), Color("b8262a"), Color("cc3a2c")]
	for k in 3:
		var a := k * TAU / 3 + .3
		var tilt := Basis(Vector3(cos(a + PI / 2), 0, sin(a + PI / 2)), .18) * Basis(Vector3.UP, a * 1.7)
		_feature_apple(g, d, skins[k], Transform3D(tilt, Vector3(cos(a) * .16, .045, sin(a) * .16)))
	_feature_apple(g, d, skins[3], Transform3D(Basis(Vector3.UP, 1.1), Vector3(0, .045 + d * .55, 0)))
	return _feature_mesh(g, .26, "Featured apples")

## Wicker basket for the apples: radius .38, .18 high, two woven bands.
static func fruit_basket() -> ArrayMesh:
	var g = FeatureGeo.new()
	g.color = Color("c9a477")
	g.lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.26, 0), Vector2(.34, .06), Vector2(.37, .16), Vector2(.38, .18), Vector2(.35, .18), Vector2(.31, .07), Vector2(0, .045)], 20)
	g.color = Color("a07a4a")
	for y: float in [.07, .13]:
		var r: float = .34 + (y - .06) * .3
		g.lathe(Vector3.ZERO, [Vector2(r, y - .012), Vector2(r + .012, y), Vector2(r, y + .012)], 20)
	return _feature_mesh(g, .85, "Fruit basket")

## A fanned bunch of four bananas lying on the table, joined at the crown (+Z end).
static func featured_bananas() -> ArrayMesh:
	var g = FeatureGeo.new()
	var length := FEATURE_BANANA
	var pivot := Vector3(0, .07, length * .5)
	for k in 4:
		var from: int = g.verts.size()
		var points := []
		var radii := []
		for i in 9:
			var t := i / 8.0
			points.append(Vector3(0, .064 + .2 * length * pow(2.0 * t - 1.0, 2.0) * (1.0 if t < .5 else .6), length * (t - .5)))
			var r := .064 * (.35 + .65 * pow(sin(PI * t), .7))
			radii.append(Vector2(r, r * .9))
		g.color = Color("f2cf3a") if k != 2 else Color("eec834")
		g.loft(points, radii, Vector3.UP, 6)
		g.color = Color("4a3a28")
		g.ellipsoid(points[0] + Vector3(0, 0, -.01), Vector3(.018, .018, .02), Basis(), 6, 3)
		g.color = Color("8a8a3a")
		g.loft([points[8], points[8] + Vector3(0, .015, .05)], [Vector2(.02, .02), Vector2(.022, .022)], Vector3.UP, 6)
		var yaw := (k - 1.5) * .19
		var lift := .03 if k == 1 or k == 2 else 0.0
		_feature_shape(g, from, Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO).translated_local(-pivot).translated(pivot + Vector3(0, lift, 0)))
	g.color = Color("6f7a34")
	g.ellipsoid(pivot + Vector3(0, .03, .05), Vector3(.05, .04, .045), Basis(), 8, 4)
	return _feature_mesh(g, .5, "Featured bananas")

## Round pedestal table (top FEATURE_TABLE_TOP high) with a cream cloth.
static func fruit_table() -> ArrayMesh:
	var g = FeatureGeo.new()
	var top := FEATURE_TABLE_TOP
	var r := FEATURE_TABLE_RADIUS
	g.color = Color("7a4e2c")
	g.lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.38, 0), Vector2(.38, .04), Vector2(.14, .09), Vector2(.08, .12), Vector2(.07, top - .08), Vector2(.12, top - .05), Vector2(0, top - .05)], 20)
	g.color = Color("9a6a3c")
	g.lathe(Vector3.ZERO, [Vector2(0, top - .05), Vector2(r - .02, top - .05), Vector2(r, top - .03), Vector2(r, top - .012), Vector2(0, top - .012)], 28)
	g.color = Color("f3ead6")
	g.lathe(Vector3.ZERO, [Vector2(0, top - .004), Vector2(r * .86, top - .004), Vector2(r * .86, top), Vector2(0, top)], 28)
	g.color = Color("5e9a4f")
	g.lathe(Vector3.ZERO, [Vector2(r * .86, top - .003), Vector2(r * .9, top - .003), Vector2(r * .9, top + .001), Vector2(r * .86, top + .001)], 28)
	return _feature_mesh(g, .8, "Fruit table")
