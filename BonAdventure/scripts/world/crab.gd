extends Node3D
## Stylised beach crab (word "crab"). The body is one shared ArrayMesh with vertex colours
## (carapace, claws, eye stalks and six legs), so each crab costs a single draw call.
## It faces local +Z and scuttles sideways along local X on a short line, pausing between
## runs; `home` is the centre of that line, as for the other wandering animals.
## Saved in the base world (first placed by the deleted coast.gd); the picking Area3D is a child of this word root.

const SHELL := Color("d9573f")
const SHELL_LIGHT := Color("e8765c")
const CLAW := Color("cc4733")
const LEG := Color("c94b36")
const BELLY := Color("f0d3a8")
const EYE_WHITE := Color("f4f1e6")
const PUPIL := Color("262a2e")
## Whole-crab scale: the mesh is about 0.62 m across, between a field mouse and a hen.
const SIZE := 0.72

static var _mesh: ArrayMesh
static var _material: StandardMaterial3D

var home := Vector3.ZERO
var clock := 0.0
@export_range(0.0, 3.0) var radius := 0.7
@export_range(0.0, 3.0) var speed := 0.5
var _body: MeshInstance3D
var _player: Node3D

func _ready() -> void:
    set_meta("word_key", "crab")
    set_meta("display_size", Vector3(.62, .4, .4))
    _body = MeshInstance3D.new()
    _body.name = "Body"
    _body.mesh = body_mesh()
    if _material == null:
        _material = StandardMaterial3D.new()
        _material.vertex_color_use_as_albedo = true
        _material.roughness = .7
    _body.material_override = _material
    add_child(_body)
    var area := Area3D.new()
    area.name = "VocabularyArea"
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(.72, .42, .5)
    shape.shape = box
    shape.position = Vector3(0, .2, .06)
    area.add_child(shape)
    add_child(area)
    home = position
    clock = float(get_index()) * 2.3 + position.x * .37

func _process(delta: float) -> void:
    # Crabs are solid to the player (house_characters.gd FigureBlocker): wait rather than
    # scuttle into the learner and shove them.
    var next_clock := clock + delta * speed
    var next := home + basis.x.normalized() * sin(next_clock) * radius
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
    var player := _player
    if player != null and is_inside_tree() and get_parent() is Node3D:
        var gap: Vector3 = (get_parent() as Node3D).to_global(next) - player.global_position
        if absf(gap.y) < 2.5 and Vector2(gap.x, gap.z).length() < 1.4 and Vector2(gap.x, gap.z).length() < Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z).length():
            return
    clock = next_clock
    # Runs and pauses: the sideways offset eases to rest at both ends of every swing.
    var swing := sin(clock)
    var moving := absf(cos(clock))
    position = next
    _body.position.y = absf(sin(clock * 14.0)) * .012 * moving
    _body.rotation.z = sin(clock * 14.0) * .03 * moving

static func body_mesh() -> ArrayMesh:
    if _mesh != null: return _mesh
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var colors := PackedColorArray()
    var indices := PackedInt32Array()
    var sphere := SphereMesh.new()
    sphere.radial_segments = 12
    sphere.rings = 6
    var cylinder := CylinderMesh.new()
    cylinder.radial_segments = 6
    cylinder.rings = 1
    cylinder.cap_top = false
    cylinder.cap_bottom = false
    var parts: Array = []
    # [centre, radii (x, y, z), colour]
    var blobs := [
        [Vector3(0, .18, 0), Vector3(.25, .125, .195), SHELL],
        [Vector3(0, .235, -.01), Vector3(.2, .095, .155), SHELL_LIGHT],
        [Vector3(0, .1, 0), Vector3(.23, .075, .18), BELLY],
    ]
    for side in [-1.0, 1.0]:
        # Eye stalks, eyeballs and pupils.
        blobs.append([Vector3(side * .1, .4, .18), Vector3(.05, .05, .05), EYE_WHITE])
        blobs.append([Vector3(side * .1, .405, .225), Vector3(.026, .026, .026), PUPIL])
        # Claw: palm plus two prongs that leave a gap.
        blobs.append([Vector3(side * .33, .25, .34), Vector3(.1, .075, .11), CLAW])
        blobs.append([Vector3(side * .285, .3, .47), Vector3(.04, .03, .09), CLAW])
        blobs.append([Vector3(side * .385, .25, .47), Vector3(.04, .03, .09), CLAW])
    var limbs := []
    for side in [-1.0, 1.0]:
        limbs.append([Vector3(side * .09, .27, .13), Vector3(side * .1, .37, .17), .018, SHELL])
        limbs.append([Vector3(side * .2, .2, .1), Vector3(side * .3, .24, .27), .03, CLAW])
        for z in [-.11, 0.0, .1]:
            limbs.append([Vector3(side * .2, .17, z), Vector3(side * .36, .3, z - .03), .013, LEG])
            limbs.append([Vector3(side * .36, .3, z - .03), Vector3(side * .47, .02, z - .08), .012, LEG])
    for blob in blobs:
        var basis := Basis.from_scale(blob[1] * 2.0)
        parts.append([sphere.get_mesh_arrays(), Transform3D(basis, blob[0]), blob[2]])
    for limb in limbs:
        var from: Vector3 = limb[0]
        var to: Vector3 = limb[1]
        var axis := (to - from).normalized()
        var side_axis := axis.cross(Vector3.UP if absf(axis.y) < .95 else Vector3.RIGHT).normalized()
        var basis := Basis(side_axis, axis, side_axis.cross(axis)) * Basis.from_scale(Vector3(limb[2] * 2.0, from.distance_to(to) * .5, limb[2] * 2.0))
        parts.append([cylinder.get_mesh_arrays(), Transform3D(basis, (from + to) * .5), limb[3]])
    for part in parts:
        var arrays: Array = part[0]
        var xform: Transform3D = part[1]
        xform.origin *= SIZE
        xform.basis = xform.basis.scaled(Vector3.ONE * SIZE)
        var first := vertices.size()
        var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        for i in range(source.size()):
            vertices.append(xform * source[i])
            normals.append((xform.basis * source_normals[i]).normalized())
            colors.append(part[2])
        for index in arrays[Mesh.ARRAY_INDEX] as PackedInt32Array: indices.append(first + index)
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices
    _mesh = ArrayMesh.new()
    _mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return _mesh
