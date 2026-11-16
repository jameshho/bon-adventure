extends SceneTree
## Evidence for the clay pig animation pilot (16 Nov 2026; record in docs/guides/ANIMAL_SYSTEM.md
## #clay-animal-animation-pilot-16-nov-2026). Loads only the two pig scenes, never the town.
##   compare.png    original display (top) and rigged pig at rest (bottom), studio light, 4 views;
##                  the pixel difference is printed (shading check)
##   seams.png      neck and hips close up at the walk's extreme poses with the head turned
##   walk.png       8 frames of one walk cycle, side view
##   idle.png       6 frames of standing (breath and weight shift), front view, 0.6 s apart
##   blink.png      the face: eyes open, half, shut (plush_life.gd's set_eyes_open)
##   head-turn.png  the head turned right, centre, left
##   wander.png     pig_anim_test.tscn running: the rigged pig wandering with park_animals.gd
##                  beside the original
##   perf.json      frame times with 0, 10 static, 1 and 10 rigged pigs (Compatibility renderer)
## Writes only into this folder. Run with an isolated HOME and a time limit (the window must be
## drawn; a hidden window can hang):
##   godot --path . --resolution 1000x700 --script res://docs/evidence/pig-anim-20261116/capture.gd [-- perf]
## (`-- perf`: timings only.) The timings are only valid while the window is shown and drawn: a
## covered window gave the same frame time for every case (16 Nov 2026), so check that
## triangles_drawn changes between cases. The run does not exit by itself after its report;
## stop it after "PIG ANIM REPORT".
const OUT := "res://docs/evidence/pig-anim-20261116/"
const W := 520
const H := 400
const Stage := preload("res://docs/evidence/pig-anim-20261116/pig_anim_test.gd")
const PlushLife := preload("res://scripts/characters/plush_life.gd")

var cam: Camera3D


func _initialize() -> void:
	run.call_deferred()


func shot() -> Image:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func aim(target: Vector3, dir: Vector3, size: float) -> void:
	cam.size = size
	cam.position = target + dir.normalized() * 14.0
	cam.look_at(target)


func tile(img: Image) -> Image:
	var out := img.duplicate() as Image
	out.resize(W, H, Image.INTERPOLATE_LANCZOS)
	return out


func sheet(rows: Array, file: String) -> void:
	var cols := 0
	for r in rows: cols = maxi(cols, r.size())
	var img := Image.create(W * cols, H * rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	for y in rows.size():
		for x in rows[y].size():
			img.blit_rect(rows[y][x], Rect2i(0, 0, W, H), Vector2i(x * W, y * H))
	img.save_png(OUT + file)


## Mean colour difference (0-255) over the pixels either image covers, and the share of those
## pixels that differ by more than 8 levels in any channel.
func difference(a: Image, b: Image, bg: Color) -> Array:
	var total := 0.0
	var counted := 0
	var off := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if _near(ca, bg) and _near(cb, bg): continue
			counted += 1
			var d := maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))) * 255.0
			total += d
			if d > 8.0: off += 1
	return [total / maxi(counted, 1), float(off) / maxi(counted, 1)]


func _near(c: Color, bg: Color) -> bool:
	return absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) < 0.02


func run() -> void:
	root.size = Vector2i(1000, 700)
	DisplayServer.window_set_size(Vector2i(1000, 700))
	var report := {}
	if OS.get_cmdline_user_args().has("perf"):
		# Timings only; keep the rest of the last report.
		var old := FileAccess.get_file_as_string(OUT + "perf.json")
		if old != "":
			report = JSON.parse_string(old)
	else:
		await studio(report)
		await wander()
	report["perf"] = await perf()
	var f := FileAccess.open(OUT + "perf.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("PIG ANIM REPORT ", JSON.stringify(report))
	quit()


## Studio views (the light of docs/evidence/pig-clay-20261111/capture.gd: lamps ride on the camera).
func studio(report: Dictionary) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	var bg := Color("fdf0e9")
	env.environment.background_color = bg
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var original: Node3D = load("res://scenes/animals/pig_clay.tscn").instantiate()
	stage.add_child(original)
	var rigged: Node3D = load("res://scenes/animals/pig_clay_rigged.scn").instantiate()
	stage.add_child(rigged)
	var anim = rigged.get_node("ClayAnimator")
	anim.set_process(false)
	var skeleton: Skeleton3D = rigged.get_node("Skeleton3D")
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(60): await process_frame
	# compare.png: rest pose against the display.
	skeleton.reset_bone_poses()
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0.7, 0.14, 0.7)]
	var top := []
	var bottom := []
	var diffs := []
	for v in views:
		aim(Vector3(0, 0.47, 0), v, 1.36)
		rigged.hide()
		original.show()
		var a: Image = await shot()
		original.hide()
		rigged.show()
		var b: Image = await shot()
		diffs.append(difference(a, b, bg))
		top.append(tile(a))
		bottom.append(tile(b))
	sheet([top, bottom], "compare.png")
	report["rest_difference"] = diffs
	original.hide()
	# walk.png: one cycle, side view (the pig walks toward the left of the picture).
	anim.speed_override = 0.6
	anim.speed = 0.6
	anim.walk = 1.0
	var row := []
	for k in 8:
		anim.phase = k / 8.0
		anim.advance(0.0)
		aim(Vector3(0, 0.47, 0), Vector3(-1, 0.08, 0), 1.36)
		row.append(tile(await shot()))
	var row2 := []
	for k in 4:
		anim.phase = k / 4.0 + 0.125
		anim.advance(0.0)
		aim(Vector3(0, 0.47, 0), Vector3(-0.7, 0.2, -0.7), 1.36)
		row2.append(tile(await shot()))
	sheet([row.slice(0, 4), row.slice(4, 8), row2], "walk.png")
	# seams.png: extreme swing (phase 0.25 and 0.75) with the head turned and nodding; neck and
	# hips close up from the side, from above the back and from below.
	var seams := []
	for p in [0.25, 0.75]:
		anim.phase = p
		anim.look(24.0 if p < 0.5 else -24.0, 100.0)
		anim.set("_yaw", anim.get("_yaw_goal"))
		anim.advance(0.0)
		var r := []
		aim(Vector3(0, 0.42, -0.1), Vector3(-1, 0.15, 0.1), 0.85)
		r.append(tile(await shot()))
		aim(Vector3(0, 0.4, 0.4), Vector3(-1, 0.1, 0.2), 0.85)
		r.append(tile(await shot()))
		aim(Vector3(0, 0.5, 0.05), Vector3(0.6, 1.0, -0.4), 1.25)
		r.append(tile(await shot()))
		aim(Vector3(0, 0.35, 0.05), Vector3(-0.8, -0.35, 0.5), 1.25)
		r.append(tile(await shot()))
		seams.append(r)
	sheet(seams, "seams.png")
	# head-turn.png: right, centre, left (front 3/4 and front), standing.
	anim.speed_override = 0.0
	anim.speed = 0.0
	anim.walk = 0.0
	var turns := [[], []]
	for yaw in [-24.0, 0.0, 24.0]:
		anim.look(yaw, 100.0)
		anim.set("_yaw", anim.get("_yaw_goal"))
		anim.advance(0.0)
		aim(Vector3(0, 0.5, -0.2), Vector3(-0.72, 0.12, -0.69), 1.0)
		turns[0].append(tile(await shot()))
		aim(Vector3(0, 0.5, -0.2), Vector3(0, 0.1, -1), 1.0)
		turns[1].append(tile(await shot()))
	sheet(turns, "head-turn.png")
	anim.look(0.0, 100.0)
	anim.set("_yaw", 0.0)
	# idle.png: 6 frames, 0.6 s apart (breath and weight shift), front and side.
	var idle := [[], []]
	for k in 6:
		anim.advance(0.6)
		anim.set("_yaw", 0.0)
		anim.look(0.0, 100.0)
		anim.advance(0.0)
		aim(Vector3(0, 0.47, 0), Vector3(0, 0.1, -1), 1.2)
		idle[0].append(tile(await shot()))
		aim(Vector3(0, 0.47, 0), Vector3(-1, 0.08, 0), 1.36)
		idle[1].append(tile(await shot()))
	sheet(idle, "idle.png")
	# blink.png: open, half, shut; front and 3/4.
	skeleton.reset_bone_poses()
	var blink := [[], []]
	for open in [1.0, 0.5, 0.0]:
		PlushLife.set_eyes_open(rigged, open)
		aim(Vector3(0, 0.62, -0.5), Vector3(0, 0.02, -1), 0.6)
		blink[0].append(tile(await shot()))
		aim(Vector3(0, 0.62, -0.5), Vector3(-0.72, 0.05, -0.69), 0.6)
		blink[1].append(tile(await shot()))
	PlushLife.set_eyes_open(rigged, 1.0)
	sheet(blink, "blink.png")
	stage.queue_free()
	await process_frame


## wander.png: the test stage running in real time, a frame every 0.7 s once the pig walks.
func wander() -> void:
	var stage = Stage.new()
	stage.with_camera = false
	root.add_child(stage)
	cam = Camera3D.new()
	cam.fov = 38
	stage.add_child(cam)
	cam.position = Vector3(0, 2.6, 5.2)
	cam.look_at(Vector3(-0.3, 0.3, 0))
	cam.current = true
	var frames := []
	var waited := 0.0
	while frames.size() < 8 and waited < 40.0:
		var t0 := Time.get_ticks_msec()
		if str(stage.wanderer.get("state")) == "walking" or not frames.is_empty():
			for i in 20: await process_frame
			frames.append(tile(await shot()))
		else:
			await process_frame
		waited += (Time.get_ticks_msec() - t0) / 1000.0
	print("WANDER: %d frames, state %s, walk %.2f" % [frames.size(), stage.wanderer.get("state"), stage.rigged.get_node("ClayAnimator").walk])
	if frames.size() >= 4:
		sheet([frames.slice(0, 4), frames.slice(4, 8)], "wander.png")
	stage.queue_free()
	await process_frame


## Frame times on the Compatibility renderer: an empty stage, 10 static display pigs, 1 rigged
## pig and 10 rigged pigs (all walking or idling with park_animals.gd), and 10 rigged pigs with
## their animators off (no pose changes), and 10 rigged pigs behind the camera (the animator
## skips pigs off screen). Vsync off; 90 warm-up frames, then 240 measured.
func perf() -> Dictionary:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var vp := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var result := {"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
			"adapter": RenderingServer.get_video_adapter_name(), "window": str(root.size)}
	for case in [["empty", 0, false], ["static x10", 10, false], ["rigged x1", 1, true], ["rigged x10", 10, true], ["rigged x10, animator off", 10, true], ["rigged x10, camera turned away", 10, true]]:
		var stage = Stage.new()
		stage.with_camera = false
		root.add_child(stage)
		stage.original.hide()
		stage.wanderer.queue_free()
		cam = Camera3D.new()
		cam.fov = 50
		stage.add_child(cam)
		cam.position = Vector3(0, 5.5, 7.5)
		cam.look_at(Vector3(0, 0.3, 0) if not case[0].ends_with("away") else Vector3(0, 5.5, 30))
		cam.current = true
		var animators := []
		for i in case[1]:
			var at := Vector3((i % 5 - 2) * 1.6, 0, (i / 5) * 2.0 - 1.0)
			if case[2]:
				var w: Node3D = stage.make_wanderer(at, 0.6)
				var anim: Node = w.get_child(0).get_node("ClayAnimator")
				if case[0].ends_with("off"):
					anim.set_process(false)
				animators.append(anim)
			else:
				var pig: Node3D = load("res://scenes/animals/pig_clay.tscn").instantiate()
				pig.position = at
				stage.add_child(pig)
		for i in 90: await process_frame
		var times := []
		var cpu := 0.0
		var gpu := 0.0
		var proc := 0.0
		var last := Time.get_ticks_usec()
		for i in 240:
			await process_frame
			var now := Time.get_ticks_usec()
			times.append((now - last) / 1000.0)
			last = now
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		times.sort()
		var mean := 0.0
		for t in times: mean += t
		mean /= times.size()
		var walking := 0
		for a in animators:
			if a.walk > 0.5: walking += 1
		result[case[0]] = {"frame_ms_mean": snappedf(mean, 0.01), "frame_ms_p95": snappedf(times[int(times.size() * 0.95)], 0.01),
				"render_cpu_ms": snappedf(cpu / 240.0, 0.01), "render_gpu_ms": snappedf(gpu / 240.0, 0.01),
				"walking_at_end": walking,
				"triangles_drawn": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
		print("PERF ", case[0], " ", result[case[0]])
		stage.queue_free()
		for i in 5: await process_frame
	return result
