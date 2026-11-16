extends Node
## Signs of life for a rigged clay animal (clay_rig.gd): a walk cycle driven by how fast the
## animal really moves, idle breathing and weight shift, a gentle head turn, a wag of the tail
## and a little ear flop. Pilot: the clay pig (scenes/animals/pig_clay_rigged.scn, 16 Nov 2026).
## Record: docs/guides/ANIMAL_SYSTEM.md#clay-animal-animation-pilot-16-nov-2026.
##
## A child of the rig's root, beside "Skeleton3D". Per-species settings are the exported
## properties below (the build tool writes them into the scene). Bone names follow clay_rig.gd's
## spec: "body", "head", "tail", "ear_l", "ear_r" (each optional) and the bones in `legs`.
##
## Ownership: this node is the only writer of the skeleton's bone poses. It never touches the
## eyes: blinking belongs to plush_life.gd (the rig's root has "Head/LeftEye" and
## "Head/RightEye", and this node puts the root in group BLINK_GROUP, so one PlushLife set to
## follow_group(BLINK_GROUP) blinks every rigged animal). The root's position and rotation
## belong to the mover (park_animals.gd); this node only reads them.
##
## Speed: measured from the root's own movement each frame (so any mover works), in model units
## per second. When an ancestor is a park_animals.gd wanderer, the head also turns toward its
## walking target.

const BLINK_GROUP := "clay_animals"

## Leg bones and each one's phase in the cycle (0 ... 1). A trot: diagonal pairs together.
@export var legs: PackedStringArray = ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
@export var leg_phase: PackedFloat32Array = [0.0, 0.5, 0.5, 0.0]
## Distance from a leg's pivot to the ground (model units); with `swing_deg` it sets the stride.
@export var leg_length := 0.4
## Forward and back swing of a leg, degrees each way at full walk.
@export var swing_deg := 22.0
## Multiplies the stride the swing would give, so the feet do not slide (1 = rolling foot).
@export var stride_scale := 1.0
## How high a swinging leg lifts (model units).
@export var lift := 0.025
## Body: bob up and down twice a cycle, roll side to side once (degrees).
@export var bob := 0.012
@export var roll_deg := 2.5
## Idle: breathing (fraction of body width) and seconds per breath; slow weight shift (degrees).
@export var breath := 0.012
@export var breath_seconds := 2.6
@export var shift_deg := 1.6
## Head: largest turn (degrees), seconds between idle looks, nod while walking (degrees).
@export var head_turn_deg := 24.0
@export var look_gap := Vector2(2.5, 6.0)
@export var nod_deg := 3.0
## Tail wag and ear flop (degrees).
@export var tail_deg := 18.0
@export var ear_deg := 7.0
## Below this speed (model units / s) the animal counts as standing.
@export var still_speed := 0.05

var skeleton: Skeleton3D
## Smoothed speed (model units / s); set `speed_override` >= 0 to drive it by hand (captures).
var speed := 0.0
var speed_override := -1.0
## The walk cycle's phase (0 ... 1, wraps) and how much of the walk is showing (0 ... 1).
var phase := 0.0
var walk := 0.0
var _clock := 0.0
var _bones := {}
var _rest := {}
var _last := Vector3.INF
var _yaw := 0.0
var _yaw_goal := 0.0
var _look_until := 0.0
var _next_look := 0.0
var _wanderer: Node3D
var _rng := RandomNumberGenerator.new()
var _screen: VisibleOnScreenNotifier3D


func _ready() -> void:
	var root := get_parent() as Node3D
	skeleton = root.get_node("Skeleton3D") as Skeleton3D
	for name in ["body", "head", "tail", "ear_l", "ear_r"] + Array(legs):
		var i := skeleton.find_bone(name)
		if i >= 0:
			_bones[name] = i
			_rest[name] = skeleton.get_bone_rest(i)
	_rng.seed = hash(str(root.get_path()))
	_clock = _rng.randf() * 100.0
	_next_look = _clock + _rng.randf_range(look_gap.x, look_gap.y)
	root.add_to_group(BLINK_GROUP)
	# Off screen the pose is not updated (no skinning work); it catches up when seen again.
	_screen = VisibleOnScreenNotifier3D.new()
	_screen.aabb = AABB(Vector3(-0.6, 0, -0.9), Vector3(1.2, 1.2, 1.8)) if not root.has_meta("anim_aabb") else root.get_meta("anim_aabb")
	root.add_child.call_deferred(_screen)
	var up := root.get_parent()
	while up != null and _wanderer == null:
		if up is Node3D and up.get_script() != null and "target" in up and "state" in up:
			_wanderer = up
		up = up.get_parent()


func _process(delta: float) -> void:
	var root := get_parent() as Node3D
	if not root.is_visible_in_tree() or (_screen.is_inside_tree() and not _screen.is_on_screen()):
		_last = Vector3.INF
		return
	advance(minf(delta, 0.1))


## Turns the head `yaw_deg` (+ = the animal's left) for `seconds`, then lets idle looks resume.
func look(yaw_deg: float, seconds := 2.0) -> void:
	_yaw_goal = deg_to_rad(clampf(yaw_deg, -head_turn_deg, head_turn_deg))
	_look_until = _clock + seconds
	_next_look = _look_until + _rng.randf_range(look_gap.x, look_gap.y)


## One step of the animation (called by _process; captures call it by hand).
func advance(dt: float) -> void:
	_clock += dt
	var root := get_parent() as Node3D
	var measured := speed
	if speed_override >= 0.0:
		measured = speed_override
	elif dt > 0.0:
		var at := root.global_position
		if _last != Vector3.INF:
			var step := at - _last
			step.y = 0.0
			measured = step.length() / dt / maxf(root.global_basis.get_scale().x, 1e-4)
		_last = at
	speed = lerpf(speed, measured, 1.0 - exp(-dt * 8.0))
	walk = move_toward(walk, 1.0 if speed > still_speed else 0.0, dt * 3.0)
	var stride := TAU * leg_length * deg_to_rad(swing_deg) * stride_scale
	phase = fposmod(phase + speed * dt / maxf(stride, 1e-3), 1.0)
	if walk <= 0.0:
		phase = 0.0
	_choose_look()
	_yaw = lerp_angle(_yaw, _yaw_goal, 1.0 - exp(-dt * 4.0))
	_pose()


func _choose_look() -> void:
	if _wanderer != null and walk > 0.5 and str(_wanderer.get("state")) == "walking":
		# Look a little toward where the walk is going.
		var to: Vector3 = _wanderer.get("target") - _wanderer.position
		var world := (_wanderer.get_parent() as Node3D).global_basis * to
		var model := (get_parent() as Node3D).global_basis.inverse() * world
		# The model faces -Z: yaw toward the target, + to the animal's left.
		_yaw_goal = clampf(atan2(-model.x, -model.z), -deg_to_rad(head_turn_deg), deg_to_rad(head_turn_deg)) * 0.6
		return
	if _clock < _look_until:
		return
	if _clock >= _next_look:
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		look(side * _rng.randf_range(0.45, 1.0) * head_turn_deg, _rng.randf_range(1.2, 3.0))
	else:
		_yaw_goal = 0.0


func _pose_bone(name: String, offset: Vector3, rotation: Quaternion, scale := Vector3.ONE) -> void:
	if not _bones.has(name):
		return
	var i: int = _bones[name]
	var rest: Transform3D = _rest[name]
	skeleton.set_bone_pose_position(i, rest.origin + offset)
	skeleton.set_bone_pose_rotation(i, rest.basis.get_rotation_quaternion() * rotation)
	skeleton.set_bone_pose_scale(i, scale)


func _pose() -> void:
	var w := walk * walk * (3.0 - 2.0 * walk)        # smoothstep
	var cycle := TAU * phase
	var idle := 1.0 - w
	# Legs: swing about the side-to-side axis (+ = the foot forward, toward -Z); lift while swinging.
	for k in legs.size():
		var a := cycle + TAU * leg_phase[k]
		var angle := deg_to_rad(swing_deg) * sin(a) * w
		var up := lift * maxf(cos(a), 0.0) * w
		_pose_bone(legs[k], Vector3(0, up, 0), Quaternion(Vector3.RIGHT, angle))
	# Body: walking bob and roll; at rest a slow breath and a weight shift from side to side.
	var breathe := sin(TAU * _clock / breath_seconds)
	var sway := sin(TAU * _clock / (breath_seconds * 2.7))
	var bounce := bob * (0.5 - 0.5 * cos(2.0 * cycle)) * w
	var roll := deg_to_rad(roll_deg * sin(cycle) * w + shift_deg * sway * idle)
	var pitch := deg_to_rad(0.6 * breathe * idle)
	_pose_bone("body", Vector3(sin(roll) * 0.02, bounce + 0.003 * breathe * idle, 0),
			Quaternion(Vector3.FORWARD, roll) * Quaternion(Vector3.RIGHT, pitch),
			Vector3(1.0 + breath * breathe * idle, 1.0 + breath * 0.4 * breathe * idle, 1.0))
	# Head: the look (yaw, with a little tilt into the turn), a nod in step while walking, and a
	# small counter-roll so the face stays level while the body rolls.
	var nod := deg_to_rad(nod_deg * sin(2.0 * cycle + 0.6) * w)
	_pose_bone("head", Vector3.ZERO, Quaternion(Vector3.UP, _yaw) * Quaternion(Vector3.FORWARD, -roll * 0.6 + _yaw * 0.15) * Quaternion(Vector3.RIGHT, nod))
	# Tail: a wag (faster when walking); ears flop a beat behind the bob.
	var wag := deg_to_rad(tail_deg * sin(_clock * lerpf(2.2, 9.0, w)) * lerpf(0.35, 1.0, w))
	_pose_bone("tail", Vector3.ZERO, Quaternion(Vector3.UP, wag))
	var flop := deg_to_rad(ear_deg * (sin(2.0 * cycle - 1.2) * w + 0.25 * breathe * idle))
	_pose_bone("ear_l", Vector3.ZERO, Quaternion(Vector3.FORWARD, flop))
	_pose_bone("ear_r", Vector3.ZERO, Quaternion(Vector3.FORWARD, -flop))
