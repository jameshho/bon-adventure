extends SceneTree
## 4 Nov 2026, Stage 4a: the family tree's kin details (side, elder, link, by_marriage) that
## Chinese needs to choose a term, the mother's-side template, and relationship questions
## unique by the learner's label. Pure logic, no town and no saves:
## godot --headless --path . --script res://docs/evidence/chinese-kinship-20261104/verify.gd
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const Questions := preload("res://scripts/learning/family_questions.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func tree_of(template: String, seed: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var tree = FamilyTree.new()
	var names := {"f": ["Ana", "Eva", "Lía", "Sara", "Rosa", "Inés", "Marta"], "m": ["Luis", "Pablo", "Juan", "Hugo", "Iván", "Tomás", "Raúl"]}
	tree.setup(template, names, rng)
	return tree

func expect(tree, a: String, b: String, want: Dictionary) -> void:
	var got: Dictionary = tree.kin(a, b)
	var ok := true
	for key in want:
		if got.get(key) != want[key]:
			ok = false
	check(ok, "%s: %s is %s's %s (got %s)" % [tree.template_id, b, a, want, got])

func run() -> void:
	check(FamilyTree.template_ids().has("mothers_side") and FamilyTree.template_ids().size() == 4, "four templates, including mothers_side: %s" % [FamilyTree.template_ids()])
	for seed in [1, 2, 3, 4, 5]:
		var big = tree_of("big_family", seed)
		expect(big, "son", "grandfather", {"word": "grandfather", "side": "paternal"})
		expect(big, "son", "daughter", {"word": "sister", "elder": big.birth_order("daughter") < big.birth_order("son")})
		expect(big, "daughter", "aunt", {"word": "aunt", "side": "paternal", "link": "f", "by_marriage": false, "elder": big.birth_order("aunt") < big.birth_order("father")})
		expect(big, "grandmother", "son", {"word": "grandson", "link": "m"})
		expect(big, "aunt", "son", {"word": "nephew", "link": "m", "by_marriage": false})
		var mothers = tree_of("mothers_side", seed)
		expect(mothers, "son", "grandfather", {"word": "grandfather", "side": "maternal"})
		expect(mothers, "daughter", "grandmother", {"word": "grandmother", "side": "maternal"})
		expect(mothers, "son", "aunt", {"word": "aunt", "side": "maternal", "link": "f", "by_marriage": false})
		expect(mothers, "grandfather", "daughter", {"word": "granddaughter", "link": "f"})
		expect(mothers, "aunt", "daughter", {"word": "niece", "link": "f", "by_marriage": false})
		var cousins = tree_of("cousins", seed)
		expect(cousins, "daughter", "uncle", {"word": "uncle", "side": "maternal", "link": "m", "by_marriage": false})
		expect(cousins, "daughter", "aunt_in_law", {"word": "aunt", "side": "maternal", "link": "m", "by_marriage": true})
		expect(cousins, "daughter", "cousin_m", {"word": "cousin", "side": "maternal", "link": "m", "elder": cousins.birth_order("cousin_m") < cousins.birth_order("daughter")})
		expect(cousins, "aunt_in_law", "daughter", {"word": "niece", "link": "f", "by_marriage": true, "side": "paternal"})
		expect(cousins, "father", "cousin_m", {"word": "nephew", "link": "m", "by_marriage": true, "side": "maternal"})
		check(cousins.relation("daughter", "uncle") == "uncle" and big.relation("son", "father") == "father", "relation() still returns the word key")
	# English and Spanish ignore the details.
	var lex = Lexicon.shared()
	check(lex.word("grandfather", "es", "label", "m", {"side": "maternal"}) == "el abuelo" and lex.word("grandfather", "en", "label", "m", {"side": "paternal"}) == "grandfather", "en / es labels ignore kin details")
	# Questions are unique by the learner's label: a labeler that tells sides apart.
	var bad: Array = []
	var asked_sides: Dictionary = {}
	for template in FamilyTree.template_ids():
		for seed in range(20):
			var tree = tree_of(template, 100 + seed)
			tree.labeler = func(word: String, _gender: String, kin: Dictionary) -> String: return word + "/" + str(kin.get("side", "")) + "/" + str(kin.get("elder", ""))
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			var question: Dictionary = Questions.generate(tree, "relation", rng)
			if question.is_empty():
				bad.append("%s: no relation question" % template)
				continue
			var found: Array = Questions.answers(tree, question)
			if found.size() != 1 or tree.label(question.subject, found[0]) != question.label:
				bad.append("%s: %s" % [template, question])
			if question.values.relation.has("kin"):
				asked_sides[str(question.values.relation.kin.get("side", ""))] = true
	check(bad.is_empty(), "relation questions are unique by label and carry the kin details: %s" % [bad.slice(0, 3)])
	check(asked_sides.has("maternal") and asked_sides.has("paternal"), "both sides come up in questions: %s" % [asked_sides.keys()])
	print("chinese kinship: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
