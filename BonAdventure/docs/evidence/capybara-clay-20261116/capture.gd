extends SceneTree
## Studio views of scenes/animals/capybara_clay.tscn on a cream stage. Loads only that scene.
##   compare.png   the blueprint's front 3/4, front, side, back and rear 3/4 views (top row,
##                 cut from reference.png) above the model in the same views at the same
##                 scale (orthographic, so the blueprint's perspective differs a little; the
##                 side view is turned 20 degrees toward the front, like the blueprint's)
##   overlay.png   the model laid half-transparent over the blueprint in those views
##   face.png      the head from the front 3/4, the front and the side
##   eyes.png      the eyes cut from the blueprint (top) and the model (bottom): front 3/4,
##                 front, side
##   turnaround.png  the five views alone
## Run with an isolated HOME (README) and a time limit: it can hang when the window is not drawn.
##   godot --path . --resolution 760x560 --script res://docs/evidence/capybara-clay-20261116/capture.gd
const OUT := "res://docs/evidence/capybara-clay-20261116/"
const UNIT := 0.95 / 287.0    # town units per sheet pixel (capybara_clay.gd: BH / (BGY - BTOP))
const GROUND := 522.0         # sheet y of the soles
const ORIGIN_X := 960.0       # sheet x at the model origin (side view)
const BG := Color("fdf1e7")

## [blueprint rect, camera direction from the model, sheet x (side view) under the middle]
const VIEWS := [
	[Rect2i(20, 195, 360, 345), Vector3(-0.7, 0.05, -0.7), 921.0],
	[Rect2i(381, 195, 290, 345), Vector3(0, 0.02, -1), 960.0],
	[Rect2i(695, 195, 450, 345), Vector3(-1, 0.03, -0.36), 920.0],
	[Rect2i(1192, 195, 290, 345), Vector3(0, 0.03, 1), 960.0],
	[Rect2i(1521, 195, 450, 345), Vector3(0.86, 0.05, 0.5), 921.0]]

var cam: Camera3D

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img

## The model in a view whose middle is sheet point (x in the side view, y), `size` sheet px, drawn `zoom` times larger.
func view(dir: Vector3, mid_x: float, mid_y: float, size: Vector2i, zoom: int, lateral := 0.0) -> Image:
	# `lateral`: sheet px the aim point lies toward the animal's left (the side the side view shows).
	root.size = size * zoom
	cam.size = size.y * UNIT
	var target := Vector3(0, (GROUND - mid_y) * UNIT, (mid_x - ORIGIN_X) * UNIT)
	var d := dir.normalized()
	target.x -= lateral * UNIT
	cam.position = target + d * 14.0
	cam.look_at(target)
	var img: Image = await shot()
	if img.get_size() != size * zoom:
		img.resize(size.x * zoom, size.y * zoom, Image.INTERPOLATE_LANCZOS)
	return img

func ghost(img: Image) -> Image:
	var bytes := img.get_data()
	for i in range(3, bytes.size(), 4): bytes[i] = 128
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, bytes)

## Views of the capybara's saved place in the town (zoo-close.png, zoo-front.png, zoo-side.png,
## zoo-location.png), with `-- zoo`: run with an isolated HOME, VT_FOCUS=all VT_SPAWN=none.
func zoo_views() -> void:
	root.size = Vector2i(1200, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	game.player.set_process(false)
	game.interaction.set_physics_process(false)
	game.player.get_node("Visual").hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var placed: Node3D = game.apartment.get_node("ParkZoo/CapybaraClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.5, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for v in [["zoo-location", facing * 13.0 - across * 8.0 + Vector3(0, 8.0, 0)], ["zoo-close", facing * 2.4 + across * 2.6 + Vector3(0, 0.8, 0)],
			["zoo-front", facing * 4.2 + Vector3(0, 0.3, 0)], ["zoo-side", -across * 4.6 + Vector3(0, 0.3, 0)],
			["zoo-location", facing * 13.0 - across * 8.0 + Vector3(0, 8.0, 0)]]:
		town_cam.global_position = aim + v[1]
		town_cam.look_at(aim)
		var img: Image = await shot()
		img.save_png(OUT + v[0] + ".png")
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(1.6, 3, 0), placed.global_position + Vector3(1.6, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y)
	game.free()

func run() -> void:
	if OS.get_cmdline_user_args().has("zoo"):
		await zoo_views()
		quit()
		return
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
	stage.add_child(load("res://scenes/animals/capybara_clay.tscn").instantiate())
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(cam)
	cam.current = true
	# Even, soft studio light, as for the other clay animals: the lamps ride on the camera.
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(90): await process_frame
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	sheet.convert(Image.FORMAT_RGBA8)

	var total := 0
	for v in VIEWS: total += (v[0] as Rect2i).size.x * 2
	var compare := Image.create(total, 345 * 4, false, Image.FORMAT_RGBA8)
	var over := Image.create(total, 345 * 2, false, Image.FORMAT_RGBA8)
	var turn := Image.create(total, 345 * 2, false, Image.FORMAT_RGBA8)
	var at := 0
	for v in VIEWS:
		var r: Rect2i = v[0]
		var img: Image = await view(v[1], v[2], r.position.y + r.size.y * 0.5, r.size, 2)
		var crop := sheet.get_region(r)
		crop.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_CUBIC)
		var box := Rect2i(Vector2i.ZERO, r.size * 2)
		compare.blit_rect(crop, box, Vector2i(at, 0))
		compare.blit_rect(img, box, Vector2i(at, 345 * 2))
		turn.blit_rect(img, box, Vector2i(at, 0))
		over.blit_rect(crop, box, Vector2i(at, 0))
		over.blend_rect(ghost(img), box, Vector2i(at, 0))
		at += r.size.x * 2
	compare.save_png(OUT + "compare.png")
	over.save_png(OUT + "overlay.png")
	turn.save_png(OUT + "turnaround.png")

	# Face: the head, 4 times the sheet's size. [camera direction, sheet x under the middle, lateral shift]
	var hs := Vector2i(280, 230)
	var faces := [[Vector3(-0.7, 0.05, -0.7), 840.0], [Vector3(0, 0.02, -1), 840.0], [Vector3(-1, 0.03, -0.36), 835.0]]
	var face := Image.create(hs.x * 4 * 3, hs.y * 4, false, Image.FORMAT_RGBA8)
	for i in faces.size():
		var img: Image = await view(faces[i][0], faces[i][1], 318.0, hs, 4)
		face.blit_rect(img, Rect2i(Vector2i.ZERO, hs * 4), Vector2i(i * hs.x * 4, 0))
	face.save_png(OUT + "face.png")

	# Eyes: blueprint (top) and model (bottom), 8 times the sheet's size.
	# [blueprint rect corner, camera direction, sheet x and lateral offset of the aim point]
	var es := Vector2i(90, 60)
	var eyes := [[Vector2i(150, 278), Vector3(-0.7, 0.05, -0.7), 852.0, 76.0], [Vector2i(420, 278), Vector3(0, 0.02, -1), 852.0, -61.0],
			[Vector2i(808, 278), Vector3(-1, 0.03, -0.36), 852.0, 76.0]]
	var eye_img := Image.create(es.x * 8 * 3, es.y * 8 * 2, false, Image.FORMAT_RGBA8)
	for i in eyes.size():
		var crop := sheet.get_region(Rect2i(eyes[i][0], es))
		crop.resize(es.x * 8, es.y * 8, Image.INTERPOLATE_CUBIC)
		eye_img.blit_rect(crop, Rect2i(Vector2i.ZERO, es * 8), Vector2i(i * es.x * 8, 0))
		var img: Image = await view(eyes[i][1], eyes[i][2], 308.0, es, 8, eyes[i][3])
		eye_img.blit_rect(img, Rect2i(Vector2i.ZERO, es * 8), Vector2i(i * es.x * 8, es.y * 8))
	eye_img.save_png(OUT + "eyes.png")
	print("CAPYBARA views saved")
	quit()
