extends SceneTree
## 4 Nov 2026, UI Stage 2: the shared activity board (data/activities.json: chance, progress
## target, one activity at a time) and the progress bar, in the real town (Main). Main saves
## progress, so run with an isolated HOME (README). A VT_FOCUS run must be reported as focused:
## HOME=<scratch>/home VT_FOCUS=supermarket,hospital godot --headless --path . --script res://docs/evidence/activities-20261104/verify_town.gd
const Currency := preload("res://scripts/learning/currency.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Questions := preload("res://scripts/learning/family_questions.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func finish() -> void:
	print("activities town: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Exactly `cents` in whole bills and coins (greedy; just for the test).
func pay(money, cents: int) -> void:
	var left := cents
	var ordered: Array = Currency.DENOMS.duplicate()
	ordered.sort_custom(func(a, b): return a.cents > b.cents)
	for d in ordered:
		while left >= int(d.cents):
			money.add_piece(d.id)
			left -= int(d.cents)

func run() -> void:
	root.size = Vector2i(1600, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var board = Board.shared()
	var lex = preload("res://scripts/language/lexicon.gd").shared()
	var box = game.shop_panel
	# Data (user decisions): every chance 1.0 for testing; cashier 5, family 20, grocery none.
	check(board.chance("shop_supermarket") == 1.0 and board.chance("cashier_supermarket") == 1.0 and board.chance("family_dr_li") == 1.0, "every chance is 100 % for testing")
	check(board.target("cashier_supermarket") == 5 and board.target("family_dr_li") == 20 and board.target("shop_supermarket") == 0, "targets: cashier 5, family 20, grocery none")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var saved: Dictionary = board.activities.cashier_supermarket.duplicate()
	board.activities.cashier_supermarket.chance = 0.0
	check(not board.roll("cashier_supermarket", rng), "chance 0 never offers")
	board.activities.cashier_supermarket.chance = 0.5
	var hits := 0
	for i in 1000:
		if board.roll("cashier_supermarket", rng):
			hits += 1
	check(hits > 420 and hits < 580, "chance 0.5 offers about half the time: %d of 1000" % hits)
	board.activities.cashier_supermarket = saved
	var shop = game.get_node_or_null("ShopSession_supermarket")
	var cashier = game.get_node_or_null("CashierSession_supermarket")
	var family = game.get_node_or_null("FamilySession")
	check(shop != null and cashier != null and family != null, "all three sessions exist")
	if shop == null or cashier == null or family == null:
		finish()
		return
	for session in [shop, cashier]:
		session.set_process(false)
	check(board.blocker("cashier_supermarket") == "" and board.blocker("family_dr_li") == "", "nothing running at the start")
	# --- Cashier: progress counts only rounds paid right first time; 5 thanks and ends.
	var money = game.money_panel
	game.interaction.clerk_activated.emit(cashier.cashier)
	check(cashier.round_active and box.is_dialogue_visible(), "the cashier offers a round")
	box.choice_pressed.emit("cashier_count")
	check(money.progress.visible and money.progress.done == 0 and money.progress.target == 5 and money.progress._label.text == "0/5", "money panel shows 0/5")
	check(money.progress.get_parent() == money._translate_button.get_parent() and money.progress.get_index() < money._translate_button.get_index(), "the bar sits left of the translate bubble")
	pay(money, cashier.request_cents)
	money._submit_button.pressed.emit()
	check(board.done("cashier_supermarket") == 1, "an exact first payment counts: %d" % board.done("cashier_supermarket"))
	box.choice_pressed.emit("cashier_another")
	box.choice_pressed.emit("cashier_count")
	check(money.progress._label.text == "1/5", "the next round shows 1/5")
	money.add_piece("coin_1")
	if Currency.total(money.counts) == cashier.request_cents:
		money.add_piece("coin_1")
	money._submit_button.pressed.emit()
	check(box.foreign_label.text == lex.phrase("cashier.wrong", lex.foreign), "a wrong payment: " + box.foreign_label.text)
	box.choice_pressed.emit("cashier_retry")
	money.clear()
	pay(money, cashier.request_cents)
	money._submit_button.pressed.emit()
	check(board.done("cashier_supermarket") == 1, "right after a miss does not count: %d" % board.done("cashier_supermarket"))
	board._done["cashier_supermarket"] = 4
	box.choice_pressed.emit("cashier_another")
	box.choice_pressed.emit("cashier_count")
	pay(money, cashier.request_cents)
	money._submit_button.pressed.emit()
	check(board.done("cashier_supermarket") == 5 and box.foreign_label.text == lex.phrase("cashier.complete", lex.foreign), "5/5: the cashier thanks the player: " + box.foreign_label.text)
	check(not money.visible and not cashier.round_active and not box.has_choices(), "the session ends")
	box.dialogue_closed.emit()
	game.interaction.clerk_activated.emit(cashier.cashier)
	check(box.foreign_label.text == lex.phrase("cashier.no_request", lex.foreign) and not cashier.round_active, "no new rounds until the next visit")
	box.dialogue_closed.emit()
	cashier.offered = true
	# --- Overlap: a grocery order blocks the cashier, and a cashier round blocks the clerk.
	shop.needs_help = true
	game.interaction.clerk_activated.emit(shop.clerk)
	box.choice_pressed.emit("yes")
	box.dialogue_closed.emit()
	check(shop.order_active() and board.blocker("cashier_supermarket") == "shop_supermarket", "a grocery order is the running activity")
	game.interaction.clerk_activated.emit(cashier.cashier)
	check(not cashier.round_active and box.foreign_label.text == lex.phrase("common.finish_first", lex.foreign), "the cashier asks to finish first: " + box.foreign_label.text)
	box.dialogue_closed.emit()
	shop._on_quit_answered(true)
	box.dialogue_closed.emit()
	check(board.blocker("cashier_supermarket") == "", "quitting the order frees the cashier")
	game.interaction.clerk_activated.emit(cashier.cashier)
	check(cashier.round_active, "the cashier starts a round")
	shop.needs_help = true
	var marker: Label3D = shop.clerk.get_node("NeedsHelpMarker")
	shop._animate(.1)
	check(not marker.visible, "the clerk's '!' is hidden while the cashier round runs")
	game.interaction.clerk_activated.emit(shop.clerk)
	check(not shop.order_active() and box.foreign_label.text == lex.phrase("common.finish_first", lex.foreign), "the clerk asks to finish first")
	box.dialogue_closed.emit()
	cashier._end_round(false)
	shop._animate(.1)
	check(marker.visible, "the '!' returns once the round ends")
	# --- Family: 20 questions answered right on the first tap; 20/20 thanks and closes.
	var panel = game.family_panel
	var doctor: Node3D = family.doctor
	game.player.global_position = doctor.global_position - doctor.global_basis.z * 3.0
	family._process(.1)
	game.interaction.clerk_activated.emit(doctor)
	box.choice_pressed.emit("family_play")
	check(panel.visible and panel.progress.visible and panel.progress._label.text == "0/20", "family panel shows 0/20")
	family._on_answer(str(family.question.answer))
	check(board.done("family_dr_li") == 1 and panel.progress._label.text == "1/20", "a right first tap counts: " + panel.progress._label.text)
	family.next_question()
	var wrong := "no" if family.question.answer == "yes" else ("yes" if family.question.answer == "no" else "")
	if wrong == "":
		for id in family.tree.people:
			if id != family.question.answer:
				wrong = id
				break
	family._on_answer(wrong)
	family._on_answer(str(family.question.answer))
	check(panel.solved and board.done("family_dr_li") == 1, "right after a miss does not count: %d" % board.done("family_dr_li"))
	board._done["family_dr_li"] = 19
	family.next_question()
	family._on_answer(str(family.question.answer))
	check(not panel.visible and box.is_dialogue_visible() and box.foreign_label.text == lex.phrase("family.complete", lex.foreign), "20/20: Dr. Li thanks the player and the panel closes: " + box.foreign_label.text)
	box.dialogue_closed.emit()
	game.interaction.clerk_activated.emit(doctor)
	check(box.foreign_label.text == lex.phrase("family.not_now", lex.foreign) and not panel.visible, "Dr. Li offers again only on the next approach")
	box.dialogue_closed.emit()
	game.player.global_position = doctor.global_position - doctor.global_basis.z * 60.0
	family._process(.1)
	game.player.global_position = doctor.global_position - doctor.global_basis.z * 3.0
	family._process(.1)
	check(family.offered, "coming back rolls the offer again")
	# Grocery: one order is one round, no bar in the cart.
	check(box.cart_card.find_children("Progress", "", true, false).is_empty(), "the grocery cart has no progress bar")
	finish()
