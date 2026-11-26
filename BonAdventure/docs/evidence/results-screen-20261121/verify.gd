extends SceneTree
## 21 Nov 2026 (user design): the reusable results screen after a minigame
## (scripts/ui/results_screen.gd, scripts/learning/session_words.gd; docs/guides/MINIGAMES.md#results-screen).
## Checks: session_words sorts new / practiced / struggled words from practice_log records and
## ranks highlights (new first, struggled first); the card's title, line, stat bubbles, at most 4
## highlighted words, "See all", rewards (quest, coins, stars), Continue / Play again / Esc, the
## "Great Practice!" variant with no new words, the card inside the window at laptop and phone
## size, every Chinese results phrase in the CJK font subset.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/results-screen-20261121/verify.gd
## (headless: checks only; with graphics it writes the PNGs here). Writes the practice log only in
## the isolated HOME.
const OUT := "res://docs/evidence/results-screen-20261121"
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const SessionWords := preload("res://scripts/learning/session_words.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
var checks := 0
var failures := 0
var game
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	game.player.set_physics_process(false)
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var screen = game.results_screen
	check(screen != null and not screen.visible, "Main has a hidden results screen")
	if screen == null:
		return finish()
	# --- the Chinese phrases are in the font subset
	var font := load("res://fonts/NotoSansTC-SemiBold-subset.ttf") as FontFile
	var missing := ""
	var phrases: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/phrases.json")).phrases.results
	for id in phrases:
		for c in str(phrases[id].get("zh", "")):
			if c.unicode_at(0) > 0x2e80 and not font.has_char(c.unicode_at(0)) and not missing.contains(c):
				missing += c
	check(missing == "", "every Chinese results phrase is in the font subset (missing: %s)" % missing)
	# --- session_words: new, practiced, struggled
	var log = PracticeLog.shared()
	log.paused = false
	var words = SessionWords.shared()
	words.start("results_test")
	log.begin("results_test", ["dog"])
	log.first_answer(true)
	log.complete()
	log.begin("results_test", ["cat"])
	log.first_answer(false)
	log.complete()
	words.start("results_test")
	log.begin("results_test", ["dog"])   # recorded before: practiced
	log.first_answer(true)
	log.complete()
	log.begin("results_test", ["cat"])   # recorded before, wrong again: practiced and struggled
	log.first_answer(false)
	log.complete()
	log.begin("results_test", ["pizza", "food"])   # new; food struggled
	log.first_answer({"pizza": true, "food": false})
	log.complete()
	log.begin("other_game", ["tree"])   # another game: ignored
	log.first_answer(true)
	log.complete()
	var s: Dictionary = words.summary()
	check(s.new == ["pizza", "food"] and s.practiced == ["dog", "cat"], "new %s, practiced %s" % [s.new, s.practiced])
	check(s.struggled == ["cat", "food"], "struggled %s" % [s.struggled])
	check(words.highlights(3) == ["food", "pizza", "cat"], "highlights: new struggled, new, familiar struggled (%s)" % [words.highlights(3)])
	# --- the standard card
	var replays := [0]
	var continues := [0]
	screen.replay_requested.connect(func(): replays[0] += 1)
	screen.continued.connect(func(): continues[0] += 1)
	var summary := {"new": ["chair", "table", "lamp", "bed", "sofa"], "practiced": ["dog", "cat", "pizza"], "struggled": ["lamp", "cat"],
			"all": ["chair", "table", "lamp", "bed", "sofa", "dog", "cat", "pizza"], "highlights": ["lamp", "chair", "table", "bed"]}
	screen.show_results({"title": "Books Sorted!", "line": "You helped Rosa put every book back on its shelf!", "words": summary, "replay": true,
			"rewards": [{"kind": "quest", "text": "Help Rosa sort the returned books"}, {"kind": "coins", "amount": 5}, {"kind": "stars", "amount": 2}]})
	await settle()
	check(screen.visible and not screen.shown.practice, "the card shows")
	check(screen.shown.stats == {"practiced": 3, "new": 5, "quests": 1}, "stats %s" % [screen.shown.stats])
	check(screen.shown.shown_words == ["lamp", "chair", "table", "bed"], "4 highlights (%s)" % [screen.shown.shown_words])
	check(_text(screen.card).contains("Books Sorted!") and _text(screen.card).contains("You helped Rosa"), "game title and line")
	check(not _text(screen.card).contains("%"), "no percentage")
	check(screen.card.find_child("Play again", true, false) != null and screen.card.find_child("Continue", true, false) != null, "Continue and Play again")
	check(not game.player.controls_enabled, "the player is locked while it shows")
	_inside(screen, "laptop")
	if graphics:
		await shot("results-laptop")
	(screen.card.find_child("See all", true, false) as Button).pressed.emit()
	await settle()
	check(screen.shown.shown_words.size() == 8, "See all lists all 8 words")
	_inside(screen, "see all")
	if graphics:
		await shot("results-see-all")
	(screen.card.find_child("Play again", true, false) as Button).pressed.emit()
	check(not screen.visible and replays[0] == 1, "Play again closes and asks for a replay")
	# --- no new words: Great Practice!
	screen.show_results({"title": "Books Sorted!", "words": {"new": [], "practiced": ["dog", "cat", "pizza", "food", "tree", "chair", "table", "lamp", "bed", "sofa", "car", "train"],
			"struggled": [], "all": ["dog", "cat", "pizza", "food", "tree", "chair", "table", "lamp", "bed", "sofa", "car", "train"]}})
	await settle()
	check(screen.shown.practice and screen.shown.stats == {"practice": 12}, "no new words: one practice stat (%s)" % [screen.shown.stats])
	var lex = Lexicon.shared()
	check(_text(screen.card).contains(lex.phrase("results.practice_title", lex.native)) and not _text(screen.card).contains("0 "), "Great Practice!, no 0 new words")
	check(screen.card.find_child("Play again", true, false) == null, "no Play again without replay")
	if graphics:
		await shot("results-practice")
	screen.close_requested.emit()
	check(not screen.visible and continues[0] == 1, "Esc continues")
	# --- words that became known this session (LEARN-04, D9, 25 Nov 2026)
	screen.show_results({"title": "Books Sorted!", "words": {"new": ["chair"], "practiced": ["dog", "cat"], "struggled": [], "known": ["dog"],
			"all": ["chair", "dog", "cat"], "highlights": ["chair", "dog", "cat"]}})
	await settle()
	check(screen.shown.stats.get("known", 0) == 1, "a known-words bubble (%s)" % [screen.shown.stats])
	var dog_row: Node = screen.card.find_child("Word dog", true, false)
	check(dog_row != null and dog_row.find_child("Tag known", true, false) != null and screen.card.find_child("Word cat", true, false).find_child("Tag known", true, false) == null, "the known word's row has the Known tag, others not")
	check(_text(screen.card).contains(lex.phrase("results.stat_known", lex.native)) and not _text(screen.card).contains("%"), "Words you now know, no percentage")
	screen.close_requested.emit()
	# --- the shared flow (results_flow.gd) for other games
	var board = preload("res://scripts/learning/activity_board.gd").shared()
	var flow = game.results_flow
	board.started.emit("lineup_rocco")
	board.ended.emit("lineup_rocco", {"completed": true})
	await create_timer(1.2).timeout
	check(screen.visible and screen.shown.title == lex.phrase("results.title_lineup_rocco", lex.native) and screen.shown.line == lex.phrase("results.line_lineup_rocco", lex.native), "a finished Spot the Suspect: Case Closed! (%s)" % screen.shown.get("title"))
	check(screen.shown.rewards.any(func(r): return r.kind == "quest") and screen.shown.rewards.any(func(r): return r.kind == "xp" and r.amount > 0), "its mission: Quest updated! and XP (%s)" % [screen.shown.rewards])
	if graphics:
		await shot("results-quest")
	screen.close_requested.emit()
	board.ended.emit("warehouse_ramon", {"completed": false})
	board.ended.emit("radar_patrol", {"completed": true})
	await create_timer(1.2).timeout
	check(not screen.visible and flow.pending == "", "nothing for a game ended early or a pastime")
	var ids := ["shop_supermarket", "family_dr_li", "warehouse_ramon", "flight_bruno", "restaurant_twinkle", "lineup_rocco", "evidence_mimi", "grammar_lana", "mystery_luna", "library_rosa", "teller_bank"]
	check(ids.all(func(id): return lex.phrases.has("results.title_" + id) and lex.phrases.has("results.line_" + id)), "every learning game has its own title and line")
	# --- phone size (landscape)
	if graphics:
		root.size = Vector2i(844, 390)
		await settle()
		screen.show_results({"title": "Books Sorted!", "line": "You helped Rosa put every book back on its shelf!", "words": summary, "replay": true,
				"rewards": [{"kind": "quest", "text": "Help Rosa sort the returned books"}]})
		await settle()
		_inside(screen, "phone")
		await shot("results-phone")
		screen.close_requested.emit()
	finish()

func settle() -> void:
	for i in 6: await process_frame

## The card fits the window (graphics only: a headless window is 64 x 64).
func _inside(screen, label: String) -> void:
	if not graphics:
		return
	var view: Rect2 = screen.get_viewport().get_visible_rect()
	var rect: Rect2 = screen.card.get_global_rect()
	check(view.encloses(rect), "%s: the card fits the window (%s in %s)" % [label, rect, view.size])

func _text(node: Node) -> String:
	var out := ""
	for child in node.find_children("*", "Label", true, false):
		out += (child as Label).text + "\n"
	for child in node.find_children("*", "Button", true, false):
		out += (child as Button).text + "\n"
	return out

func shot(title: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

func finish() -> void:
	print("RESULTS SCREEN: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
