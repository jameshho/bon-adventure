extends SceneTree
## Studio views of scenes/animals/monkey_clay.tscn on a cream stage. Loads only that scene.
##   compare.png   the blueprint's front 3/4, front, side, back and rear 3/4 views (top row,
##                 cut from reference.png) above the model in the same views at the same
##                 scale (orthographic, so the blueprint's perspective differs a little)
##   overlay.png   the model laid half-transparent over the blueprint in those views
##   face.png      the blueprint's head (top) above the model's: front 3/4, front, side
##   eyes.png      the blueprint's eyes (top) above the model's, 8x: front 3/4, front, side
##   turnaround.png  the five views alone
##   zoo-*.png     with `-- zoo`: the monkey's place in the town (see zoo_views)
## Run with an isolated HOME (README) and a time limit: it can hang when the window is not drawn.
##   godot --path . --resolution 760x560 --script res://docs/evidence/monkey-clay-20261117/capture.gd
const OUT := "res://docs/evidence/monkey-clay-20261117/"
const UNIT := 0.85 / 363.0    # town units per sheet pixel (monkey_clay.gd: M_HEIGHT / (M_GY - M_TOP))
const GROUND := 537.0         # sheet y of the soles
const ORIGIN_X := 900.0       # sheet x (side view) at the model origin
const BG := Color("fdf1e7")
const SIDE_TURN := 0.12       # the side view, turned this much toward the front (x of the camera direction)

## [blueprint rect, camera direction from the model, model point under the rect's middle
## (sheet x of the side view, sheet y, lateral z), screen shift in sheet px]
const VIEWS := [
	[Rect2i(30, 150, 330, 400), Vector3(-0.5, 0.05, -0.87), Vector3(905, 350, 0), Vector2(10, 0)],
	[Rect2i(377, 150, 290, 400), Vector3(0, 0.02, -1), Vector3(905, 350, 0), Vector2.ZERO],
	[Rect2i(720, 150, 400, 400), Vector3(-1, 0.03, -SIDE_TURN), Vector3(920, 350, 0), Vector2.ZERO],
	[Rect2i(1190, 150, 300, 400), Vector3(0, 0.03, 1), Vector3(905, 350, 0), Vector2.ZERO],
	[Rect2i(1590, 150, 350, 400), Vector3(0.88, 0.05, 0.47), Vector3(905, 350, 0), Vector2(-12, 0)]]

var cam: Camera3D

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img

static func model(p: Vector3) -> Vector3:
	return Vector3(-p.z, GROUND - p.y, p.x - ORIGIN_X) * UNIT

## The model seen from `dir`, `at` (sheet point) under the middle, shifted `shift` sheet px on
## the screen, `size` sheet px, drawn `zoom` times larger.
func view(dir: Vector3, at: Vector3, shift: Vector2, size: Vector2i, zoom: int) -> Image:
	root.size = size * zoom
	cam.size = size.y * UNIT
	var d := dir.normalized()
	cam.position = model(at) + d * 14.0
	cam.look_at(model(at))
	cam.position -= (cam.global_transform.basis.x * shift.x - cam.global_transform.basis.y * shift.y) * UNIT
	var img: Image = await shot()
	if img.get_size() != size * zoom:
		img.resize(size.x * zoom, size.y * zoom, Image.INTERPOLATE_LANCZOS)
	return img

func ghost(img: Image) -> Image:
	var bytes := img.get_data()
	for i in range(3, bytes.size(), 4): bytes[i] = 128
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, bytes)

## Blueprint (top) and model (bottom) pairs: [blueprint rect, camera direction, model point, shift].
func pairs(sheet: Image, list: Array, zoom: int, file: String) -> void:
	var w := 0
	var h := 0
	for v in list:
		w += (v[0] as Rect2i).size.x * zoom
		h = maxi(h, (v[0] as Rect2i).size.y * zoom)
	var out := Image.create(w, h * 2, false, Image.FORMAT_RGBA8)
	out.fill(BG)
	var at := 0
	for v in list:
		var r: Rect2i = v[0]
		var crop := sheet.get_region(r)
		crop.resize(r.size.x * zoom, r.size.y * zoom, Image.INTERPOLATE_CUBIC)
		out.blit_rect(crop, Rect2i(Vector2i.ZERO, r.size * zoom), Vector2i(at, 0))
		var img: Image = await view(v[1], v[2], v[3], r.size, zoom)
		out.blit_rect(img, Rect2i(Vector2i.ZERO, r.size * zoom), Vector2i(at, h))
		at += r.size.x * zoom
	out.save_png(OUT + file)

## Views of the monkey's saved place in the town (zoo-close.png, zoo-front.png,
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
	var placed: Node3D = game.apartment.get_node("ParkZoo/MonkeyClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.45, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for v in [["zoo-location", facing * 13.0 - across * 8.0 + Vector3(0, 8.0, 0)], ["zoo-close", facing * 2.2 - across * 1.4 + Vector3(0, 0.5, 0)],
			["zoo-front", facing * 3.6 + Vector3(0, 0.3, 0)],
			["zoo-location", facing * 13.0 - across * 8.0 + Vector3(0, 8.0, 0)]]:
		town_cam.global_position = aim + v[1]
		town_cam.look_at(aim)
		var img: Image = await shot()
		img.save_png(OUT + v[0] + ".png")
	# The ground under and round the display (its own footprint box left out of the rays).
	var skip: Array[RID] = []
	for body in placed.find_children("*", "CollisionObject3D", true, false): skip.append((body as CollisionObject3D).get_rid())
	for off in [Vector3.ZERO, Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0), Vector3(0, 0, 0.5), Vector3(0, 0, -0.5), Vector3(1.2, 0, 0)]:
		var probe := PhysicsRayQueryParameters3D.create(placed.global_position + off + Vector3(0, 3, 0), placed.global_position + off + Vector3(0, -3, 0))
		probe.exclude = skip
		var got := placed.get_world_3d().direct_space_state.intersect_ray(probe)
		print("GROUND at offset ", off, ": ", got.get("position", "none"), " ", got.get("collider", null))
	var ray := PhysicsRayQueryParameters3D.create(placed.global_position + Vector3(1.2, 3, 0), placed.global_position + Vector3(1.2, -3, 0))
	var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
	var lowest := INF
	for mi in placed.find_children("*", "MeshInstance3D", true, false):
		lowest = minf(lowest, ((mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()).position.y)
	print("GROUND beside display: ", hit.get("position", "none"), " display y ", placed.global_position.y, " lowest mesh y ", lowest)
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
	stage.add_child(load("res://scenes/animals/monkey_clay.tscn").instantiate())
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
	var hh := 400 * 2
	var compare := Image.create(total, hh * 2, false, Image.FORMAT_RGBA8)
	var over := Image.create(total, hh, false, Image.FORMAT_RGBA8)
	var turn := Image.create(total, hh, false, Image.FORMAT_RGBA8)
	var at := 0
	for v in VIEWS:
		var r: Rect2i = v[0]
		var img: Image = await view(v[1], v[2], v[3], r.size, 2)
		var crop := sheet.get_region(r)
		crop.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_CUBIC)
		var box := Rect2i(Vector2i.ZERO, r.size * 2)
		compare.blit_rect(crop, box, Vector2i(at, 0))
		compare.blit_rect(img, box, Vector2i(at, hh))
		turn.blit_rect(img, box, Vector2i(at, 0))
		over.blit_rect(crop, box, Vector2i(at, 0))
		over.blend_rect(ghost(img), box, Vector2i(at, 0))
		at += r.size.x * 2
	compare.save_png(OUT + "compare.png")
	over.save_png(OUT + "overlay.png")
	turn.save_png(OUT + "turnaround.png")

	# Face: the head at 3x, blueprint above model. The head's middle: sheet (880, 292).
	await pairs(sheet, [
		[Rect2i(40, 165, 290, 240), VIEWS[0][1], Vector3(880, 285, 0), Vector2(-12, 0)],
		[Rect2i(377, 165, 290, 240), VIEWS[1][1], Vector3(880, 285, 0), Vector2.ZERO],
		[Rect2i(720, 165, 290, 240), VIEWS[2][1], Vector3(865, 285, 0), Vector2.ZERO]], 3, "face.png")
	# Eyes, 8x: the monkey's left eye in the 3/4 and side views, its right eye in the front view.
	await pairs(sheet, [
		[Rect2i(134, 266, 72, 60), VIEWS[0][1], Vector3(790, 296, 42), Vector2.ZERO],
		[Rect2i(442, 266, 72, 60), VIEWS[1][1], Vector3(790, 296, -42), Vector2.ZERO],
		[Rect2i(765, 262, 72, 60), VIEWS[2][1], Vector3(790, 292, 42), Vector2.ZERO]], 8, "eyes.png")
	print("MONKEY views saved")
	quit()
