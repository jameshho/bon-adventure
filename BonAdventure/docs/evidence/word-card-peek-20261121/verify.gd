extends SceneTree
## The word card without its own translate bubble (user, 21 Nov 2026): the card's top-left EN
## bubble is gone and holding the HUD's top-right peek badge (GameSettings.set_peek, as the badge
## and L do; here a real mouse press on the badge) adds the native word under the foreign one while the card is open.
## Main saves settings and study progress: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --fixed-fps 60 --script res://docs/evidence/word-card-peek-20261121/verify.gd
## With VT_SHOTS=<folder> it also saves the card before and during the peek.
## Prints "WORD CARD PEEK: N checks, M failures".
const GameSettings := preload("res://scripts/core/game_settings.gd")

var checks := 0
var failures := 0
var main

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func shot(name: String) -> void:
	var folder := OS.get_environment("VT_SHOTS")
	if folder == "" or DisplayServer.get_name() == "headless":
		return
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

## Presses (or releases) the left mouse button on the peek badge, as a player holding it.
func hold_badge(hud, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = hud.peek_button.get_global_rect().get_center()
	event.global_position = event.position
	root.push_input(event)
	await frames(2)

func run() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280, 720))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	var settings = GameSettings.shared()
	var hud = main.hud
	settings.set_display(GameSettings.FOREIGN)
	await frames(2)
	check(settings.display == GameSettings.FOREIGN, "the card is checked in Foreign mode")
	check(hud.ui_root.find_child("Card translate", true, false) == null, "the card has no translate bubble of its own")
	hud.show_card("", "", "Kitchen & Dining", "spoon")
	await frames(3)
	var foreign: String = hud.primary_label.text
	check(foreign != "" and hud.secondary_label.text == "", "the card shows only the foreign word (\"%s\")" % foreign)
	check(hud.peek_button.visible, "the top-right peek badge shows while the card is open")
	await shot("card")
	await hold_badge(hud, true)
	check(settings.peeking, "pressing the badge starts the peek")
	check(hud.primary_label.text == foreign and hud.secondary_label.text != "", "holding the badge adds the native word (\"%s\")" % hud.secondary_label.text)
	await shot("card-peek")
	await hold_badge(hud, false)
	check(hud.secondary_label.text == "", "releasing it hides the native word again")
	hud.hide_card()
	await hold_badge(hud, true)
	hud.show_card("", "", "Kitchen & Dining", "spoon")
	await frames(2)
	check(hud.secondary_label.text != "", "a card opened during a peek shows the native word")
	await hold_badge(hud, false)
	hud.hide_card()
	print("WORD CARD PEEK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
