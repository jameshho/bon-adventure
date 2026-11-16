extends SceneTree
## Stage 0 of the vocabulary tracking work (7 Nov 2026): Both removed, Native mode is a
## Settings checkbox, no L key or HUD mode button. Graphics required, isolated HOME (Main
## saves progress and settings; the script removes its user://settings.json at the end):
## HOME=<scratch>/home VT_FOCUS=hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/display-mode-20261107/capture.gd
## Prints "DISPLAY MODE: N checks, M failures" and writes the PNGs next to this script.
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
	root.get_texture().get_image().save_png("res://docs/evidence/display-mode-20261107/" + name + ".png")

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	# A saved old Both (2) loads as Foreign.
	var file := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"display": 2}))
	file.close()
	var loaded = GameSettings.new()
	loaded.load_saved()
	check(loaded.display == GameSettings.FOREIGN, "saved Both (2) loads as Foreign")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	var settings = GameSettings.shared()
	check(settings.display == GameSettings.FOREIGN, "Foreign by default")
	check(not "mode_button" in game.hud and not game.hud.has_method("cycle_language"), "no HUD mode button or cycle")
	var key := InputEventKey.new()
	key.keycode = KEY_L
	key.pressed = true
	game._unhandled_input(key)
	check(settings.display == GameSettings.FOREIGN, "L does nothing")
	game.open_settings()
	var box: CheckBox = game.settings_panel._native_mode
	check(not box.button_pressed, "checkbox off by default")
	await shot("settings-off")
	box.toggled.emit(true)
	box.set_pressed_no_signal(true)
	check(settings.display == GameSettings.NATIVE and game.hud.mode == GameSettings.NATIVE, "checkbox turns Native mode on")
	check(JSON.parse_string(FileAccess.get_file_as_string(GameSettings.PATH)).display == GameSettings.NATIVE, "Native mode is saved")
	await shot("settings-on")
	game.settings_panel.close()
	var family = game.get_node("FamilySession")
	family.open_game()
	await shot("family-native")
	settings.set_native(false)
	check(settings.display == GameSettings.FOREIGN, "set_native(false) is Foreign")
	await shot("family-foreign")
	family.close_game()
	game.hud.toggle_help()
	await shot("help")
	game.hud.toggle_help()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("DISPLAY MODE: %d checks, %d failures" % [checks, failures])
	quit()
