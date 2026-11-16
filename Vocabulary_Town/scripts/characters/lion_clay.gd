extends RefCounted
## Clay-style lion traced from the user's "Lion Character Blueprint" turnaround (10 Nov 2026,
## "Relax Crawl Pose": front 3/4, front, side, back, rear 3/4). A static display model for the
## zoo, built once by tools/build_lion_clay.gd into scenes/animals/lion_clay.scn.
##
## Shapes are written in blueprint pixels of the side view (x to the right = toward the tail,
## y down from the top of the sheet, z lateral) and meshed as smooth signed-distance fields
## (surface nets), so the body, legs and head blend like modelling clay while the mane and tail
## tuft stay separate puffs with painted creases. Eyes, nose, mouth and whiskers are small
## lofted parts on the face. Output faces -Z (head), +Y up, ground at y = 0.
## Second pass 11 Nov 2026: all lion shapes re-measured in true sheet pixels (see Q()).

const Plaza := preload("res://scripts/buildings/monument_plaza.gd")

const GROUND := 352.0          # blueprint y of the paws' soles
const X0 := 770.0              # blueprint x placed at the model origin
const HEIGHT := 1.95           # town units, the zoo lion's display height (park_animals.gd)
const TOP := 126.0             # blueprint y of the top of the mane
const S := HEIGHT / (GROUND - TOP)
const CELL := 3.5              # field grid step, blueprint pixels (3 cm; ~70k triangles)

const CREAM := Color("eccb93")           # a little under the sheet's f8d7a2: the town light is bright
const MUZZLE := Color("f7e6c8")
const PAW_CREASE := Color("d2b27d")
const NOSE := Color("4f2a16")
const IRIS := Color("5a3015")         # warm dark brown
const LID := Color("4a2a18")          # mouth line
const PUPIL := Color("3a1d0c")        # barely darker than the iris, as on the sheet
const SHINE := Color("9a7a5a")        # small, dim catch-light
const SCLERA := Color("f7eedf")       # warm white at the outer corner and under the iris
const LID_LINE := Color("3f2414")
const MANE_HAIR := Color("cf7133")    # sheet orange (mid d27732, lit f09a50); the tail tuft matches
const MANE_HAIR_CREASE := Color("a95522")
const EAR := Color("eccb93")          # the face's cream
const EAR_PINK := Color("e58f86")
const WHISKER := Color("fbf8f2")
const MANE_K := 9.0                   # blend between mane lobes: soft seams, lobes stay distinct

# Full re-measure against the sheet (11 Nov 2026, second pass): the sheet's ground line is at
# y 359, not GROUND (352, kept because the other clay animals share P() and S). Lion shapes are
# written in true sheet pixels through Q(), which shifts them onto the model's ground.
const SHEET_DY := 7.0

# Eyes (sheet px), traced from the front view at 20x. Outline in (outward from the nose, up)
# about the eye centre: a straight lid slanting down to the inner corner (the stern look), a
# round lower arc. The iris is large, toward the nose, its top cut by the lid; white shows as a
# wedge at the outer corner and a sliver below.
const EYE_Y := 225.0
const EYE_Z := 28.5
const EYE_TOP := [Vector2(-8.1, -1.75), Vector2(-5.5, 2.6), Vector2(-2.5, 5.0), Vector2(1.5, 6.6), Vector2(5.5, 7.2), Vector2(9.0, 6.4)]
const EYE_BOTTOM := [Vector2(8.9, 1.0), Vector2(7.0, -3.0), Vector2(3.5, -6.0), Vector2(-0.5, -7.25), Vector2(-4.0, -6.5), Vector2(-7.0, -4.5)]
const IRIS_C := Vector2(-1.0, 0.25)
const IRIS_R := Vector2(6.0, 6.8)
const PUPIL_R := Vector2(3.0, 3.4)

## Primitive: {t: "ell"|"cone", c/radii/inv or a/b/ra/rb, k: blend radius, col: Color, crease: bool,
## paint: bool, sub: bool (carves the shapes before it and paints the hollow)}
var _body := []
var _mane := []
var _tuft := []
var _ears := []


static func P(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(x, GROUND - y, z)


## Lion only: true sheet pixels (ground at y 359) -> working space.
static func Q(x: float, y: float, z := 0.0) -> Vector3:
	return P(x, y - SHEET_DY, z)


## Blueprint-pixel point -> model space (a proper rotation: blueprint +x -> +Z, z -> -X).
static func to_model(p: Vector3) -> Vector3:
	return Vector3(-p.z, p.y, p.x - X0) * S


static func normal_to_model(n: Vector3) -> Vector3:
	return Vector3(-n.z, n.y, n.x)


func ell(group: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis(), paint := false) -> void:
	group.append({"t": "ell", "c": c, "r": r, "inv": basis.inverse(), "rot": basis, "k": k, "col": col, "crease": crease, "paint": paint})


## Carves an ellipsoid out of the shapes listed before it in the group; the hollow takes `col`.
func carve(group: Array, c: Vector3, r: Vector3, col: Color, basis := Basis()) -> void:
	group.append({"t": "ell", "c": c, "r": r, "inv": basis.inverse(), "rot": basis, "k": 0.0, "col": col, "crease": false, "paint": true, "sub": true})


func cone(group: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	group.append({"t": "cone", "a": a, "b": b, "ra": ra, "rb": rb, "k": k, "col": col, "crease": false, "paint": false})


func chain(group: Array, pts: Array, radii: Array, col: Color, k: float) -> void:
	for i in pts.size() - 1:
		cone(group, pts[i], pts[i + 1], radii[i], radii[i + 1], col, k if i == 0 else 4.0)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Second pass, 11 Nov 2026: every shape re-measured on a 10 px grid over the sheet's side,
	# front and back views. Chunky torso (back at y 220, belly 314, +-56 wide, +-65 at the
	# haunches), belly low at y 320, thick legs (radius ~25) and big three-toed paws (56 px long).
	ell(b, Q(790, 270), Vector3(88, 50, 56), CREAM)
	ell(b, Q(718, 262), Vector3(46, 48, 52), CREAM, 14.0)                  # chest under the mane
	ell(b, Q(852, 272), Vector3(30, 46, 50), CREAM, 14.0)                  # rump: one round dome from behind
	ell(b, Q(856, 300), Vector3(26, 34, 40), CREAM, 12.0)                  # filled between the thighs
	# Head: one smooth egg (+-52 wide, forehead y 186), the eyes set back beside the bridge
	# so they also show from the side, a jaw closing to the
	# chin, a straight sloping bridge and a pale boxy muzzle with whisker pads and chin pad.
	ell(b, Q(656, 226), Vector3(38, 44, 53), CREAM, 8.0)
	ell(b, Q(640, 256), Vector3(30, 28, 43), CREAM, 12.0)                  # cheeks and jaw
	cone(b, Q(626, 218), Q(604, 242), 13.0, 12.0, CREAM, 10.0)             # bridge
	ell(b, Q(613, 252), Vector3(19, 17, 28), MUZZLE, 8.0)                  # muzzle
	for side in [-1.0, 1.0]:
		# Brow ridges: low, inner ends down (they shade the inner eye corners).
		var brow_tilt := Basis(Vector3.RIGHT, -side * deg_to_rad(18.0))
		ell(b, Q(630, 214, side * 24.0), Vector3(7, 6, 14), CREAM, 14.0, false, brow_tilt)
		ell(b, Q(609, 254, side * 15.0), Vector3(13, 12, 15), MUZZLE, 4.0)  # whisker pads
		ell(b, Q(634, 250, side * 27.0), Vector3(22, 20, 22), CREAM, 10.0)  # full cheeks: a broad, flat face
	ell(b, Q(614, 273), Vector3(15, 12, 24), MUZZLE, 6.0)                  # chin pad
	# Ears: round discs (radius 22) at the head's upper corners, in front of the mane, turned
	# 40 deg outward so the pink cup shows from the front and the side; cream rim, pink centre.
	for side in [-1.0, 1.0]:
		var tilt := Basis(Vector3.UP, side * deg_to_rad(40.0))
		var ear := Q(655, 188, side * 43.0)
		ell(_ears, ear, Vector3(10, 22, 22), EAR, 0.0, false, tilt)
		carve(_ears, ear + tilt * Vector3(-11.5, -1.5, 0), Vector3(4.5, 11, 11), EAR_PINK, tilt)
	# Legs (z > 0 is the side seen in the side view): near front reaching forward, far front
	# back under the belly, near rear back, far rear a little ahead of it.
	_leg(b, [Q(738, 285, 37), Q(712, 318, 37), Q(700, 336, 37)], [30.0, 27.0, 27.0], Q(687, 344, 37))
	_leg(b, [Q(800, 290, -37), Q(795, 320, -37), Q(793, 336, -37)], [30.0, 27.0, 27.0], Q(788, 344, -37))
	_leg(b, [Q(847, 270, 36), Q(872, 305, 38), Q(884, 336, 38)], [31.0, 27.0, 26.0], Q(881, 344, 38))
	_leg(b, [Q(840, 270, -36), Q(858, 305, -38), Q(868, 336, -38)], [31.0, 27.0, 26.0], Q(865, 344, -38))
	# Tail: off the rump, a smooth curve down and back to the tuft.
	chain(b, [Q(862, 236), Q(880, 258), Q(896, 279), Q(912, 290), Q(924, 292)], [10.0, 8.0, 7.0, 6.5, 6.0], CREAM, 8.0)

	# Mane: big smooth lobes with soft seams, like the sheet (+-100 wide, y 130 to 321, x 621
	# to 772). A main ring of 12 round the widest part, a back ring and cap, and a collar of
	# five lobes round the cheeks and chin; two lobes meet in a V on the forehead between the
	# ears. The lobes beside the ears stay behind them.
	ell(_mane, Q(706, 226), Vector3(52, 82, 88), MANE_HAIR, 0.0, true)
	_ring(698.0, 226.0, 65.0, 63.0, 12, 0.0, Vector3(44, 34, 31), 0.5, 14.0, 7.0)
	_ring(742.0, 222.0, 48.0, 46.0, 7, 0.5, Vector3(30, 34, 33), 1.0, 0.0, 0.0)
	ell(_mane, Q(752, 224), Vector3(24, 30, 30), MANE_HAIR, MANE_K, true)
	ell(_mane, Q(648, 298), Vector3(26, 22, 30), MANE_HAIR, MANE_K, true)
	for side in [-1.0, 1.0]:
		ell(_mane, Q(650, 288, side * 42.0), Vector3(26, 27, 32), MANE_HAIR, MANE_K, true)
		ell(_mane, Q(660, 254, side * 68.0), Vector3(28, 32, 28), MANE_HAIR, MANE_K, true)
		var peak := Basis(Vector3.RIGHT, side * deg_to_rad(24.0))
		ell(_mane, Q(648, 166, side * 13.0), Vector3(24, 33, 17), MANE_HAIR, MANE_K, true, peak)
	ell(_mane, Q(631, 184), Vector3(12, 14, 10), MANE_HAIR, MANE_K, true)   # the point of the V, down on the forehead
	# Tail tuft: a lumpy ball in the mane's orange.
	ell(_tuft, Q(936, 292), Vector3(18, 18, 18), MANE_HAIR, 0.0, true)
	for i in 5:
		var a := TAU * i / 5.0
		ell(_tuft, Q(939, 292) + Vector3(0, cos(a) * 10.0, sin(a) * 10.0), Vector3(13, 13, 13), MANE_HAIR, 3.0, true)
	ell(_tuft, Q(948, 293), Vector3(12, 13, 13), MANE_HAIR, 3.0, true)
	ell(_tuft, Q(924, 292), Vector3(10, 10, 10), MANE_HAIR, 3.0, true)


## A ring of mane lobes round the head axis at sheet x: centres on an ellipse (rz, ry) about
## height cy; r = (depth, along the lobe, across); each lobe leans back by `lean`; the top
## lobe comes `crown` px forward; alternate lobes shift `stagger` px and differ 7 % in size.
func _ring(x: float, cy: float, rz: float, ry: float, count: int, phase: float, r: Vector3, lean: float, crown: float, stagger: float) -> void:
	for i in count:
		var a := TAU * (i + phase) / count
		var odd := 1.0 if i % 2 == 1 else -1.0
		var radial := Vector3(0, cos(a), sin(a))
		var tangent := Vector3(0, -sin(a), cos(a))
		var along := (radial + Vector3.RIGHT * lean).normalized()
		var basis := Basis(tangent.cross(along).normalized(), along, tangent)
		# Narrower below the cheeks (the sheet's front outline is widest at eye height).
		var lat := rz * (1.0 - 0.12 * maxf(-cos(a), 0.0))
		# The main ring's lobes beside the ears sit back so the ears stay in front of the mane.
		var behind_ear := 16.0 if stagger > 0.0 and cos(a) > 0.3 and absf(sin(a)) > 0.3 else 0.0
		var c := Q(x - crown * pow(maxf(cos(a), 0.0), 6.0) + stagger * odd + behind_ear, cy) + Vector3(0, cos(a) * ry, sin(a) * lat)
		ell(_mane, c, r * (1.0 + 0.07 * odd if stagger > 0.0 else 1.0), MANE_HAIR, MANE_K, true, basis)


## Repeatable variation in [-1, 1] (layer li, item i, channel k). The lion no longer uses it;
## the clay giraffe and the animals built on it do.
static func _h(li: int, i: int, k: int) -> float:
	var v := sin(li * 127.1 + i * 311.7 + k * 74.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


func _leg(b: Array, joints: Array, radii: Array, paw: Vector3) -> void:
	chain(b, joints, radii, CREAM, 10.0)
	cone(b, joints[joints.size() - 1], paw + Vector3(6, 6, 0), radii[radii.size() - 1], 25.0, CREAM, 6.0)
	ell(b, paw, Vector3(29, 15, 29), CREAM, 5.0, true)
	for t in [-1.0, 0.0, 1.0]:
		ell(b, paw + Vector3(-17, -1.5, t * 17.5), Vector3(12, 13.5, 11), CREAM, 2.0, true)


# --- Distance field and surface nets ------------------------------------------------------

static func _dist(pr: Dictionary, p: Vector3) -> float:
	if pr.t == "ell":
		var q: Vector3 = pr.inv * (p - pr.c)
		var r: Vector3 = pr.r
		var k1 := (q / (r * r)).length()
		if k1 < 0.000001: return -minf(r.x, minf(r.y, r.z))
		var k0 := (q / r).length()
		return k0 * (k0 - 1.0) / k1
	var pa: Vector3 = p - pr.a
	var ba: Vector3 = pr.b - pr.a
	var h := clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (pa - ba * h).length() - lerpf(pr.ra, pr.rb, h)


static func _box(pr: Dictionary) -> AABB:
	var pad: float = pr.k + CELL * 2.0
	if pr.t == "ell":
		var r: Vector3 = pr.r
		var m := maxf(r.x, maxf(r.y, r.z))
		var e := Vector3(m, m, m) if pr.rot != Basis() else r
		return AABB(pr.c - e - Vector3.ONE * pad, (e + Vector3.ONE * pad) * 2.0)
	var lo: Vector3 = pr.a.min(pr.b)
	var hi: Vector3 = pr.a.max(pr.b)
	var m: float = maxf(pr.ra, pr.rb) + pad
	return AABB(lo - Vector3.ONE * m, hi - lo + Vector3.ONE * m * 2.0)


## Meshes one group of primitives. crease_col darkens where two creased puffs meet.
func _mesh(prims: Array, crease_col: Color, crease_width: float) -> ArrayMesh:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for pr in prims:
		var bx := _box(pr)
		lo = lo.min(bx.position)
		hi = hi.max(bx.end)
	var nx := int(ceil((hi.x - lo.x) / CELL)) + 1
	var ny := int(ceil((hi.y - lo.y) / CELL)) + 1
	var nz := int(ceil((hi.z - lo.z) / CELL)) + 1
	var nxy := nx * ny
	var n := nxy * nz
	var f := PackedFloat32Array(); f.resize(n); f.fill(10000.0)
	var best := PackedFloat32Array(); best.resize(n); best.fill(10000.0)
	var fd1 := PackedFloat32Array(); fd1.resize(n); fd1.fill(10000.0)
	var fd2 := PackedFloat32Array(); fd2.resize(n); fd2.fill(10000.0)
	var col := PackedColorArray(); col.resize(n); col.fill(prims[0].col)
	for pr in prims:
		var bx := _box(pr)
		var i0 := Vector3i(((bx.position - lo) / CELL).floor()).max(Vector3i.ZERO)
		var i1 := Vector3i(((bx.end - lo) / CELL).ceil()).min(Vector3i(nx - 1, ny - 1, nz - 1))
		var k: float = pr.k
		var c: Color = pr.col
		var creased: bool = pr.crease
		var paint: bool = pr.paint
		var sub: bool = pr.get("sub", false)
		for iz in range(i0.z, i1.z + 1):
			for iy in range(i0.y, i1.y + 1):
				var row := nx * (iy + ny * iz)
				for ix in range(i0.x, i1.x + 1):
					var d := _dist(pr, lo + Vector3(ix, iy, iz) * CELL)
					var idx := row + ix
					var a := f[idx]
					if sub:
						f[idx] = maxf(a, -d)
						if absf(d) < CELL:
							best[idx] = 0.0
							col[idx] = c
						continue
					if k > 0.0:
						var h := maxf(k - absf(a - d), 0.0) / k
						f[idx] = minf(a, d) - h * h * k * 0.25
					else:
						f[idx] = minf(a, d)
					if paint and d < CELL:
						# Painted features (inner ears) own the colour wherever they reach the skin.
						best[idx] = minf(d, best[idx])
						col[idx] = c
					elif d < best[idx]:
						best[idx] = d
						col[idx] = c
					if creased:
						if d < fd1[idx]:
							fd2[idx] = fd1[idx]
							fd1[idx] = d
						elif d < fd2[idx]:
							fd2[idx] = d
	# Crease shade per grid point (1 = plain colour).
	var shade := PackedFloat32Array(); shade.resize(n); shade.fill(1.0)
	for i in n:
		if fd2[i] < 1000.0:
			shade[i] = smoothstep(0.0, crease_width, fd2[i] - fd1[i])

	var cx1 := nx - 1
	var cy1 := ny - 1
	var cell_v := PackedInt32Array(); cell_v.resize(cx1 * cy1 * (nz - 1)); cell_v.fill(-1)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var offs := [0, 1, nx, nx + 1, nxy, nxy + 1, nxy + nx, nxy + nx + 1]
	var corner := [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0),
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
	var edges := [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]
	var vals := PackedFloat32Array(); vals.resize(8)
	for cz in nz - 1:
		for cy in ny - 1:
			for cx in nx - 1:
				var base := cx + nx * (cy + ny * cz)
				var neg := 0
				for j in 8:
					var v := f[base + offs[j]]
					vals[j] = v
					if v < 0.0: neg += 1
				if neg == 0 or neg == 8: continue
				var sum := Vector3.ZERO
				var hits := 0
				for e in edges:
					var va := vals[e[0]]
					var vb := vals[e[1]]
					if (va < 0.0) == (vb < 0.0): continue
					sum += corner[e[0]].lerp(corner[e[1]], va / (va - vb))
					hits += 1
				var local := sum / hits
				var p := lo + (Vector3(cx, cy, cz) + local) * CELL
				# One Newton step onto the true surface, then the field gradient as the normal.
				var g := _grad(f, lo, nx, ny, nz, p)
				if g.length() > 0.001:
					var step := clampf(_sample(f, lo, nx, ny, nz, p) / g.length(), -CELL * 0.5, CELL * 0.5)
					p -= g.normalized() * step
					g = _grad(f, lo, nx, ny, nz, p)
				# Colour: trilinear blend of the corner colours, darkened in creases.
				var cc := Color(0, 0, 0, 0)
				var sh := 0.0
				for j in 8:
					var w := (local.x if corner[j].x > 0.5 else 1.0 - local.x) * (local.y if corner[j].y > 0.5 else 1.0 - local.y) * (local.z if corner[j].z > 0.5 else 1.0 - local.z)
					cc += col[base + offs[j]] * w
					sh += shade[base + offs[j]] * w
				cc = crease_col.lerp(cc, sh)
				cc.a = 1.0
				cell_v[cx + cx1 * (cy + cy1 * cz)] = verts.size()
				verts.append(to_model(p))
				norms.append(normal_to_model(g.normalized()))
				cols.append(cc)
	var idx := PackedInt32Array()
	for z in range(1, nz - 1):
		for y in range(1, ny - 1):
			for x in range(1, nx - 1):
				var i := x + nx * (y + ny * z)
				var inside := f[i] < 0.0
				var c11 := x + cx1 * (y + cy1 * z)
				if (f[i + 1] < 0.0) != inside:
					_quad(idx, verts, norms, cell_v, [c11 - cx1 - cx1 * cy1, c11 - cx1 * cy1, c11, c11 - cx1])
				if (f[i + nx] < 0.0) != inside:
					_quad(idx, verts, norms, cell_v, [c11 - 1 - cx1 * cy1, c11 - cx1 * cy1, c11, c11 - 1])
				if (f[i + nxy] < 0.0) != inside:
					_quad(idx, verts, norms, cell_v, [c11 - 1 - cx1, c11 - cx1, c11, c11 - 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _quad(idx: PackedInt32Array, verts: PackedVector3Array, norms: PackedVector3Array, cell_v: PackedInt32Array, cells: Array) -> void:
	var q := []
	for c in cells:
		var v := cell_v[c]
		if v < 0: return
		q.append(v)
	for t in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
		var a := verts[t[0]]
		var n := norms[t[0]] + norms[t[1]] + norms[t[2]]
		# Godot front faces wind clockwise: flip when the winding faces along the normal.
		if (verts[t[1]] - a).cross(verts[t[2]] - a).dot(n) > 0.0:
			idx.append(t[0]); idx.append(t[2]); idx.append(t[1])
		else:
			idx.append(t[0]); idx.append(t[1]); idx.append(t[2])


static func _sample(f: PackedFloat32Array, lo: Vector3, nx: int, ny: int, nz: int, p: Vector3) -> float:
	var g := (p - lo) / CELL
	var x0 := clampi(int(floor(g.x)), 0, nx - 2)
	var y0 := clampi(int(floor(g.y)), 0, ny - 2)
	var z0 := clampi(int(floor(g.z)), 0, nz - 2)
	var tx := clampf(g.x - x0, 0.0, 1.0)
	var ty := clampf(g.y - y0, 0.0, 1.0)
	var tz := clampf(g.z - z0, 0.0, 1.0)
	var i := x0 + nx * (y0 + ny * z0)
	var nxy := nx * ny
	var a := lerpf(lerpf(f[i], f[i + 1], tx), lerpf(f[i + nx], f[i + nx + 1], tx), ty)
	var b := lerpf(lerpf(f[i + nxy], f[i + nxy + 1], tx), lerpf(f[i + nxy + nx], f[i + nxy + nx + 1], tx), ty)
	return lerpf(a, b, tz)


static func _grad(f: PackedFloat32Array, lo: Vector3, nx: int, ny: int, nz: int, p: Vector3) -> Vector3:
	var h := CELL
	return Vector3(
		_sample(f, lo, nx, ny, nz, p + Vector3(h, 0, 0)) - _sample(f, lo, nx, ny, nz, p - Vector3(h, 0, 0)),
		_sample(f, lo, nx, ny, nz, p + Vector3(0, h, 0)) - _sample(f, lo, nx, ny, nz, p - Vector3(0, h, 0)),
		_sample(f, lo, nx, ny, nz, p + Vector3(0, 0, h)) - _sample(f, lo, nx, ny, nz, p - Vector3(0, 0, h))) / (2.0 * h)


## Exact (unsampled) field of a group, for placing face details on the surface.
func _field(prims: Array, p: Vector3) -> float:
	var f := 10000.0
	for pr in prims:
		var d := _dist(pr, p)
		var k: float = pr.k
		if pr.get("sub", false):
			f = maxf(f, -d)
		elif k > 0.0:
			var h := maxf(k - absf(f - d), 0.0) / k
			f = minf(f, d) - h * h * k * 0.25
		else:
			f = minf(f, d)
	return f


## Front surface of the body at blueprint height y and lateral z: [point, outward normal].
func _face_point(y: float, z: float) -> Array:
	var p := P(560, y, z)
	while _field(_body, p) > 0.0 and p.x < 720.0:
		p.x += 0.25
	var e := 0.5
	var n := Vector3(
		_field(_body, p + Vector3(e, 0, 0)) - _field(_body, p - Vector3(e, 0, 0)),
		_field(_body, p + Vector3(0, e, 0)) - _field(_body, p - Vector3(0, e, 0)),
		_field(_body, p + Vector3(0, 0, e)) - _field(_body, p - Vector3(0, 0, e))).normalized()
	return [p, n]


# --- Face details -------------------------------------------------------------------------

## Eyes: thin raised "pillows" laid on the face (sclera, iris clipped by the eye outline,
## pupil) and a soft lid line along the top. Depths follow the real skin, so the eyes sit in
## the face under the brow rather than standing on it.
func _eyes() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		var hit := _fp(EYE_Y, side * EYE_Z)
		var s: Vector3 = hit[0]
		var n: Vector3 = hit[1]
		var right := Vector3.UP.cross(n).normalized()
		var frame := Basis(right, n.cross(right).normalized(), n)
		# The outline was traced in the front view: undo the foreshortening of the turned skin.
		frame.x /= clampf(absf(frame.x.z), 0.75, 1.0)
		frame.y /= clampf(absf(frame.y.y), 0.75, 1.0)
		var outline: Array = EYE_TOP.duplicate()
		outline.append_array(EYE_BOTTOM)
		g.color = SCLERA
		_pillow(g, s, frame, side, outline, Vector2(0.5, 0.0), 0.05, 0.8)
		var iris: Array = []
		for i in 32:
			var t := TAU * i / 32.0
			var q := IRIS_C + Vector2(cos(t) * IRIS_R.x, sin(t) * IRIS_R.y)
			q.y = clampf(q.y, _eye_edge(EYE_BOTTOM, q.x, -7.25) + 0.5, _eye_edge(EYE_TOP, q.x, 7.5) - 0.1)
			iris.append(q)
		g.color = IRIS
		_pillow(g, s, frame, side, iris, IRIS_C, 0.75, 0.3)
		var pupil: Array = []
		for i in 20:
			var t := TAU * i / 20.0
			pupil.append(IRIS_C + Vector2(0, -0.6) + Vector2(cos(t) * PUPIL_R.x, sin(t) * PUPIL_R.y))
		g.color = PUPIL
		_pillow(g, s, frame, side, pupil, IRIS_C + Vector2(0, -0.6), 1.14, 0.12)
		g.color = SHINE
		var shine := s + frame * Vector3(side * (IRIS_C.x - 1.3), IRIS_C.y + 2.6, _skin(s, frame, side, IRIS_C.x - 1.3, IRIS_C.y + 2.6) + 1.2)
		g.ellipsoid(shine, Vector3(0.8, 0.7, 0.2), frame, 10, 5)
		# Lid line along the top edge (a little past the outer corner), thickest mid-way.
		var line := []
		var pts: Array = EYE_TOP.duplicate()
		pts.append(Vector2(9.8, 6.2))
		for q in pts:
			var lift := 1.3 if q.x < 1.0 else 0.7
			# Lifted toward the front (not along the turned skin), so the line stays on the outline.
			line.append(s + frame * Vector3(side * q.x, q.y + 0.1, _skin(s, frame, side, q.x, q.y) + 0.3) + Vector3(-lift, 0, 0))
		var widths := []
		for i in pts.size():
			var w := 0.35 + 0.5 * sin(PI * float(i) / float(pts.size() - 1))
			widths.append(Vector2(w, w))
		g.color = LID_LINE
		g.loft(line, widths, n, 6)
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i])
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


## Height of the eye outline's top or bottom chain at `o` (outward), linearly between points.
static func _eye_edge(chain: Array, o: float, fallback: float) -> float:
	var pts := chain.duplicate()
	pts.sort_custom(func(p, q): return p.x < q.x)
	if o <= pts[0].x: return pts[0].y
	for i in pts.size() - 1:
		if o <= pts[i + 1].x:
			return lerpf(pts[i].y, pts[i + 1].y, (o - pts[i].x) / (pts[i + 1].x - pts[i].x))
	return pts[pts.size() - 1].y if pts.size() > 0 else fallback


## Lion only: _face_point at a true sheet height.
func _fp(y: float, z: float) -> Array:
	return _face_point(y - SHEET_DY, z)


## Skin depth along the face normal at (o, u) of an eye's frame (0 = the eye centre's surface).
func _skin(s: Vector3, frame: Basis, side: float, o: float, u: float) -> float:
	var n: Vector3 = frame.z
	var p := s + frame * Vector3(side * o, u, 6.0)
	var t := 6.0
	while _field(_body, p) > 0.0 and t > -8.0:
		p -= n * 0.2
		t -= 0.2
	return t


## Raised pad over a closed outline (o, u): rings shrink toward `centre`; the top is `rim` above
## the skin at the edge and `rim + height` at the centre (an ellipse profile).
func _pillow(g, s: Vector3, frame: Basis, side: float, outline: Array, centre: Vector2, rim: float, height: float) -> void:
	var rings := [1.0, 0.92, 0.78, 0.58, 0.32, 0.0]
	var grid := []
	var ngrid := []
	for r in rings:
		var row := []
		var nrow := []
		var h: float = sqrt(maxf(1.0 - r * r, 0.0))
		var rr := minf(r, 0.96)
		var slope: float = height * rr / sqrt(1.0 - rr * rr)
		for q in outline:
			var e: Vector2 = q - centre
			var o: Vector2 = centre + e * r
			var d := _skin(s, frame, side, o.x, o.y) + rim + height * h
			row.append(s + frame * Vector3(side * o.x, o.y, d))
			var dir := e.normalized()
			var ln: Vector3 = Vector3(side * dir.x * slope / maxf(e.length(), 0.5), dir.y * slope / maxf(e.length(), 0.5), 1.0).normalized()
			nrow.append((frame * ln + frame.z * 0.6).normalized())
		grid.append(row)
		ngrid.append(nrow)
	var m: int = outline.size()
	for k in rings.size() - 1:
		for j in m:
			var j2 := (j + 1) % m
			g.quad(grid[k][j], grid[k][j2], grid[k + 1][j2], grid[k + 1][j], ngrid[k][j], ngrid[k][j2], ngrid[k + 1][j2], ngrid[k + 1][j])


func _details() -> ArrayMesh:
	var g := Plaza.Geo.new()
	for side in [-1.0, 1.0]:
		# Whiskers: three per side from the outer edge of the pale pad, fanning (level, a
		# little down, down) and sweeping out past the face over the mane.
		for w in 3:
			var root_hit := _fp([246.0, 254.0, 261.0][w], side * 30.0)
			var r0: Vector3 = root_hit[0] + root_hit[1] * 0.4
			var to_tip: Vector3 = [Vector3(21, 1, 39), Vector3(23, -6, 38), Vector3(18, -13, 31)][w]
			to_tip.z *= side
			var mid := r0 + Vector3(to_tip.x * 0.3, to_tip.y * 0.35 + 1.0, to_tip.z * 0.5)
			g.color = WHISKER
			g.loft([r0, mid, r0 + to_tip], [Vector2(1.15, 1.15), Vector2(0.95, 0.95), Vector2(0.45, 0.45)], Vector3.UP, 5)
	# Nose: the sheet's wide inverted triangle (30 px across the flat top, 14 px tall, rounded
	# corners and tip): an ellipsoid whose width is redrawn row by row.
	g.color = NOSE
	var nose_c: Vector3 = _fp(248.5, 0.0)[0] + Vector3(1.0, 0, 0)
	var nose_r := Vector3(4.5, 7.0, 15.0)
	var first := g.verts.size()
	g.ellipsoid(nose_c, nose_r, Basis(), 24, 12)
	for i in range(first, g.verts.size()):
		var q: Vector3 = g.verts[i] - nose_c
		var yn := clampf(q.y / nose_r.y, -1.0, 1.0)
		var across := clampf(q.z / (nose_r.z * sqrt(maxf(1.0 - yn * yn, 0.0004))), -1.0, 1.0)
		var t := (yn + 1.0) * 0.5
		var half := nose_r.z * lerpf(0.16, 1.0, pow(t, 0.85)) * (1.0 - 0.22 * smoothstep(0.8, 1.0, t))
		g.verts[i] = nose_c + Vector3(q.x, q.y, across * half)
	# Mouth: philtrum from the nose tip, then a shallow downturned line each way.
	var mouth := []
	for pt in [[255.0, 0.0], [263.75, 0.0]]:
		var h := _fp(pt[0], pt[1])
		mouth.append(h[0] + h[1] * 0.4)
	g.color = LID
	g.loft(mouth, [Vector2(0.75, 0.75), Vector2(0.75, 0.75)], Vector3.RIGHT, 6)
	for side in [-1.0, 1.0]:
		var curve := []
		for pt in [[263.75, 0.0], [265.5, side * 5.0], [267.5, side * 10.0], [268.75, side * 13.75]]:
			var h := _fp(pt[0], pt[1])
			curve.append(h[0] + h[1] * 0.4)
		g.loft(curve, [Vector2(0.75, 0.75), Vector2(0.75, 0.75), Vector2(0.65, 0.65), Vector2(0.4, 0.4)], Vector3.RIGHT, 6)
	for i in g.verts.size():
		g.verts[i] = to_model(g.verts[i])
		g.norms[i] = normal_to_model(g.norms[i])
	return g.commit()


# --- Scene --------------------------------------------------------------------------------

static func _material(roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = roughness
	return m


func build_display() -> Node3D:
	_body.clear(); _mane.clear(); _tuft.clear(); _ears.clear()
	_shape()
	var root := Node3D.new()
	root.name = "LionClayDisplay"
	root.set_meta("source", "User's Lion Character Blueprint, relax crawl pose (10 Nov 2026)")
	var clay := _material(0.86)
	# Matte, velvety mane: no shine, low specular (11 Nov 2026).
	var hair := _material(1.0)
	hair.metallic_specular = 0.15
	for part in [["Body", _body, PAW_CREASE, 7.0], ["Mane", _mane, MANE_HAIR_CREASE, 9.0], ["Tail tuft", _tuft, MANE_HAIR_CREASE, 8.0], ["Ears", _ears, PAW_CREASE, 7.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh(part[1], part[2], part[3])
		mi.material_override = hair if part[0] == "Mane" else clay
		root.add_child(mi)
	var eyes := MeshInstance3D.new()
	eyes.name = "Eyes"
	eyes.mesh = _eyes()
	eyes.material_override = _material(0.65)
	eyes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(eyes)
	var face := MeshInstance3D.new()
	face.name = "Face details"
	face.mesh = _details()
	face.material_override = _material(0.55)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(face)
	# Static collision: one box around the body and mane (it is a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var lo := to_model(Q(588, 359, -102)).min(to_model(Q(960, 129, 102)))
	var hi := to_model(Q(588, 359, -102)).max(to_model(Q(960, 129, 102)))
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
