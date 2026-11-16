extends SceneTree
## Radar Patrol rules check (docs/guides/RADAR_PATROL.md): runs the simulation headless, no town.
## godot --headless --path . --script res://docs/evidence/radar-patrol-20261109/rules.gd
const Game := preload("res://scripts/learning/radar_patrol_game.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func _init() -> void:
	var g = Game.new()
	# 1. Idle: the game ends by a collision eventually, never by escapes.
	g.reset(7)
	var t := 0.0
	while not g.over and t < 600.0:
		g.step(1.0 / 30.0); t += 1.0 / 30.0
	check(g.over, "idle game ends in a collision (after %.1f s, %d escaped)" % [t, g.escaped])
	check(g.escaped > 0, "UFOs escape without ending the game")
	# 2. Tapping: a UFO hit scores and builds the combo; a miss breaks it; a plane costs points.
	g.reset(3)
	g.entities = [{"kind": "ufo", "pos": Vector2(0.2, 0), "vel": Vector2.ZERO, "entered": true, "id": 1, "flash": 0.0},
		{"kind": "ufo", "pos": Vector2(-0.4, 0.3), "vel": Vector2.ZERO, "entered": true, "id": 2, "flash": 0.0},
		{"kind": "plane", "pos": Vector2(0, -0.5), "vel": Vector2.ZERO, "entered": true, "id": 3, "flash": 0.0}]
	check(g.tap(Vector2(0.21, 0.01)) == "ufo" and g.score == 100 and g.combo == 1, "first hit: 100, combo 1")
	check(g.tap(Vector2(-0.4, 0.3)) == "ufo" and g.score == 250 and g.combo == 2, "second hit: +150, combo 2")
	check(g.tap(Vector2(0.7, 0.7)) == "miss" and g.combo == 0, "a miss breaks the combo")
	check(g.tap(Vector2(0, -0.5)) == "plane" and g.score == 50 and g.count("plane") == 1, "a plane tap costs 200 and the plane stays")
	# 2b. Forgiving touch (15 Nov 2026): a UFO beside a plane takes the tap, a tap where a moving
	# UFO just was still hits it, and a finger-sized slop reaches a UFO but not a plane as far.
	g.reset(3)
	g.entities = [{"kind": "ufo", "pos": Vector2(0.1, 0), "vel": Vector2.ZERO, "entered": true, "id": 1, "flash": 0.0},
		{"kind": "plane", "pos": Vector2(-0.02, 0), "vel": Vector2.ZERO, "entered": true, "id": 2, "flash": 0.0}]
	check(g.tap(Vector2(0.0, 0), 0.06) == "ufo", "a UFO within reach wins over a closer plane")
	g.entities = [{"kind": "ufo", "pos": Vector2(0.4, 0), "vel": Vector2(0.6, 0), "entered": true, "id": 1, "flash": 0.0}]
	check(g.tap(Vector2(0.4 - 0.6 * g.TAP_LAG, 0), 0.06) == "ufo", "a tap where a moving UFO just was still hits")
	g.entities = [{"kind": "plane", "pos": Vector2(0, 0), "vel": Vector2.ZERO, "entered": true, "id": 2, "flash": 0.0}]
	check(g.tap(Vector2(0.13, 0), 0.08) == "miss", "a plane does not take a tap at the edge of the finger slop")
	# 3. Collision on the radar ends the game; off the radar it does not.
	g.reset(1)
	g.entities = [{"kind": "ufo", "pos": Vector2(1.05, 0), "vel": Vector2.ZERO, "entered": false, "id": 1, "flash": 0.0},
		{"kind": "plane", "pos": Vector2(1.06, 0), "vel": Vector2.ZERO, "entered": false, "id": 2, "flash": 0.0}]
	g._next_ufo = 99.0; g._next_plane = 99.0
	g.step(0.01)
	check(not g.over, "no collision outside the radar")
	g.entities[0]["pos"] = Vector2(0.1, 0); g.entities[1]["pos"] = Vector2(0.15, 0)
	g.step(0.01)
	check(g.over, "UFO touching a plane ends the game")
	# 4. Difficulty rises.
	g.reset(1); var early := [g.pace(), g.ufo_interval(), g.plane_interval()]
	g.time = 120.0
	check(g.pace() > early[0] * 2.0 and g.ufo_interval() < early[1] * 0.5 and g.plane_interval() < early[2], "speed and spawn rate rise (pace %.2f, ufo every %.2f s)" % [g.pace(), g.ufo_interval()])
	# 5. Spawn safety (user, 9 Nov 2026): at every plane spawn its whole path keeps clear of
	# every other plane's remaining path, and no UFO already flying is near its start; and no
	# crash happens within a second of either craft entering the radar. Ten 4-minute idle games
	# (a crash is cleared and the game goes on).
	var spawns := 0
	var bad_cross := 0
	var bad_ufo := 0
	var plane_seconds := 0.0
	var sim_seconds := 0.0
	var crashes := 0
	var early_crashes := 0
	for seed_value in 10:
		g.reset(100 + seed_value)
		var seen := {}
		var entered_at := {}
		var last_id := 0
		while g.time < 240.0:
			g.step(1.0 / 30.0)
			plane_seconds += g.count("plane") / 30.0
			sim_seconds += 1.0 / 30.0
			for e in g.entities:
				if e["pos"].length() < 1.0 and not entered_at.has(e["id"]):
					entered_at[e["id"]] = g.time
				if e["kind"] != "plane" or seen.has(e["id"]):
					continue
				seen[e["id"]] = true
				spawns += 1
				var dir: Vector2 = e["vel"].normalized()
				var path_end: Vector2 = Game.exit_point(e["pos"], dir)
				var early_end: Vector2 = e["pos"] + dir * (Game.entry_distance(e["pos"], dir) + Game.PLANE_SAFE_REACH)
				for o in g.entities:
					if o == e: continue
					if o["kind"] == "plane" and Game.segment_distance(e["pos"], path_end, o["pos"], Game.exit_point(o["pos"], o["vel"].normalized())) < Game.PLANE_PATH_CLEARANCE - 0.01:
						bad_cross += 1
					# UFOs that were flying before this plane appeared.
					if o["kind"] == "ufo" and o["id"] <= last_id and Game.segment_point_distance(e["pos"], early_end, o["pos"]) < Game.PLANE_SPAWN_SAFE - 0.05:
						bad_ufo += 1
			for e in g.entities:
				last_id = maxi(last_id, e["id"])
			if g.over:
				crashes += 1
				var youngest := INF
				for e in g.entities:
					if e["pos"].distance_to(g.crash_point) < Game.CRASH_DISTANCE:
						youngest = minf(youngest, g.time - float(entered_at.get(e["id"], g.time)))
				if youngest < 1.0:
					early_crashes += 1
				g.over = false
				g.entities = g.entities.filter(func(x): return x["pos"].distance_to(g.crash_point) > Game.CRASH_DISTANCE)
	check(spawns > 100, "planes keep spawning (%d in 10 × 4 min, %.1f on screen on average)" % [spawns, plane_seconds / sim_seconds])
	check(bad_cross == 0, "no new plane path crosses another plane's path (%d)" % bad_cross)
	check(bad_ufo == 0, "no plane spawns with a UFO near the start of its path (%d)" % bad_ufo)
	check(early_crashes == 0, "no crash within 1 s of a craft entering the radar (%d of %d crashes)" % [early_crashes, crashes])
	# 6. Scripts load.
	for path in ["res://scripts/ui/radar_patrol_panel.gd", "res://scripts/learning/radar_patrol_session.gd", "res://scripts/objects/radar_console.gd", "res://scripts/buildings/airport.gd"]:
		var script: Script = load(path)
		check(script != null and script.can_instantiate(), "loads " + path)
	var panel_script = load("res://scripts/ui/radar_patrol_panel.gd")
	check(panel_script.can_instantiate() and panel_script._format(12850) == "012,850", "score format 012,850")
	print("radar patrol rules: %d failure(s)" % failures)
	quit(1 if failures else 0)
