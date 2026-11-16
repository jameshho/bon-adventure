extends SceneTree
var game
var heli:DriveableVehicle
var checks:Array[String]=[]
var failures:Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok:bool,label:String):
    checks.append(("PASS " if ok else "FAIL ")+label)
    if not ok: failures.append(label)
func run():
    root.size=Vector2i(960,540)
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
    heli.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(0,70,0))
    heli.occupied=true
    var main_before:Basis=heli.main_rotor.basis
    var tail_before:Basis=heli.tail_rotor.basis
    for i in range(90): heli.update_rotors(1.0/60)
    check(heli.rotor_power>.9,"Rotor spools up after boarding")
    check(not heli.main_rotor.basis.is_equal_approx(main_before),"Original main rotor actually rotates")
    check(not heli.tail_rotor.basis.is_equal_approx(tail_before),"Original tail rotor actually rotates")
    check(heli.rotor_blur.visible,"Subtle rotor disk visible at flight RPM")
    check(heli.main_rotor.basis.y.is_equal_approx(main_before.y),"Main rotor spins around its mast")
    check(heli.tail_rotor.basis.x.is_equal_approx(tail_before.x),"Tail rotor spins around its axle")
    var height:float=heli.global_position.y
    for i in range(120): heli.drive_step(1.0/60,1,0,0)
    check(heli.global_rotation.x<deg_to_rad(-10),"Forward flight pitches nose down")
    check(absf(heli.global_position.y-height)<.01,"Pitch does not create unwanted altitude drift")
    check(absf(heli.travel_forward().y)<.001,"Flight heading remains horizontal")
    var yaw:float=heli.global_rotation.y
    for i in range(60): heli.drive_step(1.0/60,1,1,0)
    check(heli.global_rotation.z<deg_to_rad(-8),"Right turn banks the fuselage right")
    check(absf(angle_difference(yaw,heli.global_rotation.y))>.4,"Banking turn changes heading")
    for i in range(36): heli.drive_step(1.0/60,0,0,0)
    check(heli.global_rotation.x>0,"Braking raises the nose")
    for i in range(300): heli.drive_step(1.0/60,0,0,0,true)
    check(absf(heli.global_rotation.x)<.01 and absf(heli.global_rotation.z)<.01,"Hover assist settles to a level hover")
    for i in range(90): heli.drive_step(1.0/60,-1,-1,0)
    check(heli.global_rotation.x>deg_to_rad(8),"Reverse flight pitches nose up")
    check(heli.global_rotation.z>deg_to_rad(8),"Left turn banks left")
    # The tilted rotor's actual swept disk must still stop against geometry.
    var wall=game.box("Tilt collision fixture",Vector3.ZERO,Vector3(20,20,.2),Color.WHITE,"",true)
    wall.global_position=heli.global_position+Vector3(0,0,-12)
    await physics_frame
    await physics_frame
    check(heli.flight_fraction(Vector3(0,0,-20))<.7,"Tilted helicopter collision envelope still blocks walls")
    wall.free()
    # Tail-rotor envelope is present independently of visual animation phases.
    check(heli.flight_hulls[-1].center.is_equal_approx(Vector3(.27,2.18,4.72)),"Tail rotor has its own protective swept volume")
    var pad=game.box("Attitude landing pad",Vector3.ZERO,Vector3(30,.4,30),Color.WHITE,"",true)
    pad.global_position=Vector3(0,50,0)
    heli.global_transform=Transform3D(Basis.from_euler(Vector3(-.2,0,-.2)).scaled(Vector3.ONE*1.3),Vector3(0,54,0))
    heli.flight_velocity=Vector3.ZERO
    await physics_frame
    await physics_frame
    for i in range(240): heli.drive_step(1.0/60,0,0,-1)
    check(absf(heli.global_rotation.x)<.03 and absf(heli.global_rotation.z)<.03,"Landing approach levels both skids")
    check(heli.ground_contact(),"Aircraft lands safely after a banked approach")
    pad.free()
    heli.occupied=false
    heli.landed=true
    var power:float=heli.rotor_power
    heli.update_rotors(.5)
    check(heli.rotor_power>0 and heli.rotor_power<power,"Rotor coasts down gradually after landing/exit")
    for i in range(300): heli.update_rotors(1.0/60)
    check(heli.rotor_power==0 and not heli.rotor_blur.visible,"Parked helicopter rotors stop")
    if DisplayServer.get_name()!="headless": await capture()
    var file=FileAccess.open("res://docs/evidence/helicopter_motion/test_results.txt",FileAccess.WRITE)
    file.store_string("\n".join(checks)+"\nFailures: "+str(failures.size())+"\n")
    print("HELICOPTER MOTION: ",checks.size()," checks, ",failures.size()," failures")
    for failure in failures: print("FAIL ",failure)
    quit(0 if failures.is_empty() else 1)

func capture():
    var camera:=Camera3D.new()
    root.add_child(camera)
    camera.current=true
    heli.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(0,28,65))
    heli.flight_velocity=Vector3.ZERO
    heli.rotor_power=1
    heli.occupied=true
    heli.landed=false
    for i in range(90): heli.drive_step(1.0/60,1,.65,0)
    camera.global_position=heli.global_position+Vector3(12,6,-16)
    camera.look_at(heli.global_position+Vector3.UP*2)
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/helicopter_motion/banked_flight.png")
    for i in range(45):
        heli.drive_step(1.0/30,1,.65,0)
        heli.update_rotors(1.0/30)
        camera.global_position=heli.global_position+Vector3(12,6,-16)
        camera.look_at(heli.global_position+Vector3.UP*2)
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/helicopter_motion/frame_%03d.png"%i)
