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

## Optional settings for bigger or longer animals (big clay animals, 16 Nov 2026). Their defaults
## leave an animal without them (the pig) exactly as before.
## Per leg, degrees added to its angle while walking: a display standing mid-stride swings each
## leg about a more upright angle once it walks.
@export var leg_neutral_deg: PackedFloat32Array = []
## Per leg, the foot's ground contact point at rest (model space). When set, each leg bone is
## shortened or lengthened along its length (within `foot_stretch`) so the foot stays on the
## ground through the stance and lifts by `lift` in the swing, instead of sinking or floating as
## the leg swings about its pivot.
@export var feet: PackedVector3Array = []
@export var foot_stretch := Vector2(0.8, 1.12)
## Axis the tail wags about (model space; up suits the pig's curl, a hanging tail swings about a
## level axis). Bones after "tail" in `tail_chain` wag the same way, each `tail_lag` radians
## later than the one before, so a long tail waves.
@export var tail_axis := Vector3.UP
@export var tail_chain: PackedStringArray = []
@export var tail_lag := 0.7
## Axis the ears turn about, and seconds per slow ear fan (0: only the pig's flop in step).
@export var ear_axis := Vector3.FORWARD
@export var ear_fan_seconds := 0.0
## Neck bones from the body to the head. The look is shared out along them (`neck_share` of the
## turn on the neck, the rest on the head) and while walking the neck pumps `neck_pump_deg` per
## bone, twice a cycle.
@export var neck: PackedStringArray = []
@export var neck_share := 0.6
@export var neck_pump_deg := 0.0
## Trunk bones from the head to the tip: a slow sway from side to side (in step with the walk
## while walking) and a curl, degrees per bone, each bone a little behind the one before.
@export var trunk: PackedStringArray = []
@export var trunk_sway_deg := 0.0
@export var trunk_curl_deg := 0.0
@export var trunk_seconds := 3.2

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
	for name in ["body", "head", "tail", "ear_l", "ear_r"] + Array(legs) + Array(neck) + Array(trunk) + Array(tail_chain):
		var i := skeleton.find_bone(name)
		if i >= 0:
			_bones[name] = i
			_rest[name] = skeleton.get_bone_rest(i)
	_rng.seed = hash(str(root.get_path()))
	_clock = _rng.randf() * 100.0
	_next_look = _clock + _rng.randf_range(look_gap.x, look_gap.y)
	root.add_to_group(BLINK_GROUP)
	# Off screen the pose is not updated (no skinning work); it catches up when seen again.
	# Named and reused, so a baked town that saved it (base.gd pig_clay_walks) does not get two.
	_screen = root.get_node_or_null("OnScreen") as VisibleOnScreenNotifier3D
	if _screen == null:
		_screen = VisibleOnScreenNotifier3D.new()
		_screen.name = "OnScreen"
		root.add_child.call_deferred(_screen)
	_screen.aabb = AABB(Vector3(-0.6, 0, -0.9), Vector3(1.2, 1.2, 1.8)) if not root.has_meta("anim_aabb") else root.get_meta("anim_aabb")
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
		if k < leg_neutral_deg.size():
			angle += deg_to_rad(leg_neutral_deg[k]) * w
		if k < feet.size() and _bones.has(legs[k]):
			_plant(legs[k], feet[k], angle, lerpf(feet[k].y, up, w))
			continue
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
	var head_yaw := _yaw
	if not neck.is_empty():
		head_yaw = _yaw * (1.0 - neck_share)
		for k in neck.size():
			var pump := deg_to_rad(neck_pump_deg * sin(2.0 * cycle - 0.4 * k) * w + 0.4 * breathe * idle)
			_pose_bone(neck[k], Vector3.ZERO, Quaternion(Vector3.UP, _yaw * neck_share / neck.size()) * Quaternion(Vector3.RIGHT, pump))
	_pose_bone("head", Vector3.ZERO, Quaternion(Vector3.UP, head_yaw) * Quaternion(Vector3.FORWARD, -roll * 0.6 + head_yaw * 0.15) * Quaternion(Vector3.RIGHT, nod))
	for k in trunk.size():
		var late := 0.7 * k
		var side := trunk_sway_deg * (sin(TAU * _clock / trunk_seconds - late) * lerpf(1.0, 0.5, w) + sin(cycle - late) * w)
		var curl := trunk_curl_deg * sin(TAU * _clock / (trunk_seconds * 1.6) - late)
		_pose_bone(trunk[k], Vector3.ZERO, Quaternion(Vector3.FORWARD, deg_to_rad(side)) * Quaternion(Vector3.RIGHT, deg_to_rad(curl)))
	# Tail: a wag (faster when walking); ears flop a beat behind the bob.
	var wag := deg_to_rad(tail_deg * sin(_clock * lerpf(2.2, 9.0, w)) * lerpf(0.35, 1.0, w))
	var axis := tail_axis.normalized()
	_pose_bone("tail", Vector3.ZERO, Quaternion(axis, wag))
	for k in tail_chain.size():
		var wave := deg_to_rad(tail_deg * sin(_clock * lerpf(2.2, 9.0, w) - tail_lag * (k + 1)) * lerpf(0.35, 1.0, w))
		_pose_bone(tail_chain[k], Vector3.ZERO, Quaternion(axis, wave))
	var flop := deg_to_rad(ear_deg * (sin(2.0 * cycle - 1.2) * w + 0.25 * breathe * idle))
	if ear_fan_seconds > 0.0:
		flop = deg_to_rad(ear_deg * (sin(TAU * _clock / ear_fan_seconds) * lerpf(1.0, 0.6, w) + 0.5 * sin(2.0 * cycle - 1.2) * w))
	_pose_bone("ear_l", Vector3.ZERO, Quaternion(ear_axis, flop))
	_pose_bone("ear_r", Vector3.ZERO, Quaternion(ear_axis, -flop))


## A leg turned `angle` about its pivot and stretched along y so that its foot (rest contact
## point `foot`, model space) is at height `height`: R_x(angle) * scale_y(s) * (foot - pivot)
## reaches height - pivot.y.
func _plant(name: String, foot: Vector3, angle: float, height: float) -> void:
	var pivot := skeleton.get_bone_global_rest(_bones[name]).origin
	var f := foot - pivot
	var s := 1.0
	var down := f.y * cos(angle)
	if absf(down) > 1e-4:
		s = clampf((height - pivot.y + f.z * sin(angle)) / down, foot_stretch.x, foot_stretch.y)
	_pose_bone(name, Vector3.ZERO, Quaternion(Vector3.RIGHT, angle), Vector3(1.0, s, 1.0))
