extends SceneTree
## The welcome tutorial after the user's revised script (17 Nov 2026; scripts/learning/tutorial.gd,
## tutorial_shop.gd, data/tutorial.json, phrases tutorial.*; replaces tutorial-20261112/verify.gd
## as the "tutorial" check). One play-through with simulated input:
## - bubbles move on by themselves after their reading time, with a gap before the next one, and
##   a click moves on at once; the player is held while a line is read;
## - controls come one at a time (only E in bed, then the view, then walking; nothing to use
##   until the walk is learned) and the instruction strip says what to do (keyboard and touch);
## - the two friends are found in either order (here the bedroom friend first): hints only when
##   asked, pointing at a friend not found yet and more exact on each ask; a door the hunt has no
##   use for opens with BonBon's remark, the outside doors are locked; the curtain opens with E
##   (shut until the hunt);
## - the town reveal has its subtitle and is skipped by a click;
## Review of 17 Nov 2026 (user): "Ready for an adventure?" waits for "Yes!" in BonBon's close-up;
## the view step waits for a real drag (zooming does not count, no walking); the walk step counts
## the way walked; only doors and BonBon can be used; it starts at noon and the cast walks at the
## player's speed; the EN button is hidden until the first friend's greeting, then pulses with the
## strip until held, and the greeting waits for a reply; the journal button appears and pulses
## at its step; the minigame picker is hidden; the reveal can be skipped only once every building
## is in; in the town acts other buildings' doors say "not the right place".
## - the market: BonBon leads, the clerk's two lines and the basket, the shopping list of 1 apple,
##   2 bananas and 3 cookies ticked as it fills, BonBon's "Oops!" for a wrong item, hints that
##   follow what is missing, the money panel with only $1 bills and quarters, a wrong then a right
##   payment, "Wait!" at the door before paying;
## - the park: the statue's card reads "statue of George Washington", the journal, the picnic.
## With graphics (no --headless) it also saves views in this folder (see shot() calls).
## Writes profile saves: isolated HOME, refuses to run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/tutorial-script-20261117/verify.gd
## Prints "TUTORIAL: N checks, M failures".
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Tutorial := preload("res://scripts/learning/tutorial.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const SHOTS := "res://docs/evidence/tutorial-script-20261117/"

var checks := 0
var failures := 0
var render := false
var app: Node
var main: Node
var tutorial: Node
var lexicon
## While true, a line being read is moved on at once (a simulated click), so the run is quick.
var fast := true

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(title: String) -> void:
	if not render:
		return
	# Lines keep their own pace while the picture is taken (none is moved on unseen).
	var was := fast
	fast = false
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + title + ".png"))
	print("shot ", title)
	fast = was

func phrase(id: String, values := {}) -> String:
	return lexicon.phrase(id, lexicon.native, values)

func shown() -> String:
	return str(main.shop_panel.current_line().get("foreign", "")) if main.shop_panel.is_dialogue_visible() else ""

## Waits (at most `seconds`) until `test` is true.
func wait_until(test: Callable, seconds := 20.0) -> bool:
	var ends := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not test.call() and Time.get_ticks_msec() < ends:
		await process_frame
	return test.call()

## Runs alongside: moves every line on once it shows (a click) while `fast`.
func auto_advance() -> void:
	while is_instance_valid(tutorial):
		await process_frame
		if fast and tutorial.running and (tutorial._speaking or tutorial._pausing) and not tutorial._awaiting_reply:
			# Long enough for the checks to read the line first.
			await frames(8)
			tutorial._advance = true

## Presses the reply button of the line waiting for one.
func reply() -> void:
	await wait_until(func() -> bool: return main.shop_panel.has_choices())
	main.shop_panel.choice_pressed.emit(Tutorial.REPLY)
	await frames(2)

## Waits for the line `id` (native) to show; returns whether it did.
func wait_line(id: String, values := {}, seconds := 20.0) -> bool:
	var text := phrase(id, values)
	return await wait_until(func() -> bool: return shown() == text, seconds)

func teleport(at: Vector3, look: Vector3) -> void:
	tutorial.zone.place_player(tutorial._space("world"), at, look)
	await frames(3)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json") or FileAccess.file_exists(GameSettings.PATH):
		print("TUTORIAL: refusing to run, saves exist (use an isolated HOME)")
		quit(1)
		return
	render = DisplayServer.get_name() != "headless"
	if render:
		DisplayServer.window_set_size(Vector2i(1280, 800))
	lexicon = Lexicon.shared()
	var manager = ProfileManager.shared()
	var id: String = manager.create("Ana", "Ana", "bonbon")
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
	check(tutorial != null and tutorial.running and tutorial.act == 0, "a new profile starts the tutorial at act 1")
	if tutorial == null:
		finish()
		return
	await act_house()
	await act_market()
	await act_park()
	check(await wait_until(func() -> bool: return not tutorial.running, 30.0), "the tutorial reaches its end (act %d, step %s)" % [tutorial.act, str(tutorial.step)])
	check(bool(manager.active_profile().get("tutorial", {}).get("done", false)), "the profile records it as done")
	check(Board.shared().hold == "" and main.player.look_allowed and main.player.move_allowed and main.interaction.interact_allowed, "the hold and every control are back")
	check(not is_instance_valid(tutorial._picnic) and not tutorial.strip.is_showing(), "the picnic and the strip go when it ends")
	check(not main.interaction.interact_filter.is_valid() and main.hud.tutorial_hidden.is_empty(), "everything can be used again and every HUD button is back")
	for key in ["shower curtain", "apple", "banana", "cookie", "statue"]:
		check(main.studied_words.has(key), "'%s' counts as studied (journal)" % key)
	check(PracticeLog.shared().counts.is_empty(), "nothing is recorded in the practice log")
	finish()

# --- Act 1 -----------------------------------------------------------------------------------

func act_house() -> void:
	var player: Node3D = main.player
	# The first line moves on by itself after its reading time (no button, the player held).
	fast = false
	check(await wait_line("tutorial.good_morning"), "BonBon says good morning (%s)" % shown())
	var first: Dictionary = main.shop_panel.current_line()
	check(not player.look_allowed and not player.move_allowed and not main.interaction.interact_allowed, "only E works in bed")
	check(player.seated, "the player wakes lying on the bed")
	check(absf(float(main.day_night.minutes) - Tutorial.START_MINUTES) < 30.0, "the tutorial starts at noon (%.0f min)" % float(main.day_night.minutes))
	check(not main.hud.peek_button.visible and not main.hud.bookmark_button.visible and main.hud.tutorial_hidden.get("picker", false) and main.hud.tutorial_hidden.get("run", false), "the EN, journal, minigame and Run buttons are hidden")
	check(is_equal_approx(tutorial._walk_speed(), float(player.walk_speed)), "the cast walks at the player's walking speed (%.1f m/s)" % tutorial._walk_speed())
	var curtain_item: Node = Interactable.on(tutorial._curtain_node())
	check(curtain_item != null and curtain_item.check() is bool and not curtain_item.check(), "the shower curtain stays shut before the hunt")
	await shot("wake")
	# "Ready for an adventure?" waits for "Yes!" (a click elsewhere does not move it on).
	await wait_until(func() -> bool: return main.shop_panel.has_choices())
	check(main.shop_panel.has_choices(), "good morning has a reply button")
	await create_timer(Tutorial.reading_seconds(first) + 1.0).timeout
	check(main.shop_panel.current_line() == first, "it waits past its reading time for the reply")
	tutorial._advance = true
	await frames(3)
	check(main.shop_panel.current_line() == first, "a click elsewhere does not move it on")
	check(get_root().get_viewport().get_camera_3d() != main.camera, "BonBon's close-up while she asks")
	await reply()
	check(not main.shop_panel.is_dialogue_visible() or main.shop_panel.current_line() != first, "'Yes!' moves it on")
	# The strip asks for E.
	await frames(3)
	check(tutorial.strip.text == phrase("tutorial.ui_get_up"), "the strip says to press E (%s)" % tutorial.strip.text)
	await shot("strip-get-up")
	var tries := 0
	while player.seated and tries < 600:
		main.seating.stand()
		await process_frame
		tries += 1
	# Turning the view: only the view works.
	check(await wait_line("tutorial.look_around"), "BonBon: have a look around")
	var look_line: Dictionary = main.shop_panel.current_line()
	var started := Time.get_ticks_msec()
	await frames(30)
	check(get_root().get_viewport().get_camera_3d() != main.camera, "BonBon's lines are in a close-up while she is near")
	await wait_until(func() -> bool: return main.shop_panel.current_line() != look_line or not main.shop_panel.is_dialogue_visible(), 12.0)
	var read := (Time.get_ticks_msec() - started) / 1000.0
	var want: float = Tutorial.reading_seconds(look_line)
	check(read > want - 0.6 and read < want + 0.8, "the line stays its reading time (%.1f s, want %.1f s)" % [read, want])
	await wait_until(func() -> bool: return tutorial.strip.text == phrase("tutorial.ui_look"))
	check(player.look_allowed and not player.move_allowed and not main.interaction.interact_allowed, "the view step allows turning only")
	main.hud.set_touch_mode(true)
	await frames(3)
	check(tutorial.strip.text == phrase("tutorial.ui_look_touch"), "a touch switches the strip to the touch wording (%s)" % tutorial.strip.text)
	main.hud.set_touch_mode(false)
	await frames(3)
	await shot("strip-look")
	# Zooming does not count; a short drag is not enough.
	player.camera_distance += 3.0
	var turn_px: float = 0.8 / float(player.mouse_sensitivity)
	player.look_by(Vector2(turn_px, 0))
	await frames(10)
	check(str(tutorial.step.get("for", "")) == "view", "zooming and a short drag do not finish the view step")
	check(not player.move_allowed, "no walking during the view step")
	player.sprint_enabled = true
	await frames(2)
	check(not player.sprint_enabled, "running stays off during the tutorial")
	player.look_by(Vector2(turn_px, 0))
	# The next line comes after the gap.
	check(await wait_line("tutorial.try_walking"), "BonBon: now try walking")
	tutorial._advance = true
	await wait_until(func() -> bool: return tutorial.strip.text == phrase("tutorial.ui_move"))
	check(player.look_allowed and player.move_allowed and not main.interaction.interact_allowed, "the walking step allows the view and walking, nothing to use")
	await shot("strip-move")
	# The way walked counts (there and back), and 2 m is not enough.
	var spot: Vector3 = player.global_position
	await teleport(spot + Vector3(2.0, 0, 0), Vector3(1, 0, 0))
	await frames(5)
	check(str(tutorial.step.get("for", "")) == "move", "2 m of walking is not enough")
	for i in 3:
		await teleport(spot, Vector3(-1, 0, 0))
		await teleport(spot + Vector3(2.0, 0, 0), Vector3(1, 0, 0))
	check(await wait_line("tutorial.join_me"), "BonBon: join me in the living room")
	tutorial._advance = true
	await wait_until(func() -> bool: return str(tutorial.step.get("for", "")) == "near")
	check(player.look_allowed and player.move_allowed and main.interaction.interact_allowed, "after the walk every control works")
	check(tutorial.where_line() == "tutorial.where_chair", "asked, BonBon says she is by the chair")
	var filter: Callable = main.interaction.interact_filter
	var seat: Node = null
	for item in get_nodes_in_group("interactables"):
		var target: Node = item.get_parent()
		if tutorial._space("home").is_ancestor_of(target) and not main.doors.has(target) and seat == null:
			seat = item
	check(filter.is_valid() and seat != null and not filter.call(seat), "only doors and BonBon can be used (%s is not)" % (str(seat.get_parent().name) if seat != null else "none"))
	check(filter.call(Interactable.on(tutorial.actors.guide)), "BonBon can be talked to")
	var site: Node3D = tutorial._space("home")
	await teleport(site.to_global(Vector3(-1.4, 0.0, 6.2)), site.global_basis * Vector3(-1, 0, 0))
	# Consecutive lines: a click moves the first on, the next comes after the gap.
	check(await wait_line("tutorial.meet_friends"), "BonBon: I want you to meet my friends")
	tutorial._advance = true
	var gap_start := Time.get_ticks_msec()
	await wait_line("tutorial.where_are_they")
	var gap := (Time.get_ticks_msec() - gap_start) / 1000.0
	check(gap > 0.45 and gap < 1.1, "the next line comes after a short gap (%.2f s)" % gap)
	fast = true
	auto_advance()
	await wait_until(func() -> bool: return str(tutorial.step.get("do", "")) == "find")
	await frames(5)
	check(tutorial.strip.text == phrase("tutorial.ui_find_friends", {"name": tutorial._speaker("guide")}) and tutorial.strip.progress == "0/2", "the strip shows the objective 0/2 (%s %s)" % [tutorial.strip.text, tutorial.strip.progress])
	await find_friends(site)
	# Part 3: out of the house.
	check(await wait_until(func() -> bool: return str(tutorial.step.get("do", "")) == "wait" and str(tutorial.step.get("where", "")) == "tutorial.where_outside", 30.0), "BonBon heads outside")
	var front: Node3D = site.find_child("Front door", true, false)
	check(front != null and Interactable.on(front).check() is bool, "the front door opens at the end of the hunt")
	await teleport(site.to_global(Vector3(1.0, 0.0, 19.0)), site.global_basis * Vector3(0, 0, 1))
	check(await wait_until(func() -> bool: return is_instance_valid(tutorial._cutscene), 10.0), "the town reveal starts")
	var reveal: Node = tutorial._cutscene
	check(reveal._label.text == phrase("tutorial.title") and reveal._subtitle.visible and reveal._subtitle.text == phrase("tutorial.subtitle"), "the reveal shows 'Bon Adventure' and its subtitle")
	await shot("reveal")
	check(not reveal.skippable, "the reveal cannot be skipped while buildings load")
	check(await wait_until(func() -> bool: return not is_instance_valid(reveal) or reveal.skippable, 120.0), "it says 'Click or tap to skip' once ready")
	check(main.pending_units.is_empty(), "every building is in by then (%d left)" % main.pending_units.size())
	var skipped_at := Time.get_ticks_msec()
	reveal.skip_requested.emit()
	check(await wait_until(func() -> bool: return not is_instance_valid(tutorial._cutscene) or tutorial._cutscene != reveal, 3.0), "a click skips the reveal (%.1f s)" % ((Time.get_ticks_msec() - skipped_at) / 1000.0))

## The hunt: the bedroom friend first (either order), hints, doors, then the curtain with E.
func find_friends(site: Node3D) -> void:
	var guide: Node = Interactable.on(tutorial.actors.guide)
	guide.activate()
	await frames(2)
	check(shown() == phrase("tutorial.hint_bathroom"), "asked first, BonBon hints at the bathroom (%s)" % shown())
	guide.activate()
	await frames(2)
	check(shown() == phrase("tutorial.hint_bathroom_door"), "asked again, the hint is exact (%s)" % shown())
	var master: Node3D = site.find_child("Master bedroom door", true, false)
	var garage: Node3D = site.find_child("Garage access door", true, false)
	check(master != null and not (Interactable.on(master).check() is String), "a room the hunt has no use for opens")
	check(garage != null and str(Interactable.on(garage).check()) == phrase("tutorial.door_locked"), "an outside door is locked (%s)" % str(Interactable.on(garage).check()))
	if master != null:
		main.shop_panel.hide_dialogue()
		DoorAnimator.toggle(main, master)
		await frames(4)
		check(shown() == phrase("tutorial.not_there"), "BonBon remarks on the unrelated room (%s)" % shown())
		DoorAnimator.toggle(main, master)
	# The bedroom friend first.
	var leo: Node3D = tutorial.actors.friend_2
	await teleport(leo.global_position + Vector3(1.5, 0, 0), Vector3(-1, 0, 0))
	check(await wait_until(func() -> bool: return shown() == lexicon.phrase("tutorial.leo_hello", lexicon.foreign, {"name": tutorial._speaker("friend_2")})), "the bedroom friend greets in the language being learned")
	# The EN introduction: the button shows and pulses, the strip says to hold it, no reply yet.
	await frames(3)
	check(main.hud.peek_button.visible and main.hud.tutorial_pulse.get("peek", false), "the EN button appears and pulses")
	check(tutorial.strip.text == phrase("tutorial.ui_hold_en", {"badge": GameSettings.shared().native_badge()}), "the strip: hold EN (%s)" % tutorial.strip.text)
	check(not main.shop_panel.has_choices(), "no reply until EN was held")
	await shot("hold-en")
	# (Checked at once: the HUD ends a peek no key or button holds on its next frame.)
	GameSettings.shared().set_peek(true)
	check(main.shop_panel.show_native and not main.hud.tutorial_pulse.get("peek", false), "holding EN shows the line in the native language; the pulse stops")
	check(not main.shop_panel.translate_button.visible, "the dialogue box has no translate button of its own")
	GameSettings.shared().set_peek(false)
	await frames(3)
	check(main.shop_panel.has_choices(), "the reply shows once EN was held")
	check(not main.shop_panel.show_native, "letting go flips it back")
	await reply()
	check(await wait_line("tutorial.found_one"), "BonBon: you found one")
	await wait_until(func() -> bool: return tutorial.strip.progress == "1/2")
	check(tutorial.strip.progress == "1/2", "the objective counts 1/2")
	check(tutorial.where_line() == "tutorial.hint_bathroom", "with the bedroom friend found, the hint points to the bathroom (%s)" % tutorial.where_line())
	# The bathroom: BonBon's approach lines, the drag strip.
	var curtain: Node3D = tutorial._curtain_node()
	await teleport(site.to_global(Vector3(-7.9, 0, 9.6)), site.global_basis * Vector3(-1, 0, 0))
	check(await wait_line("tutorial.take_peek"), "BonBon: let's take a peek")
	check(await wait_until(func() -> bool: return tutorial.strip.text == phrase("tutorial.ui_open_curtain")), "the strip says to press E (%s)" % tutorial.strip.text)
	var item: Node = Interactable.on(curtain)
	check(item != null and item.check() == true, "the curtain can be used now")
	main.player.camera_distance = 2.4
	await shot("curtain-e")
	item.activate()
	await frames(2)
	check(tutorial._curtain_opened(), "E pulls the curtain back")
	check(await wait_until(func() -> bool: return shown() == lexicon.phrase("tutorial.sunny_hello", lexicon.foreign, {"name": tutorial._speaker("friend_1")})), "the bathtub friend greets")
	await shot("friend")
	check(main.shop_panel.has_choices(), "the greeting waits for a reply")
	await reply()
	check(await wait_line("tutorial.found_all"), "BonBon: you found everyone")

# --- Act 2 -----------------------------------------------------------------------------------

func act_market() -> void:
	check(await wait_until(func() -> bool: return tutorial.act == 1 and shown() == phrase("tutorial.picnic"), 30.0), "the market act opens at the supermarket with the picnic idea")
	check(await wait_line("tutorial.need_food"), "the friend: we need food")
	check(await wait_line("tutorial.to_supermarket"), "BonBon: to the supermarket")
	# (Most town buildings have open doorways; the bank's office and vault are doors.)
	var bank: Node3D = ModularTown.building(main.apartment, "bank")
	var other_door: Node3D = null
	for door in main.doors:
		if bank != null and bank.is_ancestor_of(door) and other_door == null:
			other_door = door
	check(other_door != null and str(Interactable.on(other_door).check()) == phrase("tutorial.not_right_place"), "another building's door: not the right place (%s)" % (str(Interactable.on(other_door).check()) if other_door != null else "no door"))
	await wait_until(func() -> bool: return tutorial.shop != null)
	var trip: Node = tutorial.shop
	check(await wait_line("tutorial.clerk_hello"), "the clerk welcomes the player")
	check(await wait_line("tutorial.clerk_basket"), "the clerk hands over a basket")
	check(await wait_until(func() -> bool: return main.shop_panel.is_cart_visible()), "the shopping list shows")
	check(trip.basket != null, "the player holds the basket")
	var rows: Array = trip._list_rows()
	check(rows.size() == 3 and rows.all(func(row) -> bool: return not row.done), "the list has 3 lines, none ticked (%s)" % str(rows))
	await wait_until(func() -> bool: return trip.phase == "pick")
	await wait_until(func() -> bool: return not tutorial._speaking)
	# Leaving the lot: BonBon calls the player back.
	var spot: Vector3 = main.player.global_position
	await wait_until(func() -> bool: return not tutorial._speaking)
	main.player.global_position = Vector3(-140.0, spot.y, 160.0)
	await frames(4)
	check(main.player.global_position.x <= -156.4, "the player stays in the supermarket's lot")
	check(await wait_line("tutorial.this_way", {}, 3.0), "BonBon: the supermarket is this way (%s)" % shown())
	main.player.global_position = spot
	check(trip.where() == "tutorial.hint_fruit", "asked, BonBon hints at the fruit section")
	Interactable.on(tutorial.actors.guide).activate()
	await frames(2)
	check(trip.where() == "tutorial.hint_fruit_table", "asked again, the fruit table (%s)" % trip.where())
	# Inside, unpaid: the door holds the player back.
	await teleport(Vector3(-176.0, 0.0, 163.8), Vector3(1, 0, 0))
	check(trip.door.blocks(), "inside and unpaid, the store door holds the player back")
	var market: Node3D = main.apartment.get_node("RelocatedSites/Supermarket/MarketInterior")
	var milk: Node3D = null
	for node in market.get_children():
		if node.has_meta("word_key") and str(node.get_meta("word_key")) == "milk":
			milk = node
			break
	if milk != null:
		trip._on_pick(milk)
		await frames(2)
		check(not trip.cart.has("milk") and shown() == phrase("tutorial.not_on_list"), "a wrong item: BonBon's oops, not in the basket (%s)" % shown())
	var apples: Node3D = market.get_node("Featured apples")
	var bananas: Node3D = market.get_node("Featured bananas")
	var cookies: Node3D = market.get_node("Cookie display")
	trip._on_pick(apples)
	trip._on_pick(bananas)
	rows = trip._list_rows()
	check(rows[0].done and not rows[1].done and str(rows[1].foreign).ends_with("1/2"), "the apple is ticked, the bananas count 1/2 (%s)" % str(rows))
	trip._on_pick(bananas)
	check(trip.where() == "tutorial.hint_cookies", "with the fruit done, the hint moves to the cookies (%s)" % trip.where())
	await teleport(market.to_global(Vector3(-30.2, 0.1, 36.6)), (market.to_global(Vector3(-30.2, 0.1, 38.4)) - market.to_global(Vector3(-30.2, 0.1, 36.6))).normalized())
	await shot("shop-list")
	if render:
		var look := Camera3D.new()
		main.add_child(look)
		look.fov = 70.0
		look.global_position = market.to_global(Vector3(-30.2, 1.7, 36.6))
		look.look_at(cookies.global_position + Vector3.UP * 0.8, Vector3.UP)
		look.make_current()
		await shot("cookies")
		main.camera.make_current()
		look.queue_free()
	for i in 3:
		trip._on_pick(cookies)
	check(trip.remaining.is_empty() and trip.basket.item_count() == 6, "6 items in the basket (%d)" % trip.basket.item_count())
	check(await wait_line("tutorial.got_everything"), "BonBon: we got everything")
	check(main.shop_panel.is_cart_visible() and trip._list_rows().all(func(row) -> bool: return row.done), "the list stays up, all ticked")
	await wait_until(func() -> bool: return trip.phase == "till")
	await teleport(trip._till(), Vector3(0, 0, -1))
	check(await wait_until(func() -> bool: return main.shop_panel.has_choices()), "the cashier asks")
	check(shown() == phrase("tutorial.cashier_hello", {"amount": {"learn": trip.dialogue.money_values(250), "show": true}}), "the cashier: that'll be ... (%s)" % shown())
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	var money: Node = main.money_panel
	var offered: Array = money._bills_flow.get_children() + money._coins_flow.get_children()
	check(money.visible and offered.size() == 2, "the money panel offers only the $1 bill and the quarter (%d pieces)" % offered.size())
	check(money._tray_hint.visible and money._tray_hint.text == phrase("tutorial.ui_pay", {"amount": "$2.50"}), "the empty tray says: tap to make $2.50 (%s)" % money._tray_hint.text)
	await shot("pay")
	money.counts = {"bill_1": 1}
	money.submitted.emit(100)
	check(await wait_line("tutorial.cashier_wrong"), "a wrong amount: try again")
	await wait_until(func() -> bool: return main.shop_panel.has_choices())
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	money.counts = {"bill_1": 2, "coin_25": 2}
	money.submitted.emit(250)
	check(await wait_line("tutorial.cashier_thanks"), "the cashier: perfect, thank you")
	check(await wait_line("tutorial.meet_outside"), "BonBon: let's meet outside")
	check(not trip.door.blocks(), "after paying the store door opens")
	var outside: Dictionary = trip.settings.outside
	await teleport(tutorial._space("world").to_global(tutorial._vec(outside.at)), Vector3(1, 0, 0))
	check(await wait_line("tutorial.everyone_ready"), "BonBon: everyone ready?")
	check(await wait_line("tutorial.picnic_time"), "the friend: picnic time")

# --- Act 3 -----------------------------------------------------------------------------------

func act_park() -> void:
	check(await wait_until(func() -> bool: return tutorial.act == 2 and shown() == phrase("tutorial.look_over_there"), 30.0), "the park act: look over there")
	await wait_until(func() -> bool: return str(tutorial.step.get("for", "")) == "study")
	check(tutorial.strip.text == phrase("tutorial.ui_click_statue"), "the strip: click the statue")
	var statue: Node3D = main.apartment.get_node("WashingtonStatue")
	main.interaction.selected = statue
	main.interaction.selected_point = statue.global_position + Vector3.UP * 1.5
	main.interaction._card_age = 0.0
	main.interaction.show_word(statue)
	check(lexicon.word("statue", "en") == "statue of George Washington", "the statue's word reads 'statue of George Washington'")
	await shot("statue-card")
	check(await wait_line("tutorial.statue_name"), "BonBon: it's a statue of George Washington")
	check(not main.hud.bookmark_button.visible, "the journal button is hidden before its step")
	await wait_until(func() -> bool: return str(tutorial.step.get("for", "")) == "journal")
	check(tutorial.strip.text == phrase("tutorial.ui_open_journal"), "the strip: open the journal")
	await frames(3)
	check(main.hud.bookmark_button.visible and main.hud.tutorial_pulse.get("journal", false), "the journal button appears and pulses")
	await shot("journal-button")
	if render:
		await book_icon()
	main.toggle_study_journal()
	await frames(4)
	check(not tutorial.strip.is_showing(), "the strip hides over the open journal")
	check(not main.hud.tutorial_pulse.get("journal", false), "opened, the journal button stops pulsing")
	main.toggle_study_journal()
	check(await wait_line("tutorial.picnic_eat", {}, 20.0), "BonBon: let's eat")
	check(is_instance_valid(tutorial._picnic) and tutorial._picnic.get_node("Picnic basket").item_count() == 6, "the picnic blanket with the bought food")
	print("picnic at %s, player %s, guide %s" % [tutorial._picnic.global_position, main.player.global_position, tutorial.actors.guide.global_position])
	await shot("picnic-talk")
	if render and is_instance_valid(tutorial._picnic):
		var look := Camera3D.new()
		main.add_child(look)
		look.fov = 60.0
		var at: Vector3 = tutorial._picnic.global_position
		look.global_position = at + Vector3(4.2, 3.0, -3.4)
		look.look_at(at, Vector3.UP)
		look.make_current()
		await shot("picnic")
		main.camera.make_current()
		look.queue_free()
	check(await wait_line("tutorial.goodbye", {}, 20.0), "BonBon's goodbye")

## The journal button, cropped and enlarged.
func book_icon() -> void:
	await frames(6)
	await RenderingServer.frame_post_draw
	var button: Control = main.hud.bookmark_button
	var rect := Rect2i(button.get_global_rect())
	var image: Image = root.get_texture().get_image().get_region(rect)
	image.resize(rect.size.x * 4, rect.size.y * 4, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(SHOTS + "book-icon.png"))
	print("shot book-icon")

func finish() -> void:
	SaveStore.remove_tree("user://profiles")
	print("TUTORIAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
