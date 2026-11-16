extends SceneTree
## Former rear-wing displays in their new rooms, and the closed rear (hospital-local cameras); isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-wing-removal-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/hospital-wing-removal-20261027/"+phase
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
        ["urgencias",Vector3(8.4,3.2,11.7),Vector3(4,.4,6)],
        ["examenes",Vector3(-3.2,3.2,5.2),Vector3(-7.4,.6,10.6)],
        ["imagenes",Vector3(2.7,14.2,-4.9),Vector3(7.2,11.6,-10.6)],
        ["fisioterapia",Vector3(-6.2,14.2,5.0),Vector3(-4.6,11.4,11.4)],
        ["rear-exterior",Vector3(14,9,42),Vector3(0,5,10)]
    ]:
        camera.global_position=hospital.to_global(spec[1])
        camera.look_at(hospital.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL WING REMOVAL CAPTURE: ",phase)
    quit()
