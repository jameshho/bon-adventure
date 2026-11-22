extends Node
## The Grammar Classroom (guide: docs/guides/GRAMMAR_CLASS.md; user brief and decisions, 6 Nov 2026).
## Lana, the sheep teacher by the board in the school's general classroom (TeacherLana, saved in
## the school unit by scripts/buildings/school.gd), shows the gold "!" while the player is near
## and asks in the SHARED dialogue box whether they want to join grammar class. Yes fades the
## screen and puts the player in the aisle behind the answer desks of the REAL classroom (no
## copy); the class card (grammar_card.gd) opens.
##
## Each class is 5 questions (14 Nov 2026; was 10) from the bank of the language being learned
## (grammar_questions.gd, data/grammar_class/<code>.json), never repeated within a class, except
## for the review: every question answered wrong (or not at all) comes back once more at the end
## (user decisions 8 and 14 Nov 2026; the old "only in classes of more than 5" limit is gone).
## The class grows by one ("Question 3 of 6") and a toast says so; a review that is wrong again
## does not come back a third time, so a class of 5 has at most 10 questions. A review comes
## straight after itself only when the last question of the class was the miss. A
## question is written on the board; its four answers, shuffled, lie on the four front desks.
## The player sits at a desk (E, the shared seating controller) and may stand and switch
## freely. The card's on-screen Confirm button (enabled only at an answer desk, one press)
## submits at once; otherwise the answer is taken when the 10 seconds run out. The answer is
## the desk whose chair the player sits on at that instant; standing anywhere else is
## unanswered (no point). Feedback lasts 2 seconds after a right answer; after a miss it stays
## until Continue (the Confirm button, relabelled) or 10 seconds (9 Nov 2026). Neither is taken
## from the next countdown:
## the right desk turns green, the card shows ✓ / ✗, the right sentence and a short
## explanation in the player's language. Meanwhile the game stands the player up and walks
## them back to the start in the aisle (user decision, 8 Nov 2026, replacing "the player is
## never moved"), so every question is a fair race from the same spot; the next question
## starts when both the feedback and the walk are over. A large countdown in the middle of the
## screen with a short hint runs while a question is open (grammar_card.gd). After the last
## question Lana gives the points and offers Replay or Finish.
##
## Leaving: walking out through the school entrance (an Area3D in the doorway, only while a
## class runs), the card's leave button or Esc pauses the countdown and asks "Are you finished
## with class?" (the dialogue panel's quit card). Yes ends the class; No puts the player just
## inside the entrance and resumes the question with the time it had left. A language change
## ends the class at once. No coins or rewards (user decision, 6 Nov 2026); points only.
##
## Every text comes from data/phrases.json group "grammar" through the Lexicon; offers follow
## the shared activity board ("grammar_lana" in data/activities.json).
const Board := preload("res://scripts/learning/activity_board.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const Questions := preload("res://scripts/learning/grammar_questions.gd")
const School := preload("res://scripts/buildings/school.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const PINYIN_FONT := preload("res://fonts/NotoSans-SemiBold.ttf")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const ACTIVITY := "grammar_lana"
const ANSWER_SECONDS := 10.0
const FEEDBACK_SECONDS := 2.0
## After a wrong or missed answer the explanation stays up until the player presses Continue
## (the card's Confirm button, relabelled) or this many seconds pass (user, 9 Nov 2026).
const MISS_FEEDBACK_SECONDS := 10.0
## The walk back to School.START after each answer: behind the chair, along the aisle, to the
## start. If BonBon cannot stand up, stops making progress or takes too long, she is placed there.
const BEHIND_CHAIR := 0.75
const WALK_STUCK_SECONDS := 0.8
const WALK_MAX_SECONDS := 6.0
const CALL_DISTANCE := 16.0
const WALK_AWAY_DISTANCE := 9.0
const MESSAGE_SECONDS := 7.0
const DESK_GREEN := Color("49b86a")
## Board text: a deep navy ink (darker than the 6 Nov "1d3557", 14 Nov 2026) at 144 px (sentence)
## and 96 px (pinyin), half as large again as before, for reading from the back desks.
const BOARD_INK := Color("0f1e3a")
const BOARD_FONT := 144
const BOARD_READING_FONT := 96
## The text on the board stays inside this share of the board's height; a long sentence (and its
## pinyin) is set smaller, down to BOARD_MIN_FONT, rather than run off the board.
const BOARD_TEXT_HEIGHT := 0.86
const BOARD_MIN_FONT := 72
const DESK_INK := Color("2b1d10")

var lexicon
var dialogue_panel
var card
var interaction
var player: Node3D
var world: Node3D
var main
var school: Node3D
var lana: Node3D
## The shared NPC host (minigame_host.gd: Lana, the "!", talking, the leave question) and
## in-world zone (minigame_zone.gd: fade, placing the player, the doorway).
var host
var zone
var presence:
	get: return host.presence if host != null else null
var bank := Questions.new()
## Whether Lana offers a class now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
var _rng := RandomNumberGenerator.new()
var _doorway: Area3D

## Desks and boards: letter -> {"desk": Node3D, "chair": Node3D, "top": MeshInstance3D, "glow",
## "label": Label3D}; the board's sentence and pinyin labels.
var desks: Dictionary = {}
var board: Node3D
var board_label: Label3D
var board_reading: Label3D

## The running class. state: "" (none), "question", "feedback", "paused", "over".
var state := ""
var _paused_from := ""
var questions: Array = []
var current := -1
var points := 0
var time_left := 0.0
## letter -> answer on that desk for the current question.
var on_desk: Dictionary = {}
var _submitted := false
## Feedback after a miss: waiting for Continue (or MISS_FEEDBACK_SECONDS).
var _holding := false
## The walk back to the start: "" (none), "standing" (waiting for the chair to let go),
## "walking" (player.auto_walk running).
var _walk := ""
var _walk_chair: Node3D
var _walk_time := 0.0
var _walk_check := Vector3.ZERO
var _walk_still := 0.0

func setup(shared_lexicon, shared_dialogue_panel, class_card, interaction_controller, explorer: Node3D, town: Node3D, game) -> void:
	name = "GrammarSession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	card = class_card
	interaction = interaction_controller
	player = explorer
	world = town
	main = game
	_rng.randomize()
	school = ModularTown.building(town, "school", 1)
	lana = school.get_node_or_null(School.LANA) if school != null else null
	if lana == null:
		push_warning("grammar_session: no school unit (dev focus) or no " + School.LANA)
		return
	for node in school.find_children("*", "Node3D", true, false):
		if node.has_meta("grammar_desk"):
			var letter := str(node.get_meta("grammar_desk"))
			desks[letter] = desks.get(letter, {})
			desks[letter]["desk"] = node
		if node.has_meta("grammar_seat"):
			var letter := str(node.get_meta("grammar_seat"))
			desks[letter] = desks.get(letter, {})
			desks[letter]["chair"] = node
		if node.has_meta("grammar_board"):
			board = node
	if desks.size() != School.ANSWER_DESKS.size() or board == null:
		push_warning("grammar_session: the school has no grammar desks or board (bake the school step)")
		return
	_build_labels()
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "grammar", "speaker": "grammar.lana", "play": "grammar.join", "call_distance": CALL_DISTANCE, "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS}, lexicon, dialogue_panel, interaction, player, lana)
	host.play_chosen.connect(start_class)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	zone = Zone.new()
	add_child(zone)
	zone.setup(player, main, "GrammarFade")
	_doorway = zone.make_doorway(school, School.DOORWAY, School.DOORWAY_SIZE, "Grammar class doorway", func() -> void:
		if state in ["question", "feedback"]:
			ask_leave())
	card.leave_requested.connect(ask_leave)
	card.confirm_pressed.connect(confirm)

func activity_running() -> bool:
	return state != ""

func in_class() -> bool:
	return state != ""

## For the host: Lana can be talked to during a class (keep going, the final score), so only
## a running fade or her own open line make her busy.
func busy() -> bool:
	return (zone != null and zone.fading) or (host != null and host.line_id != "")

# --- World labels: the board and the four desk tops ---------------------------------------

## Labels are built at runtime (not saved in the school scene): a sentence and a pinyin line on
## the board, and one answer lying flat on each answer desk, read from its chair.
func _build_labels() -> void:
	var size: Vector3 = board.get_meta("grammar_board")
	board_label = _label3d("Board sentence", BOARD_FONT, BOARD_INK)
	# Long sentences wrap within the board (two lines fit above the pinyin line).
	board_label.width = size.x * 0.92 / board_label.pixel_size
	board_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board.add_child(board_label)
	# The board's front faces the class (board-local -Z).
	board_label.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, size.y * 0.12, -size.z * 0.5 - 0.01))
	board_reading = _label3d("Board reading", BOARD_READING_FONT, BOARD_INK.lightened(0.15))
	board_reading.font = PINYIN_FONT
	board_reading.width = size.x * 0.94 / board_reading.pixel_size
	board_reading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board.add_child(board_reading)
	board_reading.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, -size.y * 0.28, -size.z * 0.5 - 0.01))
	for letter in desks:
		var entry: Dictionary = desks[letter]
		var top := _desk_top(entry.desk)
		entry["top"] = top
		var label := _label3d("Answer " + letter, 96, DESK_INK)
		school.add_child(label)
		var bounds := _school_bounds(top)
		var chair_side: Vector3 = school.to_local(entry.chair.global_position) - school.to_local(entry.desk.global_position)
		chair_side.y = 0
		var toward := -chair_side.normalized()
		# Lies on the top; its "up" points away from the chair, so it reads from the seat.
		var side := Vector3.UP.cross(toward).normalized()
		label.transform = Transform3D(Basis(-side, toward, Vector3.UP), Vector3(bounds.get_center().x, bounds.end.y + 0.012, bounds.get_center().z))
		label.set_meta("grammar_top_size", Vector2(bounds.size.x, bounds.size.z))
		entry["label"] = label
		entry["glow"] = _make_glow(letter, bounds)
	_clear_world()

func _label3d(title: String, font_size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = title
	label.font_size = font_size
	label.pixel_size = 0.0045
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.shaded = false
	# A flat label would shade the whole desk top (and hide the green) with its quad's shadow.
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _desk_top(desk: Node3D) -> MeshInstance3D:
	# The desk prop's top is "Top_6"; otherwise its broadest mesh.
	var best: MeshInstance3D = null
	var area := -1.0
	for mesh in desk.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		if str(mesh.name).begins_with("Top"):
			return mesh
		var box := _school_bounds(mesh)
		if box.size.x * box.size.z > area:
			best = mesh
			area = box.size.x * box.size.z
	return best

func _school_bounds(mesh: MeshInstance3D) -> AABB:
	var to_school: Transform3D = school.global_transform.affine_inverse() * mesh.global_transform
	return to_school * mesh.get_aabb()

## Fits an answer inside its desk top: the longest answer still reads at the size of a short one.
func _set_answer(letter: String, text: String) -> void:
	var label: Label3D = desks[letter].label
	var top: Vector2 = label.get_meta("grammar_top_size")
	label.text = text
	var em := float(label.font_size)
	var wide := 0.0
	for c in text:
		wide += 1.0 if c.unicode_at(0) > 0x2E80 else 0.58
	var by_width := (top.x * 0.86) / maxf(wide * em, 1.0)
	var by_height := (top.y * 0.62) / em
	label.pixel_size = minf(by_width, by_height)

func _clear_world() -> void:
	board_label.text = ""
	board_reading.text = ""
	for letter in desks:
		desks[letter].label.text = ""
		_highlight(letter, false)

## The green "right answer" plate: a thin runtime box just above the desk top, under its label.
## (The top itself is usually merged into a static batch by render_culling.gd and hidden, and
## its material is shared town-wide, so neither is touched.)
func _make_glow(letter: String, bounds: AABB) -> MeshInstance3D:
	var green := StandardMaterial3D.new()
	green.albedo_color = DESK_GREEN
	green.emission_enabled = true
	green.emission = DESK_GREEN * 0.35
	var box := BoxMesh.new()
	box.size = Vector3(bounds.size.x, 0.006, bounds.size.z)
	box.material = green
	var glow := MeshInstance3D.new()
	glow.name = "Answer glow " + letter
	glow.mesh = box
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	school.add_child(glow)
	glow.position = Vector3(bounds.get_center().x, bounds.end.y + 0.004, bounds.get_center().z)
	glow.visible = false
	return glow

func _highlight(letter: String, on: bool) -> void:
	var glow: MeshInstance3D = desks[letter].get("glow")
	if glow != null:
		glow.visible = on

# --- Dialogue box -----------------------------------------------------------------------

func _say(id: String, choices: Array = [], auto_close: float = MESSAGE_SECONDS, values: Dictionary = {}) -> void:
	host.say(id, choices, auto_close, values)

## The host asks first when the player talks to Lana: during a class she encourages or offers
## Replay; without a question bank for the language there is no class.
func _host_talk(_talker: Node3D) -> bool:
	if in_class():
		if state == "over":
			_offer_again()
		else:
			_say("grammar.keep_going")
		return true
	if host.gate():
		return true
	if not Questions.has_bank(lexicon.foreign):
		_say("grammar.no_class")
		return true
	return false

## Replay and Finish on the final score (Join and Not now are the host's).
func _on_choice(id: String) -> void:
	match id:
		"grammar_replay":
			_close_dialogue()
			_begin_questions()
		"grammar_finish":
			_close_dialogue()
			end_class("grammar.finished")

## Closing the final score without choosing is Finish.
func _on_talk_closed(was: String) -> void:
	if was == "grammar.final" and state == "over":
		end_class("")

func _close_dialogue() -> void:
	host.close_dialogue()

# --- Starting, questions and ending --------------------------------------------------------

func start_class() -> void:
	if in_class() or zone.fading:
		return
	if not bank.load_bank(lexicon.foreign):
		_say("grammar.no_class")
		return
	await zone.fade_through(func() -> void:
		zone.place_player(school, School.START, School.START_LOOK)
		Board.shared().begin(ACTIVITY)
		state = "over"
		# A smaller dialogue box at the bottom keeps the board and desks in view (user, 7 Nov 2026).
		dialogue_panel.set_compact(true))
	dialogue_panel.toast(lexicon.line("grammar.intro"), 5.0)
	_begin_questions()

## A new class of 5 questions where the player stands (start and Replay).
func _begin_questions() -> void:
	# 5 a class (data/activities.json "grammar_lana"; the test launcher may choose another number).
	# Own copies: a class marks its misses ("missed") without touching the bank.
	questions = bank.pick(Board.shared().rounds(ACTIVITY), _rng).map(func(q: Dictionary) -> Dictionary: return q.duplicate())
	points = 0
	current = -1
	card.show_native = dialogue_panel.show_native
	card.open(_title(), lexicon.line("grammar.confirm"), lexicon.line("common.show_translation"), 0, questions.size())
	_next_question()

func _title() -> Dictionary:
	return lexicon.line("grammar.question_title", {"n": maxi(current + 1, 1), "total": questions.size()})

## Practice tracking (practice_log.gd): only questions with a "noun" (Chinese measure words)
## test one word (decision 6); the submitted desk is the answer and completes the question
## (an unanswered question records nothing, unless the translation was shown).
func _practice_begin(question: Dictionary) -> void:
	if str(question.get("noun", "")) != "":
		PracticeLog.shared().begin(ACTIVITY, [str(question.noun)])
	elif PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().abandon()

func _next_question() -> void:
	for letter in desks:
		_highlight(letter, false)
	current += 1
	if current >= questions.size():
		_finish_questions()
		return
	var question: Dictionary = questions[current]
	var answers: Array = Questions.desk_answers(question, _rng)
	on_desk = {}
	var letters: Array = School.ANSWER_DESKS
	for i in letters.size():
		on_desk[letters[i]] = answers[i]
		_set_answer(letters[i], str(answers[i]))
	_practice_begin(question)
	_show_board(Questions.blanked(question))
	time_left = ANSWER_SECONDS
	_submitted = false
	state = "question"
	card.set_round(_title(), points, questions.size())
	_show_countdown()

func _show_board(text: String) -> void:
	board_label.text = text
	board_reading.text = lexicon.reading(text.replace("＿＿＿", " "), lexicon.foreign)
	_fit_board()

## Sets the board's sentence (wrapped to the board's width) and its pinyin line as large as
## they fit, from BOARD_FONT / BOARD_READING_FONT down, and stacks them, centred a little above
## the board's middle (14 Nov 2026).
func _fit_board() -> void:
	var size: Vector3 = board.get_meta("grammar_board")
	var room := size.y * BOARD_TEXT_HEIGHT
	var font_size := BOARD_FONT
	var heights := Vector2.ZERO
	while true:
		board_label.font_size = font_size
		board_reading.font_size = roundi(font_size * float(BOARD_READING_FONT) / BOARD_FONT)
		heights = Vector2(_text_height(board_label), _text_height(board_reading))
		if heights.x + heights.y <= room or font_size <= BOARD_MIN_FONT:
			break
		font_size = maxi(font_size - 8, BOARD_MIN_FONT)
	var top := (heights.x + heights.y) * 0.5 + size.y * 0.04
	var front := -size.z * 0.5 - 0.01
	board_label.position = Vector3(0, top - heights.x * 0.5, front)
	board_reading.position = Vector3(0, top - heights.x - heights.y * 0.5, front)

## Height in metres of a board label's wrapped text (0 when empty).
func _text_height(label: Label3D) -> float:
	if label.text == "":
		return 0.0
	var font: Font = label.font if label.font != null else ThemeDB.fallback_font
	return font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, label.width, label.font_size).y * label.pixel_size

## The answer desk whose chair the player sits on now, or "".
func seated_letter() -> String:
	if not player.seated or main.seating == null or main.seating.current.is_empty():
		return ""
	var seat_node: Node = main.seating.current.get("node")
	for letter in desks:
		if seat_node == desks[letter].chair:
			return letter
	return ""

func _show_countdown() -> void:
	var at_desk := seated_letter() != ""
	card.show_countdown(maxf(time_left, 0.0), lexicon.line("grammar.seated" if at_desk else "grammar.hurry"), at_desk and not _submitted)

## The card's Confirm button: submits the desk the player sits at, once.
func confirm() -> void:
	if state == "feedback" and _holding:
		# Continue after a miss: the next question starts as soon as the walk back is over.
		_holding = false
		time_left = 0.0
		card.set_confirm_enabled(false)
		return
	if state != "question" or _submitted or seated_letter() == "":
		return
	submit()

## Locks the answer of the seat the player occupies at this instant (none: unanswered).
func submit() -> void:
	if state != "question" or _submitted:
		return
	_submitted = true
	var question: Dictionary = questions[current]
	var letter := seated_letter()
	_start_walk_back(desks[letter].chair if letter != "" else _chair_near_player())
	var chosen: Variant = on_desk.get(letter, null) if letter != "" else null
	var right: bool = chosen != null and str(chosen) == str(question.answer)
	if right:
		points += 1
	if PracticeLog.shared().game_id() == ACTIVITY:
		if chosen != null:
			PracticeLog.shared().first_answer(right)
		PracticeLog.shared().complete()
	for desk in on_desk:
		if str(on_desk[desk]) == str(question.answer):
			_highlight(desk, true)
	_show_board(Questions.filled(question))
	var status := "grammar.right" if right else ("grammar.no_answer" if chosen == null else "grammar.wrong")
	var sentence := {"foreign": Questions.filled(question), "native": str(question.get("meaning", {}).get(lexicon.native, ""))}
	if not right:
		question["missed"] = true
		_queue_review(question)
	card.set_round(_title(), points, questions.size())
	_holding = not right
	card.show_feedback(lexicon.line(status), right, sentence, str(question.get("explain", {}).get(lexicon.native, "")), {} if right else lexicon.line("grammar.continue"))
	state = "feedback"
	time_left = FEEDBACK_SECONDS if right else MISS_FEEDBACK_SECONDS

## Every missed question comes back once at the end of the class (marked "review": true so it
## is not queued again; 14 Nov 2026). The class therefore has at most twice its questions.
func _queue_review(question: Dictionary) -> void:
	if question.get("review", false):
		return
	var again := question.duplicate()
	again.erase("missed")
	again["review"] = true
	questions.append(again)
	dialogue_panel.toast(lexicon.line("grammar.review_later"), 3.0)

func _finish_questions() -> void:
	state = "over"
	# Every question answered: the session is complete (missions, achievements, the results
	# screen when the class ends; 21 Nov 2026: before this Desk Dash never completed).
	Board.shared().complete(ACTIVITY)
	_clear_world()
	card.hide_card()
	_offer_again()

func _offer_again() -> void:
	host.zoom(true)
	_say("grammar.final", [host.choice("replay", "grammar.replay", "retry"), host.choice("finish", "grammar.finish", "check")], 0.0, {"points": points, "total": questions.size()})

## Ends the class (Finish, leaving, a language change): the classroom is normal again. The
## player stays where they are.
func end_class(farewell: String) -> void:
	if not in_class():
		return
	host.cancel_leave()
	state = ""
	host.abandon_practice()
	dialogue_panel.set_compact(false)
	questions = []
	current = -1
	on_desk = {}
	_stop_walk()
	_clear_world()
	card.hide_card()
	offered = false
	if not zone.fading:
		main.sync_player_controls()
	if farewell != "":
		_say(farewell)

## A language change in Settings ends the class at once.
func end_activity() -> void:
	if host == null:
		return
	if host.line_id != "":
		_close_dialogue()
	end_class("")
	host.refresh_name()

# --- Leaving -----------------------------------------------------------------------------------

## The leave button, Esc or the doorway: pause and ask (the shared quit card).
func ask_leave() -> void:
	if not in_class() or zone.fading or host.is_asking_leave():
		return
	if state == "over":
		end_class("grammar.finished")
		return
	_paused_from = state
	state = "paused"
	player.auto_walk.clear()
	player.set_controls_enabled(false)
	host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if leave:
		state = _paused_from
		end_class("grammar.left_early")
		main.sync_player_controls()
		return
	# Stay: back inside the entrance if the doorway asked, then carry on with the time left.
	if _doorway.overlaps_body(player) or _outside_school():
		zone.place_player(school, School.INSIDE, School.INSIDE_LOOK)
	state = _paused_from
	main.sync_player_controls()
	if _walk != "":
		# The leave question interrupted the walk back: carry on from where BonBon stands.
		_start_walk_back(_walk_chair)

func _outside_school() -> bool:
	var p: Vector3 = school.to_local(player.global_position)
	return p.z < School.DOOR_Z

# --- Each frame: the "!", walking away, the countdown and the feedback --------------------------

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(player):
		return
	match state:
		"question":
			time_left -= delta
			if time_left <= 0.0:
				submit()
			else:
				_show_countdown()
		"feedback":
			time_left -= delta
			_walk_tick(delta)
			if time_left <= 0.0 and _walk == "":
				_next_question()
	host.tick(delta)

# --- The walk back to the start after each answer ---------------------------------------------

## Stands the player up (if seated) and walks them to School.START: behind `chair` (the desk
## they answered at, or null), along the aisle, to the start. Controls stay locked meanwhile.
func _start_walk_back(chair: Node3D) -> void:
	_walk_chair = chair
	_walk_time = 0.0
	_walk_still = 0.0
	player.auto_walk.clear()
	player.set_controls_enabled(false)
	if player.seated:
		main.seating.stand()
		if player.seated and not player.sit_transition:
			_place_at_start()
			return
		_walk = "standing"
		return
	_begin_walking()

## Standing next to an answer chair (not on it): that chair, so the walk goes round its desk.
func _chair_near_player() -> Node3D:
	for letter in desks:
		var chair: Node3D = desks[letter].chair
		if chair.global_position.distance_to(player.global_position) < 2.0:
			return chair
	return null

func _begin_walking() -> void:
	var start: Vector3 = School.START
	var route: Array[Vector3] = []
	if is_instance_valid(_walk_chair):
		var chair: Vector3 = school.to_local(_walk_chair.global_position)
		var here: Vector3 = school.to_local(player.global_position)
		# Stood up on the aisle side of the chair (the usual case): straight across to the aisle,
		# then along it. Only from the wall side does she first go round behind the chair; the
		# old route always did, which looked like a step the wrong way (user, 8 Nov 2026).
		var aisle_side := signf(here.x - chair.x) == signf(start.x - chair.x)
		var lane_z: float = here.z if aisle_side else chair.z - BEHIND_CHAIR
		if not aisle_side:
			route.append(Vector3(chair.x, 0, lane_z))
		if absf(here.x - start.x) > 0.3 or not aisle_side:
			route.append(Vector3(start.x, 0, lane_z))
	route.append(start)
	for point in route:
		player.auto_walk.append(school.to_global(point))
	_walk = "walking"
	_walk_check = player.global_position

func _walk_tick(delta: float) -> void:
	if _walk == "":
		return
	_walk_time += delta
	if player.controls_enabled:
		player.set_controls_enabled(false)
	if _walk == "standing":
		if not player.seated:
			_begin_walking()
		elif _walk_time > 1.5:
			_place_at_start()
		return
	if player.auto_walk.is_empty():
		_arrive()
		return
	# Stuck against a desk or a chair (or far too slow): place her at the start instead.
	_walk_still += delta
	if player.global_position.distance_to(_walk_check) > 0.15:
		_walk_check = player.global_position
		_walk_still = 0.0
	if _walk_still > WALK_STUCK_SECONDS or _walk_time > WALK_MAX_SECONDS:
		_place_at_start()

## At the start: face the board (the camera turns with her) and give the controls back.
func _arrive() -> void:
	var forward: Vector3 = school.global_basis * School.START_LOOK
	var yaw := atan2(-forward.x, -forward.z)
	player.rotation.y = yaw
	player.camera_yaw = yaw
	_stop_walk()

func _place_at_start() -> void:
	player.auto_walk.clear()
	zone.place_player(school, School.START, School.START_LOOK)
	_stop_walk()

func _stop_walk() -> void:
	var was := _walk
	_walk = ""
	_walk_chair = null
	player.auto_walk.clear()
	if was != "" and state != "paused" and not zone.fading:
		main.sync_player_controls()

## Walking away closes a question box; during a class (the final score) only leaving the
## school does, since the back desks are about WALK_AWAY_DISTANCE from Lana.
func _host_walked_away(distance: float) -> bool:
	return _outside_school() if in_class() else distance > WALK_AWAY_DISTANCE
