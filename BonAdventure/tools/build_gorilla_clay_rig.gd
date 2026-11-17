extends "res://tools/clay_rig_common.gd"
## Builds the rigged clay gorilla (16 Nov 2026) from the finished display
## scenes/animals/gorilla_clay.tscn into scenes/animals/gorilla_clay_rigged.scn (meshes and skin
## in scenes/animals/clay_meshes/gorilla_rig/): a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) with a knuckle-walk for scripts/characters/clay_animator.gd.
## Rebuild the display first when the gorilla changes.
##   godot --headless --path . --script res://tools/build_gorilla_clay_rig.gd
## Bone shapes are in the gorilla sheet's pixels like gorilla_clay.gd's shapes (side view: x
## toward the rump, y down; z lateral, + = the gorilla's left) and placed with its Q() and
## to_model(); the gorilla script is only read, never changed.

const G := preload("res://scripts/characters/gorilla_clay.gd")

## Limbs as [bone, shoulder or hip, end of the column, hand or foot pivot, hand or foot centre,
## column radius, hand or foot radius, the hand or foot's own name]; z + = the gorilla's left.
const LIMBS := [
	["arm_l", [1006, 318, 100], [976, 508, 84], [972, 520, 82], [960, 542, 76], 56.0, 34.0, "hand_l"],
	["arm_r", [936, 322, -100], [869, 510, -86], [868, 520, -84], [862, 542, -78], 56.0, 34.0, "hand_r"],
	["leg_l", [1132, 420, 52], [1152, 518, 52], [1152, 532, 52], [1140, 551, 52], 54.0, 20.0, "foot_l"],
	["leg_r", [1100, 424, -52], [1068, 518, -52], [1067, 532, -52], [1052, 551, -52], 52.0, 20.0, "foot_r"],
]


## Sheet pixel -> the display's model space.
static func P(x: float, y: float, z := 0.0) -> Vector3:
	return G.to_model(G.Q(x, y, z))


static func PA(a: Array) -> Vector3:
	return P(a[0], a[1], a[2])


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * G.M * G.S


func display_path() -> String:
	return "res://scenes/animals/gorilla_clay.tscn"


func rig_name() -> String:
	return "GorillaClayRigged"


func spec(display: Node3D) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": P(1040, 370), "shapes": [
			[P(960, 340), P(1100, 390), R(88)], [P(905, 378, 27), P(905, 378, -27), R(34)],
			[P(1150, 420, 46), P(1150, 420, -46), R(50)], [P(1022, 430), P(1022, 430), R(42)]]},
		{"name": "head", "parent": "body", "pivot": P(985, 285), "shapes": [
			[P(935, 255), P(932, 210), R(72)], [P(862, 297), P(862, 297), R(42)], [P(845, 258), P(845, 258), R(16)]]},
	]
	var legs := []
	for limb in LIMBS:
		var top := PA(limb[1])
		var end := PA(limb[2])
		bones.append({"name": limb[0], "parent": "root", "pivot": top,
				# The column stops its own radius above the wrist or ankle, so the hand or foot
				# (kept level) is not pulled round with the swing.
				"shapes": [[top.lerp(end, 0.25), end + Vector3.UP * R(limb[5] * 0.8), R(limb[5])]]})
		var foot: Array = limb[4]
		bones.append({"name": limb[7], "parent": limb[0], "pivot": PA(limb[3]),
				"shapes": [[P(foot[0] - 30.0, foot[1], foot[2]), P(foot[0] + 22.0, foot[1], foot[2]), R(limb[6])]]})
		legs.append(limb[0])
		legs.append(limb[7])
	return {
		"bones": bones,
		"blend": R(14),
		"parts": {"Body": ["body", "head"] + legs, "Crest": "head", "Ears": "head"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eye_frames(display)},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.2, "Crest": 0.3, "Ears": 0.3},
	}


## Each limb's rest angle in the side view (+ = the hand or foot forward of its shoulder or hip).
static func rest_angle(limb: Array) -> float:
	var top: Array = limb[1]
	var foot: Array = limb[4]
	return rad_to_deg(atan2(top[0] - foot[0], foot[1] - top[1]))


func settings() -> Dictionary:
	# Knuckle-walk: a lateral sequence (left leg, left arm, right leg, right arm, a quarter
	# cycle apart); arms and legs swing about the mean of each pair (the display stands
	# mid-stride, right limbs forward), hands and feet stay flat, and the shoulders roll and
	# turn with the step.
	var neutral := PackedFloat32Array()
	for pair in [[0, 1], [2, 3]]:
		var mean := (rest_angle(LIMBS[pair[0]]) + rest_angle(LIMBS[pair[1]])) * 0.5
		for k in pair:
			neutral.append(mean - rest_angle(LIMBS[k]))
	return {
		"legs": PackedStringArray(["arm_l", "arm_r", "leg_l", "leg_r"]),
		"leg_phase": PackedFloat32Array([0.25, 0.75, 0.0, 0.5]),
		"leg_neutral_deg": neutral,
		"feet": PackedStringArray(["hand_l", "hand_r", "foot_l", "foot_r"]),
		"ground_lock": true,
		"leg_length": P(0, 330).distance_to(P(0, G.GOR_Y)),
		"swing_deg": 15.0,
		"stride_scale": 0.64,
		"lift": R(14),
		"bob": R(6),
		"roll_deg": 4.0,
		"twist_deg": 5.0,
		"sway": R(8),
		"breath": 0.01,
		"breath_seconds": 3.4,
		"shift_deg": 1.2,
		"head_turn_deg": 28.0,
		"nod_deg": 2.5,
		"tail_deg": 0.0,
		"ear_deg": 0.0,
		"anim_aabb": AABB(Vector3(-0.9, 0, -1.1), Vector3(1.8, 2.3, 2.2)),
	}
