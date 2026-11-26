extends SceneTree
## Save and respawn (scripts/core/player_place.gd, player_place_keeper.gd, Main._restore_place();
## 14 Nov 2026). Run with VT_FOCUS=all, VT_SPAWN=none and an isolated HOME (README Verification).
## Checks: the place file round trip; for every building unit, every entrance in Main.ENTRANCES:
## a point just inside its door is recognised as that building and respawns outside the entrance
## with a clear capsule and ground below (plus the upper hospital floors, the control tower and
## the warehouse minigame copy); outdoor points inside a wall, a vehicle, on a roof, at sea and
## from a flying vehicle; an unloaded unit and no save fall back to the usual spawn; a
## profile's saved place is restored by Main and saved again by the keeper.
## Since 25 Nov 2026 (user): the usual spawn is outside the home (was the supermarket); a place
## inside a building comes back at the same spot when it is clear (else the entrance; a place
## saved in a minigame always the entrance); an unusable saved place restores outside the home;
## Settings' Save (Main.save_game()) writes the place at once.
## Writes only in user:// (the isolated HOME): user://player-place-check/ and one test profile
## under user://profiles/, both removed at the end. Refuses to run when saves already exist.
const PlayerPlace := preload("res://scripts/core/player_place.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const TEST_DIR := "user://player-place-check"

var failures := 0
var checks := 0
var game
var town: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	for file in ["user://" + PlayerPlace.FILE, ProfileManager.INDEX_PATH]:
		if FileAccess.file_exists(file):
			print("PLAYER PLACE: refusing to run, %s exists (use an isolated HOME)" % file)
			quit(1)
			return
	_file_round_trip()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	town = game.apartment
	var start: Vector3 = game.player.global_position
	check(not PlayerPlace.enabled(), "no profile: saving and restoring are off")
	check(game.place_keeper == null, "no profile: no keeper")
	check(PlayerPlace.read().is_empty() and PlayerPlace.spawn_for(game, {}).is_empty(), "no save: no place")
	var home: Array = game.ENTRANCES.home
	var home_site := ModularTown.building(town, home[0])
	check(start.distance_to(home_site.to_global(home[3])) < 0.5, "no save: the home spawn")
	await physics_frame
	await physics_frame
	_entrances()
	_upper_floors()
	_warehouse_copy()
	await _outdoors()
	_unloaded_unit()
	await _profile_restore()
	print("PLAYER PLACE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _file_round_trip() -> void:
	var path := TEST_DIR.path_join(PlayerPlace.FILE)
	var place := {"x": 1.5, "y": 0.25, "z": -40.0, "yaw": 0.75, "entrance": "bank", "vehicle": false, "time": 5.0}
	check(PlayerPlace.write(place, path), "place written")
	var back := PlayerPlace.read(path)
	check(back.get("entrance") == "bank" and is_equal_approx(float(back.x), 1.5) and is_equal_approx(float(back.z), -40.0) \
		and is_equal_approx(float(back.yaw), 0.75) and back.get("vehicle") == false and int(back.version) == PlayerPlace.VERSION, "place read back")
	check(not FileAccess.file_exists(path + ".tmp"), "no temporary file left")
	SaveStore.write_text(path, "{not json")
	check(PlayerPlace.read(path).is_empty(), "a broken file reads as no place")
	SaveStore.write_json(path, {"version": 99, "x": 0, "y": 0, "z": 0, "yaw": 0})
	check(PlayerPlace.read(path).is_empty(), "another version reads as no place")
	SaveStore.read_only = true
	check(not PlayerPlace.write(place, path), "read_only (baking) writes nothing")
	SaveStore.read_only = false
	check(SaveStore.PROFILE_FILES.has(PlayerPlace.FILE), "the place file is a per-profile save")
	SaveStore.remove_tree(TEST_DIR)


## A spawn result is outside, standing: capsule clear, walkable ground just below, open sky.
func _good_spot(spot: Variant, label: String) -> void:
	if not spot is Vector3:
		check(false, label + ": a spot")
		return
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var capsule: CollisionShape3D = game.player.get_node("PlayerCollision")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule.shape
	query.transform = Transform3D(Basis.IDENTITY, spot) * capsule.transform
	query.collision_mask = PlayerPlace.PLAYER_MASK
	query.exclude = [game.player.get_rid()]
	check(space.intersect_shape(query, 1).is_empty(), label + ": capsule clear")
	var ray := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 0.5, spot - Vector3.UP * 1.0, PlayerPlace.PLAYER_MASK, [game.player.get_rid()])
	var hit := space.intersect_ray(ray)
	check(not hit.is_empty() and hit.normal.y > PlayerPlace.MIN_NORMAL_Y and spot.y - hit.position.y < 0.5, label + ": ground below")
	ray = PhysicsRayQueryParameters3D.create(spot + Vector3.UP, spot + Vector3.UP * 30.0, PlayerPlace.PLAYER_MASK, [game.player.get_rid()])
	check(space.intersect_ray(ray).is_empty(), label + ": open sky")


## Every unit has an entrance; a point 3 m inside each door is that building and respawns outside.
func _entrances() -> void:
	var units: Dictionary = ModularTown.registry()
	for unit in units:
		check(game.ENTRANCES.values().any(func(entry) -> bool: return entry[0] == unit), "entrance listed for unit " + unit)
	for key in game.ENTRANCES:
		var entry: Array = game.ENTRANCES[key]
		var site := ModularTown.building(town, entry[0], entry[1], entry[2])
		if site == null:
			check(false, "entrance site " + key)
			continue
		var stand := site.to_global(entry[3])
		var door := site.to_global(entry[4])
		var inward := door - stand
		inward.y = 0.0
		var inside := door + inward.normalized() * 3.0
		var found := PlayerPlace.entrance_at(game, inside)
		if entry[0] == "playground":
			# Open air: no roof, so it is outdoors (the nearby search then applies).
			check(found == "", "playground counts as outdoors")
			var near := PlayerPlace.spawn_for(game, _place(inside, ""))
			_good_spot(near.get("position"), "playground nearby")
			continue
		check(found != "" and game.ENTRANCES[found][0] == entry[0], "inside %s is unit %s (got '%s')" % [key, entry[0], found])
		# The same spot inside (25 Nov 2026), unless something stands there (then the entrance).
		var same := PlayerPlace.spawn_for(game, _place(inside, found))
		check(same.get("how") in ["inside", "entrance"], "inside %s: same spot or entrance (got %s)" % [key, same.get("how")])
		if same.get("how") == "inside":
			check((same.position as Vector3).distance_to(inside) <= PlayerPlace.INDOOR_RADIUS + 0.3 \
					and absf((same.position as Vector3).y - inside.y) <= PlayerPlace.LEVEL_STEP + PlayerPlace.LIFT, key + ": back at the same spot inside")
		print("inside ", key, " -> ", same.get("how"))
		# Saved in a minigame: always the entrance.
		var spawn := PlayerPlace.spawn_for(game, _place(inside, found, false, true))
		check(spawn.get("how") == "entrance", "respawn outside " + key)
		if spawn.get("how") != "entrance":
			continue
		var found_entry: Array = game.ENTRANCES[found]
		var found_site := ModularTown.building(town, found_entry[0], found_entry[1], found_entry[2])
		check((spawn.position as Vector3).distance_to(found_site.to_global(found_entry[3])) <= PlayerPlace.ENTRANCE_RADIUS, key + ": at the entrance")
		var facing := found_site.to_global(found_entry[4]) - (spawn.position as Vector3)
		check(absf(angle_difference(float(spawn.yaw), atan2(-facing.x, -facing.z))) < 0.05, key + ": facing the door")
		_good_spot(spawn.position, key + " entrance")
		print("entrance ", key, " -> ", found, " at ", spawn.position)


func _place(point: Vector3, entrance: String, vehicle := false, minigame := false) -> Dictionary:
	var local := town.to_local(point)
	return {"x": local.x, "y": local.y, "z": local.z, "yaw": 0.4, "entrance": entrance, "vehicle": vehicle, "minigame": minigame}


func _inside(key: String, depth: float) -> Vector3:
	var entry: Array = game.ENTRANCES[key]
	var site := ModularTown.building(town, entry[0], entry[1], entry[2])
	var stand := site.to_global(entry[3])
	var door := site.to_global(entry[4])
	var inward := door - stand
	inward.y = 0.0
	return door + inward.normalized() * depth


func _upper_floors() -> void:
	# The hospital's upper floors above its entrance hall (the school is one storey there).
	for key in ["hospital"]:
		for floor_y in [6.0, 11.5]:
			var point := town.to_global(town.to_local(_inside(key, 8.0)) + Vector3(0, floor_y, 0))
			var found := PlayerPlace.entrance_at(game, point)
			check(found == key, "%s floor at town y %.1f is %s (got '%s')" % [key, floor_y, key, found])
	var tower := PlayerPlace.entrance_at(game, _inside("tower", 3.0))
	check(tower == "tower", "inside the control tower -> its own door (got '%s')" % tower)


## The warehouse minigame copy is 300 m up; the place is the real warehouse ("map_position").
func _warehouse_copy() -> void:
	var player: Node3D = game.player
	var before := player.global_position
	var real := _inside("warehouse", 4.0)
	player.global_position = real + Vector3.UP * 300.0
	player.set_meta("map_position", real)
	var place := PlayerPlace.capture(game)
	check(place.get("entrance") == "warehouse", "in the warehouse copy: saved as the warehouse (got '%s')" % place.get("entrance"))
	check(town.to_global(Vector3(place.x, place.y, place.z)).distance_to(real) < 0.01, "in the warehouse copy: the real spot is saved")
	player.remove_meta("map_position")
	player.global_position = before


func _outdoors() -> void:
	var market: Array = game.ENTRANCES.supermarket
	var site := ModularTown.building(town, market[0])
	var stand := site.to_global(market[3])
	var away := site.to_global(market[3]) - site.to_global(market[4])
	away.y = 0.0
	away = away.normalized()
	# An open spot stays where it is.
	var open := PlayerPlace.spawn_for(game, _place(stand, ""))
	check(open.get("how") == "nearby" and (open.position as Vector3).distance_to(stand) < 0.5, "an open spot is kept")
	check(PlayerPlace.capture(game).get("entrance", "?") == "", "the spawn outside the supermarket is outdoors")
	# Inside a wall (a test wall 8 m long across the walk).
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 4.0, 0.8)
	shape.shape = box
	wall.add_child(shape)
	root.add_child(wall)
	var wall_at := stand + away * 6.0
	wall.global_transform = Transform3D(Basis.looking_at(away), wall_at + Vector3.UP * 2.0)
	await physics_frame
	await physics_frame
	var moved := PlayerPlace.spawn_for(game, _place(wall_at, ""))
	check(moved.get("how") == "nearby", "inside a wall: a nearby spot")
	if moved.get("how") == "nearby":
		var distance := Vector2(moved.position.x - wall_at.x, moved.position.z - wall_at.z).length()
		check(distance > 0.5 and distance <= PlayerPlace.SEARCH_RADIUS, "inside a wall: moved %.1f m" % distance)
		_good_spot(moved.position, "out of the wall")
	wall.queue_free()
	await physics_frame
	# Inside a parked vehicle (on foot), and beside a vehicle being flown 40 m up.
	var vehicles: Array = game.driveable_vehicles.filter(func(v) -> bool: return is_instance_valid(v) and not v.fixed_wing \
		and not v.helicopter and PlayerPlace.entrance_at(game, v.global_position) == "")
	check(not vehicles.is_empty(), "a road vehicle to test with")
	if not vehicles.is_empty():
		var car: Node3D = vehicles[0]
		var in_car := PlayerPlace.spawn_for(game, _place(car.global_position, ""))
		check(in_car.get("how") == "nearby", "inside a vehicle: a nearby spot")
		if in_car.get("how") == "nearby":
			check((in_car.position as Vector3).distance_to(car.global_position) > 0.5, "inside a vehicle: moved out")
			_good_spot(in_car.position, "beside the vehicle")
		var flying := car.global_position + Vector3.UP * 40.0
		var landed := PlayerPlace.spawn_for(game, _place(flying, "", true))
		check(landed.get("how") == "nearby" and (landed.position as Vector3).y < flying.y - 30.0, "flying: put on the ground below")
		if landed.get("how") == "nearby":
			_good_spot(landed.position, "below the flight")
	# On a roof: never on it (the ground beside the building, or the usual spawn).
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var above := _inside("supermarket", 10.0) + Vector3.UP * 80.0
	var roof := space.intersect_ray(PhysicsRayQueryParameters3D.create(above, above - Vector3.UP * 100.0))
	check(not roof.is_empty() and (roof.position as Vector3).y > 4.0, "the supermarket roof is found")
	if not roof.is_empty():
		var on_roof: Vector3 = roof.position + Vector3.UP * 0.1
		check(PlayerPlace.entrance_at(game, on_roof) == "", "on a roof counts as outdoors")
		var off := PlayerPlace.spawn_for(game, _place(on_roof, ""))
		check(off.is_empty() or (off.position as Vector3).y < on_roof.y - 2.0, "on a roof: not put back on it")
		if not off.is_empty():
			_good_spot(off.position, "off the roof")
		print("roof at ", on_roof, " -> ", off)
	# At sea (beyond every town zone): never in the water.
	var sea := Vector3.INF
	var centre := town.to_global(Vector3.ZERO)
	for step in range(10, 800, 5):
		var point := centre + Vector3.BACK.rotated(Vector3.UP, PI) * float(step)
		if game.zones.resolve_global(point) == "coast" and game.zones.resolve_global(point + Vector3.FORWARD * 30.0) == "coast":
			sea = point + Vector3.FORWARD * 30.0
			break
	check(sea != Vector3.INF, "a point at sea")
	if sea != Vector3.INF:
		var ashore := PlayerPlace.spawn_for(game, _place(sea, ""))
		check(ashore.is_empty() or game.zones.resolve_global(ashore.position) != "coast", "at sea: not put in the water")
		print("sea at ", sea, " -> ", ashore)


func _unloaded_unit() -> void:
	var loaded: Array = town.get_meta("loaded_units", [])
	town.set_meta("loaded_units", loaded.filter(func(key) -> bool: return key != "bank"))
	check(PlayerPlace.spawn_for(game, _place(_inside("supermarket", 3.0), "bank")).is_empty(), "a building that is not loaded: the usual spawn")
	town.set_meta("loaded_units", loaded)
	check(PlayerPlace.spawn_for(game, _place(Vector3.ZERO, "no_such_door")).is_empty(), "an unknown entrance: the usual spawn")


## Main with a profile: restores the saved place (bank) and the keeper saves the next one.
func _profile_restore() -> void:
	var manager = ProfileManager.shared()
	var id: String = manager.create("Check", "Check town", "bonbon")
	check(id != "", "test profile created")
	if id == "":
		return
	manager.update(id, {"tutorial": {"act": "", "done": true}})
	manager.select(id)
	check(PlayerPlace.enabled(), "with a profile: saving on")
	var in_bank := _inside("bank", 3.0)
	PlayerPlace.write(_place(in_bank, "bank"))
	await game._restore_place()
	check(game.player.global_position.distance_to(in_bank) <= PlayerPlace.INDOOR_RADIUS + 0.3, "Main restores the place inside the bank (at %s, saved %s)" % [game.player.global_position, in_bank])
	check(game.place_keeper != null, "Main starts the keeper")
	# An unusable place (unknown entrance): outside the home.
	if game.place_keeper != null:
		game.place_keeper.free()
	PlayerPlace.write(_place(Vector3.ZERO, "no_such_door"))
	await game._restore_place()
	var home: Array = game.ENTRANCES.home
	check(game.player.global_position.distance_to(ModularTown.building(town, home[0]).to_global(home[3])) < 0.5, "an unusable place: outside the home")
	# Settings' Save writes the place at once.
	if game.place_keeper != null:
		game.player.global_position = _inside("bank", 4.0)
		check(game.can_save(), "Save is offered")
		game.save_game()
		var written := PlayerPlace.read()
		check(written.get("entrance") == "bank" and town.to_global(Vector3(written.x, written.y, written.z)).distance_to(_inside("bank", 4.0)) < 0.01, "Save wrote the place")
	if game.place_keeper != null:
		game.player.global_position = _inside("library", 3.0)
		check(game.place_keeper.save_now(), "the keeper saves")
		var saved := PlayerPlace.read()
		check(saved.get("entrance") == "library", "the keeper saved the library (got '%s')" % saved.get("entrance"))
		game.place_keeper.free()
		check(FileAccess.file_exists(SaveStore.path(PlayerPlace.FILE)), "saved in the profile's folder")
	manager.select("")
	SaveStore.remove_tree(SaveStore.PROFILES_DIR)
	check(not DirAccess.dir_exists_absolute(SaveStore.PROFILES_DIR), "test profile removed")
