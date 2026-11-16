extends SceneTree
## Dr. Li's family game views; graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home VT_FOCUS=hospital godot --path . --resolution 1600x1000 --script res://docs/evidence/family-game-20261104/capture.gd
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/family-game-20261104/" + name + ".png")

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
	var doctor: Node3D = session.doctor
	var panel = game.family_panel
	var box = session.dialogue_panel
	var hospital: Node3D = game.apartment.get_node("Buildings/Hospital")
	# The player stands in front of Dr. Li; a camera behind shows her "!".
	game.player.global_position = doctor.global_position - doctor.global_basis.z * 4.0
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.fov = 60.0
	camera.global_position = hospital.to_global(Vector3(-0.8, 2.0, -18.0))
	camera.look_at(doctor.global_position + Vector3(0, 1.0, 0))
	camera.current = true
	game.hud.hide()
	await shot("dr-li-calling")
	game.hud.show()
	game.interaction.clerk_activated.emit(doctor)
	await shot("greeting")
	for i in range(30): await process_frame
	await shot("greeting-later")
	box.choice_pressed.emit("family_play")
	# A person question, a wrong tap, then the right one, with the translation shown.
	for i in 20:
		if not bool(session.question.get("yes_no", false)) and session.question.kind == "relation":
			break
		session.next_question()
	await shot("question")
	var wrong := ""
	for id in session.tree.people:
		if id != session.question.answer:
			wrong = id
			break
	panel.cards[wrong].pressed.emit()
	await shot("wrong")
	panel.cards[session.question.answer].pressed.emit()
	panel.toggle_translation()
	await shot("right-translation")
	panel.toggle_translation()
	# A yes/no question on another family.
	for i in 40:
		session.next_question()
		if bool(session.question.get("yes_no", false)) and session.tree.template_id != "big_family":
			break
	await shot("yes-no")
	# The reported bug: a solved yes/no question with the translation on.
	panel.answer_pressed.emit(str(session.question.answer))
	panel.toggle_translation()
	await shot("yes-no-translation")
	panel.toggle_translation()
	# A narrower laptop window, translation on.
	root.size = Vector2i(1280, 800)
	panel.toggle_translation()
	await shot("yes-no-1280")
	print("FAMILY GAME CAPTURE done")
	quit()
