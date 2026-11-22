extends RefCounted
## The achievement log and town stamps (user, 21 Nov 2026; guide: docs/guides/ACHIEVEMENTS.md).
## One tracker for everything the Passport's Exploration and Town Stamps pages show.
##
## EVENTS are what the game reports, one line where the thing happens:
##   Achievements.shared().note("fly_plane")
## An ACHIEVEMENT (data/achievements.json) unlocks the first time its event has happened
## "times" times (default 1); several achievements may share one event (mission_1, mission_5).
## Generated entries: "game.<activity id>" for every minigame (the board's ended() with its
## target reached, noted here) and "stamp.<id>" for every town stamp (stamp_coin.gd).
## An event that no achievement uses is still counted (and logged): new achievements can be
## added later without new code, but counts start when the line was added.
##
## Saved per profile in achievements.json (save_store.gd):
##   {"events": {event: {"count", "first", "last"}},   unix seconds
##    "unlocked": {achievement: unix},
##    "xp": total XP,
##    "log": [{"at", "kind": "unlock" | "event" | "xp", "id", "xp"?}]}   newest last, LOG_MAX kept
## The log holds every unlock, every finished minigame and mission and every XP gain (not
## repeats of small events such as sitting down, which only count). Saves from before
## 21 Nov 2026 have no file: everything starts at zero.
const SaveStore := preload("res://scripts/core/save_store.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const DATA := "res://data/achievements.json"
const FILE := "achievements.json"
const LOG_MAX := 300
## Events whose every occurrence goes in the log (prefixes); others are logged only on unlock.
const LOGGED := ["game.", "mission"]
## Each minigame's icon (shared with the picker's tiles).
const GAME_ICONS := preload("res://scripts/ui/game_launcher.gd").ICONS

## An achievement was reached for the first time: def has "id", "group", "icon", "xp", "name".
signal unlocked(id: String, def: Dictionary)
## Any event (after counting): its new count.
signal noted(event: String, count: int)
## XP was added (missions, achievements): the new total.
signal xp_changed(total: int, added: int)

## id -> {"id", "group", "event", "times", "icon", "xp"}, in display order (order).
var defs: Dictionary = {}
var order: Array[String] = []
var groups: Array = []
## Stamp id -> {"place", "at"} from the data.
var stamps: Dictionary = {}
var data: Dictionary = {}
var _board

static var _shared

static func shared():
	if _shared == null:
		_shared = new()
		_shared.load_defs()
		_shared.load_saved()
	_shared._watch_board()
	return _shared

## Follows the board's ended signal (the board is rebuilt when the profile changes).
func _watch_board() -> void:
	var board = Board.shared()
	if board == _board:
		return
	_board = board
	board.ended.connect(_on_ended)

func load_defs() -> void:
	defs.clear()
	order.clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if not parsed is Dictionary:
		push_error("achievements: cannot read " + DATA)
		return
	groups = parsed.get("groups", [])
	for id in Board.shared().activities:
		_add("game." + str(id), {"group": "games", "icon": str(GAME_ICONS.get(id, "play")), "xp": 10})
	var listed: Dictionary = parsed.get("achievements", {})
	for id in listed:
		_add(str(id), listed[id])
	stamps.clear()
	var stamp_data: Dictionary = parsed.get("stamps", {})
	for id in stamp_data:
		# Only placed stamps exist (an "at"); the others wait for a spot (ACHIEVEMENTS.md).
		if str(id).begins_with("_") or not stamp_data[id] is Dictionary or stamp_data[id].get("at") == null:
			continue
		stamps[str(id)] = stamp_data[id]
		_add("stamp." + str(id), {"group": "stamps", "icon": "star", "xp": 15})

func _add(id: String, def: Dictionary) -> void:
	var entry := def.duplicate()
	entry["id"] = id
	entry["event"] = str(def.get("event", id))
	entry["times"] = maxi(1, int(def.get("times", 1)))
	entry["xp"] = int(def.get("xp", 0))
	entry["group"] = str(def.get("group", "explore"))
	defs[id] = entry
	order.append(id)

func load_saved() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	data = parsed if parsed is Dictionary else {}
	for key in ["events", "unlocked"]:
		if not data.get(key) is Dictionary:
			data[key] = {}
	if not data.get("log") is Array:
		data["log"] = []
	data["xp"] = int(data.get("xp", 0))

func save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), data)

static func now() -> int:
	return int(Time.get_unix_time_from_system())

# --- Reporting --------------------------------------------------------------------------------

## Counts one `event` and unlocks whatever it completes. Returns the achievements it unlocked.
func note(event: String) -> Array[String]:
	var events: Dictionary = data.events
	var entry: Dictionary = events.get(event, {})
	var at := now()
	if entry.is_empty():
		entry["first"] = at
	entry["count"] = int(entry.get("count", 0)) + 1
	entry["last"] = at
	events[event] = entry
	for prefix in LOGGED:
		if event.begins_with(prefix):
			_log({"kind": "event", "id": event})
			break
	var reached: Array[String] = []
	for id in order:
		var def: Dictionary = defs[id]
		if def.event == event and not data.unlocked.has(id) and int(entry.count) >= int(def.times):
			reached.append(id)
	for id in reached:
		_unlock(id)
	save()
	noted.emit(event, int(entry.count))
	return reached

func _unlock(id: String) -> void:
	var def: Dictionary = defs[id]
	data.unlocked[id] = now()
	_log({"kind": "unlock", "id": id})
	if int(def.xp) > 0:
		add_xp(int(def.xp), id, false)
	unlocked.emit(id, def)

## Adds `amount` XP for `reason` (an achievement or "mission.<game id>") and logs it.
func add_xp(amount: int, reason: String, write := true) -> void:
	if amount <= 0:
		return
	data["xp"] = int(data.xp) + amount
	_log({"kind": "xp", "id": reason, "xp": amount})
	if write:
		save()
	xp_changed.emit(int(data.xp), amount)

func _log(item: Dictionary) -> void:
	item["at"] = now()
	var entries: Array = data.log
	entries.append(item)
	if entries.size() > LOG_MAX:
		entries = entries.slice(entries.size() - LOG_MAX)
	data["log"] = entries

## The board's ended(id, summary): a minigame finished with its target reached.
func _on_ended(id: String, summary: Dictionary) -> void:
	if bool(summary.get("completed", false)):
		note("game." + id)

# --- Reading ----------------------------------------------------------------------------------

func is_unlocked(id: String) -> bool:
	return data.unlocked.has(id)

## Unix time it unlocked (0 = not yet).
func unlocked_at(id: String) -> int:
	return int(data.unlocked.get(id, 0))

func count(event: String) -> int:
	return int(data.events.get(event, {}).get("count", 0))

## How far an achievement is: {"have", "need"}.
func progress(id: String) -> Dictionary:
	var def: Dictionary = defs.get(id, {})
	return {"have": mini(count(str(def.get("event", id))), int(def.get("times", 1))), "need": int(def.get("times", 1))}

func xp() -> int:
	return int(data.xp)

func ids_in(group: String) -> Array[String]:
	var out: Array[String] = []
	for id in order:
		if defs[id].group == group:
			out.append(id)
	return out

func unlocked_in(group: String) -> int:
	var n := 0
	for id in ids_in(group):
		if is_unlocked(id):
			n += 1
	return n

func has_stamp(stamp_id: String) -> bool:
	return is_unlocked("stamp." + stamp_id)

## The newest log entries first, at most `limit`.
func recent(limit := 50) -> Array:
	var entries: Array = data.log
	var out: Array = []
	for i in range(entries.size() - 1, maxi(-1, entries.size() - 1 - limit), -1):
		out.append(entries[i])
	return out

## An achievement's name in the native language.
func title(id: String) -> String:
	if id.begins_with("game."):
		return UiText.t("achievements.finish_game", {"game": UiText.t("games." + id.substr(5))})
	if id.begins_with("stamp."):
		return UiText.t("places." + str(stamps.get(id.substr(6), {}).get("place", id.substr(6))))
	return UiText.t("achievements." + id)

## What to do for it (the line under the name).
func hint(id: String) -> String:
	if id.begins_with("game."):
		return UiText.t("games_host." + id.substr(5)) if UiText.has("games_host." + id.substr(5)) else ""
	if id.begins_with("stamp."):
		return UiText.t("achievements.stamp_hint")
	return UiText.t("achievements_hint." + id) if UiText.has("achievements_hint." + id) else ""
