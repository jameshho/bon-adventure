extends SceneTree
## Frame times while a building arrives (26 Nov 2026, "spread each building's arrival" and "pre-warm
## shaders"): calls the real Main.add_unit() for each named unit (pending ones only) with the
## player standing in it, and prints every frame's wall time from the call until 20 frames after
## it returns (the first draws, where shader compiles show), the worst frame and its index, and
## what Main was doing. --prefetch loads the scene first; --prepare runs NearbyUnits.prepare() first (load, then instance).
## Then frees the unit again (Main.remove_unit()) so the next run starts alike. The shader warm-up
## tried on 26 Nov (since removed) is measured in the folder's README.
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=1 godot --path . --audio-driver Dummy \
##   --script res://docs/evidence/far-unit-freeing-20261126/time_arrival.gd -- restaurants hospital home police
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")

var main: Node
var stamps: Array = []
var recording := false
## "--prefetch" as the first user argument: load() the unit scene a few frames before add_unit().
var prefetch := false
var held_scene: Resource
## "--prepare": NearbyUnits.prepare() first (load, then instance), as nearby loading does.
var preparing := false
var nearby: Node


func _initialize() -> void:
	run.call_deferred()

func centre(key: String) -> Vector2:
	var box: Array = NearbyUnits.data().boxes[key][0]
	return Vector2((box[0] + box[2]) * 0.5, (box[1] + box[3]) * 0.5)

func _process(_delta: float) -> bool:
	if recording:
		stamps.append(Time.get_ticks_usec())
	return false

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.staged_loading = true
	main.initial_units = ["barn"]
	get_root().add_child(main)
	await main.town_ready
	for i in 60:
		await process_frame
	var args := Array(OS.get_cmdline_user_args())
	if args.has("--prefetch"):
		prefetch = true
		args.erase("--prefetch")
	if args.has("--prepare"):
		preparing = true
		args.erase("--prepare")
		nearby = NearbyUnits.new()
		nearby.setup(main)
		main.add_child(nearby)
		nearby.set_process(false)
	var summary: Array = []
	for round in 2:
		for key in args:
			if not main.pending_units.has(key):
				continue
			var at := centre(key)
			main.player.global_position = main.apartment.to_global(Vector3(at.x, 40.0, at.y))
			main.player.velocity = Vector3.ZERO
			for i in 10:
				await process_frame
			var load_ms := -1.0
			var prep_note := ""
			if prefetch:
				var t0 := Time.get_ticks_usec()
				held_scene = load("res://scenes/town/%s.scn" % key)
				load_ms = (Time.get_ticks_usec() - t0) / 1000.0
				await process_frame
				await process_frame
			if preparing:
				stamps = [Time.get_ticks_usec()]
				recording = true
				var pairs_before := Time.get_ticks_usec()
				await nearby.prepare(key)
				recording = false
				var prep: Array = []
				for i in range(1, stamps.size()):
					prep.append((stamps[i] - stamps[i - 1]) / 1000.0)
				prep_note = "prepare %d frames, worst %.0f ms %s; " % [prep.size(), prep.max() if not prep.is_empty() else 0.0, prep.map(func(ms: float) -> String: return "%.0f" % ms).slice(0, 12)]
				for i in 5:
					await process_frame
			stamps = [Time.get_ticks_usec()]
			recording = true
			var started := Time.get_ticks_usec()
			await main.add_unit(key)
			var hooked := stamps.size()
			for i in 20:
				main.player.velocity = Vector3.ZERO
				await process_frame
			recording = false
			var times: Array = []
			for i in range(1, stamps.size()):
				times.append((stamps[i] - stamps[i - 1]) / 1000.0)
			var worst := 0.0
			var worst_at := 0
			for i in times.size():
				if times[i] > worst:
					worst = times[i]
					worst_at = i
			var line := prep_note + ("load %.0f ms first; " % load_ms if prefetch else "") + "%s round %d: add_unit %.0f ms over %d frames; worst frame %.0f ms (frame %d, %s)" % [key, round + 1,
				(stamps[hooked - 1] - started) / 1000.0, hooked - 1, worst, worst_at + 1, "during add_unit" if worst_at + 1 < hooked else "first draws after"]
			print(line)
			print("   frames: ", times.map(func(ms: float) -> String: return "%.0f" % ms))
			summary.append(line)
			main.remove_unit(key)
			for i in 30:
				await process_frame
	print("ARRIVAL SUMMARY")
	for line in summary:
		print(line)
	quit(0)
