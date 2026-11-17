extends SceneTree
## Builds the rigged clay cow (16 Nov 2026) from the finished display scenes/animals/cow_clay.tscn
## into scenes/animals/cow_clay_rigged.scn: a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) with the cow's settings for clay_animator.gd. Rebuild the
## display first when the cow changes.
##   godot --headless --path . --script res://tools/build_cow_clay_rig.gd
## Bone shapes are in the cow sheet's pixels like cow_clay.gd's shapes (side view: x toward the
## tail, y down; z lateral, + = the cow's left), placed with its W() and to_model(); the cow
## script is only read. Record: docs/evidence/hoofed-anim-20261116/notes.md.

const CowClay := preload("res://scripts/characters/cow_clay.gd")
const Bake := preload("res://tools/clay_rig_bake.gd")


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return CowClay.to_model(CowClay.W(x, y, z)) / CowClay.FINE


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * CowClay.CH / (CowClay.CY - CowClay.CTOP)


const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]


func spec(cow) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# The barrel and the base of the neck.
		{"name": "body", "parent": "root", "pivot": M(1005, 370), "shapes": [
			[M(925, 366), M(1090, 367), R(92)], [M(915, 330), M(930, 345), R(66)]]},
		# Head and the top of the short neck: the turn bends the neck between them.
		{"name": "head", "parent": "body", "pivot": M(895, 300), "shapes": [
			[M(838, 258), M(866, 250), R(68)], [M(818, 301, 30), M(818, 301, -30), R(38)],
			[M(802, 322), M(802, 322), R(36)], [M(872, 276), M(872, 276), R(54)]]},
		# The tail stalk hangs down the rump (the tuft is its own mesh, rigid on this bone).
		{"name": "tail", "parent": "body", "pivot": M(1154, 304), "shapes": [
			[M(1162, 318), M(1173, 322), R(10)], [M(1173, 322), M(1187, 432), R(10)]]},
	]
	for k in 4:
		var leg: Array = CowClay.C_LEGS[k]
		var front: bool = leg[0] < 1000.0
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(leg[0], 400.0 if front else 385.0, leg[1] * 0.92),
				"shapes": [[M(leg[0], 455, leg[1] * 0.95), M(leg[0], 545, leg[1]), R(36)]]})
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var z: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(888, 232, z * 64.0),
				"shapes": [[M(893, 231, z * 78.0), M(915, 229, z * 120.0), R(22)]]})
	# Eyes: cow_clay.gd's own frame (_cow_eye_frame: centre, normal, outer corner, up).
	cow._shape()
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var f: Array = cow._cow_eye_frame(side[1])
		eyes.append(Bake.eye(side[0], CowClay.to_model(f[0]) / CowClay.FINE,
				CowClay.normal_to_model(f[1]), CowClay.normal_to_model(f[3])))
	return {
		"bones": bones,
		"blend": R(10),
		# The udder rides the body (a rigid part across the belly; it must not follow a leg), the
		# horns and muzzle the head, the tuft the tail.
		"parts": {"Body": ["body", "head", "tail"] + LEGS, "Muzzle": "head", "Horns": "head",
				"Ears": ["head", "ear_l", "ear_r"], "Hooves": LEGS, "Udder": "body", "Tail tuft": "tail"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.25, "Ears": 0.5, "Hooves": 0.25, "Muzzle": 0.5, "Horns": 0.5, "Udder": 0.5, "Tail tuft": 0.5},
	}


func _initialize() -> void:
	var display: Node3D = load("res://scenes/animals/cow_clay.tscn").instantiate()
	# The cow: sturdy straight legs, an unhurried walk, a hanging tail that swings like a pendulum.
	var settings := {
		"leg_length": M(0, 400).distance_to(M(0, CowClay.CY)),
		"swing_deg": 20.0,
		"lift": R(10),
		"bob": R(4),
		"roll_deg": 2.0,
		"head_turn_deg": 22.0,
		"ear_deg": 9.0,
		"tail_deg": 12.0,
		"tail_axis": Vector3.FORWARD,
	}
	var result := Bake.bake("cow", "CowClayRigged", display, spec(CowClay.new()), settings, "tools/build_cow_clay_rig.gd")
	display.free()
	quit(result)
