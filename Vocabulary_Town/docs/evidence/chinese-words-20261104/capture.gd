extends SceneTree
## Stage 4d batch 3 views (4 Nov 2026): word cards with Chinese as the foreign language and
## English as the native one (a draft language, so the Lexicon is set directly), one each
## from Electronics, Health & Body and Clothing, with the translation revealed on the last.
## Graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home2 VT_FOCUS=supermarket godot --path . --resolution 1600x1000 --script res://docs/evidence/chinese-words-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-words-20261104/" + name + ".png")

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
	lex.native = "en"
	lex.foreign = "zh"
	game.ui_languages = "en/zh"
	game.progress_language = "zh"
	var hud = game.hud
	var seen: Array = []
	for row in [["refrigerator", "Electronics & Appliances", false], ["stethoscope", "Health & Body", false], ["sneakers", "Clothing", true]]:
		hud.show_card("", "", row[1], row[0])
		if row[2]:
			hud.card_translate.pressed.emit()
		await shot("card-" + row[0])
		seen.append("%s %s %s" % [hud.primary_label.text, hud.reading_label.text, hud.secondary_label.text])
		hud.hide_card()
	print("CHINESE WORDS CAPTURE done | ", " | ".join(seen))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	quit()
