extends Control
## The Inspect button for a held item (user request, 13 Nov 2026; docs/guides/HAND_HOLD.md#inspecting).
## Shown whenever the player holds something (player.hand, hand_hold.gd): a corner-style button
## with a magnifier, left of the touch jump button in the bottom-right corner, the cluster's size (large, touch-sized,
## scales with the window). It opens object_inspector.gd on the held item; while inspecting the
## same spot shows a close button, and Esc (popup stack), E (input claim) or a tap on it
## closes. Player movement and word clicks are off while inspecting (Main.sync_player_controls).

const Inspector := preload("res://scripts/player/object_inspector.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")

var main: Node
var hud
var hand: Node3D
var inspector: Node
var inspect_button: Button
var close_button: Button

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
	game.interaction.claim("inspect", inspecting, close_inspection)
	inspector.closed.connect(func(_item): _refresh(); main.sync_player_controls())
	hand.held_changed.connect(func(_item): _refresh())
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()

func inspecting() -> bool:
	return inspector.is_open()

func open_inspection() -> void:
	if not hand.is_holding() or inspector.is_open():
		return
	if inspector.open(hand.held, main.camera, hand.inspect_options()):
		main.sync_player_controls()
		_refresh()

func close_inspection() -> void:
	inspector.close()
	_refresh()

## Mouse and keys go to the inspector's modes first (none yet: rotating, opening ... later).
func _unhandled_input(event: InputEvent) -> void:
	if inspector.is_open() and inspector.handle_input(event):
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	var open: bool = inspector.is_open()
	var covered: bool = hud.is_map_open() or hud.is_journal_open() or hud.is_help_open()
	inspect_button.visible = hand.is_holding() and not open and not covered and not _under_dialogue(inspect_button)
	close_button.visible = open
	set_process(hand.is_holding() or open)

func _under_dialogue(button: Control) -> bool:
	if not hud.cluster_cover.is_valid():
		return false
	var cover: Rect2 = hud.cluster_cover.call()
	return cover.has_area() and cover.intersects(Rect2(button.position, button.size))

## Left of the jump button in the bottom-right corner (14 Nov 2026), the cluster buttons' size.
func _layout() -> void:
	var slot: Rect2 = hud.bottom_slot(1)
	var gap: float = hud.bottom_slot(0).position.x - slot.end.x
	var jump: Rect2 = hud.jump_slot()
	var rect := Rect2(Vector2(jump.position.x - gap - slot.size.x, jump.end.y - slot.size.y), slot.size)
	for button in [inspect_button, close_button]:
		hud.size_corner_button(button, rect)

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
