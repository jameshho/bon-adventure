extends SceneTree
## Airport flight game and the HUD's EN (25 Nov 2026, user: "the EN button doesn't work during
## the airport game"). The full-screen flight panel was drawn over EN and swallowed its click,
## and its _input ate L too. Now (flight_panel.gd clear_of, as money_panel.gd):
##   - the card starts below EN and clicks on EN pass through the panel;
##   - a real click on EN shows the native language on the panel, letting go hides it;
##   - holding L does the same;
##   - the board's rows still fit without a scroll bar, and with EN held the calendar's last
##     week stays on screen (flight_panel.gd _fit_calendar()).
## Uses Main, which saves progress and settings: run with an isolated HOME (README). Graphics
## runs only (real clicks); saves en-held.png and es.png next to this script.
## HOME=<scratch>/home VT_FOCUS=airport VT_SPAWN=none godot --path . --audio-driver Dummy --script res://docs/evidence/flight-peek-20261125/verify.gd
const HERE := "res://docs/evidence/flight-peek-20261125/"
const GameSettings := preload("res://scripts/core/game_settings.gd")
var failures := 0
var checks := 0
var game

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(file: String) -> void:
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(HERE + file))

func key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_L
	event.physical_keycode = KEY_L
	event.pressed = pressed
	Input.parse_input_event(event)

func run():
	if DisplayServer.get_name() == "headless":
		print("FLIGHT PEEK: graphics only"); quit(1); return
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await frames(2)
	GameSettings.shared().set_languages("en", "es")
	var session = game.get_node("FlightSession")
	session.set_process(false)
	session.open_game()
	game.sync_minigame_hud()
	await frames(8)
	var panel: Control = game.flight_panel
	var en: Control = game.hud.peek_button
	check(panel.visible and en.is_visible_in_tree(), "the flight panel is open and the HUD's EN shows")
	var card_rect: Rect2 = panel._card.get_global_rect()
	var en_rect: Rect2 = en.get_global_rect()
	check(not card_rect.intersects(en_rect), "the card stays clear of EN (card %s, EN %s)" % [card_rect, en_rect])
	check(not panel._has_point(en_rect.get_center() - panel.global_position) and panel._has_point(card_rect.get_center() - panel.global_position), "clicks on EN pass through the panel, the card still takes its own")
	var scroll: ScrollContainer = panel.find_child("Board scroll", true, false)
	check(panel._board_rows.get_combined_minimum_size().y <= scroll.size.y + 1.0, "the board's rows fit without a scroll bar")
	await shot("es.png")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = en_rect.get_center()
	press.global_position = press.position
	press.pressed = true
	root.push_input(press)
	await frames(3)
	check(GameSettings.shared().peeking and bool(panel.show_native), "pressing EN over the panel shows the native language")
	await frames(4)
	var side: Control = panel._side
	check(side.get_global_rect().end.y <= panel._content.get_global_rect().end.y + 1.0, "with EN held the clock and calendar fit (side bottom %.0f, content bottom %.0f)" % [side.get_global_rect().end.y, panel._content.get_global_rect().end.y])
	await shot("en-held.png")
	var release := press.duplicate()
	release.pressed = false
	root.push_input(release)
	await frames(3)
	check(not GameSettings.shared().peeking and not bool(panel.show_native), "letting go of EN hides it again")
	key(true)
	await frames(3)
	check(GameSettings.shared().peeking and bool(panel.show_native), "holding L over the panel shows the native language")
	key(false)
	await frames(3)
	check(not GameSettings.shared().peeking and not bool(panel.show_native), "letting go of L hides it again")
	print("FLIGHT PEEK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
