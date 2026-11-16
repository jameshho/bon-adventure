extends SceneTree
## Customer order views (3 Nov 2026); graphics required. Isolated user directory advised.
## godot --path . --resolution 1280x800 --script res://docs/evidence/customer-order-20261103/capture.gd
## Writes PNGs into this folder only.
const FOLDER := "res://docs/evidence/customer-order-20261103"
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
	var market: Node3D = game.apartment.get_node("RelocatedSites/Supermarket")
	var session = game.get_node("ShopSession_supermarket")
	session.set_process(false)
	var panel = session.panel
	var clerk: Node3D = session.clerk
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 60.0
	camera.far = 900.0
	# Larger products and the fridge (HUD hidden); market-local eye -> target.
	game.hud.hide()
	camera.global_position = game.player.global_position + Vector3(0, 2.2, 0) + (game.player.global_position - market.to_global(Vector3(-33, .1, 34.25))).normalized() * 4.5
	camera.look_at(game.player.global_position + Vector3(0, 1.2, 0) + (market.to_global(Vector3(-33, .1, 34.25)) - game.player.global_position) * .5)
	print("CAPTURE spawn ", market.to_local(game.player.global_position), " yaw ", game.player.rotation.y)
	await shot("spawn-view")
	for spec in [["bigger-fruit", Vector3(-31.5, 2.0, 40.5), Vector3(-24, 1.0, 47)], ["bigger-vegetables", Vector3(-29, 1.9, 40.8), Vector3(-34, 1.0, 45)],
			["bigger-pantry", Vector3(-41.3, 1.9, 42.5), Vector3(-41.3, 1.0, 51)], ["bigger-fridge", Vector3(-34, 1.7, 46.2), Vector3(-34, 1.1, 50)],
			["bigger-cooler", Vector3(-24.5, 1.8, 37.5), Vector3(-20.5, 1.2, 37.5)]]:
		camera.global_position = market.to_global(spec[1])
		camera.look_at(market.to_global(spec[2]))
		await shot(spec[0])
	game.hud.show()
	camera.global_position = market.to_global(Vector3(-35.2, 1.7, 26.2))
	camera.look_at(clerk.global_position + Vector3(0, 1.0, 0))
	session._entered()
	session._animate(.35)
	await shot("clerk-needs-help")
	session._on_clerk(clerk)
	await create_timer(.7).timeout
	await shot("dialogue-question")
	panel.toggle_translation()
	await shot("dialogue-translated")
	panel.toggle_translation()
	panel.choice_pressed.emit("yes")
	await create_timer(.5).timeout
	await shot("dialogue-order-intro")
	panel.dialogue_closed.emit()
	await create_timer(.6).timeout
	var order = session.order
	var keys: Array = order.remaining.keys()
	for i in 2:
		order.add_to_cart(keys[0])
	for key in session.pool:
		if not order.remaining.has(key):
			order.add_to_cart(key)
			break
	panel.update_cart(session._cart_data())
	await shot("cart")
	panel.toggle_translation()
	await shot("cart-translated")
	panel.toggle_translation()
	session._ask_quit()
	await shot("quit-prompt")
	panel.quit_answered.emit(false)
	panel.done_pressed.emit()
	await shot("return-to-clerk")
	panel.dialogue_closed.emit()
	session._on_clerk(clerk)
	await create_timer(.7).timeout
	await shot("retry-offer")
	print("CUSTOMER ORDER CAPTURE done")
	quit()
