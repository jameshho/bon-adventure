extends Control
## The Alta Cocina menu book (11 Nov 2026, user request): read at the menu table beside the
## host stand, so the player can look at today's dishes before helping Twinkle. It only draws
## what restaurant_session.gd gives it (the same menu the next customers order from) and
## emits close_requested; text arrives as {"foreign", "native"} lines.
##
## An open book: a burgundy cover with a gold rule round two cream pages and a shaded spine.
## Spread 0 is the cover (restaurant name, "Menú del día", the course list, a hint); spreads
## 1-4 are the courses (Entradas, Platos principales, Postres, Bebidas), their dishes split
## over the two pages. Each dish: picture, name, price, and its properties drawn as on the
## order tablet (taste icons with pill bars, a small thermometer, ingredient icons; no
## property words). Index tabs along the top edge (the bookmarks) jump to a course; ◀ ▶ in
## the page corners turn one spread, with a short page-turn animation. ✕, Esc and the
## translate bubble as on the tablet.
## - Layout scales with min(window height / 800, window width / 1100); tabs, arrows and ✕
##   are at least 54 px × scale (touch, 9 Nov 2026). No scroll bars: a course fits a spread.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const FoodIcons := preload("res://scripts/ui/food_icons.gd")
const Tablet := preload("res://scripts/ui/restaurant_panel.gd")

signal close_requested

const COVER := Color("6e2a22")
const COVER_EDGE := Color("4a1a15")
const GOLD := Color("d9b26a")
const PAGE := Color("fbf5e6")
const SPINE := Color("d8ccb0")
const INK := Color("2b2420")
const SOFT := Color("7a6a58")
const RULE := Color("e3d6b8")
const TAB_COLORS := [Color("e9dcc0"), Color("9fd39a"), Color("f0c96a"), Color("e8a0a0"), Color("8fc3e8")]
const DESIGN := Vector2(1100, 800)
const TURN_SECONDS := 0.36

var show_native := false
## Set by open(): {title, subtitle, hint, translate, close (lines), courses [{id, title
## (line)}], menu {course: [dish]}, schema} (dishes and schema as for the tablet).
var ui: Dictionary = {}
## The open spread: 0 the cover, 1.. the courses in order.
var spread := 0

var _factor := 1.0
var _frame: Control
var _cover: Panel
var _tabs: HBoxContainer
var _left: PanelContainer
var _right: PanelContainer
var _left_box: VBoxContainer
var _right_box: VBoxContainer
var _spine: ColorRect
var _prev: Button
var _next: Button
var _x: Button
var _translate: Button
var _turn: ColorRect
var _turning: Tween

func _init() -> void:
	name = "Restaurant menu book"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.02, 0.5)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	add_child(shade)
	_frame = Control.new()
	_frame.name = "Book"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_tabs = HBoxContainer.new()
	_tabs.name = "Bookmarks"
	_frame.add_child(_tabs)
	_cover = Panel.new()
	_cover.name = "Cover"
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.add_child(_cover)
	_left = PanelContainer.new()
	_left.name = "Left page"
	_left.clip_contents = true
	_frame.add_child(_left)
	_left_box = VBoxContainer.new()
	_left.add_child(_left_box)
	_right = PanelContainer.new()
	_right.name = "Right page"
	_right.clip_contents = true
	_frame.add_child(_right)
	_right_box = VBoxContainer.new()
	_right.add_child(_right_box)
	_spine = ColorRect.new()
	_spine.name = "Spine"
	_spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_spine)
	_turn = ColorRect.new()
	_turn.name = "Turning page"
	_turn.color = PAGE.darkened(0.04)
	_turn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn.visible = false
	_frame.add_child(_turn)
	_prev = _button(func() -> void: turn_to(spread - 1))
	_prev.name = "Previous page"
	_prev.text = "◀"
	_frame.add_child(_prev)
	_next = _button(func() -> void: turn_to(spread + 1))
	_next.name = "Next page"
	_next.text = "▶"
	_frame.add_child(_next)
	_x = _button(func() -> void: close_requested.emit())
	_x.name = "Close book"
	_x.icon = UiIcons.texture("close", 64)
	_x.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frame.add_child(_x)
	_translate = TranslateButton.new()
	_translate.pressed.connect(toggle_translation)
	_frame.add_child(_translate)
	resized.connect(_on_resized)
	visibility_changed.connect(_on_resized)

func _style(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
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

# --- Public API ------------------------------------------------------------------------

func open(lines: Dictionary) -> void:
	ui = lines
	spread = 0
	visible = true
	_refresh()

func hide_book() -> void:
	visible = false

func spreads() -> int:
	return 1 + ui.get("courses", []).size()

## Turns to spread `index` (clamped) with the page-turn animation.
func turn_to(index: int) -> void:
	index = clampi(index, 0, spreads() - 1)
	if index == spread:
		return
	var forward := index > spread
	spread = index
	_animate_turn(forward)
	_refresh()

func toggle_translation() -> void:
	show_native = not show_native
	_refresh()

func refresh_display() -> void:
	if visible:
		_refresh()

## Esc goes to Main's popup stack, L to Main's peek; every other key and non-left button is swallowed.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Hold L: the HUD's peek (EN) works over the book too (Main._unhandled_input; 23 Nov 2026).
	if event.is_action("peek"):
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		match (event as InputEventKey).keycode:
			KEY_ESCAPE:
				return
			KEY_LEFT, KEY_A:
				turn_to(spread - 1)
			KEY_RIGHT, KEY_D:
				turn_to(spread + 1)
	if event is InputEventKey or (event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()

# --- Drawing -----------------------------------------------------------------------------

func _on_resized() -> void:
	if visible:
		_refresh()

func _text(line: Variant) -> String:
	return GameSettings.shared().inline(line, show_native)

func _stacked(line: Variant) -> String:
	return GameSettings.shared().stacked(line, show_native)

func _set_font(node: Control, font: float) -> void:
	node.add_theme_font_size_override("font_size", roundi(font * _factor))

## The book's rectangles for this window: the whole cover and the two pages inside it.
func _layout() -> Dictionary:
	var screen := get_viewport_rect().size
	var f := _factor
	var tab_h := 58.0 * f
	# Below the HUD's day clock (top centre, about 72 px × scale) and above the bottom edge.
	var top := 76.0 * f
	var room := Vector2(screen.x * 0.92, screen.y - top - tab_h - 18.0 * f)
	var size := Vector2(minf(room.x, room.y * 1.5), 0)
	size.y = minf(room.y, size.x / 1.42)
	var origin := Vector2((screen.x - size.x) / 2.0, top + tab_h + (room.y - size.y) / 2.0)
	var cover := Rect2(origin, size)
	var inset := 16.0 * f
	var gutter := 6.0 * f
	var page_w := (size.x - inset * 2 - gutter * 2) / 2.0
	var left := Rect2(origin + Vector2(inset, inset), Vector2(page_w, size.y - inset * 2))
	var right := Rect2(Vector2(left.end.x + gutter * 2, left.position.y), left.size)
	return {"cover": cover, "left": left, "right": right, "tab_h": tab_h}

func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size

func _refresh() -> void:
	if ui.is_empty() or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.5, 3.0)
	var f := _factor
	var rects := _layout()
	var cover: Rect2 = rects.cover
	_place(_cover, cover)
	var cover_style := _style(COVER, COVER_EDGE, int(3 * f), int(16 * f))
	cover_style.shadow_color = Color(0, 0, 0, 0.45)
	cover_style.shadow_size = int(16 * f)
	_cover.add_theme_stylebox_override("panel", cover_style)
	for pair in [[_left, rects.left, true], [_right, rects.right, false]]:
		var page: PanelContainer = pair[0]
		_place(page, pair[1])
		var page_style := _style(PAGE, RULE, int(1 * f), int(6 * f))
		page_style.set_content_margin_all(18 * f)
		page_style.content_margin_bottom = 64 * f
		if pair[2]:
			page_style.corner_radius_top_right = 0
			page_style.corner_radius_bottom_right = 0
		else:
			page_style.corner_radius_top_left = 0
			page_style.corner_radius_bottom_left = 0
		page.add_theme_stylebox_override("panel", page_style)
	var left: Rect2 = rects.left
	var right: Rect2 = rects.right
	_spine.position = Vector2(left.end.x - 10 * f, left.position.y)
	_spine.size = Vector2(right.position.x - left.end.x + 20 * f, left.size.y)
	_spine.color = Color(SPINE, 0.55)
	# Bookmarks: index tabs standing on the cover's top edge, the open one joined to it.
	var tab_h: float = rects.tab_h
	var button := Vector2(56, 56) * f
	_translate.refresh(show_native, f)
	var corner := button.x + (_translate.size.x + 12 * f if _translate.visible else 0.0) + 22 * f
	_tabs.position = Vector2(cover.position.x + 24 * f, cover.position.y - tab_h + 4 * f)
	_tabs.size = Vector2(cover.size.x - 24 * f - corner, tab_h)
	_fill_tabs(tab_h)
	# Translate and ✕ at the right end of the bookmark row; arrows in the page corners.
	_x.custom_minimum_size = button
	_x.size = button
	_x.position = Vector2(cover.end.x - button.x - 6 * f, cover.position.y - tab_h + (tab_h - button.y) / 2.0)
	_x.add_theme_constant_override("icon_max_width", roundi(26 * f))
	for state in ["normal", "hover", "pressed"]:
		_x.add_theme_stylebox_override(state, _style(COVER.lightened(0.12 if state == "hover" else 0.0), GOLD, int(2 * f), int(28 * f)))
	_translate.tooltip_text = str(ui.get("translate", {}).get("native", ""))
	_translate.position = Vector2(_x.position.x - _translate.size.x - 12 * f, cover.position.y - tab_h + (tab_h - _translate.size.y) / 2.0)
	for pair in [[_prev, Vector2(left.position.x + 10 * f, left.end.y - button.y - 8 * f), spread > 0], [_next, Vector2(right.end.x - button.x - 10 * f, right.end.y - button.y - 8 * f), spread < spreads() - 1]]:
		var arrow: Button = pair[0]
		arrow.custom_minimum_size = button
		arrow.size = button
		arrow.position = pair[1]
		arrow.visible = pair[2]
		_set_font(arrow, 24)
		for state in ["normal", "hover", "pressed"]:
			arrow.add_theme_stylebox_override(state, _style(Color("efe4cb") if state != "hover" else Color("f6edda"), Color("c9b48a"), int(2 * f), int(28 * f)))
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			arrow.add_theme_color_override(key, COVER)
	_fill_pages()
	_fit_pages.call_deferred()

## Wrapping labels first measure at zero width (very tall), which can push a page past the
## cover; once laid out, the pages are put back to their size (clip_contents keeps the rest).
func _fit_pages() -> void:
	if not visible or ui.is_empty():
		return
	var rects := _layout()
	_place(_left, rects.left)
	_place(_right, rects.right)

func _fill_tabs(tab_h: float) -> void:
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	var f := _factor
	_tabs.add_theme_constant_override("separation", int(5 * f))
	var titles: Array = [ui.get("title_short", ui.get("subtitle", {}))]
	for course in ui.get("courses", []):
		titles.append(course.title)
	for i in titles.size():
		var tab := _button(turn_to.bind(i))
		tab.name = "Bookmark %d" % i
		tab.text = _stacked(titles[i])
		# The tab grows with its title ("Platos principales" was clipped at 1400 px).
		tab.clip_text = false
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.size_flags_vertical = Control.SIZE_SHRINK_END
		var open := i == spread
		tab.custom_minimum_size = Vector2(0, tab_h if open else tab_h - 8 * f)
		_set_font(tab, 18)
		var color: Color = TAB_COLORS[i % TAB_COLORS.size()]
		for state in ["normal", "hover", "pressed"]:
			var fill: Color = color if open else color.darkened(0.12)
			if state == "hover" and not open:
				fill = color
			var style := _style(fill, color.darkened(0.35) if not open else GOLD, int((3 if open else 2) * f), int(12 * f))
			style.corner_radius_bottom_left = 0
			style.corner_radius_bottom_right = 0
			style.content_margin_bottom = 8 * f
			tab.add_theme_stylebox_override(state, style)
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			tab.add_theme_color_override(key, INK)
		_tabs.add_child(tab)

func _clear(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _fill_pages() -> void:
	_clear(_left_box)
	_clear(_right_box)
	var f := _factor
	for box in [_left_box, _right_box]:
		box.add_theme_constant_override("separation", int(8 * f))
	if spread == 0:
		_fill_cover_pages()
		return
	var course: Dictionary = ui.courses[spread - 1]
	var dishes: Array = ui.get("menu", {}).get(str(course.id), [])
	var split := ceili(dishes.size() / 2.0)
	_heading(_left_box, course.title)
	var more := _label(SOFT)
	more.text = " "
	_set_font(more, 26)
	_right_box.add_child(more)
	for i in dishes.size():
		_dish_entry(_left_box if i < split else _right_box, dishes[i])
	_footer(_left_box, spread * 2)
	_footer(_right_box, spread * 2 + 1)

func _heading(box: VBoxContainer, line: Dictionary) -> void:
	var title := _label(COVER)
	title.text = _stacked(line)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(title, 26)
	box.add_child(title)
	var rule := ColorRect.new()
	rule.color = GOLD
	rule.custom_minimum_size = Vector2(0, 2 * _factor)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)

func _footer(box: VBoxContainer, number: int) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	var page := _label(SOFT)
	page.text = "— %d —" % number
	page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(page, 15)
	box.add_child(page)

## Cover spread: the restaurant's name and "Menú del día" on the left, the courses (each a
## link to its spread) and the hint on the right.
func _fill_cover_pages() -> void:
	var f := _factor
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, 40 * f)
	_left_box.add_child(top)
	var name_label := _label(COVER)
	name_label.text = _stacked(ui.get("title", {}))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(name_label, 36)
	_left_box.add_child(name_label)
	var ornament := _label(GOLD.darkened(0.15))
	ornament.text = "❦"
	ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(ornament, 40)
	_left_box.add_child(ornament)
	var subtitle := _label(INK)
	subtitle.text = _stacked(ui.get("subtitle", {}))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(subtitle, 28)
	_left_box.add_child(subtitle)
	var picture := FoodIcons.View.new()
	var first: Array = ui.get("menu", {}).get(str(ui.courses[1].id) if ui.courses.size() > 1 else "", [])
	picture.art = first[0].art if not first.is_empty() else {}
	picture.custom_minimum_size = Vector2(150, 150) * f
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_left_box.add_child(picture)
	_footer(_left_box, 0)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30 * f)
	_right_box.add_child(gap)
	for i in ui.courses.size():
		var link := _button(turn_to.bind(i + 1))
		link.name = "Contents %d" % (i + 1)
		link.text = "%s   ·   %d" % [_text(ui.courses[i].title), (i + 1) * 2]
		link.alignment = HORIZONTAL_ALIGNMENT_LEFT
		link.custom_minimum_size = Vector2(0, 58 * f)
		_set_font(link, 22)
		var color: Color = TAB_COLORS[(i + 1) % TAB_COLORS.size()]
		for state in ["normal", "hover", "pressed"]:
			var style := _style(Color.TRANSPARENT if state == "normal" else Color(color, 0.45), Color.TRANSPARENT, 0, int(10 * f))
			style.border_color = color.darkened(0.2)
			style.border_width_left = int(8 * f)
			style.content_margin_left = 18 * f
			link.add_theme_stylebox_override(state, style)
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			link.add_theme_color_override(key, INK)
		_right_box.add_child(link)
	var hint := _label(SOFT)
	hint.text = _text(ui.get("hint", {}))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(hint, 17)
	_right_box.add_child(hint)
	_footer(_right_box, 1)

## One dish on a page: picture | name and price over its properties.
func _dish_entry(box: VBoxContainer, entry: Dictionary) -> void:
	var f := _factor
	var row := HBoxContainer.new()
	row.name = "Dish " + str(entry.id)
	row.add_theme_constant_override("separation", int(10 * f))
	box.add_child(row)
	var picture := FoodIcons.View.new()
	picture.art = entry.art
	picture.custom_minimum_size = Vector2(78, 78) * f
	picture.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(picture)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", int(2 * f))
	row.add_child(words)
	var line := HBoxContainer.new()
	words.add_child(line)
	var parts: Array = GameSettings.shared().view(entry.name, show_native)
	var name_label := _label(INK)
	name_label.text = str(parts[0]) + ("" if str(parts[1]) == "" else "  ·  " + str(parts[1]))
	_set_font(name_label, 19)
	line.add_child(name_label)
	var price := _label(COVER)
	price.text = str(entry.price)
	price.autowrap_mode = TextServer.AUTOWRAP_OFF
	price.size_flags_horizontal = Control.SIZE_SHRINK_END
	_set_font(price, 18)
	line.add_child(price)
	var facts := HFlowContainer.new()
	facts.add_theme_constant_override("h_separation", int(10 * f))
	facts.add_theme_constant_override("v_separation", int(2 * f))
	words.add_child(facts)
	var schema: Dictionary = ui.get("schema", {})
	for pair in schema.get("tastes", []):
		var level := int(entry.get("taste", {}).get(str(pair[0]), 0))
		if level == 0:
			continue
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", int(3 * f))
		var icon := FoodIcons.View.new()
		icon.property = str(pair[0])
		icon.custom_minimum_size = Vector2(28, 28) * f
		cell.add_child(icon)
		var bars := Tablet.Painter.new()
		bars.custom_minimum_size = Vector2(50, 28) * f
		var color := Color(str(pair[1]))
		bars.paint = func(canvas: Control) -> void:
			var h := 11.0 * f
			FoodIcons.bars(canvas, level, color, Rect2(Vector2(0, (canvas.size.y - h) / 2.0), Vector2(canvas.size.x, h)))
		cell.add_child(bars)
		facts.add_child(cell)
	var temperature := Tablet.thermometer(entry, schema, f * 0.62)
	temperature.custom_minimum_size = Vector2(150, 28) * f
	facts.add_child(temperature)
	for id in schema.get("tags", []):
		if entry.get("has", []).has(id):
			var tag := FoodIcons.View.new()
			tag.property = str(id)
			tag.custom_minimum_size = Vector2(30, 30) * f
			facts.add_child(tag)
	var rule := ColorRect.new()
	rule.color = RULE
	rule.custom_minimum_size = Vector2(0, 1 * f)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)

## A blank page sweeping over the spine: forward, from the right page to the left;
## backward, the other way. Purely decorative (the new spread is already drawn).
func _animate_turn(forward: bool) -> void:
	if _turning != null:
		_turning.kill()
	var rects := _layout()
	var from: Rect2 = rects.right if forward else rects.left
	var to: Rect2 = rects.left if forward else rects.right
	_turn.visible = true
	_place(_turn, from)
	_turn.pivot_offset = Vector2(0, 0) if forward else Vector2(from.size.x, 0)
	_turn.scale = Vector2.ONE
	_turning = create_tween()
	_turning.tween_property(_turn, "scale:x", 0.0, TURN_SECONDS * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_turning.tween_callback(func() -> void:
		_place(_turn, to)
		_turn.pivot_offset = Vector2(to.size.x, 0) if forward else Vector2(0, 0)
		_turn.scale = Vector2(0, 1))
	_turning.tween_property(_turn, "scale:x", 1.0, TURN_SECONDS * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_turning.tween_callback(func() -> void: _turn.visible = false)
