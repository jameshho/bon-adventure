extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style cow traced from the user's "Cow Character Blueprint" turnaround (11 Nov 2026,
## "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for the
## zoo, built once by tools/build_cow_clay.gd into scenes/animals/cow_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd) and the clay giraffe's skin
## painting (giraffe_clay.gd: _tint, _paint). Shapes are written in the cow sheet's side-view
## pixels (x to the right = toward the tail, y down, z lateral) and W() scales them into the
## lion's working space. The cow is small (1.55 town units), so it is meshed FINE times larger
## than life and shrunk afterwards (_fit): the clay grid is 3 cm / FINE on the finished model.
## The muzzle, horns, ears, hooves, udder and tail tuft are separate clay pieces, as on the
## sheet; the brown patches, the blush and the pink insides of the ears and nostrils are painted on the skin; eyes, lids and brows are
## small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const CH := 1.55                # town units, the zoo cow's display height (park_animals.gd)
const CY := 555.0               # sheet y of the hooves' soles
const CTOP := 146.0             # sheet y of the horn tips
const CX := 1005.0              # sheet x placed at the model origin
const FINE := 2.0               # meshed this many times larger than life
const CK := FINE * CH / ((CY - CTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet, then deepened: the sheet's lit cream burns out to white
# under the town's daylight (first render, 11 Nov 2026), and deepened again after the first zoo
# view, where the warm sun turned the brown light and orange.
const C_CREAM := Color("e6c6a6")
const C_BROWN := Color("56392a")
const C_MUZZLE := Color("e88a72")
const C_MOUTH := Color("bd6048")
const C_NOSTRIL := Color("8a3a24")
const C_BLUSH := Color("ee9080")
const C_HORN := Color("dab07c")
const C_EAR_IN := Color("e08878")
const C_HOOF := Color("4c3222")
const C_HOOF_CREASE := Color("382317")
const C_UDDER := Color("e58870")
const C_UDDER_CREASE := Color("cf7058")
const C_TUFT := Color("4e3324")
const C_TUFT_CREASE := Color("3b261a")
const C_SCLERA := Color("f6eee2")
const C_IRIS := Color("4a2812")
const C_PUPIL := Color("150a06")
const C_GLINT := Color("fffdf8")
const C_LID := Color("3a2215")
const C_CREASE := Color("5a3d2e")

# Eyes (sheet px): centre as seen from the front, and half-sizes measured face-on in the
# front 3/4 view (34 wide, 39 tall), a little wider because the eyes sit on the head's front
# corners and the front and side views each show them almost full width.
const C_EYE_Y := 256.5
const C_EYE_Z := 40.5
const C_EYE_R := Vector2(18.5, 20.2)

var _muzzle := []
var _horns := []
var _hooves := []
var _udder := []
var _ear_tints := []
var _muzzle_tints := []


## Sheet pixel -> working space (y up).
static func W(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - CX) * CK, (CY - y) * CK, z * CK)


func ce(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * CK, col, k * CK, crease, basis)


func cc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * CK, rb * CK, col, k * CK)


func tube(g: Array, pts: Array, radii: Array, col: Color, k: float, k_rest := 3.0) -> void:
	for i in pts.size() - 1:
		cc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else k_rest)


# --- Shape --------------------------------------------------------------------------------

## Legs as [sheet x, lateral z]: a slight walking stagger, as in the sheet's side view.
const C_LEGS := [[918.0, 47.0], [884.0, -47.0], [1132.0, 50.0], [1092.0, -50.0]]

func _shape() -> void:
	var b := _body
	# Torso: a deep, round barrel, as tall as it is wide.
	ce(b, W(925, 366), Vector3(80, 92, 92), C_CREAM)
	ce(b, W(1005, 364), Vector3(108, 91, 97), C_CREAM, 20.0)
	ce(b, W(1086, 367), Vector3(82, 93, 99), C_CREAM, 20.0)
	# Neck: short and thick, straight into the back of the head.
	cc(b, W(868, 272), W(925, 335), 56.0, 70.0, C_CREAM, 24.0)
	# Head: broad face (flatter across the front than a ball, so the eyes sit on its front
	# corners), round skull behind it, wide cheeks and a soft jaw under the muzzle.
	ce(b, W(838, 258), Vector3(65, 73, 66), C_CREAM, 14.0)
	ce(b, W(864, 248), Vector3(55, 65, 63), C_CREAM, 20.0)
	for side in [-1.0, 1.0]:
		ce(b, W(818, 301, side * 36.0), Vector3(39, 35, 41), C_CREAM, 16.0)
	ce(b, W(802, 322), Vector3(36, 25, 44), C_CREAM, 14.0)
	# Legs: thick straight columns.
	for leg in C_LEGS:
		cc(b, W(leg[0], 400, leg[1] * 0.92), W(leg[0], 532, leg[1]), 33.0, 28.0, C_CREAM, 14.0)
	# Tail: hangs close down the rump.
	tube(b, [W(1152, 302), W(1173, 322), W(1185, 378), W(1187, 432)], [10.0, 8.0, 7.5, 7.0], C_CREAM, 10.0)

	# Muzzle: one wide pink piece pressed on the face; the lower lip under it leaves the
	# mouth line as a crease. Nostrils are pressed in. (A rounder muzzle with a drawn mouth
	# line was tried and reverted the same day, user 11 Nov 2026.)
	var m := _muzzle
	ce(m, W(768, 298.5), Vector3(34, 32.5, 54), C_MUZZLE, 0.0, true)
	for side in [-1.0, 1.0]:
		ce(m, W(772, 298, side * 27.0), Vector3(26, 21, 24), C_MUZZLE, 8.0)   # broad, flat-topped
	ce(m, W(779, 326), Vector3(24, 17, 37), C_MUZZLE, 3.0, true)
	for side in [-1.0, 1.0]:
		var slant := Basis(Vector3(1, 0, 0), side * 0.45)
		var hole := Vector3(8.0, 6.3, 8.8)
		var at: Vector3 = _ray(m, W(690, 292.5, side * 24.0), Vector3(1, 0, 0))[0]
		carve(m, at, hole * CK, C_MUZZLE, slant)
		_muzzle_tints.append({"t": "ell", "c": at, "r": (hole + Vector3.ONE * 1.2) * CK, "inv": slant.inverse(), "col": C_NOSTRIL, "soft": CELL * 0.7})

	# Horns: pale crescents out of the top corners of the head, up and round to the tips.
	for side in [-1.0, 1.0]:
		tube(_horns, [W(880, 210, side * 40.0), W(886, 193, side * 60.0), W(895, 177, side * 70.0),
				W(896, 163, side * 69.0), W(891, 152.5, side * 62.0)], [14.0, 14.0, 13.0, 10.5, 6.5], C_HORN, 0.0, 12.0)

	# Ears: long leaf-shaped cups out to the sides and a little back, widest near the head and
	# drawn out to a point; brown with a rim round a pink hollow that faces forward and outward.
	for side in [-1.0, 1.0]:
		var along := Vector3(0.42, 0.04, side * 0.9).normalized()
		var open := Vector3(-1.0, -0.12, side * 0.2)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var c := W(900, 231, side * 92.0)
		var tip := c + along * 25.0 * CK
		ce(_ears, c, Vector3(7.5, 22.0, 34.0), C_BROWN, 0.0, false, basis)
		ce(_ears, tip, Vector3(5.0, 11.0, 23.0), C_BROWN, 8.0, false, basis)
		# The hollow is cut in brown and painted pink afterwards, so the rim keeps a crisp edge.
		var hollow := c + open * 7.5 * CK + along * 2.0 * CK
		var parts := []
		for h in [[hollow, Vector3(6.0, 15.0, 26.0)], [tip + open * 6.0 * CK - along * 2.0 * CK, Vector3(5.0, 6.0, 17.0)]]:
			carve(_ears, h[0], h[1] * CK, C_BROWN, basis)
			parts.append({"t": "ell", "c": h[0], "r": (h[1] + Vector3(1.5, 1.0, 1.0)) * CK, "inv": basis.inverse()})
		_ear_tints.append({"t": "blob", "c": hollow, "r": Vector3.ONE * 60.0 * CK, "parts": parts, "k": 5.0 * CK, "col": C_EAR_IN, "soft": CELL * 0.35})

	# Hooves: brown caps a little wider than the legs, two toes to the front, flat soles.
	for leg in C_LEGS:
		cc(_hooves, W(leg[0] - 2.0, 539, leg[1]), W(leg[0] - 2.0, 562, leg[1]), 31.0, 31.0, C_HOOF)
		for t in [-1.0, 1.0]:
			ce(_hooves, W(leg[0] - 14.0, 546, leg[1] + t * 10.0), Vector3(21, 14, 15), C_HOOF, 5.0, true)
	for leg in C_LEGS:
		carve(_hooves, W(leg[0], CY + 40.0, leg[1]), Vector3(120, 40, 120) * CK, C_HOOF)

	# Udder with four teats.
	ce(_udder, W(1057, 442), Vector3(38, 28, 36), C_UDDER)
	for x in [1038.0, 1077.0]:
		for side in [-1.0, 1.0]:
			cc(_udder, W(x, 462, side * 15.0), W(x, 482, side * 15.0), 7.0, 5.5, C_UDDER, 5.0)

	# Tail tuft: a brown teardrop.
	cc(_tuft, W(1187, 428), W(1187, 446), 8.0, 13.0, C_TUFT, 0.0)
	ce(_tuft, W(1187, 463), Vector3(19, 29, 17), C_TUFT, 5.0, true)
	for side in [-1.0, 1.0]:
		ce(_tuft, W(1187, 470, side * 6.0), Vector3(13, 20, 10), C_TUFT, 2.0, true)
	cc(_tuft, W(1188, 478), W(1191, 497), 11.0, 3.0, C_TUFT, 6.0)

	_patches()


## Painted areas, in order: blush, then the brown patches, then the cream round the tail.
func _patches() -> void:
	for side in [-1.0, 1.0]:
		_tint(W(798, 296, side * 64.0), Vector3(16, 14, 16) * CK, Basis(), C_BLUSH, CELL * 3.0)
		# Side of the head: from under the horn, round behind the eye, down to the cheek.
		_blob([[W(860, 236, side * 72.0), Vector3(54, 40, 34)], [W(848, 268, side * 74.0), Vector3(35, 27, 30)]], C_BROWN, 14.0)
		# Flank: a rounded patch with two lobes underneath.
		_blob([[W(962, 365, side * 100.0), Vector3(40, 38, 45)], [W(945, 400, side * 100.0), Vector3(24, 22, 45)],
				[W(985, 396, side * 100.0), Vector3(20, 20, 45)]], C_BROWN, 8.0)
	# Saddle: over the back and down both sides, round the rump.
	_blob([[W(1050, 285), Vector3(78, 48, 130)], [W(1078, 335), Vector3(45, 36, 130)], [W(1140, 325), Vector3(45, 55, 130)]], C_BROWN, 10.0)
	_tint(W(1182, 350), Vector3(50, 72, 40) * CK, Basis(), C_CREAM, CELL * 0.35)


## A painted patch made of ellipsoids [centre (working space), radii (sheet px)] that flow
## into each other (smooth union, k sheet px), so its outline has no cusps.
func _blob(parts: Array, col: Color, k: float) -> void:
	var centre := Vector3.ZERO
	var list := []
	for part in parts:
		centre += part[0] / parts.size()
		list.append({"t": "ell", "c": part[0], "r": part[1] * CK, "inv": Basis()})
	var reach := 0.0
	for part in list:
		var r: Vector3 = part.r
		reach = maxf(reach, centre.distance_to(part.c) + maxf(r.x, maxf(r.y, r.z)))
	_tints.append({"t": "blob", "c": centre, "r": Vector3.ONE * reach, "parts": list, "k": k * CK, "col": col, "soft": CELL * 0.35})


## giraffe_clay.gd's skin colour, extended with the "blob" patches above.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
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
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


## First point of a group's surface along a ray (working space): [point, outward normal].
func _ray(group: Array, from: Vector3, dir: Vector3) -> Array:
	var p := from
	var d := dir.normalized()
	for i in 3000:
		var f := _field(group, p)
		if f <= 0.0: break
		p += d * maxf(f * 0.5, 0.1)
	var h := 0.5
	var n := Vector3(
		_field(group, p + Vector3(h, 0, 0)) - _field(group, p - Vector3(h, 0, 0)),
		_field(group, p + Vector3(0, h, 0)) - _field(group, p - Vector3(0, h, 0)),
		_field(group, p + Vector3(0, 0, h)) - _field(group, p - Vector3(0, 0, h))).normalized()
	return [p, n]


## Drops a point near the face onto the skin along -n, then lifts it `lift` sheet px.
func _drop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * CK
	for i in 800:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * CK


# --- Face details -------------------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _cow_eye_frame(side: float) -> Array:
	var hit := _ray(_body, W(690, C_EYE_Y, side * C_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Height of an ellipsoid's surface above its centre plane at (o, u) from its centre.
static func _dome(r: Vector3, o: float, u: float) -> float:
	return r.z * sqrt(maxf(1.0 - pow(o / r.x, 2.0) - pow(u / r.y, 2.0), 0.0))


## Eyes, from the sheet's front, 3/4 and side views: a big upright oval set in the face and
## only gently domed; warm white showing as a crescent on the outer side and underneath; a
## large dark-brown iris toward the nose, almost filled by the black pupil; one small round
## catch-light high on the nose side of the pupil. The outline is drawn in _cow_details().
func _cow_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _cow_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		# The white's edge lies in the skin: its centre plane is set at the skin's mean height
		# round the eye, and the dome stands 2.8 px proud of the skin at its middle.
		var edge := 0.0
		for q in [Vector2(C_EYE_R.x, 0), Vector2(-C_EYE_R.x, 0), Vector2(0, C_EYE_R.y), Vector2(0, -C_EYE_R.y)]:
			edge += (_drop(s + (out * q.x + up * q.y) * CK, n, 0.0) - s).dot(n) / CK * 0.25
		var white_h := edge - 0.3
		var white := Vector3(C_EYE_R.x, C_EYE_R.y, 2.8 - white_h)
		g.color = C_SCLERA
		g.ellipsoid(s + n * white_h * CK, white * CK, frame, 40, 20)
		# Iris toward the nose and a little low; it rises just proud of the white.
		var io := Vector2(-2.9, -1.2)
		var iris := Vector3(15.4, 17.6, 2.4)   # a thin lens: it meets the white at a clean edge
		var iris_h := white_h + _dome(white, io.x, io.y) - iris.z + 1.2
		g.color = C_IRIS
		g.ellipsoid(s + (out * io.x + up * io.y + n * iris_h) * CK, iris * CK, frame, 36, 18)
		var pupil := Vector3(11.2, 13.3, 1.7)
		var pupil_h := iris_h + iris.z - pupil.z + 0.6
		g.color = C_PUPIL
		g.ellipsoid(s + (out * io.x + up * io.y + n * pupil_h) * CK, pupil * CK, frame, 32, 16)
		var go := Vector2(-2.9, 7.4)
		g.color = C_GLINT
		g.ellipsoid(s + (out * (io.x + go.x) + up * (io.y + go.y) + n * (pupil_h + _dome(pupil, go.x, go.y) + 0.25)) * CK,
				Vector3(2.5, 2.5, 0.6) * CK, frame, 16, 8)
	return _to_model(g)


## Lid lines and eyebrows. (No line on the cheeks: the smile corners were removed, user 11 Nov 2026.)
func _cow_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _cow_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Upper lid: a thick dark line over the top of the eye, from the nose side round and
		# down the outer side, thickest over the outer half.
		g.color = C_LID
		var lid := []
		var lid_w := []
		for i in 15:
			var t := i / 14.0
			var a := deg_to_rad(lerpf(-28.0, 166.0, t))
			var q := Vector2(cos(a) * (C_EYE_R.x - 0.3), sin(a) * (C_EYE_R.y - 0.3))
			lid.append(_drop(s + (out * q.x + up * q.y) * CK, n, 2.0))
			var w := lerpf(0.7, 2.7, sin(PI * clampf(t * 1.15, 0.0, 1.0)))
			lid_w.append(Vector2(w, 1.6) * CK)
		g.loft(lid, lid_w, n, 8)
		# The rest of the outline, under the eye: a fine brown line.
		g.color = C_CREASE
		var under := []
		var under_w := []
		for i in 13:
			var a := deg_to_rad(lerpf(166.0, 332.0, i / 12.0))
			var q := Vector2(cos(a) * (C_EYE_R.x - 0.8), sin(a) * (C_EYE_R.y - 0.8))
			under.append(_drop(s + (out * q.x + up * q.y) * CK, n, 0.5))
			under_w.append(Vector2(0.6, 0.6) * CK)
		g.loft(under, under_w, n, 6)
		# Lid crease: a fine second line above the outer half.
		g.color = C_CREASE
		var crease := []
		var crease_w := []
		for i in 7:
			var a := deg_to_rad(lerpf(48.0, 108.0, i / 6.0))
			var q := Vector2(cos(a) * (C_EYE_R.x + 5.4), sin(a) * (C_EYE_R.y + 5.2))
			crease.append(_drop(s + (out * q.x + up * q.y) * CK, n, 0.3))
			var w := 0.95 if i > 0 and i < 6 else 0.5
			crease_w.append(Vector2(w, 0.6) * CK)
		g.loft(crease, crease_w, n, 6)
		# Eyebrow: a short, soft brown arc well above the eye, the outer end lower.
		g.color = C_BROWN
		var brow := []
		var brow_w := []
		for q in [[13.0, 34.0, 2.2], [7.0, 39.5, 3.3], [-1.0, 42.5, 3.6], [-9.5, 42.5, 3.4], [-17.0, 40.0, 2.3]]:
			brow.append(_drop(s + (out * q[0] + up * q[1]) * CK, n, 0.2))
			brow_w.append(Vector2(q[2], 1.3) * CK)
		g.loft(brow, brow_w, n, 10)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / FINE
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= FINE
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
	root.name = "CowClayDisplay"
	root.set_meta("source", "User's Cow Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, C_CREAM, 7.0], ["Muzzle", _muzzle, C_MOUTH, 5.0], ["Horns", _horns, C_HORN, 7.0],
			["Ears", _ears, C_BROWN, 7.0], ["Hooves", _hooves, C_HOOF_CREASE, 5.0], ["Udder", _udder, C_UDDER_CREASE, 7.0],
			["Tail tuft", _tuft, C_TUFT_CREASE, 6.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Ears": _ear_tints, "Muzzle": _muzzle_tints}.get(part[0], [])
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
	eyes.mesh = _cow_eyes()
	eyes.material_override = _material(0.2)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _cow_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(W(740, CY, -70)) / FINE
	var c := to_model(W(1190, CTOP, 70)) / FINE
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
