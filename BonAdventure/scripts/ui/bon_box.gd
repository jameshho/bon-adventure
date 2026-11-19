@tool
extends StyleBox
## The shape of every card, tile and button in the UI art style (docs/guides/UI_STYLE.md, user
## 18 Nov 2026): a rounded box with a thick light rim, a top-to-bottom gradient inside, an
## an optional dark outline (the loading bar's track), a soft
## shadow or glow and an optional speech tail on the top edge (the dialogue box).
## Made by scripts/ui/bon_style.gd (BonStyle.box()); set its fields, then use it like any StyleBox.

## Inside colours, top and bottom.
@export var top := Color("fdf4e3")
@export var bottom := Color("fdf4e3")
## The rim around the inside (0 width: none).
@export var rim := Color("fffdf7")
@export var rim_width := 4.0
## Corner radius in pixels; negative = a pill (half the height).
@export var radius := 24.0
## A dark line just outside the rim (0: none).
@export var outline := Color(0, 0, 0, 0)
@export var outline_width := 0.0
## Shadow or glow under the box.
@export var shadow := Color(0, 0, 0, 0)
@export var shadow_size := 0.0
@export var shadow_offset := Vector2.ZERO
## A speech tail on the top edge: its size (0: none) and where it sits (fraction of the width).
@export var tail := 0.0
@export var tail_at := 0.2

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var r := _radius(rect)
	if outline_width > 0.0:
		var line := StyleBoxFlat.new()
		line.bg_color = outline
		line.set_corner_radius_all(roundi(r + outline_width))
		line.anti_aliasing = true
		line.draw(to_canvas_item, rect.grow(outline_width))
	# Rim (and the shadow under it) as one anti-aliased flat box.
	var body := StyleBoxFlat.new()
	body.bg_color = rim if rim_width > 0.0 else top
	body.set_corner_radius_all(roundi(r))
	body.corner_detail = 12
	body.anti_aliasing = true
	body.shadow_color = shadow
	body.shadow_size = roundi(shadow_size)
	body.shadow_offset = shadow_offset
	body.draw(to_canvas_item, rect)
	if tail > 0.0:
		_tail(to_canvas_item, rect, rim if rim_width > 0.0 else top, 0.0)
	var inner := rect.grow(-rim_width)
	var inner_r := maxf(0.0, r - rim_width)
	if inner.size.x <= 1.0 or inner.size.y <= 1.0:
		return
	var points := rounded(inner, inner_r)
	var colors := PackedColorArray()
	for point in points:
		colors.append(top.lerp(bottom, clampf((point.y - inner.position.y) / inner.size.y, 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, colors)
	# Smooth the polygon's edge (polygons are not anti-aliased).
	var ring := points.duplicate()
	ring.append(points[0])
	var ring_colors := colors.duplicate()
	ring_colors.append(colors[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, ring, ring_colors, 1.2, true)
	if tail > 0.0 and rim_width > 0.0:
		_tail(to_canvas_item, rect, top, rim_width * 1.6)

func _radius(rect: Rect2) -> float:
	var limit := minf(rect.size.x, rect.size.y) * 0.5
	return limit if radius < 0.0 else minf(radius, limit)

## The speech tail: a rounded triangle on the top edge pointing up, `inset` pixels smaller.
func _tail(item: RID, rect: Rect2, color: Color, inset: float) -> void:
	var x := rect.position.x + rect.size.x * tail_at
	var y := rect.position.y
	var w := tail - inset
	var h := tail * 0.8 - inset * 0.7
	var tip := Vector2(x + tail * 0.12, y - h)
	var points := PackedVector2Array([Vector2(x - w * 0.55, y + inset + 1.0), tip, Vector2(x + w * 0.55, y + inset + 1.0)])
	RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([color, color, color]))
	RenderingServer.canvas_item_add_polyline(item, PackedVector2Array([points[0], points[1], points[2]]), PackedColorArray([color, color, color]), 1.2, true)

## The outline of a rounded rectangle, clockwise from the top-left corner.
static func rounded(rect: Rect2, r: float, steps := 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	r = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
	if r < 0.5:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var corners := [
		[rect.position + Vector2(r, r), PI],
		[Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5],
		[rect.end - Vector2(r, r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
	]
	for corner in corners:
		for i in steps + 1:
			var angle: float = corner[1] + PI * 0.5 * float(i) / float(steps)
			var point: Vector2 = corner[0] + Vector2(cos(angle), sin(angle)) * r
			# A pill's straight sides have no length: skip the repeated point (triangulation
			# fails on duplicates).
			if points.is_empty() or points[points.size() - 1].distance_squared_to(point) > 0.01:
				points.append(point)
	if points.size() > 2 and points[0].distance_squared_to(points[points.size() - 1]) <= 0.01:
		points.remove_at(points.size() - 1)
	return points
