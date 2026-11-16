extends "res://scripts/characters/lion_clay.gd"
## Clay-style giraffe traced from the user's "Giraffe Character Blueprint" turnaround (11 Nov
## 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for
## the zoo, built once by tools/build_giraffe_clay.gd into scenes/animals/giraffe_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd: ell, cone, carve, _mesh, _field).
## Shapes are written in the giraffe sheet's side-view pixels (x to the right = toward the tail,
## y down, z lateral, + = the side facing the viewer) and R() scales them into the lion's working
## space, so the giraffe comes out GH town units tall at the same 3 cm clay resolution. The orange
## patches, chest bib and pale belly are painted on the finished skin (_tints, _paint), not
## modelled. Eyes, lashes, nostrils and mouth are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const GH := 4.4                 # town units, the zoo giraffe's display height (park_animals.gd)
const GY := 390.0               # sheet y of the hooves' soles
const GTOP := 87.0              # sheet y of the top of the horn knobs
const GX := 762.0               # sheet x placed at the model origin
const K := GH / ((GY - GTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet, then deepened so they read as the sheet's under the town's
# bright daylight (first zoo render came out pale, 11 Nov 2026).
const YELLOW := Color("ecb450")
const SPOT := Color("c0621f")
const G_MUZZLE := Color("efd198")
const BIB := Color("ebc983")
const BELLY := Color("eebf68")
const G_MANE := Color("6e3519")
const G_MANE_CREASE := Color("4f2410")
const TUFT := Color("733a17")
const HOOF := Color("6f4226")
const KNOB := Color("70391c")
const STALK := Color("dc9f3c")
const EAR_IN := Color("d98074")
const EYE := Color("180d07")
const GLINT := Color("fffdf8")
const LASH := Color("23130b")
const NOSTRIL := Color("9a5a34")
const MOUTH := Color("8f5530")

var _tints := []


## Sheet pixel -> working space (y up).
static func R(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - GX) * K, (GY - y) * K, z * K)


func e(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * K, col, k * K, crease, basis)


func cn(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * K, rb * K, col, k * K)


func limb(g: Array, pts: Array, radii: Array, col: Color, k: float) -> void:
	for i in pts.size() - 1:
		cn(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else 2.0)


func _gleg(b: Array, joints: Array, radii: Array, hoof: Vector3, tilt: float) -> void:
	limb(b, joints, radii, YELLOW, 10.0)
	var last: float = radii[radii.size() - 1]
	cn(b, joints[joints.size() - 1], hoof, last, last, YELLOW, 2.0)
	e(b, hoof, Vector3(12.0, 8.5, 12.0), HOOF, 0.5, false, Basis(Vector3(0, 0, 1), tilt))


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: compact and round, deepest at the chest, the back sloping down to the rump.
	e(b, R(742, 283), Vector3(38, 36, 37), YELLOW)
	e(b, R(768, 287), Vector3(44, 33, 38), YELLOW, 14.0)
	e(b, R(792, 291), Vector3(35, 32, 36), YELLOW, 14.0)
	for side in [-1.0, 1.0]:
		e(b, R(728, 290, side * 19.0), Vector3(16, 20, 15), YELLOW, 10.0)   # shoulders
		e(b, R(806, 293, side * 19.0), Vector3(20, 24, 17), YELLOW, 10.0)   # haunches
	# Neck: long, leaning forward, thick at the withers and slim under the head.
	limb(b, [R(738, 264), R(724, 236), R(713, 208), R(705, 181), R(697, 160)], [28.0, 23.0, 19.5, 17.5, 17.0], YELLOW, 16.0)
	# Head: round skull, short cream muzzle.
	e(b, R(679, 146), Vector3(30, 31, 32), YELLOW, 8.0)
	e(b, R(671, 161), Vector3(17, 18, 26), YELLOW, 6.0)   # cheeks
	e(b, R(645, 160.5), Vector3(16, 17, 20), G_MUZZLE, 5.0)
	# Horns: tan stalks, slightly splayed and leaning back, with round brown knobs.
	for side in [-1.0, 1.0]:
		cn(b, R(690, 122, side * 14.0), R(693, 101, side * 17.5), 6.2, 5.2, STALK, 3.0)
		e(b, R(693.5, 95.5, side * 18.0), Vector3(8.5, 8.5, 8.5), KNOB, 1.5)
	# Legs, relaxed walk: near front planted, far front lifted forward, far hind under the
	# belly, near hind trailing. Plain yellow with brown hooves.
	_gleg(b, [R(733, 298, 19), R(736, 338, 19), R(739, 366, 19)], [14.5, 12.0, 10.0], R(740, 381.5, 19), 0.0)
	_gleg(b, [R(714, 298, -19), R(702, 332, -19), R(682, 359, -19)], [14.0, 11.5, 10.0], R(673, 371, -19), -0.6)
	_gleg(b, [R(810, 298, 20), R(821, 338, 20), R(832, 371, 20)], [16.0, 12.5, 10.0], R(834, 381.5, 20), 0.15)
	_gleg(b, [R(786, 302, -20), R(792, 338, -20), R(775, 367, -20)], [15.0, 12.0, 10.0], R(769, 380.5, -20), -0.35)
	# Tail: thin, swung out behind.
	limb(b, [R(820, 279), R(833, 286), R(844, 296), R(851, 307)], [5.0, 4.2, 3.8, 3.5], YELLOW, 6.0)
	# Tail tuft: a brown teardrop.
	var lean := Basis(Vector3(0, 0, 1), 0.45)
	e(_tuft, R(857, 317), Vector3(12.5, 16, 11), TUFT, 0.0, true, lean)
	for side in [-1.0, 1.0]:
		e(_tuft, R(858, 322, side * 4.5), Vector3(8, 12, 7), TUFT, 2.0, true, lean)
	cn(_tuft, R(859, 321), R(866, 335), 7.5, 2.2, TUFT, 5.0)

	# Ears: leaf-shaped cups out to the sides, a little up and back; yellow outside, pink inside.
	for side in [-1.0, 1.0]:
		var along := Vector3(0.5, 0.45, side * 0.74).normalized()
		var open := Vector3(-0.8, -0.1, side * 0.55)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var c := R(713, 119, side * 44.0)
		e(_ears, c, Vector3(5.5, 12.0, 21.0), YELLOW, 0.0, false, basis)
		e(_ears, c + along * 13.0 * K, Vector3(4.5, 7.0, 11.5), YELLOW, 4.0, false, basis)
		carve(_ears, c + open * 5.0 * K + along * 1.0 * K, Vector3(4.2, 6.8, 14.5) * K, EAR_IN, basis)

	# Mane: a single row of round brown bumps from the forelock between the horns, over the
	# back of the head and down the neck to the withers.
	for m in [[686, 112, 7.5], [699, 117, 8.0], [710, 127, 8.5], [719, 142, 9.0], [725, 159, 9.0], [729, 177, 9.0],
			[731, 195, 9.0], [733, 213, 9.0], [737, 229, 9.0], [744, 241, 8.5], [752, 249, 7.5]]:
		e(_mane, R(m[0], m[1]), Vector3(m[2], m[2], m[2] * 0.85), G_MANE, 2.0, true)

	# Painted areas: chest bib and belly first, patches over them.
	_tint(R(704, 292), Vector3(17, 30, 15) * K, Basis(), BIB, CELL * 2.5)
	_tint(R(750, 322), Vector3(40, 8, 14) * K, Basis(), BELLY, CELL * 2.5)
	var id := 0
	for side in [-1.0, 1.0]:
		# Flank patches as seen in the side view: [x, y, radius along, radius up].
		for s in [[708, 195, 10, 13], [698, 211, 3.5, 3.5], [714, 229, 12, 12.5], [737, 252, 11, 10], [711, 262, 9, 12],
				[738, 281, 13, 10], [733, 300, 4.5, 4], [765, 279, 11, 12], [780, 285, 10, 11], [798, 271, 10, 7],
				[795, 297, 12, 12], [815, 304, 5, 9], [814, 283, 5, 7], [773, 262, 8, 4.5]]:
			id += 1
			var shift := Vector2.ZERO if side > 0.0 else Vector2(_h(3, id, 1), _h(3, id, 2)) * 2.0
			_spot(R(s[0] + shift.x, s[1] + shift.y, side * 90.0), Vector3(0, 0, -side), s[2], s[3], id)
		# Seen from behind: beside the mane on the neck, and on the rump either side of the tail.
		for s in [[197, 11, 4, 8], [235, 14, 5, 9], [272, 17, 12, 9]]:
			id += 1
			_spot(R(900, s[0], side * s[1]), Vector3(-1, 0, 0), s[2], s[3], id)


func _tint(c: Vector3, r: Vector3, basis: Basis, col: Color, soft := CELL * 0.35) -> void:
	_tints.append({"t": "ell", "c": c, "r": r, "inv": basis.inverse(), "col": col, "soft": soft})


## Paints a rounded, slightly irregular patch where the ray from `from` along `dir` meets the
## skin: a main ellipse (rx, ry sheet pixels) and two smaller lobes off-centre.
func _spot(from: Vector3, dir: Vector3, rx: float, ry: float, id: int) -> void:
	var hit := _hit(from, dir)
	var n: Vector3 = hit[1]
	var t1 := Vector3.UP.cross(n)
	if t1.length() < 0.2: t1 = Vector3.RIGHT.cross(n)
	t1 = t1.normalized()
	var t2 := n.cross(t1).normalized()
	if absf(dir.x) > 0.5:
		# Seen from behind: rx is across (lateral), ry is up.
		var swap := t1; t1 = t2; t2 = swap
		var keep := rx; rx = ry; ry = keep
	var basis := Basis(t1, t2, t1.cross(t2).normalized())
	_tint(hit[0], Vector3(rx, ry, 9.0) * K, basis, SPOT)
	if minf(rx, ry) < 6.0: return
	for j in 2:
		var off := t1 * rx * 0.48 * _h(7, id, j) + t2 * ry * 0.48 * _h(8, id, j)
		var s := 0.68 + 0.12 * _h(9, id, j)
		_tint(hit[0] + off * K, Vector3(rx * s, ry * s, 9.0) * K, basis, SPOT)


## First point of the body's skin along a ray (working space): [point, outward normal].
func _hit(from: Vector3, dir: Vector3) -> Array:
	var p := from
	var d := dir.normalized()
	for i in 1500:
		var f := _field(_body, p)
		if f <= 0.0: break
		p += d * maxf(f * 0.5, 0.15)
	var h := 0.5
	var n := Vector3(
		_field(_body, p + Vector3(h, 0, 0)) - _field(_body, p - Vector3(h, 0, 0)),
		_field(_body, p + Vector3(0, h, 0)) - _field(_body, p - Vector3(0, h, 0)),
		_field(_body, p + Vector3(0, 0, h)) - _field(_body, p - Vector3(0, 0, h))).normalized()
	return [p, n]


## Drops a point near the face onto the skin along -n.
func _on_skin(p: Vector3, n: Vector3) -> Vector3:
	var q := p + n * 8.0 * K
	for i in 400:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.15
	return q


## Recolours the finished skin where the painted ellipsoids reach it. The patches' edges are
## finer than the clay's 3 cm vertex spacing, so triangles an edge crosses are split in four,
## twice (refined 11 Nov 2026; about 0.75 cm along the edges, the rest of the skin untouched).
func _paint(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var base: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var reach := []
	for t in _tints:
		var r: Vector3 = t.r
		var m := maxf(r.x, maxf(r.y, r.z)) + CELL * 2.0
		reach.append(m * m)
	var cols := PackedColorArray()
	var edge := PackedFloat32Array()   # how far inside a crisp patch each vertex is (0..1)
	for i in verts.size():
		cols.append(_tinted(verts[i], base[i], reach))
		edge.append(_crisp)
	for pass_i in 2:
		var out := PackedInt32Array()
		var mids := {}
		for t in range(0, idx.size(), 3):
			var a := idx[t]
			var b := idx[t + 1]
			var c := idx[t + 2]
			var lo := minf(edge[a], minf(edge[b], edge[c]))
			var hi := maxf(edge[a], maxf(edge[b], edge[c]))
			if hi - lo < 0.2:
				out.append(a); out.append(b); out.append(c)
				continue
			var ab := _mid(a, b, mids, verts, norms, base, cols, edge, reach)
			var bc := _mid(b, c, mids, verts, norms, base, cols, edge, reach)
			var ca := _mid(c, a, mids, verts, norms, base, cols, edge, reach)
			out.append_array(PackedInt32Array([a, ab, ca, ab, b, bc, ca, bc, c, ab, bc, ca]))
		idx = out
	var built := []
	built.resize(Mesh.ARRAY_MAX)
	built[Mesh.ARRAY_VERTEX] = verts
	built[Mesh.ARRAY_NORMAL] = norms
	built[Mesh.ARRAY_COLOR] = cols
	built[Mesh.ARRAY_INDEX] = idx
	var out_mesh := ArrayMesh.new()
	out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, built)
	return out_mesh


var _crisp := 0.0

## Colour of the skin at model-space point v; leaves the crisp-patch coverage in _crisp.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var soft: float = t.soft
		var w := clampf(0.5 - _dist(t, p) / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


## Vertex at the middle of edge a-b (shared between the triangles that split it).
func _mid(a: int, b: int, mids: Dictionary, verts: PackedVector3Array, norms: PackedVector3Array, base: PackedColorArray, cols: PackedColorArray, edge: PackedFloat32Array, reach: Array) -> int:
	var key := Vector2i(mini(a, b), maxi(a, b))
	if mids.has(key): return mids[key]
	var v := (verts[a] + verts[b]) * 0.5
	var bc := base[a].lerp(base[b], 0.5)
	verts.append(v)
	norms.append((norms[a] + norms[b]).normalized())
	base.append(bc)
	cols.append(_tinted(v, bc, reach))
	edge.append(_crisp)
	mids[key] = verts.size() - 1
	return verts.size() - 1


# --- Face details -------------------------------------------------------------------------

const EYE_AT := Vector2(145.0, 23.0)        # sheet y and lateral offset of the eye centres
const EYE_R := Vector3(7.5, 7.0, 2.6)       # across the skin, up, bulge (sheet px)
const SCLERA_G := Color("f3eadb")

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _eye_frame(side: float) -> Array:
	var hit := _hit(R(590, EYE_AT.x, side * EYE_AT.y), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Eyes (reworked against the sheet's eye close-ups, 11 Nov 2026): round, glossy, near-black
## ovals a little taller than wide, a sliver of warm white showing at the outer corner, and one
## small soft catch-light high on the inner side.
func _giraffe_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		g.color = SCLERA_G
		g.ellipsoid(s + (out * 0.8 + n * 0.1) * K, Vector3(EYE_R.x * 0.95, EYE_R.y * 0.93, 2.1) * K, frame, 28, 14)
		g.color = EYE
		g.ellipsoid(s + (out * -0.35 + n * 0.25) * K, EYE_R * K, frame, 32, 16)
		var w := Vector2(-1.9, 3.0)
		var h := EYE_R.z * sqrt(maxf(1.0 - pow((w.x + 0.35) / EYE_R.x, 2.0) - pow(w.y / EYE_R.y, 2.0), 0.0))
		g.color = GLINT
		g.ellipsoid(s + (out * w.x + up * w.y + n * (h + 0.3)) * K, Vector3(1.25, 1.25, 0.35) * K, frame, 16, 8)
	return _to_model(g)


## Lid lines with lashes, nostrils and the smile.
func _giraffe_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Upper lid: a thick dark line over the top of the eye that sweeps on past the outer
		# corner as a wing, [out, up, half-width], ending in three short lashes.
		g.color = LASH
		var lid := []
		var lid_w := []
		for q in [[-5.9, 4.3, 0.45], [-3.4, 6.3, 0.9], [0.3, 7.25, 1.15], [3.8, 6.9, 1.15], [6.8, 6.0, 1.05], [9.8, 5.5, 0.9], [12.6, 5.3, 0.6]]:
			lid.append(_on_skin(s + (out * q[0] + up * q[1]) * K, n) + n * 0.75 * K)
			lid_w.append(Vector2(q[2], q[2]) * K)
		g.loft(lid, lid_w, n, 8)
		for lash in [[Vector2(8.6, 5.9), Vector2(9.6, 9.3)], [Vector2(10.6, 5.6), Vector2(12.6, 8.6)], [Vector2(12.2, 5.3), Vector2(15.2, 6.6)]]:
			var pts := []
			for t in [0.0, 0.5, 1.0]:
				var q: Vector2 = (lash[0] as Vector2).lerp(lash[1], t) + Vector2(0, 0.5 * sin(PI * t))
				pts.append(_on_skin(s + (out * q.x + up * q.y) * K, n) + n * 0.75 * K)
			g.loft(pts, [Vector2(0.7, 0.7) * K, Vector2(0.55, 0.55) * K, Vector2(0.25, 0.25) * K], n, 6)
		# Nostril: a small slanted oval on top of the muzzle.
		var nh := _hit(R(590, 157.5, side * 10.0), Vector3(1, 0, 0))
		var nn: Vector3 = nh[1]
		var nr := Vector3.UP.cross(nn).normalized()
		var nf := Basis(nr, nn.cross(nr).normalized(), nn) * Basis(Vector3(0, 0, 1), -side * 0.5)
		g.color = NOSTRIL
		g.ellipsoid(nh[0] - nn * 0.2 * K, Vector3(2.7, 1.9, 0.9) * K, nf, 14, 7)
	# Smile: a gentle upturned curve round the lower muzzle.
	var curve := []
	var widths := []
	for i in 13:
		var t := (i - 6) / 6.0
		var h := _hit(R(590, 172.5 - 4.5 * t * t, t * 14.5), Vector3(1, 0, 0))
		curve.append(h[0] + h[1] * 0.25 * K)
		var w := (0.95 - 0.45 * t * t) * K
		widths.append(Vector2(w, w))
	g.color = MOUTH
	g.loft(curve, widths, Vector3.UP, 6)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i])
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	_body.clear(); _mane.clear(); _tuft.clear(); _ears.clear(); _tints.clear()
	_shape()
	var root := Node3D.new()
	root.name = "GiraffeClayDisplay"
	root.set_meta("source", "User's Giraffe Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	var hair := _material(0.95)
	hair.metallic_specular = 0.2
	for part in [["Body", _body, YELLOW, 7.0], ["Mane", _mane, G_MANE_CREASE, 9.0], ["Tail tuft", _tuft, G_MANE_CREASE, 7.0], ["Ears", _ears, YELLOW, 7.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		mi.material_override = clay if part[0] in ["Body", "Ears"] else hair
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _giraffe_eyes()
	eyes.material_override = _material(0.22)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _giraffe_details()
	face.material_override = _material(0.7)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body, neck and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(R(628, GY, -40))
	var c := to_model(R(868, GTOP, 40))
	var lo := a.min(c)
	var hi := a.max(c)
	box.size = hi - lo
	shape.shape = box
	shape.position = (lo + hi) * 0.5
	body.add_child(shape)
	root.add_child(body)
	for child in root.get_children():
		child.owner = root
		for grand in child.get_children():
			grand.owner = root
	return root
