extends SceneTree
## 9 Nov 2026: the mahjong table in the town (docs/guides/MAHJONG.md). Loads Main, then:
##   - the table in front of the home: four chairs (word chair), four seated plush players, Mei
##     (seat 0) is the talker; the preset game in progress lies on the table (all 136 tiles);
##   - Mei's greeting -> Yes -> the mode question -> "3 fan": the fade, Mei standing, the player
##     seated in her chair with the game camera, 136 tiles, the panel open and the player locked;
##   - whole hands played through the session with the NPC logic standing in for the player's
##     clicks (tiles conserved on the table, the result card at the end), Play again, then the
##     any-fan mode;
##   - Leave: the player stands, Mei sits again, the camera and panel are gone and the preset
##     game is back on the table.
## With graphics it also saves views to this folder (approach, preset, sitting, game, slide,
## call: the first call word popping up, result, scoreboard).
## HOME=<scratch> VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/mahjong-20261109/play.gd
const AI := preload("res://scripts/learning/mahjong_ai.gd")
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const OUT := "res://docs/evidence/mahjong-20261109/"
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
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved " + file)

func run():
	graphics = DisplayServer.get_name() != "headless"
	# A headless run has a 64 x 64 screen, where no panel can fit: give the layout checks a
	# laptop-sized one (13 Nov 2026; "the scoreboard fits on screen" failed on this alone).
	if not graphics:
		root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	session = game.get_node_or_null("MahjongSession")
	# Views at noon, the brightest light (user, 9 Nov 2026: tiles too bright in the midday sun).
	var cycle = game.get("day_night")
	if cycle != null:
		cycle.set_time(720.0)
		cycle.pause()
	check(session != null and session.table != null, "the mahjong session and table exist")
	if session == null or session.table == null:
		finish()
		return
	var chairs := 0
	for chair in session.chairs:
		if chair != null and str(chair.get_meta("word_key", "")) == "chair":
			chairs += 1
	check(chairs == 4, "four chairs with word chair (%d)" % chairs)
	for seat in 4:
		var npc: Node3D = session.npcs[seat]
		check(npc != null and npc.is_in_group("figures"), "player %d seated" % seat)
	check(preload("res://scripts/core/interactable.gd").on(session.npcs[0]) != null, "Mei is the talker")
	check(session.game == null and session.view != null and _shown_tiles() == 136, "the preset game in progress on the table, all 136 tiles (%d)" % _shown_tiles())
	var batched: int = session.view.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.has_meta("render_batched")).size()
	check(batched == 0, "no tile is copied into the town's static render batches (%d)" % batched)
	# The approach view: the player a few steps north of the table, looking at it.
	var table: Node3D = session.table
	game.player.global_position = table.to_global(Vector3(0.9, 0.15, 5.6))
	var toward: Vector3 = table.global_position - game.player.global_position
	game.player.rotation.y = atan2(-toward.x, -toward.z)
	game.player.camera_yaw = game.player.rotation.y
	game.player.camera_pitch = -0.28
	game.player.reset_camera()
	await frames(20)
	await shot("approach.png")
	# The preset game from the game camera's place, before anyone sits.
	var look := Camera3D.new()
	look.fov = session.CAMERA_FOV
	session.add_child(look)
	look.global_transform = Transform3D.IDENTITY.looking_at(table.to_global(session.CAMERA_LOOK) - table.to_global(session.CAMERA_AT), Vector3.UP)
	look.global_position = table.to_global(session.CAMERA_AT)
	look.make_current()
	await frames(10)
	await shot("preset.png")
	look.queue_free()
	game.player.reset_camera()
	var player_camera = game.player.get("camera")
	if player_camera is Camera3D:
		player_camera.make_current()
	# Greeting, Yes, mode.
	session._host_talk(session.npcs[0])
	check(session.host.line_id == "mahjong.greeting", "Mei greets the player")
	session._on_choice("mahjong_yes")
	check(session.host.line_id == "mahjong.lesson_ask", "Mei asks whether the player knows how to play")
	await frames(20)
	await shot("ask.png")
	session._on_choice("mahjong_teach")
	check(session.host.line_id == "mahjong.lesson_which", "No: Mei asks which lesson")
	await frames(20)
	await shot("ask-which.png")
	await _check_lessons()
	session._on_choice("mahjong_know")
	check(session.host.line_id == "mahjong.choose_mode", "Mei asks the mode")
	await frames(20)
	await shot("mode.png")
	session._on_choice("mahjong_three")
	# In the town before the fade: Mei has stepped aside and the player sits in her chair.
	for i in 300:
		await process_frame
		if game.player.seated and not game.player.sit_transition:
			break
	await frames(5)
	check(session.camera == null and session.mei_standing != null and game.player.seated, "Mei gets up and the player sits down before the fade")
	await shot("sitting.png")
	for i in 300:
		await process_frame
		if session.game != null and not session.zone.fading:
			break
	check(session.game != null and session._mode == 3, "a 3-fan game started")
	await frames(30)
	check(game.player.seated and game.seating.current.get("node") == session.chairs[0], "the player sits in Mei's chair")
	check(not session.npcs[0].visible and session.mei_standing != null, "Mei stands beside the table")
	check(root.get_viewport().get_camera_3d() == session.camera, "the game camera is current")
	if cycle != null:
		check(cycle.sun_step_minutes > 20.0 and cycle.sun_slide_seconds > 0.0, "the sun steps rarely and slides while seated (%.1f game minutes)" % cycle.sun_step_minutes)
	check(session.view != null and session.view.get_child_count() >= 136, "136 tiles built")
	check(game.mahjong_panel.visible and not game.player.controls_enabled, "panel open, player locked")
	# 10 Nov 2026 (user): no journal / map / games / help buttons at the table.
	await frames(2)
	var hud = game.hud
	check(hud.cluster_off and not hud.bookmark_button.visible and not hud.map_button.visible and not hud.help_button.visible \
			and not game.game_launcher.corner_button.visible, "the bottom-right buttons are hidden at the table")
	# Signs of life (plush_life.gd): a blink and a head tilt, each back to rest afterwards.
	var life = session.life
	check(life != null and life.figures.size() == 4, "the four players have PlushLife")
	if life != null:
		var awoo: Node3D = session.npcs[2]
		var bao: Node3D = session.npcs[1]
		var eye: MeshInstance3D = bao.get_node("Head/LeftEye")
		check(not eye.has_meta("render_batched") and not awoo.get_node("Head/LeftEye").has_meta("render_batched"), "the players' eyes are not merged into static batches")
		life.blink(bao)
		await frames(2)
		check(life.eyes_shut(bao), "a player blinks")
		# Whole-body gestures since 13 Nov 2026 (the "Head" node is only the face).
		var head: Node3D = awoo
		var rest: Vector3 = head.rotation
		life.gesture(awoo, "tilt")
		await create_timer(0.3).timeout
		check(life.moving(awoo) and absf(head.rotation.z - rest.z) > 0.05, "a player leans to one side")
		await shot("lively.png")
		await create_timer(1.2).timeout
		check(not life.moving(awoo) and head.rotation.is_equal_approx(rest) and not life.eyes_shut(bao), "the tilt and blink end at rest")
		var gap: float = life._next_gesture - life._time
		check(gap > 0.0 and gap <= life.GESTURE_GAP.y, "the next move is %.1f s away (only now and then)" % gap)
	# The book button opens the lessons over the table; the game waits until they close.
	game.mahjong_panel.lessons_button.pressed.emit()
	await frames(20)
	check(game.mahjong_lessons.visible, "the book button opens the lessons in the game")
	await shot("lesson-in-game.png")
	session._wait = 0.5
	var turns_before: int = session.game.turns_played
	session._process(1.0)
	check(is_equal_approx(session._wait, 0.5) and session.game.turns_played == turns_before, "the game waits while the lessons are open")
	game.mahjong_lessons.close_requested.emit()
	await frames(3)
	check(not game.mahjong_lessons.visible and session._playing and session.host.line_id != "mahjong.lesson_ask", "closing them goes back to the game")
	session.set_process(false)
	var shot_taken := false
	var call_shot := false
	for mode in [3, 0]:
		if mode == 0:
			session._mode = 0
			session._on_again()
		for hand in 2:
			if hand == 1:
				session._on_again()
			var guard := 0
			while session.game.phase != "over" and guard < 3000:
				guard += 1
				_player_move()
				session._process(0.5)
				if graphics and not call_shot and session._call_words.any(func(w): return w != null and w.visible):
					call_shot = true
					session.view.finish_slides()
					await frames(20)
					await shot("call.png")
				if not shot_taken and session.game.turns_played >= 22 and session.game.phase == "turn" and session.game.turn == 0:
					shot_taken = true
					session.set_process(true)
					session.view.finish_slides()
					await frames(5)
					await shot("game.png")
					# Real time for a moment: the player's discard and the next turns slide.
					var most := 0
					var mid_shot := false
					_player_move()
					for f in 150:
						await process_frame
						most = maxi(most, session.view._slides.size())
						if not mid_shot and session.view._slides.size() > 0:
							mid_shot = true
							await frames(8)
							await shot("slide.png")
						if session.game.phase == "over" or (session.game.turn == 0 and session.game.phase == "turn"):
							break
					check(most > 0, "tiles slide between places in real time (%d at once)" % most)
					session.set_process(false)
					session.view.finish_slides()
			# The winning call's word shows first; the result card follows after the call pause.
			for i in 10:
				session._process(0.5)
				if game.mahjong_panel.result_card.visible:
					break
			session.view.finish_slides()
			_check_meld_sides()
			check(session.game.phase == "over", "mode %d hand %d ends" % [mode, hand])
			check(game.mahjong_panel.result_card.visible, "result card shown")
			var shown := _shown_tiles()
			var wall: int = session.game.wall_left()
			check(shown == 136, "mode %d hand %d: all 136 tiles on the table at the end (%d, wall %d)" % [mode, hand, shown, wall])
			var result: Dictionary = session.game.result
			print("mode %d hand %d: winner %s, fan %s, %d turns" % [mode, hand, result.get("winner"), result.get("score", {}).get("fan", "-"), session.game.turns_played])
			if mode == 0 and hand == 1:
				session.set_process(true)
				await frames(5)
				await shot("result.png")
				session.set_process(false)
	# The visit's scoreboard (10 Nov 2026): kept over Play again, zero-sum, on the result card.
	var won: int = session._visit_hands.size()
	var totals: Array = Rules.balances(session._visit_hands)
	print("visit points after 4 hands (%d won): %s" % [won, totals])
	check(totals.reduce(func(a, b): return a + b, 0) == 0, "the visit's points add up to zero (%s)" % str(totals))
	var board_labels: Array = game.mahjong_panel.result_stack.find_children("*", "Label", true, false).map(func(l): return l.text)
	check(board_labels.has(session._signed(int(totals[3]))), "the result card shows each player's points (%s)" % str(board_labels))
	# The scoreboard button and card, and the table-centre counter (10 Nov 2026).
	var panel = game.mahjong_panel
	session._update_scores()
	# The ★ card stays shut while the result card shows (it has its own scoreboard), so close the
	# result first, as Play again does.
	panel.result_card.visible = false
	check(panel.score_button.text == session._signed(int(totals[0])), "the star button shows your points (%s)" % panel.score_button.text)
	panel.score_button.pressed.emit()
	await frames(2)
	var score_text: Array = panel.score_stack.find_children("*", "Label", true, false).map(func(l): return l.text)
	check(panel.score_card.visible and score_text.has(session._signed(int(totals[3]))), "the scoreboard opens with every player's points (%s)" % str(score_text))
	check(Rect2(Vector2.ZERO, panel.get_viewport_rect().size).encloses(Rect2(panel.score_card.position, panel.score_card.size)), "the scoreboard fits on screen (card %s %s, info card %s %s, screen %s)" % [panel.score_card.position, panel.score_card.size, panel.info_card.position, panel.info_card.size, panel.get_viewport_rect().size])
	if graphics:
		session.set_process(true)
		await frames(5)
		await shot("scoreboard.png")
		session.set_process(false)
	panel.score_button.pressed.emit()
	check(not panel.score_card.visible, "the star button closes it again")
	var counter = session.view._counter
	check(counter != null and counter.visible and session.view._counter_number.text == str(session.game.wall_left()), "the table-centre counter shows the tiles left")
	await _check_play_ahead()
	await _check_win_offer()
	var words := 0
	for seat in 4:
		var word = session._call_words[seat]
		if word != null:
			words += 1
			var local: Vector3 = word.position
			check(word.get_parent() == session.view and absf(local.x) < 0.9 and absf(local.z) < 0.9 and local.y > 1.0, "seat %d's call word pops up over the table (%s)" % [seat, local])
	print("call words shown at %d seats" % words)
	session.set_process(true)
	session._on_leave_requested()
	for i in 300:
		await process_frame
		if not session._playing and not session.zone.fading:
			break
	await frames(40)
	check(not session._playing and session.game == null and session.camera == null, "leaving frees the game")
	check(session.view != null and _shown_tiles() == 136, "the preset game is back on the table")
	check(not game.player.seated, "the player stands up")
	if cycle != null:
		check(is_equal_approx(cycle.sun_step_minutes, cycle.SUN_STEP_MINUTES) and cycle.sun_slide_seconds == 0.0, "leaving restores the normal sun steps")
	check(session.npcs[0].visible and session.mei_standing == null, "Mei sits down again")
	check(not game.mahjong_panel.visible and game.player.controls_enabled, "panel closed, player free")
	check(session._visit_hands.is_empty() and not game.hud.cluster_off, "leaving clears the visit's points and brings the buttons back")
	check(not session.view._counter.visible, "the counter is gone with the preset game")
	finish()

## Every seat's exposed sets lie on its left, starting at the far left, and its concealed
## hand on its right (user, 9 Nov 2026). Four sets can reach past the middle of the row, so the
## check is that every set tile lies left of every concealed tile of the same seat.
var _meld_checked := false
## The lessons (docs/guides/MAHJONG.md#lessons): both lessons page by page (a view of each), the
## points rule (discarder pays double, 1-fan minimum), the worked examples' fan by the real
## scoring, Chinese with pinyin, closing brings Mei's question back.
func _check_lessons() -> void:
	var lessons = game.mahjong_lessons
	var Rules = load("res://scripts/learning/mahjong_rules.gd")
	check(lessons != null and session.lessons == lessons, "the lesson panel is wired")
	if lessons == null:
		return
	check(lessons.points_for(0) == 2 and lessons.points_for(3) == 8 and lessons.points_for(10) == 128 and lessons.points_for(13) == 128, "points table, 0 fan pays as 1 fan")
	var hands: Array = [{"winner": 1, "from": 3, "fan": 3}, {"winner": 2, "from": -1, "fan": 4}]
	check(lessons.balances(hands) == [-16, 0, 48, -32], "balances after the example hands (%s)" % str(lessons.balances(hands)))
	check(lessons.balances([{"winner": 0, "from": -1, "fan": 0}]) == [6, -2, -2, -2] and lessons.balances([{"winner": 0, "from": 1, "fan": 0}]) == [4, -4, 0, 0], "smallest wins pay 6 self-drawn and 4 on a discard")
	for example in lessons._lessons[1].pages[1].picture.examples:
		var tiles: Array = []
		for group in example.groups:
			tiles.append_array(group)
		var context: Dictionary = example.context
		var scored: Dictionary = Rules.score(tiles.map(func(k): return int(k)), [], {"seat_wind": int(context.seat_wind), "prevailing": int(context.prevailing), "self_drawn": bool(context.self_drawn)})
		var expected := 0
		for part in example.parts:
			expected += int(Rules.config().fan[str(part.fan)])
		check(scored.complete and int(scored.fan) == expected, "worked example scores %d fan as taught (%s)" % [expected, str(scored.get("fan"))])
	session._on_choice("mahjong_basics")
	await frames(5)
	check(lessons.visible and lessons.lesson == 0 and lessons.page == 0 and not session.host.owns_dialogue(), "Teach me the basics opens lesson 1")
	check(not game.player.controls_enabled, "the player is locked while the lessons are open")
	for lesson in 2:
		for page in 3:
			lessons.lesson = lesson
			lessons.page = page
			lessons.refresh_display()
			await frames(25)
			await shot("lesson-%d-%d.png" % [lesson + 1, page + 1])
	# Translated by holding EN (here its key, L: the HUD's EN badge and L are one hold-to-peek;
	# the one language toggle, 23 Nov 2026): the lesson panel has no EN bubble of its own.
	check(not lessons.translate_button.visible, "the lessons show no EN bubble of their own")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_L
	key.keycode = KEY_L
	key.pressed = true
	Input.parse_input_event(key)
	await frames(25)
	check(lessons.show_native, "holding EN shows the lessons in the native language")
	await shot("lesson-translated.png")
	var up := key.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await frames(5)
	check(not lessons.show_native, "letting go of EN shows the language being learned again")
	var settings = load("res://scripts/core/game_settings.gd").shared()
	var was: Array = [settings.native, settings.foreign]
	settings.set_languages("en", "zh")
	for page in [[0, 2], [1, 2]]:
		lessons.lesson = page[0]
		lessons.page = page[1]
		lessons.refresh_display()
		await frames(25)
		await shot("lesson-zh-%d-%d.png" % [page[0] + 1, page[1] + 1])
	settings.set_languages(was[0], was[1])
	await frames(5)
	# Next on the last page says Got it! and closes; Mei asks again.
	lessons.lesson = 1
	lessons.page = 2
	lessons.refresh_display()
	lessons._turn(1)
	await frames(5)
	check(not lessons.visible and session.host.line_id == "mahjong.lesson_more", "closing the lessons: Mei asks for another lesson or to play")

func _check_meld_sides() -> void:
	if _meld_checked:
		return
	var view = session.view
	var hand_left := [INF, INF, INF, INF]
	var melds := []
	for index in view._info.size():
		var key := str(view._info[index].get("key", ""))
		if key.length() < 2 or not key[0] in ["h", "m"]:
			continue
		var seat := int(key.substr(1, 1))
		var along: float = view._tiles[index].position.dot(view.right_of(seat))
		if key[0] == "h":
			hand_left[seat] = minf(hand_left[seat], along)
		else:
			melds.append([key, seat, along])
	for meld in melds:
		_meld_checked = true
		check(meld[2] < hand_left[meld[1]] and (not str(meld[0]).ends_with("_0_0") or meld[2] < -0.6), "exposed set tile %s lies left of seat %d's hand, the first at the far left (%.2f)" % meld)

## The player's own win (user, 9 Nov 2026): a staged legal deal where the player has just drawn
## a winning tile (the wall is the rest of the 136). The big Mahjong! button shows; Keep playing
## hides it and the turn goes on; staged again, Mahjong! wins and the result card follows.
const STAGED := {"dealer": 0, "turn": 0, "drawn": 13, "melds": [[], [], [], []], "discards": [[], [], [], []],
	"hands": [[0, 1, 2, 9, 10, 11, 13, 13, 18, 19, 20, 27, 27, 27], [3, 4, 5, 6, 7, 8, 12, 14, 15, 16, 17, 21, 22],
		[23, 24, 25, 26, 28, 28, 29, 29, 30, 30, 31, 31, 32], [3, 4, 5, 6, 7, 8, 12, 14, 15, 16, 17, 21, 22]]}

func _stage_win() -> void:
	session._on_again()
	var g = session.game
	g.load_preset(STAGED)
	session._fresh = true
	g.changed.emit()
	session._process(0.0)

func _check_win_offer() -> void:
	var p = game.mahjong_panel
	_stage_win()
	var g = session.game
	check(g.can_self_win(0) and p.win_offer.visible, "a winning draw shows the big Mahjong! button")
	check(session.panel.get("message_label") == null, "no message line over the table")
	session._on_action("keep", -1)
	session._process(0.0)
	check(not p.win_offer.visible and g.phase == "turn" and g.turn == 0 and g.can_self_win(0), "Keep playing hides the offer; the player's turn goes on")
	session._on_tile(AI.choose_discard(g, 0))
	check(g.turn != 0 or g.phase != "turn", "the player discards and play moves on")
	_stage_win()
	session._on_action("win", -1)
	for i in 10:
		session._process(0.5)
		if p.result_card.visible:
			break
	check(session.game.phase == "over" and int(session.game.result.winner) == 0 and p.result_card.visible, "pressing Mahjong! wins the hand")
	session.view.finish_slides()
	if graphics:
		_stage_win()
		session.set_process(true)
		await frames(10)
		await shot("offer.png")
		session.set_process(false)
		session._on_action("win", -1)   # end the staged hand: leaving then needs no question
		for i in 10:
			session._process(0.5)
			if p.result_card.visible:
				break

func _shown_tiles() -> int:
	var shown := 0
	if session.view != null:
		for tile in session.view.get_children():
			if tile is Node3D and str(tile.name).begins_with("Tile") and tile.visible:
				shown += 1
	return shown

## The player's move, chosen by the NPC logic, through the panel's signals.
## Playing ahead (user, 9 Nov 2026): during another player's turn a double-click on a hand tile
## marks it (one click does nothing); on the player's next turn it is played automatically
## unless a Mahjong! or Kong button shows. Uses real clicks on the tile buttons.
func _click(tile: Control) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	tile._gui_input(press)

func _check_play_ahead() -> void:
	var p = game.mahjong_panel
	session._on_again()
	var g = session.game
	for i in 400:
		if g.phase == "turn" and g.turn != 0:
			break
		_player_move()
		session._process(0.5)
	check(g.phase == "turn" and g.turn != 0, "another player's turn to mark a tile on")
	session._process(0.0)   # the panel shows this hand (a new deal is drawn on the next frame)
	var slot: Control = p._slots[0]
	var kind: int = slot.kind
	_click(slot)
	check(session._queued == -1, "one click during another player's turn marks nothing")
	_click(slot)
	check(session._queued == kind and slot.queued, "a double-click marks the tile to play ahead")
	if graphics:
		await frames(5)
		await shot("play-ahead.png")
	_click(slot)
	_click(slot)
	check(session._queued == -1 and not slot.queued, "a second double-click unmarks it")
	_click(slot)
	_click(slot)
	var discarded_before: int = g.discards[0].size()
	var waited := false
	for i in 400:
		if g.phase == "over" or (g.phase == "turn" and g.turn == 0 and session._auto_tile() < 0 and session._queued >= 0):
			waited = g.phase != "over"
			break
		if g.discards[0].size() > discarded_before or session._queued < 0:
			break
		if g.phase == "claim" and g.waiting.has(0):
			session._on_action("pass", -1)
		session._process(0.5)
	if waited:
		check(g.discards[0].size() == discarded_before, "with Mahjong! or Kong to choose, the marked tile waits for the player")
	elif g.phase != "over":
		check(g.discards[0].size() == discarded_before + 1 and g.discards[0][-1] == kind and session._queued == -1, "on the player's turn the marked tile is played automatically")
	# After the player's own discard a quick second click is not a double-click.
	for i in 400:
		if g.phase == "over" or (g.phase == "turn" and g.turn == 0):
			break
		if g.phase == "claim" and g.waiting.has(0):
			session._on_action("pass", -1)
		session._process(0.5)
	if g.phase == "turn" and g.turn == 0 and session._auto_tile() < 0:
		var mine: Control = p._slots[0]
		_click(mine)
		session._process(0.0)   # the panel redraws: it is no longer the player's turn
		_click(mine)
		check(session._queued == -1, "clicking twice to discard on the player's own turn marks nothing")
	session.view.finish_slides()

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

func finish() -> void:
	print("MAHJONG TABLE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
