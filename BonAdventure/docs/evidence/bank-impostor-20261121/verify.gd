extends SceneTree
## 21 Nov 2026 (user): Next, Please! impostors. The teller monitor shows each account's name,
## balance and the owner's headshot; an impostor claims another character's account (the photo is
## another animal); "Call the police" brings the beagle officer in the police costume, who
## escorts the impostor out of the bank. Checks: the plan (at most one impostor, never the change
## or short customer), the photo on the monitor (the customer's own species, the claimed one for
## an impostor), an honest customer protesting at the police, the banker stepping in when an
## impostor is paid, the officer walking in, the escort out and the count.
## Second round (user, 21 Nov 2026): the monitor's words follow EN (hold-to-peek); the camera
## toggle between the monitor and the customer; the escort lines (excuse me / what's happening /
## come with me now); the money tray in the order the bills were picked; plain asks.
## HOME=<scratch> VT_FOCUS=bank VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/bank-impostor-20261121/verify.gd
## (headless: checks only). With graphics it writes *.png here. Main saves only in the isolated HOME.
const OUT := "res://docs/evidence/bank-impostor-20261121"
const Session := preload("res://scripts/learning/teller_session.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
var checks := 0
var failures := 0
var game
var graphics := false
var scenes := {}

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	for spec in HouseCharacters.characters():  # data/npcs.json cast since 23 Nov 2026
		scenes[str(spec.id)] = str(spec.scene)
	check(Session.species_of("res://scenes/characters/pig_plush.tscn") == "pig", "species from a plush scene")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var session = game.get_node_or_null("TellerSession")
	check(session != null and session.host != null, "teller session")
	if session == null or session.host == null:
		return finish()
	var host = session.host
	var lexicon = host.lexicon
	var panel = host.dialogue_panel
	var money = session.money
	for id in ["call_police", "police_wrong", "impostor_warn", "officer_excuse", "impostor_what", "officer_now", "no_funds", "impossible", "view_customer", "view_screen"]:
		var phrase: Dictionary = lexicon.phrases.get("teller." + id, {})
		check(phrase.get("es", "") != "" and phrase.get("en", "") != "" and phrase.get("zh", "") != "", "phrase teller.%s in es, en, zh" % id)
	# --- the plan
	session.data["impostor_chance"] = 1.0
	var plans_ok := true
	for i in 40:
		Board.shared().set_rounds("teller_bank", 5)
		session._plan()
		plans_ok = plans_ok and session._impostor_at in [1, 2, 4] and session._impostor_at != session._short_at and session._change_at == 3
	check(plans_ok, "5 customers: one impostor, never the change or the short customer")
	Board.shared().set_rounds("teller_bank", 3)
	session._plan()
	check(session._impostor_at == -1, "3 customers: no room for an impostor")
	session.data["impostor_chance"] = 0.0
	Board.shared().set_rounds("teller_bank", 5)
	session._plan()
	check(session._impostor_at == -1, "impostor_chance 0: none")
	# --- a session of 5 with an impostor
	session.data["impostor_chance"] = 1.0
	host.launch()
	await _until(func() -> bool: return session.step == "ask", 7.0)
	check(session._impostor_at in [1, 2, 4], "this session has an impostor (customer %d)" % session._impostor_at)
	var first: Dictionary = session.current
	check(not first.impostor and first.face == Session.species_of(scenes[first.id]) and first.name == first.real_name, "customer 1 is honest: the photo is their own species (%s)" % first.face)
	session._on_choice(host.choice_prefix() + "check")
	check(session._screen_photo.visible and session._screen_photo.texture != null, "the monitor shows the account holder's headshot")
	check(session._screen_top.text.contains(first.name) and session._screen_amount.text != "", "the monitor shows the name and balance")
	check(session._prompt[2].size() == 3 and str(session._prompt[2][2].id).ends_with("police") and str(session._prompt[2][2].icon) == "police", "every account screen offers Call the police, with the badge icon")
	check(first.ask in ["teller.%s_ask" % first.persona, "teller.plain_ask_1", "teller.plain_ask_2", "teller.plain_ask_3"], "the request: a reason or a plain ask (%s)" % first.ask)
	if graphics:
		await _snap("monitor-headshot")
	# --- EN (hold-to-peek): the monitor's words in the native language, then back
	var GameSettings = load("res://scripts/core/game_settings.gd")
	var balance_word: String = session._screen_word.text
	GameSettings.shared().set_peek(true)
	await process_frame
	check(session._screen_word.text == lexicon.phrase("teller.screen_balance", lexicon.native) and session._screen_top.text == lexicon.phrase("teller.screen_account", lexicon.native, {"name": first.name}), "EN held: the monitor in the native language (%s)" % session._screen_word.text)
	if graphics:
		# The HUD ends a peek unless L or its EN button is held: hold the button for the capture.
		var peek: Button = game.hud.peek_button
		peek.toggle_mode = true
		peek.button_pressed = true
		await _snap("monitor-en")
		peek.button_pressed = false
		peek.toggle_mode = false
	GameSettings.shared().set_peek(false)
	await process_frame
	check(session._screen_word.text == balance_word, "EN released: back to the foreign language")
	# --- the camera toggle
	check(session._toggle_layer != null and session._toggle_layer.visible and session._on_screen, "the account screen: the camera toggle shows")
	session._on_toggle()
	check(not session._camera.current and first.presence.is_zoomed() and host.line_id == "teller.screen", "the toggle: the customer's face, the question stays")
	if graphics:
		await _snap("toggle-customer")
	session._on_toggle()
	check(session._camera.current and not first.presence.is_zoomed(), "the toggle again: back to the monitor")
	session._on_choice(host.choice_prefix() + "police")
	check(host.line_id == "teller.police_wrong" and first.missed and session.step == "fix", "police for an honest customer: they protest and no longer count")
	check(session.bank.find_children("TellerOfficer*", "", false, false).is_empty(), "no officer for an honest customer")
	session._on_choice(host.choice_prefix() + "again")
	# The tray: the bills in the order they were picked, left to right.
	session._on_choice(host.choice_prefix() + "count")
	check(money.visible and not session._toggle_layer.visible, "the money screen hides the camera toggle")
	money.add_piece("bill_5")
	money.add_piece("bill_100")
	money.add_piece("bill_5")
	money.add_piece("bill_50")
	var order: Array = money._tray_flow.get_children().filter(func(n) -> bool: return not n.is_queued_for_deletion()).map(func(n) -> String: return str(n.denom.id))
	check(order == ["bill_5", "bill_100", "bill_50"], "the tray keeps the order the bills were picked %s" % [order])
	if graphics:
		await _snap("tray-order")
	money.clear()
	money.hide_panel()
	await _serve(session, money, host)
	# --- on to the impostor
	var guard := 0
	while not session.current.get("impostor", false) and guard < 6:
		guard += 1
		session._on_choice(host.choice_prefix() + "next")
		await _until(func() -> bool: return session.step == "ask", 6.0)
		if not session.current.get("impostor", false):
			await _serve(session, money, host)
	var bad: Dictionary = session.current
	check(bad.get("impostor", false), "the impostor reaches the window")
	if not bad.get("impostor", false):
		return finish()
	var real_species := Session.species_of(scenes[bad.id])
	check(bad.face != real_species and bad.claim_id != bad.id and bad.name != bad.real_name, "the impostor claims %s's account (%s photo) but is %s (%s)" % [bad.name, bad.face, bad.real_name, real_species])
	check(bad.balance >= bad.dollars, "the impostor's claimed account has enough money")
	var done_before: int = Board.shared().done("teller_bank")
	if graphics:
		await _snap("impostor-asks")
	session._on_choice(host.choice_prefix() + "check")
	check(session._screen_top.text.contains(bad.name), "the monitor shows the claimed name")
	if graphics:
		await _snap("impostor-monitor")
	session._on_choice(host.choice_prefix() + "police")
	check(session.step == "escort" and not session._toggle_layer.visible and bad.presence.is_zoomed(), "Call the police: the camera stays on the impostor (%s)" % host.line_id)
	var officer: Node3D = bad.get("officer")
	check(officer != null and officer.find_child("Costume", true, false) != null, "a police officer in costume walks in")
	check(officer != null and officer.get_scene_file_path() == Session.OFFICER_SCENE and str(officer.get_meta("word_key", "")) == "police officer", "the officer is the police beagle")
	await _until(func() -> bool: return host.line_id == "teller.officer_excuse", 8.0)
	check(host.line_id == "teller.officer_excuse" and bad.officer_presence.is_zoomed(), "the officer arrives: 'Excuse me. Please come with me.'")
	if graphics:
		await _snap("officer-excuse")
	await _until(func() -> bool: return host.line_id == "teller.impostor_what", 6.0)
	check(host.line_id == "teller.impostor_what", "the impostor: 'What's happening?'")
	await _until(func() -> bool: return session.step == "served", 6.0)
	check(session.step == "served" and host.line_id == "teller.officer_now", "the officer: 'Please come with me now.'")
	var spot: Vector3 = game.apartment.to_global(Session.OFFICER_SPOT)
	check(officer.global_position.distance_to(Vector3(spot.x, officer.global_position.y, spot.z)) < 0.05, "the officer stands beside the window")
	check(Board.shared().done("teller_bank") == done_before + 1, "catching the impostor counts")
	check(bad.officer_presence.is_zoomed(), "the camera frames the officer")
	if graphics:
		await _snap("officer-arrives")
		await _view("officer-at-window")
	session._on_choice(host.choice_prefix() + "next")
	if graphics:
		await create_timer(1.4).timeout
		await _view("escorted-out")
	var officer_ref: WeakRef = weakref(officer)
	var bad_ref: WeakRef = weakref(bad.node)
	await _until(func() -> bool: return officer_ref.get_ref() == null, 8.0)
	check(officer_ref.get_ref() == null and bad_ref.get_ref() == null, "the officer escorts the impostor out of the bank")
	# --- the banker steps in when an impostor is paid (a second session)
	await _until(func() -> bool: return session.step == "ask", 6.0)
	session._on_talk_closed(host.line_id)
	host._on_quit_answered(true)
	await create_timer(1.3).timeout
	host.close_dialogue()
	session.data["impostor_chance"] = 0.0
	Board.shared().set_rounds("teller_bank", 3)
	host.launch()
	await _until(func() -> bool: return session.step == "ask", 7.0)
	session.current.impostor = true
	session._on_choice(host.choice_prefix() + "check")
	session._on_choice(host.choice_prefix() + "count")
	check(host.line_id == "teller.impostor_warn" and not money.visible and session.current.missed, "paying an impostor: the banker points at the photo")
	check(str(panel.current_line().foreign) == str(lexicon.line("teller.impostor_warn").foreign) and session._camera.current, "the monitor stays in view")
	session._on_choice(host.choice_prefix() + "again")
	session._on_choice(host.choice_prefix() + "decline")
	check(host.line_id == "teller.impostor_warn", "'not enough' for an impostor: the banker steps in too")
	session._on_talk_closed(host.line_id)
	host._on_quit_answered(false)
	check(host.line_id == "teller.impostor_warn", "No on the leave question: the banker's line again")
	# A short account declined: the teller's close-up, then "That's impossible!"
	session.current.impostor = false
	session.current.balance = session.current.dollars - 50
	session._on_choice(host.choice_prefix() + "again")
	session._on_choice(host.choice_prefix() + "decline")
	check(host.line_id == "teller.no_funds" and session.step == "declined" and session._camera.current, "not enough: the teller says it, in close-up")
	if graphics:
		await _snap("no-funds")
	await _until(func() -> bool: return session.step == "served", 6.0)
	check(host.line_id == "teller.impossible" and session.current.presence.is_zoomed(), "the customer: 'That's impossible!'")
	if graphics:
		await _snap("impossible")
	session._on_talk_closed(host.line_id)
	host._on_quit_answered(true)
	await create_timer(1.3).timeout
	check(not session.playing and session.bank.find_children("TellerOfficer*", "", false, false).is_empty(), "leaving clears everyone")
	finish()

## Serves the customer at the window right (from "ask" or after a mistake).
func _serve(session, money, host) -> void:
	var c: Dictionary = session.current
	if c.kind == "withdraw":
		session._on_choice(host.choice_prefix() + "check")
		if c.balance < c.dollars:
			session._on_choice(host.choice_prefix() + "decline")
			check(host.line_id == "teller.no_funds" and session._camera.current, "not enough: the teller says it, in close-up")
			if graphics:
				await _snap("no-funds")
			await _until(func() -> bool: return session.step == "served", 6.0)
			check(host.line_id == "teller.impossible", "the customer: 'That's impossible!'")
			return
	session._on_choice(host.choice_prefix() + "count")
	money.clear()
	var left: int = c.dollars
	for note in [100, 50, 10, 5]:
		if c.kind == "change" and note == 100:
			continue
		while left >= note:
			money.add_piece("bill_%d" % note)
			left -= note
	money._submit_button.pressed.emit()

func _until(condition: Callable, seconds: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < seconds:
		await process_frame
		waited += 1.0 / 60.0
		await create_timer(1.0 / 60.0).timeout

func _snap(title: String) -> void:
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

## The lobby from beside the queue (as bank-teller-20261118 teller-view).
func _view(title: String) -> void:
	var town: Node3D = game.apartment
	var cam := Camera3D.new()
	cam.fov = 60
	root.add_child(cam)
	cam.global_position = town.to_global(Vector3(130.6, 2.6, 104.4))
	cam.look_at(town.to_global(Vector3(135.0, 1.0, 108.6)), Vector3.UP)
	var previous := root.get_viewport().get_camera_3d()
	cam.current = true
	game.hud.visible = false
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	cam.queue_free()
	if previous != null and is_instance_valid(previous):
		previous.current = true

func finish() -> void:
	print("BANK IMPOSTOR: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
