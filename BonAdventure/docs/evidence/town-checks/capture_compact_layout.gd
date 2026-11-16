extends SceneTree
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless":
        push_error("Compact layout capture requires a graphical renderer")
        quit(1)
        return
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
    for spec in [["overview",Vector3(0,400,139.9),Vector3(0,0,140),490.0],["park",Vector3(0,240,70),Vector3(0,0,137),255.0],["shops",Vector3(75,24,125),Vector3(136,3,145),90.0],["south",Vector3(0,35,102),Vector3(0,0,44),165.0]]:
        camera.size=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/part2/compact-"+spec[0]+".png")
    quit()
