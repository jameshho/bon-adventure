extends SceneTree
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var market=game.apartment.get_node("RelocatedSites/Supermarket")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    var phase="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder="res://docs/evidence/market-interior-20261026/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    for spec in [
        ["player-height",Vector3(-33,1.65,39),Vector3(-33,1.65,51),76.0],
        ["entry",Vector3(-33,2.5,35),Vector3(-33,1.6,51),76.0],
        ["fresh",Vector3(-37.7,2.5,52),Vector3(-32,1.5,57),78.0],
        ["aisles",Vector3(-28.3,2.5,42),Vector3(-37,1.5,48),76.0],
        ["checkout",Vector3(-33,2.5,42),Vector3(-40,1.3,36.5),76.0],
        ["cutaway",Vector3(-33,44,46.9),Vector3(-33,0,47),37.0]
    ]:
        if spec[0]=="cutaway":
            market.get_node("Supermarket roof").hide()
            for node in market.find_children("*","Node3D",true,false):
                if node.get_meta("market_overhead",false): node.hide()
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[0]=="cutaway" else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=spec[3]; camera.fov=spec[3]
        camera.global_position=market.to_global(spec[1])
        camera.look_at(market.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("MARKET INTERIOR CAPTURE: ",phase,"; four interior views and diagnostic roof-hidden cutaway")
    quit()
