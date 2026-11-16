extends RefCounted
## Shared save step of the clay animal builds (tools/build_<animal>_clay.gd; 16 Nov 2026,
## docs/guides/ANIMAL_SYSTEM.md#clay-file-sizes-16-nov-2026). The prefab scene keeps only the nodes;
## each part's mesh is its own zstd-compressed binary file,
## scenes/animals/clay_meshes/<animal>/<part>.res, which the prefab and the town's base.scn name:
##   - vertex attributes compressed (Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES: 16-bit positions in the
##     part's box, packed normals); vertex colours stay exact 8-bit RGBA; triangles as built.
## No generated LODs: ImporterMesh.generate_lods ignores vertex colours, and its levels moved the
## zebra's stripe edges and left pinhole specks even in close-ups (docs/evidence/clay-sizes-20261116/).
## Usage, after model := script.new().build_display():
##   ClaySave.save(model, "zebra", "res://scenes/animals/zebra_clay.tscn")
const MESHES := "res://scenes/animals/clay_meshes/"

## Writes the part meshes and the scene; returns OK or the first error. Prints one summary line.
static func save(model: Node3D, animal: String, scene_path: String) -> Error:
	var folder := MESHES + animal + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	# Parts of an earlier build that this one no longer has would be left behind: clear them.
	for old in DirAccess.get_files_at(folder):
		if old.ends_with(".res"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(folder + old))
	var tris := 0
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var mesh := light_mesh(mi.mesh)
		var path := folder + String(mi.name).to_snake_case().replace(" ", "_") + ".res"
		var result := ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
		if result != OK:
			return result
		mesh.take_over_path(path)
		mi.mesh = mesh
		for s in mesh.get_surface_count():
			tris += _index_len(mesh, s) / 3
	var scene := PackedScene.new()
	var packed := scene.pack(model)
	if packed != OK:
		return packed
	packed = ResourceSaver.save(scene, scene_path)
	print("CLAY SAVE %s: %d triangles, meshes in %s" % [animal, tris, folder])
	return packed

## The same surfaces with compressed vertex attributes. Materials live on the MeshInstance3D
## (material_override); any surface material is kept.
static func light_mesh(source: Mesh) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for s in source.get_surface_count():
		mesh.add_surface_from_arrays(source.surface_get_primitive_type(s), source.surface_get_arrays(s), [], {}, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		if source.surface_get_material(s) != null:
			mesh.surface_set_material(s, source.surface_get_material(s))
	return mesh

static func _index_len(mesh: Mesh, s: int) -> int:
	var n: int = mesh.surface_get_array_index_len(s)
	return n if n > 0 else mesh.surface_get_array_len(s)
