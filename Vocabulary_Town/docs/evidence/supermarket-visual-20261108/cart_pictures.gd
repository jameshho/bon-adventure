extends SceneTree
## Customer-order list and cart with product pictures (8 Nov 2026); graphics required.
## HOME=<scratch> VT_FOCUS=supermarket godot --path . --resolution 1280x800 --script res://docs/evidence/supermarket-visual-20261108/cart_pictures.gd
## Writes props-cart.png into this folder only (drives the 3 Nov customer-order flow like
## docs/evidence/customer-order-20261103/capture.gd; use an isolated HOME).
const FOLDER := "res://docs/evidence/supermarket-visual-20261108"
func _initialize(): run.call_deferred()
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
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 60.0
	camera.global_position = market.to_global(Vector3(-31.5, 2.0, 40.5))
	camera.look_at(market.to_global(Vector3(-24, 1.0, 47)))
	session._entered()
	session._on_clerk(session.clerk)
	await create_timer(.7).timeout
	panel.choice_pressed.emit("yes")
	await create_timer(.5).timeout
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
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + "/props-cart.png")
	print("CART PICTURES order ", order.remaining.keys(), " cart ", order.cart.keys())
	quit()
