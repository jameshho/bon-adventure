extends SceneTree
## Warehouse Phase 4 views (5 Nov 2026), with the HUD: Ramón's offer outside, the copy
## with the task card and Ramón's intro, the station and arrow, the leave question, and the
## return outside. Uses Main, which saves progress: run with an isolated HOME (README).
## godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/capture_game.gd
func _initialize(): run.call_deferred()
func snap(file: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(file)
func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var folder := "res://docs/evidence/warehouse-20261105"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	for i in 4: await physics_frame
	var town: Node3D = game.apartment
	var real: Node3D = town.get_node("Warehouse")
	var ramon: Node3D = town.get_node("Warehouse/Exterior/Ramon")
	var spot := real.to_global(Vector3(-2.6, .2, -4.6))
	game.player.global_position = spot
	var look := ramon.global_position - spot
	game.player.rotation.y = atan2(-look.x, -look.z)
	game.player.camera_yaw = game.player.rotation.y
	game.player.reset_camera()
	await snap(folder + "/game-ramon-calling.png")
	game.interaction.clerk_activated.emit(ramon)
	await create_timer(.6).timeout
	await snap(folder + "/game-offer.png")
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(1.6).timeout
	await snap(folder + "/game-intro.png")
	game.shop_panel.dialogue_closed.emit()
	await create_timer(.6).timeout
	await snap(folder + "/game-station.png")
	game.player.camera_yaw += 1.1
	game.player.reset_camera()
	await snap(folder + "/game-twin.png")
	game.popups.close_top()
	await snap(folder + "/game-leave.png")
	game.shop_panel.quit_answered.emit(true)
	await create_timer(1.6).timeout
	await snap(folder + "/game-back.png")
	print("WAREHOUSE GAME CAPTURE done")
	quit()
