extends Control
## Full-screen money-selection UI: the request on top, the payment tray (one stack per
## denomination, click a stack to take one piece back), the bills and coins to click, and a
## bar with the live total, Submit, Clear All and Close. Reusable by any NPC: whoever opens
## it passes the request line and the button texts, and listens for `submitted` and
## `close_requested`. It knows nothing about cashiers, dialogue or the town.
##
## - While it is visible it consumes every key and non-left mouse event (only left clicks or
##   touches work), and Main disables the player's controls (see Main.sync_player_controls).
## - `counts` ({denomination id: count}) survives hide_panel(), so a wrong answer can be
##   retried without losing the selection; reset() clears it for a new round.
## - Layout scales with min(window height / 800, window width / 1100) so the screen works
##   on a narrow, touch-sized window too (pieces wrap onto more rows; tap targets stay big).
const Currency := preload("res://scripts/learning/currency.gd")
const Piece := preload("res://scripts/ui/money_piece.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")
## Hand over: the main action, drawn larger and in the accent colour.
const ACCENT := Color("2f7d6f")

signal submitted(cents: int)
signal close_requested

const FILL := Color("142a38")
const EDGE := Color("7abfb3")
const GOLD := Color("fff1c5")
const DIM := Color("aadddc")
const MAX_EACH := 99
## Bills and coins are drawn larger than the text scale so they are easy to hit on touch.
const PIECE_SCALE := 1.15
const DESIGN := Vector2(1100, 800)
## Tallest the card may be, as a multiple of the window width (keeps a phone-shaped window tidy).
const TALL_LIMIT := 1.35

var counts: Dictionary = {}
var show_native := false
## Text lines, each {"foreign", "native"}: request, tray_title, bills, coins,
## total, submit, clear, close, translate (set by open()).
var ui: Dictionary = {}
## Denomination ids offered (open()'s "only"); empty = all.
var only: Array = []

var _shade: ColorRect
var _card: PanelContainer
var _stack: VBoxContainer
var _pool: VBoxContainer
var _factor := 1.0
var _request_label: Label
var _native_label: Label
## Pinyin under the request when Chinese is the foreign language (GameSettings.reading()).
var _reading_label: Label
var _translate_button: Button
## The session's progress (7/20), left of the translate bubble; hidden without a target.
var progress
var _x_button: Button
var _tray_title: Label
var _tray_box: PanelContainer
var _tray_flow: HFlowContainer
## A faint hand in the empty tray (4 Nov 2026: replaces the "tap the money below" hint).
var _tray_empty: TextureRect
## open()'s "hint" (a String), shown in the empty tray under the hand (the welcome tutorial's
## "Tap the bills and coins to make $2.50.", 17 Nov 2026).
var _tray_hint: Label
var _bills_title: Label
var _bills_flow: HFlowContainer
var _coins_title: Label
var _coins_flow: HFlowContainer
var _total_label: Label
var _clear_button: Button
var _submit_button: Button
var _close_button: Button

func _init() -> void:
	name = "Money panel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.05, 0.08, 0.82)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.anchor_right = 1.0
	_shade.anchor_bottom = 1.0
	add_child(_shade)
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.anchor_left = 0.03
	_card.anchor_right = 0.97
	_card.anchor_top = 0.03
	_card.anchor_bottom = 0.97
	add_child(_card)
	_stack = VBoxContainer.new()
	_card.add_child(_stack)
	_build()
	resized.connect(_on_resized)
	visibility_changed.connect(_on_resized)

func _style(color: Color, border: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	if border:
		style.border_color = EDGE
		style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(handler: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button

func _build() -> void:
	var head := HBoxContainer.new()
	_stack.add_child(head)
	_request_label = _label(GOLD)
	head.add_child(_request_label)
	progress = ProgressBarRow.new()
	head.add_child(progress)
	_translate_button = TranslateButton.new()
	_translate_button.pressed.connect(toggle_translation)
	head.add_child(_translate_button)
	_x_button = _button(func() -> void: close_requested.emit())
	_x_button.icon = UiIcons.texture("close", 64)
	_x_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_x_button)
	_reading_label = PinyinText.style(_label(GOLD.darkened(0.15)))
	_stack.add_child(_reading_label)
	_native_label = _label(DIM)
	_stack.add_child(_native_label)
	_tray_title = _label(DIM)
	_stack.add_child(_tray_title)
	_tray_box = PanelContainer.new()
	_tray_box.add_theme_stylebox_override("panel", _style(Color("0c1c27")))
	_tray_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tray_box.size_flags_stretch_ratio = 3.0
	_stack.add_child(_tray_box)
	var tray_stack := VBoxContainer.new()
	_tray_box.add_child(tray_stack)
	_tray_empty = TextureRect.new()
	_tray_empty.texture = UiIcons.texture("hand", 128)
	_tray_empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tray_empty.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tray_empty.modulate = Color(DIM, 0.35)
	_tray_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_stack.add_child(_tray_empty)
	_tray_hint = _label(GOLD)
	_tray_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tray_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tray_hint.visible = false
	tray_stack.add_child(_tray_hint)
	_tray_flow = HFlowContainer.new()
	_tray_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	tray_stack.add_child(_tray_flow)
	_pool = VBoxContainer.new()
	_pool.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pool.size_flags_stretch_ratio = 2.0
	_pool.alignment = BoxContainer.ALIGNMENT_CENTER
	_stack.add_child(_pool)
	_bills_title = _label(DIM)
	_pool.add_child(_bills_title)
	_bills_flow = HFlowContainer.new()
	_bills_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_pool.add_child(_bills_flow)
	_coins_title = _label(DIM)
	_pool.add_child(_coins_title)
	_coins_flow = HFlowContainer.new()
	_coins_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_pool.add_child(_coins_flow)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_END
	_stack.add_child(bar)
	_total_label = _label(GOLD)
	bar.add_child(_total_label)
	_clear_button = _button(clear)
	_clear_button.icon = UiIcons.texture("trash", 64)
	bar.add_child(_clear_button)
	_submit_button = _button(func() -> void:
		var cents := Currency.total(counts)
		if cents > 0:
			submitted.emit(cents))
	_submit_button.icon = UiIcons.texture("hand", 64)
	for state in ["normal", "hover", "pressed"]:
		var style := _style(ACCENT.lightened(0.12) if state == "hover" else ACCENT)
		style.border_color = GOLD
		_submit_button.add_theme_stylebox_override(state, style)
	var off := _style(Color("1d3442"))
	off.border_color = Color(EDGE, 0.35)
	_submit_button.add_theme_stylebox_override("disabled", off)
	bar.add_child(_submit_button)
	_close_button = _button(func() -> void: close_requested.emit())
	_close_button.icon = UiIcons.texture("close", 64)
	bar.add_child(_close_button)
	for button in [_clear_button, _submit_button, _close_button]:
		button.add_theme_constant_override("h_separation", 10)
		# Disabled buttons fade clearly (nothing to clear or hand over yet).
		button.add_theme_color_override("font_disabled_color", Color(DIM, 0.4))
		button.add_theme_color_override("icon_disabled_color", Color(DIM, 0.4))

# --- Public API ----------------------------------------------------------------------------

## Shows the panel for `lines` (see `ui`). The current selection is kept.
func open(lines: Dictionary) -> void:
	ui = lines
	# "only": the denomination ids to offer (the welcome tutorial: $1 bills and quarters, 17 Nov
	# 2026, user); none = all of Currency.DENOMS.
	only = lines.get("only", [])
	visible = true
	_refresh()

func hide_panel() -> void:
	visible = false

## Forgets the selection (a new round).
func reset() -> void:
	counts.clear()
	if visible:
		_refresh()

func total_cents() -> int:
	return Currency.total(counts)

func add_piece(id: String) -> void:
	if int(counts.get(id, 0)) < MAX_EACH:
		counts[id] = int(counts.get(id, 0)) + 1
		_refresh()

func remove_piece(id: String) -> void:
	if int(counts.get(id, 0)) > 0:
		counts[id] = int(counts[id]) - 1
		if int(counts[id]) == 0:
			counts.erase(id)
		_refresh()

func clear() -> void:
	counts.clear()
	_refresh()

func toggle_translation() -> void:
	show_native = not show_native
	_refresh()

## `done` of `target` rounds (target 0 hides the bar).
func set_progress(done: int, target: int) -> void:
	progress.set_progress(done, target)

## Re-renders after a Display Mode or language change.
func refresh_display() -> void:
	if visible:
		_refresh()

# --- Input lock ------------------------------------------------------------------------------

## Only left clicks / touches reach the buttons and money; every key, wheel and other mouse
## button is swallowed while the panel is open.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Esc passes through to Main's popup stack, which runs close_requested.
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
		return
	if event is InputEventKey or (event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()

# --- Drawing ---------------------------------------------------------------------------------

func _on_resized() -> void:
	if visible:
		_refresh()

func _refresh() -> void:
	if ui.is_empty() or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.5, 3.0)
	var f := _factor
	# In a tall, narrow window the card stops growing taller than its content can fill.
	var share := minf(0.94, TALL_LIMIT * screen.x / screen.y)
	_card.anchor_top = 0.5 - share / 2.0
	_card.anchor_bottom = 0.5 + share / 2.0
	_card.add_theme_stylebox_override("panel", _style(FILL))
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(16 * f)
	_stack.add_theme_constant_override("separation", int(8 * f))
	_set_font(_request_label, 34, f)
	_set_font(_native_label, 24, f)
	_set_font(_reading_label, 22, f)
	_set_font(_tray_title, 22, f)
	_set_font(_bills_title, 22, f)
	_set_font(_coins_title, 22, f)
	_set_font(_total_label, 38, f)
	for button in [_x_button, _clear_button, _submit_button, _close_button]:
		_set_font(button, 24, f)
		button.add_theme_constant_override("icon_max_width", roundi(28 * f))
	_set_font(_submit_button, 28, f)
	_submit_button.add_theme_constant_override("icon_max_width", roundi(34 * f))
	_x_button.custom_minimum_size = Vector2(60, 52) * f
	_translate_button.refresh(show_native, f)
	progress.apply_scale(f)
	_translate_button.tooltip_text = str(ui.get("translate", {}).get("native", ""))
	# Equal widths for the two side buttons; Hand over is the widest and tallest.
	for button in [_clear_button, _close_button]:
		button.custom_minimum_size = Vector2(190, 62) * f
	_submit_button.custom_minimum_size = Vector2(250, 72) * f
	_tray_empty.custom_minimum_size = Vector2(0, 84 * f)
	_set_font(_tray_hint, 26, f)
	_tray_box.custom_minimum_size = Vector2(0, 120 * f)
	(_tray_box.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(18 * f)
	_pool.add_theme_constant_override("separation", int(10 * f))
	for flow in [_tray_flow, _bills_flow, _coins_flow]:
		flow.add_theme_constant_override("h_separation", int(14 * f))
		flow.add_theme_constant_override("v_separation", int(14 * f))
	var shown: Array = GameSettings.shared().view(ui.request, show_native)
	_request_label.text = shown[0]
	PinyinText.show(_reading_label, ui.request)
	_native_label.text = shown[1]
	_native_label.visible = shown[1] != ""
	_tray_title.text = _text(ui.tray_title)
	_bills_title.text = _text(ui.bills)
	_coins_title.text = _text(ui.coins)
	_clear_button.text = GameSettings.shared().stacked(ui.clear, show_native)
	_submit_button.text = GameSettings.shared().stacked(ui.submit, show_native)
	_close_button.text = GameSettings.shared().stacked(ui.close, show_native)
	_total_label.text = "%s: %s" % [_text(ui.total), Currency.usd(Currency.total(counts))]
	_submit_button.disabled = counts.is_empty()
	_clear_button.disabled = counts.is_empty()
	_tray_empty.visible = counts.is_empty()
	_tray_hint.text = str(ui.get("hint", ""))
	_tray_hint.visible = counts.is_empty() and _tray_hint.text != ""
	_fill(_tray_flow)
	for denom in Currency.DENOMS:
		var count := int(counts.get(denom.id, 0))
		if count > 0:
			var piece := Piece.new()
			piece.setup(denom, true, f * PIECE_SCALE)
			piece.set_count(count)
			piece.pressed.connect(remove_piece.bind(str(denom.id)))
			_tray_flow.add_child(piece)
	_fill(_bills_flow)
	_fill(_coins_flow)
	for denom in Currency.DENOMS:
		if not only.is_empty() and not only.has(denom.id):
			continue
		var piece := Piece.new()
		piece.setup(denom, false, f * PIECE_SCALE)
		piece.pressed.connect(add_piece.bind(str(denom.id)))
		(_bills_flow if denom.kind == "bill" else _coins_flow).add_child(piece)

func _text(line: Dictionary) -> String:
	return GameSettings.shared().inline(line, show_native)

func _set_font(node: Control, size: int, factor: float) -> void:
	node.add_theme_font_size_override("font_size", roundi(size * factor))

func _fill(box: Container) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
