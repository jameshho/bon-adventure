extends "res://scripts/characters/cow_clay.gd"
## Clay-style capybara traced from the user's "Capybara Character Blueprint" turnaround
## (16 Nov 2026, "Relaxed Idle Pose": front 3/4, front, side, back, rear 3/4). A static display
## model, built once by tools/build_capybara_clay.gd into scenes/animals/capybara_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd), the clay cow's surface ray and blob patches (cow_clay.gd) and the clay
## pig's ring patches (pig_clay.gd::_rings). Shapes are written in the sheet's pixels (side view:
## x to the right = toward the tail, y down; z lateral, taken from the front view) and BT()
## scales them into the lion's working space. The model is meshed BF times larger than life and
## shrunk afterwards (_bfit).
## Ready for rigging, like the clay pig: body, head, legs, paws, tail and ears are ONE fused
## mesh ("Body"); the brown muzzle, the brown paws, the ears' pink and the blush are painted on
## it. Each eye is its own mesh centred on its own node (LeftEye, RightEye: x along the lid, y
## up the eye, z out of the face). Lids, brows, nostrils and the mouth lines are "Face details".
## The head and the torso are lofted masses (see Shape), a shape type added to the lion's
## mesher for this model ("fn" in lion_clay.gd::_dist and _box).
## Output faces -Z (head), +Y up, ground at y = 0.

const Pig := preload("res://scripts/characters/pig_clay.gd")

const BH := 0.95                # town units to the top of the head: the zoo pig's height (user, 17 Nov 2026)
const BGY := 522.0              # sheet y of the soles
const BTOP := 235.0             # sheet y of the top of the head (the ears reach 212)
const BX := 960.0               # sheet x placed at the model origin
const BF := 2.6                 # meshed this many times larger than life
const BK := BF * BH / ((BGY - BTOP) * S)   # sheet pixel -> lion working unit

# Colours read from the sheet (body lit fcb166, mid f4a455, shade d58337; muzzle b36c3d-bf7941;
# ear rim da9667, ear back c2733c; paws a05f2f; ear pink ffae94; brow c57333; nostril 6d3911;
# mouth 8e4d1b; lid 662d03; iris 58300c; pupil 1e0e01), the orange a little deeper so it holds
# under the town's bright daylight.
const B_BODY := Color("e4954c")
const B_BODY_CREASE := Color("cf7f3a")
const B_MUZZLE := Color("a66535")
const B_PAW := Color("935428")
const B_PAW_CREASE := Color("7c4520")
const B_EAR := Color("c47a45")
const B_EAR_CREASE := Color("a9643a")
const B_EAR_IN := Color("f7a892")
const B_BLUSH := Color("e98450")
const B_SHADE := Color("d6853f")       # the soft shade under the brow ridge, above the lid
const B_NOSTRIL := Color("6a3712")
const B_LINE := Color("7a3f16")
const B_BROW := Color("c06f33")
const B_LID := Color("4a2006")
const B_SCLERA := Color("fbf0e2")
const B_IRIS := Color("5e3513")       # low in the iris
const B_IRIS_TOP := Color("351b07")   # under the lid
const B_PUPIL := Color("1f0f04")

# Eyes (sheet px). They sit on the sides of the head, just behind where it starts to narrow
# toward the muzzle, and are half closed: a thick straight lid, its nose end higher, with the
# lower half of the eye hanging under it (46 wide, 19 deep in the side view). The brown iris
# fills the eye down to its lower edge; the white shows only as a sliver at each corner; the
# pupil hangs from the lid; there is no catch-light on the sheet.
const B_EYE_AT := Vector2(820.0, 300.0)   # side view: middle of the lid's lower edge
const B_EYE_R := Vector2(23.0, 19.0)      # half width along the lid, depth under it
const B_EYE_TILT := 7.5                   # degrees the lid's nose end is raised
const B_IRIS_C := Vector2(0.5, -2.0)      # (toward the nose, up) from the lid's middle
const B_IRIS_R := 18.5
const B_PUPIL_C := Vector2(1.0, -1.0)
const B_PUPIL_R := 8.5

## Muzzle patch: the front-view rounded shape [centre y, half width, half height, corner radius]
## and the sheet x of its back edge in the side view.
const B_PATCH := [344.5, 53.0, 63.5, 42.0]
const B_PATCH_BACK := 764.0
## Front legs [sheet x, lateral z] and hind feet [sheet x, lateral z].
const B_FRONT_X := 858.0
const B_FRONT_Z := 48.0
const B_HIND_X := 1028.0
const B_HIND_Z := 81.0
const B_SOCK_Y := 486.0                   # the brown of the front paws starts here


# Second pass (user, 16 Nov 2026): the head has about 15% less volume than the sheet's (0.95
# in every direction about the nape), with slimmer cheeks and jaw, and runs into the back
# without a fold. Head shapes and face features are written in the sheet's pixels and placed
# with HT(), which applies that scale.
const HS := 1.0
const H_PIVOT := Vector2(940.0, 345.0)


## Sheet pixel of the head -> working space, shrunk about the nape.
static func HT(x: float, y: float, z := 0.0) -> Vector3:
	return BT(H_PIVOT.x + (x - H_PIVOT.x) * HS, H_PIVOT.y + (y - H_PIVOT.y) * HS, z * HS)


## Sheet pixel -> working space (y up).
static func BT(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - BX) * BK, (BGY - y) * BK, z * BK)


func be(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * BK, col, k * BK, crease, basis)


func bc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * BK, rb * BK, col, k * BK)


# --- Shape --------------------------------------------------------------------------------
# Rebuilt from the ground up (user, 17 Nov 2026): the head and the torso are each ONE sculpted
# mass, not ellipsoids run together. A mass is a loft: cross-sections along the sheet's x, each
# given by its top, its bottom, the height where it is widest, its half width and how square
# its upper and lower halves are (2 = an ellipse, more = fuller corners), joined by smooth
# curves and closed by rounded ends. The numbers are read from the vtracer outlines of the
# sheet's views (docs/evidence/capybara-clay-20261116/).

## Head sections: [sheet x, top y, bottom y, widest y, half width, upper squareness, lower squareness].
## Side view: the forehead slopes in one line from the crown to the blunt, rounded muzzle; the
## jaw runs level into the throat. From above: a wedge, widest behind the eyes. From the front:
## narrower over the crown than at the cheeks, the muzzle a soft rounded square.
const B_HEAD := [
	[698.0, 277.0, 391.0, 336.0, 49.0, 2.5, 2.7],
	[730.0, 269.5, 399.0, 340.0, 52.5, 2.5, 2.7],
	[756.0, 258.0, 408.5, 344.0, 56.0, 2.4, 2.6],
	[782.0, 249.0, 414.0, 347.0, 62.5, 2.3, 2.5],
	[808.0, 241.5, 417.0, 349.0, 73.0, 2.2, 2.4],
	[835.0, 237.0, 418.0, 350.0, 87.0, 2.1, 2.3],
	[862.0, 235.0, 417.0, 350.0, 98.5, 2.0, 2.3],
	[888.0, 235.0, 414.0, 350.0, 105.0, 2.0, 2.3],
	[910.0, 237.0, 410.0, 348.0, 106.0, 2.0, 2.2],
	[926.0, 244.0, 405.0, 345.0, 101.0, 2.0, 2.2],
	[938.0, 258.0, 400.0, 342.0, 93.0, 2.0, 2.1],
	[948.0, 280.0, 395.0, 340.0, 80.0, 2.0, 2.0],
	[956.0, 306.0, 392.0, 340.0, 66.0, 2.0, 2.0]]
const B_HEAD_CAPS := Vector2(30.0, 12.0)     # length of the rounded nose end and of the nape end

## The torso's sections: a ball in the side view (radius 128 about sheet (1006, 430), as
## traced), a pear from the front and back: widest low down, tapering to the shoulders.
static func _torso_sections() -> Array:
	var out := []
	for i in 21:
		var x := lerpf(879.0, 1133.0, i / 20.0)
		var s := sqrt(maxf(1.0 - pow((x - 1006.0) / 130.0, 2.0), 0.0))
		out.append([x, 430.0 - 128.0 * s, 430.0 + 113.0 * s, 430.0 + 18.0 * s, 124.0 * s, 2.0, 2.0])
	return out


## Adds a lofted mass to a group. `place` maps a sheet point to working space (BT or HT).
func loft(g: Array, sections: Array, caps: Vector2, col: Color, k := 0.0) -> Dictionary:
	var keys := []
	for j in range(1, 7):
		var row := []
		for st in sections: row.append([st[0], st[j]])
		keys.append(row)
	var x0: float = sections[0][0]
	var x1: float = sections[-1][0]
	var top := INF
	var bottom := -INF
	var wide := 0.0
	for st in sections:
		top = minf(top, st[1])
		bottom = maxf(bottom, st[2])
		wide = maxf(wide, st[4])
	var fn := func(p: Vector3) -> float:
		var sx := BX + (p.x - X0) / BK
		var sy := BGY - p.y / BK
		var x := clampf(sx, x0, x1)
		# Rounded ends: the section shrinks about its widest height along a quarter ellipse.
		var s := 1.0
		if caps.x > 0.0 and x < x0 + caps.x: s = sqrt(maxf(1.0 - pow((x0 + caps.x - x) / caps.x, 2.0), 0.0))
		if caps.y > 0.0 and x > x1 - caps.y: s = sqrt(maxf(1.0 - pow((x - x1 + caps.y) / caps.y, 2.0), 0.0))
		s = maxf(s, 0.04)
		var yc := Pig._curve(keys[2], x)
		var w := Pig._curve(keys[3], x) * s
		var dy := sy - yc
		var h := ((yc - Pig._curve(keys[0], x)) if dy < 0.0 else (Pig._curve(keys[1], x) - yc)) * s
		var n := Pig._curve(keys[4] if dy < 0.0 else keys[5], x)
		var z := absf(p.z / BK)
		dy = absf(dy)
		var reach := Vector2(z, dy).length()
		var d := -minf(w, h)
		if reach > 0.001:
			var r := pow(pow(z / w, n) + pow(dy / h, n), 1.0 / n)
			d = reach * (1.0 - 1.0 / maxf(r, 0.001)) if r > 0.02 else -minf(w, h)
		if sx != x:
			d = Vector2(maxf(d, 0.0), sx - x).length()
		return d * BK
	var pr := {"t": "fn", "fn": fn, "lo": BT(x0, bottom, -wide).min(BT(x1, top, wide)), "hi": BT(x0, bottom, -wide).max(BT(x1, top, wide)),
			"k": k * BK, "col": col, "crease": false, "paint": false}
	g.append(pr)
	return pr


## An ear as one mass: a round, thick cup (an ellipsoid with a hollow pressed into its face).
func _ear(g: Array, c: Vector3, basis: Basis, r: Vector3, hollow: Vector3, cup: Vector3, k: float) -> void:
	var solid := {"t": "ell", "c": c, "r": r, "inv": basis.inverse()}
	var hole := {"t": "ell", "c": hollow, "r": cup, "inv": basis.inverse()}
	var m := maxf(r.x, maxf(r.y, r.z))
	g.append({"t": "fn", "fn": func(p: Vector3) -> float: return maxf(_dist(solid, p), -_dist(hole, p)),
			"lo": c - Vector3.ONE * m, "hi": c + Vector3.ONE * m, "k": k, "col": B_EAR, "crease": false, "paint": false})


func _shape() -> void:
	var b := _body
	# Torso, then the ground under it; the belly lifts off the ground behind the front legs.
	loft(b, _torso_sections(), Vector2(8.0, 8.0), B_BODY)
	carve(b, BT(1005, BGY + 59.0), Vector3(500, 60, 500) * BK, B_BODY)
	carve(b, BT(950, 540), Vector3(55, 33, 200) * BK, B_BODY)
	be(b, BT(886, 432), Vector3(66, 54, 98), B_BODY, 44.0)                  # chest, run widely into the torso
	be(b, BT(1120, 487), Vector3(13, 15, 15), B_BODY, 6.0)                  # tail nub
	# Legs: short, round and a little tapered, each on a soft rounded paw with three toes.
	for side in [-1.0, 1.0]:
		var z: float = side * B_FRONT_Z
		bc(b, BT(B_FRONT_X + 4.0, 436, z + side * 4.0), BT(B_FRONT_X, 497, z), 37.0, 27.5, B_BODY, 30.0)
		be(b, BT(B_FRONT_X - 3.0, 505, z), Vector3(31, 17.5, 26.5), B_BODY, 9.0)
		for t in [-1.0, 0.0, 1.0]:
			be(b, BT(B_FRONT_X - 25.0 + absf(t) * 3.5, 509.5, z + t * 16.0), Vector3(11.5, 12.5, 9.4), B_BODY, 4.0, true)
		var hz: float = side * B_HIND_Z
		be(b, BT(B_HIND_X, 505.5, hz), Vector3(48, 18, 23), B_BODY, 9.0)
		for t in [-1.0, 0.0, 1.0]:
			be(b, BT(B_HIND_X - 44.0 + absf(t) * 3.5, 510.0, hz + 2.0 * side + t * 11.5), Vector3(11.5, 12, 7.8), B_BODY, 4.0, true)
	# Head, run into the torso and chest with a soft, shallow neck.
	var sections := []
	for st in B_HEAD:
		var at := Vector2(H_PIVOT.x + (st[0] - H_PIVOT.x) * HS, 0.0)
		sections.append([at.x, H_PIVOT.y + (st[1] - H_PIVOT.y) * HS, H_PIVOT.y + (st[2] - H_PIVOT.y) * HS,
				H_PIVOT.y + (st[3] - H_PIVOT.y) * HS, st[4] * HS, st[5], st[6]])
	var head := loft(b, sections, B_HEAD_CAPS * HS, B_BODY, 30.0)
	# Flat soles.
	for side in [-1.0, 1.0]:
		carve(b, BT(B_FRONT_X - 10.0, BGY + 40.0, side * B_FRONT_Z), Vector3(120, 40, 120) * BK, B_PAW)
		carve(b, BT(B_HIND_X, BGY + 40.0, side * B_HIND_Z), Vector3(120, 40, 120) * BK, B_PAW)
	# Ears: small, round, thick cups set into the top corners of the skull and run into it at
	# the base; open forward and outward; brown with a wide rim round a pink hollow.
	for side in [-1.0, 1.0]:
		var open := Vector3(-0.72, 0.12, side * 0.68).normalized()
		var up := (Vector3.UP - open * open.dot(Vector3.UP)).normalized()
		var basis := Basis(open, up, open.cross(up))
		var c := HT(900, 247, side * 66.0)
		var hollow := c + open * 13.0 * BK
		var cup := Vector3(14, 19.5, 19.5) * HS * BK
		_ear(b, c - open * 4.0 * BK, basis, Vector3(19, 28, 28) * HS * BK, hollow, cup, 7.0 * BK)
		_tints.append({"t": "ell", "c": hollow, "r": cup + Vector3(1.5, 1.0, 1.0) * BK, "inv": basis.inverse(), "col": B_EAR_IN,
				"soft": CELL * 0.6, "out_of": head.fn})

	# Painted areas, in order (after the ears' pink): the brown paws, the brown muzzle, the
	# blush and the soft shade over each lid.
	_tints.append({"t": "sock", "c": BT(B_FRONT_X, 505), "r": Vector3.ONE * 110.0 * BK, "col": B_PAW, "soft": CELL * 0.9})
	for side in [-1.0, 1.0]:
		_tint(BT(B_HIND_X - 4.0, 508, side * (B_HIND_Z + 6.0)), Vector3(60, 16.5, 31) * BK, Basis(), B_PAW, CELL * 0.9)
	_tints.append({"t": "muzzle", "c": HT(740, B_PATCH[0]), "r": Vector3.ONE * 110.0 * BK, "col": B_MUZZLE, "soft": CELL * 1.1})
	for side in [-1.0, 1.0]:
		var cheek: Vector3 = _ray(b, HT(866, 342, side * 230.0), Vector3(0, 0, -side))[0]
		_tint(cheek, Vector3(19, 14, 14) * BK, Basis(), B_BLUSH, CELL * 5.0)
		var eye := _capy_eye(side)
		var frame: Basis = eye[1]
		_tint(_eye_pt(eye, Vector2(0.0, 7.0), 0.0), Vector3(25, 6.5, 8) * BK, frame.inverse().transposed(), B_SHADE, CELL * 2.5)


## cow_clay.gd's skin colour, extended with the muzzle patch ("muzzle": in front of the side
## view's back edge and inside the front view's rounded shape), the front paws ("sock":
## below B_SOCK_Y round each front leg).
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	var p := Vector3(v.z / S + X0, v.y / S, -v.x / S)
	var c := col
	_crisp = 0.0
	for j in _tints.size():
		var t: Dictionary = _tints[j]
		if p.distance_squared_to(t.c) > reach[j]: continue
		var d := 10000.0
		if t.t == "muzzle" or t.t == "sock":
			var sx := BX + (p.x - X0) / BK
			var sy := BGY - p.y / BK
			var sz := absf(p.z / BK)
			if t.t == "muzzle":
				sx = H_PIVOT.x + (sx - H_PIVOT.x) / HS
				sy = H_PIVOT.y + (sy - H_PIVOT.y) / HS
				sz /= HS
				var rad: float = B_PATCH[3]
				var q := Vector2(sz - (B_PATCH[1] - rad), absf(sy - B_PATCH[0]) - (B_PATCH[2] - rad))
				var box := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - rad
				d = maxf(sx - B_PATCH_BACK, box) * BK
			else:
				d = maxf(B_SOCK_Y - sy, Vector2(sx - B_FRONT_X + 6.0, sz - B_FRONT_Z).length() - 46.0) * BK
		else:
			d = _dist(t, p)
			if t.has("out_of"): d = maxf(d, 1.5 * BK - t.out_of.call(p))    # not where the skull shows inside the ear
		var soft: float = t.soft
		var w := clampf(0.5 - d / soft, 0.0, 1.0)
		if w > 0.0:
			var tc: Color = t.col
			c = c.lerp(tc, w)
			if soft < CELL: _crisp = maxf(_crisp, w)
	c.a = 1.0
	return c


## First point of a group's surface along a ray (working space): [point, outward normal].
## As pig_clay.gd's: the lofted masses' field is not an exact distance near their rounded ends,
## so steps are capped at half a sheet px and the crossing is then closed in by halving.
func _ray(group: Array, from: Vector3, dir: Vector3) -> Array:
	var d := dir.normalized()
	var p := from
	var before := from
	var found := false
	for i in 6000:
		var f := _field(group, p)
		if f <= 0.0:
			found = true
			break
		before = p
		p += d * clampf(f * 0.5, 0.05, (0.5 if f < 20.0 * BK else 8.0) * BK)
	if found:
		for i in 12:
			var mid := (before + p) * 0.5
			if _field(group, mid) <= 0.0: p = mid
			else: before = mid
	var h := 0.5
	var n := Vector3(
		_field(group, p + Vector3(h, 0, 0)) - _field(group, p - Vector3(h, 0, 0)),
		_field(group, p + Vector3(0, h, 0)) - _field(group, p - Vector3(0, h, 0)),
		_field(group, p + Vector3(0, 0, h)) - _field(group, p - Vector3(0, 0, h))).normalized()
	return [p, n]


## Drops a point near the skin onto it along -n, then lifts it `lift` sheet px.
func _bdrop(p: Vector3, n: Vector3, lift: float) -> Vector3:
	var q := p + n * 14.0 * BK
	for i in 900:
		if _field(_body, q) <= 0.0: break
		q -= n * 0.1
	return q + n * lift * BK


# --- Eyes ---------------------------------------------------------------------------------

## The skin under the middle of an eye's lid: [point, Basis(toward the nose along the lid, up
## the eye, outward normal)] in working space. Not a rotation for both sides (the two eyes
## mirror each other); _eye_node() makes the node's own right-handed frame.
func _capy_eye(side: float) -> Array:
	var hit := _ray(_body, HT(B_EYE_AT.x, B_EYE_AT.y, side * 230.0), Vector3(0, 0, -side))
	var n: Vector3 = hit[1]
	var up := (Vector3.UP - n * n.dot(Vector3.UP)).normalized()
	var nose := (Vector3(-1, 0, 0) - n * n.dot(Vector3(-1, 0, 0)))
	nose = (nose - up * nose.dot(up)).normalized()
	var a := deg_to_rad(B_EYE_TILT)
	return [hit[0], Basis(nose * cos(a) + up * sin(a), up * cos(a) - nose * sin(a), n)]


## A point of an eye: `q` = (toward the nose, up) from the middle of the lid in sheet px, on the
## skin, lifted `lift` px plus the eye's own slight bulge.
func _eye_pt(eye: Array, q: Vector2, lift: float, bulge := 0.0) -> Vector3:
	var frame: Basis = eye[1]
	var round := maxf(1.0 - pow(q.x / B_EYE_R.x, 2.0) - pow(q.y / B_EYE_R.y, 2.0), 0.0)
	return _bdrop(eye[0] + (frame.x * q.x + frame.y * q.y) * BK * HS, frame.z, lift + bulge * round)


static func _in_eye(q: Vector2) -> bool:
	return q.y <= 0.0 and pow(q.x / B_EYE_R.x, 2.0) + pow(q.y / B_EYE_R.y, 2.0) <= 1.0


## A circle cut to the open part of the eye (the half ellipse under the lid).
static func _eye_disc(centre: Vector2, radius: float, count := 64) -> Array:
	var out := []
	for i in count:
		var a := TAU * i / count
		var p := centre + Vector2(cos(a), sin(a)) * radius
		if not _in_eye(p):
			var lo := 0.0
			var hi := 1.0
			for step in 16:
				var mid := (lo + hi) * 0.5
				if _in_eye(centre + (p - centre) * mid): lo = mid
				else: hi = mid
			p = centre + (p - centre) * lo
		out.append(p)
	return out


## Fills an outline with rings toward `centre`, laid on the skin, with smooth normals.
func _eye_fill(g, eye: Array, outline: Array, centre: Vector2, lift: float, col: Color, top := Color(0, 0, 0, 0)) -> void:
	if top.a == 0.0: top = col
	var n: Vector3 = (eye[1] as Basis).z
	var pts := [[_eye_pt(eye, centre, lift, 1.2)]]
	var cols := [[top.lerp(col, smoothstep(-3.0, -15.0, centre.y))]]
	for i in range(1, 7):
		var ring := []
		var ring_c := []
		for o in outline:
			var q: Vector2 = centre + (o - centre) * (i / 6.0)
			ring.append(_eye_pt(eye, q, lift, 1.2))
			ring_c.append(top.lerp(col, smoothstep(-3.0, -15.0, q.y)))
		pts.append(ring)
		cols.append(ring_c)
	# One normal for the whole layer: the eye is a flat inlay, and it shades evenly.
	Pig._rings(g, pts, cols, n)


## One eye: the white (the half ellipse under the lid), the iris and the pupil, each a thin
## layer lying on the head's own curve with a slight bulge (flat-set eyes, not balls).
func _capy_eye_geo(side: float):
	var g := Plaza.Geo.new()
	var eye := _capy_eye(side)
	_eye_fill(g, eye, _eye_disc(Vector2(0.0, -6.0), 60.0), Vector2(0.0, -8.0), 0.35, B_SCLERA)
	_eye_fill(g, eye, _eye_disc(B_IRIS_C, B_IRIS_R), B_IRIS_C + Vector2(0.0, -4.0), 0.6, B_IRIS, B_IRIS_TOP)
	_eye_fill(g, eye, _eye_disc(B_PUPIL_C, B_PUPIL_R), B_PUPIL_C + Vector2(0.0, -3.0), 0.85, B_PUPIL)
	return g


## The eye's node frame in model space: origin at the middle of the open eye, x along the lid,
## y up the eye, z out of the face (right-handed).
func _eye_node(side: float) -> Transform3D:
	var eye := _capy_eye(side)
	var frame: Basis = eye[1]
	var y := normal_to_model(frame.y)
	var z := normal_to_model(frame.z)
	var origin := to_model(_eye_pt(eye, Vector2(0.0, -B_EYE_R.y * 0.5), 0.35)) / BF
	return Transform3D(Basis(y.cross(z), y, z), origin)


## Geo (working space) -> mesh in the local space of `xf` (model space, life size).
func _local_mesh(g, xf: Transform3D) -> ArrayMesh:
	var inv := xf.affine_inverse()
	for i in g.verts.size():
		g.verts[i] = inv * (to_model(g.verts[i]) / BF)
		g.norms[i] = inv.basis * normal_to_model(g.norms[i])
	return g.commit()


# --- Face details -------------------------------------------------------------------------

## Lids, eyebrows and the mouth lines.
func _capy_details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var eye := _capy_eye(side)
		var n: Vector3 = (eye[1] as Basis).z
		# Lid: a thick, straight dark bar along the top of the eye, standing a little proud,
		# reaching just past the nose corner and a little farther past the outer corner.
		g.color = B_LID
		var lid := []
		var lid_w := []
		for i in 14:
			var t := i / 13.0
			lid.append(_eye_pt(eye, Vector2(lerpf(-26.5, 24.5, t), 1.6), 1.0))
			var w := 2.6 if i > 0 and i < 13 else 2.2
			lid_w.append(Vector2(w, 1.1) * BK)
		g.loft(lid, lid_w, n, 10)
		# Eyebrow: a short, soft arched dash high on the corner of the head, well above the eye.
		g.color = B_BROW
		var brow := []
		var brow_w := []
		var brow_n := Vector3.ZERO
		# It runs diagonally: its nose end is nearer the middle of the head. [sheet x, lateral z, half width]
		for q in [[824.0, 48.0, 2.4], [827.5, 51.5, 3.8], [831.5, 55.5, 4.4], [836.0, 60.0, 4.4], [840.0, 64.0, 3.8], [843.0, 67.5, 2.4]]:
			var h := _ray(_body, HT(q[0], 150.0, side * q[1]), Vector3(0, -1, 0))
			brow.append(h[0] + h[1] * 0.35 * BK)
			brow_w.append(Vector2(q[2], 1.1) * BK)
			brow_n += h[1]
		g.loft(brow, brow_w, brow_n.normalized(), 10)
		# Smile: from the foot of the middle line, down a little and up to the corner.
		g.color = B_LINE
		var smile := []
		var smile_w := []
		for i in 15:
			var t := i / 14.0
			var h := _ray(_body, HT(600, 372.0 + 9.0 * sin(PI * t) - 3.0 * t * t, side * 42.0 * t), Vector3(1, 0, 0))
			smile.append(h[0] + h[1] * 0.2 * BK)
			var w := lerpf(1.6, 0.9, t)
			smile_w.append(Vector2(w, w) * BK)
		g.loft(smile, smile_w, Vector3.UP, 6)
	# Middle line: straight down from under the nostrils to the smile.
	g.color = B_LINE
	var mid := []
	var mid_w := []
	for i in 9:
		var t := i / 8.0
		var h := _ray(_body, HT(600, lerpf(332.0, 372.5, t)), Vector3(1, 0, 0))
		mid.append(h[0] + h[1] * 0.2 * BK)
		var w := lerpf(1.0, 1.6, t)
		mid_w.append(Vector2(w, w) * BK)
	g.loft(mid, mid_w, Vector3(0, 0, 1), 6)
	# Nostrils: two small dark slanted ovals set flat into the top of the muzzle's front, their
	# inner ends lower.
	g.color = B_NOSTRIL
	for side in [-1.0, 1.0]:
		var h := _ray(_body, HT(600, 318, side * 24.5), Vector3(1, 0, 0))
		var hn: Vector3 = h[1]
		var across := Vector3(0, 0.5, side * 0.866)
		across = (across - hn * across.dot(hn)).normalized()
		g.ellipsoid(h[0] - hn * 0.3 * BK, Vector3(6.6, 3.1, 0.9) * BK, Basis(across, hn.cross(across), hn), 20, 10)
	return _local_mesh(g, Transform3D())


## Shrinks a clay mesh from its meshing size to life size.
func _bfit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= BF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _horns, _hooves, _udder, _ear_tints, _muzzle_tints]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "CapybaraClayDisplay"
	root.set_meta("source", "User's Capybara Character Blueprint, relaxed idle pose (16 Nov 2026)")
	var clay := _material(0.88)
	for part in [["Body", _body, B_BODY_CREASE, 3.5, _tints]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		var body_tints := _tints
		_tints = part[4]
		mi.mesh = _paint(mi.mesh)
		_tints = body_tints
		mi.mesh = _bfit(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var eye_mat := _material(0.35)
	eye_mat.metallic_specular = 0.25
	for eye in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var node := MeshInstance3D.new()
		node.name = eye[0]
		node.transform = _eye_node(eye[1])
		node.mesh = _local_mesh(_capy_eye_geo(eye[1]), node.transform)
		node.material_override = eye_mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _capy_details()
	face.material_override = _material(0.75)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(BT(708, BGY, -115)) / BF
	var c := to_model(BT(1140, BTOP, 115)) / BF
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
