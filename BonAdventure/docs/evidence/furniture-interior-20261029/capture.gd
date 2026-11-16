extends SceneTree
## 29 Oct 2026: furniture showroom renders (exterior, doorway, plan, cutaway, zones).
## godot --path . --resolution 1400x900 --script res://docs/evidence/furniture-interior-20261029/capture.gd -- [output_dir]
## Use the README's isolated user directory; the script only reads saves.
func _initialize(): run.call_deferred()
func run():
    var out:="res://docs/evidence/furniture-interior-20261029"
    for a in OS.get_cmdline_user_args(): out=a
    DirAccess.make_dir_recursive_absolute(out)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var store: Node3D=game.apartment.get_node("Buildings/FurnitureStore")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    for spec in [
        ["exterior",Vector3(-9,6.5,-30),Vector3(0,2.6,-14.5),62.0,false],
        ["door",Vector3(0,1.7,-17.5),Vector3(0,1.5,2),80.0,false],
        ["living",Vector3(-2.5,1.8,-13),Vector3(-8,1.0,-8),80.0,false],
        ["dining",Vector3(2.5,1.8,-13),Vector3(8,1.0,-9),80.0,false],
        ["office",Vector3(3,1.7,-4.5),Vector3(9,1.0,-1),80.0,false],
        ["lighting",Vector3(2.5,1.7,3),Vector3(8,1.4,8),85.0,false],
        ["bedroom",Vector3(-5.8,2.2,3.2),Vector3(-10.5,.8,.5),85.0,false],
        ["rear",Vector3(0,2.0,-1),Vector3(-6,1.2,9),85.0,false],
        ["top",Vector3(0,40,-1.5),Vector3(0,0,-1.5),28.0,true],
        ["iso",Vector3(-22,26,-27),Vector3(0,0,-1.5),30.0,true]
    ]:
        var hide: bool=spec[4]
        if hide:
            for n in ["Roof_18"]: store.get_node(n).hide()
            for n in store.find_children("Parapet*","Node3D",false,false): n.hide()
            for n in store.find_children("Ceiling*","Node3D",true,false): n.hide()
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if hide else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=spec[3]; camera.fov=spec[3]
        camera.global_position=store.to_global(spec[1])
        camera.look_at(store.to_global(spec[2]),Vector3.UP if spec[0]!="top" else Vector3(0,0,1))
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out+"/"+spec[0]+".png")
    print("FURNITURE CAPTURE done")
    quit()
