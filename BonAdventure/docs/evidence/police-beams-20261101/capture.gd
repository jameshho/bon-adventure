extends SceneTree
## Police-side floating beams (1 Nov 2026). Uses Main, which saves progress: run with an
## isolated user directory (README). World coordinates; pass the output folder name, e.g.
## godot --path . --resolution 1200x800 --script res://docs/evidence/police-beams-20261101/capture.gd -- after
## The before/ views were taken with the old nearest-site outline matching.
func _initialize(): run.call_deferred()
func shot(camera: Camera3D,from: Vector3,at: Vector3,file: String) -> void:
    camera.global_position=from
    camera.look_at(at)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(file)
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var args:=OS.get_cmdline_user_args()
    var folder:="res://docs/evidence/police-beams-20261101/"+(args[0] if args.size()>0 else "after")
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera); camera.current=true
    camera.fov=60.0; camera.far=900.0
    # The burger roof's stray frame stood at x −199..−223, z 45..85, south of the station.
    await shot(camera,Vector3(-188,2.4,38),Vector3(-212,4,72),folder+"/ground.png")
    await shot(camera,Vector3(-200,2.4,30),Vector3(-206,4,80),folder+"/ground-south.png")
    await shot(camera,Vector3(-160,38,30),Vector3(-200,0,80),folder+"/aerial.png")
    # The burger restaurant, which now keeps all of its eaves and corner posts.
    await shot(camera,Vector3(-80,14,80),Vector3(-111,3,45),folder+"/burger.png")
    print("POLICE BEAMS CAPTURE done")
    quit()
