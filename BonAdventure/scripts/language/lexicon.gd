extends RefCounted
## The ONE reader of the game's language data. Everything the player reads in a taught
## language goes through here:
##   data/languages.json  the known languages, their rules modules, native + foreign
##   data/words.json      every listed word: "text" per language, optional "forms"
##   data/phrases.json    every sentence, grouped ("shop.success"), one line per language
##   data/names.json      personal names for generated characters, per language and gender
## Generated language (numbers, money amounts) comes from the rules modules
## (scripts/language/rules_<code>.gd), not from listed words.
##
## Use Lexicon.shared(); word_data.gd derives Main's old dictionaries from it.
## Never put words or sentences of a taught language in game code, and never join words
## into a sentence in code: add a phrase and, if it needs grammar, a {slot:form}.
## tools/language_check.gd validates all of it.
## See docs/guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure.

const LANGUAGES_PATH := "res://data/languages.json"
const WORDS_PATH := "res://data/words.json"
const PHRASES_PATH := "res://data/phrases.json"
const NAMES_PATH := "res://data/names.json"
## Entry fields of a phrase that are not language codes.
const PHRASE_FIELDS := ["slots", "note"]

static var _shared
static var _placeholder: RegEx

var native := ""
var foreign := ""
## data/languages.json's own native and foreign (never changed by settings or profiles): the
## language of the screens before the town (English; every player is assumed to read it,
## user decision 14 Nov 2026) and the pair a new profile starts with (app_screens.gd).
var default_native := ""
var default_foreign := ""
## code -> {"name", "rules"}
var languages: Dictionary = {}
## The parsed data/words.json (about, categories, aliases, removed_with_objects, words).
var word_data: Dictionary = {}
## "group.key" -> {code: text, "slots"?: {slot: category}}
var phrases: Dictionary = {}
## The parsed data/names.json (min_per_gender, names: {code: {"f": [...], "m": [...]}}).
var name_data: Dictionary = {}
## Problems found while loading (missing files, rules modules that do not load).
var load_problems: PackedStringArray = []
## code -> the language's reading data (languages.json "reading", e.g. data/pinyin_zh.json),
## plus "names": its personal names, so they read as one word.
var reading_data: Dictionary = {}
var _rules: Dictionary = {}

static func shared():
	if _shared == null:
		_shared = new()
	return _shared

func _init() -> void:
	var setup := _read(LANGUAGES_PATH)
	languages = setup.get("languages", {})
	native = str(setup.get("native", ""))
	foreign = str(setup.get("foreign", ""))
	default_native = native
	default_foreign = foreign
	for code in [native, foreign]:
		if not languages.has(code):
			load_problems.append("languages.json: native/foreign '%s' is not a listed language" % code)
	for code in languages:
		var path := str(languages[code].get("rules", ""))
		var script: Script = load(path) as Script if ResourceLoader.exists(path) else null
		if script == null or not script.can_instantiate():
			load_problems.append("languages.json: no rules module for '%s'" % code)
			continue
		_rules[code] = script.new()
	word_data = _read(WORDS_PATH)
	var groups: Dictionary = _read(PHRASES_PATH).get("phrases", {})
	for group in groups:
		for key in groups[group]:
			phrases["%s.%s" % [group, key]] = groups[group][key]
	name_data = _read(NAMES_PATH)
	for code in languages:
		var reading_path := str(languages[code].get("reading", ""))
		if reading_path != "":
			reading_data[code] = _read(reading_path)
			reading_data[code]["names"] = names(code, "f") + names(code, "m")

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		load_problems.append("missing " + path)
		push_error("lexicon: missing " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		load_problems.append("unreadable " + path)
		push_error("lexicon: unreadable " + path)
		return {}
	return parsed

func codes() -> Array:
	return languages.keys()

## A language still being written ("status": "draft" in languages.json): not offered in Settings.
func is_draft(code: String) -> bool:
	return str(languages.get(code, {}).get("status", "")) == "draft"

## The languages a player can choose (every complete one).
func playable_codes() -> Array:
	return codes().filter(func(code): return not is_draft(code))

func rules(lang: String):
	return _rules.get(lang)

func words() -> Dictionary:
	return word_data.get("words", {})

func has_word(key: String) -> bool:
	return words().has(key)

## The word as the rules modules see it: {"key", "text", "forms"} in one language.
## `kin`: family-tree details for a relationship word (family_tree.gd kin(); Chinese chooses
## 爺爺 or 公公 from them), {} otherwise.
func word_entry(key: String, lang: String, kin: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = words().get(key, {})
	return {"key": key, "text": str(entry.get("text", {}).get(lang, "")), "forms": entry.get("forms", {}).get(lang, {}), "kin": kin}

## The display text of a word ("el vendedor / la vendedora"), or one grammatical form
## of it for a person of `gender` ("el vendedor"). Unknown words show their key.
func word(key: String, lang: String, form_name: String = "", gender: String = "", kin: Dictionary = {}) -> String:
	if not has_word(key):
		push_warning("lexicon: unknown word '%s'" % key)
		return key
	var entry := word_entry(key, lang, kin)
	if form_name == "":
		if entry.text == "":
			push_error("lexicon: '%s' has no %s text" % [key, lang])
			return key
		return entry.text
	var language_rules = rules(lang)
	var made: String = language_rules.form(entry, form_name, gender) if language_rules != null else ""
	if made == "":
		push_error("lexicon: cannot make the %s form of '%s' in %s" % [form_name, key, lang])
		return entry.text if entry.text != "" else key
	return made

## Placeholders in a phrase line: [{"name", "form"}] for each {name} / {name:form}.
static func placeholders(text: String) -> Array:
	if _placeholder == null:
		_placeholder = RegEx.create_from_string("\\{([a-z0-9_]+)(?::([a-z_]+))?\\}")
	var found: Array = []
	for found_match in _placeholder.search_all(text):
		found.append({"name": found_match.get_string(1), "form": found_match.get_string(2), "token": found_match.get_string(0)})
	return found

## One phrase in one language with its {name} values filled in. A value may be:
## - a String or number;
## - a Dictionary of language code -> text (text that differs per language);
## - a word reference {"word": key, "gender": "m"/"f"}: the word's display text for {name},
##   or the requested form for {name:form};
## - a phrase reference {"phrase": id, ...} (see text());
## - {"learn": value}: any of the above, always in the language being learned (a word to teach
##   inside a native-language line; native_line() lists it as a term).
## Values that are not given leave their placeholder untouched.
func phrase(id: String, lang: String, values: Dictionary = {}) -> String:
	var entry: Variant = phrases.get(id)
	if not entry is Dictionary or not entry.has(lang):
		push_error("lexicon: missing phrase %s (%s)" % [id, lang])
		return id
	var text: String = entry[lang]
	for slot in placeholders(text):
		if not values.has(slot.name):
			continue
		text = text.replace(slot.token, value_text(values[slot.name], lang, slot.form))
	var language_rules = rules(lang)
	if not values.is_empty() and language_rules != null:
		text = language_rules.polish(text)
	return text

## One phrase value (see phrase()) as text in `lang`; `form`: the slot's {name:form}.
func value_text(value: Variant, lang: String, form: String = "") -> String:
	if value is Dictionary and value.has("learn"):
		return value_text(value.learn, foreign, form)
	if value is Dictionary and value.has("word"):
		return word(str(value.word), lang, form if form != "" else str(value.get("form", "")), str(value.get("gender", "")), value.get("kin", {}))
	if value is Dictionary and value.has("phrase"):
		return text(value, lang)
	if value is Dictionary:
		return str(value.get(lang, ""))
	return str(value)

## A dialogue box line spoken in the NATIVE language (the welcome tutorial, its clerk and
## cashier): the same text in both slots, so every Display Mode shows it, with meta
## `narration` (the box shows no reading or translation). Its {"learn": ...} values come out in
## the language being learned and are listed in "terms" ([{"text", "gloss"}], plus
## `extra_terms`), which the dialogue box colours and explains (shop_order_panel.gd). A term
## with "show": true always shows its meaning (an amount and its digits).
func native_line(id: String, values: Dictionary = {}, extra_terms: Array = []) -> Dictionary:
	var text := phrase(id, native, values)
	var terms: Array = []
	var entry: Variant = phrases.get(id)
	for slot in placeholders(str(entry.get(native, "")) if entry is Dictionary else ""):
		var value: Variant = values.get(slot.name)
		if value is Dictionary and value.has("learn"):
			var term := {"text": value_text(value.learn, foreign, slot.form), "gloss": value_text(value.learn, native, slot.form)}
			if value.get("show", false):
				term["show"] = true
			terms.append(term)
	terms.append_array(extra_terms)
	return {"foreign": text, "native": text, "narration": true, "terms": terms}

## A term for native_line()'s `extra_terms`: word `key` in the language being learned, with its
## native meaning.
func word_term(key: String) -> Dictionary:
	return {"text": word(key, foreign), "gloss": word(key, native)}

## Text described by a reference, so it can be re-rendered in any language (world labels
## that follow the L toggle store one; see scripts/language/live_labels.gd):
##   {"word": key, "form"?: form, "gender"?: "m"/"f"}       a word or one of its forms
##   {"phrase": id, "values"?: {...}}                       a phrase; values may hold references
## Either may add "in": "other" for the other taught language than `lang`.
func text(ref: Dictionary, lang: String) -> String:
	if str(ref.get("in", "")) == "other":
		lang = other(lang)
	if ref.has("phrase"):
		return phrase(str(ref.phrase), lang, ref.get("values", {}))
	return word(str(ref.get("word", "")), lang, str(ref.get("form", "")), str(ref.get("gender", "")))

## The other of the two taught languages.
func other(lang: String) -> String:
	return native if lang == foreign else foreign

## A line for the dialogue box: {"foreign": ..., "native": ...}. (A line in the native language
## with words to teach: native_line().)
func line(id: String, values: Dictionary = {}) -> Dictionary:
	return {"foreign": phrase(id, foreign, values), "native": phrase(id, native, values)}

## Personal names in `lang` for a person of `gender` ("f" or "m").
func names(lang: String, gender: String) -> Array:
	return name_data.get("names", {}).get(lang, {}).get(gender, [])

func number(n: int, lang: String, before_noun: bool = false) -> String:
	return rules(lang).number_words(n, before_noun)

func money(cents: int, lang: String) -> String:
	return rules(lang).money_words(cents)

func join(parts: PackedStringArray, lang: String) -> String:
	return rules(lang).list_join(parts)

## How `text` in `lang` is pronounced, shown under it (pinyin for Chinese: "Jiāxīn de
## gōnggong shì shéi?"); "" for languages without reading data.
func reading(text: String, lang: String) -> String:
	if text == "" or not reading_data.has(lang) or rules(lang) == null:
		return ""
	return rules(lang).reading(text, reading_data[lang])

## The reading of `text` piece by piece (rules_zh.gd reading_tokens()); [] for languages
## without reading data.
func reading_tokens(text: String, lang: String) -> Array:
	if text == "" or not reading_data.has(lang) or rules(lang) == null or not rules(lang).has_method("reading_tokens"):
		return []
	return rules(lang).reading_tokens(text, reading_data[lang])

## Characters of `text` that the reading data does not cover ([] when all are covered).
func reading_gaps(text: String, lang: String) -> PackedStringArray:
	if not reading_data.has(lang) or rules(lang) == null:
		return []
	return rules(lang).reading_gaps(text, reading_data[lang])
