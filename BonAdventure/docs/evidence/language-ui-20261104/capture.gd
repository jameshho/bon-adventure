extends SceneTree
## UI Stage 3 views (4 Nov 2026): the word card in Foreign only with its translate bubble
## revealed (English speaker learning Spanish), then the interface in Spanish (Spanish
## speaker learning English): the F1 guide, the journal by area and the town map.
## Graphics required, isolated HOME (Main saves progress and settings):
## HOME=<scratch>/home2 VT_FOCUS=supermarket,hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/language-ui-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/language-ui-20261104/" + name + ".png")

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
	var settings = GameSettings.shared()
	var hud = game.hud
	settings.set_languages("en", "es")
	settings.set_display(GameSettings.FOREIGN)
	hud.show_card("Apple", "la manzana", "Food & Drink", "apple")
	hud.card_translate.pressed.emit()
	await shot("card-foreign-revealed")
	hud.hide_card()
	settings.set_languages("es", "en")
	hud.set_progress(game.current_room(), game.studied_words.size())
	hud.toggle_help()
	await shot("help-spanish")
	hud.toggle_help()
	hud.toggle_journal(game.studied_words, game.vocabulary, game.vocabulary_categories, game.area_vocabulary.groups, game.area_vocabulary.area_names)
	hud.set_journal_view(true)
	await shot("journal-spanish")
	hud.toggle_journal({}, {})
	hud.toggle_map()
	await shot("map-spanish")
	hud.toggle_map()
	settings.set_languages("en", "es")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("LANGUAGE UI CAPTURE done")
	quit()
