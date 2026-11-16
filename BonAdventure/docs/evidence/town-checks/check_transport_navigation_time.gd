extends SceneTree
# Real Godot 4 integration test for the travel, navigation and time learning hub.
# Run from project root: godot --headless --path . --script res://docs/evidence/town-checks/check_transport_navigation_time.gd
# This test does not write learning progress.

var failures: Array[String] = []
const KEYS: Array[String] = [
    "train", "station", "ticket", "left", "right", "straight ahead", "near", "far",
    "today", "tomorrow", "yesterday", "now", "later", "morning", "afternoon", "night"
]

func check(ok: bool, detail: String) -> void:
    if not ok:
        failures.append(detail)
        push_error(detail)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    root.size = Vector2i(1280, 720)
    var scene: PackedScene = load("res://scenes/main.tscn")
    check(scene != null, "The project's main scene must load")
    if scene == null:
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    # SpringArm3D updates its children even when player physics is disabled.
    game.camera.reparent(game)
    game.interaction.set_physics_process(false)
    # Avoid making test results change someone's progress file.
    game.interaction.word_studied.disconnect(game._on_word_studied)
    check(game.vocabulary.size() > 0, "Word dictionary loaded from words.json")
    check(game.vocabulary_categories.size() == game.vocabulary.size(), "All categories loaded")
    check(game.apartment.has_node("TravelLearningHub"), "Travel-learning hub instanced into main world")
    if not game.apartment.has_node("TravelLearningHub"):
        game.free()
        quit(1)
        return
    var hub: Node3D = game.apartment.get_node("TravelLearningHub")
    await physics_frame
    await physics_frame
    for key: String in KEYS:
        var name: String = ""
        for word_part in key.split(" "):
            name += word_part.capitalize()
        var target: Node3D = hub.get_node_or_null(name) as Node3D
        check(is_instance_valid(target), "Saved object exists: " + key)
        if not is_instance_valid(target):
            continue
        check(str(target.get_meta("word_key", "")) == key, "Object vocabulary key: " + key)
        check(bool(target.get_meta("learning_object", false)), "Object can be discovered: " + key)
        check(game.vocabulary.has(key) and not target.has_meta("spanish"), "Spanish from words.json, no cached copy: " + key)
        check(game.vocabulary_categories.has(key) and not target.has_meta("category"), "Category from words.json, no cached copy: " + key)
        var area: Area3D = target.get_node("Interaction") as Area3D
        var hitbox: CollisionShape3D = target.get_node("Interaction/Shape") as CollisionShape3D
        check(area.collision_layer == 2 and hitbox.shape is BoxShape3D, "Physics hitbox: " + key)
        var center: Vector3 = hitbox.global_position
        # Stand on the front/south side of the object at normal click range.
        var view_point: Vector3 = center + Vector3(0, 0, -2.0)
        game.player.global_position = view_point - Vector3(0, 1.1, 0)
        game.camera.global_position = view_point
        game.camera.look_at(center)
        game.interaction.pointer_position = root.get_visible_rect().size / 2.0
        await physics_frame
        await physics_frame
        var selected: Node3D = game.interaction.aimed_object()
        check(selected == target, "In-world ray picks exact vocabulary object: " + key)
        if selected != target:
            continue
        game.interaction.selected = null
        game.interaction.interact(false)
        check(game.hud.is_card_visible(), "Vocabulary popup opens: " + key)
        check(game.hud.current_spanish == game.vocabulary[key], "Popup Spanish is correct: " + key)
        check(game.hud.current_category == game.vocabulary_categories[key], "Popup category is correct: " + key)
        game.interaction.clear_card()
    # Keep the original already-interactive stop, and distinguish it from railway station.
    var stop: Node3D = game.apartment.get_node("Bus stop sign") as Node3D
    check(stop.get_meta("word_key") == "bus stop", "Existing bus stop remains discoverable")
    check(game.vocabulary["bus stop"] == "la parada de autobús", "Existing stop translation unchanged")
    check(game.vocabulary["station"] == "la estación de tren", "Railway vs bus-stop concepts remain different")
    print("TRANSPORT, NAVIGATION & TIME RUNTIME TEST: ", KEYS.size(), " new click targets; ", failures.size(), " failures")
    game.free()
    quit(0 if failures.is_empty() else 1)
