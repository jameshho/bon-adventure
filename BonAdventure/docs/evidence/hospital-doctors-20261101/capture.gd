extends SceneTree
## Ward doctor views; isolated copy, 1200x800, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/hospital-doctors-20261101/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/hospital-doctors-20261101"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var hospital: Node3D=game.apartment.get_node("Buildings/Hospital")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, room, eye, target]: room-local town coordinates; the doorway is at x -3.5.
    for spec in [
        ["exam-room","Floor1/Room3",Vector3(-2.9,2.6,-3.0),Vector3(1.2,1.0,-.2)],
        ["exam-bonbon","Floor1/Room3",Vector3(.2,1.6,-1.6),Vector3(1.9,1.1,-1.0)],
        ["icu-room","Floor2/Room3",Vector3(2.7,2.6,-3.0),Vector3(-1.4,1.0,1.2)],
        ["icu-cat","Floor2/Room3",Vector3(-.4,1.6,.4),Vector3(-2.05,1.1,1.7)],
        ["imaging-room","Floor3/Room1",Vector3(-2.9,2.6,-.4),Vector3(1.4,1.0,1.0)],
        ["imaging-beagle","Floor3/Room1",Vector3(.2,1.6,.2),Vector3(1.9,1.1,1.0)],
        ["reception","Floor1/Room1",Vector3(0,2.2,-3.2),Vector3(-.35,1.2,2.75)],
    ]:
        var room: Node3D=hospital.get_node(spec[1])
        camera.global_position=room.to_global(spec[2])
        camera.look_at(room.to_global(spec[3]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL DOCTORS CAPTURE done")
    quit()
