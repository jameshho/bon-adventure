extends "res://scripts/characters/cow_clay.gd"
## Clay-style duck traced from the user's "Duck Character Blueprint" turnaround (11 Nov 2026,
## "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model, built
## once by tools/build_duck_clay.gd into scenes/animals/duck_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd: _tint, _paint) and the clay cow's helpers (cow_clay.gd: _ray, _dome), and
## lays feathers on the skin the way the clay flamingo does (flamingo_clay.gd: _feather).
## Shapes are written in the duck sheet's side-view pixels (x to the right = toward the tail,
## y down, z lateral, + = the side facing the viewer) and V() scales them into the lion's
## working space. The duck is small (0.45 town units), so it is meshed DF times larger than
## life and shrunk afterwards: the clay grid is 3 cm / DF on the finished model.
## The bill (upper and lower), crest, wings, tail and legs are separate clay pieces; the blush
## is painted; eyes, their outline, the brows and the nostrils are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const DH := 0.45                # town units to the top of the crest (park_animals.gd: Duck)
const DY := 550.0               # sheet y of the soles
const DTOP := 181.0             # sheet y of the top of the crest
const DX := 955.0               # sheet x placed at the model origin
const DF := 12.0                # meshed this many times larger than life
const DK := DF * DH / ((DY - DTOP) * S)   # sheet pixel -> lion working unit

const D_CREAM := Color("f6e6d0")
const D_CREAM_CREASE := Color("e2cbaa")
const D_WING := Color("f7e8d3")
const D_WING_CREASE := Color("e0c9a8")
const D_BILL := Color("f0a23a")
const D_BILL_LOW := Color("e48f2c")
const D_BILL_CREASE := Color("c9761f")
const D_NOSTRIL := Color("a9651f")
const D_MOUTH := Color("a85a18")
const D_LEG := Color("eea136")
const D_LEG_CREASE := Color("d68824")
const D_BLUSH := Color("f4aaa2")
const D_BROW := Color("6a5342")
const D_SCLERA := Color("f8f1e6")
const D_IRIS := Color("24140c")
const D_PUPIL := Color("0c0706")
const D_LID := Color("2b1c14")

# Eyes (sheet px): height and lateral offset of the centre; half-sizes measured in the side
# view (22 x 31; the front view shows 19 across).
const D_EYE_Y := 264.0
const D_EYE_Z := 42.0
const D_EYE_R := Vector2(12.0, 14.2)

## Legs as [sheet x, lateral z]: walking, the far one a step ahead of the near one.
const D_LEGS := [[926.0, -36.0], [977.0, 36.0]]

var _bill_low := []
var _wings := []
var _tail := []
var _legs := []


## Sheet pixel -> working space (y up).
static func V(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - DX) * DK, (DY - y) * DK, z * DK)


func de(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * DK, col, k * DK, crease, basis)


func dc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * DK, rb * DK, col, k * DK)


## Rotation about the lateral axis: positive raises the tail end of a shape.
static func tilt(a: float) -> Basis:
	return Basis(Vector3(0, 0, 1), a)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Head: a big ball, a little wider than long, fullest low down at the cheeks.
	de(b, V(901, 268), Vector3(68, 62, 67), D_CREAM)
	for side in [-1.0, 1.0]:
		de(b, V(906, 286, side * 32.0), Vector3(52, 44, 42), D_CREAM, 14.0)
	# Neck: short and thick, flaring into the chest.
	dc(b, V(898, 318), V(902, 366), 42.0, 60.0, D_CREAM, 14.0)
	# Body: an egg lying back, with a full chest and a rump that rises to the tail.
	de(b, V(955, 421), Vector3(118, 77, 78), D_CREAM, 22.0)
	de(b, V(893, 401), Vector3(58, 66, 66), D_CREAM, 22.0)
	for side in [-1.0, 1.0]:
		de(b, V(915, 385, side * 32.0), Vector3(50, 42, 40), D_CREAM, 16.0)      # round shoulders
	de(b, V(1024, 408), Vector3(50, 50, 56), D_CREAM, 24.0)
	de(b, V(952, 459), Vector3(84, 46, 66), D_CREAM, 20.0)       # the broad, flat-bottomed belly

	# Bill: a thin, softly tapered spoon. The upper half is wide and deep at the face, with a
	# hump between the eyes, and thins to a rounded tip; its underside is cut along the mouth
	# surface (_mouth_y), which rises toward the corners for the smile. The lower half is a
	# slim, shorter lip tucked under it.
	var m := _muzzle
	de(m, V(838, 286), Vector3(24, 12.5, 37), D_BILL)
	de(m, V(842, 279), Vector3(20, 21, 21), D_BILL, 10.0)
	de(m, V(814, 288), Vector3(28, 11.5, 36), D_BILL, 10.0)
	de(m, V(793, 287), Vector3(19, 10.5, 30), D_BILL, 8.0, false, tilt(-0.12))
	carve(m, V(862, 354), Vector3(150, 60, 160) * DK, D_BILL)
	de(_bill_low, V(822, 301), Vector3(27, 8, 33), D_BILL_LOW, 0.0, false, tilt(0.07))

	# Crest: three soft fingers swept up and back off the crown, the middle one highest.
	de(_mane, V(905, 194), Vector3(21, 8.5, 7.5), D_CREAM, 0.0, true, tilt(0.55))
	for side in [-1.0, 1.0]:
		de(_mane, V(913, 200, side * 11.5), Vector3(26, 8.5, 7.5), D_CREAM, 1.5, true, Basis(Vector3(0, 1, 0), -side * 0.12) * tilt(0.12))
	de(_mane, V(906, 208), Vector3(22, 6, 16), D_CREAM, 3.0)

	_wing_feathers()

	# Tail: a fan of short rounded tufts turned up off the rump.
	var t := _tail
	de(t, V(1080, 368), Vector3(20, 12, 13), D_WING, 3.0, true, tilt(0.8))
	de(t, V(1087, 390), Vector3(19, 12, 17), D_WING, 3.0, true, tilt(0.45))
	de(t, V(1080, 413), Vector3(18, 12, 19), D_WING, 3.0, true, tilt(0.1))
	de(t, V(1064, 392), Vector3(20, 28, 22), D_WING, 6.0)

	# Legs: short thick stalks; webbed feet with three rounded toes, splayed a little outward.
	var g := _legs
	for leg in D_LEGS:
		var x: float = leg[0]
		var z: float = leg[1]
		var s := signf(z)
		dc(g, V(x, 488, z), V(x + 2.0, 536, z + s * 2.0), 13.5, 12.0, D_LEG)
		for toe in [[-51.0, 8.0], [-43.0, 28.0], [-44.0, -11.0]]:
			dc(g, V(x - 2.0, 540, z + s * 3.0), V(x + toe[0], 541.5, z + s * toe[1]), 12.5, 11.0, D_LEG, 5.0)
		de(g, V(x - 27.0, 545, z + s * 9.0), Vector3(27, 5.5, 20), D_LEG, 4.0)
		de(g, V(x + 4.0, 541, z + s * 2.0), Vector3(10, 8.5, 10), D_LEG, 5.0)
	for leg in D_LEGS:
		carve(g, V(leg[0] - 20.0, DY + 40.0, leg[1]), Vector3(140, 40, 140) * DK, D_LEG)

	# Blush: a soft round patch on each cheek, below and behind the eye.
	for side in [-1.0, 1.0]:
		_tint(V(877, 290, side * 58.0), Vector3(15.5, 14, 15.5) * DK, Basis(), D_BLUSH, CELL * 3.0)


## One feather: a flattened puff laid on the body's skin where a ray from the side meets it at
## sheet (x, y). r = half length, half width, half thickness (sheet px); `a` turns it in the
## side view (negative lowers the tail end); `lift` raises its middle off the skin.
func _feather(x: float, y: float, side: float, r: Vector3, a: float, col: Color, lift: float, k := 2.0, crease := true) -> void:
	var hit := _ray(_body, V(x, y, side * 200.0), Vector3(0, 0, -side))
	var n: Vector3 = hit[1]
	var d := Vector3(cos(a), sin(a), 0.0)
	var flat := (d - n * d.dot(n)).normalized()
	de(_wings, hit[0] + n * lift * DK, r, col, k, crease, Basis(flat, n.cross(flat).normalized(), n))


## Wings: a thick smooth pad on each flank, rounded at the shoulder, with three rows of
## round-ended feathers showing from under it toward the tail (lowest layer first).
func _wing_feathers() -> void:
	for side in [-1.0, 1.0]:
		# Lower row, along the wing's bottom edge to its tip.
		for f in [[946, 432, Vector3(21, 18, 9.0), -1.15], [974, 433, Vector3(23, 17, 9.0), -0.7], [1002, 424, Vector3(25, 16, 9.0), -0.35],
				[1028, 406, Vector3(25, 14, 9.0), -0.05]]:
			_feather(f[0], f[1], side, f[2], f[3], D_WING, 7.0, 4.0)
		# Upper row, showing from under the shoulder pad.
		for f in [[984, 410, Vector3(24, 16, 9.5), -0.45], [1012, 396, Vector3(25, 14, 9.5), -0.1]]:
			_feather(f[0], f[1], side, f[2], f[3], D_WING, 8.5, 4.0)
		_feather(940, 388, side, Vector3(36, 38, 13.0), -0.6, D_WING, 10.0, 12.0, false)
		_feather(978, 386, side, Vector3(38, 21, 11.5), 0.05, D_WING, 10.0, 12.0, false)


# --- Face details -------------------------------------------------------------------------

## Drops a point near the face onto the skin along -n, then lifts it `lift` sheet px.
func _ddrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * DK
	for i in 4000:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * DK


## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _duck_eye_frame(side: float) -> Array:
	var hit := _ray(_body, V(700, D_EYE_Y, side * D_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Eyes, from the sheet's front, 3/4 and side views: a tall upright oval set in the face and
## only gently domed, almost filled by a glossy black pupil inside a very dark brown iris that
## sits toward the bill, leaving a thin white crescent down the outer side; one round
## catch-light high in the pupil.
func _duck_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _duck_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		var edge := 0.0
		for q in [Vector2(D_EYE_R.x, 0), Vector2(-D_EYE_R.x, 0), Vector2(0, D_EYE_R.y), Vector2(0, -D_EYE_R.y)]:
			edge += (_ddrop(s + (out * q.x + up * q.y) * DK, n, 0.0) - s).dot(n) / DK * 0.25
		var white_h := edge - 0.2
		var white := Vector3(D_EYE_R.x, D_EYE_R.y, 2.6 - white_h)
		g.color = D_SCLERA
		g.ellipsoid(s + n * white_h * DK, (white - Vector3(0.5, 0.5, 0.0)) * DK, frame, 40, 20)
		var io := Vector2(-1.8, 0.5)
		var iris := Vector3(9.8, 13.0, 1.6)
		var iris_h := white_h + _dome(white, io.x, io.y) - iris.z + 0.8
		g.color = D_IRIS
		g.ellipsoid(s + (out * io.x + up * io.y + n * iris_h) * DK, iris * DK, frame, 40, 20)
		var po := io + Vector2(0.0, 0.3)
		var pupil := Vector3(8.9, 12.1, 1.3)
		var pupil_h := iris_h + _dome(iris, 0.0, 0.3) - pupil.z + 0.3
		g.color = D_PUPIL
		g.ellipsoid(s + (out * po.x + up * po.y + n * pupil_h) * DK, pupil * DK, frame, 36, 18)
		var go := Vector2(0.4, 6.3)
		g.color = D_SCLERA
		g.ellipsoid(s + (out * (po.x + go.x) + up * (po.y + go.y) + n * (pupil_h + _dome(pupil, go.x, go.y) + 0.15)) * DK,
				Vector3(3.4, 3.6, 0.45) * DK, frame, 20, 10)
	return _to_model(g)


## Sheet y of the mouth surface (the cut under the upper bill) at sheet x and lateral z.
static func _mouth_y(x: float, z: float) -> float:
	return 354.0 - 60.0 * sqrt(1.0 - pow((x - 862.0) / 150.0, 2.0) - pow(z / 160.0, 2.0))


## Eye outlines, eyebrows, nostrils and the mouth line.
func _duck_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _duck_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Outline: a dark line right round the eye, heavier over the top.
		g.color = D_LID
		var lid := []
		var lid_w := []
		for i in 33:
			var a := TAU * i / 32.0 - PI * 0.5        # starts and ends under the eye
			var q := Vector2(cos(a) * D_EYE_R.x, sin(a) * D_EYE_R.y)
			lid.append(_ddrop(s + (out * q.x + up * q.y) * DK, n, 0.9))
			var top := clampf(sin(a) * 0.5 + 0.5, 0.0, 1.0)
			lid_w.append(Vector2(lerpf(1.0, 1.8, top * top), 0.7) * DK)
		g.loft(lid, lid_w, n, 8)
		# Eyebrow: a short soft arc well above the eye, its outer end lower.
		g.color = D_BROW
		var brow := []
		var brow_w := []
		for q in [[-9.0, 30.6, 1.1], [-5.0, 32.8, 1.9], [0.0, 33.8, 2.3], [5.0, 33.2, 2.2], [9.5, 31.0, 1.8], [12.5, 28.2, 1.0]]:
			brow.append(_ddrop(s + (out * q[0] + up * q[1]) * DK, n, 0.2))
			brow_w.append(Vector2(q[2], 0.9) * DK)
		g.loft(brow, brow_w, n, 10)
		# Nostril: a tiny dark dot on the slope of the bill's hump, near its base.
		var hit := _ray(_muzzle, V(829, 180, side * 10.0), Vector3(0, -1, 0))
		var bn: Vector3 = hit[1]
		var along := (Vector3(1, 0, 0) - bn * bn.x).normalized()
		g.color = D_NOSTRIL
		g.ellipsoid(hit[0] + bn * 0.1 * DK, Vector3(1.9, 1.5, 0.5) * DK, Basis(along, bn.cross(along).normalized(), bn), 16, 8)
		# Mouth line: a fine dark line in the groove between the two halves, along the side
		# (rising to the corner at the face) and round the front under the tip.
		g.color = D_MOUTH
		var both: Array = _muzzle + _bill_low
		var line := []
		var line_w := []
		for x in [842.0, 837.0, 832.0, 827.0, 822.0, 817.0, 812.0, 807.0, 802.0]:
			var at := _ray(both, V(x, _mouth_y(x, 30.0) + 0.7, side * 90.0), Vector3(0, 0, -side))
			line.append(at[0] + at[1] * 0.3 * DK)
			line_w.append(Vector2(1.1, 0.6) * DK)
		g.loft(line, line_w, Vector3(0, 0, side), 6)
		line = []
		line_w = []
		for a in [76.0, 66.0, 56.0, 46.0, 36.0, 26.0, 16.0, 8.0, 0.0]:
			var t := deg_to_rad(a)
			var y := _mouth_y(798.0, 28.0 * sin(t)) + 0.7
			var from := V(812.0 - 70.0 * cos(t), y, side * 70.0 * sin(t))
			var at := _ray(both, from, V(812, y) - from)
			line.append(at[0] + at[1] * 0.3 * DK)
			line_w.append(Vector2(1.1, 0.6) * DK)
		g.loft(line, line_w, Vector3(-0.7, 0, 0.7 * side), 6)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / DF
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= DF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _muzzle_tints, _bill_low, _wings, _tail, _legs]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "DuckClayDisplay"
	root.set_meta("source", "User's Duck Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, D_CREAM_CREASE, 7.0], ["Bill", _muzzle, D_BILL_CREASE, 5.0], ["Bill lower", _bill_low, D_BILL_CREASE, 5.0],
			["Crest", _mane, D_CREAM_CREASE, 5.0], ["Wings", _wings, D_WING_CREASE, 2.2], ["Tail", _tail, D_WING_CREASE, 3.0],
			["Legs", _legs, D_LEG_CREASE, 5.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Bill": _muzzle_tints}.get(part[0], [])
		if not paints.is_empty():
			var body_tints := _tints
			_tints = paints
			mi.mesh = _paint(mi.mesh)
			_tints = body_tints
		mi.mesh = _fit(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _duck_eyes()
	eyes.material_override = _material(0.12)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _duck_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(V(790, DY, -80)) / DF
	var c := to_model(V(1090, DTOP, 80)) / DF
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
