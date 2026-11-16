extends SceneTree
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.player.set_physics_process(false)
    var camera=Camera3D.new()
    game.add_child(camera)
    camera.position=game.apartment.to_global(Vector3(-65,16,115))
    camera.look_at(game.apartment.to_global(Vector3(-20,1,139)))
    camera.current=true
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    for i in range(40): await process_frame
    var times=[]
    for i in range(120):
        var start=Time.get_ticks_usec()
        await process_frame
        times.append((Time.get_ticks_usec()-start)/1000.0)
    times.sort()
    print("BENCHMARK median_ms=",times[60]," p95_ms=",times[114]," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/guides/performance/latest.png")
    quit()
