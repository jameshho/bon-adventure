extends Node
## The one owner of a plush character's eyes and small signs of life (docs/guides/COMPONENTS.md
## #plush-characters). Every plush scene has the same parts ("Torso", "Head" = the face group,
## "Head/LeftEye", "Head/RightEye", "Arm", "Arm_2", "Foot", "Foot_2", "Tail"), so this works on
## any of them, the player's BonBon included.
##
## Three uses:
##   1. Blinking for a set of figures (a PlushLife node):
##          var life := PlushLife.new()
##          add_child(life)
##          life.setup([npc_a, npc_b], rng)
##      Each figure blinks every `blink_gap` seconds (random). With `gestures` on, one figure at
##      a time also makes a small move every `gesture_gap` seconds. A hidden or freed figure is
##      skipped; a figure whose eyes are held (below) does not blink; a figure whose
##      Interactable is `calling` (npc_presence.gd hops it) makes no gesture.
##   2. The town's blinker: Main makes one (`main.plush_life`, follow_group("figures")) that
##      blinks every plush in the "figures" group now and then (user, 13 Nov 2026: every NPC
##      blinks, not often). A figure in another PlushLife's set is left to that one.
##   3. Static helpers for anything else that moves a plush:
##          PlushLife.hold_eyes(figure, true)     # sleeping: shut until hold_eyes(figure, false)
##          PlushLife.set_eyes_open(figure, 0.4)  # a slow close (0 shut ... 1 open)
##          PlushLife.breath_scale(rest, breath)  # a sleeper's slow swell (breath -1 ... 1)
##          PlushLife.play(self, figure, "hop")   # one gesture, returns its Tween
##
## Ownership (do not write these from anywhere else): the eyes' transform belongs to this
## script; a sleeper holds them shut and blinking yields. Gestures move the whole figure (its
## position.y and rotation), never the "Head" node: that node is only the face (eyes, cheeks,
## snout, ears) and its origin is at the feet, so turning it slides the face off the body
## (renders: docs/evidence/plush-rig-20261113/gestures.png; the head moves of 9 Nov 2026 did this).
## Every move returns exactly to the pose it started from.

const Interactable := preload("res://scripts/core/interactable.gd")
const BLINK_GAP := Vector2(4.0, 10.0)
const BLINK_SECONDS := 0.13
const GESTURE_GAP := Vector2(10.0, 20.0)
## The town blinker's gap (user, 13 Nov 2026: "not so frequently").
const TOWN_BLINK_GAP := Vector2(6.0, 14.0)
const EYES := ["Head/LeftEye", "Head/RightEye"]
## How flat a shut eye is (its height against the open eye).
const SHUT := 0.15
## The moves a figure may make: a small hop, a shake of the body ("no"), a small bow ("yes")
## and a lean to one side.
const GESTURES := ["hop", "shake", "nod", "tilt"]
## Figures in a PlushLife's own set carry this meta, so the town blinker leaves them alone.
const OWNED_META := "plush_life_owned"
const HELD_META := "eyes_held"
const REST_META := "rest"
## Seconds between the town blinker's looks at its group for new figures.
const FOLLOW_SECONDS := 2.0
## A figure's running gesture Tween (play()); face_while() waits for it.
const GESTURE_META := "gesture_tween"
## A figure's Facing turner while it faces the player (face_while()).
const FACING_META := "facing_turner"
## Facing the player (ANIM-07, user decision D12, 25 Nov 2026): the largest turn from the
## figure's own facing (radians, about 75°), how fast the turn eases (1/s), the smallest turn
## worth making, and the room the turned figure needs in front (snout) and behind (tail), in
## metres, at FACE_RAY_HEIGHTS above its feet. A turn that would bring a wall or fixture closer
## than that (and closer than it already was) is made smaller, or skipped.
const FACE_MAX_TURN := 1.3
const FACE_RATE := 7.0
const FACE_MIN_TURN := 0.12
const FACE_ROOM_FRONT := 0.55
const FACE_ROOM_BACK := 0.45
const FACE_RAY_HEIGHTS := [0.35, 0.9]
## Metres beyond which the player has walked off and the figure turns back.
const FACE_MAX_DISTANCE := 5.0

## Seconds between one figure's blinks (min, max).
@export var blink_gap := BLINK_GAP
## Whether one figure at a time also makes a small move, and how often (min, max seconds).
@export var gestures := true
@export var gesture_gap := GESTURE_GAP

var figures: Array = []
var _rng: RandomNumberGenerator
var _time := 0.0
var _next_gesture := 0.0
var _blink_at: Dictionary = {}   # figure -> time of its next blink
var _shut: Dictionary = {}       # figure -> true while this node holds its eyes shut for a blink
var _busy: Dictionary = {}       # figure -> its gesture tween
var _group := ""
var _follow_in := 0.0

func setup(plushes: Array, rng: RandomNumberGenerator = null) -> void:
	name = "PlushLife"
	_use_rng(rng)
	set_figures(plushes)
	_next_gesture = _time + _rng.randf_range(gesture_gap.x * 0.5, gesture_gap.y)

## Replaces the set (a game that builds new figures each round). Figures no longer in it are
## released with their eyes open.
func set_figures(plushes: Array) -> void:
	for figure in figures:
		if is_instance_valid(figure) and not plushes.has(figure):
			_release(figure)
	figures = plushes.filter(func(node) -> bool: return node is Node3D and is_instance_valid(node))
	for figure in figures:
		figure.set_meta(OWNED_META, true)
		if not _blink_at.has(figure):
			_blink_at[figure] = _time + _rng.randf_range(1.0, blink_gap.y)

## The town blinker: blinks every plush in `group` (looked up again every FOLLOW_SECONDS, so
## figures made later join) that no other PlushLife owns. No gestures.
func follow_group(group: String, rng: RandomNumberGenerator = null) -> void:
	name = "PlushLife"
	_use_rng(rng)
	_group = group
	gestures = false
	_follow_in = 0.0

func _use_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()

func _exit_tree() -> void:
	for figure in figures:
		if is_instance_valid(figure):
			_release(figure)

func _release(figure: Node3D) -> void:
	if _shut.has(figure) and not eyes_held(figure):
		set_eyes_open(figure, 1.0)
	_shut.erase(figure)
	_blink_at.erase(figure)
	if _group == "":
		figure.remove_meta(OWNED_META)

func _follow() -> void:
	var found: Array = []
	for node in get_tree().get_nodes_in_group(_group):
		if node is Node3D and not node.has_meta(OWNED_META) and node.has_node(EYES[0]):
			found.append(node)
			if not _blink_at.has(node):
				_blink_at[node] = _time + _rng.randf_range(1.0, blink_gap.y)
	for figure in _blink_at.keys():
		if not found.has(figure):
			if is_instance_valid(figure) and _shut.has(figure) and not eyes_held(figure):
				set_eyes_open(figure, 1.0)
			_blink_at.erase(figure)
			_shut.erase(figure)
	figures = found

func _process(delta: float) -> void:
	_time += delta
	if _group != "":
		_follow_in -= delta
		if _follow_in <= 0.0:
			_follow_in = FOLLOW_SECONDS
			_follow()
	# Eyes are only written when a blink starts or ends: between blinks a figure costs one
	# comparison a frame.
	for figure in figures:
		var at: float = _blink_at.get(figure, INF)
		if _time < at:
			continue
		if not is_instance_valid(figure):
			continue
		if _shut.has(figure):
			if _time >= at + BLINK_SECONDS:
				_shut.erase(figure)
				if not eyes_held(figure):
					set_eyes_open(figure, 1.0)
				_blink_at[figure] = _time + _rng.randf_range(blink_gap.x, blink_gap.y)
		elif eyes_held(figure) or not figure.is_visible_in_tree():
			_blink_at[figure] = _time + _rng.randf_range(blink_gap.x, blink_gap.y)
		else:
			_shut[figure] = true
			set_eyes_open(figure, 0.0)
	if gestures and _time >= _next_gesture:
		_next_gesture = _time + _rng.randf_range(gesture_gap.x, gesture_gap.y)
		var ready: Array = figures.filter(func(f) -> bool: return is_instance_valid(f) and f.is_visible_in_tree() and not _busy.has(f) and not _calling(f) and not facing(f))
		if not ready.is_empty():
			gesture(ready[_rng.randi() % ready.size()], GESTURES[_rng.randi() % GESTURES.size()])

## An NPC hopping with its "!" (npc_presence.gd owns its position meanwhile).
static func _calling(figure: Node3D) -> bool:
	var item := Interactable.on(figure)
	return item != null and item.calling

## Blinks `figure` now (also for checks).
func blink(figure: Node3D) -> void:
	_blink_at[figure] = _time

## Makes `figure` do `kind` now ("hop", "shake", "nod", "tilt"); ignored while it is moving.
func gesture(figure: Node3D, kind: String) -> void:
	if not is_instance_valid(figure) or _busy.has(figure):
		return
	var tween := play(self, figure, kind, 1.0, 1.0 if _rng.randf() < 0.5 else -1.0)
	if tween == null:
		return
	_busy[figure] = tween
	tween.finished.connect(func() -> void: _busy.erase(figure))

## Whether `figure` is in the middle of a move (for checks).
func moving(figure: Node3D) -> bool:
	return _busy.has(figure)

# --- Shared helpers (static) ---------------------------------------------------------------------

## One gesture on any plush, as a Tween of `host`; null for an unknown kind. `strength` scales
## the size of the move, `side` (1 or -1) picks the side of a tilt. The whole figure moves:
##   hop    0.06 up and down;
##   shake  the body turns left and right ("no"; the lineup's wrong-answer shake);
##   nod    a small bow forward, twice ("yes");
##   tilt   a lean to one side, held a moment.
static func play(host: Node, figure: Node3D, kind: String, strength := 1.0, side := 1.0) -> Tween:
	if not kind in GESTURES or not is_instance_valid(figure):
		return null
	# Physics ticks (ANIM-01, 25 Nov 2026): the figure is physics-interpolated, so a move written
	# each rendered frame would stutter; written on ticks it is smoothed between them.
	var tween := host.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# face_while() waits for a running gesture (both turn the figure).
	figure.set_meta(GESTURE_META, tween)
	match kind:
		"hop":
			var y := figure.position.y
			tween.tween_property(figure, "position:y", y + 0.06 * strength, 0.12).set_trans(Tween.TRANS_SINE)
			tween.tween_property(figure, "position:y", y, 0.16).set_trans(Tween.TRANS_SINE)
		"shake":
			var yaw := figure.rotation.y
			for k in 4:
				tween.tween_property(figure, "rotation:y", yaw + (0.18 if k % 2 == 0 else -0.18) * strength, 0.08)
			tween.tween_property(figure, "rotation:y", yaw, 0.08)
		"nod":
			# A plush faces -Z: a negative turn about its X axis bows forward.
			var pitch := figure.rotation.x
			for dip in [0.09, 0.02, 0.07]:
				tween.tween_property(figure, "rotation:x", pitch - dip * strength, 0.16).set_trans(Tween.TRANS_SINE)
			tween.tween_property(figure, "rotation:x", pitch, 0.14).set_trans(Tween.TRANS_SINE)
		"tilt":
			var roll := figure.rotation.z
			tween.tween_property(figure, "rotation:z", roll + 0.09 * strength * side, 0.25).set_trans(Tween.TRANS_SINE)
			tween.tween_interval(0.6)
			tween.tween_property(figure, "rotation:z", roll, 0.3).set_trans(Tween.TRANS_SINE)
	return tween

## Facing the player while talking (ANIM-07, user decision D12, 25 Nov 2026: the whole figure
## turns by yaw, eased, and turns back afterwards; no other idle moves). `figure` turns toward
## `toward` (the player) while `keep` returns true and `toward` stays within FACE_MAX_DISTANCE,
## then eases back to the yaw it had. A Facing node under `host` does it on physics ticks and
## frees itself. Calling again while it faces just takes the new `keep`.
## Skipped (false): a seated, lying or napping figure (meta `seat_point` / `napping`, or not
## upright), shut eyes (asleep), or no room to turn (FACE_ROOM_*). A figure that is `calling`
## (npc_presence.gd hops it) or making a gesture is waited for: it turns once it stops.
## Only rotation.y of the figure is written, never "Head".
static func face_while(host: Node, figure: Node3D, toward: Node3D, keep: Callable) -> bool:
	if host == null or not is_instance_valid(figure) or not is_instance_valid(toward) or not figure.is_inside_tree():
		return false
	if bool(figure.get_meta("napping", false)) or figure.has_meta("seat_point") or eyes_held(figure):
		return false
	if figure.global_basis.y.normalized().dot(Vector3.UP) < 0.97:
		return false
	var turner = figure.get_meta(FACING_META) if figure.has_meta(FACING_META) else null
	if turner != null and is_instance_valid(turner):
		turner.toward = toward
		turner.keep = keep
		turner.returning = false
		return true
	turner = Facing.new()
	turner.name = "Facing"
	turner.figure = figure
	turner.toward = toward
	turner.keep = keep
	turner.wait = func() -> bool: return _calling(figure) or _gesturing(figure)
	turner.aim = func() -> float: return facing_yaw(figure, toward.global_position, [toward])
	host.add_child(turner)
	figure.set_meta(FACING_META, turner)
	return true

## Whether `figure` is turned toward the player now, or turning to or from it.
static func facing(figure: Node3D) -> bool:
	return is_instance_valid(figure) and figure.has_meta(FACING_META) and is_instance_valid(figure.get_meta(FACING_META))

static func _gesturing(figure: Node3D) -> bool:
	var tween = figure.get_meta(GESTURE_META) if figure.has_meta(GESTURE_META) else null
	return tween is Tween and (tween as Tween).is_valid() and (tween as Tween).is_running()

## The yaw (figure.rotation.y) that turns `figure` toward `point`, at most FACE_MAX_TURN from its
## yaw now and shortened until the turn keeps FACE_ROOM_FRONT / FACE_ROOM_BACK clear of walls
## and fixtures (or as clear as the figure stands now). NAN: no turn worth making.
## `ignore`: nodes whose bodies the room rays pass through (the player).
static func facing_yaw(figure: Node3D, point: Vector3, ignore: Array = []) -> float:
	var parent := figure.get_parent() as Node3D
	var local := (parent.to_local(point) if parent != null else point) - figure.position
	if Vector2(local.x, local.z).length() < 0.05:
		return NAN
	# A plush faces -Z.
	var now := figure.rotation.y
	var turn := clampf(angle_difference(now, atan2(-local.x, -local.z)), -FACE_MAX_TURN, FACE_MAX_TURN)
	if absf(turn) < FACE_MIN_TURN:
		return NAN
	var excluded: Array[RID] = []
	for node in [figure] + ignore:
		if node is CollisionObject3D:
			excluded.append((node as CollisionObject3D).get_rid())
		for body in (node as Node).find_children("*", "CollisionObject3D", true, false):
			excluded.append((body as CollisionObject3D).get_rid())
	var space := figure.get_world_3d().direct_space_state
	var forward := -figure.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var front_now := _room(space, figure.global_position, forward, FACE_ROOM_FRONT, excluded)
	var back_now := _room(space, figure.global_position, -forward, FACE_ROOM_BACK, excluded)
	# The whole sweep must keep its room (a tail swings through every angle on the way), so
	# step through it and stop at the last clear angle.
	var steps := maxi(int(ceil(absf(turn) / 0.2)), 1)
	var allowed := 0.0
	for i in range(1, steps + 1):
		var angle := turn * i / steps
		var ahead := forward.rotated(Vector3.UP, angle)
		if _room(space, figure.global_position, ahead, FACE_ROOM_FRONT, excluded) < minf(front_now, FACE_ROOM_FRONT) - 0.02:
			break
		if _room(space, figure.global_position, -ahead, FACE_ROOM_BACK, excluded) < minf(back_now, FACE_ROOM_BACK) - 0.02:
			break
		allowed = angle
	if absf(allowed) < FACE_MIN_TURN:
		return NAN
	return now + allowed

## How far (up to `reach` metres) the floor-level rays from `feet` along `direction` stay clear.
static func _room(space: PhysicsDirectSpaceState3D, feet: Vector3, direction: Vector3, reach: float, excluded: Array[RID]) -> float:
	var clear := reach
	for height: float in FACE_RAY_HEIGHTS:
		var start := feet + Vector3(0, height, 0)
		var query := PhysicsRayQueryParameters3D.create(start, start + direction * reach)
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			clear = minf(clear, start.distance_to(hit.position))
	return clear

## Turns one figure toward the player and back (face_while()). Runs on physics ticks, so the
## physics-interpolated figure turns smoothly; returns the figure to its yaw if freed midway.
class Facing extends Node:
	var figure: Node3D
	var toward: Node3D
	var keep: Callable
	## True while the figure may not turn yet (calling or in a gesture).
	var wait: Callable
	## The yaw to turn to, or NAN (facing_yaw()).
	var aim: Callable
	var returning := false
	var _started := false
	var _rest_yaw := 0.0
	var _goal_yaw := 0.0

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(figure):
			queue_free()
			return
		var hold := not returning and is_instance_valid(toward) and keep.is_valid() and bool(keep.call()) \
				and figure.global_position.distance_to(toward.global_position) <= FACE_MAX_DISTANCE
		if not _started:
			if not hold:
				_finish()
				return
			if bool(wait.call()):
				return
			_rest_yaw = figure.rotation.y
			_goal_yaw = float(aim.call())
			if is_nan(_goal_yaw):
				_finish()
				return
			_started = true
		if not hold:
			returning = true
		var goal := _rest_yaw if returning else _goal_yaw
		figure.rotation.y = lerp_angle(figure.rotation.y, goal, 1.0 - exp(-FACE_RATE * delta))
		if returning and absf(angle_difference(figure.rotation.y, _rest_yaw)) < 0.004:
			figure.rotation.y = _rest_yaw
			_finish()

	func _exit_tree() -> void:
		if _started and is_instance_valid(figure):
			figure.rotation.y = _rest_yaw
		_started = false
		_release()

	func _finish() -> void:
		_started = false
		_release()
		queue_free()

	func _release() -> void:
		if is_instance_valid(figure) and figure.has_meta(FACING_META) and figure.get_meta(FACING_META) == self:
			figure.remove_meta(FACING_META)

## How open `figure`'s eyes are: 1 open, 0 shut (a slit SHUT of the eye's height). The eye mesh
## is centred on its node (pig_sculpt.gd _put), so it is squashed in place.
static func set_eyes_open(figure: Node3D, open: float) -> void:
	var squash := lerpf(SHUT, 1.0, clampf(open, 0.0, 1.0))
	for path in EYES:
		var eye := figure.get_node_or_null(path) as Node3D
		if eye == null:
			continue
		if not eye.has_meta(REST_META):
			eye.set_meta(REST_META, eye.transform)
		var rest: Transform3D = eye.get_meta(REST_META)
		eye.transform = Transform3D(rest.basis * Basis.from_scale(Vector3(1.0, squash, 1.0)), rest.origin)

## Sleeping: `on` shuts the eyes and keeps them shut (no PlushLife blinks the figure) until
## hold_eyes(figure, false) opens them. For a slow close call set_eyes_open() each frame after
## hold_eyes(figure, true, false).
static func hold_eyes(figure: Node3D, on: bool, apply := true) -> void:
	if on:
		figure.set_meta(HELD_META, true)
	elif figure.has_meta(HELD_META):
		figure.remove_meta(HELD_META)
	if apply:
		set_eyes_open(figure, 0.0 if on else 1.0)

static func eyes_held(figure: Node3D) -> bool:
	return figure.has_meta(HELD_META)

## Whether `figure`'s eyes are shut now (for checks).
static func eyes_shut(figure: Node3D) -> bool:
	var eye := figure.get_node_or_null(EYES[0]) as Node3D
	return eye != null and eye.has_meta(REST_META) and eye.transform.basis.get_scale().y < (eye.get_meta(REST_META) as Transform3D).basis.get_scale().y * 0.5

## A sleeper's torso scale for `breath` in -1 ... 1: it swells in width and depth, not length.
static func breath_scale(rest: Vector3, breath: float) -> Vector3:
	return rest * Vector3(1.0 + 0.015 * breath, 1.0, 1.0 + 0.035 * breath)
