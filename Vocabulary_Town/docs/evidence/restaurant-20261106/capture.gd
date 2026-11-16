extends SceneTree
## STALE since 11 Nov 2026: the game flow, panel API and textures poster changed; the current
## check and views are docs/evidence/restaurant-flow-20261111/capture.gd. Kept as the 6 Nov record.
## Alta Cocina restaurant game in the town (6 Nov 2026): checks and views in one town load.
## Checks: the customer seat, a seated house-character customer (not staff) that can be
## talked to, Twinkle's meta, the four icon posters with their sheets; one meal played
## through the session (offer -> play -> a wrong dish then the right one for each of the four
## courses -> summary -> finish -> a new customer), the activity board blocking another game
## meanwhile, and the leave question. Views: the customer, the posters, the panel (order,
## inspection, wrong-dish ring, right, summary, leave) in Spanish, with translation, and in
## Chinese. Uses Main, which saves progress and settings: run with an isolated HOME (README).
## Camera points are in the Alta Cocina frame (Restaurants/Pizza; door side -Z).
## HOME=<scratch>/home VT_FOCUS=all godot --path . --resolution 1400x900 --script res://docs/evidence/restaurant-20261106/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const FOLDER := "res://docs/evidence/restaurant-20261106/"
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frame(file: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")

func shot(camera: Camera3D, from: Vector3, at: Vector3, file: String, fov := 60.0) -> void:
	camera.fov = fov
	camera.global_position = from
	camera.look_at(at)
	await frame(file)

## A dish on the current course's menu that misses the order (the first one found).
func wrong_dish(session) -> String:
	for entry in session.orders.menu[str(session.order.course)]:
		if not Orders.matches(entry, session.order.reqs):
			return str(entry.id)
	return ""

func right_dish(session) -> String:
	for entry in session.orders.menu[str(session.order.course)]:
		if Orders.matches(entry, session.order.reqs):
			return str(entry.id)
	return ""

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await process_frame
	var room: Node3D = game.apartment.get_node("Restaurants/Pizza")
	var at := func(x: float, y: float, z: float) -> Vector3: return room.to_global(Vector3(x, y, z))
	var session = game.get_node("RestaurantSession")
	session.set_process(false)
	# --- World checks ----------------------------------------------------------------------
	check(session.seat != null and session.seat.name == "RestaurantCustomerSeat", "customer seat marker exists")
	check(session.twinkle != null and str(session.twinkle.get_meta("shop_clerk", "")) == "restaurant_twinkle", "Twinkle (BeagleWaiter) offers restaurant_twinkle")
	var first_customer: Node3D = session.customer
	check(is_instance_valid(first_customer) and str(first_customer.get_meta("shop_clerk", "")) == "restaurant_twinkle", "a seated customer can be talked to")
	check(is_instance_valid(first_customer) and not session.STAFF.has(str(first_customer.get_meta("character_id", ""))), "the customer is not BonBon, Twinkle or Bruno (%s)" % [first_customer.get_meta("character_id", "?") if is_instance_valid(first_customer) else "none"])
	if is_instance_valid(first_customer):
		var local: Vector3 = room.to_local(first_customer.global_position)
		check(local.distance_to(Vector3(-13.95, local.y, -2.82)) < .7 and local.y > .2 and local.y < 1.6, "customer sits on the booth seat (local %s)" % [local])
	for title in ["Restaurant poster tastes", "Restaurant poster textures", "Restaurant poster ingredients", "Restaurant menu board"]:
		var poster: Node = room.find_child(title, true, false)
		var sprites: Array = poster.find_children("*", "Sprite3D", true, false) if poster != null else []
		check(poster != null and sprites.size() >= 4 and sprites[0].texture != null, "%s exists with %d icons" % [title, sprites.size()])
	game.player.global_position = at.call(-3.0, .3, 2.0)
	# --- 3D views (HUD hidden, own camera) ---------------------------------------------------
	game.hud.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.far = 900.0
	camera.current = true
	await shot(camera, at.call(-10.6, 2.0, -6.4), at.call(-13.6, 1.0, -2.9), "customer", 60.0)
	await shot(camera, at.call(-7.5, 3.2, 1.0), at.call(-12.0, 1.2, -4.5), "booths", 70.0)
	# Posters on the rear wall since 8 Nov 2026 (scripts/buildings/restaurants.gd dining_room_refresh).
	await shot(camera, at.call(3.49, 4.0, 3.5), at.call(3.49, 4.6, 7.7), "poster-tastes", 58.0)
	await shot(camera, at.call(7.6, 4.0, 3.5), at.call(7.6, 4.6, 7.7), "poster-textures", 58.0)
	await shot(camera, at.call(-1.1, 4.0, 3.5), at.call(-1.1, 4.6, 7.7), "poster-ingredients", 58.0)
	await shot(camera, at.call(12.37, 4.0, 3.3), at.call(12.37, 4.6, 7.7), "poster-menu", 62.0)
	await shot(camera, at.call(0, 5.6, 6.0), at.call(0, 2.0, -7.7), "front-wall", 84.0)
	# --- The game (HUD and game camera) ------------------------------------------------------
	camera.current = false
	game.camera.current = true
	game.hud.show()
	game.player.global_position = at.call(-3.7, .3, -1.6)  # Twinkle at z -2.75 since 8 Nov 2026
	var box = game.shop_panel
	var panel = game.restaurant_panel
	session.offered = true
	game.interaction.clerk_activated.emit(session.twinkle)
	await frame("game-offer")
	box.choice_pressed.emit("restaurant_play")
	check(panel.visible and session.playing, "Yes opens the restaurant panel")
	if session.order.is_empty():
		print("FAIL: no order; stopping (%d checks, %d failed)" % [checks, failures + 1])
		quit(1)
		return
	check(Board.shared().blocker("flight_bruno") == "restaurant_twinkle", "the activity board blocks another game during the meal")
	await frame("game-order")
	var courses_done := 0
	for i in 4:
		var course := str(session.order.course)
		check(course == str(Orders.courses()[i]), "course %d is %s" % [i + 1, course])
		check(Orders.count_matches(session.orders.menu[course], session.order.reqs) == 1, "exactly one %s matches the order" % course)
		var wrong := wrong_dish(session)
		var right := right_dish(session)
		panel.show_tab(course)
		panel.inspect(wrong)
		if i == 0:
			await frame("game-inspect")
		panel.serve_pressed.emit(wrong)
		check(panel.marks.get(wrong) == false and not panel.solved and panel.miss_prop != "", "a wrong %s is refused with the missed property (%s)" % [course, panel.miss_prop])
		if i == 0:
			await frame("game-wrong")
		panel.inspect(right)
		panel.serve_pressed.emit(right)
		check(panel.solved and Board.shared().done("restaurant_twinkle") == i + 1, "the right %s counts (%d)" % [course, Board.shared().done("restaurant_twinkle")])
		if i == 0:
			await frame("game-right")
		courses_done += 1
		if i < 3:
			panel.next_pressed.emit()
	check(not panel.summary.is_empty() and panel.summary.lines.size() > 0, "after four courses the summary lists %d words" % [panel.summary.get("lines", []).size()])
	await frame("game-summary")
	panel.finish_pressed.emit()
	check(not panel.visible and not session.playing, "Finish closes the panel")
	check(Board.shared().blocker("flight_bruno") == "", "other games are free again")
	check(is_instance_valid(session.customer) and session.customer != first_customer and str(session.customer.get_meta("character_id", "")) != str(first_customer.get_meta("character_id", "x")), "a different customer sits down (%s)" % [session.customer.get_meta("character_id", "?")])
	box.dialogue_closed.emit()
	await process_frame
	# Leaving early asks first; talking to the customer offers the game too.
	session.offered = true
	game.interaction.clerk_activated.emit(session.customer)
	await frame("game-customer-offer")
	box.choice_pressed.emit("restaurant_play")
	panel.close_requested.emit()
	await frame("game-leave")
	box.quit_answered.emit(true)
	check(not panel.visible, "leaving early closes the panel")
	box.dialogue_closed.emit()
	# Translation shown, then Chinese as the language learned.
	session.offered = true
	game.interaction.clerk_activated.emit(session.twinkle)
	box.choice_pressed.emit("restaurant_play")
	panel.show_native = true
	panel.inspect(right_dish(session))
	await frame("game-translated")
	panel.close_requested.emit()
	box.quit_answered.emit(true)
	box.dialogue_closed.emit()
	GameSettings.shared().set_languages("en", "zh")
	await process_frame
	box.dialogue_closed.emit()
	session.offered = true
	game.interaction.clerk_activated.emit(session.twinkle)
	box.choice_pressed.emit("restaurant_play")
	panel.show_native = true
	panel.inspect(right_dish(session))
	await frame("game-chinese")
	GameSettings.shared().set_languages("en", "es")
	print("%s: %d checks, %d failed" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
