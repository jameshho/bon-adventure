extends SceneTree
## Fixed Main-scene cameras; run in the isolated test project.
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/school-exterior-20261025/"+phase
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
    for spec in [
        ["street",Vector3(0,2.5,198),Vector3(0,2.8,223),65.0],
        ["context",Vector3(38,30,185),Vector3(0,2,229),62.0],
        ["front",Vector3(28,20,200),Vector3(0,2,230),43.0]
    ]:
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[0]=="front" else Camera3D.PROJECTION_PERSPECTIVE
        camera.fov=spec[3]
        camera.size=spec[3]
        camera.global_position=game.apartment.to_global(spec[1])
        camera.look_at(game.apartment.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("SCHOOL CAPTURE: ",phase,"; street, context, front; identical camera transforms")
    quit()
