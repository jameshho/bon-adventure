extends "res://scripts/characters/cow_clay.gd"
## Clay-style rhino traced from the user's "Rhino Character Blueprint" turnaround (11 Nov 2026,
## "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model, built
## once by tools/build_rhino_clay.gd into scenes/animals/rhino_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd) and the clay cow's blob paint, ray helper and fine meshing (cow_clay.gd:
## meshed FINE times larger than life and shrunk by _fit). Shapes are written in the rhino
## sheet's side-view pixels (x to the right = toward the tail, y down, z lateral, + = the side
## facing the viewer) and T() scales them into the lion's working space.
## The body is one heavy barrel. Its skin folds (behind the head, round the neck, behind the
## shoulders, round the haunches) are gentle creases: five broad creased puffs that flow into
## each other, so the mesher leaves a shallow groove and a soft darker line where they meet.
## Horns, ears and tail tuft are separate clay pieces; toenails are ivory parts of the feet;
## blush, nostrils and the pink of the ears are painted on the skin; eyes, brows and the smile
## are small parts laid on the face.
## Second pass (user, 11 Nov 2026): torso a little longer and rounder, folds made shallow
## (they were overlapping armour plates), legs thicker and straighter with matching round
## three-toed feet, head 6% larger (Hd()) with a wider muzzle, ivory horns of one family,
## smoother rump. Face, eyes and ears kept.
## Output faces -Z (head), +Y up, ground at y = 0.

const RH := 1.9                 # town units to the ear tips before the head was enlarged (not a park_animals.gd species yet)
const RGY := 527.5              # sheet y of the soles
const RTOP := 197.0             # sheet y of the ear tips
const RX := 944.0               # sheet x placed at the model origin
const RK := FINE * RH / ((RGY - RTOP) * S)   # sheet pixel -> lion working unit

# The head, horns, ears and face are the sheet's, enlarged about the back of the jaw.
const HEAD_PIVOT := Vector2(890.0, 345.0)
const HEAD_SCALE := 1.06
const HK := RK * HEAD_SCALE     # head sheet pixel -> lion working unit

# Colours sampled from the sheet (lit skin c9b4b6, mid ad9795, shade 937b75; horn f8dcc6),
# then deepened like the other clay animals so they hold under the town's bright daylight.
const R_GREY := Color("93848b")
const R_CREASE := Color("7f7077")       # folds: only a little darker than the skin
const R_IVORY := Color("e6d9c2")        # soft ivory (user, 11 Nov 2026; was a peach cream)
const R_IVORY_CREASE := Color("d2c3aa")
const R_EAR_PINK := Color("e38b7c")
const R_BLUSH := Color("ea9a94")
const R_LIP := Color("cf7a70")
const R_TUFT := Color("51443f")
const R_TUFT_CREASE := Color("3d322e")
const R_NOSTRIL := Color("463530")
const R_BROW := Color("6c5a5d")
const R_MOUTH := Color("5e3d38")
const R_SCLERA := Color("fbf8f2")
const R_BLACK := Color("120c09")
const R_IRIS := Color("1b120d")
const R_LINE := Color("1c1310")

# Eyes (head sheet px, side view): an upright oval on the side of the head, 26 wide and 31 tall
# face-on (the side view shows 24, the front view 14), leaning 6 degrees back at the top.
const R_EYE := Vector2(810.0, 314.0)
const R_EYE_R := Vector2(12.8, 15.6)
const R_EYE_LEAN := 6.0

var _rhorns := []
var _rhino_ear_tints := []


## Sheet pixel -> working space (y up).
static func T(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - RX) * RK, (RGY - y) * RK, z * RK)


## Head sheet pixel -> working space: the sheet's point, enlarged about HEAD_PIVOT.
static func Hd(x: float, y: float, z := 0.0) -> Vector3:
	return T(HEAD_PIVOT.x + (x - HEAD_PIVOT.x) * HEAD_SCALE, HEAD_PIVOT.y + (y - HEAD_PIVOT.y) * HEAD_SCALE, z * HEAD_SCALE)


func re(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * RK, col, k * RK, crease, basis)


## Head ellipsoid: radii and blend in head sheet px.
func he(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, basis := Basis()) -> void:
	ell(g, c, r * HK, col, k * HK, false, basis)


func rc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * RK, rb * RK, col, k * RK)


func rtube(g: Array, pts: Array, radii: Array, col: Color, k: float, k_rest := 3.0) -> void:
	for i in pts.size() - 1:
		rc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else k_rest)


## A tapering tube as closely spaced balls (the round cones of rtube leave a ridge at every
## joint when the taper is steep): pts and radii (working units) are interpolated every `step`.
func rtaper(g: Array, pts: Array, radii: Array, col: Color, step: float) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var count := maxi(int(ceil(a.distance_to(b) / step)), 1)
		for j in count:
			var t0 := float(j) / count
			var t1 := float(j + 1) / count
			cone(g, a.lerp(b, t0), a.lerp(b, t1), lerpf(radii[i], radii[i + 1], t0), lerpf(radii[i], radii[i + 1], t1), col, 0.0)


## A horn: round at the base, a little hollow down its front, drawn to a blunt point. Both
## horns are this one shape: `base` and `tip` in head sheet px, r = radius at the base.
func _horn(base: Vector2, tip: Vector2, r: float) -> void:
	var pts := []
	var radii := []
	# [along the horn 0..1, radius / base radius, sway forward / base radius]
	for row in [[0.0, 1.0, 0.0], [0.22, 0.87, -0.04], [0.42, 0.7, -0.1], [0.62, 0.51, -0.12], [0.8, 0.33, -0.08], [0.93, 0.19, -0.03], [1.0, 0.105, 0.0]]:
		var p := base.lerp(tip, row[0])
		pts.append(Hd(p.x + row[2] * r, p.y))
		radii.append(row[1] * r * HK)
	rtaper(_rhorns, pts, radii, R_IVORY, 2.5 * RK)


## A fold's lean in the side view: positive leans its top toward the head.
static func _lean(degrees: float) -> Basis:
	return Basis(Vector3(0, 0, 1), deg_to_rad(degrees))


# --- Shape --------------------------------------------------------------------------------

## Legs as [hip, knee, ankle (sheet x, y), lateral z]: four equal straight columns, the far
## pair a short step ahead of the near pair.
const R_LEGS := [
	[Vector2(946, 405), Vector2(945, 462), Vector2(944, 492), 52.0],
	[Vector2(910, 408), Vector2(894, 462), Vector2(886, 492), -52.0],
	[Vector2(1132, 418), Vector2(1137, 465), Vector2(1139, 492), 54.0],
	[Vector2(1094, 420), Vector2(1085, 465), Vector2(1080, 492), -54.0]]
const R_LEG_RADII := [45.0, 43.0, 42.0]

func _shape() -> void:
	var b := _body
	var fold := 13.0
	# Torso, back to front. The barrel of the back and belly: long, deep and round.
	re(b, T(1020, 362), Vector3(147, 92, 101), R_GREY, 0.0, true)
	# Haunches: one broad puff round both thighs and under the tail.
	re(b, T(1124, 414), Vector3(50, 92, 104), R_GREY, fold, true)
	# Shoulders: over the withers and down both sides, the rear edge bowed back.
	re(b, T(972, 358), Vector3(80, 93, 101), R_GREY, fold, true, _lean(12.0))
	# Neck, then the fold behind the head: sweeping down and forward to the chest.
	re(b, T(900, 338), Vector3(62, 94, 93), R_GREY, fold, true, _lean(-35.0))
	re(b, T(868, 324), Vector3(52, 85, 84), R_GREY, fold, true, _lean(-27.0))
	# Chest between the forelegs.
	re(b, T(925, 394), Vector3(66, 52, 78), R_GREY, 14.0)

	# Head: a domed skull, wide round cheeks low down, a long blunt snout with a flat front and
	# a soft lower jaw set back under it.
	he(b, Hd(855, 300), Vector3(70, 62, 64), R_GREY, 12.0)
	for side in [-1.0, 1.0]:
		he(b, Hd(840, 345, side * 34.0), Vector3(46, 46, 41), R_GREY, 14.0)
	he(b, Hd(790, 322), Vector3(42, 30, 46), R_GREY, 14.0)                  # bridge of the nose
	he(b, Hd(762, 356), Vector3(60, 43, 61), R_GREY, 16.0)
	he(b, Hd(745, 348), Vector3(42, 31, 56), R_GREY, 10.0)
	for side in [-1.0, 1.0]:
		he(b, Hd(764, 380, side * 25.0), Vector3(52, 23, 33), R_GREY, 20.0)   # full upper lip, down to the mouth
	he(b, Hd(802, 386), Vector3(54, 19, 38), R_GREY, 9.0)
	he(b, Hd(750.0, 401.5), Vector3(7.0, 3.8, 20), R_LIP, 0.5)               # lower lip
	# Nostrils: a soft rim on each front corner of the snout with a pit pressed in.
	for side in [-1.0, 1.0]:
		var from := Hd(600, 355, side * 40.0)
		var hit := _ray(b, from, Vector3(1, 0, 0))
		var n: Vector3 = hit[1]
		var up := (Vector3.UP - n * n.y).normalized()
		var basis := Basis(n, up, n.cross(up).normalized()) * Basis(Vector3(1, 0, 0), side * 0.3)
		he(b, hit[0] - n * 4.0 * HK, Vector3(8.0, 13.0, 11.0), R_GREY, 5.0, basis)
		var at: Vector3 = _ray(b, from, Vector3(1, 0, 0))[0]
		var hole := Vector3(6.5, 8.4, 6.2)
		carve(b, at, hole * HK, R_GREY, basis)
		_tints.append({"t": "ell", "c": at, "r": (hole + Vector3.ONE * 0.8) * HK, "inv": basis.inverse(), "col": R_NOSTRIL, "soft": CELL * 0.9})

	# Legs: thick straight columns into broad round feet. Three ivory toenails round the front
	# of each foot, set a little toward its outer side so the side views show them too.
	for leg in R_LEGS:
		var z: float = leg[3]
		var ankle: Vector2 = leg[2]
		rtube(b, [T(leg[0].x, leg[0].y, z), T(leg[1].x, leg[1].y, z), T(ankle.x, ankle.y, z)], R_LEG_RADII, R_GREY, 16.0, 4.0)
		var foot := T(ankle.x - 1.0, RGY - 24.0, z)
		re(b, foot, Vector3(45, 24, 44), R_GREY, 6.0)
		for deg in [-34.0, 8.0, 50.0]:
			var a := deg_to_rad(deg)
			re(b, foot + Vector3(-cos(a) * 38.5, -9.5, signf(z) * sin(a) * 37.5) * RK, Vector3(11.5, 14.5, 11.5), R_IVORY, 1.5,
					false, Basis(Vector3.UP, -signf(z) * a))
	# Tail: thin, off the rump and swung a little back.
	rtube(b, [T(1153, 338), T(1174, 362), T(1183, 395), T(1187, 416)], [9.5, 6.5, 5.0, 4.5], R_GREY, 10.0)

	# Tail tuft: a dark teardrop.
	re(_tuft, T(1188, 428), Vector3(13, 21, 11), R_TUFT, 0.0, false, _lean(10.0))
	rc(_tuft, T(1191, 438), T(1197, 451), 7.0, 1.6, R_TUFT, 5.0)

	# Horns: the tall nose horn and a small one of the same shape behind it.
	_horn(Vector2(731, 330), Vector2(726, 247.5), 26.5)
	_horn(Vector2(772, 300), Vector2(771, 272.5), 11.5)

	# Ears: upright rounded leaves, leaning out; a thick rolled rim round a pink hollow that
	# faces forward and outward.
	for side in [-1.0, 1.0]:
		var along := Vector3(0.07, 0.95, side * 0.3).normalized()
		var open := Vector3(-0.64, 0.0, side * 0.77)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var c := Hd(868, 227, side * 60.0)
		ell(_ears, c, Vector3(9.0, 25.5, 31.5) * HK, R_GREY, 0.0, false, basis)
		ell(_ears, c - along * 21.0 * HK, Vector3(9.0, 18.0, 16.0) * HK, R_GREY, 10.0 * HK, false, basis)   # stalk into the head
		var hollow := c + open * 8.0 * HK + along * 1.0 * HK
		var hole := Vector3(7.0, 17.0, 22.5)
		carve(_ears, hollow, hole * HK, R_GREY, basis)
		_rhino_ear_tints.append({"t": "blob", "c": hollow, "r": Vector3.ONE * 60.0 * HK,
				"parts": [{"t": "ell", "c": hollow, "r": (hole + Vector3(1.5, 0.6, 0.6)) * HK, "inv": basis.inverse()}],
				"k": 5.0 * HK, "col": R_EAR_PINK, "soft": CELL * 0.35})

	# Blush: a soft round patch low behind each eye.
	for side in [-1.0, 1.0]:
		var cheek: Vector3 = _ray(b, Hd(834, 336, side * 400.0), Vector3(0, 0, -side))[0]
		_tint(cheek, Vector3(13, 12, 13) * HK, Basis(), R_BLUSH, CELL * 4.0)


## Drops a point near the face onto the skin along -n, then lifts it `lift` head sheet px.
func _rdrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * HK
	for i in 900:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * HK


# --- Face details -------------------------------------------------------------------------

## The skin under an eye: [centre, Basis(toward the tail, up, outward normal)].
func _rhino_eye(side: float) -> Array:
	var hit := _ray(_body, Hd(R_EYE.x, R_EYE.y, side * 400.0), Vector3(0, 0, -side))
	var n: Vector3 = hit[1]
	var up := (Vector3.UP - n * n.y).normalized()
	var back := up.cross(n).normalized()
	if back.x < 0.0: back = -back
	var a := deg_to_rad(R_EYE_LEAN)
	return [hit[0], Basis(back * cos(a) - up * sin(a), up * cos(a) + back * sin(a), n)]


## Eyes, from the sheet's side, front and 3/4 views: a glossy upright oval set flat in the side
## of the head, almost all black; the white shows only as a thin crescent down the rear edge;
## one round catch-light high in the black, a faint brown glow low in it.
func _rhino_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _rhino_eye(side)
		var s: Vector3 = eye[0]
		var frame: Basis = eye[1]
		var back: Vector3 = frame.x
		var up: Vector3 = frame.y
		var n: Vector3 = frame.z
		# The white's edge lies in the skin: its centre plane sits at the skin's mean height
		# round the eye and the dome stands 2.2 px proud at its middle.
		var edge := 0.0
		for q in [Vector2(R_EYE_R.x, 0), Vector2(-R_EYE_R.x, 0), Vector2(0, R_EYE_R.y), Vector2(0, -R_EYE_R.y)]:
			edge += (_rdrop(s + (back * q.x + up * q.y) * HK, n, 0.0) - s).dot(n) / HK * 0.25
		var white_h := edge - 0.3
		var white := Vector3(R_EYE_R.x, R_EYE_R.y, 2.2 - white_h)
		g.color = R_SCLERA
		g.ellipsoid(s + n * white_h * HK, white * HK, frame, 40, 20)
		# The black, shifted toward the nose so only a rear crescent of white is left.
		var bo := Vector2(-1.5, 0.0)
		var black := Vector3(11.2, 14.8, 2.2)
		var black_h := white_h + _dome(white, bo.x, bo.y) - black.z + 0.9
		g.color = R_BLACK
		g.ellipsoid(s + (back * bo.x + up * bo.y + n * black_h) * HK, black * HK, frame, 40, 20)
		var glow := Vector2(-0.5, -7.5)
		g.color = R_IRIS
		g.ellipsoid(s + (back * (bo.x + glow.x) + up * (bo.y + glow.y) + n * (black_h + _dome(black, glow.x, glow.y) - 0.75)) * HK,
				Vector3(5.5, 3.8, 1.0) * HK, frame, 24, 10)
		var shine := Vector2(3.2, 5.6)
		g.color = R_SCLERA
		g.ellipsoid(s + (back * (bo.x + shine.x) + up * (bo.y + shine.y) + n * (black_h + _dome(black, shine.x, shine.y) + 0.2)) * HK,
				Vector3(2.5, 2.5, 0.6) * HK, frame, 18, 8)
	return _to_model(g)


## Eye outlines, eyebrows and the smile.
func _rhino_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _rhino_eye(side)
		var s: Vector3 = eye[0]
		var frame: Basis = eye[1]
		var back: Vector3 = frame.x
		var up: Vector3 = frame.y
		var n: Vector3 = frame.z
		# Outline: a fine dark line all round the eye, a little heavier over the top.
		g.color = R_LINE
		var ring := []
		var ring_w := []
		for i in 33:
			var a := TAU * i / 32.0
			var q := Vector2(cos(a) * (R_EYE_R.x + 0.1), sin(a) * (R_EYE_R.y + 0.1))
			ring.append(_rdrop(s + (back * q.x + up * q.y) * HK, n, 0.5))
			var w := 0.75 + 0.35 * maxf(sin(a), 0.0)
			ring_w.append(Vector2(w, 0.7) * HK)
		g.loft(ring, ring_w, n, 6, false)
		# Eyebrow: a short thick crescent well above the eye, round toward the nose and drawn
		# to a point at the rear, where it turns down.
		g.color = R_BROW
		var brow := []
		var brow_w := []
		for q in [[-4.5, 37.5, 2.1], [-2.0, 40.2, 3.3], [2.5, 42.2, 3.8], [7.0, 42.0, 3.4], [11.0, 39.3, 2.3], [13.5, 35.5, 0.9]]:
			brow.append(_rdrop(s + (back * q[0] + up * q[1]) * HK, n, 0.15))
			brow_w.append(Vector2(q[2], 1.0) * HK)
		g.loft(brow, brow_w, n, 10)
	# Smile: one dark line in the fold under the snout, from cheek to cheek, turning up at the
	# corners into a small dimple.
	g.color = R_MOUTH
	var smile := []
	var smile_w := []
	for i in 41:
		var t := (i - 20) / 20.0
		var phi := t * deg_to_rad(92.0)
		var y := 400.5 - 29.0 * pow(absf(t), 2.2)
		var dir := Vector3(cos(phi), 0.0, -sin(phi))
		var h := _ray(_body, Hd(788, y) - dir * 300.0 * RK, dir)
		smile.append(h[0] + h[1] * 0.25 * HK)
		var w := 1.7 - 0.7 * absf(t)
		smile_w.append(Vector2(w, w) * HK)
	g.loft(smile, smile_w, Vector3.UP, 6)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _rhorns, _rhino_ear_tints]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "RhinoClayDisplay"
	root.set_meta("source", "User's Rhino Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, R_CREASE, 5.0], ["Horns", _rhorns, R_IVORY_CREASE, 6.0],
			["Ears", _ears, R_CREASE, 6.0], ["Tail tuft", _tuft, R_TUFT_CREASE, 6.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Ears": _rhino_ear_tints}.get(part[0], [])
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
	eyes.mesh = _rhino_eyes()
	eyes.material_override = _material(0.3)
	eyes.material_override.metallic_specular = 0.25   # the painted catch-light is the only shine
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _rhino_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(T(692, RGY, -106)) / FINE
	var c := to_model(T(1178, 232, 106)) / FINE
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
