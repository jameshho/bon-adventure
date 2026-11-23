extends SceneTree
## Control tower fixes (23 Nov 2026; airport.gd `tower_deck_floors`, `tower_hatch_carpet`,
## `tower_stair_rails`; player_controller.gd `update_ladder`; interaction_controller.gd
## `_station_near`; docs/guides/TOWN_DESIGN_BRIEF.md "Control tower deck floor, hatch and stair
## rails — 23 November 2026").
##   HOME=<scratch>/home VT_FOCUS=airport VT_SPAWN=none godot --path . --fixed-fps 60 \
##     --resolution 1200x800 --script res://docs/evidence/tower-fixes-20261123/verify.gd
## With a window it also writes the PNG views into this folder (overwrites them); headless it
## only checks. Checks: deck floor on all four sides; no carpet over the hatch; taking the ladder
## from the top (walking into the hatch with W, or S) climbs down without bouncing back up and
## does not climb back up while W is still held at the foot; climbing up from the foot still steps
## off at the top, and W still held then walks on away from the hatch (the view turns); the radar dots show only on their own floor and in sight; the new stair
## balustrades stand in the gap between the flights, clear of every tread.
const FOLDER := "res://docs/evidence/tower-fixes-20261123/"
var failures := 0
var checks := 0
var game
var room: Node3D

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
	else:
		print("ok: ", label)

func key(code: int, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)

func box_of(node: Node) -> AABB:
	var out := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		var b: AABB = (room.global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out

func ly(p: Node3D) -> float:
	return room.to_local(p.global_position).y

func run() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.interaction.set_physics_process(false)
	for i in 3: await physics_frame
	room = game.apartment.get_node("Airport/ControlTower/Interior")
	# 1. Deck floor on all four sides (a mesh just under the deck surface at each side's middle).
	for probe in [Vector3(0, 21.97, -6.6), Vector3(0, 21.97, 6.6), Vector3(6.6, 21.97, 0), Vector3(-6.6, 21.97, 0)]:
		var hit := false
		for child in room.get_children():
			if child.name.begins_with("Observation deck floor") or child.name.begins_with("@"):
				var b := box_of(child)
				if b.size.y < .1 and b.has_point(probe): hit = true
		check(hit, "deck floor mesh at %s" % probe)
	# 2. Carpet: nothing drawn over the hatch opening at floor level.
	var over := []
	for child in room.get_children():
		var b := box_of(child)
		if b.size != Vector3.ZERO and b.position.y > 21.5 and b.position.y < 22.1 and b.has_point(Vector3(-3.25, b.position.y + .005, -.5)):
			over.append(child.name)
	check(over.is_empty(), "nothing covers the hatch (%s)" % [over])
	# 3. Ladder from the top.
	var lad: Node3D = room.get_node("Ladder")
	var player = game.player
	var out: Vector3 = lad.global_basis.z.normalized()
	var yaw := atan2(out.x, out.z)   # camera forward = toward the ladder's wall
	player.camera_yaw = yaw
	player.camera_rig.rotation.y = yaw
	for mode in ["W", "S"]:
		player.global_position = lad.to_global(Vector3(0, 5.55, 1.95))
		player.velocity = Vector3.ZERO
		for i in 20: await physics_frame
		check(absf(ly(player) - 22.0) < .2, "%s: player stands on the control-room floor at the hatch (%.2f)" % [mode, ly(player)])
		var code := KEY_W if mode == "W" else KEY_S
		key(code, true)
		var peak := -INF
		var low := INF
		var grabbed := false
		for i in 360:
			await physics_frame
			peak = maxf(peak, ly(player))
			low = minf(low, ly(player))
			grabbed = grabbed or player.ladder_node != null
		var held_y := ly(player)
		key(code, false)
		check(grabbed, "%s at the head takes the ladder" % mode)
		check(peak < 22.4, "%s: no bounce off the top (peak %.2f)" % [mode, peak])
		check(low < 16.8, "%s: climbs down to the empty level (low %.2f)" % [mode, low])
		check(held_y < 16.9, "%s: still at the foot while the key is held (y %.2f)" % [mode, held_y])
		for i in 20: await physics_frame
	# Up from the foot still works and steps off onto the control-room floor.
	player.global_position = lad.to_global(Vector3(0, .05, .5))
	player.velocity = Vector3.ZERO
	for i in 10: await physics_frame
	key(KEY_W, true)
	var top := -INF
	for i in 600:
		await physics_frame
		top = maxf(top, ly(player))
	key(KEY_W, false)
	for i in 60: await physics_frame
	var end := room.to_local(player.global_position)
	check(top >= 21.9 and absf(end.y - 22.0) < .35 and end.x > -2.55, "W from the foot climbs up, steps off and walks on away from the hatch with W still held (%s)" % end)
	# 4. Radar dots (station indicator): own floor and in sight only.
	var display: Node = room.get_node("Radar display/Interactable")
	var scope: Node = room.get_node("Radar scope/Interactable")
	var feet := func(p: Vector3) -> Vector3: return room.to_global(p)
	check(game.interaction._station_near(display, feet.call(Vector3(-2.2, 22.0, 2.2))), "display dot shows from the control room in front of it")
	check(not game.interaction._station_near(display, feet.call(Vector3(6.6, 22.0, 6.6))), "display dot hidden from the deck (behind the glass)")
	check(not game.interaction._station_near(display, feet.call(Vector3(10.0, 0.0, 0.0))), "display dot hidden from the ground beside the tower")
	check(not game.interaction._station_near(scope, feet.call(Vector3(1.5, 22.0, 1.0))), "radar-room dot hidden from the control room above")
	check(not game.interaction._station_near(scope, feet.call(Vector3(6.6, 22.0, -6.6))), "radar-room dot hidden from the deck")
	# 5. Balustrades: every new part stands in the gap between the flights (x -2.52 .. -2.08) or on
	# the empty level's guard line (z 1.6), never over a tread.
	var holder: Node3D = room.get_node("Stair balustrades")
	var stray := []
	for m in holder.get_children():
		var b := box_of(m)
		var in_gap := b.position.x > -2.52 and b.end.x < -2.08
		var top_guard := b.position.y >= 16.5 - .01 and absf(b.get_center().z - 1.6) < .06
		if not (in_gap or top_guard): stray.append([m.name, b])
	check(holder.get_child_count() > 90 and stray.is_empty(), "%d balustrade parts, all clear of the treads %s" % [holder.get_child_count(), stray.slice(0, 3)])
	print("TOWER FIXES CHECKS: ", checks, " checks, ", failures, " failures")
	if DisplayServer.get_name() != "headless":
		await renders()
	print("TOWER FIXES VERIFY: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

func renders() -> void:
	game.set_process(true)
	game.player.visible = false
	game.hud.hide()
	var cycle = game.day_night
	cycle.pause()
	cycle.set_time(13 * 60 + 44)
	var camera := Camera3D.new()
	camera.near = .05
	camera.fov = 62
	game.add_child(camera)
	camera.current = true
	# [file, eye (room-local), target (room-local)]
	var views := [
		["deck_from_outside_se", Vector3(-12, 27, -13), Vector3(0, 22.5, 0)],
		["deck_north_west", Vector3(13, 27, 13), Vector3(0, 22.5, 0)],
		["deck_along_north", Vector3(6.6, 23.7, 6.6), Vector3(-6.6, 23.0, 6.6)],
		["hatch_from_above", Vector3(-1.2, 24.6, -.5), Vector3(-3.2, 21.0, -.5)],
		["stairs_ground_up", Vector3(-3.3, 1.6, -3.5), Vector3(-3.0, 3.2, 1.5)],
		["stairs_landing_turn", Vector3(-3.4, 4.6, -1.8), Vector3(-1.6, 3.4, 2.2)],
		["stairs_flight_b", Vector3(-1.1, 4.4, 3.2), Vector3(-1.5, 5.6, -2.4)],
		["stairs_from_above", Vector3(-3.1, 9.5, -3.3), Vector3(-2.3, 6.0, 1.0)],
		["empty_level_guard", Vector3(-3.4, 18.3, 3.2), Vector3(-1.4, 16.6, -1.5)],
	]
	for v in views:
		camera.global_position = room.to_global(v[1])
		camera.look_at(room.to_global(v[2]), Vector3.UP)
		for i in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + v[0] + ".png"))
		print("TOWER VIEW ", v[0])
