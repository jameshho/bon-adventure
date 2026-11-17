extends SceneTree
## Studio views of scenes/animals/tiger_clay.tscn against the user's sheet (reference.png).
## Loads only the tiger scene; nothing of the town. Orthographic, from the sheet's own angles and
## at the sheet's scale (the angles and offsets are fitted in study.gd, which also draws the
## outlines over each other).
##   compare.png  the sheet's five views (top) over the model from the same angles (bottom):
##                front 3/4, front, side, back, rear 3/4. The sheet's "side" view is turned 25
##                degrees toward the front, so the model is too.
##   face.png     the head in the front 3/4, front and side views: sheet left, model right.
##   eyes.png     the eyes in those three views, larger: sheet left, model right.
##   turnaround.png  the model alone: front 3/4, front, a true side view, back, rear 3/4, from above.
## Lamps ride on the camera, so every view is lit alike; frames are drawn on demand, so the
## capture does not hang when the window is covered. Run with an isolated HOME (README):
##   godot --path . --script res://docs/evidence/tiger-clay-20261116/capture.gd
const OUT := "res://docs/evidence/tiger-clay-20261116/"
const UNIT := 2.1 / 315.0       # town units per sheet pixel (tiger_clay.gd: TH / (TY - TTOP))
const BG := Color("fcefe6")
const BAND := Rect2i(0, 196, 2000, 336)   # the sheet's row of figures
# [yaw degrees, c, rect in the sheet, y shift]: screen x = L cos(yaw) + x sin(yaw) + c.
const BODY := [[29.0, -248.7, Rect2i(15, 196, 365, 336), 2.0], [0.0, 501.0, Rect2i(380, 196, 245, 336), 0.0],
		[65.0, 74.7, Rect2i(676, 196, 540, 336), 0.0], [180.0, 1350.0, Rect2i(1230, 196, 240, 336), 0.0],
		[-132.0, 2444.0, Rect2i(1500, 196, 480, 336), 2.0]]
const HEAD := [[29.0, -248.7, Rect2i(20, 200, 245, 195), 2.0], [0.0, 501.0, Rect2i(385, 200, 235, 195), 0.0],
		[65.0, 74.7, Rect2i(676, 196, 215, 195), 0.0]]
const EYES := [[29.0, -248.7, Rect2i(52, 285, 150, 42), 2.0], [0.0, 501.0, Rect2i(425, 283, 150, 42), 0.0],
		[65.0, 74.7, Rect2i(692, 281, 110, 42), 0.0]]

var port: SubViewport
var cam: Camera3D

func _initialize() -> void:
	run.call_deferred()

## Sheet pixel (true x toward the tail, y, l toward the animal's left) -> model space.
func at(x: float, y: float, l := 0.0) -> Vector3:
	return Vector3(-l, 523.0 - y, x - 945.0) * UNIT

## Renders `size` sheet pixels round `target` from direction `dir`, `ss` output pixels per sheet pixel.
func shoot(dir: Vector3, target: Vector3, size: Vector2i, ss: int) -> Image:
	port.size = size * ss
	cam.size = size.y * UNIT
	cam.position = target + dir.normalized() * 20.0
	cam.look_at(target, Vector3.UP if absf(dir.normalized().y) < 0.9 else Vector3(0, 0, -1))
	for i in 3: await process_frame
	for i in 3: RenderingServer.force_draw(false)
	var img := port.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img

## The model seen as the sheet shows the rectangle v[2].
func view(v: Array, ss: int) -> Image:
	var r: Rect2i = v[2]
	var yaw := deg_to_rad(v[0])
	var right := Vector3(-cos(yaw), 0, sin(yaw))
	var mid := Vector2(r.position) + Vector2(r.size) * 0.5
	var shift: float = mid.x - (795.0 * sin(yaw) + v[1])
	var target: Vector3 = at(795, mid.y - v[3]) + right * UNIT * shift
	return await shoot(Vector3(-sin(yaw), 0, -cos(yaw)), target, r.size, ss)

func run() -> void:
	port = SubViewport.new()
	port.own_world_3d = true
	port.msaa_3d = Viewport.MSAA_4X
	port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(port)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = BG
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.62
	port.add_child(env)
	var tiger: Node3D = load("res://scenes/animals/tiger_clay.tscn").instantiate()
	port.add_child(tiger)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	port.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-55, -22, 0), 0.85], [Vector3(-8, 30, 0), 0.2]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in 10: await process_frame

	var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	sheet.convert(Image.FORMAT_RGBA8)
	var compare := Image.create(BAND.size.x, BAND.size.y * 2, false, Image.FORMAT_RGBA8)
	compare.fill(BG)
	compare.blit_rect(sheet, BAND, Vector2i.ZERO)
	for v in BODY:
		var r: Rect2i = v[2]
		var img: Image = await view(v, 3)
		img.resize(r.size.x, r.size.y, Image.INTERPOLATE_LANCZOS)
		compare.blit_rect(img, Rect2i(Vector2i.ZERO, r.size), Vector2i(r.position.x, BAND.size.y))
	compare.save_png(OUT + "compare.png")

	for set in [[HEAD, 3, "face.png"], [EYES, 6, "eyes.png"]]:
		var k: int = set[1]
		var wide := 0
		var tall := 0
		for v in set[0]:
			wide += (v[2] as Rect2i).size.x * k * 2 + 16
			tall = maxi(tall, (v[2] as Rect2i).size.y * k)
		var board := Image.create(wide, tall, false, Image.FORMAT_RGBA8)
		board.fill(Color.WHITE)
		var x0 := 0
		for v in set[0]:
			var r: Rect2i = v[2]
			var crop := sheet.get_region(r)
			crop.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_CUBIC)
			board.blit_rect(crop, Rect2i(Vector2i.ZERO, r.size * k), Vector2i(x0, 0))
			var img: Image = await view(v, k)
			board.blit_rect(img, Rect2i(Vector2i.ZERO, r.size * k), Vector2i(x0 + r.size.x * k, 0))
			x0 += r.size.x * k * 2 + 16
		board.save_png(OUT + set[2])

	# The model alone: front 3/4, front, true side, back, rear 3/4, from above.
	var cell := Vector2i(560, 350)
	var turn := Image.create(cell.x * 6, cell.y, false, Image.FORMAT_RGBA8)
	turn.fill(BG)
	var centre := at(955, 366)
	var dirs := [Vector3(-0.485, 0.03, -0.875), Vector3(0, 0.03, -1), Vector3(-1, 0.03, 0), Vector3(0, 0.03, 1), Vector3(0.743, 0.03, 0.669), Vector3(-0.001, 1, 0)]
	for i in dirs.size():
		var img: Image = await shoot(dirs[i], centre, cell if i < 5 else Vector2i(560, 580), 2)
		img.resize(cell.x, img.get_height() * cell.x / img.get_width(), Image.INTERPOLATE_LANCZOS)
		turn.blit_rect(img, Rect2i(0, (img.get_height() - cell.y) / 2, cell.x, cell.y), Vector2i(i * cell.x, 0))
	turn.save_png(OUT + "turnaround.png")
	print("TIGER CAPTURE saved")
	quit()
