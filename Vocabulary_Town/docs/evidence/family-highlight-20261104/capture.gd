extends SceneTree
## Family game highlight (4 Nov 2026): the people a question names are highlighted on the
## tree (a relation question's subject; both people of a pair), and nobody for a question
## that names nobody. Graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home2 VT_FOCUS=hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/family-highlight-20261104/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/family-highlight-20261104/" + name + ".png")

func ask(session, kinds: Array) -> void:
	for i in 60:
		if session.question.get("kind", "") in kinds:
			return
		session.next_question()

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
	var session = game.get_node("FamilySession")
	var panel = game.family_panel
	session.open_game()
	var lex = session.lexicon
	for view in [["relation", ["relation"]], ["pair", ["older_younger_yes_no", "before_after_yes_no"]], ["pair-who", ["pair_older_younger"]], ["none", ["birth_year", "age", "birth_month"]]]:
		ask(session, view[1])
		await shot(view[0])
		print("FAMILY HIGHLIGHT ", view[0], " | ", session.question.kind, " | ", panel._question.text, " | named ", panel.ui.named.map(func(id): return session.tree.people[id].name))
	# A wrong tap on a highlighted pair card: the red mark replaces the gold border.
	ask(session, ["pair_older_younger"])
	for id in panel.ui.named:
		if id != session.question.answer:
			panel.cards[id].pressed.emit()
	await shot("pair-wrong")
	print("FAMILY HIGHLIGHT CAPTURE done | foreign ", lex.foreign)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	quit()
