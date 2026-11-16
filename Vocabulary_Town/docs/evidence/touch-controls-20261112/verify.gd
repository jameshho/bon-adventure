extends SceneTree
## Touch controls (PWA phase 5, 12 Nov 2026): the joystick drives the move actions with strength,
## the E and jump buttons hold "use" / "jump", one finger on the world turns the view, two pinch
## the zoom, a short tap clicks where it landed; everything hides while the player is locked,
## and the PANELS locks flag (it replaced the LOCKING list) locks exactly the old panels.
## 14 Nov 2026 (the view turned by itself on an iPhone; the stick felt jerky): the stick alone
## never turns the view, also with a second finger down and the wrong `relative` Godot's web
## build reports then, and with iOS-style touch indices; a part push walks at part speed.
## 14 Nov 2026 (user: dialogue and help on touch): the stick zone is the left 40%; a finger on
## the dialogue box is never the stick's or a button's (the buttons stand above the box); the
## player stands still while the box shows choices; no word card opens from a click while the
## box shows; the F1 guide has a finger-sized ✕.
## 16 Nov 2026 (user): the word card beats the stick; Run works with a second finger
## (card_and_run()).
## Isolated HOME (Main runs):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/touch-controls-20261112/verify.gd
## Prints "TOUCH CONTROLS: N checks, M failures".
const MinigameWiring := preload("res://scripts/core/minigame_wiring.gd")
var controls: Control
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	# Straight to the controls: headless runs drop input outside their 64 x 64 window.
	controls._input(event)

func drag(index: int, from: Vector2, to: Vector2, relative: Variant = null) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.relative = to - from if relative == null else relative
	controls._input(event)

## The emulated click of the first finger reaching the world (no GUI control took it).
func world_click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	controls._unhandled_input(event)

## Moves the touch buttons out of the 64 x 64 headless window (no layout meanwhile), or back.
var _parked: Array = []
func park_buttons(on: bool) -> void:
	controls.set_process(not on)
	if on:
		_parked = [controls._use_rect, controls._jump_rect, controls._hyper_rect]
		for name in ["_use_rect", "_jump_rect", "_hyper_rect"]:
			controls.set(name, Rect2(Vector2(5000, 5000), Vector2(10, 10)))
	elif not _parked.is_empty():
		controls._use_rect = _parked[0]
		controls._jump_rect = _parked[1]
		controls._hyper_rect = _parked[2]

func frames(n: int) -> void:
	for i in n:
		await process_frame

func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	controls = game.hud.ui_root.get_node("TouchControls")
	check(controls != null, "Main adds the touch controls")
	if controls == null:
		print("TOUCH CONTROLS: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	controls.touch_mode = true
	# The HUD's real Buttons (Run, the corner buttons) cover most of the 64 x 64 headless window,
	# and a finger on one is the GUI's (16 Nov 2026): they take no fingers here, except Run in
	# card_and_run().
	var muted := mute_buttons(game)
	await frames(2)
	check(controls.visible, "shown in touch mode while the player can move")
	# The first finger down owns the emulated mouse click; world_click() stands in for it.
	var r: float = controls._stick_radius
	# The headless window (64 x 64) lies wholly under the minimap, which is not the stick's.
	var map_side: float = game.hud.minimap_side
	game.hud.minimap_side = 0.0
	# The stick starts exactly under the finger (Roblox style, 14 Nov 2026).
	var home: Vector2 = controls._stick_home
	var c: Vector2 = home
	touch(1, home, true)
	drag(1, home, c + Vector2(0, -r))
	check(Input.get_action_strength("move_forward") > 0.9 and Input.get_action_strength("move_back") == 0.0, "joystick up: move_forward")
	# Short throw: full speed from FULL_SPEED of the radius, evenly from the dead zone below it.
	var part: float = (controls.DEAD_ZONE + controls.FULL_SPEED) * 0.5
	drag(1, c + Vector2(0, -r), c + Vector2(r * part, 0))
	check(absf(Input.get_action_strength("move_right") - 0.5) < 0.02 and not Input.is_action_pressed("move_forward"), "joystick part right: move_right %.2f" % Input.get_action_strength("move_right"))
	drag(1, c + Vector2(r * part, 0), c + Vector2(r * controls.FULL_SPEED, 0))
	check(Input.get_action_strength("move_right") > 0.99, "full speed at the short throw")
	drag(1, c + Vector2(r * controls.FULL_SPEED, 0), c + Vector2(r * controls.DEAD_ZONE * 0.5, 0))
	check(not Input.is_action_pressed("move_right"), "inside the dead zone: no movement")
	touch(1, c, false)
	check(not Input.is_action_pressed("move_right"), "joystick released: no movement")
	# Floating stick: it starts under a finger anywhere in the left 40%, is pulled along one
	# radius behind a finger that passes the ring's edge, and goes home on release. The headless
	# window is smaller than the jump button (bottom right since 14 Nov 2026): park the buttons
	# meanwhile.
	park_buttons(true)
	var view: Vector2 = controls.get_viewport_rect().size
	var start := Vector2(view.x * 0.3, view.y * 0.6)
	touch(1, start, true)
	check(controls._stick_center == start, "the stick appears under the finger")
	var far := start + Vector2(r * 3.0, 0)
	drag(1, start, far)
	check(Input.get_action_strength("move_right") > 0.95 and controls._stick_center.distance_to(far - Vector2(r, 0)) < 0.01, "past the ring the stick follows one radius behind")
	var back := far - Vector2(r * (1.0 + controls.FULL_SPEED), 0)
	drag(1, far, back)
	check(Input.get_action_strength("move_left") > 0.95 and not Input.is_action_pressed("move_right") and controls._stick_center.distance_to(far - Vector2(r, 0)) < 0.01, "back across the pulled stick: the other way, the stick stays put inside the ring")
	far = back
	touch(1, far, false)
	await frames(1)
	check(not Input.is_action_pressed("move_right") and controls._stick_center == controls._stick_home, "released: the stick goes home")
	park_buttons(false)
	await frames(1)
	var use_at: Vector2 = controls._use_rect.get_center()
	touch(2, use_at, true)
	await frames(1)
	check(Input.is_action_pressed("use"), "E button holds use")
	touch(2, use_at, false)
	await frames(1)
	check(not Input.is_action_pressed("use"), "E button released")
	var jump_at: Vector2 = controls._jump_rect.get_center()
	touch(3, jump_at, true)
	await frames(1)
	check(Input.is_action_pressed("jump"), "jump button holds jump")
	touch(3, jump_at, false)
	await frames(1)
	var world := Vector2(400, 300)
	var yaw: float = game.player.camera_yaw
	touch(4, world, true)
	world_click(world)
	drag(4, world, world + Vector2(60, 0))
	check(not is_equal_approx(game.player.camera_yaw, yaw), "a finger drag on the world turns the view")
	touch(4, world + Vector2(60, 0), false)
	var distance: float = game.player.camera_distance
	touch(5, world, true)
	touch(6, world + Vector2(40, 0), true)
	drag(6, world + Vector2(40, 0), world + Vector2(240, 0))
	check(game.player.camera_distance < distance, "pinching out zooms in (%.2f -> %.2f)" % [distance, game.player.camera_distance])
	touch(5, world, false)
	touch(6, world + Vector2(240, 0), false)
	var tap := Vector2(321, 234)
	game.interaction.pointer_position = Vector2.ZERO
	touch(7, tap, true)
	world_click(tap)
	touch(7, tap, false)
	check(game.interaction.pointer_position == tap, "a short tap clicks where it landed")
	park_buttons(true)
	await stick_and_view(game, r, view, world)
	await card_and_run(game)
	park_buttons(false)
	await frames(1)
	await dialogue_and_help(game, view)
	# The locks flag in PANELS.
	var locking: Array = MinigameWiring.PANELS.filter(func(spec) -> bool: return spec.size() > 2 and spec[2]).map(func(spec): return spec[0])
	check(locking == ["money_panel", "family_panel", "flight_panel", "restaurant_panel", "restaurant_menu_book", "detective_card", "mahjong_panel", "mahjong_lessons", "radar_panel", "electrical_box_panel", "elevator_floor_picker", "game_launcher"], "the locks flag marks the old LOCKING panels (plus the elevator floor picker, 14 Nov 2026): %s" % str(locking))
	game.warehouse_card.visible = true
	check(not MinigameWiring.locks_player(game), "the warehouse card does not lock the player")
	game.warehouse_card.visible = false
	game.money_panel.visible = true
	game.sync_player_controls()
	await frames(2)
	check(MinigameWiring.locks_player(game) and not controls.visible, "a locking panel locks the player and hides the touch controls")
	game.money_panel.visible = false
	game.sync_player_controls()
	game.hud.minimap_side = map_side
	for button in muted:
		button.mouse_filter = muted[button]
	print("TOUCH CONTROLS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## 14 Nov 2026: the stick never turns the view; its strength reaches the player.
func stick_and_view(game: Node, r: float, view: Vector2, world: Vector2) -> void:
	var player: Node = game.player
	var yaw: float = player.camera_yaw
	var pitch: float = player.camera_pitch
	# iOS-style indices (Touch.identifier: never 0, never reused). The stick finger alone,
	# starting high in the left half and pulled far past the rim.
	var start := Vector2(view.x * 0.35, view.y * 0.05)
	# Past 40% only the ring around the stick's resting place is the stick's (the headless
	# 64 x 64 window is mostly that ring, so test the rule, not a fixed point).
	var outside := Vector2(view.x * 0.45, view.y * 0.05)
	check(controls.STICK_ZONE_WIDTH == 0.4 and controls._in_stick_zone(outside) == (outside.distance_to(controls._stick_home) <= controls._stick_radius * 1.25), "the stick's zone ends at 40% of the width")
	touch(41, start, true)
	check(controls._stick_finger == 41, "a thumb at the top of the left 40% starts the stick")
	game.hud.minimap_side = 208.0
	check(not controls._in_stick_zone(Vector2(120, 120)) and controls._in_stick_zone(Vector2(view.x * 0.2, 300)), "the minimap corner is not the stick's")
	game.hud.minimap_side = 0.0
	var at := start
	for step in [Vector2(r, 0), Vector2(r * 2.0, -r), Vector2(-r * 3.0, r * 2.0), Vector2(0, -r * 4.0)]:
		drag(41, at, at + step)
		at += step
	check(player.camera_yaw == yaw and player.camera_pitch == pitch, "the stick alone leaves the view still")
	# A second finger rests on the world while the stick moves. Godot's web build then reports
	# `relative` as the distance between the two fingers: the view must use real movement only.
	touch(42, world, true)
	drag(41, at, at + Vector2(r, 0), world - at)
	at += Vector2(r, 0)
	drag(42, world, world, at - world)
	check(player.camera_yaw == yaw and player.camera_pitch == pitch, "a resting second finger with a wrong relative leaves the view still")
	drag(42, world, world + Vector2(20, 0), at - world)
	check(is_equal_approx(player.camera_yaw, yaw - 20.0 * controls.LOOK_SPEED * player.mouse_sensitivity), "the second finger turns the view by its own movement")
	touch(42, world + Vector2(20, 0), false)
	touch(41, at, false)
	check(not Input.is_action_pressed("move_forward") and controls._stick_finger == -1 and controls._world.is_empty(), "both fingers lifted: nothing held")
	# The first finger on a GUI control (its emulated click never reaches the world) is not a
	# view drag, whatever its index.
	yaw = player.camera_yaw
	touch(43, world, true)
	drag(43, world, world + Vector2(80, 0))
	touch(43, world + Vector2(80, 0), false)
	check(player.camera_yaw == yaw, "a first finger taken by the GUI does not turn the view")
	# A stick finger that lifts without moving is a tap.
	var tap := Vector2(view.x * 0.2, view.y * 0.7)
	game.interaction.pointer_position = Vector2.ZERO
	touch(44, tap, true)
	touch(44, tap, false)
	check(game.interaction.pointer_position == tap, "a tap in the stick's zone clicks where it landed")
	# Strength reaches the player: a part push walks at part speed, the rim at full speed.
	var home: Vector2 = controls._stick_home
	touch(45, home, true)
	var c: Vector2 = controls._stick_center
	var part: float = (controls.DEAD_ZONE + controls.FULL_SPEED) * 0.5
	drag(45, home, c + Vector2(0, -r * part))
	# The stick is held: the controls may lay out (and draw) again.
	park_buttons(false)
	await frames(1)
	check(controls._drawn_knob.distance_to(Vector2(0, -r * part)) < 0.01, "the drawn knob is under the finger")
	var want: float = Input.get_action_strength("move_forward")
	check(absf(player.movement_direction().length() - want) < 0.01 and absf(want - 0.5) < 0.02, "part push: direction strength %.2f" % player.movement_direction().length())
	for i in 40:
		await physics_frame
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	check(absf(speed - player.walk_speed * want) < 0.05, "half push walks at part speed (%.2f of %.2f m/s)" % [speed, player.walk_speed])
	drag(45, c + Vector2(0, -r * part), c + Vector2(0, -r))
	for i in 40:
		await physics_frame
	speed = Vector2(player.velocity.x, player.velocity.z).length()
	check(absf(speed - player.walk_speed) < 0.05, "full push walks at full speed (%.2f m/s)" % speed)
	touch(45, c + Vector2(0, -r), false)
	for i in 40:
		await physics_frame
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01 and player.camera_yaw == yaw, "released: stopped, the view never turned")
	# Keys are unchanged: full speed, also on a diagonal.
	Input.action_press("move_forward")
	Input.action_press("move_right")
	check(absf(player.movement_direction().length() - 1.0) < 0.001, "two keys: full speed on the diagonal")
	Input.action_release("move_right")
	check(absf(player.movement_direction().length() - 1.0) < 0.001, "one key: full speed")
	Input.action_release("move_forward")

## Every BaseButton in the HUD's ui_root stops taking fingers; returns their old filters.
func mute_buttons(game: Node) -> Dictionary:
	var muted := {}
	var stack: Array = [game.hud.ui_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is BaseButton:
			muted[node] = node.mouse_filter
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return muted

## A real touch through Input (the viewport, then the GUI), not straight to the controls.
func real_touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(2)

## 16 Nov 2026 (user): a finger on the word card closes it and never starts the stick; a card
## that closed by itself before the finger lifts clicks nothing; Run (a real Button) works with a
## second finger while the first holds the stick. The headless window is 64 x 64: the card is
## moved to its right part, the stick finger stays left (x < 40%), and only Run of the HUD's
## Buttons takes fingers (mute_buttons()).
func card_and_run(game: Node) -> void:
	var hud: Node = game.hud
	var interaction: Node = game.interaction
	# The E and jump buttons too (stick_and_view() puts them back).
	park_buttons(true)
	var on_card := Vector2(52, 30)
	var stick_at := Vector2(10, 30)
	var show := func() -> void:
		hud.show_card("Tree", "Árbol", "Everyday", "")
		hud.popup_panel.position = Vector2(40, -60)
	show.call()
	await frames(1)
	# The HUD centres the card again a frame after show_card().
	hud.popup_panel.position = Vector2(40, -60)
	check(controls._on_card(on_card) and not controls._in_stick_zone(on_card) and controls._in_stick_zone(stick_at), "the open word card is not the stick's zone")
	# A finger on the card that wiggles past the tap slop: no stick, no view turn, it closes.
	var yaw: float = game.player.camera_yaw
	touch(61, on_card, true)
	check(controls._stick_finger == -1 and not controls._world.has(61), "a finger on the word card does not start the stick")
	var step := Vector2(controls._tap_slop() * 0.8, 0)
	drag(61, on_card, on_card + step)
	drag(61, on_card + step, on_card)
	check(is_equal_approx(game.player.camera_yaw, yaw), "a finger on the word card does not turn the view")
	touch(61, on_card, false)
	check(not hud.is_card_visible(), "lifting a finger on the word card closes it")
	# The stick finger (beside the card) wiggling without walking closes the card too.
	show.call()
	await frames(1)
	# The HUD centres the card again a frame after show_card().
	hud.popup_panel.position = Vector2(40, -60)
	touch(62, stick_at, true)
	check(controls._stick_finger == 62, "beside the card the stick still starts")
	drag(62, stick_at, stick_at + Vector2(0, controls._tap_slop() * 0.8))
	drag(62, stick_at + Vector2(0, controls._tap_slop() * 0.8), stick_at)
	touch(62, stick_at, false)
	check(not hud.is_card_visible(), "a stick wiggle that did not walk closes the word card")
	# The card closes by itself (the tutorial's card_seconds) under a finger: no click after.
	show.call()
	await frames(1)
	# The HUD centres the card again a frame after show_card().
	hud.popup_panel.position = Vector2(40, -60)
	interaction.pointer_position = Vector2(-7, -7)
	touch(63, on_card, true)
	interaction.clear_card()
	touch(63, on_card, false)
	check(interaction.pointer_position == Vector2(-7, -7) and not hud.is_card_visible(), "a card that closed by itself: the finger's release clicks nothing")
	interaction.pointer_position = Vector2(-7, -7)
	touch(64, stick_at, true)
	touch(64, stick_at, false)
	check(interaction.pointer_position == stick_at, "with no card a stick tap still clicks where it landed")
	interaction.clear_card()
	# Run with a second finger while the first holds the stick (real events through the GUI).
	var run: Button = controls.run_button
	var run_index := run.get_index()
	run.mouse_filter = Control.MOUSE_FILTER_STOP
	run.get_parent().move_child(run, -1)
	run.visible = true
	run.position = Vector2(40, 10)
	run.size = Vector2(20, 20)
	var run_at := Vector2(50, 20)
	check(controls._gui_button_at(run_at) == run and not controls._in_stick_zone(run_at), "Run is the GUI's, not the stick's or the world's")
	var sprint: bool = game.player.sprint_enabled
	await real_touch(65, stick_at, true)
	check(controls._stick_finger == 65, "the first finger holds the stick")
	await real_touch(66, run_at, true)
	check(not controls._world.has(66), "a second finger on Run is not a view drag")
	await real_touch(66, run_at, false)
	check(game.player.sprint_enabled != sprint, "Run works with a second finger while the stick is held")
	await real_touch(65, stick_at, false)
	# The first finger alone on Run: one toggle (its touch and emulated click press it once).
	await real_touch(67, run_at, true)
	await real_touch(67, run_at, false)
	check(game.player.sprint_enabled == sprint, "Run with one finger toggles once")
	if game.player.sprint_enabled != sprint:
		game.player.sprint_enabled = sprint
	run.get_parent().move_child(run, run_index)
	run.mouse_filter = Control.MOUSE_FILTER_IGNORE

## 14 Nov 2026: the dialogue box beats the stick and the buttons; no walking while it asks; the
## F1 guide's ✕ closes it.
func dialogue_and_help(game: Node, view: Vector2) -> void:
	var player: Node = game.player
	var panel: Control = game.shop_panel
	# A line without choices (a tutorial hint): the player stays free, the box takes its taps.
	panel.show_dialogue("Test", {"foreign": "Hola", "native": "Hello"})
	await frames(3)
	var card: Rect2 = panel.dialogue_card.get_global_rect()
	check(player.controls_enabled and controls.visible, "a line without choices leaves the player free")
	var on_card := Vector2(card.position.x + card.size.x * 0.1, card.get_center().y)
	check(controls._on_dialogue(on_card) and not controls._in_stick_zone(on_card) and controls._button_at(on_card) == "", "a point on the box is neither the stick's nor a button's")
	touch(51, on_card, true)
	check(controls._stick_finger == -1 and not controls._world.has(51), "a finger on the box is left to the box")
	touch(51, on_card, false)
	check(not controls._use_rect.intersects(card) and not controls._jump_rect.intersects(card), "the E and jump buttons stand above the box")
	# No word card from a click or tap while the box shows (a word_filter step excepted).
	var interaction: Node = game.interaction
	check(interaction.dialogue_open.is_valid() and interaction.dialogue_open.call(), "Main tells the interaction controller the box is open")
	interaction.pointer_position = root.get_visible_rect().size * 0.5
	var aimed: Node3D = interaction.aimed_object()
	var studied: Array = []
	var count := func(key: String) -> void: studied.append(key)
	interaction.word_studied.connect(count)
	if aimed != null:
		interaction.clear_card()
		interaction.click()
		check(studied.is_empty() and interaction.selected == null, "no word card while the box shows (%s)" % aimed.name)
	else:
		print("NOTE: nothing aimed at the window centre; the word-card gate was not clicked")
	panel.hide_dialogue()
	await frames(2)
	if aimed != null and interaction.aimed_object() == aimed:
		interaction.click()
		check(studied.size() == 1, "the word card opens again once the box closes")
		interaction.clear_card()
	interaction.word_studied.disconnect(count)
	if DisplayServer.get_name() != "headless":
		check(not controls._use_rect.intersects(card) or controls._use_rect.position.y > card.position.y, "the buttons go back down when the box closes")
	# A question (choices): the player stands still, the stick hides, keys do nothing.
	panel.show_dialogue("Test", {"foreign": "¿Sí?", "native": "Yes?"}, [{"id": "test_yes", "label": {"foreign": "Sí", "native": "Yes"}}])
	await frames(2)
	Input.action_press("move_forward")
	check(not player.controls_enabled and not controls.visible and player.movement_direction() == Vector3.ZERO, "a question locks the player and hides the touch controls")
	for i in 20:
		await physics_frame
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "W does not walk during a question")
	Input.action_release("move_forward")
	# Something else switching the controls on (a fade's end) does not free the player.
	player.set_controls_enabled(true)
	await frames(2)
	check(not player.controls_enabled, "the lock holds while the question shows")
	panel.hide_dialogue()
	await frames(2)
	check(player.controls_enabled and controls.visible, "closing the box frees the player")
	# The layout (14 Nov 2026, user): jump in the bottom-right corner, 25% bigger than a cluster
	# button, E centred above it; journal and games in a row under the gear; no help button.
	var hud: Node = game.hud
	var cluster: Rect2 = hud.bottom_slot(0)
	var jump: Rect2 = controls._jump_rect
	check(jump.end.is_equal_approx(cluster.end) and is_equal_approx(jump.size.x, roundf(cluster.size.x * 1.25)), "jump fills the bottom-right corner, 25%% bigger (%.0f px)" % jump.size.x)
	check(controls._use_rect.end.y < jump.position.y and absf(controls._use_rect.get_center().x - jump.get_center().x) < 0.5, "E stands centred above jump")
	check(not hud.help_button.visible, "the help button is hidden")
	var top_row: Array = [hud.bookmark_button.get_rect(), game.game_launcher.corner_button.get_rect()]
	var others: Array = [hud.settings_button.get_rect(), hud.peek_button.get_rect(), game.day_clock.pill.get_global_rect() if game.day_clock != null and game.day_clock.get("pill") != null else Rect2()]
	# Only with graphics: the headless 64 x 64 window is smaller than one button.
	if DisplayServer.get_name() != "headless":
		check(top_row.all(func(rect: Rect2) -> bool: return others.all(func(other: Rect2) -> bool: return not rect.intersects(other))) and top_row[1].end.x <= top_row[0].position.x, "journal and games sit under the gear, clear of the top buttons and clock")
	# The F1 guide: a finger-sized ✕ closes it and frees the player (the ? button too).
	game.hud.toggle_help()
	await frames(2)
	var close: Button = game.hud.help_close
	check(close != null and close.is_visible_in_tree() and close.custom_minimum_size.x >= 52.0, "the F1 guide shows a finger-sized ✕")
	check(not player.controls_enabled, "the open guide locks the player")
	close.pressed.emit()
	await frames(2)
	check(not game.hud.is_help_open() and player.controls_enabled, "the ✕ closes the guide and frees the player")
