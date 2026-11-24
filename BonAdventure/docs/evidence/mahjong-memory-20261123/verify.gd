extends SceneTree
## 23 Nov 2026: Mei's mahjong game remembers an unfinished game (docs/guides/MAHJONG.md#memory).
##   - logic: a hand saved through JSON mid-turn and mid-claim restores to the same state and
##     plays on to the same end as the original;
##   - the table: no save -> Yes asks about lessons; sit down, play some turns, leave -> the
##     profile's mahjong.json holds the mode, the scores and the hand; Yes now asks
##     "carry on?" first (with your points); Yes, continue sits down at the same hand and scores;
##     after a finished hand, continuing deals a new hand with the scores kept; No, a new game
##     goes to the lesson question and starts with no scores.
## With graphics it saves continue-ask.png (the question) and continued.png (the hand back).
## HOME=<scratch> VT_FOCUS=home VT_SPAWN=none godot --headless --path . --script res://docs/evidence/mahjong-memory-20261123/verify.gd
const AI := preload("res://scripts/learning/mahjong_ai.gd")
const Game := preload("res://scripts/learning/mahjong_game.gd")
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const OUT := "res://docs/evidence/mahjong-memory-20261123/"
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
	_check_logic()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	session = game.get_node_or_null("MahjongSession")
	check(session != null and session.table != null, "the mahjong session and table exist")
	if session == null or session.table == null:
		finish()
		return
	var path: String = session._save_path
	check(path.ends_with("mahjong.json") and not FileAccess.file_exists(path), "no saved game at the start (%s)" % path)
	session._host_talk(session.npcs[0])
	session._on_choice("mahjong_yes")
	check(session.host.line_id == "mahjong.lesson_ask", "without a save, Yes asks about lessons")
	session._on_choice("mahjong_know")
	session._on_choice("mahjong_three")
	await _sit()
	check(session.game != null and session._mode == 3, "a 3-fan game started")
	# Some turns, then stop on the player's own turn.
	session.set_process(false)
	var g = session.game
	for i in 2000:
		if g.phase == "over" or (g.turns_played >= 12 and g.phase == "turn" and g.turn == 0):
			break
		_player_move()
		session._process(0.5)
	check(g.phase == "turn" and g.turn == 0, "stopped on the player's turn after %d turns" % g.turns_played)
	session._visit_hands = [{"winner": 0, "from": 2, "fan": 3}]   # one won hand earlier this visit
	var hand_before: Array = g.hands[0].duplicate()
	var state_before := JSON.stringify(g.to_save())
	var points: int = Rules.balances(session._visit_hands)[0]
	session.set_process(true)
	await _leave()
	var saved: Variant = SaveStore.read_json(path)
	check(saved is Dictionary and int(saved.get("mode", -1)) == 3 and saved.get("hands", []).size() == 1 and saved.get("game") is Dictionary,
			"leaving saves the mode, the scores and the hand (%s)" % (str(saved.keys()) if saved is Dictionary else "none"))
	# Talk again: the continue question first.
	session._host_talk(session.npcs[0])
	session._on_choice("mahjong_yes")
	check(session.host.line_id == "mahjong.continue_ask", "with a save, Yes asks to carry on first (%s)" % session.host.line_id)
	var asked: String = str(session.host._line.get("native", "")) + " " + str(session.host._line.get("foreign", ""))
	check(asked.contains(session._signed(points)), "the question shows your points %s (%s)" % [session._signed(points), asked])
	await frames(20)
	await shot("continue-ask.png")
	session._on_choice("mahjong_continue")
	await _sit()
	g = session.game
	check(g != null and session._mode == 3, "continuing sits down in the saved mode")
	check(g != null and g.hands[0] == hand_before and JSON.stringify(g.to_save()) == state_before, "the same hand is back, tile for tile")
	check(session._visit_hands.size() == 1 and game.mahjong_panel.score_button.text == session._signed(points), "the scores are back (star %s)" % game.mahjong_panel.score_button.text)
	await frames(30)
	session.view.finish_slides()
	await frames(5)
	await shot("continued.png")
	# Play the hand to its end; the result is saved without a hand in play.
	session.set_process(false)
	for i in 3000:
		if g.phase == "over":
			break
		_player_move()
		session._process(0.5)
	for i in 10:
		session._process(0.5)
		if game.mahjong_panel.result_card.visible:
			break
	var hands_after: int = session._visit_hands.size()
	saved = SaveStore.read_json(path)
	check(g.phase == "over" and saved is Dictionary and saved.get("game") == null and saved.get("hands", []).size() == hands_after,
			"a finished hand is saved at once: %d won hands, no hand in play" % hands_after)
	session.set_process(true)
	await _leave()
	session._host_talk(session.npcs[0])
	session._on_choice("mahjong_yes")
	check(session.host.line_id == "mahjong.continue_ask", "the scores alone are still offered to carry on")
	session._on_choice("mahjong_continue")
	await _sit()
	check(session.game != null and session.game.phase != "over" and session._visit_hands.size() == hands_after, "continuing after a finished hand deals a new one with the scores kept")
	await _leave()
	# No, a new game.
	session._host_talk(session.npcs[0])
	session._on_choice("mahjong_yes")
	session._on_choice("mahjong_fresh")
	check(session.host.line_id == "mahjong.lesson_ask", "No, a new game goes on to the lesson question")
	session._on_choice("mahjong_know")
	session._on_choice("mahjong_any")
	await _sit()
	check(session.game != null and session._mode == 0 and session._visit_hands.is_empty(), "the new game has the chosen mode and no scores")
	await _leave()
	saved = SaveStore.read_json(path)
	check(saved is Dictionary and int(saved.get("mode", -1)) == 0 and saved.get("hands", []).is_empty(), "the new game replaced the old save")
	finish()

## Save -> JSON -> restore keeps a hand exactly, mid-turn and mid-claim, and both copies play
## on to the same end.
func _check_logic() -> void:
	for target in ["turn", "claim"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2311 if target == "turn" else 1123
		var a := Game.new()
		a.start(rng, 1, 0)
		for i in 400:
			if a.phase == "over" or (a.turns_played >= 20 and a.phase == target and (target == "turn" or a.waiting.size() > 0)):
				break
			_step(a)
		check(a.phase == target, "logic: reached a %s after %d turns" % [target, a.turns_played])
		var b := Game.new()
		var ok := b.restore(JSON.parse_string(JSON.stringify(a.to_save())))
		check(ok and JSON.stringify(b.to_save()) == JSON.stringify(a.to_save()), "logic: the %s restores exactly" % target)
		check(b.waiting.keys() == a.waiting.keys(), "logic: the same seats answer the claim (%s)" % str(b.waiting.keys()))
		for i in 2000:
			if a.phase == "over" and b.phase == "over":
				break
			_step(a)
			_step(b)
		check(a.phase == "over" and str(a.result.get("winner")) == str(b.result.get("winner")) and a.turns_played == b.turns_played,
				"logic: both copies end alike (winner %s, %d turns)" % [a.result.get("winner"), a.turns_played])
	check(not Game.new().restore({"phase": "over"}) and not Game.new().restore({}), "logic: an ended or empty save is not restored")

func _step(g) -> void:
	match str(g.phase):
		"turn":
			var action := AI.turn_action(g, g.turn)
			match str(action.type):
				"win": g.declare_self_win(g.turn)
				"kong": g.declare_kong(g.turn, int(action.tile))
				_: g.discard(g.turn, int(action.tile))
		"claim":
			for seat in g.waiting.keys():
				g.respond(seat, AI.claim_answer(g, seat, g.waiting[seat]))

func _player_move() -> void:
	var g = session.game
	if g.phase == "turn" and g.turn == 0:
		var action := AI.turn_action(g, 0)
		match str(action.type):
			"win": session._on_action("win", -1)
			"kong": session._on_action("kong", int(action.tile))
			_: session._on_tile(int(action.tile))
	elif g.phase == "claim" and g.waiting.has(0):
		var answer := AI.claim_answer(g, 0, g.waiting[0])
		session._on_action(str(answer.type), int(answer.get("tile", g.last_discard)))

func _sit() -> void:
	for i in 600:
		await process_frame
		if session.game != null and not session.zone.fading and session._playing:
			break
	await frames(5)

func _leave() -> void:
	session.set_process(true)
	session._leave("mahjong.left_early")
	for i in 600:
		await process_frame
		if not session._playing and not session.zone.fading:
			break
	await frames(10)
	check(not session._playing and session.game == null, "the player left the table")

func finish() -> void:
	print("MAHJONG MEMORY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
