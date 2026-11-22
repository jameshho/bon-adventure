extends Node3D
## Siren and flashing lights (21 Nov 2026, user): ONE reusable component for the police car, the
## ambulance and the fire truck (and any later emergency vehicle: add its word_key to SIRENS and a
## cue to data/sounds.json). Owned by DriveableVehicle (emergency_lights()), toggled by Q while
## driving or the HUD's Siren button (touch_controls.gd); leaving the vehicle switches it off.
##
## Beacons are found from the model, no per-model authoring: meshes whose material glows
## (emission on) red or blue and whose name, or a parent's, says light / beacon / LED / siren /
## strobe (the police light bar, the ambulance's roof bar, side beacons and rear lights, the fire
## truck's light bar). While on, the red and the blue beacons take turns in a double flash
## (PATTERN) through two shared materials (one energy write each per change), one small
## OmniLight3D (no shadows) washes the street in the lit colour, and the siren loop plays through
## the sound service (scripts/core/sound.gd, cue from SIRENS). Off restores the authored
## materials, frees the light's work (no processing) and stops the sound.
## Same shape as vehicle_headlights.gd: set_on() / toggle() / is_on and a `switched` signal.

signal switched(on: bool)

const NODE_NAME := "EmergencyLights"
const Sound := preload("res://scripts/core/sound.gd")
## word_key -> sound cue (data/sounds.json). Only these vehicles get the Siren button.
const SIRENS := {
	"police car": "siren.police",
	"ambulance": "siren.ambulance",
	"fire truck": "siren.fire_truck",
}
const BEACON_NAME := "(?i)(light|beacon|led|siren|strobe)"
## One cycle (seconds) of the flash, and when each side is lit within it: [start, end] pairs as
## fractions of the cycle. Red flashes twice, then blue twice.
const CYCLE := 0.8
const PATTERN := {
	"red": [[0.0, 0.14], [0.2, 0.34]],
	"blue": [[0.5, 0.64], [0.7, 0.84]],
}
const LIT_ENERGY := 6.0
const DIM_ENERGY := 0.08
const RED := Color(1.0, 0.1, 0.12)
const BLUE := Color(0.1, 0.35, 1.0)
const WASH_RANGE := 10.0
const WASH_ENERGY := 2.5

var is_on := false
var cue := ""
var _vehicle: Node3D
var _built := false
## "red" / "blue" -> {MeshInstance3D: authored material_override}
var _beacons := {"red": {}, "blue": {}}
var _flash := {}
var _wash: OmniLight3D
var _clock := 0.0
var _lit := ""

## Whether `vehicle` is an emergency vehicle (has a siren), without building anything.
static func fits(vehicle: Node) -> bool:
	return SIRENS.has(str(vehicle.get_meta("word_key", "")))

## The vehicle's emergency lights, made on first use; null when it has no siren.
static func of(vehicle: Node3D) -> Node3D:
	if not fits(vehicle):
		return null
	var existing := vehicle.get_node_or_null(NODE_NAME)
	if existing != null:
		return existing
	var lights: Node3D = load("res://scripts/world/emergency_lights.gd").new()
	lights.name = NODE_NAME
	lights._vehicle = vehicle
	lights.cue = SIRENS[str(vehicle.get_meta("word_key"))]
	vehicle.add_child(lights)
	return lights

func _ready() -> void:
	set_process(false)

func toggle() -> void:
	set_on(not is_on)

func set_on(value: bool) -> void:
	if value == is_on:
		return
	if value and not _built:
		_build()
	is_on = value
	for colour in _beacons:
		for mesh: MeshInstance3D in _beacons[colour]:
			if is_instance_valid(mesh):
				mesh.material_override = _flash[colour] if value else _beacons[colour][mesh]
	_clock = 0.0
	_lit = "?"
	if _wash != null:
		_wash.visible = value
	set_process(value)
	if value:
		_show(_side_at(0.0))
	var sound = Sound.shared()
	if sound != null and cue != "":
		if value:
			sound.start_loop(cue, _vehicle)
		else:
			sound.stop_loop(cue, _vehicle)
	switched.emit(value)

func _process(delta: float) -> void:
	_clock = fmod(_clock + delta, CYCLE)
	_show(_side_at(_clock / CYCLE))

## "red", "blue" or "" (both dark) at a point of the cycle (0-1).
static func _side_at(phase: float) -> String:
	for side in PATTERN:
		for span in PATTERN[side]:
			if phase >= span[0] and phase < span[1]:
				return side
	return ""

func _show(side: String) -> void:
	if side == _lit:
		return
	_lit = side
	for colour in _flash:
		_flash[colour].emission_energy_multiplier = LIT_ENERGY if colour == side else DIM_ENERGY
	if _wash != null:
		_wash.light_energy = WASH_ENERGY if side != "" else 0.0
		if side != "":
			_wash.light_color = RED if side == "red" else BLUE

func _build() -> void:
	_built = true
	var name_filter := RegEx.create_from_string(BEACON_NAME)
	var from_vehicle := _vehicle.global_transform.affine_inverse()
	var top := -INF
	var centre := Vector3.ZERO
	var count := 0
	for node in _vehicle.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not _named_as_beacon(mesh, name_filter):
			continue
		var colour := _beacon_colour(mesh.material_override if mesh.material_override != null else mesh.get_active_material(0))
		if colour == "":
			continue
		_beacons[colour][mesh] = mesh.material_override
		var at: Vector3 = from_vehicle * mesh.global_position
		centre += at
		count += 1
		top = maxf(top, at.y)
	for colour in _beacons:
		var flash := StandardMaterial3D.new()
		flash.albedo_color = RED if colour == "red" else BLUE
		flash.emission_enabled = true
		flash.emission = flash.albedo_color
		flash.emission_energy_multiplier = DIM_ENERGY
		_flash[colour] = flash
	_wash = OmniLight3D.new()
	_wash.name = "Wash"
	_wash.omni_range = WASH_RANGE
	_wash.shadow_enabled = false
	_wash.light_energy = 0.0
	_wash.visible = false
	_wash.position = Vector3(centre.x / count, top + 0.4, 0.0) if count > 0 else Vector3(0, 2.5, 0)
	add_child(_wash)

## The mesh or a parent up to the vehicle is named like a light.
func _named_as_beacon(mesh: Node, name_filter: RegEx) -> bool:
	var node: Node = mesh
	while node != null and node != _vehicle:
		if name_filter.search(str(node.name)) != null:
			return true
		node = node.get_parent()
	return false

## "red" / "blue" for a glowing, clearly red or blue material, else "".
static func _beacon_colour(material: Material) -> String:
	var surface := material as StandardMaterial3D
	if surface == null or not surface.emission_enabled:
		return ""
	var c := surface.albedo_color
	if c.r > 0.6 and c.r > c.b * 2.0 and c.r > c.g * 2.0:
		return "red"
	if c.b > 0.6 and c.b > c.r * 2.0 and c.b > c.g * 1.5:
		return "blue"
	return ""
