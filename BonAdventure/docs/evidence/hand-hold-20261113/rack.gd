extends SceneTree
## 13 Nov 2026: the library return rack's books are holdable (docs/guides/HAND_HOLD.md#books-on-the-return-rack):
## each is an interactable; E in front of one takes it in BonBon's left hand, E near its empty place
## puts it back, E on another rack book puts the held one back and takes that one.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/hand-hold-20261113/rack.gd
## (headless: checks only). With graphics writes rack-*.png here; reads no saves.
const OUT := "res://docs/evidence/hand-hold-20261113"
const Interactable := preload("res://scripts/core/interactable.gd")
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
	var shelf: Node3D = game.find_child("ReturnBooks", true, false)
	check(shelf != null, "return rack found")
	if shelf == null:
		return finish()
	var books: Array = shelf.get_children().filter(func(n): return n.has_meta("return_book"))
	check(books.size() == 24, "24 rack books (%d)" % books.size())
	check(books.all(func(b): return Interactable.on(b) != null), "every rack book has an Interactable")
	# Stand in front of a middle book of the second tier, facing it.
	var book: Node3D = books[7]
	var other: Node3D = books[8]
	var home: Transform3D = book.transform
	var out := -book.global_basis.z
	out.y = 0
	out = out.normalized()
	var floor_y: float = shelf.get_parent().global_position.y
	var aim := book.global_position
	player.global_position = Vector3(aim.x, floor_y, aim.z) + out * 1.1
	player.look_at(Vector3(aim.x, floor_y, aim.z), Vector3.UP)
	await process_frame
	game.interaction.refresh_focus()
	var focus = game.interaction.focus
	check(focus != null and focus.get_parent() in books, "a rack book gets the E focus")
	if graphics:
		await shot(player, "rack-focus", Vector3(-2.6, 2.4, 3.4), true)
	var picked: Node3D = focus.get_parent() if focus != null else book
	var picked_home: Transform3D = picked.transform
	game.use_pressed()
	check(hand.held == picked and picked.get_parent() == hand.swing, "E takes the focused book in the hand")
	await process_frame
	game.hold_ui._refresh()
	check(game.hold_ui.inspect_button.visible, "Inspect button shows for the rack book")
	if graphics:
		_rest(player)
		await shot(player, "rack-holding", Vector3(-3.0, 1.7, 0.6), false)
		await shot(player, "rack-gap", Vector3(-1.4, 2.4, 3.6), true)
	# E again (still in front of its place): it goes back exactly where it was.
	game.interaction.refresh_focus()
	check(game.interaction.focus == Interactable.on(picked), "the held book's E sits at its empty place")
	game.use_pressed()
	check(hand.held == null and picked.get_parent() == shelf and picked.transform.is_equal_approx(picked_home), "E puts it back in its place")
	# Swap: holding one book, using another puts the first back and takes the second.
	var second: Node3D = other if other != picked else book
	Interactable.on(picked).activate()
	Interactable.on(second).activate()
	check(hand.held == second and picked.get_parent() == shelf and picked.transform.is_equal_approx(picked_home), "using another book puts the first back and takes it")
	# Away from the rack the held book offers nothing (its E is at its place).
	player.global_position += out * 6.0
	game.interaction.refresh_focus()
	check(game.interaction.focus != Interactable.on(second), "no E for the held book away from the rack")
	hand.release()
	check(second.get_parent() == shelf and hand.held == null, "release puts it back")
	finish()

func finish() -> void:
	print("RACK BOOKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _rest(player) -> void:
	player.gait_weight = 0.0
	player.jump_pose = 0.0
	player.animate_bonbon(0.00001, 0.0)
	player.animate_bonbon(0.0, 0.0)

func shot(player, title: String, offset: Vector3, with_hud: bool) -> void:
	var cam := Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	var body: Node3D = player.visual
	cam.global_position = body.global_transform * offset
	cam.look_at(body.global_position + Vector3(0, 1.2, 0), Vector3.UP)
	cam.current = true
	game.hud.visible = with_hud
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	cam.queue_free()
	game.camera.current = true
