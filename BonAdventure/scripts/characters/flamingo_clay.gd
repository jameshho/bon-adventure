extends "res://scripts/characters/cow_clay.gd"
## Clay-style flamingo traced from the user's "Flamingo Character Blueprint" turnaround
## (11 Nov 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display
## model, built once by tools/build_flamingo_clay.gd into scenes/animals/flamingo_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd: _tint, _paint) and the clay cow's helpers (cow_clay.gd: _ray, blob tints).
## Shapes are written in the flamingo sheet's side-view pixels (x to the right = toward the
## tail, y down, z lateral, + = the side facing the viewer) and V() scales them into the lion's
## working space. The bird is slim (legs 12 px = 4 cm thick), so it is meshed FF times larger
## than life and shrunk afterwards: the clay grid is 3 cm / FF on the finished model.
## The beak, crest, wings with the tail, and legs are separate clay pieces; every feather is
## its own flattened puff laid on the body's skin (_feather), the upper rows over the lower
## ones; the beak's brown tip and the blush are painted; eyes, lids, lashes, brows and the
## mouth line are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const FH := 1.4                 # town units to the top of the crest (provisional: under the cow's 1.55)
const FY := 562.0               # sheet y of the soles
const FTOP := 124.0             # sheet y of the top of the crest
const FX := 950.0               # sheet x placed at the model origin
const FF := 4.0                 # meshed this many times larger than life
const FK := FF * FH / ((FY - FTOP) * S)   # sheet pixel -> lion working unit

# Colours sampled from the sheet, then deepened: the sampled mid tones (body f2a08c) washed out
# to pale peach in the town's daylight (first zoo view, 11 Nov 2026).
const F_PINK := Color("ea8572")
const F_PINK_CREASE := Color("d97462")
const F_WING_1 := Color("ee9f8b")        # top coverts and their scalloped edge
const F_WING_2 := Color("ea917f")        # second row
const F_WING_3 := Color("df6f62")        # third row
const F_WING_4 := Color("d0584f")        # long flight feathers
const F_WING_CREASE := Color("d4675a")
const F_LEG := Color("e4776a")
const F_LEG_CREASE := Color("cf6659")
const F_BEAK := Color("e2c2a4")
const F_BEAK_TIP := Color("5c3b28")
const F_MOUTH := Color("4a2f22")
const F_BLUSH := Color("ee6a58")
const F_BROW := Color("9c5f50")
const F_SCLERA := Color("f9f3ea")
const F_IRIS := Color("2d170c")
const F_PUPIL := Color("0e0705")
const F_LID := Color("2a1a13")

# Eyes (sheet px): height and lateral offset of the centre, half-sizes measured face-on in the
# front 3/4 view (21 x 25; the front view shows 15 across, the side view 20).
const F_EYE_Y := 183.0
const F_EYE_Z := 36.0
const F_EYE_R := Vector2(10.8, 13.0)

## Legs as [sheet x, lateral z]: the near one stands a little behind the far one.
const F_LEGS := [[950.0, -17.5], [972.0, 17.5]]

var _wings := []
var _legs := []


## Sheet pixel -> working space (y up).
static func V(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - FX) * FK, (FY - y) * FK, z * FK)


func fe(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * FK, col, k * FK, crease, basis)


func fc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * FK, rb * FK, col, k * FK)


func ftube(g: Array, pts: Array, radii: Array, col: Color, k: float, k_rest := 3.0) -> void:
	for i in pts.size() - 1:
		fc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else k_rest)


## Rotation about the lateral axis: positive raises the tail end of a shape.
static func tilt(a: float) -> Basis:
	return Basis(Vector3(0, 0, 1), a)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Head: a ball a little longer than tall, widest low down at the cheeks.
	fe(b, V(907, 183), Vector3(50, 43.5, 47.5), F_PINK)
	for side in [-1.0, 1.0]:
		fe(b, V(900, 201, side * 21.0), Vector3(32, 23, 26), F_PINK, 12.0)
	# Neck: an S from the back of the head down and forward into the chest; slimmest where it
	# slants.
	ftube(b, [V(930, 212), V(927, 232), V(916, 246), V(900, 263), V(886, 280), V(878, 297), V(881, 320)],
			[21.0, 20.0, 18.5, 18.0, 18.5, 20.5, 24.0], F_PINK, 10.0, 8.0)
	# Body: a deep round chest, a longer barrel, and a rump that narrows under the tail.
	fe(b, V(910, 334), Vector3(56, 48, 51), F_PINK, 18.0)
	fe(b, V(962, 342), Vector3(78, 56, 58), F_PINK, 22.0)
	fe(b, V(1012, 347), Vector3(46, 40, 42), F_PINK, 20.0)
	fe(b, V(978, 326), Vector3(62, 41, 50), F_PINK, 20.0)       # the high, rounded back
	# Feathered tops of the legs.
	for leg in F_LEGS:
		fc(b, V(leg[0], 384, leg[1] * 0.9), V(leg[0], 411, leg[1]), 14.0, 9.0, F_PINK, 8.0)

	# Beak: a thick banana, level out of the face, then bent down to a blunt hook; wider than
	# it is deep at the base. The tip is painted brown (boundary slanting down and back).
	var m := _muzzle
	fe(m, V(855, 199), Vector3(21, 19, 22), F_BEAK)
	ftube(m, [V(862, 197), V(842, 203), V(827, 214), V(823, 228), V(825.5, 240), V(828.5, 250), V(829.5, 253.5)],
			[19.0, 19.0, 16.0, 12.6, 9.6, 5.2, 2.6], F_BEAK, 6.0, 5.0)
	_muzzle_tints.append({"t": "ell", "c": V(800, 250), "r": Vector3(41, 44, 60) * FK, "inv": Basis(), "col": F_BEAK_TIP, "soft": CELL * 0.3})

	# Crest: three short fingers lying back on top of the head, the middle one highest.
	fe(_mane, V(907, 131.5), Vector3(12, 6.5, 5.8), F_PINK, 0.0, true, tilt(0.45))
	for side in [-1.0, 1.0]:
		fe(_mane, V(917, 136.5, side * 9.5), Vector3(12, 6.2, 4.8), F_PINK, 1.5, true, Basis(Vector3(0, 1, 0), -side * 0.15) * tilt(0.2))
	fe(_mane, V(912, 142), Vector3(13, 5, 12), F_PINK, 3.0)

	_wing_feathers()

	# Legs: thin stalks with a knobbly knee, a slight forward bow, and a thicker ankle.
	var g := _legs
	for leg in F_LEGS:
		var x: float = leg[0]
		var z: float = leg[1]
		var s := signf(z)
		ftube(g, [V(x, 404, z), V(x + 3.5, 440, z), V(x + 6.0, 460, z), V(x + 4.0, 482, z), V(x, 512, z), V(x - 2.0, 540, z)],
				[6.4, 6.0, 6.0, 5.8, 5.8, 6.6], F_LEG, 0.0, 2.0)
		fe(g, V(x + 6.0, 460, z), Vector3(8.6, 9.5, 8.8), F_LEG, 5.0)
		fe(g, V(x - 1.0, 546, z), Vector3(9.5, 9.0, 9.5), F_LEG, 5.0)
		# Foot: three toes fanned forward and outward, a web between them, a small heel.
		for toe in [[-52.0, 7.5], [-40.0, 27.5], [-45.0, -9.5]]:
			fc(g, V(x - 4.0, 552, z), V(x + toe[0], 556.6, z + s * toe[1]), 6.2, 4.8, F_LEG, 4.0)
		fe(g, V(x - 25.0, 557.6, z + s * 8.5), Vector3(22, 3.4, 17), F_LEG, 3.0)
		fe(g, V(x + 4.0, 554, z), Vector3(7.5, 6.5, 7.5), F_LEG, 4.0)
	for leg in F_LEGS:
		carve(g, V(leg[0] - 20.0, FY + 40.0, leg[1]), Vector3(140, 40, 140) * FK, F_LEG)

	# Blush: a soft round patch low on each cheek, behind the eye.
	for side in [-1.0, 1.0]:
		_tint(V(902, 201, side * 44.0), Vector3(15, 13, 15) * FK, Basis(), F_BLUSH, CELL * 3.0)


## One feather: a flattened puff laid on the body's skin where a ray from the side meets it at
## sheet (x, y). r = half length, half width, half thickness (sheet px); `a` turns it in the
## side view (negative lowers the tail end); `lift` raises its middle off the skin (kept under
## its thickness, so it stays sunk in the clay) and `shift` slides it along its length (for
## feathers that reach past the body); `turn` swings its tail end in toward the body.
func _feather(x: float, y: float, side: float, r: Vector3, a: float, col: Color, lift: float, shift := 0.0, turn := 0.0, k := 2.0, crease := true) -> void:
	var hit := _ray(_body, V(x, y, side * 160.0), Vector3(0, 0, -side))
	_lay(hit, Vector3(cos(a), sin(a), 0.0), r, col, lift, shift, turn, k, crease)


## One painted feather on the back, where a ray from behind meets the body at sheet height y
## and lateral z: a round-ended patch (half height ry, half width rz) over a darker rim that
## shows along its lower edge. Geometry feathers this small stood off the tightly curved rump
## like plates (11 Nov 2026), so the back's rows are paint.
func _back_feather(y: float, z: float, ry: float, rz: float, col: Color) -> void:
	var at: Vector3 = _ray(_body, V(1220, y, z), Vector3(-1, 0, 0))[0]
	_tint(at + Vector3(0, -1.6, 0) * FK, Vector3(20, ry + 0.9, rz + 0.9) * FK, Basis(), F_WING_CREASE, CELL * 0.3)
	_tint(at, Vector3(20, ry, rz) * FK, Basis(), col, CELL * 0.3)


func _lay(hit: Array, d: Vector3, r: Vector3, col: Color, lift: float, shift: float, turn: float, k: float, crease: bool) -> void:
	var n: Vector3 = hit[1]
	var flat := (d - n * d.dot(n)).normalized()
	var across := n.cross(flat).normalized()
	var along := flat * cos(turn) - n * sin(turn)
	var out := n * cos(turn) + flat * sin(turn)
	fe(_wings, hit[0] + (out * lift + along * shift) * FK, r, col, k, crease, Basis(along, across, out))


## Wings, back and tail, lowest layer first (the mesher gives each point the colour of the puff
## that stands highest there, and draws a crease where two feathers meet).
func _wing_feathers() -> void:
	for side in [-1.0, 1.0]:
		# Blades are rooted on the flank and slid back along their length, so they fan out
		# past the rump as flat feathers instead of wrapping under the belly.
		# Flight feathers: two dark blades, the lowest and longest.
		_feather(1005, 362, side, Vector3(34, 11.5, 6.0), -0.42, F_WING_4, 1.5, 40.0)
		_feather(1000, 372, side, Vector3(30, 9.5, 5.5), -0.33, F_WING_4, 1.0, 38.0)
		# Salmon blades: two under the pale wing, two longer ones fanning to the tail.
		_feather(940, 360, side, Vector3(35, 10.5, 6.0), -0.3, F_WING_3, 3.0, 27.0)
		_feather(972, 364, side, Vector3(34, 10.5, 6.0), -0.22, F_WING_3, 3.0, 27.0)
		_feather(990, 347, side, Vector3(36, 11.5, 6.0), -0.38, F_WING_3, 4.0, 28.0)
		_feather(1021, 332, side, Vector3(32, 11.5, 6.0), -0.64, F_WING_3, 4.5, 26.0)
		# Two long pale blades along the back, above the wing.
		_feather(990, 303, side, Vector3(40, 11, 6.0), -0.42, F_WING_2, 4.5, 18.0)
		_feather(1005, 315, side, Vector3(34, 10.5, 6.0), -0.5, F_WING_2, 5.0, 18.0)
		# The pale wing: three big round-ended lobes along its lower edge under one smooth
		# leaf-shaped pad from the shoulder to a point at the rump.
		for f in [[936, 346, Vector3(17, 15, 7.0), -1.35], [967, 346, Vector3(17, 16, 7.0), -0.75], [995, 340, Vector3(18, 14, 7.0), -0.5]]:
			_feather(f[0], f[1], side, f[2], f[3], F_WING_1, 6.5)
		for f in [[934, 324, Vector3(25, 25, 8.0), -1.2], [966, 318, Vector3(40, 25, 8.0), -0.1], [1000, 326, Vector3(31, 19, 7.5), -0.38]]:
			_feather(f[0], f[1], side, f[2], f[3], F_WING_1, 5.0, 0.0, 0.0, 10.0, false)
	# Back, between the wings: painted rows of wide round-ended feathers like shingles, the
	# lower row first so the upper one overlaps it.
	_back_feather(349, 0.0, 22.0, 16.0, F_WING_2)
	for side in [-1.0, 1.0]:
		_back_feather(344, side * 27.0, 20.0, 14.0, F_WING_2)
	for side in [-1.0, 1.0]:
		_back_feather(311, side * 15.0, 29.0, 17.5, F_WING_1)
	# Tail: four rounded feathers hanging down and back under them.
	for side in [-1.0, 1.0]:
		fe(_wings, V(1047, 377, side * 8.5), Vector3(11, 26, 10), F_WING_3, 1.5, true, tilt(0.3))
		fe(_wings, V(1040, 373, side * 24.0), Vector3(10.5, 23, 10), F_WING_3, 1.5, true, tilt(0.3))


# --- Face details -------------------------------------------------------------------------

## Drops a point near the face onto the skin along -n, then lifts it `lift` sheet px.
func _fdrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * FK
	for i in 1200:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * FK


## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _flamingo_eye_frame(side: float) -> Array:
	var hit := _ray(_body, V(760, F_EYE_Y, side * F_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Eyes, from the sheet's front, 3/4 and side views: an upright oval set in the side of the face
## and only gently domed; a very dark brown iris, almost filled by the black pupil, covers
## most of it and sits toward the beak, leaving a white crescent on the outer side and over
## the top; one round catch-light high in the pupil.
func _flamingo_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _flamingo_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		# The white's edge lies in the skin (its centre plane at the skin's mean height round
		# the eye); the dome stands 2.4 px proud of the skin at its middle.
		var edge := 0.0
		for q in [Vector2(F_EYE_R.x, 0), Vector2(-F_EYE_R.x, 0), Vector2(0, F_EYE_R.y), Vector2(0, -F_EYE_R.y)]:
			edge += (_fdrop(s + (out * q.x + up * q.y) * FK, n, 0.0) - s).dot(n) / FK * 0.25
		var white_h := edge - 0.2
		var white := Vector3(F_EYE_R.x, F_EYE_R.y, 2.4 - white_h)
		g.color = F_SCLERA
		g.ellipsoid(s + n * white_h * FK, (white - Vector3(0.5, 0.5, 0.0)) * FK, frame, 40, 20)
		var io := Vector2(-1.9, -0.9)
		var iris := Vector3(8.6, 11.7, 1.5)
		var iris_h := white_h + _dome(white, io.x, io.y) - iris.z + 0.75
		g.color = F_IRIS
		g.ellipsoid(s + (out * io.x + up * io.y + n * iris_h) * FK, iris * FK, frame, 40, 20)
		var po := io + Vector2(0.0, 0.9)
		var pupil := Vector3(7.3, 10.0, 1.2)
		var pupil_h := iris_h + _dome(iris, 0.0, 0.9) - pupil.z + 0.3
		g.color = F_PUPIL
		g.ellipsoid(s + (out * po.x + up * po.y + n * pupil_h) * FK, pupil * FK, frame, 36, 18)
		var go := Vector2(-0.6, 3.9)
		g.color = F_SCLERA
		g.ellipsoid(s + (out * (po.x + go.x) + up * (po.y + go.y) + n * (pupil_h + _dome(pupil, go.x, go.y) + 0.15)) * FK,
				Vector3(2.8, 2.8, 0.45) * FK, frame, 20, 10)
	return _to_model(g)


## Eye outlines, lashes, eyebrows and the mouth line along the beak.
func _flamingo_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _flamingo_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		# Outline: a dark line right round the eye, thick over the top and down the outer
		# side, fine underneath.
		g.color = F_LID
		var lid := []
		var lid_w := []
		for i in 33:
			var a := TAU * i / 32.0 - PI * 0.5        # starts and ends under the eye
			var q := Vector2(cos(a) * F_EYE_R.x, sin(a) * F_EYE_R.y)
			lid.append(_fdrop(s + (out * q.x + up * q.y) * FK, n, 0.9))
			var top := clampf(sin(a - 0.35) * 0.5 + 0.5, 0.0, 1.0)
			lid_w.append(Vector2(lerpf(0.4, 1.45, top * top), 0.7) * FK)
		g.loft(lid, lid_w, n, 8)
		# Three short lashes fanned off the upper outer corner.
		for lash in [[12.0, 4.2], [32.0, 4.8], [52.0, 4.2]]:
			var a := deg_to_rad(lash[0])
			var dir := Vector2(cos(a + 0.2), sin(a + 0.2))
			var root := Vector2(cos(a) * F_EYE_R.x, sin(a) * F_EYE_R.y)
			var pts := []
			var ws := []
			for j in 4:
				var q: Vector2 = root + dir * lash[1] * j / 3.0
				pts.append(_fdrop(s + (out * q.x + up * q.y) * FK, n, 0.6))
				ws.append(Vector2(lerpf(1.15, 0.45, j / 3.0), 0.5) * FK)
			g.loft(pts, ws, n, 6)
		# Eyebrow: a short soft arc well above the eye, its outer end a little lower.
		g.color = F_BROW
		var brow := []
		var brow_w := []
		for q in [[9.5, 21.8, 1.0], [5.0, 25.2, 1.9], [0.0, 26.4, 2.1], [-4.5, 25.8, 1.9], [-8.5, 23.4, 1.0]]:
			brow.append(_fdrop(s + (out * q[0] + up * q[1]) * FK, n, 0.2))
			brow_w.append(Vector2(q[2], 0.9) * FK)
		g.loft(brow, brow_w, n, 10)
		# Mouth: a fine line from the corner at the face along the beak's side, turning down
		# into the tip.
		g.color = F_MOUTH
		var both: Array = _body + _muzzle
		var mouth := []
		var mouth_w := []
		for q in [[864.5, 197.6], [861, 200], [856, 202], [846, 206], [838, 210.5], [832.5, 217], [829, 225], [827.5, 234], [828.5, 242], [830, 248]]:
			var hit := _ray(both, V(q[0], q[1], side * 80.0), Vector3(0, 0, -side))
			mouth.append(hit[0] + hit[1] * 0.25 * FK)
			mouth_w.append(Vector2(0.55, 0.5) * FK)
		g.loft(mouth, mouth_w, Vector3(0, 0, side), 6)
	return _to_model(g)


func _to_model(g) -> ArrayMesh:
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i]) / FF
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= FF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _muzzle_tints, _wings, _legs]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "FlamingoClayDisplay"
	root.set_meta("source", "User's Flamingo Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, F_PINK_CREASE, 7.0], ["Beak", _muzzle, F_BEAK, 5.0], ["Crest", _mane, F_PINK_CREASE, 6.0],
			["Wings", _wings, F_WING_CREASE, 2.6], ["Legs", _legs, F_LEG_CREASE, 5.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var paints: Array = {"Body": _tints, "Beak": _muzzle_tints}.get(part[0], [])
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
	eyes.mesh = _flamingo_eyes()
	eyes.material_override = _material(0.15)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _flamingo_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body, neck and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(V(815, FY, -62)) / FF
	var c := to_model(V(1070, FTOP, 62)) / FF
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
