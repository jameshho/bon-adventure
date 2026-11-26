extends Node
## Nearby loading on phones (user decision, 17 Nov 2026: option A of the proposal in
## docs/guides/performance/README.md, "Load only nearby buildings on phones"): on the web, a profile that finished the welcome tutorial starts its town with only the
## building units (data/buildings.json) near where it comes back (app.gd start_town():
## initial_for()), and this node then adds the others with Main.add_unit() as the player comes
## within LOAD_RADIUS of them, nearest first, one at a time. Since 26 Nov 2026 (user: "free far
## buildings to fix the memory", option B; a phone browser kept killing the page) it also frees
## a loaded unit again once it is beyond FREE_RADIUS (Main.remove_unit(), the farthest first, one
## at a time; never while the tutorial or a minigame runs, nor the unit the player drives, sits in
## or holds something from, nor one whose vehicle is near: Main.unit_pin()). The gap between the
## two radii keeps a unit at the edge from coming and going. Until 26 Nov units were never freed.
## The view ends at 130 m in fog (render_culling.gd VIEW_DISTANCE), so a unit arrives 20 m
## beyond what can be seen; flying, the view grows with height (vehicle_controls.gd
## update_flight_view()) and the radius grows with it (VIEW_MARGIN beyond the camera's far).
## Moving fast (driving, flying, sprinting), the spot LOOK_AHEAD seconds ahead counts too.
## Units' boxes and which unit each minigame's session lives in come from data/nearby_units.json
## (written by tools/nearby_units_data.gd; run it again after a unit's footprint or minigames
## change). The minigame picker loads an absent game's unit before starting it (game_launcher.gd).
## VT_NEARBY=1 / 0 forces it on / off (checks run it natively).
## Arrival spread (26 Nov 2026, user): a pending unit within PREPARE_MARGIN beyond the loading
## reach is prepared first (prepare()): its scene is loaded in one frame and instanced in the
## next (kept in Main.prepared_units for add_unit()), so neither shares the frame that adds its
## nodes. A unit that comes within reach unprepared is added at once. Drawing each material once
## ahead to compile its shader was tried the same day and dropped: natively it added 150 ms
## frames and the arrival frames did not get shorter (docs/evidence/far-unit-freeing-20261126).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const DATA := "res://data/nearby_units.json"
## Metres (world) from a unit's nearest part box at which it is added.
const LOAD_RADIUS := 150.0
## Metres (world) from a unit's nearest part box beyond which it is freed again (flying: this far
## beyond the loading reach). Larger than LOAD_RADIUS so a unit at the edge does not flicker.
const FREE_RADIUS := 220.0
const FREE_MARGIN := FREE_RADIUS - LOAD_RADIUS
## Flying with a longer view: units are added this far beyond the camera's far plane instead.
const VIEW_MARGIN := 20.0
## Seconds of the current speed looked ahead, above LOOK_AHEAD_SPEED metres per second.
const LOOK_AHEAD := 3.0
const LOOK_AHEAD_SPEED := 9.0
## How often the distances are checked, and the least time between two additions.
const CHECK_SECONDS := 0.25
const GAP_MS := 500
## Metres beyond the loading reach at which a pending unit is prepared (prepare()); a prepared unit
## that is this much again beyond it is dropped.
const PREPARE_MARGIN := 40.0

static var _data: Dictionary

var main: Node
var _timer := 0.0
var _last_add := 0
var _busy := false
var _last_spot := Vector3.INF
var _velocity := Vector3.ZERO

static func enabled() -> bool:
	var forced := OS.get_environment("VT_NEARBY").strip_edges()
	if forced != "":
		return forced == "1"
	return OS.has_feature("web")

static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(DATA):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if parsed is Dictionary:
			_data = parsed
	return _data

## The unit a minigame's session lives in ("" when unknown or not in a unit).
static func unit_of_activity(id: String) -> String:
	return str(data().get("activities", {}).get(id, ""))

## Distance (town units) from town point `at` (XZ) to unit `key`'s nearest part box; 0 for a
## unit with no box in the data (a new unit before the tool ran: it simply loads at once).
static func distance(key: String, at: Vector2) -> float:
	var boxes: Array = data().get("boxes", {}).get(key, [])
	if boxes.is_empty():
		return 0.0
	var best := INF
	for box in boxes:
		var dx := maxf(maxf(box[0] - at.x, 0.0), at.x - box[2])
		var dz := maxf(maxf(box[1] - at.y, 0.0), at.y - box[3])
		best = minf(best, Vector2(dx, dz).length())
	return best

## Units of `keys` within `radius` (town units) of town point `at`, nearest first.
static func near(keys: Array, at: Vector2, radius: float) -> Array:
	var found: Array = keys.filter(func(key) -> bool: return distance(key, at) <= radius)
	found.sort_custom(func(a, b) -> bool: return distance(a, at) < distance(b, at))
	return found

## Units to build before the town is ready for a player coming back at town point `at` (XZ),
## plus `must` (the saved building's unit, or the default spawn's), among the focused units.
## `scale`: town units per world metre is 1 / scale (Main's Apartment scale, 1.3).
static func initial_for(at: Vector2, scale: float, must: Array) -> Array:
	var focused: Array = ModularTown.focused_units()
	if data().is_empty() or focused.is_empty():
		return []
	var result: Array = near(focused, at, LOAD_RADIUS / scale)
	for key in must:
		if focused.has(key) and not result.has(key):
			result.append(key)
	# Never empty (an empty list means every unit to Main).
	if result.is_empty() and not focused.is_empty():
		result.append(near(focused, at, INF)[0])
	return result

func setup(game: Node) -> void:
	main = game
	name = "NearbyUnits"

func _process(delta: float) -> void:
	if not is_instance_valid(main):
		queue_free()
		return
	_timer += delta
	if _timer < CHECK_SECONDS:
		return
	var spot: Vector3 = main.player.get_meta("map_position", main.player.global_position)
	if _last_spot.is_finite():
		_velocity = (spot - _last_spot) / _timer
	_last_spot = spot
	_timer = 0.0
	if _busy or main._adding_unit or Time.get_ticks_msec() - _last_add < GAP_MS:
		return
	var key := _next_unit(spot)
	if key == "":
		# Nothing to add: prepare the next one, or free the farthest unit beyond reach.
		_drop_prepared(spot)
		var soon := _next_unit(spot, PREPARE_MARGIN)
		if soon != "" and not main.prepared_units.has(soon):
			_busy = true
			await prepare(soon)
			_busy = false
			return
		var far := _far_unit(spot)
		if far != "" and main.remove_unit(far, _free_reach()):
			_last_add = Time.get_ticks_msec()
		return
	_busy = true
	await main.add_unit(key)
	_last_add = Time.get_ticks_msec()
	_busy = false

## Metres (world) beyond which a loaded unit is freed: FREE_RADIUS, or further while the view is
## longer (flying high).
func _free_reach() -> float:
	var camera: Camera3D = main.player.camera
	var reach := maxf(LOAD_RADIUS, camera.far + VIEW_MARGIN) if camera != null else LOAD_RADIUS
	return reach + FREE_MARGIN

## The loaded unit farthest from `spot` (world; and the look-ahead point) beyond _free_reach(), or
## "". Only units the data knows (a unit with no box never goes).
func _far_unit(spot: Vector3) -> String:
	if not enabled():
		return ""
	var town: Node3D = main.apartment
	var scale: float = town.global_basis.get_scale().x
	var here := town.to_local(spot)
	var points: Array = [Vector2(here.x, here.z)]
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	if flat.length() > LOOK_AHEAD_SPEED:
		var ahead := town.to_local(spot + flat * LOOK_AHEAD)
		points.append(Vector2(ahead.x, ahead.z))
	var radius := _free_reach() / scale
	var best := ""
	var best_distance := radius
	for key in town.get_meta("loaded_units", []):
		if data().get("boxes", {}).get(key, []).is_empty():
			continue
		var nearest := INF
		for point in points:
			nearest = minf(nearest, distance(key, point))
		if nearest > best_distance and main.unit_pin(key, _free_reach()) == "":
			best = key
			best_distance = nearest
	return best

## Loads and instances pending unit `key` over two frames (see the header). The instance waits in
## Main.prepared_units; add_unit() takes it.
func prepare(key: String) -> void:
	if main.prepared_units.has(key) or not main.pending_units.has(key):
		return
	var scene := load(ModularTown.FOLDER + key + "." + ModularTown.EXTENSION) as PackedScene
	await get_tree().process_frame
	if scene == null or not is_instance_valid(main) or not main.pending_units.has(key) or main.prepared_units.has(key):
		return
	var unit := scene.instantiate()
	main.prepared_units[key] = unit

## Frees prepared units that are far again (the player turned away).
func _drop_prepared(spot: Vector3) -> void:
	for key in main.prepared_units.keys():
		if _next_unit(spot, PREPARE_MARGIN * 2.0, [key]) == "":
			var unit: Node = main.prepared_units[key]
			main.prepared_units.erase(key)
			if is_instance_valid(unit):
				unit.free()

func _exit_tree() -> void:
	if is_instance_valid(main):
		for unit in main.prepared_units.values():
			if is_instance_valid(unit):
				unit.free()
		main.prepared_units.clear()

## The nearest pending unit (of `among`, else all) within reach of `spot` (world) plus `margin`
## metres, or "".
func _next_unit(spot: Vector3, margin := 0.0, among: Array = []) -> String:
	var town: Node3D = main.apartment
	var scale: float = town.global_basis.get_scale().x
	var here := town.to_local(spot)
	var points: Array = [Vector2(here.x, here.z)]
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	if flat.length() > LOOK_AHEAD_SPEED:
		var ahead := town.to_local(spot + flat * LOOK_AHEAD)
		points.append(Vector2(ahead.x, ahead.z))
	var camera: Camera3D = main.player.camera
	var reach := maxf(LOAD_RADIUS, camera.far + VIEW_MARGIN) if camera != null else LOAD_RADIUS
	var radius := (reach + margin) / scale if enabled() else INF
	var best := ""
	var best_distance := INF
	for key in (among if not among.is_empty() else main.pending_units):
		for point in points:
			var d := distance(key, point)
			if d <= radius and d < best_distance:
				best = key
				best_distance = d
	return best
