extends Control
## The Warehouse Worker task card (Phase 4, 5 Nov 2026; guide: docs/guides/WAREHOUSE.md): a compact
## card at the top centre of the screen while a warehouse game runs. Top row: "Task 2 of 10",
## the shared progress bar, the translate bubble, a hint button ("?") and a leave button (the
## exit icon). Below: the task sentence in the language being learned, its pinyin when Chinese
## is learned, and the translation when revealed. It only draws what the session gives it and
## emits `hint_requested` / `leave_requested`; it knows nothing about warehouses or words.
##
## Review of 8 Nov 2026 (user asked for it): the bar's own "0/5" count repeated the title
## ("Tarea 1 de 5") and read as a different number, so the card hides it; the exit button was
## the engine's grey default, unlike every other control, so the hint and exit buttons now use
## the card's outline style with tooltips; the "?" sits next to the exit, not on the text.
##
## Lines are {"foreign", "native"} dictionaries; GameSettings.view() decides what shows.
## Layout scales with min(window height / 800, window width / 1100), like money_panel.gd.
## Every button has focus_mode NONE so Space (jump) never presses it.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal leave_requested
signal hint_requested

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
## The praise line between two tasks.
const GOOD := Color("3f9a35")
const DESIGN := Vector2(1100, 800)
## Card width as a share of the window, and its top margin.
const WIDTH_SHARE := 0.5
const TOP := 0.02

var show_native := false
var _title: Dictionary = {}
var _task: Dictionary = {}
var _translate: Dictionary = {}
var _factor := 1.0

var card: PanelContainer
var title_label: Label
var progress
var translate_button: Button
var hint_button: Button
var leave_button: Button
var task_label: Label
var reading_label: Label
var native_label: Label

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Warehouse task card"
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
	progress.show_count = false
	top.add_child(progress)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(toggle_translation)
	top.add_child(translate_button)
	hint_button = _icon_button("question")
	hint_button.pressed.connect(func() -> void: hint_requested.emit())
	top.add_child(hint_button)
	leave_button = _icon_button("exit")
	leave_button.pressed.connect(func() -> void: leave_requested.emit())
	top.add_child(leave_button)
	task_label = _label(30, GOLD)
	stack.add_child(task_label)
	reading_label = PinyinText.style(_label(20, GOLD.darkened(0.15)))
	stack.add_child(reading_label)
	native_label = _label(22, DIM)
	stack.add_child(native_label)
	visible = false
	resized.connect(_rescale)

func _ready() -> void:
	get_viewport().size_changed.connect(_rescale)
	_rescale()

## A square icon button in the card's outline style (filled while hovered or pressed).
func _icon_button(icon_name: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.icon = UiIcons.texture(icon_name, 64)
	button.expand_icon = false
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = {"normal": BonStyle.SKY_TOP, "hover": BonStyle.RIM, "pressed": BonStyle.SKY.darkened(0.08)}[state]
		style.anti_aliasing = true
		style.border_color = EDGE
		style.set_border_width_all(4)
		style.set_corner_radius_all(12)
		button.add_theme_stylebox_override(state, style)
	return button

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.set_meta("base_font", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

## `title`: "Task 2 of 10"; `task`: the sentence; `translate`: the bubble's tooltip line;
## `tips`: the hint and exit buttons' tooltips ({"hint": text, "leave": text}).
func open(title: Dictionary, task: Dictionary, translate: Dictionary, done: int, total: int, tips: Dictionary = {}) -> void:
	hint_button.tooltip_text = str(tips.get("hint", ""))
	leave_button.tooltip_text = str(tips.get("leave", ""))
	_title = title
	_task = task
	task_label.add_theme_color_override("font_color", GOLD)
	reading_label.add_theme_color_override("font_color", GOLD.darkened(0.15))
	_translate = translate
	progress.set_progress(done, total)
	visible = true
	refresh_display()

## "¡Muy bien! Siguiente tarea." in the task's place, in green, with the progress bar already
## moved on; the session shows the next task with open() a moment later.
func praise(line: Dictionary, done: int, total: int) -> void:
	_task = line
	progress.set_progress(done, total)
	task_label.add_theme_color_override("font_color", GOOD)
	reading_label.add_theme_color_override("font_color", GOOD.darkened(.15))
	visible = true
	refresh_display()

func is_praising() -> bool:
	return task_label.get_theme_color("font_color") == GOOD

func hide_card() -> void:
	visible = false

func toggle_translation() -> void:
	show_native = not show_native
	refresh_display()

## Re-renders the text (the Display Mode or a language changed).
func refresh_display() -> void:
	if _task.is_empty():
		return
	title_label.text = GameSettings.shared().view(_title, false)[0]
	var shown: Array = GameSettings.shared().view(_task, show_native)
	task_label.text = shown[0]
	PinyinText.show(reading_label, _task)
	native_label.text = shown[1]
	native_label.visible = shown[1] != ""
	_rescale()

func _rescale() -> void:
	if not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	for label in [title_label, task_label, reading_label, native_label]:
		label.add_theme_font_size_override("font_size", roundi(int(label.get_meta("base_font")) * _factor))
	(card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12 * _factor)
	translate_button.refresh(show_native, _factor)
	translate_button.tooltip_text = str(_translate.get("native", ""))
	for button in [hint_button, leave_button]:
		button.custom_minimum_size = Vector2(52, 46) * _factor
		button.add_theme_constant_override("icon_max_width", roundi(26 * _factor))
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
