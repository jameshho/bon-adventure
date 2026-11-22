extends Node3D
## Headlights for every road vehicle (21 Nov 2026, user: "flashlight for cars when driving at
## night", one button for all cars). Owned by DriveableVehicle (headlights()), toggled by F while
## driving or the HUD's Lights button (touch_controls.gd); boarding at night switches them on
## (vehicle_controls.gd board()) and leaving the vehicle switches them off (finish_exit()), so at
## most the driven vehicle carries a light (performance first, docs/guides/performance/).
##
## What it does, found from the model (no per-model authoring; the scene files stay untouched):
##   - the model's own lamp meshes glow: nodes named Lamp / Lamp_N, *Headlight* / *Headlamp*,
##     *Taillight* / *BrakeLight* (sockets, frames, rings and housings stay as they are). A lamp in
##     front of the body's middle (model -X is forward) glows warm white, one behind glows red.
##   - one SpotLight3D (no shadows) in front of the lamps lights the road ahead.
## Nothing is built until the lights first go on; off restores the authored materials and hides
## the light, so a parked car costs nothing.
## Shared shape with emergency_lights.gd (the siren component): set_on() / toggle() / is_on and
## a `switched` signal a sound or HUD can follow.

signal switched(on: bool)

const NODE_NAME := "Headlights"
## Lamp nodes by name; meshes under them (or the node itself) glow unless SKIP_PART matches.
const LAMP_NAME := "(?i)^(lamp(_\\d+)?|.*head ?(light|lamp).*|.*(tail|brake) ?light.*)$"
const SKIP_PART := "(?i)(socket|frame|ring|housing)"
const FRONT_GLOW := Color(1.0, 0.96, 0.82)
const REAR_GLOW := Color(1.0, 0.12, 0.1)
const FRONT_ENERGY := 3.0
const REAR_ENERGY := 1.6
## The road light: reach (m), cone half-angle (degrees), strength, and its downward tilt.
const BEAM_RANGE := 30.0
const BEAM_ANGLE := 36.0
const BEAM_ENERGY := 4.0
const BEAM_TILT := 0.14

var is_on := false
var _vehicle: Node3D
var _built := false
## MeshInstance3D -> its authored material_override (restored when the lights go off).
var _front: Dictionary = {}
var _rear: Dictionary = {}
var _front_glow: StandardMaterial3D
var _rear_glow: StandardMaterial3D
var _beam: SpotLight3D

## The vehicle's headlights, made (empty) on first use.
static func of(vehicle: Node3D) -> Node3D:
	var existing := vehicle.get_node_or_null(NODE_NAME)
	if existing != null:
		return existing
	var lights: Node3D = load("res://scripts/world/vehicle_headlights.gd").new()
	lights.name = NODE_NAME
	lights._vehicle = vehicle
	vehicle.add_child(lights)
	return lights

func toggle() -> void:
	set_on(not is_on)

func set_on(value: bool) -> void:
	if value == is_on:
		return
	if value and not _built:
		_build()
	is_on = value
	for mesh: MeshInstance3D in _front:
		if is_instance_valid(mesh):
			mesh.material_override = _front_glow if value else _front[mesh]
	for mesh: MeshInstance3D in _rear:
		if is_instance_valid(mesh):
			mesh.material_override = _rear_glow if value else _rear[mesh]
	if _beam != null:
		_beam.visible = value
	switched.emit(value)

## Finds the lamps and places the beam (once).
func _build() -> void:
	_built = true
	var name_filter := RegEx.create_from_string(LAMP_NAME)
	var skip := RegEx.create_from_string(SKIP_PART)
	var from_vehicle := _vehicle.global_transform.affine_inverse()
	var body := _body_box(from_vehicle)
	var middle := body.get_center().x
	var front_points: Array[Vector3] = []
	for node in _vehicle.find_children("*", "Node3D", true, false):
		if node == self or name_filter.search(str(node.name)) == null:
			continue
		var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
		if node is MeshInstance3D:
			meshes.append(node)
		for mesh: MeshInstance3D in meshes:
			if mesh.mesh == null or skip.search(str(mesh.name)) != null or _front.has(mesh) or _rear.has(mesh):
				continue
			var at: Vector3 = from_vehicle * mesh.global_position
			if at.x < middle:
				_front[mesh] = mesh.material_override
				front_points.append(at)
			else:
				_rear[mesh] = mesh.material_override
	_front_glow = _glow_material(_front.keys(), FRONT_GLOW, FRONT_ENERGY)
	_rear_glow = _glow_material(_rear.keys(), REAR_GLOW, REAR_ENERGY)
	# The beam starts just ahead of the lamps (or the nose, at a third of the body's height).
	var origin := Vector3(body.position.x, body.position.y + body.size.y * 0.33, 0.0)
	if not front_points.is_empty():
		origin = Vector3.ZERO
		for point in front_points:
			origin += point
		origin /= front_points.size()
		origin.x = body.position.x
		origin.z = 0.0
	_beam = SpotLight3D.new()
	_beam.name = "Beam"
	_beam.light_color = FRONT_GLOW
	_beam.light_energy = BEAM_ENERGY
	_beam.spot_range = BEAM_RANGE
	_beam.spot_angle = BEAM_ANGLE
	_beam.spot_attenuation = 0.8
	_beam.shadow_enabled = false
	_beam.position = origin + Vector3(-0.15, 0.0, 0.0)
	_beam.basis = Basis.looking_at(Vector3(-1.0, -BEAM_TILT, 0.0).normalized(), Vector3.UP)
	_beam.visible = false
	add_child(_beam)

## The vehicle's visible body in its own space (collision, the beam and this node left out).
func _body_box(from_vehicle: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	for node in _vehicle.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var part: AABB = (from_vehicle * mesh.global_transform) * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box

## One glowing copy of the first lamp's material, shared by all lamps on that end.
static func _glow_material(meshes: Array, colour: Color, energy: float) -> StandardMaterial3D:
	var base: Material = null
	for mesh: MeshInstance3D in meshes:
		base = mesh.material_override if mesh.material_override != null else mesh.get_active_material(0)
		if base != null:
			break
	var glow: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
	glow.albedo_color = colour
	glow.emission_enabled = true
	glow.emission = colour
	glow.emission_energy_multiplier = energy
	return glow
