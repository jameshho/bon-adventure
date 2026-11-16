extends SceneTree
## Playground rebuild views (1 Nov 2026). Uses Main, which saves progress: run with an
## isolated user directory (README).
## godot --path . --resolution 1200x800 --script res://docs/evidence/playground-20261101/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func shot(camera: Camera3D,from: Vector3,at: Vector3,file: String) -> void:
    camera.global_position=from
    camera.look_at(at)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(file)
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/playground-20261101/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera); camera.current=true
    camera.fov=55.0; camera.far=900.0
    var site: Node3D=game.apartment.get_node("RelocatedSites/Playground")
    # World frame of the equipment holder: +X west, +Z north, metres.
    var c: Vector3=site.to_global(Vector3(12,0,79))
    await shot(camera,c+Vector3(0,34,-.1),c,folder+"/aerial.png")
    await shot(camera,c+Vector3(-4,13,-27),c+Vector3(0,1.5,0),folder+"/front.png")
    if phase=="before": quit(); return
    await shot(camera,c+Vector3(-9,7,-9),c+Vector3(0,3,6.8),folder+"/towers.png")
    await shot(camera,c+Vector3(15,6,-1),c+Vector3(5,2.5,5),folder+"/stairs.png")
    await shot(camera,c+Vector3(-14,4,-5),c+Vector3(-6,1.2,1),folder+"/slide.png")
    await shot(camera,c+Vector3(-3,4.5,-14),c+Vector3(-6,.5,-4),folder+"/merry-go-round.png")
    await shot(camera,c+Vector3(4,4,-4),c+Vector3(5,.8,1),folder+"/seesaw-bars.png")
    # BonBon standing mid-bridge (side ropes 2.1 apart), from above the south rail.
    var kit: Node3D=site.get_node("Playground equipment")
    game.player.global_position=kit.to_global(Vector3(0,1.9,6.8))
    game.player.rotation.y=PI*.5
    await shot(camera,kit.to_global(Vector3(1.5,5.2,1.2)),kit.to_global(Vector3(0,2.6,6.8)),folder+"/bridge-bonbon.png")
    await shot(camera,kit.to_global(Vector3(4.6,3.6,6.8)),kit.to_global(Vector3(-2,2.4,6.8)),folder+"/bridge-along.png")
    # BonBon seated on the west swing, then held at three points of a high arc.
    var swing: Node3D=site.get_node("Playground equipment/Swing set").get_children().filter(func(n): return n.get_script()!=null)[0]
    var seat: Node3D=swing.seat
    game.player.set_physics_process(true)
    game.player.global_position=seat.global_position+Vector3(0,.2,-1.8)
    await physics_frame
    print("SIT: ",game.seating.try_sit())
    for i in range(60): await physics_frame
    # Freeze the pendulum at each pose; carry() places BonBon exactly as in play.
    swing.set_physics_process(false)
    var hang: Vector3=swing.global_position
    for pose in [[0.0,"swing-seated"],[1.0,"swing-forward"],[-0.95,"swing-back"]]:
        swing.angle=pose[0]; swing.rotation.x=pose[0]; swing.carry()
        await physics_frame
        var at: Vector3=seat.global_position+Vector3(0,.6,0)
        await shot(camera,Vector3(hang.x-5.5,at.y+1.2,at.z-4.5),at,folder+"/"+pose[1]+".png")
    swing.set_physics_process(true)
    await shot(camera,c+Vector3(9.5,3.2,-12),c+Vector3(9,1.6,-6.6),folder+"/swing-front.png")
    print("PLAYGROUND CAPTURE: ",phase)
    quit()
