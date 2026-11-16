@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Rounded plush lion, sized to stand beside BonBon. Faces local -Z.
# Shading, shadows and shape helpers come from plush_sculpt.gd.
# Every visible part lives in an ordinary selectable MeshInstance3D node.

@export var fur_color: Color = Color("fad696")
@export var mane_color: Color = Color("b8623a")
@export var lion_ear_inner_color: Color = Color("f5a7a0")
@export var cheek_color: Color = Color("f7a5a3")
@export var muzzle_color: Color = Color("fdf0dc")
@export var feature_color: Color = Color("5a2e1c")
@export var toe_color: Color = Color("a8653d")

const MANE_CENTER := Vector2(0.0, 1.60)

func _build() -> void:
	body_top = 2.06
	# Round belly, a slim neck hidden by the mane collar and a wide flat-fronted face.
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.30, 0.28),
		Vector3(0.32, 0.52, 0.47), Vector3(0.45, 0.65, 0.59),
		Vector3(0.62, 0.71, 0.64), Vector3(0.80, 0.70, 0.63),
		Vector3(0.98, 0.64, 0.57), Vector3(1.12, 0.58, 0.50),
		Vector3(1.24, 0.60, 0.48), Vector3(1.40, 0.66, 0.50),
		Vector3(1.58, 0.68, 0.51), Vector3(1.76, 0.64, 0.48),
		Vector3(1.90, 0.55, 0.43), Vector3(1.99, 0.40, 0.34),
		Vector3(2.04, 0.22, 0.20), Vector3(body_top, 0.006, 0.006)
	]
	var skin := _mat(fur_color)
	var mane := _mat(mane_color)
	var inner := _mat(lion_ear_inner_color)
	var blush := _mat(cheek_color, true)
	var cream := _soft_mat(muzzle_color, 0.6)
	var brown := _soft_mat(feature_color, 0.5)
	var toe := _mat(toe_color)

	_put("Torso/Visual", _make_body(skin))

	# Cloud mane: a ring of overlapping puffs framing the face, a fuller rear
	# ring and a back cap so the head reads as maned from every side.
	_put("Mane/Front", _blobs(_mane_front_puffs(), mane))
	_put("Mane/Back", _blobs(_mane_back_puffs(), mane))

	# Round ears sit on the mane at the top corners of the face.
	_put("Head/LeftEar", _pillow(_circle(Vector2(-0.44, 1.97), 0.165), -0.46, -0.18, skin))
	_put("Head/RightEar", _pillow(_circle(Vector2(0.44, 1.97), 0.165), -0.46, -0.18, skin))
	_put("Head/LeftEar/Inner", _pillow(_circle(Vector2(-0.455, 1.96), 0.098), -0.507, -0.46, inner))
	_put("Head/RightEar/Inner", _pillow(_circle(Vector2(0.455, 1.96), 0.098), -0.507, -0.46, inner))

	_put("Head/LeftCheek", _face_oval(-0.395, 1.43, 0.138, 0.130, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.395, 1.43, 0.138, 0.130, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.225, 1.60, 0.040, 0.045, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.225, 1.60, 0.040, 0.045, 0.020, brown))

	# Soft cream muzzle with a rounded triangle nose and a small "w" mouth.
	_put("Head/Muzzle", _face_oval(0.0, 1.475, 0.165, 0.125, 0.055, cream))
	var nose_z := _muzzle_z(0.0, 1.515)
	_put("Head/Muzzle/Nose", _pillow(_nose_triangle(), nose_z - 0.005, nose_z + 0.035, brown))
	_put("Head/Muzzle/Mouth", _mouth(brown))

	_put("Arm/Visual", _mitten_arm(-1.0, 1.04, 0.85, skin))
	_put("Arm_2/Visual", _mitten_arm(1.0, 1.04, 0.85, skin))
	_put("Foot/Visual", _foot(-1.0, skin))
	_put("Foot_2/Visual", _foot(1.0, skin))
	_put("Foot/Toes", _toes(-1.0, toe))
	_put("Foot_2/Toes", _toes(1.0, toe))

	# Tail curls out from the lower back on the lion's left and ends in a mane-colored tuft.
	_put("Tail", _tube([
		Vector3(-0.30, 0.42, 0.50), Vector3(-0.55, 0.38, 0.58), Vector3(-0.76, 0.44, 0.56),
		Vector3(-0.88, 0.58, 0.48), Vector3(-0.92, 0.74, 0.42), Vector3(-0.92, 0.86, 0.39)
	], [0.048, 0.046, 0.043, 0.040, 0.037, 0.034], skin))
	_put("Tail/Tuft", _blobs([
		[Vector3(-0.92, 0.95, 0.385), Vector3(0.105, 0.125, 0.105)],
		[Vector3(-0.905, 1.055, 0.385), Vector3(0.055, 0.070, 0.055)]
	], mane))

func _muzzle_z(xx: float, yy: float) -> float:
	return _oval_z(xx, yy, 0.0, 1.475, 0.165, 0.125, 0.055)

func _mane_front_puffs() -> Array:
	# A broad backing disc joins the puffs so the mane reads as one scalloped cloud.
	var puffs: Array = [[Vector3(0.0, MANE_CENTER.y - 0.02, 0.02), Vector3(0.80, 0.70, 0.32)]]
	var count := 15
	for i in range(count):
		# Start at the bottom so the collar puff sits centered under the chin.
		var theta := -PI * 0.5 + TAU * float(i) / float(count)
		var low := maxf(0.0, -sin(theta))
		var center := MANE_CENTER + Vector2(cos(theta) * 0.69, sin(theta) * (0.58 + 0.05 * low))
		# Lower puffs come forward to drape over the chest like the collar in the art.
		var depth := lerpf(-0.03, -0.36, pow(low, 1.2))
		var size := 0.200 + 0.035 * low
		puffs.append([Vector3(center.x, center.y, depth), Vector3(size, size * 0.92, 0.27 + 0.06 * low)])
	return puffs

func _mane_back_puffs() -> Array:
	var puffs: Array = []
	var count := 12
	for i in range(count):
		var theta := -PI * 0.5 + TAU * (float(i) + 0.5) / float(count)
		var center := MANE_CENTER + Vector2(cos(theta) * 0.60, sin(theta) * 0.50)
		puffs.append([Vector3(center.x, center.y, 0.24), Vector3(0.24, 0.23, 0.26)])
	puffs.append([Vector3(0.0, MANE_CENTER.y, 0.30), Vector3(0.66, 0.58, 0.30)])
	return puffs

func _nose_triangle() -> PackedVector2Array:
	# Rounded downward-pointing triangle: wide top, soft point at the bottom.
	var result := PackedVector2Array()
	var count := 60
	for i in range(count):
		var theta := TAU * float(i) / float(count)
		var xx := cos(theta) * 0.068
		var yy := sin(theta) * 0.046
		xx *= lerpf(0.42, 1.0, clampf((yy + 0.046) / 0.092, 0.0, 1.0))
		result.append(Vector2(xx, 1.515 + yy))
	return result

func _on_muzzle(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _muzzle_z(xx, yy) - 0.006)

func _mouth(material: Material) -> ArrayMesh:
	var left := _tube([_on_muzzle(0.0, 1.475), _on_muzzle(0.0, 1.448), _on_muzzle(-0.024, 1.428), _on_muzzle(-0.052, 1.426)], [0.0085, 0.0085, 0.0085, 0.0075], material)
	var right := _tube([_on_muzzle(0.0, 1.448), _on_muzzle(0.024, 1.428), _on_muzzle(0.052, 1.426)], [0.0085, 0.0085, 0.0075], material)
	return _merge([left, right], material)
