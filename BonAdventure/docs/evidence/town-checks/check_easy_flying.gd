extends SceneTree
## The flying controls (easy flying 14 Nov 2026; one set for every device 23 Nov 2026;
## docs/guides/aircraft.md#flying-controls): flies the turboprop with only up / down, the speed
## stick and turn through take-off, climb, faster / slower, a turn, level flight, descent and
## landing, takes off on the stick alone, checks the on-screen ▲ / ▼ Buttons show for both
## aircraft and hold the up / down input, and that the helicopter brakes to a hover when let go.
## Run with an isolated HOME (README "Verification"); writes no files.
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,label: String) -> void:
    checks+=1
    print(("PASS " if ok else "FAIL ")+label)
    if not ok:
        failures.append(label)
        push_error("EASY FLYING: "+label)
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for vehicle in game.driveable_vehicles: vehicle.set_physics_process(false)
    var touch=game.hud.ui_root.get_node("TouchControls")
    var plane=game.apartment.get_node("Vehicles/Turboprop")
    await physics_frame
    await physics_frame
    game.player.global_position=plane.to_global(Vector3(-2.5,.1,-1.1))
    check(game.toggle_vehicle() and game.active_vehicle==plane,"boards the plane")
    await check_flight_buttons(touch,"plane")
    var moved:=0.0
    while plane.boarding_progress<1:
        plane.fly_step(1.0/60,1,0,0)
        game.player._physics_process(1.0/60)
        moved=maxf(moved,plane.global_position.distance_to(plane.home_pose.origin))
    check(plane.landed and moved<.01 and plane.global_position.distance_to(plane.home_pose.origin)<.5,"holding up while boarding does not move the plane")
    var start: Vector3=plane.global_position
    var frames:=0
    # Up held: full power, lifts off by itself and climbs.
    while frames<60*40 and plane.global_position.y<start.y+60 and not plane.crashed:
        await physics_frame
        plane.fly_step(1.0/60,1,0,0)
        frames+=1
    print("CLIMB t=",frames/60.0," height=",plane.global_position.y-start.y," speed=",plane.airspeed)
    check(not plane.crashed and plane.global_position.y>start.y+60,"up alone takes off and climbs 60 m")
    # Let go: flies level.
    var level_y: float=plane.global_position.y
    for i in range(60*15):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0)
        if plane.crashed: break
    print("LEVEL drift=",plane.global_position.y-level_y," speed=",plane.airspeed," bank=",plane.rotation.z)
    check(not plane.crashed and absf(plane.global_position.y-level_y)<25 and plane.airspeed>14,"let go: holds height at cruise speed")
    # Turn right for 20 s: a full circle or so, without losing much height.
    var heading: Vector3=plane.travel_forward()
    var turned:=0.0
    var last: Vector3=heading
    var turn_y: float=plane.global_position.y
    for i in range(60*20):
        await physics_frame
        plane.fly_step(1.0/60,0,1,0)
        var now: Vector3=plane.travel_forward()
        turned+=Vector2(last.x,last.z).angle_to(Vector2(now.x,now.z))
        last=now
        if plane.crashed: break
    print("TURN degrees=",rad_to_deg(turned)," height change=",plane.global_position.y-turn_y," speed=",plane.airspeed)
    check(not plane.crashed and absf(turned)>PI*.75 and absf(plane.global_position.y-turn_y)<30 and plane.airspeed>14,"right turn without slowing or diving")
    for i in range(60*6):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0)
    check(absf(plane.global_basis.orthonormalized().get_euler().z)<.1,"let go: wings level again")
    # Stick forward: faster; stick back: slower; the height held either way (circling, so it
    # stays near the airport).
    level_y=plane.global_position.y
    var speeds:=[]
    for stick in [1.0,-1.0]:
        for i in range(60*10):
            await physics_frame
            plane.fly_step(1.0/60,0,1,stick)
            if plane.crashed: break
        speeds.append(plane.airspeed)
    print("SPEED forward=",speeds[0]," back=",speeds[1]," height change=",plane.global_position.y-level_y)
    check(not plane.crashed and speeds[0]>speeds[1]+5 and speeds[1]>10 and absf(plane.global_position.y-level_y)<25,"stick forward flies faster, back slower, at the same height")
    for i in range(60*6):
        await physics_frame
        plane.fly_step(1.0/60,0,0,0)
    # Final approach: 8 m up, 40 m before the parked spot (the runway is about 115 m long, with
    # the sea beyond), at approach speed; then down until stopped.
    plane.global_transform=plane.home_pose
    plane.global_position+=Vector3.UP*8-plane.travel_forward()*40
    plane.flight_velocity=plane.travel_forward()*14
    plane.airspeed=14
    plane.landed=false
    var threshold: Vector3=plane.home_pose.origin
    var touched:=false
    var touchdown_sink:=0.0
    for i in range(60*120):
        await physics_frame
        plane.fly_step(1.0/60,-1,0,0)
        if i%30==0 or plane.crashed: print("  approach t=",i/60.0," h=",plane.height_above_ground()," vy=",plane.flight_velocity.y," v=",plane.airspeed," pitch=",plane.pitch," bank=",plane.bank," landed=",plane.landed," crashed=",plane.crashed)
        if plane.crashed: break
        if plane.landed and not touched:
            touched=true
            print("TOUCHDOWN after ",plane.global_position.distance_to(threshold)," m, speed ",plane.airspeed)
        if touched and plane.current_speed<.3: break
    print("LANDING crashed=",plane.crashed," landed=",plane.landed," speed=",plane.current_speed," stopped ",plane.global_position.distance_to(threshold)," m from the threshold")
    check(not plane.crashed and touched and plane.current_speed<.6,"down alone descends, lands gently and brakes to a stop")
    # A crash returns the plane to the runway by itself.
    plane.crash()
    for i in range(60*3):
        plane.fly_step(1.0/60,0,0,0)
    check(not plane.crashed and plane.global_position.distance_to(plane.home_pose.origin)<.5,"after a crash the plane is back on the runway")
    # Stick forward alone on the runway: takes off and levels off about 20 m up.
    var runway_y: float=plane.global_position.y
    for i in range(60*45):
        await physics_frame
        plane.fly_step(1.0/60,0,0,1)
        if plane.crashed: break
    var rise: float=plane.global_position.y-runway_y
    print("STICK TAKE-OFF height=",rise," vy=",plane.flight_velocity.y," landed=",plane.landed)
    check(not plane.crashed and not plane.landed and rise>10 and rise<22 and absf(plane.flight_velocity.y)<2,"stick forward alone takes off and levels off about 15 m up")
    plane.reset_to_start()
    plane.occupied=false
    game.active_vehicle=null
    # Helicopter: climb, fly forward, let go -> hover.
    var heli=game.apartment.get_node_or_null("Buildings/Hospital/HospitalHelipad/Helicopter")
    if heli==null:
        for vehicle in game.driveable_vehicles:
            if vehicle.helicopter: heli=vehicle
    check(heli!=null,"helicopter found")
    if heli!=null:
        game.player.global_position=heli.global_position+Vector3(0,1,4)
        heli.reset_to_start()
        game.active_vehicle=heli
        heli.boarding_progress=1
        heli.occupied=true
        await check_flight_buttons(touch,"helicopter")
        for i in range(60*6):
            await physics_frame
            heli.drive_step(1.0/60,0,0,1,true)
        var y0: float=heli.global_position.y
        for i in range(60*4):
            await physics_frame
            heli.drive_step(1.0/60,1,0,0,false)
        var cruise: float=heli.current_speed
        # Easy: no stick input means the hover assist.
        for i in range(60*8):
            await physics_frame
            heli.drive_step(1.0/60,0,0,0,true)
        print("HELI climb=",y0," cruise=",cruise," after letting go=",heli.current_speed)
        check(cruise>3 and heli.current_speed<1.0,"helicopter: let go and it brakes to a hover")
        heli.occupied=false
    game.active_vehicle=null
    for i in range(3): await process_frame
    check(not touch.ascend_button.visible and not touch.descend_button.visible,"no ▲ / ▼ on foot")
    print("EASY FLYING CHECKS ",checks," FAILURES ",failures.size()," ",failures)
    quit(1 if failures.size()>0 else 0)

## The ▲ / ▼ Buttons show while flying (on every device: no touch screen here) and, held, give
## the up / down input both aircraft read (DriveableVehicle.ascend_input()).
func check_flight_buttons(touch,what: String) -> void:
    for i in range(3): await process_frame
    check(touch.ascend_button.visible and touch.descend_button.visible,"▲ / ▼ buttons show in the "+what)
    var seen:=[]
    for button in [touch.ascend_button,touch.descend_button]:
        button.button_down.emit()
        await process_frame
        seen.append(DriveableVehicle.ascend_input())
        button.button_up.emit()
        await process_frame
        seen.append(DriveableVehicle.ascend_input())
    print("BUTTONS ",what," ",seen)
    check(seen==[1.0,0.0,-1.0,0.0],"held ▲ climbs, held ▼ descends, released neither ("+what+")")
