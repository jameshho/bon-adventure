extends SceneTree
## Rewrites the visuals of sports prefabs in scenes/props/vocabulary/ with the product-art
## models of scripts/buildings/sports_props.gd (9 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md
## "Interiors polish"). Each prefab keeps its root (name, word_key, learning_object), its
## Interaction area and Footprint body; the old primitive meshes are replaced by one "Model"
## mesh and both shapes are fitted to it. Instances keep their transforms, so the hospital's
## soccer ball (scale 0.35) and the clothing store's sneakers keep their place and size.
##   godot --headless --path . --script res://tools/build_sports_props.gd
const Props := preload("res://scripts/buildings/sports_props.gd")
const Art := preload("res://scripts/buildings/supermarket_products.gd")
## prefab -> [model function, word_key to set (or "" to keep the prefab's)]
const PREFABS := {
	"soccer_ball": ["soccer_ball", ""],
	"basketball": ["basketball", ""],
	"volleyball": ["volleyball", ""],
	# Its own word was retired on 28 Oct 2026; a tennis ball teaches "ball" (la pelota).
	"tennis_ball": ["tennis_ball", "ball"],
	"dumbbell": ["dumbbell", ""],
	"helmet": ["helmet", ""],
	"sneakers": ["sneakers", ""],
}

func _initialize() -> void:
	var art = Art.new()
	var failures := 0
	for prefab in PREFABS:
		var path := "res://scenes/props/vocabulary/%s.tscn" % prefab
		var root: Node3D = load(path).instantiate()
		for child in root.get_children():
			if child is MeshInstance3D:
				root.remove_child(child)
				child.free()
		art.begin()
		Props.new().call(PREFABS[prefab][0], art)
		var mesh: ArrayMesh = art.finish(prefab.capitalize())
		var model := MeshInstance3D.new()
		model.name = "Model"
		model.mesh = mesh
		root.add_child(model)
		root.move_child(model, 0)
		model.owner = root
		if PREFABS[prefab][1] != "":
			root.set_meta("word_key", PREFABS[prefab][1])
			root.set_meta("learning_object", true)
			# The retired word's pick area had been switched off (layer 0); pickable again.
			(root.get_node("Interaction") as Area3D).collision_layer = 2
		var box := mesh.get_aabb()
		for body_name in ["Interaction", "Footprint"]:
			var body := root.get_node_or_null(body_name)
			if body == null:
				continue
			var shape := body.get_node("Shape") as CollisionShape3D
			var size := box.size + Vector3.ONE * .04 if body_name == "Interaction" else box.size * .9
			var fitted := BoxShape3D.new()
			fitted.size = size
			shape.shape = fitted
			shape.position = box.get_center()
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("PROPS %s: %s, model %s" % [prefab, "saved" if err == OK else "ERROR %d" % err, box])
		if err != OK:
			failures += 1
		root.free()
	print("PROPS done, %d failures" % failures)
	quit(1 if failures else 0)
