extends SceneTree
## Library refresh views (1 Nov 2026); isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/library-refresh-20261101/capture.gd [prefix]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/library-refresh-20261101"
    var args:=OS.get_cmdline_user_args()
    var prefix:String=args[0] if args.size()>0 else ""
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var library: Node3D=game.apartment.get_node("RelocatedSites/Library")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, eye, target]: library source frame (door on -Z at x=-15, z=37.7).
    for spec in [
        ["front",Vector3(-15,5,26),Vector3(-15,2.5,38)],
        ["entrance",Vector3(-15,1.7,38.4),Vector3(-15,1.1,50)],
        ["left",Vector3(-12.5,2.2,39.2),Vector3(-20.5,0.9,43.5)],
        ["right",Vector3(-17.5,2.2,39.2),Vector3(-9.5,0.9,43.5)],
        ["rear",Vector3(-15,2.4,42),Vector3(-15,1.4,52)],
        ["reference",Vector3(-17.2,1.6,40.6),Vector3(-20.5,0.85,40.0)],
        ["reference-close",Vector3(-19.0,1.45,40.0),Vector3(-20.6,0.85,40.0)],
        ["overview",Vector3(-10,4.8,38.2),Vector3(-16,0,46)],
    ]:
        camera.global_position=library.to_global(spec[1])
        camera.look_at(library.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+prefix+spec[0]+".png")
    print("LIBRARY CAPTURE done")
    quit()
