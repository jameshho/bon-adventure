@tool
extends "res://scripts/characters/pig_sculpt.gd"

# Two optional sculpts. The original scene and sculpt script stay untouched.
@export var plush: bool = false
const SculptCache := preload("res://scripts/characters/sculpt_cache.gd")

## Meshes come from the sculpt cache when this exact character was built before.
func _ready() -> void:
    SculptCache.build(self)

func _build() -> void:
    body_color = Color("ffc5bd")
    ear_inner_color = Color("ffaaa8")
    blush_color = Color("ffa4a7") if plush else Color("ffb5b2")
    snout_color = Color("f9949c")
    outline_color = Color("8e4d30")
    eye_color = Color("85492e")
    hoof_color = Color("f58f95")
    # Broad lower belly, nearly continuous head/body, and a gently domed crown.
    _body_profile = [
        Vector3(0.17, 0.006, 0.006), Vector3(0.23, 0.34, 0.26),
        Vector3(0.33, 0.56, 0.36), Vector3(0.48, 0.68, 0.43),
        Vector3(0.68, 0.745, 0.47), Vector3(0.90, 0.758, 0.48),
        Vector3(1.10, 0.733, 0.47), Vector3(1.30, 0.695, 0.455),
        Vector3(1.49, 0.683, 0.45), Vector3(1.69, 0.664, 0.44),
        Vector3(1.87, 0.626, 0.415), Vector3(2.03, 0.55, 0.37),
        Vector3(2.13, 0.43, 0.30), Vector3(2.18, 0.26, 0.19),
        Vector3(2.203, 0.006, 0.006)
    ]
    if plush:
        for i in range(_body_profile.size()):
            _body_profile[i].z *= 1.28
    var skin := _mat(body_color)
    var inner := _mat(ear_inner_color)
    var blush := _mat(blush_color, true)
    var nose := _mat(snout_color)
    var edge := _mat(outline_color)
    var brown := _mat(eye_color)
    var hoof := _mat(hoof_color)
    _put("Torso/Visual", _make_body(skin))
    # Soft rounded-square ears with a drooping inner corner, matching the art.
    var ear := _left_ear()
    var inset := PackedVector2Array()
    for point in ear:
        inset.append(Vector2(-0.642, 2.065) + (point - Vector2(-0.642, 2.065)) * 0.67)
    _put("Head/LeftEar", _pillow(ear, -0.27, 0.015, skin))
    _put("Head/RightEar", _pillow(_mirror(ear), -0.27, 0.015, skin))
    _put("Head/LeftEar/Inner", _pillow(inset, -0.309, -0.27, inner))
    _put("Head/RightEar/Inner", _pillow(_mirror(inset), -0.309, -0.27, inner))
    _put("Head/LeftCheek", _face_oval(-0.425, 1.535, 0.180, 0.174, 0.001, blush))
    _put("Head/RightCheek", _face_oval(0.425, 1.535, 0.180, 0.174, 0.001, blush))
    _put("Head/LeftEye", _face_oval(-0.240, 1.710, 0.033, 0.041, 0.012, brown))
    _put("Head/RightEye", _face_oval(0.240, 1.710, 0.033, 0.041, 0.012, brown))
    var front := -0.54 if not plush else -0.68
    _put("Head/Snout", _pillow(_nose_outline(), front, _front_z(0, 1.60) + 0.025, nose))
    _put("Head/Snout/PinkPad", _rim(front - 0.022, edge))
    _put("Head/Snout/LeftNostril", _flat_disc(-0.080, 1.599, front - 0.044, 0.020, 0.028, brown))
    _put("Head/Snout/RightNostril", _flat_disc(0.080, 1.599, front - 0.044, 0.020, 0.028, brown))
    _put("Arm/Visual", _arm(-1, skin))
    _put("Arm_2/Visual", _arm(1, skin))
    for side in [-1.0, 1.0]:
        var path := "Foot" if side < 0 else "Foot_2"
        _put(path + "/Visual", _ellipsoid(Vector3(side * 0.195, 0.20, -0.08), Vector3(0.205, 0.125, 0.24), skin))
        _put(path + "/Hoof", _ellipsoid(Vector3(side * 0.195, 0.085, -0.13), Vector3(0.143, 0.084, 0.18), hoof))
        _put(path + "/HoofNotch", _flat_disc(side * 0.195, 0.060, -0.304, 0.009, 0.025, edge))
    _put("Tail", _ellipsoid(Vector3(0.10, 0.62, _section(0.62).y), Vector3(0.09, 0.10, 0.11), skin))
    # Cast real contact shadows; the old character's shading remains unchanged.
    for node in find_children("*", "MeshInstance3D"):
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        if not plush and node.name in ["Visual", "LeftEar", "RightEar"]:
            node.mesh.surface_get_material(0).next_pass = _ink()

func _mat(tint: Color, fully_flat: bool = false) -> ShaderMaterial:
    # A soft illustration shader avoids the harsh town sun washing out the pink.
    # World-space normals keep the gentle light stable when walking around it.
    # One shared Shader per code for every character (sculpt_cache.gd).
    var shader := SculptCache.shared_shader("""shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint_color : source_color;
uniform float softness = 0.16;
uniform float fuzz = 0.0;
varying vec3 world_normal;
void vertex() { world_normal = MODEL_NORMAL_MATRIX * NORMAL; }
void fragment() {
    vec3 n = normalize(world_normal);
    float shade = 1.0 - softness + softness * max(dot(n, normalize(vec3(-0.45, 0.75, -0.65))), 0.0);
    vec3 color = tint_color.rgb * shade;
    // Velvet edge: plush fabric catches light where it turns away from the viewer.
    float rim = 1.0 - clamp(dot(normalize(NORMAL) * (FRONT_FACING ? 1.0 : -1.0), VIEW), 0.0, 1.0);
    ALBEDO = mix(color, min(color * 1.16 + vec3(0.06), vec3(1.0)), fuzz * pow(rim, 2.6));
}
""")
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("tint_color", tint)
    # Both plush cheeks use the exact same flat pink. Directional shading here
    # made one cheek blend into the skin while the other appeared stronger.
    material.set_shader_parameter("softness", (0.0 if plush else 0.09) if fully_flat else (0.28 if plush else 0.12))
    # Only the plush sculpt (BonBon) gets the velvet edge; flat cheeks stay flat.
    material.set_shader_parameter("fuzz", 0.45 if plush and not fully_flat else 0.0)
    return material

func _put(node_path: String, result: ArrayMesh) -> void:
    # The original helpers mix clockwise and anticlockwise contours. Correct
    # each optional part before normals/outline generation, without editing them.
    var arrays := result.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    var center := result.get_aabb().get_center()
    var flat := "Cheek" in node_path or "Eye" in node_path or "Nostril" in node_path or "Notch" in node_path or "PinkPad" in node_path
    var orientation := 0.0
    for i in range(vertices.size()):
        orientation += -normals[i].z if flat else (vertices[i] - center).dot(normals[i])
    if orientation < 0:
        for i in range(0, indices.size(), 3):
            var swap := indices[i + 1]
            indices[i + 1] = indices[i + 2]
            indices[i + 2] = swap
        result = _surface(vertices, indices, result.surface_get_material(0))
    super._put(node_path, result)

func _ink() -> ShaderMaterial:
    var shader := SculptCache.shared_shader("""shader_type spatial;
render_mode unshaded, cull_front;
void vertex() { VERTEX += NORMAL * 0.022; }
void fragment() { ALBEDO = vec3(0.27, 0.105, 0.045); }
""")
    var material := ShaderMaterial.new()
    material.shader = shader
    return material

func _left_ear() -> PackedVector2Array:
    return _bezier(Vector2(-0.42, 2.105), [
        [Vector2(-0.46, 2.245), Vector2(-0.56, 2.195), Vector2(-0.65, 2.21)],
        [Vector2(-0.76, 2.23), Vector2(-0.78, 2.28), Vector2(-0.83, 2.18)],
        [Vector2(-0.89, 2.02), Vector2(-0.86, 1.91), Vector2(-0.75, 1.89)],
        [Vector2(-0.64, 1.86), Vector2(-0.55, 1.94), Vector2(-0.42, 2.105)]
    ], 16)

func _nose_outline() -> PackedVector2Array:
    # Domed top and a much flatter base, rather than a rectangular muzzle.
    return _bezier(Vector2(-0.194, 1.50), [
        [Vector2(-0.245, 1.52), Vector2(-0.215, 1.65), Vector2(-0.155, 1.70)],
        [Vector2(-0.080, 1.765), Vector2(0.080, 1.765), Vector2(0.155, 1.70)],
        [Vector2(0.215, 1.65), Vector2(0.245, 1.52), Vector2(0.194, 1.50)],
        [Vector2(0.14, 1.475), Vector2(-0.14, 1.475), Vector2(-0.194, 1.50)]
    ], 20)

func _nose_inside() -> PackedVector2Array:
    var result := PackedVector2Array()
    for point in _nose_outline():
        result.append(Vector2(0, 1.61) + (point - Vector2(0, 1.61)) * (0.91 if plush else 0.86))
    return result

func _arm(side: float, material: Material) -> ArrayMesh:
    # Short mittens attach high and fall outward, with no disconnected ball joint.
    var contour := _bezier(Vector2(0.65, 1.22), [
        [Vector2(0.70, 1.17), Vector2(0.74, 1.12), Vector2(0.86, 1.08)],
        [Vector2(0.98, 1.04), Vector2(0.98, 0.91), Vector2(0.88, 0.89)],
        [Vector2(0.80, 0.86), Vector2(0.76, 0.89), Vector2(0.72, 0.95)],
        [Vector2(0.66, 1.00), Vector2(0.63, 1.14), Vector2(0.65, 1.22)]
    ], 16)
    if side < 0:
        contour = _mirror(contour)
    return _pillow(contour, -0.19 if not plush else -0.16, 0.18, material)

func _ellipsoid(center: Vector3, radius: Vector3, material: Material) -> ArrayMesh:
    var centers: Array[Vector3] = []
    var radii: Array[Vector2] = []
    for i in range(33):
        var t := PI * float(i) / 32.0
        centers.append(center + Vector3(0, -cos(t) * radius.y, 0))
        radii.append(Vector2(maxf(0.0001, sin(t) * radius.x), maxf(0.0001, sin(t) * radius.z)))
    return _limb_rings(centers, radii, material, 1)
