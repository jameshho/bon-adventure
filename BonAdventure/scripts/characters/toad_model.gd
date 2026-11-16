extends RefCounted
## A small cartoon toad built from primitives (Mystery Doors, 9 Nov 2026): the wrong door turns
## the player into one for two seconds (scripts/learning/mystery_session.gd). Its own materials;
## no physics. Facing -Z like the player's model, feet at y 0.
##   var toad := ToadModel.build(0.7)   # about 0.7 m tall
const SKIN := Color("5fae4a")
const BELLY := Color("d8e8a0")
const SPOTS := Color("3f7d33")
const EYE := Color("fbfaf4")
const PUPIL := Color("1b1f1b")
const CHEEK := Color("f29aa8")

static func build(height: float) -> Node3D:
	var toad := Node3D.new()
	toad.name = "Toad"
	var s := height / 0.7
	var skin := _material(SKIN)
	# Body: a squat ball, belly in front, two dark spots on the back.
	_ball(toad, "Body", Vector3(0, 0.3, 0.02) * s, Vector3(0.5, 0.36, 0.46) * s, skin)
	_ball(toad, "Belly", Vector3(0, 0.26, -0.13) * s, Vector3(0.38, 0.28, 0.3) * s, _material(BELLY))
	for spot in [Vector3(0.14, 0.55, 0.12), Vector3(-0.1, 0.58, 0.2), Vector3(0.02, 0.5, 0.33)]:
		_ball(toad, "Spot", spot * s, Vector3(0.08, 0.03, 0.08) * s, _material(SPOTS))
	# Eyes on top, looking forward; rosy cheeks.
	for side in [-1.0, 1.0]:
		_ball(toad, "Eye", Vector3(side * 0.15, 0.6, -0.12) * s, Vector3(0.12, 0.12, 0.12) * s, skin)
		_ball(toad, "Eye white", Vector3(side * 0.15, 0.63, -0.19) * s, Vector3(0.085, 0.085, 0.06) * s, _material(EYE))
		_ball(toad, "Pupil", Vector3(side * 0.15, 0.63, -0.235) * s, Vector3(0.045, 0.05, 0.03) * s, _material(PUPIL))
		_ball(toad, "Cheek", Vector3(side * 0.2, 0.36, -0.3) * s, Vector3(0.055, 0.035, 0.03) * s, _material(CHEEK))
		# Legs: folded back legs at the sides, small front feet.
		_ball(toad, "Back leg", Vector3(side * 0.27, 0.13, 0.14) * s, Vector3(0.14, 0.12, 0.22) * s, skin)
		_ball(toad, "Back foot", Vector3(side * 0.3, 0.03, -0.04) * s, Vector3(0.1, 0.03, 0.12) * s, skin)
		_ball(toad, "Front foot", Vector3(side * 0.17, 0.03, -0.28) * s, Vector3(0.08, 0.03, 0.08) * s, skin)
	# A wide, thin smile.
	_ball(toad, "Mouth", Vector3(0, 0.37, -0.315) * s, Vector3(0.16, 0.012, 0.02) * s, _material(PUPIL))
	return toad

static func _ball(parent: Node3D, title: String, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.mesh = sphere
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if radii.length() < 0.1 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mesh)
	mesh.transform = Transform3D(Basis.from_scale(radii), at)
	return mesh

static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material
