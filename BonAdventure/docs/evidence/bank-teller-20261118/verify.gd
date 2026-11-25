extends SceneTree
## 18 Nov 2026: the bank teller game "Next, Please!" (scripts/learning/teller_session.gd,
## activity teller_bank; docs/guides/MINIGAMES.md, docs/game/minigames.md). Amount stages,
## balances and change rules; every teller phrase in es/en/zh; the bear banker hosts on the shared
## host; Yes fades the player behind window 2 and customers walk up from the queue; the monitor
## shows the balance; a wrong "not enough", a wrong count (with the amount given in words), a
## retry with the tray kept, a right "not enough", a change customer given a $100 back and then
## paid right; the money screen offers only the $5, $10, $50 and $100 bills and no coins; ✕ on a
## question asks to leave and "no" asks the question again; the last customer closes the window
## and the banker thanks the player in the lobby; leaving mid-game clears the customers.
## Updated 24 Nov 2026 to the new flow (docs/guides/TOWN_DESIGN_BRIEF.md "Next, Please! polish"):
## the teller sits on window 2's chair, a withdrawal is asked once in the account view (no
## "Check the account" step), and a served customer's thanks moves on by itself (no "Next!").
## HOME=<scratch> VT_FOCUS=bank VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/bank-teller-20261118/verify.gd
## (headless: checks only). With graphics it writes *.png here. Main saves only in the isolated HOME.
const OUT := "res://docs/evidence/bank-teller-20261118"
const Session := preload("res://scripts/learning/teller_session.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Currency := preload("res://scripts/learning/currency.gd")
const Launcher := preload("res://scripts/ui/game_launcher.gd")
var checks := 0
var failures := 0
var game
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	_logic()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var session = game.get_node_or_null("TellerSession")
	check(session != null and session.host != null, "teller session on the shared host")
	if session == null or session.host == null:
		return finish()
	var host = session.host
	var lexicon = host.lexicon
	var panel = host.dialogue_panel
	var money = session.money
	var banker: Node3D = host.npc
	_phrases(lexicon, session.data)
	check(banker.name == "BearBanker" and str(banker.get_meta("word_key", "")) == "banker", "the bear banker hosts")
	check(Board.shared().session("teller_bank") == session and Launcher.ICONS.get("teller_bank") == "money", "registered on the activity board, picker icon")
	# --- talking: the greeting
	host.offered = true
	host._on_talk(banker)
	check(host.line_id == "teller.greeting" and panel.has_choices(), "talking to the banker: the greeting (%s)" % host.line_id)
	check(str(panel.current_line().foreign).contains("ventanilla") or lexicon.foreign != "es", "the greeting asks for help at the window")
	host.close_dialogue()
	# --- a session of 3 customers: Yes fades to window 2
	Board.shared().set_rounds("teller_bank", 3)
	host.launch()
	check(session.playing, "Yes starts the game")
	await create_timer(1.2).timeout
	var town: Node3D = game.apartment
	var chair: Node = session.bank.get_node_or_null(Session.TELLER_SEAT)
	check(game.player.seated and chair != null and game.seating.current.get("node") == chair, "the player sits on window 2's chair (24 Nov 2026)")
	check(session._monitor != null and session._monitor.visible and session._screen_idle.visible and session._screen_idle.text == lexicon.phrase("teller.screen_idle", lexicon.foreign), "the monitor shows the window number")
	check(session._change_at == 1 and session._short_at == 2, "3 customers: change is the second, the short account the third")
	await _until(func() -> bool: return session.step == "screen", 6.0)
	var first: Dictionary = session.current
	check(session.step == "screen" and host.line_id == str(first.ask) and panel.has_choices(), "the first customer walks up and asks, the account on the monitor (%s)" % session.step)
	check(first.kind == "withdraw" and first.dollars % 100 == 0 and first.dollars >= 100 and first.dollars <= 500, "customer 1: whole hundreds (%d)" % first.dollars)
	var window: Vector3 = town.to_global(Session.WINDOW_SPOT)
	check(Vector2(first.node.global_position.x - window.x, first.node.global_position.z - window.z).length() < 0.05, "the customer stands at window 2")
	check(str(panel.current_line().foreign).contains(lexicon.money(first.dollars * 100, lexicon.foreign)), "the request says the amount in words")
	check(str(panel.current_line().native).contains(Currency.usd(first.dollars * 100)), "the translation shows it in digits")
	check(not session.waiting.is_empty() and is_instance_valid(session.waiting.node), "the next customer joins the queue")
	check(session._camera != null and session._camera.current, "the account view frames the customer and the monitor")
	if graphics:
		await _snap("customer-asks")
	# --- the monitor and a wrong "not enough"
	first.balance = first.dollars + 125
	session._on_choice(host.choice_prefix() + "check")   # shows the changed balance
	check(session.step == "screen" and host.line_id == str(first.ask), "the request stands while the balance is read (one line)")
	check(session._screen_amount.text == Currency.usd(first.balance * 100) and session._screen_top.text.contains(first.name), "the monitor shows the name and balance %s" % session._screen_amount.text)
	if graphics:
		await _snap("monitor-balance")
	session._on_choice(host.choice_prefix() + "decline")
	check(session.step == "fix" and host.line_id == "teller.decline_wrong" and first.missed, "declining an account with enough money: the customer protests")
	session._on_choice(host.choice_prefix() + "again")
	check(session.step == "screen", "Look again: back to the monitor")
	# --- counting: only the four bills; a wrong count; retry keeps the tray
	session._on_choice(host.choice_prefix() + "count")
	check(money.visible and session.step == "count", "Count out the cash opens the money screen")
	check(not money._coins_tag.visible and not money._coins_flow.visible, "no coins on the money screen")
	check(money._bills_flow.get_child_count() == 4 and money.only == ["bill_5", "bill_10", "bill_50", "bill_100"], "only the $5, $10, $50 and $100 bills (%d)" % money._bills_flow.get_child_count())
	money.add_piece("bill_50")
	money.add_piece("bill_5")
	if graphics:
		await _snap("money-screen")
	money._submit_button.pressed.emit()
	check(not money.visible and host.line_id == "teller.wrong_amount" and session.step == "fix", "a wrong count: the customer says what they got")
	check(str(panel.current_line().foreign).contains(lexicon.money(5500, lexicon.foreign)), "the amount given, in words (%s)" % panel.current_line().foreign)
	session._on_choice(host.choice_prefix() + "retry")
	check(money.visible and int(money.counts.get("bill_50", 0)) == 1, "Count again keeps the tray")
	money.clear()
	for i in first.dollars / 100:
		money.add_piece("bill_100")
	money._submit_button.pressed.emit()
	check(session.step == "served" and host.line_id == str(first.thanks), "paid exactly: the customer's thanks (%s)" % host.line_id)
	check(Board.shared().done("teller_bank") == 0, "a customer served after a mistake does not count")
	# --- ✕ on a question asks to leave; "no" asks it again
	session._on_talk_closed(host.line_id)
	check(host.is_asking_leave(), "✕ on a customer's line asks to leave")
	host._on_quit_answered(false)
	check(not host.is_asking_leave() and host.line_id == str(first.thanks) and not panel.has_choices(), "No: the same line again, with no button")
	# --- customer 2 steps up by itself: change, a $100 back, then right
	await _next_customer(session, first.number)
	var second: Dictionary = session.current
	check(second.kind == "change" and second.dollars % 100 == 0 and host.line_id == "teller.ask", "customer 2 wants change (%d)" % second.dollars)
	check(str(panel.current_line().foreign).contains(lexicon.money(second.dollars * 100, lexicon.foreign)), "the change request names the amount")
	session._on_choice(host.choice_prefix() + "count")
	check(money.visible and money._tray_hint.text != "", "change: straight to the money screen, with the no-$100 hint")
	for i in second.dollars / 100:
		money.add_piece("bill_100")
	money._submit_button.pressed.emit()
	check(host.line_id == "teller.change_hundred", "a $100 back to a change customer: 'I need smaller ones'")
	session._on_choice(host.choice_prefix() + "retry")
	money.clear()
	for i in second.dollars / 50:
		money.add_piece("bill_50")
	money._submit_button.pressed.emit()
	check(host.line_id == "teller.change_thanks" and Board.shared().done("teller_bank") == 0, "paid in fifties: thanks (missed, so no count)")
	# --- customer 3: short account, a right "not enough" (counts)
	await _next_customer(session, second.number)
	var third: Dictionary = session.current
	check(third.kind == "withdraw" and third.balance < third.dollars, "customer 3's account is short (%d of %d)" % [third.balance, third.dollars])
	session._on_choice(host.choice_prefix() + "decline")
	check(host.line_id == "teller.no_funds" and session.step == "declined" and session._camera.current, "a right 'not enough': the teller says it, in close-up (21 Nov 2026)")
	await _until(func() -> bool: return session.step == "served", 6.0)
	check(host.line_id == "teller.impossible" and Board.shared().done("teller_bank") == 1, "the customer: 'That's impossible!', and it counts")
	# --- the rest until the target: count each one right first time
	var guard := 0
	while not session._finished and guard < 6:
		guard += 1
		await _next_customer(session, session.current.get("number", -1) if not session.current.is_empty() else -1)
		var c: Dictionary = session.current
		if c.kind == "withdraw" and c.balance < c.dollars:
			session._on_choice(host.choice_prefix() + "decline")
			await _until(func() -> bool: return session.step == "served", 6.0)
		else:
			session._on_choice(host.choice_prefix() + "count")
			_pay(money, c.dollars, c.kind == "change")
			money._submit_button.pressed.emit()
	check(session._finished and Board.shared().done("teller_bank") == 3, "the target is reached (%d)" % Board.shared().done("teller_bank"))
	check(panel.current_line() == session._prompt[1] and not panel.has_choices(), "the last customer's thanks has no button (no Close the window)")
	await _until(func() -> bool: return not session.playing and host.line_id == "teller.complete", 10.0)
	check(not session.playing and host.line_id == "teller.complete", "the banker thanks the player (%s)" % host.line_id)
	check(game.player.global_position.distance_to(banker.global_position) < 3.5, "back in the lobby by the banker")
	check(session.current.is_empty() and session.waiting.is_empty() and not session._monitor.visible, "customers and the monitor cleared")
	check(not session._camera.current, "the monitor camera is off")
	host.close_dialogue()
	# --- leaving mid-game
	Board.shared().set_rounds("teller_bank", 5)
	host.launch()
	await _until(func() -> bool: return session.step in ["ask", "screen"], 7.0)
	check(Board.shared().target("teller_bank") == 5 and session._change_at == 3 and session._short_at in [1, 2, 4], "5 customers: change is the fourth, one short account")
	if graphics:
		await _view("teller-view")
	session._on_talk_closed(host.line_id)
	host._on_quit_answered(true)
	await create_timer(1.2).timeout
	check(not session.playing and host.line_id == "teller.stopped", "leaving: the banker takes over (%s)" % host.line_id)
	check(session.current.is_empty() and session.waiting.is_empty() and session.bank.find_children("TellerCustomer*", "", false, false).is_empty(), "no customers left behind")
	finish()

## Waits until a customer other than number `previous` stands at the window with a question.
func _next_customer(session, previous: int) -> void:
	await _until(func() -> bool: return not session.current.is_empty() and session.current.number != previous and session.step in ["ask", "screen"], 12.0)

func _pay(money, dollars: int, change: bool) -> void:
	money.clear()
	var left := dollars
	for note in [100, 50, 10, 5]:
		if change and note == 100:
			continue
		while left >= note:
			money.add_piece("bill_%d" % note)
			left -= note

## The amount rules without the town.
func _logic() -> void:
	var stages: Array = []
	for i in 5:
		stages.append(Session.stage_of(i, 5))
	check(stages == ["hundreds", "hundreds", "fifties", "mixed", "mixed"], "stages for 5 customers %s" % [stages])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ok := {"hundreds": true, "fifties": true, "mixed": true, "short": true, "enough": true}
	for i in 300:
		var h := Session.amount_for("hundreds", rng)
		ok.hundreds = ok.hundreds and h % 100 == 0 and h >= 100 and h <= 500
		var f := Session.amount_for("fifties", rng)
		ok.fifties = ok.fifties and f % 100 == 50 and f >= 150 and f <= 450
		var m := Session.amount_for("mixed", rng)
		ok.mixed = ok.mixed and m % 5 == 0 and m % 50 != 0 and m > 100 and m < 500
		var s := Session.balance_for(m, true, rng)
		ok.short = ok.short and s < m and s >= 5 and s % 5 == 0
		var e := Session.balance_for(m, false, rng)
		ok.enough = ok.enough and e >= m and e % 5 == 0
	for key in ok:
		check(ok[key], "amounts: %s" % key)
	check(Session.paid_right({"bill_100": 3, "bill_50": 1}, 350, false), "350 = 3 × 100 + 50")
	check(not Session.paid_right({"bill_100": 2}, 200, true), "change: no $100 back")
	check(Session.paid_right({"bill_50": 3, "bill_10": 5}, 200, true), "change: 3 × 50 + 5 × 10")
	check(not Session.paid_right({"bill_100": 3, "bill_10": 1, "bill_5": 1}, 320, false), "315 is not 320")

## Every teller phrase in every language; each persona has its three lines with {amount} in the ask.
func _phrases(lexicon, data: Dictionary) -> void:
	var ids: Array = []
	for id in lexicon.phrases:
		if str(id).begins_with("teller."):
			ids.append(id)
	for persona in data.personas:
		for part in ["_ask", "_thanks"]:
			check(ids.has("teller.%s%s" % [persona, part]), "persona %s has %s" % [persona, part])
		check(str(lexicon.phrases["teller.%s_ask" % persona].get("es", "")).contains("{amount}"), "%s_ask names the amount" % persona)
	var langs := ["es", "en", "zh"]
	var complete := true
	for id in ids:
		for lang in langs:
			complete = complete and str(lexicon.phrases[id].get(lang, "")) != ""
	check(complete and ids.size() >= 50 and data.plain_asks.all(func(id) -> bool: return ids.has("teller." + str(id))), "every teller phrase in es, en and zh (%d)" % ids.size())
	for game_group in ["games", "games_host", "games_learn"]:
		check(lexicon.phrases.has(game_group + ".teller_bank"), game_group + ".teller_bank")

func _until(condition: Callable, seconds: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < seconds:
		await process_frame
		waited += 1.0 / 60.0
		await create_timer(1.0 / 60.0).timeout

## The screen as the player sees it (HUD, dialogue box and the game's own cameras).
func _snap(title: String) -> void:
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

## The lobby from beside the queue: the teller behind window 2, a customer at it, one waiting.
func _view(title: String) -> void:
	var town: Node3D = game.apartment
	var cam := Camera3D.new()
	cam.fov = 60
	root.add_child(cam)
	cam.global_position = town.to_global(Vector3(130.6, 2.6, 104.4))
	cam.look_at(town.to_global(Vector3(137.0, 1.3, 108.2)), Vector3.UP)
	cam.current = true
	game.hud.visible = false
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	cam.queue_free()
	game.player.camera.current = true

func finish() -> void:
	print("BANK TELLER: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
