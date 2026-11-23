extends SceneTree
## 9 Nov 2026: Hong Kong mahjong logic (docs/guides/MAHJONG.md), no town.
##   - every hand on the user's "common winning hands" sheet scores its fan (data/mahjong.json),
##     with the wind bonuses (prevailing East, seat wind, both for an East player) and self-draw;
##   - incomplete hands score nothing; shanten -1 / 0 for complete / ready hands;
##   - whole hands played by four NPC players in both modes (3 fan, any fan): tiles are kept
##     (136 in wall, hands, melds and discards), every winner has the mode's minimum fan, every
##     hand ends (win or draw), and the time per NPC decision.
## Writes nothing.  godot --headless --path . --script res://docs/evidence/mahjong-20261109/verify.gd
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const Game := preload("res://scripts/learning/mahjong_game.gd")
const AI := preload("res://scripts/learning/mahjong_ai.gd")
const HANDS_PER_MODE := 60
var failures := 0
var checks := 0

func _initialize() -> void:
	_scoring()
	_shanten()
	_preset()
	_pung_then_win()
	for mode in [3, 0]:
		_play(mode)
	print("MAHJONG: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

# m/p/s/z notation: "123m456p11z" -> kinds (z: 1-4 E S W N, 5-7 red green white).
static func tiles(text: String) -> Array:
	var out: Array = []
	var digits: Array = []
	for ch in text:
		if ch >= "0" and ch <= "9":
			digits.append(int(ch))
			continue
		var base := {"m": 0, "p": 9, "s": 18, "z": 27}[ch] as int
		for d in digits:
			out.append(base + d - 1)
		digits = []
	return out

static func meld(type: String, kind: int) -> Dictionary:
	return {"type": type, "tile": kind, "open": true}

func expect(label: String, hand: String, melds: Array, fan: int, ctx := {}, ids: Array = []) -> void:
	var context := {"seat_wind": Rules.SOUTH, "prevailing": Rules.EAST, "self_drawn": false}
	context.merge(ctx, true)
	var result := Rules.score(tiles(hand), melds, context)
	var names: Array = result.items.map(func(i): return str(i.id))
	check(result.complete and int(result.fan) == fan, "%s: %d fan expected, got %s %s" % [label, fan, result.fan, names])
	for id in ids:
		check(id in names, "%s: missing %s in %s" % [label, id, names])
	print("  %-22s %2d fan  %s" % [label, int(result.fan), names])

func _scoring() -> void:
	print("Sheet hands (seat South, prevailing East, discard win unless noted):")
	expect("1 all chows", "123456m123456p55p", [], 1, {}, ["all_chows"])
	expect("2 all pungs", "222555m222888p11z", [], 3, {}, ["all_pungs"])
	expect("3 mixed one suit", "123456789m111z66z", [], 4, {}, ["mixed_one_suit", "prevailing_wind"])
	expect("4 pure one suit", "123456789234m88m", [], 8, {}, ["pure_one_suit", "all_chows"])
	expect("5 small 3 dragons", "123456m555666z77z", [], 8, {}, ["small_three_dragons", "mixed_one_suit"])
	expect("6 big 3 dragons", "123m555666777z55p", [], 8, {}, ["big_three_dragons"])
	expect("7 small 4 winds", "123m111222333z44z", [], 9, {}, ["small_four_winds", "mixed_one_suit"])
	expect("8 big 4 winds", "111222333444z66z", [], 13, {}, ["big_four_winds"])
	expect("9 all honors", "111222555666z77z", [], 13, {}, ["all_honors"])
	expect("10 thirteen orphans", "19m19p19s12345677z", [], 13, {}, ["thirteen_orphans"])
	expect("11 four kongs", "22m", [meld("kong", Rules.RED), meld("kong", Rules.GREEN), meld("kong", Rules.EAST), meld("kong", 9)], 13, {}, ["four_kongs"])
	expect("12 seven pairs (a limit hand)", "1133m1199p5566s77z", [], Rules.limit_fan(), {}, ["seven_pairs"])
	print("Bonuses:")
	expect("self-drawn chows", "123456m123456p55p", [], 2, {"self_drawn": true}, ["all_chows", "self_drawn"])
	expect("East seat EEE", "123m456p789s111z55s", [], 2, {"seat_wind": Rules.EAST}, ["prevailing_wind", "seat_wind"])
	expect("seat wind only", "123m456p789s222z55s", [], 1, {}, ["seat_wind"])
	expect("dragon pung", "123m456p789s555z55s", [], 1, {}, ["dragon_pung"])
	expect("chicken hand", "123m456p789s999s55s", [], 0)
	expect("exposed melds", "123m55s", [meld("pung", Rules.RED), meld("chow", 9), meld("pung", Rules.SOUTH)], 2, {}, ["dragon_pung", "seat_wind"])
	expect("best split", "111222333m44455m", [], 10, {}, ["pure_one_suit", "all_pungs"])
	var broken := Rules.score(tiles("123456m123456p59p"), [], {})
	check(not broken.complete, "an incomplete hand is not complete")
	check(not Rules.is_seven_pairs(Rules.counts(tiles("1111m3344p5566s77z"))), "four of a kind is not two pairs")

func _shanten() -> void:
	check(Rules.shanten(Rules.counts(tiles("123456m123456p55p")), 0) == -1, "shanten of a complete hand is -1")
	check(Rules.shanten(Rules.counts(tiles("123456m123456p5p")), 0) == 0, "shanten of a ready hand is 0")
	check(Rules.shanten(Rules.counts(tiles("123m55s")), 3) == -1, "shanten counts melds")
	check(Rules.shanten(Rules.counts(tiles("1133m1199p5566s7z")), 0) == 0, "seven pairs ready")

func _play(mode: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109 + mode
	var wins := 0
	var draws := 0
	var decisions := 0
	var usec := 0
	var slowest := 0
	var fan_seen: Array = []
	var hands_seen: Dictionary = {}
	for hand in HANDS_PER_MODE:
		var game := Game.new()
		game.start(rng, hand % 4, mode)
		var guard := 0
		while game.phase != "over" and guard < 2000:
			guard += 1
			var start := Time.get_ticks_usec()
			if game.phase == "turn":
				var seat: int = game.turn
				var action := AI.turn_action(game, seat)
				match str(action.type):
					"win": game.declare_self_win(seat)
					"kong": game.declare_kong(seat, int(action.tile))
					_: check(game.discard(seat, int(action.tile)), "discard accepted")
			elif game.phase == "claim":
				for seat in game.waiting.keys():
					game.respond(seat, AI.claim_answer(game, seat, game.waiting[seat]))
			var spent := Time.get_ticks_usec() - start
			usec += spent
			slowest = maxi(slowest, spent)
			decisions += 1
			if game.phase != "over":
				_conserved(game)
		check(game.phase == "over", "mode %d hand %d ends" % [mode, hand])
		var winner := int(game.result.get("winner", -1))
		if winner >= 0:
			wins += 1
			var fan := int(game.result.score.fan)
			fan_seen.append(fan)
			check(fan >= mode, "mode %d winner has %d fan" % [mode, fan])
			for item in game.result.score.items:
				hands_seen[str(item.id)] = int(hands_seen.get(str(item.id), 0)) + 1
		else:
			draws += 1
			check(game.wall_left() == 0, "a draw happens only with an empty wall")
	print("Mode %d: %d hands, %d wins, %d draws, fan %s; %d decisions, %.2f ms average, %.1f ms slowest" % [mode, HANDS_PER_MODE, wins, draws, fan_seen, decisions, usec / 1000.0 / maxi(decisions, 1), slowest / 1000.0])
	print("  scoring items: %s" % [hands_seen])
	check(wins > 0, "mode %d: somebody wins" % mode)

## 23 Nov 2026 (user): a pung (or chow) of a discard that completes the hand still offers
## Mahjong on the claimer's turn; it is a win on that discard, paid by the discarder.
func _pung_then_win() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261123
	var game := Game.new()
	game.start(rng, 0, 0)
	var five_s: int = tiles("5s")[0]
	game.hands[0] = tiles("123m456m789m11p55s")
	game.hands[3].append(five_s)
	game.turn = 3
	game.phase = "turn"
	game.discard(3, five_s)
	check(game.phase == "claim" and game.waiting.get(0, {}).has("win") and game.waiting.get(0, {}).has("pung"), "pung then win: the 5s offers both Mahjong and pung")
	for seat in game.waiting.keys():
		game.respond(seat, {"type": "pung"} if seat == 0 else {"type": "pass"})
	check(game.phase == "turn" and game.turn == 0, "pung then win: the player's turn after the pung")
	check(game.can_self_win(0), "pung then win: Mahjong still offered after the pung")
	game.declare_self_win(0)
	check(game.phase == "over" and int(game.result.winner) == 0 and int(game.result.from) == 3 and not game.result.self_drawn, "pung then win: a win on seat 3's discard (%s)" % [game.result])
	# Not on a later turn: after a discard the claim is gone.
	var plain := Game.new()
	plain.start(rng, 0, 0)
	check(plain.claimed_from == -1, "pung then win: no claim at the start of a hand")

## The preset game on the table before anyone sits (data/mahjong.json "preset").
func _preset() -> void:
	var game = Game.new()
	var preset: Dictionary = Rules.config().get("preset", {})
	checks += 1
	var counts := {}
	for seat in 4:
		for kind in Array(preset.hands[seat]) + Array(preset.discards[seat]):
			counts[int(kind)] = int(counts.get(int(kind), 0)) + 1
		for meld in preset.melds[seat]:
			for kind in Rules.meld_tiles({"type": str(meld.type), "tile": int(meld.tile)}):
				counts[kind] = int(counts.get(kind, 0)) + 1
	for kind in counts:
		if counts[kind] > 4:
			failures += 1
			print("FAIL: preset uses tile %d %d times" % [kind, counts[kind]])
	game.load_preset(preset)
	_conserved(game)
	checks += 1
	if game.drawn_front != 79 or game.hands[0].size() + 3 * game.melds[0].size() != 14:
		failures += 1
		print("FAIL: preset: 79 tiles out of the wall and Mei holding 14 (%d, %d)" % [game.drawn_front, game.hands[0].size()])

func _conserved(game) -> void:
	var total: int = game.wall.size()
	for seat in 4:
		total += game.hands[seat].size() + game.discards[seat].size()
		for m in game.melds[seat]:
			total += Rules.meld_tiles(m).size()
	checks += 1
	if total != 136:
		failures += 1
		print("FAIL: tiles conserved (%d)" % total)
