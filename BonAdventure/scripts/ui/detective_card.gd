extends Control
## The police detective games' card (6 Nov 2026; design: docs/evidence/police-detective-20261106/PROMPT.md),
## shared by the lineup (police_lineup_session.gd) and the evidence game
## (police_evidence_session.gd). A card at the top centre: "Round 2 of 4", the shared progress
## bar, the translate bubble and the leave button; the officer's description (the clue
## sentence) with its pinyin and translation; a feedback line; and a button row: the tools
## (evidence game only), then the accuse button when the session gives one (none since 8 Nov
## 2026) or, once solved, Next / Finish. The evidence game's report rounds add a row of answer
## buttons over the tools (set_choices(); choice_pressed). After the last round
## show_summary() replaces the clue with the words practised, one line per round.
## Buttons (tools, answers, Next) show their translation on a second line while the translate
## bubble is on (GameSettings.stacked(), as in the shop and restaurant panels; 8 Nov 2026).
## (The bottom-right inset of the old Tocar / Escuchar results was removed with the evidence
## redesign of 8 Nov 2026: the results are now badges over the objects, evidence_props.gd.)
##
## It only draws what the session gives it and emits signals; it knows nothing about suspects
## or objects. Lines are {"foreign", "native"} dictionaries; GameSettings.view() decides what
## shows. Layout scales with min(window height / 800, window width / 1100), like
## money_panel.gd. Every button has focus_mode NONE so Space (jump) never presses it.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal leave_requested
signal tool_pressed(id: String)
signal accuse_pressed
## An answer button of a report round (index into the lines given to set_choices()).
signal choice_pressed(index: int)
signal next_pressed

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
const GOOD := Color("3f9a35")
const BAD := Color("d0523f")
const BUTTON := BonStyle.SKY_TOP
const BUTTON_ON := BonStyle.GREEN_BOTTOM
const ACCUSE := BonStyle.GREEN_BOTTOM
const DESIGN := Vector2(1100, 800)
const WIDTH_SHARE := 0.56
const TOP := 0.02

var show_native := false
var _title: Dictionary = {}
var _clue: Dictionary = {}
var _feedback: Dictionary = {}
var _feedback_good := false
var _translate: Dictionary = {}
## [{"id", "label": line, "icon"}] for the tool buttons; empty in the lineup.
var _tools: Array = []
var _tool := ""
var _accuse: Dictionary = {}
var _next: Dictionary = {}
var _solved := false
var _factor := 1.0
## The end-of-game list: one {"foreign", "native"} line per round (empty while playing).
var _summary: Array = []

var card: PanelContainer
var title_label: Label
var progress
var translate_button: Button
var leave_button: Button
var clue_label: Label
var reading_label: Label
var native_label: Label
var feedback_label: Label
var feedback_native: Label
var tool_row: HBoxContainer
var summary_box: VBoxContainer
var accuse_button: Button
var next_button: Button
var choice_row: HBoxContainer
var _tool_buttons: Dictionary = {}
## The answers of a report round: one {"foreign", "native"} line per button.
var _choices: Array = []
var _choice_buttons: Array = []

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Detective card"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(FILL, .94)
	style.border_color = EDGE
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.anti_aliasing = true
	style.shadow_color = Color(0.1, 0.27, 0.32, 0.22)
	style.shadow_size = 10
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	card.add_child(stack)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	stack.add_child(top)
	title_label = _label(22, DIM)
	top.add_child(title_label)
	progress = ProgressBarRow.new()
	top.add_child(progress)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(toggle_translation)
	top.add_child(translate_button)
	leave_button = Button.new()
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.icon = UiIcons.texture("exit", 64)
	leave_button.expand_icon = false
	leave_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leave_button.pressed.connect(func() -> void: leave_requested.emit())
	top.add_child(leave_button)
	clue_label = _label(30, GOLD)
	stack.add_child(clue_label)
	reading_label = PinyinText.style(_label(20, GOLD.darkened(0.15)))
	stack.add_child(reading_label)
	native_label = _label(22, DIM)
	stack.add_child(native_label)
	feedback_label = _label(24, GOOD)
	stack.add_child(feedback_label)
	feedback_native = _label(20, DIM)
	stack.add_child(feedback_native)
	summary_box = VBoxContainer.new()
	summary_box.name = "Summary"
	summary_box.add_theme_constant_override("separation", 2)
	summary_box.visible = false
	stack.add_child(summary_box)
	choice_row = HBoxContainer.new()
	choice_row.name = "Choices"
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_row.add_theme_constant_override("separation", 14)
	choice_row.visible = false
	stack.add_child(choice_row)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	tool_row = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 8)
	tool_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tool_row)
	accuse_button = _button(ACCUSE)
	accuse_button.icon = UiIcons.texture("check", 64)
	accuse_button.pressed.connect(func() -> void: accuse_pressed.emit())
	row.add_child(accuse_button)
	next_button = _button(BUTTON)
	next_button.icon = UiIcons.texture("next", 64)
	next_button.pressed.connect(func() -> void: next_pressed.emit())
	row.add_child(next_button)
	visible = false
	resized.connect(_rescale)

func _ready() -> void:
	get_viewport().size_changed.connect(_rescale)
	_rescale()

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.set_meta("base_font", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(tint: Color) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("tint", tint)
	button.expand_icon = false
	# White words on green, dark teal on soft blue (UI art style, 18 Nov 2026).
	var ink: Color = Color.WHITE if tint.get_luminance() < 0.6 else BonStyle.INK
	for key in ["font_color", "font_hover_color", "font_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(key, ink)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = tint.lightened(0.12) if state == "hover" else tint
		box.border_color = BonStyle.RIM
		box.set_border_width_all(4)
		box.anti_aliasing = true
		box.set_corner_radius_all(18)
		box.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, box)
	return button

func _paint(button: Button, tint: Color, ink: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var box := button.get_theme_stylebox(state) as StyleBoxFlat
		box.bg_color = tint.lightened(0.12) if state == "hover" else tint
	for key in ["font_color", "font_hover_color", "font_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(key, ink)

## Opens the card for a round. `tools`: [{"id", "label": line, "icon"}] (may be empty);
## `accuse` / `next`: button lines.
func open(title: Dictionary, clue: Dictionary, translate: Dictionary, done: int, total: int, tools: Array, accuse: Dictionary) -> void:
	_title = title
	_clue = clue
	_translate = translate
	_accuse = accuse
	_feedback = {}
	_solved = false
	_tool = ""
	_summary = []
	progress.set_progress(done, total)
	if tools != _tools:
		_tools = tools
		for child in tool_row.get_children():
			child.queue_free()
		_tool_buttons.clear()
		for spec in tools:
			var button := _button(BUTTON)
			button.icon = UiIcons.texture(str(spec.get("icon", "")), 64)
			var id := str(spec.id)
			button.pressed.connect(func() -> void: tool_pressed.emit(id))
			tool_row.add_child(button)
			_tool_buttons[id] = button
	set_choices([])
	visible = true
	refresh_display()

func hide_card() -> void:
	visible = false

## The answer buttons of a report round ([] removes them): one {"foreign", "native"} line each.
func set_choices(lines: Array) -> void:
	_choices = lines
	for button in _choice_buttons:
		button.queue_free()
	_choice_buttons.clear()
	for k in lines.size():
		var button := _button(ACCUSE)
		var index := k
		button.pressed.connect(func() -> void: choice_pressed.emit(index))
		choice_row.add_child(button)
		_choice_buttons.append(button)
	refresh_display()

## Highlights the tool in use ("" for none).
func set_tool(id: String) -> void:
	_tool = id
	refresh_display()

## A feedback line under the clue: green when `good`, coral otherwise ({} clears it).
func set_feedback(line: Dictionary, good: bool) -> void:
	_feedback = line
	_feedback_good = good
	refresh_display()

## The round is solved: "¡Es este!" gives way to `next` (Next, or Finish on the last round).
func set_solved(next: Dictionary, done: int, total: int) -> void:
	_solved = true
	_next = next
	progress.set_progress(done, total)
	refresh_display()

## The end of the game: `title` ("You practised these words:") over `lines`, and `finish`.
func show_summary(title: Dictionary, lines: Array, finish: Dictionary) -> void:
	_clue = title
	_summary = lines
	_feedback = {}
	_solved = true
	_next = finish
	for child in summary_box.get_children():
		child.queue_free()
	for line in lines:
		summary_box.add_child(_label(24, GOLD))
		summary_box.add_child(_label(18, DIM))
	refresh_display()

func toggle_translation() -> void:
	show_native = not show_native
	refresh_display()

## Re-renders the text (the Display Mode or a language changed).
func refresh_display() -> void:
	if _clue.is_empty():
		return
	var settings = GameSettings.shared()
	title_label.text = settings.view(_title, false)[0]
	var shown: Array = settings.view(_clue, show_native)
	clue_label.text = shown[0]
	PinyinText.show(reading_label, _clue)
	native_label.text = shown[1]
	native_label.visible = shown[1] != ""
	var feedback: Array = settings.view(_feedback, show_native) if not _feedback.is_empty() else ["", ""]
	feedback_label.text = feedback[0]
	feedback_label.visible = feedback[0] != ""
	feedback_label.add_theme_color_override("font_color", GOOD if _feedback_good else BAD)
	feedback_native.text = feedback[1]
	feedback_native.visible = feedback[1] != ""
	summary_box.visible = not _summary.is_empty()
	tool_row.visible = _summary.is_empty()
	choice_row.visible = _summary.is_empty() and not _choices.is_empty()
	for k in mini(_choices.size(), _choice_buttons.size()):
		var choice: Button = _choice_buttons[k]
		choice.text = settings.stacked(_choices[k], show_native)
		choice.tooltip_text = str(_choices[k].get("native", ""))
		choice.disabled = _solved
	var rows: Array = summary_box.get_children().filter(func(child: Node) -> bool: return not child.is_queued_for_deletion())
	for k in _summary.size():
		if k * 2 + 1 >= rows.size():
			break
		var said: Array = settings.view(_summary[k], show_native)
		rows[k * 2].text = said[0]
		rows[k * 2 + 1].text = said[1]
		rows[k * 2 + 1].visible = said[1] != ""
	for spec in _tools:
		var button: Button = _tool_buttons.get(str(spec.id))
		if button == null:
			continue
		button.text = settings.stacked(spec.label, show_native)
		button.tooltip_text = str(spec.label.get("native", ""))
		button.disabled = _solved
		if str(spec.id) == _tool:
			_paint(button, BUTTON_ON, Color.WHITE)
		else:
			_paint(button, BUTTON, BonStyle.INK)
	accuse_button.text = settings.stacked(_accuse, show_native) if not _accuse.is_empty() else ""
	accuse_button.tooltip_text = str(_accuse.get("native", ""))
	accuse_button.visible = not _solved and not _accuse.is_empty()
	next_button.text = settings.stacked(_next, show_native) if not _next.is_empty() else ""
	next_button.tooltip_text = str(_next.get("native", ""))
	next_button.visible = _solved
	_rescale()

func _rescale() -> void:
	if not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	var labels: Array = [title_label, clue_label, reading_label, native_label, feedback_label, feedback_native]
	labels.append_array(summary_box.get_children())
	for label in labels:
		label.add_theme_font_size_override("font_size", roundi(int(label.get_meta("base_font")) * _factor))
	(card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12 * _factor)
	translate_button.refresh(show_native, _factor)
	translate_button.tooltip_text = str(_translate.get("native", ""))
	leave_button.custom_minimum_size = Vector2(56, 46) * _factor
	leave_button.add_theme_constant_override("icon_max_width", roundi(26 * _factor))
	var buttons: Array = [accuse_button, next_button]
	buttons.append_array(_tool_buttons.values())
	for button in buttons:
		button.custom_minimum_size = Vector2(120, 54) * _factor
		button.add_theme_font_size_override("font_size", roundi(22 * _factor))
		button.add_theme_constant_override("icon_max_width", roundi(26 * _factor))
		button.add_theme_constant_override("h_separation", roundi(8 * _factor))
	for button in _choice_buttons:
		button.custom_minimum_size = Vector2(200, 62) * _factor
		button.add_theme_font_size_override("font_size", roundi(28 * _factor))
	progress.apply_scale(_factor)
	_fit()
	# Wrapped labels report their height for the width they had BEFORE this layout, so the
	# card is measured again once the new width has settled (as shop_order_panel.gd does).
	_refit_next_frame()

func _fit() -> void:
	var screen := get_viewport_rect().size
	var width := screen.x * WIDTH_SHARE
	card.custom_minimum_size = Vector2(width, 0.0)
	card.size = Vector2(width, 0.0)
	card.position = Vector2((screen.x - width) * .5, screen.y * TOP)
	card.size = Vector2(width, card.get_combined_minimum_size().y)

func _refit_next_frame() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_fit()
