extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay red panda (16 Nov 2026) from the finished display
## scenes/animals/red_panda_clay.tscn into scenes/animals/red_panda_clay_rigged.scn: a skinned,
## seam-free skeleton (scripts/characters/clay_rig.gd) for scripts/characters/clay_animator.gd,
## its long bushy tail a two-bone chain ("tail", "tail2") that swings like a whip.
## Rebuild the display first when the red panda changes.
##   godot --headless --path . --script res://tools/build_red_panda_clay_rig.gd
## Bone shapes are in the red panda sheet's pixels like red_panda_clay.gd's shapes (side view: x
## toward the tail, y down; z lateral, + = the red panda's left), placed with its PR(),
## to_model() and the display's scale PF. Head, body, ears and tail are separate meshes in the
## display: the head and ears ride the head bone whole, the tail is skinned over its two bones,
## and the body and legs are one skinned piece. red_panda_clay.gd is only read, never changed.

const RedPanda := preload("res://scripts/characters/red_panda_clay.gd")


static func M(x: float, y: float, z := 0.0) -> Vector3:
	return RedPanda.to_model(RedPanda.PR(x, y, z)) * RedPanda.PF


static func R(px: float) -> float:
	return M(px, 0).distance_to(M(0, 0))


func rigs() -> Array:
	var panda = RedPanda.new()
	panda._shape()
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(1000, 400), "shapes": [
			[M(935, 408), M(1072, 398), R(55)], [M(1052, 400, 22), M(1052, 400, -22), R(52)]]},
		{"name": "head", "parent": "body", "pivot": M(928, 380), "shapes": [[M(893, 355), M(893, 355), R(82)]]},
		# The tail, as red_panda_clay.gd's: a sausage from the rump (1070, 388) through (1122, 425)
		# to the tip (1172, 462).
		{"name": "tail", "parent": "body", "pivot": M(1068, 388), "shapes": [[M(1070, 388), M(1120, 424), R(38)]]},
		{"name": "tail2", "parent": "tail", "pivot": M(1118, 422), "shapes": [[M(1126, 428), M(1172, 462), R(41)]]},
	]
	var legs := [["leg_fl", [Vector2(942, 428), Vector2(948, 470), Vector2(951, 498)], Vector2(944, 513), 46.0, 28.0],
			["leg_fr", [Vector2(925, 430), Vector2(893, 470), Vector2(871, 493)], Vector2(859, 506), -46.0, 28.0],
			["leg_bl", [Vector2(1066, 420), Vector2(1092, 462), Vector2(1106, 497)], Vector2(1099, 513), 46.0, 30.0],
			["leg_br", [Vector2(1040, 428), Vector2(1028, 466), Vector2(1022, 492)], Vector2(1015, 507), -46.0, 29.0]]
	var start_y := 450.0
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
		neutral.append(-lean_deg(pivot, M(l[2].x, RedPanda.P_GY, z)))
		length += pivot.y / 4.0
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var hit: Array = panda._head_front(RedPanda.P_EYE.x, side[1] * RedPanda.P_EYE.y)
		var n: Vector3 = hit[1]
		var right := Vector3.UP.cross(n).normalized()
		eyes.append(eye(side[0], RedPanda.to_model(hit[0]) * RedPanda.PF, RedPanda.normal_to_model(n),
				RedPanda.normal_to_model(n.cross(right))))
	var spec := {
		"bones": bones,
		"blend": R(10),
		"parts": {"Body": ["body"] + names, "Head": "head", "Ears": "head", "Tail": ["tail", "tail2"]},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.25, "Head": 0.25, "Ears": 0.3, "Tail": 0.5},
	}
	# A quick, light walk (one foot at a time, a little roll) and a slow swing of the tail that
	# bends along its two bones.
	var settings := {
		"leg_phase": PackedFloat32Array([0.25, 0.75, 0.0, 0.5]),
		"leg_neutral_deg": neutral,
		"keep_feet_down": true,
		"foot_reach": R(32),
		"leg_length": length,
		"swing_deg": 22.0,
		"lift": R(11),
		"bob": R(4),
		"roll_deg": 3.0,
		"nod_deg": 3.0,
		"tail_deg": 13.0,
		"wag_speed": Vector2(1.6, 5.5),
		"tail_lag": 1.1,
		"ear_deg": 0.0,
		"head_turn_deg": 26.0,
	}
	return [{"scene": "res://scenes/animals/red_panda_clay.tscn", "out": "res://scenes/animals/red_panda_clay_rigged.scn",
			"folder": "res://scenes/animals/clay_meshes/red_panda_rig/", "name": "RedPandaClayRigged",
			"spec": spec, "animator": settings}]

