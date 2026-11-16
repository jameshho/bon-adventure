extends SceneTree
func _initialize(): run.call_deferred()
func run():
    root.size = Vector2i(1280,800)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.hide()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await physics_frame
    var zoo = game.apartment.get_node("ParkZoo")
    assert(zoo.scene_file_path == "res://scenes/world/park_zoo.tscn")
    var animal_paths := {}
    var count := 0
    for node in zoo.get_children():
        if node.scene_file_path.begins_with("res://scenes/animals/"):
            count += 1
            assert(node.scene_file_path.begins_with("res://scenes/animals/"))
            assert(not animal_paths.has(node.scene_file_path))
            animal_paths[node.scene_file_path] = true
            var standalone = load(node.scene_file_path).instantiate()
            assert(standalone.position == Vector3.ZERO)
            assert(standalone.get_meta("word_key") == node.get_meta("word_key"))
            assert(node.radius > 0 and node.speed > 0)
            for child in standalone.get_children():
                if child is MeshInstance3D:
                    assert(child.mesh != null and child.mesh.get_surface_count() > 0)
            standalone.free()
            assert(game.vocabulary.has(node.get_meta("word_key")))
            var area = node.get_node("VocabularyArea")
            assert(area is Area3D)
            var target = area.get_child(0).global_position
            var ray := PhysicsRayQueryParameters3D.create(target+Vector3(0,5,0),target)
            ray.collide_with_areas = true
            ray.collide_with_bodies = false
            var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
            assert(not hit.is_empty() and hit.collider == area, "Animal must be pickable: "+str(node.name))
            var home: Vector3 = node.home
            for i in range(120):
                node._process(.5)
                assert(node.position.distance_to(home) <= node.radius+.01)
            node.position = home
    assert(count == 19) # the bird was removed, 8 Nov 2026
    for building in ["Hospital","School","ClothingStore"]:
        assert(game.apartment.get_node("Buildings/"+building).has_node("InteriorDetails"))
    print("PASS: 19 independent animal scenes, editable meshes, zoo scene, physics picking, bounded movement, vocabulary and 3 interiors")
    if "--capture" in OS.get_cmdline_user_args():
        var cam := Camera3D.new()
        game.apartment.add_child(cam)
        cam.current = true
        cam.fov = 80
        var views = [
            ["zoo",Vector3(-19,17,48),Vector3(-33,0,68)],
            ["hospital",Vector3(-34.5,2.5,106),Vector3(-39,1.8,110)],
            ["school",Vector3(-6.5,2.5,106),Vector3(-11,1.5,111)],
            ["clothing",Vector3(50.5,2.5,107),Vector3(50.5,1.8,119)]]
        DirAccess.make_dir_recursive_absolute("res://docs/evidence/zoo-review")
        for view in views:
            cam.position = view[1]
            cam.look_at(game.apartment.to_global(view[2]))
            for i in range(8): await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://docs/evidence/zoo-review/"+view[0]+".png")
    game.free()
    quit()
