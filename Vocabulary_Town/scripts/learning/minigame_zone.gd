extends Node
## The shared parts of a minigame played IN THE WORLD rather than in a panel (8 Nov 2026,
## from the idea in docs/guides/future_minigame_zone.md): the fade to black, putting the player at a
## spot, and a doorway that notices the player walking out. Used with minigame_host.gd (which
## owns the leave question); the session keeps its game state and decides what each event
## means. Guide: docs/MINIGAMES.md. Users: grammar_session.gd, mahjong_session.gd,
## warehouse_session.gd (since 9 Nov 2026); the door guard (make_door_guard): mystery_session.gd
## and restaurant_session.gd (since 11 Nov 2026).
const FADE_SECONDS := 0.35

var player: Node3D
## Main: its seating (stand the player up before moving them) and sync_player_controls().
var main
var _fade: ColorRect
## True while a fade is running (ignore talk and leave requests meanwhile).
var fading := false

func setup(explorer: Node3D, game, layer_name: String) -> void:
	name = "MinigameZone"
	player = explorer
	main = game
	var layer := CanvasLayer.new()
	layer.name = layer_name
	layer.layer = 90
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)

## Fades the screen to `alpha` (1 black, 0 clear); await it. The player cannot move while the
## screen is dark; at 0 Main decides the controls again (an open panel may still lock them).
func fade_to(alpha: float) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	player.set_controls_enabled(alpha <= 0.0)
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_SECONDS)
	await tween.finished
	if alpha <= 0.0:
		main.sync_player_controls()

## Fade out, run `between` (move the player, build things), wait a physics frame, fade in.
func fade_through(between: Callable) -> void:
	fading = true
	await fade_to(1.0)
	between.call()
	await get_tree().physics_frame
	await fade_to(0.0)
	fading = false

## Puts the player at `spot` facing `look`, both in `space`'s local coordinates (a building
## root: its model scale and rotation apply), standing up first if seated; the camera follows.
func place_player(space: Node3D, spot: Vector3, look: Vector3) -> void:
	if player.seated and main.seating != null:
		main.seating.stand()
	player.global_position = space.to_global(spot + Vector3(0, .1, 0))
	player.velocity = Vector3.ZERO
	var forward: Vector3 = space.global_basis * look
	var yaw := atan2(-forward.x, -forward.z)
	player.rotation.y = yaw
	player.camera_yaw = yaw
	player.reset_camera()

## An invisible box under `parent` at `position` (parent's local coordinates) that calls
## `on_enter` when the player walks into it; the session decides whether it matters now.
func make_doorway(parent: Node3D, position: Vector3, size: Vector3, title: String, on_enter: Callable) -> Area3D:
	var doorway := Area3D.new()
	doorway.name = title
	doorway.monitorable = false
	doorway.collision_mask = player.collision_layer
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	doorway.add_child(shape)
	parent.add_child(doorway)
	doorway.position = position
	doorway.body_entered.connect(func(body: Node) -> void:
		if body == player:
			on_enter.call())
	return doorway

## A doorway the player cannot walk out of mid-game (user, 10 and 11 Nov 2026; first built for
## the Mystery House arch, shared on 11 Nov 2026 with the Alta Cocina entrance): an invisible
## wall fills it while `options.blocking` says so, and a question zone just inside it asks to
## leave. Positions and sizes are in `parent`'s local coordinates. Options (Callables unless
## noted):
##   blocking() -> bool   the wall stands now (a game runs and the player is inside)
##   can_ask() -> bool    walking into the zone asks now (checked with blocking())
##   ask()                ask the question (the session pauses its game, host.ask_leave(...))
##   cancel()             the player stepped back out while asked (host.cancel_leave(), resume)
##   asking() -> bool     the question is still up (host.is_asking_leave)
##   layer (int)          the wall's collision layer (default 1; FIGURE_LAYER stops only the
##                        player and lets the pointer through)
## The session clears `asked` when the question is answered. The guard ticks itself.
func make_door_guard(parent: Node3D, wall_at: Vector3, wall_size: Vector3, ask_at: Vector3, ask_size: Vector3, title: String, options: Dictionary) -> DoorGuard:
	var guard := DoorGuard.new()
	guard.name = title + " guard"
	guard.player = player
	guard.options = options
	guard.wall = StaticBody3D.new()
	guard.wall.name = title + " barrier"
	guard.wall.collision_layer = int(options.get("layer", 1))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = wall_size
	shape.shape = box
	shape.disabled = true
	guard.wall.add_child(shape)
	parent.add_child(guard.wall)
	guard.wall.position = wall_at
	guard.zone = make_doorway(parent, ask_at, ask_size, title + " question", guard.entered)
	add_child(guard)
	return guard

class DoorGuard extends Node:
	var player: Node3D
	var options: Dictionary
	var wall: StaticBody3D
	var zone: Area3D
	## The question was asked here and is still up.
	var asked := false

	func _call(key: String, fallback: Variant = false) -> Variant:
		var callable: Callable = options.get(key, Callable())
		return callable.call() if callable.is_valid() else fallback

	func entered() -> void:
		if not asked and _call("blocking") and _call("can_ask", true) and not _call("asking"):
			asked = true
			_call("ask", null)

	func blocks() -> bool:
		return not (wall.get_child(0) as CollisionShape3D).disabled

	func _process(_delta: float) -> void:
		if not is_instance_valid(wall) or not is_instance_valid(player):
			return
		var block: bool = _call("blocking")
		var shape := wall.get_child(0) as CollisionShape3D
		if shape.disabled == block:
			shape.set_deferred("disabled", not block)
		if asked and not _call("asking"):
			asked = false
		elif asked and not zone.overlaps_body(player):
			asked = false
			_call("cancel", null)
