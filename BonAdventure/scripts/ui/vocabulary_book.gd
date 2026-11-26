extends VBoxContainer
## The vocabulary book: the body of the study journal (J; Stage C of the vocabulary tracking
## work, 8 Nov 2026; guide: docs/guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-book). The HUD
## (vocabulary_hud.gd) owns the journal window, its title, the By Category / By Area buttons
## and the bookmarks; this panel shows every word of the dictionary as a table:
##   ★ | picture | foreign | native | studied ✓ | right | wrong
## (the picture: the word's own town object, word_pictures.gd, 23 Nov 2026; also big in the detail)
## with filters (All / Studied / Saved, search in either language, categories and areas
## (multi-select menus: any number ticked, none = all; 9 Nov 2026), sorting),
## Show / Hide scores (the last three columns) and a detail view of one word (click a row).
## Numbers come only from the practice tracker (practice_log.gd, the current foreign
## language); word totals are the sums of the per-game counts. Nothing here records practice.
##
## Rows are virtual: only the rows that fit are controls, reused while scrolling, so the
## ~780 words stay smooth. Layout scales with min(height / 800, width / 1100) (apply_scale).
## Since 9 Nov 2026 the Saved tab is the game's saved-words list (the HUD's book button opens
## this journal; the separate saved-words panel was removed) and every control is styled here
## (style_button(); the HUD styles its own header buttons with it too).
## UI art style (user, 18 Nov 2026; docs/guides/UI_STYLE.md): a light cream table on the HUD's mint
## card, dark teal and brown Fredoka text, BonStyle pills for tabs, menus and toggles (green when
## chosen), restyled at every window scale (apply_scale()).
## Known words (decision D9, 25 Nov 2026, LEARN-04): a word the word memory knows
## (word_memory.gd is_known(), the one test) has a small daisy on its picture cell (known_badge(),
## shared so the sticker-book journal can reuse it), the footer counts the known words, and the
## detail view says so.
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const Sound := preload("res://scripts/core/sound.gd")
const WordPictures := preload("res://scripts/ui/word_pictures.gd")
const WordMemory := preload("res://scripts/learning/word_memory.gd")

## Light palette (UI art style, 18 Nov 2026; was the dark HUD colours).
const GOLD := Color("e9a91f")
const HEADING := BonStyle.BROWN
const FOREIGN := BonStyle.INK
const TEXT := Color("3d5560")
const DIM := Color("a5b3b6")
const RIGHT := Color("3f9a35")
const WRONG := Color("d0523f")
const HINT := BonStyle.INK_SOFT
## Frame colours: the table's cream frame, its edge and the scroll bar.
const BUTTON_EDGE := BonStyle.RIM
const BUTTON_HOVER := Color("cde9ec")
const TEAL := Color("8cc6cd")
const ACTIVE := BonStyle.GREEN_BOTTOM
const INK := BonStyle.INK
const FRAME := BonStyle.SKY   # in-game cards are soft blue (user, 18 Nov 2026)
const TRANSLATED := Color("4f86b0")
## [button, kind] of every button styled here, restyled at each window scale (apply_scale()).
var styled_buttons: Array = []
const FILTERS := ["all", "studied", "saved"]
const FILTER_ICONS := {"all": "book", "studied": "check", "saved": "star"}
const SORTS := ["foreign", "native", "right", "wrong"]
## Base sizes at scale 1 (a 1100 x 800 window).
## Rows and the scroll bar are sized for touch too (user, 9 Nov 2026: "optimized for mobile").
const ROW_HEIGHT := 56.0
const SCROLL_WIDTH := 24.0
const STAR_WIDTH := 52.0
const NUMBER_WIDTH := 96.0
const PICTURE_WIDTH := 52.0
## The known daisy on a row's picture cell (square, at scale 1).
const KNOWN_BADGE := 24.0
## Drag to scroll (25 Nov 2026, improvement plan UI-03): a press on the list (a row, its star or
## speaker, or the empty space) that travels more than this many pixels at scale 1 (at least
## DRAG_SLOP_MIN) scrolls the list with the finger and is no longer a tap, so the row, star or
## speaker under it does nothing on release. Shorter presses are taps, as in touch_controls.gd.
const DRAG_SLOP := 12.0
const DRAG_SLOP_MIN := 10.0
## The detail view's picture (square, at scale 1).
const DETAIL_PICTURE := 132.0
## Row cells: star, picture, foreign, native, the three score columns, then the speaker.
const FOREIGN_CELL := 2
const SCORE_CELLS := [4, 5, 6]
## The speaker (24 Nov 2026, user: "there should be a speak icon on the word journal"): says the
## word in the learned language (sound.gd say_word); the column shows while spoken words are on,
## and a word without a clip leaves its cell empty.
const SPEAKER_CELL := 7
const SPEAKER_WIDTH := 52.0

## A row's star was clicked: the HUD toggles and saves the bookmark, then calls refresh_rows().
signal bookmark_toggled(word_key: String)

# Data from the HUD (toggle_journal / render_journal).
var studied: Dictionary = {}
var dictionary: Dictionary = {}
var categories: Dictionary = {}
var areas: Dictionary = {}
var area_names: Dictionary = {}
var bookmarks: Dictionary = {}
var by_area := false

# View state (kept while the journal is closed).
var filter := "all"
var query := ""
## Ticked categories / area ids of the multi-select menus; empty = every one.
var chosen_categories: Dictionary = {}
var chosen_areas: Dictionary = {}
## Word keys in the ticked areas (rebuilt with the area choice).
var area_keys: Dictionary = {}
var sort := "foreign"
var show_scores := true
var detail_key := ""

## key -> {foreign, native, search, positive, negative, translated}; rebuilt by set_data().
var words: Dictionary = {}
## The flattened table: {"heading": text} or {"key": word key}.
var items: Array = []
var shown_words := 0
var factor := 1.0

var filter_buttons: Dictionary = {}
## The tabs row; the HUD adds its By Category / By Area buttons at its end.
var tab_bar: HBoxContainer
var tools: HBoxContainer
var search: LineEdit
var category_menu: MenuButton
var area_menu: MenuButton
var sort_menu: OptionButton
var scores_button: Button
var table: VBoxContainer
var table_card: PanelContainer
var header: HBoxContainer
var list_area: Control
var scroll: VScrollBar
## Keeps the header columns over the row columns while the scroll bar shows.
var header_gap: Control
var rows: Array = []
## The press being followed on the list: where it started (viewport pixels), the scroll value
## then, and whether it has become a drag.
var _drag_from := Vector2.ZERO
var _drag_scroll := 0.0
var _drag_held := false
var dragging := false
## "No words match" / the Saved tab's how-to-save note, centred over the empty table.
var empty_label: Label
var footer_bar: HBoxContainer
var footer: Label
## The HUD's view hint (journal.hint_*), right of the footer.
var hint: Label
## [StyleBoxFlat, margin x, margin y, corner radius] at scale 1; apply_scale() resizes them.
var scaled_styles: Array = []
var detail: VBoxContainer
var back_button: Button
var detail_star: Button
var detail_speaker: Button
var detail_picture: TextureRect
var detail_foreign: Label
var detail_reading: Label
var detail_native: Label
var detail_tiles: HBoxContainer
var detail_games: GridContainer
var detail_empty: Label
var detail_hint: Label

func _init() -> void:
	name = "Vocabulary book"
	# Fredoka for every label, button and menu inside (UI art style).
	theme = Theme.new()
	theme.default_font = BonStyle.font(600)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)
	table = VBoxContainer.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("separation", 8)
	add_child(table)
	# Row 1: All / Studied / Saved tabs (pills), then the HUD's grouping buttons on the right.
	tab_bar = HBoxContainer.new()
	table.add_child(tab_bar)
	for id in FILTERS:
		var button := _button(_on_filter.bind(id))
		button.name = "Tab " + id
		button.toggle_mode = true
		style_button(button, "tab")
		if id == "saved":
			button.set_meta("icon_color", GOLD)
			_style_one(button)
		filter_buttons[id] = button
		tab_bar.add_child(button)
	var tab_space := Control.new()
	tab_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.add_child(tab_space)
	# Row 2: search, category, sorting and Show / Hide scores.
	tools = HBoxContainer.new()
	table.add_child(tools)
	search = LineEdit.new()
	search.name = "Search"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.size_flags_stretch_ratio = 1.4
	search.clear_button_enabled = true
	search.add_theme_stylebox_override("normal", _style(FRAME, BUTTON_EDGE, 24, 18, 6))
	var focused := _style(FRAME, ACTIVE, 24, 18, 6)
	search.add_theme_stylebox_override("focus", focused)
	search.add_theme_color_override("font_color", TEXT)
	search.add_theme_color_override("font_placeholder_color", Color("86aab1"))
	search.add_theme_color_override("caret_color", ACTIVE)
	search.text_changed.connect(func(text: String) -> void:
		query = text
		rebuild())
	tools.add_child(search)
	category_menu = _make_choice_menu("Categories", chosen_categories)
	tools.add_child(category_menu)
	area_menu = _make_choice_menu("Areas", chosen_areas)
	tools.add_child(area_menu)
	sort_menu = OptionButton.new()
	sort_menu.name = "Sort"
	sort_menu.focus_mode = Control.FOCUS_NONE
	sort_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort_menu.clip_text = true
	sort_menu.item_selected.connect(func(index: int) -> void:
		sort = SORTS[index]
		rebuild())
	tools.add_child(sort_menu)
	for menu in [category_menu, area_menu, sort_menu]:
		style_button(menu, "plain")
		var popup: PopupMenu = menu.get_popup()
		popup.add_theme_stylebox_override("panel", _style(FRAME, BUTTON_EDGE, 14, 8, 8))
		popup.add_theme_stylebox_override("hover", _style(BonStyle.GREEN_TOP, BonStyle.GREEN_TOP, 10, 8, 4))
		popup.add_theme_color_override("font_color", BonStyle.BROWN)
		popup.add_theme_color_override("font_hover_color", Color.WHITE)
		popup.add_theme_font_override("font", BonStyle.font(600))
	# Scores: a short on/off toggle in the tab row (teal when the score columns show; the
	# tooltip says Show / Hide scores), so the tools row keeps room for the menus.
	scores_button = _button(func() -> void: set_show_scores(not show_scores))
	scores_button.name = "Scores"
	scores_button.toggle_mode = true
	scores_button.button_pressed = show_scores
	style_button(scores_button, "plain")
	tab_bar.add_child(scores_button)
	# The table sits in a darker frame: column header, a rule, then the rows.
	table_card = PanelContainer.new()
	table_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_card.add_theme_stylebox_override("panel", _style(FRAME, BUTTON_EDGE, 18, 12, 8))
	table.add_child(table_card)
	var card_stack := VBoxContainer.new()
	card_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_stack.add_theme_constant_override("separation", 4)
	table_card.add_child(card_stack)
	header = _make_row(true)
	header_gap = Control.new()
	header_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_gap)
	card_stack.add_child(header)
	var rule := ColorRect.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.color = BUTTON_EDGE
	rule.custom_minimum_size.y = 2
	card_stack.add_child(rule)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_stack.add_child(body)
	list_area = Control.new()
	list_area.name = "Rows"
	list_area.clip_contents = true
	list_area.mouse_filter = Control.MOUSE_FILTER_STOP
	list_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_area.resized.connect(_layout_rows)
	list_area.gui_input.connect(_on_list_input)
	body.add_child(list_area)
	empty_label = Label.new()
	empty_label.name = "Empty note"
	empty_label.visible = false
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.add_theme_color_override("font_color", HINT)
	list_area.add_child(empty_label)
	empty_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll = VScrollBar.new()
	scroll.add_theme_stylebox_override("scroll", _style(Color("cfe8eb"), Color("cfe8eb"), 12, 0, 0))
	scroll.add_theme_stylebox_override("grabber", _style(Color("9fcfd5"), Color("9fcfd5"), 12, 0, 0))
	scroll.add_theme_stylebox_override("grabber_highlight", _style(TEAL, TEAL, 6, 0, 0))
	scroll.add_theme_stylebox_override("grabber_pressed", _style(ACTIVE, ACTIVE, 6, 0, 0))
	scroll.value_changed.connect(func(_v: float) -> void: _draw_rows())
	body.add_child(scroll)
	footer_bar = HBoxContainer.new()
	table.add_child(footer_bar)
	footer = Label.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_theme_color_override("font_color", HINT)
	footer_bar.add_child(footer)
	hint = Label.new()
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", HINT)
	footer_bar.add_child(hint)
	_build_detail()

## A flat rounded box; its margins and corners follow the window scale (apply_scale).
func _style(fill: Color, edge: Color, radius: float, margin_x: float, margin_y: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.anti_aliasing = true
	scaled_styles.append([style, margin_x, margin_y, radius])
	_scale_style(scaled_styles[-1])
	return style

func _scale_style(entry: Array) -> void:
	var style: StyleBoxFlat = entry[0]
	style.content_margin_left = entry[1] * factor
	style.content_margin_right = entry[1] * factor
	style.content_margin_top = entry[2] * factor
	style.content_margin_bottom = entry[2] * factor
	style.set_corner_radius_all(roundi(entry[3] * factor))

## The journal's button look (BonStyle, 18 Nov 2026). "tab": a cream pill that turns green with
## white words when chosen; "plain": the same for toggles and open menus. Restyled at each
## window scale by apply_scale(); the HUD styles its header buttons with it too.
func style_button(button: Button, kind: String) -> void:
	if not styled_buttons.any(func(e: Array) -> bool: return e[0] == button):
		styled_buttons.append([button, kind])
	_style_one(button)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _style_one(button: Button) -> void:
	var size := 18.0
	if button.has_theme_font_size_override("font_size"):
		size = float(button.get_theme_font_size("font_size")) / factor
	BonStyle.style_toggle(button, factor, size)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var look := button.get_theme_stylebox(state)
		look.content_margin_left = 16.0 * factor
		look.content_margin_right = 16.0 * factor
		look.content_margin_top = 4.0 * factor
		look.content_margin_bottom = 6.0 * factor
	if button.has_meta("icon_color"):
		for name in ["icon_normal_color", "icon_hover_color"]:
			button.add_theme_color_override(name, button.get_meta("icon_color"))

## A button whose menu ticks any number of choices (first item: "All", which clears them).
## `chosen` is the dictionary it fills (chosen_categories or chosen_areas); the menu stays open
## while ticking.
func _make_choice_menu(menu_name: String, chosen: Dictionary) -> MenuButton:
	var menu := MenuButton.new()
	menu.name = menu_name
	menu.flat = false
	menu.focus_mode = Control.FOCUS_NONE
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.clip_text = true
	menu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# A ⌄ at the right end, like the sort menu's arrow.
	menu.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var popup := menu.get_popup()
	popup.hide_on_checkable_item_selection = false
	popup.index_pressed.connect(func(index: int) -> void: toggle_choice(menu, index))
	menu.set_meta("chosen", chosen)
	return menu

## Ticks or unticks one menu item (index 0 "All" unticks every one), then filters again.
func toggle_choice(menu: MenuButton, index: int) -> void:
	var chosen: Dictionary = menu.get_meta("chosen")
	var popup := menu.get_popup()
	if index == 0:
		chosen.clear()
	else:
		var id := str(popup.get_item_metadata(index))
		if chosen.has(id):
			chosen.erase(id)
		else:
			chosen[id] = true
	_sync_choice_menu(menu)
	if menu == area_menu:
		_collect_area_keys()
	rebuild()

## The menu's ticks and its label: "All …", the one ticked name, or "N categories / areas".
func _sync_choice_menu(menu: MenuButton) -> void:
	var chosen: Dictionary = menu.get_meta("chosen")
	var popup := menu.get_popup()
	var one_name := ""
	for i in popup.item_count:
		var on: bool = chosen.is_empty() if i == 0 else chosen.has(str(popup.get_item_metadata(i)))
		popup.set_item_checked(i, on)
		if on and i > 0:
			one_name = popup.get_item_text(i)
	var areas_menu: bool = menu == area_menu
	if chosen.is_empty():
		menu.text = UiText.t("journal.all_areas" if areas_menu else "journal.all_categories")
	elif chosen.size() == 1:
		menu.text = one_name
	else:
		menu.text = UiText.t("journal.some_areas" if areas_menu else "journal.some_categories", {"n": chosen.size()})

## Fills a choice menu: "All" then each [id, shown name], sorted by name; forgets ticks of ids
## that are gone (another language's dictionary).
func _fill_choice_menu(menu: MenuButton, all_text: String, choices: Array) -> void:
	var chosen: Dictionary = menu.get_meta("chosen")
	var popup := menu.get_popup()
	popup.clear()
	popup.add_check_item(all_text)
	popup.set_item_metadata(0, "")
	choices.sort_custom(func(a, b): return str(a[1]).naturalnocasecmp_to(str(b[1])) < 0)
	var ids: Dictionary = {}
	for choice in choices:
		popup.add_check_item(str(choice[1]))
		popup.set_item_metadata(popup.item_count - 1, str(choice[0]))
		ids[str(choice[0])] = true
	for id in chosen.keys():
		if not ids.has(id):
			chosen.erase(id)
	_sync_choice_menu(menu)

func _collect_area_keys() -> void:
	area_keys.clear()
	for area in chosen_areas:
		for key in areas.get(area, []):
			area_keys[str(key)] = true

func _button(handler: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(handler)
	return button

func _cell(width: float, expand: float = 0.0) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_meta("base_width", width)
	if expand > 0.0:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = expand
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

## One table row: [star, foreign, native, studied, right, wrong] plus a heading label that
## replaces them on section rows. The header row has no star button and no click.
func _make_row(is_header: bool) -> Control:
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 10)
	if is_header:
		var spacer := _cell(STAR_WIDTH)
		spacer.text = "★"
		spacer.add_theme_color_override("font_color", HEADING)
		line.add_child(spacer)
	else:
		var star := Button.new()
		star.name = "Star"
		star.flat = true
		star.focus_mode = Control.FOCUS_NONE
		# STOP: a press on the star only saves or unsaves the word and never reaches the row
		# (which opens the detail); the wheel still scrolls the list.
		star.mouse_filter = Control.MOUSE_FILTER_STOP
		star.gui_input.connect(_on_list_input)
		star.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		star.set_meta("base_width", STAR_WIDTH)
		star.add_theme_color_override("font_color", GOLD)
		star.add_theme_color_override("font_hover_color", GOLD.lightened(0.25))
		star.pressed.connect(func() -> void:
			var key := str(line.get_meta("key", ""))
			if key != "" and not dragging:
				bookmark_toggled.emit(key))
		line.add_child(star)
	# The word's picture (empty when it has none); the header keeps its column free.
	if is_header:
		line.add_child(_cell(PICTURE_WIDTH))
	else:
		var art := TextureRect.new()
		art.name = "Picture"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.set_meta("base_width", PICTURE_WIDTH)
		art.add_child(known_badge())
		line.add_child(art)
	for spec in [[0.0, 1.3], [0.0, 1.1], [NUMBER_WIDTH, 0.0], [NUMBER_WIDTH, 0.0], [NUMBER_WIDTH, 0.0]]:
		var cell := _cell(spec[0], spec[1])
		if is_header:
			cell.add_theme_color_override("font_color", HEADING)
		elif line.get_child_count() == FOREIGN_CELL:
			cell.add_theme_color_override("font_color", FOREIGN)   # the word (dark on cream)
		elif line.get_child_count() == FOREIGN_CELL + 1:
			cell.add_theme_color_override("font_color", TEXT)   # its translation
		line.add_child(cell)
	if is_header:
		line.add_child(_cell(SPEAKER_WIDTH))
		return line
	var speaker := _speaker_button(func() -> String: return str(line.get_meta("key", "")))
	speaker.set_meta("base_width", SPEAKER_WIDTH)
	line.add_child(speaker)
	# Word rows are flat buttons (the whole row opens the detail view); the star sits on top.
	var row := Button.new()
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var plain := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = BUTTON_HOVER
	hover.set_corner_radius_all(6)
	for state in ["normal", "pressed", "focus", "disabled"]:
		row.add_theme_stylebox_override(state, plain)
	row.add_theme_stylebox_override("hover", hover)
	# Every other word row is a shade lighter, so a row's words read across.
	var stripe := ColorRect.new()
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stripe.color = Color(0.09, 0.33, 0.42, 0.05)
	row.add_child(stripe)
	stripe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(line)
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var heading := Label.new()
	heading.name = "Heading"
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	heading.add_theme_color_override("font_color", HEADING)
	row.add_child(heading)
	heading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# A section heading is underlined across the table.
	var underline := ColorRect.new()
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underline.color = Color(HEADING, 0.35)
	heading.add_child(underline)
	underline.anchor_top = 1.0
	underline.anchor_right = 1.0
	underline.anchor_bottom = 1.0
	underline.offset_top = -1.0
	row.set_meta("line", line)
	row.set_meta("heading", heading)
	row.set_meta("stripe", stripe)
	# The row takes the press, so it also follows a drag (see _on_list_input()).
	row.gui_input.connect(_on_list_input)
	row.pressed.connect(func() -> void:
		var key := str(line.get_meta("key", ""))
		if key != "" and not dragging:
			open_detail(key))
	return row

## A flat speaker button (BonStyle's icon) that says the word `key_of` returns. STOP, like the
## row star: a press says the word and never opens the detail; the wheel still scrolls the list.
func _speaker_button(key_of: Callable) -> Button:
	var speaker := Button.new()
	speaker.name = "Say"
	speaker.flat = true
	speaker.focus_mode = Control.FOCUS_NONE
	speaker.mouse_filter = Control.MOUSE_FILTER_STOP
	speaker.gui_input.connect(_on_list_input)
	speaker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	speaker.icon = BonStyle.icon_texture("speaker", 128)
	speaker.expand_icon = true
	speaker.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		speaker.add_theme_color_override(state, Color.WHITE)
	speaker.tooltip_text = UiText.t("card.say")
	speaker.pressed.connect(func() -> void:
		if not dragging:
			say(key_of.call()))
	return speaker

## Spoken words are switched on (sounds.json "voice"); otherwise no speaker column.
func voices_on() -> bool:
	var sound = Sound.shared()
	return sound != null and sound.voice_enabled()

func can_say(key: String) -> bool:
	var sound = Sound.shared()
	return key != "" and sound != null and sound.has_voice(key, Lexicon.shared().foreign)

## Says `key` in the language being learned (nothing without a clip).
func say(key: String) -> void:
	if can_say(key):
		Sound.shared().say_word(key, Lexicon.shared().foreign)

## A speaker that is there for this word, or an empty cell that keeps the column.
func _show_speaker(speaker: Button, key: String) -> void:
	var ok := can_say(key)
	speaker.disabled = not ok
	speaker.modulate.a = 1.0 if ok else 0.0
	speaker.mouse_filter = Control.MOUSE_FILTER_STOP if ok else Control.MOUSE_FILTER_IGNORE

func _build_detail() -> void:
	detail = VBoxContainer.new()
	detail.name = "Word detail"
	detail.visible = false
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	add_child(detail)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	detail.add_child(top)
	back_button = _button(close_detail)
	back_button.name = "Back"
	style_button(back_button, "plain")
	top.add_child(back_button)
	detail_picture = TextureRect.new()
	detail_picture.name = "Picture"
	detail_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(detail_picture)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	top.add_child(names)
	detail_foreign = Label.new()
	detail_foreign.add_theme_color_override("font_color", FOREIGN)
	names.add_child(detail_foreign)
	detail_reading = PinyinText.style(Label.new())
	detail_reading.add_theme_color_override("font_color", HINT)
	names.add_child(detail_reading)
	detail_native = Label.new()
	detail_native.add_theme_color_override("font_color", TEXT)
	names.add_child(detail_native)
	detail_star = Button.new()
	detail_star.flat = true
	detail_star.focus_mode = Control.FOCUS_NONE
	detail_star.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	detail_star.add_theme_color_override("font_color", GOLD)
	detail_star.add_theme_color_override("font_hover_color", GOLD.lightened(0.25))
	detail_star.pressed.connect(func() -> void: bookmark_toggled.emit(detail_key))
	detail_speaker = _speaker_button(func() -> String: return detail_key)
	detail_speaker.name = "Say word"
	top.add_child(detail_speaker)
	top.add_child(detail_star)
	detail_tiles = HBoxContainer.new()
	detail_tiles.add_theme_constant_override("separation", 10)
	detail.add_child(detail_tiles)
	for i in 4:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = BonStyle.SKY
		style.border_color = BonStyle.RIM
		style.set_border_width_all(3)
		style.set_corner_radius_all(10)
		tile.add_theme_stylebox_override("panel", style)
		var stack := VBoxContainer.new()
		tile.add_child(stack)
		for j in 2:
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", HINT if j == 0 else TEXT)
			stack.add_child(label)
		detail_tiles.add_child(tile)
	var games_card := PanelContainer.new()
	games_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	games_card.add_theme_stylebox_override("panel", _style(FRAME, BUTTON_EDGE, 18, 14, 10))
	detail.add_child(games_card)
	var games_scroll := ScrollContainer.new()
	games_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	games_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	games_card.add_child(games_scroll)
	var games_stack := VBoxContainer.new()
	games_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	games_scroll.add_child(games_stack)
	detail_games = GridContainer.new()
	detail_games.name = "Games"
	detail_games.columns = 4
	detail_games.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	games_stack.add_child(detail_games)
	detail_empty = Label.new()
	detail_empty.add_theme_color_override("font_color", DIM)
	games_stack.add_child(detail_empty)
	detail_hint = Label.new()
	detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_hint.add_theme_color_override("font_color", HINT)
	detail.add_child(detail_hint)

# --- Data ------------------------------------------------------------------------------------

## New data from the journal (opening it, a language change, a studied word, a view switch).
func set_data(new_studied: Dictionary, new_dictionary: Dictionary, new_categories: Dictionary, new_areas: Dictionary, new_area_names: Dictionary, new_bookmarks: Dictionary, new_by_area: bool) -> void:
	studied = new_studied
	dictionary = new_dictionary
	categories = new_categories
	areas = new_areas
	area_names = new_area_names
	bookmarks = new_bookmarks
	by_area = new_by_area
	var lexicon = Lexicon.shared()
	var log = PracticeLog.shared()
	var memory = WordMemory.shared()
	words.clear()
	for key in dictionary:
		var foreign := UiText.word(str(key), lexicon.foreign)
		var native := UiText.word(str(key), lexicon.native)
		var entry: Dictionary = log.totals(lexicon.foreign, str(key))
		entry.foreign = foreign
		entry.native = native
		entry.search = fold(foreign + "\n" + native)
		entry.known = memory.is_known(str(key))
		words[str(key)] = entry
	_refresh_texts()
	rebuild()
	if detail_key != "":
		if words.has(detail_key):
			_render_detail()
		else:
			close_detail()

## Lower case without accents, so "cafe" finds "café".
static func fold(text: String) -> String:
	var out := ""
	for c in text.to_lower():
		out += UiText.FOLD.get(c, c)
	return out

## {game id: {positive, negative, translated}} of one word in the current foreign language.
func games_for(key: String) -> Dictionary:
	return PracticeLog.shared().games_for(Lexicon.shared().foreign, key)

## A readable game name (data/phrases.json games.<id>); the id when there is none.
static func game_name(id: String) -> String:
	return UiText.t("games." + id) if UiText.has("games." + id) else id

## How many of the journal's words are known (word_memory.gd is_known()).
func known_total() -> int:
	return words.keys().filter(func(k): return bool(words[k].get("known", false))).size()

## The small daisy that marks a known word, for a picture cell (its parent): bottom-right corner,
## hidden until show_known() turns it on. Shared so other journal views can mark known words.
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

func filter_count(id: String) -> int:
	match id:
		"studied":
			return words.keys().filter(func(k): return studied.has(k)).size()
		"saved":
			return words.keys().filter(func(k): return bookmarks.has(k)).size()
	return words.size()

func matches(key: String) -> bool:
	if filter == "studied" and not studied.has(key):
		return false
	if filter == "saved" and not bookmarks.has(key):
		return false
	if not chosen_categories.is_empty() and not chosen_categories.has(str(categories.get(key, "Everyday"))):
		return false
	if not chosen_areas.is_empty() and not area_keys.has(key):
		return false
	var needle := fold(query.strip_edges())
	return needle == "" or str(words[key].search).contains(needle)

func _compare(a: String, b: String) -> bool:
	var wa: Dictionary = words[a]
	var wb: Dictionary = words[b]
	match sort:
		"right":
			if wa.positive != wb.positive: return wa.positive > wb.positive
		"wrong":
			if wa.negative != wb.negative: return wa.negative > wb.negative
		"native":
			var n: int = str(wa.native).naturalnocasecmp_to(str(wb.native))
			if n != 0: return n < 0
	var c: int = str(wa.foreign).naturalnocasecmp_to(str(wb.foreign))
	return c < 0 if c != 0 else a < b

## Rebuilds the flattened table from the filters (cheap: no controls are made here).
func rebuild() -> void:
	for id in FILTERS:
		filter_buttons[id].set_pressed_no_signal(id == filter)
	var groups: Dictionary = {}
	var names: Dictionary = {}
	var totals: Dictionary = {}
	if by_area:
		for area in areas:
			# Ticked areas only show their own sections.
			if not chosen_areas.is_empty() and not chosen_areas.has(str(area)):
				continue
			var keys: Array = []
			var found := 0
			for key in areas[area]:
				if not words.has(str(key)): continue
				keys.append(str(key))
				if studied.has(str(key)): found += 1
			groups[area] = keys
			names[area] = UiText.named("places", str(area_names.get(area, area)))
			totals[area] = [found, keys.size()]
	else:
		for key in words:
			var group := str(categories.get(key, "Everyday"))
			if not groups.has(group):
				groups[group] = []
				names[group] = UiText.named("categories", group)
			groups[group].append(key)
	var ordered: Array = groups.keys()
	ordered.sort_custom(func(a, b): return str(names[a]).naturalnocasecmp_to(str(names[b])) < 0)
	items.clear()
	var unique: Dictionary = {}
	for group in ordered:
		var keys: Array = groups[group].filter(matches)
		if keys.is_empty():
			continue
		keys.sort_custom(_compare)
		var title := str(names[group])
		if by_area:
			title = UiText.t("journal.area_count", {"name": title, "found": totals[group][0], "total": totals[group][1]})
		items.append({"heading": title})
		for key in keys:
			items.append({"key": key})
			unique[key] = true
	shown_words = unique.size()
	footer.text = UiText.t("journal.showing", {"shown": shown_words, "total": words.size()}) if shown_words > 0 else UiText.t("journal.no_match")
	var known := known_total()
	if shown_words > 0 and known > 0:
		footer.text += "  ·  " + UiText.t("journal.known_count", {"n": known})
	# The Saved tab with nothing saved explains how to save a word.
	var nothing_saved: bool = filter == "saved" and filter_count("saved") == 0
	empty_label.visible = items.is_empty()
	empty_label.text = UiText.t("bookmarks.empty") if nothing_saved else UiText.t("journal.no_match")
	if nothing_saved:
		footer.text = ""
	for id in FILTERS:
		filter_buttons[id].text = UiText.t("journal.filter_" + id, {"n": filter_count(id)})
	scroll.value = 0.0
	_layout_rows()

## Re-draws the visible rows only (a bookmark changed).
func refresh_rows() -> void:
	for id in FILTERS:
		filter_buttons[id].text = UiText.t("journal.filter_" + id, {"n": filter_count(id)})
	if filter == "saved":
		var top := scroll.value
		rebuild()
		scroll.value = minf(top, scroll.max_value)
	_draw_rows()
	if detail_key != "":
		_render_detail()

func _refresh_texts() -> void:
	var lexicon = Lexicon.shared()
	var foreign_name := UiText.t("language." + lexicon.foreign)
	var native_name := UiText.t("language." + lexicon.native)
	search.placeholder_text = UiText.t("journal.search", {"foreign": foreign_name, "native": native_name})
	var found: Dictionary = {}
	for key in words:
		found[str(categories.get(key, "Everyday"))] = true
	var category_choices: Array = []
	for name in found:
		category_choices.append([name, UiText.named("categories", name)])
	_fill_choice_menu(category_menu, UiText.t("journal.all_categories"), category_choices)
	var area_choices: Array = []
	for area in areas:
		area_choices.append([str(area), UiText.named("places", str(area_names.get(area, area)))])
	_fill_choice_menu(area_menu, UiText.t("journal.all_areas"), area_choices)
	_collect_area_keys()
	sort_menu.clear()
	sort_menu.add_item(UiText.t("journal.sort_by", {"lang": foreign_name}))
	sort_menu.add_item(UiText.t("journal.sort_by", {"lang": native_name}))
	sort_menu.add_item(UiText.t("journal.sort_right"))
	sort_menu.add_item(UiText.t("journal.sort_wrong"))
	sort_menu.select(SORTS.find(sort))
	var cells := header.get_children()
	cells[2].text = foreign_name
	cells[3].text = native_name
	cells[4].text = UiText.t("journal.col_studied")
	cells[5].text = UiText.t("journal.col_right")
	cells[6].text = UiText.t("journal.col_wrong")
	scores_button.text = UiText.t("journal.scores")
	scores_button.tooltip_text = UiText.t("journal.hide_scores" if show_scores else "journal.show_scores")
	back_button.text = UiText.t("journal.back")
	detail_hint.text = UiText.t("journal.detail_hint")
	detail_empty.text = UiText.t("journal.no_games")
	_apply_columns(header)

func set_filter(id: String) -> void:
	filter = id
	rebuild()

func _on_filter(id: String) -> void:
	set_filter(id)

func set_show_scores(value: bool) -> void:
	show_scores = value
	scores_button.set_pressed_no_signal(show_scores)
	scores_button.icon = UiIcons.texture("check" if show_scores else "box", roundi(22 * factor))
	scores_button.tooltip_text = UiText.t("journal.hide_scores" if show_scores else "journal.show_scores")
	_apply_columns(header)
	for row in rows:
		_apply_columns(row.get_meta("line"))

func _apply_columns(line: HBoxContainer) -> void:
	var cells := line.get_children()
	for i in SCORE_CELLS:
		cells[i].visible = show_scores
	cells[SPEAKER_CELL].visible = voices_on()

# --- Virtual rows ----------------------------------------------------------------------------

func row_height() -> float:
	return roundf(ROW_HEIGHT * factor)

## Makes enough pooled rows for the visible height and places them.
func _layout_rows() -> void:
	var height := row_height()
	var needed := int(ceil(list_area.size.y / height)) + 1
	while rows.size() < needed:
		var row := _make_row(false)
		list_area.add_child(row)
		_scale_row(row)
		_apply_columns(row.get_meta("line"))
		rows.append(row)
	while rows.size() > needed:
		var row: Control = rows.pop_back()
		row.queue_free()
	scroll.max_value = items.size() * height
	scroll.page = list_area.size.y
	scroll.step = 1.0
	scroll.custom_step = height
	scroll.visible = scroll.max_value > scroll.page
	header_gap.visible = scroll.visible
	_draw_rows()

func _draw_rows() -> void:
	var height := row_height()
	var first := int(floor(scroll.value / height))
	var offset := -fmod(scroll.value, height)
	header.get_child(SPEAKER_CELL).visible = voices_on()
	for i in rows.size():
		var row: Button = rows[i]
		var index := first + i
		row.position = Vector2(0, offset + i * height)
		row.size = Vector2(list_area.size.x, height)
		var line: HBoxContainer = row.get_meta("line")
		var heading: Label = row.get_meta("heading")
		if index >= items.size():
			row.visible = false
			continue
		row.visible = true
		var item: Dictionary = items[index]
		row.get_meta("stripe").visible = index % 2 == 1 and not item.has("heading")
		if item.has("heading"):
			line.visible = false
			line.set_meta("key", "")
			heading.visible = true
			heading.text = item.heading
			row.disabled = true
			row.mouse_default_cursor_shape = Control.CURSOR_ARROW
			continue
		var key := str(item.key)
		var word: Dictionary = words[key]
		line.visible = true
		line.set_meta("key", key)
		heading.visible = false
		row.disabled = false
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.name = "Row " + key
		var cells := line.get_children()
		var saved := bookmarks.has(key)
		cells[0].text = "★" if saved else "☆"
		cells[0].tooltip_text = UiText.t("card.unsave" if saved else "card.save")
		_show_picture(cells[1], key)
		show_known(cells[1], bool(word.get("known", false)), factor)
		cells[2].text = word.foreign
		cells[3].text = word.native
		cells[4].text = "✓" if studied.has(key) else "–"
		cells[4].add_theme_color_override("font_color", RIGHT if studied.has(key) else DIM)
		cells[5].text = str(word.positive)
		cells[5].add_theme_color_override("font_color", RIGHT if word.positive > 0 else DIM)
		cells[6].text = str(word.negative)
		cells[6].add_theme_color_override("font_color", WRONG if word.negative > 0 else DIM)
		# Rows made before the sound service existed did not know whether voices are on.
		cells[SPEAKER_CELL].visible = voices_on()
		_show_speaker(cells[SPEAKER_CELL], key)

## Shows `key`'s picture in `rect` (now or once drawn); empty without the picture maker or one.
func _show_picture(rect: TextureRect, key: String) -> bool:
	var pictures = WordPictures.shared()
	if pictures == null:
		rect.texture = null
		return false
	return pictures.fill(rect, key)

## Wheel and drag scrolling for the list area and every row, star and speaker in it (a touch
## arrives as the left mouse button). Positions are taken in viewport pixels, since the row under
## the finger is reused for other words while the list moves. The press itself is left to the
## button, which only acts on release when the press stayed a tap (`dragging` false).
func _on_list_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_drag_from = button.global_position
				_drag_scroll = scroll.value
				_drag_held = true
				dragging = false
			else:
				_drag_held = false
				# Cleared after the button's own release has run (its pressed signal checks it).
				if dragging:
					(func() -> void: dragging = false).call_deferred()
			return
		if not button.pressed:
			return
		var step := row_height() * 3.0
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll.value -= step
			accept_event()
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll.value += step
			accept_event()
	elif event is InputEventMouseMotion and _drag_held:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT == 0:
			_drag_held = false
			return
		var travel := motion.global_position.y - _drag_from.y
		if not dragging and absf(travel) >= maxf(DRAG_SLOP_MIN, DRAG_SLOP * factor):
			dragging = true
		if dragging:
			scroll.value = _drag_scroll - travel
			accept_event()

## The row control showing `key`, or null when it is scrolled out of view (for checks).
func row_for(key: String) -> Control:
	for row in rows:
		if row.visible and str(row.get_meta("line").get_meta("key", "")) == key:
			return row
	return null

## Scrolls so the first row of `key` is at the top (checks and renders).
func scroll_to(key: String) -> void:
	for i in items.size():
		if str(items[i].get("key", "")) == key:
			scroll.value = minf(i * row_height(), maxf(0.0, scroll.max_value - scroll.page))
			return

# --- Detail view -----------------------------------------------------------------------------

func open_detail(key: String) -> void:
	if not words.has(key):
		return
	detail_key = key
	search.release_focus()
	table.visible = false
	detail.visible = true
	_render_detail()

func close_detail() -> void:
	detail_key = ""
	detail.visible = false
	table.visible = true
	_draw_rows()

func is_detail_open() -> bool:
	return detail.visible

func _render_detail() -> void:
	var key := detail_key
	var word: Dictionary = words[key]
	var lexicon = Lexicon.shared()
	detail_foreign.text = word.foreign
	detail_picture.visible = _show_picture(detail_picture, key)
	PinyinText.show(detail_reading, {"foreign": word.foreign})
	detail_native.text = word.native + "  ·  " + UiText.named("categories", str(categories.get(key, "Everyday")))
	if bool(word.get("known", false)):
		detail_native.text += "  ·  " + UiText.t("journal.known_tag")
	var saved := bookmarks.has(key)
	detail_star.text = "★" if saved else "☆"
	detail_speaker.visible = can_say(key)
	detail_star.tooltip_text = UiText.t("card.unsave" if saved else "card.save")
	var games := games_for(key)
	var sums := {"positive": 0, "negative": 0, "translated": 0}
	for game in games:
		for outcome in PracticeLog.OUTCOMES:
			sums[outcome] += int(games[game].get(outcome, 0))
	var tiles := [
		[UiText.t("journal.col_studied"), "✓" if studied.has(key) else "–", RIGHT if studied.has(key) else DIM],
		[UiText.t("journal.col_right"), str(sums.positive), RIGHT],
		[UiText.t("journal.col_wrong"), str(sums.negative), WRONG],
		[UiText.t("journal.col_translated"), str(sums.translated), TRANSLATED]]
	for i in 4:
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
			_detail_cell(heads[i], HEADING, i == 0)
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
	label.add_theme_font_size_override("font_size", roundi(18 * factor))
	if first:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size.x = 130 * factor
	detail_games.add_child(label)

# --- Scaling ---------------------------------------------------------------------------------

func _font(node: Control, size: float) -> void:
	node.add_theme_font_size_override("font_size", roundi(size * factor))

func _scale_row(row: Control) -> void:
	var line: HBoxContainer = row.get_meta("line") if row.has_meta("line") else row
	line.add_theme_constant_override("separation", roundi(10 * factor))
	for cell in line.get_children():
		if cell == header_gap:
			continue
		var width: float = cell.get_meta("base_width", 0.0)
		cell.custom_minimum_size.x = width * factor
		if cell is TextureRect:
			continue
		_font(cell, 22.0 if cell is Button else 19.0)
	if row.has_meta("heading"):
		_font(row.get_meta("heading"), 18)

## Window scale min(height / 800, width / 1100), set by the HUD's layout.
func apply_scale(f: float) -> void:
	if is_equal_approx(f, factor) and not rows.is_empty():
		return
	factor = f
	for entry in scaled_styles:
		_scale_style(entry)
	add_theme_constant_override("separation", roundi(8 * f))
	table.add_theme_constant_override("separation", roundi(12 * f))
	tab_bar.add_theme_constant_override("separation", roundi(8 * f))
	tools.add_theme_constant_override("separation", roundi(10 * f))
	var icon_px := roundi(22 * f)
	for id in filter_buttons:
		var button: Button = filter_buttons[id]
		_font(button, 18)
		button.custom_minimum_size = Vector2(0, 48 * f)
		button.icon = UiIcons.texture(FILTER_ICONS[id], icon_px)
		button.add_theme_constant_override("h_separation", roundi(8 * f))
	_font(search, 18)
	search.custom_minimum_size = Vector2(200 * f, 48 * f)
	search.right_icon = UiIcons.texture("look", icon_px)
	for menu in [category_menu, area_menu, sort_menu]:
		_font(menu, 17)
		menu.custom_minimum_size = Vector2(150 * f, 48 * f)
		menu.get_popup().add_theme_font_size_override("font_size", roundi(18 * f))
		menu.get_popup().add_theme_constant_override("v_separation", roundi(10 * f))
	_font(scores_button, 17)
	scores_button.custom_minimum_size = Vector2(0, 48 * f)
	scores_button.icon = UiIcons.texture("check" if show_scores else "box", icon_px)
	for menu in [category_menu, area_menu]:
		menu.icon = UiIcons.texture("down", icon_px)
	_scale_row(header)
	for cell in header.get_children():
		_font(cell, 15)
	header.custom_minimum_size.y = 32 * f
	scroll.custom_minimum_size.x = SCROLL_WIDTH * f
	# The row HBox gap plus the scroll bar, less the header's own gap before this spacer.
	header_gap.custom_minimum_size.x = SCROLL_WIDTH * f - 10 * f
	_font(footer, 15)
	_font(hint, 15)
	_font(empty_label, 20)
	for row in rows:
		_scale_row(row)
	# Buttons rebuilt elsewhere (filter menus) may have been freed since they were styled.
	styled_buttons = styled_buttons.filter(func(entry: Array) -> bool: return is_instance_valid(entry[0]))
	for entry in styled_buttons:
		_style_one(entry[0])
	_layout_rows()
	_scale_detail()

func _scale_detail() -> void:
	var f := factor
	_font(back_button, 18)
	back_button.icon = UiIcons.texture("back", roundi(22 * f))
	back_button.add_theme_constant_override("h_separation", roundi(8 * f))
	back_button.custom_minimum_size = Vector2(130 * f, 52 * f)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_font(detail_foreign, 34)
	_font(detail_reading, 20)
	_font(detail_native, 20)
	_font(detail_star, 34)
	detail_picture.custom_minimum_size = Vector2.ONE * DETAIL_PICTURE * f
	detail_star.custom_minimum_size = Vector2(60, 60) * f
	detail_star.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	detail_speaker.custom_minimum_size = Vector2(60, 60) * f
	detail_speaker.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for tile in detail_tiles.get_children():
		(tile.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(10 * f)
		var labels: Array = tile.get_child(0).get_children()
		_font(labels[0], 16)
		_font(labels[1], 32)
	detail_games.add_theme_constant_override("h_separation", roundi(12 * f))
	detail_games.add_theme_constant_override("v_separation", roundi(8 * f))
	for cell in detail_games.get_children():
		_font(cell, 18)
		if cell.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			cell.custom_minimum_size.x = 130 * f
	_font(detail_empty, 18)
	_font(detail_hint, 15)
