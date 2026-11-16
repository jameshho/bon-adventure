extends SceneTree
func _initialize(): call_deferred("run")
func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    await physics_frame
    await physics_frame
    var failed = 0
    var samples = 0
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.25*1.3
    capsule.height = 1.7*1.3
    var q = PhysicsShapeQueryParameters3D.new()
    q.shape = capsule
    q.collide_with_areas = false
    for node in game.apartment.get_children():
        if not str(node.name).begins_with("Winding park path"): continue
        var v = node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        for i in range(0,v.size(),12):
            var p = (v[i]+v[i+1])*0.5
            var feet = 0.27 if p.x >= 4.5 and p.x <= 29.8 and abs(p.z-68) < 1.2 else 0.0
            q.transform = Transform3D(Basis.IDENTITY,game.apartment.to_global(Vector3(p.x,1.0+feet,p.z)))
            var hit = game.get_world_3d().direct_space_state.intersect_shape(q,4)
            samples += 1
            if not hit.is_empty():
                failed += 1
                print("PATH BLOCKED ",p," by ",hit[0].collider.get_path())
    for pos in [Vector3(4.5,2,-16),Vector3(0,2,60),Vector3(-50,2,65),Vector3(60,2,65),Vector3(-32,2,103),Vector3(-4,2,103),Vector3(26,2,103),Vector3(50,2,130),Vector3(77,2,73)]:
        var ray=PhysicsRayQueryParameters3D.create(game.apartment.to_global(pos),game.apartment.to_global(pos-Vector3(0,5,0)))
        if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
            failed += 1
            print("GROUND MISSING ",pos)
    for name in ["Hospital","School","ClothingStore"]:
        if game.apartment.get_node("Buildings/"+name).position.z < 100:
            failed += 1
    var words=game.vocabulary
    var unknown={}
    for n in game.apartment.get_children():
        if n.has_meta("word_key") and not words.has(n.get_meta("word_key")):
            unknown[n.get_meta("word_key")]=true
    print("Unknown vocabulary: ",unknown.keys())
    failed += unknown.size()
    print("TOWN CHECK: ",failed," failures, ",samples," park path samples")
    quit(1 if failed else 0)
