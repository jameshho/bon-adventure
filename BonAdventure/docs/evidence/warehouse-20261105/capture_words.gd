extends SceneTree
## Warehouse Phase 2 views (5 Nov 2026): the word objects (boxes, trolley, package, Ramón
## the boss, Paty the employee) and the three reception posters, in Spanish (the default). Uses Main, which saves progress: run with an
## isolated HOME (README). Camera points are in the warehouse's own frame (town units, +X
## west, entrance on local z = 0 facing the road).
## godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/capture_words.gd
func _initialize(): run.call_deferred()
func shot(camera: Camera3D, from: Vector3, at: Vector3, file: String, fov := 60.0) -> void:
	camera.fov = fov
	camera.global_position = from
	camera.look_at(at)
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(file)
func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var folder := "res://docs/evidence/warehouse-20261105"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	game.hud.hide()
	var camera := Camera3D.new()
	game.add_child(camera); camera.current = true
	camera.far = 900.0
	var wh: Node3D = game.apartment.get_node("Warehouse")
	var at := func(x: float, y: float, z: float) -> Vector3: return wh.to_global(Vector3(x, y, z))
	game.player.global_position = at.call(0, -30, 0)
	await shot(camera, at.call(-3.2, 1.9, -6.0), at.call(-3.6, 1.2, -1.4), folder + "/words-ramon.png")
	await shot(camera, at.call(-6.0, 2.4, -.5), at.call(-10.5, .5, 4.2), folder + "/words-trolley.png")
	await shot(camera, at.call(7.0, 1.9, 3.2), at.call(8.4, .6, 6.1), folder + "/words-boxes.png")
	await shot(camera, at.call(1.2, 2.1, .9), at.call(3.2, 1.3, 2.4), folder + "/words-desk.png")
	await shot(camera, at.call(-1.6, 2.7, 3.5), at.call(-5.6, 2.7, 3.5), folder + "/poster-verbs.png", 75.0)
	await shot(camera, at.call(-3.4, 2.7, 3.9), at.call(-3.4, 2.7, 6.9), folder + "/poster-positions.png", 60.0)
	await shot(camera, at.call(3.4, 2.7, 3.9), at.call(3.4, 2.7, 6.9), folder + "/poster-describe.png", 60.0)
	print("WAREHOUSE WORD CAPTURE done")
	quit()
