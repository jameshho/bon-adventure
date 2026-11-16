extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.interaction.set_physics_process(false)
    game.player.set_physics_process(false)
    game.player.visible=false
    game.player.effects.clear_trail()
    game.hud.ui_root.hide()
    var town: Node3D=game.apartment
    var camera:=Camera3D.new()
    town.add_child(camera)
    camera.current=true
    camera.fov=60
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/rooftop-review")
    for view in [["home",Vector3(26,17,32),Vector3(0,4,8)],["hospital",Vector3(-4,34,84),Vector3(-32,18,116)],["helicopter",Vector3(-23,22,106),Vector3(-33,19,115)]]:
        camera.position=view[1]
        camera.look_at(town.to_global(view[2]))
        for i in range(8):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/rooftop-review/"+view[0]+".png")
    game.free()
    quit()
