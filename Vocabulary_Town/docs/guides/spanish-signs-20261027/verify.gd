extends SceneTree
## Spanish world signs: translation, language toggle round trip and fit report.
## godot --headless --path . --script res://docs/guides/spanish-signs-20261027/verify.gd
const Signs := preload("res://scripts/world/sign_language.gd")
var failures := 0
func _initialize(): run.call_deferred()
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        print("FAIL: ", message)
func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var town: Node3D = game.apartment
    var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    var signs: Array = get_nodes_in_group(Signs.GROUP)
    check(signs.size() == town.get_meta("translated_signs"), "group matches translated count")
    check(signs.size() > 100, "most English signs translated (" + str(signs.size()) + ")")
    var shrunk := []
    for label in signs:
        check(label.text == table[label.get_meta("sign_english")], "default shows Spanish: " + label.get_meta("sign_english"))
        if label.font_size < label.get_meta("sign_font_size"):
            shrunk.append("%s %d%%" % [label.text, roundi(100.0 * label.font_size / label.get_meta("sign_font_size"))])
    # Updated 4 Nov 2026 (Display Mode): the game starts in Foreign only; L cycles
    # Both (signs stay Spanish) -> Native only (English) -> Foreign only (Spanish). Run with an
    # isolated HOME: cycling saves user://settings.json.
    game.hud.cycle_language()
    game.hud.cycle_language()
    for label in signs:
        check(label.text == label.get_meta("sign_english") and label.font_size == label.get_meta("sign_font_size"), "English mode restores " + label.get_meta("sign_english"))
    game.hud.cycle_language()
    for label in signs:
        check(label.text == table[label.get_meta("sign_english")], "Spanish mode shows Spanish: " + label.get_meta("sign_english"))
    # Untranslated labels that still look English: all-ASCII words of 3+ letters.
    var regex := RegEx.create_from_string("\\b[A-Za-z]{3,}\\b")
    var left := {}
    for label in town.find_children("*", "Label3D", true, false):
        if label.is_in_group(Signs.GROUP) or not regex.search(label.text): continue
        left[label.text.replace("\n", " / ")] = true
    print("TRANSLATED SIGNS: ", signs.size(), "; shrunk ", shrunk.size(), ": ", shrunk)
    print("UNTRANSLATED WORD LABELS: ", left.keys())
    print("SPANISH SIGNS: ", failures, " failures")
    quit(failures)
