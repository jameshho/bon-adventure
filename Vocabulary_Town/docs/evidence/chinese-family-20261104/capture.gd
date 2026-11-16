extends SceneTree
## Stage 4b views (4 Nov 2026): the family game with Chinese as the foreign language (a draft
## language, so the check sets the Lexicon directly; Settings does not offer it): a
## relationship question in Foreign only with the translation revealed, and the panel in
## Both. Graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home2 VT_FOCUS=hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/chinese-family-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-family-20261104/" + name + ".png")

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
	# Set the languages Main last saw too, so the Display Mode change below is not taken as a
	# language change (which would end the game).
	game.ui_languages = "en/zh"
	game.progress_language = "zh"
	var family = game.get_node("FamilySession")
	game.player.global_position = family.doctor.global_position - family.doctor.global_basis.z * 3.0
	family._process(.1)
	family.open_game()
	for attempt in 60:
		if family.question.get("kind", "") == "relation" and family.tree.template_id in ["cousins", "mothers_side"]:
			break
		family.next_question()
	family.panel.show_native = true
	family.panel.refresh_display()
	await shot("relation-revealed")
	GameSettings.shared().set_display(GameSettings.BOTH)
	family.panel.refresh_display()
	await shot("both")
	GameSettings.shared().set_display(GameSettings.FOREIGN)
	print("CHINESE FAMILY CAPTURE done ", family.tree.template_id, " ", family.question.get("label", ""))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	quit()
