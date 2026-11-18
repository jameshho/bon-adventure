extends SceneTree
## Render batching and Low AA (17 Nov 2026): draw calls, triangles and video memory on Low at a
## phone-like 3D size (1560 x 720: an iPhone's 390 CSS lines raised to LOW_WEB_MIN_LINES 720), in
## the home guest-suite bedroom (the tutorial start) and the street at spawn, plus the video
## memory of MSAA off / 2x / 4x in the street, and the unbatched meshes near the bedroom grouped
## by owner. VT_PROBE_SHOTS=1 also saves rendered views into this folder (overwrites the PNGs).
## Prints "PROBE" lines only. Graphics, isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/render-batching-20261117/probe.gd
const ModularTown := preload("res://scripts/world/modular_town.gd")
const DIR := "res://docs/evidence/render-batching-20261117/"
const BED_SPOT := Vector3(-4.4, 0.0, -9.6)
const BED_LOOK := Vector3(-1.0, 0.0, 0.0)
var game: Node
var shots := OS.get_environment("VT_PROBE_SHOTS") == "1"

func _initialize(): run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func info(what: int) -> int:
	return RenderingServer.get_rendering_info(what)

func measure(label: String) -> void:
	await frames(30)
	await RenderingServer.frame_post_draw
	print("PROBE %s: draws %d, objects %d, triangles %.2f M, video %.1f MB (textures %.1f, buffers %.1f), msaa %d" % [label,
		info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1e6,
		info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0,
		info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0,
		info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0,
		root.msaa_3d])

func shot(file: String) -> void:
	if not shots:
		return
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR + file))
	print("PROBE shot ", file)

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(40)
	game.day_night.set_time(12.0 * 60.0)
	var player = game.player
	var settings = preload("res://scripts/core/game_settings.gd").shared()
	print("PROBE graphics=%s window=%s 3d_scale=%.2f" % [settings.graphics, root.get_visible_rect().size, root.scaling_3d_scale])
	var street_pos: Vector3 = player.global_position
	var street_yaw: float = player.camera_yaw
	await frames(240)   # indoor_visibility measures objects over ~2.6 s
	await measure("street")
	if shots:
		var low_msaa: int = root.msaa_3d
		root.msaa_3d = Viewport.MSAA_DISABLED
		await shot("street-aa-off.png")
		root.msaa_3d = low_msaa
		await shot("street-aa-low.png")
	for mode in [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]:
		var keep: int = root.msaa_3d
		root.msaa_3d = mode
		await measure("street msaa=%d" % mode)
		root.msaa_3d = keep
	await measure("street again")
	var town: Node3D = game.apartment
	var home: Node3D = ModularTown.building(town, "home")
	_place(player, home)
	await frames(90)
	await measure("bedroom")
	await shot("bedroom.png")
	_unbatched(player.global_position, home)
	var leaves := 0
	var hidden := 0
	for leaf in home.find_children("Merged leaf", "MeshInstance3D", true, false):
		leaves += 1
	for door in game.doors:
		if is_instance_valid(door) and home.is_ancestor_of(door):
			for m: MeshInstance3D in door.find_children("*", "MeshInstance3D", true, false):
				if m.has_meta("render_batched") and not m.visible: hidden += 1
	print("PROBE home doors: %d merged leaf meshes, %d originals hidden" % [leaves, hidden])
	var shadowed := []
	for light: Light3D in root.find_children("*", "Light3D", true, false):
		if light.shadow_enabled and light.is_visible_in_tree() and not light is DirectionalLight3D:
			shadowed.append(str(light.name))
	print("PROBE shadowed omni/spot lights: %d %s" % [shadowed.size(), shadowed.slice(0, 8)])
	print("PROBE reflection probes: %d" % root.find_children("*", "ReflectionProbe", true, false).size())
	for v: SubViewport in root.find_children("*", "SubViewport", true, false):
		if v.render_target_update_mode != SubViewport.UPDATE_DISABLED:
			print("PROBE subviewport %s size %s mode %d msaa %d 3d %s" % [v.get_path(), v.size, v.render_target_update_mode, v.msaa_3d, not v.disable_3d])
	# Facing the house (the earlier "guest suite, facing the house" view).
	player.camera_yaw += PI
	player.rotation.y = player.camera_yaw
	await measure("bedroom facing house")
	await shot("bedroom-facing-house.png")
	# The nearest door: opening (mid swing) and open.
	var nearest: Node3D = null
	for door in game.doors:
		if is_instance_valid(door) and home.is_ancestor_of(door) and str(game.doors[door].get("type", "")) == "hinge":
			if nearest == null or door.global_position.distance_to(player.global_position) < nearest.global_position.distance_to(player.global_position):
				nearest = door
	if nearest != null:
		print("PROBE door ", home.get_path_to(nearest))
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.global_position = nearest.global_position + nearest.global_basis.z.normalized() * 2.6 + Vector3.UP * 1.9
		cam.look_at(nearest.global_position + Vector3.UP * 1.2)
		cam.make_current()
		await shot("door-closed.png")
		game.doors[nearest]["open"] = true
		await frames(4)
		if shots:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR + "door-opening.png"))
		await shot("door-open.png")
		game.doors[nearest]["open"] = false
		await frames(60)
		cam.queue_free()
		player.camera.make_current()
	# The mahjong table (front yard), from the player's seat side, raised.
	var table := home.find_child("MahjongTable", true, false) as Node3D
	if table != null:
		player.global_position = table.global_position + table.global_basis.z * 4.0
		await frames(60)
		await measure("mahjong yard")
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.global_position = table.to_global(Vector3(0, 2.9, 0.35))
		cam.look_at(table.to_global(Vector3(0, 1.0, 0)))
		cam.make_current()
		await shot("mahjong-table.png")
		await measure("mahjong close-up")
	quit()

func _place(player, home: Node3D) -> void:
	player.global_position = home.to_global(BED_SPOT + Vector3(0, .1, 0))
	var forward: Vector3 = home.global_basis * BED_LOOK
	player.rotation.y = atan2(-forward.x, -forward.z)
	player.camera_yaw = player.rotation.y
	player.reset_camera()

# Visible, unbatched MeshInstance3D within 30 m, grouped by their top owner under the home site
# (or the town root) and the reason the static batching left them out, with surface counts.
func _unbatched(at: Vector3, home: Node3D) -> void:
	var groups := {}
	var reasons := {}
	var total := 0
	for node: MeshInstance3D in game.apartment.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null or not node.is_visible_in_tree() or node.has_meta("render_batched"):
			continue
		if node.global_position.distance_to(at) > 30.0:
			continue
		var walk: Node = node
		var top: Node = node
		while walk != null and walk != home and walk != game.apartment:
			top = walk
			walk = walk.get_parent()
		var owner_path := ("home/" if walk == home else "town/") + str(top.name)
		var reason := ""
		var w2: Node = node
		while w2 != null and w2 != game.apartment:
			if game.doors.has(w2): reason = "door"; break
			if w2.has_meta("keep_own_draw"): reason = "keep_own_draw"; break
			if w2.is_processing() or w2.is_physics_processing(): reason = "processing"; break
			if w2.has_meta("swivel"): reason = "swivel"; break
			if str(w2.name) == "Home roof": reason = "roof"; break
			w2 = w2.get_parent()
		if reason == "":
			var override := false
			for i in node.get_surface_override_material_count():
				override = override or node.get_surface_override_material(i) != null
			if override: reason = "surface override"
			elif node.material_overlay != null or node.transparency != 0.0: reason = "overlay/transparency"
			elif node.skin != null: reason = "skinned"
			elif node.material_override == null: reason = "mesh materials (unique mesh?)"
			else: reason = "single in its group / lights"
		var key := owner_path + " [" + reason + "]"
		var surfaces: int = node.mesh.get_surface_count()
		groups[key] = int(groups.get(key, 0)) + surfaces
		reasons[reason] = int(reasons.get(reason, 0)) + surfaces
		total += surfaces
	var keys := groups.keys()
	keys.sort_custom(func(a, b): return groups[a] > groups[b])
	print("PROBE unbatched surfaces within 30 m of the bedroom: ", total, " by reason ", reasons)
	for k in keys.slice(0, 30):
		print("PROBE   %4d  %s" % [groups[k], k])
