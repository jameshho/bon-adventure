extends Node3D
## Sectional overhead garage door. Hinged sections ride side tracks: straight up the
## opening, round a short bend, then back horizontally under the ceiling. Main toggles
## it with E (aimed at the door, or standing at it); a press mid-travel just reverses
## the motion, so repeated presses never break the animation. Local frame: +X across the
## opening, +Y up, +Z out of the garage; the closed door's bottom edge is the origin.

@export var width := 8.2
@export var opening_height := 2.9
@export var sections := 5
@export var curve_radius := .4
@export var travel_seconds := 2.6
var is_open := false
var progress := 0.0 # 0 closed .. 1 open, eased when placing the sections
var on_blocked := Callable() # called when a closing door reverses for someone in the way
var _panels: Array[Node3D] = []
var _bodies: Array[RID] = []

func build(material_for: Callable, color: Color) -> void:
	set_meta("word_key", "door")
	var h := opening_height / sections
	var face: Material = material_for.call(color)
	var raised: Material = material_for.call(color.lightened(.25))
	var glass: Material = material_for.call(Color("6f8f9c"))
	var trim: Material = material_for.call(Color("4b4f52"))
	var strut: Material = material_for.call(Color("9aa0a4"))
	for i in range(sections):
		var panel := Node3D.new()
		panel.name = "Section %d" % (i + 1)
		add_child(panel)
		# A hairline gap between sections reads as the hinge line.
		_mesh(panel, Vector3.ZERO, Vector3(width, h - .014, .06), face)
		# Four raised panels per section on the street face; the top row is glazed.
		var cell := (width - .5) / 4.0
		for c in range(4):
			var x := -width / 2 + .25 + cell * (c + .5)
			_mesh(panel, Vector3(x, 0, .035), Vector3(cell - .16, h * .56, .02), glass if i == sections - 1 else raised)
		# A steel strut on the garage side keeps the stowed door readable against the ceiling.
		_mesh(panel, Vector3(0, h * .3, -.045), Vector3(width - .4, .08, .03), strut)
		if i == 0:
			_mesh(panel, Vector3(0, -h / 2 + .01, 0), Vector3(width, .03, .08), trim) # weather seal
			_mesh(panel, Vector3(0, -.06, .06), Vector3(.4, .05, .05), trim) # lift handle
		var body := StaticBody3D.new()
		panel.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(width, h, .08)
		collision.shape = shape
		body.add_child(collision)
		body.set_meta("object_name", "Garage door")
		body.set_meta("root", self)
		body.set_meta("word", "door")
		_panels.append(panel)
		_bodies.append(body.get_rid())
	_place()

func _mesh(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)

## Loaded from a saved town (modular town, 6 Nov 2026): build() ran when it was baked, so find
## its sections and their bodies again.
func _ready() -> void:
	if not _panels.is_empty():
		return
	for i in range(sections):
		var panel := get_node_or_null("Section %d" % (i + 1)) as Node3D
		if panel == null:
			continue
		_panels.append(panel)
		for body in panel.find_children("*", "StaticBody3D", false, false):
			_bodies.append(body.get_rid())
	if not _panels.is_empty():
		_place()

func toggle() -> void:
	is_open = not is_open

## Point at arc length `s` along the track, in this node's frame.
func path_point(s: float) -> Vector3:
	var bend := PI / 2 * curve_radius
	if s <= opening_height:
		return Vector3(0, s, 0)
	if s <= opening_height + bend:
		var angle := (s - opening_height) / curve_radius
		return Vector3(0, opening_height + curve_radius * sin(angle), -curve_radius * (1 - cos(angle)))
	return Vector3(0, opening_height + curve_radius, -curve_radius - (s - opening_height - bend))

## Fully open, every section lies on the horizontal run, clear of the opening.
func travel() -> float:
	return opening_height + PI / 2 * curve_radius + .05

func track_length() -> float:
	return travel() + opening_height + .2

func is_near(point: Vector3) -> bool:
	var p := to_local(point)
	return absf(p.x) < width / 2 + .6 and absf(p.z) < 2.4 and p.y < opening_height

func is_outside(point: Vector3) -> bool:
	return to_local(point).z > 0

func _physics_process(delta: float) -> void:
	var target := 1.0 if is_open else 0.0
	if progress == target:
		return
	var next := move_toward(progress, target, delta / travel_seconds)
	# A closing door stops and reopens rather than pressing into someone below it.
	if not is_open and _bottom_blocked(next):
		is_open = true
		if on_blocked.is_valid():
			on_blocked.call()
		return
	progress = next
	_place()

func _place() -> void:
	var h := opening_height / sections
	var offset := travel() * smoothstep(0.0, 1.0, progress)
	for i in range(_panels.size()):
		var a := path_point(i * h + offset)
		var b := path_point((i + 1) * h + offset)
		var up := (b - a).normalized()
		# Sections pivot as they round the bend; their street face ends up facing the ceiling.
		_panels[i].transform = Transform3D(Basis(Vector3.RIGHT, up, Vector3.RIGHT.cross(up)), (a + b) / 2)

func _bottom_blocked(next_progress: float) -> bool:
	var h := opening_height / sections
	var offset := travel() * smoothstep(0.0, 1.0, next_progress)
	if offset >= opening_height:
		return false
	var shape := BoxShape3D.new()
	shape.size = Vector3(width - .2, h, .3) * global_basis.get_scale().abs()
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.exclude = _bodies
	query.transform = Transform3D(global_basis.orthonormalized(), to_global(path_point(offset + h / 2)))
	for hit in get_world_3d().direct_space_state.intersect_shape(query):
		if hit.collider is CharacterBody3D or hit.collider is RigidBody3D:
			return true
	return false
