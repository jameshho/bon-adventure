extends "res://scripts/characters/cow_clay.gd"
## Clay-style black and white pig traced from the user's "Pig (Black & White) Character
## Blueprint" turnaround (11 Nov 2026, "Relax Walk Pose": front 3/4, front, side, back,
## rear 3/4). A static display model, built once by tools/build_pig_clay.gd into
## scenes/animals/pig_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd) and the clay cow's blob patches and eye dome (cow_clay.gd); the surface
## ray is its own (_ray), because the snout and muzzle are pressed flat.
## Shapes are written in the pig sheet's pixels (side view: x to the right = toward the tail,
## y down; z lateral, taken from the front view) and PT() scales them into the lion's working
## space. The pig is small (0.95 town units), so it is meshed PF times larger than life and
## shrunk afterwards: the clay grid is 1 cm on the finished model.
## Body, head, legs are one cream clay piece; the dark head and the dark patch round the tail
## are painted on it (the head's edge follows the sheet's side view), as is the blush. The pink
## snout, the dark drooping ears, the dark hooves and the curled tail are separate pieces; the
## eyes, brows, lip and smile are small parts laid on the face.
## The sheet's side view shows a white blaze up the forehead that its front and 3/4 views do
## not; the model follows the front views (no blaze).
## Output faces -Z (head), +Y up, ground at y = 0.

const PH := 0.95                # town units to the top of the head, the zoo pig's display height (park_animals.gd)
const PGY := 532.0              # sheet y of the soles
const PTOP := 259.0             # sheet y of the top of the head
const PX := 940.0               # sheet x placed at the model origin
const PF := 3.0                 # meshed this many times larger than life
const PK := PF * PH / ((PGY - PTOP) * S)   # sheet pixel -> lion working unit

# Colours read from the sheet (dark lit 6e5e5b, mid 584a48, shade 40302f; cream f3e4d3; snout
# f4a898), the cream and pink a little deeper so they hold under the town's bright daylight.
const P_CREAM := Color("ecd6c8")
const P_CREAM_CREASE := Color("d8bdac")
const P_DARK := Color("54453f")
const P_DARK_CREASE := Color("41342f")
const P_HOOF := Color("4a3c38")
const P_SNOUT := Color("f0a696")
const P_SNOUT_CREASE := Color("d98474")
const P_NOSTRIL := Color("9c5449")
const P_LIP := Color("cf7466")
const P_BLUSH := Color("7e4642")
const P_TAIL := Color("e6c8b6")
const P_LINE := Color("2e2424")
const P_BROW := Color("2c2322")
const P_EYE := Color("120d0c")
const P_GLINT := Color("fffdf8")
const P_EYE_LOW := Color("33221c")       # the soft shade low in the eye

# Eyes (sheet px, front view): centre height and lateral offset. Half-sizes on the skin, from
# the sheet's front 3/4 view, which shows the near eye face-on (22 wide, 28.5 tall); they lie
# on the round of the head, so the front view shows them a little narrower.
# Third pass (user, 11 Nov 2026): a little larger, higher and farther apart than measured
# (was 341.4, 45, 12.0 x 14.7), the centres 4 px outside the snout's edges, as on the sheet.
const P_EYE_Y := 339.4
const P_EYE_Z := 47.5
const P_EYE_R := Vector2(13.85, 17.7)
# Fourth pass (user, 11 Nov 2026): 9% wider and 13.5% taller again (was 12.7 x 15.6), an egg
# shape with the fuller half on top, lying on the head's own curve with a slight bulge.
const P_EYE_EGG := 0.07             # the top is this much wider than the middle, the bottom narrower
const P_EYE_BULGE := 1.5            # px the middle stands above the rim
const P_EYE_LIFT := 0.7             # px the whole eye stands above the skin

## The edge of the dark head in the side view: [sheet y, sheet x]; dark is in front of it.
const P_HEAD_EDGE := [[250.0, 950.0], [287.0, 948.0], [330.0, 943.0], [370.0, 934.0], [410.0, 914.0], [440.0, 886.0],
		[458.0, 858.0], [466.0, 800.0], [476.0, 700.0]]


## Sheet pixel -> working space (y up).
static func PT(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - PX) * PK, (PGY - y) * PK, z * PK)


func pe(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * PK, col, k * PK, crease, basis)


func pc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * PK, rb * PK, col, k * PK)


# --- Shape --------------------------------------------------------------------------------

## Legs as [sheet x, lateral z at the foot, radius at the foot]; they widen and lean outward
## toward the body. Standing almost square: the sheet's side view is turned
## about 13 degrees toward the viewer, which is what sets its far legs forward of the near ones
## (the first passes copied that as a 40 px walking stagger; body pass, 11 Nov 2026).
const P_LEGS := [[899.0, 50.0, 21.5], [893.0, -50.0, 21.5], [1099.0, 51.0, 23.5], [1093.0, -51.0, 23.5]]

func _shape() -> void:
	var b := _body
	# Torso: a fat, round barrel, level along the back, full at the rump.
	pe(b, PT(960, 388), Vector3(95, 100, 103), P_CREAM)
	pe(b, PT(1040, 388), Vector3(110, 101, 105), P_CREAM, 20.0)
	pe(b, PT(1085, 392), Vector3(78, 98, 102), P_CREAM, 20.0)
	pe(b, PT(1010, 424), Vector3(125, 64, 102), P_CREAM, 24.0)              # full, low belly
	# Head: one big round ball, as wide as the body (a circle in the sheet's front view, 202
	# across; a boxier head with low cheeks and a jaw was the first pass, user 11 Nov 2026).
	# It sits on the front of the body with a soft fold. A short stub of muzzle carries the snout.
	pe(b, PT(852, 361), Vector3(98, 100, 101), P_CREAM, 9.0)
	pe(b, PT(772, 371), Vector3(36, 28.5, 41), P_CREAM, 12.0)
	carve(b, PT(748 - 30, 371), Vector3(30, 170, 170) * PK, P_CREAM)        # the muzzle ends flat, behind the snout
	# Legs: short columns that taper to the foot and lean in a little (the feet stand closer
	# together than the body is wide), each under a full round mass (shoulder or thigh) that
	# carries the body's side down into the leg, as in the sheet's front and back views.
	for leg in P_LEGS:
		var z_top: float = leg[1] + signf(leg[1]) * 7.0
		if leg[0] > 1000.0:
			pe(b, PT(leg[0], 420, z_top - signf(leg[1]) * 2.0), Vector3(42, 60, 42), P_CREAM, 22.0)
		else:
			pe(b, PT(leg[0] + 21.0, 440, z_top), Vector3(30, 46, 38), P_CREAM, 20.0)   # set back: its front stays behind the dark head's edge
		pc(b, PT(leg[0], 450, z_top), PT(leg[0], 502, leg[1]), leg[2] + 9.0, leg[2], P_CREAM, 12.0)
	# Rump: two soft cheeks, with the faint crease between them from under the tail down.
	for side in [-1.0, 1.0]:
		pe(b, PT(1112, 440, side * 28.0), Vector3(44, 42, 50), P_CREAM, 14.0, true)

	# Snout: a thin pink disc on the front of the muzzle, a rounded shape wider than tall
	# (87 by 58 px) and widest below its middle; two small upright oval nostrils pressed in.
	# Third pass (user, 11 Nov 2026): 2 px wider, 3 px higher, a squarer rim.
	var m := _muzzle
	pe(m, PT(746, 371.5), Vector3(22, 28.5, 32.5), P_SNOUT)
	for side in [-1.0, 1.0]:
		pe(m, PT(746, 377.5, side * 17.5), Vector3(22, 21, 26), P_SNOUT, 14.0)
		pe(m, PT(746, 363, side * 14.5), Vector3(22, 20, 25.5), P_SNOUT, 14.0)
	# The front is pressed flat (a disc with a rounded rim, not a ball): cut by the nearly flat
	# pole of a wide, thin ellipsoid.
	carve(m, PT(735 - 30, 371.5), Vector3(30, 170, 170) * PK, P_SNOUT)
	carve(m, PT(749 + 30, 371.5), Vector3(30, 170, 170) * PK, P_SNOUT)      # and flat behind: a disc 14 px thick
	for side in [-1.0, 1.0]:
		var hole := Vector3(4.2, 6.4, 5.0)
		var at: Vector3 = _ray(m, PT(650, 373.4, side * 17.5), Vector3(1, 0, 0))[0]
		carve(m, at, hole * PK, P_SNOUT)
		_muzzle_tints.append({"t": "ell", "c": at, "r": (hole + Vector3.ONE * 1.0) * PK, "inv": Basis(), "col": P_NOSTRIL, "soft": CELL * 0.5})

	# Ears: long, soft, drooping paddles from the top of the head, curving outward and down
	# over its sides: four flattened lumps of clay run together along a curve (30, 45, 60, then
	# 64 degrees below level), narrow where they leave the head, widest past the middle and
	# drawn out gently to a narrower rounded tip. The broad face looks outward and up and
	# 18 degrees forward, the front edge lying on the head: a band about 40 px wide from the
	# front, a broad shield from the side.
	# (Second pass: strands of clay about 40 px thick with round ends, which read short and
	# bulky; thinner strands read as stiff, knuckled plates. User, 11 Nov 2026.)
	for side in [-1.0, 1.0]:
		var tilt := deg_to_rad(18.0)
		# [sheet y, lateral z of the centre, degrees below level, thickness, length, width (half-sizes)]
		for lump in [[277.0, 65.3, 30.0, 13.0, 30.0, 29.0], [294.5, 86.7, 45.0, 14.5, 34.0, 38.0],
				[316.8, 103.2, 60.0, 14.0, 33.0, 37.0], [330.0, 110.2, 64.0, 11.0, 25.0, 27.0]]:
			var a := deg_to_rad(lump[2])
			var along := Vector3(0.0, -sin(a), side * cos(a))
			var outward := Vector3(0.0, cos(a), side * sin(a))
			var flat := outward * cos(tilt) - Vector3(1, 0, 0) * sin(tilt)
			var across := Vector3(1, 0, 0) * cos(tilt) + outward * sin(tilt)
			pe(_ears, PT(850, lump[0], side * lump[1]), Vector3(lump[3], lump[4], lump[5]), P_DARK,
					0.0 if lump[0] == 277.0 else 12.0, false, Basis(flat, along, across))

	# Hooves: small dark blocks a touch wider than the feet and about 22 px tall, rounded into
	# the leg at the top, two toes to the front, flat soles. (First: wide low domes, which read
	# as plates; then blocks as wide as untapered legs, which read as boots.)
	for leg in P_LEGS:
		pc(_hooves, PT(leg[0] - 1.0, 520, leg[1]), PT(leg[0] - 2.0, 546, leg[1]), leg[2] + 2.0, leg[2] + 2.5, P_HOOF)
		for t in [-1.0, 1.0]:
			pe(_hooves, PT(leg[0] - leg[2] + 5.0, 525, leg[1] + t * 7.5), Vector3(11.5, 10, 10), P_HOOF, 3.0, true)
	for leg in P_LEGS:
		carve(_hooves, PT(leg[0], PGY + 40.0, leg[1]), Vector3(120, 40, 120) * PK, P_HOOF)

	# Tail: one curl standing on the top of the rump, turned half toward the side so it reads
	# as a loop from the side and from behind; dark where it leaves the patch, then cream.
	var u := Vector3(0.6, 0.0, 0.8)
	var nrm := Vector3(-0.8, 0.0, 0.6)
	var centre := PT(1153, 320, 2.0)
	var pts := []
	var radii := []
	pts.append(PT(1132, 334))
	radii.append(7.5)
	for i in 13:
		var t := i / 12.0
		var a := deg_to_rad(lerpf(215.0, 215.0 + 400.0, t))
		var rr := lerpf(18.0, 13.0, t)
		pts.append(centre + (u * cos(a) * rr + Vector3.UP * sin(a) * rr + nrm * lerpf(-1.0, 7.0, t)) * PK)
		radii.append(lerpf(6.5, 5.0, t))
	for i in pts.size() - 1:
		pc(_tuft, pts[i], pts[i + 1], radii[i], radii[i + 1], P_DARK if i < 3 else P_TAIL, 0.0 if i == 0 else 2.5)

	# Painted areas, in order: the dark head, the dark patch round the tail, the blush.
	_tints.append({"t": "cap", "c": PT(850, 360), "r": Vector3.ONE * 260.0 * PK, "col": P_DARK, "soft": CELL * 0.5})
	_blob([[PT(1122, 316), Vector3(44, 30, 40)]], P_DARK, 6.0)
	for tint in _tints:
		if tint.t == "blob":
			for part in tint.parts: part.r = part.r * PK / CK   # _blob scales by the cow's CK
			tint.r = tint.r * PK / CK
			tint.k = tint.k * PK / CK
	for side in [-1.0, 1.0]:
		_tint(PT(790, 367, side * 71.0), Vector3(14, 10, 10) * PK, Basis(), P_BLUSH, CELL * 3.0)


## Smooth curve through `keys` ([position, value] rows, positions rising) at x.
static func _curve(keys: Array, x: float) -> float:
	for i in keys.size() - 1:
		if x <= keys[i + 1][0] or i == keys.size() - 2:
			var t := clampf((x - keys[i][0]) / (keys[i + 1][0] - keys[i][0]), 0.0, 1.0)
			var p0: float = keys[maxi(i - 1, 0)][1]
			var p1: float = keys[i][1]
			var p2: float = keys[i + 1][1]
			var p3: float = keys[mini(i + 2, keys.size() - 1)][1]
			return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
	return keys[0][1]


## cow_clay.gd's skin colour, extended with the dark head ("cap": everything in front of the
## side-view edge P_HEAD_EDGE and inside the head's circle as seen from the front).
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 10000.0
		if t.t == "cap":
			var sheet_x := PX + (p.x - X0) / PK
			var sheet_y := PGY - p.y / PK
			# Low down, from the front, the dark is the round of the head and no more: a circle
			# 101 px about the head's middle (the legs beside it stay cream, as on the sheet).
			var ring := Vector2(p.z / PK, sheet_y - 361.0).length() - 101.0 - maxf(430.0 - sheet_y, 0.0) * 6.0
			d = maxf(sheet_x - _curve(P_HEAD_EDGE, sheet_y), ring) * PK * 0.8
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


## First point of a group's surface along a ray (working space): [point, outward normal].
## Replaces cow_clay.gd's: the wide thin ellipsoids that press the snout and muzzle flat
## overstate the distance deep inside them, so steps are capped at half a sheet px and the
## crossing is then closed in by halving.
func _ray(group: Array, from: Vector3, dir: Vector3) -> Array:
	var d := dir.normalized()
	var p := from
	var before := from
	var found := false
	for i in 4000:
		var f := _field(group, p)
		if f <= 0.0:
			found = true
			break
		before = p
		p += d * clampf(f * 0.5, 0.05, 0.5 * PK)
	if found:
		for i in 12:
			var mid := (before + p) * 0.5
			if _field(group, mid) <= 0.0: p = mid
			else: before = mid
	var h := 0.5
	var n := Vector3(
		_field(group, p + Vector3(h, 0, 0)) - _field(group, p - Vector3(h, 0, 0)),
		_field(group, p + Vector3(0, h, 0)) - _field(group, p - Vector3(0, h, 0)),
		_field(group, p + Vector3(0, 0, h)) - _field(group, p - Vector3(0, 0, h))).normalized()
	return [p, n]


## Drops a point near the skin onto it along -n, then lifts it `lift` sheet px.
func _pdrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * PK
	for i in 900:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * PK


# --- Face details -------------------------------------------------------------------------

## The skin under an eye: [centre, Basis(toward the outer corner, up, outward normal)]. The
## eyes lean 5 degrees, tops toward each other, as on the sheet.
func _pig_eye(side: float) -> Array:
	var hit := _ray(_body, PT(650, P_EYE_Y, side * P_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var out := Vector3.UP.cross(n).normalized() * side
	var frame := Basis(out, n.cross(out).normalized() * side, n)
	return [hit[0], Basis(n, deg_to_rad(5.0) * side) * frame]


## A point of an eye: `q` = (toward the outer corner, up) from its centre in sheet px, on the
## skin under it, lifted by the eye's own slight bulge plus `extra` px.
func _eye_at(eye: Array, q: Vector2, extra: float) -> Vector3:
	var frame: Basis = eye[1]
	var v := q.y / P_EYE_R.y
	var u := q.x / (P_EYE_R.x * (1.0 + P_EYE_EGG * v))
	var bulge := P_EYE_BULGE * maxf(1.0 - u * u - v * v, 0.0)
	return _pdrop(eye[0] + (frame.x * q.x + frame.y * q.y) * PK, frame.z, P_EYE_LIFT + bulge + extra)


## The eye's outline at `rho` (0 centre, 1 rim) and angle `a` (0 = outer corner, PI/2 = top).
static func _eye_q(rho: float, a: float) -> Vector2:
	var v := rho * sin(a)
	return Vector2(P_EYE_R.x * (1.0 + P_EYE_EGG * v) * rho * cos(a), P_EYE_R.y * v)


## One triangle with a colour per corner (Plaza.Geo.tri gives all three the same).
static func _ctri(g, pts: Array, nrm: Array, col: Array) -> void:
	var order := [0, 1, 2]
	if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(nrm[0] + nrm[1] + nrm[2]) > 0.0: order = [0, 2, 1]
	for i in order:
		g.verts.append(pts[i])
		g.norms.append(nrm[i])
		g.cols.append(col[i])


## A patch of rings (each a closed list of points; ring 0 may be a single point), shaded
## smoothly between the given colours.
static func _rings(g, pts: Array, cols: Array, n: Vector3) -> void:
	for i in pts.size() - 1:
		var inner: Array = pts[i]
		var outer: Array = pts[i + 1]
		var count := outer.size()
		for j in count:
			var k := (j + 1) % count
			var a: Vector3 = inner[j % inner.size()]
			var b: Vector3 = inner[k % inner.size()]
			var ca: Color = cols[i][j % inner.size()]
			var cb: Color = cols[i][k % inner.size()]
			_ctri(g, [a, outer[j], outer[k]], [n, n, n], [ca, cols[i + 1][j], cols[i + 1][k]])
			if inner.size() > 1:
				_ctri(g, [a, outer[k], b], [n, n, n], [ca, cols[i + 1][k], cb])


## Eyes, from the sheet's front, 3/4 and side views: an upright egg-shaped oval, the fuller
## half on top, lying on the head's own curve with a slight bulge (not a flat sticker, not a
## ball). Glossy near-black almost all over (no white of the eye), a soft dark-brown shade
## only along the bottom; a fine white accent just inside the rim, strongest low on the outer
## side and fading out toward the top; one soft round reflection high on the nose side.
func _pig_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _pig_eye(side)
		var n: Vector3 = (eye[1] as Basis).z
		# The eye itself: rings from the centre to the rim, shaded per point.
		var pts := [[_eye_at(eye, Vector2.ZERO, 0.0)]]
		var cols := [[P_EYE]]
		for i in range(1, 11):
			var ring := []
			var ring_c := []
			for j in 48:
				var q := _eye_q(i / 10.0, TAU * j / 48.0)
				ring.append(_eye_at(eye, q, 0.0))
				ring_c.append(P_EYE.lerp(P_EYE_LOW, 0.85 * smoothstep(-0.3, -0.95, q.y / P_EYE_R.y)))
			pts.append(ring)
			cols.append(ring_c)
		# Smooth normals from the rings themselves, so the light follows the head's curve.
		var first := g.verts.size()
		_rings(g, pts, cols, n)
		var sums := {}
		for at in range(first, g.verts.size(), 3):
			var face: Vector3 = (g.verts[at + 1] - g.verts[at]).cross(g.verts[at + 2] - g.verts[at])
			if face.dot(n) < 0.0: face = -face
			for k in 3:
				sums[g.verts[at + k]] = sums.get(g.verts[at + k], Vector3.ZERO) + face
		for at in range(first, g.verts.size()):
			g.norms[at] = (sums[g.verts[at]] as Vector3).normalized()
		# White accent: a fine line 88 % of the way out, from above the outer corner round the
		# outer side to under the eye; thickest low on the outer side, a hair at the top.
		g.color = P_GLINT
		var arc := []
		var arc_w := []
		for i in 29:
			var t := i / 28.0
			arc.append(_eye_at(eye, _eye_q(0.88, deg_to_rad(lerpf(62.0, -110.0, t))), 0.1))
			var w := 0.12 + 0.46 * pow(sin(PI * pow(t, 1.3)), 1.5)
			arc_w.append(Vector2(w, 0.22) * PK)
		g.loft(arc, arc_w, n, 6)
		# Reflection: a white spot with a soft edge.
		var go := Vector2(-0.31 * P_EYE_R.x, 0.42 * P_EYE_R.y)
		var spot := [[_eye_at(eye, go, 0.14)]]
		var spot_c := [[P_GLINT]]
		for i in range(1, 8):
			var r := 3.7 * i / 7.0
			var ring := []
			var ring_c := []
			for j in 24:
				var a := TAU * j / 24.0
				ring.append(_eye_at(eye, go + Vector2(cos(a), sin(a)) * r, 0.14))
				ring_c.append(P_GLINT.lerp(P_EYE, smoothstep(2.1, 3.7, r)))
			spot.append(ring)
			spot_c.append(ring_c)
		_rings(g, spot, spot_c, n)
	return _to_model(g)


## Eyebrows, the pink lower lip and the smile. All are placed by rays from the front, at the
## sheet's front-view positions.
func _pig_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		# Eyebrow: a short thick dash above the eye, darker than the head, its nose end higher,
		# a little arched, rounded at both ends.
		g.color = P_BROW
		var brow := []
		var brow_w := []
		var brow_n := Vector3.ZERO
		for q in [[51.0, 306.6, 1.8], [47.5, 304.2, 2.8], [43.0, 302.2, 3.2], [38.5, 300.8, 3.2], [34.0, 300.2, 2.8], [30.5, 300.6, 1.8]]:
			var h := _ray(_body, PT(650, q[1], side * q[0]), Vector3(1, 0, 0))
			brow.append(h[0] + h[1] * 0.3 * PK)
			brow_w.append(Vector2(q[2], 1.0) * PK)
			brow_n += h[1]
		g.loft(brow, brow_w, brow_n.normalized(), 10)
		# Smile: a short line in the fold under the muzzle, from beside the lip out and up to
		# the corner of the mouth; the snout hides it from straight in front, as on the sheet.
		g.color = P_LINE
		var smile := []
		var smile_w := []
		for i in 11:
			var t := i / 10.0
			var h := _ray(_body, PT(650, 402.5 - 13.0 * pow(t, 1.4), side * (8.0 + 30.0 * t)), Vector3(1, 0, 0))
			smile.append(h[0] + h[1] * 0.15 * PK)
			var w := lerpf(0.75, 0.35, t)
			smile_w.append(Vector2(w, w) * PK)
		g.loft(smile, smile_w, Vector3.UP, 6)
	# Lower lip: a small pink pad just under the middle of the snout.
	var lip := _ray(_body, PT(650, 402.5), Vector3(1, 0, 0))
	var ln: Vector3 = lip[1]
	var lside := Vector3.UP.cross(ln).normalized()
	g.color = P_LIP
	g.ellipsoid(lip[0], Vector3(10.5, 3.0, 2.0) * PK, Basis(lside, ln.cross(lside).normalized(), ln), 20, 10)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / PF
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= PF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _horns, _hooves, _udder, _ear_tints, _muzzle_tints]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "PigClayDisplay"
	root.set_meta("source", "User's Pig (Black & White) Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.88)
	for part in [["Body", _body, P_CREAM_CREASE, 3.5], ["Snout", _muzzle, P_SNOUT_CREASE, 5.0], ["Ears", _ears, P_DARK_CREASE, 6.0],
			["Hooves", _hooves, P_DARK_CREASE, 5.0], ["Tail", _tuft, P_CREAM_CREASE, 5.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Snout": _muzzle_tints}.get(part[0], [])
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
	eyes.mesh = _pig_eyes()
	eyes.material_override = _material(0.4)
	eyes.material_override.metallic_specular = 0.12   # near-black from every side; the painted reflection is the shine
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _pig_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(PT(726, PGY, -105)) / PF
	var c := to_model(PT(1163, PTOP, 105)) / PF
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
