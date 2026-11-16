extends "res://scripts/language/language_rules.gd"
## English (US) grammar. See language_rules.gd for the contract.
##
## English nouns have no gender, so every form is built from the display text and English
## words need no "forms" in words.json. A word may still give {"noun": "..."} when its
## display text is not the bare noun.

func _noun(word: Dictionary) -> String:
	return str(word.get("forms", {}).get("noun", word.get("text", "")))

func definite(word: Dictionary, _gender: String) -> String:
	var noun := _noun(word)
	return "" if noun == "" else "the " + noun

func label(word: Dictionary, _gender: String) -> String:
	return _noun(word)

func word_problems(word: Dictionary) -> PackedStringArray:
	var found: PackedStringArray = []
	for field in word.get("forms", {}):
		if field != "noun":
			found.append("unknown English forms field '%s'" % field)
	return found

func form_problem(word: Dictionary, form_name: String) -> String:
	if not form_name in FORMS:
		return "unknown form '%s'" % form_name
	return "" if _noun(word) != "" else "no English text"

const _ONES := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
		"ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
		"eighteen", "nineteen"]
const _TENS := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

## 0..999,999, US style without "and": "one hundred forty-seven", "twenty-one thousand".
func number_words(n: int, _before_noun: bool = false) -> String:
	assert(n >= 0 and n <= 999999, "number_words out of range: %d" % n)
	if n < 1000:
		return _hundreds_words(n)
	var rest := n % 1000
	var head := _hundreds_words(n / 1000) + " thousand"
	return head if rest == 0 else head + " " + _hundreds_words(rest)

func _hundreds_words(n: int) -> String:
	if n < 20:
		return _ONES[n]
	if n < 100:
		return _TENS[n / 10] if n % 10 == 0 else "%s-%s" % [_TENS[n / 10], _ONES[n % 10]]
	var rest := n % 100
	var head: String = _ONES[n / 100] + " hundred"
	return head if rest == 0 else head + " " + _hundreds_words(rest)

## "one dollar", "twenty-five cents", "one hundred one dollars and one cent". 0: "zero dollars".
func money_words(cents: int) -> String:
	var dollars := cents / 100
	var rest := cents % 100
	var money := ""
	if dollars > 0 or rest == 0:
		money = "%s %s" % [number_words(dollars), "dollar" if dollars == 1 else "dollars"]
	if rest > 0:
		var part := "%s %s" % [number_words(rest), "cent" if rest == 1 else "cents"]
		money = part if money == "" else money + " and " + part
	return money

func list_join(parts: PackedStringArray) -> String:
	return ", ".join(parts)
