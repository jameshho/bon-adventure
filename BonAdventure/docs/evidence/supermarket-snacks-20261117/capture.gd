extends SceneTree
## Views of the sections changed on 17 Nov 2026 (snacks, cooler/home swap, coffee, fruit stand, fridges) (positions are local to RelocatedSites/Supermarket).
## HOME=<isolated> godot --path . --resolution 1280x800 --script res://docs/evidence/supermarket-snacks-20261117/capture.gd
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name()=="headless": quit(1); return
	var folder := "res://docs/evidence/supermarket-snacks-20261117"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 70.0
	var market: Node3D = game.apartment.get_node("RelocatedSites/Supermarket")
	for spec in [
		["1-entrance", Vector3(-33,2.0,34.5), Vector3(-33,1.4,45)],
		["2-drinks-cooler", Vector3(-30.5,2.4,38.2), Vector3(-25.6,1.3,38.2)],
		["3-coffee-close", Vector3(-28.0,2.1,37.6), Vector3(-26.1,1.9,38.6)],
		["4-home-goods", Vector3(-24.6,2.2,35.0), Vector3(-21.4,0.8,39.0)],
		["5-snacks-aisle", Vector3(-41.3,2.2,41.5), Vector3(-41.3,1.0,48)],
		["6-snacks-chocolate-face", Vector3(-45.3,2.0,44.0), Vector3(-43.5,0.9,48.0)],
		["7-snacks-cracker-face", Vector3(-36.5,2.4,47.3), Vector3(-39.1,1.0,47.3)],
		["8-fruit", Vector3(-29,3.2,47.5), Vector3(-23.5,0.9,47)],
		["9-refrigerated", Vector3(-32.8,2.8,45.8), Vector3(-32.8,1.2,50)],
	]:
		camera.global_position = market.to_global(spec[1])
		camera.look_at(market.to_global(spec[2]))
		for i in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder)+"/"+spec[0]+".png")
	print("SECTIONS DONE")
	quit()
