extends SceneTree
## Minigame progression (user approval 18 Nov 2026; docs/guides/MINIGAMES.md#progression).
## Checks: stars from first-try share (default and Grocery Run's "stars_at"); unlocks only on 3
## stars at the highest level and never from a picker-rounds ("custom") session; an old save
## (no game_progress.json) starts at level 1; Grocery Run level 3 orders 3 items from the first
## three price tiers, one basket turned down at the till = 2 stars, a clean order 3 stars and a
## level up shown on the star card; the greeting shows the level badge; the picker shows level
## pills and a level stepper capped at the unlocked level; the save file holds the record per
## learned language. Pay Up! was retired into the Grocery Run checkout on 21 Nov 2026 (this check
## used it until then; the checkout itself: docs/evidence/grocery-checkout-20261121/verify.gd).
## With graphics it also saves picker.png, greeting.png and star-card.png in this folder.
## LEARN-06 (25 Nov 2026, D11 "all designed levels"): designed_levels() checks every other
## learning game's levels without the town (Who's Who?, Flight Finder, On the Menu, Spot the
## Suspect, Feel the Clues, Desk Dash, Mystery Doors; the board's level round counts) and
## town_levels() the two that need it (Library Helper's cart, Wire It Up!'s wires). Stack &
## Pack's level plans are in docs/evidence/warehouse-20261114/verify_game.gd.
## Uses Main, which saves progress: run with an isolated HOME (README; tools/run_checks.py does).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/minigame-progression-20261118/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const Order := preload("res://scripts/learning/shop_order.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const HERE := "res://docs/evidence/minigame-progression-20261118/"
const SHOP := "shop_supermarket"
## The learning game that still has no levels (Next, Please! progresses within a session).
const PLAIN := "teller_bank"
const FamilyTree := preload("res://scripts/learning/family_tree.gd")
const FamilyQuestions := preload("res://scripts/learning/family_questions.gd")
const FlightSchedule := preload("res://scripts/learning/flight_schedule.gd")
const FlightQuestions := preload("res://scripts/learning/flight_questions.gd")
const GameClock := preload("res://scripts/learning/game_clock.gd")
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const Clues := preload("res://scripts/learning/detective_clues.gd")
const Grammar := preload("res://scripts/learning/grammar_questions.gd")
const Mystery := preload("res://scripts/learning/mystery_session.gd")
var failures := 0
var checks := 0
var game

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func seconds(s: float) -> void:
	await create_timer(s).timeout

func graphics() -> bool:
	return DisplayServer.get_name() != "headless"

func shot(file: String) -> void:
	if not graphics():
		return
	await frames(4)
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(HERE + file))
	print("saved " + file)

func run():
	logic()
	designed_levels()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	await seconds(1.0)
	Progress.shared().data = {}
	await grocery()
	await town_levels()
	await picker()
	saved_file()
	finish()

# --- Rules without the town -----------------------------------------------------------------

func logic() -> void:
	check(not FileAccess.file_exists(SaveStore.path(Progress.FILE)), "isolated HOME: no progress file yet (old save)")
	var p = Progress.shared()
	check(SaveStore.PROFILE_FILES.has(Progress.FILE), "progress is a per-profile save file")
	check(p.count(SHOP) == 4 and not Board.shared().has("cashier_supermarket"), "Grocery Run has 4 levels; Pay Up! is retired")
	check(not p.has_levels(PLAIN) and p.params(PLAIN).is_empty(), "a game without levels has none")
	check(p.level(SHOP) == 1 and p.unlocked(SHOP) == 1 and p.best(SHOP, 1) == 0, "an old save starts at level 1")
	check(p.stars_for("family_dr_li", 5, 0) == 3 and p.stars_for("family_dr_li", 5, 1) == 2 and p.stars_for("family_dr_li", 5, 3) == 2 and p.stars_for("family_dr_li", 5, 4) == 1, "default stars: 0 misses 3, 1-3 misses 2, 4 misses 1 (of 5)")
	check(p.stars_for(SHOP, 1, 0) == 3 and p.stars_for(SHOP, 1, 1) == 2 and p.stars_for(SHOP, 1, 2) == 1, "Grocery Run stars: right first 3, one miss 2, two 1")
	# Unlock rules (then forget them: the town part starts clean).
	var r: Dictionary = p.record(SHOP, 1, 0, true)
	check(r.stars == 3 and not r.level_up and p.unlocked(SHOP) == 1, "picker rounds: stars, no unlock")
	r = p.record(SHOP, 1, 1)
	check(r.stars == 2 and not r.level_up and p.level(SHOP) == 1, "2 stars: no unlock")
	r = p.record(SHOP, 1, 0)
	check(r.level_up and p.level(SHOP) == 2 and p.unlocked(SHOP) == 2 and p.best(SHOP, 1) == 3, "3 stars at the top unlocked level: level 2")
	p.set_level(SHOP, 1)
	r = p.record(SHOP, 1, 0)
	check(not r.level_up and p.unlocked(SHOP) == 2 and p.level(SHOP) == 1, "3 stars on a lower level: no new unlock")
	p.set_level(SHOP, 9)
	check(p.level(SHOP) == 2, "the level is capped at the unlocked one")
	for i in 5:
		p.record(SHOP, 1, 0)
	check(p.unlocked(SHOP) == 4 and p.level(SHOP) == 4, "the last level is the top")
	p.data = {}

# --- Designed levels (LEARN-06) -------------------------------------------------------------

## The level `n` settings of `id` (1-based).
func level_of(id: String, n: int) -> Dictionary:
	return Progress.shared().level_list(id)[n - 1]

func designed_levels() -> void:
	var p = Progress.shared()
	var board = Board.shared()
	var counts := {}
	for id in board.activities:
		if board.kind(id) == "learning" or p.has_levels(id):
			counts[id] = p.count(id)
	check(counts == {"shop_supermarket": 4, "family_dr_li": 4, "warehouse_ramon": 4, "flight_bruno": 4, "restaurant_twinkle": 4,
			"lineup_rocco": 4, "evidence_mimi": 4, "grammar_lana": 4, "mystery_luna": 4, "library_rosa": 4, "teller_bank": 0,
			"feeding_nico": 4, "electrical_box": 3}, "every designed game has its levels: %s" % [counts])
	check(not p.has_levels("mahjong_mei") and not p.has_levels("radar_patrol"), "the pastimes Mahjong Club and Radar Patrol have none")
	# The board: a level's round count, unless the picker chose another number.
	board.begin("family_dr_li", 10)
	check(board.target("family_dr_li") == 10 and not board._began["family_dr_li"].custom, "a level's 10 questions replace the data's 20")
	board.set_rounds("family_dr_li", 20)
	board.begin("family_dr_li", 10)
	check(board.target("family_dr_li") == 10 and not board._began["family_dr_li"].custom, "the picker's unchanged rounds (the data's 20) keep the level's 10")
	board.set_rounds("family_dr_li", 7)
	board.begin("family_dr_li", 10)
	check(board.target("family_dr_li") == 7 and board._began["family_dr_li"].custom, "rounds changed in the picker win and count as custom")
	board.set_rounds("family_dr_li", 0)
	board.begin("family_dr_li")
	check(board.target("family_dr_li") == 20, "no level count: the data's 20")
	board.begin("electrical_box")
	check(not board._completed("electrical_box"), "a pastime is not completed by itself")
	board.complete("electrical_box")
	check(board._completed("electrical_box"), "complete() finishes a pastime (Wire It Up!)")
	board.begin("electrical_box")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261125
	# Who's Who?: L1 relations only, L2 adds ages but no birthdays, L4 more yes/no traps.
	for n in [1, 2, 4]:
		var kinds: Dictionary = level_of("family_dr_li", n).get("kinds", {})
		var seen := {}
		var made := 0
		for i in 60:
			if i % 3 == 0:
				var tree = FamilyTree.new()
				tree.setup(FamilyTree.template_ids()[i % FamilyTree.template_ids().size()], {"f": Lexicon.shared().names(Lexicon.shared().foreign, "f"), "m": Lexicon.shared().names(Lexicon.shared().foreign, "m")}, rng)
				seen["_tree"] = tree
			var kind := FamilyQuestions.pick_kind(rng, "", kinds)
			seen[kind] = int(seen.get(kind, 0)) + 1
			if not FamilyQuestions.generate(seen["_tree"], kind, rng).is_empty():
				made += 1
		seen.erase("_tree")
		check(seen.keys().all(func(k): return kinds.has(k)) and made >= 54, "Who's Who? L%d asks only %s (%d of 60 made): %s" % [n, kinds.keys(), made, seen])
	check(int(level_of("family_dr_li", 1).questions) == 10 and int(level_of("family_dr_li", 2).questions) == 10 and not level_of("family_dr_li", 3).has("questions"), "Who's Who? L1-L2 10 questions, L3 (today) 20")
	# Flight Finder: every level builds valid boards; L1-L2 never name anteayer or pasado mañana.
	var clock = GameClock.new()
	var lex = Lexicon.shared()
	for n in 4:
		var level: Dictionary = level_of("flight_bruno", n + 1)
		var made := 0
		var tries := 0
		var bad: Array = []
		for i in 24:
			clock.roll(rng)
			var kind := FlightQuestions.pick_kind(rng, "", level.get("kinds", {}))
			var schedule = FlightSchedule.new()
			schedule.setup(clock, rng)
			var questions = FlightQuestions.new(schedule, lex)
			questions.level = level
			tries += 1
			var q: Dictionary = questions.design(kind, rng)
			if q.is_empty():
				continue
			made += 1
			var off: int = schedule.offset(schedule.by_id(str(q.target)))
			if questions.count_matches(q) != 1:
				bad.append("%s: %d matches" % [kind, questions.count_matches(q)])
			if level.has("kinds") and not level.kinds.has(kind):
				bad.append("kind " + kind)
			if level.has("days") and kind in ["day", "clock"] and absi(off) > 1:
				bad.append("%s day %d" % [kind, off])
			if float(level.get("named_chance", .5)) == 0.0 and str(q.country) != "":
				bad.append("named " + kind)
			if questions.decoys(q).size() < int(level.get("min_decoys", 2)):
				bad.append("%s: %d decoys" % [kind, questions.decoys(q).size()])
		check(bad.is_empty() and made >= tries - 2, "Flight Finder L%d: %d of %d boards built, each with one answer and the level's kinds and days: %s" % [n + 1, made, tries, bad.slice(0, 4)])
	# On the Menu: L1 one need per course, L4 three (where the menu allows), L3/L4 three courses.
	for n in [1, 3, 4]:
		var level: Dictionary = level_of("restaurant_twinkle", n)
		var orders = Orders.new(rng, level.get("difficulty", {}))
		var sizes := {}
		var negations := 0
		var empty := 0
		for i in 40:
			if i % 4 == 0:
				orders.new_menu()
			var order: Dictionary = orders.make_order(str(Orders.courses()[i % Orders.courses().size()]))
			if order.is_empty():
				empty += 1
				continue
			sizes[order.reqs.size()] = int(sizes.get(order.reqs.size(), 0)) + 1
			if order.reqs.any(func(r): return Orders.is_negative(r)):
				negations += 1
		var shape_ok: bool = sizes.keys() == [1] if n == 1 else (sizes.get(3, 0) >= 20 if n == 4 else negations > 0)
		check(empty == 0 and shape_ok, "On the Menu L%d: needs per order %s, %d with no / sin, %d without an order" % [n, sizes, negations, empty])
	var ints := func(list: Array) -> Array: return list.map(func(v): return int(v))
	check(ints.call(level_of("restaurant_twinkle", 1).courses) == [2, 2] and ints.call(level_of("restaurant_twinkle", 3).courses) == [3, 3] and level_of("restaurant_twinkle", 2).is_empty(), "On the Menu: L1 two courses, L2 today (2-3), L3-L4 three")
	# Spot the Suspect and Feel the Clues.
	var clues = Clues.new()
	clues.set_level(level_of("lineup_rocco", 1))
	var lineup_bad: Array = []
	for i in 12:
		var round: Dictionary = clues.generate_lineup(rng)
		if round.candidates.size() != 4 or round.clues.size() != 2 or round.clues.any(func(c): return c.has("not")) or Clues.validate(round) != "":
			lineup_bad.append(round.get("clues", []).map(func(c): return c.id))
	check(lineup_bad.is_empty(), "Spot the Suspect L1: 4 suspects, 2 clues, no negation: %s" % [lineup_bad.slice(0, 3)])
	clues.reset()
	clues.set_level(level_of("lineup_rocco", 4))
	lineup_bad.clear()
	for i in 12:
		var round: Dictionary = clues.generate_lineup(rng)
		if round.is_empty() or round.candidates.size() != 5 or round.clues.size() != 3 or Clues.validate(round) != "":
			lineup_bad.append(round.get("clues", []).map(func(c): return c.id))
	check(lineup_bad.is_empty(), "Spot the Suspect L4: 5 suspects (the room's five spots), 3 clues: %s" % [lineup_bad.slice(0, 3)])
	check(lex.phrase("police.lineup_three", "es", {"a": {"phrase": "police.s_tall"}, "b": {"phrase": "police.s_beard"}, "c": {"phrase": "police.s_bald"}}).count(",") == 1, "the three-clue line renders: " + lex.phrase("police.lineup_three", "es", {"a": {"phrase": "police.s_tall"}, "b": {"phrase": "police.s_beard"}, "c": {"phrase": "police.s_bald"}}))
	var evidence = Clues.new()
	for n in [1, 4]:
		evidence.reset()
		evidence.set_level(level_of("evidence_mimi", n))
		var want := 3 if n == 1 else 5
		var ev_bad: Array = []
		for i in 8:
			var type: String = evidence.round_type(i)
			var round: Dictionary = evidence.generate_evidence(rng, type)
			if (n == 1 and type != "find") or (type == "find" and round.get("candidates", []).size() != want) or Clues.validate(round) != "":
				ev_bad.append("%s %d" % [type, round.get("candidates", []).size()])
		check(ev_bad.is_empty(), "Feel the Clues L%d: %s rounds, %d objects to find among: %s" % [n, "find" if n == 1 else "find and report", want, ev_bad.slice(0, 3)])
	# Desk Dash: seconds per level; harder questions first, the bank fills the rest.
	check(level_of("grammar_lana", 1).seconds == 15 and level_of("grammar_lana", 2).seconds == 10 and level_of("grammar_lana", 4).seconds == 7, "Desk Dash: 15, 10, 10 and 7 seconds")
	var bank = Grammar.new()
	bank.load_bank("es")
	check(bank.pick(5, rng, 2).size() == 5, "Desk Dash L3: a full class while the bank has no harder questions")
	# Mystery Doors: L1 4 colour doors in the basic colours, L4 8 doors of combined clues.
	var basic: Array = level_of("mystery_luna", 1).colors
	var rounds: Array = Mystery.make_rounds(4, rng, [], level_of("mystery_luna", 1).kinds, basic)
	check(rounds.size() == 4 and rounds.all(func(r): return r.kind == "color" and r.doors.all(func(d): return basic.has(d[0]))), "Mystery Doors L1: 4 colour clues, basic colours only")
	rounds = Mystery.make_rounds(int(level_of("mystery_luna", 4).doors), rng, [], level_of("mystery_luna", 4).kinds)
	check(rounds.size() == 8 and rounds.all(func(r): return r.kind == "both"), "Mystery Doors L4: 8 doors, combined clues only")
	rounds = Mystery.make_rounds(6, rng, [["purple", "star"], ["red", "circle"], ["blue", "square"]], [], basic)
	check(rounds[0].doors.all(func(d): return basic.has(d[0])), "Mystery Doors L2: the room's purple door is not kept in a basic-colour game")

# --- Library Helper and Wire It Up! in town ---------------------------------------------------

func town_levels() -> void:
	var p = Progress.shared()
	# Grocery Run's records stay for the picker and save checks below.
	var kept: Dictionary = p.data.duplicate(true)
	var Library := preload("res://scripts/learning/library_session.gd")
	var library = Board.shared().session("library_rosa")
	check(library != null, "Library Helper is in town")
	if library != null and not library.playing:
		for n in [1, 4]:
			p.data = {}
			for i in n - 1:
				p.record("library_rosa", 1, 0)
			library._fill_cart()
			var plain: bool = library.books.all(func(b): return b.spine_color == Library.PLAIN_SPINE)
			var want: int = 3 if n == 1 else 6
			check(library.books.size() == want and plain == (n == 4), "Library Helper L%d: %d books, plain spines %s" % [n, library.books.size(), plain])
		p.data = {}
		library._fill_cart()
	var box_session = Board.shared().session("electrical_box")
	check(box_session != null, "Wire It Up! is in town")
	if box_session != null:
		for n in [1, 3]:
			p.data = {}
			for i in n - 1:
				p.record("electrical_box", 1, 0)
			box_session.launch()
			await seconds(1.5)
			check(box_session.panel.wires.size() == (3 if n == 1 else 6), "Wire It Up! L%d: %d wires" % [n, box_session.panel.wires.size()])
			box_session._on_solved()
			check(Board.shared()._completed("electrical_box"), "a repaired box completes the opening")
			await seconds(2.5)
	p.data = kept
	p.save()

# --- Grocery Run ----------------------------------------------------------------------------

func grocery() -> void:
	var s = Board.shared().session(SHOP)
	check(s != null, "the grocery clerk is loaded")
	if s == null:
		return
	var p = Progress.shared()
	# The greeting shows the level badge.
	s.host.offer()
	await frames(2)
	check(game.shop_panel.level_badge.visible and game.shop_panel.level_label.text != "", "the greeting shows the level badge: " + game.shop_panel.level_label.text)
	if graphics():
		var forward: Vector3 = -s.clerk.global_basis.z
		forward.y = 0.0
		game.player.global_position = s.clerk.global_position + forward.normalized() * 2.5 + Vector3(0, .1, 0)
		await seconds(1.0)
		s.host.offer()
		await shot("greeting.png")
	s.host.close_dialogue()
	await frames(2)
	check(not game.shop_panel.level_badge.visible or not game.shop_panel.is_dialogue_visible(), "the badge goes with the line")
	# Level 3: three items from the first three price tiers, paid at the till.
	p._store(SHOP, {"level": 3, "unlocked": 3})
	await grocery_order(s, true)
	check(p.best(SHOP, 3) == 2 and p.level(SHOP) == 3, "Grocery Run with one basket turned down: 2 stars at level 3")
	check(game.star_card.visible and int(game.star_card.shown.get("stars", 0)) == 2, "the star card shows 2 stars")
	game.star_card.visible = false
	await grocery_order(s, false)
	check(p.best(SHOP, 3) == 3 and p.level(SHOP) == 4, "a clean order: 3 stars, level 4")
	check(game.star_card.visible and bool(game.star_card.shown.get("level_up", false)) and game.star_card.note.text != "", "the star card says level up: " + game.star_card.note.text)
	await shot("star-card.png")
	game.star_card.visible = false
	# Level 1 is today's game: 2 fruit and vegetables.
	p.set_level(SHOP, 1)
	s.start_game()
	check(s.order.order.size() == 2 and s.pool.size() == 16, "level 1 is today's order (2 of 16 fruit and vegetables)")
	s.end_activity()
	s.host.close_dialogue()
	await frames(3)

## One order at the current level: (a basket turned down at the till first,) the exact basket
## paid and brought back to the clerk.
func grocery_order(s, one_wrong: bool) -> void:
	var till = game.get_node("CashierSession_supermarket")
	s.start_game()
	check(s.order.order.size() == 3, "level 3 orders 3 items (%d)" % s.order.order.size())
	check(s.pool.size() == Order.tier_words(s.rules, 3).size(), "level 3 orders from three price tiers (%d)" % s.pool.size())
	s.host.close_dialogue()
	await frames(2)   # the board's watch() runs once a frame: let it see the order start
	var keys: Array = s.order.order.keys()
	if one_wrong:
		for key in keys.slice(1):
			for i in int(s.order.order[key]):
				s.order.add_to_cart(key)
		till._talk()
		check(Board.shared().misses(SHOP) == 1 and till.paying_for == "", "a basket that is not the list is a miss")
		till.host.close_dialogue()
	s.order.cart = {}
	for key in keys:
		for i in int(s.order.order[key]):
			s.order.add_to_cart(key)
	till._talk()
	till._open_money()
	game.money_panel.counts = {"coin_1": till.due_cents}
	till._on_submitted(till.due_cents)
	till.host.close_dialogue()
	s._host_talk(s.clerk)
	s.host.close_dialogue()
	await frames(3)

# --- Picker ---------------------------------------------------------------------------------

func picker() -> void:
	var launcher = game.game_launcher
	launcher.open()
	await frames(3)
	var pay_row: Dictionary = {}
	var family_row: Dictionary = {}
	for row in launcher._rows:
		if row.id == SHOP:
			pay_row = row
		if row.id == PLAIN:
			family_row = row
	check(pay_row.has("badge") and pay_row.level.text != "", "Grocery Run's tile shows its level: " + str(pay_row.get("level", Label.new()).text))
	check(not family_row.has("badge"), "a game without levels has no pill")
	launcher._show_tab("learning")
	launcher._select(SHOP)
	check(launcher._d_level.visible and launcher.level_count.text == "1", "the level stepper shows level 1")
	check(launcher.level_minus.disabled and not launcher.level_plus.disabled, "- stops at level 1")
	check(launcher.level_minus.custom_minimum_size.y >= 52.0, "the level buttons are large targets")
	for i in 4:
		launcher._step_level(SHOP, 1)
	check(Progress.shared().level(SHOP) == 4 and launcher.level_count.text == "4" and launcher.level_plus.disabled, "+ stops at the unlocked level 4")
	await shot("picker.png")
	launcher._select(PLAIN)
	check(not launcher._d_level.visible, "no level stepper for a game without levels")
	launcher.close()
	await frames(2)

func saved_file() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(Progress.FILE))
	var language: String = Lexicon.shared().foreign
	check(parsed is Dictionary and parsed.has(language) and parsed[language].has(SHOP), "game_progress.json holds Grocery Run under the learned language")
	if parsed is Dictionary and parsed.has(language):
		var shop: Dictionary = parsed[language].get(SHOP, {})
		check(int(shop.get("unlocked", 0)) == 4 and int(shop.get("plays", 0)) == 2, "saved: 2 plays, level 4 unlocked")

func finish() -> void:
	print("MINIGAME PROGRESSION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
