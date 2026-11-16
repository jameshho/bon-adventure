@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Rounded plush bear, sized to stand beside BonBon. Faces local -Z.
# One egg-shaped head and body; shading, shadows and helpers come from plush_sculpt.gd.

@export var fur_color: Color = Color("c98a63")
@export var bear_ear_inner_color: Color = Color("f3cfa6")
@export var muzzle_color: Color = Color("f7dcb9")
@export var cheek_color: Color = Color("f59c90")
@export var feature_color: Color = Color("4a2a1c")
@export var claw_color: Color = Color("6b3d26")

func _build() -> void:
	body_top = 2.18
	# Egg silhouette: widest at the belly, a barely-there waist, then a broad domed head.
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.32, 0.28),
		Vector3(0.32, 0.52, 0.45), Vector3(0.45, 0.64, 0.55),
		Vector3(0.62, 0.715, 0.61), Vector3(0.80, 0.735, 0.63),
		Vector3(1.00, 0.72, 0.62), Vector3(1.20, 0.69, 0.59),
		Vector3(1.40, 0.67, 0.57), Vector3(1.60, 0.65, 0.55),
		Vector3(1.80, 0.63, 0.53), Vector3(1.95, 0.56, 0.48),
		Vector3(2.07, 0.43, 0.38), Vector3(2.15, 0.25, 0.22),
		Vector3(body_top, 0.006, 0.006)
	]
	var skin := _mat(fur_color)
	var inner := _mat(bear_ear_inner_color)
	var blush := _mat(cheek_color, true)
	var cream := _soft_mat(muzzle_color, 0.6)
	var brown := _soft_mat(feature_color, 0.5)
	var claw := _soft_mat(claw_color, 0.3)

	_put("Torso/Visual", _make_body(skin))

	# Big round ears with a cream inner pad set toward the face.
	_put("Head/LeftEar", _pillow(_circle(Vector2(-0.535, 2.03), 0.21), -0.14, 0.12, skin))
	_put("Head/RightEar", _pillow(_circle(Vector2(0.535, 2.03), 0.21), -0.14, 0.12, skin))
	_put("Head/LeftEar/Inner", _pillow(_circle(Vector2(-0.505, 1.995), 0.115), -0.185, -0.14, inner))
	_put("Head/RightEar/Inner", _pillow(_circle(Vector2(0.505, 1.995), 0.115), -0.185, -0.14, inner))

	_put("Head/LeftCheek", _face_oval(-0.413, 1.51, 0.152, 0.140, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.413, 1.51, 0.152, 0.140, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.227, 1.667, 0.040, 0.045, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.227, 1.667, 0.040, 0.045, 0.020, brown))

	# Wide cream muzzle, an oval nose on its top edge and a small smiling "w" mouth.
	_put("Head/Muzzle", _face_oval(0.0, 1.53, 0.22, 0.135, 0.06, cream))
	var nose_z := _muzzle_z(0.0, 1.605)
	_put("Head/Muzzle/Nose", _pillow(_ear_ellipse(Vector2(0.0, 1.605), 0.072, 0.046, 0.0), nose_z - 0.005, nose_z + 0.035, brown))
	_put("Head/Muzzle/Mouth", _mouth(brown))

	_put("Arm/Visual", _mitten_arm(-1.0, 1.18, 0.95, skin))
	_put("Arm_2/Visual", _mitten_arm(1.0, 1.18, 0.95, skin))
	_put("Foot/Visual", _paw(-1.0, 0.27, -0.12, 0.26, 0.22, 0.22, skin))
	_put("Foot_2/Visual", _paw(1.0, 0.27, -0.12, 0.26, 0.22, 0.22, skin))
	_put("Foot/Claws", _claw_lines(-0.27, -0.345, [0.0], claw))
	_put("Foot_2/Claws", _claw_lines(0.27, -0.345, [0.0], claw))

func _muzzle_z(xx: float, yy: float) -> float:
	return _oval_z(xx, yy, 0.0, 1.53, 0.22, 0.135, 0.06)

func _on_muzzle(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _muzzle_z(xx, yy) - 0.006)

func _mouth(material: Material) -> ArrayMesh:
	var left := _tube([_on_muzzle(0.0, 1.585), _on_muzzle(0.0, 1.555), _on_muzzle(-0.032, 1.530), _on_muzzle(-0.066, 1.534), _on_muzzle(-0.086, 1.552)], [0.0095, 0.0095, 0.0095, 0.0095, 0.0085], material)
	var right := _tube([_on_muzzle(0.0, 1.555), _on_muzzle(0.032, 1.530), _on_muzzle(0.066, 1.534), _on_muzzle(0.086, 1.552)], [0.0095, 0.0095, 0.0095, 0.0085], material)
	return _merge([left, right], material)
