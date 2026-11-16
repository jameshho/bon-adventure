extends RefCounted
## The three NPC players at the mahjong table (docs/guides/MAHJONG.md). Simple and readable rather
## than strong.
##
## Any-fan mode: discard the tile that leaves the hand closest to ready (shanten), ties broken
## by keeping valuable honors and connected tiles.
## 3-fan mode: every turn the NPC picks the plan its hand is closest to among the ways to
## 3 fan: one suit plus honors (mixed / pure one suit), all pungs, or seven pairs; it discards
## to get closer to that plan first, then to ready. Claims: always win when allowed; pung
## dragons and scoring winds; pung any tile that fits an all-pungs or one-suit plan; otherwise
## pung or chow only when it brings the hand closer (to its plan in the 3-fan mode; no chows for
## an all-pungs plan, no claims for seven pairs). The plan chosen is kept in game.ai_plans.
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const FAR := 99
## Seven pairs can claim nothing: chosen only when clearly closer. Measured on 80 simulated
## 3-fan hands (9 Nov 2026): penalty 1 and no plan stickiness gave 38 wins (0: 33, 2: 35;
## keeping the previous plan unless another was 1-2 steps closer: 17-25).
const PAIRS_PENALTY := 1

## The action for `seat` on its turn: {"type": "win"} / {"type": "kong", "tile"} /
## {"type": "discard", "tile"}.
static func turn_action(game, seat: int) -> Dictionary:
	if game.can_self_win(seat):
		return {"type": "win"}
	var plan := choose_plan(game, seat)
	for kind in game.kong_options(seat):
		if str(plan.kind) != "pairs":
			return {"type": "kong", "tile": kind}
	return {"type": "discard", "tile": choose_discard(game, seat, plan)}

static func choose_discard(game, seat: int, plan: Dictionary = {}) -> int:
	if plan.is_empty():
		plan = choose_plan(game, seat)
	var hand: Array = game.hands[seat]
	var melds: Array = game.melds[seat]
	var best_tile: int = hand[hand.size() - 1]
	var best_value := INF
	var tried := {}
	for tile in hand:
		if tried.has(tile):
			continue
		tried[tile] = true
		var rest: Array = hand.duplicate()
		rest.erase(tile)
		var value := float(distance(rest, melds, plan)) * 1000.0
		value += float(Rules.shanten(Rules.counts(rest), melds.size())) * 100.0
		value -= _keep_value(game, seat, tile, rest, plan)
		if value < best_value:
			best_value = value
			best_tile = tile
	return best_tile

# --- Plans ---------------------------------------------------------------------------------

## {"kind": "any"} in the any-fan mode; otherwise the closest of {"kind": "suit", "suit"},
## {"kind": "pungs"}, {"kind": "pairs"} for the hand as it is now.
static func choose_plan(game, seat: int) -> Dictionary:
	if game.min_fan <= 0:
		return {"kind": "any"}
	var hand: Array = game.hands[seat]
	var melds: Array = game.melds[seat]
	var best := {"kind": "any"}
	var best_distance := FAR
	var plans: Array = [{"kind": "suit", "suit": 0}, {"kind": "suit", "suit": 1}, {"kind": "suit", "suit": 2}, {"kind": "pungs"}, {"kind": "pairs"}]
	for plan in plans:
		var d := distance(hand, melds, plan) + (PAIRS_PENALTY if str(plan.kind) == "pairs" else 0)
		if d < best_distance:
			best_distance = d
			best = plan
	game.ai_plans[seat] = best
	return best

## How far `hand` (with `melds`) is from a ready hand of `plan`, in shanten-like steps
## (FAR when the melds rule the plan out).
static func distance(hand: Array, melds: Array, plan: Dictionary) -> int:
	match str(plan.kind):
		"suit":
			var s := int(plan.suit)
			for meld in melds:
				if not Rules.is_honor(int(meld.tile)) and Rules.suit(int(meld.tile)) != s:
					return FAR
			return Rules.shanten(Rules.counts(_in_suit(hand, s)), melds.size())
		"pungs":
			var sets := 0
			for meld in melds:
				if str(meld.type) == "chow":
					return FAR
				sets += 1
			var pairs := 0
			for n in Rules.counts(hand):
				if n >= 3:
					sets += 1
				elif n == 2:
					pairs += 1
			var head := 1 if pairs > 0 else 0
			return 8 - 2 * sets - mini(maxi(pairs - head, 0), maxi(4 - sets, 0)) - head
		"pairs":
			if not melds.is_empty() or not bool(Rules.config().get("seven_pairs", true)):
				return FAR
			var pairs := 0
			var kinds := 0
			for n in Rules.counts(hand):
				if n >= 2:
					pairs += 1
				if n >= 1:
					kinds += 1
			return 6 - pairs + maxi(0, 7 - kinds)
	return Rules.shanten(Rules.counts(hand), melds.size())

static func _in_suit(tiles: Array, s: int) -> Array:
	return tiles.filter(func(t: int) -> bool: return Rules.is_honor(t) or Rules.suit(t) == s)

## How much `tile` is worth keeping (higher keeps it), a tie-breaker.
static func _keep_value(game, seat: int, tile: int, rest: Array, plan: Dictionary) -> float:
	var held := rest.count(tile)
	var value := 2.0 * held
	if Rules.is_honor(tile):
		var scoring: bool = Rules.is_dragon(tile) or tile == game.seat_winds[seat] or tile == game.prevailing
		value += (5.0 if scoring else 0.5) * held
	else:
		value += 2.0 - absf(5.0 - Rules.number(tile)) * 0.3   # middle tiles connect more
		for k in [tile - 2, tile - 1, tile + 1, tile + 2]:
			if k >= 0 and not Rules.is_honor(k) and Rules.suit(k) == Rules.suit(tile) and rest.has(k):
				value += 1.5
		if str(plan.kind) == "suit":
			value += 8.0 if Rules.suit(tile) == int(plan.suit) else -8.0
	return value

# --- Claims --------------------------------------------------------------------------------

## The NPC's answer to the last discard, given its options (game.claim_options()).
static func claim_answer(game, seat: int, options: Dictionary) -> Dictionary:
	if options.has("win"):
		return {"type": "win"}
	var tile: int = game.last_discard
	var hand: Array = game.hands[seat]
	var melds: Array = game.melds[seat]
	var plan := choose_plan(game, seat)
	var kind := str(plan.kind)
	if kind == "pairs":
		return {"type": "pass"}
	var fits: bool = kind != "suit" or Rules.is_honor(tile) or Rules.suit(tile) == int(plan.suit)
	var scoring: bool = Rules.is_dragon(tile) or tile == game.seat_winds[seat] or tile == game.prevailing
	var now := _score_of(hand, melds, plan)
	if options.has("kong") and fits:
		return {"type": "kong"}
	if options.has("pung") and fits:
		var rest: Array = hand.duplicate()
		rest.erase(tile)
		rest.erase(tile)
		var after: Array = melds.duplicate()
		after.append({"type": "pung", "tile": tile})
		if scoring or kind == "pungs" or kind == "suit" or _best_after(rest, after, plan) < now:
			return {"type": "pung"}
	if options.has("chows") and fits and kind != "pungs":
		for chow in options.chows:
			var rest: Array = hand.duplicate()
			for k in chow:
				if k != tile:
					rest.erase(k)
			var after: Array = melds.duplicate()
			after.append({"type": "chow", "tile": int(chow[0])})
			if _best_after(rest, after, plan) < now:
				return {"type": "chow", "tile": int(chow[0])}
	return {"type": "pass"}

static func _score_of(hand: Array, melds: Array, plan: Dictionary) -> int:
	return distance(hand, melds, plan) * 10 + Rules.shanten(Rules.counts(hand), melds.size())

## The best _score_of after discarding one tile from `hand` (14-tile equivalent).
static func _best_after(hand: Array, melds: Array, plan: Dictionary) -> int:
	var best := FAR * 100
	var tried := {}
	for tile in hand:
		if tried.has(tile):
			continue
		tried[tile] = true
		var rest: Array = hand.duplicate()
		rest.erase(tile)
		best = mini(best, _score_of(rest, melds, plan))
	return best
