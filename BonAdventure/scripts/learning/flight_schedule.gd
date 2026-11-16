extends RefCounted
## The airport flight game's fictional schedule: ONE list of flights that the departure
## board, the questions and the answer check all read (single source of truth). Pure logic,
## no text: countries are word keys and dates are numbers; the panel and flight_questions.gd
## turn them into language. Rules: data/flight_game.json.
##
## A flight is {"id", "code" ("VT 214"), "country" (word key), "airport" (code shown with the
## flag), "dir" ("dep": leaves for the country, "arr": comes from it), "day" (day number, see
## game_clock.gd), "date" {y, m, d}, "minutes" (after midnight; the departure or arrival time),
## "stamp" (day * 1440 + minutes), "past" (departed / arrived before now)}. Flights are
## sorted by time; no two share a stamp or a code.
##
## Redesign of 7 Nov 2026 (user decisions): board only, every flight between anteayer and
## pasado mañana. Rebuilt 8 Nov 2026 (user decisions, after play-testing): the board is built
## FOR each question (flight_questions.gd design()): a new board per question, 6 departures and
## 6 arrivals ("tab_rows"), at most 3 flights of a country per tab, so countries are mixed.
## This file keeps the pieces: today / now, flights, fillers, codes and order, and the CLUSTER
## that gives the answer its near misses (four flights of one country, direction and tense whose
## times differ only in the dimension a question tests; design() keeps three of them):
##   days   one clock time t on three days: anteayer / ayer / hoy (before now), or
##          hoy (after now) / mañana / pasado mañana; plus ayer (mañana) at another time
##   mix    ayer and anteayer (or mañana and pasado mañana), each at t1 and t2; t2 is often
##          t1 + 12 h (a las ocho de la mañana / de la noche)
##   parts  past: anoche, ayer and hoy in the morning at the same time, anteayer at night;
##          future: esta noche, mañana and pasado mañana at the same night time, esta tarde
##          (mañana when no afternoon is left today)
##   hours  exactly 1, 2 and 3 hours before (or after) now, and a fourth flight never asked
##          about: 4 hours away, or 2½ / 1½ hours when 4 would leave the day or reach 12 o'clock
## No flight leaves in the 12 o'clock hour nor from 7:00 to 8:59 p.m. ("no_flight_hours").
const GameClock := preload("res://scripts/learning/game_clock.gd")
const PATH := "res://data/flight_game.json"
const HOUR := 60
const NOON := 12 * 60
const AFTERNOON_END := 19 * 60 + 30
const NIGHT_FIRST := 20 * 60
const NIGHT_LAST := 23 * 60

static var _rules: Dictionary = {}

var today := 0
var today_date: Dictionary = {}
var now := 0
var flights: Array = []

static func rules() -> Dictionary:
	if _rules.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if not parsed is Dictionary:
			push_error("flight_schedule: unreadable " + PATH)
			return {}
		_rules = parsed
	return _rules

static func _minutes(text: String) -> int:
	var parts := text.split(":")
	return int(parts[0]) * 60 + int(parts[1])

static func first_time() -> int:
	return _minutes(str(rules().get("first_time", "06:00")))

static func last_time() -> int:
	return _minutes(str(rules().get("last_time", "23:30")))

## Sets today and now from the clock; the board is empty until flight_questions.gd design()
## places the flights for one question (question-first board, 8 Nov 2026).
func setup(clock, rng: RandomNumberGenerator) -> void:
	today = clock.today_number()
	today_date = clock.today.duplicate()
	now = int(clock.now)
	flights.clear()

## A flight of `country` going `dir` at day offset `off` and `minutes`, airport filled in.
func make(off: int, minutes: int, country: String, dir: String) -> Dictionary:
	var flight := _flight(off, minutes)
	flight.country = country
	flight.dir = dir
	flight.airport = str(rules().get("airports", {}).get(country, ""))
	return flight

## A filler flight at a random allowed time on a random board day, at a stamp not in `used`
## for that direction ({} when none was found).
func filler(rng: RandomNumberGenerator, country: String, dir: String, used: Dictionary) -> Dictionary:
	var days: Array = rules().get("board_days", [-2, 2])
	for attempt in 30:
		var off := rng.randi_range(int(days[0]), int(days[1]))
		var minutes := _between(rng, first_time(), last_time())
		var flight := make(off, minutes, country, dir)
		if minutes >= 0 and not used.has("%s %d" % [dir, flight.stamp]):
			return flight
	return {}

## Codes, order by time and ids, once every flight is placed.
func finish(rng: RandomNumberGenerator) -> void:
	var codes := {}
	for flight in flights:
		var code := rng.randi_range(100, 989)
		while codes.has(code):
			code = rng.randi_range(100, 989)
		codes[code] = true
		flight.code = "%s %d" % [str(rules().get("code_prefix", "VT")), code]
	flights.sort_custom(func(a, b): return int(a.stamp) < int(b.stamp) or (int(a.stamp) == int(b.stamp) and str(a.code) < str(b.code)))
	for i in flights.size():
		flights[i].id = "f%d" % i

func now_stamp() -> int:
	return today * 1440 + now

func by_id(id: String) -> Dictionary:
	for flight in flights:
		if flight.id == id:
			return flight
	return {}

## Whether the board has more than one direction (llegar questions are possible).
func mixed() -> bool:
	var seen := {}
	for flight in flights:
		seen[flight.dir] = true
	return seen.size() > 1

## Days from today (negative: past).
func offset(flight: Dictionary) -> int:
	return int(flight.day) - today

## Every flight is on the board (one screen, sorted by departure).
func board() -> Array:
	return flights

# --- Clusters ------------------------------------------------------------------------------

func _flight(off: int, minutes: int) -> Dictionary:
	var day := today + off
	var stamp := day * 1440 + minutes
	return {"id": "", "code": "", "country": "", "airport": "", "dir": "dep", "day": day, "date": GameClock.date_of(day), "minutes": minutes, "stamp": stamp, "past": stamp < now_stamp()}

## A random time on the hour or half hour from `low` to `high` (minutes) outside the
## "no_flight_hours", or -1.
static func _between(rng: RandomNumberGenerator, low: int, high: int) -> int:
	var slots: Array = []
	for slot in range(ceili(low / 30.0), high / 30 + 1):
		if allowed(slot * 30):
			slots.append(slot * 30)
	return int(slots[rng.randi_range(0, slots.size() - 1)]) if not slots.is_empty() else -1

## Whether a flight may leave at `minutes`: within first_time..last_time and not in an hour of
## "no_flight_hours".
static func allowed(minutes: int) -> bool:
	if minutes < first_time() or minutes > last_time():
		return false
	for hour in rules().get("no_flight_hours", []):
		if int(hour) == minutes / 60:
			return false
	return true

## The four flights of one cluster kind (see the header), none at a stamp in `used`; [] when
## the times cannot be placed. The tense is drawn again on each attempt (an hours cluster
## that would reach the 12 o'clock hour one way can go the other).
func _cluster(kind: String, rng: RandomNumberGenerator, used: Dictionary) -> Array:
	for attempt in 30:
		var past := rng.randf() < .5
		var out: Array = []
		match kind:
			"days":
				var t := _between(rng, first_time(), now - HOUR) if past else _between(rng, now + HOUR, last_time())
				var other := _between(rng, first_time(), last_time())
				if t < 0 or other == t:
					continue
				for off in ([-2, -1, 0] if past else [0, 1, 2]):
					out.append(_flight(off, t))
				out.append(_flight(-1 if past else 1, other))
			"mix":
				var t1 := _between(rng, first_time(), last_time())
				var t2 := t1 + 12 * 60
				if not allowed(t2) or rng.randf() < .4:
					t2 = _between(rng, first_time(), last_time())
				if t1 < 0 or t2 == t1:
					continue
				var near := -1 if past else 1
				out = [_flight(near, t1), _flight(near * 2, t1), _flight(near, t2), _flight(near * 2, t2)]
			"parts":
				var night := _between(rng, NIGHT_FIRST, NIGHT_LAST)
				if past:
					var morning := _between(rng, first_time(), mini(NOON - 30, now - HOUR))
					if morning < 0:
						continue
					out = [_flight(-1, night), _flight(-1, morning), _flight(0, morning), _flight(-2, night)]
				else:
					var afternoon := _between(rng, maxi(NOON + 30, now + HOUR), AFTERNOON_END)
					var afternoon_day := 0
					if afternoon < 0:
						afternoon = _between(rng, NOON + 30, AFTERNOON_END)
						afternoon_day = 1
					out = [_flight(0, night), _flight(1, night), _flight(afternoon_day, afternoon), _flight(2, night)]
			"hours":
				var sign := -1 if past else 1
				for hours in [1, 2, 3]:
					var stamp: int = now_stamp() + sign * int(hours) * HOUR
					out.append(_flight(stamp / 1440 - today, stamp % 1440))
				# The fourth flight (never asked): 4 hours away, or 2½ / 1½ hours when 4 would
				# leave the day's hours or reach the 12 o'clock hour.
				for away in [4 * HOUR, 150, 90]:
					var stamp: int = now_stamp() + sign * away
					if allowed(stamp % 1440):
						out.append(_flight(stamp / 1440 - today, stamp % 1440))
						break
			_:
				push_error("flight_schedule: unknown cluster " + kind)
				return []
		var clash := false
		for flight in out:
			var minutes := int(flight.minutes)
			if used.has(flight.stamp) or not allowed(minutes) or bool(flight.past) != past:
				clash = true
		if not clash:
			return out
	return []

static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = list[i]
		list[i] = list[j]
		list[j] = swap
