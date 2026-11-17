extends SceneTree
## Studio views of scenes/animals/rooster_clay.tscn on a cream stage, laid out like the user's
## blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png, face and eye close-ups
## (face.png, eyes.png), compare.png (each blueprint view above the model's at the same scale)
## and face-compare.png (the sheet's heads above the model's).
## Loads only the rooster scene (not the town), so it writes no saves.
##   godot --path . --resolution 1200x800 --script res://docs/evidence/rooster-clay-20261116/capture.gd [-- zoo]
## With `-- zoo` it then loads the town (run with an isolated HOME, VT_FOCUS=all VT_SPAWN=none) and
## saves zoo-close.png, zoo-side.png and zoo-location.png of the placed display.
const OUT := "res://docs/evidence/rooster-clay-20261116/"
const W := 640
const H := 640
const PXM := 0.6 / 381.0   # the model is 0.6 tall; the sheet rooster is 381 px tall
const CUT := 420           # sheet px across one full view
const FACE_CUT := 190      # sheet px across one head view
const EYE_CUT := 80

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

## The sheet's cuts (each scaled to one W x H cell) above the model's views.
func pair_up(sheet: Image, cuts: Array, below: Image, file: String) -> void:
	var both := Image.create(W * cuts.size(), H * 2, false, Image.FORMAT_RGBA8)
	both.fill(Color("fbf3e9"))
	for i in cuts.size():
		var cut := sheet.get_region(cuts[i])
		cut.resize(W, H, Image.INTERPOLATE_LANCZOS)
		both.blit_rect(cut, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	both.blit_rect(below, Rect2i(0, 0, W * cuts.size(), H), Vector2i(0, H))
	both.save_png(OUT + file)

## Sheet rectangle of `size` px centred on (x, y).
func cut_at(x: int, y: int, size: int) -> Rect2i:
	return Rect2i(x - size / 2, y - size / 2, size, size)

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
	var rooster: Node3D = load("res://scenes/animals/rooster_clay.tscn").instantiate()
	stage.add_child(rooster)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	for i in range(60): await process_frame
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0, 0.12, 1), Vector3(0.7, 0.14, 0.7)]
	var close := [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)]
	# Whole bird: the view is centred on sheet (952, 345) of the side view.
	cam.size = CUT * PXM
	var turnaround: Image = await strip_of(cam, Vector3(0, (535 - 345) * PXM, (952 - 890) * PXM), views, "turnaround.png")
	# Head: centred on sheet (838, 262) of the side view.
	cam.size = FACE_CUT * PXM
	var face: Image = await strip_of(cam, Vector3(0, (535 - 262) * PXM, (838 - 890) * PXM), close, "face.png")
	cam.size = EYE_CUT * PXM
	var eyes: Image = await strip_of(cam, Vector3(0, (535 - 262) * PXM, (812 - 890) * PXM), close, "eyes.png")
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	if sheet != null:
		sheet.convert(Image.FORMAT_RGBA8)
		pair_up(sheet, [cut_at(233, 345, CUT), cut_at(533, 345, CUT), cut_at(952, 345, CUT), cut_at(1350, 345, CUT), cut_at(1737, 345, CUT)],
				turnaround, "compare.png")
		pair_up(sheet, [cut_at(152, 266, FACE_CUT), cut_at(533, 262, FACE_CUT), cut_at(838, 262, FACE_CUT)], face, "face-compare.png")
		pair_up(sheet, [cut_at(161, 268, EYE_CUT), cut_at(533, 262, EYE_CUT), cut_at(823, 262, EYE_CUT)], eyes, "eyes-compare.png")
	print("ROOSTER views saved")
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
	var placed: Node3D = game.apartment.get_node("ParkZoo/RoosterClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count(), ", scene file '", placed.scene_file_path, "'")
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.4, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-close", aim, facing * 1.9 - across * 1.4 + Vector3(0, 0.3, 0)],
			["zoo-side", aim, -across * 2.4 + Vector3(0, 0.2, 0)],
			["zoo-location", aim + Vector3(0, 0.8, 0), facing * 11.0 - across * 7.0 + Vector3(0, 6.0, 0)]]:
		town_cam.global_position = view[1] + view[2]
		town_cam.look_at(view[1])
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(0.5, 3, 0), placed.global_position + Vector3(0.5, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()
	quit()
