extends SceneTree
## 25 Nov 2026 BonBon life (P3-19, P3-20): renders the evidence sheets for this folder.
##   jump   BonBon jumping on a small stage (real physics: jump_queued, gravity, landing), side
##          view, COLUMNS frames FRAME_GAP s apart, the whole character at 1x; a second row from
##          the player's own camera (game distance). Writes jump-<label>.png.
##   blink  BonBon facing the camera through one blink of her own blinker (plush_life.gd), the
##          whole character at 1x, then the same frames as a 2x face crop. Writes blink.png.
##   glass  the town (VT_FOCUS picks the units), one outdoors-facing window at 07:00, 12:00,
##          18:40 and 22:00, each with the reflected sky at the old fixed colour (left) and the
##          hour's (right). Writes glass.png.
## HOME=<scratch>/home VT_FOCUS=supermarket VT_SPAWN=none godot --path . --audio-driver Dummy --resolution 1280x800 \
##   --script res://docs/evidence/bonbon-life-20261125/capture.gd -- <jump|blink|glass> [label]
## Graphics only; reads no saves (the glass mode loads Main: use the isolated HOME).
const OUT := "res://docs/evidence/bonbon-life-20261125"
const COLUMNS := 9
const FRAME_GAP := 1.0 / 10.0
const CROP := Vector2i(300, 520)
const OLD_GLASS_SKY := Color(0.64, 0.79, 0.93)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() > 0 else "jump"
	var label := args[1] if args.size() > 1 else "after"
	if mode == "glass":
		await glass()
	else:
		await stage_shots(mode, label)
	await process_frame
	quit()

func shot() -> Image:
	for i in 2: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func centre_crop(image: Image, size: Vector2i, offset := Vector2i.ZERO) -> Image:
	return image.get_region(Rect2i((image.get_size() - size) / 2 + offset, size))

func strip(rows: Array) -> Image:
	var width := 0
	var height := 0
	for row: Array in rows:
		var w := 0
		for image: Image in row:
			w += image.get_width()
		width = maxi(width, w)
		height += (row[0] as Image).get_height()
	var out := Image.create(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	var y := 0
	for row: Array in rows:
		var x := 0
		for image: Image in row:
			out.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x, y))
			x += image.get_width()
		y += (row[0] as Image).get_height()
	return out

# --- Jump and blink: a small stage with only the player scene -----------------------------------

func stage_shots(mode: String, label: String) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("bfe3f2")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	stage.add_child(sun)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(200, 1, 200)
	shape.position.y = -0.5
	ground.add_child(shape)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(200, 200)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("a9d384")
	floor_mesh.material_override = floor_material
	ground.add_child(floor_mesh)
	stage.add_child(ground)
	var player = load("res://scenes/player/bonbon_player.tscn").instantiate()
	stage.add_child(player)
	player.global_position = Vector3(0, 0.2, 0)
	for i in 40: await physics_frame
	var cam := Camera3D.new()
	cam.fov = 38
	root.add_child(cam)
	if mode == "blink":
		await blink(player, cam)
	else:
		await jump(player, cam, label)
	stage.queue_free()
	cam.queue_free()

func jump(player, cam: Camera3D, label: String) -> void:
	player.rotation.y = 0.0
	var side: Array[Image] = []
	var game_view: Array[Image] = []
	var steps := int(round(FRAME_GAP * Engine.physics_ticks_per_second))
	player.jump_queued = true
	var poses := []
	for column in COLUMNS:
		if column > 0:
			for i in steps: await physics_frame
		var at: Vector3 = player.global_position
		cam.global_position = Vector3(11.0, 2.4, at.z)
		cam.look_at(Vector3(0, 1.9, at.z), Vector3.UP)
		cam.current = true
		side.append(centre_crop(await shot(), CROP))
		player.camera.current = true
		game_view.append(centre_crop(await shot(), Vector2i(CROP.x, 360), Vector2i(0, 40)))
		poses.append("%.2f" % player.jump_pose)
	print("JUMP %s: jump_pose per frame %s" % [label, ", ".join(poses)])
	strip([side, game_view]).save_png("%s/jump-%s.png" % [OUT, label])

func blink(player, cam: Camera3D) -> void:
	player.set_physics_process(false)
	player.rotation.y = 0.0
	var bonbon: Node3D = player.get_node("Visual/BonBon")
	var life = player.blinker
	life.set_process(false)
	cam.global_position = player.global_position + Vector3(0, 1.6, -6.4)
	cam.look_at(player.global_position + Vector3(0, 1.25, 0), Vector3.UP)
	cam.current = true
	var whole: Array[Image] = []
	var faces: Array[Image] = []
	life.blink(bonbon)
	var times := [0.0, 0.02, 0.07, 0.13, 0.17]
	var now := 0.0
	var opens := []
	for t: float in times:
		life._process(t - now if t > now else 0.0)
		now = t
		var image := await shot()
		whole.append(centre_crop(image, Vector2i(400, 520)))
		var face := centre_crop(image, Vector2i(200, 110), Vector2i(0, -80))
		face.resize(400, 220, Image.INTERPOLATE_BILINEAR)
		faces.append(face)
		var eye: Node3D = bonbon.get_node("Head/LeftEye")
		opens.append("%.2f" % eye.scale.y)
	print("BLINK eye height at %s s: %s" % [str(times), ", ".join(opens)])
	strip([whole, faces]).save_png("%s/blink.png" % OUT)

# --- Glass at four hours, in the town -----------------------------------------------------------

func glass() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30: await process_frame
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	var cycle = game.day_night
	cycle.pause()
	var window: Node3D = null
	var best := 0.0
	for node in root.get_tree().get_nodes_in_group("glass_windows"):
		if int(node.outside) == 0 or not node.see_through or not node.is_visible_in_tree():
			continue
		var area: float = node.width * node.height
		if area > best:
			best = area
			window = node
	if window == null:
		push_error("no outdoors window found")
		return
	print("GLASS window %s (%.1f x %.1f m)" % [window.get_path(), window.width, window.height])
	var cam := Camera3D.new()
	cam.fov = 55
	root.add_child(cam)
	var normal: Vector3 = window.global_basis.z.normalized() * (1.0 if int(window.outside) == 1 else -1.0)
	var flat := Vector3(normal.x, 0, normal.z).normalized()
	var centre: Vector3 = window.global_position
	# Eye height (about 1.6 m above the ground) 11 m out, a little to one side.
	cam.global_position = centre + flat.rotated(Vector3.UP, 0.35) * 11.0 + Vector3(0, -0.5, 0)
	cam.look_at(centre, Vector3.UP)
	cam.current = true
	var rows: Array = []
	for hour: float in [7.0, 12.0, 18.67, 22.0]:
		cycle.set_time(hour * 60.0)
		for i in 4: await process_frame
		var sky: Color = cycle._glass_sky  # what day_night.gd last wrote
		RenderingServer.global_shader_parameter_set(&"glass_sky_colour", OLD_GLASS_SKY)
		var before := centre_crop(await shot(), Vector2i(900, 460))
		RenderingServer.global_shader_parameter_set(&"glass_sky_colour", sky)
		var after := centre_crop(await shot(), Vector2i(900, 460))
		print("GLASS %05.2f h reflected sky %s" % [hour, sky.to_html(false)])
		rows.append([before, after])
	strip(rows).save_png("%s/glass.png" % OUT)
	cam.queue_free()
	game.queue_free()
