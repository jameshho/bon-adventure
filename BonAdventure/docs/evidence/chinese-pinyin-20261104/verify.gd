extends SceneTree
## 4 Nov 2026, Stage 4c: pinyin under Chinese text when Chinese is the foreign language
## (rules_zh.gd reading() from data/pinyin_zh.json). Every generated family question and
## every Chinese word gets a complete reading; the reading follows the Display Mode and only
## exists for a language with reading data. Pure logic, no town; it writes no settings
## (set_display is not called, display is set directly):
## Since the font fix (4 Nov 2026) it also checks the pinyin font's coverage of every tone letter.
## godot --headless --path . --script res://docs/evidence/chinese-pinyin-20261104/verify.gd
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const Questions := preload("res://scripts/learning/family_questions.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
## Every pinyin letter: the four tones on each vowel, ü with its tones, and the capitals a
## sentence can start with (font fix, 4 Nov 2026).
const TONE_LETTERS := "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜüĀÁǍÀĒÉĚÈŌÓǑÒ"
var failures := 0
var checks := 0
var lex

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## The Chinese text has a reading and every character of it is covered.
func complete(text: String) -> bool:
	return lex.reading(text, "zh") != "" and lex.reading_gaps(text, "zh").is_empty() and not "{" in text

func run() -> void:
	lex = Lexicon.shared()
	check(lex.reading_data.has("zh") and not lex.reading_data.has("es") and not lex.reading_data.has("en"), "only Chinese has reading data")
	check(lex.reading("el abuelo", "es") == "" and lex.reading("grandfather", "en") == "", "Spanish and English have no reading line")
	# The pinyin font has every tone letter and every letter the readings use; the built-in
	# font lacks the third-tone (caron) letters, which is why the line has its own font.
	var font: Font = PinyinText.FONT
	var lacking := ""
	for c in TONE_LETTERS:
		if not font.has_char(c.unicode_at(0)):
			lacking += c
	var used := {}
	for text in lex.reading_data.zh.chars.values() + lex.reading_data.zh.words.values():
		for c in str(text):
			used[c] = true
	for c in used:
		if not font.has_char(c.unicode_at(0)) and not c in lacking:
			lacking += c
	check(lacking == "", "the pinyin font has every tone letter, ǖ ǘ ǚ ǜ included, and every letter the readings use (missing: '%s')" % lacking)
	var builtin_lacks := ""
	for c in TONE_LETTERS:
		if not ThemeDB.fallback_font.has_char(c.unicode_at(0)):
			builtin_lacks += c
	check(builtin_lacks != "", "the built-in font still lacks some tone letters (%s), so the pinyin font is needed" % builtin_lacks)
	var label := PinyinText.style(Label.new())
	check(label.get_theme_font("font") == PinyinText.FONT and not label.visible, "PinyinText.style gives a hidden label the pinyin font")
	label.free()
	check(lex.reading_gaps("嘉欣", "zh").is_empty() and lex.reading_gaps("鑰", "zh") == PackedStringArray(["鑰"]), "a character without a reading is reported")
	# Display Mode: the reading follows the foreign line; none in Native only.
	var settings = GameSettings.new()
	lex.native = "en"
	lex.foreign = "zh"
	var line := {"foreign": "李醫生", "native": "Dr. Li"}
	for mode in [GameSettings.FOREIGN, GameSettings.BOTH]:
		settings.display = mode
		check(settings.reading(line) == "Lǐ yīshēng", "mode %d shows the pinyin: %s" % [mode, settings.reading(line)])
	settings.display = GameSettings.NATIVE
	check(settings.reading(line) == "", "Native only shows no pinyin")
	lex.foreign = "es"
	settings.display = GameSettings.FOREIGN
	check(settings.reading({"foreign": "el abuelo", "native": "grandfather"}) == "", "no pinyin when Spanish is the foreign language")
	# Every Chinese word, term and generated question reads completely.
	var bad: Array = []
	for key in lex.words():
		var word: Dictionary = lex.word_entry(key, "zh")
		if word.text != "" and not complete(word.text):
			bad.append("%s %s -> %s" % [key, word.text, lex.reading(word.text, "zh")])
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var asked := 0
	for round_index in 400:
		var tree = FamilyTree.new()
		var tree_rng := RandomNumberGenerator.new()
		tree_rng.seed = 3000 + round_index
		tree.labeler = func(word: String, gender: String, kin: Dictionary) -> String: return lex.word(word, "zh", "label", gender, kin)
		tree.setup(FamilyTree.template_ids()[round_index % 4], {"f": lex.names("zh", "f"), "m": lex.names("zh", "m")}, tree_rng)
		var question: Dictionary = Questions.generate(tree, Questions.pick_kind(rng), rng)
		if question.is_empty():
			continue
		asked += 1
		var text: String = lex.phrase(question.phrase, "zh", question.values)
		var reading: String = lex.reading(text, "zh")
		if not complete(text) or not reading.ends_with("?") or reading.left(1) != reading.left(1).to_upper():
			bad.append("%s -> %s" % [text, reading])
		for person in tree.people:
			var name_reading: String = lex.reading(tree.people[person].name, "zh")
			if not complete(tree.people[person].name) or " " in name_reading:
				bad.append("name %s -> %s" % [tree.people[person].name, name_reading])
	check(asked > 350, "questions generated: %d" % asked)
	check(bad.is_empty(), "every word, question and name reads completely: %s" % [bad.slice(0, 4)])
	lex.native = "en"
	lex.foreign = "es"
	print("chinese pinyin: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
