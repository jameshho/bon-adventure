extends SceneTree
## 7 Nov 2026: airport flight game logic after the board-only redesign (no town; replaces the
## 5 Nov check of docs/evidence/flight-game-20261105, which tested the removed booklet and kinds).
## Updated 8 Nov 2026 for the revision (3 countries from the pool per board, 4 flights each,
## no flight in the 12 o'clock hour, 12-hour clock helpers).
## Over many random "todays" and "nows" in 2026-2027:
##   - the schedule: board_countries (3) different countries from the pool, 4 flights each,
##     each country's flights share a tense, all from anteayer to pasado mañana, unique codes
##     and times, on :00 / :30 within the day's hours and never in a no_flight_hours hour;
##   - (8 Nov 2026, later) no flight from 7:00 to 8:59 p.m.; each country's flights share a
##     direction (departures or arrivals) and every board has both; a question without a
##     country is used only when the verb decides (a flight of the other direction with its
##     tense fits the time expression) and then tracks llegar / salir; arrival questions
##     use the _from / _arr phrases; wrong picks of the other direction are explained;
##   - (8 Nov 2026, evening) 4 countries, 2 departing and 2 arriving (8 flights per tab); clock
##     and hours questions name no country and use no "va a"; every Spanish question has at
##     most max_words words; the verb is tracked only when it decides;
##   - (8 Nov 2026, night) question-first boards: each question gets its own board, built
##     around it (flight_questions.gd design()): 6 departures and 6 arrivals, at most
##     max_per_country of a country per tab; a country trap when the question names a country
##     (another country, same direction, fitting time) and a verb trap in the other tab;
##   - the 12-hour helpers (8:30 / 12:00 / 1:00, a.m. before noon) and the Sunday-first column;
##   - every kind gets a board on every today;
##   - every question: exactly one matching flight, its target; at least min_decoys other
##     flights share its country (when named) and tense; a near miss differs only in the
##     tested expression (clock: both a same-clock and a same-day near miss); the verb's
##     tense fits; the tracked time word exists in data/words.json;
##   - a wrong pick that shares the country and tense is explained by the tested expression
##     (why_past_not / why_future_not, or the tense when it shares the expression);
##   - every question and explanation renders in every language.
## Prints a few sample boards. Writes nothing.
## godot --headless --path . --script res://docs/evidence/flight-board-20261107/verify.gd
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GameClock := preload("res://scripts/learning/game_clock.gd")
const Schedule := preload("res://scripts/learning/flight_schedule.gd")
const Questions := preload("res://scripts/learning/flight_questions.gd")
const SCHEDULES := 300
const SESSION := 5
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 40:
			print("FAIL: " + label)

func run() -> void:
	var lex = Lexicon.shared()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261107
	var clock = GameClock.new()
	var rules := Schedule.rules()
	var countries: Array = rules.get("countries", [])
	var rows := int(rules.get("tab_rows", 6))
	var most := int(rules.get("max_per_country", 3))
	var min_decoys := int(rules.get("min_decoys", 2))
	var countries_seen := {}
	check(GameClock.clock12(8 * 60 + 30) == "8:30" and GameClock.clock12(12 * 60) == "12:00" and GameClock.clock12(13 * 60) == "1:00" and GameClock.clock12(0) == "12:00", "12-hour digits")
	check(GameClock.is_am(11 * 60 + 30) and not GameClock.is_am(12 * 60), "a.m. before noon, p.m. from noon")
	# 1970-01-04 (day 3) was a Sunday, 1970-01-01 (day 0) a Thursday.
	check(GameClock.sunday_column(3) == 0 and GameClock.sunday_column(0) == 4, "Sunday-first calendar columns")
	check(GameClock.month_day({"y": 2026, "m": 3, "d": 11}) == "3/11", "month/day digits")
	var kinds_seen := {}
	var kind_missing := {}
	var bad_schedule := []
	var bad_question := []
	var bad_text := []
	var bad_explain := []
	var bad_traps := []
	var keys_seen := {}
	# Question-first boards (8 Nov 2026): every kind gets its own board on every "today".
	for s in SCHEDULES:
		clock.roll(rng)
		for kind in Questions.kinds():
			var schedule = Schedule.new()
			schedule.setup(clock, rng)
			var questions = Questions.new(schedule, lex)
			var question: Dictionary = questions.design(kind, rng)
			var label := "%s %s %s" % [GameClock.digits(clock.today), GameClock.clock(clock.now), kind]
			if question.is_empty():
				kind_missing[kind] = int(kind_missing.get(kind, 0)) + 1
				continue
			kinds_seen[kind] = int(kinds_seen.get(kind, 0)) + 1
			_check_board(schedule, label, rows, most, countries, countries_seen, bad_schedule)
			_check_traps(questions, schedule, question, label, bad_traps)
			_check_question(questions, schedule, question, lex, min_decoys, bad_question, bad_text, bad_explain, keys_seen, s % 25 == 0)
	check(bad_schedule.is_empty(), "every board: %d departures and %d arrivals, at most %d of a country per tab, allowed times on the board days, unique codes, right tense: %s" % [rows, rows, most, bad_schedule.slice(0, 5)])
	check(countries_seen.size() == countries.size(), "every pool country appears on some board: %s" % [countries_seen.keys()])
	check(bad_traps.is_empty(), "every board is built for its question: a country trap when the country is named, a verb trap in the other tab: %s" % [bad_traps.slice(0, 5)])
	check(bad_question.is_empty(), "every question: one matching flight (its target), enough decoys, a near miss, the right tense and direction, a known word key, short enough: %s" % [bad_question.slice(0, 5)])
	check(bad_explain.is_empty(), "wrong picks with the same country and tense are explained by the tested expression: %s" % [bad_explain.slice(0, 5)])
	check(bad_text.is_empty(), "every question and explanation renders in every language: %s" % [bad_text.slice(0, 5)])
	for kind in Questions.kinds():
		check(int(kind_missing.get(kind, 0)) == 0, "kind '%s' gets a board on every today (%d made, %d without)" % [kind, int(kinds_seen.get(kind, 0)), int(kind_missing.get(kind, 0))])
	print("questions per kind: %s; without a board: %s" % [kinds_seen, kind_missing])
	print("tracked time words: %s" % [keys_seen])
	_sample(lex, rng, clock)
	print("%s: %d checks, %d failed" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)

func _check_board(schedule, label: String, rows: int, most: int, countries: Array, countries_seen: Dictionary, bad: Array) -> void:
	var codes := {}
	for dir in ["dep", "arr"]:
		var tab: Array = schedule.flights.filter(func(f): return f.dir == dir)
		if tab.size() != rows:
			bad.append("%s: %d in %s" % [label, tab.size(), dir])
		var per := {}
		for f in tab:
			per[f.country] = int(per.get(f.country, 0)) + 1
		if per.values().any(func(n): return n > most):
			bad.append("%s: %s in %s" % [label, per, dir])
	for f in schedule.flights:
		countries_seen[f.country] = true
		if codes.has(f.code):
			bad.append("%s: repeated code %s" % [label, f.code])
		codes[f.code] = true
		if not countries.has(f.country) or str(f.airport) == "":
			bad.append("%s: country %s" % [label, f.country])
		if schedule.offset(f) < -2 or schedule.offset(f) > 2:
			bad.append("%s: %s off the board" % [label, f.code])
		if int(f.minutes) % 30 != 0 or not Schedule.allowed(int(f.minutes)) or [12, 19, 20].has(int(f.minutes) / 60):
			bad.append("%s: time %s" % [label, GameClock.clock(f.minutes)])
		if bool(f.past) != (int(f.stamp) < schedule.now_stamp()):
			bad.append("%s: tense of %s" % [label, f.code])

## The traps the board is built with (flight_questions.gd design()).
func _check_traps(questions, schedule, question: Dictionary, label: String, bad: Array) -> void:
	var fits_time := func(f): return bool(f.past) == bool(question.past) and questions.fits(question.time, f)
	if str(question.country) != "":
		var country_trap: Array = schedule.flights.filter(func(f): return f.dir == question.dir and f.country != question.country and fits_time.call(f))
		if country_trap.is_empty():
			bad.append("%s: no country trap" % label)
	var verb_trap: Array = schedule.flights.filter(func(f): return f.dir != question.dir and fits_time.call(f) and (str(question.country) == "" or f.country == question.country))
	if verb_trap.is_empty():
		bad.append("%s: no verb trap" % label)

func _check_question(questions, schedule, question: Dictionary, lex, min_decoys: int, bad_question: Array, bad_text: Array, bad_explain: Array, keys_seen: Dictionary, all_text: bool) -> void:
	var target: Dictionary = schedule.by_id(question.target)
	var name := "%s %s" % [question.kind, lex.text(question.time.ref, "es")]
	if questions.count_matches(question) != 1 or not questions.matches(question, target):
		bad_question.append("%s: %d matches" % [name, questions.count_matches(question)])
	var pool: Array = questions.decoys(question)
	if pool.size() < min_decoys:
		bad_question.append("%s: %d decoys" % [name, pool.size()])
	if questions.near_misses(question).is_empty():
		bad_question.append("%s: no near miss" % name)
	if bool(target.past) != str(question.phrase).ends_with("_past"):
		bad_question.append("tense of " + str(question.phrase))
	var arrives := str(target.dir) == "arr"
	if arrives != ("_from_" in str(question.phrase) or "_arr_" in str(question.phrase)):
		bad_question.append("direction of " + str(question.phrase))
	keys_seen["(arrival)" if arrives else "(departure)"] = int(keys_seen.get("(arrival)" if arrives else "(departure)", 0)) + 1
	var long_kind: bool = Schedule.rules().get("long_kinds", []).has(str(question.kind))
	var words: int = lex.phrase(str(question.phrase), "es", question.values).split(" ", false).size()
	if words > int(Schedule.rules().get("max_words", 99)):
		bad_question.append("%s: %d words" % [name, words])
	if long_kind and (str(question.country) != "" or str(question.phrase).ends_with("_going")):
		bad_question.append("%s: a long kind with a country or va a" % name)
	if str(question.country) == "":
		var misses: Array = questions.verb_misses(question)
		if (misses.is_empty() and not long_kind) or str(question.verb_key) != ("" if misses.is_empty() else ("to arrive" if arrives else "to depart")):
			bad_question.append("%s: no country but the verb does not decide, or its tracking is wrong" % name)
		for f in misses:
			var why: Dictionary = questions.explain(question, f)
			if why.foreign != lex.phrase("flight.why_departs" if arrives else "flight.why_arrives", "es") and why.foreign != lex.phrase("flight.why_departs" if arrives else "flight.why_arrives", lex.foreign):
				bad_explain.append("%s / %s: %s" % [name, f.code, why.foreign])
		keys_seen["(verb tracked)"] = int(keys_seen.get("(verb tracked)", 0)) + 1
	elif str(question.verb_key) != "":
		bad_question.append("%s: a country and a tracked verb" % name)
	var key: String = Questions.time_key(question)
	keys_seen[key] = int(keys_seen.get(key, 0)) + 1
	if key == "" and not (str(question.kind) == "hours" and absi(int(question.time.offset)) > 1):
		bad_question.append("%s: no tracked word" % name)
	if key != "" and not lex.has_word(key):
		bad_question.append("%s: word '%s' missing" % [name, key])
	if key != "" and not questions.time_right(question, target):
		bad_question.append("%s: target does not count as the right time word" % name)
	for f in pool:
		# Decoys share the country and tense, so the line must contrast the tested expression
		# (why_past_not / why_future_not: "…, no …" / "…, not …" / "…不是…").
		var why: Dictionary = questions.explain(question, f)
		var both := str(why.foreign) + " " + str(why.native)
		if not (", no " in both or ", not " in both or "不是" in both):
			bad_explain.append("%s / %s: %s" % [name, f.code, why.foreign])
	for code in lex.codes():
		var text: String = lex.phrase(str(question.phrase), code, question.values)
		if "{" in text or text == question.phrase or text.strip_edges() == "":
			bad_text.append("%s %s: %s" % [code, question.phrase, text])
	if all_text:
		for f in schedule.flights:
			if f.id == question.target:
				continue
			var why: Dictionary = questions.explain(question, f)
			if "{" in str(why.foreign) or "{" in str(why.native) or str(why.foreign) == "":
				bad_text.append("explanation %s" % [why])

## A few questions as the player would see them, Spanish with English, for the docs.
func _sample(lex, rng: RandomNumberGenerator, clock) -> void:
	clock.set_now({"y": 2026, "m": 3, "d": 12}, 14 * 60 + 30)
	print("\nSample: today %s (%s), now %s" % [GameClock.digits(clock.today), lex.word(Questions.WEEKDAYS[GameClock.weekday(clock.today_number())], "es"), GameClock.clock(clock.now)])
	var last := ""
	for i in SESSION:
		var kind := Questions.pick_kind(rng, last)
		last = kind
		var schedule = Schedule.new()
		schedule.setup(clock, rng)
		var questions = Questions.new(schedule, lex)
		var question: Dictionary = questions.design(kind, rng)
		print("  %d. [%s] %s | %s" % [i + 1, kind, lex.phrase(question.phrase, "es", question.values), lex.phrase(question.phrase, "en", question.values)])
		for f in schedule.flights:
			var role := "ANSWER" if f.id == question.target else ""
			print("       %s %s %s %-10s %s %s" % ["Salida " if f.dir == "dep" else "Llegada", f.code, f.airport, lex.word(Questions.WEEKDAYS[GameClock.weekday(int(f.day))], "es"), lex.phrase("flight.time_am" if GameClock.is_am(f.minutes) else "flight.time_pm", "es", {"time": GameClock.clock12(f.minutes)}), role])
