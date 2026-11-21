extends RefCounted
## The shared rules for when NPC activities (minigames) are offered, one at a time, and how a
## session's progress counts (data/activities.json; user decisions 4 Nov 2026). Every
## minigame session uses it the same way:
##   1. setup:      board.register(id, self) — the session's activity_running() returns true
##                  while its activity is in progress (an order, a round, an open panel).
##   2. arriving:   offered = board.roll(id, rng) — the data's chance; the NPC calls ("!") or
##                  invites only when offered.
##   3. talking:    if board.blocker(id) != "": refuse with common.finish_first (no overlap).
##   4. a session:  board.begin(id); per round answered right the first time
##                  board.add_success(id) (true when the target is reached: thank and end).
## New activities need only a data entry and these calls.
##
## Lifecycle (PWA phase 4, user decision 12 Nov 2026: one watcher, no session changes):
## Main calls watch() once a frame; it finds the activity in progress (as blocker("") does) and
## emits started(id) when one begins and ended(id, summary) when it stops, however it stopped
## (target reached, walked away, language change, quit). summary = {"rounds": rounds right the
## first time, "target": rounds needed (0 = none), "completed": the target was reached}.
## Progression (game_progress.gd, 18 Nov 2026) adds to the summary: "misses" (add_miss() calls:
## a round answered wrong at least once, a retry), "needed" (the rounds the session needed when
## it began, at least 1) and "custom" (the picker's rounds differed from the data's).
## running_id is the activity in progress at the last watch() ("" = none).
##
## Test launcher (game_launcher.gd, 9 Nov 2026): set_rounds(id, n) overrides the data's
## progress for the next sessions of that game (the launcher also pauses practice_log.gd). "kind" in the data is "learning" (default) or
## "pastime" (games played for fun, such as mahjong; no tested words).
const PATH := "res://data/activities.json"

signal started(id: String)
signal ended(id: String, summary: Dictionary)

var running_id := ""
## Something that is not an activity holds every offer off (the tutorial, tutorial.gd, 12 Nov
## 2026): while set, blocker(id) names it for every activity, so no NPC calls ("!") or starts a
## game. It never appears in running_id, started or ended.
var hold := ""

var activities: Dictionary = {}
## id -> WeakRef to the session (its activity_running()). Weak, because this board outlives
## the town: holding the sessions or callables bound to them crashed Godot on quit.
var _running: Dictionary = {}
## id -> successful rounds in the current session.
var _done: Dictionary = {}
## id -> rounds chosen in the test launcher (replaces the data's progress while set).
var _rounds: Dictionary = {}
## id -> misses in the current session (add_miss()).
var _misses: Dictionary = {}
## id -> {"needed", "custom"} recorded by begin() for the ended summary.
var _began: Dictionary = {}

static var _shared

static func shared():
	if _shared == null:
		_shared = new()
		_shared.load_data()
	return _shared

func load_data() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	activities = parsed.get("activities", {}) if parsed is Dictionary else {}
	if activities.is_empty():
		push_error("activity_board: no activities in " + PATH)

func has(id: String) -> bool:
	return activities.has(id)

func chance(id: String) -> float:
	return clampf(float(activities.get(id, {}).get("chance", 1.0)), 0.0, 1.0)

## Rounds a session needs; 0 means no progress bar and no target. The test launcher's
## choice (set_rounds()) wins over the data.
func target(id: String) -> int:
	if _rounds.has(id):
		return int(_rounds[id])
	return maxi(0, int(activities.get(id, {}).get("progress", 0)))

## Rounds one session plays: the target, at least 1 (games whose data says 0, such as the
## grocery order and mahjong, play one round and show no bar).
func rounds(id: String) -> int:
	return maxi(1, target(id))

## The test launcher's round count for `id` (n < 1 removes it: the data counts again).
func set_rounds(id: String, n: int) -> void:
	if n < 1:
		_rounds.erase(id)
	else:
		_rounds[id] = n

## "learning" or "pastime" (data/activities.json "kind").
func kind(id: String) -> String:
	return str(activities.get(id, {}).get("kind", "learning"))

## The session registered for `id` (null when its building is left out).
func session(id: String) -> Object:
	var ref: WeakRef = _running.get(id)
	var found: Object = ref.get_ref() if ref != null else null
	return found if is_instance_valid(found) else null

## `quiet`: an id that is not in the data on purpose (the supermarket till's free shopping,
## 21 Nov 2026: it blocks other games and hides the HUD like one, but is no game).
func register(id: String, session: Object, quiet := false) -> void:
	if not has(id) and not quiet:
		push_warning("activity_board: '%s' is not in %s" % [id, PATH])
	_running[id] = weakref(session)

## Whether the NPC offers its activity this time (rolled on arrival).
func roll(id: String, rng: RandomNumberGenerator) -> bool:
	var p := chance(id)
	return p >= 1.0 or (p > 0.0 and rng.randf() < p)

## The id of another activity in progress, or "" when `id` may start.
func blocker(id: String) -> String:
	if hold != "" and id != "":
		return hold
	for other in _running:
		var session: Object = _running[other].get_ref()
		if other != id and is_instance_valid(session) and bool(session.activity_running()):
			return other
	return ""

## Once a frame (Main._process): emits ended / started when the activity in progress changes.
func watch() -> void:
	var now := blocker("")
	if now == running_id:
		return
	var previous := running_id
	running_id = now
	if previous != "":
		var began: Dictionary = _began.get(previous, {"needed": rounds(previous), "custom": false})
		ended.emit(previous, {"rounds": done(previous), "target": target(previous), "completed": target(previous) > 0 and done(previous) >= target(previous),
				"misses": misses(previous), "needed": int(began.needed), "custom": bool(began.custom)})
	if now != "":
		started.emit(now)

## A new session starts at 0.
func begin(id: String) -> void:
	_done[id] = 0
	_misses[id] = 0
	var data_rounds := maxi(1, int(activities.get(id, {}).get("progress", 0)))
	_began[id] = {"needed": rounds(id), "custom": rounds(id) != data_rounds}

func done(id: String) -> int:
	return int(_done.get(id, 0))

## One more round right the first time. True when the session's target is reached.
func add_success(id: String) -> bool:
	_done[id] = done(id) + 1
	return target(id) > 0 and done(id) >= target(id)

## A round went wrong at least once (call once per round, or once per retry). Progression
## (game_progress.gd) turns the misses into stars; it changes nothing else.
func add_miss(id: String) -> void:
	_misses[id] = misses(id) + 1

func misses(id: String) -> int:
	return int(_misses.get(id, 0))
