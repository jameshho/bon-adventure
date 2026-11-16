extends SceneTree
## Model sheet of the evidence objects and the result badges (8 Nov 2026, second pass), without
## the town: models.png (every kind and colour variant) and badges.png (the six pins).
## Run from BonAdventure/ (needs a window, not --headless):
##   godot --path . --resolution 1280x800 --script docs/evidence/police-evidence-20261108/models.gd
const EvidenceProps := preload("res://scripts/learning/evidence_props.gd")
const OUT := "res://docs/evidence/police-evidence-20261108/"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("e9e4da")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c9d3e0")
	env.environment.ambient_light_energy = .9
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	stage.add_child(sun)
	var table := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(8.5, .02, 5)
	table.mesh = plane
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("24477f")
	table.material_override = cloth
	table.position = Vector3(-3.24, -.01, 1.2)
	stage.add_child(table)
	var data := EvidenceProps.load_data()
	var objects: Dictionary = data.evidence.objects
	# One column per kind (left to right as in the data), its colour variants behind it.
	var column := 0
	for kind in objects:
		var colours: Array = objects[kind].get("color", [""])
		for v in colours.size():
			var node := EvidenceProps.build(str(kind), {"kind": kind, "color": colours[v]})
			node.position = Vector3(-column * .72, 0, v * .72)
			stage.add_child(node)
		column += 1
	var cam := Camera3D.new()
	cam.fov = 50
	stage.add_child(cam)
	cam.look_at_from_position(Vector3(-3.24, 4.6, -2.6), Vector3(-3.24, 0, 1.25))
	await _frames(8)
	root.get_texture().get_image().save_png(OUT + "models.png")
	# Close look at the first variant of every kind, low like the game camera.
	cam.look_at_from_position(Vector3(-3.24, 1.5, -2.1), Vector3(-3.24, .05, .2))
	await _frames(4)
	root.get_texture().get_image().save_png(OUT + "models-close.png")
	stage.free()
	var sheet := Image.create(6 * 140, 170, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a6aa8"))
	var k := 0
	for value in ["hard", "soft", "rough", "smooth", "heavy", "light"]:
		var image := Image.new()
		image.load_svg_from_string(EvidenceProps.badge_svg(value), 128 / 24.0)
		image.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(6 + k * 140, 10))
		k += 1
	sheet.save_png(OUT + "badges.png")
	quit()

func _frames(n: int) -> void:
	for i in n:
		await process_frame
