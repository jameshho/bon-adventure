extends SceneTree
## Game exits and touch Jump (25 Nov 2026; improvement plan C2 GAME-01/02/03/04 and C8 P3-04):
## - Library Helper: walking out of the library mid-game puts the player back inside facing Rosa
##   and asks the shared leave question; "stay" keeps the game; Esc / back asks too
##   (request_leave()); "yes" ends it and the HUD comes back; with no game Esc opens Settings.
## - Grocery Run: request_leave() asks while an order runs, false when none.
## - Feeding Time!: walking out of the zoo puts the player back inside and asks; stay keeps them
##   in; Esc asks; yes stops (GAME-03, request_leave).
## - Radar console and electrical box: "finish the other task first" while another game runs.
## - The other in-world games (wave 2b, 25 Nov 2026): On the Menu, Next, Please!, Stack & Pack,
##   Desk Dash and Mystery Doors: request_leave() is false with no game; mid-game it asks the
##   leave question and Esc asks it instead of opening Settings; stay keeps the game, yes ends it.
##   Next, Please!: getting up from window 2's chair mid-game sits the player back down and asks.
## - The "jump" action (Space or the touch Jump button) stands the player up from a seat.
## HOME=<scratch> VT_FOCUS=all VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/game-exits-20261125/verify.gd
## Headless: checks only. With graphics it writes leave-question.png here. Saves go to the
## isolated HOME only.
const OUT := "res://docs/evidence/game-exits-20261125"
const Board := preload("res://scripts/learning/activity_board.gd")
var checks := 0
var failures := 0
var game
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	var player = game.player
	player.set_physics_process(false)
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var session = game.get_node_or_null("LibrarySession")
	check(session != null and session.host != null, "library session found")
	if session == null or session.host == null:
		return finish()
	var host = session.host
	var panel = host.dialogue_panel
	var lexicon = host.lexicon
	for id in ["leave_confirm", "leave_yes", "leave_no"]:
		var phrase: Dictionary = lexicon.phrases.get("library." + id, {})
		check(phrase.has("es") and phrase.has("en") and phrase.has("zh"), "phrase library.%s in es/en/zh" % id)
	# --- the game, with the player standing inside the library
	host.launch()
	host.close_dialogue()
	var inside: Vector3 = player.global_position
	check(game.zones.resolve_global(inside) == "library", "the player starts the game inside the library (%s)" % game.zones.resolve_global(inside))
	await create_timer(1.0).timeout
	check(session.playing and game.hud.in_minigame, "the game runs and the HUD is in game mode")
	# --- walking out: back inside, the leave question
	var outside := _outside(host.npc.global_position)
	check(outside != Vector3.INF, "a point outside the library zone found")
	player.global_position = outside
	await create_timer(.6).timeout
	check(host.is_asking_leave() and panel.is_quit_open(), "walking out asks the leave question")
	check(game.zones.resolve_global(player.global_position) == "library", "the player is put back inside the library")
	check(not player.controls_enabled, "the player stands still while asked")
	if graphics:
		await shot("leave-question")
	# Stay
	panel.quit_answered.emit(false)
	await frames(3)
	check(session.playing and not host.is_asking_leave() and not panel.is_quit_open(), "stay keeps the game going")
	check(game.zones.resolve_global(player.global_position) == "library" and player.controls_enabled, "after stay the player is inside and can move")
	# --- Esc / back mid-game asks too (no popup open)
	host.close_dialogue()
	await frames(2)
	_back()
	await frames(2)
	check(host.is_asking_leave() and not game.settings_panel.visible, "Esc mid-game asks the leave question, not Settings")
	# Yes: the game ends, the HUD and word cards come back
	panel.quit_answered.emit(true)
	await frames(4)
	check(not session.playing and session.books.is_empty() and host.line_id == "library.stopped", "yes ends the game with Rosa's thanks anyway")
	check(not game.hud.in_minigame and Board.shared().blocker("") == "", "yes restores the HUD (no game running)")
	host.close_dialogue()
	await frames(2)
	# --- no game: Esc opens Settings
	check(not session.request_leave(), "request_leave() is false with no game")
	_back()
	await frames(2)
	check(game.settings_panel.visible, "with no game Esc opens Settings")
	game.settings_panel.close()
	await frames(2)
	# --- GAME-04: radar console and electrical box say "finish first" while a game runs
	var radar := Node3D.new()
	radar.set_script(load("res://scripts/objects/radar_console.gd"))
	root.add_child(radar)
	var box: Node3D = load("res://scenes/props/electrical_box.tscn").instantiate()
	root.add_child(box)
	await frames(1)
	check(radar.can_interact() == true and box.can_interact() == true, "radar and box are usable with no game")
	host.launch()
	host.close_dialogue()
	check(radar.can_interact() == "common.finish_first" and box.can_interact() == "common.finish_first", "radar and box say finish first during Library Helper")
	session._stop()
	host.close_dialogue()
	radar.queue_free()
	box.queue_free()
	# --- Grocery Run: request_leave() during an order
	var shop = game.get_node_or_null("ShopSession_supermarket")
	if shop != null:
		check(not shop.request_leave(), "shop: request_leave() is false with no order")
		shop.start_game()
		await frames(2)
		check(shop.request_leave() and shop.host.is_asking_leave(), "shop: request_leave() asks during an order")
		panel.quit_answered.emit(false)
		await frames(2)
		check(shop.activity_running(), "shop: stay keeps the order")
		shop.abort()
		await frames(2)
	else:
		check(false, "supermarket shop session (VT_FOCUS needs supermarket)")
	# --- Feeding Time! (GAME-03 and request_leave, 25 Nov 2026): walking out of the zoo puts the
	# player back inside and asks; stay keeps them in; Esc asks; yes stops the game.
	var zoo = game.get_node_or_null("ZooFeedingSession")
	check(zoo != null and zoo.host != null, "Feeding Time! session found")
	if zoo != null and zoo.host != null:
		check(not zoo.request_leave(), "zoo: request_leave() is false with no game")
		zoo.host.launch()
		zoo.host.close_dialogue()
		check(zoo.playing and game.zones.resolve_global(player.global_position) == "zoo", "zoo: the game runs with the player in the zoo (%s)" % game.zones.resolve_global(player.global_position))
		await create_timer(1.0).timeout
		var out := Vector3.INF
		for r in range(4, 120, 2):
			for i in 24:
				var p: Vector3 = zoo.keeper.global_position + Vector3(cos(i * TAU / 24.0), 0, sin(i * TAU / 24.0)) * float(r)
				if out == Vector3.INF and game.zones.resolve_global(p) != "zoo":
					out = p
		player.global_position = out
		await create_timer(.6).timeout
		check(zoo.host.is_asking_leave() and game.zones.resolve_global(player.global_position) == "zoo" and not player.controls_enabled, "zoo: walking out puts the player back inside and asks")
		panel.quit_answered.emit(false)
		await frames(3)
		check(zoo.playing and game.zones.resolve_global(player.global_position) == "zoo" and player.controls_enabled, "zoo: stay keeps the game and the player inside")
		zoo.host.close_dialogue()
		await frames(2)
		_back()
		await frames(2)
		check(zoo.host.is_asking_leave() and not game.settings_panel.visible, "zoo: Esc mid-game asks the leave question")
		panel.quit_answered.emit(true)
		await frames(3)
		check(not zoo.playing, "zoo: yes stops the game")
		zoo.host.close_dialogue()
		await frames(2)
	# --- The other in-world games (wave 2b, 25 Nov 2026)
	player.set_physics_process(true)
	for spec in [["On the Menu", "RestaurantSession", "restaurant_twinkle"], ["Next, Please!", "TellerSession", "teller_bank"],
			["Stack & Pack", "WarehouseSession", "warehouse_ramon"], ["Desk Dash", "GrammarSession", "grammar_lana"],
			["Mystery Doors", "MysterySession", "mystery_luna"]]:
		await _leave_game(spec[0], spec[1], spec[2])
	# --- C8: the jump action stands the player up from a seat
	var seat: Dictionary = game.seating.nearest_seat_to(host.npc.global_position)
	check(not seat.is_empty(), "a seat in the library")
	if not seat.is_empty():
		player.set_physics_process(true)
		game.seating.sit_at(seat.node, seat.node.to_local(seat.point + seat.forward * .8))
		await create_timer(2.0).timeout
		check(player.seated and not player.sit_transition, "seated")
		var jump := InputEventAction.new()
		jump.action = "jump"
		jump.pressed = true
		game.seating._unhandled_input(jump)
		await create_timer(1.5).timeout
		check(not player.seated, "the jump action (touch Jump) stands the player up")
		game.seating.sit_at(seat.node, seat.node.to_local(seat.point + seat.forward * .8))
		await create_timer(2.0).timeout
		var space := InputEventKey.new()
		space.keycode = KEY_SPACE
		space.pressed = true
		game.seating._unhandled_input(space)
		await create_timer(1.5).timeout
		check(not player.seated, "Space still stands the player up")
	finish()

## request_leave() and Esc on an in-world game started through its host (the picker's launch).
func _leave_game(label: String, node_name: String, activity: String) -> void:
	var s = game.find_child(node_name, true, false)
	check(s != null and s.host != null, "%s: session found" % label)
	if s == null or s.host == null:
		return
	var host = s.host
	var panel = host.dialogue_panel
	check(not s.request_leave(), "%s: request_leave() is false with no game" % label)
	host.launch()
	await create_timer(3.0).timeout
	host.close_dialogue()
	await frames(2)
	check(Board.shared().blocker("") == activity, "%s: the game runs (%s)" % [label, Board.shared().blocker("")])
	if host.is_asking_leave():
		# Closing a customer's question asks by itself (Next, Please!): stay first.
		panel.quit_answered.emit(false)
		await frames(3)
		host.close_dialogue()
		await frames(2)
	check(s.request_leave() and host.is_asking_leave(), "%s: request_leave() asks the leave question" % label)
	panel.quit_answered.emit(false)
	await frames(3)
	check(Board.shared().blocker("") == activity and not host.is_asking_leave(), "%s: stay keeps the game" % label)
	if label == "Next, Please!":
		check(game.player.seated, "%s: seated at window 2" % label)
		game.seating.stand()
		await create_timer(1.5).timeout
		check(host.is_asking_leave() and (game.player.seated or game.player.sit_transition), "%s: getting up mid-game sits the player back down and asks" % label)
		panel.quit_answered.emit(false)
		await create_timer(1.0).timeout
		check(game.player.seated and Board.shared().blocker("") == activity, "%s: stay keeps the player seated and the game" % label)
	# Esc with no popup over the game (a first Esc may close a line or card that asks itself).
	host.close_dialogue()
	await frames(2)
	for i in 3:
		if host.is_asking_leave():
			break
		_back()
		await frames(2)
	check(host.is_asking_leave() and not game.settings_panel.visible, "%s: Esc mid-game asks the leave question, not Settings" % label)
	panel.quit_answered.emit(true)
	await create_timer(2.5).timeout
	check(Board.shared().blocker("") == "", "%s: yes ends the game" % label)
	host.close_dialogue()
	if game.settings_panel.visible:
		game.settings_panel.close()
	await frames(2)

## The first point around `centre` (rings out to 60 m) that is not in the library zone.
func _outside(centre: Vector3) -> Vector3:
	for r in range(4, 60, 2):
		for i in 24:
			var p := centre + Vector3(cos(i * TAU / 24.0), 0, sin(i * TAU / 24.0)) * float(r)
			if game.zones.resolve_global(p) != "library":
				return p
	return Vector3.INF

func _back() -> void:
	var event := InputEventAction.new()
	event.action = "back"
	event.pressed = true
	game._unhandled_input(event)

func shot(title: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

func finish() -> void:
	print("GAME EXITS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
