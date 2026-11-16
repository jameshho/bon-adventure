extends "res://scripts/characters/plush_sculpt.gd"

# Outfits for the Home plush characters, listed in data/plush_costumes.json.
# A "Costume" node under a plush root builds every piece from that wearer's own
# measured body (fur and wool included), so one outfit fits all nine sculpts
# without resizing them. Dress a plush after it is placed:
# `PlushCostume.dress(npc, "police")`. Pieces have no collision, so clicks still
# reach the plush's StudyArea and name card, and hover highlighting covers them.
# Works in the wearer's model space: +Y up, faces -Z, +X is the character's right.

const DATA := "res://data/plush_costumes.json"
const SCRIPT_PATH := "res://scripts/characters/plush_costume.gd"
# Height of the bands the body is measured in.
const BAND := 0.01
# Gap from the body to the first garment layer, and from one layer to the next.
const CLEARANCE := 0.025
const LAYER := 0.03
# Directions around the body that it is measured in.
const SECTORS := 48
const FRONT := -PI * 0.5
const BACK := PI * 0.5
# Spot name -> [share of the half-width (negative = character's left), offset from collar_y].
const SPOTS := {
	"left_chest": [-0.40, -0.26], "right_chest": [0.40, -0.26],
	"left_badge": [-0.40, -0.12], "right_badge": [0.40, -0.12],
	"left_hip": [-0.46, -0.74], "right_hip": [0.46, -0.74]
}

@export var outfit := ""
## Pieces given directly (dress_pieces()), used instead of a listed outfit's.
@export var pieces: Array = []
var _wearer: Node3D
var _fit: Dictionary
var _body: Dictionary
var _crown: Dictionary
var _parts := 0
# The hat once built: x crown radius, y seat height, z centre; _brim is a straw
# hat's brim radius (0 for peaked caps).
var _hat := Vector3.ZERO
var _brim := 0.0

static func dress(npc: Node3D, outfit_id: String) -> Node3D:
	var costume: Node3D = load(SCRIPT_PATH).new()
	costume.name = "Costume"
	costume.outfit = outfit_id
	npc.add_child(costume)
	return costume

## Dresses `npc` in pieces not listed as an outfit (same piece format as the data's
## outfits), e.g. a lineup suspect's shirt in the colour the game chose.
static func dress_pieces(npc: Node3D, outfit_pieces: Array) -> Node3D:
	var costume: Node3D = load(SCRIPT_PATH).new()
	costume.name = "Costume"
	costume.pieces = outfit_pieces
	npc.add_child(costume)
	return costume

## Every outfit the player can wear, in data order, after "" (BonBon's own look). The fitting
## room picker lists these, so an outfit added to the data shows up there by itself.
static func outfit_ids() -> Array:
	var ids: Array = [""]
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if data is Dictionary:
		ids.append_array(data["outfits"].keys())
	return ids

## Dresses the player character (player_controller.gd: Visual/BonBon, animated Arm / Arm_2 and
## their rest_poses) in `outfit_id`; "" takes the costume off. Used by every fitting booth and
## when a saved outfit is put back on at startup (fitting room picker, 9 Nov 2026). BonBon's
## species has no hide/tuck/press entries, so taking a costume off restores her completely.
static func dress_player(player: Node3D, outfit_id: String) -> void:
	var bonbon: Node3D = player.get_node_or_null("Visual/BonBon")
	if bonbon == null:
		return
	# Drop the previous costume, including sleeves moved onto the arms.
	var old: Node = bonbon.get_node_or_null("Costume")
	if old:
		bonbon.remove_child(old)
		old.queue_free()
	for arm_name in ["Arm", "Arm_2"]:
		var arm: Node = bonbon.get_node_or_null(arm_name)
		if arm == null:
			continue
		for child in arm.get_children():
			if child.has_meta("bonbon_costume_sleeve"):
				arm.remove_child(child)
				child.queue_free()
	if outfit_id == "":
		return
	var rest_poses: Dictionary = player.get("rest_poses")
	# Garments are measured from the arms' current pose: build at the rest pose (sitting
	# bends the arms), then let the player re-pose them.
	var posed := {}
	for arm_name in ["Arm", "Arm_2"]:
		var arm: Node3D = bonbon.get_node_or_null(arm_name)
		if arm and rest_poses.has(arm_name):
			posed[arm_name] = arm.transform
			arm.transform = rest_poses[arm_name]
	var costume: Node3D = dress(bonbon, outfit_id)
	for arm_name in posed:
		bonbon.get_node(arm_name).transform = posed[arm_name]
	# Sleeves ride on BonBon's arms (the player animates Arm / Arm_2); every piece is built in
	# BonBon's model space and the arms' rest poses map it onto them.
	# A piece keeps its own node transform (cached garments are re-centred meshes placed by
	# it; dropping it put both sleeves under her body, 9 Nov 2026), so side and placement use
	# the piece's transform in BonBon's space, not the bare mesh.
	for piece in costume.get_children():
		if not (piece is MeshInstance3D and str(piece.name).begins_with("Sleeve")):
			continue
		var in_bonbon: Transform3D = costume.transform * (piece as MeshInstance3D).transform
		var arm_name := "Arm" if (in_bonbon * (piece as MeshInstance3D).get_aabb()).get_center().x < 0 else "Arm_2"
		var arm: Node3D = bonbon.get_node_or_null(arm_name)
		var rest: Variant = rest_poses.get(arm_name)
		if arm == null or rest == null:
			continue
		costume.remove_child(piece)
		arm.add_child(piece)
		piece.transform = (rest as Transform3D).affine_inverse() * in_bonbon
		piece.set_meta("bonbon_costume_sleeve", true)

## A costume saved in a town scene (modular town, 6 Nov 2026) is ready before its wearer, whose
## sculpt builds the body meshes the garments are measured from: wait for the wearer.
func _ready() -> void:
	var wearer := get_parent()
	if wearer != null and not wearer.is_node_ready():
		await wearer.ready
	# Garments come from the sculpt cache when this wearer was dressed so before.
	SculptCache.dress(self)

func _build() -> void:
	_wearer = get_parent() as Node3D
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	_fit = data["species"].get(_wearer.scene_file_path.get_file().get_basename(), {})
	# Every Torso part counts (the croc's back ridge, belly grooves), so nothing pokes through.
	_body = _measure(["Torso"])
	# Hats rest on whatever crowns the head: the lion's mane or the sheep's wool cap.
	_crown = _measure(["Torso", "Mane"])
	var hide: Dictionary = _fit.get("hide", {})
	var tuck: Dictionary = _fit.get("tuck", {})
	var press: Dictionary = _fit.get("press", {})
	for piece in (pieces if not pieces.is_empty() else data["outfits"][outfit]["pieces"]):
		var kind := str(piece["piece"])
		call("_" + kind, piece)
		for path in hide.get(kind, []):
			var part := _wearer.get_node_or_null(NodePath(str(path))) as Node3D
			if part != null:
				part.visible = false
		for path in tuck.get(kind, []):
			_tuck(str(path))
		for path in press.get(kind, []):
			_press(str(path))

# Tucks a part (the lion's mane) into the collar: everything below collar_y is pulled
# inside the body's own surface, so the shirt covers it, easing back to full size
# just above.
func _tuck(path: String) -> void:
	var collar := _collar()
	_reshape(path, func(p: Vector3) -> Vector3:
		var ease := smoothstep(collar - 0.02, collar + 0.1, p.y)
		var flat := Vector2(p.x, p.z)
		var reach := flat.length()
		var inside := _radius(_body, atan2(p.z, p.x), clampf(p.y, 0.05, collar)) - 0.01
		if ease >= 1.0 or reach <= inside:
			return p
		flat *= lerpf(inside, reach, ease) / reach
		return Vector3(flat.x, minf(p.y, lerpf(collar - 0.02, p.y, ease)), flat.y))

# Presses hair (the lion's mane, the sheep's wool) flat under the cap: nothing rises
# above the band's lower edge under the cap, and beside it the hair slopes down to
# that edge, so no puff pokes out between the band and the crown.
func _press(path: String) -> void:
	var free := maxf(_hat.x * 1.05, _brim)
	var center := Vector2(0.0, _hat.z)
	_reshape(path, func(p: Vector3) -> Vector3:
		var reach := Vector2(p.x, p.z).distance_to(center)
		var beyond := maxf(0.0, reach - free)
		var limit := _hat.y - 0.1 + beyond * 0.35
		if _brim > 0.0:
			# Under a straw hat the hair follows the brim's drooping underside, so the
			# hat rests on it instead of floating.
			limit = _brim_under(minf(reach, _brim)) - 0.012 + beyond * 0.35
		if p.y <= limit - 0.06:
			return p
		# Soft knee: hair just below the limit compresses smoothly instead of a hard cut.
		var over := p.y - (limit - 0.06)
		return Vector3(p.x, limit - 0.06 + 0.06 * (1.0 - exp(-over / 0.06)), p.z))

# Height of a straw hat brim's underside at distance d from the hat's axis.
func _brim_under(d: float) -> float:
	return _hat.y - 0.012 - 0.048 * clampf((d - _hat.x) / (_brim * 0.97 - _hat.x), 0.0, 1.0)

# Replaces one part's mesh on this wearer with a copy whose vertices (in wearer
# space) go through `move`. The sculpt and other plushes are untouched.
func _reshape(path: String, move: Callable) -> void:
	var node := _wearer.get_node_or_null(NodePath(path)) as MeshInstance3D
	if node == null or node.mesh == null:
		return
	var to_root := _to_wearer(node)
	var to_node := to_root.affine_inverse()
	var source := node.mesh as ArrayMesh
	var mesh := ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays := source.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in range(verts.size()):
			verts[i] = to_node * move.call(to_root * verts[i])
		arrays[Mesh.ARRAY_VERTEX] = verts
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(surface, source.surface_get_material(surface))
	node.mesh = mesh

func _add(part: String, mesh: ArrayMesh) -> void:
	_parts += 1
	var node := MeshInstance3D.new()
	node.name = "%s%d" % [part, _parts]
	add_child(node)
	_put(node.name, mesh)

# ---- Measuring the wearer ----

func _to_wearer(node: Node3D) -> Transform3D:
	var to_root := node.transform
	var parent := node.get_parent()
	while parent != _wearer and parent is Node3D:
		to_root = (parent as Node3D).transform * to_root
		parent = parent.get_parent()
	return to_root

func _vertices(node: MeshInstance3D) -> PackedVector3Array:
	var to_root := _to_wearer(node)
	var points := PackedVector3Array()
	for vertex in node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		points.append(to_root * vertex)
	return points

# Per height band and direction around the body: the farthest any vertex of the
# given parts (and their children) reaches from the centre line.
func _measure(paths: Array) -> Dictionary:
	var raw := {}
	var top := 0.0
	for path in paths:
		var part := _wearer.get_node_or_null(NodePath(str(path)))
		if part == null:
			continue
		var meshes: Array = part.find_children("*", "MeshInstance3D", true, false)
		if part is MeshInstance3D:
			meshes.append(part)
		for node in meshes:
			if node.mesh == null or not node.visible:
				continue
			for p in _vertices(node):
				var k := roundi(p.y / BAND)
				if not raw.has(k):
					raw[k] = PackedFloat32Array()
					raw[k].resize(SECTORS)
				var sector := posmod(roundi(atan2(p.z, p.x) / TAU * SECTORS), SECTORS)
				raw[k][sector] = maxf(raw[k][sector], Vector2(p.x, p.z).length())
				top = maxf(top, p.y)
	return {"raw": raw, "smooth": {}, "top": top}

# Smoothed band k: per direction, the farthest point within 0.03 in height and one
# sector either side, averaged over 0.02 in height, so fur scallops and wool clumps
# never poke through and do not ripple the cloth either.
func _band(table: Dictionary, k: int) -> PackedFloat32Array:
	var smooth: Dictionary = table["smooth"]
	if not smooth.has(k):
		var raw: Dictionary = table["raw"]
		var widest := {}
		for i in range(k - 5, k + 6):
			var row := PackedFloat32Array()
			row.resize(SECTORS)
			var source: PackedFloat32Array = raw.get(i, row)
			for s in range(SECTORS):
				row[s] = maxf(source[s], maxf(source[posmod(s - 1, SECTORS)], source[(s + 1) % SECTORS]))
			widest[i] = row
		var result := PackedFloat32Array()
		result.resize(SECTORS)
		for s in range(SECTORS):
			var sum := 0.0
			for j in range(-2, 3):
				var most := 0.0
				for i in range(-3, 4):
					most = maxf(most, widest[k + j + i][s])
				sum += most
			result[s] = sum / 5.0
		smooth[k] = result
	return smooth[k]

# Distance from the centre line to the measured surface toward angle theta at height y.
func _radius(table: Dictionary, theta: float, y: float) -> float:
	var k := floori(y / BAND)
	var at := fposmod(theta, TAU) / TAU * SECTORS
	var s := floori(at)
	var lower := _band(table, k)
	var upper := _band(table, k + 1)
	var f := at - float(s)
	var a := lerpf(lower[s % SECTORS], lower[(s + 1) % SECTORS], f)
	var b := lerpf(upper[s % SECTORS], upper[(s + 1) % SECTORS], f)
	return lerpf(a, b, y / BAND - float(k))

# Half-width of a measured body at height y (its widest reach to either side).
func _half_width(table: Dictionary, y: float) -> float:
	return maxf(_radius(table, 0.0, y), _radius(table, PI, y))

# A point `gap` outside the body toward angle theta (FRONT faces the viewer) at height y.
func _shell(theta: float, y: float, gap: float) -> Vector3:
	var r := _radius(_body, theta, y) + gap
	return Vector3(cos(theta) * r, y, sin(theta) * r)

# Surface frame at a shell point: X along the surface to the right, Y up it, -Z outward.
func _frame(theta: float, y: float, gap: float) -> Transform3D:
	var across := (_shell(theta + 0.01, y, gap) - _shell(theta - 0.01, y, gap)).normalized()
	var up := (_shell(theta, y + 0.01, gap) - _shell(theta, y - 0.01, gap)).normalized()
	var outward := up.cross(across).normalized()
	return Transform3D(Basis(across, (-outward).cross(across), -outward), _shell(theta, y, gap))

func _gap(layer: int) -> float:
	return CLEARANCE + LAYER * float(layer)

func _collar() -> float:
	return float(_fit.get("collar_y", 1.25))

func _anchor(key: String, side: float) -> Vector3:
	var value: Array = _fit.get(key, [0.6, 1.1, 0.0])
	return Vector3(side * float(value[0]), float(value[1]), float(value[2]))

# Angle and height of a named spot or an [x share, collar offset] pair, on the front.
func _spot(at: Variant) -> Vector2:
	var value: Array = at if at is Array else SPOTS[str(at)]
	return Vector2(FRONT + asin(clampf(float(value[0]), -0.95, 0.95)), _collar() + float(value[1]))

func _spot_frame(piece: Dictionary) -> Transform3D:
	var spot := _spot(piece.get("at", "left_chest"))
	return _frame(spot.x, spot.y, _gap(int(piece.get("layer", 0))) + 0.004)

# ---- Shared shapes ----

func _same(value: float, count: int) -> Array:
	var result: Array = []
	result.resize(count)
	result.fill(value)
	return result

# Height of a neckline at theta: `dip` lower at the front, as a V or a soft scoop.
func _neckline(collar: float, dip: float, width: float, v: bool) -> Callable:
	return func(theta: float) -> float:
		var off := absf(wrapf(theta - FRONT, -PI, PI)) / width
		var drop := maxf(0.0, 1.0 - off) if v else 1.0 - smoothstep(0.0, 1.0, off)
		return collar - dip * drop

# A body wrap from y0 up to top(theta), `gap` off the body, with rolled hems.
# The seam sits at the back, where the plush leans on its seat.
func _wrap(y0: float, top: Callable, gap: float, material: Material, hem: float) -> ArrayMesh:
	var cols := 120
	var rows := 48
	var verts := PackedVector3Array()
	var tris := PackedInt32Array()
	var lower: Array = []
	var upper: Array = []
	for i in range(cols + 1):
		var theta := BACK + TAU * float(i) / float(cols)
		var y1: float = top.call(theta)
		if i < cols:
			for j in range(rows + 1):
				verts.append(_shell(theta, lerpf(y0, y1, float(j) / float(rows)), gap))
		lower.append(_shell(theta, y0, gap + hem * 0.5))
		upper.append(_shell(theta, y1, gap + hem * 0.5))
	for i in range(cols):
		var a := i * (rows + 1)
		var b := ((i + 1) % cols) * (rows + 1)
		for j in range(rows):
			tris.append_array(PackedInt32Array([a + j, b + j, a + j + 1, a + j + 1, b + j, b + j + 1]))
	return _merge([_surface(verts, tris, material), _tube(lower, _same(hem, lower.size()), material), _tube(upper, _same(hem, upper.size()), material)], material)

# A front panel from y0 to y1 whose half-width at height y is half_width(y).
func _panel(y0: float, y1: float, half_width: Callable, gap: float, material: Material) -> ArrayMesh:
	var cols := 40
	var rows := 48
	var verts := PackedVector3Array()
	var tris := PackedInt32Array()
	var edges := [[], [], [], []]
	for j in range(rows + 1):
		var y := lerpf(y0, y1, float(j) / float(rows))
		var spread := asin(clampf(float(half_width.call(y)) / (_half_width(_body, y) + gap), 0.0, 0.98))
		for i in range(cols + 1):
			verts.append(_shell(FRONT + spread * lerpf(-1.0, 1.0, float(i) / float(cols)), y, gap))
		edges[1].append(_shell(FRONT + spread, y, gap + 0.006))
		edges[3].append(_shell(FRONT - spread, y, gap + 0.006))
	for j in range(rows):
		for i in range(cols):
			var a := j * (cols + 1) + i
			var c := a + cols + 1
			tris.append_array(PackedInt32Array([a, c, a + 1, a + 1, c, c + 1]))
	for i in range(cols + 1):
		edges[0].append(verts[i] + (verts[i] - Vector3(0, verts[i].y, 0)).normalized() * 0.006)
		var t := verts[rows * (cols + 1) + i]
		edges[2].append(t + (t - Vector3(0, t.y, 0)).normalized() * 0.006)
	var parts: Array = [_surface(verts, tris, material)]
	for edge in edges:
		parts.append(_tube(edge, _same(0.012, edge.size()), material))
	return _merge(parts, material)

# Open sleeve over the inner `share` of an arm, fitted to that arm's own mesh.
func _sleeve(side: float, share: float, gap: float, material: Material, stripes: int = 0, stripe: Material = null, stripe_size: float = 0.012) -> ArrayMesh:
	var shoulder := _anchor("shoulder", side)
	var axis := _anchor("hand", side) - shoulder
	var length := axis.length()
	axis /= length
	var across := axis.cross(Vector3.BACK).normalized()
	var depth := axis.cross(across)
	var arm := _wearer.get_node("Arm/Visual" if side < 0.0 else "Arm_2/Visual") as MeshInstance3D
	var points := _vertices(arm)
	var rings := 8
	var sizes: Array[Vector2] = []
	var last := Vector2(0.12, 0.12)
	for j in range(rings + 1):
		var t := lerpf(-0.15, share, float(j) / float(rings)) * length
		var size := Vector2.ZERO
		for p in points:
			var d := p - shoulder
			if absf(d.dot(axis) - t) < 0.04:
				size = Vector2(maxf(size.x, absf(d.dot(across))), maxf(size.y, absf(d.dot(depth))))
		last = size if size != Vector2.ZERO else last
		sizes.append(last + Vector2(gap, gap) * 0.8)
	var sides := 24
	var verts := PackedVector3Array()
	var tris := PackedInt32Array()
	var cuff: Array = []
	for j in range(rings + 1):
		# Neighbour averaging keeps the cloth from following every bump of the paw.
		var size := (sizes[maxi(j - 1, 0)] + sizes[j] * 2.0 + sizes[mini(j + 1, rings)]) * 0.25
		var center := shoulder + axis * lerpf(-0.15, share, float(j) / float(rings)) * length
		for i in range(sides):
			var theta := TAU * float(i) / float(sides)
			verts.append(center + across * cos(theta) * size.x + depth * sin(theta) * size.y)
		if j == rings:
			for i in range(sides + 1):
				var theta := TAU * float(i) / float(sides)
				cuff.append(center + across * cos(theta) * (size.x + 0.008) + depth * sin(theta) * (size.y + 0.008))
			# Braid rings just above the cuff (the pilot's gold stripes).
			for k in range(stripes):
				var ring: Array = []
				var around := center - axis * (0.05 + 0.04 * float(k))
				for i in range(sides + 1):
					var theta := TAU * float(i) / float(sides)
					ring.append(around + across * cos(theta) * (size.x + 0.006) + depth * sin(theta) * (size.y + 0.006))
				_add("CuffStripe", _tube(ring, _same(stripe_size, ring.size()), stripe))
	for j in range(rings):
		for i in range(sides):
			var k := (i + 1) % sides
			tris.append_array(PackedInt32Array([j * sides + i, (j + 1) * sides + i, j * sides + k, j * sides + k, (j + 1) * sides + i, (j + 1) * sides + k]))
	return _merge([_surface(verts, tris, material), _tube(cuff, _same(0.016, cuff.size()), material)], material)

# A thin padded patch (pocket, badge, tag) lying on the surface frame.
func _patch(contour: PackedVector2Array, frame: Transform3D, thickness: float, material: Material, lift: float = 0.0) -> ArrayMesh:
	var squash := thickness / 0.085
	var flat := Transform3D(Basis.from_scale(Vector3(1, 1, squash)), Vector3(0, 0, 0.004 - 0.025 * squash - lift))
	return _moved(_pillow(contour, -0.02, 0.025, material), frame * flat)

func _shifted(contour: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in contour:
		result.append(point + offset)
	return result

# Round stack of horizontal [height, radius] rings around `center`, closed at both ends.
func _lathe(center: Vector3, rings: Array, material: Material) -> ArrayMesh:
	var centers: Array[Vector3] = []
	var radii: Array[Vector2] = []
	for ring in rings:
		centers.append(center + Vector3(0, float(ring[0]), 0))
		radii.append(Vector2(float(ring[1]), float(ring[1])))
	return _limb_rings(centers, radii, material, 1)

# ---- Pieces (one function per "piece" name in the data) ----

func _shirt(piece: Dictionary) -> void:
	var gap := _gap(int(piece.get("layer", 0)))
	var color := Color(str(piece.get("color", "ffffff")))
	var cloth := _mat(color)
	var trim := _mat(color.darkened(0.08))
	var v := bool(piece.get("v", false))
	var top := _neckline(_collar(), float(piece.get("dip", 0.06)), float(piece.get("dip_width", 0.5)), v)
	var bottom := float(piece.get("bottom", 0.45))
	_add("Shirt", _wrap(bottom, top, gap, cloth, float(piece.get("hem", 0.014))))
	var sleeve := float(piece.get("sleeve", 0.0))
	if sleeve > 0.0:
		var stripe: Material = _soft_mat(Color(str(piece.get("cuff_stripes", "e2bd4f"))), 0.6)
		for side in [-1.0, 1.0]:
			_add("Sleeve", _sleeve(side, sleeve, gap, cloth, int(piece.get("stripe_count", 2)) if piece.has("cuff_stripes") else 0, stripe, float(piece.get("stripe_size", 0.012))))
	var neck: float = top.call(FRONT)
	if piece.has("lapels"):
		# Lapels fold back along both edges of a V front: widest at the shoulder,
		# narrowing to the V's point, a shade darker than the cloth.
		var lapel := _mat(color.darkened(float(piece.get("lapels", 0.12))))
		var width := float(piece.get("dip_width", 0.5))
		for side in [-1.0, 1.0]:
			var verts := PackedVector3Array()
			var tris := PackedInt32Array()
			var edge: Array = []
			var steps := 16
			for i in range(steps + 1):
				var t := float(i) / float(steps)
				var theta: float = FRONT + side * width * (1.0 - t) * 0.96
				var y: float = top.call(theta)
				var w := 0.11 * pow(1.0 - t, 0.8) + 0.012
				verts.append(_shell(theta, y + 0.004, gap + 0.008))
				verts.append(_shell(theta + side * w * 0.9, y - w * 0.75, gap + 0.008))
				edge.append(_shell(theta, y + 0.004, gap + 0.012))
				if i < steps:
					var a := i * 2
					tris.append_array(PackedInt32Array([a, a + 1, a + 2, a + 2, a + 1, a + 3]))
			_add("Lapel", _merge([_surface(verts, tris, lapel), _tube(edge, _same(0.01, edge.size()), lapel)], lapel))
	if bool(piece.get("collar", false)):
		# Two pointed collar flaps that fall from the neckline beside its centre, or two round
		# ("collar_round") flaps; "collar_color" gives them their own colour.
		var flap_mat: Material = _mat(Color(str(piece["collar_color"]))) if piece.has("collar_color") else cloth
		var round_flap := bool(piece.get("collar_round", false))
		for side in [-1.0, 1.0]:
			var theta: float = FRONT + side * (0.15 if round_flap else 0.17)
			var flap := _circle(Vector2(0.0, -0.035), 0.075) if round_flap else _ear_triangle(Vector2.ZERO, 0.15, 0.13, PI - side * 0.55)
			_add("Collar", _patch(flap, _frame(theta, float(top.call(theta)) - 0.005, gap + 0.006), 0.022, flap_mat))
	if bool(piece.get("stand_collar", false)):
		# A rolled stand collar following the neckline (the chef's coat).
		var ring: Array = []
		for i in range(97):
			var theta := BACK + TAU * float(i) / 96.0
			ring.append(_shell(theta, float(top.call(theta)) + 0.012, gap + 0.012))
		_add("Collar", _tube(ring, _same(0.028, ring.size()), cloth))
	if bool(piece.get("placket", false)):
		var line: Array = []
		for j in range(13):
			line.append(_shell(FRONT, lerpf(bottom + 0.01, neck, float(j) / 12.0), gap + 0.004))
		_add("Placket", _tube(line, _same(0.007, line.size()), trim))
	if piece.has("buttons"):
		# One column down the front, or two for a double-breasted jacket.
		var buttons := _soft_mat(Color(str(piece["buttons"])), 0.6)
		var size := float(piece.get("button_size", 0.022))
		for share in piece.get("button_columns", [0.0]):
			var theta := FRONT + asin(clampf(float(share), -0.95, 0.95))
			var y := neck - 0.07
			var count := int(piece.get("button_count", 99))
			while y > bottom + 0.08 and count > 0:
				_add("Button", _patch(_circle(Vector2.ZERO, size), _frame(theta, y, gap + 0.004), 0.016, buttons))
				y -= float(piece.get("button_step", 0.13))
				count -= 1
	for at in piece.get("pockets", []):
		# A pocket is a spot, or {"at": spot, "size": [half-width, half-height]}.
		var where: Variant = at["at"] if at is Dictionary else at
		var size: Array = at.get("size", [0.09, 0.08]) if at is Dictionary else [0.09, 0.08]
		var spot := _spot(where)
		var frame := _frame(spot.x, spot.y, gap + 0.004)
		_add("Pocket", _patch(_rounded_rect(0.0, 0.0, float(size[0]), float(size[1])), frame, 0.02, trim))
		if bool(piece.get("flaps", false)):
			_add("Flap", _patch(_rounded_rect(0.0, 0.07, 0.095, 0.03), frame, 0.03, cloth, 0.008))

func _apron(piece: Dictionary) -> void:
	var gap := _gap(int(piece.get("layer", 1)))
	var cloth := _mat(Color(str(piece.get("color", "2f7d57"))))
	var collar := _collar()
	var top := collar - 0.15
	var waist := collar - 0.44
	var bottom := float(piece.get("bottom", 0.32))
	var bib := float(piece.get("bib", 0.23))
	# Wraps most of the way round below the waist and narrows to a bib above it.
	var half_width := func(y: float) -> float:
		var skirt := (_half_width(_body, y) + gap) * 0.86
		return lerpf(skirt, bib, smoothstep(waist - 0.14, waist + 0.16, y))
	_add("Apron", _panel(bottom, top, half_width, gap, cloth))
	var ties: Array = []
	for i in range(97):
		ties.append(_shell(BACK + TAU * float(i) / 96.0, waist - 0.08, gap + 0.006))
	_add("Ties", _tube(ties, _same(0.014, ties.size()), cloth))
	# Neck straps rise straight from the bib corners and tuck under the chin, as if
	# they ran round the back of the neck (a ring round these wide bodies reads as a lid).
	for side in [-1.0, 1.0]:
		var corner: float = FRONT + side * asin(clampf(bib / (_half_width(_body, top) + gap), 0.0, 0.98))
		var strap: Array = []
		for j in range(5):
			strap.append(_shell(corner, lerpf(top - 0.01, collar + 0.01, float(j) / 4.0), gap + 0.006))
		strap.append(_shell(corner + side * 0.06, collar + 0.035, -0.03))
		_add("Strap", _tube(strap, _same(0.02, strap.size()), cloth))
	if bool(piece.get("pocket", false)):
		var spot := _spot([0.0, -0.74])
		_add("Pocket", _patch(_rounded_rect(0.0, 0.0, 0.2, 0.09), _frame(spot.x, spot.y, gap + 0.006), 0.022, _mat(Color(str(piece.get("color", "2f7d57"))).darkened(0.1))))

func _belt(piece: Dictionary) -> void:
	var gap := _gap(int(piece.get("layer", 0)))
	var y := float(piece.get("y", 0.5))
	var loop: Array = []
	for i in range(97):
		loop.append(_shell(BACK + TAU * float(i) / 96.0, y, gap + 0.012))
	_add("Belt", _tube(loop, _same(0.03, loop.size()), _mat(Color(str(piece.get("color", "1b1c22"))))))
	_add("Buckle", _patch(_rounded_rect(0.0, 0.0, 0.06, 0.045), _frame(FRONT, y, gap + 0.04), 0.02, _soft_mat(Color(str(piece.get("buckle", "c9ced6"))), 0.6)))

func _badge(piece: Dictionary) -> void:
	# Five-point star in a round shield: reads as a police badge at any size.
	var star := PackedVector2Array()
	for i in range(10):
		var theta := PI * 0.5 + PI * float(i) / 5.0
		star.append(Vector2(cos(theta), sin(theta)) * (0.075 if i % 2 == 0 else 0.034))
	var gold := _soft_mat(Color(str(piece.get("color", "e2bd4f"))), 0.6)
	var frame := _spot_frame(piece)
	_add("Badge", _patch(_smooth_outline(star, 2), frame, 0.03, gold, 0.004))
	_add("BadgeBack", _patch(_circle(Vector2.ZERO, 0.062), frame, 0.014, _soft_mat(Color(str(piece.get("color", "e2bd4f"))).darkened(0.18), 0.6)))

func _name_tag(piece: Dictionary) -> void:
	var frame := _spot_frame(piece)
	_add("NameTag", _patch(_rounded_rect(0.0, 0.0, 0.085, 0.04), frame, 0.016, _mat(Color("fdfcf8"))))
	_add("NameStripe", _patch(_rounded_rect(0.0, 0.026, 0.085, 0.014), frame, 0.02, _mat(Color(str(piece.get("stripe", "d9534a")))), 0.002))
	var line := _mat(Color("9a9aa2"))
	_add("NameLine", _moved(_tube([Vector3(-0.05, -0.012, -0.022), Vector3(0.05, -0.012, -0.022)], [0.006, 0.006], line), frame))

func _pen(piece: Dictionary) -> void:
	# Sticks up out of a pocket: the pocket front covers its lower half.
	var frame := _spot_frame(piece)
	var body := _tube([Vector3(0, -0.04, 0.0), Vector3(0, 0.07, -0.004), Vector3(0, 0.15, -0.006)], [0.017, 0.017, 0.016], _mat(Color(str(piece.get("color", "2d5aa0")))))
	var clip := _tube([Vector3(0, 0.13, -0.02), Vector3(0, 0.08, -0.022)], [0.004, 0.004], _soft_mat(Color("c9ced6"), 0.6))
	_add("Pen", _moved(_merge([body, clip], body.surface_get_material(0)), frame))

func _notepad(piece: Dictionary) -> void:
	var frame := _spot_frame(piece)
	_add("Notepad", _patch(_rounded_rect(-0.02, 0.08, 0.05, 0.06), frame, 0.014, _mat(Color("fbfaf4")), -0.012))
	_add("NotepadRing", _moved(_tube([Vector3(-0.065, 0.135, -0.008), Vector3(0.025, 0.135, -0.008)], [0.007, 0.007], _mat(Color("8b8f99"))), frame))
	var pencil := _tube([Vector3(0.05, -0.03, -0.004), Vector3(0.05, 0.08, -0.006), Vector3(0.05, 0.15, -0.006)], [0.011, 0.011, 0.011], _mat(Color("f2c33d")))
	_add("Pencil", _moved(pencil, frame))
	_add("PencilTip", _moved(_tube([Vector3(0.05, 0.15, -0.006), Vector3(0.05, 0.19, -0.006)], [0.009, 0.002], _mat(Color("e8c9a0"))), frame))

func _stethoscope(piece: Dictionary) -> void:
	# Thick tubing drapes round the back of the neck on the shoulders. The character's
	# right end hangs to a large round chest piece; the left end ends in the steel
	# ear tubes, so both read from the front against the coat.
	var gap := _gap(int(piece.get("layer", 1))) + 0.03
	var collar := _collar()
	var steel := _soft_mat(Color("c3c9d2"), 0.6)
	var rubber := _mat(Color(str(piece.get("color", "2f3b52"))))
	var thick := float(piece.get("thickness", 0.03))
	# Round the sides and back the loop sinks inside the body (the plushes have no
	# neck), so from the front it rises from under the chin instead of reading as
	# a bar across the shoulders.
	var loop: Array = []
	for i in range(25):
		var t := float(i) / 24.0
		var theta := FRONT - 0.5 - (TAU - 1.0) * t
		var off := absf(wrapf(theta - FRONT, -PI, PI))
		loop.append(_shell(theta, collar - 0.03 + 0.05 * sin(PI * t), gap - 0.16 * smoothstep(0.5, 0.95, off)))
	var right: Array = [_shell(FRONT + 0.5, collar - 0.03, gap), _shell(FRONT + 0.42, collar - 0.14, gap), _shell(FRONT + 0.34, collar - 0.28, gap), _shell(FRONT + 0.3, collar - 0.37, gap)]
	var left: Array = [_shell(FRONT - 0.5, collar - 0.03, gap), _shell(FRONT - 0.42, collar - 0.12, gap), _shell(FRONT - 0.36, collar - 0.19, gap)]
	_add("Tubing", _merge([_tube(loop, _same(thick, loop.size()), rubber), _tube(right, _same(thick, right.size()), rubber), _tube(left, _same(thick, left.size()), rubber)], rubber))
	# Large round chest piece: a steel disc with a darker diaphragm and a short stem.
	var size := float(piece.get("chest_piece", 0.11))
	var disc := _frame(FRONT + 0.3, collar - 0.37 - size, gap + 0.01)
	_add("ChestPiece", _moved(_blobs([[Vector3(0, 0, -0.01), Vector3(size, size, 0.04)], [Vector3(0, size, -0.012), Vector3(0.03, 0.036, 0.026)]], steel), disc))
	_add("Diaphragm", _moved(_blobs([[Vector3(0, 0, -0.048), Vector3(size * 0.72, size * 0.72, 0.008)]], _soft_mat(Color("8f99a6"), 0.6)), disc))
	# Ear tubes: a short steel Y at the left end, with black tips.
	var yoke := _frame(FRONT - 0.36, collar - 0.21, gap)
	var tips := _mat(Color("2b2b30"))
	for side in [-1.0, 1.0]:
		_add("EarTube", _moved(_tube([Vector3(0, 0, -0.005), Vector3(side * 0.04, -0.06, -0.012), Vector3(side * 0.06, -0.13, -0.016)], [0.016, 0.016, 0.015], steel), yoke))
		_add("EarTip", _moved(_blobs([[Vector3(side * 0.062, -0.15, -0.018), Vector3(0.028, 0.028, 0.028)]], tips), yoke))

func _tie(piece: Dictionary) -> void:
	# Knot just under the shirt collar, then a blade that follows the chest and
	# ends in a point.
	var gap := _gap(int(piece.get("layer", 0))) + 0.012
	var cloth := _mat(Color(str(piece.get("color", "2c3e66"))))
	var top := _collar() - float(piece.get("top", 0.075))
	var bottom := top - float(piece.get("length", 0.42))
	var width := float(piece.get("width", 0.06))
	var blade := top - 0.035
	_add("Tie", _panel(bottom, blade, func(y: float) -> float:
		var t := (y - bottom) / (blade - bottom)
		return width * minf(1.0, t / 0.13) * lerpf(1.0, 0.55, t), gap, cloth))
	_add("TieKnot", _moved(_blobs([[Vector3(0, 0, -0.01), Vector3(0.04, 0.036, 0.026)]], cloth), _frame(FRONT, top - 0.012, gap + 0.004)))

func _overalls(piece: Dictionary) -> void:
	# Trousers wrap all the way round up to the waistband; a bib rises at the front
	# with straps, two big buttons and a pocket.
	var gap := _gap(int(piece.get("layer", 1)))
	var color := Color(str(piece.get("color", "6a9a3c")))
	var cloth := _mat(color)
	var collar := _collar()
	var top := collar - 0.13
	var waist := collar - 0.44
	var bib := float(piece.get("bib", 0.26))
	var bottom := float(piece.get("bottom", 0.3))
	_add("Overalls", _wrap(bottom, func(_theta: float) -> float: return waist, gap, cloth, 0.022))
	_add("Bib", _panel(waist - 0.04, top, func(_y: float) -> float: return bib, gap + 0.004, cloth))
	var button := _soft_mat(Color(str(piece.get("buttons", "f2c33d"))), 0.6)
	for side in [-1.0, 1.0]:
		var corner: float = FRONT + side * asin(clampf((bib - 0.04) / (_half_width(_body, top) + gap), 0.0, 0.98))
		var strap: Array = []
		for j in range(5):
			strap.append(_shell(corner, lerpf(top - 0.04, collar + 0.01, float(j) / 4.0), gap + 0.01))
		strap.append(_shell(corner + side * 0.06, collar + 0.035, -0.03))
		_add("Strap", _tube(strap, _same(0.026, strap.size()), cloth))
		_add("Button", _patch(_circle(Vector2.ZERO, 0.034), _frame(corner, top - 0.04, gap + 0.03), 0.022, button))
	var spot := _spot([0.0, -0.3])
	_add("Pocket", _patch(_rounded_rect(0.0, 0.0, 0.13, 0.085), _frame(spot.x, spot.y, gap + 0.008), 0.022, _mat(color.darkened(0.1))))

func _pocket_square(piece: Dictionary) -> void:
	# A welt pocket with three white points peeking out of it.
	var frame := _spot_frame(piece)
	var cloth := _mat(Color(str(piece.get("color", "fbfbf8"))))
	for i in range(3):
		var x := (float(i) - 1.0) * 0.032
		_add("PocketSquare", _patch(_ear_triangle(Vector2(x, 0.0), 0.05, 0.055 + 0.012 * float(i % 2), -x * 4.0), frame, 0.016, cloth, 0.002))
	_add("Welt", _patch(_rounded_rect(0.0, 0.0, 0.085, 0.014), frame, 0.02, _mat(Color(str(piece.get("welt", "2a2a30")))), 0.006))

func _wings(piece: Dictionary) -> void:
	var frame := _spot_frame(piece)
	_add("Wings", _patch(_wings_outline(float(piece.get("scale", 1.0))), frame, 0.022, _soft_mat(Color(str(piece.get("color", "e2bd4f"))), 0.6), 0.004))

# Pilot's wings: a small round centre with a swept wing to each side.
func _wings_outline(scale: float) -> PackedVector2Array:
	var half := [Vector2(0.0, 0.026), Vector2(0.04, 0.032), Vector2(0.09, 0.042), Vector2(0.135, 0.048), Vector2(0.122, 0.03), Vector2(0.128, 0.022), Vector2(0.1, 0.012), Vector2(0.104, 0.004), Vector2(0.07, -0.006), Vector2(0.04, -0.018), Vector2(0.0, -0.028)]
	var outline := PackedVector2Array()
	for point in half:
		outline.append(point * scale)
	for i in range(half.size() - 2, 0, -1):
		outline.append(Vector2(-half[i].x, half[i].y) * scale)
	return _smooth_outline(outline, 2)

# Crown radius, seat height and centre for a hat of radius r between the ears,
# sunk into pressed hair by the species' hat_sink.
func _fit_hat(r: float) -> Vector3:
	var sink := float(_fit.get("hat_sink", 0.0))
	r = minf(r, _ear_room(_seat(r) - sink) - 0.025)
	_hat = Vector3(r, _seat(r) - sink, float(_fit.get("hat_z", 0.0)))
	return _hat

func _straw_hat(piece: Dictionary) -> void:
	# A woven straw hat: a round crown between the ears and a wide, drooping brim
	# the ears poke up through. Rings of darker straw read as the woven coil.
	var hat := _fit_hat(float(piece.get("radius", 0.3)))
	var r := hat.x
	var at := Vector3(0, hat.y, hat.z)
	# The brim keeps its full width; ears poke up through it (user decision).
	_brim = float(piece.get("brim", 0.62))
	var color := Color(str(piece.get("color", "e8c27a")))
	var straw := _mat(color)
	var weave := _mat(color.darkened(0.16))
	_add("StrawBrim", _lathe(at, [[-0.005, 0.01], [-0.012, r], [-0.06, _brim * 0.97], [-0.055, _brim], [-0.04, _brim * 0.985], [0.0, r], [0.004, 0.01]], straw))
	_add("StrawCrown", _lathe(at, [[-0.02, 0.01], [-0.015, r * 1.03], [0.08, r * 1.0], [0.15, r * 0.93], [0.2, r * 0.74], [0.222, r * 0.38], [0.228, 0.01]], straw))
	var rings: Array = []
	for k in range(1, 5):
		var radius := lerpf(r, _brim * 0.985, float(k) / 5.0)
		var lift := lerpf(0.0, -0.04, (radius - r) / (_brim * 0.985 - r)) + 0.006
		rings.append(_tube(_ring(at + Vector3(0, lift, 0), radius), _same(0.006, 65), weave))
	for h in [0.11, 0.15, 0.185]:
		rings.append(_tube(_ring(at + Vector3(0, h, 0), r * lerpf(1.0, 0.8, (h - 0.08) / 0.12) + 0.004), _same(0.006, 65), weave))
	_add("StrawWeave", _merge(rings, weave))
	_add("StrawBand", _tube(_ring(at + Vector3(0, 0.035, 0), r * 1.02 + 0.012), _same(0.026, 65), _mat(Color(str(piece.get("band", "8a5a2b"))))))

func _chef_hat(piece: Dictionary) -> void:
	# A tall chef's toque between the ears: a band, a pleated body that flares
	# upward and a puffy mushroom top. Named CapBand/CapCrown so the cap checks
	# (ear clearance, hair under the band) cover it too.
	var hat := _fit_hat(float(piece.get("radius", 0.27)))
	var r := hat.x
	var at := Vector3(0, hat.y, hat.z)
	var color := Color(str(piece.get("color", "222226")))
	var cloth := _mat(color)
	var pleat := _mat(color.lightened(0.12))
	var height := float(piece.get("height", 0.3))
	_add("CapBand", _lathe(at, [[-0.06, 0.01], [-0.055, r * 0.97], [0.0, r], [0.09, r], [0.095, 0.01]], cloth))
	var top := 0.08 + height
	# The puffy top is as wide as the ears allow at its height (tall samoyed ears).
	var puff := minf(r * 1.5, (_ear_room(at.y + top + 0.08, 0.2) - 0.02) / 1.05)
	var flare := minf(r * 1.18, puff)
	_add("CapCrown", _merge([
		_lathe(at, [[0.07, 0.01], [0.075, r * 0.99], [0.08 + height * 0.5, lerpf(r, flare, 0.5)], [top, flare], [top + 0.005, 0.01]], cloth),
		_blobs(_toque_puffs(at + Vector3(0, top + 0.02, 0), puff), cloth)], cloth))
	# Pleats run up the body, and a slightly lighter band trims its base.
	var lines: Array = []
	for i in range(12):
		var theta := TAU * (float(i) + 0.5) / 12.0
		var dir := Vector3(cos(theta), 0, sin(theta))
		lines.append(_tube([at + dir * (r + 0.006) + Vector3(0, 0.1, 0), at + dir * (lerpf(r, flare, 0.5) + 0.006) + Vector3(0, 0.08 + height * 0.5, 0), at + dir * (flare + 0.004) + Vector3(0, top - 0.02, 0)], [0.007, 0.007, 0.007], pleat))
	_add("CapPleats", _merge(lines, pleat))
	_add("CapTrim", _tube(_ring(at + Vector3(0, 0.085, 0), r + 0.008), _same(0.014, 65), pleat))

func _wizard_hat(piece: Dictionary) -> void:
	# A fortune-teller's tall pointed hat between the ears (Madame Luna, Mystery House, 9 Nov
	# 2026): a narrow brim, a cone narrowing to a point, a gold band. Named CapBand/CapCrown so
	# the cap checks (ear clearance, hair under the band) cover it too.
	var hat := _fit_hat(float(piece.get("radius", 0.26)))
	var r := hat.x
	var at := Vector3(0, hat.y, hat.z)
	var cloth := _mat(Color(str(piece.get("color", "4a2a86"))))
	var gold := _soft_mat(Color(str(piece.get("trim", "e2b54e"))), 0.6)
	var height := float(piece.get("height", 0.55))
	var brim := r * float(piece.get("brim", 1.12))
	_add("CapBand", _lathe(at, [[-0.03, 0.01], [-0.028, brim], [0.0, brim * 1.02], [0.012, r * 0.97], [0.015, 0.01]], cloth))
	_add("CapCrown", _lathe(at, [[0.0, 0.01], [0.005, r], [height * 0.35, r * 0.72], [height * 0.7, r * 0.38], [height, 0.03], [height + 0.012, 0.004]], cloth))
	_add("CapTrim", _tube(_ring(at + Vector3(0, 0.04, 0), r * 0.94 + 0.008), _same(0.02, 65), gold))

# The toque's puffy top: a dome ringed by overlapping puffs.
func _toque_puffs(center: Vector3, radius: float) -> Array:
	var puffs: Array = [[center + Vector3(0, 0.05, 0), Vector3(radius * 0.8, 0.14, radius * 0.8)]]
	for i in range(8):
		var theta := TAU * float(i) / 8.0
		puffs.append([center + Vector3(cos(theta) * radius * 0.6, 0.0, sin(theta) * radius * 0.6), Vector3(radius * 0.45, 0.12, radius * 0.45)])
	return puffs

# 65 points closing a horizontal circle of `radius` round `center`.
func _ring(center: Vector3, radius: float) -> Array:
	var points: Array = []
	for i in range(65):
		var theta := TAU * float(i) / 64.0
		points.append(center + Vector3(cos(theta) * radius, 0, sin(theta) * radius))
	return points

func _cap(piece: Dictionary) -> void:
	# A peaked police cap perched on the crown between the ears; it narrows to
	# fit whatever room the ears leave.
	# hat_sink lowers the cap into hair that is pressed under it (see _press).
	var hat := _fit_hat(float(piece.get("radius", 0.30)))
	var r := hat.x
	var at := Vector3(0, hat.y, hat.z)
	var crown := _mat(Color(str(piece.get("color", "2c3e66"))))
	_add("CapBand", _lathe(at, [[-0.06, 0.01], [-0.055, r * 0.95], [0.0, r * 0.98], [0.09, r], [0.11, r], [0.115, 0.01]], _mat(Color(str(piece.get("band", "1a1f2b"))))))
	_add("CapCrown", _lathe(at, [[0.08, 0.01], [0.085, r * 1.02], [0.12, r * 1.16], [0.155, r * 1.22], [0.18, r * 1.14], [0.197, r * 0.85], [0.205, r * 0.35], [0.207, 0.01]], crown))
	# The visor is a flat oval mostly tucked under the band, tilted down at the front.
	var flat := Basis(Vector3.RIGHT, Vector3(0, 0, 1), Vector3(0, -1, 0))
	var visor := _moved(_pillow(_ear_ellipse(Vector2(0, -0.62 * r), r * 0.9, r * 0.6, 0.0), -0.02, 0.025, crown), Transform3D(Basis(Vector3.RIGHT, -0.32) * flat * Basis.from_scale(Vector3(1, 1, 0.35)), at + Vector3(0, 0.005, 0)))
	visor.surface_set_material(0, _soft_mat(Color(str(piece.get("visor", "15171c"))), 0.6))
	_add("CapVisor", visor)
	if piece.has("cord"):
		_add("CapCord", _tube(_ring(at + Vector3(0, 0.07, 0), r + 0.012), _same(0.016, 65), _soft_mat(Color(str(piece["cord"])), 0.6)))
	var badge := _soft_mat(Color(str(piece.get("badge", "e2bd4f"))), 0.6)
	var crest := Transform3D(Basis.IDENTITY, at + Vector3(0, 0.13, -r * 1.2))
	match str(piece.get("emblem", "oval")):
		"wings":
			_add("CapBadge", _patch(_wings_outline(0.75), crest, 0.025, badge))
		"bus":
			# A little bus front: white body, dark windscreen, two wheels.
			var dark := _mat(Color("2c3e66"))
			_add("CapBadge", _patch(_rounded_rect(0.0, 0.0, 0.05, 0.04), crest, 0.025, badge))
			_add("CapBadgeWindow", _patch(_rounded_rect(0.0, 0.012, 0.038, 0.014), crest, 0.025, dark, 0.004))
			for x in [-0.028, 0.028]:
				_add("CapBadgeWheel", _patch(_circle(Vector2(x, -0.04), 0.011), crest, 0.025, dark))
		_:
			_add("CapBadge", _patch(_ear_ellipse(Vector2.ZERO, 0.04, 0.05, 0.0), Transform3D(Basis.IDENTITY, at + Vector3(0, 0.055, -r)), 0.025, badge))

# Highest height where the crown is about as wide as a hat of radius r.
func _seat(r: float) -> float:
	var y: float = _crown["top"]
	while y > 1.5 and _half_width(_crown, y) < r * 0.92:
		y -= 0.005
	return y

# Distance from the head's centre line to the nearest ear between `below` under
# and `above` over height y (by default the band and crown of a cap seated at y).
func _ear_room(y: float, below: float = 0.08, above: float = 0.3) -> float:
	var room := INF
	for ear in _wearer.find_children("*Ear", "MeshInstance3D", true, false):
		for p in _vertices(ear):
			if p.y > y - below and p.y < y + above:
				room = minf(room, Vector2(p.x, p.z).length())
	return room
