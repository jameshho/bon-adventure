extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize(): run.call_deferred()
func run():
    root.size = Vector2i(1280, 720)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    var town: Node3D = game.apartment
    await physics_frame
    await physics_frame
    check(town.get_node("Sofa").scene_file_path.ends_with("/sofa.tscn"),"Sofa is reusable")
    check(town.get_node("Sofa").position.z > town.get_node("Television").position.z,"Sofa faces television")
    for prefix in ["Armchair","Footstool","House welcome","Plant pot","Potted plant","Entry coat hooks"]:
        check(town.find_children(prefix+"*","",false,false).is_empty(),"Removed "+prefix)
    var species := {}
    for node in town.find_children("*","Node3D",true,false):
        var key: String = node.get_meta("word_key", "")
        if not key.is_empty(): check(game.vocabulary.has(key),"Vocabulary: "+key)
        if str(node.scene_file_path).ends_with("_tree.tscn"): species[node.scene_file_path]=true
    check(species.size()==3,"Three tree species in town")
    var cabinet: Node3D = town.get_node("Drawer cabinet")
    var count := 0
    for drawer in game.doors:
        var state: Dictionary = game.doors[drawer]
        if state.type != "slide" or drawer.get_parent()!=cabinet: continue
        count += 1
        var origin: Vector3 = drawer.position
        state.open = true
        game._process(.016)
        check(drawer.position.z<origin.z and drawer.position.z>origin.z+state.shift.z,"Drawer interpolates")
        for i in range(90):game._process(1.0/60)
        check(drawer.position.distance_to(origin+state.shift)<.001,"Drawer opens fully")
        # Entire moving tray stays within its horizontal bay at every point of travel.
        check(absf(drawer.position.x)+.375<.815,"Drawer clears cabinet side")
        state.open = false
        for i in range(90):game._process(1.0/60)
        check(drawer.position.distance_to(origin)<.001,"Drawer closes fully")
    check(count==2,"Two working kitchen drawers")
    # Query the entire tray sweep against real physics bodies, excluding its face.
    for drawer in game.doors:
        if drawer.get_parent()!=cabinet: continue
        var query := PhysicsShapeQueryParameters3D.new()
        var shape := BoxShape3D.new()
        shape.size=Vector3(.68,.18,.76)*1.3
        query.shape=shape
        query.exclude=[drawer.get_node("Face/Body").get_rid(),game.player.get_rid()]
        for step in range(11):
            var offset := Vector3(0,-.08,.43-.62*step/10.0)
            query.transform=Transform3D(Basis.IDENTITY,drawer.to_global(offset))
            check(game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"Drawer tray has clear travel " + str(step))
    # Exercise the real picker against each redesigned vocabulary prop.
    for item in [["Sofa",Vector3(0,1.15,-1.8),Vector3(0,.9,0),"sofa"], ["Guitar",Vector3(0,.8,1.0),Vector3(0,.8,0),"guitar"], ["Rice",Vector3(0,.2,-.6),Vector3(0,.2,0),"rice"], ["Pasta",Vector3(0,.2,-.6),Vector3(0,.2,0),"pasta"], ["Cereal",Vector3(0,.2,-.6),Vector3(0,.2,0),"cereal"], ["Coat rack",Vector3(0,1,-.6),Vector3(0,1,0),"coat rack"]]:
        var object: Node3D=town.get_node(item[0])
        game.player.global_position = object.to_global(item[1]) - Vector3(0, 1.1, 0)
        game.camera.global_position=object.to_global(item[1])
        game.camera.look_at(object.to_global(item[2]))
        game.interaction.pointer_position = root.get_visible_rect().size * 0.5
        var picked=game.interaction.aimed_object()
        check(picked!=null and game.interaction.word_key(picked)==item[3],"Picker recognizes " + item[0] + " got " + str(picked) + " hit " + str(game.interaction.aimed_hit()))
    var car: Node3D=town.get_node("Vehicles/Car")
    var driver: Node3D=town.get_node("People/Driver")
    check(car.position.distance_to(Vector3(12.1,0,20))<.01,"Car on driveway")
    check(driver.position.distance_to(car.position)>1.6,"Driver outside car")
    check((-driver.basis.z).dot((car.position-driver.position).normalized())>.98,"Driver faces door")
    check(town.get_node("Buildings/BakeryCafe").position==Vector3(-61,0,76),"Cafe near electronics")
    # The garage ends before the car's rear bumper, and the driver stands beside it.
    var garage_end: float=town.get_node("Garage").position.z+3.1/2
    check(garage_end<car.position.z-1.7,"Car clears garage")
    var walking := CapsuleShape3D.new()
    walking.radius=.39*1.3
    walking.height=2.38*1.3
    var route_query := PhysicsShapeQueryParameters3D.new()
    route_query.shape=walking
    route_query.exclude=[game.player.get_rid()]
    for segment in [[Vector3(-47,1.3,60),Vector3(-56,1.3,60)],[Vector3(-56,1.3,60),Vector3(-61,1.3,63.2)],[Vector3(-61,1.3,63.2),Vector3(-61,1.3,65)]]:
        for i in range(15):
            route_query.transform=Transform3D(Basis.IDENTITY,town.to_global(segment[0].lerp(segment[1],i/14.0)))
            check(game.get_world_3d().direct_space_state.intersect_shape(route_query).is_empty(),"Cafe entrance route clear")
    var minimap=game.hud.ui_root.get_node("TownMinimap")
    check(minimap.surfaces.size()>10 and minimap.landmarks.size()>10,"Minimap caches town geometry")
    for yaw in [0.0,PI/2,PI,-PI/2]:
        game.player.rotation.y=yaw
        minimap.update_pose()
        var forward:=Vector2(-sin(yaw),-cos(yaw))
        check(minimap.project(minimap.map_position).distance_to(Vector2(104,104))<.001,"Player centered")
        check(minimap.project(minimap.map_position+forward*10).distance_to(Vector2(104,80))<.001,"Forward stays upward")
    var start:=Time.get_ticks_usec()
    for i in range(300):minimap.update_pose()
    print("Minimap pose average microseconds: ",(Time.get_ticks_usec()-start)/300.0)
    if "--capture" in OS.get_cmdline_user_args():
        root.size=Vector2i(1440,1000)
        Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
        var camera:=Camera3D.new()
        town.add_child(camera)
        camera.current=true
        camera.fov=67
        DirAccess.make_dir_recursive_absolute("res://docs/evidence/home-refresh-review")
        var views=[
            ["living",Vector3(5.2,2.5,10.5),Vector3(8,1,12.5)],
            ["kitchen",Vector3(-6,2.5,10.8),Vector3(-9.3,1.1,14.0)],
            ["bedroom",Vector3(-6,2.5,3),Vector3(-7,1,-1.3)],
            ["entry",Vector3(4.5,2.4,14),Vector3(4.5,1.2,16.5)],
            ["guitar",Vector3(6.5,1.6,3.7),Vector3(8,.85,1.2)],
            ["car_driver",Vector3(6,4,24),Vector3(11.5,1,20)],
            ["cafe",Vector3(-43,12,54),Vector3(-61,2,75)],
            ["trees",Vector3(-5,3.5,59),Vector3(-9,1.8,54)],
            ["pantry",Vector3(-3,2.3,12.5),Vector3(-4.39,1.4,14.4)]]
        for view in views:
            camera.position=view[1]
            camera.look_at(town.to_global(view[2]))
            game.player.position=town.to_global(view[1])-Vector3(0,2,0)
            game.player.rotation.y=camera.rotation.y
            minimap.update_pose()
            if view[0]=="kitchen":
                for drawer in game.doors:
                    if drawer.get_parent()==cabinet:game.doors[drawer].open=true
                for i in range(90):game._process(1.0/60)
            for i in range(12):await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://docs/evidence/home-refresh-review/"+view[0]+".png")
        game.set_process(true)
        for i in range(30):await process_frame
        var frame_start:=Time.get_ticks_usec()
        for i in range(120):await process_frame
        print("Graphical gameplay sample: ",120000000.0/(Time.get_ticks_usec()-frame_start)," average FPS across 120 frames at 1440x1000")
    print("HOME REFRESH: ",failures.size()," failures")
    game.free()
    quit(0 if failures.is_empty() else 1)
