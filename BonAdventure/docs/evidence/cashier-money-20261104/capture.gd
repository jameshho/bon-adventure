extends SceneTree
## Cashier money screen views (4 Nov 2026); graphics required, isolated HOME advised.
## godot --path . --resolution 1920x1200 --script res://docs/evidence/cashier-money-20261104/capture.gd  (suffix desktop)
## godot --path . --resolution 800x1400 --script res://docs/evidence/cashier-money-20261104/capture.gd   (suffix narrow)
const FOLDER := "res://docs/evidence/cashier-money-20261104"
func _initialize(): run.call_deferred()
func shot(name: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + "/" + name + ".png")
func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var suffix := "narrow" if root.size.x < root.size.y else "desktop"
	var session = game.get_node("CashierSession_supermarket")
	session.set_process(false)
	var panel = session.panel
	var money = session.money
	var market: Node3D = game.apartment.get_node("RelocatedSites/Supermarket")
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 60.0
	camera.far = 900.0
	camera.global_position = market.to_global(Vector3(-34.2, 1.6, 41.0))
	camera.look_at(session.cashier.global_position + Vector3(0, 0.7, 0))
	session.request_cents = 14738
	session._request_variant = 1
	game.interaction.clerk_activated.emit(session.cashier)
	session.request_cents = 14738
	session._show(session._money_lines().request, [session._choice("cashier_count", "cashier_count"), session._choice("cashier_bye", "reply_no")], 0.0)
	await create_timer(.6).timeout
	await shot("request-" + suffix)
	panel.toggle_translation()
	await shot("request-translated-" + suffix)
	panel.toggle_translation()
	panel.choice_pressed.emit("cashier_count")
	await create_timer(.4).timeout
	await shot("money-empty-" + suffix)
	for id in ["bill_100", "bill_20", "bill_20", "bill_5", "bill_1", "bill_1", "coin_25", "coin_10", "coin_1", "coin_1", "coin_1"]:
		money.add_piece(id)
	await shot("money-selected-" + suffix)
	money.toggle_translation()
	await shot("money-translated-" + suffix)
	money.toggle_translation()
	money.remove_piece("coin_1")
	money._submit_button.pressed.emit()
	await create_timer(.4).timeout
	await shot("wrong-" + suffix)
	panel.choice_pressed.emit("cashier_why")
	await create_timer(.4).timeout
	await shot("explain-" + suffix)
	panel.choice_pressed.emit("cashier_retry")
	money.close_requested.emit()
	await create_timer(.4).timeout
	await shot("quit-" + suffix)
	panel.choice_pressed.emit("cashier_stay")
	money.clear()
	for i in 14: money.add_piece("coin_10")
	for i in 3: money.add_piece("coin_25")
	for i in 8: money.add_piece("bill_1")
	await shot("money-crowded-" + suffix)
	quit(0)
