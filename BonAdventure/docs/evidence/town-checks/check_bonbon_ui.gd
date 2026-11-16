extends SceneTree
var failed := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failed += 1
        push_error(message)
func _initialize() -> void: run.call_deferred()
func event_for(code: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event
func run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game._unhandled_input(event_for(KEY_J))
    check(game.hud.is_journal_open() and not game.player.controls_enabled, "Journal blocks movement")
    var distance: float = game.player.camera_distance
    var wheel := InputEventMouseButton.new()
    wheel.button_index = MOUSE_BUTTON_WHEEL_UP
    wheel.pressed = true
    game.player._unhandled_input(wheel)
    game.player._unhandled_input(event_for(KEY_H))
    check(game.player.camera_distance == distance and not game.player.hyper_enabled, "Journal input cannot zoom or toggle hyper")
    game._unhandled_input(event_for(KEY_ESCAPE))
    check(not game.hud.is_journal_open() and game.player.controls_enabled, "Escape closes journal and restores control")
    game._unhandled_input(event_for(KEY_F1))
    check(game.hud.is_help_open() and not game.player.controls_enabled, "F1 opens help")
    game._unhandled_input(event_for(KEY_F1))
    game.player._unhandled_input(event_for(KEY_H))
    check(game.player.hyper_enabled and game.hud.movement_label.text.begins_with("HYPER"), "H toggles hyper and updates HUD")
    game.player._unhandled_input(event_for(KEY_H))
    check(game.player.effects.surfaces[0].material_overlay == game.player.effects.original_overlays[0], "Hyper off removes the aura")
    game._unhandled_input(event_for(KEY_M))
    check(game.hud.is_map_open() and not game.interaction.enabled, "Map blocks world picking")
    game._unhandled_input(event_for(KEY_ESCAPE))
    check(game.player.controls_enabled and game.interaction.enabled, "Map close restores gameplay")
    game.queue_free()
    await process_frame
    print("BONBON UI: ", failed, " failures")
    quit(0 if failed == 0 else 1)
