extends SceneTree

# Run with Godot --headless --path <project> --script res://docs/evidence/town-checks/check_interaction.gd.
# Uses a small physics fixture and the real HUD; never loads or writes user saves.
const InteractionController = preload("res://scripts/player/interaction_controller.gd")
const HUD_SCENE = preload("res://scenes/ui/vocabulary_hud.tscn")
const GameSettings = preload("res://scripts/core/game_settings.gd")
const Interactable = preload("res://scripts/core/interactable.gd")

var failures: Array[String] = []
var studied: Array[String] = []

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    root.size = Vector2i(1280, 720)
    var world := Node3D.new()
    root.add_child(world)
    var player := CharacterBody3D.new()
    world.add_child(player)
    var camera := Camera3D.new()
    player.add_child(camera)
    var hud = HUD_SCENE.instantiate()
    root.add_child(hud)

    var target := Node3D.new()
    target.name = "FixtureDoor"
    target.position = Vector3(0, 0, -3)
    target.set_meta("word_key", "door")
    world.add_child(target)
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    target.add_child(mesh)
    var body := StaticBody3D.new()
    target.add_child(body)
    var collision := CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    body.add_child(collision)

    var interaction := InteractionController.new()
    interaction.setup(camera, player, world, hud,
        {"door": "puerta"}, {"door": "Home"})
    interaction.word_studied.connect(func(key: String): studied.append(key))
    world.add_child(interaction)
    interaction.set_physics_process(false)
    await physics_frame
    await physics_frame

    var pointer := InputEventMouseMotion.new()
    pointer.position = Vector2(640, 360)
    pointer.global_position = pointer.position
    interaction._input(pointer)
    check(interaction.aimed_object() == target, "Saved-scene ancestor targeting")
    interaction._physics_process(1.0 / 30.0)
    # No hover glow or hover label since the interaction system (user, 12 Nov 2026).
    check(mesh.material_overlay == null, "No hover highlight")
    interaction.click()
    check(interaction.selected == target and hud.is_card_visible(), "Click opens vocabulary card")
    # Since UI Stage 3 (4 Nov 2026) the card shows the lexicon's word with its article.
    check(hud.current_spanish.ends_with("puerta") and hud.current_category == "Home", "Card translation and category")
    check(studied == ["door"], "Study emits word exactly once")
    interaction.click()
    check(interaction.selected == null and not hud.is_card_visible(), "Second click closes card")
    check(studied.size() == 1, "Closing card does not study again")

    # Free-cursor picking follows an off-center projected object.
    target.position.x = 1.4
    await physics_frame
    await physics_frame
    pointer.position = camera.unproject_position(target.global_position)
    interaction._input(pointer)
    check(interaction.aimed_object() == target, "Free cursor picks off-center vocabulary")
    target.position.x = 0
    await physics_frame
    await physics_frame
    pointer.position = Vector2(640, 360)
    interaction._input(pointer)

    # Interaction system (12 Nov 2026): an object with an Interactable is not a word. Focus, the
    # E badge, E (activate_focus) and a click all use it; none studies or opens a card.
    var uses := [0]
    var item: Node = Interactable.attach(target, {"prompt_distance": 4.0, "on_use": func() -> void: uses[0] += 1})
    check(interaction.aimed_object() == null, "An interactable is not a word target")
    interaction.refresh_focus()
    check(interaction.focus == item and interaction.icons.badge.visible, "In range and in front: focus and the E badge")
    check(interaction.activate_focus() and uses[0] == 1, "E uses the focus target")
    interaction.click()
    check(uses[0] == 2 and not hud.is_card_visible(), "A click on it uses it, with no word card")
    var area: Dictionary = interaction.icons.badge_hit_area(camera)
    check(not area.is_empty() and area.radius >= 22.0, "The badge has a finger-sized tap area")
    pointer.position = area.center + Vector2(area.radius * 0.5, 0)
    interaction._input(pointer)
    interaction.click()
    check(uses[0] == 3, "A tap on the badge uses the focus target")
    pointer.position = Vector2(640, 360)
    interaction._input(pointer)
    var claimed := [0]
    interaction.claim("fixture", func() -> bool: return true, func() -> void: claimed[0] += 1)
    interaction.refresh_focus()
    check(interaction.focus == null and not interaction.icons.badge.visible, "An input claim hides the focus")
    interaction.active_claim().use.call()
    interaction.click()
    check(claimed[0] == 1 and uses[0] == 3, "A claim takes E; its click does nothing without a click handler")
    interaction.release_claim("fixture")
    player.rotation.y = PI
    interaction.refresh_focus()
    check(interaction.focus == null, "Behind the player: no focus")
    player.rotation.y = 0
    item.free()
    await process_frame
    check(studied.size() == 1, "Using interactables does not study words")

    # Legacy objects may point to a vocabulary root outside the collider's ancestry.
    var legacy_root := Node3D.new()
    legacy_root.set_meta("word_key", "door")
    world.add_child(legacy_root)
    body.set_meta("root", legacy_root)
    check(interaction.aimed_object() == legacy_root, "Legacy metadata targeting")
    body.remove_meta("root")
    legacy_root.free()

    interaction.click()
    # A Display Mode change (the Settings Native checkbox) re-renders the open card.
    GameSettings.shared().set_native(true)
    interaction.refresh_selected_card()
    check(hud.is_card_visible() and studied.size() == 3, "Language refresh preserves study notification")
    GameSettings.shared().set_native(false)
    camera.rotation.y = 0.1
    interaction._physics_process(0.3)
    check(hud.is_card_visible(), "Small mouse movement keeps card open")
    camera.rotation.y = PI
    interaction._physics_process(0.1)
    check(hud.is_card_visible(), "Look-away dismissal has grace period")
    interaction._physics_process(0.13)
    check(not hud.is_card_visible(), "Looking away dismisses card after threshold")
    # A click ray-casts at once (12 Nov 2026): the turned camera's ray (physics-interpolated)
    # follows after physics frames, as at the other pointer moves above.
    await physics_frame
    await physics_frame
    interaction.click()
    check(studied.size() == 3, "Empty-space click does not study")

    camera.rotation.y = 0
    await physics_frame
    await physics_frame
    interaction.click()
    interaction._physics_process(1.0 / 120.0)
    check(hud.is_card_visible(), "Standing still keeps card open")
    player.position.x += 0.01
    interaction._physics_process(1.0 / 120.0)
    check(interaction.selected == null and not hud.is_card_visible(), "First small movement dismisses card immediately within range")
    var study_count := studied.size()
    interaction._physics_process(1.0 / 120.0)
    check(not hud.is_card_visible() and studied.size() == study_count, "Movement dismissal does not reopen or study again")
    # Right-button camera drag (orbit) closes the card; a tiny jitter does not.
    player.position.x -= 0.01
    interaction.click()
    check(hud.is_card_visible(), "Card reopens for the orbit test")
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_RIGHT
    press.pressed = true
    interaction._input(press)
    var nudge := InputEventMouseMotion.new()
    nudge.relative = Vector2(3, 0)
    interaction._input(nudge)
    check(hud.is_card_visible(), "Tiny right-drag jitter keeps the card open")
    var drag := InputEventMouseMotion.new()
    drag.relative = Vector2(12, 4)
    interaction._input(drag)
    check(not hud.is_card_visible(), "Right-button camera drag closes the card")
    press.pressed = false
    interaction._input(press)
    player.position.x = 0
    interaction.click()
    player.position.y += 0.01
    interaction._physics_process(1.0 / 120.0)
    check(not hud.is_card_visible(), "Vertical movement dismisses card immediately")
    player.position.y = 0
    interaction.click()
    player.position.z = 10
    interaction._physics_process(0.23)
    check(not hud.is_card_visible(), "Moving out of range dismisses card")
    check(interaction.aimed_object() == null, "Objects beyond interaction distance cannot be picked")
    world.free()
    hud.free()
    if failures.is_empty():
        print("PASS: interaction targeting, cards, signals, interactables (focus, badge, E, click, tap, claims), dismissal and range")
    quit(0 if failures.is_empty() else 1)
