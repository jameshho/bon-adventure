extends SceneTree
## Electrical box repair (9 Nov 2026; docs/guides/ELECTRICAL_BOX.md). Headless, writes no files.
## Checks: the home's box is baked on the garage wall with its word and is an interactable
## pastime station (12 Nov 2026); the real picking ray finds it from the entry path; E beside it
## (its interactable, the focus target) opens it, from behind
## the wall does not; opening locks the player, opens the door, glides a temporary camera to
## the close-up and hides the player; the wires are shuffled (never all straight across);
## a wrong drop springs back and counts nothing, right drops snap; all connected repairs the
## box (green lamp, "Electrical Box Repaired!") and the screen closes by itself, giving back
## the player camera, the player and her controls; Esc leaves early without repairing; other
## games are blocked while a box is open; wire_count / wire_colors configure a new box.
## Uses Main, which saves progress and settings: run with an isolated HOME (README), e.g.
##   python3 tools/run_checks.py --only electrical_box
const Interactable := preload("res://scripts/core/interactable.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Features := preload("res://scripts/core/features.gd")
const Session := preload("res://scripts/learning/electrical_box_session.gd")
const BOX_SCENE := preload("res://scenes/props/electrical_box.tscn")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

## What the player would aim at from `eye` looking at `target` (world), as E and a click do.
var probe: Camera3D
func aim(game, eye: Vector3, target: Vector3) -> Node3D:
	if probe == null:
		probe = Camera3D.new()
		probe.top_level = true
		probe.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		root.add_child(probe)
	var keep: Camera3D = game.interaction.camera
	game.interaction.camera = probe
	probe.global_position = eye
	probe.look_at(target)
	probe.reset_physics_interpolation()
	game.interaction.pointer_position = game.get_viewport().get_visible_rect().size * .5
	await process_frame
	var item: Node = game.interaction.aimed_interactable()
	var found: Node3D = item.get_parent() if item != null else game.interaction.aimed_object()
	game.interaction.camera = keep
	return found

## Drops wire i on right row `row` (the panel's own drop, at that connector's position).
func drop(panel, i: int, row: int) -> void:
	panel.drop_on_row(i, row)

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(20): await process_frame
	var home: Node3D = ModularTown.building(game.apartment, "home")
	check(home != null, "home loaded (VT_FOCUS must include it)")
	if home == null:
		finish()
		return
	var box: Node3D = game.apartment.get_node_or_null("RelocatedSites/Home/Electrical box")
	check(box != null and box.get_script() != null and box.get_script().resource_path == "res://scripts/world/electrical_box.gd", "home electrical box baked with its script")
	if box == null:
		finish()
		return
	check(str(box.get_meta("word_key", "")) == "electrical box" and game.vocabulary.has("electrical box"), "box has the word 'electrical box' (in words.json)")
	var item: Node = Interactable.on(box)
	check(item != null and item.indicator == Interactable.Indicator.STATION and not box.has_meta("click_play") and not box.has_meta("action_hint"), "box: an interactable pastime station (no word card, no hint metas)")
	check(box.has_node("Model/Door") and box.has_node("Solid") and box.palette().size() == 4, "box built: door, solid, 4 wires by default")
	var path_point: Vector3 = game.apartment.get_node("RelocatedSites/Home").to_global(Vector3(1.0, 1.25, 20.6))
	check((path_point - box.global_position).dot(box.facing()) > 0.0, "box faces the entry path, out of the wall")
	var session = game.electrical_box_session
	var panel = game.electrical_box_panel
	check(session != null and panel != null and Board.shared().session("electrical_box") == session, "session and panel wired, on the activity board")
	# Picking from the path in front of the box.
	var front: Vector3 = box.front_center() + box.facing() * 2.5 + Vector3(0, 0.3, 0)
	game.player.global_position = box.front_center() + box.facing() * 1.6 - Vector3(0, 1.25 * 1.3, 0)
	game.player.velocity = Vector3.ZERO
	game.player.set_physics_process(false)
	var aimed: Node3D = await aim(game, front, box.front_center())
	check(aimed == box, "picking ray from the path finds the box (got %s)" % (aimed.name if aimed else "nothing"))
	# E from behind the wall (inside the garage) does nothing.
	game.player.global_position = box.global_position - box.facing() * 1.0
	game.interaction.refresh_focus()
	check(game.interaction.focus != item and session.state == "", "behind the wall the box is not the E target")
	# E beside it opens it.
	game.player.global_position = box.front_center() + box.facing() * 1.2
	var player_camera: Camera3D = game.player.camera
	game.sync_player_controls()
	check(game.player.controls_enabled, "player free before opening")
	game.interaction.refresh_focus()
	check(game.interaction.focus == item and game.interaction.activate_focus() and session.state != "", "E beside the box opens it")
	await process_frame
	check(session.state == "opening" and panel.visible, "opening: panel up (transparent), state opening")
	check(not game.player.controls_enabled, "player locked while the box is open")
	check(Board.shared().blocker("mystery_luna") == "electrical_box", "other games blocked while a box is open")
	check(game.get_viewport().get_camera_3d() != player_camera, "close-up camera took over")
	check(not box.use(), "a second use while open does nothing")
	await wait(Session.ZOOM_SECONDS + 0.2)
	var cam: Camera3D = game.get_viewport().get_camera_3d()
	check(session.state == "playing", "camera arrived: puzzle shown")
	check(absf(box.get_node("Model/Door").rotation.y - box.DOOR_OPEN) < 0.05, "door swung open")
	check(cam != null and cam.global_position.distance_to(box.front_center()) < 3.0 and (box.front_center() - cam.global_position).normalized().dot(-box.facing()) > 0.95, "close-up camera straight in front of the box (%.2f m)" % (cam.global_position.distance_to(box.front_center()) if cam else -1.0))
	check(not game.player.visible, "player hidden during the close-up")
	# Minigame HUD (12 Nov 2026): map, minimap and corner buttons off; Settings gear stays.
	check(game.hud.in_minigame, "HUD knows a minigame is running")
	check(not game.hud.map_button.visible and not game.hud.help_button.visible and not game.hud.bookmark_button.visible and not game.game_launcher.corner_button.visible, "map, help, journal and games buttons hidden in a minigame")
	# The minimap may be switched off entirely (Features.MINIMAP, 14 Nov 2026).
	var mini: Control = minimap(game)
	check((mini == null or not mini.visible) and not game.day_clock.visible, "minimap and day clock hidden in a minigame")
	check(game.hud.settings_button.visible, "Settings gear still shown in a minigame")
	press(game, KEY_M)
	press(game, KEY_J)
	check(not game.hud.is_map_open() and not game.hud.is_journal_open(), "M and J open nothing in a minigame")
	# Shuffled wires.
	var n: int = panel.wires.size()
	var straight := true
	for i in n:
		if panel.wires[i].left != panel.wires[i].right:
			straight = false
	check(n == 4 and not straight, "4 wires, not all straight across")
	check(box._left == panel.wires.map(func(w): return w.left) and box._right == panel.wires.map(func(w): return w.right), "3D wires laid out in the puzzle's order")
	check(box._light.visible, "work light on inside the open box")
	# A wrong drop springs back.
	var wrong_row: int = (panel.wires[0].right + 1) % n
	drop(panel, 0, wrong_row)
	check(not panel.wires[0].connected and panel._returning.has(0), "wrong connector: wire springs back")
	await wait(0.4)
	check(not panel._returning.has(0), "spring-back finished")
	# Dropped far from any connector: back too.
	panel._drop(1, panel._screen(panel.box.rest(1)))
	check(not panel.wires[1].connected, "drop in empty space: not connected")
	# Right drops.
	for i in n - 1:
		drop(panel, i, panel.wires[i].right)
	check(panel.wires.slice(0, n - 1).all(func(w): return w.connected) and not panel._solved, "right connectors snap in; not solved before the last")
	check(panel._wire_at(panel._screen(box.socket(panel.wires[0].right))) != 0, "a connected wire cannot be picked up again")
	check(box._connected[0] and box.tip(0).distance_to(box.socket(panel.wires[0].right)) < 0.001, "3D wire end sits in its socket")
	drop(panel, n - 1, panel.wires[n - 1].right)
	await process_frame
	check(panel._solved and session.state == "solved", "all wires connected: solved")
	check(box.repaired and box._lamp_material.emission.g > box._lamp_material.emission.r, "box repaired: lamp green")
	check(UiText_ok(), "'Electrical Box Repaired!' phrase in every language")
	await wait(Session.SUCCESS_SECONDS - 0.4)
	check(panel.visible and session.state == "solved", "success message still showing")
	await wait(0.4 + Session.RETURN_SECONDS + 0.3)
	check(session.state == "" and not panel.visible, "closed by itself after the message")
	check(game.get_viewport().get_camera_3d() == player_camera, "player camera back")
	check(game.player.visible and game.player.controls_enabled, "player visible and free again")
	await process_frame
	# The map button and minimap come back only when their features are on (14 Nov 2026).
	var mini_after: Control = minimap(game)
	check(not game.hud.in_minigame and game.hud.map_button.visible == Features.FULL_MAP and game.game_launcher.corner_button.visible
		and (mini_after.visible if Features.MINIMAP and mini_after != null else not Features.MINIMAP) and game.day_clock.visible, "map, minimap and buttons back after the game")
	check(absf(box.get_node("Model/Door").rotation.y) < 0.02, "door shut")
	check(not box.repaired and not box._connected.has(true), "closed: box reset (broken, wires loose)")
	check(not root.find_children("ElectricalBoxCamera", "Camera3D", true, false).size() > 0, "temporary camera freed")
	# Esc leaves early, without repairing.
	check(box.use(), "click (use) opens it again")
	check(panel.wires.all(func(w): return not w.connected) and not box._connected.has(true), "reopened: a new unsolved puzzle")
	await wait(Session.ZOOM_SECONDS + 0.2)
	drop(panel, 0, panel.wires[0].right)
	check(game.popups.close_top(), "Esc closes the top popup")
	await wait(Session.RETURN_SECONDS + 0.3)
	check(session.state == "" and not panel.visible and not box.repaired, "Esc: closed, not repaired")
	check(not box._connected.has(true) and not box._light.visible, "Esc: wires back loose, work light off")
	check(game.get_viewport().get_camera_3d() == player_camera and game.player.controls_enabled, "Esc: camera and controls back")
	# Configurable boxes.
	var custom: Node3D = BOX_SCENE.instantiate()
	custom.wire_count = 6
	game.add_child(custom)
	check(custom.palette().size() == 6 and custom.has_node("Model/Wires"), "wire_count 6 gives 6 wires")
	custom.wire_count = 9
	check(custom.palette().size() == 6, "wire_count clamps to 6")
	custom.wire_colors = PackedColorArray([Color.RED, Color.WHITE, Color.BLACK])
	var colors: Array = custom.palette()
	check(colors.size() == 3 and colors[1].color == Color.WHITE and colors[2].symbol == "circle", "wire_colors replace the palette (with symbols)")
	panel.begin(colors, custom)
	check(panel.wires.size() == 3 and custom._wire_nodes.size() == 3, "panel and box take any palette")
	panel.finish()
	custom.queue_free()
	finish()

func minimap(game) -> Control:
	for child in game.hud.ui_root.get_children():
		if child.get_script() == preload("res://scripts/ui/town_minimap.gd"):
			return child
	return null

func press(game, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	game._unhandled_input(event)

func UiText_ok() -> bool:
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	for lang in ["es", "en", "zh"]:
		for id in ["electrical_box.title", "electrical_box.how_to", "electrical_box.repaired", "games.electrical_box"]:
			if not lexicon.phrases.has(id) or not lexicon.phrases[id].has(lang):
				return false
	return true

func finish() -> void:
	print("ELECTRICAL BOX: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
