extends SceneTree
## Views of the welcome tutorial's control steps (16 Nov 2026, user; scripts/learning/tutorial.gd
## "view" / "move" waits, scripts/ui/tutorial_cue.gd, touch_controls.gd highlight_stick()):
## BonBon's line and the pulsing control, with the keyboard and the touch wording, in a laptop
## window (1280 × 800) and a phone in landscape (844 × 390). Graphics only (no --headless).
## Writes profile saves: isolated HOME, refuses to run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/tutorial-controls-20261116/capture.gd
## Saves view-keys-1280.png, view-touch-1280.png, view-touch-844.png, view-keys-844.png,
## move-touch-844.png, move-keys-844.png, move-keys-1280.png, move-touch-1280.png here.
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Tutorial := preload("res://scripts/learning/tutorial.gd")
const SHOTS := "res://docs/evidence/tutorial-controls-20261116/"

var app: Node
var main: Node
var tutorial: Node
var touch: Node

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(title: String) -> void:
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + title + ".png"))
	print("shot ", title, " ", root.get_texture().get_size())

func size(width: int, height: int) -> void:
	DisplayServer.window_set_size(Vector2i(width, height))
	await frames(10)

func set_touch(on: bool) -> void:
	touch.touch_mode = on
	main.hud.set_touch_mode(on)
	await frames(3)

func until_step(kind: String) -> void:
	var waited := 0
	while str(tutorial.step.get("for", "")) != kind and waited < 3000:
		await process_frame
		waited += 1

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json") or FileAccess.file_exists(GameSettings.PATH):
		print("CAPTURE: refusing to run, saves exist (use an isolated HOME)")
		quit(1)
		return
	await size(1280, 800)
	var id: String = ProfileManager.shared().create("Ana", "Ana", "bonbon")
	preload("res://scripts/core/app.gd")._skip_splash = true
	app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await frames(3)
	app.start_town(id)
	var ticks := 0
	while app.main == null or app.loading != null or app.main.process_mode == Node.PROCESS_MODE_DISABLED:
		await process_frame
		ticks += 1
		if ticks % 600 == 0:
			print("loading... main=%s loading=%s" % [app.main != null, app.loading != null])
	print("town ready")
	main = app.main
	tutorial = main.get_node("Tutorial")
	touch = main.hud.ui_root.get_node("TouchControls")
	var waited := 0
	while not main.shop_panel.has_choices() and waited < 2000:
		await process_frame
		waited += 1
	main.shop_panel.choice_pressed.emit(Tutorial.NEXT)
	await until_step("stand")
	var tries := 0
	while main.player.seated and tries < 600:
		main.seating.stand()
		await process_frame
		tries += 1
	await until_step("view")
	print("view step: ", tutorial.step)
	await frames(60)
	await shot("view-keys-1280")
	await set_touch(true)
	await shot("view-touch-1280")
	await size(844, 390)
	await shot("view-touch-844")
	await set_touch(false)
	await shot("view-keys-844")
	main.player.look_by(Vector2(400, 0))
	await until_step("move")
	await frames(30)
	await shot("move-keys-844")
	await set_touch(true)
	await shot("move-touch-844")
	await size(1280, 800)
	await shot("move-touch-1280")
	await set_touch(false)
	await shot("move-keys-1280")
	print("CAPTURE: done")
	quit(0)
