extends SceneTree
## Size table for the product rework (18 Nov 2026): each kind's longest displayed side (model AABB
## x goods_scale, largest over its variants) for the current library and, when given, an older copy
## of supermarket_products.gd; then every product group's pick box in the baked market.
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/supermarket-products-20261118/measure.gd [-- <old products .gd>]
## Then restocks the loaded market with restock_all() and checks every unit lies in its pick box.
## Prints only; writes nothing.
const Products = preload("res://scripts/buildings/supermarket_products.gd")
const INTERIOR := "RelocatedSites/Supermarket/MarketInterior"

func _initialize() -> void:
	var now = Products.new()
	var old = null
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var script := GDScript.new()
		script.source_code = FileAccess.get_file_as_string(args[0])
		script.reload()
		old = script.new()
	print("SIZES kind | before longest (W x D x H) | after longest (W x D x H)")
	var kinds: Array = Products.FOOT.keys()
	var small := []
	for kind in kinds:
		var line := "SIZE %-13s" % kind
		for lib in [old, now]:
			if lib == null:
				line += " | -"
				continue
			var size := _displayed(lib, kind)
			line += " | %.3f (%.2f x %.2f x %.2f)" % [maxf(size.x, maxf(size.y, size.z)), size.x, size.z, size.y]
		var after := _displayed(now, kind)
		if maxf(after.x, maxf(after.y, after.z)) < .285:
			small.append(kind)
		var foot: Vector3 = Products.FOOT[kind]
		var box := Vector3.ZERO
		for v in now.variants(kind):
			var size: Vector3 = now.model(kind, v).get_aabb().size
			box = Vector3(maxf(box.x, size.x), maxf(box.y, size.y), maxf(box.z, size.z))
		if box.x > foot.x * 1.08 or box.z > foot.y * 1.08 or box.y > foot.z * 1.12:
			line += "   [model %.3f x %.3f x %.3f exceeds FOOT %s]" % [box.x, box.z, box.y, foot]
		print(line)
	print("SIZES below .285 after: ", small)
	var packed := load("res://scenes/town/supermarket.scn") as PackedScene
	if packed == null:
		quit()
		return
	var town := packed.instantiate()
	var interior := town.get_node_or_null(INTERIOR)
	if interior == null:
		for node in town.find_children("MarketInterior", "", true, false):
			interior = node
	if interior != null:
		for root in interior.get_children():
			if not root.has_meta("word_key") or not Products.FOOT.has(str(root.get_meta("word_key"))):
				continue
			for area in root.get_children():
				if area is Area3D:
					var box: Vector3 = ((area.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
					var pad := Vector2(area.position.x, area.position.z).length() * 2.0
					var units := root.get_children().filter(func(c): return c is MeshInstance3D).size()
					print("GROUP %-24s %-13s w %.2f h %.2f d %.2f pad %.2f units %d" % [root.name, root.get_meta("word_key"), box.x - .02, box.y - .02, box.z - .02 - pad, pad, units])
		# Restock the whole market with the current library (nothing is saved) and check that
		# every unit lies inside its group's pick box.
		var before := _vertices(interior)
		now.restock_all(interior)
		var after := _vertices(interior)
		print("VERTICES product units (drawn, all groups): before %d after %d; distinct meshes before %d after %d" % [before[0], after[0], before[1], after[1]])
		var outside := 0
		for root in interior.get_children():
			if not root.has_meta("word_key") or not Products.FOOT.has(str(root.get_meta("word_key"))):
				continue
			if str(root.name).begins_with("Candy rack") or str(root.name).begins_with("Featured"):
				continue
			var area: Area3D
			for child in root.get_children():
				if child is Area3D:
					area = child
			if area == null:
				continue
			var shape := area.get_child(0) as CollisionShape3D
			var pick := AABB(-(shape.shape as BoxShape3D).size * .5, (shape.shape as BoxShape3D).size).grow(.03)
			var to_pick := (area.transform * shape.transform).affine_inverse()
			var units := 0
			for unit in root.get_children():
				if unit is MeshInstance3D:
					units += 1
					var box: AABB = (to_pick * unit.transform) * (unit as MeshInstance3D).mesh.get_aabb()
					if not pick.encloses(box):
						outside += 1
						if outside <= 12:
							print("OUTSIDE %s %s unit %s pick %s" % [root.name, root.get_meta("word_key"), box, pick])
			print("AFTER %-24s %-13s units %d pick h %.2f" % [root.name, root.get_meta("word_key"), units, (shape.shape as BoxShape3D).size.y - .02])
		print("AFTER units outside their pick box: ", outside)
	town.free()
	quit()

## Displayed size (x across, y up, z deep) of the biggest variant at goods_scale.
func _displayed(lib, kind: String) -> Vector3:
	var best := Vector3.ZERO
	for v in lib.variants(kind):
		var size: Vector3 = lib.model(kind, v).get_aabb().size * lib.goods_scale(kind)
		if maxf(size.x, maxf(size.y, size.z)) > maxf(best.x, maxf(best.y, best.z)):
			best = size
	return best

## Drawn vertices of all product units in the market's product groups, and distinct meshes.
func _vertices(interior: Node) -> Array:
	var total := 0
	var meshes := {}
	var kinds := {}
	for root in interior.get_children():
		if not root.has_meta("word_key") or not Products.FOOT.has(str(root.get_meta("word_key"))):
			continue
		if str(root.name).begins_with("Candy rack") or str(root.name).begins_with("Featured"):
			continue
		for unit in root.get_children():
			if unit is MeshInstance3D and (unit as MeshInstance3D).mesh != null:
				var mesh := (unit as MeshInstance3D).mesh
				meshes[mesh] = true
				for surface in mesh.get_surface_count():
					var count := (mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					total += count
					var kind := str(root.get_meta("word_key"))
					kinds[kind] = int(kinds.get(kind, 0)) + count
	var heavy := kinds.keys()
	heavy.sort_custom(func(a, b): return kinds[a] > kinds[b])
	print("VERTICES heaviest kinds: ", heavy.slice(0, 12).map(func(k): return "%s %d" % [k, kinds[k]]))
	return [total, meshes.size()]
