extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay panda (16 Nov 2026) from the finished display
## scenes/animals/panda_clay.tscn into scenes/animals/panda_clay_rigged.scn: a skinned, seam-free
## skeleton (scripts/characters/clay_rig.gd) with a heavy, rolling walk for
## scripts/characters/clay_animator.gd. Rebuild the display first when the panda changes.
##   godot --headless --path . --script res://tools/build_panda_clay_rig.gd
## Bone shapes are in the panda sheet's pixels like panda_clay.gd's shapes (side view: x toward
## the tail, y down; z lateral, + = the panda's left) and placed with its Q() and to_model().
## The head is its own mesh on the sheet and in the display, so it rides the head bone whole;
## the body, legs and tail are one skinned piece. panda_clay.gd is only read, never changed.

const Panda := preload("res://scripts/characters/panda_clay.gd")


static func M(x: float, y: float, z := 0.0) -> Vector3:
	return Panda.to_model(Panda.Q(x, y, z))


static func R(px: float) -> float:
	return M(px, 0).distance_to(M(0, 0))


func rigs() -> Array:
	var panda = Panda.new()
	panda._shape()
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(1070, 400), "shapes": [
			[M(1010, 395), M(1105, 400), R(80)], [M(1135, 420), M(1135, 420), R(66)]]},
		{"name": "head", "parent": "body", "pivot": M(948, 352), "shapes": [[M(897, 330), M(897, 330), R(95)]]},
		{"name": "tail", "parent": "body", "pivot": M(1168, 408), "shapes": [[M(1181, 404), M(1181, 414), R(18)]]},
	]
	# Legs as panda_clay.gd's _pleg: [name, joints, paw, z, radius]; the shape runs from under the
	# torso (above it the shoulder and thigh go with the body) to the paw.
	var legs := [["leg_fl", [Vector2(1008, 400), Vector2(1008, 500)], Vector2(1003, 518), 58.0, 42.0],
			["leg_fr", [Vector2(1000, 405), Vector2(940, 462), Vector2(893, 503)], Vector2(868, 518), -58.0, 42.0],
			["leg_bl", [Vector2(1152, 450), Vector2(1166, 503)], Vector2(1168, 518), 56.0, 44.0],
			["leg_br", [Vector2(1140, 450), Vector2(1092, 500)], Vector2(1078, 518), -56.0, 44.0]]
	var start_y := 470.0
	var names := []
	var neutral := PackedFloat32Array()
	var length := 0.0
	for l in legs:
		var joints: Array = l[1]
		var z: float = l[3]
		var top := chain_at(joints, start_y)
		var pts := [M(top.x, top.y, z)]
		for j in joints:
			if j.y > start_y:
				pts.append(M(j.x, j.y, z))
		pts.append(M(l[2].x, l[2].y, z))
		var pivot := M(joints[0].x, joints[0].y, z)
		bones.append(leg(l[0], pivot, pts, R(l[4])))
		names.append(l[0])
		neutral.append(-lean_deg(pivot, M(l[2].x, Panda.PY, z)))
		length += pivot.y / 4.0
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var f: Array = panda._panda_eye_frame(side[1])
		var n: Vector3 = f[1]
		var at: Vector3 = f[0] - n * 1.6 * Panda.PK
		eyes.append(eye(side[0], Panda.to_model(at), Panda.normal_to_model(n), Panda.normal_to_model(f[3])))
	var spec := {
		"bones": bones,
		"blend": R(12),
		"parts": {"Body": ["body", "tail"] + names, "Head": "head", "Ears": "head"},
		# The dark outline and lid line round each eye (in Face details) close with the eye.
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes, "lids": {"mesh": "Face details", "reach": R(21)}},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.25, "Head": 0.25, "Ears": 0.3},
	}
	# A heavy, rolling walk like the bears': a lateral walk, the body rolling over the planted side.
	var settings := {
		"leg_phase": PackedFloat32Array([0.25, 0.75, 0.0, 0.5]),
		"leg_neutral_deg": neutral,
		"keep_feet_down": true,
		"foot_reach": R(44),
		"leg_length": length,
		"swing_deg": 17.0,
		"lift": R(12),
		"bob": R(4),
		"roll_deg": 5.0,
		"nod_deg": 2.5,
		"shift_deg": 1.8,
		"tail_deg": 9.0,
		"ear_deg": 0.0,
		"head_turn_deg": 24.0,
	}
	return [{"scene": "res://scenes/animals/panda_clay.tscn", "out": "res://scenes/animals/panda_clay_rigged.scn",
			"folder": "res://scenes/animals/clay_meshes/panda_rig/", "name": "PandaClayRigged",
			"spec": spec, "animator": settings}]

