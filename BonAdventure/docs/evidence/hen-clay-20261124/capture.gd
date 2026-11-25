extends SceneTree
## Studio views of scenes/animals/hen_clay.tscn on a cream stage, beside the user's blueprint
## (reference.png; views: front 3/4, front, side, back, rear 3/4). Loads only the hen scene
## (not the town), so it writes no saves. Adapted from the clay chick's capture.
##   compare.png     each blueprint view (top) above the model's at the same scale (bottom)
##   overlay.png     the model laid half-transparent over each blueprint view (silhouettes)
##   face.png        close-up of the face and eyes: blueprint (top) and model (bottom) in the
##                   front 3/4, front and side views, four times larger
##   details.png     comb (front, side), wing, tail (side, back) and feet: blueprint (top), model (bottom)
##   turnaround.png  the model alone in the five views
## The camera is orthographic; the blueprint has a little perspective. The lamps ride on the
## camera, so every view is lit alike. Give every run a time limit: it can hang when the window
## is not drawn.
## With `-- zoo` it then loads the town (run with an isolated HOME, VT_FOCUS=all VT_SPAWN=none) and
## saves zoo-close.png, zoo-front.png (the hen with the clay chick and rooster), zoo-side.png and
## zoo-location.png of the placed display.
##   godot --path . --script res://docs/evidence/hen-clay-20261124/capture.gd [-- zoo]
const OUT := "res://docs/evidence/hen-clay-20261124/"
const BG := Color("fdf0e9")
const TALL := 0.5          # the model's height (hen_clay.gd NH); the sheet hen is 361 px tall
const UNIT := TALL / 361.0 # town units per sheet pixel
const GROUND := 536.0      # sheet y of the soles
## Views: [sheet x under the model's origin, camera direction (from the model toward the camera)].
const VIEWS := [[195.0, Vector3(-0.53, 0.04, -0.85)], [522.0, Vector3(0, 0.02, -1)], [900.0, Vector3(-1, 0.02, 0)],
		[1335.0, Vector3(0, 0.02, 1)], [1745.0, Vector3(0.96, 0.03, 0.27)]]

var cam: Camera3D

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

## The model seen along `dir` with sheet point `mid` (in a view whose origin is at sheet x
## `x0`) at the middle of a picture `size` sheet px, drawn `k` times larger.
func view(x0: float, dir: Vector3, mid: Vector2, size: Vector2i, k: int) -> Image:
	root.size = size * k
	cam.size = size.y * UNIT
	var d := dir.normalized()
	var right := Vector3.UP.cross(d).normalized()
	var target := right * (mid.x - x0) * UNIT + Vector3(0, (GROUND - mid.y) * UNIT, 0)
	cam.position = target + d * 14.0
	cam.look_at(target)
	cam.position = target + d * 14.0
	var img: Image = await shot()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(size.x * k, size.y * k, Image.INTERPOLATE_LANCZOS)
	return img

func ghost(img: Image) -> Image:
	var bytes := img.get_data()
	for i in range(3, bytes.size(), 4): bytes[i] = 128
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, bytes)

func run() -> void:
	root.always_on_top = true      # a covered window is not drawn on macOS, and the capture stalls
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
	var hen: Node3D = load("res://scenes/animals/hen_clay.tscn").instantiate()
	stage.add_child(hen)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	for lamp in [[Vector3(-40, -20, 0), 0.7], [Vector3(-5, 30, 0), 0.25]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(60): await process_frame
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	sheet.convert(Image.FORMAT_RGBA8)

	# Whole body: 390 x 400 sheet px round each view, drawn 2x.
	var size := Vector2i(390, 400)
	var k := 2
	var cell := size * k
	var compare := Image.create(cell.x * VIEWS.size(), cell.y * 2, false, Image.FORMAT_RGBA8)
	var overlay := Image.create(cell.x * VIEWS.size(), cell.y, false, Image.FORMAT_RGBA8)
	var turn := Image.create(cell.x * VIEWS.size(), cell.y, false, Image.FORMAT_RGBA8)
	compare.fill(BG)
	for i in VIEWS.size():
		var x0: float = VIEWS[i][0]
		var mid := Vector2(clampf(x0, size.x * 0.5, sheet.get_width() - size.x * 0.5), 355)
		var img: Image = await view(x0, VIEWS[i][1], mid, size, k)
		var crop := sheet.get_region(Rect2i(Vector2i(mid) - size / 2, size))
		crop.resize(cell.x, cell.y, Image.INTERPOLATE_CUBIC)
		compare.blit_rect(crop, Rect2i(Vector2i.ZERO, cell), Vector2i(i * cell.x, 0))
		compare.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(i * cell.x, cell.y))
		turn.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(i * cell.x, 0))
		overlay.blit_rect(crop, Rect2i(Vector2i.ZERO, cell), Vector2i(i * cell.x, 0))
		overlay.blend_rect(ghost(img), Rect2i(Vector2i.ZERO, cell), Vector2i(i * cell.x, 0))
	compare.save_png(OUT + "compare.png")
	overlay.save_png(OUT + "overlay.png")
	turn.save_png(OUT + "turnaround.png")

	# Face and eyes: 190 x 130 sheet px round the face in the first three views, drawn 4x.
	var fsize := Vector2i(190, 130)
	var fk := 4
	var fcell := fsize * fk
	var faces := [[0, Vector2(120, 292)], [1, Vector2(522, 296)], [2, Vector2(808, 292)]]
	var face := Image.create(fcell.x * faces.size(), fcell.y * 2, false, Image.FORMAT_RGBA8)
	for i in faces.size():
		var v: Array = VIEWS[faces[i][0]]
		var mid: Vector2 = faces[i][1]
		var img: Image = await view(v[0], v[1], mid, fsize, fk)
		var crop := sheet.get_region(Rect2i(Vector2i(mid) - fsize / 2, fsize))
		crop.resize(fcell.x, fcell.y, Image.INTERPOLATE_CUBIC)
		face.blit_rect(crop, Rect2i(Vector2i.ZERO, fcell), Vector2i(i * fcell.x, 0))
		face.blit_rect(img, Rect2i(Vector2i.ZERO, fcell), Vector2i(i * fcell.x, fcell.y))
	face.save_png(OUT + "face.png")
	# Details, blueprint (top) above model (bottom), four times larger: comb from the front
	# and the side, wing and tail from the side, tail from the back, feet from the front.
	var dsize := Vector2i(170, 120)
	var dcell := dsize * 4
	var parts := [[1, Vector2(522, 215)], [2, Vector2(855, 215)], [2, Vector2(935, 420)], [2, Vector2(1050, 380)], [3, Vector2(1335, 385)], [1, Vector2(522, 505)]]
	var details := Image.create(dcell.x * parts.size(), dcell.y * 2, false, Image.FORMAT_RGBA8)
	for i in parts.size():
		var v: Array = VIEWS[parts[i][0]]
		var mid: Vector2 = parts[i][1]
		var img: Image = await view(v[0], v[1], mid, dsize, 4)
		var crop := sheet.get_region(Rect2i(Vector2i(mid) - dsize / 2, dsize))
		crop.resize(dcell.x, dcell.y, Image.INTERPOLATE_CUBIC)
		details.blit_rect(crop, Rect2i(Vector2i.ZERO, dcell), Vector2i(i * dcell.x, 0))
		details.blit_rect(img, Rect2i(Vector2i.ZERO, dcell), Vector2i(i * dcell.x, dcell.y))
	details.save_png(OUT + "details.png")
	print("HEN CAPTURE saved")
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
	var placed: Node3D = game.apartment.get_node("ParkZoo/HenClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count(), ", scene file '", placed.scene_file_path, "'")
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.3, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-close", aim, facing * 1.5 - across * 1.0 + Vector3(0, 0.25, 0)],
			["zoo-front", aim - across * 0.8 + Vector3(0, 0.1, 0), facing * 2.6 + Vector3(0, 0.3, 0)],
			["zoo-side", aim, -across * 2.0 + Vector3(0, 0.15, 0)],
			["zoo-location", aim + Vector3(0, 0.8, 0), facing * 11.0 - across * 7.0 + Vector3(0, 6.0, 0)]]:
		town_cam.global_position = view[1] + view[2]
		town_cam.look_at(view[1])
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(0.4, 3, 0), placed.global_position + Vector3(0.4, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()
	quit()
