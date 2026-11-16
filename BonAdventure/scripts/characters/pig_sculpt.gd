@tool
extends Node3D

# Rounded plush pig v3. Faces local -Z. Torso is a full XYZ volume.
# Meshes regenerate on scene load; individual MeshInstance3D transforms remain editable.
# Every visible part lives in an ordinary selectable MeshInstance3D node.

@export var body_color: Color = Color(0.975, 0.812, 0.795)
@export var ear_inner_color: Color = Color(0.985, 0.635, 0.655)
@export var blush_color: Color = Color(1.000, 0.740, 0.741)
@export var snout_color: Color = Color(0.975, 0.540, 0.575)
@export var outline_color: Color = Color(0.595, 0.310, 0.268)
@export var eye_color: Color = Color(0.385, 0.200, 0.155)
@export var hoof_color: Color = Color(0.925, 0.430, 0.485)

var _body_profile: Array[Vector3] = [
    # Each ring has matching X and Z radii so the side view is just as plump.
    Vector3(0.17, 0.007, 0.009),
    Vector3(0.23, 0.26, 0.28),
    Vector3(0.37, 0.47, 0.50),
    Vector3(0.55, 0.67, 0.70),
    Vector3(0.73, 0.784, 0.815),
    Vector3(0.91, 0.813, 0.840),
    Vector3(1.10, 0.804, 0.838),
    Vector3(1.28, 0.783, 0.811),
    Vector3(1.47, 0.755, 0.790),
    Vector3(1.64, 0.744, 0.790),
    Vector3(1.81, 0.707, 0.748),
    Vector3(1.95, 0.633, 0.678),
    Vector3(2.075, 0.485, 0.530),
    Vector3(2.156, 0.285, 0.325),
    Vector3(2.203, 0.007, 0.009)
]

func _ready() -> void:
    _build()

func _build() -> void:
    var skin := _mat(body_color)
    var inner := _mat(ear_inner_color)
    var blush := _mat(blush_color, true)
    var nose := _mat(snout_color)
    var edge := _mat(outline_color)
    var brown := _mat(eye_color)
    var hoof := _mat(hoof_color)

    # One true all-around 3D body: no separate sphere head, no flat extrusion.
    _put("Torso/Visual", _make_body(skin))

    # Soft, outward-flopping custom ear geometry, not circular sphere primitives.
    var ear := _left_ear()
    var ear_pink := _left_ear_inner()
    _put("Head/LeftEar", _pillow(ear, -0.49, -0.30, skin))
    _put("Head/RightEar", _pillow(_mirror(ear), -0.49, -0.30, skin))
    _put("Head/LeftEar/Inner", _pillow(ear_pink, -0.554, -0.507, inner))
    _put("Head/RightEar/Inner", _pillow(_mirror(ear_pink), -0.554, -0.507, inner))

    # Facial details are projected onto the body curvature and remain separate.
    _put("Head/LeftCheek", _face_oval(-0.465, 1.505, 0.171, 0.171, 0.006, blush))
    _put("Head/RightCheek", _face_oval(0.465, 1.505, 0.171, 0.171, 0.006, blush))
    _put("Head/LeftEye", _face_oval(-0.255, 1.787, 0.033, 0.036, 0.020, brown))
    _put("Head/RightEye", _face_oval(0.255, 1.787, 0.033, 0.036, 0.020, brown))

    # Snout has a hand-shaped rounded-rectangle cross section and a slim rim.
    # A modest nose projection preserves the cute flat-front cartoon look.
    _put("Head/Snout", _pillow(_nose_outline(), -0.896, -0.740, nose))
    _put("Head/Snout/PinkPad", _rim(-0.890, edge))
    _put("Head/Snout/LeftNostril", _flat_disc(-0.087, 1.541, -0.958, 0.018, 0.031, brown))
    _put("Head/Snout/RightNostril", _flat_disc(0.087, 1.541, -0.958, 0.018, 0.031, brown))

    # Small sculpted arms. Curved all the way around, including front and back.
    _put("Arm/Visual", _arm(-1.0, skin))
    _put("Arm_2/Visual", _arm(1.0, skin))

    # Almost hidden feet and soft pink toe caps, rather than full trouser legs.
    _put("Foot/Visual", _foot(-1.0, skin))
    _put("Foot_2/Visual", _foot(1.0, skin))
    _put("Foot/Hoof", _hoof(-1.0, hoof))
    _put("Foot_2/Hoof", _hoof(1.0, hoof))
    _put("Foot/HoofNotch", _flat_disc(-0.202, 0.070, -0.339, 0.010, 0.029, edge))
    _put("Foot_2/HoofNotch", _flat_disc(0.202, 0.070, -0.339, 0.010, 0.029, edge))
    _put("Tail", _tail(skin))

func _put(node_path: String, result: ArrayMesh) -> void:
    var node := get_node_or_null(NodePath(node_path)) as MeshInstance3D
    if node == null:
        return

    # Use a real pivot at the center of every generated sculpted part.
    # This keeps rotate/move/scale handles useful in the Godot 3D editor.
    var mesh_center := result.get_aabb().get_center()
    var parent_center := Vector3.ZERO
    var parent_mesh := node.get_parent() as MeshInstance3D
    if parent_mesh != null:
        parent_center = parent_mesh.position

    var arrays := result.surface_get_arrays(0)
    var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    for i in range(verts.size()):
        verts[i] -= mesh_center
    arrays[Mesh.ARRAY_VERTEX] = verts

    var centered := ArrayMesh.new()
    centered.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    centered.surface_set_material(0, result.surface_get_material(0))
    node.mesh = centered
    node.position = mesh_center - parent_center
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

var _skin_shader: Shader

func _mat(tint: Color, fully_flat: bool = false) -> ShaderMaterial:
    if _skin_shader == null:
        _skin_shader = Shader.new()
        _skin_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled;\nuniform vec4 tint_color : source_color = vec4(1.0);\nuniform float flat_mix : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n    vec3 n = normalize(NORMAL);\n    float light_amount = 0.91 + 0.09 * max(dot(n, normalize(vec3(-0.32, 0.64, 0.64))), 0.0);\n    light_amount = mix(light_amount, 1.0, flat_mix);\n    ALBEDO = tint_color.rgb * light_amount;\n}"
    var m := ShaderMaterial.new()
    m.shader = _skin_shader
    m.set_shader_parameter("tint_color", tint)
    m.set_shader_parameter("flat_mix", 1.0 if fully_flat else 0.0)
    return m

func _surface(points: PackedVector3Array, triangles: PackedInt32Array, material: Material) -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for point in points:
        tool.add_vertex(point)
    for index in triangles:
        tool.add_index(index)
    tool.generate_normals()
    var mesh: ArrayMesh = tool.commit()
    mesh.surface_set_material(0, material)
    return mesh

func _catmull(a: float, b: float, c: float, d: float, t: float) -> float:
    return 0.5 * ((2.0 * b) + (c - a) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t)

func _section(y: float) -> Vector2:
    var n := _body_profile.size()
    if y <= _body_profile[0].x:
        return Vector2(_body_profile[0].y, _body_profile[0].z)
    if y >= _body_profile[n - 1].x:
        return Vector2(_body_profile[n - 1].y, _body_profile[n - 1].z)
    for i in range(n - 1):
        var b := _body_profile[i]
        var c := _body_profile[i + 1]
        if y <= c.x:
            var a := _body_profile[maxi(0, i - 1)]
            var d := _body_profile[mini(i + 2, n - 1)]
            var t := (y - b.x) / (c.x - b.x)
            return Vector2(maxf(0.002, _catmull(a.y, b.y, c.y, d.y, t)), maxf(0.002, _catmull(a.z, b.z, c.z, d.z, t)))
    return Vector2(0.01, 0.01)

func _make_body(material: Material) -> ArrayMesh:
    var rows := 96
    var sides := 64
    var points := PackedVector3Array()
    var faces := PackedInt32Array()
    for j in range(rows + 1):
        var yy := lerpf(0.17, 2.203, float(j) / float(rows))
        var size := _section(yy)
        for i in range(sides):
            var theta := TAU * float(i) / float(sides)
            points.append(Vector3(cos(theta) * size.x, yy, sin(theta) * size.y))
    for j in range(rows):
        for i in range(sides):
            var k := (i + 1) % sides
            var low := j * sides + i
            var next_low := j * sides + k
            var high := (j + 1) * sides + i
            var next_high := (j + 1) * sides + k
            faces.append_array(PackedInt32Array([low, high, next_low, next_low, high, next_high]))
    return _surface(points, faces, material)

func _front_z(xx: float, yy: float) -> float:
    var r := _section(clampf(yy, 0.17, 2.203))
    var fraction := clampf(xx / r.x, -0.995, 0.995)
    return -r.y * sqrt(maxf(0.0, 1.0 - fraction * fraction))

func _face_oval(cx: float, cy: float, rx: float, ry: float, bump: float, material: Material) -> ArrayMesh:
    var sides := 48
    var rings := 7
    var points := PackedVector3Array()
    var faces := PackedInt32Array()
    for j in range(rings + 1):
        var radial := float(j) / float(rings)
        for i in range(sides):
            var theta := TAU * float(i) / float(sides)
            var xx := cx + cos(theta) * rx * radial
            var yy := cy + sin(theta) * ry * radial
            var depth := _front_z(xx, yy) - 0.026 - bump * (1.0 - radial * radial)
            points.append(Vector3(xx, yy, depth))
    for j in range(rings):
        for i in range(sides):
            var k := (i + 1) % sides
            var a := j * sides + i
            var b := j * sides + k
            var c := (j + 1) * sides + i
            var d := (j + 1) * sides + k
            faces.append_array(PackedInt32Array([a, b, c, b, d, c]))
    return _surface(points, faces, material)

func _rounded_rect(cx: float, cy: float, rx: float, ry: float) -> PackedVector2Array:
    var shape := PackedVector2Array()
    var n := 72
    for i in range(n):
        var theta := TAU * float(i) / float(n)
        var ax := cos(theta)
        var ay := sin(theta)
        var xx := cx + rx * signf(ax) * pow(absf(ax), 0.70)
        var yy := cy + ry * signf(ay) * pow(absf(ay), 0.76)
        shape.append(Vector2(xx, yy))
    return shape

func _nose_outline() -> PackedVector2Array:
    return _rounded_rect(0.0, 1.55, 0.215, 0.142)

func _nose_inside() -> PackedVector2Array:
    return _rounded_rect(0.0, 1.553, 0.193, 0.121)

# A narrow brown *front rim* only. No massive brown slab under the snout.
func _rim(depth: float, material: Material) -> ArrayMesh:
    var outer := _nose_outline()
    var inner := _nose_inside()
    var points := PackedVector3Array()
    var faces := PackedInt32Array()
    var n := outer.size()
    for i in range(n):
        points.append(Vector3(outer[i].x, outer[i].y, depth))
    for i in range(n):
        points.append(Vector3(inner[i].x, inner[i].y, depth - 0.004))
    for i in range(n):
        var next := (i + 1) % n
        faces.append_array(PackedInt32Array([i, next, n + i, n + i, next, n + next]))
    return _surface(points, faces, material)

func _flat_disc(cx: float, cy: float, zz: float, rx: float, ry: float, material: Material) -> ArrayMesh:
    var verts := PackedVector3Array([Vector3(cx, cy, zz)])
    var tris := PackedInt32Array()
    var n := 24
    for i in range(n):
        var angle := TAU * float(i) / float(n)
        verts.append(Vector3(cx + rx * cos(angle), cy + ry * sin(angle), zz))
    for i in range(n):
        tris.append_array(PackedInt32Array([0, 1 + ((i + 1) % n), 1 + i]))
    return _surface(verts, tris, material)

# Puffy watertight mesh built from an organic 2D outline, with fully curved
# front, rounded edge and back. Not a planar cutout or thin extrusion.
func _pillow(contour: PackedVector2Array, front_z: float, back_z: float, material: Material) -> ArrayMesh:
    var center := Vector2.ZERO
    for p in contour:
        center += p
    center /= float(contour.size())
    var scales := [0.0, 0.38, 0.68, 0.89, 0.99, 1.0, 0.90, 0.65, 0.34, 0.0]
    var zs := [front_z - 0.040, front_z - 0.036, front_z - 0.027, front_z - 0.013, front_z + 0.019, (front_z + back_z) * 0.5, back_z - 0.015, back_z - 0.020, back_z - 0.013, back_z]
    var count := contour.size()
    var verts := PackedVector3Array()
    var tris := PackedInt32Array()
    for j in range(scales.size()):
        for i in range(count):
            var p: Vector2 = center + (contour[i] - center) * float(scales[j])
            verts.append(Vector3(p.x, p.y, float(zs[j])))
    for j in range(scales.size() - 1):
        for i in range(count):
            var k := (i + 1) % count
            var a := j * count + i
            var b := j * count + k
            var c := (j + 1) * count + i
            var d := (j + 1) * count + k
            tris.append_array(PackedInt32Array([a, b, c, b, d, c]))
    return _surface(verts, tris, material)

func _bezier(start: Vector2, controls: Array, detail: int = 10) -> PackedVector2Array:
    var result := PackedVector2Array([start])
    var here := start
    for v in controls:
        var b: Vector2 = v[0]
        var c: Vector2 = v[1]
        var d: Vector2 = v[2]
        for i in range(1, detail + 1):
            var t := float(i) / float(detail)
            var u := 1.0 - t
            result.append(here * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
        here = d
    result.resize(result.size() - 1)
    return result

func _mirror(original: PackedVector2Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    for i in range(original.size() - 1, -1, -1):
        result.append(Vector2(-original[i].x, original[i].y))
    return result

func _left_ear() -> PackedVector2Array:
    # One soft oval pad, rotated, intersecting the head: no arrow-like root.
    return _ear_ellipse(Vector2(-0.672, 2.169), 0.329, 0.172, -0.27)

func _left_ear_inner() -> PackedVector2Array:
    return _ear_ellipse(Vector2(-0.699, 2.178), 0.244, 0.114, -0.27)

func _ear_ellipse(center: Vector2, width: float, height: float, tilt: float) -> PackedVector2Array:
    var result := PackedVector2Array()
    var count := 80
    for i in range(count):
        var theta := TAU * float(i) / float(count)
        var ax := cos(theta) * width
        var ay := sin(theta) * height
        result.append(center + Vector2(ax * cos(tilt) - ay * sin(tilt), ax * sin(tilt) + ay * cos(tilt)))
    return result

func _limb_rings(centers: Array[Vector3], radii: Array[Vector2], material: Material, side_axis: int = 0) -> ArrayMesh:
    var sides := 32
    var verts := PackedVector3Array()
    var tris := PackedInt32Array()
    for j in range(centers.size()):
        var p := centers[j]
        for i in range(sides):
            var theta := TAU * float(i) / float(sides)
            if side_axis == 0:
                verts.append(Vector3(p.x, p.y + cos(theta) * radii[j].x, p.z + sin(theta) * radii[j].y))
            else:
                verts.append(Vector3(p.x + cos(theta) * radii[j].x, p.y, p.z + sin(theta) * radii[j].y))
    for j in range(centers.size() - 1):
        for i in range(sides):
            var k := (i + 1) % sides
            var a := j * sides + i
            var b := j * sides + k
            var c := (j + 1) * sides + i
            var d := (j + 1) * sides + k
            if side_axis == 0 and centers[centers.size() - 1].x > centers[0].x:
                tris.append_array(PackedInt32Array([a, b, c, b, d, c]))
            else:
                tris.append_array(PackedInt32Array([a, c, b, b, c, d]))
    return _surface(verts, tris, material)

func _arm(sign_x: float, material: Material) -> ArrayMesh:
    # Signed positions are ordered from interior to exterior.
    var centers: Array[Vector3] = []
    var radii: Array[Vector2] = []
    var offsets := [0.0, 0.04, 0.08, 0.13, 0.18, 0.21, 0.235]
    var yr := [0.090, 0.114, 0.147, 0.154, 0.142, 0.100, 0.003]
    var zr := [0.091, 0.115, 0.152, 0.160, 0.146, 0.107, 0.003]
    for j in range(offsets.size()):
        var a: float = offsets[j]
        centers.append(Vector3(sign_x * (0.70 + a), 0.92 - 0.28 * a, -0.04))
        radii.append(Vector2(yr[j], zr[j]))
    return _limb_rings(centers, radii, material)

func _foot(sign_x: float, material: Material) -> ArrayMesh:
    var centers: Array[Vector3] = []
    var radii: Array[Vector2] = []
    var yvals := [0.002, 0.025, 0.050, 0.085, 0.125, 0.170, 0.208, 0.238]
    var xr := [0.005, 0.113, 0.143, 0.159, 0.151, 0.128, 0.082, 0.005]
    var zr := [0.005, 0.123, 0.161, 0.172, 0.163, 0.132, 0.089, 0.005]
    for j in range(yvals.size()):
        centers.append(Vector3(sign_x * 0.190, yvals[j], -0.105))
        radii.append(Vector2(xr[j], zr[j]))
    return _limb_rings(centers, radii, material, 1)

func _hoof(sign_x: float, material: Material) -> ArrayMesh:
    var centers: Array[Vector3] = []
    var radii: Array[Vector2] = []
    var ys := [0.011, 0.025, 0.044, 0.063, 0.082, 0.105, 0.128]
    var xs := [0.005, 0.080, 0.119, 0.136, 0.134, 0.105, 0.005]
    var zs := [0.005, 0.068, 0.087, 0.091, 0.085, 0.067, 0.005]
    for j in range(ys.size()):
        centers.append(Vector3(sign_x * 0.190, ys[j], -0.248))
        radii.append(Vector2(xs[j], zs[j]))
    return _limb_rings(centers, radii, material, 1)

func _tail(material: Material) -> ArrayMesh:
    var centers: Array[Vector3] = [
        Vector3(0.16, 0.71, 0.635), Vector3(0.20, 0.69, 0.705),
        Vector3(0.22, 0.66, 0.750), Vector3(0.19, 0.63, 0.772),
        Vector3(0.145, 0.66, 0.775), Vector3(0.15, 0.70, 0.754)
    ]
    var rad: Array[Vector2] = [
        Vector2(0.055, 0.055), Vector2(0.050, 0.050), Vector2(0.044, 0.044),
        Vector2(0.035, 0.035), Vector2(0.024, 0.024), Vector2(0.004, 0.004)
    ]
    return _limb_rings(centers, rad, material, 1)
