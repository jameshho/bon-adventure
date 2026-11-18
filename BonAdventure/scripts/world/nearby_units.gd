extends Node
## Nearby loading on phones (user decision, 17 Nov 2026: option A of the proposal in
## docs/guides/performance/README.md, "Load only nearby buildings on phones"): on the web with
## Low graphics, a profile that finished the welcome tutorial starts its town with only the
## building units (data/buildings.json) near where it comes back (app.gd start_town():
## initial_for()), and this node then adds the others with Main.add_unit() as the player comes
## within LOAD_RADIUS of them, nearest first, one at a time. Units are never freed (grow only),
## so the town ends where it is today once the player has been everywhere; until then the GPU
## holds only what is near (measured: about 60 of the units' 157 MB at a typical spot).
## Low's view ends at 130 m in fog (render_culling.gd LOW_VIEW_DISTANCE), so a unit arrives
## 20 m beyond what can be seen. Moving fast (driving, flying, sprinting), the spot LOOK_AHEAD
## seconds ahead counts too. With High graphics (chosen in Settings while playing) every pending
## unit is added, nearest first, since High draws the whole town.
## Units' boxes and which unit each minigame's session lives in come from data/nearby_units.json
## (written by tools/nearby_units_data.gd; run it again after a unit's footprint or minigames
## change). The minigame picker loads an absent game's unit before starting it (game_launcher.gd).
## VT_NEARBY=1 / 0 forces it on / off (checks run it natively).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const DATA := "res://data/nearby_units.json"
## Metres (world) from a unit's nearest part box at which it is added.
const LOAD_RADIUS := 150.0
## Seconds of the current speed looked ahead, above LOOK_AHEAD_SPEED metres per second.
const LOOK_AHEAD := 3.0
const LOOK_AHEAD_SPEED := 9.0
## How often the distances are checked, and the least time between two additions.
const CHECK_SECONDS := 0.25
const GAP_MS := 500

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
	return OS.has_feature("web") and GameSettings.shared().graphics == GameSettings.LOW

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
	if not is_instance_valid(main) or main.pending_units.is_empty():
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
		return
	_busy = true
	await main.add_unit(key)
	_last_add = Time.get_ticks_msec()
	_busy = false

## The nearest pending unit within reach of `spot` (world), or "".
func _next_unit(spot: Vector3) -> String:
	var town: Node3D = main.apartment
	var scale: float = town.global_basis.get_scale().x
	var here := town.to_local(spot)
	var points: Array = [Vector2(here.x, here.z)]
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	if flat.length() > LOOK_AHEAD_SPEED:
		var ahead := town.to_local(spot + flat * LOOK_AHEAD)
		points.append(Vector2(ahead.x, ahead.z))
	var radius := LOAD_RADIUS / scale if enabled() else INF
	var best := ""
	var best_distance := INF
	for key in main.pending_units:
		for point in points:
			var d := distance(key, point)
			if d <= radius and d < best_distance:
				best = key
				best_distance = d
	return best
