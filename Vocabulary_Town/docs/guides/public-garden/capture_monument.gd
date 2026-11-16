extends SceneTree
## Washington monument close views matching the user's Boston photographs.
## Usage: godot --path . --resolution 1200x800 --script res://docs/guides/public-garden/capture_monument.gd -- <tag> <absolute folder>
## Town-local coordinates (+X west, +Z north); the statue stands at (53,0,139).
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town=game.apartment
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=60
    var args=OS.get_cmdline_user_args()
    var tag=args[0]
    var folder=args[1]
    for spec in [["fountain",Vector3(81,2.1,120),Vector3(60,3.5,141)],["beds",Vector3(64.5,1.8,129),Vector3(86,.6,146)],["avenue",Vector3(39,1.8,139.4),Vector3(4,2.2,139)],["statue",Vector3(62,6.5,128.5),Vector3(53,4.6,139)],["forecourt",Vector3(100,14,139),Vector3(64,0,139)],["trails",Vector3(110,52,110),Vector3(50,0,147)],["plan",Vector3(62,80,139),Vector3(62,0,139)]]:
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[0]=="plan" else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=72
        camera.global_position=town.to_global(spec[1])
        camera.look_at(town.to_global(spec[2]),Vector3(0,0,1) if spec[0]=="plan" else Vector3.UP)
        for i in range(12): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/monument-"+tag+"-"+spec[0]+".png")
    quit()
