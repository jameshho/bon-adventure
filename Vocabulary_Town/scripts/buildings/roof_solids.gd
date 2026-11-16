extends RefCounted
## Collision for decorative roofs and canopies (7 Nov 2026, user decision): the roof/canopy
## meshes that docs/evidence/town-checks/check_rooftops.gd reported as "Solid surface above" get a StaticBody3D
## "RoofSolid" (collision layer 1, like the other roofs) under the mesh, so the learner can
## land on them and cannot pass through. Collision only; nothing visible changes. Used by the
## units' own steps "solid_roofs" (home, playground, police, airport, hospital, restaurants,
## chapel, base); the rule is the one of the deleted rooftop_collisions.gd pass.

## Meshes at or below each path (town-relative) that are at least 2 x 2 wide (the check's rule;
## thin fascias, tile courses and ridge caps stay non-solid) and have no body yet. Returns how
## many bodies were added; a missing path is an error. Paths listed in `filled` get a convex
## (filled) shape instead: for a cap that sits on a slab and is open at its apex.
static func add(town: Node3D, paths: Array, filled: Array = []) -> int:
	var added := 0
	for path in paths:
		var node: Node = town.get_node_or_null(NodePath(path))
		if node == null:
			push_error("roof_solids: missing " + str(path))
			continue
		var meshes: Array = [node] if node is MeshInstance3D else []
		meshes.append_array(node.find_children("*", "MeshInstance3D", true, false))
		for mesh in meshes:
			if mesh.mesh == null or not mesh.find_children("*", "StaticBody3D", true, false).is_empty():
				continue
			var size: Vector3 = mesh.mesh.get_aabb().size
			if size.x < 2.0 or size.z < 2.0:
				continue
			mesh.add_child(body_for(mesh.mesh, filled.has(path)))
			added += 1
	return added

## Box meshes get a matching box; sloped and faceted roofs a two-sided trimesh of their surface,
## which does not fill the rooms beneath (or, `filled`, their convex hull).
static func body_for(mesh: Mesh, filled := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "RoofSolid"
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	if mesh is BoxMesh:
		var box := BoxShape3D.new()
		box.size = mesh.size
		collision.shape = box
	elif filled:
		collision.shape = mesh.create_convex_shape(true, false)
	else:
		var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
		shape.backface_collision = true
		collision.shape = shape
	body.add_child(collision)
	return body
