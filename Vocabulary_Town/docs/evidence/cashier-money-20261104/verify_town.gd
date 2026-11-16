extends SceneTree
## 4 Nov 2026: cashier money minigame inside the real town (Main + supermarket cashier).
## Isolated user directory (Main saves progress). A VT_FOCUS=supermarket run only builds that
## interior and must be reported as focused, not as the full town:
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/cashier-money-20261104/verify_town.gd
const Currency := preload("res://scripts/learning/currency.gd")
## 4 Nov 2026: amounts in words moved from currency.gd to the Spanish rules module.
var es = preload("res://scripts/language/rules_es.gd").new()
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
## A payment of exactly `cents` using whole bills and coins (greedy; just for the test).
func pay(money, cents: int) -> void:
	var left := cents
	var ordered: Array = Currency.DENOMS.duplicate()
	ordered.sort_custom(func(a, b): return a.cents > b.cents)
	for d in ordered:
		while left >= int(d.cents):
			money.add_piece(d.id)
			left -= int(d.cents)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var session = game.get_node_or_null("CashierSession_supermarket")
	check(session != null, "Main creates the cashier session")
	if session == null:
		print("cashier town: ", checks, " checks, ", failures, " failures")
		quit(1)
		return
	session.set_process(false)
	var panel = session.panel
	var money = session.money
	var cashier: Node3D = session.cashier
	var clerk_session = game.get_node("ShopSession_supermarket")
	check(cashier != null and cashier.name == "SamoyedCashier" and str(cashier.get_meta("shop_clerk")) == "cashier_supermarket", "SamoyedCashier is tagged")
	check(game.interaction.action_hint_text(cashier.get_meta("action_hint")) == "E: Hablar", "E hint is Hablar")
	check(game.zones.resolve_global(cashier.global_position) == "supermarket", "cashier is inside the supermarket zone")
	check(game.money_panel == money and money.get_parent() == game.hud.ui_root, "one money panel under the HUD")
	check(not money.visible and not panel.is_dialogue_visible(), "nothing open at the start")
	# Talking to the cashier (the same signal a click or E emits) shows the request.
	game.interaction.clerk_activated.emit(cashier)
	check(panel.is_dialogue_visible() and panel.has_choices() and session.round_active, "cashier opens a request dialogue with choices")
	var request: int = session.request_cents
	check(request >= 25 and request <= 30000, "request in range (%d)" % request)
	var spoken := es.money_words(request)
	check(spoken in panel.foreign_label.text, "dialogue says the amount in Spanish: " + panel.foreign_label.text)
	check(Currency.usd(request) in panel._line.native, "translation shows the amount in dollars: " + str(panel._line.native))
	check(panel.speaker_label.text == "El cajero" or panel.speaker_label.text.begins_with("El "), "speaker shows the role: " + panel.speaker_label.text)
	check(not clerk_session.busy(), "the clerk's session is unaffected")
	check(not money.visible, "money panel waits for the dialogue choice")
	# Count out the money: the panel opens and the world is locked.
	panel.choice_pressed.emit("cashier_count")
	check(money.visible and not panel.is_dialogue_visible(), "money panel opens, dialogue closes")
	check(not game.player.controls_enabled and not game.interaction.enabled, "player controls and interaction are off while the panel is open")
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	money._input(key)
	check(money.get_viewport().is_input_handled(), "keys are swallowed while the panel is open")
	money.get_viewport().set_input_as_handled()
	# Add / remove / clear / total.
	var counted: Array = []
	for d in Currency.DENOMS: counted.append(d.id)
	check(counted.size() == 10, "ten denominations offered")
	check(money._bills_flow.get_child_count() == 6 and money._coins_flow.get_child_count() == 4, "6 bills and 4 coins on screen")
	money.add_piece("bill_20"); money.add_piece("bill_20"); money.add_piece("coin_25")
	check(money.total_cents() == 4025 and "$40.25" in money._total_label.text, "total updates: " + money._total_label.text)
	check(money._tray_flow.get_child_count() == 2, "tray shows one stack per denomination")
	money.remove_piece("bill_20")
	check(money.total_cents() == 2025 and money.counts.get("bill_20") == 1, "removing one takes one piece")
	money.remove_piece("coin_25")
	check(not money.counts.has("coin_25"), "stack disappears at zero")
	money.clear()
	check(money.counts.is_empty() and money.total_cents() == 0, "clear all")
	money.remove_piece("bill_1")
	check(money.counts.is_empty(), "removing from empty does nothing")
	# Wrong payment: dialogue says so, selection survives, retry reopens with the tray intact.
	var wrong_cents := request + 100 if request + 100 <= 99999 else request - 1
	pay(money, wrong_cents)
	var selection: Dictionary = money.counts.duplicate()
	money._submit_button.pressed.emit()
	check(not money.visible and panel.is_dialogue_visible(), "submit closes the panel and answers in the dialogue")
	check("no es la cantidad correcta" in panel.foreign_label.text, "wrong answer says so: " + panel.foreign_label.text)
	check(money.counts == selection, "selection kept after a wrong answer")
	check(panel.choice_row.get_child_count() == 2, "two options after a wrong answer")
	panel.choice_pressed.emit("cashier_why")
	var explanation: String = panel.foreign_label.text
	check(es.money_words(wrong_cents) in explanation, "explanation says what was given: " + explanation)
	check(("Todavía debe" in explanation) or ("de más" in explanation), "explanation says short or over")
	var diff := absi(wrong_cents - request)
	check(es.money_words(diff) in explanation, "explanation says the difference")
	panel.choice_pressed.emit("cashier_retry")
	check(money.visible and money.counts == selection, "retry reopens the panel with the same tray")
	# Close -> "are you sure?" -> no returns to the tray; yes ends the round.
	money.close_requested.emit()
	check(not money.visible and panel.is_dialogue_visible() and panel.has_choices(), "close asks 'are you sure'")
	check("¿Seguro" in panel.foreign_label.text, "question text: " + panel.foreign_label.text)
	panel.choice_pressed.emit("cashier_stay")
	check(money.visible and money.counts == selection and session.round_active, "no returns to the money screen, tray intact")
	money.close_requested.emit()
	panel.dialogue_closed.emit()
	check(money.visible and money.counts == selection, "closing the question counts as staying")
	money.close_requested.emit()
	panel.choice_pressed.emit("cashier_leave")
	check(not money.visible and not session.round_active and money.counts.is_empty(), "yes ends the round and clears the tray")
	check("buen día" in panel.foreign_label.text, "natural goodbye: " + panel.foreign_label.text)
	panel.dialogue_closed.emit()
	check(not panel.is_dialogue_visible() and game.player.controls_enabled and game.interaction.enabled, "controls return after leaving")
	# A correct round, with a combination that is not the fewest pieces.
	game.interaction.clerk_activated.emit(cashier)
	request = session.request_cents
	panel.choice_pressed.emit("cashier_count")
	# Whole-dollar part as $1 bills (not the fewest), the rest in cents.
	var dollars := request / 100
	var rest := request % 100
	for i in mini(dollars, 99): money.add_piece("bill_1")
	var remaining_dollars := dollars - mini(dollars, 99)
	pay(money, remaining_dollars * 100 + rest)
	check(money.total_cents() == request, "built the exact amount with many $1 bills")
	money._submit_button.pressed.emit()
	check("Perfecto" in panel.foreign_label.text, "exact amount accepted: " + panel.foreign_label.text)
	check(not session.round_active and money.counts.is_empty(), "round over, tray cleared")
	check(panel.choice_row.get_child_count() == 2, "another charge / goodbye offered")
	var old := request
	panel.choice_pressed.emit("cashier_another")
	check(session.round_active and money.counts.is_empty() and panel.is_dialogue_visible(), "another charge starts a fresh round")
	var changed := false
	for i in 20:
		panel.dialogue_closed.emit()
		game.interaction.clerk_activated.emit(cashier)
		if session.request_cents != old: changed = true
	check(changed, "requests vary")
	panel.dialogue_closed.emit()
	# Walking to the cashier while the clerk's order is open: ignored.
	game.interaction.clerk_activated.emit(game.get_node("ShopSession_supermarket").clerk)
	panel.dialogue_closed.emit()
	print("cashier town: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
