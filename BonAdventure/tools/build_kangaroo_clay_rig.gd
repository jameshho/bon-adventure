extends "res://tools/clay_rig_common.gd"
## Builds the rigged clay kangaroo (16 Nov 2026) from the finished display
## scenes/animals/kangaroo_clay.tscn into scenes/animals/kangaroo_clay_rigged.scn (meshes and
## skin in scenes/animals/clay_meshes/kangaroo_rig/): a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) that hops with scripts/characters/clay_animator.gd.
## Rebuild the display first when the kangaroo changes.
##   godot --headless --path . --script res://tools/build_kangaroo_clay_rig.gd
## Bone shapes are in the kangaroo sheet's pixels like kangaroo_clay.gd's shapes (side view: x
## toward the tail, y down; z lateral, + = the kangaroo's left) and placed with its Q(),
## to_model() and DETAIL; the kangaroo script is only read, never changed.

const K := preload("res://scripts/characters/kangaroo_clay.gd")


## Sheet pixel -> the display's model space.
static func P(x: float, y: float, z := 0.0) -> Vector3:
	return K.to_model(K.Q(x, y, z)) / K.DETAIL


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * K.KK * K.S / K.DETAIL


func display_path() -> String:
	return "res://scenes/animals/kangaroo_clay.tscn"


func rig_name() -> String:
	return "KangarooClayRigged"


func spec(display: Node3D) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# Body: the leaning torso with the arms (they ride on the chest).
		{"name": "body", "parent": "root", "pivot": P(765, 625), "shapes": [
			[P(683, 552), P(745, 604), R(44)], [P(676, 536), P(676, 536), R(28)],
			[P(684, 548, 31), P(640, 596, 28), R(13)], [P(684, 548, -31), P(640, 596, -28), R(13)]]},
		{"name": "head", "parent": "body", "pivot": P(668, 500), "shapes": [
			[P(656, 447), P(652, 458), R(36)], [P(634, 451), P(600, 462), R(17)], [P(610, 473), P(597, 468), R(18)]]},
		{"name": "tail", "parent": "body", "pivot": P(790, 628), "shapes": [
			[P(805, 655), P(852, 719), R(13)], [P(852, 719), P(932, 751), R(7)]]},
		# Hind legs: haunch, leg and the long foot (its own bone, kept level). The near (left)
		# leg stands straight, the far one is a step ahead with its heel lifted.
		{"name": "leg_l", "parent": "root", "pivot": P(756, 598, 42), "shapes": [
			[P(756, 606, 46), P(772, 640, 40), R(36)], [P(772, 640, 40), P(795, 682, 37), R(22)], [P(795, 682, 37), P(800, 722, 37), R(16)]]},
		{"name": "foot_l", "parent": "leg_l", "pivot": P(800, 732, 37), "shapes": [
			[P(800, 739, 37), P(732, 745, 44), R(14)]]},
		{"name": "leg_r", "parent": "root", "pivot": P(746, 598, -42), "shapes": [
			[P(746, 606, -46), P(724, 628, -40), R(36)], [P(724, 628, -40), P(688, 640, -38), R(24)], [P(688, 640, -38), P(705, 698, -37), R(18)]]},
		{"name": "foot_r", "parent": "leg_r", "pivot": P(704, 704, -37), "shapes": [
			[P(704, 706, -37), P(620, 739, -44), R(14)]]},
	]
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var z: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": P(666, 418, z * 24.0),
				"shapes": [[P(676, 400, z * 32.0), P(700, 356, z * 54.0), R(12)]]})
	return {
		"bones": bones,
		"blend": R(9),
		"parts": {"Body": ["body", "head", "tail", "leg_l", "foot_l", "leg_r", "foot_r"],
				"Ears": ["head", "ear_l", "ear_r"]},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eye_frames(display)},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.2, "Ears": 0.3},
	}


func settings() -> Dictionary:
	# A hop: both hind legs together (phase 0.75: back to forward in the air), the body rising
	# along an arc and pitching nose up on take-off and down on landing, the tail swinging up
	# in the air to balance; long feet stay level.
	return {
		"legs": PackedStringArray(["leg_l", "leg_r"]),
		"leg_phase": PackedFloat32Array([0.75, 0.75]),
		"feet": PackedStringArray(["foot_l", "foot_r"]),
		"ground_lock": true,
		"leg_length": P(0, 600).distance_to(P(0, K.KY)),
		"swing_deg": 18.0,
		"stride_scale": 1.3,
		"lift": R(6),
		"hop": R(55),
		"hop_pitch_deg": 5.0,
		"tail_lift_deg": 16.0,
		"bob": 0.0,
		"roll_deg": 0.0,
		"sway": 0.0,
		"breath": 0.012,
		"breath_seconds": 2.8,
		"shift_deg": 1.0,
		"head_turn_deg": 30.0,
		"nod_deg": 3.0,
		"tail_deg": 6.0,
		"ear_deg": 6.0,
		"anim_aabb": AABB(Vector3(-0.6, 0, -0.9), Vector3(1.2, 2.8, 2.0)),
	}
