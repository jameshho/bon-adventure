extends RefCounted
## Hong Kong mahjong rules without any nodes (docs/guides/MAHJONG.md): the 136 tiles, complete hands,
## fan scoring and shanten (how far a hand is from ready, for the NPC players). Fan values and
## the limit come from data/mahjong.json. Used by mahjong_game.gd, mahjong_ai.gd and the
## logic check (docs/evidence/mahjong-20261109/verify.gd).
##
## A tile is an int kind 0..33: 0-8 characters (萬) 1-9, 9-17 dots (筒) 1-9, 18-26 bamboo (索)
## 1-9, 27-30 the winds East South West North, 31-33 the dragons red (中), green (發) and white
## (白). A meld is {"type": "chow" | "pung" | "kong", "tile": lowest kind, "open": bool}; a
## chow's tiles are tile, tile+1, tile+2.
const DATA := "res://data/mahjong.json"
const KINDS := 34
const EAST := 27
const SOUTH := 28
const WEST := 29
const NORTH := 30
const RED := 31
const GREEN := 32
const WHITE := 33
const TERMINALS_AND_HONORS := [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33]

static var _config: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		var text := FileAccess.get_file_as_string(DATA)
		var parsed: Variant = JSON.parse_string(text)
		_config = parsed if parsed is Dictionary else {}
	return _config

static func fan_value(id: String) -> int:
	return int(config().get("fan", {}).get(id, 0))

static func limit_fan() -> int:
	return int(config().get("limit_fan", 13))

# --- Points (data/mahjong.json "points"; the lessons' table and the session scoreboard) ------

## Points for a hand of `fan`; a hand under min_fan pays as min_fan.
static func points_for(fan: int) -> int:
	var points: Dictionary = config().get("points", {})
	var counted := maxi(fan, int(points.get("min_fan", 1)))
	var best := 0
	for row in points.get("table", []):
		if int(row[0]) <= counted:
			best = int(row[1])
	return best

## Each seat's balance after `hands` ([{"winner", "from" (-1 self-drawn), "fan"}]): the
## discarder pays discard_pays times the points; on a self-drawn win every other seat pays once.
static func balances(hands: Array) -> Array:
	var money := [0, 0, 0, 0]
	var discard_pays := int(config().get("points", {}).get("discard_pays", 1))
	for hand in hands:
		var winner := int(hand.winner)
		var points := points_for(int(hand.fan))
		if int(hand.from) < 0:
			for seat in 4:
				if seat != winner:
					money[seat] -= points
					money[winner] += points
		else:
			money[int(hand.from)] -= points * discard_pays
			money[winner] += points * discard_pays
	return money

# --- Tiles --------------------------------------------------------------------------------

## 0 characters, 1 dots, 2 bamboo, -1 honor.
static func suit(tile: int) -> int:
	return tile / 9 if tile < 27 else -1

## 1..9 for suit tiles, 0 for honors.
static func number(tile: int) -> int:
	return tile % 9 + 1 if tile < 27 else 0

static func is_honor(tile: int) -> bool:
	return tile >= 27

static func is_wind(tile: int) -> bool:
	return tile >= EAST and tile <= NORTH

static func is_dragon(tile: int) -> bool:
	return tile >= RED

static func is_terminal_or_honor(tile: int) -> bool:
	return tile >= 27 or tile % 9 == 0 or tile % 9 == 8

## All 136 tiles (four of each kind), shuffled with `rng`.
static func new_wall(rng: RandomNumberGenerator) -> Array:
	var tiles: Array = []
	for kind in KINDS:
		for copy in 4:
			tiles.append(kind)
	for i in range(tiles.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: int = tiles[i]
		tiles[i] = tiles[j]
		tiles[j] = swap
	return tiles

static func counts(tiles: Array) -> Array:
	var result: Array = []
	result.resize(KINDS)
	result.fill(0)
	for tile in tiles:
		result[tile] += 1
	return result

static func meld_tiles(meld: Dictionary) -> Array:
	var tile := int(meld.tile)
	match str(meld.type):
		"chow": return [tile, tile + 1, tile + 2]
		"kong": return [tile, tile, tile, tile]
	return [tile, tile, tile]

# --- Complete hands -----------------------------------------------------------------------

## Every way to split `concealed` (counts; 3n+2 tiles) into sets and one pair:
## [{"pair": kind, "sets": [{"type", "tile"}]}].
static func decompositions(concealed: Array) -> Array:
	var found: Array = []
	var total := 0
	for n in concealed:
		total += n
	if total % 3 != 2:
		return found
	var c := concealed.duplicate()
	for pair in KINDS:
		if c[pair] < 2:
			continue
		c[pair] -= 2
		var sets_found: Array = []
		_sets(c, 0, [], sets_found)
		for sets in sets_found:
			found.append({"pair": pair, "sets": sets})
		c[pair] += 2
	return found

static func _sets(c: Array, start: int, current: Array, found: Array) -> void:
	var i := start
	while i < KINDS and c[i] == 0:
		i += 1
	if i == KINDS:
		found.append(current.duplicate())
		return
	if c[i] >= 3:
		c[i] -= 3
		current.append({"type": "pung", "tile": i})
		_sets(c, i, current, found)
		current.pop_back()
		c[i] += 3
	if i < 27 and i % 9 <= 6 and c[i + 1] > 0 and c[i + 2] > 0:
		c[i] -= 1
		c[i + 1] -= 1
		c[i + 2] -= 1
		current.append({"type": "chow", "tile": i})
		_sets(c, i, current, found)
		current.pop_back()
		c[i] += 1
		c[i + 1] += 1
		c[i + 2] += 1

static func is_seven_pairs(concealed: Array) -> bool:
	if not bool(config().get("seven_pairs", true)):
		return false
	var pairs := 0
	for n in concealed:
		if n == 2:
			pairs += 1
		elif n != 0:
			return false
	return pairs == 7

static func is_thirteen_orphans(concealed: Array) -> bool:
	var total := 0
	for kind in KINDS:
		var n: int = concealed[kind]
		total += n
		if n > 0 and not kind in TERMINALS_AND_HONORS:
			return false
	if total != 14:
		return false
	for kind in TERMINALS_AND_HONORS:
		if concealed[kind] == 0:
			return false
	return true

## True when `concealed` (counts) with `meld_count` melds is a winning shape (fan aside).
static func is_complete(concealed: Array, meld_count: int) -> bool:
	if meld_count == 0 and (is_seven_pairs(concealed) or is_thirteen_orphans(concealed)):
		return true
	return not decompositions(concealed).is_empty()

# --- Scoring ------------------------------------------------------------------------------

## The best score of a complete hand. `concealed`: tiles in hand including the winning tile;
## `melds`: exposed (and concealed kong) melds; `context`: {"seat_wind", "prevailing",
## "self_drawn"}. Returns {"complete": bool, "fan": int, "limit": bool, "items": [{"id", "fan"}]}
## (items name the hands for data/phrases.json "mahjong.hand_<id>").
static func score(concealed: Array, melds: Array, context: Dictionary) -> Dictionary:
	var c := counts(concealed)
	var best := {"complete": false, "fan": -1, "limit": false, "items": []}
	if melds.is_empty():
		if is_thirteen_orphans(c):
			return _limit("thirteen_orphans")
		if is_seven_pairs(c):
			# A limit hand when data/mahjong.json lists it (user, 9 Nov 2026), else scored by fan.
			if Array(config().get("limit_hands", [])).has("seven_pairs"):
				best = _better(best, _limit("seven_pairs"))
			else:
				best = _better(best, _score_pairs(c, context))
	for split in decompositions(c):
		var sets: Array = melds.duplicate()
		sets.append_array(split.sets)
		best = _better(best, _score_sets(sets, int(split.pair), context))
	if best.fan < 0:
		return {"complete": false, "fan": 0, "limit": false, "items": []}
	return best

static func _better(a: Dictionary, b: Dictionary) -> Dictionary:
	return b if int(b.fan) > int(a.fan) else a

static func _limit(id: String) -> Dictionary:
	return {"complete": true, "fan": limit_fan(), "limit": true, "items": [{"id": id, "fan": limit_fan()}]}

static func _finish(items: Array) -> Dictionary:
	var total := 0
	for item in items:
		total += int(item.fan)
	return {"complete": true, "fan": mini(total, limit_fan()), "limit": false, "items": items}

static func _add(items: Array, id: String, times: int = 1) -> void:
	var value := fan_value(id) * times
	if value > 0:
		items.append({"id": id, "fan": value})

## Suits used by `tiles` and whether honors are among them: [suit set, has_honor].
static func _suits(tiles: Array) -> Array:
	var used := {}
	var honors := false
	for tile in tiles:
		if is_honor(tile):
			honors = true
		else:
			used[suit(tile)] = true
	return [used, honors]

static func _suit_items(tiles: Array, items: Array) -> bool:
	var info := _suits(tiles)
	var used: Dictionary = info[0]
	if used.is_empty():
		return true   # all honors (a limit hand)
	if used.size() == 1:
		_add(items, "mixed_one_suit" if info[1] else "pure_one_suit")
	return false

static func _score_pairs(c: Array, context: Dictionary) -> Dictionary:
	var tiles: Array = []
	for kind in KINDS:
		for n in c[kind]:
			tiles.append(kind)
	var items: Array = []
	_add(items, "seven_pairs")
	if _suit_items(tiles, items):
		return _limit("all_honors")
	if context.get("self_drawn", false):
		_add(items, "self_drawn")
	return _finish(items)

static func _score_sets(sets: Array, pair: int, context: Dictionary) -> Dictionary:
	var tiles: Array = [pair, pair]
	var pungs: Array = []
	var chows := 0
	var kongs := 0
	for set in sets:
		tiles.append_array(meld_tiles(set))
		if str(set.type) == "chow":
			chows += 1
		else:
			pungs.append(int(set.tile))
			if str(set.type) == "kong":
				kongs += 1
	var wind_pungs := pungs.filter(func(t: int) -> bool: return is_wind(t))
	var dragon_pungs := pungs.filter(func(t: int) -> bool: return is_dragon(t))
	if wind_pungs.size() == 4:
		return _limit("big_four_winds")
	if kongs == 4:
		return _limit("four_kongs")
	var items: Array = []
	if _suit_items(tiles, items):
		return _limit("all_honors")
	if chows == 0:
		_add(items, "all_pungs")
	elif chows == 4:
		_add(items, "all_chows")
	if dragon_pungs.size() == 3:
		_add(items, "big_three_dragons")
	elif dragon_pungs.size() == 2 and is_dragon(pair):
		_add(items, "small_three_dragons")
	else:
		_add(items, "dragon_pung", dragon_pungs.size())
	if wind_pungs.size() == 3 and is_wind(pair):
		_add(items, "small_four_winds")
	else:
		var prevailing := int(context.get("prevailing", EAST))
		var seat := int(context.get("seat_wind", -1))
		for wind in wind_pungs:
			if wind == prevailing:
				_add(items, "prevailing_wind")
			if wind == seat:
				_add(items, "seat_wind")
	if context.get("self_drawn", false):
		_add(items, "self_drawn")
	return _finish(items)

# --- Shanten (the NPC players) ------------------------------------------------------------

## How many tiles `concealed` (counts) is from ready, with `meld_count` melds already made:
## -1 complete, 0 ready (one tile from winning). Standard shape and, with no melds, seven pairs.
static func shanten(concealed: Array, meld_count: int) -> int:
	var c := concealed.duplicate()
	var state := {"best": 8}
	_scan(c, 0, meld_count, 0, false, state)
	var best: int = state.best
	if meld_count == 0 and bool(config().get("seven_pairs", true)):
		var pairs := 0
		var kinds := 0
		for n in concealed:
			if n >= 2:
				pairs += 1
			if n >= 1:
				kinds += 1
		best = mini(best, 6 - pairs + maxi(0, 7 - kinds))
	return best

static func _scan(c: Array, start: int, sets: int, partials: int, pair: bool, state: Dictionary) -> void:
	var i := start
	while i < KINDS and c[i] == 0:
		i += 1
	if i == KINDS:
		var used := mini(partials, 4 - sets)
		state.best = mini(int(state.best), 8 - 2 * sets - used - (1 if pair else 0))
		return
	if c[i] >= 3:
		c[i] -= 3
		_scan(c, i, sets + 1, partials, pair, state)
		c[i] += 3
	if i < 27 and i % 9 <= 6 and c[i + 1] > 0 and c[i + 2] > 0:
		c[i] -= 1
		c[i + 1] -= 1
		c[i + 2] -= 1
		_scan(c, i, sets + 1, partials, pair, state)
		c[i] += 1
		c[i + 1] += 1
		c[i + 2] += 1
	if c[i] >= 2:
		c[i] -= 2
		if not pair:
			_scan(c, i, sets, partials, true, state)
		if sets + partials < 4:
			_scan(c, i, sets, partials + 1, pair, state)
		c[i] += 2
	if sets + partials < 4 and i < 27:
		if i % 9 <= 7 and c[i + 1] > 0:
			c[i] -= 1
			c[i + 1] -= 1
			_scan(c, i, sets, partials + 1, pair, state)
			c[i] += 1
			c[i + 1] += 1
		if i % 9 <= 6 and c[i + 2] > 0:
			c[i] -= 1
			c[i + 2] -= 1
			_scan(c, i, sets, partials + 1, pair, state)
			c[i] += 1
			c[i + 2] += 1
	c[i] -= 1
	_scan(c, i + 1 if c[i] == 0 else i, sets, partials, pair, state)
	c[i] += 1
