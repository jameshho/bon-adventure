extends RefCounted
## One hand of Hong Kong mahjong without any nodes (docs/guides/MAHJONG.md): the wall, four seats,
## turns, claims and the result. The session (mahjong_session.gd) drives it: it asks the NPC
## players (mahjong_ai.gd) or the player what to do and calls the actions below; `changed` is
## emitted after every action so the table view and panel redraw. The logic check plays whole
## hands with four NPC players.
##
## Seats: 0 is the player; play passes to seat + 1 (the player on your right, counter-clockwise
## round the table as in a real game). The dealer is East; the prevailing wind is East (one
## hand per game, user decision 9 Nov 2026). A chow may only be claimed by the next seat; a
## pung, kong or win by anyone; a win beats a pung or kong, which beats a chow; two winners:
## the first in turn order after the discarder. A kong draws a replacement from the back of the
## wall. The hand is a draw when the wall is empty. A win needs at least `min_fan` fan (3 or 0,
## the mode the player chose).
##
## Phases: "turn" (seat `turn` holds 14 tiles, counting melds as 3: it may win, declare a kong
## or must discard), "claim" (the others answer the last discard with respond()), "over".
const Rules := preload("res://scripts/learning/mahjong_rules.gd")

signal changed

var min_fan := 3
var prevailing := Rules.EAST
var dealer := 0
## Remaining wall, in drawing order (front = next draw, back = kong replacements).
var wall: Array = []
## How many tiles left the front and the back of the wall (the table view hides those stacks).
var drawn_front := 0
var drawn_back := 0
var hands: Array = [[], [], [], []]
var melds: Array = [[], [], [], []]
var discards: Array = [[], [], [], []]
var seat_winds: Array = [0, 0, 0, 0]
var turn := 0
var phase := ""
## The tile seat `turn` just drew (-1 after a claim).
var drawn := -1
## After a pung or chow of a discard that completes the hand: the discarder and the tile (user,
## 23 Nov 2026: a player may pung first and still call Mahjong instead of discarding; it scores
## as a win on that discard, paid by its discarder). -1 otherwise.
var claimed_from := -1
var claimed_tile := -1
var last_discard := -1
var last_from := -1
## seat -> its claim options (claim_options()) while phase is "claim"; answered seats leave.
var waiting: Dictionary = {}
var answers: Dictionary = {}
## The last call made (for the speech bubble): {"seat", "type"} or {}.
var last_call: Dictionary = {}
## {"winner": seat or -1, "from": discarder or -1, "self_drawn", "score", "tile"} once over.
var result: Dictionary = {}
var turns_played := 0
## The plan each NPC chose on its last decision (mahjong_ai.gd; for checks and debugging).
var ai_plans: Dictionary = {}

func start(rng: RandomNumberGenerator, dealer_seat: int, minimum_fan: int) -> void:
	min_fan = minimum_fan
	dealer = dealer_seat
	wall = Rules.new_wall(rng)
	drawn_front = 0
	drawn_back = 0
	for seat in 4:
		hands[seat] = []
		melds[seat] = []
		discards[seat] = []
		seat_winds[seat] = Rules.EAST + (seat - dealer + 4) % 4
	for round in 13:
		for offset in 4:
			hands[(dealer + offset) % 4].append(_take_front())
	for seat in 4:
		hands[seat].sort()
	result = {}
	last_call = {}
	last_discard = -1
	last_from = -1
	turns_played = 0
	ai_plans = {}
	turn = dealer
	_draw(dealer, false)

## The game in progress shown on the table before the player sits down (user, 9 Nov 2026):
## data/mahjong.json "preset", laid out from the user's screenshot. Only for show: nobody plays
## it, and sitting down deals a fresh hand. The wall is what is left of the 136 tiles.
func load_preset(preset: Dictionary) -> void:
	min_fan = 0
	dealer = int(preset.dealer)
	var left := {}
	for kind in Rules.KINDS:
		left[kind] = 4
	for seat in 4:
		hands[seat] = Array(preset.hands[seat]).map(func(k) -> int: return int(k))
		melds[seat] = Array(preset.melds[seat]).map(func(m) -> Dictionary: return {"type": str(m.type), "tile": int(m.tile), "open": bool(m.get("open", true))})
		discards[seat] = Array(preset.discards[seat]).map(func(k) -> int: return int(k))
		seat_winds[seat] = Rules.EAST + (seat - dealer + 4) % 4
		for kind in hands[seat] + discards[seat]:
			left[kind] -= 1
		for meld in melds[seat]:
			for kind in Rules.meld_tiles(meld):
				left[kind] -= 1
	wall = []
	for kind in Rules.KINDS:
		for i in maxi(int(left[kind]), 0):
			wall.append(kind)
	drawn_front = 136 - wall.size()
	drawn_back = 0
	turn = int(preset.turn)
	drawn = int(preset.get("drawn", -1))
	claimed_from = -1
	claimed_tile = -1
	phase = "turn"
	last_discard = -1
	last_from = -1
	result = {}

func _take_front() -> int:
	drawn_front += 1
	return wall.pop_front()

func _take_back() -> int:
	drawn_back += 1
	return wall.pop_back()

func wall_left() -> int:
	return wall.size()

## Draws for `seat` (the back of the wall for a kong); an empty wall ends the hand in a draw.
func _draw(seat: int, replacement: bool) -> void:
	if wall.is_empty():
		_finish({"winner": -1, "from": -1, "self_drawn": false, "score": {}, "tile": -1})
		return
	turn = seat
	claimed_from = -1
	claimed_tile = -1
	drawn = _take_back() if replacement else _take_front()
	hands[seat].append(drawn)
	hands[seat].sort()
	phase = "turn"
	waiting = {}
	changed.emit()

func _finish(how: Dictionary) -> void:
	result = how
	phase = "over"
	waiting = {}
	changed.emit()

func context(seat: int, self_drawn: bool) -> Dictionary:
	return {"seat_wind": seat_winds[seat], "prevailing": prevailing, "self_drawn": self_drawn}

# --- The seat whose turn it is ----------------------------------------------------------

## The score if `seat` declared a win now on its turn ({} when its hand is not complete): a
## self-drawn win after a draw, or a win on the claimed discard straight after a pung or chow.
func self_win_score(seat: int) -> Dictionary:
	if phase != "turn" or seat != turn:
		return {}
	if drawn < 0 and claimed_from < 0:
		return {}
	var scored := Rules.score(hands[seat], melds[seat], context(seat, drawn >= 0))
	return scored if scored.complete else {}

func can_self_win(seat: int) -> bool:
	var scored := self_win_score(seat)
	return not scored.is_empty() and int(scored.fan) >= min_fan

## Kinds `seat` can make a kong of now: four in hand, or the fourth of an exposed pung.
func kong_options(seat: int) -> Array:
	if phase != "turn" or seat != turn or wall.is_empty():
		return []
	var found: Array = []
	var c := Rules.counts(hands[seat])
	for kind in Rules.KINDS:
		if c[kind] == 4:
			found.append(kind)
	for meld in melds[seat]:
		if str(meld.type) == "pung" and c[int(meld.tile)] > 0:
			found.append(int(meld.tile))
	return found

func declare_self_win(seat: int) -> bool:
	if not can_self_win(seat):
		return false
	if drawn < 0:
		# Mahjong after the pung or chow: a win on that discard.
		last_call = {"seat": seat, "type": "win"}
		_finish({"winner": seat, "from": claimed_from, "self_drawn": false, "score": self_win_score(seat), "tile": claimed_tile})
		return true
	last_call = {"seat": seat, "type": "self_win"}
	_finish({"winner": seat, "from": -1, "self_drawn": true, "score": self_win_score(seat), "tile": drawn})
	return true

func declare_kong(seat: int, kind: int) -> bool:
	if not kind in kong_options(seat):
		return false
	var added := false
	for meld in melds[seat]:
		if str(meld.type) == "pung" and int(meld.tile) == kind:
			meld.type = "kong"
			hands[seat].erase(kind)
			added = true
			break
	if not added:
		for i in 4:
			hands[seat].erase(kind)
		melds[seat].append({"type": "kong", "tile": kind, "open": false, "from": -1})
	last_call = {"seat": seat, "type": "kong"}
	_draw(seat, true)
	return true

func discard(seat: int, tile: int) -> bool:
	if phase != "turn" or seat != turn or not hands[seat].has(tile):
		return false
	hands[seat].erase(tile)
	discards[seat].append(tile)
	last_discard = tile
	last_from = seat
	drawn = -1
	claimed_from = -1
	claimed_tile = -1
	turns_played += 1
	last_call = {}
	answers = {}
	waiting = {}
	for offset in range(1, 4):
		var other := (seat + offset) % 4
		var options := claim_options(other)
		if not options.is_empty():
			waiting[other] = options
	phase = "claim"
	changed.emit()
	if waiting.is_empty():
		_next_turn()
	return true

# --- Claims ------------------------------------------------------------------------------

## What `seat` may do with the last discard: {"win": score, "pung": true, "kong": true,
## "chows": [[a, b, c] lowest first]}; {} for nothing.
func claim_options(seat: int) -> Dictionary:
	if seat == last_from or last_discard < 0:
		return {}
	var tile := last_discard
	var options := {}
	var with_tile: Array = hands[seat].duplicate()
	with_tile.append(tile)
	var scored := Rules.score(with_tile, melds[seat], context(seat, false))
	if scored.complete and int(scored.fan) >= min_fan:
		options["win"] = scored
	var held: int = hands[seat].count(tile)
	if held >= 2:
		options["pung"] = true
	if held >= 3 and not wall.is_empty():
		options["kong"] = true
	if seat == (last_from + 1) % 4 and not Rules.is_honor(tile):
		var chows: Array = []
		for low in range(tile - 2, tile + 1):
			if low < 0 or Rules.suit(low) != Rules.suit(tile) or low % 9 > 6:
				continue
			var ok := true
			for k in [low, low + 1, low + 2]:
				if k != tile and not hands[seat].has(k):
					ok = false
			if ok:
				chows.append([low, low + 1, low + 2])
		if not chows.is_empty():
			options["chows"] = chows
	return options

## `seat`'s answer to the last discard: {"type": "pass" | "win" | "pung" | "kong" | "chow",
## "tile": lowest kind of the chow}. The claim resolves once every waiting seat answered.
func respond(seat: int, answer: Dictionary) -> void:
	if phase != "claim" or not waiting.has(seat):
		return
	answers[seat] = answer
	waiting.erase(seat)
	if waiting.is_empty():
		_resolve()

func _resolve() -> void:
	var order: Array = []
	for offset in range(1, 4):
		order.append((last_from + offset) % 4)
	for type in ["win", "kong", "pung", "chow"]:
		for seat in order:
			var answer: Dictionary = answers.get(seat, {})
			if str(answer.get("type", "pass")) == type:
				_claim(seat, answer)
				return
	_next_turn()

func _claim(seat: int, answer: Dictionary) -> void:
	var tile := last_discard
	discards[last_from].pop_back()
	var type := str(answer.type)
	last_call = {"seat": seat, "type": type}
	match type:
		"win":
			hands[seat].append(tile)
			hands[seat].sort()
			var scored := Rules.score(hands[seat], melds[seat], context(seat, false))
			_finish({"winner": seat, "from": last_from, "self_drawn": false, "score": scored, "tile": tile})
			return
		"kong":
			for i in 3:
				hands[seat].erase(tile)
			melds[seat].append({"type": "kong", "tile": tile, "open": true, "from": last_from})
			_draw(seat, true)
			return
		"pung":
			for i in 2:
				hands[seat].erase(tile)
			melds[seat].append({"type": "pung", "tile": tile, "open": true, "from": last_from})
		"chow":
			var low := int(answer.tile)
			for k in [low, low + 1, low + 2]:
				if k != tile:
					hands[seat].erase(k)
			melds[seat].append({"type": "chow", "tile": low, "open": true, "from": last_from, "claimed": tile})
	claimed_from = last_from
	claimed_tile = tile
	last_discard = -1
	turn = seat
	drawn = -1
	phase = "turn"
	waiting = {}
	changed.emit()

func _next_turn() -> void:
	last_discard = -1
	_draw((last_from + 1) % 4, false)
