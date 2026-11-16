@tool
extends Node3D
## Interactive faucet (8 Nov 2026; models and placing: scripts/world/bath_fixtures.gd; record:
## docs/guides/TOWN_DESIGN_BRIEF.md "Bathroom fixtures"). E, a click or a tap (its interactable -> use()) turns it on or
## off; it stays on until turned off (user decision). On: the lever lifts and the stream falls
## from the spout to the basin, with a pulsing splash ring. Off: the lever drops, the stream
## breaks off at the spout and its tail falls away. A press mid-way simply reverses.
## Prefab: scenes/props/fixtures/faucet.tscn.
##
## Silent itself: scripts/core/sound.gd starts the running-water loop on turned_on and stops it
## on turned_off (data/sounds.json, faucet.run).
const Interactable := preload("res://scripts/core/interactable.gd")
signal turned_on
signal turned_off

const BathFixtures := preload("res://scripts/world/bath_fixtures.gd")
## Lever travel (radians) and how fast it follows (per second, like the doors).
const LEVER_OPEN := .5
const LEVER_RATE := 12.0
## Water falls at about this speed (town units per second) when it starts and stops.
const FALL_SPEED := 2.2

## A style of bath_fixtures.gd STYLES with a "faucet" entry: home_basin, kitchen, public_basin.
@export var style := "home_basin":
	set(value):
		style = value
		if is_inside_tree() and has_node("Model"):
			_rebuild()
## Height from the spout tip down to where the water lands (set by BathFixtures.add_faucet).
@export var drop := .25:
	set(value):
		drop = maxf(value, .02)
		if is_inside_tree() and has_node("Model/Splash"):
			get_node("Model/Splash").position.y = _tip.y - drop

var is_on := false
## Visible water as distances below the tip: head (lowest point) and tail (highest point).
var head := 0.0
var tail := 0.0
var _lever: Node3D
var _stream: MeshInstance3D
var _splash: MeshInstance3D
var _tip := Vector3.ZERO
var _clock := 0.0

func _ready() -> void:
	if not has_meta("word_key"):
		set_meta("word_key", "faucet")
	if not has_node("Model"):
		BathFixtures.build_faucet(self, style, drop)
	_bind()
	set_process(false)
	# E, a click or a tap turns it on or off; the "E" sits on the lever (interaction system).
	if not Engine.is_editor_hint():
		Interactable.attach(self, {
			"prompt_distance": 1.9,
			"priority": 0.3,
			"on_badge": func() -> Vector3: return _lever.global_position + Vector3.UP * 0.1 if is_instance_valid(_lever) else global_position,
		})

func _rebuild() -> void:
	for child in [get_node_or_null("Model"), get_node_or_null("Pick")]:
		if child != null:
			remove_child(child)
			child.free()
	BathFixtures.build_faucet(self, style, drop)
	_bind()

func _bind() -> void:
	_lever = get_node("Model/Lever")
	_stream = get_node("Model/Stream")
	_splash = get_node("Model/Splash")
	_tip = _stream.position
	_splash.position.y = _tip.y - drop
	# Each faucet has its own water material (uniforms may differ per faucet later).
	_stream.material_override = (_stream.material_override as ShaderMaterial).duplicate()
	_show()

## E on the faucet: toggles it. Returns true (it always responds).
func use() -> bool:
	is_on = not is_on
	if is_on:
		# Water already falling from an earlier "off" restarts at the spout.
		tail = 0.0
		if head >= drop: head = 0.0
		turned_on.emit()
	else:
		turned_off.emit()
	set_process(true)
	return true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	_clock += delta
	var target := LEVER_OPEN if is_on else 0.0
	_lever.rotation.x = lerpf(_lever.rotation.x, target, minf(1.0, LEVER_RATE * delta))
	if is_on:
		head = minf(drop, head + FALL_SPEED * delta)
		tail = 0.0
	elif head > 0.0:
		tail = minf(drop, tail + FALL_SPEED * delta)
		if tail >= drop:
			head = 0.0
			tail = 0.0
	_show()
	if not is_on and head == 0.0 and absf(_lever.rotation.x) < .002:
		_lever.rotation.x = 0.0
		set_process(false)

func _show() -> void:
	var length := head - tail
	_stream.visible = length > .001
	_stream.position = _tip - Vector3(0, tail, 0)
	_stream.scale = Vector3(1, maxf(length, .001), 1)
	# The splash shows while water reaches the basin, pulsing a little.
	var landing := head >= drop - .001 and length > .001
	_splash.visible = landing
	if landing:
		var pulse := 1.0 + .12 * sin(_clock * 23.0) + .06 * sin(_clock * 37.0)
		_splash.scale = Vector3(pulse, 1.0 + .3 * sin(_clock * 29.0), pulse)
