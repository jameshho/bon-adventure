extends RefCounted
## Sports goods and sports-store fixtures in the product art style (9 Nov 2026,
## docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"). Every function draws one model into the shared
## mesh kit `supermarket_products.gd` (begin() ... finish(): one merged low-poly ArrayMesh with
## vertex colours and up to three shared finishes), so a shelf of goods costs a few draw calls.
##
## Prefab models (`tools/build_sports_props.gd` writes them into scenes/props/vocabulary/*.tscn)
## keep each prefab's old footprint: origin at the bottom centre, front facing -Z, balls 0.86
## across (the hospital and the sports store show them at scale 0.35). Store models are in
## sports-store units (one town unit; the store is scaled 1.3 by the town).

const Art := preload("res://scripts/buildings/supermarket_products.gd")
const MATTE := Art.MATTE
const SATIN := Art.SATIN
const METAL := Art.METAL

const WHITE := "f4f2ec"
const INK := "24272c"
const CHROME := "c9cfd4"
const RUBBER := "2e3236"

## A part whose local +Y points along `normal` (unit), as Euler angles for the kit.
static func facing(normal: Vector3) -> Vector3:
	return Basis(Quaternion(Vector3.UP, normal.normalized())).get_euler()

## The 12 directions of an icosahedron's vertices (the black pentagons of a soccer ball).
static func icosahedron() -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var out: Array = []
	for a in [-1.0, 1.0]:
		for b in [-t, t]:
			out.append(Vector3(0, a, b).normalized())
			out.append(Vector3(a, b, 0).normalized())
			out.append(Vector3(b, 0, a).normalized())
	return out

# ---------------------------------------------------------------- prefab models

## Soccer ball: white ball with the 12 black pentagons of the classic pattern and thin seams
## from each pentagon toward its neighbours.
static func soccer_ball(art) -> void:
	var r := .43
	var c := Vector3(0, r, 0)
	art.ball(c, Vector3.ONE * r * 2.0, WHITE, SATIN, Vector3.ZERO, 18)
	var dirs := icosahedron()
	for n in dirs:
		# A flat pentagon just under the surface, one corner (the mesh's +Z) turned toward a
		# neighbour so every corner meets a seam.
		var m: Vector3 = dirs.filter(func(o: Vector3) -> bool: return o.dot(n) > .4 and o.dot(n) < .99)[0]
		var t: Vector3 = (m - n * n.dot(m)).normalized()
		var turn := Basis(n.cross(t), n, t).get_euler()
		art.cyl(c + n * (r - .012), Vector3(.30, .03, .30), INK, SATIN, turn, 5)
	# Seams: a short thin bar from each pentagon halfway to each of its five neighbours.
	for i in dirs.size():
		for j in range(i + 1, dirs.size()):
			var a: Vector3 = dirs[i]
			var b: Vector3 = dirs[j]
			if a.dot(b) < .4:
				continue
			var mid := (a + b).normalized()
			var along := (b - a).normalized()
			var basis := Basis(along.cross(mid).normalized(), mid, -along).orthonormalized()
			art.bx(c + mid * (r + .002), Vector3(.012, .012, .2), "8d9196", MATTE, basis.get_euler())

## Basketball: orange ball, black seams (two great circles and the two curved side seams).
static func basketball(art) -> void:
	var r := .43
	var c := Vector3(0, r, 0)
	art.ball(c, Vector3.ONE * r * 2.0, "e07a2e", MATTE, Vector3.ZERO, 18)
	art.ring(c, Vector3(r * 2.03, .018, r * 2.03), INK, MATTE, Vector3(PI / 2, 0, 0), .965, 24)
	art.ring(c, Vector3(r * 2.03, .018, r * 2.03), INK, MATTE, Vector3(0, 0, 0), .965, 24)
	for side in [-1.0, 1.0]:
		var d := .24
		var small := sqrt(r * r - d * d) * 2.0 + .01
		art.ring(c + Vector3(side * d, 0, 0), Vector3(small, .018, small), INK, MATTE, Vector3(0, 0, PI / 2), .955, 20)

## Volleyball: the 18-panel pattern of a cube drawn on the ball (six faces of three strips,
## neighbouring faces' strips at right angles), dark seams on white with yellow and blue middle
## strips. Seams are short bars along arcs.
static func volleyball(art) -> void:
	var r := .43
	var c := Vector3(0, r, 0)
	art.ball(c, Vector3.ONE * r * 2.0, WHITE, SATIN, Vector3.ZERO, 18)
	var seam := "3d4148"
	var faces := [[Vector3.RIGHT, Vector3.UP], [Vector3.LEFT, Vector3.UP], [Vector3.UP, Vector3.BACK],
		[Vector3.DOWN, Vector3.BACK], [Vector3.BACK, Vector3.RIGHT], [Vector3.FORWARD, Vector3.RIGHT]]
	var k := 0
	for face in faces:
		var n: Vector3 = face[0]
		var a: Vector3 = face[1]
		var b := n.cross(a)
		# The middle strip of each face is coloured (yellow, blue alternately): bars across it.
		var tint := "f2c230" if k % 2 == 0 else "2f6fc0"
		for t in range(-4, 5):
			var p0 := (n + a * t / 4.6).normalized() * (r + .004)
			art.bx(c + p0 * (1.0 - .002 / r), Vector3(.23, .008, .1), tint, SATIN, Basis(b, p0.normalized(), b.cross(p0.normalized())).get_euler())
		# Two seams between the strips and the face's own edges along `a`.
		for s in [-1.0 / 3.0, 1.0 / 3.0, -1.0, 1.0]:
			_arc(art, c, r + .006, n + b * s, a, seam)
		k += 1

## A seam: short bars along the arc of the ball's surface through `centre` (unnormalised point
## on a cube face) running in direction `along`, from one cube edge to the other.
static func _arc(art, c: Vector3, radius: float, centre: Vector3, along: Vector3, tint: String) -> void:
	var steps := 6
	for i in steps:
		var p0 := (centre + along * (-1.0 + 2.0 * i / steps)).normalized() * radius
		var p1 := (centre + along * (-1.0 + 2.0 * (i + 1) / steps)).normalized() * radius
		var mid := (p0 + p1) * .5
		var up := mid.normalized()
		var dir := (p1 - p0).normalized()
		art.bx(c + mid, Vector3(.014, .01, (p1 - p0).length() + .006), tint, MATTE, Basis(up.cross(dir).normalized(), up, -dir).orthonormalized().get_euler())

## Tennis ball: optic yellow felt with the white curved seam (two half loops).
static func tennis_ball(art) -> void:
	var r := .25
	var c := Vector3(0, r, 0)
	art.ball(c, Vector3.ONE * r * 2.0, "d6e33f", MATTE, Vector3.ZERO, 16)
	for side in [-1.0, 1.0]:
		var d := .12
		var small := sqrt(r * r - d * d) * 2.0 + .008
		art.ring(c + Vector3(side * d, 0, 0), Vector3(small, .016, small), WHITE, MATTE, Vector3(0, 0, PI / 2), .93, 18)

## Hex dumbbell along x: knurled chrome handle, collars, black hexagonal heads with chrome
## end caps and a weight number plate.
static func dumbbell(art) -> void:
	var y := .34
	art.cyl(Vector3(0, y, 0), Vector3(.1, .62, .1), CHROME, METAL, Vector3(0, 0, PI / 2), 10)
	for k in range(-2, 3):
		art.cyl(Vector3(k * .055, y, 0), Vector3(.112, .018, .112), "9aa1a7", METAL, Vector3(0, 0, PI / 2), 10)
	for side in [-1.0, 1.0]:
		art.cyl(Vector3(side * .3, y, 0), Vector3(.17, .05, .17), CHROME, METAL, Vector3(0, 0, PI / 2), 12)
		art.cyl(Vector3(side * .43, y, 0), Vector3(.6, .24, .6), RUBBER, SATIN, Vector3(PI / 6, 0, PI / 2), 6)
		art.cyl(Vector3(side * .556, y, 0), Vector3(.2, .02, .2), CHROME, METAL, Vector3(0, 0, PI / 2), 12)
		art.bx(Vector3(side * .43, y + .15, -.258), Vector3(.12, .06, .01), "e8b04b", SATIN)

## Bicycle helmet: vented shell over a dark liner rim, short visor at the front (-Z), straps.
static func helmet(art) -> void:
	var red := "d8453a"
	art.dome(Vector3(0, .47, .02), Vector3(.76, .54, .86), red, SATIN, Vector3.ZERO, 16)
	art.cyl(Vector3(0, .21, .02), Vector3(.78, .06, .88), INK, SATIN, Vector3.ZERO, 16)
	# Vents: dark slots along the crown, front to back.
	for x in [-.13, .13]:
		for z in [-.16, .06, .26]:
			var h := .2 + sqrt(maxf(0.0, 1.0 - pow(x / .38, 2) - pow((z - .02) / .43, 2))) * .54 - .012
			art.bx(Vector3(x, h, z), Vector3(.06, .02, .12), INK, MATTE, Vector3(-(z - .02) * 1.4, 0, x * 2.2))
	# White racing stripe and the visor.
	art.bx(Vector3(0, .735, .02), Vector3(.05, .02, .14), WHITE, SATIN)
	art.bx(Vector3(0, .25, -.43), Vector3(.5, .03, .14), INK, SATIN, Vector3(.35, 0, 0))
	for side in [-1.0, 1.0]:
		art.bx(Vector3(side * .3, .08, .0), Vector3(.025, .26, .025), INK, MATTE, Vector3(0, 0, side * .25))
	art.bx(Vector3(0, -.03, -.02), Vector3(.12, .04, .05), INK, MATTE)

## A pair of running sneakers side by side, toes toward -Z: sole with a white midsole, coloured
## upper with a swoosh panel, white laces and a heel tab.
static func sneakers(art, upper := "3a74c4", accent := "f4f2ec") -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * .2
		art.bx(Vector3(x, .025, 0), Vector3(.3, .05, .66), "3b3f45", MATTE)
		art.bx(Vector3(x, .07, 0), Vector3(.29, .05, .64), WHITE, MATTE)
		art.ball(Vector3(x, .07, -.3), Vector3(.29, .1, .12), WHITE, MATTE)
		# Upper: low toe box rising to the ankle collar at the heel.
		art.bx(Vector3(x, .15, .1), Vector3(.27, .14, .42), upper, MATTE)
		art.ball(Vector3(x, .12, -.18), Vector3(.27, .14, .28), upper, MATTE)
		art.bx(Vector3(x, .23, .2), Vector3(.25, .07, .22), upper, MATTE)
		art.bx(Vector3(x, .245, .3), Vector3(.18, .12, .04), "3b3f45", MATTE)
		art.bx(Vector3(x, .195, .11), Vector3(.13, .03, .18), INK, MATTE)
		for k in 3:
			art.bx(Vector3(x, .215, -.02 + k * .06), Vector3(.15, .015, .02), WHITE, MATTE)
		art.bx(Vector3(x + side * .137, .14, .04), Vector3(.01, .05, .3), accent, SATIN, Vector3(.3, 0, 0))

# ---------------------------------------------------------------- store models
# Store units (one town unit = 1.3 m); bottoms on y = 0, fronts toward -Z unless stated.

## A shop mannequin (no head detail, matte grey) standing on a round base; dressed parts are
## separate word roots placed over it.
static func mannequin(art) -> void:
	var skin := "dcd6cc"
	art.cyl(Vector3(0, .02, 0), Vector3(.5, .04, .5), "8a9096", SATIN, Vector3.ZERO, 16)
	art.cyl(Vector3(0, .3, 0), Vector3(.04, .56, .04), CHROME, METAL, Vector3.ZERO, 8)
	for side in [-1.0, 1.0]:
		art.cyl(Vector3(side * .1, .82, 0), Vector3(.13, .66, .14), skin, MATTE, Vector3.ZERO, 10, .8)
	art.cyl(Vector3(0, 1.38, 0), Vector3(.42, .56, .24), skin, MATTE, Vector3.ZERO, 12, .78)
	for side in [-1.0, 1.0]:
		art.cyl(Vector3(side * .26, 1.32, 0), Vector3(.09, .52, .09), skin, MATTE, Vector3(0, 0, side * .12), 8)
	art.cyl(Vector3(0, 1.72, 0), Vector3(.1, .1, .1), skin, MATTE, Vector3.ZERO, 8)
	art.ball(Vector3(0, 1.88, 0), Vector3(.22, .27, .24), skin, MATTE, Vector3.ZERO, 12)

## A water bottle: tinted body, white band, sport cap.
static func water_bottle(art, tint: String) -> void:
	art.cyl(Vector3(0, .12, 0), Vector3(.1, .24, .1), tint, SATIN, Vector3.ZERO, 10)
	art.cyl(Vector3(0, .12, 0), Vector3(.104, .06, .104), WHITE, MATTE, Vector3.ZERO, 10)
	art.cyl(Vector3(0, .255, 0), Vector3(.08, .03, .08), RUBBER, SATIN, Vector3.ZERO, 10)
	art.cyl(Vector3(0, .285, 0), Vector3(.035, .04, .035), WHITE, SATIN, Vector3.ZERO, 8)

## A backpack standing upright, straps at the back (+Z).
static func backpack(art, tint: String) -> void:
	var dark := Color(tint).darkened(.3).to_html(false)
	art.bx(Vector3(0, .26, 0), Vector3(.4, .48, .2), tint, MATTE)
	art.ball(Vector3(0, .5, 0), Vector3(.4, .12, .2), tint, MATTE)
	art.bx(Vector3(0, .17, -.12), Vector3(.3, .22, .06), dark, MATTE)
	art.bx(Vector3(0, .29, -.152), Vector3(.24, .012, .006), CHROME, METAL)
	art.bx(Vector3(0, .5, -.09), Vector3(.3, .012, .03), CHROME, METAL)
	for side in [-1.0, 1.0]:
		art.bx(Vector3(side * .12, .3, .115), Vector3(.06, .42, .03), dark, MATTE)
	art.ring(Vector3(0, .57, .02), Vector3(.08, .03, .08), dark, MATTE, Vector3(PI / 2, 0, 0), .5, 8)

## Skis: a pair standing upright (tips up, curved at the top), bindings at hand height.
static func skis(art, tint: String) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * .07
		art.bx(Vector3(x, .78, 0), Vector3(.09, 1.5, .025), tint, SATIN)
		art.bx(Vector3(x, 1.56, -.02), Vector3(.09, .12, .02), tint, SATIN, Vector3(.45, 0, 0))
		art.bx(Vector3(x, .75, -.02), Vector3(.07, .16, .05), INK, SATIN)
		art.bx(Vector3(x, .4, -.015), Vector3(.06, .3, .006), WHITE, MATTE)

## Two ski poles leaning together: shafts, grips with straps, baskets near the tips.
static func ski_poles(art, tint: String) -> void:
	for side in [-1.0, 1.0]:
		var lean: Vector3 = Vector3(0, 0, side * .06)
		art.cyl(Vector3(side * .04, .62, 0), Vector3(.025, 1.22, .025), CHROME, METAL, lean, 6)
		art.cyl(Vector3(side * .075, 1.22, 0), Vector3(.05, .18, .05), tint, SATIN, lean, 8)
		art.cyl(Vector3(side * .012, .14, 0), Vector3(.13, .015, .13), RUBBER, SATIN, lean, 10)

## A snowboard standing on its tail, binding straps on the face (-Z).
static func snowboard(art, tint: String, accent: String) -> void:
	art.bx(Vector3(0, .72, 0), Vector3(.3, 1.3, .03), tint, SATIN)
	art.cyl(Vector3(0, 1.37, 0), Vector3(.3, .03, .14), tint, SATIN, Vector3(PI / 2, 0, 0), 12)
	art.cyl(Vector3(0, .07, 0), Vector3(.3, .03, .14), tint, SATIN, Vector3(PI / 2, 0, 0), 12)
	art.bx(Vector3(0, .72, -.017), Vector3(.12, .9, .006), accent, MATTE)
	for y in [.45, 1.0]:
		art.bx(Vector3(0, y, -.04), Vector3(.24, .06, .05), INK, SATIN)

## A pair of ski boots: shell, buckles, cuff.
static func ski_boots(art, tint: String) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * .12
		art.bx(Vector3(x, .03, 0), Vector3(.18, .06, .34), INK, SATIN)
		art.bx(Vector3(x, .14, -.02), Vector3(.17, .16, .3), tint, SATIN)
		art.bx(Vector3(x, .3, .05), Vector3(.17, .22, .2), tint, SATIN)
		for y in [.17, .27, .36]:
			art.bx(Vector3(x, y, -.054 if y < .2 else -.051), Vector3(.12, .02, .01), CHROME, METAL)

## A pair of gloves lying flat, fingers toward -Z.
static func gloves(art, tint: String) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * .11
		art.bx(Vector3(x, .025, .05), Vector3(.16, .05, .18), tint, MATTE)
		art.bx(Vector3(x, .03, .16), Vector3(.17, .06, .07), INK, MATTE)
		for k in 4:
			art.bx(Vector3(x - .055 + k * .037, .02, -.08), Vector3(.032, .04, .1), tint, MATTE)
		art.bx(Vector3(x + side * .095, .02, .01), Vector3(.04, .035, .09), tint, MATTE, Vector3(0, side * .5, 0))

## A knitted winter hat with a pompom and a folded band.
static func winter_hat(art, tint: String, band: String) -> void:
	art.dome(Vector3(0, .06, 0), Vector3(.26, .3, .26), tint, MATTE, Vector3.ZERO, 12)
	art.cyl(Vector3(0, .05, 0), Vector3(.275, .1, .275), band, MATTE, Vector3.ZERO, 12)
	art.ball(Vector3(0, .23, 0), Vector3(.1, .1, .1), WHITE, MATTE, Vector3.ZERO, 8)

## Ski goggles: wide mirrored lens in a frame, strap behind, facing -Z.
static func goggles(art, frame: String) -> void:
	art.bx(Vector3(0, .07, 0), Vector3(.3, .13, .06), frame, SATIN)
	art.bx(Vector3(0, .07, -.032), Vector3(.26, .1, .01), "e08a3a", METAL)
	art.bx(Vector3(0, .07, .06), Vector3(.32, .05, .1), INK, MATTE)

## A sled: two runners with curled fronts, a wooden slatted deck and a rope loop.
static func sled(art) -> void:
	for side in [-1.0, 1.0]:
		art.bx(Vector3(side * .24, .04, .05), Vector3(.04, .04, 1.0), "c3352c", SATIN)
		art.ring(Vector3(side * .24, .12, -.47), Vector3(.04, .2, .2), "c3352c", SATIN, Vector3(0, 0, PI / 2), .6, 10)
		for z in [-.25, .15, .45]:
			art.bx(Vector3(side * .24, .1, z), Vector3(.03, .1, .03), "c3352c", SATIN)
	for k in 5:
		art.bx(Vector3(0, .16, -.25 + k * .17), Vector3(.6, .03, .13), "c58a4e", MATTE)
	art.ring(Vector3(0, .2, -.55), Vector3(.3, .02, .16), "e8d9b0", MATTE, Vector3.ZERO, .8, 10)
