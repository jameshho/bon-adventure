extends SceneTree
## Clay animal sizes (16 Nov 2026): per prefab the bytes on disk (the scene plus the mesh files it
## names), LOD0 triangles and vertices, LOD levels and a load time; then base.scn's size, load time
## and the clay meshes its ParkZoo holds (embedded or external).
##   godot --headless --path . --script res://docs/evidence/clay-sizes-20261116/measure.gd -- <out.md>
## Load times: each file loaded twice with the cache ignored, the second time reported (warm disk).
const ANIMALS := ["black_bear", "black_bear_adult", "cow", "deer", "duck", "elephant", "flamingo",
	"giraffe", "golden_retriever", "gorilla", "kangaroo", "lion", "panda", "pig", "red_panda",
	"rhino", "zebra"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var lines := ["| Animal | Files (KB) | Triangles (LOD0) | Vertices | LOD levels (body) | Load ms |", "|---|---:|---:|---:|---:|---:|"]
	var total := [0, 0, 0, 0.0]
	for animal: String in ANIMALS:
		var path := "res://scenes/animals/%s_clay.tscn" % animal
		if not ResourceLoader.exists(path):
			path = "res://scenes/animals/%s_clay.scn" % animal
		var bytes := _bytes(path)
		ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		var started := Time.get_ticks_usec()
		var scene: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		var ms := (Time.get_ticks_usec() - started) / 1000.0
		var model := scene.instantiate()
		var counts := _counts(model)
		model.free()
		lines.append("| %s | %d | %d | %d | %d | %.0f |" % [animal, bytes / 1024, counts[0], counts[1], counts[2], ms])
		total[0] += bytes; total[1] += counts[0]; total[2] += counts[1]; total[3] += ms
	lines.append("| **all 17** | **%d** | **%d** | **%d** | | **%.0f** |" % [total[0] / 1024, total[1], total[2], total[3]])
	# The town copy: base.scn holds the zoo's clay animals as plain nodes.
	var base := "res://scenes/town/base.scn"
	var started := Time.get_ticks_usec()
	var packed: PackedScene = ResourceLoader.load(base, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	var base_ms := (Time.get_ticks_usec() - started) / 1000.0
	var town := packed.instantiate()
	var zoo := town.get_node("ParkZoo")
	var embedded := 0
	var external := 0
	var tris := 0
	var seen := {}
	for mi: MeshInstance3D in zoo.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not _is_clay(mi) or seen.has(mi.mesh):
			continue
		seen[mi.mesh] = true
		tris += _tris(mi.mesh)
		if mi.mesh.resource_path.contains("::") or mi.mesh.resource_path.is_empty():
			embedded += 1
		else:
			external += 1
	town.free()
	lines.append("")
	lines.append("base.scn: %d KB on disk (%d KB with the clay mesh files it names), load %.0f ms; ParkZoo clay meshes: %d embedded, %d external, %d triangles" % [
		FileAccess.get_file_as_bytes(base).size() / 1024, _bytes(base) / 1024, base_ms, embedded, external, tris])
	var text := "\n".join(lines)
	print(text)
	if not args.is_empty():
		var f := FileAccess.open(args[0], FileAccess.WRITE)
		f.store_string(text + "\n")
	quit()

## A clay part: inside a zoo model named "Clay<Name>" (or a prefab root "...ClayDisplay").
func _is_clay(mi: Node) -> bool:
	var node := mi.get_parent()
	while node != null:
		if String(node.name).ends_with("ClayDisplay") or String(node.name).begins_with("Clay"):
			return true
		node = node.get_parent()
	return false

## The file plus the clay mesh files it depends on (scenes/animals/clay_meshes/).
func _bytes(path: String) -> int:
	var total := FileAccess.get_file_as_bytes(path).size()
	for dep in ResourceLoader.get_dependencies(path):
		var dep_path := dep.get_slice("::", 2) if dep.contains("::") else dep
		if dep_path.begins_with("uid://"):
			dep_path = ResourceUID.get_id_path(ResourceUID.text_to_id(dep_path))
		if dep_path.contains("/clay_meshes/"):
			total += FileAccess.get_file_as_bytes(dep_path).size()
	return total

func _tris(mesh: Mesh) -> int:
	var t := 0
	for s in mesh.get_surface_count():
		var n: int = mesh.surface_get_array_index_len(s)
		t += (n if n > 0 else mesh.surface_get_array_len(s)) / 3
	return t

func _counts(model: Node) -> Array:
	var tris := 0
	var verts := 0
	var lods := 0
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		tris += _tris(mi.mesh)
		for s in mi.mesh.get_surface_count():
			verts += mi.mesh.surface_get_array_len(s)
		if mi.name == "Body":
			lods = (RenderingServer.mesh_get_surface(mi.mesh.get_rid(), 0).get("lods", []) as Array).size()
	return [tris, verts, lods]
