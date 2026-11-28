extends RefCounted
## Writes and checks Warehouse Worker tasks (Phase 5, 5 Nov 2026; simplified 14 Nov 2026; guide:
## docs/guides/WAREHOUSE.md#minigame-14-nov-2026). No language here: a task names phrase ids
## (data/phrases.json group "warehouse") and the Lexicon writes the sentence.
##
## Basic spatial vocabulary (user, 14 Nov 2026), four kinds of task, each an entry:
##   "on"         Pon la caja azul sobre la mesa.
##   "next_to"    Pon la caja roja al lado de la caja verde.
##   "right"      Pon la caja roja a la derecha de la caja verde.
##   "top_shelf"  Pon la caja amarilla en el estante de arriba.
## The reference for "next to" and "to the right of" is the box standing in the wall bay (the
## green one). Right is as seen by the player standing in front of it and facing it and the
## wall behind it (warehouse_goods.gd side_axis(); the bay is on the west wall, so right is
## north). "a la derecha de" counts as practice of the existing word "right".
##
## Task plan (user, 8 Nov 2026; guide: docs/guides/WAREHOUSE.md#task-plan-8-nov-2026): `plan()` writes
## all of a game's tasks before it starts, against warehouse_plan.gd, a view of the arrangement
## that moves things where each planned task leaves them, so every task can be done and is not
## already done when its turn comes. A game asks to handle one thing, or sends the player to one
## place, in at most MAX_SHARE of its tasks (two of five), and avoids the same thing or place
## twice in a row. `validate()` replays a whole plan; `still_valid()` checks a task again when
## its turn comes (the player may have moved things), and `backup()` writes a replacement under
## the same rules. A task is a dictionary:
##   "phrase", "values"   the sentence (a Lexicon reference; the task card shows it)
##   "entry"              the entry it practises (one of POSITIONS)
##   "kind"               "place"
##   "item"               the thing to put (item id)
##   "goal"               {"pos": position, "ref": reference id or ""}
## References: the bay's item id, "table", "" (the top shelf).
const Warehouse := preload("res://scripts/world/warehouse.gd")

const POSITIONS := ["on", "next_to", "right", "top_shelf"]
## The verb of every task, and its template.
const PLACING := {"put": "warehouse.task_put"}
## Most goods the table takes (it is 3 wide; a box is 0.92).
const TABLE_CAPACITY := 3
## The plan: at most this share of a game's tasks handle one thing; tries before giving up
## (the session then builds a new arrangement, warehouse_session.gd ARRANGE_TRIES).
const MAX_SHARE := .4
const PLAN_TRIES := 40
const Plan := preload("res://scripts/learning/warehouse_plan.gd")
const Goods := preload("res://scripts/learning/warehouse_goods.gd")
## Practice words (practice_log.gd) of the colours in task sentences (tools/vocabulary_report.gd
## reads these three tables).
const COLOR_WORDS := {"red": "red", "blue": "blue", "green": "green", "yellow": "yellow"}
const SIZE_WORDS := {}
## The position word each kind of task practises (user, 25 Nov 2026: Stack & Pack also tracks
## its positions). "en el estante de arriba" practises "up" (arriba).
const POSITION_WORDS := {"on": "on", "next_to": "next to", "right": "right", "top_shelf": "up"}

var goods
var boss: Node3D
var rng: RandomNumberGenerator
var _unused: Array = []

func _init(session_goods, ramon_twin: Node3D, random: RandomNumberGenerator) -> void:
	goods = session_goods
	boss = ramon_twin
	rng = random

## The current level's positions (data/activities.json warehouse_ramon "levels" "positions";
## LEARN-06, 25 Nov 2026); empty = all of POSITIONS.
var positions: Array = []

func entries() -> Array:
	return positions.duplicate() if not positions.is_empty() else POSITIONS.duplicate()

## The next task: entries are drawn without repeats until all were used.
func next() -> Dictionary:
	for attempt in 40:
		if _unused.is_empty():
			_unused = entries()
		var entry: String = _unused[rng.randi() % _unused.size()]
		var task := make(entry)
		if not task.is_empty():
			_unused.erase(entry)
			return task
	return {}

## A task for one entry in the current arrangement, or {} when none can be done now.
## `prefer_wanted`: the box the word memory wants most (_pick_item()); false picks any box, so
## the plan's retries can vary when the wanted box breaks its rules (25 Nov 2026: a due colour
## made every retry pick the same box and plans of 5 failed).
func make(entry: String, prefer_wanted := true) -> Dictionary:
	if not entry in POSITIONS:
		return {}
	return _placing("put", entry, entry, prefer_wanted)

## A placing task (verb + item + place) whose goal is not already met, or {}.
func _placing(verb: String, pos: String, entry: String, prefer_wanted := true) -> Dictionary:
	var refs := _refs_for(pos)
	refs.shuffle()
	for ref in refs:
		var goal := {"pos": pos, "ref": ref}
		var movable := _items(func(id): return id != ref and _fits(id, goal) and not reached(id, goal) and _ref_ready(id, goal))
		if movable.is_empty():
			continue
		var id: String = _pick_item(movable) if prefer_wanted else str(_pick(movable))
		return {"entry": entry, "kind": "place", "item": id, "goal": goal, "phrase": PLACING[verb], "values": {"item": thing(id), "place": place(goal, true)}}
	return {}

## References that make sense for a position right now ("" = none needed).
func _refs_for(pos: String) -> Array:
	match pos:
		"next_to", "right":
			# Only things in the wall bay: the wall gives them a front, a left and a right.
			return goods.items.keys().filter(func(ref): return goods.bay_of(ref) >= 0)
		"on":
			return ["table"] if _count(func(id): return goods.on_table(id)) < TABLE_CAPACITY else []
		"top_shelf":
			return [""] if goods.on_level(_top()) < Goods.SHELF_CAPACITY else []
	return []

static func _top() -> int:
	return Warehouse.RACK_LEVELS.size() - 1

## Whether an item may be given this goal (the shelf only takes what fits under its deck).
func _fits(id: String, goal: Dictionary) -> bool:
	if str(goal.pos) == "top_shelf":
		return goods.fits_shelf(id)
	return true

func _held(id: String) -> bool:
	return goods.carried == goods.items[id]

## Goods a task may use. The thing standing in the wall bay is left there: it is the reference
## for "next to" and "to the right of", so no task asks to move or pick it up.
func _items(keep: Callable) -> Array:
	return goods.items.keys().filter(func(id): return goods.known(id) and goods.bay_of(id) < 0 and keep.call(id))

func _count(keep: Callable) -> int:
	return _items(keep).size()

func _pick(options: Array) -> Variant:
	return options[rng.randi() % options.size()]

## The item whose words (the thing and its colour) the word memory wants most (word_memory.gd,
## 24 Nov 2026): a due word, then an allowed new one; a random one among equals.
func _pick_item(ids: Array) -> String:
	var memory = preload("res://scripts/learning/word_memory.gd").shared()
	var best: Array = []
	var top := -2
	for id in ids:
		var score: int = memory.want(words({"item": id}))
		if score > top:
			top = score
			best = [id]
		elif score == top:
			best.append(id)
	return str(_pick(best))

# --- The task plan (8 Nov 2026) ----------------------------------------------------------------

## The things a task asks to handle (the share rule counts these).
static func objects(task: Dictionary) -> Array:
	var id := str(task.get("item", ""))
	return [id] if id != "" else []

## The place a task sends the player to ("" for none): not the same twice in a row.
static func place_key(task: Dictionary) -> String:
	if task.has("goal"):
		var ref := str(task.goal.get("ref", ""))
		return ref if ref != "" else str(task.goal.pos)
	return ""

## How many of a game's tasks may handle one thing (two of five).
static func share_limit(count: int) -> int:
	return maxi(1, floori(count * MAX_SHARE))

## How many of a game's tasks may send the player to one place: share_limit(), or more when a
## level has few positions (level 1's table and top shelf take turns, so each gets its share).
func place_limit(count: int) -> int:
	return maxi(share_limit(count), ceili(float(count) / float(maxi(1, entries().size()))))

## How often each thing (by id) and each place ("@" + place_key) comes up in `list`.
static func _uses(list: Array) -> Dictionary:
	var used := {}
	for task in list:
		var keys := objects(task)
		if place_key(task) != "":
			keys.append("@" + place_key(task))
		for key in keys:
			used[key] = int(used.get(key, 0)) + 1
	return used

## Writes `count` tasks for the arrangement as it is now (the game has not started).
## {"tasks": [...], "problems": []} when every rule holds; otherwise the longest list found and
## what went wrong (the session then tries a new arrangement).
func plan(count: int) -> Dictionary:
	var live = goods
	var best: Array = []
	var problems: Array = []
	for attempt in PLAN_TRIES:
		# The first half also keeps the same thing and place from coming twice in a row.
		var strict := attempt < PLAN_TRIES / 2
		goods = Plan.new(live)
		_unused = []
		var list: Array = []
		while list.size() < count:
			var task := _planned(list, count, strict)
			if task.is_empty():
				break
			list.append(task)
			goods.apply(task)
		goods = live
		if list.size() == count:
			var found := validate(list)
			if found.is_empty():
				return {"tasks": list, "problems": []}
			problems = found
		elif list.size() > best.size():
			best = list
	if problems.is_empty():
		problems = ["only %d of %d tasks could be planned in %d tries" % [best.size(), count, PLAN_TRIES]]
	return {"tasks": best, "problems": problems}

## The next planned task: entries in random order (each as likely as the others), the first
## that gives a task the rules allow.
func _planned(list: Array, count: int, strict: bool) -> Dictionary:
	var used := _uses(list)
	var last: Dictionary = list[-1] if not list.is_empty() else {}
	if _unused.is_empty():
		_unused = entries()
	for pool in [_unused.duplicate(), entries()]:
		_shuffle(pool)
		for entry in pool:
			for variant in 3:
				var task := make(entry, variant == 0)
				if not task.is_empty() and _allowed(task, used, last, share_limit(count), strict, place_limit(count)):
					_unused.erase(entry)
					return task
	return {}

## `place_limit`: how many tasks may send the player to one place (place_limit()).
func _allowed(task: Dictionary, used: Dictionary, last: Dictionary, limit: int, strict: bool, at_place := -1) -> bool:
	if at_place < 0:
		at_place = limit
	for id in objects(task):
		if int(used.get(id, 0)) >= limit:
			return false
	if place_key(task) != "" and int(used.get("@" + place_key(task), 0)) >= at_place:
		return false
	if strict and not last.is_empty():
		var before := objects(last)
		for id in objects(task):
			if id in before:
				return false
		var key := place_key(task)
		if key != "" and key == place_key(last):
			return false
	return true

func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var swap: Variant = list[i]
		list[i] = list[j]
		list[j] = swap

## Replays a whole plan from the arrangement as it is now: every task can be done when its
## turn comes and no thing is handled too often. The problems found (empty when none).
func validate(list: Array) -> Array:
	var live = goods
	goods = Plan.new(live)
	var problems: Array = []
	var used := {}
	var limit := share_limit(list.size())
	var most_at_place := place_limit(list.size())
	for i in list.size():
		var task: Dictionary = list[i]
		if not still_valid(task):
			problems.append("task %d (%s, %s) cannot be done or is already done" % [i + 1, task.entry, task.kind])
		var keys := objects(task)
		if place_key(task) != "":
			keys.append("@" + place_key(task))
		for key in keys:
			used[key] = int(used.get(key, 0)) + 1
			var most := most_at_place if str(key).begins_with("@") else limit
			if used[key] == most + 1:
				problems.append("%s comes up in more than %d tasks" % [key, most])
		goods.apply(task)
	goods = live
	return problems

## Can the task still be done, and is it not done already? (In the plan, or live when its turn
## comes: the player may have moved things meanwhile.)
func still_valid(task: Dictionary) -> bool:
	if str(task.get("kind", "")) != "place":
		return false
	var item := str(task.get("item", ""))
	if not goods.items.has(item) or not goods.known(item) or goods.bay_of(item) >= 0:
		return false
	var goal: Dictionary = task.goal
	return _fits(item, goal) and not reached(item, goal) and _ref_ready(item, goal)

## The reference of a placing goal can take the thing (in its bay, room left).
func _ref_ready(item: String, goal: Dictionary) -> bool:
	var ref := str(goal.get("ref", ""))
	match str(goal.pos):
		"next_to", "right":
			return goods.items.has(ref) and goods.bay_of(ref) >= 0
		"on":
			return _count(func(id): return id != item and goods.on_table(id)) < TABLE_CAPACITY
		"top_shelf":
			var others: int = goods.on_level(_top()) - (1 if goods.rack_spot(item) == [0, _top()] else 0)
			return others < Goods.SHELF_CAPACITY
	return true

## A replacement for task `index` of `list` that cannot be done any more, written for the
## warehouse as it is now under the same rules ({} when none can be found).
func backup(list: Array, index: int) -> Dictionary:
	var others: Array = list.duplicate()
	others.remove_at(index)
	var used := _uses(others)
	var last: Dictionary = list[index - 1] if index > 0 else {}
	for strict in [true, false]:
		var pool: Array = entries()
		_shuffle(pool)
		for entry in pool:
			for variant in 3:
				var task := make(entry, variant == 0)
				if not task.is_empty() and _allowed(task, used, last, share_limit(list.size()), strict, place_limit(list.size())):
					return task
	return {}

## The words a task practises (practice_log.gd): its thing's word, if it has one (the boxes
## have none since 21 Nov 2026), plus the colour its sentence names, plus the position word of
## its kind (place_word(); since 25 Nov 2026). [] when no thing is named.
func words(task: Dictionary) -> Array:
	var item := str(task.get("item", ""))
	if item == "" or not goods.items.has(item):
		return []
	var keys: Array = [str(goods.items[item].get_meta("word_key", ""))]
	keys.append(COLOR_WORDS.get(item.get_slice("_", 1), ""))
	keys.append(place_word(task))
	return keys.filter(func(key): return key != "")

## The position word of a task ("" when it has none). The session judges it apart from the
## thing's words: a wrong box misses the colour, the right box put down in a wrong place misses
## the position (warehouse_session.gd).
static func place_word(task: Dictionary) -> String:
	return str(POSITION_WORDS.get(str(task.get("entry", "")), ""))

## Whether the task's thing, let go and resting, stands in a named place that is not its goal:
## on the table, on a shelf level, or beside the wall bay's box on the wrong side. Anywhere
## else on the floor is not judged (the player may just set it down on the way).
func wrong_place(task: Dictionary) -> bool:
	var id := str(task.get("item", ""))
	if str(task.get("kind", "")) != "place" or not goods.items.has(id) or not goods.resting(id):
		return false
	if reached(id, task.goal):
		return false
	if goods.on_table(id) or not goods.rack_spot(id).is_empty():
		return true
	for ref in goods.items:
		if ref != id and goods.bay_of(ref) >= 0 and goods.beside(id, ref, "next_to"):
			return true
	return false

# --- Hints (8 Nov 2026) ------------------------------------------------------------------------

## A hint for the task as things are now. Level 1 is a general clue (the area to look in);
## level 2 marks the thing in green, or, once it is carried, the place it goes.
## {"say": a reference for Ramón's line, "mark": item id or "", "region": [centre, size] or []}.
func hint(task: Dictionary, level: int) -> Dictionary:
	var item := str(task.get("item", ""))
	if item == "" or not goods.items.has(item):
		return {"say": {"phrase": "warehouse.task_again", "values": {"task": task}}}
	var name: Dictionary = task.get("values", {}).get("item", thing(item))
	if goods.carried == goods.items[item]:
		var spot := region(task.goal, item)
		if level == 1:
			return {"say": {"phrase": "warehouse.hint_goal_area", "values": {"area": {"phrase": area_of(spot[0])}}}}
		return {"say": {"phrase": "warehouse.hint_place", "values": {"item": thing(item), "place": place(task.goal)}}, "region": spot}
	# Find the thing: where it is in general, then marked in green.
	if level == 1:
		return {"say": {"phrase": "warehouse.hint_area", "values": {"item": name, "area": {"phrase": area_of(goods.center(item))}}}}
	return {"say": {"phrase": "warehouse.hint_thing", "values": {"item": name}}, "mark": item}

## The part of the hall a hall-local point is in, as a phrase id ("cerca del estante").
func area_of(p: Vector3) -> String:
	var shelf := Warehouse.SHELF_AT
	if p.z > shelf.z - 1.6 and absf(p.x - shelf.x) < Warehouse.RACK_LENGTH * .5 + .5:
		return "warehouse.area_shelf"
	for bay in Goods.BAYS:
		if p.x > bay[0].x - 1.6 and absf(p.z - bay[0].y) < 2.6:
			return "warehouse.area_bay"
	if absf(p.x - Warehouse.WORK_TABLE.x) < Warehouse.WORK_TABLE_SIZE.x * .5 + 1.0 and absf(p.z - Warehouse.WORK_TABLE.z) < Warehouse.WORK_TABLE_SIZE.y * .5 + 1.0:
		return "warehouse.area_table"
	if is_instance_valid(boss):
		var b: Vector3 = goods.to_hall(boss.global_position)
		if Vector2(p.x - b.x, p.z - b.z).length() < 2.5:
			return "warehouse.area_boss"
	if p.x < Warehouse.DIVIDER_X:
		return "warehouse.area_right_section"
	if p.z < 3.0:
		return "warehouse.area_front"
	if p.z > 10.0:
		return "warehouse.area_back"
	return "warehouse.area_middle"

# --- Language references ---------------------------------------------------------------------

## A thing's noun phrase: "box_<colour>" is *la caja roja*; anything else (the table) has its
## own phrase.
static func thing(id: String) -> Dictionary:
	if id.begins_with("box_"):
		return {"phrase": "warehouse.thing_box_plain", "values": {"color": {"phrase": "warehouse.color_f_" + id.trim_prefix("box_")}}}
	return {"phrase": "warehouse.thing_" + id}

## The place phrase of a goal ("a la derecha de la caja verde"). `instruction`: in a placing
## task's sentence, where "on" becomes "onto" in English ("Put the blue box onto the table";
## hints keep "on the table"; user, 8 Nov 2026).
static func place(goal: Dictionary, instruction := false) -> Dictionary:
	var pos := str(goal.pos)
	if instruction and pos == "on":
		pos = "onto"
	var ref: Dictionary = {"phrase": "warehouse.place_" + pos}
	if str(goal.get("ref", "")) != "":
		ref["values"] = {"ref": thing(str(goal.ref))}
	return ref

# --- Checks ------------------------------------------------------------------------------------

## Is an item where a goal wants it (ignoring whether it is still moving or carried)?
func reached(id: String, goal: Dictionary) -> bool:
	match str(goal.pos):
		"on":
			return goods.on_table(id)
		"next_to", "right":
			return goods.beside(id, str(goal.ref), str(goal.pos))
		"top_shelf":
			return goods.rack_spot(id) == [0, _top()]
	return false

## Is the task finished (put down, settled and in place)?
func done(task: Dictionary) -> bool:
	return str(task.get("kind", "")) == "place" and goods.resting(task.item) and reached(task.item, task.goal)

## Where the green marker goes for a goal: [hall-local centre, size].
func region(goal: Dictionary, id: String) -> Array:
	var ref := str(goal.get("ref", ""))
	var floor_y: float = Warehouse.FLOOR + .2
	match str(goal.pos):
		"right":
			var r: Vector3 = goods.ref_center(ref)
			var rh: Vector3 = goods.ref_half(ref)
			var axis: Vector2 = goods.side_axis(ref, "right")
			var out := (rh.x if axis.x != 0 else rh.z) + .55
			return [Vector3(r.x + axis.x * out, floor_y, r.z + axis.y * out), Vector3(.9, .4, .9)]
		"next_to":
			var r: Vector3 = goods.ref_center(ref)
			var rh: Vector3 = goods.ref_half(ref)
			return [Vector3(r.x, floor_y, r.z), Vector3(rh.x * 2 + 2.0, .4, rh.z * 2 + 2.0)]
		"on":
			return [Vector3(Warehouse.WORK_TABLE.x, Warehouse.FLOOR + Warehouse.TABLE_HEIGHT + .2, Warehouse.WORK_TABLE.z), Vector3(Warehouse.WORK_TABLE_SIZE.x, .4, Warehouse.WORK_TABLE_SIZE.y)]
		"top_shelf":
			return [Vector3(Warehouse.SHELF_AT.x, Warehouse.FLOOR + Warehouse.RACK_LEVELS[_top()] + .3, Warehouse.SHELF_AT.z), Vector3(Warehouse.RACK_LENGTH - .3, .55, Warehouse.RACK_DEPTH - .1)]
	return [goods.center(id), Vector3.ONE * .6]
