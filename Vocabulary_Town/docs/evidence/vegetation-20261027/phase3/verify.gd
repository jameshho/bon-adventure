extends SceneTree
## Phase 3 bush checks; run headless in the isolated copy.
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/vegetation-20261027/phase3/verify.gd
const BUSH := preload("res://scripts/objects/bush_species.gd")
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
    var space: PhysicsDirectSpaceState3D = town.get_world_3d().direct_space_state
    var counts := {}
    var pickable := 0
    for node in town.find_children("*", "Node3D", true, false):
        var title := String(node.name)
        if title.begins_with("Garden clipped border") or title.begins_with("Trimmed hedge"):
            check(node.get_script() == BUSH, "old clump replaced: " + str(town.get_path_to(node)))
        if node.get_script() != BUSH: continue
        var key: String = node.species
        counts[key] = counts.get(key, 0) + 1
        check(vocabulary.has(key), "bush word in dictionary: " + key)
        check(node.find_children("*", "StaticBody3D", true, false).is_empty(), "no movement collision: " + str(node.name))
        var facade: bool = str(town.get_path_to(node)).begins_with("Map facades")
        check(node.has_node("StudyArea") != facade, "study area only outside facades: " + str(town.get_path_to(node)))
        if title.begins_with("Trimmed hedge"):
            check(vocabulary.has("hedge") and not node.has_meta("spanish"), "hedge word from words.json, no cached tag")
        if node.has_node("StudyArea"):
            # Beds are dense and vehicles park nearby, so accept any of five approaches.
            var center: Vector3 = node.get_node("StudyArea").get_child(0).global_position
            var taught := []
            for from in [Vector3(0, 6, 0), Vector3(3, 1.5, 0), Vector3(-3, 1.5, 0), Vector3(0, 1.5, 3), Vector3(0, 1.5, -3)]:
                taught.append(word_at(space.intersect_ray(_ray(center + from, center)), town))
            check(key in taught, "pick teaches " + key + " at " + str(town.get_path_to(node)) + " (got " + str(taught) + ")")
            pickable += 1
    var planting: Node3D = garden.get_node("Town planting")
    for node in planting.get_children():
        if node is MeshInstance3D and node.material_override is StandardMaterial3D and node.material_override.albedo_color.to_html(false) == "63894f":
            check(false, "old low garden shrub remains")
    var holder: Node3D = garden.get_node("Garden bush groups")
    var added: int = holder.get_meta("added_bushes")
    check(added > 0 and added <= 24, "additions within the 24-clump cap (" + str(added) + ")")
    var walks: Array = garden.get_meta("walking_paths")
    var lagoon: PackedVector2Array = garden.get_meta("lagoon_polygon")
    for bush in holder.get_children():
        var p: Vector3 = garden.to_local(bush.global_position)
        check(not Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), lagoon), "addition outside lagoon: " + str(bush.name))
        for curve in walks:
            for i in range(1, curve.size()):
                var d := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(curve[i - 1].x, curve[i - 1].z), Vector2(curve[i].x, curve[i].z)).distance_to(Vector2(p.x, p.z))
                check(d >= 3.0, "addition clear of walk centerline: " + str(bush.name))
    # Foundation planting shares the plan's 24-clump cap and must keep entrances open.
    var foundations: Array = town.get_node("Foundation planting").get_children()
    check(foundations.size() > 0 and added + foundations.size() <= 24, "garden + foundation additions within cap (" + str(added) + " + " + str(foundations.size()) + ")")
    var hedges: Array = town.find_children("Trimmed hedge*", "Node3D", true, false)
    for bush in foundations:
        for hedge in hedges:
            check(bush.global_position.distance_to(hedge.global_position) / town.global_basis.get_scale().x >= 2.0, "foundation bush clear of entrance hedge: " + str(bush.name))
    for key in ["shrub", "hedge", "rose bush", "fern"]:
        check(counts.get(key, 0) > 0, "bush type present: " + key)
    for file in ["shrub", "hedge", "rose_bush", "fern"]:
        var sample: Node3D = load("res://scenes/props/nature/species/" + file + ".tscn").instantiate()
        root.add_child(sample)
        print("NOMINAL ", sample.species, " ", sample.get_meta("nominal_size"))
        sample.free()
    print("BUSH SPECIES: ", counts, "; pickable ", pickable, "; added ", added)
    print("BATCHES: ", garden.get_meta("batched_mesh_count", -1), " meshes in ", garden.get_meta("render_batch_count", -1), " batches")
    print("PHASE 3 BUSHES: ", failures, " failures")
    quit(failures)

func _ray(from: Vector3, to: Vector3) -> PhysicsRayQueryParameters3D:
    var ray := PhysicsRayQueryParameters3D.create(from, to)
    ray.collide_with_areas = true
    return ray
