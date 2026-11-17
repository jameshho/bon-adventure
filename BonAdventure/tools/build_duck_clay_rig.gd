extends "res://tools/clay_rig_common.gd"
## Builds the rigged clay duck (16 Nov 2026) from the finished display
## scenes/animals/duck_clay.tscn into scenes/animals/duck_clay_rigged.scn (meshes and skin in
## scenes/animals/clay_meshes/duck_rig/): a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) that waddles with scripts/characters/clay_animator.gd.
## Rebuild the display first when the duck changes.
##   godot --headless --path . --script res://tools/build_duck_clay_rig.gd
## Bone shapes are in the duck sheet's pixels like duck_clay.gd's shapes (side view: x toward
## the tail, y down; z lateral, + = the duck's left) and placed with its V(), to_model() and DF;
## the duck script is only read, never changed.

const D := preload("res://scripts/characters/duck_clay.gd")


## Sheet pixel -> the display's model space.
static func P(x: float, y: float, z := 0.0) -> Vector3:
	return D.to_model(D.V(x, y, z)) / D.DF


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * D.DK * D.S / D.DF


func display_path() -> String:
	return "res://scenes/animals/duck_clay.tscn"


func rig_name() -> String:
	return "DuckClayRigged"


func spec(display: Node3D) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": P(955, 430), "shapes": [
			[P(905, 405), P(1020, 412), R(66)], [P(952, 459), P(952, 459), R(46)]]},
		{"name": "head", "parent": "body", "pivot": P(900, 345), "shapes": [
			[P(901, 268), P(901, 268), R(62)], [P(906, 286, 32), P(906, 286, -32), R(42)]]},
		{"name": "tail", "parent": "body", "pivot": P(1055, 395), "shapes": [[P(1064, 392), P(1085, 390), R(18)]]},
	]
	# Legs (a separate mesh): the stalk on the leg bone, the webbed foot on its own bone kept
	# level with the ground.
	var legs := []
	for leg in D.D_LEGS:
		var x: float = leg[0]
		var z: float = leg[1]
		var s := signf(z)
		var side := "l" if z > 0.0 else "r"
		bones.append({"name": "leg_" + side, "parent": "root", "pivot": P(x, 482, z),
				"shapes": [[P(x, 488, z), P(x + 2.0, 530, z + s * 2.0), R(13)]]})
		bones.append({"name": "foot_" + side, "parent": "leg_" + side, "pivot": P(x + 1.0, 537, z + s * 2.0),
				"shapes": [[P(x - 4.0, 543, z + s * 4.0), P(x - 46.0, 545, z + s * 10.0), R(10)],
						[P(x - 30.0, 545, z + s * 22.0), P(x - 30.0, 545, z - s * 6.0), R(8)]]})
		legs += ["leg_" + side, "foot_" + side]
	return {
		"bones": bones,
		"blend": R(9),
		"parts": {"Body": ["body", "head"], "Bill": "head", "Bill lower": "head", "Crest": "head",
				"Wings": "body", "Tail": "tail", "Legs": legs},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eye_frames(display)},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.08, "Wings": 0.12, "Crest": 0.15, "Tail": 0.15, "Legs": 0.2, "Bill": 0.15, "Bill lower": 0.15},
	}


func settings() -> Dictionary:
	# A waddle: two legs half a cycle apart, the body rolling over the standing leg and turning
	# with it, the tail wagging, the head bobbing forward in step; webbed feet stay flat.
	return {
		"legs": PackedStringArray(["leg_l", "leg_r"]),
		"leg_phase": PackedFloat32Array([0.0, 0.5]),
		"feet": PackedStringArray(["foot_l", "foot_r"]),
		"ground_lock": true,
		"leg_length": P(0, 482).distance_to(P(0, D.DY)),
		"swing_deg": 26.0,
		"stride_scale": 0.64,
		"lift": R(10),
		"bob": R(4),
		"roll_deg": 9.0,
		"twist_deg": 7.0,
		"sway": R(10),
		"breath": 0.014,
		"breath_seconds": 2.2,
		"shift_deg": 2.0,
		"head_turn_deg": 32.0,
		"look_gap": Vector2(1.5, 4.0),
		"nod_deg": 4.0,
		"head_bob": R(7),
		"tail_deg": 14.0,
		"ear_deg": 0.0,
		"anim_aabb": AABB(Vector3(-0.15, 0, -0.25), Vector3(0.3, 0.5, 0.45)),
	}
