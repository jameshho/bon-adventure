extends SceneTree
## Full-town integration; optional --capture writes /tmp/vt-vehicle-views/*.png.
## Use the README isolated project. No learner data or historical images written.
var game
var failures: Array[String] = []
var checks := 0
var camera: Camera3D
var capture := false
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        push_error("DOORS: "+label)
func step(v, count: int) -> void:
    for i in range(count):
        if v.fixed_wing: v.aircraft_step(1.0/60,0,0,0,0,true,false)
        else: v.drive_step(1.0/60,0,0,0)
        game.player._physics_process(1.0/60)
func shot(v: Node3D, title: String, eye: Vector3, target: Vector3) -> void:
    if not capture: return
    camera.global_position = v.to_global(eye)
    camera.look_at(v.to_global(target))
    var was_visible: bool = game.player.visual.visible
    game.player.visual.hide() # Model inspection views; the cycle checks still animate BonBon.
    for i in range(3): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("/tmp/vt-vehicle-views/"+title+".png")
    game.player.visual.visible = was_visible
func run():
    capture = "--capture" in OS.get_cmdline_user_args()
    if capture: DirAccess.make_dir_recursive_absolute("/tmp/vt-vehicle-views")
    root.size = Vector2i(1100,760)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    camera = Camera3D.new()
    game.add_child(camera)
    camera.current = true
    camera.fov = 48
    for v in game.driveable_vehicles:
        v.set_physics_process(false)
        v.set_process(false)
    var pad = game.box("Door check pad",Vector3.ZERO,Vector3(80,.4,80),Color("687b74"),"",true)
    pad.global_position = Vector3(900,0,900)
    await physics_frame
    await physics_frame
    for v in game.driveable_vehicles:
        var title: String = v.name
        var saved: Transform3D = v.global_transform
        v.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(900,.30 if v.fixed_wing else .45,900))
        if v.road_physics!=null: v.road_physics.reset()
        await physics_frame
        await physics_frame
        # Settle the real vehicle on the test pad before E.
        v.occupied=true
        step(v,180)
        v.occupied=false
        await physics_frame
        await physics_frame
        var doors: Array = v.vehicle_doors
        if v.fixed_wing: doors = [v.cabin_door]
        check(not doors.is_empty() or v.get_meta("word_key","")=="motorcycle",title+" has a permanent door (or is open motorcycle)")
        for d in doors: check(d.visible and d.get_child_count()>0,title+" closed leaf exists and is visible")
        var eye := Vector3(-4,3,6)
        var target := Vector3(-.4,1.1,0)
        if v.get_meta("word_key","")in ["bus","school bus"]: eye=Vector3(-6,4,-8)
        if v.helicopter or v.fixed_wing:
            eye=Vector3(-7,4,-7)
            target=Vector3(0,1.7,-.6)
        game.player.global_position=v.boarding_step_point()
        if v.fixed_wing: game.player.global_position=v.to_global(Vector3(-2.1,.1,-1.1))
        await physics_frame
        var count_before: int = v.find_children("*","Node",true,false).size()
        await shot(v,title+"-closed",eye,target)
        check(game.toggle_vehicle() and game.active_vehicle==v,title+" E enters actual vehicle")
        step(v,roundi(v.boarding_duration*.6*60))
        if v.fixed_wing: v._process(0)
        for d in doors: check(absf(d.rotation.y)>.9,title+" leaf opens about hinge")
        await shot(v,title+"-open",eye,target)
        step(v,roundi(v.boarding_duration*.45*60))
        if v.fixed_wing: v._process(0)
        check(not v.boarding_busy(),title+" boarding finishes")
        for d in doors: check(d.visible and absf(d.rotation.y)<.001,title+" same leaf closes")
        var exit: Dictionary = v.safe_exit(game.player)
        print("EXIT RESULT ",title," ",exit," pose ",v.global_position)
        check(exit.ok and exit.get("door",false),title+" actual entrance has a safe exit")
        if exit.ok:
            game.toggle_vehicle()
            step(v,roundi(v.boarding_duration*.4*60))
            if v.fixed_wing: v._process(0)
            for d in doors: check(absf(d.rotation.y)>.9,title+" exit reopens same leaf")
            step(v,roundi(v.boarding_duration*.65*60))
            check(game.active_vehicle==null and game.player.riding_vehicle==null,title+" exit returns to walking")
            check(game.player.collision_layer!=0 and game.player.visual.visible,title+" player collision/visibility restored")
        else: game.complete_vehicle_exit(v,v.to_global(Vector3(0,0,5)))
        check(v.find_children("*","Node",true,false).size()==count_before,title+" no temporary geometry spawned")
        v.global_transform=saved
        print("DOOR CYCLE ",title)
    var truck: Node3D = game.apartment.get_node("Warehouse/Exterior/Delivery truck")
    check(truck.scene_file_path=="res://scenes/props/vehicles/box_truck.tscn","warehouse instances standalone box truck")
    check(truck.has_node("Model/Cabin") and truck.has_node("Model/Cargo/LeftRearDoor"),"cab and cargo/rear leaves are separate")
    await shot(truck,"warehouse-truck",Vector3(-7,4,-9),Vector3(0,-.1,-.8))
    print("VEHICLE DOORS: ",checks," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
