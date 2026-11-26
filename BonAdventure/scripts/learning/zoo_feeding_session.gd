extends Node
## Feeding Time! (user design 24 Nov 2026; purpose and levels: docs/game/minigames.md#feeding-time,
## record: docs/guides/TOWN_DESIGN_BRIEF.md#zoo-food-booth-and-feeding-time--24-november-2026).
## Nico, the sheep zookeeper at the food booth inside the zoo gate (ParkZoo/ZooKeeper, a registry
## NPC, data/npcs.json), both sells animal food and hosts this game, so this session owns three
## things that share him:
##   - the game, through the shared host (minigame_host.gd, activity "feeding_nico");
##   - the booth's till (cashier_session.gd, data/shops.json store and cashier "zoo"), which
##     borrows that host: talking to Nico while buying goes to the till, and the till's "!";
##   - feeding with a bag (animal_feeding.gd): free feeding any time, and the game's rule.
##
## The game: Nico asks "Can you feed the apple to the elephant?" in the language being learned and
## hands over a paper bag with the food for every request of the session (user: he always hands it
## over, so the game tests only the animal names). Feeding the named animal counts (first try:
## the first animal fed for that request was the right one); another animal sniffs the food and
## refuses it, a miss, and Nico says which animal that was. The next request follows at once; the
## instruction strip shows the request and "2/5". Levels (data/activities.json "levels") pick the
## animals by word tier (Lexicon.tier()) and say how many requests a session has. Practice: one
## question per request, the named animal's word (practice_log.gd).
## Leaving the zoo during the game asks whether to stop (25 Nov 2026, GAME-03: on foot the player
## is first put back just inside, facing Nico, and stands still until they answer, as the grocery
## clerk's and Library Helper's walk-away; "stay" keeps them inside). Esc / back asks the same
## (request_leave(), called by Main). Talking to Nico repeats the request.
const Host := preload("res://scripts/learning/minigame_host.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Cashier := preload("res://scripts/learning/cashier_session.gd")
const Feeding := preload("res://scripts/world/animal_feeding.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Strip := preload("res://scripts/ui/instruction_strip.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const WordMemory := preload("res://scripts/learning/word_memory.gd")
const ACTIVITY := "feeding_nico"
const NPC := "ZooKeeper"
const STORE := "zoo"
const ZONE := "zoo"
const CALL_DISTANCE := 12.0
const WALK_AWAY_DISTANCE := 12.0
## Seconds between a right feed and the next request.
const NEXT_DELAY := 1.4
const ZONE_CHECK_INTERVAL := 0.25
## The player's last places inside the zoo (one per zone check) during a game, oldest first:
## walking out puts them back at the oldest.
const INSIDE_SPOTS := 3

var lexicon
var dialogue
var panel
var interaction
var zones
var player: Node3D
var keeper: Node3D
var host
var till
var feeder
var strip
## The game: running, the requests ([{"animal", "food"}]), the one being asked and whether it
## was missed.
var playing := false
var requests: Array = []
var current := -1
var missed := false
## The game's food still in the bag (word key -> how many): taken out again when the game ends.
var game_food: Dictionary = {}
var _zone_timer := 0.0
var _in_zoo := true
var _inside_spots: Array = []
## The leave question was asked because the player walked out and was put back (not by Esc).
var _asked_at_edge := false
var _rng := RandomNumberGenerator.new()
## Whether Nico offers the game now (kept on the host; the checks read and set it).
var offered: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value

func setup(shop_dialogue, shop_panel, money_panel, interaction_controller, town_zones, explorer: Node3D, world: Node3D, sold_in: Dictionary = {}) -> void:
	name = "ZooFeedingSession"
	dialogue = shop_dialogue
	lexicon = shop_dialogue.lexicon
	panel = shop_panel
	interaction = interaction_controller
	zones = town_zones
	player = explorer
	_rng.randomize()
	keeper = world.find_child(NPC, true, false) as Node3D
	if keeper == null:
		push_warning("zoo_feeding_session: no '%s' node" % NPC)
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": ACTIVITY, "group": "zoo", "speaker": "zoo.nico", "call_distance": CALL_DISTANCE,
			"walk_away": WALK_AWAY_DISTANCE}, lexicon, panel, interaction, player, keeper)
	host.play_chosen.connect(open_game)
	host.choice_made.connect(_on_choice)
	host.leave_answered.connect(_on_leave_answered)
	till = Cashier.new()
	add_child(till)
	till.setup(STORE, shop_dialogue, shop_panel, money_panel, interaction, zones, player, world, sold_in, host)
	feeder = Feeding.new()
	add_child(feeder)
	feeder.setup(player, world)
	feeder.fed.connect(_on_fed)
	strip = Strip.new()
	add_child(strip)

# --- Host hooks -------------------------------------------------------------------------------

func activity_running() -> bool:
	return playing

func busy() -> bool:
	return host != null and (host.owns_dialogue() or host.is_asking_leave()) or (till != null and till.busy())

## Buying goes to the till; during the game Nico repeats the request.
func _host_talk(_talker: Node3D) -> bool:
	if till.free_active or till.paying_for != "":
		till._talk()
		return true
	if playing:
		_say_request([host.choice("keep", "zoo.keep_feeding", "check"), host.choice("stop", "zoo.stop", "exit")])
		return true
	return false

## The "!" also while a bag waits to be paid at the till.
func _host_calling() -> bool:
	return till != null and till._host_calling()

# --- The game ---------------------------------------------------------------------------------

func open_game() -> void:
	interaction.clear_card()
	if till.free_active:
		till.drop_free_basket()
	var settings: Dictionary = Progress.shared().params(ACTIVITY)
	var board = Board.shared()
	var custom: bool = board.target(ACTIVITY) != int(board.activities.get(ACTIVITY, {}).get("progress", 0))
	var count: int = board.rounds(ACTIVITY) if custom else int(settings.get("requests", board.rounds(ACTIVITY)))
	requests = plan(count, settings.get("tiers", [2]))
	if requests.is_empty():
		push_warning("zoo_feeding_session: no animals to ask for")
		return
	board.begin(ACTIVITY)
	playing = true
	current = -1
	var bag: Node3D = Basket.give(player, Basket.BAG)
	bag.set_meta("game_bag", true)
	var counts := {}
	for request in requests:
		counts[request.food] = int(counts.get(request.food, 0)) + 1
	Feeding.add_food(bag, counts)
	game_food = counts
	feeder.judge = _judge
	_next_request()

## `count` requests of zoo animals whose word tier (in the language being learned) is in `tiers`,
## each with a food it eats; no animal twice in a row (twice at most when there are few). Each
## pass through the animals is in the word memory's order (due first, then allowed new ones;
## word_memory.gd order(), 25 Nov 2026; it was a shuffle).
func plan(count: int, tiers: Array) -> Array:
	# JSON numbers are floats: compare tiers as ints.
	var wanted: Array = tiers.map(func(t) -> int: return int(t))
	var pool: Array = []
	for animal in feeder.animals():
		var key := Feeding.animal_key(animal)
		if wanted.has(lexicon.tier(key, lexicon.foreign)) and not pool.has(key):
			pool.append(key)
	var found: Array = []
	var bag: Array = []
	var last := ""
	while found.size() < count and not pool.is_empty():
		if bag.is_empty():
			bag = WordMemory.shared().order(pool, _rng)
			if bag.size() > 1 and bag[0] == last:
				bag.push_back(bag.pop_front())
		var key: String = bag.pop_front()
		var foods: Array = feeder.eats.get(key, [])
		found.append({"animal": key, "food": foods[_rng.randi_range(0, foods.size() - 1)]})
		last = key
	return found

func _next_request() -> void:
	current += 1
	missed = false
	var request: Dictionary = requests[current]
	PracticeLog.shared().begin(ACTIVITY, [str(request.animal)])
	_say_request()

func _request_line() -> Dictionary:
	var request: Dictionary = requests[current]
	return lexicon.line("zoo.request", {"food": feeder.food_value(str(request.food)), "animal": {"word": str(request.animal)}})

func _say_request(choices: Array = []) -> void:
	var line := _request_line()
	host.show_line("zoo.request", line, choices, 0.0 if not choices.is_empty() else -1.0)
	strip.show_text(GameSettings.shared().inline(line, panel.show_native), "%d/%d" % [current + 1, requests.size()])

## The game's rule for animal_feeding.gd: the request's food, eaten only by the named animal.
func _judge(animal_key: String, _stock: Dictionary) -> Dictionary:
	if not playing or current < 0:
		return feeder._choose(animal_key, _stock)
	var request: Dictionary = requests[current]
	return {"food": str(request.food), "eats": animal_key == str(request.animal)}

func _on_fed(animal_key: String, _food: String, ate: bool) -> void:
	if not playing or current < 0:
		return
	var request: Dictionary = requests[current]
	var right := animal_key == str(request.animal)
	var practice = PracticeLog.shared()
	if practice.game_id() == ACTIVITY:
		practice.first_answer(right)
	if not right:
		if not missed:
			missed = true
			Board.shared().add_miss(ACTIVITY)
		host.show_line("zoo.wrong_animal", lexicon.line("zoo.wrong_animal", {"wrong": {"word": animal_key}, "animal": {"word": str(request.animal)}}))
		return
	if not ate:
		return
	game_food[request.food] = int(game_food.get(request.food, 0)) - 1
	if practice.game_id() == ACTIVITY:
		practice.complete()
	if not missed:
		Board.shared().add_success(ACTIVITY)
	if current + 1 >= requests.size():
		_finish()
		return
	host.say("zoo.yummy")
	get_tree().create_timer(NEXT_DELAY).timeout.connect(func() -> void:
		if playing:
			_next_request())

## Every request fed: Nico thanks the player; the results card follows (results_flow.gd).
func _finish() -> void:
	Board.shared().complete(ACTIVITY)
	offered = false
	_stop_game()
	host.say("zoo.complete")

## The game ends (finished or left): its food leaves the bag; an empty bag goes.
func _stop_game() -> void:
	playing = false
	feeder.judge = Callable()
	strip.clear()
	host.cancel_leave()
	if _asked_at_edge:
		_asked_at_edge = false
		if get_parent() != null and get_parent().has_method("sync_player_controls"):
			get_parent().sync_player_controls()
	var bag := Basket.carried(player)
	if bag != null and bag.has_meta("game_bag"):
		var left := {}
		for key in game_food:
			if int(game_food[key]) > 0:
				left[key] = -int(game_food[key])
		Feeding.add_food(bag, left)
		bag.remove_meta("game_bag")
		if (bag.get_meta("food", {}) as Dictionary).is_empty():
			Basket.take_back(player)
	requests = []
	game_food = {}
	current = -1

func stop_game() -> void:
	if not playing:
		return
	host.abandon_practice()
	_stop_game()
	host.say("zoo.goodbye")

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"keep":
			host.close_dialogue()
		"stop":
			host.close_dialogue()
			stop_game()

func _on_leave_answered(leave: bool) -> void:
	var at_edge := _asked_at_edge
	_asked_at_edge = false
	if at_edge:
		if not leave and zones.resolve_global(player.global_position) != ZONE:
			_step_back_in()
		if get_parent() != null and get_parent().has_method("sync_player_controls"):
			get_parent().sync_player_controls()
	if leave and playing:
		stop_game()

## Esc / back while the game runs (Main, the request_leave() contract, docs/guides/MINIGAMES.md):
## asks the shared leave question. True when the press was taken.
func request_leave() -> bool:
	if host == null or not playing:
		return false
	if not host.is_asking_leave():
		host.ask_leave("zoo.leave_confirm")
	return true

## Walked out of the zoo mid-game: on foot, back inside first; in a vehicle or seat, just ask.
func _ask_at_edge() -> void:
	var main := get_parent()
	var riding: bool = player.seated or (main != null and is_instance_valid(main.get("active_vehicle")))
	if not riding and not _inside_spots.is_empty():
		_step_back_in()
		_asked_at_edge = true
		player.set_controls_enabled(false)
	host.ask_leave("zoo.leave_confirm")

## Puts the player at their oldest remembered spot inside the zoo, facing Nico.
func _step_back_in() -> void:
	if _inside_spots.is_empty():
		return
	player.global_position = _inside_spots[0]
	player.velocity = Vector3.ZERO
	var look: Vector3 = keeper.global_position - player.global_position if is_instance_valid(keeper) else Vector3.ZERO
	if Vector2(look.x, look.z).length() > 0.1:
		var yaw := atan2(-look.x, -look.z)
		player.rotation.y = yaw
		player.camera_yaw = yaw
	player.reset_camera()

## A language change in Settings ends the game; Nico's name follows the new languages.
func end_activity() -> void:
	if host == null:
		return
	stop_game()
	till.end_activity()
	host.refresh_name()

func _process(delta: float) -> void:
	if host == null:
		return
	host.tick(delta)
	_zone_timer += delta
	if _zone_timer < ZONE_CHECK_INTERVAL or zones == null or not is_instance_valid(player):
		return
	_zone_timer = 0.0
	var inside: bool = zones.resolve_global(player.global_position) == ZONE
	if playing and inside:
		_inside_spots.append(player.global_position)
		if _inside_spots.size() > INSIDE_SPOTS:
			_inside_spots.pop_front()
	elif not playing:
		_inside_spots.clear()
	# Walking out of the zoo mid-game asks whether to stop (once per exit; put back inside first).
	if playing and _in_zoo and not inside and not host.is_asking_leave():
		_ask_at_edge()
		inside = zones.resolve_global(player.global_position) == ZONE
	_in_zoo = inside
