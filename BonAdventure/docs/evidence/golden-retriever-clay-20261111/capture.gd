extends SceneTree
## Turnaround of scenes/animals/golden_retriever_clay.tscn on a cream stage, laid out like the
## user's blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png, plus face
## close-ups (face.png) and eye close-ups (eyes.png). Loads only the prefab, not the town:
##   godot --path . --resolution 1200x800 --script res://docs/evidence/golden-retriever-clay-20261111/capture.gd
const OUT := "res://docs/evidence/golden-retriever-clay-20261111/"
const W := 640
const H := 600

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func strip_of(cam: Camera3D, target: Vector3, views: Array, file: String) -> void:
	var strip := Image.create(W * views.size(), H, false, Image.FORMAT_RGBA8)
	for i in views.size():
		cam.position = target + (views[i] as Vector3).normalized() * 14.0
		cam.look_at(target)
		var img: Image = await shot()
		img.convert(Image.FORMAT_RGBA8)
		strip.blit_rect(img, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(OUT + file)

func run() -> void:
	root.size = Vector2i(W, H)
	root.always_on_top = true      # a covered window is not drawn on macOS, and the capture stalls
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("fbf3e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -150, 0)
	sun.light_energy = 0.3
	sun.shadow_enabled = true
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()   # from behind, so the back views are as readable as the front
	fill.rotation_degrees = Vector3(-35, 30, 0)
	fill.light_energy = 0.2
	stage.add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(60, 60)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fbf3e9")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	var dog: Node3D = load("res://scenes/animals/golden_retriever_clay.tscn").instantiate()
	stage.add_child(dog)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.96
	stage.add_child(cam)
	cam.current = true
	for i in range(20): await process_frame
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0, 0.12, 1), Vector3(0.7, 0.14, 0.7)]
	await strip_of(cam, Vector3(0, 0.41, 0.07), views, "turnaround.png")
	var close := [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)]
	cam.size = 0.42
	await strip_of(cam, Vector3(0, 0.66, -0.3), close, "face.png")
	cam.size = 0.2
	await strip_of(cam, Vector3(0, 0.68, -0.32), close, "eyes.png")
	# Each view centred on the dog's left eye, and the left ear from the front and the side.
	cam.size = 0.09
	await strip_of(cam, Vector3(-0.065, 0.69, -0.31), close, "eye-close.png")
	cam.size = 0.34
	await strip_of(cam, Vector3(-0.15, 0.64, -0.16), [Vector3(0, 0.0, -1), Vector3(-0.72, 0.0, -0.69), Vector3(-1, 0.0, 0), Vector3(-0.7, 0.0, 0.7), Vector3(0, 0.0, 1)], "ear.png")
	print("TURNAROUND saved")
	quit()
