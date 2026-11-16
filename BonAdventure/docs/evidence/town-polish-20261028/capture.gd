extends SceneTree
## Pool, sidewalk and taquería views; isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/town-polish-20261028/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/town-polish-20261028"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town: Node3D=game.apartment
    var home: Node3D=town.get_node("RelocatedSites/Home")
    var shell: Node3D=town.get_node("Restaurants/Cafe")
    var points: PackedVector3Array=town.get_node("Curving neighborhood road").get_meta("reference_road_points")
    var a: Vector3=points[60]
    var t: Vector3=(points[61]-points[59]).normalized()
    var side:=Vector3(-t.z,0,t.x)
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    # [name, frame, eye, target]: frame-local coordinates.
    for spec in [
        ["pool-terrace",home,Vector3(12,3.2,-4),Vector3(-2,-1,-11)],
        ["pool-edge",home,Vector3(-12,2.2,-15.5),Vector3(2,-1.2,-10)],
        ["sidewalk",town,a+side*-6+t*-10+Vector3(0,6,0),a+side*6+t*6],
        ["taqueria-front",shell,Vector3(4,3,-24),Vector3(0,2.6,-6)],
        ["taqueria-door",shell,Vector3(0,1.7,-7.2),Vector3(0,1.2,4)],
        ["taqueria-bar",shell,Vector3(-1.5,1.9,2.6),Vector3(-1.5,.9,6.5)]
    ]:
        var frame: Node3D=spec[1]
        camera.global_position=frame.to_global(spec[2])
        camera.look_at(frame.to_global(spec[3]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("TOWN POLISH CAPTURE done")
    quit()
