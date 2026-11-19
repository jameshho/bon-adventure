extends SceneTree
## Rendered views of the UI art style, phase 2 (user, 18 Nov 2026; docs/guides/UI_STYLE.md):
## Settings, the HUD corner buttons with a word card, the journal (list and a word's page) and
## the F1 guide, over the real town. Overwrites the PNGs it names in this folder. Needs graphics
## and an isolated HOME (Main saves progress and settings):
## HOME=<scratch>/home VT_FOCUS=supermarket VT_SPAWN=none godot --path . --resolution 1280x720 --script res://docs/evidence/ui-style-20261118/capture_phase2.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const OUT := "res://docs/evidence/ui-style-20261118/"

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 30:
		await process_frame
	game.hud.show_card("apple", "manzana", "Food", "apple")
	await shot("hud_card")
	game.hud.hide_card() if game.hud.has_method("hide_card") else game.hud.show_card("", "", "")
	await shot("hud")
	game.open_settings()
	await shot("settings")
	game.settings_panel.close()
	await process_frame
	game.toggle_study_journal()
	await shot("journal")
	var book = game.hud.journal_book
	var key: String = "apple" if game.vocabulary.has("apple") else str(game.vocabulary.keys()[0])
	book.open_detail(key)
	await shot("journal_word")
	book.close_detail()
	game.toggle_study_journal()
	game.hud.toggle_help()
	await shot("help")
	game.hud.toggle_help()
	print("UI STYLE PHASE 2 CAPTURE done")
	quit(0)
