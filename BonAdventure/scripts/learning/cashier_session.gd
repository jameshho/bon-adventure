extends Node
## One store's till: the checkout of the shopping in that store (user, 21 Nov 2026). Until then
## this was Pay Up!, a money-counting game of its own (4 Nov 2026); it was retired into the
## checkout: the cashier now charges what the player's basket costs, and the money panel
## (money_panel.gd), "Try again" and "What went wrong?" are the same as before. Main creates one
## session per entry in data/shops.json "cashiers" (scripts/core/minigame_wiring.gd).
##
## Two ways to shop, both paid here:
##   - Grocery Run (shop_session.gd, the clerk outside): "prompt, pick, pay, bring it back". The
##     cashier checks the order's basket against its list (shop_session.check_cart()): a basket
##     that is not exactly the list is not charged ("please check your list"; from the second
##     check on the cashier names what is missing and what is not on the list). An exact basket
##     is charged; paid, the order is done and the player takes it to the clerk.
##   - Free shopping: take a basket from a basket rack (data/shops.json "basket_racks", an
##     Interactable on each stack), click any product of the store into it and pay. The cashier
##     thanks the player and keeps the basket. Nothing is saved or scored.
## The total is the sum of the products' prices (data/shops.json "prices"); the cashier says it in
## the language being learned and takes only the exact amount.
##
## Calling it off: "Give back the basket" at the till, putting the basket back EMPTY on a rack, or
## the cart's ✕ (free shopping: "stop shopping and put everything back?"; the order: its own leave
## question) take the basket away unpaid. While the player carries an unpaid basket the shop door
## (data/shops.json "door") is an invisible wall and the cashier calls "please pay first" (or "put
## the basket back" when it is empty); the cashier's "!" shows while a basket waits to be paid.
##
## The cashier still uses the shared NPC host (minigame_host.gd) for talking, choices and the
## leave question, but is not a game of its own (not in data/activities.json, no "!" offer; free
## shopping registers quietly on the activity board so it blocks other games while it runs).
## The welcome tutorial's shop (tutorial_shop.gd) borrows the cashier with its own flow; this
## session ignores the shared panels while it has no basket or payment of its own.
const Currency := preload("res://scripts/learning/currency.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
const Order := preload("res://scripts/learning/shop_order.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const Zone := preload("res://scripts/learning/minigame_zone.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const ShopSession := preload("res://scripts/learning/shop_session.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")

const REQUEST_VARIANTS := 5
const WALK_AWAY_DISTANCE := 14.0
const MESSAGE_SECONDS := 9.0
const ZONE_CHECK_INTERVAL := 0.25
## Free shopping: at most this many items in the basket (it shows 12, shopping_basket.gd).
const BASKET_MAX := 12

var store_id := ""
var dialogue
var panel
var money
var interaction
var zones
var player: Node3D
var cashier: Node3D
var store_zone := ""
## The cashier's gender for the role word ("El Cajero"), from data/shops.json.
var npc_gender := ""
## The store's rules (data/shops.json "stores"): prices, basket racks, door, cart cap.
var rules: Dictionary = {}
## The shared NPC host (minigame_host.gd): the cashier, talking, choices, the leave question.
var host
## The shop door's guard (minigame_zone.gd make_door_guard()).
var door
## Free shopping: a basket from the rack is carried; what is in it (word key -> how many).
var free_active := false
var free_cart: Dictionary = {}
## Words a free basket may hold: sold in the store and priced.
var _pool: Array = []
## The payment asked for: "" none, "order" or "free"; the amount due.
var paying_for := ""
var due_cents := 0
var _missed_pay := false
var _last_given := 0
var _request_variant := 1
## The order the till last checked, how many of its baskets were turned down and the last
## basket turned down (the same basket again is not another miss).
var _order_seen: Object = null
var _wrong_checks := 0
var _last_wrong: Dictionary = {}
var _zone_timer := 0.0
var _in_zone := false
var _rng := RandomNumberGenerator.new()

func setup(for_store: String, shop_dialogue, shop_panel, money_panel, interaction_controller, town_zones, explorer: Node3D, world: Node3D, sold_in: Dictionary = {}) -> void:
	store_id = for_store
	name = "CashierSession_" + for_store
	dialogue = shop_dialogue
	panel = shop_panel
	money = money_panel
	interaction = interaction_controller
	zones = town_zones
	player = explorer
	var till: Dictionary = dialogue.cashiers.get(for_store, {})
	rules = dialogue.store_rules(for_store)
	store_zone = str(till.get("zone", for_store))
	npc_gender = str(till.get("npc_gender", ""))
	_rng.randomize()
	for key in Order.build_pool(for_store, sold_in):
		if Order.price_of(rules, key) > 0:
			_pool.append(key)
	cashier = world.find_child(str(till.get("npc", "")), true, false) as Node3D
	if cashier == null:
		push_warning("cashier_session: no cashier node '%s' for %s" % [till.get("npc", ""), for_store])
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": "checkout_" + for_store, "board": false, "group": "cashier",
			"leave_confirm": "cashier.stop_confirm", "leave_yes": "cashier.stop_yes", "leave_no": "cashier.keep_shopping",
			"walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS},
			dialogue.lexicon, panel, interaction, player, cashier)
	# Free shopping counts as a running activity (registered quietly: no game, no tile, no stars),
	# so other games wait for it and the HUD's corner buttons make room for the cart.
	Board.shared().register("checkout_" + for_store, self, true)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	money.submitted.connect(_on_submitted)
	money.close_requested.connect(_on_money_close)
	panel.remove_pressed.connect(_on_remove)
	panel.quit_requested.connect(_on_cart_quit)
	for rack_name in rules.get("basket_racks", []):
		var rack := world.find_child(str(rack_name), true, false) as Node3D
		if rack == null:
			push_warning("cashier_session: no basket rack '%s'" % rack_name)
			continue
		Interactable.attach(rack, {"kind": Interactable.Kind.USE, "badge_offset": Vector3(0, 0.75, 0),
				"on_use": _use_rack, "on_check": _rack_check})
	_make_door()

# --- Host hooks -----------------------------------------------------------------------------

## Workers have no personal name, so the box shows their role ("El Cajero").
func _host_speaker() -> Variant:
	return dialogue.speaker_line(str(cashier.get_meta("word_key", "")), npc_gender)

## The cashier never offers a game, so the "!" shows only while a basket waits to be paid.
func _host_near(_distance: float) -> bool:
	return false

func _host_calling() -> bool:
	return _unpaid_basket() and _basket_items() > 0 and not busy()

func _host_talk(_talker: Node3D) -> bool:
	_talk()
	return true

## Free shopping blocks other games while the basket is out (the order is the shop session's).
func activity_running() -> bool:
	return free_active

func busy() -> bool:
	return host != null and (host.owns_dialogue() or host.is_asking_leave()) or money.visible and paying_for != ""

## A language change in Settings: a payment in progress ends; a free basket's rows follow the
## new language.
func end_activity() -> void:
	if host == null:
		return
	if paying_for != "":
		_stop_paying()
		host.close_dialogue()
	if free_active and _free_cart_open():
		panel.update_cart(_free_data())

# --- Who is shopping ------------------------------------------------------------------------

## The store's Grocery Run session (null when left out).
func _shop() -> Node:
	return get_parent().get_node_or_null("ShopSession_" + store_id) if get_parent() != null else null

func _order_shopping() -> bool:
	var shop := _shop()
	return shop != null and shop.shopping()

## The player carries a basket of this store's shopping that is not paid yet.
func _unpaid_basket() -> bool:
	return Basket.carried(player) != null and (free_active or _order_shopping())

func _basket_items() -> int:
	var counts: Dictionary = free_cart if free_active else (_shop().cart() if _order_shopping() else {})
	var n := 0
	for key in counts:
		n += int(counts[key])
	return n

# --- Talking at the till ------------------------------------------------------------------

func _talk() -> void:
	var shop := _shop()
	if _order_shopping() and Basket.carried(player) != null:
		if shop.cart().is_empty():
			_say_with_back("cashier.basket_empty", host.choice("keep", "cashier.keep_shopping", "check"))
			return
		_check_order(shop)
	elif free_active:
		if free_cart.is_empty():
			_say_with_back("cashier.basket_empty", host.choice("keep", "cashier.keep_shopping", "check"))
			return
		_ask_pay("free", Order.total_of(rules, free_cart))
	elif shop != null and shop.awaiting_return:
		host.show_line("shop.return_to_clerk", shop.return_line())
	else:
		host.say("cashier.grab_basket")

## A line with `first` and "Give back the basket" as its choices.
func _say_with_back(id: String, first: Dictionary, line: Variant = null) -> void:
	var choices := [first, host.choice("give_back", "cashier.give_back", "exit")]
	if line == null:
		host.say(id, choices, 0.0)
	else:
		host.show_line(id, line, choices, 0.0)

## The order's basket against its list: exact -> the total; else "please check your list".
func _check_order(shop: Node) -> void:
	if shop.order != _order_seen:
		_order_seen = shop.order
		_wrong_checks = 0
		_last_wrong = {}
	var cart: Dictionary = shop.cart()
	# The same basket turned down again is no new miss (talking twice without changing it).
	var result: Dictionary = shop.order.compare() if cart == _last_wrong else shop.check_cart()
	if result.match:
		_ask_pay("order", shop.total())
		return
	if cart != _last_wrong:
		_wrong_checks += 1
		_last_wrong = cart.duplicate()
	var parts: Array = [dialogue.line("cashier.check_list")]
	if _wrong_checks >= 2:
		if not result.missing.is_empty():
			parts.append(dialogue.line("cashier.check_missing", {"missing": dialogue.items_values(result.missing)}))
		if not result.extra.is_empty():
			parts.append(dialogue.line("cashier.check_extra", {"extra": dialogue.items_values(result.extra)}))
	_say_with_back("cashier.check_list", host.choice("check", "cashier.will_check", "check"), _join(parts))

func _join(parts: Array) -> Dictionary:
	var foreign: PackedStringArray = []
	var native: PackedStringArray = []
	for part in parts:
		foreign.append(part.foreign)
		native.append(part.native)
	return {"foreign": " ".join(foreign), "native": " ".join(native)}

# --- Paying ---------------------------------------------------------------------------------

func _request_line() -> Dictionary:
	return dialogue.line("cashier.request_%d" % _request_variant, {"amount": dialogue.money_values(due_cents)})

func _money_lines() -> Dictionary:
	return {
		"request": _request_line(),
		"tray_title": dialogue.line("money.tray"),
		"bills": dialogue.line("money.bills"),
		"coins": dialogue.line("money.coins"),
		"total": dialogue.line("money.total"),
		"submit": dialogue.line("money.submit"),
		"clear": dialogue.line("money.clear"),
		"close": dialogue.line("money.close"),
		"translate": dialogue.line("common.show_translation"),
	}

## The cashier says the total and offers to count it out.
func _ask_pay(kind: String, cents: int) -> void:
	paying_for = kind
	due_cents = cents
	_missed_pay = false
	_last_given = 0
	_request_variant = _rng.randi_range(1, REQUEST_VARIANTS)
	money.reset()
	_say_with_back("cashier.request", host.choice("count", "cashier.count", "money"), _request_line())

func _open_money() -> void:
	host.close_dialogue()
	money.show_native = panel.show_native
	interaction.clear_card()
	money.open(_money_lines())
	money.set_progress(0, 0)

func _stop_paying() -> void:
	paying_for = ""
	due_cents = 0
	money.reset()
	if money.visible:
		money.hide_panel()

func _on_submitted(cents: int) -> void:
	if paying_for == "" or not money.visible:
		return
	money.hide_panel()
	_last_given = cents
	if not Currency.is_exact(money.counts, due_cents):
		if not _missed_pay and paying_for == "order" and _shop() != null:
			_shop().pay_missed()   # stars: one miss per payment (game_progress.gd)
		_missed_pay = true
		host.say("cashier.wrong", [host.choice("retry", "cashier.try_again", "retry"), host.choice("why", "cashier.what_wrong", "question")], 0.0)
		return
	var kind := paying_for
	_stop_paying()
	if kind == "order":
		var shop := _shop()
		shop.paid()
		host.show_line("cashier.correct", _join([dialogue.line("cashier.correct"), shop.return_line()]))
	else:
		_end_free()
		host.show_line("cashier.correct", _join([dialogue.line("cashier.correct"), dialogue.line("cashier.basket_back")]))

func _explain() -> void:
	var parts: Array = [dialogue.line("cashier.gave", {"given": dialogue.money_values(_last_given)})]
	if _last_given < due_cents:
		parts.append(dialogue.line("cashier.short", {"diff": dialogue.money_values(due_cents - _last_given)}))
	else:
		parts.append(dialogue.line("cashier.over", {"diff": dialogue.money_values(_last_given - due_cents)}))
	host.show_line("cashier.explain", _join(parts), [host.choice("retry", "cashier.try_again", "retry"), host.choice("give_back", "cashier.give_back", "exit")], 0.0)

## Close or ✕ on the money panel: no payment now; talking to the cashier again asks again.
func _on_money_close() -> void:
	if paying_for == "":
		return
	_stop_paying()

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"count", "retry":
			_open_money()
		"why":
			_explain()
		"check", "keep":
			host.close_dialogue()
		"give_back":
			_give_back()

## ✕, auto-close or walking away ended the cashier's line: a payment not started is dropped.
func _on_talk_closed(_line_id: String) -> void:
	if paying_for != "" and not money.visible:
		_stop_paying()

## "Give back the basket": the shopping is called off, unpaid.
func _give_back() -> void:
	_stop_paying()
	if _order_shopping():
		_shop().abort()
	elif free_active:
		_end_free()
	host.say("cashier.put_back")

# --- Free shopping ----------------------------------------------------------------------------

## A basket rack: take a basket (nothing carried) or put an empty one back (calls the shopping
## off). A basket with items in it must be emptied first (the check's line flashes).
func _rack_check() -> Variant:
	var basket := Basket.carried(player)
	if basket == null:
		return true
	if not _unpaid_basket():
		return false   # a paid order on its way to the clerk, or the tutorial's basket
	if _basket_items() == 0:
		return true
	return GameSettings.shared().inline(dialogue.line("cashier.empty_first"), panel.show_native)

func _use_rack() -> void:
	if Basket.carried(player) == null:
		_start_free()
		return
	_stop_paying()
	if _order_shopping():
		_shop().abort()
	elif free_active:
		_end_free()
	host.close_dialogue()

func _start_free() -> void:
	free_active = true
	free_cart = {}
	Basket.give(player)
	interaction.clear_card()
	interaction.pick_hook = _on_free_pick
	panel.show_cart(_free_data())

func _free_cart_open() -> bool:
	return interaction.pick_hook == Callable(self, "_on_free_pick")

func _free_data() -> Dictionary:
	return {"cart_title": dialogue.line("shop.cart_header"), "cart": ShopSession.price_rows(dialogue, rules, free_cart)}

func _on_free_pick(obj: Node3D) -> void:
	if not free_active or panel.is_quit_open() or not is_instance_valid(obj):
		return
	if obj.has_meta("character_name") or obj.has_meta("hold_kind"):
		return
	var key: String = interaction.word_key(obj)
	if not _pool.has(key) or zones.resolve_global(obj.global_position) != store_zone:
		return
	if int(free_cart.get(key, 0)) >= int(rules.get("cart_max_each", 3)):
		panel.toast(dialogue.line("shop.cart_max", {"max": int(rules.get("cart_max_each", 3))}))
		return
	if _basket_items() >= BASKET_MAX:
		panel.toast(dialogue.line("shop.basket_full"))
		return
	free_cart[key] = int(free_cart.get(key, 0)) + 1
	if panel.is_dialogue_visible() and host.owns_dialogue() and not panel.has_choices():
		host.close_dialogue()
	panel.update_cart(_free_data())
	var basket := Basket.carried(player)
	if basket != null:
		basket.remember(key, obj)
		basket.show_items(free_cart)

func _on_remove(key: String) -> void:
	if not free_active or not _free_cart_open() or not free_cart.has(key):
		return
	free_cart[key] = int(free_cart[key]) - 1
	if int(free_cart[key]) <= 0:
		free_cart.erase(key)
	panel.update_cart(_free_data())
	var basket := Basket.carried(player)
	if basket != null:
		basket.show_items(free_cart)

## The cart's ✕ while shopping freely: "stop shopping and put everything back?".
func _on_cart_quit() -> void:
	if free_active and _free_cart_open():
		host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
	if leave and free_active:
		_end_free()

## Free shopping ends (paid, given back, put back or left): the basket goes.
func _end_free() -> void:
	if not free_active:
		return
	free_active = false
	free_cart = {}
	if _free_cart_open():
		interaction.pick_hook = Callable()
		panel.hide_cart()
	host.cancel_leave()
	Basket.take_back(player)

## Grocery Run starting (shop_session.start_game()): a free basket gives way to the order's
## (not cancel_free(): Object has a method of that name).
func drop_free_basket() -> void:
	_stop_paying()
	_end_free()

# --- The shop door --------------------------------------------------------------------------

## The invisible wall in the shop door while an unpaid basket is carried (data/shops.json
## "door", world metres; the doorway of the welcome tutorial's own guard).
func _make_door() -> void:
	var spec: Dictionary = rules.get("door", {})
	if spec.is_empty():
		return
	var space := Node3D.new()
	space.name = "Shop door"
	add_child(space)
	var zone := Zone.new()
	add_child(zone)
	zone.setup(player, null, "CheckoutFade")
	var at := Vector3(float(spec.at[0]), float(spec.at[1]), float(spec.at[2]))
	var size := Vector3(float(spec.size[0]), float(spec.size[1]), float(spec.size[2]))
	var inward := Vector3(float(spec.inward[0]), 0.0, float(spec.inward[1])).normalized()
	# The question zone: a 1.2 m strip just inside the wall (sizes along the world axes).
	var along_x := absf(inward.x) >= absf(inward.z)
	var depth := size.x if along_x else size.z
	var ask_at := at + inward * (depth * 0.5 + 0.7) + Vector3.UP * size.y * 0.5
	var ask_size := Vector3(1.2, size.y, size.z) if along_x else Vector3(size.x, size.y, 1.2)
	door = zone.make_door_guard(space, at + Vector3.UP * size.y * 0.5, size, ask_at, ask_size, "Shop checkout door", {
		"blocking": func() -> bool: return _unpaid_basket() and _inside(at, inward, depth * 0.5 + 0.6),
		"ask": func() -> void: host.say("cashier.pay_first" if _basket_items() > 0 else "cashier.rack_first"),
		"layer": HouseCharacters.FIGURE_LAYER})

## The player is more than `margin` past the doorway's centre on the store side (the wall only
## stands then, clear of the player).
func _inside(at: Vector3, inward: Vector3, margin: float) -> bool:
	var offset: Vector3 = player.global_position - at
	return offset.x * inward.x + offset.z * inward.z > margin

# --- Each frame -------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(player) or zones == null:
		return
	_zone_timer += delta
	if _zone_timer >= ZONE_CHECK_INTERVAL:
		_zone_timer = 0.0
		var inside: bool = zones.resolve_global(player.global_position) == store_zone
		var left: bool = _in_zone and not inside
		_in_zone = inside
		# Out of the store some other way (the map, a language change): the free basket goes back.
		if left:
			if paying_for != "":
				_stop_paying()
				host.close_dialogue()
			_end_free()
	host.tick(delta)
