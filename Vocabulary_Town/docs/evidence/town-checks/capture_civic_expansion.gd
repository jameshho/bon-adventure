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
    var cam:=Camera3D.new()
    game.apartment.add_child(cam)
    cam.current=true
    cam.fov=78
    var views=[
        ["clothing_road",Vector3(44,2.1,91),Vector3(50.5,1.3,110)],
        ["police_car",Vector3(37,2.5,91.5),Vector3(42,1,95.9)]]
    for building in ["School","Hospital"]:
        var wing: Node3D=game.apartment.get_node("Buildings/"+building+"/LearningWing")
        for room in wing.get_children():
            if not room.has_meta("theme"):continue
            views.append([building+"_"+str(room.name),game.apartment.to_local(room.to_global(Vector3(0,2.3,-.8))),game.apartment.to_local(room.to_global(Vector3(0,1.15,3.6)))])
    for view in views:
        cam.position=view[1]
        cam.look_at(game.apartment.to_global(view[2]))
        for i in range(10):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/civic-review/"+view[0]+".png")
    game.free()
    quit()
