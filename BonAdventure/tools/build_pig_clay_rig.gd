extends SceneTree
## Builds the rigged clay pig (animation pilot, 16 Nov 2026) from the finished clay pig display
## scenes/animals/pig_clay.tscn into scenes/animals/pig_clay_rigged.scn: a skinned, seam-free
## skeleton (scripts/characters/clay_rig.gd) with the pig's settings for
## scripts/characters/clay_animator.gd. Rebuild the display first when the pig changes.
##   godot --headless --path . --script res://tools/build_pig_clay_rig.gd
## The bone shapes are written in the pig sheet's pixels like pig_clay.gd's shapes (side view: x
## toward the tail, y down; z lateral, + = the pig's left) and placed with its PT() and
## to_model(); the pig script is only read, never changed.

const PigClay := preload("res://scripts/characters/pig_clay.gd")
const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")
const OUT := "res://scenes/animals/pig_clay_rigged.scn"


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return PigClay.to_model(PigClay.PT(x, y, z)) / PigClay.PF


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * PigClay.PH / (PigClay.PGY - PigClay.PTOP)


func spec(pig) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(1010, 400), "shapes": [
			[M(955, 392), M(1090, 395), R(98)], [M(960, 428), M(1070, 428), R(62)],
			[M(1112, 440, 28), M(1112, 440, -28), R(44)]]},
		{"name": "head", "parent": "body", "pivot": M(915, 385), "shapes": [
			[M(852, 361), M(852, 361), R(99)], [M(790, 371), M(760, 371), R(33)]]},
		{"name": "tail", "parent": "body", "pivot": M(1132, 334), "shapes": [[M(1132, 334), M(1153, 320), R(20)]]},
	]
	var leg_names := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
	for k in 4:
		var leg: Array = PigClay.P_LEGS[k]
		var z_top: float = leg[1] + signf(leg[1]) * 7.0
		var front: bool = leg[0] < 1000.0
		var pivot := M(leg[0] + (10.0 if front else 0.0), 432.0 if front else 415.0, z_top)
		bones.append({"name": leg_names[k], "parent": "root", "pivot": pivot,
				"shapes": [[M(leg[0], 462, z_top), M(leg[0], 530, leg[1]), R(leg[2] + 3.0)]]})
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var z: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(850, 280, z * 68.0),
				"shapes": [[M(850, 296, z * 87.0), M(850, 330, z * 110.0), R(28)]]})
	# Eyes: pig_clay.gd's own placement (_pig_eye), turned into a right-handed frame with y up
	# the eye (the axis plush_life.gd squashes) and z out of the face.
	pig._shape()
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var hit: Array = pig._pig_eye(side[1])
		var b: Basis = hit[1]
		var z := PigClay.normal_to_model(b.z).normalized()
		var y := PigClay.normal_to_model(b.y).normalized()
		var x := y.cross(z).normalized()
		eyes.append({"name": side[0], "origin": PigClay.to_model(hit[0]) / PigClay.PF, "basis": Basis(x, z.cross(x), z)})
	return {
		"bones": bones,
		"blend": R(10),
		"parts": {"Body": ["body", "head"] + leg_names, "Snout": "head",
				"Ears": ["head", "ear_l", "ear_r"], "Hooves": leg_names, "Tail": "tail"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		# Skinning cost is per vertex: the 1 cm clay grid is far finer than the zoo needs
		# (perf.json; the merge above mattered more than this, see ANIMAL_SYSTEM.md).
		"simplify": {"Body": 0.25, "Ears": 0.25, "Hooves": 0.25, "Snout": 0.5},
	}


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var display: Node3D = load("res://scenes/animals/pig_clay.tscn").instantiate()
	var pig = PigClay.new()
	var rig := ClayRig.build(display, spec(pig))
	rig.name = "PigClayRigged"
	rig.set_meta("source", "scenes/animals/pig_clay.tscn, rigged by tools/build_pig_clay_rig.gd (16 Nov 2026)")
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	# The pig: short legs, a quick trot, floppy ears.
	animator.set("leg_length", M(0, 415).distance_to(M(0, PigClay.PGY)))
	animator.set("swing_deg", 24.0)
	animator.set("lift", R(9))
	animator.set("bob", R(4))
	animator.set("ear_deg", 8.0)
	rig.add_child(animator)
	animator.owner = rig
	var stats = rig.get_meta("rig_stats")
	rig.remove_meta("rig_stats")
	var scene := PackedScene.new()
	var result := scene.pack(rig)
	if result == OK:
		result = ResourceSaver.save(scene, OUT, ResourceSaver.FLAG_COMPRESS)
	print("PIG CLAY RIG: %s, %d ms, save %s" % [JSON.stringify(stats), Time.get_ticks_msec() - started, error_string(result)])
	rig.free()
	display.free()
	quit(result)
