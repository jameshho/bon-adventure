extends SceneTree
## UI-07 (25 Nov 2026): views of the welcome tutorial's act marker ("Part n of 3", beside Skip)
## and Skip's confirm card (Stay green left, Skip coral right) at 1280x800 and 844x390 (a phone
## held sideways). Needs graphics (no --headless). Writes a profile: isolated HOME, refuses to
## run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/tutorial-progress-20261125/render.gd
## Prints "TUTORIAL PROGRESS VIEWS: N saved".
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const SHOTS := "res://docs/evidence/tutorial-progress-20261125/"
const SIZES := [Vector2i(1280, 800), Vector2i(844, 390)]

var saved := 0
var app: Node
var main: Node
var tutorial: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func wait_until(test: Callable, seconds := 20.0) -> bool:
	var ends := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not test.call() and Time.get_ticks_msec() < ends:
		await process_frame
	return test.call()

func shot(title: String) -> void:
	await frames(12)
	var done := [false]
	RenderingServer.frame_post_draw.connect(func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	await wait_until(func() -> bool: return done[0], 5.0)
	if done[0]:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + title + ".png"))
		saved += 1
		print("shot " + title)
	else:
		print("NOT DRAWN: " + title)

func views(act_name: String) -> void:
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await frames(6)
		await wait_until(func() -> bool: return tutorial._skip_button.visible, 30.0)
		await shot("%s-progress-%dx%d" % [act_name, size.x, size.y])
		tutorial._skip_button.pressed.emit()
		await shot("%s-skip-confirm-%dx%d" % [act_name, size.x, size.y])
		main.shop_panel.quit_no.pressed.emit()
		await frames(2)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json") or FileAccess.file_exists(GameSettings.PATH):
		print("TUTORIAL PROGRESS VIEWS: refusing to run, saves exist (use an isolated HOME)")
		quit(1)
		return
	var id: String = ProfileManager.shared().create("Ana", "Ana", "sunny")
	preload("res://scripts/core/app.gd")._skip_splash = true
	app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await frames(3)
	app.start_town(id)
	while app.main == null or app.loading != null or app.main.process_mode == Node.PROCESS_MODE_DISABLED:
		await process_frame
	main = app.main
	tutorial = main.get_node_or_null("Tutorial")
	if tutorial != null:
		# The good-morning line (it waits for "Yes!"), act 1.
		await wait_until(func() -> bool: return main.shop_panel.has_choices(), 30.0)
		# The loading screen fades out over the first line.
		await create_timer(4.0).timeout
		await views("act1")
		# Act 3 from its checkpoint: the marker says "Part 3 of 3".
		tutorial.start(2)
		await wait_until(func() -> bool: return tutorial.act == 2 and main.shop_panel.is_dialogue_visible(), 60.0)
		await views("act3")
		tutorial.skip()
		await wait_until(func() -> bool: return not tutorial.running, 10.0)
	SaveStore.remove_tree("user://profiles")
	print("TUTORIAL PROGRESS VIEWS: %d saved" % saved)
	quit(0)
