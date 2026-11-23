extends "res://scripts/buildings/supermarket_products.gd"
## Clay-toy electronics (18 Nov 2026, user: the electronics store "needs a huge makeover"; record:
## docs/guides/TOWN_DESIGN_BRIEF.md "Electronics store makeover — 18 November 2026"). The
## supermarket's merged-mesh product builder (bx, ball, cyl ... begin/finish) plus:
##   - rbox(): a box with rounded edges and corners, the soft clay look of the zoo animals;
##   - GLOW: an unshaded finish (vertex colour shown as is), so every screen is lit;
##   - one model per electronics word (model_of(word)) and the store's fixtures.
## Models face local -Z with their base at y = 0, in store units (the store is scaled 1.3).
## Colours come from scripts/core/game_palette.gd by name (accent family "sky").
const Palette := preload("res://scripts/core/game_palette.gd")
const GLOW := 3

var trim := Palette.TRIM.to_html(false)
var cream := Palette.CREAM.to_html(false)
var cream_deep := Palette.CREAM_DEEP.to_html(false)
var wall := Palette.WALL_CREAM.to_html(false)
var stone := Palette.STONE.to_html(false)
var iron := Palette.IRON.to_html(false)
var wood := Palette.WOOD.to_html(false)
var ink := Palette.INK.to_html(false)
var rim := Palette.RIM.to_html(false)
var sun := Palette.SUN.to_html(false)
var leaf := Palette.LEAF.to_html(false)
var leaf_dark := Palette.LEAF_DARK.to_html(false)
var pig := Palette.PIG.to_html(false)
var blush := Palette.BLUSH.to_html(false)
var mint := Palette.MINT.to_html(false)
var coral := Palette.CORAL.to_html(false)
var coral_light := Palette.CORAL_LIGHT.to_html(false)
var sky_light := Palette.accent("sky", 0).to_html(false)
var sky := Palette.accent("sky", 1).to_html(false)
var sky_deep := Palette.accent("sky", 2).to_html(false)
var meadow_light := Palette.accent("meadow", 0).to_html(false)
var meadow := Palette.accent("meadow", 1).to_html(false)
var rose := Palette.accent("rose", 1).to_html(false)
var teal := Palette.accent("teal", 1).to_html(false)
## Device metal (handles, door rings): the palette's stone, a little cooler would be a new hex.
var silver := Palette.STONE.lightened(.35).to_html(false)

var _wind := 0.0

# ---------------------------------------------------------------------------------------------
# Builder additions

## Four finishes: MATTE, SATIN, METAL and GLOW (unshaded).
func begin() -> void:
	if _materials.size() == 3:
		var glow := StandardMaterial3D.new()
		glow.vertex_color_use_as_albedo = true
		glow.vertex_color_is_srgb = true
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials.append(glow)
	_v = []; _n = []; _c = []; _i = []
	for f in _materials.size():
		_v.append(PackedVector3Array()); _n.append(PackedVector3Array())
		_c.append(PackedColorArray()); _i.append(PackedInt32Array())

func finish(title: String) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	mesh.resource_name = title
	for f in _materials.size():
		if _i[f].is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = _v[f]
		arrays[Mesh.ARRAY_NORMAL] = _n[f]
		arrays[Mesh.ARRAY_COLOR] = _c[f]
		arrays[Mesh.ARRAY_INDEX] = _i[f]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _materials[f])
	return mesh

## The engine's front-face winding, read from its own box primitive (+1 or -1).
func _winding() -> float:
	if _wind == 0.0:
		var src: Array = _prim("box", 4, 1.0)
		var v: PackedVector3Array = src[0]
		var n: PackedVector3Array = src[1]
		var i: PackedInt32Array = src[2]
		_wind = signf((v[i[1]] - v[i[0]]).cross(v[i[2]] - v[i[0]]).dot(n[i[0]]))
	return _wind

## Grid coordinates along one axis of a rounded box: the flat span plus two steps per rounded edge.
func _edges(half: float, rad: float) -> Array:
	var out := []
	# Small roundings get one step per edge (vertex budget for phones), larger ones two.
	var steps := [-half, -half + rad * .5, -half + rad, half - rad, half - rad * .5, half] if rad >= .03 \
		else [-half, -half + rad, half - rad, half]
	for t in steps:
		if out.is_empty() or t - out[-1] > .0005:
			out.append(t)
	return out

## Box of size `s` centred on `c` with edges rounded to `rad` (default: 60 % of its thinnest
## half), turned by `r` (Euler).
func rbox(c: Vector3, s: Vector3, tint: String, f := MATTE, r := Vector3.ZERO, rad := -1.0) -> void:
	var h := s * .5
	var least := minf(h.x, minf(h.y, h.z))
	var rr := minf(rad if rad >= 0.0 else least * .6, least)
	# Thin or tiny parts (keys, screens, tags) are plain boxes: rounding them is not visible.
	if rr < .006 or least < .012:
		bx(c, s, tint, f, r)
		return
	var xf := Transform3D(Basis.from_euler(r), c)
	var colour := Color(tint)
	var inner := h - Vector3.ONE * rr
	var wind := _winding()
	for axis in 3:
		var ua := (axis + 1) % 3
		var va := (axis + 2) % 3
		var us := _edges(h[ua], rr)
		var vs := _edges(h[va], rr)
		for side in [-1.0, 1.0]:
			var base: int = _v[f].size()
			for a in us:
				for b in vs:
					var p := Vector3.ZERO
					p[axis] = side * h[axis]
					p[ua] = a
					p[va] = b
					var core := p.clamp(-inner, inner)
					var nrm := (p - core).normalized()
					_v[f].append(xf * (core + nrm * rr))
					_n[f].append(xf.basis * nrm)
					_c[f].append(colour)
			var w := vs.size()
			for i in us.size() - 1:
				for j in w - 1:
					var q := [base + i * w + j, base + (i + 1) * w + j, base + (i + 1) * w + j + 1, base + i * w + j + 1]
					for tri in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
						var p0: Vector3 = _v[f][tri[0]]
						var cross: Vector3 = (_v[f][tri[1]] - p0).cross(_v[f][tri[2]] - p0)
						if cross.length_squared() < 1e-14:
							continue
						if signf(cross.dot(_n[f][tri[0]] + _n[f][tri[1]] + _n[f][tri[2]])) != wind:
							tri = [tri[0], tri[2], tri[1]]
						_i[f].append_array(tri)

# ---------------------------------------------------------------------------------------------
# Screens: a lit picture on a plane facing -Z at depth z (its front), centre (x, y), size w x h.

func _sky_screen(at: Vector3, w: float, h: float) -> void:
	rbox(at, Vector3(w, h, .006), sky_light, GLOW, Vector3.ZERO, minf(w, h) * .08)

func screen_landscape(at: Vector3, w: float, h: float) -> void:
	_sky_screen(at, w, h)
	var z := at.z - .004
	bx(Vector3(at.x, at.y - h * .36, z), Vector3(w * .96, h * .24, .003), meadow_light, GLOW)
	dome(Vector3(at.x + w * .16, at.y - h * .2, z - .003), Vector3(w * .56, h * .34, .003), leaf, GLOW, Vector3.ZERO, 16)
	dome(Vector3(at.x - w * .22, at.y - h * .25, z - .002), Vector3(w * .4, h * .22, .003), meadow, GLOW, Vector3.ZERO, 16)
	var d := minf(w, h)
	ball(Vector3(at.x - w * .3, at.y + h * .22, z), Vector3(d * .22, d * .22, .003), sun, GLOW, Vector3.ZERO, 16)
	for o in [Vector3(-.06, 0, 0), Vector3(.02, .03, 0), Vector3(.1, 0, 0)]:
		ball(Vector3(at.x + w * .18 + o.x * w, at.y + h * .27 + o.y * h, z), Vector3(d * .2, d * .13, .003), rim, GLOW, Vector3.ZERO, 12)

func screen_apps(at: Vector3, w: float, h: float, cols := 3, rows := 4) -> void:
	_sky_screen(at, w, h)
	var tints := [coral, sky, meadow, sun, rose, teal]
	var cell := minf(w * .8 / cols, h * .8 / rows)
	var tile := cell * .7
	for i in cols:
		for j in rows:
			var c := Vector3(at.x + (i - (cols - 1) * .5) * cell, at.y + ((rows - 1) * .5 - j) * cell, at.z - .004)
			rbox(c, Vector3(tile, tile, .003), tints[(i + j * cols) % tints.size()], GLOW, Vector3.ZERO, tile * .25)

func screen_game(at: Vector3, w: float, h: float) -> void:
	_sky_screen(at, w, h)
	var z := at.z - .004
	var block := h * .14
	bx(Vector3(at.x, at.y - h * .5 + block * .5 + h * .02, z), Vector3(w * .96, block, .003), meadow, GLOW)
	for k in 3:
		rbox(Vector3(at.x + w * (.05 + k * .1), at.y + h * .05, z), Vector3(block * .9, block * .9, .003), sun if k == 1 else Palette.WOOD.lightened(.2).to_html(false), GLOW, Vector3.ZERO, block * .15)
	for k in 4:
		ball(Vector3(at.x - w * .32 + k * w * .08, at.y + h * .22, z), Vector3(block * .5, block * .6, .003), sun, GLOW, Vector3.ZERO, 12)
	# The player: a round pink hero mid-jump.
	ball(Vector3(at.x - w * .2, at.y - h * .12, z - .002), Vector3(block * 1.1, block * 1.1, .003), pig, GLOW, Vector3.ZERO, 16)
	ball(Vector3(at.x - w * .18, at.y - h * .11, z - .004), Vector3(block * .18, block * .2, .002), ink, GLOW, Vector3.ZERO, 8)
	ball(Vector3(at.x + w * .3, at.y + h * .3, z), Vector3(w * .14, h * .09, .003), rim, GLOW, Vector3.ZERO, 12)

## BonBon's face on the big screen (the home theatre).
func screen_bonbon(at: Vector3, w: float, h: float) -> void:
	screen_landscape(at, w, h)
	var z := at.z - .012
	var d := h * .56
	var c := Vector3(at.x + w * .04, at.y - h * .02, z)
	ball(c, Vector3(d, d * .92, .003), pig, GLOW, Vector3.ZERO, 24)
	for side in [-1, 1]:
		prism(c + Vector3(side * d * .32, d * .46, .001), Vector3(d * .22, d * .2, .003), pig, GLOW, Vector3(0, 0, side * -.3))
		ball(c + Vector3(side * d * .2, d * .08, -.002), Vector3(d * .1, d * .13, .002), ink, GLOW, Vector3.ZERO, 10)
		ball(c + Vector3(side * d * .32, -d * .12, -.002), Vector3(d * .14, d * .08, .002), blush, GLOW, Vector3.ZERO, 10)
	ball(c + Vector3(0, -d * .14, -.003), Vector3(d * .3, d * .2, .002), blush, GLOW, Vector3.ZERO, 14)
	for side in [-1, 1]:
		ball(c + Vector3(side * d * .06, -d * .14, -.005), Vector3(d * .05, d * .07, .002), ink, GLOW, Vector3.ZERO, 8)

# ---------------------------------------------------------------------------------------------
# Word models

const MODELS := {"television": "_tv", "computer": "_computer", "laptop": "_laptop",
	"smartphone": "_phone", "tablet": "_tablet", "keyboard": "_keyboard", "mouse": "_mouse",
	"game controller": "_controller", "washing machine": "_washer", "dryer": "_dryer",
	"refrigerator": "_fridge", "microwave": "_microwave", "headphones": "_headphones",
	"speaker": "_speaker", "camera": "_camera", "fan": "_fan", "smartwatch": "_watch",
	"game console": "_console", "cash register": "_register", "shopping bag": "_bag",
	"checkout counter": "_counter"}

## Small devices drawn a little larger than life so they read from the aisle (as the
## supermarket's goods, 3 Nov 2026).
const GROW := {"smartphone": 1.3, "tablet": 1.2, "smartwatch": 1.3, "mouse": 1.15}

## `extra` scales the model about its base (the 23 Nov 2026 step `bigger_products`: the small
## products 20% bigger).
func model_of(word: String, extra := 1.0) -> ArrayMesh:
	begin()
	call(MODELS[word])
	_grow_all(GROW.get(word, 1.0) * extra)
	return finish("Electronics " + word)

## Scales everything drawn since begin() about the origin (the model's base centre).
func _grow_all(grow: float) -> void:
	if grow == 1.0:
		return
	for f in _materials.size():
		for k in _v[f].size():
			_v[f][k] = _v[f][k] * grow

## The small appliances as words (user, 23 Nov 2026: the rice cookers, toasters and blenders the
## store showed were not words): one model per word and tint, base at y 0, front -Z, scaled by
## `extra`. Toaster, kettle and blender are the wall unit's decor shapes (small_appliance()); the
## rice cooker replaces its air fryer.
const APPLIANCES := {"toaster": 0, "kettle": 1, "blender": 2, "rice cooker": -1}

func appliance(word: String, tint: String, extra := 1.0) -> ArrayMesh:
	begin()
	if APPLIANCES[word] >= 0:
		small_appliance(APPLIANCES[word], tint)
	else:
		_rice_cooker(tint)
	_grow_all(extra)
	return finish("Electronics %s %s" % [word, tint])

func _rice_cooker(tint: String) -> void:
	lathe(Vector3.ZERO, [Vector2(0, 0), Vector2(.12, 0), Vector2(.145, .025), Vector2(.152, .09),
		Vector2(.146, .17), Vector2(.132, .19), Vector2(0, .19)], tint, SATIN, 16)
	ring(Vector3(0, .19, 0), Vector3(.28, .02, .28), silver, METAL, Vector3.ZERO, .86, 16)
	dome(Vector3(0, .222, 0), Vector3(.265, .065, .265), trim, SATIN, Vector3.ZERO, 16)
	rbox(Vector3(0, .262, .01), Vector3(.13, .03, .045), iron, SATIN, Vector3.ZERO, .014)
	cyl(Vector3(.06, .25, -.05), Vector3(.03, .012, .03), iron, SATIN, Vector3.ZERO, 8)
	rbox(Vector3(0, .1, -.142), Vector3(.12, .075, .022), cream, SATIN, Vector3(-.1, 0, 0), .016)
	ball(Vector3(-.028, .1, -.155), Vector3(.022, .022, .008), coral, GLOW, Vector3.ZERO, 8)
	ball(Vector3(.028, .1, -.155), Vector3(.022, .022, .008), meadow, GLOW, Vector3.ZERO, 8)

func _tv() -> void:
	for side in [-1, 1]:
		rbox(Vector3(side * .55, .04, .02), Vector3(.22, .08, .3), iron, SATIN)
	rbox(Vector3(0, .66, 0), Vector3(1.72, 1.04, .12), iron, SATIN, Vector3.ZERO, .05)
	screen_landscape(Vector3(0, .66, -.062), 1.58, .9)
	ball(Vector3(.72, .17, -.06), Vector3(.03, .03, .01), meadow, GLOW, Vector3.ZERO, 8)

func _computer() -> void:
	# Monitor on a round foot, tower on the left.
	cyl(Vector3(0, .015, .04), Vector3(.34, .03, .26), trim, SATIN, Vector3.ZERO, 16)
	rbox(Vector3(0, .2, .07), Vector3(.1, .36, .06), trim, SATIN)
	rbox(Vector3(0, .58, .02), Vector3(.84, .52, .07), trim, SATIN, Vector3.ZERO, .035)
	_sky_screen(Vector3(0, .6, -.018), .76, .42)
	for k in 3:
		rbox(Vector3(-.2 + k * .2, .64, -.024), Vector3(.16, .14, .003), [rim, Palette.SKY.to_html(false), rim][k], GLOW, Vector3.ZERO, .015)
		bx(Vector3(-.2 + k * .2, .69, -.027), Vector3(.16, .025, .002), [coral, meadow, sky][k], GLOW)
	bx(Vector3(0, .41, -.024), Vector3(.76, .035, .003), Palette.SKY.to_html(false), GLOW)
	rbox(Vector3(-.6, .24, .03), Vector3(.2, .48, .42), trim, SATIN, Vector3.ZERO, .04)
	rbox(Vector3(-.6, .3, -.18), Vector3(.025, .26, .004), sky, GLOW, Vector3.ZERO, .01)
	ball(Vector3(-.6, .41, -.183), Vector3(.035, .035, .008), meadow, GLOW, Vector3.ZERO, 8)

func _keyboard() -> void:
	rbox(Vector3(0, .02, 0), Vector3(.64, .04, .2), trim, SATIN, Vector3.ZERO, .015)
	for row in 3:
		for k in 10:
			rbox(Vector3(-.27 + k * .06, .045, -.06 + row * .055), Vector3(.048, .02, .044), cream_deep, SATIN, Vector3.ZERO, .008)
	rbox(Vector3(0, .045, .075), Vector3(.3, .02, .03), cream_deep, SATIN, Vector3.ZERO, .008)

func _mouse() -> void:
	rbox(Vector3(0, .005, 0), Vector3(.26, .01, .24), sky_light, MATTE, Vector3.ZERO, .004)
	ball(Vector3(0, .04, 0), Vector3(.1, .065, .15), trim, SATIN, Vector3.ZERO, 14)
	rbox(Vector3(0, .07, -.035), Vector3(.012, .015, .03), sky, SATIN, Vector3.ZERO, .005)

func _laptop() -> void:
	rbox(Vector3(0, .018, 0), Vector3(.58, .036, .4), trim, SATIN, Vector3.ZERO, .016)
	rbox(Vector3(0, .037, -.04), Vector3(.48, .004, .2), cream_deep, MATTE, Vector3.ZERO, .002)
	rbox(Vector3(0, .037, .12), Vector3(.16, .004, .08), cream_deep, MATTE, Vector3.ZERO, .002)
	# The lid stands at the back edge (+Z; the keyboard faces the shopper) and leans back.
	var hinge := Vector3(0, .036, .19)
	var lid := hinge + Vector3(0, .2, 0)
	_mark_now()
	rbox(lid, Vector3(.58, .4, .022), trim, SATIN, Vector3.ZERO, .014)
	screen_landscape(lid + Vector3(0, 0, -.013), .5, .32)
	_tip_last(hinge, .3)

## Everything drawn since _mark_now() is turned about the X axis through `centre` by `tilt`
## (positive: the top leans back, away from the shopper): leaning lids, phones and tablets.
var _mark := []
func _tip_last(centre: Vector3, tilt: float) -> void:
	if _mark.is_empty():
		return
	var turn := Transform3D(Basis(Vector3.RIGHT, tilt), Vector3.ZERO)
	var about := Transform3D(Basis.IDENTITY, centre) * turn * Transform3D(Basis.IDENTITY, -centre)
	for f in _materials.size():
		for k in range(_mark[f], _v[f].size()):
			_v[f][k] = about * _v[f][k]
			_n[f][k] = turn.basis * _n[f][k]
	_mark = []

func _mark_now() -> void:
	_mark = []
	for f in _materials.size():
		_mark.append(_v[f].size())

func _phone() -> void:
	rbox(Vector3(0, .03, .02), Vector3(.18, .06, .16), cream, MATTE, Vector3.ZERO, .025)
	var tilt := .22
	var c := Vector3(0, .205, .0)
	_mark_now()
	rbox(c, Vector3(.15, .29, .024), pig, SATIN, Vector3.ZERO, .022)
	screen_apps(c + Vector3(0, .005, -.013), .125, .25, 3, 5)
	ball(c + Vector3(-.04, .12, .013), Vector3(.025, .025, .006), ink, SATIN, Vector3.ZERO, 8)
	_tip_last(c - Vector3(0, .145, 0), tilt)

func _tablet() -> void:
	rbox(Vector3(0, .03, .03), Vector3(.3, .06, .18), cream, MATTE, Vector3.ZERO, .025)
	var tilt := .24
	var c := Vector3(0, .2, 0)
	_mark_now()
	rbox(c, Vector3(.44, .31, .024), mint, SATIN, Vector3.ZERO, .022)
	screen_landscape(c + Vector3(0, 0, -.013), .39, .26)
	_tip_last(c - Vector3(0, .155, 0), tilt)

func _watch() -> void:
	cyl(Vector3(0, .05, 0), Vector3(.2, .1, .2), stone, MATTE, Vector3.ZERO, 16)
	rbox(Vector3(0, .19, 0), Vector3(.1, .18, .1), cream, MATTE, Vector3.ZERO, .04)
	rbox(Vector3(0, .19, 0), Vector3(.07, .2, .115), coral, MATTE, Vector3.ZERO, .03)
	rbox(Vector3(0, .2, -.065), Vector3(.11, .12, .035), iron, SATIN, Vector3.ZERO, .02)
	rbox(Vector3(0, .2, -.084), Vector3(.088, .098, .004), sky_light, GLOW, Vector3.ZERO, .015)
	ring(Vector3(0, .2, -.088), Vector3(.06, .004, .06), meadow, GLOW, Vector3(PI / 2, 0, 0), .7, 16)
	bx(Vector3(0, .21, -.089), Vector3(.006, .03, .002), ink, GLOW)
	bx(Vector3(.01, .2, -.089), Vector3(.02, .006, .002), ink, GLOW)
	rbox(Vector3(.06, .21, -.065), Vector3(.015, .025, .02), silver, METAL)

func _controller() -> void:
	rbox(Vector3(0, .04, 0), Vector3(.28, .07, .14), trim, SATIN, Vector3.ZERO, .03)
	for side in [-1, 1]:
		ball(Vector3(side * .12, .035, .04), Vector3(.12, .07, .15), trim, SATIN, Vector3(0, side * .3, 0), 12)
		cyl(Vector3(side * .045, .085, .02), Vector3(.04, .03, .04), iron, SATIN, Vector3.ZERO, 10)
	bx(Vector3(-.09, .078, -.025), Vector3(.06, .012, .02), iron, SATIN)
	bx(Vector3(-.09, .078, -.025), Vector3(.02, .012, .06), iron, SATIN)
	for b in [[Vector3(.09, .078, -.05), coral], [Vector3(.115, .078, -.025), sky], [Vector3(.065, .078, -.025), meadow], [Vector3(.09, .078, 0), sun]]:
		ball(b[0], Vector3(.022, .015, .022), b[1], SATIN, Vector3.ZERO, 8)

func _console() -> void:
	rbox(Vector3(0, .055, 0), Vector3(.48, .11, .34), trim, SATIN, Vector3.ZERO, .04)
	rbox(Vector3(0, .113, 0), Vector3(.44, .008, .3), cream_deep, MATTE, Vector3.ZERO, .004)
	rbox(Vector3(0, .055, -.171), Vector3(.36, .012, .004), sky, GLOW, Vector3.ZERO, .005)
	ball(Vector3(.19, .055, -.172), Vector3(.02, .02, .006), meadow, GLOW, Vector3.ZERO, 8)

func _washer_body(panel: String) -> void:
	for x in [-.36, .36]:
		cyl(Vector3(x, .015, -.3), Vector3(.06, .03, .06), iron)
		cyl(Vector3(x, .015, .3), Vector3(.06, .03, .06), iron)
	rbox(Vector3(0, .6, 0), Vector3(.9, 1.14, .85), trim, SATIN, Vector3.ZERO, .07)
	rbox(Vector3(0, 1.06, -.43), Vector3(.8, .16, .03), panel, SATIN, Vector3.ZERO, .015)
	cyl(Vector3(.26, 1.06, -.45), Vector3(.1, .03, .1), trim, SATIN, Vector3(PI / 2, 0, 0), 14)
	rbox(Vector3(-.1, 1.06, -.447), Vector3(.2, .07, .004), Palette.SKY.to_html(false), GLOW, Vector3.ZERO, .01)
	ring(Vector3(0, .5, -.44), Vector3(.64, .06, .64), silver, METAL, Vector3(PI / 2, 0, 0), .74, 20)

func _washer() -> void:
	_washer_body(sky_light)
	ball(Vector3(0, .5, -.43), Vector3(.48, .48, .05), Palette.SKY.to_html(false), SATIN, Vector3.ZERO, 18)
	dome(Vector3(0, .37, -.455), Vector3(.4, .12, .02), sky_light, SATIN, Vector3(0, 0, PI), 16)
	for k in 3:
		ball(Vector3(-.1 + k * .1, .4 + (k % 2) * .05, -.46), Vector3(.05, .05, .01), rim, SATIN, Vector3.ZERO, 8)

func _dryer() -> void:
	_washer_body(coral_light)
	ball(Vector3(0, .5, -.43), Vector3(.48, .48, .05), iron, SATIN, Vector3.ZERO, 18)
	for k in 4:
		rbox(Vector3(0, .41 + k * .06, -.456), Vector3(.3 - absf(k - 1.5) * .06, .018, .004), Palette.STONE.to_html(false), MATTE, Vector3.ZERO, .006)
	rbox(Vector3(0, .1, -.43), Vector3(.5, .05, .02), cream_deep, MATTE, Vector3.ZERO, .01)

func _fridge() -> void:
	for x in [-.38, .38]:
		cyl(Vector3(x, .015, -.3), Vector3(.06, .03, .06), iron)
	rbox(Vector3(0, 1.06, .02), Vector3(.94, 2.06, .82), trim, SATIN, Vector3.ZERO, .08)
	rbox(Vector3(0, 1.7, -.4), Vector3(.88, .64, .06), trim, SATIN, Vector3.ZERO, .03)
	rbox(Vector3(0, .7, -.4), Vector3(.88, 1.28, .06), trim, SATIN, Vector3.ZERO, .03)
	for c in [Vector3(.36, 1.62, -.45), Vector3(.36, 1.2, -.45)]:
		rbox(c, Vector3(.04, .3, .04), silver, METAL, Vector3.ZERO, .018)
	rbox(Vector3(-.2, 1.78, -.432), Vector3(.2, .12, .004), Palette.SKY.to_html(false), GLOW, Vector3.ZERO, .015)
	bx(Vector3(-.2, 1.78, -.435), Vector3(.1, .02, .002), sky, GLOW)
	for m in [[Vector3(-.22, 1.0, -.44), coral], [Vector3(-.08, .9, -.44), meadow], [Vector3(-.26, .8, -.44), sun], [Vector3(.06, 1.05, -.44), rose]]:
		ball(m[0], Vector3(.07, .07, .03), m[1], SATIN, Vector3.ZERO, 10)

func _microwave() -> void:
	for x in [-.28, .28]:
		cyl(Vector3(x, .01, -.16), Vector3(.05, .02, .05), iron)
		cyl(Vector3(x, .01, .16), Vector3(.05, .02, .05), iron)
	rbox(Vector3(0, .23, 0), Vector3(.7, .42, .48), trim, SATIN, Vector3.ZERO, .05)
	rbox(Vector3(-.08, .23, -.243), Vector3(.46, .32, .02), ink, SATIN, Vector3.ZERO, .02)
	rbox(Vector3(-.08, .2, -.255), Vector3(.3, .08, .004), Palette.STONE.to_html(false), MATTE, Vector3.ZERO, .01)
	rbox(Vector3(.23, .33, -.244), Vector3(.14, .06, .004), mint, GLOW, Vector3.ZERO, .01)
	for k in 6:
		rbox(Vector3(.2 + (k % 2) * .06, .25 - (k / 2) * .05, -.245), Vector3(.04, .03, .008), cream_deep, SATIN, Vector3.ZERO, .006)
	rbox(Vector3(.14, .23, -.258), Vector3(.025, .28, .02), silver, METAL, Vector3.ZERO, .01)

func _fan() -> void:
	cyl(Vector3(0, .03, 0), Vector3(.52, .06, .52), trim, SATIN, Vector3.ZERO, 20)
	cyl(Vector3(0, .6, 0), Vector3(.06, 1.1, .06), trim, SATIN, Vector3.ZERO, 12)
	ball(Vector3(0, 1.3, .1), Vector3(.22, .22, .28), trim, SATIN, Vector3.ZERO, 14)
	ring(Vector3(0, 1.3, -.06), Vector3(.66, .07, .66), sky, SATIN, Vector3(PI / 2, 0, 0), .9, 24)
	for k in 3:
		var a := k * TAU / 3 + .3
		ball(Vector3(cos(a) * .15, 1.3 + sin(a) * .15, -.05), Vector3(.24, .13, .02), sky_light, SATIN, Vector3(0, 0, a), 12)
	ball(Vector3(0, 1.3, -.07), Vector3(.09, .09, .05), sky, SATIN, Vector3.ZERO, 10)
	for k in 6:
		var a := k * TAU / 6
		bx(Vector3(cos(a) * .15, 1.3 + sin(a) * .15, -.085), Vector3(.3, .01, .01), trim, SATIN, Vector3(0, 0, a))
	cyl(Vector3(.12, .065, -.12), Vector3(.05, .02, .05), meadow, SATIN, Vector3.ZERO, 8)

func _headphones() -> void:
	cyl(Vector3(0, .015, 0), Vector3(.22, .03, .22), wood, MATTE, Vector3.ZERO, 16)
	cyl(Vector3(0, .3, 0), Vector3(.035, .56, .035), wood, MATTE, Vector3.ZERO, 8)
	var c := Vector3(0, .47, 0)
	for k in 9:
		var a := k * PI / 8
		rbox(c + Vector3(cos(a) * .16, sin(a) * .16, 0), Vector3(.07, .04, .06), sky, SATIN, Vector3(0, 0, a + PI / 2), .018)
	for side in [-1, 1]:
		rbox(c + Vector3(side * .17, -.02, 0), Vector3(.08, .17, .15), sky, SATIN, Vector3.ZERO, .04)
		rbox(c + Vector3(side * .125, -.02, 0), Vector3(.035, .15, .13), cream, MATTE, Vector3.ZERO, .016)

func _speaker() -> void:
	rbox(Vector3(0, .25, 0), Vector3(.32, .5, .28), wood, MATTE, Vector3.ZERO, .05)
	rbox(Vector3(0, .25, -.142), Vector3(.27, .45, .008), cream, MATTE, Vector3.ZERO, .03)
	for spec in [[.36, .1], [.15, .065]]:
		ring(Vector3(0, spec[0], -.148), Vector3(spec[1] * 2.2, .02, spec[1] * 2.2), sky, SATIN, Vector3(PI / 2, 0, 0), .78, 18)
		dome(Vector3(0, spec[0], -.15), Vector3(spec[1] * 1.8, spec[1] * .4, spec[1] * 1.8), iron, SATIN, Vector3(-PI / 2, 0, 0), 14)
	ball(Vector3(.1, .48, -.15), Vector3(.02, .02, .006), meadow, GLOW, Vector3.ZERO, 8)

func _camera() -> void:
	rbox(Vector3(0, .13, 0), Vector3(.36, .22, .14), trim, SATIN, Vector3.ZERO, .04)
	rbox(Vector3(0, .09, 0), Vector3(.37, .1, .145), iron, MATTE, Vector3.ZERO, .03)
	rbox(Vector3(-.03, .26, .01), Vector3(.12, .08, .1), trim, SATIN, Vector3.ZERO, .03)
	cyl(Vector3(.03, .13, -.13), Vector3(.16, .14, .16), iron, SATIN, Vector3(PI / 2, 0, 0), 18)
	ring(Vector3(.03, .13, -.17), Vector3(.17, .03, .17), sky, SATIN, Vector3(PI / 2, 0, 0), .7, 18)
	ball(Vector3(.03, .13, -.2), Vector3(.12, .12, .03), ink, METAL, Vector3.ZERO, 14)
	ball(Vector3(.0, .15, -.212), Vector3(.03, .03, .006), rim, SATIN, Vector3.ZERO, 8)
	cyl(Vector3(.12, .255, -.02), Vector3(.05, .03, .05), coral, SATIN, Vector3.ZERO, 10)
	ball(Vector3(-.13, .2, -.073), Vector3(.035, .035, .01), sun, SATIN, Vector3.ZERO, 8)

func _register() -> void:
	rbox(Vector3(0, .06, 0), Vector3(.4, .12, .36), trim, SATIN, Vector3.ZERO, .03)
	rbox(Vector3(0, .055, -.182), Vector3(.3, .05, .006), cream_deep, MATTE, Vector3.ZERO, .01)
	rbox(Vector3(0, .15, .03), Vector3(.3, .08, .2), cream_deep, SATIN, Vector3(-.4, 0, 0), .02)
	for k in 9:
		rbox(Vector3(-.07 + (k % 3) * .07, .19, -.01 + (k / 3) * .055), Vector3(.05, .02, .04), [sky, cream, cream, cream, cream, cream, cream, cream, meadow][k], SATIN, Vector3(-.4, 0, 0), .008)
	rbox(Vector3(0, .26, .12), Vector3(.04, .14, .04), trim, SATIN, Vector3.ZERO, .015)
	rbox(Vector3(0, .34, .12), Vector3(.26, .16, .03), trim, SATIN, Vector3.ZERO, .015)
	rbox(Vector3(0, .34, .136), Vector3(.22, .12, .004), sky_light, GLOW, Vector3.ZERO, .012)
	rbox(Vector3(0, .34, .104), Vector3(.22, .12, .004), sky_light, GLOW, Vector3.ZERO, .012)
	bx(Vector3(0, .34, .1), Vector3(.12, .03, .002), sky_deep, GLOW)

func _bag() -> void:
	rbox(Vector3(0, .17, 0), Vector3(.3, .34, .14), sky, MATTE, Vector3.ZERO, .03)
	for z in [-.045, .045]:
		ring(Vector3(0, .34, z), Vector3(.14, .012, .14), sky_deep, MATTE, Vector3(PI / 2, 0, 0), .7, 14)
	rbox(Vector3(0, .17, -.072), Vector3(.1, .1, .004), trim, MATTE, Vector3.ZERO, .015)
	_plug_icon(Vector3(0, .17, -.075), .07, sky)

## The checkout counter word root's model; its origin is the counter's centre (2.0 x 0.82 x 0.7),
## low enough that the plush clerk shows above it.
func _counter() -> void:
	rbox(Vector3(0, -.355, .02), Vector3(1.94, .11, .64), stone, MATTE, Vector3.ZERO, .03)
	rbox(Vector3(0, -.02, 0), Vector3(2.0, .72, .7), trim, MATTE, Vector3.ZERO, .05)
	rbox(Vector3(0, -.04, -.355), Vector3(1.86, .42, .03), sky, SATIN, Vector3.ZERO, .04)
	rbox(Vector3(0, -.03, -.373), Vector3(.3, .28, .006), sky_light, MATTE, Vector3.ZERO, .05)
	_plug_icon(Vector3(0, -.03, -.377), .18, sky_deep)
	rbox(Vector3(0, .385, 0), Vector3(2.06, .05, .76), wood, MATTE, Vector3.ZERO, .022)

## A plug pictogram (the store's emblem) facing -Z at `at`, about `size` across.
func _plug_icon(at: Vector3, size: float, tint: String) -> void:
	rbox(at + Vector3(0, -size * .1, -.002), Vector3(size * .6, size * .5, .004), tint, MATTE, Vector3.ZERO, size * .12)
	for side in [-1, 1]:
		bx(at + Vector3(side * size * .15, size * .28, -.002), Vector3(size * .1, size * .3, .004), tint, MATTE)
	bx(at + Vector3(0, -size * .45, -.002), Vector3(size * .12, size * .25, .004), tint, MATTE)

## A chip pictogram (tech) and a controller pictogram (gaming), facing -Z.
func _chip_icon(at: Vector3, size: float, tint: String) -> void:
	rbox(at + Vector3(0, 0, -.002), Vector3(size * .56, size * .56, .004), tint, MATTE, Vector3.ZERO, size * .08)
	for k in 3:
		var o := (k - 1) * size * .17
		for side in [-1, 1]:
			bx(at + Vector3(o, side * size * .38, -.002), Vector3(size * .07, size * .16, .004), tint, MATTE)
			bx(at + Vector3(side * size * .38, o, -.002), Vector3(size * .16, size * .07, .004), tint, MATTE)

func _pad_icon(at: Vector3, size: float, tint: String, cut: String) -> void:
	rbox(at + Vector3(0, size * .05, -.002), Vector3(size * .8, size * .34, .004), tint, MATTE, Vector3.ZERO, size * .14)
	for side in [-1, 1]:
		ball(at + Vector3(side * size * .3, -size * .08, -.002), Vector3(size * .3, size * .36, .004), tint, MATTE, Vector3.ZERO, 12)
	bx(at + Vector3(-size * .22, size * .05, -.005), Vector3(size * .16, size * .05, .002), cut, MATTE)
	bx(at + Vector3(-size * .22, size * .05, -.005), Vector3(size * .05, size * .16, .002), cut, MATTE)
	ball(at + Vector3(size * .24, size * .08, -.005), Vector3(size * .07, size * .07, .002), cut, MATTE, Vector3.ZERO, 8)
	ball(at + Vector3(size * .17, size * .0, -.005), Vector3(size * .07, size * .07, .002), cut, MATTE, Vector3.ZERO, 8)

## A sign plaque: a rounded board of width w and height h (centre at the origin, facing -Z,
## `icon` drawn at the viewer's left end), on two posts down to `posts` below its centre when
## posts > 0 (a sign standing on a table). Returns nothing; the lettering is a separate Label3D.
func plaque(w: float, h: float, ground: String, icon: String, posts := 0.0) -> ArrayMesh:
	begin()
	rbox(Vector3.ZERO, Vector3(w, h, .07), ground, SATIN, Vector3.ZERO, .03)
	rbox(Vector3(0, 0, -.036), Vector3(w - .06, h - .06, .004), ground, SATIN, Vector3.ZERO, .025)
	var at := Vector3(w * .5 - h * .55, 0, -.04)
	match icon:
		"plug":
			ball(at + Vector3(0, 0, .002), Vector3(h * .78, h * .78, .004), sky_light, MATTE, Vector3.ZERO, 16)
			_plug_icon(at, h * .5, ground)
		"chip":
			ball(at + Vector3(0, 0, .002), Vector3(h * .78, h * .78, .004), sky_light, MATTE, Vector3.ZERO, 16)
			_chip_icon(at, h * .5, ground)
		"pad":
			ball(at + Vector3(0, 0, .002), Vector3(h * .78, h * .78, .004), sky_light, MATTE, Vector3.ZERO, 16)
			_pad_icon(at, h * .55, ground, sky_light)
	if posts > 0.0:
		for side in [-1, 1]:
			cyl(Vector3(side * w * .3, -h * .5 - (posts - h * .5) * .5, 0), Vector3(.04, posts - h * .5, .04), iron, SATIN, Vector3.ZERO, 8)
	return finish("Electronics plaque " + icon)

# ---------------------------------------------------------------------------------------------
# Decor (no word: nothing here imitates a word object, except screens on walls, as before)

func carton(c: Vector3, s: Vector3, tint: String, yaw := 0.0) -> void:
	rbox(c, s, tint, MATTE, Vector3(0, yaw, 0), minf(s.x, s.y) * .08)
	var front := Vector3(0, 0, -s.z * .5 - .002).rotated(Vector3.UP, yaw)
	rbox(c + front + Vector3(0, s.y * .05, 0), Vector3(s.x * .6, s.y * .5, .004), trim, MATTE, Vector3(0, yaw, 0), .01)
	rbox(c + front * 1.04 + Vector3(0, s.y * .07, 0), Vector3(s.x * .36, s.y * .26, .003), sky_light, MATTE, Vector3(0, yaw, 0), .008)

func plant(at: Vector3, size := 1.0) -> void:
	cyl(at + Vector3(0, .2 * size, 0), Vector3(.38, .4, .38) * size, stone, MATTE, Vector3.ZERO, 16, .8)
	cyl(at + Vector3(0, .395 * size, 0), Vector3(.32, .02, .32) * size, wood, MATTE, Vector3.ZERO, 14)
	for k in 7:
		var a := k * TAU / 7
		var r := .1 if k % 2 == 0 else .05
		ball(at + Vector3(cos(a) * r, .55 + (k % 3) * .1, sin(a) * r) * size + Vector3(0, 0, 0), Vector3(.24, .3, .24) * size, leaf if k % 2 == 0 else leaf_dark, MATTE, Vector3(0, 0, .2 * (k % 3 - 1)), 10)
	ball(at + Vector3(0, .82, 0) * size, Vector3(.22, .28, .22) * size, leaf, MATTE, Vector3.ZERO, 10)

## A pendant lamp: cord from the ceiling, a sky dome shade and a lit disc under it.
func pendant(at: Vector3, ceiling: float) -> void:
	cyl(Vector3(at.x, (ceiling + at.y + .15) * .5, at.z), Vector3(.02, ceiling - at.y - .15, .02), iron, MATTE, Vector3.ZERO, 6)
	dome(at, Vector3(.7, .3, .7), sky, SATIN, Vector3.ZERO, 20)
	cyl(at + Vector3(0, -.005, 0), Vector3(.6, .01, .6), cream, GLOW, Vector3.ZERO, 20)
	ball(at + Vector3(0, .3, 0), Vector3(.1, .08, .1), sky_deep, SATIN, Vector3.ZERO, 8)

## Moves everything drawn since _mark_now() by `xf` (a turn and a shift; no scale): draw a part
## in its own frame (front -Z, base at y 0), then put it in the store.
func place(xf: Transform3D) -> void:
	for f in _materials.size():
		for k in range(_mark[f], _v[f].size()):
			_v[f][k] = xf * _v[f][k]
			_n[f][k] = xf.basis * _n[f][k]
	_mark = []

## Small appliances for the wall unit (decor: none of them is a word), base at y 0, front -Z.
func small_appliance(kind: int, tint: String) -> void:
	match kind % 4:
		0:  # toaster
			rbox(Vector3(0, .13, 0), Vector3(.34, .26, .2), tint, SATIN, Vector3.ZERO, .07)
			for x in [-.06, .06]:
				rbox(Vector3(x, .262, 0), Vector3(.03, .008, .14), iron, MATTE, Vector3.ZERO, .004)
			rbox(Vector3(.12, .16, -.105), Vector3(.03, .05, .02), trim, SATIN, Vector3.ZERO, .01)
		1:  # kettle
			cyl(Vector3(0, .015, 0), Vector3(.24, .03, .24), iron, SATIN, Vector3.ZERO, 14)
			cyl(Vector3(0, .16, 0), Vector3(.22, .26, .22), tint, SATIN, Vector3.ZERO, 16, .75)
			dome(Vector3(0, .3, 0), Vector3(.16, .05, .16), tint, SATIN, Vector3.ZERO, 14)
			ring(Vector3(0, .2, .12), Vector3(.16, .03, .16), tint, SATIN, Vector3(0, PI / 2, PI / 2), .6, 12)
			prism(Vector3(0, .24, -.12), Vector3(.05, .08, .05), tint, SATIN, Vector3(-.6, 0, 0))
		2:  # blender
			rbox(Vector3(0, .07, 0), Vector3(.2, .14, .2), tint, SATIN, Vector3.ZERO, .05)
			cyl(Vector3(0, .26, 0), Vector3(.16, .24, .16), Palette.SKY.to_html(false), SATIN, Vector3.ZERO, 14, 1.15)
			cyl(Vector3(0, .39, 0), Vector3(.19, .03, .19), iron, SATIN, Vector3.ZERO, 14)
			cyl(Vector3(0, .07, -.1), Vector3(.04, .02, .04), trim, SATIN, Vector3(PI / 2, 0, 0), 10)
		3:  # air fryer
			rbox(Vector3(0, .17, 0), Vector3(.28, .34, .3), tint, SATIN, Vector3.ZERO, .1)
			rbox(Vector3(0, .12, -.15), Vector3(.22, .16, .03), darker(tint, .15), SATIN, Vector3.ZERO, .03)
			rbox(Vector3(0, .12, -.17), Vector3(.1, .03, .03), trim, SATIN, Vector3.ZERO, .012)
			rbox(Vector3(0, .27, -.143), Vector3(.12, .05, .004), mint, GLOW, Vector3.ZERO, .01)

## Accessories for the pegboard (decor), drawn facing -Z at the origin: a card and its goods.
func blister(kind: int, tint: String) -> void:
	var g := 1.45
	bx(Vector3(0, .15, .04) * g, Vector3(.012, .03, .06) * g, iron, SATIN)
	rbox(Vector3.ZERO, Vector3(.2, .26, .012) * g, trim, MATTE, Vector3.ZERO, .02)
	rbox(Vector3(0, .1, -.007) * g, Vector3(.14, .03, .003) * g, tint, MATTE, Vector3.ZERO, .006)
	match kind % 4:
		0:
			ring(Vector3(0, -.03, -.02) * g, Vector3(.13, .02, .13) * g, tint, SATIN, Vector3(PI / 2, 0, 0), .6, 14)
		1:
			rbox(Vector3(0, -.03, -.03) * g, Vector3(.08, .1, .05) * g, rim, SATIN, Vector3.ZERO, .02)
			bx(Vector3(-.015, .03, -.03) * g, Vector3(.008, .03, .008) * g, silver, METAL)
			bx(Vector3(.015, .03, -.03) * g, Vector3(.008, .03, .008) * g, silver, METAL)
		2:
			rbox(Vector3(0, -.03, -.02) * g, Vector3(.05, .12, .03) * g, tint, SATIN, Vector3.ZERO, .012)
			bx(Vector3(0, .045, -.02) * g, Vector3(.03, .04, .015) * g, silver, METAL)
		3:
			rbox(Vector3(0, -.03, -.03) * g, Vector3(.12, .08, .05) * g, rim, SATIN, Vector3.ZERO, .025)
			ball(Vector3(0, -.03, -.056) * g, Vector3(.015, .015, .004) * g, tint, GLOW, Vector3.ZERO, 8)
