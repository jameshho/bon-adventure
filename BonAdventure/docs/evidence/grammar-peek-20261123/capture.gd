extends SceneTree
## Renders of the Grammar Classroom card without its own EN bubble, with and without the HUD's EN
## held (user, 23 Nov 2026). Uses Main, which saves progress: run with an isolated HOME (README),
## windowed, with VT_FOCUS=school:
##   HOME=<scratch>/home VT_FOCUS=school godot --path . --script res://docs/evidence/grammar-peek-20261123/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const OUT := "res://docs/evidence/grammar-peek-20261123/"
var game

func _initialize(): run.call_deferred()

## Holds or lets go of L, as the player would (the HUD ends a peek nobody holds).
func _hold_l(on: bool) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_L
	key.keycode = KEY_L
	key.pressed = on
	Input.parse_input_event(key)
	GameSettings.shared().set_peek(on)

func _shot(title: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + title + ".png")
	print("saved ", title, " peeking=", GameSettings.shared().peeking)

func run():
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30: await process_frame
	var session = game.get_node("GrammarSession")
	GameSettings.shared().set_languages("en", "es")
	for i in 5: await process_frame
	session.offered = true
	await session.start_class()
	session.set_process(false)
	session._process(0.0)   # the player stays at the start, unseated
	await _shot("question")
	_hold_l(true)
	await _shot("question-en-held")
	_hold_l(false)
	session.submit()
	await _shot("feedback")
	_hold_l(true)
	await _shot("feedback-en-held")
	_hold_l(false)
	print("bubble visible: ", session.card.translate_button.visible)
	session.end_class("")
	game.free()
	quit()
