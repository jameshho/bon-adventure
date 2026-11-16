extends SceneTree
## 4 Nov 2026, Stage 4b: Traditional Chinese (Hong Kong written standard; a draft language until
## it became playable later that day)
## for the family game: kinship terms chosen from the tree's kin details, every relative in
## every template gets exactly one term, and questions are unique and render in Chinese.
## Pure logic, no town and no saves:
## godot --headless --path . --script res://docs/evidence/chinese-family-20261104/verify.gd
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const Questions := preload("res://scripts/learning/family_questions.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const ROUNDS := 40
var failures := 0
var checks := 0
var lex

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
	tree.labeler = func(word: String, gender: String, kin: Dictionary) -> String: return lex.word(word, "zh", "label", gender, kin)
	tree.setup(template, {"f": lex.names("zh", "f"), "m": lex.names("zh", "m")}, rng)
	return tree

func older(tree, a: String, b: String) -> bool:
	return tree.birth_order(a) < tree.birth_order(b)

func expect(tree, a: String, b: String, want: String) -> void:
	check(tree.label(a, b) == want, "%s: %s is %s's %s (got %s)" % [tree.template_id, b, a, want, tree.label(a, b)])

func run() -> void:
	lex = Lexicon.shared()
	# Chinese was a draft (listed, not offered in Settings) until it became playable on 4 Nov 2026.
	check(not lex.is_draft("zh") and lex.playable_codes().has("zh"), "zh is playable: offered in Settings")
	# A saved choice of Chinese is kept.
	var settings = GameSettings.new()
	var saved := FileAccess.file_exists(GameSettings.PATH)
	if not saved:
		var file := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify({"native": "en", "foreign": "zh", "display": 1}))
		file.close()
		settings.load_saved()
		check(settings.foreign == "zh", "a saved choice of Chinese is kept: " + settings.foreign)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	for seed in [11, 12, 13, 14, 15, 16]:
		var big = tree_of("big_family", seed)
		expect(big, "son", "grandfather", "爺爺")
		expect(big, "son", "grandmother", "嫲嫲")
		expect(big, "son", "daughter", "姐姐" if older(big, "daughter", "son") else "妹妹")
		expect(big, "daughter", "son", "哥哥" if older(big, "son", "daughter") else "弟弟")
		expect(big, "son", "aunt", "姑媽" if older(big, "aunt", "father") else "姑姐")
		expect(big, "grandfather", "son", "孫兒")
		expect(big, "aunt", "daughter", "姪女")
		expect(big, "father", "mother", "妻子")
		var mothers = tree_of("mothers_side", seed)
		expect(mothers, "son", "grandfather", "公公")
		expect(mothers, "daughter", "grandmother", "婆婆")
		expect(mothers, "son", "aunt", "姨媽" if older(mothers, "aunt", "mother") else "阿姨")
		expect(mothers, "grandmother", "daughter", "外孫女")
		expect(mothers, "aunt", "son", "外甥")
		var cousins = tree_of("cousins", seed)
		expect(cousins, "daughter", "uncle", "舅父")
		expect(cousins, "daughter", "aunt_in_law", "舅母")
		expect(cousins, "daughter", "cousin_m", "表哥" if older(cousins, "cousin_m", "daughter") else "表弟")
		expect(cousins, "cousin_m", "daughter", "表姐" if older(cousins, "daughter", "cousin_m") else "表妹")
		expect(cousins, "grandmother", "cousin_m", "孫兒")
		expect(cousins, "grandmother", "daughter", "外孫女")
		expect(cousins, "father", "cousin_m", "內姪")
		expect(cousins, "aunt_in_law", "daughter", "外甥女")
		var couples = tree_of("couples", seed)
		expect(couples, "daughter", "boyfriend", "男朋友")
	# Every relative in every template gets one specific term, never the listing text.
	var vague: Array = []
	for template in FamilyTree.template_ids():
		for seed in range(ROUNDS):
			var tree = tree_of(template, 500 + seed)
			for a in tree.people:
				for b in tree.people:
					var label: String = tree.label(a, b)
					if " / " in label:
						vague.append("%s: %s's %s -> %s %s" % [template, a, b, label, tree.kin(a, b)])
	check(vague.is_empty(), "every relative gets one Chinese term: %s" % [vague.slice(0, 4)])
	# Questions in Chinese: unique by the Chinese label, rendering without placeholders.
	var bad: Array = []
	var terms: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for round_index in 400:
		var tree = tree_of(FamilyTree.template_ids()[round_index % 4], 900 + round_index)
		var kind := Questions.pick_kind(rng)
		var question: Dictionary = Questions.generate(tree, kind, rng)
		if question.is_empty():
			continue
		var found: Array = Questions.answers(tree, question)
		var text: String = lex.phrase(question.phrase, "zh", question.values)
		if found.size() != 1 or "{" in text or " / " in text or text == question.phrase:
			bad.append("%s -> %s %s" % [question.phrase, text, found])
		if kind == "relation":
			terms[question.label] = true
	check(bad.is_empty(), "400 Chinese questions: one answer each, rendered: %s" % [bad.slice(0, 3)])
	check(terms.size() >= 20, "relationship questions use many different Chinese terms: %d %s" % [terms.size(), terms.keys()])
	check(lex.phrase("family.q_relation", "zh", {"relation": {"word": "grandfather", "gender": "m", "kin": {"side": "maternal"}}, "name": "嘉欣"}) == "嘉欣的公公是誰？", "q_relation in Chinese")
	check(lex.rules("zh").money_words(14738) == "一百四十七美元三十八美仙" and lex.rules("zh").number_words(1997) == "一千九百九十七", "Chinese numbers and money")
	print("chinese family: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
