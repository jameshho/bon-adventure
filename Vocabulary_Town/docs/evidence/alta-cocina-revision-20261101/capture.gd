extends SceneTree
## Alta Cocina revision views (1 Nov 2026); isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/alta-cocina-revision-20261101/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/alta-cocina-revision-20261101"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var fine: Node3D=game.apartment.get_node("Restaurants/Pizza")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, eye, target]: shell-local coordinates (door on −Z at x=0).
    for spec in [
        ["front",Vector3(7,6,-26),Vector3(0,3,-8)],
        ["aerial",Vector3(-22,22,-30),Vector3(0,3,2)],
        ["rear",Vector3(-6,9,30),Vector3(4,3,10)],
        ["doorway",Vector3(0,1.7,-13),Vector3(0,1.6,0)],
        ["motorcycle",Vector3(-10,3,-15),Vector3(-6.5,.5,-13.5)],
        ["entrance",Vector3(0,2.2,-7.2),Vector3(-3,1,4)],
        ["dining",Vector3(12,2.6,6.5),Vector3(-4,1.4,-3)],
        ["booths",Vector3(-9.3,2.4,-3.6),Vector3(-13.4,.7,-3.6)],
        ["booth-close",Vector3(-10.9,1.6,-3.6),Vector3(-13.4,.7,-3.6)],
        ["booth-seated",Vector3(-12.8,1.25,-2.9),Vector3(-12.9,.9,-4.6)],
        ["tables",Vector3(8,2.2,-1.5),Vector3(10.9,.8,-4.6)],
        ["bar",Vector3(-8.4,1.9,-.4),Vector3(-8.4,2.5,6)],
        ["floor",Vector3(1,2.0,-3),Vector3(1.5,0,-.5)],
    ]:
        camera.global_position=fine.to_global(spec[1])
        camera.look_at(fine.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("ALTA COCINA REVISION CAPTURE done")
    quit()
