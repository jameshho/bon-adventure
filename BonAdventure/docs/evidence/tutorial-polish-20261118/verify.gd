extends SceneTree
## The welcome tutorial after the user's polish list of 18 Nov 2026 (replaces
## tutorial-review-20261117/verify.gd as the "tutorial" check, which it copies and adapts):
## - "have a look around" stays 1.8 s; the view step needs a 2 rad drag, then 1 s; the walk step
##   10 m, then 0.5 s; meet friends / where are they / help find stay 2.0 / 2.3 / 2.0 s; the front
##   door opens by itself, then "let's go outside" (one line with "more to show") stays 3.5 s
##   (updated 25 Nov 2026 to the user's reviews of 20 and 21 Nov: shorter pauses, the merged
##   line, no "to the supermarket", the fruit at $1.25; tutorial-review2-20261121/verify.gd
##   checks the rest of the 21 Nov review);
## - no ✕ on the dialogue box and no HUD clock while the tutorial runs; the Skip button hides while
##   an instruction strip shows; "not where we are going" / "not there" close after 2 s, "not on
##   our shopping list" after 1.5 s; no "press E to open the curtain" strip;
## - back-to-back close-ups cut from face to face (Sunny's greeting to BonBon's "found everyone",
##   BonBon's picnic idea to Sunny's "we need food"), never through the player's view;
## - the market cast stands behind the player and never moves; the clerk and cashier are named in
##   the native language; "Great! We got everything! Let's go pay!" is one bubble in BonBon's
##   close-up; the cashier's amount has no digits and the strip says to hold EN; no Inspect button
##   while paying; the basket's handles hide while it is inspected; walking out anywhere past the
##   doorway counts (no "walk out of the store" afterwards).
## The 17 Nov review (tutorial-review-20261117/verify.gd), still checked here:
## - the profile's avatar is BonBon, so another character plays the guide; every house twin is
##   hidden (no one on the couch) and none naps;
## - in the house only the hiding friend's door opens: other doors stay shut and the guide says
##   her friends would not hide there (no "let's take a peek" line any more);
## - "you found one / everyone" and "more to show you" are in the guide's close-up although she
##   is in the living room; Sunny's "we need food first" is in her close-up;
## - the cast walks to the supermarket's door without boxing the player in;
## - the shopping list is 1 apple and 2 bananas ($1.25 since 21 Nov 2026);
## - a replay (Settings) starts with every home door shut, the sleeper back in its seat.
## The rest as in the 17 Nov script check:
## - bubbles move on by themselves after their reading time, with a gap before the next one, and
##   a click moves on at once; the player is held while a line is read;
## - controls come one at a time (only E in bed, then the view, then walking; nothing to use
##   until the walk is learned) and the instruction strip says what to do (keyboard and touch);
## - the two friends are found in either order (here the bedroom friend first): hints only when
##   asked, pointing at a friend not found yet and more exact on each ask; a door the hunt has no
##   use stays shut with the guide's line; the curtain opens with E
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
##   2 bananas ticked as it fills, BonBon's "Oops!" for a wrong item, hints that
##   follow what is missing, the money panel with only $1 bills and quarters, a wrong then a right
##   payment, "Wait!" at the door before paying;
## - the park: the statue's card reads "statue of George Washington", the journal, the picnic.
## With graphics (no --headless) it also saves views in this folder (see shot() calls).
## Writes profile saves: isolated HOME, refuses to run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/tutorial-polish-20261118/verify.gd
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
const SHOTS := "res://docs/evidence/tutorial-polish-20261118/"

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

## stderr is not buffered, so a redirected log shows progress while the run goes on.
func note(text: String) -> void:
	printerr(text)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		note("FAIL: " + label)

## Ends a run that hangs, saying where it stopped (the run takes about 3 minutes).
func watchdog() -> void:
	await create_timer(360.0).timeout
	var where := "loading" if tutorial == null else "act %d, step %s, line '%s'" % [tutorial.act, str(tutorial.step), shown()]
	check(false, "the run hung (%s)" % where)
	finish()

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
	# macOS stops drawing a hidden window or one on a sleeping or locked display: give up then.
	if await drawn(5.0):
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + title + ".png"))
		note("shot " + title)
	else:
		note("NOT DRAWN: " + title + " (the window is not being drawn)")
	fast = was

## Waits (at most `seconds`) for the next drawn frame; false if none was drawn.
func drawn(seconds: float) -> bool:
	var done := [false]
	var mark := func() -> void: done[0] = true
	RenderingServer.frame_post_draw.connect(mark, CONNECT_ONE_SHOT)
	var ends := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not done[0] and Time.get_ticks_msec() < ends:
		await process_frame
	if not done[0]:
		RenderingServer.frame_post_draw.disconnect(mark)
	return done[0]

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
	watchdog()
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
	note("town loaded")
	tutorial = main.get_node_or_null("Tutorial")
	check(tutorial != null and tutorial.running and tutorial.act == 0, "a new profile starts the tutorial at act 1")
	if tutorial == null:
		finish()
		return
	# The avatar is BonBon (the guide): someone else guides; the friends stay Sunny and Leo.
	check(str(tutorial.cast.get("guide", "")) != "bonbon" and str(tutorial.cast.get("friend_1")) == "sunny" and str(tutorial.cast.get("friend_2")) == "leo",
		"a BonBon player is guided by someone else (%s)" % str(tutorial.cast))
	var twins: Node = main.get_node("HouseCharacters")
	check(twins.get_children().all(func(twin) -> bool: return not (twin is Node3D) or not twin.visible), "every house twin is hidden (no one on the couch)")
	check(not twins.get_node("Bedtime").is_processing(), "no house character naps during the tutorial")
	check(not main.shop_panel.closable and not main.shop_panel.dialogue_close.visible, "the dialogue box has no close button")
	check(main.day_clock.kept_hidden and not main.day_clock.pill.visible, "the HUD clock is hidden")
	note("act_house")
	await act_house()
	note("act_market")
	await act_market()
	note("act_park")
	await act_park()
	check(await wait_until(func() -> bool: return not tutorial.running, 30.0), "the tutorial reaches its end (act %d, step %s)" % [tutorial.act, str(tutorial.step)])
	check(bool(manager.active_profile().get("tutorial", {}).get("done", false)), "the profile records it as done")
	check(main.shop_panel.closable and main.shop_panel.dialogue_close.visible and main.day_clock.pill.visible, "the close button and the clock come back")
	check(Board.shared().hold == "" and main.player.look_allowed and main.player.move_allowed and main.interaction.interact_allowed, "the hold and every control are back")
	check(not is_instance_valid(tutorial._picnic) and not tutorial.strip.is_showing(), "the picnic and the strip go when it ends")
	check(not main.interaction.interact_filter.is_valid() and main.hud.tutorial_hidden.is_empty(), "everything can be used again and every HUD button is back")
	for key in ["shower curtain", "apple", "banana", "statue"]:
		check(main.studied_words.has(key), "'%s' counts as studied (journal)" % key)
	check(PracticeLog.shared().counts.is_empty(), "nothing is recorded in the practice log")
	check(twins.get_children().all(func(twin) -> bool: return not (twin is Node3D) or twin.visible) and twins.get_node("Bedtime").is_processing(), "the house twins and their naps come back")
	note("replay")
	await replay()
	finish()

## Settings' Replay after free play: the front door left open and a twin napping on a bed.
func replay() -> void:
	var site: Node3D = tutorial._space("home")
	var front: Node3D = site.find_child("Front door", true, false)
	if front != null and not main.doors[front].get("open", false):
		DoorAnimator.toggle(main, front)
	var bedtime: Node = main.get_node("HouseCharacters/Bedtime")
	var sleeper: Dictionary = bedtime.sleepers[0]
	await wait_until(func() -> bool: return bedtime.searched, 4.0)
	# Out of sight (the park), so the nap may start.
	await teleport(Vector3(76.5, 0.0, 180.7), Vector3(-1, 0, 0))
	for i in 20:
		if not sleeper.bed.is_empty():
			break
		bedtime.lie_down(sleeper, main.seating)
		await frames(2)
	check(not sleeper.bed.is_empty() and main.doors[front].get("open", false), "before the replay: the front door open, a twin napping")
	app.replay_tutorial()
	fast = false
	check(await wait_line("tutorial.good_morning", {}, 30.0), "the replay starts with good morning")
	check(not main.doors[front].get("open", false), "the replay shut the front door")
	var open_doors: Array = []
	for door in main.doors:
		if is_instance_valid(door) and site.is_ancestor_of(door) and main.doors[door].get("open", false) and str(main.doors[door].get("type", "")) != "curtain":
			open_doors.append(str(door.name))
	check(open_doors == ["Family bathroom door"], "only the family bathroom door is open (%s)" % str(open_doors))
	check(sleeper.bed.is_empty() and not sleeper.npc.visible, "the napping twin is back in its seat and hidden")
	check(main.player.seated, "the player wakes on the bed again")
	await shot("replay-wake")
	tutorial.skip()
	await wait_until(func() -> bool: return not tutorial.running, 10.0)

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
	await frames(2)
	check(not tutorial._skip_button.visible, "the Skip button hides while a strip shows")
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
	var want := 1.8
	check(read > want - 0.6 and read < want + 0.8, "'have a look around' stays 1.8 s (%.1f s)" % read)
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
	await frames(5)
	check(str(tutorial.step.get("for", "")) == "view", "1.6 rad is not enough (2 rad needed)")
	player.look_by(Vector2(turn_px, 0))
	# 1 s to look on before the next line (2 s until the 20 Nov 2026 review).
	var viewed := Time.get_ticks_msec()
	check(await wait_line("tutorial.try_walking"), "BonBon: now try walking")
	var held := (Time.get_ticks_msec() - viewed) / 1000.0
	check(held > 0.8 and held < 2.2, "1 s after the drag before the next line (%.1f s)" % held)
	tutorial._advance = true
	await wait_until(func() -> bool: return tutorial.strip.text == phrase("tutorial.ui_move"))
	check(player.look_allowed and player.move_allowed and not main.interaction.interact_allowed, "the walking step allows the view and walking, nothing to use")
	await shot("strip-move")
	# The way walked counts (there and back), and 2 m is not enough.
	var spot: Vector3 = player.global_position
	await teleport(spot + Vector3(2.0, 0, 0), Vector3(1, 0, 0))
	await frames(5)
	check(str(tutorial.step.get("for", "")) == "move", "2 m of walking is not enough")
	await teleport(spot, Vector3(-1, 0, 0))
	await teleport(spot + Vector3(2.0, 0, 0), Vector3(1, 0, 0))
	await teleport(spot, Vector3(-1, 0, 0))
	await frames(5)
	check(str(tutorial.step.get("for", "")) == "move", "8 m of walking is not enough (10 m needed)")
	for i in 2:
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
	var meet_at := Time.get_ticks_msec()
	await wait_until(func() -> bool: return shown() != phrase("tutorial.meet_friends"), 6.0)
	var meet := (Time.get_ticks_msec() - meet_at) / 1000.0
	check(meet > 1.5 and meet < 2.6, "'I want you to meet my friends' stays 2.0 s (%.1f s)" % meet)
	check(await wait_line("tutorial.where_are_they"), "BonBon: where are they")
	tutorial._advance = true
	check(await wait_line("tutorial.help_find"), "BonBon: can you help me find them")
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
	# Every door but the hiding friend's stays shut and the guide says why; open ones can't be used.
	for door_name in ["Master bedroom door", "Garage access door"]:
		var door: Node3D = site.find_child(door_name, true, false)
		if door == null:
			check(false, "%s exists" % door_name)
			continue
		main.shop_panel.hide_dialogue()
		var before := "open %s, check %s, speaking %s, step %s" % [main.doors[door].get("open", false), str(Interactable.on(door).check()), tutorial._speaking, str(tutorial.step.get("do", ""))]
		Interactable.on(door).activate()
		await frames(3)
		check(not main.doors[door].get("open", false) and shown() == phrase("tutorial.not_there"), "%s stays shut: the guide says her friends aren't there ('%s'; before: %s)" % [door_name, shown(), before])
		check(main.shop_panel._auto_close > 1.8 and main.shop_panel._auto_close <= 2.0, "the remark closes after 2 s (%.2f s left)" % main.shop_panel._auto_close)
	# The tutorial opens the suite's door ("Guest bath door") and the family bathroom's itself.
	for door_name in ["Family bathroom door", "Guest bath door"]:
		var opened: Node3D = site.find_child(door_name, true, false)
		check(opened != null and main.doors[opened].get("open", false) and Interactable.on(opened).check() == false, "the open %s cannot be shut" % door_name)
	var yellow: Node3D = site.find_child("Yellow bedroom door", true, false)
	check(yellow != null and Interactable.on(yellow).check() == true, "the hiding friend's door can be opened")
	main.shop_panel.hide_dialogue()
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
	# (The reply comes once the close-up has eased in, up to 0.8 s; headless frames are quick.)
	check(await wait_until(func() -> bool: return main.shop_panel.has_choices(), 3.0), "the reply shows once EN was held")
	check(not main.shop_panel.show_native, "letting go flips it back")
	fast = false
	await reply()
	check(await wait_line("tutorial.found_one"), "BonBon: you found one")
	await wait_until(func() -> bool: return get_root().get_viewport().get_camera_3d() != main.camera, 3.0)
	check(get_root().get_viewport().get_camera_3d() != main.camera and tutorial._flat(tutorial.actors.guide.global_position, main.player.global_position) > Tutorial.GUIDE_FACE_RANGE,
		"'you found one' is in the guide's close-up although she is far")
	tutorial._advance = true
	fast = true
	await wait_until(func() -> bool: return tutorial.strip.progress == "1/2")
	check(tutorial.strip.progress == "1/2", "the objective counts 1/2")
	check(tutorial.where_line() == "tutorial.hint_bathroom", "with the bedroom friend found, the hint points to the bathroom (%s)" % tutorial.where_line())
	# The bathroom: no "press E to open the curtain" strip (user, 18 Nov 2026); the objective stays.
	var curtain: Node3D = tutorial._curtain_node()
	await teleport(site.to_global(Vector3(-7.9, 0, 9.6)), site.global_basis * Vector3(-1, 0, 0))
	await frames(20)
	check(tutorial.strip.text == phrase("tutorial.ui_find_friends", {"name": tutorial._speaker("guide")}), "no curtain strip, the objective stays (%s)" % tutorial.strip.text)
	check(not main.shop_panel.is_dialogue_visible(), "no 'let's take a peek' line (%s)" % shown())
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
	fast = false
	# The camera cuts from Sunny's face to BonBon's, never back to the player's view between.
	var through_player := [false]
	check(await wait_until(func() -> bool:
		if get_root().get_viewport().get_camera_3d() == main.camera:
			through_player[0] = true
		return shown() == phrase("tutorial.found_all")), "BonBon: you found everyone")
	await frames(2)
	check(not through_player[0] and get_root().get_viewport().get_camera_3d() != main.camera, "the camera cuts from the friend's face to the guide's (no player view between)")
	await create_timer(0.8).timeout
	await shot("found-all")
	tutorial._advance = true
	check(await wait_line("tutorial.lets_go_outside", {}, 6.0), "the guide: more to show you, let's go outside (one line)")
	var more_at := Time.get_ticks_msec()
	var front: Node3D = site.find_child("Front door", true, false)
	check(front != null and main.doors[front].get("open", false), "the front door has opened by itself")
	await frames(10)
	check(get_root().get_viewport().get_camera_3d() != main.camera, "'let's go outside' stays in her close-up")
	await wait_until(func() -> bool: return shown() != phrase("tutorial.lets_go_outside"), 8.0)
	var more := (Time.get_ticks_msec() - more_at) / 1000.0
	check(more > 3.0 and more < 4.3, "'let's go outside' stays 3.5 s (%.1f s)" % more)
	fast = true

# --- Act 2 -----------------------------------------------------------------------------------

func act_market() -> void:
	check(await wait_until(func() -> bool: return tutorial.act == 1 and shown() == phrase("tutorial.picnic"), 30.0), "the market act opens at the supermarket with the picnic idea")
	fast = false
	# The cast stands behind the player (user, 18 Nov 2026) and stays put the whole act.
	var ahead: Vector3 = -main.player.global_basis.z
	var spots := {}
	for role in tutorial.actors:
		var at: Vector3 = tutorial.actors[role].global_position
		spots[role] = at
		var off: Vector3 = at - main.player.global_position
		check(off.x * ahead.x + off.z * ahead.z < -1.0, "%s stands behind the player (%.1f m ahead)" % [role, off.x * ahead.x + off.z * ahead.z])
	await wait_until(func() -> bool: return get_root().get_viewport().get_camera_3d() != main.camera, 3.0)
	var through_player := [false]
	tutorial._advance = true
	check(await wait_until(func() -> bool:
		if get_root().get_viewport().get_camera_3d() == main.camera:
			through_player[0] = true
		return shown() == phrase("tutorial.need_food")), "the friend: we need food")
	check(not through_player[0], "the camera cuts from BonBon's face to Sunny's (no player view between)")
	await wait_until(func() -> bool: return get_root().get_viewport().get_camera_3d() != main.camera, 3.0)
	await create_timer(0.8).timeout
	check(get_root().get_viewport().get_camera_3d() != main.camera, "Sunny's 'we need food first' is in her close-up")
	await shot("need-food")
	tutorial._advance = true
	fast = true
	# (No "to the supermarket" since 20 Nov 2026: the friend's line leads straight to the clerk.)
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
	check(not main.shop_panel.cart_quit_button.visible, "the shopping list has no quit ✕ during the tutorial")
	check(main.shop_panel._speaker.foreign == main.shop_panel._speaker.native, "the clerk's name is in the native language (%s)" % str(main.shop_panel._speaker))
	# The cast stands clear of the player's way to the door (none boxes the player in).
	var from := Vector2(main.player.global_position.x, main.player.global_position.z)
	var to := Vector2(-172.4, 163.8)
	for role in tutorial.actors:
		var at: Vector3 = tutorial.actors[role].global_position
		var p := Vector2(at.x, at.z)
		var clear: float = p.distance_to(Geometry2D.get_closest_point_to_segment(p, from, to))
		check(clear >= 1.3, "%s stands clear of the way to the door (%.2f m)" % [role, clear])
	if render:
		var look := Camera3D.new()
		main.add_child(look)
		look.fov = 60.0
		look.global_position = main.player.global_position + Vector3(5.0, 7.0, -4.0)
		look.look_at(main.player.global_position + Vector3(-2.5, 0, 2.0), Vector3.UP)
		look.make_current()
		await shot("market-cast")
		main.camera.make_current()
		look.queue_free()
	var rows: Array = trip._list_rows()
	check(rows.size() == 2 and rows.all(func(row) -> bool: return not row.done), "the list has 2 lines (1 apple, 2 bananas), none ticked (%s)" % str(rows))
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
		check(main.shop_panel._auto_close > 1.3 and main.shop_panel._auto_close <= 1.5, "the oops closes after 1.5 s (%.2f s left)" % main.shop_panel._auto_close)
	var apples: Node3D = market.get_node("Featured apples")
	var bananas: Node3D = market.get_node("Featured bananas")
	trip._on_pick(apples)
	# Inspecting the basket from above: no handles over what is inside.
	main.hold_ui.open_inspection()
	await frames(3)
	check(main.hold_ui.inspecting() and not trip.basket.get_node("Handles").visible, "inspecting the basket hides its handles")
	await shot("basket-inspect")
	main.hold_ui.close_inspection()
	await frames(30)
	check(trip.basket.get_node("Handles").visible, "the handles come back after inspecting")
	trip._on_pick(bananas)
	rows = trip._list_rows()
	check(rows[0].done and not rows[1].done and str(rows[1].foreign).ends_with("1/2"), "the apple is ticked, the bananas count 1/2 (%s)" % str(rows))
	await shot("shop-list")
	trip._on_pick(bananas)
	check(trip.remaining.is_empty() and trip.basket.item_count() == 3, "3 items in the basket (%d)" % trip.basket.item_count())
	check(await wait_line("tutorial.got_everything_pay"), "BonBon: we got everything, let's go pay (one bubble)")
	await frames(30)
	check(get_root().get_viewport().get_camera_3d() != main.camera, "in BonBon's close-up")
	check(main.shop_panel.is_cart_visible() and trip._list_rows().all(func(row) -> bool: return row.done), "the list stays up, all ticked")
	await wait_until(func() -> bool: return trip.phase == "till")
	await teleport(trip._till(), Vector3(0, 0, -1))
	check(await wait_until(func() -> bool: return main.shop_panel.has_choices()), "the cashier asks")
	check(shown() == phrase("tutorial.cashier_hello", {"amount": {"learn": trip.dialogue.money_values(125)}}), "the cashier: that'll be ... (%s)" % shown())
	check(not main.shop_panel.current_line().terms.any(func(term) -> bool: return term.get("show", false)), "the amount comes without its digits")
	check(tutorial.strip.text == phrase("tutorial.ui_hold_en", {"badge": GameSettings.shared().native_badge()}), "the strip: hold EN if unsure (%s)" % tutorial.strip.text)
	check(main.shop_panel._speaker.foreign == main.shop_panel._speaker.native, "the cashier's name is in the native language (%s)" % str(main.shop_panel._speaker))
	check(not str(main.shop_panel._speaker.native).begins_with("The "), "the cashier is 'Cashier', no article (%s)" % str(main.shop_panel._speaker))
	await shot("cashier")
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	var money: Node = main.money_panel
	var offered: Array = money._bills_flow.get_children() + money._coins_flow.get_children()
	check(money.visible and offered.size() == 2, "the money panel offers only the $1 bill and the quarter (%d pieces)" % offered.size())
	await frames(2)
	check(not main.hold_ui.inspect_button.visible, "no Inspect button while paying")
	check(money._tray_hint.visible and money._tray_hint.text == phrase("tutorial.ui_pay", {"amount": "$1.25"}), "the empty tray says: tap to make $1.25 (%s)" % money._tray_hint.text)
	await shot("pay")
	money.counts = {"bill_1": 1}
	money.submitted.emit(100)
	check(await wait_line("tutorial.cashier_wrong"), "a wrong amount: try again")
	await wait_until(func() -> bool: return main.shop_panel.has_choices())
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	money.counts = {"bill_1": 1, "coin_25": 1}
	money.submitted.emit(125)
	check(await wait_line("tutorial.cashier_thanks"), "the cashier: perfect, thank you")
	check(await wait_line("tutorial.meet_outside"), "BonBon: let's meet outside")
	check(not trip.door.blocks(), "after paying the store door opens")
	# Out of the store away from the meeting point: that counts as walked out.
	await teleport(Vector3(-168.5, 0.0, 170.0), Vector3(1, 0, 0))
	check(await wait_line("tutorial.everyone_ready"), "walked out past the doorway: BonBon: everyone ready?")
	# The trip has ended (its node is freed once the shop step returns).
	check(not is_instance_valid(trip) or trip.where() == "", "no 'walk out of the store' once out")
	check(await wait_line("tutorial.picnic_time"), "the friend: picnic time")
	for role in spots:
		check(tutorial.actors[role].global_position.distance_to(spots[role]) < 0.05, "%s never moved during the market act" % role)

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
	check(is_instance_valid(tutorial._picnic) and tutorial._picnic.get_node("Picnic basket").item_count() == 3, "the picnic blanket with the bought food")
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
	if not await drawn(5.0):
		note("NOT DRAWN: book-icon")
		return
	var button: Control = main.hud.bookmark_button
	var rect := Rect2i(button.get_global_rect())
	var image: Image = root.get_texture().get_image().get_region(rect)
	image.resize(rect.size.x * 4, rect.size.y * 4, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(SHOTS + "book-icon.png"))
	note("shot book-icon")

func finish() -> void:
	SaveStore.remove_tree("user://profiles")
	note("TUTORIAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
