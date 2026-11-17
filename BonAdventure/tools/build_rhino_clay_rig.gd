extends SceneTree
## Builds the rigged clay rhino (16 Nov 2026) from the finished display
## scenes/animals/rhino_clay.tscn into scenes/animals/rhino_clay_rigged.scn: a skinned, seam-free
## skeleton (scripts/characters/clay_rig.gd) with the rhino's settings for clay_animator.gd.
## Rebuild the display first when the rhino changes.
##   godot --headless --path . --script res://tools/build_rhino_clay_rig.gd
## Bone shapes are in the rhino sheet's pixels like rhino_clay.gd's shapes (side view: x toward
## the tail, y down; z lateral, + = the rhino's left), placed with its T() (body) and Hd() (the
## enlarged head) and to_model(); the rhino script is only read.
## Record: docs/evidence/hoofed-anim-20261116/notes.md.

const RhinoClay := preload("res://scripts/characters/rhino_clay.gd")
const Bake := preload("res://tools/clay_rig_bake.gd")


## Body sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return RhinoClay.to_model(RhinoClay.T(x, y, z)) / RhinoClay.FINE


## Head sheet pixel (rhino_clay.gd's Hd(): enlarged about the back of the jaw) -> model space.
static func H(x: float, y: float, z := 0.0) -> Vector3:
	return RhinoClay.to_model(RhinoClay.Hd(x, y, z)) / RhinoClay.FINE


## Body sheet pixels -> model units (a length); RH() for head sheet pixels.
static func R(px: float) -> float:
	return px * RhinoClay.RH / (RhinoClay.RGY - RhinoClay.RTOP)


static func RH(px: float) -> float:
	return R(px) * RhinoClay.HEAD_SCALE


const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
## Feet: the broad round feet with their toenails stay level while the leg swings
## (clay_animator.gd feet); without them the toenails dug about 4 cm into the ground.
const FEET := ["foot_fl", "foot_fr", "foot_bl", "foot_br"]
const LEG_TOP := 462.0      # leg shapes start under the barrel (the haunch puff rides the legs below it)


func spec(rhino) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		# The barrel, the shoulders and the folds of the neck behind the head.
		{"name": "body", "parent": "root", "pivot": M(1020, 365), "shapes": [
			[M(935, 355), M(1110, 365), R(93)], [M(905, 336), M(905, 336), R(84)],
			[M(1124, 414, 40), M(1124, 414, -40), R(62)]]},
		# The heavy head: skull, cheeks and the long snout. Both horns ride it rigidly.
		{"name": "head", "parent": "body", "pivot": M(886, 322), "shapes": [
			[H(855, 300), H(855, 300), RH(62)], [H(840, 345, 32), H(840, 345, -32), RH(42)],
			[H(795, 330), H(752, 358), RH(44)]]},
		{"name": "tail", "parent": "body", "pivot": M(1151, 336), "shapes": [
			[M(1155, 341), M(1174, 362), R(9)], [M(1174, 362), M(1187, 416), R(7)]]},
	]
	for k in 4:
		var leg: Array = RhinoClay.R_LEGS[k]
		var z: float = leg[3]
		var hip: Vector2 = leg[0]
		var knee: Vector2 = leg[1]
		var ankle: Vector2 = leg[2]
		var top := hip.lerp(knee, (LEG_TOP - hip.y) / (knee.y - hip.y))
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(hip.x, hip.y - 5.0, z * 0.95), "shapes": [
				[M(top.x, top.y, z), M(knee.x, knee.y, z), R(48)], [M(knee.x, knee.y, z), M(ankle.x, ankle.y, z), R(47)],
				[M(ankle.x, ankle.y, z), M(ankle.x, ankle.y + 3.0, z), R(44)]]})
	for k in 4:
		var leg: Array = RhinoClay.R_LEGS[k]
		var ankle: Vector2 = leg[2]
		bones.append({"name": FEET[k], "parent": LEGS[k], "pivot": M(ankle.x, ankle.y, leg[3]),
				"shapes": [[M(ankle.x - 1.0, RhinoClay.RGY - 20.0, leg[3]), M(ankle.x - 1.0, RhinoClay.RGY - 20.0, leg[3]), R(48)]]})
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		var along := Vector3(0.07, -0.95, 0.3).normalized()    # head sheet px: x back, y down, z out
		var at := func(t: float) -> Vector3:
			return H(868.0 + along.x * t, 227.0 + along.y * t, s * (60.0 + along.z * t))
		bones.append({"name": side[0], "parent": "head", "pivot": at.call(-30.0),
				"shapes": [[at.call(-10.0), at.call(26.0), RH(15)]]})
	rhino._shape()
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var eye: Array = rhino._rhino_eye(side[1])
		var frame: Basis = eye[1]
		eyes.append(Bake.eye(side[0], RhinoClay.to_model(eye[0]) / RhinoClay.FINE,
				RhinoClay.normal_to_model(frame.z), RhinoClay.normal_to_model(frame.y)))
	return {
		"bones": bones,
		"blend": R(12),
		"parts": {"Body": ["body", "head", "tail"] + LEGS + FEET, "Horns": "head",
				"Ears": ["head", "ear_l", "ear_r"], "Tail tuft": "tail"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.25, "Ears": 0.25, "Horns": 0.5, "Tail tuft": 0.5},
	}


## The swing that brings each leg from its display pose (the far pair a short step ahead) to
## straight under its hip, for clay_animator.gd's leg_neutral_deg.
static func neutral() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for leg in RhinoClay.R_LEGS:
		var hip: Vector2 = leg[0]
		var ankle: Vector2 = leg[2]
		out.append(-rad_to_deg(atan2(hip.x - ankle.x, RhinoClay.RGY - hip.y)))
	return out


func _initialize() -> void:
	var display: Node3D = load("res://scenes/animals/rhino_clay.tscn").instantiate()
	# The rhino: short heavy columns, a slow rolling walk, a small head turn.
	var settings := {
		"leg_length": M(0, 400).distance_to(M(0, RhinoClay.RGY)),
		"leg_neutral_deg": neutral(), "straighten_lift": true,
		"feet": PackedStringArray(FEET),
		"swing_deg": 18.0,
		"lift": R(8),
		"bob": R(3),
		"roll_deg": 3.0,
		"head_turn_deg": 18.0,
		"nod_deg": 3.0,
		"ear_deg": 10.0,
		"tail_deg": 14.0,
		"tail_axis": Vector3.FORWARD,
	}
	var result := Bake.bake("rhino", "RhinoClayRigged", display, spec(RhinoClay.new()), settings, "tools/build_rhino_clay_rig.gd")
	display.free()
	quit(result)
