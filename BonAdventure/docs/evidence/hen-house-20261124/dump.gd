extends SceneTree
## Prints the farm layout around the barn for the hen house (24 Nov 2026), in town coordinates.
## Headless:  godot --headless --path . --script res://docs/evidence/hen-house-20261124/dump.gd
func _xf(root: Node, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		if c is Node3D:
			xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf

func _init():
	var base: Node = load("res://scenes/town/base.scn").instantiate()
	var zoo := base.get_node("ParkZoo") as Node3D
	print("ParkZoo xf ", _xf(base, zoo))
	for c in zoo.get_children():
		var t := String(c.name)
		var low := t.to_lower()
		if c is Node3D and ("granja" in low or "farm" in low or "hen" in low or "rooster" in low or "chick" in low or "duck" in low or "pig" in low or "cow" in low or "sheep" in low or "horse" in low or "shelter" in low or "trough" in low or "fence" in low or "gate" in low or "bench" in low):
			var p := _xf(base, c).origin
			var extra := ""
			if c is MeshInstance3D:
				var box: AABB = _xf(base, c) * (c as MeshInstance3D).get_aabb()
				extra = " box " + str(box)
			print("  ", t, " @ ", p, extra)
	# Everything in the base town standing on the farm lawn (x 42..90, z 73..109).
	for n in base.find_children("*", "Node3D", true, false):
		var p := _xf(base, n).origin
		if p.x > 41 and p.x < 91 and p.z > 72 and p.z < 110 and n.get_parent() == zoo or (p.x > 41 and p.x < 91 and p.z > 72 and p.z < 110 and n.get_parent().get_parent() == base):
			print("  ON FARM ", base.get_path_to(n), " @ ", p)
	var barn: Node = load("res://scenes/town/barn.scn").instantiate()
	for c in barn.get_children():
		print("barn part ", c.name, " xf ", (c as Node3D).transform if c is Node3D else "")
		for d in c.get_children():
			if d is Node3D:
				for e in d.get_children():
					if e is Node3D:
						print("   ", d.name, "/", e.name, " world ", _xf(barn, e).origin)
						if e.name == "Barn interior":
							for f in e.get_children():
								if f is Node3D:
									print("      INT ", f.name, " ", _xf(barn, f).origin, " meta ", f.get_meta("word_key", ""))
	quit()
