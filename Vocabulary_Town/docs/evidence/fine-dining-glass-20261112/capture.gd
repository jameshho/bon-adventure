extends SceneTree
## Alta Cocina real arched windows (user, 12 Nov 2026; restaurant steps fine_dining_real_windows*,
## docs/guides/WINDOWS.md). Since 13 Nov 2026 one glass sheet per window (step fine_dining_single_glass_2):
## dark and reflective from the street, clear from the dining room. Also an ordinary window (no
## outdoors side): the electronics store's first side window from both sides (needs electronics).
## Needs a window; writes the views below into this folder and prints the four windows' settings.
##   HOME=<scratch>/home VT_FOCUS="restaurants, electronics" VT_SPAWN=none godot --path . --resolution 1400x700 \
##     --script res://docs/evidence/fine-dining-glass-20261112/capture.gd
const FOLDER := "res://docs/evidence/fine-dining-glass-20261112/"
const GlassWindow := preload("res://scripts/world/glass_window.gd")

func _initialize(): run.call_deferred()

func shot(camera: Camera3D, room: Node3D, from: Vector3, to: Vector3, file: String) -> void:
	camera.global_position = room.to_global(from)
	camera.look_at(room.to_global(to))
	for i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + file))
	print("FACADE saved ", file)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("editing_snapshot", true)
	root.add_child(game)
	preload("res://scripts/world/garden_rendering.gd").new().build(game.apartment)
	preload("res://scripts/world/render_culling.gd").new().build(game)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	game.day_night.pause()
	game.hud.hide()
	var town: Node3D = game.apartment
	# Room frame (Restaurants/Pizza): front wall at z -7.9, windows centred x = ±8.5; the street is -z.
	var room: Node3D = town.get_node("Restaurants/Pizza")
	for w in get_nodes_in_group(GlassWindow.GROUP):
		var at: Vector3 = room.to_local(w.global_position)
		if absf(absf(at.x) - 8.5) < 0.1 and at.z < -7.5 and at.z > -8.3:
			var facing: float = (room.global_transform.affine_inverse().basis * w.global_transform.basis.z).z
			print("FACADE window %s z=%.3f outside=%d see_through=%s tint=%s/%.2f outside_tint=%s/%.2f +Z faces %s glass parts=%d" % [town.get_path_to(w), at.z, w.outside, w.see_through, w.tint.to_html(false), w.transparency, w.outside_tint.to_html(false), w.outside_transparency, "room" if facing > 0 else "street", w.glass_meshes().size()])
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.fov = 70
	game.day_night.set_time(12 * 60)
	await shot(camera, room, Vector3(0, 2.6, -21), Vector3(0, 3.2, -7.9), "street_noon.png")
	await shot(camera, room, Vector3(0, 2.0, 5.5), Vector3(0, 2.8, -7.9), "room_noon.png")
	await shot(camera, room, Vector3(8.5, 1.8, -4.5), Vector3(8.5, 2.6, -7.9), "room_window_noon.png")
	await shot(camera, room, Vector3(-1.5, 1.7, -12.5), Vector3(-8.5, 2.6, -8.1), "street_angle_noon.png")
	var plain: Node3D = null
	for w in get_nodes_in_group(GlassWindow.GROUP):
		if str(town.get_path_to(w)).begins_with("Buildings/ElectronicsStore/WindowPane"):
			plain = w
			break
	if plain != null:
		print("FACADE plain window %s outside=%d" % [town.get_path_to(plain), plain.outside])
		for side in [[1.0, "plain_a_noon.png"], [-1.0, "plain_b_noon.png"]]:
			var n: Vector3 = plain.global_transform.basis.z.normalized()
			camera.global_position = plain.global_position + n * side[0] * 2.6 + Vector3(0, 0.2, 0)
			camera.look_at(plain.global_position)
			for i in range(20):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + side[1]))
	game.day_night.set_time(21 * 60)
	await shot(camera, room, Vector3(0, 2.6, -21), Vector3(0, 3.2, -7.9), "street_night.png")
	await shot(camera, room, Vector3(8.5, 1.8, -4.5), Vector3(8.5, 2.6, -7.9), "room_window_night.png")
	quit(0)
