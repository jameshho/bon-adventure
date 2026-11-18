extends SceneTree
## One view per supermarket department (positions are local to RelocatedSites/Supermarket).
## HOME=<isolated> godot --path . --resolution 1280x800 --script res://docs/evidence/supermarket-sections-20261117/capture.gd
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name()=="headless": quit(1); return
	var folder := "res://docs/evidence/supermarket-sections-20261117"
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
		["1-checkout", Vector3(-33,3.2,42), Vector3(-40.5,0.9,38)],
		["2-drinks-household", Vector3(-30.5,2.6,38.5), Vector3(-23,1.0,38.5)],
		["3-fruit", Vector3(-29,3.2,47.5), Vector3(-23.5,0.9,47)],
		["4-vegetables", Vector3(-33,2.8,39.5), Vector3(-33,0.9,44.3)],
		["5-pantry-aisle", Vector3(-41.3,2.2,41.5), Vector3(-41.3,1.0,48)],
		["5b-pantry-east-face", Vector3(-36.5,2.4,47.3), Vector3(-39.1,1.0,47.3)],
		["6-refrigerated", Vector3(-32.8,2.8,45.8), Vector3(-32.8,1.2,50)],
		["7-seafood", Vector3(-42.4,2.4,52.8), Vector3(-42.4,1.0,57)],
		["8-meat-deli", Vector3(-33,2.4,52.8), Vector3(-33,1.0,57)],
		["9-bakery", Vector3(-23.6,2.4,52.8), Vector3(-23.6,1.0,57)],
	]:
		camera.global_position = market.to_global(spec[1])
		camera.look_at(market.to_global(spec[2]))
		for i in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder)+"/"+spec[0]+".png")
	print("SECTIONS DONE")
	quit()
