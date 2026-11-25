extends SceneTree
## Face-only check of scenes/animals/sheep_clay.tscn against the blueprint (reference.png), for
## the head rebuild (user, 24 Nov 2026: "face first"). Rows: front 3/4, front, side. Columns:
## blueprint, model, model laid half-transparent over the blueprint (outline check). 3x scale.
## Loads only the sheep scene, so it writes no saves.
##   godot --path . --script res://docs/evidence/sheep-clay-20261124/face_check.gd
const OUT := "res://docs/evidence/sheep-clay-20261124/"
const BG := Color("fdf1e7")
const UNIT := 1.05 / 350.0
const GROUND := 527.0
const K := 3
const SIZE := Vector2i(210, 170)
## [sheet x under the model's origin, camera direction, sheet point at the middle of the crop]
const VIEWS := [[197.0, Vector3(-0.47, 0.04, -0.88), Vector2(170, 300)],
		[545.0, Vector3(0, 0.02, -1), Vector2(545, 300)],
		[952.0, Vector3(-1, 0.02, 0), Vector2(830, 300)]]

var cam: Camera3D

func shot() -> Image:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.always_on_top = true
	root.size = SIZE * K
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = BG
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	stage.add_child(load("res://scenes/animals/sheep_clay.tscn").instantiate())
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = SIZE.y * UNIT
	stage.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-40, -20, 0), 0.7], [Vector3(-5, 30, 0), 0.25]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(40): await process_frame
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	sheet.convert(Image.FORMAT_RGBA8)
	var cell := SIZE * K
	var sheet_out := Image.create(cell.x * 3, cell.y * VIEWS.size(), false, Image.FORMAT_RGBA8)
	for i in VIEWS.size():
		var x0: float = VIEWS[i][0]
		var d: Vector3 = (VIEWS[i][1] as Vector3).normalized()
		var mid: Vector2 = VIEWS[i][2]
		var right := Vector3.UP.cross(d).normalized()
		var target := right * (mid.x - x0) * UNIT + Vector3(0, (GROUND - mid.y) * UNIT, 0)
		cam.position = target + d * 14.0
		cam.look_at(target)
		var img: Image = await shot()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(cell.x, cell.y, Image.INTERPOLATE_LANCZOS)
		var crop := sheet.get_region(Rect2i(Vector2i(mid) - SIZE / 2, SIZE))
		crop.resize(cell.x, cell.y, Image.INTERPOLATE_CUBIC)
		var ghost := img.duplicate()
		var bytes: PackedByteArray = ghost.get_data()
		for j in range(3, bytes.size(), 4): bytes[j] = 120
		ghost = Image.create_from_data(cell.x, cell.y, false, Image.FORMAT_RGBA8, bytes)
		var over := crop.duplicate()
		over.blend_rect(ghost, Rect2i(Vector2i.ZERO, cell), Vector2i.ZERO)
		sheet_out.blit_rect(crop, Rect2i(Vector2i.ZERO, cell), Vector2i(0, i * cell.y))
		sheet_out.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(cell.x, i * cell.y))
		sheet_out.blit_rect(over, Rect2i(Vector2i.ZERO, cell), Vector2i(cell.x * 2, i * cell.y))
	sheet_out.save_png(OUT + "face_check.png")
	print("FACE CHECK saved")
	quit()
