extends Node
## The shared parts of a minigame played SEATED AT A TABLE in the world (9 Nov 2026, taken out of
## mahjong_session.gd): the host NPC gets up from its chair and steps aside, the player sits down
## in it (seating_controller.gd sit_at()), and the screen fades (minigame_zone.gd) into the
## game's own camera with the player's model and the HUD's game overlays hidden
## (vocabulary_hud.gd hide_for_game()). Leaving fades back: the player stands up and the host
## sits down again. The session keeps its game and decides when; it builds its own screen
## inside the fades. Guide: docs/MINIGAMES.md. Users: mahjong_session.gd.
##
##     table = MinigameTable.new()
##     add_child(table)
##     table.setup(main, player, zone, chair, host_npc, {"scene": ..., "name": ..., ...})
##     if await table.begin(_open_my_screen): _deal()
##     ...
##     await table.end(_close_my_screen)
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
## The host's step from beside its chair to where it stands, then a short pause once the player
## has sat down, before the fade.
const STEP_SECONDS := 0.7
const SEATED_PAUSE := 0.4
## Where standing up starts looking for a free spot (chair-local): behind the chair.
const STAND_BACK := Vector3(0.0, 0.0, 0.9)

var main
var player: Node3D
var zone
var chair: Node3D
var host_npc: Node3D
## The host standing beside the table while the player has its chair (null otherwise).
var stand_in: Node3D
## The game's camera while the player sits in the game view (null otherwise).
var camera: Camera3D
## True from the fade into the game view until the player stands up.
var active := false
var _spec: Dictionary = {}
var _going := false

## `spec` (global points): "scene" the host's standing plush scene, "name_node" its node name,
## "gets_up_at" where it appears beside its chair, "stands_at" where it waits, "faces" what it
## looks at (default the table, the chair's parent), "camera_at", "camera_look", "fov".
func setup(game_main, explorer: Node3D, shared_zone, seat_chair: Node3D, host: Node3D, spec: Dictionary) -> void:
	name = "MinigameTable"
	main = game_main
	player = explorer
	zone = shared_zone
	chair = seat_chair
	host_npc = host
	_spec = spec

## The host gets up, the player sits down, the screen fades into the game view; `inside` runs
## while the screen is black (build the game's screen there). False when cancel() or
## release() stopped it on the way (nothing is left half done).
func begin(inside: Callable) -> bool:
	_going = true
	_host_gets_up()
	await get_tree().create_timer(STEP_SECONDS).timeout
	if not _going:
		return false
	main.seating.sit_at(chair, STAND_BACK)
	for i in 120:
		await get_tree().process_frame
		if not player.sit_transition:
			break
	await get_tree().create_timer(SEATED_PAUSE).timeout
	if not _going:
		return false
	await zone.fade_through(func() -> void:
		if _going:
			_enter()
			inside.call())
	return _going

## Fades back to the town: `inside` runs while the screen is black (close the game's screen),
## then the player stands up and the host sits down again.
func end(inside: Callable) -> void:
	await zone.fade_through(func() -> void:
		inside.call()
		release())

## Stops a begin() on its way.
func cancel() -> void:
	_going = false

## Back to the town at once, without a fade (also stops a begin()).
func release() -> void:
	_going = false
	active = false
	if camera != null:
		camera.queue_free()
		camera = null
	var player_camera = player.get("camera")
	if player_camera is Camera3D:
		player_camera.make_current()
	var model = player.get("visual")
	if model is Node3D:
		model.visible = true
	main.hud.hide_for_game(false)
	if player.seated:
		main.seating.stand()
		if player.seated or player.sit_transition:
			# No safe spot found by the seating controller: stand behind the chair.
			player.end_sitting(chair.to_global(STAND_BACK))
	if stand_in != null:
		stand_in.queue_free()
		stand_in = null
	if host_npc != null:
		host_npc.visible = true

## The host stands up beside its chair and steps to its place.
func _host_gets_up() -> void:
	host_npc.visible = false
	var stands_at: Vector3 = _spec.stands_at
	var faces: Vector3 = _spec.get("faces", chair.get_parent().global_position)
	var facing := Vector3(faces.x - stands_at.x, 0.0, faces.z - stands_at.z).normalized()
	stand_in = HouseCharacters.new().worker(str(_spec.scene), "", "person", host_npc.get_parent(), str(_spec.get("name_node", "Host standing")), _spec.gets_up_at, facing)
	# The host's own name, kept current by the session (a language change renames it).
	stand_in.set_meta("character_name", host_npc.get_meta("character_name", ""))
	var step := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	step.tween_property(stand_in, "global_position", stands_at, STEP_SECONDS)

## Behind the fade: the host at its place, the player seated, the model and HUD overlays hidden,
## the game camera on.
func _enter() -> void:
	if stand_in != null:
		stand_in.global_position = _spec.stands_at
	if not player.seated:
		main.seating.sit_at(chair, STAND_BACK)
	var model = player.get("visual")
	if model is Node3D:
		model.visible = false
	main.hud.hide_for_game(true)
	camera = Camera3D.new()
	camera.name = "TableCamera"
	camera.fov = float(_spec.get("fov", 45.0))
	camera.near = 0.05
	add_child(camera)
	var at: Vector3 = _spec.camera_at
	var look: Vector3 = _spec.camera_look
	camera.global_transform = Transform3D.IDENTITY.looking_at(look - at, Vector3.UP)
	camera.global_position = at
	camera.make_current()
	active = true
