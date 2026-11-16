extends Control
## Full-screen family game UI (Dr. Li, hospital): the question on top with the "show
## translation" toggle and ✕, the family tree as connected cards (portrait, name, gender
## icon, age, birth date MM/DD/YYYY), and a bar with the date legend, the game's "today",
## the feedback line and the Yes / No, Another question and Exit buttons. It only draws what
## family_session.gd gives it and emits signals; it knows nothing about families or words.
## Text arrives as {"foreign", "native"} lines.
##
## - While visible it swallows every key and non-left mouse event (as money_panel.gd), and
##   Main disables the player's controls (Main.sync_player_controls).
## - Layout scales with min(window height / 800, window width / 1100) (UI decision,
##   4 Nov 2026: large tap targets, text that scales with a laptop window).
const Portraits := preload("res://scripts/ui/plush_portraits.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")

signal person_pressed(id: String)
signal answer_pressed(answer: String)
signal next_pressed
signal close_requested

const FILL := Color("142a38")
const EDGE := Color("7abfb3")
const GOLD := Color("fff1c5")
const DIM := Color("aadddc")
const CARD := Color("fffaf0")
const INK := Color("2b3b40")
const LINE := Color("7abfb3")
const RIGHT := Color("3fae5a")
const WRONG := Color("d0505a")
## Gender icon colours, the same blue and red as the school family poster's figures.
const MAN := Color("2f6ea5")
const WOMAN := Color("c84b4b")
## The people the question names (ui.named): a warm card, a gold border and a glow, so the
## learner finds them at once and can attend to the language (user decision, 4 Nov 2026).
## The glow was softened after the user found it too strong (4 Nov 2026).
const NAMED_CARD := Color("fff0c2")
const NAMED_EDGE := Color("f0a020")
const NAMED_EDGE_WIDTH := 4
const NAMED_GLOW := Color(1.0, 0.85, 0.45, 0.3)
const NAMED_GLOW_SIZE := 6
const DESIGN := Vector2(1100, 800)

var show_native := false
## {title, question, legend, today, yes, no, next, exit, translate}: {"foreign", "native"}
## lines; people: [{id, name, gender, age, date, species, row, col, parents, partner}];
## named: ids of the people the question names (highlighted); yes_no: bool. Set by open().
var ui: Dictionary = {}
## Card marks: person id or "yes"/"no" -> true (right) / false (wrong).
var marks: Dictionary = {}
var feedback: Dictionary = {}
var solved := false

var portraits
var _factor := 1.0
var _shade: ColorRect
var _card: PanelContainer
var _stack: VBoxContainer
var _title: Label
var _question: Label
var _native: Label
## Pinyin under the question when Chinese is the foreign language (GameSettings.reading()).
var _reading: Label
var _translate: Button
## The session's progress (7/20), left of the translate bubble; hidden without a target.
var progress
var _x: Button
var _tree: Control
var _legend: Label
var _today: Label
var _feedback: Label
var _yes: Button
var _no: Button
var _next: Button
var _exit: Button
## person id -> Button (the card)
var cards: Dictionary = {}

func _init() -> void:
	name = "Family panel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	portraits = Portraits.new()
	portraits.name = "Portraits"
	add_child(portraits)
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

func _style(color: Color, border: Color = EDGE, width: int = 2, radius: int = 14) -> StyleBoxFlat:
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
	_tree = Control.new()
	_tree.name = "Tree"
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.mouse_filter = Control.MOUSE_FILTER_PASS
	_tree.clip_contents = true
	_tree.draw.connect(_draw_lines)
	_tree.resized.connect(_layout_cards)
	_stack.add_child(_tree)
	# The feedback has its own full-width row: inside the button bar a long translated
	# button row left it no width, and it wrapped one letter per line (fixed 4 Nov 2026).
	_feedback = _label(GOLD)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stack.add_child(_feedback)
	var bar := HBoxContainer.new()
	_stack.add_child(bar)
	var dates := VBoxContainer.new()
	dates.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(dates)
	_legend = _label(GOLD)
	_legend.autowrap_mode = TextServer.AUTOWRAP_OFF
	_legend.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dates.add_child(_legend)
	_today = _label(DIM)
	_today.autowrap_mode = TextServer.AUTOWRAP_OFF
	_today.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dates.add_child(_today)
	_yes = _button(func() -> void: answer_pressed.emit("yes"))
	bar.add_child(_yes)
	_no = _button(func() -> void: answer_pressed.emit("no"))
	bar.add_child(_no)
	_next = _button(func() -> void: next_pressed.emit())
	bar.add_child(_next)
	_exit = _button(func() -> void: close_requested.emit())
	bar.add_child(_exit)
	for pair in [[_yes, "check"], [_no, "no"], [_next, "next"], [_exit, "exit"]]:
		pair[0].icon = UiIcons.texture(pair[1], 64)
		pair[0].add_theme_constant_override("h_separation", 10)

# --- Public API ------------------------------------------------------------------------

## Shows a new question (see `ui`); clears the marks and feedback.
func open(lines: Dictionary) -> void:
	ui = lines
	marks.clear()
	feedback = {}
	solved = false
	_rebuild_cards()
	visible = true
	_refresh()

func hide_panel() -> void:
	visible = false

## Marks a tapped card (or the Yes / No button) right or wrong and shows `line`.
func mark(id: String, right: bool, line: Dictionary) -> void:
	marks[id] = right
	feedback = line
	solved = solved or right
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

## Only left clicks / touches reach the cards and buttons; every key, wheel and other
## mouse button is swallowed while the panel is open. Esc goes to Main's popup stack.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Esc passes through to Main's popup stack, which runs close_requested.
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
		return
	if event is InputEventKey or (event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()

# --- Drawing -----------------------------------------------------------------------------

func _on_resized() -> void:
	if visible:
		_refresh()

func _text(line: Variant) -> String:
	return GameSettings.shared().inline(line, show_native)

## Buttons and the date line keep the translation on a second line, so the bar never
## grows wider than the window.
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
	_card.add_theme_stylebox_override("panel", _style(FILL))
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(16 * f)
	_stack.add_theme_constant_override("separation", int(8 * f))
	_set_font(_title, 22)
	_set_font(_question, 34)
	_set_font(_native, 24)
	_set_font(_reading, 22)
	_set_font(_legend, 22)
	_set_font(_today, 20)
	_set_font(_feedback, 30)
	_feedback.custom_minimum_size = Vector2(0, 42 * f)
	for button in [_x, _yes, _no, _next, _exit]:
		_set_font(button, 24)
		button.add_theme_constant_override("icon_max_width", roundi(28 * f))
	_x.custom_minimum_size = Vector2(60, 52) * f
	_translate.refresh(show_native, f)
	progress.apply_scale(f)
	_translate.tooltip_text = str(ui.get("translate", {}).get("native", ""))
	for button in [_yes, _no, _next, _exit]:
		button.custom_minimum_size = Vector2(150, 62) * f
	_title.text = GameSettings.shared().view(ui.title, false)[0]
	var shown: Array = GameSettings.shared().view(ui.question, show_native)
	_question.text = shown[0]
	PinyinText.show(_reading, ui.question)
	_native.text = shown[1]
	_native.visible = shown[1] != ""
	_legend.text = GameSettings.shared().view(ui.legend, false)[0]
	_today.text = _stacked(ui.today)
	_feedback.text = _text(feedback)
	_feedback.add_theme_color_override("font_color", RIGHT.lightened(0.35) if solved else (WRONG.lightened(0.35) if not feedback.is_empty() else GOLD))
	var yes_no := bool(ui.get("yes_no", false))
	_yes.visible = yes_no
	_no.visible = yes_no
	_yes.text = _stacked(ui.yes)
	_no.text = _stacked(ui.no)
	_yes.disabled = solved
	_no.disabled = solved
	for answer in [["yes", _yes], ["no", _no]]:
		var button: Button = answer[1]
		if marks.has(answer[0]):
			button.add_theme_stylebox_override("normal", _style((RIGHT if marks[answer[0]] else WRONG).darkened(0.2), Color.WHITE, 3, 10))
			button.add_theme_stylebox_override("disabled", button.get_theme_stylebox("normal"))
		else:
			button.remove_theme_stylebox_override("normal")
			button.remove_theme_stylebox_override("disabled")
	_next.visible = solved
	_next.text = _stacked(ui.next)
	_exit.text = _stacked(ui.exit)
	_layout_cards()

func _rebuild_cards() -> void:
	for child in _tree.get_children():
		_tree.remove_child(child)
		child.queue_free()
	cards.clear()
	for person in ui.get("people", []):
		var card := Button.new()
		card.name = "Card " + str(person.id)
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(func() -> void: person_pressed.emit(str(person.id)))
		var column := VBoxContainer.new()
		column.name = "Column"
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(column)
		var picture := TextureRect.new()
		picture.name = "Portrait"
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		picture.texture = portraits.texture(str(person.species))
		column.add_child(picture)
		var name_row := HBoxContainer.new()
		name_row.alignment = BoxContainer.ALIGNMENT_CENTER
		name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(name_row)
		var name_label := _card_label("Name", str(person.name), INK)
		name_row.add_child(name_label)
		var icon := _card_label("Gender", "♀" if person.gender == "f" else "♂", WOMAN if person.gender == "f" else MAN)
		name_row.add_child(icon)
		column.add_child(_card_label("Age", str(person.age), INK))
		column.add_child(_card_label("Date", str(person.date), INK))
		var tick := _card_label("Mark", "", Color.WHITE)
		tick.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		card.add_child(tick)
		_tree.add_child(card)
		cards[str(person.id)] = card

func _card_label(title: String, text: String, color: Color) -> Label:
	var label := Label.new()
	label.name = title
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	return label

## Places the cards on the template's grid (row = generation, col = card columns), as big
## as the tree area allows, centred.
func _layout_cards() -> void:
	var people: Array = ui.get("people", [])
	if people.is_empty() or _tree.size.x <= 0.0:
		return
	var min_col := INF
	var max_col := -INF
	var rows := 1
	for person in people:
		min_col = minf(min_col, float(person.col))
		max_col = maxf(max_col, float(person.col))
		rows = maxi(rows, int(person.row) + 1)
	var span := max_col - min_col + 1.0
	var cell := Vector2(_tree.size.x / span, _tree.size.y / rows)
	var size := Vector2(minf(cell.x * 0.9, 200 * _factor), minf(cell.y * 0.86, 230 * _factor))
	var used := Vector2(cell.x * span, cell.y * rows)
	var origin := (_tree.size - used) / 2.0
	var f := _factor
	var font := clampf(size.y / 9.0, 12 * f, 22 * f)
	var named: Array = ui.get("named", [])
	for person in people:
		var card: Button = cards[str(person.id)]
		var centre := origin + Vector2((float(person.col) - min_col + 0.5) * cell.x, (int(person.row) + 0.5) * cell.y)
		card.size = size
		card.position = centre - size / 2.0
		var id := str(person.id)
		var highlighted := named.has(id)
		var fill: Color = NAMED_CARD if highlighted else CARD
		var border: Color = NAMED_EDGE if highlighted else EDGE
		var width := NAMED_EDGE_WIDTH if highlighted else 2
		if marks.has(id):
			border = RIGHT if marks[id] else WRONG
			width = 6
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := _style(fill if state != "hover" else fill.darkened(0.06), border, width, 12)
			style.set_content_margin_all(6 * f)
			if highlighted:
				style.shadow_color = NAMED_GLOW
				style.shadow_size = roundi(NAMED_GLOW_SIZE * f)
			card.add_theme_stylebox_override(state, style)
		var column: VBoxContainer = card.get_node("Column")
		column.add_theme_constant_override("separation", 0)
		column.offset_left = 6 * f
		column.offset_right = -6 * f
		column.offset_top = 6 * f
		column.offset_bottom = -6 * f
		for part in ["Age", "Date"]:
			column.get_node(part).add_theme_font_size_override("font_size", roundi(font * 0.9))
		var name_row := column.get_child(1)
		name_row.get_node("Name").add_theme_font_size_override("font_size", roundi(font))
		name_row.get_node("Gender").add_theme_font_size_override("font_size", roundi(font * 1.1))
		var tick: Label = card.get_node("Mark")
		tick.text = "" if not marks.has(id) else ("✓" if marks[id] else "✗")
		tick.add_theme_font_size_override("font_size", roundi(font * 1.8))
		tick.add_theme_color_override("font_color", RIGHT if marks.get(id, false) else WRONG)
		tick.position = Vector2(size.x - font * 1.6, -font * 0.2)
		card.disabled = solved and not marks.get(id, false)
	_tree.queue_redraw()

## Partner lines between partners' cards; a line from each couple (or single parent) down
## to a bar above their children, and from the bar to each child.
func _draw_lines() -> void:
	var people: Array = ui.get("people", [])
	var by_id: Dictionary = {}
	for person in people:
		by_id[str(person.id)] = person
	var width := maxf(2.0, 3.0 * _factor)
	for person in people:
		var partner := str(person.get("partner", ""))
		if partner != "" and cards.has(partner) and str(person.id) < partner:
			var a: Rect2 = cards[str(person.id)].get_rect()
			var b: Rect2 = cards[partner].get_rect()
			var y := a.get_center().y
			_tree.draw_line(Vector2(minf(a.end.x, b.end.x), y), Vector2(maxf(a.position.x, b.position.x), y), LINE, width)
	# Group children by their parent set.
	var families: Dictionary = {}
	for person in people:
		var parents: Array = person.get("parents", [])
		if parents.is_empty():
			continue
		var key := ",".join(parents)
		if not families.has(key):
			families[key] = {"parents": parents, "children": []}
		families[key].children.append(str(person.id))
	for key in families:
		var parents: Array = families[key].parents
		var top := Vector2.ZERO
		var bottom := 0.0
		for parent in parents:
			var rect: Rect2 = cards[str(parent)].get_rect()
			top += rect.get_center()
			bottom = maxf(bottom, rect.end.y)
		top /= parents.size()
		if parents.size() == 1:
			top.y = bottom
		var child_top := INF
		var left := top.x
		var right := top.x
		for child in families[key].children:
			var rect: Rect2 = cards[child].get_rect()
			child_top = minf(child_top, rect.position.y)
			left = minf(left, rect.get_center().x)
			right = maxf(right, rect.get_center().x)
		var bar := (bottom + child_top) / 2.0
		_tree.draw_line(top, Vector2(top.x, bar), LINE, width)
		_tree.draw_line(Vector2(left, bar), Vector2(right, bar), LINE, width)
		for child in families[key].children:
			var rect: Rect2 = cards[child].get_rect()
			_tree.draw_line(Vector2(rect.get_center().x, bar), Vector2(rect.get_center().x, rect.position.y), LINE, width)
