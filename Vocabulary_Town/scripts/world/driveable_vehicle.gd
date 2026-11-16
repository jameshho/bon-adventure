extends Node3D
class_name DriveableVehicle
const UiText := preload("res://scripts/language/ui_text.gd")
## Shared vehicle contract, road handling, swept collisions and helicopter visuals.
## Rotor force integration lives in helicopter_physics.gd; turboprop extends this contract.
## Boarding/exit animation (walk to the door, open it, climb in) is shared with the
## turboprop: progress runs 0 -> 1 to board and 1 -> 0 to get out.

signal exit_finished(vehicle, point: Vector3)
## The plane flew past the edge of the map (turboprop.gd; vehicle_controls.gd shows vehicle.map_edge).
signal map_edge_reached(vehicle)

@export var helicopter := false
var fixed_wing := false
## Easy flying (user, 14 Nov 2026), on by default for the helicopter and the turboprop; C in the
## cockpit switches to the expert controls and back (not saved). Easy: the helicopter hovers in
## place whenever the stick is let go (the R hover assist); the turboprop flies itself
## (turboprop.gd easy_inputs()). The "descend" action (Ctrl, the touch ▼ button) also lowers
## the helicopter in both modes. docs/guides/aircraft.md#easy-flying.
static var easy_flying := true
var boarding_progress := 1.0
## Exit while moving (user, 14 Nov 2026): E works at any speed, also in the air. A moving vehicle
## lets BonBon out beside it at once (no door sequence) and then coasts with no input: cars and
## motorcycles roll to a stop, the helicopter's rotor spins down, the plane glides unpowered.
## Physics runs only while `coasting`; once settled the vehicle is parked again (no cost).
var coasting := false
var settle_clock := 0.0
## Speed (m/s) under which a vehicle counts as stopped (exit with the door sequence, parking).
const STOPPED_SPEED := .6
## Seconds a coasting vehicle must stay still before it is parked again.
const SETTLE_TIME := .4
## Reset (user, 14 Nov 2026): the helicopter and the plane go back to where they started after a
## crash (EASY_RECOVER seconds later) or when left more than AIRCRAFT_RESET_DISTANCE from the
## player (vehicle_controls.gd); reset_to_start() is also the plane's red HUD Reset button.
## Cars stay where they stop (their airborne R recover is unchanged).
var crashed := false
var crash_clock := 0.0
const EASY_RECOVER := 2.5
const AIRCRAFT_RESET_DISTANCE := 300.0
## Helicopter: hitting something, or touching down, faster than this (m/s along the blocked axis)
## is a crash. Holding "down" in easy flying lands at about 7 m/s, which stays a landing.
const HELI_CRASH_SPEED := 10.0
## Pose in the parent's space when the town loaded: where reset_to_start() puts the vehicle.
var start_transform := Transform3D.IDENTITY
var exiting := false
var exit_point := Vector3.ZERO
## Seconds for the full walk-to-door, door and seat sequence (exit plays it in reverse).
@export_range(0.5, 5.0) var boarding_duration := 1.8
## 0 uses the vehicle-type top speed in road_vehicle_physics.gd PROFILES.
@export_range(0.0, 45.0) var top_speed := 0.0
@export_range(0.1, 4.0) var steering_rate := 1.55
@export_range(1.0, 15.0) var lift_speed := 7.0
@export_group("Road handling")
## Throttle build-up per second; releasing the pedal is twice as fast.
@export_range(0.5, 10.0) var throttle_response := 3.0
@export_range(2.0, 15.0) var brake_deceleration := 8.5
## Brake pressure build-up per second, so braking bites smoothly instead of instantly.
@export_range(1.0, 20.0) var brake_response := 6.0
@export_range(0.0, 3.0) var coast_deceleration := .8
@export_range(1.0, 15.0) var reverse_speed := 6.5
@export_range(.2, 1.0) var reverse_power := .6
## Steering wheel speed toward the input at rest (rad/s) and the return-to-centre speed.
@export_range(.5, 8.0) var steering_speed := 3.8
@export_range(.5, 10.0) var steering_return := 5.5
## Speed (m/s) at which the steering lock is halved.
@export_range(4.0, 40.0) var steering_falloff_speed := 13.0
## Lateral acceleration the steering lock is limited to at speed (m/s^2).
@export_range(2.0, 12.0) var max_lateral_acceleration := 8.0
## Extra yaw damping per m/s, which keeps fast driving from fishtailing.
@export_range(0.0, .2) var high_speed_yaw_damping := .05
@export_group("Helicopter attitude")
@export_range(0.0, 30.0) var maximum_pitch_degrees := 20.0
@export_range(0.0, 35.0) var maximum_bank_degrees := 24.0
@export_range(1.0, 8.0) var attitude_response := 3.6
@export_group("Helicopter inertia")
@export_range(0.1, 2.0) var coasting_drag := 0.38
@export_range(0.0, 2.0) var wind_strength := 0.65
var wind_clock := 0.0
var yaw_velocity := 0.0
var hover_assist := false
var rotor_power := 0.0
var rotor_angle := 0.0
var tail_rotor_angle := 0.0
var main_rotor: Node3D
var tail_rotor: Node3D
var rotor_blur: MeshInstance3D
var main_rotor_rest := Basis.IDENTITY
var tail_rotor_rest := Basis.IDENTITY
var flight_velocity := Vector3.ZERO
var landed := false
var flight_hulls: Array[Dictionary] = []
var occupied := false
var current_speed := 0.0
var original_world_y := 0.0
var collision_exceptions: Array[RID] = []
var helicopter_physics
var road_physics
var driver_door: Node3D
var vehicle_doors: Array[Node3D] = []
const VehicleDoors = preload("res://scripts/world/vehicle_doors.gd")
## Open-seat rider (the scooter, 9 Nov 2026): a RiderMount marker in the model means BonBon stays
## visible and rides it (scripts/player/motorcycle_rider.gd). The visible parts lean into turns
## and the FrontFork turns with the steering; collision and physics stay upright.
var rider_mount: Marker3D
var lean := 0.0
var applied_lean := 0.0
var longitudinal_accel := 0.0
var previous_speed := 0.0
var fork: Node3D
var fork_rest := Transform3D.IDENTITY
## Share of the front-wheel steering angle shown on the bars (they sit far behind the axis).
const BAR_STEER := .45
## Most the bars visibly turn (rad): tighter lean turns (9 Nov 2026) would pull the rider's paws off the grips.
const BAR_TURN_MAX := .06
const MAX_LEAN := .42

func has_rider() -> bool:
    return rider_mount != null

func animated_boarding() -> bool:
    return road_physics!=null or helicopter

func begin_boarding() -> void:
    exiting=false
    coasting=false
    if animated_boarding(): boarding_progress=0

func begin_exit(point: Vector3) -> void:
    exiting=true
    exit_point=point

## Advances boarding (or the reversed exit). True while the sequence still runs,
## so the caller holds the vehicle still.
func advance_boarding(dt: float) -> bool:
    if exiting:
        boarding_progress=maxf(0,boarding_progress-dt/boarding_duration)
        if boarding_progress<=0:
            exiting=false
            exit_finished.emit(self,exit_point)
        return true
    if boarding_progress<1:
        boarding_progress=minf(1,boarding_progress+dt/boarding_duration)
        return true
    return false

func boarding_busy() -> bool:
    return exiting or boarding_progress<1

func finish_exit() -> void:
    exiting=false
    boarding_progress=1
    update_driver_door()
    # Left moving: keep the momentum and coast. The helicopter also coasts while its rotor spins down.
    coasting=is_moving() or helicopter
    settle_clock=0
    if road_physics!=null and not coasting:
        park_road_vehicle()

## Road vehicles at rest: authored wheel poses, no lean, no stored motion.
func park_road_vehicle() -> void:
    if road_physics!=null:
        set_lean_applied(0)
        road_physics.reset()
        current_speed=0
        lean=0
        longitudinal_accel=0
        previous_speed=0
        if fork: fork.transform=fork_rest

# Explicit model profiles replace collision-box guesses. Geometry is prepared once.
func door_spec() -> Dictionary:
    return VehicleDoors.spec(self)

func build_driver_door() -> void:
    vehicle_doors = VehicleDoors.install(self)
    if not vehicle_doors.is_empty(): driver_door = vehicle_doors[0]
    update_driver_door()

## Door opens while walking up, stays open while climbing in, closes once seated.
func door_open_amount() -> float:
    return VehicleDoors.Door.boarding_amount(boarding_progress)

func update_driver_door() -> void:
    for door in vehicle_doors:
        door.set_open_amount(door_open_amount())

func boarding_step_point() -> Vector3:
    if has_node("MountStep"): return (get_node("MountStep") as Node3D).global_position
    if helicopter: return to_global(Vector3(-2.05,0,-.95))
    var spec:=door_spec()
    return to_global(Vector3(spec.hinge+spec.length*.55,0,spec.side+signf(spec.side)*1.05))

func boarding_seat() -> Transform3D:
    if has_rider(): return Transform3D(rider_mount.global_basis.orthonormalized()*Basis(Vector3.UP,PI/2),rider_mount.global_position)
    if helicopter: return Transform3D(global_basis.orthonormalized(),to_global(Vector3(-.42,1.0,-.95)))
    var spec:=door_spec()
    var seat:=Transform3D(global_basis.orthonormalized()*Basis(Vector3.UP,PI/2),to_global(Vector3(spec.hinge+spec.length*.6,spec.bottom,spec.side*.4)))
    return seat

## BonBon is larger than a car cabin; she tucks in as she climbs aboard.
func boarding_seat_scale() -> float:
    return rider_mount.get_meta("rider_scale",1.0) if has_rider() else .5

## Points where the walking capsule may stand to begin the walk (driver door first).
func preferred_exit_points() -> Array[Vector3]:
    var points: Array[Vector3]=[]
    if animated_boarding(): points.append(boarding_step_point())
    return points

func flight_status() -> String:
    if animated_boarding() and boarding_busy():
        return UiText.t("vehicle.getting_out" if exiting else "vehicle.getting_in")
    if helicopter:
        if crashed: return UiText.t("vehicle.status_heli_crash")
        if easy_flying: return UiText.t("vehicle.status_heli_easy",{"rotor":int(rotor_power*100)})
        return UiText.t("vehicle.status_heli",{"rotor":int(rotor_power*100),"collective":int(rad_to_deg(helicopter_physics.collective))})+"  ·  "+UiText.t("vehicle.to_easy")
    if road_physics!=null:
        return UiText.t("vehicle.status_drive",{"speed":int(absf(current_speed)*3.6),"gear":"R" if road_physics.gear<0 else "D"})
    return ""

func _ready() -> void:
    set_meta("driveable_vehicle", true)
    add_to_group("driveable_vehicles")
    if helicopter:
        set_meta("word_key", "helicopter")
    original_world_y = global_position.y
    start_transform = transform
    if helicopter:
        helicopter_physics=preload("res://scripts/world/helicopter_physics.gd").new()
        prepare_rotors()
        build_flight_hulls()
    # Self-geometry should never prevent its own motion probes.
    for descendant in find_children("*", "CollisionObject3D", true, false):
        if descendant is CollisionObject3D:
            collision_exceptions.append((descendant as CollisionObject3D).get_rid())
    rider_mount=get_node_or_null("RiderMount") as Marker3D
    fork=get_node_or_null("FrontFork") as Node3D
    if fork: fork_rest=fork.transform
    if not helicopter and not fixed_wing:
        road_physics=preload("res://scripts/world/road_vehicle_physics.gd").new()
        road_physics.configure(self)
        if has_rider(): add_rider_hull()
    if not fixed_wing: build_driver_door()

func travel_forward() -> Vector3:
    # Road vehicle bodies point along local -X; helicopter points along local -Z.
    var direction := -global_transform.basis.z if helicopter else -global_transform.basis.x
    # Collective lift is controlled separately: pitching must not turn W into descent.
    if helicopter: direction.y = 0.0
    return direction.normalized()

func entrance_distance(position_in_world: Vector3) -> float:
    var delta := position_in_world - global_position
    # Measure to the cockpit/cabin, not the vehicle's ground-level origin.
    delta.y -= (1.5 if helicopter else 0.9) * global_transform.basis.y.y
    if not animated_boarding():
        return delta.length()
    # Standing at the driver door picks this car, even in a gap beside another one.
    var door := position_in_world - boarding_step_point()
    door.y = maxf(0.0, absf(door.y) - 1.2)
    return minf(delta.length(), door.length())

## Physics only runs for the driven vehicle, one left coasting, a crashed aircraft or a boarding
## sequence; parked vehicles return at once.
func needs_physics() -> bool:
    return occupied or coasting or crashed or boarding_busy()

func _physics_process(delta: float) -> void:
    if not needs_physics(): return
    if not occupied:
        # Nobody at the controls: no input.
        drive_step(delta, 0.0, 0.0, 0.0, false)
        return
    # Move and jump actions (W A S D, Space; the touch joystick and Jump button, PWA phase 5).
    var gas := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
    var steering := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var lift := Input.get_action_strength("jump") - (maxf(float(Input.is_physical_key_pressed(KEY_SHIFT)), Input.get_action_strength("descend")) if helicopter else 0.0)
    var hover := Input.is_physical_key_pressed(KEY_R)
    # Easy flying: let go of the stick and the helicopter brakes to a hover.
    if helicopter and easy_flying and absf(gas) < .05 and absf(steering) < .05: hover = true
    drive_step(delta, gas, steering, lift, hover)

func is_aircraft() -> bool:
    return helicopter or fixed_wing

func _unhandled_input(event: InputEvent) -> void:
    if occupied and is_aircraft() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_C:
        easy_flying=not easy_flying

func drive_step(delta: float, gas: float, steering: float, lift: float, stabilize: bool = false) -> void:
    if helicopter:
        if advance_boarding(clampf(delta,0,.25)):
            update_driver_door()
            return
        if crashed:
            crash_clock+=delta
            if crash_clock>EASY_RECOVER: reset_to_start()
            return
        flight_step(delta, gas, steering, lift, stabilize)
        if crashed: return
        if global_position.y<original_world_y-60: crash()
        # Coasting ends once landed with the rotor stopped.
        elif coasting: settle(delta,landed and rotor_power<=0.0)
        return
    if road_physics==null: return
    if advance_boarding(clampf(delta,0,.25)):
        update_driver_door()
        return
    if has_rider():
        # Physics and wheel animation work in the upright frame; the lean is put back afterwards.
        set_lean_applied(0)
        road_physics.step(self,delta,gas,steering,lift>0,stabilize)
        update_rider_visuals(delta)
    else:
        road_physics.step(self,delta,gas,steering,lift>0,stabilize)
    if coasting and not occupied:
        var planar:=Vector2(road_physics.velocity.x,road_physics.velocity.z).length()
        # Fell off the world (the sea floor is far below): stop where it is.
        if global_position.y<original_world_y-60:
            coasting=false
            park_road_vehicle()
        elif settle(delta,road_physics.supported and planar<.08 and absf(road_physics.yaw_velocity)<.05):
            park_road_vehicle()

## Counts the time a coasting vehicle has been still; parks it (coasting off) after SETTLE_TIME.
func settle(delta: float, still: bool) -> bool:
    settle_clock=settle_clock+delta if still else 0.0
    if settle_clock<SETTLE_TIME: return false
    coasting=false
    settle_clock=0
    return true

## True while the vehicle moves or is off the ground: E then lets BonBon out beside it, without the
## door sequence, and the vehicle coasts on.
func is_moving() -> bool:
    if helicopter: return not ground_contact() or current_speed>STOPPED_SPEED
    if road_physics!=null:
        return not road_physics.supported or absf(road_physics.velocity.y)>.5 or absf(current_speed)>STOPPED_SPEED
    return false

## Where the vehicle stood when the town loaded.
func start_pose() -> Transform3D:
    var parent := get_parent() as Node3D
    return parent.global_transform*start_transform if parent!=null else start_transform

## Back to where it started, stopped (aircraft after a crash or left far away; the plane's red
## HUD Reset button). A driver stays aboard.
func reset_to_start() -> void:
    global_transform=start_pose()
    crashed=false
    crash_clock=0
    coasting=false
    settle_clock=0
    flight_velocity=Vector3.ZERO
    current_speed=0
    yaw_velocity=0
    if helicopter_physics!=null:
        helicopter_physics.reset()
        landed=true
        if not occupied: rotor_power=0
    if road_physics!=null: park_road_vehicle()

## A hard hit: the aircraft stops where it is and resets to its start EASY_RECOVER seconds later.
func crash() -> void:
    crashed=true
    crash_clock=0
    coasting=false
    flight_velocity=Vector3.ZERO
    current_speed=0
    yaw_velocity=0
    if helicopter_physics!=null: helicopter_physics.reset()

## Swept volume for the rider, so BonBon's head and arms cannot pass through walls (model units).
func add_rider_hull() -> void:
    # BonBon at full size is 2.24 tall and 1.22 deep; arms on the grips span 1.9.
    var rider_scale: float=rider_mount.get_meta("rider_scale",1.0)
    var shape:=BoxShape3D.new()
    shape.size=Vector3(1.3,2.25,1.9)*rider_scale
    flight_hulls.append({"shape":shape,"center":rider_mount.position+Vector3(0,1.15*rider_scale,0)/global_basis.get_scale().y,"basis":Basis.IDENTITY})

## Lean into turns (lateral acceleration v*yaw over g), turn the bars, track fore-aft acceleration.
func update_rider_visuals(delta: float) -> void:
    if road_physics==null or delta<=0: return
    var forward_speed: float=road_physics.velocity.dot(travel_forward())
    # The rider's lean (road_vehicle_physics.gd lean steering), shown up to MAX_LEAN and fading
    # out at walking pace and in reverse; it never follows the noisy yaw over kerbs.
    var target:=0.0
    if road_physics.lean_steer:
        target=road_physics.lean_angle*MAX_LEAN/road_physics.LEAN_MAX*clampf((forward_speed-1.0)/5.0,0,1)
    elif road_physics.supported:
        target=clampf(atan(forward_speed*road_physics.yaw_velocity/road_physics.GRAVITY),-MAX_LEAN,MAX_LEAN)
    lean=lerpf(lean,target,1-exp(-8*delta))
    longitudinal_accel=lerpf(longitudinal_accel,(forward_speed-previous_speed)/delta,1-exp(-5*delta))
    previous_speed=forward_speed
    if fork: fork.transform=fork_rest*Transform3D(Basis(Vector3.UP,clampf(-road_physics.steering_angle*BAR_STEER,-BAR_TURN_MAX,BAR_TURN_MAX)),Vector3.ZERO)
    set_lean_applied(lean)

## Rolls every visible part about the ground line under the bike (model X axis), undoing the
## previous lean first. StudyArea keeps the upright collision for clicks and sweeps.
func set_lean_applied(angle: float) -> void:
    if not has_rider() or is_equal_approx(angle,applied_lean): return
    var change:=Transform3D(Basis(Vector3.RIGHT,angle-applied_lean),Vector3.ZERO)
    for child in get_children():
        if child is Node3D and child.name!="StudyArea": child.transform=change*child.transform
    applied_lean=angle

# Swept physical volumes include the fuselage, skids, tail and entire rotor disk.
# Shapes are expressed in world units so the town's inherited scale is respected.
func build_flight_hulls() -> void:
    var scale_factor := global_basis.get_scale().abs()
    for mesh in find_children("*", "MeshInstance3D", true, false):
        if mesh.get_parent().name in ["MainRotor", "TailRotor"]: continue
        if not mesh.has_node("Solid") and mesh.name!="RotorMast": continue
        if mesh.mesh == null: continue
        var bounds: AABB = mesh.get_aabb()
        var local: Transform3D = global_transform.affine_inverse() * mesh.global_transform
        var shape := BoxShape3D.new()
        shape.size = bounds.size * scale_factor * local.basis.get_scale().abs()
        flight_hulls.append({"shape":shape,"center":local * bounds.get_center(),"basis":local.basis.orthonormalized()})
    var rotor := rotor_disk(4.05*scale_factor.x,.16*scale_factor.y)
    flight_hulls.append({"shape":rotor,"center":Vector3(0,3.22,.12),"basis":Basis.IDENTITY})
    var tail_disk := rotor_disk(.83*scale_factor.y,.15*scale_factor.x)
    flight_hulls.append({"shape":tail_disk,"center":Vector3(.27,2.18,4.72),"basis":Basis(Vector3.FORWARD,PI/2)})

func rotor_disk(radius: float,height: float) -> ConvexPolygonShape3D:
    # A circumscribed convex disk has stable tiny-motion sweeps in Godot Physics.
    # Its faces enclose the entire circular rotor at every animation phase.
    var shape:=ConvexPolygonShape3D.new()
    var points:=PackedVector3Array()
    var enclosing_radius:=radius/cos(PI/24)
    for i in range(24):
        var angle:=TAU*i/24
        for y in [-height*.5,height*.5]: points.append(Vector3(cos(angle)*enclosing_radius,y,sin(angle)*enclosing_radius))
    shape.points=points
    return shape

func hull_query(hull: Dictionary, pose: Transform3D, extra_exclusions: Array[RID] = []) -> PhysicsShapeQueryParameters3D:
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = hull.shape
    query.transform = Transform3D(pose.basis.orthonormalized() * hull.basis, pose * hull.center)
    query.exclude = collision_exceptions+extra_exclusions
    query.margin = 0.025
    return query

func flight_fraction(motion: Vector3, extra_exclusions: Array[RID] = []) -> float:
    var fraction := 1.0
    for hull in flight_hulls:
        var query := hull_query(hull, global_transform,extra_exclusions)
        query.motion = motion
        var result := get_world_3d().direct_space_state.cast_motion(query)
        var safe_fraction: float = result[0]
        # Keep a small skin at impact. Tiny wind steps must not start the next
        # sweep overlapping the margin (cast_motion ignores initial overlaps).
        if safe_fraction<1.0:
            safe_fraction = maxf(0.0,safe_fraction-.01/maxf(motion.length(),.00001))
        # Tiny motions can fall below the physics sweep tolerance. Also test
        # the destination so a slow gust cannot creep a rotor through a wall.
        var destination := hull_query(hull,global_transform,extra_exclusions)
        destination.transform.origin += motion*safe_fraction
        var space := get_world_3d().direct_space_state
        if not space.intersect_shape(destination,1).is_empty():
            var origin_query := hull_query(hull,global_transform,extra_exclusions)
            if space.intersect_shape(origin_query,1).is_empty():
                var low := 0.0
                var high := safe_fraction
                for i in range(8):
                    var middle := (low+high)*.5
                    destination.transform = origin_query.transform
                    destination.transform.origin += motion*middle
                    if space.intersect_shape(destination,1).is_empty(): low=middle
                    else: high=middle
                safe_fraction=low
        fraction = minf(fraction,safe_fraction)
    return fraction

func can_rotate(pose: Transform3D, extra_exclusions: Array[RID] = []) -> bool:
    for hull in flight_hulls:
        if not get_world_3d().direct_space_state.intersect_shape(hull_query(hull,pose,extra_exclusions),1).is_empty(): return false
    return true

func ground_contact() -> bool:
    if helicopter_physics==null or not helicopter_physics.wheel_support(self): return false
    return absf(flight_velocity.y)<.3 and Vector2(flight_velocity.x,flight_velocity.z).length()<.6

# Smooth, deterministic wind velocity: no per-frame random kicks or camera jitter.
func wind_velocity() -> Vector3:
    return Vector3(.75 + .25*sin(wind_clock*.31), 0, .35*sin(wind_clock*.23+.7)) * wind_strength

func flight_step(delta: float, gas: float, steering: float, lift: float, stabilize: bool = false) -> void:
    helicopter_physics.step(self,delta,gas,steering,lift,stabilize)

func safe_exit(player: CharacterBody3D) -> Dictionary:
    if animated_boarding() and boarding_busy():
        return {"ok":false,"reason":UiText.t("vehicle.getting_out" if exiting else "vehicle.getting_in")}
    if is_moving(): return moving_exit(player)
    var space := get_world_3d().direct_space_state
    var capsule: CapsuleShape3D = player.get_node("PlayerCollision").shape
    var candidates: Array[Vector3] = preferred_exit_points()
    var door_count := candidates.size()
    if candidates.is_empty() or get_meta("word_key", "")=="motorcycle":
        for direction in [global_basis.x.normalized(),-global_basis.x.normalized(),global_basis.z.normalized(),-global_basis.z.normalized()]:
            candidates.append(global_position + direction * (5.8 if helicopter else 3.3))
    for index in range(candidates.size()):
        var point: Vector3 = candidates[index]
        var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.5,point-Vector3.UP*1.0)
        ray.exclude = collision_exceptions + [player.get_rid()]
        var hit := space.intersect_ray(ray)
        if hit.is_empty() or hit.normal.y<.85: continue
        point = hit.position + Vector3.UP*.06
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = capsule
        query.transform = Transform3D(Basis.IDENTITY,point+Vector3.UP*1.1)
        query.exclude = [player.get_rid()]
        if space.intersect_shape(query,1).is_empty():
            # Check the whole transfer route, avoiding exits through walls.
            ray.from = global_position+Vector3.UP*1.2
            ray.to = point+Vector3.UP*1.2
            if space.intersect_ray(ray).is_empty(): return {"ok":true,"point":point,"door":index<door_count}
    return {"ok":false,"reason":UiText.t("vehicle.exit_blocked")}

## Sideways distance (world metres from the centre) where BonBon is let out of a moving vehicle:
## clear of the body, the rotor disk (radius 5.3 m) or the wings (half span 8.8 m).
func moving_exit_offset() -> float:
    if fixed_wing: return 10.5
    if helicopter: return 7.0
    return 3.3

## Exit from a moving or airborne vehicle: no door sequence; BonBon stands (or falls) beside it, to
## the right of the travel direction, else the left, else behind. On supported wheels the point
## snaps to the floor; in the air she falls from there (there is no fall damage).
func moving_exit(player: CharacterBody3D) -> Dictionary:
    var space := get_world_3d().direct_space_state
    var capsule: CapsuleShape3D = player.get_node("PlayerCollision").shape
    var forward := travel_forward()
    forward.y = 0.0
    forward = forward.normalized() if forward.length() > .01 else Vector3.FORWARD
    var side := forward.cross(Vector3.UP).normalized()
    var grounded: bool = road_physics!=null and road_physics.supported
    var reach := moving_exit_offset()
    for direction in [side, -side, -forward]:
        var point: Vector3 = global_position + direction * reach
        var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.5,point-Vector3.UP*1.0)
        ray.exclude = collision_exceptions + [player.get_rid()]
        if grounded:
            var hit := space.intersect_ray(ray)
            if hit.is_empty() or hit.normal.y<.85: continue
            point = hit.position + Vector3.UP*.06
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = capsule
        query.transform = Transform3D(Basis.IDENTITY,point+Vector3.UP*1.1)
        query.exclude = [player.get_rid()] + collision_exceptions
        if not space.intersect_shape(query,1).is_empty(): continue
        ray.from = global_position+Vector3.UP*1.2
        ray.to = point+Vector3.UP*1.2
        if space.intersect_ray(ray).is_empty(): return {"ok":true,"point":point,"door":false,"moving":true}
    return {"ok":false,"reason":UiText.t("vehicle.exit_blocked")}

## The flattened normal of what stops `motion` (world) from the current pose, facing back
## against the motion (road_vehicle_physics.gd wall slides). Falls back to straight back.
func contact_normal(motion: Vector3, extra_exclusions: Array[RID] = []) -> Vector3:
    var space := get_world_3d().direct_space_state
    var probe := motion.normalized()*maxf(motion.length(),.12)
    var best := Vector3.ZERO
    var best_fraction := INF
    for hull in flight_hulls:
        var query := hull_query(hull, global_transform, extra_exclusions)
        query.motion = probe
        var unsafe: float = space.cast_motion(query)[1]
        query.transform.origin += probe*minf(unsafe,1.0)
        query.motion = Vector3.ZERO
        var info := space.get_rest_info(query)
        if info.is_empty() or unsafe>best_fraction: continue
        best_fraction = unsafe
        best = info.normal
    best.y = 0.0
    var back := -Vector3(motion.x,0,motion.z).normalized()
    if best.length()<.2: return back
    best = best.normalized()
    return -best if best.dot(motion)>0 else best

# Animate the existing mesh pivots. Collision remains a continuous swept disk;
# spinning blades never change the physical envelope or the vocabulary target.
func prepare_rotors() -> void:
    main_rotor = get_node_or_null("MainRotor") as Node3D
    tail_rotor = get_node_or_null("TailRotor") as Node3D
    if main_rotor:
        main_rotor_rest = main_rotor.basis
        # A saved town (modular town) already holds the blur disc made when it was baked.
        var saved_blur := main_rotor.get_node_or_null("RotorMotionBlur") as MeshInstance3D
        if saved_blur != null:
            main_rotor.remove_child(saved_blur)
            saved_blur.free()
        rotor_blur = MeshInstance3D.new()
        rotor_blur.name = "RotorMotionBlur"
        var disk := CylinderMesh.new()
        disk.top_radius = 4.0
        disk.bottom_radius = 4.0
        disk.height = .018
        disk.radial_segments = 64
        rotor_blur.mesh = disk
        var material := StandardMaterial3D.new()
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.albedo_color = Color(.45,.55,.58,.09)
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        rotor_blur.material_override = material
        rotor_blur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        rotor_blur.visible = false
        main_rotor.add_child(rotor_blur)
    if tail_rotor: tail_rotor_rest = tail_rotor.basis

func _process(delta: float) -> void:
    if helicopter: update_rotors(delta)

func update_rotors(delta: float) -> void:
    # Visual RPM comes from the physical rotor governor; render FPS cannot change lift.
    rotor_angle = fposmod(rotor_angle + rotor_power * 36.0 * delta, TAU)
    tail_rotor_angle = fposmod(tail_rotor_angle + rotor_power * 158.4 * delta, TAU)
    if main_rotor: main_rotor.basis = main_rotor_rest * Basis(Vector3.UP,rotor_angle)
    if tail_rotor: tail_rotor.basis = tail_rotor_rest * Basis(Vector3.RIGHT,tail_rotor_angle)
    if rotor_blur:
        rotor_blur.visible = rotor_power>.35
        rotor_blur.material_override.albedo_color.a = rotor_power*.09

func landing_clearance() -> float:
    var origin := global_position+Vector3.UP*.5
    var query := PhysicsRayQueryParameters3D.create(origin,origin-Vector3.UP*4.0)
    query.exclude = collision_exceptions
    query.collision_mask = 0xFFFFFEFF # skip figure blockers (layer 256)
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty() or hit.normal.y<.65: return INF
    return maxf(0,global_position.y-hit.position.y)

