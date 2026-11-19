extends SceneTree
## Vocabulary usage report (developer tool, 7 Nov 2026; Stage A of the vocabulary tracking
## work, guide: docs/guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report). Loads the whole
## town once (every building unit; set VT_FOCUS=all) and lists, for every word of
## data/words.json, where it is placed and which minigames test or only show it.
##
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://tools/vocabulary_report.gd
##       prints FAIL: lines for hard errors (unknown word keys) and a summary line; writes nothing.
##       This is the run_checks.py check `vocabulary_report`.
##   ... --script res://tools/vocabulary_report.gd -- --write
##       also refreshes docs/guides/vocabulary-report/report.csv and summary.md, and the game guide's
##       per-game word list docs/game/words.md (16 Nov 2026; the only files it writes): only
##       when there is no hard error and the content changed (the date alone is not a change),
##       so an unchanged town leaves all three untouched. Prints
##       "VOCABULARY REPORT FILES: updated" or "unchanged". The full suite runs it this way
##       (run_checks.py `vocabulary_report`, user decision 8 Nov 2026), so the report follows
##       every change to words, buildings or minigames; commit the refreshed files with it.
##
## Placed: nodes with a `word_key` or `exterior_word` meta (aliases resolved; a node inside
## another node with the same word counts once), per building unit (data/buildings.json parts,
## else "base") and site (the town zone, data/zones.json, as the journal's By Area assigns it).
## Clickable: objects the journal's By Area index can pick (area_vocabulary.gd); a placed word
## with none cannot be studied. (Replaces docs/word_audit.gd, 7 Nov 2026.)
## "saved" = from the saved scenes (the node has an owner); "runtime" = built by scripts at load
## (NPC roles, generated props). Labels: world Label3Ds bound to a word (live_labels.gd).
## Tests: games whose question has one clear tested word (user decision, 7 Nov 2026):
## shop orders (the item; only the store's `order_words` when data/shops.json lists them,
## as shop_order.gd build_pool() does since 14 Nov 2026), family (the relative), restaurant (the dish), warehouse (the item,
## and since 8 Nov 2026 the colour and size its sentence names),
## flight (the time expression's word and the destination country; redesign of 7 Nov 2026),
## grammar class (the noun of Chinese measure-word questions), Library Helper (the book's topic and
## its category, 17 Nov 2026). Shows: words a game displays
## without testing them one at a time (restaurant properties, police clues and objects — two
## clue words per round, so not tracked — the month and weekday words of the family game and
## the weekday words of the flight board). Cashier money amounts and flight clock times and
## dates are generated language, not words.
## Dialogue: only words that fill a {slot:form} ('slots' in data/phrases.json) are reported;
## words written as plain text inside sentences are not matched.
## Hard errors (FAIL): word keys used in game data, scenes, labels, aliases or phrase slots that
## data/words.json does not have. Everything else is report-only.
const Lexicon := preload("res://scripts/language/lexicon.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const LiveLabels := preload("res://scripts/language/live_labels.gd")
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const FamilyQuestions := preload("res://scripts/learning/family_questions.gd")
const FlightQuestions := preload("res://scripts/learning/flight_questions.gd")
const OUT_DIR := "res://docs/guides/vocabulary-report/"
## Generated per-game word list of the game guide (docs/game/README.md), 16 Nov 2026.
const GUIDE_WORDS := "res://docs/game/words.md"
const WAREHOUSE_GOODS := "res://scripts/learning/warehouse_goods.gd"
const GRAMMAR_DIR := "res://data/grammar_class/"

var failures := 0
var checks := 0
var failed: Dictionary = {}
var words: Dictionary = {}
var aliases: Dictionary = {}
var removed: Array = []
var categories: Dictionary = {}
## key -> {"saved": {"unit/zone": n}, "runtime": {...}, "labels": {...}}
var placed: Dictionary = {}
## key -> {game id: true}
var tests: Dictionary = {}
var shows: Dictionary = {}
## removed_with_objects key -> places it is still found
var removed_placed: Dictionary = {}
## key -> clickable objects (the journal's By Area index, area_vocabulary.gd)
var clickable: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok and not failed.has(label):
		failed[label] = true
		failures += 1
		print("FAIL: " + label)

func resolve(raw: String) -> String:
	return str(aliases.get(raw, raw))

## Records a game's word: checks the key exists, then files it under tests or shows.
func use(table: Dictionary, game: String, raw: String) -> void:
	var key := resolve(raw)
	check(words.has(key), "unknown %s word key: %s" % [game, raw])
	if not words.has(key):
		return
	if not table.has(key):
		table[key] = {}
	table[key][game] = true

func run() -> void:
	var lexicon = Lexicon.shared()
	var data: Dictionary = lexicon.word_data
	words = lexicon.words()
	aliases = data.get("aliases", {})
	removed = data.get("removed_with_objects", [])
	categories = data.get("categories", {})
	for alias in aliases:
		check(words.has(str(aliases[alias])), "alias %s points to a missing word %s" % [alias, aliases[alias]])
	for key in words:
		check(categories.has(str(words[key].get("category", ""))), "word %s has an unknown category" % key)
	_game_words()
	var slot_phrases := _phrase_slots()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(30):
		await process_frame
	var town: Node3D = game.apartment
	var loaded: Array = town.get_meta("loaded_units", [])
	check(loaded.size() == ModularTown.registry().size(), "every building unit is loaded (VT_FOCUS=all)")
	_placements(game, town)
	for target in game.area_vocabulary.assignments:
		var key: String = game.area_vocabulary.assignments[target].key
		clickable[key] = int(clickable.get(key, 0)) + 1
	for key in game.area_vocabulary.unknown_keys:
		check(false, "unknown clickable word key: %s" % key)
	_labels(game, town)
	var duplicates := _duplicates()
	var rows := _rows(slot_phrases)
	var unplaced: Array = rows.filter(func(row): return row.unused)
	print("VOCABULARY REPORT: %d words; %d placed in saved scenes, %d only at runtime, %d unplaced and unused; %d tested by a game; %d duplicate groups; %d removed words still placed" % [
		words.size(),
		rows.filter(func(row): return row.saved > 0).size(),
		rows.filter(func(row): return row.saved == 0 and row.runtime > 0).size(),
		unplaced.size(),
		tests.size(),
		duplicates.size(),
		removed_placed.size()])
	if "--write" in OS.get_cmdline_user_args():
		if failures > 0:
			print("VOCABULARY REPORT FILES: not written (fix the failures above first)")
		else:
			_write(rows, duplicates, slot_phrases, unplaced)
	print("VOCABULARY REPORT CHECK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## The word keys of the minigame data (decision 6 for tests).
func _game_words() -> void:
	var stores: Dictionary = _json("res://data/shops.json").get("stores", {})
	for key in words:
		for store in words[key].get("sold_in", []):
			check(stores.has(str(store)), "word %s is sold_in an unknown store %s" % [key, store])
			# Only the words the clerk can order (shop_order.gd build_pool(), 14 Nov 2026).
			var allowed: Array = stores.get(str(store), {}).get("order_words", [])
			if allowed.is_empty() or allowed.has(key):
				use(tests, "shop_" + str(store), key)
	for pair in FamilyTree.WORDS.values():
		for raw in pair:
			use(tests, "family_dr_li", str(raw))
	for raw in FamilyQuestions.MONTHS:
		use(shows, "family_dr_li", str(raw))
	var restaurant := _json("res://data/restaurant_game.json")
	for dish in restaurant.get("dishes", []):
		use(tests, "restaurant_twinkle", str(dish.word))
	for group in restaurant.get("properties", {}).values():
		if not group is Dictionary:
			continue
		for entry in group.values():
			if entry is Dictionary and entry.has("word"):
				use(shows, "restaurant_twinkle", str(entry.word))
	# Warehouse goods: the word of each _item(...) call (the items are built in code).
	var source := FileAccess.get_file_as_string(WAREHOUSE_GOODS)
	var item := RegEx.create_from_string("\\n\\t+_item\\([^\\n]*?, \"([^\"]+)\", weights")
	var found := item.search_all(source)
	check(not found.is_empty(), "warehouse items found in " + WAREHOUSE_GOODS)
	for match in found:
		use(tests, "warehouse_ramon", match.get_string(1))
	# The colours and sizes task sentences name (8 Nov 2026: brown and medium are words; the
	# colour question tests its colour). warehouse_tasks.gd COLOR_WORDS / SIZE_WORDS.
	var tasks_script = load("res://scripts/learning/warehouse_tasks.gd")
	for raw in tasks_script.COLOR_WORDS.values() + tasks_script.SIZE_WORDS.values():
		use(tests, "warehouse_ramon", str(raw))
	for raw in _json("res://data/flight_game.json").get("countries", []):
		use(tests, "flight_bruno", str(raw))
	# The time words a question can test (flight_questions.gd time_key()).
	for raw in FlightQuestions.DAY_WORDS.values() + FlightQuestions.PARTS.values() + FlightQuestions.WEEKDAYS + FlightQuestions.HOUR_WORDS.values():
		use(tests, "flight_bruno", str(raw))
	for raw in FlightQuestions.WEEKDAYS:
		use(shows, "flight_bruno", str(raw))
	for file in DirAccess.get_files_at(GRAMMAR_DIR):
		if not file.ends_with(".json"):
			continue
		for question in _json(GRAMMAR_DIR + file).get("questions", []):
			if question.has("noun"):
				# Only the Chinese bank has nouns; the game id is the activity's (practice_log.gd).
				use(tests, "grammar_lana", str(question.noun))
	# Mystery Doors (9 Nov 2026): every door colour and shape can be a clue's tested word.
	var mystery = load("res://scripts/buildings/mystery.gd")
	for raw in mystery.COLORS.keys() + mystery.SHAPES:
		use(tests, "mystery_luna", str(raw))
	# Library Helper (17 Nov 2026): a book's first placement tests its topic and its category word.
	var library = load("res://scripts/buildings/library.gd")
	for raw in library.BOOK_WORDS.values():
		use(tests, "library_rosa", str(raw))
	for category in library.CATEGORIES:
		use(tests, "library_rosa", str(category[3]))
	var detective := _json("res://data/detective_game.json")
	for game in ["lineup", "evidence"]:
		var id: String = "lineup_rocco" if game == "lineup" else "evidence_mimi"
		var section: Dictionary = detective.get(game, {})
		for clue in section.get("clues", []):
			for raw in clue.get("words", []):
				# Evidence rounds (8 Nov 2026) are decided by one clue word and tracked.
				use(tests if game == "evidence" else shows, id, str(raw))
		for object in section.get("objects", {}).values():
			use(shows, id, str(object.word))

## Phrase id -> {slot: category}, checking each category exists.
func _phrase_slots() -> Dictionary:
	var result: Dictionary = {}
	var phrases: Dictionary = Lexicon.shared().phrases
	for id in phrases:
		var slots: Dictionary = phrases[id].get("slots", {})
		if slots.is_empty():
			continue
		result[id] = slots
		for slot in slots:
			check(categories.has(str(slots[slot])), "phrase %s slot %s names an unknown category %s" % [id, slot, slots[slot]])
	return result

func _unit_of(town: Node3D, node: Node) -> String:
	if not town.is_ancestor_of(node):
		return "main"
	var path := str(town.get_path_to(node))
	var best := ""
	var best_length := 0
	var units := ModularTown.registry()
	for unit in units:
		for part in units[unit].parts:
			var prefix := str(part)
			if (path == prefix or path.begins_with(prefix + "/")) and prefix.length() > best_length:
				best = unit
				best_length = prefix.length()
	return best if best != "" else "base"

func _site_of(game, town: Node3D, node: Node) -> String:
	var zone: String = game.area_vocabulary.zone_for(node)
	if zone == "" and node is Node3D and node.is_inside_tree():
		zone = game.zones.resolve_local(town.to_local((node as Node3D).global_position))
	return zone if zone != "" else "-"

func _count(key: String, kind: String, where: String) -> void:
	if not placed.has(key):
		placed[key] = {"saved": {}, "runtime": {}, "labels": {}}
	placed[key][kind][where] = int(placed[key][kind].get(where, 0)) + 1

func _placements(game, town: Node3D) -> void:
	for node in game.find_children("*", "", true, false):
		var raw := str(node.get_meta("exterior_word", node.get_meta("word_key", "")))
		if raw == "":
			continue
		var key := resolve(raw)
		# A word inside another node with the same word is one object.
		var parent: Node = node.get_parent()
		var nested := false
		while parent != null and parent != game:
			if resolve(str(parent.get_meta("exterior_word", parent.get_meta("word_key", "")))) == key:
				nested = true
				break
			parent = parent.get_parent()
		if nested:
			continue
		var where := _unit_of(town, node) + "/" + _site_of(game, town, node)
		var kind := "saved" if node.owner != null else "runtime"
		if raw in removed or key in removed:
			removed_placed[raw] = removed_placed.get(raw, []) + [where + " (" + kind + ")"]
			continue
		check(words.has(key), "unknown scene word key: %s (%s)" % [raw, where.get_slice("/", 0)])
		if words.has(key):
			_count(key, kind, where)

func _labels(game, town: Node3D) -> void:
	for label in get_nodes_in_group(LiveLabels.GROUP):
		var keys: Array = []
		_ref_words(label.get_meta("lexicon_text", {}), keys)
		for raw in keys:
			var key := resolve(raw)
			check(words.has(key), "unknown label word key: %s" % raw)
			if words.has(key):
				_count(key, "labels", _unit_of(town, label) + "/" + _site_of(game, town, label))

## Word keys inside a Lexicon text reference ({"word": key}, nested values).
func _ref_words(ref: Variant, into: Array) -> void:
	if ref is Dictionary:
		if ref.has("word"):
			into.append(str(ref.word))
		for value in ref.values():
			if value is Dictionary or value is Array:
				_ref_words(value, into)
	elif ref is Array:
		for value in ref:
			_ref_words(value, into)

## Groups of keys that mean the same thing twice: an alias that is also a word key, or two
## word keys with the same text in one language. Report-only.
func _duplicates() -> Array:
	var groups: Array = []
	for alias in aliases:
		if words.has(alias):
			groups.append({"kind": "alias is also a word", "language": "", "text": alias, "keys": [alias, str(aliases[alias])]})
	for key in words:
		if key.ends_with("s") and words.has(key.trim_suffix("s")):
			groups.append({"kind": "singular and plural", "language": "", "text": key, "keys": [key.trim_suffix("s"), key]})
	for code in Lexicon.shared().playable_codes():
		var by_text: Dictionary = {}
		for key in words:
			var text := str(words[key].get("text", {}).get(code, "")).strip_edges().to_lower()
			if text == "":
				continue
			by_text[text] = by_text.get(text, []) + [key]
		for text in by_text:
			if by_text[text].size() > 1:
				groups.append({"kind": "same text", "language": code, "text": text, "keys": by_text[text]})
	return groups

func _places(table: Dictionary) -> String:
	var parts: Array = []
	var keys := table.keys()
	keys.sort()
	for where in keys:
		parts.append("%s:%d" % [where, table[where]])
	return "; ".join(parts)

func _total(table: Dictionary) -> int:
	var n := 0
	for where in table:
		n += int(table[where])
	return n

func _rows(slot_phrases: Dictionary) -> Array:
	var rows: Array = []
	var keys := words.keys()
	keys.sort()
	for key in keys:
		var category := str(words[key].get("category", ""))
		var place: Dictionary = placed.get(key, {"saved": {}, "runtime": {}, "labels": {}})
		var slots: Array = []
		for id in slot_phrases:
			if (slot_phrases[id] as Dictionary).values().has(category):
				slots.append(str(id))
		var tested: Array = tests.get(key, {}).keys()
		tested.sort()
		var shown: Array = shows.get(key, {}).keys()
		shown.sort()
		var row := {"key": key, "category": category,
			"clickable": int(clickable.get(key, 0)), "saved": _total(place.saved), "runtime": _total(place.runtime), "labels": _total(place.labels),
			"saved_where": _places(place.saved), "runtime_where": _places(place.runtime), "labels_where": _places(place.labels),
			"tests": tested, "shows": shown, "slots": slots}
		row.unused = row.saved + row.runtime + row.labels == 0 and tested.is_empty() and shown.is_empty()
		rows.append(row)
	return rows

func _csv(value: Variant) -> String:
	var text := str(value)
	if text.contains(",") or text.contains("\"") or text.contains("\n"):
		return "\"" + text.replace("\"", "\"\"") + "\""
	return text

func _write(rows: Array, duplicates: Array, slot_phrases: Dictionary, unplaced: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var dup_keys: Dictionary = {}
	for group in duplicates:
		for key in group.keys:
			dup_keys[key] = true
	var lines: Array = ["word_key,category,clickable,placed_saved,placed_saved_where,placed_runtime,placed_runtime_where,labels,labels_where,tests,shows,phrase_slots,flags"]
	for row in rows:
		var flags: Array = []
		if row.unused:
			flags.append("unplaced_unused")
		elif row.saved + row.runtime + row.labels == 0:
			flags.append("unplaced")
		elif row.clickable == 0 and row.saved + row.runtime > 0:
			flags.append("not_clickable")
		if dup_keys.has(row.key):
			flags.append("duplicate")
		lines.append(",".join([row.key, row.category, row.clickable, row.saved, row.saved_where, row.runtime, row.runtime_where, row.labels, row.labels_where,
			" ".join(row.tests), " ".join(row.shows), " ".join(row.slots), " ".join(flags)].map(_csv)))
	var csv := "\n".join(lines) + "\n"
	var summary := _summary(rows, duplicates, slot_phrases, unplaced)
	var guide := _guide_words()
	if csv == _read(OUT_DIR + "report.csv") and _undated(summary) == _undated(_read(OUT_DIR + "summary.md")) \
			and _undated(guide) == _undated(_read(GUIDE_WORDS)):
		print("VOCABULARY REPORT FILES: unchanged")
		return
	var file := FileAccess.open(OUT_DIR + "report.csv", FileAccess.WRITE)
	file.store_string(csv)
	file.close()
	file = FileAccess.open(OUT_DIR + "summary.md", FileAccess.WRITE)
	file.store_string(summary)
	file.close()
	file = FileAccess.open(GUIDE_WORDS, FileAccess.WRITE)
	file.store_string(guide)
	file.close()
	print("VOCABULARY REPORT FILES: updated %sreport.csv, summary.md and %s (commit them with the change)" % [OUT_DIR, GUIDE_WORDS])

## The game guide's word list: for every game named in data/phrases.json `games`, the words it
## tests and only shows, in English, Spanish and Chinese (16 Nov 2026, user: the guide reflects
## the game data; data/words.json stays the only word source).
func _guide_words() -> String:
	var lexicon = Lexicon.shared()
	var names: Dictionary = {}
	for phrase_id in lexicon.phrases:
		if str(phrase_id).begins_with("games."):
			names[str(phrase_id).trim_prefix("games.")] = lexicon.phrases[phrase_id]
	var out: Array = ["# Words in each minigame", "",
		"[← Minigames](minigames.md) · [Game guide](README.md)", "",
		"Generated %s by `tools/vocabulary_report.gd -- --write` from the game data. **Do not edit by hand**: words live in `data/words.json` and each game's data file; rerun the report after changing them. \"Tested\" words are the ones a question checks and the journal tracks; \"shown\" words appear in the game without being checked one at a time. Phrases (dialogue) are not listed. Where each word is placed in town: [vocabulary report](../guides/vocabulary-report/summary.md)." % Time.get_date_string_from_system(),
		""]
	for id in names:
		var name: String = str(names[id].get("en", id)) if names[id] is Dictionary else str(id)
		var tested: Array = tests.keys().filter(func(key): return tests[key].has(id))
		var shown: Array = shows.keys().filter(func(key): return shows[key].has(id) and not (tests.has(key) and tests[key].has(id)))
		tested.sort()
		shown.sort()
		out.append("## " + name)
		out.append("")
		out.append("Activity id `%s`. Tested: %d · shown only: %d." % [id, tested.size(), shown.size()])
		out.append("")
		if tested.is_empty() and shown.is_empty():
			out.append("No words from `data/words.json` (phrases or generated language only, or a pastime).")
			out.append("")
			continue
		for part in [["Tested", tested], ["Shown only", shown]]:
			if (part[1] as Array).is_empty():
				continue
			out.append("**%s**" % part[0])
			out.append("")
			out.append("| English | Spanish | Chinese |")
			out.append("| --- | --- | --- |")
			for key in part[1]:
				out.append("| %s | %s | %s |" % [lexicon.word(key, "en"), lexicon.word(key, "es"), lexicon.word(key, "zh")])
			out.append("")
	return "\n".join(out)

func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

## The summary without its "Generated <date>" so a new day alone is not a change.
func _undated(text: String) -> String:
	var regex := RegEx.create_from_string("Generated \\d{4}-\\d{2}-\\d{2}")
	return regex.sub(text, "Generated", true)

func _summary(rows: Array, duplicates: Array, slot_phrases: Dictionary, unplaced: Array) -> String:
	var out: Array = []
	var date := Time.get_date_string_from_system()
	out.append("# Vocabulary usage report")
	out.append("")
	out.append("Generated %s by `tools/vocabulary_report.gd -- --write` (whole town loaded; how to run and what each column means: the script's header and [the guide](../ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report)). Full table: [report.csv](report.csv)." % date)
	out.append("")
	out.append("**Dialogue:** only words that fill a `{slot:form}` in `data/phrases.json` are reported (column `phrase_slots`). Words written as plain text inside dialogue lines are not matched, so a word can appear in dialogue and still be listed here as unused.")
	out.append("")
	out.append("## Totals")
	out.append("")
	out.append("| | Words |")
	out.append("| --- | ---: |")
	out.append("| In data/words.json | %d |" % rows.size())
	out.append("| Placed in the saved scenes | %d |" % rows.filter(func(row): return row.saved > 0).size())
	out.append("| Clickable somewhere (study by clicking) | %d |" % rows.filter(func(row): return row.clickable > 0).size())
	out.append("| Placed only by scripts at load (runtime) | %d |" % rows.filter(func(row): return row.saved == 0 and row.runtime > 0).size())
	out.append("| Only on a bound world label (poster) | %d |" % rows.filter(func(row): return row.saved + row.runtime == 0 and row.labels > 0).size())
	out.append("| Tested by a game | %d |" % rows.filter(func(row): return not row.tests.is_empty()).size())
	out.append("| Only shown by a game | %d |" % rows.filter(func(row): return row.tests.is_empty() and not row.shows.is_empty()).size())
	out.append("| Can fill a phrase slot | %d |" % rows.filter(func(row): return not row.slots.is_empty()).size())
	out.append("| **Placed nowhere and used by no game** | **%d** |" % unplaced.size())
	out.append("| Placed nowhere but used by a game | %d |" % rows.filter(func(row): return not row.unused and row.saved + row.runtime + row.labels == 0).size())
	var unclickable: Array = rows.filter(func(row): return row.clickable == 0 and row.saved + row.runtime > 0).map(func(row): return row.key)
	out.append("| Placed but not clickable (no pick collision) | %d |" % unclickable.size())
	out.append("")
	out.append("## Hard errors (unknown word keys)")
	out.append("")
	if failed.is_empty():
		out.append("None: every key in game data, scenes, labels, aliases and phrase slots exists in `data/words.json`.")
	for label in failed:
		out.append("- " + str(label))
	out.append("")
	out.append("## Games and the words they test")
	out.append("")
	out.append("Decision 6 (user, 7 Nov 2026). The police lineup is not tracked: each round names two clue words and the answer is a suspect, so no question has one clear tested word. The evidence game is tracked since its redesign (8 Nov 2026): one property word decides each round.")
	out.append("")
	out.append("| Game id | Tests | Shows only |")
	out.append("| --- | ---: | ---: |")
	var games: Dictionary = {}
	for key in tests:
		for game in tests[key]:
			games[game] = true
	for key in shows:
		for game in shows[key]:
			games[game] = true
	var ids := games.keys()
	ids.sort()
	for game in ids:
		var tested := rows.filter(func(row): return row.tests.has(game)).size()
		var shown := rows.filter(func(row): return row.shows.has(game) and not row.tests.has(game)).size()
		out.append("| `%s` | %d | %d |" % [game, tested, shown])
	out.append("")
	for game in ids:
		var tested: Array = rows.filter(func(row): return row.tests.has(game)).map(func(row): return row.key)
		if not tested.is_empty():
			out.append("- **%s** tests: %s" % [game, ", ".join(tested)])
	out.append("")
	out.append("## Placed nowhere and used by no game (%d)" % unplaced.size())
	out.append("")
	var by_category: Dictionary = {}
	for row in unplaced:
		by_category[row.category] = by_category.get(row.category, []) + [row.key]
	var cats := by_category.keys()
	cats.sort()
	for category in cats:
		out.append("- **%s** (%d): %s" % [category, by_category[category].size(), ", ".join(by_category[category])])
	out.append("")
	out.append("## Placed but not clickable (%d)" % unclickable.size())
	out.append("")
	out.append(", ".join(unclickable) if not unclickable.is_empty() else "None.")
	out.append("")
	out.append("## Same meaning twice (%d groups)" % duplicates.size())
	out.append("")
	out.append("An alias that is also a word key, a singular and plural key both listed, or two keys with the same text in one language (case-insensitive). Some are fine (a Chinese word that covers two English senses); each needs a human look.")
	out.append("")
	for group in duplicates:
		out.append("- %s%s \"%s\": %s" % [group.kind, " (" + group.language + ")" if group.language != "" else "", group.text, ", ".join(group.keys)])
	out.append("")
	out.append("## Removed words still placed (%d)" % removed_placed.size())
	out.append("")
	out.append("`removed_with_objects` lists deleted words whose objects should be gone; no script removes them at load any more (the startup passes were deleted 6 Nov 2026).")
	out.append("")
	if removed_placed.is_empty():
		out.append("None.")
	var removed_keys := removed_placed.keys()
	removed_keys.sort()
	for key in removed_keys:
		out.append("- **%s**: %s" % [key, ", ".join(removed_placed[key])])
	out.append("")
	out.append("## Phrase slots")
	out.append("")
	for id in slot_phrases:
		out.append("- `%s`: %s" % [id, JSON.stringify(slot_phrases[id])])
	out.append("")
	return "\n".join(out)

func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
