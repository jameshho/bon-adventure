extends RefCounted
## Low-poly product-art models for the furniture vocabulary prefabs (9 Nov 2026,
## docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"); drawn with the supermarket mesh kit
## (scripts/buildings/supermarket_products.gd) and written into the prefabs by
## tools/build_furniture_props.gd. Each model keeps its prefab's old outer size (prefab units:
## origin at the bottom centre, front -Z, back +Z). PARTS lists each prefab's meshes: "Model"
## is the body; seat words keep their seat as its own low mesh ("Seat", "Cushion ..."), and the
## bed keeps "Mattress" and "Headboard", so the seating controller still finds where to sit
## or lie.
const Art := preload("res://scripts/buildings/supermarket_products.gd")
const MATTE := Art.MATTE
const SATIN := Art.SATIN
const METAL := Art.METAL

const WOOD := "ad7b50"
const WOOD_LIGHT := "c79968"
const WOOD_DARK := "7a5232"
const CLOTH := "467a9b"
const CLOTH_LIGHT := "6e9cb4"
const CLOTH_DARK := "345f7a"
const LINEN := "eeebe4"
const HANDLE := "2b3640"
const BRASS := "c9a24a"

## Tapered round wooden leg standing on the floor.
static func leg(art, x: float, z: float, height: float, width := .06, tint := WOOD_DARK) -> void:
	art.cyl(Vector3(x, height * .5, z), Vector3(width, height, width), tint, SATIN, Vector3.ZERO, 8, .7)

## A padded block with rounded top edges along x (rolls at the front and back top edges).
static func pad(art, c: Vector3, s: Vector3, tint: String, tilt := 0.0) -> void:
	var r := Vector3(tilt, 0, 0)
	art.bx(c, Vector3(s.x, s.y - .06, s.z), tint, MATTE, r)
	art.bx(c + Vector3(0, s.y * .5 - .04, 0).rotated(Vector3.RIGHT, tilt), Vector3(s.x - .04, .08, s.z - .06), tint, MATTE, r)

## prefab -> {mesh name: drawing function}
const PARTS := {
	"sofa": {"Model": "sofa_model", "Cushion left": "sofa_cushion_left", "Cushion middle": "sofa_cushion_middle", "Cushion right": "sofa_cushion_right"},
	"armchair": {"Model": "armchair_model", "Seat": "armchair_seat"},
	"bed": {"Model": "bed_model", "Mattress": "bed_mattress", "Headboard": "bed_headboard"},
	"wardrobe": {"Model": "wardrobe_model"},
	"dresser": {"Model": "dresser_model"},
	"nightstand": {"Model": "nightstand_model"},
	"dining_table": {"Model": "dining_table_model"},
	"coffee_table": {"Model": "coffee_table_model"},
	"bench": {"Model": "bench_model", "Seat": "bench_seat"},
	"stool": {"Model": "stool_model"},
}

static func _seat_cushion(art, c: Vector3, s: Vector3, tint := CLOTH_LIGHT) -> void:
	art.bx(c + Vector3(0, 0, .04), Vector3(s.x, s.y, s.z - .08), tint, MATTE)
	art.cyl(c + Vector3(0, 0, -s.z * .5 + .06), Vector3(s.y, s.x, .14), tint, MATTE, Vector3(0, 0, PI / 2), 10)

static func sofa_model(art) -> void:
	for x in [-1.1, 1.1]:
		for z in [-.36, .36]:
			leg(art, x, z, .14)
	art.bx(Vector3(0, .27, .02), Vector3(2.36, .26, .9), CLOTH, MATTE)
	art.bx(Vector3(0, .15, -.43), Vector3(2.3, .03, .02), CLOTH_DARK, MATTE)
	pad(art, Vector3(0, .74, .37), Vector3(2.4, .74, .2), CLOTH, -.1)
	for x in [-.72, 0.0, .72]:
		pad(art, Vector3(x, .8, .22), Vector3(.68, .46, .16), CLOTH_LIGHT, -.16)
	for side in [-1.0, 1.0]:
		art.bx(Vector3(side * 1.15, .48, .0), Vector3(.2, .44, .92), CLOTH, MATTE)
		art.cyl(Vector3(side * 1.15, .7, 0), Vector3(.22, .92, .1), CLOTH, MATTE, Vector3(PI / 2, 0, 0), 10)

static func sofa_cushion_left(art) -> void:
	_seat_cushion(art, Vector3(-.72, .5, -.08), Vector3(.7, .2, .72))

static func sofa_cushion_middle(art) -> void:
	_seat_cushion(art, Vector3(0, .5, -.08), Vector3(.7, .2, .72))

static func sofa_cushion_right(art) -> void:
	_seat_cushion(art, Vector3(.72, .5, -.08), Vector3(.7, .2, .72))

static func armchair_model(art) -> void:
	for x in [-.36, .36]:
		for z in [-.33, .33]:
			leg(art, x, z, .16)
	art.bx(Vector3(0, .3, .02), Vector3(.9, .28, .82), CLOTH, MATTE)
	pad(art, Vector3(0, .82, .34), Vector3(.9, .76, .18), CLOTH, -.1)
	pad(art, Vector3(0, .86, .21), Vector3(.6, .46, .14), CLOTH_LIGHT, -.16)
	for side in [-1.0, 1.0]:
		art.bx(Vector3(side * .42, .52, 0), Vector3(.16, .4, .84), CLOTH, MATTE)
		art.cyl(Vector3(side * .42, .73, 0), Vector3(.18, .84, .08), CLOTH, MATTE, Vector3(PI / 2, 0, 0), 10)

static func armchair_seat(art) -> void:
	_seat_cushion(art, Vector3(0, .51, -.06), Vector3(.66, .18, .68))

static func bed_model(art) -> void:
	for x in [-.8, .8]:
		for z in [-1.24, 1.2]:
			leg(art, x, z, .2, .09)
	art.bx(Vector3(0, .3, 0), Vector3(1.8, .22, 2.62), WOOD, SATIN)
	art.bx(Vector3(0, .3, -1.31), Vector3(1.84, .26, .06), WOOD_DARK, SATIN)
	art.bx(Vector3(0, .5, -1.32), Vector3(1.84, .14, .06), WOOD, SATIN)

static func bed_mattress(art) -> void:
	art.bx(Vector3(0, .52, -.03), Vector3(1.68, .26, 2.46), LINEN, MATTE)
	art.bx(Vector3(0, .64, -.03), Vector3(1.6, .04, 2.38), "f7f5f0", MATTE)

static func bed_headboard(art) -> void:
	art.bx(Vector3(0, .82, 1.3), Vector3(1.9, 1.24, .1), WOOD, SATIN)
	art.bx(Vector3(0, 1.46, 1.3), Vector3(1.96, .06, .14), WOOD_DARK, SATIN)
	pad(art, Vector3(0, 1.0, 1.23), Vector3(1.6, .66, .06), CLOTH, 0.0)

static func wardrobe_model(art) -> void:
	art.bx(Vector3(0, 1.2, .02), Vector3(1.7, 2.24, .68), WOOD, SATIN)
	art.bx(Vector3(0, .05, 0), Vector3(1.66, .1, .64), WOOD_DARK, SATIN)
	art.bx(Vector3(0, 2.33, 0), Vector3(1.76, .06, .76), WOOD_DARK, SATIN)
	for side in [-1.0, 1.0]:
		var x: float = side * .42
		art.bx(Vector3(x, 1.2, -.33), Vector3(.8, 2.14, .04), WOOD_LIGHT, SATIN)
		art.bx(Vector3(x, 1.62, -.355), Vector3(.62, .9, .015), WOOD, SATIN)
		art.bx(Vector3(x, .62, -.355), Vector3(.62, .76, .015), WOOD, SATIN)
		art.cyl(Vector3(side * .07, 1.2, -.38), Vector3(.025, .36, .025), BRASS, METAL, Vector3.ZERO, 8)
		art.bx(Vector3(side * .07, 1.32, -.36), Vector3(.02, .02, .04), BRASS, METAL)
		art.bx(Vector3(side * .07, 1.08, -.36), Vector3(.02, .02, .04), BRASS, METAL)

static func dresser_model(art) -> void:
	for x in [-.52, .52]:
		for z in [-.24, .24]:
			leg(art, x, z, .12, .07)
	art.bx(Vector3(0, .62, .02), Vector3(1.16, 1.0, .6), WOOD, SATIN)
	art.bx(Vector3(0, 1.15, 0), Vector3(1.25, .05, .7), WOOD_DARK, SATIN)
	for k in 3:
		var y := .3 + k * .32
		art.bx(Vector3(0, y, -.3), Vector3(1.08, .28, .03), WOOD_LIGHT, SATIN)
		art.bx(Vector3(0, y, -.318), Vector3(.96, .2, .01), WOOD, SATIN)
		for x in [-.26, .26]:
			art.ball(Vector3(x, y, -.34), Vector3(.05, .05, .04), BRASS, METAL, Vector3.ZERO, 8)

static func nightstand_model(art) -> void:
	for x in [-.34, .34]:
		for z in [-.24, .24]:
			leg(art, x, z, .16, .06)
	art.bx(Vector3(0, .44, .02), Vector3(.76, .56, .56), WOOD, SATIN)
	art.bx(Vector3(0, .75, 0), Vector3(.82, .05, .64), WOOD_DARK, SATIN)
	art.bx(Vector3(0, .58, -.27), Vector3(.68, .2, .03), WOOD_LIGHT, SATIN)
	art.ball(Vector3(0, .58, -.3), Vector3(.05, .05, .04), BRASS, METAL, Vector3.ZERO, 8)
	art.bx(Vector3(0, .3, -.24), Vector3(.68, .24, .06), WOOD_DARK, MATTE)
	art.bx(Vector3(0, .19, -.26), Vector3(.7, .03, .03), WOOD, SATIN)

static func dining_table_model(art) -> void:
	for x in [-.78, .78]:
		for z in [-.48, .48]:
			leg(art, x, z, .78, .09)
	art.bx(Vector3(0, .71, 0), Vector3(1.6, .1, 1.0), WOOD_DARK, SATIN)
	art.bx(Vector3(0, .8, 0), Vector3(1.8, .06, 1.2), WOOD, SATIN)
	art.bx(Vector3(0, .835, 0), Vector3(1.7, .01, 1.1), WOOD_LIGHT, SATIN)

static func coffee_table_model(art) -> void:
	for x in [-.56, .56]:
		for z in [-.28, .28]:
			leg(art, x, z, .4, .07)
	art.bx(Vector3(0, .14, 0), Vector3(1.16, .03, .6), WOOD_DARK, SATIN)
	art.bx(Vector3(0, .42, 0), Vector3(1.3, .06, .75), WOOD, SATIN)
	art.bx(Vector3(0, .452, 0), Vector3(1.2, .006, .65), WOOD_LIGHT, SATIN)

static func bench_model(art) -> void:
	for x in [-.7, .7]:
		for z in [-.24, .24]:
			leg(art, x, z, .42, .08)
		art.bx(Vector3(x, .25, 0), Vector3(.05, .05, .5), WOOD_DARK, SATIN)
		art.bx(Vector3(x, .78, .28), Vector3(.07, .62, .06), WOOD_DARK, SATIN, Vector3(-.12, 0, 0))
	for k in 3:
		art.bx(Vector3(0, .66 + k * .14, .3 - k * .017), Vector3(1.6, .09, .03), WOOD, SATIN, Vector3(-.12, 0, 0))

static func bench_seat(art) -> void:
	for k in 5:
		art.bx(Vector3(0, .45, -.26 + k * .13), Vector3(1.6, .05, .11), WOOD, SATIN)

static func stool_model(art) -> void:
	for k in 4:
		var a := PI / 4 + k * PI / 2
		art.cyl(Vector3(cos(a) * .2, .34, sin(a) * .2), Vector3(.05, .7, .05), WOOD_DARK, SATIN, Vector3(sin(a) * .08, 0, -cos(a) * .08), 8)
	art.ring(Vector3(0, .24, 0), Vector3(.5, .03, .5), WOOD_DARK, SATIN, Vector3.ZERO, .86, 16)
	art.cyl(Vector3(0, .7, 0), Vector3(.84, .08, .84), WOOD, SATIN, Vector3.ZERO, 18)
	art.cyl(Vector3(0, .745, 0), Vector3(.76, .012, .76), WOOD_LIGHT, SATIN, Vector3.ZERO, 18)
