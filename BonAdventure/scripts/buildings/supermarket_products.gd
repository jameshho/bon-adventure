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
## From the 2 Nov 2026 refit; kinds redrawn on 18 Nov 2026 have the footprint of their new shape.
const FOOT = {
	"apple":Vector3(.15,.15,.15), "orange":Vector3(.16,.16,.15), "lemon":Vector3(.15,.13,.12), "lime":Vector3(.11,.09,.1),
	"pear":Vector3(.14,.14,.2), "peach":Vector3(.14,.14,.14), "cherry":Vector3(.1,.06,.12), "strawberry":Vector3(.085,.085,.1),
	"grapes":Vector3(.16,.16,.13), "banana":Vector3(.2,.34,.07), "pineapple":Vector3(.2,.2,.36), "mango":Vector3(.17,.14,.13),
	"coconut":Vector3(.17,.17,.17), "watermelon":Vector3(.52,.4,.38), "avocado":Vector3(.12,.12,.14),
	"tomato":Vector3(.14,.14,.13), "carrot":Vector3(.08,.3,.06), "broccoli":Vector3(.14,.14,.16), "potato":Vector3(.16,.12,.1),
	"lettuce":Vector3(.2,.2,.18), "onion":Vector3(.13,.13,.16), "garlic":Vector3(.1,.1,.11), "corn":Vector3(.1,.3,.08),
	"chili pepper":Vector3(.07,.2,.045), "mushroom":Vector3(.11,.11,.09), "cucumber":Vector3(.08,.32,.07), "bell pepper":Vector3(.15,.15,.16),
	"cereal":Vector3(.22,.1,.3), "rice":Vector3(.18,.1,.22), "beans":Vector3(.17,.09,.18), "flour":Vector3(.18,.11,.24),
	"sugar":Vector3(.16,.1,.2), "pasta":Vector3(.1,.08,.24), "tortilla":Vector3(.22,.22,.12), "oil":Vector3(.1,.1,.29),
	"salt":Vector3(.1,.1,.15), "pepper":Vector3(.07,.07,.15), "honey":Vector3(.11,.11,.13), "jam":Vector3(.1,.1,.12),
	"salsa":Vector3(.11,.11,.13), "olive":Vector3(.1,.1,.14), "jar":Vector3(.12,.12,.15), "can":Vector3(.1,.1,.12),
	"tuna":Vector3(.11,.11,.05), "soup":Vector3(.1,.1,.12), "coffee":Vector3(.08,.08,.22), "tea":Vector3(.18,.1,.1),
	"cookie":Vector3(.2,.09,.06), "cracker":Vector3(.15,.07,.19), "snack":Vector3(.17,.09,.23), "chocolate":Vector3(.08,.04,.13), "candy":Vector3(.12,.06,.13),
	"milk":Vector3(.11,.11,.21), "yogurt":Vector3(.17,.09,.09), "butter":Vector3(.14,.08,.07), "cheese":Vector3(.15,.13,.08),
	"eggs":Vector3(.21,.15,.14), "ham":Vector3(.25,.16,.1), "sausage":Vector3(.22,.13,.05), "salad":Vector3(.16,.08,.2),
	"chicken":Vector3(.2,.15,.1), "meat":Vector3(.22,.14,.09), "steak":Vector3(.25,.17,.05), "fish":Vector3(.14,.36,.06),
	"shrimp":Vector3(.14,.1,.05), "water bottle":Vector3(.08,.08,.25), "juice":Vector3(.1,.1,.22), "soda":Vector3(.08,.08,.23),
	"soap":Vector3(.11,.075,.08), "sponge":Vector3(.12,.08,.06), "detergent":Vector3(.15,.1,.26), "toothbrush":Vector3(.07,.04,.2),
	"toothpaste":Vector3(.18,.06,.05), "shampoo":Vector3(.1,.07,.23), "toilet paper":Vector3(.23,.23,.13),
	"bread":Vector3(.22,.2,.13), "baguette":Vector3(.5,.08,.06), "croissant":Vector3(.17,.11,.07), "cake":Vector3(.3,.3,.16),
	"cupcake":Vector3(.11,.11,.14), "donut":Vector3(.12,.12,.05)
}

## Loose produce is piled (layers from the pick height, small random turn, size and offset);
## everything else stands in neat front-facing rows.
const PILED := ["apple", "orange", "lemon", "lime", "pear", "peach", "cherry", "strawberry", "grapes", "banana",
	"pineapple", "mango", "coconut", "watermelon", "avocado", "tomato", "carrot", "broccoli", "potato", "lettuce",
	"onion", "garlic", "corn", "chili pepper", "mushroom", "cucumber", "bell pepper", "shrimp", "bread", "croissant",
	"donut", "cupcake"]
## Most units in one group (the 2 Nov groups held at most 30).
const CAP := 30
## Size rule (18 Nov 2026, goods_scale): smallest longest side of a displayed unit, the coconut's.
const MIN_SIDE := .3
const COCONUT_SIDE := .4
## Tallest pick box restock() grows a group to (as supermarket.gd _fit_pick: under the next shelf).
const PICK_TOP := .42

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
var _scales := {}
## Pick boxes restock() has grown (for restock_all's report).
var _grown := 0
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

## Products are drawn larger than life so they read from across the aisle (3 Nov 2026), and no
## unit is smaller than the coconut was (18 Nov 2026, user: "nothing should be smaller than the
## current coconut, and the coconut should be bigger"): every variant's longest displayed side is
## at least MIN_SIDE and the coconut's is COCONUT_SIDE (1.4 x its old .283). Big goods keep the
## 3 Nov enlargement.
func goods_scale(kind: String) -> float:
	if _scales.has(kind):
		return _scales[kind]
	var foot: Vector3 = FOOT[kind]
	var biggest := maxf(foot.x, maxf(foot.y, foot.z))
	var want := 1.9 if biggest <= .12 else (1.7 if biggest <= .2 else 1.4)
	var grow := clampf(minf(want, .4 / foot.z), 1.0, want)
	var side := INF
	for v in variants(kind):
		var size := model(kind, v).get_aabb().size
		side = minf(side, maxf(size.x, maxf(size.y, size.z)))
	grow = maxf(grow, (COCONUT_SIDE if kind == "coconut" else MIN_SIDE) / side)
	_scales[kind] = grow
	return grow

func variants(kind: String) -> int:
	return int({"apple":3, "pear":2, "peach":1, "grapes":2, "banana":2, "mango":2, "coconut":2, "watermelon":2,
		"avocado":2, "onion":2, "mushroom":2, "bell pepper":3, "cereal":4, "rice":2, "pasta":2, "oil":2, "jam":3,
		"can":3, "coffee":2, "tea":2, "snack":4, "chocolate":3, "candy":4, "milk":3, "yogurt":3, "cheese":2,
		"eggs":2, "chicken":2, "water bottle":1, "soda":3, "juice":3, "soap":3, "sponge":2, "detergent":3, "toothbrush":3,
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
## The root, its name, word_key and transform stay exactly as they were; the footprint is read
## back from the pick area (size = w + .02, h + .02, d + .02 + pad; turned to the goods' yaw).
## Units bigger than the group was built for (18 Nov 2026 size rule) mean fewer units, spread
## over the same area; a pick box lower than a unit (or a pile) grows upward from its bottom, at
## most PICK_TOP, and one narrower or shallower than a single unit grows to hold it.
## Returns the number of units placed.
func restock(root: Node3D) -> int:
	var kind := str(root.get_meta("word_key"))
	var area: Area3D
	for child in root.get_children():
		if child is Area3D:
			area = child
	var shape := area.get_child(0) as CollisionShape3D
	var box: Vector3 = (shape.shape as BoxShape3D).size
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
	var piled := kind in PILED
	var layers := clampi(roundi((h / foot.z - 1.0) / .75) + 1, 1, 2) if piled else 1
	if layers == 2 and foot.z * 1.75 > maxf(h, PICK_TOP - .02) + .005:
		layers = 1
	# Grow the pick box to hold the units: up to PICK_TOP high, and at least one unit wide and deep.
	var need := Vector3(maxf(w, foot.x), maxf(h, minf(foot.z * (1.0 + .75 * (layers - 1)), PICK_TOP - .02)), maxf(d, foot.y))
	if not need.is_equal_approx(Vector3(w, h, d)):
		var bigger := (shape.shape as BoxShape3D).duplicate() as BoxShape3D
		bigger.size = box + need - Vector3(w, h, d)
		shape.position.y += (need.y - h) * .5
		shape.shape = bigger
		w = need.x
		h = need.y
		d = need.z
		_grown += 1
	# Never taller than the pick area: shrink the rare unit that would poke out of it.
	if foot.z > h + .005:
		grow *= h / foot.z
		foot = FOOT[kind] * grow
	var cols := maxi(1, int(w / foot.x))
	# Shelf goods (gondolas, end caps, racks: no front reach, at most .45 deep) stand one row deep
	# as before; fridges, the cooler and service counters show two rows; produce fills its bin.
	var deep_max := 5 if piled else (1 if pad < .01 and d <= .45 else 2)
	var deep := clampi(int(d / foot.y), 1, deep_max)
	while cols * deep * layers > CAP and deep > 1:
		deep -= 1
	while cols * deep * layers > CAP and cols > 1:
		cols -= 1
	# Piled units get a small random offset and turn: keep them a little inside the edges.
	var step := Vector2(w / cols, d / deep) if not piled else Vector2(maxf(w - .04, foot.x) / cols, maxf(d - .04, foot.y) / deep)
	var placed := 0
	# Small groups (a few cakes) step through the variants so each one shows; larger groups
	# pick at random like a mixed shelf.
	var cycle := cols * deep * layers <= 2 * variants(kind)
	var first := rng.randi()
	for layer in range(layers):
		var row_deep := maxi(1, deep - layer)
		for i in range(maxi(1, cols - layer)):
			for j in range(row_deep):
				var o := Vector3((i - (maxi(1, cols - layer) - 1) * .5) * step.x, layer * foot.z * .75, (j - (row_deep - 1) * .5) * step.y)
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

## Restock every product group in the market interior with the current models (18 Nov 2026:
## clay-toy redraw and size rule), for one baked step in supermarket.gd. The groups are those
## product_models() rebuilds: word roots of a product kind holding only product meshes and one
## pick Area3D. Candy-rack frames and the tutorial's featured fruit are left alone. Root names,
## word_key and transforms are kept; pick boxes grow only where a unit needs it (restock()).
## Returns the number of groups restocked and prints a summary.
func restock_all(interior: Node3D) -> int:
	var groups := 0
	var units := 0
	var skipped := []
	_grown = 0
	for root in interior.get_children():
		if not root is Node3D or not root.has_meta("word_key") or not FOOT.has(str(root.get_meta("word_key"))):
			continue
		var title := str(root.name)
		if title.begins_with("Candy rack") or title.begins_with("Featured"):
			continue
		var areas := root.get_children().filter(func(child): return child is Area3D)
		var others := root.get_children().filter(func(child): return not child is Area3D and not child is MeshInstance3D)
		if areas.size() != 1 or not others.is_empty():
			skipped.append(title)
			continue
		units += restock(root)
		groups += 1
	print("SUPERMARKET restock_all: %d groups, %d units, %d pick boxes grown, skipped %s" % [groups, units, _grown, skipped])
	return groups

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

# Soft clay-toy parts (18 Nov 2026): chunkier, rounder goods with soft bevels. Each writes its
# own vertices (sizes in market units, no stretching of the bevels) into the same merged mesh.

## Appends one triangle list with per-vertex normals, turned by Euler `r` and moved to `c`.
func _emit(c: Vector3, r: Vector3, verts: PackedVector3Array, norms: PackedVector3Array, ids: PackedInt32Array, tint: String, f: int) -> void:
	var basis := Basis.from_euler(r)
	var base: int = _v[f].size()
	var colour := Color(tint)
	for k in verts.size():
		_v[f].append(c + basis * verts[k])
		_n[f].append((basis * norms[k]).normalized())
		_c[f].append(colour)
	for k in ids:
		_i[f].append(base + k)

## Adds the triangle a, b, c (indices into verts) facing `out`.
func _face(ids: PackedInt32Array, verts: PackedVector3Array, a: int, b: int, c: int, out: Vector3) -> void:
	if (verts[b] - verts[a]).cross(verts[c] - verts[a]).dot(out) < 0.0:
		ids.append_array(PackedInt32Array([a, b, c]))
	else:
		ids.append_array(PackedInt32Array([a, c, b]))

## Box with soft rounded edges: one bevel whose vertices take the normals of the faces they
## touch, so the edges shade like a rounded clay block. `bevel` is a share of the smallest side.
func soft_box(c: Vector3, s: Vector3, tint: String, f := MATTE, r := Vector3.ZERO, bevel := .35) -> void:
	var h := s * .5
	var b := minf(s.x, minf(s.y, s.z)) * .5 * clampf(bevel, .01, .95)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var ids := PackedInt32Array()
	for a in 3:
		var u := (a + 1) % 3
		var w := (a + 2) % 3
		for sa in [-1.0, 1.0]:
			# Face.
			var q := []
			for corner in [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]:
				var sg := Vector3.ZERO
				sg[a] = sa; sg[u] = corner[0]; sg[w] = corner[1]
				q.append(_bevel_point(verts, norms, h, b, sg, a))
			var facing := Vector3.ZERO
			facing[a] = sa
			_face(ids, verts, q[0], q[1], q[2], facing)
			_face(ids, verts, q[0], q[2], q[3], facing)
			# Bevel between this face and the next axis' faces (each edge once).
			for su in [-1.0, 1.0]:
				var e := []
				for sw in [-1.0, 1.0]:
					var sg := Vector3.ZERO
					sg[a] = sa; sg[u] = su; sg[w] = sw
					e.append(_bevel_point(verts, norms, h, b, sg, a))
					e.append(_bevel_point(verts, norms, h, b, sg, u))
				var out := Vector3.ZERO
				out[a] = sa; out[u] = su
				_face(ids, verts, e[0], e[1], e[3], out)
				_face(ids, verts, e[0], e[3], e[2], out)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var sg := Vector3(sx, sy, sz)
				_face(ids, verts, _bevel_point(verts, norms, h, b, sg, 0), _bevel_point(verts, norms, h, b, sg, 1), _bevel_point(verts, norms, h, b, sg, 2), sg)
	_emit(c, r, verts, norms, ids, tint, f)

## The point of soft_box corner `sg` that lies on the face across axis `a`, with that face's normal.
func _bevel_point(verts: PackedVector3Array, norms: PackedVector3Array, h: Vector3, b: float, sg: Vector3, a: int) -> int:
	var p := (h - Vector3.ONE * b) * sg
	p[a] = h[a] * sg[a]
	var n := Vector3.ZERO
	n[a] = sg[a]
	verts.append(p)
	norms.append(n)
	return verts.size() - 1

## Solid of revolution about the local y axis from `profile` (Vector2(radius, y), bottom to
## top). Neighbouring segments within 50 degrees share smooth normals; sharper turns stay
## creased. `squash` scales x and z after turning (oval soaps, bottles).
func lathe(c: Vector3, profile: Array, tint: String, f := SATIN, sides := 12, r := Vector3.ZERO, squash := Vector3.ONE) -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var ids := PackedInt32Array()
	var seg := []
	for k in profile.size() - 1:
		var t: Vector2 = profile[k + 1] - profile[k]
		seg.append(Vector2(t.y, -t.x).normalized() if t.length() > .00001 else Vector2.ZERO)
	var scale_basis := Basis.from_scale(squash)
	var normal_basis := scale_basis.inverse().transposed()
	# One ring of vertices per profile point, two where the profile creases; each segment joins
	# the ring that ends it below to the ring that starts it above.
	var ring_out := []  # ring index used by the segment leaving point k
	var ring_in := []   # ring index used by the segment arriving at point k
	var rings := 0
	for k in profile.size():
		var below: Vector2 = seg[k - 1] if k > 0 else Vector2.ZERO
		var above: Vector2 = seg[k] if k < seg.size() else Vector2.ZERO
		var normals := []
		if below != Vector2.ZERO and above != Vector2.ZERO and below.dot(above) > .64:
			normals = [(below + above).normalized()]
		else:
			for n in [below, above]:
				if n != Vector2.ZERO:
					normals.append(n)
		var first := rings
		for n: Vector2 in normals:
			var p: Vector2 = profile[k]
			for j in sides + 1:
				var a := j * TAU / sides
				var dir := Vector3(cos(a), 0, sin(a))
				verts.append(scale_basis * (dir * p.x + Vector3.UP * p.y))
				norms.append((normal_basis * (dir * n.x + Vector3.UP * n.y)).normalized())
			rings += 1
		ring_in.append(first)
		ring_out.append(rings - 1)
	for k in seg.size():
		if seg[k] == Vector2.ZERO:
			continue
		var lo: int = ring_out[k] * (sides + 1)
		var hi: int = ring_in[k + 1] * (sides + 1)
		for j in sides:
			var out: Vector3 = norms[lo + j] + norms[lo + j + 1] + norms[hi + j] + norms[hi + j + 1]
			if out.length() < .0001:
				out = verts[lo + j] + verts[hi + j]
			_face(ids, verts, lo + j, lo + j + 1, hi + j + 1, out)
			_face(ids, verts, lo + j, hi + j + 1, hi + j, out)
	_emit(c, r, verts, norms, ids, tint, f)

## Rounded tube through `points` with per-point radii (float, or Vector2(side, up) for an oval),
## for sausages, croissants, chillies, fish and shrimp. Ends are closed with a small round cap.
func tube(points: Array, radii: Array, tint: String, f := SATIN, sides := 8, up := Vector3.UP) -> void:
	var pts := points.duplicate()
	var rad := []
	for value in radii:
		rad.append(value if value is Vector2 else Vector2(value, value))
	# Round caps: a ring at half radius just past each end, then the pole.
	for e in 2:
		var at: int = 0 if e == 0 else pts.size() - 1
		var inner: int = 1 if e == 0 else pts.size() - 2
		var dir: Vector3 = (pts[at] - pts[inner]).normalized()
		var r0: Vector2 = rad[at]
		if r0.x < .0015:
			continue
		var cap := [pts[at] + dir * minf(r0.x, r0.y) * .55, pts[at] + dir * minf(r0.x, r0.y) * .8]
		var cap_r := [r0 * .72, r0 * .12]
		if e == 0:
			pts = [cap[1], cap[0]] + pts
			rad = [cap_r[1], cap_r[0]] + rad
		else:
			pts = pts + cap
			rad = rad + cap_r
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var ids := PackedInt32Array()
	var count := pts.size()
	for i in count:
		var t: Vector3 = (pts[mini(i + 1, count - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side := up.cross(t)
		if side.length() < .001:
			side = Vector3.RIGHT.cross(t)
		side = side.normalized()
		var lift := t.cross(side).normalized()
		var span: float = pts[mini(i + 1, count - 1)].distance_to(pts[maxi(i - 1, 0)])
		var grow_r: Vector2 = rad[mini(i + 1, count - 1)] - rad[maxi(i - 1, 0)]
		var slope := (grow_r.x + grow_r.y) * .5 / maxf(span, .0001)
		var rr: Vector2 = rad[i]
		for j in sides + 1:
			var a := j * TAU / sides
			verts.append(pts[i] + side * cos(a) * rr.x + lift * sin(a) * rr.y)
			var n := side * cos(a) / maxf(rr.x, .0005) + lift * sin(a) / maxf(rr.y, .0005)
			norms.append((n.normalized() - t * slope).normalized())
	for i in count - 1:
		for j in sides:
			var a0 := i * (sides + 1) + j
			var b0 := a0 + sides + 1
			var out: Vector3 = norms[a0] + norms[a0 + 1] + norms[b0] + norms[b0 + 1]
			_face(ids, verts, a0, a0 + 1, b0 + 1, out)
			_face(ids, verts, a0, b0 + 1, b0, out)
	_emit(Vector3.ZERO, Vector3.ZERO, verts, norms, ids, tint, f)

## Points on an arc in the xz plane (centre `c`, radius x/z, angles a0..a1), for curved tubes.
func arc(c: Vector3, radius: Vector2, a0: float, a1: float, count: int) -> Array:
	var out := []
	for k in count:
		var a := lerpf(a0, a1, k / float(count - 1))
		out.append(c + Vector3(sin(a) * radius.x, 0, -cos(a) * radius.y))
	return out

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
	# Clay-toy lime (18 Nov 2026): a plump oval lying on its side, a nub at each end, a highlight.
	tube([Vector3(-.052, .045, 0), Vector3(-.04, .045, 0), Vector3(-.02, .045, 0), Vector3(0, .045, 0), Vector3(.02, .045, 0), Vector3(.04, .045, 0), Vector3(.052, .045, 0)],
		[.007, .03, .042, .045, .042, .03, .007], "5fa833", SATIN, 12)
	ball(Vector3(-.014, .066, -.02), Vector3(.04, .022, .03), "8cc653", SATIN, Vector3.ZERO, 8)
	ball(Vector3(.022, .088, .004), Vector3(.04, .008, .02), LEAF, SATIN, Vector3(0, .3, -.3), 6)

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
	# A pair of plump cherries on joined stems with one leaf (clay-toy, 18 Nov 2026).
	var top := Vector3(.006, .112, 0)
	for side in [-1, 1]:
		var at := Vector3(side * .026, .026, 0)
		ball(at, Vector3(.054, .05, .052), "b3162f", SATIN, Vector3.ZERO, 12)
		ball(at + Vector3(-.01, .01, -.019), Vector3(.016, .012, .008), "e0566b", SATIN, Vector3.ZERO, 6)
		ball(at + Vector3(0, .024, 0), Vector3(.016, .006, .016), "7a0f22", SATIN, Vector3.ZERO, 6)
		tube([at + Vector3(0, .022, 0), at + Vector3(side * .006, .06, 0), top], [.0045, .0045, .0045], "5d7a2a", MATTE, 5)
	ball(top + Vector3(.022, -.004, 0), Vector3(.046, .01, .024), LEAF, SATIN, Vector3(0, 0, -.35), 8)

func _strawberry(_v: int) -> void:
	# Clay-toy strawberry (18 Nov 2026): a fat heart-shaped berry, bold seeds, a five-leaf crown.
	lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.012, .006), Vector2(.026, .022), Vector2(.037, .043), Vector2(.041, .06), Vector2(.036, .073), Vector2(.02, .08), Vector2(0, .082)], "d7263d", SATIN, 12)
	for spec in [[.028, .031, [-.75, 0.0, .75]], [.052, .04, [-1.1, -.37, .37, 1.1]]]:
		for a in spec[2]:
			var t: float = -PI / 2 + a
			ball(Vector3(cos(t) * spec[1], spec[0], sin(t) * spec[1]), Vector3(.009, .011, .009), "f6e27a", MATTE, Vector3.ZERO, 5)
	for k in 5:
		var a := k * TAU / 5 + .3
		ball(Vector3(cos(a) * .02, .081, sin(a) * .02), Vector3(.036, .008, .017), "3f8d3a", MATTE, Vector3(0, -a, -.25), 6)
	cyl(Vector3(0, .091, 0), Vector3(.01, .02, .01), "3f7d3a", MATTE, Vector3.ZERO, 5)

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
	# Clay-toy garlic bulb (18 Nov 2026): a round teardrop with soft clove ridges, a neck and roots.
	lathe(Vector3.ZERO, [Vector2(0, .002), Vector2(.026, .004), Vector2(.045, .02), Vector2(.05, .04), Vector2(.042, .06), Vector2(.022, .078), Vector2(.008, .092), Vector2(.006, .108), Vector2(0, .11)], "f3ecd9", SATIN, 12)
	for k in 5:
		var a := -PI / 2 + (k - 2) * .55
		var d := Vector3(cos(a), 0, sin(a))
		tube([d * .036 + Vector3(0, .014, 0), d * .05 + Vector3(0, .04, 0), d * .034 + Vector3(0, .068, 0)], [.003, .0042, .003], "dcc6d6", MATTE, 4)
	for k in 4:
		var a := k * TAU / 4
		tube([Vector3(0, .004, 0), Vector3(cos(a) * .014, -.0, sin(a) * .014)], [.0035, .002], "c9b48a", MATTE, 4)

func _corn(_v: int) -> void:
	cyl(Vector3(0, .036, -.01), Vector3(.062, .22, .062), "f2c94c", SATIN, Vector3(PI / 2, 0, 0), 8, .75)
	for k in 4:
		ring(Vector3(0, .036, -.09 + k * .055), Vector3(.064, .008, .064), "e0b23a", SATIN, Vector3(PI / 2, 0, 0), .85, 8)
	for side in [-1, 1]:
		ball(Vector3(side * .03, .032, .06), Vector3(.03, .05, .2), "8bb35a", MATTE, Vector3(0, side * .2, 0), 7)
	cyl(Vector3(0, .036, -.13), Vector3(.02, .03, .02), "b58a4a", MATTE, Vector3(PI / 2, 0, 0), 5, .3)

func _chili_pepper(_v: int) -> void:
	# Clay-toy chilli (18 Nov 2026): a chunky curved red pod tapering to a point, green cap and stem.
	tube([Vector3(0, .02, -.07), Vector3(.002, .021, -.04), Vector3(.008, .021, -.005), Vector3(.018, .019, .03), Vector3(.033, .015, .062), Vector3(.05, .009, .085)],
		[.017, .02, .019, .016, .01, .003], "cc2a22", SATIN, 10)
	ball(Vector3(-.004, .033, -.03), Vector3(.012, .006, .05), "e95a4c", SATIN, Vector3(0, .05, 0), 6)
	ball(Vector3(-.001, .021, -.077), Vector3(.036, .03, .022), "3d8a35", MATTE, Vector3.ZERO, 8)
	tube([Vector3(-.002, .025, -.085), Vector3(-.006, .031, -.1), Vector3(-.016, .037, -.108)], [.005, .005, .005], "3d8a35", MATTE, 5)

func _mushroom(v: int) -> void:
	# Clay-toy mushroom (18 Nov 2026): a fat stalk, beige gills and a plump domed cap.
	var cap := pick(v, ["a07856", "efe6d8"])
	lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.022, 0), Vector2(.026, .006), Vector2(.022, .028), Vector2(.02, .05), Vector2(0, .05)], "f4eee2", MATTE, 10)
	lathe(Vector3.ZERO, [Vector2(.019, .045), Vector2(.044, .04), Vector2(.052, .043)], "d8c8ad", MATTE, 12)
	lathe(Vector3.ZERO, [Vector2(.052, .043), Vector2(.056, .053), Vector2(.052, .067), Vector2(.038, .081), Vector2(.019, .088), Vector2(0, .09)], cap, SATIN, 12)
	if v == 0:
		for o in [Vector3(-.018, .08, -.02), Vector3(.02, .078, -.016), Vector3(0, .087, .004)]:
			ball(o, Vector3(.014, .005, .012), "c49c78", SATIN, Vector3.ZERO, 6)

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
	# A soft sleeve of cookies lying down, cookies peeking out of its open end, a cookie picture.
	var brand := pick(v, ["1e88e5", "c62828"])
	lathe(Vector3(-.02, .03, 0), [Vector2(0, -.075), Vector2(.024, -.075), Vector2(.03, -.068), Vector2(.03, .068), Vector2(.026, .075), Vector2(0, .075)], brand, SATIN, 10, Vector3(0, 0, PI / 2))
	for k in 3:
		cyl(Vector3(.06 + k * .013, .03, 0), Vector3(.054, .011, .054), "c48a4e" if k % 2 == 0 else "b57c42", MATTE, Vector3(0, 0, PI / 2), 10)
	for o in [Vector3(0, .012, -.008), Vector3(0, -.01, .01), Vector3(0, .004, .014)]:
		ball(Vector3(.0855, .03, 0) + o, Vector3(.005, .009, .009), "4a2a18", MATTE, Vector3.ZERO, 5)
	lathe(Vector3(-.02, .03, 0), [Vector2(.0305, -.035), Vector2(.0305, .035)], CREAM, MATTE, 10, Vector3(0, 0, PI / 2))
	cyl(Vector3(-.02, .03, -.031), Vector3(.034, .004, .034), "c48a4e", MATTE, Vector3(PI / 2, 0, 0), 10)
	for o in [Vector3(-.008, .006, 0), Vector3(.007, -.004, 0), Vector3(-.002, -.008, 0)]:
		ball(Vector3(-.02, .03, -.0335) + o, Vector3(.007, .007, .003), "4a2a18", MATTE, Vector3.ZERO, 4)

func _cracker(v: int) -> void:
	# An upright soft box with two big square salted crackers on its front (17 Nov 2026 kind,
	# clay-toy redraw 18 Nov 2026).
	var box := pick(v, ["d84315", "1565c0"])
	soft_box(Vector3(0, .095, 0), Vector3(.14, .19, .06), box, MATTE, Vector3.ZERO, .4)
	bx(Vector3(0, .168, -.0305), Vector3(.11, .028, .002), CREAM, MATTE)
	for k in 2:
		var c := Vector3(-.026 + k * .052, .08 + k * .006, -.032)
		bx(c, Vector3(.05, .05, .006), "e3b866", MATTE, Vector3(0, 0, .14 * (k * 2 - 1)))
		for o in [Vector3(-.012, .012, 0), Vector3(.012, -.012, 0), Vector3(0, 0, 0)]:
			ball(c + Basis(Vector3.BACK, .14 * (k * 2 - 1)) * o + Vector3(0, 0, -.005), Vector3(.006, .006, .003), "a8743a", MATTE, Vector3.ZERO, 4)

func _snack(v: int) -> void:
	var bag := pick(v, ["f9a825", "c62828", "43a047", "8e24aa"])
	ball(Vector3(0, .11, 0), Vector3(.15, .2, .07), bag, SATIN, Vector3.ZERO, 10)
	for y in [.012, .21]:
		bx(Vector3(0, y, 0), Vector3(.15, .022, .02), SILVER, METAL)
	dome(Vector3(0, .15, -.03), Vector3(.08, .01, .04), WHITE, SATIN, Vector3(-PI / 2, 0, 0), 8)
	ball(Vector3(-.01, .085, -.034), Vector3(.05, .035, .008), "f2c94c", SATIN, Vector3(0, 0, .5), 7)
	ball(Vector3(.022, .07, -.032), Vector3(.04, .03, .008), "e0b23a", SATIN, Vector3(0, 0, -.4), 7)

func _chocolate(v: int) -> void:
	# A chunky bar standing up, its wrapper torn back to show soft squares of chocolate.
	var wrap := pick(v, ["6d2c91", "c62828", "1565c0"])
	soft_box(Vector3(0, .066, .003), Vector3(.074, .128, .016), "5d3a1a", MATTE, Vector3.ZERO, .5)
	for i in 2:
		for j in 2:
			bx(Vector3(-.017 + i * .034, .096 + j * .024, -.006), Vector3(.028, .019, .006), "6e4526", MATTE)
	soft_box(Vector3(0, .042, .003), Vector3(.08, .084, .024), wrap, SATIN, Vector3.ZERO, .35)
	bx(Vector3(0, .085, .003), Vector3(.081, .008, .025), "d9dde0", METAL)
	bx(Vector3(0, .042, -.0095), Vector3(.052, .024, .003), GOLD, METAL)

func _candy(v: int) -> void:
	var tint := pick(v, ["ec407a", "fdd835", "26c6da", "ab47bc"])
	if v % 2 == 0:
		# A swirl lollipop standing in a gumdrop base.
		lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.024, 0), Vector2(.026, .006), Vector2(.017, .021), Vector2(0, .025)], lighter(tint, .3), SATIN, 10)
		cyl(Vector3(0, .045, 0), Vector3(.007, .05, .007), WHITE, MATTE, Vector3.ZERO, 6)
		lathe(Vector3(0, .092, 0), [Vector2(0, -.011), Vector2(.031, -.011), Vector2(.037, -.006), Vector2(.038, 0), Vector2(.037, .006), Vector2(.031, .011), Vector2(0, .011)], tint, SATIN, 14, Vector3(PI / 2, 0, 0))
		var spiral := []
		var radii := []
		for k in 11:
			var a := k * .78
			var rr := .004 + k * .0027
			spiral.append(Vector3(cos(a) * rr, .092 + sin(a) * rr, -.0115))
			radii.append(.0034)
		tube(spiral, radii, WHITE, SATIN, 5, Vector3.BACK)
	else:
		# A wrapped sweet lying down: a fat round candy with twisted paper ends.
		ball(Vector3(0, .026, 0), Vector3(.064, .052, .052), tint, SATIN, Vector3.ZERO, 12)
		for side in [-1, 1]:
			cyl(Vector3(side * .045, .026, 0), Vector3(.034, .028, .034), lighter(tint, .25), SATIN, Vector3(0, 0, side * PI / 2), 6, .25)
		ring(Vector3(0, .026, 0), Vector3(.054, .014, .054), WHITE, SATIN, Vector3(0, 0, PI / 2), .8, 10)
		ball(Vector3(-.01, .042, -.014), Vector3(.018, .01, .012), lighter(tint, .45), SATIN, Vector3.ZERO, 6)

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
	# A two-cup pack (18 Nov 2026): plump white cups on a card base, a fruit band, a fruit
	# picture on a white label and a foil lid with a pull tab.
	var fruit := pick(v, ["e91e63", "f9a825", "5e35b1"])
	soft_box(Vector3(0, .009, 0), Vector3(.172, .018, .088), CREAM, MATTE, Vector3.ZERO, .4)
	for side in [-1, 1]:
		var at := Vector3(side * .043, .004, 0)
		lathe(at, [Vector2(0, 0), Vector2(.03, 0), Vector2(.032, .004), Vector2(.04, .07), Vector2(.043, .073), Vector2(.043, .077), Vector2(0, .077)], WHITE, SATIN, 10)
		lathe(at, [Vector2(.0345, .02), Vector2(.0398, .062)], fruit, SATIN, 10)
		lathe(at, [Vector2(0, .078), Vector2(.045, .078), Vector2(.046, .082), Vector2(0, .083)], "d0d6da", METAL, 10)
		soft_box(at + Vector3(side * .036, .081, -.03), Vector3(.02, .004, .016), "d0d6da", METAL, Vector3(0, side * .8, 0), .5)
		ball(at + Vector3(0, .042, -.0385), Vector3(.034, .03, .006), WHITE, MATTE, Vector3.ZERO, 10)
		match v:
			0:
				ball(at + Vector3(0, .039, -.042), Vector3(.016, .019, .005), "d7263d", SATIN, Vector3.ZERO, 6)
				ball(at + Vector3(0, .05, -.042), Vector3(.014, .005, .004), "3f8d3a", MATTE, Vector3.ZERO, 5)
			1:
				tube([at + Vector3(-.012, .048, -.042), at + Vector3(-.002, .036, -.043), at + Vector3(.012, .044, -.042)], [.004, .006, .004], "f6c932", SATIN, 5)
			_:
				for o in [Vector3(-.006, .046, 0), Vector3(.006, .046, 0), Vector3(0, .036, 0)]:
					ball(at + o + Vector3(0, 0, -.042), Vector3(.011, .011, .005), "4a2f8f", SATIN, Vector3.ZERO, 5)

func _butter(_v: int) -> void:
	# A chunky butter block half unwrapped: bare butter on the left, gold foil and a label on the right.
	soft_box(Vector3(-.026, .029, 0), Vector3(.088, .056, .068), "f7dc6f", SATIN, Vector3.ZERO, .5)
	soft_box(Vector3(.034, .031, 0), Vector3(.072, .062, .074), "d9a640", METAL, Vector3.ZERO, .4)
	soft_box(Vector3(-.002, .031, 0), Vector3(.01, .066, .078), "ecc56a", METAL, Vector3.ZERO, .4)
	soft_box(Vector3(.036, .033, -.037), Vector3(.052, .034, .004), CREAM, MATTE, Vector3.ZERO, .4)
	soft_box(Vector3(.036, .033, -.0395), Vector3(.032, .01, .002), NAVY, MATTE, Vector3.ZERO, .4)
	tube(arc(Vector3(-.03, .061, 0), Vector2(.014, .012), -1.8, 1.8, 6), [.004, .006, .007, .007, .006, .004], "fbe9a0", SATIN, 6)

func _cheese(v: int) -> void:
	# A fat wedge of cheese: holey Swiss (v0), or cheddar with a red wax rind (v1).
	var top := .08
	var a := Vector3(-.075, 0, .03)
	var b := Vector3(.072, 0, -.05)
	var c := Vector3(.072, 0, .055)
	var face := pick(v, ["f4c64e", "f2a33a"])
	var rind := pick(v, ["e3a13a", "c62828"])
	var lift := Vector3(0, top, 0)
	tri(a + lift, b + lift, c + lift, face, SATIN, Vector3.UP)
	tri(a, b, c, darker(face, .1), SATIN, Vector3.DOWN)
	for side in [[a, b, face], [a, c, face], [b, c, rind]]:
		var p: Vector3 = side[0]
		var q: Vector3 = side[1]
		var out := (q - p).cross(Vector3.UP).normalized()
		if out.dot((p + q) * .5 - (a + b + c) / 3.0) < 0.0:
			out = -out
		tri(p, q, q + lift, darker(side[2], .04), SATIN, out)
		tri(p, q + lift, p + lift, darker(side[2], .04), SATIN, out)
	if v == 1:
		# The wax rind wraps over the top edge at the back.
		soft_box(Vector3(.069, top - .002, .002), Vector3(.012, .008, .106), rind, SATIN, Vector3.ZERO, .5)
		return
	# Holes: dents on the top and on the front face.
	for o in [Vector3(.02, top, -.01), Vector3(-.02, top, .012), Vector3(.048, top, .02)]:
		cyl(o + Vector3(0, .001, 0), Vector3(.022 if o.x > 0 else .016, .003, .022 if o.x > 0 else .016), "d9a032", MATTE, Vector3.ZERO, 8)
	var front := (b - a).cross(Vector3.UP).normalized()
	if front.z > 0.0:
		front = -front
	var yaw := atan2(front.x, front.z)
	for k in 3:
		var t: float = [.35, .62, .82][k]
		var at: Vector3 = a.lerp(b, t) + Vector3(0, [.045, .028, .055][k], 0) + front * .002
		ball(at, Vector3([.024, .018, .014][k], [.024, .018, .014][k], .006), "d9a032", MATTE, Vector3(0, yaw, 0), 8)

func _eggs(v: int) -> void:
	# An open egg carton (18 Nov 2026): soft pulp base, six big eggs, the lid open behind.
	var tray := "d8cbb0" if v == 0 else "9fb7c4"
	var shell := "f5efe1" if v == 0 else "e8c9a0"
	soft_box(Vector3(0, .02, 0), Vector3(.2, .04, .11), tray, MATTE, Vector3.ZERO, .5)
	for i in 3:
		for j in 2:
			lathe(Vector3(-.062 + i * .062, .02, -.026 + j * .052), [Vector2(0, 0), Vector2(.016, .003), Vector2(.024, .016), Vector2(.025, .03), Vector2(.02, .046), Vector2(.011, .056), Vector2(0, .059)], shell, SATIN, 8)
	soft_box(Vector3(0, .09, .07), Vector3(.2, .1, .014), tray, MATTE, Vector3(.3, 0, 0), .5)
	soft_box(Vector3(0, .022, -.0555), Vector3(.09, .022, .004), "f2c230", MATTE, Vector3.ZERO, .4)
	ball(Vector3(0, .022, -.058), Vector3(.014, .017, .004), WHITE, SATIN, Vector3.ZERO, 6)

## Shallow tray for deli and meat goods (white for poultry and ham, dark for red meat).
func _tray(tint: String, size := Vector2(.17, .13)) -> void:
	bx(Vector3(0, .008, 0), Vector3(size.x, .016, size.y), tint, SATIN)
	bx(Vector3(-size.x * .3, .017, -size.y * .5 + .012), Vector3(.04, .003, .018), "7cb342", MATTE)

func _ham(_v: int) -> void:
	# A cured ham leg on a wooden board, turned so its pink cut face (ringed with fat) looks to
	# the front-left; a bone knob at the narrow end.
	soft_box(Vector3(0, .006, 0), Vector3(.23, .012, .14), "c9a477", MATTE, Vector3.ZERO, .6)
	var turn := Basis(Vector3.UP, -.5)
	var body := []
	for p in [Vector3(-.08, .052, 0), Vector3(-.05, .055, 0), Vector3(-.01, .052, 0), Vector3(.03, .045, 0), Vector3(.06, .037, 0), Vector3(.08, .032, 0)]:
		body.append(turn * p)
	tube(body, [Vector2(.04, .039), Vector2(.044, .043), Vector2(.04, .04), Vector2(.03, .031), Vector2(.019, .02), Vector2(.012, .013)], "d8786b", SATIN, 12)
	cyl(turn * Vector3(-.086, .052, 0), Vector3(.07, .006, .066), "f6e3cf", MATTE, Vector3(0, -.5, PI / 2), 12)
	cyl(turn * Vector3(-.0895, .052, 0), Vector3(.056, .004, .052), "ee9aa0", SATIN, Vector3(0, -.5, PI / 2), 12)
	tube([turn * Vector3(.08, .032, 0), turn * Vector3(.112, .03, 0)], [.011, .011], "f8f1e2", MATTE, 6)
	for dz in [-.011, .011]:
		ball(turn * Vector3(.118, .03, dz), Vector3(.024, .024, .024), "f8f1e2", MATTE, Vector3.ZERO, 8)
	ball(turn * Vector3(-.03, .088, -.014), Vector3(.05, .012, .03), "eba293", SATIN, Vector3(0, -.5, 0), 8)
	ball(turn * Vector3(-.02, .08, .02), Vector3(.07, .016, .04), "b8584a", SATIN, Vector3(0, -.5, 0), 8)

func _sausage(_v: int) -> void:
	# Three plump linked sausages in a wavy chain on a white tray.
	_tray(TRAY, Vector2(.22, .12))
	var centres := [Vector3(-.068, .032, .014), Vector3(0, .032, -.012), Vector3(.068, .032, .014)]
	for k in 3:
		var dir: Vector3 = (centres[mini(k + 1, 2)] - centres[maxi(k - 1, 0)]).normalized()
		var c: Vector3 = centres[k]
		tube([c - dir * .03, c - dir * .015, c, c + dir * .015, c + dir * .03], [.012, .019, .02, .019, .012], "c06a3e" if k != 1 else "b05f36", SATIN, 10)
		ball(c + Vector3(-.006, .014, -.008), Vector3(.03, .006, .01), "dc8d62", SATIN, Vector3(0, -dir.z * 2.0, 0), 6)
	for k in 2:
		ball((centres[k] + centres[k + 1]) * .5, Vector3(.012, .012, .012), "8e4526", SATIN, Vector3.ZERO, 6)

func _chicken(v: int) -> void:
	if v == 0:
		# A whole raw chicken on a white tray: plump body, tucked wings, two drumsticks with bones.
		soft_box(Vector3(0, .006, 0), Vector3(.2, .012, .15), TRAY, SATIN, Vector3.ZERO, .6)
		ball(Vector3(-.005, .05, 0), Vector3(.15, .085, .12), "eebd85", SATIN, Vector3.ZERO, 12)
		ball(Vector3(-.02, .073, -.012), Vector3(.09, .036, .07), "f5d3a6", SATIN, Vector3.ZERO, 10)
		for side in [-1, 1]:
			tube([Vector3(.035, .055, side * .038), Vector3(.062, .07, side * .044), Vector3(.083, .08, side * .044)], [.024, .019, .011], "efc08d", SATIN, 8)
			ball(Vector3(.092, .083, side * .044), Vector3(.02, .02, .02), "f7f0e1", MATTE, Vector3.ZERO, 6)
			ball(Vector3(-.03, .045, side * .056), Vector3(.06, .032, .026), "eebd8a", SATIN, Vector3(0, 0, .3), 8)
	else:
		# Two big drumsticks on a white tray.
		soft_box(Vector3(0, .006, 0), Vector3(.2, .012, .14), TRAY, SATIN, Vector3.ZERO, .6)
		for k in 2:
			var z := -.032 + k * .064
			var flip := 1.0 if k == 0 else -1.0
			tube([Vector3(flip * -.06, .034, z), Vector3(flip * -.03, .036, z), Vector3(flip * .01, .032, z), Vector3(flip * .045, .028, z)], [.026, .03, .022, .01], "dfa260", SATIN, 10)
			tube([Vector3(flip * .045, .028, z), Vector3(flip * .07, .026, z)], [.006, .006], "f7f0e1", MATTE, 5)
			ball(Vector3(flip * .076, .026, z), Vector3(.018, .018, .02), "f7f0e1", MATTE, Vector3.ZERO, 6)
			ball(Vector3(flip * -.035, .056, z - .01), Vector3(.04, .01, .02), "ecbd7f", SATIN, Vector3.ZERO, 6)

func _meat(_v: int) -> void:
	# A chunky raw beef joint with a fat cap and a bone through it, on a dark tray.
	_tray(DARK_TRAY, Vector2(.2, .13))
	tube([Vector3(-.098, .045, 0), Vector3(.098, .045, 0)], [.01, .01], "f5ecd8", MATTE, 6)
	for side in [-1, 1]:
		for dz in [-.01, .01]:
			ball(Vector3(side * .104, .045, dz), Vector3(.022, .022, .022), "f5ecd8", MATTE, Vector3.ZERO, 8)
	ball(Vector3(0, .046, 0), Vector3(.15, .074, .108), "c0443c", MATTE, Vector3.ZERO, 12)
	ball(Vector3(.0, .058, .012), Vector3(.13, .062, .088), "f3dccb", MATTE, Vector3(0, 0, .05), 12)
	ball(Vector3(-.006, .05, -.012), Vector3(.13, .066, .09), "b83a35", MATTE, Vector3.ZERO, 12)
	ball(Vector3(-.03, .07, -.03), Vector3(.05, .016, .03), "d8625a", MATTE, Vector3.ZERO, 8)

func _steak(_v: int) -> void:
	# A thick T-bone steak on a dark tray: fat rim, red meat, marbling and a white T bone.
	_tray(DARK_TRAY, Vector2(.23, .16))
	lathe(Vector3(0, .016, 0), [Vector2(0, 0), Vector2(.1, 0), Vector2(.105, .012), Vector2(.1, .025), Vector2(0, .025)], "f3e2cf", MATTE, 14, Vector3.ZERO, Vector3(1, 1, .66))
	lathe(Vector3(-.006, .017, 0), [Vector2(0, 0), Vector2(.09, 0), Vector2(.093, .013), Vector2(.087, .027), Vector2(0, .028)], "b53a36", MATTE, 14, Vector3.ZERO, Vector3(1, 1, .64))
	for o in [Vector3(-.045, .046, -.02), Vector3(.05, .046, .022), Vector3(-.03, .046, .03)]:
		tube([o + Vector3(-.014, 0, -.004), o + Vector3(.014, 0, .004)], [.003, .003], "e7b9a8", MATTE, 4)
	soft_box(Vector3(.016, .047, 0), Vector3(.018, .012, .1), "f7f0e1", MATTE, Vector3.ZERO, .6)
	soft_box(Vector3(.016, .047, -.045), Vector3(.08, .012, .018), "f7f0e1", MATTE, Vector3.ZERO, .6)

func _salad(_v: int) -> void:
	ball(Vector3(0, .1, 0), Vector3(.14, .19, .055), "dceedd", SATIN, Vector3.ZERO, 10)
	for o in [Vector3(-.03, .07, 0), Vector3(.025, .09, 0), Vector3(-.01, .115, 0), Vector3(.03, .13, 0), Vector3(-.035, .135, 0)]:
		ball(o + Vector3(0, 0, -.022), Vector3(.05, .035, .012), ["7cb342", "4f8f3a", "a8d26b", "8e3b5a", "7cb342"][int(o.y * 100) % 5], SATIN, Vector3(0, 0, o.x * 12.0), 6)
	bx(Vector3(0, .19, 0), Vector3(.13, .02, .02), "2e7d32", SATIN)
	bx(Vector3(0, .04, -.026), Vector3(.08, .02, .004), WHITE, MATTE)

func _fish(v: int) -> void:
	# Clay-toy fish lying on its side on the ice (18 Nov 2026): a plump body, a pale belly,
	# a fanned tail, a back fin, a gill line and a big eye on top.
	var skin := pick(v, ["8fa9b8", "d08a7a"])
	var pts := []
	var radii := []
	for k in 9:
		var t := k / 8.0
		pts.append(Vector3(sin(t * PI) * .004, .024, lerpf(-.135, .11, t)))
		var r := .05 * pow(sin(PI * lerpf(.1, .93, t)), .7) * (1.0 - .45 * t)
		radii.append(Vector2(maxf(r, .008), maxf(r * .45, .006)))
	tube(pts, radii, skin, SATIN, 10)
	ball(Vector3(-.02, .02, -.03), Vector3(.05, .036, .17), "e6edf0", SATIN, Vector3.ZERO, 8)
	ball(Vector3(.03, .042, -.02), Vector3(.024, .006, .12), darker(skin, .22), SATIN, Vector3.ZERO, 6)
	for side in [-1, 1]:
		ball(Vector3(side * .024, .02, .142), Vector3(.034, .01, .07), darker(skin, .12), SATIN, Vector3(0, side * .55, 0), 8)
	ball(Vector3(.052, .02, -.01), Vector3(.03, .01, .09), darker(skin, .15), SATIN, Vector3.ZERO, 8)
	tube(arc(Vector3(0, .045, -.075), Vector2(.03, .012), -1.2, 1.2, 5), [.003, .003, .003, .003, .003], darker(skin, .3), MATTE, 4)
	ball(Vector3(.006, .045, -.108), Vector3(.026, .012, .026), WHITE, SATIN, Vector3.ZERO, 8)
	ball(Vector3(.006, .05, -.11), Vector3(.013, .008, .013), "1e1a18", SATIN, Vector3.ZERO, 6)

func _shrimp(_v: int) -> void:
	# Clay-toy shrimp (18 Nov 2026): a plump curled body of eight bold shell segments lying on its
	# side, a fanned tail, a round head with a black eye and two long feelers.
	var pts := arc(Vector3(0, .021, .012), Vector2(.046, .04), -2.2, 1.55, 9)
	for k in 8:
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[k + 1]
		var r := lerpf(.021, .009, k / 7.0)
		tube([a, (a + b) * .5, b], [r * .8, r, r * .8], "f28a6b" if k % 2 == 0 else "f8a98c", SATIN, 8)
	var dir: Vector3 = (pts[8] - pts[7]).normalized()
	for side in [-1, 1]:
		ball(pts[8] + dir * .02 + dir.cross(Vector3.UP) * side * .01, Vector3(.022, .008, .042), "e25a40", SATIN, Vector3(0, atan2(dir.x, dir.z) + side * .5, 0), 8)
	var head: Vector3 = pts[0]
	var back: Vector3 = (pts[0] - pts[1]).normalized()
	ball(head + back * .008, Vector3(.034, .032, .036), "f28a6b", SATIN, Vector3.ZERO, 10)
	ball(head + back * .016 + Vector3(0, .016, 0), Vector3(.011, .011, .011), "1e1a18", SATIN, Vector3.ZERO, 6)
	for side in [-1, 1]:
		var tip := head + back * .02
		tube([tip, tip + Vector3(-.025, .012, -.03 + side * .01), tip + Vector3(-.04, .01, -.065 + side * .02)], [.0028, .0022, .0016], "d9654c", MATTE, 4)

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
	# A plump soap bar with an embossed oval and a cluster of bubbles.
	var tint := pick(v, ["f8bbd0", "b3e5fc", "dcedc8"])
	soft_box(Vector3(0, .025, 0), Vector3(.1, .05, .066), tint, SATIN, Vector3.ZERO, .6)
	lathe(Vector3(0, .049, 0), [Vector2(0, 0), Vector2(.03, 0), Vector2(.032, .002), Vector2(.028, .004), Vector2(0, .004)], darker(tint, .1), SATIN, 12, Vector3.ZERO, Vector3(1, 1, .58))
	for spec in [[Vector3(.026, .064, .008), .03], [Vector3(.045, .06, -.016), .022], [Vector3(.006, .06, -.02), .017]]:
		ball(spec[0], Vector3.ONE * spec[1], lighter(tint, .5), SATIN, Vector3.ZERO, 12)
		ball(spec[0] + Vector3(-.2, .3, -.25) * spec[1], Vector3.ONE * spec[1] * .3, WHITE, MATTE, Vector3.ZERO, 6)

func _sponge(v: int) -> void:
	# A soft sponge block with a green scrub layer and bold holes.
	var body := pick(v, ["f9e04b", "f48fb1"])
	soft_box(Vector3(0, .02, 0), Vector3(.12, .04, .075), body, MATTE, Vector3.ZERO, .5)
	soft_box(Vector3(0, .048, 0), Vector3(.12, .016, .075), "2e8b3e", MATTE, Vector3.ZERO, .6)
	for o in [Vector3(-.035, .013, 0), Vector3(-.004, .024, 0), Vector3(.03, .012, 0), Vector3(.012, .029, 0), Vector3(.042, .027, 0), Vector3(-.024, .029, 0)]:
		ball(o + Vector3(0, 0, -.0375), Vector3(.011, .009, .004), darker(body, .22), MATTE, Vector3.ZERO, 6)

func _detergent(v: int) -> void:
	# A soft jug with a handle loop, a big cap and a bubbly label.
	var jug := pick(v, ["1e88e5", "ef6c00", "7e57c2"])
	soft_box(Vector3(0, .1, 0), Vector3(.14, .2, .085), jug, SATIN, Vector3.ZERO, .45)
	ring(Vector3(.03, .2, 0), Vector3(.072, .024, .062), jug, SATIN, Vector3(PI / 2, 0, 0), .5, 10)
	lathe(Vector3(-.038, .196, 0), [Vector2(0, 0), Vector2(.024, 0), Vector2(.025, .034), Vector2(.021, .039), Vector2(0, .04)], "ff7043" if v != 1 else "1e88e5", SATIN, 10)
	soft_box(Vector3(-.005, .095, -.043), Vector3(.1, .1, .004), WHITE, MATTE, Vector3.ZERO, .45)
	for spec in [[Vector3(-.022, .1, 0), .032], [Vector3(.016, .118, 0), .022], [Vector3(.018, .078, 0), .018], [Vector3(-.03, .066, 0), .012]]:
		ball(spec[0] + Vector3(0, 0, -.046), Vector3(spec[1], spec[1], .007), "8fd3f5", SATIN, Vector3.ZERO, 8)

func _toothbrush(v: int) -> void:
	# A chunky toothbrush on its card: a fat handle, a white bristle block with a blue tip.
	var handle := pick(v, ["29b6f6", "66bb6a", "ef5350"])
	soft_box(Vector3(0, .1, .007), Vector3(.064, .2, .006), "eef6fb", MATTE, Vector3.ZERO, .6)
	soft_box(Vector3(0, .186, .007), Vector3(.064, .028, .007), handle, MATTE, Vector3.ZERO, .6)
	tube([Vector3(0, .018, -.006), Vector3(.002, .06, -.007), Vector3(0, .11, -.006), Vector3(-.002, .14, -.006)], [.009, .008, .006, .006], handle, SATIN, 8)
	soft_box(Vector3(-.002, .158, -.006), Vector3(.02, .04, .012), handle, SATIN, Vector3.ZERO, .6)
	soft_box(Vector3(-.002, .16, -.016), Vector3(.016, .032, .012), WHITE, MATTE, Vector3.ZERO, .4)
	soft_box(Vector3(-.002, .17, -.0165), Vector3(.016, .012, .013), "4fc3f7", MATTE, Vector3.ZERO, .4)

func _toothpaste(v: int) -> void:
	# A plump tube lying down: round at the cap, flattened to a crimped seam, a coloured band.
	var stripe := pick(v, ["c62828", "1e88e5"])
	var pts := [Vector3(-.06, .022, 0), Vector3(-.03, .023, 0), Vector3(0, .023, 0), Vector3(.03, .02, 0), Vector3(.058, .016, 0), Vector3(.07, .014, 0)]
	tube(pts, [Vector2(.022, .021), Vector2(.024, .022), Vector2(.025, .021), Vector2(.026, .017), Vector2(.027, .009), Vector2(.027, .003)], WHITE, SATIN, 10)
	tube([Vector3(-.035, .023, 0), Vector3(-.015, .023, 0), Vector3(.005, .023, 0)], [Vector2(.0255, .0235), Vector2(.026, .0235), Vector2(.0262, .0228)], stripe, SATIN, 10)
	soft_box(Vector3(.076, .014, 0), Vector3(.012, .006, .056), WHITE, SATIN, Vector3.ZERO, .5)
	lathe(Vector3(-.07, .022, 0), [Vector2(0, 0), Vector2(.016, 0), Vector2(.017, .004), Vector2(.016, .022), Vector2(0, .023)], stripe, SATIN, 10, Vector3(0, 0, PI / 2))
	tube([Vector3(-.03, .03, -.022), Vector3(-.02, .024, -.025), Vector3(-.01, .03, -.0245), Vector3(0, .024, -.025)], [.003, .003, .003, .003], WHITE, SATIN, 4)

func _shampoo(v: int) -> void:
	# A soft oval bottle with rounded shoulders, a flip cap and a droplet on its label.
	var bottle := pick(v, ["7e57c2", "26a69a", "ec407a"])
	var squash := Vector3(1, 1, .62)
	lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.034, 0), Vector2(.04, .008), Vector2(.042, .03), Vector2(.042, .15), Vector2(.038, .172), Vector2(.026, .186), Vector2(.016, .19), Vector2(0, .19)], bottle, SATIN, 12, Vector3.ZERO, squash)
	lathe(Vector3.ZERO, [Vector2(.0428, .05), Vector2(.0428, .13)], lighter(bottle, .5), MATTE, 12, Vector3.ZERO, squash)
	lathe(Vector3(0, .188, 0), [Vector2(0, 0), Vector2(.019, 0), Vector2(.02, .03), Vector2(.016, .035), Vector2(0, .036)], WHITE, SATIN, 10, Vector3.ZERO, Vector3(1, 1, .8))
	ball(Vector3(0, .085, -.027), Vector3(.026, .028, .006), bottle, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(0, .104, -.027), Vector3(.018, .016, .005), bottle, SATIN, Vector3(PI / 2, 0, 0), 6, .0)

func _toilet_paper(_v: int) -> void:
	# Four soft rolls standing in a pack, cardboard cores showing, a blue wrap band with a label.
	for dx in [-.052, .052]:
		for dz in [-.052, .052]:
			lathe(Vector3(dx, 0, dz), [Vector2(.016, 0), Vector2(.044, 0), Vector2(.05, .006), Vector2(.05, .104), Vector2(.044, .11), Vector2(.016, .11)], "fbfbf8", MATTE, 12)
			lathe(Vector3(dx, 0, dz), [Vector2(.016, .11), Vector2(.016, .0)], "c4a27a", MATTE, 8)
	soft_box(Vector3(0, .055, 0), Vector3(.21, .045, .21), "64b5f6", SATIN, Vector3.ZERO, .4)
	soft_box(Vector3(0, .055, -.106), Vector3(.08, .03, .004), WHITE, MATTE, Vector3.ZERO, .4)
	cyl(Vector3(0, .055, -.109), Vector3(.02, .004, .02), "64b5f6", MATTE, Vector3(PI / 2, 0, 0), 8)

# ---------------------------------------------------------------------------------------------
# Bakery

func _bread(v: int) -> void:
	var crust := pick(v, ["c58a4a", "a8683a", "d9a566"])
	if v == 1:
		# Round country boule with a cross cut over the dome.
		lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.075, 0), Vector2(.09, .015), Vector2(.094, .045), Vector2(.08, .08), Vector2(.05, .1), Vector2(0, .108)], crust, MATTE, 14)
		for k in 2:
			var pts := []
			var heights := [.091, .105, .11, .105, .091]
			for i in 5:
				pts.append(Basis(Vector3.UP, PI / 4 + k * PI / 2) * Vector3(-.068 + i * .034, heights[i], 0))
			tube(pts, [.006, .007, .007, .007, .006], lighter(crust, .4), MATTE, 5)
		return
	# Tin loaf (v0) or a long bloomer (v2): a soft block, a domed top and three bold slashes.
	var length := .2 if v == 0 else .21
	soft_box(Vector3(0, .035, 0), Vector3(length, .07, .12), darker(crust, .06), MATTE, Vector3.ZERO, .55)
	ball(Vector3(0, .07, 0), Vector3(length, .1, .12), crust, MATTE, Vector3.ZERO, 12)
	for k in 3:
		var x := (k - 1) * .055
		var top := .07 + .05 * sqrt(maxf(0.0, 1.0 - pow(x / (length * .5), 2.0)))
		tube([Vector3(x - .012, top - .009, -.032), Vector3(x, top + .001, 0), Vector3(x + .012, top - .009, .032)], [.006, .007, .006], lighter(crust, .38), MATTE, 5)

func _baguette(_v: int) -> void:
	# A long golden tube with tapered ends and five diagonal slashes (clay-toy, 18 Nov 2026).
	var pts := []
	var radii := []
	for k in 9:
		var t := k / 8.0
		pts.append(Vector3(lerpf(-.22, .22, t), .028, sin(t * PI) * .01))
		var r := .028 * pow(sin(lerpf(.1, .9, t) * PI), .35)
		radii.append(Vector2(r, r * .95))
	tube(pts, radii, "d39b55", MATTE, 10)
	for k in 5:
		var x := -.16 + k * .08
		tube([Vector3(x - .02, .053, .01), Vector3(x + .02, .054, -.006)], [.006, .006], "f0cf93", MATTE, 5)

func _croissant(_v: int) -> void:
	# A plump crescent of rolled layers (clay-toy, 18 Nov 2026): one bumpy tube, fat in the
	# middle and tapering to darker tips, glazed.
	var pts := arc(Vector3(0, .034, .03), Vector2(.075, .06), -1.35, 1.35, 11)
	var radii := []
	for k in 11:
		var t := absf(k - 5) / 5.0
		var r := lerpf(.037, .012, pow(t, 1.3)) * (1.1 if k % 2 == 0 else .88)
		radii.append(Vector2(r, r * .95))
	tube(pts, radii, "d9953f", SATIN, 10)
	for e in [0, 10]:
		ball(pts[e], Vector3(.024, .022, .024), "b8742c", SATIN, Vector3.ZERO, 8)
	ball(Vector3(-.004, .066, -.03), Vector3(.05, .008, .02), "efc06e", SATIN, Vector3.ZERO, 8)

func _cake(v: int) -> void:
	# Clay-toy cake (18 Nov 2026): soft two-layer cake on a plate, icing that drips over the edge,
	# cream dollops and a cherry.
	var sponge := pick(v, ["f8e1e7", "fff3e0", "8d6e63"])
	var icing := pick(v, ["f48fb1", WHITE, "6d4c41"])
	lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.136, 0), Vector2(.142, .006), Vector2(.136, .01), Vector2(0, .01)], "fafafa", SATIN, 16)
	lathe(Vector3.ZERO, [Vector2(0, .01), Vector2(.118, .01), Vector2(.12, .016), Vector2(.12, .09), Vector2(0, .09)], sponge, MATTE, 16)
	lathe(Vector3.ZERO, [Vector2(.121, .046), Vector2(.123, .05), Vector2(.121, .055)], icing, MATTE, 16)
	lathe(Vector3.ZERO, [Vector2(.123, .082), Vector2(.126, .094), Vector2(.118, .106), Vector2(.09, .11), Vector2(0, .112)], icing, MATTE, 16)
	for k in 10:
		var a := k * TAU / 10 + .2
		ball(Vector3(cos(a) * .122, .076 - (k % 2) * .008, sin(a) * .122), Vector3(.026, .036 + (k % 2) * .014, .02), icing, MATTE, Vector3(0, -a, 0), 6)
	for k in 8:
		var a := k * TAU / 8
		ball(Vector3(cos(a) * .088, .118, sin(a) * .088), Vector3(.032, .026, .032), WHITE if v != 1 else "f48fb1", MATTE, Vector3.ZERO, 8)
	ball(Vector3(0, .126, 0), Vector3(.034, .034, .034), "c62828", SATIN, Vector3.ZERO, 10)
	cyl(Vector3(.004, .148, 0), Vector3(.005, .02, .005), STEM, MATTE, Vector3(0, 0, -.3), 4)

func _cupcake(v: int) -> void:
	# Clay-toy cupcake (18 Nov 2026): a pleated paper cup, a muffin top and a tall swirl of
	# frosting with a cherry.
	var cream := pick(v, ["fff3e0", "f8bbd0", "6d4c41"])
	var paper := pick(v, ["4fc3f7", "f48fb1", "ffd54f"])
	lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.032, 0), Vector2(.043, .045), Vector2(.046, .047), Vector2(0, .047)], paper, MATTE, 12)
	for k in 7:
		var a := -PI / 2 + (k - 3) * .38
		var d := Vector3(cos(a), 0, sin(a))
		tube([d * .0335 + Vector3(0, .004, 0), d * .0445 + Vector3(0, .043, 0)], [.0028, .0028], darker(paper, .16), MATTE, 4)
	lathe(Vector3.ZERO, [Vector2(.046, .045), Vector2(.05, .054), Vector2(.044, .062), Vector2(0, .064)], "c98d4f", MATTE, 12)
	lathe(Vector3.ZERO, [Vector2(0, .056), Vector2(.044, .059), Vector2(.048, .068), Vector2(.042, .077), Vector2(.034, .081), Vector2(.038, .087), Vector2(.031, .097),
		Vector2(.022, .101), Vector2(.024, .107), Vector2(.013, .116), Vector2(0, .122)], cream, MATTE, 12)
	ball(Vector3(0, .128, 0), Vector3(.026, .025, .026), "c62828", SATIN, Vector3.ZERO, 8)
	for o in [Vector3(-.03, .074, -.022), Vector3(.026, .084, -.018), Vector3(-.006, .1, -.022), Vector3(.034, .07, .01)]:
		soft_box(o, Vector3(.012, .005, .005), ["fdd835", "4fc3f7", "ef5350", "66bb6a"][int(absf(o.x) * 1000) % 4], SATIN, Vector3(0, o.x * 40.0, 0), .5)

func _donut(v: int) -> void:
	# Clay-toy donut (18 Nov 2026): a fat ring, thick icing with soft drips and bold sprinkles.
	var icing := pick(v, ["f48fb1", "6d4c41", "fff3e0"])
	ring(Vector3(0, .022, 0), Vector3(.116, .044, .116), "d08a45", MATTE, Vector3.ZERO, .34, 14)
	ring(Vector3(0, .034, 0), Vector3(.108, .026, .108), icing, MATTE, Vector3.ZERO, .4, 14)
	for k in 5:
		var a := k * TAU / 5 + .5
		ball(Vector3(cos(a) * .05, .03, sin(a) * .05), Vector3(.022, .024, .016), icing, MATTE, Vector3(0, -a, 0), 6)
	var sprinkles := ["fdd835", "4fc3f7", "ef5350", "66bb6a", WHITE]
	for k in 7:
		var a := k * TAU / 7 + .3
		var rr := .033 if k % 2 else .041
		soft_box(Vector3(cos(a) * rr, .047, sin(a) * rr), Vector3(.014, .005, .005), sprinkles[k % 5], SATIN, Vector3(0, a * 2.3, 0), .6)

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
