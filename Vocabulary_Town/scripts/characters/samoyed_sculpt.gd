@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Fluffy white plush Samoyed, sized to stand beside BonBon. Faces local -Z.
# One round head-and-body whose upper half is a continuous sculpted fur coat: soft
# layered scallops over a broad crown and down the head outline, ending in a
# scalloped ruff below the face. The face and lower belly stay smooth like the art.

@export var fur_color: Color = Color("fbf3e8")
@export var dog_ear_inner_color: Color = Color("f6b4b6")
@export var muzzle_color: Color = Color("fffaf3")
@export var cheek_color: Color = Color("f8b4b6")
@export var feature_color: Color = Color("3e2418")
@export var claw_color: Color = Color("a8968a")

const FACE_CENTER := Vector2(0.0, 1.63)
const FACE_RADII := Vector2(0.66, 0.31)

func _build() -> void:
	body_top = 2.065
	# Broad, nearly flat crown; the fur adds the scalloped outline on top of this.
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.34, 0.30),
		Vector3(0.32, 0.56, 0.50), Vector3(0.45, 0.70, 0.62),
		Vector3(0.62, 0.78, 0.69), Vector3(0.80, 0.81, 0.71),
		Vector3(1.00, 0.79, 0.70), Vector3(1.20, 0.72, 0.64),
		Vector3(1.40, 0.71, 0.63), Vector3(1.60, 0.72, 0.63),
		Vector3(1.76, 0.69, 0.60), Vector3(1.88, 0.63, 0.55),
		Vector3(1.96, 0.55, 0.48), Vector3(2.02, 0.42, 0.38),
		Vector3(2.05, 0.25, 0.23), Vector3(body_top, 0.006, 0.006)
	]
	var skin := _mat(fur_color)
	var inner := _mat(dog_ear_inner_color)
	var blush := _mat(cheek_color, true)
	var snout := _soft_mat(muzzle_color, 0.6)
	var brown := _soft_mat(feature_color, 0.5)
	var claw := _soft_mat(claw_color, 0.3)

	_put("Torso/Visual", _furry_body(skin, 0.08, 0.22, 24, _coat_mask, 0.45))

	# Tall pointed ears rise from the crown's corners and lean slightly outward.
	_put("Head/LeftEar", _pillow(_ear_triangle(Vector2(-0.41, 1.95), 0.42, 0.44, 0.18), -0.26, 0.04, skin))
	_put("Head/RightEar", _pillow(_ear_triangle(Vector2(0.41, 1.95), 0.42, 0.44, -0.18), -0.26, 0.04, skin))
	_put("Head/LeftEar/Inner", _pillow(_ear_triangle(Vector2(-0.425, 2.03), 0.22, 0.27, 0.18), -0.305, -0.26, inner))
	_put("Head/RightEar/Inner", _pillow(_ear_triangle(Vector2(0.425, 2.03), 0.22, 0.27, -0.18), -0.305, -0.26, inner))

	_put("Head/LeftCheek", _face_oval(-0.42, 1.54, 0.150, 0.140, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.42, 1.54, 0.150, 0.140, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.235, 1.71, 0.042, 0.047, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.235, 1.71, 0.042, 0.047, 0.020, brown))

	# Raised white snout with the nose near its top and a wide smile.
	_put("Head/Muzzle", _face_oval(0.0, 1.60, 0.24, 0.17, 0.075, snout))
	var nose_z := _muzzle_z(0.0, 1.70)
	_put("Head/Muzzle/Nose", _pillow(_ear_ellipse(Vector2(0.0, 1.70), 0.068, 0.046, 0.0), nose_z - 0.005, nose_z + 0.04, brown))
	_put("Head/Muzzle/Mouth", _mouth(brown))

	_put("Arm/Visual", _mitten_arm(-1.0, 1.22, 0.95, skin))
	_put("Arm_2/Visual", _mitten_arm(1.0, 1.22, 0.95, skin))
	_put("Foot/Visual", _paw(-1.0, 0.28, -0.14, 0.24, 0.21, 0.21, skin))
	_put("Foot_2/Visual", _paw(1.0, 0.28, -0.14, 0.24, 0.21, 0.21, skin))
	_put("Foot/Claws", _claw_lines(-0.28, -0.355, [0.0], claw))
	_put("Foot_2/Claws", _claw_lines(0.28, -0.355, [0.0], claw))

	# Samoyed cloud tail rises up the center of the back.
	_put("Tail", _blobs([
		[Vector3(0.0, 0.62, 0.70), Vector3(0.20, 0.20, 0.20)],
		[Vector3(0.10, 0.72, 0.80), Vector3(0.17, 0.17, 0.17)],
		[Vector3(0.04, 0.80, 0.82), Vector3(0.22, 0.22, 0.22)],
		[Vector3(-0.10, 0.88, 0.88), Vector3(0.16, 0.16, 0.16)],
		[Vector3(-0.04, 0.97, 0.84), Vector3(0.21, 0.21, 0.21)],
		[Vector3(0.02, 1.12, 0.77), Vector3(0.18, 0.18, 0.18)],
		[Vector3(0.0, 1.24, 0.67), Vector3(0.14, 0.14, 0.14)]
	], skin))

# Fur covers everything above the ruff edge except the face. The edge hangs in
# big rounded scallops around the chest, like the layered ruff in the art. Facing
# forward the coat lies flatter, so the fluff shows mostly along the head outline.
func _coat_mask(point: Vector3, theta: float) -> float:
	var hang := pow(absf(cos(theta * 6.0)), 0.6)
	var edge := 1.14 - 0.10 * hang
	var amount := smoothstep(edge - 0.012, edge + 0.012, point.y)
	if point.z < 0.0:
		var face := Vector2((point.x - FACE_CENTER.x) / FACE_RADII.x, (point.y - FACE_CENTER.y) / FACE_RADII.y).length()
		amount *= smoothstep(0.90, 1.04, face)
		var facing := -point.z / _section(point.y).y
		var ruff_band := 1.0 - smoothstep(edge + 0.05, edge + 0.14, point.y)
		amount *= lerpf(1.0, maxf(0.3, ruff_band), smoothstep(0.35, 0.85, facing))
	return amount

func _muzzle_z(xx: float, yy: float) -> float:
	return _oval_z(xx, yy, 0.0, 1.60, 0.24, 0.17, 0.075)

func _on_muzzle(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _muzzle_z(xx, yy) - 0.006)

func _mouth(material: Material) -> ArrayMesh:
	var left := _tube([_on_muzzle(0.0, 1.655), _on_muzzle(0.0, 1.622), _on_muzzle(-0.060, 1.594), _on_muzzle(-0.118, 1.602), _on_muzzle(-0.148, 1.622)], [0.011, 0.011, 0.011, 0.011, 0.010], material)
	var right := _tube([_on_muzzle(0.0, 1.622), _on_muzzle(0.060, 1.594), _on_muzzle(0.118, 1.602), _on_muzzle(0.148, 1.622)], [0.011, 0.011, 0.011, 0.010], material)
	return _merge([left, right], material)
