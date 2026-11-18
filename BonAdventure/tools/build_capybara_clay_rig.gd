extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay capybara (17 Nov 2026) from the finished display
## scenes/animals/capybara_clay.tscn into scenes/animals/capybara_clay_rigged.scn: a skinned,
## seam-free skeleton (scripts/characters/clay_rig.gd) with a slow, low waddle for
## scripts/characters/clay_animator.gd. Rebuild the display first when the capybara changes.
##   godot --headless --path . --script res://tools/build_capybara_clay_rig.gd
## Bone shapes are in the capybara sheet's pixels like capybara_clay.gd's shapes (x toward the
## tail, y down; z lateral, + = the capybara's left) and placed with its BT() and to_model().
## The capybara script is only read, never changed.
##
## The capybara's own points: one big round body resting low, so the legs are very short: the
## front legs are stubby columns that swing a little; the hind feet are long flat paws under
## the haunches that slide a short way and stay on the ground (keep_feet_down). The head sits
## straight on the body (no neck bone) and turns about a pivot in the nape. The ears are part
## of the fused Body and get their own bones. The display already has each eye on its own node,
## so the eyes ride the head as they are (clay_rig.gd on_head) and plush_life.gd blinks them
## (half closed already: a blink closes the rest).

const Capy := preload("res://scripts/characters/capybara_clay.gd")
const ZebraRig := preload("res://tools/build_zebra_clay_rig.gd")   # its _closed(): fills the gaps painted edges leave
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]


func rigs() -> Array:
	return [{"scene": "res://scenes/animals/capybara_clay.tscn",
			"out": "res://scenes/animals/capybara_clay_rigged.scn",
			"folder": "res://scenes/animals/clay_meshes/capybara_rig/",
			"name": "CapybaraClayRigged", "spec": spec(), "animator": settings(), "prepare": _close_body}]


## The painted muzzle, paws and ears split the body's triangles along their edges without
## splitting the neighbours (T-junctions), and the simplifier keeps open edges. A closed copy
## thins cleanly; the display itself is not changed (as tools/build_zebra_clay_rig.gd does).
func _close_body(display: Node3D) -> void:
	var body := display.get_node("Body") as MeshInstance3D
	var closed := ArrayMesh.new()
	closed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ZebraRig._closed(body.mesh.surface_get_arrays(0)))
	body.mesh = closed


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return Capy.to_model(Capy.BT(x, y, z)) / Capy.BF


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * Capy.BH / (Capy.BGY - Capy.BTOP)


func spec() -> Dictionary:
	var fx: float = Capy.B_FRONT_X
	var fz: float = Capy.B_FRONT_Z
	var hx: float = Capy.B_HIND_X
	var hz: float = Capy.B_HIND_Z
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# The ball of the torso and the chest under the head.
		{"name": "body", "parent": "root", "pivot": M(1006, 430), "shapes": [
			[M(1006, 422), M(1006, 422), R(112)], [M(900, 430), M(900, 430), R(52)]]},
		# Head: the skull and cheeks, and the blunt muzzle.
		{"name": "head", "parent": "body", "pivot": M(940, 350), "shapes": [
			[M(880, 326), M(880, 326), R(84)], [M(800, 330), M(742, 334), R(52)]]},
	]
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(900, 262, s * 62.0), "shapes": [
				[M(900, 246, s * 66.0), M(900, 232, s * 68.0), R(24)]]})
	for side in [[0, 1.0], [1, -1.0]]:
		var s: float = side[1]
		bones.append(leg(LEGS[side[0]], M(fx + 4.0, 448, s * fz),
				[M(fx + 2.0, 476, s * fz), M(fx, 502, s * fz), M(fx - 22.0, 510, s * fz)], R(27)))
		bones.append(leg(LEGS[side[0] + 2], M(hx + 14.0, 484, s * hz),
				[M(hx + 30.0, 506, s * hz), M(hx - 40.0, 510, s * hz)], R(19)))
	return {
		"bones": bones,
		"blend": R(12),
		"parts": {"Body": ["body", "head", "ear_l", "ear_r"] + LEGS},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details", "LeftEye", "RightEye"],
		# The body is closed (_close_body) before it is thinned.
		"simplify": {"Body": 0.3},
	}


## A slow waddle: one foot at a time (a lateral walk), very short steps, the soles kept on the
## ground, a clear roll from side to side and a little bob; slow breathing; the head looks
## about lazily; the ears twitch.
func settings() -> Dictionary:
	return {
		"legs": PackedStringArray(LEGS),
		"leg_phase": PackedFloat32Array([0.25, 0.75, 0.0, 0.5]),
		"leg_length": M(Capy.B_FRONT_X, 448).y,
		"keep_feet_down": true,
		"foot_reach": R(30),
		"swing_deg": 16.0,
		"lift": R(5),
		"bob": R(3),
		"roll_deg": 4.0,
		"breath": 0.016,
		"breath_seconds": 3.6,
		"shift_deg": 1.2,
		"head_turn_deg": 18.0,
		"look_gap": Vector2(3.5, 8.0),
		"nod_deg": 2.0,
		"tail_deg": 0.0,
		"ear_deg": 6.0,
	}
