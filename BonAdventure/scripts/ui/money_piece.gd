extends Control
## One drawn bill or coin (US style: green notes with a portrait oval and corner numbers,
## copper / silver coins with a rim), optionally with a "×N" count badge. A left click or
## touch emits `pressed`. Used by money_panel.gd; knows nothing about money totals.
signal pressed

const BILL_SIZE := Vector2(150, 70)
const COIN_SIZE := {"coin_1": 64.0, "coin_5": 72.0, "coin_10": 58.0, "coin_25": 80.0}
const BILL_TINT := {"bill_1": "b8d4a8", "bill_5": "c4d6a4", "bill_10": "d3d99f", "bill_20": "a9d1b4", "bill_50": "c2c9a2", "bill_100": "b5d6c3"}
const COIN_TINT := {"coin_1": "c47a4a", "coin_5": "c9ccd0", "coin_10": "d6d9dd", "coin_25": "b9bdc2"}

var denom: Dictionary = {}
var count := 0
var show_count := false
var scale_factor := 1.0
var _hover := false

func setup(for_denom: Dictionary, with_count: bool, factor: float) -> void:
	denom = for_denom
	show_count = with_count
	scale_factor = factor
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = piece_size() * factor
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())

func piece_size() -> Vector2:
	if denom.kind == "bill":
		return BILL_SIZE
	var d: float = COIN_SIZE[denom.id]
	return Vector2(d, d)

func set_count(value: int) -> void:
	count = value
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit()
		accept_event()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var area := Rect2(Vector2.ZERO, piece_size() * scale_factor)
	var lift := Vector2(0, -3 * scale_factor) if _hover else Vector2.ZERO
	area.position += lift
	var label_size := int(round((22.0 if denom.kind == "bill" else 20.0) * scale_factor))
	if denom.kind == "bill":
		var tint := Color(BILL_TINT[denom.id])
		draw_rect(Rect2(area.position + Vector2(0, 4 * scale_factor), area.size), Color(0, 0, 0, 0.28))
		draw_rect(area, Color("2f5d3a"))
		draw_rect(area.grow(-3 * scale_factor), tint)
		draw_rect(area.grow(-7 * scale_factor), Color("2f5d3a"), false, maxf(1.0, scale_factor))
		var centre := area.get_center()
		draw_set_transform(centre, 0.0, Vector2(1.0, 1.25))
		draw_circle(Vector2.ZERO, area.size.y * 0.27, tint.darkened(0.12))
		draw_arc(Vector2.ZERO, area.size.y * 0.27, 0.0, TAU, 28, Color("2f5d3a"), maxf(1.0, scale_factor))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var number := str(denom.label).trim_prefix("$")
		var corner := int(round(15.0 * scale_factor))
		draw_string(font, area.position + Vector2(10, 20) * scale_factor, number, HORIZONTAL_ALIGNMENT_LEFT, -1, corner, Color("1f4026"))
		draw_string(font, area.position + Vector2(area.size.x - 10 * scale_factor - 40 * scale_factor, area.size.y - 9 * scale_factor), number, HORIZONTAL_ALIGNMENT_RIGHT, 40 * scale_factor, corner, Color("1f4026"))
		draw_string(font, Vector2(area.position.x, centre.y + label_size * 0.36), denom.label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, label_size, Color("163020"))
	else:
		var tint := Color(COIN_TINT[denom.id])
		var radius := area.size.x * 0.5
		var centre := area.get_center()
		draw_circle(centre + Vector2(0, 3 * scale_factor), radius, Color(0, 0, 0, 0.28))
		draw_circle(centre, radius, tint.darkened(0.35))
		draw_circle(centre, radius - 3 * scale_factor, tint)
		draw_arc(centre, radius - 7 * scale_factor, 0.0, TAU, 32, tint.darkened(0.25), maxf(1.0, scale_factor))
		draw_string(font, Vector2(area.position.x, centre.y + label_size * 0.36), denom.label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, label_size, Color("2b2b2b"))
	if _hover:
		draw_rect(area.grow(2 * scale_factor), Color(1, 0.85, 0.4, 0.9), false, 2.0 * scale_factor)
	if show_count and count > 0:
		var badge := Vector2(46, 28) * scale_factor
		var rect := Rect2(Vector2(area.end.x - badge.x * 0.8, area.position.y - badge.y * 0.25), badge)
		draw_rect(rect, Color("142a38"))
		draw_rect(rect, Color("7abfb3"), false, maxf(1.0, scale_factor))
		draw_string(font, rect.position + Vector2(0, badge.y * 0.74), "×%d" % count, HORIZONTAL_ALIGNMENT_CENTER, badge.x, int(round(18.0 * scale_factor)), Color("fff1c5"))
