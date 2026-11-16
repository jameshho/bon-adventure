extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style deer traced from the user's "Deer Character Blueprint" turnaround (11 Nov 2026,
## "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for the
## zoo, built once by tools/build_deer_clay.gd into scenes/animals/deer_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd) and the clay giraffe's skin
## painting (giraffe_clay.gd: _tint, _paint, _hit, _on_skin). Shapes are written in the deer
## sheet's side-view pixels (x to the right = toward the tail, y down, z lateral, + = the side
## facing the viewer). The deer is small, so it is meshed DK/0.5 times larger than life (the
## lion's 3 cm clay grid becomes about 1.9 cm on the deer) and _fit() scales the finished meshes
## down to DH town units. Cream face, bib, belly, blush and the white back spots are painted on
## the finished skin; eyes, lids, lashes, brows, nose and mouth are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const DH := 2.0                 # town units to the top of the antlers (head top about 1.62)
const DY := 588.0               # sheet y of the hooves' soles
const DTOP := 125.0             # sheet y of the top of the antlers
const DX := 960.0               # sheet x placed at the model origin
const DK := 0.8                 # sheet pixel -> working unit while meshing
const FIT := DH / ((DY - DTOP) * DK * S)   # meshed size -> display size

# Colours sampled from the sheet's mid-tones (not its highlights), a little deepened for the
# town's bright daylight as with the giraffe.
const COAT := Color("ee9840")
const D_CREAM := Color("f8dcb2")
const D_SPOT := Color("fde9cb")
const D_HOOF := Color("633a22")
const D_HOOF_CLEFT := Color("3f2314")
const D_EAR := Color("b96c31")
const D_EAR_IN := Color("f8bfae")
const D_EAR_DEEP := Color("ef9484")
const ANTLER_BASE := Color("cd8c4e")
const ANTLER_MID := Color("e3ab6c")
const ANTLER_TOP := Color("f4d09c")
const D_TAIL := Color("f9dfb8")
const D_TAIL_CREASE := Color("ecc79a")
const BLUSH := Color("f4a78d")
const D_NOSE := Color("4f2d18")
const D_NOSTRIL := Color("2c170b")
const D_BROW := Color("8c4c24")
const D_LINE := Color("1f0f08")        # lid line and lashes
const D_MOUTH := Color("6a3c22")
const D_EYE := Color("1b0b05")
const D_EYE_LOW := Color("5c2f16")     # warm brown the eye shades to along its lower edge
const D_RIM := Color("3a1d10")         # thin outline under the eye
const D_SCLERA := Color("fbf4ea")

# Eyes (sheet px), from the sheet's front and side views: glossy near-black ovals, taller than
# wide, a crescent of white on the outer side, one round catch-light high on the inner side.
const D_EYE_AT := Vector2(268.5, 33.0)        # sheet y and lateral offset of the eye centres
const D_EYE_R := Vector3(9.3, 11.6, 5.4)      # across the skin, up, bulge (a clear dome, so the eye reads from the side)

var _antlers := []
var _tail := []
var _ear_tints := []   # the pink hollows, painted on the finished ears like the skin's tints


## Sheet pixel -> working space (y up).
static func D(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - DX) * DK, (DY - y) * DK, z * DK)


func de(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * DK, col, k * DK, crease, basis)


func dc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * DK, rb * DK, col, k * DK)


func dlimb(g: Array, pts: Array, radii: Array, col: Color, k: float) -> void:
	for i in pts.size() - 1:
		dc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else 2.0)


## A leg down to a cloven hoof: two dark toes side by side (their meeting line is the cleft),
## a little wider than the leg; _fit() flattens the soles on the ground.
func _dleg(b: Array, joints: Array, radii: Array, hoof_x: float, z: float) -> void:
	dlimb(b, joints, radii, COAT, 12.0)
	for t in [-1.0, 1.0]:
		de(b, D(hoof_x - 2.0, DY - 11.0, z + t * 9.0), Vector3(24, 16, 14.5), D_HOOF, 1.0, true)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: round chest, level back, full round rump, wide hips.
	de(b, D(885, 402), Vector3(46, 52, 48), COAT)
	de(b, D(958, 405), Vector3(64, 53, 50), COAT, 14.0)
	de(b, D(1035, 405), Vector3(52, 52, 52), COAT, 14.0)
	for side in [-1.0, 1.0]:
		de(b, D(885, 425, side * 30.0), Vector3(26, 34, 24), COAT, 10.0)    # shoulders
		de(b, D(1048, 420, side * 34.0), Vector3(36, 44, 30), COAT, 10.0)   # haunches
	# Neck: thick, upright, leaning a little forward.
	dlimb(b, [D(890, 385), D(876, 345), D(867, 310), D(862, 285)], [46.0, 41.0, 38.0, 36.0], COAT, 16.0)
	# Head: wide round skull, full low cheeks, short muzzle with a tucked chin.
	de(b, D(848, 254), Vector3(46, 44, 50), COAT, 8.0)
	de(b, D(796, 291), Vector3(31, 24, 27), COAT, 16.0)
	de(b, D(812, 304), Vector3(30, 16, 34), COAT, 14.0)
	for side in [-1.0, 1.0]:
		de(b, D(838, 290, side * 28.0), Vector3(32, 28, 30), COAT, 16.0)
	# Legs, relaxed walk: front pair nearly straight (far one a step ahead), near hind trailing,
	# far hind forward under the belly.
	_dleg(b, [D(882, 430, 34), D(884, 500, 34), D(884, 550, 34)], [26.0, 21.0, 19.0], 886.0, 34.0)
	_dleg(b, [D(872, 430, -34), D(866, 500, -34), D(862, 550, -34)], [26.0, 21.0, 19.0], 862.0, -34.0)
	_dleg(b, [D(1055, 430, 36), D(1084, 488, 36), D(1093, 530, 36), D(1094, 552, 36)], [37.0, 25.0, 20.0, 19.0], 1092.0, 36.0)
	_dleg(b, [D(1035, 440, -36), D(1040, 505, -36), D(1018, 550, -36)], [32.0, 23.0, 19.0], 1012.0, -36.0)

	# Ears (reworked against the sheet's ear close-ups, 11 Nov 2026): big leaves out to the
	# sides and a little back. The upper edge runs nearly straight out to a rounded tip at the
	# upper outer corner; the lower edge bellies down and curves back to the head. Brown outside
	# with a thick rounded rim round the pink hollow, which faces forward and a little outward.
	for side in [-1.0, 1.0]:
		var along := Vector3(0.6, 0.15, side * 0.78).normalized()
		var open := Vector3(-0.85, 0.0, side * 0.5)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var upv: Vector3 = basis.y * (1.0 if basis.y.y > 0.0 else -1.0)   # across the ear, upward
		var root := D(883, 236, side * 46.0)
		de(_ears, root + along * 30.0 * DK, Vector3(8.0, 23.0, 30.0), D_EAR, 0.0, false, basis)
		de(_ears, root + (along * 40.0 + upv * 11.0) * DK, Vector3(7.5, 12.0, 31.0), D_EAR, 10.0, false, basis)
		de(_ears, root + (along * 57.0 + upv * 9.0) * DK, Vector3(7.0, 10.5, 23.0), D_EAR, 12.0, false, basis)
		for h in [[along * 32.0 + upv * 1.0, Vector3(4.0, 15.5, 24.0)], [along * 48.0 + upv * 7.0, Vector3(4.0, 8.5, 24.0)]]:
			var hollow: Vector3 = root + ((h[0] as Vector3) + open * 8.5) * DK
			carve(_ears, hollow, (h[1] as Vector3) * DK, D_EAR, basis)
			_ear_tints.append({"t": "ell", "c": hollow, "r": ((h[1] as Vector3) + Vector3(2.0, 2.0, 2.0)) * DK, "inv": basis.inverse(), "col": D_EAR_IN, "soft": CELL * 0.6})
		# Deeper pink toward the base and the upper edge, fading out across the hollow.
		_ear_tints.append({"t": "ell", "c": root + (along * 20.0 + upv * 8.0 + open * 6.0) * DK, "r": Vector3(8.0, 9.0, 16.0) * DK, "inv": basis.inverse(), "col": D_EAR_DEEP, "soft": 22.0 * DK})

	# Antlers: fat rounded velvet branches. A stem up and out from the crown, a short tine
	# forward and inward, the main beam up (tip curling in) and a tine out and back. Darker at
	# the stem, pale at the tips.
	for side in [-1.0, 1.0]:
		var a := _antlers
		dlimb(a, [D(866, 224, side * 21), D(868, 195, side * 34), D(870, 178, side * 46), D(876, 165, side * 56)], [11.0, 11.0, 11.5, 12.0], ANTLER_BASE, 0.0)
		dlimb(a, [D(869, 187, side * 40), D(852, 177, side * 32), D(840, 172, side * 28)], [10.5, 11.0, 11.0], ANTLER_MID, 5.0)
		dlimb(a, [D(876, 165, side * 56), D(886, 150, side * 60)], [12.0, 12.5], ANTLER_MID, 5.0)
		dlimb(a, [D(886, 150, side * 60), D(896, 137, side * 55)], [12.5, 12.0], ANTLER_TOP, 5.0)
		dlimb(a, [D(877, 166, side * 57), D(898, 160, side * 72)], [11.5, 11.5], ANTLER_MID, 5.0)
		dlimb(a, [D(898, 160, side * 72), D(916, 155, side * 83)], [11.5, 11.0], ANTLER_TOP, 5.0)

	# Tail: a big soft cream pom on the rump, faintly lobed.
	de(_tail, D(1091, 372), Vector3(30, 30, 30), D_TAIL)
	for i in 4:
		var ang := TAU * i / 4.0 + 0.6
		de(_tail, D(1097, 372 + 12.0 * sin(ang), 12.0 * cos(ang)), Vector3(21, 21, 21), D_TAIL, 9.0, true)

	# Painted areas. Cream lower face (everything under the eye line, round the blush and down
	# under the jaw), bib down the front of the neck and chest, belly, and between the hind legs.
	var edge := CELL * 0.6
	_tint(D(800, 316), Vector3(50, 38, 150) * DK, Basis(), D_CREAM, edge)
	_tint(D(836, 360), Vector3(27, 60, 34) * DK, Basis(), D_CREAM, edge)
	_tint(D(846, 405), Vector3(36, 62, 40) * DK, Basis(), D_CREAM, edge)
	_tint(D(970, 472), Vector3(46, 42, 300) * DK, Basis(), D_CREAM, edge)
	_tint(D(1095, 437), Vector3(40, 36, 27) * DK, Basis(), D_CREAM, edge)
	for side in [-1.0, 1.0]:
		var cheek := _hit(D(700, 288, side * 47.0), Vector3(1, 0, 0))
		_tint(cheek[0], Vector3(8.5, 8.5, 8.5) * DK, Basis(), BLUSH, 10.0 * DK)
		# White spots along the back and over the haunch, as seen in the side view:
		# [x, y, radius along the body, radius up].
		for s in [[927, 366, 10, 8], [957, 362, 8, 3.5], [985, 361, 9, 4], [1023, 360, 17, 8], [967, 378, 13, 9],
				[1002, 380, 10, 7], [1040, 388, 10, 9.5], [1053, 374, 7, 5.5]]:
			_dspot(D(s[0], s[1], side * 120.0), Vector3(0, 0, -side), s[2], s[3])


## Paints one clean oval where the ray from `from` along `dir` meets the skin. The radii are as
## seen from the side, so the upright one is lengthened where the skin turns toward the sky.
func _dspot(from: Vector3, dir: Vector3, rx: float, ry: float) -> void:
	var hit := _hit(from, dir)
	var n: Vector3 = hit[1]
	if _field(_body, hit[0]) > 1.0: return   # the ray missed the body
	var t1 := Vector3.UP.cross(n)
	if t1.length() < 0.2: t1 = Vector3.RIGHT
	t1 = t1.normalized()
	var t2 := n.cross(t1).normalized()
	ry /= clampf(absf(n.z), 0.5, 1.0)
	_tint(hit[0], Vector3(rx, ry, 9.0) * DK, Basis(t1, t2, t1.cross(t2).normalized()), D_SPOT)


# --- Face details -------------------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _deer_eye_frame(side: float) -> Array:
	var hit := _hit(D(700, D_EYE_AT.x, side * D_EYE_AT.y), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	# The sheet shows a full oval from the front and from the side, so the eye is turned a
	# little further out than the skin under it (about 30 deg -> 40 deg off the front).
	n = n.rotated(Vector3.UP, -side * deg_to_rad(10.0))
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Outline of the whole eye (dark oval plus the white crescent beside it) at angle `a` from the
## outer corner, in (out, up) sheet px about the eye's centre, pushed out by `grow`.
static func _eye_outline(a: float, grow: float) -> Vector2:
	var t := (cos(a) + 1.0) * 0.5
	return Vector2(lerpf(-0.9, 1.2, t) + (lerpf(D_EYE_R.x, 10.6, t) + grow) * cos(a), (D_EYE_R.y + grow) * sin(a))


## Eyes (reworked against the sheet's close-ups, 11 Nov 2026): domed glossy ovals, near-black
## shading to warm brown along the lower edge, the white showing as a crescent on the outer side,
## one round catch-light high on the inner side.
func _deer_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _deer_eye_frame(side)
		var s: Vector3 = f[0] + (f[1] as Vector3) * 0.4 * DK
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		g.color = D_SCLERA
		g.ellipsoid(s + (out * 1.2 - n * 0.6) * DK, Vector3(10.6, 11.5, 3.6) * DK, frame, 32, 14)
		var dark := s + (out * -0.9 - n * 0.3) * DK
		g.color = D_EYE
		var first := g.verts.size()
		g.ellipsoid(dark, D_EYE_R * DK, frame, 40, 20)
		for i in range(first, g.verts.size()):
			var q: Vector3 = g.verts[i] - dark
			var u := q.dot(up) / (D_EYE_R.y * DK)
			var rim := Vector2(q.dot(out) / (D_EYE_R.x * DK), u).length()
			g.cols[i] = D_EYE.lerp(D_EYE_LOW, smoothstep(-0.1, -0.9, u) * smoothstep(0.35, 0.95, rim))
		var w := Vector2(-2.0, 4.6)
		var h := D_EYE_R.z * sqrt(maxf(1.0 - pow(w.x / D_EYE_R.x, 2.0) - pow(w.y / D_EYE_R.y, 2.0), 0.0))
		g.color = GLINT
		g.ellipsoid(dark + (out * w.x + up * w.y + n * (h + 0.05)) * DK, Vector3(2.5, 2.5, 0.6) * DK, frame, 18, 8)
		g.ellipsoid(dark + (out * 2.6 + up * -5.4 + n * (D_EYE_R.z * 0.83)) * DK, Vector3(0.9, 0.9, 0.3) * DK, frame, 10, 5)
	return _to_model(g)


## Lid lines with lashes, eyebrows, nose and the smile.
func _deer_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _deer_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Upper lid: a thick dark line hugging the top of the eye from the inner corner round
		# to the outer one, ending in three short thick lashes; a thin brown line under the eye
		# closes the outline.
		g.color = D_LINE
		var lid := []
		var lid_w := []
		for i in 22:
			var t := i / 21.0
			var o := _eye_outline(deg_to_rad(lerpf(168.0, 0.0, t)), 0.5)
			lid.append(_on_skin(s + (out * o.x + up * o.y) * DK, n) + n * 1.5 * DK)
			var lw := (0.55 + 1.2 * pow(sin(PI * minf(t * 1.15, 1.0)), 0.6)) * DK
			lid_w.append(Vector2(lw, lw))
		g.loft(lid, lid_w, n, 8)
		for lash in [[58.0, Vector2(2.6, 5.6)], [38.0, Vector2(5.4, 4.0)], [18.0, Vector2(6.2, 1.4)]]:
			var from := _eye_outline(deg_to_rad(lash[0]), 0.8)
			var pts := []
			for t in [0.0, 0.5, 1.0]:
				var q: Vector2 = from + (lash[1] as Vector2) * t + Vector2(0, 0.8 * sin(PI * t))
				pts.append(_on_skin(s + (out * q.x + up * q.y) * DK, n) + n * 1.2 * DK)
			g.loft(pts, [Vector2(1.15, 1.15) * DK, Vector2(1.0, 1.0) * DK, Vector2(0.45, 0.45) * DK], n, 6)
		g.color = D_RIM
		var under := []
		var under_w := []
		for i in 9:
			var o := _eye_outline(deg_to_rad(-8.0 - 164.0 * i / 8.0), 0.3)
			under.append(_on_skin(s + (out * o.x + up * o.y) * DK, n) + n * 0.9 * DK)
			var uw := (0.3 + 0.3 * sin(PI * i / 8.0)) * DK
			under_w.append(Vector2(uw, uw))
		g.loft(under, under_w, n, 6)
		# Eyebrow: a short brown arc high over the eye, thickest toward the nose.
		# [lateral, sheet y, half-width]
		g.color = D_BROW
		var brow := []
		var brow_w := []
		for q in [[41.5, 243.0, 1.4], [37.0, 238.2, 2.7], [32.5, 235.6, 3.3], [28.0, 235.6, 3.2], [24.0, 237.8, 2.0]]:
			var h := _hit(D(700, q[1], side * q[0]), Vector3(1, 0, 0))
			brow.append(h[0] + h[1] * 0.1 * DK)
			brow_w.append(Vector2(q[2], 0.45) * DK)
		g.loft(brow, brow_w, n, 8)
	# Nose: a wide dark rounded triangle over the tip of the muzzle, flat on top, coming to a
	# soft point below; two faint nostrils.
	var nose_c := D(771, 284)
	var nose_r := Vector3(10.5, 11.5, 15.5) * DK
	g.color = D_NOSE
	var first := g.verts.size()
	g.ellipsoid(nose_c, nose_r, Basis(), 28, 14)
	for i in range(first, g.verts.size()):
		var q: Vector3 = g.verts[i] - nose_c
		var yn := clampf(q.y / nose_r.y, -1.0, 1.0)
		var taper := lerpf(0.3, 1.0, pow((yn + 1.0) * 0.5, 0.6))
		if q.y > 0.0: q.y *= 0.8
		g.verts[i] = nose_c + Vector3(q.x, q.y, q.z * taper)
		var nn: Vector3 = g.norms[i]
		g.norms[i] = Vector3(nn.x, nn.y, nn.z / taper).normalized()
	g.color = D_NOSTRIL
	for side in [-1.0, 1.0]:
		g.ellipsoid(nose_c + Vector3(-8.2, -2.6, side * 6.8) * DK, Vector3(1.6, 1.5, 1.9) * DK, Basis(), 10, 5)
	# Mouth: a short line down from the nose, then a smile that dips either side of it and
	# lifts to the corners on the cheeks.
	g.color = D_MOUTH
	var philtrum := []
	for y in [297.0, 302.0, 307.0]:
		var h := _hit(D(700, y, 0.0), Vector3(1, 0, 0))
		philtrum.append(h[0] + h[1] * 0.3 * DK)
	g.loft(philtrum, [Vector2(0.9, 0.9) * DK, Vector2(0.9, 0.9) * DK, Vector2(0.9, 0.9) * DK], Vector3(0, 0, 1), 6)
	var curve := []
	var widths := []
	for i in 21:
		var t := (i - 10) / 10.0
		var u := absf(t)
		var h := _hit(D(700, 307.0 + 19.7 * u - 27.7 * u * u, t * 29.0), Vector3(1, 0, 0))
		curve.append(h[0] + h[1] * 0.3 * DK)
		var w := (1.0 - 0.5 * u * u) * DK
		widths.append(Vector2(w, w))
	g.loft(curve, widths, Vector3.UP, 6)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

## Scales a meshed part down to the display size and flattens anything under the ground (the
## hooves' soles).
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		var v := verts[i] * FIT
		v.y = maxf(v.y, 0.0)
		verts[i] = v
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


func build_display() -> Node3D:
	_body.clear(); _ears.clear(); _antlers.clear(); _tail.clear(); _tints.clear(); _ear_tints.clear()
	_shape()
	var root := Node3D.new()
	root.name = "DeerClayDisplay"
	root.set_meta("source", "User's Deer Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	var soft := _material(0.95)
	soft.metallic_specular = 0.25
	for part in [["Body", _body, D_HOOF_CLEFT, 2.5, clay], ["Ears", _ears, D_EAR, 7.0, clay],
			["Antlers", _antlers, ANTLER_BASE, 7.0, soft], ["Tail", _tail, D_TAIL_CREASE, 6.0, soft]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		var mesh := _mesh(part[1], part[2], part[3])
		if part[0] == "Body":
			mesh = _paint(mesh)
		elif part[0] == "Ears":
			var skin_tints := _tints
			_tints = _ear_tints
			mesh = _paint(mesh)
			_tints = skin_tints
		mi.mesh = _fit(mesh)
		mi.material_override = part[4]
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _fit(_deer_eyes())
	eyes.material_override = _material(0.16)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _fit(_deer_details())
	face.material_override = _material(0.6)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body, neck and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(D(758, DY, -45)) * FIT
	var c := to_model(D(1124, 212, 45)) * FIT
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
