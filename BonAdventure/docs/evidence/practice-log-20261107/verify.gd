extends SceneTree
## Practice tracker (Stage B, 7 Nov 2026; guide: docs/guides/ARCHITECTURE_REVIEW_PART1.md#practice-tracker).
## Part 1: the grocery example rules on the shared tracker (one word, "apple", in a test game):
## first try right, wrong then right, translate then right, wrong then translate, many
## toggles, translate after completion, abandoned; plus Native mode, a language change, a
## multi-word question, the word card and the saved file. Part 2: the real games in the town
## (shop order and family relation question; restaurant, warehouse, flight and grammar added
## with their commits). Main and the tracker save to user://: run with an isolated HOME.
## HOME=<scratch>/home VT_FOCUS=all godot --headless --path . --script res://docs/evidence/practice-log-20261107/verify.gd
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const ShopOrder := preload("res://scripts/learning/shop_order.gd")
const FlightQuestions := preload("res://scripts/learning/flight_questions.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const GAME := "test_grocery"
var failures := 0
var checks := 0
var log
var lang := ""

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## The translation is seen by peeking (holding the HUD's EN or L), since the one EN button
## (103bc60a): the panels' own toggle no longer counts (updated 25 Nov 2026).
func _peek(on: bool) -> void:
	GameSettings.shared().set_peek(on)

func frames(n: int) -> void:
	for i in n:
		await process_frame

## The counts of `key` in `game` now.
func now(key: String, game: String = GAME) -> Dictionary:
	var entry: Dictionary = log.games_for(lang, key).get(game, {})
	return {"positive": int(entry.get("positive", 0)), "negative": int(entry.get("negative", 0)), "translated": int(entry.get("translated", 0))}

## Checks that only `outcome` grew by `by` (or nothing grew, outcome "") since `before`.
func expect(before: Dictionary, key: String, outcome: String, label: String, game: String = GAME, by: int = 1) -> void:
	var after := now(key, game)
	var ok := true
	for name in PracticeLog.OUTCOMES:
		var want: int = before[name] + (by if name == outcome else 0)
		ok = ok and after[name] == want
	check(ok, label + " (before %s, after %s)" % [before, after])

func run():
	log = PracticeLog.shared()
	lang = Lexicon.shared().foreign
	var settings = GameSettings.shared()
	settings.set_native(false)
	var b: Dictionary

	# --- Part 1: grocery example rows ------------------------------------------------
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(true); log.complete()
	expect(b, "apple", "positive", "first try right -> positive")
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(false); log.first_answer(true); log.complete()
	expect(b, "apple", "negative", "wrong then right -> negative")
	b = now("apple"); log.begin(GAME, ["apple"]); log.translation_shown.emit(""); log.first_answer(true); log.complete()
	expect(b, "apple", "translated", "translate then right -> translated")
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(false); log.translation_shown.emit(""); log.first_answer(true); log.complete()
	expect(b, "apple", "translated", "wrong then translate -> translated")
	b = now("apple"); log.begin(GAME, ["apple"])
	for i in 7:
		log.translation_shown.emit("")
		log.first_answer(i % 2 == 0)
	log.complete(); log.complete(); log.first_answer(true); log.complete()
	expect(b, "apple", "translated", "many toggles, answers and repeated complete -> one translated")
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(true); log.complete(); log.translation_shown.emit(""); log.complete()
	expect(b, "apple", "positive", "translate after completion -> stays positive")
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(false); log.translation_shown.emit(""); log.abandon(); log.complete()
	expect(b, "apple", "", "abandoned -> nothing")
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(true); log.begin(GAME, ["apple"]); log.complete()
	expect(b, "apple", "", "a new question abandons the open one; no answer -> nothing")
	# Native mode.
	settings.set_native(true)
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(true); log.complete()
	expect(b, "apple", "", "question begun in Native mode -> nothing")
	settings.set_native(false)
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(true); settings.set_native(true); settings.set_native(false); log.complete()
	expect(b, "apple", "translated", "Native mode switched on mid-question -> translated")
	# A language change abandons the question; counts are per learned language.
	var native: String = settings.native
	var foreign: String = settings.foreign
	var other := ""
	for code in Lexicon.shared().playable_codes():
		if code != foreign:
			other = code
	b = now("apple"); log.begin(GAME, ["apple"]); log.first_answer(true); settings.set_languages(native, other); log.complete(); settings.set_languages(native, foreign)
	expect(b, "apple", "", "a language change abandons the question")
	check(log.games_for(other, "apple").is_empty(), "nothing recorded under the other language")
	# Several words: each gets its own outcome; the word card marks only its word.
	var bb := now("banana")
	var bm := now("milk")
	b = now("apple")
	log.begin(GAME, ["apple", "banana", "milk"])
	log.translation_shown.emit("milk")
	log.translation_shown.emit("bread")
	log.first_answer({"apple": true, "banana": false, "milk": true})
	log.complete()
	expect(b, "apple", "positive", "multi-word: apple right")
	expect(bb, "banana", "negative", "multi-word: banana wrong")
	expect(bm, "milk", "translated", "multi-word: milk's card shown")
	check(log.totals(lang, "apple").positive == now("apple").positive, "totals are the sums over games")
	# The saved file.
	var reloaded = PracticeLog.new()
	reloaded.load_saved()
	check(reloaded.games_for(lang, "apple") == log.games_for(lang, "apple"), "the saved file reloads the same counts")

	# --- Part 2: the games in the town ------------------------------------------------
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	await frames(5)
	await shop_game(game)
	await family_game(game)
	await restaurant_game(game)
	await warehouse_game(game)
	await flight_game(game)
	await grammar_game(game)
	print("PRACTICE LOG: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## A shop order: the till's first check (check_cart(), the checkout since 21 Nov 2026; the
## Done button and _on_done() are gone) finds one item missing, the second matches and paid()
## completes the question; then a second order with the translate bubble on; then an order quit.
## (Updated 25 Nov 2026 to the till's paid flow, as shop-basket-20261114/verify.gd.)
func shop_game(game) -> void:
	var shop = game.find_child("ShopSession_supermarket", true, false)
	check(shop != null, "shop session exists")
	if shop == null:
		return
	var id: String = shop.activity_id()
	shop._start_order()
	check(log.game_id() == id, "an order begins a question")
	var keys: Array = shop.order.order.keys()
	var before: Dictionary = {}
	for key in keys:
		before[key] = now(key, id)
	var missing: String = keys[0]
	for key in keys:
		if key != missing:
			for n in int(shop.order.order[key]):
				shop.order.add_to_cart(key)
	var first: Dictionary = shop.check_cart()
	check(not first.match and first.missing.has(missing), "the till's first check misses one item")
	check(log.game_id() == id, "a basket turned down keeps the question open")
	for n in int(shop.order.order[missing]):
		shop.order.add_to_cart(missing)
	check(shop.check_cart().match, "the second check matches")
	shop.paid()
	check(shop.awaiting_return and not log.is_open(), "paying completes the question")
	for key in keys:
		expect(before[key], key, "negative" if key == missing else "positive", "shop item %s" % key, id)
	shop.awaiting_return = false
	shop._finish_order()
	shop.panel.hide_dialogue()
	# Second order: the translate bubble during the intro marks every item.
	shop._start_order()
	keys = shop.order.order.keys()
	before = {}
	for key in keys:
		before[key] = now(key, id)
	_peek(true)
	await frames(2)
	for key in keys:
		for n in int(shop.order.order[key]):
			shop.order.add_to_cart(key)
	shop.check_cart()
	shop.paid()
	for key in keys:
		expect(before[key], key, "translated", "shop bubble: %s translated" % key, id)
	_peek(false)
	shop.awaiting_return = false
	shop._finish_order()
	shop.panel.hide_dialogue()
	await frames(2)
	# Third order quit from the cart: nothing.
	shop._start_order()
	keys = shop.order.order.keys()
	before = {}
	for key in keys:
		before[key] = now(key, id)
	shop._open_cart()
	shop._on_leave_answered(true)
	for key in keys:
		expect(before[key], key, "", "shop quit: %s nothing" % key, id)
	check(not log.is_open(), "quitting closes the question")
	shop.panel.hide_dialogue()
	await frames(2)

## A family relation question answered wrong then right; a non-relation question opens none.
func family_game(game) -> void:
	var family = game.get_node_or_null("FamilySession")
	check(family != null, "family session exists")
	if family == null:
		return
	# Word memory (word_memory.gd, 24 Nov 2026) allows a new word only every few practice steps,
	# and the grocery orders above have just brought new ones: Hospital Helper's relation question
	# (all new words here) would then lose to its untracked kinds, which record no step, so it
	# would never come. Start as a learner who met no new word lately (updated 25 Nov 2026).
	preload("res://scripts/learning/word_memory.gd").shared()._memory().last_new = -1000
	family.open_game()
	var found := false
	for i in 60:
		if str(family.question.get("kind", "")) == "relation":
			found = true
			break
		check(not log.is_open(), "a %s question is not tracked" % family.question.get("kind", ""))
		family.next_question()
	check(found, "a relation question came up")
	if not found:
		return
	var word: String = family.question.word
	check(log.game_id() == "family_dr_li", "a relation question begins a question")
	var before := now(word, "family_dr_li")
	var wrong := ""
	for person in family.tree.people:
		if person != str(family.question.answer):
			wrong = person
			break
	family._on_answer(wrong)
	family._on_answer(str(family.question.answer))
	expect(before, word, "negative", "family: wrong then right -> negative", "family_dr_li")
	check(not log.is_open(), "solving completes the question")
	# Next relation question with the panel's bubble on: translated.
	for i in 60:
		family.next_question()
		if str(family.question.get("kind", "")) == "relation":
			break
	if str(family.question.get("kind", "")) == "relation":
		word = family.question.word
		before = now(word, "family_dr_li")
		_peek(true)
		await frames(2)
		family._on_answer(str(family.question.answer))
		expect(before, word, "translated", "family: bubble on -> translated", "family_dr_li")
		_peek(false)
	family.next_question()
	family.close_game()
	check(not log.is_open(), "closing the game leaves no open question")

## A restaurant order with a wrong first dish (negative), then one sent with the bubble on
## (translated). Since 11 Nov 2026 a visit asks 2-3 courses and one Send answers them all.
func restaurant_game(game) -> void:
	var session = game.get_node_or_null("RestaurantSession")
	check(session != null, "restaurant session exists")
	if session == null:
		return
	const Orders := preload("res://scripts/learning/restaurant_orders.gd")
	session.open_game()
	session.open_tablet()
	var id := "restaurant_twinkle"
	var picks := _restaurant_picks(session, Orders, true)
	var word := str(Orders.dish(str(session.requests[0].target)).word)
	check(log.game_id() == id, "an order begins a question")
	var before := now(word, id)
	session._on_send(picks)
	expect(before, word, "negative", "restaurant: wrong first dish -> negative", id)
	check(not log.is_open(), "sending the order completes the question")
	session._next_visit()
	session.open_tablet()
	picks = _restaurant_picks(session, Orders, false)
	word = str(Orders.dish(str(session.requests[0].target)).word)
	before = now(word, id)
	_peek(true)
	await frames(2)
	session._on_send(picks)
	expect(before, word, "translated", "restaurant: bubble on -> translated", id)
	_peek(false)
	session._next_visit()
	session.open_tablet()
	check(log.game_id() == id, "the next order begins a question")
	session._end_game()
	check(not log.is_open(), "ending the game abandons the open question")
	await frames(2)

## The target dish of every course asked; with `first_wrong` another dish for the first.
func _restaurant_picks(session, Orders, first_wrong: bool) -> Dictionary:
	var picks := {}
	for k in session.requests.size():
		var request: Dictionary = session.requests[k]
		picks[str(request.course)] = str(request.target)
		if k == 0 and first_wrong:
			for entry in session.orders.menu[str(request.course)]:
				if str(entry.id) != str(request.target):
					picks[str(request.course)] = str(entry.id)
					break
	return picks

func _warehouse_tracked(session) -> bool:
	var task: Dictionary = session.tasks[session.current]
	return str(task.get("item", "")) != "" and task.get("kind", "") != "color"

## Finishes the current task and skips the card's praise (since 8 Nov 2026 the next task, and
## its question, shows only after PRAISE_SECONDS).
func _warehouse_done(session) -> void:
	session.task_done()
	if session.in_game() and session._praise_left > 0.0:
		session._praise_left = 0.0
		session._show_task()

## Advances to a task that names a thing (finished tasks before it count as done).
func _warehouse_next_tracked(session) -> bool:
	for i in 4:
		if not session.in_game():
			return false
		if _warehouse_tracked(session):
			return true
		check(not log.is_open(), "an untracked warehouse task opens no question")
		_warehouse_done(session)
	return session.in_game() and _warehouse_tracked(session)

## A warehouse task with a wrong attempt (negative), one with the card's bubble (translated),
## then leaving the game (nothing).
## The word followed is the task's colour (the boxes have no word of their own since 21 Nov
## 2026; since 25 Nov a wrong box misses the colour and the position word is judged apart).
func warehouse_game(game) -> void:
	var session = game.get_node_or_null("WarehouseSession")
	check(session != null, "warehouse session exists")
	if session == null:
		return
	var id := "warehouse_ramon"
	var tested := {"wrong": false, "bubble": false}
	for attempt in 4:
		if tested.wrong and tested.bubble:
			break
		await session.start_game()
		if not _warehouse_next_tracked(session):
			if session.in_game():
				await session.end_game("")
			continue
		var task: Dictionary = session.tasks[session.current]
		var word: String = str(session.writer.words(task)[0])
		check(log.game_id() == id, "a task naming %s begins a question" % word)
		var before := now(word, id)
		if not tested.wrong:
			session._wrong("warehouse.wrong_thing", {"item": {"phrase": "warehouse.thing_" + str(task.item)}}, "thing")
			session._close_dialogue()
			_warehouse_done(session)
			expect(before, word, "negative", "warehouse: wrong attempt then done -> negative", id)
			tested.wrong = true
			if not _warehouse_next_tracked(session):
				if session.in_game():
					await session.end_game("")
				continue
			task = session.tasks[session.current]
			word = str(session.writer.words(task)[0])
			before = now(word, id)
		_peek(true)
		await frames(2)
		_warehouse_done(session)
		expect(before, word, "translated", "warehouse: card bubble on -> translated", id)
		tested.bubble = true
		_peek(false)
		await frames(2)
		if session.in_game():
			check(not _warehouse_tracked(session) or log.game_id() == id, "the next task begins its question")
			await session.end_game("")
			check(not log.is_open(), "leaving the warehouse abandons the open question")
	check(tested.wrong and tested.bubble, "warehouse: both rows tested")
	await frames(2)

## Advances to a flight question that names a country and has a tracked time word
## (redesign of 7 Nov 2026: the time expression's word key and the country are tested).
func _flight_tracked_question(session) -> bool:
	for i in 60:
		var keys: Dictionary = session._tested(session.question)
		if keys.is_empty():
			check(not log.is_open(), "a flight question without tracked words opens no question")
		elif str(session.question.get("country", "")) != "" and keys.size() == 2:
			return true
		session.next_question()
	return false

## Three first taps on questions naming a country: a near miss (same country and tense, other
## time: time word negative, country positive), a flight to another country that does not fit
## the time (both negative), the target (both positive); then the bubble (translated).
func flight_game(game) -> void:
	var session = game.get_node_or_null("FlightSession")
	check(session != null, "flight session exists")
	if session == null:
		return
	var id := "flight_bruno"
	session.open_game()
	var rows := {"near miss": false, "other country": false, "right": false}
	for round in 40:
		if not rows.values().has(false):
			break
		if not _flight_tracked_question(session):
			break
		var question: Dictionary = session.question
		var country := str(question.country)
		var word: String = FlightQuestions.time_key(question)
		var target := str(question.target)
		check(log.game_id() == id, "a tracked flight question begins a question")
		var near: Array = session.questions.near_misses(question)
		var other := ""
		for flight in session.schedule.flights:
			if str(flight.country) != country and not session.questions.time_right(question, flight):
				other = flight.id
				break
		var before_word := now(word, id)
		var before_country := now(country, id)
		if not rows["near miss"] and not near.is_empty():
			session._on_flight(str(near[0].id))
			session._on_flight(target)
			expect(before_word, word, "negative", "flight: near miss first -> time word negative", id)
			expect(before_country, country, "positive", "flight: near miss first -> country positive", id)
			rows["near miss"] = true
		elif not rows["other country"] and other != "":
			session._on_flight(other)
			session._on_flight(target)
			expect(before_word, word, "negative", "flight: other country, other time first -> time word negative", id)
			expect(before_country, country, "negative", "flight: other country, other time first -> country negative", id)
			rows["other country"] = true
		else:
			session._on_flight(target)
			expect(before_word, word, "positive", "flight: right first -> time word positive", id)
			expect(before_country, country, "positive", "flight: right first -> country positive", id)
			rows["right"] = true
		session.next_question()
	check(not rows.values().has(false), "flight: all first-tap rows tested %s" % [rows])
	if _flight_tracked_question(session):
		var country := str(session.question.country)
		var word: String = FlightQuestions.time_key(session.question)
		var before_word := now(word, id)
		var before_country := now(country, id)
		_peek(true)
		await frames(2)
		session._on_flight(str(session.question.target))
		expect(before_word, word, "translated", "flight: bubble on -> time word translated", id)
		expect(before_country, country, "translated", "flight: bubble on -> country translated", id)
		_peek(false)
		await frames(2)
	session.next_question()
	session._on_finish()
	check(not log.is_open(), "finishing the flight game leaves no open question")
	session.panel.hide_panel()
	game.shop_panel.hide_dialogue()
	await frames(2)

## Sits the player on grammar answer chair `letter` (as the grammar class check does).
func _sit(game, session, letter: String) -> bool:
	var chair: Node3D = session.desks[letter].chair
	if game.player.seated:
		game.seating.stand()
		for i in 40:
			await physics_frame
			if not game.player.sit_transition:
				break
	game.player.global_position = chair.global_position + session.school.global_basis * Vector3(.8, .1, 0)
	game.player.velocity = Vector3.ZERO
	await physics_frame
	# The chair's own interactable (as seating.try_sit() was until 12 Nov 2026): this check's
	# panels lock the player's controls, which E (activate_focus) respects.
	var seat: Node = Interactable.on(chair)
	var ok: bool = seat != null and seat.check() == true and seat.activate() == ""
	for i in 40:
		await physics_frame
		if not game.player.sit_transition:
			break
	return ok and game.player.seated and is_same(game.seating.current.node, chair)

func _desk_of(session, answer: String, right: bool) -> String:
	for letter in session.on_desk:
		if (str(session.on_desk[letter]) == answer) == right:
			return letter
	return ""

## A Chinese class: a measure-word question answered wrong (negative), one right (positive),
## one unanswered (nothing), one with the card's bubble (translated). Spanish questions have
## no noun and open no question.
func grammar_game(game) -> void:
	var session = game.get_node_or_null("GrammarSession")
	check(session != null, "grammar session exists")
	if session == null:
		return
	var id := "grammar_lana"
	var settings = GameSettings.shared()
	var native: String = settings.native
	var foreign: String = settings.foreign
	session.offered = true
	await session.start_class()
	await frames(3)
	check(session.in_class() and not log.is_open(), "a %s class question opens no question" % foreign)
	session.end_class("")
	settings.set_languages(native, "zh")
	lang = "zh"
	session.offered = true
	await session.start_class()
	await frames(3)
	var rows := ["negative", "positive", "", "translated"]
	for outcome in rows:
		if not session.in_class() or session.state != "question":
			break
		var question: Dictionary = session.questions[session.current]
		var word := str(question.get("noun", ""))
		check(word != "" and log.game_id() == id, "a Chinese question tests its noun %s" % word)
		var before := now(word, id)
		if outcome == "translated":
			_peek(true)
			await frames(2)
		if outcome != "":
			var ok: bool = await _sit(game, session, _desk_of(session, str(question.answer), outcome != "negative"))
			check(ok, "seated for the %s row" % outcome)
		elif game.player.seated:
			game.seating.stand()
			for i in 40:
				await physics_frame
				if not game.player.sit_transition:
					break
		session.submit()
		expect(before, word, outcome, "grammar zh: %s" % (outcome if outcome != "" else "unanswered -> nothing"), id)
		if outcome == "translated":
			_peek(false)
		session._next_question()
		await frames(2)
	check(log.game_id() == id, "the next Chinese question is open")
	session.end_class("")
	check(not log.is_open(), "ending the class abandons the open question")
	if game.player.seated:
		game.seating.stand()
	settings.set_languages(native, foreign)
	lang = foreign
	await frames(2)
