extends SceneTree
# Run in Godot 4: godot --headless --path . --script res://docs/evidence/town-checks/check_food_shopping_vocab.gd
# Uses real project startup, PhysicsRayQueryParameters3D picking, and vocabulary HUD.
var failures: Array[String] = []

func check(ok: bool, detail: String) -> void:
    if not ok:
        failures.append(detail)
        push_error(detail)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    root.size = Vector2i(1280, 720)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    check(game.vocabulary.size() == 500, "Dictionary loads all words")
    check(game.vocabulary_categories.size() == 500, "Category table loads")
    game.interaction.word_studied.disconnect(game._on_word_studied)
    game.player.set_physics_process(false)
    # Keep the live spring arm from moving our deliberately positioned test camera.
    game.camera.reparent(game)
    game.interaction.set_physics_process(false)
    var stores: Dictionary = {
        "BakeryCafe": ["coffee", "breakfast", "lunch", "dinner", "menu", "bill", "food"],
        "MarketDisplays": ["chicken", "meat", "salad", "price", "money", "credit card"]
    }
    await physics_frame
    await physics_frame
    for place in stores:
        var store: Node3D = game.apartment.get_node("Buildings/" + place)
        check(is_instance_valid(store), place + " loaded")
        for key in stores[place]:
            var found: Node3D = null
            for child in store.get_children():
                if str(child.get_meta("word_key", "")) == key:
                    found = child
                    break
            check(is_instance_valid(found), place + ": visible asset for " + key)
            if not is_instance_valid(found):
                continue
            check(found.get_meta("learning_object",false), "Discoverable: " + key)
            check(game.vocabulary.has(key), "Dictionary lookup: " + key)
            check(game.vocabulary_categories.has(key) and not found.has_meta("category"), "Category from words.json, no cached copy: " + key)
            check(game.vocabulary.has(key) and not found.has_meta("spanish"), "Spanish from words.json, no cached copy: " + key)
            var hitbox: CollisionShape3D = found.get_node("Interaction/Shape")
            var center: Vector3 = hitbox.global_position
            var aisle: Vector3 = store.to_global(Vector3(signf(found.position.x)*1.5, found.position.y + 0.45, found.position.z - 0.7))
            game.player.global_position = aisle - Vector3(0,1.1,0)
            game.camera.global_position = aisle
            game.camera.look_at(center)
            game.interaction.pointer_position = root.get_visible_rect().size / 2
            await physics_frame
            check(game.interaction.aimed_object() == found, "Clickable ray target: " + key)
            if game.interaction.aimed_object() == found:
                game.interaction.selected = null
                game.interaction.interact(false)
                check(game.hud.is_card_visible(), "Vocabulary popup: " + key)
                check(game.hud.current_spanish == game.vocabulary[key], "Popup translation: " + key)
    print("FOOD & SHOPPING GODOT RUNTIME CHECK: ", 13, " requested words; ", failures.size(), " failures")
    game.free()
    quit(0 if failures.is_empty() else 1)
