extends SceneTree
## Shared steps of the clay rig build tools for the gorilla, kangaroo, duck and flamingo
## (16 Nov 2026; modelled on tools/build_pig_clay_rig.gd): instance the finished display, rig it
## with scripts/characters/clay_rig.gd, add a ClayAnimator with the species' settings, and save
## the scene with its meshes and skin as separate files (like the pig's _save_parts). A species
## tool extends this and sets DISPLAY, OUT, FOLDER, RIG_NAME and spec() / settings().
## The display scene and its mesher are only read.

const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")


## The species' clay_rig.gd spec (model space of the display).
func spec(_display: Node3D) -> Dictionary:
	return {}


## The species' ClayAnimator properties.
func settings() -> Dictionary:
	return {}


func display_path() -> String:
	return ""


func rig_name() -> String:
	return ""


## Eyes for clay_rig.gd's spec, found from the display's own eye mesh (the meshers place them
## with internal ray casts; this only reads the finished mesh): the mesh's vertices on each
## side of the middle (+X = the animal's right), each eye centred on its vertices, z out of the
## face (their mean normal, level), y up, x toward the outer corner.
static func eye_frames(display: Node3D, mesh_name := "Eyes") -> Array:
	var mesh := (display.get_node(mesh_name) as MeshInstance3D).mesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var out := []
	for side in [["LeftEye", -1.0], ["RightEye", 1.0]]:
		var sum := Vector3.ZERO
		var n_sum := Vector3.ZERO
		var count := 0
		for i in verts.size():
			if signf(verts[i].x) == side[1]:
				sum += verts[i]
				n_sum += norms[i]
				count += 1
		var z := n_sum.normalized()
		var y := (Vector3.UP - z * Vector3.UP.dot(z)).normalized()
		var x := y.cross(z).normalized()
		out.append({"name": side[0], "origin": sum / maxi(count, 1), "basis": Basis(x, y, z)})
	return out


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var display: Node3D = load(display_path()).instantiate()
	var rig := ClayRig.build(display, spec(display))
	rig.name = rig_name()
	rig.set_meta("source", "%s, rigged by %s (16 Nov 2026)" % [display_path().trim_prefix("res://"), (get_script() as Script).resource_path.trim_prefix("res://")])
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	var s := settings()
	for key: String in s:
		if key == "anim_aabb":
			rig.set_meta("anim_aabb", s[key])
		else:
			animator.set(key, s[key])
	rig.add_child(animator)
	animator.owner = rig
	var stats = rig.get_meta("rig_stats")
	rig.remove_meta("rig_stats")
	var out := "res://scenes/animals/%s_rigged.scn" % display_path().get_file().get_basename()
	var result := _save_parts(rig, "res://scenes/animals/clay_meshes/%s_rig/" % display_path().get_file().get_basename().trim_suffix("_clay"))
	var scene := PackedScene.new()
	if result == OK:
		result = scene.pack(rig)
	if result == OK:
		result = ResourceSaver.save(scene, out, ResourceSaver.FLAG_COMPRESS)
	var tris := 0
	for mi: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		tris += _triangles(mi.mesh)
	var shown := 0
	for mi: MeshInstance3D in display.find_children("*", "MeshInstance3D", true, false):
		shown += _triangles(mi.mesh)
	print("CLAY RIG %s: %s, triangles %d (display %d), %d ms, save %s" % [rig.name, JSON.stringify(stats), tris, shown, Time.get_ticks_msec() - started, error_string(result)])
	rig.free()
	display.free()
	quit(result)


static func _triangles(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		n += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return n


## Writes each mesh and skin of the rig to `folder`/<node>.res (zstd-compressed, vertex data
## unchanged) and points the nodes at those files (as tools/build_pig_clay_rig.gd does).
func _save_parts(rig: Node3D, folder: String) -> Error:
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
