extends Node
## Late-building timing probe (PERF-03 sculpt cache, PERF-06 material warm-up; 25 Nov 2026).
## Builds the town with only the home (staged loading, as a new profile does), then for each
## other unit: a look from its entrance before it exists (compiles the base world there), adds
## it from the home's door (Main.add_unit(): the plush sculpting), runs unit_warmup.gd (unless
## warm=0), looks from its entrance and from just inside its door (first sight), goes back to
## the home and looks again (second sight: everything compiled). Each look records the frame
## times of the first LOOK_FRAMES frames. Prints "PROBE <json>" lines.
## Native (graphics, isolated HOME; run it twice with the same HOME for a warm sculpt cache):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 \
##     --script res://docs/evidence/web-start-20261125/run_probe.gd
##   PROBE_WARM=0 turns the warm-up off; PROBE_UNITS=restaurants,police picks units;
##   PROBE_HIDE=<class>|plush|batches|Node3D hides that in the unit before the first look
##   (diagnosis); PROBE_CACHE=0 turns the sculpt cache and mesh sharing off (old web behaviour).
## Web: docs/* is not exported, so copy this file to res://scripts/dev_probe_tmp.gd and add at
## the top of app.gd _ready() (never commit either):
##   if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('probe')||''", true)) != "":
##       add_child(load("res://scripts/dev_probe_tmp.gd").new()); return
## then open index.html?probe=1 (&warm=0, &cache=0, &units=...) and read the browser console.
## A reused browser profile runs the pack its service worker cached: remove the profile's
## "Service Worker" and "Cache" folders after a new export.
const ModularTown := preload("res://scripts/world/modular_town.gd")
const UnitWarmup := preload("res://scripts/world/unit_warmup.gd")
const SculptCache := preload("res://scripts/characters/sculpt_cache.gd")
const LOOK_FRAMES := 8

var main: Node
var results := {}
var _deltas: Array = []
var _last := 0

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last != 0:
		_deltas.append((now - _last) / 1000.0)
	_last = now

func option(name: String) -> String:
	if OS.has_feature("web"):
		var value: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('%s') || ''" % name, true)
		return str(value) if value != null else ""
	return OS.get_environment("PROBE_" + name.to_upper())

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func cache_files() -> int:
	return DirAccess.get_files_at(SculptCache.FOLDER).size() if DirAccess.dir_exists_absolute(SculptCache.FOLDER) else 0

## Frame times of the next `n` frames: [worst, total].
func record(n: int) -> Array:
	_deltas.clear()
	await frames(n)
	var worst := 0.0
	var total := 0.0
	for d in _deltas:
		worst = maxf(worst, d)
		total += d
	return [snappedf(worst, 0.1), snappedf(total, 0.1)]

func entrance(key: String) -> Array:
	var entrances: Dictionary = main.get_script().get_script_constant_map()["ENTRANCES"]
	for name in entrances:
		var entry: Array = entrances[name]
		if entry[0] != key:
			continue
		var site := ModularTown.building(main.apartment, entry[0], entry[1], entry[2])
		if site == null:
			# Not loaded yet: the site's layout pivot may still exist.
			site = main.apartment.get_node_or_null(NodePath(ModularTown.registry()[key].parts[entry[1]] + ("/" + entry[2] if entry[2] != "" else ""))) as Node3D
		if site != null:
			return [site.to_global(entry[3]), site.to_global(entry[4])]
	return []

func stand(at: Vector3, toward: Vector3) -> void:
	var player: Node3D = main.player
	player.global_position = at
	var look := toward - at
	player.rotation.y = atan2(-look.x, -look.z)
	player.camera_yaw = player.rotation.y
	player.reset_camera()

## Looks from the entrance and from just inside the door: [outside, inside] records.
func look(key: String, spot: Array) -> Dictionary:
	if spot.is_empty():
		return {}
	stand(spot[0], spot[1])
	var outside := await record(LOOK_FRAMES)
	var inward: Vector3 = (spot[1] - spot[0]).normalized()
	stand(spot[1] + inward * 3.0, spot[1] + inward * 6.0)
	var inside := await record(LOOK_FRAMES)
	return {"out": outside, "in": inside}

func home_door() -> void:
	var spot := entrance("home")
	stand(spot[0], spot[1])
	await frames(30)

func run() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	UnitWarmup.on = option("warm") != "0"
	# cache=0: no sculpt cache and no mesh sharing, as every web launch before PERF-03.
	if option("cache") == "0":
		OS.set_environment("VT_SCULPT_CACHE", "0")
		OS.set_environment("VT_MESH_SHARE", "0")
	results["conditions"] = {"web": OS.has_feature("web"), "warm_up": UnitWarmup.on,
		"sculpt_cache": SculptCache.enabled(), "userfs_persistent": OS.is_userfs_persistent(),
		"cache_files_before": cache_files(), "godot": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(), "window": str(get_viewport().get_visible_rect().size)}
	print("PROBE " + JSON.stringify(results.conditions))
	var started := Time.get_ticks_msec()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.staged_loading = true
	main.initial_units = ["home"]
	add_child(main)
	await main.town_ready
	results["town_ready_ms"] = Time.get_ticks_msec() - started
	print("PROBE town_ready_ms %d (home only)" % results.town_ready_ms)
	main.day_night.set_time(14.0 * 60.0)
	main.day_night.pause()
	await home_door()
	# app.gd's look round, so the start town is compiled as in the game.
	var player: Node3D = main.player
	for i in 6:
		player.camera_yaw += TAU / 6.0
		player.reset_camera()
		await frames(2)
	await frames(60)
	var keys: Array = Array(option("units").split(",", false)) if option("units") != "" else main.pending_units.duplicate()
	var units := {}
	for key in keys:
		if not main.pending_units.has(key):
			continue
		var row := {}
		var spot := entrance(key)
		await home_door()
		row["before"] = await look(key, spot)
		await home_door()
		_deltas.clear()
		var t := Time.get_ticks_usec()
		await main.add_unit(key)
		row["add_ms"] = snappedf((Time.get_ticks_usec() - t) / 1000.0, 0.1)
		row["add_worst_ms"] = snappedf(_deltas.max() if not _deltas.is_empty() else 0.0, 0.1)
		var plush := 0
		for path in ModularTown.registry()[key].parts:
			var part: Node = main.apartment.get_node_or_null(NodePath(path))
			if part != null:
				plush += part.find_children("*", "Node3D", true, false).filter(func(n) -> bool: return str(n.scene_file_path).ends_with("_plush.tscn")).size()
		row["plush"] = plush
		if spot.is_empty():
			spot = entrance(key)
		if UnitWarmup.on:
			await frames(1)
			_deltas.clear()
			t = Time.get_ticks_usec()
			await UnitWarmup.warm(main, key)
			row["warm_ms"] = snappedf((Time.get_ticks_usec() - t) / 1000.0, 0.1)
			row["warm_worst_ms"] = snappedf(_deltas.max() if not _deltas.is_empty() else 0.0, 0.1)
			row["warm_scan_ms"] = snappedf(UnitWarmup.last_scan_ms, 0.1)
			row["warm_materials"] = UnitWarmup.last_count
		await frames(10)
		# Diagnosis (PROBE_HIDE=Label3D, Sprite3D, plush, ...): hide that kind in the unit first.
		if option("hide") != "":
			for path in ModularTown.registry()[key].parts:
				var part: Node = main.apartment.get_node_or_null(NodePath(path))
				if part == null:
					continue
				for node in part.find_children("*", "Node3D", true, false):
					if node.is_class(option("hide")) or (option("hide") == "plush" and str(node.scene_file_path).ends_with("_plush.tscn")):
						node.visible = false
			var batches: Node3D = main.apartment.get_node_or_null("StaticRenderBatches/Unit_" + key)
			if batches != null and option("hide") in ["Node3D", "batches"]:
				batches.visible = false
		row["first"] = await look(key, spot)
		await home_door()
		row["second"] = await look(key, spot)
		units[key] = row
		print("PROBE unit %s %s" % [key, JSON.stringify(row)])
	results["units"] = units
	results["cache_files_after"] = cache_files()
	print("PROBE cache_files_after %d" % results.cache_files_after)
	print("PROBE done")
	if not OS.has_feature("web"):
		var file := FileAccess.open("user://web_start_probe.json", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(results, "  "))
		get_tree().quit()
