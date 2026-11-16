extends SceneTree
## Turnaround of scenes/animals/elephant_clay.tscn on a cream stage, laid out like the user's
## blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png, plus face close-ups
## (face.png); with `zoo`, also two views of its saved place in the town (zoo-close.png,
## zoo-location.png). Run with an isolated HOME (README) and VT_FOCUS=all VT_SPAWN=none:
##   godot --path . --resolution 640x560 --script res://docs/evidence/elephant-clay-20261111/capture.gd [-- zoo]
const OUT := "res://docs/evidence/elephant-clay-20261111/"
const W := 640
const H := 560

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
		img.resize(W, H, Image.INTERPOLATE_LANCZOS)
		strip.blit_rect(img, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(OUT + file)

func run() -> void:
	var zoo := OS.get_cmdline_user_args().has("zoo")
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("fbf3e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.45
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -150, 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(60, 60)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fbf3e9")
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	var elephant: Node3D = load("res://scenes/animals/elephant_clay.tscn").instantiate()
	stage.add_child(elephant)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.9
	stage.add_child(cam)
	cam.current = true
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0, 0.12, 1), Vector3(0.7, 0.14, 0.7)]
	await strip_of(cam, Vector3(0, 1.62, 0.05), views, "turnaround.png")
	cam.size = 1.55
	await strip_of(cam, Vector3(0, 2.2, -1.15), [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)], "face.png")
	cam.size = 0.55
	await strip_of(cam, Vector3(0, 2.36, -1.3), [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)], "eyes.png")
	print("TURNAROUND saved")
	stage.free()
	if not zoo:
		quit()
		return
	root.size = Vector2i(1200, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var placed: Node3D = game.apartment.get_node("ParkZoo/ElephantClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 1.7, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-close", aim, facing * 8.5 - across * 6.0 + Vector3(0, 0.3, 0)],
			["zoo-location", aim, facing * 20.0 - across * 12.0 + Vector3(0, 12.0, 0)]]:
		town_cam.global_position = view[1] + view[2]
		town_cam.look_at(view[1])
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(2.6, 3, 0), placed.global_position + Vector3(2.6, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()
	quit()
