extends SceneTree
## Performance baseline (25 Nov 2026, improvement plan task PERF-01; docs/guides/improvement-plan/).
## One repeatable probe for comparing later changes: the time to load the town, then for six
## fixed views (street at spawn, home bedroom, mahjong yard, zoo, flight at 40 m and 100 m, all at
## 2 pm with the clock paused) the draw calls, triangles, video memory and the frame time over
## 300 frames (p50 / p95 / max, with vsync and the frame cap off) plus process and physics time.
## Desktop only (this Mac, not a phone or the web build). Writes nothing into the project: the
## results are printed as "PERF" lines and saved to user://perf_baseline.json, with one screenshot
## per view as user://perf_<view>.png (the isolated HOME).
## Graphics, an isolated HOME, the full town (dev_focus.txt = all):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/perf-baseline-20261125/probe.gd
const ModularTown := preload("res://scripts/world/modular_town.gd")
const BED_SPOT := Vector3(-4.4, 0.0, -9.6)
const BED_LOOK := Vector3(-1.0, 0.0, 0.0)
const FRAMES := 300
var game: Node
var results := {}

func _initialize(): run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func info(what: int) -> float:
	return float(RenderingServer.get_rendering_info(what))

func measure(label: String) -> void:
	await frames(240)   # indoor visibility, nearby loading and batching settle
	var times := []
	var draws := 0.0
	var tris := 0.0
	var process_ms := 0.0
	var physics_ms := 0.0
	var last := Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		draws += info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		tris += info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	times.sort()
	var row := {
		"p50_ms": times[FRAMES / 2], "p95_ms": times[int(FRAMES * 0.95)], "max_ms": times[FRAMES - 1],
		"draws": draws / FRAMES, "triangles_m": tris / FRAMES / 1e6,
		"video_mb": info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0,
		"texture_mb": info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0,
		"buffer_mb": info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0,
		"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"process_ms": process_ms / FRAMES, "physics_ms": physics_ms / FRAMES,
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
	var cam := root.get_camera_3d()
	row["camera"] = str(cam.get_path()) if cam else "none"
	row["camera_at"] = str(cam.global_position.round()) if cam else ""
	row["view_m"] = cam.far if cam else 0.0
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://perf_%s.png" % label.replace(" ", "-"))
	results[label] = row
	print("PERF %s camera %s at %s, far %.0f m" % [label, row.camera, row.camera_at, row.view_m])
	print("PERF %s: p50 %.2f ms, p95 %.2f, max %.2f | %.0f draws, %.2f M tris | video %.0f MB (tex %.0f, buf %.0f), static %.0f MB | process %.2f ms, physics %.2f ms | %d nodes" % [
		label, row.p50_ms, row.p95_ms, row.max_ms, row.draws, row.triangles_m, row.video_mb,
		row.texture_mb, row.buffer_mb, row.static_mb, row.process_ms, row.physics_ms, row.nodes])

func run():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var started := Time.get_ticks_msec()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var first_frame := Time.get_ticks_msec() - started
	await frames(40)
	results["load"] = {"first_frame_ms": first_frame, "plus_40_frames_ms": Time.get_ticks_msec() - started}
	print("PERF load: main.tscn to first frame %d ms, to 40 frames %d ms" % [first_frame, results.load.plus_40_frames_ms])
	results["conditions"] = {"window": str(root.get_visible_rect().size), "3d_scale": root.scaling_3d_scale,
		"msaa": root.msaa_3d, "renderer": RenderingServer.get_video_adapter_name(),
		"godot": Engine.get_version_info().string}
	print("PERF conditions: ", results.conditions)
	game.day_night.set_time(14.0 * 60.0)
	game.day_night.pause()
	var player = game.player
	var town: Node3D = game.apartment
	await measure("street")
	var home: Node3D = ModularTown.building(town, "home")
	player.global_position = home.to_global(BED_SPOT + Vector3(0, .1, 0))
	var forward: Vector3 = home.global_basis * BED_LOOK
	player.rotation.y = atan2(-forward.x, -forward.z)
	player.camera_yaw = player.rotation.y
	player.reset_camera()
	await measure("bedroom")
	var table := home.find_child("MahjongTable", true, false) as Node3D
	if table != null:
		player.global_position = table.global_position + table.global_basis.z * 4.0
		player.reset_camera()
		await measure("mahjong yard")
	var zoo := town.get_node_or_null("ParkZoo") as Node3D
	if zoo != null:
		var centre := Vector3.ZERO
		var count := 0
		for animal in zoo.get_children():
			if animal.is_in_group("wandering_animals"):
				centre += animal.global_position
				count += 1
		if count > 0:
			centre /= count
			player.global_position = centre + Vector3(0, 1.0, -18.0)
			# Face the animals (the first run's yaw 0 looked away from them, 25 Nov).
			var look: Vector3 = centre - player.global_position
			player.rotation.y = atan2(-look.x, -look.z)
			player.camera_yaw = player.rotation.y
			player.reset_camera()
			await measure("zoo (%d animals)" % count)
	var bounds: Rect2 = town.get_meta("reference_map_bounds")
	var map_centre: Vector3 = town.to_global(Vector3(bounds.get_center().x, 0, bounds.get_center().y))
	var plane: Node3D = town.get_node("Vehicles/Turboprop")
	player.global_position = plane.boarding_step_point()
	game.toggle_vehicle()
	for i in 200: await physics_frame
	for height in [40, 100]:
		var start: Vector3 = map_centre + Vector3(0, 0, -120)
		start.y = town.global_position.y + float(height)
		plane.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP).scaled(plane.global_basis.get_scale()), start)
		plane.flight_velocity = Vector3(0, 0, plane.CRUISE)
		plane.airspeed = plane.CRUISE
		plane.landed = false
		player.reset_camera()
		await measure("flight %d m" % height)
	var file := FileAccess.open("user://perf_baseline.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(results, "  "))
	print("PERF done")
	quit()
