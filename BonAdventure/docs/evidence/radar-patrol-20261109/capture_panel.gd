extends SceneTree
## Renders the Radar Patrol screen alone (no town) in its three looks: start card, play, game
## over. godot --path . --resolution 1100x800 --script res://docs/evidence/radar-patrol-20261109/capture_panel.gd
const RadarPanel := preload("res://scripts/ui/radar_patrol_panel.gd")
func _init() -> void:
	_run.call_deferred()
func _shot(panel, name: String) -> void:
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png("res://docs/evidence/radar-patrol-20261109/%s.png" % name)
	print("saved ", name)
func _run() -> void:
	var panel = RadarPanel.new()
	root.add_child(panel)
	panel.set_process(false)
	panel.size = root.get_visible_rect().size
	panel.open_game()
	panel._clock = 0.9
	panel._layout()
	await _shot(panel, "ready")
	panel.start()
	panel.game.reset(5)
	for i in 900:
		panel.game.step(1.0 / 60.0)
		if panel.game.over: break
	# Stage a busy scene: hits, a combo and a threat.
	var g = panel.game
	g.over = false
	g.entities = [
		{"kind": "plane", "pos": Vector2(-0.55, -0.35), "vel": Vector2(0.2, 0.02), "entered": true, "id": 1, "flash": 0.0},
		{"kind": "plane", "pos": Vector2(0.45, 0.35), "vel": Vector2(-0.18, -0.05), "entered": true, "id": 2, "flash": 0.0},
		{"kind": "ufo", "pos": Vector2(0.25, -0.42), "vel": Vector2(-0.2, 0.08), "entered": true, "id": 3, "flash": 0.0},
		{"kind": "ufo", "pos": Vector2(-0.48, 0.12), "vel": Vector2(0.18, 0.1), "entered": true, "id": 4, "flash": 0.0},
		{"kind": "ufo", "pos": Vector2(0.38, 0.28), "vel": Vector2(0.05, 0.2), "entered": true, "id": 5, "flash": 0.0},
		{"kind": "ufo", "pos": Vector2(-0.2, 0.62), "vel": Vector2(0.1, -0.2), "entered": true, "id": 6, "flash": 0.0}]
	g.score = 12500; g.combo = 3
	g.entities.append({"kind": "ufo", "pos": Vector2(0.05, 0.05), "vel": Vector2(0.1, 0.1), "entered": true, "id": 7, "flash": 0.0})
	g.tap(Vector2(0.05, 0.05))
	panel._take_events()
	for e in panel._effects: e["age"] = 0.2
	panel._clock = 2.0
	panel.queue_redraw()
	await _shot(panel, "play")
	g.entities[4]["pos"] = Vector2(0.42, 0.33)
	g.step(0.001)
	panel._take_events()
	# Staged records (not real values): BEST and, under it, MOST UFOS.
	panel.best = 25000
	panel.best_kills = 42
	panel.state = panel.State.OVER
	panel._effects = panel._effects.filter(func(e): return e["kind"] == "crash")
	for e in panel._effects: e["age"] = 3.0
	panel._layout()
	panel.queue_redraw()
	await _shot(panel, "game-over")
	quit()
