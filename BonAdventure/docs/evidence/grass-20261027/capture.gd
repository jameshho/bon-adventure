extends SceneTree
## Lawn texture and near-camera grass views (town-local cameras); isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/grass-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/grass-20261027/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    for spec in [
        ["walking-height",Vector3(30,1.6,128),Vector3(40,.6,142)],
        ["lawn-close",Vector3(-30,2.2,100),Vector3(-36,0,108)],
        ["park-hill",Vector3(8,3,150),Vector3(22,1,166)],
        ["park-wide",Vector3(36,3,126),Vector3(61,3,142)],
        ["overview",Vector3(0,125,235),Vector3(0,0,130)],
        ["town-lawn",Vector3(0,3,187),Vector3(-45,2,215)]
    ]:
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("GRASS CAPTURE: ",phase)
    quit()
