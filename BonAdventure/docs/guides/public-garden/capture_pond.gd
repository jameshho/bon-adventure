extends SceneTree
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
    for spec in [["overview",Vector3(77,62,190),Vector3(-12,0,136)],["bank",Vector3(12,6,157),Vector3(-24,1,149)],["approach",Vector3(17,5,139),Vector3(-25,3,139)],["monument",Vector3(88,9,119),Vector3(42,1,140)],["lawns",Vector3(36,5,165),Vector3(65,.4,151)],["fountains",Vector3(88,5,135),Vector3(59,1,141)],["plan",Vector3(53,90,140),Vector3(53,0,139)]]:
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[0]=="plan" else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=100
        camera.global_position=town.to_global(spec[1])
        camera.look_at(town.to_global(spec[2]),Vector3(0,0,1) if spec[0]=="plan" else Vector3.UP)
        for i in range(12): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/pond-"+tag+"-"+spec[0]+".png")
    quit()
