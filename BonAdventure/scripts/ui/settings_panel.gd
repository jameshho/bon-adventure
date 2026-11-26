extends Control
## The Settings window (user decision, 4 Nov 2026): Esc with nothing else open, or the
## gear on the HUD, opens it; Esc or Close shuts it. It sets Native mode (a checkbox, 7 Nov
## 2026; GameSettings.NATIVE) and the native and foreign languages through GameSettings (saved to user://settings.json); Main reacts
## to GameSettings.changed. The same language may be picked for both (the user tests with
## it). Labels show in the native language (data/phrases.json settings.*, language.*).
## Layout scales with min(window height / 800, window width / 1100) like the money panel.
## The native language is first chosen when a profile is made (app_screens.gd). It was shown
## locked here from 12 Nov 2026 (PWA phase 3); since 14 Nov 2026 (user) it changes here again.
## "Show FPS" for the perf readout (perf_readout.gd). The Low / High graphics buttons (14 Nov 2026)
## were removed on 23 Nov 2026 (user: one graphics setting, render_culling.gd).
## "Camera follows me" (14 Nov 2026, user): the follow camera's checkbox, on by default
## (GameSettings.set_follow_camera; player_controller.gd follow_view()).
## "Switch player" (only when the game runs from scenes/app.tscn) goes back to the profile select.
## UI art style (user, 18 Nov 2026; docs/guides/UI_STYLE.md): a mint BonStyle card with a meadow
## over a light teal veil, a dark teal title, cream checkboxes that turn green, cream drop-downs,
## cream Switch / Replay pills and a green Close.
## Sound (24 Nov 2026, user): Main volume, Music, Sound effects and Spoken words sliders in a
## 2 x 2 grid (GameSettings.set_volume; game_settings.gd VOLUME_BUSES); a drag sets the sound at
## once and saves when it ends.
## "Controls" (25 Nov 2026, improvement plan UI-04): opens the F1 controls guide, which shows the
## touch controls on a touch device (the only way to it without a keyboard); it emits
## controls_requested and Main closes this window and opens the guide.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const PerfReadout := preload("res://scripts/ui/perf_readout.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")

const GOLD := BonStyle.INK
const DIM := BonStyle.INK_SOFT
const DESIGN := Vector2(1100, 800)

signal controls_requested
## Main hides the Controls button while a minigame runs (the guide is closed then).
var controls_allowed := true

var _card: PanelContainer
var _stack: VBoxContainer
var _title: Label
var _native_mode: CheckBox
var _native_title: Label
var _foreign_title: Label
var _native_pick: OptionButton
var _foreign_pick: OptionButton
var _close_button: Button
var _switch_button: Button
var _replay_button: Button
var _controls_button: Button
var _profile_row: HBoxContainer
var _x_button: Button
var _show_fps: CheckBox
var _follow_camera: CheckBox
var _sound_grid: GridContainer
## Slider group ("master", ...) -> [title Label, HSlider].
var _volume_rows: Dictionary = {}
var _factor := 1.0

func _init() -> void:
	name = "Settings panel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	var shade := ColorRect.new()
	shade.color = BonStyle.SHADE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	add_child(shade)
	_stack = VBoxContainer.new()
	_card = BonStyle.card(_stack, 1.0)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var head := HBoxContainer.new()
	_stack.add_child(head)
	_title = _label(GOLD)
	head.add_child(_title)
	_x_button = _button()
	_x_button.icon = UiIcons.texture("close", 64)
	_x_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_x_button.pressed.connect(close)
	head.add_child(_x_button)
	# Native mode (user decision, 7 Nov 2026): one checkbox, off by default.
	_native_mode = CheckBox.new()
	_native_mode.focus_mode = Control.FOCUS_NONE
	_native_mode.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_native_mode.add_theme_color_override("font_color", GOLD)
	_native_mode.add_theme_color_override("font_pressed_color", GOLD)
	_native_mode.add_theme_color_override("font_hover_color", GOLD)
	_native_mode.add_theme_color_override("font_hover_pressed_color", GOLD)
	_native_mode.toggled.connect(func(on: bool) -> void: GameSettings.shared().set_native(on))
	# One row with "Show FPS" on its right keeps the card short on a landscape phone.
	var mode_row := HBoxContainer.new()
	_stack.add_child(mode_row)
	_native_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_child(_native_mode)
	_native_title = _label(DIM)
	_stack.add_child(_native_title)
	_native_pick = _picker()
	_stack.add_child(_native_pick)
	_foreign_title = _label(DIM)
	_stack.add_child(_foreign_title)
	_foreign_pick = _picker()
	_stack.add_child(_foreign_pick)
	_native_pick.item_selected.connect(func(_i: int) -> void: _pick_languages())
	_foreign_pick.item_selected.connect(func(_i: int) -> void: _pick_languages())
	_show_fps = CheckBox.new()
	_show_fps.focus_mode = Control.FOCUS_NONE
	_show_fps.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		_show_fps.add_theme_color_override(state, GOLD)
	_show_fps.toggled.connect(func(on: bool) -> void:
		var readout := PerfReadout.find(get_tree())
		if readout != null:
			readout.set_shown(on))
	mode_row.add_child(_show_fps)
	_follow_camera = CheckBox.new()
	_follow_camera.focus_mode = Control.FOCUS_NONE
	_follow_camera.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		_follow_camera.add_theme_color_override(state, GOLD)
	_follow_camera.toggled.connect(func(on: bool) -> void: GameSettings.shared().set_follow_camera(on))
	_stack.add_child(_follow_camera)
	_stack.move_child(_follow_camera, mode_row.get_index() + 1)
	_sound_grid = GridContainer.new()
	_sound_grid.columns = 2
	_stack.add_child(_sound_grid)
	for group in GameSettings.VOLUME_ORDER:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_sound_grid.add_child(cell)
		var title := _label(DIM)
		cell.add_child(title)
		var slider := HSlider.new()
		slider.name = "Volume " + group
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.focus_mode = Control.FOCUS_NONE
		slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(value: float) -> void: GameSettings.shared().set_volume(group, value, false))
		slider.drag_ended.connect(func(_changed: bool) -> void: GameSettings.shared().set_volume(group, slider.value))
		cell.add_child(slider)
		_volume_rows[group] = [title, slider]
	# Profile actions on one row: Switch profile, and the welcome tutorial again (app.gd
	# replay_tutorial(), PWA phase 6).
	_profile_row = HBoxContainer.new()
	_profile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_stack.add_child(_profile_row)
	_switch_button = _button()
	_switch_button.pressed.connect(func() -> void:
		var app := get_tree().current_scene
		if app != null and app.has_method("switch_profile"):
			app.switch_profile())
	_profile_row.add_child(_switch_button)
	_replay_button = _button()
	_replay_button.pressed.connect(func() -> void:
		var app := get_tree().current_scene
		if app != null and app.has_method("replay_tutorial"):
			close()
			app.replay_tutorial())
	_profile_row.add_child(_replay_button)
	_controls_button = _button()
	_controls_button.name = "Controls"
	_controls_button.icon = UiIcons.texture("question", 64)
	_controls_button.pressed.connect(func() -> void: controls_requested.emit())
	_profile_row.add_child(_controls_button)
	_close_button = _button()
	_close_button.icon = UiIcons.texture("close", 64)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(close)
	_stack.add_child(_close_button)

func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	GameSettings.shared().changed.connect(refresh)

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	visible = false

## Re-reads the settings (also after a change: the labels follow the native language).
func refresh() -> void:
	if not visible:
		return
	var settings = GameSettings.shared()
	var lexicon = Lexicon.shared()
	var lang: String = lexicon.native
	_title.text = lexicon.phrase("settings.title", lang)
	_native_mode.text = lexicon.phrase("settings.native_mode", lang)
	_native_mode.set_pressed_no_signal(settings.is_native())
	_follow_camera.text = lexicon.phrase("settings.follow_camera", lang)
	_follow_camera.set_pressed_no_signal(settings.follow_camera)
	_native_title.text = lexicon.phrase("settings.native_language", lang)
	_foreign_title.text = lexicon.phrase("settings.foreign_language", lang)
	for pick in [_native_pick, _foreign_pick]:
		pick.clear()
		for code in lexicon.playable_codes():
			# The language's name in the native language, plus its own name when that differs.
			var shown: String = lexicon.phrase("language." + str(code), lang)
			var own := str(lexicon.languages[code].get("name", code))
			pick.add_item(shown if own == shown else shown + "  (" + own + ")")
			pick.set_item_metadata(pick.item_count - 1, str(code))
	_native_pick.select(lexicon.playable_codes().find(settings.native))
	_foreign_pick.select(lexicon.playable_codes().find(settings.foreign))
	for group in _volume_rows:
		_volume_rows[group][0].text = lexicon.phrase("settings.volume_" + group, lang)
		_volume_rows[group][1].set_value_no_signal(settings.volumes.get(group, 1.0))
	_show_fps.text = lexicon.phrase("settings.show_fps", lang)
	var readout := PerfReadout.find(get_tree())
	_show_fps.visible = readout != null
	_show_fps.set_pressed_no_signal(readout != null and readout.visible)
	_close_button.text = lexicon.phrase("settings.close", lang)
	_switch_button.text = lexicon.phrase("settings.switch_profile", lang)
	var app := get_tree().current_scene
	_switch_button.visible = app != null and app.has_method("switch_profile")
	_replay_button.text = lexicon.phrase("tutorial.replay", lang)
	_replay_button.visible = app != null and app.has_method("replay_tutorial")
	_controls_button.text = lexicon.phrase("help.title", lang)
	_controls_button.visible = controls_allowed
	_profile_row.visible = _switch_button.visible or _replay_button.visible or _controls_button.visible
	_x_button.tooltip_text = _close_button.text
	_layout()

func _pick_languages() -> void:
	GameSettings.shared().set_languages(str(_native_pick.get_selected_metadata()), str(_foreign_pick.get_selected_metadata()))

func _layout() -> void:
	var screen := get_viewport_rect().size
	_factor = clampf(minf(screen.y / DESIGN.y, screen.x / DESIGN.x), 0.6, 3.0)
	# A short window (a small landscape phone) shrinks the card until it fits (14 Nov 2026).
	for attempt in 2:
		_apply_layout(screen)
		if _card.size.y <= screen.y - 12.0:
			break
		_factor *= (screen.y - 12.0) / _card.size.y

func _apply_layout(screen: Vector2) -> void:
	var f := _factor
	BonStyle.rescale_card(_card, f)
	_stack.add_theme_constant_override("separation", roundi(14 * f))
	_title.add_theme_font_size_override("font_size", roundi(40 * f))
	for label in [_native_title, _foreign_title]:
		label.add_theme_font_size_override("font_size", roundi(24 * f))
	_sound_grid.add_theme_constant_override("h_separation", roundi(28 * f))
	_sound_grid.add_theme_constant_override("v_separation", roundi(6 * f))
	for group in _volume_rows:
		_volume_rows[group][0].add_theme_font_size_override("font_size", roundi(22 * f))
		BonStyle.style_slider(_volume_rows[group][1], f)
	for check in [_native_mode, _follow_camera, _show_fps]:
		BonStyle.style_check(check, f, 24 if check == _show_fps else 26)
	for pick in [_native_pick, _foreign_pick]:
		BonStyle.style_option(pick, f, 26)
	BonStyle.style_button(_switch_button, "soft", f, 26)
	BonStyle.style_button(_replay_button, "soft", f, 26)
	BonStyle.style_button(_controls_button, "soft", f, 26)
	BonStyle.style_button(_close_button, "primary", f, 28)
	BonStyle.style_button(_x_button, "soft_quiet", f, 26)
	for button in [_close_button, _switch_button, _replay_button, _controls_button, _native_pick, _foreign_pick]:
		button.custom_minimum_size = Vector2(0, 64 * f)
		button.add_theme_constant_override("icon_max_width", roundi(26 * f))
	_close_button.custom_minimum_size = Vector2(220 * f, 66 * f)
	_switch_button.custom_minimum_size = Vector2(220 * f, 64 * f)
	_replay_button.custom_minimum_size = Vector2(220 * f, 64 * f)
	_controls_button.custom_minimum_size = Vector2(180 * f, 64 * f)
	_profile_row.add_theme_constant_override("separation", roundi(14 * f))
	_x_button.custom_minimum_size = Vector2(56 * f, 56 * f)
	_x_button.add_theme_constant_override("icon_max_width", roundi(24 * f))
	var width := minf(760.0 * f, screen.x - 40.0)
	_card.size = Vector2(width, 0)
	_card.size = Vector2(width, _card.get_combined_minimum_size().y)
	_card.position = (screen - _card.size) * 0.5

func _label(color: Color) -> Label:
	var label := Label.new()
	BonStyle.use_font(label, 700)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Short titles on one line: a wrapped label measured before its first layout reports
	# one letter per line and stretches the card.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	return label

func _button() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

func _picker() -> OptionButton:
	var pick := OptionButton.new()
	pick.focus_mode = Control.FOCUS_NONE
	pick.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return pick
