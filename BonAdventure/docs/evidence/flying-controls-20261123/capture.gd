extends SceneTree
## Rendered views of the flying controls (23 Nov 2026, docs/guides/aircraft.md#flying-controls):
## the helicopter in the air with the ▲ / ▼ Buttons (mouse: no touch mode), the same with touch
## mode on, the plane on the runway, and the F1 guide's aircraft cards. Overwrites the PNGs here.
## Graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/flying-controls-20261123/capture.gd
func _initialize(): run.call_deferred()
func shot(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/evidence/flying-controls-20261123/"+name))
func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	game.day_night.set_time(11.5 * 60.0)
	var controls: Control = game.hud.ui_root.get_node("TouchControls")
	var heli: Node3D = null
	for vehicle in game.driveable_vehicles:
		if vehicle.helicopter: heli = vehicle
	game.player.global_position = heli.boarding_step_point()
	game.toggle_vehicle()
	for i in 200: await physics_frame
	Input.action_press("jump")
	for i in 150: await physics_frame
	Input.action_release("jump")
	for i in 60: await physics_frame
	await shot("helicopter-mouse.png")
	controls.touch_mode = true
	game.hud.set_touch_mode(true)
	await shot("helicopter-touch.png")
	# Land again and get out, then board the plane.
	heli.global_position.y -= 0.0
	Input.action_press("descend")
	for i in 600: await physics_frame
	Input.action_release("descend")
	game.toggle_vehicle()
	for i in 200: await physics_frame
	var plane: Node3D = game.apartment.get_node("Vehicles/Turboprop")
	game.player.global_position = plane.to_global(Vector3(-2.5, .1, -1.1))
	game.toggle_vehicle()
	for i in 220: await physics_frame
	await shot("turboprop-touch.png")
	game.hud.toggle_help()
	await shot("help.png")
	quit()
