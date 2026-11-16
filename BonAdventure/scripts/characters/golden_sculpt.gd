@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Plush golden retriever, sized to stand beside BonBon. Faces local -Z.
# Round golden body with a scalloped V-shaped chest bib, feathered flanks,
# big feathered floppy ears and a feathered fan tail up the center of the back.

@export var fur_color: Color = Color("ecb97d")
@export var ear_color: Color = Color("e3a96c")
@export var bib_color: Color = Color("f6d6a6")
@export var muzzle_color: Color = Color("f7e2bc")
@export var cheek_color: Color = Color("f8a39c")
@export var feature_color: Color = Color("4a2a1c")
@export var claw_color: Color = Color("b07a46")

func _build() -> void:
	body_top = 2.22
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.30, 0.27),
		Vector3(0.32, 0.52, 0.46), Vector3(0.45, 0.64, 0.57),
		Vector3(0.62, 0.69, 0.61), Vector3(0.80, 0.70, 0.62),
		Vector3(1.00, 0.67, 0.60), Vector3(1.20, 0.62, 0.56),
		Vector3(1.40, 0.61, 0.55), Vector3(1.60, 0.62, 0.55),
		Vector3(1.80, 0.60, 0.53), Vector3(1.95, 0.54, 0.48),
		Vector3(2.07, 0.42, 0.38), Vector3(2.17, 0.24, 0.22),
		Vector3(body_top, 0.006, 0.006)
	]
	var skin := _mat(fur_color)
	var ears := _mat(ear_color)
	var blush := _mat(cheek_color, true)
	var snout := _soft_mat(muzzle_color, 0.6)
	var brown := _soft_mat(feature_color, 0.5)
	var claw := _soft_mat(claw_color, 0.3)

	# The bib is a lighter cream, so it reads as fluffy chest fur.
	_color_fn = _coat
	_put("Torso/Visual", _furry_body(_coat_mat(), 0.05, 0.0, 0, _coat_mask))

	# Feathered floppy ears: the zig-zag outer edge smooths into soft fringe scallops.
	var ear := _smooth_outline(PackedVector2Array([
		Vector2(-0.30, 2.12), Vector2(-0.56, 2.15), Vector2(-0.74, 2.04), Vector2(-0.86, 1.86),
		Vector2(-0.93, 1.72), Vector2(-0.87, 1.66), Vector2(-0.94, 1.56), Vector2(-0.87, 1.50),
		Vector2(-0.89, 1.40), Vector2(-0.80, 1.37), Vector2(-0.76, 1.30), Vector2(-0.68, 1.34),
		Vector2(-0.62, 1.42), Vector2(-0.56, 1.40), Vector2(-0.52, 1.52), Vector2(-0.50, 1.74),
		Vector2(-0.42, 1.98)
	]), 3)
	_put("Head/LeftEar", _pillow(ear, -0.12, 0.22, ears))
	_put("Head/RightEar", _pillow(_mirror(ear), -0.12, 0.22, ears))

	_put("Head/LeftCheek", _face_oval(-0.38, 1.60, 0.125, 0.118, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.38, 1.60, 0.125, 0.118, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.24, 1.80, 0.041, 0.046, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.24, 1.80, 0.041, 0.046, 0.020, brown))

	_put("Head/Muzzle", _face_oval(0.0, 1.60, 0.245, 0.14, 0.06, snout))
	var nose_z := _muzzle_z(0.0, 1.68)
	_put("Head/Muzzle/Nose", _pillow(_ear_ellipse(Vector2(0.0, 1.68), 0.075, 0.05, 0.0), nose_z - 0.005, nose_z + 0.04, brown))
	_put("Head/Muzzle/Mouth", _mouth(brown))

	_put("Arm/Visual", _mitten_arm(-1.0, 1.2, 0.9, skin))
	_put("Arm_2/Visual", _mitten_arm(1.0, 1.2, 0.9, skin))
	_put("Foot/Visual", _paw(-1.0, 0.25, -0.11, 0.24, 0.16, 0.18, skin))
	_put("Foot_2/Visual", _paw(1.0, 0.25, -0.11, 0.24, 0.16, 0.18, skin))
	_put("Foot/Claws", _claw_lines(-0.25, -0.295, [0.0], claw))
	_put("Foot_2/Claws", _claw_lines(0.25, -0.295, [0.0], claw))

	# Feathered fan tail drawn as a side outline (depth, height) and stood up on the center line.
	var tail := _smooth_outline(PackedVector2Array([
		Vector2(0.40, 0.42), Vector2(0.62, 0.36), Vector2(0.80, 0.40), Vector2(0.92, 0.50),
		Vector2(1.00, 0.60), Vector2(0.94, 0.66), Vector2(1.04, 0.76), Vector2(0.96, 0.82),
		Vector2(1.04, 0.94), Vector2(0.95, 0.98), Vector2(0.98, 1.10), Vector2(0.88, 1.12),
		Vector2(0.80, 1.02), Vector2(0.70, 0.84), Vector2(0.58, 0.66), Vector2(0.46, 0.56)
	]), 3)
	_put("Tail", _moved(_pillow(tail, -0.09, 0.09, skin), SIDEWAYS))

# Where the coat is feathered: a soft V-shaped chest bib whose lower edges hang in
# scallops, starting well below the chin and fading in at its top so it reads as
# chest fur rather than a beard, plus scalloped fringes along the lower flanks.
# Nothing is raised beside the face, which made earlier versions read as sideburns.
func _coat_mask(point: Vector3, theta: float) -> float:
	var r := _section(point.y)
	var fringe := pow(absf(sin(PI * point.y / 0.11)), 0.6)
	var outline := smoothstep(0.84, 0.97, absf(point.x) / r.x) * fringe
	var bib := _bib(point)
	var flanks := outline * smoothstep(0.30, 0.40, point.y) * (1.0 - smoothstep(0.80, 0.92, point.y))
	return maxf(bib * 0.6, flanks * 0.7)

# Coat colour: cream fur with the lighter bib. A named method rather than a lambda, like the
# other coats, so the sculpt cache can keep it.
func _coat(point: Vector3) -> Color:
	return fur_color.lerp(bib_color, clampf(_bib(point) * 1.4, 0.0, 1.0))

# The V-shaped chest bib: hangs in scallops, fades in below the chin.
func _bib(point: Vector3) -> float:
	if point.z >= 0.0:
		return 0.0
	var hang := pow(absf(cos(point.x * PI / 0.13)), 0.6)
	var edge := 0.86 + 0.85 * absf(point.x) - 0.06 * hang
	var facing := -point.z / _section(point.y).y
	return smoothstep(edge - 0.02, edge + 0.02, point.y) * (1.0 - smoothstep(1.05, 1.25, point.y)) * smoothstep(0.2, 0.5, facing)

func _muzzle_z(xx: float, yy: float) -> float:
	return _oval_z(xx, yy, 0.0, 1.60, 0.245, 0.14, 0.06)

func _on_muzzle(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _muzzle_z(xx, yy) - 0.006)

func _mouth(material: Material) -> ArrayMesh:
	var left := _tube([_on_muzzle(0.0, 1.632), _on_muzzle(0.0, 1.600), _on_muzzle(-0.060, 1.574), _on_muzzle(-0.118, 1.584), _on_muzzle(-0.145, 1.606)], [0.011, 0.011, 0.011, 0.011, 0.010], material)
	var right := _tube([_on_muzzle(0.0, 1.600), _on_muzzle(0.060, 1.574), _on_muzzle(0.118, 1.584), _on_muzzle(0.145, 1.606)], [0.011, 0.011, 0.011, 0.010], material)
	return _merge([left, right], material)
