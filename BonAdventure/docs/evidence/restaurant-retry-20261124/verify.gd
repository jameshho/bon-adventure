extends SceneTree
## On the Menu: a wrong order is sent back at once (24 Nov 2026, user: "it didn't give me
## feedback until after I walked back to the staff"). Plays one visit through the session:
## Twinkle -> customer -> tablet -> a wrong dish for the first course -> Order sent -> thanks ->
## "Oh no, this is not what I ordered. Can you try again?" -> the tablet opens again by itself:
## the complaint in the bubble, the right dishes still on the slip, the wrong dish marked ✗ and
## not choosable -> the target sent -> "Excellent!" -> Twinkle's "in the end..." (the visit
## does not count; user, 24 Nov 2026) -> a first-try order next -> "Good job!" (counts). Also: only the first send is tracked (negative), the retry opens no new question.
## Views: the verdict line and the reopened tablet (list and slip). Uses Main (saves): run with
## an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=restaurants VT_SPAWN=none godot --path . --resolution 1400x900 --script res://docs/evidence/restaurant-retry-20261124/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const FOLDER := "res://docs/evidence/restaurant-retry-20261124/"
const ACTIVITY := "restaurant_twinkle"
const STAND_TWINKLE := Vector3(-3.7, .3, -1.6)
const STAND_TABLES := [Vector3(-11.6, .3, -2.9), Vector3(6.3, .3, -2.9)]
var failures := 0
var checks := 0
var game
var room: Node3D
var session
var box
var panel

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frame(file: String, frames := 8) -> void:
	for i in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")

func stand(local: Vector3) -> void:
	game.player.global_position = room.to_global(local)

func line_text() -> String:
	return str(box.current_line().get("foreign", ""))

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await process_frame
	room = game.apartment.get_node("Restaurants/Pizza")
	session = game.get_node("RestaurantSession")
	box = game.shop_panel
	panel = game.restaurant_panel
	stand(STAND_TWINKLE)
	session.offered = true
	session.host._on_talk(session.twinkle)
	box.choice_pressed.emit("restaurant_play")
	check(session.playing and session.step == session.Step.TO_CUSTOMER, "Yes starts a visit")
	var i: int = session.current
	stand(STAND_TABLES[i])
	session.host._on_talk(session.tables[i].node)
	await create_timer(session.INTRO_SECONDS + 0.3).timeout
	box.choice_pressed.emit("restaurant_tablet")
	check(panel.visible, "Open the tablet shows the order tablet")
	var courses: Array = session._courses()
	var first := str(courses[0])
	var target := str(session.requests[0].target)
	var bad := ""
	for entry in session.orders.menu[first]:
		if not Orders.matches(entry, session.requests[0].reqs):
			bad = str(entry.id)
			break
	check(bad != "", "a wrong dish exists for the first course (%s)" % first)
	var right_picks := {}
	for request in session.requests:
		right_picks[str(request.course)] = str(request.target)
	for course in courses:
		panel.show_tab(course)
		panel.inspect(bad if course == first else right_picks[course])
		panel.choose()
	var word := str(Orders.dish(target).word)
	var before: Dictionary = PracticeLog.shared().counts.get(PracticeLog.shared()._language, {}).get(word, {}).get(ACTIVITY, {}).duplicate()
	panel._send.pressed.emit()
	check(not panel.sent.is_empty(), "Send order shows Order sent")
	var after: Dictionary = PracticeLog.shared().counts.get(PracticeLog.shared()._language, {}).get(word, {}).get(ACTIVITY, {})
	check(int(after.get("negative", 0)) == int(before.get("negative", 0)) + 1 and not PracticeLog.shared().is_open(), "the first send is tracked: negative for %s" % word)
	await create_timer(session.SENT_SECONDS + 0.2).timeout
	check(not panel.visible and line_text() == session.lexicon.line("restaurant.thanks").foreign, "the tablet closes and the customer says thanks")
	await create_timer(session.VERDICT_SECONDS + 0.1).timeout
	check(line_text() == session.lexicon.line("restaurant.verdict_wrong").foreign and session.step == session.Step.WAITING, "the customer sends it back at once: %s" % line_text())
	session._process(0.05)
	check(not session._host_calling(), "Twinkle does not call for a report")
	await frame("1-sent-back", 10)
	await create_timer(session.RETRY_SECONDS + 0.2).timeout
	check(panel.visible and session.step == session.Step.TO_CUSTOMER and not box.is_dialogue_visible(), "the tablet opens again by itself")
	check(panel.ui.order.foreign == session.lexicon.line("restaurant.verdict_wrong").foreign, "the bubble holds the complaint")
	check(panel.tab == first and not panel.picks.has(first), "it opens the wrong course, without a dish")
	var kept := true
	for course in courses:
		if course != first:
			kept = kept and str(panel.picks.get(course, "")) == right_picks[course]
	check(kept, "the right dishes stay on the slip")
	panel.inspect(bad)
	check(panel.is_wrong(first, bad) and not panel.can_choose(), "the sent-back dish is marked and cannot be chosen again")
	panel.choose()
	check(not panel.picks.has(first), "Choose does nothing for it")
	await frame("2-tablet-again-wrong-dish", 10)
	check(not PracticeLog.shared().is_open(), "the retry opens no new question")
	panel.inspect(target)
	check(panel.can_choose(), "another dish can be chosen")
	panel.choose()
	check(panel.can_send(), "Send order is on again")
	await frame("3-tablet-again-fixed", 10)
	var done_before: int = Board.shared().done(ACTIVITY)
	panel._send.pressed.emit()
	await create_timer(session.SENT_SECONDS + session.VERDICT_SECONDS + 0.4).timeout
	check(line_text() == session.lexicon.line("restaurant.verdict_right").foreign and session.step == session.Step.TO_HOST, "the fixed order: %s" % line_text())
	stand(STAND_TWINKLE)
	session.host._on_talk(session.twinkle)
	check(Board.shared().done(ACTIVITY) == done_before and Board.shared().misses(ACTIVITY) == 1, "a retried visit does not count (one miss)")
	check(line_text() == session._line({"phrase": "restaurant.report_retry", "values": {"name": session._name(i)}}).foreign, "Twinkle: in the end (%s)" % line_text())
	box.choice_pressed.emit("restaurant_next")
	check(session.tries == 0 and session.wrong.is_empty(), "the next visit starts clean")
	# A first-try order still counts.
	var j: int = session.current
	stand(STAND_TABLES[j])
	session.host._on_talk(session.tables[j].node)
	await create_timer(session.INTRO_SECONDS + 0.3).timeout
	box.choice_pressed.emit("restaurant_tablet")
	for request in session.requests:
		panel.show_tab(str(request.course))
		panel.inspect(str(request.target))
		panel.choose()
	panel._send.pressed.emit()
	await create_timer(session.SENT_SECONDS + session.VERDICT_SECONDS + 0.4).timeout
	stand(STAND_TWINKLE)
	session.host._on_talk(session.twinkle)
	check(Board.shared().done(ACTIVITY) == done_before + 1, "a first-try order counts")
	check(line_text() == session._line({"phrase": "restaurant.report_right", "values": {"name": session._name(j)}}).foreign, "Twinkle: Good job (%s)" % line_text())
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
