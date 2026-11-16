extends Node
## The parts of a talking NPC that every minigame shares (moved out of shop_session.gd,
## 4 Nov 2026): the small hop while it is calling the player, and the face close-up camera
## used while it talks. The gold "!" itself moved to the shared interaction icons on 12 Nov
## 2026 (scripts/ui/interact_badge.gd): animate() sets the NPC's Interactable `calling`, and
## the focus pass draws the "!" (or the "E" once the player is in range). The
## session that owns the NPC decides WHEN it calls (animate(delta, calling)) and when the
## camera zooms (zoom_to_face()); this node knows nothing about shops or games.
## Made by minigame_host.gd for every game on the shared host (docs/guides/MINIGAMES.md#building-a-minigame);
## warehouse_session.gd also makes one for Ramón's twin in the copy.

## "Calling" animation: the NPC hops (the "!" bobs above the head, interact_badge.gd).
const HOP_HEIGHT := 0.14
const HOP_SPEED := 3.6
## Talking camera: a close-up of the NPC's face, eased in and out (angle chosen 8 Nov 2026 from
## renders of every minigame NPC, docs/evidence/talk-camera-20261108/): FACE_ELEVATION degrees above
## the face, looking down, with the face FACE_SCREEN_Y of the way down the screen so the
## dialogue box at the bottom never covers it.
const FACE_FOV := 55.0
const FACE_DISTANCE := 3.6
const FACE_ELEVATION := 18.0
const FACE_SCREEN_Y := 0.34
## A wall or shelf between the face and the camera: try the camera this many degrees round the
## NPC, in order; if every side is blocked, move in to the nearest blocker (not closer than
## FACE_MIN_DISTANCE).
const FACE_YAW_TRIES := [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0]
const FACE_MIN_DISTANCE := 1.6
const ZOOM_SECONDS := 0.4

var npc: Node3D
var player: Node3D
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")

var rest_position := Vector3.ZERO
## Height of the "!" / "E" above the NPC's origin (NPC-local units): just above its head.
var marker_rest_y := 0.0
var calling := false
var _animation_time := 0.0
var _talk_camera: Camera3D
var _previous_camera: Camera3D
var _zoom_tween: Tween
## True while the talk camera hides the player's model (it stood between the camera and the NPC).
var _hid_player := false

func setup(for_npc: Node3D, explorer: Node3D) -> void:
	npc = for_npc
	player = explorer
	rest_position = npc.position
	marker_rest_y = InteractIcons.head_height(npc)

## Shows the "!" (through the NPC's Interactable) and hops while `calling`; otherwise puts the
## NPC back at rest.
func animate(delta: float, now_calling: bool) -> void:
	var item := Interactable.on(npc)
	if item != null:
		item.calling = now_calling
	if calling != now_calling:
		calling = now_calling
		if not now_calling:
			npc.position = rest_position
	if now_calling:
		_animation_time += delta
		var hop := absf(sin(_animation_time * HOP_SPEED)) * HOP_HEIGHT
		npc.position = rest_position + Vector3(0, hop, 0)

## Eases a camera in front of the NPC's face while it talks, and back to the player's
## camera afterwards. The player's own camera is never moved.
## Whether the talk camera is showing (or zooming in to) the face.
func is_zoomed() -> bool:
	return _previous_camera != null and is_instance_valid(_previous_camera)

func zoom_to_face(on: bool) -> void:
	if on == is_zoomed():
		return
	if _zoom_tween != null:
		_zoom_tween.kill()
	if on:
		_previous_camera = get_viewport().get_camera_3d()
		if _previous_camera == null:
			return
		if _talk_camera == null:
			_talk_camera = Camera3D.new()
			_talk_camera.name = "TalkCamera"
			_talk_camera.fov = FACE_FOV
			_talk_camera.near = 0.05
			_talk_camera.far = _previous_camera.far
			add_child(_talk_camera)
		_talk_camera.global_transform = _previous_camera.global_transform
		_talk_camera.make_current()
		var goal := face_transform()
		_hide_player_if_in_view(goal)
		_zoom_tween = create_tween()
		_zoom_tween.tween_method(func(t: float) -> void: _talk_camera.global_transform = _previous_camera.global_transform.interpolate_with(goal, t), 0.0, 1.0, ZOOM_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		var back := _previous_camera
		_previous_camera = null
		_show_player()
		if back == null or not is_instance_valid(back) or _talk_camera == null:
			return
		var from := _talk_camera.global_transform
		_zoom_tween = create_tween()
		_zoom_tween.tween_method(func(t: float) -> void: _talk_camera.global_transform = from.interpolate_with(back.global_transform, t), 0.0, 1.0, ZOOM_SECONDS * 0.75).set_trans(Tween.TRANS_SINE)
		# Only while the talk camera is still showing: a game camera that took over meanwhile
		# (the police detective games start right after the dialogue closes) keeps the view.
		_zoom_tween.tween_callback(func() -> void:
			if is_instance_valid(back) and _talk_camera.current:
				back.make_current())

## The point the talk camera frames: the NPC's face. Measured from the top of the NPC, so an
## NPC with a tall hat sets meta "talk_face_drop" (NPC-local units, the hat's height) to frame
## the face rather than the hat (Madame Luna, 10 Nov 2026).
func face_point() -> Vector3:
	var drop := float(npc.get_meta("talk_face_drop", 0.0))
	return npc.global_position + Vector3(0, maxf((marker_rest_y - drop) * npc.global_basis.get_scale().y - 0.45, 0.6) - 0.3, 0)

## In front of the NPC (turned a little towards the player), FACE_ELEVATION degrees above its
## face and looking down, with the face high on the screen so the dialogue box at the bottom
## does not cover it. Walls and furniture between the face and the camera move the camera
## round the NPC, or in closer (FACE_YAW_TRIES); the player's model is handled separately
## (_hide_player_if_in_view()). An NPC with meta "talk_camera_at" (a global point) is framed
## from there instead.
func face_transform() -> Transform3D:
	var face := face_point()
	# A caller-chosen camera spot (global; the tutorial's bathtub friend, 13 Nov 2026).
	if npc.has_meta("talk_camera_at"):
		return _looking_at_face(face, npc.get_meta("talk_camera_at"))
	var forward := -npc.global_basis.z
	forward.y = 0.0
	var to_player := player.global_position - npc.global_position
	to_player.y = 0.0
	var direction := forward.normalized() + (to_player.normalized() if to_player.length() > 0.1 else Vector3.ZERO) * 0.6
	if direction.length() < 0.1:
		direction = forward
	direction = direction.normalized()
	var lift := deg_to_rad(FACE_ELEVATION)
	var excluded := _bodies_of(npc) + _bodies_of(player)
	var best_eye := Vector3.ZERO
	var best_clear := -1.0
	for yaw in FACE_YAW_TRIES:
		var eye := face + (direction.rotated(Vector3.UP, deg_to_rad(yaw)) * cos(lift) + Vector3.UP * sin(lift)) * FACE_DISTANCE
		var clear := _clear_distance(face, eye, excluded)
		if clear >= FACE_DISTANCE:
			return _looking_at_face(face, eye)
		if clear > best_clear:
			best_clear = clear
			best_eye = eye
	# Blocked on every side: the clearest side, moved in front of the blocker.
	var distance := maxf(best_clear - 0.3, FACE_MIN_DISTANCE)
	return _looking_at_face(face, face + (best_eye - face).normalized() * distance)

## A camera at `eye` looking at `face`, tilted down further so the face sits FACE_SCREEN_Y of
## the way down the screen.
func _looking_at_face(face: Vector3, eye: Vector3) -> Transform3D:
	var basis := Basis.looking_at(face - eye, Vector3.UP)
	var tilt := atan((0.5 - FACE_SCREEN_Y) * 2.0 * tan(deg_to_rad(FACE_FOV) * 0.5))
	return Transform3D(Basis(basis.x, -tilt) * basis, eye)

## How far from the face the line to `eye` stays clear (FACE_DISTANCE when nothing is in the
## way). Two rays, from the face and from just under it, ignoring the NPC and the player.
func _clear_distance(face: Vector3, eye: Vector3, excluded: Array[RID]) -> float:
	if not npc.is_inside_tree():
		return FACE_DISTANCE
	var space := npc.get_world_3d().direct_space_state
	var clear := FACE_DISTANCE
	for start in [face, face - Vector3(0, 0.3, 0)]:
		var query := PhysicsRayQueryParameters3D.create(start, eye + (start - face))
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			clear = minf(clear, start.distance_to(hit.position))
	return clear

func _bodies_of(node: Node) -> Array[RID]:
	var rids: Array[RID] = []
	if node is CollisionObject3D:
		rids.append((node as CollisionObject3D).get_rid())
	for body in node.find_children("*", "CollisionObject3D", true, false):
		rids.append((body as CollisionObject3D).get_rid())
	return rids

## Hides the player's model while it would stand between the talk camera (at `view`) and the
## NPC: in front of the camera, nearer than the NPC and inside the picture. Shown again when
## the camera zooms back (_show_player()).
func _hide_player_if_in_view(view: Transform3D) -> void:
	var model = player.get("visual")
	if not model is Node3D or not (model as Node3D).visible:
		return
	var face_depth := -(view.basis.inverse() * (face_point() - view.origin)).z
	var aspect := 16.0 / 9.0
	if is_inside_tree():
		var screen := get_viewport().get_visible_rect().size
		aspect = screen.x / maxf(screen.y, 1.0)
	var half_v := tan(deg_to_rad(FACE_FOV) * 0.5)
	for height in [0.4, 1.2, 2.0]:
		var local := view.basis.inverse() * (player.global_position + Vector3(0, height, 0) - view.origin)
		var depth := -local.z
		if depth > 0.05 and depth < face_depth and absf(local.y / depth) < half_v * 1.1 and absf(local.x / depth) < half_v * aspect * 1.1:
			(model as Node3D).visible = false
			_hid_player = true
			return

func _show_player() -> void:
	if _hid_player:
		_hid_player = false
		var model = player.get("visual")
		if model is Node3D:
			(model as Node3D).visible = true
