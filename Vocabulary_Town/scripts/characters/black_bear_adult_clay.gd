extends "res://scripts/characters/black_bear_clay.gd"
## Adult clay black bear: the clay bear cub (black_bear_clay.gd: same head, face, ears, chest
## chevron and colours, traced from the user's "Black Bear Character Blueprint") with the body
## reshaped against the sheet's side and three-quarter views (user, 11 Nov 2026) and built
## larger. Built once by tools/build_black_bear_adult_clay.gd into
## scenes/animals/black_bear_adult_clay.tscn. A static display, not a park_animals.gd species.
## Output faces -Z (head), +Y up, ground at y = 0.

const ADULT_H := 2.1             # town units to the ear tops (the cub is BH = 1.5)


## A leg: a round column through `joints` (sheet x, y) at lateral z, tapering from r_top to
## r_bottom at the ankle, into a broad low paw centred at sheet x `paw_x` with four toe knuckles
## and a cream claw under each. The paw's underside is cut flat at the sole.
func _aleg(joints: Array, z: float, r_top: float, r_bottom: float, paw_x: float) -> void:
	for i in joints.size() - 1:
		var p0: Vector2 = joints[i]
		var p1: Vector2 = joints[i + 1]
		var r0 := lerpf(r_top, r_bottom, float(i) / (joints.size() - 1))
		var r1 := lerpf(r_top, r_bottom, float(i + 1) / (joints.size() - 1))
		cone(_body, T(p0.x, p0.y, z), T(p1.x, p1.y, z), r0 * BK, r1 * BK, B_FUR, (18.0 if i == 0 else 8.0) * BK)
	var paw := Vector3(46.0, 21.0, 44.0)
	var pc := T(paw_x, BGY - 17.0, z)
	be(_body, pc, paw, B_FUR, 9.0)
	for o in [-20.0, -6.7, 6.7, 20.0]:
		var front: float = paw.x * sqrt(1.0 - pow(o / paw.z, 2.0))
		be(_body, pc + Vector3(-front + 5.0, 1.0, o) * BK, Vector3(10.0, 11.0, 7.6), B_FUR, 3.0)
		be(_claws, pc + Vector3(-front - 2.0, -7.0, o) * BK, Vector3(6.0, 8.0, 4.4), B_CLAW, 0.0, false,
				Basis(Vector3(0, 0, 1), deg_to_rad(-18.0)))
	carve(_body, T(paw_x, BGY + 60.0, z), Vector3(200, 60, 200) * BK, B_FUR)


## The adult keeps the sheet's fur colour.
func _fur() -> Color:
	return B_FUR


## The adult keeps the face as traced from the sheet.
func _face_youth() -> float:
	return 0.0


## The adult keeps the sheet's full-size body (the cub shrinks its own).
func _body_squash() -> Vector3:
	return Vector3.ONE


## Pear-shaped torso, round shoulders and hips, tapering legs (replaces the cub's body).
func _torso_and_legs() -> void:
	var b := _body
	# Torso, pear-shaped: a deep rib cage, a fuller, wider belly behind it hanging to a gentle
	# curve, and a round rump. The back rises softly over the shoulders and rolls down to the tail.
	be(b, T(930, 374), Vector3(100, 104, 104), B_FUR)
	be(b, T(1025, 387), Vector3(106, 100, 128), B_FUR, 36.0)
	be(b, T(1078, 408), Vector3(74, 100, 110), B_FUR, 36.0)
	be(b, T(872, 404), Vector3(68, 76, 94), B_FUR, 32.0)                    # chest
	be(b, T(915, 300), Vector3(75, 68, 95), B_FUR, 30.0, true)
	be(b, T(975, 318), Vector3(70, 40, 85), B_FUR, 30.0)                    # withers: one line from the neck down to the back
	# Shoulders: broad and round, melted into the rib cage. Hips: a full round thigh each side.
	for side in [-1.0, 1.0]:
		be(b, T(902, 384, side * 60.0), Vector3(62, 82, 60), B_FUR, 40.0)
		be(b, T(1090, 430, side * 60.0), Vector3(64, 84, 68), B_FUR, 30.0)
	# Tail: a round ball on the rump.
	be(b, T(1141, 351), Vector3(20, 25, 26), B_FUR, 4.0)

	# Legs, relaxed walk: near front and near hind planted, far front stepping forward, far
	# hind under the belly. Each tapers from the shoulder or thigh to the ankle.
	_aleg([Vector2(922, 420), Vector2(914, 506)], 64.0, 53.0, 48.0, 906.0)
	_aleg([Vector2(890, 420), Vector2(852, 466), Vector2(828, 506)], -64.0, 51.0, 47.0, 819.0)
	_aleg([Vector2(1098, 440), Vector2(1108, 478), Vector2(1103, 507)], 66.0, 55.0, 49.0, 1100.0)
	_aleg([Vector2(1072, 445), Vector2(1048, 478), Vector2(1030, 507)], -66.0, 53.0, 48.0, 1023.0)




## The cub's scene with this body, enlarged to ADULT_H (meshes and footprint, not a node scale).
func build_display() -> Node3D:
	var root := super.build_display()
	root.name = "BlackBearAdultClayDisplay"
	var f := ADULT_H / BH
	for mi in root.find_children("*", "MeshInstance3D", false, false):
		var mesh: ArrayMesh = mi.mesh
		var grown := ArrayMesh.new()
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for i in verts.size():
				verts[i] *= f
			arrays[Mesh.ARRAY_VERTEX] = verts
			grown.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi.mesh = grown
	var shape: CollisionShape3D = root.get_node("Footprint").get_child(0)
	(shape.shape as BoxShape3D).size *= f
	shape.position *= f
	return root
