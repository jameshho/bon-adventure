extends SceneTree
## 3 Nov 2026: customer-order minigame, step 3 (rules only, no town loaded). Checks the
## shop_order.gd / shop_dialogue.gd logic and data/shops.json + data/phrases.json (4 Nov 2026:
## shop text moved to the shared Lexicon; phrase ids gained their 'shop.' group). It touches no
## saves. Run: godot --headless --path . --script res://docs/evidence/customer-order-20261103/verify.gd
const Order := preload("res://scripts/learning/shop_order.gd")
const Dialogue := preload("res://scripts/learning/shop_dialogue.gd")
class StubInteraction extends Node:
	signal clerk_activated(clerk: Node3D)
	var pick_hook: Callable = Callable()
	func clear_card() -> void: pass
	func word_key(obj: Node3D) -> String: return str(obj.get_meta("word_key"))
class StubZones extends Node:
	var zone := "supermarket"
	func resolve_global(_p: Vector3) -> String: return zone
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
func fill(order, items: Dictionary) -> void:
	for key in items:
		for i in int(items[key]): order.add_to_cart(key)
func run() -> void:
	var words: Dictionary = preload("res://scripts/learning/word_data.gd").load_all()
	var d := Dialogue.new()
	var rules: Dictionary = d.store_rules("supermarket")
	var pool: Array = Order.build_pool("supermarket", words.sold_in)
	check(pool.size() == 80, "supermarket pool has 80 products (%d)" % pool.size())
	check(rules.get("cart_max_each") == 10 and rules.get("retries") == 2, "rules loaded")
	# Dialogue data: every phrase has both languages; every placeholder is filled.
	for key in d.lexicon.phrases:
		check(d.lexicon.phrases[key].has(d.native) and d.lexicon.phrases[key].has(d.foreign), "phrase in both languages: " + key)
	var ln: Dictionary = d.line("shop.retry_missing", {"missing": d.items_values({"apple": 2})})
	check(ln.foreign == "Todavía me falta: 2 × la manzana. ¿Puedes intentarlo otra vez?", "foreign line: " + ln.foreign)
	check(ln.native == "I'm still missing: 2 × apple. Can you try again?", "native line: " + ln.native)
	check(d.pairs_text(["apple", "milk"]) == "la manzana = apple, la leche = milk", "reveal pairs: " + d.pairs_text(["apple", "milk"]))
	# Random orders: 200 seeds, always 2-5 unique pool items with 1-5 each.
	var seen_sizes := {}
	var all_ok := true
	for s in 200:
		var o = Order.new("supermarket", pool, rules, s)
		seen_sizes[o.order.size()] = true
		if o.order.size() < 2 or o.order.size() > 5: all_ok = false
		for key in o.order:
			if not pool.has(key) or o.order[key] < 1 or o.order[key] > 5: all_ok = false
	check(all_ok, "orders are 2-5 unique pool items, 1-5 each")
	check(seen_sizes.size() == 4, "all sizes 2..5 occur (%s)" % str(seen_sizes.keys()))
	check(Order.new("supermarket", pool, rules, 7).order == Order.new("supermarket", pool, rules, 7).order, "same seed, same order")
	check(Order.new("supermarket", ["milk"], rules, 1).order.size() == 1, "tiny pool is clamped")
	# Cart: cap, remove-one, not-sold.
	var o = Order.new("supermarket", pool, rules, 3)
	for i in 10: check(o.add_to_cart("apple") == "added", "add apple %d" % (i + 1))
	check(o.add_to_cart("apple") == "max" and o.cart["apple"] == 10, "11th apple refused at the cap")
	check(o.add_to_cart("sofa") == "not_sold", "non-product refused")
	check(o.remove_one("apple") and o.cart["apple"] == 9, "remove one")
	o.cart = {"milk": 1}
	check(o.remove_one("milk") and not o.cart.has("milk"), "row disappears at zero")
	check(not o.remove_one("milk"), "nothing to remove")
	# Perfect first try.
	o = Order.new("supermarket", pool, rules, 11)
	fill(o, o.order)
	var r: Dictionary = o.finish_shopping()
	check(o.state == Order.State.COMPLETE and r.missing.is_empty() and r.extra.is_empty() and o.is_over(), "exact cart completes")
	# Wrong, retry, then success: the clerk keeps correct items and asks only for the rest.
	o = Order.new("supermarket", ["apple", "milk", "bread", "soda", "tea"], {"unique_items": [2, 2], "quantity_each": [2, 2], "cart_max_each": 10, "retries": 2}, 5)
	var asked: Array = o.order.keys()
	var first: String = asked[0]
	var second: String = asked[1]
	var stray: String = ["apple", "milk", "bread", "soda", "tea"].filter(func(k): return not asked.has(k))[0]
	o.cart = {first: 1, stray: 1}
	r = o.finish_shopping()
	check(o.state == Order.State.RETRY_OFFER, "wrong cart offers a retry")
	check(r.correct == {first: 1} and r.missing == {first: 1, second: 2} and r.extra == {stray: 1}, "correct/missing/extra: " + str(r))
	check(o.accept_retry() and o.cart.is_empty() and o.remaining == {first: 1, second: 2} and o.accepted == {first: 1}, "retry keeps correct, returns wrong, asks the rest")
	check(o.retries_left() == 1, "one retry left")
	fill(o, {first: 1, second: 2})
	o.finish_shopping()
	check(o.state == Order.State.COMPLETE and o.accepted == o.order, "retry success; accepted equals the whole order")
	# Surplus quantity is wrong too.
	o = Order.new("supermarket", ["apple", "milk"], {"unique_items": [1, 1], "quantity_each": [2, 2], "cart_max_each": 10, "retries": 2}, 1)
	var only: String = o.order.keys()[0]
	fill(o, {only: 3})
	r = o.finish_shopping()
	check(o.state == Order.State.COMPLETE and r.extra == {only: 1} and r.missing.is_empty(), "surplus of the right item completes and is reported")
	# Three failed checks reveal; the third is final.
	o = Order.new("supermarket", pool, rules, 21)
	for attempt in 3:
		o.cart = {"sofa": 1}   # bypass add_to_cart's pool filter: a plainly wrong cart
		r = o.finish_shopping()
		if attempt < 2:
			check(o.state == Order.State.RETRY_OFFER, "failed check %d offers a retry" % (attempt + 1))
			o.accept_retry()
	check(o.state == Order.State.REVEALED and o.is_over(), "third failed check reveals")
	check(r.pairs.size() == o.order.size() and r.pairs.all(func(k): return o.order.has(k)), "reveal lists the missing words")
	check(o.add_to_cart("apple") == "closed", "no shopping after the reveal")
	# With no retries left, a cart that is missing something goes straight to the reveal.
	o = Order.new("supermarket", ["apple", "milk"], {"unique_items": [1, 1], "quantity_each": [1, 1], "cart_max_each": 10, "retries": 0}, 2)
	only = o.order.keys()[0]
	o.cart = {"sofa": 1}
	r = o.finish_shopping()
	check(o.state == Order.State.REVEALED and r.pairs == [only], "no retries: reveal lists the missing word")
	# Decline and cancel.
	o = Order.new("supermarket", pool, rules, 4)
	o.cart = {"sofa": 1}
	o.finish_shopping()
	o.decline_retry()
	check(o.state == Order.State.DECLINED and o.is_over(), "declining the retry ends the order")
	o = Order.new("supermarket", pool, rules, 4)
	o.cancel()
	check(o.state == Order.State.CANCELLED and o.is_over(), "cancel ends the order")
	run_session(d, words)
	print("CUSTOMER ORDER LOGIC: ", failures, " failures; ", checks, " checks")
	quit(0 if failures == 0 else 1)

func product(key: String) -> Node3D:
	var node := Node3D.new()
	node.set_meta("word_key", key)
	root.add_child(node)
	node.queue_free()
	return node
# The session + panel flow with stubbed interaction and zones (no town loaded).
func run_session(d, words: Dictionary) -> void:
	var world := Node3D.new()
	var clerk := Node3D.new()
	clerk.name = "BeagleClerk"
	clerk.set_meta("word_key", "salesperson")
	world.add_child(clerk)
	var player := Node3D.new()
	root.add_child(world)
	root.add_child(player)
	var panel = preload("res://scripts/ui/shop_order_panel.gd").new()
	root.add_child(panel)
	var inter := StubInteraction.new()
	var zones := StubZones.new()
	var session = preload("res://scripts/learning/shop_session.gd").new()
	root.add_child(session)
	session.setup("supermarket", d, panel, inter, zones, player, world, words.sold_in)
	check(clerk.get_meta("shop_clerk") == "supermarket" and clerk.get_meta("action_hint") == {"phrase": "common.talk_prompt"}, "clerk tagged and hinted (E: + the talk prompt, resolved on hover)")
	# Not needing help: a one-line answer, no choices.
	session.needs_help = false
	inter.clerk_activated.emit(clerk)
	check(panel.is_dialogue_visible() and not panel.has_choices() and panel.foreign_label.text == "Por ahora no necesito ayuda, ¡gracias!", "no-help line")
	# Needing help: yes/no question; translation toggle shows English.
	session.needs_help = true
	inter.clerk_activated.emit(clerk)
	check(panel.has_choices() and panel.choice_row.get_child_count() == 2, "yes/no question")
	panel.toggle_translation()
	check(panel.native_label.visible and panel.native_label.text == "Hi! Do you have a moment to help me?", "translation reveals English")
	panel.toggle_translation()
	# "Not now" ends politely and keeps the need.
	panel.choice_pressed.emit("no")
	check(panel.foreign_label.text == "No hay problema. ¡Hasta pronto!" and session.needs_help, "not now keeps needs_help")
	# Yes: cart opens, clicks are routed to the cart.
	inter.clerk_activated.emit(clerk)
	panel.choice_pressed.emit("yes")
	check(session.order_active() and not panel.is_cart_visible() and panel.is_dialogue_visible(), "the cart waits until the clerk has finished talking")
	panel.dialogue_closed.emit()
	check(session.order_active() and panel.is_cart_visible() and inter.pick_hook.is_valid(), "cart opens after the dialogue and takes over clicks")
	check(panel.done_button.disabled, "Done disabled while the cart is empty")
	var needed: Dictionary = session.order.remaining.duplicate()
	var first: String = needed.keys()[0]
	session._on_pick(product("sofa"))
	check(session.order.cart.is_empty(), "non-product click ignored")
	zones.zone = "park"
	session._on_pick(product(first))
	check(session.order.cart.is_empty(), "product outside the zone ignored")
	zones.zone = "supermarket"
	session._on_pick(product(first))
	check(session.order.cart_total() == 1 and panel.cart_box.get_child_count() == 1 and not panel.done_button.disabled, "product click adds a cart row")
	panel.remove_pressed.emit(first)
	check(session.order.cart.is_empty() and panel.cart_box.get_child_count() == 0, "remove one empties the row")
	# Quit prompt: Esc-style ask, keep shopping, then quit.
	session._ask_quit()
	check(panel.is_quit_open(), "quit prompt opens")
	session._on_pick(product(first))
	check(session.order.cart.is_empty(), "clicks ignored while the quit prompt is open")
	panel.quit_answered.emit(false)
	check(not panel.is_quit_open() and session.order_active(), "keep shopping")
	# Wrong then right (retry): first item short by one, plus a stray extra.
	var stray := ""
	for key in session.pool:
		if not needed.has(key):
			stray = key
			break
	for i in int(needed[first]) - (1 if needed[first] > 1 else 0):
		session._on_pick(product(first))
	session._on_pick(product(stray))
	for key in needed:
		if key != first:
			for i in int(needed[key]): session._on_pick(product(key))
	var short: bool = needed[first] > 1
	panel.done_pressed.emit()
	check(session.awaiting_return and not panel.is_cart_visible() and "vuelve con el vendedor" in panel.foreign_label.text and not inter.pick_hook.is_valid(), "Listo asks the player to return to the clerk: " + panel.foreign_label.text)
	panel.dialogue_closed.emit()
	inter.clerk_activated.emit(clerk)
	check(not session.awaiting_return, "returning to the clerk delivers the verdict")
	if short:
		check(panel.has_choices() and not panel.is_cart_visible() and "No necesito" in panel.foreign_label.text and "Todavía me falta: 1 × %s" % d.word_in(first, "es") in panel.foreign_label.text, "retry line names the extra and the missing: " + panel.foreign_label.text)
		panel.choice_pressed.emit("retry_yes")
		check(panel.is_cart_visible() and session.order.remaining == {first: 1} and panel.cart_box.get_child_count() == 0, "retry asks only for what is missing")
		session._on_pick(product(first))
		panel.done_pressed.emit()
		panel.dialogue_closed.emit()
		inter.clerk_activated.emit(clerk)
	check(session.order.state == 1 and "Perfecto" in panel.foreign_label.text and not session.needs_help and not inter.pick_hook.is_valid(), "success line, need cleared, clicks released")
	# Leaving the zone mid-order: cart closes and the clerk says goodbye.
	session.needs_help = true
	inter.clerk_activated.emit(clerk)
	panel.choice_pressed.emit("yes")
	panel.dialogue_closed.emit()
	session._left()
	check(not panel.is_cart_visible() and session.order.state == 5 and panel.foreign_label.text == "¡Qué pena que te vayas! Espero verte pronto.", "leaving mid-order closes the cart with a goodbye")
	# Three failed checks end with the reveal.
	inter.clerk_activated.emit(clerk)
	panel.choice_pressed.emit("yes")
	panel.dialogue_closed.emit()
	for attempt in 3:
		session._on_pick(product(stray if session.order.remaining.has(stray) == false else session.pool[0]))
		panel.done_pressed.emit()
		panel.dialogue_closed.emit()
		inter.clerk_activated.emit(clerk)
		if attempt < 2: panel.choice_pressed.emit("retry_yes")
	check(session.order.state == 3 and "No pasa nada" in panel.foreign_label.text and "=" in panel.foreign_label.text, "third failure reveals: " + panel.foreign_label.text)
	world.queue_free(); player.queue_free(); panel.queue_free(); session.queue_free(); inter.free(); zones.free()
