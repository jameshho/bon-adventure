extends RefCounted
## Shared meshes in a baked town scene (17 Nov 2026, WebGL context loss: docs/guides/performance/
## README.md "GPU memory on the web"). Before a unit or the base is saved, tools/bake_unit.gd
## (after the material palette) points every MeshInstance3D / MultiMesh whose mesh is an exact
## copy of one met before in the same scene at that first mesh, so the scene stores it once and
## the GPU holds one copy (a Mystery House door's gilding nine times, a restaurant's lamp spheres).
## Exact copy: same class and every stored property: an ArrayMesh's surface bytes, LODs, blend
## shapes and AABBs, a primitive's sizes and segments; materials, shadow meshes and other objects
## must be the SAME resource (the palette has already merged identical materials).
## Left unshared: meshes stored in another file (prefabs, imports, already shared), meshes marked
## `resource_local_to_scene`, and unit boxes and spheres code shares by other means.
## Runtime rule: a baked mesh may be used by several nodes, so code that edits a mesh it found on
## a node (sizes, segments, surfaces) must duplicate() it first. Checked 17 Nov 2026: only
## render_culling.gd edits baked meshes (it lowers sphere/cylinder segments, already per shared
## mesh by its largest use); warehouse.gd, ground_cut.gd and supermarket_products.gd edit or
## build meshes before assigning them.
const MaterialPalette = preload("res://tools/material_palette.gd")
var counts := {}

func count(key: String, amount := 1) -> void:
	counts[key] = counts.get(key, 0) + amount

## Exact content of `mesh` (objects by identity), or "" when it is left unshared.
static func content(mesh: Mesh) -> String:
	if mesh.resource_local_to_scene or not MaterialPalette.town_owned(mesh):
		return ""
	var parts := [mesh.get_class()]
	for property in mesh.get_property_list():
		var name: String = property.name
		if property.usage & PROPERTY_USAGE_STORAGE == 0 or name in ["resource_path", "resource_scene_unique_id"]:
			continue
		parts.append(name)
		parts.append(_plain(mesh.get(name)))
	for meta in mesh.get_meta_list():
		parts.append("meta " + meta)
		parts.append(_plain(mesh.get_meta(meta)))
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(var_to_bytes(parts))
	return hashing.finish().hex_encode()

## `value` with every object replaced by its instance id (so only the same resource matches).
static func _plain(value: Variant) -> Variant:
	if value is Object:
		return "object %d" % (value as Object).get_instance_id() if value != null else null
	if value is Array:
		return (value as Array).map(func(item: Variant) -> Variant: return _plain(item))
	if value is Dictionary:
		var result := {}
		for key in value:
			result[_plain(key)] = _plain(value[key])
		return result
	return value

## Points every mesh user under `top` at the first exact copy of its mesh.
func apply(top: Node) -> void:
	var by_content := {}
	var known := {}
	for node in [top] + top.find_children("*", "", true, false):
		var holder: Object = null
		if node is MeshInstance3D:
			holder = node
		elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
			holder = (node as MultiMeshInstance3D).multimesh
		if holder == null or holder.get("mesh") == null:
			continue
		var mesh: Mesh = holder.get("mesh")
		if not known.has(mesh):
			var key := content(mesh)
			known[mesh] = mesh
			if key != "":
				if by_content.has(key):
					known[mesh] = by_content[key]
					count("meshes merged")
				else:
					by_content[key] = mesh
			else:
				count("meshes left unshared")
		if known[mesh] != mesh:
			holder.set("mesh", known[mesh])
			count("mesh users repointed")
