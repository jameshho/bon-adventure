extends RefCounted
## A session-local index of real picking targets, never a second discovery/save store.
const Interaction = preload("res://scripts/player/interaction_controller.gd")
const Interactable = preload("res://scripts/core/interactable.gd")
const OVERRIDES_PATH := "res://data/zone_object_overrides.json"
var groups: Dictionary = {}
var area_names: Dictionary = {}
var assignments: Dictionary = {}
var unknown_keys: Dictionary = {}
var used_overrides: Dictionary = {}
## Word key -> every target carrying it, interactables included (drop_interactables() leaves this
## alone): the sources of the journal's word pictures (word_pictures.gd).
var targets: Dictionary = {}

func build(town: Node3D, zones, vocabulary: Dictionary, aliases: Dictionary) -> void:
	groups.clear()
	area_names.clear()
	assignments.clear()
	unknown_keys.clear()
	used_overrides.clear()
	targets.clear()
	_overrides = JSON.parse_string(FileAccess.get_file_as_string(OVERRIDES_PATH)).overrides
	for zone in zones.zones:
		groups[zone.id] = []
		area_names[zone.id] = zone.name
	add(town, town, zones, vocabulary, aliases)

var _overrides: Dictionary = {}

## Indexes the word targets under `root` (the town in build(); a unit added later by the app's
## staged loading, 13 Nov 2026, followed by drop_interactables()).
func add(root: Node, town: Node3D, zones, vocabulary: Dictionary, aliases: Dictionary) -> void:
	var overrides := _overrides
	var bounds: Dictionary = {}
	for body in root.find_children("*", "CollisionObject3D", true, false):
		if body.collision_layer == 0: continue
		var target := Interaction.vocabulary_target(body,town)
		if target == null: continue
		var raw: String = str(target.get_meta("exterior_word",target.get_meta("word_key","")))
		var key: String = aliases.get(raw,raw)
		if not vocabulary.has(key):
			unknown_keys[key] = true
			continue
		# Shape bounds handle generated meshes whose vertices are offset from root origin.
		for shape in body.get_children():
			if not shape is CollisionShape3D or shape.disabled or shape.shape == null: continue
			var box: AABB = shape.shape.get_debug_mesh().get_aabb()
			for i in range(8):
				var point: Vector3 = town.to_local(shape.to_global(box.get_endpoint(i)))
				if not bounds.has(target): bounds[target] = AABB(point,Vector3.ZERO)
				else: bounds[target] = bounds[target].expand(point)
	for target in bounds:
		var raw: String = str(target.get_meta("exterior_word",target.get_meta("word_key","")))
		var key: String = aliases.get(raw,raw)
		var point: Vector3 = bounds[target].get_center()
		var area: String = zones.resolve_local(point)
		# Closest ancestor wins: explicit node metadata, then path-based data overrides.
		var ancestor: Node = target
		while ancestor != town and ancestor != null:
			var path := str(town.get_path_to(ancestor))
			var override: String = str(ancestor.get_meta("zone_override",overrides.get(path,{}).get("zone","")))
			if override != "":
				if zones.by_id.has(override):
					area = override
					if overrides.has(path): used_overrides[path] = true
				else: push_error("Unknown zone override: "+path+" -> "+override)
				break
			ancestor = ancestor.get_parent()
		assignments[target] = {"key":key,"zone":area,"point":point}
		if not targets.has(key): targets[key] = []
		targets[key].append(target)
		# Freeze placement once after world construction. Vehicles retain their home zone.
		target.set_meta("assigned_zone",area)
		if not groups[area].has(key): groups[area].append(key)

## Interactables are not words (user, 12 Nov 2026): clicking one uses it. Called once every
## Interactable exists (Main, after seating): their words leave the area lists, so an area's
## count only holds words a click can study. A key stays while another target in that area
## still carries it.
func drop_interactables(town: Node3D) -> void:
	_drop_interactables(town)
	# Words of building units freed while far (remove(), 26 Nov 2026) keep counting in their area.
	for area in _kept:
		for key in _kept[area]:
			if groups.has(area) and not groups[area].has(key): groups[area].append(key)

## Area -> word keys of targets in building units freed while far (remove()).
var _kept: Dictionary = {}

## The targets under `parts` (a building unit about to be freed, Main.remove_unit(), 26 Nov 2026)
## leave the index, but their words stay in their areas (an area's count must not drop while the
## building is away); add() indexes them again when the unit returns.
func remove(parts: Array) -> void:
	for target in assignments.keys():
		if is_instance_valid(target) and not parts.any(func(part) -> bool: return part == target or (part as Node).is_ancestor_of(target)):
			continue
		var entry: Dictionary = assignments[target]
		if not _kept.has(entry.zone): _kept[entry.zone] = []
		if not _kept[entry.zone].has(entry.key): _kept[entry.zone].append(entry.key)
		assignments.erase(target)
	for key in targets.keys():
		targets[key] = (targets[key] as Array).filter(func(target) -> bool:
			return is_instance_valid(target) and not parts.any(func(part) -> bool: return part == target or (part as Node).is_ancestor_of(target)))
		if (targets[key] as Array).is_empty(): targets.erase(key)

func _drop_interactables(town: Node3D) -> void:
	for target in assignments.keys():
		# An NPC that only chats keeps its role word (npc_chatter.gd, 23 Nov 2026).
		if Interactable.find_for(target, town) != null and not target.get_meta("talk_keeps_word", false):
			assignments.erase(target)
	for area in groups:
		groups[area] = []
	for target in assignments:
		var entry: Dictionary = assignments[target]
		if not groups[entry.zone].has(entry.key): groups[entry.zone].append(entry.key)

func zone_for(target: Node) -> String:
	return assignments.get(target,{}).get("zone","")

func discovered_count(area: String, studied: Dictionary) -> int:
	var count := 0
	for key in groups.get(area,[]):
		if studied.has(key): count += 1
	return count
