extends SceneTree
## Language check: everything a language must supply, for every language in
## data/languages.json. No town is loaded and nothing is saved, so it takes seconds:
##   godot --headless --path . --script res://tools/language_check.gd
## Exits 1 when anything fails. Checks:
##  1. languages.json loads; native/foreign are listed; each language's rules module extends
##     scripts/language/language_rules.gd and overrides every function.
##  2. words.json: every word has text in every language; its forms suit that language.
##     A draft language ("status": "draft") may lack words and phrases: what it has is
##     checked, and what it lacks is reported, not failed.
##  3. phrases.json: every phrase has every language and the same placeholders in each;
##     each {slot:form} names a known form and a 'slots' category, every word of that
##     category can make the form, and the phrase renders for both genders.
##  4. language_samples.json: every section exists for every language, every output
##     matches, and every {slot:form} phrase has a sample in every language.
##  5. names.json: every language has enough unique names of each gender.
##  6. Readings (languages.json "reading", pinyin for Chinese): every character of the
##     language's words, phrases and names has a reading, each listed reading is spelled
##     with pinyin letters, and the language_samples.json "readings" rows match.
##  7. Game scripts contain no taught-language text and no word-gluing ("the " + word);
##     known, scheduled exceptions are listed in CODE_EXCEPTIONS.
##  8. Grammar Classroom banks (data/grammar_class/<code>.json, docs/guides/GRAMMAR_CLASS.md): each is
##     a listed language and follows grammar_questions.gd problems() (one blank, four different
##     choices, the answer among them, explanations in every other playable language, Chinese
##     nouns from words.json); every character of a bank with reading data has a reading.
## Then it prints a coverage report per language.
## See docs/guides/ARCHITECTURE_REVIEW_PART1.md#adding-or-changing-a-language.

const Lexicon := preload("res://scripts/language/lexicon.gd")
const BASE_RULES := "res://scripts/language/language_rules.gd"
const SAMPLES_PATH := "res://data/language_samples.json"
const SAMPLE_SECTIONS := ["numbers", "numbers_before_noun", "money", "forms", "phrases"]
const SCAN_ROOT := "res://scripts"
## Code lines allowed to contain non-English letters or glued words: [file, text, reason].
## Each is scheduled work, not a precedent; remove the entry when its text moves to data.
const CODE_EXCEPTIONS := [
	["res://scripts/world/room_names.gd", "Bakery & Café", "English place name, the lookup key of places.bakery_cafe (UiText.place translates it)"],
]
const NON_ENGLISH := "áéíóúüñÁÉÍÓÚÜÑ¿¡"

var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	var lex = Lexicon.new()
	for problem in lex.load_problems:
		check(false, problem)
	var codes: Array = lex.codes()
	check(codes.size() >= 2, "at least two languages")
	_check_rules(lex, codes)
	_check_words(lex, codes)
	var formed := _check_phrases(lex, codes)
	_check_samples(lex, codes, formed)
	_check_names(lex, codes)
	_check_readings(lex, codes)
	_check_grammar_banks(lex, codes)
	for code in codes:
		if lex.rules(code) != null:
			check(lex.rules(code).missing.is_empty(), "%s rules implement every function (missing: %s)" % [code, ", ".join(lex.rules(code).missing)])
	_check_code()
	_report(lex, codes)
	print("%s: %d checks, %d failed" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)

# --- 1. Rules modules ---------------------------------------------------------------------

func _check_rules(lex, codes: Array) -> void:
	for code in codes:
		var language_rules = lex.rules(code)
		check(language_rules != null, "%s has a rules module" % code)
		if language_rules == null:
			continue
		var script: Script = language_rules.get_script()
		var extends_base := false
		while script != null:
			if script.resource_path == BASE_RULES:
				extends_base = true
			script = script.get_base_script()
		check(extends_base, "%s rules extend language_rules.gd" % code)
		check(str(lex.languages[code].get("name", "")) != "", "%s has a display name" % code)
		# Exercise every function once so missing overrides are recorded.
		var probe := {"key": "probe", "text": "probe", "forms": {}}
		language_rules.form_problem(probe, "definite")
		language_rules.word_problems(probe)
		language_rules.number_words(1)
		language_rules.money_words(101)
		language_rules.list_join(PackedStringArray(["a", "b"]))
		for form_name in language_rules.FORMS:
			language_rules.form(probe, form_name, "m")
	check(not lex.is_draft(lex.native) and not lex.is_draft(lex.foreign), "the default languages are not drafts")
	check(codes.has(lex.native) and codes.has(lex.foreign) and lex.native != lex.foreign, "native '%s' and foreign '%s' are two listed languages" % [lex.native, lex.foreign])

# --- 2. Words ----------------------------------------------------------------------------------

func _check_words(lex, codes: Array) -> void:
	var bad := 0
	for key in lex.words():
		var entry: Dictionary = lex.words()[key]
		for code in entry.get("text", {}):
			if not codes.has(code):
				bad += 1
				check(false, "%s: text for unknown language %s" % [key, code])
		for code in entry.get("forms", {}):
			if not codes.has(code):
				bad += 1
				check(false, "%s: forms for unknown language %s" % [key, code])
		for code in codes:
			var word: Dictionary = lex.word_entry(key, code)
			if word.text.strip_edges() == "":
				if lex.is_draft(code):
					continue
				bad += 1
				check(false, "%s: no %s text" % [key, code])
			if lex.rules(code) != null:
				for problem in lex.rules(code).word_problems(word):
					bad += 1
					check(false, "%s (%s): %s" % [key, code, problem])
	check(bad == 0, "%d words have text in every language and valid forms" % lex.words().size())

# --- 3. Phrases -------------------------------------------------------------------------------

## Returns the ids of phrases that use a {slot:form}.
func _check_phrases(lex, codes: Array) -> Array:
	var formed: Array = []
	var categories: Dictionary = lex.word_data.get("categories", {})
	for id in lex.phrases:
		var entry: Dictionary = lex.phrases[id]
		for field in entry:
			if not codes.has(field) and not field in Lexicon.PHRASE_FIELDS:
				check(false, "%s: unknown field '%s'" % [id, field])
		var signature := {}
		for code in codes:
			if not entry.has(code) or str(entry[code]).strip_edges() == "":
				if not lex.is_draft(code):
					check(false, "%s: no %s line" % [id, code])
				continue
			var tokens: Array = []
			for slot in Lexicon.placeholders(str(entry[code])):
				tokens.append(slot.token)
			tokens.sort()
			signature[code] = tokens
		var first: Variant = signature.values()[0] if not signature.is_empty() else []
		for code in signature:
			check(signature[code] == first, "%s: same placeholders in every language (%s: %s)" % [id, code, signature[code]])
		var slots: Dictionary = entry.get("slots", {})
		var has_form := false
		for slot in Lexicon.placeholders(str(entry.get(lex.native, ""))):
			if slot.form == "":
				continue
			has_form = true
			var category := str(slots.get(slot.name, ""))
			check(categories.has(category), "%s: {%s:%s} has a 'slots' word category (%s)" % [id, slot.name, slot.form, category])
			for code in codes:
				var language_rules = lex.rules(code)
				if language_rules == null or not entry.has(code):
					continue
				check(slot.form in language_rules.FORMS, "%s: form '%s' is a known form" % [id, slot.form])
				for key in lex.words():
					if str(lex.words()[key].get("category", "")) != category:
						continue
					if lex.is_draft(code) and lex.word_entry(key, code).text == "":
						continue
					var problem: String = language_rules.form_problem(lex.word_entry(key, code), slot.form)
					check(problem == "", "%s: %s can fill {%s:%s} in %s %s" % [id, key, slot.name, slot.form, code, problem])
					for gender in ["m", "f"]:
						var values := {}
						for other in Lexicon.placeholders(str(entry[code])):
							values[other.name] = "X"
						values[slot.name] = {"word": key, "gender": gender}
						var text: String = lex.phrase(id, code, values)
						check(not "{" in text and text != id, "%s renders in %s with %s (%s): %s" % [id, code, key, gender, text])
		if has_form:
			formed.append(id)
	return formed

# --- 4. Samples -----------------------------------------------------------------------------

func _check_samples(lex, codes: Array, formed: Array) -> void:
	if not FileAccess.file_exists(SAMPLES_PATH):
		check(false, "missing " + SAMPLES_PATH)
		return
	var samples: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAMPLES_PATH))
	check(samples is Dictionary, "language_samples.json parses")
	if not samples is Dictionary:
		return
	for code in codes:
		var own: Dictionary = samples.get(code, {})
		var language_rules = lex.rules(code)
		for section in SAMPLE_SECTIONS:
			check(not own.get(section, []).is_empty(), "%s has '%s' samples" % [code, section])
		if language_rules == null:
			continue
		for row in own.get("numbers", []):
			_expect(language_rules.number_words(int(row[0])), str(row[1]), "%s number %d" % [code, int(row[0])])
		for row in own.get("numbers_before_noun", []):
			_expect(language_rules.number_words(int(row[0]), true), str(row[1]), "%s number %d before a noun" % [code, int(row[0])])
		for row in own.get("money", []):
			_expect(language_rules.money_words(int(row[0])), str(row[1]), "%s money %d" % [code, int(row[0])])
		for row in own.get("forms", []):
			_expect(language_rules.form(lex.word_entry(str(row[0]), code), str(row[1]), str(row[2])), str(row[3]), "%s %s of %s (%s)" % [code, row[1], row[0], row[2]])
		var sampled := {}
		for row in own.get("phrases", []):
			sampled[str(row[0])] = true
			_expect(lex.phrase(str(row[0]), code, row[1]), str(row[2]), "%s phrase %s" % [code, row[0]])
		for id in formed:
			if lex.is_draft(code) and not lex.phrases[id].has(code):
				continue
			check(sampled.has(id), "%s has a sample for grammar phrase %s" % [code, id])
		if lex.reading_data.has(code):
			check(not own.get("readings", []).is_empty(), "%s has 'readings' samples" % code)
		for row in own.get("readings", []):
			_expect(lex.reading(str(row[0]), code), str(row[1]), "%s reading of %s" % [code, row[0]])

func _expect(got: String, expected: String, label: String) -> void:
	check(got == expected, "%s: got '%s', expected '%s'" % [label, got, expected])

# --- 5. Names --------------------------------------------------------------------------------

func _check_names(lex, codes: Array) -> void:
	var minimum := int(lex.name_data.get("min_per_gender", 1))
	for code in codes:
		for gender in ["f", "m"]:
			var list: Array = lex.names(code, gender)
			var unique := {}
			for person in list:
				if str(person).strip_edges() != "":
					unique[str(person)] = true
			check(unique.size() == list.size() and list.size() >= minimum, "%s has %d unique '%s' names (needs %d)" % [code, list.size(), gender, minimum])

# --- 6. Readings -----------------------------------------------------------------------------

func _check_readings(lex, codes: Array) -> void:
	var syllable := RegEx.create_from_string("^[a-zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü]+$")
	var spelled := RegEx.create_from_string("^[A-Za-zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜüĀÁǍÀĒÉĚÈŌÓǑÒ' ]+$")
	for code in codes:
		if not lex.reading_data.has(code):
			continue
		var data: Dictionary = lex.reading_data[code]
		var bad: Array = []
		for c in data.get("chars", {}):
			if str(c).length() != 1 or syllable.search(str(data.chars[c])) == null:
				bad.append("%s %s" % [c, data.chars[c]])
		for word in data.get("words", {}):
			if spelled.search(str(data.words[word])) == null:
				bad.append("%s %s" % [word, data.words[word]])
		check(bad.is_empty(), "%s readings are spelled with pinyin letters: %s" % [code, bad.slice(0, 5)])
		# Every text of the language: word text and terms, phrase lines (placeholders removed), names.
		var texts: Array = []
		for key in lex.words():
			var word: Dictionary = lex.word_entry(key, code)
			texts.append(word.text)
			for term in word.forms.get("terms", []):
				texts.append(str(term.get("text", "")))
		for id in lex.phrases:
			var line := str(lex.phrases[id].get(code, ""))
			for slot in Lexicon.placeholders(line):
				line = line.replace(slot.token, " ")
			texts.append(line)
		texts.append_array(lex.names(code, "f") + lex.names(code, "m"))
		var gaps: PackedStringArray = []
		for text in texts:
			for gap in lex.reading_gaps(str(text), code):
				if not gaps.has(gap):
					gaps.append(gap)
		check(gaps.is_empty(), "%s: every character of its words, phrases and names has a reading (missing: %s)" % [code, " ".join(gaps)])

# --- 8. Grammar Classroom banks -------------------------------------------------------------

func _check_grammar_banks(lex, codes: Array) -> void:
	var Questions = load("res://scripts/learning/grammar_questions.gd")
	var dir := DirAccess.open(Questions.DIR)
	check(dir != null, "grammar banks folder %s exists" % Questions.DIR)
	if dir == null:
		return
	var words: Dictionary = lex.words()
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var code := file.get_basename()
		check(codes.has(code), "grammar bank %s names a listed language" % file)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Questions.DIR + file))
		check(parsed is Dictionary, "grammar bank %s parses" % file)
		if not parsed is Dictionary or not codes.has(code):
			continue
		var others: Array = lex.playable_codes().filter(func(other): return other != code)
		var problems: PackedStringArray = Questions.problems(parsed, code, others, words)
		check(problems.is_empty(), "grammar bank %s follows the rules (%d problems: %s)" % [file, problems.size(), problems.slice(0, 3)])
		if not lex.reading_data.has(code):
			continue
		var gaps: PackedStringArray = []
		for question in parsed.get("questions", []):
			for text in [str(question.get("text", "")).replace(Questions.BLANK, " ")] + question.get("choices", []):
				for gap in lex.reading_gaps(str(text), code):
					if not gaps.has(gap):
						gaps.append(gap)
		check(gaps.is_empty(), "grammar bank %s: every character has a reading (missing: %s)" % [file, " ".join(gaps)])

# --- 7. Code scan ---------------------------------------------------------------------------

func _check_code() -> void:
	var glue := RegEx.create_from_string("\"(the|a|an|el|la|los|las|un|una) \"\\s*\\+")
	var found := 0
	for path in _scripts(SCAN_ROOT):
		if path.get_file().begins_with("rules_"):
			continue
		var number := 0
		for raw in FileAccess.get_file_as_string(path).split("\n"):
			number += 1
			var code_text := _without_comment(raw)
			var foreign_letters := false
			for letter in NON_ENGLISH:
				if letter in code_text:
					foreign_letters = true
			if not foreign_letters and glue.search(code_text) == null:
				continue
			var excused := false
			for exception in CODE_EXCEPTIONS:
				if exception[0] == path and exception[1] in code_text:
					excused = true
			if not excused:
				found += 1
				check(false, "%s:%d has taught-language text or glued words: %s" % [path, number, code_text.strip_edges().left(120)])
	check(found == 0, "game scripts keep taught-language text in data (%d exceptions listed)" % CODE_EXCEPTIONS.size())

func _scripts(dir_path: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file in dir.get_files():
		if file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	for sub in dir.get_directories():
		found.append_array(_scripts(dir_path.path_join(sub)))
	return found

## The line without its trailing # comment (a # inside a string is kept).
func _without_comment(line: String) -> String:
	var quote := ""
	for i in line.length():
		var c := line[i]
		if quote != "":
			if c == "\\":
				continue
			if c == quote and (i == 0 or line[i - 1] != "\\"):
				quote = ""
		elif c == "\"" or c == "'":
			quote = c
		elif c == "#":
			return line.left(i)
	return line

# --- Report ----------------------------------------------------------------------------------

func _report(lex, codes: Array) -> void:
	print("Languages: native %s, foreign %s" % [lex.native, lex.foreign])
	for code in codes:
		var with_text := 0
		var with_forms := 0
		for key in lex.words():
			var word: Dictionary = lex.word_entry(key, code)
			if word.text != "":
				with_text += 1
			if not word.forms.is_empty():
				with_forms += 1
		var lines := 0
		for id in lex.phrases:
			if lex.phrases[id].has(code):
				lines += 1
		print("  %s (%s)%s: %d/%d words, %d with forms, %d/%d phrases" % [code, lex.languages[code].get("name", ""), " DRAFT" if lex.is_draft(code) else "", with_text, lex.words().size(), with_forms, lines, lex.phrases.size()])
