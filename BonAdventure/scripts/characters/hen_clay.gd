extends "res://scripts/characters/rooster_clay.gd"
## Clay-style hen (24 Nov 2026): the approved clay rooster (rooster_clay.gd) with small changes
## toward the user's "Hen Character Blueprint" (docs/evidence/hen-clay-20261124/reference.png).
## User's direction (24 Nov 2026): follow the rooster's design and tweak it, rather than trace
## the hen sheet from scratch. A static display model, built once by tools/build_hen_clay.gd
## into scenes/animals/hen_clay.tscn.
##
## Same body, head, neck cape, legs, beak and eyes as the rooster (its shapes, eye builder and
## mesher are inherited unchanged). The tweaks:
##   - cream all over like the hen sheet (no orange head, no red-brown saddle);
##   - a smaller, lower comb and smaller wattles;
##   - no eyebrows; a pink blush on each cheek;
##   - wings cream at the top shading to warm brown at the bottom;
##   - a short brown tail fan instead of the long teal sickles;
##   - smaller overall: HEN_H town units to the top of the comb.
## Part names are the rooster's, so a rig built for it would fit.
## Output faces -Z (head), +Y up, ground at y = 0.

const HEN_H := 0.5              # town units to the top of the comb (provisional: the user decides at placement)

const N_CREAM := Color("f5d4ac")
const N_FACE := Color("f8dcb8")
const N_HACKLE := Color("f6d6ae")
const N_HACKLE_LOW := Color("f0cba0")
const N_CREASE := Color("d9b083")
const N_BELLY := Color("f6dab6")
const N_BLUSH := Color("f4b597")
const N_WING_TOP := Color("f6d8b0")
const N_WING := Color("cf8c55")
const N_WING_LOW := Color("b0703f")
const N_WING_CREASE := Color("8f5530")
const N_TAIL := [Color("c4824e"), Color("bb7a47"), Color("b57443"), Color("ad6d3e"), Color("a46639")]
const N_TAIL_CREASE := Color("7e4a27")

## Comb and wattles are drawn this much smaller than the rooster's, about their own roots.
const COMB_K := 0.78
const WATTLE_K := 0.82


## A rooster comb / wattle lobe shrunk by `k` toward `about` (sheet px).
func _small(g: Array, about: Vector2, x: float, y: float, z: float, r: Vector3, col: Color, k: float, kk: float, crease := false, basis := Basis()) -> void:
	de(g, V(about.x + (x - about.x) * k, about.y + (y - about.y) * k, z * k), r * k, col, kk, crease, basis)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Head, neck cape, body and legs: the rooster's shapes, in cream.
	de(b, V(850, 268), Vector3(62, 50, 49), N_CREAM)
	de(b, V(866, 268), Vector3(46, 50, 56), N_CREAM, 10.0)
	for side in [-1.0, 1.0]:
		de(b, V(840, 295, side * 30.0), Vector3(42, 27, 34), N_CREAM, 12.0)
	dc(b, V(848, 284), V(856, 338), 56.0, 79.0, N_CREAM, 14.0)
	de(b, V(856, CAPE_Y), Vector3(CAPE_R.x, 40, CAPE_R.y), N_CREAM, 12.0, false, tilt(CAPE_TILT))
	var torso := []
	de(torso, V(885, 425), Vector3(112, 72, 74), N_BELLY, 20.0)
	de(torso, V(818, 422), Vector3(46, 56, 60), N_BELLY, 20.0)
	de(torso, V(972, 402), Vector3(40, 44, 52), N_BELLY, 20.0)
	de(torso, V(880, 462), Vector3(78, 34, 62), N_BELLY, 18.0)
	b.append_array(torso)
	_hackle()
	for side in [-1.0, 1.0]:
		var z: float = side * R_LEG_Z
		de(b, V(R_LEG_X, 482, z), Vector3(16, 10, 16), N_BELLY, 8.0)
	for side in [-1.0, 1.0]:
		var z: float = side * R_LEG_Z
		dc(b, V(R_LEG_X, 484, z), V(R_LEG_X, 522, z), 10.0, 9.0, R_LEG)
		for toe in [[-52.0, 0.0, 8.5], [-46.0, 21.0, 8.0], [-46.0, -19.0, 8.0], [17.0, 0.0, 7.0]]:
			dc(b, V(R_LEG_X - 2.0, 526.5, z), V(R_LEG_X + toe[0], 528.0, z + side * toe[1]), 9.0, toe[2], R_LEG, 4.0)
		de(b, V(R_LEG_X - 8.0, 525, z), Vector3(15, 8, 13), R_LEG, 4.0)
	carve(b, V(R_LEG_X - 20.0, RY + 40.0, 0.0), Vector3(400, 40, 400) * RK, R_LEG)

	# Paint: the paler face, and a pink blush on each cheek below and behind the eye.
	_tint(V(792, 272), Vector3(34, 44, 50) * RK, Basis(), N_FACE, CELL * 5.0)
	for side in [-1.0, 1.0]:
		var hit := _ray(_body, V(640, 290, side * 44.0), Vector3(1, 0, 0))
		_tint(hit[0], Vector3(11, 9, 11) * RK, Basis(), N_BLUSH, 10.0 * RK)

	# Beak: the rooster's.
	var m := _beak
	dc(m, V(800, 272.0, 0.0), V(759.0, 281.5), 12.5, 4.6, R_BEAK)
	for side in [-1.0, 1.0]:
		dc(m, V(800, 280.5, side * 12.0), V(760.0, 283.0), 12.5, 4.4, R_BEAK, 5.0)
	for side in [-1.0, 1.0]:
		carve(m, V(790, 286.0 + 60.0, side * MOUTH_Z), Vector3(260, 60, MOUTH_R) * RK, R_BEAK)
	for side in [-1.0, 1.0]:
		dc(_beak_low, V(800, 289.0, side * 8.0), V(767, 288.0), 10.0, 3.8, R_BEAK_LOW)
	de(m, V(759.0, 285.3), Vector3(5, 3.0, 5.0), R_BEAK)

	# Comb: the rooster's four lobes, smaller and sunk a little lower about the crown.
	var c := _comb
	var crown := Vector2(860, 238)
	_small(c, crown, 852, 226, 0.0, Vector3(54, 15, 14), R_COMB, COMB_K, 0.0, false, tilt(-0.06))
	_small(c, crown, 803, 228, 0.0, Vector3(13, 15, 10.5), R_COMB, COMB_K, 6.0)
	_small(c, crown, 811, 201, 0.0, Vector3(24, 29, 15), R_COMB, COMB_K, 1.5, true, tilt(-0.25))
	_small(c, crown, 856, 189, 0.0, Vector3(26, 36, 17), R_COMB, COMB_K, 1.5, true)
	_small(c, crown, 894, 196, 0.0, Vector3(23, 32, 17), R_COMB, COMB_K, 1.5, true, tilt(0.3))
	_small(c, crown, 917, 222, 0.0, Vector3(16, 25, 15), R_COMB, COMB_K, 1.5, true, tilt(0.25))
	for side in [-1.0, 1.0]:
		_small(c, crown, 872, 217, side * 14.0, Vector3(32, 15, 13), R_COMB, COMB_K, 5.0)

	# Wattles: the rooster's two teardrops, smaller, hanging from under the beak.
	var root := Vector2(794, 298)
	for side in [-1.0, 1.0]:
		var a := V(794, 298, side * 5.0)
		var tip := V(root.x + (783 - root.x) * WATTLE_K, root.y + (324 - root.y) * WATTLE_K, side * 15.5 * WATTLE_K)
		dc(_wattles, a, tip, 8.5 * WATTLE_K, 15.0 * WATTLE_K, R_WATTLE)
		_small(_wattles, root, 781, 330, side * 16.5, Vector3(19, 19.5, 17.5), R_WATTLE, WATTLE_K, 8.0, true)

	_wing_feathers(torso)
	_tail_feathers()


## Neck feathers: the rooster's two rows of tongues, in cream.
func _hackle() -> void:
	for row in 2:
		var count := 14
		for i in count:
			var th := TAU * (i + 0.5 * row) / count
			var front := maxf(cos(th), 0.0)
			var radial := Vector3(-cos(th), 0.0, sin(th))
			var long := 27.0 - (i % 2) * 6.0 - row * 5.0
			var y := CAPE_Y + CAPE_R.x * sin(CAPE_TILT) * cos(th) + 34.0 + 8.0 * front * front - long - row * 13.0
			var inset := 7.0 - row * 2.5
			var dir := (Vector3(0, -1, 0) + radial * 0.3).normalized()
			var nrm := dir.cross(Vector3(sin(th), 0.0, cos(th))).normalized()
			if nrm.dot(radial) < 0.0: nrm = -nrm
			de(_body, V(856.0 - (CAPE_R.x - inset) * cos(th), y, (CAPE_R.y - inset) * sin(th)),
					Vector3(long, 15.5 - row * 2.0, 5.5 + (i % 2) * 1.5 - row),
					N_HACKLE_LOW if row == 0 else N_HACKLE, 1.5, row == 0, Basis(dir, nrm.cross(dir).normalized(), nrm))


## Wings: the rooster's pad and lobes, shaded cream along the top to warm brown at the bottom
## (the hen sheet's cream coverts over brown flight feathers).
func _wing_feathers(torso: Array) -> void:
	for side in [-1.0, 1.0]:
		var pad := []
		for f in [[905, 410, Vector3(60, 44, 20.0), -0.05, 0.0, 0.0], [893, 402, Vector3(66, 52, 19.0), -0.05, 7.0, 12.0], [952, 412, Vector3(52, 37, 17.0), -0.12, 8.0, 14.0],
				[992, 426, Vector3(17, 13, 11.0), -0.2, 9.0, 8.0]]:
			var hit := _ray(torso, V(f[0], f[1], side * 240.0), Vector3(0, 0, -side))
			var a: float = f[3]
			_lay(pad, hit, Vector3(cos(a), sin(a), 0.0), f[2], N_WING, f[4], 0.0, f[5], false)
		_wings.append_array(pad)
		for f in [[950, 437, Vector3(42, 12.5, 5.0), 0.1], [876, 431, Vector3(28, 15, 5.0), -0.7], [895, 411, Vector3(34, 17, 5.5), -0.25],
				[915, 385, Vector3(36, 18, 5.5), 0.05]]:
			var hit := _ray(pad, V(f[0], f[1], side * 300.0), Vector3(0, 0, -side))
			var a: float = f[3]
			_lay(_wings, hit, Vector3(cos(a), sin(a), 0.0), f[2], N_WING, -1.8, 0.0, 3.0, true)
	_wing_tints.append({"t": "ell", "c": V(905, 338), "r": Vector3(260, 66, 260) * RK, "inv": Basis(), "col": N_WING_TOP, "soft": 30.0 * RK})
	_wing_tints.append({"t": "ell", "c": V(915, 500), "r": Vector3(260, 62, 260) * RK, "inv": Basis(), "col": N_WING_LOW, "soft": 40.0 * RK})


## Tail: the rooster's sickle feathers cut short before they curl over, with round ends, so
## they stand as a small upright brown fan off the rump, the hen's rounded tail.
func _tail_feathers() -> void:
	_blade([Vector3(978, 372, 0), Vector3(1005, 330, 0), Vector3(1035, 300, 0), Vector3(1062, 292, 0)],
			[18, 22, 22, 16], [30, 40, 40, 28], N_TAIL[1])
	for side in [-1.0, 1.0]:
		_blade([Vector3(985, 388, side * 18), Vector3(1020, 356, side * 30), Vector3(1052, 334, side * 40), Vector3(1080, 330, side * 44)],
				[16, 20, 20, 15], [26, 32, 32, 24], N_TAIL[2])
		_blade([Vector3(992, 402, side * 14), Vector3(1030, 386, side * 26), Vector3(1064, 380, side * 34), Vector3(1088, 386, side * 36)],
				[14, 18, 18, 13], [20, 26, 26, 20], N_TAIL[3])
	_blade([Vector3(995, 414, 0), Vector3(1030, 414, 0), Vector3(1060, 420, 0), Vector3(1078, 430, 0)],
			[12, 15, 15, 11], [18, 22, 20, 16], N_TAIL[4])


# --- Face details -------------------------------------------------------------------------

## The rooster's upper lids, nostrils and mouth line; no eyebrows (the hen sheet has none).
func _rooster_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var f := _rooster_eye_frame(side)
		var s: Vector3 = f[0]
		var n: Vector3 = f[1]
		var out: Vector3 = f[2] * side
		var up: Vector3 = f[3]
		g.color = R_LID
		var rim_h := 0.0
		for q in [Vector2(R_EYE_R.x, 0), Vector2(-R_EYE_R.x, 0), Vector2(0, R_EYE_R.y), Vector2(0, -R_EYE_R.y)]:
			rim_h += (_rdrop(s + (f[2] * q.x + up * q.y) * RK, n, 0.0) - s).dot(n) / RK * 0.25
		var lid := []
		var lid_w := []
		for i in 25:
			var t := i / 24.0
			var a := lerpf(deg_to_rad(152.0), deg_to_rad(-14.0), t)
			var w := lerpf(1.0, 3.0, smoothstep(0.0, 0.7, t)) * lerpf(1.0, 0.55, smoothstep(0.85, 1.0, t))
			var q := _rim(a, 0.2)
			lid.append(s + (out * q.x + up * q.y + n * (rim_h + 0.3)) * RK)
			lid_w.append(Vector2(w, 2.0) * RK)
		g.loft(lid, lid_w, n, 8)
		var hit := _ray(_beak, V(784.0, 200, side * 11.0), Vector3(0, -1, 0))
		var bn: Vector3 = hit[1]
		var along := (Vector3(1, 0.35, 0) - bn * bn.dot(Vector3(1, 0.35, 0))).normalized()
		g.color = R_NOSTRIL
		g.ellipsoid(hit[0] + bn * 0.1 * RK, Vector3(2.4, 1.3, 0.5) * RK, Basis(along, bn.cross(along).normalized(), bn), 16, 8)
	g.color = R_MOUTH
	var both: Array = _beak + _beak_low
	var line := []
	var line_w := []
	for i in 33:
		var t := deg_to_rad(lerpf(-78.0, 78.0, i / 32.0))
		var y := 286.6
		var at := []
		for pass_i in 2:
			var from := V(797.0 - 90.0 * cos(t), y, 90.0 * sin(t))
			at = _ray(both, from, V(797, y) - from)
			y = _mouth_y(at[0].z / RK) + 0.6
		line.append(at[0] + at[1] * 0.25 * RK)
		line_w.append(Vector2(0.75, 0.6) * RK)
	g.loft(line, line_w, Vector3.UP, 6)
	return _to_model(g)


# --- Scene --------------------------------------------------------------------------------

## Scales a mesh about the model origin.
static func _scaled(mesh: ArrayMesh, k: float) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] *= k
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _muzzle_tints, _beak, _beak_low, _comb, _wattles, _wings, _wing_tints, _tail]:
		group.clear()
	_shape()
	var k := HEN_H / RH          # the rooster's size -> the hen's
	var root := Node3D.new()
	root.name = "HenClayDisplay"
	root.set_meta("source", "Clay rooster tweaked toward the user's Hen Character Blueprint (24 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, N_CREASE, 2.2], ["Beak", _beak, R_BEAK_CREASE, 5.0], ["Beak lower", _beak_low, R_BEAK_CREASE, 5.0], ["Comb", _comb, R_COMB_CREASE, 4.0],
			["Wattles", _wattles, R_COMB_CREASE, 4.0], ["Wings", _wings, N_WING_CREASE, 2.2], ["Tail", _tail, N_TAIL_CREASE, 3.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		elif part[0] == "Wings":
			var body_tints := _tints
			_tints = _wing_tints
			mi.mesh = _paint(mi.mesh)
			_tints = body_tints
		mi.mesh = _scaled(_fit(mi.mesh), k)
		mi.material_override = clay
		root.add_child(mi)
	var eye_material := _material(0.3)
	for eye in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var mi := MeshInstance3D.new()
		mi.name = eye[0]
		mi.mesh = _scaled(_rooster_eye(eye[1]), k)
		var t := _rooster_eye_transform(eye[1])
		mi.transform = Transform3D(t.basis, t.origin * k)
		mi.material_override = eye_material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _scaled(_rooster_details(), k)
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(V(754, RY, -105)) / RF * k
	var c := to_model(V(1100, RTOP + 20.0, 105)) / RF * k
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
