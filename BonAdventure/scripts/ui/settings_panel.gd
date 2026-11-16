extends Control
## The Settings window (user decision, 4 Nov 2026): Esc with nothing else open, or the
## gear on the HUD, opens it; Esc or Close shuts it. It sets Native mode (a checkbox, 7 Nov
## 2026; GameSettings.NATIVE) and the native and foreign languages through GameSettings (saved to user://settings.json); Main reacts
## to GameSettings.changed. The same language may be picked for both (the user tests with
## it). Labels show in the native language (data/phrases.json settings.*, language.*).
## Layout scales with min(window height / 800, window width / 1100) like the money panel.
## The native language is first chosen when a profile is made (app_screens.gd). It was shown
## locked here from 12 Nov 2026 (PWA phase 3); since 14 Nov 2026 (user) it changes here again.
## Graphics quality (14 Nov 2026): two buttons, Low (default) and High (GameSettings.set_graphics,
## applied at once by render_culling.gd), and "Show FPS" for the perf readout (perf_readout.gd).
## "Camera follows me" (14 Nov 2026, user): the follow camera's checkbox, on by default
## (GameSettings.set_follow_camera; player_controller.gd follow_view()).
## "Switch player" (only when the game runs from scenes/app.tscn) goes back to the profile select.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const PerfReadout := preload("res://scripts/ui/perf_readout.gd")

const FILL := Color("142a38")
const EDGE := Color("7abfb3")
const GOLD := Color("fff1c5")
const DIM := Color("aadddc")
const DESIGN := Vector2(1100, 800)

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
var _profile_row: HBoxContainer
var _x_button: Button
var _graphics_title: Label
var _graphics_row: HBoxContainer
var _low_button: Button
var _high_button: Button
var _show_fps: CheckBox
var _follow_camera: CheckBox
var _factor := 1.0

func _init() -> void:
	name = "Settings panel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.08, 0.7)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	add_child(shade)
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	_card.add_theme_stylebox_override("panel", style)
	add_child(_card)
	_stack = VBoxContainer.new()
	_card.add_child(_stack)
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
	# Graphics quality: its title, then Low and High as one pair of big toggle buttons, on one row.
	_graphics_row = HBoxContainer.new()
	_stack.add_child(_graphics_row)
	_graphics_title = _label(DIM)
	_graphics_title.size_flags_stretch_ratio = 1.2
	_graphics_row.add_child(_graphics_title)
	var group := ButtonGroup.new()
	_low_button = _button()
	_high_button = _button()
	for pair in [[_low_button, GameSettings.LOW], [_high_button, GameSettings.HIGH]]:
		var choice: Button = pair[0]
		var value: String = pair[1]
		choice.toggle_mode = true
		choice.button_group = group
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.pressed.connect(func() -> void: GameSettings.shared().set_graphics(value))
		_graphics_row.add_child(choice)
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
	_graphics_title.text = lexicon.phrase("settings.graphics", lang)
	_low_button.text = lexicon.phrase("settings.graphics_low", lang)
	_high_button.text = lexicon.phrase("settings.graphics_high", lang)
	_low_button.set_pressed_no_signal(settings.graphics == GameSettings.LOW)
	_high_button.set_pressed_no_signal(settings.graphics == GameSettings.HIGH)
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
	_profile_row.visible = _switch_button.visible or _replay_button.visible
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
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(26 * f)
	_stack.add_theme_constant_override("separation", roundi(14 * f))
	_title.add_theme_font_size_override("font_size", roundi(34 * f))
	for label in [_native_title, _foreign_title, _graphics_title]:
		label.add_theme_font_size_override("font_size", roundi(24 * f))
	_native_mode.add_theme_font_size_override("font_size", roundi(26 * f))
	_native_mode.custom_minimum_size = Vector2(0, 60 * f)
	_native_mode.add_theme_constant_override("h_separation", roundi(14 * f))
	# The box is drawn from the theme icons, so it is redrawn at the scaled size.
	_native_mode.add_theme_icon_override("checked", UiIcons.texture("box_checked", roundi(40 * f)))
	_native_mode.add_theme_icon_override("unchecked", UiIcons.texture("box", roundi(40 * f)))
	_follow_camera.add_theme_font_size_override("font_size", roundi(26 * f))
	_follow_camera.custom_minimum_size = Vector2(0, 60 * f)
	_follow_camera.add_theme_constant_override("h_separation", roundi(14 * f))
	_follow_camera.add_theme_icon_override("checked", UiIcons.texture("box_checked", roundi(40 * f)))
	_follow_camera.add_theme_icon_override("unchecked", UiIcons.texture("box", roundi(40 * f)))
	_show_fps.add_theme_font_size_override("font_size", roundi(24 * f))
	_show_fps.custom_minimum_size = Vector2(0, 56 * f)
	_show_fps.add_theme_constant_override("h_separation", roundi(14 * f))
	_show_fps.add_theme_icon_override("checked", UiIcons.texture("box_checked", roundi(36 * f)))
	_show_fps.add_theme_icon_override("unchecked", UiIcons.texture("box", roundi(36 * f)))
	_graphics_row.add_theme_constant_override("separation", roundi(14 * f))
	for button in [_close_button, _switch_button, _replay_button, _native_pick, _foreign_pick, _low_button, _high_button]:
		button.add_theme_font_size_override("font_size", roundi(26 * f))
		button.custom_minimum_size = Vector2(0, 60 * f)
		button.add_theme_constant_override("icon_max_width", roundi(26 * f))
	_close_button.custom_minimum_size = Vector2(220 * f, 60 * f)
	_switch_button.custom_minimum_size = Vector2(220 * f, 60 * f)
	_replay_button.custom_minimum_size = Vector2(220 * f, 60 * f)
	_profile_row.add_theme_constant_override("separation", roundi(14 * f))
	_x_button.custom_minimum_size = Vector2(56 * f, 50 * f)
	_x_button.add_theme_constant_override("icon_max_width", roundi(26 * f))
	_native_pick.get_popup().add_theme_font_size_override("font_size", roundi(26 * f))
	_foreign_pick.get_popup().add_theme_font_size_override("font_size", roundi(26 * f))
	var width := minf(760.0 * f, screen.x - 40.0)
	_card.size = Vector2(width, 0)
	_card.size = Vector2(width, _card.get_combined_minimum_size().y)
	_card.position = (screen - _card.size) * 0.5

func _label(color: Color) -> Label:
	var label := Label.new()
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
