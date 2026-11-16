extends SceneTree
## Stage 4c views (4 Nov 2026): pinyin under the Chinese text with Chinese as the foreign
## language (a draft language, so the Lexicon is set directly): Dr. Li's greeting in the
## dialogue box, a family question with the translation revealed, and a word card.
## Graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home2 VT_FOCUS=hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/chinese-pinyin-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-pinyin-20261104/" + name + ".png")

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
	# The languages Main last saw, so nothing is taken as a language change (which ends the game).
	game.ui_languages = "en/zh"
	game.progress_language = "zh"
	var family = game.get_node("FamilySession")
	game.player.global_position = family.doctor.global_position - family.doctor.global_basis.z * 3.0
	family._process(.1)
	family.offered = true
	family._on_doctor(family.doctor)
	await shot("greeting")
	family._on_choice("family_play")
	for attempt in 60:
		if family.question.get("kind", "") == "relation":
			break
		family.next_question()
	family.panel.show_native = true
	family.panel.refresh_display()
	await shot("question-revealed")
	family.close_game()
	family.dialogue_panel.hide_dialogue()
	game.hud.show_card("", "", "Family", "grandfather")
	await shot("word-card")
	print("CHINESE PINYIN CAPTURE done ", family.tree.template_id, " | ", family.panel._reading.text, " | ", game.hud.reading_label.text)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	quit()
