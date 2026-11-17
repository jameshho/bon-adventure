extends "res://scripts/characters/zebra_clay.gd"
## Clay-style tiger traced from the user's "Tiger (Relaxed / Neutral) Character Blueprint"
## turnaround (16 Nov 2026, "Relaxed Idle Pose": front 3/4, front, side, back, rear 3/4). A static
## display model, built once by tools/build_tiger_clay.gd into scenes/animals/tiger_clay.tscn.
## Rebuilt from the ground up on 17 Nov 2026 (user: the head's shape and proportions were wrong).
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd), the clay cow's helpers (cow_clay.gd: _ray, carve) and the clay zebra's
## painted stripes (zebra_clay.gd: _stripe, _snap, _width, _paint with two passes), and the clay
## pig's shaded ring patches (pig_clay.gd: _rings) for the eyes.
##
## New here: the skull and the torso are "profile solids" (loft): each horizontal slice of the
## skull (each cross-section of the torso) is a rounded shape whose extents come straight from
## the sheet's outlines, so the front view and the side view of the model are the sheet's own
## silhouettes by construction (measured row by row on the sheet,
## docs/evidence/tiger-clay-20261116/measure.gd). Cheeks, muzzle, lids and limbs are run into
## them with wide blends, so the surfaces flow into each other.
##
## Shapes are written in the sheet's pixels: x toward the tail and y down as in a true side view,
## z lateral (+ = the animal's left). The sheet's "side" view is turned 25 degrees toward the
## front (the eye, the brow and the legs all fit that turn): a point seen there at x has true
## x = (seen - 74.7 - 0.4226 z) / 0.906 (true_x()).
##
## Ready for rigging, like the clay pig: body, head, legs, cheek ruffs and tail are one fused
## piece ("Body"); the nose, ears and cream brow pads are separate pieces; each eye is its own
## mesh on its own node (LeftEye, RightEye: origin at the eye's centre, local y up the eye,
## local z out of the face); whiskers, whisker dots and the mouth are "Face details".
## Output faces -Z (head), +Y up, ground at y = 0.

const Pig := preload("res://scripts/characters/pig_clay.gd")
const Lion := preload("res://scripts/characters/lion_clay.gd")

const TH := 2.1                 # town units to the ear tips, the zoo tiger's species height (park_animals.gd)
const TY := 523.0               # sheet y of the soles
const TTOP := 208.0             # sheet y of the ear tips
const TX := 945.0               # true x placed at the model origin
const TF := 1.0                 # meshing size against life size (clay grid about 3 cm)
const TK := TF * TH / ((TY - TTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet (orange lit f99f3c, mid f7922f; cream f5cfa5; stripe 7a4a2a;
# ears 6e3e20; nose f39177), the orange and cream a little deeper so they hold in bright light.
const T_ORANGE := Color("ea8c2c")
const T_CREAM := Color("f2cfa3")
const T_CREAM_CREASE := Color("dcb486")
const T_TOE_LINE := Color("cba377")        # the grooves between the toes
const T_STRIPE := Color("7a4826")
const T_TIP := Color("6e4022")
const T_EAR := Color("6e3f21")
const T_EAR_IN := Color("f2a48c")
const T_NOSE := Color("ee917b")
const T_NOSE_CREASE := Color("d67a66")
const T_NOSTRIL := Color("6a2f24")
const T_SCLERA := Color("ddd3c9")
const T_SCLERA_SHADE := Color("a89e97")
const T_PUPIL := Color("0b0807")
const T_GLINT := Color("fffdf8")
const T_LID := Color("17100e")
const T_RIM := Color("5e4638")
const T_MOUTH := Color("7c5540")
const T_MOUTH_IN := Color("3a1c14")
const T_LIP := Color("e58a7a")
const T_WHISKER := Color("8a6f58")
const T_DOT := Color("5e3d28")

# Skull (sheet px): a big ball a little wider than deep, widest at eye height. Measured on the
# sheet: top 222, 184 across at y 305, the forehead fuller than a circle (its profile from the
# side is squarer than its outline from the front).
const H_X := 795.0              # true x of the skull's axis (the ears stand on it)
const H_TOP := 222.0
const H_MID := 305.0            # the widest height
const H_BOT := 378.0            # just under the jaw line, in the throat
const H_W := 92.0               # half-width
const H_FRONT := 88.5           # axis to the brow, along the middle
const H_BACK := 86.0

# Eyes (sheet px, front view). Half-closed: a straight, heavy upper lid (level; the nose end
# 1 px lower) over a half oval 40 px wide and 19 px deep, fuller on the nose side. The black
# pupil is a big circle toward the nose, cut by the lid and running into the lower rim; the
# white shows only on the outer side, greyed by the lid's shadow; one small catch-light high on
# the pupil's outer edge.
const E_Y := 305.5              # sheet y of the eye centre (lid 296, lowest point of the rim 315)
const E_Z := 45.0               # lateral offset of the eye centre
const E_HALF := 20.25           # half-width as seen from the front
const E_TOP := 9.5              # the lid line above the centre
const E_DEPTH := 19.0           # from the lid line to the lowest point of the rim
const E_PUPIL := Vector2(-7.5, 4.5)
const E_PUPIL_R := 15.5

const P_TOE := 21.5              # paws: lateral step between the three toes
const P_TOE_R := 16.0           # and each toe's radius
## Legs as [true x, lateral z]: standing square.
const T_LEGS := [[864.0, 57.0], [864.0, -57.0], [1061.0, 57.0], [1061.0, -57.0]]
## Tail: off the top of the rump, down its back and out to the brown tip. [true x, y, radius]
const T_TAIL := [[1088.0, 330.0, 26.0], [1112.0, 352.0, 25.0], [1128.0, 385.0, 24.0], [1142.0, 420.0, 23.0], [1160.0, 448.0, 22.5], [1185.0, 466.0, 22.0]]

# Torso (true x, sheet y): [x, value] keys of its top line, its underside and its half-width.
const B_TOP := [[760.0, 398.0], [764.0, 362.0], [772.0, 335.0], [785.0, 308.0], [805.0, 280.0], [830.0, 256.0], [850.0, 246.0],
		[870.0, 249.0], [889.0, 258.0], [911.0, 274.0], [933.0, 285.0], [955.0, 292.0], [980.0, 294.0], [1020.0, 293.0], [1043.0, 295.0],
		[1065.0, 300.0], [1087.0, 309.0], [1105.0, 325.0], [1118.0, 350.0], [1124.0, 375.0], [1127.0, 398.0]]
const B_BOTTOM := [[760.0, 398.0], [763.0, 425.0], [772.0, 441.0], [790.0, 449.0], [830.0, 450.0], [900.0, 446.0], [1000.0, 444.0],
		[1060.0, 440.0], [1098.0, 428.0], [1118.0, 412.0], [1127.0, 398.0]]
const B_WIDE := [[760.0, 0.5], [763.0, 38.0], [769.0, 60.0], [780.0, 80.0], [800.0, 93.0], [830.0, 99.0], [865.0, 101.0], [950.0, 101.0], [1050.0, 100.0],
		[1090.0, 91.0], [1110.0, 72.0], [1122.0, 42.0], [1127.0, 0.5]]

## How much is built, for studying the form one layer at a time (docs/evidence/.../study.gd):
## 1 the bare skull; 2 + bridge, muzzle, chin, lids, cheek ruffs; 3 + nose, ears, brows;
## 4 + eyes and face details; 5 + torso, legs, paws, tail; 6 + the painted coat (everything).
var stage := 6

var _brows := []
var _eye_n := Vector3.ZERO


## Sheet pixel -> working space (y up).
static func T(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - TX) * TK, (TY - y) * TK, z * TK)


## True x of a point the sheet's side view shows at `seen`, z px toward the viewer.
static func true_x(seen: float, z: float) -> float:
	return (seen - 74.7 - 0.4226 * z) / 0.906


func te(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * TK, col, k * TK, crease, basis)


func tc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * TK, rb * TK, col, k * TK)


# --- Profile solids -----------------------------------------------------------------------

## A solid given by its slices. `axis` 1: horizontal slices from sheet y s0 up to s1 (the skull);
## `axis` 0: cross-sections from true x s0 back to s1 (the torso). profile(s) returns the slice
## in sheet px: [centre, extent toward the nose (axis 1) or downward (axis 0), extent toward the
## tail or upward, half-width]. Every slice is a rounded shape of exponent `e` (2 = an ellipse,
## more = squarer) with those extents.
func loft(g: Array, axis: int, s0: float, s1: float, n: int, profile: Callable, e: float, col: Color, k := 0.0) -> void:
	var tab := PackedFloat32Array()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	var first := 0.0
	var last := 0.0
	# The solid's reach in 26 directions (faces, edges and corners of a cube): the faceted hull
	# that _dist() uses as a floor for the distance outside the solid.
	var dirs := []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				if dx != 0 or dy != 0 or dz != 0: dirs.append(Vector3(dx, dy, dz).normalized())
	var reach := PackedFloat32Array()
	reach.resize(dirs.size())
	reach.fill(-INF)
	for i in n:
		# Slices crowd toward both ends, where the outline turns fastest, so the ends stay round.
		var s := lerpf(s0, s1, (1.0 - cos(PI * i / (n - 1))) * 0.5)
		var row: Array = profile.call(s)
		var at := T(row[0], s) if axis == 1 else T(s, row[0])
		var along: float = at.y if axis == 1 else at.x
		var uc: float = at.x if axis == 1 else at.y
		if i == 0: first = along
		last = along
		var um: float = maxf(row[1], 0.4) * TK
		var up: float = maxf(row[2], 0.4) * TK
		var w: float = maxf(row[3], 0.4) * TK
		tab.append_array(PackedFloat32Array([uc, um, up, w]))
		var a := Vector3(uc - um, along, -w) if axis == 1 else Vector3(along, uc - um, -w)
		var b := Vector3(uc + up, along, w) if axis == 1 else Vector3(along, uc + up, w)
		lo = lo.min(a)
		hi = hi.max(b)
		for q in 24:
			var ang := TAU * q / 24.0
			var cu := signf(cos(ang)) * pow(absf(cos(ang)), 2.0 / e)
			var cv := signf(sin(ang)) * pow(absf(sin(ang)), 2.0 / e)
			var du := cu * (um if cu < 0.0 else up)
			var rim := Vector3(uc + du, along, cv * w) if axis == 1 else Vector3(along, uc + du, cv * w)
			for j in dirs.size():
				reach[j] = maxf(reach[j], (dirs[j] as Vector3).dot(rim))
	var pad := Vector3.ONE * (k * TK + CELL * 3.0)
	g.append({"t": "loft", "axis": axis, "lo": first, "hi": last, "n": n, "tab": tab, "e": e, "cap": 0.3 * TK,
			"box": AABB(lo - pad, hi - lo + pad * 2.0), "dirs": dirs, "reach": reach, "k": k * TK, "col": col, "crease": false, "paint": false})


## The implicit function of a profile solid: below 0 inside, 0 on the skin.
static func _loft_f(pr: Dictionary, p: Vector3) -> float:
	var axis: int = pr.axis
	var s: float = p.y if axis == 1 else p.x
	var u: float = p.x if axis == 1 else p.y
	var lo: float = pr.lo
	var hi: float = pr.hi
	var n: int = pr.n
	var sc := clampf(s, lo, hi)
	var t := acos(1.0 - 2.0 * (sc - lo) / (hi - lo)) / PI * (n - 1)
	var i := mini(int(t), n - 2)
	var f := t - i
	var tab: PackedFloat32Array = pr.tab
	var j := i * 4
	var du := u - lerpf(tab[j], tab[j + 4], f)
	var a := lerpf(tab[j + 1], tab[j + 5], f) if du < 0.0 else lerpf(tab[j + 2], tab[j + 6], f)
	var w := lerpf(tab[j + 3], tab[j + 7], f)
	var e: float = pr.e
	var rho := pow(pow(absf(du) / a, e) + pow(absf(p.z) / w, e), 1.0 / e)
	var over: float = (s - sc) / pr.cap
	# Scaled by the slice's own size, so the value also falls steadily inside the solid (under
	# the ends too) and the mesher places the skin where the function crosses zero.
	return (sqrt(rho * rho + over * over) - 1.0) * minf(a, w)


## lion_clay.gd's distances, with the profile solid added (first-order distance: f / |grad f|,
## never less than the distance to the solid's faceted hull).
static func _dist(pr: Dictionary, p: Vector3) -> float:
	if pr.t == "loft":
		var f := _loft_f(pr, p)
		var g := Vector3(_loft_f(pr, p + Vector3(1, 0, 0)) - f, _loft_f(pr, p + Vector3(0, 1, 0)) - f, _loft_f(pr, p + Vector3(0, 0, 1)) - f)
		var d := f / maxf(g.length(), 0.02)
		if d > 0.0:
			# Beside the solid's flat end planes the function turns sharply and the estimate
			# falls to almost nothing, which lets a wide blend weld a stray sliver there. The
			# distance to the solid's faceted hull is a true floor for it.
			var dirs: Array = pr.dirs
			var reach: PackedFloat32Array = pr.reach
			for j in dirs.size():
				d = maxf(d, (dirs[j] as Vector3).dot(p) - reach[j])
		return d
	return Lion._dist(pr, p)


static func _box(pr: Dictionary) -> AABB:
	if pr.t == "loft":
		return pr.box
	return Lion._box(pr)


## (1 - t^p)^(1/p): the quarter outline of a rounded shape, 1 at t = 0 and 0 at t = 1.
static func _round(t: float, p: float) -> float:
	return pow(maxf(1.0 - pow(clampf(t, 0.0, 1.0), p), 0.0), 1.0 / p)


## The skull's slice at sheet height y: [axis x, extent to the front, to the back, half-width].
func _skull(y: float) -> Array:
	var up := y < H_MID
	var t := (H_MID - y) / (H_MID - H_TOP) if up else (y - H_MID) / (H_BOT - H_MID)
	# From the front: an ellipse above, fuller below (full jowls). From the side: a full, round
	# forehead; the face sets back about 2 px in a soft band at eye height (the brow stands
	# a little over the eyes; the bridge fills the middle).
	var w := H_W * _round(t, 2.0 if up else 2.5)
	var front := H_FRONT * _round(t, 2.3 if up else 2.2) - 2.0 * exp(-pow((y - 305.0) / 14.0, 2.0))
	var back := H_BACK * _round(t, 2.0)
	return [H_X, front, back, w]


## The torso's cross-section at true x: [widest height, extent down, extent up, half-width].
func _torso(x: float) -> Array:
	var top := Pig._curve(B_TOP, x)
	var bottom := maxf(Pig._curve(B_BOTTOM, x), top + 1.0)
	var mid := lerpf(top, bottom, 0.62)
	return [mid, bottom - mid, mid - top, Pig._curve(B_WIDE, x)]


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	_head()
	if stage >= 5: _trunk()
	if stage >= 3: _pieces()
	if stage >= 6: _coat()


## The head, part of the body's clay. Skull first; everything else runs into it.
func _head() -> void:
	var b := _body
	loft(b, 1, H_BOT, H_TOP, 100, _skull, 2.0, T_ORANGE)
	if stage < 2: return
	# Bridge: from between the eyes forward and down to the nose.
	tc(b, T(717, 292), T(704, 313), 13.0, 15.0, T_ORANGE, 12.0)
	# Muzzle: a broad low mound on the lower face carries two round whisker pads side by side
	# (each about 46 px across; a groove between them under the nose) and a wide soft chin; everything runs into the cheeks
	# with wide blends, so the muzzle swells out of the face instead of sitting on it.
	te(b, T(725, 339), Vector3(26, 27, 46), T_ORANGE, 20.0)
	for side in [-1.0, 1.0]:
		te(b, T(710, 334.5, side * 22.0), Vector3(22, 22.0, 23.5), T_ORANGE, 10.0)
	te(b, T(722, 363.5), Vector3(20, 13, 27), T_ORANGE, 12.0)
	for side in [-1.0, 1.0]:
		# Upper lid: a low soft pad over each eye, ending at the lid line.
		te(b, T(722.5, 285, side * 45.0), Vector3(5, 11, 20), T_ORANGE, 8.0, false, Basis(Vector3.UP, side * deg_to_rad(27.0)))
		# Cheek ruff: a soft puff on the side of the head below its middle, standing out past
		# the skull, with three small scallops along its outer back edge.
		te(b, T(780, 340, side * 82.0), Vector3(26, 24, 18), T_ORANGE, 16.0)   # the cheek runs out to the ruff
		te(b, T(798, 327, side * 94.0), Vector3(25, 31, 17), T_ORANGE, 12.0)
		te(b, T(808, 306, side * 101.5), Vector3(13, 11.0, 10), T_ORANGE, 4.0)
		te(b, T(814, 325, side * 103.5), Vector3(13, 11.5, 10), T_ORANGE, 4.0)
		te(b, T(806, 344, side * 99.5), Vector3(13, 10.0, 10), T_ORANGE, 4.0)


## Torso, legs, paws and tail, run into the head and into each other.
func _trunk() -> void:
	var b := _body
	loft(b, 0, 760.0, 1127.0, 120, _torso, 2.15, T_ORANGE, 24.0)
	for leg in T_LEGS:
		var x: float = leg[0]
		var z: float = leg[1]
		var out := signf(z)
		# Paw: a tall mitt of three fat toes lying side by side, each a round-ended roll from the
		# heel to the front, with a real groove between them; the leg comes down into it with a
		# wide blend, so the grooves fade out over the top. A flat sole (cut below).
		for t in [-1.0, 0.0, 1.0]:
			tc(b, T(x + 16.0, 507, z + t * P_TOE), T(x - (41.0 if t == 0.0 else 38.5), 507, z + t * P_TOE), P_TOE_R, P_TOE_R, T_ORANGE, 1.5)
		# The heel end spreads a little at the ground (the paw is wider than the leg from behind).
		te(b, T(x + 10.0, 511, z), Vector3(28, 13, 40), T_ORANGE, 8.0)
		if x < 950.0:
			# Foreleg: a thick column, a little wider at the shoulder.
			tc(b, T(x, 400, z + out * 9.0), T(x, 490, z), 41.0, 36.5, T_ORANGE, 18.0)
		else:
			# Hind leg: a full round thigh over a thick column.
			te(b, T(x - 3.0, 398, z + out * 3.0), Vector3(52, 60, 43), T_ORANGE, 20.0)
			tc(b, T(x, 410, z + out * 7.0), T(x + 2.0, 490, z), 40.0, 36.0, T_ORANGE, 18.0)
	# Tail: thick, the tip a brown ball.
	for i in T_TAIL.size() - 1:
		var a: Array = T_TAIL[i]
		var c: Array = T_TAIL[i + 1]
		tc(b, T(a[0], a[1]), T(c[0], c[1]), a[2], c[2], T_ORANGE, 14.0 if i == 0 else 5.0)
	te(b, T(1203, 471), Vector3(26, 25, 25), T_TIP, 5.0)
	for leg in T_LEGS:
		carve(b, T(leg[0] - 10.0, TY + 40.0, leg[1]), Vector3(130, 40, 130) * TK, T_CREAM)


## The separate pieces: nose, ears, brows.
func _pieces() -> void:
	# Nose: pink; two wide wings over a narrower stem that runs down to a round tip, a nostril
	# pressed in under each wing; a brown cap arches over it.
	var m := _muzzle
	te(m, T(692.5, 321), Vector3(10, 10.5, 22), T_NOSE)
	for side in [-1.0, 1.0]:
		te(m, T(693, 320, side * 13.0), Vector3(10, 9.5, 10.5), T_NOSE, 3.0)
	te(m, T(693.5, 329), Vector3(9, 8.5, 10.5), T_NOSE, 5.0)
	te(m, T(697, 311.5), Vector3(12, 7.0, 17.0), T_STRIPE, 3.0)
	for side in [-1.0, 1.0]:
		var slant := Basis(Vector3(1, 0, 0), side * 0.5)
		var hole := Vector3(6.0, 4.4, 6.6)
		var at: Vector3 = _ray(m, T(660, 327.0, side * 13.5), Vector3(1, 0, 0))[0]
		carve(m, at, hole * TK, T_NOSE, slant)
		_muzzle_tints.append({"t": "ell", "c": at, "r": (hole + Vector3.ONE * 0.8) * TK, "inv": slant.inverse(), "col": T_NOSTRIL, "soft": CELL * 0.5})
	_muzzle_tints.append({"t": "ell", "c": T(697, 311), "r": Vector3(14, 7.5, 18.0) * TK, "inv": Basis(), "col": T_STRIPE, "soft": CELL * 0.3})

	# Ears: thick round discs standing on the skull's top corners, turned 28 degrees outward: a
	# fat brown rim round a pink hollow, a brown dome behind. The lower inner third is in the skull.
	for side in [-1.0, 1.0]:
		var axis := Vector3(-0.883, 0.05, side * 0.469).normalized()
		var u := (Vector3.UP - axis * axis.dot(Vector3.UP)).normalized()
		var v := axis.cross(u).normalized()
		var basis := Basis(axis, u, v)
		var c := T(800, 244, side * 69.5)
		for i in 16:
			var a0 := TAU * i / 16.0
			var a1 := TAU * (i + 1) / 16.0
			tc(_ears, c + (u * cos(a0) + v * sin(a0)) * 25.0 * TK, c + (u * cos(a1) + v * sin(a1)) * 25.0 * TK, 9.0, 9.0, T_EAR, 0.0 if i == 0 and side < 0.0 else 2.0)
		te(_ears, c - axis * 5.0 * TK, Vector3(12, 31.5, 31.5), T_EAR, 4.0, false, basis)
		carve(_ears, c + axis * 10.0 * TK, Vector3(8, 19.5, 19.5) * TK, T_EAR, basis)
		_ear_tints.append({"t": "ell", "c": c + axis * 10.0 * TK, "r": Vector3(11, 21.0, 21.0) * TK, "inv": basis.inverse(), "col": T_EAR_IN, "soft": CELL * 0.35})

	# Brows: a cream roll over each eye, the outer end lower.
	for side in [-1.0, 1.0]:
		var pts := []
		for q in [[262.5, 28.5], [265.5, 43.0], [269.5, 57.5]]:
			pts.append(_ray(_body, T(660, q[0], side * q[1]), Vector3(1, 0, 0))[0] + Vector3(2.5, 0, 0) * TK)
		tc(_brows, pts[0], pts[1], 6.8, 7.4, T_CREAM, 0.0)
		tc(_brows, pts[1], pts[2], 7.4, 6.3, T_CREAM, 3.0)


# --- Coat ---------------------------------------------------------------------------------

static func _cr(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


## Rows of numbers made six times denser: a smooth curve through all but the last column (the
## stripe's width), which is eased between rows.
static func _dense(guides: Array) -> Array:
	var out := []
	var n := guides.size()
	for i in (n - 1) * 6 + 1:
		var j := mini(i / 6, n - 2)
		var f := (i - j * 6) / 6.0
		var g0: Array = guides[maxi(j - 1, 0)]
		var g1: Array = guides[j]
		var g2: Array = guides[j + 1]
		var g3: Array = guides[mini(j + 2, n - 1)]
		var row := []
		for k in g1.size():
			if k == g1.size() - 1:
				row.append(lerpf(g1[k], g2[k], smoothstep(0.0, 1.0, f)))
			else:
				row.append(_cr(g0[k], g1[k], g2[k], g3[k], f))
		out.append(row)
	return out


## A painted stripe through skin points; widths in tiger sheet px (zebra_clay.gd's _stripe).
func _emit(pts: Array, ws: Array) -> void:
	var scaled := []
	for w in ws:
		scaled.append(w * TK / ZK)
	_stripe(pts, scaled, T_STRIPE)
	# A slightly softer edge than the zebra's: it spans two of the split triangles, so the
	# edge reads smooth instead of stepped.
	_tints[_tints.size() - 1].soft = CELL * 0.45


## A stripe through guides [true x, y, lateral z, width], each dropped on the skin toward one
## core point; mirrored onto each side in `sides`.
func _core_mark(guides: Array, core: Vector3, sides := [-1.0, 1.0]) -> void:
	for side in sides:
		var c3 := T(core.x, core.y, core.z * side)
		var pts := []
		var ws := []
		for g in _dense(guides):
			pts.append(_snap(T(g[0], g[1], g[2] * side), c3))
			ws.append(g[3])
		_emit(pts, ws)


## A stripe drawn on the sheet's side view: guides [x as seen, y, width] on the torso. Each
## point is turned back from the sheet's view (true_x) and dropped on the skin toward the
## torso's axis; painted on both sides.
func _side_mark(guides: Array) -> void:
	for side in [-1.0, 1.0]:
		var pts := []
		var ws := []
		for g in _dense(guides):
			var c: float = clampf((388.0 - g[1]) / 95.0 if g[1] < 388.0 else (g[1] - 388.0) / 56.0, 0.0, 1.0)
			var z := 101.0 * sqrt(1.0 - c * c)
			# Turned back from the sheet's view; eased near the spine so the two sides meet in an arc.
			var x := true_x(g[0], z * z / (z + 15.0))
			pts.append(_snap(T(x, 388.0 + (g[1] - 388.0) * 1.3, side * z * 1.3), T(x, 388.0, 0.0)))
			ws.append(g[2])
		_emit(pts, ws)


## A stripe drawn on the sheet's front view: guides [lateral z, y, width], projected onto the
## face from the front.
func _front_mark(guides: Array, sides := [-1.0, 1.0]) -> void:
	for side in sides:
		var pts := []
		var ws := []
		for g in _dense(guides):
			pts.append(_ray(_body, T(660, g[1], side * g[0]), Vector3(1, 0, 0))[0])
			ws.append(g[2])
		_emit(pts, ws)


## The skull's skin at sheet height y, z px to the side: its true x on the front half.
func _skull_x(y: float, z: float) -> float:
	var row := _skull(y)
	var f: float = row[1]
	var w: float = row[3]
	return H_X - f * sqrt(maxf(1.0 - pow(z / w, 2.0), 0.0))


## A stripe on the rim of the face: guides [lateral z, y, width] on the skull, each dropped on
## the skin from the front and outside (so it lands in front of the cheek ruff, not on it).
func _rim_mark(guides: Array) -> void:
	for side in [-1.0, 1.0]:
		var dir := Vector3(0.5, 0.0, -0.866 * side)
		var pts := []
		var ws := []
		for g in _dense(guides):
			pts.append(_ray(_body, T(_skull_x(g[1], g[0]), g[1], side * g[0]) - dir * 50.0 * TK, dir)[0])
			ws.append(g[2])
		_emit(pts, ws)


## A stripe part of the way round a leg: from angle a0 to a1 (degrees: 0 = front, 90 = outer
## side, 180 = back), falling from sheet y0 to y1; w as in zebra_clay.gd's _width.
func _leg_band(leg: Array, a0: float, a1: float, y0: float, y1: float, w: Array) -> void:
	var pts := []
	var ws := []
	for i in 25:
		var t := i / 24.0
		var a := deg_to_rad(lerpf(a0, a1, t))
		var y := lerpf(y0, y1, t)
		pts.append(_snap(T(leg[0] - cos(a) * 70.0, y, leg[1] + signf(leg[1]) * sin(a) * 70.0), T(leg[0], y, leg[1])))
		ws.append(_width(w, t))
	_emit(pts, ws)


## The cream of a paw: the three toes, the foot up to a level edge across the front of the leg
## (lower along the sides) and a tall round arch up the back of the leg, as on the sheet's back
## view; then the two grooves between the toes drawn a shade darker.
func _paw_cream(leg: Array) -> void:
	var x: float = leg[0]
	var z: float = leg[1]
	var parts := []
	for t in [-1.0, 0.0, 1.0]:
		parts.append({"t": "cone", "a": T(x + 18.0, 507, z + t * P_TOE), "b": T(x - 40.5, 507, z + t * P_TOE), "ra": (P_TOE_R + 3.0) * TK, "rb": (P_TOE_R + 3.0) * TK})
	parts.append({"t": "ell", "c": T(x - 22.0, 520, z), "r": Vector3(72, 34.5, 58) * TK, "inv": Basis()})
	parts.append({"t": "ell", "c": T(x + 30.0, 500, z), "r": Vector3(16, 28, 30) * TK, "inv": Basis()})
	_tints.append({"t": "blob", "c": T(x - 10.0, 505, z), "r": Vector3.ONE * 100.0 * TK, "parts": parts, "k": 4.0 * TK, "col": T_CREAM, "soft": CELL * 0.5})
	for t in [-0.5, 0.5]:
		_tint(T(x - 26.0, 509.5, z + t * P_TOE), Vector3(34, 19.0, 1.5) * TK, Basis(), T_TOE_LINE, CELL * 0.4)


func _cream(c: Vector3, r: Vector3) -> void:
	_tint(c, r * TK, Basis(), T_CREAM, CELL * 0.5)


## Painted areas, in order: the cream underside, chest, lower face, ruffs and paws, then the
## brown marks.
func _coat() -> void:
	_cream(T(960, 478), Vector3(78, 62, 112))             # belly, up onto the lower flanks
	_cream(T(778, 412), Vector3(46, 62, 62))              # chest, down between the forelegs
	_cream(T(772, 388), Vector3(44, 32, 68))              # throat, under the head
	_cream(T(755, 360), Vector3(62, 34, 118))             # jaw, throat and lower cheeks
	_cream(T(716, 341), Vector3(34, 26, 44))              # muzzle, between and under the pads
	for leg in T_LEGS:
		_paw_cream(leg)
	for side in [-1.0, 1.0]:
		_cream(T(794, 330, side * 101.0), Vector3(37, 35, 30))   # ruffs
		_cream(T(710, 333.5, side * 22.0), Vector3(24, 23.5, 25))   # whisker pads

	_tint(T(699, 310.5), Vector3(14, 7.0, 16.5) * TK, Basis(), T_STRIPE, CELL * 0.3)   # the cap over the nose, where the bridge shows

	# Back and flanks, from the sheet's side view: tapered bands that cross the spine and run
	# down each side to a point.
	_core_mark([[863, 249, 0, 16.0], [859, 255, 36, 16.0], [852, 280, 74, 14.0], [855, 306, 86, 3.0]], Vector3(855, 322, 0))   # over the neck, behind the ears
	_side_mark([[910, 278, 20.0], [903, 322, 28.0], [883, 362, 25.0], [857, 402, 14.0], [848, 412, 3.0]])   # the long shoulder stripe
	_side_mark([[933, 290, 17.0], [943, 318, 20.0], [950, 345, 3.0]])
	_side_mark([[967, 293, 20.0], [970, 328, 28.0], [975, 362, 17.0], [973, 378, 3.0]])
	_side_mark([[1017, 295, 20.0], [1028, 328, 30.0], [1033, 362, 20.0], [1033, 383, 3.0]])
	_side_mark([[1057, 302, 15.0], [1070, 325, 20.0], [1078, 345, 3.0]])
	_core_mark([[1068, 380, 100, 3.0], [1052, 402, 102, 20.0], [1022, 428, 100, 20.0], [1002, 443, 92, 3.0]], Vector3(1040, 400, 0))   # haunch
	# Forelegs: a leaf-shaped band from behind, round the outer side to the front.
	for leg in T_LEGS:
		if leg[0] < 950.0:
			_leg_band(leg, 150.0, -10.0, 428.0, 455.0, [3.0, 20.0, 3.0])
	# Tail: a brown cap over its root and three rings.
	var at := 0.0
	for i in T_TAIL.size() - 1:
		var a := T(T_TAIL[i][0], T_TAIL[i][1])
		var c := T(T_TAIL[i + 1][0], T_TAIL[i + 1][1])
		var length := a.distance_to(c) / TK
		var along := (c - a).normalized()
		var up := (Vector3.UP - along * along.dot(Vector3.UP)).normalized()
		var basis := Basis(along, up, along.cross(up))
		for ring in [[12.0, 20.0], [62.0, 12.5], [98.0, 12.0], [133.0, 11.0]]:
			if ring[0] >= at and ring[0] < at + length:
				var centre: Vector3 = a + along * (ring[0] - at) * TK + Vector3(4.0, 0, 0) * TK
				var wide: float = T_TAIL[i][2] + 4.0
				_tint(centre, Vector3(ring[1], wide, wide) * TK, basis, T_STRIPE, CELL * 0.2)
		at += length

	# Head. Forehead: a wedge down the middle with an arm each side, and one dot. A short thick
	# mark over each cream brow. A big crescent round the outside of each eye, from the temple
	# down to under the cheek. A band over the top between the ears.
	_front_mark([[0.0, 229.0, 9.0], [0.0, 238.0, 14.0], [0.0, 250.0, 10.0], [0.0, 264.0, 2.0]], [1.0])
	_front_mark([[3.0, 239.5, 16.0], [14.0, 239.5, 16.0], [25.0, 241.5, 12.0], [36.0, 245.0, 2.5]])
	var dot: Vector3 = _ray(_body, T(660, 253, -17.0), Vector3(1, 0, 0))[0]
	_tint(dot, Vector3.ONE * 3.4 * TK, Basis(), T_STRIPE, CELL * 0.2)
	_front_mark([[55.0, 258.0, 3.0], [47.0, 252.0, 9.5], [38.0, 249.5, 13.0], [30.0, 250.0, 12.0], [26.5, 251.0, 7.0]])
	_rim_mark([[70.0, 266.0, 2.5], [80.0, 280.0, 8.0], [85.0, 295.0, 10.5], [86.0, 310.0, 11.5], [84.0, 322.0, 11.0],
			[78.0, 331.0, 9.5], [70.0, 336.0, 6.0], [63.0, 337.5, 2.0]])
	_core_mark([[838, 222, 0, 13.0], [838, 228, 24, 12.0], [840, 238, 44, 3.0]], Vector3(820, 300, 0))


## zebra_clay.gd's skin colour; the stripes split the clay a little way either side of their
## edge, the cream patches only where the edge itself crosses a triangle.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_edge = 10000.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 10000.0
		if t.t == "blob":
			var k: float = t.k
			for part in t.parts:
				var dp := _dist(part, p)
				var h := maxf(k - absf(d - dp), 0.0) / k
				d = minf(d, dp) - h * h * k * 0.25
		else:
			d = _dist(t, p)
		var soft: float = t.soft
		# (The thin toe grooves are narrower than a triangle, so they split like the stripes.)
		if soft < CELL: _edge = minf(_edge, d * 1.6 if t.col == T_STRIPE else (d if t.col == T_TOE_LINE else d * 4.0))
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc_: Color = t.col
			c = c.lerp(tc_, w)
	c.a = 1.0
	return c


# --- Eyes ---------------------------------------------------------------------------------

static func _eye_top(o: float) -> float:
	return E_TOP + 0.02 * o


## The lower rim at `o` (px outward from the eye centre): a half oval, fuller on the nose side.
static func _eye_bottom(o: float) -> float:
	var c := clampf(o / E_HALF, -1.0, 1.0)
	var p := lerpf(0.9, 0.6, smoothstep(-0.2, 0.5, -c))
	return _eye_top(o) - E_DEPTH * pow(sqrt(1.0 - c * c), p)


static func _eye_clip(q: Vector2) -> Vector2:
	var o := clampf(q.x, -E_HALF + 0.6, E_HALF - 0.6)
	return Vector2(o, clampf(q.y, _eye_bottom(o) + 0.25, _eye_top(o) - 0.2))


## A point of an eye: q = (outward, up) from its centre as seen from the front, on the skin,
## lifted `base` px plus the eye's own slight bulge.
func _eye_pt(side: float, q: Vector2, base: float) -> Vector3:
	var hit := _ray(_body, T(690, E_Y - q.y, side * (E_Z + q.x)), Vector3(1, 0, 0))
	var bulge := 1.2 * maxf(1.0 - pow(q.x / 20.0, 2.0) - pow(q.y / 9.5, 2.0), 0.0)
	return hit[0] + _eye_n * (base + bulge) * TK


## Smooth normals for the triangles added since `first`, facing along n.
static func _smooth(g, first: int, n: Vector3) -> void:
	var sums := {}
	for at in range(first, g.verts.size(), 3):
		var face: Vector3 = (g.verts[at + 1] - g.verts[at]).cross(g.verts[at + 2] - g.verts[at])
		if face.dot(n) < 0.0: face = -face
		for k in 3:
			sums[g.verts[at + k]] = sums.get(g.verts[at + k], Vector3.ZERO) + face
	for at in range(first, g.verts.size()):
		g.norms[at] = (sums[g.verts[at]] as Vector3).normalized()


## One eye: [mesh in the eye's own space, the eye node's transform in the model].
func _tiger_eye(side: float) -> Array:
	var hit := _ray(_body, T(690, E_Y, side * E_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	var up := n.cross(right).normalized()
	_eye_n = n
	var g := Plaza.Geo.new()
	# Outline: along the lower rim from the outer corner to the inner one, back along the lid.
	var outline := []
	for i in 37:
		var o := E_HALF * cos(PI * i / 36.0)
		outline.append(Vector2(o, _eye_bottom(o)))
	for i in range(1, 20):
		var o := lerpf(-E_HALF, E_HALF, i / 20.0)
		outline.append(Vector2(o, _eye_top(o)))
	# The white, greyer under the lid.
	var pts := [[_eye_pt(side, Vector2.ZERO, 0.4)]]
	var cols := [[T_SCLERA.lerp(T_SCLERA_SHADE, smoothstep(1.0, 8.5, 0.0))]]
	for rho in [0.3, 0.55, 0.75, 0.9, 1.0]:
		var ring := []
		var ring_c := []
		for q in outline:
			var p: Vector2 = q * rho
			ring.append(_eye_pt(side, p, 0.4))
			ring_c.append(T_SCLERA.lerp(T_SCLERA_SHADE, smoothstep(1.0, 8.5, p.y)))
		pts.append(ring)
		cols.append(ring_c)
	Pig._rings(g, pts, cols, n)
	# The pupil: a circle cut by the lid and the lower rim.
	pts = [[_eye_pt(side, E_PUPIL, 0.8)]]
	cols = [[T_PUPIL]]
	for rho in [0.45, 0.8, 1.0]:
		var ring := []
		var ring_c := []
		for i in 40:
			var a := TAU * i / 40.0
			ring.append(_eye_pt(side, _eye_clip(E_PUPIL + Vector2(cos(a), sin(a)) * E_PUPIL_R * rho), 0.8))
			ring_c.append(T_PUPIL)
		pts.append(ring)
		cols.append(ring_c)
	Pig._rings(g, pts, cols, n)
	_smooth(g, 0, n)
	var frame := Basis(right * side, up, n)
	g.color = T_GLINT
	g.ellipsoid(_eye_pt(side, Vector2(4.5, 4.3), 1.0), Vector3(1.5, 1.5, 0.45) * TK, frame, 12, 6)
	# The heavy upper lid: a thick black line, a little past the outer corner.
	var lid := []
	var lid_w := []
	for i in 15:
		var t := i / 14.0
		var o := lerpf(-E_HALF - 0.2, E_HALF + 1.4, t)
		lid.append(_eye_pt(side, Vector2(o, _eye_top(o) - 0.5), 0.7))
		lid_w.append(Vector2(lerpf(0.5, 2.3, pow(sin(PI * t), 0.6)), 0.4) * TK)
	g.color = T_LID
	g.loft(lid, lid_w, n, 8)
	# The lower rim: a fine dark line.
	var rim := []
	var rim_w := []
	for i in 29:
		var o := E_HALF * cos(PI * lerpf(0.03, 0.97, i / 28.0))
		rim.append(_eye_pt(side, Vector2(o, _eye_bottom(o)), 0.7))
		rim_w.append(Vector2(0.28, 0.25) * TK)
	g.color = T_RIM
	g.loft(rim, rim_w, n, 6)
	# Into the eye's own space: origin at its centre, y up the eye, z out of the face.
	var z := normal_to_model(n).normalized()
	var y := normal_to_model(up).normalized()
	var x := y.cross(z).normalized()
	var xf := Transform3D(Basis(x, z.cross(x), z), to_model(hit[0]) / TF)
	var inv := xf.affine_inverse()
	for i in g.verts.size():
		g.verts[i] = inv * (to_model(g.verts[i]) / TF)
		g.norms[i] = (inv.basis * normal_to_model(g.norms[i])).normalized()
	return [g.commit(), xf]


# --- Face details -------------------------------------------------------------------------

## Whiskers and their dots, the line from the nose to the mouth, the smile and the lower lip.
func _tiger_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		g.color = T_DOT
		for y in [332.2, 342.2]:
			for z in [35.0]:
				var h := _ray(_body, T(660, y, side * z), Vector3(1, 0, 0))
				var hn: Vector3 = h[1]
				var hr := Vector3.UP.cross(hn).normalized()
				g.ellipsoid(h[0], Vector3(1.5, 1.5, 0.5) * TK, Basis(hr, hn.cross(hr).normalized(), hn), 10, 5)
		# Three fine whiskers a side, thick at the root, sweeping out past the cheek and a little back.
		g.color = T_WHISKER
		for w in [[330.5, 41.0, Vector3(24, 7, 64)], [336.7, 42.0, Vector3(24, -2, 62)], [342.8, 41.0, Vector3(22, -15, 60)]]:
			var h := _ray(_body, T(660, w[0], side * w[1]), Vector3(1, 0, 0))
			var r0: Vector3 = h[0] + h[1] * 0.3 * TK
			var to_tip: Vector3 = w[2] * TK
			to_tip.z *= side
			var mid := r0 + to_tip * 0.5 + Vector3(-2.0, -1.0, 0.0) * TK
			g.loft([r0, mid, r0 + to_tip], [Vector2(0.75, 0.75) * TK, Vector2(0.4, 0.4) * TK, Vector2(0.2, 0.2) * TK], Vector3.UP, 5)
	g.color = T_MOUTH
	var line := []
	for y in [337.0, 341.0, 345.0, 349.5]:
		var h := _ray(_body, T(660, y, 0.0), Vector3(1, 0, 0))
		line.append(h[0] + h[1] * 0.8 * TK)
	g.loft(line, [Vector2(0.75, 0.6) * TK, Vector2(0.75, 0.6) * TK, Vector2(0.75, 0.6) * TK, Vector2(0.75, 0.6) * TK], Vector3(0, 0, 1), 6)
	for side in [-1.0, 1.0]:
		var smile := []
		var smile_w := []
		var keys := _dense([[349.5, 0.0, 0.0], [354.2, 11.0, 0.0], [356.6, 21.0, 0.0], [355.6, 30.0, 0.0], [352.5, 37.5, 0.0], [349.0, 41.0, 0.0]])
		for i in keys.size():
			var h := _ray(_body, T(660, keys[i][0], side * keys[i][1]), Vector3(1, 0, 0))
			smile.append(h[0] + h[1] * 0.8 * TK)
			var w := lerpf(0.6, 0.2, pow(float(i) / (keys.size() - 1), 1.5))
			smile_w.append(Vector2(w, w) * TK)
		g.loft(smile, smile_w, Vector3.UP, 6)
	# Lower lip: a small dark opening under the middle with a touch of pink.
	var lip := _ray(_body, T(660, 351.5, 0.0), Vector3(1, 0, 0))
	var ln: Vector3 = lip[1]
	var ls := Vector3.UP.cross(ln).normalized()
	var lb := Basis(ls, ln.cross(ls).normalized(), ln)
	g.color = T_MOUTH_IN
	g.ellipsoid(lip[0] + ln * 0.9 * TK + lb.y * 0.8 * TK, Vector3(5.0, 1.8, 0.8) * TK, lb, 16, 8)
	g.color = T_LIP
	g.ellipsoid(lip[0] + ln * 1.2 * TK - lb.y * 1.4 * TK, Vector3(6.0, 1.5, 0.8) * TK, lb, 16, 8)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / TF
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= TF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _hooves, _muzzle_tints, _ear_tints, _tongue, _brows]:
		group.clear()
	_paint_passes = 2
	_shape()
	var root := Node3D.new()
	root.name = "TigerClayDisplay"
	root.set_meta("source", "User's Tiger (Relaxed / Neutral) Character Blueprint, relaxed idle pose (16 Nov 2026)")
	var clay := _material(0.86)
	var parts := [["Body", _body, T_CREAM_CREASE, 5.0]]
	if stage >= 3:
		parts.append_array([["Nose", _muzzle, T_NOSE_CREASE, 4.0], ["Ears", _ears, T_EAR, 5.0], ["Brows", _brows, T_CREAM_CREASE, 4.0]])
	for part in parts:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Nose": _muzzle_tints, "Ears": _ear_tints}.get(part[0], [])
		if not paints.is_empty():
			var body_tints := _tints
			_tints = paints
			mi.mesh = _paint(mi.mesh)
			_tints = body_tints
		mi.mesh = _fit(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	if stage >= 4:
		var eye_material := _material(0.45)
		eye_material.metallic_specular = 0.15   # no glare on the black; the painted catch-light is the shine
		for eye in [["LeftEye", 1.0], ["RightEye", -1.0]]:
			var built := _tiger_eye(eye[1])
			var mi := MeshInstance3D.new()
			mi.name = eye[0]
			mi.mesh = built[0]
			mi.transform = built[1]
			mi.material_override = eye_material
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
		var face := MeshInstance3D.new()
		face.name = "Face details"
		face.mesh = _tiger_details()
		face.material_override = _material(0.75)
		face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(T(686, TY, -110)) / TF
	var c := to_model(T(1228, TTOP, 110)) / TF
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
