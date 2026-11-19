extends RefCounted
## Currency manager for the cashier money-selection minigame (no scene, no UI, no NPC, so
## the bank and any other shop can use it). Every amount is an INTEGER NUMBER OF CENTS;
## there is no floating point anywhere in the logic.
##
## - DENOMS: the ten bills and coins, in display order.
## - random_cents(): weighted random request (see REQUEST_BUCKETS).
## - total(counts) / is_exact(counts, cents): payment validation. ANY combination that sums
##   to the request is accepted, not only the fewest pieces.
## - usd(cents): "$147.38". The amount in WORDS is language, not currency: each language's
##   rules module has money_words() (scripts/language/rules_es.gd: "ciento cuarenta y siete
##   dólares con treinta y ocho centavos"); shop_dialogue.gd::money_values() pairs the two.
##
## To change the range, edit REQUEST_BUCKETS (and MAX_CENTS follows). The $500 note was
## dropped on purpose: with a $300 cap no request needs it.

## {id, cents, kind ("bill" or "coin"), label}. `id` keys the payment dictionary.
const DENOMS: Array = [
	{"id": "bill_1", "cents": 100, "kind": "bill", "label": "$1"},
	{"id": "bill_5", "cents": 500, "kind": "bill", "label": "$5"},
	{"id": "bill_10", "cents": 1000, "kind": "bill", "label": "$10"},
	{"id": "bill_20", "cents": 2000, "kind": "bill", "label": "$20"},
	{"id": "bill_50", "cents": 5000, "kind": "bill", "label": "$50"},
	{"id": "bill_100", "cents": 10000, "kind": "bill", "label": "$100"},
	{"id": "coin_1", "cents": 1, "kind": "coin", "label": "1¢"},
	{"id": "coin_5", "cents": 5, "kind": "coin", "label": "5¢"},
	{"id": "coin_10", "cents": 10, "kind": "coin", "label": "10¢"},
	{"id": "coin_25", "cents": 25, "kind": "coin", "label": "25¢"},
]

## [lowest cents, highest cents, probability]. Inclusive and contiguous; probabilities sum
## to 1: 10% up to $9.99, 30% to $29.99, 30% to $49.99, 20% to $99.99, 10% up to $300.00.
const REQUEST_BUCKETS: Array = [
	[25, 999, 0.10],
	[1000, 2999, 0.30],
	[3000, 4999, 0.30],
	[5000, 9999, 0.20],
	[10000, 30000, 0.10],
]
const MIN_CENTS := 25
const MAX_CENTS := 30000

static func denom(id: String) -> Dictionary:
	for entry in DENOMS:
		if entry.id == id:
			return entry
	return {}

## A weighted random request. Pass a seeded RandomNumberGenerator for repeatable tests.
## Progression (game_progress.gd, 18 Nov 2026): `max_cents` caps the amount (the buckets above it
## drop out, the one it falls in is cut short) and `step` is its smallest unit in cents (100:
## whole dollars, 25: quarters); the result is a multiple of `step`, at least `step`.
static func random_cents(rng: RandomNumberGenerator = null, max_cents: int = MAX_CENTS, step: int = 1) -> int:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	max_cents = clampi(max_cents, MIN_CENTS, MAX_CENTS)
	step = maxi(1, step)
	var buckets: Array = []
	var weight := 0.0
	for bucket in REQUEST_BUCKETS:
		if int(bucket[0]) <= max_cents:
			buckets.append([int(bucket[0]), mini(int(bucket[1]), max_cents), float(bucket[2])])
			weight += float(bucket[2])
	var roll := rng.randf() * weight
	var edge := 0.0
	var picked: Array = buckets[buckets.size() - 1]
	for bucket in buckets:
		edge += float(bucket[2])
		if roll < edge:
			picked = bucket
			break
	var cents := rng.randi_range(int(picked[0]), int(picked[1]))
	return clampi(cents - cents % step, step, max_cents - max_cents % step)

# --- Payment ---------------------------------------------------------------------------

## Sum in cents of a {denomination id: count} payment.
static func total(counts: Dictionary) -> int:
	var sum := 0
	for id in counts:
		sum += int(denom(str(id)).get("cents", 0)) * int(counts[id])
	return sum

static func is_exact(counts: Dictionary, cents: int) -> bool:
	return total(counts) == cents

## "$147.38", "$3,000.00" (thousands separators for amounts of $1,000 or more).
static func usd(cents: int) -> String:
	var dollars := absi(cents) / 100
	var text := str(dollars)
	var grouped := ""
	while text.length() > 3:
		grouped = "," + text.substr(text.length() - 3) + grouped
		text = text.substr(0, text.length() - 3)
	return "%s$%s%s.%02d" % ["-" if cents < 0 else "", text, grouped, absi(cents) % 100]
