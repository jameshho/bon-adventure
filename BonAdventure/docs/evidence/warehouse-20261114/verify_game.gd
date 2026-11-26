extends SceneTree
## Warehouse Worker after the redesign (user, 14 Nov 2026; docs/guides/WAREHOUSE.md#minigame-14-nov-2026):
## five placing tasks of four kinds (on the table, next to / to the right of the green box in
## the wall bay, on the top shelf). Starts a game through Ramón (as "Sure!" does) and checks the
## copy, the station, the card (Task n of 5), the goods (four boxes: green in the bay, red,
## blue and yellow; the plain one was removed 21 Nov 2026), the shelf's 2 x 3 places and its
## put-down aim (21 Nov 2026: a tap anywhere at a level's front), the cabinet (opens and shuts, no
## task), the plan (rules, replay, 30 more plans), every kind written in three languages and
## solved as a player would, "right" seen from in front of the bay, a finished task counted
## once settled, a wrong box (try again / show me), both hint levels, the practice words, the
## player capsule through both (opened) doors and around the copy's hall, E on the ways out,
## the leave question, the clean return, a language change and "¿Me ayudas otra vez?".
## Replaces docs/evidence/warehouse-20261105/verify_game.gd (38 entries, the old layout). Uses Main, which
## saves progress: run with an isolated HOME.
##   python3 tools/run_checks.py --only warehouse_game
const Board := preload("res://scripts/learning/activity_board.gd")
const Warehouse := preload("res://scripts/world/warehouse.gd")
const Picking := preload("res://scripts/player/interaction_controller.gd")
const Tasks := preload("res://scripts/learning/warehouse_tasks.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const TownCheck := preload("res://docs/evidence/warehouse-20261114/verify.gd")
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	preload("res://scripts/learning/game_progress.gd").shared().unlock("warehouse_ramon", 3)  # the level this check tests (a new profile starts at level 1; LEARN-06, 25 Nov 2026)
	game.player.set_physics_process(false)
	await frames(3)
	var town: Node3D = game.apartment
	var session: Node = game.get_node_or_null("WarehouseSession")
	check(session != null, "session exists")
	if session == null:
		print("warehouse game: %d checks, %d failures" % [checks, failures]); quit(1); return
	var ramon: Node3D = town.get_node("Warehouse/Exterior/Ramon")
	check(is_talker(ramon), "Ramón is a talk target")
	check(Board.shared().chance("warehouse_ramon") == 1.0 and Board.shared().target("warehouse_ramon") == 5, "activity data: chance 1, 5 tasks")
	var real: Node3D = town.get_node("Warehouse")
	var outside := real.to_global(Vector3(-10.0, .2, -3.6))
	game.player.global_position = outside
	var doors_before: int = game.doors.size()
	talk_to(ramon)
	check(game.shop_panel.is_dialogue_visible() and game.shop_panel.has_choices(), "greeting with choices")
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(2.0).timeout
	var copy: Node3D = town.get_node_or_null("WarehouseCopy")
	check(copy != null and session.in_game(), "copy built")
	if copy == null:
		print("warehouse game: %d checks, %d failures" % [checks, failures]); quit(1); return
	check(copy.global_position.distance_to(real.global_position + town.global_basis * Warehouse.COPY_LIFT) < .01, "copy is the lift above the real warehouse")
	check(game.doors.size() == doors_before, "copy registers no doors (they stay shut)")
	check(not ramon.visible, "Ramón outside hidden")
	check(game.player.global_position.distance_to(copy.to_global(Warehouse.STATION)) < .5, "player at the station")
	check(game.warehouse_card.visible and game.warehouse_card.title_label.text != "" and game.warehouse_card.task_label.text != "", "task card: " + game.warehouse_card.title_label.text + " / " + game.warehouse_card.task_label.text)
	check(game.warehouse_card.progress.visible and game.warehouse_card.progress.target == 5, "progress bar 0/5")
	check(game.shop_panel.is_dialogue_visible(), "Ramón's intro in the copy")
	check(str(session.lexicon.text({"phrase": "warehouse.intro"}, "en")).contains("five tasks") and str(session.lexicon.text({"phrase": "warehouse.intro"}, "es")).contains("cinco tareas"), "the intro says five tasks")
	var map_point: Vector3 = game.player.get_meta("map_position", Vector3.INF)
	check(map_point.distance_to(real.to_global(Warehouse.STATION)) < .6, "map shows the real warehouse")
	check(game.current_room().begins_with("Warehouse"), "room name: " + game.current_room())
	check(Board.shared().blocker("family_dr_li") == "warehouse_ramon", "other activities wait while the game runs")
	var twin: Node3D = copy.get_node("Hall/Ramon")
	var bodies := twin.find_children("*", "CollisionObject3D", true, false)
	var picked: Node3D = Picking.vocabulary_target(bodies[0], town) if not bodies.is_empty() else null
	check(picked == twin and str(twin.get_meta("word_key", "")) == "boss", "Ramón's twin picks as boss")
	check(twin.global_position.distance_to(copy.to_global(Warehouse.TWIN_SPOT)) < .3, "twin at his spot in the left section")
	await plan_checks(session)
	# While the checks below move boxes, the current task is a blank one, so nothing they do
	# finishes it (session_flow() puts a real task back).
	session.tasks[session.current] = {"kind": "none"}
	await goods_checks(game, session, copy)
	await kinds(game, session)
	await session_flow(game, session, copy, twin)
	await clearance(game, session, copy)
	await exits(game, session, copy)
	# Falling out of the copy puts the player back at the station.
	game.player.global_position = copy.to_global(Vector3(0, -6, 7))
	await frames(2)
	check(game.player.global_position.distance_to(copy.to_global(Warehouse.STATION)) < .5, "fall recovery to the station")
	# Esc with the card on top asks to leave; "No" keeps playing.
	game.shop_panel.dialogue_closed.emit()
	game.popups.close_top()
	check(game.shop_panel.is_quit_open(), "Esc asks to leave")
	game.shop_panel.quit_answered.emit(false)
	await frames(2)
	check(session.in_game() and not game.shop_panel.is_quit_open(), "No keeps the game")
	# Talking to Ramón repeats the task and offers to leave; Yes ends the game.
	talk_to(twin)
	check(game.shop_panel.is_dialogue_visible() and game.shop_panel.has_choices(), "twin repeats the task with Keep going / a hint / Leave")
	game.shop_panel.choice_pressed.emit("warehouse_leave")
	check(game.shop_panel.is_quit_open(), "Leave asks first")
	game.shop_panel.quit_answered.emit(true)
	await create_timer(2.0).timeout
	await frames(2)
	check(not is_instance_valid(copy) and town.get_node_or_null("WarehouseCopy") == null, "copy freed")
	check(game.player.global_position.distance_to(outside) < .3, "player back where they accepted")
	check(ramon.visible and not game.warehouse_card.visible, "Ramón back, card hidden")
	check(not game.player.has_meta("map_position"), "map stand-in cleared")
	check(Board.shared().blocker("family_dr_li") == "", "board free again")
	# A second game ends at once on a language change, also cleanly.
	session.offered = true
	game.shop_panel.dialogue_closed.emit()
	talk_to(ramon)
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(2.0).timeout
	check(session.in_game(), "second game starts")
	session.end_activity()
	await create_timer(2.0).timeout
	check(not session.in_game() and town.get_node_or_null("WarehouseCopy") == null, "language change ends the game and frees the copy")
	# A finished game: Ramón thanks the player and asks to play again; Yes starts a new game,
	# No says goodbye.
	for answer in ["warehouse_play", "warehouse_no"]:
		session.offered = true
		game.shop_panel.dialogue_closed.emit()
		talk_to(ramon)
		game.shop_panel.choice_pressed.emit("warehouse_play")
		await create_timer(2.0).timeout
		while Board.shared().done("warehouse_ramon") < Board.shared().target("warehouse_ramon") - 1:
			Board.shared().add_success("warehouse_ramon")
		check(session.task_done(), "last task ends the game")
		await create_timer(2.0).timeout
		check(not session.in_game() and ramon.visible and session._talking == "warehouse.complete" and game.shop_panel.has_choices(), "finished: Ramón asks to help again, Yes / No")
		game.shop_panel.choice_pressed.emit(answer)
		await create_timer(2.0).timeout
		if answer == "warehouse_play":
			check(session.in_game() and Board.shared().done("warehouse_ramon") == 0, "Yes: a new game from 0")
			session.end_activity()
			await create_timer(2.0).timeout
		else:
			check(not session.in_game() and session._talking == "warehouse.goodbye", "No: goodbye")
	print("warehouse game: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## The goods: four boxes of one size; the green one in the wall bay; the shelf takes three on
## each level; the cabinet opens and shuts on E.
func goods_checks(game, session, copy: Node3D) -> void:
	var goods = session.goods
	check(goods != null and session.writer != null, "goods and task writer exist")
	var ids: Array = goods.items.keys()
	ids.sort()
	check(ids == ["box_blue", "box_green", "box_red", "box_yellow"], "four boxes, no plain one: " + str(ids))
	check(goods.items.values().all(func(b): return b is RigidBody3D and b.axis_lock_angular_x and b.axis_lock_angular_z and not b.has_meta("word_key")), "rigid bodies turning only about the vertical, no word (no cardboard box)")
	check(goods.bay_of("box_green") == 0 and goods.BAYS.size() == 1, "the green box stands in the one wall bay")
	check(goods.side_axis("box_green", "right") == Vector2(0, 1), "right of the bay box (facing it and the west wall) is north, +z")
	check(goods.items.keys().all(func(id): return goods.center(id).x > Warehouse.DIVIDER_X), "every box starts in the left section")
	check(copy.find_children("*", "", true, false).filter(func(n): return n.has_meta("word_key") and str(n.get_meta("word_key")) in ["scale", "ruler", "conveyor belt", "trolley", "container"]).is_empty(), "no scale, ruler, conveyor, trolley or container in the copy")
	# The shelf: three on the top level and three below, all recognised.
	var keep := {}
	for id in goods.items:
		keep[id] = goods.center(id)
	var shelf := Warehouse.SHELF_AT
	var placed: Array = ["box_red", "box_blue", "box_yellow"]
	for level in Warehouse.RACK_LEVELS.size():
		for i in 3:
			var id: String = placed[i]
			goods.place_at(id, goods.shelf_spot(level, Warehouse.SHELF_SLOTS[i], goods.half(id).y) + Vector3(0, .02, 0))
		await frames(40)
		check(goods.on_level(level) == 3 and placed.all(func(id): return goods.rack_spot(id) == [0, level]), "shelf level %d holds 3 boxes (%d)" % [level, goods.on_level(level)])
	# The put-down aim (21 Nov 2026): the top level is full now, so aiming at it finds no place.
	game.player.global_position = copy.to_global(Vector3(shelf.x, Warehouse.FLOOR + .1, 10.6))
	await frames(2)
	var top_y: float = Warehouse.FLOOR + Warehouse.RACK_LEVELS[1]
	check(shelf_aim(goods, copy, Vector3(shelf.x + 1.3, top_y + .3, 12.7)) == Vector3.INF, "aim: a full top level offers no place")
	for id in placed:
		goods.place_at(id, Vector3(goods.FLOOR_SPOTS[placed.find(id)].x, Warehouse.FLOOR + goods.half(id).y + .01, goods.FLOOR_SPOTS[placed.find(id)].y))
	await frames(40)
	var aimed := shelf_aim(goods, copy, Vector3(shelf.x + 1.3, top_y + .3, 12.7))
	check(aimed.is_equal_approx(goods.shelf_spot(1, 1.3, goods.BOX_SIZE.y * .5)), "aim above the top deck: its nearest place %s" % [aimed])
	aimed = shelf_aim(goods, copy, Vector3(shelf.x - 1.1, top_y - .06, 12.7))
	check(aimed.is_equal_approx(goods.shelf_spot(1, -1.3, goods.BOX_SIZE.y * .5)), "aim at the top deck's front beam: the top level %s" % [aimed])
	aimed = shelf_aim(goods, copy, Vector3(shelf.x + .2, Warehouse.FLOOR + Warehouse.RACK_LEVELS[0] + .4, 12.7))
	check(aimed.is_equal_approx(goods.shelf_spot(0, 0.0, goods.BOX_SIZE.y * .5)), "aim between the decks: the bottom level %s" % [aimed])
	check(shelf_aim(goods, copy, Vector3(shelf.x, Warehouse.FLOOR, 11.4)) == Vector3.INF, "aim at the floor in front: not the shelf")
	for id in keep:
		goods.place_at(id, keep[id] + Vector3(0, .02, 0))
	await frames(40)
	# The cabinet: E (use) opens and shuts it; there is no cabinet task.
	var was: bool = goods.cabinet_open
	check(goods._cabinet_pivots.size() == 2, "two hinged cabinet doors")
	game.player.global_position = copy.to_global(Vector3(Warehouse.CABINET_AT.x, Warehouse.FLOOR + .1, Warehouse.CABINET_AT.z - 1.8))
	await frames(2)
	check(goods.use(goods._cabinet_body, null) and goods.cabinet_open != was, "E opens / shuts the cabinet")
	goods.use(goods._cabinet_body, null)
	check(goods.cabinet_open == was, "and back")
	game.player.global_position = copy.to_global(Warehouse.STATION + Vector3(0, .1, 0))
	await frames(2)

## Where a put-down aimed from a camera behind the player at a hall-local point would go
## (warehouse_goods.gd _shelf_place(); Vector3.INF when not on the shelf).
func shelf_aim(goods, copy: Node3D, at: Vector3) -> Vector3:
	var cam: Camera3D = goods.interaction.camera
	cam.global_position = copy.to_global(Vector3(at.x * .3 + Warehouse.SHELF_AT.x * .7, 2.5, 8.6))
	cam.look_at(copy.to_global(at), Vector3.UP)
	goods.interaction.pointer_position = cam.get_viewport().get_visible_rect().size * .5
	return goods._shelf_place(goods.BOX_SIZE, goods._aim_hit())

func plan_checks(session) -> void:
	var writer = session.writer
	var lexicon = session.lexicon
	check(writer.entries() == ["on", "next_to", "right", "top_shelf"], "four entries: " + str(writer.entries()))
	var plan: Array = session.tasks
	check(plan.size() == 5 and session.plan_problems.is_empty(), "5 tasks planned before the game (%d; %s)" % [plan.size(), session.plan_problems])
	check(plan.all(func(t): return t.kind == "place" and t.entry in Tasks.POSITIONS), "every task places a box")
	check(writer.validate(plan).is_empty(), "the plan replays: every task possible in its turn: %s" % [writer.validate(plan)])
	check(Tasks._uses(plan).values().all(func(n): return n <= 2), "no thing or place in more than 2 of 5 tasks: %s" % [Tasks._uses(plan)])
	var bad_text: Array = []
	for task in plan:
		print("  plan: ", lexicon.text(task, "es"), " | ", lexicon.text(task, "en"), " | ", lexicon.text(task, "zh"))
		for level in [1, 2]:
			var hint: Dictionary = writer.hint(task, level)
			for lang in ["es", "en", "zh"]:
				for text in [lexicon.text(task, lang), lexicon.text(hint.say, lang)]:
					if "{" in text or text.begins_with("warehouse.") or (lang == "es" and (" de el " in text or " a el " in text)):
						bad_text.append(lang + ": " + text)
	check(bad_text.is_empty(), "planned tasks and both hint levels render: %s" % [bad_text.slice(0, 3)])
	var different := {}
	var broken: Array = []
	var entry_counts := {}
	for n in 30:
		var planned: Dictionary = writer.plan(5)
		var found: Array = planned.problems + writer.validate(planned.tasks)
		if not found.is_empty() or planned.tasks.size() != 5:
			broken.append(found)
		different[str(planned.tasks.map(func(t): return [t.entry, Tasks.objects(t)]))] = true
		for t in planned.tasks:
			entry_counts[t.entry] = int(entry_counts.get(t.entry, 0)) + 1
	check(broken.is_empty(), "30 more plans keep every rule: %s" % [broken.slice(0, 2)])
	check(different.size() >= 20, "plans differ (%d different of 30)" % different.size())
	check(entry_counts.size() == 4, "plans use all four kinds: %s" % [entry_counts])
	# Levels (LEARN-06, 25 Nov 2026): L1 only "on" and the top shelf, L2 adds "next to"; every
	# plan still keeps the rules (each of L1's two places may take 3 of 5 tasks).
	for positions in [["on", "top_shelf"], ["on", "top_shelf", "next_to"]]:
		writer.positions = positions
		var level_broken: Array = []
		var used_entries := {}
		for n in 20:
			var planned: Dictionary = writer.plan(5)
			var found: Array = planned.problems + writer.validate(planned.tasks)
			if not found.is_empty() or planned.tasks.size() != 5:
				level_broken.append(found)
			for t in planned.tasks:
				used_entries[t.entry] = true
		var only: bool = used_entries.keys().all(func(e): return positions.has(e))
		check(level_broken.is_empty() and only and used_entries.size() == positions.size(), "level plans with %s keep every rule (%s): %s" % [positions, used_entries.keys(), level_broken.slice(0, 2)])
	writer.positions = []
	session.level = {"hints_after_miss": true}
	session._task_missed = false
	check(not session.hints_allowed(), "level 4: no hint before a wrong try")
	session._miss("thing")
	check(session.hints_allowed() and session._task_missed, "level 4: a wrong try unlocks the hints and counts one miss")
	session.level = {}
	session._task_missed = false
	session._missed = {}
	# Practice words: the colour the box's name says (no cardboard box since 21 Nov 2026).
	check(writer.words({"kind": "place", "item": "box_red"}) == ["red"], "a red box task practises red")
	check(lexicon.text(Tasks.thing("box_red"), "es") == "la caja roja", "box name: la caja roja")

## Each kind written, rendered in three languages and solved by moving the box as a player
## would; "right" is also not met on the left side, where "next to" is.
func kinds(game, session) -> void:
	var goods = session.goods
	var writer = session.writer
	var lexicon = session.lexicon
	session._close_dialogue()
	for entry in Tasks.POSITIONS:
		var task: Dictionary = writer.make(entry)
		check(not task.is_empty(), entry + " writable")
		if task.is_empty():
			continue
		for lang in ["es", "en", "zh"]:
			var text: String = lexicon.text(task, lang)
			check(not "{" in text and not text.begins_with("warehouse."), "%s renders in %s: %s" % [entry, lang, text])
		print("  ", entry, ": ", lexicon.text(task, "es"), " | ", lexicon.text(task, "en"))
		check(not writer.done(task), entry + " not done before")
		await solve(goods, task)
		check(writer.done(task), "solved: " + lexicon.text(task, "en"))
		if entry == "right":
			var ref := str(task.goal.ref)
			var left: Vector2 = goods.side_axis(ref, "left")
			var r: Vector3 = goods.ref_center(ref)
			var h: Vector3 = goods.half(task.item)
			var reach: float = goods.reach(goods.ref_half(ref), h, left) + .4
			goods.place_at(task.item, Vector3(r.x + left.x * reach, Warehouse.FLOOR + h.y + .02, r.z + left.y * reach))
			await frames(40)
			check(not writer.reached(task.item, task.goal) and writer.reached(task.item, {"pos": "next_to", "ref": ref}), "on the left of the green box: next to it, not to its right")
	# Back to the station's arrangement for the session checks.
	await frames(10)

func solve(goods, task: Dictionary) -> void:
	goods.pick_up(goods.items[task.item])
	await frames(2)
	goods._release_at(spot_for(goods, task.item, task.goal))
	await frames(45)

## A hall-local centre that meets a goal.
func spot_for(goods, id: String, goal: Dictionary) -> Vector3:
	var h: Vector3 = goods.half(id)
	var ground := Warehouse.FLOOR + h.y + .02
	var ref := str(goal.get("ref", ""))
	match str(goal.pos):
		"right", "next_to":
			var r: Vector3 = goods.ref_center(ref)
			var axis: Vector2 = goods.side_axis(ref, "right")
			var reach: float = goods.reach(goods.ref_half(ref), h, axis) + .4
			for extra in [0.0, .6, 1.1]:
				var at := Vector3(r.x + axis.x * (reach + extra), ground, r.z + axis.y * (reach + extra))
				if not goods.items.keys().any(func(other): return other != id and other != ref and absf(goods.center(other).x - at.x) < h.x + goods.half(other).x + .05 and absf(goods.center(other).z - at.z) < h.z + goods.half(other).z + .05):
					return at
			return Vector3(r.x + axis.x * reach, ground, r.z + axis.y * reach)
		"on":
			for dx in [0.0, -1.0, 1.0]:
				var at := Vector3(goods.WORK_TABLE.x + dx, Warehouse.FLOOR + goods.TABLE_HEIGHT + h.y + .02, goods.WORK_TABLE.z)
				if not goods.items.keys().any(func(other): return other != id and absf(goods.center(other).x - at.x) < .95 and goods.on_table(other)):
					return at
		"top_shelf":
			var top: int = Warehouse.RACK_LEVELS.size() - 1
			for slot in Warehouse.SHELF_SLOTS:
				var x: float = Warehouse.SHELF_AT.x + slot
				if not goods.items.keys().any(func(other): return other != id and goods.rack_spot(other) == [0, top] and absf(goods.center(other).x - x) < .9):
					return goods.shelf_spot(top, slot, h.y) + Vector3(0, .02, 0)
	return Vector3(5.0, ground, 1.7)

## The live session: a placed task counts once let go and settled; a wrong box asks "try again
## or tell me"; "tell me" marks the right box; both hint levels; the practice log.
func session_flow(game, session, copy: Node3D, twin: Node3D) -> void:
	var goods = session.goods
	var writer = session.writer
	session._close_dialogue()
	session._praise_left = 0.0
	# A fresh "on the table" task as the current one, solved by moving the box.
	var task: Dictionary = {}
	for attempt in 6:
		task = writer.make("on")
		if not task.is_empty():
			break
	check(not task.is_empty(), "an 'on the table' task for the session")
	if task.is_empty():
		return
	session.tasks[session.current] = task
	session._new_task()
	session._show_task()
	check(PracticeLog.shared().game_id() == "warehouse_ramon" and PracticeLog.shared()._keys == writer.words(task), "the card's task is tracked: %s" % [PracticeLog.shared()._keys])
	# Hints: level 1 says an area, level 2 marks the box.
	session.give_hint()
	check(game.shop_panel.is_dialogue_visible() and session._hint_level == 1, "hint 1 shown")
	session.give_hint()
	check(session._hint_level == 2 and goods._marker != null and goods._marker.visible, "hint 2 marks the box in green")
	session._close_dialogue()
	goods.clear_mark()
	# A different box picked up: try again, or be shown the right one.
	var other: String = goods.items.keys().filter(func(id): return id != task.item and goods.bay_of(id) < 0)[0]
	goods.pick_up(goods.items[other])
	await frames(2)
	check(session._talking == "warehouse.wrong_thing" and game.shop_panel.has_choices(), "picking another box: try again or tell me")
	game.shop_panel.choice_pressed.emit(session.host.choice_prefix() + "hint")
	await frames(2)
	check(goods._marker != null and goods._marker.visible and goods._marker.position.distance_to(goods.center(task.item)) < .2, "tell me: the right box marked in green")
	goods._release_at(goods.center(other) + Vector3(0, .05, 0))
	session._close_dialogue()
	await frames(30)
	var done0: int = Board.shared().done("warehouse_ramon")
	goods.pick_up(goods.items[task.item])
	await frames(2)
	goods._release_at(spot_for(goods, task.item, task.goal))
	await frames(4)
	check(Board.shared().done("warehouse_ramon") == done0, "not counted while still settling")
	await frames(90)
	check(Board.shared().done("warehouse_ramon") == done0 + 1, "the placed box counts once settled (%d -> %d)" % [done0, Board.shared().done("warehouse_ramon")])
	await create_timer(2.0).timeout
	check(session.tasks.size() >= 5 and not session.tasks[session.current].is_empty(), "the next task shows")

## The standing-player capsule in the copy: both doors opened (they stay shut in the game, so
## this tests the openings), through them and around the hall; goods do not count (they are
## pushed aside when walked into).
func clearance(game, session, copy: Node3D) -> void:
	var shell: Node3D = copy.get_node("Architecture")
	var entrance: Node3D = shell.get_node("Warehouse entrance door")
	var hall_door: Node3D = shell.get_node("Warehouse hall door")
	var closed := entrance.position
	var space: PhysicsDirectSpaceState3D = copy.get_world_3d().direct_space_state
	var exclude: Array[RID] = [game.player.get_rid()]
	for body in session.goods.items.values():
		exclude.append(body.get_rid())
	check(not TownCheck.touching(space, copy, game.player, Vector3(Warehouse.ENTRANCE_X, 0, .15), exclude).is_empty(), "copy: the shut entrance blocks")
	entrance.position = closed + Vector3(2 * Warehouse.DOOR_W2 + .15, 0, 0)
	hall_door.rotation.y = 1.75
	await frames(2)
	var stuck := []
	for p in TownCheck.walk_path():
		if p.z < 0.0:
			continue   # the copy has no lot or ramp
		var hits: Array = TownCheck.touching(space, copy, game.player, p, exclude)
		if not hits.is_empty():
			stuck.append([p, TownCheck.names(hits)])
	check(stuck.is_empty(), "copy: a standing player through both door openings, both sections and to each station: " + str(stuck))
	entrance.position = closed
	hall_door.rotation.y = 0.0
	await frames(2)

## E on the hall door, the entrance or a roll-up door asks to leave; No keeps the game and its
## progress; carrying something, E puts it down instead.
func exits(game, session, copy: Node3D) -> void:
	var goods = session.goods
	session._close_dialogue()
	var done0: int = Board.shared().done("warehouse_ramon")
	var f := Warehouse.FLOOR
	for spec in [["hall door", Vector3(-6.4, f, Warehouse.HALL_DOOR_Z), Vector3(Warehouse.RX - Warehouse.T, f + 1.3, Warehouse.HALL_DOOR_Z)], ["roll-up door A", Vector3(-5.3, f, 2.2), Vector3(-5.3, f + 1.8, .1)], ["roll-up door B", Vector3(-.3, f, 2.2), Vector3(-.3, f + 1.8, .1)]]:
		await aim_at(game, copy, spec[1], spec[2])
		check(press_e(game) and game.shop_panel.is_quit_open(), "E on the " + spec[0] + " asks to leave")
		game.shop_panel.quit_answered.emit(false)
		await frames(2)
		check(session.in_game() and not game.shop_panel.is_quit_open() and Board.shared().done("warehouse_ramon") == done0, "No: still in the game, progress kept (" + spec[0] + ")")
	var marked: Array = copy.get_node("Architecture").get_children().filter(func(n): return n.has_meta("warehouse_exit"))
	check(marked.size() == 4, "four ways out marked: hall door, entrance, two roll-up doors (%d)" % marked.size())
	var id: String = goods.items.keys().filter(func(k): return goods.bay_of(k) < 0)[0]
	# The current task's own box, so no "that isn't the box" question comes up.
	id = str(session.tasks[session.current].get("item", id))
	goods.pick_up(goods.items[id])
	await frames(2)
	session._close_dialogue()
	await frames(3)
	check(press_e(game) and goods.carried == null and not game.shop_panel.is_quit_open(), "carrying at a door: E puts it down, no leave question")
	await frames(20)
	session._close_dialogue()

func aim_at(game, copy: Node3D, stand: Vector3, target: Vector3) -> void:
	var p = game.player
	p.global_position = copy.to_global(stand + Vector3(0, .1, 0))
	var look: Vector3 = copy.to_global(target) - p.global_position
	p.rotation.y = atan2(-look.x, -look.z)
	p.camera_yaw = p.rotation.y
	p.camera_pitch = -0.1
	p.reset_camera()
	await frames(3)
	game.interaction.pointer_position = game.interaction.camera.unproject_position(copy.to_global(target))

func press_e(game) -> bool:
	game.use_pressed()
	return true

## Talking to an NPC: its Interactable's use (what E, a click or a tap on it does).
func talk_to(npc: Node) -> void:
	preload("res://scripts/core/interactable.gd").on(npc).activate()

func is_talker(npc: Node) -> bool:
	var item = preload("res://scripts/core/interactable.gd").on(npc)
	return item != null and item.enabled and item.kind == item.Kind.TALK
