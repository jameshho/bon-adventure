extends SceneTree
var failures:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String):
    if not ok:
        failures+=1
        print("FAIL: ",label)
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    var garden: Node3D=town.get_node("PublicGarden")
    # Heights come from the saved ground mesh (docs/evidence/town-checks/park_ground.gd); the analytic grading of the
    # deleted park_terrain.gd pass gave exact zeros, so level checks allow mesh rounding.
    var terrain=load("res://docs/evidence/town-checks/park_ground.gd").new(town)
    var lagoon: PackedVector2Array=garden.get_meta("lagoon_polygon")
    var ground: MeshInstance3D=garden.get_node("Rolling park ground")
    check(ground.get_meta("terrain_triangles")<26000,"bounded static terrain triangle count")
    var normals: PackedVector3Array=ground.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
    for n in normals: check(n.y>0.9,"gentle upward-facing ground")
    for p in [Vector3(103,0,139),Vector3(-112,0,139),Vector3(0,0,65),Vector3(0,0,200),Vector3(53,0,139),Vector3(2,0,139),Vector3(-42,0,139),Vector3(65,0,90),Vector3(-80,0,105)]:
        check(terrain.height_at(p)<.001,"level road, landmark or occupied pad "+str(p))
    # Natural lawn relief remains, without the former raised basin rim.
    for p in [Vector3(20,0,155),Vector3(-62,0,150),Vector3(20,0,165)]:
        check(terrain.height_at(p)>.05 and terrain.height_at(p)<1.8,"subtle lawn relief "+str(p))
    var peak:=0.0
    var monument_peak:=0.0
    for z in range(76,191,2):
        for x in range(-94,95,2):
            var p:=Vector3(x,0,z)
            var h: float=terrain.height_at(p)
            peak=maxf(peak,h)
            check(h>=0 and h<1.8,"low park grade "+str(p))
            check(absf(h-terrain.height_at(p+Vector3.RIGHT))<.22 and absf(h-terrain.height_at(p+Vector3.BACK))<.22,"smooth lawn grade "+str(p))
            if Vector2((x-53.0)/31.0,(z-139.0)/27.0).length()<=1.0:
                monument_peak=maxf(monument_peak,h)
                check(h<1.5,"restrained monument lawn "+str(p))
    check(peak>.6 and monument_peak>.4,"lawns retain visible gentle variation")
    for p in [Vector3(29,0,155),Vector3(65,0,155)]:
        check(terrain.height_at(p)>.35,"pronounced northern lawn "+str(p))
    for center in [Vector3(77,0,125),Vector3(77,0,153)]:
        for offset in [Vector3.ZERO,Vector3(4,0,0),Vector3(0,0,4),Vector3(-4,0,0),Vector3(0,0,-4)]:
            check(terrain.height_at(center+offset)<.001,"level fountain apron "+str(center+offset))
    for p in lagoon:
        check(terrain.height_at(Vector3(p.x,0,p.y))<.001,"unchanged waterline")
    await physics_frame
    await physics_frame
    # Physics checks at actual elevated locations; old flat ground cannot satisfy them.
    var samples:=0
    for z in range(80,187,3):
        for x in range(-90,91,3):
            var p:=Vector3(x,0,z)
            var h: float=terrain.height_at(p)
            if h<.15: continue
            var ray:=PhysicsRayQueryParameters3D.create(town.to_global(p+Vector3(0,h+.3,0)),town.to_global(p+Vector3(0,h-.1,0)))
            var hit:=town.get_world_3d().direct_space_state.intersect_ray(ray)
            check(not hit.is_empty(),"elevated ground collision "+str(p))
            samples+=1
    # Use the actual player collider and its configured snap length, without jumping.
    var player: CharacterBody3D=game.player
    var airborne:=0
    for route in [[Vector3(22,0,98),Vector3(22,0,133)],[Vector3(20,0,148),Vector3(20,0,182)],[Vector3(-58,0,132),Vector3(-58,0,161)]]:
        for reverse in [false,true]:
            var start: Vector3=route[1] if reverse else route[0]
            var end: Vector3=route[0] if reverse else route[1]
            start.y=terrain.height_at(start)+.15
            player.global_position=town.to_global(start)
            player.velocity=Vector3.ZERO
            for settle in range(45):
                await physics_frame
                player.velocity.y-=22.0/60.0
                player.move_and_slide()
            var direction: Vector3=(end-start)*Vector3(1,0,1)
            direction=direction.normalized()
            var reached:=false
            for frame in range(650):
                await physics_frame
                player.velocity.x=direction.x*6
                player.velocity.z=direction.z*6
                player.velocity.y-=22.0/60.0
                player.move_and_slide()
                if not player.is_on_floor(): airborne+=1
                var pos:=town.to_local(player.global_position)
                if Vector2(pos.x-end.x,pos.z-end.z).length()<.25:
                    reached=true
                    break
            check(reached,"player slope crossing "+str(start)+" -> "+str(end))
    check(airborne<6,"slope floor contact; airborne frames="+str(airborne))
    print("PARK TERRAIN: ",failures," failures; ",samples," elevated collision samples; 6 actual-player slope traversals; triangles=",ground.get_meta("terrain_triangles"),"; peak=",peak,"; monument peak=",monument_peak)
    quit(0 if failures==0 else 1)
