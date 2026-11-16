extends RefCounted
## Country flags painted in code (6 Nov 2026; no image assets): simplified but recognisable
## at row and poster-card size. Keys are the country word keys of data/flight_game.json.
## Used by the flight panel rows (flight_panel.gd) and the airport countries poster
## (saved in the airport unit). Each flag is painted once, 2×2 supersampled, and cached.
## Drawing space: x 0..1.5, y 0..1 (3:2, y down), so circles stay round.
const W := 72
const H := 48
const SAMPLES := 2
const KEYS := ["mexico", "united states", "canada", "spain", "france", "germany", "italy",
	"brazil", "japan", "china", "south korea", "australia"]
const EDGE := Color("39424a")
static var _cache: Dictionary = {}

static func has_flag(key: String) -> bool:
	return KEYS.has(key)

static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if not KEYS.has(key):
		return null
	var shapes := _shapes(key)
	var image := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var sum := Color(0, 0, 0, 0)
			for sy in SAMPLES:
				for sx in SAMPLES:
					var p := Vector2((x + (sx + .5) / SAMPLES) / W * 1.5, (y + (sy + .5) / SAMPLES) / H)
					sum += _color(key, p, shapes)
			var c := sum / float(SAMPLES * SAMPLES)
			# A thin dark edge so white flags (Japan, South Korea) read on a cream page.
			if x == 0 or y == 0 or x == W - 1 or y == H - 1:
				c = c.lerp(EDGE, .55)
			c.a = 1.0
			image.set_pixel(x, y, c)
	image.generate_mipmaps()
	var made := ImageTexture.create_from_image(image)
	_cache[key] = made
	return made

## A star polygon with `points` tips, outer radius r, centred at c.
static func _star(c: Vector2, r: float, points: int = 5, inner: float = .4) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in points * 2:
		var radius := r if i % 2 == 0 else r * inner
		var angle := -PI / 2 + i * PI / points
		poly.append(c + Vector2(cos(angle), sin(angle)) * radius)
	return poly

## Polygons each flag needs, made once per painting.
static func _shapes(key: String) -> Array:
	match key:
		"canada":
			var leaf := [Vector2(0, -1), Vector2(.12, -.72), Vector2(.3, -.8), Vector2(.25, -.35), Vector2(.5, -.6),
				Vector2(.55, -.45), Vector2(.85, -.5), Vector2(.75, -.2), Vector2(.95, -.1), Vector2(.5, .25),
				Vector2(.55, .4), Vector2(.08, .33), Vector2(.08, .75), Vector2(-.08, .75), Vector2(-.08, .33),
				Vector2(-.55, .4), Vector2(-.5, .25), Vector2(-.95, -.1), Vector2(-.75, -.2), Vector2(-.85, -.5),
				Vector2(-.55, -.45), Vector2(-.5, -.6), Vector2(-.25, -.35), Vector2(-.3, -.8), Vector2(-.12, -.72)]
			var poly := PackedVector2Array()
			for point in leaf:
				poly.append(Vector2(.75, .5) + point * .3)
			return [poly]
		"china":
			return [_star(Vector2(.25, .25), .15), _star(Vector2(.5, .1), .05), _star(Vector2(.6, .2), .05),
				_star(Vector2(.6, .35), .05), _star(Vector2(.5, .45), .05)]
		"australia":
			return [_star(Vector2(.375, .75), .13, 7, .45), _star(Vector2(1.125, .82), .065, 7, .45),
				_star(Vector2(1.125, .2), .065, 7, .45), _star(Vector2(.9, .42), .065, 7, .45),
				_star(Vector2(1.34, .36), .065, 7, .45), _star(Vector2(1.22, .56), .035, 5, .4)]
	return []

static func _inside(p: Vector2, shapes: Array) -> bool:
	for poly in shapes:
		if Geometry2D.is_point_in_polygon(p, poly):
			return true
	return false

static func _color(key: String, p: Vector2, shapes: Array) -> Color:
	var x := p.x
	var y := p.y
	match key:
		"mexico":
			if Vector2(x, y).distance_to(Vector2(.75, .5)) < .11:
				return Color("8c5a2b")
			return Color("006847") if x < .5 else (Color.WHITE if x < 1.0 else Color("ce1126"))
		"united states":
			if x < .6 and y < 7.0 / 13.0:
				for row in 5:
					for column in 6:
						if p.distance_to(Vector2(.6 * (column + .5) / 6.0, 7.0 / 13.0 * (row + .5) / 5.0)) < .026:
							return Color.WHITE
				return Color("3c3b6e")
			return Color("b22234") if int(y * 13) % 2 == 0 else Color.WHITE
		"canada":
			if x < .375 or x > 1.125:
				return Color("d52b1e")
			return Color("d52b1e") if _inside(p, shapes) else Color.WHITE
		"spain":
			return Color("c60b1e") if y < .25 or y > .75 else Color("ffc400")
		"france":
			return Color("0055a4") if x < .5 else (Color.WHITE if x < 1.0 else Color("ef4135"))
		"germany":
			return Color("111111") if y < 1.0 / 3.0 else (Color("dd0000") if y < 2.0 / 3.0 else Color("ffce00"))
		"italy":
			return Color("009246") if x < .5 else (Color.WHITE if x < 1.0 else Color("ce2b37"))
		"brazil":
			var r := p.distance_to(Vector2(.75, .5))
			if r < .25:
				var band := p.distance_to(Vector2(.75, 1.25))
				return Color.WHITE if band > .78 and band < .83 else Color("002776")
			if absf(x - .75) / .66 + absf(y - .5) / .42 <= 1.0:
				return Color("ffdf00")
			return Color("009c3b")
		"japan":
			return Color("bc002d") if p.distance_to(Vector2(.75, .5)) < .3 else Color.WHITE
		"china":
			return Color("ffde00") if _inside(p, shapes) else Color("de2910")
		"south korea":
			return _korea(p)
		"australia":
			if _inside(p, shapes):
				return Color.WHITE
			if x < .75 and y < .5:
				return _union(Vector2(x, y))
			return Color("012169")
	return Color.MAGENTA

## Taegeuk (tilted, red over blue, with the two lobes) and the four trigrams.
static func _korea(p: Vector2) -> Color:
	var center := Vector2(.75, .5)
	var q := (p - center).rotated(-deg_to_rad(33.7))
	if q.length() < .25:
		if q.distance_to(Vector2(-.125, 0)) < .125:
			return Color("cd2e3a")
		if q.distance_to(Vector2(.125, 0)) < .125:
			return Color("0047a0")
		return Color("cd2e3a") if q.y < 0 else Color("0047a0")
	# Trigrams: [corner, which bars are broken] (geon, gam, ri, gon).
	for spec in [[Vector2(.32, .21), [false, false, false]], [Vector2(1.18, .21), [true, false, true]],
			[Vector2(.32, .79), [false, true, false]], [Vector2(1.18, .79), [true, true, true]]]:
		var corner: Vector2 = spec[0]
		var along_dir := (corner - center).normalized()
		var side_dir := Vector2(-along_dir.y, along_dir.x)
		var d := p - corner
		var along := d.dot(along_dir)
		var side := d.dot(side_dir)
		if absf(side) > .1 or absf(along) > .09:
			continue
		for bar in 3:
			var start := -.09 + bar * .065
			if along >= start and along <= start + .04:
				if spec[1][bar] and absf(side) < .016:
					return Color.WHITE
				return Color("111111")
	return Color.WHITE

## Union Jack in Australia's canton: q in 0..0.75 × 0..0.5.
static func _union(q: Vector2) -> Color:
	var norm := Vector2(.75, .5).length()
	var d1 := absf(q.y * .75 - q.x * .5) / norm
	var d2 := absf((.5 - q.y) * .75 - q.x * .5) / norm
	var cross := minf(absf(q.x - .375), absf(q.y - .25))
	if cross < .035:
		return Color("c8102e")
	if cross < .07:
		return Color.WHITE
	if minf(d1, d2) < .022:
		return Color("c8102e")
	if minf(d1, d2) < .06:
		return Color.WHITE
	return Color("012169")
