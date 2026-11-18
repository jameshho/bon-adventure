extends SceneTree
## Indoor fill probe memory (18 Nov 2026): does the "Indoor fill" ReflectionProbe
## (scripts/world/day_night.gd) cause the texture memory jump when the player walks indoors?
## One run, Low, full town, noon: video/texture memory on the street, in the home guest-suite
## bedroom with the probe held back (day_night.room_probe detached), the same spot with the probe
## on, and the street again. Then, at 21:00, rendered views of the bedroom, the supermarket aisle
## and the supermarket door looking out, saved as <VT_TAG>-*.png in this folder (overwrites them).
## Prints "FILLMEM" lines only. Graphics, isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_TAG=after godot --path . --resolution 1560x720 --script res://docs/evidence/indoor-fill-memory-20261118/measure.gd
const ModularTown := preload("res://scripts/world/modular_town.gd")
const DIR := "res://docs/evidence/indoor-fill-memory-20261118/"
const BED_SPOT := Vector3(-4.4, 0.1, -9.6)
const BED_LOOK := Vector3(-1.0, 0.0, 0.0)
var game: Node
var tag := OS.get_environment("VT_TAG")

func _initialize(): run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func info(what: int) -> float:
	return RenderingServer.get_rendering_info(what) / 1048576.0

func measure(label: String) -> void:
	await frames(120)
	await RenderingServer.frame_post_draw
	var cycle = game.day_night
	var probe: ReflectionProbe = cycle.room_probe
	print("FILLMEM %s: video %.1f MB, textures %.1f MB, buffers %.1f MB | indoor %.2f, probe %s" % [label,
		info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
		info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),
		info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED),
		cycle.indoor,
		"detached" if probe == null else ("visible, size %s" % probe.size.snapped(Vector3.ONE * 0.1) if probe.visible else "hidden")])

func shot(file: String) -> void:
	if tag == "":
		return
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR + tag + "-" + file))
	print("FILLMEM shot ", tag + "-" + file)

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	# macOS stops drawing a covered window, which stalls the frame waits below.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(40)
	var cycle = game.day_night
	cycle.pause()
	cycle.set_time(12 * 60)
	var player = game.player
	var settings = preload("res://scripts/core/game_settings.gd").shared()
	print("FILLMEM graphics=%s window=%s 3d_scale=%.2f msaa=%d atlas size=%s count=%s probes=%d" % [settings.graphics,
		root.get_visible_rect().size, root.scaling_3d_scale, root.msaa_3d,
		ProjectSettings.get_setting("rendering/reflections/reflection_atlas/reflection_size"),
		ProjectSettings.get_setting("rendering/reflections/reflection_atlas/reflection_count"),
		root.find_children("*", "ReflectionProbe", true, false).size()])
	var street_pos: Vector3 = player.global_position
	await frames(240)
	await measure("street")
	var town: Node3D = game.apartment
	var home: Node3D = ModularTown.building(town, "home")
	var market: Node3D = ModularTown.building(town, "supermarket")

	# Indoors with the probe held back: day_night skips a null room_probe.
	var probe: ReflectionProbe = cycle.room_probe
	cycle.room_probe = null
	probe.visible = false
	_place(player, home.to_global(BED_SPOT), home.global_basis * BED_LOOK)
	await measure("home bedroom, probe off")
	cycle.room_probe = probe
	await measure("home bedroom, probe on")
	player.global_position = street_pos
	await measure("street again")

	# Rendered views at night, when the indoor fill differs most from the outdoor ambient.
	game.hud.hide()
	cycle.set_time(21 * 60)
	_place(player, home.to_global(BED_SPOT), home.global_basis * BED_LOOK)
	await frames(150)
	await shot("home-bedroom-2100.png")
	player.visible = false
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.make_current()
	player.global_position = market.to_global(Vector3(-30, 0.1, 44))
	cam.fov = 76.0
	cam.global_position = market.to_global(Vector3(-28.3, 2.5, 42))
	cam.look_at(market.to_global(Vector3(-37, 1.5, 48)))
	await frames(150)
	await shot("supermarket-aisle-2100.png")
	cam.fov = 70.0
	cam.global_position = market.to_global(Vector3(-33, 1.8, 41))
	cam.look_at(market.to_global(Vector3(-33, 1.4, 20)))
	await shot("supermarket-door-2100.png")
	await measure("supermarket, 21:00")
	quit()

func _place(player, at: Vector3, forward: Vector3) -> void:
	player.global_position = at
	player.rotation.y = atan2(-forward.x, -forward.z)
	player.camera_yaw = player.rotation.y
	player.reset_camera()
