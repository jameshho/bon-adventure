extends SceneTree
## Lighter motorcycle (user, 14 Nov 2026): merges the many small part meshes of
## scenes/props/vehicles/motorcycle.tscn (217 MeshInstance3D) into a few meshes with one surface
## per material, saved next to it as binary .res files. Geometry, materials and the parts that
## move or carry words stay the same:
## - each Wheel keeps its tyre "Visual" (radius lookups) and gets one "Detail" mesh (rim, spokes,
##   hub, brake), so the wheels still spin and keep their "wheel" word bodies;
## - FrontFork keeps its node (it turns with the steering) and gets one "Visual" mesh;
## - the other part groups become two meshes on the root: "Mechanics" (engine, exhaust, rear
##   suspension) and "Parts" (frame, tank, seat, bars, fenders, lights...); the lean rolls the
##   root's children, so they still lean as one. Two, not one: each merged mesh must stay under
##   render_culling.gd HEAVY_TRIANGLES (30k), or the game hides it beyond 40 m (one mesh of the
##   whole body measured 32k).
## StudyArea and the root's script and metas are untouched. Normals use the inverse transpose so
## non-uniform scales shade as before. Safe to re-run (merged groups are left as they are):
##   godot --headless --path . --script res://tools/merge_motorcycle.gd
const SCENE := "res://scenes/props/vehicles/motorcycle.tscn"
const OUT_DIR := "res://scenes/props/vehicles/"
const MECHANICS := ["Engine", "Exhaust", "RearSuspension"]
const HEAVY_TRIANGLES := 30000

func _initialize() -> void:
	var root: Node3D = load(SCENE).instantiate()
	var before := root.find_children("*", "MeshInstance3D", true, false).size()
	for child in root.get_children():
		if not child is Node3D or child.name == "StudyArea": continue
		if child.get_meta("word_key", "") == "wheel":
			var parts: Array = []
			for mesh in child.get_children():
				if mesh is MeshInstance3D and mesh.name != "Visual": parts.append(mesh)
			merge(child, parts, "Detail", "motorcycle_%s_detail" % String(child.name).to_lower())
		elif child.name == "FrontFork":
			merge(child, child.find_children("*", "MeshInstance3D", true, false), "Visual", "motorcycle_fork")
	# Static groups: everything else that only holds meshes.
	var groups: Array = []
	var parts := {"Parts": [], "Mechanics": []}
	for child in root.get_children():
		if not child is Node3D or child.name in ["StudyArea", "FrontFork"] or parts.has(child.name) or child.get_meta("word_key", "") == "wheel": continue
		var meshes := child.find_children("*", "MeshInstance3D", true, false)
		if child is MeshInstance3D: meshes.append(child)
		if meshes.is_empty(): continue
		groups.append(child)
		parts["Mechanics" if child.name in MECHANICS else "Parts"].append_array(meshes)
	merge(root, parts.Parts, "Parts", "motorcycle_parts")
	merge(root, parts.Mechanics, "Mechanics", "motorcycle_mechanics")
	for group in groups:
		root.remove_child(group)
		group.free()
	for node in root.find_children("*", "", true, false): node.owner = root
	var after := root.find_children("*", "MeshInstance3D", true, false).size()
	var packed := PackedScene.new()
	packed.pack(root)
	print("MOTORCYCLE meshes ", before, " -> ", after, "; saved ", ResourceSaver.save(packed, SCENE))
	root.free()
	quit()

## Joins `parts` (MeshInstance3D below `holder`) into one ArrayMesh in holder's space, one surface
## per material, saved as OUT_DIR/<file>.res and shown by a new MeshInstance3D `title` on holder.
func merge(holder: Node3D, parts: Array, title: String, file: String) -> void:
	if parts.size() <= 1 and holder.get_node_or_null(title) != null: return
	if parts.is_empty(): return
	var by_material := {}
	var order: Array = []
	for part in parts:
		var instance := part as MeshInstance3D
		if instance.mesh == null: continue
		var local := relative(holder, instance)
		for surface in instance.mesh.get_surface_count():
			var material: Material = instance.material_override
			if material == null: material = instance.get_surface_override_material(surface)
			if material == null: material = instance.mesh.surface_get_material(surface)
			if not by_material.has(material):
				by_material[material] = []
				order.append(material)
			by_material[material].append([instance.mesh.surface_get_arrays(surface), local])
	var merged := ArrayMesh.new()
	for material in order:
		merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, join(by_material[material]))
		merged.surface_set_material(merged.get_surface_count() - 1, material)
	var path := OUT_DIR + file + ".res"
	merged.resource_name = file
	var triangles := 0
	for i in merged.get_surface_count(): triangles += merged.surface_get_array_index_len(i) / 3
	if triangles >= HEAVY_TRIANGLES: push_error("%s: %d triangles, the game would hide it beyond 40 m" % [file, triangles])
	print("  ", path, ": ", parts.size(), " meshes -> ", merged.get_surface_count(), " surfaces, ", triangles, " triangles; ", ResourceSaver.save(merged, path, ResourceSaver.FLAG_COMPRESS))
	merged = load(path)
	for part in parts:
		part.get_parent().remove_child(part)
		part.free()
	var shown := MeshInstance3D.new()
	shown.name = title
	shown.mesh = merged
	# Small detail (wheel rims and spokes, engine, exhaust) hides beyond 120 m, as the separate
	# parts did before the merge (render_culling.gd keeps a range set here).
	if title in ["Detail", "Mechanics"]:
		shown.visibility_range_end = 120.0
	holder.add_child(shown)

func relative(holder: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var at: Node = node
	while at != holder:
		result = (at as Node3D).transform * result
		at = at.get_parent()
	return result

## Vertices, normals, tangents and UVs of several surfaces, transformed and indexed as one.
func join(pieces: Array) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for piece in pieces:
		var arrays: Array = piece[0]
		var xform: Transform3D = piece[1]
		var normal_basis := xform.basis.inverse().transposed()
		var flip := xform.basis.determinant() < 0
		var start := vertices.size()
		var source_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var source_normals = arrays[Mesh.ARRAY_NORMAL]
		var source_tangents = arrays[Mesh.ARRAY_TANGENT]
		var source_uvs = arrays[Mesh.ARRAY_TEX_UV]
		for i in source_vertices.size():
			vertices.append(xform * source_vertices[i])
			normals.append((normal_basis * source_normals[i]).normalized() if source_normals != null else Vector3.UP)
			if source_tangents != null and source_tangents.size() >= (i + 1) * 4:
				var t := (xform.basis * Vector3(source_tangents[i * 4], source_tangents[i * 4 + 1], source_tangents[i * 4 + 2])).normalized()
				tangents.append_array([t.x, t.y, t.z, source_tangents[i * 4 + 3] * (-1.0 if flip else 1.0)])
			else:
				tangents.append_array([1.0, 0.0, 0.0, 1.0])
			uvs.append(source_uvs[i] if source_uvs != null else Vector2.ZERO)
		var source_indices = arrays[Mesh.ARRAY_INDEX]
		if source_indices == null:
			source_indices = PackedInt32Array(range(source_vertices.size()))
		for i in range(0, source_indices.size(), 3):
			if flip:
				indices.append_array([start + source_indices[i], start + source_indices[i + 2], start + source_indices[i + 1]])
			else:
				indices.append_array([start + source_indices[i], start + source_indices[i + 1], start + source_indices[i + 2]])
	var result := []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = vertices
	result[Mesh.ARRAY_NORMAL] = normals
	result[Mesh.ARRAY_TANGENT] = tangents
	result[Mesh.ARRAY_TEX_UV] = uvs
	result[Mesh.ARRAY_INDEX] = indices
	return result
