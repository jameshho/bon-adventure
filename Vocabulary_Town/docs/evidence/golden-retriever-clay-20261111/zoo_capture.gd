extends SceneTree
## Two views of the clay golden retriever in its saved place in the town (zoo-close.png,
## zoo-location.png), and the ground height beside it. Run with an isolated HOME (README):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1200x800 --script res://docs/evidence/golden-retriever-clay-20261111/zoo_capture.gd
const OUT := "res://docs/evidence/golden-retriever-clay-20261111/"

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	root.size = Vector2i(1200, 800)
	root.always_on_top = true      # a covered window is not drawn on macOS, and the capture stalls
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var placed: Node3D = game.apartment.get_node("ParkZoo/GoldenRetrieverClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.current = true
	cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.5, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-close", aim, facing * 2.3 - across * 1.6 + Vector3(0, 0.35, 0)],
			["zoo-location", aim, facing * 10.0 - across * 6.0 + Vector3(0, 5.5, 0)]]:
		cam.global_position = view[1] + view[2]
		cam.look_at(view[1])
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
	var from := placed.global_position + Vector3(0.9, 3, 0)
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from - Vector3(0, 6, 0)))
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()
	quit()
