extends RefCounted
## Practice tracker (Stage B of the vocabulary tracking work, user decisions 7 Nov 2026; guide:
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#practice-tracker). Counts how each tested word was
## answered in each minigame, per learned (foreign) language:
##   practice_log.json of the active profile (save_store.gd)  {"es": {"apple": {"shop_supermarket": {"positive": 2,
##                              "negative": 1, "translated": 0}}}}
## Word totals are the sums over games; they are not stored. Old saves start at zero.
##
## A minigame tells the shared tracker about one question at a time:
##   begin(game_id, word_keys)  a new question (game ids are data/activities.json ids, e.g.
##                              "shop_supermarket"); an open question is abandoned first
##   first_answer(correct)      only the first call per question counts; `correct` is a bool,
##                              or {word_key: bool} when a question tests several words
##   complete()                 records exactly one outcome per word: translated if the
##                              native meaning was shown before now, else positive / negative
##                              from the first answer (nothing without a first answer)
##   abandon()                  records nothing (quit, walked away, language change)
## Games never call mark_translated() themselves: the translate bubble (translate_button.gd)
## and the word card (vocabulary_hud.gd) emit translation_shown, and switching Native mode on
## mid-question marks every word of it. A question begun in Native mode records nothing.
## Only questions with one clear tested word are tracked (decision 6): see the guide.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const FILE := "practice_log.json"
## The file without an active profile (checks); the game uses SaveStore.path(FILE).
const PATH := "user://" + FILE
const OUTCOMES := ["positive", "negative", "translated"]

## The native meaning was shown: "" for every word of the open question, or one word key
## (the word card of that word).
signal translation_shown(word_key: String)
## A question was recorded (word keys and the outcome of each).
signal recorded(game_id: String, outcomes: Dictionary)

var counts: Dictionary = {}
var _open := false
var _game := ""
var _keys: Array = []
var _language := ""
var _muted := false
var _answered := false
var _first: Dictionary = {}
var _translated: Dictionary = {}

static var _shared
## True while the test launcher runs a game (game_launcher.gd): no question is opened or
## recorded, so testing never changes the learner's practice counts.
var paused := false

static func shared():
	if _shared == null:
		_shared = new()
		_shared.load_saved()
	return _shared

func _init() -> void:
	translation_shown.connect(mark_translated)
	GameSettings.shared().changed.connect(_on_settings_changed)

func load_saved() -> void:
	counts = {}
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	if not parsed is Dictionary:
		return
	# JSON numbers load as floats; counts are whole numbers.
	for language in parsed:
		for key in parsed[language]:
			for game in parsed[language][key]:
				var entry: Dictionary = parsed[language][key][game]
				for outcome in entry:
					entry[outcome] = int(entry[outcome])
	counts = parsed

func save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), counts)

func is_open() -> bool:
	return _open

func game_id() -> String:
	return _game if _open else ""

func begin(game: String, word_keys: Array) -> void:
	if _open:
		abandon()
	if paused:
		return
	_open = true
	_game = game
	_keys = []
	for key in word_keys:
		if not _keys.has(str(key)):
			_keys.append(str(key))
	_language = Lexicon.shared().foreign
	_muted = GameSettings.shared().is_native()
	_answered = false
	_first = {}
	_translated = {}

func mark_translated(word_key: String = "") -> void:
	if not _open:
		return
	if word_key == "":
		for key in _keys:
			_translated[key] = true
	elif _keys.has(word_key):
		_translated[word_key] = true

func first_answer(correct: Variant) -> void:
	if not _open or _answered:
		return
	_answered = true
	for key in _keys:
		_first[key] = bool(correct.get(key, false)) if correct is Dictionary else bool(correct)

func complete() -> void:
	if not _open:
		return
	_open = false
	if _muted:
		return
	var outcomes: Dictionary = {}
	for key in _keys:
		if _translated.has(key):
			outcomes[key] = "translated"
		elif _answered:
			outcomes[key] = "positive" if _first[key] else "negative"
	if outcomes.is_empty():
		return
	var by_word: Dictionary = counts.get(_language, {})
	for key in outcomes:
		var by_game: Dictionary = by_word.get(key, {})
		var entry: Dictionary = by_game.get(_game, {"positive": 0, "negative": 0, "translated": 0})
		entry[outcomes[key]] = int(entry.get(outcomes[key], 0)) + 1
		by_game[_game] = entry
		by_word[key] = by_game
	counts[_language] = by_word
	save()
	recorded.emit(_game, outcomes)

func abandon() -> void:
	_open = false

## {game id: {positive, negative, translated}} for one word in `language`.
func games_for(language: String, word_key: String) -> Dictionary:
	return counts.get(language, {}).get(word_key, {})

## {positive, negative, translated}: the sums over every game.
func totals(language: String, word_key: String) -> Dictionary:
	var sum := {"positive": 0, "negative": 0, "translated": 0}
	var games := games_for(language, word_key)
	for game in games:
		for outcome in OUTCOMES:
			sum[outcome] += int(games[game].get(outcome, 0))
	return sum

func _on_settings_changed() -> void:
	if not _open:
		return
	if Lexicon.shared().foreign != _language:
		abandon()
	elif GameSettings.shared().is_native():
		mark_translated()
