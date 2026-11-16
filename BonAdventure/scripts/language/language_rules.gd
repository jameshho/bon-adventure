extends RefCounted
## The grammar every language must supply. Each language has one rules module
## (rules_en.gd, rules_es.gd, ...) that extends this script and overrides EVERY function
## below; data/languages.json names the module. Game code never builds a sentence out
## of words itself: phrases (data/phrases.json) ask for a form with {slot:form}, and the
## Lexicon calls form() here.
##
## A `word` argument is {"key": word key, "text": the word's display text in this language
## (words.json "text"), "forms": the word's grammar data in this language (words.json
## "forms", {} when the word has none), "kin": family-tree details for a relationship word
## ({} otherwise; see family_tree.gd kin())}. `gender` is "m" or "f": the gender of the PERSON
## a word describes (a clerk, a relative), used by words that have both forms.
##
## Adding a form: add its name to FORMS, a function here that calls _missing(), a case in
## form(), an override in EVERY rules module and samples in data/language_samples.json.
## tools/language_check.gd fails until all of that exists.
## See docs/guides/ARCHITECTURE_REVIEW_PART1.md#adding-or-changing-a-language.

## The forms a phrase may request with {slot:form}.
const FORMS := ["definite", "label"]

## Names of functions a module failed to override (filled when one is called).
var missing: PackedStringArray = []

func form(word: Dictionary, form_name: String, gender: String) -> String:
	match form_name:
		"definite":
			return definite(word, gender)
		"label":
			return label(word, gender)
	push_error("language_rules: unknown form '%s'" % form_name)
	return ""

## "the salesperson", "el vendedor". Empty when the word lacks the data to build it.
func definite(_word: Dictionary, _gender: String) -> String:
	return _missing("definite")

## How a word is written on a label or card for one person of `gender`: "la prima" in
## Spanish (the article shows the gender), "cousin" in English. Words without person data
## (mayor, before) use their display text.
func label(_word: Dictionary, _gender: String) -> String:
	return _missing("label")

## Problems with one word's data in this language ("" list when fine): wrong forms
## shape, or forms that disagree with the display text.
func word_problems(_word: Dictionary) -> PackedStringArray:
	_missing("word_problems")
	return []

## Can this word fill a {slot:form_name} slot? "" when yes, else the reason.
func form_problem(_word: Dictionary, _form_name: String) -> String:
	return _missing("form_problem")

## Whole numbers 0..999,999 in words. `before_noun`: the form used directly before a
## noun ("un dólar", not "uno dólar"), for languages that change it.
func number_words(_n: int, _before_noun: bool = false) -> String:
	return _missing("number_words")

## A US-dollar amount in words: "one hundred forty-seven dollars and thirty-eight cents".
func money_words(_cents: int) -> String:
	return _missing("money_words")

## Joins already-formatted list items ("2 × apple", "1 × milk").
func list_join(_parts: PackedStringArray) -> String:
	return _missing("list_join")

## Optional (reading(), reading_gaps() and polish() need not be overridden): how `text` is
## pronounced, from the language's reading data (languages.json "reading"). "" = no reading.
func reading(_text: String, _data: Dictionary) -> String:
	return ""

## Optional, with reading(): characters of `text` the reading data does not cover.
func reading_gaps(_text: String, _data: Dictionary) -> PackedStringArray:
	return []

## Optional: tidies a phrase after its slots are filled, for joins that only appear once
## words meet (Spanish "de" + "el" is written "del"). Default: the text unchanged.
func polish(text: String) -> String:
	return text

func _missing(function_name: String) -> String:
	if not missing.has(function_name):
		missing.append(function_name)
		push_error("%s does not implement %s()" % [get_script().resource_path, function_name])
	return ""
