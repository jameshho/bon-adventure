extends SceneTree
## Measures the player pig (BonBon) in the running game: the visible mesh's world bounds, in
## world metres and in warehouse hall units (town scale 1.3). Warehouse goods resize, 8 Nov 2026.
## HOME=<scratch>/home VT_FOCUS=all godot --headless --path . --script res://docs/evidence/warehouse-20261108/measure_pig.gd
func _initialize(): run.call_deferred()

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 3:
		await physics_frame
	var visual: Node3D = game.player.get_node("Visual")
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree() or mesh.mesh == null:
			continue
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var s: float = game.apartment.global_basis.get_scale().x
	print("pig world size (m): ", box.size, "  hall units: ", box.size / s, "  town scale ", s)
	quit()
