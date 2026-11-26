extends Control
## Full-screen airport flight information UI (Captain Bruno's game and browsing the board at
## the information desk). It only draws what flight_session.gd gives it and emits signals;
## it knows nothing about flights, dates or words. Text arrives as {"foreign", "native"} lines.
##
## Top: title, progress (quiz only), translate bubble, ✕. Then the instruction (quiz) or a
## hint (browsing), and the flight board (a dark departures screen; board only since the
## redesign of 7 Nov 2026, which removed the schedule booklet) with, on its right, a digital
## clock (today's weekday over the 12-hour time) over a Sunday-first month calendar with today
## circled and no day names (shown in the native language only with translations; 8 Nov 2026) (8 Nov 2026; they replaced the "today / now" line). Two tabs over
## the board, Salidas and Llegadas (user decision, 8 Nov 2026: departures and arrivals in
## separate tables, like an airport); the board shows the chosen tab's flights. The tab is
## the player's choice and stays between questions (choosing it is part of understanding
## salir / llegar); the session sets it at the start of a game. Columns: flight code,
## destination (Salidas) or origin (Llegadas) as a flag and airport code (never the country's
## name), one day column (the
## weekday word, or a month/day date for weekday questions; the session decides) and the
## 12-hour time; no status column. Every row is one large button; in the quiz a tap answers.
## Bottom: feedback, "What went wrong?", "Another flight", Exit. After the last flight the
## content shows the questions missed on the first tap (with what they meant on the board),
## then the other words practised, and a Finish button.
##
## - While visible it swallows every key and non-left mouse event (as family_panel.gd), and
##   Main disables the player's controls (Main.sync_player_controls).
## - Layout scales with min(window height / 800, window width / 1100) (UI decision,
##   4 Nov 2026: large tap targets, text that scales with a laptop window).
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")
const Flags := preload("res://scripts/ui/flags.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal flight_pressed(id: String)
signal why_pressed
signal next_pressed
signal finish_pressed
signal close_requested
signal tab_changed(id: String)

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
const RIGHT := Color("3fae5a")
const WRONG := Color("d0505a")
## Departures screen colours (the 3D board in the terminal is navy with yellow times).
const BOARD := Color("10224a")
const BOARD_EDGE := Color("2f62b0")
const BOARD_TEXT := Color("e8eef8")
const BOARD_TIME := Color("f2c231")
## Column widths (stretch ratios): flight, destination, day (weekday or date), time.
const COLUMNS := [1.0, 1.1, 1.2, 1.1]
## The board's tab ("dep" or "arr"): the player's choice, kept between questions.
var tab := "dep"
## Width of the board : the clock and calendar column.
const BOARD_SHARE := 2.5
const CALENDAR_FONT := 17.0
const DESIGN := Vector2(1100, 800)
const ROW_FONT := 19.0
const HEADER_FONT := 17.0
## The smallest row font: rows shrink to this before anything else gives way. The board never
## scrolls (user decision, 8 Nov 2026: 6 rows per tab always fit).
const MIN_FONT := 12.0
## The native line under the foreign one, relative to the row font.
const NATIVE_SCALE := .8

## Controls on top of the screen the card must leave visible and clickable (25 Nov 2026, user:
## the card covered the HUD's top-right EN, the one language toggle; as money_panel.gd): the
## card starts below them, and clicks on them pass through the panel.
var clear_of: Array = []
var show_native := false
## Set by open(): {quiz, title, translate, question, hint, clock {weekday (line), time}, tabs [{id ("dep" /
## "arr"), label (line), column (line: the destination / origin header)}],
## calendar {title (line), heads [7 lines, Sunday first], cells [{day, month, today}]},
## columns [4 lines], board [rows], empty, why, next, exit, finish}. A row: {id, code,
## airport, flag (country word key), dir ("dep" / "arr"), day (a weekday line or date digits), time}.
var ui: Dictionary = {}
## Row marks: flight id -> true (right) / false (wrong).
var marks: Dictionary = {}
var feedback: Dictionary = {}
var explanation: Dictionary = {}
var solved := false
var can_explain := false
## Shown instead of the tables at the end: {"title": line, "lines": [lines], "review_title":
## line, "review": [lines] (missed questions, first)}.
var summary: Dictionary = {}

var _factor := 1.0
var _shade: ColorRect
var _card: PanelContainer
var _stack: VBoxContainer
var _title: Label
var progress
var _translate: Button
var _x: Button
var _question: Label
var _reading: Label
var _native: Label
var _content: Control
var _main: HBoxContainer
var _board_column: VBoxContainer
var _tabs: HBoxContainer
var _board_panel: PanelContainer
var _side: VBoxContainer
var _clock_panel: PanelContainer
var _clock_day: Label
var _clock_day_native: Label
var _clock_time: Label
var _calendar_panel: PanelContainer
var _calendar_box: VBoxContainer
var _board_rows: VBoxContainer
var _summary_box: VBoxContainer
var _feedback: Label
var _explain_label: Label
var _why: Button
var _next: Button
var _finish: Button
var _exit: Button
## flight id -> [row buttons].
var rows: Dictionary = {}

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Flight panel"
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

func _style(color: Color, border: Color = EDGE, width: int = 4, radius: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
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
	var head := HBoxContainer.new()
	_stack.add_child(head)
	_title = _label(DIM)
	head.add_child(_title)
	progress = ProgressBarRow.new()
	head.add_child(progress)
	_translate = TranslateButton.new()
	_translate.pressed.connect(toggle_translation)
	head.add_child(_translate)
	_x = _button(func() -> void: close_requested.emit())
	_x.icon = UiIcons.texture("close", 64)
	_x.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_x)
	_question = _label(GOLD)
	_stack.add_child(_question)
	_reading = PinyinText.style(_label(GOLD.darkened(0.15)))
	_stack.add_child(_reading)
	_native = _label(DIM)
	_stack.add_child(_native)
	_content = Control.new()
	_content.name = "Content"
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.clip_contents = true
	_content.resized.connect(_layout_content)
	_stack.add_child(_content)
	_build_board()
	_summary_box = VBoxContainer.new()
	_summary_box.name = "Summary"
	_summary_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_summary_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_summary_box)
	_feedback = _label(GOLD)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stack.add_child(_feedback)
	_explain_label = _label(GOLD)
	_explain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stack.add_child(_explain_label)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_END
	_stack.add_child(bar)
	_why = _button(func() -> void: why_pressed.emit())
	_next = _button(func() -> void: next_pressed.emit())
	_finish = _button(func() -> void: finish_pressed.emit())
	_exit = _button(func() -> void: close_requested.emit())
	for pair in [[_why, "question"], [_next, "next"], [_finish, "check"], [_exit, "exit"]]:
		pair[0].icon = UiIcons.texture(pair[1], 64)
		pair[0].add_theme_constant_override("h_separation", 10)
		bar.add_child(pair[0])

func _build_board() -> void:
	_main = HBoxContainer.new()
	_main.name = "Board and calendar"
	_main.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(_main)
	_board_column = VBoxContainer.new()
	_board_column.name = "Board column"
	_board_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_column.size_flags_stretch_ratio = BOARD_SHARE
	_main.add_child(_board_column)
	_tabs = HBoxContainer.new()
	_tabs.name = "Tabs"
	_board_column.add_child(_tabs)
	_board_panel = PanelContainer.new()
	_board_panel.name = "Board"
	_board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_column.add_child(_board_panel)
	_side = VBoxContainer.new()
	_side.name = "Clock and calendar"
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main.add_child(_side)
	# The digital clock: today's weekday (the calendar has no day names) over the 12-hour time.
	_clock_panel = PanelContainer.new()
	_clock_panel.name = "Clock"
	_clock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side.add_child(_clock_panel)
	var clock_box := VBoxContainer.new()
	clock_box.alignment = BoxContainer.ALIGNMENT_CENTER
	clock_box.add_theme_constant_override("separation", 0)
	_clock_panel.add_child(clock_box)
	_clock_day = _label(BOARD_TEXT)
	_clock_day.name = "Clock day"
	_clock_day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_box.add_child(_clock_day)
	_clock_day_native = _label(DIM)
	_clock_day_native.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_box.add_child(_clock_day_native)
	_clock_time = _label(BOARD_TIME)
	_clock_time.name = "Clock time"
	_clock_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_box.add_child(_clock_time)
	_calendar_panel = PanelContainer.new()
	_calendar_panel.name = "Calendar"
	_calendar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_calendar_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(_calendar_panel)
	_calendar_box = VBoxContainer.new()
	_calendar_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_calendar_panel.add_child(_calendar_box)
	# Never a scroll bar (8 Nov 2026): the rows shrink to fit (_fit_rows); the container only clips.
	var scroll := ScrollContainer.new()
	scroll.name = "Board scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_board_panel.add_child(scroll)
	_board_rows = VBoxContainer.new()
	_board_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_board_rows)

# --- Public API ------------------------------------------------------------------------

## Shows the panel with new content (a new question or browsing); clears the marks.
func open(lines: Dictionary) -> void:
	ui = lines
	marks.clear()
	feedback = {}
	explanation = {}
	solved = false
	can_explain = false
	summary = {}
	visible = true
	_refresh()

func hide_panel() -> void:
	visible = false

## Marks a tapped flight right or wrong and shows `line`; a wrong tap offers "What went wrong?".
func mark(id: String, right: bool, line: Dictionary) -> void:
	marks[id] = right
	feedback = line
	explanation = {}
	solved = solved or right
	can_explain = not right
	_refresh()

func show_explanation(line: Dictionary) -> void:
	explanation = line
	can_explain = false
	_refresh()

## The end of a session: the practised words instead of the tables, and Finish.
func show_summary(title: Dictionary, lines: Array, line: Dictionary, review_title: Dictionary = {}, review: Array = []) -> void:
	summary = {"title": title, "lines": lines, "review_title": review_title, "review": review}
	feedback = line
	explanation = {}
	can_explain = false
	_refresh()

func toggle_translation() -> void:
	show_native = not show_native
	_refresh()

func set_progress(done: int, target: int) -> void:
	progress.set_progress(done, target)

func refresh_display() -> void:
	if visible:
		_refresh()

## Only left clicks reach the buttons; every key, wheel and other mouse button is swallowed
## while the panel is open. Esc goes to Main's popup stack.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
		return
	# Hold L (the "peek" action): the native language, as the HUD's EN (Main handles it).
	if event.is_action("peek"):
		return
	if event is InputEventKey or (event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()

## Clicks on a clear_of control go through the panel to it.
func _has_point(point: Vector2) -> bool:
	var at := get_global_transform() * point
	for rect in _clear_rects():
		if rect.has_point(at):
			return false
	return Rect2(Vector2.ZERO, size).has_point(point)

## The screen rects of the clear_of controls showing now.
func _clear_rects() -> Array:
	var rects: Array = []
	for control in clear_of:
		if is_instance_valid(control) and control.is_visible_in_tree():
			rects.append(control.get_global_rect())
	return rects

# --- Drawing -----------------------------------------------------------------------------

func _on_resized() -> void:
	if visible:
		_refresh()

func _text(line: Variant) -> String:
	return GameSettings.shared().inline(line, show_native)

func _stacked(line: Variant) -> String:
	return GameSettings.shared().stacked(line, show_native)

func _set_font(node: Control, size: float) -> void:
	node.add_theme_font_size_override("font_size", roundi(size * _factor))

func _refresh() -> void:
	if ui.is_empty() or not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.5, 3.0)
	var f := _factor
	# Below the controls it keeps clear of (clear_of), where they stand over the card's width.
	var top := 0.03 * screen.y
	for rect in _clear_rects():
		if rect.end.x > _card.anchor_left * screen.x and rect.position.x < _card.anchor_right * screen.x:
			top = maxf(top, rect.end.y + 8.0 * f)
	_card.anchor_top = minf(top / screen.y, 0.5)
	_card.add_theme_stylebox_override("panel", _style(FILL))
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(14 * f)
	_stack.add_theme_constant_override("separation", int(6 * f))
	_set_font(_title, 22)
	_set_font(_question, 32)
	_set_font(_native, 23)
	_set_font(_reading, 21)
	_set_font(_clock_day, 26)
	_set_font(_clock_day_native, 18)
	_set_font(_clock_time, 40)
	_set_font(_feedback, 26)
	_set_font(_explain_label, 24)
	for button in [_x, _why, _next, _finish, _exit]:
		_set_font(button, 23)
		button.add_theme_constant_override("icon_max_width", roundi(28 * f))
	_x.custom_minimum_size = Vector2(60, 52) * f
	_translate.refresh(show_native, f)
	_translate.tooltip_text = str(ui.get("translate", {}).get("native", ""))
	progress.apply_scale(f)
	progress.visible = bool(ui.get("quiz", false)) and progress.target > 0
	for button in [_why, _next, _finish, _exit]:
		button.custom_minimum_size = Vector2(150, 60) * f
	_title.text = GameSettings.shared().view(ui.title, false)[0]
	var prompt: Dictionary = ui.get("question", {}) if bool(ui.get("quiz", false)) else ui.get("hint", {})
	# At the end Bruno's thanks takes the instruction's place.
	if not summary.is_empty():
		prompt = feedback
	var shown: Array = GameSettings.shared().view(prompt, show_native)
	_question.text = shown[0]
	PinyinText.show(_reading, prompt)
	_native.text = shown[1]
	_native.visible = shown[1] != ""
	var clock: Dictionary = ui.get("clock", {})
	var weekday: Array = GameSettings.shared().view(clock.get("weekday", {}), show_native)
	_clock_day.text = str(weekday[0])
	_clock_day_native.text = str(weekday[1])
	_clock_day_native.visible = str(weekday[1]) != ""
	_clock_time.text = str(clock.get("time", ""))
	_feedback.text = _text(feedback)
	_feedback.visible = not feedback.is_empty() and summary.is_empty()
	_feedback.add_theme_color_override("font_color", RIGHT.lightened(0.35) if (solved or not summary.is_empty()) else (WRONG.lightened(0.35) if not feedback.is_empty() else GOLD))
	_explain_label.text = _text(explanation)
	_explain_label.visible = not explanation.is_empty()
	var quiz := bool(ui.get("quiz", false))
	_why.visible = quiz and can_explain and summary.is_empty()
	_why.text = _stacked(ui.get("why", {}))
	_next.visible = quiz and solved and summary.is_empty()
	_next.text = _stacked(ui.get("next", {}))
	_finish.visible = not summary.is_empty()
	_finish.text = _stacked(ui.get("finish", {}))
	_exit.visible = summary.is_empty()
	_exit.text = _stacked(ui.get("exit", {}))
	_rebuild_tabs()
	_rebuild_rows()
	_rebuild_calendar()
	_layout_content()

## Shows tab `id` ("dep" / "arr") and redraws the board.
func select_tab(id: String) -> void:
	if tab == id:
		return
	tab = id
	tab_changed.emit(id)
	_refresh()

## The Salidas / Llegadas tabs: large buttons with a take-off / landing icon; the chosen one
## is filled like the board, the other is dim. Two lines with translations shown.
func _rebuild_tabs() -> void:
	var f := _factor
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	_tabs.add_theme_constant_override("separation", int(8 * f))
	for entry in ui.get("tabs", []):
		var id := str(entry.id)
		var chosen := id == tab
		var button := _button(func() -> void: select_tab(id))
		button.name = "Tab " + id
		# One line (8 Nov 2026), "Salidas / Departures", so the board keeps its height.
		button.text = _text(entry.label)
		button.icon = UiIcons.texture("landing" if id == "arr" else "takeoff", 64)
		button.add_theme_constant_override("icon_max_width", roundi(26 * f))
		button.add_theme_constant_override("h_separation", int(10 * f))
		button.custom_minimum_size = Vector2(190, 52) * f
		_set_font(button, 22)
		var color := BOARD_TIME if chosen else DIM
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			button.add_theme_color_override(state, color)
		for state in ["normal", "hover", "pressed", "focus"]:
			var fill := BOARD if chosen else (BonStyle.SKY_TOP if state != "hover" else BonStyle.RIM)
			var style := _style(fill, BOARD_EDGE if chosen else EDGE, 3 if chosen else 4, 12)
			style.set_content_margin_all(8 * f)
			button.add_theme_stylebox_override(state, style)
		_tabs.add_child(button)

## The header of the chosen tab: the destination column says Destino or Origen.
func _columns() -> Array:
	var columns: Array = ui.get("columns", []).duplicate()
	for entry in ui.get("tabs", []):
		if str(entry.id) == tab and columns.size() > 1:
			columns[1] = entry.column
	return columns

## Fills the board table with the chosen tab's flights (rebuilt on every refresh).
func _rebuild_rows() -> void:
	rows.clear()
	for child in _board_rows.get_children():
		_board_rows.remove_child(child)
		child.queue_free()
	var f := _factor
	_board_panel.add_theme_stylebox_override("panel", _style(BOARD, BOARD_EDGE, 3, 10))
	(_board_panel.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(10 * f)
	_board_rows.add_theme_constant_override("separation", int(2 * f))
	_add_header(_board_rows, BOARD_TIME)
	var shown: Array = ui.get("board", []).filter(func(row): return str(row.get("dir", "dep")) == tab)
	for row in shown:
		_add_row(_board_rows, row)
	if shown.is_empty():
		_add_empty(_board_rows, BOARD_TEXT)

## Row heights for a font size (design pixels): one line, or the foreign line over a
## smaller native line when translations show.
func _row_height(font: float) -> float:
	return font * 1.4 + 8.0 if not _two_lines() else font * (1.2 + NATIVE_SCALE * 1.2) + 8.0

## One table line, a cell per column. A cell is a String (code, date, time) or a Lexicon
## line. With translations shown every cell has two labels: the foreign text on top and the
## native text under it, smaller and lighter, so all first lines share one baseline (6 Nov
## 2026: rows were cramped and out of step in Chinese). `flag` goes before column 1.
func _cells(cells: Array, colors: Array, size: float, flag: Texture2D = null) -> HBoxContainer:
	var f := _factor
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", int(6 * f))
	var two := _two_lines()
	for i in cells.size():
		var parts: Array = GameSettings.shared().view(cells[i], show_native) if cells[i] is Dictionary else [str(cells[i]), ""]
		var text_box := VBoxContainer.new()
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.alignment = BoxContainer.ALIGNMENT_CENTER
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.add_theme_constant_override("separation", 0)
		text_box.add_child(_cell_label("Main", str(parts[0]), colors[i], size))
		if two:
			# A space keeps the line's height in cells without a translation.
			var native := str(parts[1]) if str(parts[1]) != "" else " "
			text_box.add_child(_cell_label("Native", native, colors[i].lerp(Color(colors[i], .0), .3), size * NATIVE_SCALE))
		var cell: Control = text_box
		if i == 1 and flag != null:
			var holder := HBoxContainer.new()
			holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_theme_constant_override("separation", int(8 * f))
			var icon := TextureRect.new()
			icon.name = "Flag"
			icon.texture = flag
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.custom_minimum_size = Vector2(30, 20) * f * size / 19.0
			holder.add_child(icon)
			holder.add_child(text_box)
			cell = holder
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_stretch_ratio = COLUMNS[i]
		line.add_child(cell)
	return line

func _cell_label(title: String, text: String, color: Color, size: float) -> Label:
	var label := Label.new()
	label.name = title
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", roundi(size * _factor))
	return label

func _add_header(box: VBoxContainer, color: Color) -> void:
	var header := _cells(_columns(), [color, color, color, color], HEADER_FONT)
	header.name = "Header"
	header.custom_minimum_size = Vector2(0, _row_height(HEADER_FONT) * _factor)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", int(12 * _factor))
	pad.add_theme_constant_override("margin_right", int(12 * _factor))
	pad.add_child(header)
	box.add_child(pad)

func _add_empty(box: VBoxContainer, color: Color) -> void:
	var label := _label(color)
	label.text = _text(ui.get("empty", {}))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(label, 22)
	box.add_child(label)

## One flight as a full-width button: the whole row is the tap target.
func _add_row(box: VBoxContainer, row: Dictionary) -> void:
	var f := _factor
	var id := str(row.id)
	var quiz := bool(ui.get("quiz", false))
	var button := Button.new()
	button.name = "Row " + id
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP if quiz else Control.MOUSE_FILTER_IGNORE
	button.disabled = quiz and solved and not marks.get(id, false)
	button.pressed.connect(func() -> void: flight_pressed.emit(id))
	button.custom_minimum_size = Vector2(0, _row_height(ROW_FONT) * f)
	var text_color: Color = BOARD_TEXT
	var mark := ""
	if marks.has(id):
		mark = "✓ " if marks[id] else "✗ "
	var cells := [mark + str(row.code), str(row.airport), row.day, str(row.time)]
	var line := _cells(cells, [text_color, text_color, text_color, BOARD_TIME], ROW_FONT, Flags.texture(str(row.get("flag", ""))))
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 12 * f
	line.offset_right = -12 * f
	button.add_child(line)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := BOARD
		var border := Color(0, 0, 0, 0)
		var width := 0
		if state == "hover" and quiz:
			fill = BOARD.lightened(0.12)
		if marks.has(id):
			fill = (RIGHT if marks[id] else WRONG).darkened(0.1)
			border = RIGHT if marks[id] else WRONG
			width = 3
		button.add_theme_stylebox_override(state, _style(fill, border, width, 6))
	box.add_child(button)
	if not rows.has(id):
		rows[id] = []
	rows[id].append(button)

## The clock's frame and the month calendar: a title, the seven day heads (Sunday first;
## with translations, the native head under each) and the days, other months' days dim and
## today circled in gold.
func _rebuild_calendar() -> void:
	var f := _factor
	for panel_node in [_clock_panel, _calendar_panel]:
		panel_node.add_theme_stylebox_override("panel", _style(BOARD, BOARD_EDGE, 3, 10))
		(panel_node.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(10 * f)
	_main.add_theme_constant_override("separation", int(12 * f))
	_board_column.add_theme_constant_override("separation", int(6 * f))
	_side.add_theme_constant_override("separation", int(12 * f))
	for child in _calendar_box.get_children():
		_calendar_box.remove_child(child)
		child.queue_free()
	var calendar: Dictionary = ui.get("calendar", {})
	if calendar.is_empty():
		return
	_calendar_box.add_theme_constant_override("separation", int(6 * f))
	var title := _label(BOARD_TIME)
	title.text = _text(calendar.title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(title, 20)
	_calendar_box.add_child(title)
	var grid := GridContainer.new()
	grid.name = "Days"
	grid.columns = 7
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", int(2 * f))
	grid.add_theme_constant_override("v_separation", int(2 * f))
	_calendar_box.add_child(grid)
	# No day names by default (user decision, 8 Nov 2026): the player works out a weekday from
	# today's (on the clock) and the order of the days. With translations shown the heads appear
	# in the NATIVE language only (Sun, Mon…), to find one's place without the foreign word.
	if show_native:
		for head in calendar.heads:
			var label := _calendar_label(str(head.get("native", "")), DIM, CALENDAR_FONT * .85)
			label.set_meta("calendar_head", true)
			grid.add_child(label)
	for cell in calendar.cells:
		var side := CALENDAR_FONT * 1.9 * f
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.custom_minimum_size = Vector2(0, side)
		var label := _calendar_label(str(cell.day), BOARD_TEXT if bool(cell.month) else BOARD_TEXT.darkened(.55), CALENDAR_FONT)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.custom_minimum_size = Vector2(side, side)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if bool(cell.today):
			holder.name = "Today"
			label.add_theme_color_override("font_color", BOARD)
			label.add_theme_stylebox_override("normal", _style(BOARD_TIME, BOARD_TIME, 0, roundi(side / 2.0)))
		holder.add_child(label)
		grid.add_child(holder)

func _calendar_label(text: String, color: Color, size: float) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", roundi(size * _factor))
	return label

func _layout_content() -> void:
	var showing_summary := not summary.is_empty()
	_main.visible = not showing_summary
	_summary_box.visible = showing_summary
	if showing_summary:
		_fill_summary()
	if _board_panel.visible:
		_fit_rows(_board_rows, _content.size.y - _tabs.get_combined_minimum_size().y - 32 * _factor)
	_fit_calendar.call_deferred()

## The calendar's day cells shrink when the clock and calendar are taller than the content
## (25 Nov 2026: the card starts below the HUD's EN, and holding EN adds the native lines and
## day heads), so the month's last week stays on screen. _rebuild_calendar() resets them.
func _fit_calendar() -> void:
	var grid: GridContainer = _calendar_box.get_node_or_null("Days")
	if grid == null or not _main.visible:
		return
	var over := _side.get_combined_minimum_size().y - _content.size.y
	var cells: Array = grid.get_children().filter(func(child): return child is CenterContainer)
	if over <= 0.5 or cells.is_empty():
		return
	var weeks := ceili(cells.size() / 7.0)
	var side := maxf(cells[0].custom_minimum_size.y - ceilf(over / weeks), CALENDAR_FONT * 1.2 * _factor)
	for holder in cells:
		holder.custom_minimum_size.y = side
		(holder.get_child(0) as Control).custom_minimum_size = Vector2(side, side)

## Rows share the height they have (six flights a tab and the feedback lines take room): the
## text shrinks a little to fit, but never below MIN_FONT. There is no scroll bar (8 Nov 2026);
## six rows fit at a laptop window, which the capture checks.
func _fit_rows(box: VBoxContainer, available: float) -> void:
	var f := _factor
	var buttons: Array = box.get_children().filter(func(child): return child is Button)
	if buttons.is_empty() or available <= 0.0:
		return
	var separation := box.get_theme_constant("separation")
	var header := _row_height(HEADER_FONT) * f
	var font := ROW_FONT
	while font > MIN_FONT and header + buttons.size() * (_row_height(font) * f + separation) > available:
		font -= 1.0
	for button in buttons:
		button.custom_minimum_size.y = _row_height(font) * f
		for label in button.find_children("*", "Label", true, false):
			label.add_theme_font_size_override("font_size", roundi(font * f * (NATIVE_SCALE if label.name == "Native" else 1.0)))
		for icon in button.find_children("Flag", "TextureRect", true, false):
			icon.custom_minimum_size = Vector2(30, 20) * f * font / 19.0

func _two_lines() -> bool:
	return show_native and GameSettings.shared().display == GameSettings.FOREIGN

func _fill_summary() -> void:
	for child in _summary_box.get_children():
		_summary_box.remove_child(child)
		child.queue_free()
	_summary_box.add_theme_constant_override("separation", int(8 * _factor))
	# Missed questions first, in the "wrong" colour: what each expression meant on the board.
	if not summary.get("review", []).is_empty():
		var heading := _label(WRONG.lightened(0.35))
		heading.text = _text(summary.review_title)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_font(heading, 28)
		_summary_box.add_child(heading)
		for line in summary.review:
			var item := _label(WRONG.lightened(0.5))
			item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item.text = GameSettings.shared().inline(line, true, "  —  ")
			_set_font(item, 23)
			_summary_box.add_child(item)
	if summary.lines.is_empty():
		return
	var title := _label(GOLD)
	title.text = _text(summary.title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_font(title, 28)
	_summary_box.add_child(title)
	for line in summary.lines:
		var item := _label(GOLD)
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# The practised words always show their translation.
		item.text = GameSettings.shared().inline(line, true, "  —  ")
		_set_font(item, 23)
		_summary_box.add_child(item)
