extends SceneTree
## Rendered views and frame times for the day-night cycle (9 Nov 2026). Needs a window; writes
## PNGs into this folder (overwrites them). Run with an isolated HOME (README):
##   godot --path . --resolution 1200x900 --script res://docs/evidence/day-night-20261109/capture.gd
## Writes sheet-outdoor.png (rows: street, aerial, garden, sky toward the sun/moon; columns: 06:30, 12:00, 17:45, 18:40,
## 21:00), sheet-indoor.png (supermarket, home, supermarket door looking out; 12:00 and 21:00), hud-night.png (clock panel
## open) and prints frame times: noon vs midnight (paused) and a fast-running sunset.
const ModularTown := preload("res://scripts/world/modular_town.gd")
const FOLDER := "res://docs/evidence/day-night-20261109/"
const TILE := Vector2i(360, 270)
const TIMES := [[6, 30], [12, 0], [17, 45], [18, 40], [21, 0]]

var game
var camera: Camera3D

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func aim(site: Node3D, eye: Vector3, target: Vector3, fov: float) -> void:
	camera.fov = fov
	camera.global_position = site.to_global(eye)
	camera.look_at(site.to_global(target))
	# The indoor probe and Main's Home roof follow the (hidden) player.
	game.player.global_position = camera.global_position - Vector3(0, 1.6, 0)

func sheet(rows: Array, columns: int) -> Image:
	var out := Image.create(TILE.x * columns, TILE.y * rows.size(), false, Image.FORMAT_RGB8)
	for r in range(rows.size()):
		for c in range(rows[r].size()):
			var img: Image = rows[r][c]
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	return out

func measure(frames: int) -> Array:
	var times := []
	for i in range(frames):
		var start := Time.get_ticks_usec()
		await process_frame
		times.append((Time.get_ticks_usec() - start) / 1000.0)
	times.sort()
	return [times[frames / 2], times[int(frames * 0.95)], times[-1]]

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	camera = Camera3D.new()
	game.add_child(camera)
	camera.current = true
	var cycle = game.day_night
	cycle.pause()
	var town: Node3D = game.apartment
	var market := ModularTown.building(town, "supermarket")
	var home := ModularTown.building(town, "home")
	game.hud.hide()
	var outdoor := [
		[town, Vector3(0, 2.5, 198), Vector3(0, 2.8, 223), 65.0],
		[town, Vector3(38, 30, 185), Vector3(0, 2, 229), 62.0],
		[town, Vector3(-65, 16, 115), Vector3(-20, 1, 139), 70.0],
	]
	var rows := []
	for view in outdoor:
		var row := []
		aim(view[0], view[1], view[2], view[3])
		await settle(20)
		for t in TIMES:
			cycle.set_time(t[0] * 60 + t[1])
			await settle(4)
			row.append(await frame_image())
		rows.append(row)
	# Sky row: from the street, turn toward the sun disc / moon (kept at least 14° up, so a set
	# sun shows the horizon where it went down).
	var sky_row := []
	aim(town, Vector3(0, 2.5, 198), Vector3(0, 2.8, 223), 75.0)
	for t in TIMES:
		cycle.set_time(t[0] * 60 + t[1])
		await settle(2)
		var toward: Vector3 = (cycle.sky_disc.global_position - camera.global_position).normalized()
		toward.y = maxf(toward.y, 0.25)
		camera.look_at(camera.global_position + toward)
		await settle(4)
		sky_row.append(await frame_image())
	rows.append(sky_row)
	sheet(rows, TIMES.size()).save_png(FOLDER + "sheet-outdoor.png")
	var indoor := [
		[market, Vector3(-28.3, 2.5, 42), Vector3(-37, 1.5, 48), 76.0],
		[home, Vector3(3, 1.8, 10), Vector3(0, 1.2, 2), 70.0],
		# Looking out of the supermarket door: the outside must keep the time of day.
		[market, Vector3(-33, 1.8, 41), Vector3(-33, 1.4, 20), 70.0],
	]
	var indoor_rows := []
	for view in indoor:
		var row := []
		aim(view[0], view[1], view[2], view[3])
		for t in [[12, 0], [21, 0]]:
			cycle.set_time(t[0] * 60 + t[1])
			await settle(50)
			row.append(await frame_image())
		indoor_rows.append(row)
	sheet(indoor_rows, 2).save_png(FOLDER + "sheet-indoor.png")
	print("DAY NIGHT CAPTURE: indoor blend %.2f at the last indoor view" % cycle.indoor)

	# The HUD clock with its panel, at night on the street.
	aim(town, Vector3(0, 2.5, 198), Vector3(0, 2.8, 223), 65.0)
	cycle.set_time(21 * 60)
	game.hud.show()
	game.day_clock.open()
	await settle(30)
	(await frame_image()).save_png(FOLDER + "hud-night.png")
	game.day_clock.close()
	game.hud.hide()

	# Frame times (VSync off): the garden benchmark view and the street.
	for spec in [["garden", outdoor[2]], ["street", outdoor[0]]]:
		var view: Array = spec[1]
		aim(view[0], view[1], view[2], view[3])
		for t in [12 * 60, 0]:
			cycle.pause()
			cycle.set_time(t)
			await settle(40)
			var m := await measure(120)
			print("FRAME %s %s paused: median %.2f ms, p95 %.2f ms, max %.2f ms, draw calls %d" % [spec[0], "noon" if t == 720 else "midnight", m[0], m[1], m[2], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		# Sunset running fast (a one-minute day: 24 game minutes per second) through the lamp switch.
		cycle.set_time(17 * 60 + 30)
		cycle.set_cycle_minutes(1.0)
		cycle.resume()
		await settle(10)
		var running := await measure(240)
		cycle.pause()
		cycle.set_cycle_minutes(20.0)
		print("FRAME %s sunset running (to %s): median %.2f ms, p95 %.2f ms, max %.2f ms" % [spec[0], game.day_clock.time_text(), running[0], running[1], running[2]])
	quit()
