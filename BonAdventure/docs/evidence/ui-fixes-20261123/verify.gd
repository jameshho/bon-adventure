extends SceneTree
## UI fixes of 23 Nov 2026 (user items 14, 19, 20, 21), through Main and the real sessions:
##   14  the supermarket door's "pay first" line closes DOOR_LINE_LINGER s after the player steps
##       back from the door (cashier_session.gd door guard "asking"/"cancel"), and stays while
##       they stand in the door;
##   A   the checkout's money panel leaves the HUD's EN visible and clickable (money_panel.gd
##       clear_of; a real click on EN in graphics runs);
##   B   after paying, walking out of the store's zone before the clerk has the basket puts the
##       player back and asks the leave question; No keeps the order, Yes ends it (shop_session.gd);
##   19  Mahjong: holding EN (GameSettings.peeking) shows only the native text (no " / ") and no
##       button or card changes size (mahjong_panel.gd _text/_hold_width);
##   20  Mei's lesson card hides the HUD's journal and ▶ buttons (vocabulary_hud.gd cluster_hidden
##       follows hide_for_game);
##   21  Mystery Doors: a player who falls out of the endless hall is put back on its floor and
##       the game goes on; a player moved out of the house mid-game (Main's fall respawn at the
##       supermarket) ends the game, its card and hall (mystery_session.gd _guard_place).
## Uses Main, which saves progress: run with an isolated HOME (README). Graphics runs save
## screenshots next to this script.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/ui-fixes-20261123/verify.gd
const HERE := "res://docs/evidence/ui-fixes-20261123/"
const Mystery := preload("res://scripts/buildings/mystery.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Cashier := preload("res://scripts/learning/cashier_session.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const SHOP := "shop_supermarket"
## World metres (grocery-checkout-20261121/verify.gd): inside the store and outside its door.
const INSIDE := Vector3(-175.6, 0.1, 163.8)
const OUTSIDE := Vector3(-168.0, 0.1, 163.8)
var failures := 0
var checks := 0
var game

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func finish() -> void:
	print("UI FIXES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func seconds(s: float) -> void:
	await create_timer(s).timeout

func graphics() -> bool:
	return DisplayServer.get_name() != "headless"

func shot(file: String) -> void:
	if not graphics():
		return
	await frames(6)
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(HERE + file))
	print("saved " + file)

func place(at: Vector3) -> void:
	game.player.global_position = at
	game.player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func run():
	if graphics():
		root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	await seconds(1.0)
	await mystery()
	await shop_door()
	await lesson_hud()
	await mahjong()
	finish()

# --- 21 Mystery Doors -------------------------------------------------------------------------

func mystery() -> void:
	var session = game.get_node_or_null("MysterySession")
	var house: Node3D = ModularTown.building(game.apartment, "mystery")
	check(session != null and house != null and session.host != null, "mystery: the session and house are loaded")
	if session == null or house == null or session.host == null:
		return
	Board.shared().set_rounds(session.ACTIVITY, 3)
	session.zone.place_player(house, Vector3(0, Mystery.FLOOR, Mystery.DOOR_WALL - 2.5), Mystery.START_LOOK)
	await physics_frame
	session.start_game()
	await frames(2)
	check(session.in_game() and session.card.visible, "mystery: a game runs with its card")
	# The first right door swaps the player into the endless hall.
	var target: int = session.rounds[0].target
	session.doors[target].leaf.use()
	await frames(3)
	check(session.state == "walk" and session.hall.visible, "mystery: in the hall after the first right door (%s)" % session.state)
	var floor_y: float = house.to_global(Vector3(0, Mystery.ENDLESS_FLOOR, 0)).y
	var rescue_y: float = house.to_global(Vector3(0, Mystery.ENDLESS_FLOOR - session.FALL_DEPTH, 0)).y
	check(rescue_y - game.FALL_RESPAWN_Y > 8.0, "mystery: the hall floor (world %.1f) and its fall rescue (%.1f) are well above Main's respawn line (%.1f)" % [floor_y, rescue_y, game.FALL_RESPAWN_Y])
	# A fall through the hall floor: put back on it before Main's respawn.
	game.player.global_position = house.to_global(Vector3(3.0, Mystery.ENDLESS_FLOOR - 2.0, -6.0))
	game.player.velocity = Vector3(0, -8, 0)
	await frames(3)
	await physics_frame
	var p: Vector3 = house.to_local(game.player.global_position)
	check(p.y > Mystery.ENDLESS_FLOOR - 0.5 and absf(p.z + 6.0) < 1.6 and session.in_game() and session.card.visible,
			"mystery: a fall out of the hall lands back on its floor, the game goes on (local %s, %s)" % [p, session.state])
	# Moved out of the house mid-game (Main's fall respawn at the supermarket): the game ends.
	await place(game.spawn_position())
	await seconds(0.9)
	check(not session.in_game() and not session.card.visible and not session.hall.visible and Board.shared().blocker("") == "",
			"mystery: out of the house mid-game the game, its card and the hall end (state '%s', card %s)" % [session.state, session.card.visible])
	await shot("mystery-ended-outside.png")

# --- 14 The supermarket door ------------------------------------------------------------------

func shop_door() -> void:
	var shop = Board.shared().session(SHOP)
	var till = game.get_node_or_null("CashierSession_supermarket")
	check(shop != null and till != null and till.door != null, "shop: the clerk, the till and its door are loaded")
	if shop == null or till == null or till.door == null:
		return
	Progress.shared()._store(SHOP, {"level": 1, "unlocked": 1})
	await place(OUTSIDE)
	shop.start_game()
	await frames(2)
	var key: String = str(shop.order.order.keys()[0])
	shop.order.cart = {}
	shop.order.add_to_cart(key)
	game.shop_panel.update_cart(shop._cart_data())
	shop.host.close_dialogue()
	await place(INSIDE)
	await frames(3)
	check(till.door.blocks(), "shop: the door holds back the unpaid basket")
	# Into the question zone just inside the wall.
	await place(till.door.zone.global_position - Vector3(0, till.door.zone.get_child(0).shape.size.y * 0.5 - 0.1, 0))
	await frames(4)
	check(till.host.line_id == "cashier.pay_first" and game.shop_panel.is_dialogue_visible(), "shop: at the door with a full basket: pay first (%s)" % till.host.line_id)
	await seconds(3.0)
	check(till.host.line_id == "cashier.pay_first" and game.shop_panel.is_dialogue_visible(), "shop: standing in the door keeps the line")
	await shot("shop-pay-first.png")
	await place(INSIDE)
	await seconds(0.6)
	check(game.shop_panel.is_dialogue_visible(), "shop: stepping back: the line stays a moment")
	await seconds(Cashier.DOOR_LINE_LINGER + 0.4)
	check(till.host.line_id == "" and not game.shop_panel.is_dialogue_visible(), "shop: %.1f s after stepping back the line is gone" % Cashier.DOOR_LINE_LINGER)
	await shot("shop-pay-first-gone.png")
	# Asked again on the next approach.
	await place(till.door.zone.global_position - Vector3(0, till.door.zone.get_child(0).shape.size.y * 0.5 - 0.1, 0))
	await frames(4)
	check(till.host.line_id == "cashier.pay_first", "shop: walking back to the door asks again")
	till.host.close_dialogue()
	await pay_and_leave(shop, till)
	for running in [shop, till]:
		if running.has_method("end_activity"):
			running.end_activity()
	await place(OUTSIDE)
	await frames(3)

## A (23 Nov 2026): the money panel leaves the HUD's EN visible and clickable. B: after paying,
## walking out of the store's zone before the clerk has the basket asks the leave question.
func pay_and_leave(shop, till) -> void:
	await place(INSIDE)
	shop.order.cart = {}
	for key in shop.order.order:
		for i in int(shop.order.order[key]):
			shop.order.add_to_cart(key)
	var cashier: Node3D = till.cashier
	var front: Vector3 = cashier.global_position - cashier.global_basis.z * 2.0
	await place(Vector3(front.x, 0.1, front.z))
	till._talk()
	await frames(2)
	till._on_choice(till.host.choice_prefix() + "count")
	await frames(4)
	var money: Control = game.money_panel
	var en: Control = game.hud.peek_button
	check(money.visible and en.is_visible_in_tree(), "money: the panel is open and the HUD's EN shows")
	var card_rect: Rect2 = money._card.get_global_rect()
	var en_rect: Rect2 = en.get_global_rect()
	check(not card_rect.intersects(en_rect), "money: the card stays clear of EN (card %s, EN %s)" % [card_rect, en_rect])
	await frames(4)
	check(not graphics() or money._card.get_global_rect().end.y <= root.get_visible_rect().size.y + 1.0, "money: the lowered card fits on the screen (bottom %.0f)" % money._card.get_global_rect().end.y)
	check(not money._has_point(en_rect.get_center() - money.global_position) and money._has_point(card_rect.get_center() - money.global_position), "money: clicks on EN pass through the panel, the card still takes its own")
	if graphics():
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.position = en_rect.get_center()
		press.global_position = press.position
		press.pressed = true
		root.push_input(press)
		await frames(3)
		check(GameSettings.shared().peeking and bool(money.show_native), "money: pressing EN over the panel shows the native language")
		await frames(4)
		check(money._card.get_global_rect().end.y <= root.get_visible_rect().size.y + 1.0, "money: with the translation shown the card still fits (bottom %.0f)" % money._card.get_global_rect().end.y)
		await shot("money-en-held.png")
		var release := press.duplicate()
		release.pressed = false
		root.push_input(release)
		await frames(3)
		check(not GameSettings.shared().peeking, "money: letting go of EN ends the peek")
	await shot("money-panel.png")
	var total: int = till.due_cents
	money.counts = {"coin_1": total}
	till._on_submitted(total)
	await frames(3)
	check(shop.awaiting_return, "paid: the order waits for the clerk")
	till.host.close_dialogue()
	# Out of the zone before the clerk has the basket: back in, and the leave question.
	var away := Vector3.ZERO
	for d in range(10, 90, 4):
		for dir in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			var spot: Vector3 = OUTSIDE + dir * d
			if away == Vector3.ZERO and game.zones.resolve_global(spot) != shop.store_zone:
				away = spot
	await place(OUTSIDE)
	await seconds(0.8)
	game.player.global_position = away
	await seconds(0.8)
	check(shop.host.is_asking_leave() and game.shop_panel.is_quit_open() and game.zones.resolve_global(game.player.global_position) == shop.store_zone and not game.player.controls_enabled,
			"paid, walking off: back in the zone and asked whether to leave (%s)" % game.zones.resolve_global(game.player.global_position))
	await shot("paid-leave-question.png")
	shop.host._on_quit_answered(false)
	await frames(3)
	check(shop.awaiting_return and Basket.carried(game.player) != null and game.player.controls_enabled, "No: the order goes on, the basket stays, the player can move")
	game.player.global_position = away
	await seconds(0.8)
	check(shop.host.is_asking_leave(), "walking off again asks again")
	shop.host._on_quit_answered(true)
	await frames(3)
	check(not shop.awaiting_return and Basket.carried(game.player) == null and Board.shared().blocker("") == "", "Yes: the order ends, the clerk's goodbye, the basket goes back")

# --- 20 The lesson card and the HUD's buttons -------------------------------------------------

func lesson_hud() -> void:
	var hud = game.hud
	check(not hud.cluster_hidden(hud.bookmark_button), "hud: the journal button shows in the town")
	# As mahjong_session.gd _open_lessons() before a game.
	hud.hide_for_game(true)
	game.mahjong_lessons.open(0)
	await frames(4)
	check(hud.cluster_hidden(hud.bookmark_button) and not hud.bookmark_button.visible, "hud: the journal button hides under Mei's lesson card")
	var launcher_button: Button = game.game_launcher.corner_button if game.game_launcher != null else null
	check(launcher_button == null or not launcher_button.is_visible_in_tree(), "hud: the ▶ games button hides under Mei's lesson card")
	await shot("lesson-no-hud-buttons.png")
	game.mahjong_lessons.close()
	hud.hide_for_game(false)
	await frames(4)
	check(hud.bookmark_button.visible, "hud: the journal button is back once the lesson closes")

# --- 19 Mahjong: EN changes words, not sizes -------------------------------------------------

func mahjong() -> void:
	var settings = GameSettings.shared()
	settings.set_languages("en", "zh")
	settings.set_display(GameSettings.FOREIGN)
	await frames(3)
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	var panel = game.mahjong_panel
	panel.open()
	panel.set_info([lexicon.line("mahjong.status_three"), lexicon.line("mahjong.seat_wind", {"wind": {"phrase": "mahjong.wind_s"}})], [-1, 28])
	panel.set_hand([0, 4, 7, 9, 11, 14, 15, 17, 18, 21, 24, 25, 28], 1, true)
	panel.set_actions([
		{"id": "pung", "label": lexicon.line("mahjong.btn_pung"), "data": 4, "tiles": [4, 4, 4]},
		{"id": "pass", "label": lexicon.line("mahjong.btn_pass")}])
	await frames(6)
	var before := sizes(panel)
	await shot("mahjong-foreign.png")
	# Held: the HUD ends a peek whose key or button is up, so it is paused meanwhile.
	game.hud.set_process(false)
	settings.set_peek(true)
	await frames(6)
	var after := sizes(panel)
	await shot("mahjong-en-held.png")
	check(before == after, "mahjong: holding EN changes no size\n  before %s\n  after  %s" % [before, after])
	var texts: Array = []
	for label in panel.find_children("*", "Label", true, false):
		if label.is_visible_in_tree() and label.text != "":
			texts.append(label.text)
	for button in panel.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text != "":
			texts.append(button.text)
	var mixed: Array = texts.filter(func(t: String) -> bool: return t.contains(" / "))
	check(not texts.is_empty() and mixed.is_empty(), "mahjong: with EN held only the native text shows (%s)" % [texts])
	var native_pass := str(lexicon.line("mahjong.btn_pass").native)
	check(texts.has(native_pass), "mahjong: the Pass button reads '%s' (%s)" % [native_pass, texts])
	settings.set_peek(false)
	game.hud.set_process(true)
	await frames(6)
	check(sizes(panel) == before, "mahjong: letting go of EN changes no size either")
	panel.hide_panel()

## Every visible button's and card's on-screen size in the panel (rounded).
func sizes(panel: Control) -> Array:
	var out: Array = []
	for node in panel.find_children("*", "Control", true, false):
		if (node is Button or node is PanelContainer) and node.is_visible_in_tree():
			var rect: Rect2 = node.get_global_rect()
			out.append("%s %dx%d" % [node.get_class(), roundi(rect.size.x), roundi(rect.size.y)])
	return out
