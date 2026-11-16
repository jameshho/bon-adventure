extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style gorilla traced from the user's "Gorilla Character Blueprint" turnaround (11 Nov
## 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for
## the zoo, built once by tools/build_gorilla_clay.gd into scenes/animals/gorilla_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd) and the clay giraffe's skin
## painting (giraffe_clay.gd: _tint, _hit, _paint). Shapes are written in the gorilla sheet's
## side-view pixels (x to the right = toward the rump, y down, z lateral, + = the side facing
## the viewer) and Q() scales them into the lion's working space, so the gorilla comes out
## GOR_H town units tall. The body is meshed FINE times finer than the lion's 3 cm clay (the
## face has small forms: brow ridges, nose, nostrils). The light face, chest, hands and feet,
## the dark eyebrows and the nostrils are painted on the finished skin with crisp edges; the
## eyes are glossy domes set into the face, the mouth a thin line laid on the muzzle.
## Output faces -Z (head), +Y up, ground at y = 0.

const GOR_H := 2.1               # town units: knuckle-walking height, between the lion and bear
const GOR_Y := 567.0             # sheet y of the soles and knuckles
const GOR_TOP := 124.0           # sheet y of the top of the crest
const GOR_X := 1010.0            # sheet x placed at the model origin
const M := GOR_H / ((GOR_Y - GOR_TOP) * S)   # sheet pixel -> lion working unit
const FINE := 1.3                # body mesh refinement (2.3 cm clay)
const FINE_SMALL := 2.0          # ears and crest

# Colours sampled from the sheet, then deepened and cooled so they read as the sheet's cool
# grey-mauve under the town's warm daylight (the first renders came out pale, pink and brown).
const FUR := Color("41363b")
const FUR_CREASE := Color("30282c")
const SKIN := Color("807071")
const SKIN_CREASE := Color("675758")
const CHEST := Color("726162")
const EAR_SKIN := Color("766566")
const EAR_INNER := Color("857375")
const BROW := Color("43373b")
const NOSTRIL_DARK := Color("1d100d")
const MOUTH_LINE := Color("5f4842")
const SCLERA_W := Color("f6e8dc")
const SCLERA_SHADE := Color("bfa297")
const IRIS_TOP := Color("3f1c05")
const IRIS_LOW := Color("8a4708")
const IRIS_RING := Color("2c1304")
const PUPIL_K := Color("050102")
const LID_DARK := Color("2a1711")
const LOWER_LID := Color("6f5f60")
const GLEAM := Color("ffffff")

# Eyes (sheet px, from the front view): centre height, lateral offset, opening radius, how far
# the dome stands out of the face, iris and pupil radii, and the catch-light.
const G_EYE_Y := 236.7
const G_EYE_Z := 31.0
const G_EYE_A := 15.5
const G_EYE_BULGE := 8.5
const G_IRIS_R := 12.8
const G_PUPIL_R := 8.8
const G_LID_IN := 4.0            # degrees inside the opening's rim where the lid line runs
const G_EYE_OUT := 26.0          # degrees the dome faces away from straight ahead
const G_GAZE_OUT := 5.0         # degrees the iris faces away from straight ahead (less: it
								 # sits toward the nose in the opening, as in the front view)

var _crest := []
var _limbs := []                 # [points, radii] of the arms and legs, for the fur repaint


## Sheet pixel -> working space (y up).
static func Q(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - GOR_X) * M, (GOR_Y - y) * M, z * M)


func ge(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * M, col, k * M, crease, basis)


func gc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * M, rb * M, col, k * M)


## Arm or leg: a chain of thick cones ending in a light hand or foot with creased knuckles or
## toes pointing forward (-x). `end` = [centre, radii] of the hand or foot.
func _gorilla_limb(pts: Array, radii: Array, end_c: Vector3, end_r: Vector3, lobes: int, lobe_r: Vector3, lobe_drop: float) -> void:
	var b := _body
	for i in pts.size() - 1:
		gc(b, pts[i], pts[i + 1], radii[i], radii[i + 1], FUR, 26.0 if i == 0 else 3.0)
	_limbs.append([pts, radii])
	ge(b, end_c, end_r, SKIN, 6.0, true)
	var spread := end_r.z * 2.0 / lobes
	for i in lobes:
		var z := (i - (lobes - 1) * 0.5) * spread
		ge(b, end_c + Vector3(-end_r.x * 0.78, -lobe_drop, z) * M, lobe_r, SKIN, 2.0, true)
	# Crisp light skin below the wrist or ankle, then a scalloped fur cuff over its top.
	_tint(end_c, (end_r + Vector3(14, 6, 6)) * M, Basis(), SKIN)
	var last: Vector3 = pts[pts.size() - 1]
	var r: float = radii[radii.size() - 1]
	var cuff_y := end_c.y + end_r.y * M * 0.75
	_tint(Vector3(last.x, cuff_y + 14.0 * M, last.z), Vector3(r + 4.0, 14.0, r + 4.0) * M, Basis(), FUR)
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(last.x + cos(a) * (r - 3.0) * M, cuff_y, last.z + sin(a) * (r - 3.0) * M)
		_tint(p, Vector3.ONE * 15.0 * M, Basis(), FUR)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: deep chest, the back sloping down from the neck to a round rump.
	ge(b, Q(990, 345), Vector3(105, 95, 100), FUR)
	ge(b, Q(1080, 380), Vector3(80, 85, 98), FUR, 30.0)
	ge(b, Q(1130, 405), Vector3(65, 80, 98), FUR, 30.0)
	for side in [-1.0, 1.0]:
		ge(b, Q(1150, 420, side * 46.0), Vector3(46, 62, 56), FUR, 8.0)   # buttocks
	# Neck: one slope from the back of the head to the shoulders.
	gc(b, Q(960, 225), Q(1050, 330), 56.0, 55.0, FUR, 30.0)
	# Head: wide round lower half, narrower tall dome.
	ge(b, Q(935, 255), Vector3(85, 80, 90), FUR, 12.0)
	ge(b, Q(932, 205), Vector3(68, 68, 60), FUR, 30.0)
	# Brow ridges: soft raised bars over the eyes, following the head round, outer ends lower.
	for side in [-1.0, 1.0]:
		ge(b, Q(873, 203, side * 31.0), Vector3(19, 12.0, 23), FUR, 15.0, false, Basis(Vector3.UP, side * 0.55) * Basis(Vector3.RIGHT, side * deg_to_rad(11.0)))
	# (The face and chest shapes are fur-coloured here; _paint_plan paints their skin crisply.)
	# Muzzle: a big round bulb, then the low nose on top of it.
	ge(b, Q(862, 297), Vector3(46, 38, 56), FUR, 6.0)
	ge(b, Q(845, 258), Vector3(17, 8.5, 25), FUR, 5.0)
	for side in [-1.0, 1.0]:
		carve(b, Q(829, 258.5, side * 13.0), Vector3(6.5, 4.5, 6.0) * M, FUR)
	# Chest and belly: two rounded pecs over a long pale underside.
	for side in [-1.0, 1.0]:
		ge(b, Q(905, 378, side * 27.0), Vector3(26, 38, 33), FUR, 8.0)
	ge(b, Q(1022, 430), Vector3(94, 40, 40), FUR, 10.0)

	# Arms: thick columns on the knuckles; far arm forward, near arm back.
	_gorilla_limb([Q(1008, 312, 104), Q(996, 400, 104), Q(986, 465, 95), Q(975, 512, 84)], [54.0, 61.0, 58.0, 50.0],
			Q(960, 542, 76), Vector3(44, 26, 50), 3, Vector3(20, 20, 18), 5.0)
	_gorilla_limb([Q(940, 318, -104), Q(905, 400, -104), Q(876, 468, -97), Q(868, 514, -86)], [54.0, 61.0, 57.0, 49.0],
			Q(862, 542, -78), Vector3(44, 26, 50), 3, Vector3(20, 20, 18), 5.0)
	# Legs: short and bent; near leg back, far leg forward. Flat feet with four toes.
	_gorilla_limb([Q(1135, 415, 52), Q(1146, 470, 52), Q(1152, 520, 52)], [62.0, 52.0, 47.0],
			Q(1152, 551, 52), Vector3(52, 17, 40), 4, Vector3(13, 11.5, 10.5), 4.0)
	_gorilla_limb([Q(1105, 420, -52), Q(1078, 472, -52), Q(1068, 520, -52)], [60.0, 50.0, 46.0],
			Q(1064, 551, -52), Vector3(48, 17, 40), 4, Vector3(13, 11.5, 10.5), 4.0)

	# Crest: a small tuft of rounded locks on top of the dome.
	ge(_crest, Q(931, 137), Vector3(24, 13, 14), FUR, 0.0, true)
	ge(_crest, Q(906, 145), Vector3(15, 12, 12), FUR, 3.0, true)
	for side in [-1.0, 1.0]:
		ge(_crest, Q(925, 142, side * 19.0), Vector3(22, 12, 13), FUR, 3.0, true)
		ge(_crest, Q(953, 143, side * 13.0), Vector3(17, 11.5, 13), FUR, 3.0, true)

	# Ears: round cups on the sides of the head, turned half forward, hollow in front.
	for side in [-1.0, 1.0]:
		var open := Vector3(-0.72, 0.0, side * 0.69).normalized()
		var along := Vector3.UP
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var c := Q(959, 236, side * 89.0)
		ge(_ears, c, Vector3(8.0, 16.0, 22.5), EAR_SKIN, 0.0, false, basis)
		carve(_ears, c + open * 7.0 * M, Vector3(5.5, 10.5, 16.0) * M, EAR_INNER, basis)

	_paint_plan()


## Painted areas, in order: chest, fur back over whatever the chest paint touched (arms, legs,
## jaw), then the face, eyebrows and nostrils. (Hands, feet and cuffs were queued by the limbs.)
func _paint_plan() -> void:
	var limb_tints := _tints.duplicate()
	_tints.clear()
	for side in [-1.0, 1.0]:
		_tint(Q(905, 378, side * 27.0), Vector3(29, 40, 35) * M, Basis(), CHEST)
	_tint(Q(1022, 430), Vector3(96, 42, 42) * M, Basis(), CHEST)
	for limb in _limbs:
		var pts: Array = limb[0]
		var radii: Array = limb[1]
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var rb: float = radii[i + 1]
			if i == pts.size() - 2:
				# Stop short of the hand or foot (the capsule's round end stays inside the limb).
				b = a.lerp(b, 0.3)
				rb = lerpf(radii[i], rb, 0.3)
			_cone_tint(a, b, (float(radii[i]) + 1.0) * M, (rb + 1.0) * M, FUR)
	_tint(Q(935, 255), Vector3(86, 81, 91) * M, Basis(), FUR)
	_tints.append_array(limb_tints)
	# Face: a round patch about each eye joined over the nose, and the whole muzzle.
	for side in [-1.0, 1.0]:
		_face_tint(220.5, side * 31.0, 33.5, 33.0, SKIN)
		_face_tint(262.0, side * 26.0, 14.0, 21.0, SKIN)
	_face_tint(229.0, 0.0, 29.0, 20.0, SKIN)
	_tint(Q(862, 297), Vector3(48, 40, 58) * M, Basis(), SKIN)
	# Eyebrows: dark arched beans on the ridges, [lateral, sheet y, radius].
	for side in [-1.0, 1.0]:
		var arc := [[54.0, 212.0, 4.2], [47.0, 205.0, 4.9], [38.0, 200.5, 5.2], [29.0, 200.0, 5.0], [21.5, 203.0, 4.4]]
		for i in arc.size() - 1:
			for j in 4:
				var t := j / 4.0
				_face_tint(lerpf(arc[i][1], arc[i + 1][1], t), side * lerpf(arc[i][0], arc[i + 1][0], t), lerpf(arc[i][2], arc[i + 1][2], t), lerpf(arc[i][2], arc[i + 1][2], t) * 1.15, BROW, 16.0)
		_face_tint(arc[4][1], side * arc[4][0], arc[4][2], arc[4][2] * 1.15, BROW, 16.0)
		# Nostrils: a round blob with a point running down toward the middle.
		_face_tint(257.5, side * 14.0, 4.4, 4.8, NOSTRIL_DARK, 14.0)
		_face_tint(260.5, side * 10.5, 2.8, 3.2, NOSTRIL_DARK, 14.0)


## Paints an ellipse as seen from the front (sheet y, lateral z; radii up and across).
func _face_tint(y: float, z: float, ry: float, rz: float, col: Color, rx := 34.0) -> void:
	_tint(_hit(Q(780, y, z), Vector3(1, 0, 0))[0], Vector3(rx, ry, rz) * M, Basis(), col)


## As the giraffe's, but the edge measure is the painted colour itself: fur is painted back
## over the whole head and limbs here, so "inside a crisp patch" is true on both sides of most
## edges and would never split a triangle.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var c := super(v, col, reach)
	_crisp = (c.r + c.g + c.b) * 2.5
	return c


## Paints everything inside a capsule (working space).
func _cone_tint(a: Vector3, b: Vector3, ra: float, rb: float, col: Color) -> void:
	var reach := a.distance_to(b) * 0.5 + maxf(ra, rb)
	_tints.append({"t": "cone", "a": a, "b": b, "ra": ra, "rb": rb, "c": (a + b) * 0.5, "r": Vector3.ONE * reach, "col": col, "soft": CELL * 0.35})


## Meshes a group `fine` times finer than the lion's clay: the shapes are enlarged about the
## model origin, meshed on the same grid, and the result is shrunk back.
func _mesh_fine(prims: Array, crease_col: Color, crease_width: float, fine: float) -> ArrayMesh:
	var o := Vector3(X0, 0, 0)
	var big := []
	for pr in prims:
		var d: Dictionary = pr.duplicate()
		d.k = float(pr.k) * fine
		if pr.t == "ell":
			d.c = o + (pr.c - o) * fine
			d.r = pr.r * fine
		else:
			d.a = o + (pr.a - o) * fine
			d.b = o + (pr.b - o) * fine
			d.ra = float(pr.ra) * fine
			d.rb = float(pr.rb) * fine
		big.append(d)
	var mesh := _mesh(big, crease_col, crease_width * fine)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= fine
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Face details -------------------------------------------------------------------------

## Eyes: glossy domes standing out of the face. Each is a cap of a sphere, gridded about the
## gaze axis so the pupil, the iris (dark rim, lighter toward the bottom) and the warm white are
## exact circles; the opening's own axis is turned further outward with the face, so the iris
## sits toward the nose in it. One round catch-light high on the nose side.
func _gorilla_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	var rs := (G_EYE_A * G_EYE_A + G_EYE_BULGE * G_EYE_BULGE) / (2.0 * G_EYE_BULGE)   # sphere radius, px
	var rim := asin(G_EYE_A / rs)
	var iris := asin(G_IRIS_R / rs)
	var pupil := asin(G_PUPIL_R / rs)
	var ring := deg_to_rad(4.5)
	var far := minf(rim + deg_to_rad(G_EYE_OUT - G_GAZE_OUT + 8.0), deg_to_rad(115.0))
	var segs := 64
	var lid_at := rim - deg_to_rad(G_LID_IN)
	for side in [-1.0, 1.0]:
		var ball := _eye_ball(side, rs)
		var centre: Vector3 = ball[0]
		var n: Vector3 = ball[1]
		var out: Vector3 = ball[2]
		var up := Vector3.UP
		var gt := deg_to_rad(G_GAZE_OUT)
		var gaze := Vector3(-cos(gt), -0.07, side * sin(gt)).normalized()
		var gx := up.cross(gaze).normalized()
		var gy := gaze.cross(gx).normalized()
		# Bands of the dome by angle from the gaze axis: [from, to, rings, kind].
		for band in [[0.0, pupil, 5, 0], [pupil, iris - ring, 7, 1], [iris - ring, iris, 2, 2], [iris, far, 14, 3]]:
			var rows: int = band[2]
			for i in rows:
				for j in segs:
					var quad := []
					for corner in [[0, 0], [1, 0], [1, 1], [0, 1]]:
						var phi: float = lerpf(band[0], band[1], float(i + corner[0]) / rows)
						var th: float = TAU * (j + corner[1]) / segs
						var qd := (gaze * cos(phi) + (gx * cos(th) + gy * sin(th)) * sin(phi)).normalized()
						# The dome ends exactly under the lid line: anything further round the
						# sphere is pulled back onto that circle (fix 11 Nov 2026: white showed
						# outside the lid at the upper nose side, where the face falls away).
						if qd.dot(n) < cos(lid_at):
							var flat := qd - n * qd.dot(n)
							qd = (n * cos(lid_at) + flat.normalized() * sin(lid_at)).normalized()
						quad.append(qd)
					for tri in [[0, 1, 2], [0, 2, 3]]:
						var d0: Vector3 = quad[tri[0]]
						var d1: Vector3 = quad[tri[1]]
						var d2: Vector3 = quad[tri[2]]
						if (d1 - d0).cross(d2 - d0).length() < 0.0000001: continue
						var order: Array = tri
						if (d1 - d0).cross(d2 - d0).dot(d0 + d1 + d2) > 0.0: order = [tri[0], tri[2], tri[1]]
						for q in order:
							var d: Vector3 = quad[q]
							g.verts.append(centre + d * rs * M)
							g.norms.append(d)
							g.cols.append(_eye_colour(band[3], d, gaze, n, up, rim, iris))
		# Catch-light: toward the nose and up from the pupil's centre, lying on the dome.
		var hd := (gaze * rs - out * 2.4 + up * 6.2).normalized()
		var hx := up.cross(hd).normalized()
		g.color = GLEAM
		g.ellipsoid(centre + hd * (rs + 0.1) * M, Vector3(2.3, 0.45, 2.3) * M, Basis(hx, hd, hx.cross(hd)), 18, 8)
	return _to_model(g)


## An eye's sphere: [centre, the opening's axis, the direction toward its outer corner].
func _eye_ball(side: float, rs: float) -> Array:
	var skin: Vector3 = _hit(Q(780, G_EYE_Y, side * G_EYE_Z), Vector3(1, 0, 0))[0]
	var t := deg_to_rad(G_EYE_OUT)
	var n := Vector3(-cos(t), 0, side * sin(t))
	return [skin - n * (rs - G_EYE_BULGE + 0.8) * M, n, Vector3(sin(t), 0, side * cos(t))]


## Colour of the point of an eye in direction d from the eye's centre; kind: 0 pupil, 1 iris,
## 2 the iris's dark rim, 3 white (shaded toward the opening's rim, n = the opening's axis).
func _eye_colour(kind: int, d: Vector3, gaze: Vector3, n: Vector3, up: Vector3, rim: float, iris: float) -> Color:
	if kind == 0: return PUPIL_K
	if kind == 2: return IRIS_RING
	if kind == 3:
		var rho := sin(acos(clampf(d.dot(n), -1.0, 1.0))) / sin(rim) if d.dot(n) > 0.0 else 2.0
		return SCLERA_W.lerp(SCLERA_SHADE, smoothstep(0.8, 1.0, rho))
	var low := clampf(0.5 - (d - gaze).dot(up) / sin(iris) * 0.6, 0.0, 1.0)
	var ang := acos(clampf(d.dot(gaze), -1.0, 1.0))
	return IRIS_TOP.lerp(IRIS_LOW, low * low).lerp(IRIS_RING, 0.5 * smoothstep(iris - deg_to_rad(10.0), iris - deg_to_rad(4.5), ang))


## The smile: a thin dark line round the muzzle, turned up at the ends. Eyelids: a thick dark
## line along the upper rim of each eye and a fine soft crease along the lower (matte, so they
## are here and not in the glossy eye mesh).
func _gorilla_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	var curve := []
	var widths := []
	for i in 25:
		var t := (i - 12) / 12.0 * 1.07
		var h := _hit(Q(780, 300.5 - 17.7 * pow(absf(t), 2.2), t * 42.0), Vector3(1, 0, 0))
		curve.append(h[0] + h[1] * 0.1 * M)
		var w := (1.0 - 0.6 * pow(absf(t) / 1.07, 3.0)) * M
		widths.append(Vector2(w, w * 0.8))
	g.color = MOUTH_LINE
	g.loft(curve, widths, Vector3.UP, 6)
	var rs := (G_EYE_A * G_EYE_A + G_EYE_BULGE * G_EYE_BULGE) / (2.0 * G_EYE_BULGE)
	var rim := asin(G_EYE_A / rs)
	for side in [-1.0, 1.0]:
		var ball := _eye_ball(side, rs)
		var centre: Vector3 = ball[0]
		var n: Vector3 = ball[1]
		var out: Vector3 = ball[2]
		var up := Vector3.UP
		# Lid line: thick and dark over the top, a fine crease below.
		var lid_at := rim - deg_to_rad(G_LID_IN)
		for arc in [[-8.0, 188.0, 30, LID_DARK], [188.0, 352.0, 22, LOWER_LID]]:
			var lid_pts := []
			var lid_w := []
			for i in int(arc[2]) + 1:
				var th: float = deg_to_rad(lerpf(arc[0], arc[1], float(i) / float(arc[2])))
				var d := (n * cos(lid_at) + (out * cos(th) + up * sin(th)) * sin(lid_at)).normalized()
				lid_pts.append(centre + d * (rs + 0.15) * M)
				var w := (0.4 + 1.3 * smoothstep(0.0, 0.7, sin(th))) * M
				lid_w.append(Vector2(w, w * 0.55))
			g.color = arc[3]
			g.loft(lid_pts, lid_w, n, 8)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	_body.clear(); _crest.clear(); _ears.clear(); _tints.clear(); _limbs.clear()
	_shape()
	var root := Node3D.new()
	root.name = "GorillaClayDisplay"
	root.set_meta("source", "User's Gorilla Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.84)
	for part in [["Body", _body, SKIN_CREASE, 7.0, FINE], ["Crest", _crest, FUR_CREASE, 6.0, FINE_SMALL], ["Ears", _ears, SKIN_CREASE, 7.0, FINE_SMALL]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh_fine(part[1], part[2], part[3], part[4])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _gorilla_eyes()
	eyes.material_override = _material(0.16)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _gorilla_details()
	face.material_override = _material(0.8)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the whole animal (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(Q(816, GOR_Y, -158))
	var c := to_model(Q(1206, GOR_TOP, 158))
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
