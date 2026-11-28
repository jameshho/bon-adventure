extends Control
## The Passport (user, 21 Nov 2026; guide: docs/guides/ACHIEVEMENTS.md#the-passport): a corner
## button (top right, left of the map) opens a window with three pages.
##   Missions     the three town missions (missions.gd): who, what, where, the XP, "Go there"
##                (the guide arrow to the game, guide_arrow.gd); a done one is grey with a check
##                and "A new mission in 9:59", counting down every second while open.
##   Town stamps  every placed stamp (achievements.gd "stamps"): a progress bar, then the coin
##                face when collected, a faded coin with "?" and the place before.
##   Exploration  the achievement log: Things to do, Games, Missions (a ✓ or "2 / 5" each) and
##                Diary (the newest log lines with their times). Pages fit without scroll bars.
## Built like the minigame picker (game_launcher.gd) in the game's own look (UI_STYLE.md,
## bon_style.gd; the user's passport mockup gave the content, not the look, 21 Nov 2026).
## Scales with min(height / 800, width / 1100); every button is at least 52 px for a finger.
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
const Missions := preload("res://scripts/learning/missions.gd")
const Board := preload("res://scripts/learning/activity_board.gd")

## Esc and ✕ (Main's popup stack, minigame_wiring.gd PANELS).
signal close_requested

const PAGES := ["missions", "stamps", "explore"]
const LOG_PAGES := ["explore", "games", "missions", "diary"]
const DIARY_LINES := 9
const FILL := BonStyle.SKY
const LINE := BonStyle.RIM
const ROW := BonStyle.SKY_TOP
const TEXT := BonStyle.INK
const MUTED := BonStyle.INK_SOFT
const DONE_FILL := Color("e4ecec")
## The town coin (stamp_coin.gd uses the same picture) and its gold.
const COIN_FACE := preload("res://assets/stamps/coin_face.svg")
const COIN_GOLD := Color("f2b632")
const COIN_RIM := Color("f2c75c")

var main
var corner_button: Button
var window: PanelContainer
var _shade: ColorRect
var _title: Label
var _xp: Label
var _close: Button
var _tabs: Dictionary = {}
var _page := "missions"
var _log_page := "explore"
var _body: VBoxContainer
var _factor := 1.0
var _tick := 0.0
## Countdown labels of done mission slots (slot index -> Label), refreshed each second.
var _countdowns: Dictionary = {}

func setup(game) -> void:
	main = game
	name = "Passport"
	theme = BonStyle.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_shade = ColorRect.new()
	_shade.color = BonStyle.SHADE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	window = PanelContainer.new()
	window.add_theme_stylebox_override("panel", _card(FILL, LINE, 30))
	add_child(window)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	window.add_child(stack)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	stack.add_child(head)
	_title = _label(TEXT)
	head.add_child(_title)
	_xp = _label(BonStyle.BROWN)
	_xp.name = "XP"
	_xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_xp)
	for page in PAGES:
		var tab := _button("", "", func() -> void: show_page(page))
		tab.name = "Tab " + page
		head.add_child(tab)
		_tabs[page] = tab
	_close = _button("", "close", close_requested.emit)
	head.add_child(_close)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	stack.add_child(_body)
	close_requested.connect(close)
	corner_button = Button.new()
	corner_button.name = "Passport button"
	corner_button.focus_mode = Control.FOCUS_NONE
	corner_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	corner_button.icon = UiIcons.texture("passport", 128)
	corner_button.expand_icon = true
	corner_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.hud.style_corner_button(corner_button)
	corner_button.pressed.connect(toggle)
	main.hud.ui_root.add_child(corner_button)
	# Its name under it for touch players (P3-16, 25 Nov 2026).
	main.hud.add_name_tag(corner_button, "passport.title")
	get_viewport().size_changed.connect(_layout)
	var missions = Missions.shared()
	missions.changed.connect(func() -> void:
		if visible:
			_rebuild())
	missions.completed.connect(_on_mission_done)
	_layout()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open(page := "") -> void:
	if page != "":
		_page = page
	Missions.shared().refresh()
	visible = true
	_rebuild()
	main.sync_player_controls()

func close() -> void:
	visible = false
	main.sync_player_controls()

## Texts in the native language again (language change; minigame_wiring.gd PANELS).
func refresh_display() -> void:
	if visible:
		_rebuild()

func show_page(page: String) -> void:
	_page = page
	_rebuild()

func _on_mission_done(_slot: int, game: String, xp: int) -> void:
	main.hud.flash_quest_message(UiText.t("passport.mission_done", {"mission": UiText.t("missions." + game), "n": xp}))

func _process(delta: float) -> void:
	var hud = main.hud
	corner_button.visible = not visible and Board.shared().running_id == "" \
			and not hud.tutorial_hidden.get("passport", false) \
			and not (hud.is_map_open() or hud.is_journal_open() or hud.is_help_open()) \
			and not hud.cluster_hidden(corner_button)
	if not visible:
		return
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		var missions = Missions.shared()
		var before: Array = missions.slots.map(func(s): return str(s.game))
		missions.refresh()
		if missions.slots.map(func(s): return str(s.game)) == before:
			for i in _countdowns:
				_countdowns[i].text = _wait_text(missions.seconds_left(i))
	_place()

# --- Pages ------------------------------------------------------------------------------------

func _rebuild() -> void:
	_countdowns.clear()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var tracker = Achievements.shared()
	_title.text = UiText.t("passport.title")
	_xp.text = UiText.t("passport.xp_total", {"n": tracker.xp()})
	for page in PAGES:
		var tab: Button = _tabs[page]
		tab.text = UiText.t("passport.tab_" + page)
		_style_choice(tab, page == _page)
	_close.tooltip_text = UiText.t("common.close") if UiText.has("common.close") else ""
	match _page:
		"missions":
			_build_missions()
		"stamps":
			_build_stamps()
		_:
			_build_log()
	_layout()

func _build_missions() -> void:
	var f := _factor
	var missions = Missions.shared()
	_body.add_child(_hint(UiText.t("passport.missions_hint")))
	for i in missions.slots.size():
		var game: String = missions.slots[i].game
		var done: bool = missions.is_done(i)
		var card := PanelContainer.new()
		card.name = "Mission %d" % i
		card.add_theme_stylebox_override("panel", _card(DONE_FILL if done else ROW, LINE, 22, 14.0 * f))
		_body.add_child(card)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", roundi(16 * f))
		card.add_child(line)
		var icon := _icon("check" if done else str(Achievements.GAME_ICONS.get(game, "play")), 64.0, MUTED if done else TEXT)
		line.add_child(icon)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", roundi(2 * f))
		line.add_child(words)
		var title := _label(MUTED if done else TEXT, 23)
		title.text = UiText.t("missions." + game)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(title)
		var about := _label(MUTED, 16)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if done:
			about.text = _wait_text(missions.seconds_left(i))
			_countdowns[i] = about
		else:
			about.text = UiText.t("missions_desc." + game)
		words.add_child(about)
		var reward := HBoxContainer.new()
		reward.add_theme_constant_override("separation", roundi(8 * f))
		words.add_child(reward)
		reward.add_child(_pill(UiText.t("passport.xp_reward", {"n": missions.xp_for(game)}), "star", done))
		if not Achievements.shared().is_unlocked("game." + game):
			reward.add_child(_pill(UiText.t("passport.first_time"), "", done))
		var side := VBoxContainer.new()
		side.alignment = BoxContainer.ALIGNMENT_CENTER
		side.add_theme_constant_override("separation", roundi(6 * f))
		side.custom_minimum_size = Vector2(230 * f, 0)
		line.add_child(side)
		var place := _label(MUTED, 16)
		place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place.text = UiText.t("games_host." + game) if UiText.has("games_host." + game) else ""
		place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		side.add_child(place)
		if done:
			var stamp := _label(BonStyle.GREEN_TEXT, 20)
			stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stamp.text = UiText.t("passport.done")
			side.add_child(stamp)
		else:
			var go := BonStyle.button(UiText.t("map.go"), "primary", "next", f, 22.0, Vector2(200, 60))
			go.name = "Go " + game
			go.custom_minimum_size.y = maxf(60.0 * f, 52.0)
			go.pressed.connect(func() -> void: go_there(game))
			side.add_child(go)

## Closes the passport and points the guide arrow at the mission's game (a waypoint).
func go_there(game: String) -> void:
	close()
	if main.guide != null:
		main.guide.go_to_game(game)

## Town stamps: a progress strip (a coin, "n / total" and a gold bar), then one card per stamp in
## a 6-wide grid. A found stamp shows the real coin face (coin_face.svg, the coin in the town) on
## a cream card with a gold rim; one still to find shows a faded coin with "?" and the place in
## muted letters, so the player knows where to look (user, 22 Nov 2026: "look better", "a coin
## logo like the actual design of the coin instead of a star").
func _build_stamps() -> void:
	var f := _factor
	var tracker = Achievements.shared()
	var ids: Array[String] = tracker.ids_in("stamps")
	var found: int = tracker.unlocked_in("stamps")
	# Progress strip.
	var strip := PanelContainer.new()
	strip.name = "Stamp progress"
	var strip_look := _card(BonStyle.CREAM, COIN_RIM, 22, 10.0 * f)
	strip_look.content_margin_left = 16 * f
	strip_look.content_margin_right = 20 * f
	strip.add_theme_stylebox_override("panel", strip_look)
	_body.add_child(strip)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", roundi(14 * f))
	strip.add_child(line)
	line.add_child(_coin(56.0, true))
	var count := _label(BonStyle.BROWN, 30)
	count.text = "%d / %d" % [found, ids.size()]
	line.add_child(count)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", roundi(6 * f))
	line.add_child(words)
	var hint := _hint(UiText.t("passport.stamps_hint", {"n": found, "total": ids.size()}))
	hint.add_theme_color_override("font_color", BonStyle.BROWN)
	words.add_child(hint)
	var bar := ProgressBar.new()
	bar.name = "Stamp bar"
	bar.show_percentage = false
	bar.max_value = maxi(1, ids.size())
	bar.value = found
	bar.custom_minimum_size = Vector2(0, 16 * f)
	var track := BonStyle.flat(BonStyle.CREAM_DEEP, roundi(8 * f), 0, false)
	var fill := BonStyle.flat(COIN_GOLD, roundi(8 * f), 0, false)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)
	words.add_child(bar)
	# The stamps.
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", roundi(12 * f))
	grid.add_theme_constant_override("v_separation", roundi(12 * f))
	_body.add_child(grid)
	for id in ids:
		var got: bool = tracker.is_unlocked(id)
		var cell := PanelContainer.new()
		cell.name = "Stamp " + id
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", _card(BonStyle.CREAM if got else DONE_FILL, COIN_RIM if got else LINE, 20, 8.0 * f))
		grid.add_child(cell)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", roundi(4 * f))
		cell.add_child(column)
		var coin := _coin(78.0, got)
		coin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(coin)
		var name_label := _label(BonStyle.BROWN if got else Color(MUTED, 0.75), 15)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text = tracker.title(id)
		name_label.custom_minimum_size = Vector2(0, 40 * f)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(name_label)

## The town coin's face (the same picture as the 3D coin); faded with a "?" when not found yet.
func _coin(px: float, got: bool) -> Control:
	var rect := TextureRect.new()
	rect.name = "Coin"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.custom_minimum_size = Vector2(px, px) * _factor
	rect.texture = COIN_FACE
	if got:
		return rect
	# self_modulate: the "?" on it keeps full colour.
	rect.self_modulate = Color(0.62, 0.78, 0.8, 0.32)
	var mark := _label(Color(MUTED, 0.85), roundi(px * 0.42))
	mark.text = "?"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.add_child(mark)
	return rect

func _build_log() -> void:
	var f := _factor
	var tracker = Achievements.shared()
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", roundi(8 * f))
	_body.add_child(bar)
	for page in LOG_PAGES:
		var group_page: String = page
		var tab := _button("", "", func() -> void:
			_log_page = group_page
			_rebuild())
		tab.name = "Log " + page
		var label := UiText.t("passport.log_" + page)
		if page != "diary":
			label += "  %d/%d" % [tracker.unlocked_in(page), tracker.ids_in(page).size()]
		tab.text = label
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_choice(tab, page == _log_page)
		tab.custom_minimum_size = Vector2(0, maxf(52.0 * f, 52.0))
		tab.add_theme_font_size_override("font_size", roundi(18 * f))
		bar.add_child(tab)
	if _log_page == "diary":
		_build_diary()
		return
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", roundi(10 * f))
	grid.add_theme_constant_override("v_separation", roundi(8 * f))
	_body.add_child(grid)
	for id in tracker.ids_in(_log_page):
		var got: bool = tracker.is_unlocked(id)
		var cell := PanelContainer.new()
		cell.name = "Achievement " + id
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", _card(ROW if got else DONE_FILL, LINE, 16, 8.0 * f))
		grid.add_child(cell)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", roundi(10 * f))
		cell.add_child(line)
		line.add_child(_icon(str(tracker.defs[id].get("icon", "star")), 34.0, TEXT if got else Color(MUTED, 0.5)))
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 0)
		line.add_child(words)
		var title := _label(TEXT if got else MUTED, 17)
		title.text = tracker.title(id)
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		words.add_child(title)
		var sub := _label(MUTED, 13)
		sub.text = tracker.hint(id)
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		words.add_child(sub)
		var mark := _label(BonStyle.GREEN_TEXT if got else MUTED, 17)
		var progress: Dictionary = tracker.progress(id)
		mark.text = "✓" if got else ("%d/%d" % [progress.have, progress.need] if int(progress.need) > 1 else "")
		line.add_child(mark)

func _build_diary() -> void:
	var tracker = Achievements.shared()
	var entries: Array = tracker.recent(DIARY_LINES)
	if entries.is_empty():
		_body.add_child(_hint(UiText.t("passport.diary_empty")))
		return
	for entry in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", roundi(14 * _factor))
		_body.add_child(row)
		var when := _label(MUTED, 15)
		when.text = Time.get_datetime_string_from_unix_time(int(entry.get("at", 0)) + _utc_offset(), true).substr(5, 11).replace("T", " ")
		when.custom_minimum_size = Vector2(130 * _factor, 0)
		row.add_child(when)
		var what := _label(TEXT, 17)
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		what.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		what.text = _diary_line(entry)
		row.add_child(what)

static func _utc_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60

## One log entry in words.
func _diary_line(entry: Dictionary) -> String:
	var tracker = Achievements.shared()
	var id := str(entry.get("id", ""))
	match str(entry.get("kind", "")):
		"unlock":
			return UiText.t("achievements.unlocked", {"name": tracker.title(id)})
		"xp":
			var reason := id
			if id.begins_with("mission."):
				reason = UiText.t("missions." + id.substr(8))
			elif tracker.defs.has(id):
				reason = tracker.title(id)
			return UiText.t("passport.diary_xp", {"n": int(entry.get("xp", 0)), "reason": reason})
		_:
			if id.begins_with("game."):
				return UiText.t("passport.diary_game", {"game": UiText.t("games." + id.substr(5))})
			if id == "mission":
				return UiText.t("passport.diary_mission")
			return id

func _wait_text(seconds: int) -> String:
	return UiText.t("passport.next_mission", {"time": "%d:%02d" % [seconds / 60, seconds % 60]})

# --- Parts and layout -------------------------------------------------------------------------

func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	_factor = BonStyle.factor(view)
	var f := _factor
	# Top right, left of the map button (the HUD's second row: journal, picker, map, passport).
	main.hud.size_corner_button(corner_button, main.hud.top_slot(3))
	var width := minf(1040.0 * f, view.x - 32.0)
	window.custom_minimum_size = Vector2(width, 0)
	window.size = Vector2(width, 0)
	_shade.position = Vector2.ZERO
	_shade.size = view
	_title.add_theme_font_size_override("font_size", roundi(30 * f))
	_xp.add_theme_font_size_override("font_size", roundi(20 * f))
	var tap := maxf(56.0 * f, 52.0)
	_close.custom_minimum_size = Vector2(tap, tap)
	for tab in _tabs.values():
		tab.custom_minimum_size = Vector2(0, tap)
		tab.add_theme_font_size_override("font_size", roundi(19 * f))
	_place.call_deferred()

## Fits the window to its content and centres it.
func _place() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var need: float = window.get_combined_minimum_size().y
	if absf(window.size.y - need) > 0.5:
		window.size = Vector2(window.size.x, need)
	window.position = Vector2(roundf((view.x - window.size.x) * 0.5), maxf(12.0, roundf((view.y - need) * 0.5)))

func _hint(text: String) -> Label:
	var hint := _label(MUTED, 17)
	hint.text = text
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return hint

## A small cream pill with an optional icon ("+30 XP").
func _pill(text: String, icon: String, dim: bool) -> PanelContainer:
	var f := _factor
	var pill := PanelContainer.new()
	var look := BonStyle.flat(BonStyle.CREAM if not dim else DONE_FILL, roundi(16 * f), maxi(1, roundi(2 * f)), false)
	look.content_margin_left = 10 * f
	look.content_margin_right = 12 * f
	look.content_margin_top = 2 * f
	look.content_margin_bottom = 2 * f
	pill.add_theme_stylebox_override("panel", look)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", roundi(4 * f))
	pill.add_child(line)
	if icon != "":
		line.add_child(_icon(icon, 20.0, Color("e0a514") if not dim else MUTED))
	var label := _label(BonStyle.BROWN if not dim else MUTED, 15)
	label.text = text
	line.add_child(label)
	return pill

func _icon(name_id: String, px: float, tint: Color) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.texture = UiIcons.texture(name_id, 96)
	rect.modulate = tint
	rect.custom_minimum_size = Vector2(px, px) * _factor
	return rect

func _card(fill: Color, outline: Color, corners: int, margin: float = 14.0) -> StyleBoxFlat:
	var card := BonStyle.flat(fill, corners, 4, false)
	card.border_color = outline
	card.set_content_margin_all(margin)
	return card

func _label(color: Color, size := 0) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	BonStyle.use_font(label, 700 if size >= 20 else 600)
	if size > 0:
		label.add_theme_font_size_override("font_size", roundi(size * _factor))
	return label

func _button(text: String, icon: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if icon != "":
		button.icon = UiIcons.texture(icon, 64)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 26)
	BonStyle.flat_button(button, ROW, 16, TEXT)
	button.pressed.connect(handler)
	return button

## A tab: green with white words when chosen (UI_STYLE.md toggles), the soft row colour otherwise.
func _style_choice(button: Button, chosen: bool) -> void:
	BonStyle.flat_button(button, BonStyle.GREEN_BOTTOM if chosen else ROW, 16, Color.WHITE if chosen else TEXT)
