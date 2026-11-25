extends SceneTree
## Word memory check (24 Nov 2026; design docs/game/minigames.md "Which words come up", developer
## notes docs/guides/MINIGAMES.md#word-memory). Headless, without the town:
## - FSRS-4.5 on steps: first answers, success and lapse updates, retrievability falling with steps,
## - new words come in gradually: the gap grows with words being learned, stops at MAX_LEARNING,
## - order(): due words, then the allowed new (lowest tier), then known, then the other new,
## - want() and pick_round(), seeding from the practice log, saving and the profile reset,
## - a simulated learner: over 600 questions new words keep coming while recall stays high,
## - the games' pickers run with the memory (Desk Dash, Mystery Doors, Feel the Clues).
## Writes user:// saves: run with an isolated HOME. Plays no sound.
##   HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/word-memory-20261124/verify.gd
const WordMemory := preload("res://scripts/learning/word_memory.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Grammar := preload("res://scripts/learning/grammar_questions.gd")
const Mystery := preload("res://scripts/learning/mystery_session.gd")
const Clues := preload("res://scripts/learning/detective_clues.gd")
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
	answer(["w0"], false)
	check(memory.new_allowed() == 0, "right after a new word, none allowed")
	for i in WordMemory.NEW_GAP_BASE:
		answer(["w0"], true)
	check(memory.new_allowed() >= 1, "allowed again after the gap")
	for i in 11:
		answer(["x%d" % i], false)
	check(memory.learning_count() >= 12 and memory.new_gap() == -1 and memory.new_allowed() == 0, "no new words while 12 are being learned")
	fresh()
	memory = WordMemory.shared()
	for i in 6:
		answer(["y%d" % i], false)
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

	# --- Saving, seeding, reset ---------------------------------------------------------------
	var saved: Variant = SaveStore.read_json(SaveStore.path(WordMemory.FILE))
	check(saved is Dictionary and saved.has("es") and saved.es.words.has("apple"), "saved per language")
	WordMemory._shared = null
	check(WordMemory.shared().state("apple").size() == 5, "loaded back")
	fresh()
	PracticeLog.shared().counts = {"es": {"dog": {"g": {"positive": 3, "negative": 1, "translated": 0}}, "fish": {"g": {"positive": 0, "negative": 2, "translated": 1}}}}
	memory = WordMemory.shared()
	check(is_equal_approx(float(memory.state("dog").s), WordMemory.W[2]) and is_equal_approx(float(memory.state("fish").s), WordMemory.W[0]), "seeded from the practice log")
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
		pool.append("sim%03d" % i)
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

	print("WORD MEMORY CHECK: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
