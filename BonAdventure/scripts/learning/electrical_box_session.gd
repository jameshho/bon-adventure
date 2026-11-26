extends Node
## Electrical box repair (pastime, user request, 9 Nov 2026; docs/guides/ELECTRICAL_BOX.md). No NPC:
## E near a box or a click on it (scripts/world/electrical_box.gd use()) calls open_box(). The
## door swings open while a temporary camera glides from the player's view to a close-up of
## the box; then the wires inside are played in 3D, through the transparent input layer
## scripts/ui/electrical_box_panel.gd (a work light lights the inside meanwhile).
## All wires right: the panel shows "Electrical Box Repaired!", the box is marked repaired, and
## after SUCCESS_SECONDS everything runs backwards (door shuts, camera returns, player moves
## again). Esc or the ✕ leaves early the same way, without repairing. Once closed, the box is
## reset (broken, wires loose; user, 10 Nov 2026), so every opening is a new puzzle.
##
## The panel stays visible (transparent while the camera moves) from the first frame to the
## last, so Main locks the player for the whole sequence (minigame_wiring.gd PANELS, locks flag) and Esc
## reaches close_box() through the popup stack. Registered on the activity board as
## "electrical_box" (data/activities.json, kind "pastime", chance 0: never offered), so other
## games refuse while a box is open and the test launcher can open the nearest box (launch()).
##
## Silent itself: these signals are the sound hooks (scripts/core/sound.gd, later).
signal box_opened(box: Node3D)
signal box_repaired(box: Node3D)
signal box_closed(box: Node3D)

const Board := preload("res://scripts/learning/activity_board.gd")
const ElectricalBox := preload("res://scripts/world/electrical_box.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const ID := "electrical_box"
const GROUP := "electrical_box_session"
## 0.88 s: 10 % slower than the first 0.8 s (user, 10 Nov 2026).
const ZOOM_SECONDS := 0.88
const RETURN_SECONDS := 0.65
## How long "Electrical Box Repaired!" shows before the screen closes by itself.
const SUCCESS_SECONDS := 1.12
## The return after a repair; 30 % quicker than leaving early (user, 10 Nov 2026: completion to
## closed box 2.25 s -> 1.575 s, both parts scaled by 0.7).
const SOLVED_RETURN_SECONDS := 0.455
## Share of the camera glide after which the player model is hidden (she would stand between
## the close-up camera and the box).
const HIDE_PLAYER_AT := 0.55

var panel
var main
## No NPC host (the test launcher then calls launch()).
var host = null
var box: Node3D
## "" (closed), "opening", "playing", "solved" or "closing".
var state := ""
var _camera: Camera3D
var _tween: Tween
var _player_was_visible := true
## A wire went to a wrong socket in this opening (the stars count one miss).
var _missed := false

func setup(box_panel, game) -> void:
	panel = box_panel
	main = game
	panel.close_requested.connect(close_box)
	panel.solved.connect(_on_solved)
	# A wire dropped on the wrong socket: one star miss per opening (LEARN-06, 25 Nov 2026).
	panel.wire_rejected.connect(func(_index: int) -> void:
		if state == "playing" and not _missed:
			_missed = true
			Board.shared().add_miss(ID))
	# The minimap, clock and help would show through the close-up (as in radar_patrol_session.gd).
	panel.visibility_changed.connect(func() -> void:
		if main.hud != null:
			main.hud.hide_for_game(panel.visible))
	add_to_group(GROUP)
	Board.shared().register(ID, self)

## A box was used: open it unless something else is in progress. True when it opened.
func open_box(target: Node3D) -> bool:
	if state != "" or target == null or panel == null or panel.visible:
		return false
	if Board.shared().blocker(ID) != "" or main.player.seated or is_instance_valid(main.active_vehicle):
		return false
	box = target
	state = "opening"
	# On top of every HUD part added after it.
	panel.get_parent().move_child(panel, -1)
	# Levels (data/activities.json electrical_box "levels" "wires"; docs/game/minigames.md#wire-it-up):
	# how many wires the puzzle has. A box with its own wire colours keeps them.
	var wires := int(Progress.shared().params(ID).get("wires", 0))
	if wires > 0 and box.wire_colors.is_empty():
		box.wire_count = wires
	Board.shared().begin(ID)
	_missed = false
	panel.begin(box.palette(), box)
	main.interaction.clear_card()
	var from: Camera3D = main.player.camera
	_camera = Camera3D.new()
	_camera.name = "ElectricalBoxCamera"
	_camera.fov = from.fov
	_camera.near = minf(from.near, 0.05)
	_camera.far = from.far
	_camera.cull_mask = from.cull_mask
	_camera.attributes = from.attributes
	_camera.environment = from.environment
	main.add_child(_camera)
	_camera.global_transform = from.global_transform
	_camera.make_current()
	panel.camera = _camera
	box.set_work_light(true)
	_player_was_visible = main.player.visible
	box.set_door_open(true, ZOOM_SECONDS * 0.7)
	_glide(from.global_transform, box.view_transform(_camera.fov), ZOOM_SECONDS, _on_arrived)
	box_opened.emit(box)
	return true

## Esc, the ✕, the end of the success message, or a language change: everything closes.
func close_box() -> void:
	if state == "" or state == "closing":
		return
	var seconds := SOLVED_RETURN_SECONDS if state == "solved" else RETURN_SECONDS
	state = "closing"
	panel.hide_puzzle()
	if is_instance_valid(box):
		# Leaving early: the loose wires drop back before the door shuts.
		if not box.repaired:
			box.reset_wires()
		box.set_door_open(false, seconds)
	main.player.visible = _player_was_visible
	_glide(_camera.global_transform, main.player.camera.global_transform, seconds, _on_returned, true)

func _glide(from: Transform3D, to: Transform3D, seconds: float, done: Callable, returning := false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_place_camera.bind(from, to, returning), 0.0, 1.0, seconds)
	_tween.tween_callback(done)

func _place_camera(t: float, from: Transform3D, to: Transform3D, returning: bool) -> void:
	if not is_instance_valid(_camera):
		return
	# Going back, aim at where the player camera is now (it keeps following the player).
	var target: Transform3D = main.player.camera.global_transform if returning else to
	_camera.global_transform = from.interpolate_with(target, t)
	if not returning and t >= HIDE_PLAYER_AT:
		main.player.visible = false

func _on_arrived() -> void:
	if state != "opening":
		return
	state = "playing"
	panel.show_puzzle()

func _on_solved() -> void:
	if state != "playing":
		return
	state = "solved"
	# A repaired box finishes the opening: stars and level (a pastime counts only this way).
	Board.shared().complete(ID)
	if is_instance_valid(box):
		box.set_repaired(true)
		box_repaired.emit(box)
	get_tree().create_timer(SUCCESS_SECONDS).timeout.connect(func() -> void:
		if state == "solved":
			close_box())

func _on_returned() -> void:
	if is_instance_valid(main.player.camera):
		main.player.camera.make_current()
	if is_instance_valid(_camera):
		_camera.queue_free()
	_camera = null
	var closed := box
	if is_instance_valid(closed):
		closed.set_work_light(false)
		# Every close resets the box (user, 10 Nov 2026): broken again, wires loose, and the
		# next opening shuffles a new puzzle (electrical_box_panel.gd begin()).
		closed.set_repaired(false)
		closed.reset_wires()
	box = null
	state = ""
	panel.finish()
	box_closed.emit(closed)

## The test launcher's Play: opens the nearest box in town (the camera flies there).
func launch() -> void:
	var best: Node3D = null
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group(ElectricalBox.GROUP):
		var distance: float = main.player.global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best != null:
		open_box(best)

## A language change ends every activity (Main._on_settings_changed).
func end_activity() -> void:
	close_box()

func activity_running() -> bool:
	return state != ""

func busy() -> bool:
	return activity_running()
