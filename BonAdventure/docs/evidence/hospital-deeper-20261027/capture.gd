extends SceneTree
## One-room-deeper hospital: lounges, moved back rooms and exterior (hospital-local cameras); isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-deeper-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/hospital-deeper-20261027/"+phase
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
        ["lounge-floor1-left",Vector3(-.6,1.9,4.6),Vector3(6.5,.9,10.4)],
        ["lounge-floor1-right",Vector3(.6,1.9,4.6),Vector3(-6.5,.9,10.4)],
        ["lounge-floor2",Vector3(-1.2,5.6+2.6,4.2),Vector3(6,5.6+.6,10.8)],
        ["hall-to-back-rooms",Vector3(0,1.9,6),Vector3(0,1.6,19)],
        ["back-room-urgencias",Vector3(8.4,3.2,19.4),Vector3(4,.4,13.7)],
        ["side-exterior",Vector3(-34,9,4),Vector3(-9,6,4)],
        ["rear-exterior",Vector3(16,10,52),Vector3(0,6,16)]
    ]:
        camera.global_position=hospital.to_global(spec[1])
        camera.look_at(hospital.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL DEEPER CAPTURE: ",phase)
    quit()
