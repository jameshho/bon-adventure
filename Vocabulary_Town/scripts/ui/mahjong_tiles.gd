extends RefCounted
## Drawing of mahjong tile faces (docs/guides/MAHJONG.md), shared by the player's hand in the panel
## (mahjong_panel.gd) and the face atlas of the 3D tiles (mahjong_view.gd). Hong Kong style
## faces in code, no image files: characters (Chinese numeral over a red 萬), dots (rings in
## the usual patterns), bamboo (green sticks), the winds 東南西北 and the dragons 中 發 and a
## blue frame for 白. Every suit tile carries its number as a large digit in a badge in the
## top-left corner, and every wind its letter in the language being learned (user decision,
## 9 Nov 2026).
const Rules := preload("res://scripts/learning/mahjong_rules.gd")
const IVORY := Color("f6efdc")
const EDGE := Color("d8cba8")
const BACK := Color("1f7a52")
const BACK_EDGE := Color("145a3b")
const NAVY := Color("1d3570")
const RED := Color("c4262e")
const GREEN := Color("1d7d3c")
const BLUE := Color("2456b3")
const BADGE := Color("1d3570")
const NUMERALS := ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
const WINDS := ["東", "南", "西", "北"]
const DOTS := {
	1: [[.5, .5]],
	2: [[.5, .25], [.5, .75]],
	3: [[.24, .18], [.5, .5], [.76, .82]],
	4: [[.28, .25], [.72, .25], [.28, .75], [.72, .75]],
	5: [[.26, .2], [.74, .2], [.5, .5], [.26, .8], [.74, .8]],
	6: [[.3, .17], [.7, .17], [.3, .5], [.7, .5], [.3, .83], [.7, .83]],
	7: [[.2, .12], [.5, .26], [.8, .4], [.3, .64], [.7, .64], [.3, .88], [.7, .88]],
	8: [[.3, .12], [.7, .12], [.3, .37], [.7, .37], [.3, .63], [.7, .63], [.3, .88], [.7, .88]],
	9: [[.2, .17], [.5, .17], [.8, .17], [.2, .5], [.5, .5], [.8, .5], [.2, .83], [.5, .83], [.8, .83]],
}
## Bamboo sticks: [x, y] centres in the pip area; the stick's height follows the rows.
const STICKS := {
	2: [[.5, .27], [.5, .73]],
	3: [[.5, .27], [.3, .73], [.7, .73]],
	4: [[.3, .27], [.7, .27], [.3, .73], [.7, .73]],
	5: [[.22, .27], [.78, .27], [.5, .5], [.22, .73], [.78, .73]],
	6: [[.2, .27], [.5, .27], [.8, .27], [.2, .73], [.5, .73], [.8, .73]],
	7: [[.5, .17], [.2, .5], [.5, .5], [.8, .5], [.2, .83], [.5, .83], [.8, .83]],
	# 8: as on real tiles (traced from the user's reference, 9 Nov 2026): in each half two
	# upright outer sticks and two short, shallow inner sticks joining them to the middle. Top
	# half "W": the inner sticks leave the outer ones two thirds down and meet a third down in
	# the middle (/\). Bottom half "M": they leave a third down and meet two thirds down (\/).
	# A clear gap between the halves. Inner sticks are segments [x1, y1, x2, y2].
	8: [[.13, .27], [.2, .4, .5, .15], [.8, .4, .5, .15], [.87, .27], [.13, .73], [.2, .6, .5, .85], [.8, .6, .5, .85], [.87, .73]],
	9: [[.2, .17], [.5, .17], [.8, .17], [.2, .5], [.5, .5], [.8, .5], [.2, .83], [.5, .83], [.8, .83]],
}

static func font() -> Font:
	return ThemeDB.fallback_font

## The whole face of `kind` inside `rect` (ivory background included). `letters`: the four
## wind letters in the language being learned (E, S, W, N order).
static func draw_face(ci: CanvasItem, rect: Rect2, kind: int, letters: Array) -> void:
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return   # not laid out yet
	var r := minf(rect.size.x, rect.size.y) * 0.12
	_round_rect(ci, rect, r, IVORY)
	var pad := rect.size.x * 0.08
	var inner := rect.grow(-pad)
	if Rules.is_honor(kind):
		var letter := ""
		if Rules.is_wind(kind):
			letter = str(letters[kind - Rules.EAST]) if letters.size() == 4 else "ESWN"[kind - Rules.EAST]
		if letter != "":
			_badge(ci, inner, letter)
		var area := inner
		if letter != "":
			area = Rect2(inner.position + Vector2(0, inner.size.y * 0.2), inner.size * Vector2(1, 0.8))
		_honor(ci, area, kind)
		return
	_badge(ci, inner, str(Rules.number(kind)))
	var pips := Rect2(inner.position + Vector2(0, inner.size.y * 0.24), inner.size * Vector2(1, 0.76))
	match Rules.suit(kind):
		0: _characters(ci, pips, Rules.number(kind))
		1: _dots(ci, pips, Rules.number(kind))
		2: _bamboo(ci, pips, Rules.number(kind))

## The tile back (face down): green with a lighter inner panel.
static func draw_back(ci: CanvasItem, rect: Rect2) -> void:
	var r := minf(rect.size.x, rect.size.y) * 0.12
	_round_rect(ci, rect, r, BACK_EDGE)
	_round_rect(ci, rect.grow(-rect.size.x * 0.07), r * 0.8, BACK)

static func _round_rect(ci: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	box.draw(ci.get_canvas_item(), rect)

static func _text(ci: CanvasItem, center: Vector2, text: String, size: int, color: Color) -> void:
	if size < 2:
		return
	var f := font()
	var width := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5
	ci.draw_string(f, Vector2(center.x - width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

## The corner number (or wind letter): white on a navy rounded badge, top left.
static func _badge(ci: CanvasItem, inner: Rect2, text: String) -> void:
	var h := inner.size.y * 0.22
	var w := maxf(h * 1.05, h * 0.62 * text.length())
	var rect := Rect2(inner.position, Vector2(w, h))
	_round_rect(ci, rect, h * 0.3, BADGE)
	_text(ci, rect.get_center(), text, int(h * 0.82), Color.WHITE)

static func _honor(ci: CanvasItem, area: Rect2, kind: int) -> void:
	var size := int(minf(area.size.x * 0.82, area.size.y * 0.72))
	var center := area.get_center()
	if Rules.is_wind(kind):
		_text(ci, center, WINDS[kind - Rules.EAST], size, NAVY)
	elif kind == Rules.RED:
		_text(ci, center, "中", size, RED)
	elif kind == Rules.GREEN:
		_text(ci, center, "發", size, GREEN)
	else:
		# White dragon: a blue double frame.
		var frame := Rect2(center - area.size * Vector2(0.32, 0.36), area.size * Vector2(0.64, 0.72))
		var line := maxf(area.size.x * 0.05, 1.5)
		ci.draw_rect(frame, BLUE, false, line)
		ci.draw_rect(frame.grow(-line * 2.2), BLUE, false, line * 0.6)

static func _characters(ci: CanvasItem, area: Rect2, n: int) -> void:
	var size := int(minf(area.size.x * 0.62, area.size.y * 0.4))
	_text(ci, area.position + Vector2(area.size.x * 0.5, area.size.y * 0.25), NUMERALS[n - 1], size, NAVY)
	_text(ci, area.position + Vector2(area.size.x * 0.5, area.size.y * 0.72), "萬", size, RED)

static func _dots(ci: CanvasItem, area: Rect2, n: int) -> void:
	var points: Array = DOTS[n]
	var radius := minf(area.size.x, area.size.y) * (0.36 if n == 1 else 0.17 if n <= 4 else 0.13 if n <= 6 else 0.11)
	var colors := [BLUE, GREEN, RED]
	for i in points.size():
		var p: Array = points[i]
		var center := area.position + Vector2(p[0], p[1]) * area.size
		var color: Color = RED if (n == 1 or (n == 5 and i == 2) or (n == 9 and i >= 3 and i <= 5)) else colors[i % 2] if n != 3 else colors[i]
		ci.draw_circle(center, radius, color)
		ci.draw_circle(center, radius * 0.72, IVORY)
		ci.draw_circle(center, radius * 0.42, color)
		if n == 1:
			ci.draw_circle(center, radius * 0.18, IVORY)

static func _bamboo(ci: CanvasItem, area: Rect2, n: int) -> void:
	if n == 1:
		# One bamboo: a single tall stick with a red crown (the bird of real tiles, simplified).
		_stick(ci, area.position + area.size * Vector2(0.5, 0.55), area.size.x * 0.22, area.size.y * 0.8, GREEN)
		ci.draw_circle(area.position + area.size * Vector2(0.5, 0.12), area.size.x * 0.14, RED)
		return
	var points: Array = STICKS[n]
	var rows := 3 if n == 7 or n == 9 else 2
	var height := area.size.y * (0.3 if rows == 3 else 0.38 if n == 8 else 0.42)
	var width := area.size.x * (0.13 if n == 8 else 0.16)
	for i in points.size():
		var p: Array = points[i]
		var red := (n == 5 and i == 2) or (n == 7 and i == 0) or (n == 9 and (i == 1 or i == 4 or i == 7))
		var color := RED if red else GREEN
		if p.size() == 4:
			var a := area.position + Vector2(p[0], p[1]) * area.size
			var b := area.position + Vector2(p[2], p[3]) * area.size
			var top := a if a.y < b.y else b
			var bottom := b if a.y < b.y else a
			var d := top - bottom
			_stick(ci, (a + b) * 0.5, width * 0.85, d.length() + width * 0.3, color, atan2(d.x, -d.y))
		else:
			_stick(ci, area.position + Vector2(p[0], p[1]) * area.size, width, height, color)

## A bamboo stick centred on `center`; `angle` (radians, clockwise) tilts it.
static func _stick(ci: CanvasItem, center: Vector2, width: float, height: float, color: Color, angle: float = 0.0) -> void:
	if angle != 0.0:
		ci.draw_set_transform(center, angle)
		center = Vector2.ZERO
	var rect := Rect2(center - Vector2(width, height) * 0.5, Vector2(width, height))
	_round_rect(ci, rect, width * 0.45, color)
	var joint := color.darkened(0.35)
	ci.draw_line(Vector2(rect.position.x, center.y), Vector2(rect.end.x, center.y), joint, maxf(width * 0.18, 1.0))
	ci.draw_line(rect.position + Vector2(width * 0.5, height * 0.12), rect.position + Vector2(width * 0.5, height * 0.88), IVORY.darkened(0.05), maxf(width * 0.12, 1.0))
	if angle != 0.0:
		ci.draw_set_transform(Vector2.ZERO)
