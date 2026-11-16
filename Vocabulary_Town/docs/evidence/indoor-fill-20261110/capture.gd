extends SceneTree
## Local indoor fill (10 Nov 2026; scripts/world/day_night.gd _fit_room()). Needs a window; writes
## sheet.png into this folder (overwrites it) and prints the fitted boxes and colour differences.
## Run with an isolated HOME (README):
##   VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1000x780 --script res://docs/evidence/indoor-fill-20261110/capture.gd
## Rows (21:00 and 18:40 columns where noted):
##   1 hospital corridor looking out of the main door, 21:00: before (old global warm fill emulated) |
##     after, player inside | after, player outside (the door view must match the middle tile)
##   2 the street outside the hospital door, player outdoors: 21:00 | 18:40 | 12:00
##   3 supermarket, player inside: aisle 21:00 | aisle 12:00 | door looking out 21:00
const ModularTown := preload("res://scripts/world/modular_town.gd")
const FOLDER := "res://docs/evidence/indoor-fill-20261110/"
const TILE := Vector2i(400, 312)

var game
var camera: Camera3D
var cycle

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

func put_player(site: Node3D, at: Vector3) -> void:
	game.player.global_position = site.to_global(at)
	await create_timer(1.6).timeout
	await settle(3)

func box_text() -> String:
	var p: ReflectionProbe = cycle.room_probe
	return "visible=%s centre=%s size=%s yaw=%.1f indoor=%.2f" % [p.visible, p.global_position.snapped(Vector3.ONE * 0.01), p.size.snapped(Vector3.ONE * 0.01), p.global_rotation_degrees.y, cycle.indoor]

## Mean absolute RGB difference (0-255) of two images inside a rectangle given in fractions.
func difference(a: Image, b: Image, rect: Rect2) -> float:
	var size := a.get_size()
	var total := 0.0
	var count := 0
	for y in range(int(rect.position.y * size.y), int(rect.end.y * size.y), 2):
		for x in range(int(rect.position.x * size.x), int(rect.end.x * size.x), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0
			count += 1
	return total / maxf(count, 1) * 255.0

func sheet(rows: Array) -> Image:
	var out := Image.create(TILE.x * 3, TILE.y * rows.size(), false, Image.FORMAT_RGB8)
	for r in range(rows.size()):
		for c in range(rows[r].size()):
			var img: Image = rows[r][c].duplicate()
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	return out

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	# macOS stops drawing a covered window, which stalls the frame waits below.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	game.add_child(camera)
	camera.current = true
	cycle = game.day_night
	cycle.pause()
	game.hud.hide()
	var town: Node3D = game.apartment
	var hospital := ModularTown.building(town, "hospital")
	var market := ModularTown.building(town, "supermarket")
	var rows := []

	# Row 1: the user's view, the hospital corridor looking out of the main door at night.
	cycle.set_time(21 * 60)
	aim(hospital, Vector3(-32, 2.3, 113), Vector3(-32, 1.6, 95), 62.0)
	await put_player(hospital, Vector3(-32, 0.1, 111))
	print("INDOOR FILL hospital inside: ", box_text())
	var inside: Image = await frame_image()
	# Before: the fill was the global ambient and the moon faded; emulated with the probe hidden.
	var env: Environment = cycle.environment
	cycle.room_probe.visible = false
	env.ambient_light_color = Color(cycle._indoor_color)
	env.ambient_light_energy = cycle._indoor_energy
	await settle(3)
	var before: Image = await frame_image()
	cycle._apply_fill()
	await put_player(hospital, Vector3(-32, 0.1, 96))
	print("INDOOR FILL hospital outside: ", box_text())
	var outside: Image = await frame_image()
	var door := Rect2(0.36, 0.3, 0.28, 0.35)
	print("INDOOR FILL door view difference (0-255), after inside vs outside: %.2f; before inside vs outside: %.2f" % [difference(inside, outside, door), difference(before, outside, door)])
	rows.append([before, inside, outside])

	# Row 2: the street outside the door with the player outdoors.
	var street := []
	aim(hospital, Vector3(-32, 2.6, 101), Vector3(-32, 1.6, 80), 62.0)
	for t in [21 * 60, 18 * 60 + 40, 12 * 60]:
		cycle.set_time(t)
		await settle(4)
		street.append(await frame_image())
	rows.append(street)

	# Row 3: the supermarket at night and noon, and its door looking out at night.
	var shop := []
	cycle.set_time(21 * 60)
	aim(market, Vector3(-28.3, 2.5, 42), Vector3(-37, 1.5, 48), 76.0)
	await put_player(market, Vector3(-30, 0.1, 44))
	print("INDOOR FILL supermarket: ", box_text())
	shop.append(await frame_image())
	cycle.set_time(12 * 60)
	await settle(4)
	shop.append(await frame_image())
	cycle.set_time(21 * 60)
	aim(market, Vector3(-33, 1.8, 41), Vector3(-33, 1.4, 20), 70.0)
	await settle(4)
	shop.append(await frame_image())
	rows.append(shop)
	sheet(rows).save_png(FOLDER + "sheet.png")
	print("INDOOR FILL CAPTURE done")
	quit()
