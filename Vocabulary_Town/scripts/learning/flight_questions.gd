extends RefCounted
## Questions for the airport flight game: "find the flight that …" built from ONE time
## expression, an optional country and a past / future verb. Pure logic: a question holds
## text references (Lexicon.text()), never text, so it renders in any language pair.
##
## Redesign of 7 Nov 2026 (user decisions): a right answer must mean the player understood the
## time expression. Every question is validated (valid()) so that
##   1. exactly one flight matches the whole question (time, country and tense);
##   2. at least `min_decoys` (data/flight_game.json) other flights share its country (when
##      named) and its tense, so neither the flag nor the verb finds the answer alone;
##   3. one of those flights is a NEAR MISS that differs only in the tested expression (the
##      same clock time on another day; the same day at another part of the day or another
##      hour; for clock questions both).
## Arrivals (8 Nov 2026, user decision): a flight departs for its country (salir: el vuelo a
## Francia que salió…) or arrives from it (llegar: el vuelo de Francia que llegó…); decoys share
## the question's direction too. A question WITHOUT a country is used only when the verb is
## needed: on a board with both directions, a flight of the other direction with the same
## tense also fits the time expression (4.); then the verb (llegar / salir) is tracked.
## One main thing per question (8 Nov 2026, user decision, after a 19-word clock question):
## the "long_kinds" (clock: a day and a clock time; hours: hace / dentro de N horas) never name
## a country and never use the "va a" future, and they are exempt from rule 4 (the
## Salidas / Llegadas tab already asks for the verb) and ask the short way (¿Qué vuelo…?); the
## verb is tracked only when it decides; no question is longer than "max_words" (too_long()).
##
## A question: {"kind", "target" (flight id), "phrase" (flight.q_…), "values" {country?, time},
## "country" (word key or ""), "past" (bool), "dir" ("dep" / "arr"), "verb_key" (the tracked
## verb's word key, or ""), "time" {kind and its numbers, see fits()},
## "words": [text references practised: the time expression and the country]}.
##
## Kinds (data/flight_game.json "kinds"; all within anteayer..pasado mañana):
##   day      anteayer, ayer, hoy, mañana, pasado mañana
##   part     esta mañana (05:00–11:59), esta tarde (12:00–19:59), esta noche (20:00–23:59), anoche
##            (yesterday from 20:00, or today before 05:00)
##   clock    a day word plus a clock time: mañana a las ocho de la noche
##   weekday  el viernes: a day of the board other than today (salió el lunes, sale el viernes)
##   hours    hace / dentro de 1–3 horas: exactly that many hours from now
## Week, month, year, day and week intervals, "el martes pasado" and dates were removed from
## this game (7 Nov 2026) for a planned calendar game; their phrases and words stay in the data.
## The verb follows the flight: salió (departed) before now, otherwise sale or va a salir.
const GameClock := preload("res://scripts/learning/game_clock.gd")
const Schedule := preload("res://scripts/learning/flight_schedule.gd")

const DAY_WORDS := {-2: "day before yesterday", -1: "yesterday", 0: "today", 1: "tomorrow", 2: "day after tomorrow"}
const WEEKDAYS := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
const MONTHS := ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
const PARTS := {"morning": "this morning", "afternoon": "this afternoon", "night": "tonight", "last_night": "last night"}
## The listed interval words; other counts use the flight.ago_hours / in_hours phrases.
const HOUR_WORDS := {-1: "one hour ago", 1: "in one hour"}
const HOURS := [1, 3]

var schedule
var lexicon

func _init(flight_schedule, shared_lexicon) -> void:
	schedule = flight_schedule
	lexicon = shared_lexicon

static func kinds() -> Dictionary:
	return Schedule.rules().get("kinds", {})

## A uniformly weighted kind, not `avoid` when another exists.
static func pick_kind(rng: RandomNumberGenerator, avoid: String = "") -> String:
	var pool: Array = []
	for kind in kinds():
		if kind != avoid or kinds().size() == 1:
			for i in int(kinds()[kind]):
				pool.append(kind)
	return str(pool[rng.randi_range(0, pool.size() - 1)]) if not pool.is_empty() else ""

## Builds a NEW board for one question of `kind` and returns the validated question ({} when
## none could be built). Question-first (user decisions, 8 Nov 2026, after play-testing: the
## board looked random, came in blocks of one country and overflowed):
##   - the answer and "target_rows" - 1 near misses: one country, direction and tense, times
##     differing only in the tested expression (a cluster of flight_schedule.gd, three kept);
##   - when the question names the country, a COUNTRY TRAP: another country, same direction,
##     tense and time expression (so the flag matters);
##   - a VERB TRAP in the other tab: same tense and time expression, the named country (or any)
##     going the other way (so salir / llegar matters);
##   - fillers up to "tab_rows" per tab, at most "max_per_country" flights of a country per tab.
## Every flight is placed for a reason or is a filler that the validation keeps from matching.
func design(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var data := Schedule.rules()
	var pool: Array = data.get("countries", []).duplicate()
	var rows := int(data.get("tab_rows", 6))
	var keep := int(data.get("target_rows", 3))
	var most := int(data.get("max_per_country", 3))
	var choices: Array = data.get("cluster_for", {}).get(kind, [])
	if choices.is_empty() or pool.size() < 6:
		return {}
	for attempt in 120:
		Schedule._shuffle(pool, rng)
		var dir := "arr" if rng.randf() < .5 else "dep"
		var other := "dep" if dir == "arr" else "arr"
		var home := str(pool[0])
		var cluster: Array = schedule._cluster(str(choices[rng.randi_range(0, choices.size() - 1)]), rng, {})
		var fitting: Array = cluster.filter(func(f): return not time_for(kind, f).is_empty())
		if fitting.is_empty():
			continue
		var target: Dictionary = fitting[rng.randi_range(0, fitting.size() - 1)]
		var rest: Array = cluster.filter(func(f): return f != target)
		Schedule._shuffle(rest, rng)
		var named := not _long(kind) and rng.randf() < .5
		var placed: Array = []
		for f in [target] + rest.slice(0, keep - 1):
			placed.append(schedule.make(schedule.offset(f), int(f.minutes), home, dir))
		target = placed[0]
		var time := time_for(kind, target)
		if named:
			placed.append(_twin(target, time, str(pool[1]), dir, rng))
		placed.append(_twin(target, time, home if named else str(pool[3]), other, rng))
		# Fillers: this tab with two other countries, the other tab with three.
		var ok := _fill(placed, dir, [str(pool[1]), str(pool[2])], rows, most, rng) \
			and _fill(placed, other, [str(pool[3]), str(pool[4]), str(pool[5])], rows, most, rng)
		if not ok:
			continue
		schedule.flights = placed
		schedule.finish(rng)
		var question := _question(kind, target, time, home if named else "", rng)
		if valid(question):
			return question
	schedule.flights = []
	return {}

## A flight of `country` going `dir` on `target`'s day with its tense that fits `time` too: at
## another time when one fits (another part of the same morning, say), else at the same time.
func _twin(target: Dictionary, time: Dictionary, country: String, dir: String, rng: RandomNumberGenerator) -> Dictionary:
	var off: int = schedule.offset(target)
	for attempt in 12:
		var minutes := Schedule._between(rng, Schedule.first_time(), Schedule.last_time())
		var flight: Dictionary = schedule.make(off, minutes, country, dir)
		if minutes >= 0 and minutes != int(target.minutes) and bool(flight.past) == bool(target.past) and fits(time, flight):
			return flight
	return schedule.make(off, int(target.minutes), country, dir)

## Adds fillers going `dir` until that tab has `rows` flights, taking `countries` in turn and
## never more than `most` of a country in the tab; false when it cannot.
func _fill(placed: Array, dir: String, countries: Array, rows: int, most: int, rng: RandomNumberGenerator) -> bool:
	var used := {}
	for f in placed:
		used["%s %d" % [f.dir, f.stamp]] = true
	var turn := rng.randi_range(0, countries.size() - 1)
	for guard in 40:
		var tab: Array = placed.filter(func(f): return f.dir == dir)
		if tab.size() >= rows:
			return tab.size() == rows
		var country := str(countries[turn % countries.size()])
		turn += 1
		if tab.filter(func(f): return f.country == country).size() >= most:
			continue
		var flight: Dictionary = schedule.filler(rng, country, dir, used)
		if flight.is_empty():
			continue
		used["%s %d" % [dir, flight.stamp]] = true
		placed.append(flight)
	return false

func count_matches(question: Dictionary) -> int:
	var count := 0
	for flight in schedule.flights:
		if matches(question, flight):
			count += 1
	return count

## Does `flight` fit the question (time, country and tense)?
func matches(question: Dictionary, flight: Dictionary) -> bool:
	if str(question.country) != "" and str(flight.country) != str(question.country):
		return false
	if bool(flight.past) != bool(question.past) or str(flight.dir) != str(question.dir):
		return false
	return fits(question.time, flight)

## Does `flight` fit the time condition alone?
func fits(time: Dictionary, flight: Dictionary) -> bool:
	var off: int = schedule.offset(flight)
	var minutes := int(flight.minutes)
	match str(time.kind):
		"day":
			return off == int(time.offset)
		"part":
			return _part(flight) == str(time.part)
		"clock":
			return off == int(time.offset) and minutes == int(time.minutes)
		"weekday":
			return off != 0 and GameClock.weekday(int(flight.day)) == int(time.weekday)
		"hours":
			return int(flight.stamp) - schedule.now_stamp() == int(time.offset) * 60
	return false

## The flights that share the question's country (when named) and tense, except the target:
## what is left once the flag and the verb are used.
func decoys(question: Dictionary) -> Array:
	return schedule.flights.filter(func(f): return f.id != question.target and bool(f.past) == bool(question.past) \
		and str(f.dir) == str(question.dir) and (str(question.country) == "" or str(f.country) == str(question.country)))

## Flights of the other direction with the question's tense that fit its time expression: only
## the verb (llegar / salir) rules them out.
func verb_misses(question: Dictionary) -> Array:
	return schedule.flights.filter(func(f): return str(f.dir) != str(question.dir) and bool(f.past) == bool(question.past) \
		and fits(question.time, f))

## The three rules of the header.
func valid(question: Dictionary) -> bool:
	var target: Dictionary = schedule.by_id(str(question.target))
	if target.is_empty() or not matches(question, target) or count_matches(question) != 1:
		return false
	var pool := decoys(question)
	if pool.size() < int(Schedule.rules().get("min_decoys", 2)):
		return false
	if str(question.country) == "" and schedule.mixed() and verb_misses(question).is_empty() and not _long(str(question.kind)):
		return false
	if too_long(question):
		return false
	return not near_misses(question, pool).is_empty()

## Decoys that differ from the target only in the tested expression (see the header).
func near_misses(question: Dictionary, pool: Array = []) -> Array:
	if pool.is_empty():
		pool = decoys(question)
	var target: Dictionary = schedule.by_id(str(question.target))
	var off: int = schedule.offset(target)
	var same_clock := pool.filter(func(f): return int(f.minutes) == int(target.minutes) and schedule.offset(f) != off)
	var same_day := pool.filter(func(f): return schedule.offset(f) == off and int(f.minutes) != int(target.minutes))
	match str(question.kind):
		"day", "weekday":
			return same_clock
		"hours":
			return same_day
		"part":
			var same_part := pool.filter(func(f): return _bucket(int(f.minutes)) == _bucket(int(target.minutes)) and schedule.offset(f) != off)
			return same_day + same_part
		"clock":
			return same_clock + same_day if not same_clock.is_empty() and not same_day.is_empty() else []
	return []

## morning / afternoon / night by the clock alone.
static func _bucket(minutes: int) -> String:
	return "morning" if minutes < 720 else ("afternoon" if minutes < 1200 else "night")

## The part-of-day word that fits `flight`, or "".
func _part(flight: Dictionary) -> String:
	var off: int = schedule.offset(flight)
	var minutes := int(flight.minutes)
	if off == 0 and minutes >= 300:
		return _bucket(minutes)
	if (off == -1 and minutes >= 1200) or (off == 0 and minutes < 300):
		return "last_night"
	return ""

## The time condition `kind` can state about `flight` ({} when none fits): {"kind", …, "ref"}.
func time_for(kind: String, flight: Dictionary) -> Dictionary:
	var off: int = schedule.offset(flight)
	var minutes := int(flight.minutes)
	match kind:
		"day":
			if DAY_WORDS.has(off):
				return {"kind": kind, "offset": off, "ref": {"word": DAY_WORDS[off]}}
		"part":
			var part := _part(flight)
			if part != "":
				return {"kind": kind, "part": part, "ref": {"word": PARTS[part]}}
		"clock":
			# Not midnight: "mañana a medianoche" is ambiguous in everyday speech.
			if DAY_WORDS.has(off) and minutes != 0:
				return {"kind": kind, "offset": off, "minutes": minutes, "ref": {"phrase": "flight.day_clock", "values": {"day": {"word": DAY_WORDS[off]}, "clock": clock_ref(minutes)}}}
		"weekday":
			if off != 0 and DAY_WORDS.has(off):
				var weekday := GameClock.weekday(int(flight.day))
				return {"kind": kind, "weekday": weekday, "ref": {"phrase": "flight.on_weekday", "values": {"day": {"word": WEEKDAYS[weekday]}}}}
		"hours":
			var difference: int = int(flight.stamp) - schedule.now_stamp()
			if difference % 60 != 0:
				return {}
			var amount := difference / 60
			if absi(amount) < int(HOURS[0]) or absi(amount) > int(HOURS[1]):
				return {}
			return {"kind": kind, "offset": amount, "ref": _hours_ref(amount)}
	return {}

func _question(kind: String, flight: Dictionary, time: Dictionary, country: String, rng: RandomNumberGenerator) -> Dictionary:
	var past := bool(flight.past)
	var tense := "past" if past else ("future" if _long(kind) or rng.randf() < .5 else "going")
	# Long kinds ask the short way: ¿Qué vuelo…? (Busca el vuelo que… is two words longer).
	var shape := "which" if _long(kind) or rng.randf() < .5 else "find"
	var arrives := str(flight.dir) == "arr"
	# Departures: q_which_to_past / q_which_past; arrivals: q_which_from_past / q_which_arr_past.
	var middle := ("_from" if arrives else "_to") if country != "" else ("_arr" if arrives else "")
	var phrase := "flight.q_%s%s_%s" % [shape, middle, tense]
	var values := {"time": time.ref}
	var words: Array = [time.ref]
	if country != "":
		values["country"] = {"word": country}
		words.append({"word": country})
	var question := {"kind": kind, "target": flight.id, "phrase": phrase, "values": values, "country": country, "past": past, "dir": str(flight.dir), "verb_key": "", "time": time, "words": words}
	# The verb is tracked only when it decides (a flight of the other direction fits too).
	if country == "" and schedule.mixed() and not verb_misses(question).is_empty():
		question.verb_key = "to arrive" if arrives else "to depart"
		words.append({"word": question.verb_key})
	return question

## Longer than "max_words" in the foreign language (counted by spaces, so languages written
## without spaces never count as long)?
func too_long(question: Dictionary) -> bool:
	var text: String = lexicon.phrase(str(question.phrase), lexicon.foreign, question.values)
	return text.split(" ", false).size() > int(Schedule.rules().get("max_words", 99))

## Kinds whose time expression is already long: no country, no "va a" (data/flight_game.json).
static func _long(kind: String) -> bool:
	return Schedule.rules().get("long_kinds", []).has(kind)

# --- Practice tracking (practice_log.gd) --------------------------------------------------

## The word key of the tested time expression ("" when it is not one word of data/words.json:
## hace / dentro de 2–3 horas). For a clock question it is the day word.
static func time_key(question: Dictionary) -> String:
	var time: Dictionary = question.get("time", {})
	match str(time.get("kind", "")):
		"day", "clock":
			return str(DAY_WORDS.get(int(time.offset), ""))
		"part":
			return str(PARTS.get(str(time.part), ""))
		"weekday":
			return WEEKDAYS[int(time.weekday)]
		"hours":
			return str(HOUR_WORDS.get(int(time.offset), ""))
	return ""

## Was the time word understood when `flight` was tapped? It fits the time expression (for a
## clock question: the day), whatever its country or tense.
func time_right(question: Dictionary, flight: Dictionary) -> bool:
	if str(question.time.kind) == "clock":
		return schedule.offset(flight) == int(question.time.offset)
	return fits(question.time, flight)

# --- Text -----------------------------------------------------------------------------------

## The question as a {"foreign", "native"} line.
func line(question: Dictionary) -> Dictionary:
	return lexicon.line(str(question.phrase), question.values)

## Why `flight` is not the answer, as a line naming the tested expression: another country,
## or "that flight departed <its value>, not <the asked value>" (its own day, weekday, part of
## the day, day and clock, or hours from now). When the flight shares the asked value it
## differs in tense, and the line says when it really departs.
func explain(question: Dictionary, flight: Dictionary) -> Dictionary:
	var arrives := str(flight.dir) == "arr"
	# The other direction: "Ese vuelo llega, no sale" (whatever its country).
	if str(flight.dir) != str(question.dir):
		return lexicon.line("flight.why_arrives" if arrives else "flight.why_departs")
	if str(question.country) != "" and str(flight.country) != str(question.country):
		return lexicon.line("flight.why_country_from" if arrives else "flight.why_country", {"country": {"word": flight.country}, "wanted": {"word": question.country}})
	var own := _own_value(str(question.kind), flight)
	var past := bool(flight.past)
	var suffix := "_arr" if arrives else ""
	if str(own) == str(question.time.ref):
		return lexicon.line(("flight.why_past" if past else "flight.why_future") + suffix, {"time": describe(flight)})
	return lexicon.line(("flight.why_past_not" if past else "flight.why_future_not") + suffix, {"time": own, "wanted": question.time.ref})

## `flight`'s own value in the dimension `kind` tests, as a text reference.
func _own_value(kind: String, flight: Dictionary) -> Dictionary:
	var off: int = schedule.offset(flight)
	match kind:
		"day":
			if DAY_WORDS.has(off):
				return {"word": DAY_WORDS[off]}
		"weekday":
			if off == 0:
				return {"word": DAY_WORDS[0]}
			return {"phrase": "flight.on_weekday", "values": {"day": {"word": WEEKDAYS[GameClock.weekday(int(flight.day))]}}}
		"part", "hours":
			var own := time_for(kind, flight)
			if not own.is_empty():
				return own.ref
	return describe(flight)

## When a flight departs, said the simplest way: a day word and the clock within two days
## of today, otherwise its date (with the year when it is not this year).
func describe(flight: Dictionary) -> Dictionary:
	var off: int = schedule.offset(flight)
	if DAY_WORDS.has(off):
		return {"phrase": "flight.day_clock", "values": {"day": {"word": DAY_WORDS[off]}, "clock": clock_ref(int(flight.minutes))}}
	return date_ref(flight.date, int(flight.date.y) != int(schedule.today_date.y))

func date_ref(date: Dictionary, with_year: bool) -> Dictionary:
	var values := {"day": _day_number(int(date.d)), "month": {"word": MONTHS[int(date.m) - 1]}}
	if with_year:
		values["year"] = int(date.y)
	return {"phrase": "flight.on_date_year" if with_year else "flight.on_date", "values": values}

## A clock time said naturally: a las ocho de la noche, a la una y media de la tarde, al
## mediodía, a medianoche. Hours run 1–12 with de la mañana (until 11:59), de la tarde
## (12:30–19:59) and de la noche (from 20:00).
func clock_ref(minutes: int) -> Dictionary:
	if minutes == 0:
		return {"phrase": "flight.clock_midnight"}
	if minutes == 720:
		return {"phrase": "flight.clock_noon"}
	var hour24 := minutes / 60
	var half := minutes % 60 == 30
	var period := "flight.period_morning" if hour24 < 12 else ("flight.period_afternoon" if hour24 < 20 else "flight.period_night")
	var hour := hour24 % 12
	if hour == 0:
		hour = 12
	if hour == 1:
		return {"phrase": "flight.clock_one_half" if half else "flight.clock_one", "values": {"period": {"phrase": period}}}
	return {"phrase": "flight.clock_half" if half else "flight.clock_hour", "values": {"hour": _number(hour), "period": {"phrase": period}}}

func _hours_ref(amount: int) -> Dictionary:
	if HOUR_WORDS.has(amount):
		return {"word": HOUR_WORDS[amount]}
	return {"phrase": "flight.%s_hours" % ["ago" if amount < 0 else "in"], "values": {"n": _number(absi(amount))}}

## The day of a date: digits, or words in the languages listed in data/flight_game.json
## "day_in_words" (Chinese 三月四日).
func _day_number(day: int) -> Dictionary:
	var words: Array = Schedule.rules().get("day_in_words", [])
	var out := {}
	for code in lexicon.codes():
		out[code] = lexicon.number(day, code) if words.has(code) and lexicon.rules(code) != null else str(day)
	return out

## A number in every language, for a phrase value ({"es": "tres", "zh": "三", …}); before a
## noun or measure word (Chinese 兩 for 2).
func _number(n: int) -> Dictionary:
	var out := {}
	for code in lexicon.codes():
		if lexicon.rules(code) != null:
			out[code] = lexicon.number(n, code, true)
	return out
