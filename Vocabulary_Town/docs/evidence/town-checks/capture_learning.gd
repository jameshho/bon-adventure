extends SceneTree
func _initialize():run.call_deferred()
func run():
    root.size=Vector2i(1440,900)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.hide()
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    var camera:=Camera3D.new()
    game.apartment.add_child(camera)
    camera.current=true
    camera.fov=73
    var views=[
        ["sports",Vector3(26,2.8,105),Vector3(26,1.3,117)],
        ["furniture",Vector3(-52,2.8,105),Vector3(-52,1.3,119)],
        ["bakery",Vector3(50.5,2.8,127),Vector3(50.5,1.3,139)],
        ["electronics",Vector3(-59.5,2.5,39),Vector3(-59.5,1.3,46)],
        ["market",Vector3(-33,2.6,39),Vector3(-33,1.3,46)]
    ]
    for view in views:
        camera.position=view[1]
        camera.look_at(game.apartment.to_global(view[2]))
        for frame in range(8):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/learning-review/"+view[0]+".png")
    game.free()
    quit()
