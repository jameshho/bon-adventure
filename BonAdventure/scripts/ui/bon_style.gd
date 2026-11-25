extends RefCounted
## The UI art style in code (docs/guides/UI_STYLE.md, user 18 Nov 2026: one cosy cream-and-meadow
## look for every screen, card, dialogue box and button, built to the user's mockups in
## docs/guides/design-references/ui/). Palette, the Fredoka font, and builders for the parts:
## buttons (primary green, back blue, minor cream, danger coral), the card with a meadow along its
## bottom, the cloud title banner with a sprout, picture tiles, choice pills,
## section bands, the striped progress bar and the cloud panel. Decorations are SVG text
## rasterised once per size (like ui_icons.gd): no image files, crisp at any window size.
## Every size is in design pixels (1100 x 800) times the window factor `f`
## (min(h / 800, w / 1100), as money_panel.gd).
const BonBox := preload("res://scripts/ui/bon_box.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const FREDOKA := preload("res://fonts/Fredoka.ttf")
const CJK := preload("res://fonts/NotoSansTC-SemiBold-subset.ttf")

const INK := Color("16536a")
const INK_SOFT := Color("3a8f9e")
const BROWN := Color("7a4a22")
const CREAM := Color("fdf4e3")
const CREAM_DEEP := Color("f6e7cc")
const RIM := Color("fffdf7")
const MINT_TOP := Color("dff3f4")
const MINT_BOTTOM := Color("eaf6e4")
## In-game cards and buttons (user, 18 Nov 2026: the same soft blue as the page card, not cream).
const SKY := Color("dff3f4")
const SKY_TOP := Color("f0fafb")
const SKY_BOTTOM := Color("d5eef0")
const SKY_EDGE := Color("b9dfe3")
const BAND := Color("d3ecea")
const GREEN_TOP := Color("86d65e")
const GREEN_BOTTOM := Color("45a83c")
const BLUE_TOP := Color("66bdf0")
const BLUE_BOTTOM := Color("2f87cf")
const CORAL_TOP := Color("ff9b8a")
const CORAL_BOTTOM := Color("e0614f")
const SUN := Color("f7cf3f")
const LEAF := Color("8fd067")
const LEAF_DARK := Color("5aa83a")
const TERM := Color("d9661c")
## The sub line of a selected tile ("Chinese · 111 words").
const GREEN_TEXT := Color("3f8f3a")
## The cloud banner and loading panel.
const CLOUD := Color("fff4de")
const CLOUD_EDGE := Color("f0dcb6")

static var _fonts := {}
static var _textures := {}
static var _theme: Theme

# --- Window scale ----------------------------------------------------------------------------

## The window factor `f` for a window (or viewport) of `view` pixels: min(h / 800, w / 1100),
## clamped to [low, high] (UI_STYLE.md#window-scale). The one copy of the formula; each caller
## keeps its own floor: 0.5 for the HUD and in-game panels, 0.6 for the start screens, the
## loading screen and the tutorial's cues.
static func factor(view: Vector2, low := 0.5, high := 3.0) -> float:
	return clampf(minf(view.y / 800.0, view.x / 1100.0), low, high)

# --- Type ------------------------------------------------------------------------------------

## Fredoka at `weight` (300-700): 700 titles and buttons, 600 body. Chinese falls back to Noto
## Sans TC (cjk_font.gd).
static func font(weight := 700) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var file: FontFile = FREDOKA
	if not file.fallbacks.has(CJK):
		var list := file.fallbacks
		list.append(CJK)
		file.fallbacks = list
	var variation := FontVariation.new()
	variation.base_font = file
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	variation.fallbacks = [CJK]
	_fonts[weight] = variation
	return variation

## The in-game Theme: set it on a panel's root Control and everything inside without its own
## overrides gets the art style: Fredoka 600, `INK` text, soft blue buttons (white rim, `INK` text
## and icons), light scroll bars and separators.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = font(600)
	_theme.set_color("font_color", "Label", INK)
	_theme.set_color("default_color", "RichTextLabel", INK)
	var looks := {"normal": SKY, "hover": SKY_TOP, "pressed": SKY.darkened(0.08), "hover_pressed": SKY.darkened(0.05), "disabled": SKY.lerp(Color(0.86, 0.88, 0.88), 0.6)}
	for type in ["Button", "MenuButton", "OptionButton"]:
		for state in looks:
			var look := flat(looks[state], 16, 3)
			look.content_margin_left = 14
			look.content_margin_right = 14
			look.content_margin_top = 6
			look.content_margin_bottom = 6
			_theme.set_stylebox(state, type, look)
		_theme.set_stylebox("focus", type, StyleBoxEmpty.new())
		for name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
			_theme.set_color(name, type, INK)
		_theme.set_color("font_disabled_color", type, Color(INK, 0.4))
		_theme.set_color("icon_disabled_color", type, Color(INK, 0.4))
	for type in ["VScrollBar", "HScrollBar"]:
		for part in [["scroll", Color("cfe8eb")], ["grabber", Color("9fcfd5")], ["grabber_highlight", Color("8cc6cd")], ["grabber_pressed", GREEN_BOTTOM]]:
			var bar := StyleBoxFlat.new()
			bar.bg_color = part[1]
			bar.set_corner_radius_all(8)
			_theme.set_stylebox(part[0], type, bar)
	var rule := StyleBoxLine.new()
	rule.color = Color(INK_SOFT, 0.3)
	rule.thickness = 2
	_theme.set_stylebox("separator", "HSeparator", rule)
	return _theme

## A soft-blue StyleBoxFlat with a white rim and a soft shadow, for in-game panels whose layout
## code resizes StyleBoxFlat fields (radius, margins); BonBox kinds "soft" / "card" otherwise.
## `fill`: SKY (cards and buttons), GREEN_BOTTOM (on / go), CORAL_BOTTOM (leave).
static func flat(fill: Color = SKY, radius := 18, rim := 4, shadow := true) -> StyleBoxFlat:
	var look := StyleBoxFlat.new()
	look.bg_color = fill
	look.border_color = RIM
	look.set_border_width_all(rim)
	look.set_corner_radius_all(radius)
	look.anti_aliasing = true
	if shadow:
		look.shadow_color = Color(0.1, 0.27, 0.32, 0.22)
		look.shadow_size = 8
		look.shadow_offset = Vector2(0, 3)
	return look

## Sets a Button's four states as flat() boxes: `fill` normal, lighter on hover, darker pressed,
## greyed when disabled; text and icons `ink` (white on green / coral fills).
static func flat_button(button: Button, fill: Color = SKY, radius := 18, ink: Color = INK) -> void:
	var looks := {"normal": fill, "hover": fill.lightened(0.25) if fill == SKY else fill.lightened(0.1),
			"pressed": fill.darkened(0.1), "hover_pressed": fill.darkened(0.06), "disabled": fill.lerp(Color(0.86, 0.88, 0.88), 0.6)}
	for state in looks:
		button.add_theme_stylebox_override(state, flat(looks[state], radius))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		button.add_theme_color_override(name, ink)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.45))
	button.add_theme_color_override("icon_disabled_color", Color(ink, 0.45))
	button.add_theme_font_override("font", font(700))

## Sets the font of a Label, Button or RichTextLabel.
static func use_font(node: Control, weight := 700) -> void:
	if node is RichTextLabel:
		node.add_theme_font_override("normal_font", font(weight))
		node.add_theme_font_override("bold_font", font(700))
	else:
		node.add_theme_font_override("font", font(weight))

static func label(text: String, size: float, color: Color, f: float, weight := 700, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	use_font(node, weight)
	node.add_theme_font_size_override("font_size", roundi(size * f))
	node.add_theme_color_override("font_color", color)
	return node

# --- Boxes and buttons -----------------------------------------------------------------------

## A BonBox for `kind`, sized for the window factor `f`.
static func box(kind: String, f: float) -> StyleBox:
	var b := BonBox.new()
	b.rim_width = 4.0 * f
	b.radius = -1.0
	match kind:
		"primary":
			_colors(b, GREEN_TOP, GREEN_BOTTOM)
			b.shadow = Color(0.16, 0.36, 0.1, 0.28)
		"back":
			_colors(b, BLUE_TOP, BLUE_BOTTOM)
			b.shadow = Color(0.1, 0.25, 0.4, 0.28)
		"danger":
			_colors(b, CORAL_TOP, CORAL_BOTTOM)
			b.shadow = Color(0.4, 0.15, 0.1, 0.28)
		"minor":
			_colors(b, Color("fffaf0"), Color("f7e6cb"))
			b.rim = Color("fffefa")
			b.shadow = Color(0.45, 0.3, 0.12, 0.2)
		"soft":
			_colors(b, SKY_TOP, SKY_BOTTOM)
			b.rim = RIM
			b.shadow = Color(0.12, 0.35, 0.42, 0.22)
		"soft_quiet":
			_colors(b, SKY_TOP, SKY_BOTTOM)
			b.rim = RIM
			b.rim_width = 3.0 * f
			b.shadow = Color(0.12, 0.35, 0.42, 0.2)
		"quiet":
			_colors(b, Color("fffaf0"), Color("f4e4c8"))
			b.rim_width = 3.0 * f
			b.shadow = Color(0.45, 0.3, 0.12, 0.18)
		"tile":
			_colors(b, Color("fdf3e2"), Color("f8e8cf"))
			b.rim_width = 5.0 * f
			b.radius = 26.0 * f
			b.shadow = Color(0.45, 0.32, 0.15, 0.16)
		"tile_on":
			_colors(b, Color("bfe99a"), Color("8ed366"))
			b.rim = Color("ecfbdc")
			b.rim_width = 5.0 * f
			b.radius = 26.0 * f
			b.shadow = Color(0.2, 0.45, 0.1, 0.3)
		"pill":
			_colors(b, Color("fffaf1"), Color("fbf0dc"))
			b.rim = Color("f1e0c2")
			b.rim_width = 2.0 * f
		"pill_on":
			_colors(b, Color("f4fbe9"), Color("e6f6d3"))
			b.rim = Color("cfe9b5")
			b.rim_width = 2.0 * f
		"choice":
			_colors(b, Color("fff9ee"), Color("f9ebd2"))
			b.shadow = Color(0.45, 0.32, 0.15, 0.16)
		"choice_on":
			_colors(b, GREEN_TOP, GREEN_BOTTOM)
			b.rim = Color("d9f5c2")
			b.shadow = Color(0.2, 0.45, 0.1, 0.3)
		"card":
			_colors(b, MINT_TOP, MINT_BOTTOM)
			b.rim_width = 7.0 * f
			b.radius = 46.0 * f
			b.shadow = Color(0.62, 0.84, 0.93, 0.9)
		"band":
			_colors(b, BAND, BAND.lightened(0.15))
			b.rim_width = 0.0
			b.radius = 24.0 * f
		"explore":
			_colors(b, Color("e8f6fd"), Color("d5ecf9"))
			b.rim = Color("a9d8f2")
			b.rim_width = 3.0 * f
			b.radius = 28.0 * f
		"explore_on":
			_colors(b, Color("e8f6fd"), Color("d5ecf9"))
			b.rim = BLUE_BOTTOM
			b.rim_width = 4.0 * f
			b.radius = 28.0 * f
		"dialogue":
			_colors(b, Color("fff8ec"), Color("fbedd5"))
			b.rim_width = 5.0 * f
			b.radius = 30.0 * f
			b.shadow = Color(0.3, 0.2, 0.08, 0.28)
		"tag":
			_colors(b, BLUE_TOP, BLUE_BOTTOM)
			b.rim_width = 0.0
		"track":
			_colors(b, Color("f7e3d0"), Color("fbeadb"))
			b.rim_width = 0.0
			b.outline = INK
			b.outline_width = 3.0 * f
		"fill":
			_colors(b, Color("8bd960"), Color("4fae3e"))
			b.rim_width = 0.0
		_:
			_colors(b, CREAM, CREAM)
	if kind in ["primary", "back", "danger"]:
		# Candy buttons (user's reference, 18 Nov 2026): a cream rim with a faint warm edge and a
		# soft warm shadow underneath, so the button sits raised above the page.
		b.rim = Color("fff5e2")
		b.rim_width = 5.0 * f
		b.outline = Color("e9d8b8")
		b.outline_width = 1.5 * f
		b.shadow = Color(0.42, 0.3, 0.14, 0.26)
	if b.shadow.a > 0.0:
		var candy := kind in ["primary", "back", "danger"]
		b.shadow_size = (20.0 if kind == "card" else (10.0 if candy else 6.0)) * f
		b.shadow_offset = Vector2(0, 0 if kind == "card" else (5.0 if candy else 4.0) * f)
	return b

static func _colors(b: BonBox, top: Color, bottom: Color) -> void:
	b.top = top
	b.bottom = bottom

## Text colour on a box of `kind`.
static func text_color(kind: String) -> Color:
	if kind in ["primary", "back", "danger", "choice_on", "tag"]:
		return Color.WHITE
	if kind in ["minor", "tile", "pill"]:
		return BROWN
	return INK

## Styles `button` as `kind` for every state (hover lighter, pressed darker), with the font, its
## colour, a soft shadow under white text and the icon tinted to match. `size`: font size.
static func style_button(button: Button, kind: String, f: float, size := 34.0) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		var look: BonBox = box(kind, f)
		match state:
			"hover":
				look.top = look.top.lightened(0.08)
				look.bottom = look.bottom.lightened(0.08)
			"pressed", "hover_pressed":
				look.top = look.top.darkened(0.08)
				look.bottom = look.bottom.darkened(0.1)
				look.shadow_offset *= 0.4
			"disabled":
				look.top = look.top.lerp(Color(0.85, 0.85, 0.85), 0.6)
				look.bottom = look.bottom.lerp(Color(0.75, 0.75, 0.75), 0.6)
		var pad := 26.0 * f if button.text != "" else 10.0 * f
		look.content_margin_left = pad
		look.content_margin_right = pad
		look.content_margin_top = 8.0 * f
		look.content_margin_bottom = 10.0 * f
		button.add_theme_stylebox_override(state, look)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	use_font(button, 700)
	button.add_theme_font_size_override("font_size", roundi(size * f))
	var color := text_color(kind)
	for name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		button.add_theme_color_override(name, color)
	button.add_theme_color_override("font_disabled_color", Color(color, 0.5))
	if color == Color.WHITE:
		button.add_theme_color_override("font_shadow_color", Color(0, 0.15, 0.05, 0.3))
		button.add_theme_constant_override("shadow_offset_y", roundi(2.0 * f))
		button.add_theme_constant_override("shadow_offset_x", 0)
	else:
		button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	button.add_theme_constant_override("h_separation", roundi(14.0 * f))

## A finished button: `kind` primary / back / minor / danger / quiet; `icon` a BonStyle icon
## (play, arrow_left, arrow_right, trash, plus, check, close) or a ui_icons.gd name.
static func button(text: String, kind: String, icon: String, f: float, size := 34.0, min_size := Vector2(220, 80)) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = min_size * f
	style_button(node, kind, f, size)
	if icon != "":
		node.icon = icon_texture(icon, 96)
		node.add_theme_constant_override("icon_max_width", roundi(size * 1.2 * f))
	squash_on_press(node)
	return node

## A press squashes the button a little (UI_STYLE.md: gentle motion).
static func squash_on_press(node: Control) -> void:
	node.resized.connect(func() -> void: node.pivot_offset = node.size * 0.5)
	var bounce := func(to: float) -> void:
		var tween := node.create_tween()
		tween.tween_property(node, "scale", Vector2.ONE * to, 0.08).set_trans(Tween.TRANS_SINE)
	if node is BaseButton:
		(node as BaseButton).button_down.connect(bounce.bind(0.96))
		(node as BaseButton).button_up.connect(bounce.bind(1.0))

## The shade behind an in-game window (Settings, the journal): a light teal veil, never dark
## (UI_STYLE.md: keep the scene bright).
const SHADE := Color(0.1, 0.27, 0.32, 0.38)

## A toggle button (one of a pair or group such as Low / High): a cream pill, green with
## white words when pressed.
static func style_toggle(button: Button, f: float, size := 28.0) -> void:
	style_button(button, "soft", f, size)
	var on := Button.new()
	style_button(on, "choice_on", f, size)
	for state in ["pressed", "hover_pressed"]:
		var look: StyleBox = on.get_theme_stylebox("normal" if state == "pressed" else "hover").duplicate()
		look.content_margin_left = button.get_theme_stylebox("normal").content_margin_left
		look.content_margin_right = button.get_theme_stylebox("normal").content_margin_right
		button.add_theme_stylebox_override(state, look)
	on.free()
	for name in ["font_pressed_color", "font_hover_pressed_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		button.add_theme_color_override(name, Color.WHITE)

## A checkbox: `INK` words beside a cream rounded box that turns green with a white tick.
static func style_check(box_button: CheckBox, f: float, size := 26.0) -> void:
	use_font(box_button, 600)
	box_button.add_theme_font_size_override("font_size", roundi(size * f))
	for name in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		box_button.add_theme_color_override(name, INK)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		box_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var px := roundi(size * 1.5 * f)
	box_button.add_theme_icon_override("checked", _sized("check_on", px))
	box_button.add_theme_icon_override("unchecked", _sized("check_off", px))
	box_button.add_theme_constant_override("h_separation", roundi(14 * f))
	box_button.custom_minimum_size = Vector2(0, maxf(56.0, size * 2.2) * f)

## A drop-down: a cream pill with `BROWN` words and a brown chevron; its list is a cream card.
static func style_option(pick: OptionButton, f: float, size := 26.0) -> void:
	style_button(pick, "soft", f, size)
	pick.add_theme_icon_override("arrow", _sized("chevron_ink", roundi(size * f)))
	pick.add_theme_constant_override("arrow_margin", roundi(22 * f))
	var popup := pick.get_popup()
	var look: BonBox = box("soft", f)
	look.radius = 18.0 * f
	look.rim_width = 3.0 * f
	look.set_content_margin_all(10.0 * f)
	popup.add_theme_stylebox_override("panel", look)
	var hover: BonBox = box("choice_on", f)
	hover.radius = 14.0 * f
	hover.rim_width = 0.0
	hover.shadow = Color(0, 0, 0, 0)
	popup.add_theme_stylebox_override("hover", hover)
	popup.add_theme_font_override("font", font(600))
	popup.add_theme_font_size_override("font_size", roundi(size * f))
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", Color.WHITE)
	popup.add_theme_constant_override("v_separation", roundi(16 * f))
	popup.add_theme_constant_override("item_start_padding", roundi(14 * f))
	popup.add_theme_constant_override("item_end_padding", roundi(14 * f))
	popup.add_theme_icon_override("radio_checked", _sized("tick_ink", roundi(size * f)))
	popup.add_theme_icon_override("radio_unchecked", ImageTexture.new())

## A volume slider (Settings, 24 Nov 2026): a thick cream track that fills green up to a big
## white knob with a green rim, finger-sized (touch UI) and dragged by the knob or the track.
static func style_slider(slider: HSlider, f: float) -> void:
	var thick := roundf(14.0 * f)
	var track := StyleBoxFlat.new()
	track.bg_color = CREAM_DEEP
	track.border_color = RIM
	track.set_border_width_all(maxi(2, roundi(3 * f)))
	track.set_corner_radius_all(roundi(thick))
	track.content_margin_top = thick * 0.5
	track.content_margin_bottom = thick * 0.5
	track.anti_aliasing = true
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = GREEN_BOTTOM
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _sized("knob", roundi(44 * f))
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)
	slider.add_theme_icon_override("grabber_disabled", knob)
	slider.custom_minimum_size = Vector2(0, maxf(52.0, 56.0 * f))

## An icon drawn at exactly `px` pixels (theme icons are not scaled by the control).
static func _sized(name: String, px: int) -> Texture2D:
	return icon_texture(name, maxi(8, px))

# --- Cards, banners, tiles --------------------------------------------------------------------

## The page card: mint gradient, white rim, soft blue glow; `meadow` draws bushes and daisies
## along its bottom (under the content).
static func card(content: Control, f: float, meadow := true) -> PanelContainer:
	var panel := PanelContainer.new()
	var look: BonBox = box("card", f)
	look.content_margin_left = 44.0 * f
	look.content_margin_right = 44.0 * f
	look.content_margin_top = 26.0 * f
	look.content_margin_bottom = 34.0 * f
	panel.add_theme_stylebox_override("panel", look)
	panel.add_child(content)
	panel.set_meta("bon_f", f)
	if meadow:
		panel.draw.connect(func() -> void: _meadow(panel, float(panel.get_meta("bon_f", 1.0))))
	return panel

## A card made by card() redrawn at a new window factor `f` (panels that rescale with the window),
## with `margin` around its content (`bottom` below it, room for the meadow).
static func rescale_card(panel: PanelContainer, f: float, margin := 30.0, bottom := 46.0) -> void:
	var look: BonBox = box("card", f)
	look.set_content_margin_all(margin * f)
	look.content_margin_bottom = bottom * f
	panel.add_theme_stylebox_override("panel", look)
	panel.set_meta("bon_f", f)
	panel.queue_redraw()

## Bushes along the inside bottom of a card, in two layers, with a few daisies.
static func _meadow(panel: Control, f: float) -> void:
	var inner := Rect2(Vector2.ZERO, panel.size).grow(-7.0 * f)
	var r := 39.0 * f
	for layer in 2:
		var bumps: Array = []
		var x := inner.position.x - 10.0 * f
		var i := 0
		while x < inner.end.x + 40.0 * f:
			var size := (34.0 + 12.0 * sin(i * 2.3 + layer * 1.7)) * f * (1.0 if layer == 0 else 0.78)
			bumps.append([x, inner.end.y + size * (0.25 if layer == 0 else 0.45), size])
			x += size * (1.35 if layer == 0 else 1.6)
			i += 1
		var color := Color("a8dc7f") if layer == 0 else Color("c1e79b")
		_bush(panel, inner, r, bumps, color, 3.0 * f)
	for spot in [[0.08, 1.0], [0.27, 0.7], [0.5, 0.9], [0.72, 0.7], [0.92, 1.0]]:
		var px: float = 46.0 * f * float(spot[1])
		var center := Vector2(lerpf(inner.position.x + r, inner.end.x - r, float(spot[0])), inner.end.y - 26.0 * f * float(spot[1]))
		panel.draw_texture_rect(icon_texture("daisy", 96), Rect2(center - Vector2(px, px) * 0.5, Vector2(px, px)), false)

## One bush layer: the top outline of the circles `bumps` ([x, y, radius]), cut by the card's
## rounded bottom corners.
static func _bush(panel: Control, inner: Rect2, r: float, bumps: Array, color: Color, step: float) -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var x := inner.position.x
	while x <= inner.end.x + 0.01:
		var floor_y := inner.end.y
		var left := inner.position.x + r - x
		var right := x - (inner.end.x - r)
		if left > 0.0:
			floor_y -= r - sqrt(maxf(0.0, r * r - left * left))
		elif right > 0.0:
			floor_y -= r - sqrt(maxf(0.0, r * r - right * right))
		var y := floor_y
		for bump in bumps:
			var dx: float = x - float(bump[0])
			var br: float = bump[2]
			if absf(dx) < br:
				y = minf(y, float(bump[1]) - sqrt(br * br - dx * dx))
		top.append(Vector2(x, minf(y, floor_y)))
		bottom.append(Vector2(x, floor_y))
		x += step
	# One strip of quads between the outline and the floor (a single polygon fails to
	# triangulate where the two touch).
	var points := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in top.size():
		points.append(top[i])
		points.append(bottom[i])
		if i > 0:
			var k := i * 2
			indices.append_array([k - 2, k, k - 1, k, k + 1, k - 1])
	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(color)
	RenderingServer.canvas_item_add_triangle_array(panel.get_canvas_item(), indices, points, colors)
	panel.draw_polyline(top, color, 1.5, true)

## The page title on a cream cloud with a sprout on top (no yellow accents: user, 18 Nov 2026).
static func title(text: String, f: float, size := 52.0) -> Control:
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_theme_constant_override("margin_left", roundi(118 * f))
	holder.add_theme_constant_override("margin_right", roundi(118 * f))
	holder.add_theme_constant_override("margin_top", roundi(74 * f))
	holder.add_theme_constant_override("margin_bottom", roundi(20 * f))
	var words := label(text, size, INK, f)
	holder.add_child(words)
	holder.draw.connect(func() -> void:
		var area := Rect2(Vector2.ZERO, holder.size)
		var cloud := Rect2(area.position + Vector2(64, 34) * f, area.size - Vector2(128, 36) * f)
		draw_cloud(holder, cloud, f)
		var leaf := 74.0 * f
		holder.draw_texture_rect(icon_texture("sprout", 128), Rect2(Vector2(area.size.x * 0.5 - leaf * 0.5, 2.0 * f), Vector2(leaf, leaf)), false)
		)
	return holder

## A soft cream cloud filling `rect` (redrawn 18 Nov 2026, user: cuter and more natural): a
## pill-shaped base with a flat-ish bottom, a few round puffs of different sizes along the top
## and round puffs at both ends, a thin warm edge and a soft shadow.
static func draw_cloud(node: CanvasItem, rect: Rect2, f: float, fill := CLOUD, edge := CLOUD_EDGE) -> void:
	var h := rect.size.y
	var body := Rect2(Vector2(rect.position.x + h * 0.08, rect.end.y - h * 0.52), Vector2(rect.size.x - h * 0.16, h * 0.52))
	var puffs: Array = []
	# Two low puffs round off the ends; big puffs of different sizes make the top.
	puffs.append([Vector2(body.position.x + body.size.y * 0.42, body.position.y + body.size.y * 0.42), body.size.y * 0.56])
	puffs.append([Vector2(body.end.x - body.size.y * 0.42, body.position.y + body.size.y * 0.45), body.size.y * 0.53])
	var count := clampi(roundi(body.size.x / (h * 1.05)), 3, 5)
	var sizes := [0.40, 0.50, 0.44, 0.48, 0.41]
	for i in count:
		var t := (float(i) + 0.5) / float(count)
		var r := h * float(sizes[i % sizes.size()]) * (0.9 + 0.12 * sin(PI * t))
		var x := lerpf(body.position.x + h * 0.5, body.end.x - h * 0.5, t)
		puffs.append([Vector2(x, body.position.y + r * 0.42), r])
	var pill := body.size.y * 0.5
	for pass_index in 3:
		var color: Color = [Color(0.55, 0.38, 0.18, 0.12), edge, fill][pass_index]
		var grow: float = [0.0, 2.0 * f, 0.0][pass_index]
		var offset := Vector2(0, 5.0 * f) if pass_index == 0 else Vector2.ZERO
		var flat := StyleBoxFlat.new()
		flat.bg_color = color
		flat.set_corner_radius_all(roundi(pill + grow))
		flat.anti_aliasing = true
		node.draw_style_box(flat, Rect2(body.position + offset, body.size).grow(grow))
		for puff in puffs:
			node.draw_circle(puff[0] + offset, float(puff[1]) + grow, color, true, -1.0, true)

## A big picture button: `picture` (a portrait or an icon) over a name pill, an optional `sub`
## line under it; `picked`: green with a check badge top right.
static func tile(picture: Texture2D, caption: String, picked: bool, f: float, sub := "", size := Vector2(200, 232), name_size := 28.0) -> Button:
	var node := Button.new()
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = size * f
	style_button(node, "tile_on" if picked else "tile", f)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_left = 14.0 * f
	stack.offset_right = -14.0 * f
	stack.offset_top = 14.0 * f
	stack.offset_bottom = -12.0 * f
	stack.add_theme_constant_override("separation", roundi(4 * f))
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(stack)
	var art := TextureRect.new()
	art.texture = picture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Large pictures (the picker portraits, 544 px, mipmapped) stay smooth when drawn small.
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stack.add_child(art)
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look: BonBox = box("pill", f)
	look.content_margin_top = 4.0 * f
	look.content_margin_bottom = 6.0 * f
	look.content_margin_left = 10.0 * f
	look.content_margin_right = 10.0 * f
	pill.add_theme_stylebox_override("panel", look)
	var words := label(caption, name_size, BROWN, f)
	words.clip_text = true
	pill.add_child(words)
	stack.add_child(pill)
	if sub != "":
		stack.add_child(label(sub, 20, GREEN_TEXT if picked else INK_SOFT, f, 600))
	if picked:
		var badge := _corner_picture("check_badge", 62.0 * f)
		badge.anchor_left = 1.0
		badge.anchor_right = 1.0
		badge.offset_left = -44.0 * f
		badge.offset_right = 18.0 * f
		badge.offset_top = -18.0 * f
		badge.offset_bottom = 44.0 * f
		node.add_child(badge)
	squash_on_press(node)
	return node

static func _corner_picture(name: String, px: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = icon_texture(name, 128)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2(px, px)
	return picture

## A pill choice: a round flag (or picture), the words, and a check when picked (green).
static func choice(picture: Texture2D, text: String, picked: bool, f: float, size := Vector2(232, 78)) -> Button:
	var node := Button.new()
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = size * f
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(node, "choice_on" if picked else "choice", f)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14.0 * f
	row.offset_right = -14.0 * f
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", roundi(12 * f))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(row)
	if picture != null:
		var flag := TextureRect.new()
		flag.texture = picture
		flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flag.custom_minimum_size = Vector2(50, 50) * f
		flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(flag)
	row.add_child(label(text, 30, Color.WHITE if picked else BROWN, f))
	if picked:
		var tick := _corner_picture("tick", 30.0 * f)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tick)
	squash_on_press(node)
	return node

## A section band: a heading and a hint on one line, then `body`.
static func band(heading: String, hint: String, body: Control, f: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look: BonBox = box("band", f)
	look.content_margin_left = 20.0 * f
	look.content_margin_right = 20.0 * f
	look.content_margin_top = 10.0 * f
	look.content_margin_bottom = 16.0 * f
	panel.add_theme_stylebox_override("panel", look)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", roundi(10 * f))
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stack)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", roundi(16 * f))
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(label(heading, 32, INK, f, 700, HORIZONTAL_ALIGNMENT_LEFT))
	if hint != "":
		var small := label(hint, 20, INK_SOFT, f, 600, HORIZONTAL_ALIGNMENT_LEFT)
		small.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(small)
	stack.add_child(line)
	stack.add_child(body)
	return panel

# --- Progress bar ----------------------------------------------------------------------------

## The loading bar: a cream track with a dark outline and a green fill with drifting lighter
## stripes. Set `value` (0..1) and `f`.
class StripedBar extends Control:
	var value := 0.0:
		set(v):
			value = clampf(v, 0.0, 1.0)
			queue_redraw()
	var f := 1.0
	var _drift := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_drift = fmod(_drift + delta * 22.0, 1000.0)
		if value > 0.0:
			queue_redraw()

	func _draw() -> void:
		var BonStyleScript: GDScript = load("res://scripts/ui/bon_style.gd")
		var rect := Rect2(Vector2.ZERO, size)
		draw_style_box(BonStyleScript.box("track", f), rect)
		if value <= 0.0:
			return
		var inner := rect.grow(-5.0 * f)
		inner.size.x = maxf(inner.size.y, inner.size.x * value)
		draw_style_box(BonStyleScript.box("fill", f), inner)
		var outline := BonBox.rounded(inner, inner.size.y * 0.5)
		var gap := inner.size.y * 1.4
		var x := inner.position.x - inner.size.y * 2.0 + fmod(_drift * f, gap)
		while x < inner.end.x:
			var stripe := PackedVector2Array([
				Vector2(x, inner.end.y), Vector2(x + inner.size.y * 0.55, inner.end.y),
				Vector2(x + inner.size.y * 1.25, inner.position.y), Vector2(x + inner.size.y * 0.7, inner.position.y)])
			for piece in Geometry2D.intersect_polygons(stripe, outline):
				draw_colored_polygon(piece, Color(1, 1, 1, 0.22))
			x += gap

# --- Pictures --------------------------------------------------------------------------------

## The decorations and icons as SVG (viewBox 0 0 64 64). White ones are tinted by a button's
## icon colour; the others keep their colours.
const SVG := {
	"play": '<g transform="translate(5 7) scale(0.82)"><path d="M14 9.5c0-4 4.3-6.4 7.7-4.4l33 20.3c3.2 2 3.2 6.7 0 8.7l-33 20.3c-3.4 2-7.7-.4-7.7-4.4z" fill="none" stroke="#3a9435" stroke-width="9" stroke-linejoin="round"/><path d="M14 9.5c0-4 4.3-6.4 7.7-4.4l33 20.3c3.2 2 3.2 6.7 0 8.7l-33 20.3c-3.4 2-7.7-.4-7.7-4.4z" fill="#fff"/></g>',
	"arrow_left": '<path d="M52 32H14M28 17L13 32l15 15" fill="none" stroke="#fff" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>',
	"arrow_right": '<path d="M12 32h38M36 17l15 15-15 15" fill="none" stroke="#fff" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>',
	"trash": '<path d="M13 19h38" stroke="#fff" stroke-width="5.5" stroke-linecap="round"/><path d="M25 18v-5h14v5" fill="none" stroke="#fff" stroke-width="5" stroke-linejoin="round"/><path d="M17 23h30l-2.5 28c-.2 2.3-2 4-4.4 4H23.9c-2.3 0-4.2-1.7-4.4-4z" fill="#fff"/><path d="M27 30v17M37 30v17" stroke="#d9c3a6" stroke-width="3.5" stroke-linecap="round"/>',
	"plus": '<path d="M32 18v28M18 32h28" stroke="#8a552a" stroke-width="7.5" stroke-linecap="round"/>',
	"tick": '<path d="M14 33l11 11 25-26" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
	"close": '<path d="M18 18l28 28M46 18L18 46" stroke="#fff" stroke-width="7" stroke-linecap="round"/>',
	"check_badge": '<circle cx="32" cy="32" r="28" fill="#fff"/><circle cx="32" cy="32" r="23.5" fill="#3aa34a"/><path d="M20.5 32.5l8 8 15-16" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>',
	"sprout": '<path d="M32 62V34" stroke="#5aa83a" stroke-width="5" stroke-linecap="round"/><path d="M32 36C30 22 18 14 4 16c2 14 14 22 28 20z" fill="#8fd067" stroke="#5aa83a" stroke-width="2.5" stroke-linejoin="round"/><path d="M32 34C34 18 46 8 62 10c-1 16-14 26-30 24z" fill="#9ad970" stroke="#5aa83a" stroke-width="2.5" stroke-linejoin="round"/><path d="M12 19c7 2 13 7 18 14M54 13c-7 4-14 11-20 19" fill="none" stroke="#c5ef9f" stroke-width="2.4" stroke-linecap="round"/>',
	"daisy": '<g fill="#fff" stroke="#e8decb" stroke-width="1.2"><ellipse cx="32" cy="14" rx="7.5" ry="11"/><ellipse cx="32" cy="50" rx="7.5" ry="11"/><ellipse cx="14" cy="32" rx="11" ry="7.5"/><ellipse cx="50" cy="32" rx="11" ry="7.5"/><ellipse cx="19.5" cy="19.5" rx="7.5" ry="11" transform="rotate(-45 19.5 19.5)"/><ellipse cx="44.5" cy="44.5" rx="7.5" ry="11" transform="rotate(-45 44.5 44.5)"/><ellipse cx="44.5" cy="19.5" rx="7.5" ry="11" transform="rotate(45 44.5 19.5)"/><ellipse cx="19.5" cy="44.5" rx="7.5" ry="11" transform="rotate(45 19.5 44.5)"/></g><circle cx="32" cy="32" r="9" fill="#f7c93a" stroke="#e7a92a" stroke-width="1.5"/>',
	"gamepad": '<path d="M18 22h28c7 0 11 5 12 12l2 9c1 5-4 9-8 6l-7-6H19l-7 6c-4 3-9-1-8-6l2-9c1-7 5-12 12-12z" fill="#fff" stroke="#2f87cf" stroke-width="3.5" stroke-linejoin="round"/><path d="M19 30v10M14 35h10" stroke="#2f87cf" stroke-width="3.5" stroke-linecap="round"/><circle cx="44" cy="32" r="3" fill="#f07a8a"/><circle cx="50" cy="38" r="3" fill="#5cc06a"/><circle cx="38" cy="38" r="3" fill="#f7cf3f"/>',
	"check_off": '<rect x="7" y="7" width="50" height="50" rx="14" fill="#f0fafb" stroke="#9fcfd5" stroke-width="5"/>',
	"check_on": '<rect x="7" y="7" width="50" height="50" rx="14" fill="#4fb03f" stroke="#3a9435" stroke-width="5"/><path d="M19 33l9 9 18-19" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
	"chevron": '<path d="M16 24l16 16 16-16" fill="none" stroke="#7a4a22" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>',
	# Money panel tags and total (user's mockup, 18 Nov 2026): teal outlines on light fills.
	"bills": '<g stroke="#16536a" stroke-width="4" stroke-linejoin="round"><rect x="14" y="10" width="40" height="22" rx="4" transform="rotate(-14 34 21)" fill="#bfe6dc"/><rect x="10" y="22" width="42" height="24" rx="4" transform="rotate(-6 31 34)" fill="#d6f0e6"/><rect x="8" y="32" width="44" height="24" rx="4" fill="#e9f8f1"/></g><circle cx="30" cy="44" r="6" fill="none" stroke="#16536a" stroke-width="3.5"/>',
	"coins": '<g stroke="#16536a" stroke-width="4"><ellipse cx="32" cy="48" rx="20" ry="8" fill="#cfe9ec"/><path d="M12 48v-8M52 48v-8" /><ellipse cx="32" cy="40" rx="20" ry="8" fill="#dff2f4"/><path d="M12 40v-8M52 40v-8"/><ellipse cx="32" cy="32" rx="20" ry="8" fill="#cfe9ec"/><path d="M14 32v-9M50 32v-9"/><ellipse cx="32" cy="22" rx="18" ry="7" fill="#eef9fa"/></g>',
	"basket": '<path d="M22 26l8-14M42 26l-8-14" stroke="#2f87cf" stroke-width="5" stroke-linecap="round"/><path d="M8 26h48l-5 26c-.5 2.4-2.5 4-5 4H18c-2.5 0-4.5-1.6-5-4z" fill="#8fd0f2" stroke="#2f87cf" stroke-width="4.5" stroke-linejoin="round"/><path d="M24 34v14M32 34v14M40 34v14" stroke="#2f87cf" stroke-width="4" stroke-linecap="round"/><rect x="5" y="22" width="54" height="9" rx="4.5" fill="#bfe6fa" stroke="#2f87cf" stroke-width="4.5"/>',
	# Minigame stars (progression, game_progress.gd, 18 Nov 2026): earned gold, missing pale.
	# HUD icons in the mockups' look (24 Nov 2026, user: match the game's aesthetic): a thick INK
	# outline with pastel fills, like the money panel's basket and bills. Not tinted: their
	# buttons keep white icon colours. journal: the vocabulary journal (HUD button and the
	# journal's title; no key letter on it, the key shows in a hint circle instead). speaker:
	# say the word (the word card).
	"journal": '<path d="M45 51v10l-4.5-3.3L36 61V51" fill="#f7cf3f" stroke="#16536a" stroke-width="3.5" stroke-linejoin="round"/><rect x="15" y="10" width="39" height="45" rx="8" fill="#fdf4e3" stroke="#16536a" stroke-width="4.5"/><path d="M50 18v30" stroke="#e2cf9f" stroke-width="3" stroke-linecap="round"/><rect x="9" y="5" width="37" height="45" rx="8" fill="#bfe6fa" stroke="#16536a" stroke-width="4.5"/><path d="M17 7v41" stroke="#16536a" stroke-width="4"/><path d="M31.0 16.5L33.7 23.3L41.0 23.8L35.4 28.4L37.2 35.5L31.0 31.6L24.8 35.5L26.6 28.4L21.0 23.8L28.3 23.3z" fill="#f7cf3f" stroke="#16536a" stroke-width="3" stroke-linejoin="round"/><path d="M24 42h14" stroke="#16536a" stroke-width="3.5" stroke-linecap="round"/>',
	"speaker": '<path d="M9 23h10l14-12v42L19 41H9c-1.7 0-3-1.3-3-3V26c0-1.7 1.3-3 3-3z" fill="#bfe6fa" stroke="#16536a" stroke-width="4.5" stroke-linejoin="round"/><path d="M41 24.5a10.5 10.5 0 0 1 0 15" fill="none" stroke="#16536a" stroke-width="4.5" stroke-linecap="round"/><path d="M48 17a20 20 0 0 1 0 30" fill="none" stroke="#16536a" stroke-width="4.5" stroke-linecap="round"/>',
	# The volume sliders' knob (style_slider, 24 Nov 2026).
	"knob": '<circle cx="32" cy="32" r="26" fill="#fff" stroke="#45a83c" stroke-width="7"/><circle cx="32" cy="32" r="8" fill="#86d65e"/>',
	"star_on": '<path d="M32 7L39.3 23.9L57.7 25.7L43.9 37.9L47.9 55.8L32 46.5L16.1 55.8L20.1 37.9L6.3 25.7L24.7 23.9z" fill="#f7cf3f" stroke="#d9661c" stroke-width="4" stroke-linejoin="round"/>',
	"star_off": '<path d="M32 7L39.3 23.9L57.7 25.7L43.9 37.9L47.9 55.8L32 46.5L16.1 55.8L20.1 37.9L6.3 25.7L24.7 23.9z" fill="#f0fafb" stroke="#9fcfd5" stroke-width="4" stroke-linejoin="round"/>',
	"chevron_ink": '<path d="M16 24l16 16 16-16" fill="none" stroke="#16536a" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>',
	"tick_ink": '<path d="M14 33l11 11 25-26" fill="none" stroke="#16536a" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
	"tick_brown": '<path d="M14 33l11 11 25-26" fill="none" stroke="#7a4a22" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
	"radio_off": '<circle cx="32" cy="32" r="22" fill="#fff" stroke="#3a9bdc" stroke-width="5"/>',
	"radio_on": '<circle cx="32" cy="32" r="22" fill="#2f87cf" stroke="#2f87cf" stroke-width="5"/><path d="M21 33l7.5 7.5L44 25" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>',
	"flag_us": '<defs><clipPath id="c"><circle cx="32" cy="32" r="28"/></clipPath></defs><g clip-path="url(#c)"><rect width="64" height="64" fill="#fff"/><g fill="#d93a3f"><rect y="4" width="64" height="5"/><rect y="14" width="64" height="5"/><rect y="24" width="64" height="5"/><rect y="34" width="64" height="5"/><rect y="44" width="64" height="5"/><rect y="54" width="64" height="5"/></g><rect width="32" height="30" fill="#2f4b9a"/><g fill="#fff"><circle cx="10" cy="10" r="1.8"/><circle cx="18" cy="10" r="1.8"/><circle cx="26" cy="10" r="1.8"/><circle cx="14" cy="16" r="1.8"/><circle cx="22" cy="16" r="1.8"/><circle cx="10" cy="22" r="1.8"/><circle cx="18" cy="22" r="1.8"/><circle cx="26" cy="22" r="1.8"/></g></g><circle cx="32" cy="32" r="28.5" fill="none" stroke="#fff" stroke-width="3.5"/>',
	"flag_es": '<defs><clipPath id="c"><circle cx="32" cy="32" r="28"/></clipPath></defs><g clip-path="url(#c)"><rect width="64" height="64" fill="#d6262f"/><rect y="18" width="64" height="28" fill="#f7c53a"/><rect x="15" y="25" width="9" height="13" rx="2" fill="#c0282d"/><rect x="16.5" y="27" width="6" height="4" fill="#e9a23a"/></g><circle cx="32" cy="32" r="28.5" fill="none" stroke="#fff" stroke-width="3.5"/>',
	"flag_cn": '<defs><clipPath id="c"><circle cx="32" cy="32" r="28"/></clipPath></defs><g clip-path="url(#c)"><rect width="64" height="64" fill="#de2910"/><path fill="#ffde00" d="M22.0 15.0 L24.2 21.9 L31.5 21.9 L25.6 26.2 L27.9 33.1 L22.0 28.8 L16.1 33.1 L18.4 26.2 L12.5 21.9 L19.8 21.9Z M32.4 16.2 L33.7 14.1 L32.1 12.2 L34.5 12.8 L35.8 10.7 L36.0 13.2 L38.4 13.7 L36.1 14.7 L36.3 17.1 L34.7 15.3Z M36.7 20.9 L38.8 19.5 L38.1 17.2 L40.1 18.7 L42.1 17.3 L41.3 19.7 L43.2 21.2 L40.7 21.1 L39.9 23.4 L39.2 21.0Z M36.6 27.4 L39.1 27.1 L39.5 24.6 L40.6 26.8 L43.0 26.5 L41.3 28.2 L42.4 30.4 L40.2 29.3 L38.4 31.0 L38.8 28.6Z M32.2 32.1 L34.6 32.8 L36.0 30.7 L36.0 33.2 L38.4 33.9 L36.1 34.7 L36.1 37.2 L34.6 35.2 L32.3 36.1 L33.7 34.0Z"/></g><circle cx="32" cy="32" r="28.5" fill="none" stroke="#fff" stroke-width="3.5"/>',
}

## A row of three stars, `earned` of them gold (minigame progression, game_progress.gd), each
## `px` pixels; the row ignores the pointer.
static func stars(earned: int, px: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", roundi(px * 0.08))
	for i in 3:
		var star := TextureRect.new()
		star.name = "Star %d" % (i + 1)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(px, px)
		star.texture = icon_texture("star_on" if i < earned else "star_off", 96)
		row.add_child(star)
	return row

## A picture by name: a BonStyle SVG, else a ui_icons.gd icon; `px` the raster size.
static func icon_texture(name: String, px := 96) -> Texture2D:
	var key := "%s@%d" % [name, px]
	if _textures.has(key):
		return _textures[key]
	if not SVG.has(name):
		return UiIcons.texture(name, px)
	var image := Image.new()
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 64 64" width="64" height="64">%s</svg>' % SVG[name]
	image.load_svg_from_string(svg, float(px) / 64.0)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture

## The round flag of a language (data/languages.json "flag"), or null.
static func flag(flag_id: String, px := 96) -> Texture2D:
	return icon_texture("flag_" + flag_id, px) if SVG.has("flag_" + flag_id) else null
