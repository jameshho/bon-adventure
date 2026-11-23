extends SceneTree
## Prints the nodes this piece of work changes (civic fixes, 23 Nov 2026): the zoo gates and
## zoo signs (base), the police lockers, the school classroom's wall decorations, the warehouse
## cabinet. Headless:  godot --headless --path . --script res://docs/evidence/civic-fixes-20261123/dump.gd
func _init():
	var base: Node = load("res://scenes/town/base.scn").instantiate()
	for p in ["ParkZoo/ZooEntranceGate", "ParkZoo/FarmEntranceGate"]:
		var g := base.get_node_or_null(p) as Node3D
		if g == null:
			print("missing ", p); continue
		print(p, " pos ", g.position, " basis ", g.basis, " parent ", g.get_parent().transform)
		for c in g.get_children():
			print("  ", c.name, " ", c.get("position"), " rot ", c.get("rotation"))
			for d in c.get_children():
				print("     ", d.name, " ", d.get("position"), " ", d.get_class())
	for n in base.find_children("*", "", true, false):
		var t := String(n.name).to_lower()
		if ("zoo" in t and ("sign" in t or "label" in t or "board" in t)) or (n is Label3D and "ZOO" in String(n.text).to_upper()):
			print("ZOO SIGN? ", base.get_path_to(n), " ", n.get_class(), " ", (n.text if n is Label3D else ""), " ", n.get("global_position") if false else "")
	for unit in ["police", "school", "warehouse"]:
		var s: Node = load("res://scenes/town/%s.scn" % unit).instantiate()
		for n in s.find_children("*", "", true, false):
			var t := String(n.name).to_lower()
			if (unit == "police" and ("locker" in t or "tomato" in t)) or (unit == "warehouse" and "cabinet" in t) or (unit == "school" and ("pennant" in t or "bunting" in t or "flag" in t or "triangle" in t or "poster" in t or "garland" in t)):
				print(unit, ": ", s.get_path_to(n), " ", n.get_class(), " ", n.get("position"), " meta ", n.get_meta_list())
	quit()
