extends SceneTree
## 9 Nov 2026: clickability audit of the sports store, furniture store, Pizza and Burger and
## police station (and the hospital for reference).
## HOME=<scratch> VT_FOCUS="sports, furniture, restaurants, police, hospital" VT_SPAWN=none \
##   godot --headless --path . --script res://docs/evidence/interiors-polish-20261109/audit.gd -- [unit ...] [--rays] [--loose]
## Prints one line per word root: key, learnable (in words.json), collision shapes under the
## root, visible, and with --rays whether a pointer ray from around it reaches it. With --loose it
## also lists meshes outside any word root whose node name contains a word (look like a word but
## are not connected). Read-only: writes nothing.
const Controller := preload("res://scripts/player/interaction_controller.gd")
const PARTS := {
	"sports": ["RelocatedSites/Sports", "Buildings/SportsStore"],
	"furniture": ["RelocatedSites/Furniture", "Buildings/FurnitureStore"],
	"restaurants": ["Restaurants/Burger"],
	"police": ["RelocatedSites/Police"],
	"hospital": ["RelocatedSites/Hospital", "Buildings/Hospital"],
}
var game

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var units: Array = args.filter(func(a): return not a.begins_with("--"))
	if units.is_empty(): units = ["sports", "furniture", "restaurants", "police"]
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await physics_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	var totals := {}
	for unit in units:
		for path in PARTS[unit]:
			var top: Node3D = game.apartment.get_node_or_null(path)
			if top == null:
				print("AUDIT %s: %s missing" % [unit, path]); continue
			audit(unit, top, "--rays" in args, "--loose" in args, totals)
	for unit in totals: print("AUDIT TOTAL %s: %s" % [unit, totals[unit]])
	print("AUDIT done")
	quit()

func key_of(n: Node) -> String:
	var raw := str(n.get_meta("word_key", ""))
	return str(game.vocabulary_aliases.get(raw, raw))

func audit(unit: String, top: Node3D, rays: bool, loose: bool, totals: Dictionary) -> void:
	var t: Dictionary = totals.get(unit, {"roots": 0, "unlearnable": 0, "no_shape": 0, "hidden": 0, "unreachable": 0, "loose": 0})
	var roots: Array = []
	for n in [top] + top.find_children("*", "Node3D", true, false):
		if str(n.get_meta("word_key", "")) != "": roots.append(n)
	for r in roots:
		var key := key_of(r)
		var learnable: bool = game.vocabulary.has(key)
		var shapes := 0
		for s in r.find_children("*", "CollisionShape3D", true, false) + r.find_children("*", "CollisionPolygon3D", true, false):
			if not s.disabled and s.get_parent() is CollisionObject3D: shapes += 1
		var vis: bool = r.is_visible_in_tree()
		var reach := "-"
		if rays: reach = "yes" if reachable(r) else "NO"
		t.roots += 1
		if not learnable: t.unlearnable += 1
		if shapes == 0: t.no_shape += 1
		if not vis: t.hidden += 1
		if reach == "NO": t.unreachable += 1
		var flag := ""
		if not learnable or shapes == 0 or not vis or reach == "NO": flag = "  <<"
		print("ROOT %s | %s | key=%s learnable=%s shapes=%d visible=%s reach=%s | at %s%s" % [unit, top.get_path_to(r), key, learnable, shapes, vis, reach, fmt(center(r)), flag])
	if loose:
		var words: Array = game.vocabulary.keys()
		words.sort_custom(func(a, b): return a.length() > b.length())
		for m in top.find_children("*", "MeshInstance3D", true, false):
			if not m.is_visible_in_tree(): continue
			var a: Node = m
			var rooted := false
			while a != null and a != top.get_parent():
				if str(a.get_meta("word_key", "")) != "" or a.has_meta("exterior_word"): rooted = true; break
				a = a.get_parent()
			if rooted: continue
			var nm := String(m.name).to_lower().replace("_", " ")
			var pn := String(m.get_parent().name).to_lower().replace("_", " ")
			for w in words:
				if w.length() >= 3 and (nm.contains(w) or pn.contains(w)):
					t.loose += 1
					print("LOOSE %s | %s | looks like '%s' | at %s" % [unit, top.get_path_to(m), w, fmt(m.global_position)])
					break
	totals[unit] = t

func center(r: Node3D) -> Vector3:
	var box := AABB(); var first := true
	for m in r.find_children("*", "MeshInstance3D", true, false) + ([r] if r is MeshInstance3D else []):
		if m.mesh == null: continue
		var b: AABB = m.global_transform * m.mesh.get_aabb()
		box = b if first else box.merge(b); first = false
	return r.global_position if first else box.get_center()

func fmt(v: Vector3) -> String: return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]

## Rays toward the root from 8 directions around it (2.4 m out, at the item's height plus 0.8
## and at eye level) and from above, aimed at its centre and at points between the centre and
## its corners; reachable when any first hit picks the root (or a word root inside it).
func reachable(r: Node3D) -> bool:
	var c := center(r)
	var box := bounds(r)
	var targets: Array = [c]
	for i in 8:
		var corner := box.position + Vector3(box.size.x * (i & 1), box.size.y * ((i >> 1) & 1), box.size.z * ((i >> 2) & 1))
		targets.append(c.lerp(corner, .6))
	var space: PhysicsDirectSpaceState3D = game.apartment.get_world_3d().direct_space_state
	for t in targets:
		var starts: Array = [t + Vector3(0, 2.0, 0)]
		for i in 8:
			var a := TAU * i / 8.0
			var off := Vector3(cos(a), 0, sin(a)) * 2.4
			starts.append(t + off + Vector3(0, 0.8, 0))
			starts.append(Vector3(t.x + off.x, max(t.y + 0.3, 1.6), t.z + off.z))
		for s in starts:
			var q := PhysicsRayQueryParameters3D.create(s, t + (t - s).normalized() * 0.3)
			q.collide_with_areas = true
			q.collision_mask = 0xFFFFFFFF & ~Controller.FIGURE_LAYER
			q.exclude = [game.player.get_rid()]
			var hit := space.intersect_ray(q)
			if hit.is_empty(): continue
			var got: Node = Controller.vocabulary_target(hit.collider, game.apartment, game.doors)
			if got == r or (got != null and r.is_ancestor_of(got)): return true
	return false

func bounds(r: Node3D) -> AABB:
	var box := AABB(); var first := true
	for m in r.find_children("*", "MeshInstance3D", true, false) + ([r] if r is MeshInstance3D else []):
		if m.mesh == null: continue
		var b: AABB = m.global_transform * m.mesh.get_aabb()
		box = b if first else box.merge(b); first = false
	return AABB(r.global_position, Vector3.ZERO) if first else box
