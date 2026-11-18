extends SceneTree
## Which town surfaces are textured (17 Nov 2026, anisotropic filtering question): loads every
## saved town scene (scenes/town/*.scn), counts mesh surfaces by material kind and lists the
## textured ones, and the materials of meshes named like road markings, floor lines or signs.
## Read-only; prints "SCAN" lines. Headless:
## godot --headless --path . --script res://docs/evidence/render-batching-20261117/texture_scan.gd
const WORDS := ["mark", "line", "stripe", "crosswalk", "zebra", "lane", "sign", "arrow", "floor"]

func _initialize() -> void:
	var kinds := {}
	var textured := {}
	var named := {}
	var dir := DirAccess.open("res://scenes/town")
	for file in dir.get_files():
		if not file.ends_with(".scn"):
			continue
		var scene: Node = load("res://scenes/town/" + file).instantiate()
		for node: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			if node.mesh == null:
				continue
			for s in node.mesh.get_surface_count():
				var mat: Material = node.material_override
				if mat == null: mat = node.get_surface_override_material(s)
				if mat == null: mat = node.mesh.surface_get_material(s)
				var kind := _kind(mat)
				kinds[kind] = int(kinds.get(kind, 0)) + 1
				if kind.begins_with("standard+texture") or kind.begins_with("shader"):
					textured[kind] = int(textured.get(kind, 0)) + 1
				var lower := str(node.name).to_lower()
				for w in WORDS:
					if lower.contains(w):
						var key := "%s: %s" % [w, kind]
						named[key] = int(named.get(key, 0)) + 1
						break
		scene.free()
	print("SCAN surfaces by material kind: ", kinds)
	print("SCAN textured/shader kinds: ", textured)
	var keys := named.keys()
	keys.sort()
	for k in keys:
		print("SCAN named %s x%d" % [k, named[k]])
	var labels := 0
	quit()

func _kind(mat: Material) -> String:
	if mat == null:
		return "none"
	if mat is ShaderMaterial:
		var shader: Shader = (mat as ShaderMaterial).shader
		return "shader " + (shader.resource_path.get_file() if shader != null and shader.resource_path != "" else "(built-in)")
	if mat is BaseMaterial3D:
		var base := mat as BaseMaterial3D
		if base.albedo_texture != null:
			return "standard+texture filter=%d" % base.texture_filter
		return "standard plain"
	return mat.get_class()
