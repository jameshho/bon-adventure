extends Control
## The waiter's order tablet of the Alta Cocina restaurant game (11 Nov 2026; first built
## 6 Nov 2026 as a full-screen panel). It only draws what restaurant_session.gd gives it and
## emits signals; it knows nothing about orders or words. Text arrives as {"foreign",
## "native"} lines.
##
## A tablet (dark bezel round a light screen) over the dining room, not full screen. Header
## bar: title, progress, translate bubble, ✕. Left: the customer's portrait and name, the
## order in a speech bubble (foreign text, pinyin for Chinese, the translation only after the
## translate bubble; which courses: "Quisiera pedir una entrada y una bebida."), then the order
## slip: one row per course asked (2-3 since 11 Nov 2026) with the customer's request for it and
## the dish chosen for it, and "Send order" once every course has one. Right: four
## course tabs (the courses asked framed: teal, green once chosen); the left page lists the course's
## dishes (picture, name, price); tapping one opens it on the right page: its picture and
## name, the five tastes as rows (icon, then three pill bars: coloured for the level, grey for
## the rest; a faded icon for zero), a cold-to-hot thermometer and the icons of its
## ingredients, and "Choose this dish" (courses asked only), which puts it on the slip and
## opens the next course still without a dish. No property is written as a word (the posters
## teach the words). After Send the tablet shows the dishes and "Order sent!", and the session
## closes it. The session also shows the practised words at the end (show_summary(), Finish).
##
## - While visible it swallows every key and non-left mouse event (as flight_panel.gd), and
##   Main disables the player's controls (Main.sync_player_controls).
## - Layout scales with min(window height / 800, window width / 1100) (UI decision,
##   4 Nov 2026: large tap targets, text that scales with a laptop window).
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")
const Portraits := preload("res://scripts/ui/plush_portraits.gd")
const FoodIcons := preload("res://scripts/ui/food_icons.gd")

## Every course asked with its chosen dish id ({course: id}).
signal send_pressed(picks: Dictionary)
signal finish_pressed
signal close_requested

const BEZEL := Color("1c1e23")
const BEZEL_EDGE := Color("454952")
const SCREEN := Color("f6f1e7")
const HEADER := Color("1f4a47")
const CREAM := Color("fff4dc")
const GOLD := Color("e9c46a")
const SIDE := Color("ebe3d2")
const RIGHT := Color("3f7d4a")
const PAGE := Color("fffdf8")
const INK := Color("2b2420")
const RULE := Color("ddd2bc")
const BUBBLE := Color("ffffff")
const TAB_COLORS := [Color("9fd39a"), Color("f0c96a"), Color("e8a0a0"), Color("8fc3e8")]
const DESIGN := Vector2(1100, 800)

var show_native := false
## Set by open(): {title, translate, speaker (line), species, order (line), requests {course:
## line}, hint (line),
## pick_course (line), courses [{id, title (line)}], wanted [course ids asked, in order], menu
## {course: [dish]}, schema {tastes [[id, colour]], temperature_colors, tags [ids in display
## order]}, choose, send, sent, close, finish (lines)}. A dish: {id, name (line), price, art,
## taste {id: level}, temperature, has [tags]}.
var ui: Dictionary = {}
## The open menu section and the chosen dish (kept across refreshes).
var tab := ""
var inspected := ""
## The dish chosen for each course asked ({course: id}).
var picks: Dictionary = {}
## The dishes sent ({} until Send order).
var sent: Dictionary = {}
## Shown instead of the menu at the end: {"title": line, "lines": [lines]}.
var summary: Dictionary = {}
var feedback: Dictionary = {}

var _factor := 1.0
## The order bubble's text size (1 = normal), lowered by _fit_left() until the customer column
## fits the tablet (three requests with the translation and pinyin are long).
var _bubble_scale := 1.0
var _fitting := false
var _device: PanelContainer
var _screen: PanelContainer
var _stack: VBoxContainer
var _header: PanelContainer
var _title: Label
var progress
var _translate: Button
var _x: Button
var _margin: MarginContainer
var _body: HBoxContainer
var _left: PanelContainer
var _portrait: TextureRect
var _speaker: Label
var _bubble: PanelContainer
var _order: Label
var _reading: Label
var _native: Label
var _slip: VBoxContainer
var _send: Button
var _close: Button
var _finish: Button
var _book: VBoxContainer
var _tabs: HBoxContainer
var _pages: HBoxContainer
var _list_page: PanelContainer
var _list: VBoxContainer
var _detail_page: PanelContainer
var _detail: VBoxContainer
var _pick_slot: VBoxContainer
var _summary_box: VBoxContainer
var _sent_box: VBoxContainer
var portraits

func _init() -> void:
	name = "Restaurant panel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.04, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	add_child(shade)
	portraits = Portraits.new()
	portraits.name = "Portraits"
	add_child(portraits)
	_device = PanelContainer.new()
	_device.name = "Tablet"
	_device.mouse_filter = Control.MOUSE_FILTER_STOP
	_device.anchor_left = 0.055
	_device.anchor_right = 0.945
	_device.anchor_top = 0.045
	_device.anchor_bottom = 0.955
	add_child(_device)
	_screen = PanelContainer.new()
	_screen.name = "Screen"
	_device.add_child(_screen)
	_stack = VBoxContainer.new()
	_screen.add_child(_stack)
	_build()
	resized.connect(_on_resized)
	visibility_changed.connect(_on_resized)

func _style(color: Color, border: Color = RULE, width: int = 2, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
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
	_header = PanelContainer.new()
	_header.name = "Header"
	_stack.add_child(_header)
	var head := HBoxContainer.new()
	_header.add_child(head)
	_title = _label(CREAM)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.size_flags_vertical = Control.SIZE_FILL
	head.add_child(_title)
	progress = ProgressBarRow.new()
	head.add_child(progress)
	_translate = TranslateButton.new()
	_translate.pressed.connect(toggle_translation)
	head.add_child(_translate)
	_x = _button(func() -> void: close_requested.emit())
	_x.name = "Close tablet"
	_x.icon = UiIcons.texture("close", 64)
	_x.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_x)
	_margin = MarginContainer.new()
	_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stack.add_child(_margin)
	_body = HBoxContainer.new()
	_margin.add_child(_body)
	# Left column: the customer and the order.
	_left = PanelContainer.new()
	_left.name = "Customer"
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.size_flags_stretch_ratio = 0.37
	_body.add_child(_left)
	var column := VBoxContainer.new()
	_left.add_child(column)
	var who := HBoxContainer.new()
	column.add_child(who)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	who.add_child(_portrait)
	_speaker = _label(INK)
	_speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speaker.size_flags_vertical = Control.SIZE_FILL
	who.add_child(_speaker)
	_bubble = PanelContainer.new()
	_bubble.name = "Order bubble"
	column.add_child(_bubble)
	var said := VBoxContainer.new()
	_bubble.add_child(said)
	_order = _label(INK)
	said.add_child(_order)
	_reading = PinyinText.style(_label(INK.lightened(0.25)))
	said.add_child(_reading)
	_native = _label(INK.lightened(0.35))
	said.add_child(_native)
	_slip = VBoxContainer.new()
	_slip.name = "Order slip"
	column.add_child(_slip)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	_send = _button(func() -> void:
		if can_send():
			send_pressed.emit(picks.duplicate()))
	_send.name = "Send"
	_send.icon = UiIcons.texture("check", 64)
	column.add_child(_send)
	_finish = _button(func() -> void: finish_pressed.emit())
	_finish.name = "Finish"
	_finish.icon = UiIcons.texture("check", 64)
	column.add_child(_finish)
	_close = _button(func() -> void: close_requested.emit())
	_close.name = "Close"
	_close.icon = UiIcons.texture("close", 64)
	column.add_child(_close)
	# Right: the menu.
	_book = VBoxContainer.new()
	_book.name = "Menu"
	_book.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book.size_flags_stretch_ratio = 0.63
	_body.add_child(_book)
	_tabs = HBoxContainer.new()
	_book.add_child(_tabs)
	_pages = HBoxContainer.new()
	_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_book.add_child(_pages)
	_list_page = PanelContainer.new()
	_list_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_page.size_flags_stretch_ratio = 0.46
	_pages.add_child(_list_page)
	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_page.add_child(list_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(_list)
	_detail_page = PanelContainer.new()
	_detail_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_page.size_flags_stretch_ratio = 0.54
	_pages.add_child(_detail_page)
	# The dish scrolls if it must; Choose this dish stays pinned under it.
	var detail_column := VBoxContainer.new()
	_detail_page.add_child(detail_column)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_column.add_child(detail_scroll)
	_pick_slot = VBoxContainer.new()
	detail_column.add_child(_pick_slot)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_detail)
	_summary_box = VBoxContainer.new()
	_summary_box.name = "Summary"
	_summary_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_box.visible = false
	_book.add_child(_summary_box)
	_sent_box = VBoxContainer.new()
	_sent_box.name = "Sent"
	_sent_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sent_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_sent_box.visible = false
	_book.add_child(_sent_box)

# --- Public API ------------------------------------------------------------------------

## Shows the tablet with an order: opens the first course asked, nothing chosen yet.
func open(lines: Dictionary) -> void:
	ui = lines
	sent = {}
	picks = {}
	summary = {}
	feedback = {}
	var wanted: Array = ui.get("wanted", [])
	tab = str(wanted[0]) if not wanted.is_empty() else ""
	inspected = ""
	_bubble_scale = 1.0
	visible = true
	_refresh()

func hide_panel() -> void:
	visible = false

## The order went to the kitchen: the tablet shows the dishes and "Order sent!".
func show_sent(dishes: Dictionary) -> void:
	sent = dishes.duplicate()
	_refresh()

## The end of a session: the practised words instead of the menu, and Finish.
func show_summary(title: Dictionary, lines: Array, line: Dictionary) -> void:
	summary = {"title": title, "lines": lines}
	feedback = line
	visible = true
	_refresh()

func toggle_translation() -> void:
	show_native = not show_native
	_bubble_scale = 1.0
	_refresh()

func set_progress(done: int, target: int) -> void:
	progress.set_progress(done, target)

func refresh_display() -> void:
	if visible:
		_refresh()

func show_tab(course: String) -> void:
	tab = course
	inspected = ""
	_refresh()

func inspect(id: String) -> void:
	inspected = id
	_refresh()

## Whether "Choose this dish" works: a dish of a course asked, not already chosen.
func can_choose() -> bool:
	return sent.is_empty() and summary.is_empty() and _wanted().has(tab) and not _dish(inspected).is_empty() and str(picks.get(tab, "")) != inspected

## Puts the inspected dish on the slip and opens the next course asked without a dish.
func choose() -> void:
	if not can_choose():
		return
	picks[tab] = inspected
	for course in _wanted():
		if not picks.has(course):
			tab = course
			inspected = ""
			break
	_refresh()

## Whether "Send order" works: every course asked has a dish, nothing sent yet.
func can_send() -> bool:
	if not sent.is_empty() or not summary.is_empty() or _wanted().is_empty():
		return false
	for course in _wanted():
		if _dish(str(picks.get(course, ""))).is_empty():
			return false
	return true

func _wanted() -> Array:
	return ui.get("wanted", []).map(func(c): return str(c))

## Only left clicks reach the buttons; every key, wheel and other mouse button is swallowed
## while the tablet is open (the wheel still scrolls the pages under the pointer). Esc goes
## to Main's popup stack.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
		return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
	if event is InputEventKey or (event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()

# --- Drawing -----------------------------------------------------------------------------

func _on_resized() -> void:
	if visible:
		_bubble_scale = 1.0
		_refresh()

## Smaller order text while the tablet's content is taller than the tablet (its anchored
## height), one step per layout pass; no scroll bar (UI decision, 9 Nov 2026).
## Measured a frame after the change, once the columns have their widths (an earlier
## measure sees narrow, tall text and shrinks too far).
func _fit_left() -> void:
	if _fitting:
		return
	_fitting = true
	while visible and _bubble_scale > 0.6:
		await get_tree().process_frame
		var room := get_viewport_rect().size.y * (_device.anchor_bottom - _device.anchor_top)
		if _device.get_combined_minimum_size().y <= room + 1.0:
			break
		_bubble_scale -= 0.05
		_bubble_fonts()
	_fitting = false

func _bubble_fonts() -> void:
	_set_font(_order, 22 * _bubble_scale)
	_set_font(_reading, 16 * _bubble_scale)
	_set_font(_native, 18 * _bubble_scale)
	if _slip.visible:
		_fill_slip()

func _text(line: Variant) -> String:
	return GameSettings.shared().inline(line, show_native)

func _stacked(line: Variant) -> String:
	return GameSettings.shared().stacked(line, show_native)

func _set_font(node: Control, font: float) -> void:
	node.add_theme_font_size_override("font_size", roundi(font * _factor))

func _dish(id: String) -> Dictionary:
	for course in ui.get("menu", {}):
		for entry in ui.menu[course]:
			if str(entry.id) == id:
				return entry
	return {}

## A flat button style set (normal, hover, pressed, disabled) in `fill`.
func _paint_button(button: Button, fill: Color, border: Color, font: Color, radius: int) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var tint := fill
		if state == "hover":
			tint = fill.lightened(0.1)
		elif state == "pressed":
			tint = fill.darkened(0.1)
		elif state == "disabled":
			tint = Color("b8b0a2")
		button.add_theme_stylebox_override(state, _style(tint, border, 2, radius))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(key, font)
	button.add_theme_color_override("font_disabled_color", Color("f2eee6"))

func _refresh() -> void:
	if ui.is_empty() or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.5, 3.0)
	var f := _factor
	var bezel := _style(BEZEL, BEZEL_EDGE, 2, int(34 * f))
	bezel.set_content_margin_all(18 * f)
	bezel.shadow_color = Color(0, 0, 0, 0.45)
	bezel.shadow_size = int(18 * f)
	_device.add_theme_stylebox_override("panel", bezel)
	var glass := _style(SCREEN, Color("0d0e10"), 2, int(18 * f))
	glass.set_content_margin_all(0)
	_screen.add_theme_stylebox_override("panel", glass)
	var header := _style(HEADER, HEADER, 0, int(18 * f))
	header.corner_radius_bottom_left = 0
	header.corner_radius_bottom_right = 0
	header.content_margin_left = 18 * f
	header.content_margin_right = 10 * f
	header.content_margin_top = 8 * f
	header.content_margin_bottom = 8 * f
	_header.add_theme_stylebox_override("panel", header)
	_set_font(_title, 22)
	_title.text = GameSettings.shared().view(ui.title, false)[0]
	_x.custom_minimum_size = Vector2(60, 52) * f
	_x.add_theme_constant_override("icon_max_width", roundi(28 * f))
	_paint_button(_x, HEADER.lightened(0.12), HEADER.lightened(0.3), CREAM, int(12 * f))
	_translate.refresh(show_native, f)
	_translate.tooltip_text = str(ui.get("translate", {}).get("native", ""))
	progress.apply_scale(f)
	progress.visible = progress.target > 0
	# The body sits inside the screen with a margin (the header runs edge to edge).
	var inset := int(14 * f)
	for side in ["left", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, inset)
	_margin.add_theme_constant_override("margin_top", 0)
	_body.add_theme_constant_override("separation", inset)
	_stack.add_theme_constant_override("separation", inset)
	# Customer column.
	var left_style := _style(SIDE, RULE, 0, int(14 * f))
	left_style.set_content_margin_all(12 * f)
	_left.add_theme_stylebox_override("panel", left_style)
	_portrait.texture = portraits.texture(str(ui.get("species", "")))
	_portrait.custom_minimum_size = Vector2(72, 72) * f
	_set_font(_speaker, 24)
	_speaker.text = _text(ui.get("speaker", {}))
	var bubble_style := _style(BUBBLE, RULE, 2, int(16 * f))
	bubble_style.set_content_margin_all(14 * f)
	_bubble.add_theme_stylebox_override("panel", bubble_style)
	var said: Dictionary = feedback if not summary.is_empty() else ui.get("order", {})
	var shown: Array = GameSettings.shared().view(said, show_native)
	_bubble_fonts()
	_fit_left.call_deferred()
	_order.text = str(shown[0])
	PinyinText.show(_reading, said)
	_native.text = str(shown[1])
	_native.visible = str(shown[1]) != ""
	_slip.visible = summary.is_empty()
	_fill_slip()
	for button in [_close, _finish, _send]:
		_set_font(button, 22)
		button.custom_minimum_size = Vector2(0, 60) * f
		button.add_theme_constant_override("icon_max_width", roundi(26 * f))
		button.add_theme_constant_override("h_separation", int(10 * f))
	_close.text = _stacked(ui.get("close", {}))
	# The header's ✕ closes the tablet while an order is taken (the column needs the room for
	# the order slip).
	_close.visible = false
	_send.text = _stacked(ui.get("send", {}))
	_send.clip_text = true
	_send.visible = summary.is_empty() and sent.is_empty()
	_send.disabled = not can_send()
	_paint_button(_send, RIGHT, RIGHT.darkened(0.3), Color.WHITE, int(12 * f))
	_paint_button(_close, Color("6b6258"), Color("4e463e"), Color.WHITE, int(12 * f))
	_finish.text = _stacked(ui.get("finish", {}))
	_finish.visible = not summary.is_empty()
	_paint_button(_finish, RIGHT, RIGHT.darkened(0.3), Color.WHITE, int(12 * f))
	# The menu side.
	_tabs.visible = summary.is_empty() and sent.is_empty()
	_pages.visible = summary.is_empty() and sent.is_empty()
	_summary_box.visible = not summary.is_empty()
	_sent_box.visible = summary.is_empty() and not sent.is_empty()
	_book.add_theme_constant_override("separation", 0)
	if not summary.is_empty():
		_fill_summary()
		return
	if not sent.is_empty():
		_fill_sent()
		return
	_fill_tabs()
	_pages.add_theme_constant_override("separation", int(10 * f))
	for page in [_list_page, _detail_page]:
		var page_style := _style(PAGE, RULE, 2, int(10 * f))
		page_style.set_content_margin_all(10 * f)
		page_style.corner_radius_top_left = 0 if page == _list_page else int(10 * f)
		page.add_theme_stylebox_override("panel", page_style)
	_fill_list()
	_fit_rows()
	_fill_detail()

func _fill_tabs() -> void:
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	var f := _factor
	_tabs.add_theme_constant_override("separation", int(4 * f))
	var courses: Array = ui.get("courses", [])
	for i in courses.size():
		var id := str(courses[i].id)
		var button := _button(show_tab.bind(id))
		button.name = "Tab " + id
		button.text = _stacked(courses[i].title)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 54) * f
		button.clip_text = true
		_set_font(button, 18)
		var color: Color = TAB_COLORS[i % TAB_COLORS.size()]
		var active := id == tab
		var current := _wanted().has(id)
		for state in ["normal", "hover", "pressed"]:
			var fill: Color = PAGE.lerp(color, .5) if active else color.darkened(0.12)
			if state == "hover" and not active:
				fill = color
			# The courses asked are framed: teal until a dish is chosen, then green.
			var frame: Color = (RIGHT if picks.has(id) else HEADER) if current else color.darkened(0.35)
			var style := _style(fill, frame, 4 if current else 2, int(10 * f))
			style.corner_radius_bottom_left = 0
			style.corner_radius_bottom_right = 0
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", INK)
		_tabs.add_child(button)

## The open section's dishes, one large button each: picture, name, price.
func _fill_list() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var f := _factor
	_list.add_theme_constant_override("separation", int(6 * f))
	for entry in ui.get("menu", {}).get(tab, []):
		var id := str(entry.id)
		var button := _button(inspect.bind(id))
		button.name = "Dish " + id
		button.custom_minimum_size = Vector2(0, 84) * f
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6 * f
		row.offset_right = -10 * f
		row.add_theme_constant_override("separation", int(10 * f))
		button.add_child(row)
		var picture := FoodIcons.View.new()
		picture.art = entry.art
		picture.custom_minimum_size = Vector2(72, 72) * f
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(picture)
		var words := VBoxContainer.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 0)
		row.add_child(words)
		var parts: Array = GameSettings.shared().view(entry.name, show_native)
		var name_label := _label(INK)
		name_label.text = str(parts[0])
		_set_font(name_label, 20)
		words.add_child(name_label)
		# The row is drawn over the button, which does not grow with it: a taller button for
		# a long name (wraps to two lines) and for the translation line.
		# A first guess (about 13 characters a line); _fit_rows() then grows each button to its
		# wrapped text once the list has its width.
		var name_lines := clampi(ceili(str(parts[0]).length() / 13.0), 1, 3)
		var native_lines := 0 if str(parts[1]) == "" else clampi(ceili(str(parts[1]).length() / 10.0), 1, 3)
		button.custom_minimum_size.y = maxf(84.0, 30.0 * name_lines + 24.0 * native_lines + 24.0) * f
		if str(parts[1]) != "":
			var native := _label(INK.lightened(0.4))
			native.text = str(parts[1])
			_set_font(native, 16)
			words.add_child(native)
		var price := _label(INK.lightened(0.3))
		price.text = str(entry.price)
		# One line at its own width (the shared label helper wraps).
		price.autowrap_mode = TextServer.AUTOWRAP_OFF
		price.size_flags_horizontal = Control.SIZE_SHRINK_END
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.size_flags_vertical = Control.SIZE_FILL
		_set_font(price, 18)
		row.add_child(price)
		for state in ["normal", "hover", "pressed"]:
			var fill := Color.WHITE
			var border := RULE
			var width := 1
			if state == "hover":
				fill = Color("f7f2e8")
			if id == inspected:
				fill = Color("e6f0ec")
				border = HEADER
				width = 3
			button.add_theme_stylebox_override(state, _style(fill, border, width, int(10 * f)))
		_list.add_child(button)

## The dish buttons do not grow with the row drawn over them: a frame after the list is
## filled, each is made as tall as its row's wrapped text needs.
func _fit_rows() -> void:
	await get_tree().process_frame
	for button in _list.get_children():
		if button.is_queued_for_deletion() or button.get_child_count() == 0:
			continue
		var row := button.get_child(0) as Control
		var need := 0.0
		for part in row.get_children():
			need = maxf(need, (part as Control).get_combined_minimum_size().y)
		need += 14.0 * _factor
		if need > button.custom_minimum_size.y:
			button.custom_minimum_size.y = need

## The chosen dish: picture, name, taste rows, thermometer, ingredients, Send order.
func _fill_detail() -> void:
	for box in [_detail, _pick_slot]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	var f := _factor
	_detail.add_theme_constant_override("separation", int(8 * f))
	var entry := _dish(inspected)
	if entry.is_empty():
		var hint := _label(INK.lightened(0.35))
		hint.text = _text(ui.get("hint", {}))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.custom_minimum_size = Vector2(0, 200) * f
		_set_font(hint, 20)
		_detail.add_child(hint)
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", int(10 * f))
	_detail.add_child(top)
	var picture := FoodIcons.View.new()
	picture.art = entry.art
	picture.custom_minimum_size = Vector2(112, 112) * f
	top.add_child(picture)
	var title := _label(INK)
	title.text = _stacked(entry.name)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_FILL
	_set_font(title, 23)
	top.add_child(title)
	_detail.add_child(taste_rows(entry, ui.get("schema", {}), f))
	_detail.add_child(thermometer(entry, ui.get("schema", {}), f))
	_detail.add_child(ingredient_icons(entry, ui.get("schema", {}), f))
	if not _wanted().has(tab):
		return
	var pick := _button(choose)
	pick.name = "Choose"
	pick.text = _stacked(ui.get("choose", {}))
	# Two lines with the translation, and never wider than the page (the list keeps its room).
	pick.clip_text = true
	pick.icon = UiIcons.texture("check", 64)
	pick.add_theme_constant_override("icon_max_width", roundi(28 * f))
	pick.add_theme_constant_override("h_separation", int(10 * f))
	pick.custom_minimum_size = Vector2(0, 62) * f
	_set_font(pick, 22)
	pick.disabled = not can_choose()
	_paint_button(pick, HEADER, HEADER.darkened(0.3), Color.WHITE, int(12 * f))
	_pick_slot.add_child(pick)

## The order slip: one row per course asked (tap: open that course), with the customer's
## request for it ("De entrada, quiero algo salado.", pinyin and translation as in the bubble;
## 11 Nov 2026, so the bubble only says which courses) and the dish chosen for it (picture and
## name) once chosen; the hint until every course has a dish. Text follows _bubble_scale.
func _fill_slip() -> void:
	for child in _slip.get_children():
		_slip.remove_child(child)
		child.queue_free()
	var f := _factor
	var k := _bubble_scale
	_slip.add_theme_constant_override("separation", int(6 * f))
	var requests: Dictionary = ui.get("requests", {})
	for course in _wanted():
		var entry := _dish(str(picks.get(course, "")))
		var open: bool = course == tab
		var row := PanelContainer.new()
		row.name = "Slip " + course
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var row_style := _style(Color.WHITE, HEADER if open else RULE, 3 if open else 1, int(10 * f))
		row_style.content_margin_left = 10 * f
		row_style.content_margin_right = 10 * f
		row_style.content_margin_top = 6 * f
		row_style.content_margin_bottom = 6 * f
		row.add_theme_stylebox_override("panel", row_style)
		# A tap (or a touch, emulated as a click) opens the course.
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				show_tab(course))
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", int(2 * f))
		row.add_child(column)
		var request: Dictionary = requests.get(course, {})
		var shown: Array = GameSettings.shared().view(request, show_native)
		var said := _label(INK)
		said.text = str(shown[0])
		_set_font(said, 18 * k)
		column.add_child(said)
		var reading := PinyinText.style(_label(INK.lightened(0.25)))
		_set_font(reading, 14 * k)
		PinyinText.show(reading, request)
		column.add_child(reading)
		if str(shown[1]) != "":
			var native := _label(INK.lightened(0.35))
			native.text = str(shown[1])
			_set_font(native, 15 * k)
			column.add_child(native)
		var dish_row := HBoxContainer.new()
		dish_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dish_row.alignment = BoxContainer.ALIGNMENT_END
		dish_row.add_theme_constant_override("separation", int(8 * f))
		# Only once a dish is chosen (the open course's row is framed meanwhile).
		dish_row.visible = not entry.is_empty()
		column.add_child(dish_row)
		var picture := FoodIcons.View.new()
		picture.art = entry.get("art", {})
		picture.visible = not entry.is_empty()
		picture.custom_minimum_size = Vector2(34, 34) * f
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dish_row.add_child(picture)
		var dish := Label.new()
		dish.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dish.add_theme_color_override("font_color", RIGHT.darkened(0.2))
		dish.text = "→ " + str(GameSettings.shared().view(entry.name, false)[0]) if not entry.is_empty() else ""
		dish.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_set_font(dish, 18 * k)
		dish_row.add_child(dish)
		_slip.add_child(row)
	if not can_send() and sent.is_empty():
		var hint := _label(INK.lightened(0.35))
		hint.text = _text(ui.get("pick_course", {}))
		_set_font(hint, 16 * k)
		_slip.add_child(hint)

## The five tastes as rows: the taste's icon (faded at zero), then three pill bars. Shared
## with the menu book (restaurant_menu_book.gd).
static func taste_rows(entry: Dictionary, schema: Dictionary, f: float) -> Control:
	var grid := GridContainer.new()
	grid.name = "Tastes"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", int(10 * f))
	grid.add_theme_constant_override("v_separation", int(4 * f))
	for pair in schema.get("tastes", []):
		var id := str(pair[0])
		var level := int(entry.get("taste", {}).get(id, 0))
		var icon := FoodIcons.View.new()
		icon.name = "Taste " + id
		icon.property = id
		icon.faded = level == 0
		icon.background = PAGE
		icon.custom_minimum_size = Vector2(38, 38) * f
		grid.add_child(icon)
		var bar := Painter.new()
		bar.name = "Bars " + id
		bar.custom_minimum_size = Vector2(132, 38) * f
		var color := Color(str(pair[1]))
		bar.paint = func(canvas: Control) -> void:
			var h := minf(18.0 * f, canvas.size.y * .5)
			FoodIcons.bars(canvas, level, color, Rect2(Vector2(0, (canvas.size.y - h) / 2.0), Vector2(canvas.size.x, h)))
		grid.add_child(bar)
	return grid

static func thermometer(entry: Dictionary, schema: Dictionary, f: float) -> Control:
	var temperature := Painter.new()
	temperature.name = "Temperature"
	temperature.custom_minimum_size = Vector2(0, 44) * f
	var level := int(entry.get("temperature", 2))
	var colors: Array = schema.get("temperature_colors", [])
	temperature.paint = func(canvas: Control) -> void:
		var width := minf(canvas.size.x, 340 * f)
		FoodIcons.thermometer(canvas, level, colors, Rect2(Vector2((canvas.size.x - width) / 2.0, 4 * f), Vector2(width, canvas.size.y - 8 * f)))
	return temperature

## The icons of the ingredients the dish has.
static func ingredient_icons(entry: Dictionary, schema: Dictionary, f: float, side := 52.0) -> Control:
	var tags := HFlowContainer.new()
	tags.name = "Tags"
	tags.alignment = FlowContainer.ALIGNMENT_CENTER
	tags.add_theme_constant_override("h_separation", int(8 * f))
	tags.add_theme_constant_override("v_separation", int(8 * f))
	for id in schema.get("tags", []):
		if not entry.get("has", []).has(id):
			continue
		var icon := FoodIcons.View.new()
		icon.name = "Tag " + str(id)
		icon.property = str(id)
		icon.custom_minimum_size = Vector2(side, side) * f
		tags.add_child(icon)
	return tags

func _fill_sent() -> void:
	for child in _sent_box.get_children():
		_sent_box.remove_child(child)
		child.queue_free()
	var f := _factor
	_sent_box.add_theme_constant_override("separation", int(14 * f))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(18 * f))
	_sent_box.add_child(row)
	for course in _wanted():
		var entry := _dish(str(sent.get(course, "")))
		if entry.is_empty():
			continue
		var cell := VBoxContainer.new()
		cell.custom_minimum_size.x = 170 * f
		row.add_child(cell)
		var picture := FoodIcons.View.new()
		picture.art = entry.get("art", {})
		picture.custom_minimum_size = Vector2(130, 130) * f
		picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(picture)
		var dish := _label(INK)
		dish.text = _stacked(entry.get("name", {}))
		dish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_font(dish, 21)
		cell.add_child(dish)
	var done := _label(RIGHT)
	done.text = "✓  " + _text(ui.get("sent", {}))
	done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(done, 32)
	_sent_box.add_child(done)

func _fill_summary() -> void:
	for child in _summary_box.get_children():
		_summary_box.remove_child(child)
		child.queue_free()
	_summary_box.add_theme_constant_override("separation", int(8 * _factor))
	var title := _label(HEADER)
	title.text = _text(summary.title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(title, 28)
	_summary_box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_summary_box.add_child(scroll)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lines)
	for line in summary.lines:
		var item := _label(INK)
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# The practised words always show their translation.
		item.text = GameSettings.shared().inline(line, true, "  —  ")
		_set_font(item, 22)
		lines.add_child(item)

## A Control drawn by a callable (bars and the thermometer, sized by the layout).
class Painter extends Control:
	var paint: Callable

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)
