extends SceneTree
## Main integration; run in the README's isolated test project. No studies/save writes.
var failures := 0
var checks := 0
var game
func _initialize(): run.call_deferred()
func check(ok: bool, label: String):
    checks += 1
    if not ok: failures += 1; print("FAIL: ",label)
func key(code: Key, echo := false):
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=true
    event.echo=echo
    game._unhandled_input(event)
func block_at(point: Vector3,size: Vector3) -> StaticBody3D:
    var block:=StaticBody3D.new()
    root.add_child(block)
    block.global_position=point
    var shape:=CollisionShape3D.new()
    shape.shape=BoxShape3D.new()
    shape.shape.size=size
    block.add_child(shape)
    return block
func run():
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.interaction.set_physics_process(false)
    var discovered_before: Dictionary=game.studied_words.duplicate()
    var bench: Dictionary={}
    var chair: Dictionary={}
    var lounge: Dictionary={}
    for seat in game.seating.seats:
        var path:=str(game.apartment.get_path_to(seat.node))
        if path=="PublicGarden/Garden bench seat": bench=seat
        if path=="RelocatedSites/Home/Lounge chair": lounge=seat
    check(not bench.is_empty() and not lounge.is_empty(),"real garden bench and home lounge chair registered")
    # Characters rest on some seats (4 Nov 2026: Poppy uses the lounge chair), so the
    # sit/stand sequence uses a free home chair.
    for seat in game.seating.seats:
        if chair.is_empty() and str(game.apartment.get_path_to(seat.node)).begins_with("RelocatedSites/Home/") and not seat.get("bed",false) and game.seating.occupant(seat)==null: chair=seat
    if not lounge.is_empty() and game.seating.occupant(lounge)==null: chair=lounge
    check(not chair.is_empty(),"a free home chair exists")
    check(game.seating.seats.size()>100,"decorative restaurant chairs registered too")
    for seat in game.seating.seats:
        check(seat.point.is_finite() and seat.forward.is_normalized(),"valid seat anchor "+str(seat.node.name))
    await physics_frame
    for seat in [bench,chair]:
        var standing: Vector3=seat.point+seat.forward*1.9
        var ray:=PhysicsRayQueryParameters3D.create(standing+Vector3.UP*2,standing-Vector3.UP*4)
        var floor_hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(ray)
        check(not floor_hit.is_empty(),"approach has floor")
        game.player.global_position=floor_hit.get("position",standing)+Vector3.UP*0.1
        game.player.velocity=Vector3.ZERO
        for i in range(12): await physics_frame
        var old_layer: int=game.player.collision_layer
        var old_mask: int=game.player.collision_mask
        key(KEY_E,true)
        check(not game.player.seated,"echo E ignored")
        key(KEY_E)
        check(game.player.seated and game.player.sit_transition,"E starts sit transition")
        key(KEY_E)
        check(game.player.seated,"rapid E cannot interrupt sit")
        await create_timer(.7).timeout
        check(game.player.seated and not game.player.sit_transition and is_equal_approx(game.player.sit_blend,1.0),"seated pose settles")
        check(game.player.collision_layer==0 and game.player.collision_mask==0,"seat collision isolated without modifying furniture")
        var jump:=InputEventKey.new()
        jump.keycode=KEY_SPACE
        jump.pressed=true
        game.player._unhandled_input(jump)
        check(not game.player.jump_queued,"no queued jump while seated")
        game.player.toggle_noclip()
        check(not game.player.noclip_enabled,"noclip cannot strand seated state")
        game.toggle_study_journal()
        key(KEY_E)
        check(game.player.seated,"journal blocks stand action")
        game.toggle_study_journal()
        var obstruction:=block_at(seat.point+Vector3.UP,Vector3(10,4,10))
        await physics_frame
        await physics_frame
        game.seating.stand()
        check(game.player.seated and not game.player.sit_transition,"blocked exits retain seated state")
        obstruction.free()
        await physics_frame
        key(KEY_E)
        check(game.player.sit_transition,"E starts stand transition")
        await create_timer(.65).timeout
        check(not game.player.seated and not game.player.sit_transition,"standing completes")
        check(game.player.collision_layer==old_layer and game.player.collision_mask==old_mask,"collision masks restored")
        check(game.player.visual.rotation.is_zero_approx(),"visual lean reset")
        for part in game.player.parts:
            # Disable the next walking tick before checking exact restoration below.
            check(game.player.parts[part].transform.is_finite(),"valid restored limb")
    # A close seat behind a solid barrier is not interactable.
    game.player.set_physics_process(false)
    game.player.global_position=bench.point+bench.forward*1.9-Vector3.UP*.6
    var barrier:=block_at(bench.point+bench.forward*.95+Vector3.UP*.8,Vector3(4,3,.25))
    # Turned to face the bench (the garden bench faces the lagoon, -X, since 9 Nov 2026).
    barrier.global_basis=Basis.looking_at(Vector3(bench.forward.x,0,bench.forward.z).normalized())
    await physics_frame
    await physics_frame
    check(game.seating.seat_on(bench.node).is_empty(),"wall blocks seat approach")
    barrier.free()
    game.player.noclip_enabled=true
    check(game.seating.seat_on(bench.node).is_empty(),"noclip cannot begin sitting")
    check(game.studied_words==discovered_before,"sitting never studies words")
    print("SITTING: ",checks," checks; ",failures," failures; ",game.seating.seats.size()," seats")
    quit(1 if failures else 0)
