extends SceneTree
## Writes data/nearby_units.json for nearby loading on phones (scripts/world/nearby_units.gd,
## 17 Nov 2026): each building unit's part boxes (town XZ: Main's Apartment frame, +X west /
## +Z north) and the unit each minigame's session lives in. Run again after a unit's footprint
## changes, a unit is added, or a minigame moves to another building.
## Loads the town in stages (playground first, then each unit with Main.add_unit()) and notes
## which activity sessions (activity_board.gd) each unit's jobs register. Writes no saves when
## run with an isolated HOME (README "Checks"):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0 godot --headless --path . --script res://tools/nearby_units_data.gd
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const OUT := "res://data/nearby_units.json"
const FIRST := "playground"

var main: Node

func _initialize() -> void:
	run.call_deferred()

func registered() -> Array:
	var ids: Array = []
	for id in Board.shared()._running:
		if Board.shared().session(id) != null:
			ids.append(id)
	return ids

static func part_boxes(town: Node3D, part: Node) -> Array:
	var box := AABB()
	var first := true
	var to_town := town.global_transform.affine_inverse()
	for node: Node in [part] + part.find_children("*", "VisualInstance3D", true, false):
		if not node is VisualInstance3D or node is Light3D:
			continue
		var vi := node as VisualInstance3D
		var local: AABB = vi.get_aabb()
		if local.size == Vector3.ZERO:
			continue
		var b: AABB = to_town * vi.global_transform * local
		if b.size.length() > 500.0:
			continue
		box = b if first else box.merge(b)
		first = false
	if first:
		return []
	return [[snappedf(box.position.x, 0.1), snappedf(box.position.z, 0.1), snappedf(box.end.x, 0.1), snappedf(box.end.z, 0.1)]]

func run() -> void:
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.staged_loading = true
	main.initial_units = [FIRST]
	get_root().add_child(main)
	await main.town_ready
	var activities := {}
	var before := registered()
	for id in before:
		activities[id] = ""
	var order: Array = [FIRST] + main.pending_units.duplicate()
	for key in main.pending_units.duplicate():
		await main.add_unit(key)
		for id in registered():
			if not before.has(id):
				activities[id] = key
				before.append(id)
	var boxes := {}
	var units := ModularTown.registry()
	for key in order:
		var list: Array = []
		for path in units[key].parts:
			var part: Node = main.apartment.get_node_or_null(NodePath(path))
			if part != null:
				list.append_array(part_boxes(main.apartment, part))
		boxes[key] = list
	var keep := {}
	for id in activities:
		if activities[id] != "":
			keep[id] = activities[id]
	var result := {
		"_comment": "Written by tools/nearby_units_data.gd (do not edit by hand). boxes: each building unit's part boxes [x0, z0, x1, z1] in town coordinates (Main's Apartment frame); activities: the unit each minigame session lives in. Used by scripts/world/nearby_units.gd.",
		"boxes": boxes,
		"activities": keep,
	}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "\t", false))
	f.close()
	print("nearby_units_data: ", boxes.size(), " units, ", keep.size(), " activities -> ", OUT, " (in the base or ", FIRST, ": ", activities.keys().filter(func(id) -> bool: return activities[id] == ""), ")")
	quit()
