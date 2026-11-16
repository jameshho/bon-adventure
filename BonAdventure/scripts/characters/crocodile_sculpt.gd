@tool
extends "res://scripts/characters/plush_sculpt.gd"

# Plush crocodile, sized to stand beside BonBon. Faces local -Z.
# Green round body with a cream lower jaw that wraps to the cheeks and a grooved
# cream belly plate. A raised snout pad carries the nostrils, with four rounded teeth
# hanging from its lower edge. Rounded ridge plates run over the head and down the
# back, and a thick tapering tail curls up behind the center of the back.

@export var green_color: Color = Color("a7c189")
@export var belly_color: Color = Color("f4e8c8")
@export var dark_green_color: Color = Color("748f5b")
@export var tooth_color: Color = Color("fffdf5")
@export var groove_color: Color = Color("dfcfa6")
@export var cheek_color: Color = Color("f8a39a")
@export var feature_color: Color = Color("3e2216")

const SNOUT_CENTER := Vector2(0.0, 1.64)
const SNOUT_RADII := Vector2(0.37, 0.125)
const SNOUT_FRONT := -0.62
const BELLY_CENTER := Vector2(0.0, 0.80)
const BELLY_RADII := Vector2(0.43, 0.50)

func _build() -> void:
	body_top = 2.12
	# Same proportions as the other plush characters: a soft egg, not a ball.
	_body_profile = [
		Vector3(0.17, 0.006, 0.006), Vector3(0.22, 0.30, 0.26),
		Vector3(0.32, 0.49, 0.42), Vector3(0.45, 0.60, 0.51),
		Vector3(0.62, 0.65, 0.55), Vector3(0.80, 0.66, 0.56),
		Vector3(1.00, 0.645, 0.54), Vector3(1.20, 0.635, 0.53),
		Vector3(1.40, 0.65, 0.54), Vector3(1.60, 0.65, 0.54),
		Vector3(1.78, 0.61, 0.51), Vector3(1.92, 0.52, 0.44),
		Vector3(2.02, 0.39, 0.33), Vector3(2.09, 0.21, 0.18),
		Vector3(body_top, 0.006, 0.006)
	]
	_color_fn = _coat
	soften_coat = false
	var green := _mat(green_color)
	var dark := _soft_mat(dark_green_color, 0.6)
	var teeth := _soft_mat(tooth_color, 0.4)
	var groove := _soft_mat(groove_color, 0.3)
	var blush := _mat(cheek_color, true)
	var brown := _soft_mat(feature_color, 0.5)

	_put("Torso/Visual", _furry_body(_coat_mat(), 0.0, 1.0, 0, Callable(), 0.0, 240, 224))
	_put("Torso/Grooves", _belly_grooves(groove))
	_put("Torso/BackRidge", _back_ridge(green))

	_put("Head/Spikes", _merge([
		_pillow(_ear_triangle(Vector2(0.0, 2.07), 0.24, 0.19, 0.0), -0.10, 0.10, green),
		_pillow(_ear_triangle(Vector2(-0.27, 2.00), 0.19, 0.15, 0.35), -0.10, 0.10, green),
		_pillow(_ear_triangle(Vector2(0.27, 2.00), 0.19, 0.15, -0.35), -0.10, 0.10, green)
	], green))

	_put("Head/LeftCheek", _face_oval(-0.44, 1.66, 0.13, 0.12, 0.006, blush))
	_put("Head/RightCheek", _face_oval(0.44, 1.66, 0.13, 0.12, 0.006, blush))
	_put("Head/LeftEye", _face_oval(-0.24, 1.80, 0.045, 0.050, 0.020, brown))
	_put("Head/RightEye", _face_oval(0.24, 1.80, 0.045, 0.050, 0.020, brown))

	# Raised snout pad: a soft rounded rectangle standing proud of the face.
	_put("Head/Snout", _pillow(_rounded_rect(SNOUT_CENTER.x, SNOUT_CENTER.y, SNOUT_RADII.x, SNOUT_RADII.y), SNOUT_FRONT, -0.32, green))
	_put("Head/Snout/Nostrils", _merge([
		_flat_disc(-0.10, 1.665, SNOUT_FRONT - 0.042, 0.032, 0.026, dark),
		_flat_disc(0.10, 1.665, SNOUT_FRONT - 0.042, 0.032, 0.026, dark)
	], dark))
	_put("Head/Teeth", _teeth(teeth))

	_put("Arm/Visual", _mitten_arm(-1.0, 1.16, 0.95, green))
	_put("Arm_2/Visual", _mitten_arm(1.0, 1.16, 0.95, green))
	for side in [-1.0, 1.0]:
		var foot := "Foot" if side < 0 else "Foot_2"
		_put(foot + "/Visual", _paw(side, 0.28, -0.11, 0.26, 0.18, 0.20, green))
		_put(foot + "/Claws", _claw_lines(side * 0.28, -0.315, [-0.045, 0.045], dark))

	# Thick tail tapers from the lower back and curls up at the tip.
	_put("Tail", _tube([
		Vector3(0.0, 0.42, 0.34), Vector3(0.0, 0.34, 0.60), Vector3(0.0, 0.30, 0.86),
		Vector3(0.0, 0.34, 1.08), Vector3(0.0, 0.46, 1.24), Vector3(0.0, 0.62, 1.30)
	], [0.27, 0.23, 0.17, 0.12, 0.075, 0.03], green))
	_put("Tail/Spikes", _plates([
		[Vector2(0.60, 0.53), 0.17, 0.13, 0.0], [Vector2(0.86, 0.44), 0.15, 0.11, 0.0],
		[Vector2(1.07, 0.44), 0.12, 0.09, -0.15], [Vector2(1.22, 0.53), 0.09, 0.07, -0.5]
	], green))

# Cream lower jaw (tapering round to the cheeks) and belly plate; green elsewhere.
# Soft-edged blends keep the borders clean instead of fuzzy.
func _coat(point: Vector3) -> Color:
	var r := _section(point.y)
	var around := -point.z / r.y
	var fade := pow(clampf(1.0 - around, 0.0, 1.15), 2.0)
	var jaw := _edge(minf(minf(1.55 - 0.10 * fade - point.y, point.y - 1.25 - 0.14 * fade), (around + 0.15) * r.y))
	var oval := Vector2((point.x - BELLY_CENTER.x) / BELLY_RADII.x, (point.y - BELLY_CENTER.y) / BELLY_RADII.y).length()
	var belly := _edge(minf((1.0 - oval) * 0.45, -point.z))
	return green_color.lerp(belly_color, maxf(jaw, belly))

# Four rounded teeth hang from the snout's lower lip, in front of the cream jaw.
func _teeth(material: Material) -> ArrayMesh:
	var parts: Array = []
	var lip := SNOUT_CENTER.y - SNOUT_RADII.y
	for xx in [-0.33, -0.25, 0.25, 0.33]:
		var zz := _front_z(xx, lip) - 0.05
		parts.append(_tube([Vector3(xx, lip + 0.02, zz), Vector3(xx, lip - 0.012, zz), Vector3(xx, lip - 0.045, zz)], [0.030, 0.024, 0.007], material))
	return _merge(parts, material)

# Chin crease and four horizontal grooves across the belly plate.
func _belly_grooves(material: Material) -> ArrayMesh:
	var parts: Array = []
	var chin: Array = []
	for i in range(13):
		var xx := lerpf(-0.39, 0.39, float(i) / 12.0)
		var t := absf(xx) / 0.72
		var yy := 1.25 + 0.12 * t * t
		chin.append(Vector3(xx, yy, _front_z(xx, yy) - 0.004))
	parts.append(_tube(chin, _repeat(0.010, chin.size()), material))
	for yy in [1.06, 0.86, 0.66, 0.47]:
		var half := BELLY_RADII.x * sqrt(maxf(0.0, 1.0 - pow((yy - BELLY_CENTER.y) / BELLY_RADII.y, 2.0))) * 0.88
		var line: Array = []
		for i in range(11):
			var xx := lerpf(-half, half, float(i) / 10.0)
			line.append(Vector3(xx, yy, _front_z(xx, yy) - 0.004))
		parts.append(_tube(line, _repeat(0.009, line.size()), material))
	return _merge(parts, material)

# Rounded ridge plates down the center of the back, pointing outward.
func _back_ridge(material: Material) -> ArrayMesh:
	var plates: Array = []
	for row in [[1.86, 0.13, 0.09], [1.62, 0.15, 0.10], [1.38, 0.15, 0.10], [1.14, 0.13, 0.09]]:
		var yy: float = row[0]
		plates.append([Vector2(_section(yy).y - 0.03, yy), row[1], row[2], -PI * 0.5])
	return _plates(plates, material)

# Rounded triangle plates on the center line, each given as
# [base (depth, height), width, height, tilt] in the side view.
func _plates(specs: Array, material: Material) -> ArrayMesh:
	var parts: Array = []
	for spec in specs:
		var outline := _ear_triangle(spec[0], spec[1], spec[2], spec[3])
		parts.append(_moved(_pillow(outline, -0.045, 0.045, material), SIDEWAYS))
	return _merge(parts, material)

func _repeat(value: float, count: int) -> Array:
	var result: Array = []
	result.resize(count)
	result.fill(value)
	return result
