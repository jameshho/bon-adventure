extends "res://scripts/language/language_rules.gd"
## Spanish (Mexican) grammar. See language_rules.gd for the contract.
##
## words.json "forms" for Spanish, needed only by words that fill a {slot:form} phrase slot:
##   {"m": "vendedor", "f": "vendedora"}           a person word with both genders
##   {"noun": "persona", "gender": "f"}            a noun with one fixed gender
##   {"noun": "agua", "gender": "f", "article": "el"}   an article exception
## The display text ("text") must equal what the forms produce: "el vendedor / la vendedora",
## "la persona". tools/language_check.gd checks that, so the two never drift apart.

const ARTICLES := {"m": "el", "f": "la"}

func definite(word: Dictionary, gender: String) -> String:
	var forms: Dictionary = word.get("forms", {})
	if forms.has("noun"):
		return "%s %s" % [forms.get("article", ARTICLES.get(forms.get("gender", ""), "")), forms.noun]
	if forms.has(gender) and ARTICLES.has(gender):
		return "%s %s" % [ARTICLES[gender], forms[gender]]
	return ""

func label(word: Dictionary, gender: String) -> String:
	if word.get("forms", {}).is_empty():
		return str(word.get("text", ""))
	return definite(word, gender)

func word_problems(word: Dictionary) -> PackedStringArray:
	var forms: Dictionary = word.get("forms", {})
	var found: PackedStringArray = []
	if forms.is_empty():
		return found
	var expected := ""
	if forms.has("noun"):
		if not ARTICLES.has(forms.get("gender", "")):
			found.append("forms.noun needs gender 'm' or 'f'")
		for field in forms:
			if not field in ["noun", "gender", "article"]:
				found.append("unknown forms field '%s'" % field)
		expected = definite(word, "")
	elif forms.has("m") and forms.has("f"):
		if forms.size() != 2:
			found.append("person forms take only 'm' and 'f'")
		expected = "%s / %s" % [definite(word, "m"), definite(word, "f")]
	else:
		found.append("forms need either 'noun' + 'gender' or both 'm' and 'f'")
	if expected != "" and expected != str(word.get("text", "")):
		found.append("forms make '%s' but text is '%s'" % [expected, word.get("text", "")])
	return found

func form_problem(word: Dictionary, form_name: String) -> String:
	if not form_name in FORMS:
		return "unknown form '%s'" % form_name
	if form_name == "label":
		return "" if str(word.get("text", "")) != "" else "no Spanish text"
	if word.get("forms", {}).is_empty():
		return "needs Spanish 'forms' (gender and noun) to make the %s form" % form_name
	return ""

# --- Numbers (moved here from currency.gd, 4 Nov 2026) ----------------------------------

const _UNDER_30 := ["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve",
		"diez", "once", "doce", "trece", "catorce", "quince", "dieciséis", "diecisiete", "dieciocho",
		"diecinueve", "veinte", "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco",
		"veintiséis", "veintisiete", "veintiocho", "veintinueve"]
const _TENS := ["", "", "", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"]
const _HUNDREDS := ["", "ciento", "doscientos", "trescientos", "cuatrocientos", "quinientos",
		"seiscientos", "setecientos", "ochocientos", "novecientos"]

## 0..999,999. Before a (masculine) noun, and before "mil", "uno" becomes "un" and
## "veintiuno" "veintiún": "un dólar", "veintiún mil", "ciento un dólares".
func number_words(n: int, before_noun: bool = false) -> String:
	assert(n >= 0 and n <= 999999, "number_words out of range: %d" % n)
	var words := ""
	if n < 1000:
		words = _hundreds_words(n)
	else:
		var thousands := n / 1000
		var rest := n % 1000
		var head := "mil" if thousands == 1 else _apocope(_hundreds_words(thousands)) + " mil"
		words = head if rest == 0 else head + " " + _hundreds_words(rest)
	return _apocope(words) if before_noun else words

func _hundreds_words(n: int) -> String:
	if n < 30:
		return _UNDER_30[n]
	if n < 100:
		return _TENS[n / 10] if n % 10 == 0 else "%s y %s" % [_TENS[n / 10], _UNDER_30[n % 10]]
	if n == 100:
		return "cien"
	var rest := n % 100
	return _HUNDREDS[n / 100] if rest == 0 else _HUNDREDS[n / 100] + " " + _hundreds_words(rest)

func _apocope(words: String) -> String:
	if words.ends_with("veintiuno"):
		return words.trim_suffix("veintiuno") + "veintiún"
	if words.ends_with("uno"):
		return words.trim_suffix("uno") + "un"
	return words

## "un dólar", "veinticinco centavos", "ciento un dólares con un centavo". 0: "cero dólares".
func money_words(cents: int) -> String:
	var dollars := cents / 100
	var rest := cents % 100
	var money := ""
	if dollars > 0 or rest == 0:
		money = "%s %s" % [number_words(dollars, true), "dólar" if dollars == 1 else "dólares"]
	if rest > 0:
		var part := "%s %s" % [number_words(rest, true), "centavo" if rest == 1 else "centavos"]
		money = part if money == "" else money + " con " + part
	return money

func list_join(parts: PackedStringArray) -> String:
	return ", ".join(parts)

## The two compulsory contractions: de + el → del, a + el → al ("Saca la botella del
## contenedor", "Ve al estante B"). Only "el" the article; "él" (he) has an accent.
func polish(text: String) -> String:
	return text.replace(" de el ", " del ").replace(" a el ", " al ")
