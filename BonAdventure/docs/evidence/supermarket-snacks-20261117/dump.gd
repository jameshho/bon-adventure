extends SceneTree
## Measures the supermarket fixtures and signs this change moves (headless, read only).
func _initialize():
	var town: Node3D = load("res://scenes/town/supermarket.scn").instantiate()
	var site: Node3D = town.get_node("RelocatedSites__Supermarket")
	var interior: Node3D = site.get_node("MarketInterior")
	for title in ["Drinks cooler", "Household gondola", "Household endcap", "Pantry endcap", "Pantry gondola", "Produce Stand", "Refrigerator2", "Candy rack"]:
		var root: Node3D = interior.get_node(title)
		var box := AABB()
		var first := true
		for m in root.find_children("*", "MeshInstance3D", true, false):
			var xf: Transform3D = root.transform * _to(root, m)
			var b: AABB = xf * (m as MeshInstance3D).mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		print("FIX %s rot=%s box=%s end=%s" % [title, root.rotation, box.position, box.end])
	for l in site.find_children("*", "Label3D", true, false):
		var p: Node3D = l
		print("LABEL %s | %s | %s | parent %s | src %s" % [site.get_path_to(l), (l as Label3D).text, site.to_local(_glob(site, l)), l.get_parent().name, l.get_meta("sign_source", "")])
	for n in site.get_children():
		if n is Node3D and str(n.name).to_lower().contains("wall"):
			print("WALL %s %s" % [n.name, (n as Node3D).position])
	quit()

func _to(root: Node, node: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while node != root:
		if node is Node3D: xf = (node as Node3D).transform * xf
		node = node.get_parent()
	return xf

func _glob(site: Node3D, node: Node3D) -> Vector3:
	return (site.transform * _to(site, node)).origin if false else _to(site, node).origin
