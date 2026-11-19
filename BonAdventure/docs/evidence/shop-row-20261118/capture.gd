extends SceneTree
## Shop row restyle (18 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md "Shop row restyle"): the five
## shops (bakery, clothing, electronics, sports, furniture) seen from the street at noon, front and
## three-quarter, as the game draws them (static batching on). Needs a window; writes
## <prefix>-<unit>.png and <prefix>-sheet.png into this folder (overwrites them).
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/shop-row-20261118/capture.gd -- prefix=before [apply]
## `apply`: run each shop's `shop_row_style` step at load (a preview before the units are baked).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const FOLDER := "res://docs/evidence/shop-row-20261118/"
const UNITS := ["bakery", "clothing", "electronics", "sports", "furniture"]
const TILE := Vector2i(480, 320)

var game
var camera: Camera3D
var args := {}

func _initialize(): run.call_deferred()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		var b: AABB = m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var prefix: String = args.get("prefix", "view")
	game = load("res://scenes/main.tscn").instantiate()
	if args.has("apply"):
		game.set_meta("editing_snapshot", true)
	root.add_child(game)
	if args.has("apply"):
		for unit in UNITS:
			load("res://scripts/buildings/%s.gd" % unit).new().shop_row_style(game.apartment, game)
		preload("res://scripts/world/garden_rendering.gd").new().build(game.apartment)
		preload("res://scripts/world/render_culling.gd").new().build(game)
	await settle(5)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	camera.near = 0.05
	camera.fov = 58.0
	game.add_child(camera)
	camera.current = true
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	game.hud.hide()
	var town: Node3D = game.apartment
	var tiles := []
	for unit in UNITS:
		var facade := preload("res://scripts/buildings/shop_row.gd").facade_of(town, unit)
		var shell := ModularTown.building(town, unit, 1)
		if facade == null or shell == null:
			print("SHOPROW %s missing" % unit)
			continue
		var fb := bounds(facade)
		var sb := bounds(shell)
		# The street side: from the shell's centre towards its entrance mat.
		var mat := shell.find_child("Entry mat", true, false) as Node3D
		var front: Vector3 = mat.global_position if mat != null else fb.get_center()
		var out := front - sb.get_center()
		out.y = 0.0
		out = out.normalized()
		var target := Vector3(front.x, 2.6, front.z)
		var width := maxf(sb.size.x, sb.size.z)
		for angle in [0.0, 0.6]:
			var dir := out.rotated(Vector3.UP, angle)
			camera.global_position = target + dir * (width * 0.85 + 3.0) + Vector3(0, 1.4, 0)
			camera.look_at(target)
			await settle(12)
			var img := await frame_image()
			if angle == 0.0:
				img.save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-" + unit + ".png"))
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			tiles.append(img)
		# Inside, from the door towards the back wall (the shell walls are single boxes, so the
		# restyle also recolours their inner faces).
		camera.global_position = Vector3(front.x, 2.2, front.z) - out * 1.5
		camera.look_at(Vector3(sb.get_center().x, 2.0, sb.get_center().z) - out * 2.0)
		await settle(12)
		var inside := await frame_image()
		inside.save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-" + unit + "-inside.png"))
		print("SHOPROW %s facade %s shell %s out %s" % [unit, fb.get_center(), sb.get_center(), out])
	var sheet := Image.create(TILE.x * 2, TILE.y * (tiles.size() / 2), false, Image.FORMAT_RGB8)
	for i in range(tiles.size()):
		var t: Image = tiles[i]
		t.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(t, Rect2i(Vector2i.ZERO, TILE), Vector2i((i % 2) * TILE.x, (i / 2) * TILE.y))
	sheet.save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-sheet.png"))
	print("SHOPROW done")
	quit(0)
