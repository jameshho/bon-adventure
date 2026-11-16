extends SceneTree
## Shared window component (12 Nov 2026, docs/guides/WINDOWS.md): every window of the migrated units seen
## from both sides of its glass, at noon and at 21:00, as the game draws it (static batching on).
## Needs a window; writes <unit>.png sheets into this folder (overwrites them) and prints each
## sheet's rows (window paths), the draw calls and frame times of a few fixed views.
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1000x780 \
##     --script res://docs/evidence/windows-20261112/capture.gd [-- apply] [-- opaque] [-- only=<unit>,...]
## `apply`: migrate the panes at load (before the units are baked: the same helper the bake uses).
## `opaque`: the cheap glass mode (project setting vocabulary_town/rendering/glass_mode).
## Sheet columns: side A noon | side B noon | side A night | side B night (A = the glass's +Z side).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const GlassWindows := preload("res://scripts/buildings/glass_windows.gd")
const GlassWindow := preload("res://scripts/world/glass_window.gd")
const FOLDER := "res://docs/evidence/windows-20261112/"
const TILE := Vector2i(300, 220)
const UNITS := ["airport", "warehouse", "school", "sports", "bakery", "electronics", "bank", "barn", "library", "restaurants", "police", "supermarket", "clothing"]

var game
var camera: Camera3D
var cycle
var args := {}

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func sheet(rows: Array) -> Image:
	var cols := 4
	var out := Image.create(TILE.x * cols, TILE.y * maxi(rows.size(), 1), false, Image.FORMAT_RGB8)
	for r in range(rows.size()):
		for c in range(rows[r].size()):
			var img: Image = rows[r][c].duplicate()
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	return out

## Camera on one side of a window, looking at its centre from far enough to frame it.
func aim(window: Node3D, side: float) -> void:
	var centre: Vector3 = window.global_position
	var normal: Vector3 = window.global_transform.basis.z.normalized()
	var size: float = maxf(window.width, window.height) * window.global_transform.basis.get_scale().x
	var distance := clampf(size * 1.1, 2.2, 9.0)
	camera.fov = 62.0
	camera.global_position = centre + normal * side * distance
	camera.look_at(centre, Vector3.UP if absf(normal.y) < 0.9 else Vector3.FORWARD)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("opaque"):
		ProjectSettings.set_setting(GlassWindow.MODE_SETTING, "opaque")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	var started := Time.get_ticks_msec()
	game = load("res://scenes/main.tscn").instantiate()
	var units: Array = UNITS if not args.has("only") else ([] if args.only == "none" else Array(args.only.split(",")))
	# The batchers run after the panes are migrated, as in a game loaded from baked units.
	game.set_meta("editing_snapshot", true)
	root.add_child(game)
	if args.has("apply"):
		for unit in units:
			GlassWindows.migrate(game.apartment, unit)
	preload("res://scripts/world/garden_rendering.gd").new().build(game.apartment)
	preload("res://scripts/world/render_culling.gd").new().build(game)
	print("WINDOWS load %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	camera.near = 0.05
	game.add_child(camera)
	camera.current = true
	cycle = game.day_night
	cycle.pause()
	game.hud.hide()
	var town: Node3D = game.apartment
	var windows := get_nodes_in_group(GlassWindow.GROUP)
	print("WINDOWS in town: %d" % windows.size())
	await perf_views(town)
	for unit in units:
		var rows := []
		var found := []
		for part in ModularTown.registry()[unit].parts:
			var holder := town.get_node_or_null(NodePath(part))
			if holder == null:
				continue
			for w in windows:
				if holder.is_ancestor_of(w):
					found.append(w)
		for w in found:
			rows.append([null, null, null, null])
			print("WINDOWS %s row %d: %s  %.2f x %.2f see_through=%s shape=%d" % [unit, rows.size(), town.get_path_to(w), w.width, w.height, w.see_through, w.shape])
		for t in [[12 * 60, 0], [21 * 60, 2]]:
			cycle.set_time(t[0])
			await settle(3)
			for i in range(found.size()):
				for s in [[1.0, 0], [-1.0, 1]]:
					aim(found[i], s[0])
					await settle(2)
					rows[i][t[1] + s[1]] = await frame_image()
		if not rows.is_empty():
			sheet(rows).save_png(ProjectSettings.globalize_path(FOLDER + unit + ".png"))
	print("WINDOWS done in %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit(0)

## Draw calls and frame time at fixed street views (noon), for before/after comparison.
func perf_views(town: Node3D) -> void:
	cycle.set_time(12 * 60)
	var views := [
		["supermarket", Vector3(0, 2.0, -26), Vector3(0, 1.8, 0)],
		["restaurants", Vector3(0, 2.0, -24), Vector3(0, 2.0, 0)],
		["bank", Vector3(0, 2.0, -18), Vector3(0, 1.8, 0)],
		["airport", Vector3(0, 3.0, -40), Vector3(0, 3.0, 0)],
	]
	for v in views:
		var site := ModularTown.building(town, v[0])
		if site == null:
			continue
		camera.global_position = site.to_global(v[1])
		camera.look_at(site.to_global(v[2]))
		await settle(20)
		var calls := 0.0
		var objects := 0.0
		var start := Time.get_ticks_usec()
		for i in range(30):
			await process_frame
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		var ms := (Time.get_ticks_usec() - start) / 30000.0
		print("WINDOWS perf %s: %.0f draw calls, %.0f objects, %.2f ms/frame" % [v[0], calls / 30.0, objects / 30.0, ms])
