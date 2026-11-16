extends SceneTree
## Warehouse Phase 1 views (5 Nov 2026): the building between the moved school and the
## airport, its reception and the empty hall. Uses Main, which saves progress: run with an
## isolated HOME (README). Camera points are in the warehouse's own frame (town units, +X
## west, entrance on local z = 0 facing the road).
## godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/capture.gd
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
	await shot(camera, at.call(-4, 4.5, -30), at.call(0, 4.5, 8), folder + "/front.png")
	await shot(camera, at.call(-24, 9, -26), at.call(0, 3, 10), folder + "/front-east.png")
	await shot(camera, at.call(22, 8, -24), at.call(0, 3, 10), folder + "/front-west.png")
	await shot(camera, at.call(-20, 12, 50), at.call(0, 3, 14), folder + "/rear.png")
	# North street from above: hospital, moved school, warehouse, airport.
	await shot(camera, at.call(30, 95, -45), at.call(30, 0, 12), folder + "/street-aerial.png", 55.0)
	await shot(camera, at.call(30, 150, 14), at.call(30, 0, 14.01), folder + "/street-top.png", 60.0)
	# Reception with BonBon for scale.
	game.player.global_position = at.call(-.6, .2, 3.2)
	game.player.rotation.y = wh.global_rotation.y + PI / 2
	await shot(camera, at.call(-4.6, 2.2, .9), at.call(3.5, 1.2, 4.2), folder + "/reception-desk.png")
	await shot(camera, at.call(3.0, 2.0, 1.0), at.call(-2.5, 1.3, 6.8), folder + "/reception-door.png")
	var door: Node3D = wh.get_node("Architecture/Warehouse hall door")
	door.rotation.y = 1.75
	game.player.global_position = at.call(0, .2, 9.0)
	game.player.rotation.y = wh.global_rotation.y
	await shot(camera, at.call(0, 2.4, 4.6), at.call(0, 2.2, 20), folder + "/hall-from-door.png")
	await shot(camera, at.call(13.5, 6.5, 8.5), at.call(-6, 2.5, 22), folder + "/hall-wide.png")
	await shot(camera, at.call(-12, 3.0, 27), at.call(4, 2.5, 9), folder + "/hall-to-front.png")
	print("WAREHOUSE CAPTURE done")
	quit()
