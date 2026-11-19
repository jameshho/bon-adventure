extends SceneTree
## Minigame progression (user approval 18 Nov 2026; docs/guides/MINIGAMES.md#progression).
## Checks: stars from first-try share (default and Grocery Run's "stars_at"); unlocks only on 3
## stars at the highest level and never from a picker-rounds ("custom") session; an old save
## (no game_progress.json) starts at level 1; Pay Up! amounts follow the level (range and step);
## a whole Pay Up! session with one miss earns 2 stars, a clean one 3 stars and a level up shown on
## the star card; Grocery Run level 3 orders 3 items from every product, one retry = 2 stars;
## the greeting shows the level badge; the picker shows level pills and a level stepper capped at
## the unlocked level; the save file holds the record per learned language.
## With graphics it also saves picker.png, greeting.png and star-card.png in this folder.
## Uses Main, which saves progress: run with an isolated HOME (README; tools/run_checks.py does).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/minigame-progression-20261118/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const HERE := "res://docs/evidence/minigame-progression-20261118/"
const PAY := "cashier_supermarket"
const SHOP := "shop_supermarket"
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
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	await seconds(1.0)
	Progress.shared().data = {}
	await pay_up()
	await grocery()
	await picker()
	saved_file()
	finish()

# --- Rules without the town -----------------------------------------------------------------

func logic() -> void:
	check(not FileAccess.file_exists(SaveStore.path(Progress.FILE)), "isolated HOME: no progress file yet (old save)")
	var p = Progress.shared()
	check(SaveStore.PROFILE_FILES.has(Progress.FILE), "progress is a per-profile save file")
	check(p.count(PAY) == 4 and p.count(SHOP) == 4, "Pay Up! and Grocery Run have 4 levels")
	check(not p.has_levels("family_dr_li") and p.params("family_dr_li").is_empty(), "a game without levels has none")
	check(p.level(PAY) == 1 and p.unlocked(PAY) == 1 and p.best(PAY, 1) == 0, "an old save starts at level 1")
	check(p.stars_for(PAY, 5, 0) == 3 and p.stars_for(PAY, 5, 1) == 2 and p.stars_for(PAY, 5, 3) == 2 and p.stars_for(PAY, 5, 4) == 1, "Pay Up! stars: 0 misses 3, 1-3 misses 2, 4 misses 1")
	check(p.stars_for(SHOP, 1, 0) == 3 and p.stars_for(SHOP, 1, 1) == 2 and p.stars_for(SHOP, 1, 2) == 1, "Grocery Run stars: right first 3, one retry 2, two 1")
	# Amounts by level.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ok_whole := true
	var ok_quarter := true
	var ok_full := true
	for i in 400:
		var a := Currency.random_cents(rng, 2000, 100)
		ok_whole = ok_whole and a % 100 == 0 and a >= 100 and a <= 2000
		var b := Currency.random_cents(rng, 5000, 25)
		ok_quarter = ok_quarter and b % 25 == 0 and b >= 25 and b <= 5000
		var c := Currency.random_cents(rng)
		ok_full = ok_full and c >= Currency.MIN_CENTS and c <= Currency.MAX_CENTS
	check(ok_whole, "level 1 amounts: whole dollars up to $20")
	check(ok_quarter, "level 2 amounts: quarters up to $50")
	check(ok_full, "no level: today's $0.25 to $300")
	# Unlock rules (then forget them: the town part starts clean).
	var r: Dictionary = p.record(PAY, 5, 0, true)
	check(r.stars == 3 and not r.level_up and p.unlocked(PAY) == 1, "picker rounds: stars, no unlock")
	r = p.record(PAY, 5, 1)
	check(r.stars == 2 and not r.level_up and p.level(PAY) == 1, "2 stars: no unlock")
	r = p.record(PAY, 5, 0)
	check(r.level_up and p.level(PAY) == 2 and p.unlocked(PAY) == 2 and p.best(PAY, 1) == 3, "3 stars at the top unlocked level: level 2")
	p.set_level(PAY, 1)
	r = p.record(PAY, 5, 0)
	check(not r.level_up and p.unlocked(PAY) == 2 and p.level(PAY) == 1, "3 stars on a lower level: no new unlock")
	p.set_level(PAY, 9)
	check(p.level(PAY) == 2, "the level is capped at the unlocked one")
	for i in 5:
		p.record(PAY, 5, 0)
	check(p.unlocked(PAY) == 4 and p.level(PAY) == 4, "the last level is the top")
	p.data = {}

# --- Pay Up! --------------------------------------------------------------------------------

func pay_session(s, miss_round: int) -> void:
	s.start_game()
	for round in 5 + (1 if miss_round >= 0 else 0):
		if round > 0:
			s._new_round()
		s._open_money()
		await frames(1)
		if round == miss_round:
			s.money.counts = {"coin_1": s.request_cents + 1}
			s._on_submitted(s.request_cents + 1)
			check(Board.shared().misses(PAY) == 1, "a wrong hand-over is one miss")
			s._open_money()
			await frames(1)
			s.money.counts = {"coin_1": s.request_cents}
			s._on_submitted(s.request_cents)
			continue
		s.money.counts = {"coin_1": s.request_cents}
		s._on_submitted(s.request_cents)
	s.host.close_dialogue()
	await frames(3)

func pay_up() -> void:
	var s = Board.shared().session(PAY)
	check(s != null, "the cashier is loaded")
	if s == null:
		return
	var p = Progress.shared()
	var amounts_ok := true
	for i in 30:
		s._new_round()
		amounts_ok = amounts_ok and s.request_cents % 100 == 0 and s.request_cents <= 2000
	check(amounts_ok, "Pay Up! level 1 asks whole dollars up to $20")
	s._end_round(false)
	await frames(3)
	await pay_session(s, 2)
	check(p.best(PAY, 1) == 2 and p.level(PAY) == 1, "a session with one miss: 2 stars, still level 1")
	check(game.star_card.visible and int(game.star_card.shown.get("stars", 0)) == 2, "the star card shows 2 stars")
	await pay_session(s, -1)
	check(p.best(PAY, 1) == 3 and p.level(PAY) == 2, "a clean session: 3 stars, level 2")
	check(game.star_card.visible and bool(game.star_card.shown.get("level_up", false)) and game.star_card.note.text != "", "the star card says level up: " + game.star_card.note.text)
	await shot("star-card.png")
	amounts_ok = true
	for i in 30:
		s._new_round()
		amounts_ok = amounts_ok and s.request_cents % 25 == 0 and s.request_cents <= 5000
	check(amounts_ok, "Pay Up! level 2 asks quarters up to $50")
	s._end_round(false)
	s.host.close_dialogue()
	game.star_card.visible = false
	await frames(3)

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
	# Level 3: three items, any product sold in the supermarket.
	p._store(SHOP, {"level": 3, "unlocked": 3})
	s.start_game()
	check(s.order.order.size() == 3, "level 3 orders 3 items (%d)" % s.order.order.size())
	check(s.pool.size() > 16, "level 3 orders from every product (%d)" % s.pool.size())
	s.host.close_dialogue()
	await frames(2)   # the board's watch() runs once a frame: let it see the order start
	# One wrong Done (nothing of the first item), then a right one.
	var keys: Array = s.order.order.keys()
	for key in keys.slice(1):
		for i in int(s.order.order[key]):
			s.order.add_to_cart(key)
	s._on_done()
	s.host.close_dialogue()
	s._host_talk(s.clerk)
	check(Board.shared().misses(SHOP) == 1, "a wrong Done is a miss")
	s._on_choice(s.host.choice_prefix() + "retry_yes")
	for key in s.order.remaining:
		for i in int(s.order.remaining[key]):
			s.order.add_to_cart(key)
	s._on_done()
	s.host.close_dialogue()
	s._host_talk(s.clerk)
	s.host.close_dialogue()
	await frames(3)
	check(p.best(SHOP, 3) == 2 and p.level(SHOP) == 3, "Grocery Run with one retry: 2 stars at level 3")
	game.star_card.visible = false
	# Level 1 is today's game: 2 fruit and vegetables.
	p.set_level(SHOP, 1)
	s.start_game()
	check(s.order.order.size() == 2 and s.pool.size() == 16, "level 1 is today's order (2 of 16 fruit and vegetables)")
	s.end_activity()
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
		if row.id == PAY:
			pay_row = row
		if row.id == "family_dr_li":
			family_row = row
	check(pay_row.has("badge") and pay_row.level.text != "", "Pay Up!'s tile shows its level: " + str(pay_row.get("level", Label.new()).text))
	check(not family_row.has("badge"), "a game without levels has no pill")
	launcher._show_tab("learning")
	launcher._select(PAY)
	check(launcher._d_level.visible and launcher.level_count.text == "2", "the level stepper shows level 2")
	check(launcher.level_plus.disabled and not launcher.level_minus.disabled, "+ stops at the unlocked level")
	check(launcher.level_minus.custom_minimum_size.y >= 52.0, "the level buttons are large targets")
	launcher._step_level(PAY, -1)
	check(Progress.shared().level(PAY) == 1 and launcher.level_count.text == "1", "- picks level 1")
	launcher._step_level(PAY, 1)
	await shot("picker.png")
	launcher._select("family_dr_li")
	check(not launcher._d_level.visible, "no level stepper for a game without levels")
	launcher.close()
	await frames(2)

func saved_file() -> void:
	var parsed: Variant = SaveStore.read_json(SaveStore.path(Progress.FILE))
	var language: String = Lexicon.shared().foreign
	check(parsed is Dictionary and parsed.has(language) and parsed[language].has(PAY), "game_progress.json holds Pay Up! under the learned language")
	if parsed is Dictionary and parsed.has(language):
		var pay: Dictionary = parsed[language].get(PAY, {})
		check(int(pay.get("unlocked", 0)) == 2 and int(pay.get("plays", 0)) == 2, "saved: 2 plays, level 2 unlocked")

func finish() -> void:
	print("MINIGAME PROGRESSION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
