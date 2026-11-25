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
## Since 18 Nov 2026 (user) every page is built to the user's mockups in the UI art style
## (docs/guides/UI_STYLE.md, scripts/ui/bon_style.gd): a mint card with a cloud title and a meadow,
## glossy pill buttons, 4 x 2 character tiles (no Sunny), saved players picked then played with
## Next, language pills with round flags and "Just explore!" (Show everything in my language).
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
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const BACKDROP := "res://assets/ui/app/backdrop.webp"
## The user's logo (16 Nov 2026), cleaned and trimmed: assets/branding/source/clean_logo.py.
const LOGO := "res://assets/branding/bon_adventure_logo.webp"
## Logo width on the title page in design pixels (DESIGN is 1100 wide).
const LOGO_WIDTH := 820.0
const PORTRAIT := "res://assets/ui/avatars/%s.webp"
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")

const DESIGN := Vector2(1100, 800)
## The language page's size against the window factor (user, 18 Nov 2026: shorter card).
const LANGUAGES_SCALE := 0.8

var _page := ""
var _factor := 1.0
var _content: Control
## The onboarding draft: name, profile_name, avatar, native, foreign.
var _draft: Dictionary = {}
var _delete_id := ""
## The saved player picked on the profiles page (Next plays it).
var _picked_profile := ""
## "Last update on 11-15 at 19:25" in the bottom-right corner of every page (user, 15 Nov 2026;
## build_stamp.gd); hidden when the game runs from the project.
var _stamp: Label

func _init() -> void:
	name = "AppScreens"
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = BonStyle.MINT_TOP
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
	# A light wash keeps the backdrop bright behind the cards (UI_STYLE.md: no dark shade).
	shade.color = Color(1, 1, 1, 0.12)
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
	BonStyle.use_font(_stamp, 600)
	_stamp.add_theme_color_override("font_color", BonStyle.INK)
	_stamp.add_theme_color_override("font_outline_color", BonStyle.RIM)
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
	box.add_theme_constant_override("separation", roundi(28 * f))
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
		box.add_child(BonStyle.title(_t("app.title"), f, 80))
	# The big glossy Play pill (docs/guides/design-references/ui/play-button.png).
	var play := BonStyle.button(_t("app.play"), "primary", "play", f, 50, Vector2(330, 108))
	play.pressed.connect(func() -> void: splash_done.emit())
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(play)
	box.add_child(holder)
	# Play breathes (UI_STYLE.md: gentle motion); the press squash is BonStyle's.
	var pulse := play.create_tween().set_loops()
	pulse.tween_property(play, "scale", Vector2.ONE * 1.04, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
	return box

## The saved players (docs/guides/design-references/ui/profiles-and-languages.webp): a tile each
## with its progress and a Delete under it, and "New player"; a tap picks one (green, check),
## Next plays it.
func _profiles_page() -> Control:
	var manager = ProfileManager.shared()
	var entries: Array = manager.profiles()
	var ids: Array = entries.map(func(entry: Dictionary) -> String: return str(entry.id))
	if not ids.has(_picked_profile):
		var last := str(manager.index.get("last", ""))
		_picked_profile = last if ids.has(last) else (str(ids[0]) if not ids.is_empty() else "")
	var page := _page_box(_t("app.pick_avatar"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", roundi(30 * _factor))
	page.add_child(row)
	for entry in entries:
		var id := str(entry.id)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", roundi(16 * _factor))
		row.add_child(column)
		var pick := BonStyle.tile(_portrait(str(entry.avatar)), str(entry.profile_name), id == _picked_profile, _factor, _progress_text(id), Vector2(236, 270))
		pick.pressed.connect(func() -> void:
			_picked_profile = id
			_rebuild())
		column.add_child(pick)
		var remove := BonStyle.button(_t("app.delete"), "minor", "trash", _factor, 28, Vector2(200, 64))
		remove.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		remove.pressed.connect(func() -> void:
			_delete_id = id
			_show("delete"))
		column.add_child(remove)
	if manager.can_create():
		var add := BonStyle.tile(BonStyle.icon_texture("plus", 160), _t("app.new_profile"), false, _factor, "", Vector2(236, 270))
		add.pressed.connect(show_new_profile)
		var column := VBoxContainer.new()
		column.add_child(add)
		row.add_child(column)
	var back := BonStyle.button(_t("app.back"), "back", "arrow_left", _factor)
	back.pressed.connect(show_splash)
	var next := BonStyle.button(_t("app.next"), "primary", "play", _factor)
	next.disabled = _picked_profile == ""
	next.pressed.connect(func() -> void: profile_chosen.emit(_picked_profile))
	page.add_child(_nav(back, next))
	return page

## The character grid (docs/guides/design-references/ui/character-grid.webp): 4 x 2 tiles, every
## house character but those with "picker": false (Sunny; user, 18 Nov 2026).
func _avatar_page() -> Control:
	var page := _page_box(_t("app.pick_avatar"))
	if ProfileManager.shared().has_legacy_saves():
		var note := BonStyle.label(_t("app.found_saves"), 22, BonStyle.INK_SOFT, _factor, 600)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", roundi(22 * _factor))
	grid.add_theme_constant_override("v_separation", roundi(22 * _factor))
	page.add_child(grid)
	var names := _character_names()
	for id in _picker_ids():
		var tile := BonStyle.tile(_portrait(id), str(names.get(id, id)), str(_draft.avatar) == id, _factor, "", Vector2(200, 218))
		tile.pressed.connect(func() -> void:
			_draft.avatar = id
			_rebuild())
		grid.add_child(tile)
	# Back to the saved characters, or to the title when there are none.
	var back := BonStyle.button(_t("app.back"), "back", "arrow_left", _factor)
	back.pressed.connect(func() -> void:
		if ProfileManager.shared().profiles().is_empty():
			show_splash()
		else:
			_show("profiles"))
	var next := BonStyle.button(_t("app.next"), "primary", "arrow_right", _factor)
	next.pressed.connect(func() -> void: _show("languages"))
	page.add_child(_nav(back, next))
	return page

## "I speak" and "I want to learn", each a band with a row of language pills (every playable
## language, its round flag and its English name), then "Just explore!" (user, 18 Nov 2026: the
## same as Settings' "Show everything in my language" for the new player).
## Shorter than the other pages (user, 18 Nov 2026: in proportion to the screen, not its whole
## height): built at LANGUAGES_SCALE of the window factor, with a plain title (no cloud, no sprout).
func _languages_page() -> Control:
	var full := _factor
	_factor *= LANGUAGES_SCALE
	var lexicon = Lexicon.shared()
	var codes: Array = lexicon.playable_codes()
	var page := _page_box(_t("app.languages"), true)
	var exploring := bool(_draft.get("explore", false))
	for key in ["native", "foreign"]:
		var grid := GridContainer.new()
		grid.columns = codes.size() if codes.size() <= 4 else 3
		grid.add_theme_constant_override("h_separation", roundi(16 * _factor))
		grid.add_theme_constant_override("v_separation", roundi(12 * _factor))
		for code in codes:
			var spec: Dictionary = lexicon.languages.get(str(code), {})
			var choice := BonStyle.choice(BonStyle.flag(str(spec.get("flag", ""))), _t("language." + str(code)), str(_draft[key]) == str(code), _factor)
			choice.pressed.connect(func() -> void:
				# A tap on the greyed "I want to learn" row turns Just explore! back off.
				if key == "foreign":
					_draft.explore = false
				_pick_language(key, str(code)))
			grid.add_child(choice)
		var hint := "(%s)" % _t("app.i_speak_hint" if key == "native" else "app.i_learn_hint")
		var band := BonStyle.band(_t("app.i_speak" if key == "native" else "app.i_learn"), hint, grid, _factor)
		# Just explore! plays in the "I speak" language only, so "I want to learn" is greyed out
		# (user, 24 Nov 2026: the choice was confusing while that row still looked active).
		if key == "foreign" and exploring:
			band.modulate = Color(0.72, 0.72, 0.72, 0.45)
		page.add_child(band)
	page.add_child(_explore_choice())
	var back := BonStyle.button(_t("app.back"), "back", "arrow_left", _factor)
	back.pressed.connect(func() -> void: _show("avatar"))
	var start := BonStyle.button(_t("app.start"), "primary", "play", _factor)
	start.pressed.connect(_create_profile)
	page.add_child(_nav(back, start))
	_factor = full
	return page

## "Just explore! Play in my language." with a round tick on the right; a tap toggles it.
func _explore_choice() -> Button:
	var f := _factor
	var on := bool(_draft.get("explore", false))
	var choice := Button.new()
	choice.focus_mode = Control.FOCUS_NONE
	choice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	choice.custom_minimum_size = Vector2(0, 104) * f
	BonStyle.style_button(choice, "explore_on" if on else "explore", f)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 26 * f
	row.offset_right = -28 * f
	row.add_theme_constant_override("separation", roundi(22 * f))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice.add_child(row)
	row.add_child(_picture(BonStyle.icon_texture("gamepad", 128), 76 * f))
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation", 0)
	words.add_child(BonStyle.label(_t("app.explore"), 32, BonStyle.INK, f, 700, HORIZONTAL_ALIGNMENT_LEFT))
	words.add_child(BonStyle.label(_t("app.explore_hint"), 22, BonStyle.INK_SOFT, f, 600, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(words)
	row.add_child(_picture(BonStyle.icon_texture("radio_on" if on else "radio_off", 96), 42 * f))
	choice.pressed.connect(func() -> void:
		_draft.explore = not on
		_rebuild())
	BonStyle.squash_on_press(choice)
	return choice

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
	# "Just explore!" is Settings' "Show everything in my language" (user, 18 Nov 2026).
	GameSettings.shared().set_native(bool(_draft.get("explore", false)))
	_draft = {}
	profile_chosen.emit(id)

func _delete_page() -> Control:
	var entry: Dictionary = ProfileManager.shared().get_profile(_delete_id)
	var page := _page_box(_t("app.delete"))
	var warning := BonStyle.label(_t("app.delete_confirm", {"name": str(entry.get("profile_name", ""))}), 30, BonStyle.INK, _factor, 600)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.custom_minimum_size = Vector2(640, 0) * _factor
	page.add_child(warning)
	var cancel := BonStyle.button(_t("app.cancel"), "back", "arrow_left", _factor)
	cancel.pressed.connect(func() -> void: _show("profiles"))
	var remove := BonStyle.button(_t("app.delete"), "danger", "trash", _factor)
	remove.pressed.connect(func() -> void:
		ProfileManager.shared().delete(_delete_id)
		show_profiles())
	page.add_child(_nav(cancel, remove))
	return page

# --- Builders ------------------------------------------------------------------------------

## The centred card around a page (BonStyle: mint card with a meadow along the bottom).
func _card(page: Control) -> Control:
	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := BonStyle.card(page, _factor)
	card.custom_minimum_size = Vector2(minf(880.0 * _factor, get_viewport_rect().size.x - 32.0), 0)
	center.add_child(card)
	return center

## A page's column under its title: the cloud banner, or `plain` dark teal words alone.
func _page_box(title: String, plain := false) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", roundi(20 * _factor))
	if plain:
		var words := BonStyle.label(title, 50, BonStyle.INK, _factor)
		words.custom_minimum_size = Vector2(0, 64) * _factor
		page.add_child(words)
	else:
		page.add_child(BonStyle.title(title, _factor))
	return page

func _picture(texture: Texture2D, px: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2(px, px)
	return picture

func _portrait(avatar: String) -> Texture2D:
	return load(PORTRAIT % avatar) if avatar != "" and ResourceLoader.exists(PORTRAIT % avatar) else null

## Back on the left, the main action on the right (either may be null), a little above the meadow.
func _nav(back: Button, forward: Button) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(16 * _factor))
	if back != null:
		row.add_child(back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	if forward != null:
		row.add_child(forward)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", roundi(8 * _factor))
	margin.add_theme_constant_override("margin_left", roundi(30 * _factor))
	margin.add_theme_constant_override("margin_right", roundi(30 * _factor))
	margin.add_child(row)
	return margin

## The character ids the new-player grid offers, in data order.
static func _picker_ids() -> Array:
	var ids: Array = []
	for spec in HouseCharacters.characters():
		if spec.get("picker", true) != false:
			ids.append(str(spec.get("id", "")))
	return ids

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
	for spec in HouseCharacters.characters():
		names[str(spec.get("id", ""))] = str(spec.get("name", ""))
	return names
