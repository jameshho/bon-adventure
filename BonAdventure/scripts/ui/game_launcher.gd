extends Control
## The minigame picker (docs/guides/MINIGAMES.md#minigame-picker): the ▶ corner button and F9 open a
## window of every minigame in data/activities.json. Built as a test launcher on 9 Nov 2026,
## a player feature since 10 Nov 2026 (user): it shows in release builds and games played from
## it count toward practice like any other.
##
## Two tabs by "kind": learning games and pastimes ("Just for fun"). Each game is a tile (icon,
## its short name games.<id>, who and where games_host.<id>); a tap selects it and the detail
## bar below shows what it practises (games_learn.<id>), the rounds stepper (1–30, starting at
## the data's number; "no rounds" for endless games) and Play. Play closes the window, puts the
## player in front of the game's NPC and starts the game at once through its NPC host
## (minigame_host.gd launch()): no offer roll, no greeting. While that game runs its rounds are
## the chosen number (activity_board.gd set_rounds()), undone when the game is over.
##
## Games whose building is left out by dev_focus.txt show "Building not loaded"; a game whose
## building nearby loading has not built yet (nearby_units.gd, phones) can be played: Play builds
## it first (a short freeze), then starts the game as usual. Only one
## game at a time: Play is off while any minigame runs or the player is in a vehicle.
const Board := preload("res://scripts/learning/activity_board.gd")
## Levels and stars (18 Nov 2026): a tile shows the level and its best stars; the detail bar has a
## level stepper over the unlocked levels (docs/guides/MINIGAMES.md#progression).
const Progress := preload("res://scripts/learning/game_progress.gd")
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")

## Esc and ✕ (Main's popup stack, minigame_wiring.gd PANELS).
signal close_requested

const MAX_ROUNDS := 30
## Seconds after Play before "the game is over" may be decided (a fade or the first line may
## take a moment to start).
const SETTLE := 0.6
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const COLUMNS := 3
# UI art style (18 Nov 2026, docs/guides/UI_STYLE.md): soft blue window and tiles with white rims,
# dark teal text; the chosen tile has a green rim.
const FILL := BonStyle.SKY
const LINE := BonStyle.RIM
const ROW := BonStyle.SKY_TOP
const ROW_HOVER := BonStyle.RIM
const TEXT := BonStyle.INK
const MUTED := BonStyle.INK_SOFT
const GOLD := BonStyle.GREEN_BOTTOM
## Each game's tile icon (ui_icons.gd); "play" for a game not listed.
const ICONS := {
	"shop_supermarket": "cart", "family_dr_li": "family",
	"warehouse_ramon": "lift", "flight_bruno": "takeoff", "restaurant_twinkle": "cloche",
	"grammar_lana": "pencil", "lineup_rocco": "look", "evidence_mimi": "squeeze",
	"mystery_luna": "door", "library_rosa": "book", "teller_bank": "money", "mahjong_mei": "tiles", "radar_patrol": "radar", "electrical_box": "bolt",
}
## Games with no rounds to choose (one endless game or one puzzle; the library's book sorting is
## one cart of 3-6 books, 13 Nov 2026): no stepper, and launch() sets no rounds, so the data
## counts. Mahjong (user, 15 Nov 2026): no set number of hands from the picker either; the
## result card always offers Play again, as at Mei's table.
const ENDLESS := ["radar_patrol", "electrical_box", "library_rosa", "mahjong_mei"]
const KINDS := ["learning", "pastime"]

var main
## Whether the picker is offered (every build since 10 Nov 2026; kept for the checks).
var enabled := true
## The corner button (in the HUD's ui_root).
var corner_button: Button
var window: PanelContainer
var _title: Label
var _close: Button
var _tabs: Dictionary = {}      # kind -> tab Button
var _grids: Dictionary = {}     # kind -> GridContainer of tiles
var _tab := "learning"
## kind -> the selected game id on that tab.
var _picked: Dictionary = {}
## Activity id -> chosen rounds (this run of the game only).
var chosen: Dictionary = {}
## The game started from here and still running ("" when none).
var testing := ""
var _since := 0.0
## One entry per game: {id, kind, tile, icon, title, host}.
var _rows: Array = []
var _factor := 1.0
var _shade: ColorRect
# The detail bar.
var _detail: PanelContainer
var _d_icon: TextureRect
var _d_name: Label
var _d_host: Label
var _d_learn: Label
var _d_status: Label
var _d_rounds: VBoxContainer
var _d_rounds_label: Label
var _d_endless: Label
var minus: Button
var plus: Button
var count: Label
var _d_level: VBoxContainer
var _d_level_label: Label
var level_minus: Button
var level_plus: Button
var level_count: Label
var play: Button
## "Go there" (wayfinding, 18 Nov 2026): guides the player to the selected game on foot with the
## guide arrow (guide_arrow.gd) instead of starting it here.
var go: Button

func setup(game) -> void:
	main = game
	name = "GameLauncher"
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
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	for kind in KINDS:
		var tab := _button("", "", func() -> void: _show_tab(kind))
		tab.name = "Tab " + kind
		head.add_child(tab)
		_tabs[kind] = tab
	_close = _button("", "close", close_requested.emit)
	head.add_child(_close)
	for kind in KINDS:
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		stack.add_child(grid)
		_grids[kind] = grid
	_detail = PanelContainer.new()
	stack.add_child(_detail)
	_build_detail()
	close_requested.connect(close)
	corner_button = Button.new()
	corner_button.name = "Minigame launcher"
	corner_button.focus_mode = Control.FOCUS_NONE
	corner_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	corner_button.icon = UiIcons.texture("play", 128)
	corner_button.expand_icon = true
	corner_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.hud.style_corner_button(corner_button)
	corner_button.pressed.connect(toggle)
	main.hud.ui_root.add_child(corner_button)
	# Its key (F9) in a hint circle while playing with a keyboard (vocabulary_hud.gd, 24 Nov 2026).
	main.hud.add_key_hint(corner_button, "games")
	get_viewport().size_changed.connect(_layout)
	refresh_display()

## The bar under the tiles: the selected game, its rounds and Play.
func _build_detail() -> void:
	_detail.add_theme_stylebox_override("panel", _card(ROW, LINE, 18))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	_detail.add_child(line)
	_d_icon = _icon_rect()
	line.add_child(_d_icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	line.add_child(info)
	_d_name = _label(TEXT)
	_d_host = _label(MUTED)
	_d_learn = _label(TEXT)
	# One line (a wrapping label reports a tall size before its first layout).
	_d_learn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_d_learn.custom_minimum_size = Vector2(1, 0)
	_d_status = _label(GOLD)
	for label in [_d_name, _d_host, _d_learn, _d_status]:
		info.add_child(label)
	_d_rounds = VBoxContainer.new()
	_d_rounds.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(_d_rounds)
	_d_rounds_label = _label(MUTED)
	_d_rounds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_rounds.add_child(_d_rounds_label)
	var stepper := HBoxContainer.new()
	stepper.add_theme_constant_override("separation", 6)
	_d_rounds.add_child(stepper)
	minus = _button("", "minus", func() -> void: _step(_selected(), -1))
	count = _label(TEXT)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus = _button("", "plus", func() -> void: _step(_selected(), 1))
	stepper.add_child(minus)
	stepper.add_child(count)
	stepper.add_child(plus)
	_d_level = VBoxContainer.new()
	_d_level.name = "Level"
	_d_level.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(_d_level)
	_d_level_label = _label(MUTED)
	_d_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_level.add_child(_d_level_label)
	var level_stepper := HBoxContainer.new()
	level_stepper.add_theme_constant_override("separation", 6)
	_d_level.add_child(level_stepper)
	level_minus = _button("", "minus", func() -> void: _step_level(_selected(), -1))
	level_count = _label(TEXT)
	level_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_plus = _button("", "plus", func() -> void: _step_level(_selected(), 1))
	level_stepper.add_child(level_minus)
	level_stepper.add_child(level_count)
	level_stepper.add_child(level_plus)
	_d_endless = _label(MUTED)
	_d_endless.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_endless.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_child(_d_endless)
	go = _button("", "next", func() -> void: go_there(_selected()))
	go.name = "Go there"
	line.add_child(go)
	play = _button("", "play", func() -> void: launch(_selected()))
	play.name = "Play"
	play.add_theme_stylebox_override("normal", _card(BonStyle.GREEN_BOTTOM, LINE, 18))
	play.add_theme_stylebox_override("hover", _card(BonStyle.GREEN_BOTTOM.lightened(0.1), LINE, 18))
	play.add_theme_stylebox_override("pressed", _card(BonStyle.GREEN_BOTTOM.darkened(0.1), LINE, 18))
	for name in ["font_color", "font_hover_color", "font_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		play.add_theme_color_override(name, Color.WHITE)
	line.add_child(play)

# --- Opening and closing -------------------------------------------------------------------

func toggle() -> void:
	if visible:
		close()
	elif enabled and not main.hud.tutorial_hidden.get("picker", false):
		open()

func open() -> void:
	main.interaction.clear_card()
	refresh_display()
	# Above the clock and the HUD buttons, under the shade.
	get_parent().move_child(self, -1)
	visible = true
	main.sync_player_controls()

func close() -> void:
	visible = false
	main.sync_player_controls()

## Re-renders every text and tile (the window opens, the languages change).
func refresh_display() -> void:
	_title.text = UiText.t("launcher.open")
	_close.tooltip_text = UiText.t("launcher.open")
	corner_button.tooltip_text = UiText.t("launcher.open") + " (F9)"
	_d_rounds_label.text = UiText.t("launcher.rounds")
	_d_level_label.text = UiText.t("launcher.level")
	_d_endless.text = UiText.t("launcher.endless")
	play.text = UiText.t("launcher.play")
	go.text = UiText.t("map.go")
	_tabs["learning"].text = UiText.t("launcher.learning")
	_tabs["pastime"].text = UiText.t("launcher.pastimes")
	for grid in _grids.values():
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	_rows.clear()
	var board = Board.shared()
	for kind in KINDS:
		var ids: Array = board.activities.keys().filter(func(id): return board.kind(id) == kind)
		_tabs[kind].visible = not ids.is_empty()
		for id in ids:
			_grids[kind].add_child(_tile(str(id), kind))
		if not ids.has(_picked.get(kind, "")) and not ids.is_empty():
			_picked[kind] = str(ids[0])
	_show_tab(_tab)

## One game's tile: icon, name and who / where. A tap selects it.
func _tile(id: String, kind: String) -> Button:
	var tile := Button.new()
	tile.name = "Tile " + id
	tile.focus_mode = Control.FOCUS_NONE
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tile.pressed.connect(func() -> void: _select(id))
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(line)
	var icon := _icon_rect()
	icon.texture = UiIcons.texture(str(ICONS.get(id, "play")), 96)
	line.add_child(icon)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 0)
	line.add_child(names)
	var title := _label(TEXT)
	title.text = UiText.t("games." + id)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(title)
	var host := _label(MUTED)
	host.text = UiText.t("games_host." + id) if UiText.has("games_host." + id) else ""
	host.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(host)
	var row := {"id": id, "kind": kind, "tile": tile, "line": line, "icon": icon, "title": title, "host": host}
	# The level and its best stars (games with levels only).
	if Progress.shared().has_levels(id):
		var badge := VBoxContainer.new()
		badge.name = "Progress"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.alignment = BoxContainer.ALIGNMENT_CENTER
		badge.add_theme_constant_override("separation", 0)
		line.add_child(badge)
		row["level"] = _label(GOLD)
		row.level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(row.level)
		row["badge"] = badge
		_fill_badge(row)
	_rows.append(row)
	return tile

## A tile's level pill and stars (after a level change; sized by _layout()).
func _fill_badge(row: Dictionary) -> void:
	if not row.has("badge"):
		return
	var progress = Progress.shared()
	var at: int = progress.level(row.id)
	row.level.text = UiText.t("progress.level_short", {"n": at})
	if row.has("stars") and is_instance_valid(row.stars):
		row.badge.remove_child(row.stars)
		row.stars.queue_free()
	row["stars"] = BonStyle.stars(progress.best(row.id, at), 18.0 * _factor)
	row.stars.name = "Stars"
	row.badge.add_child(row.stars)

## The picker's level stepper: any unlocked level of `id`.
func _step_level(id: String, by: int) -> void:
	if id == "":
		return
	var progress = Progress.shared()
	progress.set_level(id, progress.level(id) + by)
	for row in _rows:
		if row.id == id:
			_fill_badge(row)
	_update()

func _show_tab(kind: String) -> void:
	_tab = kind
	for k in KINDS:
		_grids[k].visible = k == kind
		var on: bool = k == kind
		_tabs[k].add_theme_stylebox_override("normal", _card(Color("c9ecb4") if on else BonStyle.SKY_TOP, GOLD if on else LINE, 16))
	_style_tiles()
	_update()
	_layout()

func _select(id: String) -> void:
	_picked[_tab] = id
	_style_tiles()
	_update()

## The game shown in the detail bar ("" when the tab is empty).
func _selected() -> String:
	return str(_picked.get(_tab, ""))

func rounds(id: String) -> int:
	return int(chosen.get(id, Board.shared().rounds(id)))

func _step(id: String, by: int) -> void:
	if id == "":
		return
	chosen[id] = clampi(rounds(id) + by, 1, MAX_ROUNDS)
	_update()

## Why `id` cannot start now ("" when it can).
func blocked(id: String) -> String:
	if Board.shared().session(id) == null and not _loadable(id):
		return "launcher.absent"
	if testing != "" or _loading_id != "" or Board.shared().blocker("") != "":
		return "launcher.running"
	if is_instance_valid(main.active_vehicle):
		return "launcher.vehicle"
	return ""

## The tiles' highlight (on a new selection, tab or language, not every frame).
func _style_tiles() -> void:
	var id := _selected()
	for row in _rows:
		var on: bool = row.id == id
		var absent: bool = Board.shared().session(row.id) == null and not _loadable(row.id)
		row.tile.modulate.a = 0.55 if absent else 1.0
		row.tile.add_theme_stylebox_override("normal", _card(ROW_HOVER if on else ROW, GOLD if on else LINE, 12, 10))
		row.tile.add_theme_stylebox_override("hover", _card(ROW_HOVER, GOLD if on else LINE, 12, 10))
		row.tile.add_theme_stylebox_override("pressed", _card(ROW_HOVER, GOLD, 12, 10))
		row.icon.modulate = GOLD if on else TEXT

## The detail bar for the selected game (every frame while open: blocked / running changes).
func _update() -> void:
	var id := _selected()
	if id == "":
		return
	var why := blocked(id)
	_d_icon.texture = UiIcons.texture(str(ICONS.get(id, "play")), 128)
	_d_icon.modulate = GOLD
	_d_name.text = UiText.t("games." + id)
	_d_host.text = UiText.t("games_host." + id) if UiText.has("games_host." + id) else ""
	_d_learn.text = UiText.t("games_learn." + id) if UiText.has("games_learn." + id) else ""
	_d_status.text = UiText.t(why) if why != "" else ""
	_d_status.visible = why != ""
	var endless: bool = ENDLESS.has(id)
	_d_rounds.visible = not endless
	_d_endless.visible = endless
	count.text = str(rounds(id))
	var progress = Progress.shared()
	_d_level.visible = progress.has_levels(id)
	if _d_level.visible:
		level_count.text = str(progress.level(id))
		level_minus.disabled = progress.level(id) <= 1
		level_plus.disabled = progress.level(id) >= progress.unlocked(id)
	play.disabled = why != ""
	go.visible = main.guide != null and why != "launcher.absent"
	go.disabled = why == "launcher.running" or (main.guide != null and main.guide.target_game == id)
	minus.disabled = rounds(id) <= 1
	plus.disabled = rounds(id) >= MAX_ROUNDS

# --- Starting a game -----------------------------------------------------------------------

## Whether `id`'s session is missing only because its building is still waiting to be built.
func _loadable(id: String) -> bool:
	var unit := NearbyUnits.unit_of_activity(id)
	return unit != "" and main.pending_units.has(unit)

## Starts `id` with the chosen rounds; false when it cannot start now. A game whose building is
## still pending is built first (launch returns true at once; the game starts once it is in).
func launch(id: String) -> bool:
	if blocked(id) != "":
		return false
	if Board.shared().session(id) == null:
		close()
		_launch_after_loading(id)
		return true
	return _start(id)

## The game whose building is being built for Play (nearby loading), "" otherwise.
var _loading_id := ""

func _launch_after_loading(id: String) -> void:
	_loading_id = id
	await main.ensure_unit(NearbyUnits.unit_of_activity(id))
	_loading_id = ""
	if Board.shared().session(id) != null and blocked(id) == "":
		_start(id)

func _start(id: String) -> bool:
	var session: Object = Board.shared().session(id)
	var host = session.get("host")
	# A game with no NPC (Radar Patrol) starts itself where the player stands.
	if host == null and not session.has_method("launch"):
		return false
	close()
	if main.player.seated and main.seating != null:
		main.seating.stand()
	Board.shared().set_rounds(id, 0 if ENDLESS.has(id) else rounds(id))
	testing = id
	_since = 0.0
	if host != null:
		host.launch()
	else:
		session.launch()
	return true

## Closes the window and points the guide arrow at game `id`'s NPC (or its spot on the map when
## its building is not built yet).
func go_there(id: String) -> void:
	if id == "" or main.guide == null:
		return
	close()
	main.guide.go_to_game(id)

## The game started here is over (its session neither talks nor plays): the data's rounds
## count again.
func _finish_test() -> void:
	Board.shared().set_rounds(testing, 0)
	testing = ""

func _process(delta: float) -> void:
	if testing != "":
		_since += delta
		var session: Object = Board.shared().session(testing)
		if session == null or (_since > SETTLE and not session.busy() and not session.activity_running()):
			_finish_test()
	var hud = main.hud
	# Off while the welcome tutorial runs (user, 17 Nov 2026: no minigames meanwhile).
	corner_button.visible = enabled and not visible and testing == "" and Board.shared().running_id == "" \
			and not hud.tutorial_hidden.get("picker", false) \
			and not (hud.is_map_open() or hud.is_journal_open() or hud.is_help_open()) \
			and not hud.cluster_hidden(corner_button)
	if visible:
		_update()
		_place()

# --- Layout and looks (scaled like money_panel.gd) -----------------------------------------

func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	_factor = BonStyle.factor(view)
	var f := _factor
	# Top right, left of the journal under the gear row (14 Nov 2026, user; was in the
	# bottom-right cluster since 10 Nov 2026).
	main.hud.size_corner_button(corner_button, main.hud.top_slot(1))
	var width := minf(1040.0 * f, view.x - 32.0)
	window.custom_minimum_size = Vector2(width, 0)
	window.size = Vector2(width, 0)
	_title.add_theme_font_size_override("font_size", roundi(30 * f))
	# Finger-sized at any window size (touch UI, 9 Nov 2026): never under 52 px, as the corner button.
	var tap := func(base: float) -> float: return maxf(base * f, 52.0)
	_close.custom_minimum_size = Vector2(tap.call(56.0), tap.call(56.0))
	for tab in _tabs.values():
		tab.custom_minimum_size = Vector2(0, tap.call(56.0))
		tab.add_theme_font_size_override("font_size", roundi(19 * f))
		tab.add_theme_constant_override("h_separation", 0)
	var tile_height: float = tap.call(84.0)
	var gap := roundf(10 * f)
	for grid in _grids.values():
		grid.add_theme_constant_override("h_separation", gap)
		grid.add_theme_constant_override("v_separation", gap)
	_shade.position = Vector2.ZERO
	_shade.size = view
	var pad := roundf(12 * f)
	for row in _rows:
		row.tile.custom_minimum_size = Vector2(0, tile_height)
		row.line.offset_left = pad
		row.line.offset_right = -pad
		row.line.offset_top = 0
		row.line.offset_bottom = 0
		row.line.add_theme_constant_override("separation", roundi(12 * f))
		row.icon.custom_minimum_size = Vector2(40, 40) * f
		row.title.add_theme_font_size_override("font_size", roundi(21 * f))
		row.host.add_theme_font_size_override("font_size", roundi(15 * f))
		if row.has("badge"):
			row.level.add_theme_font_size_override("font_size", roundi(15 * f))
			for star in row.stars.get_children():
				star.custom_minimum_size = Vector2(18, 18) * f
	_d_icon.custom_minimum_size = Vector2(64, 64) * f
	_d_name.add_theme_font_size_override("font_size", roundi(26 * f))
	_d_host.add_theme_font_size_override("font_size", roundi(16 * f))
	_d_learn.add_theme_font_size_override("font_size", roundi(18 * f))
	_d_status.add_theme_font_size_override("font_size", roundi(16 * f))
	_d_rounds_label.add_theme_font_size_override("font_size", roundi(15 * f))
	_d_level_label.add_theme_font_size_override("font_size", roundi(15 * f))
	level_count.add_theme_font_size_override("font_size", roundi(26 * f))
	level_count.custom_minimum_size = Vector2(44 * f, 0)
	_d_endless.add_theme_font_size_override("font_size", roundi(16 * f))
	_d_endless.custom_minimum_size = Vector2(200 * f, 0)
	count.add_theme_font_size_override("font_size", roundi(26 * f))
	count.custom_minimum_size = Vector2(44 * f, 0)
	for button in [minus, plus, level_minus, level_plus]:
		button.custom_minimum_size = Vector2(tap.call(56.0), tap.call(56.0))
	play.custom_minimum_size = Vector2(170 * f, tap.call(72.0))
	go.custom_minimum_size = Vector2(0, tap.call(72.0))
	go.add_theme_font_size_override("font_size", roundi(20 * f))
	go.add_theme_constant_override("icon_max_width", roundi(26 * f))
	play.add_theme_font_size_override("font_size", roundi(24 * f))
	play.add_theme_constant_override("icon_max_width", roundi(30 * f))
	_place.call_deferred()

## Fits the window to its content and centres it (it fits a 1280 x 720 window with no scroll
## bar). Every frame while open, so a tab or language change re-fits it.
func _place() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var need: float = window.get_combined_minimum_size().y
	if absf(window.size.y - need) > 0.5:
		window.size = Vector2(window.size.x, need)
	window.position = Vector2(roundf((view.x - window.size.x) * 0.5), maxf(12.0, roundf((view.y - need) * 0.5)))

## A square icon that scales with its minimum size.
func _icon_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect

func _card(fill: Color, outline: Color, corners: int, margin: float = 14.0) -> StyleBoxFlat:
	var card := StyleBoxFlat.new()
	card.bg_color = fill
	card.border_color = outline
	card.set_border_width_all(4)
	card.set_corner_radius_all(corners)
	card.anti_aliasing = true
	card.set_content_margin_all(margin)
	return card

func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("icon_normal_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color(TEXT, 0.4))
	button.add_theme_color_override("icon_disabled_color", Color(TEXT, 0.4))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill: Color = BonStyle.SKY_TOP if state != "hover" else BonStyle.RIM
		if state == "pressed":
			fill = BonStyle.SKY.darkened(0.08)
		if state == "disabled":
			fill = BonStyle.SKY.lerp(Color(0.86, 0.88, 0.88), 0.6)
		button.add_theme_stylebox_override(state, _card(fill, LINE, 16))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(handler)
	return button
