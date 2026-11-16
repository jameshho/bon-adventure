extends SceneTree
var game
var hospital: Node3D
var errors: Array[String]=[]
var camera_samples: Array[float]=[]
func _initialize():run.call_deferred()
func check(ok: bool,text: String) -> void:
    if not ok:
        errors.append(text)
        push_error(text)
func key_w(pressed: bool) -> void:
    var event:=InputEventKey.new()
    event.keycode=KEY_W
    event.physical_keycode=KEY_W
    event.pressed=pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
func frame() -> void:
    game.player._physics_process(1.0/60.0)
    await physics_frame
func walk(p: Vector3, sample := false) -> void:
    var target:=hospital.to_global(p)
    var delta: Vector3=target-game.player.global_position
    delta.y=0
    if delta.length()<.18:return
    key_w(false)
    game.player.camera_yaw=atan2(-delta.x,-delta.z)
    for i in range(20):await frame()
    key_w(true)
    var reached:=false
    for i in range(450):
        await frame()
        var d: Vector3=target-game.player.global_position
        d.y=0
        if sample:camera_samples.append(game.player.spring_arm.get_hit_length())
        if d.length()<.2:
            reached=true
            break
    key_w(false)
    for i in range(8):await frame()
    check(reached,"Normal W movement blocked to "+str(p)+" actual "+str(hospital.to_local(game.player.global_position)))
func shot(name: String) -> void:
    if not "--capture" in OS.get_cmdline_user_args():return
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/hospital-surface-review/"+name+".png")
func run() -> void:
    root.size=Vector2i(1440,1000)
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.hide()
    hospital=game.apartment.get_node("Buildings/Hospital")
    game.player.global_position=hospital.to_global(Vector3(0,.05,-3.15))
    game.player.velocity=Vector3.ZERO
    game.player.camera_pitch=-.22
    game.player.reset_camera()
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/hospital-surface-review")
    for level in range(3):
        # Both same-floor entrances and return path must work with normal controls.
        await walk(Vector3(3.5,0,-3.15))
        await walk(Vector3(3.5,0,3.45))
        await walk(Vector3(0,0,3.45))
        await walk(Vector3(14.4,0,3.45))
        check(absf(hospital.to_local(game.player.global_position).y-level*5.6)<.22,"Rear entrance/gallery stays on floor "+str(level+1))
        await walk(Vector3(0,0,3.45))
        await walk(Vector3(3.5,0,3.45))
        await walk(Vector3(3.5,0,.3))
        # Walk offset from center on alternate storeys, not a single magic path.
        # Floor 3's flight (31 Oct 2026) climbs to the roof stair house.
        var lane: float=[-.6,1.2,0.0][level]
        await walk(Vector3(3.5,0,lane))
        await walk(Vector3(9,0,lane),true)
        await shot("player-ascent"+str(level+1))
        await walk(Vector3(14.2,0,lane),true)
        var top: float=(level+1)*5.6 if level<2 else 16.925
        check(absf(hospital.to_local(game.player.global_position).y-top)<.22,"Normal ascent "+("floor "+str(level+2) if level<2 else "roof"))
        await shot("player-arrival"+str(level+2))
        if level<2:
            await walk(Vector3(14.2,0,3.45))
            await walk(Vector3(0,0,3.45))
        else:
            await walk(Vector3(14.6,0,1.8))
            check(absf(hospital.to_local(game.player.global_position).y-top)<.22,"Roof stair house landing by the door")
            await walk(Vector3(14.2,0,.3))
            await walk(Vector3(9,0,.3),true)
            await walk(Vector3(3.5,0,.3),true)
            check(absf(hospital.to_local(game.player.global_position).y-11.2)<.22,"Normal descent from the roof")
            await walk(Vector3(3.5,0,3.45))
            await walk(Vector3(0,0,3.45))
    for level in range(2):
        await walk(Vector3(0,0,3.45))
        await walk(Vector3(14.2,0,3.45))
        await walk(Vector3(14.2,0,.3))
        await walk(Vector3(9,0,.3),true)
        await shot("player-descent"+str(level))
        await walk(Vector3(3.5,0,.3),true)
        check(absf(hospital.to_local(game.player.global_position).y-(1-level)*5.6)<.22,"Normal descent floor "+str(2-level))
        await walk(Vector3(3.5,0,3.45))
        await walk(Vector3(0,0,3.45))
    camera_samples.sort()
    print("STAIR CAMERA: min=",camera_samples[0]," median=",camera_samples[camera_samples.size()/2]," samples=",camera_samples.size())
    print("NORMAL STAIR ACCESS: ",errors.size()," failures; normal controller + W, front/rear approaches, offset lanes, all floors and the roof")
    quit(0 if errors.is_empty() else 1)
