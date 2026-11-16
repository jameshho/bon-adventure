extends RefCounted
## Cuts a polygonal hole through flat ground meshes (their collision is rebuilt). The algorithm of
## the deleted scripts/world/ground_openings.gd (git history, before 55f9b83), which cut the home
## pool's first opening; used again by the base step `home_expansion_ground` (12 Nov 2026) for the
## moved pool. Surface 0 keeps its original vertex array (the minimap reads it as the outline);
## only its indices change. Cut pieces go into a second surface.
const LAYERS := ["Natural town terrain", "Island beaches", "Coastal shallows", "Surrounding water"]

## Cuts `corners` (points in `space`) through every ground layer under `town`; returns how many
## meshes changed.
static func cut_layers(town: Node3D, space: Node3D, corners: PackedVector3Array) -> int:
	var changed := 0
	for title in LAYERS:
		var root := town.get_node_or_null(title)
		if root == null:
			continue
		var meshes: Array = [root] if root is MeshInstance3D else root.find_children("*", "MeshInstance3D", false, false)
		for node in meshes:
			var hole := PackedVector2Array()
			for corner in corners:
				var p: Vector3 = node.to_local(space.to_global(corner))
				hole.append(Vector2(p.x, p.z))
			if cut(node, hole):
				changed += 1
	return changed

static func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## Barycentric weights of `q` in the triangle's ground outline.
static func weights(tri: Array, q: Vector2) -> Vector3:
	var a := flat(tri[0])
	var b := flat(tri[1])
	var c := flat(tri[2])
	var d := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	var w0 := ((b.y - c.y) * (q.x - c.x) + (c.x - b.x) * (q.y - c.y)) / d
	var w1 := ((c.y - a.y) * (q.x - c.x) + (a.x - c.x) * (q.y - c.y)) / d
	return Vector3(w0, w1, 1.0 - w0 - w1)

## Cuts `hole` (mesh-local x/z) out of `node`'s mesh. Each source surface keeps its arrays (only
## its indices change) and material; the clipped pieces of a surface's cut triangles go into a new
## surface with the same material, their height, normal, colour and UV interpolated from the source
## triangle. Collision is rebuilt when the mesh had a body. Returns whether anything was cut.
static func cut(node: MeshInstance3D, hole: PackedVector2Array) -> bool:
	var bounds := Rect2(hole[0], Vector2.ZERO)
	for p in hole: bounds = bounds.expand(p)
	var mid := bounds.get_center().x
	# Splitting at the hole's centre keeps every clipped piece a simple polygon.
	var halves := [PackedVector2Array([Vector2(-1e5, -1e5), Vector2(mid, -1e5), Vector2(mid, 1e5), Vector2(-1e5, 1e5)]),
		PackedVector2Array([Vector2(mid, -1e5), Vector2(1e5, -1e5), Vector2(1e5, 1e5), Vector2(mid, 1e5)])]
	var source: Mesh = node.mesh
	var mesh := ArrayMesh.new()
	var cut_any := false
	var extra: Array = []
	for surface in range(source.get_surface_count()):
		var arrays := source.surface_get_arrays(surface)
		var material := source.surface_get_material(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var triangles: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(vertices.size()))
		var kept := PackedInt32Array()
		var pieces := SurfaceTool.new()
		pieces.begin(Mesh.PRIMITIVE_TRIANGLES)
		var surface_cut := false
		var added := 0
		for t in range(0, triangles.size(), 3):
			var ids3 := [triangles[t], triangles[t + 1], triangles[t + 2]]
			var tri := [vertices[ids3[0]], vertices[ids3[1]], vertices[ids3[2]]]
			var outline := PackedVector2Array([flat(tri[0]), flat(tri[1]), flat(tri[2])])
			var area := Rect2(outline[0], Vector2.ZERO).expand(outline[1]).expand(outline[2])
			var twice := (outline[1] - outline[0]).cross(outline[2] - outline[0])
			if absf(twice) < 1e-6 or not area.intersects(bounds):
				kept.append_array(PackedInt32Array(ids3))
				continue
			surface_cut = true
			for half in halves:
				for part in Geometry2D.intersect_polygons(outline, half):
					for piece in Geometry2D.clip_polygons(part, hole):
						var ids := Geometry2D.triangulate_polygon(piece)
						for i in range(0, ids.size(), 3):
							var corner := [ids[i], ids[i + 1], ids[i + 2]]
							# Keep the source triangle's facing.
							if signf((piece[corner[1]] - piece[corner[0]]).cross(piece[corner[2]] - piece[corner[0]])) != signf(twice):
								corner = [ids[i], ids[i + 2], ids[i + 1]]
							for k in corner:
								var q: Vector2 = piece[k]
								var w := weights(tri, q)
								if not normals.is_empty():
									pieces.set_normal((normals[ids3[0]] * w.x + normals[ids3[1]] * w.y + normals[ids3[2]] * w.z).normalized())
								if not colors.is_empty():
									pieces.set_color(colors[ids3[0]] * w.x + colors[ids3[1]] * w.y + colors[ids3[2]] * w.z)
								if not uvs.is_empty():
									pieces.set_uv(uvs[ids3[0]] * w.x + uvs[ids3[1]] * w.y + uvs[ids3[2]] * w.z)
								pieces.add_vertex(Vector3(q.x, tri[0].y * w.x + tri[1].y * w.y + tri[2].y * w.z, q.y))
								added += 1
		var copy: Array = arrays.duplicate()
		copy[Mesh.ARRAY_INDEX] = kept
		if not kept.is_empty():
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, copy)
			mesh.surface_set_material(mesh.get_surface_count() - 1, material)
		if surface_cut:
			cut_any = true
			if added > 0:
				extra.append([pieces, material])
	if not cut_any:
		return false
	for entry in extra:
		entry[0].commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, entry[1])
	node.mesh = mesh
	var solid := false
	for child in node.get_children():
		if child is StaticBody3D:
			solid = true
			child.free()
	if solid:
		node.create_trimesh_collision()
	return true
