extends SceneTree
func _initialize(): run.call_deferred()
func run():
    root.size=Vector2i(1440,1000)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.hide()
    var h: Node3D=game.apartment.get_node("Buildings/Hospital")
    var cam:=Camera3D.new()
    h.add_child(cam)
    cam.current=true
    cam.fov=65
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/hospital-surface-review")
    for v in [["front",Vector3(0,10,-40),Vector3(0,8,-8)],["front-left",Vector3(31,15,-31),Vector3(3,8,0)],["rear",Vector3(-28,22,49),Vector3(0,8,12)],["stair-landing",Vector3(1,2,-3.15),Vector3(6,2,.3)],["stair-room",Vector3(3,3,3.5),Vector3(12,5,.3)],["hall",Vector3(0,2,-11),Vector3(0,2,3)]]:
        cam.position=v[1];cam.look_at(h.to_global(v[2]))
        for i in range(8):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/hospital-surface-review/"+v[0]+".png")
    # Default player camera at the landing reported by the user.
    cam.current=false
    game.camera.current=true
    game.player.global_position=h.to_global(Vector3(14.2,5.6,.3))
    game.player.camera_yaw=PI/2
    game.player.camera_pitch=-.22
    game.player.reset_camera()
    for i in range(15):
        game.player._physics_process(1.0/60.0)
        await physics_frame
    await RenderingServer.frame_post_draw
    print("CAMERA initial ",game.player.spring_arm.get_hit_length()," desired ",game.player.camera_distance)
    root.get_texture().get_image().save_png("res://docs/evidence/hospital-surface-review/player-landing.png")
    quit()
