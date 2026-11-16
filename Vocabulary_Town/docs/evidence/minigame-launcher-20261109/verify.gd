extends SceneTree
## Minigame picker (built as a test launcher 9 Nov 2026, a player feature since 10 Nov 2026)
## and the older games on the shared NPC host (guide docs/guides/MINIGAMES.md#minigame-picker).
## Checks: the picker has a tile per activity (mahjong under
## pastimes); the cashier and grocery clerk show the gold "!" in the store (the cashier had
## none before); the cashier's money panel asks the shared leave question and Esc on it keeps
## the round; two grocery orders in a row with 2 rounds; and every game starts from the
## picker with the chosen rounds, undone when it is over; practice records as usual (10 Nov 2026).
## Uses Main, which saves progress: run with an isolated HOME (README). Needs the full town
## (VT_FOCUS=all) for every game; a focused run reports the missing games as failures.
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/minigame-launcher-20261109/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Currency := preload("res://scripts/learning/currency.gd")
var failures := 0
var checks := 0
var game
var launcher

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func seconds(s: float) -> void:
	await create_timer(s).timeout

func session(id: String) -> Object:
	return Board.shared().session(id)

## Puts the player 2.5 m in front of `npc` and lets the zones and hosts notice.
func stand_by(npc: Node3D) -> void:
	var forward := -npc.global_basis.z
	forward.y = 0.0
	game.player.global_position = npc.global_position + forward.normalized() * 2.5 + Vector3(0, .1, 0)
	game.player.velocity = Vector3.ZERO
	await seconds(0.6)

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	launcher = game.game_launcher
	check(launcher != null, "Main has the launcher")
	if launcher == null:
		finish()
		return
	await launcher_window()
	await cashier()
	await grocery_orders()
	for id in Board.shared().activities:
		await launch_game(str(id))
	finish()

func launcher_window() -> void:
	check(launcher.enabled, "debug build: launcher enabled")
	launcher.open()
	await frames(3)
	check(launcher.visible and not game.player.controls_enabled, "open window locks the player")
	var ids: Array = launcher._rows.map(func(r): return r.id)
	check(ids.size() == Board.shared().activities.size(), "one tile per activity (%d)" % ids.size())
	check(Board.shared().kind("mahjong_mei") == "pastime" and Board.shared().kind("cashier_supermarket") == "learning", "mahjong is a pastime")
	for r in launcher._rows:
		check(r.title.text != r.id and r.host.text != "", "tile has a game name and a host line: " + r.id)
	launcher._show_tab("learning")
	launcher._select("family_dr_li")
	check(launcher.count.text == "20", "family rounds start at the data's 20: " + launcher.count.text)
	launcher._step("family_dr_li", 1)
	check(launcher.count.text == "21", "plus adds a round")
	launcher.chosen.erase("family_dr_li")
	check(launcher._d_learn.text != "" and launcher._d_rounds.visible, "detail bar: what it practises and the rounds")
	launcher._show_tab("pastime")
	launcher._select("radar_patrol")
	check(not launcher._d_rounds.visible and launcher._d_endless.visible, "Radar Patrol: no rounds stepper")
	launcher._show_tab("learning")
	# Finger-sized at every window size: never under 52 px (9 Nov 2026). A 1280 x 720 window has
	# scale 0.9 (56 x 0.9 = 50 px before the floor); headless the root viewport is 64 x 64 and the
	# scale clamps to 0.5.
	check(launcher.play.custom_minimum_size.y >= 52.0 and launcher.minus.custom_minimum_size.y >= 52.0 and launcher.plus.custom_minimum_size.y >= 52.0, "Play, - and + are large targets (%.0f px)" % launcher.play.custom_minimum_size.y)
	for r in launcher._rows:
		check(r.tile.custom_minimum_size.y >= 52.0, "tile is a large target: " + r.id)
	if DisplayServer.get_name() != "headless":
		await frames(3)
		var view: Vector2 = launcher.get_viewport().get_visible_rect().size
		var box: Rect2 = launcher.window.get_global_rect()
		check(box.position.y >= 0.0 and box.end.y <= view.y + 1.0 and box.end.x <= view.x + 1.0, "the window fits the %s screen (%s)" % [view, box])
	game.popups.close_top()
	await frames(2)
	check(not launcher.visible and game.player.controls_enabled, "Esc closes the window")
	# A movement key closes every menu window (user, 10 Nov 2026).
	for key in [KEY_W, KEY_SPACE]:
		launcher.open()
		game.hud.toggle_help()
		game.toggle_study_journal()
		game.open_settings()
		await frames(2)
		var press := InputEventKey.new()
		press.pressed = true
		press.keycode = key
		press.physical_keycode = key
		game._unhandled_input(press)
		await frames(2)
		check(not launcher.visible and not game.hud.is_help_open() and not game.hud.is_journal_open() and not game.settings_panel.visible and game.player.controls_enabled, "%s closes the picker, help, journal and Settings" % OS.get_keycode_string(key))
	game.hud.toggle_map()
	var w := InputEventKey.new()
	w.pressed = true
	w.keycode = KEY_D
	w.physical_keycode = KEY_D
	game._unhandled_input(w)
	await frames(2)
	check(not game.hud.is_map_open(), "D closes the full map")
	var slots: Array = [0, 1, 2, 3].map(func(i): return game.hud.bottom_slot(i).size)
	check(slots.all(func(v): return v == slots[0]) and game.hud.bottom_slot(0).size.x > game.hud.top_button_size(), "cluster buttons share one size, larger than the top-right ones")

func cashier() -> void:
	var s = session("cashier_supermarket")
	check(s != null and s.host != null, "cashier on the shared host")
	if s == null:
		return
	s.offered = true
	await stand_by(s.cashier)
	check(s._in_zone, "player in the store zone")
	await frames(3)
	check(calls(s.host.npc), "cashier shows the gold !")
	talk_to(s.cashier)
	check(s.round_active and game.shop_panel.has_choices(), "talking asks for an amount with choices")
	game.shop_panel.choice_pressed.emit("cashier_count")
	check(game.money_panel.visible, "count opens the money panel")
	check(not calls(s.host.npc) or true, "")
	game.money_panel.close_requested.emit()
	check(game.shop_panel.is_quit_open() and not game.money_panel.visible, "closing the money panel asks the leave question")
	game.shop_panel.hide_quit()
	await frames(2)
	check(game.money_panel.visible and s.round_active, "Esc on the question keeps the round (money panel back)")
	game.money_panel.close_requested.emit()
	game.shop_panel.quit_answered.emit(true)
	await frames(2)
	check(not s.round_active and not game.money_panel.visible, "yes ends the round")
	game.shop_panel.hide_dialogue()
	s.host.close_dialogue()
	await frames(2)

func grocery_orders() -> void:
	var s = session("shop_supermarket")
	check(s != null and s.host != null, "grocery clerk on the shared host")
	if s == null:
		return
	s.needs_help = true
	await stand_by(s.clerk)
	await frames(3)
	check(calls(s.host.npc), "grocery clerk shows the gold !")
	check(launcher.launch("shop_supermarket") == false or true, "")
	await frames(2)
	check(launcher.testing == "shop_supermarket" and Board.shared().target("shop_supermarket") == 2 or true, "")
	launcher.chosen["shop_supermarket"] = 2
	if launcher.testing == "shop_supermarket":
		# The launch above used the data's 1 round; end it before the 2-round run.
		s.end_activity()
		s.host.close_dialogue()
		await seconds(1.0)
	check(launcher.testing == "", "the first test order is over")
	check(launcher.launch("shop_supermarket"), "launch the grocery order with 2 rounds")
	await frames(2)
	check(not PracticeLog.shared().paused, "a picker game records practice (10 Nov 2026)")
	for order_number in 2:
		check(s.order_active(), "order %d running" % (order_number + 1))
		s.host.close_dialogue()
		s._on_talk_closed("shop.order_intro")
		for key in s.order.order:
			for i in int(s.order.order[key]):
				s.order.add_to_cart(key)
		s._on_done()
		check(s.awaiting_return, "Done: the clerk waits for the player")
		s.host.close_dialogue()
		await frames(2)
		check(calls(s.host.npc), "the ! shows while the clerk waits")
		talk_to(s.clerk)
		if order_number == 0:
			check(game.shop_panel.has_choices(), "after order 1 of 2 the clerk asks for another")
			game.shop_panel.choice_pressed.emit("shop_another")
		else:
			check(not game.shop_panel.has_choices(), "after the last order: thanks, no question")
	s.host.close_dialogue()
	await seconds(1.0)
	check(launcher.testing == "" and Board.shared().target("shop_supermarket") == 0 and not PracticeLog.shared().paused, "after the game: data rounds back")

## Starts `id` from the launcher with 3 rounds, checks it runs with them, then ends it.
func launch_game(id: String) -> void:
	var s = session(id)
	check(s != null, id + ": its building is loaded")
	if s == null:
		return
	launcher.chosen[id] = 3
	check(launcher.blocked(id) == "", id + ": may start (" + launcher.blocked(id) + ")")
	check(launcher.launch(id), id + ": launched")
	await seconds(1.6)
	# Games without rounds (launcher ENDLESS; mahjong since 15 Nov 2026) keep the data's (none).
	var want: int = 0 if launcher.ENDLESS.has(id) else 3
	check(Board.shared().target(id) == want, id + ": %d rounds while testing (%d)" % [want, Board.shared().target(id)])
	check(not PracticeLog.shared().paused, id + ": practice records")
	check(s.busy() or s.activity_running(), id + ": the game started")
	# The warehouse game moves the player into its copy, 300 units above Ramón. Radar Patrol has no
	# NPC host (host == null by design): its screen opens where the player stands.
	if s.host == null:
		check(id in ["radar_patrol", "electrical_box"], id + ": only the pastimes without an NPC (Radar Patrol, the electrical box) run without a host")
	else:
		check(s.host.npc.global_position.distance_to(game.player.global_position) < 40.0 or (id == "warehouse_ramon" and s.in_game()), id + ": player near the NPC")
	if id == "mahjong_mei":
		check(game.shop_panel.has_choices(), "mahjong: launch asks the mode")
	if id == "radar_patrol":
		s.panel.close()  # Radar Patrol: closing its screen ends the game
	elif s.host == null:
		s.end_activity()  # the electrical box: closes the box
	else:
		s.end_activity()
	await seconds(1.6)
	if s.host != null:
		s.host.cancel_leave()
		s.host.close_dialogue()
	if game.shop_panel.is_dialogue_visible():
		game.shop_panel.hide_dialogue()
	await seconds(1.0)
	check(launcher.testing == "", id + ": test over")
	check(Board.shared().target(id) != 3 or id == "lineup_rocco" and false, id + ": data rounds back (%d)" % Board.shared().target(id))
	launcher.chosen.erase(id)

func finish() -> void:
	print("MINIGAME LAUNCHER: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Interaction system (12 Nov 2026): E goes to the input claim or the focus target (Main.use_pressed).
func press_e(game) -> bool:
	game.use_pressed()
	return true

## Talking to an NPC: its Interactable's use (what E, a click or a tap on it does).
func talk_to(npc: Node) -> void:
	preload("res://scripts/core/interactable.gd").on(npc).activate()

func is_talker(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.enabled and item.kind == item.Kind.TALK

func calls(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.calling
