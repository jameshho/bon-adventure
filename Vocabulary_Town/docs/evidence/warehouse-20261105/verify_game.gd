extends SceneTree
## Warehouse Phases 4–5 (5 Nov 2026): the Warehouse Worker game. Starts a game through the
## session (as the "Sure!" choice does), checks the copy, the station, the task card, the map
## stand-in; Phase 5: the goods, every one of the 38 entries written, rendered in three
## languages and solved (the check moves the goods as a player would and asks the task
## checker), carrying, a trolley pushed with W, the cabinet, the scale and measuring
## readouts, and the session flows (a wrong place with the green marker, a weight question
## answered wrong then right, handing a thing to Ramón, a ¿Dónde está? question). Then the
## fall recovery, the leave question and the clean return, and a second game ended by a
## language change. 8 Nov 2026: racks A and B only with the containers where rack C was, the
## ten-task plan (rules, replay, 30 more plans varied and valid, a backup for a task made
## impossible), no mistake for a wrong put-down, a placement counted only once settled, the
## shared two-level hints (card "?" and Ramón), E on the doors / loading gate asking to leave,
## the practice words (colour and size, brown and medium are words), and the end-of-game
## question. Uses Main, which saves progress: run with an isolated HOME.
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/warehouse-20261105/verify_game.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Warehouse := preload("res://scripts/world/warehouse.gd")
const Picking := preload("res://scripts/player/interaction_controller.gd")
const Tasks := preload("res://scripts/learning/warehouse_tasks.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
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
	game.player.set_physics_process(false)
	await frames(3)
	var town: Node3D = game.apartment
	var session: Node = game.get_node_or_null("WarehouseSession")
	check(session != null, "session exists")
	if session == null:
		print("warehouse game: %d checks, %d failures" % [checks, failures]); quit(1); return
	var ramon: Node3D = town.get_node("Warehouse/Exterior/Ramon")
	check(is_talker(ramon), "Ramón is a talk target")
	check(Board.shared().chance("warehouse_ramon") == 1.0 and Board.shared().target("warehouse_ramon") == 10, "activity data: chance 1, 10 tasks")
	var real: Node3D = town.get_node("Warehouse")
	var outside := real.to_global(Vector3(-3.0, .2, -3.0))
	game.player.global_position = outside
	var doors_before: int = game.doors.size()
	# Talking offers the game with two choices.
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
	check(game.warehouse_card.progress.visible and game.warehouse_card.progress.target == 10, "progress bar 0/10")
	check(game.shop_panel.is_dialogue_visible(), "Ramón's intro in the copy")
	var map_point: Vector3 = game.player.get_meta("map_position", Vector3.INF)
	check(map_point.distance_to(real.to_global(Warehouse.STATION)) < .6, "map shows the real warehouse")
	check(game.current_room() == "Warehouse" or game.current_room().begins_with("Warehouse"), "room name: " + game.current_room())
	check(Board.shared().blocker("family_dr_li") == "warehouse_ramon", "other activities wait while the game runs")
	var twin: Node3D = copy.get_node("Hall/Ramon")
	var bodies := twin.find_children("*", "CollisionObject3D", true, false)
	var picked: Node3D = Picking.vocabulary_target(bodies[0], town) if not bodies.is_empty() else null
	check(picked == twin and str(twin.get_meta("word_key", "")) == "boss", "Ramón's twin picks as boss")
	await phase5(game, session, copy, twin)
	# Falling out of the copy puts the player back at the station.
	game.player.global_position = copy.to_global(Vector3(0, -6, 18))
	await frames(2)
	check(game.player.global_position.distance_to(copy.to_global(Warehouse.STATION)) < .5, "fall recovery to the station")
	await exits(game, session, copy)
	# Esc with the card on top asks to leave; "No" keeps playing.
	game.shop_panel.dialogue_closed.emit()
	game.popups.close_top()
	check(game.shop_panel.is_quit_open(), "Esc asks to leave")
	game.shop_panel.quit_answered.emit(false)
	await frames(2)
	check(session.in_game() and not game.shop_panel.is_quit_open(), "No keeps the game")
	# Talking to Ramón repeats the task and offers to leave; Yes ends the game.
	talk_to(twin)
	check(game.shop_panel.is_dialogue_visible() and game.shop_panel.has_choices(), "twin repeats the task with Keep going / Leave")
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
	# A finished game: Ramón outside thanks the player and asks to play again; Yes starts a new
	# game, No says goodbye.
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
			# The goodbye closes itself once the player walks off (user, 8 Nov 2026).
			await frames(5)
			check(game.shop_panel.is_dialogue_visible(), "goodbye still shown while standing")
			game.player.global_position += game.player.global_basis.x * 4.0
			await frames(5)
			check(not game.shop_panel.is_dialogue_visible() and session._talking == "", "walking 4 m away closes the goodbye")
	print("warehouse game: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

# --- Phase 5 ---------------------------------------------------------------------------------

var _twin: Node3D

func phase5(game, session, copy: Node3D, twin: Node3D) -> void:
	var goods = session.goods
	var writer = session.writer
	_twin = twin
	check(goods != null and writer != null, "goods and task writer exist")
	if goods == null:
		return
	await round5(game, session, goods, writer, twin)
	check(goods.items.size() == 10 and goods.items.values().all(func(b): return b is RigidBody3D and b.axis_lock_angular_x and b.axis_lock_angular_z), "10 goods, rigid bodies turning only about the vertical (%d)" % goods.items.size())
	check(goods.containers.size() == 2 and goods.trolleys.size() == 2 and goods._cabinet_pivots.size() == 2, "2 containers, 2 trolleys, 2 cabinet hinges (%d, %d, %d)" % [goods.containers.size(), goods.trolleys.size(), goods._cabinet_pivots.size()])
	# 8 Nov 2026: eight boxes in three fixed sizes and eight colours (no packages), a suitcase and
	# a barrel, no bottle.
	var sizes := {}
	var colors := {}
	for id in goods.boxes:
		sizes[id.get_slice("_", 1)] = sizes.get(id.get_slice("_", 1), 0) + 1
		colors[id.get_slice("_", 2)] = true
		check(int(goods.items[id].get_meta("height")) == int(goods.BOX_SIZES[id.get_slice("_", 1)][1]), "fixed length for " + id)
	check(sizes == {"big": 1, "medium": 4, "small": 3} and colors.size() == 8 and not goods.items.keys().any(func(id): return id.begins_with("package")), "box mix %s, %d colours" % [sizes, colors.size()])
	check(goods.items.keys().any(func(id): return id.begins_with("suitcase_")) and goods.items.keys().any(func(id): return id.begins_with("barrel_")) and not goods.items.has("bottle"), "a suitcase and a barrel, no bottle")
	check(goods.containers.keys().any(func(cid): return goods.items.keys().any(func(id): return goods.inside_of(id) == cid)), "a small thing starts in a container")
	check(goods.BAYS.all(func(bay): return bay[0].x > 0 and bay[1] == Vector2(-1, 0)), "all wall bays on the player's left (west) wall")
	var motor: Node = copy.find_child("Conveyor motor", true, false)
	check(motor != null and not motor.find_children("*", "MeshInstance3D", true, false).any(func(m): return m.get_active_material(0) != null and m.get_active_material(0).albedo_color.is_equal_approx(Color(Warehouse.YELLOW))), "conveyor motor is not yellow")
	var barrel_id: String = goods.items.keys().filter(func(id): return id.begins_with("barrel_"))[0]
	check(goods.half(barrel_id).y * 2.0 > 1.0 and goods.half(suitcase_id(goods)).y * 2.0 > .9, "barrel and suitcase enlarged")
	plan_checks(game, session, copy)
	await big_box(game, session, goods, twin)
	check(writer.entries().size() == 37 and not "organize" in writer.entries(), "37 primary entries (no 'organize' opener)")
	game.shop_panel.dialogue_closed.emit()
	# The session must not finish tasks while the check moves things: a question task is
	# never finished by moving goods.
	var suitcase: String = goods.items.keys().filter(func(id): return id.begins_with("suitcase_"))[0]
	session.tasks[session.current] = {"kind": "where", "item": suitcase, "entry": "be", "phrase": "warehouse.task_where", "values": {"item": Tasks.thing(suitcase)}}
	var lexicon = session.lexicon
	var made := {}
	var solved := {}
	var kinds := {}
	var bad_text: Array = []
	for round in 8:
		# take_out first, while the starting thing is still in its container.
		var order: Array = writer.entries()
		order.erase("take_out")
		order.push_front("take_out")
		for entry in order:
			if solved.has(entry):
				continue
			if entry in ["weigh", "measure"]:
				# A thing left on the scale or measuring table by an earlier task blocks these.
				for other in goods.items:
					if not goods.trolley_only(other) and (goods.on_scale(other) or goods.on_table(other, "measure")):
						goods.place_at(other, free_spot(goods, other))
				await frames(10)
			var task: Dictionary = writer.make(entry)
			# Weigh / measure draw a comparison half the time; the comparison is checked below,
			# so redraw a few times for the plain question here.
			for attempt in 8:
				if task.get("kind", "") != "compare":
					break
				task = writer.make(entry)
			if task.is_empty():
				continue
			made[entry] = true
			for lang in ["es", "en", "zh"]:
				var text: String = lexicon.text(task, lang)
				if "{" in text or text.begins_with("warehouse.") or (lang == "es" and (" de el " in text or " a el " in text)):
					bad_text.append(lang + ": " + text)
			if round == 0 and entry in ["put", "on_top", "take_out", "go"]:
				print("  ", entry, ": ", lexicon.text(task, "es"), " | ", lexicon.text(task, "en"), " | ", lexicon.text(task, "zh"))
			if task.kind in ["weigh", "measure", "where", "color", "what", "compare"]:
				await answerable(goods, writer, task, entry)
				kinds[task.kind] = true
				if task.kind in ["weigh", "measure", "where"]:
					solved[entry] = true
				continue
			kinds[task.kind] = true
			await solve(goods, task, twin, game.player)
			var ok: bool = writer.done(task)
			if not ok:
				print("  not solved: ", entry, " ", task.get("goal", task.get("zone", "")), " ", task.get("item", ""), " at ", goods.center(task.item) if task.has("item") else "")
				# What else is there (9 Nov 2026 suite: the suitcase ended 0.29 above the floor).
				if task.has("item"):
					var at: Vector3 = goods.center(task.item)
					print("    velocity ", goods.items[task.item].linear_velocity, ", on floor ", goods.on_floor(task.item), ", carried ", goods.carried == goods.items[task.item])
					for other in goods.items:
						if other != task.item and Vector2(goods.center(other).x - at.x, goods.center(other).z - at.z).length() < 1.5:
							print("    near: ", other, " at ", goods.center(other), " half ", goods.half(other))
			check(ok, "solved: " + lexicon.text(task, "en"))
			solved[entry] = true
			if goods.carried != null:
				goods._release_at(free_spot(goods, goods.carried.get_meta("warehouse_item")))
				await frames(20)
	check(made.size() == 37, "every entry was writable (%d/37; missing %s)" % [made.size(), writer.entries().filter(func(e): return not made.has(e))])
	check(solved.size() == 37, "every entry was solved or answered (%d/37; missing %s)" % [solved.size(), writer.entries().filter(func(e): return not solved.has(e))])
	# The question variants, drawn until each appears (they are random).
	# A scene where each variant can be written: one box alone on the table, one thing alone
	# in a container.
	var loose: Array = goods.boxes.filter(func(id): return goods.bay_of(id) < 0 and not goods.trolley_only(id))
	for id in goods.items:
		if goods.bay_of(id) < 0 and not goods.trolley_only(id):
			goods.place_at(id, free_spot(goods, id))
			await frames(15)
	if not loose.is_empty():
		goods.place_at(loose[0], spot_for(goods, loose[0], {"pos": "on", "ref": "table"}))
	goods.place_at(suitcase, spot_for(goods, suitcase, {"pos": "inside", "ref": goods.containers.keys()[0]}))
	# One small box alone on the big box, for "what is on top of …?".
	var small: String = goods.boxes.filter(func(id): return id.begins_with("box_small_"))[0]
	goods.place_at(small, spot_for(goods, small, {"pos": "on_top", "ref": goods.big_box}))
	await frames(40)
	for pair in [["look_for", "color"], ["inside", "what"], ["on", "what"], ["top_shelf", "what"], ["on_top", "what"], ["weigh", "compare"], ["measure", "compare"]]:
		for attempt in 60:
			var variant: Dictionary = writer.make(pair[0])
			if not variant.is_empty() and variant.kind == pair[1]:
				for lang in ["es", "en", "zh"]:
					var text: String = lexicon.text(variant, lang)
					if "{" in text or (lang == "es" and (" de el " in text or " a el " in text)):
						bad_text.append(lang + ": " + text)
				print("  ", pair[0], " → ", pair[1], ": ", lexicon.text(variant, "es"), " | ", lexicon.text(variant, "en"))
				await answerable(goods, writer, variant, pair[0])
				kinds[pair[1] + ":" + pair[0]] = true
				break
	check(kinds.has("color:look_for") and kinds.has("compare:weigh") and kinds.has("compare:measure") and kinds.has("what:on_top") and (kinds.has("what:inside") or kinds.has("what:on") or kinds.has("what:top_shelf")), "question variants appeared: %s" % [kinds.keys()])
	check(bad_text.is_empty(), "variant sentences render too: %s" % [bad_text.slice(0, 3)])
	var bay_refs: Array = (goods.containers.keys() + goods.items.keys()).filter(func(ref): return goods.bay_of(ref) >= 0)
	check(bay_refs.size() >= 1, "things stand in wall bays: %s" % [bay_refs])
	if not bay_refs.is_empty():
		var ref: String = bay_refs[0]
		var out: Vector2 = goods.side_axis(ref, "front")
		var right: Vector2 = goods.side_axis(ref, "right")
		check(goods.to_hall(goods.to_world(Vector3.ZERO)).is_equal_approx(Vector3.ZERO) and absf(out.dot(right)) < .01 and goods.side_axis(ref, "behind") == -out, "bay frame: front away from the wall, right square to it")
		check(goods.ref_center(ref).x * out.x < 0, "front of a bay points into the hall")
	check(bad_text.is_empty(), "task sentences render in es/en/zh with contractions: %s" % [bad_text.slice(0, 3)])
	# A trolley pushed with W.
	var trolley: Dictionary = goods.trolleys[0]
	goods._move_trolley(trolley, goods.TROLLEY_Z.y)
	goods.grab_trolley(trolley)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await frames(45)
	key.pressed = false
	Input.parse_input_event(key)
	await frames(2)
	check(trolley.z < goods.TROLLEY_Z.y - .5, "W pushes the trolley along its lane (z %.2f)" % trolley.z)
	var feet: Vector3 = goods.to_hall(game.player.global_position)
	check(absf(feet.x - trolley.lane) < .05 and feet.z > trolley.z, "player held behind the handle")
	check(not game.player.controls_enabled, "walking is off while holding")
	check(press_e(game), "E lets go of the trolley")
	check(goods.held_trolley.is_empty() and game.player.controls_enabled, "let go: walking back on")
	# The cabinet swings with E (aimed).
	var was: bool = goods.cabinet_open
	game.player.global_position = goods.to_world(Vector3(-8.5, Warehouse.FLOOR + .1, 26.0))
	check(goods.use(goods._cabinet_body, twin), "E on the cabinet")
	await create_timer(.5).timeout
	check(goods.cabinet_open != was and (absf(goods._cabinet_pivots[0].rotation.y) > 1.5) == goods.cabinet_open, "cabinet doors swing")
	# Carrying: the item floats in front, E (no aim) puts it down in front of the player.
	game.player.global_position = goods.to_world(Vector3(0.5, Warehouse.FLOOR + .1, 18.0))
	var near_id: String = goods.boxes[1]
	var box: RigidBody3D = goods.items[near_id]
	goods.place_at(near_id, Vector3(0.5, Warehouse.FLOOR + goods.half(near_id).y + .01, 19.4))
	await frames(5)
	check(goods.use(box, twin), "E picks up an aimed box in reach")
	await frames(3)
	var held: Vector3 = goods.center(near_id)
	check(goods.carried == box and held.y > Warehouse.FLOOR + .8, "carried box floats in front (y %.2f)" % held.y)
	goods.drop_carried()
	await frames(40)
	check(goods.carried == null and goods.on_floor(near_id) and goods.resting(near_id), "put down on the floor")
	var far_id: String = goods.boxes[4]
	var far: RigidBody3D = goods.items[far_id]
	goods.place_at(far_id, Vector3(8.0, Warehouse.FLOOR + .4, 24.0))
	check(not goods.use(far, twin), "a box out of reach is not picked up")
	# Session flow 1 (8 Nov 2026): a put-down in the wrong place is no mistake; the card's "?"
	# and Ramón share the hint level (1: a clue, 2: green marker on the thing, then on its
	# place once carried); passing through the right place does not count; settling there does.
	var done0: int = Board.shared().done("warehouse_ramon")
	var place_task: Dictionary = writer.make("inside")
	for attempt in 100:
		if place_task.get("kind", "") == "place":
			break
		place_task = writer.make("inside")
	session._close_dialogue()
	session.tasks[session.current] = place_task
	session._new_task()
	session._show_task()
	var item: String = place_task.item
	goods.pick_up(goods.items[item])
	await frames(2)
	goods._release_at(free_spot(goods, item))
	await create_timer(1.3).timeout
	check(session._talking == "" and Board.shared().done("warehouse_ramon") == done0 and session.tasks[session.current] == place_task, "wrong put-down: no message, no penalty, task still open")
	game.warehouse_card.hint_button.pressed.emit()
	check(session._hint_level == 1 and session._talking == "warehouse.hint" and game.shop_panel.is_dialogue_visible() and (goods._marker == null or not goods._marker.visible), "card ?: first hint, a clue without the marker")
	session._close_dialogue()
	talk_to(twin)
	check(game.shop_panel.has_choices(), "talking to Ramón offers a hint")
	game.shop_panel.choice_pressed.emit("warehouse_ask_hint")
	check(session._hint_level == 2 and goods._marker != null and goods._marker.visible and goods._marker.position.distance_to(goods.center(item)) < .1, "Ramón's hint goes on to level 2: the thing marked green")
	session._close_dialogue()
	goods.pick_up(goods.items[item])
	await frames(2)
	game.warehouse_card.hint_button.pressed.emit()
	var spot: Array = writer.region(place_task.goal, item)
	check(session._hint_level == 2 and goods._marker.position.distance_to(spot[0]) < .1, "carrying it, the hint marks its place")
	session._close_dialogue()
	goods._release_at(spot_for(goods, item, place_task.goal))
	await frames(3)
	goods.pick_up(goods.items[item])
	await create_timer(1.0).timeout
	check(Board.shared().done("warehouse_ramon") == done0, "in the right place for a moment, picked up again: not counted")
	goods._release_at(spot_for(goods, item, place_task.goal))
	await frames(8)
	check(Board.shared().done("warehouse_ramon") == done0, "not counted before it settles")
	await create_timer(1.2).timeout
	check(Board.shared().done("warehouse_ramon") == done0 + 1 and game.warehouse_card.is_praising() and not game.shop_panel.is_dialogue_visible(), "settled in the right place: praised on the task card (no box below), counted: " + game.warehouse_card.task_label.text)
	await create_timer(session.PRAISE_SECONDS + .3).timeout
	check(not game.warehouse_card.is_praising() and game.warehouse_card._task == session._line(session.tasks[session.current]), "after the praise the card shows the next task")
	check(not goods._marker.visible and session._hint_level == 0, "marker cleared, hints start again for the next task")
	# Session flow 2: weigh; a wrong answer, the screen hint, the right answer.
	var weigh: Dictionary = writer.make("weigh")
	for attempt in 100:
		if weigh.get("kind", "") == "weigh":
			break
		weigh = writer.make("weigh")
	session._close_dialogue()
	session.tasks[session.current] = weigh
	await put_on_device(goods, weigh)
	await frames(3)
	check(session._talking == "warehouse.ask" and game.shop_panel.has_choices(), "on the scale: Ramón asks the weight")
	var wrong: int = session._choices.find(session._choices.filter(func(n): return n != session._answer)[0])
	game.shop_panel.choice_pressed.emit("warehouse_answer_%d" % wrong)
	check(session._talking == "warehouse.wrong_answer", "wrong weight: try again / tell me")
	game.shop_panel.choice_pressed.emit("warehouse_hint")
	check(session._talking == "warehouse.hint" and game.shop_panel.has_choices(), "tell me: read the screen, choices again")
	game.shop_panel.choice_pressed.emit("warehouse_answer_%d" % session._choices.find(session._answer))
	check(Board.shared().done("warehouse_ramon") == done0 + 2, "right weight counted")
	# Session flow 3: give me: talking to Ramón while carrying it, he says to put it in front of
	# him (8 Nov 2026: two verbs); put down there, the task is done.
	# A placement is only watched once the praise on the card has given way to the task.
	await create_timer(session.PRAISE_SECONDS + .3).timeout
	var give: Dictionary = writer.make("give")
	session._close_dialogue()
	session.tasks[session.current] = give
	goods.pick_up(goods.items[give.item])
	session._close_dialogue()
	talk_to(twin)
	await frames(2)
	check(session._talking == "warehouse.lift_then" and goods.carried == goods.items[give.item], "talking while carrying: Ramón says to put it in front of him")
	session._close_dialogue()
	goods._release_at(spot_for(goods, give.item, give.goal))
	await frames(60)
	check(Board.shared().done("warehouse_ramon") == done0 + 3 and goods.carried == null, "put down in front of Ramón: done")
	# Session flow 4: ¿Dónde está…? asked by talking to Ramón.
	session._close_dialogue()
	var where: Dictionary = writer.make("be")
	session.tasks[session.current] = where
	talk_to(twin)
	check(session._talking == "warehouse.ask" and game.shop_panel.has_choices(), "where: Ramón asks with three places")
	game.shop_panel.choice_pressed.emit("warehouse_answer_%d" % session._choices.find(session._answer))
	check(Board.shared().done("warehouse_ramon") == done0 + 4 and game.warehouse_card.title_label.text != "", "right place answer counted: " + game.warehouse_card.title_label.text)
	session._close_dialogue()

## The copy's layout and the ten-task plan (8 Nov 2026), on the starting arrangement.
func plan_checks(game, session, copy: Node3D) -> void:
	var goods = session.goods
	var writer = session.writer
	var lexicon = session.lexicon
	check(copy.find_child("Rack C shelf 0", true, false) == null and copy.find_child("Rack A shelf 0", true, false) != null and copy.find_child("Rack B shelf 0", true, false) != null, "copy: racks A and B, no rack C")
	var spots: Array = goods.containers.values().map(func(box): return Vector2(box.center.x, box.center.z))
	check(Warehouse.GAME_CONTAINERS.all(func(at): return spots.any(func(s): return s.distance_to(at) < .01)), "both containers stand where rack C was: %s" % [spots])
	check(spots.all(func(s): return s.y + goods.CONTAINER_SIZE.z * .5 < Warehouse.HALL_Z1 - Warehouse.T - .3 and absf(s.x) > goods.CONTAINER_SIZE.x * .5 + .4), "containers clear of the rear wall and the main aisle")
	var plan: Array = session.tasks
	check(plan.size() == 10 and session.plan_problems.is_empty(), "10 tasks planned before the game (%d; %s)" % [plan.size(), session.plan_problems])
	var problems: Array = writer.validate(plan)
	check(problems.is_empty(), "the plan replays: every task possible in its turn: %s" % [problems])
	var uses: Dictionary = Tasks._uses(plan)
	check(uses.values().all(func(n): return n <= 2), "no thing or place in more than 2 of 10 tasks: %s" % [uses])
	var repeats := 0
	for i in range(1, plan.size()):
		if Tasks.objects(plan[i]).any(func(id): return id in Tasks.objects(plan[i - 1])):
			repeats += 1
	check(repeats == 0, "no thing twice in a row (%d)" % repeats)
	var bad_text: Array = []
	for task in plan:
		print("  plan: ", lexicon.text(task, "es"), " | ", lexicon.text(task, "en"))
		for level in [1, 2]:
			var hint: Dictionary = writer.hint(task, level)
			for lang in ["es", "en", "zh"]:
				for text in [lexicon.text(task, lang), lexicon.text(hint.say, lang)]:
					if "{" in text or text.begins_with("warehouse.") or "Ordena el almacén" in text or "Organize the warehouse" in text or (lang == "es" and (" de el " in text or " a el " in text)):
						bad_text.append(lang + ": " + text)
	check(bad_text.is_empty(), "planned tasks and both hint levels render, no 'Organize the warehouse:' opener: %s" % [bad_text.slice(0, 3)])
	# More plans for the same arrangement: every one keeps the rules, and they differ.
	var different := {}
	var broken: Array = []
	var entry_counts := {}
	for n in 30:
		var planned: Dictionary = writer.plan(10)
		var found: Array = planned.problems + writer.validate(planned.tasks)
		if not found.is_empty() or planned.tasks.size() != 10 or Tasks._uses(planned.tasks).values().any(func(k): return k > 2):
			broken.append(found)
		different[str(planned.tasks.map(func(t): return [t.entry, Tasks.objects(t)]))] = true
		for t in planned.tasks:
			entry_counts[t.entry] = int(entry_counts.get(t.entry, 0)) + 1
	check(broken.is_empty(), "30 more plans keep every rule: %s" % [broken.slice(0, 2)])
	check(different.size() >= 28, "plans differ (%d different of 30)" % different.size())
	check(entry_counts.size() >= 30, "plans use many entries (%d of 37 in 300 tasks)" % entry_counts.size())
	# A task made impossible meanwhile is replaced by a backup under the same rules.
	var cabinet := {"entry": "close" if goods.cabinet_open else "open", "kind": "cabinet", "open": not goods.cabinet_open, "phrase": "warehouse.task_close" if goods.cabinet_open else "warehouse.task_open", "values": {}}
	check(writer.still_valid(cabinet), "a cabinet task is possible")
	goods.set_cabinet(cabinet.open)
	check(not writer.still_valid(cabinet), "once done by the player it is not")
	var list: Array = plan.duplicate()
	list[3] = cabinet
	var spare: Dictionary = writer.backup(list, 3)
	list[3] = spare
	check(not spare.is_empty() and writer.still_valid(spare) and Tasks._uses(list).values().all(func(k): return k <= 2), "backup for task 4: possible and within the 2-of-10 rule (%s)" % spare.get("entry", ""))
	var keep: Dictionary = session.tasks[session.current]
	session.tasks[session.current] = cabinet
	session._new_task()
	check(session.tasks[session.current] != cabinet and writer.still_valid(session.tasks[session.current]), "the session swaps it for a backup when its turn comes")
	session.tasks[session.current] = keep
	goods.set_cabinet(not cabinet.open)
	# Practice words: the thing, and the size and colour its name says (8 Nov 2026).
	var medium: String = goods.boxes.filter(func(id): return id.begins_with("box_medium_"))[0]
	var lift := {"entry": "lift", "kind": "hold", "item": medium, "phrase": "warehouse.task_lift", "values": {"item": Tasks.thing(medium)}}
	var colour: String = Tasks.COLOR_WORDS[medium.get_slice("_", 2)]
	check(writer.words(lift) == ["cardboard box", "medium", colour], "a box task practises box, size and colour: %s" % [writer.words(lift)])
	check(writer.words({"kind": "color", "item": medium}) == [colour], "a colour question practises the colour")
	var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json")).words
	check(words.has("brown") and words.has("medium") and words.brown.text.es == "marrón" and words.medium.text.es == "mediano" and Tasks.COLOR_WORDS.brown == "brown", "brown and medium are vocabulary words")
	session.tasks[session.current] = lift
	session._show_task()
	check(PracticeLog.shared().game_id() == "warehouse_ramon" and PracticeLog.shared()._keys == ["cardboard box", "medium", colour], "the session tracks them: %s" % [PracticeLog.shared()._keys])
	# Back to a question, so moving things for the checks below finishes nothing.
	var suitcase: String = suitcase_id(goods)
	session.tasks[session.current] = {"kind": "where", "item": suitcase, "entry": "be", "phrase": "warehouse.task_where", "values": {"item": Tasks.thing(suitcase)}}

## E on the hall door or the roll-up loading gate asks to leave; No keeps the game and its
## progress; carrying something, E puts it down instead.
func exits(game, session, copy: Node3D) -> void:
	var goods = session.goods
	session._close_dialogue()
	var done0: int = Board.shared().done("warehouse_ramon")
	for spec in [["hall door", Vector3(-.3, Warehouse.FLOOR, Warehouse.HALL_Z0 + 2.2), Vector3(-.3, Warehouse.FLOOR + 1.3, Warehouse.HALL_Z0 + .1)], ["loading gate", Vector3(-12.2, Warehouse.FLOOR, Warehouse.HALL_Z0 + 2.2), Vector3(-12.2, Warehouse.FLOOR + 1.8, Warehouse.HALL_Z0 + .1)]]:
		await aim_at(game, copy, spec[1], spec[2])
		check(press_e(game) and game.shop_panel.is_quit_open(), "E on the " + spec[0] + " asks to leave")
		game.shop_panel.quit_answered.emit(false)
		await frames(2)
		check(session.in_game() and not game.shop_panel.is_quit_open() and Board.shared().done("warehouse_ramon") == done0, "No: still in the game, progress kept (" + spec[0] + ")")
	var id: String = suitcase_id(goods)
	goods.pick_up(goods.items[id])
	await frames(2)
	check(press_e(game) and goods.carried == null and not game.shop_panel.is_quit_open(), "carrying at the gate: E puts it down, no leave question")
	await frames(20)
	# A left click does what E does and never opens a word card (user, 8 Nov 2026): click the
	# suitcase to pick it up, then click a floor spot to put it down there.
	var camera: Camera3D = game.interaction.camera
	await click(game, camera.unproject_position(goods.items[id].global_position))
	check(goods.carried == goods.items[id] and not is_instance_valid(game.interaction.selected), "left click picks the suitcase up, no word card")
	var spot := Vector3(-11.3, Warehouse.FLOOR, Warehouse.HALL_Z0 + 1.0)
	await click(game, camera.unproject_position(goods.to_world(spot)))
	var at: Vector3 = goods.center(id)
	check(goods.carried == null and Vector2(at.x - spot.x, at.z - spot.z).length() < .7 and not is_instance_valid(game.interaction.selected), "left click puts it down where clicked (%.2f m off), no word card" % Vector2(at.x - spot.x, at.z - spot.z).length())
	await frames(20)

func click(game, at: Vector2) -> void:
	game.interaction.pointer_position = at
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	game._unhandled_input(event)
	await frames(3)

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

func suitcase_id(goods) -> String:
	return goods.items.keys().filter(func(id): return id.begins_with("suitcase_"))[0]

## The big box (8 Nov 2026): trolley-only. E does not lift it, it rides its trolley with what
## is stacked on it, it is never a shelf / table / scale task, and "on top of the big box" is.
func big_box(game, session, goods, twin: Node3D) -> void:
	var big: String = goods.big_box
	check(big.begins_with("box_big_") and goods.trolley_only(big) and goods.items[big].freeze, "big box is frozen and trolley-only: " + big)
	var carrier: Dictionary = {}
	for trolley in goods.trolleys:
		if trolley.get("cargo", "") == big:
			carrier = trolley
	check(not carrier.is_empty(), "big box rides a trolley")
	if carrier.is_empty():
		return
	var at: Vector3 = goods.center(big)
	game.player.global_position = goods.to_world(Vector3(at.x, Warehouse.FLOOR + .1, at.z + 1.9))
	var told := [false]
	goods.too_heavy.connect(func() -> void: told[0] = true, CONNECT_ONE_SHOT)
	check(goods.use(goods.items[big], twin) and goods.carried == null and told[0], "E on the big box: not lifted, too-heavy toast")
	var tall: float = goods.half(big).y * 2.0
	check(tall > 1.2 and tall < 1.71, "big box almost as tall as the pig (%.2f of 1.71)" % tall)
	# Clear the big box (a small box may start on it), then stack one small box.
	for id in goods.items:
		if goods.on_top_of(id, big):
			goods.place_at(id, free_spot(goods, id))
	await frames(10)
	# A small box not in a container (one may start there, for "take out").
	var small: String = goods.boxes.filter(func(id): return id.begins_with("box_small_") and goods.inside_of(id) == "")[0]
	var home: Vector3 = goods.center(small)
	goods.place_at(small, spot_for(goods, small, {"pos": "on_top", "ref": big}))
	await frames(30)
	check(goods.on_top_of(small, big), "a small box stands on the big box (small bottom %.2f, big top %.2f, small at %s, big at %s)" % [goods.bottom(small), goods.top(big), goods.center(small), goods.center(big)])
	var z0: float = carrier.z
	var target: float = goods.TROLLEY_Z.x if z0 > (goods.TROLLEY_Z.x + goods.TROLLEY_Z.y) * .5 else goods.TROLLEY_Z.y
	goods._move_trolley(carrier, target)
	await frames(20)
	check(absf(goods.center(big).z - target) < .05 and goods.on_top_of(small, big), "big box and its rider move with the trolley")
	var writer = session.writer
	var stacked := false
	for attempt in 80:
		var task: Dictionary = writer.make("on_top")
		if task.get("kind", "") == "place" and task.goal.ref == big:
			stacked = true
			print("  on_top big box: ", session.lexicon.text(task, "es"), " | ", session.lexicon.text(task, "en"))
			break
	check(stacked or goods.covered(big), "an on-top task can use the big box")
	for entry in ["lift", "weigh", "measure", "top_shelf", "on", "carry", "bring"]:
		for attempt in 10:
			var task: Dictionary = writer.make(entry)
			check(task.get("item", "") != big, entry + " never uses the big box")
	goods.place_at(small, home)
	await frames(20)

## Moves goods as a player would so a task is met.
func solve(goods, task: Dictionary, twin: Node3D, player: Node3D) -> void:
	match str(task.kind):
		"place":
			goods.pick_up(goods.items[task.item])
			await frames(2)
			goods._release_at(spot_for(goods, task.item, task.goal))
		"hold":
			goods.pick_up(goods.items[task.item])
		"bring":
			var b: Vector3 = goods.to_hall(twin.global_position)
			goods.place_at(task.item, Vector3(b.x + .9, Warehouse.FLOOR + goods.half(task.item).y + .02, b.z + .4))
		"push":
			goods._move_trolley(goods.trolley_for(task.zone), goods.TROLLEY_Z.x)
		"pull":
			goods._move_trolley(goods.trolley_for(task.zone), goods.TROLLEY_Z.y)
		"cabinet":
			goods.set_cabinet(task.open)
		"go":
			player.global_position = goods.to_world(Vector3(Warehouse.GAME_RACKS[task.rack][1], Warehouse.FLOOR + .1, Warehouse.RACK_Z - 1.6))
	await frames(45)

func put_on_device(goods, task: Dictionary) -> void:
	for other in goods.items:
		if other != task.item and (goods.on_scale(other) if task.kind == "weigh" else goods.on_table(other, "measure")):
			goods.place_at(other, free_spot(goods, other))
	var h: Vector3 = goods.half(task.item)
	if task.kind == "weigh":
		goods.place_at(task.item, goods.SCALE_AT + Vector3(0, Warehouse.FLOOR + goods.SCALE_TOP + h.y + .02, 0))
	else:
		goods.place_at(task.item, goods.MEASURE_TABLE + Vector3(-.4, Warehouse.FLOOR + Warehouse.MEASURE_PLATE_TOP + h.y + .02, -.1))
	await frames(40)

## A hall-local centre that meets a goal.
func spot_for(goods, id: String, goal: Dictionary) -> Vector3:
	var h: Vector3 = goods.half(id)
	var ground := Warehouse.FLOOR + h.y + .02
	var ref := str(goal.get("ref", ""))
	match str(goal.pos):
		"on_top":
			var r: Vector3 = goods.ref_center(ref)
			return Vector3(r.x, r.y + goods.ref_half(ref).y + h.y + .02, r.z)
		"under":
			return Vector3(goods.WORK_TABLE.x, ground, goods.WORK_TABLE.z)
		"front", "behind", "left", "right":
			var r: Vector3 = goods.ref_center(ref)
			var axis: Vector2 = goods.side_axis(ref, str(goal.pos))
			var reach: float = goods.reach(goods.ref_half(ref), h, axis) + (.15 if goal.pos == "behind" else .4)
			# Step further out (still inside the 1.8 area) when an earlier task left something there.
			for extra in ([0.0] if goal.pos == "behind" else [0.0, .6, 1.2]):
				var at := Vector3(r.x + axis.x * (reach + extra), ground, r.z + axis.y * (reach + extra))
				if not goods.items.keys().any(func(other): return other != id and other != ref and absf(goods.center(other).x - at.x) < h.x + goods.half(other).x + .05 and absf(goods.center(other).z - at.z) < h.z + goods.half(other).z + .05):
					return at
			return Vector3(r.x + axis.x * reach, ground, r.z + axis.y * reach)
		"next_to", "outside", "out_of":
			var r: Vector3 = goods.ref_center(ref)
			var rh: Vector3 = goods.ref_half(ref)
			if goods.bay_of(ref) >= 0:
				var side: Vector2 = goods.side_axis(ref, "left")
				var reach: float = goods.reach(rh, h, side) + .4
				return Vector3(r.x + side.x * reach, ground, r.z + side.y * reach)
			return Vector3(r.x - rh.x - h.x - .4, ground, r.z)
		"inside":
			return goods.containers[ref].center + Vector3(0, h.y + .02, 0)
		"on":
			if ref == "scale":
				return goods.SCALE_AT + Vector3(0, Warehouse.FLOOR + goods.SCALE_TOP + h.y + .02, 0)
			return Vector3(goods.WORK_TABLE.x + .55, Warehouse.FLOOR + goods.TABLE_HEIGHT + h.y + .02, goods.WORK_TABLE.z)
		"top_shelf", "bottom_shelf", "up", "down", "at_top", "at_bottom":
			var r: int = Tasks.RACK_LETTERS.find(ref.trim_prefix("rack_")) if ref.begins_with("rack_") else 0
			var level := 2 if goal.pos in ["top_shelf", "at_top", "up"] else 0
			var x: float = Warehouse.GAME_RACKS[r][1]
			for offset in [1.6, -1.6, 0.55, -0.55]:
				var clear := true
				for other in goods.items:
					var spot: Array = goods.rack_spot(other)
					if other != id and not spot.is_empty() and spot[0] == r and spot[1] == level and absf(goods.center(other).x - (x + offset)) < .85:
						clear = false
				if clear:
					x += offset
					break
			return Vector3(x, Warehouse.FLOOR + Warehouse.RACK_LEVELS[level] + .02 + h.y + .02, Warehouse.RACK_Z)
		"off":
			return free_spot(goods, id)
		"in":
			var rect: Rect2 = goods.zone_rect(ref)
			return Vector3(rect.position.x + .6 if ref == "zone_in" else rect.end.x - .5, ground, rect.get_center().y)
		"boss_front":
			var f: Vector3 = goods.boss_front(_twin)
			return Vector3(f.x, ground, f.z)
	return free_spot(goods, id)

## Fifth round (8 Nov 2026): goods a fifth bigger with weight by size, two-verb lift and
## give-me tasks, the upright ruler, no word cards in a minigame, trolleys rolled by walking.
func round5(game, session, goods, writer, twin: Node3D) -> void:
	var by_size := true
	for id in goods.items:
		var kind: String = id.get_slice("_", 1) if id.begins_with("box_") else id.get_slice("_", 0)
		var w: Array = goods.WEIGHTS[kind]
		by_size = by_size and int(goods.items[id].get_meta("weight")) >= w[0] and int(goods.items[id].get_meta("weight")) <= w[1]
	check(by_size, "every weight within its size's range")
	check(goods.half(goods.big_box).x * 2.0 < goods.TROLLEY_DECK.x and goods.BOX_SIZES.medium[0].y < goods.SHELF_CLEAR, "big box fits the wider deck, medium boxes still fit a shelf")
	for entry in ["lift", "pick_up", "look_for", "find", "bring", "give"]:
		var task: Dictionary = {}
		for attempt in 20:
			task = writer.make(entry)
			if not task.is_empty() and task.kind != "color":
				break
		var es: String = session.lexicon.text(task, "es")
		var two: bool = task.get("kind", "") == "place" and task.get("lift", false) and " pon" in es and not "{" in es
		if entry in ["bring", "give"]:
			two = two and task.goal.pos == "boss_front" and "delante de mí" in es
		check(two, "two verbs for %s: %s | %s" % [entry, es, session.lexicon.text(task, "en")])
	for attempt in 20:
		var weigh: Dictionary = writer.make("weigh")
		if weigh.get("kind", "") == "compare":
			check(weigh.items[0].get_slice("_", 1) == weigh.items[1].get_slice("_", 1), "a weight comparison uses two boxes of one size")
			break
	# The upright ruler reads the height of a thing on its base.
	var medium: String = goods.boxes.filter(func(id): return id.begins_with("box_medium_") and goods.bay_of(id) < 0)[0]
	var home: Vector3 = goods.center(medium)
	goods.place_at(medium, goods.MEASURE_TABLE + Vector3(-.3, Warehouse.FLOOR + Warehouse.MEASURE_PLATE_TOP + goods.half(medium).y + .02, 0))
	await frames(30)
	check(goods.on_table(medium, "measure") and goods._measure_label.text == "66 cm", "the upright ruler reads the medium box: " + goods._measure_label.text)
	goods.place_at(medium, home)
	await frames(20)
	# No word card while a minigame runs.
	check(game.interaction.minigame_running(), "the warehouse game counts as a running minigame")
	game.interaction.pointer_position = game.interaction.camera.unproject_position(goods.items[medium].global_position)
	game.interaction.click()
	check(not is_instance_valid(game.interaction.selected), "no word card in the game")
	# A two-verb task: picking its thing up makes Ramón say what comes next.
	var saved: Dictionary = session.tasks[session.current]
	var lift := {"entry": "lift", "kind": "place", "lift": true, "item": medium, "goal": {"pos": "on", "ref": "table"}, "phrase": "warehouse.task_lift", "values": {"item": Tasks.thing(medium), "it": {"phrase": "warehouse.it_f"}, "place": Tasks.place({"pos": "on", "ref": "table"}, true)}}
	session.tasks[session.current] = lift
	session._close_dialogue()
	goods.pick_up(goods.items[medium])
	await frames(3)
	check(session._talking == "warehouse.lift_then" and lift.get("lifted", false), "picked up: Ramón says what to do next: " + session.lexicon.text({"phrase": "warehouse.lift_then", "values": {"it": lift.values.it, "place": lift.values.place}}, "es"))
	goods._release_at(home)
	session._close_dialogue()
	session.tasks[session.current] = saved
	await frames(20)
	# Walking into a trolley rolls it along its lane, slower than a grabbed one.
	var trolley: Dictionary = goods.trolleys[0]
	var z0: float = trolley.z
	var toward: Vector3 = goods.to_world(Vector3(0, 0, -1)) - goods.to_world(Vector3.ZERO)
	if z0 < goods.TROLLEY_Z.x + 1.0:
		toward = -toward
	goods._roll_trolley(trolley, toward.normalized(), 1.0)
	var rolled: float = absf(trolley.z - z0)
	check(rolled > .3 and rolled < goods.TROLLEY_SPEED * .5, "walking into a trolley rolls it slowly along its lane (%.2f in 1 s)" % rolled)
	goods._move_trolley(trolley, z0)
	await frames(10)

var _spots := 0
## Separate floor spots south of the free hall, so put-downs never overlap.
func free_spot(goods, id: String) -> Vector3:
	_spots += 1
	return Vector3(-0.8 + (_spots % 5) * 1.2, Warehouse.FLOOR + goods.half(id).y + .02, 13.6 + (_spots / 5 % 3) * 1.2)

## A question task: put things on the device where needed, then the question has its answer
## among the choices (and a comparison waits until both were read alone).
func answerable(goods, writer, task: Dictionary, entry: String) -> void:
	if task.kind in ["weigh", "measure"]:
		await put_on_device(goods, task)
		check(writer.ready_to_ask(task), entry + ": ready to ask once on its device")
		var reading: String = goods._scale_label.text if task.kind == "weigh" else goods._measure_label.text
		var expected := "%d %s" % [int(goods.items[task.item].get_meta("weight" if task.kind == "weigh" else "height")), "kg" if task.kind == "weigh" else "cm"]
		check(reading == expected, entry + ": readout shows " + expected + " (got " + reading + ")")
	if task.kind == "compare":
		check(not writer.ready_to_ask(task), entry + ": comparison waits for both")
		for id in task.items:
			await put_on_device(goods, {"kind": task.device, "item": id})
			writer.note_device(task)
			goods.place_at(id, free_spot(goods, id))
			await frames(5)
		check(writer.ready_to_ask(task), entry + ": comparison ready after both were read")
	var asked: Dictionary = writer.question(task)
	var count := 2 if task.kind == "compare" else 3
	check(asked.choices.size() == count and asked.answer in asked.choices and asked.labels.size() == count, "%s (%s): %d choices with the answer" % [entry, task.kind, count])
	if task.kind == "where" or task.kind == "what":
		var goal: Dictionary = asked.answer if task.kind == "where" else task.goal
		check(writer.reached(task.item, goal), entry + ": the answer is true")
	if task.kind == "compare":
		var key := "weight" if task.device == "weigh" else "height"
		var a: int = int(goods.items[asked.answer].get_meta(key))
		var other: String = task.items[0] if task.items[1] == asked.answer else task.items[1]
		var b: int = int(goods.items[other].get_meta(key))
		check((a > b) == bool(task.more), entry + ": comparison answer is right")
	var hint: Array = writer.question_hint(task, asked.answer)
	check(not hint[0].is_empty(), entry + ": a hint for " + str(task.kind))

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
