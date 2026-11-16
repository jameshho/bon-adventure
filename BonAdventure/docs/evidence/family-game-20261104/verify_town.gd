extends SceneTree
## 4 Nov 2026: Dr. Li's family game inside the real town (Main). Main saves progress, so
## run with an isolated HOME (README). A VT_FOCUS run that skips interiors must be reported
## as focused:
## HOME=<scratch>/home VT_FOCUS=hospital godot --headless --path . --script res://docs/evidence/family-game-20261104/verify_town.gd
const Questions := preload("res://scripts/learning/family_questions.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func finish() -> void:
	print("family game town: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var session = game.get_node_or_null("FamilySession")
	var lex = session.lexicon if session != null else null
	check(session != null and session.doctor != null, "Main creates the family session with Dr. Li")
	if session == null or session.doctor == null:
		finish()
		return
	var doctor: Node3D = session.doctor
	var panel = game.family_panel
	check(doctor.name == "DrLi" and doctor.get_meta("shop_clerk", "") == "family_dr_li", "Dr. Li is a talk target")
	check(game.interaction.action_hint_text(doctor.get_meta("action_hint", "")) == "E: " + lex.phrase("common.talk_prompt", lex.foreign), "E hint: " + game.interaction.action_hint_text(doctor.get_meta("action_hint", "")))
	check(str(doctor.get_meta("character_name", "")) == lex.phrase("hospital.dr_li", lex.foreign), "Dr. Li keeps her name")
	# The shared presence: a "!" child of Dr. Li; the shop clerks use the same script.
	var marker: Label3D = doctor.get_node_or_null("NeedsHelpMarker")
	check(marker != null, "Dr. Li has the gold '!' marker")
	for shop in game.get_children().filter(func(node): return str(node.name).begins_with("ShopSession_")):
		if shop.clerk != null:
			check(shop.presence != null and shop.clerk.get_node_or_null("NeedsHelpMarker") != null, "%s keeps its '!' through npc_presence.gd" % shop.name)
	# Calling only while the player is near and nothing is open.
	var rest: Vector3 = session.presence.rest_position
	game.player.global_position = doctor.global_position + doctor.global_basis * Vector3(0, 0, -60)
	session._process(.1)
	check(not marker.visible, "no '!' when the player is far away")
	game.player.global_position = doctor.global_position - doctor.global_basis.z * 3.0
	session._process(.1)
	session._process(.3)
	check(marker.visible and doctor.position.y >= rest.y, "'!' and hop when the player is near")
	# Talking: the greeting in the shared dialogue box, with two choices.
	game.interaction.clerk_activated.emit(doctor)
	var box = session.dialogue_panel
	check(box.is_dialogue_visible() and box.speaker_label.text == lex.phrase("hospital.dr_li", lex.foreign), "greeting from Dra. Li: " + box.speaker_label.text)
	check(box.foreign_label.text == lex.phrase("family.greeting", lex.foreign), "greeting text: " + box.foreign_label.text)
	check(box.has_choices() and box._choices.size() == 2, "greeting offers play / not now")
	session._process(.1)
	check(not marker.visible and doctor.position.is_equal_approx(rest), "'!' hidden and Dr. Li at rest while talking")
	box.choice_pressed.emit("family_play")
	await process_frame
	check(panel.visible and not box.is_dialogue_visible(), "'let's go' opens the family panel and closes the box")
	check(not game.player.controls_enabled, "player controls are locked while the panel is open")
	check(panel.cards.size() == session.tree.people.size() and panel.cards.size() == 7, "one card per family member: %d" % panel.cards.size())
	var question: Dictionary = session.question
	check(not question.is_empty() and Questions.answers(session.tree, question) == [question.answer], "the question has exactly one answer")
	# The people the question names are highlighted (gold border and glow), nobody else.
	var lit: Array = []
	for id in panel.cards:
		var style: StyleBoxFlat = panel.cards[id].get_theme_stylebox("normal")
		if style.border_color == panel.NAMED_EDGE and style.shadow_size > 0:
			lit.append(id)
	lit.sort()
	var want_lit: Array = Questions.named(question).duplicate()
	want_lit.sort()
	check(lit == want_lit and panel.ui.named == Questions.named(question), "%s highlights %s: %s" % [question.kind, want_lit, lit])
	check(not "{" in panel._question.text and panel._question.text == lex.phrase(question.phrase, lex.foreign, question.values), "question text: " + panel._question.text)
	check(not panel._native.visible, "translation hidden: " + panel._native.text)
	panel.toggle_translation()
	check(panel._native.visible and panel._native.text == lex.phrase(question.phrase, lex.native, question.values), "show translation reveals the native line: " + panel._native.text)
	panel.toggle_translation()
	# Cards show name, age in the foreign language and MM/DD/YYYY; the legend is shown.
	var any_id: String = session.tree.people.keys()[0]
	var person: Dictionary = session.tree.people[any_id]
	var card: Button = panel.cards[any_id]
	var column: Node = card.get_node("Column")
	check(column.get_child(1).get_node("Name").text == person.name, "card name: " + person.name)
	check(column.get_node("Age").text == lex.phrase("posters.age", lex.foreign, {"age": person.age}), "card age: " + column.get_node("Age").text)
	var date: String = column.get_node("Date").text
	check(date == "%02d/%02d/%04d" % [person.birth.m, person.birth.d, person.birth.y], "card date MM/DD/YYYY: " + date)
	check(column.get_child(1).get_node("Gender").text == ("♀" if person.gender == "f" else "♂"), "card gender icon")
	check(panel._legend.text == lex.phrase("family.date_legend", lex.foreign) and "11/04/2026" in panel._today.text, "legend and today: %s / %s" % [panel._legend.text, panel._today.text])
	# Answer: wrong first (retry allowed), then right.
	var yes_no := bool(question.get("yes_no", false))
	check(panel._yes.visible == yes_no and panel._no.visible == yes_no, "Yes / No buttons only for yes/no questions")
	var wrong := ""
	if yes_no:
		wrong = "no" if question.answer == "yes" else "yes"
	else:
		for id in session.tree.people:
			if id != question.answer:
				wrong = id
				break
	if yes_no:
		panel.answer_pressed.emit(wrong)
	else:
		panel.cards[wrong].pressed.emit()
	check(panel.marks.get(wrong, true) == false and not panel.solved and not panel._next.visible, "a wrong answer is marked ✗ and allows another try")
	check(panel._feedback.text == lex.phrase("family.wrong", lex.foreign), "wrong feedback: " + panel._feedback.text)
	if yes_no:
		panel.answer_pressed.emit(str(question.answer))
	else:
		panel.cards[question.answer].pressed.emit()
	check(panel.marks.get(str(question.answer), false) == true and panel.solved and panel._next.visible, "the right answer is marked ✓ and offers another question")
	# With the translation on, the bar and feedback stay small and the tree keeps its room.
	# (The headless window is tiny, so the check sets a laptop-sized window first.)
	var before: Vector2i = root.size
	root.size = Vector2i(1600, 1000)
	panel.toggle_translation()
	await process_frame
	await process_frame
	var screen: Vector2 = panel.get_viewport_rect().size
	check(panel._feedback.size.y < screen.y * .15 and panel._tree.size.y > screen.y * .4, "translation on: feedback %.0f px tall, tree %.0f px of %.0f" % [panel._feedback.size.y, panel._tree.size.y, screen.y])
	panel.toggle_translation()
	root.size = before
	check(panel._feedback.text == lex.phrase("family.correct", lex.foreign), "right feedback: " + panel._feedback.text)
	# Another question: marks cleared; a new family after three questions; both kinds of answer.
	var template: String = session.tree.template_id
	var kinds := {}
	var saw_yes_no := yes_no
	var saw_person := not yes_no
	var changed := false
	for index in 12:
		panel.next_pressed.emit()
		kinds[session.question.kind] = true
		saw_yes_no = saw_yes_no or bool(session.question.get("yes_no", false))
		saw_person = saw_person or not bool(session.question.get("yes_no", false))
		changed = changed or session.tree.template_id != template
		if index == 0:
			check(panel.marks.is_empty() and not panel.solved and panel.feedback.is_empty(), "another question clears the marks")
	check(changed, "a new family from another template after %d questions" % session.QUESTIONS_PER_FAMILY)
	check(saw_yes_no and saw_person and kinds.size() >= 4, "questions vary: %s" % [kinds.keys()])
	# Keys are swallowed; Esc passes through to Main's popup stack (4 Nov 2026), which
	# closes the panel with Dr. Li's goodbye.
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	await process_frame
	check(not panel.visible, "Esc closes the panel")
	check(box.is_dialogue_visible() and box.foreign_label.text == lex.phrase("family.goodbye", lex.foreign), "Dr. Li says goodbye: " + box.foreign_label.text)
	check(game.player.controls_enabled, "player controls return")
	box.dialogue_closed.emit()
	check(not box.is_dialogue_visible() and not session.busy(), "closing the goodbye ends the session")
	# "Not now" path.
	game.interaction.clerk_activated.emit(doctor)
	box.choice_pressed.emit("family_no")
	check(box.foreign_label.text == lex.phrase("family.goodbye", lex.foreign) and not panel.visible, "'not now' says goodbye without opening the panel")
	box.dialogue_closed.emit()
	# Walking away from the greeting closes it.
	game.interaction.clerk_activated.emit(doctor)
	game.player.global_position = doctor.global_position - doctor.global_basis.z * 20.0
	session._process(.1)
	check(not box.is_dialogue_visible() and not session.busy(), "walking away closes the greeting")
	finish()
