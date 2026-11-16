@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Siamese plush cat, sized to stand beside BonBon. Faces local -Z.
# Cream body with soft brown color points on the face, ears, paws, feet and tail.
# Shading, color points and helpers come from plush_sculpt.gd.

@export var fur_color: Color = Color("f5e6d3")
@export var point_color: Color = Color("6e4330")
@export var cat_ear_inner_color: Color = Color("f6a9a5")
@export var cheek_color: Color = Color("f9aaa6")
@export var feature_color: Color = Color("3e2216")
@export var claw_color: Color = Color("4a2c1f")

func _build() -> void:
	body_top = 2.14
	# Big round head on a smaller egg body, with a soft neck between them.
	_body_profile = [
		Vector3(0.17, 0.00648, 0.00624), Vector3(0.22, 0.324, 0.281),
		Vector3(0.32, 0.518, 0.447), Vector3(0.45, 0.626, 0.541),
		Vector3(0.62, 0.68, 0.582), Vector3(0.8, 0.68, 0.582),
		Vector3(1, 0.626, 0.541), Vector3(1.15, 0.583, 0.499),
		Vector3(1.25, 0.605, 0.52), Vector3(1.4, 0.67, 0.551),
		Vector3(1.6, 0.702, 0.572), Vector3(1.8, 0.691, 0.562),
		Vector3(1.96, 0.605, 0.499), Vector3(2.06, 0.454, 0.385),
		Vector3(2.12, 0.238, 0.208), Vector3(body_top, 0.006, 0.006)
	]
	var blush := _mat(cheek_color, true)
	var points := _mat(point_color)
	var inner := _mat(cat_ear_inner_color)
	var brown := _soft_mat(feature_color, 0.5)
	var claw := _soft_mat(claw_color, 0.3)

	# The dark mask fades out from the nose across the face.
	_put("Torso/Visual", _make_body(_point_mat(fur_color, point_color, Vector3(0.0, 1.60, -0.56), 0.02, 0.48, 0.78)))

	_put("Head/LeftEar", _pillow(_ear_triangle(Vector2(-0.46, 1.95), 0.42, 0.40, 0.24), -0.12, 0.12, points))
	_put("Head/RightEar", _pillow(_ear_triangle(Vector2(0.46, 1.95), 0.42, 0.40, -0.24), -0.12, 0.12, points))
	_put("Head/LeftEar/Inner", _pillow(_ear_triangle(Vector2(-0.475, 2.01), 0.23, 0.25, 0.24), -0.16, -0.12, inner))
	_put("Head/RightEar/Inner", _pillow(_ear_triangle(Vector2(0.475, 2.01), 0.23, 0.25, -0.24), -0.16, -0.12, inner))

	_put("Head/LeftCheek", _face_oval(-0.46, 1.51, 0.150, 0.140, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.46, 1.51, 0.150, 0.140, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.27, 1.656, 0.042, 0.047, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.27, 1.656, 0.042, 0.047, 0.020, brown))

	var nose_z := _front_z(0.0, 1.635)
	_put("Head/Nose", _pillow(_nose_shape(Vector2(0.0, 1.635), 0.062, 0.042), nose_z - 0.03, nose_z + 0.01, brown))
	_put("Head/Mouth", _mouth(brown))
	_put("Head/Whiskers", _whiskers(brown))

	# Paws and feet darken toward their tips like Siamese points.
	for side in [-1.0, 1.0]:
		var arm := "Arm/Visual" if side < 0 else "Arm_2/Visual"
		var foot := "Foot" if side < 0 else "Foot_2"
		_put(arm, _mitten_arm(side, 1.08, 0.85, _point_mat(fur_color, point_color, _mitten_tip(side, 1.08, 0.85), 0.08, 0.24)))
		_put(foot + "/Visual", _paw(side, 0.24, -0.10, 0.25, 0.18, 0.19, _point_mat(fur_color, point_color, Vector3(side * 0.24, -0.05, -0.10), 0.24, 0.42)))
		_put(foot + "/Claws", _claw_lines(side * 0.24, -0.295, [-0.04, 0.04], claw))

	# Thick brown tail leaves the center of the lower back and curls up behind.
	_put("Tail", _tube([
		Vector3(0.0, 0.40, 0.42), Vector3(0.0, 0.34, 0.62), Vector3(0.0, 0.46, 0.78),
		Vector3(0.0, 0.68, 0.84), Vector3(0.0, 0.90, 0.80), Vector3(0.0, 1.06, 0.72)
	], [0.085, 0.090, 0.090, 0.088, 0.082, 0.070], points))

func _on_face(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _front_z(xx, yy) - 0.03)

func _mouth(material: Material) -> ArrayMesh:
	var left := _tube([_on_face(0.0, 1.600), _on_face(0.0, 1.585), _on_face(-0.050, 1.560), _on_face(-0.100, 1.570), _on_face(-0.128, 1.595)], [0.010, 0.010, 0.010, 0.010, 0.009], material)
	var right := _tube([_on_face(0.0, 1.585), _on_face(0.050, 1.560), _on_face(0.100, 1.570), _on_face(0.128, 1.595)], [0.010, 0.010, 0.010, 0.009], material)
	return _merge([left, right], material)

# Two whiskers per side, rooted at the face edge and reaching past the silhouette.
func _whiskers(material: Material) -> ArrayMesh:
	var parts: Array = []
	for side in [-1.0, 1.0]:
		for pair in [[1.575, 1.590], [1.525, 1.495]]:
			var root := _on_face(side * 0.64, float(pair[0]))
			var tip := Vector3(side * 0.92, float(pair[1]), root.z - 0.02)
			parts.append(_tube([root, root.lerp(tip, 0.5) + Vector3(0, 0.006, 0), tip], [0.012, 0.011, 0.009], material))
	return _merge(parts, material)
