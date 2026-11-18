extends "res://scripts/characters/capybara_clay.gd"
## Clay-style horse traced from the user's "Horse Character Blueprint" turnaround (17 Nov 2026,
## "Relaxed Idle Pose": front 3/4, front, side, back, rear 3/4). A static display model, built
## once by tools/build_horse_clay.gd into scenes/animals/horse_clay.tscn.
##
## Built like the clay capybara (capybara_clay.gd, whose loft, surface ray and mesh helpers it
## reuses): the sheet was traced with vtracer first (docs/evidence/horse-clay-20261117/), and the
## torso, the neck and the head are each ONE lofted mass (cross-sections along a line, joined
## by smooth curves), run together with the legs into one fused mesh.
## Shapes are written in the sheet's pixels (side view: x to the right = toward the tail, y
## down; z lateral, from the front and back views) and _pt() scales them into the lion's
## working space. Meshed H_FINE times larger than life and shrunk afterwards.
## Ready for rigging: "Body" is one fused mesh (torso, neck, head, legs, hooves, ears) with the
## cream muzzle, the blaze, the socks, the dark hooves and the ears' pink painted on; "Mane" and
## "Tail" are separate pieces; each eye is its own mesh centred on its own node (LeftEye,
## RightEye: y up the eye, z out of the face); lids, brows, nostrils and the mouth are
## "Face details".
## Output faces -Z (head), +Y up, ground at y = 0.

const H_HEIGHT := 1.9           # town units to the ear tips (provisional: the zoo horse's species height)
const H_GY := 578.0             # sheet y of the soles
const H_TOP := 131.0            # sheet y of the ear tips
const H_X := 972.0              # sheet x placed at the model origin
const H_FINE := 2.0             # meshed this many times larger than life
const HK := H_FINE * H_HEIGHT / ((H_GY - H_TOP) * S)

# Colours read from the sheet (coat d37e3f-dc8f54, mane and tail 734121-804a29, muzzle and socks
# f7cfaa, hooves about 5e3a22), the coat a little deeper so it holds under the town's daylight.
const H_COAT := Color("c57c48")
const H_COAT_CREASE := Color("b06834")
const H_MANE := Color("73411f")
const H_MANE_CREASE := Color("57301a")
const H_CREAM := Color("f2c8a0")
const H_HOOF := Color("5a361f")
const H_EAR_IN := Color("f3a590")
const H_BROW := Color("8a4d23")
const H_LID := Color("2a150b")
const H_SCLERA := Color("fbeedd")
const H_IRIS := Color("4a2410")
const H_PUPIL := Color("170b05")
const H_GLINT := Color("fffdf8")
const H_NOSTRIL := Color("c7866a")
const H_LINE := Color("8a4a24")

## Torso sections: [sheet x, top y, bottom y, widest y, half width, upper squareness, lower squareness].
const H_TORSO := [
	[826.0, 314.0, 398.0, 354.0, 46.0, 2.0, 2.0],
	[858.0, 304.0, 412.0, 358.0, 57.0, 2.0, 2.1],
	[900.0, 301.5, 418.0, 362.0, 61.0, 2.0, 2.2],
	[940.0, 302.5, 417.0, 362.0, 59.0, 2.0, 2.2],
	[980.0, 304.5, 406.0, 358.0, 58.0, 2.0, 2.2],
	[1020.0, 304.5, 405.0, 357.0, 61.0, 2.0, 2.1],
	[1050.0, 303.0, 412.0, 360.0, 64.0, 2.0, 2.1],
	[1072.0, 307.0, 416.0, 364.0, 62.0, 2.0, 2.0],
	[1088.0, 318.0, 418.0, 368.0, 56.0, 2.0, 2.0]]
## (The last two sections lie inside the torso, so the neck has no end on the surface.)
## Neck sections, running straight down the sheet (axis 90 degrees): [sheet y, -(x of the crest),
## -(x of the throat), -(x where it is widest), half width, squareness toward the crest, toward the throat].
const H_NECK := [
	[186.0, -872.0, -836.0, -856.0, 32.0, 2.0, 2.0],
	[220.0, -888.0, -836.0, -864.0, 35.0, 2.0, 2.0],
	[255.0, -906.0, -832.0, -872.0, 38.0, 2.0, 2.0],
	[290.0, -926.0, -826.0, -880.0, 42.0, 2.0, 2.0],
	[322.0, -944.0, -825.0, -888.0, 44.0, 2.0, 2.0],
	[352.0, -954.0, -832.0, -894.0, 46.0, 2.0, 2.0],
	[385.0, -946.0, -846.0, -896.0, 38.0, 2.0, 2.0],
	[408.0, -936.0, -858.0, -897.0, 26.0, 2.0, 2.0]]
## Head sections, rebuilt from a finer trace of the sheet that keeps the cream muzzle apart
## from the background (user, 17 Nov 2026: the first head was too long, flat and angular).
## Side view: a short round muzzle whose top slopes up at about 45 degrees to the foot of the
## face, a face that stands almost upright above it and rounds over into the crown, a level
## jaw behind a chin that hangs a little below it. Front view: full cheeks (squarer lower
## half), nearly as wide as the crown. Over the muzzle the face's upper half is drawn in
## (low squareness), a wedge seen from above, so the eyes on it show from the front and side.
const H_HEAD := [
	[713.0, 248.0, 280.0, 265.0, 34.0, 2.2, 2.0],
	[728.0, 246.0, 286.0, 268.0, 39.5, 2.2, 2.0],
	[738.0, 241.0, 293.0, 270.0, 42.0, 2.2, 2.1],
	[747.0, 236.0, 300.0, 272.0, 43.0, 2.0, 2.2],
	[750.0, 222.0, 301.0, 272.0, 43.0, 1.5, 2.3],
	[753.0, 208.0, 301.0, 271.0, 43.0, 1.3, 2.3],
	[758.0, 195.0, 301.0, 269.0, 43.0, 1.25, 2.3],
	[766.0, 184.0, 295.0, 262.0, 43.5, 1.4, 2.4],
	[778.0, 176.0, 286.0, 252.0, 45.0, 1.75, 2.8],
	[793.0, 171.0, 281.0, 244.0, 47.0, 2.2, 3.0],
	[811.0, 168.0, 280.0, 239.0, 47.5, 2.4, 3.0],
	[832.0, 168.0, 278.0, 234.0, 47.5, 2.4, 2.8],
	[850.0, 172.0, 268.0, 226.0, 46.0, 2.3, 2.4],
	[866.0, 181.0, 256.0, 220.0, 41.0, 2.1, 2.1],
	[876.0, 196.0, 244.0, 217.0, 32.0, 2.0, 2.0]]

const H_EYE_AT := Vector2(770.0, 231.0)   # side view: middle of the eye
const H_EYE_R := Vector2(12.4, 13.2)      # half width, half height on the skin
const H_SOCK_Y := 496.0                   # the cream socks start here
const H_HOOF_Y := 553.0                   # the dark hooves start here
## The cream muzzle's back edge in the side view: [sheet y, sheet x].
const H_MUZZLE_EDGE := [[230.0, 741.0], [242.0, 750.0], [256.0, 761.0], [270.0, 773.0], [281.0, 779.0], [292.0, 774.0], [304.0, 765.0]]
## The blaze's half width down the face: [sheet y, half width].
const H_BLAZE := [[170.0, 5.5], [200.0, 6.5], [226.0, 7.5], [240.0, 9.5], [250.0, 14.0], [258.0, 23.0], [268.0, 38.0]]
const H_FRONT_Z := 24.5
const H_HIND_Z := 33.5

var _tail := []


func _init() -> void:
	_px = HK
	_ox = H_X
	_gy = H_GY
	_fine = H_FINE
	# The sheet's side view is turned about 20 degrees toward the viewer (the far ear and the far
	# hind leg stand about 30 px ahead of the near ones), so it shows the horse about 4% short.
	_stretch = 1.04


func he(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * _px, col, k * _px, crease, basis)


func hc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * _px, rb * _px, col, k * _px)


## A basis turned `deg` about the lateral axis: x along a line that many degrees below the
## sheet's x (toward the tail), y across it, z lateral.
static func _lean(deg: float) -> Basis:
	var a := deg_to_rad(deg)
	return Basis(Vector3(cos(a), -sin(a), 0), Vector3(sin(a), cos(a), 0), Vector3(0, 0, 1))


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	loft(b, H_TORSO, Vector2(26.0, 26.0), H_COAT)
	# Legs: straight, round, a little tapered columns under a full shoulder and haunch.
	for side in [-1.0, 1.0]:
		var z: float = side * H_FRONT_Z
		he(b, _pt(874, 372, side * 26.0), Vector3(34, 36, 30), H_COAT, 30.0)                 # shoulder
		hc(b, _pt(877, 400, z), _pt(876, 458, z), 28.0, 21.5, H_COAT, 26.0)
		hc(b, _pt(876, 458, z), _pt(875, 548, z), 21.5, 20.0, H_COAT, 8.0)
		he(b, _pt(869, 562, z), Vector3(27, 18, 22), H_COAT, 5.0)                           # hoof
		var o := -12.0      # both hind legs stand here; the sheet's stagger is its turned view
		var hz: float = side * H_HIND_Z
		he(b, _pt(1034, 384, side * 25.0), Vector3(47, 52, 34), H_COAT, 30.0)                # haunch
		hc(b, _pt(1042 + o * 0.5, 426, hz), _pt(1061 + o, 492, hz), 28.0, 16.0, H_COAT, 24.0)
		hc(b, _pt(1061 + o, 492, hz), _pt(1062 + o, 548, hz), 16.0, 15.5, H_COAT, 6.0)
		he(b, _pt(1055 + o, 562, hz), Vector3(24, 18, 19), H_COAT, 5.0)
	carve(b, _pt(960, H_GY + 59.0), Vector3(700, 60, 500) * _px, H_HOOF)
	# Neck, then the head on it.
	loft(b, H_NECK, Vector2(10.0, 10.0), H_COAT, 38.0, Vector3(0, 0, 90.0))
	loft(b, H_HEAD, Vector2(14.0, 12.0), H_COAT, 14.0)
	# Ears: tall pointed leaves on the top corners of the skull, leaning outward, open to the
	# front and a little outward; a pink hollow inside a coat-coloured rim.
	for side in [-1.0, 1.0]:
		var base := _pt(818, 190, side * 33.0)
		var tip := _pt(810, 133, side * 44.5)
		var along := (tip - base).normalized()
		var open := Vector3(-0.8, 0.0, side * 0.6)
		open = (open - along * open.dot(along)).normalized()
		var basis := Basis(open, along, open.cross(along))
		var mid := base.lerp(tip, 0.46)
		var blade := {"t": "ell", "c": mid, "r": Vector3(8.0, 27.0, 15.5) * _px, "inv": basis.inverse()}
		var point := {"t": "cone", "a": mid, "b": tip - along * 3.0 * _px, "ra": 11.0 * _px, "rb": 3.0 * _px}
		var hollow_c := mid + open * 6.5 * _px + along * 1.0 * _px
		var hollow := {"t": "ell", "c": hollow_c, "r": Vector3(6.0, 21.0, 9.5) * _px, "inv": basis.inverse()}
		var reach: float = 34.0 * _px
		b.append({"t": "fn", "fn": func(p: Vector3) -> float:
				var d1 := _dist(blade, p)
				var d2 := _dist(point, p)
				var kk := 6.0 * _px
				var h := maxf(kk - absf(d1 - d2), 0.0) / kk
				return maxf(minf(d1, d2) - h * h * kk * 0.25, -_dist(hollow, p)),
				"lo": mid - Vector3.ONE * reach, "hi": mid + Vector3.ONE * reach, "k": 6.0 * _px, "col": H_COAT, "crease": false, "paint": false})
		_tints.append({"t": "ell", "c": hollow_c, "r": Vector3(7.5, 22.0, 10.5) * _px, "inv": basis.inverse(), "col": H_EAR_IN, "soft": CELL * 0.6})

	# Eye sockets: a shallow round dish pressed into the face under each eye, so the eyes sit
	# in the head (found on the finished head, then pressed in; a soft shade round the rim).
	var sockets := []
	for side in [-1.0, 1.0]:
		var hit := _ray(b, _pt(H_EYE_AT.x, H_EYE_AT.y, side * 160.0), Vector3(0, 0, -side))
		sockets.append(hit)
	for hit in sockets:
		var hn: Vector3 = hit[1]
		carve(b, hit[0] + hn * (34.0 - 3.2) * _px, Vector3.ONE * 34.0 * _px, H_COAT)
		_tint(hit[0], Vector3.ONE * 17.5 * _px, Basis(), H_COAT.darkened(0.1), CELL * 2.2)

	# Mane: soft overlapping lobes down the crest of the neck, each with a lock hanging on
	# either side, and a forelock between the ears that falls forward over the forehead.
	var m := _mane
	# A low ridge down the crest, and on it and on both sides of the neck a row of locks: flat
	# pointed leaves lying down and back, each over the next, their tips standing off the
	# mane's back edge as on the sheet.
	for lobe in [[856.0, 181.0, 44.0], [876.0, 204.0, 52.0], [896.0, 232.0, 54.0], [913.0, 260.0, 54.0], [931.0, 286.0, 46.0]]:
		he(m, _pt(lobe[0], lobe[1]), Vector3(30, 10, 24), H_MANE, 8.0, false, _lean(lobe[2]))
	# [root x, root y, tip x, tip y, half width, distance from the middle (0 = on the crest), half thickness]
	for lock in [[854.0, 166.0, 908.0, 206.0, 12.0, 0.0, 15.0], [868.0, 186.0, 927.0, 236.0, 13.0, 0.0, 16.0],
			[884.0, 213.0, 943.0, 266.0, 13.0, 0.0, 16.0], [900.0, 241.0, 957.0, 292.0, 13.0, 0.0, 15.0], [917.0, 268.0, 964.0, 308.0, 11.0, 0.0, 13.0],
			[850.0, 180.0, 896.0, 226.0, 11.0, 24.0, 8.0], [862.0, 203.0, 912.0, 256.0, 12.0, 28.0, 8.5],
			[877.0, 230.0, 928.0, 285.0, 12.0, 31.0, 8.5], [893.0, 258.0, 943.0, 306.0, 11.0, 33.0, 8.0]]:
		var root := Vector2(lock[0], lock[1])
		var run := Vector2(lock[2], lock[3]) - root
		var length := run.length()
		var hw: float = lock[4]
		# The loft's own x runs from the root to the tip; its "top" is the side toward the crest.
		loft(m, [[root.x, root.y - hw * 0.75, root.y + hw * 0.75, root.y, lock[6] * 0.85, 2.0, 2.0],
				[root.x + length * 0.4, root.y - hw, root.y + hw, root.y, lock[6], 2.0, 2.0],
				[root.x + length * 0.75, root.y - hw * 0.8, root.y + hw * 0.8, root.y, lock[6] * 0.8, 2.0, 2.0],
				[root.x + length, root.y - hw * 0.5, root.y + hw * 0.5, root.y, lock[6] * 0.5, 2.0, 2.0]],
				Vector2(8.0, length * 0.3), H_MANE, 3.0, Vector3(root.x, root.y, rad_to_deg(run.angle())), lock[5], true)
	# Forelock: a knot between the ears, a soft cap on the forehead and three locks hanging
	# from it, the middle one longest.
	he(m, _pt(834, 157), Vector3(15, 11, 16), H_MANE, 0.0, true)
	he(m, _pt(811, 160), Vector3(24, 12, 27), H_MANE, 8.0, false, _lean(-10.0))
	he(m, _pt(786, 171, 11.0), Vector3(18, 9, 11.5), H_MANE, 6.0, true, _lean(-38.0))
	he(m, _pt(781, 174, -11.0), Vector3(21, 9.5, 12.5), H_MANE, 6.0, true, _lean(-42.0))
	he(m, _pt(770, 184, -2.0), Vector3(19, 8.5, 10.5), H_MANE, 6.0, true, _lean(-50.0))

	# Tail: one thick, soft lock from the top of the croup, out over the rump and down,
	# turning back at the tip.
	var t := _tail
	for part in [[1052.0, 314.0, Vector3(26, 10, 20), 0.0], [1080.0, 327.0, Vector3(25, 19, 28), 18.0], [1099.0, 362.0, Vector3(28, 34, 34), 26.0],
			[1101.0, 410.0, Vector3(27, 40, 38), 30.0], [1101.0, 452.0, Vector3(27, 36, 33), 30.0], [1110.0, 484.0, Vector3(25, 19, 22), 22.0],
			[1130.0, 491.0, Vector3(11, 9, 10), 8.0]]:
		he(t, _pt(part[0], part[1]), part[2], H_MANE, part[3])

	# Painted areas, after the ears' pink: socks, hooves, the cream muzzle and the blaze.
	var far := Vector3.ONE * 900.0 * _px
	_tints.append({"t": "below", "y": H_SOCK_Y, "c": _pt(960, 540), "r": far, "col": H_CREAM, "soft": CELL * 1.2})
	_tints.append({"t": "below", "y": H_HOOF_Y, "c": _pt(960, 565), "r": far, "col": H_HOOF, "soft": CELL * 0.5})
	_tints.append({"t": "blaze", "c": _pt(780, 230), "r": Vector3.ONE * 80.0 * _px, "col": H_CREAM, "soft": CELL * 1.1})
	_tints.append({"t": "muzzle", "c": _pt(750, 270), "r": Vector3.ONE * 80.0 * _px, "col": H_CREAM, "soft": CELL * 1.2})


## cow_clay.gd's skin colour with the horse's painted areas: "below" (everything under a sheet
## height: socks, hooves), "muzzle" (in front of H_MUZZLE_EDGE) and "blaze" (a stripe up the face).
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 10000.0
		if t.t == "ell":
			d = _dist(t, p)
		else:
			var sx := _ox + (p.x - X0) / _px
			var sy := _gy - p.y / _px
			var sz := absf(p.z / _px)
			if t.t == "below":
				d = (float(t.y) - sy) * _px
			elif t.t == "muzzle":
				d = (sx - Pig._curve(H_MUZZLE_EDGE, sy)) * _px
			else:
				d = maxf(maxf(sz - Pig._curve(H_BLAZE, sy), sx - 793.0), sy - 270.0) * _px
		var soft: float = t.soft
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


# --- Eyes ---------------------------------------------------------------------------------

## The skin under the middle of an eye: [point, Basis(toward the nose, up the eye, outward)].
func _horse_eye(side: float) -> Array:
	var hit := _ray(_body, _pt(H_EYE_AT.x, H_EYE_AT.y, side * 160.0), Vector3(0, 0, -side))
	var n: Vector3 = hit[1]
	var up := (Vector3.UP - n * n.dot(Vector3.UP)).normalized()
	var nose := (Vector3(-1, 0, 0) - n * n.dot(Vector3(-1, 0, 0)))
	nose = (nose - up * nose.dot(up)).normalized()
	return [hit[0], Basis(nose, up, n)]


## A point of an eye: `q` = (toward the nose, up) from its middle in sheet px, on the skin,
## lifted `lift` px plus a slight bulge.
func _eye_at(eye: Array, q: Vector2, lift: float) -> Vector3:
	var frame: Basis = eye[1]
	var round := maxf(1.0 - pow(q.x / H_EYE_R.x, 2.0) - pow(q.y / H_EYE_R.y, 2.0), 0.0)
	return _bdrop(eye[0] + (frame.x * q.x + frame.y * q.y) * _px, frame.z, lift + 1.0 * round)


## An ellipse filled with rings, laid on the skin.
func _eye_disc_fill(g, eye: Array, centre: Vector2, r: Vector2, lift: float, col: Color, edge := Color(0, 0, 0, 0)) -> void:
	if edge.a == 0.0: edge = col
	var n: Vector3 = (eye[1] as Basis).z
	var pts := [[_eye_at(eye, centre, lift)]]
	var cols := [[col]]
	for i in range(1, 7):
		var ring := []
		var ring_c := []
		for j in 40:
			var a := TAU * j / 40.0
			ring.append(_eye_at(eye, centre + Vector2(cos(a) * r.x, sin(a) * r.y) * (i / 6.0), lift))
			ring_c.append(col.lerp(edge, smoothstep(0.55, 1.0, i / 6.0)))
		pts.append(ring)
		cols.append(ring_c)
	Pig._rings(g, pts, cols, n)


## One eye, from the sheet's views: big, round and dark; the cream white shows as a crescent
## on the outer side; a large dark-brown iris almost filled by the pupil; one big catch-light
## high in the eye and a small one low on the other side.
func _horse_eye_geo(side: float):
	var g := Plaza.Geo.new()
	var eye := _horse_eye(side)
	_eye_disc_fill(g, eye, Vector2.ZERO, H_EYE_R, 0.35, H_SCLERA)
	_eye_disc_fill(g, eye, Vector2(1.5, -0.3), Vector2(10.6, 11.6), 0.6, H_IRIS, H_IRIS.darkened(0.25))
	_eye_disc_fill(g, eye, Vector2(1.5, -0.3), Vector2(7.0, 7.8), 0.85, H_PUPIL)
	_eye_disc_fill(g, eye, Vector2(-1.6, 4.6), Vector2(2.9, 2.9), 1.1, H_GLINT)
	_eye_disc_fill(g, eye, Vector2(4.2, -4.4), Vector2(1.3, 1.3), 1.1, H_GLINT)
	return g


func _horse_eye_node(side: float) -> Transform3D:
	var eye := _horse_eye(side)
	var frame: Basis = eye[1]
	var y := normal_to_model(frame.y)
	var z := normal_to_model(frame.z)
	return Transform3D(Basis(y.cross(z), y, z), to_model(_eye_at(eye, Vector2.ZERO, 0.35)) / _fine)


# --- Face details -------------------------------------------------------------------------

## Lash lines, eyebrows, nostrils and the smile.
func _horse_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _horse_eye(side)
		var n: Vector3 = (eye[1] as Basis).z
		# Upper lid: a dark line round the top of the eye, thickest over the outer half.
		g.color = H_LID
		var lid := []
		var lid_w := []
		for i in 17:
			var t := i / 16.0
			var a := deg_to_rad(lerpf(8.0, 172.0, t))
			lid.append(_eye_at(eye, Vector2(cos(a) * (H_EYE_R.x + 0.4), sin(a) * (H_EYE_R.y + 0.4)), 1.0))
			var w := lerpf(0.6, 1.5, sin(PI * t))
			lid_w.append(Vector2(w, 0.9) * _px)
		g.loft(lid, lid_w, n, 8)
		# Eyebrow: a short, soft arched dash above the eye, its nose end a little lower.
		g.color = H_BROW
		var brow := []
		var brow_w := []
		for q in [[12.0, 21.5, 1.6], [7.0, 24.5, 2.5], [1.0, 26.0, 2.9], [-5.0, 26.0, 2.9], [-11.0, 24.5, 2.4], [-15.5, 21.5, 1.5]]:
			brow.append(_eye_at(eye, Vector2(q[0], q[1]), 0.35))
			brow_w.append(Vector2(q[2], 1.0) * _px)
		g.loft(brow, brow_w, n, 10)
		# Nostril: a small upright oval set flat into the front of the muzzle.
		g.color = H_NOSTRIL
		var h := _ray(_body, _pt(600, 266, side * 17.0), Vector3(1, 0, 0))
		var hn: Vector3 = h[1]
		var upward := (Vector3.UP - hn * hn.dot(Vector3.UP)).normalized()
		g.ellipsoid(h[0] - hn * 0.3 * _px, Vector3(3.4, 4.8, 0.9) * _px, Basis(upward.cross(hn), upward, hn), 20, 10)
	# Smile: one long curve across the lower muzzle, its ends turned up round the sides.
	g.color = H_LINE
	var smile := []
	var smile_w := []
	for i in 25:
		var t := i / 24.0 * 2.0 - 1.0
		# Rays toward the muzzle's own axis, so the line runs round its sides.
		var ang := deg_to_rad(t * 68.0)
		var y := 288.5 - 19.0 * pow(absf(t), 3.0)
		var from := _pt(743.0 - 130.0 * cos(ang), y, 130.0 * sin(ang))
		var h := _ray(_body, from, _pt(743.0, y) - from)
		smile.append(h[0] + h[1] * 0.2 * _px)
		var w := lerpf(1.9, 1.0, absf(t))
		smile_w.append(Vector2(w, w) * _px)
	g.loft(smile, smile_w, Vector3.UP, 6)
	return _local_mesh(g, Transform3D())


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _horns, _hooves, _udder, _ear_tints, _muzzle_tints, _tail]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "HorseClayDisplay"
	root.set_meta("source", "User's Horse Character Blueprint, relaxed idle pose (17 Nov 2026)")
	var clay := _material(0.88)
	for part in [["Body", _body, H_COAT_CREASE, 3.5, true], ["Mane", _mane, H_MANE_CREASE, 4.5, false], ["Tail", _tail, H_MANE_CREASE, 4.5, false]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		if part[4]: mi.mesh = _paint(mi.mesh)
		mi.mesh = _bfit(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eye_mat := _material(0.3)
	eye_mat.metallic_specular = 0.3
	for eye in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var node := MeshInstance3D.new()
		node.name = eye[0]
		node.transform = _horse_eye_node(eye[1])
		node.mesh = _local_mesh(_horse_eye_geo(eye[1]), node.transform)
		node.material_override = eye_mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _horse_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(_pt(723, H_GY, -70)) / _fine
	var c := to_model(_pt(1142, H_TOP, 70)) / _fine
	var lo := a.min(c)
	var hi := a.max(c)
	box.size = hi - lo
	shape.shape = box
	shape.position = (lo + hi) * 0.5
	body.add_child(shape)
	root.add_child(body)
	for child in root.get_children():
		child.owner = root
		for grand in child.get_children():
			grand.owner = root
	return root
