extends SceneTree
## 4 Nov 2026: family game logic (no town). Trees, kinship, and the question generator and
## validator over many random rounds, in every taught language. Writes nothing.
## godot --headless --path . --script res://docs/evidence/family-game-20261104/verify.gd
const Lexicon := preload("res://scripts/language/lexicon.gd")
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const Questions := preload("res://scripts/learning/family_questions.gd")
const ROUNDS := 400
const QUESTIONS := 4000
const INVERSE := {"father": "child", "mother": "child", "son": "parent", "daughter": "parent",
	"grandfather": "grandchild", "grandmother": "grandchild", "grandson": "grandparent",
	"granddaughter": "grandparent", "uncle": "sibling_child", "aunt": "sibling_child",
	"nephew": "parent_sibling", "niece": "parent_sibling", "brother": "sibling", "sister": "sibling",
	"cousin": "cousin", "husband": "married", "wife": "married", "boyfriend": "dating", "girlfriend": "dating"}
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func names(lex) -> Dictionary:
	return {"f": lex.names(lex.foreign, "f"), "m": lex.names(lex.foreign, "m")}

func run() -> void:
	var lex = Lexicon.shared()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261104
	var data: Dictionary = FamilyTree.rules()
	check(FamilyTree.template_ids().size() >= 3 and FamilyTree.template_ids().size() <= 4, "3-4 tree templates: %s" % [FamilyTree.template_ids()])
	# The reference date is the shared random "today" (game_clock.gd, 5 Nov 2026): each round
	# rolls a new one so the ages are checked against many dates in 2026-2027.
	var clock = preload("res://scripts/learning/game_clock.gd").shared()
	# --- Trees ---------------------------------------------------------------------------
	var words_seen: Dictionary = {}
	var bad_trees := []
	for template in FamilyTree.template_ids():
		for round_index in ROUNDS:
			clock.roll(rng)
			var reference: Dictionary = clock.today
			var tree = FamilyTree.new()
			if not tree.setup(template, names(lex), rng):
				bad_trees.append(template + ": setup failed")
				continue
			var ages := {}
			var shown := {}
			for id in tree.people:
				var person: Dictionary = tree.people[id]
				var birth: Dictionary = person.birth
				var later: bool = birth.m > reference.m or (birth.m == reference.m and birth.d > reference.d)
				if reference.y - birth.y - (1 if later else 0) != person.age:
					bad_trees.append("%s %s: age %d does not match birth %s" % [template, id, person.age, FamilyTree.date_digits(birth)])
				if person.age < int(data.min_age) or ages.has(person.age):
					bad_trees.append("%s %s: age %d too young or repeated" % [template, id, person.age])
				ages[person.age] = true
				if shown.has(person.name) or not person.name in lex.names(lex.foreign, person.gender):
					bad_trees.append("%s %s: name '%s' repeated or not a %s name" % [template, id, person.name, person.gender])
				shown[person.name] = true
				for parent in person.parents:
					if tree.people[parent].age - person.age < int(data.gap[0]) - int(data.partner_spread):
						bad_trees.append("%s %s: parent %s only %d years older" % [template, id, parent, tree.people[parent].age - person.age])
				for other in tree.people:
					var word: String = tree.relation(id, other)
					if word == "":
						continue
					words_seen[word] = true
					# The word matches the other person's gender, and the reverse relation exists.
					var back: String = tree.relation(other, id)
					var kind: String = INVERSE.get(word, "")
					var expected: Array = FamilyTree.WORDS.get(kind, [])
					if expected.is_empty() or not back in expected:
						bad_trees.append("%s: %s is %s's %s, but %s's relation back is '%s'" % [template, other, id, word, other, back])
					if FamilyTree.WORDS.values().any(func(pair): return word in pair and pair[0] != pair[1] and pair[1 if tree.people[other].gender == "f" else 0] != word):
						bad_trees.append("%s: %s (%s) called %s" % [template, other, tree.people[other].gender, word])
	check(bad_trees.is_empty(), "%d random rounds per template: ages match birth dates, differ, at least min_age; names unique and foreign; relations consistent both ways: %s" % [ROUNDS, bad_trees.slice(0, 6)])
	var all_words := []
	for pair in FamilyTree.WORDS.values():
		for word in pair:
			if not word in all_words:
				all_words.append(word)
	var missing := all_words.filter(func(word): return not words_seen.has(word))
	check(missing.is_empty(), "every relationship word occurs in some template: missing %s" % [missing])
	for word in all_words:
		check(lex.has_word(word) and str(lex.words()[word].get("category", "")) == "Family", word + " is a Family word")
	# Kinship spot checks on the big family.
	var tree = FamilyTree.new()
	tree.setup("big_family", names(lex), rng)
	var expect := [["son", "grandfather", "grandfather"], ["son", "aunt", "aunt"], ["aunt", "son", "nephew"],
		["aunt", "daughter", "niece"], ["son", "daughter", "sister"], ["father", "aunt", "sister"],
		["mother", "father", "husband"], ["grandmother", "son", "grandson"], ["mother", "grandfather", ""]]
	for row in expect:
		check(tree.relation(row[0], row[1]) == row[2], "big family: %s is %s's '%s': got '%s'" % [row[1], row[0], row[2], tree.relation(row[0], row[1])])
	var cousins = FamilyTree.new()
	cousins.setup("cousins", names(lex), rng)
	for row in [["daughter", "uncle", "uncle"], ["daughter", "aunt_in_law", "aunt"], ["daughter", "cousin_m", "cousin"],
			["aunt_in_law", "daughter", "niece"], ["father", "cousin_m", "nephew"], ["aunt_in_law", "mother", ""]]:
		check(cousins.relation(row[0], row[1]) == row[2], "cousins: %s is %s's '%s': got '%s'" % [row[1], row[0], row[2], cousins.relation(row[0], row[1])])
	for template in FamilyTree.template_ids():
		check(FamilyTree.rules().trees[template].people.size() == 7, template + " has 7 people (user decision)")
	var couples = FamilyTree.new()
	couples.setup("couples", names(lex), rng)
	check(couples.relation("daughter", "boyfriend") == "boyfriend" and couples.relation("boyfriend", "daughter") == "girlfriend" and couples.relation("son", "girlfriend") == "girlfriend", "dating partners are boyfriend / girlfriend")
	check(couples.relation("boyfriend", "father") == "", "a boyfriend has no family word for her father")
	# --- Questions -----------------------------------------------------------------------
	var kinds_seen := {}
	var relation_words := {}
	var months := {}
	var yes := 0
	var yes_no := 0
	var failed := []
	var repeated := 0
	var last := ""
	var samples := {}
	tree = null
	for index in QUESTIONS:
		if index % 3 == 0:
			tree = FamilyTree.new()
			tree.setup(FamilyTree.template_ids()[rng.randi_range(0, FamilyTree.template_ids().size() - 1)], names(lex), rng)
		var kind := Questions.pick_kind(rng, last)
		if kind == last:
			repeated += 1
		last = kind
		var question := Questions.generate(tree, kind, rng)
		if question.is_empty():
			failed.append(kind + " (" + tree.template_id + "): none generated")
			continue
		kinds_seen[kind] = int(kinds_seen.get(kind, 0)) + 1
		var found := Questions.answers(tree, question)
		if found.size() != 1 or found[0] != question.answer:
			failed.append("%s: answers %s, stored %s" % [question.phrase, found, question.answer])
		if bool(question.get("yes_no", false)):
			yes_no += 1
			yes += 1 if question.answer == "yes" else 0
			if not question.answer in ["yes", "no"]:
				failed.append("yes/no answer " + str(question.answer))
		elif not tree.people.has(question.answer):
			failed.append("answer is not a person: " + str(question.answer))
		# Highlighted people: the relation subject or both of a pair, never anyone else.
		var named: Array = Questions.named(question)
		var want_named: Array = [question.subject] if kind == "relation" else ([question.first, question.second] if question.has("first") else [])
		if named != want_named or named.any(func(id): return not tree.people.has(id)):
			failed.append("%s names %s, expected %s" % [kind, named, want_named])
		if kind == "relation" and named.has(question.answer):
			failed.append("relation highlights its answer " + str(question.answer))
		if kind == "relation":
			relation_words[question.word] = true
		if kind == "birth_month":
			months[question.month] = true
		for code in lex.codes():
			var text: String = lex.phrase(question.phrase, code, question.values)
			if "{" in text or text == question.phrase or text.strip_edges() == "":
				failed.append("%s does not render in %s: %s" % [question.phrase, code, text])
		if not samples.has(question.phrase):
			samples[question.phrase] = "%s | %s" % [lex.phrase(question.phrase, lex.foreign, question.values), lex.phrase(question.phrase, lex.native, question.values)]
	check(failed.is_empty(), "%d questions: each has exactly one answer, the stored one, and renders in every language: %s" % [QUESTIONS, failed.slice(0, 6)])
	check(kinds_seen.size() == Questions.kinds().size(), "every question kind occurs: %s" % [kinds_seen])
	check(Questions.kinds().size() >= 6 and Questions.kinds().size() <= 8, "version 1 has 6-8 question kinds: %d" % Questions.kinds().size())
	check(repeated == 0, "no kind repeats immediately: %d" % repeated)
	print("  yes/no: %d of %d yes" % [yes, yes_no])
	var ratio := float(yes) / maxf(yes_no, 1)
	check(yes_no > 500 and ratio > .45 and ratio < .55, "yes/no answers are balanced: %d of %d yes" % [yes, yes_no])
	var unasked := all_words.filter(func(word): return not relation_words.has(word))
	check(unasked.is_empty(), "every relationship word is asked about: missing %s" % [unasked])
	check(months.size() == 12, "every month is asked about: %d" % months.size())
	# Every phrase of the family group exists in every language (language_check covers parity).
	for id in ["family.greeting", "family.play", "family.goodbye", "family.title", "family.date_legend", "family.today",
			"family.answer_yes", "family.answer_no", "family.correct", "family.wrong", "family.next", "family.exit"]:
		for code in lex.codes():
			check(lex.phrase(id, code, {"date": "11/04/2026"}) != id, "%s exists in %s" % [id, code])
	var ids := samples.keys()
	ids.sort()
	for id in ids:
		print("  sample %s: %s" % [id, samples[id]])
	print("family game logic: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
