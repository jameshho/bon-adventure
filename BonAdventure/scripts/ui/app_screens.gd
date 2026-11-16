extends Control
## The screens before the town (PWA restructure phase 3, user decisions 12 Nov 2026; simplified
## 13 Nov 2026, user: title + Play, choose character, then the game): the game's logo (LOGO, Bon
## Adventure: Little Town of Words since 16 Nov 2026; the text title if the picture is missing) with a
## Play button, then "Pick your character": the saved characters (up to 3 profiles,
## profile_manager.gd; tap one to continue) and a "New player" tile, or straight the character
## grid (one of the 9 house characters) when nothing is saved. A new character then picks
## "I speak / I want to learn" from language tiles (never the same language twice: picking the
## other side's language swaps the two) and starts. The tiles come from the playable languages of
## data/languages.json; each shows the language's badge, its name and its own name, and the
## picked one is green with a gold border and a check mark. A new character starts with
## languages.json's pair (English -> Spanish; user decision 14 Nov 2026). There are no name fields any more; a new
## profile is named after its character (names were never shown in the game). A pre-rendered, blurred town picture sits behind slim panels in the HUD
## colours (settings_panel.gd); avatar portraits are pre-rendered pictures. Both come from
## tools/capture_app_art.gd and are optional (missing pictures leave a plain colour / the name).
## Text is data/phrases.json "app.*" in languages.json's native language (Lexicon.default_native:
## English, whatever a profile picked; user decision 14 Nov 2026: every player reads English).
## Sizes follow the window like the money panel (min(h / 800, w / 1100)), shrinking further when
## a page would not fit (a landscape phone), and every target is finger sized (AGENTS.md).
## scripts/core/app.gd drives it: show_splash() -> splash_done (the Play button, Enter or Space),
## show_profiles() -> profile_chosen(id) (also emitted after a new profile is created).
signal splash_done
signal profile_chosen(id: String)

const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const BuildStamp := preload("res://scripts/core/build_stamp.gd")
const VocabularyProgress := preload("res://scripts/learning/vocabulary_progress.gd")
const BACKDROP := "res://assets/ui/app/backdrop.webp"
## The user's logo (16 Nov 2026), cleaned and trimmed: assets/branding/source/clean_logo.py.
const LOGO := "res://assets/branding/bon_adventure_logo.webp"
## Logo width on the title page in design pixels (DESIGN is 1100 wide).
const LOGO_WIDTH := 820.0
const PORTRAIT := "res://assets/ui/avatars/%s.webp"
const CHARACTERS := "res://data/house_characters.json"

const FILL := Color("142a38")
const EDGE := Color("7abfb3")
const GOLD := Color("fff1c5")
const DIM := Color("aadddc")
const PICKED := Color("3fae5a")
const DESIGN := Vector2(1100, 800)

var _page := ""
var _factor := 1.0
var _content: Control
## The onboarding draft: name, profile_name, avatar, native, foreign.
var _draft: Dictionary = {}
var _delete_id := ""
## "Last update on 11-15 at 19:25" in the bottom-right corner of every page (user, 15 Nov 2026;
## build_stamp.gd); hidden when the game runs from the project.
var _stamp: Label

func _init() -> void:
	name = "AppScreens"
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = FILL.darkened(0.3)
	back.anchor_right = 1.0
	back.anchor_bottom = 1.0
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	if ResourceLoader.exists(BACKDROP):
		var picture := TextureRect.new()
		picture.texture = load(BACKDROP)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.anchor_right = 1.0
		picture.anchor_bottom = 1.0
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(picture)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.08, 0.35)
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_stamp = Label.new()
	_stamp.text = BuildStamp.line(Lexicon.shared().default_native)
	_stamp.visible = _stamp.text != ""
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stamp.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_stamp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
	_stamp.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_stamp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp.add_theme_color_override("font_color", Color(DIM, 0.85))
	_stamp.add_theme_color_override("font_outline_color", FILL)
	_stamp.z_index = 1
	add_child(_stamp)

func _ready() -> void:
	get_viewport().size_changed.connect(_rebuild)

func show_splash() -> void:
	_show("splash")

func show_profiles() -> void:
	if ProfileManager.shared().profiles().is_empty():
		show_new_profile()
	else:
		_show("profiles")

## The first page of a new profile (also with no profiles yet).
func show_new_profile() -> void:
	var lexicon = Lexicon.shared()
	var playable: Array = lexicon.playable_codes()
	var native: String = lexicon.default_native if playable.has(lexicon.default_native) else str(playable[0])
	var foreign: String = lexicon.default_foreign
	if foreign == native or not playable.has(foreign):
		for code in playable:
			if str(code) != native:
				foreign = str(code)
				break
	_draft = {"avatar": ProfileManager.DEFAULT_AVATAR, "native": native, "foreign": foreign}
	_show("avatar")

func _show(page: String) -> void:
	if page in ["avatar", "languages"] and _draft.is_empty():
		show_new_profile()
		return
	_page = page
	_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if _page == "splash" and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		splash_done.emit()

func _t(id: String, values: Dictionary = {}) -> String:
	var lexicon = Lexicon.shared()
	return lexicon.phrase(id, lexicon.default_native, values)

# --- Pages ---------------------------------------------------------------------------------

func _rebuild() -> void:
	if _content != null:
		remove_child(_content)
		_content.queue_free()
	_content = null
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	_stamp.add_theme_font_size_override("font_size", roundi(18 * _factor))
	_stamp.add_theme_constant_override("outline_size", roundi(5 * _factor))
	_stamp.offset_right = -14.0 * _factor
	_stamp.offset_bottom = -10.0 * _factor
	_stamp.offset_left = _stamp.offset_right - 600.0 * _factor
	_stamp.offset_top = _stamp.offset_bottom - 40.0 * _factor
	# A page that does not fit (a small landscape phone) is built once more, smaller.
	for attempt in 2:
		match _page:
			"splash": _content = _splash()
			"profiles": _content = _card(_profiles_page())
			"avatar": _content = _card(_avatar_page())
			"languages": _content = _card(_languages_page())
			"delete": _content = _card(_delete_page())
			_: return
		add_child(_content)
		var need := _content.get_combined_minimum_size()
		var room := screen * 0.96
		if attempt == 1 or (need.x <= room.x and need.y <= room.y):
			break
		_factor = maxf(0.3, _factor * minf(room.x / need.x, room.y / need.y))
		remove_child(_content)
		_content.queue_free()

func _splash() -> Control:
	var f := _factor
	var box := VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", roundi(24 * f))
	if ResourceLoader.exists(LOGO):
		var logo := TextureRect.new()
		logo.texture = load(LOGO)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex_size: Vector2 = logo.texture.get_size()
		logo.custom_minimum_size = Vector2(LOGO_WIDTH, LOGO_WIDTH * tex_size.y / tex_size.x) * f
		logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(logo)
	else:
		var title := _label(_t("app.title"), 120, GOLD)
		title.add_theme_constant_override("outline_size", roundi(18 * f))
		title.add_theme_color_override("font_outline_color", FILL)
		box.add_child(title)
	var play := _button(_t("app.play"), "play")
	play.custom_minimum_size = Vector2(300 * f, 96 * f)
	play.add_theme_font_size_override("font_size", roundi(44 * f))
	play.add_theme_constant_override("icon_max_width", roundi(40 * f))
	var style := StyleBoxFlat.new()
	style.bg_color = PICKED
	style.border_color = GOLD
	style.set_border_width_all(roundi(3 * f))
	style.set_corner_radius_all(roundi(48 * f))
	style.set_content_margin_all(16 * f)
	for state in ["normal", "hover", "pressed"]:
		var look := style.duplicate()
		look.bg_color = PICKED.lightened(0.12) if state == "hover" else (PICKED.darkened(0.15) if state == "pressed" else PICKED)
		play.add_theme_stylebox_override(state, look)
	play.add_theme_color_override("font_color", Color.WHITE)
	play.add_theme_color_override("font_hover_color", Color.WHITE)
	play.add_theme_color_override("font_pressed_color", Color.WHITE)
	play.pressed.connect(func() -> void: splash_done.emit())
	var holder := CenterContainer.new()
	holder.add_child(play)
	box.add_child(holder)
	var pulse := play.create_tween().set_loops()
	pulse.tween_property(play, "scale", Vector2.ONE * 1.04, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
	play.resized.connect(func() -> void: play.pivot_offset = play.size * 0.5)
	return box

func _profiles_page() -> Control:
	var manager = ProfileManager.shared()
	var page := _page_box(_t("app.pick_avatar"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", roundi(20 * _factor))
	page.add_child(row)
	for entry in manager.profiles():
		var id := str(entry.id)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", roundi(8 * _factor))
		row.add_child(column)
		var pick := _tile(str(entry.avatar), str(entry.profile_name), false)
		pick.pressed.connect(func() -> void: profile_chosen.emit(id))
		column.add_child(pick)
		var progress := _label(_progress_text(id), 20, DIM)
		column.add_child(progress)
		var remove := _button(_t("app.delete"), "trash")
		remove.add_theme_font_size_override("font_size", roundi(22 * _factor))
		remove.pressed.connect(func() -> void:
			_delete_id = id
			_show("delete"))
		column.add_child(remove)
	if manager.can_create():
		var add := _tile("", _t("app.new_profile"), false)
		add.icon = UiIcons.texture("plus", roundi(96 * _factor))
		add.pressed.connect(show_new_profile)
		row.add_child(add)
	return page

func _avatar_page() -> Control:
	var page := _page_box(_t("app.pick_avatar"))
	if ProfileManager.shared().has_legacy_saves():
		var note := _label(_t("app.found_saves"), 24, DIM)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", roundi(12 * _factor))
	grid.add_theme_constant_override("v_separation", roundi(12 * _factor))
	page.add_child(grid)
	var names := _character_names()
	for id in ProfileManager.avatar_ids():
		var tile := _tile(id, str(names.get(id, id)), str(_draft.avatar) == id, 0.62)
		tile.pressed.connect(func() -> void:
			_draft.avatar = id
			_rebuild())
		grid.add_child(tile)
	# Back to the saved characters, or to the title when there are none.
	var back := _button(_t("app.back"), "back")
	back.pressed.connect(func() -> void:
		if ProfileManager.shared().profiles().is_empty():
			show_splash()
		else:
			_show("profiles"))
	var next := _button(_t("app.next"), "next")
	next.pressed.connect(func() -> void: _show("languages"))
	page.add_child(_nav(back, next))
	return page

## "I speak" and "I want to learn", each a row of language tiles (every playable language).
func _languages_page() -> Control:
	var lexicon = Lexicon.shared()
	var codes: Array = lexicon.playable_codes()
	var page := _page_box(_t("app.languages"))
	page.add_child(_label(_t("app.languages_hint"), 24, DIM))
	for key in ["native", "foreign"]:
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", roundi(14 * _factor))
		heading.add_child(_label(_t("app.i_speak" if key == "native" else "app.i_learn"), 32, GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		var use := _label(_t("app.i_speak_hint" if key == "native" else "app.i_learn_hint"), 22, DIM, HORIZONTAL_ALIGNMENT_LEFT)
		use.size_flags_vertical = Control.SIZE_SHRINK_END
		heading.add_child(use)
		page.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = codes.size() if codes.size() <= 4 else 3
		grid.add_theme_constant_override("h_separation", roundi(14 * _factor))
		grid.add_theme_constant_override("v_separation", roundi(14 * _factor))
		page.add_child(grid)
		for code in codes:
			var choice := _language_tile(str(code), str(_draft[key]) == str(code))
			choice.pressed.connect(func() -> void: _pick_language(key, str(code)))
			grid.add_child(choice)
	var back := _button(_t("app.back"), "back")
	back.pressed.connect(func() -> void: _show("avatar"))
	var start := _button(_t("app.start"), "play")
	_primary(start)
	start.pressed.connect(_create_profile)
	page.add_child(_nav(back, start))
	return page

## One side's language; picking the other side's language swaps the two (never the same twice).
func _pick_language(key: String, code: String) -> void:
	var other := "foreign" if key == "native" else "native"
	if str(_draft[other]) == code:
		_draft[other] = str(_draft[key])
	_draft[key] = code
	_rebuild()

func _create_profile() -> void:
	var manager = ProfileManager.shared()
	# Named after the character (the name fields were dropped on 13 Nov 2026).
	var character := str(_character_names().get(str(_draft.avatar), str(_draft.avatar)))
	var id: String = manager.create(character, character, str(_draft.avatar))
	if id == "":
		show_profiles()
		return
	manager.select(id)
	GameSettings.shared().set_languages(str(_draft.native), str(_draft.foreign))
	_draft = {}
	profile_chosen.emit(id)

func _delete_page() -> Control:
	var entry: Dictionary = ProfileManager.shared().get_profile(_delete_id)
	var page := _page_box(_t("app.delete"))
	var warning := _label(_t("app.delete_confirm", {"name": str(entry.get("profile_name", ""))}), 26, GOLD)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(warning)
	var cancel := _button(_t("app.cancel"), "back")
	cancel.pressed.connect(func() -> void: _show("profiles"))
	var remove := _button(_t("app.delete"), "trash")
	remove.pressed.connect(func() -> void:
		ProfileManager.shared().delete(_delete_id)
		show_profiles())
	page.add_child(_nav(cancel, remove))
	return page

# --- Builders ------------------------------------------------------------------------------

## The centred panel around a page (HUD colours, rounded, scaled).
func _card(page: Control) -> Control:
	var f := _factor
	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(FILL, 0.94)
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(roundi(16 * f))
	style.set_content_margin_all(28 * f)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(minf(720.0 * f, get_viewport_rect().size.x - 32.0), 0)
	card.add_child(page)
	center.add_child(card)
	return center

func _page_box(title: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", roundi(16 * _factor))
	page.add_child(_label(title, 38, GOLD))
	return page

func _label(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", roundi(size * _factor))
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, icon: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(180 * _factor, 64 * _factor)
	button.add_theme_font_size_override("font_size", roundi(28 * _factor))
	if icon != "":
		button.icon = UiIcons.texture(icon, 64)
		button.add_theme_constant_override("icon_max_width", roundi(28 * _factor))
	return button

## A big square picture button: a character portrait (or an icon) over a name.
func _tile(avatar: String, caption: String, picked: bool, size := 1.0) -> Button:
	var f := _factor * size
	var tile := _button(caption)
	tile.custom_minimum_size = Vector2(190 * f, 230 * f)
	tile.add_theme_font_size_override("font_size", roundi(26 * f))
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.expand_icon = true
	tile.icon = null
	tile.add_theme_constant_override("icon_max_width", roundi(150 * f))
	if avatar != "" and ResourceLoader.exists(PORTRAIT % avatar):
		tile.icon = load(PORTRAIT % avatar)
	if picked:
		var style := StyleBoxFlat.new()
		style.bg_color = PICKED.darkened(0.35)
		style.border_color = PICKED
		style.set_border_width_all(roundi(4 * _factor))
		style.set_corner_radius_all(roundi(12 * _factor))
		for state in ["normal", "hover", "pressed"]:
			tile.add_theme_stylebox_override(state, style)
	return tile

## A language tile: the badge (EN, ES, 中) in a circle, the language's name in the page's
## language and, below, its own name (Español); green with a gold border and a check when picked.
func _language_tile(code: String, picked: bool) -> Button:
	var f := _factor
	var lexicon = Lexicon.shared()
	var spec: Dictionary = lexicon.languages.get(code, {})
	var shown := _t("language." + code)
	var own := str(spec.get("name", code))
	var tile := Button.new()
	tile.focus_mode = Control.FOCUS_NONE
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(285 * f, 104 * f)
	tile.tooltip_text = shown
	for state in ["normal", "hover", "pressed"]:
		var look := StyleBoxFlat.new()
		look.set_corner_radius_all(roundi(14 * f))
		if picked:
			look.bg_color = PICKED.darkened(0.2)
			look.border_color = GOLD
			look.set_border_width_all(maxi(2, roundi(4 * f)))
		else:
			look.bg_color = FILL.lightened(0.12 if state == "hover" else (0.02 if state == "pressed" else 0.07))
			look.border_color = EDGE.darkened(0.25)
			look.set_border_width_all(maxi(1, roundi(2 * f)))
		tile.add_theme_stylebox_override(state, look)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16 * f
	# Room on the right for the check mark (it is not part of the row, so no tile shifts).
	row.offset_right = -46 * f
	row.add_theme_constant_override("separation", roundi(14 * f))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(row)
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.custom_minimum_size = Vector2(60, 60) * f
	var disc := StyleBoxFlat.new()
	disc.bg_color = GOLD if picked else Color(FILL, 0.0)
	disc.border_color = GOLD if picked else EDGE
	disc.set_border_width_all(maxi(1, roundi(3 * f)))
	disc.set_corner_radius_all(roundi(30 * f))
	badge.add_theme_stylebox_override("panel", disc)
	var mark := _label(str(spec.get("badge", code.to_upper())), 24, FILL if picked else EDGE)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(mark)
	row.add_child(badge)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_theme_constant_override("separation", 0)
	names.add_child(_label(shown, 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	if own != shown:
		names.add_child(_label(own, 22, GOLD if picked else DIM, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(names)
	if picked:
		var tick := TextureRect.new()
		tick.texture = UiIcons.texture("check", roundi(34 * f))
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tick.anchor_left = 1.0
		tick.anchor_right = 1.0
		tick.anchor_top = 0.5
		tick.anchor_bottom = 0.5
		tick.offset_left = -44 * f
		tick.offset_right = -10 * f
		tick.offset_top = -17 * f
		tick.offset_bottom = 17 * f
		tile.add_child(tick)
	return tile

## The page's main action: green with a gold border, like the title's Play.
func _primary(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var look := StyleBoxFlat.new()
		look.bg_color = PICKED.lightened(0.12) if state == "hover" else (PICKED.darkened(0.15) if state == "pressed" else PICKED)
		look.border_color = GOLD
		look.set_border_width_all(maxi(2, roundi(3 * _factor)))
		look.set_corner_radius_all(roundi(12 * _factor))
		look.set_content_margin_all(12 * _factor)
		button.add_theme_stylebox_override(state, look)
	for colour in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(colour, Color.WHITE)

## Back on the left, the main action on the right (either may be null).
func _nav(back: Button, forward: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(16 * _factor))
	if back != null:
		row.add_child(back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	if forward != null:
		row.add_child(forward)
	return row

## "Spanish · 12 words": the language a saved profile learns and the words it has found there,
## read from its own save files (nothing is selected).
func _progress_text(id: String) -> String:
	var folder := SaveStore.PROFILES_DIR.path_join(id)
	var settings: Variant = SaveStore.read_json(folder.path_join(GameSettings.FILE))
	var foreign: String = str(settings.get("foreign", GameSettings.shared().foreign)) if settings is Dictionary else GameSettings.shared().foreign
	var found: Variant = SaveStore.read_json(folder.path_join(VocabularyProgress.LANGUAGE_FILE.get_file()))
	var count: int = found.get(foreign, []).size() if found is Dictionary and found.get(foreign) is Array else 0
	return _t("app.profile_progress", {"language": _t("language." + foreign), "count": str(count)})

static func _character_names() -> Dictionary:
	var names := {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHARACTERS))
	for spec in (data.get("characters", []) if data is Dictionary else []):
		names[str(spec.get("id", ""))] = str(spec.get("name", ""))
	return names
