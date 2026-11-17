extends SceneTree
## Builds the rigged clay lion (big clay animals, 16 Nov 2026) from the finished display
## scenes/animals/lion_clay.scn (the zoo's lion: base.gd clay_meshes_external finds it as .scn)
## into scenes/animals/lion_clay_rigged.scn: a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) with the lion's settings for
## scripts/characters/clay_animator.gd. Rebuild the display first when the lion changes.
##   godot --headless --path . --script res://tools/build_lion_clay_rig.gd [-- mane-merged]
## The bone shapes are written in true sheet pixels like lion_clay.gd's shapes (Q(): side view,
## x toward the tail, y down; z lateral, + = the lion's left) and placed with its to_model(); the
## lion script is only read, never changed. Record: docs/evidence/big-anim-20261116/notes.md.
##
## Beyond the pig: the mane is its own mesh, skinned across head, neck and body with a soft
## blend, so the front of the mane turns with the face and the back stays on the shoulders; a
## two-bone tail that waves, the tuft riding its tip; a lateral-sequence walk with the feet kept
## on the ground (the display crouches mid-stride). The mane keeps its matte hair material (user,
## 11 Nov 2026) as a second skinned surface: joined to the clay surface it read shinier (16-27% of
## its pixels changed, notes.md). `-- mane-merged` builds the one-surface variant.

const LionClay := preload("res://scripts/characters/lion_clay.gd")
const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")
const OUT := "res://scenes/animals/lion_clay_rigged.scn"
const PARTS := "res://scenes/animals/clay_meshes/lion_rig/"
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
## Per leg: pivot (x, y), the leg's joints and paw (x, y), z: lion_clay.gd's _leg() calls.
const LEG_AT := [
	[Vector2(736, 288), [Vector2(712, 318), Vector2(700, 336), Vector2(687, 344)], 37.0],
	[Vector2(800, 290), [Vector2(795, 320), Vector2(793, 336), Vector2(788, 344)], -37.0],
	[Vector2(846, 272), [Vector2(872, 305), Vector2(884, 336), Vector2(881, 344)], 37.0],
	[Vector2(840, 272), [Vector2(858, 305), Vector2(868, 336), Vector2(865, 344)], -37.0]]


## True sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return LionClay.to_model(LionClay.Q(x, y, z))


## Sheet pixels -> model units (a length).
static func L(px: float) -> float:
	return px * LionClay.S


func spec(lion, mane_own: bool) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(790, 270), "shapes": [
			[M(740, 264), M(850, 272), L(50)], [M(856, 298), M(856, 298), L(30)]]},
		# The neck sits inside the mane's ring; it carries part of the look and the mane between
		# the face and the shoulders.
		{"name": "neck", "parent": "body", "pivot": M(718, 245), "shapes": [[M(712, 236), M(696, 230), L(40)]]},
		{"name": "head", "parent": "neck", "pivot": M(680, 230), "shapes": [
			[M(656, 224), M(656, 224), L(42)], [M(640, 256), M(613, 252), L(24)], [M(614, 273), M(614, 273), L(15)],
			[M(634, 250, 27), M(634, 250, -27), L(22)]]},
		{"name": "tail", "parent": "body", "pivot": M(862, 238), "shapes": [[M(866, 242), M(896, 279), L(9)]]},
		{"name": "tail_2", "parent": "tail", "pivot": M(896, 279), "shapes": [[M(896, 279), M(924, 292), L(7)]]},
	]
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(655, 202, s * 38.0), "shapes": [[M(655, 188, s * 43.0), M(655, 182, s * 45.0), L(18)]]})
	for k in 4:
		var at: Array = LEG_AT[k]
		var z: float = at[2]
		var top: Vector2 = at[0]
		var j: Array = at[1]
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(top.x, top.y, z), "shapes": [
				[M(lerpf(top.x, j[0].x, 0.4), lerpf(top.y, j[0].y, 0.4), z), M(j[0].x, j[0].y, z), L(28)],
				[M(j[0].x, j[0].y, z), M(j[1].x, j[1].y, z), L(27)],
				[M(j[1].x, j[1].y, z), M(j[2].x - 6.0, j[2].y, z), L(28)]]})
	# Eyes: lion_clay.gd's own placement (_fp(EYE_Y, ...) as in _eyes()), as a right-handed
	# frame with y up the eye (the axis plush_life.gd squashes) and z out of the face.
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var hit: Array = lion._fp(LionClay.EYE_Y, side[1] * LionClay.EYE_Z)
		var n: Vector3 = hit[1]
		var right := Vector3.UP.cross(n).normalized()
		var z := LionClay.normal_to_model(n).normalized()
		var y := LionClay.normal_to_model(n.cross(right)).normalized()
		var x := y.cross(z).normalized()
		eyes.append({"name": side[0], "origin": LionClay.to_model(hit[0]), "basis": Basis(x, z.cross(x), z)})
	var out := {
		"bones": bones,
		"blend": L(10),
		"parts": {"Body": ["body", "neck", "head", "tail", "tail_2"] + LEGS, "Mane": ["body", "neck", "head"],
				"Tail tuft": "tail_2", "Ears": ["head", "ear_l", "ear_r"]},
		# The mane is far from every bone's shapes: a softer blend spreads the turn across it.
		"blends": {"Mane": L(22)},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.4, "Mane": 0.3, "Tail tuft": 0.5, "Ears": 0.5},
	}
	if not mane_own:
		out["merge_into"] = {"Mane": "Body"}
	return out


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var display: Node3D = load("res://scenes/animals/lion_clay.scn").instantiate()
	var lion = LionClay.new()
	lion._shape()
	var mane_own := not OS.get_cmdline_user_args().has("mane-merged")
	var rig := ClayRig.build(display, spec(lion, mane_own))
	rig.name = "LionClayRigged"
	rig.set_meta("source", "scenes/animals/lion_clay.scn, rigged by tools/build_lion_clay_rig.gd (16 Nov 2026)")
	rig.set_meta("anim_aabb", AABB(Vector3(-1.0, -0.1, -1.7), Vector3(2.0, 2.2, 3.5)))
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	# The lion: a lateral-sequence walk (left hind, left fore, right hind, right fore), a low
	# prowl with a little roll, the head and mane turning on the neck, a waving tail.
	var feet := PackedVector3Array()
	var neutral := PackedFloat32Array()
	for k in 4:
		var at: Array = LEG_AT[k]
		var top: Vector2 = at[0]
		var paw: Vector2 = at[1][2]
		var pivot := M(top.x, top.y, at[2])
		var foot := M(paw.x, 359.0, at[2])
		feet.append(foot)
		neutral.append(-0.3 * rad_to_deg(atan2(pivot.z - foot.z, pivot.y - foot.y)))
	animator.set("legs", PackedStringArray(LEGS))
	animator.set("leg_phase", PackedFloat32Array([0.25, 0.75, 0.0, 0.5]))
	animator.set("leg_length", M(0, 288).distance_to(M(0, 359)))
	animator.set("leg_neutral_deg", neutral)
	animator.set("foot_contacts", feet)
	animator.set("foot_stretch", Vector2(0.72, 1.12))
	animator.set("swing_deg", 14.0)
	animator.set("lift", L(12))
	animator.set("bob", L(3))
	animator.set("roll_deg", 1.8)
	animator.set("breath", 0.012)
	animator.set("breath_seconds", 3.0)
	animator.set("shift_deg", 1.2)
	animator.set("head_turn_deg", 22.0)
	animator.set("look_gap", Vector2(2.5, 6.0))
	animator.set("nod_deg", 2.5)
	animator.set("neck", PackedStringArray(["neck"]))
	animator.set("neck_share", 0.45)
	animator.set("neck_pump_deg", 1.2)
	animator.set("tail_deg", 13.0)
	animator.set("tail_axis", Vector3.RIGHT.cross((M(924, 292) - M(862, 236)).normalized()).normalized())
	animator.set("tail_chain", PackedStringArray(["tail_2"]))
	animator.set("tail_lag", 0.8)
	animator.set("ear_deg", 6.0)
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
	print("LION CLAY RIG: %s, neutral %s, mane %s, %d ms, save %s" % [JSON.stringify(stats), neutral, "own surface" if mane_own else "in the clay surface", Time.get_ticks_msec() - started, error_string(result)])
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
