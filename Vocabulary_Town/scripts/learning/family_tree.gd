extends RefCounted
## One round's family for the hospital family game (Dr. Li): a tree template from
## data/family_game.json filled with foreign-language names (data/names.json), portrait
## species, ages and birth dates counted from the game's shared today (game_clock.gd). Pure logic:
## no nodes and no text; scripts/learning/family_questions.gd asks the questions.
##
## relation(a, b) names what person b is to person a with a Family word key ("mother",
## "cousin", "husband"), or "" when the family words have none (a father-in-law). In-laws
## count the way people speak: an uncle's wife is an aunt, a wife's brother's son a nephew.
## kin(a, b) adds the details languages such as Chinese need to choose a term (Stage 4
## decision, 4 Nov 2026; English and Spanish ignore them): "side" (paternal / maternal: the
## gender of a's parent on the path), "elder" (b, or the blood relative linking them, was born
## before a or before that parent), "link" (m / f: the gender of the blood relative on the
## path: the sibling for a niece, the child for a grandchild, the parent's sibling for a
## cousin or an aunt by marriage) and "by_marriage" (the path runs through a spouse).
const PATH := "res://data/family_game.json"
const MAX_TRIES := 200
## Relationship -> [word for a man or boy, word for a woman or girl] (Family words in words.json).
const WORDS := {
	"married": ["husband", "wife"],
	"dating": ["boyfriend", "girlfriend"],
	"parent": ["father", "mother"],
	"child": ["son", "daughter"],
	"sibling": ["brother", "sister"],
	"grandparent": ["grandfather", "grandmother"],
	"grandchild": ["grandson", "granddaughter"],
	"parent_sibling": ["uncle", "aunt"],
	"sibling_child": ["nephew", "niece"],
	"cousin": ["cousin", "cousin"],
}

static var _rules: Dictionary = {}

## Optional: (word, gender, kin) -> the label the learner sees. Questions compare these, so a
## question is unique in the language being learned (family_session sets the foreign label;
## without it the word key is compared).
var labeler: Callable

var template_id := ""
## id -> {id, gender, name, species, age, birth {y, m, d}, row, col, parents [ids], partner, partner_kind}
var people: Dictionary = {}
## {y, m, d}
var reference: Dictionary = {}

static func rules() -> Dictionary:
	if _rules.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if not parsed is Dictionary:
			push_error("family_tree: missing or unreadable " + PATH)
			return {}
		_rules = parsed
	return _rules

static func template_ids() -> Array:
	return rules().get("trees", {}).keys()

static func parse_date(text: String) -> Dictionary:
	var parts := text.split("-")
	return {"y": int(parts[0]), "m": int(parts[1]), "d": int(parts[2])}

## MM/DD/YYYY digits (user decision, 4 Nov 2026), the same in every language.
static func date_digits(date: Dictionary) -> String:
	return "%02d/%02d/%04d" % [date.m, date.d, date.y]

static func days_in(month: int) -> int:
	# February keeps 28 days so a birthday exists every year.
	return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]

## Fills this tree with a new random family from `template` (a key of "trees"). `names` is
## {"f": [...], "m": [...]}. False when no set of different ages was found.
func setup(template: String, names: Dictionary, rng: RandomNumberGenerator) -> bool:
	template_id = template
	# The game's shared "today" (game_clock.gd; user decision, 5 Nov 2026: one random date
	# per launch, the same as the airport flight game's).
	var today: Dictionary = preload("res://scripts/learning/game_clock.gd").shared().today
	reference = {"y": int(today.y), "m": int(today.m), "d": int(today.d)}
	if not _fill(names, rng):
		push_error("family_tree: could not give '%s' different ages" % template)
		return false
	return true

func _fill(names: Dictionary, rng: RandomNumberGenerator) -> bool:
	var data: Dictionary = rules()
	var spec: Dictionary = data.trees[template_id]
	people.clear()
	for id in spec.people:
		var person: Dictionary = spec.people[id]
		people[id] = {"id": id, "gender": str(person.gender), "row": int(person.row), "col": float(person.col),
			"parents": person.get("parents", []).duplicate(), "partner": str(person.get("partner", "")),
			"partner_kind": str(person.get("partner_kind", ""))}
	# Partners are declared on one side; link both.
	for id in people:
		var partner: String = people[id].partner
		if partner != "" and people.has(partner):
			people[partner].partner = id
			people[partner].partner_kind = people[id].partner_kind
	var declared: Dictionary = {}
	for id in spec.people:
		if spec.people[id].has("partner"):
			declared[id] = true
	for attempt in MAX_TRIES:
		if _assign_ages(spec, declared, rng):
			_assign_names(names, rng)
			return true
	return false

func _assign_ages(spec: Dictionary, declared: Dictionary, rng: RandomNumberGenerator) -> bool:
	var data: Dictionary = rules()
	var gap: Array = data.get("gap", [24, 30])
	var spread := int(data.get("partner_spread", 4))
	var root_age: Array = spec.get("root_age", [66, 80])
	var ages: Dictionary = {}
	for pass_index in people.size() + 1:
		for id in people:
			if ages.has(id):
				continue
			var person: Dictionary = people[id]
			var partner: String = person.partner
			var partner_has_parents: bool = partner != "" and not people[partner].parents.is_empty()
			if not person.parents.is_empty():
				var youngest := 1000
				var ready := true
				for parent in person.parents:
					if not ages.has(parent):
						ready = false
					else:
						youngest = mini(youngest, int(ages[parent]))
				if ready:
					ages[id] = youngest - rng.randi_range(int(gap[0]), int(gap[1]))
			elif partner == "" or (not partner_has_parents and declared.has(id)):
				ages[id] = rng.randi_range(int(root_age[0]), int(root_age[1]))
			elif ages.has(partner):
				ages[id] = int(ages[partner]) + rng.randi_range(-spread, spread)
	var seen: Dictionary = {}
	for id in people:
		if not ages.has(id) or int(ages[id]) < int(data.get("min_age", 6)) or seen.has(ages[id]):
			return false
		seen[ages[id]] = true
	# Everyone has a different birth month (at most 12 people), so a month names one person.
	var months: Array = range(1, 13)
	_shuffle(months, rng)
	var index := 0
	for id in people:
		var age := int(ages[id])
		var month: int = months[index % 12]
		index += 1
		var day := rng.randi_range(1, days_in(month))
		var later := month > int(reference.m) or (month == int(reference.m) and day > int(reference.d))
		people[id].age = age
		people[id].birth = {"y": int(reference.y) - age - (1 if later else 0), "m": month, "d": day}
	return true

func _assign_names(names: Dictionary, rng: RandomNumberGenerator) -> void:
	var species: Array = rules().get("portrait_species", ["pig"]).duplicate()
	_shuffle(species, rng)
	var pools := {"f": names.get("f", []).duplicate(), "m": names.get("m", []).duplicate()}
	for gender in pools:
		_shuffle(pools[gender], rng)
	var index := 0
	for id in people:
		var pool: Array = pools.get(people[id].gender, [])
		people[id].name = str(pool.pop_back()) if not pool.is_empty() else id
		people[id].species = str(species[index % species.size()])
		index += 1

static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = list[i]
		list[i] = list[j]
		list[j] = swap

# --- Kinship ---------------------------------------------------------------------------

func parents_of(id: String) -> Array:
	return people[id].parents

func children_of(id: String) -> Array:
	var found: Array = []
	for other in people:
		if id in people[other].parents:
			found.append(other)
	return found

func siblings_of(id: String) -> Array:
	var found: Array = []
	for other in people:
		if other == id:
			continue
		for parent in people[id].parents:
			if parent in people[other].parents:
				found.append(other)
				break
	return found

func spouse_of(id: String) -> String:
	return people[id].partner if people[id].partner_kind == "married" else ""

func _each(ids: Array, step: Callable) -> Array:
	var found: Array = []
	for id in ids:
		for other in step.call(id):
			if not other in found:
				found.append(other)
	return found

## What `b` is to `a`: a Family word key, or "".
func relation(a: String, b: String) -> String:
	return str(kin(a, b).get("word", ""))

## The label of what `b` is to `a` (see labeler), or "".
func label(a: String, b: String) -> String:
	var found := kin(a, b)
	if found.is_empty():
		return ""
	return str(labeler.call(found.word, people[b].gender, found)) if labeler.is_valid() else str(found.word)

func _born_before(a: String, b: String) -> bool:
	return birth_order(a) < birth_order(b)

func _side(parent: String) -> String:
	return "paternal" if people[parent].gender == "m" else "maternal"

## What `b` is to `a`: {"word", and the details above that apply}, or {} when there is no word.
func kin(a: String, b: String) -> Dictionary:
	if a == b or not people.has(a) or not people.has(b):
		return {}
	var kind := ""
	var details: Dictionary = {}
	if people[a].partner == b:
		kind = people[a].partner_kind
	elif b in parents_of(a):
		kind = "parent"
	elif b in children_of(a):
		kind = "child"
	elif b in siblings_of(a):
		kind = "sibling"
		details = {"elder": _born_before(b, a)}
	elif b in _each(parents_of(a), parents_of):
		kind = "grandparent"
		for parent in parents_of(a):
			if b in parents_of(parent):
				details = {"side": _side(parent)}
				break
	elif b in _each(children_of(a), children_of):
		kind = "grandchild"
		for child in children_of(a):
			if b in children_of(child):
				details = {"link": people[child].gender}
				break
	else:
		var spouse := spouse_of(a)
		for parent in parents_of(a):
			for sibling in siblings_of(parent):
				if b == sibling or b == spouse_of(sibling):
					kind = "parent_sibling"
					details = {"side": _side(parent), "elder": _born_before(sibling, parent), "link": people[sibling].gender, "by_marriage": b != sibling}
				elif b in children_of(sibling):
					kind = "cousin"
					details = {"side": _side(parent), "elder": _born_before(b, a), "link": people[sibling].gender}
				if kind != "":
					break
			if kind != "":
				break
		if kind == "":
			var own: Array = siblings_of(a)
			var by_spouse: Array = siblings_of(spouse) if spouse != "" else []
			for sibling in own + by_spouse:
				if b in children_of(sibling):
					kind = "sibling_child"
					details = {"link": people[sibling].gender, "by_marriage": not sibling in own}
					if spouse != "" and not sibling in own:
						details.side = "paternal" if people[spouse].gender == "m" else "maternal"
					break
	if kind == "":
		return {}
	details.word = WORDS[kind][1 if people[b].gender == "f" else 0]
	return details

## Birth date as one comparable number (earlier birth = smaller).
func birth_order(id: String) -> int:
	var birth: Dictionary = people[id].birth
	return int(birth.y) * 10000 + int(birth.m) * 100 + int(birth.d)
