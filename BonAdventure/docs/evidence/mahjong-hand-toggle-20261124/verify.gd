extends SceneTree
## 24 Nov 2026: the hand bar's hide/show button (docs/guides/MAHJONG.md, "Your turn"): ▾ tucks
## the hand away so the player's own tiles on the table show, ▴ brings it back, and the player's
## next turn brings it back by itself. Updated 24 Nov 2026 (UI polish): the button is now a pull
## tab centred on the tray's top edge that slides the tray (0.22 s) and waits at the bottom edge. Plays until the player has an exposed set (or 30 turns),
## then checks the button and, with graphics, saves hand-shown.png and hand-hidden.png.
## HOME=<scratch> VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/mahjong-hand-toggle-20261124/verify.gd
const AI := preload("res://scripts/learning/mahjong_ai.gd")
const OUT := "res://docs/evidence/mahjong-hand-toggle-20261124/"
var failures := 0
var checks := 0
var game
var session
var graphics := false

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(file: String) -> void:
	if not graphics:
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved " + file)

func run():
	graphics = DisplayServer.get_name() != "headless"
	if not graphics:
		root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	session = game.get_node_or_null("MahjongSession")
	if session == null or session.table == null:
		check(false, "the mahjong session and table exist")
		finish()
		return
	var cycle = game.get("day_night")
	if cycle != null:
		cycle.set_time(720.0)
		cycle.pause()
	session._host_talk(session.npcs[0])
	session._on_choice("mahjong_yes")
	session._on_choice("mahjong_know")
	session._on_choice("mahjong_any")
	for i in 600:
		await process_frame
		if session.game != null and not session.zone.fading and session._playing:
			break
	var panel = game.mahjong_panel
	var g = session.game
	check(g != null and panel.visible, "a game started")
	# Play (the player claims what the NPC logic would) until an exposed set or 30 turns, and stop
	# on another player's turn so the hand is not needed.
	session.set_process(false)
	for i in 3000:
		if g.phase == "over" or (g.turns_played >= 8 and (not g.melds[0].is_empty() or g.turns_played >= 30) and g.phase == "turn" and g.turn != 0):
			break
		_player_move()
		session._process(0.5)
	check(g.phase == "turn" and g.turn != 0, "stopped on another player's turn (turn %d, %d exposed sets)" % [g.turns_played, g.melds[0].size()])
	session.set_process(true)
	await frames(30)
	session.view.finish_slides()
	session.set_process(false)
	await frames(5)
	var toggle: Button = panel.hand_toggle
	check(panel.hand_bar.visible and toggle.visible, "the hand and its ▾ tab show")
	var bar: Rect2 = panel.hand_bar.get_global_rect()
	var at: Rect2 = toggle.get_global_rect()
	check(absf(at.get_center().x - bar.get_center().x) < 2.0 and absf(at.end.y - bar.position.y - 3.0) < 2.0, "▾ is centred on the tray's top edge (%s, bar %s)" % [at, bar])
	check(at.size.x >= 48.0 and at.size.y >= 44.0, "the tab's touch area is finger-sized (%s)" % at.size)
	await shot("hand-shown.png")
	toggle.pressed.emit()
	await create_timer(0.35).timeout
	var screen: Vector2 = panel.get_viewport_rect().size
	at = toggle.get_global_rect()
	check(not panel.hand_bar.visible and toggle.visible and panel.hand_hidden, "▾ slides the hand away")
	check(absf(at.end.y - screen.y) < 1.0 and absf(at.get_center().x - screen.x * 0.5) < 2.0, "▴ waits at the bottom edge, centred (%s)" % at)
	await shot("hand-hidden.png")
	toggle.pressed.emit()
	await create_timer(0.35).timeout
	check(panel.hand_bar.visible and not panel.hand_hidden and absf(panel.hand_bar.get_global_rect().position.y - bar.position.y) < 1.0, "▴ slides the hand back")
	# Tucked away, then the player's turn comes: the hand returns.
	toggle.pressed.emit()
	await create_timer(0.35).timeout
	for i in 2000:
		if g.phase == "over" or (g.phase == "turn" and g.turn == 0):
			break
		if g.phase == "claim" and g.waiting.has(0):
			session._on_action("pass", -1)
		session._process(0.5)
	session._process(0.01)   # the session redraws the panel for the new turn
	await create_timer(0.35).timeout
	check(g.phase == "over" or (panel.hand_bar.visible and not panel.hand_hidden), "the player's turn brings the hand back")
	finish()

func _player_move() -> void:
	var g = session.game
	if g.phase == "turn" and g.turn == 0:
		var action := AI.turn_action(g, 0)
		match str(action.type):
			"kong": session._on_action("kong", int(action.tile))
			"win": session._on_tile(int(g.hands[0].back()))   # no win: keep the hand going
			_: session._on_tile(int(action.tile))
	elif g.phase == "claim" and g.waiting.has(0):
		var answer := AI.claim_answer(g, 0, g.waiting[0])
		var type := str(answer.type)
		if type == "win":
			type = "pass"   # keep the hand going for the views
		session._on_action(type, int(answer.get("tile", g.last_discard)))

func finish() -> void:
	print("MAHJONG HAND TOGGLE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
