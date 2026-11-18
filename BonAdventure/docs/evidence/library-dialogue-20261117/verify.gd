extends SceneTree
## SUPERSEDED the same day by docs/evidence/library-refresh-20261117/verify.gd (new titles, no "Another cart?").
## 17 Nov 2026: Rosa's book-sorting game after the user's review (scripts/learning/library_session.gd;
## docs/guides/MINIGAMES.md). Replaces docs/evidence/library-sorting-20261113/verify.gd as runner id
## `library_sorting`. The display, the cart and its 3-6 books; the first greeting, then
## greeting_again; the two start lines; a wrong shelf wobbles and the book goes back to the hand;
## the right one slides, hops and sparks; talking mid-game: holding / left_one / left_many with OK
## and "I'll help later"; the game ends by itself with perfect + one book's recap, then "Another
## cart?"; Yes fills a fresh cart.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/library-dialogue-20261117/verify.gd
## (headless: checks only). With graphics writes *.png here; reads no saves.
const OUT := "res://docs/evidence/library-dialogue-20261117"
const Interactable := preload("res://scripts/core/interactable.gd")
const Session := preload("res://scripts/learning/library_session.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
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
	var player = game.player
	player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var hand: Node3D = player.hand
	var session = game.get_node_or_null("LibrarySession")
	var shelves: Node3D = game.find_child("CategoryShelves", true, false)
	check(session != null and session.host != null and shelves != null, "library session and shelves found")
	if session == null or session.host == null or shelves == null:
		return finish()
	var host = session.host
	var lexicon = host.lexicon
	var panel = host.dialogue_panel
	var librarian: Node3D = host.npc
	check(session.catalog.size() == 18 and session.slots.size() == 6, "18 titles, 6 cart slots")
	check(session.gaps.size() >= 18 and session.gaps.all(func(g): return Interactable.on(g) != null), "every gap has an Interactable (%d)" % session.gaps.size())
	check(not session.has_method("_check") and not session.has_method("_host_calling"), "Rosa no longer checks or calls with an empty cart")
	for id in ["ask_done", "done", "not_yet", "cart_left", "keep_going", "stop", "wrong_animals", "wrong_space"]:
		check(not lexicon.phrases.has("library." + id), "phrase library.%s removed" % id)
	# --- the first greeting, then the game
	host.offered = true
	host._on_talk(librarian)
	check(host.line_id == "library.greeting", "first talk: the full greeting (%s)" % host.line_id)
	host.close_dialogue()
	host.launch()
	var books: Array = session.books
	check(session.playing and books.size() >= 3 and books.size() <= 6, "a game puts 3-6 books on the cart (%d)" % books.size())
	check(host.line_id == "library.start" and panel.current_line() == lexicon.line("library.start"), "Rosa's first start line")
	await create_timer(4.4).timeout
	await process_frame
	check(host.line_id == "library.start_signs", "the second start line follows (%s)" % host.line_id)
	host.close_dialogue()
	# --- mid-game talk: how many are left
	host._on_talk(librarian)
	var want_left := "library.left_many" if books.size() > 1 else "library.left_one"
	check(host.line_id == want_left and panel.has_choices(), "mid-game talk says how many are left (%s)" % host.line_id)
	var count_text: String = lexicon.number(books.size(), lexicon.foreign, true)
	check(str(panel.current_line().foreign).contains(count_text), "the count is in the line (%s)" % panel.current_line().foreign)
	if graphics:
		await view("talk-left", librarian.global_position + _flat(-librarian.global_basis.z) * 2.6 + Vector3(0, 1.5, 0), librarian.global_position + Vector3(0, .9, 0), true)
	session._on_choice(host.choice_prefix() + "ok")
	check(not host.owns_dialogue() and session.playing, "OK closes the box and the game goes on")
	# --- holding a book
	var first: Node3D = books[0]
	Interactable.on(first).activate()
	check(hand.held == first, "E takes a cart book in the hand")
	host._on_talk(librarian)
	check(host.line_id == "library.holding", "talking while holding a book -> holding (%s)" % host.line_id)
	host.close_dialogue()
	# --- wrong shelf: wobble, back to the hand
	var wrong_gap: Node3D = _gap(session, str(first.get_meta("library_category")), false)
	check(Interactable.on(wrong_gap).check() == true, "E at a free gap while holding the book")
	_stand_before(player, wrong_gap, 1.1)
	var sparks_before := wrong_gap.get_child_count()
	Interactable.on(wrong_gap).activate()
	check(first.get_parent() == wrong_gap and hand.held == null and wrong_gap.get_child_count() == sparks_before + 1, "wrong shelf: placed with no sparks")
	if graphics:
		for i in 3: await process_frame
		await view("wrong-wobble", wrong_gap.global_transform * Vector3(.9, .9, -1.6), wrong_gap.global_transform * Vector3(0, .45, 0))
	await create_timer(.7).timeout
	check(hand.held == first, "after the wobble the book is back in the hand")
	check(session._gap_free(wrong_gap), "the wrong gap is free again")
	if graphics:
		await view("wrong-back-in-hand", wrong_gap.global_transform * Vector3(1.6, 1.3, -2.4), wrong_gap.global_transform * Vector3(0, .4, 0), true)
	# E on the held book puts it back on its cart slot (its home is the cart, not the wrong gap).
	Interactable.on(first).activate()
	check(session.slots.has(first.get_parent()) and hand.held == null, "putting the book down sends it back to the cart")
	# --- every book but the last to its own shelf
	var animated := true
	for b in books.slice(0, books.size() - 1):
		Interactable.on(b).activate()
		var gap := _gap(session, str(b.get_meta("library_category")), true)
		var before := gap.get_child_count()
		Interactable.on(gap).activate()
		animated = animated and b.get_parent() == gap and gap.get_child_count() > before + 1 and not b.transform.is_equal_approx(Session.SHELVED)
	check(animated, "right shelf: the book slides in with sparks")
	await create_timer(.8).timeout
	check(session.playing and session._left() == 1, "one book left, the game goes on")
	host._on_talk(librarian)
	check(host.line_id == "library.left_one", "one book left -> left_one (%s)" % host.line_id)
	host.close_dialogue()
	# --- the last book: the game ends by itself
	var last: Node3D = books[books.size() - 1]
	Interactable.on(last).activate()
	var last_gap := _gap(session, str(last.get_meta("library_category")), true)
	_stand_before(player, last_gap, 1.3)
	Interactable.on(last_gap).activate()
	if graphics:
		for i in 5: await process_frame
		await view("right-shelf", last_gap.global_transform * Vector3(.9, .9, -1.6), last_gap.global_transform * Vector3(0, .45, 0))
	await create_timer(.8).timeout
	check(not session.playing and host.line_id == "library.perfect", "the last book ends the game with perfect (%s)" % host.line_id)
	var shown: Dictionary = panel.current_line()
	var recalled := books.any(func(b): return str(shown.get("foreign", "")).contains(SignLanguage.say(str(b.get_meta("book_title")), lexicon.foreign)) and str(shown.get("native", "")).contains(SignLanguage.say(str(b.get_meta("book_title")), lexicon.native)))
	check(recalled, "the thanks recall one of this cart's books in both languages: %s / %s" % [shown.get("foreign"), shown.get("native")])
	check(not str(shown.get("foreign", "")).contains("{") and not str(shown.get("native", "")).contains("{"), "no unfilled placeholders")
	if graphics:
		await view("win-recap", last_gap.global_transform * Vector3(0, 1.0, -2.6), last_gap.global_transform * Vector3(0, .4, .2), true)
	# --- "Another cart?" after the thanks close
	panel.hide_dialogue()
	host._on_dialogue_closed()
	await process_frame
	await process_frame
	check(host.line_id == "library.again" and panel.has_choices(), "Another cart? follows the thanks (%s)" % host.line_id)
	var old: Array = books.duplicate()
	host._on_choice(host.choice_prefix() + "play")
	check(session.playing and session.books.size() >= 3 and old.all(func(b): return not is_instance_valid(b) or b.is_queued_for_deletion() or b.get_parent() == null), "Yes clears the shelved books and fills the cart again")
	host.close_dialogue()
	# --- I'll help later, with a book in the hand
	Interactable.on(session.books[0]).activate()
	var held: Node3D = hand.held
	host._on_talk(librarian)
	session._on_choice(host.choice_prefix() + "later")
	check(not session.playing and session.books.is_empty() and hand.held == null and held.get_parent() == null, "I'll help later clears the cart, shelves and hand")
	check(host.line_id == "library.stopped", "Rosa's thanks anyway (%s)" % host.line_id)
	host.close_dialogue()
	# --- later greetings
	host.offered = true
	host._on_talk(librarian)
	check(host.line_id == "library.greeting_again", "a later talk greets the player back (%s)" % host.line_id)
	finish()

func finish() -> void:
	print("LIBRARY SORTING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _flat(v: Vector3) -> Vector3:
	v.y = 0
	return v.normalized()

## A free gap of (or not of) `category`.
func _gap(session, category: String, same: bool) -> Node3D:
	for g in session.gaps:
		if (str(g.get_meta("library_category")) == category) == same and session._gap_free(g) and float(g.global_position.y - session.cart.global_position.y) < 2.0:
			return g
	return null

func _stand_before(player, gap: Node3D, distance: float) -> void:
	var out := _flat(-gap.global_basis.z)
	var at := gap.global_position
	var floor_y: float = game.find_child("CategoryShelves", true, false).global_position.y
	player.global_position = Vector3(at.x, floor_y, at.z) + out * distance
	player.look_at(Vector3(at.x, floor_y, at.z), Vector3.UP)

func view(title: String, from: Vector3, to: Vector3, with_hud := false) -> void:
	var cam := Camera3D.new()
	cam.fov = 55
	root.add_child(cam)
	cam.global_position = from
	cam.look_at(to, Vector3.UP)
	cam.current = true
	game.hud.visible = with_hud
	game.player.visible = with_hud
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	game.player.visible = true
	cam.queue_free()
	game.camera.current = true
