extends "res://tools/clay_rig_common.gd"
## Builds the rigged clay flamingo (16 Nov 2026) from the finished display
## scenes/animals/flamingo_clay.tscn into scenes/animals/flamingo_clay_rigged.scn (meshes and
## skin in scenes/animals/clay_meshes/flamingo_rig/): a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) with a slow stride for scripts/characters/clay_animator.gd:
## long legs that fold backward at the ankle, and an S-neck of two bones that sways.
## Rebuild the display first when the flamingo changes.
##   godot --headless --path . --script res://tools/build_flamingo_clay_rig.gd
## Bone shapes are in the flamingo sheet's pixels like flamingo_clay.gd's shapes (side view: x
## toward the tail, y down; z lateral, + = the flamingo's left) and placed with its V(),
## to_model() and FF; the flamingo script is only read, never changed.

const F := preload("res://scripts/characters/flamingo_clay.gd")


## Sheet pixel -> the display's model space.
static func P(x: float, y: float, z := 0.0) -> Vector3:
	return F.to_model(F.V(x, y, z)) / F.FF


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * F.FK * F.S / F.FF


func display_path() -> String:
	return "res://scenes/animals/flamingo_clay.tscn"


func rig_name() -> String:
	return "FlamingoClayRigged"


func spec(display: Node3D) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": P(960, 345), "shapes": [
			[P(912, 336), P(1012, 347), R(48)], [P(962, 342), P(962, 342), R(56)], [P(978, 326), P(978, 326), R(44)]]},
		# The S-neck: a lower bone from the chest up to the bend, an upper one to the head.
		{"name": "neck_1", "parent": "body", "pivot": P(882, 312), "shapes": [
			[P(881, 314), P(880, 292), R(21)], [P(880, 292), P(890, 276), R(18.5)]]},
		{"name": "neck_2", "parent": "neck_1", "pivot": P(892, 272), "shapes": [
			[P(895, 268), P(910, 252), R(18)], [P(910, 252), P(926, 236), R(19)]]},
		{"name": "head", "parent": "neck_2", "pivot": P(928, 226), "shapes": [
			[P(907, 183), P(907, 183), R(44)], [P(900, 201, 21), P(900, 201, -21), R(24)], [P(930, 212), P(930, 212), R(20)]]},
	]
	# Legs: the feathered thigh and the bare leg to the knobbly ankle on the leg bone, the shin
	# below the ankle on its own bone (it folds backward while the leg swings), the foot level.
	var legs := []
	var thighs := []
	for leg in F.F_LEGS:
		var x: float = leg[0]
		var z: float = leg[1]
		var s := signf(z)
		var side := "l" if z > 0.0 else "r"
		bones.append({"name": "leg_" + side, "parent": "root", "pivot": P(x, 388, z * 0.9),
				"shapes": [[P(x, 392, z * 0.9), P(x, 411, z), R(11)], [P(x, 411, z), P(x + 6.0, 456, z), R(6.5)]]})
		bones.append({"name": "shin_" + side, "parent": "leg_" + side, "pivot": P(x + 6.0, 460, z),
				"shapes": [[P(x + 5.0, 468, z), P(x - 1.0, 538, z), R(6.5)]]})
		bones.append({"name": "foot_" + side, "parent": "shin_" + side, "pivot": P(x - 1.0, 546, z),
				"shapes": [[P(x - 3.0, 552, z), P(x - 48.0, 556.6, z + s * 8.0), R(6)], [P(x - 30.0, 557, z + s * 24.0), P(x - 30.0, 557, z - s * 8.0), R(5)],
						[P(x + 4.0, 554, z), P(x + 4.0, 554, z), R(7)]]})
		legs += ["leg_" + side, "shin_" + side, "foot_" + side]
		thighs.append("leg_" + side)
	return {
		"bones": bones,
		"blend": R(6),
		"parts": {"Body": ["body", "neck_1", "neck_2", "head"] + thighs, "Beak": "head", "Crest": "head",
				"Wings": "body", "Legs": legs},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eye_frames(display)},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.2, "Wings": 0.15, "Legs": 0.3, "Crest": 0.4, "Beak": 0.25},
	}


func settings() -> Dictionary:
	# A slow, high-stepping stride: two legs half a cycle apart, each shin folding back at the
	# ankle as its leg swings forward, feet level; the S-neck sways and the head bobs a little.
	return {
		"legs": PackedStringArray(["leg_l", "leg_r"]),
		"leg_phase": PackedFloat32Array([0.0, 0.5]),
		"lower_legs": PackedStringArray(["shin_l", "shin_r"]),
		"bend_deg": 38.0,
		"feet": PackedStringArray(["foot_l", "foot_r"]),
		"ground_lock": true,
		"leg_length": P(0, 388).distance_to(P(0, F.FY)),
		"swing_deg": 17.0,
		"stride_scale": 0.64,
		"lift": R(6),
		"bob": R(4),
		"roll_deg": 2.0,
		"twist_deg": 2.5,
		"sway": R(4),
		"breath": 0.012,
		"breath_seconds": 3.2,
		"shift_deg": 1.0,
		"head_turn_deg": 30.0,
		"look_gap": Vector2(2.0, 5.0),
		"nod_deg": 3.0,
		"head_bob": R(6),
		"neck": PackedStringArray(["neck_1", "neck_2"]),
		"neck_sway_deg": 5.0,
		"tail_deg": 0.0,
		"ear_deg": 0.0,
		"anim_aabb": AABB(Vector3(-0.35, 0, -0.5), Vector3(0.7, 1.6, 1.0)),
	}
