extends Control
## Mei's mahjong lessons (docs/guides/MAHJONG.md#lessons; user, 9 Nov 2026: the approved script
## docs/evidence/mahjong-20261109/LESSON_SCRIPT.md, with pictures, looking cute). Two lessons (tabs
## Basics and Scoring) of pages; each page has a title, a picture drawn from real tile faces
## (mahjong_tiles.gd) and Mei's text in a speech bubble beside her portrait. Back / Next and
## tile-shaped page dots below; the last page's Next says Got it! and closes.
##
## Everything a page shows comes from data: data/mahjong.json "lessons" (pages, text ids and
## the picture of each page) and "points" (the fan -> points table, the discarder paying
## double), and the text from data/phrases.json through the shared Lexicon, so the pages
## follow the language settings. Text ids may mark **bold** words. The panel knows no game
## rules; mahjong_session.gd opens it before a game (Mei's "Do you know how to play?") and
## from the book button on the game screen, and the game waits while it is open.
##
## Scales with min(window height / 800, window width / 1100) like the other minigame screens
## (user decision, 4 Nov 2026); large tap targets, nothing needs hover or a mouse wheel.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const Tiles := preload("res://scripts/ui/mahjong_tiles.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const TranslateButton := preload("res://scripts/ui/translate_button.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const Portraits := preload("res://scripts/ui/plush_portraits.gd")

## Esc and the ✕ (minigame_wiring.gd PANELS) ask to close; `closed` follows once it is hidden.
signal close_requested
signal closed

const DESIGN := Vector2(1100, 800)
## The card, kept below the HUD buttons along the top of the window.
const CARD := Vector2(1000, 690)
const CARD_DROP := 30.0
## Pastel look: a cream card with a pink border, mint picture area, pink and blue pills.
const CREAM := Color("fff8ec")
const PINK := Color("ff8fb8")
const PINK_SOFT := Color("ffd6e5")
const MINT := Color("e3f6ee")
const MINT_EDGE := Color("a8dcc6")
const INK := Color("5b3350")
const INK_SOFT := Color("8a6a80")
const BLUE := Color("8cc8ff")
const SUN := Color("ffd166")
const GOOD := Color("2f9d68")
const BAD := Color("e0475b")
## One colour per call (the 3D pop-up words' outlines, mahjong_session.gd) and per scoring part.
const SET_COLORS := {"chow": Color("3aa6ff"), "pung": Color("ff5f9e"), "kong": Color("9a73ff")}
const PART_COLORS := [Color("ff7eb0"), Color("6cb8ff"), Color("ffb347"), Color("9a73ff")]
## Picture species of the four players (plush_portraits.gd), Mei first.
const HOST_SPECIES := "cat"

var show_native := false
var letters: Array = []
var lesson := 0
var page := 0
var _factor := 1.0
var _lessons: Array = []
var _points: Dictionary = {}

var dim: ColorRect
var card: PanelContainer
var tab_row: HBoxContainer
var translate_button: Button
var close_button: Button
var title_label: Label
var picture: LessonPicture
var portrait: TextureRect
var tail: BubbleTail
var bubble: PanelContainer
var text_room: ScrollContainer
var text_stack: VBoxContainer
var back_button: Button
var next_button: Button
var dots: PageDots
var portraits: Node

func _init() -> void:
	name = "Mahjong lessons"
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var config := Rules.config()
	_lessons = config.get("lessons", [])
	_points = config.get("points", {})
	dim = ColorRect.new()
	dim.color = Color(0.16, 0.08, 0.18, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(CREAM, PINK, 5, 30, 18))
	add_child(card)
	var stack := VBoxContainer.new()
	card.add_child(stack)
	stack.add_theme_constant_override("separation", 8)
	# Top: the two lesson tabs, the translate bubble and the ✕.
	var top := HBoxContainer.new()
	stack.add_child(top)
	tab_row = HBoxContainer.new()
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tab_row)
	translate_button = TranslateButton.new()
	translate_button.pressed.connect(func() -> void:
		show_native = not show_native
		refresh_display())
	top.add_child(translate_button)
	close_button = _icon_button("close", PINK)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	top.add_child(close_button)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", INK)
	title_label.add_theme_color_override("font_outline_color", Color.WHITE)
	stack.add_child(title_label)
	# Middle: the picture on the left, Mei and her speech bubble on the right.
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(body)
	picture = LessonPicture.new()
	picture.panel = self
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(picture)
	var talk := VBoxContainer.new()
	talk.add_theme_constant_override("separation", 0)
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(talk)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	talk.add_child(portrait)
	tail = BubbleTail.new()
	# No speech-bubble point (user, 24 Nov 2026: no triangles on dialogue boxes).
	tail.visible = false
	talk.add_child(tail)
	bubble = PanelContainer.new()
	bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _box(Color.WHITE, PINK_SOFT, 3, 22, 0))
	talk.add_child(bubble)
	# The paragraphs never grow the card: they sit in a scroller with no bar and shrink to fit.
	text_room = ScrollContainer.new()
	text_room.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	text_room.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	text_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(text_room)
	text_stack = VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_room.add_child(text_stack)
	# Bottom: Back, the page dots, Next / Got it!
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(bottom)
	back_button = _button(Color("b9a6c9"))
	back_button.pressed.connect(func() -> void: _turn(-1))
	bottom.add_child(back_button)
	dots = PageDots.new()
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(dots)
	next_button = _button(PINK)
	next_button.pressed.connect(func() -> void: _turn(1))
	bottom.add_child(next_button)
	close_requested.connect(close)
	visible = false
	resized.connect(_rescale)

func _ready() -> void:
	portraits = Portraits.new()
	add_child(portraits)
	get_viewport().size_changed.connect(_rescale)
	_rescale()

## Opens lesson `index` (0 basics, 1 scoring) at its first page; `revealed`: start with the
## translation showing (the dialogue box's state).
func open(index: int, revealed: bool = false) -> void:
	lesson = clampi(index, 0, maxi(_lessons.size() - 1, 0))
	page = 0
	show_native = revealed
	visible = true
	refresh_display()

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _turn(step: int) -> void:
	var pages: Array = _pages()
	if page + step >= pages.size():
		close()
		return
	page = clampi(page + step, 0, pages.size() - 1)
	refresh_display()

func _pages() -> Array:
	return _lessons[lesson].get("pages", []) if lesson < _lessons.size() else []

func current_page() -> Dictionary:
	var pages := _pages()
	return pages[page] if page < pages.size() else {}

# --- Text ----------------------------------------------------------------------------------

## The {"foreign", "native"} line of phrase `id` (values filled in).
func line(id: String, values: Dictionary = {}) -> Dictionary:
	return Lexicon.shared().line(id, values)

## What a short label shows: the foreign text, with the translation after it when revealed.
func label_text(id_or_line: Variant, values: Dictionary = {}) -> String:
	var shown: Dictionary = id_or_line if id_or_line is Dictionary else line(str(id_or_line), values)
	return _plain(GameSettings.shared().inline(shown, show_native))

## **bold** -> [b]bold[/b] for a RichTextLabel.
static func _bbcode(text: String) -> String:
	var parts := text.replace("[", "[lb]").split("**")
	var out := ""
	for i in parts.size():
		out += ("[b]%s[/b]" % parts[i]) if i % 2 == 1 else parts[i]
	return out

static func _plain(text: String) -> String:
	return text.replace("**", "")

## Re-renders every text (opening, a page turn, the Display Mode or a language changed).
func refresh_display() -> void:
	letters = []
	var lexicon = Lexicon.shared()
	for wind in ["e", "s", "w", "n"]:
		letters.append(lexicon.phrase("mahjong.letter_" + wind, lexicon.foreign))
	translate_button.refresh(show_native, _factor)
	if not visible:
		return
	_build_tabs()
	var data := current_page()
	title_label.text = label_text(str(data.get("title", "")))
	_build_text(data.get("text", []))
	var pages := _pages()
	back_button.visible = page > 0
	back_button.text = label_text("mahjong.lesson_back")
	next_button.text = label_text("mahjong.lesson_done" if page >= pages.size() - 1 else "mahjong.lesson_next")
	dots.count = pages.size()
	dots.current = page
	dots.factor = _factor
	dots.queue_redraw()
	if portraits != null:
		portrait.texture = portraits.texture(HOST_SPECIES)
	picture.queue_redraw()
	_fit_text.call_deferred()

func _build_tabs() -> void:
	for child in tab_row.get_children():
		tab_row.remove_child(child)
		child.queue_free()
	tab_row.add_theme_constant_override("separation", roundi(10 * _factor))
	for i in _lessons.size():
		var active := i == lesson
		var tab := _button(PINK if active else Color.WHITE, 22, Vector2(170, 56))
		tab.text = label_text(str(_lessons[i].get("tab", "")))
		if not active:
			for state in ["normal", "hover", "pressed"]:
				var box: StyleBoxFlat = tab.get_theme_stylebox(state)
				box.border_color = PINK
				box.set_border_width_all(roundi(3 * _factor))
			for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
				tab.add_theme_color_override(color_name, INK)
		var index := i
		tab.pressed.connect(func() -> void:
			lesson = index
			page = 0
			refresh_display())
		tab_row.add_child(tab)

## Mei's paragraphs: the foreign text (bold words), its reading (pinyin) under it, and the
## translation in a softer colour when revealed.
func _build_text(ids: Array) -> void:
	for child in text_stack.get_children():
		text_stack.remove_child(child)
		child.queue_free()
	var settings = GameSettings.shared()
	for id in ids:
		var shown: Dictionary = line(str(id))
		var parts: Array = settings.view(shown, show_native)
		var main_text := RichTextLabel.new()
		main_text.bbcode_enabled = true
		main_text.fit_content = true
		main_text.scroll_active = false
		main_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_text.add_theme_color_override("default_color", INK)
		main_text.text = _bbcode(str(parts[0]))
		main_text.set_meta("base_font", 20)
		text_stack.add_child(main_text)
		var reading := PinyinText.style(Label.new())
		reading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reading.add_theme_color_override("font_color", INK_SOFT)
		reading.set_meta("base_font", 15)
		PinyinText.show(reading, {"foreign": _plain(str(shown.foreign)), "native": ""})
		text_stack.add_child(reading)
		if str(parts[1]) != "" and parts[1] != parts[0]:
			var other := RichTextLabel.new()
			other.bbcode_enabled = true
			other.fit_content = true
			other.scroll_active = false
			other.mouse_filter = Control.MOUSE_FILTER_IGNORE
			other.add_theme_color_override("default_color", Color("4f8f7a"))
			other.text = "[i]%s[/i]" % _bbcode(str(parts[1]))
			other.set_meta("base_font", 17)
			text_stack.add_child(other)

## Shrinks the paragraphs' font until they fit the bubble (long Spanish, pinyin under Chinese),
## so the page never needs a scroll bar (AGENTS.md).
func _fit_text() -> void:
	await get_tree().process_frame
	var room := text_room.size.y
	if room <= 0.0 or not visible:
		return
	for shrink in [1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.66]:
		var height := 0.0
		for child in text_stack.get_children():
			var font_size := roundi(float(child.get_meta("base_font", 20)) * _factor * shrink)
			if child is RichTextLabel:
				for kind in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
					child.add_theme_font_size_override(kind, font_size)
				height += child.get_content_height()
			elif child is Label and child.visible:
				child.add_theme_font_size_override("font_size", font_size)
				height += child.get_minimum_size().y
		var shown := text_stack.get_children().filter(func(child) -> bool: return child.visible).size()
		height += text_stack.get_theme_constant("separation") * maxi(shown - 1, 0)
		if height <= room:
			break

# --- Layout --------------------------------------------------------------------------------

func _rescale() -> void:
	var screen := get_viewport_rect().size if is_inside_tree() else DESIGN
	_factor = minf(screen.y / DESIGN.y, screen.x / DESIGN.x)
	card.add_theme_stylebox_override("panel", _box(CREAM, PINK, 5, 30, 18))
	card.custom_minimum_size = CARD * _factor
	card.size = CARD * _factor
	card.position = (screen - card.size) * 0.5 + Vector2(0, CARD_DROP * _factor)
	title_label.add_theme_font_size_override("font_size", roundi(34 * _factor))
	title_label.add_theme_constant_override("outline_size", roundi(8 * _factor))
	picture.custom_minimum_size = Vector2(510, 0) * _factor
	portrait.custom_minimum_size = Vector2(104, 104) * _factor
	tail.custom_minimum_size = Vector2(0, 14) * _factor
	tail.factor = _factor
	bubble.add_theme_stylebox_override("panel", _box(Color.WHITE, PINK_SOFT, 3, 22, 14))
	text_stack.add_theme_constant_override("separation", roundi(6 * _factor))
	close_button.custom_minimum_size = Vector2(56, 56) * _factor
	close_button.icon = UiIcons.texture("close", roundi(34 * _factor))
	for button in [back_button, next_button]:
		_style_button(button, button.get_meta("color"), 24, Vector2(190, 62))
	refresh_display()

func _box(fill: Color, edge: Color, border: float, radius: float, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(roundi(border * _factor))
	box.set_corner_radius_all(roundi(radius * _factor))
	box.set_content_margin_all(margin * _factor)
	if fill == CREAM:
		box.shadow_color = Color(0.3, 0.1, 0.25, 0.3)
		box.shadow_size = roundi(14 * _factor)
	return box

func _button(color: Color, font_size: int = 24, min_size: Vector2 = Vector2(190, 62)) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("color", color)
	_style_button(button, color, font_size, min_size)
	return button

## Rounded pill in `color` (lighter under the mouse, darker pressed), white bold text.
func _style_button(button: Button, color: Color, font_size: int, min_size: Vector2) -> void:
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color.lightened(0.12) if state == "hover" else color.darkened(0.12) if state == "pressed" else color
		box.set_corner_radius_all(roundi(min_size.y * 0.5 * _factor))
		box.set_content_margin_all(10 * _factor)
		box.shadow_color = Color(0.3, 0.1, 0.25, 0.18)
		box.shadow_size = roundi(4 * _factor)
		box.shadow_offset = Vector2(0, 3) * _factor
		button.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, Color.WHITE)
	button.add_theme_font_size_override("font_size", roundi(font_size * _factor))
	button.custom_minimum_size = min_size * _factor

func _icon_button(icon: String, color: Color) -> Button:
	var button := _button(color, 24, Vector2(56, 56))
	button.icon = UiIcons.texture(icon, 34)
	button.expand_icon = false
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button

# --- Points (lesson 2, page 3) ---------------------------------------------------------------

## Points for a hand of `fan` (mahjong_rules.gd, shared with the session's scoreboard).
func points_for(fan: int) -> int:
	return Rules.points_for(fan)

## Each player's balance after `hands` ([{"winner", "from" (-1 self-drawn), "fan"}]).
func balances(hands: Array) -> Array:
	return Rules.balances(hands)

## Mini tiles, pills and portraits drawn into the picture area. Coordinates are in design
## pixels (540 wide) scaled by the panel's factor.
class LessonPicture extends Control:
	var panel
	var _font: Font
	var f := 1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_font = ThemeDB.fallback_font

	func _draw() -> void:
		if panel == null:
			return
		f = panel._factor
		var area := Rect2(Vector2(6, 4) * f, size - Vector2(12, 8) * f)
		var back := StyleBoxFlat.new()
		back.bg_color = MINT
		back.border_color = MINT_EDGE
		back.set_border_width_all(roundi(3 * f))
		back.set_corner_radius_all(roundi(24 * f))
		draw_style_box(back, area)
		_sparkle(area.position + Vector2(22, 22) * f, 9 * f, SUN)
		_sparkle(area.end - Vector2(24, 24) * f, 7 * f, PINK)
		_sparkle(Vector2(area.end.x - 30 * f, area.position.y + 26 * f), 6 * f, BLUE)
		var pic: Dictionary = panel.current_page().get("picture", {})
		var inner := area.grow(-24 * f)
		match str(pic.get("type", "")):
			"rows": _rows(inner, pic)
			"groups": _groups(inner, pic)
			"sets": _sets(inner, pic)
			"card": _card(inner, pic)
			"worked": _worked(inner, pic)
			"balances": _balances(inner, pic)

	# Building blocks -------------------------------------------------------------------------

	func _tile(rect: Rect2, kind: int) -> void:
		var depth := rect.size.y * 0.07
		_round(Rect2(rect.position + Vector2(0, depth), rect.size), rect.size.x * 0.14, Tiles.BACK)
		if kind < 0:
			Tiles.draw_back(self, Rect2(rect.position, rect.size))
		else:
			Tiles.draw_face(self, Rect2(rect.position, rect.size - Vector2(0, depth)), kind, panel.letters)

	## Tiles left to right from `at` (top left); returns the right edge.
	func _tiles(at: Vector2, kinds: Array, w: float, gap: float = 2.0) -> float:
		var x := at.x
		for kind in kinds:
			_tile(Rect2(Vector2(x, at.y), Vector2(w, w * 1.3)), int(kind))
			x += w + gap * f
		return x - gap * f

	func _round(rect: Rect2, radius: float, color: Color) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(roundi(radius))
		draw_style_box(box, rect)

	## A rounded label; the text shrinks to fit `max_width`. Returns its rect.
	func _pill(center: Vector2, text: String, fill: Color, ink: Color, font_size: float, max_width: float = 0.0) -> Rect2:
		var px := roundi(font_size * f)
		var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		if max_width > 0.0:
			while width > max_width - 20 * f and px > 9:
				px -= 1
				width = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var rect := Rect2(center - Vector2(width * 0.5 + 12 * f, px * 0.75 + 5 * f), Vector2(width + 24 * f, px * 1.5 + 10 * f))
		_round(rect, rect.size.y * 0.5, fill)
		_text(Vector2(rect.position.x + 12 * f, center.y), text, px, ink)
		return rect

	## Text whose vertical middle is at `left_middle.y`.
	func _text(left_middle: Vector2, text: String, px: int, ink: Color) -> void:
		var base := left_middle.y + (_font.get_ascent(px) - _font.get_descent(px)) * 0.5
		draw_string(_font, Vector2(left_middle.x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)

	func _text_center(center: Vector2, text: String, px: int, ink: Color) -> void:
		var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		_text(Vector2(center.x - width * 0.5, center.y), text, px, ink)

	## A four-pointed sparkle.
	func _sparkle(center: Vector2, r: float, color: Color) -> void:
		var points := PackedVector2Array()
		for i in 8:
			var angle := i * PI / 4.0
			var reach := r if i % 2 == 0 else r * 0.32
			points.append(center + Vector2(sin(angle), -cos(angle)) * reach)
		draw_colored_polygon(points, color)

	func _arrow(from: Vector2, to: Vector2, color: Color) -> void:
		draw_line(from, to, color, 4 * f, true)
		var dir := (to - from).normalized()
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([to + dir * 6 * f, to - dir * 8 * f + side * 8 * f, to - dir * 8 * f - side * 8 * f]), color)

	# Lesson 1 ----------------------------------------------------------------------------------

	## The tiles: one row per suit with its name.
	func _rows(area: Rect2, pic: Dictionary) -> void:
		var rows: Array = pic.get("rows", [])
		var label_w := 120 * f
		var w := minf((area.size.x - label_w - 10 * f) / 9.0 - 3 * f, 44 * f)
		var step := area.size.y / rows.size()
		var colors := [PINK_SOFT, Color("d6ecff"), Color("d9f2dd"), Color("ffeccc")]
		for i in rows.size():
			var row: Dictionary = rows[i]
			var y := area.position.y + step * i + (step - w * 1.3) * 0.5
			_pill(Vector2(area.position.x + label_w * 0.5, y + w * 0.65), panel.label_text(str(row.label)), colors[i % colors.size()], INK, 19, label_w)
			_tiles(Vector2(area.position.x + label_w + 10 * f, y), row.tiles, w, 3)

	## Four sets and a pair, each labelled, and draw one -> discard one under them.
	func _groups(area: Rect2, pic: Dictionary) -> void:
		var groups: Array = pic.get("groups", [])
		var w := 46 * f
		var h := w * 1.3
		var lines := [groups.slice(0, 3), groups.slice(3)]
		var y := area.position.y + 8 * f
		for row in lines:
			var widths: Array = row.map(func(g) -> float: return g.tiles.size() * (w + 2 * f))
			var total: float = widths.reduce(func(a, b): return a + b, 0.0) + (row.size() - 1) * 26 * f
			var x := area.position.x + (area.size.x - total) * 0.5
			for i in row.size():
				var group: Dictionary = row[i]
				var right := _tiles(Vector2(x, y), group.tiles, w)
				var is_pair: bool = group.tiles.size() == 2
				_pill(Vector2((x + right) * 0.5, y + h + 24 * f), panel.label_text(str(group.label)), PINK if is_pair else BLUE, Color.WHITE, 18, right - x + 20 * f)
				x = right + 26 * f + 2 * f
			y += h + 64 * f
		# Draw one, throw one away.
		var flow: Array = pic.get("flow", [])
		if flow.size() >= 2:
			var mid := area.position.x + area.size.x * 0.5
			var row_y := area.end.y - 70 * f
			var tw := 40 * f
			_tile(Rect2(Vector2(mid - 190 * f, row_y - tw * 0.65), Vector2(tw, tw * 1.3)), -1)
			_arrow(Vector2(mid - 140 * f, row_y), Vector2(mid - 104 * f, row_y), INK_SOFT)
			_pill(Vector2(mid - 50 * f, row_y), panel.label_text(str(flow[0])), SUN, INK, 19, 120 * f)
			_tile(Rect2(Vector2(mid + 30 * f, row_y - tw * 0.65), Vector2(tw, tw * 1.3)), 13)
			_arrow(Vector2(mid + 80 * f, row_y), Vector2(mid + 116 * f, row_y), INK_SOFT)
			_pill(Vector2(mid + 176 * f, row_y), panel.label_text(str(flow[1])), PINK_SOFT, INK, 19, 130 * f)

	## Chow, pung, kong: the set, its name and a little table showing who you can take it from.
	func _sets(area: Rect2, pic: Dictionary) -> void:
		var sets: Array = pic.get("sets", [])
		var step := area.size.y / sets.size()
		var w := 44 * f
		for i in sets.size():
			var spec: Dictionary = sets[i]
			var top := area.position.y + step * i
			var mid_y := top + step * 0.5
			var kind := str(spec.name).trim_prefix("mahjong.btn_")
			var color: Color = SET_COLORS.get(kind, PINK)
			_pill(Vector2(area.position.x + 50 * f, mid_y - 22 * f), panel.label_text(str(spec.name)) + "!", color, Color.WHITE, 22, 104 * f)
			var right := _tiles(Vector2(area.position.x + 110 * f, mid_y - w * 0.85), spec.tiles, w)
			if bool(spec.get("extra", false)):
				_text(Vector2(right + 6 * f, mid_y - w * 0.2), "+", roundi(24 * f), INK)
				_tile(Rect2(Vector2(right + 22 * f, mid_y - w * 0.6), Vector2(w * 0.7, w * 0.91)), -1)
			_pill(Vector2(area.position.x + 110 * f + 2.2 * w, mid_y + w * 0.75), panel.label_text(str(spec.note)), Color.WHITE, INK, 17, 4.6 * w)
			_seat_map(Vector2(area.end.x - 50 * f, mid_y), str(spec.from), color)

	## A small table seen from above: you at the bottom, the player before you on the left.
	func _seat_map(center: Vector2, from: String, color: Color) -> void:
		var half := 26 * f
		_round(Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0), 8 * f, Color("6fc7a1"))
		var seats := {"you": Vector2(0, 1), "before": Vector2(-1, 0), "across": Vector2(0, -1), "after": Vector2(1, 0)}
		for seat in seats:
			var at: Vector2 = center + seats[seat] * (half + 13 * f)
			var giving: bool = seat == "before" or (from == "anyone" and seat != "you")
			var fill: Color = INK if seat == "you" else (color if giving else Color("d9d0d8"))
			draw_circle(at, 10 * f, fill)
			if giving:
				_arrow(at + (center - at) * 0.3, center + seats["you"] * half * 0.4 + (at - center) * 0.15, color.darkened(0.15))

	# Lesson 2 ----------------------------------------------------------------------------------

	## The scoring card: mini tiles, the hand's name and its fan in a sun badge.
	func _card(area: Rect2, pic: Dictionary) -> void:
		var rows: Array = pic.get("rows", [])
		var fans: Dictionary = Rules.config().get("fan", {})
		var step := area.size.y / rows.size()
		var w := minf(step * 0.62, 30 * f)
		for i in rows.size():
			var row: Dictionary = rows[i]
			var mid_y := area.position.y + step * (i + 0.5)
			if i % 2 == 0:
				_round(Rect2(Vector2(area.position.x - 8 * f, mid_y - step * 0.5 + 1), Vector2(area.size.x + 16 * f, step - 2)), 10 * f, Color(1, 1, 1, 0.55))
			_tiles(Vector2(area.position.x, mid_y - w * 0.65), row.tiles, w, 1)
			var names: Array = row.get("names", []).map(func(id) -> String: return panel.label_text(str(id)))
			var px := roundi(minf(19.0, step * 0.42 / f) * f)
			var text := " · ".join(names)
			var room := area.size.x - 4 * (w + f) - 64 * f
			var text_x := area.position.x + 4 * (w + f) + 14 * f
			if names.size() > 1 and _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > room:
				# Two names on two lines (seat wind, round wind).
				var small := roundi(px * 0.82)
				_text(Vector2(text_x, mid_y - small * 0.62), str(names[0]), small, INK)
				_text(Vector2(text_x, mid_y + small * 0.62), str(names[1]), small, INK)
			else:
				while _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > room and px > 9:
					px -= 1
				_text(Vector2(text_x, mid_y), text, px, INK)
			var fan := int(fans.get(str(row.fan), 0))
			var badge := ("+%d" % fan) if bool(row.get("bonus", false)) else str(fan)
			var center := Vector2(area.end.x - 22 * f, mid_y)
			draw_circle(center, minf(step * 0.42, 20 * f), SUN if not bool(row.get("bonus", false)) else PINK_SOFT)
			_text_center(center, badge, roundi(minf(step * 0.4, 19 * f)), INK)

	## Two winning hands with a coloured bar under each part that scores, the parts named in
	## their colours (wrapping, centred) and the sum.
	func _worked(area: Rect2, pic: Dictionary) -> void:
		var examples: Array = pic.get("examples", [])
		var fans: Dictionary = Rules.config().get("fan", {})
		var step := area.size.y / examples.size()
		var w := minf((area.size.x - 4 * 8 * f) / 14.0 - 2 * f, 34 * f)
		for e in examples.size():
			var example: Dictionary = examples[e]
			var y := area.position.y + step * e + 10 * f
			_pill(Vector2(area.position.x + area.size.x * 0.5, y), panel.label_text(str(example.chip)), Color.WHITE, INK, 16, area.size.x)
			y += 20 * f
			# The hand, its groups apart.
			var spans: Array = []
			var x := area.position.x + (area.size.x - (14 * (w + 2 * f) + 4 * 8 * f)) * 0.5
			for group in example.groups:
				var right := _tiles(Vector2(x, y), group, w)
				spans.append([x, right])
				x = right + 10 * f
			y += w * 1.3 + 8 * f
			# A bar per scoring part under the groups it covers (self-drawn covers none).
			var labels: Array = []
			var sum: Array = []
			for p in example.parts.size():
				var part: Dictionary = example.parts[p]
				var color: Color = PART_COLORS[p % PART_COLORS.size()]
				var groups: Array = part.groups
				if not groups.is_empty():
					var from: float = spans[int(groups[0])][0]
					var to: float = spans[int(groups[groups.size() - 1])][1]
					_round(Rect2(Vector2(from, y + p * 8 * f), Vector2(to - from, 5 * f)), 3 * f, color)
				var fan := int(fans.get(str(part.fan), 0))
				sum.append(str(fan))
				labels.append(["%s +%d" % [panel.label_text("mahjong.hand_" + str(part.fan)), fan], color])
			var total := 0
			for n in sum:
				total += int(n)
			# The sum joins the last row of parts, in sunny yellow.
			labels.append([panel.label_text("mahjong.l_fan_sum", {"sum": " + ".join(sum), "total": total}), SUN, INK])
			_pill_rows(area, y + example.parts.size() * 8 * f + 20 * f, labels, 16)

	## Coloured pills ([text, colour, ink (default white)]) in centred rows that wrap inside `area`, the first row's
	## middle at `y`; returns the last row's middle.
	func _pill_rows(area: Rect2, y: float, labels: Array, font_size: int) -> float:
		var px := roundi(font_size * f)
		var gap := 6 * f
		var rows: Array = [[]]
		var widths: Array = [0.0]
		for label in labels:
			var width := _font.get_string_size(str(label[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + 24 * f
			if not rows[-1].is_empty() and widths[-1] + gap + width > area.size.x:
				rows.append([])
				widths.append(0.0)
			widths[-1] += (gap if not rows[-1].is_empty() else 0.0) + width
			rows[-1].append([label, width])
		for r in rows.size():
			var x := area.position.x + (area.size.x - float(widths[r])) * 0.5
			for item in rows[r]:
				var width: float = item[1]
				var ink: Color = item[0][2] if item[0].size() > 2 else Color.WHITE
				_pill(Vector2(x + width * 0.5, y), str(item[0][0]), item[0][1], ink, font_size, area.size.x)
				x += width + gap
			if r < rows.size() - 1:
				y += px * 1.5 + 16 * f
		return y

	## Balances: everyone at 0, the fan -> points table, the two hands, the balances after.
	func _balances(area: Rect2, pic: Dictionary) -> void:
		var players: Array = pic.get("players", [])
		var hands: Array = pic.get("hands", [])
		var x0 := area.position.x
		var mid := x0 + area.size.x * 0.5
		var y := area.position.y + 10 * f
		_pill(Vector2(mid, y), panel.label_text("mahjong.l_start"), Color.WHITE, INK, 17, area.size.x)
		_players(Rect2(Vector2(x0, y + 16 * f), Vector2(area.size.x, 70 * f)), players, [0, 0, 0, 0])
		y += 122 * f
		# Fan -> points, two rows of five.
		var table: Array = panel._points.get("table", [])
		_pill(Vector2(mid, y), panel.label_text("mahjong.l_points_table"), SUN, INK, 18, area.size.x)
		y += 20 * f
		var cell := Vector2(area.size.x / 5.0, 29 * f)
		for i in table.size():
			var at := Vector2(x0 + cell.x * (i % 5), y + cell.y * int(i / 5))
			_round(Rect2(at + Vector2(3, 2) * f, cell - Vector2(6, 4) * f), 10 * f, Color(1, 1, 1, 0.8))
			_text_center(at + cell * 0.5, "%d → %d" % [int(table[i][0]), int(table[i][1])], roundi(17 * f), INK)
		y += cell.y * ceili(table.size() / 5.0) + 22 * f
		# The two hands.
		var shown: Array = []
		for hand in hands:
			shown.append({"winner": int(hand.winner), "from": int(hand.from), "fan": int(hand.fan)})
			_pill(Vector2(mid, y), panel.label_text(str(hand.text)), PINK_SOFT, INK, 17, area.size.x)
			y += 36 * f
		y += 4 * f
		_pill(Vector2(mid, y), panel.label_text("mahjong.l_after_two"), Color.WHITE, INK, 17, area.size.x)
		_players(Rect2(Vector2(x0, y + 16 * f), Vector2(area.size.x, 70 * f)), players, panel.balances(shown))

	## Four portraits with their names and balances.
	func _players(rect: Rect2, players: Array, money: Array) -> void:
		var step := rect.size.x / players.size()
		for i in players.size():
			var center := Vector2(rect.position.x + step * (i + 0.5), rect.position.y + 28 * f)
			draw_circle(center, 26 * f, Color.WHITE)
			var texture: Texture2D = panel.portraits.texture(str(players[i][0])) if panel.portraits != null else null
			if texture != null:
				draw_texture_rect(texture, Rect2(center - Vector2(26, 26) * f, Vector2(52, 52) * f), false)
			var value := int(money[i])
			var text := ("+%d" % value) if value > 0 else str(value).replace("-", "−")
			var color := GOOD if value > 0 else BAD if value < 0 else INK
			_text_center(Vector2(center.x, center.y + 40 * f), "%s %s" % [panel.label_text(str(players[i][1])), text], roundi(17 * f), color)

## Page dots shaped like little tiles: the current page is a face-up pink tile.
class PageDots extends Control:
	var count := 0
	var current := 0
	var factor := 1.0
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w := 22 * factor
		var h := 29 * factor
		var gap := 12 * factor
		var x := (size.x - count * w - (count - 1) * gap) * 0.5
		for i in count:
			var rect := Rect2(Vector2(x + i * (w + gap), (size.y - h) * 0.5), Vector2(w, h))
			var box := StyleBoxFlat.new()
			box.set_corner_radius_all(roundi(5 * factor))
			box.bg_color = PINK if i == current else Color("cfe9dc")
			box.border_color = Color.WHITE
			box.set_border_width_all(roundi(2 * factor))
			draw_style_box(box, rect)

## The speech bubble's point, up toward Mei's portrait (drawn over the bubble's edge).
class BubbleTail extends Control:
	var factor := 1.0
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 1
	func _draw() -> void:
		var f := factor
		var tip := Vector2(52 * f, 0)
		var left := Vector2(40 * f, size.y + 4 * f)
		var right := Vector2(70 * f, size.y + 4 * f)
		draw_colored_polygon(PackedVector2Array([tip, right, left]), Color.WHITE)
		draw_line(left + Vector2(0, -4 * f), tip, PINK_SOFT, 3 * f, true)
		draw_line(tip, right + Vector2(0, -4 * f), PINK_SOFT, 3 * f, true)
