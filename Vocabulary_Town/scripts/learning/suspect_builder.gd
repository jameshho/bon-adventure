extends RefCounted
## Builds one lineup suspect for the police lineup game (6 Nov 2026; redrawn 7 Nov 2026): the
## bear plush (scenes/characters/bear_plush.tscn) with its own ears, eyes, blush and muzzle, in
## a light coat so hair reads clearly, with hair, a beard or moustache, a big, medium or small
## nose, a shirt in the suspect's colour and a tall, medium or short height. Every tested
## feature comes from the same suspect dictionary the clues are checked against
## (detective_clues.gd), with colours and sizes from data/detective_game.json "lineup.looks".
## Women get eyelashes and never facial hair. Blush size and ear tilt vary at random and are
## never named by a clue.
## Hair and beard are shells fitted to the bear's own body profile (`_section`): the hair hugs
## the head down to a hairline with combed grooves and a fringe; long hair falls behind the
## cheeks to the shoulders, flares out and ends in a rounded roll ("Hair back"); the beard
## covers the jaw from sideburn to sideburn.
## Works in the bear's model space: +Y up, faces -Z, head top at y 2.18. The bear's parts are
## re-centred meshes (pig_sculpt.gd _put): change them through their own transforms.
const BEAR := "res://scenes/characters/bear_plush.tscn"
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
## The suspect's size in the world (BonBon-sized plushes are 1.0), before its height factor.
const BASE_SCALE := 0.95
const FACIAL_DEFAULT := "5e4234"
const WHITE := "fdfbf6"
## Direction of the face around the body (the costume's FRONT): -Z.
const FRONT := -PI * 0.5
const HEAD_CENTER := Vector3(0, 1.75, 0)

## A new suspect under `parent`, standing at `spot` (global, floor level) and facing `facing`
## (global direction). `index` is stored as meta "detective_index" on the root and its pick area.
static func build(suspect: Dictionary, looks: Dictionary, parent: Node3D, spot: Vector3, facing: Vector3, index: int) -> Node3D:
	var bear: Node3D = load(BEAR).instantiate()
	bear.name = "Suspect%d" % (index + 1)
	bear.set("fur_color", Color(str(looks.get("fur", "f6f0e2"))))
	if looks.has("muzzle"):
		bear.set("muzzle_color", Color(str(looks.muzzle)))
	if looks.has("ear_inner"):
		bear.set("bear_ear_inner_color", Color(str(looks.ear_inner)))
	bear.remove_meta("word_key")
	parent.add_child(bear)
	var study := bear.get_node_or_null("StudyArea")
	if study:
		study.free()
	# Height scales mostly upward: a tall suspect is a little taller and only slightly wider.
	var height: float = float(looks.get("height", {}).get(str(suspect.height), 1.0))
	var width: float = float(looks.get("width", {}).get(str(suspect.height), 1.0))
	var basis := Basis.looking_at(Vector3(facing.x, 0, facing.z).normalized(), Vector3.UP).scaled(Vector3(width, height, width) * BASE_SCALE)
	bear.global_transform = Transform3D(basis, spot)
	bear.set_meta("detective_index", index)
	# Dressed first, while the bear is exactly as the sculpt cache built it, so the shirt (only
	# measured from the body) comes from the cache too: one entry per shirt colour.
	var shirt_hex: String = str(looks.get("shirt", {}).get(str(suspect.shirt), "888888"))
	PlushCostume.dress_pieces(bear, [{"piece": "shirt", "color": shirt_hex, "sleeve": 0.42, "bottom": 0.5,
		"collar": true, "collar_round": true, "collar_color": WHITE, "stand_collar": true,
		"buttons": WHITE, "button_count": 2, "button_size": 0.026, "button_step": 0.12}])
	var hair_hex: String = str(looks.get("hair_color", {}).get(str(suspect.get("hair_color", "")), FACIAL_DEFAULT))
	var hair_color := Color(hair_hex)
	var hair_mat: Material = bear._soft_mat(hair_color, 0.8)
	match str(suspect.hair):
		"short":
			_add(bear, "Hair", bear._merge([_cap(bear, false, hair_mat), bear._blobs(_fringe(bear, false), hair_mat)], hair_mat))
		"long":
			_add(bear, "Hair", bear._merge([_cap(bear, true, hair_mat), bear._blobs(_fringe(bear, true), hair_mat)], hair_mat))
			_add(bear, "Hair back", _locks(bear, hair_mat))
	# Facial hair matches the hair (a bald man's is dark brown).
	var face_color := hair_color if str(suspect.get("hair_color", "")) != "" else Color(FACIAL_DEFAULT)
	var face_mat: Material = bear._soft_mat(face_color, 0.8)
	var nose := bear.get_node_or_null("Head/Muzzle/Nose") as MeshInstance3D
	var nose_scale: float = float(looks.get("nose", {}).get(str(suspect.nose), 1.0))
	match str(suspect.facial_hair):
		"beard":
			_add(bear, "Beard", _beard(bear, face_mat, str(suspect.hair) == "bald"))
		"moustache":
			_add(bear, "Moustache", _moustache(bear, nose, nose_scale, face_mat))
	if nose != null and nose.mesh != null:
		# A white gloss dot on the upper left of the nose; it scales with the nose. The nose
		# mesh is centred on its node, so it grows about its own middle.
		var box: AABB = nose.mesh.get_aabb()
		var gloss := MeshInstance3D.new()
		gloss.name = "Nose gloss"
		gloss.mesh = bear._blobs([[Vector3(-box.size.x * .2, box.size.y * .2, box.position.z + .012), Vector3(.017, .011, .008)]], bear._soft_mat(Color("ffffff"), 0.0))
		nose.add_child(gloss)
		nose.scale = Vector3.ONE * nose_scale
		# The "w" mouth sits just under the nose: a bigger nose would cover it and leave its
		# top poking out below as dark lumps (seen 8 Nov 2026), so it moves down as the nose grows.
		var mouth := nose.get_parent().get_node_or_null("Mouth") as Node3D
		if mouth != null and nose_scale > 1.0:
			mouth.position.y -= box.size.y * .5 * (nose_scale - 1.0) + .006
	if str(suspect.gender) == "f":
		_add(bear, "Eyelash", _lashes(bear))
	_vary_face(bear)
	# One pick box for the whole suspect (the costume has no collision).
	var area := Area3D.new()
	area.name = "SuspectPick"
	area.set_meta("detective_index", index)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.5, 2.3, 1.3)
	shape.shape = box_shape
	shape.position = Vector3(0, 1.15, 0)
	area.add_child(shape)
	bear.add_child(area)
	return bear

## A point on the bear's body (a surface of revolution) at angle `theta` and height `y`, pushed
## out `lift` along the surface normal.
static func _on_head(bear: Node3D, theta: float, y: float, lift: float) -> Vector3:
	var top: float = bear.get("body_top")
	y = minf(y, top - .002)
	var r: Vector2 = bear._section(y)
	var p := Vector3(r.x * cos(theta), y, r.y * sin(theta))
	var dy := .004
	var r2: Vector2 = bear._section(minf(y + dy, top - .0005))
	var r1: Vector2 = bear._section(y - dy)
	var along_y := Vector3((r2.x - r1.x) * cos(theta), 2.0 * dy, (r2.y - r1.y) * sin(theta))
	var around := Vector3(-r.x * sin(theta), 0, r.y * cos(theta))
	var n := around.cross(along_y).normalized()
	if n.dot(p - HEAD_CENTER) < 0.0:
		n = -n
	return p + n * lift

## How far round from the face `theta` is: 0 at the front, 1 at the back.
static func _round_share(theta: float) -> float:
	return absf(wrapf(theta - FRONT, -PI, PI)) / PI

## Height of the hairline around the head. Short: high over the forehead, down in front of the
## ears as sideburns, to the nape at the back. Long: the forehead and temples, then straight
## down behind the cheeks to the shoulders all round the back.
static func _hairline(theta: float, long: bool) -> float:
	var u := _round_share(theta)
	if long:
		if u < .3:
			return lerpf(1.9, 1.78, smoothstep(.08, .3, u))
		return lerpf(1.78, 1.13, smoothstep(.3, .42, u))
	var y := lerpf(1.9, 1.76, smoothstep(.1, .3, u))
	# Sideburns just in front of the ears, then up round the ears and down to the nape.
	y -= .12 * smoothstep(.26, .34, u) * (1.0 - smoothstep(.36, .44, u))
	return lerpf(y, 1.5, smoothstep(.5, .9, u))

## A sheet over the body between two lines: for each angle in [theta0, theta1] (all round when
## `closed`) from `top(theta)` down to `bottom(theta)`, lifted `lift(theta, t)` off the surface
## (t 0 at the top line, 1 at the bottom; `lift` also gets the height).
static func _sheet(bear: Node3D, theta0: float, theta1: float, closed: bool, top: Callable, bottom: Callable, lift: Callable, material: Material, sides := 64, rows := 36) -> ArrayMesh:
	var columns := sides if closed else sides + 1
	var verts := PackedVector3Array()
	var tris := PackedInt32Array()
	for j in range(rows + 1):
		var t := float(j) / float(rows)
		for i in range(columns):
			var theta := lerpf(theta0, theta1, float(i) / float(sides))
			var y0: float = top.call(theta)
			var y := lerpf(y0, float(bottom.call(theta)), .55 * t * t + .45 * t if closed else t)
			verts.append(_on_head(bear, theta, y, float(lift.call(theta, t, y))))
	for j in range(rows):
		for i in range(sides):
			var k := (i + 1) % columns
			var a := j * columns + i
			var b := j * columns + k
			var d := (j + 1) * columns + i
			var e := (j + 1) * columns + k
			tris.append_array(PackedInt32Array([a, b, d, b, e, d]))
	return bear._surface(verts, tris, material)

## The hair cap: a soft shell over the crown down to the hairline with shallow combed grooves.
## Short hair thins out to the hairline so it lies on the head. Long hair keeps its thickness
## and flares out below the ears, like hair falling over the shoulders.
static func _cap(bear: Node3D, long: bool, material: Material) -> ArrayMesh:
	var top: float = bear.get("body_top")
	var lift := func(theta: float, t: float, y: float) -> float:
		var groove := 1.0 + .2 * sqrt(t) * cos(theta * 18.0)
		if long:
			return (.075 + .09 * smoothstep(1.75, 1.2, y)) * groove
		return .06 * groove * (1.0 - .8 * smoothstep(.7, 1.0, t))
	return _sheet(bear, 0.0, TAU, true, func(_theta: float) -> float: return top - .001, func(theta: float) -> float: return _hairline(theta, long), lift, material, 96, 44)

## The fringe: soft scallops along the forehead hairline (short), or two big lobes swept to
## the sides from a centre parting (long).
static func _fringe(bear: Node3D, long: bool) -> Array:
	var puffs: Array = []
	if long:
		for side in [-1.0, 1.0]:
			for k in 3:
				var theta: float = FRONT + side * (.14 + k * .26)
				var y := _hairline(theta, true) + .015 - k * .025
				puffs.append([_on_head(bear, theta, y, .075), Vector3(.14 - k * .01, .08, .085)])
		return puffs
	for k in 7:
		var theta: float = FRONT + (k - 3) * .2
		var y := _hairline(theta, false) + .01
		puffs.append([_on_head(bear, theta, y, .04), Vector3(.1, .065, .06)])
	return puffs

## Long hair: a rounded roll along the edge of the hair, from the temples down behind the
## cheeks and round the back at shoulder height, so the edge reads as soft, thick hair.
static func _locks(bear: Node3D, material: Material) -> ArrayMesh:
	var rim: Array = []
	var radii: Array = []
	for i in range(97):
		var theta := TAU * float(i % 96) / 96.0
		var y := _hairline(theta, true)
		var thick := .075 + .09 * smoothstep(1.75, 1.2, y)
		rim.append(_on_head(bear, theta, y, thick * .5))
		radii.append(thick * .5 + .012)
	return bear._tube(rim, radii, material)

## The beard: a soft shell over the jaw from sideburn to sideburn under the muzzle and the
## blush, thickest at the chin, with a fluffy scalloped lower edge (no moustache, so barba and
## bigote stay apart). The sideburns run up to meet the hair, or stop at the ears when bald.
static func _beard(bear: Node3D, material: Material, bald: bool) -> ArrayMesh:
	var reach := 1.3
	var rise := .16 if bald else .34
	var rise_under := .1 if bald else .3
	var top := func(theta: float) -> float:
		var a := absf(theta - FRONT) / reach
		return lerpf(1.405, 1.46, smoothstep(0.0, .6, a)) + rise * smoothstep(.6, 1.0, a)
	var bottom := func(theta: float) -> float:
		var a := absf(theta - FRONT) / reach
		return lerpf(1.2, 1.32, smoothstep(0.0, .65, a)) + rise_under * smoothstep(.65, 1.0, a)
	var lift := func(theta: float, t: float, _y: float) -> float:
		var a := absf(theta - FRONT) / reach
		return .02 + .075 * smoothstep(0.0, .4, t) * (1.0 - .25 * a) * (1.0 - .6 * smoothstep(.88, 1.0, a))
	var sheet := _sheet(bear, FRONT - reach, FRONT + reach, false, top, bottom, lift, material, 48, 24)
	var puffs: Array = []
	for k in 9:
		var theta: float = FRONT + (k - 4) * .26
		var y: float = bottom.call(theta) + .04
		puffs.append([_on_head(bear, theta, y, .07 - absf(k - 4) * .006), Vector3(.115, .095, .08)])
	# A soft round end to each sideburn.
	for side in [-1.0, 1.0]:
		var theta: float = FRONT + side * reach * .95
		var mid: float = (float(top.call(theta)) + float(bottom.call(theta))) * .5
		puffs.append([_on_head(bear, theta, mid, .03), Vector3(.07, .11, .07)])
	return bear._merge([sheet, bear._blobs(puffs, material)], material)

## The moustache: two bushy lobes under the nose, tips flicked up a little.
static func _moustache(bear: Node3D, nose: MeshInstance3D, nose_scale: float, material: Material) -> ArrayMesh:
	var under := 1.56
	if nose != null and nose.mesh != null:
		var box: AABB = nose.mesh.get_aabb()
		var muzzle := nose.get_parent() as Node3D
		under = muzzle.position.y + nose.position.y - box.size.y * .5 * nose_scale
	var lobes: Array = []
	for side in [-1.0, 1.0]:
		var points: Array = []
		for at in [Vector2(.01, 0.0), Vector2(.07, -.008), Vector2(.13, -.014), Vector2(.18, -.008), Vector2(.205, .014)]:
			var x: float = side * at.x
			var y: float = under - .012 + at.y
			points.append(Vector3(x, y, bear._muzzle_z(x, y) - .03))
		lobes.append(bear._tube(points, [.042, .05, .044, .032, .018], material))
	return bear._merge(lobes, material)

## Women's eyelashes: three short flicks fanning out from the upper outer edge of each eye.
static func _lashes(bear: Node3D) -> ArrayMesh:
	var lash: Material = bear._soft_mat(Color("2b1b14"), 0.0)
	var pieces: Array = []
	for side in [-1.0, 1.0]:
		var eye := Vector2(side * .227, 1.667)
		for k in 3:
			var angle: float = deg_to_rad(20.0 + k * 28.0)
			var dir := Vector2(side * cos(angle), sin(angle))
			var from := eye + Vector2(dir.x * .036, dir.y * .043)
			var to := from + dir * .042
			var a := Vector3(from.x, from.y, bear._front_z(from.x, from.y) - .03)
			var b := Vector3(to.x, to.y, bear._front_z(to.x, to.y) - .035)
			pieces.append(bear._tube([a, b], [.011, .006], lash))
	return bear._merge(pieces, lash)

## Untested variety: rounder or smaller blush and slightly tilted ears.
static func _vary_face(bear: Node3D) -> void:
	var blush := randf_range(.85, 1.15)
	for path in ["Head/LeftCheek", "Head/RightCheek"]:
		var cheek := bear.get_node_or_null(path) as MeshInstance3D
		if cheek != null:
			cheek.scale = Vector3.ONE * blush
	var tilt := randf_range(-.13, .13)
	for path in ["Head/LeftEar", "Head/RightEar"]:
		var ear := bear.get_node_or_null(path) as MeshInstance3D
		if ear != null and ear.mesh != null:
			# Turn about the ear's base (its mesh is centred on the node); both ears lean out
			# (or in) together, mirrored.
			var box: AABB = ear.mesh.get_aabb()
			var pivot := Vector3(0, box.position.y, 0)
			var turn := Basis(Vector3.FORWARD, signf(ear.position.x) * tilt)
			ear.transform = ear.transform * Transform3D(turn, pivot - turn * pivot)

static func _add(bear: Node3D, title: String, mesh: ArrayMesh) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	bear.add_child(node)
	return node
