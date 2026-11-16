extends RefCounted
## Tire grip, raycast spring/damper and steering adapted from Dechode's MIT
## Godot-Simple-Vehicle. Copyright (c) 2022 Dechode; local adaptation 2026.
## See docs/guides/ZOO_VEHICLE_IMPLEMENTATION.md for pinned source and retained license.
## Existing road models face -X; this is an assisted upright-body vehicle solver.
const GRAVITY := 9.81
# [mass kg, engine acceleration m/s^2, top speed m/s]. 28 Oct 2026: about 1.6x the
# earlier pull. 29 Oct 2026: top speeds 1.5-1.9x the former shared 14 m/s; heavy
# vehicles keep their slower, distinct feel. DriveableVehicle exports override them.
const PROFILES := {
    "car":[1250.0,6.5,25.0], "taxi":[1400.0,5.9,24.0], "police car":[1450.0,7.4,27.0],
    "truck":[4200.0,3.8,22.0], "bus":[6500.0,3.2,21.0], "school bus":[6500.0,3.2,21.0],
    "ambulance":[3600.0,4.8,24.0], "fire truck":[6800.0,3.7,21.0], "motorcycle":[260.0,7.8,27.0]
}
## Wheel rays start this far above the wheel centre, so a curb or bump ahead of the
## tyre is sensed as ground before the body sweep meets it.
const RAY_HEADROOM := .35
## Largest ledge (world units) the body may climb when a sweep is blocked.
const STEP_HEIGHT := .3
var velocity := Vector3.ZERO
var yaw_velocity := 0.0
var steering_angle := 0.0
var throttle := 0.0
var brake_level := 0.0
var gear := 1
var mass := 1250.0
var engine_acceleration := 3.8
var wheelbase := 2.7
## Model-unit x midway between the axles. Tire yaw arms are measured from here, so
## bodies with unequal overhangs (Subi: front axle 1.24, rear 1.01) stay neutral.
var axle_center := 0.0
var yaw_inertia := 1200.0
var body_bottom := 0.0
var supported := false
var wheels: Array[Dictionary] = []
var contacts: Array[Dictionary] = []
var ground_exclusions: Array[RID] = []
var floor_height := -INF
var grip_usage := 0.0
var parked_pose := Transform3D.IDENTITY
var has_parked_pose := false
## Two-wheelers (the scooter, 9 Nov 2026) steer by leaning instead of the car tyre model:
## holding A/D builds the lean progressively, the lean sets the path curvature
## (lateral acceleration LEAN_GRIP*g*tan(lean), capped by the bars' lock at low speed), the
## body follows its nose (sideways slip damped) and the yaw comes from the path, not from
## per-tyre forces, so a kerb under one of the two tyres cannot spin the bike or upset the lean.
var lean_steer := false
var lean_angle := 0.0
## Tuning passes with the user, 9 Nov 2026: turns too small -> more grip; then "start at a greater
## angle, grow more the longer I press, don't slow so quickly off the throttle".
const LEAN_MAX := 1.0
const LEAN_START := .35      # a press snaps to this lean at once (LEAN_SNAP rad/s) ...
const LEAN_SNAP := 3.0
const LEAN_IN := .28         # ... then keeps building at this rate: full lean after ~2.4 s
const LEAN_OUT := 1.8        # rad/s back toward upright when released or reversed
const LEAN_GRIP := 2.4       # arcade grip: lateral g per tan(lean)
const LEAN_LOCK := .8        # bars' lock (rad): the tightest turn at walking pace
const LEAN_YAW_MAX := 2.6    # rad/s
const SLIP_DAMPING := 14.0   # 1/s; how quickly sideways slip dies away
const CORNER_DRAG := 2.0     # m/s^2 at full grip: a deep lean scrubs a little speed
const LEAN_COAST := .35      # m/s^2 rolling off the throttle (cars: vehicle.coast_deceleration)
## Arcade wall contact (user, 14 Nov 2026): a blocked move slides along what blocks it instead of
## stopping dead. The into-wall speed is removed (a little bounces back), the speed along the wall
## keeps SLIDE_KEEP_* (scaled by how hard the hit was, so a long scrape does not bleed speed every
## step), steering keeps working and the nose is nudged toward the wall line. Hard hits (into-wall
## speed above MAJOR_IMPACT_SPEED, i.e. near head-on at speed) keep only MAJOR_KEEP. The rest of
## the move is swept again along the wall (up to SLIDE_PASSES sweeps), so nothing tunnels.
const SLIDE_KEEP_CAR := .85
const SLIDE_KEEP_BIKE := .95       # motorcycles are the most forgiving
const IMPACT_REFERENCE := 3.0      # m/s into the wall for the full SLIDE_KEEP loss (lighter hits lose less)
const MAJOR_IMPACT_SPEED := 9.0    # m/s into the wall where a hit starts to count as major
const MAJOR_IMPACT_FULL := 15.0    # m/s into the wall for the full MAJOR_KEEP
const MAJOR_KEEP := .45
const WALL_BOUNCE := .15           # share of the into-wall speed bounced back
const YAW_KEEP := .8               # share of the yaw rate kept at a hit (was cut to 25%)
const YAW_NUDGE := 2.0             # 1/s per radian between the nose and the wall line
const YAW_NUDGE_MAX := .6          # rad/s
const SLIDE_PASSES := 3
const BIKE_ALIGN := .8             # share of the angle to the wall line a motorcycle turns at a hit
## Into-wall speed (m/s) of the latest hit, for checks and future sound.
var last_impact := 0.0

func configure(vehicle) -> void:
    var key: String=vehicle.get_meta("word_key","car")
    var profile: Array=PROFILES.get(key,PROFILES.car)
    mass=profile[0]
    engine_acceleration=profile[1]
    if vehicle.top_speed<=0: vehicle.top_speed=profile[2]
    var min_x:=INF
    var max_x:=-INF
    for child in vehicle.get_children():
        if child.get_meta("word_key","")!="wheel": continue
        var visual:=child.get_node_or_null("Visual") as MeshInstance3D
        var radius:=.33
        if visual!=null and visual.mesh is CylinderMesh: radius=visual.mesh.top_radius*visual.scale.x
        wheels.append({"node":child,"rest":child.transform,"radius":radius,"spin":0.0,"compression":.5})
        min_x=minf(min_x,child.position.x)
        max_x=maxf(max_x,child.position.x)
    var scale_factor: Vector3=vehicle.global_basis.get_scale().abs()
    wheelbase=maxf(1,(max_x-min_x)*scale_factor.x)
    axle_center=(min_x+max_x)*.5 if wheels.size()>0 else 0.0
    yaw_inertia=mass*(wheelbase*wheelbase+2)/12
    lean_steer=wheels.size()<=2
    var bounds:=AABB()
    var first:=true
    # Preserve actual authored body/cabin volumes; don't rely on three bumper rays.
    for collider in vehicle.get_node("StudyArea").get_children():
        if not collider is CollisionShape3D or not collider.shape is BoxShape3D: continue
        var local: Transform3D=vehicle.global_transform.affine_inverse()*collider.global_transform
        var shape:=BoxShape3D.new()
        shape.size=collider.shape.size*scale_factor*local.basis.get_scale().abs()
        vehicle.flight_hulls.append({"shape":shape,"center":local.origin,"basis":local.basis.orthonormalized()})
        var box: AABB=local*AABB(-collider.shape.size*.5,collider.shape.size)
        bounds=box if first else bounds.merge(box)
        first=false
    body_bottom=bounds.position.y*scale_factor.y
    # Several authored vocabulary/body boxes extend below the visible tire bottoms.
    # Calibrate preload to their existing floor clearance, without rewriting scenes.
    for wheel in wheels:
        var foot: float=(wheel.rest.origin.y-wheel.radius)*scale_factor.y
        wheel.gap=maxf(0,-body_bottom+.035+foot)

func reset() -> void:
    velocity=Vector3.ZERO
    yaw_velocity=0
    steering_angle=0
    lean_angle=0
    throttle=0
    brake_level=0
    gear=1
    supported=false
    for wheel in wheels:
        wheel.spin=0.0
        wheel.compression=.5
        wheel.node.transform=wheel.rest

func step(vehicle,delta: float,gas: float,steering: float,brake: bool,recover: bool = false) -> void:
    # Parked (and the overlay pause) costs nothing; a vehicle left moving coasts (exit while
    # moving, 14 Nov 2026) with no input until it settles (DriveableVehicle.coasting).
    if not vehicle.occupied and not vehicle.coasting: return
    if not has_parked_pose:
        parked_pose=vehicle.global_transform
        has_parked_pose=true
    if recover and not supported:
        var pose:=parked_pose
        pose.origin.y+=.6
        if vehicle.can_rotate(pose):
            vehicle.global_transform=pose
            reset()
            vehicle.current_speed=0
            return
    var remaining:=clampf(delta,0,.25)
    while remaining>.000001:
        var dt:=minf(remaining,1.0/120)
        integrate(vehicle,dt,gas,steering,brake)
        remaining-=dt

func sample_ground(vehicle,dt: float) -> void:
    contacts.clear()
    ground_exclusions.clear()
    floor_height=-INF
    var scale_factor: Vector3=vehicle.global_basis.get_scale()
    for wheel in wheels:
        var p: Vector3=wheel.rest.origin
        var radius: float=wheel.radius*scale_factor.y
        var anchor: Vector3=vehicle.to_global(p)+Vector3.UP*RAY_HEADROOM
        var ray:=PhysicsRayQueryParameters3D.create(anchor,anchor-Vector3.UP*(radius+RAY_HEADROOM+.48))
        ray.exclude=vehicle.collision_exceptions
        ray.collision_mask=0xFFFFFEFF # skip figure blockers (layer 256)
        var hit: Dictionary=vehicle.get_world_3d().direct_space_state.intersect_ray(ray)
        # Park slopes up to about 55 degrees still count as driving surface.
        if hit.is_empty() or hit.normal.y<.55:
            wheel.compression=0.0
            continue
        # Adapted Wheels.gd spring compression and asymmetric damping calculation.
        var spring_length: float=anchor.distance_to(hit.position)-radius-(RAY_HEADROOM-.12)
        var rest_length: float=2*(.12+wheel.gap)
        var compression:=clampf(1-spring_length/rest_length,0,1)
        var compression_speed: float=(compression-wheel.compression)*rest_length/dt
        var weight:=mass*GRAVITY/wheels.size()
        var normal_load:=maxf(0,weight*2*compression+compression_speed*mass/wheels.size()*3)
        normal_load=minf(normal_load,weight*3)
        wheel.compression=compression
        var title:=str(hit.collider.get_parent().name).to_lower()
        var mu:=.95
        if "terrain" in title or "meadow" in title or "lawn" in title: mu=.65
        if "beach" in title: mu=.45
        contacts.append({"wheel":wheel,"point":hit.position,"load":normal_load,"mu":mu,"normal":hit.normal})
        if not ground_exclusions.has(hit.rid): ground_exclusions.append(hit.rid)
        floor_height=maxf(floor_height,hit.position.y-body_bottom+.035)
    # A two-wheeler is still on the road with one tyre over a kerb edge.
    supported=contacts.size()>=(1 if lean_steer else 2)

func tire_force(slip_angle: float,normal_load: float,mu: float) -> float:
    # Upstream's normal-load-scaled curve, with an analytic peak instead of a resource.
    var slip:=absf(slip_angle)
    var curve:=minf(slip/.12,1.0)*lerpf(1.0,.85,clampf((slip-.25)/.75,0,1))
    return -signf(slip_angle)*curve*normal_load*mu

func integrate(vehicle,dt: float,gas: float,steering: float,brake: bool) -> void:
    sample_ground(vehicle,dt)
    var forward: Vector3=vehicle.travel_forward()
    forward.y=0
    forward=forward.normalized()
    var speed:=velocity.dot(forward)
    var planar_speed:=Vector2(velocity.x,velocity.z).length()
    var braking: bool=brake or (gas*speed<-.4)
    if absf(speed)<.4 and absf(gas)>.01 and not brake: gear=1 if gas>0 else -1
    var target_throttle: float=absf(gas) if not braking else 0.0
    # Pedals ease in (smooth launches and brake bite) and release twice as fast.
    throttle=move_toward(throttle,target_throttle,dt*vehicle.throttle_response*(1.0 if target_throttle>throttle else 2.0))
    brake_level=move_toward(brake_level,1.0 if braking else 0.0,dt*vehicle.brake_response*(1.0 if braking else 2.0))
    # Steering lock shrinks with speed and is capped so the requested turn stays
    # within max_lateral_acceleration (v^2 * steer / wheelbase): stable at high speed.
    var max_steer: float=.55*(vehicle.steering_rate/1.55)/(1+pow(planar_speed/vehicle.steering_falloff_speed,2))
    if planar_speed>1: max_steer=minf(max_steer,atan(vehicle.max_lateral_acceleration*wheelbase/(planar_speed*planar_speed)))
    var steer_rate: float=vehicle.steering_speed/(1+planar_speed/20) if absf(steering)>.01 else vehicle.steering_return
    steering_angle=move_toward(steering_angle,steering*max_steer,dt*steer_rate)
    var curvature:=0.0
    if lean_steer:
        # Lean toward the held side (positive leans left, as A gives steering -1); easing back
        # (released or reversed) is faster than leaning in.
        var target_lean:=-steering*LEAN_MAX
        var leaning_in:=absf(target_lean)>absf(lean_angle) and signf(target_lean)==signf(lean_angle) or lean_angle==0
        var lean_rate:=LEAN_OUT
        if leaning_in: lean_rate=LEAN_SNAP if absf(lean_angle)<LEAN_START else LEAN_IN
        lean_angle=move_toward(lean_angle,target_lean,dt*lean_rate)
        var balanced:=LEAN_GRIP*GRAVITY*tan(absf(lean_angle))/maxf(speed*speed,.01)
        curvature=signf(lean_angle)*minf(balanced,tan(LEAN_LOCK*absf(lean_angle)/LEAN_MAX)/wheelbase)
        # The front wheel and bars show the geometric angle of that path.
        steering_angle=-atan(curvature*wheelbase)
    var speed_limit: float=vehicle.top_speed if gear>0 else vehicle.reverse_speed
    var power: float=1.0 if gear>0 else vehicle.reverse_power
    var engine_force: float=mass*engine_acceleration*power*throttle*gear*clampf(1-pow(absf(speed)/maxf(speed_limit,1),3),0,1)
    var total_force:=Vector3.DOWN*mass*GRAVITY
    var torque:=0.0
    grip_usage=0
    for contact in contacts:
        var p: Vector3=contact.wheel.rest.origin
        var front: bool=p.x<axle_center
        var wheel_forward: Vector3=forward.rotated(Vector3.UP,-steering_angle if front else 0.0)
        var wheel_right: Vector3=wheel_forward.cross(Vector3.UP)
        var arm: Vector3=vehicle.global_basis*Vector3(p.x-axle_center,0,p.z)
        var point_velocity: Vector3=velocity+Vector3.UP.cross(arm)*yaw_velocity
        var along:=point_velocity.dot(wheel_forward)
        var side:=point_velocity.dot(wheel_right)
        var slip:=atan2(side,maxf(absf(along),.7))
        var lateral: float=0.0 if lean_steer else tire_force(slip,contact.load,contact.mu)
        var longitudinal: float=engine_force/wheels.size()
        if braking or (brake_level>.01 and absf(gas)<.01):
            var decel: float=maxf(vehicle.brake_deceleration*brake_level,vehicle.coast_deceleration)
            longitudinal=-signf(along)*minf(mass*decel/wheels.size(),absf(along)*mass/(dt*wheels.size()))
        elif absf(gas)<.01:
            var coast: float=LEAN_COAST if lean_steer else vehicle.coast_deceleration
            longitudinal=-signf(along)*minf(mass*coast/wheels.size(),absf(along)*mass/(dt*wheels.size()))
        else:
            longitudinal-=signf(along)*mass*.15/wheels.size()
        # Adapted upstream combined slip: acceleration/braking and cornering share grip.
        var demand:=Vector2(lateral,longitudinal)
        var available: float=contact.load*contact.mu
        grip_usage=maxf(grip_usage,demand.length()/maxf(available,1))
        demand=demand.limit_length(available)
        var tire_force_world: Vector3=wheel_right*demand.x+wheel_forward*demand.y
        total_force+=tire_force_world+contact.normal*contact.load
        torque+=arm.cross(tire_force_world).y
    total_force-=Vector3(velocity.x,0,velocity.z)*planar_speed*.45
    velocity+=total_force/mass*dt
    if lean_steer:
        if supported:
            # Follow the nose: sideways slip dies away; the yaw follows the leaned path.
            var side_axis: Vector3=forward.cross(Vector3.UP)
            velocity-=side_axis*velocity.dot(side_axis)*(1-exp(-SLIP_DAMPING*dt))
            var along:=velocity.dot(forward)
            yaw_velocity=lerpf(yaw_velocity,along*curvature,1-exp(-10*dt))
            # Carry the speed round the bend with the nose (damping alone would bleed it away).
            velocity=velocity.rotated(Vector3.UP,yaw_velocity*dt)
            grip_usage=absf(along*yaw_velocity)/(GRAVITY*LEAN_GRIP*tan(LEAN_MAX))
            velocity-=forward*signf(along)*minf(absf(along),CORNER_DRAG*grip_usage*grip_usage*dt)
        else:
            yaw_velocity*=exp(-dt*.15)
    else:
        yaw_velocity+=torque/yaw_inertia*dt
        yaw_velocity*=exp(-dt*((.8+planar_speed*vehicle.high_speed_yaw_damping) if supported else .15))
    var yaw_max:=LEAN_YAW_MAX if lean_steer else 1.8
    yaw_velocity=clampf(yaw_velocity,-yaw_max,yaw_max)
    if supported and braking and planar_speed<.15:
        velocity.x=0
        velocity.z=0
        yaw_velocity=0
    # Collision-check the entire turning body in small angular increments.
    var angle: float=yaw_velocity*dt
    var segments:=maxi(1,ceili(absf(angle)/.003))
    for i in range(segments):
        var pose: Transform3D=vehicle.global_transform
        pose.basis=Basis(Vector3.UP,angle/segments)*pose.basis
        if vehicle.can_rotate(pose,ground_exclusions): vehicle.global_transform=pose
        else:
            yaw_velocity=0
            break
    # Supporting slabs are handled by wheel contacts, other solids by body sweeps. The planar move
    # is swept whole; a blocked rest climbs a kerb (step_up) or slides along the wall and is swept again.
    var move:=Vector3(velocity.x,0,velocity.z)*dt
    var hit:=false
    for i in range(SLIDE_PASSES):
        if move.length_squared()<.000000001: break
        var fraction: float=vehicle.flight_fraction(move,ground_exclusions)
        vehicle.global_position+=move*fraction
        if fraction>=1: break
        var rest:=move*(1-fraction)
        if supported and step_up(vehicle,rest): break
        var normal: Vector3=vehicle.contact_normal(rest,ground_exclusions)
        if not hit: wall_contact(vehicle,normal)
        else:
            # A second surface (a corner): only stop moving into it.
            var into:=velocity.dot(normal)
            if into<0: velocity-=normal*into
        hit=true
        move=rest-normal*minf(0,rest.dot(normal))
    var movement:=Vector3(0,velocity.y*dt,0)
    if supported and vehicle.global_position.y+movement.y<floor_height:
        movement.y=floor_height-vehicle.global_position.y
        velocity.y=0
    if movement.length_squared()>.000000001:
        var fraction: float=vehicle.flight_fraction(movement,ground_exclusions)
        vehicle.global_position+=movement*fraction
        if fraction<1: velocity.y=0
    var actual_forward: Vector3=vehicle.travel_forward()
    var signed_speed:=velocity.dot(actual_forward)
    vehicle.current_speed=Vector2(velocity.x,velocity.z).length()*(signf(signed_speed) if absf(signed_speed)>.01 else gear)
    animate_wheels(vehicle,dt)

## A hit on a surface with (flat, outward) normal `normal`: removes the into-wall speed, keeps
## most of the speed along it and nudges the nose toward the wall line (constants above).
func wall_contact(vehicle,normal: Vector3) -> void:
    var planar:=Vector3(velocity.x,0,velocity.z)
    var into:=-planar.dot(normal)
    if into<=0: return
    last_impact=into
    var tangent:=planar+normal*into
    var keep:=lerpf(1.0,SLIDE_KEEP_BIKE if lean_steer else SLIDE_KEEP_CAR,clampf(into/IMPACT_REFERENCE,0,1))
    keep=lerpf(keep,MAJOR_KEEP,clampf((into-MAJOR_IMPACT_SPEED)/(MAJOR_IMPACT_FULL-MAJOR_IMPACT_SPEED),0,1))
    var result:=tangent*keep+normal*into*WALL_BOUNCE
    velocity.x=result.x
    velocity.z=result.z
    yaw_velocity*=YAW_KEEP
    if tangent.length()>.5:
        var forward: Vector3=vehicle.travel_forward()
        forward.y=0
        # Line the nose (or the tail, when reversing) up with the wall.
        var heading:=tangent.normalized()*(1.0 if forward.dot(tangent)>=0 else -1.0)
        var turn:=forward.normalized().signed_angle_to(heading,Vector3.UP)
        # A bike follows its nose (no tyre forces swing it round): it turns most of the way to the
        # wall line at once, as far as it can without touching anything, and rides along it.
        if lean_steer: rotate_clear(vehicle,turn*BIKE_ALIGN)
        yaw_velocity+=clampf(turn*YAW_NUDGE,-YAW_NUDGE_MAX,YAW_NUDGE_MAX)

## Turns the body by `angle` (rad) in small steps, stopping where the next step would touch something.
func rotate_clear(vehicle,angle: float) -> void:
    var segments:=maxi(1,ceili(absf(angle)/.01))
    for i in range(segments):
        var pose: Transform3D=vehicle.global_transform
        pose.basis=Basis(Vector3.UP,angle/segments)*pose.basis
        if not vehicle.can_rotate(pose,ground_exclusions): return
        vehicle.global_transform=pose

func step_up(vehicle,rest: Vector3) -> bool:
    # Curbs, dropped kerbs and small ledges lift the body instead of stopping it; the
    # suspension then settles onto the new surface. Walls and posts still block.
    for lift in [STEP_HEIGHT*.4,STEP_HEIGHT*.7,STEP_HEIGHT]:
        var raised: Transform3D=vehicle.global_transform
        raised.origin.y+=lift
        if not vehicle.can_rotate(raised,ground_exclusions): return false
        var saved: Transform3D=vehicle.global_transform
        vehicle.global_transform=raised
        var fraction: float=vehicle.flight_fraction(rest,ground_exclusions)
        if fraction>.95:
            vehicle.global_position+=rest*fraction
            return true
        vehicle.global_transform=saved
    return false

func animate_wheels(vehicle,dt: float) -> void:
    var scale_factor: float=vehicle.global_basis.get_scale().y
    var forward_speed:=velocity.dot(vehicle.travel_forward())
    for wheel in wheels:
        wheel.spin=fposmod(wheel.spin-forward_speed/maxf(wheel.radius*scale_factor,.1)*dt,TAU)
        var rest: Transform3D=wheel.rest
        var steer: float=-steering_angle if rest.origin.x<0 else 0.0
        wheel.node.transform=Transform3D(Basis(Vector3.UP,steer)*rest.basis*Basis(Vector3.UP,wheel.spin),rest.origin)
        # Keep tire geometry and its existing vocabulary target together.
        wheel.node.position.y-=wheel.gap/scale_factor
        wheel.node.position.y+=(wheel.compression-.5)*.12
