extends RefCounted
## Food pictures and property icons for the Alta Cocina restaurant game, drawn in code
## (6 Nov 2026, user decision: no image assets; one flat style for every dish). The same
## drawings serve the menu panel (FoodIcons.View, a Control) and the restaurant posters
## (sheet(): one SubViewport per poster whose texture the cards' Sprite3Ds share).
##
## Everything is drawn in a 100 × 100 box (y down) scaled into the target rect.
## - Dishes: data/restaurant_game.json "art" = {"base": vessel, "fill"?: colour,
##   "layers": [[shape, colour?], …]}; BASES and LAYERS list what exists, and each base
##   gives the anchor point its layers are drawn around. New dishes reuse these; a new shape
##   is one more match branch in _layer().
## - Properties: one icon per taste, temperature word and tag (PROPERTY_ICONS). The same
##   icon means the same property everywhere (menu, inspection, posters).
## - Intensity: bars() draws 0-3 filled pill bars; zero is three grey bars, and faded() greys an
##   icon so "none" reads at a glance. crossed() is the "not" mark, ring() the missed one.
const BASES := ["plate", "bowl", "glass", "mug", "cup", "dessert_cup", "board", "none"]
const LAYERS := ["leaves", "tomatoes", "veg_bits", "herb_bits", "cucumber", "fries", "bread",
	"cheese_melt", "shrimp", "lemon_wedge", "chips", "jalapenos", "wings", "drumstick",
	"grill_marks", "steam", "taco", "chili_small", "fish", "roast", "beef_chunks", "pork_slab",
	"lasagna", "pizza", "spaghetti", "meatballs", "steak", "scoops", "cake_slice", "brownie",
	"yogurt", "berries", "candies", "fruit_bits", "tiramisu", "flan", "pie_slice", "cookies",
	"ice", "lemon_rim", "orange_rim", "straw", "bubbles", "whipped", "strawberry_top", "tea_tag"]
const PROPERTY_ICONS := ["sweet", "salty", "sour", "bitter", "spicy", "cold", "warm", "hot",
	"crunchy", "creamy", "juicy", "dry", "hard", "soft", "refreshing", "fizzy", "fresh", "with_ice",
	"chicken", "fish", "beef", "pork", "lamb", "shrimp", "vegetables", "fruit", "cheese", "chocolate"]
## Where each base's food sits (layers are drawn around it).
const ANCHORS := {"plate": Vector2(50, 60), "bowl": Vector2(50, 48), "glass": Vector2(50, 26),
	"mug": Vector2(46, 34), "cup": Vector2(50, 44), "dessert_cup": Vector2(50, 42),
	"board": Vector2(50, 58), "none": Vector2(50, 58)}
## Glass interior at y (for liquid, ice and bubbles): x from 32 + t*3 to 68 - t*3.
const GLASS_TOP := 14.0
const GLASS_BOTTOM := 92.0
const INK := Color("3b2f2a")
const WHITE := Color("fbf8f2")
const PORCELAIN := Color("ebe5d9")
const BAR_EMPTY := Color("d9d2c4")

static func has_property_icon(id: String) -> bool:
	return PROPERTY_ICONS.has(id)

## Problems with a dish's art spec ([] when every base and layer exists).
static func art_problems(art: Dictionary) -> PackedStringArray:
	var found: PackedStringArray = []
	if not BASES.has(str(art.get("base", ""))):
		found.append("unknown base '%s'" % art.get("base", ""))
	for layer in art.get("layers", []):
		if not layer is Array or layer.is_empty() or not LAYERS.has(str(layer[0])):
			found.append("unknown layer %s" % [layer])
	return found

# --- Primitives (all in the 100 × 100 box) ------------------------------------------------

static func _begin(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_set_transform(rect.position, 0.0, rect.size / 100.0)

static func _end(ci: CanvasItem) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _ellipse_points(c: Vector2, rx: float, ry: float, from := 0.0, to := TAU, steps := 36, angle := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps + 1:
		var a := lerpf(from, to, i / float(steps))
		points.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(angle))
	if is_equal_approx(to - from, TAU):
		points.remove_at(points.size() - 1)
	return points

static func _ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, angle := 0.0) -> void:
	ci.draw_colored_polygon(_ellipse_points(c, rx, ry, 0.0, TAU, 36, angle), color)

static func _poly(ci: CanvasItem, points: Array, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(points), color)

static func _line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	ci.draw_line(a, b, color, width, true)
	# Round caps, so thick lines read as sausages, bones and stems.
	if width > 3.0:
		ci.draw_circle(a, width / 2.0, color)
		ci.draw_circle(b, width / 2.0, color)

static func _arc(ci: CanvasItem, c: Vector2, r: float, from: float, to: float, color: Color, width: float) -> void:
	ci.draw_arc(c, r, from, to, 24, color, width, true)

static func _round_rect(ci: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	var points := PackedVector2Array()
	var corners := [rect.position + Vector2(rect.size.x - r, r), rect.end - Vector2(r, r), rect.position + Vector2(r, rect.size.y - r), rect.position + Vector2(r, r)]
	for k in 4:
		for i in 7:
			var a := -PI / 2 + k * PI / 2 + i * (PI / 2) / 6.0
			points.append(corners[k] + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(points, color)

static func _wave(ci: CanvasItem, x: float, top: float, bottom: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		points.append(Vector2(x + sin(t * TAU * 1.2) * 4.0, lerpf(bottom, top, t)))
	ci.draw_polyline(points, color, width, true)

static func _star(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 8:
		var radius := r if i % 2 == 0 else r * .35
		var a := -PI / 2 + i * PI / 4
		points.append(c + Vector2(cos(a), sin(a)) * radius)
	ci.draw_colored_polygon(points, color)

static func _glass_x(y: float) -> Vector2:
	var t := (y - GLASS_TOP) / (GLASS_BOTTOM - GLASS_TOP)
	return Vector2(30.0 + t * 6.0, 70.0 - t * 6.0)

# --- Dishes ------------------------------------------------------------------------------

## A dish picture in `rect` from its art spec.
static func draw_dish(ci: CanvasItem, art: Dictionary, rect: Rect2) -> void:
	_begin(ci, rect)
	var base := str(art.get("base", "plate"))
	var fill := Color(str(art.get("fill", "e8d9b8")))
	_base(ci, base, fill, false)
	var anchor: Vector2 = ANCHORS.get(base, Vector2(50, 58))
	for layer in art.get("layers", []):
		var color: Variant = Color(str(layer[1])) if layer.size() > 1 else null
		_layer(ci, str(layer[0]), anchor, base, color)
	_base(ci, base, fill, true)
	_end(ci)

## The vessel; `front` draws the parts in front of the food (glass walls, rims).
static func _base(ci: CanvasItem, base: String, fill: Color, front: bool) -> void:
	match base:
		"plate":
			if not front:
				_ellipse(ci, Vector2(50, 74), 47, 15, Color(0, 0, 0, .12))
				_ellipse(ci, Vector2(50, 71), 47, 15, WHITE)
				_ellipse(ci, Vector2(50, 70), 36, 10.5, PORCELAIN)
		"bowl":
			if not front:
				_ellipse(ci, Vector2(50, 88), 26, 5, Color(0, 0, 0, .12))
				_poly(ci, _ellipse_points(Vector2(50, 48), 42, 38, 0.0, PI), WHITE)
				_ellipse(ci, Vector2(50, 48), 42, 11, PORCELAIN)
				_ellipse(ci, Vector2(50, 49), 37, 8.5, fill)
			else:
				ci.draw_polyline(_ellipse_points(Vector2(50, 48), 42, 11, 0.0, PI), WHITE, 2.5, true)
		"glass":
			if not front:
				_ellipse(ci, Vector2(50, 93), 20, 4, Color(0, 0, 0, .12))
				var top := 30.0
				var a := _glass_x(top)
				var b := _glass_x(GLASS_BOTTOM)
				_poly(ci, [Vector2(a.x, top), Vector2(a.y, top), Vector2(b.y, GLASS_BOTTOM), Vector2(b.x, GLASS_BOTTOM)], fill)
				_ellipse(ci, Vector2(50, top), (a.y - a.x) / 2, 3.5, fill.lightened(.15))
			else:
				var t := _glass_x(GLASS_TOP)
				var bottom := _glass_x(GLASS_BOTTOM)
				var edge := Color("9fc3cf")
				_line(ci, Vector2(t.x, GLASS_TOP), Vector2(bottom.x, GLASS_BOTTOM), edge, 2.5)
				_line(ci, Vector2(t.y, GLASS_TOP), Vector2(bottom.y, GLASS_BOTTOM), edge, 2.5)
				_line(ci, Vector2(bottom.x, GLASS_BOTTOM), Vector2(bottom.y, GLASS_BOTTOM), edge, 3.0)
				ci.draw_polyline(_ellipse_points(Vector2(50, GLASS_TOP), (t.y - t.x) / 2, 3.5), edge, 2.0, true)
				_line(ci, Vector2(t.x + 5, GLASS_TOP + 12), Vector2(t.x + 7.5, GLASS_BOTTOM - 12), Color(1, 1, 1, .55), 2.5)
		"mug":
			if not front:
				_ellipse(ci, Vector2(46, 92), 26, 4, Color(0, 0, 0, .12))
				_arc(ci, Vector2(70, 62), 12, -PI / 2, PI / 2, Color("c4473a"), 6.0)
				_round_rect(ci, Rect2(22, 34, 48, 58), 7, Color("c4473a"))
				_ellipse(ci, Vector2(46, 35), 24, 6, Color("a8382d"))
				_ellipse(ci, Vector2(46, 36), 21, 4.5, fill)
		"cup":
			if not front:
				_ellipse(ci, Vector2(50, 86), 40, 9, WHITE)
				_ellipse(ci, Vector2(50, 85), 26, 5, PORCELAIN)
				_arc(ci, Vector2(74, 58), 10, -PI / 2, PI / 2, WHITE, 5.0)
				_poly(ci, [Vector2(24, 44), Vector2(76, 44), Vector2(68, 82), Vector2(32, 82)], WHITE)
				_ellipse(ci, Vector2(50, 44), 26, 6, PORCELAIN)
				_ellipse(ci, Vector2(50, 45), 23, 4.5, fill)
		"dessert_cup":
			if not front:
				_ellipse(ci, Vector2(50, 92), 20, 4, Color(0, 0, 0, .12))
				_ellipse(ci, Vector2(50, 90), 18, 4, Color("cfe6ee"))
				_poly(ci, [Vector2(47, 70), Vector2(53, 70), Vector2(54, 90), Vector2(46, 90)], Color("cfe6ee"))
				_poly(ci, _ellipse_points(Vector2(50, 46), 34, 26, 0.0, PI), Color("dcedf3"))
				_ellipse(ci, Vector2(50, 46), 34, 8, Color("e9f4f8"))
			else:
				ci.draw_polyline(_ellipse_points(Vector2(50, 46), 34, 26, 0.0, PI), Color("9fc3cf"), 2.0, true)
		"board":
			if not front:
				_ellipse(ci, Vector2(50, 80), 44, 6, Color(0, 0, 0, .12))
				_round_rect(ci, Rect2(8, 62, 84, 16), 6, Color("b07a45"))
				_round_rect(ci, Rect2(8, 60, 84, 14), 6, Color("c98f55"))
				_line(ci, Vector2(14, 67), Vector2(86, 67), Color("b07a45"), 1.2)

static func _layer(ci: CanvasItem, shape: String, at: Vector2, base: String, color: Variant) -> void:
	match shape:
		"leaves":
			for p in [Vector2(-18, -2), Vector2(-6, -8), Vector2(8, -6), Vector2(18, 0), Vector2(0, 2), Vector2(-12, 4), Vector2(12, 5)]:
				_ellipse(ci, at + p, 11, 6.5, Color("5fa83e"), p.x * .03)
				_ellipse(ci, at + p + Vector2(1, -1), 7, 3.5, Color("8fd06a"), p.x * .03)
		"tomatoes":
			for p in [Vector2(-10, -4), Vector2(9, -2), Vector2(0, 3)]:
				ci.draw_circle(at + p, 5.5, Color("d8352a"))
				ci.draw_circle(at + p + Vector2(-1.5, -1.5), 1.8, Color("f08070"))
		"veg_bits":
			for p in [Vector2(-14, 0), Vector2(-4, 3), Vector2(8, -1), Vector2(16, 3), Vector2(2, -4)]:
				_poly(ci, [at + p + Vector2(-3, -3), at + p + Vector2(3, -3), at + p + Vector2(3, 3), at + p + Vector2(-3, 3)], Color("ef8a2a"))
			for p in [Vector2(-9, -3), Vector2(4, 4), Vector2(12, -4), Vector2(-17, 4)]:
				ci.draw_circle(at + p, 2.6, Color("5fa83e"))
		"herb_bits":
			for p in [Vector2(-14, -2), Vector2(-5, 2), Vector2(6, -3), Vector2(14, 1), Vector2(0, -6), Vector2(-9, 5)]:
				ci.draw_circle(at + p, 1.6, Color("3f8a2a"))
		"cucumber":
			for p in [Vector2(-8, -2), Vector2(8, 1)]:
				ci.draw_circle(at + p, 5.5, Color("3f8a2a"))
				ci.draw_circle(at + p, 4.2, Color("cfe8a8"))
		"fries":
			var stick := Color("f2c94c")
			for i in 9:
				var x := 32.0 + i * 4.5
				var top := 20.0 + float((i * 7) % 11)
				_poly(ci, [Vector2(x, top), Vector2(x + 4, top + 1), Vector2(x + 2.5, 56), Vector2(x - 1.5, 55)], stick if i % 2 == 0 else stick.darkened(.08))
			_poly(ci, [Vector2(26, 46), Vector2(74, 46), Vector2(66, 92), Vector2(34, 92)], Color("d8352a"))
			_poly(ci, [Vector2(27, 52), Vector2(73, 52), Vector2(72.4, 56), Vector2(27.6, 56)], WHITE)
		"bread":
			_ellipse(ci, at + Vector2(0, -2), 34, 15, Color("d9a35a"))
			_ellipse(ci, at + Vector2(0, -5), 30, 10, Color("e8b874"))
			for x in [-14.0, 0.0, 14.0]:
				_line(ci, at + Vector2(x - 4, -10), at + Vector2(x + 4, -2), Color("b5803e"), 2.0)
		"cheese_melt":
			var cheese := Color("f5c93a")
			_ellipse(ci, at + Vector2(0, -10), 26, 7, cheese)
			for x in [-16.0, -4.0, 9.0, 19.0]:
				_line(ci, at + Vector2(x, -9), at + Vector2(x, -2 + absf(x) * .15), cheese, 4.0)
		"shrimp":
			for p in [Vector2(-14, -4), Vector2(2, -8), Vector2(12, 2)]:
				_arc(ci, at + p, 8, PI * .1, PI * 1.25, Color("f08a5d"), 6.0)
				_poly(ci, [at + p + Vector2(7, 2), at + p + Vector2(13, -1), at + p + Vector2(12, 6)], Color("e0603a"))
		"lemon_wedge":
			var c := at + Vector2(26, 2) if base != "glass" else Vector2(66, 16)
			_poly(ci, _ellipse_points(c, 10, 10, PI, TAU), Color("e6c021"))
			_poly(ci, _ellipse_points(c, 8, 8, PI, TAU), Color("fbe58a"))
		"chips":
			for p in [Vector2(-18, -2), Vector2(-6, -8), Vector2(8, -4), Vector2(18, 0), Vector2(-2, 3), Vector2(12, 5), Vector2(-14, 6)]:
				_poly(ci, [at + p + Vector2(0, -8), at + p + Vector2(8, 5), at + p + Vector2(-8, 5)], Color("e8b04a"))
		"jalapenos":
			for p in [Vector2(-10, -6), Vector2(6, -9), Vector2(14, -3)]:
				ci.draw_circle(at + p, 3.5, Color("3f8a2a"))
				ci.draw_circle(at + p, 2.0, Color("a8d070"))
		"wings":
			for p in [Vector2(-16, 0), Vector2(0, -4), Vector2(16, 1)]:
				_line(ci, at + p + Vector2(-4, 4), at + p + Vector2(5, -5), Color("b5482a"), 12.0)
				ci.draw_circle(at + p + Vector2(-3, -2), 2.5, Color("e0603a"))
		"drumstick":
			_line(ci, at + Vector2(-12, 4), at + Vector2(6, -6), Color("b0602e"), 20.0)
			_line(ci, at + Vector2(10, -8), at + Vector2(20, -14), WHITE, 5.0)
			ci.draw_circle(at + Vector2(22, -17), 3.5, WHITE)
			ci.draw_circle(at + Vector2(24, -13), 3.5, WHITE)
		"grill_marks":
			for k in 3:
				_line(ci, at + Vector2(-10 + k * 7, -2), at + Vector2(-5 + k * 7, -9), Color("5a2e14"), 2.0)
		"steam":
			var top := 4.0 if base in ["mug", "cup", "glass"] else 10.0
			var bottom := at.y - 14.0
			for x in [-10.0, 0.0, 10.0]:
				_wave(ci, at.x + x, top, maxf(bottom, top + 14.0), Color(.6, .6, .62, .7), 2.5)
		"taco":
			_poly(ci, _ellipse_points(at + Vector2(0, 6), 30, 26, PI, TAU), Color("f2c25a"))
			_poly(ci, _ellipse_points(at + Vector2(0, 6), 24, 20, PI * 1.05, PI * 1.95), Color("8a4a2a"))
			for p in [Vector2(-14, -10), Vector2(-4, -16), Vector2(8, -15), Vector2(16, -8)]:
				ci.draw_circle(at + p, 4.0, Color("5fa83e"))
			for p in [Vector2(-8, -12), Vector2(4, -12), Vector2(12, -12)]:
				ci.draw_circle(at + p, 2.5, Color("d8352a"))
			_arc(ci, at + Vector2(0, 6), 28, PI, TAU, Color("d9a040"), 3.0)
		"chili_small":
			_arc(ci, at + Vector2(26, 0), 8, PI * .2, PI * .9, Color("d8352a"), 5.0)
			_line(ci, at + Vector2(31, 5), at + Vector2(34, 2), Color("3f8a2a"), 3.0)
		"fish":
			_ellipse(ci, at + Vector2(-4, -2), 26, 11, Color("e8c9a0"))
			_poly(ci, [at + Vector2(18, -2), at + Vector2(32, -12), at + Vector2(32, 8)], Color("d9b080"))
			ci.draw_circle(at + Vector2(-20, -5), 2.2, INK)
			for k in 3:
				_arc(ci, at + Vector2(-6 + k * 8, -2), 6, -PI * .35, PI * .35, Color("c99a68"), 1.5)
		"roast":
			_ellipse(ci, at + Vector2(0, -2), 28, 15, Color("7a3c1e"))
			_ellipse(ci, at + Vector2(-3, -6), 20, 8, Color("a0552c"))
			for x in [-10.0, 0.0, 10.0]:
				_line(ci, at + Vector2(x, 6), at + Vector2(x + 3, -12), Color("5a2a12"), 1.5)
		"beef_chunks":
			for p in [Vector2(-14, -2), Vector2(-2, -7), Vector2(10, -2), Vector2(2, 4), Vector2(-10, 5)]:
				_round_rect(ci, Rect2(at + p - Vector2(5, 4), Vector2(10, 8)), 3, Color("7a3c1e"))
		"pork_slab":
			_round_rect(ci, Rect2(at + Vector2(-24, -12), Vector2(48, 18)), 4, Color("f0c9a8"))
			_round_rect(ci, Rect2(at + Vector2(-24, -16), Vector2(48, 8)), 4, Color("d9963a"))
			for x in [-16.0, -6.0, 4.0, 14.0]:
				_line(ci, at + Vector2(x, -15), at + Vector2(x + 4, -9), Color("a8641e"), 1.8)
		"lasagna":
			var r := Rect2(at + Vector2(-22, -20), Vector2(44, 26))
			_poly(ci, [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)], Color("f0d080"))
			for k in 3:
				var y := r.position.y + 5 + k * 7
				_poly(ci, [Vector2(r.position.x, y), Vector2(r.end.x, y), Vector2(r.end.x, y + 3), Vector2(r.position.x, y + 3)], Color("c8402a"))
			_ellipse(ci, Vector2(at.x, r.position.y), 23, 3.5, Color("f5d860"))
		"pizza":
			_ellipse(ci, at + Vector2(0, 2), 36, 13, Color("d9a35a"))
			_ellipse(ci, at + Vector2(0, 2), 31, 10.5, Color("d8442e"))
			for p in [Vector2(-16, 0), Vector2(-4, -4), Vector2(10, 3), Vector2(18, -1), Vector2(2, 6), Vector2(-12, 6)]:
				_ellipse(ci, at + p, 5, 2.5, Color("f8e8b0"))
			for p in [Vector2(-8, 2), Vector2(8, -3), Vector2(16, 5), Vector2(-20, 4)]:
				_ellipse(ci, at + p, 3.5, 2, Color("9a2a1e"))
		"spaghetti":
			for k in 6:
				var points := PackedVector2Array()
				for i in 9:
					points.append(at + Vector2(-26 + i * 6.5, -2 + k * 2.2 + sin(i * 1.3 + k) * 2.5))
				ci.draw_polyline(points, Color("f2d27a") if k % 2 == 0 else Color("e6c060"), 2.2, true)
		"meatballs":
			for p in [Vector2(-10, -6), Vector2(4, -8), Vector2(-2, 0), Vector2(12, -1)]:
				ci.draw_circle(at + p, 6.0, Color("7a3c1e"))
				ci.draw_circle(at + p + Vector2(-2, -2), 1.8, Color("a8603a"))
			_ellipse(ci, at + Vector2(0, -6), 16, 3, Color(.85, .25, .15, .7))
		"steak":
			_poly(ci, [at + Vector2(-26, -4), at + Vector2(-18, -14), at + Vector2(14, -14), at + Vector2(26, -6), at + Vector2(20, 6), at + Vector2(-20, 6)], Color("f2e6d0"))
			_poly(ci, [at + Vector2(-22, -4), at + Vector2(-16, -11), at + Vector2(12, -11), at + Vector2(22, -6), at + Vector2(17, 3), at + Vector2(-17, 3)], Color("7a3420"))
		"scoops":
			var tint: Color = color if color != null else Color("f6e7b8")
			for p in [Vector2(-12, 0), Vector2(12, 0), Vector2(0, -12)]:
				ci.draw_circle(at + p, 13.0, tint)
				ci.draw_circle(at + p + Vector2(-4, -4), 3.5, tint.lightened(.35))
			ci.draw_circle(at + Vector2(3, -26), 4.0, Color("c8202a"))
		"cake_slice":
			var tint: Color = color if color != null else Color("6b3b22")
			_poly(ci, [at + Vector2(-26, 8), at + Vector2(24, 8), at + Vector2(24, -18), at + Vector2(-26, -6)], tint)
			_poly(ci, [at + Vector2(-26, -2), at + Vector2(24, -12), at + Vector2(24, -9), at + Vector2(-26, 1)], tint.lightened(.45))
			_poly(ci, [at + Vector2(-26, -6), at + Vector2(24, -18), at + Vector2(24, -24), at + Vector2(-26, -11)], tint.darkened(.25))
			ci.draw_circle(at + Vector2(16, -24), 3.5, Color("c8202a"))
		"brownie":
			_round_rect(ci, Rect2(at + Vector2(-20, -18), Vector2(40, 24)), 3, Color("3e2214"))
			_round_rect(ci, Rect2(at + Vector2(-20, -18), Vector2(40, 7)), 3, Color("5a3420"))
			_line(ci, at + Vector2(-10, -14), at + Vector2(-2, -12), Color("2a160c"), 1.5)
			_line(ci, at + Vector2(4, -15), at + Vector2(12, -13), Color("2a160c"), 1.5)
		"yogurt":
			_poly(ci, _ellipse_points(at + Vector2(0, 4), 31, 22, 0.0, PI), Color("f6eef2"))
			_ellipse(ci, at + Vector2(0, 4), 31, 7, Color("fbf4f7"))
		"berries":
			for p in [Vector2(-12, 0), Vector2(-2, -4), Vector2(9, 0), Vector2(16, 3), Vector2(3, 4)]:
				ci.draw_circle(at + p, 3.8, Color("c8203a") if int(p.x) % 2 == 0 else Color("6a3a9a"))
		"candies":
			for i in 3:
				var c := at + Vector2(-16 + i * 16, -4 + (i % 2) * 4)
				var tint: Color = [Color("e05a9a"), Color("4aa0e0"), Color("f0b030")][i]
				_poly(ci, [c + Vector2(-6, 0), c + Vector2(-12, -5), c + Vector2(-12, 5)], tint.darkened(.15))
				_poly(ci, [c + Vector2(6, 0), c + Vector2(12, -5), c + Vector2(12, 5)], tint.darkened(.15))
				ci.draw_circle(c, 6.5, tint)
				ci.draw_circle(c + Vector2(-2, -2), 2.0, tint.lightened(.5))
		"fruit_bits":
			var tints := [Color("d8352a"), Color("f5a524"), Color("5fa83e"), Color("6a3a9a"), Color("f2d23a"), Color("e05a9a")]
			for i in 9:
				var p := Vector2(-22 + (i % 5) * 11, -4 + int(i / 5) * 6 - (i % 2) * 3)
				ci.draw_circle(at + p, 5.0, tints[i % tints.size()])
		"tiramisu":
			var r := Rect2(at + Vector2(-20, -22), Vector2(40, 28))
			for k in 4:
				var y := r.position.y + k * 7
				_poly(ci, [Vector2(r.position.x, y), Vector2(r.end.x, y), Vector2(r.end.x, y + 7), Vector2(r.position.x, y + 7)], Color("f4ead2") if k % 2 == 0 else Color("a8743e"))
			_poly(ci, [r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + 3), Vector2(r.position.x, r.position.y + 3)], Color("5a3420"))
		"flan":
			_poly(ci, [at + Vector2(-24, 6), at + Vector2(24, 6), at + Vector2(17, -18), at + Vector2(-17, -18)], Color("f2c860"))
			_ellipse(ci, at + Vector2(0, -18), 17, 4.5, Color("a8541e"))
			_line(ci, at + Vector2(-17, -16), at + Vector2(-20, -6), Color("a8541e"), 3.0)
			_line(ci, at + Vector2(12, -16), at + Vector2(14, -8), Color("a8541e"), 3.0)
		"pie_slice":
			_poly(ci, [at + Vector2(-26, 6), at + Vector2(26, 6), at + Vector2(-4, -20)], Color("d9a35a"))
			_poly(ci, [at + Vector2(-22, 4), at + Vector2(22, 4), at + Vector2(-4, -15)], Color("e8c060"))
			for k in 3:
				_line(ci, at + Vector2(-16 + k * 12, 4), at + Vector2(-8 + k * 6, -10), Color("c08a40"), 2.5)
			_line(ci, at + Vector2(-26, 6), at + Vector2(26, 6), Color("b5803e"), 4.0)
		"cookies":
			for i in 3:
				var c := at + Vector2(-16 + i * 16, -3 + (i % 2) * 4)
				ci.draw_circle(c, 11.0, Color("c88a4a"))
				ci.draw_circle(c, 9.0, Color("d9a35a"))
				for p in [Vector2(-4, -3), Vector2(3, -4), Vector2(0, 3), Vector2(5, 2)]:
					ci.draw_circle(c + p, 1.6, Color("4a2a18"))
		"ice":
			for p in [Vector2(-10, 12), Vector2(6, 9), Vector2(-2, 22)]:
				_round_rect(ci, Rect2(at + p - Vector2(6, 6), Vector2(12, 12)), 2.5, Color(.93, .97, 1.0, .85))
				_line(ci, at + p + Vector2(-3, -3), at + p + Vector2(1, -3), Color(1, 1, 1, .9), 1.5)
		"lemon_rim":
			ci.draw_circle(Vector2(68, 16), 10.0, Color("e6c021"))
			ci.draw_circle(Vector2(68, 16), 8.0, Color("fbe58a"))
			for k in 6:
				_line(ci, Vector2(68, 16), Vector2(68, 16) + Vector2(cos(k * PI / 3), sin(k * PI / 3)) * 7, Color("e6c021"), 1.0)
		"orange_rim":
			ci.draw_circle(Vector2(68, 16), 10.0, Color("ef8a2a"))
			ci.draw_circle(Vector2(68, 16), 8.0, Color("fbc070"))
			for k in 6:
				_line(ci, Vector2(68, 16), Vector2(68, 16) + Vector2(cos(k * PI / 3), sin(k * PI / 3)) * 7, Color("ef8a2a"), 1.0)
		"straw":
			_line(ci, Vector2(54, 40), Vector2(62, 2), Color("e04a4a"), 4.0)
			for k in 3:
				var t := (k + .5) / 3.0
				_line(ci, Vector2(54, 40).lerp(Vector2(62, 2), t - .06), Vector2(54, 40).lerp(Vector2(62, 2), t + .04), WHITE, 4.2)
		"bubbles":
			for p in [Vector2(-10, 30), Vector2(4, 22), Vector2(10, 40), Vector2(-4, 46), Vector2(8, 56), Vector2(-8, 60)]:
				ci.draw_arc(at + p, 2.6, 0, TAU, 12, Color(1, 1, 1, .9), 1.4, true)
		"whipped":
			var c := at + Vector2(0, 0)
			for p in [Vector2(-12, 0), Vector2(12, 0), Vector2(0, -2), Vector2(-6, -10), Vector2(6, -10), Vector2(0, -18)]:
				ci.draw_circle(c + p, 8.0, Color("fbf6ee"))
			ci.draw_arc(c + Vector2(0, -6), 9, PI * 1.1, PI * 1.9, 16, Color("e0d8c8"), 1.5, true)
		"strawberry_top":
			var c := at + Vector2(4, -22)
			_poly(ci, [c + Vector2(-6, -2), c + Vector2(6, -2), c + Vector2(0, 9)], Color("d8253a"))
			ci.draw_circle(c + Vector2(-3, -2), 3.2, Color("d8253a"))
			ci.draw_circle(c + Vector2(3, -2), 3.2, Color("d8253a"))
			_poly(ci, [c + Vector2(-4, -5), c + Vector2(4, -5), c + Vector2(0, -2)], Color("3f8a2a"))
		"tea_tag":
			ci.draw_polyline(PackedVector2Array([Vector2(60, 46), Vector2(70, 30), Vector2(80, 50)]), Color("8a7a60"), 1.2, true)
			_round_rect(ci, Rect2(76, 50, 10, 12), 1.5, Color("f2e2a0"))

# --- Property icons -----------------------------------------------------------------------

## A property's icon in `rect`. `faded` greys it (the dish has none of it).
static func draw_property(ci: CanvasItem, id: String, rect: Rect2, faded := false, background := Color.TRANSPARENT) -> void:
	_begin(ci, rect)
	_icon(ci, id)
	_end(ci)
	if faded:
		var veil := background if background.a > 0.0 else Color("fbf5e6")
		ci.draw_rect(rect, Color(veil, .72))

static func _icon(ci: CanvasItem, id: String) -> void:
	match id:
		"sweet":
			_poly(ci, [Vector2(30, 50), Vector2(10, 34), Vector2(12, 66)], Color("c8407e"))
			_poly(ci, [Vector2(70, 50), Vector2(90, 34), Vector2(88, 66)], Color("c8407e"))
			ci.draw_circle(Vector2(50, 50), 23, Color("e05a9a"))
			ci.draw_arc(Vector2(50, 50), 13, 0, PI * 1.5, 24, Color("fbd0e4"), 4.0, true)
			ci.draw_circle(Vector2(42, 41), 4, Color("fbd0e4"))
		"salty":
			_round_rect(ci, Rect2(32, 36, 36, 54), 8, Color("eef1f4"))
			_poly(ci, [Vector2(32, 44), Vector2(68, 44), Vector2(68, 82), Vector2(32, 82)], Color("e2e7ec"))
			_round_rect(ci, Rect2(30, 18, 40, 22), 9, Color("8f9bab"))
			for p in [Vector2(42, 26), Vector2(50, 24), Vector2(58, 26), Vector2(46, 32), Vector2(54, 32)]:
				ci.draw_circle(p, 1.8, Color("3b4652"))
			for p in [Vector2(20, 12), Vector2(80, 10), Vector2(76, 22), Vector2(24, 24)]:
				_poly(ci, [p, p + Vector2(3, 0), p + Vector2(3, 3), p + Vector2(0, 3)], Color("b8c4d0"))
		"sour":
			_ellipse(ci, Vector2(50, 52), 34, 24, Color("e6c021"), -.25)
			_poly(ci, [Vector2(14, 62), Vector2(20, 54), Vector2(22, 64)], Color("e6c021"))
			_poly(ci, [Vector2(86, 42), Vector2(78, 40), Vector2(80, 50)], Color("e6c021"))
			_ellipse(ci, Vector2(40, 44), 10, 5, Color("fbe58a"), -.25)
			_ellipse(ci, Vector2(64, 26), 9, 4, Color("5fa83e"), -.6)
		"bitter":
			_ellipse(ci, Vector2(50, 50), 24, 34, Color("6b3b22"), .5)
			_ellipse(ci, Vector2(46, 44), 9, 16, Color("8a5434"), .5)
			var points := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				points.append(Vector2(50, 50) + Vector2(sin(t * TAU) * 5, lerpf(-26, 26, t)).rotated(.5))
			ci.draw_polyline(points, Color("3a1e10"), 3.5, true)
		"spicy":
			var points := PackedVector2Array()
			for i in 16:
				var t := i / 15.0
				points.append(Vector2(30 + t * 46, 30 + sin(t * PI * .9) * 40 + t * 8))
			ci.draw_polyline(points, Color("d8352a"), 16.0, true)
			ci.draw_circle(points[0], 8.0, Color("d8352a"))
			ci.draw_circle(points[points.size() - 1], 3.0, Color("d8352a"))
			ci.draw_circle(Vector2(36, 30), 3.0, Color("f08070"))
			_line(ci, Vector2(26, 26), Vector2(18, 14), Color("3f8a2a"), 5.0)
			_ellipse(ci, Vector2(28, 26), 7, 5, Color("3f8a2a"))
		"cold":
			var blue := Color("4a90d9")
			for k in 3:
				var dir := Vector2.from_angle(k * PI / 3.0 + PI / 2)
				_line(ci, Vector2(50, 50) - dir * 34, Vector2(50, 50) + dir * 34, blue, 6.0)
				for s in [-1.0, 1.0]:
					var tip: Vector2 = Vector2(50, 50) + dir * 22 * s
					_line(ci, tip, tip + (dir * s).rotated(.8) * 11, blue, 4.0)
					_line(ci, tip, tip + (dir * s).rotated(-.8) * 11, blue, 4.0)
			ci.draw_circle(Vector2(50, 50), 6, blue)
		"warm":
			_round_rect(ci, Rect2(24, 46, 40, 40), 6, Color("f0a040"))
			_arc(ci, Vector2(66, 64), 10, -PI / 2, PI / 2, Color("f0a040"), 5.0)
			_ellipse(ci, Vector2(44, 47), 20, 4, Color("c97a20"))
			for x in [36.0, 52.0]:
				_wave(ci, x, 12, 38, Color("f0a040"), 4.0)
		"hot":
			_poly(ci, [Vector2(50, 6), Vector2(66, 30), Vector2(76, 56), Vector2(70, 80), Vector2(50, 92), Vector2(30, 80), Vector2(24, 56), Vector2(36, 40), Vector2(40, 54), Vector2(46, 26)], Color("e0442c"))
			_poly(ci, [Vector2(52, 40), Vector2(62, 58), Vector2(62, 76), Vector2(50, 86), Vector2(38, 76), Vector2(40, 62), Vector2(48, 68)], Color("f6b03a"))
		"crunchy":
			_poly(ci, [Vector2(14, 22), Vector2(56, 18), Vector2(48, 50), Vector2(58, 84), Vector2(16, 82)], Color("e8b45a"))
			_poly(ci, [Vector2(64, 18), Vector2(86, 22), Vector2(86, 82), Vector2(68, 84), Vector2(58, 50)], Color("e8b45a"))
			for p in [Vector2(26, 34), Vector2(38, 34), Vector2(26, 52), Vector2(36, 66), Vector2(24, 70), Vector2(74, 34), Vector2(76, 52), Vector2(74, 70)]:
				ci.draw_circle(p, 2.5, Color("b5803e"))
			for p in [Vector2(56, 92), Vector2(62, 95), Vector2(50, 96)]:
				ci.draw_circle(p, 2.2, Color("e8b45a"))
		"creamy":
			var cream := Color("f4ead2")
			_ellipse(ci, Vector2(50, 80), 34, 10, cream.darkened(.08))
			_ellipse(ci, Vector2(50, 74), 32, 11, cream)
			_ellipse(ci, Vector2(50, 58), 24, 10, cream.darkened(.04))
			_ellipse(ci, Vector2(50, 44), 16, 8, cream)
			_poly(ci, [Vector2(42, 40), Vector2(58, 40), Vector2(52, 20)], cream)
			ci.draw_arc(Vector2(50, 66), 22, PI * 1.05, PI * 1.95, 20, Color("d8c8a0"), 2.0, true)
			ci.draw_arc(Vector2(50, 50), 14, PI * 1.05, PI * 1.95, 20, Color("d8c8a0"), 2.0, true)
		"juicy":
			_poly(ci, _ellipse_points(Vector2(44, 56), 30, 30, PI * .5, PI * 1.5), Color("ef8a2a"))
			_poly(ci, _ellipse_points(Vector2(46, 56), 25, 25, PI * .5, PI * 1.5), Color("fbc070"))
			for k in 4:
				var a := PI * .5 + (k + 1) * PI / 5
				_line(ci, Vector2(46, 56), Vector2(46, 56) + Vector2.from_angle(a) * 22, Color("ef8a2a"), 1.5)
			for p in [Vector2(66, 34), Vector2(78, 54), Vector2(68, 72)]:
				_poly(ci, [p + Vector2(0, -10), p + Vector2(5, 0), p + Vector2(-5, 0)], Color("4aa0e0"))
				ci.draw_circle(p + Vector2(0, 1), 5, Color("4aa0e0"))
		"dry":
			ci.draw_circle(Vector2(76, 22), 12, Color("f2b830"))
			_round_rect(ci, Rect2(10, 46, 80, 42), 6, Color("c8955a"))
			for path in [[Vector2(20, 52), Vector2(32, 64), Vector2(28, 80)], [Vector2(32, 64), Vector2(48, 60), Vector2(58, 74), Vector2(56, 86)], [Vector2(48, 60), Vector2(60, 50)], [Vector2(58, 74), Vector2(78, 68), Vector2(84, 80)]]:
				ci.draw_polyline(PackedVector2Array(path), Color("7a4a22"), 3.0, true)
		"hard":
			_poly(ci, [Vector2(16, 70), Vector2(24, 38), Vector2(46, 22), Vector2(72, 28), Vector2(86, 52), Vector2(80, 80), Vector2(50, 88), Vector2(24, 84)], Color("8a8f96"))
			_poly(ci, [Vector2(28, 44), Vector2(46, 30), Vector2(62, 34), Vector2(48, 46)], Color("b4b9c0"))
			ci.draw_polyline(PackedVector2Array([Vector2(56, 52), Vector2(66, 64), Vector2(62, 78)]), Color("5a5f66"), 2.5, true)
		"soft":
			var puff := Color("fbeef2")
			for p in [Vector2(30, 58), Vector2(46, 46), Vector2(64, 48), Vector2(76, 60), Vector2(52, 62)]:
				ci.draw_circle(p, 18, Color("e8c8d4"))
			for p in [Vector2(30, 56), Vector2(46, 44), Vector2(64, 46), Vector2(76, 58), Vector2(52, 60)]:
				ci.draw_circle(p, 16, puff)
			_round_rect(ci, Rect2(14, 58, 72, 18), 9, puff)
		"refreshing":
			_ellipse(ci, Vector2(40, 58), 16, 28, Color("4fb06a"), .6)
			_line(ci, Vector2(24, 78), Vector2(52, 40), Color("2f8a4a"), 2.5)
			for y in [24.0, 40.0, 56.0]:
				var points := PackedVector2Array()
				for i in 10:
					var t := i / 9.0
					points.append(Vector2(56 + t * 34, y + sin(t * TAU) * 4))
				ci.draw_polyline(points, Color("6fc0e8"), 4.0, true)
		"fizzy":
			for c in [[Vector2(36, 76), 10.0], [Vector2(62, 66), 8.0], [Vector2(44, 48), 7.0], [Vector2(66, 36), 6.0], [Vector2(42, 22), 5.0], [Vector2(60, 12), 4.0], [Vector2(28, 40), 4.0]]:
				ci.draw_circle(c[0], c[1], Color(.55, .8, .95, .35))
				ci.draw_arc(c[0], c[1], 0, TAU, 20, Color("3a8ad0"), 2.5, true)
				ci.draw_circle(c[0] + Vector2(-c[1] * .35, -c[1] * .35), c[1] * .25, Color.WHITE)
		"fresh":
			_ellipse(ci, Vector2(46, 58), 20, 34, Color("4fb06a"), .7)
			_line(ci, Vector2(22, 84), Vector2(66, 34), Color("2f8a4a"), 3.0)
			for k in 3:
				var base := Vector2(30, 74).lerp(Vector2(60, 40), k / 3.0 + .15)
				_line(ci, base, base + Vector2(-10, -4).rotated(.2), Color("2f8a4a"), 1.8)
			_star(ci, Vector2(76, 22), 13, Color("f2c230"))
			_star(ci, Vector2(84, 46), 7, Color("f2c230"))
		"with_ice":
			for c in [Vector2(36, 58), Vector2(62, 42)]:
				_round_rect(ci, Rect2(c - Vector2(20, 20), Vector2(40, 40)), 7, Color("a8d8f0"))
				_round_rect(ci, Rect2(c - Vector2(16, 16), Vector2(32, 32)), 5, Color("d8f0fb"))
				_line(ci, c + Vector2(-10, -10), c + Vector2(2, -10), Color.WHITE, 3.0)
		"chicken":
			ci.draw_circle(Vector2(50, 54), 30, Color("f8f6f0"))
			for p in [Vector2(40, 22), Vector2(50, 18), Vector2(60, 22)]:
				ci.draw_circle(p, 8, Color("e0302a"))
			_poly(ci, [Vector2(76, 50), Vector2(94, 58), Vector2(76, 64)], Color("f2b030"))
			_ellipse(ci, Vector2(72, 72), 5, 8, Color("e0302a"))
			ci.draw_circle(Vector2(62, 46), 4, INK)
			ci.draw_circle(Vector2(63, 45), 1.4, Color.WHITE)
		"fish":
			_ellipse(ci, Vector2(44, 50), 32, 18, Color("5a9ad0"))
			_poly(ci, [Vector2(70, 50), Vector2(92, 32), Vector2(92, 68)], Color("3a7ab0"))
			_ellipse(ci, Vector2(44, 56), 24, 7, Color("a8d0ec"))
			ci.draw_circle(Vector2(24, 44), 4, Color.WHITE)
			ci.draw_circle(Vector2(24, 44), 2, INK)
			_arc(ci, Vector2(36, 50), 12, -PI * .35, PI * .35, Color("3a7ab0"), 2.0)
		"beef":
			_poly(ci, [Vector2(18, 30), Vector2(6, 18), Vector2(20, 22)], Color("e8dcc8"))
			_poly(ci, [Vector2(82, 30), Vector2(94, 18), Vector2(80, 22)], Color("e8dcc8"))
			_ellipse(ci, Vector2(14, 38), 9, 5, Color("2b2b2b"), -.4)
			_ellipse(ci, Vector2(86, 38), 9, 5, Color("2b2b2b"), .4)
			_ellipse(ci, Vector2(50, 50), 30, 34, Color("f8f6f0"))
			_ellipse(ci, Vector2(38, 36), 12, 10, Color("2b2b2b"))
			_ellipse(ci, Vector2(50, 72), 24, 14, Color("f2b0b8"))
			ci.draw_circle(Vector2(42, 72), 3, Color("b06070"))
			ci.draw_circle(Vector2(58, 72), 3, Color("b06070"))
			ci.draw_circle(Vector2(38, 46), 3.5, INK)
			ci.draw_circle(Vector2(62, 46), 3.5, INK)
		"pork":
			_poly(ci, [Vector2(22, 36), Vector2(18, 10), Vector2(42, 24)], Color("e88aa0"))
			_poly(ci, [Vector2(78, 36), Vector2(82, 10), Vector2(58, 24)], Color("e88aa0"))
			ci.draw_circle(Vector2(50, 54), 34, Color("f4a8b8"))
			_ellipse(ci, Vector2(50, 64), 16, 11, Color("e88aa0"))
			_ellipse(ci, Vector2(44, 64), 3, 4.5, Color("a84a60"))
			_ellipse(ci, Vector2(56, 64), 3, 4.5, Color("a84a60"))
			ci.draw_circle(Vector2(36, 44), 3.5, INK)
			ci.draw_circle(Vector2(64, 44), 3.5, INK)
		"lamb":
			for k in 10:
				ci.draw_circle(Vector2(50, 48) + Vector2.from_angle(k * TAU / 10.0) * 30, 13, Color("f4f0e6"))
			ci.draw_circle(Vector2(50, 48), 30, Color("f4f0e6"))
			_ellipse(ci, Vector2(22, 52), 10, 5, Color("4a3a32"), .5)
			_ellipse(ci, Vector2(78, 52), 10, 5, Color("4a3a32"), -.5)
			_ellipse(ci, Vector2(50, 58), 18, 24, Color("4a3a32"))
			ci.draw_circle(Vector2(42, 52), 3, Color.WHITE)
			ci.draw_circle(Vector2(58, 52), 3, Color.WHITE)
			_ellipse(ci, Vector2(50, 72), 5, 3, Color("2a1e1a"))
		"shrimp":
			_arc(ci, Vector2(50, 46), 26, PI * .05, PI * 1.25, Color("f08a5d"), 16.0)
			for k in 4:
				var a := PI * .25 + k * PI * .25
				_line(ci, Vector2(50, 46) + Vector2.from_angle(a) * 18, Vector2(50, 46) + Vector2.from_angle(a) * 34, Color("e0603a"), 2.0)
			_poly(ci, [Vector2(74, 52), Vector2(92, 40), Vector2(90, 66)], Color("e0603a"))
			ci.draw_circle(Vector2(36, 26), 3, INK)
			_line(ci, Vector2(28, 26), Vector2(8, 12), Color("e0603a"), 1.5)
		"vegetables":
			_poly(ci, [Vector2(14, 30), Vector2(30, 20), Vector2(58, 88)], Color("ef8a2a"))
			for d in [Vector2(-8, -12), Vector2(0, -16), Vector2(8, -12)]:
				_line(ci, Vector2(22, 24), Vector2(22, 24) + d, Color("4fb06a"), 4.0)
			_line(ci, Vector2(70, 88), Vector2(70, 58), Color("8fc070"), 9.0)
			for p in [Vector2(58, 48), Vector2(72, 40), Vector2(84, 50), Vector2(70, 54), Vector2(64, 36), Vector2(80, 34)]:
				ci.draw_circle(p, 10, Color("3f8a2a"))
		"fruit":
			ci.draw_circle(Vector2(40, 60), 26, Color("d8352a"))
			ci.draw_circle(Vector2(32, 52), 6, Color("f08070"))
			_line(ci, Vector2(42, 36), Vector2(46, 22), Color("6a4a2a"), 3.5)
			_ellipse(ci, Vector2(56, 24), 10, 5, Color("4fb06a"), -.4)
			for p in [Vector2(76, 70), Vector2(86, 76)]:
				ci.draw_circle(p, 8, Color("b0203a"))
			ci.draw_polyline(PackedVector2Array([Vector2(76, 62), Vector2(80, 44), Vector2(86, 68)]), Color("3f8a2a"), 2.0, true)
		"cheese":
			_poly(ci, [Vector2(10, 74), Vector2(90, 74), Vector2(90, 46), Vector2(30, 28)], Color("f5c93a"))
			_poly(ci, [Vector2(10, 74), Vector2(90, 74), Vector2(90, 82), Vector2(10, 82)], Color("e0a828"))
			for c in [[Vector2(46, 56), 6.0], [Vector2(70, 62), 5.0], [Vector2(34, 66), 4.0], [Vector2(74, 48), 3.0]]:
				ci.draw_circle(c[0], c[1], Color("e0a828"))
		"chocolate":
			_round_rect(ci, Rect2(18, 14, 64, 74), 6, Color("4a2a18"))
			for row in 3:
				for col in 2:
					_round_rect(ci, Rect2(24 + col * 28, 20 + row * 22, 24, 18), 3, Color("6b3b22"))
			_poly(ci, [Vector2(18, 70), Vector2(82, 54), Vector2(82, 88), Vector2(18, 88)], Color("c8c8d0"))

# --- Intensity, temperature, marks -------------------------------------------------------

## Three pill-shaped bars side by side in `rect` (11 Nov 2026 restyle: a taste row is its icon
## then these bars), `level` of them filled with `color` with a soft highlight; the rest are
## light grey tracks (0: three grey bars).
static func bars(ci: CanvasItem, level: int, color: Color, rect: Rect2) -> void:
	var gap := rect.size.x * .06
	var width := (rect.size.x - gap * 2) / 3.0
	var height := rect.size.y
	var edge := maxf(1.5, height * .12)
	for i in 3:
		var bar := Rect2(rect.position + Vector2(i * (width + gap), 0), Vector2(width, height))
		if i < level:
			_round_rect(ci, bar, height * .5, color.darkened(.18))
			_round_rect(ci, bar.grow(-edge), height * .5, color)
			_round_rect(ci, Rect2(bar.position + Vector2(height * .35, height * .2), Vector2(maxf(width - height * .7, 1.0), height * .2)), height * .1, Color(1, 1, 1, .4))
		else:
			_round_rect(ci, bar, height * .5, BAR_EMPTY)
			_round_rect(ci, bar.grow(-edge), height * .5, BAR_EMPTY.lightened(.45))

## A cold-to-hot strip: five segments (frozen, cold, room, warm, hot) with the dish's level
## raised and marked, a snowflake at the cold end and a flame at the hot end.
static func thermometer(ci: CanvasItem, level: int, colors: Array, rect: Rect2) -> void:
	var icon := rect.size.y
	draw_property(ci, "cold", Rect2(rect.position, Vector2(icon, icon)))
	draw_property(ci, "hot", Rect2(Vector2(rect.end.x - icon, rect.position.y), Vector2(icon, icon)))
	var strip := Rect2(rect.position + Vector2(icon * 1.15, rect.size.y * .3), Vector2(rect.size.x - icon * 2.3, rect.size.y * .4))
	var width := strip.size.x / 5.0
	for i in 5:
		var cell := Rect2(strip.position + Vector2(i * width + 1, 0), Vector2(width - 2, strip.size.y))
		var tint := Color(str(colors[i])) if i < colors.size() else Color.GRAY
		if i == level:
			cell = cell.grow(rect.size.y * .22)
			_round_rect(ci, cell.grow(2), 6, INK)
			_round_rect(ci, cell, 5, tint)
		else:
			_round_rect(ci, cell, 4, Color(tint, .45))

## The "not" mark over an icon: a red circle with a slash.
static func crossed(ci: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * .46
	ci.draw_arc(c, r, 0, TAU, 32, Color("d0303a"), r * .14, true)
	ci.draw_line(c + Vector2(-r, r).rotated(0) * .7, c + Vector2(r, -r) * .7, Color("d0303a"), r * .14, true)

## The missed requirement: a thick red ring around its icon.
static func ring(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_arc(rect.get_center(), maxf(rect.size.x, rect.size.y) * .62, 0, TAU, 40, Color("d0303a"), maxf(3.0, rect.size.x * .08), true)

# --- Controls and poster sheets ----------------------------------------------------------

## A Control that draws one dish (`art`) or one property icon (`property`).
class View extends Control:
	var art: Dictionary = {}
	var property := ""
	var faded := false
	var crossed_out := false
	var ringed := false
	var background := Color.TRANSPARENT

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var box := Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))
		var FoodIcons = load("res://scripts/ui/food_icons.gd")
		if not art.is_empty():
			FoodIcons.draw_dish(self, art, box)
		elif property != "":
			FoodIcons.draw_property(self, property, box, faded, background)
			if crossed_out:
				FoodIcons.crossed(self, box)
		if ringed:
			FoodIcons.ring(self, box)

## One texture holding every cell of a poster, drawn once in a SubViewport under `parent`.
## Returns {"texture", "cell", "columns"}; region(i) of it is cell i (Sprite3D.region_rect).
static func sheet(parent: Node, cells: Array, cell := 128) -> Dictionary:
	var columns := mini(8, maxi(1, cells.size()))
	var rows := ceili(cells.size() / float(columns))
	var view := SubViewport.new()
	view.name = "Icon sheet"
	view.size = Vector2i(columns * cell, rows * cell)
	view.transparent_bg = false
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var drawing: Control = preload("res://scripts/ui/food_icon_sheet.gd").new()
	drawing.cells = cells
	drawing.cell = cell
	drawing.columns = columns
	drawing.size = Vector2(view.size)
	view.add_child(drawing)
	parent.add_child(view)
	return {"texture": view.get_texture(), "cell": cell, "columns": columns}

static func region(sheet_info: Dictionary, index: int) -> Rect2:
	var cell: int = sheet_info.cell
	var columns: int = sheet_info.columns
	return Rect2((index % columns) * cell, int(index / columns) * cell, cell, cell)
