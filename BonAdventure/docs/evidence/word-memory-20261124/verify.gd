extends SceneTree
## Word memory check (24 Nov 2026; design docs/game/minigames.md "Which words come up", developer
## notes docs/guides/MINIGAMES.md#word-memory). Headless, without the town:
## - FSRS-4.5 on steps: first answers, success and lapse updates, retrievability falling with steps,
## - new words come in gradually: the gap grows with words being learned, stops at MAX_LEARNING,
## - order(): due words, then the allowed new (lowest tier), then known, then the other new,
## - want() and pick_round(), seeding from the practice log, saving and the profile reset,
## - a simulated learner: over 600 questions new words keep coming while recall stays high,
## - the games' pickers run with the memory (Desk Dash, Mystery Doors, Feel the Clues),
## - (25 Nov 2026, LEARN-01/02) "being learned" counts only lexicon words in the game's pool or
##   answered recently: a learner who saturates one game meets new words in the next; seeded Good
##   words start learned; Feeding Time! asks a due animal first, never the same one twice in a row,
## - (25 Nov 2026, LEARN-03/D8) time away: a 1-day, 7-day and 60-day gap (capped at a week), at
##   most AWAY_REVIEWS_PER_SESSION away-due words per session, and old saves without the times.
## Words whose being-learned state matters are real lexicon keys (real()); fillers are not.
## Writes user:// saves: run with an isolated HOME. Plays no sound.
##   HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/word-memory-20261124/verify.gd
const WordMemory := preload("res://scripts/learning/word_memory.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Grammar := preload("res://scripts/learning/grammar_questions.gd")
const Mystery := preload("res://scripts/learning/mystery_session.gd")
const Clues := preload("res://scripts/learning/detective_clues.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const ZooFeeding := preload("res://scripts/learning/zoo_feeding_session.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## One recorded question through the practice log, as a game records it.
func answer(keys: Array, right: Variant) -> void:
	PracticeLog.shared().begin("check", keys)
	PracticeLog.shared().first_answer(right)
	PracticeLog.shared().complete()

## Feeding Time!'s food helper as plan() uses it: the animals and what they eat.
class FeederStub extends RefCounted:
	var nodes: Array = []
	var eats: Dictionary = {}
	func animals() -> Array:
		return nodes

## Real lexicon word keys, sorted (the memory ignores keys missing from the lexicon).
var _real: Array = []
func real(i: int) -> String:
	if _real.is_empty():
		_real = Lexicon.shared().words().keys()
		_real.sort()
	return str(_real[i])

## A word the learner knows well, answered at the current step.
func knows(memory, key: String) -> void:
	memory._memory().words[key] = {"s": 40.0, "d": 4.0, "last": memory.step(), "reps": 4, "lapses": 0}

func fresh() -> void:
	WordMemory._shared = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.path(WordMemory.FILE)))
	PracticeLog.shared().counts = {}

func run():
	GameSettings.shared().set_languages("en", "es")
	fresh()
	var memory = WordMemory.shared()

	# --- FSRS ------------------------------------------------------------------------------
	answer(["apple"], true)
	var s: Dictionary = memory.state("apple")
	check(is_equal_approx(float(s.s), WordMemory.W[2]) and int(s.reps) == 1 and int(s.lapses) == 0, "Good first answer: S0 = W2 (%s)" % s)
	answer(["pear"], false)
	check(is_equal_approx(float(memory.state("pear").s), WordMemory.W[0]) and int(memory.state("pear").lapses) == 1, "Again first answer: S0 = W0")
	check(float(memory.state("pear").d) > float(s.d), "Again starts harder than Good")
	answer(["step"], true)
	check(memory.step() == 3 and is_equal_approx(memory.retrievability("pear"), WordMemory._r(1.0 / 8.0, WordMemory.W[0])), "one step = 1/8 FSRS day")
	var r_before: float = memory.retrievability("apple")
	for i in 20:
		answer(["filler%d" % i], true)
	check(memory.retrievability("apple") < r_before, "recall falls as steps pass")
	var s_old := float(memory.state("apple").s)
	answer(["apple"], true)
	check(float(memory.state("apple").s) > s_old and int(memory.state("apple").reps) == 2, "a right review grows stability (%.2f -> %.2f)" % [s_old, float(memory.state("apple").s)])
	s_old = float(memory.state("apple").s)
	answer(["apple"], false)
	check(float(memory.state("apple").s) < s_old and int(memory.state("apple").lapses) == 1, "a lapse shrinks stability")
	PracticeLog.shared().begin("check", ["cat"])
	PracticeLog.shared().mark_translated("cat")
	PracticeLog.shared().first_answer(true)
	PracticeLog.shared().complete()
	check(int(memory.state("cat").lapses) == 1, "a shown translation counts as Again")

	# --- New-word interval -----------------------------------------------------------------
	fresh()
	memory = WordMemory.shared()
	check(memory.new_gap() == WordMemory.NEW_GAP_BASE and memory.new_allowed() == WordMemory.NEW_AT_ONCE, "a new player may meet NEW_AT_ONCE new words")
	answer([real(0)], false)
	check(memory.new_allowed() == 0, "right after a new word, none allowed")
	for i in WordMemory.NEW_GAP_BASE:
		answer([real(0)], true)
	check(memory.new_allowed() >= 1, "allowed again after the gap")
	for i in 11:
		answer([real(1 + i)], false)
	check(memory.learning_count() >= 12 and memory.new_gap() == -1 and memory.new_allowed() == 0, "no new words while 12 are being learned")
	fresh()
	memory = WordMemory.shared()
	for i in 6:
		answer([real(20 + i)], false)
	check(memory.new_gap() == WordMemory.NEW_GAP_BASE + 2, "gap grows with words being learned (%d)" % memory.new_gap())

	# --- order(), want(), pick_round() --------------------------------------------------------
	fresh()
	memory = WordMemory.shared()
	answer(["apple"], false)
	answer(["bread"], true)
	for i in 40:
		answer(["bread"], true)
	check(memory.is_due("apple") and not memory.is_due("bread"), "apple (missed long ago) is due, bread is not")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ranked: Array = memory.order(["bread", "n1", "apple", "n2", "n3", "n4", "n5"], rng)
	check(ranked[0] == "apple", "due first (%s)" % [ranked])
	var allowed: int = memory.new_allowed()
	check(ranked.slice(1, 1 + allowed).all(func(k): return memory.is_new(k)) and ranked[1 + allowed] == "bread", "then %d allowed new, then known (%s)" % [allowed, ranked])
	check(ranked.size() == 7, "every word still ranked")
	check(memory.want(["apple"]) == 2 and memory.want(["bread"]) == 0, "want: due 2, known 0")
	check(memory.want(["n1"]) == (1 if allowed > 0 else -1), "want: new word follows the allowance")
	check(memory.want(["n1", "n2", "n3", "n4"]) == -1, "want: more new words than allowed is -1")
	var made := [0]
	var picked = memory.pick_round(func():
		made[0] += 1
		return {"words": ["bread"]} if made[0] < 3 else {"words": ["apple"]}, func(r): return r.words)
	check(picked.words == ["apple"] and made[0] == 3, "pick_round keeps trying until a wanted round")
	made[0] = 0
	picked = memory.pick_round(func():
		made[0] += 1
		return {"words": ["bread"]}, func(r): return r.words, 4)
	check(made[0] == 4 and picked.words == ["bread"], "pick_round falls back to the last round")
	# A word-less round (a family "who is older") never replaces a turned-down round with words:
	# word-less rounds record no step, so the new-word gate would never reopen (25 Nov 2026).
	var newish: String = real(500)
	answer([real(501)], true)  # a new word just now: none allowed for a few steps
	check(memory.want([newish]) == -1, "a new word is not allowed now")
	made[0] = 0
	picked = memory.pick_round(func():
		made[0] += 1
		return {"words": [newish]} if made[0] % 2 == 1 else {"words": []}, func(r): return r.words, 4)
	check(picked.words == [newish] and made[0] == 5, "after a turned-down round with words, word-less rounds are skipped and the next round with words is taken (%s, %d made)" % [picked.words, made[0]])
	made[0] = 0
	picked = memory.pick_round(func():
		made[0] += 1
		return {"words": []}, func(r): return r.words)
	check(made[0] == 1 and picked.words.is_empty(), "a word-less round is taken as it comes")

	# --- Saving, seeding, reset ---------------------------------------------------------------
	var saved: Variant = SaveStore.read_json(SaveStore.path(WordMemory.FILE))
	check(saved is Dictionary and saved.has("es") and saved.es.words.has("apple"), "saved per language")
	WordMemory._shared = null
	check(WordMemory.shared().state("apple").size() == 6, "loaded back (with the answer's time)")
	fresh()
	PracticeLog.shared().counts = {"es": {"dog": {"g": {"positive": 3, "negative": 1, "translated": 0}}, "fish": {"g": {"positive": 0, "negative": 2, "translated": 1}}}}
	memory = WordMemory.shared()
	check(is_equal_approx(float(memory.state("dog").s), maxf(WordMemory.W[2], WordMemory.LEARNED_STABILITY)) and is_equal_approx(float(memory.state("fish").s), WordMemory.W[0]), "seeded from the practice log (a Good word starts learned)")
	PracticeLog.shared().counts = {}
	preload("res://scripts/core/profile_manager.gd").reset_singletons()
	check(WordMemory._shared == null, "the profile reset clears the memory")
	check(SaveStore.PROFILE_FILES.has(WordMemory.FILE), "word_memory.json is a profile file")
	GameSettings.shared().set_languages("en", "es")

	# --- A simulated learner ------------------------------------------------------------------
	# 120 words; each round the game asks for 4 by order(). The learner answers right with the
	# FSRS recall chance (new words: 50 %). New words must keep coming over 600 questions.
	fresh()
	memory = WordMemory.shared()
	var pool: Array = []
	for i in 120:
		pool.append(real(100 + i))
	var sim := RandomNumberGenerator.new()
	sim.seed = 42
	var seen_at: Array = []
	var right := 0
	for q in 600:
		var key: String = memory.order(pool, sim)[0]
		var chance: float = 0.5 if memory.is_new(key) else memory.retrievability(key)
		var ok := sim.randf() < chance
		right += int(ok)
		answer([key], ok)
		if q % 100 == 99:
			seen_at.append(memory._memory().words.size())
	print("SIM: words met after each 100 questions %s; right %d / 600; being learned %d" % [seen_at, right, memory.learning_count()])
	check(seen_at[0] >= 8 and seen_at[0] <= 40, "first 100 questions bring a modest number of new words (%d)" % seen_at[0])
	var growing := true
	for i in range(1, seen_at.size()):
		growing = growing and seen_at[i] > seen_at[i - 1]
	check(growing, "new words keep coming every 100 questions")
	check(right > 360, "most answers right (reviews come before they are forgotten)")

	# --- Games use the memory -----------------------------------------------------------------
	fresh()
	memory = WordMemory.shared()
	var bank := Grammar.new()
	if Grammar.has_bank("zh") and bank.load_bank("zh"):
		GameSettings.shared().set_languages("en", "zh")
		var nouns: Array = bank.questions.map(func(q): return str(q.get("noun", ""))).filter(func(n): return n != "")
		if nouns.size() > 2:
			var target := str(nouns[nouns.size() - 1])
			answer([target], false)
			for i in 40:
				answer(["filler"], true)
			rng.seed = 3
			var first: Dictionary = bank.pick(3, rng)[0]
			check(str(first.get("noun", "")) == target, "Desk Dash: the due noun's question comes first (%s)" % first.get("noun", ""))
		GameSettings.shared().set_languages("en", "es")
	rng.seed = 5
	var rounds: Array = Mystery.make_rounds(6, rng)
	check(rounds.size() == 6 and rounds.all(func(r): return not Mystery.tested_words(r).is_empty()), "Mystery Doors: rounds made with the memory")
	var clues := Clues.new()
	var evidence: Dictionary = clues.generate_evidence(rng, "find")
	check(not evidence.is_empty() and Clues.words_of(evidence.clues).size() >= 1, "Feel the Clues: an evidence round made")
	var word := str(Clues.words_of(evidence.clues)[0])
	answer([word], false)
	clues.generate_evidence(rng, "find")  # one round between (a clue never repeats at once)
	for i in 40:
		answer(["filler"], true)
	var again: Dictionary = clues.generate_evidence(rng, "find")
	check(str(Clues.words_of(again.clues)[0]) == word, "Feel the Clues: the due word's clue comes back (%s, %s)" % [word, Clues.words_of(again.clues)])

	two_games()
	zoo_due_first()
	known_words()
	time_away()
	old_save_without_times()

	print("WORD MEMORY CHECK: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

## LEARN-01: a learner who has missed 15 words of one game (more than MAX_LEARNING being learned)
## moves to a second game (10 well-known words, 30 new) and still meets new words in it.
func two_games() -> void:
	fresh()
	var memory = WordMemory.shared()
	var game_a: Array = []
	var game_b: Array = []
	for i in 40:
		game_a.append(real(300 + i))
		game_b.append(real(400 + i))
	for i in 10:
		knows(memory, game_b[i])
	var sim := RandomNumberGenerator.new()
	sim.seed = 11
	for i in 15:
		answer([game_a[i]], false)  # 15 of game A's words missed: being learned there
	check(memory.learning_count(game_a) >= WordMemory.MAX_LEARNING and memory.new_allowed(game_a) == 0, "game A: no new words while %d are being learned there" % memory.learning_count(game_a))
	var met := 0
	for q in 40:
		var key: String = memory.order(game_b, sim)[0]
		met += int(memory.is_new(key))
		answer([key], true)
	print("TWO GAMES: game A learning %d; new words met in 40 questions of game B: %d" % [memory.learning_count(game_a), met])
	check(met >= 4, "game B: new words come although game A has %d being learned (%d met)" % [WordMemory.MAX_LEARNING, met])
	check(memory.learning_count(game_a) >= WordMemory.MAX_LEARNING and memory.new_allowed(game_a) == 0, "back in game A its own words still hold new ones back")
	for i in 12:
		answer(["not_a_word_%d" % i], false)
	var fakes: Array = []
	for i in 12:
		fakes.append("not_a_word_%d" % i)
	check(memory.learning_count(fakes) == memory.learning_count(), "keys missing from the lexicon are not being learned, even just answered")

## LEARN-02: Feeding Time! plans requests in the memory's order: a due animal first.
func zoo_due_first() -> void:
	fresh()
	var memory = WordMemory.shared()
	var lexicon = Lexicon.shared()
	var tier_of := {}
	var animals: Array = []
	for i in _real.size():
		var t: int = lexicon.tier(real(i), lexicon.foreign)
		tier_of[t] = tier_of.get(t, []) + [real(i)]
		if tier_of[t].size() == 5:
			animals = tier_of[t]
			break
	var feeder := FeederStub.new()
	for key in animals:
		var node := Node3D.new()
		node.set_meta("word_key", key)
		feeder.nodes.append(node)
		feeder.eats[key] = ["apple"]
	var session = ZooFeeding.new()
	session.lexicon = lexicon
	session.feeder = feeder
	var due: String = animals[3]
	answer([due], false)
	for key in animals:
		if key != due:
			knows(memory, key)
	for i in 40:
		answer(["filler"], true)
	for key in animals:
		if key != due:
			knows(memory, key)
	check(memory.is_due(due) and animals.all(func(k): return k == due or not memory.is_due(k)), "zoo: only %s is due" % due)
	var tiers := [lexicon.tier(due, lexicon.foreign)]
	var requests: Array = session.plan(3, tiers)
	check(not requests.is_empty() and str(requests[0].animal) == due, "Feeding Time!: the due animal is asked first (%s)" % [requests.map(func(r): return r.animal)])
	requests = session.plan(12, tiers)
	var repeats := 0
	for i in range(1, requests.size()):
		repeats += int(requests[i].animal == requests[i - 1].animal)
	check(requests.size() == 12 and repeats == 0, "Feeding Time!: no animal twice in a row (%d repeats)" % repeats)
	session.free()
	for node in feeder.nodes:
		node.free()

## LEARN-04 / D9 (25 Nov 2026): one meaning of "known" (stability >= LEARNED_STABILITY), the
## known_changed signal and the session's "known" words (session_words.gd).
func known_words() -> void:
	fresh()
	var SessionWords := preload("res://scripts/learning/session_words.gd")
	SessionWords._shared = null
	var memory = WordMemory.shared()
	var words = SessionWords.shared()
	var changes: Array = []
	memory.known_changed.connect(func(g, k, known): changes.append([g, k, known]))
	words.start("check")
	var key := real(10)
	answer([key], true)
	check(not memory.is_known(key) and WordMemory.W[2] < WordMemory.LEARNED_STABILITY, "one right answer is not known yet (S %.2f)" % float(memory.state(key).s))
	check(memory.is_known(key) == WordMemory.known_state(memory.state(key)) and not memory.is_known("never_seen_word"), "is_known follows known_state; an unseen word is not known")
	for i in 40:
		answer(["filler"], true)
	answer([key], true)
	check(memory.is_known(key) and float(memory.state(key).s) >= WordMemory.LEARNED_STABILITY, "a right review after a gap makes it known (S %.2f)" % float(memory.state(key).s))
	check(changes.has(["check", key, true]), "known_changed told the game (%s)" % [changes])
	check(words.summary().known.has(key) and words.became_known(key), "the session lists it as known (%s)" % [words.summary().known])
	check(memory.known_count([key, "filler"]) == (2 if memory.is_known("filler") else 1), "known_count counts the known keys")
	check(memory.learning_count([key]) == 0, "a known word is not being learned")
	for i in 400:
		answer(["filler"], true)
	answer([key], false)
	answer([key], false)
	check(not memory.is_known(key) and changes.back() == ["check", key, false] and not words.summary().known.has(key), "lapses below the threshold: not known, and off the session's list (S %.2f)" % float(memory.state(key).s))
	words.start("other")
	check(words.summary().known.is_empty(), "a new session starts with no known words")
	SessionWords._shared = null

## A word the learner has answered at `unix` (now, by steps), with stability `s`.
func answered_at(memory, key: String, s: float, unix: float) -> void:
	memory._memory().words[key] = {"s": s, "d": 5.0, "last": memory.step(), "reps": 2, "lapses": 0, "unix": int(unix)}

## LEARN-03 (D8): real days since a word was answered add to its elapsed time, capped at a week;
## away-due words count as due only AWAY_REVIEWS_PER_SESSION per session.
func time_away() -> void:
	fresh()
	var memory = WordMemory.shared()
	var t0 := 1.8e9
	memory.now_for_test = t0
	answer(["filler"], true)
	var learned: String = real(600)
	var strong: String = real(601)
	answered_at(memory, learned, WordMemory.LEARNED_STABILITY, t0)
	answered_at(memory, strong, 40.0, t0)
	check(is_equal_approx(memory.retrievability(learned), 1.0) and not memory.is_due(learned), "no time away: nothing added")
	# 1 day away: one FSRS day added; a learned word is not due yet.
	memory.now_for_test = t0 + 86400.0
	check(is_equal_approx(memory.away_days(learned), 1.0) and is_equal_approx(memory.retrievability(learned), WordMemory._r(1.0, WordMemory.LEARNED_STABILITY)), "1 day away adds one FSRS day (R %.3f)" % memory.retrievability(learned))
	check(not memory.is_due(learned) and not memory.is_due(strong), "1 day away: a learned word is not due")
	# 7 days away: the learned word comes due, a well-known one does not.
	memory.now_for_test = t0 + 7 * 86400.0
	check(is_equal_approx(memory.away_days(learned), 7.0) and memory.is_due(learned), "7 days away: a learned word is due (R %.3f)" % memory.retrievability(learned))
	check(not memory.is_due(strong), "7 days away: a well-known word is not due")
	# 60 days away: counted as AWAY_DAYS_CAP.
	memory.now_for_test = t0 + 60 * 86400.0
	check(is_equal_approx(memory.away_days(learned), WordMemory.AWAY_DAYS_CAP) and is_equal_approx(memory.retrievability(learned), WordMemory._r(WordMemory.AWAY_DAYS_CAP, WordMemory.LEARNED_STABILITY)), "60 days away counts as %d (R %.3f)" % [WordMemory.AWAY_DAYS_CAP, memory.retrievability(learned)])
	check(memory.is_due(learned) and not memory.is_due(strong), "60 days away: the learned word is due, the well-known one still is not")
	var r_away: float = memory.retrievability(learned)
	answer([learned], true)
	check(float(memory.state(learned).s) > WordMemory.LEARNED_STABILITY and int(memory.state(learned).unix) == int(t0 + 60 * 86400.0) and not memory.is_due(learned), "a review after time away grows stability and saves the time (R was %.3f)" % r_away)

	# The flood cap: 20 learned words answered 60 days ago, plus one word due by steps.
	fresh()
	memory = WordMemory.shared()
	memory.now_for_test = t0
	answer(["filler"], true)
	var missed: String = real(650)
	answer([missed], false)
	for i in 40:
		answer(["filler"], true)
	knows(memory, "filler")
	var pool: Array = []
	for i in 20:
		pool.append(real(620 + i))
		answered_at(memory, pool[i], WordMemory.LEARNED_STABILITY + 0.1 * i, t0)
	var back := t0 + 60 * 86400.0
	memory.now_for_test = back
	var due_now: Array = pool.filter(func(k): return memory.is_due(k))
	check(due_now == pool.slice(0, WordMemory.AWAY_REVIEWS_PER_SESSION), "60 days away: only the %d most forgotten count as due (%d)" % [WordMemory.AWAY_REVIEWS_PER_SESSION, due_now.size()])
	check(memory.is_due(missed), "a word due by steps is due whatever the cap")
	var fresh_word: String = real(700)
	var ranked: Array = memory.order(pool + [fresh_word, missed])
	check(ranked.slice(0, 1 + WordMemory.AWAY_REVIEWS_PER_SESSION).has(missed) and ranked.find(fresh_word) == 1 + WordMemory.AWAY_REVIEWS_PER_SESSION, "order: the capped due words, then the new word, then the other away words (%s)" % [ranked.find(fresh_word)])
	for i in WordMemory.AWAY_REVIEWS_PER_SESSION:
		memory.now_for_test = back + 60.0 * (i + 1)
		answer([memory.order(pool)[0]], true)
	var still: Array = pool.filter(func(k): return memory.is_due(k))
	check(memory.away_budget() == 0 and still.is_empty(), "after %d away reviews no other away word is due this session (%d)" % [WordMemory.AWAY_REVIEWS_PER_SESSION, still.size()])
	check(memory.retrievability(pool[19]) < WordMemory.TARGET_RETENTION and memory.order(pool)[0] == pool[WordMemory.AWAY_REVIEWS_PER_SESSION], "the other away words still come first among the known")
	memory.now_for_test = back + 600.0 + WordMemory.SESSION_GAP_SECONDS
	still = pool.filter(func(k): return memory.is_due(k))
	check(memory.away_budget() == WordMemory.AWAY_REVIEWS_PER_SESSION and still.size() == WordMemory.AWAY_REVIEWS_PER_SESSION, "next session: %d more come due (%d)" % [WordMemory.AWAY_REVIEWS_PER_SESSION, still.size()])

## Old saves (no "unix" times) load unchanged and add no time away until a question is answered;
## new saves keep every field an older build reads.
func old_save_without_times() -> void:
	fresh()
	var old := {"es": {"step": 50, "last_new": 10, "words": {"apple": {"s": 4.0, "d": 5.0, "last": 50, "reps": 2, "lapses": 0}}}}
	SaveStore.write_json(SaveStore.path(WordMemory.FILE), old)
	var memory = WordMemory.shared()
	var t0 := 1.8e9
	memory.now_for_test = t0
	check(memory.step() == 50 and memory.state("apple").size() == 5 and is_equal_approx(memory.away_days("apple"), 0.0), "old save loads unchanged, no time away")
	check(is_equal_approx(memory.retrievability("apple"), 1.0) and not memory.is_due("apple") and memory.away_budget() == WordMemory.AWAY_REVIEWS_PER_SESSION, "old save: same recall as before")
	answer(["bread"], true)
	memory.now_for_test = t0 + 7 * 86400.0
	check(is_equal_approx(memory.away_days("apple"), 7.0) and memory.is_due("apple"), "an old word counts time away from the language's last question")
	var saved: Variant = SaveStore.read_json(SaveStore.path(WordMemory.FILE))
	var ok: bool = saved is Dictionary and saved.has("es") and saved.es.has("step") and saved.es.has("last_new")
	if ok:
		for key in saved.es.words:
			var w: Dictionary = saved.es.words[key]
			for field in ["s", "d", "last", "reps", "lapses"]:
				ok = ok and w.has(field)
	check(ok and saved.es.has("unix") and saved.es.words.bread.has("unix") and not saved.es.words.apple.has("unix"), "new save keeps every older field; times are added (%s)" % [saved.es.words if saved is Dictionary else saved])
