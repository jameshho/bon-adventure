extends SceneTree
## Former rear-wing displays live in the matching main-floor rooms (27 Oct 2026).
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/town-checks/check_hospital_departments.gd
const ROOMS := {
    "Floor1/Room2": ["stretcher", "defibrillator", "first aid kit", "oxygen tank", "syringe", "surgical mask"],
    "Floor1/Room3": ["stethoscope", "thermometer", "blood pressure monitor", "reflex hammer", "medicine", "sheet"],
    "Floor3/Room1": ["x ray machine", "medical monitor", "computer", "clipboard", "mri scanner", "headphones"],
    "Floor3/Room3": ["wheelchair", "crutches", "walker", "prosthetic leg", "bandage", "medicine"]
}
const MISSIONS := {"emergency_room": "Floor1/Room2", "examination_room": "Floor1/Room3", "imaging_room": "Floor3/Room1", "rehabilitation_room": "Floor3/Room3"}
var failures := 0
func _initialize(): run.call_deferred()
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        print("FAIL: ", message)

## Word roots under a room (lower-case key -> node), including the room's own descendants only.
func words_in(room: Node3D) -> Dictionary:
    var found := {}
    for node in room.find_children("*", "Node3D", true, false):
        var key := str(node.get_meta("word_key", "")).to_lower()
        if key != "" and not found.has(key): found[key] = node
    return found

func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var town: Node3D = game.apartment
    var hospital: Node3D = town.get_node("Buildings/Hospital")
    check(not hospital.has_node("LearningWing"), "rear wing removed from the hospital")
    for path in ["res://scenes/buildings/hospital_learning_wing.tscn", "res://scenes/buildings/rooms/hospital_emergencyroom.tscn"]:
        check(not ResourceLoader.exists(path), "wing scene deleted: " + path)
    var vocabulary: Dictionary = preload("res://scripts/learning/word_data.gd").load_all().vocabulary
    var lower := {}
    for key in vocabulary: lower[str(key).to_lower()] = true
    var placed := 0
    for room_path in ROOMS:
        var room: Node3D = hospital.get_node(room_path)
        var found := words_in(room)
        for word in ROOMS[room_path]:
            check(lower.has(word), "dictionary has " + word)
            check(found.has(word), word + " is in " + room_path)
            if found.has(word):
                placed += 1
                var target: Node3D = found[word]
                check(not target.find_children("*", "CollisionObject3D", true, false).is_empty(), word + " has a pick/collision shape")
    check(hospital.get_node("Floor1/Room3/HospitalBed/Sheet").get_meta("word_key", "") == "sheet", "examination bed sheet teaches sheet")
    # "imaging" moved from an old plaque onto the Imágenes door plaque (sign clean-up).
    var plaque: Node3D = hospital.get_node("Floor3/ImagingDoorPlaquePanel")
    check(plaque.get_meta("word_key", "") == "imaging" and not plaque.find_children("*", "CollisionObject3D", true, false).is_empty(), "Imágenes door plaque teaches imaging")
    print("HOSPITAL DEPARTMENTS: ", placed, " room words placed; ", failures, " failures")
    quit(failures)
