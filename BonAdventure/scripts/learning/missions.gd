extends RefCounted
## Town missions (user, 21 Nov 2026; guide: docs/guides/ACHIEVEMENTS.md#missions): three small
## jobs around town, each pointing at one minigame ("Help Officer Rocco catch a suspect!"), shown
## on the Passport's Missions page (passport_panel.gd) and as stars on the town map.
##
## Rules (user):
##   - Three slots. A new profile starts with Spot the Suspect, Library Helper and Desk Dash
##     (START). Playing is optional: any order, or none; every other game still plays as usual.
##   - A mission is done when its game finishes with its target reached, by any route (the NPC,
##     the picker): the board's ended() with "completed". Each one rewards on its own: its XP
##     (data/activities.json "mission_xp", default XP) through achievements.gd, and the
##     "mission" event (the mission_1 / 5 / 20 achievements). No reward for doing all three.
##   - A done slot turns grey with "A new mission in 9:59": REFRESH seconds of real time after it
##     was done (also while the game is closed) it gets a new game.
##   - Rotation: a new game is a learning game that is not in another slot and not the one just
##     done, picked mostly (1 - FAVOURITE) among the games finished least recently (never first),
##     sometimes among the most played (a familiar favourite). Pastimes are never missions.
## No daily reset (user's 10-minute rule; the mockup's "Resets in 14 h" was not adopted).
##
## Saved per profile in missions.json: {"slots": [{"game", "since", "done_at"}]} (unix seconds;
## done_at 0 = active). Missing or broken file: the START set.
const SaveStore := preload("res://scripts/core/save_store.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
const FILE := "missions.json"
const SLOTS := 3
const START := ["lineup_rocco", "library_rosa", "grammar_lana"]
const REFRESH := 600
const XP := 30
const FAVOURITE := 0.25

## A slot's mission was done: its index, game id and the XP it gave.
signal completed(slot: int, game: String, xp: int)
## The slots changed (a mission done or a new one rolled).
signal changed

var slots: Array = []
var rng := RandomNumberGenerator.new()
var _board
## Seconds of real time the tests may add ("now" = system time + offset).
var clock_offset := 0

static var _shared

static func shared():
	if _shared == null:
		_shared = new()
		_shared.rng.randomize()
		_shared.load_saved()
	_shared._watch_board()
	return _shared

func _watch_board() -> void:
	var board = Board.shared()
	if board == _board:
		return
	_board = board
	board.ended.connect(_on_ended)

func now() -> int:
	return Achievements.now() + clock_offset

func load_saved() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	slots = []
	if parsed is Dictionary and parsed.get("slots") is Array:
		for slot in parsed.slots:
			if slot is Dictionary and Board.shared().has(str(slot.get("game", ""))):
				slots.append({"game": str(slot.game), "since": int(slot.get("since", 0)), "done_at": int(slot.get("done_at", 0))})
	if slots.size() != SLOTS:
		slots = []
		for id in START:
			slots.append({"game": id, "since": now(), "done_at": 0})
		save()

func save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), {"slots": slots})

## Rolls new games into slots whose wait is over. Call before showing them (cheap).
func refresh() -> void:
	var rolled := false
	for i in slots.size():
		if int(slots[i].done_at) > 0 and seconds_left(i) <= 0:
			var done: String = slots[i].game
			slots[i] = {"game": pick(done), "since": now(), "done_at": 0}
			rolled = true
	if rolled:
		save()
		changed.emit()

func is_done(i: int) -> bool:
	return int(slots[i].done_at) > 0

## Seconds until slot `i` gets a new mission (0 for an active slot).
func seconds_left(i: int) -> int:
	if not is_done(i):
		return 0
	return maxi(0, int(slots[i].done_at) + REFRESH - now())

## Games of the active (not done) missions.
func active_games() -> Array[String]:
	var out: Array[String] = []
	for slot in slots:
		if int(slot.done_at) == 0:
			out.append(str(slot.game))
	return out

func xp_for(id: String) -> int:
	return int(Board.shared().activities.get(id, {}).get("mission_xp", XP))

## The learning games a mission may ask for.
func candidates() -> Array[String]:
	var out: Array[String] = []
	var board = Board.shared()
	for id in board.activities:
		if board.kind(id) == "learning":
			out.append(str(id))
	return out

## A new game for a slot (not `just_done`, not in another slot).
func pick(just_done: String) -> String:
	var taken: Array = slots.map(func(s): return str(s.game))
	var pool := candidates().filter(func(id): return id != just_done and not taken.has(id))
	if pool.is_empty():
		pool = candidates().filter(func(id): return id != just_done)
	if pool.is_empty():
		return just_done
	var tracker = Achievements.shared()
	var last := func(id: String) -> int: return int(tracker.data.events.get("game." + id, {}).get("last", 0))
	if rng.randf() < FAVOURITE:
		pool.sort_custom(func(a, b): return tracker.count("game." + a) > tracker.count("game." + b))
	else:
		pool.sort_custom(func(a, b): return last.call(a) < last.call(b))
	return pool[rng.randi_range(0, mini(2, pool.size() - 1))]

## The board's ended(): a finished game completes its active mission.
func _on_ended(id: String, summary: Dictionary) -> void:
	if bool(summary.get("completed", false)):
		complete(id)

## Marks the active mission for game `id` done and rewards it; -1 when there is none.
func complete(id: String) -> int:
	for i in slots.size():
		if slots[i].game == id and not is_done(i):
			slots[i].done_at = now()
			save()
			var xp := xp_for(id)
			var tracker = Achievements.shared()
			tracker.add_xp(xp, "mission." + id)
			tracker.note("mission")
			completed.emit(i, id, xp)
			changed.emit()
			return i
	return -1
