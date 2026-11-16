extends SceneTree
## Follow camera and the bigger, tap-to-close word card (user, 14 Nov 2026):
##  - player_controller.gd follow_view(): walking sideways turns the view that way; walking
##    forward or straight at the camera turns nothing; a drag pauses it; Settings switches it off
##    (GameSettings.follow_camera, saved).
##  - vocabulary_hud.gd: the word card scales with the window (CARD_SIZE at 1100 x 800);
##    interaction_controller.gd click(): any click or tap closes an open card.
## Main saves settings and study progress: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --fixed-fps 60 --script res://docs/evidence/follow-camera-word-card-20261114/verify.gd
## Windowed (not --headless: the headless viewport is 64 x 64, so the card's size is not
## checked there). With VT_SHOTS=<folder> it also saves pictures of the card and Settings.
## Prints "FOLLOW CAMERA + WORD CARD: N checks, M failures".
const GameSettings := preload("res://scripts/core/game_settings.gd")

var checks := 0
var failures := 0
var main

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

## Holds one move action for `n` physics frames and returns how far camera_yaw turned.
func walk(action: String, n: int) -> float:
	var before: float = main.player.camera_yaw
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(2)
	return main.player.camera_yaw - before

func shot(name: String) -> void:
	var folder := OS.get_environment("VT_SHOTS")
	if folder == "" or DisplayServer.get_name() == "headless":
		return
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

func run() -> void:
	var windowed := DisplayServer.get_name() != "headless"
	if windowed:
		DisplayServer.window_set_size(Vector2i(1280, 720))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	var player = main.player
	var settings = GameSettings.shared()
	check(settings.follow_camera and player.follow_camera, "the follow camera is on by default")
	player.follow_pause = 0.0

	# --- Follow camera ---
	var right: float = await walk("move_right", 40)
	check(right < -0.3, "walking right turns the view right (yaw %.2f)" % right)
	var left: float = await walk("move_left", 40)
	check(left > 0.3, "walking left turns the view left (yaw %.2f)" % left)
	var forward: float = await walk("move_forward", 30)
	check(absf(forward) < 0.001, "walking forward turns nothing (yaw %.3f)" % forward)
	var back: float = await walk("move_back", 30)
	check(absf(back) < 0.001, "walking toward the camera turns nothing (yaw %.3f)" % back)
	player.look_by(Vector2(10, 0))
	var paused: float = await walk("move_right", 30)
	check(absf(paused) < 0.001, "the follow waits after the view was dragged (yaw %.3f)" % paused)
	player.follow_pause = 0.0
	settings.set_follow_camera(false)
	check(not player.follow_camera, "Settings switches the player's follow camera off")
	var off: float = await walk("move_right", 30)
	check(absf(off) < 0.001, "switched off, walking sideways turns nothing (yaw %.3f)" % off)
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameSettings.PATH))
	check(saved is Dictionary and saved.get("follow_camera", true) == false, "the choice is saved with the settings")
	settings.set_follow_camera(true)
	check(player.follow_camera, "and switched on again")

	# --- Word card ---
	var hud = main.hud
	hud.show_card("table", "mesa", "Furniture")
	await frames(3)
	var screen: Vector2 = root.get_visible_rect().size
	var f: float = clampf(minf(screen.y / 800.0, screen.x / 1100.0), 0.5, 3.0)
	if windowed:
		check(absf(hud.popup_panel.size.x - hud.CARD_SIZE.x * f) < 2.0, "the card is %d px wide at %s (CARD_SIZE x %.2f)" % [hud.popup_panel.size.x, screen, f])
		check(hud.primary_label.get_theme_font_size("font_size") == roundi(68 * f), "its word is %d px" % hud.primary_label.get_theme_font_size("font_size"))
		check(hud.bookmark_star.size.x >= 44.0 and hud.card_translate.size.y >= 44.0, "its star and translate button are finger-sized")
	check(hud.close_hint.text != "" and hud.close_hint.is_visible_in_tree(), "its bottom line says how to close (\"%s\")" % hud.close_hint.text)
	await shot("card-1280x720")
	main.interaction.pointer_position = screen * 0.5
	main.interaction.click()
	check(not hud.is_card_visible(), "a click or tap on the card closes it")
	hud.show_card("table", "mesa", "Furniture")
	main.interaction.pointer_position = Vector2(20, screen.y - 20)
	main.interaction.click()
	check(not hud.is_card_visible(), "a click or tap anywhere else closes it too")
	if windowed and OS.get_environment("VT_SHOTS") != "":
		main.open_settings()
		await shot("settings-1280x720")
		# A landscape phone's shape (the scale's lower end).
		DisplayServer.window_set_size(Vector2i(844, 390))
		await frames(6)
		await shot("settings-844x390")
		main.settings_panel.close()
		hud.show_card("refrigerator", "el refrigerador", "Kitchen")
		await shot("card-844x390")
		hud.hide_card()
	print("FOLLOW CAMERA + WORD CARD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
