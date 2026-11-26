extends SceneTree
## Stack & Pack word pool (user, 25 Nov 2026: track the position words too). Starts a warehouse
## game through Ramón and plays four tasks as a player would, reading what the practice log
## records (practice_log.gd `recorded`):
##   top_shelf  the right box first put on the table (a wrong named place): colour right, "up" missed
##   on         a wrong box picked up first: colour missed, "on" right
##   right      the place hint (level 2, box carried) marks the goal: colour right, "right" missed
##   next_to    done straight away: both right
## Also: every position word is a words.json key, and a task's practice words are its colour
## plus its position word. Uses Main, which saves progress: run with an isolated HOME.
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/word-pools-20261125/verify.gd
const Warehouse := preload("res://scripts/world/warehouse.gd")
const Tasks := preload("res://scripts/learning/warehouse_tasks.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
var failures := 0
var checks := 0
var outcomes: Array = []
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func finish() -> void:
	print("WORD POOLS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func run():
	var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json")).words
	for entry in Tasks.POSITIONS:
		var key := Tasks.place_word({"entry": entry})
		check(words.has(key), "%s practises the words.json key '%s'" % [entry, key])
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	await frames(3)
	var town: Node3D = game.apartment
	var session: Node = game.get_node_or_null("WarehouseSession")
	check(session != null, "session exists")
	if session == null:
		finish(); return
	PracticeLog.shared().recorded.connect(func(game_id: String, got: Dictionary) -> void:
		if game_id == "warehouse_ramon":
			outcomes.append(got.duplicate()))
	game.player.global_position = town.get_node("Warehouse").to_global(Vector3(-10.0, .2, -3.6))
	preload("res://scripts/core/interactable.gd").on(town.get_node("Warehouse/Exterior/Ramon")).activate()
	game.shop_panel.choice_pressed.emit("warehouse_play")
	await create_timer(2.0).timeout
	check(session.in_game(), "game started")
	if not session.in_game():
		finish(); return
	var goods = session.goods
	var writer = session.writer
	session._close_dialogue()

	# top_shelf: put on the table first.
	var task := await begin(session, "top_shelf")
	if not task.is_empty():
		check(writer.words(task).has("up") and writer.words(task).size() == 2, "a top-shelf task practises its colour and 'up': %s" % [writer.words(task)])
		await put(goods, task.item, spot_for(goods, task.item, {"pos": "on", "ref": "table"}))
		check(goods.on_table(task.item) and session._missed.has("up") and session._missed.size() == 1, "the right box on the table misses 'up' only: %s" % [session._missed])
		await put(goods, task.item, spot_for(goods, task.item, task.goal))
		expect(task, false, true)

	# on: a wrong box picked up first.
	task = await begin(session, "on")
	if not task.is_empty():
		var other: String = goods.items.keys().filter(func(id): return id != task.item and goods.bay_of(id) < 0)[0]
		goods.pick_up(goods.items[other])
		await frames(2)
		session._close_dialogue()
		goods._release_at(goods.center(other) + Vector3(0, .05, 0))
		await frames(40)
		await put(goods, task.item, spot_for(goods, task.item, task.goal))
		expect(task, true, false)

	# right: the level-2 hint while carrying marks the place.
	task = await begin(session, "right")
	if not task.is_empty():
		goods.pick_up(goods.items[task.item])
		await frames(2)
		session.give_hint()
		session.give_hint()
		session._close_dialogue()
		check(session._missed.has("right") and session._missed.size() == 1, "the place hint misses 'right' only: %s" % [session._missed])
		goods._release_at(spot_for(goods, task.item, task.goal))
		await frames(120)
		expect(task, false, true)

	# next_to: straight away.
	task = await begin(session, "next_to")
	if not task.is_empty():
		await put(goods, task.item, spot_for(goods, task.item, task.goal))
		expect(task, false, false)
	finish()

## Makes a task of `entry` the current one and shows it ({} when none can be written now).
func begin(session, entry: String) -> Dictionary:
	await create_timer(.3).timeout
	session._praise_left = 0.0
	session._close_dialogue()
	var task: Dictionary = {}
	for attempt in 8:
		task = session.writer.make(entry)
		if not task.is_empty():
			break
	check(not task.is_empty(), entry + " task written")
	if task.is_empty():
		return {}
	session.tasks[session.current] = task
	session._new_task()
	session.tasks[session.current] = task
	session._show_task()
	check(PracticeLog.shared()._keys == session.writer.words(task), "%s tracked: %s" % [entry, PracticeLog.shared()._keys])
	outcomes.clear()
	return task

func put(goods, id: String, spot: Vector3) -> void:
	goods.pick_up(goods.items[id])
	await frames(2)
	goods._release_at(spot)
	await frames(120)

## The one recorded question of `task`: its colour and its position word, each positive unless missed.
func expect(task: Dictionary, colour_missed: bool, place_missed: bool) -> void:
	var colour: String = Tasks.COLOR_WORDS.get(str(task.item).get_slice("_", 1), "")
	var place := Tasks.place_word(task)
	var want := {colour: "negative" if colour_missed else "positive", place: "negative" if place_missed else "positive"}
	check(outcomes.size() == 1 and outcomes[0] == want, "%s recorded %s (want %s)" % [task.entry, outcomes, want])

## A hall-local centre that meets a goal (as docs/evidence/warehouse-20261114/verify_game.gd).
func spot_for(goods, id: String, goal: Dictionary) -> Vector3:
	var h: Vector3 = goods.half(id)
	var ground := Warehouse.FLOOR + h.y + .02
	var ref := str(goal.get("ref", ""))
	match str(goal.pos):
		"right", "next_to":
			var r: Vector3 = goods.ref_center(ref)
			# "next to" on the left (the right side may already hold the "right" task's box).
			var axis: Vector2 = goods.side_axis(ref, "left" if str(goal.pos) == "next_to" else "right")
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
