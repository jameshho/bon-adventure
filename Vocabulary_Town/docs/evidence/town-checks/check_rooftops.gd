extends SceneTree
## Rooftop landings, the hospital helicopter and the helipad jump progression.
## Reworked 7 Nov 2026: the old Home roof (Buildings/HouseStructure/HomeRoof, with walkable
## West/East slopes) no longer exists (the redesigned Home has a decorative "Home roof" that
## lifts while the learner is under it, main.gd / vehicle_controls.gd), so its slope landings
## and samples were removed; missing nodes now fail instead of stopping the check.
var failures: Array[String] = []
## Which meshes count as rooftops (from the deleted rooftop_collisions.gd pass, 6 Nov 2026).
func is_rooftop_surface(label: String) -> bool:
    label = label.to_lower()
    if label.contains("light") or label.contains("lamp") or label.contains("beam") or label.contains("leaves"):
        return false
    return label.contains("roof") or label.contains("ceiling") or label.contains("canopy") or label.contains("awning") or label.contains("eave")
var checks := 0
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.interaction.set_physics_process(false)
    var player=game.player
    player.set_physics_process(false)
    var town: Node3D=game.apartment
    await physics_frame
    await physics_frame
    var home: Node3D=preload("res://scripts/world/modular_town.gd").building(town,"home")
    check(home!=null and home.has_node("Home roof"),"Home roof present (lifted while under it)")
    check(town.find_child("Great-room peaked roof ridge",true,false)==null,"Old floating ridge removed")
    # Parts renamed when the helicopter got wheels and pilot windows (was CockpitGlass, SkidLeft/Right).
    var heli: Node3D=town.get_node_or_null("Buildings/Hospital/HospitalHelipad/Helicopter")
    check(heli!=null and heli.scene_file_path=="res://scenes/props/vehicles/helicopter.tscn","Separate helicopter instance")
    for part in ["Fuselage","PilotWindowLeft","MainWheelLeft","MainWheelRight","TailBoom","MainRotor","TailRotor"]:
        check(heli!=null and heli.has_node(part),"Editable helicopter component "+part)
    var tested := 0
    for mesh in town.find_children("*","MeshInstance3D",true,false):
        if mesh.mesh==null: continue
        var label: String=str(mesh.name)+" "+str(mesh.get_parent().name)
        if not is_rooftop_surface(label): continue
        # Thin ridge caps and interior ceilings are covered by surface ray checks below.
        var bounds: AABB=mesh.mesh.get_aabb()
        if (bounds.size.x<2 or bounds.size.z<2 or label.to_lower().contains("ceiling")):continue
        var origin: Vector3=mesh.to_global(bounds.get_center())
        var query:=PhysicsRayQueryParameters3D.create(origin+Vector3(0,60,0),origin-Vector3(0,.5,0),1,[player.get_rid()])
        var hit: Dictionary=town.get_world_3d().direct_space_state.intersect_ray(query)
        check(not hit.is_empty(),"Solid surface above "+label)
        if hit.is_empty():continue
        check(hit.normal.y>.70,"Walkable normal above "+label)
        player.global_position=hit.position+Vector3(0,1.3,0)
        player.velocity=Vector3.ZERO
        player.jump_queued=false
        player.reset_physics_interpolation()
        for i in range(60):
            player._physics_process(1.0/60)
            await physics_frame
        check(player.is_on_floor(),"BonBon lands and stands on "+label)
        check(player.global_position.y>hit.position.y-.25,"BonBon cannot fall through "+label)
        # Jump from the actual roof and return to it, rather than only ray testing.
        player.jump_queued=true
        player._physics_process(1.0/60)
        await physics_frame
        check(player.velocity.y>0 and not player.is_on_floor(),"BonBon jumps off "+label)
        for i in range(75):
            player._physics_process(1.0/60)
            await physics_frame
        check(player.is_on_floor(),"BonBon lands again on "+label)
        tested+=1
    print("ROOFTOP LANDINGS: ",tested)
    # Broad samples on the hospital roofs and the helipad deck.
    var surfaces := [
        ["Buildings/Hospital/MainRoof",Vector3(-7,0,8)],
        ["Buildings/Hospital/Azotea/TopSlab5",Vector3(0,0,0)],
        ["Buildings/Hospital/HospitalHelipad/LandingDeck",Vector3(4,0,-4)]]
    for sample in surfaces:
        var mesh: Node3D=town.get_node_or_null(sample[0])
        check(mesh!=null,"Roof sample node exists "+str(sample[0]))
        if mesh==null: continue
        var point: Vector3=mesh.to_global(sample[1])
        var q:=PhysicsRayQueryParameters3D.create(point+Vector3(0,2,0),point-Vector3(0,2,0),1,[player.get_rid()])
        var h: Dictionary=town.get_world_3d().direct_space_state.intersect_ray(q)
        check(not h.is_empty(),"Roof edge/slope collision "+str(sample[0]))
    # Use real input events and the real CharacterBody controller for successive jumps.
    var deck: Node3D=town.get_node_or_null("Buildings/Hospital/HospitalHelipad/LandingDeck")
    check(deck!=null,"Helipad landing deck exists")
    if deck==null:
        print("ROOFTOPS & JUMPS: ",checks," checks, ",failures.size()," failures")
        game.free(); quit(1); return
    var start: Vector3=deck.to_global(Vector3(4,.14,-4))
    player.global_position=start+Vector3(0,.06,0)
    player.velocity=Vector3.ZERO
    for i in range(10):
        player._physics_process(1.0/60)
        await physics_frame
    check(player.is_on_floor(),"Initial helipad footing")
    var walk:=InputEventKey.new()
    walk.physical_keycode=KEY_A
    walk.pressed=true
    Input.parse_input_event(walk)
    var walk_start: Vector3=player.global_position
    for i in range(24):
        player._physics_process(1.0/60)
        await physics_frame
    walk.pressed=false
    Input.parse_input_event(walk)
    check(player.global_position.distance_to(walk_start)>1.5 and player.is_on_floor(),"Real WASD movement walks across helipad")
    player.velocity=Vector3.ZERO
    # Infinite jump is off at the start since 14 Nov 2026 (Features.INFINITE_JUMP_AT_START; the
    # I key turns it on): one press jumps once, a second press in the air does nothing.
    check(not player.infinite_jump_enabled,"Infinite jump off at the start")
    var once:=InputEventKey.new()
    once.keycode=KEY_SPACE
    once.pressed=true
    player._unhandled_input(once)
    player._physics_process(1.0/60)
    await physics_frame
    for tick in range(6):
        player._physics_process(1.0/60)
        await physics_frame
    var rising: float=player.velocity.y
    player._unhandled_input(once)
    player._physics_process(1.0/60)
    await physics_frame
    check(player.consecutive_jumps==1 and player.velocity.y<rising,"Without infinite jump a press in the air does not jump again")
    for tick in range(200):
        player._physics_process(1.0/60)
        await physics_frame
        if player.is_on_floor():break
    check(player.is_on_floor(),"Back on the helipad after the single jump")
    # The successive jumps below test infinite jump itself, switched on as the I key does.
    player.infinite_jump_enabled=true
    player.velocity=Vector3.ZERO
    var previous_height := 0.0
    var space:=InputEventKey.new()
    space.keycode=KEY_SPACE
    space.pressed=true
    for jump in range(6):
        var y: float=player.position.y
        player._unhandled_input(space)
        player._physics_process(1.0/60)
        await physics_frame
        var launch_speed: float=player.velocity.y
        check(player.consecutive_jumps==jump+1,"Jump counter "+str(jump+1))
        if jump==0:check(is_equal_approx(launch_speed,player.jump_speed),"First jump retains original strength")
        var apex: float=player.position.y
        for tick in range(100):
            player._physics_process(1.0/60)
            await physics_frame
            apex=maxf(apex,player.position.y)
            if player.velocity.y<=0:break
        var height: float=apex-y
        check(height>previous_height+.01,"Each successive jump gains actual height "+str(jump+1))
        check(launch_speed<=player.jump_speed*sqrt(player.max_jump_height_multiplier)+.001,"Jump speed stays bounded")
        print("Jump ",jump+1,": launch ",snappedf(launch_speed,.01)," m/s; rise ",snappedf(height,.01)," m")
        previous_height=height
    # Fall naturally to the same deck. Reset must happen on actual contact.
    for tick in range(420):
        player._physics_process(1.0/60)
        await physics_frame
        if player.is_on_floor():break
    check(player.is_on_floor() and player.consecutive_jumps==0,"Landing resets progression")
    player._unhandled_input(space)
    player._physics_process(1.0/60)
    check(is_equal_approx(player.velocity.y,player.jump_speed),"Post-landing jump returns to base strength")
    space.echo=true
    player._unhandled_input(space)
    check(not player.jump_queued,"Key-repeat cannot trigger jumps")
    player.toggle_noclip()
    check(player.consecutive_jumps==0 and not player.jump_queued,"Noclip clears jump progression")
    player.toggle_noclip()
    if "--capture" in OS.get_cmdline_user_args():
        player.visible=false
        var camera:=Camera3D.new()
        town.add_child(camera)
        camera.current=true
        camera.fov=60
        DirAccess.make_dir_recursive_absolute("res://docs/evidence/rooftop-review")
        for view in [["home",Vector3(26,17,32),Vector3(0,4,8)],["hospital",Vector3(-4,34,84),Vector3(-32,18,116)],["helicopter",Vector3(-23,22,106),Vector3(-33,19,115)]]:
            camera.position=view[1]
            camera.look_at(town.to_global(view[2]))
            for i in range(5):await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://docs/evidence/rooftop-review/"+view[0]+".png")
    print("ROOFTOPS & JUMPS: ",checks," checks, ",failures.size()," failures")
    game.free()
    quit(0 if failures.is_empty() else 1)
