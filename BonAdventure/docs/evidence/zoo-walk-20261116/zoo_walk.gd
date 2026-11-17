extends SceneTree
## Every rigged clay zoo animal in the town (base steps pig_clay_walks, clay_animals_walk,
## 16 Nov 2026). Loads the full town at noon and saves:
##   walkers.png   one frame of each clay animal caught walking (side view, following it)
##   overview.png  the wild-animal lawn from above the gate
## and prints frame times over the zoo with every ClayAnimator running and then paused.
## Isolated HOME, full town:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/zoo-walk-20261116/zoo_walk.gd -- <folder>
const ANIMALS := ["Pig", "Cow", "Zebra", "Deer", "Rhinoceros", "Elephant", "Giraffe", "Lion", "Bear",
	"Bear Cub", "Panda", "Red Panda", "Dog", "Gorilla", "Kangaroo", "Duck", "Flamingo"]

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func frame_ms(frames: int) -> float:
	var start := Time.get_ticks_usec()
	for i in frames: await process_frame
	return (Time.get_ticks_usec() - start) / 1000.0 / frames

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
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 40
	var up := Vector3.UP
	var tiles: Array[Image] = []
	for name in ANIMALS:
		var animal: Node3D = zoo.get_node(name)
		var anim: Node = animal.find_child("ClayAnimator", true, false)
		var height: float = (animal.get_meta("display_size") as Vector3).y * zoo.global_basis.get_scale().y
		var follow := func() -> void:
			var facing: Vector3 = animal.global_basis.z.normalized()
			var side: Vector3 = facing.cross(up).normalized()
			var eye: Vector3 = animal.global_position + up * height * 0.5
			var space := cam.get_world_3d().direct_space_state
			for way in [1.0, -1.0, 0.0]:
				var spot: Vector3 = eye + (side * way if way != 0.0 else -facing) * height * 2.6
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, spot))
				if hit.is_empty() or way == 0.0:
					cam.global_position = spot
					break
			cam.look_at(animal.global_position + up * height * 0.45)
		var waited := 0
		for attempt in range(900):
			follow.call()
			await process_frame
			waited += 1
			if anim != null and str(animal.get("state")) == "walking" and float(anim.get("walk")) > 0.99:
				break
		var img: Image = await shot()
		print("ZOO WALK %s: animator %s state %s walk %.2f phase %.2f after %d frames" % [name, anim != null, animal.get("state"), anim.get("walk") if anim else -1.0, anim.get("phase") if anim else -1.0, waited])
		img.resize(300, 200)
		tiles.append(img)
	var sheet := Image.create(300 * 6, 200 * 3, false, tiles[0].get_format())
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, 300, 200), Vector2i((i % 6) * 300, (i / 6) * 200))
	sheet.save_png(folder.path_join("walkers.png"))
	var centre := Vector3.ZERO
	for name in ANIMALS:
		centre += (zoo.get_node(name) as Node3D).global_position / ANIMALS.size()
	var front: Vector3 = zoo.global_basis.z.normalized()
	cam.global_position = centre + front * 45 + up * 38
	cam.look_at(centre)
	cam.fov = 50
	for i in range(30): await process_frame
	(await shot()).save_png(folder.path_join("overview.png"))
	var on := await frame_ms(240)
	var animators := zoo.find_children("ClayAnimator", "", true, false)
	for a in animators: a.set_process(false)
	var off := await frame_ms(240)
	print("ZOO WALK frame ms over the zoo, %d animators running %.2f, paused %.2f (%s)" % [animators.size(), on, off, RenderingServer.get_video_adapter_name()])
	print("ZOO WALK blink list: %d in group clay_animals, ClayLife has %d" % [get_nodes_in_group("clay_animals").size(), game.clay_life.figures.size()])
	game.free()
	quit()
