extends RefCounted
## The one registry of every NPC (23 Nov 2026, user): data/npcs.json. Guide, coordinate system and
## how to add an NPC: docs/guides/NPCS.md.
##
## - Lookups for everyone else: spec(id), all(), cast() (the profile avatars, in data order;
##   house_characters.gd), of_node(node) (the entry of a placed NPC).
## - place(town, roots): every "scene" NPC under `roots` (the unit parts just loaded) is moved to
##   its registry spot and tagged with meta `npc_id`; Main calls it once the world is built and for
##   every unit added later (staged loading), before word areas, seats and figure blockers. Baking
##   runs it too, so a baked unit saves the registry's spot.
## - spawn(town, roots): makes every "registry" NPC whose unit part is among `roots` (the barn
##   farmer). Never while baking: these never enter a unit scene.
## Load it with preload() (no class_name, like the other helpers headless checks use).

const DATA := "res://data/npcs.json"
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
const DIRECTIONS := {"+x": Vector3.RIGHT, "-x": Vector3.LEFT, "+z": Vector3.BACK, "-z": Vector3.FORWARD}

static var _data: Dictionary = {}

## The whole file (read once).
static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = parsed if parsed is Dictionary else {"npcs": []}
	return _data

## Every NPC entry, in data order.
static func all() -> Array:
	return data().get("npcs", [])

## The entry of `id` ({} when unknown).
static func spec(id: String) -> Dictionary:
	for entry in all():
		if str(entry.get("id", "")) == id:
			return entry
	return {}

## The cast: profile avatars and tutorial stand-ins, in data order (house_characters.gd).
static func cast() -> Array:
	return all().filter(func(entry) -> bool: return bool(entry.get("cast", false)))

## The registry entry of a placed NPC node (meta `npc_id`, else `character_id`), {} when none.
static func of_node(node: Node) -> Dictionary:
	if node == null:
		return {}
	var id := str(node.get_meta("npc_id", node.get_meta("character_id", "")))
	return spec(id) if id != "" else {}

## The brush-off set ("staff" or "friend") of a chatter group.
static func brush_set(group: String) -> String:
	return str(data().get("chatter_groups", {}).get(group, "staff"))

## A registry direction (an axis name or [x, z]) as a town-frame vector.
static func direction(facing: Variant) -> Vector3:
	if facing is Array:
		return Vector3(float(facing[0]), 0, float(facing[1])).normalized()
	return DIRECTIONS.get(str(facing), Vector3.FORWARD)

## [x, y, z] as a Vector3.
static func point(at: Array) -> Vector3:
	return Vector3(float(at[0]), float(at[1]), float(at[2]))

## Moves every "scene" NPC found under `roots` (town parts; empty = the whole town) to its
## registry spot: origin at `at`, turned about the vertical so it looks along `facing` (a seated
## NPC keeps its recline). Its seat_point moves with it. Returns how many were placed.
static func place(town: Node3D, roots: Array = []) -> int:
	var placed := 0
	for entry in all():
		if str(entry.get("placement", "")) != "scene":
			continue
		var npc := town.get_node_or_null(NodePath(str(entry.node))) as Node3D
		if npc == null or (not roots.is_empty() and not roots.any(func(r) -> bool: return r == npc or (r as Node).is_ancestor_of(npc))):
			continue
		_put(town, npc, entry)
		npc.set_meta("npc_id", str(entry.id))
		placed += 1
	return placed

static func _put(town: Node3D, npc: Node3D, entry: Dictionary) -> void:
	var goal := town.to_global(point(entry.at))
	var want := town.global_basis.orthonormalized() * direction(entry.facing)
	want.y = 0.0
	var now := -npc.global_basis.z
	now.y = 0.0
	var turn := 0.0
	if now.length() > 0.01 and want.length() > 0.01:
		turn = now.normalized().signed_angle_to(want.normalized(), Vector3.UP)
	var shift := goal - npc.global_position
	npc.global_transform = Transform3D(Basis(Vector3.UP, turn) * npc.global_basis, goal)
	if npc.has_meta("seat_point"):
		npc.set_meta("seat_point", (npc.get_meta("seat_point") as Vector3) + shift)

## Makes every "registry" NPC whose unit part (the first segment of its `node` path) is in
## `roots` (empty = every loaded one): the plush at `at` (the floor it stands on), looking along
## `facing`, dressed in its costume, with metas npc_id, character_name (when named) and word_key.
## Returns the new nodes.
static func spawn(town: Node3D, roots: Array = []) -> Array:
	var made: Array = []
	for entry in all():
		if str(entry.get("placement", "")) != "registry":
			continue
		var path := NodePath(str(entry.node))
		if town.has_node(path):
			continue
		var parent := town.get_node_or_null(str(entry.node).get_base_dir()) as Node3D
		if parent == null or (not roots.is_empty() and not roots.any(func(r) -> bool: return r == parent or (r as Node).is_ancestor_of(parent))):
			continue
		var npc := make(town, entry, parent, str(entry.node).get_file())
		made.append(npc)
	return made

## A standing registry NPC under `parent` named `title`: its lowest point rests on `at` (town
## frame), it looks along `facing`, wears its costume and carries its metas. Also used by the
## minigames that make their NPC at run time (the bank manager).
static func make(town: Node3D, entry: Dictionary, parent: Node3D, title: String) -> Node3D:
	var npc: Node3D = load(str(entry.scene)).instantiate()
	npc.name = title
	parent.add_child(npc)
	var spot := town.to_global(point(entry.at))
	var look := town.global_basis.orthonormalized() * direction(entry.facing)
	npc.global_transform = Transform3D(Basis.looking_at(Vector3(look.x, 0, look.z).normalized(), Vector3.UP), spot)
	npc.global_position.y += spot.y - _lowest(npc)
	if str(entry.get("costume", "")) != "":
		PlushCostume.dress(npc, str(entry.costume))
	npc.set_meta("npc_id", str(entry.id))
	if str(entry.get("word", "")) != "":
		npc.set_meta("word_key", str(entry.word))
	return npc

# The world height of the body's lowest vertex, tails and costumes excluded (as
# house_characters.gd worker() measures it).
static func _lowest(npc: Node3D) -> float:
	var lowest := INF
	for mesh in npc.find_children("*", "MeshInstance3D", true, false):
		var path := str(npc.get_path_to(mesh))
		if "Tail" in path or "Costume" in path or mesh.mesh == null:
			continue
		for surface in range(mesh.mesh.get_surface_count()):
			for vertex in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				lowest = minf(lowest, (mesh.global_transform * vertex).y)
	return lowest if lowest != INF else npc.global_position.y
