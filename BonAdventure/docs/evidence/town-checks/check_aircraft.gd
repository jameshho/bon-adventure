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
    # The flight model through fly_step() (rewritten 23 Nov 2026: a steady arcade model); the
    # player's controls and buttons have their own check, check_easy_flying.gd.
    await physics_frame
    await physics_frame
    check(game.driveable_vehicles.has(plane),"registered through existing vehicle controller")
    check(game.vocabulary.get("airplane")=="el avión" and game.vocabulary_categories.get("airplane")=="Vehicles","airplane vocabulary")
    check(absf(plane.global_basis.get_scale().x-1.3*plane.SIZE)<.01,"the smaller plane: SIZE of the saved model")
    check(plane.can_rotate(plane.global_transform),"parked aircraft envelope is clear")
    check(plane.ground_contact(),"runway supports wheels")
    var pick:=PhysicsRayQueryParameters3D.create(plane.to_global(Vector3(-4,2,-1)),plane.to_global(Vector3(0,2,-1)))
    var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(pick)
    check(not hit.is_empty() and hit.collider.get_meta("root",null)==plane,"aircraft physics target resolves to vocabulary root")
    game.player.global_position=plane.to_global(Vector3(-2.5,.1,-1.1))
    var old_layers: int=game.player.collision_layer
    var walk_scale: float=game.player.visual.global_basis.get_scale().x
    check(game.toggle_vehicle() and game.active_vehicle==plane,"E boards at cabin entrance")
    check(game.player.visual.visible,"pig remains visible while boarding")
    check(not plane.safe_exit(game.player).ok,"exit denied during boarding")
    for i in range(150):
        plane.fly_step(1.0/60,0,0,0)
        game.player._physics_process(1.0/60)
    check(plane.boarding_progress==1,"boarding completes")
    check(game.player.visual.global_position.distance_to(plane.get_node("PilotSeat").global_position)<.02,"pig reaches cockpit seat")
    check(absf(game.player.visual.global_basis.get_scale().x-plane.SIZE)<.05,"BonBon sits at the plane's size")
    check(game.player.collision_layer==0,"player collision disabled while seated")
    check(plane.safe_exit(game.player).ok,"stopped aircraft has a safe exit")
    # Take-off: up held from a standstill, well within the short runway.
    var start: Vector3=plane.global_position
    var lift_off:=-1.0
    for i in range(60*10):
        await physics_frame
        plane.fly_step(1.0/60,1,0,0)
        if lift_off<0 and not plane.landed: lift_off=Vector2(plane.global_position.x-start.x,plane.global_position.z-start.z).length()
        if plane.global_position.y>start.y+8 or plane.crashed: break
    print("TAKEOFF speed=",plane.airspeed," after ",lift_off," m; delta=",plane.global_position-start," crashed=",plane.crashed)
    check(lift_off>0 and lift_off<45 and plane.global_position.y>start.y+8 and not plane.crashed,"takes off within 45 m of runway")
    check(plane.safe_exit(game.player).ok and not plane.safe_exit(game.player).door,"airborne exit lets BonBon out beside the wing (14 Nov 2026)")
    # Steadiness (user, 23 Nov 2026: it wobbled up and down by itself): a minute hands off, high up.
    plane.global_transform=plane.home_pose
    plane.global_position+=Vector3.UP*100
    plane.flight_velocity=plane.travel_forward()*plane.CRUISE
    plane.airspeed=plane.CRUISE
    plane.landed=false
    plane.pitch=.04
    plane.bank=0
    plane.turn_rate=0
    var y0: float=plane.global_position.y
    var worst_vs:=0.0
    var worst_pitch:=0.0
    for i in range(60*60):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0)
        worst_vs=maxf(worst_vs,absf(plane.flight_velocity.y))
        worst_pitch=maxf(worst_pitch,absf(plane.pitch-.04))
        if plane.crashed: break
    print("STEADY drift=",plane.global_position.y-y0," worst vs=",worst_vs," worst pitch=",worst_pitch," speed=",plane.airspeed)
    check(not plane.crashed and absf(plane.global_position.y-y0)<.05 and worst_vs<.01 and worst_pitch<.01 and absf(plane.airspeed-plane.CRUISE)<.01,"hands off: a minute of level flight with no bobbing")
    # Flying high, the view reaches further (vehicle_controls.gd update_flight_view(), 23 Nov 2026).
    var VC=preload("res://scripts/core/vehicle_controls.gd")
    var RC=preload("res://scripts/world/render_culling.gd")
    var camera: Camera3D=game.player.camera
    var base_far: float=camera.far
    for i in range(60): VC.update_flight_view(game,.1)
    var height: float=plane.global_position.y-game.apartment.global_position.y
    var expected: float=minf(VC.FLIGHT_VIEW_MAX,RC.VIEW_DISTANCE+height*VC.FLIGHT_VIEW_PER_METRE)
    print("VIEW at ",height," m: far ",camera.far," (expected ",expected,"), fog end ",game.day_night.environment.fog_depth_end)
    check(is_equal_approx(base_far,RC.VIEW_DISTANCE) and absf(camera.far-expected)<1 and camera.far>RC.VIEW_DISTANCE+100 and is_equal_approx(game.day_night.environment.fog_depth_end,camera.far),"flying high: the view and its fog reach further")
    # Up, then let go: the climb eases in and out once, never back below zero (no bounce).
    var climb_y: float=plane.global_position.y
    var lowest_after:=INF
    for i in range(60*8):
        await physics_frame
        plane.fly_step(1.0/60,1 if i<60*3 else 0,0,0)
        if i>=60*3: lowest_after=minf(lowest_after,plane.flight_velocity.y)
    var pitch_while_level: float=plane.pitch
    print("CLIMB rose ",plane.global_position.y-climb_y," m; lowest vs after letting go ",lowest_after)
    check(plane.global_position.y-climb_y>8 and lowest_after>-.01 and absf(plane.flight_velocity.y)<.2,"let go after climbing: levels off without dipping")
    check(absf(pitch_while_level-.04)<.05,"nose returns level")
    # Nose pitch follows the climb angle, the same every time.
    for i in range(60*4):
        await physics_frame
        plane.fly_step(1.0/60,1,0,0)
    check(absf(plane.pitch-(atan2(plane.flight_velocity.y,plane.airspeed)+.04))<.02 and plane.pitch>.15,"climbing, the nose shows the climb angle")
    for i in range(60*4):
        await physics_frame
        plane.fly_step(1.0/60,-1,0,0)
    check(plane.pitch<-.05,"descending, the nose points down")
    # A banked right turn.
    var heading: Vector3=plane.travel_forward()
    for i in range(120):
        await physics_frame
        plane.fly_step(1.0/60,0,1,0)
    check(plane.global_basis.orthonormalized().get_euler().z<-.1,"D banks right")
    check(plane.travel_forward().dot(heading.cross(Vector3.UP))>0,"bank produces a right turn")
    for i in range(60*4):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0)
    check(absf(plane.bank)<.03,"let go: wings level")
    # Nobody aboard (exit in flight): glides down slowly, never faster than a landing.
    plane.occupied=false
    plane.coasting=true
    var glide_height: float=plane.global_position.y
    var fastest_sink:=0.0
    for i in range(60*10):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0,false)
        fastest_sink=minf(fastest_sink,plane.flight_velocity.y)
    print("GLIDE height ",glide_height," -> ",plane.global_position.y," fastest sink ",fastest_sink," speed ",plane.airspeed)
    check(plane.global_position.y<glide_height-10 and fastest_sink>-plane.CRASH_SINK and plane.engine_power<.01,"unpowered, it glides down slowly")
    plane.coasting=false
    plane.occupied=true
    # Landing on the runway: down held from 6 m at approach speed.
    plane.global_transform=plane.home_pose
    plane.global_position+=Vector3.UP*6
    plane.flight_velocity=plane.travel_forward()*plane.SLOW
    plane.airspeed=plane.SLOW
    plane.landed=false
    for i in range(60*30):
        await physics_frame
        plane.fly_step(1.0/60,-1,0,0)
        if plane.crashed: break
        if plane.ground_contact() and plane.current_speed<.1: break
    print("LANDING speed=",plane.current_speed," ground=",plane.ground_contact()," crashed=",plane.crashed," rolled ",plane.global_position.distance_to(plane.home_pose.origin)," m")
    check(not plane.crashed and plane.ground_contact() and plane.current_speed<.6,"landing and braking on the runway")
    # E starts the door / climb-out sequence (vehicle doors, 5 Nov 2026); it ends with exit_finished.
    check(game.toggle_vehicle(),"E starts disembarking after landing")
    for i in range(roundi(plane.boarding_duration*1.2*60)+2):
        plane.fly_step(1.0/60,0,0,0)
        game.player._physics_process(1.0/60)
    check(game.active_vehicle==null and game.player.riding_vehicle==null,"E disembarks after landing")
    for i in range(60): VC.update_flight_view(game,.1)
    check(is_equal_approx(camera.far,RC.VIEW_DISTANCE) and is_equal_approx(game.day_night.environment.fog_depth_end,RC.VIEW_DISTANCE),"out of the plane: the usual 130 m view again")
    check(game.player.collision_layer==old_layers and game.player.visual.visible and absf(game.player.visual.global_basis.get_scale().x-walk_scale)<.01,"walking collision, full size and visible pig restored")
    check(plane.engine_power==0,"engine shuts down on disembarking")
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
    plane.landed=false
    plane.global_position+=Vector3.UP*.5
    plane.flight_velocity=plane.travel_forward()*12
    plane.airspeed=12
    for i in range(90):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0)
        if plane.crashed: break
    check(plane.crashed,"high-speed wing impact stops aircraft and offers recovery")
    wall.free()
    for i in range(60*3): plane.fly_step(1.0/60,0,0,0)
    check(not plane.crashed and plane.global_position.distance_to(plane.home_pose.origin)<.01,"back on the runway after a crash")
    var position: Vector3=plane.global_position
    plane.occupied=false
    plane.fly_step(1.0/60,1,1,1)
    check(plane.global_position==position,"unoccupied parked aircraft stays still")
    print("AIRCRAFT: ",checks," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
