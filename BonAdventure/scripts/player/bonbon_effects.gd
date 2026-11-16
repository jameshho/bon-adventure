extends Node3D

# Bounded world-space ribbon and 40 lightweight particles. Original materials
# are never edited: the aura is an instance-local, removable overlay.
# No screen bloom or local light (user, 10 Nov 2026): they lit up the sky and
# surroundings; the glow, trail and sparks stay on BonBon.
@export var glow_color := Color("00BFFF")
@export var trail_lifetime := 0.24
@export var max_trail_points := 24
var enabled := false
var intensity := 0.0
var aura := ShaderMaterial.new()
var surfaces: Array[MeshInstance3D] = []
var original_overlays: Array[Material] = []
var trail: MeshInstance3D
var ribbon := ImmediateMesh.new()
var trail_material := StandardMaterial3D.new()
var particles: CPUParticles3D
var points: Array[Vector3] = []
var ages: Array[float] = []

## The meshes the hyper aura covers (again after the player's model changes: set_avatar()).
func collect_surfaces() -> void:
    surfaces.clear()
    original_overlays.clear()
    for node in get_parent().get_node("Visual/BonBon").find_children("*", "MeshInstance3D", true, false):
        surfaces.append(node)
        original_overlays.append(node.material_overlay)

func _ready() -> void:
    aura.shader = preload("res://scripts/player/shaders/hyper_aura.gdshader")
    aura.set_shader_parameter("glow_color", glow_color)
    collect_surfaces()
    trail = MeshInstance3D.new()
    trail.name = "NeonTrail"
    trail.top_level = true
    trail.mesh = ribbon
    trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(trail)
    trail.global_transform = Transform3D.IDENTITY
    trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    trail_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    trail_material.vertex_color_use_as_albedo = true
    trail_material.emission_enabled = true
    trail_material.emission = glow_color
    trail_material.emission_energy_multiplier = 2.5
    trail.material_override = trail_material
    particles = CPUParticles3D.new()
    particles.name = "BlueWhiteSparks"
    particles.position.y = 1.0
    particles.amount = 40
    particles.lifetime = 0.4
    particles.local_coords = false
    particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 0.5
    particles.gravity = Vector3(0, 0.6, 0)
    particles.direction = Vector3.UP
    particles.spread = 90
    particles.initial_velocity_min = 0.3
    particles.initial_velocity_max = 1.0
    particles.scale_amount_min = 0.025
    particles.scale_amount_max = 0.07
    var spark := SphereMesh.new()
    spark.radial_segments = 6
    spark.rings = 3
    spark.radius = 1.0
    spark.height = 2.0
    var spark_material := StandardMaterial3D.new()
    spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    spark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    spark_material.vertex_color_use_as_albedo = true
    spark_material.emission_enabled = true
    spark_material.emission = Color("b9f2ff")
    spark_material.emission_energy_multiplier = 2.0
    spark.material = spark_material
    particles.mesh = spark
    var gradient := Gradient.new()
    gradient.colors = PackedColorArray([Color("e2faff"), Color("00bfff"), Color(0, 0.75, 1, 0)])
    gradient.offsets = PackedFloat32Array([0, 0.35, 1])
    particles.color_ramp = gradient
    particles.emitting = false
    particles.visible = false
    add_child(particles)

func set_enabled(value: bool) -> void:
    enabled = value
    for i in surfaces.size():
        surfaces[i].material_overlay = aura if enabled else original_overlays[i]
    particles.visible = enabled
    if not enabled:
        intensity = 0.0
        particles.emitting = false
        clear_trail()
    else:
        particles.restart()
        particles.emitting = false

func clear_trail() -> void:
    points.clear()
    ages.clear()
    ribbon.clear_surfaces()

func update_motion(delta: float, speed_ratio: float) -> void:
    if not enabled:
        return
    intensity = lerpf(intensity, clampf(speed_ratio, 0.0, 1.0), 1.0 - exp(-10.0 * delta))
    aura.set_shader_parameter("strength", 0.35 + intensity * 0.65)
    particles.emitting = speed_ratio > 0.08
    particles.initial_velocity_max = 0.5 + intensity * 1.8
    for i in ages.size():
        ages[i] += delta
    while not ages.is_empty() and (ages[0] > trail_lifetime or points.size() >= max_trail_points):
        ages.pop_front()
        points.pop_front()
    var point := global_position + Vector3(0, 1.0, 0)
    if not points.is_empty() and point.distance_to(points[-1]) > 4.0:
        clear_trail()
    if speed_ratio > 0.08 and (points.is_empty() or point.distance_to(points[-1]) > 0.07):
        points.append(point)
        ages.append(0.0)
    ribbon.clear_surfaces()
    if points.size() < 2:
        return
    # Two crossed ribbons remain visible from both elevated and side views.
    ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1, points.size()):
        var tangent := (points[i] - points[i - 1]).normalized()
        var across := tangent.cross(Vector3.UP).normalized()
        if across.length_squared() < 0.01:
            across = Vector3.RIGHT
        var width := (0.08 + intensity * 0.20) * (1.0 - ages[i] / trail_lifetime)
        for axis in [across, Vector3.UP]:
            var offset: Vector3 = axis * width
            var tint := glow_color
            tint.a = (1.0 - ages[i] / trail_lifetime) * (0.4 + intensity * 0.6)
            ribbon.surface_set_color(tint)
            for vertex in [points[i-1]-offset, points[i-1]+offset, points[i]+offset, points[i-1]-offset, points[i]+offset, points[i]-offset]:
                ribbon.surface_add_vertex(vertex)
    ribbon.surface_end()
