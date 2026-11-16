@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Plush sheep, sized to stand beside BonBon. Faces local -Z.
# One wool cloud of sculpted clumps covers the body, with a taller cap on the head
# around a smooth cream face; floppy sideways ears, brown hands and hooves.

@export var wool_color: Color = Color("fdf7ee")
@export var face_color: Color = Color("fbe6d2")
@export var muzzle_color: Color = Color("f0d1b2")
@export var sheep_ear_inner_color: Color = Color("f6a9a8")
@export var cheek_color: Color = Color("f9a7a6")
@export var sheep_hoof_color: Color = Color("8b6450")
@export var feature_color: Color = Color("4a2a1c")

const FACE_CENTER := Vector2(0.0, 1.50)
const FACE_RADII := Vector2(0.50, 0.29)

func _build() -> void:
	body_top = 2.18
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.28, 0.26),
		Vector3(0.32, 0.48, 0.44), Vector3(0.45, 0.60, 0.55),
		Vector3(0.62, 0.66, 0.61), Vector3(0.80, 0.68, 0.63),
		Vector3(1.00, 0.67, 0.62), Vector3(1.20, 0.65, 0.60),
		Vector3(1.40, 0.64, 0.58), Vector3(1.60, 0.63, 0.57),
		Vector3(1.80, 0.60, 0.54), Vector3(1.95, 0.53, 0.48),
		Vector3(2.06, 0.42, 0.38), Vector3(2.14, 0.26, 0.24),
		Vector3(body_top, 0.006, 0.006)
	]
	_color_fn = _coat
	var wool := _mat(wool_color)
	var inner := _mat(sheep_ear_inner_color)
	var blush := _mat(cheek_color, true)
	var snout := _soft_mat(muzzle_color, 0.6)
	var brown := _soft_mat(feature_color, 0.5)
	var hoof := _mat(sheep_hoof_color)

	# Deep creases between clumps make the coat read as wool rather than fur.
	_put("Torso/Visual", _furry_body(_coat_mat(), 0.11, 0.26, 12, _wool_mask, 0.8))

	# Floppy ears stick out sideways from under the wool cap, drooping at the tips.
	_put("Head/LeftEar", _pillow(_ear_ellipse(Vector2(-0.78, 1.76), 0.20, 0.12, 0.35), -0.14, 0.12, wool))
	_put("Head/RightEar", _pillow(_ear_ellipse(Vector2(0.78, 1.76), 0.20, 0.12, -0.35), -0.14, 0.12, wool))
	_put("Head/LeftEar/Inner", _pillow(_ear_ellipse(Vector2(-0.80, 1.755), 0.13, 0.068, 0.35), -0.185, -0.14, inner))
	_put("Head/RightEar/Inner", _pillow(_ear_ellipse(Vector2(0.80, 1.755), 0.13, 0.068, -0.35), -0.185, -0.14, inner))

	_put("Head/LeftCheek", _face_oval(-0.37, 1.42, 0.125, 0.115, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.37, 1.42, 0.125, 0.115, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.22, 1.56, 0.036, 0.041, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.22, 1.56, 0.036, 0.041, 0.020, brown))

	# Small tan muzzle with a little triangle nose and a short line below it.
	_put("Head/Muzzle", _face_oval(0.0, 1.47, 0.165, 0.095, 0.035, snout))
	var nose_z := _muzzle_z(0.0, 1.495)
	_put("Head/Muzzle/Nose", _pillow(_nose_shape(Vector2(0.0, 1.495), 0.045, 0.030), nose_z - 0.005, nose_z + 0.03, brown))
	_put("Head/Muzzle/Mouth", _tube([_on_muzzle(0.0, 1.475), _on_muzzle(0.0, 1.448), _on_muzzle(0.0, 1.422)], [0.010, 0.010, 0.009], brown))

	# Brown hand nubs poke out of the wool; white legs end in brown hooves.
	for side in [-1.0, 1.0]:
		var arm := "Arm/Visual" if side < 0 else "Arm_2/Visual"
		var foot := "Foot" if side < 0 else "Foot_2"
		_put(arm, _mitten_arm(side, 1.04, 0.72, hoof))
		_put(foot + "/Visual", _paw(side, 0.24, -0.06, 0.30, 0.15, 0.16, _point_mat(wool_color, sheep_hoof_color, Vector3(side * 0.24, -0.30, -0.06), 0.40, 0.42)))
		_put(foot + "/Claws", _claw_lines(side * 0.24, -0.225, [0.0], brown, 0.08))

# Wool everywhere except the face and the very bottom, piled higher on the crown.
func _wool_mask(point: Vector3, theta: float) -> float:
	var amount := smoothstep(0.22, 0.34, point.y)
	if point.z < 0.0:
		amount *= smoothstep(0.92, 1.05, _face_distance(point))
	return amount * (1.0 + 0.5 * smoothstep(1.85, 2.05, point.y))

func _coat(point: Vector3) -> Color:
	return face_color if point.z < 0.0 and _face_distance(point) < 1.0 else wool_color

func _face_distance(point: Vector3) -> float:
	return Vector2((point.x - FACE_CENTER.x) / FACE_RADII.x, (point.y - FACE_CENTER.y) / FACE_RADII.y).length()

func _muzzle_z(xx: float, yy: float) -> float:
	return _oval_z(xx, yy, 0.0, 1.47, 0.165, 0.095, 0.035)

func _on_muzzle(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _muzzle_z(xx, yy) - 0.006)
