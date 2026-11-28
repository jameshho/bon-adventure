extends RefCounted
## Round generation and answer checking for the two police detective games (6 Nov 2026;
## design: docs/evidence/police-detective-20261106/PROMPT.md). Pure data: no scenes, no text. Clues and
## candidates come from data/detective_game.json; the sessions turn clues into phrases.
##
## A round: {"candidates": [Dictionary], "target": index, "clues": [clue dicts], ...}.
## Lineup rounds also carry "instruction" (always ""); candidates are suspects ({"gender",
## "height", "hair", "hair_color", "facial_hair", "nose", "shirt"}) and there are 2 clues.
## Evidence rounds (redesigned 8 Nov 2026) carry "type" ("find" or "report") and ONE clue;
## candidates are objects ({"kind", "word", "size" or "length", "color", "shiny"?,
## "hardness"?, "texture", "weight"}); a report round has one object and "options" (the clue
## and its opposite).
##
## Guarantees (checked by validate(), and by docs/evidence/police-detective-20261106/verify_clues.gd):
## the target matches every clue, every other candidate fails at least one, so exactly one
## answer is right; lineup distractors share a clue with the target and the clue pair differs
## from the previous round's; suspects are never bald with hair colour, women never have a
## beard or moustache, and no two suspects look identical; objects on one table are all
## different kinds, every one shows the clue's property, the evidence clue differs from the
## previous round's, and a report round's right answer is its clue.
const PATH := "res://data/detective_game.json"

var data: Dictionary = {}
## The current level's settings (data/activities.json lineup_rocco / evidence_mimi "levels";
## LEARN-06, 25 Nov 2026), merged over the mode's data by set_level(): the lineup's
## "suspects", "clue_count" and "negation" (false leaves out the clues with "not": no beard),
## the evidence's "objects_on_table" and "rounds".
var _lineup_data: Dictionary = {}
var _evidence_data: Dictionary = {}
## clue id -> times used this session (keeps the tested words balanced).
var _usage: Dictionary = {}
var _last_pair: Array = []

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	data = parsed if parsed is Dictionary else {}
	if data.is_empty():
		push_error("detective_clues: cannot read " + PATH)
	set_level({})

## Merges a level's settings over the data ({} = the game as in the data).
func set_level(settings: Dictionary) -> void:
	_lineup_data = (data.get("lineup", {}) as Dictionary).duplicate()
	_evidence_data = (data.get("evidence", {}) as Dictionary).duplicate()
	for key in settings:
		if key in ["objects_on_table", "rounds"]:
			_evidence_data[key] = settings[key]
		else:
			_lineup_data[key] = settings[key]
	if not bool(_lineup_data.get("negation", true)):
		_lineup_data["clues"] = (_lineup_data.get("clues", []) as Array).filter(func(c): return not (c as Dictionary).has("not"))

func reset() -> void:
	_usage.clear()
	_last_pair.clear()

# --- Matching ----------------------------------------------------------------------------

## Whether `candidate` fits `clue`. Lineup clues name an "attr", evidence clues a "dim"; a
## missing property never matches a positive clue.
static func matches(candidate: Dictionary, clue: Dictionary) -> bool:
	var key: String = str(clue.get("attr", clue.get("dim", "")))
	var value: String = str(candidate.get(key, ""))
	if clue.has("not"):
		return value != str(clue["not"])
	return value != "" and value == str(clue.get("value", ""))

static func matches_all(candidate: Dictionary, clues: Array) -> bool:
	for clue in clues:
		if not matches(candidate, clue):
			return false
	return true

## The first clue `candidate` does not fit ({} when it fits them all).
static func failing_clue(candidate: Dictionary, clues: Array) -> Dictionary:
	for clue in clues:
		if not matches(candidate, clue):
			return clue
	return {}

## "" when the round is sound, otherwise what is wrong with it.
static func validate(round: Dictionary) -> String:
	var candidates: Array = round.get("candidates", [])
	var clues: Array = round.get("clues", [])
	var target: int = int(round.get("target", -1))
	if candidates.is_empty() or clues.is_empty() or target < 0 or target >= candidates.size():
		return "empty round"
	var matching := 0
	for i in candidates.size():
		if matches_all(candidates[i], clues):
			matching += 1
			if i != target:
				return "candidate %d also matches" % i
	if matching != 1:
		return "target does not match"
	if round.has("options"):
		# A report round: one object, two answers (the clue and its opposite), one of them right.
		var options: Array = round.options
		var right := options.filter(func(o): return matches(candidates[target], o))
		if options.size() != 2 or right.size() != 1 or str(right[0].id) != str(clues[0].id):
			return "report answers are not the clue and its opposite"
	for clue in clues:
		if clue.has("dim"):
			for c in candidates:
				if str(c.get(str(clue.dim), "")) == "":
					return "clue %s needs a property some candidate lacks" % clue.id
	for c in candidates:
		if c.has("hair"):
			if str(c.hair) == "bald" and str(c.hair_color) != "":
				return "bald suspect with hair colour"
			if str(c.hair) != "bald" and str(c.hair_color) == "":
				return "hair without colour"
			if str(c.gender) == "f" and str(c.facial_hair) != "none":
				return "woman with facial hair"
	for i in candidates.size():
		for j in range(i + 1, candidates.size()):
			if _same_look(candidates[i], candidates[j]):
				return "candidates %d and %d look the same" % [i, j]
	return ""

static func _same_look(a: Dictionary, b: Dictionary) -> bool:
	if a.has("kind"):
		return str(a.kind) == str(b.kind)
	for key in a:
		if str(a[key]) != str(b.get(key, "")):
			return false
	return true

# --- Lineup ------------------------------------------------------------------------------

func _lineup() -> Dictionary:
	return _lineup_data

func random_suspect(rng: RandomNumberGenerator) -> Dictionary:
	var attributes: Dictionary = _lineup().get("attributes", {})
	var suspect := {}
	suspect["gender"] = "f" if rng.randf() < float(_lineup().get("female_share", 0.5)) else "m"
	for key in attributes:
		suspect[key] = _pick(rng, attributes[key])
	return repair(suspect)

## Makes a suspect possible: no hair colour when bald, a colour otherwise, no facial hair on
## a woman.
static func repair(suspect: Dictionary) -> Dictionary:
	if str(suspect.get("hair", "")) == "bald":
		suspect["hair_color"] = ""
	elif str(suspect.get("hair_color", "")) == "":
		suspect["hair_color"] = "black"
	if str(suspect.get("gender", "")) == "f":
		suspect["facial_hair"] = "none"
	return suspect

## Changes `suspect` so that it fits (`fit` true) or fails `clue`; repairs and returns it.
func _force(suspect: Dictionary, clue: Dictionary, fit: bool, rng: RandomNumberGenerator) -> Dictionary:
	var key: String = str(clue.attr)
	var choices: Array = (_lineup().get("attributes", {}) as Dictionary).get(key, [])
	var options: Array = []
	for value in choices:
		var probe := suspect.duplicate()
		probe[key] = value
		if matches(probe, clue) == fit:
			options.append(value)
	if options.is_empty():
		return suspect
	suspect[key] = _pick(rng, options)
	# A beard or moustache needs a man; hair colour needs hair.
	if key == "facial_hair" and str(suspect[key]) != "none":
		suspect["gender"] = "m"
	if key == "hair_color":
		if str(suspect.get("hair", "")) == "bald":
			suspect["hair"] = _pick(rng, ["long", "short"])
	if str(suspect.get("hair", "")) != "bald" and str(suspect.get("hair_color", "")) == "":
		suspect["hair_color"] = _pick(rng, (_lineup().get("attributes", {}) as Dictionary).get("hair_color", ["black"]))
	return repair(suspect)

func generate_lineup(rng: RandomNumberGenerator) -> Dictionary:
	var count: int = int(_lineup().get("suspects", 5))
	var clue_count: int = int(_lineup().get("clue_count", 2))
	var clues_data: Array = _lineup().get("clues", [])
	for attempt in 200:
		var target := random_suspect(rng)
		var clues := _choose_clues(rng, target, clues_data, clue_count, [target])
		if clues.size() < clue_count:
			continue
		var candidates: Array = [target]
		var tries := 0
		while candidates.size() < count and tries < 200:
			tries += 1
			var other := random_suspect(rng)
			# Fit every clue but one (a near miss), so the answer is not obvious.
			var miss: int = (candidates.size() - 1) % clues.size()
			for k in clues.size():
				other = _force(other, clues[k], k != miss, rng)
			if matches_all(other, clues) or candidates.any(func(c): return _same_look(c, other)):
				continue
			candidates.append(other)
		if candidates.size() < count:
			continue
		var round := _shuffled({"candidates": candidates, "target": 0, "clues": clues, "instruction": ""}, rng)
		if validate(round) == "":
			_remember(clues)
			return round
	push_error("detective_clues: no valid lineup")
	return {}

# --- Evidence ----------------------------------------------------------------------------
# Redesigned 8 Nov 2026: one property word decides each round (data "evidence.rounds").

func _evidence() -> Dictionary:
	return _evidence_data

const DIMENSIONS := ["size", "length", "color", "hardness", "texture", "weight"]

## An object of `kind` with random looks; `fixed` ({dim: value}) forces properties (a value
## the kind cannot have is ignored). "weight_from" derives the weight from another property,
## and forcing the weight sets that property instead (a heavy block is a long one).
func random_object(kind: String, rng: RandomNumberGenerator, fixed: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = _evidence().get("objects", {}).get(kind, {})
	var item := {"kind": kind, "word": str(spec.get("word", kind))}
	var wanted := fixed.duplicate()
	var link: Dictionary = spec.get("weight_from", {})
	if wanted.has("weight") and not link.is_empty():
		for key in link:
			if key != "dim" and str(link[key]) == str(wanted.weight):
				wanted[str(link.dim)] = key
		wanted.erase("weight")
	for dim in DIMENSIONS:
		if not spec.has(dim):
			continue
		var values: Array = spec[dim]
		item[dim] = str(wanted[dim]) if wanted.has(dim) and values.has(wanted[dim]) else _pick(rng, values)
	if not link.is_empty():
		item["weight"] = str(link.get(str(item.get(str(link.dim), "")), ""))
	if bool(spec.get("shiny", false)):
		item["shiny"] = true
	return item

## The values `kind` can have on `dim` ([] when it has none; derived weights included).
func values_of(kind: String, dim: String) -> Array:
	var spec: Dictionary = _evidence().get("objects", {}).get(kind, {})
	if spec.has(dim):
		return spec[dim]
	var link: Dictionary = spec.get("weight_from", {})
	if dim == "weight" and not link.is_empty():
		var found: Array = []
		for key in link:
			if key != "dim" and not found.has(str(link[key])):
				found.append(str(link[key]))
		return found
	return []

## The clue whose value is `clue`'s opposite (hard -> soft).
func opposite(clue: Dictionary) -> Dictionary:
	for other in _evidence().get("clues", []):
		if str(other.dim) == str(clue.dim) and str(other.value) == str(clue.get("opposite", "")):
			return other
	return {}

## The round type of round `number` (0-based) from data "rounds" ("find" or "report").
func round_type(number: int) -> String:
	var types: Array = _evidence().get("rounds", ["find"])
	return str(types[number % types.size()]) if not types.is_empty() else "find"

## A "find" round: four objects, exactly one has the clue's value and the other three have the
## opposite one ("¿Qué objeto es blando?"). A "report" round: one object, and the clue and its
## opposite as the two answers ("¿Es la piedra dura o blanda?"), in "options".
func generate_evidence(rng: RandomNumberGenerator, type: String = "find") -> Dictionary:
	var count: int = int(_evidence().get("objects_on_table", 4)) if type == "find" else 1
	var kinds: Array = (_evidence().get("objects", {}) as Dictionary).keys()
	var clues_data: Array = (_evidence().get("clues", []) as Array).duplicate()
	_shuffle(clues_data, rng)
	# The clue whose word the word memory wants first (word_memory.gd, 24 Nov 2026: due, then
	# allowed new, then the least well remembered), the least used among equals.
	var ranked: Array = preload("res://scripts/learning/word_memory.gd").shared().order(words_of(clues_data), rng)
	var rank := func(clue) -> int:
		var words: Array = words_of([clue])
		var i := ranked.find(str(words[0])) if not words.is_empty() else -1
		return i if i >= 0 else ranked.size()
	clues_data.sort_custom(func(a, b): return rank.call(a) * 1000 + int(_usage.get(a.id, 0)) < rank.call(b) * 1000 + int(_usage.get(b.id, 0)))
	for clue in clues_data:
		if _last_pair == [str(clue.id)] and clues_data.size() > 1:
			continue
		var other := opposite(clue)
		var fitting: Array = kinds.filter(func(k): return values_of(k, str(clue.dim)).has(str(clue.value)))
		var opposed: Array = kinds.filter(func(k): return values_of(k, str(clue.dim)).has(str(other.get("value", ""))))
		if fitting.is_empty() or other.is_empty():
			continue
		var target_kind := str(_pick(rng, fitting))
		opposed.erase(target_kind)
		if opposed.size() < count - 1:
			continue
		_shuffle(opposed, rng)
		var candidates: Array = [random_object(target_kind, rng, {str(clue.dim): str(clue.value)})]
		for kind in opposed.slice(0, count - 1):
			candidates.append(random_object(kind, rng, {str(clue.dim): str(other.value)}))
		var round := {"type": type, "candidates": candidates, "target": 0, "clues": [clue]}
		if type == "report":
			var options: Array = [clue, other]
			_shuffle(options, rng)
			round["options"] = options
		round = _shuffled(round, rng)
		if validate(round) == "":
			_remember([clue])
			return round
	push_error("detective_clues: no valid evidence round")
	return {}

# --- Shared ------------------------------------------------------------------------------

## `count` clues that fit `target`, on different properties, preferring the least used and
## never the previous round's pair (the lineup).
func _choose_clues(rng: RandomNumberGenerator, target: Dictionary, clues_data: Array, count: int, _candidates: Array) -> Array:
	var fitting: Array = clues_data.filter(func(c): return matches(target, c))
	_shuffle(fitting, rng)
	fitting.sort_custom(func(a, b): return int(_usage.get(a.id, 0)) < int(_usage.get(b.id, 0)))
	for attempt in 40:
		var picked: Array = []
		var keys: Array = []
		for clue in fitting:
			var key := str(clue.get("attr", clue.get("dim", "")))
			if keys.has(key):
				continue
			# Mostly the least used, sometimes a random one, so pairs vary.
			if rng.randf() < 0.35 and attempt < 39:
				continue
			picked.append(clue)
			keys.append(key)
			if picked.size() == count:
				break
		if picked.size() < count:
			continue
		var ids: Array = picked.map(func(c): return str(c.id))
		ids.sort()
		if ids == _last_pair:
			continue
		return picked
	return []

func _remember(clues: Array) -> void:
	var ids: Array = []
	for clue in clues:
		_usage[clue.id] = int(_usage.get(clue.id, 0)) + 1
		ids.append(str(clue.id))
	ids.sort()
	_last_pair = ids

## The candidates in random order; "target" follows the target.
func _shuffled(round: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var order: Array = range(round.candidates.size())
	_shuffle(order, rng)
	var shuffled: Array = []
	for i in order:
		shuffled.append(round.candidates[i])
	round["target"] = order.find(int(round.target))
	round["candidates"] = shuffled
	return round

## A key of `weights` ({key: weight}) picked in proportion to its weight ("" when empty).
static func _weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var roll := rng.randf() * total
	for key in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return str(key)
	return ""

static func _pick(rng: RandomNumberGenerator, values: Array) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)] if not values.is_empty() else ""

static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = values[i]
		values[i] = values[j]
		values[j] = swap

## Every word key the clues practise, in order, without repeats.
static func words_of(clues: Array) -> Array:
	var found: Array = []
	for clue in clues:
		for key in clue.get("words", []):
			if not found.has(key):
				found.append(key)
	return found
