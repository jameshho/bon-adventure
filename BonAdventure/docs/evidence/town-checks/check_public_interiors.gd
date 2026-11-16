extends SceneTree
func _initialize():
    call_deferred("run")
func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    await physics_frame
    await physics_frame
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.28 * 1.3
    capsule.height = 1.75 * 1.3
    var query = PhysicsShapeQueryParameters3D.new()
    query.shape = capsule
    query.collide_with_areas = false
    var routes = [
        [Vector2(-33,36.5),Vector2(-33,50)],
        [Vector2(-36.6,42),Vector2(-36.6,50)],
        [Vector2(-29.2,42),Vector2(-29.2,50)],
        [Vector2(-38,51.6),Vector2(-27.5,51.6)],
        [Vector2(-15,36.5),Vector2(-15,49.9)],
        [Vector2(-19,47),Vector2(-11,47)],
        [Vector2(-16.5,42),Vector2(-16.5,49.8)],
        [Vector2(-13.5,42),Vector2(-13.5,49.8)]
    ]
    var failures = 0
    for route in routes:
        for i in range(41):
            var p = route[0].lerp(route[1],float(i)/40)
            query.transform = Transform3D(Basis.IDENTITY,game.apartment.to_global(Vector3(p.x,0.98,p.y)))
            var hits = game.get_world_3d().direct_space_state.intersect_shape(query,8)
            if not hits.is_empty():
                print("Blocked route ",route," at ",p," ",hits[0].collider.get_path())
                failures += 1
                break
    var words = preload("res://scripts/learning/word_data.gd").load_all().vocabulary
    for node in game.apartment.get_children():
        if not node is Node3D: continue
        var pos = node.position
        if pos.z > 37.5 and pos.z < 52.5 and pos.x > -40 and pos.x < -9:
            if node.has_meta("word_key") and not words.has(str(node.get_meta("word_key"))):
                print("Missing word ",node.get_meta("word_key"))
                failures += 1
    print("INTERIOR ROUTES: ",failures," failures, ",routes.size()," paths checked")
    quit(1 if failures else 0)
