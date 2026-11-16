extends SceneTree
## Hospital colour/signage review views (hospital-local cameras); isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-colours-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/hospital-colours-20261027/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    game.player.hide()
    var hospital: Node3D=game.apartment.get_node("Buildings/Hospital")
    var lift=hospital.get_node("Elevator")
    await process_frame
    if lift.hint: lift.hint.hide()
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=68.0
    for spec in [
        ["hall-floor1",Vector3(0,1.8,-11),Vector3(0,2.2,2)],
        ["elevator-from-hall",Vector3(2.4,1.8,1.2),Vector3(-4,2.6,-.2)],
        ["stairs-bottom",Vector3(0,1.8,-3.3),Vector3(6,1.6,.3)],
        ["stairs-top-floor2",Vector3(12.2,5.6+2.2,.3),Vector3(16,5.6+2.4,-1)],
        ["alcove-directory",Vector3(-1.2,1.8,-3.7),Vector3(-6,2.2,-2.7)],
        ["patient-room-201",Vector3(.4,5.6+1.8,-8.35),Vector3(8,5.6+1.2,-9.4)],
        ["hall-floor3",Vector3(0,11.2+1.8,-11),Vector3(0,11.2+2.2,2)]
    ]:
        camera.global_position=hospital.to_global(spec[1])
        camera.look_at(hospital.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL COLOUR CAPTURE: ",phase)
    quit()
