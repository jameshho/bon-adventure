extends RefCounted
## Rotor force/moment integration adapted from Igor Akulov's MIT VehicleRotor3D.
## Copyright (c) 2025 Igor Akulov; local adaptation and flight assistance, 2026.
## Pinned source and retained license: docs/guides/helicopter_inertia/README.md.
## Body axes: +X right, +Y up, -Z forward. Forces/velocities use world metres.
const DENSITY := 1.2255
const GRAVITY := 9.81
const OPERATING_SPEED := 36.0 # rad/s, 344 RPM
const MASS := 1800.0
const INERTIA := Vector3(14000,16000,9000)
var angular_velocity := Vector3.ZERO # body frame, rad/s
var collective := 0.0 # blade pitch at 75% radius, radians
var cyclic := Vector2.ZERO
var tail_pitch := 0.0
var induced_velocity := 0.0
var vertical_integral := 0.0
var thrust := 0.0
var force := Vector3.ZERO
var torque := Vector3.ZERO
var auxiliary_acceleration := Vector3.ZERO

func reset() -> void:
    angular_velocity=Vector3.ZERO
    collective=0
    cyclic=Vector2.ZERO
    tail_pitch=0
    induced_velocity=0
    vertical_integral=0
    thrust=0
    force=Vector3.ZERO
    torque=Vector3.ZERO
    auxiliary_acceleration=Vector3.ZERO

func wheel_support(vehicle) -> bool:
    for wheel in [Vector3(-1.12,.4,0),Vector3(1.12,.4,0),Vector3(0,.4,3.35)]:
        var start: Vector3=vehicle.to_global(wheel)
        var ray:=PhysicsRayQueryParameters3D.create(start,start-Vector3.UP*.7)
        ray.exclude=vehicle.collision_exceptions
        ray.collision_mask=0xFFFFFEFF # skip figure blockers (layer 256)
        var hit: Dictionary=vehicle.get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty() or hit.normal.y<.85: return false
        var foot: Vector3=vehicle.to_global(wheel-Vector3(0,.4,0))
        if foot.y-hit.position.y>.12: return false
    return true

func step(vehicle,delta: float,gas: float,steering: float,lift: float,assist: bool) -> void:
    # Consume elapsed time rather than silently discarding frames longer than 50 ms.
    var remaining:=clampf(delta,0,.25)
    while remaining>.000001:
        var dt:=minf(remaining,1.0/120)
        integrate(vehicle,dt,gas,steering,lift,assist)
        if vehicle.crashed: return
        remaining-=dt

func integrate(vehicle,dt: float,gas: float,steering: float,lift: float,assist: bool) -> void:
    var supported: bool=wheel_support(vehicle) and vehicle.flight_velocity.y<.5
    # Main uses occupied=false while an overlay is open. Preserve the suspended flight. A
    # helicopter left in the air (exit while moving, 14 Nov 2026) flies on with the rotor spinning down.
    if not vehicle.occupied and not vehicle.coasting and not supported: return
    var operating: bool=vehicle.occupied
    vehicle.rotor_power=move_toward(vehicle.rotor_power,1.0 if operating else 0.0,dt*(.45 if operating else .22))
    vehicle.wind_clock+=dt
    vehicle.hover_assist=operating and assist
    var basis: Basis=vehicle.global_basis.orthonormalized()
    var scale_factor: Vector3=vehicle.global_basis.get_scale()
    var wind: Vector3=vehicle.wind_velocity()
    var air_velocity: Vector3=basis.inverse()*(vehicle.flight_velocity-wind)
    var radius: float=4.05*scale_factor.x
    var chord: float=.27*scale_factor.x
    var omega: float=OPERATING_SPEED*vehicle.rotor_power
    var root_radius: float=radius*.2
    var lift_slope: float=DENSITY*omega*omega*chord*4*(pow(radius,3)-pow(root_radius,3))*TAU/6
    var desired_pitch: float=-gas*deg_to_rad(vehicle.maximum_pitch_degrees)
    var desired_roll: float=-steering*deg_to_rad(vehicle.maximum_bank_degrees)
    if assist:
        var local_velocity: Vector3=basis.inverse()*vehicle.flight_velocity
        # Cancel tail side-force and wind drag as well as existing ground-relative drift.
        desired_pitch=clampf((-local_velocity.z*.9-auxiliary_acceleration.z)/GRAVITY,-.32,.32)
        desired_roll=clampf((local_velocity.x*.9+auxiliary_acceleration.x)/GRAVITY,-.32,.32)
    var clearance: float=vehicle.landing_clearance()
    var near_ground: float=clampf((clearance-.35)/2.0,0,1) if lift<=0 else 1.0
    desired_pitch*=near_ground
    desired_roll*=near_ground
    if supported and lift<=0:
        desired_pitch=0
        desired_roll=0
        vertical_integral=0
    var attitude: Vector3=basis.get_euler()
    var forward: Vector3=-basis.z
    var heading:=Basis(Vector3.UP,atan2(-forward.x,-forward.z))
    var desired_basis:=heading*Basis.from_euler(Vector3(desired_pitch,0,desired_roll))
    var error_rotation: Quaternion=(basis.inverse()*desired_basis).get_rotation_quaternion().normalized()
    if error_rotation.w<0: error_rotation=-error_rotation
    var attitude_error:=error_rotation.get_axis()*error_rotation.get_angle()
    var yaw_rate: float=-steering*vehicle.steering_rate*.55 if operating and not supported else 0.0
    var feedforward_rates: Vector3=basis.inverse()*Vector3(0,yaw_rate,0)
    var stiffness: float=vehicle.attitude_response*vehicle.attitude_response*.7
    var damping: float=vehicle.attitude_response*1.4
    var acceleration_target:=Vector3(
        attitude_error.x*stiffness+(feedforward_rates.x-angular_velocity.x)*damping,
        (feedforward_rates.y-angular_velocity.y)*3,
        attitude_error.z*stiffness+(feedforward_rates.z-angular_velocity.z)*damping)
    var requested_torque: Vector3=INERTIA*acceleration_target
    var moment_slope:=maxf(lift_slope*radius*.375,1)
    var cyclic_target:=Vector2(-requested_torque.x/moment_slope,-requested_torque.z/moment_slope)
    cyclic=cyclic.lerp(cyclic_target.clamp(Vector2(-.105,-.105),Vector2(.105,.105)),1-exp(-8*dt))
    var target_vertical: float=lift*vehicle.lift_speed
    var vertical_error: float=target_vertical-vehicle.flight_velocity.y
    if vehicle.rotor_power>.9 and not supported:
        vertical_integral=clampf(vertical_integral+vertical_error*dt,-4,4)
    var vertical_acceleration:=clampf(vertical_error*2.5+vertical_integral,-5,6)
    var target_thrust:=MASS*(GRAVITY+vertical_acceleration)/maxf(basis.y.y,.55)
    if not operating or (supported and lift<=0): target_thrust=0
    var inflow_target:=sqrt(maxf(thrust,0)/(2*DENSITY*PI*radius*radius))
    induced_velocity=lerpf(induced_velocity,inflow_target,1-exp(-4*dt))
    var pitch_target:=target_thrust/maxf(lift_slope,1)+atan2(air_velocity.y+induced_velocity,maxf(omega*radius*.75,1))
    collective=move_toward(collective,clampf(pitch_target,0,deg_to_rad(20)),dt*.6)
    var main:=rotor_forces(air_velocity,omega,radius,chord,collective,cyclic,induced_velocity)
    thrust=maxf(main.force.y,0)
    # Upstream tail rotor: relative flow + rotational blade speed -> lift -> yaw torque.
    # A stability controller supplies anti-torque trim as well as the pilot's pedal input.
    var arm:=4.72*scale_factor.z
    var tail_radius:=.83*scale_factor.y
    var tail_speed:=tail_radius*omega*4.4
    var tail_area:=2*.17*scale_factor.x*tail_radius*.5
    var lateral_velocity: float=air_velocity.x+angular_velocity.y*arm
    var pressure:=.5*pow(lateral_velocity+tail_speed,2)*DENSITY*tail_area
    var tail_target: float=-(requested_torque.y-main.torque.y)/maxf(arm*pressure*TAU,1)-atan2(lateral_velocity,maxf(tail_speed,1))
    tail_pitch=lerpf(tail_pitch,clampf(tail_target,-.22,.22),1-exp(-10*dt))
    var tail:=tail_forces(air_velocity,omega,scale_factor,tail_pitch)
    var rotor_drag: Vector3=-air_velocity*MASS*vehicle.coasting_drag
    var fuselage_drag: Vector3=-Vector3(5.5,10,3)*air_velocity*air_velocity.abs()*.5*DENSITY
    var in_plane_force: Vector3=main.force-Vector3.UP*main.force.y
    auxiliary_acceleration=(in_plane_force+tail.force+rotor_drag+fuselage_drag)/MASS
    force=basis*(main.force+tail.force+rotor_drag+fuselage_drag)+Vector3.DOWN*MASS*GRAVITY
    torque=main.torque+tail.torque
    if supported and lift<=0:
        # Coming down onto the skids much faster than a landing is a crash (14 Nov 2026).
        if vehicle.flight_velocity.y< -vehicle.HELI_CRASH_SPEED:
            vehicle.crash()
            return
        vehicle.flight_velocity=Vector3.ZERO
        angular_velocity=Vector3.ZERO
        vehicle.current_speed=0
        vehicle.yaw_velocity=0
        vehicle.landed=true
        return
    var angular_acceleration: Vector3=(torque-angular_velocity.cross(INERTIA*angular_velocity))/INERTIA
    angular_velocity+=angular_acceleration*dt
    angular_velocity=angular_velocity.clamp(Vector3(-1.5,-1.5,-1.5),Vector3(1.5,1.5,1.5))
    var rotation_step:=angular_velocity*dt
    var next_pose: Transform3D=vehicle.global_transform
    if rotation_step.length_squared()>.000000001:
        next_pose.basis=(basis*Basis(rotation_step.normalized(),rotation_step.length())).orthonormalized().scaled(scale_factor)
        # Level about the lowest wheel on approach, avoiding rotating a wheel into the pad.
        if clearance<1 and absf(attitude.x)+absf(attitude.z)>.01:
            var old_low:=INF
            var new_low:=INF
            for p in [Vector3(-1.12,0,0),Vector3(1.12,0,0),Vector3(0,0,3.35)]:
                old_low=minf(old_low,(vehicle.global_transform*p).y)
                new_low=minf(new_low,(next_pose*p).y)
            next_pose.origin.y+=maxf(0,old_low-new_low)
        if vehicle.can_rotate(next_pose): vehicle.global_transform=next_pose
        else: angular_velocity=Vector3.ZERO
    vehicle.flight_velocity+=force/MASS*dt
    # Use full-volume swept collisions for every translation, including rotor drift.
    for axis in [0,2,1]:
        var movement:=Vector3.ZERO
        movement[axis]=vehicle.flight_velocity[axis]*dt
        if movement.length_squared()<.000000001: continue
        var fraction: float=vehicle.flight_fraction(movement)
        vehicle.global_position+=movement*fraction
        if fraction<1:
            # A hard hit is a crash (14 Nov 2026): it resets to its pad (DriveableVehicle.crash()).
            if absf(vehicle.flight_velocity[axis])>vehicle.HELI_CRASH_SPEED:
                vehicle.crash()
                return
            vehicle.flight_velocity[axis]=0
            if axis==1: vertical_integral=0
    vehicle.current_speed=Vector2(vehicle.flight_velocity.x,vehicle.flight_velocity.z).length()
    vehicle.yaw_velocity=-angular_velocity.y
    vehicle.landed=wheel_support(vehicle) and absf(vehicle.flight_velocity.y)<.3 and vehicle.current_speed<.6

func rotor_forces(air_velocity: Vector3,omega: float,radius: float,chord: float,pitch: float,stick: Vector2,inflow: float) -> Dictionary:
    # Adapted VehicleRotor3D's blade-force summation/cyclic pitch and VehicleWing3D's
    # local-flow/pressure vectors. Eight azimuths average a revolution, avoiding
    # rotor-phase aliasing at different physics rates. Four radial blade elements.
    var result_force:=Vector3.ZERO
    var result_torque:=Vector3.ZERO
    var dr:=radius*.8/4
    for azimuth in range(8):
        var angle:=TAU*azimuth/8
        var radial:=Vector3(cos(angle),0,sin(angle))
        var tangent:=Vector3.UP.cross(radial)
        var cyclic_pitch: float=stick.x*sin(angle)-stick.y*cos(angle)
        for section in range(4):
            var r: float=radius*.2+(section+.5)*dr
            var arm: Vector3=radial*r
            var velocity: Vector3=air_velocity+angular_velocity.cross(arm)
            var speed:=maxf(0,omega*r+velocity.dot(tangent))
            var flow:=tangent*speed+Vector3.UP*(velocity.y+inflow)
            if flow.length_squared()<.0001: continue
            var alpha: float=pitch+cyclic_pitch-deg_to_rad(5)*(r/radius-.75)-atan2(velocity.y+inflow,maxf(speed,1))
            var cl:=clampf(TAU*alpha,-1.35,1.35)
            if absf(alpha)>deg_to_rad(18): cl=lerpf(cl,sin(2*alpha),clampf((absf(alpha)-.314)/.4,0,1))
            var cd:=.012+.015*cl*cl
            var wind_direction: Vector3=-flow.normalized()
            var lift_direction: Vector3=wind_direction.cross(radial).normalized()
            var pressure: float=.5*DENSITY*flow.length_squared()*chord*dr*4/8
            var blade_force: Vector3=(lift_direction*cl+wind_direction*cd)*pressure
            result_force+=blade_force
            result_torque+=arm.cross(blade_force)
    return {"force":result_force,"torque":result_torque}

func tail_forces(air_velocity: Vector3,omega: float,scale_factor: Vector3,pitch: float) -> Dictionary:
    # Adapted VehicleRotor3D::_calc_fake_tail_torque, retaining translational force.
    var arm:=Vector3(0,0,4.72*scale_factor.z)
    var radius: float=.83*scale_factor.y
    var work_area: float=2*.17*scale_factor.x*radius*.5
    var lateral_velocity: float=(air_velocity+angular_velocity.cross(arm)).x
    var blade_velocity: float=radius*omega*4.4
    var pressure:=.5*pow(lateral_velocity+blade_velocity,2)*DENSITY*work_area
    var alpha:=atan2(lateral_velocity,maxf(blade_velocity,1))+pitch
    var lift: float=TAU*clampf(alpha,-.244,.244)
    var tail_force:=Vector3.LEFT*lift*pressure
    return {"force":tail_force,"torque":arm.cross(tail_force)}
