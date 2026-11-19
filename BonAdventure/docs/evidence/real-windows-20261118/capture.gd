extends SceneTree
## Real windows (user, 18 Nov 2026; docs/guides/WINDOWS.md "Real windows"): each front window of the
## police station and the supermarket seen from the street and from the room, at noon and 21:00, plus
## a wide street view and a wide room view; prints draw calls at the street views and checks the
## windows (see-through, outdoors face, preset frame, wall opened: a ray through the glass centre
## hits nothing but the window's own wall collision).
## Needs a window; writes <tag>-<unit>.png sheets and full-size <tag>-<unit>-street.png and
## -room.png wide views into this folder (overwrites them). Keep keys away from the window (B shows
## the zone walls).
##   HOME=<scratch>/home VT_FOCUS=police,supermarket VT_SPAWN=none godot --path . --resolution 1000x780 \
##     --script res://docs/evidence/real-windows-20261118/capture.gd -- tag=before|after [units=police,supermarket] [apply] [opaque]
## `apply`: run each unit's `real_windows` step at load (as the bake will), for a dry run.
## `opaque`: the cheap glass mode. Sheet columns: street noon | room noon | street angle | street 21:00 | room 21:00.
const ModularTown := preload("res://scripts/world/modular_town.gd")
const GlassWindow := preload("res://scripts/world/glass_window.gd")
const FOLDER := "res://docs/evidence/real-windows-20261118/"
const TILE := Vector2i(320, 230)
## Window centres (town coordinates) and the outdoors direction, per unit.
const TARGETS := {
	"police": [[Vector3(-138.885, 2.15, 74.01), Vector3(1, 0, 0), 6.6], [Vector3(-138.885, 2.15, 85.985), Vector3(1, 0, 0), 6.6]],
	"supermarket": [[Vector3(-132.9, 2.12, 118.05), Vector3(1, 0, 0), 8.9], [Vector3(-132.9, 2.12, 133.96), Vector3(1, 0, 0), 8.9]],
}

var game
var camera: Camera3D
var cycle
var args := {}
var town: Node3D

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func sheet(rows: Array) -> Image:
	var cols := 5
	var out := Image.create(TILE.x * cols, TILE.y * maxi(rows.size(), 1), false, Image.FORMAT_RGB8)
	for r in range(rows.size()):
		for c in range(rows[r].size()):
			if rows[r][c] == null:
				continue
			var img: Image = rows[r][c].duplicate()
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	return out

## Camera at `offset` (town units, in the window's frame: x along the wall, z outward), looking at it.
func aim(centre: Vector3, outward: Vector3, offset: Vector3, look_y := 0.0) -> void:
	var along := Vector3.UP.cross(outward)
	var eye := centre + along * offset.x + Vector3.UP * offset.y + outward * offset.z
	camera.fov = 62.0
	camera.global_position = town.to_global(eye)
	camera.look_at(town.to_global(centre + Vector3.UP * look_y), Vector3.UP)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("opaque"):
		ProjectSettings.set_setting(GlassWindow.MODE_SETTING, "opaque")
	var tag: String = args.get("tag", "view")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("editing_snapshot", true)
	root.add_child(game)
	town = game.apartment
	var units: Array = Array(args.units.split(",")) if args.has("units") else TARGETS.keys()
	if args.has("apply"):
		for unit in units:
			var script = load("res://scripts/buildings/%s.gd" % unit).new()
			if script.has_method("real_windows"):
				script.real_windows(town, game)
	preload("res://scripts/world/garden_rendering.gd").new().build(town)
	preload("res://scripts/world/render_culling.gd").new().build(game)
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
	await settle(5)
	for unit in units:
		check(unit)
		var rows := []
		for target in TARGETS[unit]:
			rows.append([null, null, null, null, null])
		# Wide views: street and room, noon.
		var wide := [null, null, null, null, null]
		for t in [[12 * 60, 0], [21 * 60, 1]]:
			cycle.set_time(t[0])
			await settle(4)
			for i in range(TARGETS[unit].size()):
				var target: Array = TARGETS[unit][i]
				var dist: float = clampf(target[2] * 0.75, 3.0, 7.0)
				var shots := [[Vector3(0, 0.1, dist), 0], [Vector3(0, -0.4, -dist), 1], [Vector3(target[2] * 0.45, -0.2, dist * 0.55), 2]] if t[1] == 0 \
					else [[Vector3(0, 0.1, dist), 3], [Vector3(0, -0.4, -dist), 4]]
				for shot in shots:
					aim(target[0], target[1], shot[0])
					await settle(3)
					rows[i][shot[1]] = await frame_image()
			if t[1] == 0:
				var a: Array = TARGETS[unit][0]
				var b: Array = TARGETS[unit][1]
				var mid: Vector3 = (a[0] + b[0]) * 0.5
				aim(mid, a[1], Vector3(0, 0.0, 16.0), -0.3)
				await settle(20)
				var calls := 0.0
				for k in range(20):
					await process_frame
					calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				print("REAL %s %s street view: %.0f draw calls" % [tag, unit, calls / 20.0])
				wide[0] = await frame_image()
				aim(mid, a[1], Vector3(0, 0.0, -11.0), -0.3)
				await settle(8)
				wide[1] = await frame_image()
		rows.append(wide)
		wide[0].save_png(ProjectSettings.globalize_path(FOLDER + "%s-%s-street.png" % [tag, unit]))
		wide[1].save_png(ProjectSettings.globalize_path(FOLDER + "%s-%s-room.png" % [tag, unit]))
		sheet(rows).save_png(ProjectSettings.globalize_path(FOLDER + "%s-%s.png" % [tag, unit]))
		print("REAL %s %s sheet written" % [tag, unit])
	quit(0)

## Windows near each target: see-through, outdoors face, frame preset, and the wall opened (a ray
## from the room through the glass centre to the street meets only thin glass-window collision).
func check(unit: String) -> void:
	for target in TARGETS[unit]:
		var centre: Vector3 = target[0]
		var found: Node3D = null
		for w in get_nodes_in_group(GlassWindow.GROUP):
			if town.to_local((w as Node3D).global_position).distance_to(centre) < 0.3:
				found = w
		if found == null:
			print("REAL CHECK %s %s: no window at the centre" % [unit, centre])
			continue
		var mesh_hits := []
		var from: Vector3 = centre - target[1] * 1.5
		var to: Vector3 = centre + target[1] * 1.5
		for m in town.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null or not mi.visible or found.is_ancestor_of(mi):
				continue
			var to_town := town.global_transform.affine_inverse() * mi.global_transform
			var a := from + Vector3(0, 0.3, 0.3)
			var b := to + Vector3(0, 0.3, 0.3)
			if not (to_town * mi.get_aabb()).intersects_segment(a, b):
				continue
			# Through the triangles (a cut wall's box still spans its opening).
			var faces := mi.mesh.get_faces()
			var la := to_town.affine_inverse() * a
			var lb := to_town.affine_inverse() * b
			for f in range(0, faces.size(), 3):
				if Geometry3D.segment_intersects_triangle(la, lb, faces[f], faces[f + 1], faces[f + 2]) != null:
					mesh_hits.append(str(town.get_path_to(mi)))
					break
		var click := found.find_children("*", "StaticBody3D", true, false)
		print("REAL CHECK %s %s: see_through=%s outside=%d style=%d accent=%s wall_depth=%.2f word=%s click bodies=%d; meshes across the glass: %s" % [
			unit, found.name, found.see_through, found.outside, found.frame_style, found.frame_accent, found.wall_depth,
			found.get_meta("word_key", ""), click.size(), mesh_hits])
