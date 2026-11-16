extends SceneTree
## Street-side views of the school, hospital and supermarket fronts for foundation planting.
## godot --path . --resolution 1200x900 --script res://docs/evidence/vegetation-20261027/phase3/capture_foundations.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/vegetation-20261027/phase3/foundations-"+phase
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
    camera.fov=62.0
    for spec in [
        ["school",Vector3(0,3,206),Vector3(0,1.5,221)],
        ["hospital",Vector3(56,11,198),Vector3(56,0.5,221)],
        ["supermarket",Vector3(-117,3,126),Vector3(-132,1.5,126)]
    ]:
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("FOUNDATION CAPTURE: ",phase)
    quit()
