extends SceneTree
## 13 Nov 2026 left-hand holding and inspection (docs/guides/HAND_HOLD.md): checks hold / swap /
## release, solids off while held, the holding arm pose, the Inspect button, the close-up and its
## exit; with graphics it also renders the poses and the close-up into this folder.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/hand-hold-20261113/verify.gd
## 25 Nov 2026: the close checks follow the book's tap_close (a press or Esc, no ✕); the basket
## keeps the ✕ and the popup stack.
## (headless works too: checks only). Writes <view>.png here with graphics; reads no saves.
const OUT := "res://docs/evidence/hand-hold-20261113"
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
	check(hand != null and hand.get_parent() == player.parts["Arm"], "hand socket rides on the left arm")
	var ui = game.hold_ui
	check(ui != null and not ui.inspect_button.visible, "no Inspect button with an empty hand")
	# --- a book (the library's picture book scene, at town scale) from a shelf-like parent
	var shelf := Node3D.new()
	shelf.name = "TestShelf"
	game.apartment.add_child(shelf)
	shelf.global_position = player.global_position + Vector3(3, 0, 0)
	var book: Node3D = load("res://scenes/props/book.tscn").instantiate()
	book.title = "Soccer"
	book.size = Vector3(.45, .54, .18)
	book.spine_color = Color("d4572a")
	shelf.add_child(book)
	book.position = Vector3(.2, .5, 0)
	var book_home: Transform3D = book.transform
	await process_frame
	var world_size: Vector3 = book.global_basis.get_scale()
	check(hand.hold(book) == null and hand.held == book and hand.profile == hand.PROFILES["book"], "holds a book with the book profile")
	check(book.global_basis.get_scale().is_equal_approx(world_size), "the book keeps its world size")
	await process_frame
	ui._refresh()
	check(ui.inspect_button.visible, "Inspect button shows while holding")
	# --- arm pose: standing still is stable, walking swings the arm (smaller than an empty arm)
	player.gait_weight = 0.0
	player.jump_pose = 0.0
	_pose(player, 0.0)
	var still: Vector3 = book.global_position
	_pose(player, 0.0)
	check(book.global_position.is_equal_approx(still), "standing still: the book stays put")
	_pose(player, PI * .5, .8)
	var forward: Vector3 = book.global_position
	_pose(player, PI * 1.5, .8)
	var back: Vector3 = book.global_position
	var travel := forward.distance_to(back)
	check(travel > .05 and travel < .6, "walking: the book swings with the arm (%.2f)" % travel)
	if graphics:
		_pose(player, 0.0)
		await shot(player, "book-standing", Vector3(-3.2, 1.6, -2.6))
		_pose(player, PI * .5, .9)
		await shot(player, "book-walking", Vector3(-3.2, 1.6, -2.6))
		_pose(player, 0.0)
		await shot(player, "book-behind", Vector3(-1.6, 2.2, 4.2))
	# --- inspect: zoom in, controls off; a book closes with a press anywhere or Esc (its profile's
	# "tap_close", since 24 Nov 2026: no ✕); closing puts it back in the hand
	_pose(player, 0.0)
	game.camera.current = true
	ui.open_inspection()
	check(ui.inspecting() and book.get_parent() == ui.inspector.stage, "Inspect opens a close-up of the held book")
	check(not player.controls_enabled, "movement off while inspecting")
	ui._refresh()
	check(ui.tap_close and not ui.close_button.visible and not ui.inspect_button.visible, "a book shows no ✕ and no Inspect while open (tap_close)")
	await create_timer(.6).timeout
	if graphics:
		await frame("book-inspect")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	ui._input(press)
	await create_timer(.6).timeout
	check(not ui.inspecting() and book.get_parent() == hand.swing, "a press anywhere closes it and puts the book back in the hand")
	game.sync_player_controls()
	check(player.controls_enabled, "movement back after closing")
	ui.open_inspection()
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	ui._input(esc)
	await create_timer(.6).timeout
	check(not ui.inspecting() and book.get_parent() == hand.swing, "Esc closes a book's close-up too")
	game.sync_player_controls()
	# --- swap for a basket: the book comes back detached
	var basket: Node3D = load("res://scenes/props/shopping_basket.tscn").instantiate()
	shelf.add_child(basket)
	basket.scale = Vector3.ONE * 1.3
	await process_frame
	var solids := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	solids.add_child(shape)
	basket.add_child(solids)
	var old: Node3D = hand.swap(basket)
	check(old == book and book.get_parent() == null and hand.held == basket and hand.profile == hand.PROFILES["basket"], "swap returns the book and holds the basket")
	await physics_frame
	check(shape.disabled, "the basket's solid shape is off while held")
	shelf.add_child(book)
	book.transform = book_home
	if graphics:
		_pose(player, 0.0)
		await shot(player, "basket-standing", Vector3(-3.2, 1.6, -2.6))
		_pose(player, PI * .5, .9)
		await shot(player, "basket-walking", Vector3(-3.2, 1.6, -2.6))
	# --- a basket (no tap_close) keeps the ✕, which the popup stack closes (Esc)
	_pose(player, 0.0)
	game.camera.current = true
	ui.open_inspection()
	ui._refresh()
	check(not ui.tap_close and ui.close_button.visible and not ui.inspect_button.visible, "the basket's close-up shows the ✕ instead of Inspect")
	check(game.popups.is_open(ui.close_button), "Esc closes the basket's close-up (popup stack)")
	await create_timer(.6).timeout
	if graphics:
		await frame("basket-inspect")
	game.popups.close_top()
	await create_timer(.6).timeout
	check(not ui.inspecting() and basket.get_parent() == hand.swing, "closing puts the basket back in the hand")
	game.sync_player_controls()
	check(player.controls_enabled, "movement back after the basket's close-up")
	# --- release: back where it came from, solids on, button gone
	var put: Node3D = hand.release()
	await physics_frame
	check(put == basket and basket.get_parent() == shelf and hand.held == null, "release puts the basket back")
	check(not shape.disabled, "its solid shape is on again")
	ui._refresh()
	check(not ui.inspect_button.visible, "Inspect button hides with an empty hand")
	# --- hold, then release to a new place at a given transform
	hand.hold(book)
	var spot := Transform3D(Basis(), shelf.global_position + Vector3(0, 1, 1))
	hand.release(shelf, spot)
	check(book.get_parent() == shelf and book.global_position.is_equal_approx(spot.origin), "release to a target places it there")
	print("HAND HOLD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

## Poses BonBon's limbs at a gait phase and weight, as animate_bonbon() does while walking.
func _pose(player, phase: float, weight := 0.0) -> void:
	player.gait_phase = phase
	player.gait_weight = weight
	player.jump_pose = 0.0
	player.animate_bonbon(0.00001, 0.0)
	player.gait_weight = weight
	player.animate_bonbon(0.0, 0.0)

func shot(player, title: String, offset: Vector3) -> void:
	var cam := Camera3D.new()
	cam.fov = 45
	root.add_child(cam)
	var body: Node3D = player.visual
	cam.global_position = body.global_transform * offset
	cam.look_at(body.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	cam.current = true
	game.hud.visible = false
	await frame(title)
	game.hud.visible = true
	cam.queue_free()
	game.camera.current = true

func frame(title: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
