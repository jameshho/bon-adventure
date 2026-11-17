extends SceneTree
## Builds the rigged clay elephant (big clay animals, 16 Nov 2026) from the finished display
## scenes/animals/elephant_clay.tscn into scenes/animals/elephant_clay_rigged.scn: a skinned,
## seam-free skeleton (scripts/characters/clay_rig.gd) with the elephant's settings for
## scripts/characters/clay_animator.gd. Rebuild the display first when the elephant changes.
##   godot --headless --path . --script res://tools/build_elephant_clay_rig.gd
## The bone shapes are written in the elephant sheet's pixels like elephant_clay.gd's shapes
## (side view: x toward the tail, y down; z lateral, + = the elephant's left) and placed with its
## T() and to_model(); the elephant script is only read, never changed. Record:
## docs/evidence/big-anim-20261116/notes.md.
##
## Beyond the pig: a three-bone trunk that sways, ears that fan on a vertical hinge, a slow
## lateral-sequence walk (hind, fore on one side, then the other) and feet kept on the ground
## (the display stands mid-stride, so the walk swings each leg about a more upright angle).

const ElephantClay := preload("res://scripts/characters/elephant_clay.gd")
const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")
const OUT := "res://scenes/animals/elephant_clay_rigged.scn"
const PARTS := "res://scenes/animals/clay_meshes/elephant_rig/"
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
## Hip or shoulder pivot and foot (sheet x, y of the sole) per leg, z per side: elephant_clay.gd's
## _eleg() calls (near front reaching, far front planted, near hind trailing, far hind).
const LEG_AT := [[1008.0, 400.0, 895.0, 49.0], [1006.0, 400.0, 1001.0, -49.0], [1150.0, 395.0, 1181.0, 52.0], [1113.0, 398.0, 1095.0, -52.0]]


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return ElephantClay.to_model(ElephantClay.T(x, y, z))


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * ElephantClay.EH / (ElephantClay.EGY - ElephantClay.ETOP)


func spec(elephant) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# Barrel and rump; the neck fold is shared with the head.
		{"name": "body", "parent": "root", "pivot": M(1085, 330), "shapes": [
			[M(1040, 325), M(1110, 328), R(92)], [M(990, 312), M(990, 312), R(70)]]},
		{"name": "head", "parent": "body", "pivot": M(930, 290), "shapes": [
			[M(890, 258), M(890, 258), R(66)], [M(884, 312, 30), M(884, 312, -30), R(46)],
			[M(848, 354), M(848, 354), R(12)],
			[M(850, 333, 45), M(796, 356, 60), R(12)], [M(850, 333, -45), M(796, 356, -60), R(12)]]},
		# Trunk: base, middle and the curled tip (tube points in _shape()).
		{"name": "trunk_1", "parent": "head", "pivot": M(832, 318), "shapes": [[M(830, 318), M(800, 362), R(27)]]},
		{"name": "trunk_2", "parent": "trunk_1", "pivot": M(797, 380), "shapes": [[M(797, 380), M(799, 420), R(21)]]},
		{"name": "trunk_3", "parent": "trunk_2", "pivot": M(800, 428), "shapes": [
			[M(802, 435), M(811, 461), R(16)], [M(811, 461), M(838, 463), R(13)], [M(843, 454), M(843, 454), R(12)]]},
		{"name": "tail", "parent": "body", "pivot": M(1190, 318), "shapes": [[M(1196, 335), M(1213, 402), R(8)]]},
	]
	for k in 4:
		var at: Array = LEG_AT[k]
		var z: float = at[3]
		var top := Vector2(at[0], at[1])
		var foot := Vector2(at[2], ElephantClay.EGY - 17.0)
		var knee := top.lerp(foot, 0.5)
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(top.x, top.y, z), "shapes": [
				[M(top.x, top.y + 22.0, z), M(knee.x, knee.y, z), R(38)], [M(knee.x, knee.y, z), M(foot.x, foot.y - 8.0, z), R(34)],
				[M(foot.x - 12.0, foot.y + 4.0, z), M(foot.x + 6.0, foot.y + 4.0, z), R(30)]]})
	# Ears: a vertical hinge where the ear leaves the head; the fan's shapes stay clear of the
	# root so the inner edge bends with the head.
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": ElephantClay.to_model(elephant._ear_point(s, 0.0, 268.0)), "shapes": [
				[ElephantClay.to_model(elephant._ear_point(s, 72.0, 262.0)), ElephantClay.to_model(elephant._ear_point(s, 112.0, 300.0)), R(52)]]})
	# Eyes: elephant_clay.gd's own placement (_elephant_eye), as a right-handed frame with y up
	# the eye (the axis plush_life.gd squashes) and z out of the face.
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var hit: Array = elephant._elephant_eye(side[1])
		var b: Basis = hit[1]
		var z := ElephantClay.normal_to_model(b.z).normalized()
		var y := ElephantClay.normal_to_model(b.y).normalized()
		var x := y.cross(z).normalized()
		eyes.append({"name": side[0], "origin": ElephantClay.to_model(hit[0]), "basis": Basis(x, z.cross(x), z)})
	var trunk := ["head", "trunk_1", "trunk_2", "trunk_3"]
	return {
		"bones": bones,
		"blend": R(12),
		"parts": {"Body": ["body", "head", "tail"] + trunk.slice(1) + LEGS,
				"Ears": ["head", "ear_l", "ear_r"], "Tail tuft": "tail",
				# Lids, brows, smile and the trunk's wrinkles: skinned so the wrinkles stay on the
				# swaying trunk, in the clay surface (no second skinned surface).
				"Face details": trunk},
		"merge_into": {"Face details": "Body"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"simplify": {"Body": 0.2, "Ears": 0.2},
	}


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var display: Node3D = load("res://scenes/animals/elephant_clay.tscn").instantiate()
	var elephant = ElephantClay.new()
	elephant._shape()
	var rig := ClayRig.build(display, spec(elephant))
	rig.name = "ElephantClayRigged"
	rig.set_meta("source", "scenes/animals/elephant_clay.tscn, rigged by tools/build_elephant_clay_rig.gd (16 Nov 2026)")
	rig.set_meta("anim_aabb", AABB(Vector3(-1.9, -0.1, -2.2), Vector3(3.8, 3.5, 4.4)))
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	# The elephant: a slow, heavy lateral-sequence walk (left hind, left fore, right hind, right
	# fore, a quarter cycle apart), a small bob and roll, ears fanning, trunk swaying.
	var feet := PackedVector3Array()
	var neutral := PackedFloat32Array()
	for k in 4:
		var at: Array = LEG_AT[k]
		var pivot := M(at[0], at[1], at[3])
		var foot := M(at[2], ElephantClay.EGY, at[3])
		feet.append(foot)
		# Lean of the leg at rest (+ = foot forward); walking swings about 40% of the way upright.
		neutral.append(-0.4 * rad_to_deg(atan2(pivot.z - foot.z, pivot.y - foot.y)))
	animator.set("legs", PackedStringArray(LEGS))
	animator.set("leg_phase", PackedFloat32Array([0.25, 0.75, 0.0, 0.5]))
	animator.set("leg_length", M(0, 400).distance_to(M(0, ElephantClay.EGY)))
	animator.set("leg_neutral_deg", neutral)
	animator.set("feet", feet)
	animator.set("foot_stretch", Vector2(0.7, 1.12))
	animator.set("swing_deg", 13.0)
	animator.set("stride_scale", 1.0)
	animator.set("lift", R(14))
	animator.set("bob", R(3))
	animator.set("roll_deg", 1.4)
	animator.set("breath", 0.008)
	animator.set("breath_seconds", 4.2)
	animator.set("shift_deg", 0.8)
	animator.set("head_turn_deg", 14.0)
	animator.set("look_gap", Vector2(3.5, 8.0))
	animator.set("nod_deg", 2.0)
	animator.set("tail_deg", 14.0)
	animator.set("tail_axis", Vector3.RIGHT.cross((M(1213, 402) - M(1188, 312)).normalized()).normalized())
	animator.set("ear_axis", Vector3.UP)
	animator.set("ear_deg", 9.0)
	animator.set("ear_fan_seconds", 3.4)
	animator.set("trunk", PackedStringArray(["trunk_1", "trunk_2", "trunk_3"]))
	animator.set("trunk_sway_deg", 5.0)
	animator.set("trunk_curl_deg", 4.0)
	animator.set("trunk_seconds", 3.6)
	rig.add_child(animator)
	animator.owner = rig
	var stats = rig.get_meta("rig_stats")
	rig.remove_meta("rig_stats")
	var result := _save_parts(rig)
	var scene := PackedScene.new()
	if result == OK:
		result = scene.pack(rig)
	if result == OK:
		result = ResourceSaver.save(scene, OUT, ResourceSaver.FLAG_COMPRESS)
	print("ELEPHANT CLAY RIG: %s, neutral %s, %d ms, save %s" % [JSON.stringify(stats), neutral, Time.get_ticks_msec() - started, error_string(result)])
	rig.free()
	display.free()
	quit(result)


## Writes each mesh and skin of the rig to PARTS/<node>.res (zstd-compressed, vertex data
## unchanged) and points the nodes at those files (as tools/build_pig_clay_rig.gd does).
func _save_parts(rig: Node3D) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PARTS))
	for old in DirAccess.get_files_at(PARTS):
		if old.ends_with(".res"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PARTS + old))
	for mi: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		var base := PARTS + String(mi.name).to_snake_case().replace(" ", "_")
		for pair in [["mesh", ""], ["skin", "_skin"]]:
			var res: Resource = mi.get(pair[0])
			if res == null:
				continue
			var path: String = base + pair[1] + ".res"
			var result := ResourceSaver.save(res, path, ResourceSaver.FLAG_COMPRESS)
			if result != OK:
				return result
			res.take_over_path(path)
	return OK
