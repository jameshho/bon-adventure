extends RefCounted
## Word memory (user, 24 Nov 2026: "apply FSRS to each game ... focus on the interval in gradually
## increasing the new words ... not on time"; design: docs/game/minigames.md "Which words come
## up", developer notes: docs/guides/MINIGAMES.md#word-memory). One shared memory of every
## tested word, per learned language, that every learning game asks which words to use.
##
## Clock: STEPS, not days. Every recorded question (practice_log.gd `recorded`, any game) is one
## step; elapsed = steps since the word was last answered. FSRS's day is STEPS_PER_DAY steps.
## Time away (25 Nov 2026, user decision D8, improvement plan LEARN-03): elapsed also adds the
## real days since the word was last answered, AWAY_DAY_WEIGHT FSRS days per day, at most
## AWAY_DAYS_CAP (a two-month break counts as a week). A word due only because of that term
## ("away-due") counts as due only for the AWAY_REVIEWS_PER_SESSION most forgotten of them per
## session (a session starts after SESSION_GAP_SECONDS without a question); the others stay
## first among the known words, so a long break never floods a game with reviews or holds new
## words back for long. Words without a saved time (older saves) use the time of the language's
## last question, and add nothing until one is saved.
##
## Memory per word (FSRS-4.5, default weights W): stability S (in FSRS days: the elapsed time at
## which recall drops to 90 %), difficulty D (1-10), retrievability R = (1 + F * t / S) ^ DECAY.
## Grades from the tracker: positive = Good (3); negative and translated (the meaning was shown)
## = Again (1). A first answer sets S0 and D0; later ones update D and S with FSRS's success or
## lapse formula.
##
## Choosing words: order(pool, rng) returns the pool best first:
##   1. due      seen words whose R has fallen under TARGET_RETENTION, most forgotten first;
##   2. new      up to new_allowed() never-seen words, lowest word tier first (data/words.json
##               "tier", draft), random within a tier;
##   3. known    other seen words, least well remembered first;
##   4. the remaining new words (so a game always has enough).
## New words come in gradually, by an interval in steps: after a new word is first answered,
## the next one is allowed new_gap() steps later (NEW_GAP_BASE, +1 for every LEARNING_PER_STEP
## words still being learned, none while MAX_LEARNING are), at most NEW_AT_ONCE at a time.
## "Being learned": seen with S under LEARNED_STABILITY, a word of the lexicon, and either in the
## pool the game asks about or answered in the last RECENT_STEPS steps (25 Nov 2026: before, every
## low-stability word ever logged counted, so a player with 12 of them in one game never met a
## new word in another). So a player who keeps getting words right meets new words often; one who
## struggles reviews first.
## Games with a fixed generator (a family tree, a flight board) keep their own generator and
## ask wants(keys) to pick among a few generated questions instead (see pick_round()).
##
## Saved per profile: word_memory.json {"es": {"step": 41, "last_new": 37, "unix": 1795600000,
## "away_left": 6, "words": {"apple": {"s": 3.7, "d": 5.1, "last": 12, "reps": 2, "lapses": 0,
## "unix": 1795590000}}}} ("unix" and "away_left" since 25 Nov 2026: additive, an older build
## ignores them). A language without memory is
## seeded once from the practice log (one review per word: Good when right answers outnumber
## the others; a Good word starts at LEARNED_STABILITY at least, since 25 Nov 2026, so a player's
## well-known words do not hold back new ones; languages seeded before keep their memory). Games started from the ▶ picker record like any other (practice_log.gd).
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const FILE := "word_memory.json"

## FSRS-4.5 default weights.
const W := [0.4872, 1.4003, 3.7145, 13.8206, 5.1618, 1.2298, 0.8975, 0.031, 1.6474, 0.1367,
		1.0461, 2.1072, 0.0793, 0.3246, 1.587, 0.2272, 2.8755]
const DECAY := -0.5
const FACTOR := 19.0 / 81.0
const AGAIN := 1
const GOOD := 3
## Recorded questions that count as one FSRS day.
const STEPS_PER_DAY := 8.0
const TARGET_RETENTION := 0.9
## New words: the gap in steps between them, growing with the words still being learned.
const NEW_GAP_BASE := 3
const LEARNING_PER_STEP := 3
const MAX_LEARNING := 12
const NEW_AT_ONCE := 3
## A word with at least this stability (FSRS days) counts as learned, not "being learned".
const LEARNED_STABILITY := 4.0
## Words answered this many steps ago or less count as being learned in any game (two FSRS days).
const RECENT_STEPS := 16
## Time away (LEARN-03, D8): FSRS days per real day since a word was last answered, the cap in
## real days, the away-due words that count as due per session and the pause that starts one.
const AWAY_DAY_WEIGHT := 1.0
const AWAY_DAYS_CAP := 7.0
const AWAY_REVIEWS_PER_SESSION := 8
const SESSION_GAP_SECONDS := 3 * 3600
const SECONDS_PER_DAY := 86400.0
## Tier of a word without one (data/words.json "tier" is a draft, 24 Nov 2026).
const DEFAULT_TIER := 2

static var _shared

## language -> {"step", "last_new", "unix", "away_left", "words": {key: state}}.
var data: Dictionary = {}
## Checks set the wall clock (unix seconds); below 0 = the system clock.
var now_for_test := -1.0
## The away-due words that count as due now, cached per language, step, budget and hour.
var _away_cache_key := ""
var _away_due: Dictionary = {}

static func shared():
	if _shared == null:
		_shared = new()
		_shared.load_saved()
		PracticeLog.shared().recorded.connect(_shared._on_recorded)
	return _shared

func load_saved() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	data = parsed if parsed is Dictionary else {}
	_away_cache_key = ""

func save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), data)

## The memory of the language being learned (seeded from the practice log the first time).
func _memory() -> Dictionary:
	var language: String = Lexicon.shared().foreign
	if not data.has(language):
		data[language] = _seeded(language)
	return data[language]

## `pending`: the outcomes being recorded now (already in the log), left out so they count once.
func _seeded(language: String, pending: Dictionary = {}) -> Dictionary:
	var memory := {"step": 0, "last_new": -1000, "words": {}}
	var counts: Dictionary = PracticeLog.shared().counts.get(language, {})
	for key in counts:
		var sum: Dictionary = PracticeLog.shared().totals(language, str(key))
		var outcome := str(pending.get(str(key), ""))
		var right := int(sum.positive) - (1 if outcome == "positive" else 0)
		var other := int(sum.negative) + int(sum.translated) - (1 if outcome in ["negative", "translated"] else 0)
		if right + other > 0:
			var first := _first_state(GOOD if right > other else AGAIN, 0)
			if right > other:
				first.s = maxf(float(first.s), LEARNED_STABILITY)
			memory.words[str(key)] = first
	return memory

func step() -> int:
	return int(_memory().get("step", 0))

## A word's state ({} for a word never answered in this language).
func state(key: String) -> Dictionary:
	return _memory().words.get(key, {})

func is_new(key: String) -> bool:
	return state(key).is_empty()

## Recall probability now (1.0 for a new word, which is not due): steps plus capped time away.
func retrievability(key: String) -> float:
	var s := state(key)
	if s.is_empty():
		return 1.0
	return _r(_step_days(s) + away_days(key), float(s.s))

## Due: by steps alone, or away-due and among this session's AWAY_REVIEWS_PER_SESSION.
func is_due(key: String) -> bool:
	var s := state(key)
	if s.is_empty():
		return false
	if _r(_step_days(s), float(s.s)) < TARGET_RETENTION:
		return true
	return _away_due_now().has(key)

func now_unix() -> float:
	return now_for_test if now_for_test >= 0.0 else Time.get_unix_time_from_system()

## The time-away term of a word in FSRS days (0 without a saved time; capped at AWAY_DAYS_CAP).
func away_days(key: String) -> float:
	var memory := _memory()
	var s: Dictionary = memory.words.get(key, {})
	var since := float(s.get("unix", memory.get("unix", -1.0)))
	if s.is_empty() or since < 0.0:
		return 0.0
	return AWAY_DAY_WEIGHT * clampf((now_unix() - since) / SECONDS_PER_DAY, 0.0, AWAY_DAYS_CAP)

## Away-due words that may still count as due this session (a new session after a pause).
func away_budget() -> int:
	var memory := _memory()
	if now_unix() - float(memory.get("unix", -1e12)) >= SESSION_GAP_SECONDS:
		return AWAY_REVIEWS_PER_SESSION
	return maxi(0, int(memory.get("away_left", AWAY_REVIEWS_PER_SESSION)))

func _step_days(s: Dictionary) -> float:
	return float(step() - int(s.last)) / STEPS_PER_DAY

## The away_budget() most forgotten away-due words of the language (key -> true).
func _away_due_now() -> Dictionary:
	var budget := away_budget()
	var cache_key := "%s|%d|%d|%d|%d" % [Lexicon.shared().foreign, step(), budget, int(now_unix() / 3600.0), _memory().words.size()]
	if cache_key == _away_cache_key:
		return _away_due
	var candidates: Array = []
	var words: Dictionary = _memory().words
	if budget > 0:
		for key in words:
			var s: Dictionary = words[key]
			if _r(_step_days(s), float(s.s)) >= TARGET_RETENTION:
				var r := retrievability(str(key))
				if r < TARGET_RETENTION:
					candidates.append([r, str(key)])
	candidates.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	_away_due = {}
	for item in candidates.slice(0, budget):
		_away_due[item[1]] = true
	_away_cache_key = cache_key
	return _away_due

## Seen words still being learned (stability under LEARNED_STABILITY) that are in the lexicon
## and in `pool` (the words the game asks about) or answered in the last RECENT_STEPS steps.
func learning_count(pool: Array = []) -> int:
	var memory := _memory()
	var now := int(memory.get("step", 0))
	var lexicon: Dictionary = Lexicon.shared().words()
	var in_pool := {}
	for key in pool:
		in_pool[str(key)] = true
	var n := 0
	for key in memory.words:
		var s: Dictionary = memory.words[key]
		if float(s.s) >= LEARNED_STABILITY or not lexicon.has(key):
			continue
		if in_pool.has(key) or now - int(s.last) <= RECENT_STEPS:
			n += 1
	return n

## Steps between new words now: NEW_GAP_BASE, +1 per LEARNING_PER_STEP words being learned;
## -1 (no new words) while MAX_LEARNING are being learned. `pool` as in learning_count().
func new_gap(pool: Array = []) -> int:
	var learning := learning_count(pool)
	if learning >= MAX_LEARNING:
		return -1
	return NEW_GAP_BASE + learning / LEARNING_PER_STEP

## How many never-seen words may come up now (`pool` as in learning_count()).
func new_allowed(pool: Array = []) -> int:
	var gap := new_gap(pool)
	if gap < 0:
		return 0
	var since: int = step() - int(_memory().get("last_new", -1000))
	return clampi(since / gap, 0, NEW_AT_ONCE)

## The pool best first (see the header). `rng` breaks ties (a game's own, so seeded runs repeat).
func order(pool: Array, rng: RandomNumberGenerator = null) -> Array:
	var due: Array = []
	var fresh: Array = []
	var known: Array = []
	for key in pool:
		var k := str(key)
		var jitter := rng.randf() * 0.001 if rng != null else 0.0
		if is_new(k):
			fresh.append([float(tier(k)) + jitter * 100.0, k])
		elif is_due(k):
			due.append([retrievability(k) + jitter, k])
		else:
			known.append([retrievability(k) + jitter, k])
	for list in [due, fresh, known]:
		list.sort_custom(func(a, b): return a[0] < b[0])
	var quota := mini(new_allowed(pool), fresh.size())
	var ranked: Array = []
	for list in [due, fresh.slice(0, quota), known, fresh.slice(quota)]:
		for item in list:
			ranked.append(item[1])
	return ranked

## The first `count` of order().
func choose(pool: Array, count: int, rng: RandomNumberGenerator = null) -> Array:
	return order(pool, rng).slice(0, count)

## How much a question testing `keys` is wanted now: 2 a due word, 1 an allowed new word,
## 0 only known words, -1 a new word while none is allowed.
func want(keys: Array) -> int:
	var best := 0
	var new_words := 0
	for key in keys:
		var k := str(key)
		if is_due(k):
			best = maxi(best, 2)
		elif is_new(k):
			new_words += 1
	if new_words > 0:
		if new_words > new_allowed(keys):
			return -1 if best < 2 else best
		best = maxi(best, 1)
	return best

## For games whose generator builds a whole round at once (a family tree question, a flight
## board): calls `make` up to `tries` times until a round's words (`words_of(round)`) are wanted
## (want() >= 1) and returns that round; else the last one made (each call replaces the game's
## state, so the last one is the one in place). An empty round is retried. A round that tests no
## word (a family "who is older" question) is taken as it comes, but once a round with words was
## turned down only rounds with words count, and from the last try on the next one is taken
## whatever its words (25 Nov 2026: before, a word-less round replaced it, and since those record
## no step, the new-word gate never reopened and a game could stop asking about words at all).
func pick_round(make: Callable, words_of: Callable, tries := 6) -> Variant:
	var made: Variant = null
	var saw_words := false
	for attempt in tries * 2:
		made = make.call()
		if made == null or (made is Dictionary and made.is_empty()):
			continue
		var keys: Array = words_of.call(made)
		if keys.is_empty():
			if not saw_words:
				return made
			continue
		saw_words = true
		if want(keys) >= 1 or attempt >= tries - 1:
			return made
	return made

## A word's draft tier (data/words.json "tier": a number or {code: n, "default": n}).
func tier(key: String) -> int:
	var value: Variant = Lexicon.shared().words().get(key, {}).get("tier", DEFAULT_TIER)
	if value is Dictionary:
		value = value.get(Lexicon.shared().foreign, value.get("default", DEFAULT_TIER))
	return int(value)

## One recorded question: one step, then every word's FSRS update.
func _on_recorded(_game_id: String, outcomes: Dictionary) -> void:
	var language: String = Lexicon.shared().foreign
	if not data.has(language):
		data[language] = _seeded(language, outcomes)
	var memory := _memory()
	var budget := away_budget()
	var away_reviewed := 0
	for key in outcomes:
		var k := str(key)
		if memory.words.has(k) and is_due(k) and _r(_step_days(memory.words[k]), float(memory.words[k].s)) >= TARGET_RETENTION:
			away_reviewed += 1
	memory.step = int(memory.get("step", 0)) + 1
	var now: int = memory.step
	var unix := int(now_unix())
	for key in outcomes:
		var grade := GOOD if str(outcomes[key]) == "positive" else AGAIN
		var s: Dictionary = memory.words.get(str(key), {})
		if s.is_empty():
			memory.words[str(key)] = _first_state(grade, now)
			memory.last_new = now
		else:
			# Time away counts towards the review (FSRS's elapsed time), as in retrievability().
			memory.words[str(key)] = _review(s, grade, now, away_days(str(key)))
		memory.words[str(key)].unix = unix
	memory.unix = unix
	memory.away_left = maxi(0, budget - away_reviewed)
	save()

func _first_state(grade: int, now: int) -> Dictionary:
	return {"s": W[grade - 1], "d": _d0(grade), "last": now, "reps": 1, "lapses": 1 if grade == AGAIN else 0}

func _review(s: Dictionary, grade: int, now: int, away := 0.0) -> Dictionary:
	var stability := float(s.s)
	var difficulty := float(s.d)
	var r := _r(float(now - int(s.last)) / STEPS_PER_DAY + away, stability)
	var next_d := clampf(W[7] * _d0(4) + (1.0 - W[7]) * (difficulty - W[6] * (grade - 3)), 1.0, 10.0)
	var next_s: float
	if grade == AGAIN:
		next_s = minf(stability, W[11] * pow(difficulty, -W[12]) * (pow(stability + 1.0, W[13]) - 1.0) * exp(W[14] * (1.0 - r)))
	else:
		next_s = stability * (exp(W[8]) * (11.0 - difficulty) * pow(stability, -W[9]) * (exp(W[10] * (1.0 - r)) - 1.0) + 1.0)
	return {"s": maxf(0.1, next_s), "d": next_d, "last": now, "reps": int(s.reps) + 1, "lapses": int(s.lapses) + (1 if grade == AGAIN else 0)}

func _d0(grade: int) -> float:
	return clampf(W[4] - exp(W[5] * (grade - 1)) + 1.0, 1.0, 10.0)

static func _r(elapsed_days: float, stability: float) -> float:
	return pow(1.0 + FACTOR * maxf(0.0, elapsed_days) / maxf(0.1, stability), DECAY)
