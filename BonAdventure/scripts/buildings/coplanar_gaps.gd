extends RefCounted
## Town-wide z-fighting fix (10 Nov 2026, user request; docs/guides/TOWN_DESIGN_BRIEF.md
## "Coplanar faces across the town"). Two visible faces of different looks that lie in one plane,
## face the same way and overlap flicker: the depth test cannot pick one, so the colour swaps
## from pixel to pixel as the camera moves (the supermarket fridge backs and the Alta Cocina
## windows, 8 Nov). This finds every such pair in the whole loaded town and separates them by
## STEP: within each group of fighting faces the largest face stays where it is and each smaller
## face stands STEP further out (a box face grows outward, a label, sprite or plane moves along
## its normal). Only nodes the unit saves are changed: a face built at runtime or inside a prefab
## instance stays, and the larger face it fights recedes STEP instead. Collision is untouched.
##
## Used by each unit's `coplanar_gaps` step (scripts/buildings/<unit>.gd):
##   preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "<unit>")
## The plan is made once per loaded town, from the state before any unit's step ran, and each
## unit then applies its own share, so a single bake of every unit gives one consistent result.
## docs/evidence/coplanar-scan-20261110/scan.gd reports the pairs (`pairs()`) without changing anything.
## Faces come from BoxMesh, CylinderMesh caps, PlaneMesh, QuadMesh, Label3D and Sprite3D; other
## meshes (spheres, tori, generated ArrayMeshes) are not checked.

const PLANE_TOL := .001        # world metres: faces closer than this share a plane
const MIN_AREA := .0004        # world m² (2 × 2 cm) of overlap
const STEP := .005             # world metres between separated faces
const NUDGE := .003            # covered-test offset off the face
const CELL := 2.0
const CAP_SIDES := 12

## Approved exact dimensions (docs/evidence/town-checks/check_building_access.gd, TOWN_DESIGN_BRIEF.md): never resized;
## the faces they fight move instead.
const PROTECTED := [
	"RelocatedSites/Supermarket/Expanded foundation", "RelocatedSites/Supermarket/Supermarket left wall",
	"RelocatedSites/Supermarket/Supermarket right wall", "RelocatedSites/Supermarket/Supermarket back wall",
	"RelocatedSites/Supermarket/Supermarket front pier", "RelocatedSites/Supermarket/Supermarket front pier2",
	"RelocatedSites/Supermarket/Supermarket roof", "Buildings/School/ApprovedShell/Floor", "Buildings/School/MainRoof",
]

static var _plans := {}   # town instance id -> plan Dictionary

## Each face: [normal, plane distance, polygon (world points), look key, node, kind, axis,
## sign, face area]; kind is "box" (axis/sign name the face), "cap" or "flat".
var faces := []
var solids := {}
var town: Node3D
var unit_roots := {}
var census := {}
## Signs are saved in English and translated at load, so a label's text can be wider in play
## than in the bake: with wide_labels a label counts as WIDE_LABEL times its baked size.
var wide_labels := false
const WIDE_LABEL := Vector2(1.8, 1.2)

## Applies the unit's share of the town-wide plan; returns a short report. Pass 2 (step
## `coplanar_gaps_2`) plans again after every unit's first pass: it catches faces that a first
## move brought into a new plane and widens labels for translated text (WIDE_LABEL).
static func separate(town_root: Node3D, unit: String, pass_no := 1) -> Dictionary:
	var id := str(town_root.get_instance_id()) + ":" + str(pass_no)
	if not _plans.has(id):
		var finder = load("res://scripts/buildings/coplanar_gaps.gd").new()
		finder.wide_labels = pass_no >= 2
		_plans[id] = finder.plan(town_root)
	var plan: Dictionary = _plans[id]
	var moved := 0
	var by_face: Dictionary = plan.offsets
	for f in by_face:
		var face: Array = f
		if plan.unit_of[face[4]] != unit:
			continue
		_push(face, by_face[f])
		moved += 1
	# A first pass that moved faces makes any second-pass plan stale (in a bake of several units
	# one unit's first pass can run after another unit's second pass; 10 Nov 2026 the hospital and
	# mystery units got both moves on top of each other that way; the hospital was rebaked alone).
	if pass_no == 1 and moved > 0:
		_plans.erase(str(town_root.get_instance_id()) + ":2")
	var report := {"faces moved": moved}
	print("COPLANAR GAPS %s pass %d: %d faces moved" % [unit, pass_no, moved])
	return report

## Town-wide plan: {offsets: {face: world metres outward}, unit_of: {node: unit},
## pairs: Array, unfixed: Array}.
func plan(town_root: Node3D) -> Dictionary:
	var rows := pairs(town_root)
	var unit_by_node := {}
	var graph := {}
	for r in rows:
		for f in [r[1], r[2]]:
			if not graph.has(f):
				graph[f] = []
			unit_by_node[f[4]] = unit_of(f[4])
		graph[r[1]].append(r[2])
		graph[r[2]].append(r[1])
	# Largest face first; each face stands one STEP in front of every larger face it fights.
	var order: Array = graph.keys()
	order.sort_custom(func(a, b): return a[8] > b[8])
	var level := {}
	for f in order:
		var top := -1
		for n in graph[f]:
			if level.has(n):
				top = maxi(top, level[n])
		level[f] = top + 1
	var offsets := {}
	for f in order:
		if movable(f[4]) and level[f] > 0:
			offsets[f] = level[f] * STEP
	# A face that cannot move keeps its plane; larger movable faces it fights recede behind it.
	for f in order:
		if movable(f[4]) or level[f] == 0:
			continue
		for n in graph[f]:
			if level[n] < level[f] and movable(n[4]) and n[5] != "flat":
				offsets[n] = minf(offsets.get(n, 0.0), -STEP)
	var unfixed := []
	for r in rows:
		if absf(offsets.get(r[1], 0.0) - offsets.get(r[2], 0.0)) < STEP * .5:
			unfixed.append(r)
	print("COPLANAR GAPS plan: %d pairs, %d faces to move, %d pairs left (runtime or prefab on both sides)" \
		% [rows.size(), offsets.size(), unfixed.size()])
	return {"offsets": offsets, "unit_of": unit_by_node, "pairs": rows, "unfixed": unfixed}

## A node the unit scene saves: a plain node, or a part of a building prefab placed in the town
## (scenes/buildings/, e.g. the hospital; saved as an instance override, as the hospital steps
## do). Nodes built at runtime and the insides of vehicles, characters, animals and props stay.
func movable(node: Node) -> bool:
	for path in PROTECTED:
		var kept := town.get_node_or_null(path)
		if kept != null and (kept == node or kept.is_ancestor_of(node)):
			return false
	if node.owner == town:
		return true
	var prefab := node.owner
	return prefab != null and prefab.owner == town and prefab.scene_file_path.begins_with("res://scenes/buildings/")

static var _resized := {}   # [mesh, axis, new size] -> resized copy, so equal boxes share

## Moves a face `amount` world metres outward (negative: inward). A box or cylinder gets a resized
## copy of its mesh and moves by half the amount, so its other faces stay put; its children
## (collision, labels) move with it by at most STEP / 2. Planes, labels and sprites move whole.
static func _push(face: Array, amount: float) -> void:
	var node: Node3D = face[4]
	if face[5] == "flat":
		node.global_position += (face[0] as Vector3) * amount
		return
	var mi := node as MeshInstance3D
	var axis: int = face[6]
	var side: float = face[7]
	var scale: float = mi.global_transform.basis[axis].length()
	var local := amount / scale
	var size: float = (mi.mesh as BoxMesh).size[axis] if mi.mesh is BoxMesh else (mi.mesh as CylinderMesh).height
	var key := [mi.mesh, axis, snappedf(size + local, .00001)]
	if not _resized.has(key):
		var copy: PrimitiveMesh = mi.mesh.duplicate()
		if copy is BoxMesh:
			var v: Vector3 = (copy as BoxMesh).size
			v[axis] = size + local
			(copy as BoxMesh).size = v
		else:
			(copy as CylinderMesh).height = size + local
		_resized[key] = copy
	mi.mesh = _resized[key]
	var offset := Vector3.ZERO
	offset[axis] = side * local * .5
	mi.transform = mi.transform * Transform3D(Basis.IDENTITY, offset)

## Visible pairs of fighting faces in the loaded town, largest visible overlap first:
## [visible m², face a, face b, share of sample points not covered by another solid].
func pairs(town_root: Node3D) -> Array:
	town = town_root
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))
	for unit in registry["units"]:
		for part in registry["units"][unit]["parts"]:
			var n := town.get_node_or_null(NodePath(part))
			if n != null:
				unit_roots[n] = unit
	collect(town)
	var buckets := {}
	for i in faces.size():
		var f: Array = faces[i]
		var n: Vector3 = f[0]
		var key := "%d,%d,%d|%d" % [roundi(n.x * 200), roundi(n.y * 200), roundi(n.z * 200),
			floori(f[1] / (PLANE_TOL * 2))]
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(i)
	var rows := []
	for key in buckets:
		var parts: PackedStringArray = key.split("|")
		var mine: Array = buckets[key]
		var other: Array = buckets.get(parts[0] + "|" + str(int(parts[1]) + 1), [])
		var n: Vector3 = faces[mine[0]][0]
		var u := n.cross(Vector3.UP if absf(n.y) < .9 else Vector3.RIGHT).normalized()
		var v := n.cross(u)
		var flats := {}
		var rects := {}
		for i in mine + other:
			flats[i] = flat(faces[i][2], u, v)
			var r := Rect2(flats[i][0], Vector2.ZERO)
			for p in flats[i]:
				r = r.expand(p)
			rects[i] = r
		for ai in mine.size():
			var a: int = mine[ai]
			for b in mine.slice(ai + 1) + other:
				var fa: Array = faces[a]
				var fb: Array = faces[b]
				# Two labels: only glyph pixels draw (the rest is cut away), so overlapping label
				# rectangles are not a fight worth moving for.
				if fa[4] is Label3D and fb[4] is Label3D:
					continue
				if fa[4] == fb[4] or fa[3] == fb[3] or absf(fa[1] - fb[1]) > PLANE_TOL \
						or fa[0].dot(fb[0]) < .9995 or not (rects[a] as Rect2).intersects(rects[b]):
					continue
				var ov := overlap(flats[a], flats[b], fa[0], fa[1], u, v)
				if ov[0] >= MIN_AREA and ov[1] > 0.0:
					rows.append([ov[0] * ov[1], fa, fb, ov[1]])
	rows.sort_custom(func(x, y): return x[0] > y[0])
	return rows

func unit_of(node: Node) -> String:
	var n := node
	while n != null and n != town:
		if unit_roots.has(n):
			return unit_roots[n]
		n = n.get_parent()
	return "base"

func material_key(mat: Material) -> String:
	if mat is BaseMaterial3D:
		var m := mat as BaseMaterial3D
		var tex := m.albedo_texture
		return m.albedo_color.to_html(true) + "|" + (str(tex.get_rid().get_id()) if tex else "") \
			+ "|" + str(m.emission_enabled and m.emission != Color.BLACK)
	if mat is ShaderMaterial:
		return "shader:" + str(mat.get_instance_id())
	return "none"

func mesh_key(mi: MeshInstance3D) -> String:
	var mat := mi.material_override
	if mat == null and mi.mesh.get_surface_count() > 0:
		mat = mi.get_surface_override_material(0)
		if mat == null:
			mat = mi.mesh.surface_get_material(0)
	return material_key(mat)

func add_face(normal: Vector3, poly: Array, key: String, node: Node, kind: String, axis := -1, side := 0.0) -> void:
	normal = normal.normalized()
	var c := Vector3.ZERO
	for p in poly:
		c += p
	c /= poly.size()
	var u := normal.cross(Vector3.UP if absf(normal.y) < .9 else Vector3.RIGHT).normalized()
	faces.append([normal, normal.dot(c), poly, key, node, kind, axis, side,
		absf(area(flat(poly, u, normal.cross(u))))])

func add_box(xf: Transform3D, size: Vector3, key: String, node: Node) -> void:
	for i in 3:
		var j := (i + 1) % 3
		var k := (i + 2) % 3
		var ai: Vector3 = xf.basis[i]
		var aj: Vector3 = xf.basis[j] * size[j] * .5
		var ak: Vector3 = xf.basis[k] * size[k] * .5
		if aj.length() < 1e-5 or ak.length() < 1e-5:
			continue
		for s in [-1.0, 1.0]:
			var c: Vector3 = xf.origin + ai * size[i] * .5 * s
			add_face(ai * s, [c - aj - ak, c + aj - ak, c + aj + ak, c - aj + ak], key, node, "box", i, s)

func add_flat(xf: Transform3D, u: Vector3, v: Vector3, half: Vector2, normal: Vector3, key: String, node: Node, both := false) -> void:
	var c := xf.origin
	var a := xf.basis * (u * half.x)
	var b := xf.basis * (v * half.y)
	var poly := [c - a - b, c + a - b, c + a + b, c - a + b]
	add_face(xf.basis * normal, poly, key, node, "flat")
	if both:
		add_face(-(xf.basis * normal), poly, key, node, "flat")

func disc(xf: Transform3D, y: float, r: float) -> Array:
	var pts := []
	for i in CAP_SIDES:
		var a := TAU * i / CAP_SIDES
		pts.append(xf * Vector3(cos(a) * r, y, sin(a) * r))
	return pts

func collect(node: Node) -> void:
	if node.name == "StaticRenderBatches":
		return   # render_culling's merged copies; the hidden originals are read instead
	for child in node.get_children():
		collect(child)
	if not node is VisualInstance3D:
		return
	var shown := (node as Node3D).is_visible_in_tree() or (node.has_meta("render_batched")
		and (node.get_parent() as Node3D).is_visible_in_tree())
	if not shown:
		return
	var gi := node as GeometryInstance3D
	if gi != null and gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		return
	census[node.get_class()] = census.get(node.get_class(), 0) + 1
	var xf: Transform3D = (node as Node3D).global_transform
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null:
			return
		var key := mesh_key(mi)
		if mesh is BoxMesh:
			add_box(xf, (mesh as BoxMesh).size, key, mi)
			if mi.transparency == 0.0:
				add_solid(xf, (mesh as BoxMesh).size, mi)
		elif mesh is QuadMesh:
			var q := mesh as QuadMesh
			add_flat(xf.translated_local(q.center_offset), Vector3.RIGHT, Vector3.UP, q.size * .5, Vector3.BACK, key, mi)
		elif mesh is PlaneMesh:
			var p := mesh as PlaneMesh
			var o := xf.translated_local(p.center_offset)
			match p.orientation:
				PlaneMesh.FACE_Y: add_flat(o, Vector3.RIGHT, Vector3.BACK, p.size * .5, Vector3.UP, key, mi)
				PlaneMesh.FACE_Z: add_flat(o, Vector3.RIGHT, Vector3.UP, p.size * .5, Vector3.BACK, key, mi)
				PlaneMesh.FACE_X: add_flat(o, Vector3.BACK, Vector3.UP, p.size * .5, Vector3.RIGHT, key, mi)
		elif mesh is CylinderMesh:
			var cy := mesh as CylinderMesh
			if cy.cap_top and cy.top_radius > .005:
				add_face(xf.basis.y, disc(xf, cy.height * .5, cy.top_radius), key, mi, "cap", 1, 1.0)
			if cy.cap_bottom and cy.bottom_radius > .005:
				add_face(-xf.basis.y, disc(xf, -cy.height * .5, cy.bottom_radius), key, mi, "cap", 1, -1.0)
	elif node is Label3D or node is Sprite3D:
		var billboard: int = (node as Label3D).billboard if node is Label3D else (node as Sprite3D).billboard
		if billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			return
		var box := (node as VisualInstance3D).get_aabb()
		if box.size.x < .001 or box.size.y < .001:
			return
		var both: bool = (node as Label3D).double_sided if node is Label3D else (node as Sprite3D).double_sided
		var half := Vector2(box.size.x, box.size.y) * .5
		if wide_labels and node is Label3D:
			half *= WIDE_LABEL
		add_flat(xf.translated_local(box.get_center()), Vector3.RIGHT, Vector3.UP, half,
			Vector3.BACK, node.get_class() + ":" + str(node.get_instance_id()), node, both)

## Opaque boxes, for the "is this face covered?" test.
func add_solid(xf: Transform3D, size: Vector3, node: MeshInstance3D) -> void:
	var mat := node.material_override as BaseMaterial3D
	if mat != null and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and mat.albedo_color.a < .95:
		return
	var box := xf * AABB(-size * .5, size)
	var entry := [xf.affine_inverse(), size * .5]
	for x in range(floori(box.position.x / CELL), floori(box.end.x / CELL) + 1):
		for y in range(floori(box.position.y / CELL), floori(box.end.y / CELL) + 1):
			for z in range(floori(box.position.z / CELL), floori(box.end.z / CELL) + 1):
				var c := Vector3i(x, y, z)
				if not solids.has(c):
					solids[c] = []
				solids[c].append(entry)

func covered(p: Vector3) -> bool:
	for e in solids.get(Vector3i(floori(p.x / CELL), floori(p.y / CELL), floori(p.z / CELL)), []):
		var q: Vector3 = e[0] * p
		var h: Vector3 = e[1]
		if absf(q.x) < h.x and absf(q.y) < h.y and absf(q.z) < h.z:
			return true
	return false

## 2D polygon in the plane's (u, v) frame, counter-clockwise.
func flat(poly: Array, u: Vector3, v: Vector3) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(Vector2(u.dot(p), v.dot(p)))
	if area(out) < 0:
		out.reverse()
	return out

func area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		a += p[i].cross(p[(i + 1) % p.size()])
	return a * .5

## [overlap area, share of sample points that another solid does not cover]
func overlap(a: PackedVector2Array, b: PackedVector2Array, n: Vector3, d: float, u: Vector3, v: Vector3) -> Array:
	var total := 0.0
	var samples := 0
	var open := 0
	for h in Geometry2D.intersect_polygons(a, b):
		total += absf(area(h))
		var c := Vector2.ZERO
		for p in h:
			c += p
		c /= h.size()
		var pts := [c]
		for p in h:
			pts.append(c.lerp(p, .8))
		for p in pts:
			var w: Vector3 = u * p.x + v * p.y + n * (d + NUDGE)
			samples += 1
			# Undersides at floor level: nobody looks up from below the ground floor.
			if n.y < -.9 and town.to_local(w).y < .12:
				continue
			if not covered(w):
				open += 1
	return [total, float(open) / maxi(samples, 1)]
