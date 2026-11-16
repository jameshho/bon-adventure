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
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/resize-20261025")
    for spec in [
        ["school-front",Vector3(28,23,190),Vector3(0,2,229),47.0],
        ["market-front",Vector3(-97,26,99),Vector3(-146,2,126),52.0],
        ["sites",Vector3(-53,270,160),Vector3(-53,0,160.1),280.0],
        ["school-entry",Vector3(0,3,217),Vector3(0,2,230),14.0],
        ["market-entry",Vector3(-127,3,126),Vector3(-145,2,126),15.0]
    ]:
        camera.size=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/resize-20261025/"+spec[0]+".png")
    camera.projection=Camera3D.PROJECTION_PERSPECTIVE
    camera.fov=70
    for spec in [["school-player",Vector3(-7,.03,230),Vector3(-7,3.2,225.8),Vector3(-7,1.1,234)], ["market-player",Vector3(-140,.12,126),Vector3(-135,3.2,126),Vector3(-146,1.1,126)]]:
        game.player.global_position=game.apartment.to_global(spec[1])
        camera.global_position=game.apartment.to_global(spec[2])
        camera.look_at(game.apartment.to_global(spec[3]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/resize-20261025/"+spec[0]+".png")
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    # Explicit cutaway diagnostics, not the normal in-game roof appearance.
    for path in ["Buildings/School/MainRoof","RelocatedSites/Supermarket/Supermarket roof"]: game.apartment.get_node(path).hide()
    for spec in [["school-cutaway",Vector3(0,60,229.9),Vector3(0,0,230),34.0],["market-cutaway",Vector3(-146,70,125.9),Vector3(-146,0,126),39.0]]:
        camera.size=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/resize-20261025/"+spec[0]+".png")
    quit()
