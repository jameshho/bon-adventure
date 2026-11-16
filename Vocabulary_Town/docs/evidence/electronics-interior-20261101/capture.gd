extends SceneTree
## Electronics store refresh views (1 Nov 2026); isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/electronics-interior-20261101/capture.gd [prefix]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/electronics-interior-20261101"
    var args:=OS.get_cmdline_user_args()
    var prefix:String=args[0] if args.size()>0 else ""
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var store: Node3D=game.apartment.get_node("Buildings/ElectronicsStore")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, eye, target] in the store frame: door gap on -Z (z=-7.6), rear wall z=+7.6.
    for spec in [
        ["front",Vector3(0,3.2,-15),Vector3(0,1.8,0)],
        ["entrance",Vector3(0,1.7,-7.3),Vector3(0,1.1,6)],
        ["left",Vector3(1.8,2.0,-4.5),Vector3(-5.6,1.0,0.5)],
        ["right",Vector3(-1.8,2.0,-4.5),Vector3(5.6,1.0,0.5)],
        ["rear",Vector3(0,2.2,5.6),Vector3(0,1.0,-7.6)],
        ["counter",Vector3(-1.5,1.8,2.0),Vector3(4.6,1.0,6.4)],
        ["gaming",Vector3(-2.6,1.9,4.0),Vector3(-5.6,1.1,6.0)],
        ["phones",Vector3(-0.9,1.7,0.6),Vector3(-2.6,1.1,1.9)],
        ["appliances",Vector3(1.6,1.9,-1.8),Vector3(5.6,1.0,-5.4)],
        ["overview",Vector3(4.9,4.6,-7.2),Vector3(-2.5,0,3.5)],
        ["overview-rear",Vector3(-4.9,4.6,7.2),Vector3(2.5,0,-3.5)],
    ]:
        camera.global_position=store.to_global(spec[1])
        camera.look_at(store.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+prefix+spec[0]+".png")
    print("ELECTRONICS CAPTURE done")
    quit()
