extends SceneTree
## Shared steps of the clay rig build tools for the bears, panda, red panda and golden retriever
## (16 Nov 2026; tools/build_black_bear_clay_rig.gd, build_panda_clay_rig.gd,
## build_red_panda_clay_rig.gd, build_golden_retriever_clay_rig.gd), modelled on
## tools/build_pig_clay_rig.gd: build each rig with scripts/characters/clay_rig.gd from its
## finished display scene, add a ClayAnimator with the species' settings, and save the scene
## with its meshes and skin in their own files (scenes/animals/clay_meshes/<prefab>_rig/), so a
## saved town names them instead of copying them. A subclass returns its rigs from rigs().
## The display scenes and their *_clay.gd meshers are only read.

const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")


## [{scene, out, folder, name, spec, animator: {property: value}}] (subclasses).
func rigs() -> Array:
	return []


func _initialize() -> void:
	var result := OK
	for r in rigs():
		result = build_one(r)
		if result != OK:
			break
	quit(result)


func build_one(r: Dictionary) -> Error:
	var started := Time.get_ticks_msec()
	var display: Node3D = load(r.scene).instantiate()
	var rig := ClayRig.build(display, r.spec)
	rig.name = r.name
	rig.set_meta("source", "%s, rigged by %s (16 Nov 2026)" % [String(r.scene).trim_prefix("res://"), String(get_script().resource_path).trim_prefix("res://")])
	# The animator's on-screen notifier: the display's own size, a little grown for the swing.
	var box := AABB()
	for mi: MeshInstance3D in display.find_children("*", "MeshInstance3D", true, false):
		box = mi.get_aabb() if box.size == Vector3.ZERO else box.merge(mi.get_aabb())
	rig.set_meta("anim_aabb", box.grow(box.size.y * 0.15))
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	for key in r.animator:
		animator.set(key, r.animator[key])
	rig.add_child(animator)
	animator.owner = rig
	var stats = rig.get_meta("rig_stats")
	rig.remove_meta("rig_stats")
	var tris := 0
	for mi: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		tris += _triangles(mi.mesh)
	var display_tris := 0
	for mi: MeshInstance3D in display.find_children("*", "MeshInstance3D", true, false):
		display_tris += _triangles(mi.mesh)
	var result := save_parts(rig, r.folder)
	var scene := PackedScene.new()
	if result == OK:
		result = scene.pack(rig)
	if result == OK:
		result = ResourceSaver.save(scene, r.out, ResourceSaver.FLAG_COMPRESS)
	print("CLAY RIG %s: %d triangles (display %d), parts %s, %d ms, save %s" % [r.name, tris, display_tris,
			JSON.stringify(stats), Time.get_ticks_msec() - started, error_string(result)])
	rig.free()
	display.free()
	return result


static func _triangles(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		n += (a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size()) / 3
	return n


## Writes each mesh and skin of the rig to <folder><node>.res (zstd-compressed, vertex data
## unchanged) and points the nodes at those files (as tools/build_pig_clay_rig.gd).
static func save_parts(rig: Node3D, folder: String) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for old in DirAccess.get_files_at(folder):
		if old.ends_with(".res"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(folder + old))
	for mi: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		var base := folder + String(mi.name).to_snake_case().replace(" ", "_")
		for pair in [["mesh", ""], ["skin", "_skin"]]:
			var res: Resource = mi.get(pair[0])
			if res == null:
				continue
			var path: String = base + pair[1] + ".res"
			var result := ResourceSaver.save(res, path, ResourceSaver.FLAG_COMPRESS)
			if result != OK:
				return result
			res.take_over_path(path)
	return OK


## An eye for clay_rig.gd's spec: centred at `origin` (model space) with z out of the face along
## `n` and y up the eye (the axis plush_life.gd squashes), right-handed.
static func eye(name: String, origin: Vector3, n: Vector3, up: Vector3) -> Dictionary:
	var z := n.normalized()
	var x := up.cross(z).normalized()
	return {"name": name, "origin": origin, "basis": Basis(x, z.cross(x), z)}


## A leg bone pivoting at `pivot`, its part of the body a chain of capsules through `joints`
## (model space) of radius `radius`.
static func leg(name: String, pivot: Vector3, joints: Array, radius: float) -> Dictionary:
	var shapes := []
	for i in joints.size() - 1:
		shapes.append([joints[i], joints[i + 1], radius])
	return {"name": name, "parent": "root", "pivot": pivot, "shapes": shapes}


## How far a leg leans forward at rest (degrees, + = the foot toward the head, -Z), from its
## pivot to its foot; the animator's leg_neutral_deg is minus this.
static func lean_deg(pivot: Vector3, foot: Vector3) -> float:
	return rad_to_deg(atan2(-(foot.z - pivot.z), pivot.y - foot.y))


## The point where a leg's joint chain (sheet px, y rising down the leg) passes height y.
static func chain_at(joints: Array, y: float) -> Vector2:
	for i in joints.size() - 1:
		var a: Vector2 = joints[i]
		var b: Vector2 = joints[i + 1]
		if y <= b.y or i == joints.size() - 2:
			return a.lerp(b, clampf((y - a.y) / (b.y - a.y), 0.0, 1.0))
	return joints[0]
