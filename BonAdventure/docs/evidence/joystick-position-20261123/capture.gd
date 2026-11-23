extends SceneTree
## The touch joystick at rest after it moved up and right and grew 30 % (23 Nov 2026, user).
## Phone landscape size like the user's screenshot. Graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 2000x1139 --script res://docs/evidence/joystick-position-20261123/capture.gd
func _initialize(): run.call_deferred()
func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	game.day_night.set_time(11.5 * 60.0)
	var controls: Control = game.hud.ui_root.get_node("TouchControls")
	controls.touch_mode = true
	game.hud.set_touch_mode(true)
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/evidence/joystick-position-20261123/phone-touch.png"))
	print("stick home ", controls._stick_home, " radius ", controls._stick_radius, " view ", root.get_visible_rect().size)
	quit()
