extends VBoxContainer
## The vocabulary journal's sticker book: the Places tab (25 Nov 2026; approved design and every
## rule: docs/guides/JOURNAL.md, which replaced the table of the vocabulary book of 8 Nov 2026,
## in git history). The HUD (vocabulary_hud.gd) owns the journal window and its header (icon,
## title, the full total with its bar, ✕) and puts this book's search field and ★ Pocket button in
## that header; this panel shows the album:
##   contents: one card per place (data/zones.json) with "12 of 28" and a bar, plus Around town
##             (words in AROUND_TOWN_PLACES or more places) and ★ Pocket (the saved words);
##   chapter:  a two-page spread of PER_PAGE stickers a page, big page arrows and a swipe; a found
##             word shows its picture and foreign word (a tap flips it to the native word, a second
##             tap opens the word page), a word not found yet a soft silhouette with "?";
##   word page: big picture, word, translation, speaker, ★, the places it is found in, and
##             Details (today's right / wrong / translated tiles and per-game table).
## Chapters come from the baked place index data/journal_places.json (tools/vocabulary_report.gd
## -- --write), so they are complete on the web before buildings load; only findable words count.
## Found = in the studied list (Main's studied_words: the word card was opened) or answered in a
## minigame (the practice log of the language being learned); nothing here records or saves.
## Layout scales with min(height / 800, width / 1100) (apply_scale); stickers and cards are placed
## by hand inside each page, sized from the page, so the spread fits any window.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const Sound := preload("res://scripts/core/sound.gd")
const WordPictures := preload("res://scripts/ui/word_pictures.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const WordMemory := preload("res://scripts/learning/word_memory.gd")

const PLACE_INDEX := "res://data/journal_places.json"
## A word found in this many places or more has its own Around town chapter (user, 25 Nov 2026)
## and is left out of the place chapters and their counts.
const AROUND_TOWN_PLACES := 4
const AROUND := "around_town"
const POCKET := "pocket"
const SEARCH := "search"
## Stickers per page (two pages a spread: 8; user, 25 Nov 2026) and contents cards per page.
const PER_PAGE := 4
const CARD_COLUMNS := 3
const CARD_ROWS := 3
## A drag this long (design px) sideways turns the page.
const SWIPE := 70.0
## Finger-sized buttons and readable text on a landscape phone, where the window scale is about
## 0.5 (touch UI, AGENTS.md): no button under TAP px high, no text under MIN_TEXT px.
const TAP := 44.0
const MIN_TEXT := 11
## Line icons of the contents cards (ui_icons.gd) until places get drawn icons; "map" otherwise.
const PLACE_ICONS := {
	AROUND: "map", POCKET: "star", "supermarket": "cart", "library": "book", "police": "police",
	"home": "door", "airport": "takeoff", "control_tower": "radar", "school": "pencil",
	"hospital": "plus", "bank": "money", "bakery": "cloche", "fine_dining": "cloche",
	"burger": "cloche", "taqueria": "cloche", "electronics": "screen", "clothing": "person",
	"warehouse": "lift", "mystery_house": "question", "church": "bell", "farm": "sun",
	"central_park": "sun", "zoo": "look", "playground": "play", "sports": "play",
	"furniture": "box", "town_road": "map", "coast": "moon", "gazebo": "sun",
}
const GOLD := Color("e9a91f")
const TEXT := Color("3d5560")
const DIM := Color("a5b3b6")
const RIGHT := Color("3f9a35")
const WRONG := Color("d0523f")
const TRANSLATED := Color("4f86b0")
## Album colours (UI_STYLE palette): cream pages, white stickers, a cream-deep empty slot.
const PAGE := BonStyle.CREAM
const STICKER := BonStyle.RIM
const SLOT := BonStyle.CREAM_DEEP
## The known daisy on a found sticker's picture (square, at scale 1; decision D9, LEARN-04).
const KNOWN_BADGE := 24.0
## A word not found yet: its picture as a flat soft shape (colour removed).
const SILHOUETTE_SHADER := "shader_type canvas_item;\nuniform vec4 tint : source_color = vec4(0.48, 0.60, 0.64, 0.5);\nvoid fragment() {\n\tCOLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);\n}\n"

## A star was pressed (word page): the HUD toggles and saves the bookmark, then calls refresh_rows().
signal bookmark_toggled(word_key: String)

# Data from the HUD (render_journal).
var studied: Dictionary = {}
## Found words: studied, or recorded in the practice log in the language being learned (set_data).
var found_words: Dictionary = {}
var dictionary: Dictionary = {}
var categories: Dictionary = {}
var areas: Dictionary = {}
var area_names: Dictionary = {}
var bookmarks: Dictionary = {}

## Word key -> place ids, from PLACE_INDEX (read once; live areas when the file is missing).
static var _index: Dictionary = {}
## Words only games find (no click studies them): the word page says "Found in a game at".
static var _from_games: Dictionary = {}
## key -> {foreign, native, search}: the findable words of the dictionary (set_data()).
var words: Dictionary = {}
## Chapter id (zone id, AROUND) -> sorted word keys; places in chapter_order.
var chapters: Dictionary = {}
var chapter_order: Array = []
var total_words := 0
var total_found := 0

# View state (kept while the journal is closed).
## "contents", "chapter" or "word".
var view := "contents"
var chapter := ""
## Spread index (two pages) of the contents or the chapter.
var page := 0
var contents_page := 0
var detail_key := ""
var details_open := false
var query := ""
## The view under the search results, restored when the field is cleared.
var _before_search: Array = []
## The sticker turned to its native word (one at a time).
var flipped_key := ""
var factor := 1.0
## Keyboard play: the footer also names the ← → keys and Hold L (the HUD's key hints switch it
## off on a touch and on again on a key press, set_keyboard_hints).
var keyboard_hints := not DisplayServer.is_touchscreen_available()

# Nodes.
var search: LineEdit
var pocket_button: Button
var back_button: Button
var title_label: Label
var count_label: Label
var top_row: HBoxContainer
var prev_button: Button
var next_button: Button
var spread: PanelContainer
var pages_box: HBoxContainer
var left_page: Control
var right_page: Control
var crease: Control
var empty_label: Label
var footer: HBoxContainer
var page_label: Label
## The HUD's view hint (right of the footer).
var hint: Label
var stickers: Array = []
var cards: Array = []
var silhouette: ShaderMaterial
## [button, kind] of the buttons styled with style_button(), restyled at each window scale.
var styled_buttons: Array = []
# Word page.
var detail: HBoxContainer
## The word page's right side scrolls (drag or bar) when it is taller than the page: Details on a
## landscape phone, or a word tested by many games.
var detail_scroll: ScrollContainer
var detail_picture: TextureRect
var detail_tag: Label
var detail_foreign: Label
var detail_reading: Label
var detail_native: Label
var detail_speaker: Button
var detail_star: Button
var found_heading: Label
var found_places: HFlowContainer
var details_button: Button
var details_box: VBoxContainer
var detail_tiles: HBoxContainer
var detail_games: GridContainer
var detail_empty: Label
var detail_hint: Label
# Swipe.
var _press_at := Vector2.ZERO
var _pressing := false
var _swiped := false

func _init() -> void:
	name = "Vocabulary book"
	theme = BonStyle.theme()
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	silhouette = ShaderMaterial.new()
	silhouette.shader = Shader.new()
	silhouette.shader.code = SILHOUETTE_SHADER
	# Header tools the HUD places in its header row.
	search = LineEdit.new()
	search.name = "Search"
	search.clear_button_enabled = true
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(set_query)
	pocket_button = _button(func() -> void: open_chapter(POCKET))
	pocket_button.name = "Pocket"
	pocket_button.toggle_mode = true
	style_button(pocket_button, "plain")
	pocket_button.set_meta("icon_color", GOLD)
	# Row 1: back to the contents, the chapter's name and count.
	top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_row)
	back_button = _button(go_back)
	back_button.name = "Back"
	style_button(back_button, "plain")
	top_row.add_child(back_button)
	title_label = Label.new()
	title_label.add_theme_font_override("font", BonStyle.font(700))
	title_label.add_theme_color_override("font_color", BonStyle.INK)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_label)
	count_label = Label.new()
	count_label.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(count_label)
	# Row 2: ‹ the album spread ›.
	var spread_row := HBoxContainer.new()
	spread_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spread_row)
	prev_button = _arrow("arrow_left", -1)
	spread_row.add_child(prev_button)
	spread = PanelContainer.new()
	spread.name = "Spread"
	spread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spread.mouse_filter = Control.MOUSE_FILTER_STOP
	spread.add_theme_stylebox_override("panel", BonStyle.flat(PAGE, 26, 6))
	spread.gui_input.connect(_on_drag)
	spread_row.add_child(spread)
	next_button = _arrow("arrow_right", 1)
	spread_row.add_child(next_button)
	pages_box = HBoxContainer.new()
	pages_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pages_box.add_theme_constant_override("separation", 0)
	spread.add_child(pages_box)
	left_page = _page("Left page")
	pages_box.add_child(left_page)
	crease = Fold.new()
	pages_box.add_child(crease)
	right_page = _page("Right page")
	pages_box.add_child(right_page)
	empty_label = Label.new()
	empty_label.name = "Empty note"
	empty_label.visible = false
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	spread.add_child(empty_label)
	_build_detail()
	# Row 3: hint and the page number.
	footer = HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	hint = Label.new()
	hint.name = "Hint"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	hint.clip_text = true
	hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(hint)
	page_label = Label.new()
	page_label.name = "Page number"
	page_label.add_theme_color_override("font_color", BonStyle.BROWN)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(page_label)
	for i in PER_PAGE * 2:
		var sticker := _make_sticker(i)
		(left_page if i < PER_PAGE else right_page).add_child(sticker)
		stickers.append(sticker)
	for i in CARD_COLUMNS * CARD_ROWS * 2:
		var card := _make_card(i)
		(left_page if i < CARD_COLUMNS * CARD_ROWS else right_page).add_child(card)
		cards.append(card)
	# The pages are fit left then right, so the right one's resize sees both new sizes.
	right_page.resized.connect(_place_items)

func _ready() -> void:
	# Holding L shows every sticker's native word (user, 25 Nov 2026), like the rest of the game.
	GameSettings.shared().peek_changed.connect(func() -> void:
		if is_visible_in_tree():
			_draw_page())

## ← → and Page Up / Page Down turn the spread (on the word page: the next found word). W A S D
## still close the journal (Main, user 10 Nov 2026); a focused search field keeps its arrows.
func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_LEFT, KEY_PAGEUP:
			turn_page(-1)
		KEY_RIGHT, KEY_PAGEDOWN:
			turn_page(1)
		_:
			return
	get_viewport().set_input_as_handled()

func set_keyboard_hints(on: bool) -> void:
	keyboard_hints = on
	if not words.is_empty():
		_draw_hint()

func _page(page_name: String) -> Control:
	var node := Control.new()
	node.name = page_name
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.clip_contents = true
	return node

func _button(handler: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(handler)
	return button

## A big round page arrow (soft blue, INK arrow).
func _arrow(icon: String, step: int) -> Button:
	var button := _button(func() -> void: turn_page(step))
	button.name = "Previous page" if step < 0 else "Next page"
	button.icon = BonStyle.icon_texture(icon, 96)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_button(button, "arrow")
	return button

## The journal's button look (BonStyle). "plain": a soft blue pill that turns green with white
## words when pressed (toggles); "arrow": a round soft button. Restyled at each window scale by
## apply_scale(); the HUD styles its ✕ with it too.
func style_button(button: Button, kind: String) -> void:
	if not styled_buttons.any(func(e: Array) -> bool: return e[0] == button):
		styled_buttons.append([button, kind])
	_style_one(button, kind)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _style_one(button: Button, kind := "plain") -> void:
	var size := 18.0
	if button.has_meta("font_base"):
		size = float(button.get_meta("font_base"))
	BonStyle.style_toggle(button, factor, size)
	button.add_theme_font_size_override("font_size", maxi(roundi(size * factor), MIN_TEXT))
	var pad := 8.0 if kind == "arrow" else 16.0
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var look := button.get_theme_stylebox(state)
		look.content_margin_left = pad * factor
		look.content_margin_right = pad * factor
		look.content_margin_top = (8.0 if kind == "arrow" else 4.0) * factor
		look.content_margin_bottom = (8.0 if kind == "arrow" else 6.0) * factor
	if button.has_meta("icon_color"):
		for name in ["icon_normal_color", "icon_hover_color"]:
			button.add_theme_color_override(name, button.get_meta("icon_color"))
	# Pastel icons (the speaker, the stars) keep their own colours.
	if button.has_meta("own_icon"):
		for name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
			button.add_theme_color_override(name, Color.WHITE)

## One sticker: a white-edged card with the word's picture, a "?" when not found, the word on a
## strip at the bottom and a ★ pin when saved. Reused for every page.
func _make_sticker(index: int) -> Button:
	var sticker := Button.new()
	sticker.name = "Sticker %d" % index
	sticker.focus_mode = Control.FOCUS_NONE
	sticker.mouse_filter = Control.MOUSE_FILTER_STOP
	sticker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sticker.gui_input.connect(_on_drag)
	sticker.pressed.connect(func() -> void: _on_sticker(sticker))
	sticker.resized.connect(func() -> void: sticker.pivot_offset = sticker.size * 0.5)
	var art := TextureRect.new()
	art.name = "Picture"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sticker.add_child(art)
	art.add_child(known_badge())
	var mark := Label.new()
	mark.name = "Mark"
	mark.text = "?"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_override("font", BonStyle.font(700))
	mark.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	sticker.add_child(mark)
	var tag := Label.new()
	tag.name = "Tag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_font_override("font", BonStyle.font(700))
	tag.add_theme_color_override("font_color", BonStyle.INK)
	sticker.add_child(tag)
	var word := Label.new()
	word.name = "Word"
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word.clip_text = true
	word.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	word.add_theme_font_override("font", BonStyle.font(700))
	sticker.add_child(word)
	var pin := TextureRect.new()
	pin.name = "Pin"
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pin.texture = BonStyle.icon_texture("star_on", 96)
	sticker.add_child(pin)
	return sticker

## One contents card: a round icon badge, the place's name, "12 of 28" and a small bar.
func _make_card(index: int) -> Button:
	var card := Button.new()
	card.name = "Card %d" % index
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(_on_drag)
	card.pressed.connect(func() -> void:
		if not _swiped:
			open_chapter(str(card.get_meta("chapter", ""))))
	var badge := Panel.new()
	badge.name = "Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(badge)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.add_child(icon)
	var title := Label.new()
	title.name = "Name"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", BonStyle.font(700))
	title.add_theme_color_override("font_color", BonStyle.INK)
	card.add_child(title)
	var count := Label.new()
	count.name = "Count"
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_color_override("font_color", BonStyle.BROWN)
	card.add_child(count)
	var bar := MiniBar.new()
	bar.name = "Bar"
	card.add_child(bar)
	return card

func _build_detail() -> void:
	detail = HBoxContainer.new()
	detail.name = "Word page"
	detail.visible = false
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spread.add_child(detail)
	# Left page: the big picture (or the word on a tag when it has none).
	var left := CenterContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(left)
	var frame := PanelContainer.new()
	frame.name = "Picture frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", BonStyle.flat(STICKER, 26, 8))
	left.add_child(frame)
	var frame_stack := Control.new()
	frame_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(frame_stack)
	detail_picture = TextureRect.new()
	detail_picture.name = "Picture"
	detail_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame_stack.add_child(detail_picture)
	detail_picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_tag = Label.new()
	detail_tag.name = "Tag"
	detail_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_tag.add_theme_font_override("font", BonStyle.font(700))
	detail_tag.add_theme_color_override("font_color", BonStyle.INK)
	frame_stack.add_child(detail_tag)
	detail_tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var detail_fold := Fold.new()
	detail_fold.name = "Fold"
	detail.add_child(detail_fold)
	# Right page: word, reading, translation, speaker and ★, then Found in or the details.
	detail_scroll = ScrollContainer.new()
	detail_scroll.name = "Word scroll"
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.scroll_deadzone = 8
	detail.add_child(detail_scroll)
	var right := VBoxContainer.new()
	right.name = "Word side"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.mouse_filter = Control.MOUSE_FILTER_PASS
	detail_scroll.add_child(right)
	detail_foreign = Label.new()
	detail_foreign.add_theme_font_override("font", BonStyle.font(700))
	detail_foreign.add_theme_color_override("font_color", BonStyle.INK)
	detail_foreign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(detail_foreign)
	detail_reading = PinyinText.style(Label.new())
	detail_reading.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	right.add_child(detail_reading)
	detail_native = Label.new()
	detail_native.add_theme_color_override("font_color", TEXT)
	detail_native.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(detail_native)
	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(actions)
	detail_speaker = _button(func() -> void: say(detail_key))
	detail_speaker.name = "Say word"
	detail_speaker.icon = BonStyle.icon_texture("speaker", 128)
	detail_speaker.expand_icon = true
	detail_speaker.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_speaker.set_meta("own_icon", true)
	style_button(detail_speaker, "arrow")
	actions.add_child(detail_speaker)
	detail_star = _button(func() -> void: bookmark_toggled.emit(detail_key))
	detail_star.name = "Save word"
	detail_star.expand_icon = true
	detail_star.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_star.set_meta("own_icon", true)
	style_button(detail_star, "arrow")
	actions.add_child(detail_star)
	details_button = _button(func() -> void:
		details_open = not details_open
		_render_detail())
	details_button.name = "Details"
	details_button.toggle_mode = true
	style_button(details_button, "plain")
	actions.add_child(details_button)
	found_heading = Label.new()
	found_heading.add_theme_font_override("font", BonStyle.font(700))
	found_heading.add_theme_color_override("font_color", BonStyle.BROWN)
	right.add_child(found_heading)
	found_places = HFlowContainer.new()
	found_places.name = "Found in"
	found_places.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(found_places)
	details_box = VBoxContainer.new()
	details_box.name = "Details box"
	details_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(details_box)
	detail_tiles = HBoxContainer.new()
	detail_tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_box.add_child(detail_tiles)
	for i in 3:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel", BonStyle.flat(STICKER, 14, 3, false))
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(stack)
		for j in 2:
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.add_theme_color_override("font_color", BonStyle.INK_SOFT if j == 0 else TEXT)
			stack.add_child(label)
		detail_tiles.add_child(tile)
	detail_games = GridContainer.new()
	detail_games.name = "Games"
	detail_games.columns = 4
	detail_games.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_box.add_child(detail_games)
	detail_empty = Label.new()
	detail_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_empty.add_theme_color_override("font_color", DIM)
	details_box.add_child(detail_empty)
	detail_hint = Label.new()
	detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_hint.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	details_box.add_child(detail_hint)

# --- Data ------------------------------------------------------------------------------------

## The baked place index (word key -> place ids), read once.
static func place_index() -> Dictionary:
	if _index.is_empty() and FileAccess.file_exists(PLACE_INDEX):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACE_INDEX))
		if parsed is Dictionary:
			_index = parsed.get("words", {})
			for key in parsed.get("from_games", []):
				_from_games[str(key)] = true
	return _index

## Whether only games find `key` (the index's from_games).
static func from_games(key: String) -> bool:
	place_index()
	return _from_games.has(key)

## New data from the HUD (opening the journal, a language change, a studied word). The last two
## arguments are kept for the HUD's call (the old By Area switch); `new_areas` (live area groups)
## only stands in when the place index is missing.
func set_data(new_studied: Dictionary, new_dictionary: Dictionary, new_categories: Dictionary, new_areas: Dictionary, new_area_names: Dictionary, new_bookmarks: Dictionary, _unused := false) -> void:
	studied = new_studied
	dictionary = new_dictionary
	categories = new_categories
	areas = new_areas
	area_names = new_area_names
	bookmarks = new_bookmarks
	var places := place_index()
	if places.is_empty():
		places = {}
		for area in areas:
			for key in areas[area]:
				if not places.has(str(key)):
					places[str(key)] = []
				places[str(key)].append(str(area))
	var lexicon = Lexicon.shared()
	words.clear()
	chapters.clear()
	total_found = 0
	found_words = studied.duplicate()
	for key in PracticeLog.shared().counts.get(lexicon.foreign, {}):
		found_words[str(key)] = true
	var memory = WordMemory.shared()
	for key in places:
		if not dictionary.has(key):
			continue
		var foreign := UiText.word(str(key), lexicon.foreign)
		var native := UiText.word(str(key), lexicon.native)
		words[key] = {"foreign": foreign, "native": native, "search": fold(foreign + "\n" + native), "tier": lexicon.tier(str(key), lexicon.foreign), "known": memory != null and memory.is_known(str(key))}
		if found_words.has(key):
			total_found += 1
		var where: Array = places[key]
		var ids: Array = [AROUND] if where.size() >= AROUND_TOWN_PLACES else where
		for id in ids:
			if not chapters.has(id):
				chapters[id] = []
			chapters[id].append(key)
	total_words = words.size()
	for id in chapters:
		chapters[id].sort_custom(_compare)
	chapter_order = chapters.keys().filter(func(id): return id != AROUND)
	chapter_order.sort_custom(func(a, b): return place_name(a).naturalnocasecmp_to(place_name(b)) < 0)
	if chapters.has(AROUND):
		chapter_order.push_front(AROUND)
	chapter_order.append(POCKET)
	_refresh_texts()
	if view != "contents" and chapter != SEARCH and chapter != POCKET and not chapters.has(chapter):
		show_contents()
		return
	if view == "word" and not words.has(detail_key):
		view = "chapter"
	_draw_page()

## Lower case without accents, so "cafe" finds "café".
static func fold(text: String) -> String:
	var out := ""
	for c in text.to_lower():
		out += UiText.FOLD.get(c, c)
	return out

## Album order: easier words first (the word's tier in the language learned), then by word key,
## so a sticker keeps its slot when the player changes languages (25 Nov 2026).
func _compare(a: String, b: String) -> bool:
	var ta: int = words[a].tier
	var tb: int = words[b].tier
	return ta < tb if ta != tb else a < b

## A place's shown name (zones.json name through phrases `places`), or a shelf's.
func place_name(id: String) -> String:
	match id:
		AROUND:
			return UiText.t("journal.around_town")
		POCKET:
			return UiText.t("journal.pocket")
		SEARCH:
			return UiText.t("journal.search_title", {"query": query.strip_edges()})
	return UiText.named("places", str(area_names.get(id, id.capitalize())))

## The word keys of a chapter (a place, Around town, the Pocket or the search results).
func chapter_keys(id: String) -> Array:
	match id:
		POCKET:
			var saved: Array = bookmarks.keys().filter(func(k): return words.has(str(k)))
			saved.sort_custom(_compare)
			return saved
		SEARCH:
			var needle := fold(query.strip_edges())
			if needle == "":
				return []
			var hits: Array = words.keys().filter(func(k): return str(words[k].search).contains(needle))
			hits.sort_custom(_compare)
			return hits
	return chapters.get(id, [])

## [found, total] of a chapter.
func chapter_count(id: String) -> Array:
	var keys := chapter_keys(id)
	return [keys.filter(func(k): return found_words.has(k)).size(), keys.size()]

## Every place of a word (data/zones.json ids), from the index.
func places_of(key: String) -> Array:
	var places: Array = place_index().get(key, [])
	if places.is_empty():
		for area in areas:
			if areas[area].has(key):
				places.append(str(area))
	return places

## {game id: {positive, negative, translated}} of one word in the current foreign language.
func games_for(key: String) -> Dictionary:
	return PracticeLog.shared().games_for(Lexicon.shared().foreign, key)

## A readable game name (data/phrases.json games.<id>); the id when there is none.
static func game_name(id: String) -> String:
	return UiText.t("games." + id) if UiText.has("games." + id) else id

## How many of the journal's words are known (word_memory.gd is_known()).
func known_total() -> int:
	return words.keys().filter(func(k): return bool(words[k].get("known", false))).size()

## The small daisy that marks a known word, for a picture (its parent): bottom-right corner,
## hidden until show_known() turns it on (decision D9, 25 Nov 2026, LEARN-04).
static func known_badge() -> TextureRect:
	var daisy := TextureRect.new()
	daisy.name = "Known"
	daisy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daisy.texture = BonStyle.icon_texture("daisy", 64)
	daisy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	daisy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	daisy.visible = false
	daisy.anchor_left = 1.0
	daisy.anchor_top = 1.0
	daisy.anchor_right = 1.0
	daisy.anchor_bottom = 1.0
	return daisy

## Shows or hides `cell`'s known daisy, sized for the window scale `f`.
static func show_known(cell: Control, known: bool, f: float) -> void:
	var daisy: Control = cell.get_node_or_null("Known")
	if daisy == null:
		return
	daisy.visible = known
	var px := KNOWN_BADGE * f
	daisy.offset_left = -px
	daisy.offset_top = -px
	daisy.offset_right = 0.0
	daisy.offset_bottom = 0.0

func voices_on() -> bool:
	var sound = Sound.shared()
	return sound != null and sound.voice_enabled()

func can_say(key: String) -> bool:
	var sound = Sound.shared()
	return key != "" and sound != null and sound.voice_enabled() and sound.has_voice(key, Lexicon.shared().foreign)

## Says `key` in the language being learned (nothing without a clip).
func say(key: String) -> void:
	if can_say(key):
		Sound.shared().say_word(key, Lexicon.shared().foreign)

# --- Navigation ------------------------------------------------------------------------------

func show_contents() -> void:
	view = "contents"
	chapter = ""
	page = contents_page
	flipped_key = ""
	_draw_page()

func open_chapter(id: String) -> void:
	if view == "contents":
		contents_page = page
	if id != SEARCH and query != "":
		_clear_search()
	view = "chapter"
	chapter = id
	page = 0
	flipped_key = ""
	_draw_page()

## The word page of a found word.
func open_detail(key: String) -> void:
	if not words.has(key) or not found_words.has(key):
		return
	detail_key = key
	details_open = false
	flipped_key = ""
	view = "word"
	search.release_focus()
	_draw_page()

## Back one level: word page -> chapter -> contents (Back, Esc).
func go_back() -> void:
	match view:
		"word":
			close_detail()
		"chapter":
			if chapter == SEARCH:
				_clear_search()
			show_contents()

func close_detail() -> void:
	if view != "word":
		return
	view = "chapter"
	# Keep the spread that shows the word.
	var index := chapter_keys(chapter).find(detail_key)
	if index >= 0:
		page = index / (PER_PAGE * 2)
	detail_key = ""
	_draw_page()

func is_detail_open() -> bool:
	return view == "word"

func page_count() -> int:
	match view:
		"contents":
			return maxi(1, ceili(chapter_order.size() / float(cards.size())))
		"chapter":
			return maxi(1, ceili(chapter_keys(chapter).size() / float(PER_PAGE * 2)))
	return 1

## Turns the spread (contents, chapter) or steps to the chapter's next found word (word page).
func turn_page(step: int) -> void:
	if view == "word":
		var found: Array = chapter_keys(chapter).filter(func(k): return found_words.has(k))
		var index := found.find(detail_key)
		if index >= 0 and index + step >= 0 and index + step < found.size():
			detail_key = found[index + step]
			_draw_page()
		return
	var to := clampi(page + step, 0, page_count() - 1)
	if to == page:
		return
	page = to
	flipped_key = ""
	_draw_page()

func set_query(text: String) -> void:
	var had := query.strip_edges() != ""
	query = text
	var has := query.strip_edges() != ""
	if has and not had:
		_before_search = [view, chapter, page, detail_key]
		if view == "contents":
			contents_page = page
	if has:
		view = "chapter"
		chapter = SEARCH
		page = 0
		flipped_key = ""
		_draw_page()
	elif had:
		_restore_view()

func _clear_search() -> void:
	query = ""
	search.text = ""
	_before_search = []

func _restore_view() -> void:
	var before := _before_search
	_before_search = []
	if before.is_empty() or before[1] == SEARCH:
		show_contents()
		return
	view = before[0]
	chapter = before[1]
	page = before[2]
	detail_key = before[3]
	if view == "contents":
		show_contents()
	else:
		_draw_page()

## A tap on a sticker: the first flips a found word to its native word (another flipped sticker
## turns back), the second opens its word page. A word not found yet flips to "Not found yet".
func _on_sticker(sticker: Button) -> void:
	if _swiped:
		return
	var key := str(sticker.get_meta("key", ""))
	if key == "":
		return
	if flipped_key == key and found_words.has(key):
		open_detail(key)
		return
	var before := flipped_key
	flipped_key = "" if flipped_key == key else key
	for other in stickers:
		if str(other.get_meta("key", "")) == before and before != key:
			_flip(other)
	_flip(sticker)

## Plays the flip (squash to a line and back) and redraws the sticker's face halfway.
func _flip(sticker: Button) -> void:
	var tween := sticker.create_tween()
	tween.tween_property(sticker, "scale:x", 0.0, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _draw_sticker(sticker, str(sticker.get_meta("key", ""))))
	tween.tween_property(sticker, "scale:x", 1.0, 0.1).set_trans(Tween.TRANS_SINE)

## A press and a sideways drag on the spread or its stickers turns the page (touch and mouse).
func _on_drag(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_at = event.global_position
			_pressing = true
			_swiped = false
		else:
			_pressing = false
	elif event is InputEventMouseMotion and _pressing and not _swiped:
		var moved: Vector2 = event.global_position - _press_at
		if absf(moved.x) > SWIPE * factor and absf(moved.x) > absf(moved.y) * 1.5:
			_swiped = true
			turn_page(-1 if moved.x > 0.0 else 1)
	elif event is InputEventMouseButton and event.pressed and view != "word":
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			turn_page(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			turn_page(1)

# --- Drawing ---------------------------------------------------------------------------------

## A bookmark changed (HUD): redraw the shown page and the Pocket's count.
func refresh_rows() -> void:
	_draw_page()

func _refresh_texts() -> void:
	var lexicon = Lexicon.shared()
	search.placeholder_text = UiText.t("journal.search", {"foreign": UiText.t("language." + lexicon.foreign), "native": UiText.t("language." + lexicon.native)})
	pocket_button.text = UiText.t("journal.pocket")
	pocket_button.tooltip_text = UiText.t("journal.pocket_tip")
	back_button.text = UiText.t("journal.contents")
	details_button.text = UiText.t("journal.details")
	detail_hint.text = UiText.t("journal.detail_hint")
	detail_empty.text = UiText.t("journal.no_games")

func _draw_page() -> void:
	var on_word := view == "word"
	detail.visible = on_word
	pages_box.visible = not on_word
	back_button.visible = view != "contents"
	pocket_button.set_pressed_no_signal(chapter == POCKET and view != "contents")
	page = clampi(page, 0, page_count() - 1)
	empty_label.visible = false
	match view:
		"contents":
			title_label.text = UiText.t("journal.contents")
			count_label.text = ""
			for i in stickers.size():
				stickers[i].visible = false
			for i in cards.size():
				var index: int = page * cards.size() + i
				var card: Button = cards[i]
				card.visible = index < chapter_order.size()
				if card.visible:
					_draw_card(card, chapter_order[index])
		"chapter":
			for card in cards:
				card.visible = false
			var keys := chapter_keys(chapter)
			title_label.text = place_name(chapter)
			var count := chapter_count(chapter)
			count_label.text = UiText.t("journal.place_count", {"found": count[0], "total": count[1]}) if chapter != POCKET and chapter != SEARCH else UiText.t("journal.word_count", {"n": keys.size()})
			for i in stickers.size():
				var index: int = page * stickers.size() + i
				var sticker: Button = stickers[i]
				sticker.visible = index < keys.size()
				sticker.scale = Vector2.ONE
				sticker.set_meta("key", str(keys[index]) if sticker.visible else "")
				if sticker.visible:
					_draw_sticker(sticker, str(keys[index]))
			if keys.is_empty():
				empty_label.visible = true
				empty_label.text = UiText.t("journal.pocket_empty") if chapter == POCKET else UiText.t("journal.no_match")
		"word":
			title_label.text = place_name(chapter)
			count_label.text = ""
			_render_detail()
	_draw_hint()
	var pages := page_count()
	page_label.text = "%d / %d" % [page + 1, pages] if not on_word and pages > 1 else ""
	if on_word:
		var found: Array = chapter_keys(chapter).filter(func(k): return found_words.has(k))
		var index := found.find(detail_key)
		page_label.text = "%d / %d" % [index + 1, found.size()] if index >= 0 else ""
		prev_button.disabled = index <= 0
		next_button.disabled = index < 0 or index >= found.size() - 1
	else:
		prev_button.disabled = page <= 0
		next_button.disabled = page >= pages - 1
	for arrow in [prev_button, next_button]:
		arrow.modulate.a = 0.35 if arrow.disabled else 1.0
	_place_items()

## The footer hint: what a tap does, and with keyboard play the ← → keys and Hold L.
func _draw_hint() -> void:
	var parts: Array = []
	match view:
		"contents":
			parts = [UiText.t("journal.hint_contents")]
			if keyboard_hints and page_count() > 1:
				parts.append(UiText.t("journal.hint_pages"))
		"chapter":
			parts = [UiText.t("journal.hint_chapter")]
			if keyboard_hints:
				if page_count() > 1:
					parts.append(UiText.t("journal.hint_pages"))
				parts.append(UiText.t("journal.hint_flip_all"))
		"word":
			if keyboard_hints:
				parts = [UiText.t("journal.hint_words")]
	hint.text = " · ".join(parts)

func _draw_card(card: Button, id: String) -> void:
	card.set_meta("chapter", id)
	card.name = "Card " + id
	var count := chapter_count(id)
	var pocket := id == POCKET
	card.get_node("Name").set_meta("raw", place_name(id))
	(card.get_node("Count") as Label).text = UiText.t("journal.word_count", {"n": count[1]}) if pocket else UiText.t("journal.place_count", {"found": count[0], "total": count[1]})
	var bar: MiniBar = card.get_node("Bar")
	bar.visible = not pocket
	bar.value = float(count[0]) / maxf(1.0, float(count[1]))
	(card.get_node("Badge/Icon") as TextureRect).texture = UiIcons.texture(str(PLACE_ICONS.get(id, "map")), 64)
	(card.get_node("Badge/Icon") as TextureRect).modulate = GOLD if pocket else BonStyle.INK
	# A place with nothing found yet is greyed (no visit tracking: nothing found = not visited).
	card.modulate = Color(1, 1, 1, 0.6) if count[0] == 0 and not pocket else Color.WHITE

func _draw_sticker(sticker: Button, key: String) -> void:
	sticker.name = "Sticker " + key
	var found := found_words.has(key)
	var word: Dictionary = words.get(key, {})
	var art: TextureRect = sticker.get_node("Picture")
	var mark: Label = sticker.get_node("Mark")
	var tag: Label = sticker.get_node("Tag")
	var label: Label = sticker.get_node("Word")
	var pin: TextureRect = sticker.get_node("Pin")
	var has_picture := _show_picture(art, key)
	art.visible = has_picture
	art.material = null if found else silhouette
	show_known(art, found and bool(word.get("known", false)), factor)
	var native: bool = (flipped_key == key or GameSettings.shared().peeking) and found
	pin.visible = bookmarks.has(key)
	# Restyled only when found or the window scale changes (no new boxes on every page turn).
	var look_id := "%s@%s" % [found, factor]
	if sticker.get_meta("look", "") != look_id:
		sticker.set_meta("look", look_id)
		BonStyle.flat_button(sticker, STICKER if found else SLOT, roundi(20 * factor), BonStyle.INK)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			var look: StyleBoxFlat = sticker.get_theme_stylebox(state)
			look.set_border_width_all(roundi((6 if found else 3) * factor))
			look.shadow_size = roundi((8 if found else 0) * factor)
	if found:
		mark.visible = false
		tag.visible = not has_picture and not native
		tag.set_meta("raw", str(word.get("foreign", key)))
		label.text = str(word.get("native" if native else "foreign", key))
		label.add_theme_color_override("font_color", BonStyle.BROWN if native else BonStyle.INK)
		label.visible = has_picture or native
		if native and not has_picture:
			tag.visible = false
		sticker.tooltip_text = ""
	else:
		tag.visible = false
		mark.visible = true
		# Search results say where a word not found yet is; a flipped one says it is not found.
		var caption := ""
		if flipped_key == key:
			caption = UiText.t("journal.not_found")
		elif chapter == SEARCH or chapter == POCKET:
			var places := places_of(key)
			caption = place_name(AROUND if places.size() >= AROUND_TOWN_PLACES else str(places[0])) if not places.is_empty() else ""
		label.text = caption
		label.visible = caption != ""
		label.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	_place_sticker(sticker)

## Shows `key`'s picture in `rect` (now or once drawn); false without the picture maker or one.
func _show_picture(rect: TextureRect, key: String, size := WordPictures.SIZE) -> bool:
	var pictures = WordPictures.shared()
	if pictures == null:
		rect.texture = null
		return false
	return pictures.fill(rect, key, size)

func _render_detail() -> void:
	var key := detail_key
	if not words.has(key):
		return
	var word: Dictionary = words[key]
	detail_foreign.text = word.foreign
	PinyinText.show(detail_reading, {"foreign": word.foreign})
	detail_native.text = word.native
	if bool(word.get("known", false)):
		detail_native.text += "  ·  " + UiText.t("journal.known_tag")
	var has_picture := _show_picture(detail_picture, key, WordPictures.BIG)
	detail_picture.visible = has_picture
	detail_tag.visible = not has_picture
	detail_tag.text = word.foreign
	var saved := bookmarks.has(key)
	detail_star.icon = BonStyle.icon_texture("star_on" if saved else "star_off", 96)
	detail_star.tooltip_text = UiText.t("card.unsave" if saved else "card.save")
	detail_speaker.visible = can_say(key)
	detail_speaker.tooltip_text = UiText.t("card.say")
	details_button.set_pressed_no_signal(details_open)
	found_heading.text = UiText.t("journal.found_in_game" if from_games(key) else "journal.found_in")
	found_heading.visible = not details_open
	found_places.visible = not details_open
	details_box.visible = details_open
	detail_scroll.scroll_vertical = 0
	for child in found_places.get_children():
		found_places.remove_child(child)
		child.queue_free()
	var places := places_of(key)
	if places.size() >= AROUND_TOWN_PLACES:
		places = [AROUND] + places
	for id in places:
		var chip := _button(open_chapter.bind(str(id)))
		chip.name = "Place " + str(id)
		chip.text = place_name(str(id))
		chip.set_meta("font_base", 17.0)
		style_button(chip, "plain")
		chip.custom_minimum_size.y = _tap(44)
		found_places.add_child(chip)
	var games := games_for(key)
	var sums := {"positive": 0, "negative": 0, "translated": 0}
	for game in games:
		for outcome in PracticeLog.OUTCOMES:
			sums[outcome] += int(games[game].get(outcome, 0))
	var tiles := [
		[UiText.t("journal.col_right"), str(sums.positive), RIGHT],
		[UiText.t("journal.col_wrong"), str(sums.negative), WRONG],
		[UiText.t("journal.col_translated"), str(sums.translated), TRANSLATED]]
	for i in 3:
		var labels: Array = detail_tiles.get_child(i).get_child(0).get_children()
		labels[0].text = tiles[i][0]
		labels[1].text = tiles[i][1]
		labels[1].add_theme_color_override("font_color", tiles[i][2])
	for child in detail_games.get_children():
		detail_games.remove_child(child)
		child.queue_free()
	var ids: Array = games.keys()
	ids.sort_custom(func(a, b): return game_name(a).naturalnocasecmp_to(game_name(b)) < 0)
	detail_empty.visible = ids.is_empty()
	if not ids.is_empty():
		var heads := [UiText.t("journal.col_game"), UiText.t("journal.col_right"), UiText.t("journal.col_wrong"), UiText.t("journal.col_translated")]
		for i in 4:
			_detail_cell(heads[i], BonStyle.BROWN, i == 0)
		for id in ids:
			var entry: Dictionary = games[id]
			_detail_cell(game_name(id), TEXT, true)
			for outcome in PracticeLog.OUTCOMES:
				var n := int(entry.get(outcome, 0))
				var color: Color = DIM if n == 0 else {"positive": RIGHT, "negative": WRONG, "translated": TRANSLATED}[outcome]
				_detail_cell(str(n), color, false)
	_scale_detail()

func _detail_cell(text: String, color: Color, first: bool) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	_font(label, 16)
	if first:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size.x = 76 * factor
	detail_games.add_child(label)

# --- Layout ----------------------------------------------------------------------------------

## Places the stickers (2 x 2 a page) or the cards (CARD_COLUMNS x CARD_ROWS a page) in the pages.
func _place_items() -> void:
	var gap := 14.0 * factor
	for i in stickers.size():
		if not stickers[i].visible:
			continue
		var page_node: Control = left_page if i < PER_PAGE else right_page
		var slot := i % PER_PAGE
		var cell := (page_node.size - Vector2(gap * 3.0, gap * 3.0)) / 2.0
		var sticker: Button = stickers[i]
		sticker.position = Vector2(gap + (slot % 2) * (cell.x + gap), gap + (slot / 2) * (cell.y + gap))
		sticker.size = cell.max(Vector2.ONE)
		_place_sticker(sticker)
	var per_page := CARD_COLUMNS * CARD_ROWS
	for i in cards.size():
		if not cards[i].visible:
			continue
		var page_node: Control = left_page if i < per_page else right_page
		var slot := i % per_page
		var cell := (page_node.size - Vector2(gap * (CARD_COLUMNS + 1), gap * (CARD_ROWS + 1))) / Vector2(CARD_COLUMNS, CARD_ROWS)
		var card: Button = cards[i]
		card.position = Vector2(gap + (slot % CARD_COLUMNS) * (cell.x + gap), gap + (slot / CARD_COLUMNS) * (cell.y + gap))
		card.size = cell.max(Vector2.ONE)
		_place_card(card)

## The sticker's parts inside it: the picture square on top, the word strip at the bottom.
func _place_sticker(sticker: Button) -> void:
	var s := sticker.size
	var pad := 10.0 * factor
	var strip := clampf(s.y * 0.2, 26.0 * factor, 46.0 * factor)
	var art: TextureRect = sticker.get_node("Picture")
	_put(art, Vector2(pad, pad), Vector2(s.x - pad * 2.0, s.y - strip - pad * 1.5).max(Vector2.ONE))
	var mark: Label = sticker.get_node("Mark")
	mark.add_theme_font_size_override("font_size", roundi(minf(art.size.y * 0.55, 72.0 * factor)))
	_put(mark, art.position, art.size)
	var tag: Label = sticker.get_node("Tag")
	_fit_lines(tag, str(tag.get_meta("raw", "")), s.x - pad * 2.0, 30.0, 16.0)
	_put(tag, Vector2(pad, pad), Vector2(s.x - pad * 2.0, s.y - pad * 2.0).max(Vector2.ONE))
	var label: Label = sticker.get_node("Word")
	label.add_theme_font_size_override("font_size", _fit_size(label.text, s.x - pad, 24.0, 14.0))
	_put(label, Vector2(pad * 0.5, s.y - strip - pad * 0.5), Vector2(s.x - pad, strip))
	var pin: TextureRect = sticker.get_node("Pin")
	var pin_side := 30.0 * factor
	pin.size = Vector2.ONE * pin_side
	pin.position = Vector2(s.x - pin_side - 4.0 * factor, 4.0 * factor)
	var mid := sticker.size * 0.5
	sticker.pivot_offset = mid

## Places `node` at `at` with `size`: the width first, so a wrapping label's height is worked out
## for its new width (a Control never shrinks below its minimum size for the old width).
static func _put(node: Control, at: Vector2, size: Vector2) -> void:
	node.position = at
	node.size = Vector2(size.x, 1.0)
	node.size = size

## The largest font size from `big` down to `small` (design px) at which `text` fits `width`.
func _fit_size(text: String, width: float, big: float, small: float) -> int:
	var font := BonStyle.font(700)
	var size := big
	while size > small and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(size * factor)).x > width:
		size -= 2.0
	return maxi(roundi(size * factor), MIN_TEXT)

## Sets `label` to `text` on one line, or two (split at the space nearest the middle) when one
## line would not fit `width`, at the largest font size from `big` to `small` that fits.
func _fit_lines(label: Label, text: String, width: float, big: float, small: float) -> void:
	var font := BonStyle.font(700)
	var lines := text
	var one := _fit_size(text, width, big, small)
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, one).x > width and text.contains(" "):
		var best := -1
		for i in text.length():
			if text[i] == " " and (best < 0 or absi(i - text.length() / 2) < absi(best - text.length() / 2)):
				best = i
		lines = text.substr(0, best) + "\n" + text.substr(best + 1)
	var size := big * factor
	for line in lines.split("\n"):
		size = minf(size, float(_fit_size(line, width, big, small)))
	label.text = lines
	label.add_theme_font_size_override("font_size", roundi(size))

func _place_card(card: Button) -> void:
	var s := card.size
	var pad := 10.0 * factor
	var badge: Panel = card.get_node("Badge")
	var side := minf(s.y * 0.3, 56.0 * factor)
	_put(badge, Vector2((s.x - side) * 0.5, pad), Vector2.ONE * side)
	# New boxes only when the card's size or the window scale changes.
	var look_id := "%s@%s" % [side, factor]
	var restyle: bool = card.get_meta("look", "") != look_id
	if restyle:
		card.set_meta("look", look_id)
		badge.add_theme_stylebox_override("panel", BonStyle.flat(BonStyle.SKY, roundi(side * 0.5), roundi(3 * factor), false))
	var icon: TextureRect = badge.get_node("Icon")
	_put(icon, Vector2.ONE * side * 0.2, Vector2.ONE * side * 0.6)
	var bar: MiniBar = card.get_node("Bar")
	bar.f = factor
	_put(bar, Vector2(pad * 2.0, s.y - pad - 10.0 * factor), Vector2(s.x - pad * 4.0, 10.0 * factor))
	var count: Label = card.get_node("Count")
	_font(count, 16)
	_put(count, Vector2(pad, bar.position.y - 26.0 * factor), Vector2(s.x - pad * 2.0, 22.0 * factor))
	var title: Label = card.get_node("Name")
	_fit_lines(title, str(title.get_meta("raw", "")), s.x - pad * 2.0, 19.0, 12.0)
	var top := badge.position.y + side
	_put(title, Vector2(pad, top), Vector2(s.x - pad * 2.0, maxf(1.0, count.position.y - top)))
	if not restyle:
		return
	var look := BonStyle.flat(STICKER, roundi(18 * factor), roundi(5 * factor))
	look.shadow_size = roundi(6 * factor)
	card.add_theme_stylebox_override("normal", look)
	var hover := look.duplicate()
	hover.bg_color = BonStyle.SKY_TOP
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", hover)
	card.add_theme_stylebox_override("hover_pressed", hover)
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _font(node: Control, size: float) -> void:
	node.add_theme_font_size_override("font_size", maxi(roundi(size * factor), MIN_TEXT))

## A button's height: `size` design px at the window scale, never under TAP.
func _tap(size: float) -> float:
	return maxf(size * factor, TAP)

## Window scale min(height / 800, width / 1100), set by the HUD's layout.
func apply_scale(f: float) -> void:
	factor = f
	add_theme_constant_override("separation", roundi(10 * f))
	top_row.add_theme_constant_override("separation", roundi(12 * f))
	top_row.custom_minimum_size.y = _tap(52)
	_font(title_label, 26)
	_font(count_label, 18)
	_font(back_button, 18)
	back_button.icon = UiIcons.texture("back", roundi(22 * f))
	back_button.custom_minimum_size = Vector2(0, _tap(48))
	_font(search, 18)
	search.custom_minimum_size = Vector2(180 * f, _tap(48))
	search.right_icon = UiIcons.texture("look", roundi(22 * f))
	search.add_theme_stylebox_override("normal", _field(BonStyle.RIM))
	search.add_theme_stylebox_override("focus", _field(BonStyle.GREEN_BOTTOM))
	search.add_theme_color_override("font_color", TEXT)
	search.add_theme_color_override("font_placeholder_color", Color("86aab1"))
	search.add_theme_color_override("caret_color", BonStyle.GREEN_BOTTOM)
	_font(pocket_button, 18)
	pocket_button.icon = UiIcons.texture("star", roundi(22 * f))
	pocket_button.custom_minimum_size = Vector2(0, _tap(48))
	for arrow in [prev_button, next_button]:
		arrow.custom_minimum_size = Vector2.ONE * _tap(64)
		arrow.add_theme_constant_override("icon_max_width", roundi(34 * f))
	var page_look: StyleBoxFlat = spread.get_theme_stylebox("panel")
	page_look.set_corner_radius_all(roundi(26 * f))
	page_look.set_border_width_all(roundi(6 * f))
	page_look.set_content_margin_all(10 * f)
	crease.custom_minimum_size.x = 26 * f
	_font(empty_label, 20)
	_font(hint, 15)
	_font(page_label, 17)
	footer.custom_minimum_size.y = maxf(24 * f, MIN_TEXT + 6)
	styled_buttons = styled_buttons.filter(func(entry: Array) -> bool: return is_instance_valid(entry[0]))
	for entry in styled_buttons:
		_style_one(entry[0], entry[1])
	_scale_detail()
	# _draw_page places the items too.
	if words.is_empty():
		_place_items()
	else:
		_draw_page()

func _field(edge: Color) -> StyleBoxFlat:
	var look := BonStyle.flat(BonStyle.SKY, roundi(24 * factor), roundi(3 * factor), false)
	look.border_color = edge
	look.content_margin_left = 18 * factor
	look.content_margin_right = 12 * factor
	return look

func _scale_detail() -> void:
	var f := factor
	var side := clampf(minf(spread.size.x * 0.3, spread.size.y - 60.0 * f), 100.0 * f, 320.0 * f) if spread.size.y > 0.0 else 280.0 * f
	var frame: PanelContainer = detail_picture.get_parent().get_parent()
	frame.custom_minimum_size = Vector2(side, side)
	var frame_look: StyleBoxFlat = frame.get_theme_stylebox("panel")
	frame_look.set_corner_radius_all(roundi(26 * f))
	frame_look.set_border_width_all(roundi(8 * f))
	frame_look.set_content_margin_all(14 * f)
	_font(detail_tag, 40)
	(detail.get_node("Fold") as Control).custom_minimum_size.x = 26 * f
	detail.add_theme_constant_override("separation", roundi(8 * f))
	(detail_scroll.get_node("Word side") as VBoxContainer).add_theme_constant_override("separation", roundi(8 * f))
	detail_scroll.get_v_scroll_bar().custom_minimum_size.x = maxf(24.0 * f, 14.0)
	_font(detail_foreign, 40)
	_font(detail_reading, 20)
	_font(detail_native, 24)
	(detail_scroll.get_node("Word side/Actions") as HBoxContainer).add_theme_constant_override("separation", roundi(10 * f))
	for button in [detail_speaker, detail_star]:
		button.custom_minimum_size = Vector2.ONE * _tap(60)
		button.add_theme_constant_override("icon_max_width", roundi(36 * f))
	_font(details_button, 18)
	details_button.custom_minimum_size = Vector2(0, _tap(60))
	_font(found_heading, 18)
	found_places.add_theme_constant_override("h_separation", roundi(8 * f))
	found_places.add_theme_constant_override("v_separation", roundi(8 * f))
	for chip in found_places.get_children():
		chip.custom_minimum_size.y = _tap(44)
		_font(chip, 17)
	details_box.add_theme_constant_override("separation", roundi(8 * f))
	detail_tiles.add_theme_constant_override("separation", roundi(8 * f))
	for tile in detail_tiles.get_children():
		(tile.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(8 * f)
		var labels: Array = tile.get_child(0).get_children()
		_font(labels[0], 14)
		_font(labels[1], 26)
	detail_games.add_theme_constant_override("h_separation", roundi(8 * f))
	detail_games.add_theme_constant_override("v_separation", roundi(4 * f))
	for cell in detail_games.get_children():
		_font(cell, 16)
		if cell.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			cell.custom_minimum_size.x = 76 * f
	_font(detail_empty, 16)
	_font(detail_hint, 14)

## The album's centre fold: a soft shadow either side of a thin crease.
class Fold extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func _draw() -> void:
		var mid := size.x * 0.5
		var steps := 6
		for i in steps:
			var w := mid * (1.0 - float(i) / steps)
			draw_rect(Rect2(mid - w, 0, w * 2.0, size.y), Color(0.48, 0.29, 0.13, 0.025))
		draw_line(Vector2(mid, 0), Vector2(mid, size.y), Color(0.48, 0.29, 0.13, 0.22), maxf(1.0, size.x * 0.06))

## A small static progress bar (contents cards): a cream-deep track and a green fill.
class MiniBar extends Control:
	var f := 1.0
	var value := 0.0:
		set(v):
			value = clampf(v, 0.0, 1.0)
			queue_redraw()

	var track := StyleBoxFlat.new()
	var fill := StyleBoxFlat.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var BonStyleScript: GDScript = load("res://scripts/ui/bon_style.gd")
		track.bg_color = BonStyleScript.CREAM_DEEP
		fill.bg_color = BonStyleScript.GREEN_BOTTOM
		track.anti_aliasing = true
		fill.anti_aliasing = true

	func _draw() -> void:
		var radius := roundi(size.y * 0.5)
		track.set_corner_radius_all(radius)
		draw_style_box(track, Rect2(Vector2.ZERO, size))
		if value <= 0.0:
			return
		fill.set_corner_radius_all(radius)
		draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * value), size.y)))
