extends SceneTree
var game
var checks:=0
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures.append(label)
        push_error("ROAD PHYSICS: "+label)
func reset(vehicle,p := Vector3(1000,.45,1000)) -> void:
    vehicle.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),p)
    vehicle.road_physics.reset()
    vehicle.current_speed=0
    vehicle.occupied=true
func advance(vehicle,seconds: float,gas: float,steer := 0.0,brake := false,hz := 60) -> void:
    for i in range(roundi(seconds*hz)): vehicle.drive_step(1.0/hz,gas,steer,1.0 if brake else 0.0)
func run():
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for vehicle in game.driveable_vehicles:
        vehicle.set_physics_process(false)
        vehicle.set_process(false)
    var pad=game.box("Road physics fixture",Vector3.ZERO,Vector3(140,.4,140),Color.WHITE,"",true)
    pad.global_position=Vector3(1000,0,1000)
    await physics_frame
    await physics_frame
    var speeds: Dictionary={}
    for vehicle in game.driveable_vehicles:
        if vehicle.helicopter or vehicle.fixed_wing: continue
        var original: Transform3D=vehicle.global_transform
        var title: String=vehicle.name
        check(vehicle.road_physics.wheels.size()>=2 and vehicle.flight_hulls.size()>=1,title+" existing wheels and solid envelopes reused")
        check(game.interaction.word_key(vehicle)==vehicle.get_meta("word_key"),title+" vocabulary root retained")
        reset(vehicle)
        advance(vehicle,1,0,0,true)
        check(vehicle.road_physics.supported,title+" suspension supports vehicle on the platform")
        var start: Vector3=vehicle.global_position
        advance(vehicle,3,1)
        speeds[title]=vehicle.current_speed
        check(vehicle.current_speed>2 and vehicle.global_position.distance_to(start)>4,title+" engine force accelerates vehicle")
        check(vehicle.current_speed<vehicle.top_speed+.2,title+" configured top speed remains effective")
        var moving_exit: Dictionary=vehicle.safe_exit(game.player)
        check(moving_exit.ok and not moving_exit.door,title+" moving exit lets BonBon out beside it, no door sequence (14 Nov 2026)")
        var speed: float=vehicle.current_speed
        advance(vehicle,.5,0)
        check(vehicle.current_speed>speed*.65 and vehicle.current_speed<speed,title+" release coasts with drag")
        advance(vehicle,3,0,0,true)
        check(absf(vehicle.current_speed)<.1,title+" service brakes stop vehicle")
        check(vehicle.safe_exit(game.player).ok,title+" stopped vehicle has a safe exit")
        advance(vehicle,2,-1)
        check(vehicle.current_speed< -1 and vehicle.road_physics.gear==-1,title+" S selects controlled reverse after stopping")
        var heading: Vector3=vehicle.travel_forward()
        advance(vehicle,1,-1,.4)
        check(vehicle.travel_forward().dot(heading.cross(Vector3.UP))<0,title+" reverse steering changes heading in the correct direction")
        reset(vehicle)
        advance(vehicle,3,1)
        var before: Vector3=vehicle.travel_forward()
        advance(vehicle,1.5,1,.4)
        check(vehicle.travel_forward().dot(before.cross(Vector3.UP))>0,title+" D steers right through tire forces")
        check(absf(vehicle.road_physics.steering_angle)>.01,title+" front steering animation follows controls")
        var pause_pose: Transform3D=vehicle.global_transform
        var pause_velocity: Vector3=vehicle.road_physics.velocity
        vehicle.occupied=false
        advance(vehicle,1,1,1)
        check(vehicle.global_transform.is_equal_approx(pause_pose) and vehicle.road_physics.velocity==pause_velocity,title+" overlay pause retains position and momentum")
        vehicle.global_transform=original
        vehicle.road_physics.reset()
    check(speeds.Car>speeds.Bus*1.5 and speeds.Police_Car>speeds.Truck,"mass/engine profiles give cars and heavy vehicles distinct handling")
    var car=game.apartment.get_node("Vehicles/Car")
    var original: Transform3D=car.global_transform
    reset(car)
    advance(car,3,1)
    var speed_before: float=car.current_speed
    advance(car,.1,-1)
    check(car.current_speed>0 and car.current_speed<speed_before,"S brakes before changing from drive to reverse")
    var physics=car.road_physics
    # Path steering (21 Nov 2026): a held key keeps turning at speed, within the grip limit.
    physics.steer_input=1
    check(absf(physics.steer_curvature(car,0,1,16,16,.65))<absf(physics.steer_curvature(car,0,1,16,16,.95)),"lower-grip surfaces reduce cornering")
    physics.steer_input=0
    reset(car)
    while car.current_speed<16: advance(car,1.0/60,1)
    advance(car,2,.3,1)
    var turn_radius: float=absf(car.current_speed/physics.yaw_velocity) if absf(physics.yaw_velocity)>.001 else INF
    check(turn_radius<30 and turn_radius>15,"held D at 16 m/s keeps turning on a 15-30 m circle (%.1f m)"%turn_radius)
    check(absf(car.current_speed*physics.yaw_velocity)<=car.max_lateral_acceleration+.3,"cornering stays within max_lateral_acceleration")
    reset(car)
    advance(car,1.5,.4)
    advance(car,2,.4,1)
    turn_radius=absf(car.current_speed/physics.yaw_velocity) if absf(physics.yaw_velocity)>.001 else INF
    check(turn_radius<8,"full lock at low speed turns on a tight circle (%.1f m)"%turn_radius)
    var positions: Array[Vector3]=[]
    for hz in [30,60,120]:
        reset(car)
        advance(car,4,1,.25,false,hz)
        positions.append(car.global_position)
    check(positions[0].distance_to(positions[2])<.03 and positions[1].distance_to(positions[2])<.03,"driving trajectory agrees at 30, 60 and 120 Hz")
    reset(car)
    car.drive_step(.2,1,.25,0)
    var long_frame: Vector3=car.global_position
    reset(car)
    advance(car,.2,1,.25,false,120)
    check(car.global_position.distance_to(long_frame)<.01,"long frames consume elapsed driving time")
    # Offset posts miss the old bumper rays; full body sweeps must stop the corner.
    reset(car)
    var wall=game.box("Corner post fixture",Vector3.ZERO,Vector3(.2,4,.2),Color.WHITE,"",true)
    wall.global_position=Vector3(994,1.5,1000.95)
    await physics_frame
    await physics_frame
    advance(car,4,1)
    print("FRONT POST root ",car.global_position," speed ",car.current_speed)
    check(car.global_position.x>996 and absf(car.current_speed)<.1,"front corner sweep prevents tunneling into an offset post")
    check(car.can_rotate(car.global_transform,car.road_physics.ground_exclusions),"stopped body stays outside the obstacle")
    wall.free()
    reset(car)
    var rear=game.box("Rear corner fixture",Vector3.ZERO,Vector3(.2,4,.2),Color.WHITE,"",true)
    rear.global_position=Vector3(1006,1.5,1000.95)
    await physics_frame
    await physics_frame
    advance(car,5,-1)
    check(car.global_position.x<1004 and absf(car.current_speed)<.1,"rear corner sweep also protects reversing")
    rear.free()
    reset(car)
    var swing=game.box("Steering swing fixture",Vector3.ZERO,Vector3(.2,3,.2),Color.WHITE,"",true)
    swing.global_position=Vector3(998.8,1.5,998.3)
    await physics_frame
    await physics_frame
    advance(car,.1,0,0,true)
    var turned: Transform3D=car.global_transform
    turned.basis=Basis(Vector3.UP,-.65).scaled(Vector3.ONE*1.3)
    check(not car.can_rotate(turned,car.road_physics.ground_exclusions),"rotation checks detect side-body swing into an obstacle")
    swing.free()
    pad.free()
    var small=game.box("Road edge fixture",Vector3.ZERO,Vector3(8,.4,8),Color.WHITE,"",true)
    small.global_position=Vector3(1200,8,1000)
    reset(car,Vector3(1200,8.45,1000))
    car.road_physics.has_parked_pose=false
    await physics_frame
    await physics_frame
    advance(car,5,1)
    check(not car.road_physics.supported and car.road_physics.velocity.y< -1,"leaving the road loses wheel support and falls under gravity")
    var air_exit: Dictionary=car.safe_exit(game.player)
    check(air_exit.ok and not air_exit.door,"airborne exit lets BonBon out beside the car (14 Nov 2026)")
    car.drive_step(1.0/60,0,0,0,true)
    check(car.global_position.distance_to(Vector3(1200,9.05,1000))<.1,"R recovers unsupported vehicle to its initial parking point")
    small.free()
    car.global_transform=original
    car.occupied=false
    car.road_physics.reset()
    print("ROAD PHYSICS: ",checks," checks; ",failures.size()," failures; speeds ",speeds)
    quit(0 if failures.is_empty() else 1)
