extends Node3D
## A door of the Mystery House: the mystery room's three and the endless hall's
## (scripts/buildings/mystery.gd builds them; the Mystery Doors minigame,
## scripts/learning/mystery_session.gd, plays them). This node
## is the door leaf's word root ("door"): E or a click calls use(), which hands the door to the
## session. Outside a game the session rattles it (locked). The leaf turns on its parent, the
## hinge, so open(), close() and rattle() only move the parent.
##
## Processing on purpose: render_culling.gd keeps a processing node and everything under it out
## of the static batches, so the session can recolour the leaf and swap its shape symbol.
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
const OPEN_ANGLE := 1.75
const SWING_SPEED := 2.6
const RATTLE_SECONDS := 0.55
## slam(): the right door shutting behind the player in the endless hall, faster than a swing.
const SLAM_SPEED := 4.2
const GROUP := "mystery_doors_session"
## Where reach is measured, in the leaf's local y (its origin is the middle of the 3 m box,
## so -0.5 is 1 m above the leaf's foot, before the house's scale).
const REACH_Y := -0.5

## For data/sounds.json bindings: opened and slammed play the room door sounds (25 Nov 2026);
## rattled has no sound yet.
signal opened
signal rattled
signal slammed

var _target := 0.0
var _angle := 0.0
var _rattle := 0.0
var _speed := SWING_SPEED
## 1: hinged on the left edge (seen from the front), -1: on the right (meta swing; mystery.gd
## step hinges_right). The leaf always opens away from the front.
var _swing := 1.0

func _ready() -> void:
	_swing = float(get_meta("swing", 1.0))
	set_process(true)
	# E, a click or a tap uses it (interaction system, 12 Nov 2026); the session decides.
	# The badge sits mid-leaf, but reach is measured at hand height: in the scaled house the
	# leaf's middle is about 2.8 m above the floor, past the controller's MAX_RISE, so the door
	# could only be used mid-jump (bug, 25 Nov 2026).
	var centre := InteractIcons.local_center(self)
	Interactable.attach(self, {
		"kind": Interactable.Kind.OPEN,
		"prompt_distance": 2.6,
		"badge_offset": centre,
		"on_point": func(_from: Vector3) -> Vector3: return to_global(Vector3(centre.x, REACH_Y, centre.z)),
	})

func use() -> void:
	var session := get_tree().get_first_node_in_group(GROUP)
	if session != null:
		session.door_used(self)

func open() -> void:
	_target = OPEN_ANGLE
	_speed = SWING_SPEED
	opened.emit()

func close() -> void:
	_target = 0.0
	_speed = SWING_SPEED

## Open at once (the door the player comes out of in the mystery room after the treasure).
func open_now() -> void:
	_target = OPEN_ANGLE
	_angle = OPEN_ANGLE
	_speed = SWING_SPEED
	_apply(_angle)

## Swings shut quickly (the door closing behind the player).
func slam() -> void:
	_target = 0.0
	_speed = SLAM_SPEED
	slammed.emit()

## Fully closed and not moving.
func is_shut() -> bool:
	return _angle == 0.0 and _target == 0.0

func shut_now() -> void:
	_target = 0.0
	_angle = 0.0
	_apply(0.0)

func is_open() -> bool:
	return _angle > 0.2

func rattle() -> void:
	_rattle = RATTLE_SECONDS
	rattled.emit()

func _process(delta: float) -> void:
	if is_equal_approx(_angle, _target) and _rattle <= 0.0:
		return
	_angle = move_toward(_angle, _target, delta * _speed)
	var wobble := 0.0
	if _rattle > 0.0:
		_rattle = maxf(_rattle - delta, 0.0)
		wobble = sin(_rattle * 46.0) * 0.045 * (_rattle / RATTLE_SECONDS)
	_apply(_angle + wobble)

func _apply(angle: float) -> void:
	var hinge := get_parent() as Node3D
	if hinge != null:
		hinge.rotation.y = angle * _swing
