extends RefCounted
## The Alta Cocina restaurant game's order engine (6 Nov 2026): menus drawn from the dish
## catalog, the property matcher, and order generation. Pure logic, no scene and no text:
## an order holds requirements and Lexicon references (Lexicon.text()), so it renders in
## any language pair. Data: data/restaurant_game.json (schema in its "about").
##
## A requirement: {"kind": "taste" | "temp" | "tag", "prop": id, "op": op}
##   taste  op any (1-3, "dulce"), little (1, "un poco dulce"), very (3, "muy dulce"),
##          none (0, "nada dulce"), not_very (0-2, "no muy dulce")
##   temp   op is: the dish's temperature level is one of the word's levels (frío = 0-1)
##   tag    op has / not: an ingredient in the dish's "has" (textures and extras were
##          removed on 11 Nov 2026: the game is about taste, temperature and ingredients)
## An order: {"course", "target" (dish id), "reqs" [requirements]}. Positive requirements
## come first (descriptions before ingredients), then at most one negative one.
##
## Generation (make_order): a dish of the course not served yet; candidate requirement sets
## of the rolled size from that dish's own properties; only sets that EXACTLY ONE dish of
## the course on the current menu meets are kept; among those, sets with more partly
## matching dishes (good distractors) and fewer recently asked properties win. If no set of
## that size is unique, it tries one more requirement (up to difficulty.max_size), then fewer
## (since 11 Nov 2026: with only tastes, temperature and ingredients some dishes have just two
## facts), then another dish. It never returns an order the menu cannot fulfil.
const PATH := "res://data/restaurant_game.json"
const TAG_GROUPS := ["ingredient"]
const NEGATIVE_OPS := ["none", "not_very", "not"]

static var _data: Dictionary = {}

var rng: RandomNumberGenerator
var difficulty: Dictionary = {}
## course -> [dish dictionaries] on the current menu, in menu order.
var menu: Dictionary = {}

## `overrides` replaces difficulty settings (tests force intensity and negation on).
func _init(random: RandomNumberGenerator = null, overrides: Dictionary = {}) -> void:
	rng = random if random != null else RandomNumberGenerator.new()
	difficulty = data().get("difficulty", {}).duplicate(true)
	difficulty.merge(overrides, true)

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
		if _data.is_empty():
			push_error("restaurant_orders: cannot read " + PATH)
	return _data

static func courses() -> Array:
	return data().get("courses", [])

static func dishes() -> Array:
	return data().get("dishes", [])

static func dish(id: String) -> Dictionary:
	for entry in dishes():
		if str(entry.id) == id:
			return entry
	return {}

static func properties() -> Dictionary:
	return data().get("properties", {})

static func taste_ids() -> Array:
	return properties().get("taste", {}).keys()

static func temperature_words() -> Dictionary:
	return properties().get("temperature_words", {})

## The schema entry of a tag (an ingredient) and its group, or {}.
static func tag_def(id: String) -> Dictionary:
	for group in TAG_GROUPS:
		var defs: Dictionary = properties().get(group, {})
		if defs.has(id):
			var entry: Dictionary = defs[id].duplicate()
			entry["group"] = group
			return entry
	return {}

static func tag_ids(group: String) -> Array:
	return properties().get(group, {}).keys()

# --- Dish properties ---------------------------------------------------------------------

static func taste(entry: Dictionary, id: String) -> int:
	return int(entry.get("taste", {}).get(id, 0))

static func temperature(entry: Dictionary) -> int:
	return int(entry.get("temperature", 2))

static func has_tag(entry: Dictionary, id: String) -> bool:
	return entry.get("has", []).has(id)

## Does the dish meet one requirement?
static func meets(entry: Dictionary, req: Dictionary) -> bool:
	match str(req.kind):
		"taste":
			var v := taste(entry, str(req.prop))
			match str(req.op):
				"any": return v >= 1
				"little": return v == 1
				"very": return v == 3
				"none": return v == 0
				"not_very": return v <= 2
		"temp":
			for level in temperature_words().get(str(req.prop), {}).get("levels", []):
				if int(level) == temperature(entry):
					return true
			return false
		"tag":
			return has_tag(entry, str(req.prop)) == (str(req.op) == "has")
	return false

static func matches(entry: Dictionary, reqs: Array) -> bool:
	for req in reqs:
		if not meets(entry, req):
			return false
	return true

static func count_matches(section: Array, reqs: Array) -> int:
	var count := 0
	for entry in section:
		if matches(entry, reqs):
			count += 1
	return count

static func is_negative(req: Dictionary) -> bool:
	return NEGATIVE_OPS.has(str(req.op))

## The first requirement the dish does not meet (positives first), or {} when it meets all.
static func first_miss(entry: Dictionary, reqs: Array) -> Dictionary:
	for req in reqs:
		if not meets(entry, req):
			return req
	return {}

## The property id a requirement is about (taste id, temperature word, tag id).
static func prop_of(req: Dictionary) -> String:
	return str(req.prop)

# --- Menus ------------------------------------------------------------------------------

## A fresh random menu: for each course, menu_size dishes of that course, re-rolled until
## at least one dish has a valid order.
func new_menu() -> void:
	menu.clear()
	var size: Array = data().get("menu_size", [4, 5])
	for course in courses():
		var pool: Array = dishes().filter(func(d): return str(d.course) == str(course))
		var best: Array = []
		for attempt in 30:
			_shuffle(pool)
			var count := clampi(rng.randi_range(int(size[0]), int(size[1])), 1, pool.size())
			var pick: Array = pool.slice(0, count)
			best = pick
			if _orderable(pick):
				break
		menu[course] = best

func _orderable(section: Array) -> bool:
	for entry in section:
		for n in range(1, int(difficulty.get("max_size", 3)) + 1):
			if not _unique_sets(entry, section, n, false, false).is_empty():
				return true
	return false

# --- Orders -----------------------------------------------------------------------------

## A validated order for `course` on the current menu, or {}. `served` lists dish ids not to
## ask for again when another dish is possible; `recent` lists recently asked property ids.
func make_order(course: String, served: Array = [], recent: Array = []) -> Dictionary:
	var section: Array = menu.get(course, [])
	if section.is_empty():
		return {}
	var intensity: bool = rng.randf() < float(difficulty.get("intensity_chance", 0.0))
	var negation: bool = rng.randf() < float(difficulty.get("negation_chance", 0.0))
	var size := _pick_size()
	var targets: Array = section.filter(func(d): return not served.has(str(d.id)))
	if targets.is_empty():
		targets = section.duplicate()
	_shuffle(targets)
	# Plain orders are the fallback, so a menu that cannot say "muy" or "pero no" still works.
	for options in [[intensity, negation], [false, false]]:
		for target in targets:
			for n in range(size, int(difficulty.get("max_size", 3)) + 1) + range(size - 1, 0, -1):
				var reqs := _best_set(target, section, n, options[0], options[1], recent)
				if not reqs.is_empty():
					return {"course": course, "target": str(target.id), "reqs": reqs}
	return {}

func _pick_size() -> int:
	var weights: Dictionary = difficulty.get("sizes", {"1": 1})
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var roll := rng.randf() * total
	for key in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return maxi(1, int(key))
	return 1

## The requirements the target dish can truthfully be described with.
## positive: tastes it has (any; with intensity also little / very), its temperature word,
## its tags. negative (with negation): tastes it lacks or does not have strongly, and tags
## it lacks, but only where another dish of the section differs (so the negation matters).
func facts(target: Dictionary, section: Array, intensity: bool, negation: bool) -> Dictionary:
	var positive: Array = []
	var negative: Array = []
	for id in taste_ids():
		var v := taste(target, id)
		if v > 0:
			positive.append({"kind": "taste", "prop": id, "op": "any"})
			if intensity and v == 1:
				positive.append({"kind": "taste", "prop": id, "op": "little"})
			if intensity and v == 3:
				positive.append({"kind": "taste", "prop": id, "op": "very"})
		if negation:
			var others: Array = section.filter(func(d): return d != target)
			if v == 0 and others.any(func(d): return taste(d, id) > 0):
				negative.append({"kind": "taste", "prop": id, "op": "none"})
			elif v > 0 and v <= 2 and others.any(func(d): return taste(d, id) == 3):
				negative.append({"kind": "taste", "prop": id, "op": "not_very"})
	for word in temperature_words():
		var req := {"kind": "temp", "prop": word, "op": "is"}
		if meets(target, req):
			positive.append(req)
	for group in TAG_GROUPS:
		for id in tag_ids(group):
			if has_tag(target, id):
				positive.append({"kind": "tag", "prop": id, "op": "has"})
			elif negation and bool(properties()[group][id].get("negate", true)) and section.any(func(d): return d != target and has_tag(d, id)):
				negative.append({"kind": "tag", "prop": id, "op": "not"})
	return {"positive": positive, "negative": negative}

## Every requirement set of size n that only the target meets in the section: with
## negation n-1 positives plus one negative (n >= 2), otherwise n positives. _best_set
## chooses among them.
func _unique_sets(target: Dictionary, section: Array, n: int, intensity: bool, negation: bool) -> Array:
	var f := facts(target, section, intensity, negation)
	var sets: Array = []
	if negation:
		if n < 2:
			return sets
		for combo in _combinations(f.positive, n - 1):
			for neg in f.negative:
				var reqs: Array = combo + [neg]
				if _valid(reqs) and count_matches(section, reqs) == 1:
					sets.append(reqs)
		return sets
	for combo in _combinations(f.positive, n):
		if _valid(combo) and count_matches(section, combo) == 1:
			sets.append(combo)
	return sets

func _best_set(target: Dictionary, section: Array, n: int, intensity: bool, negation: bool, recent: Array) -> Array:
	var sets := _unique_sets(target, section, n, intensity, negation)
	var best: Array = []
	var best_score := -INF
	for reqs in sets:
		var score := rng.randf() * .75
		# Good distractors: dishes that meet some, but not all, of the requirements.
		for entry in section:
			if entry == target:
				continue
			var met := 0
			for req in reqs:
				if meets(entry, req):
					met += 1
			if met > 0:
				score += 1.0
		for req in reqs:
			if recent.has(prop_of(req)):
				score -= 2.0
			if str(req.op) in ["little", "very"]:
				score += 2.0
		if score > best_score:
			best_score = score
			best = reqs
	return _ordered(best)

## One requirement per property; at most one temperature; intensity and plain wording of
## the same taste never together.
static func _valid(reqs: Array) -> bool:
	var seen := {}
	var temps := 0
	for req in reqs:
		var key := str(req.kind) + ":" + str(req.prop)
		if seen.has(key):
			return false
		seen[key] = true
		if str(req.kind) == "temp":
			temps += 1
	return temps <= 1

## Descriptions before ingredients, the negative one last (natural phrasing: algo caliente
## y con pollo, pero nada picante).
static func _ordered(reqs: Array) -> Array:
	var rank := func(req: Dictionary) -> int:
		if is_negative(req):
			return 3
		if str(req.kind) == "tag" and str(tag_def(str(req.prop)).get("group", "")) == "ingredient":
			return 2
		return 1 if str(req.kind) == "temp" else 0
	var out := reqs.duplicate()
	out.sort_custom(func(a, b): return rank.call(a) < rank.call(b))
	return out

static func _combinations(items: Array, n: int) -> Array:
	var out: Array = []
	if n <= 0 or n > items.size():
		return out
	if n == 1:
		for item in items:
			out.append([item])
		return out
	for i in range(items.size() - n + 1):
		for rest in _combinations(items.slice(i + 1), n - 1):
			out.append([items[i]] + rest)
	return out

func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = list[i]
		list[i] = list[j]
		list[j] = swap

# --- Text references (rendered by the Lexicon in any language) ---------------------------

## The word key a requirement teaches (the poster word).
static func word_of(req: Dictionary) -> String:
	match str(req.kind):
		"taste": return str(properties().get("taste", {}).get(str(req.prop), {}).get("word", ""))
		"temp": return str(temperature_words().get(str(req.prop), {}).get("word", ""))
		"tag": return str(tag_def(str(req.prop)).get("word", ""))
	return ""

## One requirement as an order fragment: "muy dulce", "frío", "con pollo", "sin queso".
static func fragment(req: Dictionary) -> Dictionary:
	var word := {"word": word_of(req)}
	match str(req.kind):
		"taste":
			var phrase: String = {"any": "f_plain", "little": "f_little", "very": "f_very", "none": "f_none", "not_very": "f_not_very"}.get(str(req.op), "f_plain")
			return {"phrase": "restaurant." + phrase, "values": {"p": word}}
		"tag":
			return {"phrase": str(tag_def(str(req.prop)).get("with" if str(req.op) == "has" else "without", ""))}
	return {"phrase": "restaurant.f_plain", "values": {"p": word}}

## All of an order's requirements as one {want} value.
static func want(reqs: Array) -> Dictionary:
	var positive: Array = []
	var negative: Array = []
	for req in reqs:
		(negative if is_negative(req) else positive).append(fragment(req))
	var out: Dictionary = {}
	match positive.size():
		0: out = {}
		1: out = positive[0]
		2: out = {"phrase": "restaurant.and", "values": {"a": positive[0], "b": positive[1]}}
		_: out = {"phrase": "restaurant.list3", "values": {"a": positive[0], "b": positive[1], "c": positive[2]}}
	if not negative.is_empty():
		out = negative[0] if out.is_empty() else {"phrase": "restaurant.but", "values": {"a": out, "b": negative[0]}}
	return out

static func order_ref(order: Dictionary) -> Dictionary:
	return {"phrase": "restaurant.order_" + str(order.course), "values": {"want": want(order.reqs)}}

## One wrong dish in Twinkle's report: `name` wanted something `req` (the requirement the dish
## missed), but the player served `dish_word` (its words.json key). `also`: a second or third
## wrong dish of the same order ("También quería algo ...").
static func miss_ref(req: Dictionary, dish_word: String, name: String, also := false) -> Dictionary:
	return {"phrase": "restaurant.miss_also" if also else "restaurant.miss_first", "values": {"name": name, "want": fragment(req), "dish": {"word": dish_word}}}

## Sentences one after the other (several requests, several wrong dishes).
static func sentences(refs: Array) -> Dictionary:
	if refs.is_empty():
		return {}
	var out: Dictionary = refs[0]
	for k in range(1, refs.size()):
		out = {"phrase": "restaurant.sentences", "values": {"a": out, "b": refs[k]}}
	return out

## Twinkle's report of a wrong order: `misses` [[requirement, served dish word], ...].
static func report_ref(misses: Array, name: String) -> Dictionary:
	var refs: Array = []
	for k in misses.size():
		refs.append(miss_ref(misses[k][0], str(misses[k][1]), name, k > 0))
	return {"phrase": "restaurant.report_wrong", "values": {"misses": sentences(refs)}}

## The customer's first line: "Quisiera pedir una entrada y una bebida."
static func intro_ref(course_ids: Array) -> Dictionary:
	var items: Array = course_ids.map(func(c): return {"phrase": "restaurant.item_" + str(c)})
	var joined: Dictionary = items[0] if items.size() == 1 else ({"phrase": "restaurant.and", "values": {"a": items[0], "b": items[1]}} if items.size() == 2 else {"phrase": "restaurant.list3", "values": {"a": items[0], "b": items[1], "c": items[2]}})
	return {"phrase": "restaurant.order_intro", "values": {"items": joined}}

static func course_ref(course: String) -> Dictionary:
	return {"phrase": "restaurant.course_" + course}
