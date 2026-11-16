extends SceneTree
## Mystery House and Mystery Doors (9 Nov 2026; design: docs/guides/TOWN_DESIGN_BRIEF.md "Mystery House
## and Mystery Doors"). The building (doors, Luna, roof over the room, map site, zone, room name,
## the hidden endless hall, right-hand hinges) and a game played through the real session and
## card: locked doors outside a game, a new door look on leaving the house, the round rules
## (shape, colour, both), the game starting in the endless hall with the mystery room's doors as
## they were, one door behind the player, a wrong door (a ~0.95 s change, a toad for 3 s that hops, the clue again
## highlighted, nothing reset), a right door (opens away, slams behind the player, who is moved
## back one room with the same view), the door behind staying shut, progress counting only first
## tries, leaving from the hall, the final line back with Luna, a language change while a toad.
## Uses Main, which saves progress: run with an isolated HOME (README). Works with the full town
## or VT_FOCUS=mystery (report a focused run as focused).
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/mystery-house-20261109/verify.gd
const Mystery := preload("res://scripts/buildings/mystery.gd")
const Session := preload("res://scripts/learning/mystery_session.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const RoomNames := preload("res://scripts/world/room_names.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
var failures := 0
var checks := 0
var game
var session
var house: Node3D

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func finish() -> void:
	print("MYSTERY HOUSE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Real frames until `done` returns true (or `frames` pass).
func wait_for(done: Callable, frames := 600) -> bool:
	for i in frames:
		if done.call():
			return true
		await physics_frame
	return done.call()

func leaf(i: int) -> Node3D:
	return session.doors[i].leaf

func hall_leaf(wall: int, i: int) -> Node3D:
	return session.hall_walls[wall][i].leaf

## The [colour, shape] each door of hall wall `wall` shows.
func looks(wall: int) -> Array:
	var out: Array = []
	for door in session.hall_walls[wall]:
		out.append([str(door.leaf.get_meta("door_color")), str(door.leaf.get_meta("door_shape"))])
	return out

## The one door of hall wall `wall` shown on its far side (-1 none, -2 more than one).
func only_back(wall: int) -> int:
	var shown := -1
	for i in 3:
		var door: Dictionary = session.hall_walls[wall][i]
		if door.back.visible and not door.cover.visible:
			shown = i if shown == -1 else -2
		elif door.back.visible or not door.cover.visible:
			return -2
	return shown

## Puts the player at a house-local spot (as if walked there), facing on (+z).
func zone_place(spot: Vector3) -> void:
	session.zone.place_player(house, spot, Mystery.START_LOOK)

## After leaving mid-game: across the fortune table from Luna (clear of the table and her),
## facing her, and she has said the goodbye.
func at_luna() -> bool:
	var p: Vector3 = house.to_local(game.player.global_position)
	var flat := Vector2(p.x, p.z)
	var table := Vector2(Mystery.LUNA_SPOT.x - 1.3, Mystery.LUNA_SPOT.z + 1.0)
	var luna_at := Vector2(Mystery.LUNA_SPOT.x, Mystery.LUNA_SPOT.z)
	var yaw: float = game.player.rotation.y
	var forward: Vector3 = Vector3(-sin(yaw), 0, -cos(yaw))
	var to_luna: Vector3 = session.luna.global_position - game.player.global_position
	to_luna.y = 0.0
	var across := (table - flat).normalized().dot((luna_at - table).normalized()) > 0.95
	return flat.distance_to(Vector2(Mystery.GUEST_SPOT.x, Mystery.GUEST_SPOT.z)) < 0.3 and flat.distance_to(table) > 1.2 \
		and across and forward.dot(to_luna.normalized()) > 0.95 and session.host.line_id == "mystery.sorry_leave"

## From INSIDE, steps out through the arch into the entrance hall (the real doorway Area3D
## notices it); stops stepping while the controls are off (a question). `ended_line`: Luna's
## line the frame the game ended (walking on 3 m closes a goodbye: shop_order_panel WALK_OFF).
var ended_line := "-"
func walk_out() -> void:
	zone_place(Mystery.INSIDE)
	await physics_frame
	ended_line = "-"
	var goal: Vector3 = house.to_global(Vector3(0, Mystery.FLOOR, Mystery.HALL_REAR - 5.0))
	for i in 140:
		var step: Vector3 = goal - game.player.global_position
		step.y = 0.0
		if game.player.controls_enabled and step.length() > 0.1:
			game.player.global_position += step.normalized() * 0.08
		await physics_frame
		if ended_line == "-" and session.state == "":
			ended_line = "%s|%s" % [session.host.line_id, game.shop_panel.has_choices()]

## A one-door game (Board rounds set to 1) played to "return": out of a mystery room door after
## the treasure.
func play_to_return() -> void:
	Board.shared().set_rounds(Session.ACTIVITY, 1)
	zone_place(Vector3(0, Mystery.FLOOR, Mystery.DOOR_WALL - 2.5))
	await session.start_game()
	if session.rounds.size() != 1:
		return
	var target: int = session.rounds[0].target
	leaf(target).use()
	await wait_for(func() -> bool: return hall_leaf(1, target).is_open(), 60)
	zone_place(Vector3(Mystery.DOOR_X[target], Mystery.ENDLESS_FLOOR, float(Mystery.HALL_WALLS[1]) + Mystery.WALL + 8.0))
	await wait_for(func() -> bool: return session.state == "treasure", 300)
	session.chest.use()
	await wait_for(func() -> bool: return session.state == "exit", 400)
	await wait_for(func() -> bool: return hall_leaf(2, session.exit_door).is_open(), 60)
	zone_place(Vector3(Mystery.DOOR_X[session.exit_door], Mystery.ENDLESS_FLOOR, float(Mystery.HALL_WALLS[2]) + Mystery.WALL + 1.2))
	await wait_for(func() -> bool: return session.state == "return" and not session.zone.fading, 300)

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	session = game.get_node_or_null("MysterySession")
	house = ModularTown.building(game.apartment, "mystery")
	check(house != null and session != null, "mystery unit loaded and the session exists")
	if house == null or session == null or session.host == null:
		finish()
		return
	# --- The building ------------------------------------------------------------------------
	check(session.luna != null and is_talker(session.luna), "Madame Luna stands in the mystery room and can be talked to")
	check(session.doors.size() == 3, "three mystery doors")
	for i in session.doors.size():
		var door: Dictionary = session.doors[i]
		check(str(door.leaf.get_meta("word_key", "")) == "door" and preload("res://scripts/core/interactable.gd").on(door.leaf) != null, "door %d: word door, an interactable" % i)
		check(door.painted.size() == 3, "door %d: the leaf, its round head and its carving (step door_faces) are painted (%d)" % [i, door.painted.size()])
		check(door.symbols != null and door.symbols.get_child_count() == 4, "door %d: four shape symbols" % i)
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	check(session.hall != null and not session.hall.visible and session.hall_walls.size() == 3, "the endless hall: hidden, three door walls")
	var hall_ok := true
	for w in session.hall_walls:
		hall_ok = hall_ok and w.size() == 3 and str(w[0].leaf.get_meta("word_key", "")) == "door" and w[0].painted.size() == 3
	check(hall_ok, "every hall wall has three painted doors")
	var below: Vector3 = house.to_global(Vector3(0, Mystery.ENDLESS_FLOOR + 1.0, 6.0))
	var hall_roof := space.intersect_ray(PhysicsRayQueryParameters3D.create(below, below + Vector3.UP * 20.0))
	var hall_floor := space.intersect_ray(PhysicsRayQueryParameters3D.create(below, below + Vector3.DOWN * 3.0))
	check(not hall_roof.is_empty() and not hall_floor.is_empty(), "the hall has a solid floor and ceiling")
	check(game.zones.resolve_global(below) == "mystery_house", "the hall is in zone mystery_house")
	# A triangle has three corners (a CylinderMesh keeps at least four sides: render review).
	var corners := {}
	var tri: Mesh = (session.doors[0].symbols.get_node("triangle/Fill") as MeshInstance3D).mesh
	for v in tri.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		corners[Vector2(snappedf(v.x, 0.001), snappedf(v.y, 0.001))] = true
	check(corners.size() == 3, "the triangle symbol has 3 corners (%d)" % corners.size())
	var start: Vector3 = house.to_global(Mystery.START)
	var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(start + Vector3.UP, start + Vector3.UP * 30.0))
	check(not up.is_empty(), "a roof over the middle of the mystery room (indoor light probe)")
	check(game.reference_layout.site_bounds.has("MysteryHouse"), "map site bound MysteryHouse")
	var on_map := false
	for entry in game.reference_layout.entries:
		if entry.node == house and str(entry.title) == "MYSTERY HOUSE":
			on_map = true
	check(on_map, "map entry MYSTERY HOUSE")
	check(game.zones.resolve_global(start) == "mystery_house", "zone mystery_house in the room (%s)" % game.zones.resolve_global(start))
	game.player.global_position = start + Vector3.UP * 0.1
	check(RoomNames.room_at(game) == "Mystery House", "room name Mystery House (%s)" % RoomNames.room_at(game))
	# --- Round rules -----------------------------------------------------------------------------
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var kinds: Array = []
	for r in Session.make_rounds(6, rng):
		kinds.append(r.kind)
	check(kinds == ["shape", "shape", "color", "color", "both", "both"], "6 rounds: shape, colour, both (%s)" % [kinds])
	var bad := 0
	for n in 300:
		var kind: String = Session.KINDS[n % 3]
		var r: Dictionary = Session.make_round(kind, rng)
		var target: Array = r.doors[r.target]
		var same_color := 0
		var same_shape := 0
		var exact := 0
		for i in 3:
			if i == r.target:
				continue
			var d: Array = r.doors[i]
			same_color += 1 if d[0] == target[0] else 0
			same_shape += 1 if d[1] == target[1] else 0
			exact += 1 if d == target else 0
		if exact > 0 or (kind == "shape" and same_shape > 0) or (kind == "color" and same_color > 0) or (kind == "both" and (same_color != 1 or same_shape != 1)):
			bad += 1
	check(bad == 0, "300 rounds: the clue always picks exactly one door (%d bad)" % bad)
	var lex = Lexicon.shared()
	var both := {"kind": "both", "doors": [["red", "star"], ["red", "circle"], ["blue", "star"]], "target": 0}
	var texts := {}
	for code in ["es", "en", "zh"]:
		texts[code] = lex.text(Session.clue_ref(both), code)
		check(not texts[code].contains("{") and texts[code] != "", "clue renders in %s: %s" % [code, texts[code]])
	check(texts.es == "Entra por la puerta roja con la estrella.", "Spanish clue: " + texts.es)
	check(Session.tested_words(both) == ["red", "star"], "a both round tests the colour and the shape")
	# --- Locked outside a game -------------------------------------------------------------------
	leaf(0).use()
	check(session.state == "" and session.host.line_id == "mystery.locked", "outside a game a door is locked: Luna says so")
	for i in 30:
		await physics_frame
	check(not leaf(0).is_open(), "the locked door stays shut")
	session.host.close_dialogue()
	# The hinges are on the other side (user, 9 Nov 2026): the right edge, still opening away.
	var hinge: Node3D = leaf(1).get_parent()
	check(hinge.position.x > 1.0 and float(leaf(1).get_meta("swing", 1.0)) == -1.0, "the hinge is on the right edge")
	# A new random look each time the player leaves the house.
	var seen: Array = session.room_looks()
	game.player.global_position = house.to_global(Mystery.INSIDE + Vector3(0, 0.1, 0))
	for i in 3: await process_frame
	game.player.global_position = house.to_global(Vector3(0, 0.1, Mystery.FRONT - 6.0))
	for i in 3: await process_frame
	var fresh: Array = session.room_looks()
	var distinct := {}
	for look in fresh:
		distinct[look[0]] = true
		distinct[look[1]] = true
	check(fresh != seen and distinct.size() == 6, "leaving the house gives the doors a new look (%s)" % [fresh])
	# --- A game: it starts where the player is (user, 10 Nov 2026) ------------------------------
	session.offered = true
	var room_doors: Array = session.room_looks()
	var talk_spot := Vector3(2.0, Mystery.FLOOR, Mystery.DOOR_WALL - 4.0)
	zone_place(talk_spot)
	await physics_frame
	var at_talk: Vector3 = house.to_local(game.player.global_position)
	await session.start_game()
	check(session.state == "choose" and session.current == 0 and game.mystery_card.visible, "the game starts: round 1, card open")
	check(session.rounds.size() == Board.shared().rounds(Session.ACTIVITY), "rounds from activities.json (%d)" % session.rounds.size())
	check(not session.zone.fading and session._in_mystery_room() and house.to_local(game.player.global_position).distance_to(at_talk) < 0.05, "the game starts in place: no fade, no move")
	check(session._room_round and session._round_doors() == session.doors, "round 1 is played at the mystery room's own doors")
	check(session.room_looks() == room_doors and session.rounds[0].doors == room_doors and looks(1) == room_doors, "round 1 uses the mystery room's doors as they were (the hall's wall B matches)")
	check(session.hall.visible and only_back(0) == 1, "the hall waits below, ready: one door behind wall A")
	var round_data: Dictionary = session.rounds[0]
	var dressed := true
	for i in 3:
		var look: Array = round_data.doors[i]
		var door: Dictionary = session.doors[i]
		dressed = dressed and door.material.albedo_color.is_equal_approx(Mystery.COLORS[look[0]]) and door.symbols.get_node(str(look[1])).visible
		for shape in Mystery.SHAPES:
			if shape != look[1]:
				dressed = dressed and not door.symbols.get_node(shape).visible
	check(dressed, "each door shows its colour and one shape")
	check(game.interaction.minigame_running(), "the game counts as running (no word cards)")
	# A wrong door: a ~0.95 s change (the player shrinks, the toad grows), a toad for 3 seconds
	# that can hop about, the same change back, then the clue again, nothing reset.
	var wrong: int = (round_data.target + 1) % 3
	leaf(wrong).use()
	check(session.state == "toad", "a wrong door starts the toad")
	var tps := float(Engine.physics_ticks_per_second)
	var change_frames := 0
	var shrank := false
	while not session.is_toad() and change_frames < 120:
		await physics_frame
		change_frames += 1
		shrank = shrank or game.player.visual.scale.x < 0.5
	check(shrank and not game.player.controls_enabled, "the player shrinks in the puff, controls locked")
	await physics_frame
	check(session.is_toad() and session._toad.scale.x < 0.9 and not game.player.controls_enabled, "the toad grows in the puff, controls still locked")
	while session._toad_phase == "in" and change_frames < 200:
		await physics_frame
		change_frames += 1
	var change_in := change_frames / tps
	check(change_in > 0.8 and change_in < 1.15, "the change into a toad takes about 0.95 s (%.2f s)" % change_in)
	check(session.is_toad() and not game.player.visual.visible and game.player.controls_enabled, "the player is a toad and can move")
	check(game.player.visual.scale.is_equal_approx(Vector3.ONE) or not game.player.visual.visible, "the hidden player model is back to full size")
	check(game.player.speed_override == 0.0, "a sitting toad does not slide")
	session._hop = 0.05
	await physics_frame
	await physics_frame
	var toad: Node3D = session._toad
	check(game.player.speed_override == Session.HOP_SPEED and toad != null and toad.position.y > float(toad.get_meta("floor", 0.0)) + 0.05, "a hop: fast in the air, the toad lifted")
	check(not leaf(wrong).is_open(), "the wrong door stays shut")
	var toad_frames := 2
	while session._toad_phase == "toad" and toad_frames < 400:
		await physics_frame
		toad_frames += 1
	var seconds := toad_frames / tps
	check(seconds > 2.8 and seconds < 3.3, "the toad lasts about 3 s (%.2f s)" % seconds)
	check(not game.player.controls_enabled, "controls locked for the change back")
	var out_frames := 0
	var toad_shrank := false
	while session.state == "toad" and out_frames < 200:
		await physics_frame
		out_frames += 1
		toad_shrank = toad_shrank or (session.is_toad() and session._toad.scale.x < 0.5)
	var change_out := out_frames / tps
	check(toad_shrank and change_out > 0.8 and change_out < 1.15, "the change back: the toad shrinks, about 0.95 s (%.2f s)" % change_out)
	check(session.state == "choose" and session.current == 0 and not session.is_toad() and game.player.visual.visible, "back to the player, same round")
	check(game.player.visual.scale.is_equal_approx(Vector3.ONE), "the player model at full size again")
	check(game.player.speed_override < 0.0, "normal speed again")
	check(session.host.line_id == "mystery.wrong", "Luna repeats the clue")
	check(game.mystery_card.clue_label.text.contains("[u]"), "the card highlights the clue's key words")
	check(Board.shared().done(Session.ACTIVITY) == 0, "a miss does not count")
	# The right door of round 1 (user approval, 10 Nov 2026): in the same frame the player and
	# camera move to the same spot before the hall's wall B, whose matching door opens instead.
	# Then it opens away, the player walks through, it slams, one room back.
	var right := hall_leaf(1, round_data.target)
	var shut_at: Vector3 = house.to_local(right.global_position)
	zone_place(Vector3(Mystery.DOOR_X[round_data.target] + 0.4, Mystery.FLOOR, Mystery.DOOR_WALL - 2.2))
	await physics_frame
	var in_room: Vector3 = house.to_local(game.player.global_position)
	var view_room: Vector3 = game.player.camera_rig.global_position - game.player.global_position
	leaf(round_data.target).use()
	var in_hall: Vector3 = house.to_local(game.player.global_position)
	var swap := Vector3(0, Mystery.ENDLESS_FLOOR - Mystery.FLOOR, float(Mystery.HALL_WALLS[1]) - Mystery.DOOR_WALL)
	check(not session.zone.fading and in_hall.distance_to(in_room + swap) < 0.05, "the right door: swapped at once to the same spot before wall B (%s)" % [in_hall - in_room])
	check((game.player.camera_rig.global_position - game.player.global_position).distance_to(view_room) < 0.05, "the camera moved with the player")
	check(not session._room_round and session._round_doors() == session.hall_walls[1] and not leaf(round_data.target).is_open(), "the mystery room's door stays shut; the hall's wall B is in play")
	check(session.state == "walk" and game.player.controls_enabled, "the right door: the player walks on")
	check(looks(2) == session.rounds[1].doors, "the next room already shows round 2's doors")
	await wait_for(func() -> bool: return right.is_open(), 60)
	await wait_for(func() -> bool: return house.to_local(right.global_position).z > shut_at.z + 0.6, 60)
	check(house.to_local(right.global_position).z > shut_at.z + 0.6, "the door opens away from the player")
	var past: float = float(Mystery.HALL_WALLS[1]) + Mystery.WALL
	# Pacing (user, 10 Nov 2026): just through the doorway the card shows round 2's clue at once;
	# the door waits only while its swing could still touch the player, then slams.
	check(game.mystery_card._praising, "the right door: the card praises")
	zone_place(Vector3(Mystery.DOOR_X[round_data.target], Mystery.ENDLESS_FLOOR, past + 1.0))
	for i in 4: await physics_frame
	check(not game.mystery_card._praising and game.mystery_card._clue == session._clue_line(1) and session.state == "walk", "through the doorway: round 2's clue at once, the door still clear of the player")
	zone_place(Vector3(Mystery.DOOR_X[round_data.target], Mystery.ENDLESS_FLOOR, past + 2.8))
	check(await wait_for(func() -> bool: return session.state == "shut", 30), "clear of its swing the door slams")
	check(only_back(1) == round_data.target, "seen from the next room: only the door come through")
	var before: Vector3 = house.to_local(game.player.global_position)
	var view_before: Vector3 = game.player.camera_rig.global_position - game.player.global_position
	check(await wait_for(func() -> bool: return session.state == "choose" and session.current == 1, 300), "round 2 starts")
	var after: Vector3 = house.to_local(game.player.global_position)
	var view_after: Vector3 = game.player.camera_rig.global_position - game.player.global_position
	check(absf(before.z - after.z - Mystery.HALL_STEP) < 0.3 and absf(before.x - after.x) < 0.2, "moved back one room (%.2f)" % (before.z - after.z))
	check(view_before.distance_to(view_after) < 0.2, "the camera moved with the player")
	check(looks(0) == round_data.doors and only_back(0) == round_data.target and looks(1) == session.rounds[1].doors and not right.is_open(), "the same view: one door behind, round 2 ahead")
	check(Board.shared().done(Session.ACTIVITY) == 0, "round 1 needed two tries: no progress")
	# The door behind stays shut.
	session.host.close_dialogue()
	hall_leaf(0, round_data.target).use()
	check(session.host.line_id == "mystery.no_way_back" and not hall_leaf(0, round_data.target).is_open(), "the door behind: no way back")
	session.host.close_dialogue()
	# Round 2 right at the first try.
	var round2: Dictionary = session.rounds[1]
	hall_leaf(1, round2.target).use()
	await wait_for(func() -> bool: return hall_leaf(1, round2.target).is_open(), 60)
	zone_place(Vector3(Mystery.DOOR_X[round2.target], Mystery.ENDLESS_FLOOR, past + 8.0))
	check(await wait_for(func() -> bool: return session.state == "choose" and session.current == 2, 400), "round 2 right at the first try: round 3")
	check(Board.shared().done(Session.ACTIVITY) == 1, "a first-try door moves the progress bar")
	# Leaving from the hall: the card's button, "No", then "Yes": back in the mystery room.
	game.mystery_card.leave_requested.emit()
	check(session.state == "paused" and session.host.is_asking_leave(), "the leave button asks")
	game.shop_panel.quit_answered.emit(false)
	check(session.state == "choose" and game.player.controls_enabled and session._in_hall(), "No: the game goes on in the hall")
	game.mystery_card.leave_requested.emit()
	game.shop_panel.quit_answered.emit(true)
	check(session.state == "" and not game.mystery_card.visible, "Yes: the game ends")
	await wait_for(func() -> bool: return not session.zone.fading, 120)
	check(session._in_mystery_room() and not session.hall.visible, "back in the mystery room, the hall hidden")
	check(at_luna(), "left from the hall: across the table from Luna, facing her, her goodbye said")
	check(session.room_looks() == room_doors and not leaf(0).is_open(), "the mystery room's doors kept their look until the player leaves")
	# The final line: a one-door game ends back with Luna.
	Board.shared().set_rounds(Session.ACTIVITY, 1)
	session.host.close_dialogue()
	await wait_for(func() -> bool: return not session.zone.fading, 300)
	await session.start_game()
	check(session.state == "choose" and session.rounds.size() == 1, "a one-door game starts")
	if session.rounds.size() != 1:
		finish()
		return
	var last: Dictionary = session.rounds[0]
	zone_place(Vector3(Mystery.DOOR_X[last.target], Mystery.FLOOR, Mystery.DOOR_WALL - 2.2))
	leaf(last.target).use()
	check(session._in_hall() and not session._room_round, "the one door was the mystery room's: swapped into the hall")
	await wait_for(func() -> bool: return hall_leaf(1, last.target).is_open(), 60)
	check(session.treasure.visible and looks(2) == session._exit_looks, "the last door: the treasure room, new doors ahead")
	zone_place(Vector3(Mystery.DOOR_X[last.target], Mystery.ENDLESS_FLOOR, past + 8.0))
	check(await wait_for(func() -> bool: return session.state == "treasure", 300), "the door shuts: the treasure chest waits")
	check(session.host.line_id == "mystery.treasure", "Luna: open the treasure chest")
	zone_place(Vector3(0, Mystery.ENDLESS_FLOOR, Mystery.TREASURE_Z - 2.0))
	await physics_frame
	await physics_frame
	var aimed_from: Vector3 = house.to_global(Vector3(0, Mystery.ENDLESS_FLOOR + 1.2, Mystery.TREASURE_Z - 2.0))
	var at_chest := space.intersect_ray(PhysicsRayQueryParameters3D.create(aimed_from, house.to_global(Vector3(0, Mystery.ENDLESS_FLOOR + 0.5, Mystery.TREASURE_Z))))
	check(not at_chest.is_empty() and game.interaction.vocabulary_target(at_chest.collider, game.apartment) == null, "the chest is solid and not a vocabulary word")
	session.chest.use()
	check(session.state == "diamond", "E or a click opens the chest")
	await wait_for(func() -> bool: return session._ray != null, 300)
	check(session._ray != null and session._diamond.visible, "the diamond surges up with a rainbow ray")
	check(await wait_for(func() -> bool: return session.state == "exit", 400), "then the door out opens")
	check(not session._diamond.visible and session._lid.rotation.x > 1.5 and session.treasure.visible and session._ray == null, "the diamond is gone, the chest stays open")
	check(session.host.line_id == "mystery.treasure_returned", "the diamond went back to Luna (%s)" % session.host.line_id)
	check(await wait_for(func() -> bool: return hall_leaf(2, session.exit_door).is_open(), 60), "one door ahead opens")
	var out: int = session.exit_door
	var out_looks: Array = session._exit_looks.duplicate(true)
	zone_place(Vector3(Mystery.DOOR_X[out], Mystery.ENDLESS_FLOOR, float(Mystery.HALL_WALLS[2]) + Mystery.WALL + 1.2))
	check(await wait_for(func() -> bool: return session.state == "return" and not session.zone.fading, 300), "through it: back in the mystery room")
	var came_out: Vector3 = house.to_local(game.player.global_position)
	check(session._in_mystery_room() and not session.hall.visible and absf(came_out.x - Mystery.DOOR_X[out]) < 0.3 and leaf(out).is_open(), "out of the matching mystery room door")
	check(session.room_looks() == out_looks, "the mystery room's doors now show the doors of the last room")
	check(session._host_calling(), "Luna calls the player back")
	await wait_for(func() -> bool: return not leaf(out).is_open(), 200)
	check(not leaf(out).is_open(), "the door shuts behind the player")
	session._host_talk(session.luna)
	check(session.host.line_id == "mystery.final" and game.shop_panel.has_choices(), "Luna says thank you, gives the result and offers play again or finish")
	game.shop_panel.choice_pressed.emit("mystery_finish")
	check(session.state == "" and session.host.line_id == "mystery.finished", "Finish ends the game")
	# Walking out through the arch at the final stage (user, 10 Nov 2026): it just finishes.
	session.host.close_dialogue()
	await wait_for(func() -> bool: return not session.zone.fading, 300)
	await play_to_return()
	check(session.state == "return", "another one-door game: back in the mystery room with the diamond")
	zone_place(Mystery.INSIDE)
	for i in 4: await physics_frame
	check(not game.player.test_move(game.player.global_transform, house.global_basis * Vector3(0, 0, -4.0)), "at the final stage the arch is open")
	await walk_out()
	check(session.state == "" and not session.host.is_asking_leave() and not game.shop_panel.is_quit_open(), "walking out at the final stage ends the game, no question")
	check(ended_line == "mystery.finished|false", "only the self-closing goodbye (%s)" % ended_line)
	check(not game.mystery_card.visible and not session._host_calling() and Board.shared().blocker("") == "", "the card is gone, Luna stops calling, nothing blocks other games")
	check(game.player.controls_enabled and house.to_local(game.player.global_position).z < Mystery.HALL_REAR - 3.0, "the player is not stopped or put back")
	# Mid-game the arch still asks (round 1 is played in the mystery room itself).
	Board.shared().set_rounds(Session.ACTIVITY, 2)
	session.host.close_dialogue()
	await session.start_game()
	await walk_out()
	check(session.state == "paused" and session.host.is_asking_leave(), "mid-game the arch asks the quit question")
	game.shop_panel.quit_answered.emit(false)
	check(session.state == "choose" and session._in_mystery_room(), "No: put back in the mystery room, the game goes on")
	# The arch is closed mid-game and the question goes when the player steps back (user,
	# 10 Nov 2026: the question showed but the player still got out).
	zone_place(Mystery.INSIDE)
	for i in 4: await physics_frame
	var out_step: Vector3 = house.global_basis * Vector3(0, 0, -4.0)
	check(game.player.test_move(game.player.global_transform, out_step), "mid-game the arch is closed: the player cannot walk out")
	zone_place(Session.ARCH_ASK_AT - Vector3(0, 2.0, 0))
	for i in 4: await physics_frame
	check(session.state == "paused" and session.host.is_asking_leave() and session._asked_at_arch and game.player.controls_enabled, "stepping up to the arch asks, the player can still move")
	zone_place(Mystery.INSIDE)
	for i in 4: await physics_frame
	for i in 3: await process_frame
	check(session.state == "choose" and not session.host.is_asking_leave() and not game.shop_panel.is_quit_open(), "stepping back from the arch takes the question away, the game goes on")
	session.end_game("")
	await wait_for(func() -> bool: return not session.zone.fading, 300)
	Board.shared().set_rounds(Session.ACTIVITY, 0)
	# Leaving while a toad (user, 10 Nov 2026): turned back, across the table from Luna.
	session.host.close_dialogue()
	await wait_for(func() -> bool: return not session.zone.fading, 300)
	await session.start_game()
	if not session.rounds.is_empty():
		await wait_for(func() -> bool: return session.state == "choose" and not session.zone.fading, 300)
		session._round_doors()[(session.rounds[0].target + 1) % 3].leaf.use()
		await wait_for(func() -> bool: return session.is_toad() and session._toad_phase == "toad", 200)
		check(session.is_toad() and session.state == "toad", "a wrong door: a toad, before leaving")
		game.mystery_card.leave_requested.emit()
		check(session.state == "paused" and session._paused_from == "toad" and session.host.is_asking_leave(), "a toad can ask to leave")
		game.shop_panel.quit_answered.emit(true)
		await wait_for(func() -> bool: return not session.zone.fading, 120)
		check(session.state == "" and not session.is_toad() and game.player.visual.visible and game.player.visual.scale == Vector3.ONE, "leaving as a toad: turned back first")
		check(at_luna(), "left as a toad: across the table from Luna, facing her, her goodbye said")
	else:
		check(false, "a game starts for leaving as a toad")
	# A language change, and leaving while a toad.
	session.host.close_dialogue()
	await wait_for(func() -> bool: return not session.zone.fading, 300)
	await session.start_game()
	check(session.state == "choose" and not session.rounds.is_empty(), "a new game starts")
	if session.rounds.is_empty():
		finish()
		return
	leaf((session.rounds[0].target + 1) % 3).use()
	await wait_for(func() -> bool: return session.is_toad(), 120)
	session.end_activity()
	await wait_for(func() -> bool: return not session.zone.fading, 120)
	check(session.state == "" and not session.is_toad() and game.player.visual.visible and session._in_mystery_room(), "a language change ends the game, undoes the toad, back in the room")
	check(not game.interaction.minigame_running(), "no game running afterwards")
	# Play again also starts in place (user, 10 Nov 2026).
	session.host.close_dialogue()
	await play_to_return()
	session._host_talk(session.luna)
	await physics_frame
	var replay_at: Vector3 = house.to_local(game.player.global_position)
	game.shop_panel.choice_pressed.emit("mystery_replay")
	check(session.state == "choose" and session.current == 0 and session._room_round and not session.zone.fading and house.to_local(game.player.global_position).distance_to(replay_at) < 0.05, "Play again starts in place at the mystery room's doors")
	session.end_game("")
	Board.shared().set_rounds(Session.ACTIVITY, 0)
	finish()

## Interaction system (12 Nov 2026): E goes to the input claim or the focus target (Main.use_pressed).
func press_e(game) -> bool:
	game.use_pressed()
	return true

## Talking to an NPC: its Interactable's use (what E, a click or a tap on it does).
func talk_to(npc: Node) -> void:
	preload("res://scripts/core/interactable.gd").on(npc).activate()

func is_talker(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.enabled and item.kind == item.Kind.TALK

func calls(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.calling
