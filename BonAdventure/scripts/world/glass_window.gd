@tool
extends Node3D
## Reusable window (user request, 12 Nov 2026; docs/guides/WINDOWS.md). Drop scenes/props/window.tscn
## into a wall opening and set the exports: every window in town draws its glass with ONE shared
## material (materials/glass/window_glass.tres), so render_culling.gd merges all the panes of a
## 24 m cell into one MultiMesh draw. See-through glass is ONE sheet (13 Nov 2026) drawn from both
## sides by window_glass.gdshader: with `outside` set, the outdoors face is dark and reflective and
## the room face light and clear. It casts no shadow, has no collision and no per-frame code.
##
## The panes and the optional frame are built at load from code (as electrical_box.gd does), so a
## unit scene stores only this root, its exports and metas. Sizes are town units (scale 1.3).
## Origin: the centre of the rectangular pane; the glass lies in the local XY plane, thickness on Z.
## shape ARCH adds a half disc of radius width / 2 on top of the rectangle.
##
## Cheaper glass: the project setting `vocabulary_town/rendering/glass_mode` = "opaque" (read at
## load) draws every window with materials/glass/window_glass_opaque.tres instead: no
## transparency pass, the old tinted look. `see_through = false` does the same for one window
## whose glass sits on a solid wall (nothing to see behind it).

## Every window joins this group.
const GROUP := "glass_windows"
const GLASS := preload("res://materials/glass/window_glass.tres")
const GLASS_OPAQUE := preload("res://materials/glass/window_glass_opaque.tres")
const FRAME := preload("res://materials/glass/window_frame.tres")
const MODE_SETTING := "vocabulary_town/rendering/glass_mode"
## The tint and transparency of the shared material (a window that keeps both uses the .tres).
const DEFAULT_TINT := Color(0.66, 0.78, 0.86)
const DEFAULT_TRANSPARENCY := 0.7
const DEFAULT_FRAME_COLOR := Color(0.93, 0.945, 0.95)
## The outdoors face of the glass (`outside` set): dark slate, mostly opaque.
const DEFAULT_OUTSIDE_TINT := Color(0.17, 0.2, 0.22)
const DEFAULT_OUTSIDE_TRANSPARENCY := 0.2
## Behind the opaque look: the tint darkened as if by an unlit room.
const ROOM_DARK := Color(0.16, 0.2, 0.24)
const ARCH_SEGMENTS := 16
## Marks the nodes this script builds (rebuilt on every load, never saved).
const PART_META := "glass_window_part"

enum Shape { RECT, ARCH }
## Which face of the glass looks outdoors: NONE = both faces look the same (tint, transparency).
enum Outside { NONE, FRONT, BACK }

@export var width := 1.2:
	set(value):
		width = maxf(value, 0.01)
		_rebuild()
@export var height := 1.4:
	set(value):
		height = maxf(value, 0.01)
		_rebuild()
@export var thickness := 0.04:
	set(value):
		thickness = maxf(value, 0.002)
		_rebuild()
@export var shape := Shape.RECT:
	set(value):
		shape = value
		_rebuild()
@export_group("Glass")
@export var tint := DEFAULT_TINT:
	set(value):
		tint = value
		_rebuild()
## The room-side look (both sides when `outside` is NONE). 0 = solid colour, 1 = invisible.
## About 0.6–0.75 reads as glass.
@export_range(0.0, 1.0, 0.01) var transparency := DEFAULT_TRANSPARENCY:
	set(value):
		transparency = value
		_rebuild()
## false: this pane is drawn opaque (its glass sits on a wall, or it must hide what is behind).
@export var see_through := true:
	set(value):
		see_through = value
		_rebuild()
## The face that looks outdoors (FRONT = +Z, BACK = -Z): drawn darker and more reflective,
## with outside_tint and outside_transparency; the other face uses tint and transparency.
@export var outside := Outside.NONE:
	set(value):
		outside = value
		_rebuild()
@export var outside_tint := DEFAULT_OUTSIDE_TINT:
	set(value):
		outside_tint = value
		_rebuild()
@export_range(0.0, 1.0, 0.01) var outside_transparency := DEFAULT_OUTSIDE_TRANSPARENCY:
	set(value):
		outside_transparency = value
		_rebuild()
@export_group("Frame")
@export var frame_visible := false:
	set(value):
		frame_visible = value
		_rebuild()
@export var frame_width := 0.08:
	set(value):
		frame_width = maxf(value, 0.005)
		_rebuild()
@export var frame_depth := 0.1:
	set(value):
		frame_depth = maxf(value, 0.005)
		_rebuild()
@export var frame_color := DEFAULT_FRAME_COLOR:
	set(value):
		frame_color = value
		_rebuild()

## Shared resources: one unit box and one unit half disc for every window, and one material
## per distinct look (custom tints and frame colours are cached, never one per window).
static var _unit_box: BoxMesh
static var _unit_half_disc: ArrayMesh
static var _unit_quad: QuadMesh
static var _unit_half_disc_front: ArrayMesh
static var _materials := {}


func _ready() -> void:
	add_to_group(GROUP)
	_build()


func _rebuild() -> void:
	if is_inside_tree():
		_build()


## The glass as built: one MeshInstance3D, or two for an arch (rectangle + half disc).
func glass_meshes() -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	for child in get_children():
		if child.has_meta(PART_META) and child.get_meta(PART_META) == "glass":
			found.append(child)
	return found


func _build() -> void:
	for child in get_children():
		if child.has_meta(PART_META):
			remove_child(child)
			child.free()
	var glass := glass_material()
	var r := width * 0.5
	if glass is ShaderMaterial:
		# See-through: one sheet in the pane's middle plane, both faces drawn by the shader.
		_part("Glass", "glass", unit_quad(), Transform3D(Basis.from_scale(Vector3(width, height, 1)), Vector3.ZERO), glass, false)
		if shape == Shape.ARCH:
			_part("Glass arch", "glass", unit_half_disc_front(), Transform3D(Basis.from_scale(Vector3(r, r, 1)), Vector3(0, height * 0.5, 0)), glass, false)
	else:
		# Opaque (on a wall, or the cheap glass mode): a thin box.
		_part("Glass", "glass", unit_box(), Transform3D(Basis.from_scale(Vector3(width, height, thickness)), Vector3.ZERO), glass, false)
		if shape == Shape.ARCH:
			_part("Glass arch", "glass", unit_half_disc(), Transform3D(Basis.from_scale(Vector3(r, r, thickness)), Vector3(0, height * 0.5, 0)), glass, false)
	if frame_visible:
		_build_frame()


func _build_frame() -> void:
	var mat := frame_material()
	var fw := frame_width
	var fd := frame_depth
	var hw := width * 0.5
	var hh := height * 0.5
	_bar(Vector3(0, -hh - fw * 0.5, 0), Vector3(width + fw * 2.0, fw, fd), 0.0, mat)
	_bar(Vector3(-hw - fw * 0.5, 0, 0), Vector3(fw, height, fd), 0.0, mat)
	_bar(Vector3(hw + fw * 0.5, 0, 0), Vector3(fw, height, fd), 0.0, mat)
	if shape == Shape.RECT:
		_bar(Vector3(0, hh + fw * 0.5, 0), Vector3(width + fw * 2.0, fw, fd), 0.0, mat)
		return
	# Arch: short bars along the half circle, each tangent to it.
	var r := hw + fw * 0.5
	var step := PI / 8.0
	var length := 2.0 * r * tan(step * 0.5) + fw * 0.2
	for i in range(8):
		var a := step * (i + 0.5)
		_bar(Vector3(cos(a) * r, hh + sin(a) * r, 0), Vector3(fw, length, fd), a, mat)


func _bar(at: Vector3, size: Vector3, angle: float, mat: Material) -> void:
	_part("Frame", "frame", unit_box(), Transform3D(Basis(Vector3.BACK, angle) * Basis.from_scale(size), at), mat, true)


func _part(title: String, kind: String, mesh: Mesh, pose: Transform3D, mat: Material, shadow: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.transform = pose
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_meta(PART_META, kind)
	add_child(node)
	return node


static func opaque_mode() -> bool:
	return str(ProjectSettings.get_setting(MODE_SETTING, "transparent")) == "opaque"


## The material for this window's glass: the shared file unless its look was customised.
func glass_material() -> Material:
	var opaque := not see_through or opaque_mode()
	var plain := tint.is_equal_approx(DEFAULT_TINT) and is_equal_approx(transparency, DEFAULT_TRANSPARENCY)
	if opaque:
		# The opaque look shows the outdoors tint when there is one (that is the face people see).
		var face := outside_tint if outside != Outside.NONE else tint
		var amount := outside_transparency if outside != Outside.NONE else transparency
		if plain and outside == Outside.NONE:
			return GLASS_OPAQUE
		var opaque_key := ["opaque", face.to_html(false), snappedf(amount, 0.01)]
		if not _materials.has(opaque_key):
			var flat: StandardMaterial3D = GLASS_OPAQUE.duplicate()
			flat.resource_name = "Window glass %s" % face.to_html(false)
			flat.albedo_color = face.lerp(ROOM_DARK, amount * 0.45)
			_materials[opaque_key] = flat
		return _materials[opaque_key]
	if plain and outside == Outside.NONE:
		return GLASS
	var key := ["glass", tint.to_html(false), snappedf(transparency, 0.01), outside,
		outside_tint.to_html(false), snappedf(outside_transparency, 0.01)]
	if not _materials.has(key):
		var mat: ShaderMaterial = GLASS.duplicate()
		mat.resource_name = "Window glass %s" % tint.to_html(false)
		mat.set_shader_parameter("inside_tint", Color(tint, 1.0 - transparency))
		mat.set_shader_parameter("outside_face", int(outside))
		mat.set_shader_parameter("outside_tint", Color(outside_tint, 1.0 - outside_transparency))
		_materials[key] = mat
	return _materials[key]


func frame_material() -> Material:
	if frame_color.is_equal_approx(DEFAULT_FRAME_COLOR):
		return FRAME
	var key := ["frame", frame_color.to_html(false)]
	if not _materials.has(key):
		var mat: StandardMaterial3D = FRAME.duplicate()
		mat.albedo_color = frame_color
		_materials[key] = mat
	return _materials[key]


static func unit_box() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
	return _unit_box


## A 1 x 1 sheet facing +Z (see-through glass).
static func unit_quad() -> QuadMesh:
	if _unit_quad == null:
		_unit_quad = QuadMesh.new()
	return _unit_quad


## One flat half disc facing +Z (see-through glass): radius 1, in the plane z = 0.
static func unit_half_disc_front() -> ArrayMesh:
	if _unit_half_disc_front != null:
		return _unit_half_disc_front
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.BACK)
	for i in range(ARCH_SEGMENTS):
		var a0 := PI * i / ARCH_SEGMENTS
		var a1 := PI * (i + 1) / ARCH_SEGMENTS
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(cos(a1), sin(a1), 0))
		st.add_vertex(Vector3(cos(a0), sin(a0), 0))
	_unit_half_disc_front = st.commit()
	return _unit_half_disc_front


## Upper half of a disc: radius 1, from z -0.5 to 0.5, flat side on y = 0 (open there: it sits on
## the rectangle's top face).
static func unit_half_disc() -> ArrayMesh:
	if _unit_half_disc != null:
		return _unit_half_disc
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(ARCH_SEGMENTS):
		var a0 := PI * i / ARCH_SEGMENTS
		var a1 := PI * (i + 1) / ARCH_SEGMENTS
		var p0 := Vector3(cos(a0), sin(a0), 0)
		var p1 := Vector3(cos(a1), sin(a1), 0)
		for side in [1.0, -1.0]:
			var z := Vector3(0, 0, 0.5 * side)
			# Godot's front faces wind clockwise as seen from outside.
			st.set_normal(Vector3(0, 0, side))
			if side > 0:
				st.add_vertex(z)
				st.add_vertex(p1 + z)
				st.add_vertex(p0 + z)
			else:
				st.add_vertex(z)
				st.add_vertex(p0 + z)
				st.add_vertex(p1 + z)
		# Rim between the two faces.
		var f0 := p0 + Vector3(0, 0, 0.5)
		var f1 := p1 + Vector3(0, 0, 0.5)
		var b0 := p0 - Vector3(0, 0, 0.5)
		var b1 := p1 - Vector3(0, 0, 0.5)
		st.set_normal(((p0 + p1) * 0.5).normalized())
		for v in [f0, b1, b0, f0, f1, b1]:
			st.add_vertex(v)
	_unit_half_disc = st.commit()
	return _unit_half_disc
