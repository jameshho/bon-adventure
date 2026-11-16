extends SceneTree
## Chinese playable (4 Nov 2026): the player picks Chinese in Settings as the language being
## learned (English native), then the town follows: a word card with pinyin and the HUD.
## Graphics required, isolated HOME (Main saves progress and settings):
## HOME=<scratch>/home2 VT_FOCUS=supermarket godot --path . --resolution 1600x1000 --script res://docs/evidence/chinese-playable-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-playable-20261104/" + name + ".png")

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	var lex = preload("res://scripts/language/lexicon.gd").shared()
	var panel = game.settings_panel
	panel.open()
	var pick: OptionButton = panel._foreign_pick
	var index: int = lex.playable_codes().find("zh")
	pick.select(index)
	pick.item_selected.emit(index)
	await shot("settings-chinese")
	panel.close()
	game.hud.show_card("", "", "Food & Drink", "apple")
	await shot("card-apple")
	print("CHINESE PLAYABLE CAPTURE done | playable ", lex.playable_codes(), " | foreign ", lex.foreign, " | ", game.hud.primary_label.text, " ", game.hud.reading_label.text)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	quit()
