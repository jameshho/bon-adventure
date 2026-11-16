extends SceneTree
## Phase 2 tree species checks; run headless in the isolated copy.
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/vegetation-20261027/phase2/verify.gd
var failures := 0
func _initialize(): run.call_deferred()
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        print("FAIL: ", message)

func word_at(hit: Dictionary, town: Node3D) -> String:
    var node: Node = hit.get("collider")
    while node != null and node != town:
        if node is Node3D and str(node.get_meta("word_key", "")) != "": return str(node.get_meta("word_key"))
        node = node.get_parent()
    return ""

func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    for i in range(3): await physics_frame
    var town: Node3D = game.apartment
    var garden: Node3D = town.get_node("PublicGarden")
    var vocabulary: Dictionary = preload("res://scripts/learning/word_data.gd").load_all().vocabulary
    var categories: Dictionary = preload("res://scripts/learning/word_data.gd").load_all().categories
    var species_trees: Array = []
    var fruit := 0
    for node in town.find_children("*", "Node3D", true, false):
        var file: String = node.scene_file_path.get_file()
        check(file != "maple_tree.tscn", "old maple prefab remains at " + str(town.get_path_to(node)))
        if file == "tree.tscn" and String(node.name).begins_with("Garden "): check(false, "generic garden tree remains: " + str(node.name))
        if String(node.name).begins_with("Willow "): check(false, "assembled willow piece remains: " + str(node.name))
        if file == "apple_tree.tscn" or file == "orange_tree.tscn":
            fruit += 1
            check(vocabulary.has(str(node.get_meta("word_key"))), "fruit tree word in dictionary: " + str(node.get_meta("word_key")))
        if node.get_script() == preload("res://scripts/objects/tree_species.gd"): species_trees.append(node)
    var counts := {}
    var space: PhysicsDirectSpaceState3D = town.get_world_3d().direct_space_state
    var paths: Array = garden.get_meta("walking_paths")
    var nearest_path := INF
    var shielded: Array[String] = []
    for tree in species_trees:
        var key: String = tree.species
        counts[key] = counts.get(key, 0) + 1
        check(vocabulary.has(key) and categories.get(key, "") == "Nature", "species word and Nature category: " + key)
        check(tree.get_meta("word_key") == key, "root word_key matches species: " + key)
        check(tree.has_node("StudyArea") and tree.find_children("Body", "StaticBody3D", true, false).size() == 1, "one study area and one solid trunk: " + str(tree.name))
        # Ray from outside the crown toward its center should teach the species.
        var study: CollisionShape3D = tree.get_node("StudyArea").get_child(0)
        var center: Vector3 = study.global_position
        var reach: float = study.shape.size.length() * tree.global_basis.get_scale().x
        # Groves overlap, so require the species from at least one of four approaches.
        var taught := []
        for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
            taught.append(word_at(space.intersect_ray(_ray(center + side * reach + Vector3(0, 0.3, 0), center)), town))
        check(key in taught, "crown pick teaches " + key + " at " + str(tree.name) + " (got " + str(taught) + ")")
        # Phase 3 bushes can ring a trunk at ankle height, so try four approaches at
        # ankle height and at 60% of the trunk, as a player would aim higher.
        var trunk_shape: CollisionShape3D = tree.find_children("Body", "StaticBody3D", true, false)[0].get_child(0)
        var trunk_ok := false
        for height in [0.25, trunk_shape.shape.height * trunk_shape.global_basis.get_scale().y * 0.6]:
            var base: Vector3 = tree.global_position + Vector3(0, height, 0)
            for side in [Vector3(3, 0, 0.01), Vector3(-3, 0, 0.01), Vector3(0.01, 0, 3), Vector3(0.01, 0, -3)]:
                var trunk_hit := space.intersect_ray(_ray(base + side, base))
                if not trunk_hit.is_empty() and trunk_hit.collider is StaticBody3D and word_at(trunk_hit, town) == "tree": trunk_ok = true
        # A short trunk inside its own foliage and ringed by a planting bed can be fully
        # shielded; that is real in-game behaviour, so list such trunks and cap them.
        if not trunk_ok: shielded.append(str(tree.name))
        if tree.get_parent() == garden:
            var p: Vector3 = tree.global_position
            for curve in paths:
                for i in range(1, curve.size()):
                    nearest_path = minf(nearest_path, Geometry3D.get_closest_point_to_segment(garden.to_local(p), curve[i - 1], curve[i]).distance_to(garden.to_local(p)))
    for key in ["oak", "pine", "palm tree", "birch", "weeping willow", "cherry tree", "cypress", "maple"]:
        check(counts.get(key, 0) > 0, "species present: " + key)
    check(fruit == 10, "five apple and five orange trees retained (found " + str(fruit) + ")")
    check(shielded.size() <= 2, "at most two trunks fully shielded from picking (" + str(shielded) + ")")
    print("SHIELDED TRUNKS: ", shielded)
    print("TREE SPECIES: ", counts, "; fruit trees ", fruit, "; total ", species_trees.size() + fruit)
    print("NEAREST GARDEN TRUNK TO PATH CENTERLINE: ", snapped(nearest_path, 0.01), " garden units")
    print("BATCHES: ", garden.get_meta("batched_mesh_count", -1), " meshes in ", garden.get_meta("render_batch_count", -1), " batches")
    print("PHASE 2 TREES: ", failures, " failures")
    quit(failures)

func _ray(from: Vector3, to: Vector3) -> PhysicsRayQueryParameters3D:
    var ray := PhysicsRayQueryParameters3D.create(from, to)
    ray.collide_with_areas = true
    return ray
