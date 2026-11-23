extends SceneTree
## Shops polish checks (23 Nov 2026): electronics small products 20% bigger and the small appliances
## as words (step `bigger_products`), the café's table meals redrawn (bakery step `table_meals`).
## Run with the README's isolated HOME and VT_FOCUS=all (or a list with electronics and bakery):
##   godot --headless --path . --fixed-fps 60 --script res://docs/evidence/shops-polish-20261123/verify.gd
## The store's full room checks stay in docs/evidence/electronics-makeover-20261118/verify.gd.
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const Products := preload("res://scripts/buildings/electronics_products.gd")
const Makeover := preload("res://scripts/buildings/electronics_makeover.gd")
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER
var failures := 0
var checks := 0
var game

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

## AABB of every mesh under `node`, in `frame`'s local space.
func bounds(node: Node3D, frame: Node3D) -> AABB:
	var lo := Vector3.ONE * 1e9
	var hi := -lo
	var inv := frame.global_transform.affine_inverse()
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (m as MeshInstance3D).get_aabb()
		for i in 8:
			var q: Vector3 = inv * ((m as MeshInstance3D).global_transform * a.get_endpoint(i))
			lo = lo.min(q)
			hi = hi.max(q)
	return AABB(lo, hi - lo)

func pick_centre(node: Node3D) -> Vector3:
	for area in node.find_children("*", "Area3D", true, false):
		for holder in area.get_children():
			if holder is CollisionShape3D:
				return holder.global_position
	return Vector3.INF

## A pointer ray from `eye` (global) to the root's pick centre resolves to the root.
func picked(node: Node3D, eye: Vector3) -> bool:
	var target := pick_centre(node)
	if target == Vector3.INF:
		return false
	var ray := PhysicsRayQueryParameters3D.create(eye, target + (target - eye).normalized() * .05)
	ray.collide_with_areas = true
	ray.collision_mask = 0xFFFFFFFF & ~FIGURE_LAYER  # as the pointer (interaction_controller.gd)
	ray.exclude = [game.player.get_rid()]
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and Interaction.vocabulary_target(hit.collider, game.apartment) == node

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var vocabulary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))["words"]
	var town: Node3D = game.apartment
	electronics(town, vocabulary)
	cafe(town, vocabulary)
	print("shops polish checks: ", checks, " failures: ", failures)
	quit(1 if failures > 0 else 0)

func electronics(town: Node3D, vocabulary: Dictionary) -> void:
	var store: Node3D = town.get_node("Buildings/ElectronicsStore")
	var displays: Node3D = store.get_node("LearningDisplays")
	var interior: Node3D = store.get_node("Interior")
	var site: Node3D = town.get_node("RelocatedSites/Electronics")
	var kit = Products.new()
	# Grown roots: 1.2 x the model the makeover gave them, and clear of each other.
	var boxes := {}
	for spec in Makeover.ROOTS:
		if not str(spec[1]) in Makeover.BIGGER:
			continue
		var parent: Node3D = {"L": displays, "I": interior, "S": site}[spec[0]]
		var node := parent.get_node_or_null(spec[1]) as Node3D
		check(node != null and str(node.get_meta("word_key", "")) == spec[2], "grown root kept: " + spec[1])
		if node == null:
			continue
		var b := bounds(node, store)
		boxes[spec[1]] = b
		var want: Vector3 = kit.model_of(spec[2]).get_aabb().size * Makeover.SMALL
		var model := node.get_node_or_null("Model") as MeshInstance3D
		var got: Vector3 = model.mesh.get_aabb().size if model else Vector3.ZERO
		check(got.is_equal_approx(want), "%s is 20%% bigger (%s vs %s)" % [spec[1], got, want / Makeover.SMALL])
		var c := pick_centre(node)
		check(c != Vector3.INF and b.grow(.05).has_point(store.to_local(c)), "pick area on the model: " + spec[1])
	# The computer's box spans the desk under its monitor, where the keyboard and mouse sit by design
	# (the monitor stands behind them; see after-electronics-computers.png): that pair is not boxed.
	var by_design := [["Computer", "Keyboard"], ["Computer", "Mouse"]]
	var names: Array = boxes.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			if [names[i], names[j]] in by_design:
				continue
			var a: AABB = boxes[names[i]]
			var o: AABB = boxes[names[j]]
			check(not a.grow(-.005).intersects(o.grow(-.005)), "no clipping: %s / %s" % [names[i], names[j]])
	# Table items stay on the island tops and off the risers (islands: centre x, centre z, length, side).
	var on_island := {"Computer": 0, "Keyboard": 0, "Mouse": 0, "Laptop": 0, "Smartphone": 1, "Tablet": 1,
		"Smartwatch": 1, "Camera": 2, "Headphones": 3, "Speaker": 3}
	for title in on_island:
		var spec: Array = Makeover.ISLANDS[on_island[title]]
		var b: AABB = boxes[title]
		var cx: float = spec[1]
		var cz: float = spec[2]
		var length: float = spec[3]
		var side: int = spec[4]
		check(b.position.x > cx - .58 and b.end.x < cx + .58 and b.position.z > cz - length * .5 - .03 and b.end.z < cz + length * .5 + .03,
			"on its island top: %s %s" % [title, b])
		var riser := AABB(Vector3(cx + side * .33 - .18, .99, cz - (length - .3) * .5), Vector3(.36, .25, length - .3))
		check(not b.grow(-.005).intersects(riser), "clear of the riser: " + title)
		# The camera's lens hangs over its base by .024 (.02 before the growth); everything else sits flat.
		check(absf(b.position.y - Makeover.TOP) < .03, "standing on the table (%.3f): %s" % [b.position.y, title])
	# The small appliances: twelve word roots, three of each word, on their shelves, pickable.
	var counts := {}
	var levels := [[.195, .68], [.72, 1.28], [1.32, 1.94]]
	for node in displays.get_children():
		var word := str(node.get_meta("word_key", ""))
		if not word in ["toaster", "kettle", "blender", "rice cooker"]:
			continue
		counts[word] = counts.get(word, 0) + 1
		check(vocabulary.has(word) and vocabulary[word]["category"] == "Electronics & Appliances", "word listed: " + word)
		check(node.get_meta("learning_object", false), "learning object: " + node.name)
		var b := bounds(node, store)
		var level := -1
		for k in 3:
			if absf(b.position.y - levels[k][0]) < .01:
				level = k
		check(level >= 0, "%s stands on a shelf (%.3f)" % [node.name, b.position.y])
		if level >= 0:
			check(b.end.y < levels[level][1], "%s fits under the shelf above (%.3f < %.2f)" % [node.name, b.end.y, levels[level][1]])
		check(b.position.x > 5.12 and b.end.x < 5.62 and b.position.z > -1.47 and b.end.z < 1.47, "%s inside the unit %s" % [node.name, b])
		var eye: Vector3 = store.to_global(Vector3(4.1, 1.9, b.get_center().z))
		check(picked(node, eye), "pickable from the aisle: " + node.name)
	check(counts == {"toaster": 3, "kettle": 3, "blender": 3, "rice cooker": 3}, "twelve appliances, three of each: %s" % counts)
	var blocker := interior.get_node_or_null("Small appliances unit body") as StaticBody3D
	check(blocker != null and blocker.collision_layer == FIGURE_LAYER and blocker.collision_mask == 0, "unit blocker stops the player, not the pointer")
	for title in ["Computers island", "Phones island", "Cameras island", "Audio island", "Left wall displays"]:
		check(interior.find_children(title, "MeshInstance3D", false, false).size() == 1, "one mesh: " + title)
	for title in ["Computers island body", "Microwave counter body", "Appliance plinth body"]:
		check(interior.find_children(title, "StaticBody3D", false, false).size() == 1, "one blocker: " + title)

func cafe(town: Node3D, vocabulary: Dictionary) -> void:
	var cafe_node: Node3D = town.get_node("Buildings/BakeryCafe")
	var interior: Node3D = cafe_node.get_node("Interior")
	var tables := []
	for node in interior.get_children():
		if str(node.get_meta("word_key", "")) == "table":
			tables.append(node.position)
	check(tables.size() == 5, "five café tables")
	for title in ["Everyday_Breakfast", "Everyday_Lunch", "Everyday_Dinner", "Everyday_Food", "Everyday_Coffee"]:
		var node := cafe_node.get_node_or_null(title) as Node3D
		var word: String = title.trim_prefix("Everyday_").to_lower()
		check(node != null and str(node.get_meta("word_key", "")) == word and vocabulary.has(word), "meal kept: " + title)
		if node == null:
			continue
		check(node.scene_file_path == "" and node.get_node_or_null("Model") is MeshInstance3D, "clay meal model: " + title)
		var b := bounds(node, interior)
		var table = null
		for t in tables:
			if absf(t.x - b.get_center().x) < .6 and absf(t.z - b.get_center().z) < .6:
				table = t
		check(table != null, "on a table: " + title)
		if table == null:
			continue
		check(absf(b.position.y - .815) < .01, "resting on the table top (%.3f): %s" % [b.position.y, title])
		check(b.position.x > table.x - .525 and b.end.x < table.x + .525 and b.position.z > table.z - .525 and b.end.z < table.z + .525, "within the table top: %s %s" % [title, b])
		var area_box := AABB()
		for area in node.find_children("*", "Area3D", true, false):
			var holder: CollisionShape3D = area.get_child(0)
			area_box = AABB(holder.position - holder.shape.size * .5, holder.shape.size)
			check(area.collision_layer == 2, "pick area on layer 2: " + title)
		check(area_box.size.x < .8 and area_box.size.z < .8 and area_box.size.y < .5, "pick area fitted to the meal: %s %s" % [title, area_box.size])
		# The diner's side (-X, where the chair is) and the aisle side both see and pick it.
		var aisle := 1.0 if table.x < 0 else -1.0
		var eye_side := cafe_node.to_global(Vector3(table.x + aisle * 1.3, 1.9, table.z))
		check(picked(node, eye_side), "pickable from the aisle: " + title)
