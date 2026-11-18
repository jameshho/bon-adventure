extends RefCounted
## Sculpt cache and shared character shaders (6 Nov 2026, docs/guides/MODULAR_TOWN.md boot timing).
##
## Every plush character sculpts its meshes in GDScript in _ready, and every costume measures
## its wearer's body and builds its garments (together about 2.3 s for the restaurant and
## police staff plus the player's nine characters). The result only depends on the scripts,
## the character's own variables and its pose, so it is kept in user://sculpt_cache/ and
## reused on the next launch:
##   build(sculpt)   pig_art_variants.gd / plush_sculpt.gd _ready: the body meshes
##   dress(costume)  plush_costume.gd _ready: the garments plus the wearer parts the costume
##                   hid or reshaped; only when every wearer mesh is still exactly what the
##                   cache built (a suspect's random hair, say, is built normally instead)
## A restored character or costume also gets back the script variables its build set (the
## costume's body measurements, BonBon's colours), so it behaves exactly like a built one.
## Keys hash the source of the whole script chain (and the outfit data), every script
## variable, and the transforms of the parts, so an edit simply builds and caches again.
## Older entries of an edited script are deleted. Never used in the editor; VT_SCULPT_CACHE=0
## turns the files off.
##
## Shared meshes (17 Nov 2026, WebGL context loss, docs/guides/performance/README.md "GPU memory
## on the web"): characters and costumes with the same key get the same mesh and material
## resources in memory (the first one built or loaded, kept in _shared), so the GPU holds one
## copy (two beagles, ten pizza staff in one shirt). Safe because nothing edits a character's
## meshes or materials after its build: plush_life.gd blinks by node transform, costumes
## hide parts by `visible` and reshape them into NEW meshes (plush_costume.gd _reshape), the
## player's aura is a node overlay (bonbon_effects.gd). Code that changes a built character's
## mesh or material in place must give it its own copy first. Script variables are copied per
## character. An entry is dropped once no character (for a costume entry: no costume) that
## used it is left, so suspects with random shirts or outfits tried on in the fitting room do
## not pile up for the session. Works without the files too (checks run with VT_SCULPT_CACHE=0); not in the
## editor; VT_MESH_SHARE=0 turns it off (measuring).
##
## Shaders: each character used to make its own Shader objects with identical code, and every
## copy is compiled on the first frame (about 0.9 s). shared_shader() keeps one per code.
const FOLDER := "user://sculpt_cache/"
## Part of every key: raise it when the stored layout changes, so old entries are not read.
const FORMAT := "3"
const COSTUME_DATA := "res://data/plush_costumes.json"
## What a build may change on a mesh part; only the changed ones are stored and restored.
const FIELDS := ["mesh", "transform", "cast_shadow", "visible"]
static var _shaders := {}
static var _source_hashes := {}
## Characters whose current meshes all came through here: instance id -> {key, meshes}.
static var _built := {}
## Key -> the entry every character with that key restores from (sharing() only).
static var _shared := {}
## Key -> WeakRefs of the characters (costumes) using that entry.
static var _users := {}

## Off in the editor, and with the environment variable VT_SCULPT_CACHE=0 (always build).
static func enabled() -> bool:
	return not Engine.is_editor_hint() and OS.get_environment("VT_SCULPT_CACHE") != "0"

## Characters with the same key share meshes in memory (see the header); off in the editor.
static func sharing() -> bool:
	return not Engine.is_editor_hint() and OS.get_environment("VT_MESH_SHARE") != "0"

static func shared_shader(code: String) -> Shader:
	if not _shaders.has(code):
		var shader := Shader.new()
		shader.code = code
		_shaders[code] = shader
	return _shaders[code]

## Builds `sculpt` (its _build()) or restores its meshes from the cache.
static func build(sculpt: Node3D) -> void:
	if not enabled() and not sharing():
		sculpt.call("_build")
		return
	var key := _sculpt_key(sculpt)
	_finish(sculpt, null, key, func() -> void: sculpt.call("_build"))

## Builds `costume` (its _build()) or restores its pieces and wearer changes from the cache.
static func dress(costume: Node3D) -> void:
	var wearer := costume.get_parent() as Node3D
	if (not enabled() and not sharing()) or wearer == null:
		costume.call("_build")
		return
	var key := _costume_key(costume, wearer)
	_finish(wearer, costume, key, func() -> void: costume.call("_build"))

static func _finish(root: Node3D, costume: Node3D, key: String, make: Callable) -> void:
	_drop_unused()
	if key == "" or not _restore(root, costume, key):
		var before := _parts(root, costume)
		make.call()
		if key != "":
			_store(root, costume, key, before)
	if key != "":
		var meshes := {}
		var parts := _parts(root, costume)
		for path in parts:
			if parts[path][0] != null:
				meshes[path] = parts[path][0]
		_built[root.get_instance_id()] = {"key": key, "meshes": meshes}
		if _shared.has(key):
			if not _users.has(key):
				_users[key] = []
			_users[key].append(weakref(costume if costume != null else root))
	else:
		_built.erase(root.get_instance_id())

## Forgets shared entries whose characters (costumes) are all gone, so their meshes can be freed.
static func _drop_unused() -> void:
	for key in _shared.keys():
		var alive: Array = _users.get(key, []).filter(func(user: WeakRef) -> bool: return user.get_ref() != null)
		if alive.is_empty():
			_shared.erase(key)
			_users.erase(key)
		else:
			_users[key] = alive

## Mesh parts of `root` outside `skip`: path -> FIELDS values.
static func _parts(root: Node3D, skip: Node) -> Dictionary:
	var parts := {}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		if skip != null and (node == skip or skip.is_ancestor_of(node)):
			continue
		parts[String(root.get_path_to(node))] = [node.mesh, node.transform, node.cast_shadow, node.visible]
	return parts

static func _source_hash(script: Script) -> String:
	if not _source_hashes.has(script):
		var sources := ""
		var level := script
		while level != null:
			if level.source_code == "":
				sources = ""
				break
			sources += level.resource_path + "\n" + level.source_code
			level = level.get_base_script()
		_source_hashes[script] = (FORMAT + sources).sha256_text().substr(0, 16) if sources != "" else ""
	return _source_hashes[script]

## Script variables of `node` as text; "" when one cannot be compared (a callback set
## from outside before the build).
static func _variables(node: Node, state: PackedStringArray) -> bool:
	for property in node.get_property_list():
		if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var value: Variant = node.get(property.name)
		if value is Callable:
			if (value as Callable).is_valid():
				return false
			continue
		if value is Object:
			continue
		state.append(property.name + "=" + var_to_str(value))
	return true

static func _sculpt_key(sculpt: Node3D) -> String:
	var script: Script = sculpt.get_script()
	var source := _source_hash(script)
	var state := PackedStringArray([Engine.get_version_info().string])
	if source == "" or not _variables(sculpt, state):
		return ""
	for node in sculpt.find_children("*", "MeshInstance3D", true, false):
		state.append(String(sculpt.get_path_to(node)) + " " + var_to_str(node.transform))
	return script.resource_path.get_file().get_basename() + "-" + source + "-" + "\n".join(state).sha256_text().substr(0, 16)

static func _costume_key(costume: Node3D, wearer: Node3D) -> String:
	var entry: Dictionary = _built.get(wearer.get_instance_id(), {})
	var source := _source_hash(costume.get_script())
	if entry.is_empty() or source == "":
		return ""
	# The wearer must still be exactly what the cache built (and later costumes reshaped).
	var meshes: Dictionary = entry.meshes
	var parts := _parts(wearer, costume)
	var count := 0
	for path in parts:
		if parts[path][0] == null:
			continue
		count += 1
		if meshes.get(path) != parts[path][0]:
			return ""
	if count != meshes.size():
		return ""
	source = (source + FileAccess.get_file_as_string(COSTUME_DATA)).sha256_text().substr(0, 16)
	var state := PackedStringArray([entry.key, var_to_str(costume.transform)])
	if not _variables(costume, state):
		return ""
	for node in wearer.find_children("*", "Node3D", true, false):
		if node == costume or costume.is_ancestor_of(node):
			continue
		state.append(String(wearer.get_path_to(node)) + " " + var_to_str(node.transform) + " " + str(node.visible))
	return "plush_costume-" + source + "-" + "\n".join(state).sha256_text().substr(0, 16)

static func _restore(root: Node3D, costume: Node3D, key: String) -> bool:
	var saved: Resource = _shared.get(key) if sharing() else null
	if saved == null:
		var path := FOLDER + key + ".res"
		if not enabled() or not FileAccess.file_exists(path):
			return false
		# Fresh copies from the file (shared below only when sharing() is on).
		saved = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if saved == null or not saved.has_meta("parts"):
			return false
		if sharing():
			_shared[key] = saved
	var parts: Dictionary = saved.get_meta("parts")
	for node_path in parts:
		if not root.get_node_or_null(NodePath(node_path)) is MeshInstance3D or not parts[node_path] is Dictionary:
			return false
	if costume != null and not saved.get_meta("pieces") is PackedScene:
		return false
	if not saved.get_meta("state") is Dictionary:
		return false
	for node_path in parts:
		var node := root.get_node(NodePath(node_path)) as MeshInstance3D
		var part: Dictionary = parts[node_path]
		for field in part:
			node.set(field, part[field])
		_share_shaders(node)
	if costume != null:
		var holder: Node = (saved.get_meta("pieces") as PackedScene).instantiate()
		for piece in holder.get_children():
			holder.remove_child(piece)
			# Built pieces have no owner: drop the holder's, like a fresh build.
			for part in [piece] + piece.find_children("*", "", true, false):
				part.owner = null
			costume.add_child(piece)
			_share_shaders(piece)
		holder.free()
	_set_state(costume if costume != null else root, root, saved.get_meta("state"))
	return true

static func _store(root: Node3D, costume: Node3D, key: String, before: Dictionary) -> void:
	var state := _get_state(costume if costume != null else root, root)
	if state.is_empty():
		return
	# Only what the build changed: e.g. a tail the town hid stays hidden, whichever character
	# the entry was stored from.
	var parts := {}
	var after := _parts(root, costume)
	for node_path in after:
		var was: Array = before.get(node_path, [null, null, null, null])
		var part := {}
		for i in FIELDS.size():
			if after[node_path][i] != was[i]:
				part[FIELDS[i]] = after[node_path][i]
		if not part.is_empty():
			parts[node_path] = part
	var saved := Resource.new()
	saved.set_meta("parts", parts)
	saved.set_meta("state", state)
	# The pieces are packed from duplicates of this costume's nodes, which keep its meshes: the
	# next wearer with this key instantiates the same ones.
	if costume != null:
		var holder := Node3D.new()
		for piece in costume.get_children():
			holder.add_child(piece.duplicate())
		for node in holder.find_children("*", "", true, false):
			node.owner = holder
		var packed := PackedScene.new()
		var error := packed.pack(holder)
		holder.free()
		if error != OK:
			return
		saved.set_meta("pieces", packed)
	if sharing():
		_shared[key] = saved
	if not enabled():
		return
	DirAccess.make_dir_recursive_absolute(FOLDER)
	# Entries made from an older version of the same script are stale.
	var current := key.substr(0, key.rfind("-") + 1)
	var family := key.substr(0, key.find("-") + 1)
	for file in DirAccess.get_files_at(FOLDER):
		if file.begins_with(family) and not file.begins_with(current):
			DirAccess.remove_absolute(FOLDER + file)
	ResourceSaver.save(saved, FOLDER + key + ".res", ResourceSaver.FLAG_COMPRESS)

## Script variables of `node` after its build: {vars, calls, nodes}; {} when one cannot be
## kept (a lambda, a callback or node from elsewhere). Shaders are made again on demand.
static func _get_state(node: Node, wearer: Node) -> Dictionary:
	var vars := {}
	var calls := {}
	var nodes := {}
	for property in node.get_property_list():
		if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var value: Variant = node.get(property.name)
		if value is Callable:
			var callback := value as Callable
			if not callback.is_valid():
				continue
			if callback.is_custom() or callback.get_object() != node:
				return {}
			calls[property.name] = callback.get_method()
		elif value is Shader:
			continue
		elif value is Node:
			if value != node and value != wearer:
				return {}
			nodes[property.name] = "self" if value == node else "wearer"
		elif not _storable(value):
			return {}
		else:
			vars[property.name] = value
	return {"vars": vars, "calls": calls, "nodes": nodes}

static func _storable(value: Variant) -> bool:
	if value is Object:
		return value is Resource
	if value is Array:
		return (value as Array).all(func(item: Variant) -> bool: return _storable(item))
	if value is Dictionary:
		return (value as Dictionary).keys().all(func(item: Variant) -> bool: return _storable(item)) and (value as Dictionary).values().all(func(item: Variant) -> bool: return _storable(item))
	return true

static func _set_state(node: Node, wearer: Node, state: Dictionary) -> void:
	for name in state.get("vars", {}):
		var value: Variant = state.vars[name]
		# Each character gets its own arrays and dictionaries (an entry may be shared).
		if value is Array or value is Dictionary:
			value = value.duplicate(true)
		var current: Variant = node.get(name)
		# A typed array (the sculpt's _body_profile) comes back untyped, and set() would
		# silently keep the old value: convert it into the variable's own type.
		if current is Array and (current as Array).is_typed() and value is Array:
			var typed: Array = (current as Array).duplicate()
			typed.assign(value)
			value = typed
		node.set(name, value)
	for name in state.get("calls", {}):
		node.set(name, Callable(node, state.calls[name]))
	for name in state.get("nodes", {}):
		node.set(name, node if state.nodes[name] == "self" else wearer)

## Points loaded materials at the shared shaders and drops the cache file's resource paths.
static func _share_shaders(node: Node) -> void:
	for mesh_node in [node] + node.find_children("*", "GeometryInstance3D", true, false):
		var materials: Array = []
		if mesh_node is GeometryInstance3D and mesh_node.material_override != null:
			materials.append(mesh_node.material_override)
		if mesh_node is MeshInstance3D and mesh_node.mesh != null:
			# Loaded parts must look generated: the town bake strips them, never links the cache.
			mesh_node.mesh.resource_path = ""
			for surface in mesh_node.mesh.get_surface_count():
				materials.append(mesh_node.mesh.surface_get_material(surface))
		for material in materials:
			while material != null:
				material.resource_path = ""
				if material is ShaderMaterial and (material as ShaderMaterial).shader != null:
					(material as ShaderMaterial).shader = shared_shader((material as ShaderMaterial).shader.code)
				material = material.next_pass
