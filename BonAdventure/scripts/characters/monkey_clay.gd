extends "res://scripts/characters/capybara_clay.gd"
## Clay-style baby monkey traced from the user's "Monkey Character Blueprint" turnaround
## (17 Nov 2026, "Relaxed Idle Pose": front 3/4, front, side, back, rear 3/4). A static display
## model, built once by tools/build_monkey_clay.gd into scenes/animals/monkey_clay.tscn.
##
## Built like the clay capybara and horse (capybara_clay.gd: its surface ray, skin drop and mesh
## helpers; the clay lion's distance-field mesher; the clay giraffe's skin painting). The sheet
## was traced with vtracer first (docs/evidence/monkey-clay-20261117/). Shapes are written in the
## sheet's pixels (side view: x to the right = toward the tail, y down; z lateral, + = the
## monkey's left, from the front and back views) and _pt() scales them into the lion's working
## space. Meshed M_FINE times larger than life and shrunk afterwards.
## Ready for rigging: "Body" is one fused mesh (head, tuft, ears, nose, torso, arms, hands, legs,
## feet, tail) with the tan face mask, belly, ears, hands and feet, the ears' pink and the blush
## painted or coloured on; each eye is its own mesh centred on its own node (LeftEye, RightEye:
## x toward the nose, y up the eye, z out of the face); brows, the eyes' upper rims, nostrils and
## the smile are "Face details".
## Output faces -Z (head), +Y up, ground at y = 0.

const M_HEIGHT := 0.85          # town units to the top of the tuft (provisional: the zoo monkey's species height)
const M_GY := 537.0             # sheet y of the soles
const M_TOP := 174.0            # sheet y of the top of the tuft
const M_X := 900.0              # sheet x (side view) placed at the model origin
const M_FINE := 3.6             # meshed this many times larger than life (a grid step of about 3.5 sheet px)
const MK := M_FINE * M_HEIGHT / ((M_GY - M_TOP) * S)

# Colours read from the sheet (brown lit a2613e, mid 945734, shade 8a4f2d; tan lit fac392, mid
# f3b17e, shade e9a76f; nose f6ad76-d1834f; ear pink fdaa89-fa9d75; brow b36f41-bb774b; smile
# 9c5926; iris 663817-5d3313, under the rim 4b2c15; pupil 1f0f00; white f6dec9), the brown and
# tan a little deeper so they hold under the town's bright daylight.
const M_BROWN := Color("82492b")
const M_BROWN_CREASE := Color("5e321a")
const M_TAN := Color("f0b28a")
const M_NOSE := Color("e2996c")
const M_EAR_IN := Color("f5a47a")
const M_BLUSH := Color("f6a07c")
const M_BROW := Color("b8723f")
const M_LINE := Color("7e3f17")
const M_NOSTRIL := Color("8a4524")
const M_RIM := Color("2c1405")
const M_SCLERA := Color("f8e8d8")
const M_IRIS := Color("6a3c19")       # low in the iris
const M_IRIS_TOP := Color("3a1c07")   # under the upper rim
const M_PUPIL := Color("1a0b02")
const M_GLINT := Color("fffaf3")

# Eyes, measured in the front view at 8x (sheet px as the front view shows them): big, upright
# ovals set flush in the mask with a slight lens bulge. The dark iris fills almost all of the eye
# and sits a little toward the nose; the warm white shows as a crescent on the outer side and a
# sliver below; a large round pupil; one round catch-light high in each eye, toward the monkey's
# left in both (one light); a thin dark rim over the top.
const M_EYE_Y := 294.0                    # front view: middle of the eye
const M_EYE_Z := 44.0                     # front view: from the middle of the face
const M_EYE_R := Vector2(19.3, 21.6)      # half width, half height on the skin (the front view shows them about 10% narrower)
const M_IRIS_C := Vector2(2.0, -0.6)      # (toward the nose, up) from the eye's middle
const M_IRIS_R := Vector2(17.5, 21.2)
const M_PUPIL_C := Vector2(1.8, -2.0)
const M_PUPIL_R := Vector2(10.0, 10.4)
const M_GLINT_C := Vector2(7.0, 8.6)
const M_GLINT_R := 3.7
const M_EYE_OUT := 25.0                  # degrees the eye turns out from straight ahead
const M_EYE_UP := 18.0                   # and up: the plane of the skin under it
const M_BULGE := 2.6                      # the lens: sheet px proud of the skin at the eye's middle

## The tan face mask in the front view: the top edge (two round lobes over the eyes and the
## brown point between them) as [|z|, sheet y], the half width down the cheeks as [sheet y,
## |z|], and its back edge in the side view as [sheet y, sheet x].
const M_MASK_TOP := [[0.0, 253.0], [8.0, 249.5], [18.0, 243.5], [28.0, 240.0], [40.0, 238.5], [52.0, 240.5],
		[62.0, 246.0], [72.0, 256.0], [80.0, 270.0], [85.0, 288.0], [87.0, 300.0]]
const M_MASK_SIDE := [[288.0, 84.0], [320.0, 81.0], [340.0, 77.0], [352.0, 70.0], [360.0, 62.0],
		[368.0, 53.0], [375.0, 41.0], [380.0, 27.0], [384.0, 0.0]]
const M_MASK_BACK := [[230.0, 846.0], [262.0, 851.0], [292.0, 850.0], [315.0, 840.0], [335.0, 830.0],
		[360.0, 820.0], [380.0, 813.0], [410.0, 813.0]]
## The tan belly in the front view: middle, half width, half height, and the top edge (two soft
## bumps, a shallow dip in the middle) as [|z|, sheet y].
const M_BELLY := [0.0, 454.0, 29.0, 50.0]
const M_BELLY_TOP := [[0.0, 404.0], [8.0, 399.0], [16.0, 398.0], [23.0, 402.0], [30.0, 412.0]]

## The head's sections along the side view (see capybara_clay.gd's loft): [sheet x, top y,
## bottom y, widest y, half width, upper squareness, lower squareness]. Tops and bottoms are
## read column by column from the sheet's side view (the crown under the tuft and the jaw
## behind x 836, hidden there by the tuft and the neck, carried on smoothly); half widths from
## the front view, growing steadily from the muzzle back to the skull so the face is one
## gently rounded surface. The front sections are the muzzle: low, broad and blunt, its top
## drawn to a soft ridge in the middle (upper squareness under 2) so it rises into the nose
## bridge without a shelf across the face.
const M_HEAD := [
	[746.0, 309.0, 350.0, 332.0, 22.0, 2.0, 2.2],
	[752.0, 303.0, 358.0, 334.0, 33.0, 2.0, 2.3],
	[758.0, 300.0, 366.0, 335.0, 42.0, 2.0, 2.4],
	[764.0, 298.0, 371.0, 336.0, 49.0, 1.5, 2.4],
	[770.0, 288.0, 375.0, 336.0, 55.0, 1.4, 2.4],
	[776.0, 270.0, 378.0, 334.0, 60.0, 1.5, 2.4],
	[782.0, 254.0, 380.0, 330.0, 64.0, 1.7, 2.4],
	[788.0, 236.0, 382.0, 325.0, 68.0, 1.9, 2.5],
	[794.0, 226.0, 384.0, 320.0, 72.0, 2.0, 2.5],
	[800.0, 221.0, 385.0, 316.0, 76.0, 2.0, 2.5],
	[812.0, 215.0, 388.0, 310.0, 83.0, 2.1, 2.5],
	[824.0, 210.0, 390.0, 306.0, 89.0, 2.2, 2.5],
	[836.0, 207.0, 391.0, 303.0, 93.0, 2.3, 2.5],
	[860.0, 204.0, 391.0, 300.0, 96.0, 2.3, 2.5],
	[880.0, 204.0, 389.0, 298.0, 96.0, 2.3, 2.4],
	[900.0, 206.0, 384.0, 297.0, 95.0, 2.3, 2.3],
	[920.0, 212.0, 378.0, 296.0, 91.0, 2.2, 2.2],
	[932.0, 218.0, 372.0, 295.0, 87.0, 2.1, 2.1],
	[944.0, 226.0, 366.0, 295.0, 80.0, 2.0, 2.0]]
## The loft closes 10 px inside the round back of the skull (an ellipsoid, see _shape), so the
## point where it closes, which shades as a dimple, never shows.
const M_HEAD_CAPS := Vector2(6.0, 24.0)    # length of the rounded muzzle end and of the back end

var _cranium := {}
var _torso := []
var _arms := []


func _init() -> void:
	_px = MK
	_ox = M_X
	_gy = M_GY
	_fine = M_FINE
	_stretch = 1.0


func me(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> Dictionary:
	ell(g, c, r * _px, col, k * _px, crease, basis)
	return g[-1]


func mc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * _px, rb * _px, col, k * _px)


## A basis whose x points along `dir` (the others square to it, y as near up as it can be).
static func _along(dir: Vector3) -> Basis:
	var x := dir.normalized()
	var z := x.cross(Vector3.UP)
	if z.length() < 0.01: z = Vector3(0, 0, 1)
	z = z.normalized()
	return Basis(x, z.cross(x).normalized(), z)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: a soft pear sitting upright, narrow at the shoulders, broad and low at the seat.
	_torso.append(me(b, _pt(912, 428), Vector3(58, 52, 44), M_BROWN))
	_torso.append(me(b, _pt(935, 478), Vector3(72, 58, 54), M_BROWN, 40.0))
	carve(b, _pt(930, M_GY + 60.0), Vector3(400, 60, 400) * _px, M_BROWN)
	# Hind legs: a big round thigh on each side, folded up with the foot flat under its front.
	for side in [-1.0, 1.0]:
		var z: float = side * 66.0
		me(b, _pt(956, 474, z), Vector3(56, 45, 34), M_BROWN, 14.0, false, Basis(Vector3(0, 0, 1), deg_to_rad(-12.0)))
		# Foot: a long low tan pad with four round toes in front.
		var fz: float = side * 84.0
		me(b, _pt(940, 521, fz), Vector3(46, 15.5, 22), M_TAN, 8.0)
		for t in [-1.5, -0.5, 0.5, 1.5]:
			me(b, _pt(901.0 + absf(t) * 4.0, 525.5, fz + t * 10.5), Vector3(11, 11, 6.2), M_TAN, 2.0)
	# Arms: straight, round and a little tapered, from the shoulders down to the hands between the feet.
	for side in [-1.0, 1.0]:
		var top := _pt(884, 412, side * 46.0)
		var wrist := _pt(846, 497, side * 41.0)
		mc(b, top, wrist, 18.5, 16.5, M_BROWN, 12.0)
		_arms.append(b[-1])
		# Hand: a tan pad with four round fingers resting on the ground.
		var hz: float = side * 37.0
		me(b, _pt(846, 517, hz), Vector3(27, 17, 23), M_TAN, 7.0)
		for t in [-1.5, -0.5, 0.5, 1.5]:
			me(b, _pt(818.0 + absf(t) * 3.5, 525.0, hz + t * 11.0), Vector3(12, 12, 6.4), M_TAN, 2.0)
	# Head: ONE lofted mass (capybara_clay.gd's loft), so the face is a single smooth surface:
	# the round skull, a gently rounded face and the broad, soft muzzle low in front, with no
	# seams between separate shapes. Run into the shoulders below.
	loft(b, M_HEAD, M_HEAD_CAPS, M_BROWN, 18.0)
	# The round back of the skull (sheet side view: back at x 978, crown 205; front view: 95 to
	# either side), lying just inside the loft over the crown and sides and inside the face, so
	# it shows only behind, where it closes the head as one smooth dome.
	_cranium = me(b, _pt(884, 297), Vector3(94, 92, 95), M_BROWN, 24.0)
	# Nose: a small, wide, rounded pad on the front of the muzzle.
	me(b, _pt(750, 318), Vector3(8, 7.5, 16.5), M_NOSE, 5.0)
	# Tuft: a little swirl of four rounded clay curls on the crown, leaning back.
	for q in [[846.0, 203.0, -18.0, Vector3(17, 12, 13), -25.0], [868.0, 189.0, -4.0, Vector3(21, 14, 14), 10.0],
			[893.0, 201.0, 15.0, Vector3(18, 12, 13), 30.0], [863.0, 206.0, 23.0, Vector3(14, 10, 11), 0.0]]:
		me(b, _pt(q[0], q[1], q[2]), q[3], M_BROWN, 8.0, true, Basis(Vector3(0, 0, 1), deg_to_rad(q[4])))
	# Ears: big round tan cups at the sides, opening forward and outward, run into the skull at
	# the base, with a pink hollow.
	for side in [-1.0, 1.0]:
		var open := Vector3(-0.72, 0.0, side * 0.69).normalized()
		var up := Vector3.UP
		var basis := Basis(open, up, open.cross(up).normalized())
		var c := _pt(902, 315, side * 112.0)
		var hollow := c + open * 7.0 * _px
		var cup := Vector3(8, 25, 22) * _px
		_monkey_ear(b, c, basis, Vector3(11, 35, 32) * _px, hollow, cup, 6.0 * _px)
		_tints.append({"t": "ell", "c": hollow, "r": cup + Vector3(1.5, 1.5, 1.5) * _px, "inv": basis.inverse(), "col": M_EAR_IN,
				"soft": CELL * 0.6, "out_of": _cranium})
		# The brown of the head runs onto the ear where it joins the skull.
		_tints.append({"t": "root", "c": c, "r": Vector3.ONE * 60.0 * _px, "col": M_BROWN, "soft": CELL * 1.2})
	# Tail: rises from the seat close behind the back, then curls back and to the right into a hook.
	var tail := [[990.0, 497.0, 0.0, 17.5], [1016.0, 482.0, -2.0, 17.0], [1033.0, 458.0, -4.0, 16.5], [1035.0, 436.0, -6.0, 16.5],
			[1030.0, 414.0, -8.0, 16.5], [1022.0, 394.0, -10.0, 16.5], [1017.0, 374.0, -12.0, 16.5], [1019.0, 357.0, -15.0, 16.5],
			[1030.0, 344.0, -19.0, 16.5], [1048.0, 338.0, -24.0, 16.5], [1065.0, 344.0, -28.0, 16.5], [1075.0, 358.0, -31.0, 16.3],
			[1077.0, 375.0, -33.0, 16.0], [1076.0, 386.0, -34.0, 15.8]]
	for i in tail.size() - 1:
		var a: Array = tail[i]
		var e: Array = tail[i + 1]
		mc(b, _pt(a[0], a[1], a[2]), _pt(e[0], e[1], e[2]), a[3], e[3], M_BROWN, 14.0 if i == 0 else 0.5)
	me(b, _pt(1076, 386, -34), Vector3(15.8, 15.8, 15.8), M_BROWN, 3.0)

	# Painted areas, in order after the ears': the tan mask, the nose's own colour over it, the
	# tan belly, and the blush.
	_tints.append({"t": "mask", "c": _pt(800, 310), "r": Vector3.ONE * 140.0 * _px, "col": M_TAN, "soft": CELL * 0.5})
	_tint(_pt(750, 318), Vector3(9.5, 9, 18) * _px, Basis(), M_NOSE, CELL * 0.8)
	_tints.append({"t": "belly", "c": _pt(870, 448), "r": Vector3.ONE * 90.0 * _px, "col": M_TAN, "soft": CELL * 0.5})
	for side in [-1.0, 1.0]:
		var cheek: Vector3 = _ray(b, _pt(600, 328, side * 68.0), Vector3(1, 0, 0))[0]
		_tint(cheek, Vector3(20, 14, 18) * _px, Basis(), M_BLUSH, CELL * 5.0)


## An ear as one mass: a round, thick disc with a hollow pressed into its face.
func _monkey_ear(g: Array, c: Vector3, basis: Basis, r: Vector3, hollow: Vector3, cup: Vector3, k: float) -> void:
	var solid := {"t": "ell", "c": c, "r": r, "inv": basis.inverse()}
	var hole := {"t": "ell", "c": hollow, "r": cup, "inv": basis.inverse()}
	var m := maxf(r.x, maxf(r.y, r.z))
	g.append({"t": "fn", "fn": func(p: Vector3) -> float: return maxf(_dist(solid, p), -_dist(hole, p)),
			"lo": c - Vector3.ONE * m, "hi": c + Vector3.ONE * m, "k": k, "col": M_TAN, "crease": false, "paint": false})


## The skin colour with the monkey's painted areas: "mask" (the face, from its front-view outline
## and its side-view back edge), "belly" (on the torso only, from its front-view outline),
## "root" (brown on the ear near the skull) and painted ellipsoids.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 10000.0
		var sx := _ox + (p.x - X0) / _px
		var sy := _gy - p.y / _px
		var sz := absf(p.z / _px)
		if t.t == "mask":
			var top := Pig._curve(M_MASK_TOP, minf(sz, 87.0))
			var half := Pig._curve(M_MASK_SIDE, clampf(sy, 288.0, 384.0)) if sy > 288.0 else 84.0
			d = maxf(maxf(top - sy, sz - half), sx - Pig._curve(M_MASK_BACK, clampf(sy, 230.0, 410.0))) * _px
			if sy > 384.0: d = maxf(d, (sy - 384.0) * _px)
		elif t.t == "belly":
			var q := Vector2((p.z / _px - M_BELLY[0]) / M_BELLY[2], (sy - M_BELLY[1]) / M_BELLY[3])
			var e := pow(pow(absf(q.x), 2.4) + pow(absf(q.y), 2.4), 1.0 / 2.4)
			d = maxf((e - 1.0) * M_BELLY[2], Pig._curve(M_BELLY_TOP, minf(absf(p.z / _px - M_BELLY[0]), 30.0)) - sy)
			# On the torso, not the arms: nearer the torso's own shapes than the arms'.
			var on_torso := 10000.0
			for pr in _torso: on_torso = minf(on_torso, _dist(pr, p))
			var on_arm := 10000.0
			for pr in _arms: on_arm = minf(on_arm, _dist(pr, p))
			d = maxf(maxf(d, (on_torso - on_arm) / _px - 5.0), sx - 905.0) * _px
		elif t.t == "root":
			d = maxf(_dist(_cranium, p) / _px - 9.0, 92.0 - sz) * _px
		else:
			d = _dist(t, p)
			if t.has("out_of"): d = maxf(d, 1.5 * _px - _dist(t.out_of, p))   # not where the skull shows inside the ear
		var soft: float = t.soft
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


# --- Eyes ---------------------------------------------------------------------------------

## The skin under the middle of an eye: [point, Basis(toward the nose, up the eye, outward), side].
## `side`: +1 the monkey's left eye (z > 0).
func _monkey_eye(side: float) -> Array:
	var hit := _ray(_body, _pt(600, M_EYE_Y, side * M_EYE_Z), Vector3(1, 0, 0))
	# The eye's facing: the skin's under the whole eye (the lofted face is even there), fixed so
	# both eyes match exactly.
	var n := Vector3(-cos(deg_to_rad(M_EYE_OUT)), sin(deg_to_rad(M_EYE_UP)), side * sin(deg_to_rad(M_EYE_OUT))).normalized()
	var up := (Vector3.UP - n * n.dot(Vector3.UP)).normalized()
	var nose := Vector3(0, 0, -side)
	nose = (nose - n * n.dot(nose))
	nose = (nose - up * nose.dot(up)).normalized()
	return [hit[0] as Vector3, Basis(nose, up, n), side]


## A point of an eye: `q` = (toward the nose, up) from its middle in sheet px, on the skin,
## lifted `lift` px plus the lens bulge.
func _mk_eye_pt(eye: Array, q: Vector2, lift: float) -> Vector3:
	var frame: Basis = eye[1]
	var round := maxf(1.0 - pow(q.x / M_EYE_R.x, 2.0) - pow(q.y / M_EYE_R.y, 2.0), 0.0)
	var base := _bdrop(eye[0] + (frame.x * q.x + frame.y * q.y) * _px, frame.z, 0.0)
	return base + frame.z * (lift + M_BULGE * sqrt(round)) * _px


## An ellipse filled with rings, laid on the eye; colour `top` high in it, `col` low.
func _mk_disc(g, eye: Array, centre: Vector2, r: Vector2, lift: float, col: Color, top := Color(0, 0, 0, 0), clip := false) -> void:
	if top.a == 0.0: top = col
	var n: Vector3 = (eye[1] as Basis).z
	var pts := [[_mk_eye_pt(eye, centre, lift)]]
	var cols := [[top.lerp(col, smoothstep(r.y * 0.35, -r.y * 0.6, 0.0))]]
	for i in range(1, 9):
		var ring := []
		var ring_c := []
		for j in 48:
			var a := TAU * j / 48.0
			var q := centre + Vector2(cos(a) * r.x, sin(a) * r.y) * (i / 8.0)
			if clip:
				# Kept inside the eye's own outline.
				var e := pow(q.x / M_EYE_R.x, 2.0) + pow(q.y / M_EYE_R.y, 2.0)
				if e > 0.94: q *= sqrt(0.94 / e)
			ring.append(_mk_eye_pt(eye, q, lift))
			ring_c.append(top.lerp(col, smoothstep(r.y * 0.35, -r.y * 0.6, q.y - centre.y)))
		pts.append(ring)
		cols.append(ring_c)
	Pig._rings(g, pts, cols, n)


func _monkey_eye_geo(side: float):
	var g := Plaza.Geo.new()
	var eye := _monkey_eye(side)
	_mk_disc(g, eye, Vector2.ZERO, M_EYE_R, 0.3, M_SCLERA)
	_mk_disc(g, eye, M_IRIS_C, M_IRIS_R, 0.55, M_IRIS, M_IRIS_TOP, true)
	_mk_disc(g, eye, M_PUPIL_C, M_PUPIL_R, 0.8, M_PUPIL)
	# One light for both eyes: the catch-light sits toward the monkey's left in each (the
	# sheet's front view shows both up and to the right), so it is not mirrored like the iris.
	_mk_disc(g, eye, Vector2(-side * M_GLINT_C.x, M_GLINT_C.y), Vector2(M_GLINT_R, M_GLINT_R), 1.05, M_GLINT)
	return g


func _monkey_eye_node(side: float) -> Transform3D:
	var eye := _monkey_eye(side)
	var frame: Basis = eye[1]
	var y := normal_to_model(frame.y)
	var z := normal_to_model(frame.z)
	return Transform3D(Basis(y.cross(z), y, z), to_model(_mk_eye_pt(eye, Vector2.ZERO, 0.3)) / _fine)


# --- Face details -------------------------------------------------------------------------

## The eyes' dark upper rims, the brows, the nostrils and the smile.
func _monkey_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _monkey_eye(side)
		var n: Vector3 = (eye[1] as Basis).z
		# Upper rim: a thin dark line round the top of the eye from the nose side over to the
		# outer side, a little heavier over the outer top.
		g.color = M_RIM
		var rim := []
		var rim_w := []
		for i in 21:
			var t := i / 20.0
			var a := deg_to_rad(lerpf(14.0, 196.0, t))
			rim.append(_mk_eye_pt(eye, Vector2(cos(a) * (M_EYE_R.x - 0.2), sin(a) * (M_EYE_R.y - 0.2)), 1.2))
			var w := lerpf(0.45, 1.5, sin(PI * pow(t, 0.8)))
			rim_w.append(Vector2(w, 0.8) * _px)
		g.loft(rim, rim_w, n, 8)
		# Brow: a short soft arched dash over the outer half of the eye, its outer end lower.
		g.color = M_BROW
		var brow := []
		var brow_w := []
		for q in [[37.0, 252.5, 1.2], [42.0, 250.5, 2.0], [47.5, 250.0, 2.3], [53.0, 251.5, 2.1], [57.5, 254.5, 1.6], [60.5, 258.0, 1.0]]:
			var h := _ray(_body, _pt(600, q[1], side * q[0]), Vector3(1, 0, 0))
			brow.append(h[0] + h[1] * 0.35 * _px)
			brow_w.append(Vector2(q[2], 1.0) * _px)
		g.loft(brow, brow_w, n, 10)
		# Nostril: a small dark dent low on each side of the nose.
		g.color = M_NOSTRIL
		var hn := _ray(_body, _pt(600, 319.5, side * 10.0), Vector3(1, 0, 0))
		var nn: Vector3 = hn[1]
		var across := (Vector3(0, 0, side) - nn * nn.dot(Vector3(0, 0, side))).normalized()
		g.ellipsoid(hn[0] - nn * 0.25 * _px, Vector3(4.2, 2.6, 0.8) * _px, Basis(across, nn.cross(across), nn), 18, 8)
	# Smile: one wide thin curve across the lower muzzle, its ends turned up.
	g.color = M_LINE
	var smile := []
	var smile_w := []
	for i in 29:
		var t := i / 28.0 * 2.0 - 1.0
		var z := t * 43.0
		var y := 355.5 - 17.0 * pow(absf(t), 1.9) - 2.5 * pow(absf(t), 10.0)
		var h := _ray(_body, _pt(600, y, z), Vector3(1, 0, 0))
		smile.append(h[0] + h[1] * 0.2 * _px)
		var w := lerpf(1.25, 0.7, pow(absf(t), 2.0))
		smile_w.append(Vector2(w, w) * _px)
	g.loft(smile, smile_w, Vector3.UP, 6)
	return _local_mesh(g, Transform3D())


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _horns, _hooves, _udder, _ear_tints, _muzzle_tints, _torso]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "MonkeyClayDisplay"
	root.set_meta("source", "User's Monkey Character Blueprint, relaxed idle pose (17 Nov 2026)")
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = _bfit(_paint(_mesh(_body, M_BROWN_CREASE, 3.5)))
	mi.material_override = _material(0.88)
	root.add_child(mi)
	var eye_mat := _material(0.22)
	eye_mat.metallic_specular = 0.45
	for eye in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var node := MeshInstance3D.new()
		node.name = eye[0]
		node.transform = _monkey_eye_node(eye[1])
		node.mesh = _local_mesh(_monkey_eye_geo(eye[1]), node.transform)
		node.material_override = eye_mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _monkey_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(_pt(800, M_GY, -110)) / _fine
	var c := to_model(_pt(1060, M_TOP, 110)) / _fine
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
