extends SceneTree
## Known words (improvement plan LEARN-04 / C11, decision D9, 25 Nov 2026): word_memory.gd
## is_known() (stability >= LEARNED_STABILITY) drives the journal's daisy marker and known count
## (vocabulary_book.gd) and the results card's "Words you now know" bubble and Known tag
## (session_words.gd "known", results_screen.gd). Seeds a test save (practice log, studied words,
## word memory with a few known words and one almost known) BEFORE Main loads, records one game
## through the practice log so the almost-known word becomes known, then checks and renders the
## journal and the results card at the window size: run once with --resolution 1280x800 (laptop)
## and once with --resolution 844x390 (phone landscape).
## Writes user:// saves: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none \
##     godot --path . --resolution 1280x800 --script res://docs/evidence/known-words-20261125/verify.gd
## (headless: checks only; with graphics it writes the PNGs next to this script).
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const WordMemory := preload("res://scripts/learning/word_memory.gd")
const SessionWords := preload("res://scripts/learning/session_words.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Progress := preload("res://scripts/learning/vocabulary_progress.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const DIR := "res://docs/evidence/known-words-20261125/"
## Known before the game (stability well over the threshold).
const KNOWN := ["apple", "bread", "dog", "cat", "water"]
## Almost known: one right review after a gap makes it known.
const ALMOST := "banana"
const GAME := "shop_supermarket"
var failures := 0
var checks := 0
var graphics := false
var game

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
	if not graphics:
		return
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR + name + ".png")
	print("CAPTURE ", name)

func settle() -> void:
	for i in 6: await process_frame

func run():
	graphics = DisplayServer.get_name() != "headless"
	# --- Seed the test save -------------------------------------------------------------------
	var counts := {}
	var words := {}
	for key in KNOWN:
		counts[key] = {GAME: {"positive": 4, "negative": 0, "translated": 0}}
		words[key] = {"s": 30.0, "d": 3.0, "last": 30, "reps": 4, "lapses": 0}
	counts[ALMOST] = {GAME: {"positive": 1, "negative": 0, "translated": 0}}
	words[ALMOST] = {"s": WordMemory.W[2], "d": 1.0, "last": 0, "reps": 1, "lapses": 0}
	counts["milk"] = {GAME: {"positive": 0, "negative": 1, "translated": 0}}
	words["milk"] = {"s": WordMemory.W[0], "d": 7.0, "last": 2, "reps": 1, "lapses": 1}
	write(PracticeLog.PATH, {"es": counts})
	write(Progress.LANGUAGE_FILE, {"es": KNOWN + [ALMOST, "milk"]})
	SaveStore.write_json(SaveStore.path(WordMemory.FILE), {"es": {"step": 40, "last_new": 2, "words": words}})
	var settings = GameSettings.shared()
	settings.set_languages("en", "es")
	WordMemory._shared = null
	SessionWords._shared = null
	var memory = WordMemory.shared()
	check(KNOWN.all(func(k): return memory.is_known(k)) and not memory.is_known(ALMOST) and not memory.is_known("milk"), "seeded: 5 known, banana and milk not")

	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)

	# --- One game: banana becomes known, pizza is new, milk is practiced again ------------------
	memory = WordMemory.shared()   # Main may have reset the profile singletons
	var log = PracticeLog.shared()
	log.paused = false
	var session = SessionWords.shared()
	session.start(GAME)
	for item in [[ALMOST, true], ["pizza", true], ["milk", false], ["apple", true]]:
		log.begin(GAME, [item[0]])
		log.first_answer(item[1])
		log.complete()
	var summary: Dictionary = session.summary()
	check(memory.is_known(ALMOST) and summary.known == [ALMOST], "banana became known this session (%s, S %.2f)" % [summary.known, float(memory.state(ALMOST).s)])
	check(summary.new == ["pizza"] and not summary.known.has("apple"), "pizza new; apple was known already, not listed")

	# One window size per run (the HUD lays out for the window, not for root.size).
	for size in [root.size]:
		var tag := "phone" if size.y < 600 else "laptop"
		# --- The journal
		game.toggle_study_journal()
		await settle()
		var book = game.hud.journal_book
		check(book.known_total() == KNOWN.size() + 1, "%s: the journal counts %d known words (%d)" % [tag, KNOWN.size() + 1, book.known_total()])
		check(book.footer.text.contains(UiText.t("journal.known_count", {"n": KNOWN.size() + 1})), "%s: the footer says so (%s)" % [tag, book.footer.text])
		book.query = "banana"
		book.rebuild()
		await settle()
		var row: Control = book.row_for(ALMOST)
		var daisy: Control = row.get_meta("line").get_child(1).get_node("Known") if row != null else null
		check(daisy != null and daisy.visible, "%s: banana's row shows the daisy" % tag)
		book.query = ""
		book.set_filter("studied")
		await settle()
		var milk_row: Control = book.row_for("milk")
		check(milk_row == null or not milk_row.get_meta("line").get_child(1).get_node("Known").visible, "%s: milk (not known) has no daisy" % tag)
		await shot("journal-studied-" + tag)
		book.open_detail(ALMOST)
		await settle()
		check(book.detail_native.text.contains(UiText.t("journal.known_tag")), "%s: the detail view says known" % tag)
		await shot("journal-detail-" + tag)
		book.close_detail()
		book.set_filter("all")
		game.toggle_study_journal()
		await settle()
		# --- The results card
		var screen = game.results_screen
		screen.show_results({"title": UiText.t("results.title_done"), "line": "", "words": session, "replay": true})
		await settle()
		check(screen.shown.stats.get("known", 0) == 1 and screen.card.find_child("Tag known", true, false) != null, "%s: the results card has the known bubble and tag (%s)" % [tag, screen.shown.stats])
		if graphics:
			var view: Rect2 = screen.get_viewport().get_visible_rect()
			check(view.encloses(screen.card.get_global_rect()), "%s: the card fits the window" % tag)
		await shot("results-known-" + tag)
		screen.close_requested.emit()
		await settle()

	print("KNOWN WORDS CHECK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
