extends Control
## On-screen touch controls (PWA restructure phase 5, 12 Nov 2026; landscape phone, tablet and
## touch laptops). They appear on a touch screen (or after the first touch) and only while the
## player can move; everything they do goes through the same InputMap actions as the keys
## (project.godot, phase 2), so the player, vehicles, swan boats, swings and swivel chairs need
## no touch code of their own:
##   joystick (left side)    move_forward / back / left / right, with strength. Floating (user,
##                           13 Nov 2026: modern and smooth) and, since 14 Nov 2026 (user: do
##                           it the way Roblox does), modelled on Roblox's DynamicThumbstick:
##                           a finger anywhere in the left 40% of the screen (not on the
##                           minimap or the dialogue box) starts the stick exactly where it
##                           landed (Roblox's start area is 40% wide; it is not moved in from
##                           the screen edge). The throw is short: nothing
##                           inside DEAD_ZONE, full speed from FULL_SPEED of the drawn radius
##                           (Roblox: 2 and 20 points), evenly in between, and the player
##                           keeps that strength (player_controller.gd movement_direction()).
##                           The ring is small (STICK_SIZE), so its edge is close to full
##                           speed. Unlike Roblox (user, 14 Nov 2026: do it if it controls
##                           better), a finger that goes past the ring's edge pulls the
##                           stick along behind it, so turning round never takes more than
##                           one ring of travel; inside the ring the stick stays put. The
##                           knob is drawn under the finger. On release the stick glides
##                           back to its resting place bottom left (dimmed). A finger that
##                           lifts without having moved (_tap_slop()) clicks there, like a
##                           tap on the world.
##   E button               "use" (the same as the E key; the focused interactable, standing up,
##                           leaving a vehicle)
##   jump button            "jump" (also brakes a car, climbs in the helicopter and the plane)
##   down button (▼)        "descend", only while flying the helicopter or the plane (easy
##                           flying, 14 Nov 2026, user; docs/guides/aircraft.md#easy-flying): left of
##                           jump, it lowers the aircraft (Shift / Ctrl on a keyboard)
##   lightning button       "debug_hyper" (hyper speed on/off, like the H key; lit while on;
##                           switched off for now: Features.HYPER_SPEED, README.md#hidden-features;
##                           13 Nov 2026, user: phones had no way to turn it on)
##   one finger on the world  drags the view (player.look_by()); a short tap without a drag
##                           clicks there (interaction_controller.gd click(): the "E" badge, an
##                           interactable, a word card)
##   two fingers             pinch to zoom (player.zoom_by())
## Since 14 Nov 2026 (user) jump sits in the bottom-right corner, 25% bigger than the HUD's
## cluster buttons (HUD jump_slot()), with E (cluster size) centred above it; they used to sit
## left of the cluster, whose journal and picker moved to the top right.
## Several fingers work at once (each touch is tracked by its index); the GUI never sees the
## joystick or button touches, and Main leaves a touch's emulated click to the tap here.
## Rules that keep the view still unless a finger drags it (14 Nov 2026, user: the view turned
## by itself on an iPhone):
##   - Finger movement is measured from the positions kept here, never from
##     InputEventScreenDrag.relative: Godot's web build works that out per slot of the browser's
##     changedTouches list, not per finger, so with two fingers down (the stick and anything
##     else, even a resting thumb) it is the distance BETWEEN the fingers and the view jumped.
##   - A touch index is the browser's Touch.identifier: on iOS it is not 0 for the first finger.
##     The finger that owns the emulated mouse is the first one down (_mouse_finger), as in
##     Godot's Input; never test for index 0.
##   - The stick's zone is the whole left 40%, so a thumb there never becomes a view drag.
## The dialogue box always wins (14 Nov 2026, user): a finger on it (or on the quit question or
## the cart) is the GUI's, never the stick's or a button's, so the player can always go on or
## leave a conversation; the E and jump buttons move up above the box if it reaches them. While the
## box waits for an answer (it has choices) the player is locked (Main.sync_player_controls()),
## so these controls hide and the player stands still.
## The word card wins too (16 Nov 2026, user: closing it sometimes started the stick instead):
## it is centred and reaches into the stick zone, so a finger on it (_on_card()) is never the
## stick's or a view drag; it closes the card on release. Any other finger that lands while the
## card shows closes it on release as well (a stick finger even after a wiggle that neither
## tapped nor walked; walking closes it anyway); if the card closed meanwhile (walking, the
## tutorial's card_seconds) that release clicks nothing, so it cannot open another card.
## A panel with its own way out (the fitting room's outfit picker, 14 Nov 2026, user: not
## mobile friendly) hides them too while it shows: put its card Control in the TOUCH_HIDE
## group. The stick and E / jump then never take a finger on it or stand over the screen.
##
## Two real Buttons are kept here too (14 Nov 2026, user), on touch screens AND with a mouse
## (they live in the HUD's ui_root, not in this layer, so they show without touch_mode):
##   Run (hud.run_button)    left of jump, where ▼ sits while flying (Run hides in vehicles, so
##                           they never meet); one more slot left while the Inspect button
##                           (hold_inspect_ui.gd) is there. It fires "sprint" like Shift and is
##                           lit while running is on (player.sprint_enabled). Hidden in a
##                           vehicle, while seated, while these controls hide (player locked, a
##                           TOUCH_HIDE panel), whenever the HUD hides its game buttons
##                           (hud.game_buttons_hidden()) and under the dialogue box.
##   Reset (vehicle.reset_plane)  red, left of E above the ▼ slot, only while flying the plane
##                           (fixed_wing): calls active_vehicle.reset_to_start() when it has one.
## A finger on any real Button in the HUD (these two, the corner buttons, the word card's star
## and translate bubble: _gui_button_at()) is the GUI's and not tracked here, whichever finger
## it is: the Button takes the touch itself, so Run works with a second finger while the first
## holds the stick (16 Nov 2026, user: it did nothing, as this layer used to take that touch as a
## view drag; only the first finger has an emulated click). A mouse click never reaches this layer.
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
## Switched-off features (hyper speed: no lightning button; README.md#hidden-features).
const Features := preload("res://scripts/core/features.gd")
const FILL := Color(0.08, 0.16, 0.22, 0.55)
const EDGE := Color("7abfb3")
const KNOB := Color(1, 0.95, 0.8, 0.85)
const GOLD := Color("fff1c5")
const HYPER := Color("00BFFF")
## Group of panels that hide these controls while they are visible (see the header).
const TOUCH_HIDE := "touch_hide"
## Joystick: the left part of the screen that starts it (fraction of the window: 0.4, as
## Roblox's DynamicThumbstick start frame in landscape, Roblox/Core-Scripts
## DynamicThumbstick.lua; 0.5 until 14 Nov 2026, user: too much of the screen), the ring's
## radius (fraction of a corner button's side; 0.95 until 14 Nov 2026, when half the ring did
## nothing), its dead zone and where full speed starts (fractions of the drawn radius; about 2
## and 20 points on a phone, Roblox's values), and how fast the drawn stick goes home (per second).
const STICK_ZONE_WIDTH := 0.4
const STICK_SIZE := 0.6
const DEAD_ZONE := 0.06
const FULL_SPEED := 0.7
const STICK_RETURN := 10.0
## Finger travel below which a touch is a tap, not a drag: at least this many pixels, and
## TAP_SHARE of the stick's radius (about 10 points on a phone; 14 raw pixels were under 5).
const TAP_PIXELS := 14.0
const TAP_SHARE := 0.33
## Touch drag to view turn, relative to the mouse orbit's sensitivity.
const LOOK_SPEED := 1.4
## Camera distance per pixel of pinch.
const PINCH_SPEED := 0.03

var main: Node
var player: Node
var hud: Node
## Shown on a touch screen or after the first touch.
var touch_mode := false

## Where the stick is now (follows the finger), and its resting place.
var _stick_center := Vector2.ZERO
var _stick_home := Vector2.ZERO
## Drawn positions, eased towards the real ones every frame.
var _drawn_center := Vector2.ZERO
var _drawn_knob := Vector2.ZERO
var _stick_radius := 90.0
var _stick_finger := -1
var _stick_vector := Vector2.ZERO
## Where the stick finger is and how far it has travelled (under TAP_PIXELS: a tap).
var _stick_at := Vector2.ZERO
var _stick_travel := 0.0
var _use_rect := Rect2()
var _jump_rect := Rect2()
var _hyper_rect := Rect2()
var _down_rect := Rect2()
## finger index -> the action its button holds ("use" / "jump" / "debug_hyper").
var _button_fingers: Dictionary = {}
## World fingers (not on a control): index -> position.
var _world: Dictionary = {}
var _tap_finger := -1
var _tap_travel := 0.0
var _pinch := 0.0
## The finger that owns the emulated mouse: the first one down while none was (as Godot's Input
## picks it; -1 none). Its emulated click reached the world (no GUI control took it): only then
## is that finger a tap or a view drag. Other fingers have no emulated click.
var _mouse_finger := -1
var _first_on_world := false
## Fingers that landed while a word card showed: index -> whether on the card itself (see the
## header: such a finger closes the card on release and never clicks the world).
var _card_fingers: Dictionary = {}
## What was last drawn (redrawn only when it changes).
var _drawn: Array = []
## The welcome tutorial's "move" cue (16 Nov 2026): the resting stick pulses, undimmed, until a
## finger takes it. Set with highlight_stick().
var _highlight := false
var _font: Font
## The Run toggle and the plane's Reset (see the header), and the styles they swap.
var run_button: Button
var reset_button: Button
var _run_styles: Dictionary = {}
const RUN_LIT := [Color("2b7a70"), Color("fff1c5")]
const RESET_RED := [Color("b3261e"), Color("ff9c8f")]

func _init() -> void:
	name = "TouchControls"
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(game: Node) -> void:
	main = game
	player = game.player
	hud = game.hud
	touch_mode = DisplayServer.is_touchscreen_available()
	hud.set_touch_mode(touch_mode)
	_font = get_theme_default_font()
	run_button = _hud_button("Run button", func() -> void: _fire_once("sprint"))
	_run_styles = {false: _styles(null), true: _styles(RUN_LIT)}
	reset_button = _hud_button("Reset plane button", _reset_plane)
	_apply_styles(reset_button, _styles(RESET_RED))
	reset_button.add_theme_color_override("font_color", Color.WHITE)

func _process(delta: float) -> void:
	_update_hud_buttons()
	var shown: bool = touch_mode and is_instance_valid(player) and player.controls_enabled and not _hidden_by_panel()
	if visible != shown:
		visible = shown
		_drawn = []
		if not shown:
			_release_all()
	if visible:
		_layout()
		if _stick_finger < 0:
			_stick_center = _stick_home
		# Held: exactly under the finger (easing lagged it at a phone's frame rate). Released:
		# it glides home.
		var follow := 1.0 if _stick_finger >= 0 else 1.0 - exp(-STICK_RETURN * delta)
		_drawn_center = _drawn_center.lerp(_stick_center, follow)
		_drawn_knob = _drawn_knob.lerp(_stick_vector * _stick_radius, follow)
		if _stick_finger < 0 and _drawn_center.distance_to(_stick_center) < 0.5 and _drawn_knob.length() < 0.5:
			_drawn_center = _stick_center
			_drawn_knob = Vector2.ZERO
		var state: Array = [_drawn_center, _drawn_knob, _stick_radius, _stick_finger >= 0, _use_rect, _jump_rect, _down_rect, _button_fingers.values(), player.hyper_enabled]
		if state != _drawn:
			_drawn = state
			queue_redraw()
		if _highlight:
			queue_redraw()

## The welcome tutorial points at the joystick (tutorial.gd "cue": "move"): its ring pulses
## while `on`.
func highlight_stick(on: bool) -> void:
	_highlight = on
	queue_redraw()

func _layout() -> void:
	var view := get_viewport_rect().size
	# Jump in the bottom-right corner, 25% bigger than a cluster button; E centred above it
	# (14 Nov 2026, user; both were left of the cluster); the lightning button above E.
	var side: float = hud.bottom_slot(0).size.x
	var gap := roundf(side * 0.12)
	_jump_rect = hud.jump_slot()
	var column_x := _jump_rect.get_center().x - side * 0.5
	_use_rect = Rect2(Vector2(column_x, _jump_rect.position.y - gap - side), Vector2(side, side))
	# No lightning button while hyper speed is switched off (Features.HYPER_SPEED).
	_hyper_rect = Rect2(Vector2(column_x, _use_rect.position.y - gap - side), Vector2(side, side)) if Features.HYPER_SPEED else Rect2()
	# The ▼ (descend) button, left of jump and level with its centre, only while flying.
	_down_rect = Rect2(Vector2(_jump_rect.position.x - gap - side, _jump_rect.get_center().y - side * 0.5), Vector2(side, side)) if _flying() else Rect2()
	# On a narrow window the dialogue box can reach the buttons: while it shows, they stand
	# above it (its ✕ once sat on the jump button). The order cart hangs from the top right:
	# lifting above it would push them off the screen, so a button under it hides meanwhile
	# (a phone in landscape, 14 Nov 2026), as the HUD's cluster buttons do under the box.
	var cover := _dialogue_cover(false)
	if cover.has_area() and cover.intersects(Rect2(_jump_rect.position.x, 0.0, _jump_rect.size.x, view.y)):
		var lift := _jump_rect.end.y - (cover.position.y - gap)
		if lift > 0.0:
			for rect in ["_use_rect", "_jump_rect", "_hyper_rect", "_down_rect"]:
				var moved: Rect2 = get(rect)
				if moved.has_area():
					set(rect, Rect2(moved.position - Vector2(0.0, lift), moved.size))
	var panel: Control = main.get("shop_panel") if main != null else null
	if panel != null and panel.cart_card.is_visible_in_tree():
		var cart: Rect2 = panel.cart_card.get_global_rect()
		for rect in ["_use_rect", "_jump_rect", "_hyper_rect", "_down_rect"]:
			if cart.intersects(get(rect)):
				set(rect, Rect2())
	_stick_radius = side * STICK_SIZE
	_stick_home = Vector2(28.0 + _stick_radius * 1.1, view.y - 28.0 - _stick_radius * 1.1)
	if _drawn_center == Vector2.ZERO:
		_drawn_center = _stick_home
	# The HUD's "SPRINT" / "HYPER SPEED" line sits bottom left, under the joystick: lift it
	# above the stick while the controls show (the HUD lays it out again on a resize).
	hud.movement_label.position.y = _stick_home.y - _stick_radius * 1.1 - 36.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not touch_mode:
			touch_mode = true
			hud.set_touch_mode(true)
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed and _mouse_finger == -1:
		_mouse_finger = touch.index
	if visible:
		_handle(event)
	if touch != null and not touch.pressed and touch.index == _mouse_finger:
		_mouse_finger = -1
		_first_on_world = false

func _handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch(event)
	elif event is InputEventScreenDrag:
		_drag(event)
	elif event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
		# The emulated click of a touch on a control is ours (the GUI and the world never see it).
		if _on_control(event.position):
			get_viewport().set_input_as_handled()

# --- Run and Reset (real Buttons, touch and mouse; see the header) ---------------------------

func _hud_button(title: String, handler: Callable) -> Button:
	var button := Button.new()
	button.name = title
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_text = false
	button.visible = false
	button.pressed.connect(handler)
	hud.ui_root.add_child(button)
	return button

## The corner buttons' box (hud.style_corner_button) or `colors` [fill, edge] for every state.
func _styles(colors: Variant) -> Dictionary:
	var looks := {}
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var fill: Color = Color("142a38") if colors == null else colors[0]
		var edge: Color = Color("7abfb3") if colors == null else colors[1]
		if state == "pressed" or state == "hover_pressed":
			fill = fill.darkened(0.2)
		looks[state] = hud.make_ui_card(fill, edge, 12)
	return looks

func _apply_styles(button: Button, looks: Dictionary) -> void:
	for state in looks:
		if button.get_theme_stylebox(state) != looks[state]:
			button.add_theme_stylebox_override(state, looks[state])
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

## Places, labels and shows the Run and Reset buttons every frame.
func _update_hud_buttons() -> void:
	if not is_instance_valid(player) or hud == null:
		return
	var side: float = hud.bottom_slot(0).size.x
	var gap := roundf(side * 0.12)
	var jump: Rect2 = hud.jump_slot()
	var run_rect := Rect2(Vector2(jump.position.x - gap - side, jump.get_center().y - side * 0.5), Vector2(side, side))
	var inspect: Control = main.hold_ui.inspect_button if main != null and main.get("hold_ui") != null else null
	if inspect != null and inspect.visible:
		run_rect.position.x = inspect.position.x - gap - side
	var reset_rect := Rect2(Vector2(jump.position.x - gap - side, jump.position.y - gap - side * 2.0), Vector2(side, side))
	var vehicle: Variant = main.get("active_vehicle") if main != null else null
	var driving := is_instance_valid(vehicle)
	var free: bool = player.controls_enabled and not _hidden_by_panel() and not hud.is_map_open() and not hud.is_journal_open() and not hud.is_help_open()
	var cover := _dialogue_cover()
	_place(run_button, run_rect, UiText.t("hud.run_button"),
			free and not driving and not player.seated and not hud.game_buttons_hidden() and not cover.intersects(run_rect))
	_apply_styles(run_button, _run_styles[player.sprint_enabled])
	var gold := Color("fff1c5")
	run_button.add_theme_color_override("font_color", gold if player.sprint_enabled else Color("fff2d8"))
	run_button.add_theme_color_override("font_hover_color", gold)
	_place(reset_button, reset_rect, UiText.t("vehicle.reset_plane"),
			free and driving and bool(vehicle.get("fixed_wing")) and not cover.intersects(reset_rect))

func _place(button: Button, rect: Rect2, text: String, shown: bool) -> void:
	button.visible = shown
	if not shown:
		return
	if button.text != text:
		button.text = text
	if button.position != rect.position or button.size != rect.size:
		button.custom_minimum_size = rect.size
		button.size = rect.size
		button.position = rect.position
	# The word fills about 70% of the button's width, never more than a quarter of its side tall.
	var font := button.get_theme_font("font")
	var width := maxf(1.0, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x)
	var size := clampi(roundi(minf(rect.size.x * 0.25, rect.size.x * 0.7 * 100.0 / width)), 10, 200)
	if button.get_theme_font_size("font_size") != size:
		button.add_theme_font_size_override("font_size", size)

## A single tap of `action` (pressed and released), as the key would send it.
func _fire_once(action: String) -> void:
	_fire(action, true)
	_fire(action, false)

func _reset_plane() -> void:
	var vehicle: Variant = main.get("active_vehicle") if main != null else null
	if is_instance_valid(vehicle) and vehicle.has_method("reset_to_start"):
		vehicle.reset_to_start()

## Whether a TOUCH_HIDE panel shows (the outfit picker).
func _hidden_by_panel() -> bool:
	for card in get_tree().get_nodes_in_group(TOUCH_HIDE):
		if card.is_visible_in_tree():
			return true
	return false

## Whether the player flies the helicopter or the plane (the ▼ button shows).
func _flying() -> bool:
	var vehicle: Variant = main.get("active_vehicle") if main != null else null
	return is_instance_valid(vehicle) and vehicle.has_method("is_aircraft") and vehicle.is_aircraft()

func _on_control(at: Vector2) -> bool:
	return _in_stick_zone(at) or _button_at(at) != ""

## The shared dialogue box (with the quit question and, unless `with_cart` is false, the cart)
## where it is on screen: a finger there is always the GUI's (see the header). Empty while
## nothing shows.
func _dialogue_cover(with_cart := true) -> Rect2:
	var panel: Control = main.get("shop_panel") if main != null else null
	if panel == null:
		return Rect2()
	var cover := Rect2()
	for card in [panel.dialogue_card, panel.quit_card] + ([panel.cart_card] if with_cart else []):
		if card.is_visible_in_tree():
			cover = card.get_global_rect() if not cover.has_area() else cover.merge(card.get_global_rect())
	return cover

func _on_dialogue(at: Vector2) -> bool:
	var panel: Control = main.get("shop_panel") if main != null else null
	if panel == null:
		return false
	for card in [panel.dialogue_card, panel.quit_card, panel.cart_card]:
		if card.is_visible_in_tree() and card.get_global_rect().has_point(at):
			return true
	return false

## The open word card (hud.popup_panel) under a point. It is centred and wide enough to reach
## into the stick zone (1280 x 800: x 280-1000, the zone ends at 512; 844 x 390: x 242-602, the
## zone ends at 338), so a finger on it must never start the stick (user, 16 Nov 2026).
func _on_card(at: Vector2) -> bool:
	return hud.is_card_visible() and hud.popup_panel.get_global_rect().has_point(at)

## The visible, enabled real Button (Run, Reset, the corner buttons, the word card's star and
## translate bubble: anything in the HUD's ui_root) under a point, or null. A finger there is the
## GUI's, the first or any later one (user, 16 Nov 2026: Run did nothing while the stick was
## held, because this layer took the second finger's touch as a view drag).
func _gui_button_at(at: Vector2) -> BaseButton:
	return _find_button(hud.ui_root, at) if hud != null and hud.ui_root != null else null

func _find_button(node: Node, at: Vector2) -> BaseButton:
	for i in range(node.get_child_count() - 1, -1, -1):
		var child := node.get_child(i) as Control
		if child == null or not child.visible or child == self:
			continue
		var found := _find_button(child, at)
		if found != null:
			return found
		if child is BaseButton and not child.disabled and child.mouse_filter != Control.MOUSE_FILTER_IGNORE and child.get_global_rect().has_point(at):
			return child
	return null

## The left 40% of the screen, where a finger starts the joystick (not on a button, a real
## Button, the dialogue box, the word card, or the minimap in the top left corner, which keeps
## its own tap).
func _in_stick_zone(at: Vector2) -> bool:
	var view := get_viewport_rect().size
	if _button_at(at) != "" or _on_dialogue(at) or _on_card(at) or _gui_button_at(at) != null:
		return false
	var map_side: float = hud.minimap_side
	if map_side > 0.0 and at.x <= 16.0 + map_side and at.y <= 16.0 + map_side:
		return false
	return at.x <= view.x * STICK_ZONE_WIDTH or at.distance_to(_stick_home) <= _stick_radius * 1.25

func _touch(event: InputEventScreenTouch) -> void:
	var index := event.index
	if event.pressed:
		if _on_dialogue(event.position) or _gui_button_at(event.position) != null:
			# The dialogue box's or a real Button's: left to the GUI (the touch itself, which a
			# Button takes from any finger, and the first finger's emulated click), not tracked here.
			return
		if hud.is_card_visible():
			_card_fingers[index] = _on_card(event.position)
			if _card_fingers[index]:
				# On the word card: it closes on release, never the stick or a view drag.
				get_viewport().set_input_as_handled()
				return
		if _stick_finger < 0 and _in_stick_zone(event.position):
			_stick_finger = index
			# The stick starts exactly under the finger and stays there.
			_stick_center = event.position
			_drawn_center = _stick_center
			_stick_at = event.position
			_stick_travel = 0.0
			_move_stick(_stick_center)
		elif _button_at(event.position) != "":
			var action := _button_at(event.position)
			_button_fingers[index] = action
			_fire(action, true)
		else:
			_world[index] = event.position
			if _world.size() == 1:
				_tap_finger = index
				_tap_travel = 0.0
			else:
				# A second finger: a pinch, never a tap.
				_tap_finger = -1
				_pinch = _pinch_distance()
		get_viewport().set_input_as_handled()
		return
	# A finger that landed while a word card showed: if the card still shows it closes it
	# (_click() does only that then), also after a wiggle that neither tapped nor walked; if the
	# card closed meanwhile (walking, card_seconds), its release clicks nothing.
	var card_finger := _card_fingers.has(index)
	var on_card: bool = _card_fingers.get(index, false)
	_card_fingers.erase(index)
	var card_open: bool = hud.is_card_visible()
	if on_card:
		if card_open:
			_click(event.position)
		return
	if index == _stick_finger:
		_stick_finger = -1
		_move_stick(_stick_center)
		_stick_center = _stick_home
		if (card_open and card_finger) or (_stick_travel < _tap_slop() and not card_finger):
			_click(event.position)
	elif _button_fingers.has(index):
		_fire(_button_fingers[index], false)
		_button_fingers.erase(index)
	elif _world.has(index):
		_world.erase(index)
		if index == _tap_finger and _tap_travel < _tap_slop() and _counts(index) and (card_open or not card_finger):
			_click(event.position)
		if index == _tap_finger:
			_tap_finger = -1
		_pinch = _pinch_distance()

## A tap: a click on the world where the finger was.
func _click(at: Vector2) -> void:
	main.interaction.pointer_position = at
	main.interaction.click()
	main.sync_player_controls()

func _drag(event: InputEventScreenDrag) -> void:
	var index := event.index
	if index == _stick_finger:
		_stick_travel += event.position.distance_to(_stick_at)
		_stick_at = event.position
		# Past the ring's edge the stick is pulled along, one radius behind the finger.
		var offset: Vector2 = event.position - _stick_center
		if offset.length() > _stick_radius:
			_stick_center = event.position - offset.normalized() * _stick_radius
		_move_stick(event.position)
	elif _world.has(index):
		# Not event.relative: see the header (wrong on the web with two fingers down).
		var moved: Vector2 = event.position - _world[index]
		_world[index] = event.position
		if not _counts(index):
			return
		if _world.size() >= 2:
			var distance := _pinch_distance()
			player.zoom_by((_pinch - distance) * PINCH_SPEED)
			_pinch = distance
		else:
			if index == _tap_finger:
				_tap_travel += moved.length()
			if _tap_travel >= _tap_slop() or index != _tap_finger:
				player.look_by(moved * LOOK_SPEED)

## Finger travel (pixels) below which a touch is a tap.
func _tap_slop() -> float:
	return maxf(TAP_PIXELS, _stick_radius * TAP_SHARE)

## The action of the button under a point ("" when none).
func _button_at(at: Vector2) -> String:
	if _on_dialogue(at):
		return ""
	if _use_rect.has_point(at):
		return "use"
	if _jump_rect.has_point(at):
		return "jump"
	if _hyper_rect.has_point(at):
		return "debug_hyper"
	if _down_rect.has_point(at):
		return "descend"
	return ""

## Whether a world finger counts (the mouse finger only when its click reached the world).
func _counts(index: int) -> bool:
	return index != _mouse_finger or _first_on_world

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_first_on_world = true

func _pinch_distance() -> float:
	var points: Array = _world.values()
	return points[0].distance_to(points[1]) if points.size() >= 2 else 0.0

## The joystick: the four move actions with strength, from where the finger is relative to
## where it started: 0 inside the dead zone, rising evenly to 1 at FULL_SPEED of the radius.
func _move_stick(at: Vector2) -> void:
	_stick_vector = (at - _stick_center) / _stick_radius
	var reach := clampf((_stick_vector.length() - DEAD_ZONE) / (FULL_SPEED - DEAD_ZONE), 0.0, 1.0)
	var amount := _stick_vector.normalized() * reach if reach > 0.0 else Vector2.ZERO
	_set_action("move_right", maxf(amount.x, 0.0))
	_set_action("move_left", maxf(-amount.x, 0.0))
	_set_action("move_back", maxf(amount.y, 0.0))
	_set_action("move_forward", maxf(-amount.y, 0.0))

func _set_action(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

## A button press or release, as an action event (Main and the player react to the event).
func _fire(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func _release_all() -> void:
	if _stick_finger >= 0 or _stick_vector != Vector2.ZERO:
		_stick_finger = -1
		_move_stick(_stick_center)
		_stick_center = _stick_home
	for index in _button_fingers:
		_fire(_button_fingers[index], false)
	_button_fingers.clear()
	_world.clear()
	_tap_finger = -1
	_card_fingers.clear()

func _draw() -> void:
	if _drawn_center == Vector2.ZERO:
		return
	# Dimmed at rest, full while a finger holds it.
	var active := 1.0 if _stick_finger >= 0 or _highlight else 0.6
	draw_circle(_drawn_center, _stick_radius, Color(FILL, FILL.a * active))
	draw_arc(_drawn_center, _stick_radius, 0.0, TAU, 64, Color(EDGE, active), 2.0, true)
	draw_circle(_drawn_center + _drawn_knob, _stick_radius * 0.5, Color(KNOB, KNOB.a * active))
	if _highlight and _stick_finger < 0:
		# A gold ring swells out of the stick and fades (the tutorial's cue).
		var pulse := fmod(Time.get_ticks_msec() / 1100.0, 1.0)
		draw_arc(_drawn_center, _stick_radius * (1.08 + 0.45 * pulse), 0.0, TAU, 64, Color(GOLD, 1.0 - pulse), maxf(3.0, _stick_radius * 0.09), true)
	for spec in [[_use_rect, "use"], [_jump_rect, "jump"], [_hyper_rect, "debug_hyper"], [_down_rect, "descend"]]:
		if spec[0].size == Vector2.ZERO:
			continue
		var rect: Rect2 = spec[0]
		var held: bool = _button_fingers.values().has(spec[1]) or (spec[1] == "debug_hyper" and player.hyper_enabled)
		var center := rect.get_center()
		var radius := rect.size.x * 0.5
		draw_circle(center, radius, FILL.lightened(0.25) if held else FILL)
		draw_arc(center, radius, 0.0, TAU, 64, EDGE, 2.0, true)
		if spec[1] == "use":
			# The same "E" as the in-world badge.
			var size := roundi(radius * 0.9)
			var text_size := _font.get_string_size("E", HORIZONTAL_ALIGNMENT_CENTER, -1, size)
			draw_string(_font, center + Vector2(-text_size.x * 0.5, text_size.y * 0.32), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, size, GOLD)
		elif spec[1] == "debug_hyper":
			# A lightning bolt (hyper speed's colour on the HUD while it is on).
			var w := radius * 0.5
			var bolt := PackedVector2Array([center + Vector2(w * 0.25, -w), center + Vector2(-w * 0.45, w * 0.1), center + Vector2(w * 0.05, w * 0.1), center + Vector2(-w * 0.25, w)])
			draw_polyline(bolt, HYPER if player.hyper_enabled else GOLD, maxf(3.0, radius * 0.1), true)
		else:
			# Jump: an up chevron; descend: the same, upside down.
			var w := radius * 0.42
			var flip := -1.0 if spec[1] == "descend" else 1.0
			draw_polyline(PackedVector2Array([center + Vector2(-w, w * 0.45 * flip), center + Vector2(0, -w * 0.55 * flip), center + Vector2(w, w * 0.45 * flip)]), GOLD, maxf(3.0, radius * 0.1), true)
