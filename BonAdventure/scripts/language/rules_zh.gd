extends "res://scripts/language/language_rules.gd"
## Traditional Chinese, Hong Kong written standard (Stage 4 decision, 4 Nov 2026; playable
## since 4 Nov 2026; its text is Claude's draft, awaiting review by a Chinese speaker).
## See language_rules.gd for the contract.
##
## Chinese nouns have no articles, gender or plural, so "definite" and "label" are the
## display text, except for kinship words. Their words.json forms list
## {"terms": [{"when": {...}, "text": ...}, ...]}: the first term whose "when" matches the
## family-tree details (word["kin"]: side, elder, link, by_marriage; family_tree.gd kin())
## and the person's "gender" is used. Without details (a poster) no term matches and the
## display text, which lists the terms ("爺爺 / 公公"), is shown.
const KIN_KEYS := ["side", "elder", "link", "by_marriage", "gender"]

func _term(word: Dictionary, gender: String) -> String:
	var kin: Dictionary = word.get("kin", {})
	if kin.is_empty():
		return str(word.get("text", ""))
	for term in word.get("forms", {}).get("terms", []):
		var matches := true
		var when: Dictionary = term.get("when", {})
		for key in when:
			var have: Variant = gender if key == "gender" else kin.get(key)
			if have != when[key]:
				matches = false
				break
		if matches:
			return str(term.get("text", ""))
	return str(word.get("text", ""))

func definite(word: Dictionary, gender: String) -> String:
	return _term(word, gender)

func label(word: Dictionary, gender: String) -> String:
	return _term(word, gender)

func word_problems(word: Dictionary) -> PackedStringArray:
	var found: PackedStringArray = []
	var forms: Dictionary = word.get("forms", {})
	for field in forms:
		if field != "terms":
			found.append("unknown Chinese forms field '%s'" % field)
	var terms: Variant = forms.get("terms", [])
	if not terms is Array:
		found.append("Chinese 'terms' must be a list")
		return found
	for term in terms:
		if not term is Dictionary or str(term.get("text", "")) == "" or not term.get("when", {}) is Dictionary:
			found.append("a Chinese term needs 'text' and a 'when' object: %s" % [term])
			continue
		for key in term.get("when", {}):
			if not key in KIN_KEYS:
				found.append("unknown kin detail '%s' in a Chinese term" % key)
	return found

func form_problem(word: Dictionary, form_name: String) -> String:
	if not form_name in FORMS:
		return "unknown form '%s'" % form_name
	return "" if str(word.get("text", "")) != "" else "no Chinese text"

const _DIGITS := ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]

## 0..999,999: 十一, 一百零一, 一千零一十, 二萬一千. `before_noun`: 兩 for 2 (兩美元).
func number_words(n: int, before_noun: bool = false) -> String:
	assert(n >= 0 and n <= 999999, "number_words out of range: %d" % n)
	if n == 0:
		return _DIGITS[0]
	if before_noun and n == 2:
		return "兩"
	if n < 10000:
		return _below_10000(n, true)
	var rest := n % 10000
	var head := _below_10000(n / 10000, true) + "萬"
	if rest == 0:
		return head
	return head + ("零" if rest < 1000 else "") + _below_10000(rest, false)

## `leading`: the number starts here, so 10..19 read 十.. rather than 一十..
func _below_10000(n: int, leading: bool) -> String:
	var units := ["千", "百", "十", ""]
	var values := [n / 1000, (n / 100) % 10, (n / 10) % 10, n % 10]
	var out := ""
	var zero := false
	var started := false
	for i in 4:
		var digit: int = values[i]
		if digit == 0:
			zero = started
			continue
		if zero:
			out += "零"
			zero = false
		if not (i == 2 and digit == 1 and not started and leading):
			out += _DIGITS[digit]
		out += units[i]
		started = true
	return out

## A US-dollar amount: 一百四十七美元三十八美仙 (Hong Kong: 仙 for cents). 0: 零美元.
func money_words(cents: int) -> String:
	var dollars := cents / 100
	var rest := cents % 100
	var money := ""
	if dollars > 0 or rest == 0:
		money = number_words(dollars, true) + "美元"
	if rest > 0:
		money += number_words(rest, true) + "美仙"
	return money

## 甲、乙和丙
func list_join(parts: PackedStringArray) -> String:
	if parts.size() <= 1:
		return "".join(parts)
	return "、".join(parts.slice(0, parts.size() - 1)) + "和" + parts[parts.size() - 1]

# --- Pinyin (Stage 4c, 4 Nov 2026) -----------------------------------------------------------
# `data` is data/pinyin_zh.json plus "names" (see its "about"). The text is split into the
# longest listed words and names, runs of numerals (一百 四十七, split after 萬 千 百) and
# single characters; a sentence (text with ，。？！) starts with a capital letter.

const _NUMERALS := "零一二兩三四五六七八九十百千萬"
const _NUMBER_BREAKS := "萬千百"
const _PUNCTUATION := {"，": ",", "。": ".", "？": "?", "！": "!", "、": ",", "：": ":", "；": ";", "（": "(", "）": ")", "「": "“", "」": "”"}
const _SENTENCE_MARKS := "，。？！"
const _SENTENCE_ENDS := ".?!"
## A syllable starting with one of these after another syllable in a word takes an apostrophe (孫兒 sūn'ér).
const _APOSTROPHE_BEFORE := "aeoāáǎàēéěèōóǒò"

var _segments: Dictionary = {}
var _segments_from: Variant = null
var _longest := 1

func reading(text: String, data: Dictionary) -> String:
	var tokens := _tokens(text, data)
	var sentence := false
	for mark in _SENTENCE_MARKS:
		if mark in text:
			sentence = true
	var out := ""
	var previous := ""
	var capital := sentence
	for token in tokens:
		var piece: String = token.text
		if token.kind == "word" or token.kind == "gap":
			if capital:
				piece = _capital(piece)
			capital = false
		if out != "" and token.kind != "close" and previous != "open":
			out += " "
		out += piece
		previous = token.kind
		if token.kind == "close" and piece in _SENTENCE_ENDS:
			capital = sentence
	return out

func reading_gaps(text: String, data: Dictionary) -> PackedStringArray:
	var gaps: PackedStringArray = []
	for token in _tokens(text, data):
		if token.kind == "gap" and not gaps.has(token.source):
			gaps.append(token.source)
	return gaps

## The reading piece by piece (24 Nov 2026, for spoken words, tools/voice_manifest.gd):
## [{"source": 蘋果, "reading": píngguǒ, "kind": word / gap / open / close / other}].
func reading_tokens(text: String, data: Dictionary) -> Array:
	var out: Array = []
	for token in _tokens(text, data):
		out.append({"source": token.source, "reading": token.text, "kind": token.kind})
	return out

## [{"text", "kind": word / gap / open / close / other, "source"}]
func _tokens(text: String, data: Dictionary) -> Array:
	_prepare(data)
	var chars: Dictionary = data.get("chars", {})
	var tokens: Array = []
	var i := 0
	var count := text.length()
	while i < count:
		var c := text[i]
		if c == " " or c == "　":
			i += 1
			continue
		if _PUNCTUATION.has(c):
			var mark: String = _PUNCTUATION[c]
			tokens.append({"text": mark, "kind": "open" if mark in "(“" else "close", "source": c})
			i += 1
			continue
		if not _is_han(c):
			var run := ""
			while i < count and not _is_han(text[i]) and not _PUNCTUATION.has(text[i]) and text[i] != " " and text[i] != "　":
				run += text[i]
				i += 1
			tokens.append({"text": run, "kind": "other", "source": run})
			continue
		var found := ""
		for size in range(mini(_longest, count - i), 0, -1):
			if _segments.has(text.substr(i, size)):
				found = text.substr(i, size)
				break
		if found != "":
			tokens.append({"text": _segments[found], "kind": "word", "source": found})
			i += found.length()
			continue
		if c in _NUMERALS:
			var number := ""
			while i < count and text[i] in _NUMERALS:
				number += text[i]
				i += 1
				if text[i - 1] in _NUMBER_BREAKS:
					break
			var made := _compose(number, chars)
			tokens.append({"text": made if made != "" else "?", "kind": "word" if made != "" else "gap", "source": number})
			continue
		var syllable := str(chars.get(c, ""))
		tokens.append({"text": syllable if syllable != "" else "?", "kind": "word" if syllable != "" else "gap", "source": c})
		i += 1
	return tokens

func _prepare(data: Dictionary) -> void:
	if is_same(_segments_from, data):
		return
	_segments_from = data
	_segments = {}
	var words: Dictionary = data.get("words", {})
	for word in words:
		_segments[word] = str(words[word])
	for person in data.get("names", []):
		var made := _compose(str(person), data.get("chars", {}))
		if made != "" and not _segments.has(person):
			_segments[person] = _capital(made)
	_longest = 1
	for word in _segments:
		_longest = maxi(_longest, str(word).length())

## One word from its characters' readings ("" when one is missing): 嘉欣 jiāxīn, 一百 yībǎi.
func _compose(text: String, chars: Dictionary) -> String:
	var out := ""
	for c in text:
		var syllable := str(chars.get(c, ""))
		if syllable == "":
			return ""
		if out != "" and syllable.left(1) in _APOSTROPHE_BEFORE:
			out += "'"
		out += syllable
	return out

func _capital(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)

func _is_han(c: String) -> bool:
	var code := c.unicode_at(0)
	return (code >= 0x3400 and code <= 0x9fff) or (code >= 0xf900 and code <= 0xfaff) or (code >= 0x20000 and code <= 0x2ffff)
