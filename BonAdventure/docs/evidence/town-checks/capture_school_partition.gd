extends SceneTree
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
    game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false); game.hud.hide()
    var school=game.apartment.get_node("Buildings/School")
    var camera:=Camera3D.new(); game.add_child(camera); camera.current=true
    var phase="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder="res://docs/evidence/school-partition-20261026/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    for spec in [
        ["front-open",Vector3(0,2.1,-10),Vector3(0,2,-1),85.0],
        ["crossing",Vector3(-2.5,2,-8),Vector3(7,2,-6),78.0],
        ["exterior",Vector3(24,16,-34),Vector3(0,2,-3.2),45.0],
        ["floor-plan",Vector3(0,38,-3.21),Vector3(0,0,-3.2),29.0]
    ]:
        if spec[0]=="floor-plan": school.get_node("MainRoof").hide()
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[0] in ["floor-plan","exterior"] else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=spec[3]; camera.fov=spec[3]
        camera.global_position=school.to_global(spec[1]); camera.look_at(school.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("SCHOOL PARTITION CAPTURE: ",phase,"; interior, crossing, exterior, roof-hidden floor plan")
    quit()
