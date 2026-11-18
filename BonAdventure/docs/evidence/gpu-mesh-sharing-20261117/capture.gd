extends SceneTree
## Rendered views for the shared meshes (17 Nov 2026): two plush characters of the same kind that
## now share their meshes, plush characters in costumes (shared garments), BonBon, and the
## Mystery House doors and trim (merged copies in mystery.scn). Prints which characters share a
## torso mesh. Overwrites the PNGs in this folder (or VT_CAPTURE_OUT). Graphics, isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/gpu-mesh-sharing-20261117/capture.gd
var game: Node
var camera: Camera3D

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func out_dir() -> String:
	var custom := OS.get_environment("VT_CAPTURE_OUT")
	return custom if custom != "" else ProjectSettings.globalize_path("res://docs/evidence/gpu-mesh-sharing-20261117/")

## Camera `distance` m in front of `target` (plush characters face local -Z), at `height`.
func shoot(file: String, target: Node3D, distance: float, height: float, side := 0.0) -> void:
	var forward := -target.global_transform.basis.z.normalized()
	var right := target.global_transform.basis.x.normalized()
	var focus := target.global_position + Vector3.UP * height * 0.6
	var spot := target.global_position + forward * distance + right * side + Vector3.UP * height
	game.player.global_position = spot - Vector3.UP * height
	camera.global_position = spot
	camera.look_at(focus, Vector3.UP)
	await frames(30)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir().path_join(file))
	print("CAPTURE: ", file, " at ", target.get_path())

func torso(figure: Node) -> Mesh:
	var node := figure.get_node_or_null("Torso/Visual") as MeshInstance3D
	return node.mesh if node != null else null

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(60)
	game.day_night.set_time(11.5 * 60.0)
	game.player.set_physics_process(false)
	game.player.visible = false
	camera = Camera3D.new()
	camera.far = 300
	root.add_child(camera)
	camera.make_current()
	var figures: Array = []
	for node in root.find_children("*", "Node3D", true, false):
		if node.scene_file_path.begins_with("res://scenes/characters/") and torso(node) != null:
			figures.append(node)
	# Characters sharing one torso mesh object: mesh -> figures.
	var by_mesh := {}
	for figure in figures:
		var mesh := torso(figure)
		if not by_mesh.has(mesh):
			by_mesh[mesh] = []
		by_mesh[mesh].append(figure)
	var shared_groups := 0
	var pair: Array = []
	for mesh in by_mesh:
		var group: Array = by_mesh[mesh]
		if group.size() < 2:
			continue
		shared_groups += 1
		print("SHARED torso (%d): %s" % [group.size(), ", ".join(group.map(func(f): return String(f.name)))])
		# The closest two of a kind, for one view of both.
		for i in group.size():
			for j in range(i + 1, group.size()):
				var gap: float = group[i].global_position.distance_to(group[j].global_position)
				if gap < 8.0 and (pair.is_empty() or gap < pair[2]):
					pair = [group[i], group[j], gap]
	print("SHARED: %d plush characters, %d torso meshes, %d shared by two or more" % [figures.size(), by_mesh.size(), shared_groups])
	if not pair.is_empty():
		var middle := Node3D.new()
		root.add_child(middle)
		middle.global_transform = pair[0].global_transform
		middle.global_position = (pair[0].global_position + pair[1].global_position) * 0.5
		print("PAIR: ", pair[0].get_path(), " + ", pair[1].get_path())
		await shoot("same-kind-pair.png", middle, 3.0 + pair[2], 1.6)
	# Same kind in different rooms: one view each (they share one torso mesh, printed above).
	for name in ["CatWaiter", "CatCashier", "BeagleWaiter", "BeagleDoctor"]:
		for figure in figures:
			if String(figure.name) == name:
				await shoot("same-kind-%s.png" % name.to_lower(), figure, 3.0, 1.9)
				break
	var dressed: Array = figures.filter(func(f): return f.get_node_or_null("Costume") != null)
	var wanted := ["BearChef", "PilotBruno", "GoldenCashier"]
	var shot := 0
	for figure in dressed:
		if String(figure.name) in wanted:
			await shoot("costume-%s.png" % String(figure.name).to_lower(), figure, 2.8, 2.3)
			shot += 1
	if shot == 0 and not dressed.is_empty():
		await shoot("costume.png", dressed[0], 3.2, 1.5)
	var town: Node3D = game.apartment
	for door_path in ["MysteryHouse/DoorWall/MysteryDoor A", "MysteryHouse/DoorWall/MysteryDoor B"]:
		var door := town.get_node_or_null(door_path) as Node3D
		if door == null:
			print("MISSING: ", door_path)
			continue
		var file: String = "mystery-" + door_path.get_file().to_lower().replace(" ", "-") + "-%s.png"
		await shoot(file % "front", door, 5.0, 1.8)
		var flipped := Node3D.new()
		root.add_child(flipped)
		flipped.global_transform = door.global_transform.rotated_local(Vector3.UP, PI)
		await shoot(file % "back", flipped, 5.0, 1.8)
	quit()
