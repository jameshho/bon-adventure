extends "res://tools/clay_rig_tool.gd"
## Builds the rigged clay black bears (16 Nov 2026) from the finished displays
## scenes/animals/black_bear_clay.tscn (the cub) and black_bear_adult_clay.tscn into
## scenes/animals/black_bear_clay_rigged.scn and black_bear_adult_clay_rigged.scn: skinned,
## seam-free skeletons (scripts/characters/clay_rig.gd) with a heavy, rolling walk for
## scripts/characters/clay_animator.gd. Rebuild the displays first when the bears change.
##   godot --headless --path . --script res://tools/build_black_bear_clay_rig.gd
## Bone shapes are in the bear sheet's pixels like black_bear_clay.gd's shapes (side view: x
## toward the tail, y down; z lateral, + = the bear's left) and placed with its T(), to_model()
## and the cub's body squash (_body_squash: the cub's torso and legs are drawn in toward the
## neck, its head is not). The adult is the same sheet with its own torso and legs, enlarged by
## ADULT_H / BH. The bear scripts are only read, never changed.

const Cub := preload("res://scripts/characters/black_bear_clay.gd")
const Adult := preload("res://scripts/characters/black_bear_adult_clay.gd")

var bear          # the bear script instance being rigged
var grow := 1.0   # adult: ADULT_H / BH


func rigs() -> Array:
	var out := []
	for adult in [false, true]:
		bear = Adult.new() if adult else Cub.new()
		grow = Adult.ADULT_H / Cub.BH if adult else 1.0
		bear._shape()
		var prefab := "black_bear_adult_clay" if adult else "black_bear_clay"
		var rig_spec := spec(adult)
		out.append({"scene": "res://scenes/animals/%s.tscn" % prefab,
				"out": "res://scenes/animals/%s_rigged.scn" % prefab,
				"folder": "res://scenes/animals/clay_meshes/%s_rig/" % prefab.trim_suffix("_clay"),
				"name": "BlackBearAdultClayRigged" if adult else "BlackBearCubClayRigged",
				"spec": rig_spec, "animator": settings})
	return out


## Sheet pixel -> the display's model space; `squash`: a point of the torso or legs, which the
## cub draws in toward the neck (black_bear_clay.gd _squash).
func M(x: float, y: float, z := 0.0, squash := true) -> Vector3:
	var p: Vector3 = Cub.T(x, y, z)
	var f: Vector3 = bear._body_squash()
	if squash and f != Vector3.ONE:
		var pivot: float = Cub.T(880, 0).x
		p = Vector3(pivot + (p.x - pivot) * f.x, p.y * f.y, p.z * f.z)
	return Cub.to_model(p) / Cub.FINE * grow


## Sheet pixels -> model units (a length); squashed lengths shrink with the cub's body.
func R(px: float, squash := true) -> float:
	var f: Vector3 = bear._body_squash()
	return M(px, 0, 0, false).distance_to(M(0, 0, 0, false)) * (minf(f.y, f.z) if squash else 1.0)


var settings := {}


func spec(adult: bool) -> Dictionary:
	var bones := [{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []}]
	if adult:
		bones.append({"name": "body", "parent": "root", "pivot": M(985, 390), "shapes": [
			[M(905, 372), M(1050, 392), R(98)], [M(872, 404), M(872, 404), R(70)],
			[M(1078, 408), M(1078, 408), R(88)], [M(915, 302), M(975, 318), R(55)],
			[M(1090, 430, 40), M(1090, 430, -40), R(70)]]})
	else:
		bones.append({"name": "body", "parent": "root", "pivot": M(960, 385), "shapes": [
			[M(875, 375), M(1050, 382), R(88)], [M(920, 425), M(1060, 425), R(52)],
			[M(915, 302), M(975, 318), R(58)], [M(1100, 420, 40), M(1100, 420, -40), R(62)]]})
	# Head (never squashed): the skull and jowls; the muzzle, nose and ears are rigid on it.
	bones.append({"name": "head", "parent": "body", "pivot": M(885, 282, 0, false), "shapes": [
		[M(850, 258, 0, false), M(850, 258, 0, false), R(64, false)],
		[M(848, 292, 40, false), M(848, 292, -40, false), R(42, false)],
		[M(820, 270, 0, false), M(790, 285, 0, false), R(36, false)]]})
	bones.append({"name": "tail", "parent": "body", "pivot": M(1128, 356), "shapes": [
		[M(1141, 351), M(1145, 351), R(24)]]})
	# Legs, as black_bear_clay.gd's _bleg / black_bear_adult_clay.gd's _aleg: the pivot at the
	# top of the leg in the shoulder or thigh; the shape from below the torso to the paw.
	var legs: Array
	if adult:
		legs = [["leg_fl", [Vector2(922, 420), Vector2(914, 506)], 906.0, 64.0, 50.0],
				["leg_fr", [Vector2(890, 420), Vector2(852, 466), Vector2(828, 506)], 819.0, -64.0, 49.0],
				["leg_bl", [Vector2(1098, 440), Vector2(1108, 478), Vector2(1103, 507)], 1100.0, 66.0, 52.0],
				["leg_br", [Vector2(1072, 445), Vector2(1048, 478), Vector2(1030, 507)], 1023.0, -66.0, 51.0]]
	else:
		legs = [["leg_fl", [Vector2(884, 410), Vector2(880, 520)], 874.0, 62.0, 43.0],
				["leg_fr", [Vector2(858, 410), Vector2(818, 520)], 812.0, -62.0, 43.0],
				["leg_bl", [Vector2(1106, 425), Vector2(1110, 520)], 1104.0, 64.0, 50.0],
				["leg_br", [Vector2(1050, 425), Vector2(1014, 520)], 1008.0, -64.0, 50.0]]
	var paw_y := Cub.BGY - (17.0 if adult else 15.0)
	var start_y := 468.0   # under the torso: above it the shoulder and thigh go with the body
	var names := []
	var neutral := PackedFloat32Array()
	var length := 0.0
	for l in legs:
		var joints: Array = l[1]
		var z: float = l[3]
		var top := chain_at(joints, start_y)
		var pts := [M(top.x, top.y, z)]
		for j in joints:
			if j.y > start_y:
				pts.append(M(j.x, j.y, z))
		var paw := M(l[2], paw_y, z)
		pts.append(paw)
		var pivot := M(joints[0].x, joints[0].y, z)
		bones.append(leg(l[0], pivot, pts, R(l[4])))
		names.append(l[0])
		neutral.append(-lean_deg(pivot, M(l[2], Cub.BGY, z)))
		length += pivot.y / 4.0
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var hit: Array = bear._bear_eye(side[1])
		var b: Basis = hit[1]
		var origin: Vector3 = Cub.to_model(hit[0]) / Cub.FINE * grow
		eyes.append(eye(side[0], origin, Cub.normal_to_model(b.z), Cub.normal_to_model(b.y)))
	# A heavy, rolling walk: one foot at a time, hind then front on each side (a lateral walk),
	# the body rolling over the planted side; short swing, low lift, a slow nod.
	settings = {
		"leg_phase": PackedFloat32Array([0.25, 0.75, 0.0, 0.5]),
		"leg_neutral_deg": neutral,
		"keep_feet_down": true,
		"foot_reach": R(52),
		"leg_length": length,
		"swing_deg": 17.0,
		"lift": R(12),
		"bob": R(4),
		"roll_deg": 5.0,
		"nod_deg": 2.5,
		"shift_deg": 1.8,
		"tail_deg": 9.0,
		"ear_deg": 0.0,
		"head_turn_deg": 24.0,
	}
	return {
		"bones": bones,
		"blend": R(12, false),
		"parts": {"Body": ["body", "head", "tail"] + names, "Muzzle": "head", "Ears": "head", "Claws": names},
		# The lid lines (in Face details, round each eye) close with the eye; the brows stay.
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes,
				"lids": {"mesh": "Face details", "reach": R(17.0 + 2.0 * bear._face_youth(), false)}},
		"keep": ["Footprint"],
		"merge": true,
		# The nose has its own, shinier material: as a skinned part it would be a second skinned
		# surface, so it rides the Head attachment unskinned (it is rigid on the head anyway).
		"on_head": ["Face details", "Nose"],
		"simplify": {"Body": 0.25, "Ears": 0.3, "Muzzle": 0.35, "Claws": 0.35},
	}

