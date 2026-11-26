extends SceneTree
## 25 Nov 2026 BonBon gait (ANIM-03, D13): renders a strip of BonBon walking (walk_speed), sprinting
## (sprint_speed) and pushing the stick a little (SLOW m/s), one row each, COLUMNS frames FRAME_GAP
## seconds apart from the side, driving player_controller.gd animate_bonbon() directly at 60 Hz.
## Every row starts at the same gait phase, so a before/after pair shows only the cadence.
## A small stage (ground, sun, sky) with only the player scene, so it does not depend on the town.
## HOME=<scratch> godot --path . --resolution 1280x800 --script res://docs/evidence/characters-20261125/gait_strip.gd -- <name>
## Writes gait-<name>.png here (graphics only); reads no saves.
const OUT := "res://docs/evidence/characters-20261125"
const COLUMNS := 8
const FRAME_GAP := 1.0 / 12.0
const SLOW := 2.4
const CROP := Vector2i(300, 460)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var label := "strip"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		label = args[0]
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("bfe3f2")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	stage.add_child(sun)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(200, 1, 200)
	shape.position.y = -0.5
	ground.add_child(shape)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(200, 200)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = _checker()
	floor_material.uv1_scale = Vector3(100, 100, 1)
	floor_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	floor_mesh.material_override = floor_material
	ground.add_child(floor_mesh)
	stage.add_child(ground)
	var player = load("res://scenes/player/bonbon_player.tscn").instantiate()
	stage.add_child(player)
	player.global_position = Vector3(0, 0.2, 0)
	for i in 30: await physics_frame
	player.set_physics_process(false)
	player.camera.current = false
	var cam := Camera3D.new()
	cam.fov = 38
	root.add_child(cam)
	cam.current = true
	var rows: Array[Image] = []
	for speed: float in [player.walk_speed, player.sprint_speed, SLOW]:
		var start: Vector3 = player.global_position
		player.rotation.y = 0.0
		# Settle the gait weight at this speed, then start every row from phase 0.
		for i in 90:
			player.animate_bonbon(1.0 / 60.0, speed)
		player.gait_phase = 0.0
		var row := Image.create(CROP.x * COLUMNS, CROP.y, false, Image.FORMAT_RGBA8)
		var step := 0
		for column in COLUMNS:
			var steps := int(round(FRAME_GAP * 60.0)) if column > 0 else 0
			for i in steps:
				player.global_position += Vector3(0, 0, -speed / 60.0)
				player.animate_bonbon(1.0 / 60.0, speed)
				step += 1
			player.reset_physics_interpolation()
			cam.global_position = player.global_position + Vector3(11.0, 2.2, 0)
			cam.look_at(player.global_position + Vector3(0, 1.7, 0), Vector3.UP)
			for i in 2: await process_frame
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			shot.convert(Image.FORMAT_RGBA8)
			var size := shot.get_size()
			row.blit_rect(shot, Rect2i((size - CROP) / 2, CROP), Vector2i(column * CROP.x, 0))
		print("ROW speed %.1f m/s: phase advanced %.2f rad over %.2f s" % [speed, player.gait_phase, step / 60.0])
		rows.append(row)
		player.global_position = start
	var strip := Image.create(CROP.x * COLUMNS, CROP.y * rows.size(), false, Image.FORMAT_RGBA8)
	for i in rows.size():
		strip.blit_rect(rows[i], Rect2i(Vector2i.ZERO, rows[i].get_size()), Vector2i(0, i * CROP.y))
	strip.save_png("%s/gait-%s.png" % [OUT, label])
	print("CAPTURE gait-", label)
	stage.queue_free()
	await process_frame
	quit()

## A checkerboard of 1 m squares, so the ground shows how far BonBon moved between frames.
func _checker() -> ImageTexture:
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, Color("8fbf6a"))
	image.set_pixel(1, 1, Color("8fbf6a"))
	image.set_pixel(1, 0, Color("a9d384"))
	image.set_pixel(0, 1, Color("a9d384"))
	var texture := ImageTexture.create_from_image(image)
	return texture
