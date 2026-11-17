extends SceneTree
## Builds the rigged clay zebra (16 Nov 2026) from the finished display
## scenes/animals/zebra_clay.tscn into scenes/animals/zebra_clay_rigged.scn: a skinned, seam-free
## skeleton (scripts/characters/clay_rig.gd) with the zebra's settings for clay_animator.gd.
## Rebuild the display first when the zebra changes.
##   godot --headless --path . --script res://tools/build_zebra_clay_rig.gd
## Bone shapes are in the zebra sheet's pixels like zebra_clay.gd's shapes (side view: x toward
## the tail, y down; z lateral, + = the zebra's left), placed with its V() and to_model(); the
## zebra script is only read. Record: docs/evidence/hoofed-anim-20261116/notes.md.

const ZebraClay := preload("res://scripts/characters/zebra_clay.gd")
const Bake := preload("res://tools/clay_rig_bake.gd")


## Sheet pixel -> the display's model space.
static func M(x: float, y: float, z := 0.0) -> Vector3:
	return ZebraClay.to_model(ZebraClay.V(x, y, z)) / ZebraClay.FINE


## Sheet pixels -> model units (a length).
static func R(px: float) -> float:
	return px * ZebraClay.ZH / (ZebraClay.ZY - ZebraClay.ZTOP)


const BODY_KEEP := 0.12     # of the closed body (321k triangles): about 40k, near the rhino's
const LEGS := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]


func spec(zebra) -> Dictionary:
	var bones := [
		{"name": "root", "parent": "", "pivot": Vector3.ZERO, "shapes": []},
		{"name": "body", "parent": "root", "pivot": M(815, 485), "shapes": [
			[M(752, 482), M(880, 488), R(55)], [M(776, 446), M(776, 446), R(38)]]},
		# The upright neck turns with part of the head's look (clay_animator.gd neck_share).
		{"name": "neck", "parent": "body", "pivot": M(762, 440), "shapes": [
			[M(750, 418), M(745, 350), R(38)]]},
		{"name": "head", "parent": "neck", "pivot": M(742, 328), "shapes": [
			[M(712, 326), M(712, 326), R(45)], [M(736, 316), M(736, 316), R(38)],
			[M(706, 352), M(676, 342), R(33)]]},
		# The tail stalk slants down from the rump (the tuft is its own mesh, rigid on this bone).
		{"name": "tail", "parent": "body", "pivot": M(916, 457), "shapes": [
			[M(920, 460), M(943, 506), R(10)]]},
	]
	for k in 4:
		var leg: Array = ZebraClay.Z_LEGS[k]
		var x: float = leg[0]
		var z: float = leg[1]
		var shapes := [[M(x, 548, z), M(x, 662, z), R(25)]] if k < 2 else \
				[[M(x - 1.0, 548, z), M(x + 4.0, 584, z), R(28)], [M(x + 4.0, 584, z), M(x, 662, z), R(25)]]
		bones.append({"name": LEGS[k], "parent": "root", "pivot": M(x if k < 2 else x - 2.0, 495.0 if k < 2 else 490.0, z * 0.92), "shapes": shapes})
	for side in [["ear_l", 1.0], ["ear_r", -1.0]]:
		var z: float = side[1]
		bones.append({"name": side[0], "parent": "head", "pivot": M(729, 289, z * 30.0),
				"shapes": [[M(731, 271, z * 37.0), M(734, 248, z * 46.0), R(16)]]})
	zebra._shape()
	var eyes := []
	for side in [["LeftEye", 1.0], ["RightEye", -1.0]]:
		var f: Array = zebra._zebra_eye_frame(side[1])
		eyes.append(Bake.eye(side[0], ZebraClay.to_model(f[0]) / ZebraClay.FINE,
				ZebraClay.normal_to_model(f[1]), ZebraClay.normal_to_model(f[3])))
	return {
		"bones": bones,
		"blend": R(10),
		# The mane runs from the forelock down the neck to the withers: blended over the three.
		"parts": {"Body": ["body", "neck", "head", "tail"] + LEGS, "Muzzle": "head", "Tongue": "head",
				"Mane": ["head", "neck", "body"], "Ears": ["head", "ear_l", "ear_r"], "Hooves": LEGS, "Tail tuft": "tail"},
		"eyes": {"mesh": "Eyes", "bone": "head", "eyes": eyes},
		"keep": ["Footprint"],
		"merge": true,
		"on_head": ["Face details"],
		# The body is closed (_closed) before it is thinned.
		"simplify": {"Body": BODY_KEEP, "Mane": 0.25, "Ears": 0.25, "Hooves": 0.25, "Muzzle": 0.5, "Tongue": 0.5, "Tail tuft": 0.5},
	}


func _initialize() -> void:
	var display: Node3D = load("res://scenes/animals/zebra_clay.tscn").instantiate()
	# The painted stripes split the body's triangles along their edges without splitting the
	# neighbours (T-junctions: ~100k open edges, 286k triangles). The simplifier keeps open edges,
	# so it stopped at a third and pulled the shape out of true (rest difference 9.5 levels).
	# A closed copy (the display is not changed) thins like the other animals.
	var body := display.get_node("Body") as MeshInstance3D
	var closed := ArrayMesh.new()
	closed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _closed(body.mesh.surface_get_arrays(0)))
	body.mesh = closed
	# The zebra: longer legs and a brisker trot than the cow, upright ears that flick.
	var settings := {
		"leg_length": M(0, 495).distance_to(M(0, ZebraClay.ZY)),
		"swing_deg": 24.0,
		"lift": R(13),
		"bob": R(4),
		"roll_deg": 2.0,
		"head_turn_deg": 26.0,
		"nod_deg": 4.0,
		"neck_share": 0.45,
		"ear_deg": 7.0,
		"tail_deg": 14.0,
		"tail_axis": Vector3.FORWARD,
	}
	var result := Bake.bake("zebra", "ZebraClayRigged", display, spec(ZebraClay.new()), settings, "tools/build_zebra_clay_rig.gd")
	display.free()
	quit(result)


## `arrays` with its T-junctions filled: for each open edge a -> b, the chain of open edges that
## runs back from b to a along it (the neighbour's split edge) is closed with a fan of
## zero-area triangles, so every edge has two sides. Positions, normals and colours unchanged.
static func _closed(arrays: Array) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var directed := {}
	for t in range(0, index.size(), 3):
		for k in 3:
			directed[Vector2i(index[t + k], index[t + (k + 1) % 3])] = true
	var out_edges := {}     # vertex -> open edges leaving it
	var open := []
	for e: Vector2i in directed:
		if not directed.has(Vector2i(e.y, e.x)):
			open.append(e)
			if not out_edges.has(e.x):
				out_edges[e.x] = []
			out_edges[e.x].append(e.y)
	var fill := PackedInt32Array()
	var filled := 0
	for e: Vector2i in open:
		var a := e.x
		var b := e.y
		var chain := _chain(b, a, verts, out_edges, verts[a], verts[b], 6)
		if chain.is_empty():
			continue
		# chain: b -> p1 -> ... -> pn -> a; fan from a over the reversed edges.
		var pts := [b] + chain
		for i in range(pts.size() - 1, 0, -1):
			fill.append_array([a, pts[i], pts[i - 1]])
		filled += 1
	var out := arrays.duplicate()
	var joined := index.duplicate()
	joined.append_array(fill)
	out[Mesh.ARRAY_INDEX] = joined
	print("ZEBRA BODY: %d open edges, %d closed with %d triangles" % [open.size(), filled, fill.size() / 3])
	return out


## The open-edge path from `from` to `to` through points near the segment a-b (at most `depth`
## steps), without `from` and with `to` dropped; empty when there is none.
static func _chain(from: int, to: int, verts: PackedVector3Array, out_edges: Dictionary, a: Vector3, b: Vector3, depth: int) -> Array:
	if depth == 0 or not out_edges.has(from):
		return []
	var ab := b - a
	var tol := ab.length() * 0.2
	for next: int in out_edges[from]:
		if next == to:
			return []    # the edge b -> a itself would not be a split edge
		var p := verts[next]
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if p.distance_to(a + ab * t) > tol:
			continue
		if out_edges.has(next) and (out_edges[next] as Array).has(to):
			return [next]
		var rest := _chain(next, to, verts, out_edges, a, b, depth - 1)
		if not rest.is_empty():
			return [next] + rest
	return []
