extends Control
## The fitting room's outfit picker (user request, 9 Nov 2026; guide: docs/guides/TOWN_DESIGN_BRIEF.md
## "Fitting room outfit picker"): a card at the bottom of the screen while BonBon sits in a fitting
## cabin. Top row: the title (the word "fitting room"), the page dots, Cancel, Keep this look and
## the translate bubble. Below: one page of large outfit cards between ‹ and › page buttons, the
## job name in the foreign language (pinyin and the translation below when shown); the outfit
## BonBon is trying on is outlined in gold. BonBon herself is the preview: clicking a card dresses her
## at once (fitting_booth.gd).
## Touch (14 Nov 2026, user: not mobile friendly): no scroll bar. As many cards as fit the width
## show at a time; ‹ / › or a sideways swipe on the cards turns the page, and selecting an outfit
## (A / D) shows its page. The card is in touch_controls.gd's TOUCH_HIDE group: the joystick and
## the E / jump buttons hide while it shows (they took fingers on its left part and stood over
## Keep; Cancel and Keep are the ways out). The panel is one row shorter than before, so more of
## BonBon shows in the mirror view.
##
## It only draws what it is given and emits `picked(id)`, `kept` and `cancelled`; it knows
## nothing about booths, costumes or saving. Outfit names are the outfits.* phrases, so a new
## language needs no code. Layout scales with min(window height / 800, window width / 1100),
## like money_panel.gd; every button has focus_mode NONE so Space and Enter never press it.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")

signal picked(id: String)
signal kept
signal cancelled

const FILL := Color("142a38")
const EDGE := Color("7abfb3")
const GOLD := Color("fff1c5")
const DIM := Color("aadddc")
const KEEP := Color("2f9a5b")
const DESIGN := Vector2(1100, 800)
## Design sizes (× the window factor): an outfit card, the ‹ › buttons, the swipe distance.
const CARD := Vector2(130, 104)
const ARROW_WIDTH := 64.0
const SWIPE := 48.0
const TouchControls := preload("res://scripts/ui/touch_controls.gd")
const WIDTH_SHARE := 0.86
const BOTTOM_MARGIN := 0.02
## The word the title shows (data/words.json).
const TITLE_WORD := "fitting room"

var show_native := false
## Outfit ids in order ("" = BonBon's own look) and the one outlined.
var ids: Array = []
var selected := ""
var _factor := 1.0

var card: PanelContainer
var title_label: Label
var translate_button: Button
var row: HBoxContainer
var prev_button: Button
var next_button: Button
var dots_label: Label
## The page shown and how many cards fit on one (set by _rescale from the window width).
var page := 0
var per_page := 1
## A finger or mouse pressed on the cards: where, and whether it already turned a page.
var _swipe_from := Vector2.INF
var _swiped := false
var cancel_button: Button
var keep_button: Button
## id -> {"button", "name", "reading", "native"}.
var _cards: Dictionary = {}

func _init() -> void:
	name = "Outfit picker"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(FILL, .94)
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	card.add_to_group(TouchControls.TOUCH_HIDE)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	card.add_child(stack)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	stack.add_child(top)
	title_label = _label(24, DIM)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title_label)
	dots_label = _label(18, DIM)
	dots_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dots_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(dots_label)
	cancel_button = _action_button("Cancel", FILL.lightened(0.18))
	cancel_button.pressed.connect(func() -> void: cancelled.emit())
	top.add_child(cancel_button)
	keep_button = _action_button("Keep", KEEP)
	keep_button.pressed.connect(func() -> void: kept.emit())
	top.add_child(keep_button)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(toggle_translation)
	top.add_child(translate_button)
	var strip := HBoxContainer.new()
	stack.add_child(strip)
	prev_button = _action_button("Previous", FILL.lightened(0.12))
	prev_button.text = "‹"
	prev_button.set_meta("base_font", 40)
	prev_button.pressed.connect(func() -> void: turn_page(-1))
	strip.add_child(prev_button)
	row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_child(row)
	next_button = _action_button("Next", FILL.lightened(0.12))
	next_button.text = "›"
	next_button.set_meta("base_font", 40)
	next_button.pressed.connect(func() -> void: turn_page(1))
	strip.add_child(next_button)
	visible = false
	resized.connect(_rescale)

func _ready() -> void:
	get_viewport().size_changed.connect(_rescale)
	GameSettings.shared().changed.connect(refresh_display)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.set_meta("base_font", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _box(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(8)
	return box

func _action_button(button_name: String, color: Color) -> Button:
	var button := Button.new()
	button.name = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("base_font", 24)
	button.add_theme_stylebox_override("normal", _box(color, color, 0))
	button.add_theme_stylebox_override("disabled", _box(Color(color, 0.35), color, 0))
	button.add_theme_color_override("font_disabled_color", Color(Color.WHITE, 0.3))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.12), color, 0))
	button.add_theme_stylebox_override("pressed", _box(color.darkened(0.15), color, 0))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	return button

## Shows the picker with `outfit_ids` (outfit order, "" first) and `current` outlined.
func open(outfit_ids: Array, current: String) -> void:
	if outfit_ids != ids:
		ids = outfit_ids.duplicate()
		_build_cards()
	visible = true
	select(current)
	refresh_display()

func hide_picker() -> void:
	visible = false
	_swipe_from = Vector2.INF

func page_count() -> int:
	return maxi(1, ceili(float(ids.size()) / per_page))

## Shows page `page + step` (‹ / › or a swipe); stays on the first / last page.
func turn_page(step: int) -> void:
	_show_page(page + step)

func _show_page(number: int) -> void:
	page = clampi(number, 0, page_count() - 1)
	for i in ids.size():
		_cards[ids[i]].button.visible = i / per_page == page
	prev_button.disabled = page == 0
	next_button.disabled = page >= page_count() - 1
	var dots := ""
	for i in page_count():
		dots += "●" if i == page else "○"
	dots_label.text = dots
	dots_label.visible = page_count() > 1

## A sideways swipe on the cards turns the page (touch arrives as emulated mouse events). The
## page turns as soon as the finger has moved SWIPE. The card the swipe started on still reports
## its press on release (hiding it does not cancel it), so `_swiped` stays set until the next
## press and the cards ignore that press: a swipe never also tries an outfit on.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var on_cards: bool = event.pressed and row.get_global_rect().has_point(event.position)
		_swipe_from = event.position if on_cards else Vector2.INF
		if event.pressed:
			_swiped = false
	elif event is InputEventMouseMotion and _swipe_from != Vector2.INF and not _swiped:
		var moved: Vector2 = event.position - _swipe_from
		if absf(moved.x) >= SWIPE * _factor and absf(moved.x) > absf(moved.y):
			_swiped = true
			turn_page(-1 if moved.x > 0.0 else 1)

func _build_cards() -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	_cards.clear()
	for id in ids:
		var button := Button.new()
		button.name = "Outfit_" + (str(id) if id != "" else "own")
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.pressed.connect(func() -> void:
			if not _swiped:
				picked.emit(id))
		var lines := VBoxContainer.new()
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.add_theme_constant_override("separation", 0)
		lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(lines)
		var name_label := _label(22, GOLD)
		var reading_label := PinyinText.style(_label(16, GOLD.darkened(0.15)))
		var native_label := _label(17, DIM)
		for label in [name_label, reading_label, native_label]:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lines.add_child(label)
		row.add_child(button)
		_cards[id] = {"button": button, "name": name_label, "reading": reading_label, "native": native_label}
	_rescale()

## Outlines `id` and shows its page (A / D or a click).
func select(id: String) -> void:
	selected = id
	for key in _cards:
		_style_card(_cards[key].button, key == id)
	if ids.has(id):
		_show_page(ids.find(id) / per_page)

func _style_card(button: Button, on: bool) -> void:
	var width := maxi(2, roundi((4.0 if on else 2.0) * _factor))
	var base := Color(FILL.lightened(0.22 if on else 0.08), 1.0)
	var border := GOLD if on else EDGE.darkened(0.25)
	button.add_theme_stylebox_override("normal", _box(base, border, width))
	button.add_theme_stylebox_override("hover", _box(base.lightened(0.08), GOLD if on else EDGE, width))
	button.add_theme_stylebox_override("pressed", _box(base.darkened(0.1), GOLD, width))

## The job name of outfit `id` as a {"foreign", "native"} line (outfits.* phrases).
static func outfit_line(id: String) -> Dictionary:
	var phrase := "outfits." + UiText.slug("BonBon's own look" if id == "" else id)
	if not UiText.has(phrase):
		return {"foreign": id, "native": id}
	return Lexicon.shared().line(phrase)

func toggle_translation() -> void:
	show_native = not show_native
	refresh_display()

## Re-renders the text (opened, the translate bubble, or the Display Mode / a language changed).
func refresh_display() -> void:
	if not visible:
		return
	var settings = GameSettings.shared()
	var lexicon = Lexicon.shared()
	var title := {"foreign": lexicon.word(TITLE_WORD, lexicon.foreign), "native": lexicon.word(TITLE_WORD, lexicon.native)}
	title_label.text = _capital(settings.inline(title, show_native))
	for id in _cards:
		var line := outfit_line(id)
		var shown: Array = settings.view(line, show_native)
		_cards[id].name.text = shown[0]
		PinyinText.show(_cards[id].reading, line)
		_cards[id].native.text = shown[1]
		_cards[id].native.visible = shown[1] != "" and shown[1] != shown[0]
	cancel_button.text = settings.inline(lexicon.line("seats.outfit_cancel"), show_native)
	keep_button.text = settings.inline(lexicon.line("seats.outfit_keep"), show_native)
	_rescale()

static func _capital(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1) if text != "" else text

func _rescale() -> void:
	if not is_inside_tree():
		return
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	var labels: Array = [title_label, dots_label, cancel_button, keep_button, prev_button, next_button]
	for entry in _cards.values():
		labels.append_array([entry.name, entry.reading, entry.native])
	for label in labels:
		label.add_theme_font_size_override("font_size", roundi(int(label.get_meta("base_font")) * _factor))
	var margin := 12 * _factor
	(card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(margin)
	translate_button.refresh(show_native, _factor)
	var gap := roundi(10 * _factor)
	row.add_theme_constant_override("separation", gap)
	(row.get_parent() as HBoxContainer).add_theme_constant_override("separation", gap)
	# Large, easy targets (user decisions, 4 and 9 Nov 2026): as many full-size cards as fit
	# between the page buttons; they share the row's width.
	var arrow := Vector2(ARROW_WIDTH, CARD.y) * _factor
	prev_button.custom_minimum_size = arrow
	next_button.custom_minimum_size = arrow
	var inside := screen.x * WIDTH_SHARE - 2.0 * margin - 4.0
	var room := inside - 2.0 * (arrow.x + gap)
	per_page = maxi(1, floori((room + gap) / (CARD.x * _factor + gap)))
	var card_width := floorf((room - gap * (per_page - 1)) / per_page)
	for entry in _cards.values():
		entry.button.custom_minimum_size = Vector2(card_width, CARD.y * _factor)
	cancel_button.custom_minimum_size = Vector2(150, 60) * _factor
	keep_button.custom_minimum_size = Vector2(200, 60) * _factor
	if ids.has(selected):
		select(selected)
	else:
		_show_page(page)
	_fit()
	_refit_next_frame()

func _fit() -> void:
	var screen := get_viewport_rect().size
	var width := screen.x * WIDTH_SHARE
	card.custom_minimum_size = Vector2(width, 0.0)
	card.size = Vector2(width, card.get_combined_minimum_size().y)
	card.position = Vector2((screen.x - width) * .5, screen.y * (1.0 - BOTTOM_MARGIN) - card.size.y)

func _refit_next_frame() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_fit()
