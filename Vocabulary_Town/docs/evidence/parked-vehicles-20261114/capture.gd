extends SceneTree
## Parked vehicles (14 Nov 2026): rendered views of filled lots and a road-side car, and the
## render cost of the 29 added vehicles (draw calls, primitives, frame time with them shown and
## hidden, same views). Overwrites the PNGs here and prints "PERF" lines. Graphics, isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/parked-vehicles-20261114/capture.gd
const VIEWS := [
	# [file, camera (town), look at (town)]
	["restaurant-lot.png", Vector3(-45, 10, 70), Vector3(-45, 0, 48)],
	["bakery-electronics-lots.png", Vector3(100, 10, 150), Vector3(119, 0, 150)],
	["hospital-school-lots.png", Vector3(33, 12, 190), Vector3(33, 0, 211)],
	["roadside-car.png", Vector3(76, 4, 186), Vector3(82.5, 0.5, 196)],
	["overview.png", Vector3(0, 70, 60), Vector3(0, 0, 150)],
	["warehouse-lot.png", Vector3(-35, 12, 194), Vector3(-35, 0, 214)],
]
var game: Node
var camera: Camera3D
var added: Array[Node3D] = []
func _initialize(): run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func measure() -> Dictionary:
	await frames(8)
	var start := Time.get_ticks_usec()
	await frames(60)
	var frame_ms := (Time.get_ticks_usec() - start) / 60000.0
	await RenderingServer.frame_post_draw
	return {"draws": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"ms": frame_ms}

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(40)
	game.day_night.set_time(11.5 * 60.0)
	game.player.set_physics_process(false)
	game.player.visible = false
	var town: Node3D = game.apartment
	print("MAP: reference_map_bounds (town units) ", town.get_meta("reference_map_bounds"))
	for vehicle in town.get_node("Vehicles").get_children():
		if String(vehicle.name).begins_with("Parked ") or String(vehicle.name).begins_with("Road-side "): added.append(vehicle)
	camera = Camera3D.new()
	camera.far = 900
	root.add_child(camera)
	camera.make_current()
	var meshes := 0
	for vehicle in added: meshes += vehicle.find_children("*", "MeshInstance3D", true, false).size()
	print("PERF: ", added.size(), " vehicles added, ", meshes, " mesh instances (default graphics settings)")
	for view in VIEWS:
		camera.global_position = town.to_global(view[1])
		camera.look_at(town.to_global(view[2]), Vector3.UP)
		var shown := await measure()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/evidence/parked-vehicles-20261114/" + view[0]))
		for vehicle in added: vehicle.visible = false
		var hidden := await measure()
		for vehicle in added: vehicle.visible = true
		print("PERF %s: draw calls %d -> %d (+%d), objects %d -> %d, primitives %d -> %d, frame %.2f -> %.2f ms" % [view[0], hidden.draws, shown.draws, shown.draws - hidden.draws, hidden.objects, shown.objects, hidden.primitives, shown.primitives, hidden.ms, shown.ms])
	quit()
