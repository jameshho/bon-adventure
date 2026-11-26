extends RefCounted
## Where the player was, and where they come back (save and respawn, 14 Nov 2026, user).
##
## Each profile keeps its last place in FILE (save_store.gd PROFILE_FILES; atomic writes):
##   {"version": 1, "x": .., "y": .., "z": .., "yaw": .., "entrance": "bank", "vehicle": false,
##    "time": <unix seconds>}
## x, y, z are the player's feet in TOWN coordinates (Main.apartment's local frame, +X west /
## +Z north; while driving: the vehicle's position; in the warehouse minigame copy: the real
## warehouse spot, the player's "map_position"). `entrance` is the Main.ENTRANCES key of the
## building the player was inside ("" outdoors); `vehicle` is true when they were driving
## (vehicles themselves are not saved).
##
## Saving (player_place_keeper.gd, made by Main once the town is ready): every SAVE_SECONDS when the player moved
## at least MOVE_METRES, and at once on a close request, when the app is paused or loses focus
## (a phone app switch), when the town leaves the tree (quit, "Switch profile" back to the title)
## and when the web page is hidden (web_resume.gd). Only with a profile selected (checks and tools
## run without one, so they never save or restore a place) and never while baking (read_only).
##
## Reopening (Main._restore_place(), before town_ready, profiles that finished the tutorial, no
## dev `spawn=`): inside a building -> just outside its entrance (the ENTRANCES standing point,
## facing the door, as the dev spawn); outdoors -> the nearest safe spot within SEARCH_RADIUS
## (safe_spot()); otherwise, or when that building's unit is not loaded, the usual supermarket
## spawn. Indoors means a static roof overhead and static walls on 3 of 4 sides (as
## indoor_visibility.gd); the building is the unit (data/buildings.json) owning the roof's
## collider, else the town zone (data/zones.json) there.
##
## The last-resort unstuck (GAME-05, 25 Nov 2026) reuses this: rescue_spot() for a seat or vehicle
## with no clear exit (seating_controller.gd, vehicle_controls.gd), then Main.respawn().
const SaveStore := preload("res://scripts/core/save_store.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")

const FILE := "player_place.json"
const VERSION := 1
const SAVE_SECONDS := 10.0
const MOVE_METRES := 1.5
## Outdoor search: rings RING_STEP apart out to SEARCH_RADIUS around the saved spot.
const SEARCH_RADIUS := 15.0
const RING_STEP := 1.5
## Around an entrance's standing point (it should be clear already; a parked car may not be).
const ENTRANCE_RADIUS := 6.0
const ROOF_RAY := 30.0
const WALL_REACH := 40.0
## Ground steeper than this (normal.y) is not walkable.
const MIN_NORMAL_Y := 0.85
## A surface with solid ground more than this below it is a roof, a deck or a vehicle's top.
const MAX_DROP := 2.5
## At most this many bodies are passed through looking for the ground below a surface.
const UNDER_LAYERS := 8
## Feet are placed this far above the ground (the capsule then touches nothing on a slope).
const LIFT := 0.15
## The player's collision mask on foot (player_controller.gd: world 1 + figures).
const PLAYER_MASK := 1 | 256
## Last-resort unstuck (GAME-05, rescue_spot()): the search radius around a blocked seat or
## vehicle, the floor step a spot may differ by, and the waist height of the sight line.
const RESCUE_RADIUS := 6.0
const LEVEL_STEP := 0.6
const LEVEL_SIGHT := 1.2
## Town zones whose id is not the unit key (scripts/world/town_zones.gd, data/zones.json).
const ZONE_UNITS := {
	"farm": "barn", "church": "chapel", "mystery_house": "mystery", "fine_dining": "restaurants",
	"burger": "restaurants", "taqueria": "restaurants", "control_tower": "airport",
}

static var _part_units := {}


## Saving and restoring are on: a profile is selected and saves are writable.
static func enabled() -> bool:
	return ProfileManager.shared().active_id != "" and not SaveStore.read_only


static func read(path: String = "") -> Dictionary:
	var parsed: Variant = SaveStore.read_json(path if path != "" else SaveStore.path(FILE))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != VERSION:
		return {}
	for key in ["x", "y", "z", "yaw"]:
		if not (parsed.get(key) is float or parsed.get(key) is int):
			return {}
	return parsed


static func write(place: Dictionary, path: String = "") -> bool:
	if place.is_empty():
		return false
	var data := place.duplicate()
	data["version"] = VERSION
	return SaveStore.write_json(path if path != "" else SaveStore.path(FILE), data)


## The player's place now, or {} when there is no player in the town.
static func capture(main) -> Dictionary:
	var player: Node3D = main.get("player")
	var town: Node3D = main.get("apartment")
	if not is_instance_valid(player) or not is_instance_valid(town) or not player.is_inside_tree():
		return {}
	var vehicle: Node3D = main.get("active_vehicle")
	var driving := is_instance_valid(vehicle)
	var point: Vector3 = vehicle.global_position if driving else player.get_meta("map_position", player.global_position)
	var local := town.to_local(point)
	return {
		"x": local.x, "y": local.y, "z": local.z,
		"yaw": float(player.get("camera_yaw")),
		"entrance": "" if driving else entrance_at(main, point),
		"vehicle": driving,
		"time": Time.get_unix_time_from_system(),
	}


## The ENTRANCES key of the building around world point `point`, or "" outdoors.
static func entrance_at(main, point: Vector3) -> String:
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var exclude := _exclusions(main)
	var from := point + Vector3.UP * 1.6
	var roof := _ray(space, from, from + Vector3.UP * ROOF_RAY, exclude)
	if roof.is_empty() or not roof.collider is StaticBody3D:
		return ""
	var walls := 0
	for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var hit := _ray(space, from, from + side * WALL_REACH, exclude)
		if not hit.is_empty() and hit.collider is StaticBody3D:
			walls += 1
	if walls < 3:
		return ""
	var unit := unit_of(main.apartment, roof.collider)
	if unit == "" and main.get("zones") != null:
		var zone: String = main.zones.resolve_global(point)
		unit = ZONE_UNITS.get(zone, zone)
	return nearest_entrance(main, unit, point)


## The ENTRANCES key of unit `unit` whose door is nearest `point` (XZ), or "".
static func nearest_entrance(main, unit: String, point: Vector3) -> String:
	var best := ""
	var best_distance := INF
	for key in main.ENTRANCES:
		var entry: Array = main.ENTRANCES[key]
		if entry[0] != unit:
			continue
		var site := ModularTown.building(main.apartment, entry[0], entry[1], entry[2])
		if site == null:
			continue
		var door := site.to_global(entry[4])
		var distance := Vector2(door.x - point.x, door.z - point.z).length()
		if distance < best_distance:
			best_distance = distance
			best = key
	return best


## The building unit (data/buildings.json) one of whose parts holds `node`, or "".
static func unit_of(town: Node, node: Node) -> String:
	if _part_units.is_empty():
		var units := ModularTown.registry()
		for key in units:
			for part in units[key].parts:
				_part_units[str(part)] = key
	while node != null and node != town:
		var key: String = _part_units.get(str(town.get_path_to(node)), "")
		if key != "":
			return key
		node = node.get_parent()
	return ""


## Where to put the player for a saved `place`: {"position", "yaw", "how"} ("entrance" or
## "nearby"), or {} for the usual spawn (nothing usable, a building that is not loaded, no
## safe spot).
static func spawn_for(main, place: Dictionary) -> Dictionary:
	if place.is_empty():
		return {}
	var town: Node3D = main.apartment
	var entrance := str(place.get("entrance", ""))
	if entrance != "":
		var entry: Array = main.ENTRANCES.get(entrance, [])
		if entry.is_empty():
			return {}
		var site := ModularTown.building(town, entry[0], entry[1], entry[2])
		if site == null:
			return {}
		var stand := site.to_global(entry[3])
		var spot: Variant = safe_spot(main, stand, ENTRANCE_RADIUS)
		if spot == null:
			return {}
		var facing: Vector3 = site.to_global(entry[4]) - spot
		return {"position": spot, "yaw": atan2(-facing.x, -facing.z), "how": "entrance"}
	var point := town.to_global(Vector3(float(place.x), float(place.y), float(place.z)))
	var found: Variant = safe_spot(main, point, SEARCH_RADIUS)
	if found == null:
		return {}
	return {"position": found, "yaw": float(place.yaw), "how": "nearby"}


## Last-resort unstuck (GAME-05, 25 Nov 2026): where to put a player whose seat or vehicle has no
## clear exit (seating_controller.gd stand(), vehicle_controls.gd toggle_vehicle()). `origin` is
## the seat or vehicle (world), `floor_y` the floor height there, `sight_ignore` the bodies of the
## seat or vehicle itself (the sight line starts inside them). First a clear spot on the same
## floor within RESCUE_RADIUS and in sight of `origin` (indoors too): {"position", "how": "nearby"}.
## Else the respawn as on reopening a save (spawn_for(): outside the building's entrance, or the
## nearest safe spot outdoors), else the usual spawn: "how" is then "entrance", "nearby_far" or
## "spawn", and the caller respawns there through Main.respawn() (which ends a running game).
static func rescue_spot(main, origin: Vector3, floor_y: float, sight_ignore: Array[RID] = []) -> Dictionary:
	var near: Variant = safe_spot(main, origin, RESCUE_RADIUS, floor_y, sight_ignore)
	if near != null:
		var away: Vector3 = near - origin
		var yaw: float = atan2(-away.x, -away.z) if Vector2(away.x, away.z).length() > 0.1 else float(main.player.get("camera_yaw"))
		return {"position": near, "yaw": yaw, "how": "nearby"}
	var local: Vector3 = main.apartment.to_local(Vector3(origin.x, floor_y, origin.z))
	var place := {"x": local.x, "y": local.y, "z": local.z, "yaw": float(main.player.get("camera_yaw")),
		"entrance": entrance_at(main, Vector3(origin.x, floor_y, origin.z))}
	var spot := spawn_for(main, place)
	if not spot.is_empty():
		if spot.how == "nearby":
			spot.how = "nearby_far"
		return spot
	return {"position": main.spawn_position(), "yaw": main.spawn_yaw(), "how": "spawn"}


## The nearest spot to `origin` (world) within `radius` where the player can stand: walkable
## ground below (not a roof or deck, not the sea), no roof overhead, the capsule clear of walls,
## vehicles and props, and (when the player could stand at `origin`) in sight of it at waist
## height, so the search never passes through a wall. null when there is none.
## With `floor_y` (GAME-05 level mode, for a seat or vehicle indoors): the ground must be within
## LEVEL_STEP of that floor, a roof overhead is fine, and the sight line starts at `origin`'s
## waist height on that floor, through `sight_ignore`.
static func safe_spot(main, origin: Vector3, radius: float, floor_y: float = NAN, sight_ignore: Array[RID] = []) -> Variant:
	var level := not is_nan(floor_y)
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var exclude := _exclusions(main)
	var capsule: CollisionShape3D = main.player.get_node("PlayerCollision")
	var sight: Variant = null
	if level:
		sight = Vector3(origin.x, floor_y + LEVEL_SIGHT, origin.z)
	else:
		var start := _ground(main, space, origin, origin.y, exclude)
		if not start.is_empty() and start.safe and origin.y - start.point.y < 3.0:
			sight = start.point + Vector3.UP
	var through: Array[RID] = exclude.duplicate()
	through.append_array(sight_ignore)
	var candidates: Array[Vector3] = [origin]
	var ring := RING_STEP
	while ring <= radius + 0.01:
		var count := maxi(8, ceili(TAU * ring / RING_STEP))
		for i in count:
			candidates.append(origin + Vector3.FORWARD.rotated(Vector3.UP, TAU * i / count) * ring)
		ring += RING_STEP
	for candidate in candidates:
		var ground := _level_ground(main, space, candidate, floor_y, exclude) if level \
				else _ground(main, space, candidate, origin.y, exclude)
		if ground.is_empty() or not ground.safe:
			continue
		var spot: Vector3 = ground.point + Vector3.UP * LIFT
		if not level and not _ray(space, spot + Vector3.UP, spot + Vector3.UP * ROOF_RAY, exclude).is_empty():
			continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule.shape
		query.transform = Transform3D(Basis.IDENTITY, spot) * capsule.transform
		query.collision_mask = PLAYER_MASK
		# The vehicle being left still stands there: only the player passes through.
		query.exclude = [main.player.get_rid()]
		if not space.intersect_shape(query, 1).is_empty():
			continue
		if sight != null and candidate != origin \
				and not _ray(space, sight, spot + Vector3.UP, through).is_empty():
			continue
		return spot
	return null


## The first surface below `at` (from 4 m above `top`): {"point", "safe"}, or {} when nothing.
## Unsafe: too steep, the sea (no town zone there), or more than MAX_DROP above the lowest solid
## below it (a roof, a deck or bridge, the top of a vehicle or a tall prop).
static func _ground(main, space: PhysicsDirectSpaceState3D, at: Vector3, top: float, exclude: Array[RID]) -> Dictionary:
	var from := Vector3(at.x, top + 4.0, at.z)
	var hit := _ray(space, from, Vector3(at.x, minf(top - 60.0, -60.0), at.z), exclude)
	if hit.is_empty():
		return {}
	var point: Vector3 = hit.position
	var safe: bool = hit.normal.y > MIN_NORMAL_Y
	if safe and main.get("zones") != null and main.zones.resolve_global(point) == "coast":
		safe = false
	if safe:
		# The lowest solid below, through every body in between (a roof is often several layered
		# bodies: slab, ceiling, upper floor; one ray would stop at the next layer).
		var below: Array[RID] = exclude.duplicate()
		below.append(hit.rid)
		var lowest := point
		for i in UNDER_LAYERS:
			var under := _ray(space, lowest - Vector3.UP * 0.05, Vector3(at.x, point.y - 60.0, at.z), below)
			if under.is_empty():
				break
			lowest = under.position
			below.append(under.rid)
		safe = point.y - lowest.y <= MAX_DROP
	return {"point": point, "safe": safe}


## Level mode (GAME-05): the floor below `at` within LEVEL_STEP of `floor_y`, walkable and not the
## sea; looked for from just under a ceiling (LEVEL_SIGHT + LEVEL_STEP above the floor).
static func _level_ground(main, space: PhysicsDirectSpaceState3D, at: Vector3, floor_y: float, exclude: Array[RID]) -> Dictionary:
	var hit := _ray(space, Vector3(at.x, floor_y + LEVEL_SIGHT + LEVEL_STEP, at.z), Vector3(at.x, floor_y - LEVEL_STEP, at.z), exclude)
	if hit.is_empty():
		return {}
	var point: Vector3 = hit.position
	var safe: bool = hit.normal.y > MIN_NORMAL_Y and absf(point.y - floor_y) <= LEVEL_STEP
	if safe and main.get("zones") != null and main.zones.resolve_global(point) == "coast":
		safe = false
	return {"point": point, "safe": safe}


static func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, PLAYER_MASK, exclude)
	return space.intersect_ray(query)


static func _exclusions(main) -> Array[RID]:
	var result: Array[RID] = []
	var player = main.get("player")
	if is_instance_valid(player):
		result.append(player.get_rid())
	var vehicle = main.get("active_vehicle")
	if is_instance_valid(vehicle) and vehicle is CollisionObject3D:
		result.append(vehicle.get_rid())
	return result

