extends SceneTree
## 23 Nov 2026 (user): bank rework. The bank grows backward (an annex: a bigger vault room with the
## round wall safe on its back wall, a safe-deposit room with walls of small boxes, the manager's
## office extended to the back), a staff door from the office to the teller side of the counter,
## a slow, heavy vault door, one teller view that shows the monitor and the customer together, and
## the bank manager: paying an impostor brings her out of the office to warn the player; a second
## payout in a session ends the shift with a "let go" results card.
## Checks: the annex parts and boxes, the heavy swing (slow start, about 3 s), the stamp coin still
## in the moved safe, clear walking routes (lobby -> office -> staff door -> behind the counter;
## lobby -> vault -> deposit room), the account view framing both the monitor and the customer's
## face above the dialogue box, the warning scene (walk out, two lines, "sorry", walk back, the
## game goes on with another impostor later), and the firing (two lines, the card, no replay, the
## banker no longer offering). With graphics it writes *.png here.
## Updated 24 Nov 2026 to the new flow (docs/guides/TOWN_DESIGN_BRIEF.md "Next, Please! polish"):
## a withdrawal is asked once in the account view (no "Check the account" step) and a served
## customer moves on by itself (no "Next!"); the staff door is wider (its route is unchanged).
## HOME=<scratch> VT_FOCUS=bank VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/bank-rework-20261123/verify.gd
const OUT := "res://docs/evidence/bank-rework-20261123"
const Session := preload("res://scripts/learning/teller_session.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
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
	# --- the annex
	for title in ["Annex roof", "Annex back wall", "Annex left wall", "Annex right wall", "Bank back wall upper",
			"Bank back wall teller", "Vault room floor", "Deposit room floor", "Deposit room", "Staff door", "Office window"]:
		check(bank.get_node_or_null(title) != null, "annex part: " + title)
	check(bank.get_node_or_null("Bank back wall") == null, "the old one-piece back wall is gone")
	var boxes := 0
	for node: MultiMeshInstance3D in bank.find_children("Deposit box doors*", "MultiMeshInstance3D", true, false):
		boxes += node.multimesh.instance_count
	check(boxes > 400, "walls of small deposit boxes (%d)" % boxes)
	var box_words := bank.find_children("Deposit boxes*", "", false, false).filter(func(n) -> bool: return n.has_meta("word_key"))
	check(box_words.is_empty(), "the deposit boxes are look only (no words)")
	var annex_aabb := _town_aabb(bank.get_node("Annex roof"))
	check(annex_aabb.end.x < 150.3 and annex_aabb.position.z > 101.6 and annex_aabb.end.z < 114.4, "the annex stays behind the bank, within its width %s" % annex_aabb)
	# --- the stamp coin is still inside the moved safe
	var coin := town.find_child("StampCoin_bank", true, false) as Node3D
	var drum := bank.get_node_or_null("Vault safe drum") as Node3D
	check(coin != null and drum != null and coin.global_position.distance_to(drum.global_position) < 0.9, "the bank's stamp coin sits in the moved safe")
	# --- the heavy vault door
	var vault_leaf := bank.get_node_or_null("Vault entrance/Vault entrance door") as Node3D
	check(vault_leaf != null and game.doors.has(vault_leaf) and float(game.doors[vault_leaf].get("seconds", 0.0)) >= 2.5, "the vault door is a heavy door (%s s)" % (game.doors[vault_leaf].get("seconds") if vault_leaf != null and game.doors.has(vault_leaf) else "?"))
	check(DoorAnimator.heavy_curve(0.25) < 0.12 and absf(DoorAnimator.heavy_curve(1.0) - 1.0) < 0.001 and DoorAnimator.heavy_curve(0.0) == 0.0, "the heavy swing starts slowly (%.3f at a quarter)" % DoorAnimator.heavy_curve(0.25))
	if vault_leaf != null and game.doors.has(vault_leaf):
		var full := float(game.doors[vault_leaf].angle)
		DoorAnimator.toggle(game, vault_leaf)
		await create_timer(1.0).timeout
		var after_one := vault_leaf.rotation.y / full
		check(after_one > 0.02 and after_one < 0.4, "one second in, the vault door is only %.0f%% open" % (after_one * 100.0))
		if graphics:
			await _view("vault-door-swinging", Vector3(134.6, 1.9, 103.0), Vector3(138.6, 1.1, 104.0))
		await create_timer(2.6).timeout
		check(absf(vault_leaf.rotation.y / full - 1.0) < 0.02, "after about 3 s it is fully open")
	# --- walking routes (doors open): behind the counter through the office, and into the deposit room
	for path in ["Manager office/Manager office door", "Staff door/Staff door leaf", "Deposit room/Deposit room door"]:
		var leaf := bank.get_node_or_null(path)
		check(leaf != null and game.doors.has(leaf), "door registered: " + path)
		if leaf != null and game.doors.has(leaf):
			game.doors[leaf]["open"] = true
	await create_timer(1.5).timeout
	var routes := {
		"lobby to the teller side (office, staff door)": [Vector3(135.6, 0, 111.55), Vector3(136.8, 0, 111.55), Vector3(138.2, 0, 111.0), Vector3(139.475, 0, 110.6), Vector3(139.475, 0, 109.6), Vector3(139.475, 0, 108.8), Session.TELLER_SPOT],
		"lobby to the deposit room (vault)": [Vector3(136.3, 0, 104.15), Vector3(138.4, 0, 103.9), Vector3(140.5, 0, 104.2), Vector3(142.5, 0, 104.15), Vector3(144.3, 0, 104.15), Vector3(145.1, 0, 104.15), Vector3(146.5, 0, 104.15), Vector3(146.5, 0, 105.6), Vector3(148.6, 0, 105.6)],
		"the manager's walk": [Vector3(142.9, 0, 110.4), Session.MANAGER_DOOR, Session.MANAGER_SPOT],
	}
	for title in routes:
		var blocked := _blocked(routes[title])
		check(blocked.is_empty(), "clear route: %s %s" % [title, blocked])
	if graphics:
		await _view("exterior-back", Vector3(158.0, 8.5, 118.5), Vector3(143.5, 2.0, 108.0))
		await _view("vault-room", Vector3(138.3, 1.75, 102.7), Vector3(145.0, 1.1, 106.6))
		await _view("deposit-room", Vector3(145.8, 2.2, 102.7), Vector3(149.3, 1.2, 110.0))
		await _view("deposit-room-left", Vector3(146.0, 2.2, 112.5), Vector3(149.4, 1.2, 104.5))
		await _view("office-and-staff-door", Vector3(137.4, 2.1, 113.3), Vector3(141.0, 0.9, 109.6))
		await _view("staff-door-from-teller-side", Vector3(140.2, 1.9, 106.2), Vector3(139.4, 1.0, 110.0))
		await _plan("plan")
	for path in ["Manager office/Manager office door", "Staff door/Staff door leaf", "Deposit room/Deposit room door", "Vault entrance/Vault entrance door"]:
		var leaf := bank.get_node_or_null(path)
		if leaf != null and game.doors.has(leaf):
			game.doors[leaf]["open"] = false
	# --- the teller game: the account view, then impostors and the manager
	var session = game.get_node_or_null("TellerSession")
	check(session != null and session.host != null and session.manager != null, "teller session with the bank manager")
	if session == null or session.host == null:
		return finish()
	var host = session.host
	var money = session.money
	var manager: Node3D = session.manager
	check(manager.find_child("Costume", true, false) != null and str(manager.get_meta("word_key", "")) == "boss", "the manager: a suit, tag 'boss'")
	for id in ["impostor_thanks", "manager_warn_1", "manager_warn_2", "manager_sorry", "manager_fired_1", "manager_fired_2", "manager_okay"]:
		var phrase: Dictionary = host.lexicon.phrases.get("teller." + id, {})
		check(phrase.get("es", "") != "" and phrase.get("en", "") != "" and phrase.get("zh", "") != "", "phrase teller.%s in es, en, zh" % id)
	session.data["impostor_chance"] = 1.0
	Board.shared().set_rounds("teller_bank", 5)
	host.launch()
	await _until(func() -> bool: return session.step in ["ask", "screen"], 8.0)
	if session.current.kind == "change":
		await _pay(session, money, host)
		await _until(func() -> bool: return session.step in ["ask", "screen"] and not session.current.is_empty() and session.current.kind != "change", 12.0)
	await create_timer(0.6).timeout
	check(session._camera != null and session._camera.current and session.step == "screen", "a withdrawal: straight to the account view")
	var framing := _framing(session._camera, session._monitor.global_position, session.current.node)
	check(framing.ok, "one view shows the monitor and the customer's face, above the dialogue box %s" % framing)
	if graphics:
		await _snap("teller-account-view")
	session._on_choice(host.choice_prefix() + "decline")
	if session.step == "fix":
		check(session._camera.current, "a mistake about the account keeps the account view")
		if graphics:
			await _snap("teller-mistake-view")
		session._on_choice(host.choice_prefix() + "again")
	else:
		await _until(func() -> bool: return session.step == "served", 6.0)
	# Serve until the impostor and pay them.
	await _to_impostor(session, money, host)
	check(session.current.get("impostor", false), "an impostor reaches the window")
	if not session.current.get("impostor", false):
		return finish()
	var first_number: int = session.current.number
	await _pay(session, money, host)
	check(session.step == "paid_out" and host.line_id == "teller.impostor_thanks", "paying an impostor: the money goes ('Thanks! Bye!')")
	check(session._impostor_at > first_number, "another impostor comes later in the session (customer %d)" % session._impostor_at)
	await _until(func() -> bool: return session.step == "manager", 6.0)
	await create_timer(0.8).timeout
	var staff_leaf := bank.get_node_or_null(Session.STAFF_DOOR_LEAF)
	check(staff_leaf != null and bool(game.doors[staff_leaf].open), "the staff door opens for the manager")
	if session.step != "manager":
		# The state when the manager's first visit is missed (the 24-25 Nov failures: the impostor
		# was paid while walking up, see _to_impostor).
		print("DIAG manager visit: step '%s', line '%s', payouts %d, playing %s, current (number, impostor, kind) %s, manager valid %s at %s, door open %s" % [
				session.step, host.line_id, session._payouts, session.playing, [session.current.get("number"), session.current.get("impostor"), session.current.get("kind")],
				is_instance_valid(manager), manager.global_position if is_instance_valid(manager) else Vector3.ZERO,
				bool(game.doors[staff_leaf].open) if staff_leaf != null else false])
	if graphics:
		await _snap("manager-walks-out")
	await _until(func() -> bool: return host.line_id == "teller.manager_warn_1", 8.0)
	var spot: Vector3 = town.to_global(Session.MANAGER_SPOT)
	check(host.line_id == "teller.manager_warn_1" and manager.global_position.distance_to(Vector3(spot.x, manager.global_position.y, spot.z)) < 0.05, "the manager comes to the teller: 'That person isn't the one in the photo'")
	check(session._manager_presence.is_zoomed(), "the camera frames the manager")
	if graphics:
		await _snap("manager-warns")
	await _until(func() -> bool: return host.line_id == "teller.manager_warn_2", 6.0)
	check(host.line_id == "teller.manager_warn_2" and str(session._prompt[2][0].id).ends_with("sorry"), "'If it happens again...' with a 'Sorry' answer")
	if graphics:
		await _snap("manager-warns-2")
	session._on_choice(host.choice_prefix() + "sorry")
	await _until(func() -> bool: return session.step in ["ask", "screen"], 10.0)
	check(session.step in ["ask", "screen"] and session.playing, "the manager walks back and the game goes on")
	await _until(func() -> bool: return not bool(game.doors[staff_leaf].open), 6.0)
	check(not bool(game.doors[staff_leaf].open), "the staff door closes behind her")
	# The second impostor, paid too: the player is let go.
	await _to_impostor(session, money, host)
	check(session.current.get("impostor", false), "the second impostor reaches the window")
	if not session.current.get("impostor", false):
		return finish()
	await _pay(session, money, host)
	await _until(func() -> bool: return host.line_id == "teller.manager_fired_2", 16.0)
	check(host.line_id == "teller.manager_fired_2" and str(session._prompt[2][0].id).ends_with("fired"), "a second payout: 'you don't work here anymore'")
	if graphics:
		await _snap("manager-fires")
	session._on_choice(host.choice_prefix() + "fired")
	await _until(func() -> bool: return game.results_screen.visible, 6.0)
	check(game.results_screen.visible and str(game.results_screen.shown.get("title", "")) == preload("res://scripts/language/ui_text.gd").t("results.title_teller_fired"), "the 'let go' results card")
	check(not bool(game.results_screen.shown.get("replay", true)) and game.results_screen.card.find_child("Play again", true, false) == null, "no Play again on it")
	check(not session.playing and not session.offered, "the shift is over; the banker offers it again on a later visit")
	check(manager.global_position.distance_to(town.to_global(Session.MANAGER_HOME)) < 0.5, "the manager is back at her desk")
	if graphics:
		await _snap("let-go-card")
	finish()

## A town-space AABB of a node's meshes.
func _town_aabb(node: Node3D) -> AABB:
	var inv := town.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for m: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (inv * m.global_transform) * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

## Points (town) along `points` every 0.25 where a 0.5 x 1.0 x 0.5 body would hit something.
func _blocked(points: Array) -> Array:
	var space = town.get_world_3d().direct_space_state
	var hits := []
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 1.0, 0.5)
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var steps := maxi(1, ceili(a.distance_to(b) / 0.25))
		for k in steps + 1:
			var p := a.lerp(b, float(k) / steps)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = Transform3D(town.global_basis.orthonormalized(), town.to_global(Vector3(p.x, 0.75, p.z)))
			query.exclude = [game.player.get_rid()]
			for hit in space.intersect_shape(query, 4):
				var session = game.get_node_or_null("TellerSession")
				if session != null and session.manager != null and session.manager.is_ancestor_of(hit.collider):
					continue
				var title := str(hit.collider.get_meta("object_name", hit.collider.get_parent().name))
				hits.append("%s at (%.1f, %.1f)" % [title, p.x, p.z])
				break
	return hits

## Where the monitor's screen and the customer's face fall in the camera's picture.
func _framing(camera: Camera3D, monitor: Vector3, customer: Node3D) -> Dictionary:
	var top := customer.global_position.y + 1.0
	for mesh: MeshInstance3D in customer.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh != null and mesh.is_visible_in_tree():
			top = maxf(top, (mesh.global_transform * mesh.mesh.get_aabb()).end.y)
	var face := Vector3(customer.global_position.x, top - 0.4 * town.global_basis.get_scale().y, customer.global_position.z)
	var view: Vector2 = root.get_visible_rect().size
	var m := camera.unproject_position(monitor) / view
	var f := camera.unproject_position(face) / view
	var inside := func(p: Vector2) -> bool: return p.x > 0.05 and p.x < 0.95 and p.y > 0.05 and p.y < 0.68
	return {"ok": not camera.is_position_behind(monitor) and not camera.is_position_behind(face) and inside.call(m) and inside.call(f),
			"monitor": m.snapped(Vector2(0.01, 0.01)), "face": f.snapped(Vector2(0.01, 0.01))}

## Serves customers right until an impostor stands at the window. Each customer takes two turns
## of the loop (asking, then the thanks), so the guard allows a whole session; the impostor is
## paid only once it has reached the window and asks (25 Nov 2026: with 8 turns an impostor that
## came fifth was paid while still walking up; it then asked again, so the manager never came).
func _to_impostor(session, money, host) -> void:
	for guard in 24:
		await _until(func() -> bool: return session.step in ["ask", "screen", "served"], 12.0)
		if session.step == "served":
			# The thanks moves on by itself (24 Nov 2026).
			await _until(func() -> bool: return session.step != "served", 8.0)
			continue
		if session.current.get("impostor", false):
			break
		var c: Dictionary = session.current
		if c.kind == "withdraw" and c.balance < c.dollars:
			session._on_choice(host.choice_prefix() + "decline")
			await _until(func() -> bool: return session.step == "served", 6.0)
			continue
		await _pay(session, money, host)
		await _until(func() -> bool: return session.step == "served", 3.0)
	await _until(func() -> bool: return session.step in ["ask", "screen"], 12.0)

## Counts out the exact amount for the customer at the window.
func _pay(session, money, host) -> void:
	var c: Dictionary = session.current
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

## The bank from above with its roofs and ceilings hidden (a plan of the new layout).
func _plan(title: String) -> void:
	var hidden := []
	for part in [bank, town.get_node_or_null("Map facades/BANK")]:
		if part == null:
			continue
		for node in part.find_children("*", "Node3D", true, false):
			var n := str(node.name).to_lower()
			if (n.contains("roof") or n.contains("ceiling") or n.contains("back wall upper") or n.contains("cornice") or n.contains("fascia") or n.contains("sign")) and node.visible:
				node.visible = false
				hidden.append(node)
	for node in town.get_children():
		if str(node.name).begins_with("Building outline") and node is Node3D and node.visible:
			node.visible = false
			hidden.append(node)
	await _view(title, Vector3(137.0, 30.0, 107.9), Vector3(137.0, 0.0, 107.95), 48.0)
	for node in hidden:
		node.visible = true

func finish() -> void:
	print("BANK REWORK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
