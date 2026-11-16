extends SceneTree
## Hold-to-peek (user decision, 9 Nov 2026): holding L or the HUD badge button shows world
## signs and labels in the native language until released. Graphics required, isolated HOME
## (Main saves progress and settings; the script removes its user://settings.json at the end):
## HOME=<scratch>/home VT_FOCUS=supermarket godot --path . --resolution 1600x1000 --script res://docs/evidence/peek-20261109/capture.gd
## Prints "PEEK: N checks, M failures" and writes the PNGs next to this script.
const GameSettings := preload("res://scripts/core/game_settings.gd")
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/peek-20261109/" + name + ".png")

func l_key(down: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_L
	key.physical_keycode = KEY_L
	key.pressed = down
	Input.parse_input_event(key)
	Input.flush_buffered_events()

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	var settings = GameSettings.shared()
	check(settings.display == GameSettings.FOREIGN and not settings.peeking, "Foreign, not peeking at start")
	# The biggest translated sign (a building name), seen through a camera in front of it.
	var sign: Label3D = null
	for label in get_nodes_in_group("translated_signs"):
		if label.is_visible_in_tree() and label.get_meta("sign_english") != label.get_meta("sign_spanish") and (sign == null or label.font_size * label.pixel_size > sign.font_size * sign.pixel_size):
			sign = label
	check(sign != null, "a translated sign exists")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = sign.global_position + sign.global_basis.z.normalized() * 6.0
	camera.look_at(sign.global_position, Vector3.UP)
	camera.make_current()
	print("sign: %s / %s" % [sign.get_meta("sign_spanish"), sign.get_meta("sign_english")])
	check(sign.text == sign.get_meta("sign_spanish"), "sign starts in the foreign language")
	await shot("foreign")
	l_key(true)
	await process_frame
	check(settings.peeking, "holding L peeks")
	check(sign.text == sign.get_meta("sign_english"), "sign in the native language while L is held")
	check(settings.display == GameSettings.FOREIGN, "peeking does not change the Display Mode")
	check(not FileAccess.file_exists(GameSettings.PATH) or JSON.parse_string(FileAccess.get_file_as_string(GameSettings.PATH)).get("display", 1) == GameSettings.FOREIGN, "peeking is not saved")
	await shot("peek-held")
	check(settings.peeking and sign.text == sign.get_meta("sign_english"), "still peeking while held")
	l_key(false)
	await process_frame
	check(not settings.peeking and sign.text == sign.get_meta("sign_spanish"), "releasing L goes back")
	# The touch button: down peeks, up ends it.
	var button: Button = game.hud.peek_button
	check(button.visible and button.text == settings.native_badge(), "peek button shows the native badge")
	check(button.size.x >= 52.0, "peek button is a finger-sized target")
	button.button_down.emit()
	check(settings.peeking and sign.text == sign.get_meta("sign_english"), "button down peeks")
	button.button_up.emit()
	check(not settings.peeking and sign.text == sign.get_meta("sign_spanish"), "button up ends the peek")
	# A missed release cannot leave the peek on.
	settings.set_peek(true)
	for i in range(3): await process_frame
	check(not settings.peeking, "a peek with nothing held ends by itself")
	# Native mode hides the button.
	settings.set_native(true)
	await process_frame
	check(not button.visible, "no peek button in Native mode")
	settings.set_native(false)
	game.hud.toggle_help()
	await shot("help")
	game.hud.toggle_help()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("PEEK: %d checks, %d failures" % [checks, failures])
	quit()
