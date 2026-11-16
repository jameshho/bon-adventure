extends SceneTree
## The clay animals in the town's zoo (16 Nov 2026): an overview from the gate side (far views),
## two mid views and four close-ups, saved as <folder>/zoo-*.png. Time is frozen
## (Engine.time_scale 0) while the town loads, and the zoo's processing is then switched off, so
## the animals stand at their saved places; the time of day is held at noon. Two runs can be compared with views.gd's `diff`.
## Isolated HOME, full town:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/clay-sizes-20261116/zoo.gd -- <folder>
const VIEWS := ["zoo-overview", "zoo-front-left", "zoo-front-right", "zoo-zebra", "zoo-pig", "zoo-lion", "zoo-dog"]

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	var folder: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1200, 800)
	root.always_on_top = true
	Engine.time_scale = 0.0
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.day_night.pause()
	game.day_night.set_time(12 * 60.0)       # noon: the day-night cycle follows the clock
	var zoo: Node3D = game.apartment.get_node("ParkZoo")
	zoo.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	Engine.time_scale = 1.0
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 50
	var front: Vector3 = zoo.global_basis.z.normalized()
	var across: Vector3 = zoo.global_basis.x.normalized()
	var up := Vector3.UP
	var centre := Vector3.ZERO
	for name in ["Panda", "Red Panda", "Gorilla", "Deer", "Kangaroo", "Rhinoceros", "Zebra", "Bear Cub", "Flamingo", "Bear"]:
		centre += (zoo.get_node(name) as Node3D).global_position / 10.0
	var shots := [["zoo-overview", centre + front * 34 + up * 22, centre],
		["zoo-front-left", centre + front * 12 + across * 6 + up * 4, centre + across * 6 + up * 1.5],
		["zoo-front-right", centre + front * 12 - across * 7 + up * 4, centre - across * 7 + up * 1.5]]
	for name in ["Zebra", "Pig", "Lion", "Dog"]:
		var animal: Node3D = zoo.get_node(name)
		var height: float = (animal.get_meta("display_size") as Vector3).y * zoo.global_basis.get_scale().y
		var facing: Vector3 = animal.global_basis.z.normalized()      # wanderers face +Z
		var side: Vector3 = facing.cross(up).normalized()
		shots.append(["zoo-" + name.to_lower(), animal.global_position + (facing * 2.0 + side * 1.0 + up * 0.7) * maxf(height, 1.2), animal.global_position + up * height * 0.55])
	for view in shots:
		cam.global_position = view[1]
		cam.look_at(view[2])
		var img: Image = await shot()
		img.save_png(folder.path_join(view[0] + ".png"))
		print("ZOO VIEW ", view[0])
	game.free()
	quit()
