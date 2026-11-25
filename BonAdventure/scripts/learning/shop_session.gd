extends Node
## One store's "customer order" minigame: ties the clerk, the zone, the shared panel and
## the order rules (shop_order.gd) together. Main creates one session per entry in
## data/shops.json "stores"; a store's clerk node, zone id, order rules and
## orderable words (`sold_in` in words.json) all come from data. The session never
## studies or saves words: while the cart is open, clicks go to `_on_pick` instead of
## the word card (InteractionController.pick_hook).
##
## Since 9 Nov 2026 the clerk uses the shared NPC host (minigame_host.gd): the "!", the
## greeting with Yes / Not now, the leave question of the cart and walking away. The offer
## is rolled on entering the store (_host_near()); the "!" also shows while the clerk waits
## for the player to come back after Done (_host_calling()). A session is one order unless
## the activity board says more rounds (the test launcher): then the clerk asks for another
## order after each finished one.
const Order := preload("res://scripts/learning/shop_order.gd")
## Offers follow the shared activity board (data/activities.json "shop_<store>"); an order is
## one round, so it has no progress bar (user decision, 4 Nov 2026).
const Board := preload("res://scripts/learning/activity_board.gd")
const Host := preload("res://scripts/learning/minigame_host.gd")
## Practice tracking (practice_log.gd): one order is one question testing each ordered item;
## an item is right when the first Done had none of it missing.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
## Levels and stars (game_progress.gd, 18 Nov 2026): the player's level replaces some of the
## store's order rules (data/activities.json "levels"; an empty "order_words" opens every product
## sold in the store, "order_tiers" the first n price tiers); every basket the till turns down and
## every wrong payment is a miss (21 Nov 2026).
const Progress := preload("res://scripts/learning/game_progress.gd")
## A store with "basket": true in data/shops.json hands the player a shopping basket while the
## order is shopped (user, 14 Nov 2026; the same basket as the welcome tutorial's shop):
## given when the cart opens, picked items show in it, taken back when the order is handed in,
## cancelled or left. Since 14 Nov 2026 (user) the cart and the basket come at once when an order
## starts: the clerk's order line (shop.order_intro) shows in the dialogue box beside the cart
## (it closes by itself, on ✕ or on the first pick); there is no wait for it to close.
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Currency := preload("res://scripts/learning/currency.gd")
## Checkout (user, 21 Nov 2026; Pay Up! retired into it): the order is "prompt, pick, pay, bring
## it back". There is no Done button: the cashier (cashier_session.gd, the till) checks the basket
## against the list (check_cart(); a basket that is not exactly the list is a miss and is not
## charged), says the total of the products' prices (data/shops.json "prices") and takes the exact
## money; paid() then finishes the order and the clerk outside takes the basket and thanks the
## player. The shop door holds back an unpaid basket. Giving the basket back to the cashier,
## putting it back empty on the basket rack or the cart's ✕ calls the order off (abort()).
## Stars: every basket the till turns down and every wrong payment is a miss.

const ZONE_CHECK_INTERVAL := 0.25
const WALK_AWAY_DISTANCE := 14.0
const MESSAGE_SECONDS := 9.0

var store_id := ""
var rules: Dictionary = {}
var dialogue
var panel
var interaction
var zones
var player: Node3D
var clerk: Node3D
var pool: Array = []
## The store's own rules and the words sold there (data/shops.json, words.json `sold_in`), kept
## so each order can apply the player's level to them.
var _store_rules: Dictionary = {}
var _sold_in: Dictionary = {}
var store_zone := ""
var order
var in_zone := false
var _zone_timer := 0.0
## The shared NPC host (minigame_host.gd): the clerk, the "!", talking, leaving.
var host
var presence:
	get: return host.presence if host != null else null
var _rest_position: Vector3:
	get: return presence.rest_position if presence != null else Vector3.ZERO
## Whether the clerk needs help now (rolled on entering the store; kept on the host).
var needs_help: bool:
	get: return host.offered if host != null else false
	set(value):
		if host != null:
			host.offered = value
## The order is paid, but the clerk only reports it when the player comes back to him.
var awaiting_return := false
var _result: Dictionary = {}
## Leaving the store's zone during an order asks the shared leave question (user, 23 Nov 2026:
## after paying, the player could walk off before bringing the basket back): the player is put
## back where they were a moment before, inside, facing the clerk, and stands still until they
## answer. Yes ends the order with the clerk's goodbye; No (or Esc) keeps it.
var _asked_at_edge := false
## The player's last places inside the zone (one per zone check), oldest first.
var _inside_spots: Array = []
const INSIDE_SPOTS := 3

func setup(for_store: String, shop_dialogue, shop_panel, interaction_controller, town_zones, explorer: Node3D, world: Node3D, sold_in: Dictionary) -> void:
	store_id = for_store
	name = "ShopSession_" + for_store
	dialogue = shop_dialogue
	panel = shop_panel
	interaction = interaction_controller
	zones = town_zones
	player = explorer
	rules = dialogue.store_rules(for_store)
	_store_rules = rules
	_sold_in = sold_in
	store_zone = str(rules.get("zone", for_store))
	pool = Order.build_pool(for_store, sold_in, rules.get("order_words", []))
	clerk = world.find_child(str(rules.get("clerk", "")), true, false) as Node3D
	if clerk == null:
		push_warning("shop_session: no clerk node '%s' for %s" % [rules.get("clerk", ""), for_store])
		return
	host = Host.new()
	add_child(host)
	host.setup(self, {"activity": activity_id(), "group": "shop", "greeting": "shop.greeting_needs_help",
			"play": "common.reply_yes", "not_now": "shop.greeting_no_help", "goodbye": "shop.decline_goodbye",
			"leave_confirm": "shop.quit_confirm", "leave_yes": "shop.quit_yes", "leave_no": "shop.quit_no",
			"walk_away": WALK_AWAY_DISTANCE, "message_seconds": MESSAGE_SECONDS},
			dialogue.lexicon, panel, interaction, player, clerk)
	host.play_chosen.connect(start_game)
	host.choice_made.connect(_on_choice)
	host.talk_closed.connect(_on_talk_closed)
	host.leave_answered.connect(_on_leave_answered)
	panel.remove_pressed.connect(_on_remove)
	panel.quit_requested.connect(_ask_quit)

func activity_id() -> String:
	return "shop_" + store_id

# --- Host hooks and the activity board --------------------------------------------------------

## Workers have no personal name, so the box shows their role ("El Vendedor").
func _host_speaker() -> Variant:
	if not is_instance_valid(clerk):
		return {"foreign": "", "native": ""}
	return dialogue.speaker_line(str(clerk.get_meta("word_key", "")), str(rules.get("clerk_gender", "")))

## The clerk calls while the player is in the store (each visit rolls the offer again).
func _host_near(_distance: float) -> bool:
	return in_zone

## The "!" also shows while the clerk waits to report a checked order.
func _host_calling() -> bool:
	return awaiting_return and not host.owns_dialogue()

## Coming back after Done: the clerk reports the order instead of greeting.
func _host_talk(_talker: Node3D) -> bool:
	if not awaiting_return:
		return false
	awaiting_return = false
	_report(_result)
	return true

## For the activity board: an order is open or waiting for its verdict.
func activity_running() -> bool:
	return order_active() or awaiting_return

func order_active() -> bool:
	return order != null and not order.is_over()

## True while this session owns the panel (an order, or a question waiting for an answer).
func busy() -> bool:
	return (order_active() and not awaiting_return) or (host != null and host.owns_dialogue() and panel.has_choices())

func _say(key: String, values: Dictionary = {}, choices: Array = [], auto_close: float = -1.0) -> void:
	host.say(key, choices, auto_close, values)

func _join(parts: Array) -> Dictionary:
	var foreign: PackedStringArray = []
	var native: PackedStringArray = []
	for part in parts:
		foreign.append(part.foreign)
		native.append(part.native)
	return {"foreign": " ".join(foreign), "native": " ".join(native)}

# --- Orders -------------------------------------------------------------------------------

## Yes on the greeting (or the test launcher): a new session of orders.
func start_game() -> void:
	var till := _till()
	if till != null:
		till.drop_free_basket()   # a free-shopping basket gives way to the order's basket
	Board.shared().begin(activity_id())
	_apply_level()
	_start_order()

## The store's order rules with the player's level on top; the pool follows "order_words".
func _apply_level() -> void:
	rules = _store_rules.merged(Progress.shared().params(activity_id()), true)
	# "order_tiers" n: the products of the first n price tiers (easy words first, 21 Nov 2026).
	var words: Array = Order.tier_words(rules, int(rules.order_tiers)) if rules.has("order_tiers") else rules.get("order_words", [])
	pool = Order.build_pool(store_id, _sold_in, words)

func _start_order() -> void:
	order = Order.new(store_id, pool, rules)
	PracticeLog.shared().begin(activity_id(), order.order.keys())
	# The cart and the basket at once, the clerk's line beside them (14 Nov 2026, user).
	_open_cart()
	_say("shop.order_intro")

## An order is over (paid and brought back). True when the session goes on
## with another order (more rounds on the activity board).
func _finish_order() -> bool:
	Board.shared().add_success(activity_id())
	return Board.shared().done(activity_id()) < Board.shared().rounds(activity_id())

## The choices after a finished order: another order while rounds remain, else none.
func _after_order(more: bool) -> Array:
	if not more:
		needs_help = false
		return []
	return [host.choice("another", "common.reply_yes", "check"), host.choice("no", "common.reply_no", "no")]

func _on_choice(id: String) -> void:
	match id.trim_prefix(host.choice_prefix()):
		"another":
			host.close_dialogue()
			_start_order()

## ✕, auto-close or walking away ended the clerk's line (nothing to do since the till checks).
func _on_talk_closed(_line_id: String) -> void:
	pass

# --- Cart -----------------------------------------------------------------------------

func _open_cart() -> void:
	host.zoom(false)
	interaction.clear_card()
	interaction.pick_hook = _on_pick
	panel.show_cart(_cart_data())
	host.cancel_leave()
	if rules.get("basket", false):
		Basket.give(player)
		_fill_basket()

## Shows the cart in the carried basket; `picked`: the object just picked (how it looks).
func _fill_basket(picked: Node3D = null) -> void:
	var basket := Basket.carried(player)
	if basket == null or order == null:
		return
	if picked != null:
		basket.remember(interaction.word_key(picked), picked)
	basket.show_items(order.cart)

func _close_cart() -> void:
	interaction.pick_hook = Callable()
	panel.hide_cart()

## Order or cart rows; each shows the product's price ("$1.25 each"; the till says the total).
static func price_rows(shop_dialogue, store_rules: Dictionary, items: Dictionary) -> Array:
	var rows: Array = []
	for key in items:
		var single := {key: items[key]}
		var price := Order.price_of(store_rules, str(key))
		var row := {"key": key}
		for slot in ["foreign", "native"]:
			var lang: String = shop_dialogue.foreign if slot == "foreign" else shop_dialogue.native
			# The price wraps as one piece ("$3.00 c/u" never splits).
			var tag: String = "   " + shop_dialogue.phrase("shop.price_each", lang, {"price": Currency.usd(price)}).replace(" ", "\u00a0") if price > 0 else ""
			# "/" is a line-break chance: a word joiner keeps "c/u" whole.
			row[slot] = shop_dialogue.items_text(single, lang) + tag.replace("/", "/\u2060")
		rows.append(row)
	return rows

## No "done": the cart has no Done button since the till checks it (21 Nov 2026).
func _cart_data() -> Dictionary:
	return {
		"list_title": dialogue.line("shop.list_header"),
		"cart_title": dialogue.line("shop.cart_header"),
		"needed": price_rows(dialogue, rules, order.remaining),
		"cart": price_rows(dialogue, rules, order.cart),
	}

func _on_pick(obj: Node3D) -> void:
	if order == null or order.state != Order.State.SHOPPING or panel.is_quit_open() or not is_instance_valid(obj):
		return
	if obj.has_meta("character_name") or obj.has_meta("hold_kind"):
		return
	var key: String = interaction.word_key(obj)
	if not pool.has(key) or zones.resolve_global(obj.global_position) != store_zone:
		return
	match order.add_to_cart(key):
		"added":
			if panel.is_dialogue_visible() and not panel.has_choices():
				panel.hide_dialogue()
			panel.update_cart(_cart_data())
			_fill_basket(obj)
		"max":
			panel.toast(dialogue.line("shop.cart_max", {"max": order.cart_max()}))

func _on_remove(key: String) -> void:
	if order != null and order.remove_one(key):
		panel.update_cart(_cart_data())
		_fill_basket()

# --- Checkout (the till, cashier_session.gd) -------------------------------------------------

## The till session of this store (null when its cashier is left out).
func _till() -> Node:
	return get_parent().get_node_or_null("CashierSession_" + store_id) if get_parent() != null else null

## An order is being shopped and not yet paid (the till checks it; the door holds it back).
func shopping() -> bool:
	return order != null and order.state == Order.State.SHOPPING and not awaiting_return

## The order's cart, for the till.
func cart() -> Dictionary:
	return order.cart if order != null else {}

## The till's check of the basket against the list ({"match", "missing", "extra"}). The first
## check is the practice answer: an item is right when nothing of it was missing or extra; every
## basket turned down is a miss.
func check_cart() -> Dictionary:
	var result: Dictionary = order.compare()
	if order.checks_done == 0:
		var first: Dictionary = {}
		for key in order.order:
			first[key] = not result.missing.has(key) and not result.extra.has(key)
		PracticeLog.shared().first_answer(first)
	order.checks_done += 1
	if not result.match:
		Board.shared().add_miss(activity_id())
	return result

## A wrong payment at the till.
func pay_missed() -> void:
	Board.shared().add_miss(activity_id())

## What the order's basket costs.
func total() -> int:
	return Order.total_of(rules, order.cart) if order != null else 0

## The till took the exact money: the order is done; the player brings the basket to the clerk.
func paid() -> void:
	if not shopping():
		return
	_result = order.finish_shopping()
	_practice_done()
	_close_cart()
	awaiting_return = true

## The clerk's line for the till ("please return to the clerk").
func return_line() -> Dictionary:
	return dialogue.line("shop.return_to_clerk", {"clerk": dialogue.role(str(clerk.get_meta("word_key", "")), str(rules.get("clerk_gender", "")))})

## The order is called off: the basket given back to the cashier or put back empty on the rack.
## The basket goes; the caller says the line.
func abort() -> void:
	if not shopping():
		return
	order.cancel()
	host.abandon_practice()
	host.cancel_leave()
	_close_cart()
	Basket.take_back(player)
	needs_help = false

## The clerk's thanks when the player brings the paid basket back; he takes the basket.
func _report(_result_unused: Dictionary) -> void:
	Basket.take_back(player)
	var parts: Array = [dialogue.line("shop.success")]
	var more := _finish_order()
	if more:
		parts.append(dialogue.line("shop.another_order"))
	host.show_line("shop.success", _join(parts), _after_order(more), 0.0 if more else -1.0)

## The order's result is final (paid): record it.
func _practice_done() -> void:
	if PracticeLog.shared().game_id() == activity_id():
		PracticeLog.shared().complete()

# --- Quitting, leaving, walking away ----------------------------------------
# Esc reaches this session through Main's popup stack: it runs the ✕ of the cart (ask to
# quit), the quit prompt or the dialogue box, whichever is on top.

func _ask_quit() -> void:
	if order != null and order.state == Order.State.SHOPPING:
		host.ask_leave()

## Esc / back with no popup open while an order runs (Main, the request_leave() contract,
## docs/guides/MINIGAMES.md; 25 Nov 2026): the in-world part (shopping with the basket, or the
## paid basket on its way back to the clerk) asks the shared leave question. True when taken.
func request_leave() -> bool:
	if host == null or not activity_running():
		return false
	if not host.is_asking_leave():
		host.ask_leave()
	return true

func _on_leave_answered(leave: bool) -> void:
	var at_edge := _asked_at_edge
	_asked_at_edge = false
	if at_edge:
		if not leave and zones.resolve_global(player.global_position) != store_zone:
			_step_back_in()
		if get_parent() != null and get_parent().has_method("sync_player_controls"):
			get_parent().sync_player_controls()
	if leave and awaiting_return:
		_left()
		return
	if leave and order != null and order.state == Order.State.SHOPPING:
		order.cancel()
		host.abandon_practice()
		_close_cart()
		Basket.take_back(player)
		needs_help = false
		_say("shop.decline_goodbye")

func _process(delta: float) -> void:
	if host == null or not is_instance_valid(player) or zones == null:
		return
	_zone_timer += delta
	if _zone_timer >= ZONE_CHECK_INTERVAL:
		_zone_timer = 0.0
		var inside: bool = zones.resolve_global(player.global_position) == store_zone
		if inside:
			_inside_spots.append(player.global_position)
			if _inside_spots.size() > INSIDE_SPOTS:
				_inside_spots.pop_front()
		if inside != in_zone:
			if not inside and activity_running() and not _inside_spots.is_empty():
				_ask_at_edge()
			else:
				in_zone = inside
				if not inside:
					_left()
	host.tick(delta)

## The player walked out of the store's zone during an order: back inside, and the leave
## question (see _asked_at_edge).
func _ask_at_edge() -> void:
	_step_back_in()
	if _asked_at_edge or host.is_asking_leave():
		return
	_asked_at_edge = true
	player.set_controls_enabled(false)
	host.ask_leave()

## Puts the player at their oldest remembered spot inside the zone, facing the clerk.
func _step_back_in() -> void:
	if _inside_spots.is_empty():
		return
	player.global_position = _inside_spots[0]
	player.velocity = Vector3.ZERO
	var look: Vector3 = clerk.global_position - player.global_position if is_instance_valid(clerk) else Vector3.ZERO
	if Vector2(look.x, look.z).length() > 0.1:
		var yaw := atan2(-look.x, -look.z)
		player.rotation.y = yaw
		player.camera_yaw = yaw
	player.reset_camera()

## A language change in Settings ends a running order with the clerk's goodbye, as leaving.
func end_activity() -> void:
	_left()

## Leaving the zone in the middle of an order or question closes it with the clerk's goodbye.
func _left() -> void:
	if host == null or not (busy() or awaiting_return):
		return
	if order_active():
		order.cancel()
		host.abandon_practice()
	awaiting_return = false
	host.cancel_leave()
	_close_cart()
	Basket.take_back(player)
	_say("shop.leave_goodbye")
