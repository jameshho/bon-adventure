extends SceneTree
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=175
    game.add_child(camera)
    camera.position=game.apartment.to_global(Vector3(0,180,100))
    camera.look_at(game.apartment.to_global(Vector3(0,0,137)),Vector3(0,0,1))
    camera.current=true
    for frame in range(8): await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/guides/public-garden/overview.png")
    camera.size=65
    camera.position=game.apartment.to_global(Vector3(-65,28,100))
    camera.look_at(game.apartment.to_global(Vector3(-20,0,139)))
    for frame in range(5): await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/guides/public-garden/bridge.png")
    camera.size=255
    camera.position=game.apartment.to_global(Vector3(0,230,95))
    camera.look_at(game.apartment.to_global(Vector3(0,0,137)),Vector3(0,0,1))
    for frame in range(5): await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/guides/public-garden/districts.png")
    camera.size=33
    camera.position=game.apartment.to_global(Vector3(85,19,116))
    camera.look_at(game.apartment.to_global(Vector3(53,3,139)))
    for frame in range(5): await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/guides/public-garden/washington.png")
    camera.size=24
    camera.position=game.apartment.to_global(Vector3(-58,12,111))
    camera.look_at(game.apartment.to_global(Vector3(-40,1,127)))
    for frame in range(5): await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/guides/public-garden/dock.png")
    # Full central district, north up, including all four inner sidewalk connections.
    camera.size=310
    camera.position=game.apartment.to_global(Vector3(0,300,127))
    camera.look_at(game.apartment.to_global(Vector3(0,0,127)),Vector3(0,0,1))
    for frame in range(5): await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/guides/public-garden/blueprint-trails.png")
    quit()
