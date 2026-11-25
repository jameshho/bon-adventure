extends SceneTree
## Feeding Time! and the zoo food booth (user design 24 Nov 2026; docs/game/minigames.md#feeding-time).
## Checks: the data (every zoo animal eats one of the five booth foods, each food sold at the booth
## with a price, bamboo is a word, the levels' tiers cover every animal); the booth (counter,
## paper bags, five food crates as word roots in the zoo zone, Nico from the registry); free buying
## (a paper bag from the stack, foods clicked in, paid at Nico's till, the bag kept with its food);
## free feeding (an animal comes and eats a food it likes, the bag gets lighter; a food it does not
## eat is refused and goes back; an empty bag goes); the game (level 1 asks tier-2 animals, Nico
## hands over a bag with the food, the wrong animal refuses and is a miss, the right ones eat, the
## session completes with a results card, the practice log records the animals, stars follow the
## miss); walking out of the zoo mid-game asks whether to stop.
## With graphics it saves booth.png, bag.png, eating.png and refusing.png here.
## Uses Main, which saves progress: run with an isolated HOME (README; tools/run_checks.py does).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/zoo-feeding-20261124/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const Order := preload("res://scripts/learning/shop_order.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const HERE := "res://docs/evidence/zoo-feeding-20261124/"
const GAME := "feeding_nico"
## Zoo-local (= town) spots: on the path in front of the booth's counter.
const AT_BOOTH := Vector3(-76.6, 0.2, 124.1)
var failures := 0
var checks := 0
var game
var zoo: Node3D
var session
var data: Dictionary = {}
var _fed: Array = []

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func seconds(s: float) -> void:
	await create_timer(s).timeout

func graphics() -> bool:
	return DisplayServer.get_name() != "headless"

## A screenshot from `eye` looking at `target` (zoo-local points), then the game camera again.
func shot(file: String, eye: Vector3, target: Vector3) -> void:
	if not graphics():
		return
	var cam := Camera3D.new()
	cam.fov = 55.0
	game.add_child(cam)
	cam.global_position = zoo.to_global(eye)
	cam.look_at(zoo.to_global(target), Vector3.UP)
	cam.make_current()
	await frames(8)
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(HERE + file))
	print("saved " + file)
	cam.queue_free()
	if game.camera != null:
		game.camera.make_current()

func place(local: Vector3, look_at_local := Vector3.INF) -> void:
	game.player.global_position = zoo.to_global(local)
	game.player.velocity = Vector3.ZERO
	if look_at_local != Vector3.INF:
		var to: Vector3 = zoo.to_global(look_at_local) - game.player.global_position
		game.player.rotation.y = atan2(-to.x, -to.z)
	await physics_frame
	await physics_frame

func run():
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/zoo_feeding.json"))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	await seconds(1.0)
	Progress.shared().data = {}
	zoo = game.apartment.get_node("ParkZoo")
	session = game.get_node_or_null("ZooFeedingSession")
	check(session != null and session.host != null and session.till != null and session.feeder != null, "the zoo session, Nico's host, the till and the feeder are loaded")
	if session != null and session.host != null:
		session.feeder.fed.connect(func(animal: String, food: String, ate: bool) -> void: _fed.append([animal, food, ate]))
		check_data()
		check_booth()
		await free_buying()
		await free_feeding()
		await play()
		await leave_zoo()
	finish()

# --- Data -----------------------------------------------------------------------------------

func check_data() -> void:
	var lexicon = Lexicon.shared()
	var shops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json"))
	var rules: Dictionary = shops.stores.zoo
	var foods: Array = data.foods
	check(foods == ["meat", "apple", "fish", "carrot", "bamboo"], "the five booth foods (user, 24 Nov 2026)")
	check(lexicon.has_word("bamboo") and lexicon.tier("bamboo", "es") == 3, "bamboo is a word (tier 3)")
	var unpriced: Array = []
	for food in foods:
		var sold: Array = lexicon.words().get(food, {}).get("sold_in", [])
		if not sold.has("zoo") or Order.price_of(rules, food) <= 0:
			unpriced.append(food)
	check(unpriced.is_empty(), "every food is sold at the booth with a price: %s" % [unpriced])
	var animals: Array = session.feeder.animals()
	var keys: Array = animals.map(func(a: Node3D) -> String: return str(a.get_meta("word_key", "")).to_lower())
	check(animals.size() == 17, "17 zoo animals can be fed (%d)" % animals.size())
	var hungry: Array = []
	for key in data.eats:
		var liked: Array = data.eats[key]
		if liked.is_empty() or liked.any(func(f) -> bool: return not foods.has(f)):
			hungry.append(key)
		if not keys.has(key):
			hungry.append(key + " (not in the zoo)")
	check(hungry.is_empty(), "every zoo animal eats a booth food and is in the zoo: %s" % [hungry])
	var levels: Array = Board.shared().activities[GAME].levels
	var tiers: Array = levels[levels.size() - 1].tiers.map(func(t) -> int: return int(t))
	var uncovered: Array = keys.filter(func(k: String) -> bool: return not tiers.has(lexicon.tier(k, "es")))
	check(uncovered.is_empty(), "the last level may name every animal: %s" % [uncovered])
	var first: Array = levels[0].tiers.map(func(t) -> int: return int(t))
	check(first == [2] and int(levels[0].requests) == 3, "level 1: three requests of tier-2 animals")

# --- Booth ----------------------------------------------------------------------------------

func check_booth() -> void:
	var booth := zoo.get_node_or_null("ZooFoodBooth")
	check(booth != null, "the booth is baked into the base world")
	if booth == null:
		return
	var crates := 0
	for food in data.foods:
		var crate := booth.get_node_or_null("Booth food " + str(food))
		if crate != null and str(crate.get_meta("word_key", "")) == food and crate.find_child("Pick area", true, false) != null \
				and game.zones.resolve_global(crate.global_position) == "zoo":
			crates += 1
	check(crates == 5, "five food crates, each a word with a pick area in the zoo zone (%d)" % crates)
	check(Interactable.on(booth.get_node_or_null("Paper bags")) != null, "the paper bags are the till's rack")
	var keeper: Node3D = session.keeper
	check(keeper != null and str(keeper.get_meta("npc_id", "")) == "nico" and keeper.get_parent() == zoo, "Nico stands at the booth (registry NPC)")
	var label := booth.get_node_or_null("Booth sign") as Label3D
	check(label != null and label.text != "ANIMAL FOOD", "the ANIMAL FOOD board is translated (%s)" % (label.text if label != null else "-"))

# --- Free buying and feeding ------------------------------------------------------------------

func free_buying() -> void:
	var till = session.till
	var rack: Node3D = zoo.get_node("ZooFoodBooth/Paper bags")
	var item = Interactable.on(rack)
	await place(AT_BOOTH, Vector3(-75.0, 1.0, 124.1))
	check(item.check() == true, "the stack offers a bag")
	item.activate()
	await frames(2)
	var bag := Basket.carried(game.player)
	check(till.free_active and bag != null and bag.is_bag() and str(bag.get_meta("word_key", "")) == "shopping bag", "the stack hands over a paper bag")
	for key in ["apple", "apple", "bamboo", "carrot"]:
		till._on_free_pick(zoo.get_node("ZooFoodBooth/Booth food " + key))
	check(till.free_cart == {"apple": 2, "bamboo": 1, "carrot": 1}, "clicked foods go in the bag (%s)" % [till.free_cart])
	check(bag.item_count() == 4, "the bag shows them")
	await shot("booth.png", Vector3(-80.5, 2.3, 121.0), Vector3(-75.0, 1.2, 124.1))
	var total: int = Order.total_of(till.rules, till.free_cart)
	session._host_talk(session.keeper)
	check(till.paying_for == "free" and total == 425, "Nico charges the bag's total (%d)" % total)
	till._open_money()
	game.money_panel.counts = {"coin_1": total}
	till._on_submitted(total)
	await frames(2)
	bag = Basket.carried(game.player)
	check(not till.free_active and bag != null and bag.get_meta("food", {}) == {"apple": 2, "bamboo": 1, "carrot": 1}, "paid: the player keeps the bag with its food")
	check(Board.shared().blocker(GAME) == "", "paid: the game may start")
	session.host.close_dialogue()
	await seconds(0.4)
	var elephant: Node3D = zoo.get_node("Elephant")
	check(Interactable.on(elephant) != null, "with food in the bag the animals can be fed")
	# On the path in front of the booth, looking into the plains; the camera faces the player.
	await place(Vector3(-78.0, 0.2, 120.0), Vector3(-70.0, 0.2, 120.0))
	await shot("bag.png", Vector3(-76.2, 2.5, 118.2), Vector3(-77.9, 0.6, 119.5))

## Waits until the feeder reports the animal (or `limit` seconds).
func fed_by(animal: String, limit := 14.0) -> Array:
	var waited := 0.0
	while waited < limit:
		for entry in _fed:
			if entry[0] == animal:
				_fed.erase(entry)
				return entry
		await seconds(0.1)
		waited += 0.1
	return []

func free_feeding() -> void:
	var feeder = session.feeder
	var elephant: Node3D = zoo.get_node("Elephant")
	# In Wildlife Plains, in front of the elephant.
	await near(elephant)
	feeder.feed(elephant)
	check(feeder.busy_animal == elephant and str(elephant.state) == "coming", "the elephant comes to the food")
	var bag := Basket.carried(game.player)
	check(bag.get_meta("food", {}).get("apple", 0) == 1, "the apple left the bag")
	# The eating pose, mid-bite.
	var waited := 0.0
	while str(elephant.state) != "eating" and waited < 10.0:
		await seconds(0.1)
		waited += 0.1
	check(str(elephant.state) == "eating", "the elephant eats")
	await seconds(0.9)
	var food: Vector3 = zoo.to_local(feeder.food_node.global_position) if is_instance_valid(feeder.food_node) else elephant.position
	await shot("eating.png", (elephant.position + food) * 0.5 + Vector3(5.5, 2.2, 1.5), (elephant.position + food) * 0.5 + Vector3(0, 1.2, 0))
	var result := await fed_by("elephant")
	check(result == ["elephant", "apple", true], "the elephant ate the apple (%s)" % [result])
	check(not elephant.feeding() and absf(elephant.rotation.x) < 0.01, "the elephant is back to wandering")
	# A food it does not eat: the lion and carrots and apples only -> refused, back in the bag.
	var lion: Node3D = zoo.get_node("Lion")
	await near(lion)
	var before: Dictionary = bag.get_meta("food", {}).duplicate()
	feeder.feed(lion)
	waited = 0.0
	while str(lion.state) != "refusing" and waited < 10.0:
		await seconds(0.1)
		waited += 0.1
	await seconds(1.2)
	await shot("refusing.png", lion.position + Vector3(4.5, 2.2, -3.5), lion.position + Vector3(0, 1.0, -1.0))
	result = await fed_by("lion")
	check(result.size() == 3 and not result[2], "the lion refuses a food it does not eat")
	check(bag.get_meta("food", {}) == before, "the refused food is back in the bag")
	# The panda gets the bamboo; feed the rest until the bag is empty: it goes.
	var panda: Node3D = zoo.get_node("Panda")
	await near(panda)
	feeder.feed(panda)
	result = await fed_by("panda")
	check(result == ["panda", "bamboo", true], "the panda eats the bamboo (%s)" % [result])
	await near(elephant)
	for i in 2:
		feeder.feed(elephant)
		await fed_by("elephant")
	await seconds(0.5)
	check(Basket.carried(game.player) == null, "an empty bag goes away")
	await seconds(0.4)
	check(Interactable.on(elephant) == null, "without food the animals have no Interactable (word cards again)")

# --- The game ------------------------------------------------------------------------------------

func play() -> void:
	var lexicon = Lexicon.shared()
	var practice = PracticeLog.shared()
	practice.paused = false
	var stars: Array = []
	var on_stars := func(id: String, result: Dictionary) -> void:
		if id == GAME:
			stars.append(int(result.stars))
	Progress.shared().recorded.connect(on_stars)
	var completed: Array = []
	var on_ended := func(id: String, summary: Dictionary) -> void:
		if id == GAME:
			completed.append(bool(summary.completed))
	Board.shared().ended.connect(on_ended)
	await place(AT_BOOTH, Vector3(-75.0, 1.0, 124.1))
	session.open_game()
	await frames(2)
	check(session.playing and session.requests.size() == 3, "level 1: three requests (%d)" % session.requests.size())
	var all_tier_two: bool = session.requests.all(func(r: Dictionary) -> bool: return lexicon.tier(str(r.animal), lexicon.foreign) == 2)
	check(all_tier_two, "level 1 names tier-2 animals only")
	var bag := Basket.carried(game.player)
	var given := 0
	for key in bag.get_meta("food", {}):
		given += int(bag.get_meta("food")[key])
	check(bag != null and bag.has_meta("game_bag") and given == 3, "Nico hands over a bag with the session's food")
	check(session.strip.text != "" and session.strip.progress == "1/3", "the instruction strip shows the request and 1/3")
	var line: Dictionary = game.shop_panel.current_line()
	var first: Dictionary = session.requests[0]
	check(str(line.get("foreign", "")).contains(lexicon.word(str(first.animal), lexicon.foreign).trim_prefix("el ").trim_prefix("la ")), "the request names the animal: %s" % line.get("foreign", ""))
	for i in session.requests.size():
		var request: Dictionary = session.requests[i]
		var target: Node3D = _animal(str(request.animal))
		if i == 0:
			# A wrong animal first: it refuses, a miss.
			var wrong: Node3D = _animal("giraffe" if str(request.animal) != "giraffe" else "zebra")
			await near(wrong)
			session.feeder.feed(wrong)
			var result := await fed_by(str(wrong.get_meta("word_key")).to_lower())
			check(result.size() == 3 and not result[2], "the wrong animal refuses the food")
			check(Board.shared().misses(GAME) == 1 and session.missed, "the wrong animal is a miss")
			check(game.shop_panel.current_line().get("foreign", "") != line.get("foreign", ""), "Nico says which animal that was")
		await near(target)
		session.feeder.feed(target)
		var result := await fed_by(str(request.animal))
		check(result.size() == 3 and result[2], "request %d: the %s eats" % [i + 1, request.animal])
		if i + 1 < session.requests.size():
			await seconds(1.8)
			check(session.current == i + 1 and session.strip.progress == "%d/3" % (i + 2), "the next request follows")
	await frames(3)
	check(not session.playing, "the session ends after the last request")
	check(completed == [true], "the board ends the session completed (results card)")
	check(stars == [2], "one miss in a session: two stars (%s)" % [stars])
	check(Basket.carried(game.player) == null, "the game's empty bag goes")
	var counts: Dictionary = practice.counts.get(lexicon.foreign, {})
	var first_word: Dictionary = counts.get(str(first.animal), {}).get(GAME, {})
	check(int(first_word.get("negative", 0)) == 1, "practice: the first animal recorded as missed (%s)" % [first_word])
	check(not counts.is_empty(), "practice: the animals are recorded")
	Progress.shared().recorded.disconnect(on_stars)
	Board.shared().ended.disconnect(on_ended)
	session.host.close_dialogue()

## A spot 3 units from `animal` toward the middle of its zone (front zones lie north of the cross
## path, z > 104), looking at it.
func near(animal: Node3D) -> void:
	var dz: float = -3.0 if animal.position.z > 104.0 else 3.0
	await place(Vector3(animal.position.x, 0.2, animal.position.z + dz), animal.position)

func _animal(key: String) -> Node3D:
	for animal in session.feeder.animals():
		if str(animal.get_meta("word_key", "")).to_lower() == key:
			return animal
	return null

func leave_zoo() -> void:
	await place(AT_BOOTH, Vector3(-75.0, 1.0, 124.1))
	session.open_game()
	await frames(2)
	await place(Vector3(-78.0, 0.2, 131.0))
	await seconds(0.6)
	check(session.host.is_asking_leave(), "walking out of the zoo mid-game asks whether to stop")
	session.host._on_quit_answered(true)
	await frames(3)
	check(not session.playing and Basket.carried(game.player) == null, "stopping ends the game and takes its food away")
	session.host.close_dialogue()

func finish() -> void:
	print("ZOO FEEDING: %d checks, %d failures" % [checks, failures])
	if graphics():
		OS.kill(OS.get_process_id())
	quit(1 if failures > 0 else 0)
