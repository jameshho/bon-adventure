extends Node
## Feeding the zoo animals from a paper bag (Feeding Time!, user design 24 Nov 2026;
## docs/game/minigames.md#feeding-time). While the player carries the zoo food booth's bag
## (shopping_basket.gd, carrier "bag") with food in it (the bag's meta "food", word key -> how
## many: paid at the booth's till, cashier_session.gd "keep_paid", or handed over by Nico's game),
## every zoo animal that eats one of the booth's foods (data/zoo_feeding.json "eats") gets an
## Interactable: E, a click or a tap on it puts a piece of food on the ground in front of the
## player and the animal comes to eat it (park_animals.gd offer_food(): head down, chewing, a happy
## hop). A food it does not eat is sniffed and refused, and goes back into the bag. One animal at
## a time. An empty bag goes away. Without food the animals have no Interactable, so a click on
## one opens its word card as usual.
##
## The game sets `judge` ((animal_key, bag_food) -> {"food": key, "eats": bool}) to decide which
## food is offered and whether the animal eats it (only the named animal does); free feeding
## offers the first food in the bag that the animal eats.
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const Art := preload("res://scripts/buildings/supermarket_products.gd")
const DATA := "res://data/zoo_feeding.json"
const ZOO := "ParkZoo"
## Seconds between checks of what the player carries.
const CHECK_SECONDS := 0.25
## Metres from the animal's body edge within which E feeds it.
const REACH := 2.6
## Where the food lies: metres ahead of the player toward the animal; its longest side (metres).
const DROP_AHEAD := 1.1
const FOOD_SIZE := 0.42

## An animal came to the food: `ate` false when it refused it (or it was the wrong animal).
signal fed(animal_key: String, food: String, ate: bool)
## A piece of food was put down for an animal.
signal offered(animal_key: String, food: String)

var player: Node3D
var zoo: Node3D
var foods: Array = []
var eats: Dictionary = {}
var food_phrases: Dictionary = {}
## Optional game rule, see the header.
var judge: Callable
## The animal busy with food now (null when none) and the food on the ground.
var busy_animal: Node3D
var food_node: Node3D
var _food_key := ""
var _animals: Array = []
var _armed := false
var _timer := 0.0
var _art

func setup(explorer: Node3D, world: Node3D) -> void:
	name = "AnimalFeeding"
	player = explorer
	zoo = world.get_node_or_null(ZOO) as Node3D
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if data is Dictionary:
		foods = data.get("foods", [])
		eats = data.get("eats", {})
		food_phrases = data.get("food_phrases", {})
	if zoo == null:
		return
	for node in zoo.get_children():
		if node is Node3D and node.has_method("offer_food") and eats.has(str(node.get_meta("word_key", "")).to_lower()):
			_animals.append(node)

## The zoo animals that can be fed (word keys in data/zoo_feeding.json "eats").
func animals() -> Array:
	return _animals

static func animal_key(animal: Node3D) -> String:
	return str(animal.get_meta("word_key", "")).to_lower()

## A food as a phrase value: its word, or the phrase that says it in a sentence (fish).
func food_value(key: String) -> Dictionary:
	return {"phrase": str(food_phrases[key])} if food_phrases.has(key) else {"word": key}

## The bag the player carries with food in it, or null.
func food_bag() -> Node3D:
	var bag := Basket.carried(player)
	if bag == null or not bag.is_bag() or (bag.get_meta("food", {}) as Dictionary).is_empty():
		return null
	return bag

## Adds `counts` (word key -> how many) to the bag's food and shows it.
static func add_food(bag: Node3D, counts: Dictionary) -> void:
	var food: Dictionary = (bag.get_meta("food", {}) as Dictionary).duplicate()
	for key in counts:
		food[key] = int(food.get(key, 0)) + int(counts[key])
		if int(food[key]) <= 0:
			food.erase(key)
	bag.set_meta("food", food)
	bag.show_items(food)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0 or zoo == null:
		return
	_timer = CHECK_SECONDS
	var want := food_bag() != null
	if want != _armed:
		_armed = want
		for animal in _animals:
			if want:
				_arm(animal)
			else:
				var item := Interactable.on(animal)
				if item != null:
					item.queue_free()
					animal.remove_child(item)

## The animal's Interactable while the player carries food.
func _arm(animal: Node3D) -> void:
	var box: AABB = animal.call("_visible_bounds")
	var top := box.end.y
	Interactable.attach(animal, {"kind": Interactable.Kind.USE, "prompt_distance": REACH, "needs_facing": false,
		"on_use": func() -> void: feed(animal),
		"on_check": func() -> Variant: return busy_animal == null and food_bag() != null,
		"on_badge": func() -> Vector3: return animal.to_global(Vector3(0, top, 0)) + Vector3.UP * 0.3,
		"on_point": func(from: Vector3) -> Vector3: return _edge(animal, from)})

## The point of the animal's footprint nearest `from` (world), at the player's height.
func _edge(animal: Node3D, from: Vector3) -> Vector3:
	var centre := animal.global_position
	var flat := Vector3(from.x - centre.x, 0, from.z - centre.z)
	var radius: float = float(animal.get("footprint")) * zoo.global_basis.get_scale().x
	var edge := centre + (flat.normalized() * minf(radius, flat.length()) if flat.length() > 0.001 else Vector3.ZERO)
	return Vector3(edge.x, from.y, edge.z)

## Offers `animal` a piece of food from the bag (E on it).
func feed(animal: Node3D) -> void:
	var bag := food_bag()
	if bag == null or busy_animal != null:
		return
	var key := animal_key(animal)
	var stock: Dictionary = bag.get_meta("food", {})
	var choice: Dictionary = judge.call(key, stock) if judge.is_valid() else _choose(key, stock)
	var food := str(choice.get("food", ""))
	if food == "" or int(stock.get(food, 0)) <= 0:
		return
	var eats_it := bool(choice.get("eats", false))
	busy_animal = animal
	_food_key = food
	# The food leaves the bag now; a refused piece goes back when the animal turns away.
	add_food(bag, {food: -1})
	_drop(animal, food)
	offered.emit(key, food)
	animal.connect("food_done", _on_done.bind(animal, food), CONNECT_ONE_SHOT)
	animal.call("offer_food", zoo.to_local(food_node.global_position), eats_it)

## Free feeding: the first food in the bag that the animal eats, else the first food (refused).
func _choose(key: String, stock: Dictionary) -> Dictionary:
	var liked: Array = eats.get(key, [])
	for food in foods:
		if int(stock.get(food, 0)) > 0 and liked.has(food):
			return {"food": food, "eats": true}
	for food in foods:
		if int(stock.get(food, 0)) > 0:
			return {"food": food, "eats": false}
	return {}

## The food on the ground between the player and the animal.
func _drop(animal: Node3D, food: String) -> void:
	if _art == null:
		_art = Art.new()
	var mesh: Mesh = _art.model(food)
	var item := MeshInstance3D.new()
	item.name = "Fed " + food
	item.mesh = mesh
	var size := mesh.get_aabb()
	var grow := FOOD_SIZE / maxf(0.001, maxf(size.size.x, maxf(size.size.y, size.size.z)))
	zoo.get_parent().add_child(item)
	var from := player.global_position
	var to := animal.global_position - from
	to.y = 0.0
	var ahead := minf(DROP_AHEAD, maxf(0.0, to.length() - 0.3))
	var at: Vector3 = from + (to.normalized() * ahead if to.length() > 0.01 else Vector3.ZERO)
	at.y = from.y
	item.global_transform = Transform3D(Basis(Vector3.UP, atan2(to.x, to.z)).scaled(Vector3.ONE * grow), at - Vector3(0, size.position.y * grow, 0))
	food_node = item

func _on_done(ate: bool, animal: Node3D, food: String) -> void:
	busy_animal = null
	if is_instance_valid(food_node):
		food_node.queue_free()
	food_node = null
	var bag := Basket.carried(player)
	if not ate and bag != null and bag.is_bag():
		add_food(bag, {food: 1})
	elif bag != null and bag.is_bag() and (bag.get_meta("food", {}) as Dictionary).is_empty() and not bag.has_meta("game_bag"):
		Basket.take_back(player)
	fed.emit(animal_key(animal), food, ate)

## A bite each chew: the food shrinks while the animal eats (called each frame while busy).
func _physics_process(delta: float) -> void:
	if busy_animal == null or not is_instance_valid(food_node):
		return
	if str(busy_animal.get("state")) == "eating":
		food_node.scale *= 1.0 - minf(1.0, delta * 0.45)
