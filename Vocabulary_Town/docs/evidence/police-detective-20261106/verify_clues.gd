extends SceneTree
## 6 Nov 2026: the detective games' round generator (scripts/learning/detective_clues.gd).
## Generates many random rounds of each game and checks every one is solvable, unambiguous
## and consistent; prints how evenly clues and answer positions are spread. The evidence part
## follows the 8 Nov 2026 redesign (one deciding property word, find and report rounds;
## _check_evidence()). No town, no saves:
## godot --headless --path . --script res://docs/evidence/police-detective-20261106/verify_clues.gd
const Clues := preload("res://scripts/learning/detective_clues.gd")
const ROUNDS := 4000
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 20:
			print("FAIL: ", label)

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261106
	_check_evidence(rng)
	for game in ["lineup"]:
		var clues := Clues.new()
		var usage := {}
		var positions := {}
		var previous: Array = []
		var overlap := 0
		var distractors := 0
		var instructions := 0
		var touch_or_listen := 0
		for n in ROUNDS:
			if n % 4 == 0:
				clues.reset()
				previous = []
			var round: Dictionary = clues.generate_lineup(rng) if game == "lineup" else clues.generate_evidence(rng)
			check(not round.is_empty(), "%s round %d generated" % [game, n])
			if round.is_empty():
				continue
			var problem := Clues.validate(round)
			check(problem == "", "%s round %d: %s" % [game, n, problem])
			check(round.clues.size() == 2, "%s round %d has 2 clues" % [game, n])
			var ids: Array = round.clues.map(func(c): return str(c.id))
			ids.sort()
			check(ids != previous, "%s round %d repeats the previous clues %s" % [game, n, ids])
			previous = ids
			var keys: Array = round.clues.map(func(c): return str(c.get("attr", c.get("dim", ""))))
			check(keys[0] != keys[1], "%s round %d: two clues on one property" % [game, n])
			positions[int(round.target)] = int(positions.get(int(round.target), 0)) + 1
			for clue in round.clues:
				usage[clue.id] = int(usage.get(clue.id, 0)) + 1
				if str(clue.get("tool", "look")) != "look":
					touch_or_listen += 1
			if str(round.instruction) != "":
				instructions += 1
				check(round.clues.any(func(c): return str(c.tool) == str(round.instruction)), "%s round %d: instruction tool is needed" % [game, n])
			for i in round.candidates.size():
				if i == int(round.target):
					continue
				distractors += 1
				var fits := 0
				for clue in round.clues:
					if Clues.matches(round.candidates[i], clue):
						fits += 1
				if fits > 0:
					overlap += 1
				check(not Clues.failing_clue(round.candidates[i], round.clues).is_empty(), "%s round %d: distractor %d has a failing clue" % [game, n, i])
			check(Clues.failing_clue(round.candidates[round.target], round.clues).is_empty(), "%s round %d: target fits" % [game, n])
		var all_ids: Array = []
		for clue in clues.data[game].clues:
			all_ids.append(str(clue.id))
		var unused := all_ids.filter(func(id): return not usage.has(id))
		print("%s: %d rounds; answer positions %s; distractors sharing a clue %d%%; clue uses min %d max %d; unused clues %s; instructions %d; touch/listen clues %d" % [game, ROUNDS, positions, 100 * overlap / maxi(distractors, 1), usage.values().min(), usage.values().max(), unused, instructions, touch_or_listen])
		check(unused.is_empty(), "%s: every clue is used" % game)
		check(float(overlap) / distractors > 0.6, "%s: most distractors share a clue" % game)
	print("detective clue checks: ", checks, " failures: ", failures)
	quit(1 if failures > 0 else 0)

## Evidence (8 Nov 2026): rounds alternate find / report as data "rounds" says; each has one
## clue, every candidate shows its property, a find table has exactly one object with the
## value and three with the opposite, a report round has one object and the clue and its
## opposite as answers. Consecutive rounds never repeat a clue, every clue is used about
## equally, and every object kind appears.
func _check_evidence(rng: RandomNumberGenerator) -> void:
	var clues := Clues.new()
	var usage := {}
	var positions := {}
	var kinds := {}
	var types := {}
	var previous := ""
	for n in ROUNDS:
		if n % 4 == 0:
			clues.reset()
			previous = ""
		var type := clues.round_type(n % 4)
		var round: Dictionary = clues.generate_evidence(rng, type)
		check(not round.is_empty(), "evidence round %d generated" % n)
		if round.is_empty():
			continue
		check(Clues.validate(round) == "", "evidence round %d: %s" % [n, Clues.validate(round)])
		check(round.clues.size() == 1 and str(round.type) == type, "evidence round %d: one clue, type %s" % [n, type])
		var clue: Dictionary = round.clues[0]
		check(str(clue.id) != previous, "evidence round %d repeats the previous clue %s" % [n, clue.id])
		previous = str(clue.id)
		usage[clue.id] = int(usage.get(clue.id, 0)) + 1
		types[type] = int(types.get(type, 0)) + 1
		var other := clues.opposite(clue)
		for i in round.candidates.size():
			var item: Dictionary = round.candidates[i]
			kinds[item.kind] = int(kinds.get(item.kind, 0)) + 1
			var value := str(item.get(str(clue.dim), ""))
			if i == int(round.target):
				check(value == str(clue.value), "evidence round %d: the target is %s" % [n, clue.value])
			else:
				check(value == str(other.value), "evidence round %d: distractor %d is %s, not %s" % [n, i, other.value, value])
		if type == "find":
			check(round.candidates.size() == 4, "evidence round %d: four objects" % n)
			positions[int(round.target)] = int(positions.get(int(round.target), 0)) + 1
		else:
			check(round.candidates.size() == 1 and round.options.size() == 2, "evidence round %d: one object, two answers" % n)
	var all_ids: Array = clues.data.evidence.clues.map(func(c): return str(c.id))
	var unused := all_ids.filter(func(id): return not usage.has(id))
	print("evidence: %d rounds %s; find answer positions %s; clue uses %s; object kinds %s" % [ROUNDS, types, positions, usage, kinds])
	check(unused.is_empty(), "evidence: every clue is used")
	check(usage.values().max() < usage.values().min() * 1.3, "evidence: clues used about equally")
	check(kinds.size() == clues.data.evidence.objects.size(), "evidence: every object kind appears")
