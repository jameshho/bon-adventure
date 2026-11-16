extends SceneTree
## The welcome tutorial (PWA restructure phase 6, 12 Nov 2026; scripts/learning/tutorial.gd,
## data/tutorial.json): one play-through with simulated events. A new profile starts it after
## loading; every step of the three acts is driven (Next, standing up, walking by teleport,
## doors, the shower curtain, the cart, a wrong then a right payment, walking out, the statue's
## word card, the journal); checkpoints, the board hold, the hidden house twins, studied words,
## the empty practice log, the stand-in for an avatar friend, Replay and Skip are checked.
## Since 13 Nov 2026 also: word cards stay off until the park act (a real click on the bedroom
## curtain shows nothing), talking to BonBon (her interactable) says each wait step's "where" line,
## the fruit is picked with real clicks on the supermarket's fruit table (one apple, one banana),
## and BonBon says to walk out after paying.
## Since 13 Nov 2026 (user review) also: the player wakes in the guest suite; doors the tour
## does not use say "not hiding here" (the front door opens at the end); the family bathroom
## door opens inwards; the bathtub friend's close-up uses its fixed camera spot; the market act
## keeps the player at the supermarket and its lot; the statue step holds the player still and
## only the statue opens a card.
## Since 14 Nov 2026 (user review) also: the clerk greets the player in the native language and
## hands over a basket (held; the picked fruit shows in it), the clerk's and cashier's lines are
## native with coloured terms in the language being learned (the amount with its digits), the
## cashier's thanks closes itself after 3 s, and the store door holds the player back until paid.
## With graphics (no --headless) it also saves the views in this folder: wake, bath-door,
## bathroom, friend, cutscene, shop-greeting, shop, fruit, basket, pay, statue, journal.
## 16 Nov 2026 also: BonBon teaches turning the view and walking (keyboard and touch wording, the
## cue, the pulsing joystick); views controls-view and controls-move.
## 14 Nov 2026 also: views wake-bed, living-approach and living-player (the staging), the open family bathroom door, the hidden mahjong
## table, the "Skip tutorial" label and word cards that close by themselves.
## Writes profile saves: isolated HOME, refuses to run when saves exist:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/tutorial-20261112/verify.gd
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
const Currency := preload("res://scripts/learning/currency.gd")
const SHOTS := "res://docs/evidence/tutorial-20261112/"

var checks := 0
var failures := 0
var render := false
var app: Node
var main: Node
var tutorial: Node
var lexicon

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
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + title + ".png"))
	print("shot ", title)

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
	check(Board.shared().hold == "tutorial", "the activity board is held while it runs")
	var waited := 0
	while not main.shop_panel.has_choices() and waited < 2000:
		await process_frame
		waited += 1
	check(main.player.seated, "the player wakes lying on the bed")
	check(not main.get_node("HouseCharacters/bonbon").visible and not main.get_node("HouseCharacters/sunny").visible and tutorial.actors.size() == 3, "the cast stands in for the hidden house twins")
	var calling := get_nodes_in_group(Interactable.GROUP).filter(func(item) -> bool: return item.calling)
	check(calling.is_empty(), "no NPC calls (!) during the tutorial (%d)" % calling.size())
	check(_shown_text() == lexicon.phrase("tutorial.good_morning", lexicon.native), "BonBon speaks the native language")
	# 14 Nov 2026: the mahjong table is out of the way, the button says what it skips, cards close
	# by themselves.
	var table: Node3D = main.apartment.get_node_or_null("RelocatedSites/Home/MahjongTable")
	var table_items: Array = table.find_children("Interactable", "", true, false) if table != null else []
	check(table != null and not table.visible and table_items.all(func(item): return not item.enabled), "the mahjong table is hidden and its seats are off")
	check(tutorial._skip_button.text == lexicon.phrase("tutorial.skip", lexicon.native) and tutorial._skip_button.text.length() > 4, "the button says '%s'" % tutorial._skip_button.text)
	check(main.interaction.card_seconds > 0.0, "word cards close by themselves (%.1f s)" % main.interaction.card_seconds)
	await shot("wake")
	var handled := {}
	var last_act := 0
	var guard := 0
	while tutorial.running and guard < 40000:
		guard += 1
		var spec: Dictionary = tutorial.step
		if tutorial.act != last_act:
			check(int(manager.active_profile().get("tutorial", {}).get("act", -1)) == tutorial.act, "the checkpoint of act %d is saved" % (tutorial.act + 1))
			last_act = tutorial.act
		if spec.is_empty():
			await process_frame
		elif not handled.has(spec):
			handled[spec] = true
			await drive(spec)
		else:
			await process_frame
	check(not tutorial.running, "the tutorial reaches its end (stopped at act %d, step %s)" % [tutorial.act, str(tutorial.step)])
	check(bool(manager.active_profile().get("tutorial", {}).get("done", false)), "the profile records it as done")
	check(Board.shared().hold == "", "the hold is released")
	check(table == null or (table.visible and table_items.all(func(item): return item.enabled)), "the mahjong table is back")
	check(main.get_node("HouseCharacters/bonbon").visible and tutorial.actors.is_empty(), "the house twins come back and the cast leaves")
	for key in ["shower curtain", "apple", "banana", "statue"]:
		check(main.studied_words.has(key), "'%s' counts as studied (journal)" % key)
	check(PracticeLog.shared().counts.is_empty(), "nothing is recorded in the practice log")
	var clerk_item := Interactable.on(main.apartment.find_child("BeagleClerk", true, false))
	check(clerk_item == null or clerk_item.enabled, "the clerk's own game is back")
	check(Tutorial.begin(main) == null, "a finished profile does not see it again")
	# Replay with Sunny as the avatar: the next house character takes Sunny's part; then Skip.
	manager.update(id, {"avatar": "sunny"})
	var again: Node = Tutorial.begin(main, true)
	check(again == tutorial and again.running and again.act == 0, "Replay starts again from act 1")
	check(again.cast.get("friend_1") == "bruno" and again.cast.get("friend_2") == "leo", "a friend who is the avatar is replaced (%s)" % str(again.cast))
	await create_timer(1.0).timeout
	await again.skip()
	var spot: Vector3 = again._space("home").to_global(again._vec(again.data.skip_to.at))
	check(not again.running and Board.shared().hold == "" and main.player.global_position.distance_to(spot) < 1.5, "Skip ends it outside the home (%.1f m from the spot)" % main.player.global_position.distance_to(spot))
	check(bool(manager.active_profile().get("tutorial", {}).get("done", false)), "Skip records it as done")
	check(table == null or table.visible, "the mahjong table is back after Skip")
	var bath_door: Node = main.apartment.find_child("Family bathroom door", true, false)
	check(bath_door != null and not main.doors[bath_door].get("open", true), "the doors it opened are closed again")
	check(main.interaction.card_seconds == 0.0, "word cards stay open again after the tutorial")
	finish()

func _shown_text() -> String:
	return str(main.shop_panel.current_line().get("foreign", "")) if main.shop_panel.is_dialogue_visible() else ""

func next() -> void:
	var waited := 0
	while not main.shop_panel.has_choices() and waited < 600:
		await process_frame
		waited += 1
	main.shop_panel.choice_pressed.emit(Tutorial.NEXT)
	await frames(2)

## Points the click at `point` (the screen spot of the player's camera), as a mouse or a tap would.
func aim_at(point: Vector3) -> void:
	await frames(3)
	var camera: Camera3D = main.camera
	main.interaction.pointer_position = camera.unproject_position(point)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func teleport(at: Vector3, look: Vector3) -> void:
	tutorial.zone.place_player(tutorial._space("world"), at, look)
	await frames(3)

func drive(spec: Dictionary) -> void:
	match str(spec.do):
		"say":
			if spec.get("learning", false):
				check(_shown_text() == lexicon.phrase(str(spec.line), lexicon.foreign, {"name": tutorial._speaker(str(spec.who))}), "%s greets in the language being learned" % spec.who)
				if spec.who == "friend_1":
					# The curtain slides open and the close-up eases in.
					await create_timer(0.9).timeout
					var friend: Node3D = tutorial.actors.friend_1
					var view := get_root().get_viewport().get_camera_3d()
					check(friend.has_meta("talk_camera_at") and view != null and view.global_position.distance_to(friend.get_meta("talk_camera_at")) < 0.3, "the bathtub close-up uses its fixed camera spot")
					var curtain: Node3D = main.apartment.get_node(NodePath(str(tutorial.data.curtain)))
					check(not main.doors[curtain].get("open", true) and curtain.scale.x < 0.5, "the curtain is pulled back to the wall")
					await shot("friend")
			await next()
			if spec.line == "tutorial.good_morning":
				await staging_shots()
			elif spec.line == "tutorial.friends_hiding":
				await approach_shots()
		"wait":
			if spec.has("where"):
				check(tutorial.where_line() == str(spec.where), "BonBon knows where to go during wait %s (%s)" % [spec.for, tutorial.where_line()])
			await wait_for(spec)
		"cutscene":
			var opened: Array = tutorial._opened.map(func(door): return str(door.name))
			check(opened.has("Guest bath door") and opened.has("Family bathroom door"), "BonBon's way out and the family bathroom are open (%s)" % str(opened))
			await frames(30)
			await shot("cutscene")
		"shop":
			await shop()

## 14 Nov 2026: the opening as staged: the family bathroom door already open (the friend is
## behind one thing, the curtain), no mahjong table; the view from the bed.
func staging_shots() -> void:
	var opened: Array = tutorial._opened.map(func(door): return str(door.name))
	check(opened == ["Family bathroom door"], "the family bathroom door starts open (%s)" % str(opened))
	if not render:
		return
	await create_timer(1.2).timeout
	await shot("wake-bed")

## BonBon waiting in the living room by the chairs, out from the wall, turned between the family
## bathroom door and the suite (user, 14 Nov 2026): checked, then seen from the player's way in
## (a camera of its own at the suite's doorway, home site coordinates) and from the player.
func approach_shots() -> void:
	var site: Node3D = tutorial._space("home")
	var bonbon: Node3D = tutorial.actors.guide
	var walk: Dictionary = tutorial.data.acts[0].steps.filter(func(s): return s.do == "walk")[0]
	var spot: Array = walk.path.back()
	# The test teleports ahead of her: let her arrive and turn.
	var ends := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < ends and _flat_to(site, bonbon, spot) > 0.05:
		await process_frame
	# Her turn is the walk tween's last step, a moment after she is within 5 cm (a headless frame
	# can be far shorter than that moment).
	await create_timer(0.3).timeout
	var at: Vector3 = site.to_local(bonbon.global_position)
	var facing: Vector3 = site.global_basis.inverse() * (-bonbon.global_basis.z)
	var want := Vector2(float(walk.look[0]), float(walk.look[1])).normalized()
	check(Vector2(facing.x, facing.z).normalized().dot(want) > 0.98, "BonBon turns between the bathroom door and the suite (facing %.2f, %.2f; want %.2f, %.2f)" % [facing.x, facing.z, want.x, want.y])
	check(Vector2(at.x - float(spot[0]), at.z - float(spot[1])).length() < 0.3 and at.x > -3.0, "BonBon waits in the living room out from the wall (site %.2f, %.2f)" % [at.x, at.z])
	if not render:
		return
	var look := Camera3D.new()
	main.add_child(look)
	look.fov = 70.0
	look.global_position = site.to_global(Vector3(-3.75, 2.3, -1.6))
	look.look_at(site.to_global(Vector3(-4.0, 1.0, 8.5)), Vector3.UP)
	look.make_current()
	await shot("living-approach")
	main.camera.make_current()
	look.queue_free()
	await shot("living-player")

func _flat_to(site: Node3D, node: Node3D, spot: Array) -> float:
	var at: Vector3 = site.to_local(node.global_position)
	return Vector2(at.x - float(spot[0]), at.z - float(spot[1])).length()

## The family bathroom (14 Nov 2026: its door is already open, so the curtain is the one thing to
## open to find the friend): talking to BonBon says where to go, the door stands open inwards.
func bathroom_entry() -> void:
	var item: Node = Interactable.on(tutorial.actors.guide)
	check(item != null and not (item.check() is bool and not item.check()), "BonBon can be talked to while the player looks for the bathroom")
	if item != null:
		item.activate()
		await frames(2)
		check(_shown_text() == lexicon.phrase("tutorial.where_bathroom", lexicon.native), "BonBon says where the bathroom is")
	var site: Node3D = tutorial._space("home")
	var door: Node3D = site.find_child("Family bathroom door", true, false)
	check(door != null and bool(main.doors[door].get("open", false)), "the family bathroom door is already open")
	if door == null:
		return
	# Inwards: the open leaf's middle is inside the bathroom (site x < -5).
	var middle: Vector3 = site.to_local(door.to_global(preload("res://scripts/ui/interact_badge.gd").local_center(door)))
	check(middle.x < -5.0, "the family bathroom door opens into the bathroom (leaf middle at site x %.2f)" % middle.x)
	await teleport(site.to_global(Vector3(-2.2, 0, 8.7)), site.global_basis * Vector3(-1, 0, 0))
	await shot("bath-door")

func wait_for(spec: Dictionary) -> void:
	match str(spec.for):
		"stand":
			# E is ignored while the lie-down movement still plays: press until up.
			var tries := 0
			while main.player.seated and tries < 600:
				main.seating.stand()
				await process_frame
				tries += 1
			await frames(20)
			var home_space: Node3D = tutorial._space("home")
			check(home_space.to_local(main.player.global_position).z < -3.0, "the player wakes in the guest suite (site z %.1f)" % home_space.to_local(main.player.global_position).z)
			var master := home_space.find_child("Master bedroom door", true, false)
			var master_item: Node = Interactable.on(master) if master != null else null
			check(master_item != null and str(master_item.check()) == lexicon.phrase("tutorial.not_here", lexicon.native), "a door the tour does not use says they are not hiding there")
			var front := home_space.find_child("Front door", true, false)
			check(front != null and str(Interactable.on(front).check()) == lexicon.phrase("tutorial.not_here", lexicon.native), "the front door stays shut during the house tour")
			var yellow := home_space.find_child("Yellow bedroom door", true, false)
			check(yellow != null and Interactable.on(yellow).check() is bool and Interactable.on(yellow).check(), "the yellow bedroom door opens")
			# Word cards are off: a real click on the bed shows no card.
			# Since 13 Nov 2026 the player wakes in the guest suite: its bed's duvet.
			var curtains: Node3D = tutorial._bed(home_space, Vector3(-6.75, 0, -10.25))
			if curtains != null:
				await aim_at(curtains.global_position + Vector3.UP * 0.5)
				var aimed: Node3D = main.interaction.aimed_object()
				main.interaction.click()
				await frames(2)
				# Whatever word object is under the pointer (the curtain, or the wall or window
				# beside it): no card opens and its word is not studied.
				var aimed_key: String = main.interaction.word_key(aimed) if aimed != null else ""
				check(aimed != null and not main.hud.is_card_visible() and not main.studied_words.has(aimed_key), "no word card during the house tour (clicked '%s')" % aimed_key)
		"view", "move":
			await try_control(spec)
		"near":
			if str(spec.get("where", "")) == "tutorial.where_bathroom":
				await bathroom_entry()
			var point: Vector3
			if spec.has("who"):
				point = tutorial.actors[str(spec.who)].global_position + Vector3(1.0, 0, 0)
			else:
				point = tutorial._space(str(spec.space)).to_global(tutorial._vec(spec.at))
			await teleport(point, Vector3(0, 0, 1))
		"door":
			var door: Node3D = tutorial._door(spec)
			check(door != null, "the door near %s exists" % str(spec.at))
			if door != null and not main.doors[door].get("open", false):
				DoorAnimator.toggle(main, door)
		"use":
			var curtain: Node3D = main.apartment.get_node(NodePath(str(tutorial.data.curtain)))
			var home: Node3D = tutorial._space("home")
			# In front of the family tub (on the west wall since 13 Nov 2026), facing its curtain.
			await teleport(home.to_global(Vector3(-7.9, 0, 9.6)), home.global_basis * Vector3(-1, 0, 0))
			check(bool(main.doors[curtain].get("open", false)) and curtain.scale.x > 0.9, "the curtain starts drawn across the tub")
			main.interaction.refresh_focus()
			var focus: Node = main.interaction.focus
			check(focus != null and focus.get_parent() == curtain, "the shower curtain is the focused interactable in the bathroom (%s)" % (str(focus.get_parent().name) if focus != null else "none"))
			# A closer camera than the default for the picture (the doorway is behind the player).
			main.player.camera_distance = 2.4
			await shot("bathroom")
			DoorAnimator.toggle(main, curtain)
		"study":
			var statue: Node3D = main.apartment.get_node("WashingtonStatue")
			check(main.interaction.word_cards, "word cards are back for the statue")
			check(_shown_text() == lexicon.phrase("tutorial.click_statue", lexicon.native), "BonBon says to click the statue to reveal it")
			var filter: Callable = main.interaction.word_filter
			var bench: Node3D = null
			for node in main.apartment.find_children("*", "Node3D", true, false):
				if node.has_meta("word_key") and main.interaction.word_key(node) == "bench":
					bench = node
					break
			check(filter.is_valid() and filter.call(statue) and (bench == null or not filter.call(bench)), "only the statue opens a word card")
			var held: Vector3 = main.player.global_position
			main.player.global_position = held + Vector3(3, 0, 0)
			await frames(4)
			check(main.player.global_position.distance_to(held) < 0.2, "the player cannot move away before clicking the statue (%.2f m)" % main.player.global_position.distance_to(held))
			await aim_at(statue.global_position + Vector3.UP * 1.5)
			if main.interaction.aimed_object() == statue:
				main.interaction.click()
			else:
				print("NOTE: the statue is not under the screen point; its card is opened directly")
				main.interaction.selected = statue
				main.interaction._card_age = 0.0
				main.interaction.show_word(statue)
			await shot("statue")
			await create_timer(main.interaction.card_seconds + 0.5).timeout
			check(not main.hud.is_card_visible(), "the statue's card closed by itself")
		"journal":
			if main.hud.is_journal_open() != bool(spec.open):
				main.toggle_study_journal()
			if spec.open:
				await shot("journal")

## 16 Nov 2026 (user): BonBon teaches turning the view and walking right after waking. Checks the
## keyboard wording and the cue, then the touch wording (a first touch re-shows the hint) and the
## pulsing joystick, and that the step waits until the player has really tried the control.
func try_control(spec: Dictionary) -> void:
	var kind := str(spec.for)
	var hud: Node = main.hud
	var stick: Node = hud.ui_root.get_node_or_null("TouchControls")
	await frames(3)
	check(_shown_text() == lexicon.phrase(str(spec.where), lexicon.native), "BonBon says the keyboard line for '%s' (%s)" % [kind, _shown_text()])
	check(tutorial.cue.kind == kind and not tutorial.cue.touch, "the %s cue shows (keyboard)" % kind)
	await shot("controls-" + kind)
	hud.set_touch_mode(true)
	await frames(3)
	check(_shown_text() == lexicon.phrase(str(spec.touch_where), lexicon.native), "a first touch switches BonBon's %s line to the touch wording (%s)" % [kind, _shown_text()])
	check(tutorial.where_line() == str(spec.touch_where), "talking to BonBon repeats the touch line (%s)" % tutorial.where_line())
	check(tutorial.cue.touch and stick != null and stick._highlight == (kind == "move"), "on a touch screen the %s cue is the touch one (the joystick pulses only for move)" % kind)
	check(tutorial.step == spec, "the %s step waits until the player tries it" % kind)
	var player: Node3D = main.player
	if kind == "view":
		player.look_by(Vector2(20, 0))
		await frames(3)
		check(tutorial.step == spec, "a tiny turn is not enough")
		player.look_by(Vector2(400, 0))
	else:
		var from: Vector3 = player.global_position
		player.global_position = from + player.global_basis.z * 0.5
		await frames(3)
		check(tutorial.step == spec, "half a metre is not enough")
		await teleport(from + Vector3(2.0, 0.0, 0.0), Vector3(1, 0, 0))
	await frames(3)
	check(tutorial.step != spec, "trying the control ends the %s step" % kind)
	# The move step's hint and cue follow the view step at once; after it nothing pulses.
	if kind == "view":
		check(tutorial.cue.kind == "move", "the view cue gives way to the move cue (%s)" % tutorial.cue.kind)
	else:
		check(tutorial.cue.kind == "" and (stick == null or not stick._highlight), "the cue goes after the move step")
	hud.set_touch_mode(false)

func shop() -> void:
	while tutorial.shop == null:
		await process_frame
	var trip: Node = tutorial.shop
	check(trip.clerk != null and trip.cashier != null, "the store's clerk and cashier are found")
	# The market act keeps the player at the store and its lot: a step onto the road comes back.
	var lot_spot: Vector3 = main.player.global_position
	main.player.global_position = Vector3(-140.0, lot_spot.y, 160.0)
	await frames(4)
	check(main.player.global_position.x <= -156.4, "the player stays in the supermarket's lot (x %.1f)" % main.player.global_position.x)
	main.player.global_position = lot_spot
	await frames(2)
	# The clerk's greeting: native, with "basket" in the language being learned as a coloured term.
	var waited_line := 0
	while not main.shop_panel.has_choices() and waited_line < 600:
		await process_frame
		waited_line += 1
	var hello: Dictionary = main.shop_panel.current_line()
	var basket_word: String = lexicon.word("basket", lexicon.foreign)
	check(str(hello.get("foreign", "")).begins_with(lexicon.phrase("tutorial.clerk_hello", lexicon.native).split("(")[0].strip_edges().left(10)) and hello.get("narration", false), "the clerk greets the player in the native language (%s)" % hello.get("foreign", ""))
	check(hello.get("terms", []).size() == 1 and hello.terms[0].text == basket_word and hello.terms[0].gloss == lexicon.word("basket", lexicon.native), "the greeting's basket word is a term with its meaning")
	var markup: String = main.shop_panel.foreign_label.text
	check(markup.contains("[url=term:0]") and markup.contains(main.shop_panel.TERM.to_html(false)), "the dialogue box colours the term (%s)" % markup)
	main.shop_panel.foreign_label.meta_clicked.emit("term:0")
	await frames(2)
	check(main.shop_panel.foreign_label.get_parsed_text().contains("= " + lexicon.word("basket", lexicon.native)), "tapping the term shows its meaning (%s)" % main.shop_panel.foreign_label.get_parsed_text())
	await shot("shop-greeting")
	await next()
	var hand = main.player.hand
	check(hand.is_holding() and trip.basket != null and hand.held == trip.basket and str(hand.held.get_meta("hold_kind", "")) == "basket", "the clerk hands the player a basket to hold")
	var order_line: Dictionary = main.shop_panel.current_line()
	check(order_line.get("terms", []).size() == 2, "the order line colours each fruit word (%d terms)" % order_line.get("terms", []).size())
	await next()
	# The second clerk line first lets the greeting's close-up ease back (up to 0.8 s).
	var waited_cart := 0
	while not main.shop_panel.is_cart_visible() and waited_cart < 120:
		await process_frame
		waited_cart += 1
	check(main.shop_panel.is_cart_visible(), "the cart opens for the order")
	# The door: walking in is free; inside and unpaid, the doorway's wall stands.
	check(trip.door != null and not trip.door.blocks(), "the store door is open from outside")
	await teleport(Vector3(-176.0, 0.0, 163.8), Vector3(1, 0, 0))
	await frames(4)
	check(trip.door.blocks(), "inside and unpaid, the store door holds the player back")
	main.player.velocity = Vector3.ZERO
	var before_x: float = main.player.global_position.x
	for i in 60:
		main.player.velocity = Vector3(6.0, main.player.velocity.y, 0.0)
		main.player.move_and_slide()
		await physics_frame
	check(main.player.global_position.x < -172.1, "walking out unpaid stops at the doorway (x %.2f from %.2f)" % [main.player.global_position.x, before_x])
	# The produce area, looking at the fruit.
	await teleport(Vector3(-186.0, 0.0, 176.6), Vector3(-1, 0, 0))
	await shot("shop")
	var fruit := {}
	for node in main.apartment.find_children("*", "Node3D", true, false):
		var key: String = main.interaction.word_key(node) if node.has_meta("word_key") else ""
		if key in ["milk"] and not fruit.has(key) and main.zones.resolve_global(node.global_position) == "supermarket":
			fruit[key] = node
	var market: Node3D = main.apartment.get_node("RelocatedSites/Supermarket/MarketInterior")
	fruit["apple"] = market.get_node_or_null("Featured apples")
	fruit["banana"] = market.get_node_or_null("Featured bananas")
	check(fruit.apple != null and fruit.banana != null and main.zones.resolve_global(fruit.apple.global_position) == "supermarket", "the fruit table inside the door holds an apple and a banana")
	if fruit.has("milk"):
		trip._on_pick(fruit.milk)
		check(not trip.cart.has("milk"), "something not on the list stays out of the cart")
	check(tutorial.where_line() == "tutorial.where_fruit", "BonBon points to the fruit table while shopping")
	# Real clicks: stand in front of the table (towards the door) and click each fruit.
	if fruit.apple != null:
		var table: Vector3 = market.to_global(Vector3(-30.2, 0.1, 38.4))
		await teleport(market.to_global(Vector3(-30.2, 0.1, 36.6)), (table - market.to_global(Vector3(-30.2, 0.1, 36.6))).normalized())
		await shot("fruit")
		for key in ["apple", "banana"]:
			await aim_at((fruit[key] as Node3D).global_position + Vector3.UP * 0.15)
			var aimed: Node3D = main.interaction.aimed_object()
			check(aimed == fruit[key], "the %s is under the click (%s)" % [key, str(aimed.name) if aimed != null else "nothing"])
			main.interaction.click()
			await frames(2)
	await frames(3)
	check(trip.remaining.is_empty() and not main.shop_panel.is_cart_visible(), "the picked order closes the cart")
	check(trip.basket != null and trip.basket.item_count() == 2, "the picked apple and banana are in the basket (%d)" % (trip.basket.item_count() if trip.basket != null else -1))
	await teleport(market.to_global(Vector3(-31.5, 0.1, 35.6)), Vector3(0, 0, 1))
	await shot("basket")
	await teleport(trip._till(), Vector3(0, 0, -1))
	var waited := 0
	while not main.shop_panel.has_choices() and waited < 600:
		await process_frame
		waited += 1
	var request: Dictionary = main.shop_panel.current_line()
	var digits: String = Currency.usd(int(trip.settings.price_cents))
	check(request.get("narration", false) and request.get("terms", []).size() == 1 and request.terms[0].get("show", false) and request.terms[0].gloss == digits, "the cashier asks in the native language, the amount as a term with its digits")
	check(main.shop_panel.foreign_label.get_parsed_text().contains(lexicon.money(int(trip.settings.price_cents), lexicon.foreign)) and main.shop_panel.foreign_label.get_parsed_text().contains("= " + digits), "the amount shows in the language being learned and in digits (%s)" % main.shop_panel.foreign_label.get_parsed_text())
	await shot("pay")
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	check(main.money_panel.visible, "the cashier opens the money panel")
	main.money_panel.counts = {"bill_1": 1}
	main.money_panel.submitted.emit(100)
	await frames(3)
	check(not trip.paid and not main.money_panel.visible, "a wrong amount is not accepted")
	waited = 0
	while not main.shop_panel.has_choices() and waited < 600:
		await process_frame
		waited += 1
	main.shop_panel.choice_pressed.emit(trip.PAY)
	await frames(3)
	main.money_panel.counts = {"bill_1": 2, "coin_25": 2}
	main.money_panel.submitted.emit(250)
	await frames(3)
	check(trip.paid, "the exact price is accepted")
	var thanks_shown: bool = main.shop_panel.is_dialogue_visible() and main.shop_panel.current_line().get("narration", false)
	await create_timer(2.5).timeout
	var still_up: bool = main.shop_panel.is_dialogue_visible() and _shown_text() == lexicon.phrase("cashier.correct", lexicon.native)
	await create_timer(1.1).timeout
	check(thanks_shown and still_up and _shown_text() != lexicon.phrase("cashier.correct", lexicon.native), "the cashier's native thanks shows for 3 s and closes itself")
	check(not trip.door.blocks(), "after paying the store door opens")
	check(_shown_text() == lexicon.phrase("tutorial.where_leave_store", lexicon.native) and tutorial.where_line() == "tutorial.where_leave_store", "after paying BonBon says to walk out (%s)" % _shown_text())
	var outside: Dictionary = trip.settings.outside
	await teleport(tutorial._space("world").to_global(tutorial._vec(outside.at)), Vector3(1, 0, 0))
	await frames(6)
	check(not main.player.hand.is_holding(), "the basket is taken back after the shop")

func finish() -> void:
	SaveStore.remove_tree("user://profiles")
	print("TUTORIAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
