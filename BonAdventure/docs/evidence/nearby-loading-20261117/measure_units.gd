extends SceneTree
## Nearby loading proposal (17 Nov 2026, docs/guides/performance/README.md "Proposal: load only
## nearby buildings on phones"): what each building unit (data/buildings.json) costs once it is
## in the running town. Starts Main the way the app does (staged loading) with only the base world
## and `FIRST` (default barn), then adds every other unit with Main.add_unit() and records, per
## unit: load() and bare instantiate() time, add_unit()'s frames (wall time, worst frame, frame
## count), video/buffer/texture memory and node deltas, mesh bytes new to the unit (unique mesh
## RIDs not seen before, every surface's vertex/attribute/skin/index bytes), plush count and the
## world-space XZ box of each part. Then (FREE_TEST) it frees a few units' parts and their
## Unit_<key> batch containers with Main paused, to see how much memory really comes back.
## Web-only Label3D size sharing (render_culling.share_label_sizes) is forced after each step so
## the texture numbers match the web. Writes results.json next to this file (or `-- out=<path>`).
## Needs graphics (headless reports no video memory). Writes saves and the sculpt cache: isolated HOME.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 \
##   --script res://docs/evidence/nearby-loading-20261117/measure_units.gd [-- first=playground only=barn web_signs=1]
const ModularTown := preload("res://scripts/world/modular_town.gd")
const RenderCulling := preload("res://scripts/world/render_culling.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const FREE_TEST := ["mystery", "supermarket", "restaurants", "school"]

var main: Node
var seen_meshes := {}
var frame_ms: Array = []
var last_us := 0
var recording := false
var out := "res://docs/evidence/nearby-loading-20261117/results.json"

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _tick() -> void:
	var now := Time.get_ticks_usec()
	if recording and last_us != 0:
		frame_ms.append((now - last_us) / 1000.0)
	last_us = now

func mem() -> Dictionary:
	return {
		"video_mb": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0,
		"texture_mb": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0,
		"buffer_mb": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	}

func diff(a: Dictionary, b: Dictionary) -> Dictionary:
	var r := {}
	for k in a:
		r[k] = snappedf(b[k] - a[k], 0.01)
	return r

static func mesh_bytes(mesh: Mesh) -> int:
	var total := 0
	var rid := mesh.get_rid()
	for i in RenderingServer.mesh_get_surface_count(rid):
		var s: Dictionary = RenderingServer.mesh_get_surface(rid, i)
		for key in ["vertex_data", "attribute_data", "skin_data", "index_data"]:
			if s.has(key):
				total += (s[key] as PackedByteArray).size()
	return total

## Unique mesh bytes under `root` not already counted (marks them counted).
func new_mesh_bytes(root: Node) -> int:
	var total := 0
	for node: Node in [root] + root.find_children("*", "", true, false):
		var mesh: Mesh = null
		if node is MeshInstance3D:
			mesh = (node as MeshInstance3D).mesh
		elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
			mesh = (node as MultiMeshInstance3D).multimesh.mesh
		if mesh == null:
			continue
		var id := mesh.get_rid().get_id()
		if seen_meshes.has(id):
			continue
		seen_meshes[id] = true
		total += mesh_bytes(mesh)
	return total

static func world_box(root: Node) -> AABB:
	var box := AABB()
	var first := true
	for node: Node in [root] + root.find_children("*", "VisualInstance3D", true, false):
		if not node is VisualInstance3D or node is Light3D:
			continue
		var vi := node as VisualInstance3D
		var b: AABB = vi.global_transform * vi.get_aabb()
		if b.size.length() > 600.0:
			continue
		box = b if first else box.merge(b)
		first = false
	return box

static func xz(box: AABB) -> Array:
	return [snappedf(box.position.x, 0.1), snappedf(box.position.z, 0.1), snappedf(box.end.x, 0.1), snappedf(box.end.z, 0.1)]

func unit_parts(key: String) -> Array:
	var result: Array = []
	for path in ModularTown.registry()[key].parts:
		var node: Node = main.apartment.get_node_or_null(NodePath(path))
		if node != null:
			result.append(node)
	return result

## Mesh MB under the plush characters in `parts` (unique meshes; counted apart from seen_meshes).
func plush_mesh_mb(parts: Array) -> float:
	var ids := {}
	var total := 0
	for part in parts:
		for node in part.find_children("*", "Node3D", true, false):
			if not str(node.scene_file_path).ends_with("_plush.tscn"):
				continue
			for m: Node in node.find_children("*", "MeshInstance3D", true, false):
				var mesh: Mesh = (m as MeshInstance3D).mesh
				if mesh != null and not ids.has(mesh.get_rid().get_id()):
					ids[mesh.get_rid().get_id()] = true
					total += mesh_bytes(mesh)
	return total / 1048576.0

func count_plush(parts: Array) -> int:
	var n := 0
	for part in parts:
		for node in part.find_children("*", "Node3D", true, false):
			if str(node.scene_file_path).ends_with("_plush.tscn"):
				n += 1
	return n

## Glyph caches of the default font and its fallbacks: [file, sizes, textures, atlas MB].
static func font_report() -> Array:
	var rows: Array = []
	var fonts: Array = [ThemeDB.fallback_font]
	var seen := {}
	while not fonts.is_empty():
		var item = fonts.pop_back()
		if item == null or seen.has(item):
			continue
		seen[item] = true
		if item is FontVariation:
			fonts.append(item.base_font)
		if item is FontFile:
			var sizes := 0
			var textures := 0
			var atlas_mb := 0.0
			for cache in range(item.get_cache_count()):
				for size in item.get_size_cache_list(cache):
					sizes += 1
					textures += item.get_texture_count(cache, size)
					for i in item.get_texture_count(cache, size):
						var image: Image = item.get_texture_image(cache, size, i)
						if image != null:
							atlas_mb += image.get_data_size() / 1048576.0
			rows.append([str(item.resource_path).get_file(), sizes, textures, snappedf(atlas_mb, 0.1)])
		fonts.append_array(item.fallbacks)
	return rows

static func font_mb() -> float:
	var total := 0.0
	for row in font_report():
		total += row[3]
	return total

func run() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var first: String = args.get("first", "barn")
	var only: Array = Array(str(args.get("only", "")).split(",", false))
	if args.has("out"):
		out = args.out
	# web_signs=1: sign_language.gd's web path (signs stay on shared sizes; stage 0, 17 Nov 2026).
	if args.get("web_signs", "") == "1":
		preload("res://scripts/world/sign_language.gd").share_sizes = true
	DisplayServer.window_set_size(Vector2i(1280, 800))
	process_frame.connect(_tick)
	await frames(10)
	var empty := mem()
	var t := Time.get_ticks_msec()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.staged_loading = true
	main.initial_units = [] if first == "all" else [first]
	get_root().add_child(main)
	await main.town_ready
	var startup_ms := Time.get_ticks_msec() - t
	await frames(30)
	RenderCulling.share_label_sizes(main)
	await frames(10)
	var base := mem()
	base["font_atlas_mb"] = font_mb()
	new_mesh_bytes(main)
	print("NEARBY base (with ", first, "): ", base, " startup ", startup_ms, " ms")
	var units := {}
	var order: Array = main.pending_units.duplicate()
	if not only.is_empty():
		order = order.filter(func(k) -> bool: return only.has(k))
	for key in order:
		await frames(5)
		var before := mem()
		var font_before := font_mb()
		var path: String = ModularTown.FOLDER + key + "." + ModularTown.EXTENSION
		var t0 := Time.get_ticks_usec()
		var scene := load(path) as PackedScene
		var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		var probe := scene.instantiate()
		var inst_ms := (Time.get_ticks_usec() - t0) / 1000.0
		var scene_nodes := probe.find_children("*", "", true, false).size()
		probe.free()
		await frames(2)
		frame_ms = []
		recording = true
		last_us = 0
		t0 = Time.get_ticks_usec()
		await main.add_unit(key)
		var add_ms := (Time.get_ticks_usec() - t0) / 1000.0
		await frames(3)
		recording = false
		scene = null
		RenderCulling.share_label_sizes(main)
		await frames(10)
		var after := mem()
		var parts := unit_parts(key)
		var bytes := 0
		var part_rows: Array = []
		for part in parts:
			var b := new_mesh_bytes(part)
			bytes += b
			part_rows.append({"path": str(main.apartment.get_path_to(part)), "mesh_mb": snappedf(b / 1048576.0, 0.01), "box": xz(world_box(part)), "nodes": part.find_children("*", "", true, false).size() + 1})
		var batch: Node = main.apartment.get_node_or_null("StaticRenderBatches/Unit_" + key)
		var batch_bytes := new_mesh_bytes(batch) if batch != null else 0
		var worst := 0.0
		for f in frame_ms:
			worst = maxf(worst, f)
		units[key] = {
			"delta": diff(before, after),
			"font_atlas_mb": snappedf(font_mb() - font_before, 0.1),
			"mesh_mb": snappedf(bytes / 1048576.0, 0.01),
			"batch_mesh_mb": snappedf(batch_bytes / 1048576.0, 0.01),
			"batch_instances": batch.find_children("*", "MultiMeshInstance3D", true, false).size() if batch != null else 0,
			"plush": count_plush(parts),
			"plush_mesh_mb": snappedf(plush_mesh_mb(parts), 0.01),
			"scene_nodes": scene_nodes,
			"load_ms": snappedf(load_ms, 0.1),
			"instantiate_ms": snappedf(inst_ms, 0.1),
			"add_ms": snappedf(add_ms, 0.1),
			"add_frames": frame_ms.size(),
			"worst_frame_ms": snappedf(worst, 0.1),
			"frames_over_50ms": frame_ms.filter(func(f) -> bool: return f > 50.0).size(),
			"parts": part_rows,
		}
		print("NEARBY unit ", key, ": ", JSON.stringify(units[key]))
	await frames(30)
	var full := mem()
	# Entrances (Main.ENTRANCES, standing point) in world XZ, for the radius tables.
	var entrances := {}
	var entrance_map: Dictionary = main.get_script().get_script_constant_map()["ENTRANCES"]
	for name in entrance_map:
		var e: Array = entrance_map[name]
		var site := ModularTown.building(main.apartment, e[0], e[1], e[2])
		if site != null:
			var p: Vector3 = site.to_global(e[3])
			entrances[name] = [snappedf(p.x, 0.1), snappedf(p.z, 0.1)]
	var town_box := world_box(main.apartment.get_node("Ground") if main.apartment.has_node("Ground") else main.apartment)
	var tex_rows: Array = []
	var font_rows: Array = font_report()
	print("NEARBY fonts: ", font_rows)
	# The size caches (font size, outline) of the default font, and the label pairs in use.
	var label_pairs := {}
	for label: Label3D in main.find_children("*", "Label3D", true, false):
		var pair := "%d/%d" % [label.font_size, label.outline_size]
		label_pairs[pair] = int(label_pairs.get(pair, 0)) + 1
	var cache_pairs: Array = []
	var default_font = ThemeDB.fallback_font
	while default_font is FontVariation:
		default_font = default_font.base_font
	if default_font is FontFile:
		for cache in range(default_font.get_cache_count()):
			for size in default_font.get_size_cache_list(cache):
				cache_pairs.append("%d/%d" % [size.x, size.y])
	print("NEARBY label pairs: ", label_pairs)
	print("NEARBY cache pairs: ", cache_pairs)
	# Free test: do the GPU bytes come back when a unit's nodes and batches go?
	var freed := {}
	if only.is_empty():
		main.process_mode = Node.PROCESS_MODE_DISABLED
		for key in FREE_TEST:
			var before := mem()
			for part in unit_parts(key):
				part.get_parent().remove_child(part)
				part.free()
			var batch: Node = main.apartment.get_node_or_null("StaticRenderBatches/Unit_" + key)
			if batch != null:
				batch.get_parent().remove_child(batch)
				batch.free()
			await frames(20)
			freed[key] = diff(before, mem())
			print("NEARBY freed ", key, ": ", freed[key])
	var result := {
		"date": "2026-11-17", "first": first, "renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "graphics": GameSettings.shared().graphics,
		"empty": empty, "base_with_first": base, "full": full, "startup_ms": startup_ms,
		"units": units, "freed": freed, "top_textures": tex_rows, "fonts": font_rows, "entrances": entrances, "town_box": xz(town_box),
	}
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  "))
	f.close()
	print("NEARBY done: ", out)
	quit()
