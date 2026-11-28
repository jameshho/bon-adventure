extends SceneTree
## Grammar Classroom (6 Nov 2026; guide docs/guides/GRAMMAR_CLASS.md): the remodelled classroom and a
## class played through the real session, seating controller and card. Covers the brief's test
## list: staying seated across questions, switching seats, early Confirm, timeout with no seat,
## repeated Confirm, leaving a seat just before the timeout, shuffling, the green desk, the
## 2-second feedback that does not eat the next countdown, the doorway exit (cancel and leave),
## Replay, no repeats in a class, the three banks, and the classroom after a class.
## Updated 8 Nov 2026: after every answer the game stands the player up and walks them back to
## the start (the old "stays seated across questions" check now checks that walk), and the
## countdown is the large number in the middle of the screen. Later on 8 Nov: the start moved
## closer to the board, and missed questions come back once at the end (the review). 9 Nov: after
## a miss the explanation stays until Continue or 10 s. 14 Nov: 5 questions a class, every miss
## comes back once (at most 10), the bigger board (6.0 × 2.6) with fitted text, and the months
## poster on the left side wall.
## Uses Main, which saves progress: run with an isolated HOME (README). Works with the full
## town or VT_FOCUS=school (report a focused run as focused).
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/grammar-class-20261106/verify.gd
const School := preload("res://scripts/buildings/school.gd")
const Questions := preload("res://scripts/learning/grammar_questions.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
var failures := 0
var checks := 0
var game
var session
var school: Node3D

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## Lets the session's _process run `seconds` of game time in `step` slices.
func tick(seconds: float, step := 0.1) -> void:
	var left := seconds
	while left > 0.0001:
		var d := minf(step, left)
		session._process(d)
		left -= d

## Sits the player on answer chair `letter` through the real seating controller (E).
func sit(letter: String) -> bool:
	var chair: Node3D = session.desks[letter].chair
	if game.player.seated:
		await stand()
	game.player.global_position = chair.global_position + school.global_basis * Vector3(.8, .1, 0)
	game.player.velocity = Vector3.ZERO
	await physics_frame
	var ok: bool = game.interaction.activate_focus()
	for i in 40:
		await physics_frame
		if not game.player.sit_transition:
			break
	return ok and game.player.seated and is_same(game.seating.current.node, chair)

## Stands the player 0.7 behind answer chair `letter` (board side ahead), facing the board,
## and presses E through the real seating controller.
func sit_from_behind(letter: String) -> bool:
	var chair: Node3D = session.desks[letter].chair
	if game.player.seated:
		await stand()
	var board_dir: Vector3 = (school.global_basis * Vector3(0, 0, 1)).normalized()
	game.player.global_position = chair.global_position - board_dir * .7 + Vector3.UP * .1
	game.player.rotation.y = atan2(-board_dir.x, -board_dir.z)
	game.player.velocity = Vector3.ZERO
	await physics_frame
	var ok: bool = game.interaction.activate_focus()
	for i in 40:
		await physics_frame
		if not game.player.sit_transition:
			break
	return ok and game.player.seated and is_same(game.seating.current.node, chair)

func stand() -> void:
	game.seating.stand()
	for i in 40:
		await physics_frame
		if not game.player.sit_transition:
			break

## Lets the real frames run until the walk back to the start is over (or about 8 s pass).
func walk_done() -> bool:
	for i in 500:
		if session._walk == "":
			break
		await physics_frame
	return session._walk == ""

## After the walk: Continue if a miss holds the feedback, then let the feedback end.
func advance() -> void:
	await walk_done()
	if session.state == "feedback" and session._holding:
		game.grammar_card.confirm_button.pressed.emit()
	for i in 30:
		if session.state != "feedback":
			break
		tick(0.1)

func at_start() -> bool:
	var p: Vector3 = school.to_local(game.player.global_position)
	return Vector2(p.x - School.START.x, p.z - School.START.z).length() < .6

func green_desks() -> Array:
	var found := []
	for letter in session.desks:
		if session.desks[letter].glow.visible:
			found.append(letter)
	return found

func right_letter() -> String:
	var answer := str(session.questions[session.current].answer)
	for letter in session.on_desk:
		if str(session.on_desk[letter]) == answer:
			return letter
	return ""

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	preload("res://scripts/learning/game_progress.gd").shared().unlock("grammar_lana", 2)  # the level this check tests (a new profile starts at level 1; LEARN-06, 25 Nov 2026)
	game.set_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	session = game.get_node_or_null("GrammarSession")
	school = preload("res://scripts/world/modular_town.gd").building(game.apartment, "school", 1)
	check(school != null and session != null, "school loaded and the grammar session exists")
	if school == null or session == null:
		finish()
		return
	# --- The classroom -------------------------------------------------------------------------
	check(session.lana != null and session.lana.get_meta("word_key", "") == "teacher", "Lana stands in the classroom (word teacher)")
	check(session.desks.size() == 4 and session.board != null, "four answer desks with chairs and the board")
	var objects: Node3D = school.get_node("RetainedLearningObjects")
	var counts := {}
	for node in objects.get_children():
		var key := str(node.get_meta("word_key", ""))
		counts[key] = counts.get(key, 0) + 1
	check(counts.get("desk", 0) == 6 and counts.get("chair", 0) == 6, "6 desks and 6 chairs (%s / %s)" % [counts.get("desk", 0), counts.get("chair", 0)])
	for key in ["notebook", "whiteboard", "piano", "guitar", "violin", "microphone", "trumpet", "drum", "sheet music"]:
		check(counts.get(key, 0) >= 1, "word still in the school: " + key)
	check(counts.get("whiteboard", 0) == 1 and session.board.get_meta("word_key", "") == "whiteboard", "one board, the whiteboard word")
	var board_x: float = school.to_local(session.board.global_position).x
	check(school.to_local(session.board.global_position).z > 5.0 and board_x < -4.0, "board on the rear wall of the classroom half")
	var board_size: Vector3 = session.board.get_meta("grammar_board")
	check(board_size.x >= 5.9 and board_size.y >= 2.5, "the bigger board (%s)" % board_size)
	var months: Node3D = school.get_node_or_null(School.MONTHS_POSTER)
	var months_at: Vector3 = school.to_local(months.global_position) if months != null else Vector3.ZERO
	var months_faces: Vector3 = school.global_basis.inverse() * (months.global_basis * Vector3(0, 0, -1)) if months != null else Vector3.ZERO
	check(months != null and months_at.x < -11.5 and months_at.z < -7.0 and months_faces.x > 0.9, "months poster on the left side wall, front end, facing the room (%s, %s)" % [months_at, months_faces])
	var month_words := 0
	if months != null:
		for node in months.get_children():
			if str(node.get_meta("word_key", "")) in ["january", "may", "december", "february", "march", "april", "june", "july", "august", "september", "october", "november"]:
				month_words += 1
	check(month_words == 12, "the months poster keeps its 12 month words (%d)" % month_words)
	for letter in session.desks:
		var desk: Vector3 = school.to_local(session.desks[letter].desk.global_position)
		var chair: Vector3 = school.to_local(session.desks[letter].chair.global_position)
		check(chair.z < desk.z and absf(chair.x - desk.x) < .01, "desk %s: chair on the side away from the board" % letter)
		check(desk.z > -1.0, "desk %s is in the front two rows" % letter)
	var a: Vector3 = school.to_local(session.desks.A.desk.global_position)
	var b: Vector3 = school.to_local(session.desks.B.desk.global_position)
	var c: Vector3 = school.to_local(session.desks.C.desk.global_position)
	check(absf(a.x - b.x) > 4.5 and absf(a.z - c.z) > 2.5, "desks spaced (columns %.1f, rows %.1f apart)" % [absf(a.x - b.x), absf(a.z - c.z)])
	# Seats face the board: a seated player looks toward +z (school).
	check(await sit("A"), "the player sits at desk A with E")
	var facing: Vector3 = school.global_basis.inverse() * -game.player.global_basis.z
	check(facing.z > .7, "seated at desk A, the player faces the board (%s)" % facing)
	await stand()
	check(not game.player.seated, "stands up again")
	# Behind an answer chair, facing the board, E picks that chair, not the one in the row
	# behind (seating_controller.gd behind penalty, 7 Nov 2026; the focus pass since 12 Nov).
	for letter in ["A", "C"]:
		check(await sit_from_behind(letter), "behind chair %s facing the board, E sits on chair %s" % [letter, letter])
		await stand()
	# --- Banks -------------------------------------------------------------------------------------
	var lex = Lexicon.shared()
	var words: Dictionary = lex.words()
	for code in ["es", "zh", "en"]:
		var bank = Questions.new()
		check(bank.load_bank(code) and bank.questions.size() >= 16, "%s bank loads (%d questions)" % [code, bank.questions.size()])
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Questions.DIR + code + ".json"))
		var others: Array = lex.playable_codes().filter(func(x): return x != code)
		var problems: PackedStringArray = Questions.problems(parsed, code, others, words)
		check(problems.is_empty(), "%s bank follows the rules %s" % [code, problems.slice(0, 3)])
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var picked: Array = bank.pick(10, rng)
		var ids := {}
		for q in picked:
			ids[q.id] = true
		check(picked.size() == 10 and ids.size() == 10, "%s: 10 different questions per class" % code)
		if code == "zh":
			check(lex.reading(Questions.blanked(bank.questions[0]).replace("＿＿＿", " "), "zh") != "", "Chinese board line has pinyin")
	# Shuffling: over many rounds the right answer lands on every desk.
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 11
	var probe = Questions.new()
	probe.load_bank("es")
	var seen := {}
	for i in 60:
		var answers: Array = Questions.desk_answers(probe.questions[0], rng2)
		seen[answers.find(probe.questions[0].answer)] = true
		if i == 0:
			check(answers.size() == 4 and answers.has(probe.questions[0].answer), "shuffle keeps the four answers")
	check(seen.size() == 4, "the right answer lands on every desk position (%s)" % [seen.keys()])
	# --- A class -----------------------------------------------------------------------------------
	session.offered = true
	await session.start_class()
	for i in 3:
		await physics_frame
	check(session.state == "question" and session.questions.size() == 5, "class started: question 1 of 5 (%d)" % session.questions.size())
	var start: Vector3 = school.to_local(game.player.global_position)
	check(Vector2(start.x - School.START.x, start.z - School.START.z).length() < .6, "player teleported to the start point in the real classroom")
	check(session.board_label.text.contains("＿＿＿"), "the question is on the board")
	check(session.board_label.font_size >= session.BOARD_MIN_FONT and session.board_label.font_size <= 144 and session._text_height(session.board_label) + session._text_height(session.board_reading) <= board_size.y * session.BOARD_TEXT_HEIGHT + 0.01, "the board text fits the board (font %d)" % session.board_label.font_size)
	var desk_texts := []
	for letter in School.ANSWER_DESKS:
		desk_texts.append(session.desks[letter].label.text)
	var choices: Array = session.questions[0].choices.duplicate()
	desk_texts.sort()
	choices.sort()
	check(desk_texts == choices, "the four desks show the question's four answers")
	check(game.grammar_card.visible and game.grammar_card.confirm_button.disabled, "card open; Confirm off while not seated")
	check(game.grammar_card.countdown.visible and game.grammar_card.count_label.text == "10", "large countdown shows 10 (%s)" % game.grammar_card.count_label.text)
	check(game.grammar_card.hint_label.text != "" and not game.grammar_card.status_label.visible, "hint below the countdown; no countdown line on the card")
	# Q1: nobody seated, the timer runs out -> unanswered, no point; the right desk turns green.
	var right := right_letter()
	tick(10.05)
	check(session.state == "feedback" and session.points == 0, "timeout while standing is unanswered (0 points)")
	check(session.questions.size() == 6 and session.questions[5].id == session.questions[0].id and session.questions[5].get("review", false), "the missed question 1 comes back at the end (class of 6)")
	check(green_desks() == [right], "only the right desk is green (%s, right %s)" % [green_desks(), right])
	check(session.board_label.text.contains(str(session.questions[0].answer)), "board shows the completed sentence")
	check(not game.grammar_card.countdown.visible, "the countdown hides during feedback")
	tick(1.9)
	check(session.state == "feedback", "feedback still showing at 1.9 s")
	check(await walk_done(), "the walk back (already at the start) finishes")
	tick(0.15)
	check(session.state == "feedback", "a miss keeps the explanation past 2 s")
	var button: Button = game.grammar_card.confirm_button
	check(button.visible and not button.disabled and game.grammar_card._continue == session.lexicon.line("grammar.continue"), "after a miss the button says Continue (%s)" % button.text)
	tick(maxf(session.time_left, 0.0) + 0.05)
	check(session.state == "question" and session.current == 1, "after 10 s without Continue the next question starts")
	check(game.player.controls_enabled, "controls back for the next question")
	check(session.time_left > 9.9, "the feedback did not use the next countdown (%.2f s left)" % session.time_left)
	check(green_desks().is_empty(), "highlight cleared for the next question")
	# Q2: sit at the right desk, Confirm early; repeated Confirm does nothing.
	right = right_letter()
	check(await sit(right), "sits at the right desk " + right)
	session._process(0.05)
	check(not game.grammar_card.confirm_button.disabled, "Confirm on while at an answer desk")
	var left_before: float = session.time_left
	game.grammar_card.confirm_button.pressed.emit()
	check(session.state == "feedback" and session.points == 1, "early Confirm submits at once (1 point)")
	check(left_before > 5.0, "submitted with time to spare")
	game.grammar_card.confirm_pressed.emit()
	session.confirm()
	session.submit()
	check(session.points == 1 and session.current == 1, "repeated Confirm is ignored")
	check(not game.player.controls_enabled, "controls locked while the game walks the player back")
	check(await walk_done(), "the walk back from desk %s finishes" % right)
	check(not game.player.seated and at_start(), "stood up and walked back to the start (%s)" % school.to_local(game.player.global_position))
	tick(2.05)
	check(session.state == "question", "a right answer moves on after 2 s")
	# Q3: starts at the start; sitting at a desk and waiting submits it on the timeout.
	check(session.state == "question" and not game.player.seated and at_start(), "question 3 starts with the player at the start")
	check(await sit(right), "sits at desk " + right)
	var expected: int = session.points + (1 if session.on_desk[right] == session.questions[session.current].answer else 0)
	tick(10.05)
	check(session.points == expected, "seated: the timeout submits desk %s" % right)
	check(await walk_done() and at_start(), "back at the start after the timeout")
	await advance()
	# Q4: switch seats during the countdown; the seat at the end counts.
	var other: String = "D" if right != "D" else "A"
	check(await sit(right) and await sit(other), "switches from desk %s to desk %s" % [right, other])
	expected = session.points + (1 if session.on_desk[other] == session.questions[session.current].answer else 0)
	tick(10.05)
	check(session.points == expected, "after switching, desk %s is the one submitted" % other)
	check(await walk_done() and at_start(), "back at the start from desk " + other)
	await advance()
	# Q5: stand up just before the timeout -> unanswered.
	check(await sit(right), "sits for question 5")
	# Sitting down let real frames run part of the countdown: stand up with about 1 s left.
	tick(maxf(session.time_left - 1.0, 0.0))
	await stand()
	var before: int = session.points
	tick(1.1)
	check(session.state == "feedback" and session.points == before, "leaving the seat just before the timeout is unanswered")
	# The leave question during the walk stops it; No carries on walking.
	session.ask_leave()
	check(session.state == "paused" and game.player.auto_walk.is_empty(), "asking to leave stops the walk")
	game.shop_panel.quit_answered.emit(false)
	check(session.state == "feedback" and session._walk != "", "No: the walk back carries on")
	check(await walk_done() and at_start(), "back at the start after the leave question")
	check(session._holding, "the miss holds the feedback")
	button.pressed.emit()
	tick(0.05)
	check(session.state == "question", "Continue starts the next question at once")
	# Exit: walking out of the door pauses and asks; "No" puts the player inside and resumes.
	var question_at: int = session.current
	game.player.set_physics_process(false)
	game.player.global_position = school.to_global(School.DOORWAY)
	for i in 6:
		await physics_frame
	check(session.state == "paused" and game.shop_panel.is_quit_open(), "walking out of the doorway pauses and asks")
	var paused_at: float = session.time_left
	tick(3.0)
	check(is_equal_approx(session.time_left, paused_at), "the countdown is paused while asking")
	game.shop_panel.quit_answered.emit(false)
	var inside: Vector3 = school.to_local(game.player.global_position)
	check(session.state == "question" and session.current == question_at and inside.z > School.DOOR_Z + 1.0, "No: back inside, same question, time resumes")
	check(game.player.controls_enabled, "controls back after No")
	for i in 4:
		await physics_frame
	check(session.state == "question" and not game.shop_panel.is_quit_open(), "no repeated question after stepping back in")
	game.player.set_physics_process(true)
	# Finish the class quickly, then Replay.
	while session.state != "over":
		if session.state == "question":
			session.submit()
		await advance()
	check(session.current == session.questions.size() and not game.grammar_card.visible, "after the last question the card closes (%d questions)" % session.questions.size())
	var reviews := 0
	var back_to_back := false
	var ids := {}
	for i in session.questions.size():
		var q: Dictionary = session.questions[i]
		if q.get("review", false):
			reviews += 1
			check(ids.has(q.id) and ids[q.id] == 1, "review %s repeats an earlier question once" % q.id)
		ids[q.id] = ids.get(q.id, 0) + 1
		if i > 0 and session.questions[i - 1].id == q.id:
			back_to_back = true
	check(reviews >= 2 and reviews <= 5 and session.questions.size() == 5 + reviews and session.questions.size() <= 10, "reviews only added at the end (%d, class of %d)" % [reviews, session.questions.size()])
	var missed := 0
	for q in session.questions.slice(0, 5):
		if q.get("missed", false):
			missed += 1
	check(missed == reviews, "every missed question comes back once (%d missed, %d reviews)" % [missed, reviews])
	check(not back_to_back, "a question never comes straight after itself (the last one was not the only miss)")
	check(game.shop_panel.is_dialogue_visible(), "Lana gives the points and offers Replay / Finish")
	# Geometry is checked in the rendered views (dialogue-*-after.png): headless has no real window.
	check(game.shop_panel.compact, "in class the dialogue box is the compact one")
	game.shop_panel.choice_pressed.emit("grammar_replay")
	check(session.state == "question" and session.current == 0 and session.points == 0, "Replay starts a new class where the player stands")
	# Leave by the card: Yes ends the class and the classroom is normal again.
	session.ask_leave()
	check(session.state == "paused", "the leave button asks first")
	game.shop_panel.quit_answered.emit(true)
	check(session.state == "" and not session.activity_running(), "Yes ends the class")
	var cleared: bool = session.board_label.text == "" and green_desks().is_empty()
	for letter in session.desks:
		cleared = cleared and session.desks[letter].label.text == ""
	check(cleared and not game.grammar_card.visible, "board, desks and card cleared")
	check(not game.shop_panel.compact, "after class the dialogue box is the normal one again")
	check(preload("res://scripts/learning/activity_board.gd").shared().blocker("flight_bruno") == "", "other minigames are free again")
	# Exploration: the doorway no longer asks, the chairs still seat the player.
	game.player.set_physics_process(false)
	game.player.global_position = school.to_global(School.DOORWAY)
	for i in 4:
		await physics_frame
	check(not game.shop_panel.is_quit_open(), "after class the doorway does not ask")
	check(await sit("B"), "after class the answer chairs are ordinary seats")
	await stand()
	finish()

func finish() -> void:
	print("GRAMMAR CLASS: %d checks, %d failures" % [checks, failures])
	if game != null:
		game.free()
	quit(1 if failures > 0 else 0)
