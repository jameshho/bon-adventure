@tool
class_name ElevatorCallButton
extends Node3D
## Reusable elevator call button (9 Nov 2026; guide: docs/guides/HOSPITAL_THREE_FLOORS.md "Elevator call
## buttons"). One per elevator and floor (scenes/props/fixtures/elevator_call_button.tscn); its face
## is local +Z. hospital_elevator.gd builds them on every landing and in the car (10 Nov 2026).
## E, a click or a tap (its interactable -> use()) calls `elevator` to `floor_index` through the elevator's
## call_elevator(). The button glows while that stop is called and goes dark when the car arrives.
##
## The lit state is never stored: every frame it is read from the elevator's own
## is_floor_requested(), so other buttons and the cabin keys keep it in step.
## A press while the stop is already called does nothing.
##
## Look (10 Nov 2026 rebuild, user: "improve the looks of the buttons"): a round ivory push
## button in a steel bezel with a halo ring that lights; a caption (a cabin button's stop number)
## is printed on the face, a landing button shows ▲▼ there instead. Lit, the face and halo glow.
## Optional brushed-steel wall plate (plate_size; zero = none, for buttons on a shared panel).
##
## Its parts are internal children built in _ready, so a bake (tools/bake_unit.gd) saves only the
## node and its exports. Silent itself: `pressed` is there for a click sound later.
## 14 Nov 2026 (user): cabin buttons (picker_on_e) answer E with the elevator's floor picker
## (scripts/ui/elevator_floor_picker.gd) and a click or tap still presses them; their pick box is
## 1.5x wider (pick_size) and an Area3D, so the player never catches on it.
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
signal pressed(floor_index: int)
signal lit_changed(lit: bool)

## The elevator node (hospital_elevator.gd or anything with call_elevator / is_floor_requested).
@export var elevator: NodePath
## The stop this button calls (index into the elevator's floor_ys).
@export var floor_index := 0
## Glow of the face and halo while the stop is called (landing: warm amber).
@export var glow_color := Color("ff9a2e"):
	set(value):
		glow_color = value
		_paint()
@export_range(0.0, 8.0, 0.1) var glow_energy := 2.4:
	set(value):
		glow_energy = value
		_paint()
## Soft light thrown on the wall while lit (0 = emission only, cheapest).
@export_range(0.0, 4.0, 0.05) var light_energy := 0.45
@export_range(0.1, 4.0, 0.05) var light_range := 1.3
## Face colour while dark (ivory push button).
@export var idle_color := Color("e9e7e0"):
	set(value):
		idle_color = value
		_paint()
## Number / arrow print on the face.
@export var mark_color := Color("2b3236"):
	set(value):
		mark_color = value
		_paint()
## Brushed steel of the wall plate and bezel.
@export var plate_color := Color("c3c7c9"):
	set(value):
		plate_color = value
		_paint()
## Wall plate width × height (town units); Vector2.ZERO: no plate (a button on a shared panel).
@export var plate_size := Vector2(0.3, 0.5):
	set(value):
		plate_size = value
		_rebuild()
## Radius of the round push button.
@export var button_radius := 0.085:
	set(value):
		button_radius = value
		_rebuild()
## Pick (click / tap) box width × height on the face; Vector2.ZERO: the plate, or 2.8 × the
## radius square round a button without one. Cabin buttons get 1.5× that (14 Nov 2026, user),
## clipped to the button pitch so neighbours never overlap (hospital_elevator.gd).
@export var pick_size := Vector2.ZERO:
	set(value):
		pick_size = value
		_rebuild()
## E (the key or the touch E button) opens the elevator's floor picker instead of pressing this
## button (cabin buttons, 14 Nov 2026); a click or a tap still presses it.
@export var picker_on_e := false
## Text printed on the face (a cabin button's stop: "1", "A"); empty shows ▲▼ marks instead.
@export var caption := "":
	set(value):
		caption = value
		_rebuild()
## Seconds the glow takes to fade in or out.
const FADE := 0.15
const PLATE_DEPTH := 0.014
## Halo ring colour while dark.
const RING_IDLE := Color("3a4146")

var _parts: Node3D
var _face_mat: StandardMaterial3D
var _ring_mat: StandardMaterial3D
var _plate_mat: StandardMaterial3D
var _bezel_mat: StandardMaterial3D
var _mark_mat: StandardMaterial3D
var _caption: Label3D
var _light: OmniLight3D
var _glow := 0.0
var _lit := false

func _ready() -> void:
	if not has_meta("word_key"):
		set_meta("word_key", "elevator")
	set_meta("elevator_call_button", true)
	_rebuild()
	# E, a click or a tap calls the lift (interaction system, 12 Nov 2026).
	if not Engine.is_editor_hint():
		# A landing button answers from the middle of its doorway (2.75 m away in the hospital);
		# the car's panel buttons sit side by side, so they need aiming, and reach across the
		# hospital's big cabin (about 4 m from its middle; keys 1-4 also choose a floor there).
		Interactable.attach(self, {
			"prompt_distance": 4.2 if caption != "" else 3.2,
			"needs_aim": caption != "",
			"priority": 0.3,
			"badge_offset": InteractIcons.local_center(self, Vector3(0, 0, 0.05)),
		})
	_lit = is_lit()
	_glow = 1.0 if _lit else 0.0
	_paint()

func target() -> Node:
	return get_node_or_null(elevator) if not elevator.is_empty() else null

## Whether the elevator has this stop called and not yet reached (live, never cached).
func is_lit() -> bool:
	var lift := target()
	return lift != null and lift.has_method("is_floor_requested") and lift.is_floor_requested(floor_index)

## Its interactable's use (E, a click or a tap). Returns true when the call was accepted.
## A cabin button (picker_on_e) answers E with the floor picker (the user's "E at the panel");
## "use" is held only while E or the touch E button is down, never for a click or a tap.
func use() -> bool:
	if picker_on_e and Input.is_action_pressed("use"):
		var lift := target()
		if lift != null and lift.has_method("open_floor_picker") and lift.open_floor_picker():
			return true
	return press()

## The pick box's width × height (face plane, local units).
func pick_extent() -> Vector2:
	if pick_size.x > 0.0 and pick_size.y > 0.0:
		return pick_size
	if plate_size.x > 0.0 and plate_size.y > 0.0:
		return plate_size
	return Vector2(button_radius * 2.8, button_radius * 2.8)

func press() -> bool:
	var lift := target()
	if lift == null or not lift.has_method("call_elevator") or is_lit():
		return false
	lift.call_elevator(floor_index)
	_update(0.0)
	if not _lit:
		return false
	pressed.emit(floor_index)
	return true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update(delta)

func _update(delta: float) -> void:
	var now := is_lit()
	if now != _lit:
		_lit = now
		lit_changed.emit(_lit)
	var goal := 1.0 if _lit else 0.0
	if _glow != goal:
		_glow = move_toward(_glow, goal, delta / FADE) if delta > 0.0 else _glow
		_paint()

func _material(metal: float, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.metallic = metal
	mat.roughness = rough
	# Per button, and kept out of a bake's shared palette (tools/material_palette.gd skips these).
	mat.resource_local_to_scene = true
	return mat

func _disc(radius: float, height: float, z: float, mat: Material) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 32
	cylinder.rings = 1
	disc.mesh = cylinder
	disc.material_override = mat
	# Cylinder axis along +Z (the face direction).
	disc.rotation.x = PI / 2.0
	disc.position.z = z + height / 2.0
	_parts.add_child(disc)
	return disc

func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _parts != null:
		_parts.free()
	# Internal: not saved by a bake or the editor, rebuilt here at every load.
	_parts = Node3D.new()
	_parts.name = "Parts"
	add_child(_parts, false, Node.INTERNAL_MODE_FRONT)
	_plate_mat = _material(0.5, 0.38)
	_bezel_mat = _material(0.6, 0.28)
	_face_mat = _material(0.0, 0.35)
	_face_mat.emission_enabled = true
	_ring_mat = _material(0.2, 0.3)
	_ring_mat.emission_enabled = true
	_mark_mat = _material(0.0, 0.6)
	var r := button_radius
	var has_plate := plate_size.x > 0.0 and plate_size.y > 0.0
	var base := PLATE_DEPTH if has_plate else 0.0
	if has_plate:
		var plate := MeshInstance3D.new()
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(plate_size.x, plate_size.y, PLATE_DEPTH)
		plate.mesh = plate_mesh
		plate.material_override = _plate_mat
		plate.position.z = PLATE_DEPTH / 2.0
		_parts.add_child(plate)
	# Steel bezel, then the glowing halo ring round the button, then the push button itself
	# (each a few millimetres prouder than the last: no shared planes).
	_disc(r + 0.02, 0.01, base, _bezel_mat)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = r + 0.002
	torus.outer_radius = r + 0.014
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = _ring_mat
	ring.rotation.x = PI / 2.0
	ring.position.z = base + 0.012
	_parts.add_child(ring)
	_disc(r, 0.02, base, _face_mat)
	var face_z := base + 0.022
	if caption != "":
		_caption = Label3D.new()
		_caption.text = caption
		_caption.font_size = 64
		_caption.outline_size = 0
		# Glyphs about the button's radius tall.
		_caption.pixel_size = r * 0.95 / 46.0
		_caption.double_sided = false
		_caption.position.z = face_z
		# A stop name, not a sign: sign_language.gd leaves it alone.
		_caption.set_meta("sign_dynamic", true)
		_parts.add_child(_caption)
	else:
		_caption = null
		# ▲ ▼ printed on the face (meshes, so no sign translation is involved).
		for side in [1, -1]:
			var arrow := MeshInstance3D.new()
			var prism := PrismMesh.new()
			prism.size = Vector3(r * 0.62, r * 0.42, 0.003)
			arrow.mesh = prism
			arrow.material_override = _mark_mat
			arrow.rotation.z = 0.0 if side > 0 else PI
			arrow.position = Vector3(0, side * r * 0.3, face_z)
			_parts.add_child(arrow)
	# Pick target: one box over the plate, or round the button (interaction_controller.gd walks
	# up to this node's Interactable). A button without a plate (the car's panel) picks through an
	# Area3D (14 Nov 2026): clicks and taps still find it, but it never blocks the player.
	var body: CollisionObject3D = StaticBody3D.new() if has_plate else Area3D.new()
	body.name = "Pick"
	if body is Area3D:
		(body as Area3D).monitoring = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var extent := pick_extent()
	box.size = Vector3(extent.x, extent.y, 0.06)
	shape.shape = box
	shape.position.z = 0.03
	body.add_child(shape)
	_parts.add_child(body)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 0, 0.18)
	_light.shadow_enabled = false
	_parts.add_child(_light)
	_paint()

func _paint() -> void:
	if _face_mat == null:
		return
	_plate_mat.albedo_color = plate_color
	_bezel_mat.albedo_color = plate_color.darkened(0.18)
	_mark_mat.albedo_color = mark_color
	if _caption != null:
		_caption.modulate = mark_color
	# Lit: the face takes the glow colour itself with a soft emission (stronger washed out to
	# white in the renders); the halo ring carries the full glow.
	_face_mat.albedo_color = idle_color.lerp(glow_color, _glow)
	_face_mat.emission = glow_color
	_face_mat.emission_energy_multiplier = glow_energy * 0.2 * _glow
	_ring_mat.albedo_color = RING_IDLE.lerp(glow_color, _glow)
	_ring_mat.emission = glow_color
	_ring_mat.emission_energy_multiplier = glow_energy * _glow
	_light.light_color = glow_color
	_light.light_energy = light_energy * _glow
	_light.omni_range = light_range
	_light.visible = _glow > 0.0 and light_energy > 0.0
