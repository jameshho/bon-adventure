extends SceneTree
## 28 Oct 2026: airport metal detector clearance, every airport seat sittable from the
## front, and the steerable swan boats (standing, bench seats, saddle steering, lagoon
## bounds). Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_seats_and_swan_boats.gd
var fails:=0
func check(ok: bool, label: String) -> void:
    print(("ok   " if ok else "FAIL ")+label)
    if not ok: fails+=1
func capsule_clear(game, p: Vector3) -> bool:
    var q:=PhysicsShapeQueryParameters3D.new()
    q.shape=game.player.get_node("PlayerCollision").shape
    q.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*1.1)
    q.exclude=[game.player.get_rid()]
    return game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()
func frames(n: int) -> void:
    for i in n: await physics_frame
func _initialize(): run.call_deferred()
func run() -> void:
    create_timer(420).timeout.connect(func(): print("TIMEOUT"); quit())
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await frames(3)
    var player=game.player
    var terminal: Node3D=game.apartment.get_node("Airport/Terminal")
    # --- detector: walk through along the lane
    player.global_position=terminal.to_global(Vector3(1.6,.1,4.7))
    await frames(5)
    var start_x: float=terminal.to_local(player.global_position).x
    for i in 120:
        player.velocity=terminal.global_basis.x.normalized()*4.0
        player.move_and_slide()
        await physics_frame
    var end_local: Vector3=terminal.to_local(player.global_position)
    check(end_local.x>6.0, "walked through detector and security gap: x %.2f -> %.2f (z %.2f)"%[start_x,end_local.x,end_local.z])
    # --- airport seats
    var ok:=0
    var tried:=0
    for s in game.seating.seats:
        if not terminal.is_ancestor_of(s.node): continue
        tried+=1
        # Café chairs face their table: approach from the side; row seats from the front.
        var cafe: bool=terminal.to_local(s.point).x< -8
        var start: Vector3=s.point+(s.forward.cross(Vector3.UP)*1.1 if cafe else s.forward*1.1)
        start.y=terminal.global_position.y+.12
        player.global_position=start
        await frames(4)
        var near: Dictionary=game.seating.focused_seat()
        if near.get("node")==s.node and game.interaction.activate_focus():
            await frames(40)
            if player.seated:
                ok+=1
                game.seating.stand()
                await frames(40)
                if player.seated: print("  could not stand: ",s.node.name)
        else: print("  no seat: ",terminal.to_local(s.point).snapped(Vector3.ONE*.01)," near ",near.get("label","NONE"))
    check(ok==tried, "airport seats sat on intended seat: %d/%d"%[ok,tried])
    # --- swan boats
    var boats:=[]
    for c in game.apartment.get_children():
        if String(c.name).begins_with("Swan boat") and c.has_method("drive"): boats.append(c)
    check(boats.size()==2,"two swan boat roots")
    check(game.apartment.get_node("PublicGarden").find_children("Swan*","",false,false).filter(func(n): return not String(n.name).begins_with("Swan boat landing")).is_empty(),"no swan parts left in garden")
    for boat in boats:
        boat.set_physics_process(false)
        var n:=0
        for s in game.seating.seats: if boat.is_ancestor_of(s.node): n+=1
        check(n==6,"%s seats registered: %d"%[boat.name,n])
        check(boat.find_children("Swan sculpted neck*","MeshInstance3D",false,false).size()==1,"%s carries its neck"%boat.name)
        check(boat.clear_at(boat.transform),"%s starts clear of obstacles"%boat.name)
        check(boat.afloat(boat.transform),"%s starts inside lagoon"%boat.name)
        print("  parts ",boat.get_child_count()," pos ",boat.position," yaw ",rad_to_deg(boat.rotation.y))
    var boat=boats[0]
    # stand on the bow deck
    player.global_position=boat.to_global(Vector3(0,1.2,-3.45))
    player.velocity=Vector3.ZERO
    await frames(60)
    var lp: Vector3=boat.to_local(player.global_position)
    check(player.is_on_floor() and lp.y>.25,"stands on bow deck (local y %.2f)"%lp.y)
    # walk from the dock onto the boat
    var dock: Node3D=game.apartment.get_node("PublicGarden").find_child("Swan boat landing",false,false)
    if dock:
        player.global_position=dock.global_position+Vector3.UP*.3
        await frames(20)
        var toward: Vector3=(boat.global_position-dock.global_position)*Vector3(1,0,1)
        for i in 90:
            player.velocity=toward.normalized()*5.0+Vector3.DOWN*2
            player.move_and_slide()
            await physics_frame
        lp=boat.to_local(player.global_position)
        print("  dock walk ended at boat-local ",lp.snapped(Vector3.ONE*.01)," floor ",player.is_on_floor())
    # sit on a bench from a bench top
    player.global_position=boat.to_global(Vector3(0,.7,-.8))
    await frames(30)
    var near: Dictionary=game.seating.focused_seat()
    check(near.get("label","")=="swan boat bench","bench seat offered from bench top: "+str(near.get("label","NONE")))
    check(game.interaction.activate_focus(),"sit on bench")
    await frames(40)
    game.seating.stand()
    await frames(40)
    check(not player.seated and boat.is_ancestor_of(game.seating.current.node),"stood up from bench")
    lp=boat.to_local(player.global_position)
    print("  after standing, boat-local ",lp.snapped(Vector3.ONE*.01))
    # sit on saddle from the last bench
    player.global_position=boat.to_global(Vector3(0,.7,1.3))
    await frames(30)
    near=game.seating.focused_seat()
    check(near.get("node")==boat.saddle,"saddle offered from last bench: "+str(near.get("label","NONE")))
    check(game.interaction.activate_focus(),"sit on saddle")
    await frames(40)
    check(boat.piloted(),"saddle pilots the boat")
    var before: Vector3=boat.position
    var yaw0: float=boat.rotation.y
    for i in 180:
        boat.drive(1.0/60,1.0,0.0)
        await physics_frame
    var moved: float=before.distance_to(boat.position)
    check(moved>2.0,"W moves boat forward %.2f town units"%moved)
    for i in 120:
        boat.drive(1.0/60,1.0,1.0)
        await physics_frame
    check(absf(angle_difference(yaw0,boat.rotation.y))>.3,"A turns boat: %.1f deg"%rad_to_deg(angle_difference(yaw0,boat.rotation.y)))
    var seat_err: float=player.global_position.distance_to(boat.saddle.to_global(Vector3(0,.04,0))+(boat.global_basis*Vector3(0,0,-1)).normalized()*.12-Vector3.UP*.17)
    check(seat_err<.05,"pilot rides with the saddle (err %.3f)"%seat_err)
    # drive for a long time into the shore: must stay inside lagoon
    for i in 1200:
        boat.drive(1.0/60,1.0,0.0)
        if i%10==0: await physics_frame
    check(boat.afloat(boat.transform),"stays in lagoon after long drive, pos "+str(boat.position.snapped(Vector3.ONE*.1)))
    for i in 300: boat.drive(1.0/60,0.0,0.0)
    await frames(3)
    game.seating.stand()
    await frames(50)
    lp=boat.to_local(player.global_position)
    check(not player.seated and absf(lp.z-1.3)<.6 and lp.y>.4,"stood from saddle onto last bench (local %s)"%str(lp.snapped(Vector3.ONE*.01)))
    print("SEATS AND SWAN BOATS: ",fails," failures")
    quit()
