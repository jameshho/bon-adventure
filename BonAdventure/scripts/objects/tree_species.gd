@tool
extends Node3D
## Stylized low-poly tree, one scene per species under scenes/props/nature/species/.
## Most foliage uses shared SphereMesh/BoxMesh resources for garden batching.
## Willow strands use three static ArrayMeshes; wood cylinders draw directly.
## Geometry is rebuilt in _ready and never saved into the scene (no owner).
## Nominal heights are about 7 town units; callers scale the root uniformly.

const SPECIES := ["oak", "pine", "palm tree", "birch", "weeping willow", "cherry tree", "cypress", "maple"]
const BARK := Color("7a5a43")

@export_enum("oak", "pine", "palm tree", "birch", "weeping willow", "cherry tree", "cypress", "maple") var species := "oak":
    set(value):
        species = value
        _rebuild()
## Each species has three deterministic variants: proportions, palette and lean.
@export_range(0, 2) var profile := 0:
    set(value):
        profile = value
        _rebuild()

static var _materials := {}
static var _spheres := {}
var _rng := RandomNumberGenerator.new()
var _crown := AABB()

func _ready() -> void:
    _rebuild()

func _rebuild() -> void:
    if not is_inside_tree(): return
    for child in get_children():
        if child.has_meta("tree_species_part"):
            remove_child(child)
            child.queue_free()
    set_meta("word_key", species)
    _rng.seed = hash(species) + profile * 7919
    _crown = AABB()
    var lean := Vector3(_rng.randf_range(-3.0, 3.0), 0, _rng.randf_range(-3.0, 3.0)) if profile > 0 else Vector3.ZERO
    var body := Node3D.new()
    body.name = "Model"
    body.rotation_degrees = lean
    _part(body, self)
    match species:
        "oak": _oak(body)
        "pine": _pine(body)
        "palm tree": _palm(body)
        "birch": _birch(body)
        "weeping willow": _willow(body)
        "cherry tree": _cherry(body)
        "cypress": _cypress(body)
        "maple": _maple(body)
    # Crown picking teaches the species; the trunk node below teaches generic "tree".
    var study := Area3D.new()
    study.name = "StudyArea"
    study.collision_layer = 1
    study.collision_mask = 0
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    # Slightly inside the lobes so neighbouring crowns in groves overlap less.
    box.size = _crown.size * 0.85
    shape.shape = box
    shape.position = body.transform * _crown.get_center()
    study.add_child(shape)
    _part(study, self)
    set_meta("nominal_height", (body.transform * _crown).end.y)

func _part(node: Node, parent: Node) -> Node:
    node.set_meta("tree_species_part", true)
    parent.add_child(node)
    return node

static func shared_material(tint: Color) -> StandardMaterial3D:
    var key := tint.to_html()
    if not _materials.has(key):
        var material := StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = 0.9
        _materials[key] = material
    return _materials[key]

static func unit_sphere(segments: int) -> SphereMesh:
    if not _spheres.has(segments):
        var mesh := SphereMesh.new()
        mesh.radius = 1.0
        mesh.height = 2.0
        mesh.radial_segments = segments
        mesh.rings = segments / 2
        _spheres[segments] = mesh
    return _spheres[segments]

## Ellipsoid foliage lobe; size is the full diameter on each axis.
func _lobe(parent: Node3D, point: Vector3, size: Vector3, tint: Color, tilt := Vector3.ZERO) -> void:
    var lobe := MeshInstance3D.new()
    lobe.name = "Foliage"
    lobe.mesh = unit_sphere(12)
    lobe.material_override = shared_material(tint)
    lobe.position = point
    lobe.rotation_degrees = tilt
    lobe.scale = size * 0.5
    parent.add_child(lobe)
    _grow_crown(AABB(point - size * 0.5, size))

func _leaf(parent: Node3D, point: Vector3, size: Vector3, tint: Color, basis: Basis) -> void:
    var leaf := MeshInstance3D.new()
    leaf.name = "Frond"
    var mesh := BoxMesh.new()
    mesh.size = Vector3.ONE
    leaf.mesh = mesh
    leaf.material_override = shared_material(tint)
    leaf.transform = Transform3D(basis.scaled_local(size), point)
    parent.add_child(leaf)
    _grow_crown(AABB(point - Vector3.ONE * size.x * 0.5, Vector3.ONE * size.x))

func _grow_crown(bounds: AABB) -> void:
    _crown = bounds if _crown.size == Vector3.ZERO else _crown.merge(bounds)

## Tapered wood segment from a to b.
func _wood(parent: Node3D, a: Vector3, b: Vector3, radius: float, tint := BARK, top := 0.75) -> MeshInstance3D:
    var wood := MeshInstance3D.new()
    wood.name = "Wood"
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = radius
    mesh.top_radius = radius * top
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 8
    mesh.rings = 1
    wood.mesh = mesh
    wood.material_override = shared_material(tint)
    var up := (b - a).normalized()
    var side := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
    var x := up.cross(side).normalized()
    wood.transform = Transform3D(Basis(x, up, x.cross(up)), (a + b) * 0.5)
    parent.add_child(wood)
    return wood

## Generic "tree" word root with one solid trunk collider.
func _trunk(parent: Node3D, height: float, radius: float, tint := BARK) -> void:
    var trunk := Node3D.new()
    trunk.name = "Trunk"
    trunk.set_meta("word_key", "tree")
    parent.add_child(trunk)
    _wood(trunk, Vector3.ZERO, Vector3(0, height, 0), radius, tint)
    var solid := StaticBody3D.new()
    solid.name = "Body"
    solid.collision_layer = 1
    solid.collision_mask = 0
    var shape := CollisionShape3D.new()
    var cylinder := CylinderShape3D.new()
    cylinder.radius = radius
    cylinder.height = height
    shape.shape = cylinder
    shape.position.y = height * 0.5
    solid.add_child(shape)
    trunk.add_child(solid)

func _jitter(amount: float) -> Vector3:
    return Vector3(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount) * 0.5, _rng.randf_range(-amount, amount))

func _pick(colors: Array) -> Color:
    return Color(colors[_rng.randi_range(0, colors.size() - 1)])

func _oak(body: Node3D) -> void:
    var spread: float = [1.0, 1.12, 0.92][profile]
    var greens: Array = [["5e8a45", "6f9a4f", "87ad5e"], ["587f40", "6a9449", "7fa557"], ["6b9450", "7da35a", "93b766"]][profile]
    _trunk(body, 3.4, 0.36)
    _wood(body, Vector3(0, 2.6, 0), Vector3(-1.3 * spread, 4.0, 0.4), 0.17)
    _wood(body, Vector3(0, 2.9, 0), Vector3(1.2 * spread, 4.3, -0.5), 0.15)
    _lobe(body, Vector3(0, 4.9, 0), Vector3(4.6, 3.0, 4.4) * spread, Color(greens[1]))
    for i in range(6):
        var a := TAU * i / 6.0 + _rng.randf_range(-0.3, 0.3)
        var point := Vector3(cos(a) * 1.9 * spread, 4.5 + _rng.randf_range(-0.4, 0.9), sin(a) * 1.8 * spread)
        _lobe(body, point, Vector3(2.5, 2.0, 2.4) * _rng.randf_range(0.85, 1.15), _pick(greens))
    _lobe(body, Vector3(0.3, 6.3, -0.2), Vector3(2.8, 1.8, 2.6), Color(greens[2]))

func _maple(body: Node3D) -> void:
    var tints: Array = [["6f9a45", "84a94c", "a3b443"], ["7c9d44", "a3b443", "d0973f"], ["d0973f", "c9703a", "e0aa4a"]][profile]
    _trunk(body, 3.0, 0.27)
    _wood(body, Vector3(0, 2.3, 0), Vector3(-0.9, 3.7, 0.3), 0.12)
    _wood(body, Vector3(0, 2.5, 0), Vector3(0.8, 3.9, -0.3), 0.12)
    _lobe(body, Vector3(0, 4.7, 0), Vector3(3.6, 3.6, 3.4), _pick(tints))
    for i in range(5):
        var a := TAU * i / 5.0 + _rng.randf_range(-0.25, 0.25)
        _lobe(body, Vector3(cos(a) * 1.4, 4.3 + _rng.randf_range(-0.3, 1.2), sin(a) * 1.4), Vector3(2.2, 2.1, 2.1), _pick(tints))
    _lobe(body, Vector3(0, 6.3, 0), Vector3(2.2, 1.6, 2.1), Color(tints[0]))

func _birch(body: Node3D) -> void:
    var bark := Color("e7e2d6")
    var greens: Array = [["86b05e", "9ec26c"], ["8fb862", "a6c773"], ["a3bb5f", "93b866"]][profile]
    var stems := [Vector3.ZERO] if profile != 1 else [Vector3(-0.35, 0, 0), Vector3(0.4, 0, 0.2)]
    for i in range(stems.size()):
        var base: Vector3 = stems[i]
        var top: Vector3 = base * 2.2 + Vector3(0, 5.4 - i * 0.6, 0)
        if i == 0:
            _trunk(body, 5.4, 0.17, bark)
        else:
            _wood(body, base, top, 0.14, bark)
        # Dark bark marks; small boxes batch with other foliage boxes.
        for m in range(4):
            var y := 0.9 + m * 1.05 + _rng.randf_range(-0.2, 0.2)
            _leaf(body, base.lerp(top, y / 5.4) + Vector3(0, 0, 0.13), Vector3(0.22, 0.07, 0.06), Color("3d3a36"), Basis(Vector3.UP, _rng.randf_range(0, TAU)))
    _crown = AABB()
    for i in range(7):
        var a := TAU * i / 7.0
        var y := 4.4 + (i % 3) * 0.9
        _lobe(body, Vector3(cos(a) * 1.1, y, sin(a) * 1.0) + _jitter(0.3), Vector3(1.6, 1.3, 1.5), _pick(greens))
    _lobe(body, Vector3(0, 6.6, 0), Vector3(1.5, 1.4, 1.4), Color(greens[1]))

func _pine(body: Node3D) -> void:
    var greens: Array = [["3f6b45", "4f7c4f"], ["365f40", "47734a"], ["456f43", "5a8452"]][profile]
    var slim: float = [1.0, 0.85, 1.12][profile]
    _trunk(body, 2.2, 0.24)
    var tiers := 5
    for i in range(tiers):
        var t := float(i) / (tiers - 1)
        var width := lerpf(4.0, 1.2, t) * slim
        _lobe(body, Vector3(0, 2.2 + i * 1.15, 0), Vector3(width, 1.5, width), Color(greens[i % 2]))
    _lobe(body, Vector3(0, 7.6, 0), Vector3(0.7, 1.3, 0.7), Color(greens[1]))

func _cypress(body: Node3D) -> void:
    var greens: Array = [["4a7348", "5a8653"], ["426a44", "52794c"], ["557d4c", "678f58"]][profile]
    var height: float = [1.0, 1.1, 0.9][profile]
    _trunk(body, 0.9, 0.2)
    for i in range(4):
        var y := (1.7 + i * 1.45) * height
        var width: float = [1.9, 1.8, 1.5, 1.0][i]
        _lobe(body, Vector3(0, y, 0) + _jitter(0.08), Vector3(width, 2.6 * height, width), Color(greens[i % 2]))
    _lobe(body, Vector3(0, 7.0 * height, 0), Vector3(0.6, 1.2, 0.6), Color(greens[1]))

func _palm(body: Node3D) -> void:
    var bend: float = [1.0, 1.4, 0.6][profile]
    var greens: Array = [["5d9446", "74a955"], ["548a40", "6b9f4e"], ["6aa04f", "82b45e"]][profile]
    var bark := Color("a88a64")
    _trunk(body, 1.2, 0.27, bark)
    var points: Array[Vector3] = [Vector3(0, 1.2, 0)]
    for i in range(1, 6):
        var t := float(i) / 5.0
        points.append(Vector3(t * t * 1.4 * bend, 1.2 + t * 5.2, 0))
    for i in range(1, points.size()):
        _wood(body, points[i - 1], points[i], lerpf(0.25, 0.17, float(i) / 5.0), bark, 0.92)
    var top: Vector3 = points.back()
    _lobe(body, top + Vector3(0, 0.1, 0), Vector3(0.7, 0.6, 0.7), Color("7a6a3e"))
    for i in range(8):
        var a := TAU * i / 8.0 + 0.2
        var droop := deg_to_rad(_rng.randf_range(18, 34))
        var basis := Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, -droop)
        _leaf(body, top + basis * Vector3(1.4, 0, 0), Vector3(3.0, 0.08, 1.0), Color(greens[i % 2]), basis)

func _willow(body: Node3D) -> void:
    # Sunlit lime domes of fat drooping strands over a forked trunk; [0] tints inner tiers.
    var greens: Array = [["4f7f2c", "6fa23a", "8bbb47"], ["4a782a", "679a37", "82b343"], ["568631", "78a940", "94c24f"]][profile]
    var sides: int = [6, 5, 7][profile]
    _trunk(body, 3.3, 0.42)
    var fork := Vector3(0, 3.0, 0)
    # [centre, dome radius, lowest hem height]; one crown cluster plus a ring of side clusters.
    var clusters: Array = [[Vector3(0.2, 6.7, -0.1), 1.6, 3.4]]
    for i in range(sides):
        var a := TAU * i / sides + _rng.randf_range(-.25, .25)
        var reach := _rng.randf_range(2.4, 3.1)
        clusters.append([Vector3(cos(a) * reach, _rng.randf_range(4.8, 6.1), sin(a) * reach), _rng.randf_range(1.3, 1.65), _rng.randf_range(1.0, 2.4)])
    # One static mesh per shade: no per-leaf nodes, transparency or processing.
    var tools: Array[SurfaceTool] = []
    var counts := [0, 0, 0]
    for shade in range(3):
        tools.append(SurfaceTool.new())
        tools[shade].begin(Mesh.PRIMITIVE_TRIANGLES)
    for cluster in clusters:
        var centre: Vector3 = cluster[0]
        var radius: float = cluster[1]
        var bottom: float = cluster[2]
        var elbow := fork.lerp(centre, .5) + Vector3(0, .35, 0)
        _wood(body, fork, elbow, .2, BARK, .8)
        _wood(body, elbow, centre - Vector3(0, radius * .3, 0), .16, BARK, .55)
        var outward := Vector3(centre.x, 0, centre.z)
        var tilt := Basis() if outward.length() < .5 else Basis(Vector3.UP.cross(outward).normalized(), .22)
        # Shallow cap hides where the strands meet at the top of each dome.
        _lobe(body, centre + tilt * Vector3(0, radius * .58, 0), Vector3(1.2, .5, 1.2) * radius, Color(greens[2]), tilt.get_euler() * 180.0 / PI)
        var strands := int(radius * 7.5)
        # Outer tier forms the dome and long curtain; a shorter, darker inner tier fills gaps.
        for tier in range(2):
            var n := strands if tier == 0 else strands / 2
            for f in range(n):
                var a := TAU * (f + .5 * tier) / n + _rng.randf_range(-.08, .08)
                var radial := Vector3(cos(a), 0, sin(a))
                var shrink := 1.0 if tier == 0 else .7
                var start := deg_to_rad(_rng.randf_range(8, 22) if tier == 0 else _rng.randf_range(35, 45))
                var bend := deg_to_rad(_rng.randf_range(100, 116) if tier == 0 else 80.0)
                var shade := 0 if tier == 1 else _rng.randi_range(1, 2)
                var path := PackedVector3Array()
                for k in range(7):
                    var phi := lerpf(start, bend, k / 6.0)
                    path.append(radial * sin(phi) * radius * shrink + Vector3.UP * cos(phi) * radius * .7)
                var rim := path[6]
                var hang := maxf(.6, (centre.y + rim.y - bottom - tier * .6) * _rng.randf_range(.6, 1.0))
                # Strands facing the trunk stay short so limbs show between clusters.
                if outward.length() > .5 and radial.dot(-outward.normalized()) > .3: hang *= .4
                for k in range(1, 9):
                    var s := k / 8.0
                    path.append(rim + radial * radius * .18 * s + Vector3.DOWN * hang * s)
                for k in range(path.size()):
                    path[k] = centre + tilt * path[k]
                counts[shade] = _willow_strand(tools[shade], counts[shade], path, tilt * Vector3(-sin(a), 0, cos(a)), radius * _rng.randf_range(.24, .29))
    for shade in range(3):
        var foliage := MeshInstance3D.new()
        foliage.name = "Hanging strands " + str(shade)
        foliage.mesh = tools[shade].commit()
        foliage.material_override = shared_material(Color(greens[shade]))
        body.add_child(foliage)

## Smooth, slightly flattened tube along path with rounded ends; returns the new vertex count.
func _willow_strand(st: SurfaceTool, base: int, path: PackedVector3Array, side: Vector3, width: float) -> int:
    var centres: Array[Vector3] = []
    var radii: Array[float] = []
    var caps: Array[float] = []
    var head := (path[0] - path[1]).normalized()
    var tail := (path[-1] - path[-2]).normalized()
    for c in range(3, 0, -1):
        centres.append(path[0] + head * width * .5 * sin(c * PI / 6.0))
        radii.append(width * .75 * cos(c * PI / 6.0))
        caps.append(-sin(c * PI / 6.0))
    for k in range(path.size()):
        centres.append(path[k])
        var t := k / float(path.size() - 1)
        radii.append(width * (.75 + .25 * sin(minf(t * 3.0, 1.0) * PI * .5)) * (1.0 - .25 * t * t))
        caps.append(0.0)
    for c in range(1, 4):
        centres.append(path[-1] + tail * width * .7 * sin(c * PI / 6.0))
        radii.append(width * .75 * cos(c * PI / 6.0))
        caps.append(sin(c * PI / 6.0))
    for j in range(centres.size()):
        var tangent := (centres[mini(j + 1, centres.size() - 1)] - centres[maxi(j - 1, 0)]).normalized()
        var out := side.cross(tangent).normalized()
        var cap := head if caps[j] < 0 else tail
        for q in range(8):
            var angle := TAU * q / 8.0
            var around := (side * cos(angle) + out * sin(angle) / .7).normalized()
            st.set_normal((around * cos(asin(absf(caps[j]))) + cap * absf(caps[j])).normalized())
            st.add_vertex(centres[j] + (side * cos(angle) + out * sin(angle) * .7) * radii[j])
        _grow_crown(AABB(centres[j] - Vector3.ONE * radii[j], Vector3.ONE * radii[j] * 2.0))
    for j in range(centres.size() - 1):
        for q in range(8):
            var a := base + j * 8 + q
            var b := base + j * 8 + (q + 1) % 8
            for index in [a, b, a + 8, b, b + 8, a + 8]:
                st.add_index(index)
    return base + centres.size() * 8

func _cherry(body: Node3D) -> void:
    var pinks: Array = [["f2b8c6", "e79bb0", "fbd3dc"], ["f6c7d2", "eeadbf", "fde0e6"], ["e9a3b7", "de8aa3", "f6c2cf"]][profile]
    _trunk(body, 2.0, 0.24, Color("6b4a3a"))
    _wood(body, Vector3(0, 1.8, 0), Vector3(-1.4, 3.1, 0.3), 0.13, Color("6b4a3a"))
    _wood(body, Vector3(0, 1.9, 0), Vector3(1.3, 3.2, -0.4), 0.13, Color("6b4a3a"))
    _wood(body, Vector3(0, 2.0, 0), Vector3(0.1, 3.4, 1.2), 0.12, Color("6b4a3a"))
    _lobe(body, Vector3(0, 3.9, 0), Vector3(4.2, 2.0, 4.0), Color(pinks[0]))
    for i in range(6):
        var a := TAU * i / 6.0 + _rng.randf_range(-0.3, 0.3)
        _lobe(body, Vector3(cos(a) * 1.8, 3.6 + _rng.randf_range(-0.2, 0.6), sin(a) * 1.7), Vector3(2.0, 1.4, 1.9), _pick(pinks))
    _lobe(body, Vector3(0.2, 4.8, -0.1), Vector3(2.4, 1.2, 2.2), Color(pinks[2]))
