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
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal submitted(cents: int)
signal close_requested

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
## The mockup's parts: cream pills and tray, the light bills strip, the soft blue section tags.
const CREAM := Color("fbf1e1")
const STRIP := Color("f1f9fa")
const TAG := Color("e4f4f6")
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
## The coins section tag, hidden with the coins when open()'s "only" offers none (the bank
## teller game: $5, $10, $50 and $100 bills only, 18 Nov 2026).
var _coins_tag: Control
var _total_label: Label
var _request_pill: PanelContainer
var _bills_box: PanelContainer
var _total_pill: PanelContainer
var _basket: TextureRect
var _clear_button: Button
var _submit_button: Button
var _close_button: Button

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Money panel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	_shade = ColorRect.new()
	_shade.color = BonStyle.SHADE
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
	# Layout to the user's mockup (docs/guides/design-references/ui/money-panel.webp, 18 Nov 2026):
	# the request in a cream pill, section tags ("Tu mano", "Billetes", "Monedas"), a cream hand
	# tray, the bills on a light strip, the total in a cream pill with a basket, cream Clear and
	# Leave pills and a green Pay pill. Box sizes are set in _refresh() (they scale with the window).
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_BEGIN
	_stack.add_child(head)
	_request_pill = PanelContainer.new()
	_request_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_request_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(_request_pill)
	_request_label = _label(GOLD)
	_request_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_request_label.add_theme_font_override("font", BonStyle.font(700))
	_request_pill.add_child(_request_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(spacer)
	progress = ProgressBarRow.new()
	head.add_child(progress)
	_translate_button = TranslateButton.new()
	_translate_button.pressed.connect(toggle_translation)
	head.add_child(_translate_button)
	_x_button = _button(func() -> void: close_requested.emit())
	_x_button.icon = UiIcons.texture("close", 64)
	_x_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_x_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_x_button)
	_reading_label = PinyinText.style(_label(GOLD.darkened(0.15)))
	_stack.add_child(_reading_label)
	_native_label = _label(DIM)
	_stack.add_child(_native_label)
	_tray_title = _label(GOLD)
	_stack.add_child(_tag(_tray_title, ""))
	_tray_box = PanelContainer.new()
	_tray_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tray_box.size_flags_stretch_ratio = 3.0
	_stack.add_child(_tray_box)
	var tray_stack := VBoxContainer.new()
	tray_stack.alignment = BoxContainer.ALIGNMENT_CENTER
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
	_bills_title = _label(GOLD)
	_pool.add_child(_tag(_bills_title, "bills"))
	_bills_box = PanelContainer.new()
	_pool.add_child(_bills_box)
	_bills_flow = HFlowContainer.new()
	_bills_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_bills_box.add_child(_bills_flow)
	_coins_title = _label(GOLD)
	_coins_tag = _tag(_coins_title, "coins")
	_pool.add_child(_coins_tag)
	_coins_flow = HFlowContainer.new()
	_coins_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_pool.add_child(_coins_flow)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_END
	_stack.add_child(bar)
	_total_pill = PanelContainer.new()
	_total_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_total_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_total_pill)
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_total_pill.add_child(total_row)
	_basket = TextureRect.new()
	_basket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_basket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	total_row.add_child(_basket)
	_total_label = _label(GOLD)
	_total_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_total_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_total_label.add_theme_font_override("font", BonStyle.font(700))
	total_row.add_child(_total_label)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(gap)
	_clear_button = _button(clear)
	_clear_button.icon = UiIcons.texture("trash", 64)
	bar.add_child(_clear_button)
	_submit_button = _button(func() -> void:
		var cents := Currency.total(counts)
		if cents > 0:
			submitted.emit(cents))
	_submit_button.icon = UiIcons.texture("hand", 64)
	bar.add_child(_submit_button)
	_close_button = _button(func() -> void: close_requested.emit())
	_close_button.icon = UiIcons.texture("close", 64)
	bar.add_child(_close_button)

## A section tag: a small soft blue pill holding `title` (and a BonStyle icon, "" = none). The
## pill is styled in _refresh() (group "money_tag").
func _tag(title: Label, icon: String) -> Control:
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.add_theme_font_override("font", BonStyle.font(700))
	var holder := HBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_to_group("money_tag")
	holder.add_child(pill)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	if icon != "":
		var picture := TextureRect.new()
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.set_meta("icon_name", icon)
		picture.add_to_group("money_tag_icon")
		row.add_child(picture)
	row.add_child(title)
	return holder

## A box of the mockup's parts at the window factor `f`: `fill` inside a white rim.
func _part(fill: Color, radius: float, rim: float, f: float, margin_x: float, margin_y: float, shadow := true) -> StyleBoxFlat:
	var look := BonStyle.flat(fill, roundi(radius * f), maxi(2, roundi(rim * f)), shadow)
	if shadow:
		look.shadow_size = roundi(8 * f)
		look.shadow_offset = Vector2(0, 3 * f)
	look.content_margin_left = margin_x * f
	look.content_margin_right = margin_x * f
	look.content_margin_top = margin_y * f
	look.content_margin_bottom = margin_y * f
	return look

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
	_card.add_theme_stylebox_override("panel", _part(FILL, 44, 7, f, 22, 18))
	_request_pill.add_theme_stylebox_override("panel", _part(CREAM, 40, 5, f, 26, 8))
	_tray_box.add_theme_stylebox_override("panel", _part(CREAM, 30, 5, f, 18, 14, false))
	_bills_box.add_theme_stylebox_override("panel", _part(STRIP, 26, 5, f, 14, 12, false))
	_total_pill.add_theme_stylebox_override("panel", _part(CREAM, 40, 5, f, 26, 8))
	for pill in get_tree().get_nodes_in_group("money_tag"):
		if is_ancestor_of(pill):
			pill.add_theme_stylebox_override("panel", _part(TAG, 24, 4, f, 16, 3, false))
			(pill.get_child(0) as HBoxContainer).add_theme_constant_override("separation", roundi(10 * f))
	for picture in get_tree().get_nodes_in_group("money_tag_icon"):
		if is_ancestor_of(picture):
			picture.texture = BonStyle.icon_texture(str(picture.get_meta("icon_name")), roundi(34 * f))
			picture.custom_minimum_size = Vector2(32, 32) * f
	_basket.texture = BonStyle.icon_texture("basket", roundi(48 * f))
	_basket.custom_minimum_size = Vector2(46, 46) * f
	(_basket.get_parent() as HBoxContainer).add_theme_constant_override("separation", roundi(16 * f))
	BonStyle.style_button(_clear_button, "minor", f, 26)
	BonStyle.style_button(_close_button, "minor", f, 26)
	BonStyle.style_button(_x_button, "minor", f, 26)
	BonStyle.style_button(_submit_button, "primary", f, 30)
	for button in [_clear_button, _close_button, _x_button]:
		for name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
			button.add_theme_color_override(name, GOLD)
	_stack.add_theme_constant_override("separation", int(8 * f))
	_set_font(_request_label, 34, f)
	_set_font(_native_label, 24, f)
	_set_font(_reading_label, 22, f)
	_set_font(_tray_title, 22, f)
	_set_font(_bills_title, 22, f)
	_set_font(_coins_title, 22, f)
	_set_font(_total_label, 38, f)
	for button in [_x_button, _clear_button, _submit_button, _close_button]:
		button.add_theme_constant_override("icon_max_width", roundi(30 * f))
		button.add_theme_constant_override("h_separation", roundi(14 * f))
	_submit_button.add_theme_constant_override("icon_max_width", roundi(40 * f))
	_x_button.custom_minimum_size = Vector2(64, 60) * f
	_translate_button.refresh(show_native, f)
	progress.apply_scale(f)
	_translate_button.tooltip_text = str(ui.get("translate", {}).get("native", ""))
	# Equal widths for the two side buttons; Hand over is the widest and tallest.
	for button in [_clear_button, _close_button]:
		button.custom_minimum_size = Vector2(190, 70) * f
	_submit_button.custom_minimum_size = Vector2(250, 76) * f
	_tray_empty.custom_minimum_size = Vector2(0, 84 * f)
	_set_font(_tray_hint, 26, f)
	_tray_box.custom_minimum_size = Vector2(0, 120 * f)
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
	# In the order the pieces were first picked, left to right (user, 21 Nov 2026): `counts`
	# keeps insertion order, and a denomination taken back out to 0 goes to the end next time.
	for id in counts:
		var denom: Dictionary = Currency.denom(str(id))
		var count := int(counts[id])
		if count > 0 and not denom.is_empty():
			var piece := Piece.new()
			piece.setup(denom, true, f * PIECE_SCALE)
			piece.set_count(count)
			piece.pressed.connect(remove_piece.bind(str(denom.id)))
			_tray_flow.add_child(piece)
	_fill(_bills_flow)
	_fill(_coins_flow)
	var any_coin := only.is_empty() or only.any(func(id) -> bool: return str(Currency.denom(str(id)).get("kind", "")) == "coin")
	_coins_tag.visible = any_coin
	_coins_flow.visible = any_coin
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
