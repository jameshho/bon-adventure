@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Plush beagle, sized to stand beside BonBon. Faces local -Z.
# Tan coat with a white forehead blaze, muzzle, chin, chest and paws, dark saddle
# patches on the shoulders, long floppy brown ears and a white-tipped tail.

@export var tan_color: Color = Color("e1a569")
@export var white_color: Color = Color("fbf1e2")
@export var saddle_color: Color = Color("8c5634")
@export var ear_color: Color = Color("bd7e4f")
@export var muzzle_color: Color = Color("fffaf2")
@export var cheek_color: Color = Color("f8a6a0")
@export var feature_color: Color = Color("4a2a1c")
@export var claw_color: Color = Color("8c5634")

func _build() -> void:
	body_top = 2.23
	# A wide round head on a slim neck, over a pear-shaped body.
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.28, 0.26),
		Vector3(0.32, 0.47, 0.42), Vector3(0.45, 0.58, 0.52),
		Vector3(0.62, 0.63, 0.56), Vector3(0.80, 0.63, 0.56),
		Vector3(1.00, 0.60, 0.53), Vector3(1.15, 0.55, 0.49),
		Vector3(1.25, 0.52, 0.47), Vector3(1.35, 0.54, 0.48),
		Vector3(1.50, 0.56, 0.49), Vector3(1.70, 0.55, 0.48),
		Vector3(1.88, 0.51, 0.45), Vector3(2.02, 0.43, 0.38),
		Vector3(2.13, 0.30, 0.27), Vector3(2.20, 0.14, 0.13),
		Vector3(body_top, 0.006, 0.006)
	]
	_color_fn = _coat
	soften_coat = false
	var ears := _mat(ear_color)
	var blush := _mat(cheek_color, true)
	var snout := _soft_mat(muzzle_color, 0.6)
	var brown := _soft_mat(feature_color, 0.5)
	var claw := _soft_mat(claw_color, 0.3)
	var white := _mat(white_color)

	# Dense mesh so the blaze and patch edges stay crisp.
	_put("Torso/Visual", _furry_body(_coat_mat(), 0.0, 1.0, 0, Callable(), 0.0, 240, 256))

	# Long floppy ears hang from the top of the head down past the cheeks.
	var ear := _smooth_outline(PackedVector2Array([
		Vector2(-0.30, 2.14), Vector2(-0.60, 2.12), Vector2(-0.80, 1.95), Vector2(-0.88, 1.62),
		Vector2(-0.84, 1.36), Vector2(-0.70, 1.27), Vector2(-0.57, 1.36), Vector2(-0.51, 1.62),
		Vector2(-0.46, 1.92)
	]), 3)
	_put("Head/LeftEar", _pillow(ear, -0.14, 0.20, ears))
	_put("Head/RightEar", _pillow(_mirror(ear), -0.14, 0.20, ears))

	_put("Head/LeftCheek", _face_oval(-0.36, 1.59, 0.115, 0.108, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.36, 1.59, 0.115, 0.108, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.215, 1.78, 0.040, 0.045, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.215, 1.78, 0.040, 0.045, 0.020, brown))

	# Big round white muzzle with the nose on top and a smile below it.
	_put("Head/Muzzle", _face_oval(0.0, 1.50, 0.225, 0.20, 0.10, snout))
	var nose_z := _muzzle_z(0.0, 1.665)
	_put("Head/Muzzle/Nose", _pillow(_ear_ellipse(Vector2(0.0, 1.665), 0.08, 0.052, 0.0), nose_z - 0.005, nose_z + 0.04, brown))
	_put("Head/Muzzle/Mouth", _mouth(brown))

	# Tan arms with white mitten paws.
	for side in [-1.0, 1.0]:
		var arm := "Arm/Visual" if side < 0 else "Arm_2/Visual"
		var foot := "Foot" if side < 0 else "Foot_2"
		_put(arm, _mitten_arm(side, 1.16, 0.85, _point_mat(tan_color, white_color, _mitten_tip(side, 1.16, 0.85), 0.10, 0.13)))
		_put(foot + "/Visual", _paw(side, 0.25, -0.10, 0.26, 0.16, 0.18, white))
		_put(foot + "/Claws", _claw_lines(side * 0.25, -0.285, [0.0], claw))

	# Tail rises from the center of the lower back, tan with a white tip.
	_put("Tail", _tube([
		Vector3(0.0, 0.45, 0.46), Vector3(0.0, 0.42, 0.64), Vector3(0.0, 0.55, 0.78),
		Vector3(0.0, 0.75, 0.84), Vector3(0.0, 0.95, 0.80), Vector3(0.0, 1.08, 0.72)
	], [0.080, 0.085, 0.080, 0.075, 0.070, 0.060], _point_mat(tan_color, white_color, Vector3(0.0, 1.03, 0.75), 0.10, 0.13)))

# Beagle markings, by position on the body. Each mark is a soft-edged blend
# (`_edge`), so outlines stay smooth without blurring the whole coat.
func _coat(point: Vector3) -> Color:
	var r := _section(point.y)
	var around := point.z / r.y
	# Dark saddle over the shoulders and back only, so nothing reads as straps from the front.
	var saddle := _edge(minf(minf(point.y - 1.02, 1.30 - point.y), (around - 0.15) * r.y))
	var color := tan_color.lerp(saddle_color, saddle)
	# White blaze up the middle of the forehead, widening toward the muzzle.
	var half := lerpf(0.075, 0.045, clampf((point.y - 1.70) / 0.50, 0.0, 1.0))
	var blaze := _edge(minf(minf(half - absf(point.x), point.y - 1.55), 0.25 - point.z), 0.01)
	# White chin and lower face around the muzzle.
	var chin := _edge(minf((1.0 - Vector2(point.x / 0.34, (point.y - 1.42) / 0.20).length()) * 0.2, -point.z))
	# White chest and belly.
	var chest_half := lerpf(0.40, 0.28, smoothstep(0.95, 1.27, point.y))
	var chest := _edge(minf(minf(chest_half - absf(point.x), 1.27 - point.y), -point.z))
	var white := maxf(maxf(blaze, chin), maxf(chest, _edge(0.24 - point.y)))
	return color.lerp(white_color, white)

func _muzzle_z(xx: float, yy: float) -> float:
	return _oval_z(xx, yy, 0.0, 1.50, 0.225, 0.20, 0.10)

func _on_muzzle(xx: float, yy: float) -> Vector3:
	return Vector3(xx, yy, _muzzle_z(xx, yy) - 0.006)

func _mouth(material: Material) -> ArrayMesh:
	var left := _tube([_on_muzzle(0.0, 1.615), _on_muzzle(0.0, 1.572), _on_muzzle(-0.055, 1.540), _on_muzzle(-0.110, 1.550), _on_muzzle(-0.135, 1.572)], [0.011, 0.011, 0.011, 0.011, 0.010], material)
	var right := _tube([_on_muzzle(0.0, 1.572), _on_muzzle(0.055, 1.540), _on_muzzle(0.110, 1.550), _on_muzzle(0.135, 1.572)], [0.011, 0.011, 0.011, 0.010], material)
	return _merge([left, right], material)
