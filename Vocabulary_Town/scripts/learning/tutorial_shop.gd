extends Node
## The welcome tutorial's shopping trip (PWA restructure phase 6, 12 Nov 2026; tutorial.gd step
## "shop", settings in data/tutorial.json "shop"): the store's clerk asks for a fixed order
## (2 apples and 1 banana), the player clicks the fruit into the shared cart, pays the cashier
## the exact price with the money panel and walks out. Tutorial-only: it borrows the store's
## clerk and cashier as speakers (their own interactables are off meanwhile, so their games never
## start) and the shared cart, dialogue and money panels, whose real sessions ignore events while
## they have no order or round. Picked fruit counts as studied (word_studied); nothing goes to the
## practice log or the activity board.
##
## User review, 14 Nov 2026: the clerk greets the player and hands over a shopping basket
## (shopping_basket.gd give(), held with hand_hold.gd; picked fruit shows in it); the clerk and
## cashier speak the NATIVE language, with the words and the amount in the language being learned
## coloured in the dialogue box (Lexicon.native_line() terms; the amount always shows its
## digits); the cashier's thanks closes itself after 3 s; and until the fruit is paid for, the
## supermarket door holds the player back (minigame_zone.gd make_door_guard(), settings "door").
const ShopDialogue := preload("res://scripts/learning/shop_dialogue.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
## Seconds the cashier's thanks stays up after paying (user, 14 Nov 2026: no tap needed).
const THANKS_SECONDS := 3.0
const PAY := "tutorial_pay"
## Metres from the cashier's front within which the player is "at the till".
const TILL_RADIUS := 2.6

var tutorial
var main
var panel
var money
var interaction
var dialogue
var settings: Dictionary = {}
var clerk: Node3D
var cashier: Node3D
var store_zone := ""
## key -> count still to pick, and in the cart.
var remaining: Dictionary = {}
var cart: Dictionary = {}
var paid := false
## Where the trip is, for BonBon's "where next" line (where()): "order", "pick", "till", "pay",
## "leave", "done".
var phase := "order"
var _paying := false
var _pay_pressed := false
var _speakers: Dictionary = {}
var _turned_off: Array = []
## The basket the clerk handed over (null before the greeting and after the trip).
var basket: Node3D
## The store door's guard (minigame_zone.gd DoorGuard): stands while the player is inside and
## has not paid.
var door

func setup(director, shop_settings: Dictionary) -> void:
	name = "TutorialShop"
	tutorial = director
	main = director.main
	panel = main.shop_panel
	money = main.money_panel
	interaction = main.interaction
	settings = shop_settings
	dialogue = ShopDialogue.new()
	var store := str(settings.store)
	var rules: Dictionary = dialogue.store_rules(store)
	var till: Dictionary = dialogue.cashiers.get(store, {})
	store_zone = str(rules.get("zone", store))
	clerk = main.apartment.find_child(str(rules.get("clerk", "")), true, false) as Node3D
	cashier = main.apartment.find_child(str(till.get("npc", "")), true, false) as Node3D
	_speakers[clerk] = dialogue.speaker_line(str(clerk.get_meta("word_key", "")) if clerk != null else "", str(rules.get("clerk_gender", "")))
	_speakers[cashier] = dialogue.speaker_line(str(cashier.get_meta("word_key", "")) if cashier != null else "", str(till.get("npc_gender", "")))
	for npc in [clerk, cashier]:
		var item := Interactable.on(npc)
		if item != null and item.enabled:
			item.enabled = false
			_turned_off.append(item)
	for key in settings.items:
		remaining[str(key)] = int(settings.items[key])
	panel.done_pressed.connect(_on_done)
	panel.remove_pressed.connect(_on_remove)
	panel.choice_pressed.connect(func(id: String) -> void: _pay_pressed = _pay_pressed or id == PAY)
	money.submitted.connect(_on_submitted)
	money.close_requested.connect(_on_money_close)
	_make_door()

## The invisible wall in the store's doorway (data/tutorial.json shop "door": its centre "at",
## "size" along the space's axes and the "inward" [x, z] direction, in "space"); walking into
## it says "pay first".
func _make_door() -> void:
	var spec: Dictionary = settings.get("door", {})
	if spec.is_empty():
		return
	var space: Node3D = tutorial._space(str(spec.space))
	var at: Vector3 = tutorial._vec(spec.at)
	var size: Vector3 = tutorial._vec(spec.size)
	var inward: Vector3 = tutorial._look(spec.inward).normalized()
	# The question zone: a 1.2 m strip just inside the wall (sizes are along the space's axes).
	var along_x := absf(inward.x) >= absf(inward.z)
	var depth := size.x if along_x else size.z
	var ask_at := at + inward * (depth * 0.5 + 0.7) + Vector3.UP * size.y * 0.5
	var ask_size := Vector3(1.2, size.y, size.z) if along_x else Vector3(size.x, size.y, 1.2)
	door = tutorial.zone.make_door_guard(space, at + Vector3.UP * size.y * 0.5, size, ask_at, ask_size, "Tutorial store door", {
		"blocking": func() -> bool: return not paid and _inside(space, at, inward, depth * 0.5 + 0.6),
		"ask": func() -> void: panel.toast(tutorial.narration("tutorial.pay_first"), 2.5),
		"layer": HouseCharacters.FIGURE_LAYER})

func _remove_door() -> void:
	if door == null:
		return
	for node in [door.wall, door.zone, door]:
		if is_instance_valid(node):
			node.queue_free()
	door = null

## The player is more than `margin` past the doorway's centre on the store side (the wall only
## stands then, clear of the player, so the player can walk in).
func _inside(space: Node3D, at: Vector3, inward: Vector3, margin: float) -> bool:
	var offset: Vector3 = space.to_local(main.player.global_position) - at
	return offset.x * inward.x + offset.z * inward.z > margin

## The whole trip; returns when the player has paid and walked out (or the tutorial stopped).
func play() -> void:
	# The clerk greets the player and hands over a basket, in the native language.
	var lexicon = dialogue.lexicon
	await tutorial.say(_speakers.get(clerk, ""), tutorial.narration("tutorial.clerk_hello", {"word": {"learn": {"word": "basket"}}}), "", clerk)
	if not tutorial.running:
		return
	basket = Basket.give(main)
	var order: String = dialogue.items_text(remaining, dialogue.foreign)
	var words: Array = []
	for key in remaining:
		words.append(lexicon.word_term(str(key)))
	await tutorial.say(_speakers.get(clerk, ""), tutorial.narration("tutorial.clerk_order", {"items": order}, words), "", clerk)
	phase = "pick"
	# Shopping: clicks on the store's fruit go to the cart (InteractionController.pick_hook).
	interaction.clear_card()
	interaction.pick_hook = _on_pick
	panel.show_cart(_cart_data())
	tutorial.hint(tutorial._speaker("guide"), tutorial.narration("tutorial.pick_fruit"))
	var picked: bool = await tutorial.until(func() -> bool: return remaining.is_empty())
	if not picked:
		return
	_close_cart()
	phase = "till"
	tutorial.hint(tutorial._speaker("guide"), tutorial.narration("tutorial.go_pay"))
	var till := _till()
	var at_till: bool = await tutorial.until(func() -> bool: return tutorial._flat(main.player.global_position, till) <= TILL_RADIUS)
	if not at_till:
		return
	# Paying: the cashier asks for the price in the native language, the amount in the language
	# being learned with its digits ("dos dólares con cincuenta centavos (= $2.50)").
	phase = "pay"
	var request: Dictionary = tutorial.narration("cashier.request_1", {"amount": {"learn": dialogue.money_values(int(settings.price_cents)), "show": true}})
	while not paid:
		_pay_pressed = false
		panel.show_dialogue(_speakers.get(cashier, ""), request, [{"id": PAY, "label": tutorial.narration("cashier.count"), "icon": "money"}])
		var pressed: bool = await tutorial.until(func() -> bool: return _pay_pressed)
		if not pressed:
			return
		_open_money(request)
		var counted: bool = await tutorial.until(func() -> bool: return not _paying)
		if not counted:
			return
	var thanks: Dictionary = tutorial.narration("cashier.correct")
	panel.show_dialogue(_speakers.get(cashier, ""), thanks, [], THANKS_SECONDS)
	phase = "leave"
	# Then BonBon says where everyone waits (13 Nov 2026: without it the player was left with no
	# instruction after paying).
	await tutorial.until(func() -> bool: return not panel.is_dialogue_visible() or panel.current_line() != thanks)
	if tutorial.running:
		tutorial.hint(tutorial._speaker("guide"), tutorial.narration("tutorial.where_leave_store"))
	var outside: Dictionary = settings.outside
	var exit_at: Vector3 = tutorial._space(str(outside.space)).to_global(tutorial._vec(outside.at))
	await tutorial.until(func() -> bool: return tutorial._flat(main.player.global_position, exit_at) <= float(outside.radius))
	phase = "done"
	_restore()
	_remove_door()
	Basket.take_back(main)
	basket = null

## The phrase id of where to go next (BonBon, tutorial.gd where_line()); "" while the clerk speaks
## or the cashier's request with its button is up.
func where() -> String:
	return {"pick": "tutorial.where_fruit", "till": "tutorial.where_till", "leave": "tutorial.where_leave_store"}.get(phase, "")

## The point in front of the cashier (where a customer stands).
func _till() -> Vector3:
	if cashier == null:
		return main.player.global_position
	return cashier.global_position - cashier.global_basis.z.normalized() * 1.8

func _rows(items: Dictionary) -> Array:
	var rows: Array = []
	for key in items:
		var single := {key: items[key]}
		rows.append({"key": key, "foreign": dialogue.items_text(single, dialogue.foreign), "native": dialogue.items_text(single, dialogue.native)})
	return rows

func _cart_data() -> Dictionary:
	return {
		"list_title": dialogue.line("shop.list_header"),
		"cart_title": dialogue.line("shop.cart_header"),
		"done": dialogue.line("shop.done_button"),
		"needed": _rows(remaining),
		"cart": _rows(cart),
	}

func _on_pick(obj: Node3D) -> void:
	if not is_instance_valid(obj) or obj.has_meta("character_name") or obj.has_meta("hold_kind"):
		return
	var key: String = interaction.word_key(obj)
	if main.zones.resolve_global(obj.global_position) != store_zone:
		return
	if not remaining.has(key):
		panel.toast(tutorial.narration("tutorial.not_on_list"))
		return
	remaining[key] = int(remaining[key]) - 1
	if int(remaining[key]) <= 0:
		remaining.erase(key)
	cart[key] = int(cart.get(key, 0)) + 1
	interaction.word_studied.emit(key)
	panel.update_cart(_cart_data())
	_fill_basket(obj)

## Shows the cart's contents in the held basket; `picked`: the object just picked.
func _fill_basket(picked: Node3D = null) -> void:
	if not is_instance_valid(basket):
		return
	if picked != null:
		basket.remember(interaction.word_key(picked), picked)
	basket.show_items(cart)

func _on_remove(key: String) -> void:
	if interaction.pick_hook != Callable(self, "_on_pick") or not cart.has(key):
		return
	cart[key] = int(cart[key]) - 1
	if int(cart[key]) <= 0:
		cart.erase(key)
	remaining[key] = int(remaining.get(key, 0)) + 1
	panel.update_cart(_cart_data())
	_fill_basket()

## The cart's Done button: the order is checked as it is picked, so this only reminds.
func _on_done() -> void:
	if interaction.pick_hook == Callable(self, "_on_pick") and not remaining.is_empty():
		panel.toast(tutorial.narration("tutorial.pick_fruit"))

func _close_cart() -> void:
	if interaction.pick_hook == Callable(self, "_on_pick"):
		interaction.pick_hook = Callable()
	panel.hide_cart()

func _open_money(request: Dictionary) -> void:
	_paying = true
	panel.hide_dialogue()
	interaction.clear_card()
	money.show_native = panel.show_native
	money.reset()
	money.open({
		"request": request,
		"tray_title": dialogue.line("money.tray"),
		"bills": dialogue.line("money.bills"),
		"coins": dialogue.line("money.coins"),
		"total": dialogue.line("money.total"),
		"submit": dialogue.line("money.submit"),
		"clear": dialogue.line("money.clear"),
		"close": dialogue.line("money.close"),
		"translate": dialogue.line("common.show_translation"),
	})
	money.set_progress(0, 0)
	panel.toast(tutorial.narration("tutorial.pay_hint"), 4.0)
	main.sync_player_controls()

func _on_submitted(_cents: int) -> void:
	if not _paying or not money.visible:
		return
	paid = Currency.is_exact(money.counts, int(settings.price_cents))
	money.hide_panel()
	money.reset()
	_paying = false
	main.sync_player_controls()
	if not paid:
		panel.toast(tutorial.narration("cashier.wrong"), 3.0)

func _on_money_close() -> void:
	if not _paying:
		return
	money.hide_panel()
	_paying = false
	main.sync_player_controls()

func _restore() -> void:
	for item in _turned_off:
		if is_instance_valid(item):
			item.enabled = true
	_turned_off.clear()

## The tutorial stopped mid-trip (skip): close what this trip opened.
func stop() -> void:
	_close_cart()
	Basket.take_back(main)
	basket = null
	_remove_door()
	if _paying:
		money.hide_panel()
		money.reset()
		_paying = false
	_restore()
