extends SceneTree
## Measures the shared plush rig (docs/guides/COMPONENTS.md): for every plush scene, the bounds of the
## body parts in the character's own frame, and where each part node's origin (its pivot) sits.
## Headless: godot --headless --path . --script res://docs/evidence/plush-rig-20261113/measure.gd
## Writes docs/evidence/plush-rig-20261113/measure.json and prints a table.
const SCENES := ["BonBon", "pig_plush", "bear_plush", "cat_plush", "beagle_plush", "golden_plush",
	"samoyed_plush", "sheep_plush", "lion_plush", "crocodile_plush"]
const PARTS := ["Torso", "Head", "Head/LeftEye", "Head/RightEye", "Arm", "Arm_2", "Foot", "Foot_2"]

func _initialize() -> void:
	run.call_deferred()

func bounds(root: Node3D, part: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var inverse := root.global_transform.affine_inverse()
	var nodes: Array = [part] + part.find_children("*", "MeshInstance3D", true, false)
	for node in nodes:
		if not node is MeshInstance3D or node.mesh == null:
			continue
		# Ears, manes and spikes are not part of the head ball.
		var path := str(part.get_path_to(node))
		if "Ear" in path or "Spikes" in path or "Whiskers" in path:
			continue
		var b: AABB = inverse * node.global_transform * node.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func r(v: Vector3) -> Array:
	return [snappedf(v.x, .01), snappedf(v.y, .01), snappedf(v.z, .01)]

func run() -> void:
	var holder := Node3D.new()
	get_root().add_child(holder)
	var out := {}
	for title in SCENES:
		var plush: Node3D = load("res://scenes/characters/%s.tscn" % title).instantiate()
		holder.add_child(plush)
		for i in 2: await process_frame
		var entry := {}
		var whole := AABB()
		var first := true
		for mesh in plush.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null: continue
			var b: AABB = plush.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			whole = b if first else whole.merge(b)
			first = false
		entry["height"] = snappedf(whole.end.y, .01)
		for path in PARTS:
			var part := plush.get_node_or_null(path) as Node3D
			if part == null:
				continue
			var box := bounds(plush, part)
			var origin: Vector3 = plush.global_transform.affine_inverse() * part.global_position
			entry[path] = {"pivot": r(origin), "center": r(box.get_center()), "size": r(box.size)}
		out[title] = entry
		var head: Dictionary = entry.get("Head", {})
		var arm: Dictionary = entry.get("Arm", {})
		var eye: Dictionary = entry.get("Head/LeftEye", {})
		print("%-16s h %.2f | head pivot %s centre %s size %s | arm pivot %s centre %s size %s | eye centre %s size %s" % [
			title, entry.height, head.get("pivot"), head.get("center"), head.get("size"),
			arm.get("pivot"), arm.get("center"), arm.get("size"), eye.get("center"), eye.get("size")])
		plush.queue_free()
	var file := FileAccess.open("res://docs/evidence/plush-rig-20261113/measure.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "  "))
	file.close()
	quit()
