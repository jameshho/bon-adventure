extends RefCounted
## The game's shared "today" and "now" (user decision, 5 Nov 2026): one random date between
## FIRST_YEAR-01-01 and LAST_YEAR-12-31 and a time between NOW_FIRST and NOW_LAST on the
## half hour, picked once per launch and never saved. The hospital family game counts ages
## from it (family_tree.gd) and the airport flight game builds its schedule around it
## (flight_schedule.gd), so both show the same "today". It does not advance while playing.
## The HUD clock (scripts/world/day_night.gd, 9 Nov 2026) starts at `now` and then runs on its
## own; `now` itself stays fixed, so the airport board keeps the launch time.
##
## Dates are {"y", "m", "d"}; a "day number" is whole days since 1970-01-01 (UTC), so date
## arithmetic is integer arithmetic. Times are minutes after midnight.
## Tests may fix the clock with set_now().
const FIRST_YEAR := 2026
const LAST_YEAR := 2027
## The earliest and latest "now", in minutes (09:00 and 19:00).
const NOW_FIRST := 9 * 60
const NOW_LAST := 19 * 60

static var _shared

var today: Dictionary = {}
var now: int = 0

static func shared():
	if _shared == null:
		_shared = new()
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		_shared.roll(rng)
	return _shared

func roll(rng: RandomNumberGenerator) -> void:
	var first := day_number({"y": FIRST_YEAR, "m": 1, "d": 1})
	var last := day_number({"y": LAST_YEAR, "m": 12, "d": 31})
	today = date_of(rng.randi_range(first, last))
	now = rng.randi_range(NOW_FIRST / 30, NOW_LAST / 30) * 30

func set_now(date: Dictionary, minutes: int) -> void:
	today = {"y": int(date.y), "m": int(date.m), "d": int(date.d)}
	now = minutes

func today_number() -> int:
	return day_number(today)

static func day_number(date: Dictionary) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": int(date.y), "month": int(date.m), "day": int(date.d), "hour": 12, "minute": 0, "second": 0})) / 86400

static func date_of(number: int) -> Dictionary:
	var parts := Time.get_datetime_dict_from_unix_time(number * 86400 + 43200)
	return {"y": int(parts.year), "m": int(parts.month), "d": int(parts.day)}

## 0 = Monday … 6 = Sunday (calendar weeks start on Monday).
static func weekday(number: int) -> int:
	# 1970-01-01 (day 0) was a Thursday.
	return (number + 3) % 7

## The day number of the Monday of `number`'s week.
static func monday(number: int) -> int:
	return number - weekday(number)

static func days_in_month(year: int, month: int) -> int:
	var next := {"y": year + (1 if month == 12 else 0), "m": 1 if month == 12 else month + 1, "d": 1}
	return day_number(next) - day_number({"y": year, "m": month, "d": 1})

## MM/DD/YYYY digits (user decision, 4 Nov 2026), the same in every language.
static func digits(date: Dictionary) -> String:
	return "%02d/%02d/%04d" % [int(date.m), int(date.d), int(date.y)]

## 24-hour clock digits: 08:30 (checks and logs; the flight game shows clock12()).
static func clock(minutes: int) -> String:
	return "%02d:%02d" % [minutes / 60, minutes % 60]

## 12-hour clock digits without the a.m. / p.m. marker: 8:30, 12:00 (user decision, 8 Nov
## 2026: the flight game shows 12-hour times; the marker is a phrase, flight.time_am / time_pm).
static func clock12(minutes: int) -> String:
	var hour := (minutes / 60) % 12
	return "%d:%02d" % [12 if hour == 0 else hour, minutes % 60]

## Before noon (a.m.)?
static func is_am(minutes: int) -> bool:
	return minutes < 12 * 60

## Month/day digits without the year: 3/11 (the flight board's date for weekday questions).
static func month_day(date: Dictionary) -> String:
	return "%d/%d" % [int(date.m), int(date.d)]

## 0 = Sunday … 6 = Saturday: the column in a Sunday-first calendar (user decision, 8 Nov 2026).
static func sunday_column(number: int) -> int:
	return (weekday(number) + 1) % 7
