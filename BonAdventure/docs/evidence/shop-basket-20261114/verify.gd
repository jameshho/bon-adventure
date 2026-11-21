extends SceneTree
## The supermarket's customer order game hands the player a shopping basket (user, 14 Nov 2026;
## shop_session.gd with data/shops.json "basket", shopping_basket.gd give() / show_items() /
## take_back(), held through hand_hold.gd): given when the cart opens, picked goods show in it,
## a removed item leaves it, and it is taken back when the order is handed in or the player quits.
## Since 21 Nov 2026 the order is paid at the till before it is handed in.
## Main saves study progress: run with an isolated HOME. Needs the supermarket unit:
## HOME=<scratch>/home VT_FOCUS=supermarket VT_SPAWN=none godot --headless --path . --script res://docs/evidence/shop-basket-20261114/verify.gd
## Prints "SHOP BASKET: N checks, M failures".
const Basket := preload("res://scripts/world/shopping_basket.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(20)
	var session = main.get_node_or_null("ShopSession_supermarket")
	check(session != null and session.rules.get("basket", false), "the supermarket's order game has a basket (data/shops.json)")
	if session == null:
		return finish()
	var hand = main.player.hand
	var market: Node3D = main.apartment.get_node("RelocatedSites/Supermarket/MarketInterior")
	# Order 1: start, open the cart (the clerk's line closed), pick, remove, quit.
	session.start_game()
	await frames(2)
	session._on_talk_closed("")
	await frames(2)
	check(session.order != null and main.shop_panel.is_cart_visible(), "the order's cart is open")
	var basket: Node3D = Basket.carried(main)
	check(basket != null and hand.held == basket and str(basket.get_meta("hold_kind", "")) == "basket", "the player holds a basket while shopping")
	var key: String = str(session.order.order.keys()[0])
	var product: Node3D = _product(main, market, key)
	check(product != null, "a %s to pick in the store" % key)
	if product != null:
		session._on_pick(product)
		await frames(2)
		check(int(session.order.cart.get(key, 0)) == 1 and basket.item_count() == 1, "the picked %s shows in the basket (%d)" % [key, basket.item_count()])
		session._on_pick(basket)
		check(not session.order.cart.has("basket"), "clicking the held basket picks nothing")
		session._on_remove(key)
		await frames(2)
		check(basket.item_count() == 0, "a removed item leaves the basket")
		session._on_pick(product)
		session._on_pick(product)
		await frames(2)
		check(basket.item_count() == 2, "two picks, two items in the basket")
	session._on_leave_answered(true)
	await frames(3)
	check(not hand.is_holding(), "quitting the order takes the basket back")
	# Order 2: shop and hand it in to the clerk.
	session.host.close_dialogue()
	session.start_game()
	await frames(2)
	session._on_talk_closed("")
	await frames(2)
	check(Basket.carried(main) != null, "the next order gives a basket again")
	if product != null:
		for k in session.order.order:
			var p := _product(main, market, str(k))
			for i in int(session.order.order[k]):
				if p != null:
					session._on_pick(p)
		await frames(2)
		check(Basket.carried(main) != null and Basket.carried(main).item_count() > 0, "the order's goods are in the basket")
	# Paid at the till since 21 Nov 2026 (cashier_session.gd; the cart had a Done button before).
	var till = main.get_node("CashierSession_supermarket")
	till._talk()
	till._open_money()
	main.money_panel.counts = {"coin_1": till.due_cents}
	till._on_submitted(till.due_cents)
	till.host.close_dialogue()
	await frames(2)
	check(session.awaiting_return and Basket.carried(main) != null, "paid at the till, the player carries the basket back to the clerk")
	session._report(session._result)
	await frames(3)
	check(not hand.is_holding(), "the clerk takes the basket with the order")
	finish()

## A product group of word `key` inside the store (a shelf root with a pick area).
func _product(main, market: Node3D, key: String) -> Node3D:
	for node in market.get_children():
		if node is Node3D and node.has_meta("word_key") and main.interaction.word_key(node) == key and main.zones.resolve_global(node.global_position) == "supermarket":
			return node
	return null

func finish() -> void:
	print("SHOP BASKET: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
