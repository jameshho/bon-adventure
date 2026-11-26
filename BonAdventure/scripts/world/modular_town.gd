extends RefCounted
## Modular town loader (docs/guides/MODULAR_TOWN.md). Main instances the base world
## (scenes/town/base.scn); this puts the building units listed in data/buildings.json back
## into it. With dev_focus.txt / VT_FOCUS listing buildings, only those units are loaded.
##
## A unit scene's root holds one child per part (see tools/bake_unit.gd). Each part
## carries `unit_parent` (its original parent, a path under the town root), `unit_name` and
## `unit_index`, and is stored in town coordinates, so the unit can be opened on its own in
## the editor. At load every part goes back to its original node path (saved data, checks and
## the bake rely on it); runtime code finds buildings with building() instead of those paths.
##
## Node references in metadata cannot be saved; the bake stores them as town-relative paths
## (`<meta>__ref` / `<meta>__refs`) and lists the nodes holding them in `node_refs` on the
## scene root. restore_node_refs() turns them back into nodes (missing units are skipped);
## `viewport_texture` links give a sprite its SubViewport's texture again.
const REGISTRY := "res://data/buildings.json"
const FOLDER := "res://scenes/town/"
## Binary scenes: about 5x faster to load than text (measured 6 Nov 2026).
const EXTENSION := "scn"
const DevFocus = preload("res://scripts/core/dev_focus.gd")

## Main (the node with `apartment` and `seating`) above `node`, for behaviour nodes saved in
## the town scenes: a saved scene cannot keep their `game` reference, so they find it in _ready.
static func find_game(node: Node) -> Node:
	var parent := node.get_parent()
	while parent != null:
		if "apartment" in parent and "seating" in parent:
			return parent
		parent = parent.get_parent()
	return null

static func registry() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(REGISTRY)).units

static var _unit_parts := {}

## Building address book: the node of building unit `key` (data/buildings.json) in `town`,
## so runtime code does not spell out historical node paths. `part` indexes the unit's
## `parts` (0 = its site, e.g. "RelocatedSites/Home"; see the registry for the others) and
## `below` is an optional path inside that part, e.g. building(town, "home", 0, "Garage door").
## Returns null when the unit is not loaded (dev focus; its site may still exist as an empty
## layout pivot) or the node is missing, so callers must handle a missing building.
static func building(town: Node, key: String, part := 0, below := "") -> Node3D:
	if town == null:
		return null
	if _unit_parts.is_empty():
		var units := registry()
		for unit in units:
			_unit_parts[unit] = units[unit].parts
	var parts: Array = _unit_parts.get(key, [])
	if part < 0 or part >= parts.size():
		push_error("modular_town.building: no part %d of unit '%s'" % [part, key])
		return null
	var loaded = town.get_meta("loaded_units", null)
	if loaded != null and not (loaded as Array).has(key):
		return null
	var path: String = parts[part] + ("/" + below if below != "" else "")
	return town.get_node_or_null(NodePath(path)) as Node3D

## Unit keys to load: every unit, or only those named (or aliased) in the dev focus.
static func focused_units() -> Array:
	var units := registry()
	var focus: Array = DevFocus.dev_focus()
	if focus.is_empty():
		return units.keys()
	var result: Array = []
	for key in units:
		var names: Array = [key] + Array(units[key].get("aliases", []))
		if names.any(func(name): return focus.has(name)):
			result.append(key)
	return result

## Transform of `node` relative to `town` (both in the tree or not).
static func town_transform(town: Node, node: Node) -> Transform3D:
	var result := Transform3D.IDENTITY
	while node != null and node != town:
		if node is Node3D:
			result = (node as Node3D).transform * result
		node = node.get_parent()
	return result

## on_step (optional, the app's staged loading through Main._loading_step): awaited after each
## unit, so a loading screen can draw between them. Without it everything loads at once.
## `keys` (optional): load only these units now (the app's home-first start, 13 Nov 2026); the
## others are added later, one at a time, with add_unit(). Empty: every focused unit.
static func load_units(town: Node3D, on_step: Callable = Callable(), keys: Array = []) -> Array:
	var loaded: Array = []
	var parts: Array = []
	var refs: Array = []
	var holders: Array = []
	for key in (keys if not keys.is_empty() else focused_units()):
		var unit := _instance(key)
		if unit == null:
			continue
		holders.append(unit)
		refs.append_array(unit.get_meta("node_refs", []))
		parts.append_array(unit.get_children())
		loaded.append(key)
		if on_step.is_valid():
			await on_step.call()
	parts.sort_custom(func(a, b): return int(a.get_meta("unit_index")) < int(b.get_meta("unit_index")))
	_place_parts(town, parts)
	for unit in holders:
		unit.free()
	refs.append_array(town.get_meta("node_refs", []))
	# Units still to come keep the base's links into them until they arrive (add_unit()).
	_restore_refs_keeping(town, refs, not keys.is_empty())
	town.set_meta("loaded_units", loaded)
	print("modular_town: loaded ", loaded.size(), " of ", registry().size(), " units ", loaded if loaded.size() < registry().size() else "(all)")
	return loaded

## Adds one more unit to a town that is already running (the app's staged loading: the home
## first, the rest while the player plays). Returns the parts it put in the town (their scripts
## have run _ready); Main.add_unit() then hooks them into the town-wide systems.
## `held` (optional): the unit's plush characters are taken out first and listed there as
## [node, parent, index]; the caller puts them back one per frame with put_back() (each plush
## sculpts its meshes in _ready, the bulk of a unit's freeze: 13 Nov 2026), then calls
## finish_refs(town). Without it everything goes in at once.
## `prepared`: the unit's scene already instanced (nearby_units.gd prepare(), 26 Nov 2026), or null.
static func add_unit(town: Node3D, key: String, held = null, prepared: Node = null) -> Array:
	var loaded: Array = town.get_meta("loaded_units", [])
	if loaded.has(key):
		if prepared != null:
			prepared.free()
		return []
	var unit := prepared if prepared != null else _instance(key)
	if unit == null:
		return []
	var refs: Array = unit.get_meta("node_refs", [])
	var parts: Array = unit.get_children()
	parts.sort_custom(func(a, b): return int(a.get_meta("unit_index")) < int(b.get_meta("unit_index")))
	if held is Array:
		for part in parts:
			for node in part.find_children("*", "Node3D", true, false):
				if str(node.scene_file_path).ends_with("_plush.tscn") and node.get_parent() != null \
						and not held.any(func(entry) -> bool: return (entry[0] as Node).is_ancestor_of(node)):
					held.append([node, node.get_parent(), node.get_index()])
			for entry in held:
				if entry[0].get_parent() == entry[1]:
					entry[1].remove_child(entry[0])
	_place_parts(town, parts)
	unit.free()
	loaded.append(key)
	town.set_meta("loaded_units", loaded)
	refs.append_array(town.get_meta("pending_node_refs", []))
	town.set_meta("pending_node_refs", refs)
	if not held is Array:
		finish_refs(town)
	return parts

## The part nodes of loaded unit `key` in `town` (registry order; missing ones skipped).
static func unit_parts(town: Node, key: String) -> Array:
	var parts: Array = []
	if not (town.get_meta("loaded_units", []) as Array).has(key):
		return parts
	for path in registry().get(key, {}).get("parts", []):
		var part := town.get_node_or_null(NodePath(path))
		if part != null:
			parts.append(part)
	return parts

## Takes loaded unit `key` out of `town` (Main.remove_unit(), the far-unit freeing of
## nearby_units.gd, 26 Nov 2026) and frees its parts. Links from the rest of the town into the
## unit (`<meta>` node references made by restore_node_refs()) turn back into `__ref` paths and
## wait in `pending_node_refs`, so add_unit() restores them when the unit returns. The caller
## has already told the town-wide systems.
static func remove_unit(town: Node3D, key: String, parts: Array) -> void:
	var inside := func(node) -> bool:
		return node is Node and is_instance_valid(node) and parts.any(func(part) -> bool: return part == node or (part as Node).is_ancestor_of(node))
	var pending: Array = town.get_meta("pending_node_refs", [])
	# The holders the bake listed (the base's `node_refs`; a unit's own links stay inside it).
	var holders: Array = []
	for holder_path in town.get_meta("node_refs", []):
		var holder := town.get_node_or_null(NodePath(holder_path))
		if holder != null and not holders.has(holder):
			holders.append(holder)
	for holder: Node in holders:
		if inside.call(holder):
			continue
		var changed := false
		for meta in holder.get_meta_list():
			var value: Variant = holder.get_meta(meta)
			if value is Node and inside.call(value):
				holder.set_meta(String(meta) + "__ref", town.get_path_to(value))
				holder.remove_meta(meta)
				changed = true
			elif value is Array and not (value as Array).is_empty() and (value as Array).any(func(item) -> bool: return inside.call(item)):
				var paths: Array = []
				for item in value:
					if item is Node and is_instance_valid(item):
						paths.append(town.get_path_to(item))
				holder.set_meta(String(meta) + "__refs", paths)
				holder.remove_meta(meta)
				changed = true
		if changed:
			var path := str(town.get_path_to(holder))
			if not pending.has(path):
				pending.append(path)
	town.set_meta("pending_node_refs", pending)
	for part: Node in parts:
		part.get_parent().remove_child(part)
		part.free()
	var loaded: Array = town.get_meta("loaded_units", [])
	loaded.erase(key)
	town.set_meta("loaded_units", loaded)

## Puts a plush held by add_unit() back where it was (it builds itself in _ready).
static func put_back(town: Node3D, entry: Array) -> void:
	var node: Node = entry[0]
	var parent: Node = entry[1]
	parent.add_child(node)
	parent.move_child(node, mini(int(entry[2]), parent.get_child_count() - 1))
	node.owner = town

## Resolves the links waiting in the town's `pending_node_refs` (add_unit()).
static func finish_refs(town: Node3D) -> void:
	_restore_refs_keeping(town, town.get_meta("pending_node_refs", []), true)

static func _instance(key: String) -> Node:
	var path: String = FOLDER + key + "." + EXTENSION
	if not ResourceLoader.exists(path):
		push_warning("modular_town: missing unit scene " + path)
		return null
	return (load(path) as PackedScene).instantiate()

## Puts each part back at its original node path (sorted by unit_index).
static func _place_parts(town: Node3D, parts: Array) -> void:
	var saved_nodes: Array = []
	for part in parts:
		var parent: Node = town.get_node_or_null(NodePath(part.get_meta("unit_parent")))
		if parent == null:
			push_warning("modular_town: no parent " + str(part.get_meta("unit_parent")) + " for " + str(part.name))
			continue
		var stored: Transform3D = part.transform
		# Recorded before _ready runs, so nodes that scripts then build are not among them.
		saved_nodes.append(part)
		saved_nodes.append_array(part.find_children("*", "", true, false))
		part.get_parent().remove_child(part)
		part.owner = null
		part.name = part.get_meta("unit_name")
		# An absent unit's site may hold an empty stand-in pivot (reference_world_layout.gd).
		var stand_in: Node = parent.get_node_or_null(NodePath(str(part.name)))
		if stand_in != null and stand_in.has_meta("unit_placeholder"):
			parent.remove_child(stand_in)
			stand_in.free()
		part.transform = town_transform(town, parent).affine_inverse() * stored
		parent.add_child(part)
		parent.move_child(part, mini(int(part.get_meta("unit_index")), parent.get_child_count() - 1))
		for meta in ["unit_parent", "unit_name", "unit_index"]:
			part.remove_meta(meta)
	# Saved nodes belong to the town, as in the old saved town (prefab internals keep their own
	# owner); nodes scripts build at runtime stay ownerless, so tools/bake_unit.gd can tell them
	# apart. (find_child() with its default owned=true also finds them again.) The unit scene's
	# holder still owns the parts' nodes here (it is freed afterwards, which would leave them
	# ownerless: the bake then dropped them as runtime-built, 13 Nov 2026), so any owner that is
	# no longer an ancestor is replaced too.
	for node in saved_nodes:
		if is_instance_valid(node) and node.is_inside_tree() and (node.owner == null or not node.owner.is_ancestor_of(node)):
			node.owner = town

## restore_node_refs(), and with `keep` the holders whose targets are not loaded yet keep those
## links (in the town's `pending_node_refs`) for add_unit().
static func _restore_refs_keeping(town: Node, paths: Array, keep: bool) -> void:
	var pending := restore_node_refs(town, paths, keep)
	if keep:
		town.set_meta("pending_node_refs", pending)

## Returns the holders that still link to absent nodes when `keep_missing` (their `__ref` /
## `__refs` metas then stay, so a later call can finish them); without it those links are dropped.
static func restore_node_refs(town: Node, paths: Array, keep_missing := false) -> Array:
	var pending: Array = []
	for holder_path in paths:
		var holder: Node = town.get_node_or_null(NodePath(holder_path))
		if holder == null:
			continue
		for meta in holder.get_meta_list():
			var title := String(meta)
			if title.ends_with("__ref"):
				var target: Node = town.get_node_or_null(holder.get_meta(meta))
				if target == null and keep_missing:
					if not pending.has(holder_path):
						pending.append(holder_path)
					continue
				holder.remove_meta(meta)
				if target == null:
					continue
				if title == "viewport_texture__ref" and target is Viewport:
					# A sprite showing a SubViewport (e.g. a restaurant poster's icon sheet).
					holder.texture = (target as Viewport).get_texture()
				else:
					holder.set_meta(title.trim_suffix("__ref"), target)
			elif title.ends_with("__refs"):
				var targets: Array = []
				var missing := false
				for target_path in holder.get_meta(meta):
					var target: Node = town.get_node_or_null(target_path)
					if target != null:
						targets.append(target)
					else:
						missing = true
				holder.set_meta(title.trim_suffix("__refs"), targets)
				if missing and keep_missing:
					if not pending.has(holder_path):
						pending.append(holder_path)
				else:
					holder.remove_meta(meta)
	return pending
