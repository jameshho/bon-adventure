extends SceneTree
## Grocery Run checkout and free shopping (user, 21 Nov 2026; Pay Up! retired into the till).
## Checks: every product sold in the supermarket has one price in its tier (whole dollars, then
## quarters, then quarters with dimes, then any cents); Pay Up! is gone from the activity board
## and the till is no activity; the order's cart has prices and no Done button; the shop door
## holds back an unpaid basket; the till turns down a basket that is not exactly the list (a miss,
## the same basket again is no new miss, the second check names what is missing and extra),
## charges the exact total, counts a wrong payment as a miss, and once paid the door opens and
## the clerk takes the basket (2 misses -> 1 star); free shopping from the basket rack: picking,
## the cap, the total, paying, giving the basket back, putting an empty basket back on the rack
## (and not a full one); the order can be called off at the rack.
## With graphics it saves order-cart.png, till-check.png, till-pay.png and free-basket.png here.
## Uses Main, which saves progress: run with an isolated HOME (README; tools/run_checks.py does).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/grocery-checkout-20261121/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const Order := preload("res://scripts/learning/shop_order.gd")
const Basket := preload("res://scripts/world/shopping_basket.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const HERE := "res://docs/evidence/grocery-checkout-20261121/"
const SHOP := "shop_supermarket"
## World metres: inside the store, 3 m in from the doorway (data/shops.json door), and in
## front of the till.
const INSIDE := Vector3(-175.6, 0.1, 163.8)
const OUTSIDE := Vector3(-168.0, 0.1, 163.8)
var failures := 0
var checks := 0
var game
var shop
var till

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

func shot(file: String) -> void:
	if not graphics():
		return
	await frames(6)
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(HERE + file))
	print("saved " + file)

func run():
	data()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	await seconds(1.0)
	Progress.shared().data = {}
	shop = Board.shared().session(SHOP)
	till = game.get_node_or_null("CashierSession_supermarket")
	check(shop != null and till != null, "the clerk and the till are loaded")
	if shop != null and till != null:
		check(not Board.shared().has("checkout_supermarket") and not Board.shared().has("cashier_supermarket"), "the till is no game in the data; Pay Up! is gone")
		await order()
		await free_shopping()
		await abort_order()
	finish()

# --- Prices -----------------------------------------------------------------------------------

func data() -> void:
	var stores: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json")).stores
	var rules: Dictionary = stores.supermarket
	var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))
	words = words.get("words", words)
	var tiers: Array = rules.prices
	check(tiers.size() == 4, "four price tiers")
	var sold := 0
	var unpriced: Array = []
	for key in words:
		if words[key] is Dictionary and (words[key].get("sold_in", []) as Array).has("supermarket"):
			sold += 1
			if Order.price_of(rules, key) <= 0:
				unpriced.append(key)
	check(unpriced.is_empty(), "every supermarket product has a price: missing %s" % [unpriced])
	var bad: Array = []
	for i in tiers.size():
		for key in tiers[i]:
			var c := int(tiers[i][key])
			var ok: bool = [c % 100 == 0, c % 25 == 0 and c % 100 != 0, c % 5 == 0 and c % 25 != 0 and not [5, 15].has(c % 100), c % 5 != 0][i]
			if not ok:
				bad.append("%s %d (tier %d)" % [key, c, i + 1])
	check(bad.is_empty(), "prices follow their tier: %s" % [bad])
	check(Order.total_of(rules, {"apple": 2, "cheese": 1, "lime": 1, "garlic": 1}) == 200 + 450 + 60 + 89, "a total adds price x count")
	check(Order.tier_words(rules, 2).size() == (tiers[0] as Dictionary).size() + (tiers[1] as Dictionary).size(), "order_tiers 2 = the first two tiers")
	check(not rules.has("retries"), "the order has no retries any more")

# --- Grocery Run: prompt, pick, pay, bring it back ------------------------------------------

func place(at: Vector3) -> void:
	game.player.global_position = at
	game.player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func line_text() -> String:
	var line: Dictionary = game.shop_panel.current_line()
	return str(line.get("foreign", "")) + " | " + str(line.get("native", ""))

func fill(counts: Dictionary) -> void:
	shop.order.cart = {}
	for key in counts:
		for i in int(counts[key]):
			shop.order.add_to_cart(key)
	game.shop_panel.update_cart(shop._cart_data())

func order() -> void:
	var p = Progress.shared()
	p._store(SHOP, {"level": 2, "unlocked": 2})
	await place(OUTSIDE)
	shop.start_game()
	await frames(2)
	check(shop.order.order.size() == 3, "level 2 orders 3 items")
	var easy: Array = Order.tier_words(shop.rules, 2)
	check(shop.pool.all(func(k): return easy.has(k)) and shop.pool.size() == easy.size(), "level 2 orders from the first two price tiers (%d)" % shop.pool.size())
	check(Basket.carried(game.player) != null, "the clerk hands over a basket")
	check(game.shop_panel.is_cart_visible() and not game.shop_panel.done_button.visible, "the cart shows, with no Done button")
	var first_row: Dictionary = shop._cart_data().needed[0]
	check(str(first_row.native).contains("$"), "the list shows prices: " + str(first_row.native))
	await shot("order-cart.png")
	shop.host.close_dialogue()
	# The door: open outside; a wall once inside with the unpaid basket.
	await place(INSIDE)
	await frames(3)
	check(till.door != null and till.door.blocks(), "the shop door holds back an unpaid basket")
	# The till with a wrong basket: the first item missing, an extra product added.
	var keys: Array = shop.order.order.keys()
	var wrong: Dictionary = {}
	for key in keys.slice(1):
		wrong[key] = shop.order.order[key]
	var extra := ""
	for key in shop.pool:
		if not shop.order.order.has(key):
			extra = key
			break
	wrong[extra] = 1
	fill(wrong)
	var cashier: Node3D = till.cashier
	var front: Vector3 = cashier.global_position - cashier.global_basis.z * 2.0
	await place(Vector3(front.x, 0.1, front.z))
	till._talk()
	await frames(2)
	check(till.host.line_id == "cashier.check_list" and till.paying_for == "", "a wrong basket is not charged: " + line_text())
	check(Board.shared().misses(SHOP) == 1, "a wrong basket is a miss")
	await shot("till-check.png")
	till._talk()
	check(Board.shared().misses(SHOP) == 1, "the same basket again is no new miss")
	wrong.erase(extra)
	fill(wrong)
	till._talk()
	var said: String = line_text()
	check(Board.shared().misses(SHOP) == 2 and said.count(".") >= 2, "the second wrong basket names what is missing: " + said)
	till.host.close_dialogue()
	# The exact basket: the total, a wrong payment, then the exact one.
	fill(shop.order.order)
	till._talk()
	var total: int = Order.total_of(shop.rules, shop.order.order)
	check(till.paying_for == "order" and till.due_cents == total, "the exact basket is charged its total (%d)" % till.due_cents)
	till._on_choice(till.host.choice_prefix() + "count")
	await frames(2)
	check(game.money_panel.visible, "Count out the money opens the money panel")
	await shot("till-pay.png")
	game.money_panel.counts = {"coin_1": total + 1}
	till._on_submitted(total + 1)
	check(Board.shared().misses(SHOP) == 3 and till.host.line_id == "cashier.wrong", "a wrong payment is a miss")
	till._on_choice(till.host.choice_prefix() + "retry")
	await frames(1)
	game.money_panel.counts = {"coin_1": total}
	till._on_submitted(total)
	await frames(3)
	check(shop.awaiting_return and not shop.shopping(), "paid: the order waits for the clerk")
	check(not till.door.blocks() and Basket.carried(game.player) != null, "paid: the door opens, the basket stays with the player")
	check(not game.shop_panel.is_cart_visible(), "paid: the cart closes")
	till.host.close_dialogue()
	# Back to the clerk.
	await place(OUTSIDE)
	shop.host._on_talk(shop.clerk)
	await frames(3)
	check(Basket.carried(game.player) == null and shop.host.line_id == "shop.success", "the clerk takes the basket and thanks the player")
	shop.host.close_dialogue()
	await frames(3)
	check(p.best(SHOP, 2) == 1, "three misses: 1 star (%d)" % p.best(SHOP, 2))
	game.star_card.visible = false

# --- Free shopping ----------------------------------------------------------------------------

func product(key: String) -> Node3D:
	for node in till.cashier.get_parent().find_children("*", "Node3D", true, false):
		if str(node.get_meta("word_key", "")) == key:
			return node
	return null

func free_shopping() -> void:
	var rack: Node3D = game.apartment.find_child("Shopping basket", true, false)
	var item = Interactable.on(rack) if rack != null else null
	check(item != null, "the basket rack is an Interactable")
	if item == null:
		return
	await place(INSIDE)
	check(item.check() == true, "the rack offers a basket")
	item.activate()
	await frames(2)
	check(till.free_active and Basket.carried(game.player) != null and game.shop_panel.is_cart_visible(), "the rack hands over a basket and an empty cart")
	check(not game.shop_panel.needed_box.visible, "free shopping has no shopping list")
	check(till.door.blocks(), "the door holds back the empty basket too")
	await frames(2)
	check(Board.shared().blocker("shop_supermarket") == "checkout_supermarket" and game.hud.in_minigame, "free shopping blocks other games and clears the HUD corner")
	var picked: Array = []
	for key in ["milk", "cheese", "avocado", "garlic", "apple"]:
		var node := product(key)
		if node != null:
			till._on_free_pick(node)
			picked.append(key)
	check(picked.size() >= 2 and till.free_cart.size() == picked.size(), "clicked products go in the basket (%s)" % [picked])
	check(Basket.carried(game.player).item_count() > 0, "the basket shows them")
	check(item.check() is String, "a full basket cannot go back on the rack")
	var one := product(picked[0])
	for i in 4:
		till._on_free_pick(one)
	check(int(till.free_cart[picked[0]]) == 3, "at most 3 of one product")
	await shot("free-basket.png")
	var total: int = Order.total_of(till.rules, till.free_cart)
	till._talk()
	check(till.paying_for == "free" and till.due_cents == total, "the till charges the free basket's total")
	till._open_money()
	game.money_panel.counts = {"coin_1": total}
	till._on_submitted(total)
	await frames(2)
	check(not till.free_active and Basket.carried(game.player) == null and not till.door.blocks(), "paid: the cashier keeps the basket, the door opens")
	check(Board.shared().blocker("shop_supermarket") == "", "paid: other games may start")
	till.host.close_dialogue()
	# Give the basket back at the till.
	item.activate()
	till._on_free_pick(one)
	till._talk()
	till._on_choice(till.host.choice_prefix() + "give_back")
	await frames(2)
	check(not till.free_active and Basket.carried(game.player) == null, "giving the basket back calls the shopping off")
	till.host.close_dialogue()
	# An empty basket back on the rack.
	item.activate()
	check(till.free_active, "a second basket")
	item.activate()
	await frames(2)
	check(not till.free_active and Basket.carried(game.player) == null and not game.shop_panel.is_cart_visible(), "an empty basket goes back on the rack")

func abort_order() -> void:
	var item = Interactable.on(game.apartment.find_child("Shopping basket2", true, false))
	await place(OUTSIDE)
	shop.start_game()
	shop.host.close_dialogue()
	await place(INSIDE)
	check(item.check() == true, "the order's empty basket may go back on the rack")
	item.activate()
	await frames(3)
	check(not shop.order_active() and Basket.carried(game.player) == null and not till.door.blocks(), "the rack calls the order off")
	check(not shop.activity_running(), "the order is over")
	shop.host.close_dialogue()

func finish() -> void:
	print("GROCERY CHECKOUT: %d checks, %d failures" % [checks, failures])
	if graphics():
		OS.kill(OS.get_process_id())
	quit(1 if failures > 0 else 0)
