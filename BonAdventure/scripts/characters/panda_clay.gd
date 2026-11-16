extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style panda traced from the user's "Panda Character Blueprint" turnaround (11 Nov 2026,
## "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for the
## zoo, built once by tools/build_panda_clay.gd into scenes/animals/panda_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd) and the clay giraffe's skin
## painting (giraffe_clay.gd: _paint, _mid, _to_model). Shapes are written in the panda sheet's
## pixels (side view: x to the right = toward the tail, y down; z lateral, taken from the front
## view) and Q() scales them into the lion's working space. The head is its own mesh, as on the
## sheet, where it sits in front of the body as a separate ball. Everything is modelled cream;
## the dark legs, shoulder band and eye patches and the pink cheeks are painted on the finished
## skin. Eyes, nose and mouth are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const PH := 1.6                  # town units to the top of the ears
const PY := 535.0                # sheet y of the soles
const PTOP := 212.0              # sheet y of the top of the ears
const PX := 1010.0               # sheet x placed at the model origin
const PK := PH / ((PY - PTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet's lit areas, a little deeper for the town's daylight.
const P_CREAM := Color("ead8bd")
const P_CREASE := Color("b09a80")
const P_DARK := Color("4a3d36")
const P_EAR_IN := Color("dd8f7c")
const P_BLUSH := Color("f6ab99")
const P_NOSE := Color("3b281b")
const P_MOUTH := Color("6b4a34")
const P_SCLERA := Color("f1e8dc")
const P_IRIS_RIM := Color("241003")
const P_IRIS := Color("3f2008")
const P_PUPIL := Color("1c0b02")
const P_GLINT := Color("fffaf2")
const P_LID := Color("33261f")

# Eyes, from the front view (sheet px): centre height and lateral offset; outline radii and bulge.
const P_EYE_AT := Vector2(332.5, 51.0)
const P_EYE_R := Vector3(15.5, 16.5, 6.0)

var _head := []
var _head_tints := []
var _body_tints := []
var _ear_tints := []


## Sheet pixel -> working space (y up).
static func Q(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - PX) * PK, (PY - y) * PK, z * PK)


func pe(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * PK, col, k * PK, crease, basis)


## A leg that will be painted dark: tapered segments through `joints` down to a round paw with
## three toes at the front; the same shapes, slightly grown, are recorded as paint.
func _pleg(joints: Array, radii: Array, paw: Vector3) -> void:
	var grow := 3.0 * PK
	for i in joints.size() - 1:
		cone(_body, joints[i], joints[i + 1], radii[i] * PK, radii[i + 1] * PK, P_CREAM, (14.0 if i == 0 else 4.0) * PK)
		_dark_cone(joints[i], joints[i + 1], radii[i] * PK + grow, radii[i + 1] * PK + grow)
	var last: float = radii[radii.size() - 1] * PK
	var ankle := paw + Vector3(0, 4, 0) * PK
	cone(_body, joints[joints.size() - 1], ankle, last, last, P_CREAM, 4.0 * PK)
	_dark_cone(joints[joints.size() - 1], ankle, last + grow, last + grow)
	pe(_body, paw, Vector3(41, 17, 41), P_CREAM, 6.0, true)
	_dark_ell(paw, Vector3(41, 17, 41) * PK + Vector3.ONE * grow)
	for t in [-1.0, 0.0, 1.0]:
		var toe := paw + Vector3(-29.0, -2.0, t * 24.0) * PK
		pe(_body, toe, Vector3(15, 14, 13.5), P_CREAM, 2.0, true)
		_dark_ell(toe, Vector3(15, 14, 13.5) * PK + Vector3.ONE * grow)


func _dark_cone(a: Vector3, b: Vector3, ra: float, rb: float) -> void:
	var reach := a.distance_to(b) * 0.5 + maxf(ra, rb)
	_body_tints.append({"t": "cone", "a": a, "b": b, "ra": ra, "rb": rb, "c": (a + b) * 0.5,
		"r": Vector3.ONE * reach, "col": P_DARK, "soft": CELL * 0.35, "shade": true})


func _dark_ell(c: Vector3, r: Vector3) -> void:
	_body_tints.append({"t": "ell", "c": c, "r": r, "inv": Basis(), "col": P_DARK, "soft": CELL * 0.35, "shade": true})


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: a round barrel, highest at the shoulders, sloping down to a full rump.
	pe(b, Q(1015, 392), Vector3(75, 84, 98), P_CREAM)
	pe(b, Q(1100, 400), Vector3(85, 72, 96), P_CREAM, 30.0)
	pe(b, Q(1135, 420), Vector3(52, 68, 90), P_CREAM, 30.0)
	# Tail: a short upright oval on the rump, no further back than the thighs.
	pe(b, Q(1181, 408), Vector3(15, 27, 22), P_CREAM, 6.0)
	# Legs, relaxed walk: thick columns. Near front planted, far front stepping forward, near
	# hind trailing, far hind under the belly.
	_pleg([Q(1008, 400, 58), Q(1008, 500, 58)], [44.0, 40.0], Q(1003, 518, 58))
	_pleg([Q(1000, 405, -58), Q(940, 462, -58), Q(893, 503, -58)], [44.0, 41.0, 38.0], Q(868, 518, -58))
	_pleg([Q(1152, 450, 56), Q(1166, 503, 56)], [48.0, 40.0], Q(1168, 518, 56))
	_pleg([Q(1140, 450, -56), Q(1092, 500, -56)], [48.0, 40.0], Q(1078, 518, -56))
	# Thighs: painted as the side view's round patches cut straight across the body from the
	# leg's inner side outward, so their edges are clean on the flank and across the rump
	# instead of fading where the thigh merges into the body.
	for thigh in [[1152.0, 1.0], [1140.0, -1.0]]:
		_body_tints.append({"t": "thigh", "c": Q(thigh[0], 452), "rad": 50.0 * PK, "side": thigh[1], "zmin": 22.0 * PK,
			"r": Vector3.ONE * 130.0 * PK, "col": P_DARK, "soft": CELL * 0.35, "shade": true})
	# Shoulder band: everything in front of a plane leaning forward over the shoulders, down
	# to the top of the pale chest patch between the front legs.
	var edge := Q(1058, 390) - Q(1032, 303)
	_body_tints.append({"t": "band", "c": Q(1032, 303), "n": Vector3(-edge.y, edge.x, 0).normalized(),
		"xmax": Q(1054, 0).x, "ymin": Q(0, 452).y, "r": Vector3.ONE * 260.0 * PK,
		"col": P_DARK, "soft": CELL * 0.35, "shade": true})

	# Head: a big, slightly wide ball; full cheeks low on the face and a short muzzle bump.
	var h := _head
	pe(h, Q(897, 322), Vector3(97, 89, 106), P_CREAM)
	for side in [-1.0, 1.0]:
		pe(h, Q(890, 360, side * 50.0), Vector3(82, 66, 66), P_CREAM, 30.0)
	pe(h, Q(880, 372), Vector3(80, 58, 80), P_CREAM, 30.0)
	pe(h, Q(801, 373), Vector3(30, 28, 38), P_CREAM, 18.0)

	# Ears: thick round discs facing forward and 40 degrees outward, lower edge sunk into the
	# head; a hollow in the front, painted pink (the rim hides most of it from the side).
	for side in [-1.0, 1.0]:
		var n := Vector3(-cos(deg_to_rad(40.0)), 0, side * sin(deg_to_rad(40.0)))
		var basis := Basis(n, Vector3.UP, n.cross(Vector3.UP).normalized())
		var c := Q(905, 256, side * 82.0)
		pe(_ears, c, Vector3(20, 41, 41), P_DARK, 0.0, false, basis)
		var inward := basis.z * (-1.0 if basis.z.z * side > 0.0 else 1.0)
		var hollow := c + (n * 22.0 + Vector3(0, -8.0, 0) + inward * 9.0) * PK
		carve(_ears, hollow, Vector3(11, 24, 21) * PK, P_DARK, basis)
		_ear_tints.append({"t": "ell", "c": hollow, "r": Vector3(13, 25.5, 22.5) * PK, "inv": basis.inverse(), "col": P_EAR_IN, "soft": CELL * 0.35})

	# Painted on the head: eye patches (tilted ovals, inner end up, as seen from the front)
	# and soft pink cheeks.
	for side in [-1.0, 1.0]:
		var at := _hit_on(_head, Q(700, 327, side * 62.0), Vector3(1, 0, 0))
		var a := deg_to_rad(48.0)
		var long := Vector3(0, sin(a), -side * cos(a))
		var across := Vector3(0, cos(a), side * sin(a))
		var frame := Basis(Vector3(1, 0, 0), long, across)
		_head_tints.append({"t": "ell", "c": at[0], "r": Vector3(55, 40, 28) * PK, "inv": frame.inverse(), "col": P_DARK, "soft": CELL * 0.35})
		var cheek := _hit_on(_head, Q(700, 376, side * 81.0), Vector3(1, 0, 0))
		_head_tints.append({"t": "ell", "c": cheek[0], "r": Vector3.ONE * 15.0 * PK, "inv": Basis(), "col": P_BLUSH, "soft": 16.0 * PK})


## First point of a group's skin along a ray (working space): [point, outward normal].
func _hit_on(group: Array, from: Vector3, dir: Vector3) -> Array:
	var p := from
	var d := dir.normalized()
	for i in 1500:
		var f := _field(group, p)
		if f <= 0.0: break
		p += d * maxf(f * 0.5, 0.15)
	var h := 0.5
	var n := Vector3(
		_field(group, p + Vector3(h, 0, 0)) - _field(group, p - Vector3(h, 0, 0)),
		_field(group, p + Vector3(0, h, 0)) - _field(group, p - Vector3(0, h, 0)),
		_field(group, p + Vector3(0, 0, h)) - _field(group, p - Vector3(0, 0, h))).normalized()
	return [p, n]


## Colour of the skin at model-space point v (called by the giraffe's _paint and _mid). Adds the
## band and thigh shapes and, for the dark paint, keeps the toe creases' shading underneath.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	var shade := clampf(col.r / P_CREAM.r, 0.0, 1.0)
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 0.0
		if t.t == "band":
			var n: Vector3 = t.n
			var c0: Vector3 = t.c
			var xmax: float = t.xmax
			var ymin: float = t.ymin
			d = maxf((p - c0).dot(n), maxf(p.x - xmax, ymin - p.y))
		elif t.t == "thigh":
			var c1: Vector3 = t.c
			var rad: float = t.rad
			var side: float = t.side
			var zmin: float = t.zmin
			d = maxf(Vector2(p.x - c1.x, p.y - c1.y).length() - rad, zmin - side * p.z)
		else:
			d = _dist(t, p)
		var soft: float = t.soft
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			if t.get("shade", false): tc = tc * shade
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


# --- Face details -------------------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _panda_eye_frame(side: float) -> Array:
	var hit := _hit_on(_head, Q(700, P_EYE_AT.x, side * P_EYE_AT.y), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## A thin coloured layer following the eye's dome: an ellipse (centre c2, radii r2, in sheet px
## across the eye) raised `lift` above the dome so layers stack without dipping into each other.
func _decal(g, s: Vector3, frame: Basis, c2: Vector2, r2: Vector2, lift: float, col: Color) -> void:
	g.color = col
	var rings := 8
	var segs := 36
	var pts := []
	var nrm := []
	for i in rings + 1:
		var row := []
		var nrow := []
		for j in segs:
			var a := TAU * j / segs
			var q := c2 + Vector2(cos(a) * r2.x, sin(a) * r2.y) * (float(i) / rings)
			var inside := maxf(1.0 - pow(q.x / P_EYE_R.x, 2.0) - pow(q.y / P_EYE_R.y, 2.0), 0.0)
			var hgt := P_EYE_R.z * sqrt(inside)
			row.append(s + (frame.x * q.x + frame.y * q.y + frame.z * (hgt + lift)) * PK)
			nrow.append((frame * Vector3(q.x / pow(P_EYE_R.x, 2.0), q.y / pow(P_EYE_R.y, 2.0), maxf(hgt, 0.6) / pow(P_EYE_R.z, 2.0))).normalized())
		pts.append(row)
		nrm.append(nrow)
	for i in rings:
		for j in segs:
			var k := (j + 1) % segs
			for tri in [[pts[i][j], pts[i + 1][j], pts[i + 1][k], nrm[i][j], nrm[i + 1][j], nrm[i + 1][k]],
					[pts[i][j], pts[i + 1][k], pts[i][k], nrm[i][j], nrm[i + 1][k], nrm[i][k]]]:
				var a: Vector3 = tri[0]
				var b: Vector3 = tri[1]
				var c: Vector3 = tri[2]
				if (b - a).cross(c - a).dot(frame.z) < 0.0:
					g.tri(a, b, c, tri[3], tri[4], tri[5])
				else:
					g.tri(a, c, b, tri[3], tri[5], tri[4])


## Eyes: round glossy beads set into the patches. A warm-white dome with a dark rim round it;
## a large brown iris (darker at its edge) sitting toward the nose so white shows only as a
## crescent on the outer side; a near-black pupil; one small catch-light high on the inner side.
## The dark rim and lid line are matte and belong to _panda_details().
func _panda_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _panda_eye_frame(side)
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		var s: Vector3 = f[0] - n * 1.6 * PK
		g.color = P_SCLERA
		g.ellipsoid(s, P_EYE_R * PK, frame, 36, 18)
		_decal(g, s, frame, Vector2(-2.1, 0.0), Vector2(13.2, 15.7), 0.2, P_IRIS_RIM)
		_decal(g, s, frame, Vector2(-2.1, -0.4), Vector2(10.9, 13.0), 0.35, P_IRIS)
		_decal(g, s, frame, Vector2(-2.0, -0.8), Vector2(5.6, 6.3), 0.5, P_PUPIL)
		_decal(g, s, frame, Vector2(-5.4, 6.0), Vector2(2.3, 2.3), 0.65, P_GLINT)
	return _to_model(g)


## Nose (a rounded, flat-topped triangle standing off the muzzle), the line under it and the
## mouth: two shallow arcs meeting in a small peak under the nose.
func _panda_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	# Eye rims and upper lids (matte, so they do not catch the sky like the glossy eyes do):
	# a dark rim just outside the eye and a heavier line over its top, thickest in the middle.
	g.color = P_LID
	for side in [-1.0, 1.0]:
		var f := _panda_eye_frame(side)
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var s: Vector3 = f[0] - n * 1.6 * PK
		g.ellipsoid(s, Vector3(P_EYE_R.x + 1.5, P_EYE_R.y + 1.5, P_EYE_R.z - 1.6) * PK, Basis(out, up, n), 36, 14)
		var lid := []
		var lid_w := []
		for i in 13:
			var a := deg_to_rad(lerpf(12.0, 168.0, i / 12.0))
			var w := (0.7 + 1.5 * sin(PI * i / 12.0)) * PK
			lid.append(s + (out * cos(a) * (P_EYE_R.x + 0.4) + up * sin(a) * (P_EYE_R.y + 0.4) + n * 1.4) * PK)
			lid_w.append(Vector2(w, w))
		g.loft(lid, lid_w, n, 8)
	# Nose: one smooth rounded triangle, wide and flatter on top, narrowing to a blunt point.
	var at := _hit_on(_head, Q(700, 357, 0), Vector3(1, 0, 0))
	var tip: Vector3 = at[0] + Vector3(2.0, 0, 0) * PK
	g.color = P_NOSE
	var rows := 18
	var segs := 32
	var grid := []
	var ngrid := []
	for i in rows + 1:
		var phi := PI * i / rows
		var row := []
		var nrow := []
		for j in segs:
			var th := TAU * j / segs
			var u := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var wide := lerpf(0.42, 1.0, smoothstep(-1.0, 0.55, u.y))
			var r := Vector3(12.0, 8.5 if u.y > 0.0 else 13.5, 20.0 * wide)
			row.append(tip + u * r * PK)
			nrow.append((u / r).normalized())
		grid.append(row)
		ngrid.append(nrow)
	for i in rows:
		for j in segs:
			var k := (j + 1) % segs
			if i > 0: g.tri(grid[i][j], grid[i + 1][j], grid[i][k], ngrid[i][j], ngrid[i + 1][j], ngrid[i][k])
			if i < rows - 1: g.tri(grid[i][k], grid[i + 1][j], grid[i + 1][k], ngrid[i][k], ngrid[i + 1][j], ngrid[i + 1][k])
	g.color = P_MOUTH
	var line := []
	var line_w := []
	for i in 6:
		var y := lerpf(370.0, 387.0, i / 5.0)
		var hit := _hit_on(_head, Q(700, y, 0), Vector3(1, 0, 0))
		line.append(hit[0] + hit[1] * 0.2 * PK)
		line_w.append(Vector2(1.0, 1.0) * PK)
	g.loft(line, line_w, Vector3(0, 0, 1), 6)
	for side in [-1.0, 1.0]:
		var curve := []
		var widths := []
		for i in 9:
			var t := i / 8.0
			var y := 386.5 + 5.0 * sin(PI * 0.65 * t)
			var hit := _hit_on(_head, Q(700, y, side * t * 20.0), Vector3(1, 0, 0))
			curve.append(hit[0] + hit[1] * 0.2 * PK)
			var w := (1.4 - 0.7 * t) * PK
			widths.append(Vector2(w, w))
		g.loft(curve, widths, Vector3.UP, 6)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	_body.clear(); _head.clear(); _ears.clear(); _body_tints.clear(); _head_tints.clear(); _ear_tints.clear()
	_shape()
	var root := Node3D.new()
	root.name = "PandaClayDisplay"
	root.set_meta("source", "User's Panda Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.95)
	clay.metallic_specular = 0.15   # matte, velvety: no sheen on the dark fur
	for part in [["Body", _body, _body_tints], ["Head", _head, _head_tints], ["Ears", _ears, _ear_tints]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], P_CREASE, 7.0)
		if not (part[2] as Array).is_empty():
			_tints = part[2]
			mi.mesh = _paint(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _panda_eyes()
	eyes.material_override = _material(0.3)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _panda_details()
	face.material_override = _material(0.6)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(Q(772, PY, -104))
	var c := to_model(Q(1234, PTOP, 104))
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
