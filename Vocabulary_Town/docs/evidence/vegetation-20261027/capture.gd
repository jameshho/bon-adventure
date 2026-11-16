extends SceneTree
## Run in an isolated copy, at 1200x900. Stable town-local cameras for vegetation phases.
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder="res://docs/evidence/vegetation-20261027/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    for spec in [
        ["overview",Vector3(0,125,235),Vector3(0,0,130),65.0],
        ["pond",Vector3(-65,16,115),Vector3(-20,1,139),75.0],
        ["park",Vector3(36,3,126),Vector3(61,3,142),70.0],
        ["frontage",Vector3(0,3,187),Vector3(-45,2,215),70.0],
        ["shore",Vector3(130,4,145),Vector3(175,1,175),70.0]
    ]:
        camera.fov=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("VEGETATION CAPTURE: ",phase)
    quit()
