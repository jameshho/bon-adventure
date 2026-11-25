extends CanvasLayer

# v0.6: Place aiming reticle + popup in viewport PIXEL coordinates.
# CanvasLayer is not a Control parent, so PRESET_FULL_RECT can leave a
# dynamically-created Control at 0 x 0 (which made the HUD appear top-left).
## The Display Mode (GameSettings: 0 native, 1 foreign); world signs follow it (the native
## language only in mode 0).
signal language_changed(mode: int)
## The gear button on the top right (Main opens Settings).
signal settings_requested
## The book button (top right) or the journal's ✕: Main opens or closes the journal like J.
signal journal_toggle_requested
## The F1 guide opened or closed (its ✕, the ? button, F1 or Esc): Main re-checks the player lock.
signal help_toggled
## The town map opened or closed (M, its corner button, its ✕): Main re-checks the controls.
signal map_toggled
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
## Switched-off features (minimap, full map, hyper speed; README.md#hidden-features).
const Features := preload("res://scripts/core/features.gd")
## Interface text in the native language (data/phrases.json; UI Stage 3, 4 Nov 2026).
const UiText := preload("res://scripts/language/ui_text.gd")
var settings_button: Button
## Labels whose text is one phrase, re-set by refresh_language(): label -> phrase id.
var phrase_labels: Dictionary = {}
var room_english := ""
var room_count := 0
var move_sprinting := false
## Set by touch_controls.gd once the screen is touched: texts leave out keyboard hints.
var touch_mode := false
var move_hyper := false
## Toggle id -> [on, text]: the F1 pills' state, kept across a rebuild of the guide.
var help_states: Dictionary = {}
var ui_root: Control
## HUD parts that lie over a minigame's own view (a seated table game, minigame_table.gd): the
## controls help, the place line, the walk line, and what Main adds (the minimap, the day clock).
## A new HUD part that would cover such a view joins this group (9 Nov 2026).
const GAME_HIDDEN_GROUP := "hud_hidden_in_games"
var _hidden_for_game: Array = []
## Why GAME_HIDDEN_GROUP is hidden now ("game": a seated table or a game panel; "minigame":
## any activity in progress, set by Main). Shown again when no reason is left.
var _hide_reasons: Dictionary = {}
## True while any minigame is in progress (activity_board.gd; Main updates it every frame).
## The map, the minimap, the journal / map / games / help buttons and the other
## GAME_HIDDEN_GROUP parts are off; the Settings gear and the peek badge stay (user, 12 Nov 2026).
var in_minigame := false
var overlay: ColorRect
var reticle_group: Control
var pointer_dot: ColorRect
var reticle_parts: Array[ColorRect] = []
var popup_panel: PanelContainer
## The word card at 1100 x 800 (it scales with the window, _layout_hud()) and its dim
## "Tap to close" line: a tap or click anywhere closes it (interaction_controller.gd click()).
const CARD_SIZE := Vector2(720, 340)
var close_hint: Label
var title_label: Label
var primary_label: Label
var secondary_label: Label
## Pinyin under the word when Chinese is the foreign language (GameSettings.reading()).
var reading_label: Label
var category_label: Label
var room_label: Label
var fps_label: Label
var movement_label: Label
var noclip_label: Label
var map_overlay: ColorRect
var help_overlay: PanelContainer
var help_scroll: ScrollContainer
## The F1 guide's ✕ (14 Nov 2026, user: touch had no way to close it), as big as a corner button.
var help_close: Button
## Toggle id -> {label, style}: pills in the F1 guide that mirror each toggle live.
var help_pills: Dictionary = {}
var quest_toast: Label
var quest_toast_time := 0.0
var journal_overlay: ColorRect
var journal_panel: PanelContainer
var journal_title: Label
## Header right side: "5 of 781 words studied" and its bar; the ✕ close button.
var journal_progress_label: Label
var journal_progress: ProgressBar
var journal_close: Button
var journal_icon: TextureRect
## The table, filters and word detail (scripts/ui/vocabulary_book.gd; Stage C, 8 Nov 2026).
var journal_book
var journal_hint: Label
var journal_category_button: Button
var journal_area_button: Button
var journal_by_area := false
var journal_studied: Dictionary = {}
var journal_dictionary: Dictionary = {}
var journal_categories: Dictionary = {}
var journal_areas: Dictionary = {}
var journal_area_names: Dictionary = {}
var fps_visible := false
var mode := GameSettings.DEFAULT_DISPLAY
var current_english := ""
var current_spanish := ""
var current_category := "Everyday"
var current_character := ""
var hover_active := false
var flight_label: Label
# Bookmarked words: a star on the word card saves its canonical key; the book
# button (top right) opens the journal, whose Saved tab lists them (9 Nov 2026: the separate
# saved-words panel was merged into the journal). Persisted by VocabularyProgress.
const VocabularyProgress = preload("res://scripts/learning/vocabulary_progress.gd")
const BOOKMARK_GOLD := Color("e9a91f")   # the saved-word star (same as the journal's)
const PULSE_TINT := Color("c4ecb0")   # a tutorial-pulsed button glows soft green (no yellow, 18 Nov 2026)
var bookmark_button: Button
## Hold to see the town's signs in the native language (the touch twin of holding L,
## 9 Nov 2026); left of the gear, labelled with the native badge (EN, ES, 中).
var peek_button: Button
## The welcome tutorial's HUD buttons (user, 17 Nov 2026): names ("peek", "journal", "picker")
## hidden until the tutorial introduces them (tutorial.gd), and those that pulse meanwhile to ask
## for a click. The picker (game_launcher.gd) reads tutorial_hidden too.
var tutorial_hidden := {}
var tutorial_pulse := {}
var _pulse_time := 0.0
## The bottom-right cluster (10 Nov 2026, user): a 2 x 2 block of equal buttons, the journal
## (bookmark_button), the full map, the minigame picker (game_launcher.gd places it with
## bottom_slot(2)) and help. Since 14 Nov 2026 (user) the journal and the picker are a second
## row under the gear and the peek badge (top_slot()), the help button is hidden (F1 and Esc
## still work; the guide has its ✕), and the bottom right holds the touch jump and E buttons
## (jump_slot()); the map slot stays empty while the map is hidden. Sizes (user, 10 Nov 2026: 2.8 x larger, then 2 x after seeing it):
## the cluster is 2 x the old 60 px corner button, the top-right peek badge and gear 1.5 x.
const CLUSTER_SCALE := 2.0
const TOP_SCALE := 1.5
## The peek badge ("EN") and the gear only (user, 21 Nov 2026): 10 % bigger than the other top
## buttons, and held further in from the right edge (TOP_INSET px x the HUD factor, at least
## TOP_INSET_MIN) so a phone's rounded corner does not clip them; the second row lines up with them.
const TOP_BIG := 1.1
const TOP_INSET := 30.0
const TOP_INSET_MIN := 20.0
var map_button: Button
var help_button: Button
## The minimap's side in px (town_minimap.gd side_for()), for what sits under it.
var minimap_side := 208.0
## What covers the lower screen now (Main: the NPC dialogue box's rect, empty when it is not
## showing): a cluster button it overlaps hides meanwhile (cluster_hidden()).
var cluster_cover: Callable
## True while a game hides the whole cluster (user, 10 Nov 2026: none of the four during mahjong;
## the game's status card keeps its own lessons and leave buttons, the gear stays).
var cluster_off := false
var bookmark_star: Button
## The word card's speaker (24 Nov 2026, user): says the word in the language being learned
## (sound.gd say_word(), docs/guides/VOICE.md). Top left of the card, opposite the star; shown
## only when the word has a clip and spoken words are on (data/sounds.json voice.enabled).
var speaker_button: Button
const Sound := preload("res://scripts/core/sound.gd")
## Key hint circles (24 Nov 2026, user): a small INK circle with the button's key ("J" on the
## journal) at a HUD button's bottom-left corner, only while playing with a keyboard (a laptop):
## on at start without a touch screen, off after a touch, on again after a key press. The key
## comes from the action's binding in project.godot, so the circle always matches the input map.
var key_hints: Array = []
var keyboard_hints := false
## The gear and book buttons' boxes (size and margins follow the window in _layout_hud).
var corner_styles: Array = []
var bookmarks: Dictionary = {}
var bookmark_vocabulary: Dictionary = {}
var bookmark_aliases: Dictionary = {}
var bookmark_english_index: Dictionary = {}
var current_word_key := ""


## Hides the GAME_HIDDEN_GROUP parts that are showing, or shows those again once no other
## `reason` still hides them.
func hide_for_game(hide: bool, reason := "game") -> void:
    if hide:
        _hide_reasons[reason] = true
    else:
        _hide_reasons.erase(reason)
    if not _hide_reasons.is_empty():
        for node in get_tree().get_nodes_in_group(GAME_HIDDEN_GROUP):
            if node is CanvasItem and node.visible and not _hidden_for_game.has(node):
                node.visible = false
                _hidden_for_game.append(node)
    else:
        for node in _hidden_for_game:
            if is_instance_valid(node):
                node.visible = true
        _hidden_for_game.clear()

func set_flight_status(message: String) -> void:
    flight_label.text=message
    flight_label.visible=not message.is_empty()

func _ready() -> void:
    # The HUD follows the settings itself (the Settings window), so it works
    # without Main too; language_changed then tells Main to switch the world labels.
    GameSettings.shared().changed.connect(func() -> void:
        set_display_mode(GameSettings.shared().display)
        refresh_language())
    keyboard_hints = not DisplayServer.is_touchscreen_available()
    ui_root = Control.new()
    ui_root.name = "Viewport aligned HUD"
    ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Fredoka for every HUD text (UI art style, docs/guides/UI_STYLE.md, 18 Nov 2026).
    ui_root.theme = Theme.new()
    ui_root.theme.default_font = BonStyle.font(600)
    add_child(ui_root)
    flight_label=Label.new()
    flight_label.position=Vector2(18,345)
    flight_label.add_theme_font_size_override("font_size",17)
    flight_label.add_theme_color_override("font_color",Color("fff9e8"))
    flight_label.add_theme_color_override("font_shadow_color",Color("162530"))
    flight_label.add_theme_constant_override("shadow_offset_x",2)
    flight_label.add_theme_constant_override("shadow_offset_y",2)
    flight_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    flight_label.hide()
    ui_root.add_child(flight_label)

    overlay = ColorRect.new()
    overlay.color = Color(0.03, 0.07, 0.10, 0.24)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.visible = false
    ui_root.add_child(overlay)

    var help := Label.new()
    help.name = "Controls"
    phrase_label(help, "hud.controls")
    help.position = Vector2(18, 232)
    help.add_theme_font_size_override("font_size", 16)
    help.add_theme_color_override("font_color", Color("fff9e8"))
    help.add_theme_color_override("font_shadow_color", Color("162530"))
    help.add_theme_constant_override("shadow_offset_x", 2)
    help.add_theme_constant_override("shadow_offset_y", 2)
    help.mouse_filter = Control.MOUSE_FILTER_IGNORE
    help.add_to_group(GAME_HIDDEN_GROUP)
    # Hidden since 10 Nov 2026 (user: a cleaner HUD): the same controls are in the F1 / ? help,
    # and the hover line shows the key for what the player is looking at.
    help.visible = false
    ui_root.add_child(help)

    # Four precise crosshair ticks with a dot in the exact screen center.
    reticle_group = Control.new()
    reticle_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(reticle_group)
    for layout in [Vector4(-1, -13, 2, 8), Vector4(-1, 5, 2, 8), Vector4(-13, -1, 8, 2), Vector4(5, -1, 8, 2)]:
        var tick := ColorRect.new()
        tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
        tick.color = Color.WHITE
        tick.position = Vector2(layout.x, layout.y)
        tick.size = Vector2(layout.z, layout.w)
        reticle_group.add_child(tick)
        reticle_parts.append(tick)
    pointer_dot = ColorRect.new()
    pointer_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pointer_dot.position = Vector2(-2, -2)
    pointer_dot.size = Vector2(4, 4)
    pointer_dot.color = Color.WHITE
    reticle_group.add_child(pointer_dot)


    popup_panel = PanelContainer.new()
    popup_panel.name = "Centered vocabulary card"
    popup_panel.custom_minimum_size = CARD_SIZE
    popup_panel.size = CARD_SIZE
    popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    popup_panel.visible = false
    ui_root.add_child(popup_panel)
    var card := StyleBoxFlat.new()
    card.bg_color = BonStyle.SKY
    card.border_color = BonStyle.RIM
    card.set_border_width_all(5)
    card.set_corner_radius_all(28)
    card.shadow_color = Color(0.1, 0.27, 0.32, 0.22)
    card.shadow_size = 14
    card.shadow_offset = Vector2(0, 5)
    card.anti_aliasing = true
    card.content_margin_left = 34
    card.content_margin_right = 34
    card.content_margin_top = 28
    card.content_margin_bottom = 26
    popup_panel.add_theme_stylebox_override("panel", card)
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_theme_constant_override("separation", 11)
    popup_panel.add_child(stack)
    category_label = Label.new()
    category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    category_label.add_theme_font_size_override("font_size", 15)
    category_label.add_theme_color_override("font_color", BonStyle.INK_SOFT)
    stack.add_child(category_label)
    title_label = Label.new()
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 16)
    title_label.add_theme_color_override("font_color", BonStyle.BROWN)
    stack.add_child(title_label)
    primary_label = Label.new()
    primary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    primary_label.add_theme_font_size_override("font_size", 40)
    primary_label.add_theme_color_override("font_color", BonStyle.INK)
    primary_label.add_theme_font_override("font", BonStyle.font(700))
    stack.add_child(primary_label)
    reading_label = PinyinText.style(Label.new())
    reading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reading_label.add_theme_font_size_override("font_size", 24)
    reading_label.add_theme_color_override("font_color", BonStyle.TERM)
    stack.add_child(reading_label)
    secondary_label = Label.new()
    secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    secondary_label.add_theme_font_size_override("font_size", 24)
    secondary_label.add_theme_color_override("font_color", Color("3d5560"))
    stack.add_child(secondary_label)
    close_hint = Label.new()
    phrase_label(close_hint, "card.foot")
    close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    close_hint.add_theme_color_override("font_color", BonStyle.INK_SOFT)
    stack.add_child(close_hint)

    mode = GameSettings.shared().display
    settings_button = Button.new()
    settings_button.name = "Settings gear"
    settings_button.focus_mode = Control.FOCUS_NONE
    settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
    settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    settings_button.icon = UiIcons.texture("gear", 128)
    settings_button.expand_icon = true
    settings_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    style_corner_button(settings_button)
    settings_button.pressed.connect(func() -> void: settings_requested.emit())
    ui_root.add_child(settings_button)
    add_key_hint(settings_button, "back")
    peek_button = Button.new()
    peek_button.name = "Peek native"
    peek_button.focus_mode = Control.FOCUS_NONE
    peek_button.mouse_filter = Control.MOUSE_FILTER_STOP
    peek_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    for state in ["font_color", "font_hover_color"]:
        peek_button.add_theme_color_override(state, BonStyle.INK)
    peek_button.add_theme_color_override("font_pressed_color", Color.WHITE)
    peek_button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
    peek_button.add_theme_font_override("font", BonStyle.font(700))
    style_corner_button(peek_button)
    peek_button.button_down.connect(func() -> void: GameSettings.shared().set_peek(true))
    peek_button.button_up.connect(func() -> void: GameSettings.shared().set_peek(false))
    ui_root.add_child(peek_button)
    add_key_hint(peek_button, "peek")

    room_label = Label.new()
    room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    room_label.text = ""
    room_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    room_label.add_theme_font_size_override("font_size", 16)
    room_label.add_theme_color_override("font_color", Color("fff2d8"))
    room_label.add_theme_color_override("font_shadow_color", Color("2a414a"))
    room_label.add_theme_constant_override("shadow_offset_x", 2)
    room_label.add_theme_constant_override("shadow_offset_y", 2)
    room_label.add_to_group(GAME_HIDDEN_GROUP)
    ui_root.add_child(room_label)

    fps_label = Label.new()
    fps_label.text = ""
    fps_label.add_theme_font_size_override("font_size", 15)
    fps_label.add_theme_color_override("font_color", Color("f5e2ac"))
    fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fps_label.visible = false
    ui_root.add_child(fps_label)
    movement_label = Label.new()
    movement_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    movement_label.add_theme_font_size_override("font_size", 16)
    movement_label.add_theme_color_override("font_shadow_color", Color("14252b"))
    movement_label.add_theme_constant_override("shadow_offset_x", 2)
    movement_label.add_theme_constant_override("shadow_offset_y", 2)
    movement_label.add_to_group(GAME_HIDDEN_GROUP)
    # Only while sprinting or in hyper speed (10 Nov 2026): walking needs no line.
    movement_label.visible = false
    ui_root.add_child(movement_label)
    noclip_label = Label.new()
    phrase_label(noclip_label, "hud.noclip")
    noclip_label.add_theme_font_size_override("font_size", 18)
    noclip_label.add_theme_color_override("font_color", Color("ffe19b"))
    noclip_label.add_theme_color_override("font_shadow_color", Color("14252b"))
    noclip_label.add_theme_constant_override("shadow_offset_x", 2)
    noclip_label.add_theme_constant_override("shadow_offset_y", 2)
    noclip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    noclip_label.visible = false
    ui_root.add_child(noclip_label)
    # The town map's full-screen layer (wayfinding, 18 Nov 2026): Main puts the baked map
    # (town_map_panel.gd) in it; it shows while the map is open.
    map_overlay = ColorRect.new()
    map_overlay.name = "Map overlay"
    map_overlay.color = BonStyle.SHADE
    map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    map_overlay.visible = false
    ui_root.add_child(map_overlay)
    # Compact always-visible discovery challenge: pointer-friendly but does not
    # absorb input from the third-person view.
    quest_toast = Label.new()
    quest_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    quest_toast.add_theme_font_size_override("font_size", 16)
    quest_toast.add_theme_color_override("font_color", Color("fff3b2"))
    quest_toast.add_theme_color_override("font_shadow_color", Color("182d33"))
    quest_toast.add_theme_constant_override("shadow_offset_x", 2)
    quest_toast.add_theme_constant_override("shadow_offset_y", 2)
    quest_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
    quest_toast.visible = false
    ui_root.add_child(quest_toast)

    build_bookmarks()

    # A searchable-by-scrolling study journal, using the original local word
    # progress, not a second database of vocabulary discoveries.
    journal_overlay = ColorRect.new()
    journal_overlay.name = "Study journal dimmer"
    journal_overlay.color = BonStyle.SHADE
    journal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    journal_overlay.visible = false
    ui_root.add_child(journal_overlay)
    journal_panel = PanelContainer.new()
    journal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    journal_panel.add_theme_stylebox_override("panel", make_light_card(BonStyle.MINT_TOP, 34))
    journal_overlay.add_child(journal_panel)
    var journal_stack := VBoxContainer.new()
    journal_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    journal_stack.add_theme_constant_override("separation", 12)
    journal_panel.add_child(journal_stack)
    journal_book = preload("res://scripts/ui/vocabulary_book.gd").new()
    journal_book.bookmark_toggled.connect(toggle_bookmark)
    # Header: book icon and title, then progress (studied of all words) and the ✕.
    var journal_header := HBoxContainer.new()
    journal_header.name = "Journal header"
    journal_header.add_theme_constant_override("separation", 14)
    journal_stack.add_child(journal_header)
    journal_icon = TextureRect.new()
    journal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    journal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    journal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    journal_header.add_child(journal_icon)
    journal_title = Label.new()
    journal_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    journal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    journal_title.add_theme_color_override("font_color", BonStyle.INK)
    journal_title.add_theme_font_override("font", BonStyle.font(700))
    journal_header.add_child(journal_title)
    var progress_stack := VBoxContainer.new()
    progress_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    progress_stack.add_theme_constant_override("separation", 4)
    journal_header.add_child(progress_stack)
    journal_progress_label = Label.new()
    journal_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    journal_progress_label.add_theme_color_override("font_color", BonStyle.INK_SOFT)
    progress_stack.add_child(journal_progress_label)
    journal_progress = ProgressBar.new()
    journal_progress.show_percentage = false
    journal_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var bar_back := StyleBoxFlat.new()
    bar_back.bg_color = Color("cfe8eb")
    bar_back.set_corner_radius_all(6)
    var bar_fill := StyleBoxFlat.new()
    bar_fill.bg_color = BonStyle.GREEN_BOTTOM
    bar_fill.set_corner_radius_all(6)
    journal_progress.add_theme_stylebox_override("background", bar_back)
    journal_progress.add_theme_stylebox_override("fill", bar_fill)
    progress_stack.add_child(journal_progress)
    journal_close = Button.new()
    journal_close.name = "Close journal"
    journal_close.focus_mode = Control.FOCUS_NONE
    journal_close.expand_icon = true
    journal_close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    journal_close.icon = UiIcons.texture("close", 64)
    journal_close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    journal_book.style_button(journal_close, "plain")
    journal_close.pressed.connect(func() -> void: journal_toggle_requested.emit())
    journal_header.add_child(journal_close)
    # The grouping buttons (By Category / By Area) sit at the end of the book's tab row.
    var views := HBoxContainer.new()
    views.add_theme_constant_override("separation", 6)
    journal_book.tab_bar.add_child(views)
    journal_category_button = Button.new()
    phrase_label(journal_category_button, "journal.by_category")
    journal_category_button.toggle_mode = true
    journal_category_button.focus_mode = Control.FOCUS_NONE
    journal_book.style_button(journal_category_button, "plain")
    journal_category_button.pressed.connect(func(): set_journal_view(false))
    views.add_child(journal_category_button)
    journal_area_button = Button.new()
    phrase_label(journal_area_button, "journal.by_area")
    journal_area_button.toggle_mode = true
    journal_area_button.focus_mode = Control.FOCUS_NONE
    journal_book.style_button(journal_area_button, "plain")
    journal_area_button.pressed.connect(func(): set_journal_view(true))
    views.add_child(journal_area_button)
    journal_hint = journal_book.hint
    journal_stack.add_child(journal_book)

    help_overlay = PanelContainer.new()
    help_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    help_overlay.add_theme_stylebox_override("panel", make_light_card(BonStyle.MINT_TOP, 30))
    help_overlay.visible = false
    ui_root.add_child(help_overlay)
    build_help_content()

    # The word card has no translate bubble of its own (user, 21 Nov 2026): holding the top-right
    # peek badge (or L) shows the native word on it, like every other open card.
    GameSettings.shared().peek_changed.connect(func() -> void:
        if is_card_visible():
            update_card())

    get_viewport().size_changed.connect(_layout_hud)
    refresh_language()
    _layout_hud()

## A label (or button) showing one phrase; refresh_language() re-sets it.
func phrase_label(node: Control, id: String) -> void:
    phrase_labels[node] = id
    node.set("text", UiText.t(id))

## Re-renders every interface text in the current native language (Settings changes).
func refresh_language() -> void:
    for node in phrase_labels:
        if is_instance_valid(node):
            node.set("text", UiText.t(phrase_labels[node]))
    settings_button.tooltip_text = UiText.t("settings.open")
    peek_button.text = GameSettings.shared().native_badge()
    peek_button.tooltip_text = UiText.t("hud.peek")
    bookmark_button.tooltip_text = UiText.t("bookmarks.open")
    map_button.tooltip_text = UiText.t("map.title") + " (M)"
    help_button.tooltip_text = UiText.t("help.title") + " (F1)"
    journal_close.tooltip_text = UiText.t("journal.close")
    for child in help_overlay.get_children():
        help_overlay.remove_child(child)
        child.queue_free()
    help_pills.clear()
    build_help_content()
    if room_english != "":
        set_progress(room_english, room_count)
    set_movement_mode(move_sprinting, move_hyper)
    if is_journal_open():
        render_journal()
    if is_card_visible():
        update_card()

func _layout_hud() -> void:
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    ui_root.position = Vector2.ZERO
    ui_root.size = viewport_size
    overlay.position = Vector2.ZERO
    overlay.size = viewport_size
    var center: Vector2 = viewport_size * 0.5
    reticle_group.position = center
    # The journal and the top-right buttons scale with the window like the minigame panels
    # (money_panel.gd). The gear and book are 60 px at 1100 x 800 (were 46 x 44, 9 Nov 2026).
    var f: float = BonStyle.factor(viewport_size)
    # The word card scales with the window too (14 Nov 2026, user: bigger, for phones; it was a
    # fixed 560 x 258 with a 40 px word). Assign its size, then recenter even on window resize.
    var card_box: StyleBoxFlat = popup_panel.get_theme_stylebox("panel")
    card_box.content_margin_left = 40.0 * f
    card_box.content_margin_right = 40.0 * f
    card_box.content_margin_top = 34.0 * f
    card_box.content_margin_bottom = 24.0 * f
    card_box.set_corner_radius_all(roundi(32 * f))
    card_box.set_border_width_all(maxi(3, roundi(6 * f)))
    card_box.shadow_size = roundi(14 * f)
    (popup_panel.get_child(0) as VBoxContainer).add_theme_constant_override("separation", roundi(12 * f))
    category_label.add_theme_font_size_override("font_size", roundi(22 * f))
    title_label.add_theme_font_size_override("font_size", roundi(24 * f))
    primary_label.add_theme_font_size_override("font_size", roundi(68 * f))
    reading_label.add_theme_font_size_override("font_size", roundi(38 * f))
    secondary_label.add_theme_font_size_override("font_size", roundi(38 * f))
    close_hint.add_theme_font_size_override("font_size", roundi(20 * f))
    popup_panel.custom_minimum_size = Vector2(minf(CARD_SIZE.x * f, viewport_size.x - 24.0), CARD_SIZE.y * f)
    # A long word widens the card past its minimum; center what it really takes.
    popup_panel.size = popup_panel.custom_minimum_size.max(popup_panel.get_combined_minimum_size())
    popup_panel.position = (viewport_size - popup_panel.size) * 0.5
    bookmark_star.custom_minimum_size = Vector2(72, 72) * f
    bookmark_star.size = bookmark_star.custom_minimum_size
    var corner: float = top_corner_size()
    var right: float = top_right_inset()
    settings_button.position = Vector2(viewport_size.x - corner - right, 10.0)
    peek_button.position = Vector2(settings_button.position.x - corner - 10.0, 10.0)
    for button in [settings_button, peek_button]:
        size_corner_button(button, Rect2(button.position, Vector2(corner, corner)))
    size_corner_button(bookmark_button, top_slot(0))
    # The second top-right row, left of the minigame picker (wayfinding, 18 Nov 2026; it was in
    # the bottom-right cluster, where the touch jump button sits since 14 Nov 2026).
    size_corner_button(map_button, top_slot(2))
    size_corner_button(help_button, bottom_slot(3))
    peek_button.add_theme_font_size_override("font_size", roundi(corner * 0.36))
    fps_label.position = Vector2(peek_button.position.x - 120.0, 16)
    bookmark_star.position = popup_panel.position + Vector2(popup_panel.size.x - bookmark_star.size.x - 12.0 * f, 12.0 * f)
    speaker_button.custom_minimum_size = bookmark_star.size
    speaker_button.size = bookmark_star.size
    speaker_button.position = popup_panel.position + Vector2(12.0 * f, 12.0 * f)
    # The place and words found sit under the minimap (10 Nov 2026; were bottom right).
    minimap_side = preload("res://scripts/ui/town_minimap.gd").side_for(viewport_size) if Features.MINIMAP else 0.0
    room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    room_label.position = Vector2(16, 16 + minimap_side + 6)
    room_label.size = Vector2(maxf(minimap_side, 420.0), 28)
    room_label.add_theme_font_size_override("font_size", roundi(16 * f))
    flight_label.position = Vector2(18, room_label.position.y + 34)
    movement_label.position = Vector2(18, viewport_size.y - 132)
    noclip_label.position = Vector2(18, viewport_size.y - 104)
    # The toast (flash_quest_message) sits below FPS on the right.
    quest_toast.position = Vector2(maxf(8.0, viewport_size.x - 510.0), top_slot(0).end.y + 12.0)
    quest_toast.size = Vector2(minf(490.0, viewport_size.x - 20.0), 48.0)
    journal_overlay.position = Vector2.ZERO
    journal_overlay.size = viewport_size
    var book_size := Vector2(minf(1020.0 * f, viewport_size.x - 40.0), minf(740.0 * f, viewport_size.y - 40.0))
    journal_panel.size = book_size
    journal_panel.position = (viewport_size - book_size) * 0.5
    var card: StyleBoxFlat = journal_panel.get_theme_stylebox("panel")
    card.content_margin_left = 22.0 * f
    card.content_margin_right = 22.0 * f
    card.content_margin_top = 16.0 * f
    card.content_margin_bottom = 16.0 * f
    journal_icon.custom_minimum_size = Vector2(46, 46) * f
    journal_icon.texture = BonStyle.icon_texture("journal", roundi(46 * f))
    journal_title.add_theme_font_size_override("font_size", roundi(28 * f))
    journal_progress_label.add_theme_font_size_override("font_size", roundi(15 * f))
    journal_progress.custom_minimum_size = Vector2(220 * f, 10 * f)
    journal_close.custom_minimum_size = Vector2(52, 52) * f
    for button in [journal_category_button, journal_area_button]:
        button.add_theme_font_size_override("font_size", roundi(17 * f))
        button.custom_minimum_size = Vector2(0, 48 * f)
    journal_book.apply_scale(f)
    help_overlay.size = Vector2(minf(1240.0, viewport_size.x - 40.0), minf(660.0, viewport_size.y - 40.0))
    help_overlay.position = (viewport_size - help_overlay.size) * 0.5
    _size_help_close()
    map_overlay.position = Vector2.ZERO
    map_overlay.size = viewport_size

func _process(delta: float) -> void:
    reticle_group.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not is_card_visible()
    # Full-screen windows cover the top-right buttons (the journal has its own ✕).
    var covered: bool = is_map_open() or is_journal_open() or is_help_open()
    bookmark_button.visible = not covered and not cluster_hidden(bookmark_button) and not tutorial_hidden.get("journal", false)
    map_button.visible = Features.FULL_MAP and not covered and not cluster_hidden(map_button) and not tutorial_hidden.get("map", false)
    # Hidden (14 Nov 2026, user): F1 opens the guide; its ✕ closes it.
    help_button.visible = false
    settings_button.visible = not covered
    # Native mode already shows the native language, so there is nothing to peek at.
    peek_button.visible = not covered and mode != GameSettings.NATIVE and not tutorial_hidden.get("peek", false)
    _pulse_time += delta
    for entry in [["peek", peek_button], ["journal", bookmark_button]]:
        _pulse(entry[1], tutorial_pulse.get(entry[0], false))
    # The peek ends when neither L nor the button is held (a release eaten by a popup,
    # the window losing focus or the button hiding cannot leave it stuck on).
    if GameSettings.shared().peeking and not Input.is_physical_key_pressed(KEY_L) and not (peek_button.visible and peek_button.is_pressed()):
        GameSettings.shared().set_peek(false)
    if quest_toast_time > 0.0:
        quest_toast_time -= delta
        if quest_toast_time <= 0.0:
            quest_toast.visible = false
    if fps_visible:
        fps_label.text = UiText.t("hud.fps", {"n": Engine.get_frames_per_second()})

func toggle_fps() -> void:
    fps_visible = not fps_visible
    fps_label.visible = fps_visible
    set_help_state("fps", fps_visible)

func is_card_visible() -> bool:
    return popup_panel.visible

## The reticle turns gold while the pointer is on the focused interactable (the "E" badge is
## on it). The hover word line and its "Click: study" / "E: ..." hints were removed with the
## interaction system (user, 12 Nov 2026; interaction_controller.gd).
func set_pointer_active(active: bool) -> void:
    if active == hover_active:
        return
    hover_active = active
    var tint: Color = Color("ffd27f") if active else Color.WHITE
    for tick in reticle_parts:
        tick.color = tint
    pointer_dot.color = tint

## `english` / `spanish` are the native / foreign text of a word without a words.json key
## (update_card() takes both from words.json when `word_key` is known).
func show_card(english: String, spanish: String, category: String = "Everyday", word_key: String = "") -> void:
    current_character = ""
    current_english = english
    current_spanish = spanish
    current_category = category
    current_word_key = word_key if word_key != "" else card_word_key(english, spanish)
    update_card()
    popup_panel.visible = true
    # The click popup of a word reveals its meaning: a question testing it counts as translated.
    if current_word_key != "":
        PracticeLog.shared().translation_shown.emit(current_word_key)
    overlay.visible = true
    reticle_group.visible = false
    # Re-center after Godot lays out PanelContainer's contents.
    _layout_hud()

# Same popup, showing a house character's name instead of a vocabulary word.
func show_name_card(character_name: String, species: String) -> void:
    show_card("", "", "")
    current_character = character_name
    current_category = species
    current_word_key = ""
    update_card()

func hide_card() -> void:
    popup_panel.visible = false
    bookmark_star.visible = false
    speaker_button.visible = false
    overlay.visible = false
    reticle_group.visible = true

## The card follows the Display Mode like the dialogue (user decision, 4 Nov 2026): Foreign
## only shows the foreign word, and holding the top-right peek badge (or L) adds the native word
## under it (since 21 Nov 2026; it had its own translate bubble); Native mode shows the native
## word (Both was removed 7 Nov 2026). Words come from data/words.json.
func update_card() -> void:
    var lexicon = Lexicon.shared()
    var language_name := func(code: String) -> String: return UiText.t("language." + code)
    if current_word_key != "":
        current_english = UiText.word(current_word_key, lexicon.native)
        current_spanish = UiText.word(current_word_key, lexicon.foreign)
    var view: Array = GameSettings.shared().view({"foreign": current_spanish, "native": current_english}, GameSettings.shared().peeking)
    category_label.text = UiText.t("card.category_word", {"category": UiText.named("categories", current_category)}).to_upper()
    if current_character != "":
        category_label.text = UiText.t("card.category_character", {"species": UiText.named("species", current_category)}).to_upper()
        title_label.text = UiText.t("card.meet").to_upper()
        primary_label.text = current_character
        PinyinText.show(reading_label, {"foreign": current_character})
        secondary_label.text = ""
    else:
        if mode == GameSettings.NATIVE:
            title_label.text = UiText.t("card.title_native", {"language": language_name.call(lexicon.native)}).to_upper()
        else:
            title_label.text = UiText.t("card.title_foreign", {"language": language_name.call(lexicon.foreign)}).to_upper()
        primary_label.text = view[0]
        PinyinText.show(reading_label, {"foreign": current_spanish})
        secondary_label.text = view[1]
    # Only dictionary words (not character introductions) can be saved.
    bookmark_star.visible = current_character == "" and current_word_key != ""
    bookmark_star.tooltip_text = UiText.t("card.unsave") if bookmarks.has(current_word_key) else UiText.t("card.save")
    bookmark_star.queue_redraw()
    speaker_button.visible = can_say_current_word()
    speaker_button.tooltip_text = UiText.t("card.say")
    # Long words can expand the card's minimum size.
    call_deferred("_layout_hud")

## Runs whenever the settings change (the Settings window's Native mode checkbox or languages).
func set_display_mode(value: int) -> void:
    mode = value
    language_changed.emit(mode)
    if is_card_visible():
        update_card()

func set_progress(room: String, count: int) -> void:
    room_english = room
    room_count = count
    if room_label != null:
        room_label.text = UiText.t("hud.words_found", {"room": UiText.place(room), "count": count})

func set_noclip(value: bool) -> void:
    set_help_state("noclip", value)
    if is_instance_valid(noclip_label):
        noclip_label.visible = value

func toggle_map() -> void:
    if is_instance_valid(map_overlay):
        map_overlay.visible = not map_overlay.visible
        quest_toast.visible = not map_overlay.visible and quest_toast_time > 0.0
        map_toggled.emit()

func is_map_open() -> bool:
    return is_instance_valid(map_overlay) and map_overlay.visible

# Builds the word-card star, the top-right book button and the saved-words list.
# All three stop mouse clicks/wheel so they never reach world picking or zoom,
# and take no keyboard focus so Space/Enter keep driving the player.
func build_bookmarks() -> void:
    var words: Dictionary = preload("res://scripts/learning/word_data.gd").load_all()
    bookmark_vocabulary = words.vocabulary
    bookmark_aliases = words.aliases
    for key in bookmark_vocabulary:
        var english: String = journal_english(str(key))
        if not bookmark_english_index.has(english):
            bookmark_english_index[english] = []
        bookmark_english_index[english].append(str(key))
    bookmarks = VocabularyProgress.load_bookmarked_words(bookmark_vocabulary, bookmark_aliases)

    bookmark_star = Button.new()
    bookmark_star.name = "Bookmark star"
    bookmark_star.flat = true
    bookmark_star.focus_mode = Control.FOCUS_NONE
    bookmark_star.mouse_filter = Control.MOUSE_FILTER_STOP
    bookmark_star.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    bookmark_star.custom_minimum_size = Vector2(44, 44)
    bookmark_star.size = Vector2(44, 44)
    bookmark_star.visible = false
    bookmark_star.draw.connect(_draw_bookmark_star)
    bookmark_star.pressed.connect(toggle_current_bookmark)
    ui_root.add_child(bookmark_star)
    speaker_button = Button.new()
    speaker_button.name = "Say word"
    speaker_button.flat = true
    speaker_button.focus_mode = Control.FOCUS_NONE
    speaker_button.mouse_filter = Control.MOUSE_FILTER_STOP
    speaker_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    speaker_button.icon = BonStyle.icon_texture("speaker", 256)
    speaker_button.expand_icon = true
    speaker_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    for state in ["icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"]:
        speaker_button.add_theme_color_override(state, Color.WHITE)
    speaker_button.visible = false
    speaker_button.pressed.connect(say_current_word)
    ui_root.add_child(speaker_button)

    bookmark_button = Button.new()
    bookmark_button.name = "Journal book"
    bookmark_button.focus_mode = Control.FOCUS_NONE
    bookmark_button.mouse_filter = Control.MOUSE_FILTER_STOP
    bookmark_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    style_corner_button(bookmark_button)
    # The journal icon in the mockups' look (24 Nov 2026, user; was a hand-drawn coral book with a
    # J): its own colours, so not tinted; the J shows in the key hint circle on keyboards.
    bookmark_button.icon = BonStyle.icon_texture("journal", 256)
    bookmark_button.expand_icon = true
    bookmark_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    for state in ["icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"]:
        bookmark_button.add_theme_color_override(state, Color.WHITE)
    bookmark_button.pressed.connect(func() -> void: journal_toggle_requested.emit())
    ui_root.add_child(bookmark_button)
    add_key_hint(bookmark_button, "journal")
    map_button = _cluster_button("Map button", "map", toggle_map)
    add_key_hint(map_button, "map")
    help_button = _cluster_button("Help button", "question", toggle_help)

## A bottom-right cluster button (style_corner_button, an icon, sized in _layout_hud).
func _cluster_button(title: String, icon: String, handler: Callable) -> Button:
    var button := Button.new()
    button.name = title
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.icon = UiIcons.texture(icon, 128)
    button.expand_icon = true
    button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    style_corner_button(button)
    button.pressed.connect(handler)
    ui_root.add_child(button)
    return button

func _hud_factor() -> float:
    var view: Vector2 = get_viewport().get_visible_rect().size
    return BonStyle.factor(view)

## The top-right peek badge and gear: 90 px at 1100 x 800 (TOP_SCALE x 60), never under 52.
func top_button_size() -> float:
    return roundf(clampf(60.0 * TOP_SCALE * _hud_factor(), 52.0, 60.0 * TOP_SCALE * 2.0))

## The peek badge and gear: top_button_size() x TOP_BIG (user, 21 Nov 2026).
func top_corner_size() -> float:
    return roundf(top_button_size() * TOP_BIG)

## Gap between the top-right buttons and the window's right edge (a phone's rounded corner).
func top_right_inset() -> float:
    return 12.0 + maxf(TOP_INSET_MIN, TOP_INSET * _hud_factor())

## Slot `index` of the bottom-right 2 x 2 cluster, all one size (120 px at 1100 x 800):
## 0 the journal (bottom right), 1 the map (left of it), 2 the minigame picker (above the
## journal), 3 help (above the map).
func bottom_slot(index: int) -> Rect2:
    var view: Vector2 = get_viewport().get_visible_rect().size
    var f := _hud_factor()
    var side: float = roundf(clampf(60.0 * CLUSTER_SCALE * f, 52.0, 60.0 * CLUSTER_SCALE * 2.0))
    var gap: float = roundf(12.0 * f)
    var column := index % 2
    var row := index / 2
    return Rect2(Vector2(view.x - 16.0 - side - column * (side + gap), view.y - 16.0 - side - row * (side + gap)), Vector2(side, side))

## The second top-right row (14 Nov 2026, user), under the top buttons and their size: 0 the
## journal (under the gear), 1 the minigame picker (under the peek badge). Clear of the clock and
## the tutorial's Skip button in the top centre.
func top_slot(index: int) -> Rect2:
    var view: Vector2 = get_viewport().get_visible_rect().size
    var corner: float = top_button_size()
    # Right-aligned under the bigger gear / peek badge above it (21 Nov 2026).
    var big: float = top_corner_size()
    return Rect2(Vector2(view.x - corner - top_right_inset() - index * (big + 10.0), 10.0 + big + 10.0), Vector2(corner, corner))

## The touch jump button in the bottom-right corner, 25% bigger than a cluster button (14 Nov
## 2026, user); E stands above it (touch_controls.gd) and Inspect left of it (hold_inspect_ui.gd).
func jump_slot() -> Rect2:
    var slot := bottom_slot(0)
    var side := roundf(slot.size.x * 1.25)
    return Rect2(slot.end - Vector2(side, side), Vector2(side, side))

## Sizes and places a style_corner_button button; its box margins and corners follow its size.
func size_corner_button(button: Button, rect: Rect2) -> void:
    button.custom_minimum_size = rect.size
    button.size = rect.size
    button.position = rect.position
    for state in ["normal", "hover", "pressed"]:
        var style := button.get_theme_stylebox(state) as StyleBoxFlat
        if style != null:
            style.set_content_margin_all(roundf(rect.size.x * 0.16))
            style.set_corner_radius_all(roundi(rect.size.x * 0.24))

## Whether the HUD hides its game buttons now (a game's cluster_off, a minigame in progress, or
## any hide_for_game() reason); the Run button (touch_controls.gd) follows it.
func game_buttons_hidden() -> bool:
    return cluster_off or in_minigame or not _hide_reasons.is_empty()

## Whether `button` is hidden by a game (cluster_off) or under what covers the lower screen
## (cluster_cover: the dialogue box).
## A gentle grow-and-shrink with a soft green tint while the tutorial asks for this button.
func _pulse(button: Control, on: bool) -> void:
    button.pivot_offset = button.size * 0.5
    if not on:
        if button.scale != Vector2.ONE:
            button.scale = Vector2.ONE
            button.self_modulate = Color.WHITE
        return
    var wave := 0.5 + 0.5 * sin(_pulse_time * 6.0)
    button.scale = Vector2.ONE * (1.0 + 0.12 * wave)
    button.self_modulate = Color.WHITE.lerp(PULSE_TINT, wave)

## Any hide_for_game() reason counts too (23 Nov 2026, user: the journal and ▶ buttons showed
## on top of Mei's mahjong lesson card, which hides the HUD with hide_for_game()).
func cluster_hidden(button: Control) -> bool:
    if game_buttons_hidden():
        return true
    if not cluster_cover.is_valid():
        return false
    var cover: Rect2 = cluster_cover.call()
    return cover.has_area() and cover.intersects(Rect2(button.position, button.size))

## The top-right gear and book and the bottom-right buttons: a cream square with a white rim and
## an INK icon; pressed turns green with a white icon (UI art style, 18 Nov 2026; sized in
## _layout_hud).
func style_corner_button(button: Button) -> void:
    var looks := {"normal": BonStyle.SKY, "hover": BonStyle.SKY_TOP, "pressed": BonStyle.GREEN_BOTTOM}
    for state in looks:
        var style := make_ui_card(looks[state], BonStyle.RIM, 12)
        style.set_border_width_all(4)
        style.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
        style.shadow_size = 6
        style.shadow_offset = Vector2(0, 3)
        style.anti_aliasing = true
        corner_styles.append(style)
        button.add_theme_stylebox_override(state, style)
    button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    for name in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
        button.add_theme_color_override(name, BonStyle.INK)
    for name in ["icon_pressed_color", "icon_hover_pressed_color"]:
        button.add_theme_color_override(name, Color.WHITE)

# Canonical dictionary key for the open card. The interaction controller shows
# English as journal_english(key) and Spanish as vocabulary[key], so match both.
func card_word_key(english: String, spanish: String) -> String:
    for key in bookmark_english_index.get(english, []):
        if str(bookmark_vocabulary.get(key, "")) == spanish:
            return key
    return ""

## Whether the open card's word can be said now (a dictionary word with a clip in the language
## being learned, spoken words switched on).
func can_say_current_word() -> bool:
    var sound = Sound.shared()
    return current_character == "" and current_word_key != "" and sound != null and sound.has_voice(current_word_key, Lexicon.shared().foreign)

func say_current_word() -> void:
    if can_say_current_word():
        Sound.shared().say_word(current_word_key, Lexicon.shared().foreign)

func is_word_bookmarked(key: String) -> bool:
    return bookmarks.has(key)

func toggle_current_bookmark() -> void:
    toggle_bookmark(current_word_key)

## Saves or unsaves one word (the card star and the vocabulary book's stars) and saves at once.
func toggle_bookmark(key: String) -> void:
    if key == "":
        return
    if bookmarks.has(key):
        bookmarks.erase(key)
    else:
        bookmarks[key] = true
        preload("res://scripts/learning/achievements.gd").shared().note("save_word")
    VocabularyProgress.save_bookmarked_words(bookmarks, bookmark_vocabulary, bookmark_aliases)
    if is_journal_open():
        journal_book.refresh_rows()
    bookmark_star.tooltip_text = UiText.t("card.unsave") if bookmarks.has(current_word_key) else UiText.t("card.save")
    bookmark_star.queue_redraw()

func _draw_bookmark_star() -> void:
    var center: Vector2 = bookmark_star.size * 0.5
    # Drawn for a 44 px button and scaled with it (the card scales with the window).
    var k: float = bookmark_star.size.x / 44.0
    if bookmark_star.is_hovered():
        bookmark_star.draw_circle(center, 21.0 * k, Color(0.48, 0.29, 0.13, 0.08))
    var points := PackedVector2Array()
    for i in 10:
        var radius: float = (17.0 if i % 2 == 0 else 7.2) * k
        var angle: float = -PI * 0.5 + i * PI / 5.0
        points.append(center + Vector2(cos(angle), sin(angle)) * radius)
    if bookmarks.has(current_word_key):
        bookmark_star.draw_colored_polygon(points, BOOKMARK_GOLD)
    points.append(points[0])
    bookmark_star.draw_polyline(points, BOOKMARK_GOLD, 2.0 * k, true)

## A big light card (the journal and the F1 guide): `fill` inside a thick white rim with a soft
## shadow (UI art style, 18 Nov 2026). A StyleBoxFlat so _layout_hud can set its margins.
func make_light_card(fill: Color, corners: int) -> StyleBoxFlat:
    var card := make_ui_card(fill, BonStyle.RIM, corners)
    card.set_border_width_all(6)
    card.shadow_color = Color(0.1, 0.27, 0.32, 0.3)
    card.shadow_size = 18
    card.shadow_offset = Vector2(0, 6)
    card.anti_aliasing = true
    return card

func make_ui_card(fill: Color, outline: Color, corners: int) -> StyleBoxFlat:
    var card := StyleBoxFlat.new()
    card.bg_color = fill
    card.border_color = outline
    card.set_border_width_all(2)
    card.set_corner_radius_all(corners)
    card.content_margin_left = 17
    card.content_margin_right = 17
    card.content_margin_top = 14
    card.content_margin_bottom = 14
    return card

func flash_quest_message(message: String) -> void:
    quest_toast.text = message
    quest_toast_time = 4.0
    quest_toast.visible = true

func is_journal_open() -> bool:
    return journal_overlay.visible

func toggle_journal(studied: Dictionary, dictionary: Dictionary, categories: Dictionary = {}, areas: Dictionary = {}, area_names: Dictionary = {}) -> void:
    journal_overlay.visible = not journal_overlay.visible
    if not journal_overlay.visible:
        journal_book.search.release_focus()
        return
    journal_studied = studied
    journal_dictionary = dictionary
    journal_categories = categories
    journal_areas = areas
    journal_area_names = area_names
    render_journal()

func set_journal_view(by_area: bool) -> void:
    journal_by_area = by_area
    render_journal()

static func journal_english(key: String) -> String:
    return key.replace("_", " ").capitalize()

## The title, view buttons and hint; the vocabulary book draws the words (every word of the
## dictionary, with filters; see scripts/ui/vocabulary_book.gd).
func render_journal() -> void:
    journal_category_button.set_pressed_no_signal(not journal_by_area)
    journal_area_button.set_pressed_no_signal(journal_by_area)
    journal_title.text = UiText.t("journal.title").to_upper()
    var studied_count := 0
    for key in journal_studied:
        if journal_dictionary.has(key):
            studied_count += 1
    journal_progress_label.text = UiText.t("journal.progress", {"count": studied_count, "total": journal_dictionary.size()})
    journal_progress.max_value = maxi(1, journal_dictionary.size())
    journal_progress.value = studied_count
    journal_hint.text = UiText.t("journal.hint_area" if journal_by_area else "journal.hint_category")
    journal_book.set_data(journal_studied, journal_dictionary, journal_categories, journal_areas, journal_area_names, bookmarks, journal_by_area)

const HELP_PLAIN_TOKENS := ["/", "+", "hold", "then"]
## Words on key caps, shown in the native language; other caps are printed key names.
const KEY_WORDS := {"hold": "help.key_hold", "then": "help.key_then", "Right-click": "help.key_right_click", "Left-click": "help.key_left_click", "Scroll": "help.key_scroll", "Space": "help.key_space"}
const HELP_ON := Color("45a83c")
const HELP_OFF := Color("c9e5e8")

## Every key in the game, grouped; rows are [keys, description, optional toggle id];
## titles and descriptions are phrase ids (help.*), key words are KEY_WORDS.
func help_sections() -> Array:
    return [
        [
            ["help.toggles", BonStyle.BROWN, [
                [["Shift"], "help.sprint", "sprint"],
                [["H"], "help.hyper", "hyper"] if Features.HYPER_SPEED else [],
                [["I"], "help.jump", "jump"],
                [["N"], "help.noclip", "noclip"],
                [["B"], "help.zones", "zones"],
                [["F3"], "help.fps", "fps"]]],
            ["help.move", Color("3f9a35"), [
                [["W", "A", "S", "D"], "help.walk"],
                [["Space"], "help.jump_row"],
                [["W", "/", "S"], "help.ladder"],
                [["hold", "Right-click"], "help.orbit"],
                [["Scroll"], "help.zoom"],
                [["Space", "/", "Ctrl"], "help.fly"]]],
        ],
        [
            ["help.learn", Color("2f87cf"), [
                [["Left-click"], "help.study"],
                [["E"], "help.use"],
                [["G"], "help.drop"],
                [["J"], "help.journal"],
                [["M"], "help.map"] if Features.FULL_MAP else [],
                [["hold", "L"], "help.peek"],
                [["F1"], "help.guide"],
                [["Esc"], "help.esc"]]],
            ["help.cars", BonStyle.TERM, [
                [["W", "/", "S"], "help.accelerate"],
                [["A", "/", "D"], "help.steer"],
                [["Space", "/", "R"], "help.brake"],
                [["F"], "help.headlights"],
                [["Q"], "help.siren"],
                [["E"], "help.get_out"]]],
            ["help.seats", Color("9a5bb5"), [
                [["A", "/", "D"], "help.swivel"],
                [["W", "/", "S"], "help.swan"],
                [["E", "then", "W", "/", "S"], "help.swing"],
                [["1", "/", "2", "/", "3"], "help.elevator"]]],
        ],
        [
            # One set of flying controls for both aircraft (23 Nov 2026, user): ▲ / ▼ on screen.
            ["help.helicopter", BonStyle.TERM, [
                [["Space", "/", "Shift"], "help.fly_up_down"],
                [["W", "/", "S"], "help.fly_speed"],
                [["A", "/", "D"], "help.fly_turn"],
                [["E"], "help.heli_exit"]]],
            ["help.turboprop", BonStyle.TERM, [
                [["Space", "/", "Shift"], "help.fly_up_down"],
                [["W", "/", "S"], "help.fly_speed"],
                [["A", "/", "D"], "help.fly_turn"],
                [["W", "/", "Space"], "help.fly_take_off"],
                [["E"], "help.heli_exit"]]],
        ],
    ]

func make_keycap(text: String) -> PanelContainer:
    var cap := PanelContainer.new()
    cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = BonStyle.RIM
    style.border_color = BonStyle.SKY_EDGE
    style.set_border_width_all(1)
    style.border_width_bottom = 3
    style.set_corner_radius_all(5)
    style.content_margin_left = 7
    style.content_margin_right = 7
    style.content_margin_top = 1
    style.content_margin_bottom = 1
    cap.add_theme_stylebox_override("panel", style)
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 13)
    label.add_theme_color_override("font_color", BonStyle.INK)
    label.add_theme_font_override("font", BonStyle.font(700))
    cap.add_child(label)
    return cap

func make_help_row(keys: Array, description: String, toggle_id: String) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    var key_box := HBoxContainer.new()
    key_box.add_theme_constant_override("separation", 4)
    key_box.custom_minimum_size.x = 112
    key_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    for key in keys:
        if key in HELP_PLAIN_TOKENS:
            var plain := Label.new()
            plain.text = UiText.maybe(KEY_WORDS.get(key, str(key)))
            plain.add_theme_font_size_override("font_size", 12)
            plain.add_theme_color_override("font_color", BonStyle.INK_SOFT)
            key_box.add_child(plain)
        else:
            key_box.add_child(make_keycap(UiText.maybe(KEY_WORDS.get(key, str(key)))))
    row.add_child(key_box)
    var text := Label.new()
    text.text = UiText.t(description)
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.custom_minimum_size.x = 90
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text.add_theme_font_size_override("font_size", 14)
    text.add_theme_color_override("font_color", Color("3d5560"))
    row.add_child(text)
    if not toggle_id.is_empty():
        var pill := PanelContainer.new()
        pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
        pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        pill.custom_minimum_size.x = 58
        var style := StyleBoxFlat.new()
        style.bg_color = HELP_OFF
        style.set_corner_radius_all(9)
        style.content_margin_left = 6
        style.content_margin_right = 6
        style.content_margin_top = 1
        style.content_margin_bottom = 1
        pill.add_theme_stylebox_override("panel", style)
        var state := Label.new()
        state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        state.add_theme_font_size_override("font_size", 12)
        pill.add_child(state)
        row.add_child(pill)
        help_pills[toggle_id] = {"label": state, "style": style}
    return row

func build_help_content() -> void:
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 8)
    help_overlay.add_child(body)
    var header := HBoxContainer.new()
    body.add_child(header)
    var title := Label.new()
    title.text = UiText.t("help.title").to_upper()
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", BonStyle.INK)
    title.add_theme_font_override("font", BonStyle.font(700))
    header.add_child(title)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    var close_hint := Label.new()
    close_hint.text = UiText.t("help.close")
    close_hint.add_theme_font_size_override("font_size", 14)
    close_hint.add_theme_color_override("font_color", BonStyle.INK_SOFT)
    header.add_child(close_hint)
    help_close = Button.new()
    help_close.name = "Close help"
    help_close.focus_mode = Control.FOCUS_NONE
    help_close.mouse_filter = Control.MOUSE_FILTER_STOP
    help_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    help_close.expand_icon = true
    help_close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help_close.icon = UiIcons.texture("close", 64)
    help_close.tooltip_text = UiText.t("help.close")
    help_close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    journal_book.style_button(help_close, "plain")
    help_close.pressed.connect(toggle_help)
    header.add_child(help_close)
    _size_help_close()
    help_scroll = ScrollContainer.new()
    help_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    help_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(help_scroll)
    # A light scroll bar like the journal's (UI art style, 18 Nov 2026).
    var bar := help_scroll.get_v_scroll_bar()
    for part in [["scroll", Color("cfe8eb")], ["grabber", Color("9fcfd5")], ["grabber_highlight", Color("8cc6cd")], ["grabber_pressed", BonStyle.GREEN_BOTTOM]]:
        var look := StyleBoxFlat.new()
        look.bg_color = part[1]
        look.set_corner_radius_all(8)
        bar.add_theme_stylebox_override(part[0], look)
    var flow := HFlowContainer.new()
    flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    flow.add_theme_constant_override("h_separation", 14)
    flow.add_theme_constant_override("v_separation", 14)
    help_scroll.add_child(flow)
    for column in help_sections():
        var stack := VBoxContainer.new()
        stack.custom_minimum_size.x = 345
        stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        stack.add_theme_constant_override("separation", 12)
        flow.add_child(stack)
        for section in column:
            var card := PanelContainer.new()
            card.add_theme_stylebox_override("panel", make_ui_card(BonStyle.SKY, BonStyle.RIM, 18))
            stack.add_child(card)
            var rows := VBoxContainer.new()
            rows.add_theme_constant_override("separation", 5)
            card.add_child(rows)
            var heading := Label.new()
            heading.text = UiText.t(section[0]).to_upper()
            heading.add_theme_font_size_override("font_size", 15)
            heading.add_theme_font_override("font", BonStyle.font(700))
            heading.add_theme_color_override("font_color", section[1])
            rows.add_child(heading)
            for entry in section[2]:
                if entry.is_empty():
                    continue   # a switched-off feature's row (Features)
                rows.add_child(make_help_row(entry[0], entry[1], entry[2] if entry.size() > 2 else ""))
    for id in ["sprint", "hyper", "jump", "noclip", "zones", "fps"]:
        var state: Array = help_states.get(id, [id == "jump" and Features.INFINITE_JUMP_AT_START, ""])
        set_help_state(id, state[0], state[1])

## Updates a toggle pill in the F1 guide; text overrides the default ON / OFF.
func set_help_state(id: String, on: bool, text: String = "") -> void:
    help_states[id] = [on, text]
    if not help_pills.has(id):
        return
    var pill: Dictionary = help_pills[id]
    var label: Label = pill["label"]
    var style: StyleBoxFlat = pill["style"]
    label.text = text if not text.is_empty() else UiText.t("hud.on" if on else "hud.off")
    label.add_theme_color_override("font_color", Color("ffffff") if on else BonStyle.INK_SOFT)
    style.bg_color = HELP_ON if on else HELP_OFF

func set_infinite_jump(enabled: bool) -> void:
    set_help_state("jump", enabled)
    flash_quest_message(UiText.t("hud.jump_toggle", {"state": UiText.t("hud.on" if enabled else "hud.off")}))

func toggle_help() -> void:
    help_overlay.visible = not help_overlay.visible
    help_toggled.emit()

## The ✕ is a finger-sized square: the corner buttons' size (bottom_slot(), never under 52 px).
func _size_help_close() -> void:
    if help_close != null and is_inside_tree():
        var side: float = bottom_slot(0).size.x
        help_close.custom_minimum_size = Vector2(side, side)
        help_close.add_theme_constant_override("icon_max_width", roundi(side * 0.5))

func is_help_open() -> bool:
    return help_overlay.visible

## Adds a key hint circle to a HUD button for `action` (see key_hints). Other HUD owners call it
## too (game_launcher.gd: the ▶ picker, "games").
func add_key_hint(button: Control, action: String) -> void:
    var key := key_label(action)
    if key == "":
        return
    var hint := Control.new()
    hint.name = "Key hint"
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hint.set_meta("key", key)
    hint.draw.connect(_draw_key_hint.bind(hint))
    hint.visible = keyboard_hints
    button.add_child(hint)
    button.resized.connect(_place_key_hint.bind(hint))
    _place_key_hint(hint)
    key_hints.append(hint)

## The key bound to `action` as players read it on the keyboard: "J", "Esc", "F9"; "" if none.
static func key_label(action: String) -> String:
    if not InputMap.has_action(action):
        return ""
    for event in InputMap.action_get_events(action):
        if event is InputEventKey:
            var code: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
            var text := OS.get_keycode_string(code)
            return "Esc" if text == "Escape" else text
    return ""

func _place_key_hint(hint: Control) -> void:
    var button := hint.get_parent() as Control
    var side := roundf(clampf(button.size.x * 0.4, 22.0, 48.0))
    hint.size = Vector2(side, side)
    hint.position = Vector2(-side * 0.22, button.size.y - side * 0.78)
    hint.queue_redraw()

func _draw_key_hint(hint: Control) -> void:
    var side: float = hint.size.x
    var key: String = hint.get_meta("key")
    var center := Vector2(side, side) * 0.5
    # A short key is a circle; a longer one ("Esc", "F9") a pill just wide enough.
    var font: Font = BonStyle.font(700)
    var font_size := roundi(side * (0.56 if key.length() == 1 else 0.42))
    var text_size: Vector2 = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
    var width := maxf(side, text_size.x + side * 0.5)
    var box := StyleBoxFlat.new()
    box.bg_color = BonStyle.INK
    box.border_color = BonStyle.RIM
    box.set_border_width_all(maxi(2, roundi(side * 0.09)))
    box.set_corner_radius_all(roundi(side * 0.5))
    box.anti_aliasing = true
    box.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
    box.shadow_size = roundi(side * 0.08)
    box.draw(hint.get_canvas_item(), Rect2(Vector2(center.x - width * 0.5, 0), Vector2(width, side)))
    var baseline := Vector2(center.x - text_size.x * 0.5, center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
    hint.draw_string(font, baseline, key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

## Shows or hides every key hint circle (keyboard play on, touch off).
func set_keyboard_hints(on: bool) -> void:
    keyboard_hints = on
    for hint in key_hints:
        if is_instance_valid(hint):
            hint.visible = on

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not keyboard_hints:
        set_keyboard_hints(true)
    elif (event is InputEventScreenTouch or event is InputEventScreenDrag) and keyboard_hints:
        set_keyboard_hints(false)

func set_touch_mode(on: bool) -> void:
    if on and keyboard_hints:
        set_keyboard_hints(false)
    if touch_mode != on:
        touch_mode = on
        set_movement_mode(move_sprinting, move_hyper)

func set_movement_mode(sprinting: bool, hyper: bool) -> void:
    move_sprinting = sprinting
    move_hyper = hyper
    # A touch screen has no keys: the line leaves out the key hints (13 Nov 2026).
    var suffix := "_touch" if touch_mode and (hyper or sprinting) else ""
    movement_label.text = UiText.t(("hud.move_hyper" if hyper else ("hud.move_sprint" if sprinting else "hud.move_walk")) + suffix)
    movement_label.add_theme_color_override("font_color", Color("00BFFF") if hyper else Color("fff2d8"))
    if not _hidden_for_game.has(movement_label):
        movement_label.visible = sprinting or hyper
    set_help_state("sprint", sprinting)
    set_help_state("hyper", hyper)
