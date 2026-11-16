extends SceneTree
## Hospital reception redesign and final walkthrough views (hospital-local cameras); isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-reception-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/hospital-reception-20261027/"+phase
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
        ["reception",Vector3(4.2,1.8,-11.4),Vector3(5.6,1.8,-4.6)],
        ["reception-from-door",Vector3(1.4,1.9,-9.6),Vector3(6.8,1.7,-5.2)],
        ["walk-floor1-hall",Vector3(0,1.9,-11.5),Vector3(0,2,19)],
        ["walk-floor1-lounge",Vector3(0,1.9,4.8),Vector3(0,1.5,19)],
        ["walk-floor2-hall",Vector3(0,5.6+1.9,-11.5),Vector3(0,5.6+2,19)],
        ["walk-floor3-hall",Vector3(0,11.2+1.9,-11.5),Vector3(0,11.2+2,19)],
        ["walk-floor3-lounge",Vector3(-1.2,11.2+2.6,4.2),Vector3(-6,11.2+.6,10.8)],
        ["walk-exterior-front",Vector3(0,9,-48),Vector3(0,6,0)]
    ]:
        camera.global_position=hospital.to_global(spec[1])
        camera.look_at(hospital.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL RECEPTION CAPTURE: ",phase)
    quit()
