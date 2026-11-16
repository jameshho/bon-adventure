extends SceneTree
# Subi (Home garage) boarding/exit sequence, driver door, the scooter's visible rider
# (9 Nov 2026) and fast-road handling for every road vehicle. Writes no files; run with an isolated user directory.
const Rider := preload("res://scripts/player/motorcycle_rider.gd")
var game
var checks:=0
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures.append(label)
        push_error("VEHICLE BOARDING: "+label)
func frames(vehicle,count: int,gas := 0.0,steer := 0.0,brake := false) -> void:
    for i in range(count):
        vehicle.drive_step(1.0/60,gas,steer,1.0 if brake else 0.0)
        game.player._physics_process(1.0/60)
## World distance from BonBon's paw tip (Arm or Arm_2) to its grip on the scooter.
func paw_to_grip(bike,key: String) -> float:
    var side:=-1.0 if key.ends_with("_2") else 1.0
    var bonbon: Node3D=game.player.get_node("Visual/BonBon")
    var moved: Transform3D=game.player.parts[key].transform*game.player.rest_poses[key].affine_inverse()
    var tip: Vector3=bonbon.global_transform*(moved*Vector3(Rider.ARM_TIP.x*side,Rider.ARM_TIP.y,Rider.ARM_TIP.z))
    return tip.distance_to(Rider.grip(bike,"Near" if side>0 else "Far").global_position)

## The scooter: BonBon stays visible getting on, riding and getting off, seated with paws on the
## grips and the floorboard; the scooter leans into turns and the rider stays in sync.
func check_scooter(pad_center: Vector3) -> void:
    var bike: DriveableVehicle=game.apartment.get_node("Vehicles/Motorcycle")
    check(bike.has_rider() and bike.scene_file_path=="res://scenes/props/vehicles/scooter.tscn","the restaurant-lot motorcycle is the scooter with a rider mount")
    check(game.interaction.word_key(bike)=="motorcycle","scooter keeps the word motorcycle")
    var parked: Transform3D=bike.global_transform
    bike.global_transform=Transform3D(parked.basis,pad_center+Vector3(0,.45,0))
    game.player.global_position=bike.boarding_step_point()+Vector3(0,.1,0)
    await physics_frame
    game.interaction.refresh_focus()
    check(game.interaction.focus!=null and game.interaction.focus.get_parent()==bike,"scooter is the focused interactable at its mounting step")
    check(game.toggle_vehicle() and game.active_vehicle==bike,"E gets on the scooter")
    var always_visible:=true
    var hop_height:=0.0
    for i in range(roundi(bike.boarding_duration*60)+40):
        frames(bike,1)
        always_visible=always_visible and game.player.visual.visible
        hop_height=maxf(hop_height,game.player.visual.global_position.y-bike.boarding_seat().origin.y)
    check(always_visible and game.player.visual.visible,"BonBon stays visible getting on and seated")
    check(hop_height>.2,"BonBon hops up onto the seat (%.2f m above it)"%hop_height)
    check(game.player.visual.global_position.distance_to(bike.boarding_seat().origin)<.08,"BonBon sits at the rider mount")
    check(absf(game.player.visual.global_basis.get_scale().x-bike.boarding_seat_scale())<.01,"BonBon rides at the scooter's rider scale")
    check(paw_to_grip(bike,"Arm")<.03 and paw_to_grip(bike,"Arm_2")<.03,"both paws on the grips when seated (%.3f, %.3f)"%[paw_to_grip(bike,"Arm"),paw_to_grip(bike,"Arm_2")])
    var mat: Node3D=bike.get_node("Bodywork/FloorMat")
    var bonbon: Node3D=game.player.get_node("Visual/BonBon")
    for key in ["Foot","Foot_2"]:
        var moved: Transform3D=game.player.parts[key].transform*game.player.rest_poses[key].affine_inverse()
        var paw: Vector3=bonbon.global_transform*(moved*Vector3((-.2 if key=="Foot" else .2),.02,-.08))
        # Inside the mat's footprint (its unit box) and within 6 cm of its top surface.
        var on_mat: Vector3=mat.global_transform.affine_inverse()*paw
        var above: float=paw.y-(mat.global_transform*Vector3(0,.5,0)).y
        check(absf(on_mat.x)<.5 and absf(on_mat.z)<.5 and absf(above)<.06,key+" rests on the floorboard mat (%.3f m from its top)"%above)
    # Accelerate, turn left, brake: lean sign and size, sync and grip every tick.
    var worst_seat:=0.0
    var worst_grip:=0.0
    var max_lean:=0.0
    var max_back:=0.0
    var max_forward:=0.0
    for phase in [[90,1.0,0.0,false],[120,.7,-1.0,false],[300,0.0,0.0,true]]:
        for i in range(phase[0]):
            frames(bike,1,phase[1],phase[2],phase[3])
            worst_seat=maxf(worst_seat,game.player.visual.global_position.distance_to(bike.boarding_seat().origin))
            worst_grip=maxf(worst_grip,maxf(paw_to_grip(bike,"Arm"),paw_to_grip(bike,"Arm_2")))
            max_lean=maxf(max_lean,bike.lean)
            max_back=maxf(max_back,bike.longitudinal_accel)
            max_forward=minf(max_forward,bike.longitudinal_accel)
    check(max_lean>.2 and max_lean<=bike.MAX_LEAN+.001,"scooter leans into the left turn (%.2f rad)"%max_lean)
    check(bike.get_node("StudyArea").global_basis.orthonormalized().y.dot(Vector3.UP)>.999,"collision stays upright")
    check(max_back>2 and max_forward<-2,"acceleration and braking reach the rider rock (%.1f / %.1f m/s^2)"%[max_back,max_forward])
    check(worst_seat<.12,"rider stays on the seat every tick (worst %.3f m)"%worst_seat)
    check(worst_grip<.03,"paws stay on the grips every tick (worst %.3f m)"%worst_grip)
    check(absf(bike.current_speed)<.1,"scooter brakes to a stop")
    var result: Dictionary=bike.safe_exit(game.player)
    check(result.ok and result.get("door",false),"stopped scooter offers the mounting-step exit")
    check(game.toggle_vehicle() and bike.exiting,"E starts getting off")
    always_visible=true
    for i in range(roundi(bike.boarding_duration*60)+5):
        if game.active_vehicle==null: break
        frames(bike,1)
        always_visible=always_visible and game.player.visual.visible
    check(always_visible and game.active_vehicle==null,"BonBon stays visible getting off and ends on foot")
    # The walking animation has run one tick since, so compare what riding changes: size,
    # facing and the turned head.
    var head: Node3D=game.player.get_node("Visual/BonBon/Head")
    check(game.player.visual.transform.basis.is_equal_approx(Basis.IDENTITY) and head.transform.is_equal_approx(game.player.get_meta("rider_head_rest")),"full size, upright and head straight after getting off")
    check(absf(bike.applied_lean)<.001,"scooter upright again when parked")
    check(game.player.process_physics_priority==0,"player physics order restored")
    bike.global_transform=parked

func run():
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for vehicle in game.driveable_vehicles:
        vehicle.set_physics_process(false)
        vehicle.set_process(false)
    await physics_frame
    await physics_frame
    var subi: DriveableVehicle=game.apartment.get_node("RelocatedSites/Home/SubaruOutback")
    check(game.driveable_vehicles.has(subi),"Subi is registered as a driveable vehicle")
    check(subi.get_meta("character_name","")=="Subi" and game.interaction.word_key(subi)=="car","Subi keeps its name card and car word")
    check(subi.driver_door!=null and subi.driver_door.visible and absf(subi.driver_door.rotation.y)<.001,"driver door built and closed while parked")
    # Walk up on the driver side (+Z model side), as a learner would in the garage.
    game.player.global_position=subi.to_global(Vector3(0,.1,2.2))
    await physics_frame
    game.interaction.refresh_focus()
    check(game.interaction.focus!=null and game.interaction.focus.get_parent()==subi,"Subi is the focused interactable at its driver door")
    var parked: Transform3D=subi.global_transform
    var layers: int=game.player.collision_layer
    check(game.toggle_vehicle() and game.active_vehicle==subi,"E boards Subi")
    check(game.player.visual.visible and subi.boarding_busy(),"BonBon stays visible while walking to the door")
    check(not subi.safe_exit(game.player).ok,"exit denied while getting in")
    var opened:=0.0
    var seat_distance:=INF
    for i in range(roundi(subi.boarding_duration*60)+2):
        if not subi.boarding_busy(): break
        frames(subi,1,1.0)
        opened=maxf(opened,absf(subi.driver_door.rotation.y))
        if subi.boarding_progress>.6 and subi.boarding_progress<.8:
            seat_distance=minf(seat_distance,game.player.visual.global_position.distance_to(subi.boarding_seat().origin))
    check(opened>.9,"driver door swings open during boarding (max %.2f rad)"%opened)
    check(seat_distance<1.2,"BonBon moves from the door into the driver seat")
    check(subi.boarding_progress==1 and subi.driver_door.visible and absf(subi.driver_door.rotation.y)<.001,"door closes once seated")
    check(not game.player.visual.visible,"BonBon is hidden inside the cabin while driving")
    check(subi.global_transform.is_equal_approx(parked),"W during boarding does not move the car")
    check(game.player.collision_layer==0,"walking collision off while seated")
    # The overhead garage door (when present) must be open to drive out.
    var garage=game.garage_door()
    if garage!=null and not garage.is_open:
        garage.toggle()
        for i in range(roundi(garage.travel_seconds*60)+10): garage._physics_process(1.0/60)
        await physics_frame
        await physics_frame
    var start: Vector3=subi.global_position
    frames(subi,150,1.0)
    check(subi.global_position.distance_to(start)>4 and subi.current_speed>3,"Subi drives out of the garage (%.1f m)"%subi.global_position.distance_to(start))
    frames(subi,180,0,0,true)
    check(absf(subi.current_speed)<.1,"Subi brakes to a stop")
    var result: Dictionary=subi.safe_exit(game.player)
    check(result.ok and result.get("door",false),"stopped Subi offers the driver-door exit")
    check(game.toggle_vehicle() and game.active_vehicle==subi and subi.exiting,"E starts the exit sequence")
    check(game.player.visual.visible,"BonBon reappears to climb out")
    opened=0.0
    for i in range(roundi(subi.boarding_duration*60)+2):
        if game.active_vehicle==null: break
        frames(subi,1)
        if is_instance_valid(subi.driver_door): opened=maxf(opened,absf(subi.driver_door.rotation.y))
    check(opened>.9,"driver door opens again to get out")
    check(game.active_vehicle==null and game.player.riding_vehicle==null,"exit completes on foot")
    check(game.player.collision_layer==layers and game.player.visual.visible,"walking collision and visible BonBon restored")
    check(game.player.global_position.distance_to(result.point)<.01,"BonBon stands at the driver-door exit point")
    check(subi.driver_door.visible and absf(subi.driver_door.rotation.y)<.001,"door closed after exit")
    subi.global_transform=parked
    # Fast-road handling on a clear pad for every road vehicle.
    var pad=game.box("Fast road fixture",Vector3.ZERO,Vector3(900,.4,900),Color.WHITE,"",true)
    pad.global_position=Vector3(3000,0,3000)
    await physics_frame
    await physics_frame
    await check_scooter(Vector3(3000,.2,2900))
    var report:={}
    for vehicle in game.driveable_vehicles:
        if vehicle.helicopter or vehicle.fixed_wing: continue
        var saved: Transform3D=vehicle.global_transform
        vehicle.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(3350,.45,3000))
        vehicle.road_physics.reset()
        vehicle.current_speed=0
        vehicle.occupied=true
        var title: String=vehicle.name
        check(vehicle.top_speed>=14*1.5-.01 and vehicle.top_speed<=14*2+.01,title+" top speed is 1.5-2x the former 14 m/s")
        var peak:=0.0
        var t_to_14:=-1.0
        for i in range(30*60):
            vehicle.drive_step(1.0/60,1,0,0)
            peak=maxf(peak,vehicle.current_speed)
            if t_to_14<0 and vehicle.current_speed>=14: t_to_14=i/60.0
        check(peak>14*1.35 and peak<vehicle.top_speed+.2,title+" reaches well beyond the former top speed (%.1f m/s)"%peak)
        # Full steering at speed: lock is reduced, the car stays planted without spinning.
        var max_yaw:=0.0
        var max_slip:=0.0
        for i in range(180):
            vehicle.drive_step(1.0/60,1,1,0)
            max_yaw=maxf(max_yaw,absf(vehicle.road_physics.yaw_velocity))
            var v: Vector3=vehicle.road_physics.velocity
            v.y=0
            if v.length()>1: max_slip=maxf(max_slip,absf(v.normalized().dot(vehicle.travel_forward().cross(Vector3.UP))))
        check(vehicle.road_physics.supported and max_slip<.25,title+" full lock at speed stays stable (slip %.2f)"%max_slip)
        # Two-wheelers lean into ever-tighter held turns (user, 9 Nov 2026), capped at LEAN_YAW_MAX.
        var yaw_limit: float=vehicle.road_physics.LEAN_YAW_MAX+.05 if vehicle.road_physics.lean_steer else 1.0
        check(max_yaw<yaw_limit,title+" high-speed yaw rate stays moderate (%.2f rad/s)"%max_yaw)
        var speed: float=vehicle.current_speed
        var from: Vector3=vehicle.global_position
        var stop_time:=0.0
        for i in range(8*60):
            vehicle.drive_step(1.0/60,0,0,1)
            if absf(vehicle.current_speed)<.1: break
            stop_time+=1.0/60
        check(absf(vehicle.current_speed)<.1,title+" brakes from speed to a stop")
        report[title]={"top":vehicle.top_speed,"peak":snappedf(peak,.1),"0-14":snappedf(t_to_14,.1),"steer_slip":snappedf(max_slip,.01),"yaw":snappedf(max_yaw,.01),"brake_from":snappedf(speed,.1),"brake_s":snappedf(stop_time,.01),"brake_m":snappedf(vehicle.global_position.distance_to(from),.1)}
        vehicle.occupied=false
        vehicle.road_physics.reset()
        vehicle.global_transform=saved
    pad.free()
    for title in report: print("HANDLING ",title," ",report[title])
    print("VEHICLE BOARDING: ",checks," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
