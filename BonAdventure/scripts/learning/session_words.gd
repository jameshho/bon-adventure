extends RefCounted
## The words of one minigame session, for its results screen (user design, 21 Nov 2026;
## docs/guides/MINIGAMES.md#results-screen). It listens to the practice tracker
## (practice_log.gd `recorded`) and sorts every word the session recorded into:
##   new        its first record ever in this foreign language (a first meaningful encounter)
##   practiced  it had been recorded before (in any game)
##   struggled  answered wrong, or its translation was shown, at least once in this session
##   known      became known this session: the word memory's stability crossed the learned
##              threshold on one of this session's answers (word_memory.gd is_known() and
##              known_changed; decision D9, 25 Nov 2026) and the word is still known at the end
##
##   SessionWords.shared().start("library_rosa")   when the game starts
##   SessionWords.shared().summary()               {"game", "new": [keys], "practiced": [keys],
##                                                  "struggled": [keys], "known": [keys],
##                                                  "all": [keys]}
## Records of other games are ignored. Runtime only: nothing is saved here.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const WordMemory := preload("res://scripts/learning/word_memory.gd")

static var _shared

var game := ""
## Word keys in the order they were first recorded this session.
var order: Array = []
var _new: Dictionary = {}
var _struggled: Dictionary = {}
## Words that became known this session (and have not dropped back).
var _known: Dictionary = {}

static func shared():
	if _shared == null:
		_shared = new()
		PracticeLog.shared().recorded.connect(_shared._on_recorded)
		WordMemory.shared().known_changed.connect(_shared._on_known_changed)
	return _shared

## Starts a session of `game_id` (an activities.json id): forgets the previous one.
func start(game_id: String) -> void:
	game = game_id
	order.clear()
	_new.clear()
	_struggled.clear()
	_known.clear()

func summary() -> Dictionary:
	var fresh: Array = order.filter(func(k): return _new.has(k))
	var known: Array = order.filter(func(k): return not _new.has(k))
	return {"game": game, "new": fresh, "practiced": known, "struggled": order.filter(func(k): return _struggled.has(k)), "known": order.filter(func(k): return _known.has(k)), "all": order.duplicate()}

## Up to `count` words worth showing: new ones first (struggled before others), then familiar
## words the player struggled with, then words that became known (since 25 Nov 2026, LEARN-04),
## then the rest (user: 3-5, new and struggled first).
func highlights(count: int) -> Array:
	var ranked: Array = []
	for group in [[true, true], [true, false], [false, true]]:
		for key in order:
			if _new.has(key) == group[0] and _struggled.has(key) == group[1]:
				ranked.append(key)
	for key in order:
		if _known.has(key) and not ranked.has(key):
			ranked.append(key)
	for key in order:
		if not ranked.has(key):
			ranked.append(key)
	return ranked.slice(0, count)

func is_new(key: String) -> bool:
	return _new.has(key)

func became_known(key: String) -> bool:
	return _known.has(key)

func _on_known_changed(game_id: String, key: String, known: bool) -> void:
	if game_id != game or game == "":
		return
	if known:
		_known[key] = true
	else:
		_known.erase(key)

func _on_recorded(game_id: String, outcomes: Dictionary) -> void:
	if game_id != game or game == "":
		return
	var log = PracticeLog.shared()
	var language: String = Lexicon.shared().foreign
	for key in outcomes:
		if str(outcomes[key]) != "positive":
			_struggled[key] = true
		if order.has(key):
			continue
		order.append(key)
		# The tracker counts this record already: a total of one means it is the first ever.
		var total := 0
		for n in log.totals(language, key).values():
			total += int(n)
		if total <= 1:
			_new[key] = true
