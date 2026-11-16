extends SceneTree

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    root.size = Vector2i(1280, 720)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    for i in range(30): await process_frame
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/bonbon-review")
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/bonbon-review/gameplay.png")
    game.player.set_physics_process(false)
    game.player.position = Vector3(6, 0.1, 30)
    game.player.camera_yaw = 2.6
    game.player.camera_pitch = -0.18
    game.player.camera_distance = 5.5
    game.player.spring_arm.spring_length = 5.5
    game.player.reset_camera()
    for i in range(15): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/bonbon-review/bonbon.png")
    game.hud.set_movement_mode(false, true)
    game.player.hyper_enabled = true
    game.player.effects.set_enabled(true)
    for i in range(35):
        game.player.position.x += 0.25
        game.player.camera_rig.global_position = game.player.global_position + Vector3(0, 2.55, 0)
        game.player.effects.update_motion(1.0/60.0, 1.0)
        game.player.animate_bonbon(1.0/60.0, 20.0)
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/bonbon-review/hyper.png")
    game.queue_free()
    await process_frame
    quit()
