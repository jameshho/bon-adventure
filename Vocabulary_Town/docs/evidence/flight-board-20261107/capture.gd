extends SceneTree
## Airport flight game after the board-only redesign (7 Nov 2026): the flight panel at a fixed
## today (Thursday 03/12/2026, 14:30) with Spanish, English and Chinese as the language
## learned: a question, a wrong near-miss tap with "What went wrong?", a weekday question (no
## day column), the summary and browsing. Uses Main, which saves progress and settings: run
## with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=airport godot --path . --resolution 1400x900 --script res://docs/evidence/flight-board-20261107/capture.gd
const GameClock := preload("res://scripts/learning/game_clock.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const FOLDER := "res://docs/evidence/flight-board-20261107/"
func _initialize(): run.call_deferred()

func frame(file: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")

## Asks until the question is of `kind` (and names a country when `country`).
func ask(session, kind: String, country := true) -> void:
	for i in 80:
		if str(session.question.get("kind", "")) == kind and (not country or str(session.question.country) != ""):
			return
		session.next_question()

func play(game, session) -> void:
	session.offered = true
	game.interaction.clerk_activated.emit(session.bruno)
	game.shop_panel.choice_pressed.emit("flight_play")

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	GameClock.shared().set_now({"y": 2026, "m": 3, "d": 12}, 14 * 60 + 30)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await process_frame
	var session = game.get_node("FlightSession")
	session.set_process(false)
	var panel = game.flight_panel
	var box = game.shop_panel
	GameSettings.shared().set_languages("en", "es")
	await play(game, session)
	await ask(session, "clock")
	await frame("es-question")
	var near: Array = session.questions.near_misses(session.question)
	panel.flight_pressed.emit(str(near[0].id))
	panel.why_pressed.emit()
	await frame("es-wrong")
	await ask(session, "weekday")
	await frame("es-weekday")
	panel.flight_pressed.emit(str(session.question.target))
	Board.shared()._done["flight_bruno"] = 4
	panel.next_pressed.emit()
	panel.flight_pressed.emit(session.question.target)
	await frame("es-summary")
	panel.finish_pressed.emit()
	box.dialogue_closed.emit()
	# English learned (Spanish native), then Chinese learned with the translation shown.
	GameSettings.shared().set_languages("es", "en")
	await play(game, session)
	await ask(session, "part")
	await frame("en-question")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	GameSettings.shared().set_languages("en", "zh")
	await play(game, session)
	await ask(session, "hours")
	panel.show_native = true
	panel.refresh_display()
	await frame("zh-question")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	GameSettings.shared().set_languages("en", "es")
	# Browsing outside the game (what E on the board or the booklet prop opens).
	session.quiz = false
	panel.show_native = false
	panel.open(session._panel_data())
	await frame("browse")
	print("FLIGHT BOARD CAPTURE done")
	quit()
