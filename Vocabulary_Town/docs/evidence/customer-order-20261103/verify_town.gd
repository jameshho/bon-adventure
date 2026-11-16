extends SceneTree
## 3 Nov 2026: customer order minigame inside the real town (Main + supermarket clerk).
## Run with an isolated user directory (Main saves progress):
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/customer-order-20261103/verify_town.gd
const F := .1
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var town: Node3D = game.apartment
	var market: Node3D = town.get_node("RelocatedSites/Supermarket")
	var session = game.get_node_or_null("ShopSession_supermarket")
	check(session != null, "Main creates the supermarket session")
	if session == null:
		print("customer order town: ", checks, " checks, ", failures, " failures")
		quit(1)
		return
	var clerk: Node3D = session.clerk
	check(clerk != null and clerk.name == "BeagleClerk" and clerk.get_meta("shop_clerk") == "supermarket", "BeagleClerk is the tagged clerk")
	check(game.interaction.action_hint_text(clerk.get_meta("action_hint")) == "E: Hablar", "E hint is Hablar")
	var local := market.to_local(clerk.global_position)
	print("clerk market-local ", local)
	check(local.z < 34.25 and local.z > 28.0, "clerk stands in front of the store wall")
	check(game.zones.resolve_global(clerk.global_position) == "supermarket", "clerk is inside the supermarket zone")
	# Clear of the door (x -35.8..-30.2): the door and the clerk never share a click target.
	check(local.x < -36.5 or local.x > -29.5, "clerk is beside the door, not in front of it")
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(clerk.global_position + Vector3(0, 1.0, 0), clerk.global_position - Vector3(0, 1.5, 0))
	var ground := space.intersect_ray(down)
	check(not ground.is_empty() and absf(ground.position.y - clerk.global_position.y) < .08, "clerk stands on the ground")
	# The clerk can be aimed at: a ray from in front reaches the clerk's collider.
	var from: Vector3 = clerk.global_position + clerk.global_basis * Vector3(0, 1.0, 3.0)
	var ray := PhysicsRayQueryParameters3D.create(from, clerk.global_position + Vector3(0, 1.0, 0))
	var hit := space.intersect_ray(ray)
	var node: Node = hit.collider if not hit.is_empty() else null
	while node != null and node != town and not node.has_meta("shop_clerk"):
		node = node.get_parent()
	check(node == clerk, "clicking the clerk resolves to the clerk node")
	# The marker follows needs_help.
	var marker: Label3D = clerk.get_node("NeedsHelpMarker")
	session.needs_help = true
	session._animate(.1)
	check(marker.visible and marker.position.y > .5, "'!' shows while the clerk needs help")
	session._animate(.3)
	check(clerk.position.y >= session._rest_position.y, "clerk hop keeps him at or above his spot")
	session._start_order()
	session._animate(.1)
	check(not marker.visible and clerk.position.is_equal_approx(session._rest_position), "'!' hidden and clerk at rest during an order")
	session._on_quit_answered(true)
	session.needs_help = false
	session._animate(.1)
	check(not marker.visible, "'!' hidden when no help is needed")
	# Pool: every product is a clickable word inside the store and routes into the cart.
	var inside := {}
	for obj in town.find_children("*", "Node3D", true, false):
		var key := str(obj.get_meta("word_key", ""))
		if key == "" or not session.pool.has(key):
			continue
		var p := market.to_local(obj.global_position)
		if p.x < -45.75 or p.x > -20.25 or p.z < 34.25 or p.z > 59.75 or p.y > 5.8 or p.y < -.5:
			continue
		inside[key] = obj
	check(session.pool.size() == 80, "pool holds the 80 supermarket words")
	var absent: Array = session.pool.filter(func(k): return not inside.has(k))
	print("pool words with no shelf object: ", absent)
	check(absent.is_empty(), "every orderable word can be clicked in the store")
	session._start_order()
	var some: Node3D = inside[session.pool[0]]
	var added_before: int = session.order.cart_total()
	session._on_pick(some)
	check(session.order.cart_total() == added_before + 1, "shelf click adds to the cart")
	session._on_quit_answered(true)
	# Inside a refrigerator only the goods are clickable; the frame still reads "refrigerator".
	var fridge: Node3D = market.get_node("MarketInterior/Refrigerator")
	var fp := market.to_local(fridge.global_position)
	var ray_target := func(y: float, x: float) -> String:
		var rq := PhysicsRayQueryParameters3D.create(market.to_global(Vector3(x, y, fp.z - 2.5)), market.to_global(Vector3(x, y, fp.z + 1.0)))
		rq.collide_with_areas = true
		var rh := space.intersect_ray(rq)
		if rh.is_empty():
			return ""
		var tgt = preload("res://scripts/player/interaction_controller.gd").vocabulary_target(rh.collider, town)
		return str(tgt.get_meta("word_key", "")) if tgt != null else ""
	var top_hit: String = ray_target.call(F + 2.45, fp.x)
	check(top_hit == "refrigerator", "the fridge's outer frame is clickable as refrigerator: " + top_hit)
	var fridge_hits: Array = []
	for y in [.35, .5, .65, .85, 1.0, 1.15, 1.35, 1.5, 1.65, 1.85, 2.0]:
		for x in [-1.0, -.5, .5, 1.0]:
			fridge_hits.append(ray_target.call(F + y, fp.x + x))
	check(not fridge_hits.has("refrigerator"), "nothing inside the fridge reads as refrigerator, hits: " + str(fridge_hits.filter(func(k): return k == "refrigerator").size()))
	check(fridge_hits.any(func(k): return k != ""), "goods fridge_hits the fridge are clickable")
	# Mission code is gone.
	check(not ("quests" in game) and game.get("quests") == null, "Main no longer has quests")
	check(not FileAccess.file_exists("res://scripts/learning/learning_quests.gd"), "learning_quests.gd removed")
	print("customer order town: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
