extends SceneTree
## Fixed Main-scene cameras for the lighting/sky pass; run in the isolated test project.
## godot --path . --resolution 1200x900 --script res://docs/evidence/lighting-sky-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/lighting-sky-20261027/"+phase
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
    var town: Node3D=game.apartment
    var market: Node3D=town.get_node("RelocatedSites/Supermarket")
    var hospital: Node3D=town.get_node("Buildings/Hospital")
    var home: Node3D=town.get_node("RelocatedSites/Home")
    # Main._process lifts this roof while the learner is indoors; processing is paused here.
    home.get_node("Home roof").hide()
    for spec in [
        ["street",town,Vector3(0,2.5,198),Vector3(0,2.8,223),65.0],
        ["context",town,Vector3(38,30,185),Vector3(0,2,229),62.0],
        ["horizon",town,Vector3(0,3,198),Vector3(60,12,260),70.0],
        ["market",market,Vector3(-28.3,2.5,42),Vector3(-37,1.5,48),76.0],
        ["hospital",hospital,Vector3(0,2,-11),Vector3(0,2,3),70.0],
        ["home",home,Vector3(3,1.8,10),Vector3(0,1.2,2),70.0]
    ]:
        var site: Node3D=spec[1]
        camera.fov=spec[4]
        camera.global_position=site.to_global(spec[2])
        camera.look_at(site.to_global(spec[3]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("LIGHTING CAPTURE: ",phase,"; street, context, horizon, market, hospital, home")
    quit()
