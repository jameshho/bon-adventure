extends SceneTree
## Prints the bank's teller-area parts (chairs, counter, staff door) in town coordinates (24 Nov 2026).
## Headless:  godot --headless --path . --script res://docs/evidence/bank-teller-polish-20261124/dump.gd
func _xf(root: Node, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		if c is Node3D:
			xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf

func _init():
	var unit: Node = load("res://scenes/town/bank.scn").instantiate()
	for n in unit.find_children("*", "Node3D", true, false):
		var xf := _xf(unit, n)
		var p := xf.origin
		if p.x < 135.5 or p.x > 145 or p.z < 103 or p.z > 113:
			continue
		var t := String(n.name).to_lower()
		var key := str(n.get_meta("word_key", ""))
		if key != "" or "chair" in t or "seat" in t or "staff" in t or "counter" in t or "divider" in t or "teller" in t:
			var extra := ""
			var meshes: Array = n.find_children("*", "MeshInstance3D", true, false)
			if n is MeshInstance3D: meshes.append(n)
			if not meshes.is_empty() and meshes[0].mesh != null:
				var box: AABB = _xf(unit, meshes[0]) * meshes[0].mesh.get_aabb()
				extra = " box %s..%s" % [box.position, box.end]
			print(unit.get_path_to(n), " key=", key, " @ ", p, " children=", n.get_child_count(), extra)
	quit()
