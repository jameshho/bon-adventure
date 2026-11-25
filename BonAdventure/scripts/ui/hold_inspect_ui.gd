extends Control
## The Inspect button for a held item (user request, 13 Nov 2026; docs/guides/HAND_HOLD.md#inspecting).
## Shown whenever the player holds something (player.hand, hand_hold.gd): a corner-style button
## with a magnifier, left of the touch jump button in the bottom-right corner, the cluster's size (large, touch-sized,
## scales with the window). It opens object_inspector.gd on the held item; while inspecting the
## same spot shows a close button, and Esc (popup stack), E (input claim) or a tap on it
## closes. Player movement and word clicks are off while inspecting (Main.sync_player_controls).
## An item whose hold profile says "auto" (books, user 21 Nov 2026) opens by itself when the
## player picks it up (hand_hold.gd picked_up), after the profile's "delay"; with "tap_close" a
## press anywhere closes it and there is no ✕.
## The Drop button (user, 24 Nov 2026: "add a button for me to drop it"), above Inspect, shows
## while the held item can be dropped (it has a drop() method: farm_egg.gd, which breaks); G does
## the same (`drop` action).

const Inspector := preload("res://scripts/player/object_inspector.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const UiText := preload("res://scripts/language/ui_text.gd")

var main: Node
var hud
var hand: Node3D
var inspector: Node
var inspect_button: Button
var close_button: Button
var drop_button: Button
## The open inspection closes on a press anywhere (its profile's "tap_close"; no ✕ then).
var tap_close := false

func setup(game: Node) -> void:
	main = game
	hud = game.hud
	hand = game.player.hand
	name = "HoldInspect"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.ui_root.add_child(self)
	inspector = Inspector.new()
	inspector.name = "ObjectInspector"
	add_child(inspector)
	inspect_button = _button("Inspect button", "look", open_inspection)
	inspect_button.tooltip_text = "Inspect"
	close_button = _button("Close inspection button", "close", close_inspection)
	close_button.tooltip_text = "Close"
	game.popups.watch(close_button, close_inspection)
	drop_button = _button("Drop button", "drop", drop_held)
	drop_button.tooltip_text = UiText.t("help.drop")
	hud.add_key_hint(drop_button, "drop")
	game.interaction.claim("inspect", inspecting, close_inspection)
	inspector.closed.connect(func(_item): _refresh(); main.sync_player_controls())
	hand.held_changed.connect(func(_item): _refresh())
	hand.picked_up.connect(_on_picked_up)
	# A game taking the inspected item out of the hand (placing a book, clearing a game) ends the
	# close-up at once, so the item is in the hand again to be released.
	hand.releasing.connect(func(item):
		if inspector.is_open() and inspector.item == item:
			inspector.close_now())
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()

func inspecting() -> bool:
	return inspector.is_open()

func open_inspection() -> void:
	if not hand.is_holding() or inspector.is_open():
		return
	var options: Dictionary = hand.inspect_options()
	if inspector.open(hand.held, main.camera, options):
		tap_close = bool(options.get("tap_close", false))
		main.sync_player_controls()
		_refresh()

## The player picked `item` up: an "auto" item opens after its delay, while it is still in the
## hand and nothing covers the screen.
func _on_picked_up(item: Node3D) -> void:
	var options: Dictionary = hand.inspect_options()
	if not bool(options.get("auto", false)):
		return
	var delay := float(options.get("delay", 0.0))
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_instance_valid(item) and hand.held == item and not _covered():
		open_inspection()

## The held item can be dropped (it says how: its drop()).
func can_drop() -> bool:
	return hand.is_holding() and hand.held.has_method("drop")

func drop_held() -> void:
	if can_drop() and not inspector.is_open():
		hand.held.drop()
		_refresh()

func close_inspection() -> void:
	inspector.close()
	_refresh()

## Mouse and keys go to the inspector's modes first (none yet: rotating, opening ... later).
## A tap_close inspection: any press (mouse button or touch), on a button or not, or Esc closes
## it and does nothing else.
func _input(event: InputEvent) -> void:
	if not tap_close or not inspector.is_open():
		return
	var press: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	# Esc too: the popup stack only knows the ✕, which is hidden here.
	if press or event.is_action_pressed("ui_cancel"):
		close_inspection()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop") and not event.is_echo() and drop_button.visible:
		drop_held()
		get_viewport().set_input_as_handled()
		return
	if inspector.is_open() and inspector.handle_input(event):
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	var open: bool = inspector.is_open()
	inspect_button.visible = hand.is_holding() and not open and not _covered() and not _under_dialogue(inspect_button)
	close_button.visible = open and not tap_close
	drop_button.visible = inspect_button.visible and can_drop() and not _under_dialogue(drop_button)
	set_process(hand.is_holding() or open)

## The map, journal, help or money panel is open (the money panel: user, 18 Nov 2026, no
## Inspect while paying).
func _covered() -> bool:
	var paying: bool = main.get("money_panel") != null and main.money_panel.visible
	var poster: bool = main.get("poster_ui") != null and main.poster_ui.inspecting()
	return hud.is_map_open() or hud.is_journal_open() or hud.is_help_open() or paying or poster

func _under_dialogue(button: Control) -> bool:
	if not hud.cluster_cover.is_valid():
		return false
	var cover: Rect2 = hud.cluster_cover.call()
	return cover.has_area() and cover.intersects(Rect2(button.position, button.size))

## Left of the jump button in the bottom-right corner (14 Nov 2026), the cluster buttons' size;
## Drop above it.
func _layout() -> void:
	var slot: Rect2 = hud.bottom_slot(1)
	var gap: float = hud.bottom_slot(0).position.x - slot.end.x
	var jump: Rect2 = hud.jump_slot()
	var rect := Rect2(Vector2(jump.position.x - gap - slot.size.x, jump.end.y - slot.size.y), slot.size)
	for button in [inspect_button, close_button]:
		hud.size_corner_button(button, rect)
	# Drop above Inspect (Run takes the place left of it, touch_controls.gd).
	hud.size_corner_button(drop_button, Rect2(rect.position - Vector2(0, gap + rect.size.y), rect.size))

func _button(title: String, icon: String, handler: Callable) -> Button:
	var button := Button.new()
	button.name = title
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.icon = UiIcons.texture(icon, 128)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.style_corner_button(button)
	button.pressed.connect(handler)
	button.visible = false
	add_child(button)
	return button
