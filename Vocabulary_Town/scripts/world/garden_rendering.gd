extends RefCounted
## Runtime-only batches keep the authored scene editable and collisions/word roots intact.
func build(town: Node3D) -> void:
    var garden := town.get_node_or_null("PublicGarden")
    if garden == null or garden.has_node("RenderBatches"): return
    var container := Node3D.new()
    container.name = "RenderBatches"
    garden.add_child(container)
    var groups := {}
    var cube := BoxMesh.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 16
    sphere.rings = 8
    var merged := 0
    for node in garden.find_children("*", "MeshInstance3D", true, false):
        if not node.is_visible_in_tree() or node.mesh == null: continue
        # Night lamp globes (day_night.gd) keep their glow material; render_culling batches them.
        if node.has_meta("night_glow"): continue
        var mesh: Mesh = node.mesh
        if not (mesh is BoxMesh or mesh is SphereMesh): continue
        if not node.material_override is StandardMaterial3D: continue
        var material: StandardMaterial3D = node.material_override
        var pose: Transform3D = garden.global_transform.affine_inverse() * node.global_transform
        var dimensions: Vector3 = mesh.size if mesh is BoxMesh else Vector3(mesh.radius, mesh.height * 0.5, mesh.radius)
        pose.basis = pose.basis.scaled_local(dimensions)
        var cell := Vector2i(floori(pose.origin.x / 24.0), floori(pose.origin.z / 24.0))
        var key := str(cell) + material.albedo_color.to_html() + ("box" if mesh is BoxMesh else "sphere")
        if not groups.has(key):
            groups[key] = {"mesh":cube if mesh is BoxMesh else sphere,"material":material,"poses":[]}
        groups[key].poses.append(pose)
        # Keep source meshes for map rebuilds/editor inspection, but remove their draw work.
        node.hide()
        node.set_meta("render_batched", true)
        merged += 1
    for key in groups:
        var entry: Dictionary = groups[key]
        var batch := MultiMeshInstance3D.new()
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.mesh = entry.mesh
        instances.instance_count = entry.poses.size()
        for i in range(entry.poses.size()): instances.set_instance_transform(i,entry.poses[i])
        batch.multimesh = instances
        batch.material_override = entry.material
        container.add_child(batch)
    var water := garden.get_node_or_null("Public Garden lagoon")
    if water:
        # The map uses a flat fallback color when this runtime shader is active.
        var material := ShaderMaterial.new()
        material.shader = preload("res://shaders/garden_water.gdshader")
        water.set_surface_override_material(0,material)
        water.material_override = null
        water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    garden.set_meta("batched_mesh_count",merged)
    garden.set_meta("render_batch_count",groups.size())
    print("Garden rendering: ",merged," meshes in ",groups.size()," spatial batches")
