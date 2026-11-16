extends SceneTree

# Run with Godot --headless --path <project> --script res://docs/evidence/town-checks/check_house.gd
var failures: Array[String] = []
var game

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("FAIL: ", message)

func _initialize() -> void:
    call_deferred("validate")

func validate() -> void:
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_physics_process(false)
    game.player.set_physics_process(false)
    game.player.set_process(false)
    var apartment: Node3D = game.apartment
    var house := apartment.get_node("Buildings/HouseStructure")
    for wall in ["BedroomWestWall", "BedroomEastWall", "GreatRoomWestWall", "GreatRoomEastWall", "BedroomDivider", "BedroomDivider_2"]:
        var visual: MeshInstance3D = house.get_node(wall + "/Visual")
        var collision: CollisionShape3D = house.get_node(wall + "/Body/Collision")
        check(visual.mesh.size.is_equal_approx(collision.shape.size), wall + " visual matches collision")
        check(visual.position.is_zero_approx(), wall + " has no stray visual offset")
    check(apartment.get_node("TV display").position.z > apartment.get_node("Television").position.z, "TV faces the sofa")
    check(apartment.get_node("Bathroom mirror").position.x > 2.7, "Vanity mirror is on the east wall")
    check(house.to_local(apartment.get_node("Padded headboard accent").global_position).z < -8.0, "Headboard accent follows the bed")
    check(not apartment.has_node("Poster"), "Unnecessary study poster removed")
    var doors := 0
    for node in game.doors:
        var state: Dictionary = game.doors[node]
        if state.type == "slide":
            check(node.position.is_equal_approx(state.origin), "Drawer slide origin follows the worktop")
        elif str(node.name).contains("door"):
            doors += 1
            node.rotation.y = state.angle
    check(doors == 4, "All four house doors are present")
    # Detect missing vocabulary metadata across generated house furnishings.
    for node in apartment.get_children():
        if node is Node3D and abs(node.position.x) < 12 and node.position.z > -9 and node.position.z < 12:
            var key: String = node.get_meta("word_key", "")
            if not key.is_empty():
                check(game.vocabulary.has(key), "Vocabulary exists: " + key)
    await physics_frame
    await physics_frame
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.25 * game.APARTMENT_SCALE
    capsule.height = 1.75 * game.APARTMENT_SCALE
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = capsule
    query.exclude = [game.player.get_rid()]
    query.collide_with_areas = false
    var routes = [
        ["entry", Vector3(4.5, 0, 12), Vector3(4.5, 0, 2.3)],
        ["hall", Vector3(-6.325, 0, 2.3), Vector3(5.425, 0, 2.3)],
        ["primary doorway", Vector3(-6.325, 0, 2.3), Vector3(-6.325, 0, -2.5)],
        ["bathroom doorway", Vector3(0, 0, 2.3), Vector3(0, 0, -5.4)],
        ["study doorway", Vector3(5.425, 0, 2.3), Vector3(5.425, 0, -3)],
        ["kitchen", Vector3(-4.8, 0, 3), Vector3(-8.0, 0, 5.4)],
        ["living", Vector3(4.5, 0, 4.4), Vector3(8, 0, 4.4)]
    ]
    for route in routes:
        for step in range(31):
            var point: Vector3 = route[1].lerp(route[2], float(step) / 30.0)
            query.transform = Transform3D(Basis.IDENTITY, house.to_global(point + Vector3(0, 0.91, 0)))
            var hits := apartment.get_world_3d().direct_space_state.intersect_shape(query)
            if not hits.is_empty():
                check(false, "%s blocked at %s by %s" % [route[0], point, hits[0].collider.get_parent().name])
                break
    print("House checks: ", failures.size(), " failures; 7 walking routes, 4 doors, drawer origins, wall geometry, vocabulary and fixture placements checked.")
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
