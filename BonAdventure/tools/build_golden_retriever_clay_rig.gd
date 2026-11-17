extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay golden retriever (16 Nov 2026) from the finished display
## scenes/animals/golden_retriever_clay.tscn into scenes/animals/golden_retriever_clay_rigged.scn:
## a skinned, seam-free skeleton (scripts/characters/clay_rig.gd) with a lively trot, a wagging
## two-bone tail plume and floppy ears for scripts/characters/clay_animator.gd.
## Rebuild the display first when the dog changes.
##   godot --headless --path . --script res://tools/build_golden_retriever_clay_rig.gd
## Bone shapes are in the dog sheet's pixels like golden_retriever_clay.gd's shapes (side view:
## x toward the tail, y down; z lateral, + = the dog's left) and placed with its W(),
## to_model() and FINE. Body, head and legs are one skinned piece; the ears are skinned over the
## head and their own bones; the tail plume over its two bones. The dog script is only read.

const Dog := preload("res://scripts/characters/golden_retriever_clay.gd")


static func M(x: float, y: float, z := 0.0) -> Vector3:
	return Dog.to_model(Dog.W(x, y, z)) / Dog.FINE


static func R(px: float) -> float:
	return M(px, 0).distance_to(M(0, 0))


func rigs() -> Array:
	var dog = Dog.new()
	dog._shape()
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# Torso, shoulders and haunches, the thick neck and the ruff over the chest.
		{"name": "body", "parent": "root", "pivot": M(820, 535), "shapes": [
			[M(740, 538), M(922, 525), R(62)], [M(704, 528), M(704, 528), R(44)],
			[M(724, 470), M(738, 515), R(50)],
			[M(737, 562, 36), M(737, 562, -36), R(36)], [M(912, 556, 38), M(912, 556, -38), R(42)]]},
		{"name": "head", "parent": "body", "pivot": M(728, 448), "shapes": [
			[M(710, 400), M(710, 400), R(46)], [M(688, 430, 25), M(688, 430, -25), R(26)],
			[M(662, 430), M(640, 426), R(28)],
			# The top of the skull under the ears' roots, so a flap bends below its root.
			[M(732, 374, 40), M(732, 374, -40), R(18)]]},
		# The plume, as golden_retriever_clay.gd's tail tube: up from the rump, then curling forward.
		{"name": "tail", "parent": "body", "pivot": M(934, 492), "shapes": [
			[M(936, 491), M(993, 468), R(30)], [M(993, 468), M(1003, 446), R(33)], [M(1000, 494), M(1018, 484), R(26)]]},
		{"name": "tail2", "parent": "tail", "pivot": M(1003, 446), "shapes": [
			[M(1003, 436), M(995, 411), R(24)], [M(995, 411), M(951, 385), R(14)], [M(1028, 452), M(1013, 420), R(19)]]},
	]
	# Ears: flaps hanging from the top of the skull down the cheeks (D_EAR_RUNGS); the pivot at
	# the root, the shape down the hanging part, so the top stays on the head and the rest flops.
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(732, 368, s * 46.0), "shapes": [
			[M(722, 405, s * 58.0), M(723, 460, s * 66.0), R(11)], [M(752, 402, s * 70.0), M(762, 425, s * 76.0), R(11)],
			[M(742, 445, s * 72.0), M(742, 445, s * 72.0), R(11)]]})
	var legs := [["leg_fl", [Vector2(735, 560), Vector2(717, 612), Vector2(683, 662)], Vector2(662, 686), 30.0, 26.0],
			["leg_fr", [Vector2(745, 560), Vector2(762, 615), Vector2(776, 657)], Vector2(771, 685), -30.0, 26.0],
			["leg_bl", [Vector2(920, 558), Vector2(948, 608), Vector2(967, 652)], Vector2(976, 686), 33.0, 28.0],
			["leg_br", [Vector2(900, 562), Vector2(871, 614), Vector2(852, 656)], Vector2(843, 686), -33.0, 28.0]]
	var start_y := 598.0
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
		neutral.append(-lean_deg(pivot, M(l[2].x, Dog.DY, z)))
		length += pivot.y / 4.0
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var f: Array = dog._dog_eye_frame(side[1])
		eyes.append(eye(side[0], Dog.to_model(f[0]) / Dog.FINE, Dog.normal_to_model(f[1]), Dog.normal_to_model(f[3])))
	var spec := {
		"bones": bones,
		"blend": R(9),
		"parts": {"Body": ["body", "head"] + names, "Ears": ["head", "ear_l", "ear_r"], "Tail": ["tail", "tail2"]},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		# The nose has its own material: unskinned on the Head attachment, so the dog stays one
		# skinned surface.
		"on_head": ["Face details", "Nose"],
		"simplify": {"Body": 0.25, "Ears": 0.3, "Tail": 0.3},
	}
	# A lively trot (diagonal pairs), a springy bob, ears flopping in step and a happy wag.
	var settings := {
		"leg_neutral_deg": neutral,
		"keep_feet_down": true,
		"foot_reach": R(28),
		"leg_length": length,
		"swing_deg": 26.0,
		"lift": R(16),
		"bob": R(6),
		"roll_deg": 2.0,
		"nod_deg": 4.0,
		"tail_deg": 24.0,
		"wag_speed": Vector2(5.0, 12.0),
		"tail_lag": 0.7,
		"ear_deg": 11.0,
		"head_turn_deg": 28.0,
	}
	return [{"scene": "res://scenes/animals/golden_retriever_clay.tscn", "out": "res://scenes/animals/golden_retriever_clay_rigged.scn",
			"folder": "res://scenes/animals/clay_meshes/golden_retriever_rig/", "name": "GoldenRetrieverClayRigged",
			"spec": spec, "animator": settings}]

