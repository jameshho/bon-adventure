extends SceneTree
## Studio views of every clay animal prefab (16 Nov 2026), one strip each in <folder>/<animal>.png:
## front 3/4, side, a face close-up (framed on the Eyes mesh) and an eye close-up. Loads only the
## prefabs (not the town), so it writes no saves.
##   godot --path . --script res://docs/evidence/clay-sizes-20261116/views.gd -- <folder> [from=<prefab folder>] [nolod] [animal ...]
## With `diff <folder_a> <folder_b>` it compares every PNG of a with b's instead (also zoo.gd's) and prints the
## largest channel difference, the share of pixels off by more than 8/255 and the RMS error, and
## writes <folder_b>/<animal>-diff.png (b faded, pixels off by more than 8/255 in red).
const W := 480
const H := 540
const ANIMALS := ["black_bear", "black_bear_adult", "cow", "deer", "duck", "elephant", "flamingo",
	"giraffe", "golden_retriever", "gorilla", "kangaroo", "lion", "panda", "pig", "red_panda",
	"rhino", "zebra"]

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img

static func prefab(animal: String, from := "res://scenes/animals/") -> String:
	var path := from.path_join("%s_clay.tscn" % animal)
	return path if ResourceLoader.exists(path) else from.path_join("%s_clay.scn" % animal)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 3 and args[0] == "diff":
		diff(args[1], args[2])
		quit()
		return
	var folder: String = args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	# `from=<folder>`: load the prefabs from another folder (e.g. old versions taken from git).
	var from := "res://scenes/animals/"
	for arg in args.slice(1):
		if arg.begins_with("from="):
			from = arg.trim_prefix("from=")
	# `nolod`: draw every mesh at full detail (mesh LODs off), to tell LOD changes from others.
	if args.has("nolod"):
		root.mesh_lod_threshold = 0.0
	var animals: Array = Array(args.slice(1)).filter(func(a): return not a.begins_with("from=") and a != "nolod")
	if animals.is_empty():
		animals = ANIMALS
	root.size = Vector2i(W, H)
	root.always_on_top = true      # a covered window is not drawn on macOS
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("fbf3e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.34
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -150, 0)
	sun.light_energy = 0.26
	sun.shadow_enabled = true
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 40, 0)
	fill.light_energy = 0.2
	stage.add_child(fill)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	for animal: String in animals:
		var model: Node3D = load(prefab(animal, from)).instantiate()
		stage.add_child(model)
		var box := AABB()
		var eyes := AABB()
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			box = mi.get_aabb() if box.size == Vector3.ZERO else box.merge(mi.get_aabb())
			if mi.name == "Eyes":
				eyes = mi.get_aabb()
		var big := maxf(box.size.y, maxf(box.size.x, box.size.z))
		var views := [[box.get_center(), Vector3(-0.72, 0.12, -0.69), big * 1.15],
			[box.get_center(), Vector3(-1, 0.08, 0), big * 1.15],
			[eyes.get_center(), Vector3(-0.5, 0.05, -0.86), big * 0.55],
			[eyes.get_center(), Vector3(0, 0.02, -1), maxf(eyes.size.x, eyes.size.y) * 1.6]]
		var strip := Image.create(W * views.size(), H, false, Image.FORMAT_RGBA8)
		for i in views.size():
			cam.size = views[i][2]
			cam.position = views[i][0] + (views[i][1] as Vector3).normalized() * 14.0
			cam.look_at(views[i][0])
			var img: Image = await shot()
			strip.blit_rect(img, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
		strip.save_png(folder.path_join(animal + ".png"))
		print("VIEWS ", animal)
		model.free()
	stage.free()
	quit()

func diff(a_folder: String, b_folder: String) -> void:
	for file: String in DirAccess.get_files_at(a_folder):
		if not file.ends_with(".png") or file.ends_with("-diff.png"):
			continue
		var animal := file.get_basename()
		var a := Image.load_from_file(a_folder.path_join(animal + ".png"))
		var b := Image.load_from_file(b_folder.path_join(animal + ".png"))
		if a == null or b == null:
			continue
		a.convert(Image.FORMAT_RGBA8)
		b.convert(Image.FORMAT_RGBA8)
		var out := Image.create(a.get_width(), a.get_height(), false, Image.FORMAT_RGBA8)
		var worst := 0.0
		var off := 0
		var sq := 0.0
		for y in a.get_height():
			for x in a.get_width():
				var ca := a.get_pixel(x, y)
				var cb := b.get_pixel(x, y)
				var d := maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b)))
				worst = maxf(worst, d)
				sq += d * d
				if d > 8.0 / 255.0:
					off += 1
				out.set_pixel(x, y, Color.RED if d > 8.0 / 255.0 else cb.lerp(Color.WHITE, 0.75))
		out.save_png(b_folder.path_join(animal + "-diff.png"))
		var n := a.get_width() * a.get_height()
		print("DIFF %-17s max %3d/255  off>8: %6.3f%%  rms %.2f/255" % [animal, int(worst * 255), 100.0 * off / n, sqrt(sq / n) * 255.0])
