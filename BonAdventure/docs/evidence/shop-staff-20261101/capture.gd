extends SceneTree
## Bank, sports and furniture staff views; isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/shop-staff-20261101/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/shop-staff-20261101"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town: Node3D=game.apartment
    var bank: Node3D=town.get_node("RelocatedSites/Bank")
    var sports: Node3D=town.get_node("Buildings/SportsStore")
    var furniture: Node3D=town.get_node("Buildings/FurnitureStore")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, frame, eye, target]: frame-local coordinates.
    for spec in [
        ["bank-lobby",bank,Vector3(24.5,2.4,45.0),Vector3(21.1,1.0,39.0)],
        ["bank-banker",bank,Vector3(21.9,1.8,42.4),Vector3(21.1,1.4,38.9)],
        ["sports-floor",sports,Vector3(-1.0,2.6,3.0),Vector3(-6.0,1.0,10.0)],
        ["sports-salesperson",sports,Vector3(-4.0,1.8,8.0),Vector3(-6.1,1.4,11.15)],
        ["furniture-entrance",furniture,Vector3(0,2.2,-13.8),Vector3(1.7,1.0,-6.4)],
        ["furniture-salesperson",furniture,Vector3(1.0,1.8,-9.6),Vector3(1.7,1.4,-6.4)],
    ]:
        var frame: Node3D=spec[1]
        camera.global_position=frame.to_global(spec[2])
        camera.look_at(frame.to_global(spec[3]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("SHOP STAFF CAPTURE done")
    quit()
