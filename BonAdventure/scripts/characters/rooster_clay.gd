extends "res://scripts/characters/cow_clay.gd"
## Clay-style rooster traced from the user's "Rooster Character Blueprint" turnaround (16 Nov
## 2026, "Relaxed Idle Pose": front 3/4, front, side, back, rear 3/4). A static display model,
## built once by tools/build_rooster_clay.gd into scenes/animals/rooster_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd: _tint, _paint) and the clay cow's helpers (cow_clay.gd: _ray, _dome), and
## lays feathers on the skin the way the clay duck and flamingo do (_lay).
## Shapes are written in the rooster sheet's side-view pixels (x to the right = toward the tail,
## y down, z lateral, + = the animal's left) and V() scales them into the lion's working space.
## The rooster is small, so it is meshed RF times larger than life and shrunk afterwards.
##
## Ready for rigging like the clay pig: head, neck feathers, body, legs and feet are one fused
## mesh ("Body"); beak (upper and lower), comb, wattles, wings and tail are separate clay pieces; each eye is its
## own mesh centred on its own node (LeftEye, RightEye: local x across the eye, y up the eye,
## z out of the face); lids, brows, nostrils and the mouth line are "Face details".
## Output faces -Z (head), +Y up, ground at y = 0.

const RH := 0.6                 # town units to the top of the comb (provisional: the user decides at placement)
const RY := 535.0               # sheet y of the soles
const RTOP := 154.0             # sheet y of the top of the comb
const RX := 890.0               # sheet x placed at the model origin
const RF := 6.0                 # meshed this many times larger than life
const RK := RF * RH / ((RY - RTOP) * S)   # sheet pixel -> lion working unit
const PXM := RH / (RY - RTOP)   # sheet pixel -> finished model unit

const R_HEAD := Color("fab658")
const R_FACE := Color("fdcd8a")           # the paler face and cheeks (painted)
const R_HACKLE := Color("f7a646")
const R_HACKLE_LOW := Color("f39b3c")
const R_HACKLE_CREASE := Color("dd8530")
const R_CREAM := Color("f1d2ae")
const R_RUMP := Color("c96c34")
const R_COMB := Color("e4533a")
const R_COMB_CREASE := Color("cc452b")
const R_WATTLE := Color("e85a3c")
const R_BEAK := Color("f9bf52")
const R_BEAK_LOW := Color("df8526")
const R_BEAK_CREASE := Color("c9761f")
const R_NOSTRIL := Color("b06c20")
const R_MOUTH := Color("a85a18")
const R_LEG := Color("f8b23e")
const R_WING_LIGHT := Color("d87a40")
const R_WING_1 := Color("c56a34")
const R_WING_2 := Color("b05c2c")
const R_WING_3 := Color("904a22")
const R_WING_CREASE := Color("94502a")
const R_TAIL := [Color("46646b"), Color("3e5a62"), Color("3a555c"), Color("365059"), Color("334b53")]
const R_TAIL_CREASE := Color("2a3e44")
const R_BROW := Color("bd652e")
const R_SCLERA := Color("fbf0e0")
const R_IRIS := Color("5e391c")
const R_IRIS_RIM := Color("40240f")
const R_PUPIL := Color("140a05")
const R_LID := Color("2a190e")

# Eyes (sheet px). Height and lateral offset of the centre are the front view's; the half-sizes
# are the 3/4 view's, which looks straight at the eye (33 x 36).
const R_EYE_Y := 264.0
const R_EYE_Z := 35.5
const R_EYE_R := Vector2(16.2, 18.0)

const Pig := preload("res://scripts/characters/pig_clay.gd")

## Legs: sheet x and lateral z. The sheet's front view has them level; they stand level here.
const R_LEG_X := 893.0
const R_LEG_Z := 29.0

# Mouth: lateral offset and half width of the two cuts under the upper beak.
const MOUTH_Z := 28.0
const MOUTH_R := 100.0

# Neck cape: sheet y of its middle, half sizes (along the body, across) and tilt of its rim.
const CAPE_Y := 342.0
const CAPE_R := Vector2(84.0, 81.0)
const CAPE_TILT := 0.25

var _beak := []
var _beak_low := []
var _comb := []
var _wattles := []
var _wings := []
var _wing_tints := []
var _tail := []


## Sheet pixel -> working space (y up).
static func V(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - RX) * RK, (RY - y) * RK, z * RK)


func de(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * RK, col, k * RK, crease, basis)


func dc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * RK, rb * RK, col, k * RK)


## Rotation about the lateral axis: positive raises the tail end of a shape.
static func tilt(a: float) -> Basis:
	return Basis(Vector3(0, 0, 1), a)


## One feather: a flattened puff laid on the skin at `hit` ([point, normal]), its length along
## `d` projected onto the skin. r = half length, half width, half thickness (sheet px); `lift`
## raises its middle off the skin and `shift` slides it along its length.
func _lay(g: Array, hit: Array, d: Vector3, r: Vector3, col: Color, lift: float, shift := 0.0, k := 2.0, crease := true) -> void:
	var n: Vector3 = hit[1]
	var flat := (d - n * d.dot(n)).normalized()
	de(g, hit[0] + (n * lift + flat * shift) * RK, r, col, k, crease, Basis(flat, n.cross(flat).normalized(), n))


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Head: a big ball, narrower across the face than behind the eyes (so the eyes face well
	# out to the sides, as on the sheet), with full cheeks low down.
	de(b, V(850, 268), Vector3(62, 50, 49), R_HEAD)
	de(b, V(866, 268), Vector3(46, 50, 56), R_HEAD, 10.0)
	for side in [-1.0, 1.0]:
		de(b, V(840, 295, side * 30.0), Vector3(42, 27, 34), R_HEAD, 12.0)
	# Neck cape: a smooth bell from the cheeks out to a wide rim, lower at the chest than at
	# the back.
	dc(b, V(848, 284), V(856, 338), 56.0, 79.0, R_HEAD, 14.0)
	de(b, V(856, CAPE_Y), Vector3(CAPE_R.x, 40, CAPE_R.y), R_HEAD, 12.0, false, tilt(CAPE_TILT))
	# Body: an egg, with a full chest and a rump that carries the tail.
	var torso := []
	de(torso, V(885, 425), Vector3(112, 72, 74), R_CREAM, 20.0)
	de(torso, V(818, 422), Vector3(46, 56, 60), R_CREAM, 20.0)
	de(torso, V(972, 402), Vector3(40, 44, 52), R_CREAM, 20.0)
	de(torso, V(880, 462), Vector3(78, 34, 62), R_CREAM, 18.0)      # the broad belly
	b.append_array(torso)
	_hackle()
	# Legs: a small feathered cuff, a straight stalk and three fat toes with a short heel.
	for side in [-1.0, 1.0]:
		var z: float = side * R_LEG_Z
		de(b, V(R_LEG_X, 482, z), Vector3(16, 10, 16), R_CREAM, 8.0)
	for side in [-1.0, 1.0]:
		var z: float = side * R_LEG_Z
		dc(b, V(R_LEG_X, 484, z), V(R_LEG_X, 522, z), 10.0, 9.0, R_LEG)
		for toe in [[-52.0, 0.0, 8.5], [-46.0, 21.0, 8.0], [-46.0, -19.0, 8.0], [17.0, 0.0, 7.0]]:
			dc(b, V(R_LEG_X - 2.0, 526.5, z), V(R_LEG_X + toe[0], 528.0, z + side * toe[1]), 9.0, toe[2], R_LEG, 4.0)
		de(b, V(R_LEG_X - 8.0, 525, z), Vector3(15, 8, 13), R_LEG, 4.0)
	carve(b, V(R_LEG_X - 20.0, RY + 40.0, 0.0), Vector3(400, 40, 400) * RK, R_LEG)

	# Paint: the paler face and cheeks, and the red-brown saddle between the wings and tail.
	_tint(V(792, 272), Vector3(34, 44, 50) * RK, Basis(), R_FACE, CELL * 5.0)
	for side in [-1.0, 1.0]:
		_tint(V(826, 292, side * 44.0), Vector3(32, 24, 26) * RK, Basis(), R_FACE, CELL * 5.0)
	_tint(V(975, 386), Vector3(62, 46, 70) * RK, Basis(), R_RUMP, CELL * 3.0)

	# Beak: a short cone, wide at the face, with a rounded tip that hooks a little over the
	# lower half. The upper half is cut flat underneath along the mouth; the darker lower half
	# is a slim lip tucked under it.
	var m := _beak
	# A narrow ridge down the middle over two fuller sides gives the rounded-triangle front.
	dc(m, V(800, 272.0, 0.0), V(759.0, 281.5), 12.5, 4.6, R_BEAK)
	for side in [-1.0, 1.0]:
		dc(m, V(800, 280.5, side * 12.0), V(760.0, 283.0), 12.5, 4.4, R_BEAK, 5.0)
	# Two cuts side by side leave the mouth a little lower in the middle than at the corners.
	for side in [-1.0, 1.0]:
		carve(m, V(790, 286.0 + 60.0, side * MOUTH_Z), Vector3(260, 60, MOUTH_R) * RK, R_BEAK)
	for side in [-1.0, 1.0]:
		dc(_beak_low, V(800, 289.0, side * 8.0), V(767, 288.0), 10.0, 3.8, R_BEAK_LOW)
	de(m, V(759.0, 285.3), Vector3(5, 3.0, 5.0), R_BEAK)

	# Comb: four fat lobes over the crown, the second the tallest, a tongue down the forehead
	# and a thicker middle (the sheet's front and back views show it about 55 px wide).
	var c := _comb
	de(c, V(852, 226), Vector3(54, 15, 14), R_COMB, 0.0, false, tilt(-0.06))
	de(c, V(803, 228), Vector3(13, 15, 10.5), R_COMB, 6.0)
	de(c, V(811, 201), Vector3(24, 29, 15), R_COMB, 1.5, true, tilt(-0.25))
	de(c, V(856, 189), Vector3(26, 36, 17), R_COMB, 1.5, true)
	de(c, V(894, 196), Vector3(23, 32, 17), R_COMB, 1.5, true, tilt(0.3))
	de(c, V(917, 222), Vector3(16, 25, 15), R_COMB, 1.5, true, tilt(0.25))
	for side in [-1.0, 1.0]:
		de(c, V(872, 217, side * 14.0), Vector3(32, 15, 13), R_COMB, 5.0)

	# Wattles: two teardrops hanging side by side under the beak.
	for side in [-1.0, 1.0]:
		dc(_wattles, V(794, 298, side * 5.0), V(783, 324, side * 15.5), 8.5, 15.0, R_WATTLE)
		de(_wattles, V(781, 330, side * 16.5), Vector3(19, 19.5, 17.5), R_WATTLE, 8.0, true)

	_wing_feathers(torso)
	_tail_feathers()


## Neck feathers: two layers of thin round-ended tongues hanging from the cape's rim like the
## hem of a skirt, long and short ones in turn; the upper layer is shorter and sits between
## the lower ones (the cape above them is smooth, as on the sheet). Placed round the rim itself
## (no rays): `th` runs from the chest (0) round the animal's left to the back.
func _hackle() -> void:
	for row in 2:
		var count := 14
		for i in count:
			var th := TAU * (i + 0.5 * row) / count
			var front := maxf(cos(th), 0.0)
			var radial := Vector3(-cos(th), 0.0, sin(th))
			var long := 27.0 - (i % 2) * 6.0 - row * 5.0
			var y := CAPE_Y + CAPE_R.x * sin(CAPE_TILT) * cos(th) + 34.0 + 8.0 * front * front - long - row * 13.0
			var inset := 7.0 - row * 2.5
			var dir := (Vector3(0, -1, 0) + radial * 0.3).normalized()
			var nrm := dir.cross(Vector3(sin(th), 0.0, cos(th))).normalized()
			if nrm.dot(radial) < 0.0: nrm = -nrm
			de(_body, V(856.0 - (CAPE_R.x - inset) * cos(th), y, (CAPE_R.y - inset) * sin(th)),
					Vector3(long, 15.5 - row * 2.0, 5.5 + (i % 2) * 1.5 - row),
					R_HACKLE_LOW if row == 0 else R_HACKLE, 1.5, row == 0, Basis(dir, nrm.cross(dir).normalized(), nrm))


## Wings: one smooth egg-shaped pad on each flank, fat at the shoulder and tapering to a
## rounded tip at the rump, with four big soft feather lobes in low relief on it (the sheet's
## wing is nearly smooth, with a few sweeping lines). The pad is laid on the body alone
## (`torso`), so the shoulder tucks under the neck feathers; the lobes are laid on the pad.
## Its colour runs from terracotta at the top to a darker brown along the bottom (painted).
func _wing_feathers(torso: Array) -> void:
	for side in [-1.0, 1.0]:
		var pad := []
		# The first shape fills in between the pad and the flank, so the wing reads as a thick
		# pad from the front and back instead of a flap standing off the body.
		for f in [[905, 410, Vector3(60, 44, 20.0), -0.05, 0.0, 0.0], [893, 402, Vector3(66, 52, 19.0), -0.05, 7.0, 12.0], [952, 412, Vector3(52, 37, 17.0), -0.12, 8.0, 14.0],
				[992, 426, Vector3(17, 13, 11.0), -0.2, 9.0, 8.0]]:
			var hit := _ray(torso, V(f[0], f[1], side * 240.0), Vector3(0, 0, -side))
			var a: float = f[3]
			_lay(pad, hit, Vector3(cos(a), sin(a), 0.0), f[2], R_WING_1, f[4], 0.0, f[5], false)
		_wings.append_array(pad)
		# Lobes, lowest first: the long flight feathers to the tip, the lower front, the middle
		# and the upper covert, each ending in a rounded edge toward the tail.
		for f in [[950, 437, Vector3(42, 12.5, 5.0), 0.1], [876, 431, Vector3(28, 15, 5.0), -0.7], [895, 411, Vector3(34, 17, 5.5), -0.25],
				[915, 385, Vector3(36, 18, 5.5), 0.05]]:
			var hit := _ray(pad, V(f[0], f[1], side * 300.0), Vector3(0, 0, -side))
			var a: float = f[3]
			_lay(_wings, hit, Vector3(cos(a), sin(a), 0.0), f[2], R_WING_1, -1.8, 0.0, 3.0, true)
	# Shading: lighter along the top, darker along the bottom, both soft.
	_wing_tints.append({"t": "ell", "c": V(915, 315), "r": Vector3(260, 52, 260) * RK, "inv": Basis(), "col": R_WING_LIGHT, "soft": 38.0 * RK})
	_wing_tints.append({"t": "ell", "c": V(915, 494), "r": Vector3(260, 62, 260) * RK, "inv": Basis(), "col": R_WING_3, "soft": 44.0 * RK})


## One sickle feather: a fat, flattened blade along a smooth curve through `pts` (sheet x, y,
## lateral z). `thick` is its half size in the side view and `wide` its lateral half size at
## each point.
func _blade(pts: Array, thick: Array, wide: Array, col: Color) -> void:
	var steps := 5
	var last := pts.size() - 1
	var at := []
	var size := []
	for i in last:
		for s in steps:
			var t := float(s) / steps
			at.append((pts[i] as Vector3).cubic_interpolate(pts[i + 1], pts[maxi(i - 1, 0)], pts[mini(i + 2, last)], t))
			size.append(Vector2(lerpf(thick[i], thick[i + 1], t), lerpf(wide[i], wide[i + 1], t)))
	at.append(pts[last])
	size.append(Vector2(thick[last], wide[last]))
	for i in at.size():
		var p: Vector3 = at[i]
		var a: Vector3 = at[maxi(i - 1, 0)]
		var b: Vector3 = at[mini(i + 1, at.size() - 1)]
		var along := Vector3(b.x - a.x, a.y - b.y, b.z - a.z)      # sheet y is down
		var seg := along.length() * 0.5
		along = along.normalized()
		var lateral := (Vector3(0, 0, 1) - along * along.z).normalized()
		de(_tail, V(p.x, p.y, p.z), Vector3(maxf(seg * 1.5, size[i].x * 0.8), size[i].x, size[i].y), col, 4.0, false,
				Basis(along, lateral.cross(along).normalized(), lateral))


## Tail: sickle feathers that rise off the rump and curl over and down: two on the midline
## (the long one and a shorter one above it), two pairs fanning out below them and a short
## one underneath.
func _tail_feathers() -> void:
	_blade([Vector3(978, 372, 0), Vector3(1015, 322, 0), Vector3(1062, 307, 0), Vector3(1105, 320, 0), Vector3(1132, 352, 0), Vector3(1145, 396, 0)],
			[18, 23, 25, 23, 18, 7], [32, 44, 48, 44, 32, 12], R_TAIL[1])
	_blade([Vector3(980, 352, 0), Vector3(1010, 286, 0), Vector3(1050, 269, 0), Vector3(1090, 271, 0), Vector3(1118, 286, 0)],
			[14, 16, 17, 15, 6], [20, 26, 28, 24, 9], R_TAIL[0])
	for side in [-1.0, 1.0]:
		_blade([Vector3(985, 388, side * 20), Vector3(1030, 360, side * 32), Vector3(1070, 366, side * 42), Vector3(1097, 392, side * 46),
				Vector3(1102, 430, side * 46), Vector3(1079, 466, side * 40)],
				[15, 19, 20, 19, 15, 6], [26, 30, 31, 28, 21, 8], R_TAIL[2])
		_blade([Vector3(992, 402, side * 14), Vector3(1023, 393, side * 22), Vector3(1048, 410, side * 28), Vector3(1054, 438, side * 30),
				Vector3(1035, 463, side * 28)],
				[13, 16, 16, 13, 5], [17, 20, 20, 16, 7], R_TAIL[3])
	_blade([Vector3(995, 414, 0), Vector3(1014, 428, 0), Vector3(1018, 446, 0), Vector3(1008, 462, 0)],
			[12, 13, 11, 4.5], [18, 20, 15, 6], R_TAIL[4])


# --- Face details -------------------------------------------------------------------------

## Drops a point near the face onto the skin along -n, then lifts it `lift` sheet px.
func _rdrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * RK
	for i in 4000:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * RK


## The skin under an eye and its frame: [centre, outward normal, across (toward the animal's
## rear on its left eye, toward the beak on its right), up]. A proper rotation on both sides.
func _rooster_eye_frame(side: float) -> Array:
	var hit := _ray(_body, V(640, R_EYE_Y, side * R_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right, n.cross(right).normalized()]


## Point on the eye's rim at angle `a` (0 = the outer, rear corner; a quarter turn = the top),
## `grow` px outside it, in the eye's own plane.
static func _rim(a: float, grow := 0.0) -> Vector2:
	return Vector2(cos(a) * (R_EYE_R.x + grow), sin(a) * (R_EYE_R.y + grow))


## One eye, in its own frame (x toward the outer corner times `side`, y up, z out of the face;
## sheet px until the end). From the sheet's front, 3/4 and side views: a tall upright oval set
## in the face and only gently domed; a large dark-brown iris that sits toward the beak and
## fills the eye's height, leaving a white crescent down the outer side; a big black pupil a
## little low in it; one round catch-light high in the pupil.
func _rooster_eye(side: float) -> ArrayMesh:
	var f := _rooster_eye_frame(side)
	var s: Vector3 = f[0]
	var n: Vector3 = f[1]
	var edge := 0.0
	for q in [Vector2(R_EYE_R.x, 0), Vector2(-R_EYE_R.x, 0), Vector2(0, R_EYE_R.y), Vector2(0, -R_EYE_R.y)]:
		edge += (_rdrop(s + (f[2] * q.x + f[3] * q.y) * RK, n, 0.0) - s).dot(n) / RK * 0.25
	var g := Plaza.Geo.new()
	var white_h := edge + 0.15
	var bulge := 1.7 - white_h
	var io := Vector2(-3.9 * side, 0.3)
	var iris := Vector2(11.7, 17.3)
	var po := io + Vector2(0.0, -1.6)
	var pupil := Vector2(7.9, 10.0)
	# One dome, rings from the centre to the rim, coloured per point so the iris and the pupil
	# have soft edges (the clay pig's ring builder).
	var pts := [[Vector3(0, 0, white_h + bulge)]]
	var cols := [[_eye_colour(Vector2.ZERO, io, iris, po, pupil)]]
	for i in range(1, 31):
		var rho := i / 30.0
		var ring := []
		var ring_c := []
		for j in 64:
			var q := _rim(TAU * j / 64.0) * rho
			ring.append(Vector3(q.x, q.y, white_h + bulge * sqrt(1.0 - rho * rho)))
			ring_c.append(_eye_colour(q, io, iris, po, pupil))
		pts.append(ring)
		cols.append(ring_c)
	Pig._rings(g, pts, cols, Vector3(0, 0, 1))
	for i in g.verts.size():
		var v := g.verts[i]
		g.norms[i] = Vector3(v.x / (R_EYE_R.x * R_EYE_R.x), v.y / (R_EYE_R.y * R_EYE_R.y), maxf(v.z - white_h, 0.05) / (bulge * bulge)).normalized()
	# Catch-light: a white spot with a soft edge, high in the pupil.
	var go := po + Vector2(1.6 * side, 8.6)
	var gz := white_h + bulge * sqrt(1.0 - pow(go.x / R_EYE_R.x, 2.0) - pow(go.y / R_EYE_R.y, 2.0)) + 0.4
	var spot := [[Vector3(go.x, go.y, gz)]]
	var spot_c := [[Color("fffdf8")]]
	for i in range(1, 7):
		var r := 3.5 * i / 6.0
		var ring := []
		var ring_c := []
		for j in 24:
			var a := TAU * j / 24.0
			ring.append(Vector3(go.x + cos(a) * r, go.y + sin(a) * r, gz))
			ring_c.append(Color("fffdf8").lerp(R_PUPIL, smoothstep(2.7, 3.5, r)))
		spot.append(ring)
		spot_c.append(ring_c)
	Pig._rings(g, spot, spot_c, Vector3(0, 0, 1))
	for i in g.verts.size():
		g.verts[i] *= PXM
	return g.commit()


## Colour of the eye at q (sheet px from its centre): warm white, a brown iris that darkens
## toward its rim, a black pupil; both edges are soft.
static func _eye_colour(q: Vector2, io: Vector2, iris: Vector2, po: Vector2, pupil: Vector2) -> Color:
	var di := ((q - io) / iris).length()
	var dp := ((q - po) / pupil).length()
	var c := R_SCLERA.lerp(R_IRIS.lerp(R_IRIS_RIM, smoothstep(0.8, 1.0, di)), smoothstep(1.05, 0.96, di))
	return c.lerp(R_PUPIL, smoothstep(1.12, 0.84, dp))


## Where an eye's node sits in the finished model: the eye's frame at the skin.
func _rooster_eye_transform(side: float) -> Transform3D:
	var f := _rooster_eye_frame(side)
	return Transform3D(Basis(normal_to_model(f[2]), normal_to_model(f[3]), normal_to_model(f[1])), to_model(f[0]) / RF)


## Upper lids, eyebrows, nostrils and the mouth line.
func _rooster_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _rooster_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2] * side
		var up: Vector3 = f[3]
		# Upper lid: a heavy dark line over the top of the eye, from the beak side round to
		# half way down the outer side, thickest over the outer corner.
		g.color = R_LID
		var rim_h := 0.0
		for q in [Vector2(R_EYE_R.x, 0), Vector2(-R_EYE_R.x, 0), Vector2(0, R_EYE_R.y), Vector2(0, -R_EYE_R.y)]:
			rim_h += (_rdrop(s + (f[2] * q.x + up * q.y) * RK, n, 0.0) - s).dot(n) / RK * 0.25
		var lid := []
		var lid_w := []
		for i in 25:
			var t := i / 24.0
			var a := lerpf(deg_to_rad(152.0), deg_to_rad(-14.0), t)
			var w := lerpf(1.0, 3.0, smoothstep(0.0, 0.7, t)) * lerpf(1.0, 0.55, smoothstep(0.85, 1.0, t))
			var q := _rim(a, 0.2)
			# On the eye's own rim plane (not dropped to the skin), deep enough to reach the skin.
			lid.append(s + (out * q.x + up * q.y + n * (rim_h + 0.3)) * RK)
			lid_w.append(Vector2(w, 2.0) * RK)
		g.loft(lid, lid_w, n, 8)
		# Eyebrow: a short soft arc well above the eye, thickest in the middle.
		g.color = R_BROW
		var brow := []
		var brow_w := []
		for q in [[-8.0, 29.6, 1.6], [-4.0, 31.8, 2.8], [0.5, 32.9, 3.4], [5.5, 32.7, 3.4], [10.0, 31.2, 2.8], [13.5, 29.2, 1.6]]:
			brow.append(_rdrop(s + (out * q[0] + up * q[1]) * RK, n, 0.2))
			brow_w.append(Vector2(q[2], 0.9) * RK)
		g.loft(brow, brow_w, n, 10)
		# Nostril: a small dark slot high on the upper beak, near its base.
		var hit := _ray(_beak, V(784.0, 200, side * 11.0), Vector3(0, -1, 0))
		var bn: Vector3 = hit[1]
		var along := (Vector3(1, 0.35, 0) - bn * bn.dot(Vector3(1, 0.35, 0))).normalized()
		g.color = R_NOSTRIL
		g.ellipsoid(hit[0] + bn * 0.1 * RK, Vector3(2.4, 1.3, 0.5) * RK, Basis(along, bn.cross(along).normalized(), bn), 16, 8)
	# Mouth line: a fine dark line in the groove between the two halves, right round the beak.
	g.color = R_MOUTH
	var both: Array = _beak + _beak_low
	var line := []
	var line_w := []
	for i in 33:
		var t := deg_to_rad(lerpf(-78.0, 78.0, i / 32.0))
		var y := 286.6
		var at := []
		for pass_i in 2:
			var from := V(797.0 - 90.0 * cos(t), y, 90.0 * sin(t))
			at = _ray(both, from, V(797, y) - from)
			y = _mouth_y(at[0].z / RK) + 0.6
		line.append(at[0] + at[1] * 0.25 * RK)
		line_w.append(Vector2(0.75, 0.6) * RK)
	g.loft(line, line_w, Vector3.UP, 6)
	return _to_model(g)


## Sheet y of the cut under the upper beak at lateral z.
static func _mouth_y(z: float) -> float:
	return 286.0 + 60.0 * (1.0 - sqrt(1.0 - pow((absf(z) - MOUTH_Z) / MOUTH_R, 2.0)))


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / RF
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= RF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _muzzle_tints, _beak, _beak_low, _comb, _wattles, _wings, _wing_tints, _tail]:
		group.clear()
	_shape()
	var fr := _rooster_eye_frame(1.0)
	print("ROOSTER eye: sheet x %.1f, z %.1f, faces %.0f deg from straight ahead" % [(fr[0].x - X0) / RK + RX, fr[0].z / RK, rad_to_deg(atan2(fr[1].z, -fr[1].x))])
	var root := Node3D.new()
	root.name = "RoosterClayDisplay"
	root.set_meta("source", "User's Rooster Character Blueprint, relaxed idle pose (16 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, R_HACKLE_CREASE, 2.2], ["Beak", _beak, R_BEAK_CREASE, 5.0], ["Beak lower", _beak_low, R_BEAK_CREASE, 5.0], ["Comb", _comb, R_COMB_CREASE, 4.0],
			["Wattles", _wattles, R_COMB_CREASE, 4.0], ["Wings", _wings, R_WING_CREASE, 2.2], ["Tail", _tail, R_TAIL_CREASE, 3.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		elif part[0] == "Wings":
			var body_tints := _tints
			_tints = _wing_tints
			mi.mesh = _paint(mi.mesh)
			_tints = body_tints
		mi.mesh = _fit(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eye_material := _material(0.3)
	for eye in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var mi := MeshInstance3D.new()
		mi.name = eye[0]
		mi.mesh = _rooster_eye(eye[1])
		mi.transform = _rooster_eye_transform(eye[1])
		mi.material_override = eye_material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _rooster_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(V(754, RY, -105)) / RF
	var c := to_model(V(1150, RTOP, 105)) / RF
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
