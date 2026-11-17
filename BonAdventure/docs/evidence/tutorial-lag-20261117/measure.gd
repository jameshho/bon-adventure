extends SceneTree
## Tutorial lag (17 Nov 2026, docs/evidence/tutorial-lag-20261117/README.md): plays the welcome
## tutorial's house act through app.tscn (simulated input, a reader's 1.5 s per line) and logs
## every frame slower than HITCH_MS with the step it happened in, how the loading bar moved, and
## each step's worst frame. Stops a few seconds into the title cutscene.
## Needs graphics (shader compiling is what it looks for). Writes a profile: isolated HOME. An
## empty HOME is a first launch; a second run with the same HOME reuses the profile (warm caches).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/tutorial-lag-20261117/measure.gd
## The web build, where the lag showed, is measured in the browser instead (README.md).
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const Tutorial := preload("res://scripts/learning/tutorial.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const HITCH_MS := 40.0

var app: Node
var main: Node
var tutorial: Node
var last_us := 0
var started_us := 0
var rows: Array = []
var per_step := {}
var vp: RID
var phase := "loading"
var bar: Array = []

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func label() -> String:
	if app != null and app.loading != null:
		return "loading/warm-up"
	if tutorial == null:
		return phase
	var s: Dictionary = tutorial.step
	if s.is_empty():
		return "(no step)"
	var extra := str(s.get("line", s.get("for", s.get("who", ""))))
	var dlg := " [box]" if main.shop_panel.is_dialogue_visible() else ""
	var cam := " [closeup]" if get_root().get_viewport().get_camera_3d() != main.camera else ""
	return "%s %s%s%s" % [s.do, extra, dlg, cam]

func _on_frame() -> void:
	var now := Time.get_ticks_usec()
	if last_us != 0:
		var ms := (now - last_us) / 1000.0
		var l := label()
		var cpu := RenderingServer.viewport_get_measured_render_time_cpu(vp)
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(vp)
		var proc := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		if not per_step.has(l):
			per_step[l] = {"frames": 0, "worst": 0.0, "hitches": 0, "total": 0.0}
		var e: Dictionary = per_step[l]
		e.frames += 1
		e.total += ms
		e.worst = maxf(e.worst, ms)
		if ms > HITCH_MS:
			e.hitches += 1
			rows.append("%8.0f ms  frame %6.1f ms  process %6.1f  render cpu %6.1f gpu %6.1f  objects %d  | %s" % [
				(now - started_us) / 1000.0, ms, proc, cpu, gpu,
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), l])
	last_us = now
	if app != null and app.loading != null and is_instance_valid(app.loading):
		var p: float = app.loading._progress
		if bar.is_empty() or absf(bar.back()[1] - p) > 0.02:
			bar.append([(now - started_us) / 1000.0, p])

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	vp = get_root().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var manager = ProfileManager.shared()
	var id := ""
	if FileAccess.file_exists("user://profiles/index.json"):
		# Only a profile this check made ("Ana"): never a learner's saves.
		var first: Dictionary = manager.profiles()[0] if not manager.profiles().is_empty() else {}
		if str(first.get("name", "")) != "Ana" or manager.profiles().size() != 1:
			print("MEASURE: refusing to run, saves exist (use an isolated HOME)")
			quit(1)
			return
		id = str(first.id)
	if id == "":
		if manager.has_legacy_saves() or FileAccess.file_exists(preload("res://scripts/core/game_settings.gd").PATH):
			print("MEASURE: refusing to run, saves exist (use an isolated HOME)")
			quit(1)
			return
		id = manager.create("Ana", "Ana", "bonbon")
		print("FIRST LAUNCH (new profile)")
	else:
		manager.select(id)
		manager.update(id, {"tutorial": {"act": 0, "done": false}})
		print("REPEAT LAUNCH (existing profile, caches warm)")
	preload("res://scripts/core/app.gd")._skip_splash = true
	app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await frames(3)
	started_us = Time.get_ticks_usec()
	process_frame.connect(_on_frame)
	var t0 := Time.get_ticks_msec()
	app.start_town(id)
	while app.main == null or app.loading != null or app.main.process_mode == Node.PROCESS_MODE_DISABLED:
		await process_frame
	print("loading + warm-up: %d ms" % (Time.get_ticks_msec() - t0))
	main = app.main
	tutorial = main.get_node_or_null("Tutorial")
	if tutorial == null:
		print("no tutorial"); quit(1); return
	var handled := {}
	var guard := 0
	while tutorial.running and guard < 20000:
		guard += 1
		var spec: Dictionary = tutorial.step
		if not spec.is_empty() and spec.do == "cutscene":
			break
		if spec.is_empty() or handled.has(spec):
			await process_frame
			continue
		handled[spec] = true
		await drive(spec)
	# A few seconds of the cutscene, then stop.
	await create_timer(3.0).timeout
	process_frame.disconnect(_on_frame)
	print("\n== HITCHES (> %d ms), ms since start_town ==" % HITCH_MS)
	for r in rows:
		print(r)
	print("== BAR (ms, fraction) ==")
	for b in bar:
		print("%8.0f  %.2f" % [b[0], b[1]])
	print("\n== PER STEP: frames, worst, hitches, avg ==")
	for l in per_step:
		var e: Dictionary = per_step[l]
		print("%5d  worst %7.1f  hitches %3d  avg %5.1f | %s" % [e.frames, e.worst, e.hitches, e.total / e.frames, l])
	quit(0)

func next() -> void:
	# A reader takes a moment over each line.
	await create_timer(1.5).timeout
	var waited := 0
	while not main.shop_panel.has_choices() and waited < 600:
		await process_frame
		waited += 1
	main.shop_panel.choice_pressed.emit(Tutorial.NEXT)
	await frames(2)

func teleport(at: Vector3, look: Vector3) -> void:
	tutorial.zone.place_player(tutorial._space("world"), at, look)
	await frames(3)

func drive(spec: Dictionary) -> void:
	match str(spec.do):
		"say":
			await next()
		"wait":
			await create_timer(1.0).timeout
			match str(spec.for):
				"stand":
					var tries := 0
					while main.player.seated and tries < 600:
						main.seating.stand()
						await process_frame
						tries += 1
				"view":
					main.player.look_by(Vector2(400, 0))
				"move":
					var from: Vector3 = main.player.global_position
					await teleport(from + Vector3(2.0, 0.0, 0.0), Vector3(1, 0, 0))
				"near":
					var point: Vector3
					if spec.has("who"):
						point = tutorial.actors[str(spec.who)].global_position + Vector3(1.0, 0, 0)
					else:
						point = tutorial._space(str(spec.space)).to_global(tutorial._vec(spec.at))
					await teleport(point, Vector3(0, 0, 1))
				"door":
					var door: Node3D = tutorial._door(spec)
					if door != null and not main.doors[door].get("open", false):
						DoorAnimator.toggle(main, door)
				"use":
					var curtain: Node3D = main.apartment.get_node(NodePath(str(tutorial.data.curtain)))
					var home: Node3D = tutorial._space("home")
					await teleport(home.to_global(Vector3(-7.9, 0, 9.6)), home.global_basis * Vector3(-1, 0, 0))
					DoorAnimator.toggle(main, curtain)
