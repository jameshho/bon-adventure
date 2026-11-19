extends Control
## One drawn bill or coin (US style: green notes with a portrait oval and corner numbers,
## copper / silver coins with a rim), optionally with a "×N" count badge. A left click or
## touch emits `pressed`. Used by money_panel.gd; knows nothing about money totals.
signal pressed

const BILL_SIZE := Vector2(150, 70)
const COIN_SIZE := {"coin_1": 64.0, "coin_5": 72.0, "coin_10": 58.0, "coin_25": 80.0}
## Bright, soft colours to the user's mockup (docs/guides/design-references/ui/money-panel.webp,
## 18 Nov 2026): light green notes ($10 and $50 yellow), a darker edge, a ring round the value.
const BILL_TINT := {"bill_1": "c9eda4", "bill_5": "dcf3a8", "bill_10": "f6ef9e", "bill_20": "c8edbc", "bill_50": "eee29c", "bill_100": "cdeec9"}
const BILL_EDGE := {"bill_1": "3f8f3c", "bill_5": "5d9a32", "bill_10": "b9a43a", "bill_20": "3f8f4a", "bill_50": "a8902e", "bill_100": "3f8f4a"}
const COIN_TINT := {"coin_1": "eb8a4e", "coin_5": "dcdfe3", "coin_10": "e7e9ec", "coin_25": "cdd0d5"}
const BonStyle := preload("res://scripts/ui/bon_style.gd")

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
	var k := scale_factor
	var area := Rect2(Vector2.ZERO, piece_size() * k)
	var lift := Vector2(0, -3 * k) if _hover else Vector2.ZERO
	area.position += lift
	var label_size := int(round((24.0 if denom.kind == "bill" else 21.0) * k))
	var bold: Font = BonStyle.font(700)
	if denom.kind == "bill":
		var tint := Color(BILL_TINT[denom.id])
		var edge := Color(BILL_EDGE[denom.id])
		var ink := edge.darkened(0.45)
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color(0.1, 0.27, 0.32, 0.18)
		shadow.set_corner_radius_all(roundi(7 * k))
		draw_style_box(shadow, Rect2(area.position + Vector2(0, 5 * k), area.size))
		var body := StyleBoxFlat.new()
		body.bg_color = tint
		body.border_color = edge
		body.set_border_width_all(maxi(2, roundi(3.5 * k)))
		body.set_corner_radius_all(roundi(7 * k))
		body.anti_aliasing = true
		draw_style_box(body, area)
		# A thin inner frame with little rounded notches in its corners.
		var inner := area.grow(-8 * k)
		var frame := StyleBoxFlat.new()
		frame.draw_center = false
		frame.border_color = Color(edge, 0.45)
		frame.set_border_width_all(maxi(1, roundi(1.5 * k)))
		frame.set_corner_radius_all(roundi(6 * k))
		frame.anti_aliasing = true
		draw_style_box(frame, inner)
		for corner in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
			draw_arc(corner, 6 * k, 0.0, TAU, 16, Color(edge, 0.45), maxf(1.0, 1.5 * k), true)
		var centre := area.get_center()
		var ring := area.size.y * 0.31
		draw_circle(centre, ring, tint.lightened(0.18))
		draw_arc(centre, ring, 0.0, TAU, 40, edge, maxf(1.5, 2.5 * k), true)
		var number := str(denom.label).trim_prefix("$")
		var corner_size := int(round(15.0 * k))
		draw_string(bold, area.position + Vector2(11, 22) * k, number, HORIZONTAL_ALIGNMENT_LEFT, -1, corner_size, ink)
		draw_string(bold, area.position + Vector2(area.size.x - 51 * k, area.size.y - 10 * k), number, HORIZONTAL_ALIGNMENT_RIGHT, 40 * k, corner_size, ink)
		draw_string(bold, Vector2(area.position.x, centre.y + label_size * 0.36), denom.label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, label_size, ink)
	else:
		var tint := Color(COIN_TINT[denom.id])
		var radius := area.size.x * 0.5
		var centre := area.get_center()
		draw_circle(centre + Vector2(0, 4 * k), radius, Color(0.1, 0.27, 0.32, 0.2))
		draw_circle(centre, radius, tint.darkened(0.22))
		draw_circle(centre, radius - 4 * k, tint)
		draw_arc(centre, radius - 8 * k, 0.0, TAU, 40, tint.lightened(0.35), maxf(1.0, 2.0 * k), true)
		draw_string(bold, Vector2(area.position.x, centre.y + label_size * 0.36), denom.label, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, label_size, tint.darkened(0.62))
	if _hover:
		var glow := StyleBoxFlat.new()
		glow.draw_center = false
		glow.border_color = Color(1, 1, 1, 0.95)
		glow.set_border_width_all(maxi(2, roundi(3 * k)))
		glow.set_corner_radius_all(roundi((10.0 if denom.kind == "bill" else area.size.x * 0.5 / k + 3.0) * k))
		glow.anti_aliasing = true
		draw_style_box(glow, area.grow(3 * k))
	if show_count and count > 0:
		# A dark teal tag with a white count (the mockup).
		var badge := Vector2(48, 30) * k
		var rect := Rect2(Vector2(area.end.x - badge.x * 0.85, area.position.y - badge.y * 0.4), badge)
		var tag := StyleBoxFlat.new()
		tag.bg_color = BonStyle.INK
		tag.set_corner_radius_all(roundi(8 * k))
		tag.anti_aliasing = true
		draw_style_box(tag, rect)
		draw_string(bold, rect.position + Vector2(0, badge.y * 0.72), "×%d" % count, HORIZONTAL_ALIGNMENT_CENTER, badge.x, int(round(19.0 * k)), Color.WHITE)
