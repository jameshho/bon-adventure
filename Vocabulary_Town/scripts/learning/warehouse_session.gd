extends Node
## The Warehouse Worker minigame (Phase 4, 5 Nov 2026; guide: docs/guides/WAREHOUSE.md). Ramón
## (Warehouse/Exterior/Ramon, built by scripts/world/warehouse.gd) shows the gold "!" while
## the player is near and greets them in the SHARED dialogue box (shop_order_panel.gd).
## Accepting fades the screen, saves where the player stood, hides Ramón outside, builds the
## minigame copy of the warehouse (warehouse.gd build_copy(), 300 units above the real one)
## and puts the player at the station beside Ramón's twin. The task card
## (warehouse_task_card.gd) shows "Task n of 5" and the task. Leaving early (the card's exit
## button, Esc, or "Leave" when talking to Ramón) always asks first; a language change ends
## the game at once. Ending fades back to the saved spot outside and frees the whole copy.
## Falling or flying out of the copy returns the player to the station.
##
## Phase 5 (5 Nov 2026): the copy gets its own goods and cabinet (warehouse_goods.gd, a child
## of this node while a game runs) and each task is written for the arrangement as it is
## (warehouse_tasks.gd). Goods, the cabinet and the ways out are interactables (E, a click or a
## tap: lift, open, ask to leave); while carrying, the session's "warehouse" input claim puts
## down (interaction system, 12 Nov 2026). A finished task is praised and the next one written.
## A wrong attempt (picking up a different box than the task names) asks "try again, or shall I
## tell you what went wrong?"; the second marks the right box in green. Nothing counts first
## tries: only the finished tasks matter.
##
## 14 Nov 2026 (user): five placing tasks only (on the table, next to / to the right of the
## green box, on the top shelf); the questions, weighing, measuring and trolleys were removed.
##
## 8 Nov 2026 (user): all of a game's tasks are planned before the copy is shown
## (warehouse_tasks.gd plan(); a new arrangement when no plan keeps every rule, at most
## ARRANGE_TRIES times); each task is checked again when its turn comes and replaced by a
## backup if the player's moves made it impossible or already done. Putting a thing down in
## the wrong place is not a mistake (no message, no penalty); a placing task is done once the
## thing has been let go and stays still in the right place for SETTLE_SECONDS. Hints: the
## card's "?" button and "¿Me das una pista?" when talking to Ramón share one hint level per
## task (1: a general clue, 2: the thing or its place marked in green). E on the hall door, the
## entrance door or the roll-up loading gate asks to leave, like the card's exit button.
##
## Every text comes from data/phrases.json group "warehouse" through the Lexicon. Offers
## and progress follow the shared activity board ("warehouse_ramon" in data/activities.json).
##
## 9 Nov 2026: Ramón, the "!", talking (also to his twin in the copy), the leave question and
## walking away use the shared NPC host (minigame_host.gd); the fade and placing the player
## use the shared in-world zone (minigame_zone.gd). docs/MINIGAMES.md.
const Board := preload("res://scripts/learning/activity_board.gd")
const Presence := preload("res://scripts/learning/npc_presence.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const Warehouse := preload("res://scripts/world/warehouse.gd")
const Goods := preload("res://scripts/learning/warehouse_goods.gd")
const Tasks := preload("res://scripts/learning/warehouse_tasks.gd")
## Practice tracking (practice_log.gd): a task tests the word of the thing it names and its
## colour (decision 6). Any wrong attempt before the task is done is a wrong first answer.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const ACTIVITY := "warehouse_ramon"
const CALL_DISTANCE := 30.0
const WALK_AWAY_DISTANCE := 14.0
const MESSAGE_SECONDS := 9.0
## How far outside the copy's hall the player may get before being put back at the station.
const OUT_OF_BOUNDS := 3.0
## Ramón's praise stays up this long before the next task.
## The praise shows on the task card this long before the next task (user, 8 Nov 2026: one
## box, not a second one at the bottom).
const PRAISE_SECONDS := 1.6
## How long a put-down thing must stay still in the right place before the task counts.
const SETTLE_SECONDS := 0.5
## New arrangements tried when no task plan keeps every rule.
const ARRANGE_TRIES := 3
## How far (hall units) the player may be from a door to leave through it with E.
const EXIT_REACH := 3.5

var lexicon
var dialogue_panel
var card
var interaction
var player: Node3D
var world: Node3D
var main
var ramon: Node3D
## The shared NPC host (Ramón outside, his twin in the copy) and in-world zone (fade, placing).
var host
var zone
var presence:
	get: return host.presence if host != null else null
## Whether Ramón offers the game now (rolled on approach; kept on the host).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
var _rng := RandomNumberGenerator.new()
## The line the dialogue box shows for this session, or "" when it is not ours.
var _talking: String:
	get: return host.line_id if host != null and host.owns_dialogue() else ""
var _busy_fading := false

## The running game: the copy, its Ramón, where to return the player, the tasks.
var copy_root: Node3D
var twin: Node3D
## Seconds left of the praise on the card before the next task shows.
var _praise_left := 0.0
var twin_presence
var _return := {}
var tasks: Array = []
var current := 0
var goods
var writer
## What "tell me what went wrong" shows: "place" or "thing".
var _hint := ""
var _carry_told := false
## Hints asked for the current task (0, 1 or 2), shared by the card's "?" and Ramón.
var _hint_level := 0
## How long the current task's goal has held without a break (placing must settle).
var _settled := 0.0
## What went wrong when planning this game ("" when nothing); kept for tests and reports.
var plan_problems: Array = []

func setup(shared_lexicon, shared_dialogue_panel, task_card, interaction_controller, explorer: Node3D, town: Node3D, game) -> void:
	name = "WarehouseSession"
	lexicon = shared_lexicon
	dialogue_panel = shared_dialogue_panel
	card = task_card
	interaction = interaction_controller
	player = explorer
	world = town
	main = game
	_rng.randomize()
	ramon = preload("res://scripts/world/modular_town.gd").building(town, "warehouse", 0, "Exterior/Ramon")
	if ramon == null:
		push_warning("warehouse_session: no warehouse unit (dev focus) or no Exterior/Ramon")
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "warehouse", "speaker": "warehouse.ramon",
			"call_distance": CALL_DISTANCE, "walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS},
			lexicon, dialogue_panel, interaction, player, ramon)
	host.play_chosen.connect(start_game)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(func(_id: String) -> void: _zoom_twin(false))
	host.leave_answered.connect(_on_leave_answered)
	zone = Zone.new()
	add_child(zone)
	zone.setup(player, main, "WarehouseFade")
	card.leave_requested.connect(ask_leave)
	card.hint_requested.connect(give_hint)
	# While carrying an item, E and a click put it down where aimed; on Ramón's twin they talk. Interaction system, 12 Nov 2026.
	interaction.claim("warehouse", func() -> bool: return in_game() and not _busy_fading and goods != null and goods.holding(), _carry_use, _carry_use)

## For the activity board: a game is running while the copy exists.
func activity_running() -> bool:
	return is_instance_valid(copy_root)

func in_game() -> bool:
	return is_instance_valid(copy_root)

func busy() -> bool:
	return _busy_fading or (host != null and host.owns_dialogue())

# --- Dialogue box ----------------------------------------------------------------------

func _say(id: String, choices: Array = [], auto_close: float = MESSAGE_SECONDS, values: Dictionary = {}) -> void:
	host.say(id, choices, auto_close, values)

## Talking: Ramón outside gets the host's greeting; his twin in the copy talks about the task.
func _host_talk(talker: Node3D) -> bool:
	if talker == ramon:
		return in_game()
	if talker != twin or not in_game():
		return true
	_zoom_twin(true)
	_say("warehouse.task_again", [host.choice("stay", "warehouse.keep_going", "check"), host.choice("ask_hint", "warehouse.ask_hint", "question"), host.choice("leave", "warehouse.leave", "exit")], 0.0, {"task": tasks[current]})
	return true

## In the copy the player walks about with the task open: no line closes by distance there.
func _host_walked_away(distance: float) -> bool:
	return not in_game() and distance > WALK_AWAY_DISTANCE

func _zoom_twin(on: bool) -> void:
	if twin_presence != null:
		twin_presence.zoom_to_face(on)

func _on_choice(id: String) -> void:
	var choice := id.trim_prefix(host.choice_prefix())
	match choice:
		"stay":
			_close_dialogue()
		"leave":
			_close_dialogue()
			ask_leave()
		"try":
			_close_dialogue()
		"hint":
			_close_dialogue()
			_point_out()
		"ask_hint":
			_close_dialogue()
			give_hint()

func _close_dialogue() -> void:
	host.close_dialogue()
	_zoom_twin(false)

# --- Starting and ending ------------------------------------------------------------------

func start_game() -> void:
	if in_game() or _busy_fading:
		return
	_busy_fading = true
	await zone.fade_to(1.0)
	_return = {"position": player.global_position, "yaw": player.rotation.y, "camera_yaw": player.camera_yaw}
	ramon.visible = false
	Board.shared().begin(ACTIVITY)
	# The whole game is planned before the copy is shown; a new arrangement when no plan
	# keeps every rule (the problems are reported, never silently ignored).
	var planned: Dictionary = {}
	for attempt in ARRANGE_TRIES:
		if attempt > 0:
			_free_round()
		_build_round()
		planned = writer.plan(Board.shared().target(ACTIVITY))
		if planned.problems.is_empty():
			break
	plan_problems = planned.problems
	if not plan_problems.is_empty():
		push_warning("warehouse_session: task plan: " + "; ".join(plan_problems))
	tasks = planned.tasks
	if tasks.is_empty():
		tasks = [writer.next()]
	current = 0
	_praise_left = 0.0
	_new_task()
	_to_station()
	await get_tree().physics_frame
	_show_task()
	await zone.fade_to(0.0)
	_busy_fading = false
	_say("warehouse.intro")

## One arrangement: the copy, its goods and Ramón's twin, and a task writer for them.
func _build_round() -> void:
	copy_root = Warehouse.new().build_copy(main, world)
	goods = Goods.new()
	add_child(goods)
	goods.setup(main, copy_root, player, interaction, _rng)
	goods.item_picked.connect(_on_item_picked)
	_carry_told = false
	twin = copy_root.get_node("Hall/Ramon")
	host.add_talker(twin)
	twin_presence = Presence.new()
	twin_presence.name = "TwinPresence"
	add_child(twin_presence)
	twin_presence.setup(twin, player)
	writer = Tasks.new(goods, twin, _rng)
	# The ways out of the copy (warehouse.gd marks them "warehouse_exit"): E asks to leave.
	for exit_node in copy_root.find_children("*", "", true, false):
		if exit_node is Node3D and exit_node.has_meta("warehouse_exit"):
			Interactable.attach(exit_node, {
				"kind": Interactable.Kind.OPEN,
				"prompt_distance": EXIT_REACH * 1.3,
				"badge_offset": InteractIcons.local_center(exit_node),
				"on_check": func() -> Variant: return not busy(),
				"on_use": ask_leave,
			})

## Undoes _build_round() (the player was never put in it).
func _free_round() -> void:
	goods.shutdown()
	# Out of the tree at once, so the next copy and goods get the same node names.
	for node in [goods, twin_presence, copy_root]:
		node.get_parent().remove_child(node)
		node.queue_free()
	goods = null
	twin_presence = null
	host.remove_talker(twin)
	twin = null
	copy_root = null
	writer = null

## A task's turn comes: hints start again, and a planned task the player's moves made
## impossible or already done is replaced by a backup written for the warehouse as it is.
func _new_task() -> void:
	_hint_level = 0
	_settled = 0.0
	if writer.still_valid(tasks[current]):
		return
	var replacement: Dictionary = writer.backup(tasks, current)
	if replacement.is_empty():
		push_warning("warehouse_session: no backup keeps the rules for task %d; writing any task" % (current + 1))
		replacement = writer.next()
	tasks[current] = replacement

func _show_task() -> void:
	var total: int = Board.shared().target(ACTIVITY)
	card.show_native = dialogue_panel.show_native
	var task: Dictionary = tasks[current]
	var words: Array = writer.words(task)
	if not words.is_empty():
		PracticeLog.shared().begin(ACTIVITY, words)
	else:
		_practice_abandon()
	card.open(lexicon.line("warehouse.task_title", {"n": current + 1, "total": total}), _line(tasks[current]), lexicon.line("common.show_translation"), Board.shared().done(ACTIVITY), total, {"hint": str(lexicon.line("warehouse.hint_button").get("native", "")), "leave": str(lexicon.line("warehouse.leave").get("native", ""))})

func _line(ref: Dictionary) -> Dictionary:
	return {"foreign": lexicon.text(ref, lexicon.foreign), "native": lexicon.text(ref, lexicon.native)}

## The current task is done: counts it, then ends the game or writes and shows the next
## task. True when the session is finished.
func task_done() -> bool:
	if not in_game():
		return false
	goods.clear_mark()
	_hint = ""
	if PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().first_answer(true)
		PracticeLog.shared().complete()
	var finished: bool = Board.shared().add_success(ACTIVITY)
	if finished:
		end_game("warehouse.complete")
		return true
	current += 1
	if current >= tasks.size():
		tasks.append(writer.next())
	_new_task()
	# The card says "¡Muy bien! Siguiente tarea." (progress already counted), then the next task.
	card.praise(lexicon.line("warehouse.well_done"), Board.shared().done(ACTIVITY), Board.shared().target(ACTIVITY))
	_praise_left = PRAISE_SECONDS
	return false

## Praise on the card, then the next task (or the end).
func _complete_task() -> void:
	if _talking != "":
		_close_dialogue()
	task_done()

# --- Tasks: talking, wrong attempts -----------------------------------------------------------

## A wrong attempt: try again, or be told what went wrong.
func _wrong(id: String, values: Dictionary, hint: String) -> void:
	if PracticeLog.shared().game_id() == ACTIVITY:
		PracticeLog.shared().first_answer(false)
	_hint = hint
	if _talking != "":
		_close_dialogue()
	_say(id, [host.choice("try", "warehouse.try_again", "retry"), host.choice("hint", "warehouse.show_me", "question")], 0.0, values)

## "Tell me what went wrong": marks the place or the thing in green.
func _point_out() -> void:
	var task: Dictionary = tasks[current]
	match _hint:
		"place":
			var spot: Array = writer.region(task.goal, task.item)
			goods.mark(spot[0], spot[1])
			_say("warehouse.hint_place", [], MESSAGE_SECONDS, {"item": Tasks.thing(task.item), "place": Tasks.place(task.goal)})
		"thing":
			goods.mark_item(task.item)
			_say("warehouse.hint_thing", [], MESSAGE_SECONDS, {"item": Tasks.thing(task.item)})

## Hints (user, 8 Nov 2026): the card's "?" and "¿Me das una pista?" to Ramón. Each asks
## for the next level (1: a general clue; 2: the thing, or once carried its place, marked in
## green; asking again at 2 marks what fits now). The task and the game go on meanwhile.
func give_hint() -> void:
	if not in_game() or _busy_fading or tasks.is_empty():
		return
	_hint_level = mini(_hint_level + 1, 2)
	var hint: Dictionary = writer.hint(tasks[current], _hint_level)
	if str(hint.get("mark", "")) != "":
		goods.mark_item(hint.mark)
	elif not hint.get("region", []).is_empty():
		goods.mark(hint.region[0], hint.region[1])
	if _talking != "":
		_close_dialogue()
	host.show_line("warehouse.hint", _line(hint.say), [], MESSAGE_SECONDS)

## Picking up a different box than the task names: try again, or be shown the right one.
func _on_item_picked(id: String) -> void:
	if not _carry_told:
		_carry_told = true
		dialogue_panel.toast(lexicon.line("warehouse.carry_help"), 4.0)
	var task: Dictionary = tasks[current]
	if str(task.get("item", "")) != "" and id != task.item and _talking == "":
		_wrong("warehouse.wrong_thing", {"item": Tasks.thing(task.item)}, "thing")

## The "warehouse" input claim (while holding something): on Ramón's twin, talk (he takes what
## to him); anywhere else, put the item down where aimed.
func _carry_use() -> void:
	if not player.controls_enabled:
		return
	var aimed: Node = interaction.aimed_interactable()
	if aimed != null and aimed.get_parent() == twin and is_instance_valid(goods.carried):
		interaction.activate(aimed)
		return
	goods.use(aimed.get_parent() if aimed != null else null, twin)

## Leaving early always asks first (shared quit card of the dialogue panel).
func ask_leave() -> void:
	if not in_game() or _busy_fading:
		return
	host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if leave:
		end_game("warehouse.left_early")

## Fades out, returns the player to where they accepted, frees the copy, fades in, and lets
## Ramón outside say `farewell`.
func end_game(farewell: String) -> void:
	if not in_game() or _busy_fading:
		return
	_busy_fading = true
	host.cancel_leave()
	if _talking != "":
		_close_dialogue()
	card.hide_card()
	await zone.fade_to(1.0)
	_free_copy()
	player.global_position = _return.position
	player.velocity = Vector3.ZERO
	player.rotation.y = _return.yaw
	player.camera_yaw = _return.camera_yaw
	player.reset_camera()
	ramon.visible = true
	offered = false
	await get_tree().physics_frame
	await zone.fade_to(0.0)
	_busy_fading = false
	if farewell == "warehouse.complete":
		# A finished game: thanks, and would the player help again (user decision, 8 Nov 2026).
		host.offer(farewell)
	elif farewell != "":
		_say(farewell)

func _practice_abandon() -> void:
	host.abandon_practice()

func _free_copy() -> void:
	_practice_abandon()
	if goods != null:
		goods.shutdown()
		goods.queue_free()
		goods = null
	writer = null
	_hint = ""
	if twin_presence != null:
		twin_presence.zoom_to_face(false)
		twin_presence.queue_free()
		twin_presence = null
	if twin != null:
		host.remove_talker(twin)
	twin = null
	if is_instance_valid(copy_root):
		copy_root.queue_free()
	copy_root = null
	player.remove_meta("map_position")
	tasks = []

## A language change in Settings ends the game at once; Ramón says goodbye outside.
func end_activity() -> void:
	if host == null:
		return
	host.cancel_leave()
	if in_game():
		end_game("warehouse.goodbye")

func _to_station() -> void:
	zone.place_player(copy_root, Warehouse.STATION, Warehouse.STATION_LOOK)

# --- Each frame: "!", walking away, staying inside the copy, the map ---------------------------

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(player):
		return
	host.tick(delta)
	if in_game():
		# The map and room name show the real warehouse while the player is in the copy.
		player.set_meta("map_position", player.global_position - _lift())
		if not _busy_fading and _outside_copy():
			goods.shutdown()
			_to_station()
		twin_presence.animate(delta, false)
		_watch_task(delta)

## The copy's lift in world space (the copy has the real warehouse's orientation and scale).
func _lift() -> Vector3:
	return world.global_basis * Warehouse.COPY_LIFT

## Below the floor, above the roof or beyond the walls of the copy's hall and reception.
func _outside_copy() -> bool:
	var p: Vector3 = copy_root.to_local(player.global_position)
	return p.y < -2.0 or p.y > Warehouse.H + 4.0 or absf(p.x) > Warehouse.HW + OUT_OF_BOUNDS or p.z < -OUT_OF_BOUNDS or p.z > Warehouse.HALL_Z1 + OUT_OF_BOUNDS

## Each frame in the game: a finished task (let go and settled in place) is praised.
func _watch_task(delta: float) -> void:
	if _praise_left > 0.0:
		_praise_left -= delta
		if _praise_left <= 0.0:
			_show_task()
		return
	if _busy_fading or tasks.is_empty() or goods == null:
		return
	var task: Dictionary = tasks[current]
	if writer.done(task):
		# A placed thing must be let go and stay in place, not just pass through or bounce.
		_settled += delta
		if _settled >= SETTLE_SECONDS:
			_complete_task()
		return
	_settled = 0.0
