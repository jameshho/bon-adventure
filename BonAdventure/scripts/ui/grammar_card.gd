extends Control
## The Grammar Classroom card (guide: docs/guides/GRAMMAR_CLASS.md): a compact card at the top centre
## while a class runs. Top row: "Question 3 of 6", the shared progress bar (the points:
## right answers out of 10), the translate bubble and a leave button (the exit icon). Below: the feedback after an answer (✓ / ✗, the
## right sentence and a short explanation in the player's language) and the large on-screen
## Confirm button (user decision, 6 Nov 2026: a button only, no hotkey). While a question is
## open the seconds left are a large number in the middle of the screen with a short hint below
## it ("Hurry! Pick a desk!"; user decision, 8 Nov 2026); the last 3 seconds turn red and pulse.
## It only draws what grammar_session.gd gives it and emits `confirm_pressed` and
## `leave_requested`; it knows nothing about grammar or desks.
##
## Lines are {"foreign", "native"} dictionaries; GameSettings.view() decides what shows.
## Layout scales with min(window height / 800, window width / 1100), like money_panel.gd.
## Every button has focus_mode NONE so Space and Enter never press it.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const ProgressBarRow := preload("res://scripts/ui/progress_bar.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal confirm_pressed
signal leave_requested

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
const RIGHT := Color("3f9a35")
const WRONG := Color("d0523f")
const CONFIRM := BonStyle.GREEN_BOTTOM
const HURRY := Color("e0614f")
const INK := Color("0b1a24")
## The countdown's centre, as a share of the screen height: high, over the ceiling, so it never
## hides the question on the board or the answer desks (render check, 8 Nov 2026).
const COUNTDOWN_Y := 0.14
const LAST_SECONDS := 3
const DESIGN := Vector2(1100, 800)
const WIDTH_SHARE := 0.46
const BOTTOM_MARGIN := 0.02

var show_native := false
var _title: Dictionary = {}
var _status: Dictionary = {}
var _sentence: Dictionary = {}
var _explain := ""
var _confirm: Dictionary = {}
## The button's line during feedback after a miss ("Continue"); empty otherwise.
var _continue: Dictionary = {}
var _translate: Dictionary = {}
var _status_color := GOLD
var _factor := 1.0

var card: PanelContainer
var title_label: Label
var progress
var translate_button: Button
var leave_button: Button
var status_label: Label
var sentence_label: Label
var reading_label: Label
var native_label: Label
var explain_label: Label
var confirm_button: Button
## The large countdown in the middle of the screen: the number and the hint below it.
var countdown: VBoxContainer
var count_label: Label
var hint_label: Label
var _hint: Dictionary = {}
var _seconds_left := 0.0

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Grammar card"
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
	status_label = _label(30, GOLD)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(status_label)
	sentence_label = _label(26, GOLD)
	sentence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(sentence_label)
	reading_label = PinyinText.style(_label(18, GOLD.darkened(0.15)))
	reading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(reading_label)
	native_label = _label(20, DIM)
	native_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(native_label)
	explain_label = _label(20, DIM)
	explain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(explain_label)
	confirm_button = Button.new()
	confirm_button.name = "Confirm"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.set_meta("base_font", 26)
	confirm_button.pressed.connect(func() -> void:
		if not confirm_button.disabled:
			confirm_pressed.emit())
	_style_confirm()
	stack.add_child(confirm_button)
	countdown = VBoxContainer.new()
	countdown.name = "Countdown"
	countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown.add_theme_constant_override("separation", 0)
	countdown.visible = false
	add_child(countdown)
	count_label = _label(120, Color.WHITE)   # over the room: white with an INK edge
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	countdown.add_child(count_label)
	hint_label = _label(34, Color.WHITE)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	countdown.add_child(hint_label)
	for label in [count_label, hint_label]:
		label.add_theme_color_override("font_outline_color", INK)
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

func _style_confirm() -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = CONFIRM.lightened(0.12) if state == "hover" else CONFIRM.darkened(0.15) if state == "pressed" else BonStyle.SKY.lerp(Color(0.86, 0.88, 0.88), 0.6) if state == "disabled" else CONFIRM
		box.set_corner_radius_all(18)
		box.border_color = BonStyle.RIM
		box.set_border_width_all(4)
		box.anti_aliasing = true
		box.set_content_margin_all(10)
		confirm_button.add_theme_stylebox_override(state, box)
	confirm_button.add_theme_color_override("font_color", Color.WHITE)
	confirm_button.add_theme_color_override("font_hover_color", Color.WHITE)
	confirm_button.add_theme_color_override("font_disabled_color", Color(BonStyle.INK, .4))

## A class is running: `title` "Question 3 of 6", `confirm` the button's line, `translate`
## the bubble's tooltip line, `points` of `total` on the progress bar.
func open(title: Dictionary, confirm: Dictionary, translate: Dictionary, points: int, total: int) -> void:
	_title = title
	_confirm = confirm
	_translate = translate
	progress.set_progress(points, total)
	visible = true
	refresh_display()

## A question is open: `seconds` left as the large number and `hint` below it ("Hurry! Pick a
## desk!" or "Press Confirm or wait"); the card itself shows only the title row and Confirm.
func show_countdown(seconds: float, hint: Dictionary, confirm_enabled: bool) -> void:
	var changed := hint != _hint or not countdown.visible or not _status.is_empty() or confirm_button.disabled == confirm_enabled
	_seconds_left = seconds
	_hint = hint
	countdown.visible = true
	_update_count()
	if not changed:
		return
	_status = {}
	_sentence = {}
	_explain = ""
	_continue = {}
	confirm_button.disabled = not confirm_enabled
	confirm_button.visible = true
	refresh_display()

## The number, red and pulsing (once a second) in the last seconds.
func _update_count() -> void:
	var whole := ceili(_seconds_left)
	count_label.text = str(whole)
	var last := whole <= LAST_SECONDS
	count_label.add_theme_color_override("font_color", HURRY if last else Color.WHITE)
	var beat := _seconds_left - floorf(_seconds_left)
	countdown.pivot_offset = countdown.size * .5
	countdown.scale = Vector2.ONE * (1.0 + (0.18 * beat * beat if last else 0.0))

## Feedback after a submission: ✓ / ✗ line, the right sentence and the explanation. With a
## `continue_line` (after a miss) the button stays, relabelled, and emits confirm_pressed.
func show_feedback(status: Dictionary, right: bool, sentence: Dictionary, explain: String, continue_line: Dictionary = {}) -> void:
	_status = status
	_status_color = RIGHT if right else WRONG
	_sentence = sentence
	_explain = explain
	_continue = continue_line
	confirm_button.disabled = continue_line.is_empty()
	confirm_button.visible = not continue_line.is_empty()
	countdown.visible = false
	refresh_display()

## The title and points change between questions.
func set_round(title: Dictionary, points: int, total: int) -> void:
	_title = title
	progress.set_progress(points, total)
	refresh_display()

func set_confirm_enabled(enabled: bool) -> void:
	confirm_button.disabled = not enabled

func hide_card() -> void:
	visible = false
	countdown.visible = false

func toggle_translation() -> void:
	show_native = not show_native
	refresh_display()

## Re-renders the text (the Display Mode or a language changed).
func refresh_display() -> void:
	if _title.is_empty():
		return
	var settings = GameSettings.shared()
	title_label.text = settings.view(_title, false)[0]
	status_label.text = settings.inline(_status, show_native) if not _status.is_empty() else ""
	status_label.visible = status_label.text != ""
	status_label.add_theme_color_override("font_color", _status_color)
	hint_label.text = settings.inline(_hint, show_native) if not _hint.is_empty() else ""
	var shown: Array = settings.view(_sentence, show_native)
	sentence_label.text = shown[0]
	sentence_label.visible = shown[0] != ""
	PinyinText.show(reading_label, _sentence)
	native_label.text = shown[1]
	native_label.visible = shown[1] != ""
	explain_label.text = _explain
	explain_label.visible = _explain != ""
	confirm_button.text = settings.inline(_continue if not _continue.is_empty() else _confirm, false)
	_rescale()

func _rescale() -> void:
	if not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	for label in [title_label, status_label, sentence_label, reading_label, native_label, explain_label, confirm_button, count_label, hint_label]:
		label.add_theme_font_size_override("font_size", roundi(int(label.get_meta("base_font")) * _factor))
	(card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12 * _factor)
	translate_button.refresh(show_native, _factor)
	translate_button.tooltip_text = str(_translate.get("native", ""))
	leave_button.custom_minimum_size = Vector2(56, 46) * _factor
	leave_button.add_theme_constant_override("icon_max_width", roundi(26 * _factor))
	# A large, easy target (user decision, 4 Nov 2026).
	confirm_button.custom_minimum_size = Vector2(240, 64) * _factor
	count_label.add_theme_constant_override("outline_size", roundi(14 * _factor))
	hint_label.add_theme_constant_override("outline_size", roundi(8 * _factor))
	progress.apply_scale(_factor)
	_fit()
	_refit_next_frame()

func _fit() -> void:
	var screen := get_viewport_rect().size
	var width := screen.x * WIDTH_SHARE
	card.custom_minimum_size = Vector2(width, 0.0)
	card.size = Vector2(width, 0.0)
	card.position = Vector2((screen.x - width) * .5, 0.0)
	card.size = Vector2(width, card.get_combined_minimum_size().y)
	# Sits at the bottom of the screen (user decision, 8 Nov 2026).
	card.position.y = screen.y * (1.0 - BOTTOM_MARGIN) - card.size.y
	countdown.size = countdown.get_combined_minimum_size()
	countdown.position = Vector2((screen.x - countdown.size.x) * .5, screen.y * COUNTDOWN_Y - countdown.size.y * .5)
	countdown.pivot_offset = countdown.size * .5

func _refit_next_frame() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_fit()
