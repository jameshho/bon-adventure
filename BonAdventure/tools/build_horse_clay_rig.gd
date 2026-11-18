extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay horse (17 Nov 2026) from the finished display
## scenes/animals/horse_clay.tscn into scenes/animals/horse_clay_rigged.scn: a skinned,
## seam-free skeleton (scripts/characters/clay_rig.gd) with a light trot for
## scripts/characters/clay_animator.gd. Rebuild the display first when the horse changes.
##   godot --headless --path . --script res://tools/build_horse_clay_rig.gd
## Bone shapes are in the horse sheet's pixels like horse_clay.gd's shapes (x toward the tail, y
## down; z lateral, + = the horse's left) and placed with its _pt() and to_model(). The horse
## script is only read, never changed.
##
## The horse's own points: an upright neck bone that shares the head's look (as the zebra's);
## the ears are part of the fused Body and get their own bones; the Mane bends over head, neck
## and body; the Tail hangs on a two-bone chain; the display already has each eye on its own
## node, so the eyes ride the head as they are (clay_rig.gd on_head) and plush_life.gd blinks
## them.

const Horse := preload("res://scripts/characters/horse_clay.gd")
const ZebraRig := preload("res://tools/build_zebra_clay_rig.gd")   # its _closed(): fills the gaps painted edges leave
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
## [sheet x of the leg, lateral z]: front left, front right, hind left, hind right.
const LEG_AT := [[875.0, 24.5], [875.0, -24.5], [1049.0, 33.5], [1049.0, -33.5]]

var _horse = Horse.new()


func rigs() -> Array:
	return [{"scene": "res://scenes/animals/horse_clay.tscn",
			"out": "res://scenes/animals/horse_clay_rigged.scn",
			"folder": "res://scenes/animals/clay_meshes/horse_rig/",
			"name": "HorseClayRigged", "spec": spec(), "animator": settings(), "prepare": _close_body}]


## The painted socks, hooves, muzzle and blaze split the body's triangles along their edges
## without splitting the neighbours (T-junctions), and the simplifier keeps open edges. A closed
## copy thins cleanly; the display itself is not changed (as tools/build_zebra_clay_rig.gd does).
func _close_body(display: Node3D) -> void:
	var body := display.get_node("Body") as MeshInstance3D
	var closed := ArrayMesh.new()
	closed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ZebraRig._closed(body.mesh.surface_get_arrays(0)))
	body.mesh = closed


## Sheet pixel -> the display's model space.
func M(x: float, y: float, z := 0.0) -> Vector3:
	return Horse.to_model(_horse._pt(x, y, z)) / Horse.H_FINE


## Sheet pixels -> model units (a length).
func R(px: float) -> float:
	return px * Horse.H_HEIGHT / (Horse.H_GY - Horse.H_TOP)


func spec() -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# Torso: the barrel, and the tops of the shoulders and haunches (they stay with the
		# body; the legs swing below them).
		{"name": "body", "parent": "root", "pivot": M(960, 360), "shapes": [
			[M(862, 360), M(1070, 362), R(54)],
			[M(874, 372, 28), M(874, 372, -28), R(32)], [M(1034, 384, 25), M(1034, 384, -25), R(44)]]},
		# The upright neck turns with part of the head's look (clay_animator.gd neck_share).
		{"name": "neck", "parent": "body", "pivot": M(890, 332), "shapes": [
			[M(884, 318), M(864, 222), R(36)]]},
		# Head: the skull and cheeks, and the muzzle.
		{"name": "head", "parent": "neck", "pivot": M(852, 232), "shapes": [
			[M(818, 226), M(818, 226), R(50)], [M(776, 262), M(736, 270), R(31)]]},
		{"name": "tail", "parent": "body", "pivot": M(1052, 314), "shapes": [[M(1058, 316), M(1098, 356), R(27)]]},
		{"name": "tail_2", "parent": "tail", "pivot": M(1100, 366), "shapes": [
			[M(1101, 382), M(1103, 455), R(36)], [M(1103, 455), M(1126, 490), R(21)]]},
	]
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(818, 186, s * 33.0), "shapes": [
				[M(816, 170, s * 37.0), M(811, 140, s * 43.0), R(12)]]})
	# Legs: the pivot inside the shoulder or haunch; the shape from under the belly to the hoof.
	for k in 4:
		var x: float = LEG_AT[k][0]
		var z: float = LEG_AT[k][1]
		if k < 2:
			bones.append(leg(LEGS[k], M(x + 1.0, 396, z), [M(x + 1.0, 440, z), M(x, 548, z), M(x - 6.0, 566, z)], R(24)))
		else:
			bones.append(leg(LEGS[k], M(x - 8.0, 402, z), [M(x - 6.0, 444, z), M(x, 492, z), M(x + 1.0, 548, z), M(x - 6.0, 566, z)], R(22)))
	return {
		"bones": bones,
		"blend": R(12),
		"parts": {"Body": ["body", "neck", "head", "ear_l", "ear_r"] + LEGS,
				"Mane": ["head", "neck", "body"], "Tail": ["body", "tail", "tail_2"]},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details", "LeftEye", "RightEye"],
		# The body is closed (_close_body) before it is thinned.
		"simplify": {"Body": 0.3, "Mane": 0.4, "Tail": 0.4},
	}


## A light trot (diagonal pairs together), long legs, a nodding head on an upright neck that
## looks about, ears that flick, a hanging tail that swings with its tip a beat behind.
func settings() -> Dictionary:
	return {
		"legs": PackedStringArray(LEGS),
		"leg_phase": PackedFloat32Array([0.0, 0.5, 0.5, 0.0]),
		"leg_length": M(876, 396).y,
		"swing_deg": 22.0,
		"lift": R(13),
		"bob": R(4),
		"roll_deg": 2.0,
		"breath": 0.01,
		"breath_seconds": 3.0,
		"shift_deg": 1.2,
		"head_turn_deg": 24.0,
		"look_gap": Vector2(2.5, 6.0),
		"nod_deg": 4.0,
		"neck_share": 0.45,
		"ear_deg": 7.0,
		"tail_deg": 10.0,
		"tail_axis": Vector3.RIGHT.cross((M(1126, 490) - M(1052, 314)).normalized()).normalized(),
		"tail_chain": PackedStringArray(["tail_2"]),
		"tail_lag": 0.8,
	}
