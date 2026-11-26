extends SceneTree
## Indoor sun and flight sky (improvement plan GFX-03 / GFX-04, 25 Nov 2026; day_night.gd).
## Writes into this folder (overwrites):
##   indoor.png  rows: café (bakery), home, supermarket door looking out; columns 08:00, 12:00, 18:30
##   flight.png  the plane flown level north over the town centre: 40 m and 100 m by day (14:00),
##               100 m at night (22:54), and on foot at the centre (14:00, the usual 130 m view)
## and prints the sun energy, indoor blend and fill per indoor view, and the sky curve / fog sky
## affect per flight view. LIGHT_FLIGHT_ONLY=1 skips the indoor views (indoor.png is kept).
## Needs a window; isolated HOME:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1200x900 --script res://docs/evidence/light-indoor-flight-20261125/capture.gd
const ModularTown := preload("res://scripts/world/modular_town.gd")
const FOLDER := "res://docs/evidence/light-indoor-flight-20261125/"
const TILE := Vector2i(400, 300)

var game
var camera: Camera3D

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func sheet(rows: Array, columns: int) -> Image:
	var out := Image.create(TILE.x * columns, TILE.y * rows.size(), false, Image.FORMAT_RGB8)
	for r in range(rows.size()):
		for c in range(rows[r].size()):
			var img: Image = rows[r][c]
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	return out

func aim(site: Node3D, eye: Vector3, target: Vector3, fov: float) -> void:
	camera.fov = fov
	camera.global_position = site.to_global(eye)
	camera.look_at(site.to_global(target))
	# The indoor probe follows the (hidden) player.
	game.player.global_position = camera.global_position - Vector3(0, 1.6, 0)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	var cycle = game.day_night
	cycle.pause()
	var town: Node3D = game.apartment
	var home := ModularTown.building(town, "home")
	var market := ModularTown.building(town, "supermarket")
	# Indoor views: the player is parked (physics off) and hidden; a free camera looks around.
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	game.hud.hide()
	camera = Camera3D.new()
	camera.near = 0.05
	game.add_child(camera)
	camera.current = true
	var views := [
		["café", town, Vector3(184.0, 1.7, 214.0), Vector3(191.0, 1.0, 208.5), 72.0],
		["home", home, Vector3(3, 1.8, 10), Vector3(0, 1.2, 2), 70.0],
		["market door", market, Vector3(-33, 1.8, 41), Vector3(-33, 1.4, 20), 70.0],
	]
	var rows := []
	var flight_only := OS.get_environment("LIGHT_FLIGHT_ONLY") == "1"
	for view in ([] if flight_only else views):
		var row := []
		# The café view is in world coordinates (game root); the others are building-local.
		var site: Node3D = game if view[0] == "café" else view[1]
		aim(site, view[2], view[3], view[4])
		for t in [8.0, 12.0, 18.5]:
			cycle.set_time(t * 60.0)
			await settle(50)
			row.append(await frame_image())
			print("LIGHT %s %05.2f h: indoor %.2f, sun %.2f, ambient %.2f, fill %s %.2f" % [view[0], t, cycle.indoor, cycle.sun.light_energy, cycle.environment.ambient_light_energy, cycle.room_probe.visible if cycle.room_probe else false, cycle.room_probe.ambient_color_energy if cycle.room_probe else 0.0])
		rows.append(row)
	if not flight_only:
		sheet(rows, 3).save_png(FOLDER + "indoor.png")
	# Flight: the game's own chase camera and HUD hidden.
	camera.current = false
	game.player.visible = true
	game.player.set_physics_process(true)
	game.interaction.set_physics_process(true)
	var bounds: Rect2 = town.get_meta("reference_map_bounds")
	var centre: Vector3 = town.to_global(Vector3(bounds.get_center().x, 0, bounds.get_center().y))
	var shots := []
	cycle.set_time(14.0 * 60.0)
	game.player.global_position = centre + Vector3(0, 2, -120)
	game.player.camera_yaw = PI
	game.player.reset_camera()
	await settle(200)
	var on_foot: Image = await frame_image()
	print("LIGHT on foot: view %.0f, sky curve %.3f, fog sky %.2f" % [game.player.camera.far, cycle.sky_material.sky_curve, cycle.environment.fog_sky_affect])
	var plane: Node3D = town.get_node("Vehicles/Turboprop")
	game.player.global_position = plane.boarding_step_point()
	game.toggle_vehicle()
	for i in 200: await physics_frame
	for spec in [[40, 14.0], [100, 14.0], [100, 22.9]]:
		cycle.set_time(spec[1] * 60.0)
		var start: Vector3 = centre + Vector3(0, 0, -120)
		start.y = town.global_position.y + float(spec[0])
		plane.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP).scaled(plane.global_basis.get_scale()), start)
		plane.flight_velocity = Vector3(0, 0, plane.CRUISE)
		plane.airspeed = plane.CRUISE
		plane.landed = false
		game.player.reset_camera()
		await settle(240)
		shots.append(await frame_image())
		print("LIGHT flight %d m at %.1f h: view %.0f, sky curve %.3f, fog sky %.2f, plane %.0f m up at %s, camera %s" % [spec[0], spec[1], game.player.camera.far, cycle.sky_material.sky_curve, cycle.environment.fog_sky_affect, plane.global_position.y - town.global_position.y, plane.global_position, game.player.camera.global_position])
	shots.append(on_foot)
	sheet([[shots[0], shots[1]], [shots[2], shots[3]]], 2).save_png(FOLDER + "flight.png")
	quit()
