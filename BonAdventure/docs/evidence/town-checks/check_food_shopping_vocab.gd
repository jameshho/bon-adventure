extends SceneTree
# Run in Godot 4: godot --headless --path . --script res://docs/evidence/town-checks/check_food_shopping_vocab.gd
# (or python3 tools/run_checks.py --only food_shopping_vocab, which isolates HOME).
# The food and shopping words of FOOD_SHOPPING_VOCAB_ADDITIONS.json in the modular town
# (rewritten 18 Nov 2026): each word comes from data/words.json with no copy cached on the
# object, an object teaching it is placed in some building scene (data/buildings.json), a centre
# ray from a nearby camera picks it through the real interaction controller, and a click opens
# the vocabulary card with the translation. Found anywhere in the town, not in fixed stores:
# the old Buildings/BakeryCafe and Buildings/MarketDisplays paths predate 6 Nov 2026.
const WORDS := ["coffee", "breakfast", "lunch", "dinner", "menu", "bill", "food",
    "chicken", "meat", "salad", "price", "money", "credit card"]
## How many placed copies of a word to try before reporting it as not pickable.
const MAX_COPIES := 8
const WATCHDOG_SECONDS := 420.0

var failures: Array[String] = []
var checks := 0
var finished := false

func check(ok: bool, detail: String) -> void:
    checks += 1
    if not ok:
        failures.append(detail)
        push_error(detail)

func _initialize() -> void:
    # Always quit, also when a SCRIPT ERROR ends the coroutine below.
    create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
        if finished:
            return
        failures.append("watchdog: the check did not finish in %d s" % int(WATCHDOG_SECONDS))
        push_error(failures[-1])
        finish())
    run.call_deferred()

func finish() -> void:
    finished = true
    print("FOOD & SHOPPING GODOT RUNTIME CHECK: ", WORDS.size(), " requested words; ", checks, " checks; ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)

## Word roots in the town per key (lower case), in tree order.
func placed_words(town: Node) -> Dictionary:
    var found := {}
    for node in town.find_children("*", "Node3D", true, false):
        var key := str(node.get_meta("word_key", "")).to_lower()
        if key in WORDS:
            if not found.has(key):
                found[key] = []
            found[key].append(node)
    return found

## Collision objects under `word` that the controller resolves to it.
func pick_bodies(game, word: Node3D) -> Array:
    var result := []
    for body in word.find_children("*", "CollisionObject3D", true, false):
        if game.interaction.vocabulary_target(body, game.apartment) == word:
            result.append(body)
    return result

## Aims the camera at `word` from a few sides; true when the centre ray picks it.
func aim_at(game, word: Node3D) -> bool:
    for body in pick_bodies(game, word):
        var center: Vector3 = (body as Node3D).global_position
        for shape in body.find_children("*", "CollisionShape3D", false, false):
            center = (shape as Node3D).global_position
            break
        for height in [0.35, 0.0, 0.9]:
            for side in 8:
                var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * side / 8.0)
                var eye: Vector3 = center + dir * 1.4 + Vector3.UP * height
                game.player.global_position = eye - Vector3(0, 1.1, 0)
                game.camera.global_position = eye
                game.camera.look_at(center)
                await physics_frame
                if game.interaction.aimed_object() == word:
                    return true
    return false

func run() -> void:
    root.size = Vector2i(1280, 720)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    # The data, not a literal: Main's dictionaries hold every word of data/words.json.
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))
    var word_count: int = data.get("words", {}).size()
    check(word_count > 0 and game.vocabulary.size() == word_count, "Dictionary loads all words (%d of %d)" % [game.vocabulary.size(), word_count])
    check(game.vocabulary_categories.size() == word_count, "Category table loads (%d of %d)" % [game.vocabulary_categories.size(), word_count])
    if game.interaction.word_studied.is_connected(game._on_word_studied):
        game.interaction.word_studied.disconnect(game._on_word_studied)
    game.player.set_physics_process(false)
    # Keep the live spring arm from moving the deliberately positioned test camera.
    game.camera.reparent(game)
    game.interaction.set_physics_process(false)
    game.interaction.pointer_position = root.get_visible_rect().size / 2
    await physics_frame
    await physics_frame
    var placed := placed_words(game.apartment)
    var not_placed: Array[String] = []
    for key in WORDS:
        check(game.vocabulary.has(key), "Dictionary lookup: " + key)
        check(game.vocabulary_categories.has(key), "Category from words.json: " + key)
        if not placed.has(key):
            not_placed.append(key)
            continue
        var copies: Array = placed[key]
        for node in copies:
            check(not node.has_meta("category") and not node.has_meta("spanish"), "No cached category/translation: " + str(game.apartment.get_path_to(node)))
        var picked: Node3D = null
        for node in copies.slice(0, MAX_COPIES):
            if await aim_at(game, node):
                picked = node
                break
        check(picked != null, "Clickable ray target: " + key + " (" + str(copies.size()) + " placed)")
        if picked == null:
            continue
        print("  ", key, ": ", copies.size(), " placed; picked ", game.apartment.get_path_to(picked))
        game.interaction.clear_card()
        game.interaction.click()
        check(game.hud.is_card_visible() and game.interaction.selected == picked, "Vocabulary popup: " + key)
        check(str(game.hud.current_spanish).ends_with(str(game.vocabulary[key])), "Popup translation: " + key + " -> " + str(game.hud.current_spanish))
        game.interaction.clear_card()
    if not not_placed.is_empty():
        print("  not placed in the town (skipped): ", ", ".join(not_placed))
    game.free()
    finish()
