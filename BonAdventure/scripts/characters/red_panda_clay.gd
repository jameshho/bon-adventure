extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style red panda traced from the user's "Red Panda Character Blueprint" turnaround (11 Nov
## 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for
## the zoo, built once by tools/build_red_panda_clay.gd into scenes/animals/red_panda_clay.tscn.
##
## Extends the clay giraffe only for its shared helpers (lion_clay.gd's distance-field mesher plus
## the giraffe's skin painting: _tint, _paint, _hit, _on_skin); every shape here is the panda's own.
## Shapes are written in the sheet's side-view pixels (x to the right = toward the tail, y down,
## z lateral) and PR() scales them into the lion's working space. The panda is small, so it is
## meshed as if P_WORK town units tall (about 1.2 cm of clay per grid step at its real size) and
## the finished meshes are scaled to P_HEIGHT. Head, body, ears and tail are separate fields, so
## they meet in creases as on the sheet; the orange back, cream face patches and tail rings are
## painted on the finished skin. Eyes, nose, mouth and whiskers are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const P_HEIGHT := 0.9           # town units to the ear tips (a small animal: dog .8, monkey .85)
const P_WORK := 2.2             # town units it is meshed at
const P_GY := 527.0             # sheet y of the soles
const P_TOP := 255.0            # sheet y of the ear tips
const P_GX := 1000.0            # sheet x placed at the model origin
const PK := P_WORK / ((P_GY - P_TOP) * S)   # sheet pixel -> lion working unit
const PF := P_HEIGHT / P_WORK   # finished meshes -> display size

# Colours sampled from the sheet and deepened a little for the town's daylight.
const P_ORANGE := Color("dc7433")
const P_BROWN := Color("67412b")
const P_BROWN_CREASE := Color("432819")
const P_CREAM := Color("f6dfba")
const P_PINK := Color("e98876")
const P_PINK_LIGHT := Color("f0a38c")
const P_NOSE := Color("3a2015")
const P_MOUTH := Color("5b3323")
const P_TAIL_DARK := Color("d16a2b")
const P_TAIL_LIGHT := Color("f4a450")
const P_IRIS := Color("4a2614")
const P_PUPIL := Color("120805")
const P_EYE_RING := Color("f7ead2")
const P_WHISKER := Color("e68b4c")

const P_EYE := Vector2(368.0, 35.0)        # sheet y and lateral offset of the eye centres

var _head := []
var _tail := []
var _head_tints := []
var _body_tints := []
var _tail_tints := []


## Sheet pixel -> working space (y up).
static func PR(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - P_GX) * PK, (P_GY - y) * PK, z * PK)


func pe(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * PK, col, k * PK, crease, basis)


func pc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * PK, rb * PK, col, k * PK)


## Short, thick leg and a round paw with three toes, creased between them.
func _pleg(b: Array, joints: Array, radii: Array, paw: Vector3) -> void:
	for i in joints.size() - 1:
		pc(b, joints[i], joints[i + 1], radii[i], radii[i + 1], P_BROWN, 14.0 if i == 0 else 5.0)
	pe(b, paw, Vector3(28, 14, 27), P_BROWN, 6.0, true)
	for t in [-1.0, 0.0, 1.0]:
		pe(b, paw + Vector3(-22.0, -2.5, t * 16.0) * PK, Vector3(12.0, 10.5, 9.5), P_BROWN, 2.0, true)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: a short, round barrel; brown clay, the orange back is painted on below.
	pe(b, PR(1005, 398), Vector3(88, 57, 64), P_BROWN)
	pe(b, PR(932, 410), Vector3(50, 47, 58), P_BROWN, 14.0)
	pe(b, PR(1048, 396), Vector3(46, 55, 62), P_BROWN, 14.0)
	# Legs, relaxed walk: one front leg planted and one reaching forward, one hind leg trailing
	# and one under the belly; the far pair's paws are just off the ground.
	_pleg(b, [PR(942, 428, 46), PR(948, 470, 46), PR(951, 498, 46)], [31.0, 27.0, 25.0], PR(944, 513, 46))
	_pleg(b, [PR(925, 430, -46), PR(893, 470, -46), PR(871, 493, -46)], [31.0, 27.0, 25.0], PR(859, 506, -46))
	_pleg(b, [PR(1066, 420, 46), PR(1092, 462, 46), PR(1106, 497, 46)], [35.0, 29.0, 25.0], PR(1099, 513, 46))
	_pleg(b, [PR(1040, 428, -46), PR(1028, 466, -46), PR(1022, 492, -46)], [32.0, 28.0, 25.0], PR(1015, 507, -46))
	_tints = []
	# Orange over the back and flanks, down to a line that dips a little mid-body.
	_tint(PR(1000, 371), Vector3(138, 57, 400) * PK, Basis(), P_ORANGE, CELL * 1.1)
	_body_tints = _tints

	# Head: very large and wide, broadest low at the cheeks, with a short cream muzzle.
	var h := _head
	pe(h, PR(893, 355), Vector3(84, 76, 86), P_ORANGE)
	for side in [-1.0, 1.0]:
		pe(h, PR(888, 336, side * 38.0), Vector3(62, 40, 42), P_ORANGE, 14.0)   # temples: boxy top
		pe(h, PR(868, 388, side * 52.0), Vector3(54, 44, 46), P_ORANGE, 16.0)   # cheeks
	pe(h, PR(822, 399), Vector3(30, 27, 37), P_CREAM, 8.0)
	_tints = []
	# Muzzle patch: a bell, narrow between the eyes and wide round the mouth.
	_tint(PR(828, 403), Vector3(40, 30, 44) * PK, Basis(), P_CREAM)
	_tint(PR(824, 381), Vector3(32, 20, 26) * PK, Basis(), P_CREAM)
	for side in [-1.0, 1.0]:
		# Brow spots: slanted beans, thicker and lower at the inner end.
		_patch(PR(700, 331, side * 31.0), 15.0, 9.0, P_CREAM, side * 0.2)
		_patch(PR(700, 334, side * 24.0), 9.5, 9.5, P_CREAM, side * 0.2)
		# Cheek patches: from just behind the eye down and back round the cheek.
		_tint(PR(854, 394, side * 74.0), Vector3(30, 34, 30) * PK, Basis(), P_CREAM)
	_head_tints = _tints

	# Ears: big thick cream cups turned half forward, half outward, pink inside with a paler
	# bump at the base, orange behind, and a cream tuft curling at the lower outer corner.
	for side in [-1.0, 1.0]:
		var open := Vector3(-0.78, 0.06, side * 0.62).normalized()
		var tall := Vector3(0.1, 0.95, side * 0.3)
		tall = (tall - open * tall.dot(open)).normalized()
		var wide := open.cross(tall).normalized()
		var basis := Basis(open, tall, wide)
		var c := PR(906, 299, side * 72.0)
		pe(_ears, c, Vector3(17, 48, 40), P_CREAM, 0.0, false, basis)
		pe(_ears, c - open * 7.0 * PK, Vector3(14, 41, 33), P_ORANGE, 0.0, false, basis)
		carve(_ears, c + (open * 14.0 - tall * 5.0) * PK, Vector3(11, 31, 24) * PK, P_PINK, basis)
		pe(_ears, c + (open * 5.0 - tall * 17.0) * PK, Vector3(5, 10, 9), P_PINK_LIGHT, 0.0, false, basis)
		pe(_ears, PR(928, 343, side * 95.0), Vector3(16, 12, 13), P_CREAM, 4.0)
		pe(_ears, PR(914, 335, side * 99.0), Vector3(13, 11, 11), P_CREAM, 4.0)

	# Tail: a thick, nearly straight sausage angled down behind, with pale rings and a dark tip.
	var root := PR(1070, 388)
	var tip := PR(1172, 462)
	var mid := PR(1122, 425)
	pc(_tail, root, mid, 32.0, 42.0, P_TAIL_DARK)
	pc(_tail, mid, tip, 42.0, 41.0, P_TAIL_DARK, 10.0)
	var along := (tip - root).normalized()
	var across := Vector3(0, 0, 1)
	var ring_basis := Basis(along, across.cross(along).normalized(), across)
	_tints = []
	for at in [42.0, 86.0, 128.0]:
		_tint(root + along * at * PK, Vector3(13, 90, 90) * PK, ring_basis, P_TAIL_LIGHT)
	_tail_tints = _tints


## Paints an ellipse (rx across, ry up, sheet pixels) on the head's skin where the ray from
## `from` toward the tail meets it, rolled about the skin's normal.
func _patch(from: Vector3, rx: float, ry: float, col: Color, roll := 0.0) -> void:
	var hit := _head_hit(from)
	var n: Vector3 = hit[1]
	var t1 := Vector3.UP.cross(n).normalized()
	var basis := Basis(t1, n.cross(t1).normalized(), n) * Basis(Vector3(0, 0, 1), roll)
	_tint(hit[0], Vector3(rx, ry, 9.0) * PK, basis, col)


## The head's skin seen from the front: [point, outward normal] (working space).
func _head_hit(from: Vector3) -> Array:
	var keep := _body
	_body = _head
	var hit := _hit(from, Vector3(1, 0, 0))
	_body = keep
	return hit


func _head_front(y: float, z: float) -> Array:
	return _head_hit(PR(700, y, z))


func _painted(mesh: ArrayMesh, tints: Array) -> ArrayMesh:
	_tints = tints
	return _paint(mesh)


# --- Face details -------------------------------------------------------------------------

## Eyes: big, round and glossy; warm dark iris, large black pupil, a thin pale ring showing
## at the lower outer edge, one catch-light high toward the nose and a small one opposite.
func _panda_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var hit := _head_front(P_EYE.x, side * P_EYE.y)
		var s: Vector3 = hit[0]
		var n: Vector3 = hit[1]
		var right := Vector3.UP.cross(n).normalized()
		var out: Vector3 = right * side
		var up := n.cross(right).normalized()
		var frame := Basis(out, up, n)
		g.color = P_EYE_RING
		g.ellipsoid(s + (out * 0.9 - up * 0.7) * PK, Vector3(15.0, 15.5, 2.0) * PK, frame, 32, 12)
		g.color = P_IRIS
		g.ellipsoid(s + n * 0.4 * PK, Vector3(14.0, 14.6, 4.2) * PK, frame, 36, 16)
		g.color = P_PUPIL
		g.ellipsoid(s + n * 1.5 * PK, Vector3(11.0, 11.6, 3.6) * PK, frame, 32, 14)
		g.color = Color("fffdf8")
		g.ellipsoid(s + (out * -3.6 + up * 5.2 + n * 4.5) * PK, Vector3(3.0, 3.0, 0.5) * PK, frame, 16, 8)
		g.ellipsoid(s + (out * 4.6 - up * 4.8 + n * 4.25) * PK, Vector3(1.4, 1.4, 0.35) * PK, frame, 12, 6)
	return _to_model(g)


## Nose, mouth and whiskers.
func _panda_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	# Nose: a rounded triangle, wide at the top, on the front of the muzzle.
	g.color = P_NOSE
	var nose_c: Vector3 = _head_front(387.0, 0.0)[0] + Vector3(1.0, 0, 0) * PK
	var nose_r := Vector3(7.0, 9.5, 15.0) * PK
	var first := g.verts.size()
	g.ellipsoid(nose_c, nose_r, Basis(), 24, 12)
	for i in range(first, g.verts.size()):
		var q: Vector3 = g.verts[i] - nose_c
		var yn := clampf(q.y / nose_r.y, -1.0, 1.0)
		var taper := lerpf(0.3, 1.0, pow((yn + 1.0) * 0.5, 0.7))
		if q.y > 0.0: q.y *= 0.8   # flatter top
		g.verts[i] = nose_c + Vector3(q.x, q.y, q.z * taper)
		var nn: Vector3 = g.norms[i]
		g.norms[i] = Vector3(nn.x, nn.y, nn.z / taper).normalized()
	# Mouth: short line down from the nose, then a small upturned curve to each side.
	g.color = P_MOUTH
	var line := []
	for y in [395.0, 401.0, 407.5]:
		var hit := _head_front(y, 0.0)
		line.append(hit[0] + hit[1] * 0.3 * PK)
	var thin := Vector2(0.85, 0.85) * PK
	g.loft(line, [thin, thin, thin], Vector3(0, 0, 1), 6)
	for side in [-1.0, 1.0]:
		var curve := []
		var widths := []
		for pt in [[407.5, 0.0, 0.85], [410.5, 5.0, 0.85], [412.0, 11.0, 0.85], [411.0, 17.0, 0.75], [408.0, 22.0, 0.6], [404.5, 25.5, 0.35]]:
			var hit := _head_front(pt[0], side * pt[1])
			curve.append(hit[0] + hit[1] * 0.3 * PK)
			widths.append(Vector2(pt[2], pt[2]) * PK)
		g.loft(curve, widths, Vector3.UP, 6)
		# Whiskers: three faint pale strokes lying on the cheek between muzzle and cheek patch.
		g.color = P_WHISKER
		for w in [[393.0, 389.0], [400.0, 400.0], [407.0, 411.0]]:
			var stroke := []
			for t in [0.0, 0.5, 1.0]:
				var hit := _head_front(lerpf(w[0], w[1], t), side * lerpf(48.0, 62.0, t))
				stroke.append(hit[0] + hit[1] * 0.1 * PK)
			g.loft(stroke, [Vector2(0.4, 0.4) * PK, Vector2(0.4, 0.4) * PK, Vector2(0.2, 0.2) * PK], Vector3.UP, 5)
		g.color = P_MOUTH
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

## The mesh at display size (the fields are meshed larger for a fine surface).
static func _sized(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] *= PF
	var built := []
	built.resize(Mesh.ARRAY_MAX)
	for channel in [Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR, Mesh.ARRAY_INDEX]:
		built[channel] = arrays[channel]
	built[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, built)
	return out


func build_display() -> Node3D:
	_body.clear(); _head.clear(); _ears.clear(); _tail.clear()
	_shape()
	var root := Node3D.new()
	root.name = "RedPandaClayDisplay"
	root.set_meta("source", "User's Red Panda Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.9)
	clay.metallic_specular = 0.3
	for part in [["Body", _body, _body_tints], ["Head", _head, _head_tints], ["Ears", _ears, []], ["Tail", _tail, _tail_tints]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		var mesh := _mesh(part[1], P_BROWN_CREASE, 6.0)
		if not (part[2] as Array).is_empty():
			mesh = _painted(mesh, part[2])
		mi.mesh = _sized(mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _sized(_panda_eyes())
	eyes.material_override = _material(0.18)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _sized(_panda_details())
	face.material_override = _material(0.45)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the whole animal (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(PR(790, P_GY, -98)) * PF
	var c := to_model(PR(1214, P_TOP, 98)) * PF
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
