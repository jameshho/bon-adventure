extends Node
## Far plush meshes (26 Nov 2026, option C of docs/guides/performance/README.md "Load only nearby
## buildings on phones"; user: free far plush characters' meshes). On the web (with nearby
## loading, NearbyUnits.enabled()), a plush character of the town more than STRIP_RADIUS from
## the player and the camera gives up its meshes (SculptCache.strip(): nodes, scripts, collision
## and costumes stay) and gets them back (SculptCache.unstrip()) once within RESTORE_RADIUS, or
## sooner when the player moves fast (look-ahead). Plushes are drawn only to 45 m
## (render_culling.gd PLUSH_RANGE), so one coming back is ready well before it shows.
## At most one plush is stripped per CHECK_SECONDS and one restored per frame (a restore loads
## its meshes from user://far_meshes/, a few ms). Made by app.gd next to NearbyUnits.
const SculptCache := preload("res://scripts/characters/sculpt_cache.gd")

## Metres (world).
const STRIP_RADIUS := 80.0
const RESTORE_RADIUS := 60.0
## Seconds of movement the restore radius looks ahead (cars reach 45 m/s, flying more).
const LOOK_AHEAD := 1.5
const CHECK_SECONDS := 0.25

var main: Node
var _timer := 0.0
var _last_spot := Vector3.INF
var _speed := 0.0
## Plushes whose meshes could not be saved (strip() false): not tried again.
var _failed := {}

func setup(game: Node) -> void:
	main = game
	name = "FarPlushMeshes"

## Distance (metres) from `node` to the nearer of the player and the camera.
func _distance(node: Node3D) -> float:
	var at := node.global_position
	var near := at.distance_to(main.player.global_position)
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		near = minf(near, at.distance_to(camera.global_position))
	return near

## Plush characters of the town (not avatars in other viewports).
func _characters() -> Array:
	var town: Node = main.apartment
	return SculptCache.built_characters().filter(func(node) -> bool:
		return node is Node3D and node.is_inside_tree() and town.is_ancestor_of(node))

func _process(delta: float) -> void:
	if not is_instance_valid(main) or not is_instance_valid(main.player):
		return
	var characters := _characters()
	var reach := RESTORE_RADIUS + _speed * LOOK_AHEAD
	# Restore first, nearest, one per frame.
	var nearest: Node3D = null
	var nearest_distance := reach
	for node: Node3D in characters:
		if SculptCache.is_stripped(node):
			var d := _distance(node)
			if d < nearest_distance:
				nearest = node
				nearest_distance = d
	if nearest != null:
		SculptCache.unstrip(nearest)
		return
	_timer += delta
	if _timer < CHECK_SECONDS:
		return
	var spot: Vector3 = main.player.global_position
	_speed = 0.0 if not _last_spot.is_finite() else spot.distance_to(_last_spot) / _timer
	_last_spot = spot
	_timer = 0.0
	# Strip the farthest beyond STRIP_RADIUS (and beyond the look-ahead reach).
	var farthest: Node3D = null
	var farthest_distance := maxf(STRIP_RADIUS, reach + 10.0)
	for node: Node3D in characters:
		if not SculptCache.is_stripped(node) and not _failed.has(node.get_instance_id()):
			var d := _distance(node)
			if d > farthest_distance:
				farthest = node
				farthest_distance = d
	if farthest != null and not SculptCache.strip(farthest):
		_failed[farthest.get_instance_id()] = true
