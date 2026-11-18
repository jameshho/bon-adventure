extends SceneTree
## Lists the town's vehicles (name, scene, world position) near the supermarket's tutorial
## parking lot and every motorcycle anywhere (tutorial polish, 18 Nov 2026).
func _init() -> void:
	var base: Node3D = load("res://scenes/town/base.scn").instantiate()
	root.add_child(base)
	await process_frame
	var lot := Vector3(-166.0, 0, 160.0)
	for v in base.find_children("*", "", true, false):
		if not (v is Node3D) or v.scene_file_path == "" or not v.scene_file_path.contains("vehicles/"):
			continue
		var p: Vector3 = (v as Node3D).global_position
		var near := Vector2(p.x - lot.x, p.z - lot.z).length() < 45.0
		if near or v.scene_file_path.contains("motorcycle") or v.scene_file_path.contains("scooter") or v.scene_file_path.contains("truck"):
			print("VEH %s | %s | %s | yaw %.0f | near %s" % [base.get_path_to(v), v.scene_file_path.get_file(), p.snapped(Vector3.ONE * 0.1), rad_to_deg((v as Node3D).global_rotation.y), near])
	var town_to_world: Transform3D = base.global_transform
	print("BASE xform ", town_to_world)
	quit()
