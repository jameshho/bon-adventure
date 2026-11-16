extends "res://scripts/characters/cow_clay.gd"
## Clay-style zebra traced from the user's "Zebra Character Blueprint" turnaround (11 Nov 2026,
## "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model, built once
## by tools/build_zebra_clay.gd into scenes/animals/zebra_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd: _tint, _paint) and the clay cow's helpers (cow_clay.gd: _ray, _fit, blob
## tints). Shapes are written in the zebra sheet's side-view pixels (x to the right = toward the
## tail, y down, z lateral, + = the side facing the viewer) and V() scales them into the lion's
## working space. Meshed FINE times larger than life and shrunk afterwards, like the cow.
## The muzzle with its open mouth, the tongue, mane, ears, hooves and tail tuft are separate clay
## pieces; the stripes are painted on the skin as tapered bands that follow it (_stripe: chains
## of capsules through points dropped on the skin); eyes, lids, lashes and brows are small parts
## laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const ZH := 1.7                 # town units: between the zoo cow (1.55) and horse (1.9)
const ZY := 670.0               # sheet y of the hooves' soles
const ZTOP := 246.0             # sheet y of the top of the forelock
const ZX := 815.0               # sheet x placed at the model origin
const ZK := FINE * ZH / ((ZY - ZTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet; the cream is a little under the sheet's lit f6e6d6, which
# burns out to white in bright light (see cow_clay.gd).
const Z_CREAM := Color("ebd5ca")
const Z_CREASE := Color("d5bdb0")
const Z_STRIPE := Color("5b514e")
const Z_MUZZLE := Color("675c58")
const Z_MUZZLE_CREASE := Color("4a4140")
const Z_NOSTRIL := Color("3a3231")
const Z_MOUTH_IN := Color("4c3936")
const Z_TONGUE := Color("ee8266")
const Z_MANE := Color("5a504d")
const Z_MANE_CREASE := Color("3f3836")
const Z_EAR_IN := Color("f2927c")
const Z_HOOF := Color("524947")
const Z_HOOF_CREASE := Color("3a3332")
const Z_SCLERA := Color("fbf6ee")
const Z_PUPIL := Color("14100f")
const Z_LID := Color("2e2625")

# Eyes (sheet px): centre as seen from the front, half-sizes measured face-on.
const Z_EYE_Y := 331.0
const Z_EYE_Z := 26.4
const Z_EYE_R := Vector2(7.6, 10.7)      # the white, to its outline
const Z_PUPIL_R := Vector2(6.5, 9.5)     # the black oval that almost fills it

var _tongue := []


## Sheet pixel -> working space (y up).
static func V(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - ZX) * ZK, (ZY - y) * ZK, z * ZK)


func ze(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * ZK, col, k * ZK, crease, basis)


func zc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * ZK, rb * ZK, col, k * ZK)


func ztube(g: Array, pts: Array, radii: Array, col: Color, k: float, k_rest := 3.0) -> void:
	for i in pts.size() - 1:
		zc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else k_rest)


## Rotation about the lateral axis: positive leans the top of a shape toward the head.
static func lean(a: float) -> Basis:
	return Basis(Vector3(0, 0, 1), a)


# --- Shape --------------------------------------------------------------------------------

## Legs as [sheet x, lateral z]: the walking stagger of the sheet's side view.
const Z_LEGS := [[763.0, 31.0], [721.0, -31.0], [909.0, 31.0], [861.0, -31.0]]

func _shape() -> void:
	var b := _body
	# Torso: a round barrel, deep chest, full rump.
	ze(b, V(748, 482), Vector3(46, 55, 55), Z_CREAM)
	ze(b, V(815, 485), Vector3(76, 53, 54), Z_CREAM, 20.0)
	ze(b, V(880, 488), Vector3(48, 54, 57), Z_CREAM, 20.0)
	# Neck: thick and upright, narrower across than front to back; withers under the mane's end.
	ze(b, V(746, 385), Vector3(42, 95, 34), Z_CREAM, 22.0, false, lean(0.08))
	ze(b, V(776, 446), Vector3(36, 34, 42), Z_CREAM, 20.0)
	ze(b, V(738, 318), Vector3(36, 40, 36), Z_CREAM, 16.0)
	# Head: round skull, a face that narrows toward the front (the eyes sit on its front
	# corners, turned half sideways), wide cheeks, and a short bridge down to the muzzle.
	ze(b, V(710, 323), Vector3(45, 44, 46), Z_CREAM, 16.0)
	ze(b, V(712, 332), Vector3(46, 38, 36), Z_CREAM, 12.0)
	ze(b, V(708, 354), Vector3(36, 31, 49.5), Z_CREAM, 16.0)
	ze(b, V(676, 341), Vector3(34, 27, 21), Z_CREAM, 10.0, false, lean(0.45))
	# Legs: full at the top, a rounded knee (front) or a hock set a little back (hind), a
	# slimmer cannon and a flare above the hoof.
	for i in Z_LEGS.size():
		var x: float = Z_LEGS[i][0]
		var z: float = Z_LEGS[i][1]
		if i < 2:
			zc(b, V(x + 1.0, 500, z * 0.92), V(x, 578, z), 23.0, 19.0, Z_CREAM, 14.0)
			ze(b, V(x - 1.0, 583, z), Vector3(20.0, 13.0, 19.5), Z_CREAM, 6.0)
			zc(b, V(x, 583, z), V(x, 618, z), 18.5, 17.0, Z_CREAM, 4.0)
		else:
			zc(b, V(x - 4.0, 500, z * 0.92), V(x + 4.0, 582, z), 26.0, 19.5, Z_CREAM, 14.0)
			ze(b, V(x + 5.0, 586, z), Vector3(19.5, 13.0, 19.0), Z_CREAM, 6.0)
			zc(b, V(x + 4.0, 586, z), V(x, 618, z), 18.5, 17.0, Z_CREAM, 4.0)
		zc(b, V(x, 618, z), V(x, 642, z), 17.0, 21.5, Z_CREAM, 4.0)
	# Tail: a thin stalk slanting down and back from the top of the rump.
	ztube(b, [V(918, 458), V(932, 472), V(940, 492), V(943, 506)], [10.0, 9.0, 8.0, 7.0], Z_CREAM, 8.0)

	# Muzzle: a big grey bulb, wider than the bridge behind it; the lower jaw hangs open under
	# it. The mouth is cut right through from side to side, rising to the corners at the back.
	var m := _muzzle
	ze(m, V(646, 359), Vector3(27, 23, 29.5), Z_MUZZLE, 0.0, true)
	ze(m, V(657, 381), Vector3(24, 17, 27), Z_MUZZLE, 0.0, true, lean(0.45))
	for side in [-1.0, 1.0]:
		# Each half of the cut rises toward its corner: a smile.
		carve(m, V(642, 384, side * 12.0), Vector3(16, 6.0, 22) * ZK, Z_MOUTH_IN, lean(0.5) * Basis(Vector3(1, 0, 0), -side * 0.45))
	carve(m, V(642, 385.5), Vector3(16, 5.5, 13) * ZK, Z_MOUTH_IN, lean(0.5))   # no ridge between the halves
	for side in [-1.0, 1.0]:
		var slant := Basis(Vector3(1, 0, 0), side * 0.5)
		var hole := Vector3(4.5, 3.4, 5.2)
		var at: Vector3 = _ray(m, V(590, 355, side * 15.5), Vector3(1, 0, 0))[0]
		carve(m, at, hole * ZK, Z_MUZZLE, slant)
		_muzzle_tints.append({"t": "ell", "c": at, "r": (hole + Vector3.ONE * 0.3) * ZK, "inv": slant.inverse(), "col": Z_NOSTRIL, "soft": CELL * 0.35})
	ze(_tongue, V(649.0, 389.5), Vector3(12.5, 4.5, 16.0), Z_TONGUE, 0.0, false, lean(0.5))

	# Mane: a small forelock on top of the head (a dark tuft, a cream section, a dark one), then
	# an upright crest between the ears, over the back of the head and down the neck to the
	# withers: flattish sections longer than they are tall, lying along the crest and running
	# into each other with only a shallow notch between them.
	ze(_mane, V(682, 272), Vector3(11.5, 18.5, 12.5), Z_MANE, 0.0, true, lean(0.3))
	for side in [-1.0, 1.0]:
		ze(_mane, V(683, 272, side * 6.5), Vector3(10, 16.5, 8), Z_MANE, 3.0, false, lean(0.3))
		ze(_mane, V(677, 262, side * 6.0), Vector3(8.5, 8, 7.5), Z_MANE, 4.0, false, lean(0.3))
		ze(_mane, V(688, 261, side * 6.0), Vector3(7, 7, 7.5), Z_MANE, 4.0, false, lean(0.3))
	ze(_mane, V(698, 270), Vector3(6.5, 18.5, 13), Z_CREAM, 2.0, true, lean(0.18))
	ze(_mane, V(708.5, 269), Vector3(7, 18, 13), Z_MANE, 2.0, true, lean(0.08))
	var crest := [Vector2(744, 279), Vector2(762, 292), Vector2(777, 311), Vector2(787, 333), Vector2(793, 358), Vector2(798, 382), Vector2(800, 405), Vector2(801, 425)]
	# A continuous core under the sections keeps the notches between them shallow.
	for i in crest.size() - 1:
		zc(_mane, V(crest[i].x, crest[i].y), V(crest[i + 1].x, crest[i + 1].y), 12.0 if i < 6 else 9.5, 12.0 if i < 5 else (9.5 if i == 5 else 7.0), Z_MANE)
	for i in crest.size():
		var along: Vector2 = (crest[mini(i + 1, crest.size() - 1)] - crest[maxi(i - 1, 0)]).normalized()
		var fade: float = [1.0, 1.0, 1.0, 1.0, 1.0, 0.95, 0.85, 0.62][i]
		# Local x lies along the crest, y stands out from the neck, z is the crest's half-width.
		ze(_mane, V(crest[i].x, crest[i].y), Vector3(17.5, 14.5 * fade, 14.0 * fade), Z_MANE, 3.0, true, lean(atan2(-along.y, along.x)))

	# Ears: upright leaf-shaped cups, leaning outward; cream outside, the pink hollow facing
	# forward and outward.
	for side in [-1.0, 1.0]:
		var along := Vector3(0.12, 0.9, side * 0.36).normalized()
		var open := Vector3(-0.64, 0.0, side * 0.77)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var c := V(731, 271, side * 37.0)
		ze(_ears, c, Vector3(7.5, 18.0, 26.0), Z_CREAM, 0.0, false, basis)
		ze(_ears, c + along * 12.0 * ZK, Vector3(5.5, 11.0, 17.0), Z_CREAM, 6.0, false, basis)
		carve(_ears, c + open * 6.5 * ZK + along * 1.5 * ZK, Vector3(5.0, 11.0, 19.0) * ZK, Z_EAR_IN, basis)

	# Hooves: dark caps a little wider than the legs, toe to the front with a small cleft,
	# flat soles.
	for leg in Z_LEGS:
		zc(_hooves, V(leg[0] - 1.0, 648, leg[1]), V(leg[0] - 1.0, 672, leg[1]), 22.0, 23.0, Z_HOOF)
		for t in [-1.0, 1.0]:
			ze(_hooves, V(leg[0] - 8.0, 661, leg[1] + t * 7.0), Vector3(19, 13, 14), Z_HOOF, 4.0, true)
	for leg in Z_LEGS:
		carve(_hooves, V(leg[0], ZY + 40.0, leg[1]), Vector3(120, 40, 120) * ZK, Z_HOOF)

	# Tail tuft: a dark teardrop hanging back from the stalk.
	var hang := lean(-0.42)
	zc(_tuft, V(941, 500), V(947, 513), 6.5, 13.0, Z_MANE, 0.0)
	ze(_tuft, V(951, 529), Vector3(18, 28, 19), Z_MANE, 5.0, true, hang)
	for side in [-1.0, 1.0]:
		ze(_tuft, V(953, 534, side * 9.5), Vector3(12, 21, 12), Z_MANE, 2.0, true, hang)
	zc(_tuft, V(957, 545), V(964, 563), 9.0, 2.5, Z_MANE, 6.0)

	_stripes()


# --- Stripes ------------------------------------------------------------------------------

## A painted stripe through working-space points on the skin; widths in sheet px.
func _stripe(pts: Array, widths: Array, col := Z_STRIPE) -> void:
	var centre := Vector3.ZERO
	for p in pts:
		centre += p / pts.size()
	var parts := []
	var reach := 0.0
	for i in pts.size():
		reach = maxf(reach, centre.distance_to(pts[i]) + widths[i] * 0.5 * ZK)
		if i > 0 and pts[i].distance_to(pts[i - 1]) > 0.01:
			parts.append({"t": "cone", "a": pts[i - 1], "b": pts[i], "ra": widths[i - 1] * 0.5 * ZK, "rb": widths[i] * 0.5 * ZK})
	_tints.append({"t": "blob", "c": centre, "r": Vector3.ONE * reach, "parts": parts, "k": 1.5 * ZK, "col": col, "soft": CELL * 0.2})


## The skin on the line from a point outside the body toward a point inside it.
func _snap(outside: Vector3, core: Vector3) -> Vector3:
	for reachout in [2.2, 1.6, 1.25, 1.05]:
		var from: Vector3 = core + (outside - core) * reachout
		if _field(_body, from) > 0.0:
			return _ray(_body, from, core - from)[0]
	return outside


## Width along a stripe, w = [start, body, end, taper from (optional, default 0.6)]: it swells
## from `start` to the body width over the first third, holds it, and from `taper from`
## narrows smoothly to a rounded `end`.
static func _width(w: Array, t: float) -> float:
	if t < 0.5:
		return lerpf(w[0], w[1], smoothstep(0.0, 0.3, t))
	return lerpf(w[1], w[2], smoothstep(w[3] if w.size() > 3 else 0.6, 1.0, t))


## A stripe wrapping round a limb, the neck or the barrel. In the side view it runs from `back`
## (on one silhouette edge) to `front` (on the opposite edge); `a0`..`a1` is the part of that
## half turn it covers (degrees: 0 at `back`, 90 on the flank, 180 at `front`), `half` the
## part's lateral half-width and `cz` its lateral centre. `bow` (sheet px) curves it in the
## side view. Painted on each side in `sides`.
func _band(back: Vector2, front: Vector2, half: float, a0: float, a1: float, w: Array, sides := [-1.0, 1.0], cz := 0.0, bow := 0.0) -> void:
	var mid := (back + front) * 0.5
	var core := V(mid.x, mid.y, cz)
	var across := (front - back).orthogonal().normalized()
	for side in sides:
		var pts := []
		var ws := []
		for i in 25:
			var t := i / 24.0
			var a := deg_to_rad(lerpf(a0, a1, t))
			var along := (1.0 - cos(a)) * 0.5
			var q := back.lerp(front, along) + across * bow * sin(PI * along)
			pts.append(_snap(V(q.x, q.y, cz + side * sin(a) * half), core))
			ws.append(_width(w, t))
		_stripe(pts, ws)


## A stripe through guide points [sheet x, y, lateral z, width], each dropped on the skin
## toward `core` (sheet x, y, z); mirrored onto each side in `sides`.
func _stroke(guides: Array, core: Vector3, sides := [-1.0, 1.0]) -> void:
	for side in sides:
		var c3 := V(core.x, core.y, core.z * side)
		var pts := []
		var ws := []
		for i in (guides.size() - 1) * 6 + 1:
			# Six steps per guide span (Catmull-Rom), so curved stripes stay smooth on the skin.
			var j := mini(i / 6, guides.size() - 2)
			var f := (i - j * 6) / 6.0
			var g0: Array = guides[maxi(j - 1, 0)]
			var g1: Array = guides[j]
			var g2: Array = guides[j + 1]
			var g3: Array = guides[mini(j + 2, guides.size() - 1)]
			var p := Vector3(g1[0], g1[1], g1[2]).cubic_interpolate(Vector3(g2[0], g2[1], g2[2]), Vector3(g0[0], g0[1], g0[2]), Vector3(g3[0], g3[1], g3[2]), f)
			pts.append(_snap(V(p.x, p.y, p.z * side), c3))
			ws.append(lerpf(g1[3], g2[3], smoothstep(0.0, 1.0, f)))
		_stripe(pts, ws)


func _stripes() -> void:
	# Neck: four bands from under the mane, slanting down and forward with a slight upward
	# bow, full width for most of their length and narrowing to a rounded point short of the
	# middle of the throat.
	for n in [[764, 324, 714, 384], [782, 368, 717, 420], [793, 406, 721, 455], [800, 437, 729, 488]]:
		_band(Vector2(n[0], n[1]), Vector2(n[2], n[3]), 36.0, 4.0, 158.0, [15.0, 14.5, 3.0, 0.66], [-1.0, 1.0], 0.0, 4.0)
	# Barrel: bands from the spine down the flanks; the second is the longest.
	_band(Vector2(819, 428), Vector2(826, 540), 56.0, 3.0, 90.0, [13.0, 13.0, 4.0, 0.84], [-1.0, 1.0], 0.0, -3.0)
	_band(Vector2(845, 429), Vector2(831, 541), 56.0, 3.0, 112.0, [16.0, 15.5, 4.0, 0.82], [-1.0, 1.0], 0.0, -3.0)
	_band(Vector2(872, 431), Vector2(862, 541), 56.0, 3.0, 80.0, [16.0, 15.0, 4.0, 0.82])
	_band(Vector2(908, 438), Vector2(872, 545), 56.0, 3.0, 86.0, [15.0, 14.5, 4.0, 0.84], [-1.0, 1.0], 0.0, 4.0)
	# Shoulder: one arc over the top of the foreleg, carried round onto the front of the chest.
	_stroke([[799, 505, 60, 3.0], [783, 495, 70, 14.0], [763, 496, 70, 14.5], [744, 507, 62, 13.0], [724, 517, 46, 9.0], [709, 525, 28, 3.0]], Vector3(765, 492, 0))
	# Haunch: two curved bands round the rump onto the thigh.
	_stroke([[931, 476, 16, 3.0], [923, 491, 42, 12.0], [910, 503, 62, 15.0], [896, 514, 66, 14.0], [881, 524, 60, 3.0]], Vector3(880, 490, 0))
	_stroke([[930, 530, 28, 3.0], [914, 543, 60, 12.5], [895, 553, 62, 3.0]], Vector3(895, 530, 12))
	# Tail: a dark cap over its root and one ring on the stalk.
	_tint(V(917, 453), Vector3(9, 5, 10) * ZK, lean(-0.7), Z_STRIPE, CELL * 0.2)
	_tint(V(935, 478), Vector3(13, 3.0, 13) * ZK, lean(0.5), Z_STRIPE, CELL * 0.2)
	# Legs: three bands round the outer face, front and back of each, rounded at both ends.
	for i in Z_LEGS.size():
		var x: float = Z_LEGS[i][0]
		var z: float = Z_LEGS[i][1]
		var rows: Array = [[538.0, -5.0, 14.0], [572.0, 1.0, 11.5], [601.0, 2.0, 12.0]] if i < 2 else [[547.0, -6.0, 13.5], [578.0, -4.0, 11.5], [603.0, 1.0, 12.5]]
		for row in rows:
			var y: float = row[0] + (3.0 if z < 0.0 else 0.0)
			_band(Vector2(x + 20.0, y - row[1]), Vector2(x - 20.0, y + row[1]), 20.0, -40.0, 220.0, [3.5, row[2], 3.5], [signf(z)], z)
	# Head: a wedge down the forehead from the forelock with a smaller one either side; a
	# band under each ear; a flame-shaped band behind each eye; one short mark on each cheek.
	_stroke([[679, 287, 0, 15.0], [669, 304, 0, 9.0], [660, 319, 0, 2.5]], Vector3(712, 325, 0), [1.0])
	_stroke([[684, 284, 14, 7.0], [677, 296, 12.5, 5.5], [672, 306, 11, 2.5]], Vector3(712, 325, 0))
	_stroke([[742, 296, 40, 12.0], [732, 314, 46, 11.0], [727, 334, 46, 3.0]], Vector3(720, 325, 0))
	_stroke([[708, 318, 44, 3.0], [713, 339, 47, 9.5], [719, 359, 47, 11.0], [713, 378, 42, 3.0]], Vector3(712, 345, 0))
	_stroke([[694, 348, 40, 2.5], [690, 359, 41, 6.0], [690, 370, 38, 2.5]], Vector3(712, 352, 0))


## Signed distance (working units) from the last _tinted() point to the nearest painted edge.
var _edge := 0.0

## cow_clay.gd's skin colour, also leaving the distance to the nearest stripe edge in _edge.
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
		_edge = minf(_edge, d)
		var soft: float = t.soft
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
	c.a = 1.0
	return c


## giraffe_clay.gd's skin painting with finer, distance-driven edges: every triangle within
## reach of a painted edge is split in four, three times, each pass in a band half as wide
## (about 0.2 cm along the edges on the finished model). Splitting by distance rather than by
## colour difference also catches stripe tips narrower than the clay grid, which otherwise
## break into fragments.
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
	var dist := PackedFloat32Array()
	for i in verts.size():
		cols.append(_tinted(verts[i], base[i], reach))
		dist.append(_edge)
	var span := CELL * 0.55
	for pass_i in 3:
		var out := PackedInt32Array()
		var mids := {}
		for t in range(0, idx.size(), 3):
			var a := idx[t]
			var b := idx[t + 1]
			var c := idx[t + 2]
			var lo := minf(dist[a], minf(dist[b], dist[c]))
			var hi := maxf(dist[a], maxf(dist[b], dist[c]))
			if lo > span or hi < -span:
				out.append(a); out.append(b); out.append(c)
				continue
			var ab := _zmid(a, b, mids, verts, norms, base, cols, dist, reach)
			var bc := _zmid(b, c, mids, verts, norms, base, cols, dist, reach)
			var ca := _zmid(c, a, mids, verts, norms, base, cols, dist, reach)
			out.append_array(PackedInt32Array([a, ab, ca, ab, b, bc, ca, bc, c, ab, bc, ca]))
		idx = out
		span *= 0.5
	var built := []
	built.resize(Mesh.ARRAY_MAX)
	built[Mesh.ARRAY_VERTEX] = verts
	built[Mesh.ARRAY_NORMAL] = norms
	built[Mesh.ARRAY_COLOR] = cols
	built[Mesh.ARRAY_INDEX] = idx
	var out_mesh := ArrayMesh.new()
	out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, built)
	return out_mesh


## Vertex at the middle of edge a-b (shared between the triangles that split it).
func _zmid(a: int, b: int, mids: Dictionary, verts: PackedVector3Array, norms: PackedVector3Array, base: PackedColorArray, cols: PackedColorArray, dist: PackedFloat32Array, reach: Array) -> int:
	var key := Vector2i(mini(a, b), maxi(a, b))
	if mids.has(key): return mids[key]
	var v := (verts[a] + verts[b]) * 0.5
	var bc := base[a].lerp(base[b], 0.5)
	verts.append(v)
	norms.append((norms[a] + norms[b]).normalized())
	base.append(bc)
	cols.append(_tinted(v, bc, reach))
	dist.append(_edge)
	mids[key] = verts.size() - 1
	return verts.size() - 1


# --- Face details -------------------------------------------------------------------------

## Drops a point near the face onto the skin along -n, then lifts it `lift` sheet px.
func _drop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * ZK
	for i in 800:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * ZK


## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _zebra_eye_frame(side: float) -> Array:
	var hit := _ray(_body, V(590, Z_EYE_Y, side * Z_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Eyes, from the sheet's front, 3/4 and side views: an upright oval set in the face and only
## gently domed; glossy black almost to the edge, leaving a thin white rim that is widest on
## the outer side; a round catch-light high on the nose side and a tiny one low on the outer
## side. The outline, lashes and brows are drawn in _zebra_details().
func _zebra_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _zebra_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		# The white's edge lies in the skin (its centre plane at the skin's mean height round
		# the eye); the dome stands 2.2 px proud of the skin at its middle.
		var edge := 0.0
		for q in [Vector2(Z_EYE_R.x, 0), Vector2(-Z_EYE_R.x, 0), Vector2(0, Z_EYE_R.y), Vector2(0, -Z_EYE_R.y)]:
			edge += (_drop(s + (out * q.x + up * q.y) * ZK, n, 0.0) - s).dot(n) / ZK * 0.25
		var white_h := edge - 0.2
		var white := Vector3(Z_EYE_R.x, Z_EYE_R.y, 2.2 - white_h)
		g.color = Z_SCLERA
		g.ellipsoid(s + n * white_h * ZK, white * ZK, frame, 40, 20)
		# The black oval, a little toward the nose; a thin lens just proud of the white.
		var io := Vector2(-0.8, 0.1)
		var pupil := Vector3(Z_PUPIL_R.x, Z_PUPIL_R.y, 1.5)
		var pupil_h := white_h + _dome(white, io.x, io.y) - pupil.z + 0.75
		g.color = Z_PUPIL
		g.ellipsoid(s + (out * io.x + up * io.y + n * pupil_h) * ZK, pupil * ZK, frame, 40, 20)
		g.color = Z_SCLERA
		for glint in [[Vector2(-1.3, 4.3), 1.75], [Vector2(2.3, -4.8), 0.8]]:
			var go: Vector2 = glint[0]
			var gr: float = glint[1]
			g.ellipsoid(s + (out * (io.x + go.x) + up * (io.y + go.y) + n * (pupil_h + _dome(pupil, go.x, go.y) + 0.15)) * ZK,
					Vector3(gr, gr, 0.4) * ZK, frame, 16, 8)
	return _to_model(g)


## Eye outlines, lashes and eyebrows.
func _zebra_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _zebra_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Outline: a dark line right round the eye, thick over the top, fine underneath.
		g.color = Z_LID
		var lid := []
		var lid_w := []
		for i in 33:
			var t := i / 32.0
			var a := TAU * t - PI * 0.5        # starts and ends under the eye
			var q := Vector2(cos(a) * Z_EYE_R.x, sin(a) * Z_EYE_R.y)
			lid.append(_drop(s + (out * q.x + up * q.y) * ZK, n, 0.9))
			lid_w.append(Vector2(lerpf(0.4, 1.0, clampf(sin(a) * 0.5 + 0.5, 0.0, 1.0)), 0.7) * ZK)
		g.loft(lid, lid_w, n, 8)
		# Two short lashes off the upper outer corner.
		for lash in [[32.0, 3.6], [56.0, 3.2]]:
			var a := deg_to_rad(lash[0])
			var dir := Vector2(cos(a + 0.25), sin(a + 0.25))
			var root := Vector2(cos(a) * Z_EYE_R.x, sin(a) * Z_EYE_R.y)
			var pts := []
			var ws := []
			for j in 4:
				var q: Vector2 = root + dir * lash[1] * j / 3.0
				pts.append(_drop(s + (out * q.x + up * q.y) * ZK, n, 0.6))
				ws.append(Vector2(lerpf(0.75, 0.25, j / 3.0), 0.5) * ZK)
			g.loft(pts, ws, n, 6)
		# Eyebrow: a short grey arc well above the eye, highest toward the nose side.
		g.color = Z_STRIPE
		var brow := []
		var brow_w := []
		for q in [[7.0, 22.5, 1.5], [3.5, 25.5, 3.4], [-0.5, 27.0, 4.0], [-4.5, 27.0, 3.4], [-7.0, 25.5, 1.5]]:
			brow.append(_drop(s + (out * q[0] + up * q[1]) * ZK, n, 0.2))
			brow_w.append(Vector2(q[2], 1.0) * ZK)
		g.loft(brow, brow_w, n, 10)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _hooves, _muzzle_tints, _tongue]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "ZebraClayDisplay"
	root.set_meta("source", "User's Zebra Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, Z_CREASE, 7.0], ["Muzzle", _muzzle, Z_MUZZLE_CREASE, 5.0], ["Tongue", _tongue, Z_TONGUE, 5.0],
			["Mane", _mane, Z_MANE_CREASE, 8.0], ["Ears", _ears, Z_CREASE, 7.0], ["Hooves", _hooves, Z_HOOF_CREASE, 5.0],
			["Tail tuft", _tuft, Z_MANE_CREASE, 6.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Muzzle": _muzzle_tints}.get(part[0], [])
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
	eyes.mesh = _zebra_eyes()
	eyes.material_override = _material(0.15)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _zebra_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(V(622, ZY, -58)) / FINE
	var c := to_model(V(940, ZTOP, 58)) / FINE
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
