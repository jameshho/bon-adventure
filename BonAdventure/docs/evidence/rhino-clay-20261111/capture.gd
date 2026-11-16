extends SceneTree
## Turnaround of scenes/animals/rhino_clay.tscn on a cream stage, laid out like the user's
## blueprint (front 3/4, front, side, back, rear 3/4) in turnaround.png, face and eye close-ups
## (face.png, eyes.png), compare.png: the blueprint (reference.png) above the turnaround, and
## pairs.png: the blueprint's front 3/4, front and side views each beside the model at the same
## scale (orthographic, so the blueprint's perspective differs a little).
## With `zoo` it instead loads the town and saves views of the rhino's saved place
## (zoo-close.png, zoo-front.png, zoo-side.png, zoo-location.png). Run with an isolated HOME
## (README), and for `zoo` VT_FOCUS=all VT_SPAWN=none:
##   godot --path . --resolution 760x560 --script res://docs/evidence/rhino-clay-20261111/capture.gd [-- zoo]
const OUT := "res://docs/evidence/rhino-clay-20261111/"
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

## Views of the rhino's saved place in the town (zoo-close.png, zoo-front.png, zoo-location.png).
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
	var placed: Node3D = game.apartment.get_node("ParkZoo/RhinoClayDisplay")
	print("CLAY DISPLAY at ", placed.global_position, ", parts ", placed.get_child_count())
	var town_cam := Camera3D.new()
	game.add_child(town_cam)
	town_cam.current = true
	town_cam.fov = 40
	var aim := placed.global_position + Vector3(0, 1.1, 0)
	var facing := -placed.global_transform.basis.z.normalized()
	var across := placed.global_transform.basis.x.normalized()
	for view in [["zoo-close", facing * 5.0 - across * 4.5 + Vector3(0, 0.6, 0)], ["zoo-front", facing * 6.5 + Vector3(0, 0.4, 0)],
			["zoo-side", -across * 7.0 + Vector3(0, 0.4, 0)], ["zoo-location", facing * 16.0 - across * 10.0 + Vector3(0, 10.0, 0)]]:
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
	var rhino: Node3D = load("res://scenes/animals/rhino_clay.tscn").instantiate()
	stage.add_child(rhino)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.3
	stage.add_child(cam)
	cam.current = true
	# Even, soft studio light (user, 11 Nov 2026): the lamps ride on the camera, so every view
	# is lit the same: a gentle key from above and a little left, a faint fill from the right, no shadows.
	for lamp in [[Vector3(-58, -20, 0), 0.9], [Vector3(-8, 30, 0), 0.22]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = lamp[0]
		light.light_energy = lamp[1]
		cam.add_child(light)
	for i in range(20): await process_frame
	var views := [Vector3(-0.72, 0.12, -0.69), Vector3(0, 0.1, -1), Vector3(-1, 0.08, 0), Vector3(0, 0.12, 1), Vector3(0.7, 0.14, 0.7)]
	var turn: Image = await strip_of(cam, Vector3(0, 0.93, 0), views, "turnaround.png")
	cam.size = 1.25
	await strip_of(cam, Vector3(0, 1.2, -0.75), [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)], "face.png")
	cam.size = 0.62
	await strip_of(cam, Vector3(0, 1.24, -0.78), [Vector3(-0.72, 0.05, -0.69), Vector3(0, 0.02, -1), Vector3(-1, 0.02, 0)], "eyes.png")
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
		var unit := 1.9 / 330.5   # town units per sheet pixel
		var rows := [[Rect2i(20, 185, 360, 365), Vector3(-0.55, 0.1, -0.83)], [Rect2i(401, 185, 240, 365), Vector3(0, 0.02, -1)],
				[Rect2i(680, 185, 540, 365), Vector3(-1, 0.02, 0)]]
		var total := 0
		for row in rows: total += (row[0] as Rect2i).size.x * 4 + 40
		var pairs := Image.create(total, 365 * 2, false, Image.FORMAT_RGBA8)
		pairs.fill(Color("fdf0e9"))
		var at := 0
		for row in rows:
			var r: Rect2i = row[0]
			root.size = r.size * 2
			cam.size = r.size.y * unit
			var target := Vector3(0, (527.5 - (r.position.y + r.size.y * 0.5)) * unit, 0)
			if r.position.x == 680: target.z = (r.position.x + r.size.x * 0.5 - 944.0) * unit
			cam.position = target + (row[1] as Vector3).normalized() * 14.0
			cam.look_at(target)
			var img: Image = await shot()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_LANCZOS)
			var crop := sheet.get_region(r)
			crop.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_CUBIC)
			pairs.blit_rect(crop, Rect2i(Vector2i.ZERO, r.size * 2), Vector2i(at, 0))
			pairs.blit_rect(img, Rect2i(Vector2i.ZERO, r.size * 2), Vector2i(at + r.size.x * 2, 0))
			at += r.size.x * 4 + 40
		pairs.save_png(OUT + "pairs.png")
	print("TURNAROUND saved")
	quit()
