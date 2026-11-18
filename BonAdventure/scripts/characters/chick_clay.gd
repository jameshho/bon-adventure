extends "res://scripts/characters/cow_clay.gd"
## Clay-style chick traced from the user's "Chick Character Blueprint" turnaround (16 Nov 2026,
## "Relaxed Idle": front 3/4, front, side, back, rear 3/4). A static display model, built once
## by tools/build_chick_clay.gd into scenes/animals/chick_clay.tscn.
##
## Reuses the clay lion's distance-field mesher (lion_clay.gd), the clay giraffe's skin painting
## (giraffe_clay.gd: _tint, _paint) and the clay cow's helpers (cow_clay.gd: _ray).
## Shapes are written in the chick sheet's side-view pixels (x to the right = toward the tail,
## y down, z lateral, + = the side facing the viewer = the chick's left) and H() scales them
## into the lion's working space. The chick is small, so it is meshed HF times larger than life
## and shrunk afterwards: the clay grid is 3 cm / HF on the finished model.
##
## Ready for rigging, like the clay pig: head, body, legs and feet are one fused mesh ("Body");
## beak, crest, wings and tail are separate clay pieces; each eye is its own mesh ("LeftEye",
## "RightEye") centred on its node, local y up the eye and z out of the face. The cream belly
## and the blush are painted; the mouth line is the step between the two halves of the beak.
## The chick has no brows or smile lines, so there is no "Face details" part.
## Output faces -Z (head), +Y up, ground at y = 0.

const HH := 0.4                 # town units to the top of the crown feathers (user, 18 Nov 2026: as built)
const HY := 522.0               # sheet y of the soles
const HTOP := 181.0             # sheet y of the top of the crest
const HX := 950.0               # sheet x placed at the model origin
const HF := 9.0                 # meshed this many times larger than life
const HK := HF * HH / ((HY - HTOP) * S)   # sheet pixel -> lion working unit

const H_YELLOW := Color("efc566")
const H_YELLOW_CREASE := Color("dba93c")
const H_BELLY := Color("ffe6ae")
const H_WING := Color("f3cd70")
const H_WING_CREASE := Color("e0b03e")
const H_BEAK := Color("f59a2e")
const H_BEAK_LOW := Color("e87f1a")
const H_BEAK_CREASE := Color("d86c12")
const H_LEG := Color("f4932b")
const H_LEG_CREASE := Color("d8781c")
const H_BLUSH := Color("f8ab80")
const H_EYE_SHADE := Color("c98f2e")
const H_SCLERA := Color("f4e6ca")
const H_IRIS := Color("5a3008")
const H_PUPIL := Color("120801")
const H_GLINT := Color("ffffff")

# Eyes (sheet px), from the front view: centre height, lateral offset, half-sizes across the
# skin (33 px wide seen from the front on a face that turns 31 degrees away there, 44 tall),
# and how far the top leans toward the beak.
const H_EYE_Y := 307.5
const H_EYE_Z := 56.0
const H_EYE_R := Vector2(20.0, 22.5)
const H_EYE_LEAN := -0.06
const H_EYE_LIFT := 0.3          # the eye's edge above the skin
const H_EYE_BULGE := 3.8         # extra height at the middle: a gently domed bead

## Legs as [sheet x, lateral z]: standing square.
const H_LEGS := [[968.0, -40.0], [968.0, 40.0]]

var _wings := []
var _tail := []


## Sheet pixel -> working space (y up).
static func H(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3(X0 + (x - HX) * HK, (HY - y) * HK, z * HK)


func he(g: Array, c: Vector3, r: Vector3, col: Color, k := 0.0, crease := false, basis := Basis()) -> void:
	ell(g, c, r * HK, col, k * HK, crease, basis)


func hc(g: Array, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, k := 0.0) -> void:
	cone(g, a, b, ra * HK, rb * HK, col, k * HK)


## Rotation about the lateral axis: positive raises the tail end of a shape.
static func tilt(a: float) -> Basis:
	return Basis(Vector3(0, 0, 1), a)


# --- Shape --------------------------------------------------------------------------------

func _shape() -> void:
	var b := _body
	# Two round volumes (user, 18 Nov 2026): a large ball of a head, a little wider than long,
	# sitting on a smaller plump body. They meet in a soft fold: the neck is narrower than
	# both, and the blends are small so each volume keeps its own roundness.
	he(b, H(932, 324), Vector3(106, 102, 112), H_YELLOW, 18.0)     # k only widens its grid box for the later blends
	# Cheeks: the head is fullest low down, and stays wide right to the tops of the wings.
	he(b, H(928, 350), Vector3(100, 66, 111), H_YELLOW, 14.0)
	# Throat and lower face: the fullest part of the front, so the face runs straight into the
	# chest; the fold shows at the sides and the back, not under the beak.
	he(b, H(886, 366), Vector3(66, 56, 86), H_YELLOW, 16.0)
	# Body: one plump round volume, narrower than the head at the shoulders; it widens into a
	# flat-bottomed belly low at the sides (kept back from the front, where the belly tucks
	# under); and a rump that stands out behind the head (its top is the fold seen from the back).
	he(b, H(952, 410), Vector3(126, 76, 92), H_YELLOW, 14.0)
	he(b, H(960, 438), Vector3(106, 48, 100), H_YELLOW, 16.0)
	# Belly: full and round in front too, so the body is plump from the 3/4 view.
	he(b, H(897, 428), Vector3(73, 62, 85), H_YELLOW, 16.0)
	he(b, H(1000, 412), Vector3(78, 62, 86), H_YELLOW, 12.0)

	# Legs and feet (same fused mesh): short stalks; three fat round toes pointing forward.
	for leg in H_LEGS:
		var x: float = leg[0]
		var z: float = leg[1]
		hc(b, H(x, 476, z), H(x, 506, z), 12.5, 12.0, H_LEG, 3.0)
		he(b, H(x + 8.0, 510.5, z), Vector3(13.5, 11.5, 12.5), H_LEG, 4.0)
		for toe in [-21.5, 0.0, 21.5]:      # round tips that just touch, so the three toes read apart
			hc(b, H(x - 8.0, 510.5, z + toe * 0.5), H(x - 43.0, 510.0, z + toe), 11.5, 11.5, H_LEG, 0.0)
	for leg in H_LEGS:
		carve(b, H(leg[0] - 20.0, HY + 40.0, leg[1]), Vector3(140, 40, 140) * HK, H_LEG)

	# Beak: a short rounded cone, its tip a little raised. Both halves are widest at the mouth:
	# the upper is a soft-peaked roof (a low wide puff and a tall narrow one, cut flat underneath), the lower is shallower, narrower and darker, so the
	# mouth shows as a step with a darker edge right round.
	var m := _muzzle
	he(m, H(835, 333), Vector3(37, 11, 24), H_BEAK, 0.0, false, tilt(-0.14))
	he(m, H(836, 333), Vector3(36, 20.5, 13), H_BEAK, 10.0, false, tilt(-0.14))
	carve(m, H(835, 333) + tilt(-0.14) * Vector3(0, -60.0 * HK, 0), Vector3(150, 60, 160) * HK, H_BEAK, tilt(-0.14))
	ell(m, H(838, 336), Vector3(31, 12.5, 22) * HK, H_BEAK_LOW, 0.0, false, tilt(-0.14), true)    # painted: owns its colour

	# Crown feathers (rebuilt 18 Nov 2026): three smooth curved feathers that overlap. The tall
	# one sweeps up and back and leans to the chick's left; a lower one lies behind it on the
	# left and a short one stands beside it on the right. Each is one curved round-ended tube.
	var c := _mane
	_plume(c, Vector3(918, 221, 17), Vector3(945, 207, 22), Vector3(961, 214, 24), 11.5, 12.5, 10.5)
	_plume(c, Vector3(900, 221, -25), Vector3(905, 206, -29), Vector3(919, 208, -29), 11.0, 12.0, 10.5)
	_plume(c, Vector3(903, 221, -10), Vector3(912, 191, 0), Vector3(946, 196.5, 17), 13.0, 15.0, 12.0)

	_wing_feathers()

	# Tail: three short round-ended tufts fanned off the rump.
	var t := _tail
	he(t, H(1064, 392), Vector3(20, 32, 24), H_WING, 0.0)
	for tip in [H(1086, 368), H(1095, 392, -9), H(1095, 392, 9), H(1086, 416)]:
		hc(t, H(1064, 392), tip, 14.5, 13.0, H_WING, 3.0)

	# Belly: a pale cream patch over the front and underside, soft-edged.
	_tint(H(855, 468), Vector3(100, 85, 105) * HK, Basis(), H_BELLY, 12.0 * HK)
	# Blush: a soft round patch on each cheek, below and outside the eye.
	for side in [-1.0, 1.0]:
		var hit := _ray(_body, H(600, 344, side * 78.0), Vector3(1, 0, 0))
		_tint(hit[0], Vector3(17, 17, 17) * HK, Basis(), H_BLUSH, 14.0 * HK)
	# A soft shade in the skin round each eye, heaviest over the top, so the eye sits in the face.
	for side in [-1.0, 1.0]:
		var f := _chick_eye_frame(side)
		_tint(f[0] + f[3] * 1.5 * HK, Vector3(H_EYE_R.x + 1.0, H_EYE_R.y + 1.5, 10.0) * HK, Basis(f[2], f[3], f[1]), H_EYE_SHADE, 5.0 * HK)


## One smooth curved feather: a round-ended tube along the curve from p0 to p2 that bends
## toward p1 (sheet px: x, y, lateral z), r0 / r1 / r2 thick at its root, middle and tip.
func _plume(g: Array, p0: Vector3, p1: Vector3, p2: Vector3, r0: float, r1: float, r2: float) -> void:
	var steps := 10
	var last := Vector3.ZERO
	var last_r := 0.0
	for i in steps + 1:
		var t := float(i) / steps
		var q := p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * t * (1.0 - t) + p2 * t * t
		var at := H(q.x, q.y, q.z)
		var r := r0 * 2.0 * (t - 0.5) * (t - 1.0) - r1 * 4.0 * t * (t - 1.0) + r2 * 2.0 * t * (t - 0.5)
		if i > 0:
			hc(g, last, at, last_r, r, H_YELLOW, 3.0)
		last = at
		last_r = r


## Middle of a wing in the sheet's side view.
const H_WING_AT := Vector2(975.0, 402.0)

## One piece of a wing: a flattened puff in the wing's own plane (`frame` = [point on the
## flank, along the body toward the tail, up the flank, outward]) at sheet (x, y). r = half
## length, half width, half thickness (sheet px); `a` turns it in the side view (positive
## raises the tail end); `lift` raises its middle off the plane.
func _wing_piece(frame: Array, x: float, y: float, r: Vector3, a: float, lift: float, k: float) -> void:
	var at: Vector3 = frame[0] + (frame[1] * (x - H_WING_AT.x) + frame[2] * (H_WING_AT.y - y) + frame[3] * lift) * HK
	var along: Vector3 = frame[1] * cos(a) + frame[2] * sin(a)
	he(_wings, at, r, H_WING, k, false, Basis(along, frame[3].cross(along).normalized(), frame[3]))


## Wings (rebuilt 18 Nov 2026): each is one smooth oval dome on the flank, right under the
## cheek, with three round feather tips showing from under its rear edge as soft scallops. The
## wing is a thick pad lying along the flank, so from the front and the 3/4 view it shows as a
## round pad beside the body, as on the sheet; its upper edge runs straight into the top tip.
func _wing_feathers() -> void:
	for side in [-1.0, 1.0]:
		var hit := _ray(_body, H(H_WING_AT.x, H_WING_AT.y, side * 220.0), Vector3(0, 0, -side))
		var n: Vector3 = hit[1]
		var along := (Vector3(1, 0, 0) - n * n.x).normalized()
		var up := along.cross(n).normalized()
		if up.y < 0.0: up = -up
		var turn := -0.08
		var frame := [hit[0], (along * cos(turn) - n * sin(turn)).normalized(), up, (n * cos(turn) + along * sin(turn)).normalized()]
		_wing_piece(frame, 1036, 387, Vector3(27, 17, 11), 0.2, 12.0, 9.0)
		_wing_piece(frame, 1027, 414, Vector3(24, 16, 11), -0.25, 12.0, 9.0)
		_wing_piece(frame, 1004, 433, Vector3(22, 16, 11), -0.55, 12.0, 9.0)
		_wing_piece(frame, 1008, 383, Vector3(44, 22, 18), 0.15, 14.0, 12.0)
		_wing_piece(frame, 976, 402, Vector3(54, 43, 26), 0.15, 17.0, 12.0)


# --- Eyes ---------------------------------------------------------------------------------

## The skin under an eye and its frame: [centre, outward normal, toward the outer corner, up].
func _chick_eye_frame(side: float) -> Array:
	var hit := _ray(_body, H(700, H_EYE_Y, side * H_EYE_Z), Vector3(1, 0, 0))
	var n: Vector3 = hit[1]
	var right := Vector3.UP.cross(n).normalized()
	var out := right * side
	var up := n.cross(right).normalized()
	# The top of the eye leans toward the beak.
	return [hit[0], n, (out * cos(H_EYE_LEAN) + up * sin(H_EYE_LEAN)).normalized(), (up * cos(H_EYE_LEAN) - out * sin(H_EYE_LEAN)).normalized()]


## A point of the eye's surface at (o, u) sheet px from its centre (o toward the outer corner,
## u up the eye): on the head's skin, lifted H_EYE_LIFT plus the bulge, plus `extra`.
func _eye_point(f: Array, o: float, u: float, extra := 0.0) -> Vector3:
	var n: Vector3 = f[1]
	var p: Vector3 = f[0] + (f[2] * o + f[3] * u) * HK + n * 8.0 * HK
	for i in 400:
		var d := _field(_body, p)
		if d <= 0.02: break
		p -= n * maxf(d * 0.6, 0.02)
	var t2 := minf(pow(o / H_EYE_R.x, 2.0) + pow(u / H_EYE_R.y, 2.0), 1.0)
	return p + n * (H_EYE_LIFT + H_EYE_BULGE * (1.0 - t2) + extra) * HK


## Colour of the eye at (o, u): a glossy near-black pupil that fills most of it, a dark brown
## iris showing as a band along the bottom and thinly up the sides, and a hairline of warm
## white down the outer edge.
static func _eye_colour(o: float, u: float) -> Color:
	var iris := Vector2((o + 1.0) / (H_EYE_R.x - 0.2), u / (H_EYE_R.y + 0.6)).length()
	var pupil := Vector2((o + 1.0) / (H_EYE_R.x - 6.0), (u - 2.4) / (H_EYE_R.y - 7.0)).length()
	var col := H_PUPIL.lerp(H_IRIS, smoothstep(0.8, 1.15, pupil))
	return col.lerp(H_SCLERA, smoothstep(0.985, 1.015, iris))


## One eye: [mesh in the eye's own frame, that frame in model space]. A single domed surface
## that follows the head (painted, like the pig's), with one round catch-light high on the
## beak side of the pupil. Local y is up the eye and z out of the face, so it can blink.
func _chick_eye(side: float) -> Array:
	var f := _chick_eye_frame(side)
	var n: Vector3 = f[1]
	var g := Plaza.Geo.new()
	var rings := 30
	var segs := 64
	# Grid: ring 0 is the centre; the last ring is a skirt tucked under the skin.
	var pts := []
	var cols := []
	for i in rings + 2:
		var t := minf(float(i) / rings, 1.0)
		var row := PackedVector3Array()
		var crow := PackedColorArray()
		for j in segs:
			var a := TAU * j / segs
			var o := t * H_EYE_R.x * cos(a)
			var u := t * H_EYE_R.y * sin(a)
			row.append(_eye_point(f, o, u, -1.2 if i > rings else 0.0))
			crow.append(_eye_colour(o, u))
		pts.append(row)
		cols.append(crow)
	var nrm := []
	for i in rings + 2:
		var row := PackedVector3Array()
		for j in segs:
			if i == 0 or i > rings:
				row.append(n if i == 0 else nrm[rings][j])
				continue
			var across: Vector3 = pts[i][(j + 1) % segs] - pts[i][(j + segs - 1) % segs]
			var along: Vector3 = pts[i + 1 if i < rings else i][j] - pts[i - 1][j]
			var v := across.cross(along).normalized()
			row.append(v if v.dot(n) > 0.0 else -v)
		nrm.append(row)
	for i in rings + 1:
		for j in segs:
			var j2 := (j + 1) % segs
			for tri in [[[i, j], [i + 1, j], [i + 1, j2]], [[i, j], [i + 1, j2], [i, j2]]]:
				if i == 0 and tri[2] == [i, j2]: continue      # the centre ring is one point
				for corner in tri:
					g.color = cols[corner[0]][corner[1]]
					g.cols.append(g.color)
				var a3: Vector3 = pts[tri[0][0]][tri[0][1]]
				var b3: Vector3 = pts[tri[1][0]][tri[1][1]]
				var c3: Vector3 = pts[tri[2][0]][tri[2][1]]
				var flip := (b3 - a3).cross(c3 - a3).dot(n) > 0.0
				var order := [0, 2, 1] if flip else [0, 1, 2]
				if flip:
					var keep: Color = g.cols[g.cols.size() - 1]
					g.cols[g.cols.size() - 1] = g.cols[g.cols.size() - 2]
					g.cols[g.cols.size() - 2] = keep
				for k in order:
					g.verts.append(pts[tri[k][0]][tri[k][1]])
					g.norms.append(nrm[tri[k][0]][tri[k][1]])
	# Catch-light: a small round white spot riding on the dome.
	var at := Vector2(-3.6, 10.4)
	var gr := Vector2(4.4, 4.7)
	g.color = H_GLINT
	var mid := _eye_point(f, at.x, at.y, 0.6)
	var rim := []
	for j in 24:
		var a := TAU * j / 24.0
		rim.append(_eye_point(f, at.x + gr.x * cos(a), at.y + gr.y * sin(a), 0.4))
	for j in 24:
		g.tri(mid, rim[j], rim[(j + 1) % 24], n, n, n)
	# Into the eye's own frame (model space, life size).
	var zm := normal_to_model(n).normalized()
	var ym := normal_to_model(f[3]).normalized()
	var xm := ym.cross(zm).normalized()
	var basis := Basis(xm, zm.cross(xm).normalized(), zm)
	var origin := to_model(f[0]) / HF
	var inv := basis.inverse()
	for i in g.verts.size():
		g.verts[i] = inv * (to_model(g.verts[i]) / HF - origin)
		g.norms[i] = inv * normal_to_model(g.norms[i])
	return [g.commit(), Transform3D(basis, origin)]


## The belly's cream stops at the legs: orange clay is never tinted.
func _tinted(v: Vector3, col: Color, reach: Array) -> Color:
	if col.b < 0.28:
		_crisp = 0.0
		return col
	return super(v, col, reach)


## Meshes a small part `factor` times finer than the clay grid: the shapes are enlarged about
## the working origin, meshed, and the mesh is shrunk back.
func _mesh_fine(prims: Array, crease_col: Color, crease_width: float, factor: float) -> ArrayMesh:
	var big := []
	for pr in prims:
		var q: Dictionary = pr.duplicate()
		for key in ["c", "r", "a", "b", "ra", "rb", "k"]:
			if q.has(key): q[key] = q[key] * factor
		big.append(q)
	var mesh := _mesh(big, crease_col, crease_width * factor)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var shift := Vector3(0, 0, X0 * S)
	for i in verts.size():
		verts[i] = (verts[i] + shift) / factor - shift
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Shrinks a clay mesh from its meshing size to life size.
func _fit(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] /= HF
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


# --- Scene --------------------------------------------------------------------------------

func build_display() -> Node3D:
	for group in [_body, _mane, _tuft, _ears, _tints, _muzzle, _muzzle_tints, _wings, _tail]:
		group.clear()
	_shape()
	var root := Node3D.new()
	root.name = "ChickClayDisplay"
	root.set_meta("source", "User's Chick Character Blueprint, relaxed idle (16 Nov 2026)")
	var clay := _material(0.86)
	for part in [["Body", _body, H_YELLOW_CREASE, 5.0], ["Beak", _muzzle, H_BEAK_CREASE, 1.2], ["Crest", _mane, H_YELLOW_CREASE, 4.0],
			["Wings", _wings, H_WING_CREASE, 3.0], ["Tail", _tail, H_WING_CREASE, 3.0]]:
		var mi := MeshInstance3D.new()
		mi.name = part[0]
		mi.mesh = _mesh_fine(part[1], part[2], part[3], 2.0 if part[0] == "Beak" else 1.5) if part[0] in ["Beak", "Crest", "Tail"] else _mesh(part[1], part[2], part[3])
		if part[0] == "Body":
			mi.mesh = _paint(mi.mesh)
		mi.mesh = _fit(mi.mesh)
		mi.material_override = clay
		root.add_child(mi)
	var glossy := _material(0.3)
	glossy.metallic_specular = 0.2
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var built := _chick_eye(side[1])
		var eye := MeshInstance3D.new()
		eye.name = side[0]
		eye.mesh = built[0]
		eye.transform = built[1]
		eye.material_override = glossy
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(eye)
	# Static collision: one box round the body and head (a display, not an animal).
	var body := StaticBody3D.new()
	body.name = "Footprint"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var a := to_model(H(800, HY, -110)) / HF
	var c := to_model(H(1105, HTOP, 110)) / HF
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
