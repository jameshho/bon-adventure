extends Control
## The HUD clock (9 Nov 2026; guide: docs/guides/performance/README.md#day-night-cycle--9-november-2026).
## A pill at the top centre shows the game time in 12-hour form ("8:30 PM", native language via
## hud.clock_am / clock_pm) with a sun, moon or pause icon. Clicking it opens a compact panel:
## − / + move the time one hour (and pause the cycle, day_night.gd step_hours()), Resume starts
## it again, Close (or Esc, Main's popup stack) hides the panel and keeps the chosen time.
## Sizes follow the window like the other HUD panels: f = min(height / 800, width / 1100).
## Only redraws when the shown minute, the pause state or the language changes.

const UiText := preload("res://scripts/language/ui_text.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const GameClock := preload("res://scripts/learning/game_clock.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const INK := Color("fff6e6")
const GOLD := Color("e6c58c")
const TEAL := Color("a9d5c6")

var day_night
var hud
var pill: Button
var panel: PanelContainer
var time_label: Label
var title_label: Label
var status_label: Label
var back_button: Button
var forward_button: Button
var resume_button: Button
var close_button: Button
## True hides the clock (the welcome tutorial, user 18 Nov 2026: no clock while it runs).
var kept_hidden := false
var _scale := 1.0
var _styles: Array = []


func setup(cycle, owner_hud) -> void:
	day_night = cycle
	hud = owner_hud
	name = "Day clock"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	day_night.time_changed.connect(func(_minute: int) -> void: _refresh())
	day_night.paused_changed.connect(func(_paused: bool) -> void: _refresh())
	GameSettings.shared().changed.connect(_refresh_text)
	# Full-screen windows (map, journal, help) cover the clock like the corner buttons.
	for overlay in [hud.map_overlay, hud.journal_overlay, hud.help_overlay]:
		overlay.visibility_changed.connect(_update_covered)
	get_viewport().size_changed.connect(_layout)
	_refresh_text()
	_layout()


func open() -> void:
	panel.visible = true


func close() -> void:
	panel.visible = false


func toggle() -> void:
	panel.visible = not panel.visible


## The shown time, e.g. "8:30 PM" (native language).
func time_text() -> String:
	var minute: int = day_night.clock_minute()
	return UiText.t("hud.clock_am" if GameClock.is_am(minute) else "hud.clock_pm", {"time": GameClock.clock12(minute)})


func _build() -> void:
	pill = Button.new()
	pill.name = "Clock"
	pill.focus_mode = Control.FOCUS_NONE
	pill.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pill.expand_icon = false
	pill.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_button(pill, Color("142a38"), Color("7abfb3"))
	pill.pressed.connect(toggle)
	add_child(pill)

	panel = PanelContainer.new()
	panel.name = "Clock panel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var card := _box(Color(0.07, 0.14, 0.19, 0.97), Color("e7c27c"), 18)
	card.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", card)
	add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(stack)
	title_label = _label(GOLD)
	stack.add_child(title_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(row)
	back_button = _icon_button("minus")
	back_button.pressed.connect(func() -> void: day_night.step_hours(-1))
	row.add_child(back_button)
	time_label = _label(INK)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(time_label)
	forward_button = _icon_button("plus")
	forward_button.pressed.connect(func() -> void: day_night.step_hours(1))
	row.add_child(forward_button)
	status_label = _label(TEAL)
	stack.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(actions)
	resume_button = _icon_button("play")
	resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_button.pressed.connect(func() -> void: day_night.resume())
	actions.add_child(resume_button)
	close_button = _icon_button("close")
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(close)
	actions.add_child(close_button)


func _label(color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	return label


func _icon_button(icon: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("icon_name", icon)
	_style_button(button, Color("1d3a4c"), Color("7abfb3"))
	return button


func _style_button(button: Button, fill: Color, edge: Color) -> void:
	var looks := {"normal": [fill, edge], "hover": [fill.lightened(0.12), TEAL], "pressed": [fill.lightened(0.12), Color("ffd27f")], "disabled": [fill.darkened(0.25), fill.lightened(0.2)]}
	for state in looks:
		var style := _box(looks[state][0], looks[state][1], 12)
		button.add_theme_stylebox_override(state, style)
		if state == "hover":
			button.add_theme_stylebox_override("hover_pressed", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(color, INK)
	button.add_theme_color_override("font_disabled_color", INK.darkened(0.45))
	button.add_theme_color_override("icon_disabled_color", INK.darkened(0.45))


func _box(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	_styles.append(style)
	return style


func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	_scale = clampf(minf(view.y / 800.0, view.x / 1100.0), 0.5, 3.0)
	var f := _scale
	var height := roundf(clampf(52.0 * f, 46.0, 104.0))
	for style in _styles:
		style.content_margin_left = roundf(14.0 * f)
		style.content_margin_right = roundf(14.0 * f)
		style.content_margin_top = roundf(6.0 * f)
		style.content_margin_bottom = roundf(6.0 * f)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		(pill.get_theme_stylebox(state) as StyleBoxFlat).set_corner_radius_all(roundi(height * 0.5))
	pill.add_theme_font_size_override("font_size", roundi(21.0 * f))
	pill.add_theme_constant_override("icon_max_width", roundi(26.0 * f))
	pill.add_theme_constant_override("h_separation", roundi(9.0 * f))
	pill.custom_minimum_size = Vector2(roundf(176.0 * f), height)
	pill.size = pill.custom_minimum_size
	pill.position = Vector2(roundf((view.x - pill.size.x) * 0.5), 10.0)
	var card: StyleBoxFlat = panel.get_theme_stylebox("panel")
	card.set_content_margin_all(roundf(16.0 * f))
	title_label.add_theme_font_size_override("font_size", roundi(17.0 * f))
	time_label.add_theme_font_size_override("font_size", roundi(30.0 * f))
	time_label.custom_minimum_size = Vector2(roundf(150.0 * f), 0)
	status_label.add_theme_font_size_override("font_size", roundi(15.0 * f))
	for button in [back_button, forward_button]:
		button.custom_minimum_size = Vector2(roundf(64.0 * f), roundf(58.0 * f))
	for button in [resume_button, close_button]:
		button.custom_minimum_size = Vector2(roundf(132.0 * f), roundf(52.0 * f))
		button.add_theme_font_size_override("font_size", roundi(18.0 * f))
	for button in [back_button, forward_button, resume_button, close_button]:
		button.icon = UiIcons.texture(button.get_meta("icon_name"), roundi(26.0 * f))
	for box in panel.find_children("*", "BoxContainer", true, false):
		box.add_theme_constant_override("separation", roundi(10.0 * f))
	panel.reset_size()
	var width := maxf(panel.get_combined_minimum_size().x, 330.0 * f)
	panel.size = Vector2(width, 0)
	panel.position = Vector2(roundf((view.x - width) * 0.5), pill.position.y + height + roundf(8.0 * f))
	_refresh()


func _refresh_text() -> void:
	title_label.text = UiText.t("hud.clock_title")
	resume_button.text = UiText.t("hud.clock_resume")
	close_button.text = UiText.t("hud.clock_close")
	back_button.tooltip_text = UiText.t("hud.clock_back")
	forward_button.tooltip_text = UiText.t("hud.clock_forward")
	pill.tooltip_text = UiText.t("hud.clock_open")
	_refresh()


func _refresh() -> void:
	if day_night == null:
		return
	var text := time_text()
	pill.text = text
	time_label.text = text
	var icon := "pause" if day_night.paused else ("moon" if day_night.is_night(day_night.minutes / 60.0) else "sun")
	pill.icon = UiIcons.texture(icon, roundi(26.0 * _scale))
	status_label.text = UiText.t("hud.clock_paused" if day_night.paused else "hud.clock_running")
	resume_button.disabled = not day_night.paused


## Hides (or shows again) the clock and closes its panel.
func set_hidden(on: bool) -> void:
	kept_hidden = on
	_update_covered()

func _update_covered() -> void:
	var covered: bool = kept_hidden or hud.is_map_open() or hud.is_journal_open() or hud.is_help_open()
	pill.visible = not covered
	if covered:
		close()
