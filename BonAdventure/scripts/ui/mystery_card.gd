extends Control
## The Mystery Doors card (Mystery House, 9 Nov 2026; design: docs/guides/TOWN_DESIGN_BRIEF.md "Mystery
## House and Mystery Doors"): a compact card at the top centre while Madame Luna's game runs, in
## the warehouse task card's style. Top row: "Door 2 of 6", the shared progress bar (doors
## opened at the first try), the translate bubble and a leave button (the exit icon). Below: the
## clue in the language being learned ("Entra por la puerta roja con la estrella."), its pinyin
## when Chinese is learned, the translation when revealed, and a short how-to line in the
## player's language. After a wrong door the clue's key words (the colour, the shape) are
## highlighted. It only draws what mystery_session.gd gives it and emits `leave_requested`; it
## knows nothing about doors.
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

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
## Praise after a right door, and the highlighted key words after a wrong one.
const GOOD := Color("3f9a35")
const KEY := BonStyle.TERM
const DESIGN := Vector2(1100, 800)
const WIDTH_SHARE := 0.5
## Below the HUD clock at the top centre (render review, 9 Nov 2026: at 0.02 the clock covered
## the card's top row).
const TOP := 0.085

var show_native := false
var _title: Dictionary = {}
var _clue: Dictionary = {}
var _hint: Dictionary = {}
## The how-to line shown now: _hint, or after a right door "Walk through the open door".
var _hint_now: Dictionary = {}
var _translate: Dictionary = {}
## Key words of the clue to highlight ({"foreign", "native"} lines); empty: none.
var _keys: Array = []
var _praising := false
var _factor := 1.0

var card: PanelContainer
var title_label: Label
var progress
var translate_button: Button
var leave_button: Button
var clue_label: RichTextLabel
var reading_label: Label
var native_label: RichTextLabel
var hint_label: Label

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Mystery card"
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
	# The title already says "Door 2 of 6".
	progress.show_count = false
	top.add_child(progress)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(toggle_translation)
	top.add_child(translate_button)
	leave_button = Button.new()
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.icon = UiIcons.texture("exit", 64)
	leave_button.expand_icon = false
	leave_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leave_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": BonStyle.SKY_TOP, "hover": BonStyle.RIM, "pressed": BonStyle.SKY.darkened(0.08)}[state]
		box.anti_aliasing = true
		box.border_color = EDGE
		box.set_border_width_all(4)
		box.set_corner_radius_all(12)
		leave_button.add_theme_stylebox_override(state, box)
	leave_button.pressed.connect(func() -> void: leave_requested.emit())
	top.add_child(leave_button)
	clue_label = _rich(30)
	stack.add_child(clue_label)
	reading_label = PinyinText.style(_label(20, GOLD.darkened(0.15)))
	reading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(reading_label)
	native_label = _rich(22)
	stack.add_child(native_label)
	hint_label = _label(18, DIM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(hint_label)
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

## A centred, wrapping text that can colour its key words (BBCode).
func _rich(font_size: int) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.set_meta("base_font", font_size)
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

## A game started: `title` "Door 1 of 6", `hint` the how-to line (native), `translate` the
## bubble's tooltip line, `done` of `total` on the progress bar.
func open(title: Dictionary, hint: Dictionary, translate: Dictionary, done: int, total: int, tips: Dictionary = {}) -> void:
	leave_button.tooltip_text = str(tips.get("leave", ""))
	_title = title
	_hint = hint
	_hint_now = hint
	_translate = translate
	_clue = {}
	_keys = []
	_praising = false
	progress.set_progress(done, total)
	visible = true
	refresh_display()

## A new door: the title and the clue, nothing highlighted.
func set_round(title: Dictionary, clue: Dictionary, done: int, total: int) -> void:
	_title = title
	_clue = clue
	_hint_now = _hint
	_keys = []
	_praising = false
	progress.set_progress(done, total)
	refresh_display()

## After a wrong door: the same clue with its key words (the colour, the shape) highlighted.
func highlight(keys: Array) -> void:
	_keys = keys
	refresh_display()

## "¡Correcto!" in green in the clue's place, the bar already moved on; `hint` (native) under it.
func praise(line: Dictionary, done: int, total: int, hint: Dictionary = {}) -> void:
	_clue = line
	_hint_now = hint
	_keys = []
	_praising = true
	progress.set_progress(done, total)
	refresh_display()

func hide_card() -> void:
	visible = false

func toggle_translation() -> void:
	show_native = not show_native
	refresh_display()

## Re-renders the text (the Display Mode or a language changed).
func refresh_display() -> void:
	if _title.is_empty():
		return
	var settings = GameSettings.shared()
	title_label.text = settings.view(_title, false)[0]
	var shown: Array = settings.view(_clue, show_native)
	var color := GOOD if _praising else GOLD
	clue_label.text = _marked(shown[0], 0, color)
	PinyinText.show(reading_label, _clue)
	native_label.text = _marked(shown[1], 1, DIM)
	native_label.visible = shown[1] != ""
	hint_label.text = str(_hint_now.get("native", ""))
	hint_label.visible = hint_label.text != ""
	_rescale()

## `text` centred in `color`, with the shown text of each key word (view() part `part`)
## coloured and underlined where it appears.
func _marked(text: String, part: int, color: Color) -> String:
	var out := text.replace("[", "[lb]")
	for key in _keys:
		var word: String = str(GameSettings.shared().view(key, true)[part])
		if word == "" or not out.contains(word):
			continue
		out = out.replace(word, "[color=#%s][u]%s[/u][/color]" % [KEY.to_html(false), word])
	return "[center][color=#%s]%s[/color][/center]" % [color.to_html(false), out]

func _rescale() -> void:
	if not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	for label in [title_label, reading_label, hint_label]:
		label.add_theme_font_size_override("font_size", roundi(int(label.get_meta("base_font")) * _factor))
	for label in [clue_label, native_label]:
		label.add_theme_font_size_override("normal_font_size", roundi(int(label.get_meta("base_font")) * _factor))
	(card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12 * _factor)
	translate_button.refresh(show_native, _factor)
	translate_button.tooltip_text = str(_translate.get("native", ""))
	# A large, easy target (user decision, 4 Nov 2026).
	leave_button.custom_minimum_size = Vector2(56, 46) * _factor
	leave_button.add_theme_constant_override("icon_max_width", roundi(26 * _factor))
	progress.apply_scale(_factor)
	_fit()
	# Wrapped text reports its height for the width it had BEFORE this layout, so the card is
	# measured again once the new width has settled (as warehouse_task_card.gd does).
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
