@tool
extends Node3D
## Stylized low-poly bush, one scene per type under scenes/props/nature/species/.
## Shares tree_species.gd's cached materials and unit sphere so garden bushes batch
## with garden_rendering.gd. Decorative: a StudyArea teaches the word, but there is
## no movement collision. Geometry is rebuilt in _ready and never saved (no owner).
## Nominal sizes: shrub ~1.4 x 1.0, rose bush ~1.1 x 0.9, fern ~1.5 x 0.7 town units;
## hedge is `length` long, 0.8 tall and 0.6 deep.

const TreeSpecies = preload("res://scripts/objects/tree_species.gd")

@export_enum("shrub", "hedge", "rose bush", "fern") var species := "shrub":
    set(value):
        species = value
        _rebuild()
## Three deterministic variants of shape, plus rose color for rose bushes. Greens
## come from one small shared set: each extra tint adds a batch per garden cell.
## Shrub only: profile 3 is a tall clipped yew "egg" (~1.2 x 1.55), as lining the
## Washington monument walks; other species treat 3 as 2.
@export_range(0, 3) var profile := 0:
    set(value):
        profile = value
        _rebuild()
## Hedge section length along local X.
@export_range(0.6, 8.0, 0.1) var length := 2.0:
    set(value):
        length = value
        _rebuild()

## False for decorative planting that is not a study target (e.g. the facade planters the old world_refinements.gd pass placed; now saved in the town).
@export var study_area := true

var _rng := RandomNumberGenerator.new()
var _bounds := AABB()

func _ready() -> void:
    _rebuild()

func _rebuild() -> void:
    if not is_inside_tree(): return
    for child in get_children():
        if child.has_meta("bush_species_part"):
            remove_child(child)
            child.queue_free()
    set_meta("word_key", species)
    _rng.seed = hash(species) + profile * 7919
    _bounds = AABB()
    var body := Node3D.new()
    body.name = "Model"
    body.set_meta("bush_species_part", true)
    add_child(body)
    match species:
        "shrub": _shrub(body)
        "hedge": _hedge(body)
        "rose bush": _rose_bush(body)
        "fern": _fern(body)
    if not study_area:
        set_meta("nominal_size", _bounds.size)
        return
    var study := Area3D.new()
    study.name = "StudyArea"
    study.collision_layer = 1
    study.collision_mask = 0
    study.set_meta("bush_species_part", true)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = _bounds.size
    shape.shape = box
    shape.position = _bounds.get_center()
    study.add_child(shape)
    add_child(study)
    set_meta("nominal_size", _bounds.size)

## Ellipsoid lobe; size is the full diameter on each axis.
func _lobe(parent: Node3D, point: Vector3, size: Vector3, tint: Color, tilt := Vector3.ZERO) -> void:
    var lobe := MeshInstance3D.new()
    lobe.name = "Foliage"
    lobe.mesh = TreeSpecies.unit_sphere(12)
    lobe.material_override = TreeSpecies.shared_material(tint)
    lobe.position = point
    lobe.rotation_degrees = tilt
    lobe.scale = size * 0.5
    parent.add_child(lobe)
    var reach := Vector3(maxf(size.x, size.z), size.y, maxf(size.x, size.z)) * 0.5
    var bounds := AABB(point - reach, reach * 2.0)
    _bounds = bounds if _bounds.size == Vector3.ZERO else _bounds.merge(bounds)

func _pick(colors: Array) -> Color:
    return Color(colors[_rng.randi_range(0, colors.size() - 1)])

func _shrub(body: Node3D) -> void:
    var greens: Array = [["4f7a40", "5c8749"], ["4f7a40", "5c8749"], ["5c8749", "6a9452"], ["4f7a40", "5c8749"]][profile]
    # Profile 3: stacked lobes taper from a broad base to a rounded crown, the Boston
    # Public Garden's sheared yews; flat-bottomed so it sits on the lawn, not on a point.
    if profile == 3:
        _lobe(body, Vector3(0, 0.78, 0), Vector3(1.16, 1.54, 1.16), Color(greens[0]))
        _lobe(body, Vector3(0, 0.36, 0), Vector3(1.2, 0.7, 1.2), Color(greens[0]))
        _bounds = AABB(Vector3(-0.6, 0, -0.6), Vector3(1.2, 1.55, 1.2))
        return
    # Profile 1 is a tidy clipped dome; the others are looser, irregular clumps.
    if profile == 1:
        _lobe(body, Vector3(0, 0.45, 0), Vector3(1.3, 0.9, 1.2), Color(greens[0]))
        _lobe(body, Vector3(0.15, 0.7, -0.05), Vector3(0.8, 0.5, 0.75), Color(greens[1]))
        return
    _lobe(body, Vector3(0, 0.5, 0), Vector3(1.0, 0.9, 0.95), Color(greens[0]))
    for i in range(4):
        var a := TAU * i / 4.0 + _rng.randf_range(-0.4, 0.4)
        _lobe(body, Vector3(cos(a) * 0.4, 0.35 + _rng.randf_range(0.0, 0.25), sin(a) * 0.38), Vector3(0.7, 0.6, 0.65) * _rng.randf_range(0.85, 1.15), _pick(greens))

func _hedge(body: Node3D) -> void:
    var greens: Array = [["4f7a40", "5c8749"], ["5c8749", "4f7a40"], ["5c8749", "6a9452"]][mini(profile, 2)]
    var core := MeshInstance3D.new()
    core.name = "Hedge body"
    var mesh := BoxMesh.new()
    mesh.size = Vector3.ONE
    core.mesh = mesh
    core.material_override = TreeSpecies.shared_material(Color(greens[0]))
    core.position = Vector3(0, 0.36, 0)
    core.scale = Vector3(length - 0.3, 0.72, 0.5)
    body.add_child(core)
    _bounds = AABB(Vector3(-length * 0.5, 0, -0.3), Vector3(length, 0.8, 0.6))
    # Soft rounded top and ends so the section does not read as a plain green box.
    var count := maxi(2, int(round(length / 0.55)))
    for i in range(count):
        var x := lerpf(-length * 0.5 + 0.3, length * 0.5 - 0.3, float(i) / (count - 1))
        _lobe(body, Vector3(x, 0.66 + _rng.randf_range(-0.03, 0.04), 0), Vector3(0.62, 0.32, 0.6), Color(greens[i % 2]))
    for side in [-1.0, 1.0]:
        _lobe(body, Vector3(side * (length * 0.5 - 0.25), 0.38, 0), Vector3(0.5, 0.76, 0.6), Color(greens[0]))

func _rose_bush(body: Node3D) -> void:
    var blooms: Array = [["c9353f", "e0505a"], ["e98aa5", "f2a9bd"], ["f3e6d8", "f2d47a"]][mini(profile, 2)]
    var leaves: Array = ["4f7a40", "5c8749"]
    _lobe(body, Vector3(0, 0.42, 0), Vector3(0.95, 0.8, 0.9), Color(leaves[0]))
    for i in range(3):
        var a := TAU * i / 3.0 + 0.4
        _lobe(body, Vector3(cos(a) * 0.32, 0.35, sin(a) * 0.3), Vector3(0.6, 0.55, 0.55), Color(leaves[i % 2]))
    # Blooms sit on the outer surface of the foliage dome.
    for i in range(9):
        var a := _rng.randf_range(0.0, TAU)
        var up := _rng.randf_range(0.25, 1.0)
        var dir := Vector3(cos(a) * sqrt(1.0 - up * up), up, sin(a) * sqrt(1.0 - up * up))
        _lobe(body, Vector3(0, 0.42, 0) + dir * Vector3(0.5, 0.42, 0.47), Vector3(0.2, 0.17, 0.2), Color(blooms[i % 2]))

func _fern(body: Node3D) -> void:
    var greens: Array = ["4f8a3e", "63994c"]
    var fronds := 9
    for i in range(fronds):
        var a := TAU * i / fronds + _rng.randf_range(-0.15, 0.15)
        var reach := _rng.randf_range(0.65, 0.85)
        var lift := _rng.randf_range(28.0, 42.0)
        # Long flat leaflet rising from the center, arching out and slightly down at the tip.
        var frond := Node3D.new()
        frond.rotation = Vector3(0, -a, 0)
        body.add_child(frond)
        _lobe(frond, Vector3(reach * 0.45, 0.22, 0), Vector3(reach, 0.06, 0.24), Color(greens[i % 2]), Vector3(0, 0, lift))
        _lobe(frond, Vector3(reach * 0.95, 0.36, 0), Vector3(reach * 0.55, 0.05, 0.18), Color(greens[(i + 1) % 2]), Vector3(0, 0, -12.0))
    _bounds = AABB(Vector3(-0.85, 0, -0.85), Vector3(1.7, 0.6, 1.7))
    _lobe(body, Vector3(0, 0.12, 0), Vector3(0.3, 0.24, 0.3), Color("4f7a40"))
