extends RefCounted
## Turns a built clay display (scenes/animals/*_clay.tscn: one fused distance-field body plus
## separate pieces) into a skinned, seam-free rig for clay_animator.gd. Pilot: the clay pig
## (tools/build_pig_clay_rig.gd, 16 Nov 2026). Reads the display's finished meshes and never
## changes the mesher (lion_clay.gd / cow_clay.gd) or the display scene.
##
## Why skinning: body, head and legs are one mesh, so cutting them apart would leave seams.
## Every vertex instead gets up to four bone weights, blended by its distance to simple shapes
## (spheres and capsules) that stand for each bone's part of the body:
##     w_i = exp(-(d_i - d_min) / blend)        d_i = distance to bone i's shapes minus radius
## so the weights change smoothly across the fold between head and body or leg and hip, and the
## skin stretches there instead of tearing.
##
## Spec (model space: the display's own coordinates, ground y 0, head toward -Z):
##   bones:  [{name, parent ("" for the root), pivot: Vector3, shapes: [[a, b, radius], ...]}]
##           A shape is a capsule from a to b (a sphere when a == b).
##   blend:  softness of the weights between bones, in model units.
##   parts:  {mesh node name: bone name (rigid) | [bone names] (blended over those bones)}
##           A mesh not listed is left out of the rig.
##   eyes:   {"mesh": node name, "bone": bone name, "eyes": [{name, origin, basis}]}: the eye
##           mesh is split by the nearest eye and each eye becomes its own MeshInstance3D centred
##           on its node (x toward the outer corner, y up the eye, z out of the face) under a
##           BoneAttachment3D named "Head", so plush_life.gd can blink it (it squashes local y).
##   keep:   other display children copied as they are (e.g. "Footprint").
##   simplify: {mesh node name: fraction of triangles to keep}. Skinning costs per vertex every
##           frame the pose changes, so dense clay meshes are thinned at bake time with Godot's
##           mesh simplifier (ImporterMesh LODs, meshoptimizer): it keeps a subset of the
##           original vertices with their own normals and colours, so the clay stays smooth.
##
##   merge:  true joins skinned parts that share a material into one surface ("Clay").
##   on_head: rigid display meshes (e.g. "Face details") moved under the Head attachment
##           unskinned, so they cost no skinning.
##
## Output: root (the display's name + "Rigged") with Skeleton3D (the skinned meshes as its
## children), Head (BoneAttachment3D on `eyes.bone`: eyes and on_head pieces) and the kept nodes.

const MAX_INFLUENCE := 4


## Builds the rig from an instantiated display. The display is not changed.
static func build(display: Node3D, spec: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(display.name).replace("Display", "") + "Rigged"
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)
	var bones: Array = spec.bones
	var pivots := {}
	for bone in bones:
		var index := skeleton.add_bone(bone.name)
		pivots[bone.name] = bone.pivot
		if bone.parent != "":
			skeleton.set_bone_parent(index, skeleton.find_bone(bone.parent))
		var parent_pivot: Vector3 = pivots.get(bone.parent, Vector3.ZERO)
		skeleton.set_bone_rest(index, Transform3D(Basis(), bone.pivot - parent_pivot))
	skeleton.reset_bone_poses()
	var skin := Skin.new()
	for bone in bones:
		skin.add_named_bind(bone.name, Transform3D(Basis(), -(bone.pivot as Vector3)))
	var stats := {}
	# Skinned parts, merged into one surface per material when spec.merge: on the Compatibility
	# renderer each skinned surface costs about as much as a dense one (perf.json), so a pig is
	# one skinned surface, not five.
	var groups := []
	for part: String in spec.parts:
		var source := display.get_node_or_null(part) as MeshInstance3D
		if source == null:
			push_warning("clay_rig: no mesh %s" % part)
			continue
		var target = spec.parts[part]
		var names: Array = [target] if target is String else target
		var arrays := source.mesh.surface_get_arrays(0)
		var keep: float = spec.get("simplify", {}).get(part, 1.0)
		if keep < 1.0:
			arrays = _simplified(arrays, keep)
		arrays = _skinned(arrays, skeleton, bones, names, spec.blend, stats, part)
		var group = null
		if spec.get("merge", false):
			for g in groups:
				if g.material == source.material_override and g.shadow == source.cast_shadow:
					group = g
		if group == null:
			group = {"name": part, "material": source.material_override, "shadow": source.cast_shadow, "arrays": []}
			groups.append(group)
		group.arrays.append(arrays)
	for g in groups:
		var mi := MeshInstance3D.new()
		mi.name = "Clay" if g.arrays.size() > 1 else g.name
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _joined(g.arrays))
		mi.mesh = mesh
		mi.material_override = g.material
		mi.cast_shadow = g.shadow
		mi.skin = skin
		mi.skeleton = NodePath("..")
		skeleton.add_child(mi)
	# Rigid pieces on the head (eyes, and spec.on_head) ride a BoneAttachment3D named "Head".
	var on_head: Array = spec.get("on_head", [])
	if spec.has("eyes") or not on_head.is_empty():
		var bone_name: String = spec.eyes.bone if spec.has("eyes") else "head"
		var head := BoneAttachment3D.new()
		head.name = "Head"
		root.add_child(head)
		head.use_external_skeleton = true
		head.external_skeleton = NodePath("../Skeleton3D")
		head.bone_name = bone_name
		var head_pivot: Vector3 = pivots[bone_name]
		head.transform = Transform3D(Basis(), head_pivot)
		if spec.has("eyes"):
			var source := display.get_node(spec.eyes.mesh) as MeshInstance3D
			for eye in _split_eyes(source.mesh, spec.eyes.eyes):
				var node := MeshInstance3D.new()
				node.name = eye.name
				node.mesh = eye.mesh
				node.transform = Transform3D(eye.basis, (eye.origin as Vector3) - head_pivot)
				node.material_override = source.material_override
				node.cast_shadow = source.cast_shadow
				head.add_child(node)
		for part: String in on_head:
			var piece := (display.get_node(part) as MeshInstance3D).duplicate() as MeshInstance3D
			piece.transform = Transform3D(Basis(), -head_pivot)
			head.add_child(piece)
	for keep: String in spec.get("keep", []):
		var node := display.get_node_or_null(keep)
		if node != null:
			root.add_child(node.duplicate())
	_own(root, root)
	root.set_meta("rig_stats", stats)
	return root


static func _own(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_own(child, owner)


## Distance from p to a bone's shapes, minus their radius (negative inside).
static func _bone_distance(p: Vector3, shapes: Array) -> float:
	var best := INF
	for s in shapes:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		var ab := b - a
		var t := 0.0 if ab.length_squared() < 1e-12 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t) - float(s[2]))
	return best


## A copy of `mesh` (one surface) with bone indices and weights. With one bone name every
## vertex goes to it; with several, the weights blend by distance to their shapes.
static func _skinned(arrays: Array, skeleton: Skeleton3D, bones: Array, names: Array, blend: float, stats: Dictionary, part: String) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ids := PackedInt32Array()
	var weights := PackedFloat32Array()
	ids.resize(verts.size() * MAX_INFLUENCE)
	weights.resize(verts.size() * MAX_INFLUENCE)
	var chosen := []
	for bone in bones:
		if names.has(bone.name):
			chosen.append([skeleton.find_bone(bone.name), bone.shapes])
	var blended := 0
	for v in verts.size():
		var p := verts[v]
		var near := []
		var lowest := INF
		for c in chosen:
			var d := _bone_distance(p, c[1]) if chosen.size() > 1 else 0.0
			near.append([d, c[0]])
			lowest = minf(lowest, d)
		near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
		var total := 0.0
		var w := []
		for k in mini(near.size(), MAX_INFLUENCE):
			var value := exp(-(float(near[k][0]) - lowest) / blend)
			w.append(value)
			total += value
		if w.size() > 1 and w[1] / total > 0.02:
			blended += 1
		for k in MAX_INFLUENCE:
			var at := v * MAX_INFLUENCE + k
			if k < w.size():
				ids[at] = near[k][1]
				weights[at] = w[k] / total
			else:
				ids[at] = 0
				weights[at] = 0.0
	arrays[Mesh.ARRAY_BONES] = ids
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	var index = arrays[Mesh.ARRAY_INDEX]
	stats[part] = {"vertices": verts.size(), "triangles": (index.size() if index != null else verts.size()) / 3, "blended": blended}
	return arrays


## Several skinned array sets as one (indexed; colours white where a part had none).
static func _joined(sets: Array) -> Array:
	if sets.size() == 1:
		return sets[0]
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var b := PackedInt32Array()
	var w := PackedFloat32Array()
	var idx := PackedInt32Array()
	for a in sets:
		var base := v.size()
		var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		v.append_array(verts)
		n.append_array(a[Mesh.ARRAY_NORMAL])
		if a[Mesh.ARRAY_COLOR] != null:
			c.append_array(a[Mesh.ARRAY_COLOR])
		else:
			for i in verts.size(): c.append(Color.WHITE)
		b.append_array(a[Mesh.ARRAY_BONES])
		w.append_array(a[Mesh.ARRAY_WEIGHTS])
		if a[Mesh.ARRAY_INDEX] != null:
			for i: int in a[Mesh.ARRAY_INDEX]: idx.append(base + i)
		else:
			for i in verts.size(): idx.append(base + i)
	out[Mesh.ARRAY_VERTEX] = v
	out[Mesh.ARRAY_NORMAL] = n
	out[Mesh.ARRAY_COLOR] = c
	out[Mesh.ARRAY_BONES] = b
	out[Mesh.ARRAY_WEIGHTS] = w
	out[Mesh.ARRAY_INDEX] = idx
	return out


## `arrays` (indexed triangles) thinned to about `keep` of its triangles: the simplifier's
## level closest to it, with the unused vertices dropped.
static func _simplified(arrays: Array, keep: float) -> Array:
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if index.is_empty():
		return arrays
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	im.generate_lods(25.0, 60.0, [])
	var want := int(index.size() * keep)
	var best := index
	for i in im.get_surface_lod_count(0):
		var lod := im.get_surface_lod_indices(0, i)
		if absi(lod.size() - want) < absi(best.size() - want):
			best = lod
	var remap := {}
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var new_index := PackedInt32Array()
	for i in best:
		if not remap.has(i):
			remap[i] = remap.size()
		new_index.append(remap[i])
	var order := PackedInt32Array()
	order.resize(remap.size())
	for old in remap:
		order[remap[old]] = old
	for slot in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR]:
		var src = arrays[slot]
		if src == null:
			continue
		var dst = src.duplicate()
		dst.resize(order.size())
		for k in order.size():
			dst[k] = src[order[k]]
		out[slot] = dst
	out[Mesh.ARRAY_INDEX] = new_index
	return out


## The eye mesh split by the nearest eye origin, each piece in its eye's own frame.
static func _split_eyes(mesh: Mesh, eyes: Array) -> Array:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if index.is_empty():
		for i in verts.size(): index.append(i)
	var out := []
	for e in eyes:
		out.append({"name": e.name, "origin": e.origin, "basis": e.basis, "v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray()})
	for t in range(0, index.size(), 3):
		var centre := (verts[index[t]] + verts[index[t + 1]] + verts[index[t + 2]]) / 3.0
		var best := 0
		for i in eyes.size():
			if centre.distance_to(eyes[i].origin) < centre.distance_to(eyes[best].origin):
				best = i
		var e: Dictionary = out[best]
		var to_local := Transform3D(e.basis, e.origin).affine_inverse()
		for k in 3:
			var i := index[t + k]
			e.v.append(to_local * verts[i])
			e.n.append((to_local.basis * norms[i]).normalized())
			e.c.append(cols[i] if not cols.is_empty() else Color.WHITE)
	for e in out:
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = e.v
		a[Mesh.ARRAY_NORMAL] = e.n
		a[Mesh.ARRAY_COLOR] = e.c
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		e.mesh = m
	return out
