extends SceneTree
## Lot entrance strips (2 Nov 2026): top-down orthographic views of every parking lot, 1200x800,
## graphics required. SHOT_TAG (before or after) prefixes the file names.
## SHOT_TAG=after godot --path . --resolution 1200x800 --script res://docs/evidence/lot-strips-20261102/capture.gd
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var folder := ProjectSettings.globalize_path("res://docs/evidence/lot-strips-20261102/")
	var tag: String = OS.get_environment("SHOT_TAG")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 900.0
	# [name, world x/z centre, orthographic height in world units]
	for spec in [
		["restaurants", Vector2(-80, 60), 90.0],
		["east_upper", Vector2(150, 130), 100.0],
		["east_lower", Vector2(150, 215), 100.0],
		["west_upper", Vector2(-165, 125), 100.0],
		["west_lower", Vector2(-160, 205), 100.0],
		["hospital_school", Vector2(37, 272), 80.0],
		["furniture_sports", Vector2(135, 282), 60.0],
		["airport", Vector2(-100, 285), 60.0],
		["library", Vector2(40, 66), 60.0],
	]:
		camera.size = spec[2]
		camera.global_position = Vector3(spec[1].x, 120.0, spec[1].y)
		camera.look_at(Vector3(spec[1].x, 0.0, spec[1].y), Vector3(0, 0, -1))
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + tag + "-" + spec[0] + ".png")
	print("LOT STRIPS CAPTURE done")
	quit()
