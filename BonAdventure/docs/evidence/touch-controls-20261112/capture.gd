extends SceneTree
## Rendered view of the touch controls (PWA phase 5, 12 Nov 2026) at a landscape phone size,
## joystick pushed up-right. Overwrites touch.png here. Graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/touch-controls-20261112/capture.gd
func _initialize(): run.call_deferred()
func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	game.day_night.set_time(11.5 * 60.0)
	var controls: Control = game.hud.ui_root.get_node("TouchControls")
	controls.touch_mode = true
	await process_frame
	controls._move_stick(controls._stick_center + Vector2(0.5, -0.7) * controls._stick_radius * 0.8)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/evidence/touch-controls-20261112/touch.png"))
	controls._move_stick(controls._stick_center)
	quit()
