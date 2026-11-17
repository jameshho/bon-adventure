extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay tiger (17 Nov 2026) from the finished display
## scenes/animals/tiger_clay.tscn into scenes/animals/tiger_clay_rigged.scn: a skinned,
## seam-free skeleton (scripts/characters/clay_rig.gd) with a soft, heavy cub's walk for
## scripts/characters/clay_animator.gd. Rebuild the display first when the tiger changes.
##   godot --headless --path . --script res://tools/build_tiger_clay_rig.gd
## Bone shapes are in the tiger sheet's pixels like tiger_clay.gd's shapes (true x toward the
## tail, y down; z lateral, + = the tiger's left) and placed with its T() and to_model(). The
## tiger script is only read, never changed.
##
## The tiger's own points: the head is a big ball that sits straight on the shoulders (no neck
## bone: the skull, muzzle and cheek ruffs turn together about a pivot in the neck, the skin
## stretching over the nape and throat); a two-bone tail that hangs and waves; ears with a
## little flop; the display already has each eye on its own node, so the eyes ride the head as
## they are (clay_rig.gd on_head) and plush_life.gd blinks them.

const Tiger := preload("res://scripts/characters/tiger_clay.gd")
const ZebraRig := preload("res://tools/build_zebra_clay_rig.gd")   # its _closed(): fills the gaps painted stripes leave
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]


func rigs() -> Array:
	return [{"scene": "res://scenes/animals/tiger_clay.tscn",
			"out": "res://scenes/animals/tiger_clay_rigged.scn",
			"folder": "res://scenes/animals/clay_meshes/tiger_rig/",
			"name": "TigerClayRigged", "spec": spec(), "animator": settings(), "prepare": _close_body}]


## The painted stripes and cream split the body's triangles along their edges without
## splitting the neighbours (T-junctions). The simplifier keeps open edges, so the body thinned
## badly (paws and tail tip torn, rest difference about 18 levels). A closed copy thins like the
## other animals; the display itself is not changed (as tools/build_zebra_clay_rig.gd does).
func _close_body(display: Node3D) -> void:
	var body := display.get_node("Body") as MeshInstance3D
	var closed := ArrayMesh.new()
	closed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ZebraRig._closed(body.mesh.surface_get_arrays(0)))
	body.mesh = closed


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return Tiger.to_model(Tiger.T(x, y, z)) / Tiger.TF


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return M(px, 0).distance_to(M(0, 0))


func spec() -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# Torso: the barrel, the chest under the head, the rump, and the tops of the shoulders
		# and thighs (they stay with the body; the legs swing below them).
		{"name": "body", "parent": "root", "pivot": M(950, 385), "shapes": [
			[M(850, 365), M(1050, 375), R(86)], [M(800, 402), M(800, 402), R(52)], [M(1085, 385), M(1085, 385), R(58)],
			[M(864, 420, 62), M(864, 420, -62), R(40)], [M(1058, 408, 60), M(1058, 408, -60), R(50)]]},
		# Head: the skull, the muzzle and chin, the cheek ruffs.
		{"name": "head", "parent": "body", "pivot": M(842, 316), "shapes": [
			[M(795, 303), M(795, 303), R(86)], [M(745, 340), M(712, 340), R(28)], [M(798, 327, 96), M(798, 327, -96), R(20)]]},
		{"name": "tail", "parent": "body", "pivot": M(1090, 328), "shapes": [[M(1094, 336), M(1128, 385), R(24)]]},
		{"name": "tail_2", "parent": "tail", "pivot": M(1128, 385), "shapes": [
			[M(1128, 385), M(1160, 448), R(22)], [M(1160, 448), M(1203, 471), R(24)]]},
	]
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(800, 266, s * 58.0), "shapes": [
				[M(800, 246, s * 69.5), M(800, 226, s * 72.0), R(26)]]})
	# Legs: the pivot inside the shoulder or thigh; the shape from under the belly to the paw.
	for k in 4:
		var x: float = Tiger.T_LEGS[k][0]
		var z: float = Tiger.T_LEGS[k][1]
		bones.append(leg(LEGS[k], M(x, 408, z + signf(z) * 3.0),
				[M(x, 458, z), M(x + 1.0, 490, z), M(x - 16.0, 507, z)], R(38)))
	return {
		"bones": bones,
		"blend": R(14),
		"parts": {"Body": ["body", "head", "tail", "tail_2"] + LEGS, "Nose": "head", "Brows": "head",
				"Ears": ["head", "ear_l", "ear_r"]},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details", "LeftEye", "RightEye"],
		# The body is closed (_close_body) before it is thinned.
		"simplify": {"Body": 0.3, "Ears": 0.4, "Nose": 0.5, "Brows": 0.6},
	}


## A chunky cub's walk: one foot at a time, hind then front on each side (a lateral walk), short
## steps, a low lift, a little roll over the planted side; the head nods and looks about, the
## hanging tail swings like a pendulum, its tip a beat behind; the ears flop a little.
func settings() -> Dictionary:
	return {
		"legs": PackedStringArray(LEGS),
		"leg_phase": PackedFloat32Array([0.25, 0.75, 0.0, 0.5]),
		"leg_length": M(864, 408).y,
		"keep_feet_down": true,
		"foot_reach": R(44),
		"swing_deg": 15.0,
		"lift": R(10),
		"bob": R(3),
		"roll_deg": 3.5,
		"breath": 0.012,
		"breath_seconds": 3.0,
		"shift_deg": 1.5,
		"head_turn_deg": 20.0,
		"look_gap": Vector2(2.5, 6.0),
		"nod_deg": 2.5,
		"tail_deg": 11.0,
		"tail_axis": Vector3.RIGHT.cross((M(1203, 471) - M(1090, 328)).normalized()).normalized(),
		"tail_chain": PackedStringArray(["tail_2"]),
		"tail_lag": 0.8,
		"ear_deg": 5.0,
	}
