extends Control
## The welcome tutorial's control cues (16 Nov 2026; scripts/learning/tutorial.gd, a wait step's
## "cue"): while BonBon asks the player to try a control, the matching control pulses on screen.
## Drawn only, never takes a click or a finger (mouse_filter IGNORE), and has no words, so it
## needs no translation.
##   "view"  right of the middle, outside the joystick's left 40%: a hand (touch) or a mouse
##           (keyboard and mouse) sliding left and right between two arrows (drag to look).
##   "move"  keyboard: the W A S D keys, bottom left (where the joystick sits on a touch
##           screen). On a touch screen the joystick itself pulses (touch_controls.gd
##           highlight_stick()), so nothing is drawn here.
## Sized with the window like the panels (money_panel.gd: min(height / 800, width / 1100)).
const BonStyle := preload("res://scripts/ui/bon_style.gd")
# UI art style (18 Nov 2026): soft blue keys and pill, dark teal marks, a green pulse.
const GOLD := BonStyle.INK
const FILL := Color(0.875, 0.953, 0.957, 0.94)
const EDGE := BonStyle.RIM
const GLOW := BonStyle.GREEN_BOTTOM

## "view", "move" or "" (nothing).
var kind := ""
## The touch wording and drawing (BonBon's line says the same).
var touch := false
var _font: Font

func _init() -> void:
	name = "TutorialCue"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_font = BonStyle.font(700)

func show_cue(what: String, on_touch: bool) -> void:
	kind = what
	touch = on_touch
	queue_redraw()

func _process(_delta: float) -> void:
	if kind != "":
		queue_redraw()

func _scale() -> float:
	var screen := get_viewport_rect().size
	return BonStyle.factor(screen, 0.6)

func _draw() -> void:
	if kind == "view":
		_draw_view()
	elif kind == "move" and not touch:
		_draw_keys()

## Two arrows and a hand or a mouse gliding between them.
func _draw_view() -> void:
	var screen := get_viewport_rect().size
	var f := _scale()
	var center := Vector2(screen.x * 0.7, screen.y * 0.42)
	var t := Time.get_ticks_msec() / 1000.0
	var glow := 0.75 + 0.25 * sin(t * 4.0)
	var reach := 120.0 * f
	# A dark pill behind the arrows and the glider (readable on a bright wall or sky).
	var pill := StyleBoxFlat.new()
	pill.bg_color = FILL
	pill.border_color = EDGE.lerp(GLOW, glow - 0.5)
	pill.set_border_width_all(maxi(2, roundi(3.0 * f)))
	pill.set_corner_radius_all(roundi(64.0 * f))
	var half := Vector2(reach + 34.0 * f, 64.0 * f)
	draw_style_box(pill, Rect2(center - half, half * 2.0))
	for side in [-1.0, 1.0]:
		var tip := center + Vector2(side * reach, 0.0)
		var w := 24.0 * f
		var arrow := PackedVector2Array([tip + Vector2(-side * w, -w), tip, tip + Vector2(-side * w, w)])
		draw_polyline(arrow, GOLD, maxf(4.0, 9.0 * f), true)
	var at := center + Vector2(sin(t * 2.2) * reach * 0.45, 0.0)
	if touch:
		# A fingertip: a filled dot with a soft ring.
		draw_circle(at, 30.0 * f, Color(GLOW, 0.9))
		draw_arc(at, 42.0 * f, 0.0, TAU, 48, Color(GLOW, 0.45), maxf(2.0, 4.0 * f), true)
	else:
		# A mouse: a rounded body, the button split and a cable.
		var size := Vector2(52.0, 78.0) * f
		var body := StyleBoxFlat.new()
		body.bg_color = BonStyle.RIM
		body.set_corner_radius_all(roundi(26.0 * f))
		draw_style_box(body, Rect2(at - size * 0.5, size))
		var line := GOLD
		draw_line(at + Vector2(-size.x * 0.5, -size.y * 0.12), at + Vector2(size.x * 0.5, -size.y * 0.12), line, maxf(2.0, 3.0 * f))
		draw_line(at + Vector2(0.0, -size.y * 0.5), at + Vector2(0.0, -size.y * 0.12), line, maxf(2.0, 3.0 * f))

## W above A S D, pulsing, bottom left.
func _draw_keys() -> void:
	var screen := get_viewport_rect().size
	var f := _scale()
	var side := 64.0 * f
	var gap := 10.0 * f
	var glow := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
	var origin := Vector2(48.0 * f, screen.y * 0.5)
	var keys := {"W": Vector2(1, 0), "A": Vector2(0, 1), "S": Vector2(1, 1), "D": Vector2(2, 1)}
	for letter in keys:
		var cell: Vector2 = keys[letter]
		var rect := Rect2(origin + cell * (side + gap), Vector2(side, side))
		var cap := StyleBoxFlat.new()
		cap.bg_color = FILL
		cap.border_color = GLOW.lerp(EDGE, 1.0 - glow)
		cap.set_border_width_all(maxi(2, roundi(4.0 * f)))
		cap.set_corner_radius_all(roundi(12.0 * f))
		cap.shadow_color = Color(GLOW, 0.35 * glow)
		cap.shadow_size = roundi(10.0 * f)
		draw_style_box(cap, rect)
		var size := roundi(side * 0.55)
		var text := _font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
		draw_string(_font, rect.get_center() + Vector2(-text.x * 0.5, text.y * 0.32), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, size, GOLD)
