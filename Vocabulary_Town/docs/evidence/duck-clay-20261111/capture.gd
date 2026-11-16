extends SceneTree
## Studio views of scenes/animals/duck_clay.tscn on a cream stage, laid out like the user's
## blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png, face and eye close-ups
## (face.png, eyes.png), compare.png (each blueprint view above the model's at the same scale)
## and face-compare.png (the sheet's heads above the model's).
## Loads only the duck scene (not the town), so it writes no saves.
##   godot --path . --resolution 1200x800 --script res://docs/evidence/duck-clay-20261111/capture.gd [-- zoo]
const OUT := "res://docs/evidence/duck-clay-20261111/"
const W := 600
const H := 760
const TALL := 0.45         # the model's height; the sheet duck is 369 px tall
const PX := 369.0
const VIEW := 0.58         # camera height in town units
const FACE := 0.3

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func strip_of(cam: Camera3D, target: Vector3, views: Array, file: String) -> Image:
	var strip := Image.create(W * views.size(), H, false, Image.FORMAT_RGBA8)
	for i in views.size():
		cam.position = target + (views[i] as Vector3).normalized() * 14.0
		cam.look_at(target)
		var img: Image = await shot()
		img.convert(Image.FORMAT_RGBA8)
		strip.blit_rect(img, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(OUT + file)
	return strip

func pair_up(sheet: Image, cuts: Array, k: float, below: Image, file: String) -> void:
	var top := int(cuts[0].size.y * k)
	var both := Image.create(W * cuts.size(), top + H, false, Image.FORMAT_RGBA8)
	both.fill(Color("fbf3e9"))
	for i in cuts.size():
		var cut := sheet.get_region(cuts[i])
		cut.resize(int(cut.get_width() * k), top, Image.INTERPOLATE_LANCZOS)
		both.blit_rect(cut, Rect2i(0, 0, mini(cut.get_width(), W), top), Vector2i(i * W + maxi((W - cut.get_width()) / 2, 0), 0))
	both.blit_rect(below, Rect2i(0, 0, W * cuts.size(), H), Vector2i(0, top))
	both.save_png(OUT + file)

func run() -> void:
	root.size = Vector2i(W, H)
	root.always_on_top = true      # a covered window is not drawn on macOS, and the capture stalls
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("fbf3e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.8
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -150, 0)
	sun.light_energy = 0.3
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()      # soft light from behind, so the back views read
	fill.rotation_degrees = Vector3(-35, 40, 0)
	fill.light_energy = 0.16
	stage.add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(60, 60)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fbf3e9")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	var duck: Node3D = load("res://scenes/animals/duck_clay.tscn").instantiate()
	stage.add_child(duck)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = VIEW
	stage.add_child(cam)
	cam.current = true
	for i in range(60): await process_frame
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0, 0.12, 1), Vector3(0.7, 0.14, 0.7)]
	var close := [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)]
	var turnaround: Image = await strip_of(cam, Vector3(0, 0.235, -0.02), views, "turnaround.png")
	cam.size = FACE
	var face: Image = await strip_of(cam, Vector3(0, 0.335, -0.107), close, "face.png")
	cam.size = 0.13
	await strip_of(cam, Vector3(0, 0.35, -0.12), close, "eyes.png")
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	if sheet != null:
		sheet.convert(Image.FORMAT_RGBA8)
		await pair_up(sheet, [Rect2i(25, 150, 370, 420), Rect2i(352, 150, 370, 420), Rect2i(765, 150, 370, 420), Rect2i(1187, 150, 370, 420), Rect2i(1595, 150, 370, 420)],
				TALL / PX * (H / VIEW), turnaround, "compare.png")
		await pair_up(sheet, [Rect2i(65, 165, 190, 190), Rect2i(442, 165, 190, 190), Rect2i(772, 165, 190, 190)],
				TALL / PX * (H / FACE), face, "face-compare.png")
	print("DUCK views saved")
	stage.free()
	if not OS.get_cmdline_user_args().has("zoo"):
		quit()
		return
	# With `-- zoo` (isolated HOME, VT_FOCUS=all VT_SPAWN=none): its saved place in the town.
	root.size = Vector2i(1200, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var placed: Node3D = game.apartment.get_node("ParkZoo/DuckClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.3, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-close", aim, facing * 1.5 - across * 1.1 + Vector3(0, 0.25, 0)],
			["zoo-side", aim, -across * 1.9 + Vector3(0, 0.15, 0)],
			["zoo-location", aim + Vector3(0, 0.6, 0), facing * 9.0 - across * 6.0 + Vector3(0, 5.0, 0)]]:
		town_cam.global_position = view[1] + view[2]
		town_cam.look_at(view[1])
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(0.5, 3, 0), placed.global_position + Vector3(0.5, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()
	quit()
