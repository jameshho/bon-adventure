extends RefCounted
## Washington monument plaza art (user reference image, 8 Nov 2026; docs/guides/public-garden/README.md,
## "Monument plaza art"). Called by base.gd steps `tulip_beds`, `plaza_fountains` and
## `bronze_statue`. Everything is built in town coordinates (+X west, +Z north) under the
## existing nodes; shapes are merged ArrayMeshes and two tulip MultiMeshes per planting.
## Positions, walks, collision bodies, word metas and the nodes the checks read are kept.

const BRONZE := Color("5d4c37")
const FOUNTAIN_STONE := Color("ddd3c1")
const CURB_STONE := Color("e2d7c4")
const SOIL := Color("4b3527")
const LEAF := Color("5fa344")
const STEM := Color("4a8a34")
## Lens-bed mix: [colour, weight]. Borders keep their own colour schemes (BORDER_TULIPS).
const TULIP_MIX := [["e1303b", 5], ["f7c531", 4], ["f283b0", 4], ["8d58c9", 3], ["f37c2a", 3], ["f4efe4", 2], ["d8357a", 2], ["f9b6cf", 2]]
const BORDER_TULIPS := {"e2b23a": "f7c531", "d9822b": "f37c2a", "e7e4d6": "f6f1e6", "d9739a": "ef7fae", "c23a3a": "e0313b"}
const STEM_HEIGHT := 0.37
const TULIP_RANGE := 120.0

## Triangle soup with explicit normals and vertex colours. `tri` orients each triangle from
## its normals (Godot front faces wind clockwise), so builders need not track winding.
class Geo:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var color := Color.WHITE

	func tri(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
		if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:
			var t := b
			b = c
			c = t
			var tn := nb
			nb = nc
			nc = tn
		verts.append(a); verts.append(b); verts.append(c)
		norms.append(na); norms.append(nb); norms.append(nc)
		cols.append(color); cols.append(color); cols.append(color)

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
		tri(a, b, c, na, nb, nc)
		tri(a, c, d, na, nc, nd)

	## Flat-shaded triangle whose normal faces `outward`.
	func flat(a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
		var n := (b - a).cross(c - a).normalized()
		if n.dot(outward) < 0.0: n = -n
		tri(a, b, c, n, n, n)

	## Tube through `points`; radii[i] = (half width along the side axis, half depth along
	## the up axis); up_hint picks the up axis (Y for bodies, X for legs). Rounded end caps.
	func loft(points: Array, radii: Array, up_hint: Vector3, segs := 12, caps := true) -> void:
		var count := points.size()
		var rings := []
		var normals := []
		for i in count:
			var t: Vector3 = (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
			var side := t.cross(up_hint)
			if side.length() < 0.05: side = t.cross(Vector3.BACK if absf(t.z) < 0.9 else Vector3.RIGHT)
			side = side.normalized()
			var up := side.cross(t).normalized()
			var r: Vector2 = radii[i]
			var ring := []
			var nring := []
			for j in segs:
				var a := TAU * j / segs
				ring.append(points[i] + side * cos(a) * r.x + up * sin(a) * r.y)
				nring.append((side * cos(a) / r.x + up * sin(a) / r.y).normalized())
			rings.append(ring)
			normals.append(nring)
		for i in count - 1:
			for j in segs:
				var k := (j + 1) % segs
				quad(rings[i][j], rings[i + 1][j], rings[i + 1][k], rings[i][k], normals[i][j], normals[i + 1][j], normals[i + 1][k], normals[i][k])
		if not caps: return
		for end in [0, count - 1]:
			var t: Vector3 = (points[mini(end + 1, count - 1)] - points[maxi(end - 1, 0)]).normalized() * (-1.0 if end == 0 else 1.0)
			var r: Vector2 = radii[end]
			var pole: Vector3 = points[end] + t * minf(r.x, r.y) * 0.8
			for j in segs:
				var k := (j + 1) % segs
				tri(rings[end][j], rings[end][k], pole, normals[end][j].lerp(t, 0.5).normalized(), normals[end][k].lerp(t, 0.5).normalized(), t)

	func ellipsoid(center: Vector3, radii: Vector3, basis := Basis(), segs := 12, rows := 7) -> void:
		var grid := []
		var ngrid := []
		for i in rows + 1:
			var phi := PI * i / rows
			var row := []
			var nrow := []
			for j in segs:
				var th := TAU * j / segs
				var unit := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
				row.append(center + basis * (unit * radii))
				nrow.append((basis * (unit / radii)).normalized())
			grid.append(row)
			ngrid.append(nrow)
		for i in rows:
			for j in segs:
				var k := (j + 1) % segs
				if i > 0: tri(grid[i][j], grid[i + 1][j], grid[i][k], ngrid[i][j], ngrid[i + 1][j], ngrid[i][k])
				if i < rows - 1: tri(grid[i][k], grid[i + 1][j], grid[i + 1][k], ngrid[i][k], ngrid[i + 1][j], ngrid[i + 1][k])

	## Surface of revolution about `center`'s vertical axis. profile = Vector2(radius, height)
	## points, traversed with the solid on the left (outer walls upward, inner walls downward).
	## smooth=false gives crisp mouldings (one normal per profile segment).
	func lathe(center: Vector3, profile: Array, segs := 28, smooth := true) -> void:
		var last := profile.size() - 1
		for i in last:
			var p0: Vector2 = profile[i]
			var p1: Vector2 = profile[i + 1]
			if p0.distance_to(p1) < 0.0001: continue
			var d0: Vector2 = (profile[mini(i + 1, last)] - profile[maxi(i - 1, 0)]) if smooth else (p1 - p0)
			var d1: Vector2 = (profile[mini(i + 2, last)] - profile[i]) if smooth else (p1 - p0)
			var n0 := Vector2(d0.y, -d0.x).normalized()
			var n1 := Vector2(d1.y, -d1.x).normalized()
			for j in segs:
				var a0 := TAU * j / segs
				var a1 := TAU * (j + 1) / segs
				var c0 := Vector3(cos(a0), 0, sin(a0))
				var c1 := Vector3(cos(a1), 0, sin(a1))
				quad(center + c0 * p0.x + Vector3.UP * p0.y, center + c0 * p1.x + Vector3.UP * p1.y,
					center + c1 * p1.x + Vector3.UP * p1.y, center + c1 * p0.x + Vector3.UP * p0.y,
					c0 * n0.x + Vector3.UP * n0.y, c0 * n1.x + Vector3.UP * n1.y,
					c1 * n1.x + Vector3.UP * n1.y, c1 * n0.x + Vector3.UP * n0.y)

	## Straight block with a chamfered cross-section `profile` (Vector2(side, up), convex,
	## any winding), extruded `length` along `tangent` from `center`.
	func block(center: Vector3, tangent: Vector3, length: float, profile: Array) -> void:
		var t := tangent.normalized()
		var side := t.cross(Vector3.UP).normalized()
		var half := t * length * 0.5
		var mid := Vector2.ZERO
		for p in profile: mid += p
		mid /= profile.size()
		var ring := []
		for p in profile: ring.append(center + side * p.x + Vector3.UP * p.y)
		for i in ring.size():
			var a: Vector3 = ring[i]
			var b: Vector3 = ring[(i + 1) % ring.size()]
			var edge: Vector2 = (profile[i] + profile[(i + 1) % ring.size()]) * 0.5 - mid
			var out := side * edge.x + Vector3.UP * edge.y
			flat(a - half, b - half, b + half, out)
			flat(a - half, b + half, a + half, out)
		var c := center + side * mid.x + Vector3.UP * mid.y
		for i in ring.size():
			var a: Vector3 = ring[i]
			var b: Vector3 = ring[(i + 1) % ring.size()]
			flat(a + half, b + half, c + half, t)
			flat(a - half, b - half, c - half, -t)

	func commit() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_COLOR] = cols
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


static func material(color: Color, roughness := 0.82, metallic := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.vertex_color_use_as_albedo = true
	result.roughness = roughness
	result.metallic = metallic
	return result


static func add_mesh(parent: Node3D, name: String, geo: Geo, mat: Material, shadows := true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = geo.commit()
	node.material_override = mat
	if not shadows: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node, true)
	return node


static func remove(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()


# --- Tulips ---------------------------------------------------------------------------

## Cup bloom, origin at its base: six pointed petal tips around a dished top.
static func bloom_mesh() -> ArrayMesh:
	var g := Geo.new()
	const SEGS := 12
	var rows := [[0.02, 0.0, 0.62], [0.072, 0.075, 0.92]]
	var rings := []
	var normals := []
	for row in rows:
		var ring := []
		var nring := []
		for j in SEGS:
			var a := TAU * j / SEGS
			ring.append(Vector3(cos(a) * row[0], row[1], sin(a) * row[0]))
			nring.append(Vector3(cos(a), 0.35 - row[1] * 3.0, sin(a)).normalized())
		rings.append(ring)
		normals.append(nring)
	var tips := []
	var ntips := []
	for j in SEGS:
		var a := TAU * j / SEGS
		var tip := j % 2 == 0
		tips.append(Vector3(cos(a) * (0.058 if tip else 0.064), 0.19 if tip else 0.148, sin(a) * (0.058 if tip else 0.064)))
		ntips.append(Vector3(cos(a), 0.15, sin(a)).normalized())
	rings.append(tips)
	normals.append(ntips)
	var shades := [0.62, 0.92, 1.0]
	for i in 2:
		for j in SEGS:
			var k := (j + 1) % SEGS
			g.color = Color(shades[i], shades[i], shades[i])
			g.quad(rings[i][j], rings[i + 1][j], rings[i + 1][k], rings[i][k], normals[i][j], normals[i + 1][j], normals[i + 1][k], normals[i][k])
	g.color = Color(0.82, 0.82, 0.82)
	var dish := Vector3(0, 0.135, 0)
	var bottom := Vector3(0, -0.01, 0)
	for j in SEGS:
		var k := (j + 1) % SEGS
		g.tri(tips[j], tips[k], dish, Vector3.UP, Vector3.UP, Vector3.UP)
		g.tri(rings[0][j], rings[0][k], bottom, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN)
	return g.commit()


## Stem and two arching lanceolate leaves, origin on the soil; both leaf faces are built.
static func foliage_mesh() -> ArrayMesh:
	var g := Geo.new()
	g.color = STEM
	var stem := []
	for j in 3:
		var a := TAU * j / 3.0
		stem.append(Vector3(cos(a), 0, sin(a)) * 0.012)
	for j in 3:
		var k := (j + 1) % 3
		var out: Vector3 = (stem[j] + stem[k]).normalized()
		g.quad(stem[j], stem[j] + Vector3.UP * (STEM_HEIGHT + 0.02), stem[k] + Vector3.UP * (STEM_HEIGHT + 0.02), stem[k], out, out, out, out)
	for leaf in [[0.0, 0.3, 0.052], [2.7, 0.24, 0.046]]:
		var dir := Vector3(cos(leaf[0]), 0, sin(leaf[0]))
		var side := dir.cross(Vector3.UP)
		var spine := []
		var widths := []
		for i in 5:
			var s := i / 4.0
			spine.append(dir * (0.015 + 0.09 * s + 0.05 * s * s) + Vector3.UP * (0.01 + leaf[1] * (s - 0.18 * s * s)))
			widths.append(leaf[2] * sin(PI * minf(0.12 + s * 0.95, 1.0)))
		for i in 4:
			g.color = LEAF.darkened(0.12 * (1.0 - i / 4.0))
			var a: Vector3 = spine[i] - side * widths[i]
			var b: Vector3 = spine[i + 1] - side * widths[i + 1]
			var c: Vector3 = spine[i + 1] + side * widths[i + 1]
			var d: Vector3 = spine[i] + side * widths[i]
			var n := (b - a).cross(d - a).normalized()
			if n.dot(dir) < 0.0: n = -n
			g.quad(a, b, c, d, n, n, n, n)
			g.quad(a, b, c, d, -n, -n, -n, -n)
	return g.commit()


static func pick_color(rng: RandomNumberGenerator) -> Color:
	var total := 0
	for entry in TULIP_MIX: total += entry[1]
	var roll := rng.randi_range(1, total)
	for entry in TULIP_MIX:
		roll -= entry[1]
		if roll <= 0: return Color(entry[0])
	return Color(TULIP_MIX[0][0])


## One planting = a foliage MultiMesh and a bloom MultiMesh (instance colours). The instance
## data is kept in baked_multimesh.gd's array (the headless bake's renderer drops it).
static func add_tulips(parent: Node3D, name: String, items: Array) -> void:
	var leaf_material := material(Color.WHITE, 0.8)
	var bloom_material := material(Color.WHITE, 0.55)
	for layer in [["leaves", foliage_mesh(), leaf_material], ["blooms", bloom_mesh(), bloom_material]]:
		var colored: bool = layer[0] == "blooms"
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = colored
		instances.mesh = layer[1]
		instances.instance_count = items.size()
		var data := PackedFloat32Array()
		var bounds := AABB()
		for i in items.size():
			var pose: Transform3D = items[i][0]
			if colored: pose = pose * Transform3D(Basis(), Vector3(0, STEM_HEIGHT, 0))
			var b := pose.basis
			data.append_array([b.x.x, b.y.x, b.z.x, pose.origin.x, b.x.y, b.y.y, b.z.y, pose.origin.y, b.x.z, b.y.z, b.z.z, pose.origin.z])
			if colored:
				var c: Color = items[i][1]
				data.append_array([c.r, c.g, c.b, c.a])
			bounds = AABB(pose.origin, Vector3.ZERO) if i == 0 else bounds.expand(pose.origin)
		var node := MultiMeshInstance3D.new()
		node.set_script(preload("res://scripts/objects/baked_multimesh.gd"))
		node.set("instance_buffer", data)
		node.name = name + " " + layer[0]
		node.multimesh = instances
		node.custom_aabb = bounds.grow(0.6)
		node.material_override = layer[2]
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = TULIP_RANGE
		node.visibility_range_end_margin = 10.0
		node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(node, true)


static func tulip_pose(rng: RandomNumberGenerator, at: Vector3, size: float) -> Transform3D:
	var basis := Basis.from_euler(Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(0, TAU), rng.randf_range(-0.12, 0.12)))
	return Transform3D(basis * Basis.from_scale(Vector3(size, size * rng.randf_range(0.9, 1.15), size)), at)


## Lens bed outline from the saved bed patch: per spine x, the edge z values and ground y.
static func bed_columns(bed: MeshInstance3D) -> Array:
	var columns := {}
	var vertices: PackedVector3Array = bed.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for v in vertices:
		var p: Vector3 = bed.transform * v
		var key := int(round(p.x * 20.0))
		if not columns.has(key): columns[key] = [INF, -INF, 0.0, 0]
		var c: Array = columns[key]
		c[0] = minf(c[0], p.z)
		c[1] = maxf(c[1], p.z)
		c[2] += p.y
		c[3] += 1
	var keys := columns.keys()
	keys.sort()
	var result := []
	for key in keys:
		var c: Array = columns[key]
		result.append({"x": key / 20.0, "zc": (c[0] + c[1]) * 0.5, "half": (c[1] - c[0]) * 0.5, "y": c[2] / c[3] - 0.055})
	return result


static func column_at(columns: Array, x: float) -> Dictionary:
	for i in range(1, columns.size()):
		if x <= columns[i].x:
			var a: Dictionary = columns[i - 1]
			var b: Dictionary = columns[i]
			var t := clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0, 1)
			return {"zc": lerpf(a.zc, b.zc, t), "half": lerpf(a.half, b.half, t), "y": lerpf(a.y, b.y, t)}
	return columns.back()


static func soil_height(column: Dictionary, u: float) -> float:
	return column.y + 0.1 + 0.1 * (1.0 - u * u) * clampf(column.half, 0.3, 1.0)


## Raised lens bed: chamfered curb stones round the outline, a domed soil bed and dense
## mixed tulips, taller toward the crown.
static func lens_bed(bed: MeshInstance3D, curb: Geo, soil: Geo, tulips: Array, rng: RandomNumberGenerator) -> void:
	var columns := bed_columns(bed)
	var loop := []
	for c in columns: loop.append(Vector2(c.x, c.zc + c.half))
	for i in range(columns.size() - 1, -1, -1): loop.append(Vector2(columns[i].x, columns[i].zc - columns[i].half))
	var polygon := PackedVector2Array(loop)
	# Resample the outline evenly, then lay one curb stone per step, pushed outward.
	var perimeter := 0.0
	for i in loop.size(): perimeter += loop[i].distance_to(loop[(i + 1) % loop.size()])
	var stones := int(perimeter / 0.45)
	var points := []
	var walked := 0.0
	var target := 0.0
	var step := perimeter / stones
	for i in loop.size():
		var a: Vector2 = loop[i]
		var b: Vector2 = loop[(i + 1) % loop.size()]
		var length := a.distance_to(b)
		while target <= walked + length and points.size() < stones:
			points.append(a.lerp(b, (target - walked) / maxf(length, 0.0001)))
			target += step
		walked += length
	var profile := [Vector2(-0.13, -0.06), Vector2(0.13, -0.06), Vector2(0.13, 0.12), Vector2(0.09, 0.17), Vector2(-0.09, 0.17), Vector2(-0.13, 0.12)]
	for i in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		var mid := (a + b) * 0.5
		var dir := (b - a).normalized()
		var normal := Vector2(dir.y, -dir.x)
		if Geometry2D.is_point_in_polygon(mid + normal * 0.05, polygon): normal = -normal
		mid += normal * 0.1
		var ground: float = column_at(columns, mid.x).y
		curb.color = CURB_STONE * rng.randf_range(0.9, 1.04)
		curb.color.a = 1.0
		curb.block(Vector3(mid.x, ground, mid.y), Vector3(dir.x, 0, dir.y), a.distance_to(b) - 0.035, profile)
	# Domed soil, one strip per outline column.
	const ACROSS := 8
	for i in columns.size() - 1:
		for k in ACROSS:
			var quad := []
			for corner in [[i, k], [i + 1, k], [i + 1, k + 1], [i, k + 1]]:
				var c: Dictionary = columns[corner[0]]
				var u: float = lerpf(-1.0, 1.0, float(corner[1]) / ACROSS)
				quad.append(Vector3(c.x, soil_height(c, u), c.zc + u * maxf(c.half - 0.04, 0.0)))
			soil.color = SOIL * rng.randf_range(0.93, 1.05)
			soil.color.a = 1.0
			soil.flat(quad[0], quad[1], quad[2], Vector3.UP)
			soil.flat(quad[0], quad[2], quad[3], Vector3.UP)
	# Tulips on a staggered grid with jitter.
	var x0: float = columns[0].x + 0.2
	var x1: float = columns.back().x - 0.2
	var row := 0
	var x := x0
	while x <= x1:
		var c := column_at(columns, x)
		var z: float = c.zc - c.half + 0.17 + (0.1 if row % 2 else 0.0)
		while z <= c.zc + c.half - 0.17:
			var px := x + rng.randf_range(-0.05, 0.05)
			var pz := z + rng.randf_range(-0.05, 0.05)
			var cc := column_at(columns, px)
			var u := clampf((pz - cc.zc) / maxf(cc.half, 0.01), -1, 1)
			var size := rng.randf_range(0.85, 1.05) * (1.0 + 0.2 * (1.0 - u * u))
			tulips.append([tulip_pose(rng, Vector3(px, soil_height(cc, u) - 0.02, pz), size), pick_color(rng)])
			z += 0.2
		x += 0.19
		row += 1


static func tulip_beds(town: Node3D) -> void:
	var garden: Node3D = town.get_node("PublicGarden")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261108
	var old := ["Entrance bedding flowers", "Elephant ear leaf", "Dark foliage", "Canna leaf", "Canna bloom", "Monument border flowers"]
	var border := []
	var beds := []
	for child in garden.get_children():
		var base := String(child.name).rstrip("0123456789")
		if base == "Entrance tapered flower bed":
			beds.append(child)
		elif base in old:
			if base == "Monument border flowers":
				var ball: MeshInstance3D = child.get_child(0)
				border.append([child.position, (ball.material_override as StandardMaterial3D).albedo_color])
			remove(child)
	var curb := Geo.new()
	var soil := Geo.new()
	var lens := []
	for bed in beds: lens_bed(bed, curb, soil, lens, rng)
	add_mesh(garden, "Tulip bed curb", curb, material(Color.WHITE, 0.88))
	add_mesh(garden, "Tulip bed soil", soil, material(Color.WHITE, 0.95), false)
	add_tulips(garden, "Lens bed tulips", lens)
	# Border flowers: two tulips per former ball, in the border's own colours.
	var rows := []
	for spot in border:
		var key: String = spot[1].to_html(false)
		var tint := Color(BORDER_TULIPS.get(key, key))
		for n in 2:
			var at: Vector3 = spot[0] + Vector3(rng.randf_range(-0.14, 0.14), -0.2, rng.randf_range(-0.14, 0.14))
			rows.append([tulip_pose(rng, at, rng.randf_range(0.78, 0.92)), tint])
	add_tulips(garden, "Border tulips", rows)
	print("Monument plaza: ", lens.size(), " lens-bed tulips, ", rows.size(), " border tulips, ", border.size(), " border balls replaced")


# --- Fountains ------------------------------------------------------------------------

## Seated child holding a bird, origin on the seat, facing +X.
static func bronze_child(g: Geo, o: Vector3) -> void:
	g.ellipsoid(o + Vector3(0, 0.1, 0), Vector3(0.13, 0.1, 0.15))
	for s in [1.0, -1.0]:
		g.loft([o + Vector3(0, 0.07, 0.08 * s), o + Vector3(0.2, 0.06, 0.2 * s)], [Vector2(0.06, 0.06), Vector2(0.055, 0.055)], Vector3.UP, 10)
		g.loft([o + Vector3(0.2, 0.06, 0.2 * s), o + Vector3(0.24, 0.045, -0.05 * s)], [Vector2(0.05, 0.05), Vector2(0.042, 0.042)], Vector3.UP, 10)
		g.ellipsoid(o + Vector3(0.27, 0.045, -0.07 * s), Vector3(0.06, 0.032, 0.035), Basis(), 10, 6)
		g.loft([o + Vector3(0.0, 0.42, 0.14 * s), o + Vector3(0.07, 0.3, 0.17 * s)], [Vector2(0.042, 0.042), Vector2(0.036, 0.036)], Vector3.UP, 10)
		g.loft([o + Vector3(0.07, 0.3, 0.17 * s), o + Vector3(0.19, 0.335, 0.05 * s)], [Vector2(0.035, 0.035), Vector2(0.03, 0.03)], Vector3.UP, 10)
		g.ellipsoid(o + Vector3(0.2, 0.34, 0.04 * s), Vector3(0.04, 0.03, 0.035), Basis(), 10, 6)
		g.ellipsoid(o + Vector3(0.0, 0.565, 0.1 * s), Vector3(0.02, 0.032, 0.015), Basis(), 8, 5)
	g.loft([o + Vector3(0, 0.12, 0), o + Vector3(0.01, 0.28, 0), o + Vector3(0, 0.4, 0), o + Vector3(0, 0.47, 0)],
		[Vector2(0.13, 0.1), Vector2(0.14, 0.1), Vector2(0.135, 0.09), Vector2(0.06, 0.05)], Vector3.RIGHT)
	g.ellipsoid(o + Vector3(0.02, 0.57, 0), Vector3(0.105, 0.115, 0.1))
	g.ellipsoid(o + Vector3(-0.01, 0.6, 0), Vector3(0.108, 0.1, 0.105))
	g.ellipsoid(o + Vector3(0.12, 0.56, 0), Vector3(0.022, 0.02, 0.018), Basis(), 8, 5)
	# The bird, beak forward.
	g.ellipsoid(o + Vector3(0.235, 0.39, 0), Vector3(0.062, 0.04, 0.038), Basis(Vector3.BACK, 0.35))
	g.ellipsoid(o + Vector3(0.285, 0.43, 0), Vector3(0.03, 0.028, 0.026), Basis(), 10, 6)
	g.loft([o + Vector3(0.31, 0.432, 0), o + Vector3(0.345, 0.426, 0)], [Vector2(0.009, 0.008), Vector2(0.002, 0.002)], Vector3.UP, 6)
	g.loft([o + Vector3(0.18, 0.37, 0), o + Vector3(0.13, 0.355, 0)], [Vector2(0.028, 0.006), Vector2(0.024, 0.005)], Vector3.UP, 8)


static func plaza_fountains(town: Node3D) -> void:
	var garden: Node3D = town.get_node("PublicGarden")
	for fountain in garden.get_children():
		if not String(fountain.name).begins_with("Monument fountain"): continue
		# Old streams and sphere figure go; the red granite parts keep their collision only.
		for child in fountain.get_children():
			var title := String(child.name)
			if title.begins_with("Falling water") or title.begins_with("Bronze figure") or title.begins_with("@"):
				remove(child)
		for part in ["Red granite base", "Red granite column", "Red granite capital", "Sculpture bowl"]:
			for child in fountain.get_node(part).get_children():
				if child is MeshInstance3D: child.hide()
		var stone := Geo.new()
		stone.lathe(Vector3.ZERO, [Vector2(0.72, 0.14), Vector2(0.72, 0.3), Vector2(0.64, 0.36), Vector2(0.52, 0.38), Vector2(0.52, 0.45), Vector2(0.4, 0.47)], 28, false)
		stone.lathe(Vector3.ZERO, [Vector2(0.4, 0.47), Vector2(0.36, 0.5), Vector2(0.33, 0.56), Vector2(0.25, 0.62), Vector2(0.3, 0.76),
			Vector2(0.315, 0.88), Vector2(0.27, 1.0), Vector2(0.18, 1.11), Vector2(0.165, 1.17), Vector2(0.22, 1.2), Vector2(0.22, 1.25),
			Vector2(0.18, 1.29), Vector2(0.26, 1.33), Vector2(0.56, 1.39), Vector2(0.92, 1.47), Vector2(1.13, 1.54), Vector2(1.21, 1.59),
			Vector2(1.23, 1.645), Vector2(1.19, 1.685), Vector2(1.12, 1.68), Vector2(1.0, 1.63), Vector2(0.6, 1.56), Vector2(0.0, 1.54)])
		# Seat stone for the figure, rising out of the bowl water.
		stone.lathe(Vector3.ZERO, [Vector2(0.3, 1.55), Vector2(0.3, 1.7), Vector2(0.27, 1.76), Vector2(0.2, 1.79), Vector2(0.0, 1.8)])
		add_mesh(fountain, "Fountain centrepiece", stone, material(FOUNTAIN_STONE, 0.85))
		var bronze := Geo.new()
		bronze_child(bronze, Vector3(-0.02, 1.79, 0))
		add_mesh(fountain, "Bronze child with bird", bronze, material(BRONZE, 0.42, 0.45))
		# Bowl water reuses the basin's rippling water material.
		var basin_water: MeshInstance3D = fountain.get_node("Fountain water").get_child(0)
		var bowl_water := MeshInstance3D.new()
		bowl_water.name = "Bowl water"
		var disc := CylinderMesh.new()
		disc.top_radius = 1.13
		disc.bottom_radius = 1.13
		disc.height = 0.012
		disc.radial_segments = 32
		disc.rings = 1
		bowl_water.mesh = disc
		bowl_water.position.y = 1.64
		bowl_water.material_override = basin_water.material_override
		bowl_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fountain.add_child(bowl_water, true)
		# Separate streams spill over the lip in arcs.
		var water := Geo.new()
		for i in 28:
			var a := TAU * (i + 0.5) / 28.0
			var out := Vector3(cos(a), 0, sin(a))
			var pts := []
			var radii := []
			for k in 7:
				var s := k / 6.0
				pts.append(out * (1.24 + 0.3 * pow(s, 0.6)) + Vector3.UP * (1.66 - 1.36 * s * s))
				radii.append(Vector2(0.036, 0.026) * (1.0 - 0.3 * s))
			water.loft(pts, radii, Vector3.UP, 6, false)
		var flow := ShaderMaterial.new()
		flow.shader = preload("res://shaders/fountain_stream.gdshader")
		add_mesh(fountain, "Falling water curtain", water, flow, false)
		# Foam ring and splash mounds where the streams land.
		var foam := Geo.new()
		foam.color = Color("f2f8fa")
		for i in 28:
			var a := TAU * (i + 0.5) / 28.0
			foam.ellipsoid(Vector3(cos(a) * 1.53, 0.31, sin(a) * 1.53), Vector3(0.11, 0.04, 0.11), Basis(), 8, 4)
		foam.lathe(Vector3.ZERO, [Vector2(1.72, 0.3), Vector2(1.6, 0.325), Vector2(1.45, 0.33), Vector2(1.36, 0.3)], 40)
		var foam_material := material(Color.WHITE, 0.35)
		foam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		foam_material.albedo_color.a = 0.85
		add_mesh(fountain, "Splash foam", foam, foam_material, false)


# --- Statue ---------------------------------------------------------------------------

## Smooth bronze horse and rider in the statue's own frame (+X = facing, pedestal top y 3.5),
## walking with the near foreleg raised as on the Boston statue.
static func horse_and_rider(g: Geo) -> void:
	var body := [[-1.38, 5.25, 0.22, 0.25], [-1.2, 5.15, 0.4, 0.45], [-0.9, 5.05, 0.5, 0.58], [-0.45, 4.98, 0.5, 0.6],
		[0.05, 4.95, 0.5, 0.6], [0.5, 4.98, 0.48, 0.6], [0.85, 5.05, 0.42, 0.56], [1.08, 5.18, 0.32, 0.45], [1.2, 5.32, 0.2, 0.28]]
	var pts := []
	var radii := []
	for b in body:
		pts.append(Vector3(b[0], b[1], 0))
		radii.append(Vector2(b[2], b[3]))
	g.loft(pts, radii, Vector3.UP, 16)
	var neck := [[0.95, 5.35, 0.3, 0.42], [1.22, 5.72, 0.24, 0.35], [1.42, 6.08, 0.18, 0.28], [1.56, 6.42, 0.15, 0.22], [1.63, 6.56, 0.14, 0.19]]
	pts = []
	radii = []
	for n in neck:
		pts.append(Vector3(n[0], n[1], 0))
		radii.append(Vector2(n[2], n[3]))
	g.loft(pts, radii, Vector3.UP, 14)
	# Mane along the crest of the neck, then a forelock.
	var mane := []
	var mane_radii := []
	for i in neck.size():
		var t: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var crest := Vector3(-t.y, t.x, 0)
		mane.append(pts[i] + crest * neck[i][3] * 0.88)
		mane_radii.append(Vector2(0.05, 0.1) * (1.0 - 0.4 * i / neck.size()))
	g.loft(mane, mane_radii, Vector3.UP, 8)
	g.loft([Vector3(1.6, 6.72, 0), Vector3(1.7, 6.68, 0), Vector3(1.78, 6.58, 0)], [Vector2(0.04, 0.03), Vector2(0.04, 0.03), Vector2(0.02, 0.015)], Vector3.UP, 8)
	g.loft([Vector3(1.58, 6.62, 0), Vector3(1.8, 6.48, 0), Vector3(2.0, 6.3, 0), Vector3(2.18, 6.13, 0), Vector3(2.3, 6.02, 0)],
		[Vector2(0.14, 0.18), Vector2(0.135, 0.17), Vector2(0.11, 0.13), Vector2(0.09, 0.105), Vector2(0.085, 0.09)], Vector3.UP, 14)
	g.ellipsoid(Vector3(1.75, 6.42, 0), Vector3(0.17, 0.15, 0.15))
	for s in [1.0, -1.0]:
		g.loft([Vector3(1.6, 6.72, 0.07 * s), Vector3(1.58, 6.86, 0.085 * s), Vector3(1.57, 6.94, 0.09 * s)], [Vector2(0.04, 0.03), Vector2(0.03, 0.022), Vector2(0.008, 0.006)], Vector3.RIGHT, 8)
		g.ellipsoid(Vector3(2.29, 6.06, 0.05 * s), Vector3(0.025, 0.02, 0.012), Basis(), 6, 4)
	# Legs: [x, y, half width, half depth] from the body down to the hoof.
	var legs := [
		[0.26, [[-0.85, 5.0, 0.2, 0.32], [-0.95, 4.55, 0.14, 0.22], [-1.05, 4.2, 0.09, 0.13], [-1.08, 4.05, 0.08, 0.1], [-1.0, 3.8, 0.06, 0.07], [-0.98, 3.64, 0.07, 0.08], [-0.95, 3.57, 0.065, 0.075], [-0.93, 3.5, 0.085, 0.1]]],
		[-0.26, [[-0.85, 5.0, 0.2, 0.32], [-0.9, 4.55, 0.14, 0.22], [-0.98, 4.2, 0.09, 0.13], [-1.0, 4.05, 0.08, 0.1], [-0.9, 3.8, 0.06, 0.07], [-0.86, 3.64, 0.07, 0.08], [-0.83, 3.57, 0.065, 0.075], [-0.81, 3.5, 0.085, 0.1]]],
		[-0.22, [[0.85, 4.95, 0.17, 0.24], [0.92, 4.5, 0.12, 0.17], [0.95, 4.1, 0.085, 0.1], [0.96, 3.95, 0.07, 0.08], [0.97, 3.66, 0.07, 0.08], [0.99, 3.58, 0.065, 0.075], [1.0, 3.5, 0.085, 0.1]]],
		[0.22, [[0.85, 4.95, 0.17, 0.24], [1.0, 4.55, 0.12, 0.16], [1.2, 4.3, 0.085, 0.1], [1.14, 4.0, 0.07, 0.08], [1.08, 3.88, 0.07, 0.08], [1.12, 3.8, 0.085, 0.1]]]]
	for leg in legs:
		pts = []
		radii = []
		for p in leg[1]:
			pts.append(Vector3(p[0], p[1], leg[0]))
			radii.append(Vector2(p[2], p[3]))
		g.loft(pts, radii, Vector3.RIGHT, 10)
	g.loft([Vector3(-1.35, 5.3, 0), Vector3(-1.5, 5.1, 0), Vector3(-1.56, 4.75, 0), Vector3(-1.52, 4.35, 0), Vector3(-1.45, 4.1, 0)],
		[Vector2(0.08, 0.09), Vector2(0.11, 0.12), Vector2(0.12, 0.12), Vector2(0.1, 0.1), Vector2(0.05, 0.05)], Vector3.RIGHT, 10)
	# Saddle and rider.
	g.ellipsoid(Vector3(0.05, 5.55, 0), Vector3(0.36, 0.09, 0.32))
	g.ellipsoid(Vector3(0.05, 5.74, 0), Vector3(0.22, 0.15, 0.22))
	g.loft([Vector3(0.02, 5.98, 0), Vector3(-0.14, 5.7, 0), Vector3(-0.3, 5.56, 0)], [Vector2(0.3, 0.22), Vector2(0.4, 0.3), Vector2(0.42, 0.28)], Vector3.RIGHT, 12)
	g.loft([Vector3(0.03, 5.8, 0), Vector3(0.02, 6.3, 0), Vector3(0.0, 6.72, 0), Vector3(0.0, 6.92, 0)],
		[Vector2(0.24, 0.17), Vector2(0.27, 0.19), Vector2(0.3, 0.17), Vector2(0.08, 0.08)], Vector3.RIGHT, 14)
	g.ellipsoid(Vector3(0.04, 7.15, 0), Vector3(0.16, 0.19, 0.15))
	g.ellipsoid(Vector3(0.2, 7.13, 0), Vector3(0.03, 0.035, 0.025), Basis(), 8, 5)
	g.loft([Vector3(-0.1, 7.1, 0), Vector3(-0.17, 6.98, 0), Vector3(-0.18, 6.88, 0)], [Vector2(0.05, 0.05), Vector2(0.04, 0.04), Vector2(0.025, 0.025)], Vector3.RIGHT, 8)
	# Tricorn: brim turned up between three corners (one forward), and a low crown.
	var hat := Vector3(0.03, 7.32, 0)
	const HAT_SEGS := 24
	var inner := []
	var outer := []
	for j in HAT_SEGS:
		var th := TAU * j / HAT_SEGS
		var reach := 0.27 + 0.07 * cos(3.0 * th)
		inner.append(hat + Vector3(cos(th) * 0.15, 0.0, sin(th) * 0.15))
		outer.append(hat + Vector3(cos(th) * reach, 0.1 - 0.06 * cos(3.0 * th), sin(th) * reach))
	for j in HAT_SEGS:
		var k := (j + 1) % HAT_SEGS
		var n: Vector3 = (outer[j] - inner[j]).cross(inner[k] - inner[j]).normalized()
		g.quad(inner[j], outer[j], outer[k], inner[k], n, n, n, n)
		g.quad(inner[j], outer[j], outer[k], inner[k], -n, -n, -n, -n)
	g.ellipsoid(hat + Vector3(0, 0.07, 0), Vector3(0.17, 0.12, 0.16))
	for s in [1.0, -1.0]:
		g.loft([Vector3(0.05, 5.74, 0.2 * s), Vector3(0.45, 5.38, 0.55 * s)], [Vector2(0.12, 0.12), Vector2(0.1, 0.1)], Vector3.UP, 10)
		g.loft([Vector3(0.45, 5.38, 0.55 * s), Vector3(0.4, 5.05, 0.56 * s), Vector3(0.35, 4.78, 0.55 * s)], [Vector2(0.1, 0.1), Vector2(0.095, 0.095), Vector2(0.085, 0.085)], Vector3.UP, 10)
		g.loft([Vector3(0.33, 4.76, 0.55 * s), Vector3(0.52, 4.72, 0.55 * s)], [Vector2(0.06, 0.05), Vector2(0.05, 0.04)], Vector3.UP, 8)
		g.ellipsoid(Vector3(0.0, 6.78, 0.3 * s), Vector3(0.11, 0.045, 0.09))
		g.loft([Vector3(0.0, 6.74, 0.3 * s), Vector3(0.18, 6.36, 0.36 * s)], [Vector2(0.08, 0.08), Vector2(0.07, 0.07)], Vector3.UP, 10)
		g.loft([Vector3(0.18, 6.36, 0.36 * s), Vector3(0.5, 6.26, 0.15 * s)], [Vector2(0.065, 0.065), Vector2(0.055, 0.055)], Vector3.UP, 10)
		g.ellipsoid(Vector3(0.53, 6.26, 0.14 * s), Vector3(0.07, 0.055, 0.06))
		g.loft([Vector3(0.55, 6.25, 0.12 * s), Vector3(1.3, 6.02, 0.2 * s), Vector3(2.12, 6.12, 0.1 * s)], [Vector2(0.018, 0.018), Vector2(0.018, 0.018), Vector2(0.018, 0.018)], Vector3.UP, 5)
	g.loft([Vector3(-0.05, 5.82, 0.3), Vector3(-0.45, 5.15, 0.44)], [Vector2(0.035, 0.035), Vector2(0.03, 0.03)], Vector3.UP, 8)


static func bronze_statue(town: Node3D) -> void:
	var statue: Node3D = town.get_node("WashingtonStatue")
	# Old sphere-and-box figure: hidden, not deleted (checks read the horse head/body and the
	# tricorn brim; FigureTorso etc. keep their collision).
	for child in statue.get_children():
		var title := String(child.name)
		if (title.begins_with("Washington") and not title.ends_with("granite step")) or title.begins_with("Figure"):
			child.hide()
	for detail in statue.get_node("SculptureDetails").get_children():
		if not String(detail.name).begins_with("Pedestal"): detail.hide()
	var g := Geo.new()
	horse_and_rider(g)
	add_mesh(statue, "Bronze horse and rider", g, material(BRONZE, 0.42, 0.45))
	# Raised panel mouldings on the pedestal's four faces (pedestal block: 4 x 3 x 4, centre y 1.5).
	var pedestal := Geo.new()
	var frame := [Vector2(-0.06, -0.05), Vector2(0.06, -0.05), Vector2(0.06, 0.03), Vector2(0.03, 0.06), Vector2(-0.03, 0.06), Vector2(-0.06, 0.03)]
	for face in 4:
		var normal := Vector3.RIGHT.rotated(Vector3.UP, face * PI * 0.5)
		var along := normal.cross(Vector3.UP)
		var center := normal * 2.0
		for spec in [[Vector3(0, 2.38, 0), along, 2.9], [Vector3(0, 1.0, 0), along, 2.9]]:
			_face_bar(pedestal, center + spec[0], spec[1], spec[2], normal, frame)
		for s in [1.0, -1.0]:
			_face_bar(pedestal, center + along * 1.42 * s + Vector3(0, 1.69, 0), Vector3.UP, 1.32, normal, frame)
	var ped_mesh: MeshInstance3D = statue.get_node("Pedestal")
	var stone: StandardMaterial3D = ped_mesh.material_override
	add_mesh(statue, "Pedestal panel mouldings", pedestal, material(stone.albedo_color.lightened(0.04), 0.85))
	# Engraved-style lettering in place of the white outlined label.
	var plaque: Label3D = statue.get_node("Plaque")
	plaque.modulate = Color("4a4236")
	plaque.outline_size = 0
	plaque.font_size = 48
	plaque.pixel_size = 0.006
	plaque.position.y = 1.72


## A moulding bar on a pedestal face: profile x across the bar, y out of the face.
static func _face_bar(g: Geo, center: Vector3, along: Vector3, length: float, normal: Vector3, profile: Array) -> void:
	var across := along.cross(normal).normalized()
	var half := along.normalized() * length * 0.5
	var ring := []
	for p in profile: ring.append(center + across * p.x + normal * p.y)
	for i in ring.size():
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % ring.size()]
		var edge: Vector2 = (profile[i] + profile[(i + 1) % ring.size()]) * 0.5
		var out := across * edge.x + normal * edge.y
		g.flat(a - half, b - half, b + half, out)
		g.flat(a - half, b + half, a + half, out)
	var c := center + normal * 0.005
	for i in ring.size():
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % ring.size()]
		g.flat(a + half, b + half, c + half, half)
		g.flat(a - half, b - half, c - half, -half)


# --- Statue, character blueprint (8 Nov 2026) --------------------------------------------
# User's "Washington Equestrian Statue - Character Blueprint": a chunky, friendly horse and
# rider in olive patina bronze with gilt bridle, blanket trim, buttons and epaulettes, on a
# rounded bronze base plate; warm cream stone for the pedestal and its steps.

const PATINA := Color("75774a")
const PATINA_DARK := Color("45462b")
const GILT := Color("b8a05a")
const PLATE_TOP := 3.6
const STATUE_STONE := {"Pedestal": "e4cbb4", "UpperPlinth": "eed9c6",
	"SculptureDetails/Pedestal cornice": "eed9c6", "SculptureDetails/Pedestal cornice fillet": "dcc1a8",
	"SculptureDetails/Pedestal base course": "dcc1a8", "Washington upper granite step": "e2c9b2",
	"Washington lower granite step": "d6bba2", "Pedestal panel mouldings": "ecd6c2"}
## The horse's head is modelled high and dropped by this much so the rider's head stands clear.
const HEAD_DROP := Vector3(0, -0.3, 0)


static func _tube(g: Geo, points: Array, radius: float, segs := 8, caps := true) -> void:
	var radii := []
	for p in points: radii.append(Vector2(radius, radius))
	g.loft(points, radii, Vector3.UP, segs, caps)


## Loft from [x, y, half width, half depth] rows at side offset z.
static func _limb(g: Geo, rows: Array, z: float, up: Vector3, segs := 12, girth := 1.0) -> void:
	var pts := []
	var radii := []
	for r in rows:
		pts.append(Vector3(r[0], r[1], z))
		radii.append(Vector2(r[2], r[3]) * girth)
	g.loft(pts, radii, up, segs)


## Moves the vertices added since index `from`.
static func _shift(g: Geo, from: int, offset: Vector3) -> void:
	for i in range(from, g.verts.size()): g.verts[i] += offset


## Statue frame: +X = facing, hooves on the base plate at y PLATE_TOP.
static func blueprint_horse(g: Geo) -> void:
	var y0 := PLATE_TOP
	g.color = PATINA
	# Barrel (constant girth under the blanket), haunches and shoulders.
	_limb(g, [[-1.16, 5.12, 0.2, 0.22], [-1.08, 5.1, 0.38, 0.42], [-0.9, 5.08, 0.5, 0.55], [-0.6, 5.07, 0.53, 0.58],
		[-0.3, 5.07, 0.53, 0.58], [0.1, 5.07, 0.53, 0.58], [0.4, 5.07, 0.53, 0.58], [0.7, 5.1, 0.5, 0.56],
		[0.95, 5.17, 0.42, 0.5], [1.1, 5.25, 0.28, 0.35], [1.17, 5.3, 0.12, 0.16]], 0.0, Vector3.UP, 20)
	for s in [1.0, -1.0]:
		g.ellipsoid(Vector3(-0.74, 4.97, 0.29 * s), Vector3(0.38, 0.47, 0.24), Basis(), 14, 8)
		g.ellipsoid(Vector3(0.72, 4.97, 0.27 * s), Vector3(0.28, 0.42, 0.22), Basis(), 14, 8)
	# Thick arched neck; mane: a thick wavy crest with lumps.
	var neck := [[0.75, 5.3, 0.36, 0.42], [0.98, 5.6, 0.31, 0.37], [1.15, 5.85, 0.26, 0.31], [1.28, 6.03, 0.21, 0.26], [1.38, 6.17, 0.18, 0.22]]
	_limb(g, neck, 0.0, Vector3.UP, 16)
	for i in neck.size():
		var a := Vector3(neck[maxi(i - 1, 0)][0], neck[maxi(i - 1, 0)][1], 0)
		var b := Vector3(neck[mini(i + 1, neck.size() - 1)][0], neck[mini(i + 1, neck.size() - 1)][1], 0)
		var t := (b - a).normalized()
		var crest: Vector3 = Vector3(neck[i][0], neck[i][1], 0) + Vector3(-t.y, t.x, 0) * neck[i][3] * 0.82
		g.ellipsoid(crest, Vector3(0.13, 0.12, 0.09 - 0.008 * i), Basis(Vector3.BACK, atan2(t.y, t.x)), 10, 6)
	# Big rounded head with cheek and muzzle, forelock, ears, eyes, nostrils (dropped below).
	var head_from := g.verts.size()
	_limb(g, [[1.36, 6.54, 0.17, 0.2], [1.58, 6.38, 0.175, 0.2], [1.78, 6.18, 0.155, 0.17], [1.92, 6.02, 0.14, 0.15], [2.0, 5.93, 0.12, 0.12]], 0.0, Vector3.UP, 16)
	g.ellipsoid(Vector3(1.52, 6.32, 0), Vector3(0.2, 0.2, 0.18), Basis(), 14, 8)
	g.ellipsoid(Vector3(1.97, 5.95, 0), Vector3(0.15, 0.13, 0.145), Basis(), 14, 8)
	g.loft([Vector3(1.47, 6.7, 0), Vector3(1.58, 6.66, 0.02), Vector3(1.66, 6.56, 0.0)], [Vector2(0.06, 0.05), Vector2(0.055, 0.045), Vector2(0.03, 0.025)], Vector3.UP, 8)
	for s in [1.0, -1.0]:
		g.color = PATINA
		g.loft([Vector3(1.4, 6.6, 0.09 * s), Vector3(1.39, 6.76, 0.11 * s), Vector3(1.37, 6.9, 0.12 * s)], [Vector2(0.065, 0.045), Vector2(0.05, 0.035), Vector2(0.01, 0.008)], Vector3.RIGHT, 8)
		g.color = PATINA_DARK
		g.ellipsoid(Vector3(1.62, 6.43, 0.165 * s), Vector3(0.05, 0.045, 0.03), Basis(), 8, 5)
		g.ellipsoid(Vector3(2.07, 5.93, 0.075 * s), Vector3(0.025, 0.03, 0.02), Basis(), 6, 4)
	_shift(g, head_from, HEAD_DROP)
	# Legs [x, y, half width, half depth]: near foreleg raised and curled, far hind leg back.
	g.color = PATINA
	var legs := [
		[0.27, [[-0.72, 4.75, 0.17, 0.24], [-0.82, 4.38, 0.13, 0.17], [-0.92, 4.12, 0.1, 0.12], [-0.93, 3.98, 0.085, 0.09], [-0.92, 3.82, 0.095, 0.1], [-0.91, 3.74, 0.09, 0.09]], Vector3(-0.9, 0, 0.27)],
		[-0.27, [[-0.72, 4.75, 0.17, 0.24], [-0.78, 4.38, 0.13, 0.17], [-0.84, 4.12, 0.1, 0.12], [-0.83, 3.98, 0.085, 0.09], [-0.8, 3.82, 0.095, 0.1], [-0.79, 3.74, 0.09, 0.09]], Vector3(-0.78, 0, -0.27)],
		[-0.24, [[0.72, 4.75, 0.15, 0.2], [0.76, 4.4, 0.11, 0.14], [0.78, 4.18, 0.1, 0.11], [0.78, 3.98, 0.085, 0.09], [0.8, 3.82, 0.095, 0.1], [0.81, 3.74, 0.09, 0.09]], Vector3(0.82, 0, -0.24)],
		[0.24, [[0.72, 4.75, 0.15, 0.2], [0.85, 4.45, 0.11, 0.14], [0.98, 4.27, 0.1, 0.11], [0.93, 4.07, 0.085, 0.09], [0.87, 3.97, 0.09, 0.09]], null]]
	for leg in legs:
		_limb(g, leg[1], leg[0], Vector3.RIGHT, 12, 1.22)
		var hoof = leg[2]
		g.color = PATINA_DARK.lerp(PATINA, 0.55)
		if hoof == null:
			g.ellipsoid(Vector3(0.83, 3.93, 0.24), Vector3(0.13, 0.09, 0.14), Basis(Vector3.BACK, 0.6), 12, 6)
		else:
			g.lathe(Vector3(hoof.x, y0, hoof.z), [Vector2(0, 0), Vector2(0.16, 0), Vector2(0.162, 0.06), Vector2(0.145, 0.13), Vector2(0.115, 0.17), Vector2(0, 0.175)], 16)
		g.color = PATINA
	# Thick wavy tail.
	g.loft([Vector3(-1.1, 5.32, 0), Vector3(-1.28, 5.2, 0), Vector3(-1.38, 4.9, 0.02), Vector3(-1.33, 4.55, -0.02), Vector3(-1.38, 4.25, 0.02), Vector3(-1.5, 4.02, 0), Vector3(-1.6, 3.95, 0)],
		[Vector2(0.09, 0.1), Vector2(0.12, 0.14), Vector2(0.13, 0.17), Vector2(0.12, 0.16), Vector2(0.11, 0.14), Vector2(0.08, 0.09), Vector2(0.03, 0.03)], Vector3.RIGHT, 12)
	# Saddle blanket draped over the barrel with a gilt border, and the saddle.
	var xs := [-0.62, -0.42, -0.22, -0.02, 0.18, 0.38]
	const BLANKET_A := 1.45
	var cols := 14
	var grid := []
	var ngrid := []
	for x in xs:
		var row := []
		var nrow := []
		for j in cols + 1:
			var a := lerpf(-BLANKET_A, BLANKET_A, float(j) / cols)
			row.append(Vector3(x, 5.07 + 0.605 * cos(a), 0.555 * sin(a)))
			nrow.append(Vector3(0, cos(a) / 0.605, sin(a) / 0.555).normalized())
		grid.append(row)
		ngrid.append(nrow)
	g.color = PATINA.darkened(0.06)
	for i in xs.size() - 1:
		for j in cols:
			g.quad(grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1], ngrid[i][j], ngrid[i + 1][j], ngrid[i + 1][j + 1], ngrid[i][j + 1])
	var border := []
	for j in cols + 1: border.append(grid[0][j])
	for i in range(1, xs.size()): border.append(grid[i][cols])
	for j in range(cols - 1, -1, -1): border.append(grid[xs.size() - 1][j])
	for i in range(xs.size() - 2, -1, -1): border.append(grid[i][0])
	var lifted := []
	for p in border: lifted.append(Vector3(p.x, 5.07 + (p.y - 5.07) * 1.015, p.z * 1.015))
	g.color = GILT
	_tube(g, lifted, 0.026, 6, false)
	g.color = PATINA
	g.ellipsoid(Vector3(-0.05, 5.67, 0), Vector3(0.42, 0.1, 0.36), Basis(), 16, 6)
	g.ellipsoid(Vector3(0.3, 5.76, 0), Vector3(0.08, 0.09, 0.13), Basis(), 10, 6)
	g.ellipsoid(Vector3(-0.42, 5.77, 0), Vector3(0.07, 0.11, 0.24), Basis(), 10, 6)
	# Gilt bridle: noseband loop, cheek straps, rosettes, bit rings and reins.
	g.color = GILT
	var bridle_from := g.verts.size()
	var along := Vector3(0.67, -0.74, 0).normalized()
	var perp := Vector3(0.74, 0.67, 0).normalized()
	var loop := []
	for j in 17:
		var th := TAU * j / 16.0
		loop.append(Vector3(1.85, 6.06, 0) + Vector3(0, 0, 0.168) * cos(th) + perp * 0.168 * sin(th))
	_tube(g, loop, 0.022, 6, false)
	for s in [1.0, -1.0]:
		_tube(g, [Vector3(1.42, 6.66, 0.16 * s), Vector3(1.55, 6.5, 0.19 * s), Vector3(1.7, 6.3, 0.18 * s), Vector3(1.84, 6.1, 0.17 * s)], 0.022, 6)
		g.ellipsoid(Vector3(1.52, 6.54, 0.2 * s), Vector3(0.055, 0.055, 0.025), Basis(), 10, 5)
		var ring := []
		for j in 13:
			var th := TAU * j / 12.0
			ring.append(Vector3(1.94, 5.98, 0.165 * s) + along * 0.05 * cos(th) + perp * 0.05 * sin(th))
		_tube(g, ring, 0.014, 5, false)
	_shift(g, bridle_from, HEAD_DROP)
	for s in [1.0, -1.0]:
		_tube(g, [Vector3(0.45, 6.04, 0.17 * s), Vector3(0.9, 5.98, 0.27 * s), Vector3(1.3, 5.9, 0.25 * s), Vector3(1.65, 5.8, 0.2 * s), Vector3(1.93, 5.68, 0.17 * s)], 0.02, 6)


static func blueprint_rider(g: Geo) -> void:
	g.color = PATINA
	# Seat, upright torso, coat tails lying on the horse's back.
	g.ellipsoid(Vector3(-0.05, 5.86, 0), Vector3(0.28, 0.17, 0.27), Basis(), 14, 7)
	_limb(g, [[-0.05, 5.82, 0.27, 0.2], [-0.03, 6.2, 0.28, 0.21], [-0.02, 6.48, 0.31, 0.2], [-0.02, 6.62, 0.15, 0.12]], 0.0, Vector3.RIGHT, 16)
	g.loft([Vector3(-0.12, 6.08, 0), Vector3(-0.3, 5.84, 0), Vector3(-0.46, 5.76, 0)], [Vector2(0.3, 0.12), Vector2(0.33, 0.1), Vector2(0.28, 0.06)], Vector3.UP, 12)
	# Legs over the barrel: thigh, tall boot with a turned cuff, foot; stirrup leathers.
	for s in [1.0, -1.0]:
		g.color = PATINA
		_tube(g, [Vector3(0.0, 5.88, 0.17 * s), Vector3(0.16, 5.8, 0.36 * s), Vector3(0.3, 5.68, 0.5 * s)], 0.135, 12)
		g.color = PATINA.darkened(0.12)
		g.loft([Vector3(0.3, 5.66, 0.5 * s), Vector3(0.28, 5.25, 0.62 * s), Vector3(0.27, 4.98, 0.64 * s)], [Vector2(0.12, 0.12), Vector2(0.1, 0.1), Vector2(0.095, 0.095)], Vector3.UP, 12)
		g.ellipsoid(Vector3(0.3, 5.6, 0.52 * s), Vector3(0.14, 0.06, 0.14), Basis(Vector3.RIGHT, -0.25 * s), 12, 5)
		g.ellipsoid(Vector3(0.37, 4.91, 0.65 * s), Vector3(0.17, 0.075, 0.09), Basis(), 12, 6)
		g.color = PATINA_DARK.lerp(PATINA, 0.4)
		_tube(g, [Vector3(0.04, 5.62, 0.42 * s), Vector3(0.2, 5.2, 0.6 * s), Vector3(0.3, 4.9, 0.66 * s)], 0.018, 5)
	# Arms holding the reins, cuffs, hands; gilt epaulettes.
	for s in [1.0, -1.0]:
		g.color = PATINA
		_tube(g, [Vector3(-0.02, 6.46, 0.32 * s), Vector3(0.06, 6.26, 0.38 * s), Vector3(0.13, 6.12, 0.37 * s)], 0.095, 10)
		_tube(g, [Vector3(0.13, 6.12, 0.37 * s), Vector3(0.26, 6.06, 0.29 * s), Vector3(0.36, 6.05, 0.22 * s)], 0.08, 10)
		g.ellipsoid(Vector3(0.34, 6.05, 0.23 * s), Vector3(0.06, 0.085, 0.085), Basis(Vector3.UP, 0.5 * s), 10, 6)
		g.ellipsoid(Vector3(0.43, 6.04, 0.18 * s), Vector3(0.07, 0.06, 0.06), Basis(), 10, 6)
		g.color = GILT
		g.ellipsoid(Vector3(-0.02, 6.56, 0.29 * s), Vector3(0.12, 0.04, 0.1), Basis(), 12, 5)
		g.ellipsoid(Vector3(-0.02, 6.52, 0.33 * s), Vector3(0.11, 0.04, 0.07), Basis(), 12, 5)
		# Lapel piping and buttons down the coat front.
		_tube(g, [Vector3(0.12, 6.58, 0.07 * s), Vector3(0.19, 6.3, 0.12 * s), Vector3(0.21, 5.98, 0.13 * s)], 0.016, 5)
		for k in 4:
			g.ellipsoid(Vector3(0.205, 6.4 - k * 0.12, 0.09 * s), Vector3(0.022, 0.022, 0.022), Basis(), 6, 4)
	# Cravat, neck and a big friendly head with nose, eyes, ears, side curls and queue.
	g.color = PATINA.lightened(0.05)
	g.ellipsoid(Vector3(0.15, 6.52, 0), Vector3(0.07, 0.09, 0.09), Basis(), 10, 6)
	g.color = PATINA
	_tube(g, [Vector3(-0.02, 6.55, 0), Vector3(-0.01, 6.76, 0)], 0.11, 12)
	g.ellipsoid(Vector3(0.0, 6.96, 0), Vector3(0.26, 0.28, 0.25), Basis(), 20, 12)
	g.ellipsoid(Vector3(0.255, 6.93, 0), Vector3(0.05, 0.06, 0.045), Basis(), 8, 5)
	for s in [1.0, -1.0]:
		g.color = PATINA_DARK
		g.ellipsoid(Vector3(0.225, 7.01, 0.09 * s), Vector3(0.022, 0.034, 0.026), Basis(), 8, 5)
		g.color = PATINA
		g.ellipsoid(Vector3(0.0, 6.94, 0.245 * s), Vector3(0.045, 0.065, 0.035), Basis(), 8, 5)
		for row in [7.03, 6.9]:
			g.ellipsoid(Vector3(-0.1, row, 0.215 * s), Vector3(0.085, 0.06, 0.05), Basis(), 10, 6)
	_tube(g, [Vector3(-0.22, 6.96, 0), Vector3(-0.29, 6.8, 0), Vector3(-0.3, 6.6, 0)], 0.05, 8)
	g.ellipsoid(Vector3(-0.27, 6.82, 0), Vector3(0.04, 0.05, 0.1), Basis(), 8, 5)
	# Tricorn: wide brim turned up between three corners (one forward), rolled edge, crown.
	var hat := Vector3(0.0, 7.15, 0)
	const HAT_SEGS := 36
	var inner := []
	var outer := []
	for j in HAT_SEGS + 1:
		var th := TAU * j / HAT_SEGS
		var reach := 0.42 + 0.08 * cos(3.0 * th)
		inner.append(hat + Vector3(cos(th) * 0.23, 0.0, sin(th) * 0.22))
		outer.append(hat + Vector3(cos(th) * reach, 0.13 - 0.08 * cos(3.0 * th), sin(th) * reach))
	for j in HAT_SEGS:
		var n: Vector3 = (outer[j] - inner[j]).cross(inner[j + 1] - inner[j]).normalized()
		g.quad(inner[j], outer[j], outer[j + 1], inner[j + 1], n, n, n, n)
		g.quad(inner[j], outer[j], outer[j + 1], inner[j + 1], -n, -n, -n, -n)
	_tube(g, outer, 0.028, 6, false)
	g.ellipsoid(hat + Vector3(0, 0.08, 0), Vector3(0.25, 0.17, 0.24), Basis(), 16, 8)
	# Sword hanging at the left hip.
	g.color = PATINA_DARK.lerp(PATINA, 0.5)
	_tube(g, [Vector3(-0.1, 5.85, -0.32), Vector3(-0.35, 5.45, -0.5), Vector3(-0.55, 5.1, -0.58)], 0.03, 6)
	g.color = GILT
	g.ellipsoid(Vector3(-0.08, 5.9, -0.31), Vector3(0.05, 0.05, 0.05), Basis(), 8, 5)


## Rounded bronze plate under the hooves, on the upper plinth (top y 3.5).
static func blueprint_plate(g: Geo) -> void:
	g.color = PATINA.darkened(0.1)
	var rim := []
	var corners := [Vector2(1.08, 0.36), Vector2(-1.08, 0.36), Vector2(-1.08, -0.36), Vector2(1.08, -0.36)]
	var start := [0.0, PI * 0.5, PI, PI * 1.5]
	for k in 4:
		for j in 7:
			var a: float = start[k] + PI * 0.5 * j / 6.0
			rim.append(corners[k] + Vector2(cos(a), sin(a)) * 0.34)
	var bottom := 3.5
	var top := PLATE_TOP
	for i in rim.size():
		var a: Vector2 = rim[i]
		var b: Vector2 = rim[(i + 1) % rim.size()]
		var na := Vector3(a.x - clampf(a.x, -1.08, 1.08), 0, a.y - clampf(a.y, -0.36, 0.36)).normalized()
		var nb := Vector3(b.x - clampf(b.x, -1.08, 1.08), 0, b.y - clampf(b.y, -0.36, 0.36)).normalized()
		var ia := Vector3(a.x, top, a.y) - na * 0.04
		var ib := Vector3(b.x, top, b.y) - nb * 0.04
		g.quad(Vector3(a.x, bottom, a.y), Vector3(b.x, bottom, b.y), Vector3(b.x, top - 0.03, b.y), Vector3(a.x, top - 0.03, a.y), na, nb, nb, na)
		var ba := (na + Vector3.UP).normalized()
		var bb := (nb + Vector3.UP).normalized()
		g.quad(Vector3(a.x, top - 0.03, a.y), Vector3(b.x, top - 0.03, b.y), ib, ia, ba, bb, bb, ba)
		g.tri(Vector3(0, top, 0), ia, ib, Vector3.UP, Vector3.UP, Vector3.UP)


static func statue_blueprint(town: Node3D) -> void:
	var statue: Node3D = town.get_node("WashingtonStatue")
	remove(statue.get_node("Bronze horse and rider"))
	var g := Geo.new()
	blueprint_plate(g)
	blueprint_horse(g)
	blueprint_rider(g)
	var bronze := material(Color.WHITE, 0.5, 0.22)
	bronze.vertex_color_is_srgb = true
	add_mesh(statue, "Bronze horse and rider", g, bronze)
	for path in STATUE_STONE:
		var node := statue.get_node(path)
		var mesh: MeshInstance3D = node if node is MeshInstance3D else node.get_child(0)
		var stone: StandardMaterial3D = mesh.material_override.duplicate()
		stone.albedo_color = Color(STATUE_STONE[path])
		mesh.material_override = stone
	var plaque: Label3D = statue.get_node("Plaque")
	plaque.modulate = Color("6a5644")


# --- Statue traced from the character blueprint (8 Nov 2026, second pass) ----------------
# The first blueprint pass kept the old figure's proportions. This one is traced from the
# blueprint's side view: every point below is in that view's pixels (x right = statue +X,
# y down, hooves at y 375; widths from the front/back views at the same scale) and converted
# with TRACE_SCALE, so the rider, the head carriage and the statue/pedestal ratio match it.

const TRACE_SCALE := 0.018      # metres (town units) per blueprint pixel
const TRACE_X0 := 905.0         # blueprint x of the statue's centre
const TRACE_GROUND := 375.0     # blueprint y of the hooves
const TRACE_BRONZE := Color("6c6b42")
const TRACE_SHADE := Color("3d3d24")
const TRACE_GILT := Color("b89a4c")


static func _p(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3((x - TRACE_X0) * TRACE_SCALE, PLATE_TOP + (TRACE_GROUND - y) * TRACE_SCALE, z * TRACE_SCALE)


## Loft through blueprint rows [x, y, half width (z), half depth], all in pixels.
static func _trace(g: Geo, rows: Array, z: float, up: Vector3, segs := 14) -> void:
	var pts := []
	var radii := []
	for r in rows:
		pts.append(_p(r[0], r[1], z))
		radii.append(Vector2(r[2], r[3]) * TRACE_SCALE)
	g.loft(pts, radii, up, segs)


static func _blob(g: Geo, x: float, y: float, z: float, r: Vector3, basis := Basis(), segs := 14, rows := 8) -> void:
	g.ellipsoid(_p(x, y, z), r * TRACE_SCALE, basis, segs, rows)


static func _cord(g: Geo, points: Array, r: float, segs := 7, caps := true) -> void:
	var pts := []
	for p in points: pts.append(_p(p.x, p.y, p.z))
	_tube(g, pts, r * TRACE_SCALE, segs, caps)


static func traced_horse(g: Geo) -> void:
	g.color = TRACE_BRONZE
	# Long barrel with a high rounded rump and deep chest; haunches and shoulders.
	_trace(g, [[795, 272, 12, 14], [803, 271, 27, 26], [818, 272, 36, 31], [845, 277, 37, 32], [880, 281, 35, 30],
		[915, 280, 35, 30], [948, 275, 36, 32], [970, 272, 33, 30], [984, 274, 24, 22], [991, 276, 10, 10]], 0, Vector3.UP, 22)
	for s in [1.0, -1.0]:
		_blob(g, 832, 280, 20 * s, Vector3(28, 31, 15))
		_blob(g, 958, 282, 19 * s, Vector3(20, 28, 15))
	_blob(g, 976, 277, 0, Vector3(16, 25, 27), Basis(), 18, 10)
	# Upright, thick neck rising from the withers; big head carried high, nose down.
	var neck := [[960, 262, 25, 29], [982, 226, 21, 23], [996, 192, 18, 20], [1004, 168, 16, 17]]
	_trace(g, neck, 0, Vector3.UP, 18)
	var head_from := g.verts.size()
	_trace(g, [[1002, 156, 17, 18], [1013, 174, 17.5, 21], [1024, 194, 15, 17], [1032, 210, 13.5, 13.5], [1036, 218, 10, 9]], 0, Vector3.UP, 20)
	_blob(g, 1009, 184, 0, Vector3(17, 19, 15.5))
	_blob(g, 1030, 210, 0, Vector3(13.5, 12.5, 14))
	# Smooth crest with chunky locks falling to the near side, and a forelock.
	var crest := [Vector3(948, 238, 0), Vector3(968, 214, 0), Vector3(985, 186, 0), Vector3(998, 164, 0), Vector3(1003, 152, 0)]
	_trace(g, [[948, 240, 7, 8], [968, 216, 8, 9], [985, 188, 8, 9], [998, 165, 7, 8], [1003, 153, 5, 5]], 0, Vector3.UP, 10)
	for i in 4:
		var a: Vector3 = crest[i].lerp(crest[i + 1], 0.5)
		_blob(g, a.x + 2, a.y + 6, 10, Vector3(9, 12, 6), Basis(Vector3.BACK, -0.9), 10, 6)
	_cord(g, [Vector3(1003, 149, 0), Vector3(1012, 150, 0), Vector3(1019, 159, 0)], 5, 8)
	for s in [1.0, -1.0]:
		g.color = TRACE_BRONZE
		_trace(g, [[1002, 153, 6, 4.5], [1001, 146, 4.5, 3.5], [999, 139, 0.8, 0.6]], 8 * s, Vector3.RIGHT, 8)
		g.color = TRACE_SHADE
		_blob(g, 1017, 173, 15.6 * s, Vector3(4, 3.6, 2.4), Basis(), 10, 6)
		_blob(g, 1040, 213, 6.5 * s, Vector3(1.8, 2.5, 1.6), Basis(), 6, 4)
	_shift(g, head_from, Vector3(0, -8 * TRACE_SCALE, 0))
	# Legs [x, y, half width, half depth]: near foreleg raised and curled, near hind leg back.
	g.color = TRACE_BRONZE
	var legs := [
		[16, [[832, 290, 14, 18], [826, 312, 11, 13], [818, 334, 9, 10], [816, 348, 7.5, 8], [816, 360, 8.5, 9], [816, 366, 7.5, 7.5]], Vector2(816, 16)],
		[-16, [[838, 290, 14, 18], [840, 312, 11, 13], [838, 334, 9, 10], [842, 348, 7.5, 8], [846, 360, 8.5, 9], [847, 366, 7.5, 7.5]], Vector2(848, -16)],
		[-15, [[958, 296, 13, 16], [957, 318, 10, 12], [957, 336, 9, 10], [958, 350, 7.5, 8], [960, 360, 8.5, 9], [961, 366, 7.5, 7.5]], Vector2(962, -15)],
		[15, [[960, 296, 13, 16], [972, 312, 10, 12], [985, 326, 9, 10], [979, 340, 7.5, 8], [972, 350, 8, 8.5]], null]]
	for leg in legs:
		_trace(g, leg[1], leg[0], Vector3.RIGHT, 14)
		g.color = TRACE_SHADE.lerp(TRACE_BRONZE, 0.55)
		var hoof = leg[2]
		if hoof == null:
			_blob(g, 967, 353, 15, Vector3(9, 6.5, 9.5), Basis(Vector3.BACK, 0.8), 12, 6)
		else:
			var at := _p(hoof.x, TRACE_GROUND, hoof.y)
			var k := TRACE_SCALE
			g.lathe(at, [Vector2(0, 0), Vector2(10.5 * k, 0), Vector2(10.6 * k, 4 * k), Vector2(9.5 * k, 8 * k), Vector2(8 * k, 10.5 * k), Vector2(0, 11 * k)], 18)
		g.color = TRACE_BRONZE
	# Thick, long wavy tail.
	_trace(g, [[800, 256, 6, 7], [791, 268, 9, 10], [786, 292, 10, 12.5], [790, 318, 9.5, 12], [785, 338, 8, 10], [778, 352, 5, 6], [774, 356, 1.5, 1.5]], 0, Vector3.RIGHT, 14)
	# Saddle blanket over the barrel with a gilt border; saddle with pommel and cantle.
	var xs := [850.0, 865.0, 880.0, 895.0, 910.0, 924.0]
	const ARC := 2.05
	var cols := 16
	var grid := []
	var ngrid := []
	for x in xs:
		var row := []
		var nrow := []
		for j in cols + 1:
			var a := lerpf(-ARC, ARC, float(j) / cols)
			row.append(_p(x, 280.5 - 31.5 * cos(a), 36.6 * sin(a)))
			nrow.append(Vector3(0, cos(a) / 31.5, sin(a) / 36.6).normalized())
		grid.append(row)
		ngrid.append(nrow)
	g.color = TRACE_BRONZE.darkened(0.08)
	for i in xs.size() - 1:
		for j in cols:
			g.quad(grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1], ngrid[i][j], ngrid[i + 1][j], ngrid[i + 1][j + 1], ngrid[i][j + 1])
	var border := []
	for j in cols + 1: border.append(grid[0][j])
	for i in range(1, xs.size()): border.append(grid[i][cols])
	for j in range(cols - 1, -1, -1): border.append(grid[xs.size() - 1][j])
	for i in range(xs.size() - 2, -1, -1): border.append(grid[i][0])
	g.color = TRACE_GILT
	_tube(g, border, 1.6 * TRACE_SCALE, 6, false)
	g.color = TRACE_BRONZE
	_blob(g, 886, 249, 0, Vector3(29, 6.5, 30), Basis(), 18, 6)
	_blob(g, 909, 244, 0, Vector3(6, 7, 11), Basis(), 10, 6)
	_blob(g, 862, 243, 0, Vector3(5, 8, 20), Basis(), 10, 6)
	# Gilt bridle: noseband, cheek straps, rosettes, bit rings; reins to both hands.
	g.color = TRACE_GILT
	var axis := Vector3(0.436, -0.9, 0).normalized()
	var perp := Vector3(0.9, 0.436, 0)
	var bridle_from := g.verts.size()
	var nose := _p(1026, 200)
	var loop := []
	for j in 21:
		var th := TAU * j / 20.0
		loop.append(nose + Vector3(0, 0, 16.2 * TRACE_SCALE) * cos(th) + perp * 16.8 * TRACE_SCALE * sin(th))
	_tube(g, loop, 1.5 * TRACE_SCALE, 6, false)
	for s in [1.0, -1.0]:
		_cord(g, [Vector3(1001, 156, 17.6 * s), Vector3(1010, 172, 18.4 * s), Vector3(1018, 188, 17.2 * s), Vector3(1023, 200, 16.2 * s)], 1.6)
		_blob(g, 1007, 165, 18.4 * s, Vector3(4, 4, 1.5), Basis(), 12, 5)
		var ring := []
		for j in 15:
			var th := TAU * j / 14.0
			ring.append(_p(1035, 211, 14 * s) + axis * 3.8 * TRACE_SCALE * cos(th) + perp * 3.8 * TRACE_SCALE * sin(th))
		_tube(g, ring, 1.1 * TRACE_SCALE, 5, false)
	_shift(g, bridle_from, Vector3(0, -8 * TRACE_SCALE, 0))
	for s in [1.0, -1.0]:
		_cord(g, [Vector3(934, 205, 17 * s), Vector3(962, 207, 21 * s), Vector3(990, 204, 23 * s), Vector3(1014, 214, 18 * s), Vector3(1034, 219, 14.5 * s)], 1.3, 6)


static func traced_rider(g: Geo) -> void:
	g.color = TRACE_BRONZE
	# Seat and a broad coat torso; coat skirts falling over the horse's back and flanks.
	_blob(g, 886, 240, 0, Vector3(22, 14, 26))
	_trace(g, [[885, 242, 26, 17], [887, 222, 28, 17], [890, 202, 30, 16], [892, 184, 29, 15], [893, 171, 19, 12]], 0, Vector3.RIGHT, 20)
	var skirt := []
	var skirt_n := []
	const SKIRT_ROWS := 5
	const SKIRT_COLS := 24
	for i in SKIRT_ROWS + 1:
		var t := float(i) / SKIRT_ROWS
		var row := []
		var nrow := []
		for j in SKIRT_COLS + 1:
			var th := lerpf(0.42 * PI, 1.58 * PI, float(j) / SKIRT_COLS)
			var side := absf(sin(th))
			var rx := lerpf(17.5, 33.0, t)
			var rz := lerpf(27.0, 37.0 + 2.0 * side, t)
			var y := lerpf(230.0, 247.0 + 16.0 * side, t)
			row.append(_p(887 + cos(th) * rx, y, sin(th) * rz))
			nrow.append(Vector3(cos(th) / rx, 0.35, sin(th) / rz).normalized())
		skirt.append(row)
		skirt_n.append(nrow)
	for i in SKIRT_ROWS:
		for j in SKIRT_COLS:
			g.quad(skirt[i][j], skirt[i + 1][j], skirt[i + 1][j + 1], skirt[i][j + 1], skirt_n[i][j], skirt_n[i + 1][j], skirt_n[i + 1][j + 1], skirt_n[i][j + 1])
			g.quad(skirt[i][j], skirt[i + 1][j], skirt[i + 1][j + 1], skirt[i][j + 1], -skirt_n[i][j], -skirt_n[i + 1][j], -skirt_n[i + 1][j + 1], -skirt_n[i][j + 1])
	var hem := []
	for p in skirt[SKIRT_ROWS]: hem.append(p)
	_tube(g, hem, 1.6 * TRACE_SCALE, 6)
	# Legs: thick thighs forward over the barrel, boots hanging down the flank to the belly line.
	for s in [1.0, -1.0]:
		g.color = TRACE_BRONZE
		_cord(g, [Vector3(888, 240, 15 * s), Vector3(902, 244, 30 * s), Vector3(915, 250, 41 * s)], 11.5, 12)
		g.color = TRACE_BRONZE.darkened(0.1)
		_trace(g, [[915, 251, 10, 10.5], [914, 270, 9.5, 10], [912, 286, 9, 9.5]], 44 * s, Vector3.RIGHT, 12)
		_blob(g, 915, 251, 43 * s, Vector3(12.5, 5.5, 12), Basis(), 12, 5)
		_blob(g, 921, 292, 45 * s, Vector3(13, 6, 7.5), Basis(), 12, 6)
		g.color = TRACE_SHADE.lerp(TRACE_BRONZE, 0.4)
		_cord(g, [Vector3(886, 252, 31 * s), Vector3(903, 274, 40 * s), Vector3(916, 292, 45 * s)], 1.3, 5)
	# Arms bent to the reins, cuffs and hands; gilt epaulettes, lapel piping and buttons.
	for s in [1.0, -1.0]:
		g.color = TRACE_BRONZE
		_cord(g, [Vector3(890, 184, 31 * s), Vector3(896, 198, 35 * s), Vector3(901, 211, 35 * s)], 9.5, 12)
		_cord(g, [Vector3(901, 211, 35 * s), Vector3(914, 209, 28 * s), Vector3(926, 206, 21 * s)], 8.5, 12)
		_blob(g, 921, 207, 24 * s, Vector3(5, 9, 9.5), Basis(Vector3.UP, 0.6 * s), 12, 6)
		_blob(g, 932, 205, 17.5 * s, Vector3(7, 6.5, 6.5), Basis(), 12, 6)
		_blob(g, 891, 180, 29 * s, Vector3(12, 4.5, 10), Basis(), 14, 6)
		for k in 9:
			var a := TAU * k / 9.0
			_cord(g, [Vector3(891 + cos(a) * 10.5, 182, (29 + sin(a) * 8.5) * s), Vector3(891 + cos(a) * 11.5, 190, (29 + sin(a) * 9.5) * s)], 1.6, 5)
		g.color = TRACE_GILT
		var rim := []
		for k in 17:
			var a := TAU * k / 16.0
			rim.append(Vector3(891 + cos(a) * 11.5, 181, (29 + sin(a) * 9.5) * s))
		_cord(g, rim, 1.1, 5, false)
		_cord(g, [Vector3(902, 178, 6 * s), Vector3(906, 200, 12 * s), Vector3(904, 232, 15 * s)], 1.3, 5)
		for k in 4:
			_blob(g, 906, 192 + k * 10, 7.5 * s, Vector3(1.6, 1.6, 1.6), Basis(), 8, 5)
	g.color = TRACE_BRONZE.lightened(0.04)
	_blob(g, 904, 172, 0, Vector3(7, 9, 9), Basis(), 12, 6)
	_blob(g, 906, 182, 0, Vector3(5, 6, 7), Basis(), 10, 6)
	g.color = TRACE_BRONZE
	var collar := []
	for k in 25:
		var a := TAU * k / 24.0
		collar.append(Vector3(894 + cos(a) * 12, 165 + 2.5 * cos(a), sin(a) * 13))
	_cord(g, collar, 4, 8, false)
	# Big head with a modelled face, wig rolls, queue and ears.
	g.color = TRACE_BRONZE
	_cord(g, [Vector3(893, 172, 0), Vector3(895, 160, 0)], 9, 12)
	_blob(g, 898, 136, 0, Vector3(20, 23, 20), Basis(), 22, 14)
	_blob(g, 911, 152.5, 0, Vector3(5, 4, 7), Basis(), 12, 6)
	_blob(g, 919.5, 138, 0, Vector3(4.6, 6.4, 4), Basis(Vector3.BACK, 0.2), 10, 6)
	for s in [1.0, -1.0]:
		g.color = TRACE_SHADE
		_blob(g, 916.2, 131, 7.5 * s, Vector3(1.8, 2.9, 2.3), Basis(), 10, 6)
		g.color = TRACE_BRONZE
		_cord(g, [Vector3(915.5, 125.5, 3.5 * s), Vector3(916, 124.5, 7.5 * s), Vector3(914.5, 125.5, 11 * s)], 1.2, 5)
		_blob(g, 897, 138, 20.3 * s, Vector3(3.5, 5.5, 2.5), Basis(), 10, 6)
		for y in [134.0, 143.0]:
			_cord(g, [Vector3(880, y, 17.5 * s), Vector3(886, y, 19.5 * s), Vector3(892, y, 19.5 * s)], 3.6, 10)
	g.color = TRACE_SHADE
	_cord(g, [Vector3(916.5, 149.5, -4), Vector3(917.6, 150.6, 0), Vector3(916.5, 149.5, 4)], 0.8, 5)
	g.color = TRACE_BRONZE
	_cord(g, [Vector3(880, 140, 0), Vector3(875, 150, 0), Vector3(873, 162, 0)], 4.2, 8)
	_blob(g, 877, 147, 0, Vector3(3.5, 4, 8), Basis(), 10, 6)
	# Tricorn: wide brim turned up between three corners (one forward), rolled edge, crown.
	var hat := _p(898, 115)
	const HAT_SEGS := 42
	var inner := []
	var outer := []
	var k := TRACE_SCALE
	for j in HAT_SEGS + 1:
		var th := TAU * j / HAT_SEGS
		var reach := (40.0 + 8.0 * cos(3.0 * th)) * k
		inner.append(hat + Vector3(cos(th) * 19.5 * k, 0.0, sin(th) * 19 * k))
		outer.append(hat + Vector3(cos(th) * reach, (11.0 - 8.0 * cos(3.0 * th)) * k, sin(th) * reach))
	for j in HAT_SEGS:
		var n: Vector3 = (outer[j] - inner[j]).cross(inner[j + 1] - inner[j]).normalized()
		g.quad(inner[j], outer[j], outer[j + 1], inner[j + 1], n, n, n, n)
		g.quad(inner[j], outer[j], outer[j + 1], inner[j + 1], -n, -n, -n, -n)
	_tube(g, outer, 2.0 * k, 6, false)
	g.ellipsoid(hat + Vector3(0, 6 * k, 0), Vector3(20.5, 13, 19.5) * k, Basis(), 18, 9)
	# Sword at the left hip.
	g.color = TRACE_SHADE.lerp(TRACE_BRONZE, 0.5)
	_cord(g, [Vector3(882, 236, -30), Vector3(866, 256, -38), Vector3(850, 276, -42)], 2.2, 6)
	g.color = TRACE_GILT
	_blob(g, 884, 233, -29, Vector3(3.5, 3.5, 3.5), Basis(), 8, 5)


## Rounded plate under the hooves (blueprint x 812-990), on the new cap at y 3.5.
static func traced_plate(g: Geo) -> void:
	g.color = TRACE_BRONZE.darkened(0.12)
	var cx := (_p(812, 0).x + _p(992, 0).x) * 0.5
	var hx := (_p(992, 0).x - _p(812, 0).x) * 0.5 - 0.38
	var hz := 0.42
	var r := 0.38
	var rim := []
	var corners := [Vector2(hx, hz), Vector2(-hx, hz), Vector2(-hx, -hz), Vector2(hx, -hz)]
	for c in 4:
		for j in 7:
			var a: float = PI * 0.5 * c + PI * 0.5 * j / 6.0
			rim.append(corners[c] + Vector2(cos(a), sin(a)) * r)
	var bottom := 3.5
	var top := PLATE_TOP
	for i in rim.size():
		var a: Vector2 = rim[i]
		var b: Vector2 = rim[(i + 1) % rim.size()]
		var na := Vector3(a.x - clampf(a.x, -hx, hx), 0, a.y - clampf(a.y, -hz, hz)).normalized()
		var nb := Vector3(b.x - clampf(b.x, -hx, hx), 0, b.y - clampf(b.y, -hz, hz)).normalized()
		var pa := Vector3(cx + a.x, 0, a.y)
		var pb := Vector3(cx + b.x, 0, b.y)
		g.quad(pa + Vector3.UP * bottom, pb + Vector3.UP * bottom, pb + Vector3.UP * (top - 0.03), pa + Vector3.UP * (top - 0.03), na, nb, nb, na)
		var ia := pa + Vector3.UP * top - na * 0.04
		var ib := pb + Vector3.UP * top - nb * 0.04
		g.quad(pa + Vector3.UP * (top - 0.03), pb + Vector3.UP * (top - 0.03), ib, ia, (na + Vector3.UP).normalized(), (nb + Vector3.UP).normalized(), (nb + Vector3.UP).normalized(), (na + Vector3.UP).normalized())
		g.tri(Vector3(cx, top, 0), ia, ib, Vector3.UP, Vector3.UP, Vector3.UP)


## Box with bevelled top edges (sides and top only), in the statue's frame.
static func _bevel_box(g: Geo, center: Vector3, half: Vector3, bevel: float) -> void:
	var y0 := center.y - half.y
	var y1 := center.y + half.y - bevel
	var y2 := center.y + half.y
	var outer := [Vector3(half.x, 0, half.z), Vector3(-half.x, 0, half.z), Vector3(-half.x, 0, -half.z), Vector3(half.x, 0, -half.z)]
	for i in 4:
		var a: Vector3 = outer[i]
		var b: Vector3 = outer[(i + 1) % 4]
		var out := ((a + b) * 0.5).normalized()
		out = Vector3(signf(out.x) if absf(a.x - b.x) < 0.001 else 0.0, 0, signf(out.z) if absf(a.z - b.z) < 0.001 else 0.0)
		var ia := a - Vector3(signf(a.x), 0, signf(a.z)) * bevel
		var ib := b - Vector3(signf(b.x), 0, signf(b.z)) * bevel
		var c := Vector3(center.x, 0, center.z)
		g.flat(c + a + Vector3.UP * y0, c + b + Vector3.UP * y0, c + b + Vector3.UP * y1, out)
		g.flat(c + a + Vector3.UP * y0, c + b + Vector3.UP * y1, c + a + Vector3.UP * y1, out)
		g.flat(c + a + Vector3.UP * y1, c + b + Vector3.UP * y1, c + ib + Vector3.UP * y2, (out + Vector3.UP).normalized())
		g.flat(c + a + Vector3.UP * y1, c + ib + Vector3.UP * y2, c + ia + Vector3.UP * y2, (out + Vector3.UP).normalized())
	var t := [Vector3(half.x - bevel, y2, half.z - bevel), Vector3(-half.x + bevel, y2, half.z - bevel), Vector3(-half.x + bevel, y2, -half.z + bevel), Vector3(half.x - bevel, y2, -half.z + bevel)]
	var c2 := Vector3(center.x, 0, center.z)
	g.flat(c2 + t[0], c2 + t[1], c2 + t[2], Vector3.UP)
	g.flat(c2 + t[0], c2 + t[2], c2 + t[3], Vector3.UP)


## Replaces the first blueprint statue (step `statue_blueprint`) with the traced one and a wide
## stone cap; the narrow UpperPlinth mesh is hidden (its collision stays).
static func statue_traced(town: Node3D) -> void:
	var statue: Node3D = town.get_node("WashingtonStatue")
	traced_bronze(statue)
	var upper: MeshInstance3D = statue.get_node("UpperPlinth")
	upper.hide()
	var cap := Geo.new()
	_bevel_box(cap, Vector3(0, 3.27, 0), Vector3(1.95, 0.23, 1.95), 0.06)
	_bevel_box(cap, Vector3(0, 3.06, 0), Vector3(2.05, 0.06, 2.05), 0.03)
	var stone: StandardMaterial3D = upper.material_override.duplicate()
	stone.vertex_color_use_as_albedo = false
	add_mesh(statue, "Statue cap", cap, stone)


## Replaces the statue's bronze mesh with the traced horse, rider and plate.
static func traced_bronze(statue: Node3D) -> void:
	remove(statue.get_node("Bronze horse and rider"))
	var g := Geo.new()
	traced_plate(g)
	traced_horse(g)
	traced_rider(g)
	var bronze := material(Color.WHITE, 0.55, 0.15)
	bronze.vertex_color_is_srgb = true
	add_mesh(statue, "Bronze horse and rider", g, bronze)


# --- Sculptural reference refinement (8 November 2026) -------------------------
## Catmull-Rom interpolation removes the angular transitions between anatomy rows.
static func _smooth_trace(g: Geo, rows: Array, z: float, up: Vector3, segs := 20) -> void:
	var smooth := []
	for i in rows.size() - 1:
		for j in 4:
			var t := j / 4.0
			var row := []
			for c in 4:
				var a: float = rows[maxi(0, i - 1)][c]
				var b: float = rows[i][c]
				var d: float = rows[i + 1][c]
				var e: float = rows[mini(rows.size() - 1, i + 2)][c]
				row.append(0.5 * (2*b + (-a+d)*t + (2*a-5*b+4*d-e)*t*t + (-a+3*b-3*d+e)*t*t*t))
			smooth.append(row)
	smooth.append(rows.back())
	_trace(g, smooth, z, up, maxi(segs, 20))

static func reference_horse(g: Geo) -> void:
	g.color = TRACE_BRONZE
	# Long barrel with a high rounded rump and deep chest; haunches and shoulders.
	_smooth_trace(g, [[795, 272, 12, 14], [803, 271, 27, 26], [818, 272, 36, 31], [845, 277, 37, 32], [880, 281, 35, 30],
		[915, 280, 35, 30], [948, 275, 36, 32], [970, 272, 33, 30], [984, 274, 24, 22], [991, 276, 10, 10]], 0, Vector3.UP, 22)
	for s in [1.0, -1.0]:
		_blob(g, 832, 280, 20 * s, Vector3(28, 31, 11))
		_blob(g, 958, 282, 19 * s, Vector3(20, 28, 10))
	_blob(g, 976, 277, 0, Vector3(16, 25, 27), Basis(), 18, 10)
	# Upright, thick neck rising from the withers; big head carried high, nose down.
	var neck := [[956, 272, 27, 32], [968, 248, 25, 28], [980, 220, 21, 25], [990, 194, 18, 23], [1004, 168, 16, 17]]
	_smooth_trace(g, neck, 0, Vector3.UP, 18)
	var head_from := g.verts.size()
	_smooth_trace(g, [[1002, 156, 17, 18], [1013, 174, 17.5, 21], [1024, 194, 15, 17], [1032, 210, 13.5, 13.5], [1036, 218, 10, 9]], 0, Vector3.UP, 20)
	_blob(g, 1009, 184, 0, Vector3(17, 19, 15.5))
	_blob(g, 1030, 210, 0, Vector3(13.5, 12.5, 14))
	# Smooth crest with chunky locks falling to the near side, and a forelock.
	var crest := [Vector3(948, 238, 0), Vector3(968, 214, 0), Vector3(985, 186, 0), Vector3(998, 164, 0), Vector3(1003, 152, 0)]
	_smooth_trace(g, [[948, 240, 7, 8], [968, 216, 8, 9], [985, 188, 8, 9], [998, 165, 7, 8], [1003, 153, 5, 5]], 0, Vector3.UP, 10)
	for i in 4:
		var a: Vector3 = crest[i].lerp(crest[i + 1], 0.5)
		_blob(g, a.x + 2, a.y + 6, 10, Vector3(9, 12, 6), Basis(Vector3.BACK, -0.9), 10, 6)
	_cord(g, [Vector3(1003, 149, 0), Vector3(1012, 150, 0), Vector3(1019, 159, 0)], 5, 8)
	for s in [1.0, -1.0]:
		g.color = TRACE_BRONZE
		_smooth_trace(g, [[1002, 153, 6, 4.5], [1001, 146, 4.5, 3.5], [999, 139, 0.8, 0.6]], 8 * s, Vector3.RIGHT, 8)
		g.color = TRACE_SHADE
		_blob(g, 1017, 173, 15.6 * s, Vector3(4, 3.6, 2.4), Basis(), 10, 6)
		_blob(g, 1040, 213, 6.5 * s, Vector3(1.8, 2.5, 1.6), Basis(), 6, 4)
	_shift(g, head_from, Vector3(0, -8 * TRACE_SCALE, 0))
	# Legs [x, y, half width, half depth]: near foreleg raised and curled, near hind leg back.
	g.color = TRACE_BRONZE
	var legs := [
		[16, [[832, 290, 14, 18], [826, 312, 11, 13], [818, 334, 6, 7], [816, 348, 5.5, 6], [816, 360, 8.5, 9], [816, 366, 7.5, 7.5]], Vector2(816, 16)],
		[-16, [[838, 290, 14, 18], [840, 312, 11, 13], [838, 334, 6, 7], [842, 348, 5.5, 6], [846, 360, 8.5, 9], [847, 366, 7.5, 7.5]], Vector2(848, -16)],
		[-15, [[958, 296, 13, 16], [957, 318, 10, 12], [957, 336, 6, 7], [958, 350, 5.5, 6], [960, 360, 8.5, 9], [961, 366, 7.5, 7.5]], Vector2(962, -15)],
		[15, [[960, 296, 13, 16], [972, 312, 10, 12], [985, 326, 9, 10], [979, 340, 7.5, 8], [972, 350, 8, 8.5]], null]]
	for leg in legs:
		_smooth_trace(g, leg[1], leg[0], Vector3.RIGHT, 14)
		g.color = TRACE_SHADE.lerp(TRACE_BRONZE, 0.55)
		var hoof = leg[2]
		if hoof == null:
			_blob(g, 967, 353, 15, Vector3(9, 6.5, 9.5), Basis(Vector3.BACK, 0.8), 12, 6)
		else:
			var at := _p(hoof.x, TRACE_GROUND, hoof.y)
			var k := TRACE_SCALE
			g.lathe(at, [Vector2(0, 0), Vector2(10.5 * k, 0), Vector2(10.6 * k, 4 * k), Vector2(9.5 * k, 8 * k), Vector2(8 * k, 10.5 * k), Vector2(0, 11 * k)], 18)
		g.color = TRACE_BRONZE
	# Thick, long wavy tail.
	_smooth_trace(g, [[800, 256, 6, 7], [791, 268, 9, 10], [786, 292, 10, 12.5], [790, 318, 9.5, 12], [785, 338, 8, 10], [778, 352, 5, 6], [774, 356, 1.5, 1.5]], 0, Vector3.RIGHT, 14)
	# Saddle blanket over the barrel with a gilt border; saddle with pommel and cantle.
	var xs := [850.0, 865.0, 880.0, 895.0, 910.0, 924.0]
	const ARC := 2.05
	var cols := 16
	var grid := []
	var ngrid := []
	for x in xs:
		var row := []
		var nrow := []
		for j in cols + 1:
			var a := lerpf(-ARC, ARC, float(j) / cols)
			row.append(_p(x, 280.5 - 31.5 * cos(a), 36.6 * sin(a)))
			nrow.append(Vector3(0, cos(a) / 31.5, sin(a) / 36.6).normalized())
		grid.append(row)
		ngrid.append(nrow)
	g.color = TRACE_BRONZE.darkened(0.08)
	for i in xs.size() - 1:
		for j in cols:
			g.quad(grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1], ngrid[i][j], ngrid[i + 1][j], ngrid[i + 1][j + 1], ngrid[i][j + 1])
	var border := []
	for j in cols + 1: border.append(grid[0][j])
	for i in range(1, xs.size()): border.append(grid[i][cols])
	for j in range(cols - 1, -1, -1): border.append(grid[xs.size() - 1][j])
	for i in range(xs.size() - 2, -1, -1): border.append(grid[i][0])
	g.color = TRACE_GILT
	_tube(g, border, 1.6 * TRACE_SCALE, 6, false)
	g.color = TRACE_BRONZE
	_blob(g, 886, 249, 0, Vector3(29, 6.5, 30), Basis(), 18, 6)
	_blob(g, 909, 244, 0, Vector3(6, 7, 11), Basis(), 10, 6)
	_blob(g, 862, 243, 0, Vector3(5, 8, 20), Basis(), 10, 6)
	# Gilt bridle: noseband, cheek straps, rosettes, bit rings; reins to both hands.
	g.color = TRACE_GILT
	var axis := Vector3(0.436, -0.9, 0).normalized()
	var perp := Vector3(0.9, 0.436, 0)
	var bridle_from := g.verts.size()
	var nose := _p(1026, 200)
	var loop := []
	for j in 21:
		var th := TAU * j / 20.0
		loop.append(nose + Vector3(0, 0, 16.2 * TRACE_SCALE) * cos(th) + perp * 16.8 * TRACE_SCALE * sin(th))
	_tube(g, loop, 1.5 * TRACE_SCALE, 6, false)
	for s in [1.0, -1.0]:
		_cord(g, [Vector3(1001, 156, 17.6 * s), Vector3(1010, 172, 18.4 * s), Vector3(1018, 188, 17.2 * s), Vector3(1023, 200, 16.2 * s)], 1.6)
		_blob(g, 1007, 165, 18.4 * s, Vector3(4, 4, 1.5), Basis(), 12, 5)
		var ring := []
		for j in 15:
			var th := TAU * j / 14.0
			ring.append(_p(1035, 211, 14 * s) + axis * 3.8 * TRACE_SCALE * cos(th) + perp * 3.8 * TRACE_SCALE * sin(th))
		_tube(g, ring, 1.1 * TRACE_SCALE, 5, false)
	_shift(g, bridle_from, Vector3(0, -8 * TRACE_SCALE, 0))
	for s in [1.0, -1.0]:
		_cord(g, [Vector3(934, 205, 17 * s), Vector3(962, 230, 28 * s), Vector3(990, 236, 27 * s), Vector3(1014, 227, 20 * s), Vector3(1034, 219, 14.5 * s)], 1.3, 6)


static func reference_rider(g: Geo) -> void:
	g.color = TRACE_BRONZE
	# Seat and a broad coat torso; coat skirts falling over the horse's back and flanks.
	_blob(g, 886, 240, 0, Vector3(22, 14, 26))
	_smooth_trace(g, [[885, 242, 26, 17], [887, 222, 28, 17], [890, 202, 30, 16], [892, 184, 29, 15], [893, 171, 19, 12]], 0, Vector3.RIGHT, 20)
	var skirt := []
	var skirt_n := []
	const SKIRT_ROWS := 5
	const SKIRT_COLS := 24
	for i in SKIRT_ROWS + 1:
		var t := float(i) / SKIRT_ROWS
		var row := []
		var nrow := []
		for j in SKIRT_COLS + 1:
			var th := lerpf(0.42 * PI, 1.58 * PI, float(j) / SKIRT_COLS)
			var side := absf(sin(th))
			var rx := lerpf(17.5, 33.0, t)
			var rz := lerpf(27.0, 37.0 + 2.0 * side, t)
			var y := lerpf(230.0, 247.0 + 16.0 * side, t)
			row.append(_p(887 + cos(th) * rx, y, sin(th) * rz))
			nrow.append(Vector3(cos(th) / rx, 0.35, sin(th) / rz).normalized())
		skirt.append(row)
		skirt_n.append(nrow)
	for i in SKIRT_ROWS:
		for j in SKIRT_COLS:
			g.quad(skirt[i][j], skirt[i + 1][j], skirt[i + 1][j + 1], skirt[i][j + 1], skirt_n[i][j], skirt_n[i + 1][j], skirt_n[i + 1][j + 1], skirt_n[i][j + 1])
			g.quad(skirt[i][j], skirt[i + 1][j], skirt[i + 1][j + 1], skirt[i][j + 1], -skirt_n[i][j], -skirt_n[i + 1][j], -skirt_n[i + 1][j + 1], -skirt_n[i][j + 1])
	var hem := []
	for p in skirt[SKIRT_ROWS]: hem.append(p)
	_tube(g, hem, 1.6 * TRACE_SCALE, 6)
	# Legs: thick thighs forward over the barrel, boots hanging down the flank to the belly line.
	for s in [1.0, -1.0]:
		g.color = TRACE_BRONZE
		_cord(g, [Vector3(888, 240, 15 * s), Vector3(902, 244, 30 * s), Vector3(915, 250, 41 * s)], 11.5, 12)
		g.color = TRACE_BRONZE.darkened(0.1)
		_smooth_trace(g, [[915, 251, 10, 10.5], [914, 270, 9.5, 10], [912, 286, 9, 9.5]], 44 * s, Vector3.RIGHT, 12)
		_blob(g, 915, 251, 43 * s, Vector3(12.5, 5.5, 12), Basis(), 12, 5)
		_blob(g, 921, 292, 45 * s, Vector3(13, 6, 7.5), Basis(), 12, 6)
		g.color = TRACE_SHADE.lerp(TRACE_BRONZE, 0.4)
		_cord(g, [Vector3(886, 252, 31 * s), Vector3(903, 274, 40 * s), Vector3(916, 292, 45 * s)], 1.3, 5)
	# Arms bent to the reins, cuffs and hands; gilt epaulettes, lapel piping and buttons.
	for s in [1.0, -1.0]:
		g.color = TRACE_BRONZE
		_cord(g, [Vector3(890, 184, 31 * s), Vector3(896, 198, 35 * s), Vector3(901, 211, 35 * s)], 9.5, 12)
		_cord(g, [Vector3(901, 211, 35 * s), Vector3(914, 209, 28 * s), Vector3(926, 206, 21 * s)], 8.5, 12)
		_blob(g, 921, 207, 24 * s, Vector3(5, 9, 9.5), Basis(Vector3.UP, 0.6 * s), 12, 6)
		_blob(g, 932, 205, 17.5 * s, Vector3(7, 6.5, 6.5), Basis(), 12, 6)
		_blob(g, 891, 180, 29 * s, Vector3(12, 4.5, 10), Basis(), 14, 6)
		for k in 9:
			var a := TAU * k / 9.0
			_cord(g, [Vector3(891 + cos(a) * 10.5, 182, (29 + sin(a) * 8.5) * s), Vector3(891 + cos(a) * 11.5, 190, (29 + sin(a) * 9.5) * s)], 1.6, 5)
		g.color = TRACE_GILT
		var rim := []
		for k in 17:
			var a := TAU * k / 16.0
			rim.append(Vector3(891 + cos(a) * 11.5, 181, (29 + sin(a) * 9.5) * s))
		_cord(g, rim, 1.1, 5, false)
		_cord(g, [Vector3(902, 178, 6 * s), Vector3(906, 200, 12 * s), Vector3(904, 232, 15 * s)], 1.3, 5)
		for k in 4:
			_blob(g, 906, 192 + k * 10, 7.5 * s, Vector3(1.6, 1.6, 1.6), Basis(), 8, 5)
	g.color = TRACE_BRONZE.lightened(0.04)
	_blob(g, 904, 172, 0, Vector3(7, 9, 9), Basis(), 12, 6)
	_blob(g, 906, 182, 0, Vector3(5, 6, 7), Basis(), 10, 6)
	g.color = TRACE_BRONZE
	var collar := []
	for k in 25:
		var a := TAU * k / 24.0
		collar.append(Vector3(894 + cos(a) * 12, 165 + 2.5 * cos(a), sin(a) * 13))
	_cord(g, collar, 4, 8, false)
	angular_portrait(g)
	# Tricorn: wide brim turned up between three corners (one forward), rolled edge, crown.
	var hat := _p(898, 115)
	const HAT_SEGS := 42
	var inner := []
	var outer := []
	var k := TRACE_SCALE
	for j in HAT_SEGS + 1:
		var th := TAU * j / HAT_SEGS
		var reach := (29.0 + 7.0 * cos(3.0 * th)) * k
		inner.append(hat + Vector3(cos(th) * 19.5 * k, 0.0, sin(th) * 19 * k))
		outer.append(hat + Vector3(cos(th) * reach, (14.0 - 10.0 * cos(3.0 * th)) * k, sin(th) * reach))
	for j in HAT_SEGS:
		var n: Vector3 = (outer[j] - inner[j]).cross(inner[j + 1] - inner[j]).normalized()
		g.quad(inner[j], outer[j], outer[j + 1], inner[j + 1], n, n, n, n)
		g.quad(inner[j], outer[j], outer[j + 1], inner[j + 1], -n, -n, -n, -n)
	_tube(g, outer, 2.0 * k, 6, false)
	g.ellipsoid(hat + Vector3(0, 10 * k, 0), Vector3(19.5, 20, 18.5) * k, Basis(), 18, 9)
	# Sword at the left hip.
	g.color = TRACE_SHADE.lerp(TRACE_BRONZE, 0.5)
	_cord(g, [Vector3(882, 236, -30), Vector3(866, 256, -38), Vector3(850, 276, -42)], 2.2, 6)
	g.color = TRACE_GILT
	_blob(g, 884, 233, -29, Vector3(3.5, 3.5, 3.5), Basis(), 8, 5)


static func statue_reference(town: Node3D) -> void:
	var statue: Node3D = town.get_node("WashingtonStatue")
	var previous := statue.get_node_or_null("Reference corner pilasters")
	if previous: remove(previous)
	remove(statue.get_node("Bronze horse and rider"))
	var g := Geo.new()
	traced_plate(g)
	reference_horse(g)
	reference_rider(g)
	# Flowing overlapping locks along the neck and tail, with bronze highlight ridges.
	g.color = TRACE_BRONZE.darkened(0.12)
	for i in 10:
		var x := 949.0 + i * 5.3
		var y := 245.0 - i * 8.7
		_smooth_trace(g, [[x+8,y-8,3,4], [x-3,y,5,6], [x-7,y+10,5,6], [x-2,y+17,3,4], [x-5,y+23,0.8,1]], 12, Vector3.RIGHT, 16)
	for i in 7:
		var z := (i - 3) * 2.5
		_smooth_trace(g, [[799,258,2,3], [784-i*0.5,282,3,4], [781+i*0.5,309,3,4], [773+i,334,2.5,3], [765+i,350,0.8,1]], z, Vector3.RIGHT, 14)
	g.color = TRACE_GILT
	for side in [-1.0, 1.0]:
		# Breast strap, saddle fringe, stirrup and boot trim.
		_cord(g, [Vector3(941,249,30*side), Vector3(968,266,32*side), Vector3(982,288,18*side)], 1.8)
		for i in 23:
			_cord(g, [Vector3(852+i*3,295,33*side), Vector3(852+i*3,301,33*side)], 0.65, 5)
		_cord(g, [Vector3(911,278,48*side), Vector3(906,293,51*side), Vector3(934,298,51*side), Vector3(933,288,48*side), Vector3(911,278,48*side)], 1.3)
		# A laurel sprig on each blanket flank.
		for i in 6:
			var y := 287.0-i*3
			_blob(g, 873-i*1.4, y, 36*side, Vector3(1.4,3,0.9), Basis(Vector3.BACK, -0.5), 8, 5)
			_blob(g, 879+i*1.4, y, 36*side, Vector3(1.4,3,0.9), Basis(Vector3.BACK, 0.5), 8, 5)
	# Warm aged bronze; restrained surface variation keeps the form legible in town sunlight.
	for i in g.cols.size():
		var c := g.cols[i]
		var warm := Color(c.r * 1.12, c.g * 0.90, c.b * 0.83, 1)
		var v := g.verts[i]
		var mottling := 0.0 if v.y > _p(898,175).y else sin(v.x*27 + sin(v.y*17))*sin(v.z*31+v.y*11)*0.025
		g.cols[i] = warm.lightened(mottling) if mottling > 0 else warm.darkened(-mottling)
	add_mesh(statue, "Bronze horse and rider", g, uniform_bronze_material())
	# Four corner pilasters give the existing pedestal the reference's carved stone rhythm.
	var stone := Geo.new()
	for x in [-1.94, 1.94]:
		for z in [-1.94, 1.94]:
			_bevel_box(stone, Vector3(x,1.65,z), Vector3(0.18,0.95,0.18), 0.035)
			for y in [0.73,2.55]:
				_bevel_box(stone, Vector3(x,y,z), Vector3(0.24,0.075,0.24), 0.035)
	add_mesh(statue, "Reference corner pilasters", stone, material(Color("d8bca0"), 0.86))


## Longer, planar portrait: broad forehead, cheek planes and a defined squared jaw.
## Rings use a rounded rectangle, rather than the former spherical head.
static func angular_portrait(g: Geo) -> void:
	var portrait_start := g.verts.size()
	g.color = TRACE_BRONZE
	_smooth_trace(g, [[895,172,7,7], [896,160,7,8], [898,153,8,9]], 0, Vector3.RIGHT)
	var rows := [[114,898,11,13], [121,898,12,14], [130,899,11.5,13], [138,900,11,12], [147,900,10,11], [154,901,8.5,10], [157,902,6,7]]
	var rings := []
	var normals := []
	for r in rows:
		var ring := []
		var ns := []
		for j in 24:
			var a := TAU*j/24.0
			var cx := cos(a)
			var sz := sin(a)
			ring.append(_p(r[1] + signf(cx)*pow(absf(cx),0.65)*r[3], r[0], signf(sz)*pow(absf(sz),0.65)*r[2]))
			ns.append(Vector3(signf(cx)*pow(absf(cx),1.35)/r[3], 0, signf(sz)*pow(absf(sz),1.35)/r[2]).normalized())
		rings.append(ring)
		normals.append(ns)
	for i in rows.size()-1:
		for j in 24:
			var k := (j+1)%24
			g.quad(rings[i][j],rings[i+1][j],rings[i+1][k],rings[i][k],normals[i][j],normals[i+1][j],normals[i+1][k],normals[i][k])
	for j in 24:
		g.tri(rings.back()[j], _p(902,158), rings.back()[(j+1)%24],Vector3.DOWN,Vector3.DOWN,Vector3.DOWN)
	# Brow, narrow straight nose, restrained lips and chin; relief seated in the face.
	_smooth_trace(g, [[912,129,2.0,1.8], [914,135,2.2,2.2], [915,141,2.6,2.4], [912,143,2.8,1.5]], 0, Vector3.RIGHT, 16)
	for side in [-1.0,1.0]:
		g.color = TRACE_SHADE
		_blob(g, 911.4,131,6.5*side,Vector3(1.1,1.3,1.8),Basis(),12,6)
		g.color = TRACE_BRONZE
		_cord(g,[Vector3(912,127,3*side),Vector3(912,126,6*side),Vector3(910.5,127,9*side)],1.0,8)
		_blob(g, 898,138,12*side,Vector3(2.7,4.8,2),Basis(),12,8)
	g.color = TRACE_SHADE.lerp(TRACE_BRONZE,0.35)
	_cord(g,[Vector3(911,148,-4),Vector3(911.5,148.5,0),Vector3(911,148,4)],0.45,6)
	# A fitted hair mass wraps the back of the skull; strand ridges follow swept arcs.
	g.color = TRACE_BRONZE.darkened(0.16)
	for side in [-1.0,1.0]:
		_blob(g,888,127,8*side,Vector3(8,13,7),Basis(),20,12)
		for strand in 12:
			var points := []
			for j in 13:
				var t := j/12.0
				var a := lerpf(0.2,2.6,t)
				var sweep := 0.3 + strand*0.22 + 0.3*t
				points.append(Vector3(888 + 8*sin(a)*cos(sweep), 127-13*cos(a), side*(8+7*sin(a)*sin(sweep))))
			g.color = TRACE_BRONZE.lightened(0.035 if strand%2==0 else 0.0)
			_cord(g,points,0.32,6)
		# Three layered wig rolls behind each ear, incised by closely spaced spiral ridges.
		for row in 3:
			var y := 134.0+row*7.0
			g.color = TRACE_BRONZE.darkened(0.12)
			_blob(g,886,y,12.5*side,Vector3(8,3.7,4.2),Basis(),20,10)
			var curl := []
			for j in 81:
				var t := j/80.0
				var angle := t*TAU*5
				var taper := sqrt(1.0-pow((14*t-7)/8.0,2))
				curl.append(Vector3(879+14*t,y+3.7*taper*cos(angle),side*(12.5+4.2*taper*sin(angle))))
			g.color = TRACE_BRONZE.lightened(0.04)
			_cord(g,curl,0.35,6)
	# Tied queue with lengthwise hair grooves.
	g.color = TRACE_BRONZE.darkened(0.14)
	_smooth_trace(g,[[883,141,4,4],[880,150,4.5,4],[878,161,3,3]],0,Vector3.RIGHT)
	for strand in 7:
		var angle := TAU*strand/7.0
		g.color = TRACE_BRONZE
		_cord(g,[Vector3(883+3*cos(angle),142,3*sin(angle)),Vector3(880+4*cos(angle),151,4*sin(angle)),Vector3(878+2.8*cos(angle),162,2.8*sin(angle))],0.5,6)
	g.color = TRACE_SHADE
	_blob(g,880,150,0,Vector3(3.8,1.7,5),Basis(),12,6)

	# Temple locks bridge the forehead to the side wig above and in front of each ear.
	for side in [-1.0,1.0]:
		_blob(g,900,123,11.4*side,Vector3(6,9,3.2),Basis(),20,12)
		for strand in 9:
			var points := []
			for j in 17:
				var t := j/16.0
				var a := lerpf(0.2,2.6,t)
				var sweep := 0.3+strand*0.28+0.25*t
				points.append(Vector3(900+6*sin(a)*cos(sweep),123-9*cos(a),side*(11.4+3.2*sin(a)*sin(sweep))))
			_cord(g,points,0.32,6)
	# Keep every relief feature and hair strand attached while adjusting the proportions.
	# Twelve percent wider across the face, eight percent shorter, anchored under the hat.
	var anchor := _p(898,114)
	var stretch := Vector3(1.04,0.92,1.12)
	for i in range(portrait_start,g.verts.size()):
		g.verts[i] = anchor + (g.verts[i]-anchor)*stretch
		g.norms[i] = (g.norms[i]/stretch).normalized()
		g.cols[i] = TRACE_BRONZE


## One finish for every part of the bronze: no gilt, dark hair or vertex-colour mottling.
static func uniform_bronze_material() -> StandardMaterial3D:
	var bronze := material(Color("796037"), 0.55, 0.35)
	bronze.vertex_color_use_as_albedo = false
	return bronze

static func uniform_statue_bronze(town: Node3D) -> void:
	var bronze: MeshInstance3D = town.get_node("WashingtonStatue/Bronze horse and rider")
	bronze.material_override = uniform_bronze_material()


# --- Cast-bronze finish from the user's Boston photograph (9 November 2026) -----------------
# One continuous material for the whole statue (no part colours, per `statue_single_bronze`):
# dark chocolate bronze, glossy where bare, with green-grey patina in patches and streaks.
# The mesh has no UVs, so both textures are projected from the three axes (triplanar); a
# smaller Y scale stretches the noise downward into rain-run streaks.

## [noise offset, colour] stops: deep shadow bronze, bare bronze, warm highlight, patina.
## Lifted on 9 Nov (step `statue_patina_warm`): the first values read near-black in town light.
const PATINA_RAMP := [[0.0, "3a2b1d"], [0.4, "523e2a"], [0.6, "6b5137"], [0.7, "5e5640"], [0.82, "5f6649"], [1.0, "6d7a5c"]]
## Roughness stops on the same noise: bare bronze glossy, patina dull.
const PATINA_ROUGH := [[0.0, 0.3], [0.62, 0.36], [0.78, 0.6], [1.0, 0.78]]

static func _patina_texture(stops: Array, grey: bool) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 1776
	noise.frequency = 0.02
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.55
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	ramp.colors = PackedColorArray(stops.map(func(s): return Color(s[1], s[1], s[1]) if grey else Color(s[1])))
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = ramp
	return texture

static func patina_bronze_material() -> StandardMaterial3D:
	var bronze := StandardMaterial3D.new()
	bronze.albedo_texture = _patina_texture(PATINA_RAMP, false)
	bronze.roughness_texture = _patina_texture(PATINA_ROUGH, true)
	bronze.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	bronze.roughness = 1.0
	bronze.metallic = 0.38    # 0.62 mirrored the blue sky (hat underside read pale blue)
	bronze.metallic_specular = 0.5
	bronze.uv1_triplanar = true
	bronze.uv1_triplanar_sharpness = 2.0
	bronze.uv1_scale = Vector3(0.55, 0.22, 0.55)
	bronze.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return bronze

static func patina_statue_bronze(town: Node3D) -> void:
	var bronze: MeshInstance3D = town.get_node("WashingtonStatue/Bronze horse and rider")
	bronze.material_override = patina_bronze_material()


# --- Town-style bronze (user, 9 Nov 2026: "look and feel like the rest of the game") --------
# Replaces the triplanar patina (`statue_patina*`): its noise blotches read as camouflage, its
# metallic sheen mirrored the sky. The town paints every prop with one plain colour and no
# metal (Main.material_for(), roughness 0.82); the statue keeps that rule with a dark olive
# bronze and a slightly lower roughness so its sculpted form still catches the sun. Picked from
# runtime swatches: matte #7d6a4a / #6e6447 / #806446 read as beige clay in sunlight; #4e5b45
# as a green toy soldier, #5f4a32 as chocolate.
const TOWN_BRONZE := Color("5c5236")

static func town_bronze_material() -> StandardMaterial3D:
	var bronze := material(TOWN_BRONZE, 0.6, 0.0)
	bronze.vertex_color_use_as_albedo = false    # one colour for the whole statue, as previewed
	return bronze

static func town_statue_bronze(town: Node3D) -> void:
	var bronze: MeshInstance3D = town.get_node("WashingtonStatue/Bronze horse and rider")
	bronze.material_override = town_bronze_material()
