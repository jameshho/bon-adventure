extends SceneTree
var game
var heli:DriveableVehicle
var checks:Array[String]=[]
var failures:Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok:bool,label:String):
    checks.append(("PASS " if ok else "FAIL ")+label)
    if not ok: failures.append(label)
func reset_flight():
    heli.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(0,70,0))
    heli.flight_velocity=Vector3.ZERO
    heli.yaw_velocity=0
    heli.wind_clock=0
    heli.occupied=true
func run():
    root.size=Vector2i(1100,700)
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    game.player.visible=false
    game.hud.visible=false
    heli=game.apartment.get_node("Buildings/Hospital/HospitalHelipad/Helicopter")
    heli.set_process(false)
    heli.set_physics_process(false)
    await physics_frame
    await physics_frame
    reset_flight()
    for i in range(240): heli.drive_step(1.0/60,0,0,0)
    check(heli.global_position.x>0.5 and heli.global_position.x<3,"Hands-off hover develops gentle bounded wind drift")
    check(absf(heli.global_position.y-70)<.01,"Wind does not cause uncontrolled altitude loss")
    for i in range(240): heli.drive_step(1.0/60,0,0,0,true)
    var anchored:=heli.global_position
    for i in range(120): heli.drive_step(1.0/60,0,0,0,true)
    check(heli.global_position.distance_to(anchored)<.01,"Held hover assist arrests drift")
    for i in range(120): heli.drive_step(1.0/60,0,0,0)
    check(heli.global_position.distance_to(anchored)>.15,"Releasing hover assist restores natural drift")
    reset_flight()
    for i in range(180): heli.drive_step(1.0/60,1,0,0)
    var speed_before:=heli.current_speed
    var coast_start:=heli.global_position
    for i in range(60): heli.drive_step(1.0/60,0,0,0)
    check(heli.current_speed>speed_before*.5 and heli.current_speed<speed_before,"Released cyclic retains decaying momentum")
    check(heli.global_position.distance_to(coast_start)>5,"Aircraft coasts instead of stopping abruptly")
    for i in range(90): heli.drive_step(1.0/60,-1,0,0)
    check(heli.flight_velocity.dot(heli.travel_forward())<0,"Opposite cyclic can brake and reverse")
    reset_flight()
    heli.drive_step(1.0/60,0,1,0)
    check(heli.yaw_velocity>0 and heli.yaw_velocity<.15,"Yaw starts gradually")
    for i in range(60): heli.drive_step(1.0/60,0,1,0)
    var yaw_rate:=heli.yaw_velocity
    heli.drive_step(1.0/60,0,0,0)
    check(heli.yaw_velocity>yaw_rate*.8 and heli.yaw_velocity<yaw_rate,"Yaw retains brief momentum after release")
    for i in range(120): heli.drive_step(1.0/60,0,0,0,true)
    check(absf(heli.yaw_velocity)<.001,"Yaw settles without indefinite spinning")
    var positions:Array[Vector3]=[]
    for hz in [30,120]:
        reset_flight()
        for i in range(hz*4): heli.drive_step(1.0/hz,0,0,0)
        positions.append(heli.global_position)
    check(positions[0].distance_to(positions[1])<.03,"Wind/coasting remains consistent at 30 and 120 Hz")
    reset_flight()
    var wall=game.box("Wind collision wall",Vector3.ZERO,Vector3(.2,20,20),Color.WHITE,"",true)
    wall.global_position=Vector3(6.5,73,0)
    await physics_frame
    await physics_frame
    for i in range(900): heli.drive_step(1.0/60,0,0,0)

    check(heli.global_position.x<1.3,"Wind-driven drift respects the full rotor collision envelope")
    wall.free()
    var pad=game.box("Parking fixture",Vector3.ZERO,Vector3(40,.4,40),Color.WHITE,"",true)
    pad.global_position=Vector3(0,50,0)
    reset_flight()
    heli.global_position=Vector3(0,54,0)
    await physics_frame
    await physics_frame
    for i in range(240): heli.drive_step(1.0/60,0,0,-1,true)
    var parked:=heli.global_transform
    for i in range(180): heli.drive_step(1.0/60,1,1,0)
    check(heli.global_position.distance_to(parked.origin)<.01 and heli.global_basis.is_equal_approx(parked.basis),"Wheels stay planted despite wind and cyclic while parked")
    check(heli.safe_exit(game.player).ok,"Stable grounded exit remains available")
    for i in range(120): heli.drive_step(1.0/60,0,0,1,true)
    check(heli.global_position.y>parked.origin.y+2,"Collective releases ground brake for takeoff")
    pad.free()
    if DisplayServer.get_name()!="headless":
        reset_flight()
        heli.global_position=Vector3(0,29,65)
        heli.rotor_power=1
        var camera=Camera3D.new()
        root.add_child(camera)
        camera.current=true
        for i in range(120):
            heli.drive_step(1.0/60,1,.5,0)
            heli.update_rotors(1.0/60)
            camera.global_position=heli.global_position+Vector3(12,6,-16)
            camera.look_at(heli.global_position+Vector3.UP*2)
            await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/guides/helicopter_inertia/flight.png")
    FileAccess.open("res://docs/guides/helicopter_inertia/test_results.txt",FileAccess.WRITE).store_string("\n".join(checks)+"\n")
    print("HELICOPTER INERTIA: ",checks.size()," checks, ",failures.size()," failures")
    for f in failures: print("FAIL ",f)
    quit(0 if failures.is_empty() else 1)
