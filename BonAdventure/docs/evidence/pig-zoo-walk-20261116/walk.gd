extends SceneTree
## The rigged clay pig in the town's zoo (base step pig_clay_walks, 16 Nov 2026): loads the full
## town at noon, makes ParkZoo/Pig walk (park_animals.gd), follows it from the side and saves
## walk.png (8 frames, 0.12 s apart) and context.png (a wider view with its neighbours). Prints
## the animator's walk/speed and whether Main's ClayLife blinker has the pig.
## Isolated HOME, full town:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/pig-zoo-walk-20261116/walk.gd -- <folder>

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	var folder: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(900, 600)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.day_night.pause()
	game.day_night.set_time(12 * 60.0)
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var zoo: Node3D = game.apartment.get_node("ParkZoo")
	var pig: Node3D = zoo.get_node("Pig")
	var anim: Node = pig.get_node("ClayPig/ClayAnimator")
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 40
	var height: float = (pig.get_meta("display_size") as Vector3).y * zoo.global_basis.get_scale().y
	# The animator only poses an animal on screen, so the camera follows the pig from the start;
	# wait for a walking bout that has reached full stride.
	var frames: Array[Image] = []
	var up := Vector3.UP
	var follow := func() -> void:
		var facing: Vector3 = pig.global_basis.z.normalized()
		var side: Vector3 = facing.cross(up).normalized()
		cam.global_position = pig.global_position + side * height * 3.2 + up * height * 0.6
		cam.look_at(pig.global_position + up * height * 0.45)
	for attempt in range(1200):
		follow.call()
		await process_frame
		if str(pig.get("state")) == "walking" and float(anim.get("walk")) > 0.99 and float(pig.get("_timer")) > 1.5:
			break
	print("PIG ZOO: state %s walk %.2f speed %.3f" % [pig.get("state"), anim.get("walk"), anim.get("speed")])
	for i in range(8):
		follow.call()
		var img: Image = await shot()
		frames.append(img)
		print("PIG ZOO frame %d: state %s walk %.2f phase %.2f" % [i, pig.get("state"), anim.get("walk"), anim.get("phase")])
		var until := Time.get_ticks_msec() + 120
		while Time.get_ticks_msec() < until:
			follow.call()
			await process_frame
	var w := frames[0].get_width() / 2
	var h := frames[0].get_height() / 2
	var strip := Image.create(w * 4, h * 2, false, frames[0].get_format())
	for i in frames.size():
		var f := frames[i]
		f.resize(w, h)
		strip.blit_rect(f, Rect2i(0, 0, w, h), Vector2i((i % 4) * w, (i / 4) * h))
	strip.save_png(folder.path_join("walk.png"))
	var facing2: Vector3 = pig.global_basis.z.normalized()
	cam.global_position = pig.global_position + (facing2 * 6 + facing2.cross(up) * 4) * height + up * height * 2.5
	cam.look_at(pig.global_position + up * height * 0.4)
	for i in range(4): await process_frame
	(await shot()).save_png(folder.path_join("context.png"))
	var life = game.get("clay_life")
	print("PIG ZOO blink: ClayLife %s, pig in its list %s, group size %d" % [life != null, life != null and life.figures.has(pig.get_node("ClayPig")), get_nodes_in_group("clay_animals").size()])
	game.free()
	quit()
