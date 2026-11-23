extends SceneTree
## Vocabulary book (Stage C of the vocabulary tracking work, 8 Nov 2026; guide:
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-book). Seeds a test save (studied words,
## bookmarks and practice counts in es and zh) BEFORE Main loads, then checks the journal's
## table: every word listed, totals equal to practice_log sums, the star toggling and saving a
## bookmark, the filters, search, category and sorting, Show / Hide scores, the detail view's
## totals and readable game names, Esc order, virtual rows and that nothing is recorded.
## Writes user:// saves: run with an isolated HOME (run_checks.py does).
##   HOME=<scratch>/home VT_FOCUS=all godot --headless --path . --script res://docs/evidence/vocabulary-book-20261108/verify.gd
## With graphics it also renders PNGs next to this script (table, scores hidden, a filter and
## a detail view; en/es, es/zh and zh/es native/foreign):
##   HOME=<scratch>/home VT_FOCUS=home godot --path . --resolution 1600x1000 --script res://docs/evidence/vocabulary-book-20261108/verify.gd
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Progress := preload("res://scripts/learning/vocabulary_progress.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const DIR := "res://docs/evidence/vocabulary-book-20261108/"
const COUNTS := {
	"es": {
		"apple": {"shop_supermarket": {"positive": 3, "negative": 1, "translated": 1}, "restaurant_twinkle": {"positive": 2, "negative": 1, "translated": 0}},
		"bread": {"shop_supermarket": {"positive": 1, "negative": 0, "translated": 0}},
		"mother": {"family_dr_li": {"positive": 4, "negative": 2, "translated": 1}},
		"mexico": {"flight_bruno": {"positive": 0, "negative": 3, "translated": 2}}},
	"zh": {
		"apple": {"grammar_lana": {"positive": 1, "negative": 1, "translated": 0}, "shop_supermarket": {"positive": 2, "negative": 0, "translated": 1}},
		"dog": {"grammar_lana": {"positive": 5, "negative": 0, "translated": 0}}},
}
var failures := 0
var checks := 0
var game
var hud
var book

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func write(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR + name + ".png")

## Ticks or unticks the menu item whose metadata is `id`.
func tick(menu, id: String) -> void:
	var popup: PopupMenu = menu.get_popup()
	for i in popup.item_count:
		if str(popup.get_item_metadata(i)) == id:
			book.toggle_choice(menu, i)
			return
	check(false, "menu item %s exists" % id)

## A left click at a screen position, through the viewport (as a mouse or tap).
func click(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		root.push_input(event)
		await process_frame

func item_keys() -> Array:
	return book.items.filter(func(i): return i.has("key")).map(func(i): return i.key)

## The sums of practice_log's per-game counts for `key` (the tracker's own data).
func log_sums(lang: String, key: String) -> Dictionary:
	var sums := {"positive": 0, "negative": 0, "translated": 0}
	var games: Dictionary = PracticeLog.shared().games_for(lang, key)
	for g in games:
		for o in sums:
			sums[o] += int(games[g].get(o, 0))
	return sums

func detail_tile(i: int) -> String:
	return book.detail_tiles.get_child(i).get_child(0).get_child(1).text

## Checks the open detail view of `key` against practice_log.
func check_detail(lang: String, key: String) -> void:
	var sums := log_sums(lang, key)
	check(detail_tile(0) == ("✓" if game.studied_words.has(key) else "–"), "%s %s: detail studied" % [lang, key])
	check(detail_tile(1) == str(sums.positive) and detail_tile(2) == str(sums.negative) and detail_tile(3) == str(sums.translated),
		"%s %s: detail totals match practice_log %s (shown %s %s %s)" % [lang, key, sums, detail_tile(1), detail_tile(2), detail_tile(3)])
	var games: Dictionary = PracticeLog.shared().games_for(lang, key)
	var cells: Array = book.detail_games.get_children()
	check(cells.size() == (games.size() + 1) * 4 if not games.is_empty() else cells.is_empty(), "%s %s: one detail row per game" % [lang, key])
	for g in games:
		var found := false
		for i in range(4, cells.size(), 4):
			if cells[i].text == UiText.t("games." + g):
				found = true
				check(cells[i + 1].text == str(games[g].positive) and cells[i + 2].text == str(games[g].negative) and cells[i + 3].text == str(games[g].translated), "%s %s %s: per-game counts" % [lang, key, g])
			check(cells[i].text != g, "%s %s: game shown by name, not id %s" % [lang, key, cells[i].text])
		check(found and UiText.has("games." + g), "%s %s: readable name for %s" % [lang, key, g])

func run():
	# Every activity (the tracker's game ids) has a readable name for the detail view.
	var activities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/activities.json")).activities
	var unnamed: Array = activities.keys().filter(func(id): return not UiText.has("games." + str(id)))
	check(unnamed.is_empty(), "every data/activities.json id has a games.<id> name in data/phrases.json: missing %s" % [unnamed])
	# --- Seed the test save before anything loads it ------------------------------------------
	write(Progress.LANGUAGE_FILE, {"es": ["apple", "bread", "sofa", "mother", "coffee"], "zh": ["apple", "dog"]})
	write(Progress.BOOKMARKS_FILE, ["apple", "dog"])
	write(PracticeLog.PATH, COUNTS)
	var settings = GameSettings.shared()
	settings.set_languages("en", "es")
	settings.set_native(false)
	var log_before := FileAccess.get_file_as_string(PracticeLog.PATH)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	hud = game.hud
	book = hud.journal_book
	game.toggle_study_journal()
	await process_frame
	await process_frame
	check(hud.is_journal_open() and book.visible and not game.player.controls_enabled, "J opens the book and blocks gameplay")

	# --- Every word, totals from practice_log -------------------------------------------------
	check(book.words.size() == game.vocabulary.size() and book.words.size() > 700, "every dictionary word is listed (%d)" % book.words.size())
	check(item_keys().size() == book.words.size() and book.filter == "all", "All shows every word once by category")
	var mismatched: Array = []
	for key in book.words:
		var sums := log_sums("es", key)
		var w: Dictionary = book.words[key]
		if w.positive != sums.positive or w.negative != sums.negative or w.translated != sums.translated:
			mismatched.append(key)
	check(mismatched.is_empty(), "word totals equal the sums of practice_log per-game counts: %s" % [mismatched.slice(0, 5)])
	check(book.words.apple.positive == 5 and book.words.apple.negative == 2 and book.words.apple.translated == 1, "apple es totals 5/2/1")

	# --- Virtual rows ---------------------------------------------------------------------------
	check(book.rows.size() < 40, "only visible rows are controls (%d rows for %d items)" % [book.rows.size(), book.items.size()])
	var t0 := Time.get_ticks_usec()
	for i in 10:
		book.rebuild()
	var rebuild_ms := (Time.get_ticks_usec() - t0) / 10000.0
	t0 = Time.get_ticks_usec()
	for i in 50:
		book.scroll.value = i * 97.0
	var scroll_ms := (Time.get_ticks_usec() - t0) / 50000.0
	print("VOCABULARY BOOK timing: rebuild %.2f ms, scroll step %.3f ms (%d words)" % [rebuild_ms, scroll_ms, book.words.size()])
	check(rebuild_ms < 40.0 and scroll_ms < 4.0, "filtering and scrolling stay fast (%.1f ms, %.2f ms)" % [rebuild_ms, scroll_ms])
	book.scroll.value = 0.0
	await shot("table-en-es")

	# --- Star toggles the bookmark at once, saved -----------------------------------------------
	book.scroll_to("bread")
	var row = book.row_for("bread")
	check(row != null, "bread row visible after scroll_to")
	if row != null:
		var star: Button = row.get_meta("line").get_child(0)
		check(star.text == "☆", "bread starts unsaved")
		star.pressed.emit()
		check(hud.bookmarks.has("bread") and star.text == "★", "star saves bread")
		check(Progress.load_bookmarked_words().has("bread"), "bookmark written to " + Progress.BOOKMARKS_FILE)
		star.pressed.emit()
		check(not hud.bookmarks.has("bread") and not Progress.load_bookmarked_words().has("bread") and star.text == "☆", "star again unsaves bread")
		check(row.size.y >= 56.0 * book.factor - 1.0 and book.scroll.size.x >= 24.0 * book.factor - 1.0, "touch-size rows (%.0f px) and scroll bar (%.0f px)" % [row.size.y, book.scroll.size.x])
		# A real click on the star saves without opening the word (9 Nov 2026). Graphics only: the
		# headless root viewport is 64 x 64 px (and cannot be resized), so clicks at the rows'
		# positions land outside it and are dropped (9 Nov 2026 suite; traced the same day).
		if DisplayServer.get_name() == "headless":
			print("VOCABULARY BOOK: real-click checks skipped headless (run with graphics, see header)")
		else:
			await click(star.get_global_rect().get_center())
			check(hud.bookmarks.has("bread") and not book.is_detail_open(), "clicking the star saves and does not open the detail")
			await click(star.get_global_rect().get_center())
			check(not hud.bookmarks.has("bread") and not book.is_detail_open(), "clicking the star again unsaves, still no detail")
			await click(row.get_meta("line").get_child(book.FOREIGN_CELL).get_global_rect().get_center())
			check(book.is_detail_open() and book.detail_key == "bread", "clicking the word itself opens the detail")
			book.close_detail()

	# --- Filters, search, category, sorting ------------------------------------------------------
	book.filter_buttons.studied.pressed.emit()
	var studied_keys := item_keys()
	check(book.filter == "studied" and studied_keys.size() == 5 and studied_keys.all(func(k): return game.studied_words.has(k)), "Studied filter: %s" % [studied_keys])
	book.filter_buttons.saved.pressed.emit()
	var saved_keys := item_keys()
	saved_keys.sort()
	check(saved_keys == ["apple", "dog"], "Saved filter: %s" % [saved_keys])
	check(book.filter_buttons.saved.text == UiText.t("journal.filter_saved", {"n": 2}), "Saved button shows its count")
	await shot("saved-en-es")
	# The Saved tab is the saved-words list (9 Nov 2026): with nothing saved it says how to save.
	var kept: Dictionary = hud.bookmarks.duplicate()
	hud.bookmarks.clear()
	book.set_filter("saved")
	check(book.empty_label.visible and book.empty_label.text == UiText.t("bookmarks.empty"), "empty Saved tab explains how to save a word")
	await shot("saved-empty-en-es")
	for k in kept:
		hud.bookmarks[k] = true
	book.set_filter("saved")
	check(not book.empty_label.visible and item_keys().size() == 2, "Saved tab lists the words again")
	book.filter_buttons.all.pressed.emit()
	book.search.text = "manzana"
	book.search.text_changed.emit("manzana")
	check(item_keys().has("apple"), "search in the foreign language")
	book.search.text = "APPLE"
	book.search.text_changed.emit("APPLE")
	check(item_keys().has("apple") and item_keys().size() < 20, "search in the native language, any case")
	book.search.text = "sofa"
	book.search.text_changed.emit("sofa")
	check(item_keys().has("sofa"), "search ignores accents (sofá)")
	book.search.text = "zzqx"
	book.search.text_changed.emit("zzqx")
	check(item_keys().is_empty() and book.footer.text == UiText.t("journal.no_match"), "no match message")
	book.search.text = ""
	book.search.text_changed.emit("")
	tick(book.category_menu, "Food & Drink")
	var food := item_keys()
	check(food.has("apple") and food.all(func(k): return game.vocabulary_categories[k] == "Food & Drink") and book.category_menu.text == UiText.named("categories", "Food & Drink"), "category filter")
	# Multi-select (9 Nov 2026): a second ticked category adds its words; the label counts them.
	tick(book.category_menu, "Animals")
	var two := item_keys()
	check(two.has("apple") and two.has("dog") and two.all(func(k): return game.vocabulary_categories[k] in ["Food & Drink", "Animals"]) and book.category_menu.text == UiText.t("journal.some_categories", {"n": 2}), "two categories ticked")
	check(book.category_menu.get_popup().is_item_checked(0) == false, "All is unticked while categories are ticked")
	tick(book.category_menu, "Animals")
	check(item_keys() == food, "unticking Animals leaves Food & Drink")
	book.sort_menu.select(2)
	book.sort_menu.item_selected.emit(2)
	check(item_keys()[0] == "apple", "Most right first puts apple (5) first in Food & Drink")
	book.sort_menu.select(3)
	book.sort_menu.item_selected.emit(3)
	check(item_keys()[0] == "apple", "Most wrong first in Food & Drink")
	book.toggle_choice(book.category_menu, 0)
	check(book.chosen_categories.is_empty() and book.category_menu.get_popup().is_item_checked(0) and book.category_menu.text == UiText.t("journal.all_categories"), "All clears the categories")
	var countries: Array = item_keys().filter(func(k): return game.vocabulary_categories[k] == game.vocabulary_categories.mexico)
	check(countries[0] == "mexico", "Most wrong first sorts inside each category: mexico (3) first in its group")
	book.sort_menu.select(0)
	book.sort_menu.item_selected.emit(0)
	# Area menu (multi-select, 9 Nov 2026): words of the ticked areas only; All clears.
	var area_ids: Array = game.area_vocabulary.groups.keys().filter(func(a): return not game.area_vocabulary.groups[a].is_empty())
	area_ids.sort()
	var a1 := str(area_ids[0])
	var a2 := str(area_ids[1])
	var in_areas := func(ids: Array) -> Dictionary:
		var out := {}
		for a in ids:
			for k in game.area_vocabulary.groups[a]:
				if book.words.has(str(k)): out[str(k)] = true
		return out
	tick(book.area_menu, a1)
	var one_area := item_keys()
	var expected_one: Dictionary = in_areas.call([a1])
	check(not one_area.is_empty() and one_area.size() == expected_one.size() and one_area.all(func(k): return expected_one.has(k)), "area filter: %s (%d words)" % [a1, one_area.size()])
	tick(book.area_menu, a2)
	var expected_two: Dictionary = in_areas.call([a1, a2])
	var two_areas := item_keys()
	check(two_areas.size() == expected_two.size() and book.area_menu.text == UiText.t("journal.some_areas", {"n": 2}), "two areas ticked: %d words" % two_areas.size())
	hud.journal_area_button.pressed.emit()
	var headings: Array = book.items.filter(func(i): return i.has("heading"))
	check(headings.size() == 2, "By Area with two areas ticked shows only their two sections")
	hud.journal_category_button.pressed.emit()
	await shot("areas-en-es")
	book.toggle_choice(book.area_menu, 0)
	check(book.chosen_areas.is_empty() and item_keys().size() == book.words.size(), "All clears the areas")
	book.filter_buttons.studied.pressed.emit()
	await shot("filter-studied-en-es")

	# --- Show / Hide scores -------------------------------------------------------------------------
	var before := item_keys()
	book.scores_button.pressed.emit()
	var hidden_ok: bool = not book.show_scores and not book.header.get_child(book.SCORE_CELLS[0]).visible and not book.header.get_child(book.SCORE_CELLS[2]).visible
	for r in book.rows:
		var cells: Array = r.get_meta("line").get_children()
		hidden_ok = hidden_ok and book.SCORE_CELLS.all(func(i): return not cells[i].visible) and cells[book.FOREIGN_CELL].visible
	check(hidden_ok and not book.scores_button.button_pressed and book.scores_button.tooltip_text == UiText.t("journal.show_scores"), "Hide scores hides studied, right and wrong")
	check(item_keys() == before and book.filter == "studied", "Hide scores changes no filter or data")
	book.filter_buttons.all.pressed.emit()
	await shot("scores-hidden-en-es")
	book.scores_button.pressed.emit()
	check(book.show_scores and book.header.get_child(book.SCORE_CELLS[1]).visible, "Show scores brings them back")

	# --- Detail view ------------------------------------------------------------------------------
	book.scroll_to("apple")
	row = book.row_for("apple")
	check(row != null, "apple row visible")
	if row != null:
		row.pressed.emit()
	check(book.is_detail_open() and book.detail_key == "apple" and not book.table.visible, "clicking a row opens the detail view")
	check_detail("es", "apple")
	await shot("detail-en-es")
	book.detail_star.pressed.emit()
	check(not hud.bookmarks.has("apple") and book.detail_star.text == "☆", "detail star unsaves")
	book.detail_star.pressed.emit()
	check(hud.bookmarks.has("apple"), "detail star saves again")
	game.popups.close_top()
	check(not book.is_detail_open() and hud.is_journal_open(), "Esc closes the detail first")
	book.open_detail("sofa")
	check_detail("es", "sofa")
	check(book.detail_empty.visible, "a word without practice says so")
	book.open_detail("mexico")
	check_detail("es", "mexico")
	book.close_detail()

	# --- Area view ------------------------------------------------------------------------------------
	hud.journal_area_button.pressed.emit()
	check(hud.journal_by_area and book.by_area and book.items[0].has("heading") and not item_keys().is_empty(), "By Area groups the table by area")
	hud.journal_category_button.pressed.emit()
	check(not book.by_area, "By Category again")

	# --- Other languages (renders) ----------------------------------------------------------------
	settings.set_languages("es", "zh")
	await process_frame
	check(book.words.dog.positive == 5 and book.words.apple.translated == 1, "zh counts after switching the learned language")
	check(hud.journal_title.text.begins_with("DIARIO"), "journal in Spanish")
	await shot("table-es-zh")
	book.open_detail("apple")
	check_detail("zh", "apple")
	check(book.detail_reading.visible and book.detail_reading.text != "", "pinyin under the Chinese word")
	await shot("detail-es-zh")
	book.close_detail()
	settings.set_languages("zh", "es")
	await process_frame
	book.scores_button.pressed.emit()
	await shot("scores-hidden-zh-es")
	book.scores_button.pressed.emit()
	book.open_detail("mother")
	check_detail("es", "mother")
	await shot("detail-zh-es")
	book.close_detail()

	# --- The book button and the ✕ (saved words merged into the journal, 9 Nov 2026) --------------
	check(not "bookmark_panel" in hud, "no separate saved-words panel")
	hud.journal_close.pressed.emit()
	# The HUD shows the corner buttons again in its _process (after process_frame).
	await process_frame
	await process_frame
	check(not hud.is_journal_open() and game.player.controls_enabled, "the journal's close button closes it")
	check(hud.bookmark_button.visible and hud.settings_button.visible, "book and gear show with the journal closed")
	check(hud.bookmark_button.size.x >= 52.0 and hud.settings_button.size.x >= 52.0 and hud.bookmark_button.position.is_equal_approx(hud.top_slot(0).position), "book and gear are big buttons, the book under the gear (14 Nov 2026; %.0f px)" % hud.bookmark_button.size.x)
	await shot("hud-buttons")
	hud.bookmark_button.pressed.emit()
	await process_frame
	check(hud.is_journal_open() and not game.player.controls_enabled, "the book button opens the journal")

	# --- Nothing recorded; closing ------------------------------------------------------------------
	check(FileAccess.get_file_as_string(PracticeLog.PATH) == log_before, "the book never writes the practice log")
	game.toggle_study_journal()
	check(not hud.is_journal_open() and game.player.controls_enabled, "J closes the book and restores controls")
	settings.set_languages("en", "es")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("VOCABULARY BOOK: %d checks, %d failures" % [checks, failures])
	quit()
