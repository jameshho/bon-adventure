extends Node
## The airport flight game: Captain Bruno (the bear plush in the pilot outfit at the
## terminal's information desk, PilotBruno, saved in the airport unit; first placed by the deleted airport_interior.gd) shows the gold
## "!" while the player is near, greets them in the SHARED dialogue box
## (shop_order_panel.gd) and opens the flight panel (flight_panel.gd). Five instructions
## per session (data/activities.json "flight_bruno"); each names one flight of a fictional
## schedule (flight_schedule.gd) that the player finds on the departure board (board only
## since the redesign of 7 Nov 2026; since 8 Nov 2026 a new board is built for each question,
## flight_questions.gd design()). Questions come from flight_questions.gd; text from the
## Lexicon (data/phrases.json group "flight"). No word is studied and no coins are paid.
##
## Flow: E / click Bruno -> greeting (+ "yes" / "not now") -> panel. Tap a flight: right
## shows ✓ and "Another flight"; wrong shows ✗, "try again" and "What went wrong?" (the
## country, or that flight's value of the tested time expression). Only flights found on the first tap count
## (user decision, 5 Nov 2026). At the target the panel lists first the questions missed on
## the first tap ("Para repasar": the expression -> the right flight's day and time as the
## board showed them; user decision, 8 Nov 2026), then the other words practised; Finish
## closes it and Bruno asks whether to play again (user decision, 8 Nov 2026): yes starts a
## new board at 0/5, no gets his goodbye. ✕ / Exit / Esc during the game asks before leaving
## (the dialogue panel's quit card); leaving ends the session without completion.
##
## Revised 8 Nov 2026 (user decisions): a Sunday-first calendar with today marked and a
## digital clock (today's weekday and the 12-hour time; the calendar has no day names, so the
## player works out other weekdays from today's) replace the "today / now" line; departures and arrivals are two tabs, Salidas and Llegadas (the
## player picks the tab; each game starts on Salidas); board times are
## 12-hour with a.m. / p.m. in every language. The board has ONE day column: the weekday
## word, or for weekday questions (el miércoles) the month/day date instead, so the weekday
## in the question never appears on the board and the calendar maps it to a date.
##
## Outside the game, the 3D flight board and the schedule booklet prop on the desk (meta
## "flight_info") are interactables: E, a click or a tap opens the same board for browsing.
const Board := preload("res://scripts/learning/activity_board.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
const GameClock := preload("res://scripts/learning/game_clock.gd")
const Schedule := preload("res://scripts/learning/flight_schedule.gd")
const Questions := preload("res://scripts/learning/flight_questions.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const NPC := "PilotBruno"
const ACTIVITY := "flight_bruno"
const CALL_DISTANCE := 22.0
const WALK_AWAY_DISTANCE := 12.0
const MESSAGE_SECONDS := 9.0
const WEEKDAYS := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
## Practice tracking (practice_log.gd, redesign of 7 Nov 2026): a question tests its time
## expression's word key (flight_questions.gd time_key(); none for hace / dentro de 2–3 horas)
## and, when it names a destination, that country. On the first tap the time word is right
## when the tapped flight fits the time expression (time_right()), the country when it goes
## to that country; the right flight completes the question. Since 8 Nov 2026 (user decision)
## day, part and clock questions about a day other than today also test that day's WEEKDAY
## (the board shows weekdays, so ayer means finding miércoles): right when the tapped flight
## leaves on the target's day. A question without a country on a board with arrivals and
## departures (flight_questions.gd: only when the verb decides) also tests the verb, "to
## arrive" / "to depart": right when the tapped flight goes the asked way.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
## Board columns: one day column, the weekday word (col_day) or, for weekday questions, the
## date (col_date), since the weekday word would be the answer.
const COLUMNS := ["col_flight", "col_destination", "col_day", "col_time"]
## Question kinds that also track the target day's weekday (when it is not today).
const WEEKDAY_TRACKED := ["day", "part", "clock"]

var lexicon
var dialogue_panel
var panel
var interaction
var player: Node3D
var bruno: Node3D
## The shared NPC host (minigame_host.gd): Bruno, the "!", talking, leaving.
var host
var presence:
	get: return host.presence if host != null else null
## Whether Bruno offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
var schedule
var questions
var question: Dictionary = {}
var quiz := false
var _practised: Array = []
## Questions missed on the first tap this session: [{"ref" (the time expression), "line"}].
var _missed: Array = []
var _last_kind := ""
var _wrong_flight := ""
## The last session reached its target (Finish then asks to play again).
var _completed := false
var _rng := RandomNumberGenerator.new()

func setup(shared_lexicon, shared_dialogue_panel, flight_panel, interaction_controller, explorer: Node3D, world: Node3D) -> void:
	name = "FlightSession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	panel = flight_panel
	interaction = interaction_controller
	player = explorer
	_rng.randomize()
	panel.flight_pressed.connect(_on_flight)
	panel.why_pressed.connect(_on_why)
	panel.next_pressed.connect(next_question)
	panel.finish_pressed.connect(_on_finish)
	panel.close_requested.connect(_on_close)
	bruno = world.find_child(NPC, true, false) as Node3D
	if bruno == null:
		push_warning("flight_session: no '%s' node" % NPC)
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "flight", "speaker": "flight.bruno", "call_distance": CALL_DISTANCE, "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS}, lexicon, dialogue_panel, interaction, player, bruno)
	host.play_chosen.connect(open_game)
	host.leave_answered.connect(_on_leave_answered)
	var airport: Node = preload("res://scripts/world/modular_town.gd").building(world, "airport")
	for node in (airport.find_children("*", "Node3D", true, false) if airport != null else []):
		if node.has_meta("flight_info"):
			Interactable.attach(node, {
				"prompt_distance": 3.5,
				"badge_offset": InteractIcons.local_center(node),
				"on_check": func() -> Variant: return not busy(),
				"on_use": browse,
			})

## For the activity board: a game is in progress.
func activity_running() -> bool:
	return quiz and panel.visible

func busy() -> bool:
	return (host != null and host.owns_dialogue()) or panel.visible

func _show(id: String) -> void:
	host.say(id)

# --- Browsing (E on the board or the booklet prop) ---------------------------------------

## The flight board's and the booklet's interactable use: the board for browsing, no question.
func browse() -> bool:
	if busy() or not player.controls_enabled:
		return false
	interaction.clear_card()
	if schedule == null or schedule.flights.is_empty():
		# Browsing outside the game: a board built for a random question (not asked).
		_new_schedule()
		questions.design(Questions.pick_kind(_rng), _rng)
	quiz = false
	question = {}
	panel.show_native = dialogue_panel.show_native
	panel.open(_panel_data())
	return true

# --- Game --------------------------------------------------------------------------------

func _new_schedule() -> void:
	schedule = Schedule.new()
	schedule.setup(GameClock.shared(), _rng)
	questions = Questions.new(schedule, lexicon)

func open_game() -> void:
	interaction.clear_card()
	_new_schedule()
	quiz = true
	_completed = false
	_practised.clear()
	_missed.clear()
	_last_kind = ""
	panel.show_native = dialogue_panel.show_native
	panel.tab = "dep"
	Board.shared().begin(ACTIVITY)
	panel.set_progress(0, Board.shared().target(ACTIVITY))
	next_question()

## A new question with a new board built for it (flight_questions.gd design(); question-first
## since 8 Nov 2026), of a kind other than the last one.
func next_question() -> void:
	if not quiz:
		return
	# A board whose tested words are due or may be new is preferred (word_memory.gd,
	# 24 Nov 2026). Each try builds a new board, so the last one made is the one shown.
	var make := func() -> Dictionary:
		for attempt in 10:
			var kind := Questions.pick_kind(_rng, _last_kind)
			_new_schedule()
			var made: Dictionary = questions.design(kind, _rng)
			if not made.is_empty():
				_last_kind = kind
				return made
		return {}
	var picked: Variant = preload("res://scripts/learning/word_memory.gd").shared().pick_round(make, func(made: Dictionary) -> Array: return _tested(made).keys())
	question = picked if picked is Dictionary else {}
	if question.is_empty():
		push_error("flight_session: no board could be built for a question")
		return
	_wrong_flight = ""
	var keys := _tested(question).keys()
	if not keys.is_empty():
		PracticeLog.shared().begin(ACTIVITY, keys)
	else:
		_practice_abandon()
	panel.open(_panel_data())

## The tested word keys of `q` -> whether a tap on `flight` got each right ({} without a
## flight: every value false).
func _tested(q: Dictionary, flight: Dictionary = {}) -> Dictionary:
	var out := {}
	var time_key := Questions.time_key(q)
	if time_key != "":
		out[time_key] = not flight.is_empty() and questions.time_right(q, flight)
	if str(q.get("country", "")) != "":
		out[str(q.country)] = str(flight.get("country", "")) == str(q.country)
	if str(q.get("verb_key", "")) != "":
		out[str(q.verb_key)] = str(flight.get("dir", "")) == str(q.dir)
	var target: Dictionary = schedule.by_id(str(q.get("target", "")))
	if WEEKDAY_TRACKED.has(str(q.get("kind", ""))) and not target.is_empty() and schedule.offset(target) != 0:
		out[WEEKDAYS[GameClock.weekday(int(target.day))]] = not flight.is_empty() and int(flight.day) == int(target.day)
	return out

func _word_line(key: String) -> Dictionary:
	return {"foreign": lexicon.word(key, lexicon.foreign), "native": lexicon.word(key, lexicon.native)}

## A board row: the destination is a flag and an airport code, never the country's name
## (the question names it); no departed / scheduled status (it would give the tense away).
## "day" is the weekday line, or the month/day digits for weekday questions.
func _row(flight: Dictionary) -> Dictionary:
	var day: Variant = GameClock.month_day(flight.date) if _shows_date() else _word_line(WEEKDAYS[GameClock.weekday(int(flight.day))])
	return {"id": flight.id, "code": flight.code, "airport": str(flight.get("airport", "")), "flag": flight.country,
		"dir": str(flight.get("dir", "dep")), "day": day, "time": _time_text(int(flight.minutes))}

## A missed question for the summary: "ayer → miércoles 8:30 a. m." (the right flight's day,
## or date for weekday questions, and time as the board showed them) over the expression in
## the native language.
func _review_line(q: Dictionary) -> Dictionary:
	var target: Dictionary = schedule.by_id(str(q.target))
	var row := _row(target)
	var day: String = str(row.day.foreign) if row.day is Dictionary else str(row.day)
	return {"foreign": lexicon.phrase("flight.review_item", lexicon.foreign, {"time": q.time.ref, "board": "%s %s" % [day, row.time]}),
		"native": lexicon.text(q.time.ref, lexicon.native)}

## Weekday questions show the date instead of the weekday word.
func _shows_date() -> bool:
	return quiz and str(question.get("kind", "")) == "weekday"

## 12-hour digits with the foreign language's a.m. / p.m. marker: 8:30 a. m.
func _time_text(minutes: int) -> String:
	return lexicon.phrase("flight.time_am" if GameClock.is_am(minutes) else "flight.time_pm", lexicon.foreign, {"time": GameClock.clock12(minutes)})

## The calendar of today's month, Sunday first, with whole weeks; it grows to show every
## board day (anteayer to pasado mañana) when they fall in the next or last month. Cells:
## {"day", "month" (false: another month, drawn dim), "today"}.
func _calendar() -> Dictionary:
	var clock = GameClock.shared()
	var today: int = clock.today_number()
	var first := GameClock.day_number({"y": int(clock.today.y), "m": int(clock.today.m), "d": 1})
	var last := first + GameClock.days_in_month(int(clock.today.y), int(clock.today.m)) - 1
	var days: Array = Schedule.rules().get("board_days", [-2, 2])
	var start := mini(first, today + int(days[0]))
	start -= GameClock.sunday_column(start)
	var finish := maxi(last, today + int(days[1]))
	finish += 6 - GameClock.sunday_column(finish)
	var cells: Array = []
	for number in range(start, finish + 1):
		var date := GameClock.date_of(number)
		cells.append({"day": int(date.d), "month": int(date.m) == int(clock.today.m), "today": number == today})
	var heads: Array = []
	for id in ["cal_sun", "cal_mon", "cal_tue", "cal_wed", "cal_thu", "cal_fri", "cal_sat"]:
		heads.append(lexicon.line("flight." + id))
	return {"title": lexicon.line("flight.calendar_title", {"month": {"word": Questions.MONTHS[int(clock.today.m) - 1]}, "year": str(clock.today.y)}),
		"heads": heads, "cells": cells}

func _panel_data() -> Dictionary:
	var clock = GameClock.shared()
	var columns: Array = []
	for id in COLUMNS:
		columns.append(lexicon.line("flight." + ("col_date" if id == "col_day" and _shows_date() else id)))
	return {
		"quiz": quiz,
		"title": lexicon.line("flight.title"),
		"translate": lexicon.line("common.show_translation"),
		"question": questions.line(question) if quiz and not question.is_empty() else {},
		"hint": lexicon.line("flight.browse_hint"),
		"clock": {"weekday": _word_line(WEEKDAYS[GameClock.weekday(clock.today_number())]), "time": _time_text(int(clock.now))},
		"tabs": [{"id": "dep", "label": lexicon.line("flight.tab_departures"), "column": lexicon.line("flight.col_destination")},
			{"id": "arr", "label": lexicon.line("flight.tab_arrivals"), "column": lexicon.line("flight.col_origin")}],
		"calendar": _calendar(),
		"columns": columns,
		"board": schedule.board().map(_row),
		"empty": lexicon.line("flight.empty"),
		"why": lexicon.line("flight.what_wrong"),
		"next": lexicon.line("flight.next"),
		"exit": lexicon.line("flight.exit"),
		"finish": lexicon.line("flight.finish"),
	}

func _on_flight(id: String) -> void:
	if not quiz or question.is_empty() or panel.solved or not panel.visible:
		return
	if panel.marks.has(id):
		return
	var right: bool = id == str(question.target)
	# Only a flight found on the first tap counts toward progress.
	var first_try: bool = not panel.marks.values().has(false)
	if not right:
		_wrong_flight = id
	if PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().first_answer(_tested(question, schedule.by_id(id)))
		if right:
			PracticeLog.shared().complete()
	panel.mark(id, right, lexicon.line("flight.correct" if right else "flight.wrong"))
	if not right:
		return
	for ref in question.words:
		if not _practised.has(ref):
			_practised.append(ref)
	if not first_try:
		_missed.append({"ref": question.time.ref, "line": _review_line(question)})
	if first_try:
		var finished: bool = Board.shared().add_success(ACTIVITY)
		panel.set_progress(Board.shared().done(ACTIVITY), Board.shared().target(ACTIVITY))
		if finished:
			offered = false
			_completed = true
			var review: Array = _missed.map(func(m): return m.line)
			var lines: Array = []
			for ref in _practised:
				if _missed.any(func(m): return m.ref == ref):
					continue
				lines.append({"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)})
			panel.show_summary(lexicon.line("flight.summary"), lines, lexicon.line("flight.complete"), lexicon.line("flight.review"), review)

func _on_why() -> void:
	if not quiz or question.is_empty() or _wrong_flight == "":
		return
	panel.show_explanation(questions.explain(question, schedule.by_id(_wrong_flight)))

func _practice_abandon() -> void:
	host.abandon_practice()

## Finish: after a completed game Bruno asks whether to play again (yes: open_game through
## the host's play_chosen; no: his goodbye); otherwise his goodbye.
func _on_finish() -> void:
	_practice_abandon()
	quiz = false
	question = {}
	panel.hide_panel()
	if _completed:
		_completed = false
		host.offer("flight.again", "flight.play_again")
	else:
		_show("flight.goodbye")

## ✕, Exit or Esc: browsing and the summary close at once; a game in progress asks first.
func _on_close() -> void:
	if not panel.visible:
		return
	if not panel.summary.is_empty():
		_on_finish()
		return
	if not quiz:
		panel.hide_panel()
		return
	host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if leave:
		_practice_abandon()
		quiz = false
		question = {}
		panel.hide_panel()
		_show("flight.left_early")

## A language change in Settings ends the game with Bruno's goodbye; his name follows the
## new languages.
func end_activity() -> void:
	if host == null:
		return
	host.cancel_leave()
	_practice_abandon()
	if panel.visible:
		var was_quiz := quiz
		quiz = false
		question = {}
		panel.hide_panel()
		if was_quiz:
			_show("flight.left_early")
	host.refresh_name()

# --- Each frame -------------------------------------------------------------------------

func _process(delta: float) -> void:
	if host != null:
		host.tick(delta)
