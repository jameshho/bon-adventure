extends SceneTree
## 24 Nov 2026: the Mahjong UI polish (docs/guides/MAHJONG.md, "The screen"): the compact status
## card, the soft call buttons above the tray's pull tab, the opponents' nameplates (lit on their
## turn, clear of the cards and the tray) and the cream table counter. Plays until the player may
## claim a discard with Pung / Chow / Kong (or 40 turns), checks the layout and, with graphics,
## saves actions.png, then an opponent's turn (turn.png) and the tray slid away (tray-hidden.png),
## named with the window size when it is not 1280x800.
## HOME=<scratch> VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/mahjong-ui-polish-20261124/verify.gd
const AI := preload("res://scripts/learning/mahjong_ai.gd")
const OUT := "res://docs/evidence/mahjong-ui-polish-20261124/"
var failures := 0
var checks := 0
var session
var graphics := false
var suffix := ""

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(file: String) -> void:
	if not graphics:
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file.replace(".png", suffix + ".png")))
	print("saved " + file.replace(".png", suffix + ".png"))

func run():
	graphics = DisplayServer.get_name() != "headless"
	if not graphics:
		root.size = Vector2i(1280, 800)
	var window := root.get_visible_rect().size
	if Vector2i(window) != Vector2i(1280, 800):
		suffix = "-%dx%d" % [int(window.x), int(window.y)]
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	session = main.get_node_or_null("MahjongSession")
	if session == null or session.table == null:
		check(false, "the mahjong session and table exist")
		finish()
		return
	var cycle = main.get("day_night")
	if cycle != null:
		cycle.set_time(720.0)
		cycle.pause()
	session._host_talk(session.npcs[0])
	session._on_choice("mahjong_yes")
	session._on_choice("mahjong_know")
	session._on_choice("mahjong_any")
	for i in 600:
		await process_frame
		if session.game != null and not session.zone.fading and session._playing:
			break
	var panel = main.mahjong_panel
	var g = session.game
	check(g != null and panel.visible, "a game started")
	session.set_process(false)
	for i in 4000:
		if g.phase == "over":
			break
		if g.turns_played >= 4 and g.phase == "claim" and g.waiting.has(0):
			var options: Dictionary = g.waiting[0]
			if options.has("pung") or options.has("kong") or not options.get("chows", []).is_empty():
				break
		_player_move()
		session._process(0.5)
	check(g.phase == "claim" and g.waiting.has(0), "the player may claim a discard (turn %d)" % g.turns_played)
	session._refresh()
	await create_timer(0.4).timeout
	session.view.finish_slides()
	await frames(3)
	var screen: Vector2 = panel.get_viewport_rect().size
	var whole := Rect2(Vector2.ZERO, screen)
	var info := Rect2(panel.info_card.position, panel.info_card.size * panel.info_card.scale)
	var corner := Rect2(panel.corner_card.position, panel.corner_card.size * panel.corner_card.scale)
	print("status card %s (%.1f%% of the screen's height), corner card %s" % [info, 100.0 * info.size.y / screen.y, corner])
	check(info.size.y <= screen.y * 0.15, "the status card is compact (%.0f px tall)" % info.size.y)
	var tab: Rect2 = panel.hand_toggle.get_global_rect()
	var bar: Rect2 = panel.hand_bar.get_global_rect()
	var row: Rect2 = panel.action_row.get_global_rect()
	check(panel.action_row.get_child_count() > 0, "call buttons show")
	check(row.end.y <= tab.end.y - panel.hand_toggle.tab_height() - 4.0, "the calls sit above the tab (calls %s, tab %s)" % [row, tab])
	check(absf(tab.get_center().x - bar.get_center().x) < 2.0, "the tab is centred on the tray")
	for button in panel.action_row.get_children():
		check(whole.encloses(button.get_global_rect()), "%s fits on screen" % button.name)
	var plates: Array = []
	for seat in range(1, 4):
		var plate: Control = panel._plates[seat]
		var r := plate.get_global_rect()
		plates.append(r)
		check(plate.visible and whole.encloses(r), "nameplate %d shows on screen (%s)" % [seat, r])
		check(not r.intersects(info) and not r.intersects(corner) and not r.intersects(bar) and not r.intersects(row), "nameplate %d is clear of the cards, calls and tray (%s)" % [seat, r])
		var label: Label = plate.get_child(0).get_child(1)
		check(label.text != "", "nameplate %d names its player (%s)" % [seat, label.text])
	check(not plates[0].intersects(plates[1]) and not plates[1].intersects(plates[2]) and not plates[0].intersects(plates[2]), "the nameplates do not overlap")
	var counter: Node3D = session.view.get_node_or_null("CentreCounter")
	check(counter != null and counter.visible, "the table counter shows")
	await shot("actions.png")
	# Pass, then stop on an opponent's turn: their plate is lit.
	session._on_action("pass", -1)
	for i in 400:
		if g.phase == "over" or (g.phase == "turn" and g.turn != 0):
			break
		_player_move()
		session._process(0.5)
	session._refresh()
	await create_timer(0.4).timeout
	check(g.phase == "over" or panel._turn == g.turn, "the opponent's plate is lit on their turn (%d)" % g.turn)
	await shot("turn.png")
	panel.hand_toggle.pressed.emit()
	await create_timer(0.35).timeout
	tab = panel.hand_toggle.get_global_rect()
	check(not panel.hand_bar.visible and absf(tab.end.y - screen.y) < 1.0, "the tray slides away, the tab waits at the bottom edge")
	await shot("tray-hidden.png")
	finish()

func _player_move() -> void:
	var g = session.game
	if g.phase == "turn" and g.turn == 0:
		var action := AI.turn_action(g, 0)
		match str(action.type):
			"kong": session._on_action("kong", int(action.tile))
			"win": session._on_tile(int(g.hands[0].back()))
			_: session._on_tile(int(action.tile))
	elif g.phase == "claim" and g.waiting.has(0):
		session._on_action("pass", -1)

func finish() -> void:
	print("MAHJONG UI POLISH: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
