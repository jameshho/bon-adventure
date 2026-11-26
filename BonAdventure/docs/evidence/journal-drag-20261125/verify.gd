extends SceneTree
## Journal drag-to-scroll (improvement plan UI-03, 25 Nov 2026; vocabulary_book.gd _on_list_input()).
## At the window's size (run at 1280 x 800, laptop, and 844 x 390, phone landscape): a drag on a word row scrolls the list
## with the finger and opens nothing; a tap (a few pixels of travel) opens the row; a tap on the
## star saves the word and a drag that starts on the star does not; the wheel still scrolls.
## The journal is laid out when it opens, so each size is its own run (a window resized afterwards
## leaves the panel where it was). Each run is tested with mouse events (Viewport.push_input) and with touches
## (Input.parse_input_event, emulated as the mouse as on a phone). Saves table-<size>.png and
## dragged-<size>.png here. Writes user:// saves (bookmarks): run with an isolated HOME and graphics:
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/journal-drag-20261125/verify.gd
##   (and again with --resolution 844x390)
const DIR := "res://docs/evidence/journal-drag-20261125/"
var failures := 0
var checks := 0
var game
var hud
var book

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("ok:   " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func shot(name: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR + name + ".png")

## A press at `from`, moved to `to` in `steps`, released there: mouse events or touches.
func gesture(from: Vector2, to: Vector2, steps: int, touch: bool) -> void:
	await press(from, true, touch)
	for i in range(1, steps + 1):
		var at := from.lerp(to, float(i) / steps)
		if touch:
			var drag := InputEventScreenDrag.new()
			drag.position = at
			drag.relative = (to - from) / steps
			Input.parse_input_event(drag)
		else:
			var motion := InputEventMouseMotion.new()
			motion.position = at
			motion.global_position = at
			motion.relative = (to - from) / steps
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(motion)
		await process_frame
	await press(to, false, touch)
	for i in range(3): await process_frame

func press(at: Vector2, down: bool, touch: bool) -> void:
	if touch:
		var t := InputEventScreenTouch.new()
		t.position = at
		t.pressed = down
		Input.parse_input_event(t)
	else:
		if down:
			# A mouse is over the spot before it presses (the first press of a run had none).
			var hover := InputEventMouseMotion.new()
			hover.position = at
			hover.global_position = at
			root.push_input(hover)
			await process_frame
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = at
		event.global_position = at
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event)
	await process_frame

func wheel(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_WHEEL_DOWN
		event.pressed = down
		event.position = at
		event.global_position = at
		root.push_input(event)
		await process_frame

func row_key(row: Control) -> String:
	return str(row.get_meta("line").get_meta("key", ""))

## The first visible word row fully inside the list, below its top.
func word_row(skip := 1) -> Control:
	var area: Rect2 = book.list_area.get_global_rect()
	for row in book.rows:
		if row.visible and row_key(row) != "" and area.encloses(row.get_global_rect()):
			if skip == 0:
				return row
			skip -= 1
	return null

func test_size(size: Vector2i, touch: bool) -> void:
	var tag := "%dx%d-%s" % [size.x, size.y, "touch" if touch else "mouse"]
	book.scroll.value = 0.0
	for i in range(4): await process_frame
	if not touch:
		await shot("table-%dx%d" % [size.x, size.y])
	var row := word_row(2)
	check(row != null, tag + ": a word row is on screen")
	if row == null:
		return
	var word := row.get_meta("line").get_child(book.FOREIGN_CELL) as Control
	var at := word.get_global_rect().get_center()
	# Drag up by about three rows: the list follows the finger, nothing opens.
	var distance: float = book.row_height() * 3.0
	var before: float = book.scroll.value
	await gesture(at, at - Vector2(0, distance), 8, touch)
	var moved: float = book.scroll.value - before
	check(absf(moved - distance) < 2.0, "%s: drag scrolls the list with the finger (%.0f of %.0f px)" % [tag, moved, distance])
	check(not book.is_detail_open(), tag + ": a drag on a row opens nothing")
	check(not book.dragging, tag + ": the drag ends on release")
	if not touch:
		await shot("dragged-%dx%d" % [size.x, size.y])
	# Drag back down: scrolls back.
	await gesture(at - Vector2(0, distance), at, 8, touch)
	check(absf(book.scroll.value - before) < 2.0, tag + ": dragging down scrolls back (%.0f)" % book.scroll.value)
	# A tap with a little wobble (under the slop) opens the row under the finger.
	row = word_row(2)
	var key := row_key(row)
	await gesture(at, at + Vector2(3, 4), 2, touch)
	check(book.is_detail_open() and book.detail_key == key, "%s: a tap (5 px wobble) opens the row (%s, open %s)" % [tag, key, book.detail_key if book.is_detail_open() else "-"])
	check(absf(book.scroll.value - before) < 0.5, tag + ": a tap does not scroll")
	book.close_detail()
	for i in range(3): await process_frame
	# The star: a drag that starts on it scrolls and saves nothing; a tap saves.
	row = word_row(2)
	key = row_key(row)
	var star := row.get_meta("line").get_child(0) as Button
	var had: bool = hud.bookmarks.has(key)
	var star_at := star.get_global_rect().get_center()
	await gesture(star_at, star_at - Vector2(0, distance * 0.5), 6, touch)
	check(hud.bookmarks.has(key) == had and not book.is_detail_open(), "%s: a drag from the star saves nothing (%s)" % [tag, key])
	check(book.scroll.value > before + distance * 0.4, tag + ": ... and scrolls")
	book.scroll.value = before
	for i in range(3): await process_frame
	row = word_row(2)
	key = row_key(row)
	star = row.get_meta("line").get_child(0) as Button
	had = hud.bookmarks.has(key)
	await gesture(star.get_global_rect().get_center(), star.get_global_rect().get_center(), 1, touch)
	check(hud.bookmarks.has(key) != had and not book.is_detail_open(), "%s: a tap on the star saves or unsaves %s and opens nothing" % [tag, key])
	if hud.bookmarks.has(key) != had:
		await gesture(star.get_global_rect().get_center(), star.get_global_rect().get_center(), 1, touch)
	# The wheel (mouse only) still scrolls three rows.
	if not touch:
		before = book.scroll.value
		await wheel(at)
		check(absf(book.scroll.value - before - book.row_height() * 3.0) < 1.0, "%s: the wheel scrolls three rows (%.0f px)" % [tag, book.scroll.value - before])

func run():
	if DisplayServer.get_name() == "headless":
		print("JOURNAL DRAG: needs graphics")
		quit(1)
		return
	# A covered window stops drawing on macOS (frame_post_draw never comes).
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	# The desktop's real cursor must not mix its hover and clicks into the scripted gestures (a
	# run without this failed different checks each time): OS mouse events pass through.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await process_frame
	hud = game.hud
	book = hud.journal_book
	game.toggle_study_journal()
	for i in range(4): await process_frame
	check(hud.is_journal_open(), "the journal is open")
	for size in [DisplayServer.window_get_size()]:
		for i in range(20): await process_frame
		print("JOURNAL DRAG: window %s, viewport %s, scale %.2f, row %.0f px" % [size, root.get_visible_rect().size, book.factor, book.row_height()])
		for touch in [false, true]:
			await test_size(size, touch)
	print("JOURNAL DRAG: %d checks, %d failures" % [checks, failures])
	quit()
