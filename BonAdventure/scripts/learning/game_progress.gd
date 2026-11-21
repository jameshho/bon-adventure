extends RefCounted
## Minigame progression (user approval, 18 Nov 2026; design: docs/game/minigames.md "How games
## get harder", developer notes: docs/guides/MINIGAMES.md#progression). One shared system for
## every game; a game only reads its level's settings.
##
## Levels: data/activities.json "levels" of a game is a list of settings dictionaries, level 1
## first; what a key means belongs to the game (Pay Up!: "max_cents", "step"; Grocery Run: its
## data/shops.json order rules). A game without "levels" has no progression and is ignored here.
##   GameProgress.shared().params(id)   the current level's settings ({} without levels)
##   level(id), unlocked(id), count(id) the current level, the highest unlocked, how many
##   set_level(id, n)                   the picker: any unlocked level
##   best(id, level)                    best stars at a level (0 = never finished)
##
## Stars: when a session of a levelled game ends COMPLETED (activity_board.gd ended(): at least
## the rounds it needed), the share of rounds right first time, needed / (needed + misses), gives
## 3 stars at or above the first "stars_at" value, 2 at or above the second, else 1 (default
## [1.0, 0.6]; data may override it per game: Grocery Run's single order uses [1.0, 0.5], so one
## retry is 2 stars). A game reports misses with Board.add_miss(id); nothing else is needed.
## An unfinished session records nothing.
##
## Unlocks: 3 stars at the highest unlocked level unlocks the next one and makes it current.
## A level never goes down by itself. A session whose rounds were changed in the picker
## ("custom") still records its stars but unlocks nothing.
##
## Saved per profile in game_progress.json (save_store.gd), per learned language like the
## practice log: {"es": {"shop_supermarket": {"level": 2, "unlocked": 2, "best": {"1": 3},
## "plays": 4}}}. Saves from before 18 Nov 2026 have no file: every game starts at level 1.
const Board := preload("res://scripts/learning/activity_board.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const FILE := "game_progress.json"
const STARS_AT := [1.0, 0.6]

## A finished session of a levelled game was scored: result = {"stars", "level" (played),
## "best" (at that level), "level_up" (bool), "new_level" (current level now), "count"}.
signal recorded(id: String, result: Dictionary)

var data: Dictionary = {}
var _board

static var _shared

static func shared():
	if _shared == null:
		_shared = new()
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

func load_saved() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	data = parsed if parsed is Dictionary else {}

func save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), data)

# --- Levels -----------------------------------------------------------------------------------

## The game's level list from data/activities.json ([] = no progression).
func level_list(id: String) -> Array:
	var levels: Variant = Board.shared().activities.get(id, {}).get("levels", [])
	return levels if levels is Array else []

func count(id: String) -> int:
	return level_list(id).size()

func has_levels(id: String) -> bool:
	return count(id) > 0

## This game's record in the learned language (a new one is not stored until written).
func _entry(id: String) -> Dictionary:
	var by_game: Dictionary = data.get(Lexicon.shared().foreign, {})
	var entry: Dictionary = by_game.get(id, {})
	return entry

func _store(id: String, entry: Dictionary) -> void:
	var language: String = Lexicon.shared().foreign
	var by_game: Dictionary = data.get(language, {})
	by_game[id] = entry
	data[language] = by_game
	save()

func unlocked(id: String) -> int:
	return clampi(int(_entry(id).get("unlocked", 1)), 1, maxi(1, count(id)))

func level(id: String) -> int:
	return clampi(int(_entry(id).get("level", 1)), 1, unlocked(id))

## The current level's settings ({} for a game without levels).
func params(id: String) -> Dictionary:
	var levels := level_list(id)
	if levels.is_empty():
		return {}
	var settings: Variant = levels[level(id) - 1]
	return settings if settings is Dictionary else {}

## The picker's level stepper: any unlocked level.
func set_level(id: String, n: int) -> void:
	if not has_levels(id):
		return
	var entry := _entry(id)
	entry["level"] = clampi(n, 1, unlocked(id))
	entry["unlocked"] = unlocked(id)
	_store(id, entry)

func best(id: String, at_level: int) -> int:
	return int(_entry(id).get("best", {}).get(str(at_level), 0))

# --- Stars ------------------------------------------------------------------------------------

## Stars for a finished session of `needed` rounds with `misses` misses.
func stars_for(id: String, needed: int, misses: int) -> int:
	var at: Variant = Board.shared().activities.get(id, {}).get("stars_at", STARS_AT)
	if not at is Array or (at as Array).size() < 2:
		at = STARS_AT
	var share := float(maxi(1, needed)) / float(maxi(1, needed) + maxi(0, misses))
	if share >= float(at[0]) - 0.0001:
		return 3
	if share >= float(at[1]) - 0.0001:
		return 2
	return 1

## The board's ended(id, summary): score a completed session of a levelled game.
func _on_ended(id: String, summary: Dictionary) -> void:
	if not has_levels(id):
		return
	var needed := int(summary.get("needed", maxi(1, int(summary.get("target", 0)))))
	if int(summary.get("rounds", 0)) < needed:
		return
	record(id, needed, int(summary.get("misses", 0)), bool(summary.get("custom", false)))

## Records one finished session (also used by checks). Returns the result it emitted.
func record(id: String, needed: int, misses: int, custom := false) -> Dictionary:
	var played := level(id)
	var stars := stars_for(id, needed, misses)
	var entry := _entry(id)
	var bests: Dictionary = entry.get("best", {})
	bests[str(played)] = maxi(int(bests.get(str(played), 0)), stars)
	entry["best"] = bests
	entry["plays"] = int(entry.get("plays", 0)) + 1
	var open := unlocked(id)
	var level_up := stars == 3 and not custom and played == open and open < count(id)
	if level_up:
		open += 1
		entry["level"] = open
	else:
		entry["level"] = played
	entry["unlocked"] = open
	_store(id, entry)
	var result := {"stars": stars, "level": played, "best": int(bests[str(played)]), "level_up": level_up,
			"new_level": int(entry.level), "count": count(id)}
	recorded.emit(id, result)
	return result
