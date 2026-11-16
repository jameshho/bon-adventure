extends SceneTree

var failures: Array[String] = []
var player

func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)

func key(code: Key, echo := false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    event.echo = echo
    player._unhandled_input(event)

func mouse(button: MouseButton, pressed := true) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = button
    event.pressed = pressed
    player._input(event)
    player._unhandled_input(event)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    var world := Node3D.new()
    root.add_child(world)
    var floor_body := StaticBody3D.new()
    var floor_shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(200, 1, 200)
    floor_shape.shape = box
    floor_body.add_child(floor_shape)
    floor_body.position.y = -0.5
    world.add_child(floor_body)
    player = load("res://scenes/player/bonbon_player.tscn").instantiate()
    world.add_child(player)
    await physics_frame
    await physics_frame
    check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Cursor starts free")
    check(is_equal_approx(player.get_node("PlayerCollision").shape.radius, 0.76), "Original capsule radius preserved")
    check(player.get_node("Visual/BonBon").scale == Vector3.ONE, "Uniform playable model scale")
    check(player.get_node("Visual/BonBon/SolidBody/Collision").disabled, "No self collision")
    key(KEY_SHIFT)
    check(player.sprint_enabled, "Shift toggles sprint on")
    key(KEY_SHIFT, true)
    check(player.sprint_enabled, "Key repeat cannot toggle sprint")
    key(KEY_H)
    check(player.hyper_enabled and player.sprint_enabled, "Hyper and sprint coexist")
    check(player.effects.surfaces[0].material_overlay == player.effects.aura, "Hyper aura enabled")
    key(KEY_H)
    check(not player.hyper_enabled and player.sprint_enabled, "Hyper off restores sprint")
    check(player.effects.surfaces[0].material_overlay == player.effects.original_overlays[0], "Original materials restored")
    check(not player.effects.particles.visible and player.effects.points.is_empty(), "Hyper off removes particles and trail")
    key(KEY_SHIFT)
    check(not player.sprint_enabled, "Sprint toggles off")
    for i in range(3):
        key(KEY_SPACE)
        await physics_frame
        await physics_frame
        check(player.velocity.y > 7.0, "Consecutive jump " + str(i))
    # Exercise actual physical WASD input, acceleration and independent facing.
    var forward := InputEventKey.new()
    forward.physical_keycode = KEY_W
    forward.pressed = true
    Input.parse_input_event(forward)
    for i in range(30): await physics_frame
    check(player.velocity.z < -5.8, "W accelerates to walking speed")
    key(KEY_SHIFT)
    for i in range(20): await physics_frame
    check(player.velocity.z < -9.8, "Sprint is faster than walk")
    key(KEY_H)
    for i in range(50): await physics_frame
    check(player.velocity.z < -27.5, "Hyper is significantly faster than sprint")
    key(KEY_SPACE)
    await physics_frame
    await physics_frame
    check(player.hyper_enabled and player.sprint_enabled and player.velocity.y > 7.0, "Hyper sprint and midair jump coexist")
    key(KEY_H)
    key(KEY_SHIFT)
    player.camera_yaw = PI / 2
    for i in range(50): await physics_frame
    check(player.velocity.x < -5.5 and absf(player.velocity.z) < 0.4, "W movement follows camera yaw")
    check(absf(angle_difference(player.rotation.y, PI / 2)) < 0.1, "BonBon smoothly faces movement")
    forward.pressed = false
    Input.parse_input_event(forward)
    for i in range(20): await physics_frame
    check(Vector2(player.velocity.x, player.velocity.z).length() < 0.1, "Releasing WASD decelerates to rest")
    player.rotation.y = 0
    player.set_physics_process(false)
    var old_yaw: float = player.camera_yaw
    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(100, 30)
    player._unhandled_input(motion)
    check(player.camera_yaw == old_yaw, "Free mouse does not orbit")
    mouse(MOUSE_BUTTON_RIGHT)
    player._unhandled_input(motion)
    check(player.camera_yaw != old_yaw and player.rotation.y == 0.0, "RMB orbits without turning character")
    mouse(MOUSE_BUTTON_RIGHT, false)
    check(not player.orbiting and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "RMB release frees cursor")
    for i in range(30): mouse(MOUSE_BUTTON_WHEEL_UP)
    check(player.camera_distance == player.min_camera_distance, "Zoom minimum remains third person")
    for i in range(40): mouse(MOUSE_BUTTON_WHEEL_DOWN)
    check(player.camera_distance == player.max_camera_distance, "Zoom maximum clamped")
    player.set_controls_enabled(false)
    key(KEY_H)
    key(KEY_SPACE)
    mouse(MOUSE_BUTTON_RIGHT)
    check(not player.hyper_enabled and not player.jump_queued and not player.orbiting, "Modal UI blocks gameplay input")
    player.set_controls_enabled(true)
    player.position = Vector3.ZERO
    player.camera_yaw = 0
    player.camera_pitch = 0
    player.reset_camera()
    player.spring_arm.spring_length = 6.5
    var wall := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var wall_box := BoxShape3D.new()
    wall_box.size = Vector3(10, 10, 0.5)
    shape.shape = wall_box
    wall.add_child(shape)
    wall.position = Vector3(0, 2.55, 3)
    world.add_child(wall)
    for i in range(5): await physics_frame
    check(player.spring_arm.get_hit_length() < 3.0, "Camera sphere sweep stops before wall")
    check(player.camera.global_position.y > 2.2, "Compressed camera remains above BonBon, outside her head")
    wall.queue_free()
    for i in range(5): await physics_frame
    check(player.spring_arm.get_hit_length() > 6.0, "Camera recovers after obstacle removed")
    key(KEY_H)
    for i in range(100):
        player.position.x += 0.2
        player.effects.update_motion(1.0/60.0, 1.0)
    check(player.effects.points.size() <= player.effects.max_trail_points, "Trail memory bounded")
    check(player.effects.ribbon.get_surface_count() == 1, "Moving hyper mode draws trail")
    check(player.effects.find_children("*", "OmniLight3D", true, false).is_empty() and player.effects.find_children("*", "CanvasLayer", true, false).is_empty(), "Hyper adds no light or screen bloom")
    key(KEY_H)
    check(player.effects.ribbon.get_surface_count() == 0, "Hyper off clears ribbon")
    world.free()
    print("BONBON: ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)
