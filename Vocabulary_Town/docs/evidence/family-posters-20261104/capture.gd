extends SceneTree
## Family posters and Dr. Li views; graphics required, isolated HOME (Main saves progress):
## HOME=<scratch>/home VT_FOCUS="school, hospital" godot --path . --resolution 1600x1000 --script res://docs/evidence/family-posters-20261104/capture.gd
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var folder := "res://docs/evidence/family-posters-20261104"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var town: Node3D = game.apartment
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 65.0
	camera.far = 900.0
	# [name, building, eye, target]: building-local town coordinates.
	for spec in [
		["family-tree", "Buildings/School", Vector3(7.4, 2.5, 1.175), Vector3(0, 2.45, 1.175)],
		["family-tree-detail", "Buildings/School", Vector3(3.2, 2.4, 2.4), Vector3(0, 2.3, 2.4)],
		["rear-wall-posters", "Buildings/School", Vector3(-5.3, 2.4, -2.4), Vector3(-5.3, 2.6, 5.5)],
		["months-detail", "Buildings/School", Vector3(-2.3, 2.5, 2.4), Vector3(-2.3, 2.65, 5.5)],
		["dr-li", "Buildings/Hospital", Vector3(-1.2, 2.0, -19.5), Vector3(-3.7, 1.0, -13.9)],
		["dr-li-close", "Buildings/Hospital", Vector3(-3.0, 1.5, -16.4), Vector3(-3.7, 1.1, -13.9)],
		# After the L toggle to English mode (mode 0): the same posters in the native language.
		["english-family-tree", "Buildings/School", Vector3(7.4, 2.5, 1.175), Vector3(0, 2.45, 1.175), 0],
		["english-rear-wall-posters", "Buildings/School", Vector3(-5.3, 2.4, -2.4), Vector3(-5.3, 2.6, 5.5), 0],
	]:
		if spec.size() > 4:
			game.hud.language_changed.emit(spec[4])
		var building: Node3D = town.get_node(spec[1])
		camera.global_position = building.to_global(spec[2])
		camera.look_at(building.to_global(spec[3]))
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + "/" + spec[0] + ".png")
	print("FAMILY POSTERS CAPTURE done")
	quit()
