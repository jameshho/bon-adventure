extends SceneTree
## Turnaround of scenes/animals/lion_clay.scn on a cream stage, laid out like the user's
## blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png; with `zoo`, also two
## views of its saved place in the town (zoo-close.png, zoo-location.png).
## Run with an isolated HOME (README) and VT_FOCUS=all VT_SPAWN=none:
##   godot --path . --resolution 1400x520 --script res://docs/evidence/lion-clay-20261110/capture.gd [-- zoo]
const OUT := "res://docs/evidence/lion-clay-20261110/"
const W := 700
const H := 520

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	var zoo := OS.get_cmdline_user_args().has("zoo")
	root.size = Vector2i(W, H)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("fbf3e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.55
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -150, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(60, 60)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fbf3e9")
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	var lion: Node3D = load("res://scenes/animals/lion_clay.scn").instantiate()
	stage.add_child(lion)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.75
	stage.add_child(cam)
	cam.current = true
	var target := Vector3(0, 0.98, 0.05)
	var strip := Image.create(W * 5, H, false, Image.FORMAT_RGBA8)
	var views := [["front-three-quarter", Vector3(-0.72, 0.12, -0.69)], ["front", Vector3(0, 0.1, -1)],
		["side", Vector3(-1, 0.08, 0)], ["back", Vector3(0, 0.12, 1)], ["rear-three-quarter", Vector3(0.7, 0.14, 0.7)]]
	for i in views.size():
		cam.position = target + (views[i][1] as Vector3).normalized() * 12.0
		cam.look_at(target)
		var img: Image = await shot()
		img.convert(Image.FORMAT_RGBA8)
		strip.blit_rect(img, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(OUT + "turnaround.png")
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
	var placed: Node3D = game.apartment.get_node("ParkZoo/LionClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 1.0, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	var other: Node3D = game.apartment.get_node_or_null("ParkZoo/LionBlueprintDisplay")
	var pair := aim if other == null else (aim + other.global_position + Vector3(0, 1.0, 0)) * 0.5
	# Close-up from inside the fence (the gate sign stands in front); both displays from the gate.
	for view in [["zoo-close", aim, facing * 5.6 - across * 3.4 + Vector3(0, 1.3, 0)],
			["zoo-pair", pair, facing * 15.0 + Vector3(0, 7.0, 0)],
			["zoo-location", aim, facing * 14.0 - across * 8.0 + Vector3(0, 9.0, 0)]]:
		town_cam.global_position = view[1] + view[2]
		town_cam.look_at(view[1])
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(2.6, 3, 0), placed.global_position + Vector3(2.6, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()
	quit()
