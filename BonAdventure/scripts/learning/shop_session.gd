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
## sold in the store); every wrong Done and a declined retry is a miss.
const Progress := preload("res://scripts/learning/game_progress.gd")
## A store with "basket": true in data/shops.json hands the player a shopping basket while the
## order is shopped (user, 14 Nov 2026; the same basket as the welcome tutorial's shop):
## given when the cart opens, picked items show in it, taken back when the order is handed in,
## cancelled or left. Since 14 Nov 2026 (user) the cart and the basket come at once when an order
## starts: the clerk's order line (shop.order_intro) shows in the dialogue box beside the cart
## (it closes by itself, on ✕ or on the first pick); there is no wait for it to close.
const Basket := preload("res://scripts/world/shopping_basket.gd")

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
## The order is checked, but the clerk only reports it when the player comes back to him.
var awaiting_return := false
var _result: Dictionary = {}

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
	panel.done_pressed.connect(_on_done)
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
	Board.shared().begin(activity_id())
	_apply_level()
	_start_order()

## The store's order rules with the player's level on top; the pool follows "order_words".
func _apply_level() -> void:
	rules = _store_rules.merged(Progress.shared().params(activity_id()), true)
	pool = Order.build_pool(store_id, _sold_in, rules.get("order_words", []))

func _start_order() -> void:
	order = Order.new(store_id, pool, rules)
	PracticeLog.shared().begin(activity_id(), order.order.keys())
	# The cart and the basket at once, the clerk's line beside them (14 Nov 2026, user).
	_open_cart()
	_say("shop.order_intro")

## An order is over (complete, revealed or retry declined). True when the session goes on
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
		"retry_yes":
			if order != null and order.accept_retry():
				host.close_dialogue()
				_open_cart()
		"retry_no":
			if order != null:
				order.decline_retry()
				_practice_done()
			Board.shared().add_miss(activity_id())
			_finish_order()
			needs_help = false
			_say("shop.decline_goodbye")

## ✕, auto-close or walking away ended the clerk's line.
func _on_talk_closed(_line_id: String) -> void:
	# Closing a pending retry question counts as saying no.
	if order != null and order.state == Order.State.RETRY_OFFER and not awaiting_return:
		order.decline_retry()
		_practice_done()
		Board.shared().add_miss(activity_id())
		_finish_order()
		needs_help = false

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
		"needed": _rows(order.remaining),
		"cart": _rows(order.cart),
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

func _on_done() -> void:
	if order == null or order.state != Order.State.SHOPPING or order.cart.is_empty():
		return
	_result = order.finish_shopping()
	var first: Dictionary = {}
	for key in order.order:
		first[key] = not _result.missing.has(key)
	PracticeLog.shared().first_answer(first)
	if _result.state != Order.State.RETRY_OFFER:
		_practice_done()
	if _result.state != Order.State.COMPLETE:
		Board.shared().add_miss(activity_id())
	_close_cart()
	awaiting_return = true
	_say("shop.return_to_clerk", {"clerk": dialogue.role(str(clerk.get_meta("word_key", "")), str(rules.get("clerk_gender", "")))})

## The clerk's verdict, given when the player returns to him after pressing Done.
func _report(result: Dictionary) -> void:
	# The clerk takes the basket (a retry hands it back with the kept items: _open_cart()).
	Basket.take_back(player)
	match result.state:
		Order.State.COMPLETE:
			var parts: Array = []
			for key in result.extra:
				parts.append(dialogue.line("shop.extra_item", {"item": dialogue.items_values({key: result.extra[key]})}))
			parts.append(dialogue.line("shop.success"))
			var more := _finish_order()
			if more:
				parts.append(dialogue.line("shop.another_order"))
			host.show_line("shop.success", _join(parts), _after_order(more), 0.0 if more else -1.0)
		Order.State.RETRY_OFFER:
			var parts: Array = []
			if not result.correct.is_empty():
				parts.append(dialogue.line("shop.retry_keep", {"correct": dialogue.items_values(result.correct)}))
			for key in result.extra:
				parts.append(dialogue.line("shop.extra_item", {"item": dialogue.items_values({key: result.extra[key]})}))
			parts.append(dialogue.line("shop.retry_missing", {"missing": dialogue.items_values(result.missing)}))
			host.show_line("shop.retry", _join(parts), [host.choice("retry_yes", "shop.retry_yes", "retry"), host.choice("retry_no", "shop.retry_no", "exit")], 0.0)
		Order.State.REVEALED:
			var more := _finish_order()
			var parts: Array = [dialogue.line("shop.final_reveal", {"pairs": dialogue.pairs_text(result.pairs)})]
			if more:
				parts.append(dialogue.line("shop.another_order"))
			host.show_line("shop.final_reveal", _join(parts), _after_order(more), 0.0 if more else -1.0)

## The order's result is final (complete, revealed or retry declined): record it.
func _practice_done() -> void:
	if PracticeLog.shared().game_id() == activity_id():
		PracticeLog.shared().complete()

# --- Quitting, leaving, walking away ----------------------------------------
# Esc reaches this session through Main's popup stack: it runs the ✕ of the cart (ask to
# quit), the quit prompt or the dialogue box, whichever is on top.

func _ask_quit() -> void:
	if order != null and order.state == Order.State.SHOPPING:
		host.ask_leave()

func _on_leave_answered(leave: bool) -> void:
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
		if inside != in_zone:
			in_zone = inside
			if not inside:
				_left()
	host.tick(delta)

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
