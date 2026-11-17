extends RefCounted
## Shared last step of the clay rig build tools (tools/build_<prefab>_clay_rig.gd; cow, zebra,
## deer and rhino, 16 Nov 2026): builds the rig from a display scene and a spec with
## scripts/characters/clay_rig.gd, adds a ClayAnimator with the species' settings, and saves the
## scene with its meshes and skin as separate files, the way tools/build_pig_clay_rig.gd does.

const ClayRig := preload("res://scripts/characters/clay_rig.gd")
const ClayAnimator := preload("res://scripts/characters/clay_animator.gd")


## Builds and saves scenes/animals/<prefab>_clay_rigged.scn (meshes in
## scenes/animals/clay_meshes/<prefab>_rig/). Returns the save result; prints the rig stats.
static func bake(prefab: String, root_name: String, display: Node3D, spec: Dictionary, settings: Dictionary, tool: String) -> Error:
	var started := Time.get_ticks_msec()
	var rig := ClayRig.build(display, spec)
	rig.name = root_name
	rig.set_meta("source", "scenes/animals/%s_clay.tscn, rigged by %s (16 Nov 2026)" % [prefab, tool])
	# The on-screen box of clay_animator.gd: the display's own bounds with room for the swing.
	rig.set_meta("anim_aabb", _bounds(display).grow(0.15))
	var animator := Node.new()
	animator.name = "ClayAnimator"
	animator.set_script(ClayAnimator)
	for key in settings:
		animator.set(key, settings[key])
	rig.add_child(animator)
	animator.owner = rig
	var stats = rig.get_meta("rig_stats")
	rig.remove_meta("rig_stats")
	var result := _save_parts(rig, "res://scenes/animals/clay_meshes/%s_rig/" % prefab)
	var scene := PackedScene.new()
	if result == OK:
		result = scene.pack(rig)
	var out := "res://scenes/animals/%s_clay_rigged.scn" % prefab
	if result == OK:
		result = ResourceSaver.save(scene, out, ResourceSaver.FLAG_COMPRESS)
	var triangles := 0
	for part in stats:
		triangles += int(stats[part].triangles)
	print("%s CLAY RIG: %d skinned triangles %s, %d ms, save %s" % [prefab.to_upper(), triangles, JSON.stringify(stats), Time.get_ticks_msec() - started, error_string(result)])
	rig.free()
	return result


## Union of the display's mesh bounds (model space).
static func _bounds(display: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in display.find_children("*", "MeshInstance3D", true, false):
		var b := mi.transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Writes each mesh and skin of the rig to `folder`<node>.res (zstd-compressed, vertex data
## unchanged) and points the nodes at those files, so the zoo's base.scn names them instead of
## copying them (see build_pig_clay_rig.gd).
static func _save_parts(rig: Node3D, folder: String) -> Error:
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


## An eye entry for clay_rig.gd's spec: a right-handed frame with y up the eye (the axis
## plush_life.gd squashes) and z out of the face, from model-space normal and up directions.
static func eye(name: String, origin: Vector3, normal: Vector3, up: Vector3) -> Dictionary:
	var z := normal.normalized()
	var x := up.normalized().cross(z).normalized()
	return {"name": name, "origin": origin, "basis": Basis(x, z.cross(x), z)}
