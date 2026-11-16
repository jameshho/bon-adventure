@tool
extends Node3D
## Interactive toilet (8 Nov 2026; models and placing: scripts/world/bath_fixtures.gd; record:
## docs/guides/TOWN_DESIGN_BRIEF.md "Bathroom fixtures"). E near the toilet sits on it (a seat for
## scripts/player/seating_controller.gd, 9 Nov 2026); E or a click on the flush lever / push
## plate (Model/Flush, scripts/world/flush_control.gd) calls flush(): the lever dips and springs
## back (the wall style's button presses in), the bowl water swirls, drops and refills. A press
## during a flush does nothing. Prefab: scenes/props/fixtures/toilet.tscn.
##
## Silent itself: scripts/core/sound.gd listens to these signals and plays the cues
## (data/sounds.json, toilet.flush).
signal flush_started
signal refill_started
signal flush_finished

const BathFixtures := preload("res://scripts/world/bath_fixtures.gd")
## Seconds of one flush, and the moments inside it (fractions of FLUSH_SECONDS are not used so
## the lever feels the same whatever the flush length).
const FLUSH_SECONDS := 2.8
const LEVER_DOWN := .15
const LEVER_BACK := .45
const REFILL_AT := 1.5
## How far the water drops while emptying (town units) and how much its disc narrows.
const LEVEL_DROP := .06
const NARROW := .25

## "home" (floor-standing, cistern, raised lid) or "public" (wall-hung, push plate).
@export var style := "home":
	set(value):
		style = value
		if is_inside_tree() and has_node("Model"):
			rebuild()

var flushing := false
var elapsed := 0.0
var _lever: Node3D
var _water: MeshInstance3D
var _water_material: ShaderMaterial
var _water_rest := Vector3.ZERO
var _water_scale := Vector3.ONE
var _phase := 0.0
var _refilling := false

func _ready() -> void:
	if not has_meta("word_key"):
		set_meta("word_key", "toilet")
	# A seat: E nearby sits down, facing away from the cistern (+Z), on the seat ring.
	set_meta("sit_enabled", true)
	set_meta("sit_label", "toilet")
	set_meta("sit_position", Vector3(0, BathFixtures.RIM_Y + .03, BathFixtures.BOWL_Z - .1))
	set_meta("sit_forward", Vector3(0, 0, 1))
	if not has_node("Model"):
		BathFixtures.build_toilet(self, style)
		_bind()
	elif not has_node("Model/Flush"):
		# Parts saved before the flush control (9 Nov 2026): build them again (the bake step
		# toilet_flush_control saves the new ones).
		rebuild()
	else:
		_bind()
	set_process(false)

## Frees and builds the parts again (the style setter; bath_fixtures.gd rebuild_toilets).
func rebuild() -> void:
	for child in [get_node_or_null("Model"), get_node_or_null("Solid")]:
		if child != null:
			remove_child(child)
			child.free()
	BathFixtures.build_toilet(self, style)
	_bind()

func _bind() -> void:
	_lever = get_node("Model/Flush/Lever")
	_water = get_node("Model/Water")
	_water_rest = _water.position
	_water_scale = _water.scale
	# Each toilet animates its own copy (a saved material may be shared through the palette).
	_water_material = (_water.material_override as ShaderMaterial).duplicate()
	_water.material_override = _water_material

## The flush lever or plate was used (flush_control.gd). Returns true when a flush starts.
func flush() -> bool:
	if flushing:
		return false
	flushing = true
	_refilling = false
	elapsed = 0.0
	flush_started.emit()
	set_process(true)
	return true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	elapsed += delta
	var t := elapsed
	# Lever (or button): down quickly, back with an ease.
	var press := 0.0
	if t < LEVER_DOWN:
		press = t / LEVER_DOWN
	elif t < LEVER_BACK:
		press = 1.0 - ease((t - LEVER_DOWN) / (LEVER_BACK - LEVER_DOWN), .5)
	if _lever.has_node("Button"):
		_lever.position.z = .025 - .012 * press
	else:
		# The arm reaches forward (+Z); turning about X dips its tip.
		_lever.rotation.x = .55 * press
	# Swirl comes in, peaks, and settles while the bowl refills.
	var swirl := smoothstep(.05, .5, t) * (1.0 - smoothstep(1.6, 2.5, t))
	_phase += delta * (4.0 + 10.0 * swirl) * swirl
	_water_material.set_shader_parameter("swirl", swirl)
	_water_material.set_shader_parameter("phase", _phase)
	# Level: drops while emptying, comes back while refilling.
	var low := smoothstep(.35, 1.25, t) * (1.0 - smoothstep(REFILL_AT, FLUSH_SECONDS, t))
	_water.position = _water_rest - Vector3(0, LEVEL_DROP * low, 0)
	_water.scale = _water_scale * Vector3(1.0 - NARROW * low, 1, 1.0 - NARROW * low)
	if t >= REFILL_AT and not _refilling:
		_refilling = true
		refill_started.emit()
	if t >= FLUSH_SECONDS:
		_water.position = _water_rest
		_water.scale = _water_scale
		_water_material.set_shader_parameter("swirl", 0.0)
		flushing = false
		set_process(false)
		flush_finished.emit()
