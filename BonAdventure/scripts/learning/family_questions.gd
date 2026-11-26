extends RefCounted
## Questions for the hospital family game: fixed phrase templates (data/phrases.json
## group "family") filled from one round's family (family_tree.gd). Pure logic, no text.
##
## A question is {"kind", "phrase" (phrase id), "values" (Lexicon phrase values), "yes_no",
## the parameters below, "answer" (a person id, or "yes"/"no")}. answers() recomputes the
## answer set from the parameters alone, independently of how generate() chose them, and
## generate() only returns a question whose set has exactly one member. Yes/No questions
## pick their truth first, so "yes" and "no" are equally likely.
##
## Kinds (weights in data/family_game.json "kinds"):
##   relation              subject, word, label  "¿Quién es la prima de Ana?"
## A relation question is unique by its label in the language being learned (tree.labeler):
## Chinese tells 爺爺 from 公公 where English and Spanish have one grandfather.
##   age                   age                   "¿Quién tiene 28 años?"
##   oldest_youngest       extreme               "¿Quién es el mayor de la familia?"
##   birth_month           month                 "¿Quién nació en mayo?"
##   birth_year            year                  "¿Quién nació en 1997?"
##   pair_older_younger    first, second, compare "¿Quién es mayor, Ana o Luis?"
##   older_younger_yes_no  first, second, compare "¿Ana es menor que Luis?"
##   before_after_yes_no   first, second, compare "¿Ana nació antes que Luis?"
const MONTHS := ["january", "february", "march", "april", "may", "june", "july", "august",
		"september", "october", "november", "december"]
const TRIES := 60

static func kinds() -> Dictionary:
	return preload("res://scripts/learning/family_tree.gd").rules().get("kinds", {})

## A weighted random kind, never `last` (no immediate repetition) when another exists.
## `only`: the current level's weights (data/activities.json family_dr_li "levels" "kinds";
## LEARN-06, 25 Nov 2026) instead of the data's.
static func pick_kind(rng: RandomNumberGenerator, last: String = "", only: Dictionary = {}) -> String:
	var weights: Dictionary = only if not only.is_empty() else kinds()
	var total := 0.0
	for kind in weights:
		if kind != last or weights.size() == 1:
			total += float(weights[kind])
	var roll := rng.randf() * total
	for kind in weights:
		if kind == last and weights.size() > 1:
			continue
		roll -= float(weights[kind])
		if roll <= 0.0:
			return kind
	return weights.keys()[0]

## A validated question of `kind`, or {} when none was found.
static func generate(tree, kind: String, rng: RandomNumberGenerator) -> Dictionary:
	for attempt in TRIES:
		var question := _draft(tree, kind, rng)
		if question.is_empty():
			continue
		var found := answers(tree, question)
		if found.size() == 1:
			question.answer = found[0]
			return question
	return {}

static func _ids(tree) -> Array:
	return tree.people.keys()

static func _pick(list: Array, rng: RandomNumberGenerator):
	return list[rng.randi_range(0, list.size() - 1)]

static func _two(tree, rng: RandomNumberGenerator) -> Array:
	var ids := _ids(tree)
	var first: String = _pick(ids, rng)
	var second: String = first
	while second == first:
		second = _pick(ids, rng)
	return [first, second]

static func _draft(tree, kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var people: Dictionary = tree.people
	match kind:
		"relation":
			var subject: String = _pick(_ids(tree), rng)
			var counts: Dictionary = {}
			var person_of: Dictionary = {}
			for other in people:
				var label: String = tree.label(subject, other)
				if label != "":
					counts[label] = int(counts.get(label, 0)) + 1
					person_of[label] = other
			var unique: Array = counts.keys().filter(func(label): return counts[label] == 1)
			if unique.is_empty():
				return {}
			var label: String = _pick(unique, rng)
			var other: String = person_of[label]
			var kin: Dictionary = tree.kin(subject, other)
			return {"kind": kind, "phrase": "family.q_relation", "subject": subject, "word": kin.word, "label": label,
				"values": {"relation": {"word": kin.word, "gender": people[other].gender, "kin": kin}, "name": people[subject].name}}
		"age":
			var person: Dictionary = people[_pick(_ids(tree), rng)]
			return {"kind": kind, "phrase": "family.q_age", "age": person.age, "values": {"age": person.age}}
		"oldest_youngest":
			var extreme: String = _pick(["oldest", "youngest"], rng)
			return {"kind": kind, "phrase": "family.q_" + extreme, "extreme": extreme, "values": {}}
		"birth_month":
			var month := int(people[_pick(_ids(tree), rng)].birth.m)
			return {"kind": kind, "phrase": "family.q_month", "month": month, "values": {"month": {"word": MONTHS[month - 1]}}}
		"birth_year":
			var year := int(people[_pick(_ids(tree), rng)].birth.y)
			return {"kind": kind, "phrase": "family.q_year", "year": year, "values": {"year": year}}
		"pair_older_younger", "older_younger_yes_no", "before_after_yes_no":
			var pair := _two(tree, rng)
			var yes_no := kind != "pair_older_younger"
			var options: Array = ["before", "after"] if kind == "before_after_yes_no" else ["older", "younger"]
			var compare: String = _pick(options, rng)
			var question := {"kind": kind, "first": pair[0], "second": pair[1], "compare": compare, "yes_no": yes_no}
			if yes_no:
				# Choose the truth first; swapping the two names flips the answer.
				var want: String = _pick(["yes", "no"], rng)
				if _yes_no(tree, question) != want:
					question.first = pair[1]
					question.second = pair[0]
			var ids := {"older": "older", "younger": "younger", "before": "born_before", "after": "born_after"}
			question.phrase = ("family.q_pair_" if not yes_no else ("family.q_is_" if kind == "older_younger_yes_no" else "family.q_")) + ids[compare]
			question.values = {"first": people[question.first].name, "second": people[question.second].name}
			return question
	push_error("family_questions: unknown kind '%s'" % kind)
	return {}

## The people the question names, for the panel to highlight (user decision, 4 Nov 2026):
## the relation question's subject ("Ana" in "Who is Ana's cousin?") and both people of a
## pair. Questions that name nobody (age, month, year, oldest/youngest) highlight nobody,
## since that would point at the answer.
static func named(question: Dictionary) -> Array:
	match str(question.get("kind", "")):
		"relation":
			return [question.subject]
		"pair_older_younger", "older_younger_yes_no", "before_after_yes_no":
			return [question.first, question.second]
	return []

## True when `a` was born before `b` (is older).
static func _earlier(tree, a: String, b: String) -> bool:
	return tree.birth_order(a) < tree.birth_order(b)

static func _yes_no(tree, question: Dictionary) -> String:
	var earlier := _earlier(tree, question.first, question.second)
	var truth: bool = earlier if question.compare in ["older", "before"] else not earlier
	return "yes" if truth else "no"

## Every correct answer to `question` in `tree`: person ids, or ["yes"] / ["no"].
static func answers(tree, question: Dictionary) -> Array:
	var people: Dictionary = tree.people
	var found: Array = []
	match str(question.get("kind", "")):
		"relation":
			for id in people:
				var label: String = tree.label(question.subject, id)
				if label != "" and label == str(question.get("label", question.word)):
					found.append(id)
		"age":
			for id in people:
				if int(people[id].age) == int(question.age):
					found.append(id)
		"oldest_youngest":
			var best := -1
			for id in people:
				var age := int(people[id].age)
				var better: bool = best < 0 or (age > best if question.extreme == "oldest" else age < best)
				if better:
					best = age
			for id in people:
				if int(people[id].age) == best:
					found.append(id)
		"birth_month":
			for id in people:
				if int(people[id].birth.m) == int(question.month):
					found.append(id)
		"birth_year":
			for id in people:
				if int(people[id].birth.y) == int(question.year):
					found.append(id)
		"pair_older_younger":
			var first_older := _earlier(tree, question.first, question.second)
			found.append(question.first if first_older == (question.compare == "older") else question.second)
		"older_younger_yes_no", "before_after_yes_no":
			found.append(_yes_no(tree, question))
	return found
