extends SceneTree
func _initialize(): run.call_deferred()
func run():
    root.size=Vector2i(1100,1300)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    var home=game.apartment.get_node("RelocatedSites/Home")
    var count:=0
    await physics_frame
    await physics_frame
    for door in game.doors:
        if not home.is_ancestor_of(door): continue
        count+=1
        var state: Dictionary=game.doors[door]
        var collision: CollisionShape3D=door.find_children("*","CollisionShape3D",true,false)[0]
        var query:=PhysicsShapeQueryParameters3D.new()
        var shape:=BoxShape3D.new()
        shape.size=Vector3(1.54,2.60,.12)*1.3
        query.shape=shape
        query.exclude=[collision.get_parent().get_rid(),game.player.get_rid()]
        for step in range(13):
            var pose: Transform3D=door.get_parent().global_transform*Transform3D(Basis(Vector3.UP,state.angle*step/12.0),door.position)
            query.transform=Transform3D(pose.basis.orthonormalized(),pose*Vector3(.78,0,0))
            var hits=game.get_world_3d().direct_space_state.intersect_shape(query)
            if not hits.is_empty():
                push_error(str(door.name)+" sweep blocked at "+str(step)+" by "+str(hits[0].collider.get_meta("object_name",hits[0].collider.get_parent().name)))
                quit(1)
                return
        state.open=true
        for i in range(100): game._process(1.0/60)
        assert(absf(door.rotation.y-state.angle)<.002,"Door opens")
        state.open=false
        for i in range(100): game._process(1.0/60)
        assert(absf(door.rotation.y)<.002,"Door closes")
        assert(door.find_children("*","CollisionShape3D",true,false).size()>0,"Door has collision")
    assert(count==8,"Eight working doors; former extra suite is open living space")
    print("REFERENCE HOME: ",count," doors open and close with attached collision")
    # Player-width routes through the newly connected shared space, above the floor.
    var route_shape:=BoxShape3D.new()
    route_shape.size=Vector3(.7,1.6,.7)*1.3
    var route_query:=PhysicsShapeQueryParameters3D.new()
    route_query.shape=route_shape
    route_query.exclude=[game.player.get_rid()]
    var samples:=0
    for route in [[Vector3(1,.95,16),Vector3(5.3,.95,15.3)], [Vector3(5.3,.95,15.3),Vector3(5.3,.95,12.5)], [Vector3(5.3,.95,12.5),Vector3(6.8,.95,12.5)], [Vector3(6.8,.95,12.5),Vector3(6.8,.95,-1)], [Vector3(6.8,.95,4.25),Vector3(13.5,.95,4.25)], [Vector3(13.5,.95,4.25),Vector3(13.5,.95,11)], [Vector3(-3.35,.95,0),Vector3(-3.35,.95,10)]]:
        var steps:=ceili(route[0].distance_to(route[1])/.25)
        for step in range(steps+1):
            route_query.transform=Transform3D(Basis.IDENTITY,home.to_global(route[0].lerp(route[1],float(step)/steps)))
            var hits=game.get_world_3d().direct_space_state.intersect_shape(route_query)
            if not hits.is_empty():
                push_error("Shared-space route blocked by "+str(hits[0].collider.get_meta("object_name",hits[0].collider.get_parent().name)))
                quit(1)
                return
            samples+=1
    print("REFERENCE HOME: ",samples," shared-space clearance samples passed")
    game.player.global_position=home.to_global(Vector3(0,0,4))
    game._process(.3)
    assert(not home.get_node("Home roof").visible,"Roof lifts inside the home")
    game.player.global_position=home.to_global(Vector3(0,0,28))
    game._process(.3)
    assert(home.get_node("Home roof").visible,"Roof returns outside the home")
    var garage_drivers:=0
    var taxi_drivers:=0
    var taxi: Node3D=game.apartment.get_node("Vehicles/Taxi")
    for person in game.apartment.get_node("People").get_children():
        if not person.scene_file_path.ends_with("driver.tscn"): continue
        var p: Vector3=home.to_local(person.global_position)
        if p.x>6 and p.x<17 and p.z>14 and p.z<24: garage_drivers+=1
        if person.global_position.distance_to(taxi.global_position)<5: taxi_drivers+=1
    assert(garage_drivers==0 and taxi_drivers==1,"Garage drivers removed; one driver beside taxi")
    print("REFERENCE HOME: roof visibility and taxi driver placement passed")
    for entry in [[Vector3(11,0,1.5),"Dining room"], [Vector3(12,0,8),"Kitchen"], [Vector3(0,0,4),"Living room"], [Vector3(0,0,13),"Entry lounge"]]:
        game.player.global_position=home.to_global(entry[0])
        assert(game.current_room()==entry[1],"Room label follows revised interior")
    if "--capture" in OS.get_cmdline_user_args():
        game.player.visible=false
        var camera:=Camera3D.new()
        home.add_child(camera)
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=57
        camera.position=Vector3(2.5,45,13)
        camera.look_at(home.to_global(Vector3(2.5,0,4)))
        camera.current=true
        game.hud.ui_root.visible=false
        for i in range(15): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/town-checks/reference-home.png")
    game.free()
    quit()
