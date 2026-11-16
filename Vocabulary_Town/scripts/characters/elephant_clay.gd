extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style elephant traced from the user's "Elephant Character Blueprint" turnaround (11 Nov
## 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for
## the zoo, built once by tools/build_elephant_clay.gd into scenes/animals/elephant_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd) and the clay giraffe's skin
## painting and ray helpers (giraffe_clay.gd: _tint, _paint, _hit, _on_skin, _to_model). Shapes
## are written in the elephant sheet's side-view pixels (x to the right = toward the tail, y
## down, z lateral, + = the side facing the viewer) and T() scales them into the lion's working
## space, so the elephant comes out EH town units tall at the same 3 cm clay resolution.
## Tusks, toenails and soles are cream parts of the body; the ears are thin membranes inside a
## thick rolled rim with the pink painted on their front faces; eyes, lashes, brows, trunk
## wrinkles and the smile are small parts laid on the skin.
## Output faces -Z (head), +Y up, ground at y = 0.

const EH := 3.15                # town units, the zoo elephant's display height (park_animals.gd)
const EGY := 543.0              # sheet y of the soles
const ETOP := 184.0             # sheet y of the top of the ears
const EX := 1005.0              # sheet x placed at the model origin
const EK := EH / ((EGY - ETOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet, then deepened so they read as the sheet's under the town's
# bright daylight (the first zoo render came out pale pink-white, 11 Nov 2026).
const GREY := Color("82757a")
const GREY_CREASE := Color("6f6368")
const EAR_PINK_E := Color("de7768")
const IVORY := Color("dcc698")
const TAIL_TUFT := Color("5f473d")
const E_IRIS := Color("4e2b18")
const E_PUPIL := Color("1c0f0a")
const E_SCLERA := Color("fbf7f0")
const E_LINE := Color("2b1a14")
const E_BROW := Color("62565a")
const E_WRINKLE := Color("6a5e63")
const E_MOUTH := Color("5a4446")

# Ears, in the ear's own plane (u = out from the head along the ear, y = sheet y): the outline
# is the edge of these ovals together, [u, y, radius along, radius up]: the big fan and the
# three scallops of the lower edge.
const EAR_OVALS := [[78.0, 258.0, 78.0, 74.0], [128.0, 300.0, 24.0, 22.0], [86.0, 326.0, 26.0, 22.0], [38.0, 338.0, 30.0, 22.0]]
const EAR_PINKS := [[71.0, 258.0, 65.0, 58.0], [124.0, 296.0, 20.0, 17.0], [86.0, 318.0, 21.0, 18.0], [40.0, 330.0, 25.0, 18.0]]
const EAR_ROOT := Vector2(915.0, 56.0)   # sheet x and lateral offset where the ear leaves the head
const EAR_SWEEP := Vector2(0.5, 0.866)   # the ear runs this much back and out per unit of u (30 degrees back)

# Eyes (sheet px on the skin): outward from the nose, up.
const E_EYE_Y := 274.0
const E_EYE_Z := 51.0
const E_EYE_R := Vector2(13.3, 14.8)
const E_IRIS_C := Vector2(-1.7, 0.3)
const E_IRIS_R := Vector2(10.7, 13.5)
const E_PUPIL_R := Vector2(5.6, 7.1)


## Sheet pixel -> working space (y up).
static func T(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - EX) * EK, (EGY - y) * EK, z * EK)


func eb(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, basis := Basis()) -> void:
	ell(g, c, r * EK, col, k * EK, false, basis)


func tube(g: Array, pts: Array, radii: Array, col: Color, k: float, k_rest := 3.0) -> void:
	for i in pts.size() - 1:
		cone(g, pts[i], pts[i + 1], radii[i] * EK, radii[i + 1] * EK, col, (k if i == 0 else k_rest) * EK)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: one round barrel, flat along the back and full at the rump.
	eb(b, T(1095, 328), Vector3(95, 98, 100), GREY)
	eb(b, T(1040, 322), Vector3(72, 90, 92), GREY, 24.0)
	eb(b, T(1135, 322), Vector3(65, 95, 98), GREY, 24.0)
	eb(b, T(955, 300), Vector3(50, 62, 64), GREY, 22.0)                     # neck
	# Head: a tall domed skull over broad round cheeks.
	eb(b, T(890, 258), Vector3(64, 70, 76), GREY, 18.0)
	eb(b, T(884, 312), Vector3(54, 44, 82), GREY, 22.0)
	# Trunk: thick at the brow, straight down the front, the tip curled back.
	tube(b, [T(838, 310), T(812, 338), T(797, 367), T(797, 402), T(801, 435), T(811, 461), T(826, 469), T(838, 463), T(843, 454)],
			[34.0, 29.0, 24.0, 21.5, 18.5, 16.0, 13.5, 12.0, 11.5], GREY, 16.0, 4.0)
	eb(b, T(844, 452), Vector3(12.5, 10.0, 12.5), GREY, 3.0)
	eb(b, T(848, 354), Vector3(14, 9, 22), GREY, 6.0)                       # lower lip
	for side in [-1.0, 1.0]:
		# Tusks: short, curving down, forward and a little outward, from a soft socket.
		eb(b, T(849, 332, side * 45.0), Vector3(16, 14, 14), GREY, 8.0)
		tube(b, [T(852, 334, side * 45.0), T(827, 349, side * 51.0), T(803, 357, side * 57.0), T(788, 355, side * 62.0)],
				[12.0, 11.5, 9.5, 6.5], IVORY, 1.0, 1.0)
	# Legs, relaxed walk: near front reaching forward, far front planted, near hind trailing.
	_eleg(b, [T(1012, 395, 49), T(955, 455, 49), T(910, 505, 49)], [40.0, 35.0, 33.0], T(895, 526, 49))
	_eleg(b, [T(1008, 395, -49), T(1004, 460, -49), T(1003, 510, -49)], [38.0, 32.0, 31.0], T(1001, 527, -49))
	_eleg(b, [T(1150, 390, 52), T(1170, 450, 52), T(1180, 510, 52)], [44.0, 36.0, 33.0], T(1181, 527, 52))
	_eleg(b, [T(1115, 395, -52), T(1100, 455, -52), T(1097, 510, -52)], [42.0, 35.0, 32.0], T(1095, 527, -52))
	# Tail: thin, hanging off the rump and swung a little back.
	tube(b, [T(1188, 312), T(1200, 345), T(1208, 378), T(1213, 402)], [9.0, 7.0, 6.0, 5.5], GREY, 8.0)
	# Tail tuft: a dark brown teardrop.
	var lean := Basis(Vector3(0, 0, 1), 0.4)
	ell(_tuft, T(1221, 420), Vector3(9.5, 15.0, 8.5) * EK, TAIL_TUFT, 0.0, false, lean)
	cone(_tuft, T(1224, 428), T(1232, 444), 6.5 * EK, 1.6 * EK, TAIL_TUFT, 4.0 * EK)

	# Ears: big fans swept 30 degrees back from straight out, so the front, side and 3/4 views show
	# their pink fronts. A thick rolled rim follows the scalloped outline round a thin membrane.
	for side in [-1.0, 1.0]:
		var along := Vector3(EAR_SWEEP.x, 0, side * EAR_SWEEP.y)
		var front := Vector3(-EAR_SWEEP.y, 0, side * EAR_SWEEP.x)
		var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
		for o in EAR_OVALS:
			eb(_ears, _ear_point(side, o[0], o[1]), Vector3(o[2], o[3], 8.0), GREY, 6.0, basis)
		var edge := _ear_outline()
		for i in edge.size():
			var p: Vector2 = edge[i]
			var q: Vector2 = edge[(i + 1) % edge.size()]
			cone(_ears, _ear_point(side, p.x, p.y), _ear_point(side, q.x, q.y), 9.5 * EK, 9.5 * EK, GREY, 4.0 * EK)
		for o in EAR_PINKS:
			_tint(_ear_point(side, o[0], o[1]) + front * 10.0 * EK, Vector3(o[2], o[3], 8.0) * EK, basis, EAR_PINK_E, CELL * 2.2)


func _ear_point(side: float, u: float, y: float) -> Vector3:
	return T(EAR_ROOT.x + u * EAR_SWEEP.x, y, side * (EAR_ROOT.y + u * EAR_SWEEP.y))


## Edge of the ear ovals together, as [u, y] points round the fan's centre.
func _ear_outline() -> Array:
	var centre := Vector2(78.0, 262.0)
	var pts := []
	for i in 64:
		var dir := Vector2.from_angle(TAU * i / 64.0)
		var reach := 0.0
		for o in EAR_OVALS:
			var t := 0.0
			while t < 200.0:
				var p := centre + dir * t
				if pow((p.x - float(o[0])) / float(o[2]), 2.0) + pow((p.y - float(o[1])) / float(o[3]), 2.0) <= 1.0:
					reach = maxf(reach, t)
				t += 0.5
		pts.append(centre + dir * reach)
	return pts


## Column leg into a broad round foot with a cream sole and three cream toenails in front.
func _eleg(b: Array, joints: Array, radii: Array, foot: Vector3) -> void:
	tube(b, joints, radii, GREY, 18.0, 4.0)
	var last: float = radii[radii.size() - 1]
	cone(b, joints[joints.size() - 1], foot, last * EK, (last + 2.0) * EK, GREY, 3.0 * EK)
	eb(b, foot, Vector3(35, 16.5, 34), GREY, 4.0)
	eb(b, foot + Vector3(0, -13.0, 0) * EK, Vector3(34, 4.5, 33), IVORY, 1.0)
	for t in [-1.0, 0.0, 1.0]:
		eb(b, foot + Vector3(-31.0 + 6.0 * absf(t), -5.0, t * 19.0) * EK, Vector3(8.5, 11.5, 10.0), IVORY, 1.5)


# --- Face details -------------------------------------------------------------------------

## The skin under an eye: [centre, frame] with frame = (right, up, outward normal).
func _elephant_eye(side: float) -> Array:
	var hit := _hit(T(700, E_EYE_Y, side * E_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], Basis(right, n.cross(right).normalized(), n)]


## Closed oval of (outward, up) points in working units, optionally kept inside the eye.
static func _oval(c: Vector2, r: Vector2, count: int, inside := Vector2.ZERO) -> Array:
	var pts := []
	for i in count:
		var p := c + Vector2(cos(TAU * i / count) * r.x, sin(TAU * i / count) * r.y)
		if inside != Vector2.ZERO:
			var m := (p / inside).length()
			if m > 1.0: p /= m
		pts.append(p * EK)
	return pts


## Eyes, from the sheet's front, side and 3/4 views: flat on the head's front corners, slightly
## taller than wide, a big warm-brown iris with a black pupil filling most of the eye, a
## crescent of white left at the outer side and under it, a fine dark outline, one round
## catch-light high on the inner side and a speck low on the outer side.
func _elephant_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _elephant_eye(side)
		var s: Vector3 = eye[0]
		var frame: Basis = eye[1]
		g.color = E_LINE
		_pillow(g, s, frame, side, _oval(Vector2.ZERO, E_EYE_R + Vector2(0.9, 0.9), 40), Vector2.ZERO, 0.1, 0.35)
		g.color = E_SCLERA
		_pillow(g, s, frame, side, _oval(Vector2.ZERO, E_EYE_R, 40), Vector2.ZERO, 0.3, 0.7)
		g.color = E_IRIS
		_pillow(g, s, frame, side, _oval(E_IRIS_C, E_IRIS_R, 40, E_EYE_R - Vector2(0.5, 0.5)), E_IRIS_C * EK, 0.95, 0.5)
		g.color = E_PUPIL
		_pillow(g, s, frame, side, _oval(E_IRIS_C, E_PUPIL_R, 28), E_IRIS_C * EK, 1.45, 0.15)
		g.color = E_SCLERA
		for shine in [[Vector2(-4.4, 6.2), 2.5], [Vector2(3.6, -6.0), 1.1]]:
			var q: Vector2 = (E_IRIS_C + shine[0]) * EK
			var at := s + frame * Vector3(side * q.x, q.y, _skin(s, frame, side, q.x, q.y) + 1.7)
			g.ellipsoid(at, Vector3(shine[1], shine[1], 0.3) * EK, frame, 16, 8)
	return _to_model(g)


## Point on the skin at (outward, up) sheet px from an eye's centre, lifted off it.
func _by_eye(s: Vector3, frame: Basis, side: float, q: Vector2, lift: float) -> Vector3:
	return _on_skin(s + frame * Vector3(side * q.x, q.y, 0.0) * EK, frame.z) + frame.z * lift * EK


## Upper lids with three lashes, brows, trunk wrinkles and the smile.
func _elephant_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _elephant_eye(side)
		var s: Vector3 = eye[0]
		var frame: Basis = eye[1]
		var n: Vector3 = frame.z
		var rim := E_EYE_R + Vector2(0.7, 0.7)
		# Upper lid: a dark line over the top of the eye, thickest toward the outer corner.
		g.color = E_LINE
		var lid := []
		var lid_w := []
		for i in 13:
			var a := deg_to_rad(lerpf(172.0, 4.0, i / 12.0))
			lid.append(_by_eye(s, frame, side, Vector2(cos(a), sin(a)) * rim, 0.9))
			var w := (0.6 + 1.0 * sin(PI * pow(i / 12.0, 0.8))) * EK
			lid_w.append(Vector2(w, w))
		g.loft(lid, lid_w, n, 8)
		# Three short lashes flicking out and up from the outer top corner.
		for deg in [58.0, 40.0, 22.0]:
			var a := deg_to_rad(deg)
			var from := Vector2(cos(a), sin(a)) * rim
			var to := from + Vector2.from_angle(a + 0.25) * 6.5
			var pts := []
			for t in [0.0, 0.5, 1.0]:
				var q := from.lerp(to, t) + Vector2(0, 0.9 * sin(PI * t))
				pts.append(_by_eye(s, frame, side, q, 0.9))
			g.loft(pts, [Vector2(0.95, 0.95) * EK, Vector2(0.7, 0.7) * EK, Vector2(0.3, 0.3) * EK], n, 6)
		# Brow: a short fine arc well above the eye, highest toward the nose.
		g.color = E_BROW
		var brow := []
		var brow_w := []
		var marks := [Vector2(12.0, 30.5), Vector2(6.0, 34.0), Vector2(-2.0, 36.5), Vector2(-10.0, 37.0), Vector2(-17.0, 34.5)]
		for i in marks.size():
			brow.append(_by_eye(s, frame, side, marks[i], 0.35))
			var w := (0.45 + 0.75 * sin(PI * i / (marks.size() - 1.0))) * EK
			brow_w.append(Vector2(w, w))
		g.loft(brow, brow_w, n, 6)
		# Smile: a short dark curve on the cheek behind the tusk, turning up.
		g.color = E_MOUTH
		var smile := []
		for q in [Vector2(849, 351), Vector2(854, 348.5), Vector2(859, 344), Vector2(862.5, 338), Vector2(864, 332)]:
			var h := _hit(T(q.x, q.y, side * 220.0), Vector3(0, 0, -side))
			smile.append(h[0] + h[1] * 0.3 * EK)
		g.loft(smile, [Vector2(1.0, 1.0) * EK, Vector2(1.1, 1.1) * EK, Vector2(1.0, 1.0) * EK, Vector2(0.8, 0.8) * EK, Vector2(0.4, 0.4) * EK], Vector3.UP, 6)
	# Trunk wrinkles: fine creases across the front of the trunk, from the brow to the curl.
	g.color = E_WRINKLE
	for ring in [[318.0, 30.0], [331.0, 28.0], [344.0, 26.0], [357.0, 24.0], [370.0, 22.5], [383.0, 21.5], [396.0, 20.5], [409.0, 19.5], [422.0, 18.5], [435.0, 17.5]]:
		var line := []
		var widths := []
		for i in 11:
			var t := (i - 5) / 5.0
			var h := _hit(T(700, ring[0] + 1.5 * t * t, t * ring[1] * 0.62), Vector3(1, 0, 0))
			line.append(h[0] + h[1] * 0.1 * EK)
			var w := (0.6 - 0.4 * t * t) * EK
			widths.append(Vector2(w, w))
		g.loft(line, widths, Vector3.UP, 6)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	_body.clear(); _mane.clear(); _tuft.clear(); _ears.clear(); _tints.clear()
	_shape()
	var root := Node3D.new()
	root.name = "ElephantClayDisplay"
	root.set_meta("source", "User's Elephant Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body], ["Tail tuft", _tuft], ["Ears", _ears]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], GREY_CREASE, 7.0)
		if part[0] == "Ears":
			mi.mesh = _paint(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _elephant_eyes()
	eyes.material_override = _material(0.22)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _elephant_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body, head and trunk (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(T(775, EGY, -105))
	var c := to_model(T(1200, ETOP, 105))
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
