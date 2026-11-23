extends "res://scripts/buildings/electronics_products.gd"
## Café table meals (user, 23 Nov 2026: make the food on the café tables more appealing, game-style
## low-poly). One merged clay-style mesh per meal word (breakfast, lunch, dinner, food, coffee),
## drawn with the shared product kit (supermarket_products.gd parts, the electronics kit's rbox,
## GLOW and place()) and reusing the grocery models for fruit and vegetables (_apple, _tomato,
## _broccoli, _grapes). Used by bakery.gd step `table_meals`.
## Café units (the café is not scaled). A meal is drawn around its table's centre with its base on
## the table top (y = 0); the diner's chair is on the -X side, so the plate sits towards -X and the
## drink stands at the far +X corner.

const PLATE := "fbf6ea"
const MAT := "f6c7b8"     # coral-light placemat
const CRUST := "c98a45"
const BREAD := "f1cf8c"

func meal(word: String) -> ArrayMesh:
	begin()
	call("_meal_" + word)
	return finish("Cafe " + word)

## A round plate (diameter d) with a coral rim line, its base at c.
func _plate(c: Vector3, d: float) -> void:
	lathe(c, [Vector2(0, 0), Vector2(d * .3, 0), Vector2(d * .34, .008), Vector2(d * .5, .03),
		Vector2(d * .48, .036), Vector2(d * .36, .016), Vector2(0, .016)], PLATE, SATIN, 22)
	ring(c + Vector3(0, .029, 0), Vector3(d * .95, .006, d * .95), coral, SATIN, Vector3.ZERO, .94, 24)

func _mat(c: Vector3, s: Vector2) -> void:
	rbox(c + Vector3(0, .004, 0), Vector3(s.x, .008, s.y), MAT, MATTE, Vector3.ZERO, .03)
	rbox(c + Vector3(0, .0085, 0), Vector3(s.x - .05, .002, s.y - .05), lighter(MAT, .35), MATTE, Vector3.ZERO, .02)

## A glass of drink (a coloured body, a clear rim and foot), base at c.
func _glass(c: Vector3, drink: String, straw := "") -> void:
	cyl(c + Vector3(0, .006, 0), Vector3(.1, .012, .1), sky_light, SATIN, Vector3.ZERO, 14)
	lathe(c, [Vector2(0, .012), Vector2(.04, .012), Vector2(.047, .13), Vector2(0, .13)], drink, SATIN, 14)
	ring(c + Vector3(0, .135, 0), Vector3(.104, .012, .104), sky_light, SATIN, Vector3.ZERO, .86, 16)
	ball(c + Vector3(-.01, .07, -.035), Vector3(.012, .07, .01), lighter(drink, .45), SATIN, Vector3.ZERO, 6)
	if straw != "":
		cyl(c + Vector3(.018, .17, .01), Vector3(.012, .16, .012), straw, SATIN, Vector3(0, 0, -.25), 6)

## A grocery model drawn at the origin, placed at `at` turned by `yaw` and scaled by `grow`.
func _put(kind: String, variant: int, at: Vector3, yaw := 0.0, grow := 1.0) -> void:
	_mark_now()
	call("_" + kind, variant)
	for f in _materials.size():
		for k in range(_mark[f], _v[f].size()):
			_v[f][k] = _v[f][k] * grow
	place(Transform3D(Basis(Vector3.UP, yaw), at))

## A fried egg: a wobbly white and a glossy yolk.
func _egg(c: Vector3, yaw: float) -> void:
	ball(c + Vector3(0, .008, 0), Vector3(.15, .016, .12), "fffdf4", SATIN, Vector3(0, yaw, 0), 12)
	ball(c + Vector3(.03, .009, .02).rotated(Vector3.UP, yaw), Vector3(.1, .016, .09), "fffdf4", SATIN, Vector3(0, yaw, 0), 10)
	dome(c + Vector3(-.005, .026, 0), Vector3(.06, .03, .06), "f7b52c", SATIN, Vector3.ZERO, 12)
	ball(c + Vector3(-.015, .036, -.01), Vector3(.014, .006, .012), "fde7a8", SATIN, Vector3.ZERO, 6)

## A slice of toast lying at c (crust, crumb, a melting butter pat).
func _toast(c: Vector3, yaw: float, tilt := 0.0) -> void:
	var r := Vector3(tilt, yaw, 0)
	rbox(c, Vector3(.13, .022, .13), CRUST, MATTE, r, .02)
	rbox(c + Vector3(0, .0035, 0), Vector3(.108, .02, .108), "e9b467", MATTE, r, .016)

func _meal_breakfast() -> void:
	_mat(Vector3(-.1, 0, 0), Vector2(.66, .52))
	var p := Vector3(-.16, .008, 0)
	_plate(p, .44)
	_egg(p + Vector3(-.06, .016, -.06), .4)
	_egg(p + Vector3(-.05, .016, .07), -.3)
	_toast(p + Vector3(.08, .03, -.02), .25, .12)
	rbox(p + Vector3(.085, .05, -.02), Vector3(.035, .012, .03), "f7d36b", SATIN, Vector3(.12, .5, 0), .006)
	for k in 2:
		var pts := []
		for j in 6:
			pts.append(p + Vector3(-.02 + j * .03, .024 + sin(j * 1.7) * .006, .1 + k * .035))
		tube(pts, [.012, .015, .015, .015, .015, .012].map(func(v): return Vector2(v, .006)), "c8553d", SATIN, 6)
	_glass(Vector3(.2, .008, -.2), "f29a2e")
	cyl(Vector3(.235, .145, -.2), Vector3(.06, .01, .06), "f0a030", SATIN, Vector3(0, 0, PI / 2), 10)

## A sandwich half: a triangle of bread, lettuce, tomato and cheese lying flat (apex towards -Z
## before `yaw`), base at c.
func _sandwich(c: Vector3, yaw: float) -> void:
	var r := Vector3(-PI / 2, yaw, 0)
	var y := 0.0
	for layer in [[.17, .028, CRUST], [.19, .012, "79b84a"], [.165, .012, "e0402f"], [.175, .008, "f7c948"], [.17, .03, CRUST]]:
		var size: float = layer[0]
		var thick: float = layer[1]
		prism(c + Vector3(0, y + thick * .5, 0), Vector3(size, size, thick), layer[2], MATTE, r)
		if layer[2] == CRUST:
			prism(c + Vector3(0, y + thick * .5, 0), Vector3(size - .025, size - .025, thick + .004), BREAD, MATTE, r)
		y += thick

func _meal_lunch() -> void:
	_mat(Vector3(-.1, 0, 0), Vector2(.66, .52))
	var p := Vector3(-.16, .008, 0)
	_plate(p, .44)
	_sandwich(p + Vector3(-.03, .016, -.05), .3)
	_sandwich(p + Vector3(.02, .016, .06), PI + .5)
	for k in 5:
		var a := k * 1.25
		ball(p + Vector3(.1 + cos(a) * .035, .03, -.08 + sin(a) * .035), Vector3(.05, .012, .04), "f2c14e", MATTE, Vector3(.3 * (k % 2), a, .2), 8)
	ball(p + Vector3(-.12, .035, .08), Vector3(.1, .04, .08), "6fae3a", SATIN, Vector3(0, .5, 0), 8)
	ball(p + Vector3(-.11, .055, .1), Vector3(.04, .04, .04), "e0402f", SATIN, Vector3.ZERO, 8)
	_glass(Vector3(.2, .008, -.2), "f7e07a", coral)

func _meal_dinner() -> void:
	_mat(Vector3(-.1, 0, 0), Vector2(.66, .52))
	var p := Vector3(-.16, .008, 0)
	_plate(p, .46)
	# A steak with grill lines.
	rbox(p + Vector3(-.03, .035, -.06), Vector3(.18, .04, .12), "8a4a2e", SATIN, Vector3(0, .35, 0), .03)
	for k in 3:
		bx(p + Vector3(-.03 + (k - 1) * .045, .056, -.06), Vector3(.008, .004, .11), "5a2e1c", MATTE, Vector3(0, .35 + .6, 0))
	# Mashed potato with butter.
	dome(p + Vector3(.08, .05, .05), Vector3(.12, .07, .12), "f3e3b3", MATTE, Vector3.ZERO, 12)
	rbox(p + Vector3(.08, .088, .05), Vector3(.03, .014, .03), "f7d36b", SATIN, Vector3(0, .4, 0), .005)
	# Peas, carrots and a broccoli floret.
	for k in 7:
		ball(p + Vector3(-.09 + (k % 4) * .022, .026, .09 + (k / 4) * .022), Vector3(.022, .022, .022), "6fae3a", SATIN, Vector3.ZERO, 6)
	for k in 3:
		cyl(p + Vector3(.1 + k * .02, .03, -.08 + k * .025), Vector3(.022, .055, .022), "ee7d21", SATIN, Vector3(PI / 2, .4 + k * .3, 0), 8)
	_put("broccoli", 0, p + Vector3(-.12, .016, .02), .3, .8)
	_glass(Vector3(.2, .008, -.2), "cfe9f2")

## Food: a wooden serving board of fruit, vegetables, bread and cheese (grocery models reused).
func _meal_food() -> void:
	rbox(Vector3(-.05, .016, 0), Vector3(.56, .032, .38), wood, MATTE, Vector3.ZERO, .03)
	rbox(Vector3(.27, .016, 0), Vector3(.1, .028, .08), wood, MATTE, Vector3.ZERO, .02)
	cyl(Vector3(.29, .03, 0), Vector3(.03, .006, .03), darker(wood, .3), MATTE, Vector3.ZERO, 8)
	var top := .032
	# Low pieces on the near (-X) half, fruit behind them.
	_put("apple", 0, Vector3(.1, top, -.08), .4, 1.05)
	_put("grapes", 0, Vector3(.13, top, .09), .6, 1.1)
	_put("tomato", 0, Vector3(-.05, top, .11), 0.0, .95)
	# A crusty roll with three cuts.
	ball(Vector3(-.2, top + .04, -.07), Vector3(.15, .085, .11), CRUST, MATTE, Vector3(0, .2, 0), 12)
	for k in 3:
		bx(Vector3(-.2 + (k - 1) * .035, top + .082, -.07), Vector3(.012, .006, .08), BREAD, MATTE, Vector3(0, .2 + .5, 0))
	# A cheese wedge with holes.
	prism(Vector3(-.21, top + .04, .09), Vector3(.13, .08, .1), "f7c948", MATTE, Vector3(0, -.3, 0))
	for o in [Vector3(-.225, top + .03, .04), Vector3(-.195, top + .05, .045)]:
		ball(o, Vector3(.018, .018, .006), "dba92e", MATTE, Vector3(0, -.3, 0), 6)

## Coffee: a latte on its saucer with a heart in the foam, a spoon, and a croissant on a plate.
func _meal_coffee() -> void:
	_mat(Vector3(-.05, 0, 0), Vector2(.56, .44))
	var s := Vector3(-.1, .008, -.05)
	lathe(s, [Vector2(0, 0), Vector2(.06, 0), Vector2(.12, .014), Vector2(.115, .02), Vector2(.05, .01), Vector2(0, .01)], PLATE, SATIN, 20)
	var c := s + Vector3(0, .01, 0)
	lathe(c, [Vector2(0, 0), Vector2(.04, 0), Vector2(.058, .02), Vector2(.07, .08), Vector2(.074, .125),
		Vector2(.066, .125), Vector2(.064, .115), Vector2(0, .115)], coral_light, SATIN, 18)
	ring(c + Vector3(0, .04, 0), Vector3(.135, .012, .135), coral, SATIN, Vector3.ZERO, .9, 18)
	cyl(c + Vector3(0, .117, 0), Vector3(.124, .004, .124), "a0683f", SATIN, Vector3.ZERO, 18)
	for side in [-1, 1]:
		ball(c + Vector3(side * .012, .1205, -.008), Vector3(.03, .003, .03), "f6e7cf", SATIN, Vector3.ZERO, 8)
	prism(c + Vector3(0, .1205, .012), Vector3(.05, .032, .003), "f6e7cf", SATIN, Vector3(PI / 2, 0, 0))
	ring(c + Vector3(.085, .065, 0), Vector3(.06, .055, .016), coral_light, SATIN, Vector3(PI / 2, 0, 0), .55, 12)
	bx(s + Vector3(.05, .018, .085), Vector3(.1, .006, .014), silver, METAL, Vector3(0, .5, 0))
	ball(s + Vector3(.005, .02, .062), Vector3(.03, .008, .022), silver, METAL, Vector3(0, .5, 0), 8)
	# The croissant on a side plate.
	var p := Vector3(.12, .008, .1)
	_plate(p, .24)
	var pts := arc(p + Vector3(0, .045, .03), Vector2(.075, .055), -1.35, 1.35, 7)
	tube(pts, [.016, .026, .034, .038, .034, .026, .016], "d9963f", SATIN, 10)
	tube(pts.map(func(q): return q + Vector3(0, .012, 0)), [.008, .016, .022, .025, .022, .016, .008], "e8b264", SATIN, 8)
