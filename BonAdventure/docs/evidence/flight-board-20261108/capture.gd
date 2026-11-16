extends SceneTree
## Airport flight game, revision of 8 Nov 2026 (calendar and digital clock, 12-hour times, one
## day column, 3 countries x 4 flights, weekday tracking, play again). Renders the flight panel
## at a fixed today (Thursday 3/12/2026, 2:30 p.m.) and checks in the real town:
##   - a day / clock question shows weekday words in the day column; a weekday question shows
##     month/day dates (col_date) and never the asked weekday word;
##   - board times are 12-hour with the foreign a.m. / p.m. marker; no flight in the 12 o'clock hour;
##   - the calendar has 7 heads, today circled, and covers anteayer..pasado mañana at a month end;
##   - an ayer / anteayer / mañana question also tracks that day's weekday;
##   - Finish after a completed game asks to play again; yes starts a new game at 0/5;
##   - (later on 8 Nov) no flight from 7:00 to 8:59 p.m.; the board has departures and
##     arrivals (rows carry dir); an arrival question without a country tracks "to arrive";
##     a question missed on the first tap opens the summary's "Para repasar" list;
##   - (Salidas / Llegadas tabs, later on 8 Nov) each tab shows only its flights with Destino /
##     Origen; a game starts on Salidas;
##   - (evening of 8 Nov) 4 countries, 8 departures and 8 arrivals; the clock shows today's
##     weekday and the time; the calendar has no day names (native-language names only with
##     translations); a clock question names no country and has at most 12 words;
##   - (night of 8 Nov, question-first boards) every question gets its own board: 6 departures and
##     6 arrivals, at most 3 of a country per tab; the rows fit the board without a scroll bar
##     (es-day, and zh-question with two-line translated rows).
## Each view first shows the tab of the flight that matters (the target, or the wrong pick).
## Views: es-start, es-day, es-wrong, es-arrival, es-weekday, es-summary, es-again, es-month-end, en-question,
## zh-question (translations shown), browse. Uses Main, which saves progress and settings:
## run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=airport godot --path . --resolution 1400x900 --script res://docs/evidence/flight-board-20261108/capture.gd
const GameClock := preload("res://scripts/learning/game_clock.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Questions := preload("res://scripts/learning/flight_questions.gd")
const FOLDER := "res://docs/evidence/flight-board-20261108/"
var failures := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frame(file: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")

## Asks until `accept` holds for the question.
func ask(session, accept: Callable) -> bool:
	for i in 120:
		if not session.question.is_empty() and accept.call(session.question):
			return true
		session.next_question()
	return false

## The calendar's day-name labels (flight_panel.gd tags them; sibling names are made unique).
func _heads(panel) -> Array:
	return panel.find_children("*", "Label", true, false).filter(func(l): return l.has_meta("calendar_head"))

## The board's rows fit inside it (no scroll bar, 8 Nov 2026).
func _fits(panel) -> bool:
	var scroll: ScrollContainer = panel.find_child("Board scroll", true, false)
	return panel._board_rows.get_combined_minimum_size().y <= scroll.size.y + 1.0

func _board_ok(flights: Array) -> bool:
	for dir in ["dep", "arr"]:
		var per := {}
		var tab: Array = flights.filter(func(f): return f.dir == dir)
		for f in tab:
			per[f.country] = int(per.get(f.country, 0)) + 1
		if tab.size() != 6 or per.values().any(func(n): return n > 3):
			return false
	return true

func play(game, session) -> void:
	session.offered = true
	game.interaction.clerk_activated.emit(session.bruno)
	game.shop_panel.choice_pressed.emit("flight_play")

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	GameClock.shared().set_now({"y": 2026, "m": 3, "d": 12}, 14 * 60 + 30)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await process_frame
	var session = game.get_node("FlightSession")
	session.set_process(false)
	var panel = game.flight_panel
	var box = game.shop_panel
	GameSettings.shared().set_languages("en", "es")
	await play(game, session)
	var lex = session.lexicon
	# Board: built for the question, 6 per tab, at most 3 of a country per tab, 12-hour times.
	var flights: Array = session.schedule.flights
	check(_board_ok(flights), "6 departures and 6 arrivals, at most 3 of a country per tab")
	check(flights.all(func(f): return not [12, 19, 20].has(int(f.minutes) / 60)), "no flight in the 12 o'clock hour or from 7:00 to 8:59 p.m.")
	check(flights.any(func(f): return f.dir == "arr") and flights.any(func(f): return f.dir == "dep"), "the board has arrivals and departures")
	var data: Dictionary = session._panel_data()
	check(data.board.all(func(r): return str(r.time).ends_with(" a. m.") or str(r.time).ends_with(" p. m.")), "board times are 12-hour with a. m. / p. m.: %s" % [data.board[0].time])
	check(str(data.clock.time) == "2:30 p. m." and str(data.clock.weekday.foreign) == "jueves", "clock: %s %s" % [data.clock.weekday.foreign, data.clock.time])
	await frame("es-start")
	check(_heads(panel).is_empty(), "the calendar shows no day names")
	check(panel.tab == "dep", "a game starts on Salidas")
	for id in ["dep", "arr"]:
		panel.select_tab(id)
		var ids: Array = panel.rows.keys()
		var right := ids.all(func(i): return session.schedule.by_id(i).dir == id) and ids.size() == flights.filter(func(f): return f.dir == id).size()
		var head := str(panel._columns()[1].foreign)
		check(right and head == ("Destino" if id == "dep" else "Origen"), "tab %s shows only its %d flights under %s" % [id, ids.size(), head])
	var cal: Dictionary = data.calendar
	check(cal.heads.size() == 7 and str(cal.heads[0].foreign) == "dom" and cal.cells.size() % 7 == 0 and cal.cells.filter(func(c): return c.today).size() == 1, "calendar: Sunday first, whole weeks, one today (%s)" % [cal.title.foreign])
	# A day question about another day: weekday words in the day column, weekday tracked.
	var found: bool = await ask(session, func(q): return str(q.kind) == "clock" and int(q.time.offset) != 0)
	var words: int = session.lexicon.phrase(str(session.question.phrase), "es", session.question.values).split(" ", false).size()
	check(found and str(session.question.country) == "" and words <= 12, "a clock question about another day: no country, %d words" % words)
	data = session._panel_data()
	check(data.board.all(func(r): return r.day is Dictionary), "day questions show weekday words")
	var target: Dictionary = session.schedule.by_id(session.question.target)
	var weekday_key: String = Questions.WEEKDAYS[GameClock.weekday(int(target.day))]
	var tracked: Dictionary = session._tested(session.question, target)
	check(tracked.has(weekday_key) and tracked[weekday_key] == true, "the target's weekday is tracked: %s" % [tracked])
	var other_day: Array = session.schedule.flights.filter(func(f): return int(f.day) != int(target.day))
	check(session._tested(session.question, other_day[0]).get(weekday_key) == false, "a flight on another day misses the weekday")
	check(_board_ok(session.schedule.flights), "a new board for the new question, 6 per tab")
	panel.select_tab(str(session.schedule.by_id(session.question.target).dir))
	await frame("es-day")
	check(_fits(panel), "es-day: the rows fit the board without a scroll bar")
	var near: Array = session.questions.near_misses(session.question)
	panel.flight_pressed.emit(str(near[0].id))
	panel.why_pressed.emit()
	await frame("es-wrong")
	# An arrival question without a country: the verb decides and is tracked.
	found = await ask(session, func(q): return str(q.dir) == "arr" and str(q.country) == "" and str(q.verb_key) != "")
	var arrival_target: Dictionary = session.schedule.by_id(session.question.target) if found else {}
	check(found and session._tested(session.question, arrival_target).get("to arrive") == true, "an arrival question without a country tracks llegar: %s" % [session.lexicon.phrase(str(session.question.get("phrase", "")), "es", session.question.get("values", {}))])
	if found:
		var departs: Array = session.questions.verb_misses(session.question)
		check(not departs.is_empty() and session._tested(session.question, departs[0]).get("to arrive") == false, "a departure at the asked time misses llegar")
		panel.flight_pressed.emit(str(departs[0].id))
		panel.why_pressed.emit()
		panel.select_tab(str(departs[0].dir))
	await frame("es-arrival")
	# A weekday question: dates in the day column, never the asked weekday word.
	found = await ask(session, func(q): return str(q.kind) == "weekday")
	data = session._panel_data()
	check(found and data.board.all(func(r): return r.day is String and "/" in str(r.day)) and str(data.columns[2].foreign) == "Fecha", "weekday questions show month/day dates under Fecha")
	panel.select_tab(str(session.schedule.by_id(session.question.target).dir))
	await frame("es-weekday")
	# The end: a miss first (for "Para repasar"), the summary, then Finish asks to play again;
	# yes starts again at 0/5.
	panel.flight_pressed.emit(str(session.questions.near_misses(session.question)[0].id))
	panel.flight_pressed.emit(str(session.question.target))
	check(session._missed.size() == 1, "a question missed on the first tap is kept for the summary")
	Board.shared()._done["flight_bruno"] = 4
	panel.next_pressed.emit()
	panel.flight_pressed.emit(session.question.target)
	check(not panel.summary.review.is_empty() and "→" in str(panel.summary.review[0].foreign), "the summary lists the missed question first: %s" % [panel.summary.review])
	await frame("es-summary")
	panel.finish_pressed.emit()
	check(box.is_dialogue_visible() and str(box.current_line().foreign) == lex.phrase("flight.again", "es"), "Finish asks to play again")
	await frame("es-again")
	box.choice_pressed.emit("flight_play")
	check(session.quiz and panel.visible and Board.shared().done("flight_bruno") == 0, "yes starts a new game at 0/5")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	# A month end: Tuesday 3/31, so mañana and pasado mañana are in April.
	GameClock.shared().set_now({"y": 2026, "m": 3, "d": 31}, 10 * 60)
	await play(game, session)
	cal = session._panel_data().calendar
	var april: Array = cal.cells.filter(func(c): return not c.month and int(c.day) <= 2)
	check(april.size() >= 2, "the month-end calendar shows April 1 and 2")
	await frame("es-month-end")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	GameClock.shared().set_now({"y": 2026, "m": 3, "d": 12}, 14 * 60 + 30)
	# English learned (Spanish native), then Chinese learned with the translation shown.
	GameSettings.shared().set_languages("es", "en")
	await play(game, session)
	await ask(session, func(q): return str(q.kind) == "part")
	panel.select_tab(str(session.schedule.by_id(session.question.target).dir))
	await frame("en-question")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	GameSettings.shared().set_languages("en", "zh")
	await play(game, session)
	await ask(session, func(q): return str(q.kind) == "day")
	panel.show_native = true
	panel.refresh_display()
	var heads: Array = _heads(panel)
	check(heads.size() == 7 and str(heads[0].text) == "Sun", "with translations the calendar shows native day names: %s" % [heads.map(func(h): return h.text)])
	panel.select_tab(str(session.schedule.by_id(session.question.target).dir))
	await frame("zh-question")
	check(_fits(panel), "zh-question: two-line rows fit the board without a scroll bar")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	GameSettings.shared().set_languages("en", "es")
	# Browsing outside the game (what E on the board or the booklet prop opens).
	session.quiz = false
	panel.show_native = false
	panel.open(session._panel_data())
	await frame("browse")
	print("FLIGHT BOARD CAPTURE %s, %d failed" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
