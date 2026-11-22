extends RefCounted
## Puts the town stamp coins (stamp_coin.gd) in their buildings (user's list, 21 Nov 2026;
## guide: docs/guides/ACHIEVEMENTS.md#town-stamps). The spots are data, not baked:
## data/achievements.json "stamps", one entry per coin:
##   "unit"    the building unit (data/buildings.json) the coin belongs to; it is added when that
##             unit is loaded (main.when_unit_loaded) and never when the unit is not in the town
##             (dev_focus.txt);
##   "at"      [x, y, z] the coin's centre in TOWN coordinates (Apartment space: units of 1.3 m,
##             +X west, +Z north); null = not placed, the stamp does not exist yet;
##   "parent"  optional: a node path below the Apartment to carry the coin (a lift car); default
##             the Apartment's "StampCoins" holder;
##   "face"    optional: a town point the coin faces; it then stands still (no room to spin);
##   "reach"   optional: pickup radius in metres (default stamp_coin.gd pickup_radius);
##   "gate"    optional: node path below the Apartment of a hinged door the coin sits behind;
##             the coin is collected only while that door is open (the Bank's safe).
## The coin keeps unit scale (its size is in metres) whatever its parent's scale.
const StampCoin := preload("res://scripts/world/stamp_coin.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const FILE := "res://data/achievements.json"
## The coins' own holder under the Apartment: outside the building parts, so they never count in
## a unit's bounds (nearby loading, render cells, the map bake). Units are never unloaded.
const HOLDER := "StampCoins"

## The placed stamps: id -> its entry (only those with "unit" and "at").
static func spots() -> Dictionary:
	var out := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if not parsed is Dictionary:
		return out
	var stamps: Dictionary = parsed.get("stamps", {})
	for id in stamps:
		var entry = stamps[id]
		if str(id).begins_with("_") or not entry is Dictionary:
			continue
		if entry.get("at") is Array and entry.at.size() == 3 and str(entry.get("unit", "")) != "":
			out[str(id)] = entry
	return out

## Called once from main.gd: each coin waits for its building.
static func install(main) -> void:
	# Never in a bake (tools/bake_unit.gd): coins are not part of the building scenes.
	if main.has_meta("bake_world_only"):
		return
	var all := spots()
	for id in all:
		main.when_unit_loaded(str(all[id].unit), place.bind(main, str(id), all[id]))

## Adds stamp `id`'s coin to the running town; the coin or null (unit absent, already there).
static func place(main, id: String, entry: Dictionary) -> Node3D:
	var town: Node3D = main.apartment
	if town == null:
		return null
	if ModularTown.building(town, str(entry.unit)) == null:
		return null
	var holder: Node3D = null
	if str(entry.get("parent", "")) != "":
		holder = town.get_node_or_null(NodePath(str(entry.parent))) as Node3D
	else:
		holder = town.get_node_or_null(HOLDER) as Node3D
		if holder == null:
			holder = Node3D.new()
			holder.name = HOLDER
			town.add_child(holder)
	if holder == null or holder.has_node("StampCoin_" + id):
		return null
	var coin: Node3D = StampCoin.make(id)
	if entry.has("reach"):
		coin.pickup_radius = float(entry.reach)
	if str(entry.get("gate", "")) != "":
		coin.gate = town.get_node_or_null(NodePath(str(entry.gate))) as Node3D
	var at: Vector3 = town.global_transform * Vector3(float(entry.at[0]), float(entry.at[1]), float(entry.at[2]))
	# Local transform set before it enters the tree, so its pickup never starts elsewhere.
	coin.transform = holder.global_transform.affine_inverse() * Transform3D(Basis.IDENTITY, at)
	holder.add_child(coin)
	if entry.get("face") is Array and (entry.face as Array).size() == 3:
		# Faces that point and stands still: the spin needs a coin's width of depth (22 Nov 2026).
		coin.spin_speed = 0.0
		coin.look_at(town.global_transform * Vector3(float(entry.face[0]), float(entry.face[1]), float(entry.face[2])), Vector3.UP)
	return coin
