extends SceneTree

# Headless read-only category and progress-invariance check.
# godot --headless --path . --script res://docs/evidence/town-checks/check_vocabulary_categories.gd
const VocabularyProgress = preload("res://scripts/learning/vocabulary_progress.gd")
var failures: Array[String] = []

func expect(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    # data/words.json is the only word source; counts are derived, not hard-coded.
    var words: Dictionary = preload("res://scripts/learning/word_data.gd").load_all()
    var vocabulary: Variant = words.vocabulary
    var categories: Variant = words.categories
    var aliases: Variant = words.aliases
    var catalog: Variant = words.catalog
    expect(vocabulary is Dictionary and categories is Dictionary and aliases is Dictionary and catalog is Dictionary, "All vocabulary JSON documents decode into dictionaries")
    if not (vocabulary is Dictionary and categories is Dictionary and aliases is Dictionary and catalog is Dictionary):
        quit(1)
        return
    expect(vocabulary.size() > 0 and categories.size() == vocabulary.size(), "Every word has one category")
    expect(catalog.size() >= 183, "Reusable learning assets keep their prefab sizes")
    var valid_categories: Array = words.category_rules.keys()
    expect(valid_categories.size() >= 10 and valid_categories.size() <= 20, "A small, browsable category set")
    for category in valid_categories:
        expect(categories.values().has(category), "Category has words: " + str(category))
    # Scenes store only word_key; cached Spanish/category copies must not return.
    for folder in ["res://scenes/props/vocabulary", "res://scenes/buildings", "res://scenes/world"]:
        for file in DirAccess.get_files_at(folder):
            if not file.ends_with(".tscn"): continue
            var text := FileAccess.get_file_as_string(folder + "/" + file)
            expect(not text.contains("\nmetadata/spanish = ") and not text.contains("\nmetadata/category = ") and not text.contains("\nmetadata/english = "), "No cached word metadata in " + file)
    for key in vocabulary.keys():
        expect(categories.has(key), "Missing category: " + str(key))
        if categories.has(key):
            expect(valid_categories.has(str(categories[key])), "Invalid category for " + str(key))
    for key in categories.keys():
        expect(vocabulary.has(key), "Orphan category: " + str(key))
    for key in aliases.keys():
        expect(vocabulary.has(aliases[key]) and not vocabulary.has(key), "Alias resolves to primary vocabulary: " + str(key))
    for key in catalog.keys():
        expect(vocabulary.has(key), "Catalog word exists: " + str(key))
        if categories.has(key):
            expect(str(catalog[key].get("category", "")) == str(categories[key]), "Prefab category matches the dictionary: " + str(key))
    for deleted in ["couch", "exam bed", "science", "skeleton", "student desk", "petri dish", "microscope", "baseboard"]:
        expect(not vocabulary.has(deleted) and not categories.has(deleted), "Deleted vocabulary must not reappear: " + deleted)
    var studied: Dictionary = VocabularyProgress.normalize_studied_words(
        ["tap", "faucet", "bedside table", "nightstand", "bed", "imaginary word"], vocabulary, aliases)
    expect(studied.size() == 3 and studied.has("faucet") and studied.has("nightstand") and studied.has("bed"), "Existing save normalization remains compatible")
    var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
    expect(scene != null, "Project's entry scene can load")
    if failures.is_empty():
        print("PASS: ", vocabulary.size(), " words in ", valid_categories.size(), " categories; catalog, aliases, no cached scene copies, save normalization and scene loading")
    quit(0 if failures.is_empty() else 1)
