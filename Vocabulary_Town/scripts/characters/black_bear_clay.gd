extends "res://scripts/characters/cow_clay.gd"
## Clay-style black bear traced from the user's "Black Bear Character Blueprint" turnaround
## (11 Nov 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display
## model, built once by tools/build_black_bear_clay.gd into scenes/animals/black_bear_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd) and the clay cow's ray helper, eye dome and fine meshing (cow_clay.gd:
## meshed FINE times larger than life and shrunk by _fit). Shapes are written in the bear
## sheet's pixels (side view: x to the right = toward the tail, y down; z lateral, taken from
## the front view, + = the side facing the viewer) and T() scales them into the lion's working
## space. The sheet's side view is turned a little toward the front (the far eye's lid and the
## chest patch show), so lateral parts (ears, eyes, mouth corners) follow the front view.
## The body, head, legs and tail are one dark clay piece with a soft fold where the head sits
## on the neck. The cream muzzle, the dark nose, the ears and the cream claws are separate
## pieces, as on the sheet; the cream chevron on the chest and the pink of the ears are painted
## on the skin; eyes, lids, brows and the mouth line are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const BH := 1.5                 # town units to the ear tops (a cub; not a park_animals.gd species size)
const BGY := 547.0              # sheet y of the soles
const BTOP := 184.0             # sheet y of the ear tops
const BX := 950.0               # sheet x placed at the model origin
const BK := FINE * BH / ((BGY - BTOP) * S)   # sheet pixel -> lion working unit

# Colours read from the sheet (fur lit 5c5150, mid 4b4141, shade 3a3232; cream f0d2a5), the
# cream a little deeper so it holds under the town's bright daylight.
const B_FUR := Color("4a3f3b")
const B_CREASE := Color("382e2b")
const B_CREAM := Color("e6c39a")
const B_CREAM_CREASE := Color("cfa97c")
const B_CLAW := Color("e6cba4")
const B_EAR_PINK := Color("cf827c")
const B_NOSE := Color("241c1b")
const B_BROW := Color("2a2222")
const B_MOUTH := Color("3d251d")
const B_LIP := Color("e2a092")
const B_SCLERA := Color("f8f3ea")
const B_IRIS := Color("2e1c13")
const B_PUPIL := Color("120b08")
const B_GLINT := Color("fffdf8")
const B_LID := Color("171110")
const B_LID_LOW := Color("2c211e")

# Eyes (sheet px, front view): centre height and lateral offset; half-sizes measured face-on
# in the front 3/4 view (21 wide, 23 tall on the sheet's front view).
const B_EYE_Y := 255.0
const B_EYE_Z := 36.0
const B_EYE_R := Vector2(11.6, 11.9)

var _bnose := []
var _claws := []


## Sheet pixel -> working space (y up).
static func T(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - BX) * BK, (BGY - y) * BK, z * BK)


func be(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * BK, col, k * BK, crease, basis)


## A leg: an upright oval column (wider across the body than along it, as on the sheet) from
## `top` to `foot` (sheet x, y) at lateral z, a broad round paw with four toe knuckles, and a
## cream claw under each knuckle.
func _bleg(top: Vector2, foot: Vector2, z: float, r: Vector2) -> void:
	var a := T(top.x, top.y, z)
	var b := T(foot.x, foot.y, z)
	var along := (a - b).normalized()
	var basis := Basis(along.cross(Vector3(0, 0, 1)).normalized(), along, Vector3(0, 0, 1))
	be(_body, (a + b) * 0.5, Vector3(r.x, top.distance_to(foot) * 0.5 + 22.0, r.y), B_FUR, 16.0, false, basis)
	# The oval alone narrows toward the ankle; a straight core keeps the leg a column to the paw.
	cone(_body, (a + b) * 0.5, T(foot.x, BGY - r.x * 0.92 - 3.0, z), r.x * 0.94 * BK, r.x * 0.92 * BK, B_FUR, 10.0 * BK)
	var paw := Vector3(r.x + 1.0, 15.0, r.y)
	var pc := T(foot.x - 6.0, BGY - paw.y, z)
	be(_body, pc, paw, B_FUR, 6.0)
	for o in [-20.0, -6.7, 6.7, 20.0]:
		var front: float = paw.x * sqrt(1.0 - pow(o / paw.z, 2.0))
		be(_body, pc + Vector3(-front + 4.0, 1.0, o) * BK, Vector3(9.0, 10.0, 7.2), B_FUR, 2.5)
		be(_claws, pc + Vector3(-front - 2.5, -6.5, o) * BK, Vector3(6.0, 8.0, 4.4), B_CLAW, 0.0, false,
				Basis(Vector3(0, 0, 1), deg_to_rad(-18.0)))


# --- Shape --------------------------------------------------------------------------------

## Torso, shoulders, haunches, tail and legs (the adult bear, black_bear_adult_clay.gd, replaces
## this with its own body and keeps the rest of _shape).
func _torso_and_legs() -> void:
	var b := _body
	# Torso: a wide, low barrel; a hump of neck and shoulder rising to the back of the head.
	be(b, T(1035, 376), Vector3(100, 93, 124), B_FUR)
	be(b, T(935, 380), Vector3(105, 92, 116), B_FUR, 30.0)
	be(b, T(862, 390), Vector3(60, 74, 100), B_FUR, 30.0)
	be(b, T(985, 420), Vector3(110, 52, 105), B_FUR, 30.0)                  # full, low belly
	be(b, T(915, 300), Vector3(75, 68, 95), B_FUR, 30.0, true)
	be(b, T(975, 318), Vector3(70, 40, 85), B_FUR, 30.0)                    # withers: one line from the neck down to the back
	# Shoulders and haunches: a full round mass over each leg, the rump between the thighs.
	for side in [-1.0, 1.0]:
		be(b, T(888, 378, side * 64.0), Vector3(58, 74, 58), B_FUR, 24.0)
		be(b, T(1100, 420, side * 60.0), Vector3(54, 80, 64), B_FUR, 24.0)
	# Tail: a round ball on the rump.
	be(b, T(1141, 351), Vector3(20, 25, 26), B_FUR, 4.0)

	# Legs, relaxed walk: near front and near hind planted, far front stepping forward, far
	# hind under the belly.
	_bleg(Vector2(884, 410), Vector2(880, 520), 62.0, Vector2(41, 45))
	_bleg(Vector2(858, 410), Vector2(818, 520), -62.0, Vector2(41, 45))
	_bleg(Vector2(1106, 425), Vector2(1110, 520), 64.0, Vector2(48, 46))
	_bleg(Vector2(1050, 425), Vector2(1014, 520), -64.0, Vector2(48, 46))


## The cub's fur: a lighter, softer black than the sheet's (user, 11 Nov 2026). The adult bear
## returns B_FUR.
func _fur() -> Color:
	return Color("625752")


## 1 for the cub's younger face (bigger eyes set a little lower and wider, bigger ears, a
## shorter muzzle; user, 11 Nov 2026), 0 for the face as traced from the sheet (the adult bear).
func _face_youth() -> float:
	return 1.0


## How much the body (not the head) is drawn in toward the neck along the bear, in height and
## across it, so the cub reads as a baby: the same head on a short, round body (user, 11 Nov
## 2026). The adult bear returns Vector3.ONE.
func _body_squash() -> Vector3:
	return Vector3(0.72, 0.95, 0.92)


## Draws the shapes of `group` from index `from` on toward the neck and the ground. The first
## `torso` of them (the torso masses) shrink with it; the rest (tail, legs, paws, claws) only
## move, so the legs stay thick and the paws big under the shorter body.
func _squash(group: Array, from: int, torso: int) -> void:
	var f := _body_squash()
	if f == Vector3.ONE: return
	var pivot := T(880, 0).x
	for i in range(from, group.size()):
		var pr: Dictionary = group[i]
		var whole := i - from < torso
		if pr.t == "ell":
			var c: Vector3 = pr.c
			pr.c = Vector3(pivot + (c.x - pivot) * f.x, c.y * f.y, c.z * f.z)
			var r: Vector3 = pr.r
			pr.r = r * f if whole else r * 0.96
		else:
			var a: Vector3 = pr.a
			var b: Vector3 = pr.b
			pr.a = Vector3(pivot + (a.x - pivot) * f.x, a.y * f.y, a.z * f.z)
			pr.b = Vector3(pivot + (b.x - pivot) * f.x, b.y * f.y, b.z * f.z)
			pr.ra *= 0.96
			pr.rb *= 0.96
		if whole: pr.k *= (f.x + f.y + f.z) / 3.0


func _shape() -> void:
	var b := _body
	var body_from := _body.size()
	var claws_from := _claws.size()
	_torso_and_legs()
	_squash(_body, body_from, 10)   # six torso masses, two shoulders, two haunches; then tail and legs
	_squash(_claws, claws_from, 0)

	# Head: wide and low, a rounder face pushed forward, heavy jowls low at the sides. It
	# rests on the neck with a soft fold.
	be(b, T(850, 262), Vector3(72, 62, 90), B_FUR, 12.0, true)
	be(b, T(858, 240), Vector3(55, 40, 70), B_FUR, 20.0)                    # broad flat crown
	be(b, T(832, 262), Vector3(56, 58, 66), B_FUR, 20.0)
	for side in [-1.0, 1.0]:
		be(b, T(848, 292, side * 44.0), Vector3(52, 40, 48), B_FUR, 22.0)

	# Muzzle: a short cream ball pressed on the face, two full upper lips and a small chin.
	var m := _muzzle
	be(m, T(779, 290), Vector3(38, 32, 36), B_CREAM)
	be(m, T(768, 273), Vector3(24, 17, 27), B_CREAM, 8.0)                   # bridge under the nose, up between the eyes
	for side in [-1.0, 1.0]:
		be(m, T(757, 295, side * 13.0), Vector3(17, 14, 17), B_CREAM, 7.0)
	be(m, T(771, 310), Vector3(24, 11.5, 22), B_CREAM, 4.0)

	# Nose: a wide rounded triangle sitting on top of the muzzle's front, point down.
	be(_bnose, T(752, 273), Vector3(14, 11.5, 18.5), B_NOSE)
	be(_bnose, T(749, 281), Vector3(7, 7, 6.5), B_NOSE, 6.0)
	for side in [-1.0, 1.0]:
		var at: Vector3 = _ray(_bnose, T(650, 279, side * 7.5), Vector3(1, 0, 0))[0]
		carve(_bnose, at, Vector3(3.2, 3.2, 3.8) * BK, B_NOSE)
	# Younger face: the muzzle is drawn back toward the face and the nose rides in with it.
	var short := 1.0 - 0.22 * _face_youth()
	var face_x := T(800, 0).x
	for pr in m:
		pr.c.x = face_x + (pr.c.x - face_x) * short
		pr.r.x *= short
	for pr in _bnose:
		pr.c.x = face_x + (pr.c.x - face_x) * short

	# Ears: thick round discs on the top corners of the head, facing forward and 42 degrees
	# outward; a round hollow in the front, painted pink, inside a broad rolled rim.
	for side in [-1.0, 1.0]:
		var a := deg_to_rad(42.0)
		var n := Vector3(-cos(a), 0, side * sin(a))
		var across := n.cross(Vector3.UP).normalized()
		var basis := Basis(n, Vector3.UP, across)
		var c := T(874, 212, side * 68.0)
		var big := 1.0 + 0.18 * _face_youth()
		be(_ears, c, Vector3(16, 27.5, 27.5) * big, B_FUR, 0.0, false, basis)
		var inward := across * (-1.0 if across.z * side > 0.0 else 1.0)
		var hollow := c + (n * 16.0 + Vector3(0, -2.5, 0) + inward * 2.5) * BK * big
		var hole := Vector3(8.0, 17.0, 17.0) * big
		carve(_ears, hollow, hole * BK, B_FUR, basis)
		_ear_tints.append({"t": "blob", "c": hollow, "r": Vector3.ONE * 60.0 * BK,
				"parts": [{"t": "ell", "c": hollow, "r": (hole + Vector3(1.5, 0.8, 0.8)) * BK, "inv": basis.inverse()}],
				"k": 4.0 * BK, "col": B_EAR_PINK, "soft": CELL * 0.35})

	# Chest: a cream chevron from shoulder to shoulder (painted; see _tinted).
	_tints.append({"t": "vee", "c": T(840, 382), "r": Vector3.ONE * 130.0 * BK, "xmax": T(905, 0).x,
			"col": B_CREAM, "soft": CELL * 0.6})


## The chevron's edge in the front view (sheet px; negative inside): the top edge sags from the
## shoulder tips (|z| 71, y 347) to y 379 on the centre line, the lower edges run straight from
## the tips to the point at y 417.
static func _vee(y: float, z: float) -> float:
	var u := minf(absf(z) / 71.0, 1.2)
	var top := 379.0 - 32.0 * pow(u, 1.05)
	var bottom := 417.0 - 70.0 * u
	return maxf(top - y, y - bottom) * 0.8


## cow_clay.gd's skin colour, extended with the chest chevron ("vee": a front-view outline
## pressed straight back onto the chest, no further than xmax).
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 10000.0
		if t.t == "vee":
			d = maxf(_vee(BGY - p.y / BK, p.z / BK) * BK, p.x - t.xmax)
		elif t.t == "blob":
			var k: float = t.k
			for part in t.parts:
				var dp := _dist(part, p)
				var h := maxf(k - absf(d - dp), 0.0) / k
				d = minf(d, dp) - h * h * k * 0.25
		else:
			d = _dist(t, p)
		var soft: float = t.soft
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


## Drops a point near a group's surface onto it along -n, then lifts it `lift` sheet px.
func _bdrop(group: Array, p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * BK
	for i in 900:
		if _field(group, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * BK


# --- Face details -------------------------------------------------------------------------

## The skin under an eye: [centre, Basis(toward the outer corner, up, outward normal)].
func _bear_eye(side: float) -> Array:
	var hit := _ray(_body, T(650, B_EYE_Y + 4.0 * _face_youth(), side * (B_EYE_Z + 2.0 * _face_youth())), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var out := Vector3.UP.cross(n).normalized() * side
	return [hit[0], Basis(out, n.cross(out).normalized() * side, n)]


## Eyes, from the sheet's front, 3/4 and side views: a round eye, slightly taller than wide,
## set in the face and gently domed. Almost all of it is the dark iris and pupil, pushed
## toward the nose; the white shows as a crescent down the outer side and a little underneath;
## one round catch-light high on the nose side of the pupil. The outline is in _bear_details().
func _bear_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	var es := 1.0 + 0.22 * _face_youth()
	var er := B_EYE_R * es
	for side in [-1.0, 1.0]:
		var eye := _bear_eye(side)
		var s: Vector3 = eye[0]
		var frame: Basis = eye[1]
		var out: Vector3 = frame.x
		var up: Vector3 = frame.y
		var n: Vector3 = frame.z
		# The white's edge lies in the skin: its centre plane sits at the skin's mean height
		# round the eye and the dome stands 2.4 px proud at its middle.
		var edge := 0.0
		for q in [Vector2(er.x, 0), Vector2(-er.x, 0), Vector2(0, er.y), Vector2(0, -er.y)]:
			edge += (_bdrop(_body, s + (out * q.x + up * q.y) * BK, n, 0.0) - s).dot(n) / BK * 0.25
		var white_h := edge - 0.3
		var white := Vector3(er.x, er.y, 2.4 - white_h)
		g.color = B_SCLERA
		g.ellipsoid(s + n * white_h * BK, white * BK, frame, 40, 20)
		# Iris toward the nose and a touch high; a thin lens just proud of the white.
		var io := Vector2(-1.9, 0.5) * es
		var iris := Vector3(9.4 * es, 10.6 * es, 2.0)
		var iris_h := white_h + _dome(white, io.x, io.y) - iris.z + 1.0
		g.color = B_IRIS
		g.ellipsoid(s + (out * io.x + up * io.y + n * iris_h) * BK, iris * BK, frame, 36, 18)
		var po := Vector2(0.0, 0.9) * es
		var pupil := Vector3(8.6 * es, 9.5 * es, 1.5)
		var pupil_h := iris_h + _dome(iris, po.x, po.y) - pupil.z + 0.5
		g.color = B_PUPIL
		g.ellipsoid(s + (out * (io.x + po.x) + up * (io.y + po.y) + n * pupil_h) * BK, pupil * BK, frame, 32, 16)
		var go := Vector2(-2.4, 4.0) * es
		g.color = B_GLINT
		g.ellipsoid(s + (out * (io.x + po.x + go.x) + up * (io.y + po.y + go.y) + n * (pupil_h + _dome(pupil, go.x, go.y) + 0.2)) * BK,
				Vector3(2.0 * es, 2.0 * es, 0.5) * BK, frame, 16, 8)
	return _to_model(g)


## Smooth curve through `keys` ([position, value] rows, positions rising) at x.
static func _through(keys: Array, x: float) -> float:
	for i in keys.size() - 1:
		if x <= keys[i + 1][0] or i == keys.size() - 2:
			var t := clampf((x - keys[i][0]) / (keys[i + 1][0] - keys[i][0]), 0.0, 1.0)
			var p0: float = keys[maxi(i - 1, 0)][1]
			var p1: float = keys[i][1]
			var p2: float = keys[i + 1][1]
			var p3: float = keys[mini(i + 2, keys.size() - 1)][1]
			return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
	return keys[0][1]


## Lid lines, eyebrows, the line from nose to mouth, the smile and the lower lip.
func _bear_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	var er := B_EYE_R * (1.0 + 0.22 * _face_youth())
	for side in [-1.0, 1.0]:
		var eye := _bear_eye(side)
		var s: Vector3 = eye[0]
		var frame: Basis = eye[1]
		var out: Vector3 = frame.x
		var up: Vector3 = frame.y
		var n: Vector3 = frame.z
		# Upper lid: a thick near-black line over the top of the eye, from the nose side round
		# and down the outer side, heaviest over the outer half.
		g.color = B_LID
		var lid := []
		var lid_w := []
		for i in 17:
			var t := i / 16.0
			var a := deg_to_rad(lerpf(-35.0, 200.0, t))
			var q := Vector2(cos(a) * (er.x - 0.2), sin(a) * (er.y - 0.2))
			lid.append(_bdrop(_body, s + (out * q.x + up * q.y) * BK, n, 1.4))
			var w := lerpf(0.6, 1.6, sin(PI * clampf(t * 1.1, 0.0, 1.0)))
			lid_w.append(Vector2(w, 1.2) * BK)
		g.loft(lid, lid_w, n, 8)
		# The rest of the outline, under the eye: a fine dark-brown line.
		g.color = B_LID_LOW
		var under := []
		var under_w := []
		for i in 11:
			var a := deg_to_rad(lerpf(200.0, 325.0, i / 10.0))
			var q := Vector2(cos(a) * (er.x - 0.5), sin(a) * (er.y - 0.5))
			under.append(_bdrop(_body, s + (out * q.x + up * q.y) * BK, n, 0.5))
			under_w.append(Vector2(0.55, 0.55) * BK)
		g.loft(under, under_w, n, 6)
		# Eyebrow: a short raised arc well above the eye, darker than the fur; its outer end
		# lower and drawn to a point, thickest toward the nose.
		g.color = B_BROW
		var brow := []
		var brow_w := []
		for q in [[9.0, 23.5, 0.9], [6.0, 27.0, 2.0], [2.0, 30.0, 2.9], [-3.0, 31.3, 3.3], [-7.5, 31.0, 3.0], [-11.0, 29.3, 1.9]]:
			brow.append(_bdrop(_body, s + (out * q[0] + up * (q[1] + 3.0 * _face_youth())) * BK, n, 0.3))
			brow_w.append(Vector2(q[2], 1.3) * BK)
		g.loft(brow, brow_w, n, 10)
	# Mouth, on the muzzle: rays aimed at the muzzle's upright axis, `deg` round from the front.
	g.color = B_MOUTH
	var philtrum := []
	var philtrum_w := []
	for i in 6:
		var y := lerpf(287.0, 299.0, i / 5.0)
		var h := _ray(_muzzle, T(650, y), Vector3(1, 0, 0))
		philtrum.append(h[0] + h[1] * 0.2 * BK)
		philtrum_w.append(Vector2(0.8, 0.8) * BK)
	g.loft(philtrum, philtrum_w, Vector3(0, 0, 1), 6)
	# Smile: a soft W, dipping under each upper lip and rising to the corners.
	var keys := [[0.0, 299.0], [0.2, 302.0], [0.45, 303.2], [0.72, 299.5], [1.0, 290.0]]
	var smile := []
	var smile_w := []
	for i in 49:
		var t := (i - 24) / 24.0
		var phi := t * deg_to_rad(62.0)
		var dir := Vector3(cos(phi), 0.0, -sin(phi))
		var h := _ray(_muzzle, T(786, _through(keys, absf(t))) - dir * 120.0 * BK, dir)
		smile.append(h[0] + h[1] * 0.2 * BK)
		var w := 0.95 - 0.45 * pow(absf(t), 2.0)
		smile_w.append(Vector2(w, w) * BK)
	g.loft(smile, smile_w, Vector3.UP, 6)
	# Lower lip: a small pink pad under the middle of the smile.
	var lip := _ray(_muzzle, T(650, 304.6), Vector3(1, 0, 0))
	var ln: Vector3 = lip[1]
	var lside := Vector3.UP.cross(ln).normalized()
	g.color = B_LIP
	g.ellipsoid(lip[0] - ln * 0.5 * BK, Vector3(5.5, 1.9, 1.0) * BK, Basis(lside, ln.cross(lside).normalized(), ln), 16, 8)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _horns, _hooves, _udder, _ear_tints, _muzzle_tints, _bnose, _claws]:
		group.clear()
	_shape()
	var fur := _fur()
	var crease := B_CREASE if fur == B_FUR else fur.darkened(0.25)
	for group in [_body, _ears]:
		for pr in group:
			if pr.col == B_FUR: pr.col = fur
	var root := Node3D.new()
	root.name = "BlackBearCubClayDisplay"
	root.set_meta("source", "User's Black Bear Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.9)
	var nose_clay := _material(0.5)
	for part in [["Body", _body, crease, 5.0], ["Muzzle", _muzzle, B_CREAM_CREASE, 5.0], ["Nose", _bnose, B_NOSE, 5.0],
			["Ears", _ears, crease, 6.0], ["Claws", _claws, B_CREAM_CREASE, 5.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Ears": _ear_tints}.get(part[0], [])
		if not paints.is_empty():
			var body_tints := _tints
			_tints = paints
			mi.mesh = _paint(mi.mesh)
			_tints = body_tints
		mi.mesh = _fit(mi.mesh)
		mi.material_override = nose_clay if part[0] == "Nose" else clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _bear_eyes()
	eyes.material_override = _material(0.35)
	eyes.material_override.metallic_specular = 0.25   # the painted catch-light is the only shine
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _bear_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(T(737, BGY, -125)) / FINE
	var c := to_model(T(1154, BTOP, 125)) / FINE
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
