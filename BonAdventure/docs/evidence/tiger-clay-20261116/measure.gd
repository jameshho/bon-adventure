extends SceneTree
## Measures the user's sheet (reference.png) for tiger_clay.gd: prints, row by row and column by
## column, where each figure's outline lies, and saves enlarged crops of the head views with a
## 10 px grid (blue every 50 px) into the folder given as the argument.
##   godot --headless --path . --script res://docs/evidence/tiger-clay-20261116/measure.gd -- <folder>
const REF := "res://docs/evidence/tiger-clay-20261116/reference.png"
var img: Image
var out := ""

func fig(x: int, y: int) -> bool:
	var c := img.get_pixel(x, y)
	return c.s > 0.2 or c.v < 0.75

func brown(x: int, y: int) -> bool:
	var c := img.get_pixel(x, y)
	return c.v < 0.62 and c.s > 0.4

func cream(x: int, y: int) -> bool:
	var c := img.get_pixel(x, y)
	return c.s > 0.2 and c.s < 0.48 and c.v > 0.85 and c.h < 0.12 and c.h > 0.05

func grid(r: Rect2i, k: int, file: String) -> void:
	var crop := img.get_region(r)
	crop.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_CUBIC)
	for x in range(r.position.x - r.position.x % 10 + 10, r.end.x, 10):
		var strong := x % 50 == 0
		for py in crop.get_height():
			var px := (x - r.position.x) * k
			crop.set_pixel(px, py, crop.get_pixel(px, py).lerp(Color(0, 0.2, 1) if strong else Color(0, 0, 0), 0.55 if strong else 0.22))
	for y in range(r.position.y - r.position.y % 10 + 10, r.end.y, 10):
		var strong := y % 50 == 0
		for px in crop.get_width():
			var py := (y - r.position.y) * k
			crop.set_pixel(px, py, crop.get_pixel(px, py).lerp(Color(0, 0.2, 1) if strong else Color(0, 0, 0), 0.55 if strong else 0.22))
	crop.save_png(out + file)

func rows(name: String, x0: int, x1: int, y0: int, y1: int, step: int) -> void:
	print("== ", name, ": y | fig left right | non-brown left right")
	for y in range(y0, y1 + 1, step):
		var l := -1; var r := -1; var nl := -1; var nr := -1
		for x in range(x0, x1):
			if fig(x, y):
				if l < 0: l = x
				r = x
				if not brown(x, y):
					if nl < 0: nl = x
					nr = x
		print(y, " | ", l, " ", r, " | ", nl, " ", nr)

func cols(name: String, x0: int, x1: int, y0: int, y1: int, step: int) -> void:
	print("== ", name, ": x | top y | first non-brown y")
	for x in range(x0, x1 + 1, step):
		var t := -1; var nt := -1
		for y in range(y0, y1):
			if fig(x, y):
				if t < 0: t = y
				if not brown(x, y) and nt < 0: nt = y
		print(x, " | ", t, " | ", nt)

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0] + "/"
	img = Image.load_from_file(ProjectSettings.globalize_path(REF))
	img.convert(Image.FORMAT_RGBA8)
	grid(Rect2i(385, 200, 240, 190), 6, "g_front.png")
	grid(Rect2i(675, 195, 210, 190), 6, "g_side.png")
	grid(Rect2i(20, 200, 240, 190), 6, "g_q.png")
	grid(Rect2i(1235, 195, 230, 190), 6, "g_back.png")
	grid(Rect2i(1740, 200, 240, 190), 6, "g_rear.png")
	rows("front head", 385, 625, 205, 385, 5)
	rows("side head (left edge = face profile)", 675, 900, 205, 385, 5)
	cols("side head top", 690, 900, 195, 300, 10)
	rows("back", 1235, 1470, 205, 525, 10)
	rows("front whole", 385, 625, 385, 525, 10)
	rows("side whole", 675, 1200, 205, 525, 10)
	cols("side top", 700, 1190, 195, 400, 20)
	quit()
