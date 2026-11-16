extends SceneTree
## Turnaround of scenes/animals/pig_clay.tscn on a cream stage, laid out like the user's
## blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png, face and eye close-ups
## (face.png, eyes.png), compare.png: the blueprint (reference.png) above the turnaround, and
## pairs.png: the blueprint's front 3/4, front, side, back and rear 3/4 views each beside the model at the same
## scale (orthographic, so the blueprint's perspective differs a little; the side pair is turned
## 13 degrees toward the front, like the blueprint's side view; body-overlay.png lays the model
## half-transparent over the blueprint in those views), and head-pairs.png: the same
## three views of the head alone, larger; eye-pairs.png cuts the eyes from them (blueprint left,
## model right; rows: front 3/4, front, side); head-overlay.png lays the model half-transparent over
## the blueprint in those views. The 3/4 cameras are level (they looked down 6 degrees until the
## third pass, which made the face look low). Loads only the pig scene, unless `zoo` is given.
## With `zoo` it instead loads the town and saves views of the pig's saved place (zoo-close.png,
## zoo-front.png, zoo-side.png, zoo-location.png). Run with an isolated HOME (README), and for
## `zoo` VT_FOCUS=all VT_SPAWN=none. Give every run a time limit: it can hang when the window is not drawn.
##   godot --path . --resolution 760x560 --script res://docs/evidence/pig-clay-20261111/capture.gd [-- zoo]
const OUT := "res://docs/evidence/pig-clay-20261111/"
const W := 760
const H := 560

func _initialize() -> void:
	run.call_deferred()

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func strip_of(cam: Camera3D, target: Vector3, views: Array, file: String) -> Image:
	var strip := Image.create(W * views.size(), H, false, Image.FORMAT_RGBA8)
	for i in views.size():
		cam.position = target + (views[i] as Vector3).normalized() * 14.0
		cam.look_at(target)
		var img: Image = await shot()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(W, H, Image.INTERPOLATE_LANCZOS)
		strip.blit_rect(img, Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(OUT + file)
	return strip

## Views of the pig's saved place in the town (zoo-close.png, zoo-front.png, zoo-side.png, zoo-location.png).
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
	var placed: Node3D = game.apartment.get_node("ParkZoo/PigClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 0.5, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-location", facing * 13.0 - across * 8.0 + Vector3(0, 8.0, 0)], ["zoo-close", facing * 2.4 + across * 2.6 + Vector3(0, 0.8, 0)], ["zoo-front", facing * 4.2 + Vector3(0, 0.3, 0)],
			["zoo-side", -across * 4.6 + Vector3(0, 0.3, 0)], ["zoo-location", facing * 13.0 - across * 8.0 + Vector3(0, 8.0, 0)]]:
		town_cam.global_position = aim + view[1]
		town_cam.look_at(aim)
		var img: Image = await shot()
		img.save_png(OUT + view[0] + ".png")
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
	env.environment.background_color = Color("fdf0e9")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e6")
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var pig: Node3D = load("res://scenes/animals/pig_clay.tscn").instantiate()
	stage.add_child(pig)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.36
	stage.add_child(cam)
	cam.current = true
	# Even, soft studio light (user, 11 Nov 2026): the lamps ride on the camera, so every view
	# is lit the same: a gentle key from above and a little left, a faint fill from the right, no shadows.
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(90): await process_frame   # the first views came out blank with a shorter wait
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0, 0.12, 1), Vector3(0.7, 0.14, 0.7)]
	var turn: Image = await strip_of(cam, Vector3(0, 0.47, 0), views, "turnaround.png")
	cam.size = 0.72
	await strip_of(cam, Vector3(0, 0.6, -0.5), [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)], "face.png")
	cam.size = 0.34
	await strip_of(cam, Vector3(0, 0.655, -0.55), [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)], "eyes.png")
	var ref := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
	if ref != null:
		ref.convert(Image.FORMAT_RGBA8)
		var rh := int(round(ref.get_height() * float(turn.get_width()) / ref.get_width()))
		ref.resize(turn.get_width(), rh, Image.INTERPOLATE_LANCZOS)
		var both := Image.create(turn.get_width(), rh + H, false, Image.FORMAT_RGBA8)
		both.blit_rect(ref, Rect2i(0, 0, turn.get_width(), rh), Vector2i.ZERO)
		both.blit_rect(turn, Rect2i(0, 0, turn.get_width(), H), Vector2i(0, rh))
		both.save_png(OUT + "compare.png")
		# Pairs: [blueprint rect, camera direction, sheet x under the screen centre (side view only)].
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(OUT + "reference.png"))
		sheet.convert(Image.FORMAT_RGBA8)
		var unit := 0.95 / 273.0   # town units per sheet pixel
		var rows := [[Rect2i(20, 235, 360, 310), Vector3(-0.5, 0.03, -0.866)], [Rect2i(385, 235, 300, 310), Vector3(0, 0.02, -1)],
				[Rect2i(700, 235, 490, 310), Vector3(-1, 0.03, -0.23)], [Rect2i(1208, 235, 300, 310), Vector3(0, 0.02, 1)],
				[Rect2i(1530, 235, 460, 310), Vector3(0.6, 0.03, 0.8)]]
		var total := 0
		for row in rows: total += (row[0] as Rect2i).size.x * 4 + 40
		var pairs := Image.create(total, 310 * 2, false, Image.FORMAT_RGBA8)
		pairs.fill(Color("fdf0e9"))
		# body-overlay.png: the model laid half-transparent over the blueprint in the same views.
		var body_over := Image.create(total / 2, 310 * 2, false, Image.FORMAT_RGBA8)
		body_over.fill(Color("fdf0e9"))
		var at := 0
		for row in rows:
			var r: Rect2i = row[0]
			root.size = r.size * 2
			cam.size = r.size.y * unit
			var target := Vector3(0, (532.0 - (r.position.y + r.size.y * 0.5)) * unit, 0)
			if r.position.x == 700: target.z = (r.position.x + r.size.x * 0.5 - 940.0) * unit
			cam.position = target + (row[1] as Vector3).normalized() * 14.0
			cam.look_at(target)
			var img: Image = await shot()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_LANCZOS)
			var crop := sheet.get_region(r)
			crop.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_CUBIC)
			pairs.blit_rect(crop, Rect2i(Vector2i.ZERO, r.size * 2), Vector2i(at, 0))
			pairs.blit_rect(img, Rect2i(Vector2i.ZERO, r.size * 2), Vector2i(at + r.size.x * 2, 0))
			body_over.blit_rect(crop, Rect2i(Vector2i.ZERO, r.size * 2), Vector2i(at / 2, 0))
			var body_bytes := img.get_data()
			for bi in range(3, body_bytes.size(), 4): body_bytes[bi] = 128
			body_over.blend_rect(Image.create_from_data(r.size.x * 2, r.size.y * 2, false, Image.FORMAT_RGBA8, body_bytes),
					Rect2i(Vector2i.ZERO, r.size * 2), Vector2i(at / 2, 0))
			at += r.size.x * 4 + 40
		pairs.save_png(OUT + "pairs.png")
		body_over.save_png(OUT + "body-overlay.png")
		# Head pairs: the blueprint's head in its front 3/4, front and side views, each beside
		# the model's head at the same scale. [sheet point at the middle of the head, camera
		# direction]. The blueprint's side view has the head turned about 15 degrees toward
		# the viewer (its far ear, nostrils and near eye show), so the model is turned the same.
		var hs := Vector2i(300, 250)
		var heads := [[Vector2(172, 356), Vector3(-0.5, 0.03, -0.866)], [Vector2(533, 356), Vector3(0, 0.02, -1)], [Vector2(850, 356), Vector3(-1, 0.03, -0.27)]]
		var hp := Image.create((hs.x * 6 + 30) * 3, hs.y * 3, false, Image.FORMAT_RGBA8)
		hp.fill(Color("fdf0e9"))
		# head-overlay.png: the model laid half-transparent over the blueprint, for the silhouettes.
		# eye-pairs.png: the eyes cut from the same three views, blueprint left, model right.
		var eye_at := [Vector2i(55, 78), Vector2i(75, 80), Vector2i(40, 78)]   # top-left in the head crop, sheet px
		var ep := Image.create(1800 + 20, 360 * 3 + 40, false, Image.FORMAT_RGBA8)
		ep.fill(Color("fdf0e9"))
		var over := Image.create((hs.x * 3 + 30) * 3, hs.y * 3, false, Image.FORMAT_RGBA8)
		over.fill(Color("fdf0e9"))

		root.size = hs * 3
		cam.size = hs.y * unit
		for i in heads.size():
			var mid: Vector2 = heads[i][0]
			var target := Vector3(0, (532.0 - 356.0) * unit, (852.0 - 940.0) * unit)
			cam.position = target + (heads[i][1] as Vector3).normalized() * 14.0
			cam.look_at(target)
			var img: Image = await shot()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(hs.x * 3, hs.y * 3, Image.INTERPOLATE_LANCZOS)
			var crop := sheet.get_region(Rect2i(Vector2i(mid) - hs / 2, hs))
			crop.resize(hs.x * 3, hs.y * 3, Image.INTERPOLATE_CUBIC)
			hp.blit_rect(crop, Rect2i(Vector2i.ZERO, hs * 3), Vector2i(i * (hs.x * 6 + 30), 0))
			hp.blit_rect(img, Rect2i(Vector2i.ZERO, hs * 3), Vector2i(i * (hs.x * 6 + 30) + hs.x * 3, 0))
			over.blit_rect(crop, Rect2i(Vector2i.ZERO, hs * 3), Vector2i(i * (hs.x * 3 + 30), 0))
			var bytes := img.get_data()
			for bi in range(3, bytes.size(), 4): bytes[bi] = 128
			var ghost := Image.create_from_data(hs.x * 3, hs.y * 3, false, Image.FORMAT_RGBA8, bytes)
			over.blend_rect(ghost, Rect2i(Vector2i.ZERO, hs * 3), Vector2i(i * (hs.x * 3 + 30), 0))
			for half_i in 2:
				var cut: Image = ([crop, img][half_i] as Image).get_region(Rect2i(eye_at[i] * 3, Vector2i(450, 180)))
				cut.resize(900, 360, Image.INTERPOLATE_CUBIC)
				ep.blit_rect(cut, Rect2i(0, 0, 900, 360), Vector2i(half_i * 920, i * 380))
		hp.save_png(OUT + "head-pairs.png")
		ep.save_png(OUT + "eye-pairs.png")
		over.save_png(OUT + "head-overlay.png")
	print("TURNAROUND saved")
	quit()
