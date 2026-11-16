extends SceneTree
## Alta Cocina restaurant game, new flow (11 Nov 2026): checks and views in one town load.
## Checks: the textures poster is gone and the tastes poster moved; the menu table and book;
## two customer seats with two different seated house characters; one game played through
## the session: Twinkle (no customer named) -> customer ("!") -> "I'd like to order a starter
## and a drink" -> two seconds later the requests -> tablet -> a dish chosen per course ->
## send (two wrong dishes on the first visit) -> thanks -> verdict -> Twinkle's report (each
## wrong dish / good job) -> next customer at the other table ... -> the last report -> the
## words -> Finish -> new guests; the menu book (cover, a course, bookmarks); stopping a game
## at Twinkle (quit card); the entrance during a game (an invisible wall, the leave question,
## stepping back, "yes" ends the game). Updated for multi-course orders and the door on
## 11 Nov 2026 (second request). Views: room, menu table, both customers, posters, each step
## of the flow, tablet and book in Spanish, with translation and in Chinese. Uses Main, which saves progress and settings: run with an
## isolated HOME (README). Camera points are in the Alta Cocina frame (Restaurants/Pizza;
## door side -Z).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/restaurant-flow-20261111/capture.gd
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const FOLDER := "res://docs/evidence/restaurant-flow-20261111/"
const ACTIVITY := "restaurant_twinkle"
## Where the player stands to talk (room-local): Twinkle, each customer table, the menu table.
const STAND_TWINKLE := Vector3(-3.7, .3, -1.6)
const STAND_TABLES := [Vector3(-11.6, .3, -2.9), Vector3(6.3, .3, -2.9)]
const STAND_BOOK := Vector3(-4.7, .3, -5.3)
## At the entrance (in the door question zone) and a few steps back into the room.
const STAND_DOOR := Vector3(0, .3, -6.7)
const STAND_BACK := Vector3(0, .3, -4.2)
var failures := 0
var checks := 0
var game
var room: Node3D
var session
var box
var panel
var book

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frame(file: String, frames := 8) -> void:
	for i in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")

func shot(camera: Camera3D, from: Vector3, at: Vector3, file: String, fov := 60.0) -> void:
	camera.fov = fov
	camera.global_position = from
	camera.look_at(at)
	await frame(file)

func at(p: Vector3) -> Vector3:
	return room.to_global(p)

func stand(local: Vector3) -> void:
	game.player.global_position = at(local)

## A dish per course asked: the target, or (`wrong`) another dish of the course for the
## first and the last course.
func picks_for(wrong: bool) -> Dictionary:
	var out := {}
	for k in session.requests.size():
		var request: Dictionary = session.requests[k]
		out[str(request.course)] = str(request.target)
		if wrong and (k == 0 or k == session.requests.size() - 1):
			for entry in session.orders.menu[str(request.course)]:
				if not Orders.matches(entry, request.reqs):
					out[str(request.course)] = str(entry.id)
					break
	return out

## Lets physics see a teleported player (area overlaps, the door wall).
func settle() -> void:
	await create_timer(0.25).timeout

func line_text() -> String:
	return str(box.current_line().get("foreign", ""))

## Talk to the current customer, open the tablet and send `right` or a wrong dish; wait for
## the verdict. `views` saves the steps.
func serve(right: bool, views: bool) -> void:
	var i: int = session.current
	stand(STAND_TABLES[i])
	session._process(0.05)
	check(session.tables[i].presence.marker.visible, "the customer Twinkle sent the player to shows the '!' (table %d)" % (i + 1))
	var courses: Array = session._courses()
	var all: Array = Orders.courses()
	var in_order := true
	for k in range(1, courses.size()):
		in_order = in_order and all.find(courses[k]) > all.find(courses[k - 1])
	check(courses.size() >= 2 and courses.size() <= 3 and in_order, "the customer orders 2-3 courses in menu order %s" % [courses])
	game.interaction.clerk_activated.emit(session.tables[i].node)
	check(not box.has_choices() and line_text() == session._line(Orders.intro_ref(courses)).foreign, "first what they would like to order: %s" % line_text())
	if views:
		await frame("flow-2a-intro", 40)
	await create_timer(session.INTRO_SECONDS + 0.3).timeout
	check(box.has_choices() and line_text() == session._line(session._requests_ref()).foreign, "two seconds later the requests: %s" % line_text())
	if views:
		await frame("flow-2b-order", 10)
	box.choice_pressed.emit("restaurant_tablet")
	check(panel.visible and not box.is_dialogue_visible(), "Open the tablet shows the order tablet")
	check(panel.tab == courses[0] and not panel.can_send(), "the tablet opens the first course asked; Send waits for every course")
	var rows := 0
	for course in courses:
		rows += 1 if panel._slip.get_node_or_null("Slip " + course) != null else 0
	check(panel.ui.order.foreign == session._line(Orders.intro_ref(courses)).foreign and rows == courses.size() and panel.ui.requests.size() == courses.size(), "the bubble says which courses; the slip has each request (%d rows)" % rows)
	var picks := picks_for(not right)
	for k in courses.size():
		panel.inspect(picks[courses[k]])
		if views and k == 0:
			await frame("tablet-1-dish")
		panel.choose()
		if k + 1 < courses.size():
			check(panel.tab == courses[k + 1] and not panel.can_send(), "Choose puts the dish on the slip and opens the next course (%s)" % courses[k + 1])
	check(panel.can_send() and panel.picks == picks, "every course has a dish: Send order is on")
	if views:
		await frame("tablet-2-slip")
	panel._send.pressed.emit()
	check(panel.sent == picks, "Send order sends every dish and shows Order sent (%s)" % [picks])
	if views:
		await frame("tablet-3-sent")
	await create_timer(session.SENT_SECONDS + 0.2).timeout
	check(not panel.visible and line_text() == session.lexicon.line("restaurant.thanks").foreign, "the tablet closes and the customer says thanks")
	if views:
		await frame("flow-3-thanks")
	await create_timer(session.VERDICT_SECONDS).timeout
	var verdict: String = session.lexicon.line("restaurant.verdict_right" if right else "restaurant.verdict_wrong").foreign
	check(line_text() == verdict and session.step == session.Step.TO_HOST, "about two seconds later the verdict: %s" % line_text())
	if views:
		await frame("flow-4-verdict-" + ("right" if right else "wrong"))
	session._process(0.05)
	check(session.twinkle.get_node("NeedsHelpMarker").visible, "Twinkle shows the '!' for the report")

func report(views: String) -> void:
	stand(STAND_TWINKLE)
	game.interaction.clerk_activated.emit(session.twinkle)
	if views != "":
		await frame(views, 40)

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await process_frame
	room = game.apartment.get_node("Restaurants/Pizza")
	session = game.get_node("RestaurantSession")
	box = game.shop_panel
	panel = game.restaurant_panel
	book = game.restaurant_menu_book
	# --- World checks ----------------------------------------------------------------------
	check(room.find_child("Restaurant poster textures", true, false) == null, "the textures poster is gone")
	var tastes: Node3D = room.find_child("Restaurant poster tastes", true, false)
	check(tastes != null and is_equal_approx(tastes.position.x, 5.5), "the tastes poster is centred over the kitchen pass")
	var menu_book: Node3D = room.find_child("RestaurantMenuBook", true, false)
	check(menu_book != null and str(menu_book.get_meta("word_key", "")) == "menu" and str(menu_book.get_meta("shop_clerk", "")) == ACTIVITY, "the menu book is a word and can be used")
	check(session.tables.size() == 2, "two customer seats")
	var ids := {}
	for i in session.tables.size():
		var node: Node3D = session.tables[i].node
		check(is_instance_valid(node) and str(node.get_meta("shop_clerk", "")) == ACTIVITY, "customer %d can be talked to" % (i + 1))
		if is_instance_valid(node):
			ids[str(node.get_meta("character_id", ""))] = true
			check(not session.STAFF.has(str(node.get_meta("character_id", ""))), "customer %d is not staff" % (i + 1))
			var local: Vector3 = room.to_local(node.global_position)
			var seat: Vector3 = room.to_local(session.tables[i].seat.global_position)
			check(Vector2(local.x, local.z).distance_to(Vector2(seat.x, seat.z)) < .7 and local.y > .2 and local.y < 1.6, "customer %d sits at the seat (local %s)" % [i + 1, local])
	check(ids.size() == 2, "two different customers")
	stand(Vector3(-3.0, .3, 2.0))
	# --- 3D views (HUD hidden, own camera) ---------------------------------------------------
	game.hud.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.far = 900.0
	camera.current = true
	await shot(camera, at(Vector3(1.5, 2.6, -7.2)), at(Vector3(-4.0, .9, -3.0)), "room-entrance", 72.0)
	await shot(camera, at(Vector3(-3.6, 1.9, -5.9)), at(Vector3(-5.7, 1.0, -5.3)), "menu-table", 55.0)
	await shot(camera, at(Vector3(-10.6, 2.0, -6.4)), at(Vector3(-13.6, 1.0, -2.9)), "customer-1", 60.0)
	await shot(camera, at(Vector3(3.4, 2.0, -6.6)), at(Vector3(5.0, 1.0, -3.7)), "customer-2", 60.0)
	await shot(camera, at(Vector3(4.0, 3.6, 1.0)), at(Vector3(4.0, 4.4, 7.7)), "rear-wall-posters", 80.0)
	# --- The game (HUD and game camera) ------------------------------------------------------
	camera.current = false
	game.camera.current = true
	game.hud.show()
	# The menu book.
	stand(STAND_BOOK)
	game.interaction.clerk_activated.emit(menu_book)
	check(book.visible and book.spread == 0, "using the menu book opens it at the cover")
	await frame("book-1-cover")
	book.turn_to(2)
	check(book.spread == 2, "a bookmark turns to the main courses")
	await frame("book-2-main", 30)
	book.show_native = true
	book.turn_to(4)
	await frame("book-3-drinks-translated", 30)
	book.show_native = false
	book.close_requested.emit()
	check(not book.visible, "✕ closes the book")
	# One game: Twinkle sends the player to a customer.
	stand(STAND_TWINKLE)
	session.offered = true
	game.interaction.clerk_activated.emit(session.twinkle)
	await frame("flow-0-offer", 30)
	box.choice_pressed.emit("restaurant_play")
	check(session.playing and session.step == session.Step.TO_CUSTOMER and session.current >= 0, "Yes starts a visit")
	check(Board.shared().blocker("flight_bruno") == ACTIVITY, "the activity board blocks another game meanwhile")
	check(line_text() == session.lexicon.line("restaurant.go_to_customer").foreign and not session._name(session.current) in line_text(), "Twinkle does not name the customer: %s" % line_text())
	await frame("flow-1-go-to-customer")
	# The other (waiting) customer only says they are still reading the menu.
	var other: int = (session.current + 1) % 2
	stand(STAND_TABLES[other])
	game.interaction.clerk_activated.emit(session.tables[other].node)
	check(line_text() == session.lexicon.line("restaurant.customer_wait").foreign, "the other customer is still looking at the menu")
	# First visit: a wrong dish.
	var first: int = session.current
	await serve(false, true)
	await report("flow-5-report-wrong")
	var several: bool = session.requests.size() > 1
	check("pero le serviste" in line_text() and (not several or "También quería" in line_text()) and box.has_choices(), "Twinkle says each wrong dish: %s" % line_text())
	check(Board.shared().done(ACTIVITY) == 0, "a wrong dish does not count")
	box.choice_pressed.emit("restaurant_next")
	check(session.current != first and session.step == session.Step.TO_CUSTOMER, "Next customer: the other table")
	var target: int = Board.shared().target(ACTIVITY)
	for n in target:
		await serve(true, n == 0)
		await report("flow-6-report-right" if n == 0 else ("flow-7-report-last" if n == target - 1 else ""))
		check(Board.shared().done(ACTIVITY) == n + 1, "a right dish counts (%d)" % (n + 1))
		if n < target - 1:
			check(line_text().begins_with("¡Buen trabajo!"), "Twinkle: good job")
			box.choice_pressed.emit("restaurant_next")
	check(session.finished and box.has_choices(), "the last report offers the words")
	box.choice_pressed.emit("restaurant_words")
	check(panel.visible and not panel.summary.is_empty() and panel.summary.lines.size() > 0, "the tablet lists %d practised words" % [panel.summary.get("lines", []).size()])
	await frame("tablet-4-summary")
	var guests := [session.tables[0].node, session.tables[1].node]
	panel.finish_pressed.emit()
	check(not panel.visible and not session.playing, "Finish ends the game")
	check(Board.shared().blocker("flight_bruno") == "", "other games are free again")
	check(session.tables[0].node != guests[0] and session.tables[1].node != guests[1], "new guests sit down")
	box.dialogue_closed.emit()
	await process_frame
	# Stopping: Twinkle's reminder offers Stop serving, which asks first.
	session.offered = true
	game.interaction.clerk_activated.emit(session.twinkle)
	box.choice_pressed.emit("restaurant_play")
	game.interaction.clerk_activated.emit(session.twinkle)
	check(box.has_choices() and line_text() == session.lexicon.line("restaurant.reminder").foreign, "Twinkle reminds there is a customer: %s" % line_text())
	box.choice_pressed.emit("restaurant_stop")
	await frame("flow-8-stop")
	box.quit_answered.emit(true)
	check(not session.playing, "Stop serving ends the game")
	box.dialogue_closed.emit()
	# The entrance: before a game the door is open; during one an invisible wall holds it and
	# stepping up asks first (as the Mystery House arch).
	var out_of_door: Vector3 = room.global_basis * Vector3(0, 0, -2.5)
	stand(STAND_DOOR)
	await settle()
	var wall_shape: CollisionShape3D = session.door.wall.get_child(0)
	check(wall_shape.disabled and not session.host.is_asking_leave(), "no game: no wall, no question at the door")
	stand(STAND_TWINKLE)
	session.offered = true
	game.interaction.clerk_activated.emit(session.twinkle)
	box.choice_pressed.emit("restaurant_play")
	box.dialogue_closed.emit()
	await settle()
	check(not wall_shape.disabled, "a game: the wall stands in the door")
	stand(STAND_DOOR)
	await settle()
	check(session.host.is_asking_leave() and box.is_quit_open(), "walking up to the door asks whether to leave")
	check(game.player.test_move(game.player.global_transform, out_of_door), "the player cannot walk out meanwhile")
	await frame("flow-9-door-question")
	stand(STAND_BACK)
	await settle()
	session._process(0.05)
	check(not session.host.is_asking_leave() and session.playing, "stepping back takes the question away; the game goes on")
	stand(STAND_DOOR)
	await settle()
	check(session.host.is_asking_leave(), "back at the door: asked again")
	box.quit_answered.emit(true)
	await settle()
	check(not session.playing and wall_shape.disabled, "yes ends the game and opens the door")
	box.dialogue_closed.emit()
	# The tablet with translation, then Chinese as the language learned.
	for lang in ["es", "zh"]:
		GameSettings.shared().set_languages("en", lang)
		await process_frame
		box.dialogue_closed.emit()
		stand(STAND_TWINKLE)
		session.offered = true
		game.interaction.clerk_activated.emit(session.twinkle)
		box.choice_pressed.emit("restaurant_play")
		stand(STAND_TABLES[session.current])
		game.interaction.clerk_activated.emit(session.tables[session.current].node)
		await create_timer(session.INTRO_SECONDS + 0.3).timeout
		box.choice_pressed.emit("restaurant_tablet")
		panel.show_native = true
		panel.inspect(str(session.requests[0].target))
		panel.choose()
		panel.inspect(str(session.requests[1].target))
		await frame("tablet-translated-" + lang)
		panel.close_requested.emit()
		check(not panel.visible and session.playing, "✕ closes the tablet, the visit goes on (%s)" % lang)
		stand(STAND_BOOK)
		game.interaction.clerk_activated.emit(menu_book)
		book.turn_to(1)
		await frame("book-starters-" + lang, 30)
		book.close_requested.emit()
		session._on_leave_answered(true)
		box.dialogue_closed.emit()
	GameSettings.shared().set_languages("en", "es")
	print("%s: %d checks, %d failed" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
