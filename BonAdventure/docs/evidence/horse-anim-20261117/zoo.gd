extends SceneTree
## The rigged clay horse in the town (base step horse_clay_walks, 17 Nov 2026), after
## docs/evidence/zoo-walk-20261116/zoo_walk.gd. Loads the full town at noon and saves into the
## folder given after --:
##   zoo-context.png  the tiger in the farm lawn from the visitors' side, standing
##   zoo-close.png    close, three-quarter view
##   zoo-walk.png     8 frames 0.12 s apart following it from the side while it walks
## and prints its place, size, word, blink list membership and the ground beside it.
## Isolated HOME, full town:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/horse-anim-20261117/zoo.gd -- <folder>

func _initialize() -> void:
	run.call_deferred()

## Drawn on demand: waiting for the window's own frame stalls when the window is covered.
func shot() -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()

func run() -> void:
	var folder: String = OS.get_cmdline_user_args()[0]
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
	var tiger: Node3D = zoo.get_node("Horse")
	var anim: Node = tiger.find_child("ClayAnimator", true, false)
	var size: Vector3 = tiger.get_meta("display_size")
	var height: float = size.y * zoo.global_basis.get_scale().y
	var names := []
	for c in tiger.get_children(): names.append(str(c.name))
	print("ZOO HORSE: word %s, children %s, model %s, scale %.4f, position %s, home %s, display size %s, world height %.3f" % [
			tiger.get_meta("word_key"), names, tiger.get_node("ClayHorse").scene_file_path, tiger.scale.x, tiger.position, tiger.get("home"), size, height])
	var bounds: AABB = tiger.call("_visible_bounds")
	print("ZOO HORSE: visible height %.3f (zoo units), soles at y %.3f" % [bounds.size.y * tiger.scale.y, tiger.position.y + bounds.position.y * tiger.scale.y])
	var space := tiger.get_world_3d().direct_space_state
	var beside := tiger.global_position + Vector3(2.2, 0, 0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(beside + Vector3(0, 3, 0), beside - Vector3(0, 3, 0)))
	print("ZOO HORSE: world y %.3f, ground beside it %s" % [tiger.global_position.y, hit.get("position", "none")])
	print("ZOO HORSE: in group clay_animals %s, in clay_life %s, animator %s" % [
			tiger.get_node("ClayHorse").is_in_group("clay_animals"), game.clay_life.figures.has(tiger.get_node("ClayHorse")), anim != null])
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 40
	var up := Vector3.UP
	# Standing: hold the wanderer still for the two portraits.
	tiger.set_physics_process(false)
	tiger.set_process(false)
	for i in range(30): await process_frame
	var facing: Vector3 = tiger.global_basis.z.normalized()
	var side: Vector3 = facing.cross(up).normalized()
	var aim: Vector3 = tiger.global_position + up * height * 0.5
	cam.global_position = aim + facing * height * 4.2 + side * height * 2.0 + up * height * 1.6
	cam.look_at(aim)
	for i in range(10): await process_frame
	(await shot()).save_png(folder.path_join("zoo-context.png"))
	cam.global_position = aim + facing * height * 1.9 + side * height * 1.3 + up * height * 0.25
	cam.look_at(aim)
	for i in range(10): await process_frame
	(await shot()).save_png(folder.path_join("zoo-close.png"))
	# Walking: let it wander, wait until the walk has faded in, then 8 frames from the side.
	tiger.set_physics_process(true)
	tiger.set_process(true)
	var follow := func() -> void:
		var f: Vector3 = tiger.global_basis.z.normalized()
		var s: Vector3 = f.cross(up).normalized()
		var eye: Vector3 = tiger.global_position + up * height * 0.5
		cam.global_position = eye + s * height * 2.6 + up * height * 0.15
		cam.look_at(tiger.global_position + up * height * 0.45)
	var waited := 0
	for attempt in range(1500):
		follow.call()
		await process_frame
		waited += 1
		if str(tiger.get("state")) == "walking" and float(anim.get("walk")) > 0.99:
			break
	print("ZOO HORSE: state %s, walk %.2f after %d frames" % [tiger.get("state"), anim.get("walk"), waited])
	var tiles: Array[Image] = []
	for k in 8:
		for i in 7:
			follow.call()
			await process_frame
		follow.call()
		var img: Image = await shot()
		img.resize(450, 300)
		tiles.append(img)
	var sheet := Image.create(450 * 4, 300 * 2, false, tiles[0].get_format())
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, 450, 300), Vector2i((i % 4) * 450, (i / 4) * 300))
	sheet.save_png(folder.path_join("zoo-walk.png"))
	print("ZOO HORSE saved")
	game.free()
	quit()
