extends SceneTree
## Fixed sign views before/after translation; run in the isolated copy at 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/guides/spanish-signs-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/guides/spanish-signs-20261027/"+phase
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
    var town: Node3D=game.apartment
    var market: Node3D=town.get_node("RelocatedSites/Supermarket")
    for spec in [
        ["school",town,Vector3(0,3,206),Vector3(0,2.5,221)],
        ["supermarket-front",town,Vector3(-117,3,126),Vector3(-132,2.5,126)],
        ["supermarket-aisles",market,Vector3(-28.3,2.5,42),Vector3(-37,1.5,48)],
        ["supermarket-entry",market,Vector3(-33,2.5,35),Vector3(-33,1.6,51)],
        ["library",town,Vector3(51,3,58),Vector3(51,3,40)],
        ["police",town,Vector3(-88,3,55),Vector3(-88,3,37)],
        ["bank",town,Vector3(110,3,108),Vector3(127,3,108)]
    ]:
        var site: Node3D=spec[1]
        camera.global_position=site.to_global(spec[2])
        camera.look_at(site.to_global(spec[3]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("SIGN CAPTURE: ",phase)
    quit()
