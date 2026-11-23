@tool
extends Node3D
## Reusable door (user request, 13 Nov 2026; docs/guides/DOORS.md). Three scenes share this script's
## look, so every door in town is the same door in its own colours:
##   scenes/props/door.tscn         this script: one hinged leaf
##   scenes/props/double_door.tscn  scripts/world/double_door.gd: two leaves opening together
##   scenes/props/sliding_door.tscn scripts/world/sliding_door.gd: one leaf sliding along the wall
## Drop a scene into a wall opening and set width and height to the CLEAR opening: the frame lines
## the opening from outside it and the leaf fills it exactly, so there is no gap between frame
## and door. Sizes are in the parent's units (town units, scale 1.3 above the town).
## Origin: the floor at the middle of the opening. The wall lies in the local XY plane, its
## thickness on Z; +Z is the "front" (swing_to_front).
##
## The frame, leaf, handles, sign and collision are built at load from code (as glass_window.gd),
## so a unit scene stores only this root, its exports and metas (tools/bake_unit.gd strips the
## parts). An interactive door's leaf gets a `door_state` meta when it is built; Main collects it
## (DoorAnimator.restore_editor_door_states) and the leaf becomes an interactable (E, click, tap).
## Every part uses one shared unit box mesh and one material per colour, so render_culling.gd
## merges the frames of a cell into a few draws (the moving leaves keep their own draws).

const GROUP := "doors"
## Marks the nodes this script builds (rebuilt on every load, never saved).
const PART_META := "door_part"
const WINDOW := preload("res://scenes/props/window.tscn")
const DEFAULT_LEAF := Color("f1ede4")
const DEFAULT_FRAME := Color("f0e7d7")
const DEFAULT_HANDLE := Color("b8bfc4")
## A frame stands this far proud of each wall face, so it never shares a face with the wall.
const FRAME_PROUD := 0.015
## Handle height above the floor (town units), lowered on short doors.
const HANDLE_Y := 1.0

enum Hinge { LEFT, RIGHT }
enum Sign { NONE, WOMEN, MEN }

## Clear opening between the jambs and from the floor to the head.
@export var width := 0.9:
	set(value):
		width = maxf(value, 0.1)
		_rebuild()
@export var height := 2.1:
	set(value):
		height = maxf(value, 0.1)
		_rebuild()
## Thickness of the wall around the opening (the frame is this deep plus a little).
@export var wall_thickness := 0.2:
	set(value):
		wall_thickness = maxf(value, 0.01)
		_rebuild()
## false: the door never opens (a closed door, still the word "door" and solid).
@export var interactive := true:
	set(value):
		interactive = value
		_rebuild()
## Name of the leaf node (the hinge pivot; double doors add " left" / " right").
@export var leaf_name := "Leaf":
	set(value):
		leaf_name = value
		_rebuild()
@export_group("Leaf")
@export var leaf_color := DEFAULT_LEAF:
	set(value):
		leaf_color = value
		_rebuild()
@export var leaf_thickness := 0.05:
	set(value):
		leaf_thickness = maxf(value, 0.01)
		_rebuild()
## true: the upper part of the leaf is glass (the shared window glass).
@export var vision_glass := false:
	set(value):
		vision_glass = value
		_rebuild()
@export var handle_color := DEFAULT_HANDLE:
	set(value):
		handle_color = value
		_rebuild()
## A restroom figure on both faces.
@export var sign := Sign.NONE:
	set(value):
		sign = value
		_rebuild()
@export_group("Swing")
## Hinged edge, seen from the front (+Z). Not used by double and sliding doors.
@export var hinge := Hinge.LEFT:
	set(value):
		hinge = value
		_rebuild()
## true: the leaf swings toward +Z; false: toward -Z. Not used by sliding doors.
@export var swing_to_front := true:
	set(value):
		swing_to_front = value
		_rebuild()
@export_range(0.5, 2.0, 0.01) var open_angle := 1.6:
	set(value):
		open_angle = value
		_rebuild()
## 0: the usual quick swing. Above 0: a heavy door (the bank vault, 23 Nov 2026) that takes this
## many seconds to swing, starting slowly and settling softly (door_animator.gd "seconds").
@export_range(0.0, 8.0, 0.1) var swing_seconds := 0.0:
	set(value):
		swing_seconds = maxf(value, 0.0)
		_rebuild()
@export_group("Frame")
@export var frame_visible := true:
	set(value):
		frame_visible = value
		_rebuild()
@export var frame_width := 0.07:
	set(value):
		frame_width = maxf(value, 0.005)
		_rebuild()
@export var frame_color := DEFAULT_FRAME:
	set(value):
		frame_color = value
		_rebuild()

static var _unit_box: BoxMesh
static var _materials := {}


func _ready() -> void:
	add_to_group(GROUP)
	_build()


func _rebuild() -> void:
	if is_inside_tree():
		_build()


## The leaves as built (one, or two for a double door).
func leaves() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for child in get_children():
		if child.has_meta(PART_META) and child.get_meta(PART_META) == "leaf":
			found.append(child)
	return found


func _build() -> void:
	for child in get_children():
		if child.has_meta(PART_META):
			remove_child(child)
			child.free()
	if frame_visible:
		_build_frame()
	_build_leaves()


## Hinged single door: the pivot on the hinge jamb, the leaf running across the opening.
func _build_leaves() -> void:
	var dir := 1.0 if hinge == Hinge.LEFT else -1.0
	var leaf := _leaf_node(leaf_name, Vector3(-dir * width * 0.5, 0, 0))
	_leaf_parts(leaf, 0.0, dir * width, false)
	var angle := open_angle * -dir * (1.0 if swing_to_front else -1.0)
	var state := {"open": false, "type": "hinge", "angle": angle}
	if swing_seconds > 0.0:
		state["seconds"] = swing_seconds
	_register(leaf, state)


func _build_frame() -> void:
	var fw := frame_width
	var depth := wall_thickness + FRAME_PROUD * 2.0
	var mat := material(frame_color)
	for side in [-1.0, 1.0]:
		_box(self, "Door jamb", Vector3(side * (width + fw) * 0.5, (height + fw) * 0.5, 0), Vector3(fw, height + fw, depth), mat, "frame")
	_box(self, "Door head", Vector3(0, height + fw * 0.5, 0), Vector3(width + fw * 2.0, fw, depth), mat, "frame")


## A leaf root (pivot) at `at`: the word root "door", built part, later the door_state holder.
func _leaf_node(title: String, at: Vector3) -> Node3D:
	var leaf := Node3D.new()
	leaf.name = title
	leaf.position = at
	leaf.set_meta(PART_META, "leaf")
	leaf.set_meta("word_key", "door")
	add_child(leaf)
	return leaf


## The leaf's parts under `leaf`: a slab from x `x0` to `x1` (leaf-local), the full opening
## height, with two raised panels (or glass above one panel) and a handle on each face near
## the latch edge (the end away from the hinge, `x1`). `pull` = a bar pull (sliding doors).
func _leaf_parts(leaf: Node3D, x0: float, x1: float, pull: bool) -> void:
	var lw := absf(x1 - x0)
	var dir := signf(x1 - x0)
	var cx := (x0 + x1) * 0.5
	var t := leaf_thickness
	var h := height
	var mat := material(leaf_color)
	var panel_mat := material(leaf_color.darkened(0.07))
	var margin := clampf(lw * 0.14, 0.08, 0.18)
	var split := h * 0.44
	if vision_glass:
		# Stiles and rails around the glass, the lower part solid.
		_box(leaf, "Door stile", Vector3(x0 + dir * margin * 0.5, h * 0.5, 0), Vector3(margin, h, t), mat)
		_box(leaf, "Door stile", Vector3(x1 - dir * margin * 0.5, h * 0.5, 0), Vector3(margin, h, t), mat)
		_box(leaf, "Door rail", Vector3(cx, split * 0.5, 0), Vector3(lw - margin * 2.0, split, t), mat)
		_box(leaf, "Door rail", Vector3(cx, h - margin * 0.5, 0), Vector3(lw - margin * 2.0, margin, t), mat)
		var glass: Node3D = WINDOW.instantiate()
		glass.name = "Door glass"
		glass.set("width", lw - margin * 2.0)
		glass.set("height", h - margin - split)
		glass.set("thickness", t * 0.4)
		glass.position = Vector3(cx, (split + h - margin) * 0.5, 0)
		leaf.add_child(glass)
	else:
		_box(leaf, "Door slab", Vector3(cx, h * 0.5, 0), Vector3(lw, h, t), mat)
		var upper := Vector2(split + margin * 0.5, h - margin)
		for face in [-1.0, 1.0]:
			_box(leaf, "Door panel", Vector3(cx, (upper.x + upper.y) * 0.5, face * (t * 0.5 + 0.006)), Vector3(lw - margin * 2.0, upper.y - upper.x, 0.012), panel_mat)
	var lower := Vector2(margin, split - margin * 0.5)
	for face in [-1.0, 1.0]:
		_box(leaf, "Door panel", Vector3(cx, (lower.x + lower.y) * 0.5, face * (t * 0.5 + 0.006)), Vector3(lw - margin * 2.0, lower.y - lower.x, 0.012), panel_mat)
	# Handles on both faces near the latch edge.
	var handle_mat := material(handle_color)
	var hy := minf(HANDLE_Y, h * 0.45)
	var hx := x1 - dir * minf(0.09, lw * 0.15)
	for face in [-1.0, 1.0]:
		if pull:
			_box(leaf, "Door pull", Vector3(hx, hy + 0.1, face * (t * 0.5 + 0.035)), Vector3(0.03, 0.4, 0.03), handle_mat)
			for end in [-0.17, 0.17]:
				_box(leaf, "Door pull post", Vector3(hx, hy + 0.1 + end, face * (t * 0.5 + 0.017)), Vector3(0.025, 0.025, 0.035), handle_mat)
		else:
			_box(leaf, "Door rose", Vector3(hx, hy, face * (t * 0.5 + 0.008)), Vector3(0.05, 0.14, 0.016), handle_mat)
			_box(leaf, "Door lever", Vector3(hx - dir * 0.06, hy, face * (t * 0.5 + 0.035)), Vector3(0.15, 0.025, 0.03), handle_mat)
	if sign != Sign.NONE:
		var icon_mat := material(Color("d07fa0") if sign == Sign.WOMEN else Color("5f8fd0"))
		for face in [-1.0, 1.0]:
			var z: float = face * (t * 0.5 + 0.006)
			_box(leaf, "Door sign", Vector3(cx, h * 0.68, z), Vector3(0.22, 0.34, 0.012), icon_mat)
			_box(leaf, "Door sign head", Vector3(cx, h * 0.68 + 0.27, z), Vector3(0.13, 0.13, 0.012), icon_mat)
			if sign == Sign.WOMEN:
				_box(leaf, "Door sign skirt", Vector3(cx, h * 0.68 - 0.1, z), Vector3(0.34, 0.14, 0.012), icon_mat)
	# Collision: the slab, a pickable word root "door".
	var body := StaticBody3D.new()
	body.name = "Door body"
	body.set_meta("root", leaf)
	body.set_meta("word", "door")
	body.set_meta("object_name", name)
	leaf.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(lw, h, t)
	shape.shape = box
	shape.position = Vector3(cx, h * 0.5, 0)
	body.add_child(shape)


## Gives an interactive door's leaf its state (Main collects it at load).
func _register(leaf: Node3D, state: Dictionary) -> void:
	if interactive:
		leaf.set_meta("door_state", state)


func _box(parent: Node3D, title: String, at: Vector3, size: Vector3, mat: Material, kind := "") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = unit_box()
	node.transform = Transform3D(Basis.from_scale(size), at)
	node.material_override = mat
	if kind != "":
		node.set_meta(PART_META, kind)
	parent.add_child(node)
	return node


static func unit_box() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
	return _unit_box


## One material per colour for every door in town (never one per door).
static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html(true)
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.resource_name = "Door " + key
		mat.albedo_color = color
		mat.roughness = 0.82
		_materials[key] = mat
	return _materials[key]
