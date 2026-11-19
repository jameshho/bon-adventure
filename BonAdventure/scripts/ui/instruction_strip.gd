extends CanvasLayer
## The instruction strip (17 Nov 2026, user: the tutorial's "UI" lines, a reusable component):
## one slim line of what to do now, top centre, apart from the speech bubble of whoever talks.
## It stays until the task is done (show_text() again replaces it, clear() hides it) and can carry
## a progress note ("1/2"). Drawn only (mouse_filter IGNORE), so it never takes a click or a
## finger. Sized with the window like the panels (money_panel.gd: min(height / 800,
## width / 1100)), finger-friendly and readable on a laptop and a landscape phone.
##
## Use: add one to the tree (it is its own CanvasLayer), then show_text("Press E to get up.") /
## show_text("Find BonBon's two friends", "1/2") / clear(). `hidden_when` (optional
## () -> bool) hides it meanwhile without forgetting the text (an open journal or map).
## `top` (pixels at scale 1) places it below other top-centre UI (the tutorial's Skip button).
## Owners: scripts/learning/tutorial.gd (the welcome tutorial); any guided activity may reuse it.
const BonStyle := preload("res://scripts/ui/bon_style.gd")
# UI art style (18 Nov 2026): a soft blue strip with a white rim, dark teal text, a green pointer.
const GOLD := BonStyle.INK
const FILL := Color(0.875, 0.953, 0.957, 0.97)
const EDGE := BonStyle.GREEN_BOTTOM
const PROGRESS := Color("3f9a35")
## Seconds of the slide-in and the pulse when the text changes.
const IN_SECONDS := 0.25

var hidden_when: Callable
## Pixels from the top of the window at scale 1.
var top := 142.0
var text := ""
var progress := ""
var _panel: PanelContainer
var _row: HBoxContainer
var _icon: Control
var _label: Label
var _progress: Label
var _style: StyleBoxFlat
var _age := 10.0

func _init() -> void:
	name = "InstructionStrip"
	layer = 58
	_panel = PanelContainer.new()
	_panel.name = "Strip"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.bg_color = FILL
	_style.border_color = BonStyle.RIM
	_style.set_border_width_all(4)
	_style.set_corner_radius_all(22)
	_style.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
	_style.shadow_size = 8
	_style.anti_aliasing = true
	_panel.add_theme_stylebox_override("panel", _style)
	add_child(_panel)
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_row)
	# A small gold pointer before the text: "this is what to do".
	_icon = Control.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.draw.connect(func() -> void:
		var h: float = _icon.size.y
		var w: float = _icon.size.x
		_icon.draw_colored_polygon(PackedVector2Array([Vector2(w * 0.15, h * 0.28), Vector2(w * 0.9, h * 0.5), Vector2(w * 0.15, h * 0.72)]), EDGE))
	_row.add_child(_icon)
	_label = _make_label(GOLD)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.add_child(_label)
	_progress = _make_label(PROGRESS)
	_row.add_child(_progress)
	_panel.visible = false

func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", BonStyle.font(700))
	return label

## Shows `line` (and an optional progress note such as "1/2"); the strip slides in when the
## text is new.
func show_text(line: String, note := "") -> void:
	if line == "":
		clear()
		return
	if line != text:
		_age = 0.0
	text = line
	progress = note
	_label.text = line
	_progress.text = note
	_progress.visible = note != ""

func clear() -> void:
	text = ""
	progress = ""
	_panel.visible = false

func is_showing() -> bool:
	return _panel.visible

func _process(delta: float) -> void:
	var hidden: bool = hidden_when.is_valid() and bool(hidden_when.call())
	_panel.visible = text != "" and not hidden
	if not _panel.visible:
		return
	_age += delta
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var f := clampf(minf(screen.y / 800.0, screen.x / 1100.0), 0.6, 3.0)
	for label in [_label, _progress]:
		label.add_theme_font_size_override("font_size", roundi(26 * f))
	_icon.custom_minimum_size = Vector2(18, 30) * f
	_icon.queue_redraw()
	_row.add_theme_constant_override("separation", roundi(14 * f))
	_style.content_margin_left = 24 * f
	_style.content_margin_right = 24 * f
	_style.content_margin_top = 10 * f
	_style.content_margin_bottom = 10 * f
	_style.set_corner_radius_all(roundi(16 * f))
	var width := minf(screen.x - 32.0, 760.0 * f)
	# As wide as the text needs (one line where it fits), at most `width`.
	_label.custom_minimum_size = Vector2(0, 0)
	var font: Font = _label.get_theme_font("font")
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(26 * f)).x
	var extra: float = _icon.get_minimum_size().x + (_progress.get_minimum_size().x if _progress.visible else 0.0) + (14 * f) * 2 + 48 * f
	var wanted := minf(text_width + extra + 4.0, width)
	_label.custom_minimum_size.x = maxf(wanted - extra, 40.0)
	_panel.size = Vector2(wanted, 0)
	_panel.size = _panel.get_minimum_size()
	var t := clampf(_age / IN_SECONDS, 0.0, 1.0)
	var ease_in := 1.0 - pow(1.0 - t, 3.0)
	_panel.position = Vector2((screen.x - _panel.size.x) * 0.5, top * f - (1.0 - ease_in) * 18.0 * f)
	_panel.modulate.a = ease_in
	# A gentle glow of the edge while it is new, so the change is noticed.
	_style.border_color = BonStyle.RIM.lerp(EDGE, maxf(0.0, 1.0 - _age / 1.2))
