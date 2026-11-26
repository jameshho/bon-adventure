extends SceneTree
## Vocabulary journal, sticker book: the baked place index and the Places tab (25 Nov 2026;
## design and rules: docs/guides/JOURNAL.md). Seeds a test save (studied words, bookmarks and
## practice counts in es) BEFORE Main loads, then checks: the index (findable words, Around town),
## the full total, the contents cards, a chapter's stickers (found = foreign word, not found =
## silhouette with "?" and never its word), page turns, tap-to-flip and the second tap, the word
## page (Found in, Details = practice_log sums), search (never reveals a word not found), the
## ★ Pocket, Esc order and that nothing is saved. Since the review fixes (25 Nov 2026): a word
## answered in a game (practice log) counts as found in that language only, a game-only word's
## page says "Found in a game at", ← → and Page Up / Down turn pages, the footer names keys only
## with keyboard play, buttons stay finger-sized and text readable at the smallest scale, the word
## page asks for the big picture, and Chinese learned (pinyin) and a Chinese interface render.
## Writes user:// saves: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/journal-sticker-book-20261125/verify.gd
## With graphics it also saves its views next to this script, named with the window size when it
## is not 1280x800 (laptop; the phone-landscape views are 844x390):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/journal-sticker-book-20261125/verify.gd
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 844x390 --script res://docs/evidence/journal-sticker-book-20261125/verify.gd
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Progress := preload("res://scripts/learning/vocabulary_progress.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Book := preload("res://scripts/ui/vocabulary_book.gd")
const WordPictures := preload("res://scripts/ui/word_pictures.gd")
const DIR := "res://docs/evidence/journal-sticker-book-20261125/"
var failures := 0
var checks := 0
var game
var hud
var book
var suffix := ""

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

func graphics() -> bool:
	return DisplayServer.get_name() != "headless"

func shot(name: String, frames := 10) -> void:
	if not graphics():
		return
	for i in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR + name + suffix + ".png")

func shown_stickers() -> Array:
	return book.stickers.filter(func(s): return s.visible)

func sticker_of(key: String) -> Button:
	for s in book.stickers:
		if s.visible and str(s.get_meta("key", "")) == key:
			return s
	return null

func run():
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Book.PLACE_INDEX))
	var places: Dictionary = index.get("words", {})
	check(places.size() > 700 and places.size() + index.get("not_findable", []).size() == 800, "the place index lists the findable words (%d) and the rest (%d)" % [places.size(), index.get("not_findable", []).size()])
	for key in ["airplane", "car", "soccer", "tennis", "bed"]:
		check(places.has(key), "%s (only asked by a game) is findable" % key)
	# The supermarket's own words (fewer than 4 places), alphabetical by key: some found.
	var market: Array = places.keys().filter(func(k): return places[k].has("supermarket") and places[k].size() < Book.AROUND_TOWN_PLACES)
	market.sort()
	# Found: five of the first spread (chapters run by tier, then key), so the views show found and
	# unfound stickers side by side.
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	market.sort_custom(func(a, b):
		var ta: int = lexicon.tier(a, "es")
		var tb: int = lexicon.tier(b, "es")
		return ta < tb if ta != tb else a < b)
	var found_market: Array = [market[0], market[2], market[3], market[5], market[6]]
	var studied := found_market + ["apple", "dog"]
	write(Progress.LANGUAGE_FILE, {"es": studied})
	write(Progress.BOOKMARKS_FILE, ["apple", found_market[0]])
	# car: only Library Helper asks it (no click studies it), answered once in Spanish. market[1]:
	# answered in Chinese only, so it is found when learning Chinese, not Spanish.
	write(PracticeLog.PATH, {
		"es": {"apple": {"shop_supermarket": {"positive": 3, "negative": 1, "translated": 1}, "restaurant_twinkle": {"positive": 2, "negative": 1, "translated": 0}},
			"car": {"library_rosa": {"positive": 1, "negative": 0, "translated": 0}}},
		"zh": {market[1]: {"shop_supermarket": {"positive": 1, "negative": 0, "translated": 0}}}})
	var found_es: Array = studied + ["car"]
	var settings = GameSettings.shared()
	settings.set_languages("en", "es")
	var saves_before := [FileAccess.get_file_as_string(Progress.LANGUAGE_FILE), FileAccess.get_file_as_string(Progress.BOOKMARKS_FILE), FileAccess.get_file_as_string(PracticeLog.PATH)]
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	await process_frame
	if graphics():
		var window := root.get_visible_rect().size
		if Vector2i(window) != Vector2i(1280, 800):
			suffix = "-%dx%d" % [int(window.x), int(window.y)]
	hud = game.hud
	book = hud.journal_book
	game.toggle_study_journal()
	await process_frame
	await process_frame
	check(hud.is_journal_open() and book.view == "contents", "J opens the sticker book on its contents")

	# --- Totals: findable words only ------------------------------------------------------------
	var findable: Array = places.keys().filter(func(k): return game.vocabulary.has(k))
	check(book.total_words == findable.size(), "the total counts the findable words (%d of %d)" % [book.total_words, findable.size()])
	check(book.total_found == found_es.size(), "found = studied or answered in a Spanish game (%d)" % book.total_found)
	check(book.found_words.has("car") and not book.found_words.has(market[1]), "a game answer finds a word in its own language only")
	check(hud.journal_progress_label.text == UiText.t("journal.found_total", {"found": found_es.size(), "total": findable.size()}), "header: \"%s\"" % hud.journal_progress_label.text)
	check(is_equal_approx(hud.journal_progress.value, float(found_es.size()) / findable.size()), "the header bar shows the share found")

	# --- Contents ------------------------------------------------------------------------------
	check(book.chapter_order[0] == Book.AROUND and book.chapter_order[-1] == Book.POCKET, "contents: Around town first, ★ Pocket last")
	# A word is in each of its places' chapters, or only in Around town (4 or more places).
	var where: Dictionary = {}
	var around_ok := true
	for id in book.chapters:
		for key in book.chapters[id]:
			where[key] = where.get(key, []) + [id]
			var many: bool = places[key].size() >= Book.AROUND_TOWN_PLACES
			if many != (id == Book.AROUND):
				around_ok = false
	var misplaced: Array = findable.filter(func(k):
		var want: Array = [Book.AROUND] if places[k].size() >= Book.AROUND_TOWN_PLACES else places[k]
		var have: Array = where.get(k, [])
		return have.size() != want.size() or want.any(func(id): return not have.has(id)))
	check(misplaced.is_empty(), "every findable word is in its places' chapters: wrong %s" % [misplaced.slice(0, 5)])
	check(around_ok and book.chapters[Book.AROUND].has("apple"), "Around town holds the words of 4+ places (%d), and only those" % book.chapters[Book.AROUND].size())
	var shown_cards: Array = book.cards.filter(func(c): return c.visible)
	check(shown_cards.size() == mini(book.chapter_order.size(), book.cards.size()), "contents page shows %d cards" % shown_cards.size())
	var market_card: Button = null
	for card in book.cards:
		if str(card.get_meta("chapter", "")) == "supermarket":
			market_card = card
	await shot("contents")
	book.turn_page(1)
	check(book.page == 1 and book.page_count() == 2, "contents turn to page 2 of 2")
	for card in book.cards:
		if card.visible and str(card.get_meta("chapter", "")) == "supermarket":
			market_card = card
	check(market_card != null and market_card.get_node("Count").text == UiText.t("journal.place_count", {"found": 5, "total": market.size()}), "the supermarket card counts 5 of %d" % market.size())
	await shot("contents-2")
	book.turn_page(-1)

	# --- A chapter ----------------------------------------------------------------------------
	book.open_chapter("supermarket")
	await process_frame
	check(book.view == "chapter" and shown_stickers().size() == 8, "a chapter spread shows 8 stickers")
	check(book.back_button.visible and book.title_label.text == UiText.named("places", "Supermarket"), "chapter title and Back")
	var revealed := false
	for s in shown_stickers():
		var key := str(s.get_meta("key"))
		var word: Label = s.get_node("Word")
		var tag: Label = s.get_node("Tag")
		if studied.has(key):
			check(word.visible and word.text == book.words[key].foreign and not s.get_node("Mark").visible, "found sticker %s shows its foreign word" % key)
		else:
			check(s.get_node("Mark").visible, "unfound sticker %s shows ?" % key)
			for text in [word.text if word.visible else "", tag.text if tag.visible else ""]:
				if text != "" and (text == book.words[key].foreign or text == book.words[key].native):
					revealed = true
	check(not revealed, "no sticker reveals a word not found yet")
	var first: Button = sticker_of(found_market[0])
	check(first != null and first.get_node("Pin").visible, "a saved word's sticker has the ★ pin")
	var pages: int = book.page_count()
	check(pages == ceili(market.size() / 8.0), "chapter pages: %d" % pages)
	book.turn_page(1)
	check(book.page == 1, "page arrows turn the spread")
	book.turn_page(-1)
	# Keys: → / Page Down and ← / Page Up turn the spread (calls the book's handler directly).
	for pair in [[KEY_RIGHT, 1], [KEY_PAGEUP, 0], [KEY_PAGEDOWN, 1], [KEY_LEFT, 0]]:
		var key_event := InputEventKey.new()
		key_event.keycode = pair[0]
		key_event.pressed = true
		book._unhandled_input(key_event)
		check(book.page == pair[1], "%s turns to spread %d" % [OS.get_keycode_string(pair[0]), pair[1] + 1])
	# The footer names keys only with keyboard play (a touch switches the HUD's key hints off).
	hud.set_keyboard_hints(false)
	check(book.hint.text == UiText.t("journal.hint_chapter"), "touch: the hint has no keys (\"%s\")" % book.hint.text)
	hud.set_keyboard_hints(true)
	check(book.hint.text.contains(UiText.t("journal.hint_flip_all")) and book.hint.text.contains(UiText.t("journal.hint_pages")), "keyboard: the hint names ← → and Hold L")
	# Finger-sized at any window (headless is 64 x 64, the smallest scale): buttons and text.
	await process_frame
	var small: Array = [book.prev_button, book.next_button, book.back_button, book.pocket_button, book.search, hud.journal_close].filter(func(b): return b.size.y < Book.TAP - 0.5)
	check(small.is_empty(), "buttons at least %d px high (scale %.2f): too small %s" % [Book.TAP, book.factor, small.map(func(b): return "%s %.0f" % [b.name, b.size.y])])
	check(book.hint.get_theme_font_size("font_size") >= Book.MIN_TEXT and book.page_label.get_theme_font_size("font_size") >= Book.MIN_TEXT, "footer text at least %d px" % Book.MIN_TEXT)
	# Tap to flip, tap again to open.
	book._on_sticker(first)
	for i in 20: await process_frame
	check(book.flipped_key == found_market[0] and first.get_node("Word").text == book.words[found_market[0]].native, "a tap flips a sticker to the native word")
	await shot("chapter-flipped")
	var unfound: Button = null
	for s in shown_stickers():
		if not studied.has(str(s.get_meta("key"))):
			unfound = s
			break
	book._on_sticker(unfound)
	for i in 20: await process_frame
	check(first.get_node("Word").text == book.words[found_market[0]].foreign, "flipping another sticker turns the first back")
	check(unfound.get_node("Word").text == UiText.t("journal.not_found"), "an unfound sticker flips to Not found yet")
	book._on_sticker(unfound)
	check(book.view == "chapter", "a word not found has no word page")
	book._on_sticker(first)
	book._on_sticker(first)
	check(book.view == "word" and book.detail_key == found_market[0], "the second tap opens the word page")
	# Hold L: every found sticker shows its native word.
	book.go_back()
	# (The HUD ends the peek on the next frame unless L is really held: check at once.)
	settings.set_peek(true)
	check(first.get_node("Word").text == book.words[found_market[0]].native, "holding L flips every sticker")
	settings.set_peek(false)
	await process_frame

	# --- Word page ------------------------------------------------------------------------------
	book.open_chapter(Book.AROUND)
	book.open_detail("apple")
	await process_frame
	check(book.detail_foreign.text == book.words["apple"].foreign and book.detail_native.text.begins_with(book.words["apple"].native), "word page: word and translation")
	# Known words (LEARN-04, merged 25 Nov 2026): the page says so exactly when the word memory knows it.
	var apple_known: bool = book.words["apple"].known
	check(book.detail_native.text.contains(UiText.t("journal.known_tag")) == apple_known, "word page: the known tag follows the word memory (known: %s)" % apple_known)
	var chips: Array = book.found_places.get_children().map(func(c): return c.name)
	check(chips.has("Place " + Book.AROUND) and chips.has("Place supermarket"), "Found in lists Around town and its places: %s" % [chips])
	if game.get("word_pictures") != null:
		check(str(book.detail_picture.get_meta("picture_key", "")) == "apple@%d" % WordPictures.BIG, "the word page asks for the big picture")
	var small_chips: Array = book.found_places.get_children().filter(func(c): return c.size.y < Book.TAP - 0.5)
	check(small_chips.is_empty(), "Found in pills at least %d px high" % Book.TAP)
	await shot("word-page", 30)
	book.details_button.pressed.emit()
	await process_frame
	var tiles: Array = book.detail_tiles.get_children().map(func(t): return t.get_child(0).get_child(1).text)
	check(tiles == ["5", "2", "1"], "Details shows practice_log's sums (%s)" % [tiles])
	check(book.detail_games.get_child_count() == 12, "Details: one row per game")
	if graphics():
		# Details never grows the album past the window (a landscape phone: the right side scrolls).
		await process_frame
		var bottom: float = hud.journal_panel.get_global_rect().end.y
		check(bottom <= root.get_visible_rect().size.y + 0.5, "Details fits the window (album bottom %.0f of %.0f)" % [bottom, root.get_visible_rect().size.y])
	await shot("word-details")
	book.open_chapter("supermarket")
	book.open_detail(found_market[0])
	book.turn_page(1)
	check(book.view == "word" and book.detail_key != found_market[0] and found_market.has(book.detail_key), "page arrows step to the chapter's next found word")
	# A word only a game asks, found by a game answer: its page names the game's place.
	book.open_chapter("library")
	book.open_detail("car")
	await process_frame
	check(book.view == "word" and book.found_heading.text == UiText.t("journal.found_in_game") and book.found_places.get_child(0).name == "Place library", "a game-only word: \"Found in a game at\" the library")
	book.open_chapter("supermarket")
	book.open_detail(found_market[0])
	check(book.found_heading.text == UiText.t("journal.found_in"), "a clicked word: \"Found in\"")
	# Esc: word page -> chapter -> contents -> closed.
	game.popups.close_top()
	check(book.view == "chapter", "Esc leaves the word page first")
	game.popups.close_top()
	check(book.view == "contents", "then the chapter")
	game.popups.close_top()
	check(not hud.is_journal_open(), "then closes the journal")
	game.toggle_study_journal()
	await process_frame

	# --- Search -------------------------------------------------------------------------------
	book.search.text = "manzana"
	book.set_query("manzana")
	await process_frame
	check(book.chapter == Book.SEARCH and sticker_of("apple") != null, "search finds a found word in the foreign language")
	var hidden_key := ""
	for key in market:
		if not studied.has(key) and str(book.words[key].native).length() > 4:
			hidden_key = key
			break
	book.search.text = book.words[hidden_key].native
	book.set_query(book.words[hidden_key].native)
	await process_frame
	var hit: Button = sticker_of(hidden_key)
	check(hit != null and hit.get_node("Mark").visible and hit.get_node("Word").text == book.place_name(places[hidden_key][0]), "an unfound word's search result: ?, its place, not its word")
	await shot("search-unfound", 20)
	book.search.text = ""
	book.set_query("")
	check(book.view == "contents", "clearing the search goes back")

	# --- Pocket ---------------------------------------------------------------------------------
	book.pocket_button.pressed.emit()
	await process_frame
	check(book.chapter == Book.POCKET and shown_stickers().size() == 2, "★ Pocket lists the saved words")
	await shot("pocket", 20)
	book.go_back()

	# --- Nothing saved ---------------------------------------------------------------------------
	game.toggle_study_journal()
	var saves_after := [FileAccess.get_file_as_string(Progress.LANGUAGE_FILE), FileAccess.get_file_as_string(Progress.BOOKMARKS_FILE), FileAccess.get_file_as_string(PracticeLog.PATH)]
	check(saves_after == saves_before, "browsing the book saves nothing")

	# --- Chinese --------------------------------------------------------------------------------
	# Learning Chinese with a Spanish interface: Chinese stickers, pinyin on the word page, the
	# market[1] word found by its Chinese game answer. Then a Chinese interface learning English.
	write(Progress.LANGUAGE_FILE, {"es": studied, "zh": studied})
	settings.set_languages("es", "zh")
	for i in 3: await process_frame
	game.toggle_study_journal()
	await process_frame
	check(book.words["apple"].foreign == UiText.word("apple", "zh") and book.found_words.has(market[1]) and not book.found_words.has("car"), "learning Chinese: Chinese words, its own game answers")
	book.open_chapter("supermarket")
	# Chinese tiers order the chapter: turn to the spread with the first found word.
	for i in book.chapter_keys("supermarket").find(found_market[0]) / 8:
		book.turn_page(1)
	await process_frame
	var zh_sticker: Button = sticker_of(found_market[0])
	check(zh_sticker != null and zh_sticker.get_node("Word").text == UiText.word(found_market[0], "zh"), "a found sticker shows the Chinese word")
	await shot("zh-chapter", 20)
	book.open_detail(found_market[0])
	await process_frame
	var reading: String = settings.reading({"foreign": book.detail_foreign.text})
	check(book.detail_reading.text == reading and book.detail_reading.visible == (reading != ""), "word page: pinyin under the Chinese word (\"%s\")" % book.detail_reading.text)
	await shot("zh-word-page", 30)
	book.go_back()
	book.go_back()
	game.toggle_study_journal()
	settings.set_languages("zh", "en")
	for i in 3: await process_frame
	game.toggle_study_journal()
	await process_frame
	check(book.view == "contents" and book.title_label.text == UiText.t("journal.contents") and hud.journal_progress_label.text.contains(str(book.total_words)), "a Chinese interface: contents and header (\"%s\")" % hud.journal_progress_label.text)
	await shot("zh-ui-contents", 20)
	game.toggle_study_journal()
	print("JOURNAL STICKER BOOK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
