extends SceneTree
## Alta Cocina and plush staff views; isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/alta-cocina-20261101/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/alta-cocina-20261101"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town: Node3D=game.apartment
    var fine: Node3D=town.get_node("Restaurants/Pizza")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, frame, eye, target]: frame-local coordinates.
    for spec in [
        ["front",fine,Vector3(7,5,-24),Vector3(0,2.2,-8)],
        ["terrace",fine,Vector3(13,2.2,-13.5),Vector3(5,1,-8.5)],
        ["rear",fine,Vector3(-6,8,28),Vector3(4,2,10)],
        ["dining",fine,Vector3(12,2.6,6.5),Vector3(-4,.8,-3)],
        ["entrance",fine,Vector3(0,2.2,-7.2),Vector3(-3,1,4)],
        ["table",fine,Vector3(-6.3,1.7,-3.1),Vector3(-5,.8,-4.6)],
        ["booth",fine,Vector3(-11.6,1.8,-2.8),Vector3(-13.35,.8,-4.0)],
        ["bar",fine,Vector3(-8.4,1.9,-.4),Vector3(-8.4,1.3,4.4)],
        ["pass",fine,Vector3(5.5,1.8,4.6),Vector3(6.5,1.0,12)],
        ["kitchen",fine,Vector3(13.4,2.6,9.0),Vector3(4,.8,13.5)],
        ["taqueria",town.get_node("Restaurants/Cafe"),Vector3(-3,2.3,-5),Vector3(1,1,3)],
        ["pizza-burger",town.get_node("Restaurants/Burger"),Vector3(0,2.2,-5),Vector3(-5,1,4)],
        ["bakery",town.get_node("Buildings/BakeryCafe"),Vector3(0,2.2,-1),Vector3(.3,1,7.3)],
    ]:
        var frame: Node3D=spec[1]
        camera.global_position=frame.to_global(spec[2])
        camera.look_at(frame.to_global(spec[3]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("ALTA COCINA CAPTURE done")
    quit()
