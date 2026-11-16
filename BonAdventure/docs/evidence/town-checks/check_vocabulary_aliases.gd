extends SceneTree

# Godot 4: godot --headless --path <project> --script res://docs/evidence/town-checks/check_vocabulary_aliases.gd
# No user:// save files are read or written by this test.
const VocabularyProgress = preload("res://scripts/learning/vocabulary_progress.gd")
const InteractionController = preload("res://scripts/player/interaction_controller.gd")

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    var words: Dictionary = preload("res://scripts/learning/word_data.gd").load_all()
    var vocabulary: Variant = words.vocabulary
    var aliases: Variant = words.aliases
    var categories: Variant = words.categories
    var catalog: Variant = words.catalog
    check(vocabulary is Dictionary and aliases is Dictionary, "Vocabulary and aliases parse as dictionaries")
    if not (vocabulary is Dictionary and aliases is Dictionary):
        quit(1)
        return
    check(vocabulary.size() > 0 and aliases.size() > 0, "Words and aliases load from words.json")
    check(categories is Dictionary and catalog is Dictionary, "Categories and learning catalog parse")
    for old_key in aliases.keys():
        var canonical: String = str(aliases[old_key])
        check(not vocabulary.has(old_key) and vocabulary.has(canonical), "Alias maps to canonical word: " + str(old_key))
    var studied: Dictionary = VocabularyProgress.normalize_studied_words(
        ["tap", "faucet", "bedside table", "nightstand", "chest of drawers", "dresser", "nonexistent"], vocabulary, aliases)
    check(studied.size() == 3 and studied.has("faucet") and studied.has("nightstand") and studied.has("dresser"),
        "Older progress migrates without double-counting, invalid words excluded")
    var fixture := Node3D.new()
    fixture.set_meta("word_key", "tap")
    var controller := InteractionController.new()
    controller.vocabulary_aliases = aliases
    check(controller.word_key(fixture) == "faucet", "Legacy scene interaction resolves canonical vocabulary")
    controller.free()
    fixture.free()
    for path in ["res://scenes/props/vocabulary/dresser.tscn", "res://scenes/props/vocabulary/coffee_maker.tscn"]:
        var scene: PackedScene = load(path) as PackedScene
        check(scene != null, "Reusable vocabulary prefab loads: " + path)
        if scene != null:
            var obj: Node = scene.instantiate()
            check(vocabulary.has(str(obj.get_meta("word_key", ""))), "Prefab uses a primary vocabulary key: " + path)
            obj.free()
    if failures.is_empty():
        print("PASS: vocabulary alias loading, migration, interaction resolution and prefab loading")
    quit(0 if failures.is_empty() else 1)
