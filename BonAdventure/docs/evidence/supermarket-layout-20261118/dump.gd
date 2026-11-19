extends SceneTree
## Lists every MarketInterior root with its interior-space box and word key (headless, read only).
## HOME=<isolated> godot --headless --path . --script res://docs/evidence/supermarket-layout-20261118/dump.gd
func _initialize():
	var town: Node3D = load("res://scenes/town/supermarket.scn").instantiate()
	var site: Node3D = town.get_node("RelocatedSites__Supermarket")
	var interior: Node3D = site.get_node("MarketInterior")
	print("SITE xf=%s INTERIOR xf=%s" % [site.transform, interior.transform])
	for root in interior.get_children():
		var box := AABB()
		var first := true
		if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
			box = (root as MeshInstance3D).transform * (root as MeshInstance3D).mesh.get_aabb()
			first = false
		for m in root.find_children("*", "MeshInstance3D", true, false):
			if (m as MeshInstance3D).mesh == null: continue
			var b: AABB = _to(interior, m) * (m as MeshInstance3D).mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		var extra := ""
		if root is Label3D: extra = " LABEL '%s'" % (root as Label3D).text
		var pos = (root as Node3D).position if root is Node3D else Vector3.ZERO
		var rot = (root as Node3D).rotation if root is Node3D else Vector3.ZERO
		print("R|%s|%s|%s|pos=%s|rot=%s|box=%s..%s|kids=%d%s" % [root.name, root.get_class(), root.get_meta("word_key", ""), pos, rot, box.position, box.end, root.get_child_count(), extra])
	quit()

func _to(root: Node, node: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while node != root:
		if node is Node3D: xf = (node as Node3D).transform * xf
		node = node.get_parent()
	return xf
