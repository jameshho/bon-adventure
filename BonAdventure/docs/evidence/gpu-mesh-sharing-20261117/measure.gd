extends SceneTree
## GPU mesh memory of the full town (17 Nov 2026, docs/guides/performance/README.md "GPU memory on
## the web"): video/buffer/texture memory from RenderingServer.get_rendering_info(), and every mesh
## in the tree once (by RID) with its surface bytes, by owner (plush characters, clay animals,
## the rest) and as byte-identical copies (same surface data, different mesh). Writes nothing.
## Graphics, isolated HOME (default settings = Low):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/gpu-mesh-sharing-20261117/measure.gd
var start_usec := 0

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func mb(bytes: float) -> String:
	return "%.1f" % (bytes / 1048576.0)

func info() -> String:
	return "video %s MB (buffers %s, textures %s)" % [
		mb(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)),
		mb(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED)),
		mb(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED))]

func owner_kind(node: Node) -> String:
	var at := node
	while at != null:
		var path := at.scene_file_path
		if path.begins_with("res://scenes/characters/"):
			return "plush"
		if path.begins_with("res://scenes/animals/"):
			return "animals"
		at = at.get_parent()
	return "rest"

var town: Node

## The node's top two levels under the town (a unit part or base root, and its child).
func unit_of(node: Node) -> String:
	if town == null or not town.is_ancestor_of(node):
		return "outside town"
	var parts := String(town.get_path_to(node)).split("/")
	return "/".join(parts.slice(0, mini(2, parts.size() - 1)))

func run() -> void:
	await frames(2)
	print("MEM empty: ", info())
	start_usec = Time.get_ticks_usec()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	var loaded_ms := (Time.get_ticks_usec() - start_usec) / 1000.0
	await frames(240)
	await RenderingServer.frame_post_draw
	print("LOAD: main ready in %.0f ms (sculpt cache %s, share %s)" % [loaded_ms,
		OS.get_environment("VT_SCULPT_CACHE"), OS.get_environment("VT_MESH_SHARE")])
	print("MEM town: ", info())
	town = game.get("apartment")
	var seen := {}
	var dup_by_name := {}
	var by_kind := {"plush": 0, "animals": 0, "rest": 0}
	var count_kind := {"plush": 0, "animals": 0, "rest": 0}
	var by_hash := {}
	var dup_by_unit := {}
	var dup_by_kind := {}
	var total := 0
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh = null
		if node is MeshInstance3D:
			mesh = node.mesh
		elif node is MultiMeshInstance3D and node.multimesh != null:
			mesh = node.multimesh.mesh
		if mesh == null or seen.has(mesh.get_rid()):
			continue
		seen[mesh.get_rid()] = true
		var bytes := 0
		var ctx := HashingContext.new()
		ctx.start(HashingContext.HASH_MD5)
		for s in RenderingServer.mesh_get_surface_count(mesh.get_rid()):
			var surface: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(), s)
			for field in ["vertex_data", "attribute_data", "skin_data", "index_data"]:
				var data: PackedByteArray = surface.get(field, PackedByteArray())
				bytes += data.size()
				if data.size() > 0:
					ctx.update(data)
			ctx.update(var_to_bytes([surface.get("format", 0), surface.get("primitive", 0)]))
		var kind := owner_kind(node)
		by_kind[kind] += bytes
		count_kind[kind] += 1
		total += bytes
		var hash := ctx.finish().hex_encode()
		if by_hash.has(hash):
			dup_by_kind[kind] = dup_by_kind.get(kind, 0) + bytes
			# Where the static (non-character) copies are.
			if kind == "rest":
				var unit := unit_of(node)
				dup_by_unit[unit] = dup_by_unit.get(unit, 0) + bytes
				var name := unit + " " + String(node.get_parent().name if String(node.name).begins_with("@") else node.name).rstrip("0123456789 _")
				dup_by_name[name] = dup_by_name.get(name, 0) + bytes
		by_hash[hash] = true
	print("MESH: %d meshes, %d different, %s MB (plush %s MB in %d, animals %s MB in %d, rest %s MB in %d)" % [
		seen.size(), by_hash.size(), mb(total), mb(by_kind.plush), count_kind.plush,
		mb(by_kind.animals), count_kind.animals, mb(by_kind.rest), count_kind.rest])
	var dup := 0
	for kind in dup_by_kind:
		dup += dup_by_kind[kind]
	print("DUP: %s MB byte-identical copies; by kind %s" % [mb(dup), str(dup_by_kind.keys().map(func(k): return "%s %s" % [k, mb(dup_by_kind[k])]))])
	var units := dup_by_unit.keys()
	units.sort_custom(func(a, b): return dup_by_unit[a] > dup_by_unit[b])
	for unit in units.slice(0, 12):
		print("DUP rest unit %s: %s MB" % [unit, mb(dup_by_unit[unit])])
	var names := dup_by_name.keys()
	names.sort_custom(func(a, b): return dup_by_name[a] > dup_by_name[b])
	for name in names.slice(0, 15):
		print("DUP rest name %s: %s MB" % [name, mb(dup_by_name[name])])
	quit()
