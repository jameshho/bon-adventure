extends SceneTree
## Rewrites the visuals of furniture prefabs in scenes/props/vocabulary/ with the product-art
## models of scripts/buildings/furniture_props.gd (9 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md
## "Interiors polish"). Each prefab keeps its root (name, word_key, learning_object) and its
## Interaction area and Footprint body; the old primitive meshes are replaced by the model's
## meshes and the Interaction area is fitted to them. Pick areas listed in SHAPES leave room
## above the seat or mattress, and those prefabs' footprints stop the player only
## (FIGURE_LAYER), so cushions, pillows and blankets placed on them can be clicked.
## Users (9 Nov 2026): the furniture store; the hospital also shows sofa, armchair, coffee_table.
##   godot --headless --path . --script res://tools/build_furniture_props.gd
const Props := preload("res://scripts/buildings/furniture_props.gd")
const Art := preload("res://scripts/buildings/supermarket_products.gd")
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER
## Pick boxes (position, size) for prefabs that hold other words on them.
const SHAPES := {
	"sofa": [AABB(Vector3(-1.27, 0, -.5), Vector3(2.54, .6, 1.0)), AABB(Vector3(-1.27, .6, .27), Vector3(2.54, .55, .23)),
		AABB(Vector3(-1.27, .6, -.47), Vector3(.24, .2, .94)), AABB(Vector3(1.03, .6, -.47), Vector3(.24, .2, .94))],
	"armchair": [AABB(Vector3(-.51, 0, -.43), Vector3(1.02, .6, .86)), AABB(Vector3(-.51, .6, .24), Vector3(1.02, .62, .22)),
		AABB(Vector3(-.51, .6, -.43), Vector3(.2, .18, .86)), AABB(Vector3(.31, .6, -.43), Vector3(.2, .18, .86))],
	"bed": [AABB(Vector3(-.92, 0, -1.36), Vector3(1.84, .66, 2.62)), AABB(Vector3(-.98, .66, 1.24), Vector3(1.96, .84, .14))],
}

func _initialize() -> void:
	var art = Art.new()
	var props = Props.new()
	var failures := 0
	for prefab in Props.PARTS:
		var path := "res://scenes/props/vocabulary/%s.tscn" % prefab
		var root: Node3D = load(path).instantiate()
		for child in root.get_children():
			if child is MeshInstance3D:
				root.remove_child(child)
				child.free()
		var bounds := AABB()
		var first := true
		var k := 0
		for title in Props.PARTS[prefab]:
			art.begin()
			props.call(Props.PARTS[prefab][title], art)
			var mesh: ArrayMesh = art.finish("%s %s" % [prefab.capitalize(), title])
			var view := MeshInstance3D.new()
			view.name = title
			view.mesh = mesh
			root.add_child(view)
			root.move_child(view, k)
			view.owner = root
			k += 1
			bounds = mesh.get_aabb() if first else bounds.merge(mesh.get_aabb())
			first = false
		var area := root.get_node("Interaction") as Area3D
		for old in area.get_children():
			area.remove_child(old)
			old.free()
		var boxes: Array = SHAPES.get(prefab, [bounds.grow(.02)])
		var n := 0
		for box in boxes:
			var shape := CollisionShape3D.new()
			shape.name = "Shape" if n == 0 else "Shape%d" % (n + 1)
			var cube := BoxShape3D.new()
			cube.size = box.size
			shape.shape = cube
			shape.position = box.get_center()
			area.add_child(shape)
			shape.owner = root
			n += 1
		var footprint := root.get_node_or_null("Footprint") as StaticBody3D
		if footprint != null and SHAPES.has(prefab):
			footprint.collision_layer = FIGURE_LAYER
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("PROPS %s: %s, model %s, %d pick boxes" % [prefab, "saved" if err == OK else "ERROR %d" % err, bounds, n])
		if err != OK:
			failures += 1
		root.free()
	print("PROPS done, %d failures" % failures)
	quit(1 if failures else 0)
