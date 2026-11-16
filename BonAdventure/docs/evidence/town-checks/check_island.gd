extends SceneTree
var errors: Array[String] = []
func check(ok: bool, message: String):
    if not ok:
        errors.append(message)
        push_error(message)
func _initialize(): run.call_deferred()
func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.hide()
    await physics_frame
    await physics_frame
    var town = game.apartment
    check(not town.has_node("Landmarks/BonBon"),"BonBon removed")
    check(not town.has_node("RearMeadow"),"Unused pig meadow removed")
    check(town.get_node("Buildings/HouseStructure").position.z == 6,"Home six meters closer to road")
    check(town.get_node("Buildings").position == Vector3.ZERO,"Other buildings stay in place")
    check(town.get_node("Natural town terrain").position == Vector3.ZERO,"Terrain is not shifted with home")
    var trees := 0
    for node in town.find_children("*","Node3D",true,false):
        if str(node.scene_file_path).ends_with("_tree.tscn"): trees += 1
    check(trees <= 18,"Excess trees removed: "+str(trees))
    var land: AABB = town.get_node("Natural town terrain").get_aabb()
    var beach: AABB = town.get_node("Island beaches").get_aabb()
    check(land.position.z > -20 and land.end.z < 170,"Compact north/south footprint")
    check(land.position.x > -80 and land.end.x < 80,"Compact east/west footprint")
    check(beach.position.x < land.position.x and beach.end.x > land.end.x and beach.position.z < land.position.z and beach.end.z > land.end.z,"Beaches surround island")
    for point in [Vector3(0,2,0),Vector3(4.5,2,-16),Vector3(-78,2,68),Vector3(77,2,73),Vector3(-64,2,40),Vector3(-60,2,130),Vector3(55,2,150),Vector3(-4,2,155)]:
        var ray := PhysicsRayQueryParameters3D.create(town.to_global(point),town.to_global(point-Vector3(0,6,0)))
        check(not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Land/beach supports "+str(point))
    for building in ["School","Hospital"]:
        var node = town.get_node("Buildings/"+building)
        check(node.get_meta("floors",0)==3,building+" has three floors")
        for level in range(1,4):
            var window = node.get_node("Floor"+str(level)+"/FrontWindow-5.4")
            check(window.material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,building+" has glass windows")
    print("ISLAND: ",errors.size()," failures; ",trees," trees, compact shoreline, beach support, home relocation, three-floor civic buildings")
    if "--capture" in OS.get_cmdline_user_args():
        root.size=Vector2i(1440,1000)
        Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
        var camera := Camera3D.new()
        town.add_child(camera)
        camera.current=true
        camera.fov=65
        DirAccess.make_dir_recursive_absolute("res://docs/evidence/island-review")
        var views=[
            ["island",Vector3(108,156,-76),Vector3(0,0,75)],
            ["home",Vector3(26,17,36),Vector3(1,1,9)],
            ["civic",Vector3(24,22,83),Vector3(-17,7,117)],
            ["beach",Vector3(27,6,-22),Vector3(-2,1,-8)],
            ["school_science",Vector3(-6.8,7.8,107),Vector3(-10,7,113)],
            ["school_stairs",Vector3(6.7,2,116),Vector3(6.7,4,125)]]
        for view in views:
            camera.position=view[1]
            camera.look_at(town.to_global(view[2]))
            for i in range(8):await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://docs/evidence/island-review/"+view[0]+".png")
    game.queue_free()
    await process_frame
    quit(0 if errors.is_empty() else 1)
