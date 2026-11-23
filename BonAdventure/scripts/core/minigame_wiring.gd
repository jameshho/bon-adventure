extends RefCounted
## Minigame and shop wiring, moved out of main.gd (7 Nov 2026). Main stays the entry point and
## keeps every field other scripts read (shop_panel, money_panel, grammar_card, ...); these
## static functions fill and use them. Adding a minigame: create its panel and session in
## build(), add the panel to PANELS (refresh, Esc and, with `true`, the control lock).
##
## One shared "customer order" panel (the dialogue box) and one session per store in
## data/shops.json; their text comes from the shared Lexicon (data/phrases.json,
## data/words.json).

## Main fields of the minigame panels, in refresh order, with what Esc does on each
## ("close_requested" or "leave_requested", emitted on the panel) and, as a third value,
## `true` when the panel locks the player while visible (PWA phase 5: this flag replaced the
## separate LOCKING list).
const PANELS := [
	["money_panel", "close_requested", true],
	["family_panel", "close_requested", true],
	["flight_panel", "close_requested", true],
	["restaurant_panel", "close_requested", true],
	# The Alta Cocina menu book (the table by the host stand): Esc closes it.
	["restaurant_menu_book", "close_requested", true],
	# The task card stays open during the warehouse game: Esc asks whether to leave.
	["warehouse_card", "leave_requested"],
	["detective_card", "leave_requested", true],
	["grammar_card", "leave_requested"],
	# The Mystery Doors card: Esc asks whether to leave the game.
	["mystery_card", "leave_requested"],
	# The mahjong screen: Esc asks whether to leave the table (docs/guides/MAHJONG.md).
	["mahjong_panel", "leave_requested", true],
	# Mei's mahjong lessons, over the dialogue's place and the mahjong screen: Esc closes them.
	["mahjong_lessons", "close_requested", true],
	# Radar Patrol (pastime, docs/guides/RADAR_PATROL.md): Esc closes the arcade screen.
	["radar_panel", "close_requested", true],
	# Electrical boxes (docs/guides/ELECTRICAL_BOX.md): Esc leaves the close-up early.
	["electrical_box_panel", "close_requested", true],
	# The elevator floor picker (docs/guides/HOSPITAL_THREE_FLOORS.md): Esc closes the panel close-up.
	["elevator_floor_picker", "close_requested", true],
	# The minigame test launcher (debug builds; docs/guides/MINIGAMES.md#test-launcher).
	["game_launcher", "close_requested", true],
	# The Passport (scripts/ui/passport_panel.gd): Esc closes it.
	["passport", "close_requested", true],
	# The results screen after a minigame (docs/guides/MINIGAMES.md#results-screen): Esc continues.
	["results_screen", "close_requested", true],
]
static func build(main) -> void:
	var hud = main.hud
	var shop_dialogue = preload("res://scripts/learning/shop_dialogue.gd").new()
	var shop_panel = preload("res://scripts/ui/shop_order_panel.gd").new()
	main.shop_panel = shop_panel
	shop_panel.walker = main.player
	hud.ui_root.add_child(shop_panel)
	for store_id in shop_dialogue.stores:
		_when(main, store_id, func() -> void:
			var session = preload("res://scripts/learning/shop_session.gd").new()
			main.add_child(session)
			session.setup(store_id, shop_dialogue, shop_panel, main.interaction, main.zones, main.player, main.apartment, main.vocabulary_sold_in))
	# Cashier counters (the till: checkout of the Grocery Run and of free shopping with a basket,
	# 21 Nov 2026): same dialogue box, plus the money screen.
	main.money_panel = preload("res://scripts/ui/money_panel.gd").new()
	hud.ui_root.add_child(main.money_panel)
	main.money_panel.visibility_changed.connect(main.sync_player_controls)
	# The HUD's EN (the one language toggle) stays visible and clickable above the card.
	main.money_panel.clear_of = [hud.peek_button]
	for cashier_id in shop_dialogue.cashiers:
		_when(main, cashier_id, func() -> void:
			var cashier_session = preload("res://scripts/learning/cashier_session.gd").new()
			main.add_child(cashier_session)
			cashier_session.setup(cashier_id, shop_dialogue, shop_panel, main.money_panel, main.interaction, main.zones, main.player, main.apartment, main.vocabulary_sold_in))
	# The bank teller game (bear banker, teller window 2; 18 Nov 2026): same dialogue box and
	# money screen, played behind the bank's teller counter.
	_when(main, "bank", func() -> void:
		var teller_session = preload("res://scripts/learning/teller_session.gd").new()
		main.add_child(teller_session)
		teller_session.setup(shop_dialogue, shop_panel, main.money_panel, main.interaction, main.player, main.apartment, main))
	# Dr. Li's family game (hospital): same dialogue box, plus the family panel.
	main.family_panel = preload("res://scripts/ui/family_panel.gd").new()
	hud.ui_root.add_child(main.family_panel)
	main.family_panel.visibility_changed.connect(main.sync_player_controls)
	_when(main, "hospital", func() -> void:
		var family_session = preload("res://scripts/learning/family_session.gd").new()
		main.add_child(family_session)
		family_session.setup(shop_dialogue.lexicon, shop_panel, main.family_panel, main.interaction, main.player, main.apartment))
	# Ramón's Warehouse Worker game (docs/guides/WAREHOUSE.md): same dialogue box and quit card, plus
	# the task card; the game itself runs in a copy of the warehouse built on demand.
	main.warehouse_card = _under_dialogue(main, preload("res://scripts/ui/warehouse_task_card.gd").new())
	_when(main, "warehouse", func() -> void:
		main.warehouse_session = preload("res://scripts/learning/warehouse_session.gd").new()
		main.add_child(main.warehouse_session)
		main.warehouse_session.setup(shop_dialogue.lexicon, shop_panel, main.warehouse_card, main.interaction, main.player, main.apartment, main))
	# Lana's Grammar Classroom (docs/guides/GRAMMAR_CLASS.md): runs in the real school classroom.
	main.grammar_card = _under_dialogue(main, preload("res://scripts/ui/grammar_card.gd").new())
	_when(main, "school", func() -> void:
		var grammar_session = preload("res://scripts/learning/grammar_session.gd").new()
		main.add_child(grammar_session)
		grammar_session.setup(shop_dialogue.lexicon, shop_panel, main.grammar_card, main.interaction, main.player, main.apartment, main))
	# Madame Luna's Mystery Doors (Mystery House, 9 Nov 2026): runs in the real mystery room;
	# the card sits at the top of the screen.
	main.mystery_card = _under_dialogue(main, preload("res://scripts/ui/mystery_card.gd").new())
	_when(main, "mystery", func() -> void:
		var mystery_session = preload("res://scripts/learning/mystery_session.gd").new()
		main.add_child(mystery_session)
		mystery_session.setup(shop_dialogue.lexicon, shop_panel, main.mystery_card, main.interaction, main.player, main.apartment, main))
	# Rosa's library mission (11 Nov 2026, dialogue only for now): the shared dialogue box.
	_when(main, "library", func() -> void:
		var library_session = preload("res://scripts/learning/library_session.gd").new()
		main.add_child(library_session)
		library_session.setup(shop_dialogue.lexicon, shop_panel, main.interaction, main.player, main.apartment))
	# Captain Bruno's flight game (airport information desk): same dialogue box and quit card,
	# plus the flight panel.
	main.flight_panel = _under_dialogue(main, preload("res://scripts/ui/flight_panel.gd").new())
	main.flight_panel.visibility_changed.connect(main.sync_player_controls)
	_when(main, "airport", func() -> void:
		main.flight_session = preload("res://scripts/learning/flight_session.gd").new()
		main.add_child(main.flight_session)
		main.flight_session.setup(shop_dialogue.lexicon, shop_panel, main.flight_panel, main.interaction, main.player, main.apartment))
	# Twinkle's restaurant game (Alta Cocina host stand): same dialogue box and quit card, plus
	# the order tablet and the menu book on the table by the host stand (11 Nov 2026).
	main.restaurant_panel = _under_dialogue(main, preload("res://scripts/ui/restaurant_panel.gd").new())
	main.restaurant_panel.visibility_changed.connect(main.sync_player_controls)
	main.restaurant_menu_book = _under_dialogue(main, preload("res://scripts/ui/restaurant_menu_book.gd").new())
	main.restaurant_menu_book.visibility_changed.connect(main.sync_player_controls)
	_when(main, "restaurants", func() -> void:
		var restaurant_session = preload("res://scripts/learning/restaurant_session.gd").new()
		main.add_child(restaurant_session)
		restaurant_session.setup(shop_dialogue.lexicon, shop_panel, main.restaurant_panel, main.interaction, main.player, main.apartment, main.restaurant_menu_book))
	# The police detective games (docs/evidence/police-detective-20261106/PROMPT.md): Officer Rocco's
	# lineup and Officer Mimi's evidence table share one card; an open card locks the player
	# (fixed camera).
	main.detective_card = _under_dialogue(main, preload("res://scripts/ui/detective_card.gd").new())
	main.detective_card.visibility_changed.connect(main.sync_player_controls)
	for detective_mode in ["lineup", "evidence"]:
		_when(main, "police", func() -> void:
			var detective_session = preload("res://scripts/learning/police_detective_session.gd").new()
			main.add_child(detective_session)
			detective_session.setup(detective_mode, shop_dialogue.lexicon, shop_panel, main.detective_card, main.interaction, main.player, main.apartment))
	# Mei's Hong Kong mahjong table in front of the home (docs/guides/MAHJONG.md): same dialogue box and
	# quit card, plus the mahjong screen; the tiles load only while the player sits at the table.
	main.mahjong_panel = _under_dialogue(main, preload("res://scripts/ui/mahjong_panel.gd").new())
	main.mahjong_panel.visibility_changed.connect(main.sync_player_controls)
	main.mahjong_lessons = _under_dialogue(main, preload("res://scripts/ui/mahjong_lesson_panel.gd").new())
	main.mahjong_lessons.visibility_changed.connect(main.sync_player_controls)
	_when(main, "home", func() -> void:
		var mahjong_session = preload("res://scripts/learning/mahjong_session.gd").new()
		main.add_child(mahjong_session)
		mahjong_session.setup(shop_dialogue.lexicon, shop_panel, main.mahjong_panel, main.interaction, main.player, main.apartment, main, main.mahjong_lessons))
	# Radar Patrol (docs/guides/RADAR_PATROL.md): a click or E on either control-tower radar opens the
	# arcade screen; no NPC.
	main.radar_panel = preload("res://scripts/ui/radar_patrol_panel.gd").new()
	main.hud.ui_root.add_child(main.radar_panel)
	main.radar_panel.visibility_changed.connect(main.sync_player_controls)
	_when(main, "airport", func() -> void:
		var radar_session = preload("res://scripts/learning/radar_patrol_session.gd").new()
		main.add_child(radar_session)
		radar_session.setup(main.radar_panel, main.apartment, main.hud))
	# Electrical boxes (docs/guides/ELECTRICAL_BOX.md): E near a box or a click on it opens the
	# close-up wire screen; no NPC.
	main.electrical_box_panel = preload("res://scripts/ui/electrical_box_panel.gd").new()
	main.hud.ui_root.add_child(main.electrical_box_panel)
	main.electrical_box_panel.visibility_changed.connect(main.sync_player_controls)
	main.electrical_box_session = preload("res://scripts/learning/electrical_box_session.gd").new()
	main.add_child(main.electrical_box_session)
	main.electrical_box_session.setup(main.electrical_box_panel, main)
	# Elevator floor picker (hospital and control tower): E at a cabin panel zooms onto it.
	main.elevator_floor_picker = preload("res://scripts/ui/elevator_floor_picker.gd").new()
	main.elevator_floor_picker.main = main
	main.hud.ui_root.add_child(main.elevator_floor_picker)
	main.elevator_floor_picker.visibility_changed.connect(main.sync_player_controls)
	# The minigame picker (F9 or its ▶ corner button; a player feature since 10 Nov 2026): starts
	# any game above with a chosen number of rounds.
	main.game_launcher = preload("res://scripts/ui/game_launcher.gd").new()
	main.hud.ui_root.add_child(main.game_launcher)
	main.game_launcher.setup(main)
	# The Passport (missions, town stamps, the achievement log; 21 Nov 2026, docs/guides/ACHIEVEMENTS.md).
	main.passport = preload("res://scripts/ui/passport_panel.gd").new()
	main.hud.ui_root.add_child(main.passport)
	main.passport.setup(main)
	# The stars card at the end of a session of a game with levels (progression, 18 Nov 2026).
	main.star_card = preload("res://scripts/ui/star_card.gd").new()
	main.hud.ui_root.add_child(main.star_card)
	main.star_card.setup()
	# The results screen after a minigame (21 Nov 2026): sessions call show_results().
	main.results_screen = preload("res://scripts/ui/results_screen.gd").new()
	main.hud.ui_root.add_child(main.results_screen)
	main.results_screen.setup()
	main.results_screen.visibility_changed.connect(main.sync_player_controls)
	main.results_flow = preload("res://scripts/learning/results_flow.gd").new()
	main.add_child(main.results_flow)
	main.results_flow.setup(main)
	# The dialogue box reaches over the bottom-right cluster: buttons under it hide (10 Nov 2026).
	main.hud.cluster_cover = func() -> Rect2:
		var card: Control = main.shop_panel.dialogue_card
		return card.get_global_rect() if main.shop_panel.is_dialogue_visible() else Rect2()

## Runs `job` (a minigame's session, which finds its NPC once at setup) now, or when building
## unit `unit` arrives if the app's staged loading has not added it yet (Main.when_unit_loaded,
## 13 Nov 2026). A unit that is not a building unit (or not loading at all) runs it now.
static func _when(main, unit: String, job: Callable) -> void:
	main.when_unit_loaded(unit, job)

## Adds a minigame card under the dialogue box, so its leave question shows on top.
static func _under_dialogue(main, card: Control) -> Control:
	main.hud.ui_root.add_child(card)
	main.hud.ui_root.move_child(card, main.shop_panel.get_index())
	return card

## Esc on the dialogue box, the cart, the quit card and every minigame panel
## (scripts/ui/popup_stack.gd).
static func watch_popups(main, popups) -> void:
	var shop_panel = main.shop_panel
	popups.watch(shop_panel.dialogue_card, func() -> void: shop_panel.dialogue_closed.emit())
	popups.watch(shop_panel.cart_card, func() -> void: shop_panel.quit_requested.emit())
	popups.watch(shop_panel.quit_card, shop_panel.hide_quit)
	for spec in PANELS:
		var panel: Control = main.get(spec[0])
		var request: String = spec[1]
		popups.watch(panel, func() -> void: panel.emit_signal(request))

## Re-renders every minigame text (the Display Mode or a language changed).
static func refresh_display(main) -> void:
	main.shop_panel.refresh_display()
	for spec in PANELS:
		main.get(spec[0]).refresh_display()

## True while a minigame panel that locks the player is open.
static func locks_player(main) -> bool:
	for spec in PANELS:
		var panel = main.get(spec[0])
		if spec.size() > 2 and spec[2] and panel != null and panel.visible:
			return true
	return false
