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
## Uses Main, which saves progress: run with an isolated HOME (README; tools/run_checks.py does).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/minigame-progression-20261118/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Progress := preload("res://scripts/learning/game_progress.gd")
const Order := preload("res://scripts/learning/shop_order.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const HERE := "res://docs/evidence/minigame-progression-20261118/"
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
	await grocery()
	await picker()
	saved_file()
	finish()

# --- Rules without the town -----------------------------------------------------------------

func logic() -> void:
	check(not FileAccess.file_exists(SaveStore.path(Progress.FILE)), "isolated HOME: no progress file yet (old save)")
	var p = Progress.shared()
	check(SaveStore.PROFILE_FILES.has(Progress.FILE), "progress is a per-profile save file")
	check(p.count(SHOP) == 4 and not Board.shared().has("cashier_supermarket"), "Grocery Run has 4 levels; Pay Up! is retired")
	check(not p.has_levels("family_dr_li") and p.params("family_dr_li").is_empty(), "a game without levels has none")
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
		if row.id == "family_dr_li":
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
	launcher._select("family_dr_li")
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
