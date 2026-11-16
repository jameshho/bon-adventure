extends "res://scripts/characters/giraffe_clay.gd"
## Clay-style kangaroo traced from the user's "Kangaroo Character Blueprint" turnaround (11 Nov
## 2026, "Relax Walk Pose": front 3/4, front, side, back, rear 3/4). A static display model for
## the zoo, built once by tools/build_kangaroo_clay.gd into scenes/animals/kangaroo_clay.tscn.
##
## Reuses the clay lion's distance-field mesher and the clay giraffe's skin painting and ray
## helpers (_tint, _paint, _hit, _to_model). Shapes are written in the kangaroo sheet's
## side-view pixels (x to the right = toward the tail, y down, z lateral, + = the side facing
## the viewer; front-view measurements give z). The kangaroo is small next to the mesher's 3 cm
## cell, so it is meshed DETAIL times too large and the finished meshes are shrunk (_shrunk):
## 1.5 cm clay, which the ears' thin cups need. Cream throat, belly, lower legs and tail
## underside are painted on the finished skin; toes and fingertips are brown clay; eyes, nose
## and mouth are small parts laid on the face.
## Output faces -Z (head), +Y up, ground at y = 0.

const KH := 2.3                 # town units to the ear tips (chosen 11 Nov 2026; lion 1.95, bear 2.2)
const KY := 758.0               # sheet y of the soles
const KTOP := 350.0             # sheet y of the ear tips
const KX := 750.0               # sheet x placed at the model origin
const DETAIL := 2.0
const KK := DETAIL * KH / ((KY - KTOP) * S)   # sheet pixel -> working unit

# Colours sampled from the sheet, then deepened so they read as the sheet's under the town's
# bright daylight (the first zoo preview came out pale, as the giraffe's did).
const ORANGE := Color("d98a3c")
const K_CREAM := Color("eec08a")
const K_TOE := Color("774a26")
const K_TOE_CREASE := Color("523218")
const K_NOSE := Color("6b4424")
const K_EAR_IN := Color("eda684")
const K_EYE := Color("2f1c0e")
const K_GLINT := Color("d9cfc2")
const K_MOUTH := Color("6a4425")

const K_EYE_AT := Vector2(447.0, 22.8)      # sheet y and lateral offset of the eye centres
const K_EYE_R := Vector3(6.6, 8.3, 3.4)     # across the skin, up, bulge (sheet px)


## Sheet pixel -> working space (y up).
static func Q(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - KX) * KK, (KY - y) * KK, z * KK)


func ke(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis(), paint := false) -> void:
	ell(g, c, r * KK, col, k * KK, crease, basis, paint)


func kc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * KK, rb * KK, col, k * KK)


func klimb(g: Array, pts: Array, radii: Array, k: float, k_next := 4.0) -> void:
	for i in pts.size() - 1:
		kc(g, pts[i], pts[i + 1], radii[i], radii[i + 1], ORANGE, k if i == 0 else k_next)


## Painted area in sheet pixels; `soft` is the width of its edge.
func ktint(c: Vector3, r: Vector3, col: Color, soft := 4.0, basis := Basis()) -> void:
	_tint(c, r * KK, basis, col, soft * KK)


## Three brown toes (or fingertips) side by side at `c`, pointing along -x tilted by `tilt`.
func _digits(b: Array, c: Vector3, r: Vector3, spread: float, tilt: float) -> void:
	var basis := Basis(Vector3(0, 0, 1), tilt)
	for t in [-1.0, 0.0, 1.0]:
		var rr := r * (1.0 if t == 0.0 else 0.92)
		ke(b, c + Vector3(0, 0, t * spread * KK), rr, K_TOE, 2.0, true, basis, true)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Torso: leaning forward, slim chest swelling to a heavy rump.
	klimb(b, [Q(683, 552), Q(720, 584), Q(752, 610)], [37.0, 49.0, 51.0], 0.0, 0.0)
	# Neck, upright, a little thicker at the shoulders.
	kc(b, Q(662, 486), Q(676, 536), 24.0, 30.0, ORANGE, 14.0)
	# Head: round skull, full cheeks low down, a short tapering snout.
	ke(b, Q(656, 447), Vector3(38, 35, 38), ORANGE, 10.0)
	ke(b, Q(652, 458), Vector3(30, 32, 41), ORANGE, 10.0)
	kc(b, Q(634, 451), Q(600, 462), 20.0, 12.0, ORANGE, 8.0)
	ke(b, Q(610, 473), Vector3(22, 18.5, 25), ORANGE, 8.0)
	ke(b, Q(597, 468), Vector3(11, 11.5, 15), ORANGE, 6.0)   # blunt tip under the nose
	# Haunches: big round thighs standing proud of the body; the far one swings forward.
	ke(b, Q(756, 606, 46), Vector3(44, 48, 28), ORANGE, 9.0)
	ke(b, Q(746, 606, -46), Vector3(43, 47, 28), ORANGE, 9.0)
	# Near hind leg: straight down from the haunch, foot flat on the ground.
	klimb(b, [Q(772, 640, 40), Q(795, 682, 37), Q(800, 724, 37)], [26.0, 18.0, 15.5], 10.0)
	kc(b, Q(800, 739, 37), Q(748, 744, 43), 16.0, 13.5, ORANGE, 5.0)
	_digits(b, Q(734, 745, 45), Vector3(17, 11.5, 9.5), 14.0, 0.0)
	# Far hind leg: knee forward, heel lifted, the long foot reaching down to its toes.
	klimb(b, [Q(724, 628, -40), Q(688, 640, -38), Q(705, 698, -37)], [28.0, 21.0, 16.5], 10.0)
	kc(b, Q(704, 706, -37), Q(636, 731, -43), 16.0, 14.5, ORANGE, 5.0)
	_digits(b, Q(617, 741.5, -45), Vector3(18, 11.5, 9.5), 14.0, 0.36)
	# Arms: held in front of the chest, hands drooping with brown fingertips.
	for side in [-1.0, 1.0]:
		kc(b, Q(684, 548, side * 33), Q(644, 568, side * 30), 14.0, 12.0, ORANGE, 8.0)
		kc(b, Q(642, 570, side * 29), Q(636, 596, side * 27), 12.0, 11.5, ORANGE, 4.0)
		_digits(b, Q(635, 604.5, side * 27), Vector3(7.5, 8.0, 5.6), 8.0, 0.0)
	# Tail: thick at the rump, sweeping down and trailing along the ground to a slim tip.
	var tail := [Q(793, 636), Q(822, 682), Q(852, 719), Q(885, 739), Q(914, 748), Q(932, 751.5)]
	var tail_r := [21.0, 14.0, 10.5, 8.0, 5.6, 3.6]
	klimb(b, tail, tail_r, 16.0, 6.0)

	# Ears: long leaf-shaped cups, splayed out and leaning back, opening forward and outward;
	# orange outside with a thick rim, peach-pink inside.
	for side in [-1.0, 1.0]:
		var along := Vector3(38, 69, side * 34).normalized()
		var open := Vector3(-0.85, 0.0, side * 0.53)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(-open, along.cross(-open).normalized(), along)
		var c := Q(664, 420, side * 22) + along * 41.0 * KK
		ke(_ears, c, Vector3(6.0, 21.0, 42.0), ORANGE, 0.0, false, basis)
		ke(_ears, c + along * 19.0 * KK, Vector3(5.2, 12.5, 25.0), ORANGE, 6.0, false, basis)
		carve(_ears, c + open * 5.6 * KK + along * 2.0 * KK, Vector3(4.9, 17.2, 35.5) * KK, K_EAR_IN, basis)

	# Painted cream: lower snout and chin, throat and chest, belly, lower legs, tail underside.
	ktint(Q(604, 485), Vector3(30, 21, 27), K_CREAM, 3.5)
	ktint(Q(642, 530), Vector3(28, 56, 28), K_CREAM, 4.0)
	ktint(Q(686, 606), Vector3(34, 50, 33), K_CREAM, 4.0)
	ktint(Q(790, 737, 38), Vector3(42, 31, 27), K_CREAM, 16.0)
	ktint(Q(665, 716, -38), Vector3(64, 37, 29), K_CREAM, 16.0)
	for i in range(1, tail.size()):
		var a: Vector3 = tail[i - 1]
		var d: Vector3 = tail[i]
		for t in ([0.5, 1.0] if i > 1 else [1.0]):
			var r: float = lerpf(tail_r[i - 1], tail_r[i], t)
			var dir := (d - a).normalized()
			var under := Vector3(-dir.y, dir.x, 0.0)   # the side of the tail facing the ground
			if under.y > 0.0: under = -under
			ktint(a.lerp(d, t) + under * r * 0.95 * KK, Vector3(r * 1.5, r, r * 1.05), K_CREAM, 3.0, Basis(Vector3(0, 0, 1), atan2(dir.y, dir.x)))


## The brown clay (toes, fingertips, nose) keeps its colour under the painted cream.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var painted := super(v, col, reach)
	var d := Vector3(col.r - ORANGE.r, col.g - ORANGE.g, col.b - ORANGE.b).length()
	var full := Vector3(K_TOE.r - ORANGE.r, K_TOE.g - ORANGE.g, K_TOE.b - ORANGE.b).length()
	return painted.lerp(col, clampf(d / (full * 0.6), 0.0, 1.0))


# --- Face details -------------------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _k_eye_frame(side: float) -> Array:
	var hit := _hit(Q(540, K_EYE_AT.x, side * K_EYE_AT.y), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	return [hit[0], n, right * side, n.cross(right).normalized()]


## Eyes: plain glossy dark-brown beads, taller than wide, set into the sides of the face and
## standing a little proud of it. No whites, lids or lashes on the sheet; one small soft
## catch-light high on each.
func _kangaroo_eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _k_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2]
		var up: Vector3 = f[3]
		var frame := Basis(out, up, n)
		var c := s - n * 0.7 * KK
		g.color = K_EYE
		g.ellipsoid(c, K_EYE_R * KK, frame, 36, 18)
		var w := Vector2(-0.6, 3.6)
		var h := K_EYE_R.z * sqrt(maxf(1.0 - pow(w.x / K_EYE_R.x, 2.0) - pow(w.y / K_EYE_R.y, 2.0), 0.0))
		g.color = K_GLINT
		g.ellipsoid(c + (out * w.x + up * w.y + n * (h + 0.05)) * KK, Vector3(1.3, 1.3, 0.3) * KK, frame, 16, 8)
	return _to_model(g)


## Mouth: a line down from the nose that splits into two shallow smiling curves wrapping
## round the snout, each ending in a small upturned corner.
func _kangaroo_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	# Nose: a rounded brown triangle capping the tip of the snout, wide at the top.
	g.color = K_NOSE
	g.ellipsoid(Q(589.5, 461.5), Vector3(7.5, 6.0, 11.8) * KK, Basis(), 28, 14)
	g.ellipsoid(Q(590.5, 464.8), Vector3(6.0, 6.2, 7.6) * KK, Basis(), 24, 12)
	g.color = K_MOUTH
	var drop := []
	var drop_w := []
	for y in [473.5, 476.0, 479.0, 482.0]:
		var h := _hit(Q(540, y), Vector3(1, 0, 0))
		drop.append(h[0] + h[1] * 0.2 * KK)
		drop_w.append(Vector2(0.8, 0.8) * KK)
	g.loft(drop, drop_w, Vector3(0, 0, 1), 6)
	var heights := [482.0, 484.3, 485.2, 483.6, 479.6, 474.6, 472.4]
	for side in [-1.0, 1.0]:
		var curve := []
		var widths := []
		for i in 25:
			var t := i / 20.0                    # 1 = mouth corner, beyond it the upturned tick
			var fi := t * 5.0
			var i0 := mini(int(fi), 5)
			var y := lerpf(heights[i0], heights[i0 + 1], fi - i0)
			var th: float = side * minf(t, 1.08) * deg_to_rad(64.0)
			var from := Q(622, y) + Vector3(-cos(th), 0.0, sin(th)) * 70.0 * KK
			var h := _hit(from, Vector3(cos(th), 0.0, -sin(th)))
			curve.append(h[0] + h[1] * 0.2 * KK)
			var w := (0.95 - 0.5 * maxf(t - 0.7, 0.0)) * KK
			widths.append(Vector2(w, w))
		g.loft(curve, widths, Vector3.UP, 6)
	return _to_model(g)


## Meshes are built DETAIL times too large (see the header): bring one down to size.
static func _shrunk(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] = verts[i] / DETAIL
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	_body.clear(); _mane.clear(); _tuft.clear(); _ears.clear(); _tints.clear()
	_shape()
	var root := Node3D.new()
	root.name = "KangarooClayDisplay"
	root.set_meta("source", "User's Kangaroo Character Blueprint, relax walk pose (11 Nov 2026)")
	var clay := _material(0.88)
	for part in [["Body", _body, K_TOE_CREASE], ["Ears", _ears, ORANGE]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		var mesh := _mesh(part[1], part[2], 7.0)
		if part[0] == "Body":
			mesh = _paint(mesh)
		mi.mesh = _shrunk(mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _shrunk(_kangaroo_eyes())
	eyes.material_override = _material(0.2)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _shrunk(_kangaroo_details())
	face.material_override = _material(0.7)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal); the tail
	# trails outside it.
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(Q(585, KY, -72)) / DETAIL
	var c := to_model(Q(830, KTOP, 72)) / DETAIL
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
