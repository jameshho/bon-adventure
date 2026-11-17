extends SceneTree
## Builds the rigged clay deer (16 Nov 2026) from the finished display scenes/animals/deer_clay.tscn
## into scenes/animals/deer_clay_rigged.scn: a skinned, seam-free skeleton
## (scripts/characters/clay_rig.gd) with the deer's settings for clay_animator.gd. Rebuild the
## display first when the deer changes.
##   godot --headless --path . --script res://tools/build_deer_clay_rig.gd
## Bone shapes are in the deer sheet's pixels like deer_clay.gd's shapes (side view: x toward the
## tail, y down; z lateral, + = the deer's left), placed with its D(), to_model() and FIT; the
## deer script is only read. The display stands mid-stride (deer_clay.gd's relaxed walk), so the
## legs follow their own joints and the walk swings about straight legs (leg_neutral_deg).
## Record: docs/evidence/hoofed-anim-20261116/notes.md.

const DeerClay := preload("res://scripts/characters/deer_clay.gd")
const Bake := preload("res://tools/clay_rig_bake.gd")


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return DeerClay.to_model(DeerClay.D(x, y, z)) * DeerClay.FIT


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * DeerClay.DH / (DeerClay.DY - DeerClay.DTOP)


const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
## The cloven hooves stay level while the legs swing (clay_animator.gd feet), so a straightened
## hind leg does not dig its toe into the ground.
const FEET := ["foot_fl", "foot_fr", "foot_bl", "foot_br"]
## deer_clay.gd's legs (its _dleg calls): joints [x, y] below the body, lateral z, hoof x, hip pivot.
const D_LEGS := [
	[[[882, 430], [884, 500], [884, 550]], 34.0, 886.0, Vector2(882, 420)],
	[[[872, 430], [866, 500], [862, 550]], -34.0, 862.0, Vector2(872, 420)],
	[[[1055, 430], [1084, 488], [1093, 530], [1094, 552]], 36.0, 1092.0, Vector2(1050, 415)],
	[[[1035, 440], [1040, 505], [1018, 550]], -36.0, 1012.0, Vector2(1040, 415)]]
const LEG_TOP := 468.0      # leg shapes start under the belly and haunches


func spec(deer) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(958, 405), "shapes": [
			[M(885, 402), M(1035, 405), R(52)], [M(885, 425, 30), M(885, 425, -30), R(26)],
			[M(1048, 420, 34), M(1048, 420, -34), R(32)]]},
		# The upright neck takes part of the head's look (clay_animator.gd neck_share).
		{"name": "neck", "parent": "body", "pivot": M(888, 382), "shapes": [
			[M(884, 362), M(866, 300), R(40)]]},
		{"name": "head", "parent": "neck", "pivot": M(864, 282), "shapes": [
			[M(848, 254), M(848, 254), R(45)], [M(838, 290, 26), M(838, 290, -26), R(30)],
			[M(812, 302), M(796, 292), R(28)]]},
		# The cream pom is its own mesh, rigid on this bone; it swishes from its base.
		{"name": "tail", "parent": "body", "pivot": M(1068, 372), "shapes": []},
	]
	for k in 4:
		var leg: Array = D_LEGS[k]
		var z: float = leg[1]
		var joints := [Vector2(leg[0][0][0], leg[0][0][1])]
		for j in range(1, leg[0].size()):
			joints.append(Vector2(leg[0][j][0], leg[0][j][1]))
		joints.append(Vector2(leg[2], 556.0))
		# Clip the chain where it leaves the body.
		var shapes := []
		for j in joints.size() - 1:
			var a: Vector2 = joints[j]
			var b: Vector2 = joints[j + 1]
			if b.y <= LEG_TOP:
				continue
			if a.y < LEG_TOP:
				a = a.lerp(b, (LEG_TOP - a.y) / (b.y - a.y))
			shapes.append([M(a.x, a.y, z), M(b.x, b.y, z), R(24.0 if j == 0 else 22.0)])
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(leg[3].x, leg[3].y, z * 0.95), "shapes": shapes})
	for k in 4:
		var leg: Array = D_LEGS[k]
		var x: float = leg[2]
		bones.append({"name": FEET[k], "parent": LEGS[k], "pivot": M(x, 556.0, leg[1]),
				"shapes": [[M(x - 4.0, 572.0, leg[1]), M(x, 580.0, leg[1]), R(21)]]})
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var s: float = side[1]
		var along := Vector3(0.6, -0.15, 0.78).normalized()    # sheet px: x back, y down, z out
		var at := func(t: float) -> Vector3:
			return M(883.0 + along.x * t, 236.0 + along.y * t, s * (46.0 + along.z * t))
		bones.append({"name": side[0], "parent": "head", "pivot": at.call(-2.0),
				"shapes": [[at.call(14.0), at.call(68.0), R(18)]]})
	deer._shape()
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var f: Array = deer._deer_eye_frame(side[1])
		var centre: Vector3 = f[0] + (f[1] as Vector3) * 0.4 * DeerClay.DK    # as deer_clay.gd's _deer_eyes
		eyes.append(Bake.eye(side[0], DeerClay.to_model(centre) * DeerClay.FIT,
				DeerClay.normal_to_model(f[1]), DeerClay.normal_to_model(f[3])))
	return {
		"bones": bones,
		"blend": R(9),
		# Hooves are part of the body mesh (deer_clay.gd), so they follow their legs' weights.
		"parts": {"Body": ["body", "neck", "head"] + LEGS + FEET, "Ears": ["head", "ear_l", "ear_r"],
				},
		# The antlers and the pom have their own softer material: rigid on their bones, unskinned,
		# so the deer stays one skinned surface.
		"attach": {"Antlers": "head", "Tail": "tail"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		"simplify": {"Body": 0.25, "Ears": 0.5},
	}


## The swing that brings each leg from its display pose to straight under its hip (degrees,
## + = the foot forward), for clay_animator.gd's leg_neutral_deg.
static func neutral() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for leg in D_LEGS:
		var pivot: Vector2 = leg[3]
		out.append(-rad_to_deg(atan2(pivot.x - float(leg[2]), DeerClay.DY - pivot.y)))
	return out


func _initialize() -> void:
	var display: Node3D = load("res://scenes/animals/deer_clay.tscn").instantiate()
	# The deer: long thin legs, a light high-stepping walk, big ears and a swishing pom.
	var settings := {
		"leg_length": M(0, 418).distance_to(M(0, DeerClay.DY)),
		"leg_neutral_deg": neutral(), "straighten_lift": true,
		"feet": PackedStringArray(FEET),
		"swing_deg": 22.0,
		"lift": R(16),
		"bob": R(5),
		"roll_deg": 2.0,
		"head_turn_deg": 28.0,
		"nod_deg": 4.0,
		"neck_share": 0.45,
		"ear_deg": 9.0,
		"tail_deg": 20.0,
	}
	var result := Bake.bake("deer", "DeerClayRigged", display, spec(DeerClay.new()), settings, "tools/build_deer_clay_rig.gd")
	display.free()
	quit(result)
