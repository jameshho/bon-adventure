extends SceneTree
## Far plush meshes (26 Nov 2026, option C; scripts/characters/far_plush_meshes.gd and
## SculptCache.strip()/unstrip()), natively with the web path forced (VT_NEARBY=1):
## - stripping every town plush drops their meshes and gives back video memory (printed);
## - unstripping gives every part its mesh back, characters that shared a mesh share it again,
##   and video memory returns to about where it was (no pile-up over two cycles);
## - the FarPlushMeshes node strips plushes far from the player and restores them as the player
##   comes back, before they are within the 45 m draw range.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=1 godot --path . --audio-driver Dummy --script res://docs/evidence/far-unit-freeing-20261126/verify_plush.gd
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")
const SculptCache := preload("res://scripts/characters/sculpt_cache.gd")
const FarPlushMeshes := preload("res://scripts/characters/far_plush_meshes.gd")

var main: Node
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func centre(key: String) -> Vector2:
	var box: Array = NearbyUnits.data().boxes[key][0]
	return Vector2((box[0] + box[2]) * 0.5, (box[1] + box[3]) * 0.5)

func stand_at(key: String, lift := 3.0) -> void:
	var at := centre(key)
	main.player.global_position = main.apartment.to_global(Vector3(at.x, lift, at.y))
	main.player.velocity = Vector3.ZERO

func video_mb() -> float:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0

func plushes() -> Array:
	return SculptCache.built_characters().filter(func(node) -> bool: return node is Node3D and main.apartment.is_ancestor_of(node))

## [parts with a mesh, distinct meshes] over `nodes`.
func mesh_counts(nodes: Array) -> Array:
	var parts := 0
	var distinct := {}
	for root in nodes:
		for part: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			if part.mesh != null:
				parts += 1
				distinct[part.mesh.get_instance_id()] = true
	return [parts, distinct.size()]

func run() -> void:
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var apartment: Node3D = main.get_node("Apartment")
	main.staged_loading = true
	main.initial_units = NearbyUnits.initial_for(centre("restaurants"), apartment.transform.basis.get_scale().x, ["restaurants"])
	get_root().add_child(main)
	await main.town_ready
	await frames(30)
	stand_at("restaurants")
	var town := plushes()
	var before := mesh_counts(town)
	var full_mb := video_mb()
	print("  units ", main.apartment.get_meta("loaded_units", []), ": %d plushes, %d parts with meshes, %d distinct meshes, video %.0f MB" % [town.size(), before[0], before[1], full_mb])
	check(town.size() > 10, "the restaurants' plushes came through the sculpt cache (%d)" % town.size())

	for cycle in 2:
		var started := Time.get_ticks_msec()
		var stripped := 0
		for node in town:
			if SculptCache.strip(node):
				stripped += 1
		var strip_ms := Time.get_ticks_msec() - started
		await frames(20)
		var bare_mb := video_mb()
		print("  cycle %d: stripped %d in %d ms, video %.0f MB" % [cycle + 1, stripped, strip_ms, bare_mb])
		check(stripped == town.size() and mesh_counts(town)[0] == 0, "cycle %d: every plush gives up its meshes" % (cycle + 1))
		check(bare_mb < full_mb - 10.0, "cycle %d: video memory drops (%.0f -> %.0f MB)" % [cycle + 1, full_mb, bare_mb])
		started = Time.get_ticks_msec()
		var worst := 0
		for node in town:
			var one := Time.get_ticks_msec()
			SculptCache.unstrip(node)
			worst = maxi(worst, Time.get_ticks_msec() - one)
		print("  cycle %d: restored in %d ms (worst plush %d ms)" % [cycle + 1, Time.get_ticks_msec() - started, worst])
		await frames(20)
		var after := mesh_counts(town)
		check(after[0] == before[0], "cycle %d: every part has its mesh again (%d of %d)" % [cycle + 1, after[0], before[0]])
		check(after[1] <= before[1], "cycle %d: shared meshes are shared again (%d distinct, was %d)" % [cycle + 1, after[1], before[1]])
		check(video_mb() < full_mb + 10.0, "cycle %d: video memory back (%.0f vs %.0f MB)" % [cycle + 1, video_mb(), full_mb])

	# The node: far away they go, coming back they return before they show.
	var driver := FarPlushMeshes.new()
	driver.setup(main)
	main.add_child(driver)
	stand_at("sports", 30.0)
	await frames(30)
	var waited := 0
	while plushes().any(func(node) -> bool: return not SculptCache.is_stripped(node) and node.global_position.distance_to(main.player.global_position) > FarPlushMeshes.STRIP_RADIUS + 1.0) and waited < 6000:
		stand_at("sports", 30.0)
		await process_frame
		waited += 1
	var far_ones := plushes().filter(func(node) -> bool: return node.global_position.distance_to(main.player.global_position) > FarPlushMeshes.STRIP_RADIUS + 1.0)
	check(not far_ones.is_empty() and far_ones.all(func(node) -> bool: return SculptCache.is_stripped(node)), "far from the restaurants every plush there is stripped (%d, %d frames)" % [far_ones.size(), waited])
	print("  far away: video %.0f MB" % video_mb())
	# Walk back in steps of 2 m per frame (120 m/s at 60 fps is faster than any car): none is
	# within the 45 m draw range while stripped.
	var from: Vector3 = main.player.global_position
	var to: Vector3 = main.apartment.to_global(Vector3(centre("restaurants").x, 3.0, centre("restaurants").y))
	var seen_bare := 0
	var steps := int(from.distance_to(to) / 2.0)
	for i in steps:
		main.player.global_position = from.lerp(to, float(i + 1) / steps)
		main.player.velocity = Vector3.ZERO
		await process_frame
		for node in plushes():
			if SculptCache.is_stripped(node) and node.global_position.distance_to(main.player.global_position) < 45.0:
				seen_bare += 1
	await frames(60)
	print("  walked back %d steps; stripped plushes inside 45 m seen %d times" % [steps, seen_bare])
	check(seen_bare == 0, "walking back fast, no plush is still bare inside its 45 m draw range")
	check(mesh_counts(plushes().filter(func(node) -> bool: return node.global_position.distance_to(main.player.global_position) < FarPlushMeshes.RESTORE_RADIUS))[0] > 0 \
		and plushes().filter(func(node) -> bool: return node.global_position.distance_to(main.player.global_position) < FarPlushMeshes.RESTORE_RADIUS).all(func(node) -> bool: return not SculptCache.is_stripped(node)), "back at the restaurants every near plush has its meshes")
	print("far plush meshes verify: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
