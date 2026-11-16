extends SceneTree
## Hospital sign clean-up: no hanging signs, door plaques, stair signs, landing insets (hospital-local cameras); isolated copy, 1200x900.
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-signs-20261027/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/hospital-signs-20261027/"+phase
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
        ["entrance-hall",Vector3(0,1.9,-11.5),Vector3(0,2,6)],
        ["stair-signs",Vector3(3.6,1.9,-.6),Vector3(5.5,2.6,-4.4)],
        ["stair-landing",Vector3(1.4,2.8,-1.8),Vector3(3.6,0,.6)],
        ["stair-top-floor2",Vector3(12.2,5.6+2.2,.3),Vector3(16,5.6+2.4,-1)],
        ["hall-floor2",Vector3(0,5.6+1.9,-11.5),Vector3(0,5.6+2,19)],
        ["door-plaques-floor2",Vector3(-.3,5.6+1.9,9.6),Vector3(1.9,5.6+2,13.3)],
        ["elevator-from-hall",Vector3(2.4,1.8,1.2),Vector3(-4,2.6,-.2)]
    ]:
        camera.global_position=hospital.to_global(spec[1])
        camera.look_at(hospital.to_global(spec[2]))
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("HOSPITAL SIGNS CAPTURE: ",phase)
    quit()
