extends Control
## The mahjong screen over the 3D table (docs/guides/MAHJONG.md): the player's concealed hand as
## large clickable tiles along the bottom (the tile just drawn set apart on the right), call
## buttons above it (Pung, Kong, one Chow button per way with its three tiles, Pass, Keep
## playing), a big pulsing golden Mahjong! button above those when the player can win, with
## what the hand is worth (user, 9 Nov 2026: winning is the player's own click and choice),
## a status card at the top left (the mode, your wind, the lessons book, the scoreboard button
## showing your points), translate and leave at the top right beside the HUD's own buttons
## (16 Nov 2026: the top centre stays clear for Awoo's face), the scoreboard card that button opens (10 Nov 2026,
## user: each player's wind and points this visit), no message line (user, 9 Nov 2026), and the result card at the end (who won,
## each scoring hand with its fan, the total, Play again and Leave). A round ▾ button over the
## hand bar's right end tucks the hand away to see the player's own tiles on the table under it
## (exposed sets, discards; user, 24 Nov 2026); ▴ at the bottom right brings it back, and so
## does the start of the player's next turn. It only draws what
## mahjong_session.gd gives it and emits signals; it knows no rules.
##
## Lines are {"foreign", "native"} dictionaries; GameSettings decides what shows. Layout scales
## with min(window height / 800, window width / 1100), like money_panel.gd (user decision,
## 4 Nov 2026: large tap targets on a laptop window). Buttons never take keyboard focus.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Tiles := preload("res://scripts/ui/mahjong_tiles.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const Portraits := preload("res://scripts/ui/plush_portraits.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

signal tile_pressed(kind: int)
## A tile double-clicked (or tapped twice) while another player is playing: play it
## automatically on the player's next turn (user, 9 Nov 2026). -1: the marked tile again, unmark.
signal tile_queued(kind: int)
## id: "win", "pung", "kong", "chow" (data: the chow's lowest tile, a kong's tile), "pass",
## "keep" (play on instead of a self-drawn win).
signal action_pressed(id: String, data: int)
signal leave_requested
## The book button: open Mei's lessons (mahjong_lesson_panel.gd) over the table.
signal lessons_requested
signal again_pressed

const FILL := BonStyle.SKY
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
const WIN := Color("c4262e")
## The big Mahjong! button: gold with red letters, gently pulsing.
const WIN_FILL := Color("ffc93c")
const WIN_INK := Color("b3202a")
const WIN_PULSE := 1.06
# The money panel's pattern (user's mockup, design-references/ui/money-panel.webp, 18 Nov 2026):
# green for the calls, cream pills for Pass / Keep / Leave and the hand's tray, soft blue cards.
const CALL := BonStyle.GREEN_BOTTOM
const PASS := Color("fbf1e1")
const TRAY := Color("fbf1e1")
## The scoreboard's change after a hand: points won, points paid.
const GAIN := Color("3f9a35")
const LOSS := Color("d0523f")
const TILE := Vector2(62, 84)
const DESIGN := Vector2(1100, 800)
## Places in the hand bar besides the drawn tile (13 less 3 for each exposed set).
const HAND_SLOTS := 13
## The hand bar's tiles are 30 % larger than TILE (user, 16 Nov 2026), less only when the bar
## would not fit the window's width (see _hand_tile()).
const HAND_GROWTH := 1.3
## The status card at the top left (text, small tiles, buttons and their icons) is 50 % larger
## than the rest of the panel (user, 16 Nov 2026). Everything in it, the icons included, scales
## with the window, so on a phone it stays clear of the far discards (user, 16 Nov 2026).
const INFO_GROWTH := 1.5
## The status card's largest height as a share of the screen's (it is scaled down past that).
const INFO_MAX_HEIGHT := 0.19
## The top centre is left clear for the face of the player across the table (Awoo; user,
## 16 Nov 2026: "make the top status bar easy to read but not block awoo's face"). His face is
## about the same share of the screen's height at any window size (the game camera keeps its
## vertical FOV), so the clear band reaches FACE_CLEAR x the screen's height to each side of
## the centre: about 0.21 of the height measured at 844x390 and 1280x800. The status card and
## the corner card (translate, leave) are scaled to stay outside it, and the status card grows
## up to INFO_MAX_GROW where there is room (a phone), always within INFO_MAX_HEIGHT.
const FACE_CLEAR := 0.23
## The status card's two lines (and the wind tile) are larger than its buttons, so together they
## fill the buttons' height and read on a phone (16 Nov 2026).
const INFO_TEXT_GROWTH := 1.85
const INFO_MAX_GROW := 1.4

var show_native := false
var letters: Array = []
var _factor := 1.0
## The hand bar's tile size (TILE × _factor × HAND_GROWTH, fitted to the window's width).
var _hand_tile := TILE
var _info: Array = []
var _hand: Array = []
var _drawn := -1
var _discarding := false
var _actions: Array = []
var _result: Dictionary = {}
var _places := HAND_SLOTS
## The tile marked to play on the player's next turn (-1: none); one slot of that kind shows it.
var _queued := -1
## The hand bar tucked away (hand_toggle); shown again on open() and when a turn of the player's
## begins.
var hand_hidden := false
var hand_toggle: Button

var info_card: PanelContainer
var info_rows: VBoxContainer
## Translate and leave, at the top right, left of the HUD's top-right buttons (`corner_limit`,
## set by the session; the card ends left of the leftmost visible one, else at the screen edge).
var corner_card: PanelContainer
var corner_limit: Array = []
var _info_tiles: Array = []
var _info_key: Array = []
var lessons_button: Button
var translate_button: Button
var leave_button: Button
var hand_bar: PanelContainer
var hand_row: HBoxContainer
var _slots: Array = []
var action_row: HBoxContainer
var win_offer: VBoxContainer
var result_card: PanelContainer
var result_stack: VBoxContainer
## The scoreboard button (star and your points) and the card it opens: [{"name": line,
## "face": species, "wind": kind, "total": "+12", "change": ""}] per seat, set by the session.
var score_button: Button
var score_card: PanelContainer
var score_stack: VBoxContainer
## Each player's face on both scoreboards (plush_portraits.gd, 11 Nov 2026).
var portraits
var _scores: Array = []

func _init() -> void:
	# Fredoka everywhere inside (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
	theme = BonStyle.theme()
	name = "Mahjong panel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	info_card = _card()
	add_child(info_card)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	info_card.add_child(top)
	info_rows = VBoxContainer.new()
	info_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_rows.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(info_rows)
	lessons_button = Button.new()
	lessons_button.focus_mode = Control.FOCUS_NONE
	lessons_button.icon = UiIcons.texture("book", roundi(64 * INFO_GROWTH))
	lessons_button.expand_icon = false
	lessons_button.pressed.connect(func() -> void: lessons_requested.emit())
	top.add_child(lessons_button)
	score_button = Button.new()
	score_button.name = "Scoreboard button"
	score_button.focus_mode = Control.FOCUS_NONE
	score_button.icon = UiIcons.texture("star", roundi(40 * INFO_GROWTH))
	score_button.expand_icon = false
	score_button.pressed.connect(func() -> void: show_scores(not score_card.visible))
	top.add_child(score_button)
	corner_card = _card()
	corner_card.name = "Corner card"
	add_child(corner_card)
	var corner_row := HBoxContainer.new()
	corner_row.add_theme_constant_override("separation", 10)
	corner_card.add_child(corner_row)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(func() -> void:
		show_native = not show_native
		refresh_display())
	corner_row.add_child(translate_button)
	leave_button = Button.new()
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.icon = UiIcons.texture("exit", roundi(64 * INFO_GROWTH))
	leave_button.expand_icon = false
	leave_button.pressed.connect(func() -> void: leave_requested.emit())
	corner_row.add_child(leave_button)
	hand_bar = _card()
	# The hand sits in a cream tray, like the money panel's "Tu mano".
	(hand_bar.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = TRAY
	add_child(hand_bar)
	hand_row = HBoxContainer.new()
	hand_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	hand_bar.add_child(hand_row)
	hand_toggle = Button.new()
	hand_toggle.name = "Hand toggle"
	hand_toggle.focus_mode = Control.FOCUS_NONE
	hand_toggle.expand_icon = false
	hand_toggle.pressed.connect(func() -> void: set_hand_hidden(not hand_hidden))
	add_child(hand_toggle)
	action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(action_row)
	win_offer = VBoxContainer.new()
	win_offer.alignment = BoxContainer.ALIGNMENT_CENTER
	win_offer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_offer.visible = false
	add_child(win_offer)
	result_card = _card()
	result_card.visible = false
	add_child(result_card)
	result_stack = VBoxContainer.new()
	result_stack.add_theme_constant_override("separation", 8)
	result_card.add_child(result_stack)
	score_card = _card()
	score_card.name = "Scoreboard"
	score_card.visible = false
	add_child(score_card)
	score_stack = VBoxContainer.new()
	score_card.add_child(score_stack)
	move_child(result_card, -1)
	visible = false
	resized.connect(_rescale)

func _ready() -> void:
	portraits = Portraits.new()
	portraits.name = "Portraits"
	add_child(portraits)
	get_viewport().size_changed.connect(_rescale)
	_rescale()

func _card() -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(FILL, .96)
	style.border_color = EDGE
	style.set_border_width_all(5)
	style.set_corner_radius_all(26)
	style.anti_aliasing = true
	style.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	return card

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.set_meta("base_font", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

## One language at a time (user, 23 Nov 2026): the foreign text, or only the native one while
## the HUD's EN is held (never "foreign / native" together: too crowded at the table).
func _text(line: Variant) -> String:
	var parts: Array = GameSettings.shared().view(line, show_native)
	return parts[1] if show_native and parts[1] != "" else parts[0]

## The width of `line`'s text in its widest language, in `control`'s font (call it in the tree).
func _widest(line: Variant, control: Control) -> float:
	var settings = GameSettings.shared()
	var font: Font = control.get_theme_font("font")
	var font_size: int = control.get_theme_font_size("font_size")
	var widest := 0.0
	for text in [settings.view(line, false)[0], settings.view(line, true)[1]]:
		if str(text) != "":
			widest = maxf(widest, font.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return ceilf(widest)

## Keeps a label or button as wide as its text in either language, so holding EN changes the
## words but never a size (user, 23 Nov 2026: EN resized the buttons). Measured once it is in
## the tree (deferred), before the next layout pass places it.
func _hold_width(control: Control, line: Variant) -> void:
	var apply := func() -> void:
		if not is_instance_valid(control):
			return
		var extra := 0.0
		var box: StyleBox = control.get_theme_stylebox("normal") if control is Button else null
		if box != null:
			extra = box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT)
		control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, _widest(line, control) + extra)
		_place.call_deferred()
	if control.is_inside_tree():
		apply.call()
	else:
		control.tree_entered.connect(apply, CONNECT_ONE_SHOT)

# --- What the session shows ----------------------------------------------------------------

func open() -> void:
	hand_hidden = false
	_result = {}
	result_card.visible = false
	visible = true
	refresh_display()

func hide_panel() -> void:
	visible = false
	result_card.visible = false
	score_card.visible = false

## The status card: lines (mode, tiles left, your wind, round wind); `tiles`: for each line
## a tile kind drawn small after it (-1: none), e.g. the wind tiles (user, 9 Nov 2026).
func set_info(lines: Array, tiles: Array = []) -> void:
	_info = lines
	_info_tiles = tiles
	refresh_display()

func _build_info() -> void:
	var texts: Array = _info.map(_text)
	var key := [texts, _info_tiles, _factor, letters]
	if key == _info_key:
		return   # unchanged: no rebuild between turns
	_info_key = key
	_clear(info_rows)
	var grown := _factor * INFO_TEXT_GROWTH
	info_rows.add_theme_constant_override("separation", 0)
	for i in _info.size():
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", roundi(8 * grown))
		var label := _label(19, DIM)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text = texts[i]
		label.add_theme_font_size_override("font_size", roundi(19 * grown))
		row.add_child(label)
		_hold_width(label, _info[i])
		var kind: int = int(_info_tiles[i]) if i < _info_tiles.size() else -1
		if kind >= 0:
			var tile := TileStrip.new()
			tile.tiles = [kind]
			tile.letters = letters
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tile.custom_minimum_size = Vector2(0.33, 0.33 * 1.3) * TILE.x * grown
			row.add_child(tile)
		info_rows.add_child(row)

## The player's concealed tiles (sorted), the tile just drawn (-1: none), whether a click
## discards now, and how many places the hand has besides the drawn tile (13 less 3 for each
## exposed set).
func set_hand(hand: Array, drawn: int, discarding: bool, places: int = HAND_SLOTS) -> void:
	if discarding and not _discarding:
		hand_hidden = false   # the player's turn: the hand is needed to play
	_hand = hand.duplicate()
	_drawn = drawn
	_discarding = discarding
	_places = clampi(places, 1, HAND_SLOTS)
	_build_hand()

## Marks the tile the player chose to play ahead (-1: none).
func set_queued(kind: int) -> void:
	if kind == _queued:
		return
	_queued = kind
	_build_hand()

## This visit's points, one {"name": line, "wind": kind, "total": "+12", "change": ""} per seat
## (the player first); `title`: the card's heading.
func set_scores(rows: Array) -> void:
	if rows == _scores:
		return
	_scores = rows.duplicate(true)
	score_button.text = str(_scores[0].total) if not _scores.is_empty() else ""
	if score_card.visible:
		_build_scores()

## Opens or closes the scoreboard card (the star button, its ✕).
func show_scores(open_it: bool) -> void:
	score_card.visible = open_it and not _scores.is_empty() and not result_card.visible   # the result has its own
	if score_card.visible:
		_build_scores()

## Call buttons: [{"id", "label": line, "data": int, "tiles": [kinds] (chow / kong pictures)}].
func set_actions(actions: Array) -> void:
	_actions = actions
	_build_actions()

## The end of the hand: {"title": line, "lines": [line], "total": line or {}, "scores":
## [{"name": line, "total": "+12", "change": "+8" or ""}] (this visit, one per seat)}; hides the
## hand and call buttons, shows Play again / Leave.
func show_result(result: Dictionary, again: Dictionary, leave: Dictionary) -> void:
	_result = {"data": result, "again": again, "leave": leave}
	set_actions([])
	_discarding = false
	_build_hand()
	_build_result()
	result_card.visible = true
	score_card.visible = false

# --- Building ------------------------------------------------------------------------------

## Removes the children at once (queue_free alone leaves them in the layout for a frame).
static func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

## The hand bar (user, 9 Nov 2026): one place per concealed tile (13, less 3 for each exposed
## set), a gap, and a place on the right for the drawn tile that stays even when empty. The
## bar is centred and shrinks only when a set is exposed; drawing or discarding never moves
## it. The slots are made once (again only when the window scale changes) and only their tiles
## change, so nothing is freed and rebuilt between turns (no flicker). Right after a claim the
## hand has one tile more than its places: the highest goes in the drawn place.
func _build_hand() -> void:
	_ensure_slots()
	var shown := _hand.duplicate()
	var drawn_kind := -1
	if _drawn >= 0 and shown.has(_drawn):
		shown.erase(_drawn)
		drawn_kind = _drawn
	elif shown.size() > _places:
		drawn_kind = shown.pop_back()
	var marked := false   # only one slot of the queued kind shows the mark
	for i in HAND_SLOTS + 1:
		var kind: int = drawn_kind if i == HAND_SLOTS else (int(shown[i]) if i < shown.size() else -1)
		if i < HAND_SLOTS:
			_slots[i].visible = i < _places
		var mark := not marked and kind >= 0 and kind == _queued
		marked = marked or mark
		_show_slot(_slots[i], kind, mark)
	hand_bar.visible = not _hand.is_empty() and not hand_hidden
	hand_toggle.visible = not _hand.is_empty()
	hand_toggle.icon = UiIcons.texture("up" if hand_hidden else "down", roundi(40 * _factor * INFO_GROWTH))
	_place.call_deferred()

## Tucks the hand bar away (true) or brings it back.
func set_hand_hidden(hidden: bool) -> void:
	hand_hidden = hidden
	_build_hand()

func _ensure_slots() -> void:
	if _slots.size() == HAND_SLOTS + 1 and _slots[0].custom_minimum_size == _hand_tile:
		return
	_clear(hand_row)
	_slots.clear()
	# Tiles 30 % closer than the default spacing (user, 9 Nov 2026).
	hand_row.add_theme_constant_override("separation", 2)
	for i in HAND_SLOTS + 1:
		if i == HAND_SLOTS:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(18, 0) * _hand_tile.x / TILE.x
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hand_row.add_child(gap)
		var tile := TileButton.new()
		tile.letters = letters
		tile.custom_minimum_size = _hand_tile
		tile.pressed.connect(func() -> void:
			if _discarding and tile.kind >= 0:
				tile_pressed.emit(tile.kind))
		tile.double_pressed.connect(func() -> void:
			if not _discarding and tile.kind >= 0:
				tile_queued.emit(-1 if tile.kind == _queued else tile.kind))
		hand_row.add_child(tile)
		_slots.append(tile)

## Shows `kind` in a slot (-1: an empty slot that keeps its place).
func _show_slot(tile: TileButton, kind: int, queued := false) -> void:
	var enabled := _discarding and kind >= 0
	if tile.kind == kind and tile.enabled == enabled and tile.letters == letters and tile.queued == queued:
		return
	tile.kind = kind
	tile.letters = letters
	tile.enabled = enabled
	tile.queued = queued
	tile.mouse_filter = Control.MOUSE_FILTER_STOP if kind >= 0 else Control.MOUSE_FILTER_IGNORE
	tile.queue_redraw()

## A flat rounded button in `color` (lighter under the mouse, darker when pressed), white text.
func _button(text: String, color: Color, font_size: int, min_size: Vector2, margin := 10.0) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color.lightened(0.15) if state == "hover" else color.darkened(0.2) if state == "pressed" else color
		box.set_corner_radius_all(18)
		box.border_color = BonStyle.RIM
		box.set_border_width_all(4)
		box.anti_aliasing = true
		box.set_content_margin_all(margin)
		button.add_theme_stylebox_override(state, box)
	# White words on blue, dark teal on soft blue (UI art style, 18 Nov 2026).
	var ink: Color = Color.WHITE if color.get_luminance() < 0.6 else BonStyle.INK
	for name in ["font_color", "font_hover_color", "font_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(name, ink)
	button.add_theme_font_size_override("font_size", roundi(font_size * _factor))
	button.custom_minimum_size = min_size * _factor
	button.text = text
	return button

## The big Mahjong! button and the hand's worth under it.
func _build_win_offer(action: Dictionary) -> void:
	var button := _button(_text(action.label), WIN_FILL, 46, Vector2(330, 96), 14.0)
	for state in ["normal", "hover", "pressed"]:
		var box: StyleBoxFlat = button.get_theme_stylebox(state)
		box.border_color = WIN_INK
		box.set_border_width_all(roundi(4 * _factor))
		box.set_corner_radius_all(roundi(22 * _factor))
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = roundi(8 * _factor)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, WIN_INK)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void: action_pressed.emit("win", -1))
	win_offer.add_child(button)
	if action.has("worth"):
		var worth := _label(24, Color.WHITE)
		worth.autowrap_mode = TextServer.AUTOWRAP_OFF
		worth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		worth.add_theme_color_override("font_outline_color", Color("0b1a24"))
		worth.add_theme_constant_override("outline_size", 8)
		worth.text = _text(action.worth)
		_scale_font(worth)
		win_offer.add_child(worth)
	# A gentle pulse around the button's centre; the tween dies with the button.
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	var pulse := button.create_tween().set_loops()
	pulse.tween_property(button, "scale", Vector2.ONE * WIN_PULSE, 0.45).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(button, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)

func _build_actions() -> void:
	_clear(action_row)
	_clear(win_offer)
	win_offer.visible = false
	for action in _actions:
		var id := str(action.id)
		if id == "win":
			_build_win_offer(action)
			win_offer.visible = true
			continue
		var color := PASS if id in ["pass", "keep"] else CALL
		var button := _button(_text(action.label), color, 26, Vector2(120, 64))
		var tiles: Array = action.get("tiles", [])
		if not tiles.is_empty():
			var row := TileStrip.new()
			row.tiles = tiles
			row.letters = letters
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			# Wider and shorter than the hand's tiles (user, 9 Nov 2026).
			var small := Vector2(0.72, 0.72 * 1.22) * TILE.x * _factor
			row.custom_minimum_size = Vector2(small.x * tiles.size(), small.y)
			var box := HBoxContainer.new()
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.alignment = BoxContainer.ALIGNMENT_CENTER
			box.add_theme_constant_override("separation", int(8 * _factor))
			box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var text := Label.new()
			text.text = button.text
			text.add_theme_font_size_override("font_size", roundi(24 * _factor))
			text.add_theme_color_override("font_color", button.get_theme_color("font_color"))
			box.add_child(text)
			box.add_child(row)
			button.text = ""
			button.add_child(box)
			# As wide as the label in either language: holding EN never resizes it.
			var label_width := _widest(action.label, text)
			text.custom_minimum_size.x = label_width
			button.custom_minimum_size = Vector2(row.custom_minimum_size.x + maxf(110 * _factor, label_width + 40 * _factor), small.y + 20 * _factor)
		else:
			_hold_width(button, action.label)
		var data := int(action.get("data", -1))
		button.pressed.connect(func() -> void: action_pressed.emit(id, data))
		action_row.add_child(button)
	action_row.add_theme_constant_override("separation", int(14 * _factor))
	_place.call_deferred()

func _build_result() -> void:
	_clear(result_stack)
	if _result.is_empty():
		return
	var data: Dictionary = _result.data
	var title := _label(34, GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = _text(data.title)
	title.add_theme_font_override("font", BonStyle.font(700))
	# The headline in a cream pill (the money panel's request line).
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var look := BonStyle.flat(TRAY, roundi(40 * _factor), maxi(3, roundi(5 * _factor)))
	look.content_margin_left = 26 * _factor
	look.content_margin_right = 26 * _factor
	look.content_margin_top = 6 * _factor
	look.content_margin_bottom = 6 * _factor
	pill.add_theme_stylebox_override("panel", look)
	pill.add_child(title)
	result_stack.add_child(pill)
	for line in data.get("lines", []):
		var row := _label(23, DIM)
		row.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.text = _text(line)
		result_stack.add_child(row)
	if not data.get("total", {}).is_empty():
		var total := _label(28, GOLD)
		total.autowrap_mode = TextServer.AUTOWRAP_OFF
		total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		total.text = _text(data.total)
		result_stack.add_child(total)
	if not data.get("scores", []).is_empty():
		result_stack.add_child(_scoreboard(data.scores))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", int(16 * _factor))
	result_stack.add_child(buttons)
	for spec in [["again", CALL], ["leave", PASS]]:
		# No "again" after the last hand the session plays (test launcher rounds).
		if (_result[spec[0]] as Dictionary).is_empty():
			continue
		var button := _button(_text(_result[spec[0]]), spec[1], 26, Vector2(190, 64), 12.0)
		_hold_width(button, _result[spec[0]])
		if spec[0] == "again":
			button.pressed.connect(func() -> void: again_pressed.emit())
		else:
			button.pressed.connect(func() -> void: leave_requested.emit())
		buttons.add_child(button)
	for label in result_stack.find_children("*", "Label", true, false):
		_scale_font(label)
	_place.call_deferred()

## This visit's points: a column per player (face, name, total, the last hand's change). No
## heading: the faces and numbers say it (user, 11 Nov 2026).
func _scoreboard(rows: Array) -> Control:
	var board := HBoxContainer.new()
	board.alignment = BoxContainer.ALIGNMENT_CENTER
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_theme_constant_override("separation", int(22 * _factor))
	for row in rows:
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 0)
		var face := Face.new()
		face.texture = portraits.texture(str(row.get("face", ""))) if portraits != null and str(row.get("face", "")) != "" else null
		face.wind = int(row.get("wind", -1))
		face.letters = letters
		face.custom_minimum_size = Vector2(64, 64) * _factor
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(face)
		var name_label := _label(18, DIM)
		name_label.text = _text(row.name)
		var total := _label(28, GOLD)
		total.text = str(row.total)
		var change := _label(18, GAIN if str(row.change).begins_with("+") else LOSS)
		change.text = str(row.change) if str(row.change) != "" else " "
		for label in [name_label, total, change]:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(label)
		board.add_child(column)
	return board

func _build_scores() -> void:
	_clear(score_stack)
	score_stack.add_theme_constant_override("separation", roundi(6 * _factor))
	# The players' columns with the close button in the top-right corner (no heading).
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(14 * _factor))
	score_stack.add_child(head)
	head.add_child(_scoreboard(_scores))
	# A round grey button with a bold white cross, the size of a fingertip (touch UI).
	var side := 52.0 * _factor
	var close := _button("", PASS, 20, Vector2(52, 52), 0.0)
	for state in ["normal", "hover", "pressed"]:
		(close.get_theme_stylebox(state) as StyleBoxFlat).set_corner_radius_all(roundi(side * 0.5))
	close.name = "Close scoreboard"
	close.icon = UiIcons.texture("close", roundi(26 * _factor))
	close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.expand_icon = false
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(func() -> void: show_scores(false))
	head.add_child(close)
	for label in score_stack.find_children("*", "Label", true, false):
		_scale_font(label)
	_place.call_deferred()

## Re-renders every text (the Display Mode or a language changed).
func refresh_display() -> void:
	_build_info()
	if score_card.visible:
		_build_scores()
	translate_button.refresh(show_native, _factor * INFO_GROWTH)
	if visible:
		_build_actions()
		if result_card.visible:
			_build_result()
	_place.call_deferred()

# --- Layout --------------------------------------------------------------------------------

func _rescale() -> void:
	var screen := get_viewport_rect().size if is_inside_tree() else DESIGN
	_factor = minf(screen.y / DESIGN.y, screen.x / DESIGN.x)
	var grown := _factor * INFO_GROWTH
	# Lessons, scoreboard and leave: cream round buttons with dark teal icons (money panel's ✕).
	for button in [lessons_button, score_button, leave_button, hand_toggle]:
		BonStyle.style_button(button, "minor", grown, 22)
		for name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
			button.add_theme_color_override(name, GOLD)
	leave_button.custom_minimum_size = Vector2(56, 56) * grown
	lessons_button.custom_minimum_size = Vector2(56, 56) * grown
	score_button.custom_minimum_size = Vector2(56, 56) * grown
	hand_toggle.custom_minimum_size = Vector2(56, 56) * grown
	score_button.add_theme_font_size_override("font_size", roundi(22 * grown))
	translate_button.refresh(show_native, grown)
	info_card.get_theme_stylebox("panel").set_content_margin_all(10 * grown)
	corner_card.get_theme_stylebox("panel").set_content_margin_all(10 * grown)
	lessons_button.icon = UiIcons.texture("book", roundi(64 * grown))
	score_button.icon = UiIcons.texture("star", roundi(40 * grown))
	leave_button.icon = UiIcons.texture("exit", roundi(64 * grown))
	# The whole bar (14 tiles, 13 gaps of 2, the 18 gap before the drawn tile, the card's
	# margins) at HAND_GROWTH, or as large as fits between the screen's side margins.
	var natural := TILE.x * (HAND_SLOTS + 1) + 2.0 * HAND_SLOTS + 18.0
	var room := (screen.x - 2.0 * 14.0 * _factor - 24.0) / natural
	_hand_tile = (TILE * minf(_factor * HAND_GROWTH, room)).round()
	if visible:
		_build_hand()
		_build_actions()
		_build_result()
		if score_card.visible:
			_build_scores()
	_place.call_deferred()

func _scale_font(label: Label) -> void:
	label.add_theme_font_size_override("font_size", roundi(float(label.get_meta("base_font", 20)) * _factor))

func _place() -> void:
	var screen := get_viewport_rect().size if is_inside_tree() else DESIGN
	var margin := 14.0 * _factor
	# The top centre stays clear for Awoo's face (FACE_CLEAR): the status card ends left of it,
	# the corner card (translate, leave) starts right of it and ends at the HUD's buttons.
	var face_left := screen.x * 0.5 - screen.y * FACE_CLEAR
	var face_right := screen.x * 0.5 + screen.y * FACE_CLEAR
	info_card.reset_size()
	info_card.position = Vector2(margin, margin)
	# Never taller than INFO_MAX_HEIGHT of the screen (about its height at 1280 x 800), so on a
	# phone it stays clear of the far discards (user, 16 Nov 2026: "fit on phone").
	info_card.scale = Vector2.ONE * minf(minf(INFO_MAX_GROW, screen.y * INFO_MAX_HEIGHT / maxf(info_card.size.y, 1.0)),
			(face_left - margin) / maxf(info_card.size.x, 1.0))
	corner_card.reset_size()
	var right := screen.x - margin
	for button in corner_limit:
		if is_instance_valid(button) and button.is_visible_in_tree():
			right = minf(right, button.get_global_rect().position.x - margin)
	corner_card.scale = Vector2.ONE * minf(info_card.scale.x, (right - face_right) / maxf(corner_card.size.x, 1.0))
	corner_card.position = Vector2(right - corner_card.size.x * corner_card.scale.x, margin)
	hand_bar.reset_size()
	hand_bar.position = Vector2((screen.x - hand_bar.size.x) * 0.5, screen.y - hand_bar.size.y - margin)
	# The hide/show button: just above the bar's right end, or in the bottom right corner while
	# the bar is tucked away.
	hand_toggle.reset_size()
	if hand_bar.visible:
		hand_toggle.position = Vector2(hand_bar.position.x + hand_bar.size.x - hand_toggle.size.x, hand_bar.position.y - hand_toggle.size.y - margin * 0.5)
	else:
		hand_toggle.position = screen - hand_toggle.size - Vector2(margin, margin)
	action_row.reset_size()
	var above := hand_bar.position.y if hand_bar.visible else screen.y - margin
	action_row.position = Vector2((screen.x - action_row.size.x) * 0.5, above - action_row.size.y - margin)
	win_offer.reset_size()
	var over := action_row.position.y if not _actions.is_empty() and action_row.get_child_count() > 0 else above
	win_offer.position = Vector2((screen.x - win_offer.size.x) * 0.5, over - win_offer.size.y - margin)
	score_card.reset_size()
	score_card.position = Vector2(margin, info_card.position.y + info_card.size.y * info_card.scale.y + margin)
	result_card.custom_minimum_size.x = 460 * _factor
	result_card.reset_size()
	result_card.position = (screen - result_card.size) * Vector2(0.5, 0.42)

# --- Tiles ---------------------------------------------------------------------------------

## One tile of the player's hand: lifts under the mouse when it can be discarded. Two presses
## within DOUBLE_MS while it cannot be discarded (another player's turn) emit double_pressed;
## a press that discards never starts one, so a quick second click after discarding is not one.
class TileButton extends Control:
	signal pressed
	signal double_pressed
	const DOUBLE_MS := 450
	## The mark of a tile queued to play ahead: lifted, with a pink border and a ▶ badge.
	const QUEUED := Color("ff5f9e")
	var kind := -1   # -1: an empty slot (nothing drawn)
	var letters: Array = []
	var enabled := true
	var queued := false
	var _hover := false
	var _last_press := -1
	var _last_kind := -1
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func() -> void:
			_hover = true
			queue_redraw())
		mouse_exited.connect(func() -> void:
			_hover = false
			queue_redraw())
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			var now := Time.get_ticks_msec()
			if enabled:
				_last_press = -1
			elif _last_press >= 0 and now - _last_press <= DOUBLE_MS and _last_kind == kind:
				_last_press = -1
				double_pressed.emit()
			else:
				_last_press = now
				_last_kind = kind
			pressed.emit()
	func _draw() -> void:
		if kind < 0:
			return
		var lift := size.y * 0.12 if ((_hover and enabled) or queued) else 0.0
		var rect := Rect2(Vector2(1, 0 - lift + size.y * 0.06), size - Vector2(2, size.y * 0.06))
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.9), Vector2(rect.size.x, rect.size.y * 0.12)), Tiles.BACK)
		var face := Rect2(rect.position, rect.size * Vector2(1, 0.94))
		Tiles.draw_face(self, face, kind, letters)
		if queued:
			draw_rect(face, QUEUED, false, maxf(3.0, size.x * 0.06))
			var badge := Vector2(face.end.x - size.x * 0.2, face.position.y + size.x * 0.2)
			var r := size.x * 0.16
			draw_circle(badge, r, QUEUED)
			draw_colored_polygon(PackedVector2Array([badge + Vector2(-r * 0.35, -r * 0.5), badge + Vector2(r * 0.55, 0), badge + Vector2(-r * 0.35, r * 0.5)]), Color.WHITE)
		elif _hover and enabled:
			draw_rect(face, BonStyle.GREEN_BOTTOM, false, 3.0)

## A row of small tiles (on a call button, in the status card). Each keeps a tile's shape
## (height 1.22 × width) and the row is centred, however the strip is stretched.
class TileStrip extends Control:
	var tiles: Array = []
	var letters: Array = []
	func _draw() -> void:
		if tiles.is_empty():
			return
		var w := minf(size.x / tiles.size(), size.y / 1.22)
		var h := w * 1.22
		var start := Vector2((size.x - w * tiles.size()) * 0.5, (size.y - h) * 0.5)
		for i in tiles.size():
			var rect := Rect2(start + Vector2(i * w + 1, 0), Vector2(w - 2, h))
			draw_rect(Rect2(rect.position + Vector2(0, h * 0.06), rect.size), Tiles.BACK)
			Tiles.draw_face(self, Rect2(rect.position, rect.size * Vector2(1, 0.94)), int(tiles[i]), letters)

## A player's face on the scoreboards: their plush portrait (plush_portraits.gd) in a light
## circle, with their seat wind as a small tile badge at the lower right when given.
class Face extends Control:
	## Share of the portrait shown across the circle (1 = all of it) and how far above the
	## picture's centre the circle is centred (share of its height): the head fills the face.
	const ZOOM := 0.66
	const HEAD_UP := -0.05
	## The soft background: a pale mint disc that lightens toward a glow behind the head.
	const BACK_EDGE := Color("cfe7e4")
	const BACK_GLOW := Color("fbf8ef")
	var texture: Texture2D
	var wind := -1
	var letters: Array = []
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var side := minf(size.x, size.y)
		var centre := size * 0.5
		for i in 12:
			var t := i / 11.0
			draw_circle(centre + Vector2(0, -side * 0.08 * t), side * 0.5 * (1.0 - t * 0.7), BACK_EDGE.lerp(BACK_GLOW, t), true, -1.0, true)
		if texture != null:
			# The portrait drawn as a textured disc, so it never spills past the circle, and
			# zoomed in on the head (the middle ZOOM share of the picture, a little above centre).
			var points := PackedVector2Array()
			var uvs := PackedVector2Array()
			var radius := side * 0.5 - maxf(1.5, side * 0.03)
			for i in 48:
				var turn := Vector2.from_angle(TAU * i / 48.0)
				points.append(centre + turn * radius)
				uvs.append(Vector2(0.5, 0.5 + HEAD_UP) + turn * 0.5 * ZOOM)
			draw_colored_polygon(points, Color.WHITE, uvs, texture)
		draw_arc(centre, side * 0.5, 0.0, TAU, 48, BonStyle.RIM, maxf(1.5, side * 0.03), true)
		if wind >= 0:
			var tile := Vector2(0.34, 0.34 * 1.3) * side
			var at := Vector2(size.x * 0.5 + side * 0.5 - tile.x * 0.8, size.y * 0.5 + side * 0.5 - tile.y * 0.85)
			Tiles.draw_face(self, Rect2(at, tile), wind, letters)
