extends SceneTree
## Radar Patrol from the test launcher in the full town (9 Nov 2026): Play opens the screen,
## a click on a UFO scores, Esc closes it and the launcher's test ends.
## HOME=<scratch>/home godot --path . --resolution 1200x800 --script res://docs/evidence/radar-patrol-20261109/launcher.gd
const Board := preload("res://scripts/learning/activity_board.gd")
var failures := 0
var game
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	var launcher = game.game_launcher
	var panel = game.radar_panel
	check(Board.shared().session("radar_patrol") != null, "radar_patrol registered")
	launcher.open()
	await frames(3)
	print("blocked: '", launcher.blocked("radar_patrol"), "'")
	check(launcher.launch("radar_patrol"), "launch returns true")
	await frames(10)
	print("panel visible=%s rect=%s viewport=%s parent=%s mouse_filter=%d" % [panel.visible, panel.get_global_rect(), root.get_visible_rect(), panel.get_parent().get_path(), panel.mouse_filter])
	print("state=%s mouse_mode=%d controls=%s launcher.testing=%s" % [panel.state, Input.mouse_mode, game.player.controls_enabled, launcher.testing])
	root.get_texture().get_image().save_png("res://docs/evidence/radar-patrol-20261109/launcher-open.png")
	# Click to start.
	await click(panel._centre)
	check(panel.state == panel.State.PLAYING, "a click starts the game (state %s)" % panel.state)
	await create_timer(4.0).timeout
	root.get_texture().get_image().save_png("res://docs/evidence/radar-patrol-20261109/launcher-play.png")
	var ufo = null
	for e in panel.game.entities:
		if e["kind"] == "ufo" and e["pos"].length() < 0.9: ufo = e
	print("entities=%d over=%s time=%.1f" % [panel.game.entities.size(), panel.game.over, panel.game.time])
	if ufo != null:
		await click(panel._centre + ufo["pos"] * panel._radius)
		check(panel.game.kills >= 1, "clicking a UFO destroys it (kills %d, score %d)" % [panel.game.kills, panel.game.score])
	game.popups.close_top()
	await frames(5)
	check(not panel.visible and game.player.controls_enabled, "Esc closes the screen and frees the player")
	await create_timer(1.0).timeout
	check(launcher.testing == "", "launcher test ended")
	# E on a real radar (9 Nov 2026 bug: the panel was also in the "radar_patrol" group, so the
	# radar could call the panel's void open_game() and hit a Nil-return script error).
	check(get_nodes_in_group("radar_patrol").size() == 1, "only the session is in the radar_patrol group")
	for radar_name in ["Radar scope", "Radar display"]:
		var radar = game.apartment.get_node_or_null("Airport/ControlTower/Interior/" + radar_name)
		check(radar != null and radar.has_method("use"), "%s has use()" % radar_name)
		if radar == null: continue
		check(radar.use() == true and panel.visible, "%s: use() opens the screen" % radar_name)
		await frames(3)
		game.popups.close_top()
		await frames(5)
		check(not panel.visible and game.player.controls_enabled, "%s: Esc closes the screen" % radar_name)
	print("radar launcher: %d failure(s)" % failures)
	quit(1 if failures else 0)
func click(at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		Input.parse_input_event(e)
		await frames(2)
