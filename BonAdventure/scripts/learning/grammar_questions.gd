extends RefCounted
## The Grammar Classroom's question banks (data/grammar_class/<code>.json, one per taught
## language; guide: docs/guides/GRAMMAR_CLASS.md). Loads the bank of the language being learned, picks
## a session's questions without repeats and shuffles each question's four answers over the
## four answer desks. Knows nothing about the classroom: a new language needs only a new file.
##
## A question: {"id", "topic", "level", "text" (one ___ blank), "choices" (4), "answer",
## "explain" {code: text}, "meaning"? {code: text}, "noun"? (words.json key, Chinese)}.
## The answer is the word itself, so a shuffle can never change which desk is right.
const DIR := "res://data/grammar_class/"
const BLANK := "___"
const CHOICES := 4

var language := ""
var topics: Dictionary = {}
var questions: Array = []

## The bank for `code`, or false when that language has no class (no file, or no questions).
func load_bank(code: String) -> bool:
	language = code
	topics = {}
	questions = []
	var path := DIR + code + ".json"
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("grammar_questions: %s is not a JSON object" % path)
		return false
	topics = parsed.get("topics", {})
	questions = parsed.get("questions", [])
	return not questions.is_empty()

static func has_bank(code: String) -> bool:
	return FileAccess.file_exists(DIR + code + ".json")

## `count` different questions (all of them when the bank is smaller): those on a noun the word
## memory wants first (word_memory.gd, 24 Nov 2026: due, then allowed new), the rest in random order.
func pick(count: int, rng: RandomNumberGenerator) -> Array:
	var order: Array = questions.duplicate()
	shuffle(order, rng)
	var nouns: Array = order.map(func(q): return str(q.get("noun", ""))).filter(func(n): return n != "")
	if not nouns.is_empty():
		var ranked: Array = preload("res://scripts/learning/word_memory.gd").shared().order(nouns, rng)
		var rank := func(q) -> int:
			var i := ranked.find(str(q.get("noun", "")))
			return i if i >= 0 else ranked.size()
		order.sort_custom(func(a, b): return rank.call(a) < rank.call(b))
	return order.slice(0, mini(count, order.size()))

## The question's four answers in random desk order.
static func desk_answers(question: Dictionary, rng: RandomNumberGenerator) -> Array:
	var answers: Array = question.get("choices", []).duplicate()
	shuffle(answers, rng)
	return answers

static func shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept: Variant = list[i]
		list[i] = list[j]
		list[j] = kept

## The sentence with the blank shown as a line (the board while a question is open).
static func blanked(question: Dictionary) -> String:
	return str(question.get("text", "")).replace(BLANK, "＿＿＿")

## The sentence with the right answer in the blank (the board during feedback).
static func filled(question: Dictionary) -> String:
	return str(question.get("text", "")).replace(BLANK, str(question.get("answer", "")))

## Every rule a bank must follow, for tools/language_check.gd: `bank` is the parsed file of
## language `code`; `others` are the languages that may read its explanations (every playable
## language but `code`); `words` is the parsed words.json "words".
static func problems(bank: Dictionary, code: String, others: Array, words: Dictionary) -> PackedStringArray:
	var found: PackedStringArray = []
	if str(bank.get("language", "")) != code:
		found.append("%s.json: 'language' is not '%s'" % [code, code])
	var topics_in: Dictionary = bank.get("topics", {})
	var ids := {}
	var list: Array = bank.get("questions", [])
	if list.size() < 10:
		found.append("%s.json: %d questions; a session needs 10" % [code, list.size()])
	for question in list:
		var id := str(question.get("id", ""))
		var where := "%s.json %s" % [code, id]
		if id == "" or ids.has(id):
			found.append(where + ": missing or repeated id")
		ids[id] = true
		if not topics_in.has(str(question.get("topic", ""))):
			found.append(where + ": unknown topic '%s'" % question.get("topic", ""))
		var text := str(question.get("text", ""))
		if text.count(BLANK) != 1:
			found.append(where + ": needs exactly one %s" % BLANK)
		var choices: Array = question.get("choices", [])
		var unique := {}
		for choice in choices:
			unique[str(choice).strip_edges()] = true
		if choices.size() != CHOICES or unique.size() != CHOICES or unique.has(""):
			found.append(where + ": needs %d different, non-empty choices" % CHOICES)
		if not choices.has(question.get("answer", null)):
			found.append(where + ": the answer is not one of the choices")
		for other in others:
			if str(question.get("explain", {}).get(other, "")) == "":
				found.append(where + ": no explanation in '%s'" % other)
			if question.has("meaning") and str(question.meaning.get(other, "")) == "":
				found.append(where + ": no meaning in '%s'" % other)
		if question.has("noun"):
			var noun: Dictionary = words.get(str(question.noun), {})
			var shown := str(noun.get("text", {}).get(code, ""))
			if shown == "" or not text.contains(shown):
				found.append(where + ": noun '%s' is not the game's word in the sentence" % question.noun)
	for topic in topics_in:
		for other in others:
			if str(topics_in[topic].get("name", {}).get(other, "")) == "":
				found.append("%s.json topic %s: no name in '%s'" % [code, topic, other])
	return found
