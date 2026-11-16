extends RefCounted
## Interface text (menus, HUD, help, hints, messages) in the player's NATIVE language, from
## data/phrases.json (UI Stage 3, 4 Nov 2026). Learning text (what NPCs say, the words) goes
## through Lexicon.line() and the Display Mode instead.
##   UiText.t("toast.zoo_gate_opened")            a phrase id, with optional {values}
##   UiText.place("School · Floor 2 · Science")   an English place name from the world code,
##                                                 translated part by part (group "places")
##   UiText.named("categories", "Food & Drink")    an English name in a lookup group
## Names are looked up by slug ("Food & Drink" -> "categories.food_drink"). A name without a
## phrase shows in English and is listed in `missing`, which the checks read.
const Lexicon := preload("res://scripts/language/lexicon.gd")

static var missing: Dictionary = {}

static func t(id: String, values: Dictionary = {}) -> String:
	var lexicon = Lexicon.shared()
	return lexicon.phrase(id, lexicon.native, values)

## Accented letters folded for slugs (escapes: code holds no non-English letters).
const FOLD := {"\u00e1": "a", "\u00e9": "e", "\u00ed": "i", "\u00f3": "o", "\u00fa": "u", "\u00fc": "u", "\u00f1": "n"}

## "Bakery / Café" -> "bakery_cafe" (accents folded, so "BAKERY / CAFE" finds the same phrase).
static func slug(english: String) -> String:
	var out := ""
	for c in english.to_lower():
		c = FOLD.get(c, c)
		out += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "_"
	while "__" in out:
		out = out.replace("__", "_")
	return out.trim_prefix("_").trim_suffix("_")

static func has(id: String) -> bool:
	return Lexicon.shared().phrases.has(id)

## `english` in the native language via "<group>.<slug>"; English when there is no phrase.
static func named(group: String, english: String) -> String:
	if english == "":
		return ""
	var id := group + "." + slug(english)
	if has(id):
		return t(id)
	missing[id] = english
	return english

## A word of data/words.json in `lang` (the card, journal and saved words); a key without
## an entry shows as its capitalized key.
static func word(key: String, lang: String) -> String:
	var lexicon = Lexicon.shared()
	if lexicon.has_word(key) and lexicon.word_entry(key, lang).text != "":
		return lexicon.word(key, lang)
	return key.replace("_", " ").capitalize()

## Text that may be a phrase id (seat and action metadata hold ids): the phrase when it is
## one, otherwise the text itself.
static func maybe(text: String) -> String:
	return t(text) if has(text) else text

## Place names are built as "Hospital · Floor 2 · Patient Rooms, ICU & Surgery": each part
## is translated on its own ("Floor 2" through places.floor_n).
static func place(english: String) -> String:
	var parts: PackedStringArray = []
	for part in english.split(" · "):
		var words := part.strip_edges().split(" ")
		if words.size() == 2 and words[0] == "Floor" and words[1].is_valid_int():
			parts.append(t("places.floor_n", {"n": int(words[1])}))
		else:
			parts.append(named("places", part.strip_edges()))
	return " · ".join(parts)
