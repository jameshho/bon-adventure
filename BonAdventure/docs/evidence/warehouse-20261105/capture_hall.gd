extends SceneTree
## Warehouse Phase 3 views (5 Nov 2026): the hall equipment and light town stock (racks
## A–C, tables, scale, cabinet, conveyor, IN / OUT areas, trolley lanes) and the truck. Uses Main, which saves progress: run with an
## isolated HOME (README). Camera points are in the warehouse's own frame (town units, +X
## west, entrance on local z = 0 facing the road).
## godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/capture_hall.gd
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
	var door: Node3D = wh.get_node("Architecture/Warehouse hall door")
	door.rotation.y = 1.75
	game.player.global_position = at.call(0, -30, 0)
	await shot(camera, at.call(0, 2.4, 4.6), at.call(0, 2.0, 20), folder + "/hall3-from-door.png")
	await shot(camera, at.call(13.5, 6.5, 8.5), at.call(-4, 1.0, 22), folder + "/hall3-wide.png")
	await shot(camera, at.call(-12, 4.5, 24), at.call(2, .8, 12), folder + "/hall3-to-front.png")
	await shot(camera, at.call(6.2, 2.0, 21.5), at.call(6.2, 1.1, 27.3), folder + "/hall3-racks.png", 70.0)
	await shot(camera, at.call(-3.5, 2.0, 22.5), at.call(-6, 1.0, 27.3), folder + "/hall3-rack-c.png", 65.0)
	await shot(camera, at.call(8.0, 2.2, 8.6), at.call(8.5, .8, 13.5), folder + "/hall3-stations.png", 70.0)
	await shot(camera, at.call(-7, 5.5, 17.5), at.call(-7, 0, 10.5), folder + "/hall3-loading.png", 70.0)
	await shot(camera, at.call(-18, 5, -6), at.call(-10.5, 1.5, 4), folder + "/truck.png")
	print("WAREHOUSE HALL CAPTURE done")
	quit()
