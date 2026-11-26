extends CharacterBody3D

signal movement_mode_changed(sprinting: bool, hyper: bool)
signal infinite_jump_changed(enabled: bool)

@export_group("Movement")
## 14 Nov 2026 (user): 20% faster walking and running (were 6.0 and 10.0); Shift or the HUD's Run
## button (touch_controls.gd) toggles sprint_enabled.
@export var walk_speed := 7.2
@export var sprint_speed := 12.0
@export var hyper_speed := 28.0
@export var jump_speed := 8.3
@export var gravity := 22.0
@export_group("Consecutive jumps")
# Each press adds height, with diminishing gains approaching a safe speed ceiling.
@export_range(0.0, 1.0, 0.01) var jump_height_growth := 0.35
@export_range(1.0, 4.0, 0.05) var max_jump_height_multiplier := 3.0
@export var acceleration := 45.0
@export var deceleration := 60.0
@export var turn_response := 12.0
@export_group("Camera")
@export var mouse_sensitivity := 0.00225
@export var min_camera_distance := 3.0
@export var max_camera_distance := 14.0
@export var zoom_step := 0.8
@export var camera_response := 16.0
## Follow camera on foot (user, 14 Nov 2026; for young players): walking sideways turns the view
## that way at up to this many radians per second, so one stick or A / D alone steers and the
## view never has to be dragged. Walking toward the camera turns nothing (no flip).
@export var follow_turn_speed := 1.1
## Seconds the follow waits after the view was dragged, so it never fights the player's hand.
@export var follow_pause_seconds := 2.0
## Smallest spring-arm length change applied while the arm is blocked (see _physics_process).
const ARM_SETTLE := 0.08

@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var visual: Node3D = $Visual
@onready var effects: Node3D = $HyperEffects
var sprint_enabled := false
var hyper_enabled := false
var noclip_enabled := false
var controls_enabled := true
## The welcome tutorial's control steps (tutorial.gd "controls", 17 Nov 2026, user): while false,
## turning the view (look_by) or walking and jumping are ignored; the other controls stay as
## controls_enabled says. Both true outside the tutorial.
var look_allowed := true
var move_allowed := true
var orbiting := false
var orbit_cursor := Vector2.ZERO
var camera_yaw := 0.0
## The follow camera's switch (Settings "Camera follows me", GameSettings.follow_camera; Main
## sets it) and the time left of its pause after a drag.
var follow_camera := true
## Optional () -> float, 0 outdoors to 1 indoors (Main: day_night.gd `indoor`): rooms are small,
## so the follow turns at FOLLOW_INDOOR of its speed inside.
var follow_indoor: Callable
const FOLLOW_INDOOR := 0.55
## Chase camera turn rate (1/s at 8 m/s and above) behind a road vehicle's nose.
const CHASE_RATE := 2.2
var follow_pause := 0.0
## Left-button drag-look (desktop): armed by a press on the world, turns after this many pixels.
const LEFT_LOOK_PIXELS := 8.0
var left_look_armed := false
var left_look_travel := 0.0
var camera_pitch := -0.22
## Extra downward tilt of the view while flying high, added to camera_pitch (written by
## vehicle_controls.gd update_flight_view(), 23 Nov 2026), so the town stays in view.
var flight_tilt := 0.0
## Radians the view has been turned by hand (look_by(): a mouse or finger drag), never by the
## follow camera. Only grows; the welcome tutorial's "view" step waits for it (16 Nov 2026).
var look_turned := 0.0
var camera_distance := 6.5
var jump_queued := false
## I toggles midair jumping; when off, Space only jumps from the ground.
var infinite_jump_enabled: bool = Features.INFINITE_JUMP_AT_START
## Ladders: any Node3D in group "ladders" (meta ladder_height); its +Z points away from the wall.
## Optional meta ladder_exit "forward": the top step-off goes over the ladder instead of back.
const CLIMB_SPEED := 3.0
var ladder_node: Node3D
var ladder_near: Node3D
var ladder_launch := 0.0
var ladder_velocity := Vector3.ZERO
## Set when the ladder was taken from the top (walking into the hatch or S at its head): while the
## key or stick push that took it is still held, it means "down", so it cannot bounce the player
## straight back off the top (23 Nov 2026, user). Cleared once that push is let go.
var ladder_from_top := false
## After climbing down to the foot with that push still held: do not take the ladder again (and
## climb back up) until it is let go.
var ladder_wait_release := false
var consecutive_jumps := 0
var gait_phase := 0.0
var gait_weight := 0.0
## Metres of ground per radian of gait phase (animate_bonbon()): at walk_speed 7.2 m/s the old
## cadence was 11.8 rad/s, so 7.2 / 11.8. One full step cycle (TAU) covers about 3.8 m.
const GAIT_STRIDE := 0.61
## The fastest the gait phase may turn (rad/s), for hyper speed.
const GAIT_MAX_RATE := 22.0
## Arms up and feet tucked for a jump (0 rest ... 1 take-off). Eased since 25 Nov 2026 (P3-19;
## it used to snap to 1 on take-off and drop linearly on landing): take-off sets jump_kick, which
## fades over about half a second, and the pose eases toward the larger of the kick and the
## airborne hold, quickly going up (JUMP_POSE_RISE) and softer on the way down.
var jump_pose := 0.0
var jump_kick := 0.0
## BonBon's own blinker (bind_model()).
var blinker: Node
const JUMP_AIR_POSE := 0.55
const JUMP_KICK_FADE := 1.6
const JUMP_POSE_RISE := 16.0
const JUMP_POSE_SETTLE := 8.0
var riding_vehicle: DriveableVehicle
var saved_collision_layer := 1
var saved_collision_mask := 1
var saved_arm_mask := 1
var parts: Dictionary = {}
var rest_poses: Dictionary = {}
## Left-hand item holding (scripts/player/hand_hold.gd, docs/guides/HAND_HOLD.md): hand.hold(item),
## hand.release(), hand.held. animate_bonbon() poses the left arm ("Arm") for what it holds.
var hand: Node3D
var boarding_start := Transform3D.IDENTITY
## After leaving a vehicle the camera glides back to BonBon instead of snapping.
var camera_catch_up := 0.0
## A scripted walk (minigames, e.g. grammar_session.gd walking BonBon back to the start): world
## points she walks to in order at walk speed, whatever the keys say; each is dropped when she
## reaches it (XZ only). Empty: normal control. The caller locks controls and watches progress.
var auto_walk: Array[Vector3] = []
## Walking speed set from outside, or below 0 for the normal speeds (the Mystery Doors toad hops:
## mystery_session.gd sets it each frame, fast in the air and 0 on landing).
var speed_override := -1.0
const AUTO_WALK_REACH := 0.2
var seated := false
var sit_transition := false
var sit_blend := 0.0
var sit_tween: Tween
## Optional seated camera target (world); a playground swing sets it while carrying BonBon.
var seat_focus: Variant = null
## Lying in a bed (seating_controller.gd): the seated state with BonBon on her back, head
## toward the headboard, eyes shut and breathing slowly. lie_* are measured in _ready.
var lying := false
var lie_lift := 0.7
var lie_mid := 1.12
var sleep_parts: Dictionary = {}
## Characters and animals block BonBon on this physics layer (house_characters.gd).
const Rider := preload("res://scripts/player/motorcycle_rider.gd")
## Eyes and the sleeping breath are shared with every plush (docs/guides/COMPONENTS.md#plush-characters).
const PlushLife := preload("res://scripts/characters/plush_life.gd")
## Switched-off features (hyper speed; infinite jump at the start; README.md#hidden-features).
const Features := preload("res://scripts/core/features.gd")
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    spring_arm.add_excluded_object(get_rid())
    bind_model()
    add_to_group("player")
    collision_mask |= FIGURE_LAYER
    reset_camera()

## The animated parts and the lying measurements of the model in Visual/BonBon.
func bind_model() -> void:
    parts.clear()
    rest_poses.clear()
    for path in ["Arm", "Arm_2", "Foot", "Foot_2"]:
        var part: Node3D = $Visual/BonBon.get_node(path)
        parts[path] = part
        rest_poses[path] = part.transform
    sleep_parts.clear()
    if hand == null:
        hand = preload("res://scripts/player/hand_hold.gd").new()
        hand.setup(parts["Arm"], rest_poses["Arm"], visual)
    else:
        hand.rebind(parts["Arm"], rest_poses["Arm"])
    measure_lying()
    # BonBon blinks too (P3-19, 25 Nov 2026): her own PlushLife, no gestures (they would move the
    # player's model). She is not in "figures" (that group marks occupied seats). Lying holds her
    # eyes shut, so the blinker leaves them alone while she sleeps.
    if blinker == null:
        blinker = PlushLife.new()
        blinker.gestures = false
        add_child(blinker)
        blinker.setup([$Visual/BonBon])
    else:
        blinker.set_figures([$Visual/BonBon])

## A profile's avatar (PWA phase 3): another cast plush (data/npcs.json) replaces
## BonBon's model. Every plush has the same Arm / Arm_2 / Foot / Foot_2 parts and BonBon's size at
## scale 1. The new model keeps the node name "BonBon", so the code that poses, dresses, seats
## and rides the player (plush_costume.gd, motorcycle_rider.gd, bonbon_effects.gd) is unchanged.
func set_avatar(scene: PackedScene) -> void:
    var old: Node3D = $Visual/BonBon
    var model: Node3D = scene.instantiate()
    model.transform = old.transform
    # The hand socket rides on the old model's arm: keep it (bind_model() moves it over).
    if hand != null and hand.get_parent() != null:
        hand.get_parent().remove_child(hand)
    visual.remove_child(old)
    old.free()
    model.name = "BonBon"
    visual.add_child(model)
    # Like the player's own BonBon: the model is never studied or collided with.
    var area := model.get_node_or_null("StudyArea") as Area3D
    if area != null:
        area.collision_layer = 0
        area.monitoring = false
        area.monitorable = false
    bind_model()
    effects.collect_surfaces()

## BonBon's depth behind her origin (the lift when on her back) and her mid-height.
func measure_lying() -> void:
    var bonbon: Node3D = $Visual/BonBon
    var inverse := visual.global_transform.affine_inverse()
    var bounds := AABB()
    var first := true
    for mesh in bonbon.find_children("*", "MeshInstance3D", true, false):
        if mesh.mesh == null or "Tail" in str(bonbon.get_path_to(mesh)): continue
        var box: AABB = inverse * mesh.global_transform * mesh.get_aabb()
        bounds = box if first else bounds.merge(box)
        first = false
    if not first:
        lie_lift = bounds.end.z
        lie_mid = bounds.get_center().y
    for path in ["Torso", "Tail"]:
        var part: Node3D = bonbon.get_node_or_null(path)
        if part != null: sleep_parts[path] = [part, part.scale, part.visible]

## Origin for lying with the body centred on `center` (mattress top) and head along `head`.
func lie_origin(center: Vector3, head: Vector3) -> Vector3:
    return center - head * lie_mid + Vector3.UP * (lie_lift - 0.06)

func reset_camera() -> void:
    camera_rig.global_position = global_position + Vector3(0, 2.55, 0)
    camera_rig.rotation = Vector3(camera_pitch, camera_yaw, 0)
    effects.clear_trail()
    reset_physics_interpolation()

func set_controls_enabled(enabled: bool) -> void:
    controls_enabled = enabled
    if not enabled:
        release_orbit()
        jump_queued = false

func board_vehicle(vehicle: DriveableVehicle) -> void:
    if seated or riding_vehicle != null or vehicle == null:
        return
    riding_vehicle = vehicle
    saved_collision_layer = collision_layer
    saved_collision_mask = collision_mask
    saved_arm_mask = spring_arm.collision_mask
    boarding_start=visual.global_transform
    visual.visible = vehicle.fixed_wing or vehicle.boarding_progress<1
    effects.set_enabled(false)
    collision_layer = 0
    collision_mask = 0
    spring_arm.collision_mask = saved_arm_mask
    for rid in vehicle.collision_exceptions:
        spring_arm.add_excluded_object(rid)
    velocity = Vector3.ZERO
    jump_queued = false
    # Pose BonBon after the vehicle has moved this tick, so a visible rider never lags a frame.
    process_physics_priority = 10
    # The plane is the small one since 23 Nov 2026 (turboprop.gd SIZE): a closer chase view.
    camera_distance = 16.0 if vehicle.fixed_wing else (10.0 if vehicle.helicopter else 8.5)
    if vehicle.fixed_wing:
        camera_yaw=vehicle.global_basis.orthonormalized().get_euler().y
        camera_pitch=-.2
    release_orbit()

## Exit plays the boarding sequence backwards and ends standing at exit_point,
## facing away from the vehicle.
func begin_vehicle_exit(exit_point: Vector3) -> void:
    if riding_vehicle == null:
        return
    var away := exit_point - riding_vehicle.global_position
    away.y = 0
    if away.length_squared() > .0001:
        rotation.y = atan2(-away.x, -away.z)
    boarding_start = Transform3D(Basis(Vector3.UP, rotation.y), exit_point)
    visual.visible = true

func leave_vehicle(exit_point: Vector3) -> void:
    if riding_vehicle == null:
        return
    var camera_from := camera_rig.global_position
    for rid in riding_vehicle.collision_exceptions:
        spring_arm.remove_excluded_object(rid)
    riding_vehicle = null
    process_physics_priority = 0
    Rider.reset(self)
    jump_queued = false
    global_position = exit_point
    visual.visible = true
    visual.transform=Transform3D.IDENTITY
    for key in parts: parts[key].transform=rest_poses[key]
    effects.set_enabled(hyper_enabled)
    collision_layer = saved_collision_layer
    collision_mask = saved_collision_mask
    spring_arm.collision_mask = saved_arm_mask
    velocity = Vector3.ZERO
    consecutive_jumps = 0
    camera_distance = 6.5
    reset_camera()
    camera_rig.global_position = camera_from
    camera_catch_up = .9

func release_orbit() -> void:
    if orbiting:
        orbiting = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        get_viewport().warp_mouse(orbit_cursor)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        release_orbit()
        jump_queued = false

# Releases must be observed even when a UI control consumes the event.
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
        release_orbit()
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        left_look_armed = false
    if event.is_action_pressed("back"):
        release_orbit()

func _unhandled_input(event: InputEvent) -> void:
    if not controls_enabled:
        return
    if event is InputEventMouseButton:
        # Left button on the world (13 Nov 2026, user: laptop trackpads have no easy right
        # drag): the press still clicks (Main), and dragging past LEFT_LOOK_PIXELS turns the
        # view like the right button, with the cursor left visible. Touch has its own drag-look.
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
            left_look_armed = true
            left_look_travel = 0.0
        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            orbit_cursor = get_viewport().get_mouse_position()
            orbiting = true
            # In a browser a captured mouse is a pointer lock, and the browser then shows its
            # own "press Esc to show your cursor" banner on every orbit (user, 13 Nov 2026:
            # remove it). The web build only hides the cursor while the right button is held.
            Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
            zoom_by(-zoom_step if event.button_index == MOUSE_BUTTON_WHEEL_UP else zoom_step)
    elif event is InputEventMouseMotion and orbiting:
        look_by(event.relative)
    elif event is InputEventMouseMotion and left_look_armed and event.device != InputEvent.DEVICE_ID_EMULATION:
        left_look_travel += event.relative.length()
        if left_look_travel > LEFT_LOOK_PIXELS:
            look_by(event.relative)
    # InputMap actions (project.godot; PWA phase 2): touch controls fire the same ones
    # (InputEventAction, scripts/ui/touch_controls.gd).
    elif (event is InputEventKey or event is InputEventAction) and event.is_pressed() and not event.is_echo():
        if event.is_action_pressed("sprint"):
            if is_instance_valid(riding_vehicle) and (riding_vehicle.fixed_wing or riding_vehicle.helicopter): return
            sprint_enabled = not sprint_enabled
            movement_mode_changed.emit(sprint_enabled, hyper_enabled)
        elif event.is_action_pressed("debug_hyper") and Features.HYPER_SPEED:
            hyper_enabled = not hyper_enabled
            effects.set_enabled(hyper_enabled and not seated and not is_instance_valid(riding_vehicle))
            movement_mode_changed.emit(sprint_enabled, hyper_enabled)
        elif event.is_action_pressed("debug_infinite_jump"):
            infinite_jump_enabled = not infinite_jump_enabled
            infinite_jump_changed.emit(infinite_jump_enabled)
        elif event.is_action_pressed("jump"):
            if not seated and not is_instance_valid(riding_vehicle) and move_allowed:
                jump_queued = true

## Turns the camera by a pointer movement (right-mouse orbit, a touch drag: touch_controls.gd).
func look_by(relative: Vector2) -> void:
    if not look_allowed:
        return
    follow_pause = follow_pause_seconds
    look_turned += (absf(relative.x) + absf(relative.y)) * mouse_sensitivity
    camera_yaw -= relative.x * mouse_sensitivity
    camera_pitch = clampf(camera_pitch - relative.y * mouse_sensitivity, -1.15, 0.15)

## The follow camera: turns camera_yaw toward the side the player walks to. `direction` is the
## world walking direction (movement_direction(), length up to 1). Only the sideways share
## turns the view, fading to nothing as the walk points back at the camera; a scripted walk,
## a held drag and the pause after one leave the view alone.
func follow_view(direction: Vector3, delta: float) -> void:
    follow_pause = maxf(follow_pause - delta, 0.0)
    if not follow_camera or follow_pause > 0.0 or orbiting or not auto_walk.is_empty() or not controls_enabled:
        return
    var local := Basis(Vector3.UP, -camera_rig.rotation.y) * direction
    var rate := follow_turn_speed * lerpf(1.0, FOLLOW_INDOOR, clampf(float(follow_indoor.call()), 0.0, 1.0) if follow_indoor.is_valid() else 0.0)
    camera_yaw -= local.x * clampf(1.0 - local.z, 0.0, 1.0) * rate * delta

## Road vehicles (21 Nov 2026): once moving, the view eases round behind the nose (also while
## reversing), faster with speed, so a turn reads as a turn. A held drag and the pause after one
## leave the view alone, as on foot.
func chase_view(delta: float) -> void:
    follow_pause = maxf(follow_pause - delta, 0.0)
    if not follow_camera or follow_pause > 0.0 or orbiting or not controls_enabled or riding_vehicle.boarding_busy():
        return
    var forward := riding_vehicle.travel_forward()
    var speed := absf(riding_vehicle.current_speed)
    if speed < 1.0 or Vector2(forward.x, forward.z).length() < .1:
        return
    var heading := atan2(-forward.x, -forward.z)
    camera_yaw = lerp_angle(camera_yaw, heading, 1.0 - exp(-CHASE_RATE * clampf(speed / 8.0, 0.0, 1.0) * delta))

## Moves the camera nearer (negative) or farther (the wheel, a pinch: touch_controls.gd).
func zoom_by(step: float) -> void:
    camera_distance = clampf(camera_distance + step, min_camera_distance, 28.0 if is_instance_valid(riding_vehicle) and riding_vehicle.fixed_wing else max_camera_distance)

func toggle_noclip() -> void:
    if seated or is_instance_valid(riding_vehicle):
        return
    noclip_enabled = not noclip_enabled
    collision_layer = 0 if noclip_enabled else 1
    collision_mask = 0 if noclip_enabled else 1 | FIGURE_LAYER
    velocity = Vector3.ZERO
    consecutive_jumps = 0
    jump_queued = false

func movement_direction() -> Vector3:
    while not auto_walk.is_empty():
        var to := auto_walk[0] - global_position
        to.y = 0
        if to.length() < AUTO_WALK_REACH:
            auto_walk.pop_front()
            continue
        # Slow down into the last point so she stops on it instead of sliding past.
        return to.normalized() * (clampf(to.length() / 0.8, 0.35, 1.0) if auto_walk.size() == 1 else 1.0)
    if not controls_enabled or not move_allowed:
        return Vector3.ZERO
    var axis := Vector3(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        0,
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward"))
    # Keeps the strength of a touch stick (a small push walks slowly; 14 Nov 2026); keys are
    # 0 or 1, so they move at full speed in eight directions as before.
    return Basis(Vector3.UP, camera_rig.rotation.y) * axis.limit_length(1.0)

## W / S climb a ladder you are standing in front of; Space lets go and hops away from the wall.
## A push of the stick (or the move keys) toward the wall counts as W and away from it as S, so
## touch players can climb too. At the head of a ladder (standing on the floor beside the hatch),
## walking toward the ladder or holding S takes it from the top and climbs down.
## Returns true while clinging (velocity is then ladder_velocity).
func update_ladder(delta: float) -> bool:
    ladder_launch = maxf(ladder_launch - delta, 0.0)
    ladder_near = null
    if noclip_enabled or not controls_enabled or ladder_launch > 0.0:
        ladder_node = null
        ladder_from_top = false
        return false
    var keys_up := Input.is_action_pressed("climb_up")
    var keys_down := Input.is_action_pressed("climb_down")
    var found: Node3D = null
    var at_head := false
    for candidate in get_tree().get_nodes_in_group("ladders"):
        if not is_instance_valid(candidate) or not candidate.is_inside_tree(): continue
        var local: Vector3 = (candidate as Node3D).to_local(global_position)
        var rise := float(candidate.get_meta("ladder_height", 4.0))
        if absf(local.x) < .65 and local.z > -.3 and local.z < 1.2 and local.y > -.2 and local.y < rise + .05:
            found = candidate
            at_head = local.y > rise - .35
            break
        # The head: on the top floor, within a step of the hatch, in line with the ladder.
        if candidate.get_meta("ladder_exit", "") != "forward" and absf(local.x) < .65 and local.z > -.3 and local.z < 2.4 \
                and local.y > rise - .35 and local.y < rise + .6:
            found = candidate
            at_head = local.y > rise - .35
            break
    if found == null:
        ladder_node = null
        ladder_from_top = false
        return false
    ladder_near = found
    var out: Vector3 = found.global_basis.z.normalized()
    var push := _ladder_push(out)
    var up := keys_up or push > .5
    var down := keys_down or push < -.5
    if ladder_wait_release:
        if up: return false
        ladder_wait_release = false
    if ladder_node != found:
        if at_head and found.get_meta("ladder_exit", "") != "forward" and (down or up):
            # Taken from the top: whatever brought the player here means "climb down".
            ladder_from_top = true
        elif not up:
            return false
        ladder_node = found
    if ladder_from_top:
        if up and not keys_down and not down:
            down = true
            up = false
        elif not up and not down:
            ladder_from_top = false
    var local: Vector3 = found.to_local(global_position)
    var rise := float(found.get_meta("ladder_height", 4.0))
    if jump_queued:
        jump_queued = false
        velocity = out * 5.0 + Vector3.UP * 5.0
        ladder_node = null
        ladder_from_top = false
        ladder_launch = .3
        return false
    if down and is_on_floor() and local.y < .3:
        ladder_node = null
        ladder_wait_release = ladder_from_top and up_held(keys_up, push)
        ladder_from_top = false
        return false
    var climb := float(up) - float(down)
    if climb > 0.0 and local.y >= rise - .05:
        # Reached the top floor: step off onto it, clear of the hatch. A ladder with meta
        # ladder_exit "forward" stands in a loft notch instead and steps off over its top.
        var exit := -out if found.get_meta("ladder_exit", "") == "forward" else out
        velocity = exit * 3.8 + Vector3.UP * 4.5
        ladder_node = null
        ladder_launch = .5
        # The view turns to face the way she stepped off, so a W still held walks on away from
        # the hatch instead of back into it; and that held push does not take the ladder again.
        camera_yaw = atan2(-exit.x, -exit.z)
        ladder_wait_release = true
        return false
    # Near the head the body is centred on the hatch so it drops through without catching its sides.
    var side := 0.0 if local.y > rise - 1.2 else clampf(local.x, -.2, .2)
    var wanted: Vector3 = found.to_global(Vector3(side, local.y, .45))
    var pull := (wanted - global_position) * 12.0
    # From the head, slide over the hatch before dropping so the body clears the floor's edge.
    var flat_gap := Vector2(wanted.x - global_position.x, wanted.z - global_position.z).length()
    if climb < 0.0 and local.y > rise - 1.2 and flat_gap > .25:
        climb = 0.0
    ladder_velocity = Vector3(pull.x, climb * CLIMB_SPEED, pull.z)
    rotation.y = lerp_angle(rotation.y, atan2(out.x, out.z), 1.0 - exp(-12.0 * delta))
    return true

func up_held(keys_up: bool, push: float) -> bool:
    return keys_up or push > .5

## How hard the move input pushes toward the ladder's wall (+1) or away from it (-1).
func _ladder_push(out: Vector3) -> float:
    var axis := Vector3(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        0,
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward"))
    if axis.length_squared() < .04:
        return 0.0
    var direction := Basis(Vector3.UP, camera_rig.rotation.y) * axis.limit_length(1.0)
    var flat_out := Vector3(out.x, 0, out.z).normalized()
    return -direction.dot(flat_out)

func next_jump_speed() -> float:
    # Count one includes a first press after walking off a ledge.
    var extra_jumps := maxi(consecutive_jumps - 1, 0)
    var limit := maxf(max_jump_height_multiplier, 1.0)
    var height_multiplier := 1.0 + (limit - 1.0) * (1.0 - exp(-maxf(jump_height_growth, 0.0) * extra_jumps))
    # Ballistic height is proportional to speed squared, so tune actual height.
    return jump_speed * sqrt(height_multiplier)

func _physics_process(delta: float) -> void:
    if seated:
        velocity = Vector3.ZERO
        jump_queued = false
        animate_sitting()
        var blend := 1.0-exp(-camera_response*delta)
        var focus: Vector3 = seat_focus if seat_focus != null else global_position+Vector3(0,2.1,0)
        camera_rig.global_position = camera_rig.global_position.lerp(focus,blend)
        camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y,camera_yaw,blend)
        camera_rig.rotation.x = lerpf(camera_rig.rotation.x,camera_pitch,blend)
        spring_arm.spring_length = camera_distance
        return
    if is_instance_valid(riding_vehicle):
        global_position = riding_vehicle.global_position + Vector3.UP * (1.7 if riding_vehicle.helicopter else 1.15)
        velocity = Vector3.ZERO
        var camera_height := 3.2 if riding_vehicle.fixed_wing else (3.8 if riding_vehicle.helicopter else 2.75)
        if riding_vehicle.animated_boarding():
            animate_boarding(delta)
        if riding_vehicle.fixed_wing:
            if not orbiting:
                camera_yaw=lerp_angle(camera_yaw,riding_vehicle.global_basis.orthonormalized().get_euler().y,1-exp(-2*delta))
        elif not riding_vehicle.helicopter:
            chase_view(delta)
        camera_rig.global_position = camera_rig.global_position.lerp(riding_vehicle.global_position + Vector3.UP * camera_height, 1.0-exp(-5.0*delta))
        camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, camera_yaw, 1.0 - exp(-camera_response * delta))
        camera_rig.rotation.x = lerpf(camera_rig.rotation.x, clampf(camera_pitch - flight_tilt, -1.15, 0.15), 1.0 - exp(-camera_response * delta))
        spring_arm.spring_length = lerpf(spring_arm.spring_length, camera_distance, 1.0 - exp(-4.0 * delta))
        return
    if is_on_floor() or noclip_enabled:
        consecutive_jumps = 0
    var climbing := update_ladder(delta)
    var direction := movement_direction() if not climbing else Vector3.ZERO
    follow_view(direction, delta)
    var speed: float = walk_speed if not auto_walk.is_empty() else (hyper_speed if hyper_enabled else (sprint_speed if sprint_enabled else walk_speed))
    if speed_override >= 0.0:
        speed = speed_override
    var response: float = acceleration if direction.length_squared() > 0.001 else deceleration
    if ladder_launch <= 0.0:
        velocity.x = move_toward(velocity.x, direction.x * speed, response * delta)
        velocity.z = move_toward(velocity.z, direction.z * speed, response * delta)
    if noclip_enabled:
        var vertical := 0.0
        if controls_enabled:
            vertical = Input.get_action_strength("jump") - Input.get_action_strength("descend")
        velocity.y = vertical * speed
    elif jump_queued and (infinite_jump_enabled or is_on_floor()):
        # A new press resets upward velocity even at the apex or during a fall.
        consecutive_jumps += 1
        velocity.y = next_jump_speed()
        jump_kick = 1.0
    elif not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    jump_queued = false
    if climbing: velocity = ladder_velocity
    move_and_slide()
    if is_on_floor():
        consecutive_jumps = 0
    if direction.length_squared() > 0.001:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-turn_response * delta))
    # Independent world-space rig: turning BonBon cannot turn the camera.
    if camera_catch_up > 0.0:
        camera_catch_up = maxf(camera_catch_up - delta, 0.0)
        camera_rig.global_position = camera_rig.global_position.lerp(global_position + Vector3(0, 2.55, 0), 1.0 - exp(-7.0 * delta) if camera_catch_up > 0.0 else 1.0)
    else:
        camera_rig.global_position = global_position + Vector3(0, 2.55, 0)
    var blend := 1.0 - exp(-camera_response * delta)
    camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, camera_yaw, blend)
    camera_rig.rotation.x = lerpf(camera_rig.rotation.x, camera_pitch, blend)
    # Contract immediately on impact; ease back out when the obstruction clears. While the arm
    # rests against a wall, changes under ARM_SETTLE are skipped: its shape cast is only accurate
    # to about a 256th of its length, and feeding each result into the next cast's length made
    # the camera bounce ~2 cm every frame, so every edge shimmered (e.g. facing the control
    # tower's lift from its narrow lobby, user, 10 Nov 2026). The camera still sits at the hit.
    var hit := spring_arm.get_hit_length()
    var available := minf(spring_arm.spring_length, hit + 0.05)
    var wanted := lerpf(available, camera_distance, blend)
    if hit >= spring_arm.spring_length - 0.01 or absf(wanted - spring_arm.spring_length) > ARM_SETTLE:
        spring_arm.spring_length = wanted
    var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
    animate_bonbon(delta, actual_speed)
    effects.update_motion(delta, actual_speed / hyper_speed)

# Shared by the turboprop and road vehicles: walk to the door/step (t 0-.45), then
# climb into the seat (.45-1). Exits run t backwards from the seat to boarding_start.
func animate_boarding(delta: float) -> void:
    if riding_vehicle.has_rider():
        Rider.pose(self, delta)
        return
    var t:=riding_vehicle.boarding_progress
    var seat: Transform3D=riding_vehicle.boarding_seat()
    var step: Vector3=riding_vehicle.boarding_step_point()
    var center: Vector3=boarding_start.origin.lerp(step,smoothstep(0,.45,t)) if t<.45 else step.lerp(seat.origin,smoothstep(.45,1,t))
    center.y+=sin(t*PI)*.18
    var tuck: float=lerpf(1.0,riding_vehicle.boarding_seat_scale(),smoothstep(.45,1,t))
    # Face the door on arrival, then turn to the seat's forward direction.
    var door_facing:=Basis(riding_vehicle.global_basis.orthonormalized().get_rotation_quaternion())
    var facing: Quaternion=boarding_start.basis.get_rotation_quaternion().slerp(seat.basis.get_rotation_quaternion(),smoothstep(0,1,t))
    if not riding_vehicle.fixed_wing:
        facing=boarding_start.basis.get_rotation_quaternion().slerp(door_facing.get_rotation_quaternion(),smoothstep(0,.4,t)) if t<.45 else door_facing.get_rotation_quaternion().slerp(seat.basis.get_rotation_quaternion(),smoothstep(.45,.85,t))
    visual.global_transform=Transform3D(Basis(facing).scaled(Vector3.ONE*tuck),center)
    # Road cabins are smaller than BonBon: hidden once seated and the door shuts.
    visual.visible=riding_vehicle.fixed_wing or t<.9
    gait_phase+=delta*10
    for key in parts:
        var rest: Transform3D=rest_poses[key]
        var part: Node3D=parts[key]
        part.transform=rest
        var side: float=-1 if str(key).ends_with("_2") else 1
        if str(key).begins_with("Arm"):
            var turn:=Basis(Vector3.RIGHT,lerpf(sin(gait_phase)*side*.35,-.7,smoothstep(.4,1,t)))
            var pivot:=Vector3(-.65*side,1.22,0)
            part.transform=Transform3D(turn*rest.basis,rest.origin+pivot-turn*pivot)
        else:
            part.position+=Vector3(0,sin(gait_phase+side)*.12*(1-t)+.2*t,-.36*t)

func animate_bonbon(delta: float, speed: float) -> void:
    var grounded := is_on_floor() and not noclip_enabled
    gait_weight = lerpf(gait_weight, clampf(speed / sprint_speed, 0.0, 1.0) if grounded else 0.0, 1.0 - exp(-12.0 * delta))
    # The phase follows the ground covered (ANIM-03, 25 Nov 2026), so the feet never skate: a slow
    # stick push steps slowly, a sprint quickly. GAIT_STRIDE keeps walk_speed's cadence as it was
    # (7 + 8 * walk/sprint rad/s); GAIT_MAX_RATE stops hyper speed from blurring the feet.
    gait_phase += minf(speed / GAIT_STRIDE, GAIT_MAX_RATE) * delta
    jump_kick = move_toward(jump_kick, 0.0, delta * JUMP_KICK_FADE)
    var jump_goal := maxf(jump_kick, 0.0 if grounded else JUMP_AIR_POSE)
    jump_pose = lerpf(jump_pose, jump_goal, 1.0 - exp(-(JUMP_POSE_RISE if jump_goal > jump_pose else JUMP_POSE_SETTLE) * delta))
    visual.position.y = absf(sin(gait_phase)) * 0.055 * gait_weight
    for key in parts:
        var part: Node3D = parts[key]
        var rest: Transform3D = rest_poses[key]
        var side := -1.0 if str(key).ends_with("_2") else 1.0
        var swing := sin(gait_phase) * side * gait_weight
        if str(key).begins_with("Arm"):
            var pivot := Vector3(-0.65 * side, 1.22, 0)
            var turn := Basis(Vector3.RIGHT, swing * 0.42 - jump_pose * 0.55)
            if key == "Arm" and hand.is_holding():
                # Holding (hand_hold.gd): a little forward and out, a smaller swing, less lift
                # when jumping, so the item moves with the arm but stays calm.
                var hold: Vector3 = hand.arm_pose()
                turn = Basis(Vector3.RIGHT, swing * 0.42 * hold.y - jump_pose * 0.25 + hold.x) * Basis(Vector3.BACK, -hold.z)
            part.transform = Transform3D(turn * rest.basis, rest.origin + pivot - turn * pivot)
        else:
            part.transform = rest
            part.position += Vector3(0, maxf(0, swing) * 0.12 + jump_pose * 0.06, swing * 0.16)

# Procedural mesh-part pose: BonBon has no humanoid skeleton to retarget.
## With lie true (a bed) `facing` points toward the feet and the pose is lying on the back.
func begin_sitting(point: Vector3, facing: float, lie := false) -> void:
    if seated or is_instance_valid(riding_vehicle) or noclip_enabled: return
    seated = true
    lying = lie
    if lying and sleep_parts.has("Tail"): sleep_parts["Tail"][0].visible = false
    if lying: PlushLife.hold_eyes($Visual/BonBon, true, false)
    sit_transition = true
    saved_collision_layer = collision_layer
    saved_collision_mask = collision_mask
    collision_layer = 0
    collision_mask = 0
    velocity = Vector3.ZERO
    jump_queued = false
    effects.set_enabled(false)
    if sit_tween: sit_tween.kill()
    sit_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel(true)
    sit_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    sit_tween.tween_property(self,"global_position",point,0.55)
    sit_tween.tween_property(self,"rotation:y",rotation.y+angle_difference(rotation.y,facing),0.4)
    sit_tween.tween_property(self,"sit_blend",1.0,0.55)
    sit_tween.chain().tween_callback(func(): sit_transition = false)

func animate_sitting() -> void:
    visual.position = Vector3.ZERO
    if lying:
        animate_lying()
        return
    visual.rotation.x = 0.08*sit_blend
    for key in parts:
        var rest: Transform3D = rest_poses[key]
        var part: Node3D = parts[key]
        part.transform = rest
        if str(key).begins_with("Arm"):
            var side := -1.0 if str(key).ends_with("_2") else 1.0
            var pivot := Vector3(-0.65*side,1.22,0)
            var turn := Basis(Vector3.RIGHT,-0.55*sit_blend)
            part.transform = Transform3D(turn*rest.basis,rest.origin+pivot-turn*pivot)
        else:
            part.position += Vector3(0,0.35,-0.55)*sit_blend
            part.rotation.x -= 0.35*sit_blend

# On her back (visual turned about X: her up axis points to the head end, her face to the
# sky), paws resting, eyes closing to slits and a slow breath that swells the body.
func animate_lying() -> void:
    visual.rotation.x = PI * 0.5 * sit_blend
    for key in parts: parts[key].transform = rest_poses[key]
    var breath := sin(Time.get_ticks_msec() * 0.0017) * sit_blend
    if sleep_parts.has("Torso"): sleep_parts["Torso"][0].scale = PlushLife.breath_scale(sleep_parts["Torso"][1], breath)
    PlushLife.set_eyes_open($Visual/BonBon, 1.0 - sit_blend)

func end_sitting(point: Vector3) -> void:
    if not seated or sit_transition: return
    sit_transition = true
    if sit_tween: sit_tween.kill()
    sit_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel(true)
    sit_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    sit_tween.tween_property(self,"global_position",point,0.45)
    sit_tween.tween_property(self,"sit_blend",0.0,0.45)
    sit_tween.chain().tween_callback(finish_standing)

func finish_standing() -> void:
    seated = false
    seat_focus = null
    sit_transition = false
    sit_blend = 0
    collision_layer = saved_collision_layer
    collision_mask = saved_collision_mask
    visual.transform = Transform3D.IDENTITY
    for key in parts: parts[key].transform = rest_poses[key]
    if lying:
        lying = false
        PlushLife.hold_eyes($Visual/BonBon, false)
        for path in sleep_parts:
            sleep_parts[path][0].scale = sleep_parts[path][1]
            sleep_parts[path][0].visible = sleep_parts[path][2]
    velocity = Vector3.ZERO
    consecutive_jumps = 0
    jump_pose = 0
    jump_kick = 0
    gait_weight = 0
    effects.set_enabled(hyper_enabled)
