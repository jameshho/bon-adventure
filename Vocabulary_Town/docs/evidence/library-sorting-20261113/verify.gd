extends SceneTree
## 13 Nov 2026: Rosa's book-sorting game (scripts/learning/library_session.gd; docs/guides/MINIGAMES.md).
## The NEW BOOKS display, the return cart and its slots; a game fills the cart with 3-6 of the
## display's titles; a held book shows E at free gaps; a wrong shelf gets no flourish, the right
## one a slide, hop and sparks; Rosa's check says cart_left, wrong_<shelf> or perfect; Stop and a
## replay clear the books.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/library-sorting-20261113/verify.gd
## (headless: checks only). With graphics writes *.png here; reads no saves.
const OUT := "res://docs/evidence/library-sorting-20261113"
const Interactable := preload("res://scripts/core/interactable.gd")
const Session := preload("res://scripts/learning/library_session.gd")
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
	# --- the display and the cart
	var header := shelves.get_node_or_null("New books shelf/NEW BOOKS header") as Label3D
	check(header != null and str(header.get_meta("sign_english", "")) == "NEW BOOKS", "the display's header is NEW BOOKS")
	check(shelves.get_node_or_null("New books shelf/ReturnBooks") != null and session.catalog.size() == 24, "24 titles in the collection (%d)" % session.catalog.size())
	var cart: Node3D = session.cart
	check(cart != null and str(cart.get_meta("word_key", "")) == "trolley" and session.slots.size() == 6, "return cart (trolley) with 6 slots")
	var librarian: Node3D = session.host.npc
	check(cart != null and cart.global_position.distance_to(librarian.global_position) < 3.5, "the cart stands near Rosa (%.2f m)" % (cart.global_position.distance_to(librarian.global_position) if cart else -1.0))
	check(session.gaps.size() >= 24 and session.gaps.all(func(g): return Interactable.on(g) != null), "every gap has an Interactable (%d)" % session.gaps.size())
	check(session.books.is_empty() and not session.playing, "the cart is empty before a game")
	if graphics:
		var rack: Node3D = header.get_parent() if header else null
		if rack:
			await view("new-books", rack.to_global(Vector3(0, 2.0, -3.2)), rack.to_global(Vector3(0, 2.2, 0)))
		await view("cart-idle", librarian.global_position + _flat(-librarian.global_basis.z) * 3.2 + Vector3(0, 1.9, 0) + _flat(librarian.global_basis.x) * 1.2, cart.global_position + Vector3(0, .9, 0))
	# --- start: Rosa's question, then the cart fills
	session.host.offered = true
	session.host._on_talk(librarian)
	check(session.host.line_id == "library.greeting", "Rosa asks the greeting (%s)" % session.host.line_id)
	session.host.close_dialogue()
	session.host.launch()
	var books: Array = session.books
	check(session.playing and books.size() >= 3 and books.size() <= 6, "a game puts 3-6 books on the cart (%d)" % books.size())
	check(books.all(func(b): return session.slots.has(b.get_parent()) and Interactable.on(b) != null and b.has_meta("library_category")), "each book stands on a cart slot and can be taken")
	var titles := {}
	for b in books:
		titles[str(b.get_meta("book_title"))] = true
	check(titles.size() == books.size() and titles.keys().all(func(t): return session.catalog.any(func(e): return e.title == t)), "distinct titles from the collection")
	check(session.host.line_id == "library.start", "Rosa explains the task")
	if graphics:
		session.host.close_dialogue()
		await view("cart-filled", cart.global_position + _flat(-cart.global_basis.z) * 2.2 + Vector3(0, 1.7, 0), cart.global_position + Vector3(0, .9, 0))
	# --- report too early: books left on the cart
	session._on_choice(session.host.choice_prefix() + "done")
	check(session.host.line_id == "library.cart_left", "books left on the cart -> cart_left (%s)" % session.host.line_id)
	# --- a free gap offers E only while holding one of the game's books
	var first: Node3D = books[0]
	var wrong_gap: Node3D = _gap(session, str(first.get_meta("library_category")), false)
	check(Interactable.on(wrong_gap).check() == false, "no E at a gap with an empty hand")
	Interactable.on(first).activate()
	check(hand.held == first, "E takes a cart book in the hand")
	check(Interactable.on(wrong_gap).check() == true, "E at a free gap while holding the book")
	# Focus from in front of the wrong bookcase.
	_stand_before(player, wrong_gap, 1.1)
	game.interaction.refresh_focus()
	var focus = game.interaction.focus
	check(focus != null and focus.get_parent() is Node3D and session.gaps.has(focus.get_parent()), "standing at a bookcase, a gap gets the focus")
	if graphics:
		await view("gap-focus", wrong_gap.global_transform * Vector3(1.6, 1.3, -2.4), wrong_gap.global_transform * Vector3(0, .4, 0), true)
	# --- wrong shelf: placed, no flourish
	var sparks_before := wrong_gap.get_child_count()
	Interactable.on(wrong_gap).activate()
	check(first.get_parent() == wrong_gap and hand.held == null, "wrong shelf: the book stays where it was put")
	check(first.transform.is_equal_approx(Session.SHELVED) and wrong_gap.get_child_count() == sparks_before + 1, "wrong shelf: no slide, hop or sparks")
	check(Interactable.on(wrong_gap).check() == false, "an occupied gap offers nothing")
	# Every other book to its own shelf.
	var animated := true
	for b in books.slice(1):
		Interactable.on(b).activate()
		var gap := _gap(session, str(b.get_meta("library_category")), true)
		var before := gap.get_child_count()
		Interactable.on(gap).activate()
		animated = animated and b.get_parent() == gap and gap.get_child_count() > before + 1 and not b.transform.is_equal_approx(Session.SHELVED)
	check(animated, "right shelf: the book slides in with sparks")
	session.host.close_dialogue()
	check(session._host_calling(), "Rosa calls once the cart is empty")
	session._on_choice(session.host.choice_prefix() + "done")
	var expected := "library.wrong_" + str(wrong_gap.get_meta("library_category"))
	check(session.host.line_id == expected, "a wrong book -> Rosa names its shelf (%s, want %s)" % [session.host.line_id, expected])
	check(session.playing, "the game goes on after a wrong report")
	# --- fix it: take it from the wrong shelf, put it on its own
	Interactable.on(first).activate()
	check(hand.held == first and Interactable.on(wrong_gap).check() == true, "a shelved book can be taken again")
	var right_gap: Node3D = _gap(session, str(first.get_meta("library_category")), true)
	if graphics:
		_stand_before(player, right_gap, 1.3)
		game.interaction.refresh_focus()
	Interactable.on(right_gap).activate()
	if graphics:
		for i in 5: await process_frame
		await view("right-shelf", right_gap.global_transform * Vector3(.9, .9, -1.6), right_gap.global_transform * Vector3(0, .45, 0))
	await create_timer(.8).timeout
	check(first.get_parent() == right_gap and first.transform.is_equal_approx(Session.SHELVED), "the flourish ends with the book in place")
	session._on_choice(session.host.choice_prefix() + "done")
	check(session.host.line_id == "library.perfect" and not session.playing, "all right -> perfect, the game ends")
	if graphics:
		await view("shelved", right_gap.global_transform * Vector3(0, 1.0, -2.6), right_gap.global_transform * Vector3(0, .4, .2))
	# --- replay: new books, old ones gone
	var old: Array = books.duplicate()
	session.host.close_dialogue()
	session.host.launch()
	check(session.playing and session.books.size() >= 3 and old.all(func(b): return not is_instance_valid(b) or b.is_queued_for_deletion() or b.get_parent() == null), "a replay clears the shelved books and fills the cart again")
	# --- stop helping, with a book in the hand
	Interactable.on(session.books[0]).activate()
	var held: Node3D = hand.held
	session._on_choice(session.host.choice_prefix() + "stop")
	check(not session.playing and session.books.is_empty() and hand.held == null and held.get_parent() == null, "Stop helping clears the cart, shelves and hand")
	check(session.host.line_id == "library.stopped", "Rosa's thanks anyway")
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

func view(title: String, from: Vector3, to: Vector3, with_player := false) -> void:
	var cam := Camera3D.new()
	cam.fov = 55
	root.add_child(cam)
	cam.global_position = from
	cam.look_at(to, Vector3.UP)
	cam.current = true
	game.hud.visible = with_player
	game.player.visible = with_player
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	game.player.visible = true
	cam.queue_free()
	game.camera.current = true
