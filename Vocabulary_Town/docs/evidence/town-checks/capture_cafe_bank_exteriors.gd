extends SceneTree
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/cafe-bank-exteriors-20261025/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera); camera.current=true
    for spec in [
        ["cafe-street",Vector3(105,2.6,164),Vector3(127,2.7,166),62.0],
        ["cafe-front",Vector3(100,20,145),Vector3(135,2,166),39.0],
        ["bank-street",Vector3(106,2.7,106),Vector3(127,3,108),62.0],
        ["bank-front",Vector3(103,20,89),Vector3(133,2,108),35.0],
        ["context",Vector3(55,35,116),Vector3(134,2,138),65.0]
    ]:
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if str(spec[0]).ends_with("front") else Camera3D.PROJECTION_PERSPECTIVE
        camera.fov=spec[3]; camera.size=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("CAFE/BANK CAPTURE: ",phase,"; five fixed Main views")
    quit()
