extends RefCounted
## Derives the dictionaries the game has always used from the shared Lexicon
## (scripts/language/lexicon.gd), which is the only reader of data/words.json:
## vocabulary (key -> display text in the FOREIGN language of data/languages.json),
## categories (key -> category), aliases (old key -> word), catalog (prefab words ->
## {spanish, category, size}; "spanish" is the legacy name of the foreign text), sold_in
## (word -> store ids that may order it), category_rules (category -> what belongs there)
## and removed_with_objects (deleted words whose tagged objects are removed from town).
## Edit words.json, never these.
const Lexicon := preload("res://scripts/language/lexicon.gd")

static func load_all() -> Dictionary:
	var result := {"vocabulary": {}, "categories": {}, "aliases": {}, "catalog": {}, "sold_in": {}, "category_rules": {}, "removed_with_objects": []}
	var lexicon = Lexicon.shared()
	var parsed: Dictionary = lexicon.word_data
	if parsed.is_empty():
		return result
	result.category_rules = parsed.get("categories", {})
	result.aliases = parsed.get("aliases", {})
	result.removed_with_objects = parsed.get("removed_with_objects", [])
	var words: Dictionary = lexicon.words()
	for key in words:
		var entry: Dictionary = words[key]
		var text: String = lexicon.word(key, lexicon.foreign)
		result.vocabulary[key] = text
		result.categories[key] = entry.category
		if entry.has("sold_in"):
			result.sold_in[key] = entry.sold_in
		if entry.has("prefab_size"):
			result.catalog[key] = {"spanish": text, "category": entry.category, "size": entry.prefab_size}
	return result
