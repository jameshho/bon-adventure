extends RefCounted
## Material warm-up for building units added after the town is ready (PERF-06, 25 Nov 2026;
## docs/guides/performance/README.md "Late buildings: sculpt cache and material warm-up").
## app.gd _warm_up() draws the start town behind the loading screen so its shaders are compiled
## before play; a unit added later (nearby loading, the tutorial's staged loading, the picker's
## "load then go") compiled each new material on the frame it was first drawn, all at once: on
## the web (WebGL compiles programs slowly) a stall when the building came into view or was
## entered. warm() draws each new pairing of material and vertex layout in the new unit once,
## with one of the unit's own meshes shrunk far below a pixel just in front of the camera,
## PER_FRAME per frame, so the compiling is spread over frames while the unit is still out of
## sight. The real mesh matters: the driver (ANGLE / Metal on the web) builds a pipeline per
## program and vertex layout, so a stand-in quad warmed only about a third of the stall (native,
## measured 25 Nov). Static pieces merged into MultiMeshes (render_culling.gd) are warmed as
## MultiMeshes (the renderer's instanced variant), the rest as plain meshes. Materials count as
## seen by their shader-shaping settings (_signature()), so a colour or a texture image alone is
## not drawn again.
## app.gd connects it to Main.unit_added, and forget() to Main.unit_removed: a unit freed far away
## (web, 26 Nov 2026) may take the last user of a shader with it, so its materials are drawn
## again when it returns. Checks that load main.tscn directly do not run it.
## VT_WARM_UNITS=0 turns it off (measuring).
const ModularTown := preload("res://scripts/world/modular_town.gd")
## Materials drawn per frame.
const PER_FRAME := 4
## Longest side of a drawn mesh and its distance beyond the camera's near plane (metres): well
## under a pixel.
const SIZE := 0.0002
const AHEAD := 0.02

static var on := OS.get_environment("VT_WARM_UNITS") != "0"
## Signatures already drawn (or loaded with the start town and drawn by app.gd's warm-up).
static var _seen := {}
static var _signatures := {}
## Unit key -> the signatures its warm() marked seen (forget()).
static var _by_unit := {}
## Class -> names of its stored on/off, mode and resource settings (_signature()).
static var _shaping := {}
## The last warm(): milliseconds spent finding the materials, and how many were drawn (probe).
static var last_scan_ms := 0.0
static var last_count := 0

## Draws unit `key`'s new materials once (await it). Nothing when off or without a camera.
static func warm(game: Node, key: String) -> void:
	if not on or not is_instance_valid(game):
		return
	var started := Time.get_ticks_usec()
	var todo := materials(game, key)
	last_scan_ms = (Time.get_ticks_usec() - started) / 1000.0
	last_count = todo.size()
	if todo.is_empty():
		return
	var tree := game.get_tree()
	while not todo.is_empty():
		var camera := game.get_viewport().get_camera_3d()
		if camera == null:
			return
		var holder := Node3D.new()
		holder.name = "UnitWarmup"
		camera.add_child(holder)
		holder.position = Vector3(0.0, 0.0, -(camera.near + AHEAD))
		for entry in todo.slice(0, PER_FRAME):
			holder.add_child(_drawer(entry[0], entry[1], entry[2]))
		todo = todo.slice(PER_FRAME)
		# Two frames: the second is drawn with them for sure (app.gd _warm_up()).
		await tree.process_frame
		await tree.process_frame
		holder.queue_free()

## [material, instanced, mesh] for each material and vertex layout of unit `key` not seen yet;
## marks them seen.
static func materials(game: Node, key: String) -> Array:
	var town: Node = game.get("apartment")
	var registry: Dictionary = ModularTown.registry()
	if town == null or not registry.has(key):
		return []
	var nodes: Array = []
	for path in registry[key].parts:
		var part := town.get_node_or_null(NodePath(path))
		if part != null:
			nodes.append(part)
			nodes.append_array(part.find_children("*", "GeometryInstance3D", true, false))
	var batches := town.get_node_or_null("StaticRenderBatches/Unit_" + key)
	if batches != null:
		nodes.append_array(batches.find_children("*", "MultiMeshInstance3D", true, false))
	var todo: Array = []
	var marked: Array = _by_unit.get(key, [])
	_by_unit[key] = marked
	for node in nodes:
		if node is MultiMeshInstance3D:
			var multimesh := (node as MultiMeshInstance3D).multimesh
			if multimesh == null or multimesh.mesh == null:
				continue
			for surface in multimesh.mesh.get_surface_count():
				var material: Material = node.material_override if node.material_override != null else multimesh.mesh.surface_get_material(surface)
				_add(todo, material, true, multimesh.mesh, surface, marked)
		elif node is MeshInstance3D and (node as MeshInstance3D).mesh != null and not node.has_meta("render_batched"):
			var mesh_node := node as MeshInstance3D
			for surface in mesh_node.mesh.get_surface_count():
				_add(todo, mesh_node.get_active_material(surface), false, mesh_node.mesh, surface, marked)
				_add(todo, mesh_node.material_overlay, false, mesh_node.mesh, surface, marked)
	return todo

## Unit `key` was freed: its signatures are new again, and the per-material cache (keyed by
## instance ids that may be reused) starts over.
static func forget(key: String) -> void:
	for signature in _by_unit.get(key, []):
		_seen.erase(signature)
	_by_unit.erase(key)
	_signatures.clear()

static func _add(todo: Array, material: Material, instanced: bool, mesh: Mesh, surface: int, marked: Array) -> void:
	if material == null:
		return
	# The vertex layout: an ArrayMesh's surface format, a primitive mesh's class.
	var layout: String = str(mesh.surface_get_format(surface)) if mesh is ArrayMesh else mesh.get_class()
	var signature := _signature(material) + "|" + layout + ("|multimesh" if instanced else "")
	if _seen.has(signature):
		return
	_seen[signature] = true
	marked.append(signature)
	todo.append([material, instanced, mesh])

## What decides the shader a material compiles to: its class and its on/off and mode settings and
## which texture slots are filled (not colours, numbers or the images), plus its next pass; for
## a ShaderMaterial, its Shader.
static func _signature(material: Material) -> String:
	var id := material.get_instance_id()
	if _signatures.has(id):
		return _signatures[id]
	var signature: String
	if material is ShaderMaterial:
		var shader := (material as ShaderMaterial).shader
		signature = "shader %d" % (shader.get_instance_id() if shader != null else 0)
	else:
		var type := material.get_class()
		if not _shaping.has(type):
			var names := PackedStringArray()
			for property in material.get_property_list():
				if (property.usage & PROPERTY_USAGE_STORAGE) != 0 and property.name != "next_pass" \
						and property.type in [TYPE_BOOL, TYPE_INT, TYPE_OBJECT]:
					names.append(property.name)
			_shaping[type] = names
		var parts := PackedStringArray([type])
		for name in _shaping[type]:
			var value: Variant = material.get(name)
			parts.append(("1" if value != null else "0") if value is Object or value == null else str(value))
		signature = "|".join(parts)
	if material.next_pass != null:
		signature += " > " + _signature(material.next_pass)
	_signatures[id] = signature
	return signature

## `mesh` shrunk to SIZE and centred, drawn with `material` (every surface), as a MultiMesh of one
## when `instanced`.
static func _drawer(material: Material, instanced: bool, mesh: Mesh) -> GeometryInstance3D:
	var box := mesh.get_aabb()
	var shrink := SIZE / maxf(box.get_longest_axis_size(), 0.0001)
	var pose := Transform3D(Basis.from_scale(Vector3.ONE * shrink), -box.get_center() * shrink)
	var drawer: GeometryInstance3D
	if instanced:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = 1
		multimesh.set_instance_transform(0, pose)
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multimesh
		drawer = batch
	else:
		var single := MeshInstance3D.new()
		single.mesh = mesh
		single.transform = pose
		drawer = single
	drawer.material_override = material
	drawer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return drawer
