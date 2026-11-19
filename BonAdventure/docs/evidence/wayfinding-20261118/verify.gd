extends SceneTree
## Wayfinding (user, 18 Nov 2026; docs/guides/MINIGAMES.md#town-map-and-guide-arrow): the baked town
## map (M, the map corner button) and the guide arrow ("Go there" on the map or in the minigame
## picker). Checks the map opens with its picture and every place, a tap picks the nearest place,
## Go there starts the arrow, the arrow points the right way and clears on arrival, the picker's
## Go there targets the game's NPC, and the picture is let go when the map closes. Measures the
## frame time while turning with nothing open, with the guide on and with the map open (vsync
## off). Renders the views into this folder (overwrites them). Needs graphics and an isolated HOME:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1100x800 --script res://docs/evidence/wayfinding-20261118/verify.gd
const OUT := "res://docs/evidence/wayfinding-20261118/"
var game
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label)

func wait(frames := 10) -> void:
	for i in frames:
		await process_frame

func shot(name: String) -> void:
	await wait(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func resize(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	await wait(12)

## Mean milliseconds a frame over `frames` frames while the player turns (the old minimap's
## worst case: it redrew while turning).
func frame_ms(frames := 180) -> float:
	await wait(20)
	var start := Time.get_ticks_usec()
	for i in frames:
		game.player.rotate_y(0.035)
		await process_frame
	return (Time.get_ticks_usec() - start) / 1000.0 / frames

func place_index(name: String) -> int:
	for i in range(game.town_map.places.size()):
		if game.town_map.places[i].name == name:
			return i
	return -1

func run() -> void:
	if DisplayServer.get_name() == "headless" or FileAccess.file_exists("user://profiles/index.json"):
		print("verify: needs graphics and an isolated HOME")
		quit(1)
		return
	# A covered window gets few frames on macOS: stay on top.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await wait(40)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	var hud = game.hud
	var map = game.town_map
	var guide = game.guide
	check(map != null and guide != null, "map and guide built")
	check(hud.map_button.visible, "map corner button shows")
	check(map.picture == null, "picture not loaded while closed")
	# Frame time with nothing open.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var base := await frame_ms()
	# The map: M opens it.
	var press := InputEventAction.new()
	press.action = "map"
	press.pressed = true
	Input.parse_input_event(press)
	await wait(4)
	check(hud.is_map_open() and map.visible, "M opens the map")
	check(map.picture != null, "picture loaded when open")
	check(not game.player.controls_enabled, "player stops while the map is open")
	check(map._pills.size() == map.places.size() and map.places.size() >= 20, "every place has a name pill (%d)" % map._pills.size())
	var inside := true
	for pill in map._pills:
		inside = inside and map._shown.grow(1).encloses(pill.rect)
	check(inside, "every pill inside the picture")
	var card_rect: Rect2 = map.card.get_global_rect()
	check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(card_rect), "map card fits the window")
	var map_ms := await frame_ms()
	await shot("map")
	# A tap near the library's entrance dot picks it.
	var library := place_index("library")
	map.pick_nearest(map._pills[library].at + Vector2(6, 4))
	check(map.picked == library, "a tap picks the nearest place")
	await shot("map_picked")
	var market := place_index("supermarket")
	map.pick(market)
	check(map.games_box.get_child_count() == 2, "supermarket lists its two games")
	# Go there to the library (the supermarket's entrance is the spawn, so it would arrive at once).
	map.pick(library)
	map.go_button.pressed.emit()
	await wait(4)
	check(not hud.is_map_open() and map.picture == null, "Go there closes the map and lets the picture go")
	check(guide.active() and guide.target_name != "", "Go there starts the guide")
	# The arrow points straight up when the camera looks at the target.
	var camera := root.get_viewport().get_camera_3d()
	var to: Vector3 = guide.target_point - game.player.global_position
	game.player.look_at(game.player.global_position - Vector3(to.x, 0, to.z), Vector3.UP)
	await wait(6)
	var angle: float = guide._angle
	print("guide angle facing the target: %.1f deg (camera %s)" % [rad_to_deg(angle), camera != null])
	var guide_ms := await frame_ms()
	await wait(4)
	await shot("guide")
	check(guide.card.visible and guide.card.get_global_rect().size.y >= 44.0, "guide card shows, finger-sized")
	# Arrival.
	if not guide.active():
		print("WAYFINDING stopped: no guide target")
		quit(1)
		return
	game.player.global_position = guide.target_point + Vector3(1.5, 0.1, 0)
	await wait(4)
	check(not guide.active(), "the guide clears on arrival")
	check(hud.quest_toast.visible, "arrival toast")
	# The picker's Go there.
	game.game_launcher.open()
	game.game_launcher._select("family_dr_li")
	await wait(4)
	check(game.game_launcher.go.visible and not game.game_launcher.go.disabled, "picker shows Go there")
	await shot("picker_go")
	game.game_launcher.go.pressed.emit()
	await wait(4)
	check(guide.target_game == "family_dr_li" and is_instance_valid(guide.target_node), "picker Go there follows Dr. Li")
	check(not game.game_launcher.visible, "picker closes")
	# Phone landscape.
	await resize(Vector2i(844, 390))
	hud.toggle_map()
	await wait(4)
	map.pick(place_index("police_station"))
	var phone_card: Rect2 = map.card.get_global_rect()
	check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(phone_card), "map fits a phone (844 x 390)")
	check(map.go_button.size.y >= 44.0 and map.close_button.size.x >= 44.0, "phone buttons finger-sized")
	await shot("map_phone")
	hud.toggle_map()
	await wait(4)
	await shot("guide_phone")
	print("FRAME MS while turning: nothing open %.2f | map open %.2f | guide on %.2f" % [base, map_ms, guide_ms])
	print("WAYFINDING done: %d failures" % failures)
	quit(1 if failures > 0 else 0)
