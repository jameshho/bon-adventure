extends SceneTree
var game
var heli
var failures: Array[String]=[]
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures.append(label)
        push_error("HELICOPTER: "+label)
func reset_airborne(power := 1.0) -> void:
    heli.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(500,90,500))
    heli.flight_velocity=Vector3.ZERO
    heli.current_speed=0
    heli.yaw_velocity=0
    heli.wind_clock=0
    heli.rotor_power=power
    heli.occupied=true
    heli.helicopter_physics.reset()
func advance(seconds: float,gas: float,steering: float,lift: float,assist := false,hz := 60) -> void:
    for i in range(roundi(seconds*hz)): heli.drive_step(1.0/hz,gas,steering,lift,assist)
func run():
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    for v in game.driveable_vehicles:
        v.set_physics_process(false)
        v.set_process(false)
    heli=game.apartment.get_node("Buildings/Hospital/HospitalHelipad/Helicopter")
    await physics_frame
    await physics_frame
    check(game.driveable_vehicles.has(heli),"original hospital helicopter remains registered")
    check(heli.ground_contact() and heli.can_rotate(heli.global_transform),"actual hospital pad supports a clear full-aircraft envelope")
    check(game.interaction.word_key(heli)=="helicopter","existing vocabulary root retained")
    var start: Transform3D=heli.global_transform
    heli.occupied=true
    advance(3,1,1,0)
    check(heli.global_transform.is_equal_approx(start),"grounded rotor spool-up does not slide or turn")
    check(heli.rotor_power>.99,"physical rotor governor reaches operating RPM")
    var rotor_before: Basis=heli.main_rotor.basis
    heli.update_rotors(.1)
    check(not heli.main_rotor.basis.is_equal_approx(rotor_before) and heli.rotor_blur.visible,"actual model rotor and blur animate at physical RPM")
    advance(4,0,0,1,true)
    print("HOSPITAL TAKEOFF ",heli.global_position-start.origin," v ",heli.flight_velocity)
    check(heli.global_position.y>start.origin.y+6,"collective takes off from the actual hospital pad")
    check(heli.safe_exit(game.player).ok and not heli.safe_exit(game.player).door,"airborne exit lets BonBon out clear of the rotor (14 Nov 2026)")
    reset_airborne(0)
    advance(.2,0,0,0)
    check(heli.flight_velocity.y< -1 and heli.global_position.y<90,"gravity acts when rotor RPM cannot support weight")
    var physics=heli.helicopter_physics
    physics.angular_velocity=Vector3.ZERO
    var low: Dictionary=physics.rotor_forces(Vector3.ZERO,18,5.265,.351,.17,Vector2.ZERO,0)
    var high: Dictionary=physics.rotor_forces(Vector3.ZERO,36,5.265,.351,.17,Vector2.ZERO,0)
    check(high.force.y>low.force.y*3.9,"rotor lift scales with RPM squared")
    var collective_high: Dictionary=physics.rotor_forces(Vector3.ZERO,36,5.265,.351,.22,Vector2.ZERO,0)
    check(collective_high.force.y>high.force.y,"collective blade pitch controls rotor thrust")
    var forward: Dictionary=physics.rotor_forces(Vector3.ZERO,36,5.265,.351,.17,Vector2(.04,0),0)
    var bank: Dictionary=physics.rotor_forces(Vector3.ZERO,36,5.265,.351,.17,Vector2(0,.04),0)
    check(forward.torque.x<0 and bank.torque.z<0,"differential blade pitch creates pitch and roll torque")
    var tail: Dictionary=physics.tail_forces(Vector3.ZERO,36,Vector3.ONE*1.3,.1)
    check(tail.force.x<0 and tail.torque.y<0,"tail rotor supplies lateral force and yaw torque")
    reset_airborne()
    advance(8,0,0,0,true)
    var hover_start: Vector3=heli.global_position
    advance(4,0,0,0,true)
    print("HOVER drift ",heli.global_position-hover_start," v ",heli.flight_velocity," tilt ",heli.global_rotation)
    check(absf(heli.global_position.y-hover_start.y)<.5,"hover collective balances gravity after settling")
    check(Vector2(heli.flight_velocity.x,heli.flight_velocity.z).length()<.25,"R cancels world drift and anti-torque side-force")
    reset_airborne()
    advance(4,1,0,0)
    check(heli.global_rotation.x<-.15 and heli.flight_velocity.dot(heli.travel_forward())>3,"W tilts the rotor and accelerates forward")
    var speed: float=heli.current_speed
    advance(.5,0,0,0)
    check(heli.current_speed>speed*.5,"release preserves momentum rather than snapping velocity")
    advance(5,0,0,0,true)
    check(heli.current_speed<.4,"hover assist brakes to a controlled hover")
    reset_airborne()
    var heading: Vector3=heli.travel_forward()
    advance(2,0,1,0)
    check(heli.global_rotation.z<-.15 and heli.travel_forward().dot(heading.cross(Vector3.UP))>0,"D banks and turns right through rotor/tail torque")
    reset_airborne()
    advance(2,0,-1,0)
    check(heli.global_rotation.z>.15 and heli.travel_forward().dot(heading.cross(Vector3.UP))<0,"A banks and turns left")
    var poses: Array[Vector3]=[]
    for hz in [30,60,120]:
        reset_airborne()
        advance(4,.5,.25,.2,false,hz)
        poses.append(heli.global_position)
    check(poses[0].distance_to(poses[2])<.05 and poses[1].distance_to(poses[2])<.05,"same flight trajectory at 30, 60 and 120 Hz")
    reset_airborne()
    heli.drive_step(.2,0,0,1,true)
    var long_frame: Vector3=heli.global_position
    reset_airborne()
    advance(.2,0,0,1,true,120)
    check(heli.global_position.distance_to(long_frame)<.01,"long frames consume elapsed physics time")
    reset_airborne()
    var wall=game.box("Rotor regression fixture",Vector3.ZERO,Vector3(.2,20,30),Color.WHITE,"",true)
    wall.global_position=Vector3(506.5,94,500)
    await physics_frame
    await physics_frame
    check(heli.flight_fraction(Vector3(10,0,0))<.15,"full main rotor disk catches a wall before the fuselage")
    # Repeated tiny pushes reproduce the old slow-wind penetration failure.
    for i in range(1500):
        var motion:=Vector3(.002,0,0)
        heli.global_position+=motion*heli.flight_fraction(motion)
    print("ROTOR WALL x=",heli.global_position.x)
    check(heli.global_position.x<501.2,"tiny repeated drift cannot creep a rotor through the wall")
    check(heli.can_rotate(heli.global_transform),"rotor remains outside the wall after repeated contact")
    wall.free()
    reset_airborne()
    var ceiling=game.box("Rotor ceiling fixture",Vector3.ZERO,Vector3(20,.2,20),Color.WHITE,"",true)
    ceiling.global_position=Vector3(500,95,500)
    await physics_frame
    await physics_frame
    check(heli.flight_fraction(Vector3.UP*2)<.5,"main rotor protects against overhead obstacles")
    var tilted: Transform3D=heli.global_transform
    tilted.basis=Basis(Vector3.FORWARD,.4).scaled(Vector3.ONE*1.3)
    check(not heli.can_rotate(tilted),"bank rotation cannot sweep rotor through a ceiling")
    ceiling.free()
    var tail_wall=game.box("Tail rotor fixture",Vector3.ZERO,Vector3(.5,2,.2),Color.WHITE,"",true)
    tail_wall.global_position=Vector3(500.351,92.834,507.8)
    await physics_frame
    await physics_frame
    var tail_query: PhysicsShapeQueryParameters3D=heli.hull_query(heli.flight_hulls[-1],heli.global_transform)
    tail_query.motion=Vector3(0,0,2)
    var tail_sweep: PackedFloat32Array=game.get_world_3d().direct_space_state.cast_motion(tail_query)
    check(tail_sweep[0]<.3,"tail rotor has an independent swept protective disk")
    tail_wall.free()
    var pad=game.box("Helicopter landing fixture",Vector3.ZERO,Vector3(70,.4,70),Color.WHITE,"",true)
    pad.global_position=Vector3(500,60,500)
    reset_airborne()
    heli.global_position=Vector3(500,66,500)
    heli.rotation.x=-.15
    heli.rotation.z=-.15
    await physics_frame
    await physics_frame
    advance(8,0,0,-.4,true)
    print("LANDING ",heli.global_position," supported ",heli.ground_contact()," v ",heli.flight_velocity)
    check(heli.ground_contact(),"tilted approach levels and lands on all three wheels")
    check(heli.safe_exit(game.player).ok,"landed helicopter has a safe capsule-checked exit")
    var parked: Transform3D=heli.global_transform
    advance(2,1,1,0)
    check(heli.global_transform.is_equal_approx(parked),"ground brake holds position and attitude against pilot inputs")
    heli.occupied=false
    advance(5,0,0,0)
    heli.update_rotors(.1)
    check(heli.rotor_power==0 and not heli.rotor_blur.visible,"physical rotor coasts down after grounded exit")
    heli.occupied=true
    advance(5,0,0,1,true)
    check(heli.global_position.y>parked.origin.y+5,"parked helicopter can spool up and take off again")
    var pause_pose: Transform3D=heli.global_transform
    var pause_velocity: Vector3=heli.flight_velocity
    heli.occupied=false
    advance(1,1,1,1)
    check(heli.global_transform.is_equal_approx(pause_pose) and heli.flight_velocity==pause_velocity,"blocking overlay pauses flight without losing momentum")
    pad.free()
    print("HELICOPTER PHYSICS: ",checks," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
