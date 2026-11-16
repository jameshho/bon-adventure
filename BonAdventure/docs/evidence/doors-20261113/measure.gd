## Door opening measurement (13 Nov 2026, docs/guides/DOORS.md): loads Main, prints and writes JSON of each
## old door (world units: leaf bounds, wall ray hits, swing side). Writes only MEASURE_OUT.
##   MEASURE_OUT=<scratch>/measure.json HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none \
##     godot --headless --path . --script res://docs/evidence/doors-20261113/measure.gd
extends SceneTree
const HOME := ["Terrace", "Guest bath", "Front", "Family bathroom", "Yellow bedroom", "Garage access", "Guest suite bathroom", "Hall", "Master bedroom", "Bathroom", "Study"]
var DOORS := [
	["RelocatedSites/Bank/Manager office", "slide"], ["RelocatedSites/Bank/Vault entrance", "slide"],
	["RelocatedSites/Police/Interview room", "slide"], ["RelocatedSites/Police/Holding cell", "slide"], ["RelocatedSites/Police/Lineup room door", "hinge"],
	["Airport/Terminal/Interior/Women's restroom door", "hinge"], ["Airport/Terminal/Interior/Men's restroom door", "hinge"], ["Airport/ControlTower/Interior/Deck door", "slide"],
	["Buildings/Hospital/Floor1/Pharmacy/PharmacyDoor", "hinge"], ["Buildings/Hospital/Azotea/RoofDoor", "hinge"],
	["Warehouse/Architecture/Warehouse entrance door", "slide"], ["Warehouse/Architecture/Warehouse hall door", "hinge"],
	["Airport/Terminal/Interior/Boarding door", "static"], ["Restaurants/Burger/Back door", "static"], ["Restaurants/Pizza/Kitchen back door", "static"],
	["Restaurants/Pizza/Arched back door", "static"], ["Restaurants/Pizza/Entrance door leaf", "static"],
]
var game
var space: PhysicsDirectSpaceState3D
var exclude: Array[RID] = []

func _initialize(): run.call_deferred()

func ray(a: Vector3, b: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.exclude = exclude
	return space.intersect_ray(q)

func run() -> void:
	for h in HOME: DOORS.push_front(["RelocatedSites/Home/%s door frame/%s door" % [h, h], "hinge"])
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 3: await physics_frame
	space = game.get_world_3d().direct_space_state
	var town: Node3D = game.apartment
	var out := []
	for d in DOORS:
		var node: Node3D = town.get_node_or_null(d[0])
		if node == null:
			print("MISSING ", d[0])
			continue
		exclude = []
		for b in node.find_children("*", "CollisionObject3D", true, false): exclude.append(b.get_rid())
		var a := AABB()
		var first := true
		for m in node.find_children("*", "MeshInstance3D", true, false):
			if m.mesh == null: continue
			var bb: AABB = m.global_transform * m.mesh.get_aabb()
			a = bb if first else a.merge(bb)
			first = false
		var c: Vector3 = a.get_center()
		var u := Vector3(1, 0, 0) if a.size.x >= a.size.z else Vector3(0, 0, 1)
		var n := Vector3(0, 0, 1) if u.x != 0 else Vector3(1, 0, 0)
		var st: Dictionary = game.doors.get(node, node.get_meta("door_state", {}))
		var pivot: Vector3 = node.global_position
		if d[1] == "hinge":
			var ang: float = st.angle
			var rel: Vector3 = c - pivot
			var opened: Vector3 = pivot + rel.rotated(Vector3.UP, ang)
			if (opened - c).dot(n) < 0: n = -n
		u = Vector3.UP.cross(n)
		var y0: float = a.position.y
		var hits := {}
		for hy in [0.6, 1.2, 1.8]:
			for s in [-1.0, 1.0]:
				var from := Vector3(c.x, y0 + hy, c.z)
				var r := ray(from, from + u * s * 4.0)
				hits["%s_%s" % [s, hy]] = snappedf((r.position - from).dot(u * s), 0.001) if r else -1.0
		var head := ray(Vector3(c.x, y0 + 0.5, c.z), Vector3(c.x, y0 + 6.0, c.z))
		var floor_hit := ray(Vector3(c.x, y0 + 0.5, c.z), Vector3(c.x, y0 - 2.0, c.z))
		var lw: float = a.size.x if absf(u.x) > .5 else a.size.z
		var faces := []
		for s in [-1.0, 1.0]:
			var side_pt: Vector3 = c + u * s * (lw * 0.5 + 0.25)
			var f := ray(side_pt + n * 1.5, side_pt)
			var b := ray(side_pt - n * 1.5, side_pt)
			faces.append([snappedf((f.position - c).dot(n), 0.001) if f else null, snappedf((b.position - c).dot(n), 0.001) if b else null])
		var entry := {
			"path": d[0], "kind": d[1], "c": [c.x, c.y, c.z], "min_y": y0, "max_y": a.end.y,
			"leaf_w": lw, "leaf_t": a.size.z if absf(u.x) > .5 else a.size.x,
			"u": [u.x, u.y, u.z], "n": [n.x, n.y, n.z], "pivot_u": (pivot - c).dot(u), "pivot_n": (pivot - c).dot(n),
			"hits": hits, "head": (head.position.y - y0) if head else null, "floor": floor_hit.position.y if floor_hit else null,
			"faces": faces, "state": str(st), "scale": town.global_basis.get_scale().x,
		}
		if st.get("type") == "slide":
			var sh: Vector3 = node.get_parent().global_basis * st.shift
			entry["shift_u"] = sh.dot(u)
		out.append(entry)
		print("DOOR ", JSON.stringify(entry))
	var f := FileAccess.open(OS.get_environment("MEASURE_OUT"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	quit()
