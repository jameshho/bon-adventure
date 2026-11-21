extends SceneTree
## Diagnoses road vehicles in their real parked spots: drive forward, then steer, and log heading
## change and what blocks rotation.
var game
func _initialize(): run.call_deferred()
func run():
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for v in game.driveable_vehicles:
        v.set_physics_process(false)
        v.set_process(false)
    for i in 3: await physics_frame
    var n:=0
    for v in game.driveable_vehicles:
        if v.helicopter or v.fixed_wing: continue
        n+=1
        if n>12: break
        var original: Transform3D=v.global_transform
        v.occupied=true
        v.road_physics.reset()
        for i in 30: v.drive_step(1.0/60,0,0,1.0)
        var space=v.get_world_3d().direct_space_state
        var blockers:=[]
        for hull in v.flight_hulls:
            for r in space.intersect_shape(v.hull_query(hull,v.global_transform,v.road_physics.ground_exclusions),4):
                blockers.append(str(r.collider.get_path()).get_slice("/",-2)+"/"+r.collider.name)
        var h0: Vector3=v.travel_forward()
        var p0: Vector3=v.global_position
        var fails:=0
        for i in 90: v.drive_step(1.0/60,1,0,0)
        var h1: Vector3=v.travel_forward()
        var yaws:=[]
        for i in 120:
            v.drive_step(1.0/60,1,1,0)
            if i%20==0: yaws.append(snappedf(v.road_physics.yaw_velocity,.01))
        var h2: Vector3=v.travel_forward()
        print("DIAG ",v.name," sup=",v.road_physics.supported," contacts=",v.road_physics.contacts.size(),
            " moved=",snappedf(p0.distance_to(v.global_position),.1)," speed=",snappedf(v.current_speed,.1),
            " straight_turn=",snappedf(rad_to_deg(h0.signed_angle_to(h1,Vector3.UP)),.1),
            " steer_turn=",snappedf(rad_to_deg(h1.signed_angle_to(h2,Vector3.UP)),.1),
            " steer_angle=",snappedf(v.road_physics.steering_angle,.01)," yaw=",yaws,
            " rest_overlaps=",blockers)
        v.global_transform=original
        v.occupied=false
        v.road_physics.reset()
    # Flat pad: turning circle at steady speeds, holding D.
    var pad=game.box("Diag pad",Vector3.ZERO,Vector3(400,.4,400),Color.WHITE,"",true)
    pad.global_position=Vector3(1000,0,1000)
    for i in 2: await physics_frame
    for title in ["Car","Taxi","Bus","Fire_Truck","Motorcycle"]:
        var v=null
        for c in game.driveable_vehicles:
            if c.name==title: v=c
        if v==null: continue
        var original: Transform3D=v.global_transform
        for target in [4.0,8.0,16.0,24.0]:
            v.global_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.3),Vector3(1000,.45,1000))
            v.road_physics.reset()
            v.occupied=true
            for i in 30: v.drive_step(1.0/60,0,0,1.0)
            var t:=0
            while absf(v.current_speed)<target and t<900:
                v.drive_step(1.0/60,1,0,0)
                t+=1
            var h0: Vector3=v.travel_forward()
            var ms:=-1
            for i in 180:
                v.drive_step(1.0/60,1 if absf(v.current_speed)<target else 0.0,1,0)
                if ms<0 and absf(v.road_physics.yaw_velocity)>.3*absf(v.current_speed)*.0+.15: ms=i*16
            var yaw: float=v.road_physics.yaw_velocity
            print("PAD ",title," target=",target," speed=",snappedf(v.current_speed,.1)," yaw=",snappedf(yaw,.01),
                " radius=",snappedf(absf(v.current_speed/yaw) if absf(yaw)>.001 else INF,.1)," turned3s=",
                snappedf(rad_to_deg(h0.signed_angle_to(v.travel_forward(),Vector3.UP)),1)," ms_to_turn=",ms,
                " slip=",snappedf(v.road_physics.velocity.dot(v.travel_forward().cross(Vector3.UP)),.01))
        v.global_transform=original
        v.occupied=false
        v.road_physics.reset()
    pad.free()
    quit(0)
