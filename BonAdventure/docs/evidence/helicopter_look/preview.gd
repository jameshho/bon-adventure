extends SceneTree
func _initialize(): run.call_deferred()
func run():
    root.size=Vector2i(1280,800)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    game.player.visible=false
    game.hud.visible=false
    var heli=game.apartment.get_node("Buildings/Hospital/HospitalHelipad/Helicopter")
    heli.set_process(false)
    heli.set_physics_process(false)
    var camera=Camera3D.new()
    root.add_child(camera)
    camera.current=true
    camera.fov=43
    for view in ["front","rear"]:
        camera.global_position=heli.global_position+Vector3(11,7,-14 if view=="front" else 16)
        camera.look_at(heli.global_position+Vector3(0,2,1))
        for i in range(10): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/helicopter_look/"+view+".png")
    print("Helicopter graphical main-scene previews captured")
    quit()
