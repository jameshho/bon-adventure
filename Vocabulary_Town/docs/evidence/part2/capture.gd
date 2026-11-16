extends SceneTree
## Run with the graphical Compatibility renderer, at 1200x900.
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless":
        push_error("Capture requires the graphical renderer")
        quit(1)
        return
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    for node in game.apartment.get_node("ParkZoo").get_children():
        if node.get("home")!=null: node.set_process(false)
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    for spec in [
        ["town",Vector3(0,390,110),Vector3(0,0,150),430.0],
        ["washington",Vector3(78,17,119),Vector3(53,4,139),17.0],
        ["wildlife",Vector3(92,22,163),Vector3(63,2,194),46.0],
        ["snake",Vector3(55,2.5,202),Vector3(52.5,.5,199),3.2],
        ["tiger",Vector3(58,4,185),Vector3(52.5,.8,181),6.0],
        ["airport",Vector3(-90,105,235),Vector3(-90,0,250),130.0]
    ]:
        camera.size=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(4): await process_frame
        await RenderingServer.frame_post_draw
        var error=root.get_texture().get_image().save_png("res://docs/evidence/part2/"+spec[0]+".png")
        if error!=OK: push_error(error_string(error)); quit(1); return
    print("PART 2: six rendered views saved")
    quit()
