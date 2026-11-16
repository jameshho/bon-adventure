extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style golden retriever traced from the user's "Golden Retriever Character Blueprint"
## turnaround (11 Nov 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static
## display model, built once by tools/build_golden_retriever_clay.gd into
## scenes/animals/golden_retriever_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd) and the clay giraffe's skin
## painting (giraffe_clay.gd: _tint, _paint). Shapes are written in the sheet's side-view pixels
## (x to the right = toward the tail, y down, z lateral, z > 0 = the dog's left, the side the
## sheet shows) and W() scales them into the lion's working space. The dog is small (0.8 town
## units), so it is meshed FINE times larger than life and shrunk afterwards (_fit).
## The fur clumps are part of the body's clay and blend into it; the ears, the nose and the
## tail plume are separate pieces; the cream muzzle, blaze, chest, belly, lower legs and tail
## feathers are painted on; eyes, lids, brows and the mouth line
## are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const DH := 0.8                 # town units, the zoo dog's display height (park_animals.gd)
const DY := 700.0               # sheet y of the paws' soles
const DTOP := 347.0             # sheet y of the top of the head
const DX := 800.0               # sheet x placed at the model origin
const FINE := 5.0               # meshed this many times larger than life
const DK := FINE * DH / ((DY - DTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet (gold eea551, head f9bb6a, ears e09446, cream f7d3a5), then
# deepened and reddened: the first render (11 Nov 2026) lit them a step brighter and yellower,
# and the cream burned out to white, as for the other clay animals.
const D_GOLD := Color("d88c4b")
const D_HEAD := Color("e09a55")
const D_GOLD_SHADE := 0.92                  # creases between toes: this much darker
const D_EAR := Color("c47638")
const D_CREAM := Color("e6c092")
const D_NOSE := Color("46291a")
const D_NOSTRIL := Color("24130d")
const D_SCLERA := Color("f3e8d8")
const D_IRIS_DARK := Color("4b2814")
const D_IRIS_LIGHT := Color("8a5124")
const D_PUPIL := Color("2e170c")
const D_GLINT := Color("fffdf8")
const D_LID := Color("2c170e")
const D_UNDER := Color("4a2a18")
const D_BROW := Color("ad6c30")
const D_MOUTH := Color("5e3b22")

# Eyes (sheet px), sixth pass (11 Nov 2026, user: "the shape of the eye is completely
# different"), traced at 24x in the sheet's front, side and front 3/4 views. Centre as seen from
# the front. D_EYE_OUTLINE is the outline face-on (front 3/4 view), as the radius at each angle
# about the centre (0 = toward the outer corner, 90 = up): round on the nose side and
# underneath, the upper lid slanting flat across the upper outer quarter down to a soft outer
# corner a little below the middle. The eye is a bulging dome (D_EYE_DOME proud of the skin), so
# the white wedge at the outer corner turns away from the front (a sliver there) and faces the
# side (a clear wedge there), as on the sheet.
const D_EYE_Y := 395.0
const D_EYE_Z := 28.5
const D_EYE_OUTLINE := [[-33.5, 10.4], [-22.7, 10.5], [-12.0, 10.9], [-5.8, 9.85], [1.3, 9.1], [18.8, 8.3], [39.0, 8.3], [59.0, 8.4],
	[75.2, 8.9], [100.7, 9.5], [122.3, 10.1], [144.8, 10.4], [169.8, 10.2], [188.5, 10.15], [210.8, 10.3], [236.1, 9.87], [268.8, 9.2],
	[299.4, 9.76]]
const D_EYE_DOME := 2.6
const D_EYE_SEGS := 160
const D_EYE_RINGS := 48

# Ears (eighth pass, 11 Nov 2026, user: "replace the rounded, circular ears with a soft,
# elongated triangular silhouette ... hang along the cheeks, following the head's contour").
# Level rungs down the flap (sheet px): [y, front edge x, z, bend x, z, back edge x, z, half
# thickness]. Each rung runs from the front edge, against the side of the face, out to a bend
# and back in to the back edge, so the flap wraps round the head instead of standing off it.
# D_EAR_OUTLINE is the sheet's outline at each height, [y, front x, back x (side view), outer
# z (front view)]: widest level with the nose and drawn down to a soft point by the jaw. The
# rungs are set in from it by their thickness and the blend's swell; build_display() prints
# the built outline beside it.
const D_EAR_RUNGS := [[364.0, 725.0, 42.0, 729.0, 45.5, 732.0, 42.0, 5.5], [372.0, 715.0, 47.0, 738.0, 53.5, 745.5, 51.0, 6.0],
	[382.0, 713.5, 50.0, 746.0, 60.5, 755.0, 57.5, 6.5], [392.0, 712.5, 51.5, 753.0, 67.0, 763.0, 63.5, 6.5],
	[402.0, 712.5, 52.5, 760.0, 73.5, 770.0, 70.0, 6.5], [412.0, 712.5, 53.0, 766.0, 77.0, 776.0, 73.5, 6.5],
	[422.0, 712.5, 54.0, 764.0, 78.0, 774.0, 74.5, 6.5], [432.0, 713.0, 55.0, 758.5, 77.5, 768.5, 73.5, 6.0],
	[442.0, 713.5, 57.0, 749.0, 74.0, 758.0, 70.0, 5.5], [451.0, 716.0, 60.0, 738.0, 69.0, 745.0, 66.0, 5.0],
	[459.0, 720.5, 62.5, 727.0, 65.0, 732.0, 64.0, 4.0], [466.0, 723.0, 65.0, 724.5, 65.5, 726.0, 65.0, 3.0]]
const D_EAR_OUTLINE := [[364.0, 716.0, 742.0, 56.0], [372.0, 705.0, 752.0, 64.0], [382.0, 703.0, 763.0, 72.0], [392.0, 702.0, 771.0, 79.0],
	[402.0, 702.0, 778.0, 85.0], [412.0, 702.0, 783.0, 88.0], [422.0, 702.0, 781.0, 89.0], [432.0, 703.0, 775.0, 88.0],
	[442.0, 704.0, 767.0, 84.0], [451.0, 707.0, 755.0, 78.0], [459.0, 712.0, 743.0, 73.0], [466.0, 718.0, 731.0, 69.0]]
const D_EAR_BLEND := 5.0        # smooth union between rungs (sheet px)
const D_EAR_FINE := 1.5         # the ears are meshed this much finer again, so the dent holds
const D_EAR_DENT_Y := 407.0     # sheet y of the dent in the ear's outer edge

var _nose := []
var _tail := []
var _clumps := []        # fur clumps waiting to be pressed on: [point, normal, flow, length, width, thick]
var _tail_tints := []
var _ear_swell := 0.0      # how far the blended clay stands outside a rung's own surface (sheet px)
var _ear_tints := []      # soft fold lines painted on the ears
var _plain_paint := false  # true while painting a piece that is not golden skin


## Sheet pixel -> working space (y up).
static func W(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - DX) * DK, (DY - y) * DK, z * DK)


func ce(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * DK, col, k * DK, crease, basis)


func cc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0, crease := false) -> void:
	g.append({"t": "cone", "a": a, "b": b, "ra": ra * DK, "rb": rb * DK, "k": k * DK, "col": col, "crease": crease, "paint": false})


func tube(g: Array, pts: Array, radii: Array, col: Color, k: float, k_rest := 3.0, crease := false) -> void:
	for i in pts.size() - 1:
		cc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else k_rest, crease)


## The ear's rung at sheet height y, between the rows of D_EAR_RUNGS.
static func _ear_rung(y: float) -> Array:
	for i in D_EAR_RUNGS.size() - 1:
		var r0: Array = D_EAR_RUNGS[i]
		var r1: Array = D_EAR_RUNGS[i + 1]
		if y <= r1[0]:
			var f := clampf((y - r0[0]) / (r1[0] - r0[0]), 0.0, 1.0)
			var out := [y]
			for j in range(1, 8): out.append(lerpf(r0[j], r1[j], f))
			return out
	return D_EAR_RUNGS[D_EAR_RUNGS.size() - 1]


## A point on the ear's centre sheet at height y, t of the way from the front edge (0) through
## the bend (0.5) to the back edge (1): [point, outward normal of the flap there].
static func _ear_at(y: float, t: float, side: float) -> Array:
	var r := _ear_rung(y)
	var a := W(r[1], y, side * r[2]) if t < 0.5 else W(r[3], y, side * r[4])
	var b := W(r[3], y, side * r[4]) if t < 0.5 else W(r[5], y, side * r[6])
	var along := (b - a).normalized()
	var n := Vector3(-along.z, 0.0, along.x)
	if n.z * side < 0.0: n = -n
	return [a.lerp(b, t * 2.0 if t < 0.5 else t * 2.0 - 1.0), n]


## A group's primitives enlarged f times about the model origin, to mesh a piece finer.
func _enlarged(prims: Array, f: float) -> Array:
	var origin := Vector3(X0, 0, 0)
	var out := []
	for pr in prims:
		var q: Dictionary = pr.duplicate()
		q.k = pr.get("k", 0.0) * f
		if pr.t == "ell":
			q.c = origin + (pr.c - origin) * f
			q.r = pr.r * f
		else:
			q.a = origin + (pr.a - origin) * f
			q.b = origin + (pr.b - origin) * f
			q.ra = pr.ra * f
			q.rb = pr.rb * f
		out.append(q)
	return out


## One level rung of the ear's clay: front edge to the bend, bend to the back edge.
func _ear_rung_clay(y: float, side: float, first: bool) -> void:
	var r := _ear_rung(y)
	var bend := W(r[3], y, side * r[4])
	cc(_ears, W(r[1], y, side * r[2]), bend, r[7], r[7], D_EAR, 0.0 if first else D_EAR_BLEND)
	cc(_ears, bend, W(r[5], y, side * r[6]), r[7], r[7], D_EAR, D_EAR_BLEND)


## Prints the built ear's outline beside the sheet's (D_EAR_OUTLINE), from the clay's own field.
func _ear_report() -> void:
	print("EAR outline, sheet px (built / sheet): y, front x, back x, outer z")
	for row in D_EAR_OUTLINE:
		var lo := Vector2(INF, INF)
		var hi := -lo
		var x := 690.0
		while x <= 795.0:
			var z := 36.0
			while z <= 96.0:
				if _field(_ears, W(x, row[0], z)) <= 0.0:
					lo = lo.min(Vector2(x, z))
					hi = hi.max(Vector2(x, z))
				z += 1.0
			x += 1.0
		print("  %.0f: %.0f / %.0f, %.0f / %.0f, %.0f / %.0f" % [row[0], lo.x, row[1], hi.x, row[2], hi.y, row[3]])


## A leg down its joints and a big round three-toed paw (toes toward the head).
func _dleg(joints: Array, radii: Array, paw: Vector3) -> void:
	var b := _body
	tube(b, joints, radii, D_GOLD, 22.0, 12.0)
	cc(b, joints[joints.size() - 1], paw + Vector3(6, 5, 0) * DK, radii[radii.size() - 1], 21.0, D_GOLD, 8.0)
	ce(b, paw, Vector3(26, 14.5, 25), D_GOLD, 6.0, true)
	for t in [-1.0, 0.0, 1.0]:
		ce(b, paw + Vector3(-17, -1.5, t * 15.5) * DK, Vector3(11.5, 12.5, 9.5), D_GOLD, 2.0, true)


## Marks a clump of fur where the ray meets the body, lying along `flow` (length, width and
## thickness in sheet px). _press_clumps() adds them all afterwards, so every clump is placed
## on the bare body.
func _clump(from: Vector3, dir: Vector3, flow: Vector3, length: float, width: float, thick := 8.0) -> void:
	var hit := _ray(_body, from, dir)
	_clumps.append([hit[0], hit[1], flow, length, width, thick])


## Fur clumps (third pass, 11 Nov 2026, user review: the separate pointed leaves read as
## spikes): broad round-ended pads pressed into the body's own clay, the upper end buried and
## the lower end a little proud, so they overlap softly and take the coat's painted colour.
func _press_clumps() -> void:
	for c in _clumps:
		var s: Vector3 = c[0]
		var n: Vector3 = c[1]
		var flow: Vector3 = c[2]
		var length: float = c[3]
		var width: float = c[4]
		var thick: float = c[5]
		var t := (flow - n * flow.dot(n)).normalized()
		var across := n.cross(t).normalized()
		var tilt := Basis(across, deg_to_rad(-8.0))
		var basis := Basis(tilt * t, across, tilt * n)
		ce(_body, s - t * length * 0.1 * DK - n * thick * 0.45 * DK, Vector3(length * 0.5, width * 0.5, thick), D_GOLD, 5.0, true, basis)
		ce(_body, s + t * length * 0.33 * DK - n * thick * 0.1 * DK, Vector3(length * 0.32, width * 0.25, thick * 0.85), D_GOLD, 7.0, false, basis)   # a soft rounded point
	_clumps.clear()


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: a deep chest, the belly rising toward the hind legs, a round rump; shoulder and
	# haunch masses carry the legs into it.
	ce(b, W(738, 538), Vector3(62, 70, 72), D_GOLD)
	ce(b, W(815, 529), Vector3(82, 59, 69), D_GOLD, 24.0)
	ce(b, W(895, 523), Vector3(61, 57, 73), D_GOLD, 24.0)
	for side in [-1.0, 1.0]:
		ce(b, W(737, 562, side * 36.0), Vector3(34, 44, 26), D_GOLD, 20.0)
		ce(b, W(912, 556, side * 38.0), Vector3(42, 48, 28), D_GOLD, 20.0)
	# Neck: short and very thick under the ruff.
	cc(b, W(722, 450), W(738, 512), 47.0, 59.0, D_GOLD, 24.0)
	# The ruff's bulk (fourth pass, measured with docs/.../overlay.gd): full at the sides of the
	# neck (+-68 px from the front) and forward over the chest (front at x 660).
	for side in [-1.0, 1.0]:
		ce(b, W(735, 488, side * 42.0), Vector3(40, 40, 26), D_GOLD, 20.0)
	ce(b, W(702, 528), Vector3(40, 46, 46), D_GOLD, 20.0)
	# Head: a face narrower than the skull, so the eyes sit on its front corners and show
	# from the front and from the side; round skull behind, soft cheeks, a broad short muzzle
	# with an almost level bridge.
	ce(b, W(697, 399), Vector3(44, 47, 41), D_GOLD, 12.0)   # +-41: the eye corners face 45 degrees out (seventh pass)
	ce(b, W(717, 400), Vector3(48, 48, 50), D_GOLD, 14.0)   # +-50: the ears, not the skull, are the head's outline from the front
	for side in [-1.0, 1.0]:
		ce(b, W(686, 431, side * 27.0), Vector3(29, 25, 27), D_GOLD, 22.0)
	ce(b, W(646, 434), Vector3(31, 28, 43), D_GOLD, 12.0)
	ce(b, W(641, 419), Vector3(24, 15, 24), D_GOLD, 12.0)
	# Ears: see D_EAR_RUNGS. The dog's left ear is built first and its outline measured.
	for side in [1.0, -1.0]:
		var start := _ears.size()
		for i in D_EAR_RUNGS.size() - 1:
			var y0: float = D_EAR_RUNGS[i][0]
			var y1: float = D_EAR_RUNGS[i + 1][0]
			for j in 3:
				_ear_rung_clay(lerpf(y0, y1, j / 3.0), side, _ears.size() == start)
		_ear_rung_clay(D_EAR_RUNGS[D_EAR_RUNGS.size() - 1][0], side, false)
		if side > 0.0:
			var bend := _ear_rung(D_EAR_DENT_Y)
			var hit: Vector3 = _ray(_ears, W(bend[3], D_EAR_DENT_Y, 150.0), Vector3(0, 0, -1))[0]
			_ear_swell = hit.z / DK - (bend[4] + bend[7])
			_ear_report()
	# The dent (sixth pass, user): on the sheet the ear's outer edge, seen from the front, has
	# a small dent level with the top of the nose, where the upper fold ends and the lower lobe
	# begins. A soft level groove pressed round the back rim, from just before the bend (the
	# outline seen from the front) to the back edge: about 1.3 px deep and 9 px tall, each
	# point set from the clay's own surface there. (Rejected the same day: a round dimple read
	# as a hole, a narrow cut as a slot, a groove up or across the outer face as a scratch.)
	var grooves := []
	for side in [1.0, -1.0]:
		var bend := _ear_at(D_EAR_DENT_Y, 0.5, side)
		var back := _ear_at(D_EAR_DENT_Y, 1.0, side)
		var n1: Vector3 = _ear_at(D_EAR_DENT_Y, 0.4, side)[1]
		var n2: Vector3 = back[1]
		var back_p: Vector3 = back[0]
		var bend_p: Vector3 = bend[0]
		var axis: Vector3 = (back_p - bend_p).normalized()
		var along1 := Vector3(n1.z, 0.0, -n1.x)
		if along1.dot(axis) < 0.0: along1 = -along1
		# A wide, shallow press: a narrow one (4 px across, 1.6 deep) left crisp edges.
		var cut := 8.0
		var marks := [[bend_p - along1 * 2.0 * DK, (n1 + n2).normalized(), 1.0], [back_p, n2, 0.0]]
		for deg in [60.0, 30.0, 0.0, -35.0]:
			marks.append([back_p, axis * cos(deg_to_rad(deg)) + n2 * sin(deg_to_rad(deg)), 1.4 if deg < 0.0 else 0.0])
		var pts := []
		for m in marks:
			var from: Vector3 = m[0]
			var dir: Vector3 = m[1]
			var skin: Vector3 = _ray(_ears, from + dir * 40.0 * DK, -dir)[0]
			pts.append(skin + dir * (cut - 1.3 + m[2]) * DK)
		for i in pts.size() - 1:
			grooves.append({"t": "cone", "a": pts[i], "b": pts[i + 1], "ra": cut * DK, "rb": cut * DK, "k": 0.0, "col": D_EAR,
					"crease": false, "paint": true, "sub": true})
	_ears.append_array(grooves)
	for side in [1.0, -1.0]:
		# Soft folds, painted a shade deeper on the outer face as on the sheet: the edge of the
		# upper fold, from the root down to the dent, and a fainter one inside the front edge.
		for fold in [[[378.0, 0.3], [389.0, 0.37], [399.0, 0.43], [405.0, 0.48]], [[382.0, 0.08], [402.0, 0.07], [424.0, 0.08], [444.0, 0.1]]]:
			var line := []
			for q in fold:
				var at := _ear_at(q[0], q[1], side)
				var on: Vector3 = at[0]
				var n: Vector3 = at[1]
				line.append(on + n * (_ear_rung(q[0])[7] + _ear_swell + 0.5) * DK)
			for i in line.size() - 1:
				_ear_tints.append({"t": "cone", "a": line[i], "b": line[i + 1], "ra": 1.2 * DK, "rb": 1.2 * DK,
						"c": (line[i] + line[i + 1]) * 0.5, "r": Vector3.ONE * (line[i].distance_to(line[i + 1]) * 0.5 + 9.0 * DK),
						"col": D_EAR * (0.9 if fold[0][1] > 0.2 else 0.94), "soft": 7.0 * DK})
	# Legs, as in the side view: left front reaching forward, right front back under the
	# chest, left hind back, right hind forward under the belly.
	_dleg([W(735, 560, 30), W(717, 612, 30), W(683, 662, 30)], [30.0, 25.0, 22.0], W(662, 686, 30))
	_dleg([W(745, 560, -30), W(762, 615, -30), W(776, 657, -30)], [30.0, 25.0, 22.0], W(771, 685, -30))
	_dleg([W(920, 558, 33), W(948, 608, 33), W(967, 652, 33)], [35.0, 27.0, 22.0], W(976, 686, 33))
	_dleg([W(900, 562, -33), W(871, 614, -33), W(852, 656, -33)], [33.0, 26.0, 22.0], W(843, 686, -33))
	for paw in [W(662, 0, 30), W(771, 0, -30), W(976, 0, 33), W(843, 0, -33)]:
		carve(b, Vector3(paw.x, -40.0 * DK, paw.z), Vector3(120, 40, 120) * DK, D_GOLD)   # flat soles

	# Nose: a dark piece on the tip of the muzzle, wide and round on top, narrowing to a
	# rounded point underneath; two nostrils pressed in.
	var m := _nose
	ce(m, W(617, 417.0), Vector3(9.5, 10, 17), D_NOSE)
	ce(m, W(616.0, 425.5), Vector3(6.5, 8.5, 8.0), D_NOSE, 5.0)
	for side in [-1.0, 1.0]:
		var at: Vector3 = _ray(m, W(560, 423.0, side * 8.5), Vector3(1, 0, 0))[0]
		carve(m, at, Vector3(4.0, 3.0, 3.6) * DK, D_NOSTRIL)

	# Tail: carried high. One thick continuous plume: a full base, swelling as it curves up
	# and tapering as it curls forward to the tip, with soft rounded swells along its outer
	# and lower edge. The cream of the feathers is painted on, fading into the gold.
	var t := _tail
	tube(t, [W(933, 492), W(964, 484), W(993, 468), W(1004, 440), W(995, 411), W(975, 393), W(951, 385)],
			[19.0, 29.0, 37.0, 33.0, 25.0, 15.0, 7.0], D_GOLD, 0.0, 12.0)
	for lobe in [[987, 500, 30, 24, 34], [1014, 484, 24, 30, 30], [1030, 452, 16, 24, 26], [1013, 420, 16, 20, 20]]:
		ce(t, W(lobe[0], lobe[1]), Vector3(lobe[2], lobe[3], lobe[4]), D_GOLD, 12.0)
	for patch in [[968, 384, 26, 12, 14], [1014, 416, 24, 26, 34], [1034, 452, 24, 34, 46], [1026, 492, 30, 30, 50],
			[994, 514, 36, 22, 50], [962, 512, 20, 16, 40]]:
		_tail_tints.append({"t": "ell", "c": W(patch[0], patch[1]), "r": Vector3(patch[2], patch[3], patch[4]) * DK, "inv": Basis(),
				"col": D_CREAM, "soft": CELL * 6.0})

	_feathers()
	_coat()


## Painted areas on the golden skin, soft-edged.
func _coat() -> void:
	var soft := CELL * 4.0
	_tint(W(700, 405), Vector3(75, 70, 75) * DK, Basis(), D_HEAD, CELL * 6.0)         # the head is a lighter gold
	_tint(W(645, 438), Vector3(48, 36, 56) * DK, Basis(), D_CREAM, CELL * 4.0)        # muzzle and under the eyes
	_tint(W(668, 380), Vector3(42, 52, 11.0) * DK, Basis(), D_CREAM.lerp(D_HEAD, 0.3), CELL * 5.0)   # a soft blaze up the forehead
	_tint(W(692, 552), Vector3(46, 78, 44) * DK, Basis(), D_CREAM, soft)              # chest
	_tint(W(828, 636), Vector3(50, 80, 120) * DK, Basis(), D_CREAM, soft)             # belly
	for paw in [W(662, 690, 30), W(771, 690, -30), W(976, 690, 33), W(843, 690, -33)]:
		_tint(paw, Vector3(50, 56, 40) * DK, Basis(), D_CREAM, CELL * 8.0)            # lower legs and paws


## Fur clumps: the ruff round the neck and chest, the belly fringe, the feathers behind the
## front legs and the trousers behind the thighs. Few, broad and round-ended.
func _feathers() -> void:
	var down := Vector3(0, -1, 0)
	for row in [[482.0, 729.0, [0, 46, 92, 136], 44.0, 36.0], [516.0, 735.0, [23, 69, 112], 46.0, 38.0],
			[552.0, 741.0, [0, 44], 46.0, 38.0], [586.0, 746.0, [0], 40.0, 32.0]]:
		for deg in row[2]:
			for side in ([1.0] if deg == 0 else [-1.0, 1.0]):
				var a := deg_to_rad(deg)
				var radial := Vector3(-cos(a), 0.0, side * sin(a))
				_clump(W(row[1], row[0]) + radial * 230.0 * DK, -radial, down + radial * 0.1, row[3], row[4])
	for side in [-1.0, 1.0]:
		for x in [800.0, 832.0]:
			_clump(W(x, 690, side * 14.0), Vector3(0, 1, 0), Vector3(1, -0.3, 0), 28.0, 20.0, 6.0)
		_clump(W(1060, 575, side * 34.0), Vector3(-1, 0, 0), Vector3(0.3, -1, 0), 40.0, 28.0, 7.0)
		_clump(W(1060, 608, side * 34.0), Vector3(-1, 0, 0), Vector3(0.3, -1, 0), 32.0, 22.0, 6.0)
	_clump(W(820, 622, 30), Vector3(-1, 0, 0), Vector3(0.5, -1, 0), 30.0, 20.0, 6.0)
	_clump(W(812, 620, -30), Vector3(-1, 0, 0), Vector3(0.5, -1, 0), 30.0, 20.0, 6.0)
	_press_clumps()


## giraffe_clay.gd's skin colour, keeping the creases between the toes under the paint: the
## crease shade is read off the golden skin, the patches are painted, then it is put back.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	if _plain_paint: return super._tinted(v, col, reach)
	var dark := D_GOLD * D_GOLD_SHADE
	var span := Vector3(D_GOLD.r - dark.r, D_GOLD.g - dark.g, D_GOLD.b - dark.b)
	var shade := clampf(Vector3(col.r - dark.r, col.g - dark.g, col.b - dark.b).dot(span) / span.length_squared(), 0.0, 1.0)
	var c := super._tinted(v, D_GOLD, reach)
	var f := lerpf(D_GOLD_SHADE, 1.0, shade)
	return Color(c.r * f, c.g * f, c.b * f, 1.0)


## First point of a group's surface along a ray (working space): [point, outward normal].
func _ray(group: Array, from: Vector3, dir: Vector3) -> Array:
	var p := from
	var d := dir.normalized()
	for i in 4000:
		var f := _field(group, p)
		if f <= 0.0: break
		p += d * maxf(f * 0.5, 0.1)
	return [p, _normal(group, p)]


func _normal(group: Array, p: Vector3) -> Vector3:
	var h := 0.5
	return Vector3(
		_field(group, p + Vector3(h, 0, 0)) - _field(group, p - Vector3(h, 0, 0)),
		_field(group, p + Vector3(0, h, 0)) - _field(group, p - Vector3(0, h, 0)),
		_field(group, p + Vector3(0, 0, h)) - _field(group, p - Vector3(0, 0, h))).normalized()


## Drops a point near the face onto the skin along -n, then lifts it `lift` sheet px.
func _drop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * DK
	for i in 800:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * DK


## Moves a point near the skin onto it (along the field's gradient): [point, outward normal].
func _snap(p: Vector3) -> Array:
	var q := p
	for i in 16:
		q -= _normal(_body, q) * _field(_body, q)
	return [q, _normal(_body, q)]


# --- Face details -------------------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _dog_eye_frame(side: float) -> Array:
	var hit := _ray(_body, W(560, D_EYE_Y, side * D_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	# Turned 5 degrees further outward than the skin: the sheet's side view shows the eye wider
	# than a dome lying flat on this face would (its edge still follows the skin).
	var turn := deg_to_rad(5.0)
	var out := right * side
	var n2 := (n * cos(turn) + out * sin(turn)).normalized()
	var out2 := (out * cos(turn) - n * sin(turn)).normalized()
	return [hit[0], n2, out2, n2.cross(out2 * side).normalized()]


## Radius of the eye's outline at an angle (degrees): a smooth curve through D_EYE_OUTLINE.
static func _eye_radius(deg: float) -> float:
	var count := D_EYE_OUTLINE.size()
	var first: float = D_EYE_OUTLINE[0][0]
	var d := fposmod(deg - first, 360.0) + first
	for i in count:
		var a0: float = D_EYE_OUTLINE[i][0]
		var a1: float = D_EYE_OUTLINE[(i + 1) % count][0] + (360.0 if i == count - 1 else 0.0)
		if d <= a1:
			var p0: float = D_EYE_OUTLINE[(i - 1 + count) % count][1]
			var p1: float = D_EYE_OUTLINE[i][1]
			var p2: float = D_EYE_OUTLINE[(i + 1) % count][1]
			var p3: float = D_EYE_OUTLINE[(i + 2) % count][1]
			var t := (d - a0) / (a1 - a0)
			return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
	return D_EYE_OUTLINE[0][1]


## Colour of the eye at (o toward the outer corner, u up) from its centre, `inset` px in from
## the outline at angle `deg`. Painted, as on the sheet: a dark rim that is the upper lid
## (thick over the top and thickest above the outer corner) and thins to a fine brown line
## underneath; a tall dark-brown iris toward the nose that fills the eye's height, warmer and
## lighter low down, its big pupil soft-edged; white only as a wedge at the outer corner.
static func _eye_colour(o: float, u: float, inset: float, deg: float) -> Color:
	# Ninth pass (user: "make the eyes sharper, more like the original design"), re-read from
	# the sheet at 11x: a crisp dark line all round, thick over the top and running straight
	# down to a pointed outer corner; a narrower upright iris (15 px wide, 17 tall) with a dark
	# ring, so the white is a clear triangle between the iris, the lid and the corner; crisp
	# edges throughout.
	var d := deg if deg <= 270.0 else deg - 360.0
	var lid := smoothstep(-40.0, -14.0, d) * (1.0 - smoothstep(170.0, 205.0, d))
	var rim_w := lerpf(0.8, 1.9 + 0.5 * exp(-pow((d - 35.0) / 45.0, 2.0)), lid)
	var rim := D_UNDER.lerp(D_LID, lid)
	var e := pow((o + 2.5) / 7.6, 2.0) + pow(u / 9.4, 2.0)
	var iris := D_IRIS_DARK.lerp(D_IRIS_LIGHT, (1.0 - smoothstep(-8.0, 3.0, u)) * (0.3 + 0.7 * minf(e, 1.0)))
	iris = iris.lerp(D_IRIS_DARK * 0.7, 0.85 * smoothstep(0.74, 0.92, e))   # the dark ring round the iris
	var pupil := pow((o + 2.6) / 3.9, 2.0) + pow((u + 0.2) / 4.7, 2.0)
	iris = iris.lerp(D_PUPIL, 1.0 - smoothstep(0.6, 1.2, pupil))
	iris = iris * lerpf(1.0, 0.72, smoothstep(4.5, 9.0, u))            # in the lid's shade
	var white := D_SCLERA * lerpf(1.0, 0.88, smoothstep(2.0, 8.0, u))
	var c := white.lerp(iris, 1.0 - smoothstep(0.94, 1.06, e))
	c = c.lerp(rim, 1.0 - smoothstep(rim_w - 0.1, rim_w + 0.1, inset))
	c.a = 1.0
	return c


## Eyes: one painted dome each (see D_EYE_OUTLINE and _eye_colour), following the head's
## curve and bulging D_EYE_DOME px proud of it, its edge on the skin; one small round
## catch-light high on the nose side.
func _dog_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	var segs := D_EYE_SEGS
	var rings := D_EYE_RINGS
	for side in [-1.0, 1.0]:
		var f := _dog_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# The skin's height round the outline (the head curves away from the eye's centre).
		var radius := PackedFloat32Array()
		var skin := PackedFloat32Array()
		for i in segs:
			var a := TAU * i / segs
			var r := _eye_radius(360.0 * i / segs)
			radius.append(r)
			skin.append((_drop(s + (out * cos(a) + up * sin(a)) * r * DK, n, 0.0) - s).dot(n) / DK)
		# _drop() steps in tenths of a unit; smooth that out, or the dome's shine shows it as rays.
		for pass_i in 3:
			var smooth := PackedFloat32Array()
			for i in segs:
				var sum := 0.0
				for k in range(-4, 5): sum += skin[(i + k + segs) % segs]
				smooth.append(sum / 9.0)
			skin = smooth
		# Grid of rings from the centre out; the last ring is a skirt tucked under the edge.
		var pts := PackedVector3Array()
		var cols := PackedColorArray()
		for j in rings + 2:
			var rho := minf(float(j) / rings, 1.0)
			for i in segs:
				var a := TAU * i / segs
				var r := radius[i]
				var o := cos(a) * r * rho
				var u := sin(a) * r * rho
				var h := (skin[i] + 0.25) * rho * rho + D_EYE_DOME * (1.0 - rho * rho)
				if j == rings + 1: h -= 2.0
				pts.append(s + (out * o + up * u + n * h) * DK)
				cols.append(_eye_colour(o, u, (1.0 - rho) * r, 360.0 * i / segs))
		var nrm := PackedVector3Array()
		nrm.resize(pts.size())
		var tris := []
		for j in rings + 1:
			for i in segs:
				var a0 := j * segs + i
				var a1 := j * segs + (i + 1) % segs
				for t in [[a0, a0 + segs, a1 + segs], [a0, a1 + segs, a1]]:
					var c := (pts[t[1]] - pts[t[0]]).cross(pts[t[2]] - pts[t[0]])
					if side > 0.0: c = -c          # the grid winds the other way on the mirrored eye
					for v in t: nrm[v] += c
					tris.append(t)
		# The grid's winding is the same all over, so one test orients every normal outward.
		var probe: Vector3 = nrm[(rings / 2) * segs]
		var sign_out := 1.0 if probe.dot(n) > 0.0 else -1.0
		var centre := Vector3.ZERO
		for i in segs: centre += nrm[i]
		for i in segs: nrm[i] = centre
		for t in tris:
			g.color = cols[t[0]]
			var before := g.verts.size()
			g.tri(pts[t[0]], pts[t[1]], pts[t[2]], (nrm[t[0]] * sign_out).normalized(), (nrm[t[1]] * sign_out).normalized(), (nrm[t[2]] * sign_out).normalized())
			# tri() may swap its second and third corners; give each corner its own colour.
			for k in 3:
				for v in t:
					if g.verts[before + k] == pts[v]:
						g.cols[before + k] = cols[v]
						break
		if side > 0.0:
			var lo := Vector3(INF, INF, INF)
			var hi := -lo
			for i in segs:
				var edge: Vector3 = pts[rings * segs + i] / DK
				lo = lo.min(edge)
				hi = hi.max(edge)
			print("EYE outline, sheet px: %.1f wide from the front, %.1f from the side, %.1f tall; centre x %.1f" % [hi.z - lo.z, hi.x - lo.x, hi.y - lo.y,
					DX + ((lo.x + hi.x) * 0.5 - X0 / DK)])
		var go := Vector2(-1.8, 3.0)
		var deg := rad_to_deg(atan2(go.y, go.x))
		var seg := int(round(fposmod(deg, 360.0) / 360.0 * segs)) % segs
		var rho := go.length() / radius[seg]
		var gh := (skin[seg] + 0.25) * rho * rho + D_EYE_DOME * (1.0 - rho * rho)
		g.color = D_GLINT
		g.ellipsoid(s + (out * go.x + up * go.y + n * (gh + 0.1)) * DK, Vector3(1.3, 1.3, 0.4) * DK, Basis(out, up, n), 16, 8)
	return _to_model(g)


## Eyebrows and the mouth. (The lid lines are painted on the eyes.)
func _dog_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _dog_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Eyebrow: a short soft arc of darker gold well above the eye, the outer end lower.
		g.color = D_BROW
		var brow := []
		var brow_w := []
		for q in [[9.5, 20.5, 1.5], [5.0, 24.5, 2.3], [-1.0, 26.5, 2.6], [-6.0, 26.0, 2.3], [-10.0, 24.5, 1.5]]:
			brow.append(_drop(s + (out * q[0] + up * q[1]) * DK, n, 0.2))
			brow_w.append(Vector2(q[2], 1.0) * DK)
		g.loft(brow, brow_w, n, 10)
		# Mouth: from under the nose down, out and back along the muzzle to a smile corner.
		g.color = D_MOUTH
		var lip := []
		var lip_w := []
		var lip_n := Vector3.ZERO
		for q in [[614, 445.0, 0.0, 0.75], [616, 448.5, 7.0, 0.8], [622, 451.0, 17.0, 0.8], [633, 450.5, 27.0, 0.8],
				[643, 447.0, 35.0, 0.85], [654, 441.5, 37.0, 1.0], [661, 435.5, 34.5, 1.3], [663, 432.0, 33.0, 0.8]]:
			var hit := _snap(W(q[0], q[1], side * q[2]))
			lip.append(hit[0] + hit[1] * 0.1 * DK)
			lip_w.append(Vector2(q[3], q[3]) * DK)
			lip_n += hit[1]
		g.loft(lip, lip_w, lip_n.normalized(), 8)
	g.color = D_MOUTH
	var philtrum := []
	for y in [433.0, 439.0, 445.0]:
		var hit := _snap(W(611, y))
		philtrum.append(hit[0] + hit[1] * 0.1 * DK)
	g.loft(philtrum, [Vector2(0.8, 0.8) * DK, Vector2(0.8, 0.8) * DK, Vector2(0.8, 0.8) * DK], Vector3(-1, 0, 0), 8)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / FINE
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh, by := FINE) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= by
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _nose, _tail, _clumps, _tail_tints, _ear_tints]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "GoldenRetrieverClayDisplay"
	root.set_meta("source", "User's Golden Retriever Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.95)
	clay.metallic_specular = 0.2
	for part in [["Body", _body, D_GOLD * D_GOLD_SHADE, 5.0], ["Ears", _ears, D_EAR, 5.0], ["Nose", _nose, D_NOSE, 5.0], ["Tail", _tail, D_GOLD, 6.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		var crease: Color = part[2]
		crease.a = 1.0
		var ear: bool = part[0] == "Ears"
		mi.mesh = _mesh(_enlarged(part[1], D_EAR_FINE) if ear else part[1], crease, part[3])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		elif part[0] == "Tail":
			var body_tints := _tints
			_tints = _tail_tints
			mi.mesh = _paint(mi.mesh)
			_tints = body_tints
		elif ear:
			# The ear is meshed D_EAR_FINE larger, so its paint is enlarged the same way.
			var body_tints := _tints
			_tints = _enlarged(_ear_tints, D_EAR_FINE)
			for t in _tints:
				t.c = Vector3(X0, 0, 0) + (t.c - Vector3(X0, 0, 0)) * D_EAR_FINE
				t.r = t.r * D_EAR_FINE
				t.soft = t.soft * D_EAR_FINE
			_plain_paint = true
			mi.mesh = _paint(mi.mesh)
			_plain_paint = false
			_tints = body_tints
		mi.mesh = _fit(mi.mesh, FINE * D_EAR_FINE if ear else FINE)
		mi.material_override = _material(0.6) if part[0] == "Nose" else clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _dog_eyes()
	eyes.material_override = _material(0.42)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _dog_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(W(605, DY, -75)) / FINE
	var c := to_model(W(1035, DTOP, 75)) / FINE
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
