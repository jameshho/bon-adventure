extends RefCounted
## Shop and cashier minigame helpers: the rules from data/shops.json, plus the few
## shop-specific ways of filling phrases (order lists, word pairs, money amounts). All
## words and sentences come from the shared Lexicon (scripts/language/lexicon.gd);
## nothing here knows a language.
const Lexicon := preload("res://scripts/language/lexicon.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const PATH := "res://data/shops.json"

var lexicon
var native: String:
	get: return lexicon.native
var foreign: String:
	get: return lexicon.foreign
var stores: Dictionary = {}
## Cashier counters (money-selection minigame): store id -> {zone, npc, npc_gender}.
var cashiers: Dictionary = {}

func _init(shared_lexicon = null) -> void:
	lexicon = shared_lexicon if shared_lexicon != null else Lexicon.shared()
	if not FileAccess.file_exists(PATH):
		push_error("Missing " + PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("Unreadable " + PATH)
		return
	stores = parsed.get("stores", {})
	cashiers = parsed.get("cashiers", {})

func store_rules(store_id: String) -> Dictionary:
	return stores.get(store_id, {})

func word_in(key: String, lang: String) -> String:
	return lexicon.word(key, lang)

## A word reference for a {slot:form} phrase value: the NPC's role word and gender.
func role(word_key: String, gender: String) -> Dictionary:
	return {"word": word_key, "gender": gender}

## The speaker card of a worker, who has no personal name: "El Vendedor".
func speaker(word_key: String, gender: String) -> String:
	if word_key == "":
		return ""
	return lexicon.word(word_key, foreign, "definite", gender).capitalize()

## The speaker in both languages, so the dialogue box can follow the Display Mode.
func speaker_line(word_key: String, gender: String) -> Dictionary:
	if word_key == "":
		return {"foreign": "", "native": ""}
	return {"foreign": speaker(word_key, gender), "native": lexicon.word(word_key, native, "definite", gender).capitalize()}

## "2 × la manzana, 1 × la leche".
func items_text(items: Dictionary, lang: String) -> String:
	var parts: PackedStringArray = []
	for key in items:
		parts.append(phrase("shop.item_count", lang, {"count": int(items[key]), "item": {"word": str(key)}}))
	return lexicon.join(parts, lang)

## "la manzana = apple, ..." for the final reveal: foreign word, then its native meaning.
func pairs_text(keys: Array) -> String:
	var parts: PackedStringArray = []
	for key in keys:
		parts.append(phrase("shop.word_pair", foreign, {"foreign": word_in(str(key), foreign), "native": word_in(str(key), native)}))
	return lexicon.join(parts, foreign)

func phrase(id: String, lang: String, values: Dictionary = {}) -> String:
	return lexicon.phrase(id, lang, values)

## A dialogue box line {"foreign", "native"}; the box reveals the native line on request.
func line(id: String, values: Dictionary = {}) -> Dictionary:
	return lexicon.line(id, values)

## Item list values for phrase(): {foreign code: text, native code: text}.
func items_values(items: Dictionary) -> Dictionary:
	return {foreign: items_text(items, foreign), native: items_text(items, native)}

## An amount for phrase(): in words in the foreign language, in digits ("$147.38") in the
## native one, so the translation shows the number to count out.
func money_values(cents: int) -> Dictionary:
	return {foreign: lexicon.money(cents, foreign), native: Currency.usd(cents)}
