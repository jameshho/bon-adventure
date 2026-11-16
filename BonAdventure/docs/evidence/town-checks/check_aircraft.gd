extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures.append(label)
        push_error("AIRCRAFT: "+label)
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for vehicle in game.driveable_vehicles: vehicle.set_physics_process(false)
    var plane=game.apartment.get_node("Vehicles/Turboprop")
    # The expert controls (F flaps); easy flying has its own check, docs/check_easy_flying.gd.
    DriveableVehicle.easy_flying=false
    await physics_frame
    await physics_frame
    check(game.driveable_vehicles.has(plane),"registered through existing vehicle controller")
    check(game.vocabulary.get("airplane")=="el avión" and game.vocabulary_categories.get("airplane")=="Vehicles","airplane vocabulary")
    check(plane.can_rotate(plane.global_transform),"parked aircraft envelope is clear")
    check(plane.ground_contact(),"runway supports wheels")
    var pick:=PhysicsRayQueryParameters3D.create(plane.to_global(Vector3(-4,2,-1)),plane.to_global(Vector3(0,2,-1)))
    var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(pick)
    check(not hit.is_empty() and hit.collider.get_meta("root",null)==plane,"aircraft physics target resolves to vocabulary root")
    game.player.global_position=plane.to_global(Vector3(-2.5,.1,-1.1))
    var old_layers: int=game.player.collision_layer
    check(game.toggle_vehicle() and game.active_vehicle==plane,"E boards at cabin entrance")
    check(game.player.visual.visible,"pig remains visible while boarding")
    check(not plane.safe_exit(game.player).ok,"exit denied during boarding")
    for i in range(150):
        plane.aircraft_step(1.0/60,0,0,0,0,false,false)
        game.player._physics_process(1.0/60)
    check(plane.boarding_progress==1,"boarding completes")
    check(game.player.visual.global_position.distance_to(plane.get_node("PilotSeat").global_position)<.02,"pig reaches cockpit seat")
    check(game.player.collision_layer==0,"player collision disabled while seated")
    var flap_key:=InputEventKey.new()
    flap_key.physical_keycode=KEY_F
    flap_key.pressed=true
    plane._unhandled_input(flap_key)
    check(plane.flaps==1,"F selects landing flaps")
    plane._unhandled_input(flap_key)
    check(plane.flaps==0,"F retracts flaps")
    plane._unhandled_input(flap_key)
    check(plane.safe_exit(game.player).ok,"stopped aircraft has a safe exit")
    var start: Vector3=plane.global_position
    var lifted:=false
    for i in range(900):
        await physics_frame
        plane.aircraft_step(1.0/60,1, .45 if plane.airspeed>21 and plane.global_position.y<start.y+12 else 0.0,0,0,false,plane.global_position.y>start.y+12)
        if plane.global_position.y>start.y+4:
            lifted=true
            break
        if plane.crashed: break
    print("TAKEOFF speed=",plane.airspeed," delta=",plane.global_position-start," crashed=",plane.crashed)
    check(lifted and not plane.crashed,"takeoff from existing short runway")
    check(plane.safe_exit(game.player).ok and not plane.safe_exit(game.player).door,"airborne exit lets BonBon out beside the wing (14 Nov 2026)")
    # Exercise a sustained banked turn and then release controls with level assist.
    plane.global_transform=plane.home_pose
    plane.global_position+=Vector3.UP*100
    plane.flight_velocity=plane.travel_forward()*32
    plane.airspeed=32
    plane.flaps=0
    plane.throttle=.55
    plane.engine_power=.55
    plane.angle_of_attack=0
    plane.pitch_rate=0
    plane.roll_rate=0
    var heading: Vector3=plane.travel_forward()
    for i in range(120):
        await physics_frame
        plane.aircraft_step(1.0/60,0,0,.4,0,false,false)
    check(plane.global_basis.orthonormalized().get_euler().z<-.1,"D banks right")
    check(plane.travel_forward().dot(heading.cross(Vector3.UP))>0,"bank produces a right turn")
    for i in range(1800):
        await physics_frame
        plane.aircraft_step(1.0/60,0,0,0,0,false,true)
        if plane.crashed: break
    check(not plane.crashed and plane.global_position.is_finite() and absf(plane.rotation.z)<.08,"30 seconds of stable assisted flight")
    plane.flight_velocity=plane.travel_forward()*25
    plane.airspeed=25
    var level_speed: float=plane.airspeed
    plane.throttle=0
    plane.engine_power=0
    var glide_height: float=plane.global_position.y
    for i in range(1200):
        await physics_frame
        plane.aircraft_step(1.0/60,0,0,0,0,false,true)
        if plane.crashed: break
    var energy_before: float=.5*level_speed*level_speed+9.81*glide_height
    var energy_after: float=.5*plane.airspeed*plane.airspeed+9.81*plane.global_position.y
    print("GLIDE speed ",level_speed," -> ",plane.airspeed," height ",glide_height," -> ",plane.global_position.y," energy ",energy_before," -> ",energy_after)
    check(energy_after<energy_before and plane.airspeed>8 and plane.global_position.y<glide_height,"power-off aircraft loses energy and glides rather than hovering")
    # Aerodynamic probes: speed squared lift, drag, and loss of lift beyond stall.
    plane.global_basis=Basis.IDENTITY.scaled(Vector3.ONE*1.3)
    plane.flaps=0
    plane.airspeed=30
    var slow: Vector3=plane.aerodynamic_force(Vector3(0,0,-15))
    var fast: Vector3=plane.aerodynamic_force(Vector3(0,0,-30))
    check(fast.y>slow.y*3.9 and fast.z>0,"lift scales with speed squared; drag opposes velocity")
    plane.rotation.x=.2
    var attached: Vector3=plane.aerodynamic_force(Vector3(0,0,-30))
    plane.rotation.x=.7
    var stalled_force: Vector3=plane.aerodynamic_force(Vector3(0,0,-30))
    check(plane.stalled and stalled_force.y<attached.y,"high angle of attack stalls wing")
    # Controlled landing on the runway at modest forward speed.
    plane.global_transform=plane.home_pose
    plane.global_position+=Vector3.UP*1.5
    plane.flight_velocity=plane.travel_forward()*8+Vector3.DOWN
    plane.throttle=0
    plane.engine_power=0
    plane.flaps=1
    plane.angle_of_attack=0
    plane.pitch_rate=0
    plane.roll_rate=0
    for i in range(360):
        await physics_frame
        plane.aircraft_step(1.0/60,0,0,0,0,true,false)
        if plane.crashed: break
        if plane.ground_contact() and plane.current_speed<.1: break
    check(not plane.crashed and plane.ground_contact() and plane.current_speed<.6,"landing and wheel braking")
    print("LANDING speed=",plane.current_speed," ground=",plane.ground_contact()," crashed=",plane.crashed)
    # E starts the door / climb-out sequence (vehicle doors, 5 Nov 2026); it ends with exit_finished.
    check(game.toggle_vehicle(),"E starts disembarking after landing")
    for i in range(roundi(plane.boarding_duration*1.2*60)+2):
        plane.aircraft_step(1.0/60,0,0,0,0,true,false)
        game.player._physics_process(1.0/60)
    check(game.active_vehicle==null and game.player.riding_vehicle==null,"E disembarks after landing")
    check(game.player.collision_layer==old_layers and game.player.visual.visible,"walking collision and visible pig restored")
    check(plane.throttle==0 and plane.engine_power==0,"engine shuts down on disembarking")
    # Sweep the whole wing into an obstacle, not merely the fuselage center.
    plane.recover()
    var wall:=StaticBody3D.new()
    game.add_child(wall)
    wall.global_position=plane.to_global(Vector3(5,3.2,-5))
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new()
    shape.size=Vector3(1,8,1)
    collision.shape=shape
    wall.add_child(collision)
    await physics_frame
    await physics_frame
    check(plane.flight_fraction(plane.travel_forward()*10)<1,"wingtip sweep catches obstacle")
    plane.occupied=true
    plane.flight_velocity=plane.travel_forward()*12
    for i in range(90):
        await physics_frame
        plane.aircraft_step(1.0/60,0,0,0,0,false,false)
        if plane.crashed: break
    check(plane.crashed,"high-speed wing impact stops aircraft and offers recovery")
    wall.free()
    plane.occupied=true
    plane.aircraft_step(1.0/60,0,0,0,0,false,true)
    check(not plane.crashed and plane.global_position.distance_to(plane.home_pose.origin)<.01,"R recovers safely to runway")
    var position: Vector3=plane.global_position
    plane.occupied=false
    plane.aircraft_step(1.0/60,1,1,1,1,false,false)
    check(plane.global_position==position,"unoccupied or overlay-paused aircraft stays still")
    print("AIRCRAFT: ",checks," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
