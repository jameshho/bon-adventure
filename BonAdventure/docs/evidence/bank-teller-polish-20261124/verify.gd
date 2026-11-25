extends SceneTree
## 24 Nov 2026 (user): Next, Please! polish. A served customer's thanks moves on by itself (no
## "Next!" click); a withdrawal is asked once, in the account view (no "Check the account" and no
## second "Do I have enough?"); "Call the police" is no reply any more: a hidden red alarm button
## on the counter calls them; the player sits on window 2's chair for the game; the three teller
## chairs are real seats; the staff door is wide enough for BonBon; no tail on dialogue boxes.
## Checks: the staff door's width and a clear walk for the player's own capsule from the office
## to the teller side, the teller seats, the game flow above (seat, one request, two replies,
## auto-advance, the alarm hit test and the officer, the player's close-up showing BonBon, the
## model hidden in the account view, standing up at the end) and the dialogue box without a tail.
## With graphics it writes *.png here.
## HOME=<scratch> VT_FOCUS=bank VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/bank-teller-polish-20261124/verify.gd
const OUT := "res://docs/evidence/bank-teller-polish-20261124"
const Session := preload("res://scripts/learning/teller_session.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
var checks := 0
var failures := 0
var game
var town: Node3D
var bank: Node3D
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	town = game.apartment
	bank = ModularTown.building(town, "bank")
	check(bank != null, "the bank is loaded")
	if bank == null:
		return finish()
	# --- the dialogue box has no tail
	check(game.get("shop_panel") == null or not bool(game.shop_panel.tail), "dialogue box: no tail")
	# --- the staff door
	var staff := bank.get_node_or_null("Staff door") as Node3D
	check(staff != null and float(staff.width) >= 1.25, "the staff door is %.2f wide (town; was 0.95)" % (float(staff.width) if staff != null else 0.0))
	var leaf := bank.get_node_or_null(Session.STAFF_DOOR_LEAF)
	check(leaf != null and game.doors.has(leaf), "the staff door leaf is a registered door")
	if leaf != null and game.doors.has(leaf):
		game.doors[leaf]["open"] = true
	var office_door := bank.get_node_or_null("Manager office/Manager office door")
	if office_door != null and game.doors.has(office_door):
		game.doors[office_door]["open"] = true
	await create_timer(1.5).timeout
	var route := [Vector3(138.2, 0, 111.0), Vector3(139.5, 0, 110.9), Vector3(139.5, 0, 109.6), Vector3(139.5, 0, 108.6), Session.TELLER_SPOT]
	var blocked := _blocked_for_player(route)
	check(blocked.is_empty(), "BonBon's own capsule fits through the staff door to the teller side %s" % [blocked])
	if graphics:
		await _view("staff-door-from-office", Vector3(137.6, 2.2, 112.9), Vector3(139.6, 1.0, 109.4))
		await _view("staff-door-from-teller-side", Vector3(140.4, 2.0, 106.2), Vector3(139.5, 1.0, 110.0))
	for door in [leaf, office_door]:
		if door != null and game.doors.has(door):
			game.doors[door]["open"] = false
	# --- the teller seats
	var seats := []
	for n in 3:
		var node := bank.get_node_or_null("Interior/Teller chair seat %d" % (n + 1))
		var found: Array = game.seating.seats.filter(func(seat) -> bool: return seat.node == node)
		seats.append(node)
		check(node != null and not found.is_empty(), "teller chair %d is a seat" % (n + 1))
		if not found.is_empty():
			var forward: Vector3 = town.global_basis.inverse() * found[0].forward
			check(forward.normalized().x < -0.9, "teller chair %d faces the glass (%s)" % [n + 1, forward.normalized().snapped(Vector3(0.01, 0.01, 0.01))])
	# --- the game
	var session = game.get_node_or_null("TellerSession")
	check(session != null and session.host != null, "teller session")
	if session == null or session.host == null:
		return finish()
	var host = session.host
	var money = session.money
	for id in ["enough_q", "check", "call_police", "next", "close_window"]:
		check(not host.lexicon.phrases.has("teller." + id), "phrase teller.%s is gone" % id)
	for id in ["impostor_warn", "manager_warn_2"]:
		var en := str(host.lexicon.phrases.get("teller." + id, {}).get("en", ""))
		check(en.contains("red button"), "teller.%s names the red button" % id)
	session.data["impostor_chance"] = 1.0
	Board.shared().set_rounds("teller_bank", 5)
	host.launch()
	await _until(func() -> bool: return session.step in ["screen", "ask"] and not session.zone.fading, 10.0)
	await create_timer(0.8).timeout
	check(game.player.seated and game.seating.current.get("node") == seats[1], "the player sits on window 2's chair")
	var model := game.player.get("visual") as Node3D
	check(model != null and not model.visible, "BonBon's model is hidden in the teller's own view")
	var c: Dictionary = session.current
	if c.kind == "withdraw":
		check(session.step == "screen" and session._camera != null and session._camera.current, "a withdrawal goes straight to the account view")
		check(host.line_id == str(c.ask), "one request line (%s), no second 'Do I have enough?'" % host.line_id)
		var ids: Array = session._prompt[2].map(func(choice) -> String: return str(choice.id).trim_prefix(host.choice_prefix()))
		check(ids == ["count", "decline"], "two replies: count, not enough (%s)" % [ids])
	check(session._alarm != null and session._alarm.visible, "the alarm button is on the counter")
	if graphics:
		await _snap("account-view")
	# A right answer: the thanks moves on by itself.
	await _serve_right(session, money, host)
	check(session.step == "served" and (session._prompt[2] as Array).is_empty(), "the thanks has no button")
	var served_number: int = c.number
	if graphics:
		await _snap("thanks-no-button")
	await _until(func() -> bool: return not session.current.is_empty() and session.current.number != served_number and session.step in ["screen", "ask"], 12.0)
	check(not session.current.is_empty() and session.current.number != served_number, "the next customer steps up without a click")
	# On to the impostor; the alarm on a non-impostor would be a mistake, so serve the others.
	for guard in 6:
		if session.current.get("impostor", false):
			break
		if session.current.kind == "withdraw" and session.current.balance < session.current.dollars:
			session._on_choice(host.choice_prefix() + "decline")
			await _until(func() -> bool: return session.step == "declined", 2.0)
			if graphics and session.step == "declined":
				await create_timer(0.3).timeout
				check(model.visible, "the teller's close-up shows BonBon")
				await _snap("teller-close-up")
		else:
			await _serve_right(session, money, host)
		var number: int = session.current.number
		await _until(func() -> bool: return not session.current.is_empty() and session.current.number != number and session.step in ["screen", "ask"], 14.0)
	check(session.current.get("impostor", false), "an impostor reaches the window")
	if session.current.get("impostor", false):
		var camera: Camera3D = root.get_viewport().get_camera_3d()
		var spot: Vector2 = camera.unproject_position(session._alarm.to_global(Vector3(0, 0.022, 0)))
		var view: Vector2 = root.get_visible_rect().size
		check(spot.x > 0 and spot.x < view.x and spot.y > 0 and spot.y < view.y * 0.7, "the alarm is on screen in the account view, above the dialogue box (%s of %s)" % [spot.round(), view])
		check(not session.alarm_aimed(camera, spot + Vector2(0, -160)), "a click well away from the button misses it")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game.interaction.pointer_position = spot
		session._on_world_click()
		check(session.step == "escort", "a click on the red button calls the police")
		await _until(func() -> bool: return session.step == "served", 12.0)
		check(host.line_id == "teller.officer_now" and (session._prompt[2] as Array).is_empty(), "the officer's 'Please come with me now' moves on by itself")
		if graphics:
			await _snap("officer")
	session.end_activity()
	await create_timer(1.0).timeout
	var banker_at: Vector3 = session.banker.global_position
	check(not session.playing and not game.player.seated and not game.player.sit_transition and model.visible,
			"leaving the game: standing, BonBon visible (seated %s, sliding %s, visible %s)" % [game.player.seated, game.player.sit_transition, model.visible])
	check(game.player.global_position.distance_to(banker_at) < 3.5, "back in the lobby by the banker (%.1f m)" % game.player.global_position.distance_to(banker_at))
	check(not session._alarm.visible, "the alarm is put away")
	if graphics:
		# BonBon sitting at window 3's chair, seen from the lobby.
		game.seating.sit_at(seats[2], Vector3(1.2, 0, 0))
		await create_timer(1.0).timeout
		await _view("sitting-at-window-3", Vector3(134.0, 2.0, 109.6), Vector3(137.9, 0.9, 108.9))
	finish()

## Serves the customer at the window right (the exact cash, or "not enough" when short).
func _serve_right(session, money, host) -> void:
	var c: Dictionary = session.current
	if c.kind == "withdraw" and c.balance < c.dollars:
		session._on_choice(host.choice_prefix() + "decline")
		await _until(func() -> bool: return session.step == "served", 8.0)
		return
	session._on_choice(host.choice_prefix() + "count")
	money.clear()
	var left: int = c.dollars
	for note in [100, 50, 10, 5]:
		if c.kind == "change" and note == 100:
			continue
		while left >= note:
			money.add_piece("bill_%d" % note)
			left -= note
	money._submit_button.pressed.emit()
	await _until(func() -> bool: return session.step == "served", 3.0)

## Points (town) along `points` every 0.2 where the player's own collision capsule (world size)
## would hit something other than the player.
func _blocked_for_player(points: Array) -> Array:
	var space = town.get_world_3d().direct_space_state
	var body: CollisionShape3D = game.player.get_node("PlayerCollision")
	var hits := []
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var steps := maxi(1, ceili(a.distance_to(b) / 0.2))
		for k in steps + 1:
			var p := a.lerp(b, float(k) / steps)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = body.shape
			# A little above the floor, as the body stands (its centre at 1.1 m).
			query.transform = Transform3D(Basis(), town.to_global(Vector3(p.x, 0.05, p.z)) + Vector3(0, body.position.y + 0.02, 0))
			query.collision_mask = game.player.collision_mask
			query.exclude = [game.player.get_rid()]
			for hit in space.intersect_shape(query, 4):
				var title := str(hit.collider.get_meta("object_name", hit.collider.get_parent().name))
				hits.append("%s at (%.2f, %.2f)" % [title, p.x, p.z])
				break
	return hits

func _until(condition: Callable, seconds: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < seconds:
		await create_timer(1.0 / 30.0).timeout
		waited += 1.0 / 30.0

func _snap(title: String) -> void:
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

## A still view from `eye` toward `at` (town coordinates), HUD hidden.
func _view(title: String, eye: Vector3, at: Vector3, fov := 62.0) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.near = 0.05
	root.add_child(cam)
	cam.global_position = town.to_global(eye)
	cam.look_at(town.to_global(at), Vector3.UP)
	var previous := root.get_viewport().get_camera_3d()
	cam.current = true
	game.hud.visible = false
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	cam.queue_free()
	if previous != null and is_instance_valid(previous):
		previous.current = true

func finish() -> void:
	print("BANK TELLER POLISH: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
