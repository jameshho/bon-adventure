extends SceneTree
## Builds the rigged clay giraffe (big clay animals, 16 Nov 2026) from the finished display
## scenes/animals/giraffe_clay.tscn into scenes/animals/giraffe_clay_rigged.scn: a skinned,
## seam-free skeleton (scripts/characters/clay_rig.gd) with the giraffe's settings for
## scripts/characters/clay_animator.gd. Rebuild the display first when the giraffe changes.
##   godot --headless --path . --script res://tools/build_giraffe_clay_rig.gd
## The bone shapes are written in the giraffe sheet's pixels like giraffe_clay.gd's shapes
## (side view: x toward the tail, y down; z lateral, + = the giraffe's left) and placed with its
## R() and to_model(); the giraffe script is only read, never changed. Record:
## docs/evidence/big-anim-20261116/notes.md.
##
## Beyond the pig: a three-bone neck under the head with blended weights, so the look is shared
## along it and the neck pumps in step; a pace (both legs on one side together); the mane and
## tail tuft (hair material) join the clay surface so they bend with the neck and tail without
## a second skinned surface.

const GiraffeClay := preload("res://scripts/characters/giraffe_clay.gd")
const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")
const OUT := "res://scenes/animals/giraffe_clay_rigged.scn"
const PARTS := "res://scenes/animals/clay_meshes/giraffe_rig/"
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
## Per leg: pivot x, y, the leg's joints (x, y), hoof centre (x, y), z: giraffe_clay.gd's _gleg()
## calls (near front planted, far front lifted forward, near hind trailing, far hind under).
const LEG_AT := [
	[733.0, 300.0, [Vector2(736, 338), Vector2(739, 366)], Vector2(740, 381.5), 19.0, [14.5, 12.0, 10.0]],
	[714.0, 300.0, [Vector2(702, 332), Vector2(682, 359)], Vector2(673, 371), -19.0, [14.0, 11.5, 10.0]],
	[810.0, 300.0, [Vector2(821, 338), Vector2(832, 371)], Vector2(834, 381.5), 20.0, [16.0, 12.5, 10.0]],
	[786.0, 304.0, [Vector2(792, 338), Vector2(775, 367)], Vector2(769, 380.5), -20.0, [15.0, 12.0, 10.0]]]


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return GiraffeClay.to_model(GiraffeClay.R(x, y, z))


## Sheet pixels -> model units (a length).
static func L(px: float) -> float:
	return px * GiraffeClay.GH / (GiraffeClay.GY - GiraffeClay.GTOP)


func spec(giraffe) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(766, 288), "shapes": [
			[M(742, 284), M(794, 290), L(36)], [M(806, 293, 19), M(806, 293, -19), L(20)]]},
		# Neck: three bones along giraffe_clay.gd's neck limb, withers to the skull.
		{"name": "neck_1", "parent": "body", "pivot": M(737, 262), "shapes": [[M(737, 262), M(724, 236), L(25)]]},
		{"name": "neck_2", "parent": "neck_1", "pivot": M(722, 230), "shapes": [[M(722, 230), M(713, 206), L(20)]]},
		{"name": "neck_3", "parent": "neck_2", "pivot": M(711, 200), "shapes": [[M(711, 200), M(705, 181), L(18)]]},
		{"name": "head", "parent": "neck_3", "pivot": M(702, 172), "shapes": [
			[M(679, 146), M(679, 146), L(30)], [M(671, 161), M(645, 160.5), L(17)],
			[M(690, 122, 14), M(693, 96, 18), L(8)], [M(690, 122, -14), M(693, 96, -18), L(8)]]},
		{"name": "tail", "parent": "body", "pivot": M(820, 279), "shapes": [[M(824, 282), M(851, 307), L(5)]]},
	]
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(706, 121, s * 30.0), "shapes": [
				[M(713, 119, s * 44.0), M(718, 113, s * 54.0), L(10)]]})
	for k in 4:
		var at: Array = LEG_AT[k]
		var z: float = at[4]
		var joints: Array = at[2]
		var r: Array = at[5]
		var hoof: Vector2 = at[3]
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(at[0], at[1], z), "shapes": [
				[M(at[0], at[1] + 14.0, z), M(joints[0].x, joints[0].y, z), L(r[0])],
				[M(joints[0].x, joints[0].y, z), M(joints[1].x, joints[1].y, z), L(r[1])],
				[M(joints[1].x, joints[1].y, z), M(hoof.x, hoof.y, z), L(r[2] + 2.0)]]})
	# Eyes: giraffe_clay.gd's own placement (_eye_frame), as a right-handed frame with y up the
	# eye (the axis plush_life.gd squashes) and z out of the face.
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var f: Array = giraffe._eye_frame(side[1])
		var z := GiraffeClay.normal_to_model(f[1]).normalized()
		var y := GiraffeClay.normal_to_model(f[3]).normalized()
		var x := y.cross(z).normalized()
		eyes.append({"name": side[0], "origin": GiraffeClay.to_model(f[0]), "basis": Basis(x, z.cross(x), z)})
	var spine := ["body", "neck_1", "neck_2", "neck_3", "head"]
	var out := {
		"bones": bones,
		"blend": L(11),
		"parts": {"Body": spine + ["tail"] + LEGS, "Mane": spine, "Tail tuft": "tail",
				"Ears": ["head", "ear_l", "ear_r"]},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.5, "Mane": 0.4, "Tail tuft": 0.5, "Ears": 0.4},
	}
	if not OS.get_cmdline_user_args().has("hair-own"):
		out["merge_into"] = {"Mane": "Body", "Tail tuft": "Body"}
	return out


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var display: Node3D = load("res://scenes/animals/giraffe_clay.tscn").instantiate()
	var giraffe = GiraffeClay.new()
	giraffe._shape()
	var rig := ClayRig.build(display, spec(giraffe))
	rig.name = "GiraffeClayRigged"
	rig.set_meta("source", "scenes/animals/giraffe_clay.tscn, rigged by tools/build_giraffe_clay_rig.gd (16 Nov 2026)")
	rig.set_meta("anim_aabb", AABB(Vector3(-1.0, -0.1, -2.1), Vector3(2.0, 4.7, 3.9)))
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	# The giraffe: a pace (near legs together, then far legs), a strong roll from side to side,
	# the neck pumping in step and sharing the head's turns.
	var feet := PackedVector3Array()
	var neutral := PackedFloat32Array()
	for k in 4:
		var at: Array = LEG_AT[k]
		var pivot := M(at[0], at[1], at[4])
		var hoof: Vector2 = at[3]
		var foot := M(hoof.x, hoof.y + 8.5, at[4])
		feet.append(foot)
		neutral.append(-0.5 * rad_to_deg(atan2(pivot.z - foot.z, pivot.y - foot.y)))
	animator.set("legs", PackedStringArray(LEGS))
	animator.set("leg_phase", PackedFloat32Array([0.0, 0.5, 0.0, 0.5]))
	animator.set("leg_length", M(0, 300).distance_to(M(0, GiraffeClay.GY)))
	animator.set("leg_neutral_deg", neutral)
	animator.set("feet", feet)
	animator.set("foot_stretch", Vector2(0.75, 1.12))
	animator.set("swing_deg", 16.0)
	animator.set("lift", L(9))
	animator.set("bob", L(2))
	animator.set("roll_deg", 2.6)
	animator.set("breath", 0.01)
	animator.set("breath_seconds", 3.4)
	animator.set("shift_deg", 1.0)
	animator.set("head_turn_deg", 30.0)
	animator.set("look_gap", Vector2(3.0, 7.0))
	animator.set("nod_deg", 2.0)
	animator.set("neck", PackedStringArray(["neck_1", "neck_2", "neck_3"]))
	animator.set("neck_share", 0.6)
	animator.set("neck_pump_deg", 2.2)
	animator.set("tail_deg", 16.0)
	animator.set("tail_axis", Vector3.RIGHT.cross((M(851, 307) - M(820, 279)).normalized()).normalized())
	animator.set("ear_deg", 8.0)
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
	print("GIRAFFE CLAY RIG: %s, neutral %s, %d ms, save %s" % [JSON.stringify(stats), neutral, Time.get_ticks_msec() - started, error_string(result)])
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
