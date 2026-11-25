extends "res://scripts/characters/cow_clay.gd"
## Clay-style sheep traced from the user's "Sheep Character Blueprint" turnaround (24 Nov 2026,
## "Stylized 3D, Relaxed Idle": front 3/4, front, side, back, rear 3/4). A static display model,
## built once by tools/build_sheep_clay.gd into scenes/animals/sheep_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd: _tint, _paint) and the clay cow's helpers (cow_clay.gd: _ray), like the
## clay chick. Shapes are written in the sheep sheet's side-view pixels (x to the right = toward
## the tail, y down, z lateral, + = the side facing the viewer = the sheep's left) and SP()
## scales them into the lion's working space. Meshed SF times larger than life and shrunk
## afterwards, so the clay grid is about 1 cm on the finished model.
##
## Parts: "Body" (the peach face, head and legs, one fused mesh; the blush is painted),
## "Wool" (the fleece, head cap and tail: round puffs with soft creases where they meet),
## "Hooves", "Ears" (cupped leaves, pink inside), "Nose" (a small raised pink heart),
## "LeftEye" / "RightEye" (each its own mesh centred on its node, local y up the eye and z out
## of the face) and "Face details" (lashes, brows, the line under the nose and the smile).
## Output faces -Z (head), +Y up, ground at y = 0.

const Pig := preload("res://scripts/characters/pig_clay.gd")

const SH := 1.05                # town units to the top of the wool (park_animals.gd ANIMAL_HEIGHTS "Sheep")
const SY := 527.0               # sheet y of the soles
const STOP := 177.0             # sheet y of the top of the wool
const SX := 952.0               # sheet x placed at the model origin
const SF := 3.0                 # meshed this many times larger than life
const SK := SF * SH / ((SY - STOP) * S)   # sheet pixel -> lion working unit

const S_WOOL := Color("f9e7d8")
const S_WOOL_LOW := Color("f2d0b4")       # the fleece warms toward the belly
const S_WOOL_CREASE := Color("efd0b8")
const S_SKIN := Color("f7c4a0")           # under the sheet's ffd8b2: the town light is bright and warm
const S_SKIN_CREASE := Color("e6ae80")
const S_LEG := Color("f4bd8e")
const S_HOOF := Color("7a4b2e")
const S_HOOF_CREASE := Color("5c351e")
const S_EAR := Color("f6c69e")
const S_EAR_PINK := Color("f49a76")
const S_EAR_CREASE := Color("e6ad84")
const S_NOSE := Color("ef9a7a")
const S_NOSE_CREASE := Color("d97a58")
const S_BLUSH := Color("f7ab8c")
const S_BROW := Color("7a5236")
const S_LASH := Color("2c180b")
const S_MOUTH := Color("7d4a2c")
const E_RIM := Color("24130a")
const E_IRIS := Color("381f10")
const E_IRIS_LOW := Color("5a3820")
const E_PUPIL := Color("0b0604")
const E_WHITE := Color("f1e6d8")
const E_GLINT := Color("fffdf8")

# Eyes (sheet px). Centre height and lateral offset from the front view; half-sizes across the
# skin from the 3/4 view, which looks most nearly straight at the eye (35 x 40).
const E_Y := 301.0
const E_Z := 44.0
const E_R := Vector2(17.5, 19.0)
const E_LIFT := 0.4             # the eye's edge above the skin
const E_BULGE := 3.0            # extra height at the middle: a glossy, gently domed eye
const E_YAW := deg_to_rad(30.0) # how far each eye turns out from straight ahead
const E_FLAT := 0.85            # 0 = the eye follows the skin's curve, 1 = a flat disc on its plane

## Legs as [sheet x, lateral z]. Relaxed idle: the far (right) legs stand a little forward.
const S_LEGS := [[897.0, 40.0], [877.0, -40.0], [1017.0, 43.0], [992.0, -43.0]]

var _wool := []
var _nose := []


## Sheet pixel -> working space (y up).
static func SP(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - SX) * SK, (SY - y) * SK, z * SK)


func se(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * SK, col, k * SK, crease, basis)


func sc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * SK, rb * SK, col, k * SK)


## One round wool puff of radius r (sheet px) at sheet point (x, y, z).
func puff(x: float, y: float, z: float, r: float) -> void:
	se(_wool, SP(x, y, z), Vector3(r, r, r), S_WOOL, 7.0, true)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Head (rebuilt again 24 Nov 2026, "face first", fitted to the front AND side views): bear
	# style, a head ball plus a round muzzle. The ball gives the front view's round outline
	# (half-width 77) and, in the side view, puts the skin at the eyes (+-44) back at x ~812 and
	# the ear roots at ~868. The muzzle is a round ball in the middle that carries the side
	# profile forward to the nose tip (751, 320), the bridge (770, 288) and the chin (765, 345),
	# falling back fast toward the eyes. Low full cheeks round off the front view's jaw.
	se(b, SP(914, 300), Vector3(122, 62, 77), S_SKIN)
	se(b, SP(832, 268), Vector3(42, 30, 36), S_SKIN, 24.0)          # forehead: the profile slopes back to (790, 258) under the cap
	se(b, SP(797, 322), Vector3(45, 38, 36), S_SKIN, 12.0)
	se(b, SP(792, 349), Vector3(28, 15, 26), S_SKIN, 10.0)          # chin: rounder and a little lower, (775, 360)
	for side in [-1.0, 1.0]:
		se(b, SP(830, 335, side * 30.0), Vector3(40, 26, 36), S_SKIN, 20.0)
	# Neck under the wool, so the head sits on the body.
	se(b, SP(875, 330), Vector3(48, 52, 52), S_SKIN, 20.0)
	# Legs: thick round peach posts, tops hidden in the fleece.
	for leg in S_LEGS:
		sc(b, SP(leg[0], 450, leg[1]), SP(leg[0], 497, leg[1]), 21.5, 20.5, S_LEG, 0.0)

	# Hooves: short rounded drums, a little wider than the legs, flat underneath.
	var h := _hooves
	for leg in S_LEGS:
		se(h, SP(leg[0], 506, leg[1]), Vector3(23, 10, 23), S_HOOF, 0.0)
		se(h, SP(leg[0] - 1.0, 516, leg[1]), Vector3(25.5, 12, 25), S_HOOF, 8.0)
	for leg in S_LEGS:
		carve(h, SP(leg[0], SY + 30.0, leg[1]), Vector3(60, 30, 60) * SK, S_HOOF)

	_fleece()
	_head_cap()
	_tail_puffs()
	_ear_leaves()
	_nose_heart()

	# Blush: a soft round patch on each cheek, below and outside the eye.
	for side in [-1.0, 1.0]:
		var hit := _ray(_body, SP(700, 337, side * 60.0), Vector3(1, 0, 0))
		_tint(hit[0], Vector3(15, 13, 13) * SK, Basis(), S_BLUSH, 11.0 * SK)


## Body fleece: a core with round puffs spread evenly over an egg-shaped shell (a Fibonacci
## lattice, so the lobes are even but not in rows), each bulging out of the shell.
func _fleece() -> void:
	se(_wool, SP(952, 394), Vector3(118, 70, 92), S_WOOL, 0.0)
	var c := SP(952, 394)
	var shell := Vector3(140, 89, 112)
	var count := 34
	var golden := PI * (3.0 - sqrt(5.0))
	for i in count:
		var yv := 1.0 - 2.0 * (i + 0.5) / count
		var rr := sqrt(1.0 - yv * yv)
		var th := i * golden
		var dir := Vector3(cos(th) * rr, yv, sin(th) * rr)
		var p := c + Vector3(dir.x * shell.x, dir.y * shell.y, dir.z * shell.z) * SK
		var n := Vector3(dir.x / shell.x, dir.y / shell.y, dir.z / shell.z).normalized()
		var r := 45.0 + 4.0 * _h(31, i, 0)
		se(_wool, p - n * r * 0.62 * SK, Vector3(r, r, r), S_WOOL, 7.0, true)


## Head cap: puffs over the crown, a scalloped fringe of smaller puffs along the forehead,
## and the nape running down into the fleece.
func _head_cap() -> void:
	# Crown: a rounded dome of puffs that sits on top of the head (front view +-92 wide at
	# most), with its lower edge just above the ears; the face below stays bare.
	puff(838, 206, 0, 30)
	puff(878, 198, 0, 32)
	puff(920, 210, 0, 30)
	puff(955, 230, 0, 28)
	for s in [-1.0, 1.0]:
		puff(835, 216, s * 34.0, 27)
		puff(878, 214, s * 40.0, 28)
		puff(920, 220, s * 40.0, 28)
		puff(955, 240, s * 36.0, 27)
		puff(824, 236, s * 52.0, 21)
		puff(854, 236, s * 60.0, 22)
		puff(888, 240, s * 64.0, 23)
		puff(922, 248, s * 62.0, 25)
		# Behind the face's edge, above the ears: the cap comes down round the face like a hood.
		puff(910, 258, s * 72.0, 24)
		puff(936, 272, s * 70.0, 25)
		# Temples: the hood rounds off the face's top corners from behind (front view: the face's
		# outline goes under the wool above y 275).
		puff(862, 262, s * 76.0, 22)
		puff(878, 279, s * 82.0, 19)
	# Fringe: [lateral z, sheet y of its lower edge, radius], from the front view. A level ray
	# finds the forehead just under that edge; the puff's middle sits a little behind that
	# point, so the fringe lies on the forehead (no visor) and its scallops show on the skin.
	for f in [[0.0, 259.0, 22.0], [-36.0, 258.0, 22.0], [36.0, 258.0, 22.0], [-66.0, 264.0, 21.0], [66.0, 264.0, 21.0]]:
		var from := SP(700, f[1] + 4.0, f[0] * 1.3)
		var dir := (SP(850, f[1] + 4.0) - from).normalized()
		var hit := _ray(_body, from, dir)
		var centre: Vector3 = hit[0] + dir * f[2] * 0.3 * SK
		centre.y = SP(0, f[1] - f[2] * 0.95).y
		se(_wool, centre, Vector3(f[2], f[2], f[2]), S_WOOL, 7.0, true)
	# Nape: behind the head the wool runs down into the fleece (no dip behind the cap).
	puff(980, 284, 0, 28)
	puff(1002, 298, 0, 30)
	for s in [-1.0, 1.0]:
		puff(962, 280, s * 46.0, 26)
		puff(985, 292, s * 40.0, 27)
		puff(1000, 296, s * 45.0, 30)
		puff(972, 302, s * 66.0, 28)
		puff(948, 296, s * 66.0, 27)


## Tail: a little cloud of four puffs high on the rump.
func _tail_puffs() -> void:
	puff(1093, 362, 0, 24)
	puff(1090, 408, 0, 19)
	for s in [-1.0, 1.0]:
		puff(1097, 391, s * 14.0, 21)
		puff(1085, 350, s * 18.0, 18)


## Ears: long flat leaves, wider toward the tip, hanging out and a little down and back from
## behind the face's edge (front view: the face's outline runs on past the ear roots); the inner face is cupped and pink and faces forward and down.
func _ear_leaves() -> void:
	for side in [-1.0, 1.0]:
		var root := SP(894, 284, side * 68.0)
		var d := Vector3(0.45, -0.45, side * 0.77).normalized()
		var n0 := Vector3(-0.55, -0.45, side * 0.45)
		var n := (n0 - d * n0.dot(d)).normalized()
		var w := n.cross(d).normalized()
		var basis := Basis(d, w, n)
		var mid := root + d * 44.0 * SK
		se(_ears, mid, Vector3(48, 30, 9), S_EAR, 0.0, false, basis)
		se(_ears, root + d * 12.0 * SK, Vector3(20, 14, 9.5), S_EAR, 8.0, false, basis)
		carve(_ears, mid + (d * 5.0 + n * 10.5) * SK, Vector3(39, 23, 7) * SK, S_EAR_PINK, basis)


## Nose: a small raised rounded triangle at the front of the muzzle, wide and flat on top,
## tapering to a soft point where the line down to the smile starts.
func _nose_heart() -> void:
	for lobe in [[0.0, 324.5, 15.5, 4.2], [0.0, 328.5, 9.5, 4.0], [0.0, 332.0, 4.5, 2.8]]:
		var hit := _ray(_body, SP(700, lobe[1], lobe[0]), Vector3(1, 0, 0))
		var n: Vector3 = hit[1]
		var across := (Vector3(0, 0, 1) - n * n.z).normalized()
		se(_nose, hit[0] - n * 1.2 * SK, Vector3(lobe[2], lobe[3], 3.4), S_NOSE, 4.0, false, Basis(across, n.cross(across).normalized(), n))


# --- Eyes and face details ----------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
## The eye faces E_YAW out from straight ahead (the sheet shows it about as wide from the side
## as from the front), whatever the skin's own slope under it.
func _sheep_eye_frame(side: float) -> Array:
	var hit := _ray(_body, SP(700, E_Y, side * E_Z), Vector3(1, 0, 0))
	var skin: Vector3 = hit[1]
	var level := Vector2(-skin.x, skin.z).length()
	var n := Vector3(-cos(E_YAW) * level, skin.y, side * sin(E_YAW) * level).normalized()
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## A point on the skin near the face: p dropped along -n onto the head, then lifted `lift` px.
func _sdrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 10.0 * SK
	for i in 600:
		var d := _field(_body, q)
		if d <= 0.02: break
		q -= n * maxf(d * 0.6, 0.02)
	return q + n * lift * SK


## A point of the eye's surface at (o, u) sheet px from its centre (o toward the outer corner,
## u up the eye): on the skin, lifted E_LIFT plus the dome, plus `extra`.
func _eye_point(f: Array, o: float, u: float, extra := 0.0) -> Vector3:
	var p: Vector3 = f[0] + (f[2] * o + f[3] * u) * SK
	var t2 := minf(pow(o / E_R.x, 2.0) + pow(u / E_R.y, 2.0), 1.0)
	var lift := E_LIFT + E_BULGE * sqrt(1.0 - t2) + extra
	var on_skin := _sdrop(p, f[1], lift)
	var on_plane: Vector3 = f[0] + (f[2] * o + f[3] * u + f[1] * lift) * SK
	if (on_plane - on_skin).dot(f[1]) < 0.0:
		return on_skin          # never under the skin
	return on_skin.lerp(on_plane, E_FLAT if extra >= 0.0 else 0.0)


## Colour of the eye at (o, u), traced from the sheet's front view at 6x: a large glossy black
## pupil a little low and toward the nose, a dark brown iris round it (warmer at the bottom), a
## thin warm-white crescent just inside the rim down the outer side, and a dark rim that is
## heaviest over the top (the upper lid line).
static func _eye_colour(o: float, u: float) -> Color:
	var d := Vector2(o / E_R.x, u / E_R.y).length()
	var dp := Vector2((o + 2.0) / 12.0, (u + 3.0) / 14.5).length()
	var col := E_PUPIL.lerp(E_IRIS, smoothstep(0.86, 1.08, dp))
	col = col.lerp(E_IRIS_LOW, smoothstep(0.2, 0.9, -u / E_R.y) * smoothstep(0.95, 1.2, dp) * 0.7)
	var outer := o / (E_R.x * maxf(d, 0.001))       # 1 at the outer corner, -1 at the nose side
	var band := smoothstep(0.72, 0.76, d) * (1.0 - smoothstep(0.85, 0.88, d))
	col = col.lerp(E_WHITE, band * smoothstep(0.0, 0.55, outer))
	var rim := 0.9 - 0.09 * clampf(u / E_R.y, 0.0, 1.0)
	return col.lerp(E_RIM, smoothstep(rim - 0.025, rim + 0.025, d))


## One eye: [mesh in the eye's own frame, that frame in model space]. A domed surface that
## follows the head (as the clay chick's), with one round catch-light high on the nose side.
func _sheep_eye(side: float) -> Array:
	var f := _sheep_eye_frame(side)
	var n: Vector3 = f[1]
	var g := Plaza.Geo.new()
	var rings := 30
	var segs := 64
	var pts := []
	var cols := []
	for i in rings + 2:
		var t := minf(float(i) / rings, 1.0)
		var row := PackedVector3Array()
		var crow := PackedColorArray()
		for j in segs:
			var a := TAU * j / segs
			var o := t * E_R.x * cos(a)
			var u := t * E_R.y * sin(a)
			row.append(_eye_point(f, o, u, -1.4 if i > rings else 0.0))
			crow.append(_eye_colour(o, u))
		pts.append(row)
		cols.append(crow)
	var nrm := []
	for i in rings + 2:
		var row := PackedVector3Array()
		for j in segs:
			if i == 0 or i > rings:
				row.append(n if i == 0 else nrm[rings][j])
				continue
			var across: Vector3 = pts[i][(j + 1) % segs] - pts[i][(j + segs - 1) % segs]
			var along: Vector3 = pts[i + 1 if i < rings else i][j] - pts[i - 1][j]
			var v := across.cross(along).normalized()
			row.append(v if v.dot(n) > 0.0 else -v)
		nrm.append(row)
	for i in rings + 1:
		for j in segs:
			var j2 := (j + 1) % segs
			for tri in [[[i, j], [i + 1, j], [i + 1, j2]], [[i, j], [i + 1, j2], [i, j2]]]:
				if i == 0 and tri[2] == [i, j2]: continue      # the centre ring is one point
				var corner_pts := []
				var corner_n := []
				var corner_c := []
				for corner in tri:
					corner_pts.append(pts[corner[0]][corner[1]])
					corner_n.append(nrm[corner[0]][corner[1]])
					corner_c.append(cols[corner[0]][corner[1]])
				Pig._ctri(g, corner_pts, corner_n, corner_c)
	# Catch-light: a round white spot riding on the dome, its edge softened into the pupil.
	var at := Vector2(-5.0, 8.0)
	var mid := _eye_point(f, at.x, at.y, 0.5)
	var spot := [[mid]]
	var spot_c := [[E_GLINT]]
	for i in range(1, 6):
		var r := 4.3 * i / 5.0
		var ring := []
		var ring_c := []
		for j in 24:
			var a := TAU * j / 24.0
			ring.append(_eye_point(f, at.x + cos(a) * r, at.y + sin(a) * r, 0.5))
			ring_c.append(E_GLINT.lerp(E_PUPIL, smoothstep(3.4, 4.3, r)))
		spot.append(ring)
		spot_c.append(ring_c)
	Pig._rings(g, spot, spot_c, n)
	# Into the eye's own frame (model space, life size).
	var zm := normal_to_model(n).normalized()
	var ym := normal_to_model(f[3]).normalized()
	var xm := ym.cross(zm).normalized()
	var basis := Basis(xm, zm.cross(xm).normalized(), zm)
	var origin := to_model(f[0]) / SF
	var inv := basis.inverse()
	for i in g.verts.size():
		g.verts[i] = inv * (to_model(g.verts[i]) / SF - origin)
		g.norms[i] = inv * normal_to_model(g.norms[i])
	return [g.commit(), Transform3D(basis, origin)]


## A stroke lying on the skin through the eye-frame points q = [o, u, half width] (sheet px).
func _stroke(g, f: Array, qs: Array, thick: float, lift: float) -> void:
	var line := []
	var widths := []
	for q in qs:
		line.append(_sdrop(f[0] + (f[2] * q[0] + f[3] * q[1]) * SK, f[1], lift))
		widths.append(Vector2(q[2], thick) * SK)
	g.loft(line, widths, f[1], 8)


## Lashes, brows, the line under the nose and the smile.
func _sheep_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _sheep_eye_frame(side)
		# Three short lashes at the outer upper corner, sweeping out and curling up; the top
		# one the longest.
		g.color = S_LASH
		for lash in [[4.0, 5.5, 0.25], [22.0, 6.5, 0.35], [40.0, 6.0, 0.45]]:
			var a := deg_to_rad(lash[0])
			var root := Vector2(cos(a) * E_R.x, sin(a) * E_R.y) * 0.98
			var out := Vector2(cos(a), sin(a))
			var curl := Vector2(0, 1)
			var qs := []
			for i in 6:
				var t := i / 5.0
				var p: Vector2 = root + out * lash[1] * t + curl * lash[1] * lash[2] * t * t
				qs.append([p.x, p.y, lerpf(2.0, 0.6, t)])
			_stroke(g, f, qs, 0.7, 0.5)
		# Eyebrow: a soft arc well above the eye, rising toward the nose, thickest in the middle.
		g.color = S_BROW
		_stroke(g, f, [[13.0, 32.0, 1.3], [9.0, 36.5, 2.1], [3.5, 39.3, 2.4], [-2.5, 40.3, 2.1], [-8.0, 39.5, 1.0]], 0.8, 0.3)
	# The line from the nose down to the smile, and the smile: two shallow arcs meeting under it.
	g.color = S_MOUTH
	var lines := [[[0.0, 333.0], [0.0, 338.0], [0.0, 343.0], [0.0, 348.0], [0.0, 351.0]]]
	for s in [-1.0, 1.0]:
		var arc := []
		for q in [[0.0, 351.0], [5.0, 353.0], [11.0, 354.0], [18.0, 352.5], [24.0, 349.0], [28.0, 345.0]]:
			arc.append([s * q[0], q[1]])
		lines.append(arc)
	for l in lines:
		var line := []
		var widths := []
		for i in l.size():
			var q: Array = l[i]
			var hit := _ray(_body, SP(700, q[1], q[0]), Vector3(1, 0, 0))
			line.append(hit[0] + hit[1] * 0.3 * SK)
			var taper := 1.0 if l.size() == 5 else lerpf(1.0, 0.6, smoothstep(0.6, 1.0, float(i) / (l.size() - 1)))
			widths.append(Vector2(0.85 * taper, 0.6) * SK)
		g.loft(line, widths, Vector3(-1, 0, 0), 6)
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / SF
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


# --- Meshing ------------------------------------------------------------------------------

## Meshes a small part `factor` times finer than the clay grid (the clay chick's method).
func _mesh_fine(prims: Array, crease_col: Color, crease_width: float, factor: float) -> ArrayMesh:
	var big := []
	for pr in prims:
		var q: Dictionary = pr.duplicate()
		for key in ["c", "r", "a", "b", "ra", "rb", "k"]:
			if q.has(key): q[key] = q[key] * factor
		big.append(q)
	var mesh := _mesh(big, crease_col, crease_width * factor)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var shift := Vector3(0, 0, X0 * S)
	for i in verts.size():
		verts[i] = (verts[i] + shift) / factor - shift
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Shrinks a clay mesh from its meshing size to life size; `warm` > 0 warms the colour toward
## the ground (the fleece's belly), as on the sheet.
func _fit_sheep(mesh: ArrayMesh, warm := 0.0) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	for i in verts.size():
		verts[i] /= SF
		if warm > 0.0:
			var w := smoothstep(0.62, 0.2, verts[i].y / SH) * warm
			cols[i] = cols[i].lerp(cols[i] * S_WOOL_LOW / S_WOOL, w)
			cols[i].a = 1.0
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _muzzle_tints, _hooves, _wool, _nose]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "SheepClayDisplay"
	root.set_meta("source", "User's Sheep Character Blueprint, relaxed idle (24 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, S_SKIN_CREASE, 2.0, 1.0], ["Wool", _wool, S_WOOL_CREASE, 2.2, 1.0],
			["Hooves", _hooves, S_HOOF_CREASE, 2.0, 1.0], ["Ears", _ears, S_EAR_CREASE, 2.0, 2.0],
			["Nose", _nose, S_NOSE_CREASE, 1.0, 3.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh_fine(part[1], part[2], part[3], part[4]) if part[4] > 1.0 else _mesh(part[1], part[2], part[3])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		mi.mesh = _fit_sheep(mi.mesh, 0.9 if part[0] == "Wool" else 0.0)
		mi.material_override = clay
		root.add_child(mi)
	var glossy := _material(0.25)
	glossy.metallic_specular = 0.35
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var built := _sheep_eye(side[1])
		var eye := MeshInstance3D.new()
		eye.name = side[0]
		eye.mesh = built[0]
		eye.transform = built[1]
		eye.material_override = glossy
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(eye)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _sheep_details()
	face.material_override = _material(0.7)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the fleece and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(SP(750, SY, -125)) / SF
	var c := to_model(SP(1115, STOP, 125)) / SF
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
