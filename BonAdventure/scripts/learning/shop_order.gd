extends RefCounted
## Rules and state of one "customer order" (no UI, no nodes). A clerk asks for a random
## list of products from a store's `sold_in` pool; the player fills a cart and presses
## Done; the clerk checks it. Since 21 Nov 2026 (user) the cart is checked at the till instead
## (compare(); cashier_session.gd) and only an exact cart is paid and finished (finish_shopping()
## then always COMPLETEs); the retry and reveal states are kept for the order's own checks. Wrong carts get up to `retries` second chances, after
## which the answers are revealed. Phrases live in shop_dialogue.gd; the cart panel and
## clerk talk to this class and never decide correctness themselves.
##
## Flow: SHOPPING --finish_shopping()--> COMPLETE | RETRY_OFFER | REVEALED
##       RETRY_OFFER --accept_retry()--> SHOPPING   --decline_retry()--> DECLINED
##       any state --cancel()--> CANCELLED (quit prompt or leaving the zone)
enum State { SHOPPING, COMPLETE, RETRY_OFFER, REVEALED, DECLINED, CANCELLED }

var store_id := ""
var pool: Array = []
var rules: Dictionary = {}
var state := State.SHOPPING
var order: Dictionary = {}      # what the clerk originally asked for
var accepted: Dictionary = {}   # items the clerk has already taken
var remaining: Dictionary = {}  # items still needed
var cart: Dictionary = {}       # what the player has picked in this round
var checks_done := 0
var retries_used := 0
var last_check: Dictionary = {}
var rng := RandomNumberGenerator.new()

## Words a store may order: every word whose `sold_in` lists the store id, limited to
## `allowed` when the store lists "order_words" in data/shops.json (14 Nov 2026, user: the
## supermarket orders only basic fruit and vegetables). An allowed word that is not sold there
## is left out with a warning.
static func build_pool(for_store: String, sold_in: Dictionary, allowed: Array = []) -> Array:
	var found: Array = []
	for key in sold_in:
		if (sold_in[key] as Array).has(for_store) and (allowed.is_empty() or allowed.has(key)):
			found.append(key)
	for key in allowed:
		if not found.has(key):
			push_warning("shop_order: order word '%s' is not sold in %s" % [key, for_store])
	found.sort()
	return found

## Prices (user, 21 Nov 2026: the checkout): a store's "prices" in data/shops.json are tiers of
## word -> cents, from easy words to hard ones (since 24 Nov 2026 each product in its word's tier,
## data/words.json: whole dollars, then quarters, then any cents). 0 for a word with no price.
static func price_of(store_rules: Dictionary, key: String) -> int:
	for tier in store_rules.get("prices", []):
		if (tier as Dictionary).has(key):
			return int(tier[key])
	return 0

## What `counts` (word key -> how many) costs, in cents.
static func total_of(store_rules: Dictionary, counts: Dictionary) -> int:
	var cents := 0
	for key in counts:
		cents += price_of(store_rules, str(key)) * int(counts[key])
	return cents

## The words of the first `n` price tiers (a level's "order_tiers", data/activities.json).
static func tier_words(store_rules: Dictionary, n: int) -> Array:
	var words: Array = []
	var tiers: Array = store_rules.get("prices", [])
	for i in mini(n, tiers.size()):
		words.append_array((tiers[i] as Dictionary).keys())
	return words

func _init(for_store: String, store_pool: Array, store_rules: Dictionary, seed_value: int = -1) -> void:
	store_id = for_store
	pool = store_pool.duplicate()
	rules = store_rules
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_generate_order()

func _generate_order() -> void:
	var unique_range: Array = rules.get("unique_items", [2, 5])
	var quantity_range: Array = rules.get("quantity_each", [1, 5])
	# Due words first, then new ones as they are allowed (word_memory.gd, 24 Nov 2026; was a
	# plain shuffle). The rng breaks ties, so a seeded order repeats.
	var picks: Array = preload("res://scripts/learning/word_memory.gd").shared().order(pool, rng)
	var count := clampi(rng.randi_range(int(unique_range[0]), int(unique_range[1])), 0, picks.size())
	for i in count:
		order[picks[i]] = rng.randi_range(int(quantity_range[0]), int(quantity_range[1]))
	remaining = order.duplicate()

func cart_max() -> int:
	return int(rules.get("cart_max_each", 10))

func retries_left() -> int:
	return maxi(0, int(rules.get("retries", 2)) - retries_used)

func cart_total() -> int:
	var total := 0
	for key in cart:
		total += int(cart[key])
	return total

## Returns "added", "max" (item already at the cap), "not_sold" (word is not a
## product of this store) or "closed" (not shopping).
func add_to_cart(key: String) -> String:
	if state != State.SHOPPING:
		return "closed"
	if not pool.has(key):
		return "not_sold"
	if int(cart.get(key, 0)) >= cart_max():
		return "max"
	cart[key] = int(cart.get(key, 0)) + 1
	return "added"

## The cart's ✕: removes one; the row disappears at zero.
func remove_one(key: String) -> bool:
	if state != State.SHOPPING or not cart.has(key):
		return false
	if int(cart[key]) <= 1:
		cart.erase(key)
	else:
		cart[key] = int(cart[key]) - 1
	return true

## The Done button. Compares the cart with what is still needed and moves to the next
## state. Result: {state, correct, missing, extra, pairs}. `extra` counts surplus
## (a word not asked for, or more than asked). Anything missing is wrong and leads to a
## retry or the reveal; a cart with nothing missing COMPLETEs even when `extra` is not
## empty (the clerk names the extras and gives them back). `pairs` (only on REVEALED)
## lists the missing words.
func finish_shopping() -> Dictionary:
	if state != State.SHOPPING:
		return last_check
	checks_done += 1
	var correct := {}
	var missing := {}
	var extra := {}
	for key in remaining:
		var need := int(remaining[key])
		var have := int(cart.get(key, 0))
		if mini(need, have) > 0:
			correct[key] = mini(need, have)
		if need > have:
			missing[key] = need - have
	for key in cart:
		var surplus := int(cart[key]) - int(remaining.get(key, 0))
		if surplus > 0:
			extra[key] = surplus
	var pairs: Array = []
	if missing.is_empty():
		state = State.COMPLETE
		_take(correct)
		remaining = {}
	elif checks_done > int(rules.get("retries", 2)):
		state = State.REVEALED
		pairs = missing.keys()
	else:
		state = State.RETRY_OFFER
	last_check = {"state": state, "correct": correct, "missing": missing, "extra": extra, "pairs": pairs}
	return last_check

## The till's check (21 Nov 2026): the cart against what is still needed, changing nothing.
## {"match": the cart is exactly the list, "missing", "extra"} (word key -> how many).
func compare() -> Dictionary:
	var missing := {}
	var extra := {}
	for key in remaining:
		var short := int(remaining[key]) - int(cart.get(key, 0))
		if short > 0:
			missing[key] = short
	for key in cart:
		var surplus := int(cart[key]) - int(remaining.get(key, 0))
		if surplus > 0:
			extra[key] = surplus
	return {"match": missing.is_empty() and extra.is_empty(), "missing": missing, "extra": extra}

func _take(items: Dictionary) -> void:
	for key in items:
		accepted[key] = int(accepted.get(key, 0)) + int(items[key])

## "Yes, again": the clerk keeps the correct items, wrong ones go back, and the cart
## reopens empty for what is still missing.
func accept_retry() -> bool:
	if state != State.RETRY_OFFER:
		return false
	_take(last_check.correct)
	remaining = last_check.missing.duplicate()
	cart = {}
	retries_used += 1
	state = State.SHOPPING
	return true

func decline_retry() -> void:
	if state == State.RETRY_OFFER:
		state = State.DECLINED

## Quit prompt confirmed, or the player left the store's zone.
func cancel() -> void:
	if state == State.SHOPPING or state == State.RETRY_OFFER:
		state = State.CANCELLED

func is_over() -> bool:
	return state == State.COMPLETE or state == State.REVEALED or state == State.DECLINED or state == State.CANCELLED
