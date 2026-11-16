extends SceneTree

# Renders plush characters inside the real game, beside BonBon at the home spawn.
# godot --path . --resolution 1280x800 --script res://docs/evidence/town-checks/capture_character.gd -- res://scenes/characters/lion_plush.tscn [more .tscn ...] [output_dir]
# Writes lineup.png (the spawn view), then per character front, side, back,
# two three-quarter views and a size comparison with BonBon, in <output_dir>/<scene name>/.
# Output defaults to user://character-review/. Only reads learner saves.

func _initialize() -> void:
	run.call_deferred()

func shot(folder: String, name: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

func bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var part: AABB = mi.global_transform * mi.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box

func run() -> void:
	var scenes: Array[String] = []
	var base := "user://character-review"
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with(".tscn"):
			scenes.append(arg)
		else:
			base = arg
	if scenes.is_empty():
		push_error("Pass character scenes after --, e.g. -- res://scenes/characters/lion_plush.tscn")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(base)
	root.size = Vector2i(1280, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	# Main's front-yard lineup, as the learner first sees it.
	await shot(base, "lineup")
	# Stop BonBon's controller so it cannot reclaim the active camera.
	game.player.set_physics_process(false)
	game.player.set_process(false)
	# Pause hover highlighting too: it would keep pointing at the characters freed below.
	game.interaction.set_physics_process(false)
	# The named house characters stay where Main put them; the subject is placed
	# beside BonBon at the spawn, away from them.
	var cam := Camera3D.new()
	cam.fov = 40
	game.add_child(cam)
	cam.current = true
	var bonbon: Node3D = game.player.get_node("Visual")
	print("bonbon bounds ", bounds(bonbon))
	for path in scenes:
		var folder := base.path_join(path.get_file().get_basename())
		DirAccess.make_dir_recursive_absolute(folder)
		var character: Node3D = load(path).instantiate()
		game.add_child(character)
		var facing: Basis = game.player.global_transform.basis
		character.global_position = game.player.global_position + facing.x * 2.2
		var mid: Vector3 = (character.global_position + game.player.global_position) * 0.5 + Vector3.UP * 1.1
		cam.global_position = mid - facing.z * 8.0 + Vector3.UP * 0.6
		# Face the comparison camera; BonBon's own turn may still be settling at startup.
		character.look_at(Vector3(cam.global_position.x, character.global_position.y, cam.global_position.z), Vector3.UP)
		print(path.get_file(), " bounds ", bounds(character))
		cam.look_at(mid, Vector3.UP)
		bonbon.visible = true
		await shot(folder, "with_bonbon")
		bonbon.visible = false
		var target := character.global_position + Vector3.UP * 1.15
		var views := {"front": 0.0, "three_quarter": 0.7, "side": PI * 0.5, "back": PI, "other_three_quarter": -0.9}
		for key in views:
			var dir: Vector3 = character.global_transform.basis * Vector3(sin(views[key]), 0.12, -cos(views[key]))
			cam.global_position = target + dir.normalized() * 4.6
			cam.look_at(target, Vector3.UP)
			await shot(folder, key)
		character.free()
	print("saved views to ", ProjectSettings.globalize_path(base))
	game.queue_free()
	await process_frame
	quit()
