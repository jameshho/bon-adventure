extends SceneTree
## The welcome tutorial after the user's second review of 21 Nov 2026 (docs/guides/
## ARCHITECTURE_REVIEW_PART1.md "Review 2, 21 Nov 2026"). Starts a new profile at the market act
## (the house act is checked by tutorial-polish-20261118/verify.gd) and checks:
## - after a pan to the next speaker the box waits for the pan to end (+0.25 s);
## - the price is $1.25; the cashier asks in her close-up with the shopping list hidden, the
##   close-up stays over the money panel, then pans to BonBon for "meet outside";
## - outside, only "Everyone ready? Let's go to the park!" (BonBon) and Leo's "Picnic time!";
## - the park: Sunny's "what's that?" pans to BonBon's close-up; the statue's name waits for its
##   card to close (+0.2 s); one journal line; every picnic line in its speaker's close-up; the
##   new last line;
## - afterwards the guide and friends sit round the blanket and each answers E with its own lines
##   in turn; a replay removes them.
## The produce price tag reads $1.25 (supermarket.gd price_sign).
## With graphics (no --headless) it saves views in this folder.
## Writes profile saves: isolated HOME, refuses to run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/tutorial-review2-20261121/verify.gd
## Prints "REVIEW2: N checks, M failures".
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Tutorial := preload("res://scripts/learning/tutorial.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const SHOTS := "res://docs/evidence/tutorial-review2-20261121/"

var checks := 0
var failures := 0
var render := false
var app: Node
var main: Node
var tutorial: Node
var lexicon

func _initialize() -> void:
	run.call_deferred()

func note(text: String) -> void:
	printerr(text)

func check(ok: bool, label: String) -> void:
	checks += 1
	note(("ok: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func watchdog() -> void:
	await create_timer(420.0).timeout
	var where := "loading" if tutorial == null else "act %d, step %s, line '%s'" % [tutorial.act, str(tutorial.step), shown()]
	check(false, "the run hung (%s)" % where)
	finish()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func seconds(s: float) -> void:
	await create_timer(s).timeout

func shot(title: String) -> void:
	if not render:
		return
	await frames(4)
	if await drawn(5.0):
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + title + ".png"))
		note("shot " + title)
	else:
		note("NOT DRAWN: " + title)

func drawn(limit: float) -> bool:
	var done := [false]
	var mark := func() -> void: done[0] = true
	RenderingServer.frame_post_draw.connect(mark, CONNECT_ONE_SHOT)
	var ends := Time.get_ticks_msec() + int(limit * 1000.0)
	while not done[0] and Time.get_ticks_msec() < ends:
		await process_frame
	if not done[0]:
		RenderingServer.frame_post_draw.disconnect(mark)
	return done[0]

func phrase(id: String, values := {}) -> String:
	return lexicon.phrase(id, lexicon.native, values)

func shown() -> String:
	return str(main.shop_panel.current_line().get("foreign", "")) if main.shop_panel.is_dialogue_visible() else ""

func wait_until(test: Callable, limit := 20.0) -> bool:
	var ends := Time.get_ticks_msec() + int(limit * 1000.0)
	while not test.call() and Time.get_ticks_msec() < ends:
		await process_frame
	return test.call()

func wait_line(id: String, values := {}, limit := 25.0) -> bool:
	var text := phrase(id, values)
	return await wait_until(func() -> bool: return shown() == text, limit)

func close_up() -> bool:
	return get_root().get_viewport().get_camera_3d() != main.camera

## Waits for line `id`, lets the camera settle (a pan is 0.7 s), checks it is in a close-up
## (when `face`) and saves a view.
func line_shot(id: String, title: String, face := true) -> void:
	check(await wait_line(id), "line '%s' shows (%s)" % [id, shown()])
	await seconds(0.9)
	if face:
		check(close_up(), "'%s' is in a close-up" % id)
	await shot(title)

func teleport(at: Vector3, look: Vector3) -> void:
	tutorial.zone.place_player(tutorial._space("world"), at, look)
	await frames(3)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json") or FileAccess.file_exists(GameSettings.PATH):
		print("REVIEW2: refusing to run, saves exist (use an isolated HOME)")
		quit(1)
		return
	render = DisplayServer.get_name() != "headless"
	if render:
		DisplayServer.window_set_size(Vector2i(1280, 800))
	watchdog()
	lexicon = Lexicon.shared()
	var manager = ProfileManager.shared()
	# Not BonBon, so BonBon guides.
	var id: String = manager.create("Ana", "Ana", "miso")
	manager.update(id, {"tutorial": {"act": 1, "done": false}})
	preload("res://scripts/core/app.gd")._skip_splash = true
	app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await frames(3)
	app.start_town(id)
	while app.main == null or app.loading != null or app.main.process_mode == Node.PROCESS_MODE_DISABLED:
		await process_frame
	main = app.main
	tutorial = main.get_node_or_null("Tutorial")
	check(tutorial != null and tutorial.running and tutorial.act == 1, "the profile resumes the tutorial at the market act")
	if tutorial == null:
		finish()
		return
	await market()
	await park()
	await party()
	await price_tag()
	finish()

## The produce price tag reads $1.25 (shot last, once every building is in).
func price_tag() -> void:
	await wait_until(func() -> bool: return main.pending_units.is_empty() and app.loading == null, 60.0)
	var tags: Array = []
	for label: Label3D in main.apartment.find_children("*", "Label3D", true, false):
		if label.text.contains("1.25") or label.text.contains("1.50") or str(label.get_meta("sign_english", "")).begins_with("$1."):
			tags.append(label)
	check(tags.size() >= 1 and tags.all(func(l) -> bool: return str(l.get_meta("sign_english", l.text)) == "$1.25"), "the produce tag reads $1.25 (%s)" % str(tags.map(func(l) -> String: return "%s/%s" % [l.text, l.get_meta("sign_english", "")])))
	if render and not tags.is_empty():
		var tag: Label3D = tags[0]
		var look := Camera3D.new()
		main.add_child(look)
		var ahead: Vector3 = tag.global_basis.z.normalized()
		look.global_position = tag.global_position + ahead * 2.2 + Vector3.UP * 0.4
		look.look_at(tag.global_position, Vector3.UP)
		look.make_current()
		await shot("price-tag")
		main.camera.make_current()
		look.queue_free()

func market() -> void:
	check(await wait_until(func() -> bool: return is_instance_valid(tutorial.shop), 60.0), "the shop trip starts")
	var trip: Node = tutorial.shop
	check(int(trip.settings.price_cents) == 125, "the price is 125 cents")
	await wait_until(func() -> bool: return trip.phase == "pick", 30.0)
	await wait_until(func() -> bool: return not tutorial._speaking, 10.0)
	var market_root: Node3D = main.apartment.get_node("RelocatedSites/Supermarket/MarketInterior")
	trip._on_pick(market_root.get_node("Featured apples"))
	await frames(3)
	trip._on_pick(market_root.get_node("Featured bananas"))
	trip._on_pick(market_root.get_node("Featured bananas"))
	check(trip.remaining.is_empty(), "the list is complete")
	await wait_until(func() -> bool: return trip.phase == "till", 20.0)
	check(main.shop_panel.is_cart_visible(), "the list is up on the way to the till")
	await teleport(trip._till(), -trip.cashier.global_basis.z * -1.0)
	check(await wait_until(func() -> bool: return main.shop_panel.has_choices(), 15.0), "the cashier asks")
	check(shown() == phrase("tutorial.cashier_hello", {"amount": {"learn": trip.dialogue.money_values(125)}}), "the cashier asks for $1.25 (%s)" % shown())
	check(not main.shop_panel.is_cart_visible(), "the shopping list is hidden while she asks")
	await seconds(0.9)
	check(close_up() and tutorial._held_face == tutorial._faces.get(trip.cashier), "the request is in the cashier's close-up")
	await shot("cashier-ask")
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(4)
	var money: Node = main.money_panel
	check(money.visible and money._tray_hint.text == phrase("tutorial.ui_pay", {"amount": "$1.25"}), "the money panel: make $1.25 (%s)" % money._tray_hint.text)
	check(not main.shop_panel.is_cart_visible() and close_up(), "the list stays hidden and the close-up stays over the money panel")
	await shot("cashier-pay")
	money.counts = {"bill_1": 1}
	money.submitted.emit(100)
	check(await wait_line("tutorial.cashier_wrong"), "a wrong amount: try again")
	check(close_up() and not main.shop_panel.is_cart_visible(), "still her close-up, no list")
	await wait_until(func() -> bool: return main.shop_panel.has_choices(), 15.0)
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	money.counts = {"bill_1": 1, "coin_25": 1}
	money.submitted.emit(125)
	check(trip.paid, "a $1 bill and a quarter pay it")
	await line_shot("tutorial.cashier_thanks", "cashier-thanks")
	var through := [false]
	check(await wait_until(func() -> bool:
		if not close_up():
			through[0] = true
		return shown() == phrase("tutorial.meet_outside"), 15.0), "BonBon: meet outside")
	check(not through[0], "the camera pans from the cashier to BonBon (no player view between)")
	await seconds(0.9)
	check(close_up() and tutorial._faces.get(tutorial.actors.guide) != null and tutorial._faces[tutorial.actors.guide].is_zoomed(), "'meet outside' is in BonBon's close-up")
	await shot("meet-outside")
	await wait_until(func() -> bool: return trip.phase == "leave", 15.0)
	await teleport(Vector3(-168.5, 0.0, 170.0), Vector3(1, 0, 0))
	await line_shot("tutorial.everyone_ready", "everyone-ready")
	check(shown() == "Everyone ready? Let's go to the park!", "one line: everyone ready, to the park (%s)" % shown())
	through[0] = false
	check(await wait_until(func() -> bool:
		if not close_up():
			through[0] = true
		return shown() == phrase("tutorial.picnic_time"), 15.0), "Leo: picnic time")
	check(str(main.shop_panel._speaker).contains("Leo"), "Leo says it (%s)" % str(main.shop_panel._speaker))
	check(not through[0], "the camera pans from BonBon to Leo")
	await seconds(0.9)
	await shot("picnic-time")
	# Nothing else before the park.
	check(await wait_until(func() -> bool: return tutorial.act == 2, 30.0), "then the park act (no other line)")

func park() -> void:
	await wait_until(func() -> bool: return main.pending_units.is_empty() or main.has_node("NearbyUnits"), 90.0)
	await line_shot("tutorial.look_over_there", "look-over-there")
	var through := [false]
	check(await wait_until(func() -> bool:
		if not close_up():
			through[0] = true
		return shown() == phrase("tutorial.closer_look"), 15.0), "BonBon: closer look")
	check(not through[0], "the camera pans from Sunny to BonBon")
	await seconds(0.9)
	check(close_up(), "'closer look' is in BonBon's close-up")
	await shot("closer-look")
	await wait_until(func() -> bool: return str(tutorial.step.get("for", "")) == "study", 15.0)
	var statue: Node3D = main.apartment.get_node("WashingtonStatue")
	main.interaction.selected = statue
	main.interaction.selected_point = statue.global_position + Vector3.UP * 1.5
	main.interaction.selected_player_position = main.player.global_position
	main.interaction._card_age = 0.0
	main.interaction.show_word(statue)
	await frames(3)
	check(main.hud.is_card_visible(), "the statue's card shows")
	await shot("statue-card")
	var closed_at := [-1]
	var said: bool = await wait_until(func() -> bool:
		if closed_at[0] < 0 and not main.hud.is_card_visible():
			closed_at[0] = Time.get_ticks_msec()
		return shown() == phrase("tutorial.statue_name"), 20.0)
	var gap: int = Time.get_ticks_msec() - int(closed_at[0])
	check(said and closed_at[0] > 0, "the statue's name comes after its card closed")
	# 0.2 s pause plus the 0.6 s line gap and the face settling.
	check(gap >= 180 and gap < 2000, "%d ms between the card closing and the name" % gap)
	await seconds(0.6)
	await shot("statue-name")
	check(await wait_line("tutorial.journal_intro"), "one journal line")
	check(shown() == "Every word you find goes into your journal. Let's have a look!", "journal line text (%s)" % shown())
	await wait_until(func() -> bool: return str(tutorial.step.get("for", "")) == "journal", 15.0)
	main.toggle_study_journal()
	await frames(4)
	main.toggle_study_journal()
	await line_shot("tutorial.picnic_eat", "picnic-eat")
	for pair in [["tutorial.picnic_yum", "picnic-yum"], ["tutorial.picnic_thanks", "picnic-thanks"], ["tutorial.goodbye", "goodbye"]]:
		var through2 := [false]
		var empty_from := [-1]
		check(await wait_until(func() -> bool:
			if not close_up():
				through2[0] = true
			if empty_from[0] < 0 and shown() == "":
				empty_from[0] = Time.get_ticks_msec()
			return shown() == phrase(pair[0]), 20.0), "picnic line '%s'" % pair[0])
		# Line gap 0.6 s, then the 0.7 s pan and 0.25 s before the box.
		var empty_ms: int = Time.get_ticks_msec() - int(empty_from[0])
		check(empty_ms >= 1400, "the box for '%s' waits for the pan (%d ms without a box)" % [pair[0], empty_ms])
		check(not through2[0], "the camera pans to '%s' without the player view" % pair[0])
		await seconds(0.9)
		check(close_up(), "'%s' in a close-up" % pair[0])
		await shot(pair[1])
	check(shown() == "The whole town is now yours to explore. Have fun!", "the new last line (%s)" % shown())

func party() -> void:
	check(await wait_until(func() -> bool: return not tutorial.running, 30.0), "the tutorial ends")
	var crew: Node3D = tutorial._party
	check(is_instance_valid(crew), "the picnic party stays")
	if not is_instance_valid(crew):
		return
	var sitters: Array = crew.get_children().filter(func(n) -> bool: return n.has_meta("character_name"))
	check(sitters.size() == 3, "three sit round the blanket (%d)" % sitters.size())
	check(crew.get_node_or_null("TutorialPicnic") != null, "the blanket stays")
	await frames(10)
	if render:
		var look := Camera3D.new()
		main.add_child(look)
		look.fov = 55.0
		var at: Vector3 = crew.get_node("TutorialPicnic").global_position
		main.player.visible = false
		for sitter in sitters:
			print("%s at %s" % [sitter.get_meta("character_name"), sitter.global_position])
		print("blanket at %s" % at)
		look.global_position = at + Vector3(0.0, 6.5, 0.01)
		look.look_at(at, Vector3.UP)
		look.make_current()
		await shot("party-top")
		# From the open side, where the player stood.
		look.global_position = at + Vector3(4.0, 1.8, 0.0)
		look.look_at(at + Vector3.UP * 0.4, Vector3.UP)
		await shot("party-wide")
		look.global_position = at + Vector3(-3.2, 1.6, 2.6)
		look.look_at(at + Vector3.UP * 0.4, Vector3.UP)
		await shot("party-back")
		main.player.visible = true
		main.camera.make_current()
		look.queue_free()
	await shot("party-player")
	for npc in sitters:
		var item: Node = Interactable.on(npc)
		check(item != null and item.check() != null and item.check() != false, "%s can be talked to" % npc.get_meta("character_name"))
		var heard: Array = []
		for i in 4:
			item.activate()
			await frames(3)
			heard.append(shown())
			if i == 0:
				await shot("party-talk-%s" % str(npc.get_meta("character_name")).to_lower())
		note("%s: %s" % [npc.get_meta("character_name"), str(heard)])
		check(heard[0] != "" and heard[0] != heard[1] and heard[1] != heard[2] and heard[3] == heard[0], "%s rotates three lines" % npc.get_meta("character_name"))
	# A replay clears them.
	app.replay_tutorial()
	await frames(5)
	check(not is_instance_valid(crew) or crew.is_queued_for_deletion(), "a replay removes the party")
	await wait_until(func() -> bool: return tutorial.running, 10.0)
	tutorial.skip()
	await wait_until(func() -> bool: return not tutorial.running, 10.0)
	check(not is_instance_valid(tutorial._party), "a skip makes no party")

func finish() -> void:
	SaveStore.remove_tree("user://profiles")
	note("REVIEW2: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
