extends SceneTree
## 6 Nov 2026: the enlarged police station (20 x 22, front fixed) and its two detective
## minigames (docs/evidence/police-detective-20261106/PROMPT.md). Loads Main, checks the shell, rooms,
## officers, doors, anchors and posters, then plays both games through their session API:
## wrong and right guesses, the evidence tools, find and report rounds and their practice
## records (evidence game redesigned 8 Nov 2026), Next / Finish, leaving early.
## Main writes study progress: run with the README's isolated user directory.
## godot --headless --path . --script res://docs/evidence/police-detective-20261106/verify.gd
const Interior := preload("res://scripts/buildings/police.gd")
const Clues := preload("res://scripts/learning/detective_clues.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func box_clear(space: PhysicsDirectSpaceState3D, xform: Transform3D, size: Vector3, own: Node = null) -> bool:
	var box := BoxShape3D.new()
	box.size = size
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = xform
	if own != null:
		var rids: Array[RID] = []
		for body in own.find_children("*", "CollisionObject3D", true, false):
			rids.append(body.get_rid())
		query.exclude = rids
	var hits := space.intersect_shape(query, 4)
	for hit in hits:
		var collider: Object = hit.collider
		print("  hit: ", collider.get_path() if collider is Node else collider)
	return hits.is_empty()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var town: Node3D = game.apartment
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var station: Node3D = town.get_node("RelocatedSites/Police")
	# --- Shell -------------------------------------------------------------------------
	check(station.get_meta("approved_dimensions", Vector3.ZERO) == Vector3(20, 5.8, 22), "approved dimensions 20 x 5.8 x 22")
	check(station.position.is_equal_approx(Vector3(-101.5, 0, 37)), "station position unchanged")
	var left: Node3D = station.get_node("Police Station left wall")
	var back: Node3D = station.get_node("Police Station back wall")
	check(is_equal_approx(left.position.x, 33.0) and is_equal_approx(back.position.z, 59.5), "shell walls at x 33 / z 59.5")
	var pier: Node3D = station.get_node("Police Station front pier")
	check(is_equal_approx(pier.position.z, 37.5), "facade stays at z 37.5")
	# Front corridor: straight out of the door stays free.
	var door := station.to_global(Vector3(43, 0, 35.0))
	check(box_clear(space, Transform3D(station.global_basis.orthonormalized(), door + Vector3(0, 1.0, 0)), Vector3(2.4, 1.6, 3.0)), "door approach lane is clear")
	var inside := station.to_global(Vector3(43, 0, 40.5))
	check(box_clear(space, Transform3D(station.global_basis.orthonormalized(), inside + Vector3(0, 1.0, 0)), Vector3(2.0, 1.4, 2.5)), "lobby inside the door is clear")
	var car: Node3D = town.get_node_or_null("Vehicles/Police_Car")
	check(car != null and station.to_local(car.global_position).z < 37.5, "police car stays in front of the facade")
	# --- Rooms, doors, anchors -----------------------------------------------------------
	check(station.has_node("Interior") and station.get_meta("venue", "") == "police", "interior built")
	for title in ["LineupStage", "LineupCamera", "EvidenceTable", "EvidenceCamera"]:
		check(station.has_node("Interior/" + title), "anchor " + title)
	for title in ["Interview room", "Holding cell"]:
		var node: Node3D = station.get_node_or_null(title)
		var registered: bool = node != null and game.doors.has(node)
		check(registered, "working door kept: " + title)
		if registered:
			check((game.doors[node]["origin"] as Vector3).is_equal_approx(node.position), "door origin follows the door: " + title)
	var posters := 0
	for node in station.get_node("Interior").get_children():
		if String(node.name).begins_with("Police poster"):
			posters += 1
	check(posters == 2, "two teaching posters (%d)" % posters)
	var poster_words: Array = station.get_node("Interior/Police poster evidence").get_children().filter(func(n): return n.has_meta("word_key")).map(func(n): return str(n.get_meta("word_key")))
	poster_words.sort()
	check(poster_words == ["hard", "heavy", "light (weight)", "rough", "smooth", "soft", "to lift", "to squeeze", "to touch"], "evidence poster shows the three tools and their six words (%s)" % [poster_words])
	var exhibits := station.get_node("Interior").get_children().filter(func(n): return String(n.name).begins_with("Evidence ") and n.has_meta("word_key"))
	check(exhibits.size() == 10, "ten labelled evidence exhibits (%d)" % exhibits.size())
	# Since 8 Nov 2026 (second pass) the shelves show exactly the game's objects.
	var shelf_words: Array = exhibits.map(func(n): return str(n.get_meta("word_key")))
	var game_words: Array = (Clues.new().data.evidence.objects as Dictionary).values().map(func(o): return str(o.word))
	shelf_words.sort()
	game_words.sort()
	check(shelf_words == game_words, "the shelf exhibits are the game's objects (%s)" % [shelf_words])
	# Standing room in front of the lineup rail and at the evidence counter.
	for design in [Vector3(48.5, 0, 53.4), Vector3(41.0, 0, 43.5), Vector3(44.0, 0, 48.5)]:
		var spot: Vector3 = Interior.mirror_point(design)
		check(box_clear(space, Transform3D(station.global_basis.orthonormalized(), station.to_global(spot) + Vector3(0, 1.0, 0)), Vector3(.7, 1.2, .7)), "walkable: %s" % spot)
	# Seen from the door, as approved: evidence room left, lineup room right.
	var eye := station.to_global(Vector3(43, 1.5, 38.4))
	var ahead := (station.to_global(Vector3(43, 1.5, 52)) - eye).normalized()
	var right_hand := ahead.cross(Vector3.UP)
	var table: Node3D = station.get_node("Interior/EvidenceTable")
	var stage: Node3D = station.get_node("Interior/LineupStage")
	check((table.global_position - eye).dot(right_hand) < 0.0, "evidence room on the left seen from the door")
	check((stage.global_position - eye).dot(right_hand) > 0.0, "lineup room on the right seen from the door")
	# --- Officers ------------------------------------------------------------------------
	var croc: Node3D = town.get_node_or_null("People/CrocodilePoliceOfficer")
	var cat: Node3D = town.get_node_or_null("People/CatEvidenceOfficer")
	check(croc != null and cat != null, "both officers exist")
	for pair in [[croc, Interior.LINEUP_OFFICER_SPOT, "crocodile"], [cat, Interior.EVIDENCE_OFFICER_SPOT, "cat"]]:
		var npc: Node3D = pair[0]
		if npc == null:
			continue
		var local := station.to_local(npc.global_position)
		var spot: Vector3 = Interior.mirror_point(pair[1])
		check(Vector2(local.x - spot.x, local.z - spot.z).length() < .05, pair[2] + " officer on its spot")
		check(local.x > Interior.LEFT and local.x < Interior.RIGHT and local.z > Interior.FRONT and local.z < Interior.REAR, pair[2] + " officer is inside")
		var costume: Node = npc.get_node_or_null("Costume")
		check(costume != null and String(costume.get("outfit")) == "police", pair[2] + " wears the police uniform")
		check(box_clear(space, Transform3D(npc.global_basis.orthonormalized(), npc.global_position + Vector3(0, .9, 0)), Vector3(.8, 1.0, .8), npc), pair[2] + " officer not inside a solid")
	# --- Sessions --------------------------------------------------------------------------
	var lineup = game.get_node_or_null("PoliceDetective_lineup")
	var evidence = game.get_node_or_null("PoliceDetective_evidence")
	check(lineup != null and lineup.officer == croc, "lineup session found Rocco")
	check(evidence != null and evidence.officer == cat, "evidence session found Mimi")
	var card = game.detective_card
	if lineup == null or evidence == null or lineup.officer == null or evidence.officer == null:
		finish()
		return
	# Lineup: four rounds, one wrong guess first.
	lineup.start_game()
	await process_frame
	check(card.visible and not game.player.controls_enabled, "card open, player locked")
	check(game.get_viewport().get_camera_3d() == lineup._camera, "fixed lineup camera is current")
	var activity_board = preload("res://scripts/learning/activity_board.gd").shared()
	check(activity_board.blocker("evidence_mimi") == "lineup_rocco", "the evidence game waits while the lineup runs")
	for r in 4:
		var rnd: Dictionary = lineup.round
		check(Clues.validate(rnd) == "", "lineup round %d valid" % (r + 1))
		check(lineup._nodes.size() == 5, "five suspects built")
		_check_suspects(lineup, rnd, r)
		var wrong := (int(rnd.target) + 1) % 5
		lineup.select(wrong)
		lineup.accuse()
		check(not lineup._solved and card.feedback_label.visible, "wrong suspect gives feedback (round %d)" % (r + 1))
		lineup.accuse()
		check(card.feedback_label.text == lineup.lexicon.line("police.choose_first_suspect").foreign, "accusing nobody asks to choose first")
		lineup.select(int(rnd.target))
		lineup.accuse()
		check(lineup._solved and card.next_button.visible and not card.accuse_button.visible, "right suspect solves round %d" % (r + 1))
		await create_timer(.5).timeout
		lineup.next_round()
		await process_frame
	await _check_summary(lineup, "lineup", card)
	check(not lineup.activity_running() and not card.visible, "lineup ends after four rounds")
	await create_timer(1.0).timeout
	check(game.player.controls_enabled, "player unlocked after the lineup")
	# Evidence (redesigned 8 Nov 2026): three tools that examine every object, find and report
	# rounds, the agreeing answer line, one practice record per round; then leave early.
	game.shop_panel.hide_dialogue()
	var records: Array = []
	var PracticeLog = preload("res://scripts/learning/practice_log.gd")
	var on_record := func(id: String, outcomes: Dictionary) -> void:
		if id == "evidence_mimi":
			records.append(outcomes)
	PracticeLog.shared().recorded.connect(on_record)
	evidence.offered = true
	evidence.start_game()
	await process_frame
	check(card.visible and card.tool_row.get_child_count() == 3, "evidence card has three tools")
	for r in 4:
		var rnd: Dictionary = evidence.round
		var clue: Dictionary = rnd.clues[0]
		check(Clues.validate(rnd) == "", "evidence round %d valid" % (r + 1))
		check(str(rnd.type) == evidence.clues.round_type(r), "evidence round %d is a %s round" % [r + 1, evidence.clues.round_type(r)])
		check(evidence._nodes.size() == rnd.candidates.size(), "objects on the table")
		var target := int(rnd.target)
		var word := str(rnd.candidates[target].word)
		# The round's tool examines every object and leaves the right result icon on each.
		evidence._on_tool(str(clue.tool))
		await create_timer(evidence.TOOL_STAGGER * rnd.candidates.size() + .4).timeout
		var badges_right := true
		for i in evidence._nodes.size():
			var badge: Node = evidence._nodes[i].get_node_or_null("Badge")
			badges_right = badges_right and badge != null and str(badge.get_meta("badge", "")) == str(rnd.candidates[i].get(str(clue.dim), ""))
		check(badges_right, "the %s tool shows every object's %s (round %d)" % [clue.tool, clue.dim, r + 1])
		if str(rnd.type) == "find":
			check(not card.choice_row.visible, "a find round has no answer buttons")
			var wrong: int = (target + 1) % rnd.candidates.size()
			evidence.choose(wrong)
			var told: String = str(card._feedback.get("foreign", ""))
			check(not evidence._solved and told.contains(evidence.lexicon.word(str(rnd.candidates[wrong].word), evidence.lexicon.foreign)), "a wrong object is told what it is (round %d): %s" % [r + 1, told])
			evidence.choose(target)
		else:
			check(card.choice_row.visible and card._choice_buttons.size() == 2 and evidence._nodes.size() == 1, "a report round shows one object and two answers")
			var right_index: int = 0 if str(rnd.options[0].id) == str(clue.id) else 1
			# The translate bubble also translates the buttons (user request 8 Nov 2026).
			card.toggle_translation()
			var tool_text: String = (card._tool_buttons[str(clue.tool)] as Button).text
			var choice_text: String = (card._choice_buttons[0] as Button).text
			check(tool_text.contains("\n") and choice_text.contains("\n"), "translation on: tool and answer buttons show their translation (%s | %s)" % [tool_text.replace("\n", " / "), choice_text.replace("\n", " / ")])
			card.toggle_translation()
			check(not (card._tool_buttons[str(clue.tool)] as Button).text.contains("\n"), "translation off: one line again")
			evidence._tool = ""
			evidence.answer(1 - right_index)
			check(not evidence._solved, "a wrong answer does not solve round %d" % (r + 1))
			await create_timer(.7).timeout
			check(evidence._tool == str(clue.tool), "a wrong answer uses the right tool by itself (round %d)" % (r + 1))
			evidence.answer(right_index)
		check(evidence._solved, "right answer solves round %d" % (r + 1))
		var said: String = str(card._feedback.get("foreign", ""))
		var agreed: String = evidence.lexicon.phrase(evidence._agreed(str(clue.phrase), word, evidence.lexicon.foreign), evidence.lexicon.foreign)
		check(said.contains(evidence.lexicon.word(word, evidence.lexicon.foreign)) and said.contains(agreed), "the solved line names the object and its property (round %d): %s" % [r + 1, said])
		await create_timer(.3).timeout
		evidence.next_round()
		await process_frame
	check(records.size() == 4 and records.all(func(o: Dictionary) -> bool: return o.size() == 1), "one practice record per evidence round, one word each (%s)" % [records])
	# The tracker is a static singleton that outlives this script: never leave it connected here.
	PracticeLog.shared().recorded.disconnect(on_record)
	await _check_summary(evidence, "evidence", card)
	check(not evidence.activity_running(), "evidence game ends after four rounds")
	await create_timer(1.0).timeout
	game.shop_panel.hide_dialogue()
	evidence.offered = true
	evidence.start_game()
	await process_frame
	card.leave_requested.emit()
	check(game.shop_panel.is_quit_open(), "leaving asks first")
	game.shop_panel.quit_answered.emit(true)
	await create_timer(1.0).timeout
	check(not evidence.activity_running() and not card.visible and evidence._nodes.is_empty(), "leaving ends the game and clears the table")
	finish()

## After the fourth round: the card lists one line per round (the suspect's number or the
## object, and the clue words) with Finish; Finish ends the game.
func _check_summary(session, label: String, card) -> void:
	var lines: Array = card._summary
	check(session.activity_running() and card.visible and card.summary_box.visible and lines.size() == 4 and session._nodes.is_empty(), "%s shows the word summary after four rounds" % label)
	var first: Dictionary = session._history[0] if not session._history.is_empty() else {}
	var said: String = session.lexicon.word(str(first.words[0]), session.lexicon.foreign) if not first.is_empty() else ""
	if label == "evidence" and not first.is_empty():
		# The evidence summary gives the adjective agreeing with the object (8 Nov 2026).
		said = session.lexicon.phrase(session._agreed(str(first.adjective), str(first.object), session.lexicon.foreign), session.lexicon.foreign)
	var named := not first.is_empty() and str(lines[0].get("foreign", "")).contains(said)
	if label == "lineup":
		named = named and str(lines[0].foreign).contains(str(first.number))
	check(named and card.next_button.visible and not card.accuse_button.visible, "%s summary names the round's words, Finish shown" % label)
	session.next_round()
	# Checked at once: this test's player stands far from the officer, so the next frame's
	# walk-away rule would close the question.
	check(session.host.line_id == str(session.spec.complete) and session.dialogue_panel.has_choices(), "%s ends by asking to play again (Yes / No)" % label)
	session.host._on_choice(session.host.choice_prefix() + "no")
	await process_frame

## Every built suspect shows the features its data says.
func _check_suspects(session, rnd: Dictionary, r: int) -> void:
	for i in session._nodes.size():
		var bear: Node3D = session._nodes[i]
		var s: Dictionary = rnd.candidates[i]
		var ok := true
		ok = ok and (bear.has_node("Beard") == (s.facial_hair == "beard"))
		ok = ok and (bear.has_node("Moustache") == (s.facial_hair == "moustache"))
		ok = ok and (bear.has_node("Hair") == (s.hair != "bald"))
		ok = ok and (bear.has_node("Hair back") == (s.hair == "long"))
		ok = ok and (bear.has_node("Eyelash") == (s.gender == "f"))
		ok = ok and bear.has_node("Costume")
		# Height scales mostly upward, so height / width tells tall, medium and short apart
		# whatever the station's own scale.
		var size: Vector3 = bear.global_basis.get_scale()
		var ratio: float = size.y / size.x
		ok = ok and ((ratio > 1.02) == (s.height == "tall")) and ((ratio < .98) == (s.height == "short"))
		var nose := bear.get_node_or_null("Head/Muzzle/Nose") as Node3D
		var nose_size: float = nose.transform.basis.get_scale().x if nose else 0.0
		ok = ok and ((nose_size > 1.6) == (s.nose == "big")) and ((nose_size < 1.1) == (s.nose == "small"))
		check(ok, "round %d suspect %d looks like its data" % [r + 1, i + 1])

func finish() -> void:
	print("POLICE DETECTIVE: ", failures, " failures; ", checks, " checks")
	quit(0 if failures == 0 else 1)
