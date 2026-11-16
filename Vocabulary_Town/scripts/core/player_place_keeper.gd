extends Node
## Saves the player's place while the town runs (player_place.gd has the file, the rules and
## when; Main._restore_place() adds this node once the town is ready).
const PlayerPlace := preload("res://scripts/core/player_place.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")

var main: Node
## The profile's file, fixed at setup: a save while the town is torn down (a profile switch)
## still goes to this profile.
var path := ""
var _elapsed := 0.0
var _last := Vector3.INF

func setup(game: Node) -> void:
	main = game
	name = "PlayerPlaceKeeper"
	path = SaveStore.path(PlayerPlace.FILE)
	var player: Node3D = main.get("player")
	if is_instance_valid(player):
		_last = player.global_position

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < PlayerPlace.SAVE_SECONDS:
		return
	_elapsed = 0.0
	var player: Node3D = main.get("player")
	if is_instance_valid(player) and player.global_position.distance_to(_last) >= PlayerPlace.MOVE_METRES:
		save_now()

## Writes the place now (also called by web_resume.gd when the page is hidden).
func save_now() -> bool:
	if path == "" or SaveStore.read_only or not is_instance_valid(main) or not main.is_inside_tree():
		return false
	var place := PlayerPlace.capture(main)
	if place.is_empty():
		return false
	_last = main.player.global_position
	return PlayerPlace.write(place, path)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE]:
		save_now()
