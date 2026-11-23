extends SceneTree
## Rendered views of the smaller plane and its rewritten flight (23 Nov 2026,
## docs/guides/aircraft.md): parked beside BonBon, BonBon in the cockpit, then flown with the real
## controls (Input actions) in the game's chase view: the take-off roll, climbing, a right turn
## and hands-off level flight. Overwrites the PNGs here. Graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/small-plane-20261123/capture.gd
const DIR := "res://docs/evidence/small-plane-20261123/"
func _initialize(): run.call_deferred()
func shot(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR+name))
func hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames: await physics_frame
	Input.action_release(action)
func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	game.day_night.set_time(11.5 * 60.0)
	var plane: Node3D = game.apartment.get_node("Vehicles/Turboprop")
	# Parked, BonBon standing by the cabin step (a fixed camera).
	game.player.global_position = plane.to_global(Vector3(-4.5, .1, -1.5))
	for i in 20: await physics_frame
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = plane.to_global(Vector3(-16, 7, -14))
	camera.look_at(plane.to_global(Vector3(-1, 1.5, 0)))
	camera.current = true
	game.hud.hide()
	await shot("parked.png")
	game.player.global_position = plane.boarding_step_point()
	game.toggle_vehicle()
	for i in 200: await physics_frame
	camera.global_position = plane.to_global(Vector3(-5, 3.6, -4.5))
	camera.look_at(plane.to_global(Vector3(0, 2, -1.2)))
	await shot("cockpit.png")
	camera.queue_free()
	game.player.camera.current = true
	game.hud.show()
	await hold("jump", 150)
	Input.action_press("jump")
	for i in 30: await physics_frame
	await shot("takeoff.png")
	for i in 300: await physics_frame
	await shot("climb.png")
	Input.action_release("jump")
	Input.action_press("move_right")
	for i in 120: await physics_frame
	await shot("turn.png")
	Input.action_release("move_right")
	for i in 300: await physics_frame
	await shot("level.png")
	quit()
