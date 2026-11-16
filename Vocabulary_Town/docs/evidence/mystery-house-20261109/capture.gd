extends SceneTree
## Rendered views of the Mystery House (9 Nov 2026) at noon: outside, the hall, the mystery room
## and its dome, a top-down view of the site, then the Mystery Doors game through the player's
## camera (10 Nov 2026: the card at the start in the mystery room, the room behind, the change,
## a toad mid-hop, the clue again, then swap-before / swap-after at the right door and the one
## door behind in the hall), then in the endless hall (the
## clue again, the open door, the card just through the doorway and the door slamming behind
## (pacing, 10 Nov 2026), the view after the step back and the one door behind it, then the doors'
## front and back faces and the mystery room at 1 a.m. and at noon, 10 Nov 2026). Needs a window (kept on top: a hidden
## window stops rendering); isolated HOME:
## HOME=<scratch>/home VT_FOCUS="mystery, bank, library" VT_SPAWN=none godot --path . --always-on-top --resolution 1600x1000 --script res://docs/evidence/mystery-house-20261109/capture.gd [-- <out folder>]
## Writes <view>.png into the out folder (default: next to this script).
const Mystery := preload("res://scripts/buildings/mystery.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
var out := "res://docs/evidence/mystery-house-20261109/"

func _initialize(): run.call_deferred()

func shot(title: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var path := out.path_join(title + ".png")
	root.get_texture().get_image().save_png(path)
	print("MYSTERY CAPTURE: ", path, " at ", Time.get_ticks_msec() / 1000.0, " s")

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.visible = false
	await process_frame
	for child in game.get_children():
		if child is CanvasLayer:
			child.visible = false
	if game.day_night != null:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var house: Node3D = ModularTown.building(game.apartment, "mystery")
	if house == null:
		print("MYSTERY CAPTURE: the mystery unit is not loaded")
		quit(1)
		return
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	camera.fov = 62
	var f := Mystery.FLOOR
	var views := [
		["front", Vector3(6, 3.2, -36), Vector3(0, 6.5, -10)],
		["aerial-front", Vector3(-30, 26, -42), Vector3(0, 5, 0)],
		["aerial-rear", Vector3(32, 22, 38), Vector3(0, 5, 0)],
		["hall-shapes", Vector3(-5.0, f + 1.9, -11.5), Vector3(11, f + 2.4, -9.0)],
		["hall-colors", Vector3(5.0, f + 1.9, -11.5), Vector3(-11, f + 2.4, -9.0)],
		["hall-arch", Vector3(0, f + 1.8, -14.2), Vector3(0, f + 2.4, 0)],
		["room-doors", Vector3(0, f + 2.0, -4.0), Vector3(0, f + 2.0, 11)],
		["room-dome", Vector3(0, f + 1.6, -4.2), Vector3(0, f + 16, 3.5)],
		["room-luna", Vector3(-5, f + 2.0, 7), Vector3(8.6, f + 1.4, -2.6)],
		["room-zodiac", Vector3(-6, f + 2.2, 2.0), Vector3(11.5, f + 5.8, 3.0)],
		["room-doorwall", Vector3(0, f + 2.3, 2.5), Vector3(0, f + 3.0, 11)],
	]
	for view in views:
		camera.global_position = house.to_global(view[1])
		camera.look_at(house.to_global(view[2]), Vector3.UP)
		await shot(view[0])
	# Top-down view of the site: north up, west left (as on the town map).
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 90.0 * 1.3
	camera.far = 2000
	var town: Node3D = game.apartment
	camera.global_position = town.to_global(Vector3(122, 200, 82))
	camera.look_at(town.to_global(Vector3(122, 0, 82)), Vector3(0, 0, 1))
	await shot("site-top")
	# The game, seen as the player sees it.
	camera.queue_free()
	var cameras: Array = game.player.find_children("*", "Camera3D", true, false)
	if not cameras.is_empty():
		cameras[0].make_current()
	for child in game.get_children():
		if child is CanvasLayer:
			child.visible = true
	game.player.visible = true
	game.player.set_physics_process(true)
	var session = game.get_node("MysterySession")
	session.offered = true
	# The game starts where the player talked to Luna (user, 10 Nov 2026): round 1 at the
	# mystery room's own doors.
	session.zone.place_player(house, Vector3(1.5, Mystery.FLOOR, Mystery.DOOR_WALL - 5.0), Mystery.START_LOOK)
	for i in 20: await process_frame
	session.start_game()
	for i in 30: await process_frame
	await shot("game-card")
	var player = game.player
	player.camera_yaw += PI
	for i in 40: await process_frame
	await shot("room-behind-start")
	player.camera_yaw -= PI
	for i in 40: await process_frame
	var first: Dictionary = session.rounds[0]
	session.door_used(session.doors[(first.target + 1) % 3].leaf)
	# The change (0.95 s, user 10 Nov 2026): the player shrinking in the puff, then the toad.
	while player.visual.scale.x > 0.8 and not session.is_toad():
		await process_frame
	await shot("game-toad-change")
	while session._toad_phase != "toad":
		await process_frame
	for i in 6: await process_frame
	session._hop = 0.22
	await process_frame
	await shot("game-toad")
	while session.state != "choose":
		await process_frame
	for i in 10: await process_frame
	await shot("game-wrong")
	session.host.close_dialogue()
	# The swap at the right door (user approval, 10 Nov 2026): the view just before (the mystery
	# room) and just after (the hall's wall B, its door starting to open) should look the same.
	session.zone.place_player(house, Vector3(Mystery.DOOR_X[first.target] + 0.4, Mystery.FLOOR, Mystery.DOOR_WALL - 2.2), Mystery.START_LOOK)
	for i in 30: await process_frame
	await shot("swap-before")
	session.door_used(session.doors[first.target].leaf)
	await shot("swap-after")
	player.camera_yaw += PI
	for i in 40: await process_frame
	await shot("hall-behind-start")
	player.camera_yaw -= PI
	for i in 60: await process_frame
	await shot("hall-open")
	# Pacing (10 Nov 2026): just through the doorway the card shows the next clue; clear of the
	# leaf's swing the door slams behind the player.
	var past := float(Mystery.HALL_WALLS[1]) + Mystery.WALL
	session.zone.place_player(house, Vector3(Mystery.DOOR_X[first.target], Mystery.ENDLESS_FLOOR, past + 1.0), Mystery.START_LOOK)
	for i in 12: await process_frame
	await shot("pacing-through")
	session.zone.place_player(house, Vector3(Mystery.DOOR_X[first.target], Mystery.ENDLESS_FLOOR, past + 2.8), Mystery.START_LOOK)
	while session.state != "shut":
		await process_frame
	player.camera_yaw += PI
	for i in 4: await process_frame
	await shot("pacing-slam")
	player.camera_yaw -= PI
	while not (session.state == "choose" and session.current == 1):
		await process_frame
	for i in 10: await process_frame
	await shot("hall-after-step")
	player.camera_yaw += PI
	for i in 40: await process_frame
	await shot("hall-behind")
	# The ending: a one-door game to the treasure, the diamond's flight, the way out.
	player.camera_yaw -= PI
	session.end_activity()
	while session.zone.fading:
		await process_frame
	session.host.close_dialogue()
	var Board = preload("res://scripts/learning/activity_board.gd")
	Board.shared().set_rounds(session.ACTIVITY, 1)
	await session.start_game()
	session.host.close_dialogue()
	var only: Dictionary = session.rounds[0]
	session.zone.place_player(house, Vector3(Mystery.DOOR_X[only.target], Mystery.FLOOR, Mystery.DOOR_WALL - 2.2), Mystery.START_LOOK)
	for i in 10: await process_frame
	session.door_used(session.doors[only.target].leaf)
	for i in 60: await process_frame
	await shot("treasure-through-door")
	session.zone.place_player(house, Vector3(Mystery.DOOR_X[only.target], Mystery.ENDLESS_FLOOR, float(Mystery.HALL_WALLS[1]) + Mystery.WALL + 8.0), Mystery.START_LOOK)
	while session.state != "treasure":
		await process_frame
	session.zone.place_player(house, Vector3(0, Mystery.ENDLESS_FLOOR, Mystery.TREASURE_Z - 3.2), Mystery.START_LOOK)
	player.camera_pitch = -0.05
	for i in 30: await process_frame
	await shot("treasure-chest")
	session.chest_used(session.chest)
	while session._timer < 1.4:
		await process_frame
	await shot("treasure-shake")
	while session._timer < 2.35:
		await process_frame
	await shot("treasure-surge")
	while session.state != "exit":
		await process_frame
	for i in 40: await process_frame
	await shot("treasure-open")
	var out: int = session.exit_door
	session.zone.place_player(house, Vector3(Mystery.DOOR_X[out], Mystery.ENDLESS_FLOOR, float(Mystery.HALL_WALLS[2]) + Mystery.WALL + 1.2), Mystery.START_LOOK)
	while session.state != "return" or session.zone.fading:
		await process_frame
	player.camera_yaw += PI
	for i in 20: await process_frame
	await shot("room-return")
	Board.shared().set_rounds(session.ACTIVITY, 0)
	# The doors' faces (10 Nov 2026) and the mystery room by night and by day (lighting fix,
	# 10 Nov 2026). The indoor probe (day_night.gd) follows the player, so the hidden player
	# stands at each view's spot while the ambient settles.
	session.end_activity()
	while session.zone.fading:
		await process_frame
	session.host.close_dialogue()
	var still := Camera3D.new()
	root.add_child(still)
	still.make_current()
	still.fov = 62
	for child in game.get_children():
		if child is CanvasLayer:
			child.visible = false
	player.visible = false
	player.set_physics_process(false)
	var ef := Mystery.ENDLESS_FLOOR
	var wb := float(Mystery.HALL_WALLS[1]) + Mystery.WALL
	var stills := [
		["door-front", Vector3(0, f + 2.3, Mystery.DOOR_WALL - 3.8), Vector3(0, f + 2.0, Mystery.DOOR_WALL), 12],
		["door-front-oblique", Vector3(-3.4, f + 1.5, Mystery.DOOR_WALL - 2.3), Vector3(-6.5, f + 1.8, Mystery.DOOR_WALL), 12],
		["door-back", Vector3(0.8, ef + 2.2, wb + 4.6), Vector3(0, ef + 2.0, wb), 12],
		["door-back-open", Vector3(-2.6, ef + 1.9, wb + 4.4), Vector3(-6.0, ef + 1.8, wb + 0.6), 12],
		["night-room-doors", Vector3(0, f + 2.0, -4.0), Vector3(0, f + 2.0, 11), 1],
		["night-room-corner", Vector3(-9.5, f + 2.2, 9.5), Vector3(8.6, f + 1.4, -2.6), 1],
		["night-room-side", Vector3(9.0, f + 2.0, 8.0), Vector3(-2.0, f + 3.0, -4.0), 1],
		["day-room-corner", Vector3(-9.5, f + 2.2, 9.5), Vector3(8.6, f + 1.4, -2.6), 12],
	]
	for view in stills:
		var hall_view: bool = view[1].y < 0.0
		session._show_hall(hall_view)
		session._reset_hall()
		if view[0] == "door-back":
			session._set_back(session.hall_walls[1], 1)
		elif view[0] == "door-back-open":
			session._set_back(session.hall_walls[1], 2)
			session.hall_walls[1][2].leaf.open_now()
		game.day_night.set_time(view[3] * 60.0)
		player.global_position = house.to_global(Vector3(view[1].x, ef if hall_view else f, view[1].z))
		await create_timer(1.8).timeout
		still.global_position = house.to_global(view[1])
		still.look_at(house.to_global(view[2]), Vector3.UP)
		print("MYSTERY CAPTURE indoor ", view[0], " ", game.day_night.indoor)
		await shot(view[0])
	print("MYSTERY CAPTURE done")
	quit()
