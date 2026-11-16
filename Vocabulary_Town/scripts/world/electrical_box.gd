@tool
extends Node3D
## A wall-mounted electrical box with a wire-repair puzzle (user request, 9 Nov 2026;
## docs/guides/ELECTRICAL_BOX.md). Reusable: drop scenes/props/electrical_box.tscn anywhere in town
## (its back on a wall, its front +Z facing out) and set the exports. It is an interactable
## (scripts/core/interactable.gd, a pastime station): E, a click or a tap calls use(); the session
## (scripts/learning/electrical_box_session.gd, group "electrical_box_session") opens the door,
## zooms the camera in and shows the wire screen (scripts/ui/electrical_box_panel.gd).
##
## The model is built at load from code (as toilet.gd does), so it is never saved in a unit
## scene: only the root, its exports and metas are. Sizes are town units (the town has scale 1.3).
## Origin: the centre of the box's back, against the wall.
##
## Silent itself: these signals are the hooks for sounds (scripts/core/sound.gd, later).
const Interactable := preload("res://scripts/core/interactable.gd")
signal door_moved(opening: bool)
signal repaired_changed(repaired: bool)

## Every box joins this group (the session finds the nearest one for E and the test launcher).
const GROUP := "electrical_boxes"
const WIDTH := 0.56
const HEIGHT := 0.72
const DEPTH := 0.16
const WALL := 0.025
## The door turns about its left hinge to this angle (radians, outward).
const DOOR_OPEN := -1.95
## Wires the puzzle can hold, and the default palette: each colour with its symbol, so the
## colours can be told apart without colour vision (as in the reference picture).
const MIN_WIRES := 2
const MAX_WIRES := 6
const PALETTE := [
	{"color": Color("e8412f"), "symbol": "triangle"},
	{"color": Color("2f56e0"), "symbol": "cross"},
	{"color": Color("f2d43a"), "symbol": "circle"},
	{"color": Color("d43ad8"), "symbol": "star"},
	{"color": Color("3cbf5a"), "symbol": "square"},
	{"color": Color("f08a24"), "symbol": "diamond"},
]
const SYMBOLS := ["triangle", "cross", "circle", "star", "square", "diamond"]

## Optional id for saves or quests that need to tell boxes apart.
@export var box_id := ""
## How many wires the puzzle has (MIN_WIRES..MAX_WIRES), taken from PALETTE in order.
@export_range(2, 6) var wire_count := 4:
	set(value):
		wire_count = clampi(value, MIN_WIRES, MAX_WIRES)
		_refresh_interior()
## Custom wire colours, in order (symbols follow SYMBOLS); when set, they replace PALETTE and
## wire_count is ignored (at most MAX_WIRES are used).
@export var wire_colors := PackedColorArray():
	set(value):
		wire_colors = value
		_refresh_interior()
## Body colour (a soft utility grey by default).
@export var body_color := Color("c3cbc6"):
	set(value):
		body_color = value
		if is_inside_tree() and has_node("Model"):
			_build()
## Length of the conduit pipe from the box's bottom down to the ground (0: none).
@export var conduit := 0.0:
	set(value):
		conduit = value
		if is_inside_tree() and has_node("Model"):
			_build()

## Repaired since the town loaded (not saved): the lamp turns from blinking red to green and
## the wires inside stay connected.
var repaired := false
var _door: Node3D
var _lamp_material: StandardMaterial3D
var _interior: Node3D
var _blink := 0.0
var _door_tween: Tween
static var _materials := {}

func _ready() -> void:
	if not has_meta("word_key"):
		set_meta("word_key", "electrical box")
	add_to_group(GROUP)
	_build()
	# A pastime station (interaction system, 12 Nov 2026): a subtle dot within 15 m; E, a click or
	# a tap opens it from in front (as use_nearby did: within 2.2 m, on its front side).
	if not Engine.is_editor_hint():
		Interactable.attach(self, {
			"kind": Interactable.Kind.PLAY,
			"indicator": Interactable.Indicator.STATION,
			"prompt_distance": 2.2,
			"needs_facing": false,
			"priority": 0.5,
			"on_point": func(from: Vector3) -> Vector3:
				var p := global_position
				return Vector3(p.x, from.y, p.z) if (from - p).dot(facing()) > 0.0 else Vector3.INF,
			"on_badge": func() -> Vector3: return front_center() + Vector3.UP * 0.5,
		})

## The puzzle's wires: [{"color", "symbol"}], wire_colors or the first wire_count of PALETTE.
func palette() -> Array:
	var out := []
	if wire_colors.size() > 0:
		for i in mini(wire_colors.size(), MAX_WIRES):
			out.append({"color": wire_colors[i], "symbol": SYMBOLS[i % SYMBOLS.size()]})
	else:
		for i in clampi(wire_count, MIN_WIRES, MAX_WIRES):
			out.append(PALETTE[i])
	return out

## Its interactable's use (E, a click or a tap): asks the session to open this box. True when it opened.
func use() -> bool:
	for session in get_tree().get_nodes_in_group("electrical_box_session"):
		if session.has_method("open_box"):
			return session.open_box(self)
	return false

## The point the player looks at and the way the box faces (world space).
func front_center() -> Vector3:
	return to_global(Vector3(0, 0, DEPTH))

func facing() -> Vector3:
	return (global_transform.basis * Vector3(0, 0, 1)).normalized()

## Camera transform for the close-up: straight in front of the box, so it fills `fill` of the
## view height at vertical field of view `fov` (degrees).
## The view is aimed a little below the centre, so the box sits above the puzzle's bottom bar.
func view_transform(fov: float, fill := 0.78) -> Transform3D:
	var scale_y := global_transform.basis.get_scale().y
	var distance := (HEIGHT * scale_y / fill) * 0.5 / tan(deg_to_rad(fov) * 0.5)
	var target := to_global(Vector3(0, -0.045, DEPTH * 0.5))
	var from := target + facing() * (distance + DEPTH * 0.5 * scale_y)
	return Transform3D(Basis(), from).looking_at(target, Vector3.UP)

## Swings the door open (true) or shut over `seconds`.
func set_door_open(open: bool, seconds := 0.5) -> void:
	if _door == null:
		return
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	_door_tween = create_tween().set_trans(Tween.TRANS_BACK if open else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN_OUT)
	_door_tween.tween_property(_door, "rotation:y", DOOR_OPEN if open else 0.0, seconds)
	door_moved.emit(open)

func set_repaired(value: bool) -> void:
	if repaired == value:
		return
	repaired = value
	_refresh_interior()
	_update_lamp(1.0)
	set_process(not repaired and not Engine.is_editor_hint())
	repaired_changed.emit(repaired)

func _process(delta: float) -> void:
	# A broken box's lamp blinks red (about 1.2 times a second).
	_blink = fmod(_blink + delta * 1.2, 1.0)
	_update_lamp(1.0 if _blink < 0.5 else 0.15)

func _update_lamp(level: float) -> void:
	if _lamp_material == null:
		return
	var color := Color("57e36b") if repaired else Color("ff3b2e")
	_lamp_material.albedo_color = color.darkened(0.2)
	_lamp_material.emission = color
	_lamp_material.emission_energy_multiplier = 2.2 * level

# --- Model ------------------------------------------------------------------------------

func _build() -> void:
	for child in [get_node_or_null("Model"), get_node_or_null("Solid")]:
		if child != null:
			remove_child(child)
			child.free()
	var model := Node3D.new()
	model.name = "Model"
	add_child(model)
	var w := WIDTH
	var h := HEIGHT
	var d := DEPTH
	var dark := body_color.darkened(0.35)
	# Hollow shell: back, two sides, top and bottom, so the inside shows with the door open.
	_box(model, Vector3(0, 0, WALL * 0.5), Vector3(w, h, WALL), body_color)
	for side in [-1, 1]:
		_box(model, Vector3(side * (w - WALL) * 0.5, 0, d * 0.5), Vector3(WALL, h, d), body_color)
		_box(model, Vector3(0, side * (h - WALL) * 0.5, d * 0.5), Vector3(w, WALL, d), body_color)
	# Rain hood over the top, and the wall plate the box is screwed to.
	_box(model, Vector3(0, h * 0.5 + 0.018, d * 0.5 + 0.02), Vector3(w + 0.07, 0.035, d + 0.07), dark)
	_box(model, Vector3(0, 0, -0.004), Vector3(w + 0.08, h + 0.08, 0.008), Color("8a8f8c"))
	# Inside: dark back panel and two terminal strips.
	_box(model, Vector3(0, 0, WALL + 0.003), Vector3(w - 2 * WALL, h - 2 * WALL, 0.006), Color("33373e"))
	# Terminal strip (left) and socket rail (right) behind the wires, and a cable duct along
	# the bottom.
	for x in [LEFT_X - 0.03, SOCKET_X + 0.045]:
		_box(model, Vector3(x, 0, WALL + 0.02), Vector3(0.062, ROWS_TOP * 2.0 + 0.06, 0.03), Color("4a4f58"))
	_box(model, Vector3(0, -ROWS_TOP - 0.055, WALL + 0.025), Vector3(w - 2 * WALL - 0.02, 0.035, 0.04), Color("5b6168"))
	_interior = Node3D.new()
	_interior.name = "Wires"
	model.add_child(_interior)
	_refresh_interior()
	# Door on its left hinge (seen from the front); it swings outward to DOOR_OPEN.
	_door = Node3D.new()
	_door.name = "Door"
	model.add_child(_door)
	_door.position = Vector3(-w * 0.5, 0, d)
	var panel := _box(_door, Vector3(w * 0.5, 0, 0.012), Vector3(w - 0.004, h - 0.004, 0.024), body_color.lightened(0.06))
	panel.name = "Panel"
	# Warning sticker: a yellow triangle with a dark lightning bolt.
	var sticker := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.17, 0.15, 0.004)
	sticker.mesh = prism
	sticker.material_override = _material(Color("f5c623"))
	_door.add_child(sticker)
	sticker.position = Vector3(w * 0.5, 0.13, 0.026)
	for part in [[Vector3(0.006, 0.02, 0), -0.5], [Vector3(-0.006, -0.02, 0), -0.5]]:
		var bolt := _box(_door, sticker.position + part[0] + Vector3(0, -0.012, 0.003), Vector3(0.016, 0.06, 0.003), Color("2b2b2b"))
		bolt.rotation.z = part[1]
	# Handle, vent slots and the status lamp.
	_box(_door, Vector3(w - 0.06, -0.02, 0.04), Vector3(0.026, 0.12, 0.03), Color("3a3d42"))
	for i in 3:
		_box(_door, Vector3(w * 0.5, -0.17 - i * 0.04, 0.025), Vector3(w * 0.5, 0.012, 0.003), dark)
	var lamp := MeshInstance3D.new()
	lamp.name = "Lamp"
	var bulb := SphereMesh.new()
	bulb.radius = 0.026
	bulb.height = 0.04
	lamp.mesh = bulb
	_lamp_material = StandardMaterial3D.new()
	_lamp_material.emission_enabled = true
	lamp.material_override = _lamp_material
	_door.add_child(lamp)
	lamp.position = Vector3(w * 0.5, -0.06, 0.03)
	_update_lamp(1.0)
	# Conduit down to the ground.
	if conduit > 0.01:
		var pipe := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = 0.03
		tube.bottom_radius = 0.03
		tube.height = conduit
		tube.radial_segments = 12
		pipe.mesh = tube
		pipe.material_override = _material(Color("8a8f8c"))
		model.add_child(pipe)
		pipe.position = Vector3(0, -h * 0.5 - conduit * 0.5, 0.05)
	# One solid for picking and blocking (the door is not solid).
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w + 0.04, h + 0.06, d + 0.04)
	shape.shape = box
	shape.position = Vector3(0, 0.01, d * 0.5)
	solid.add_child(shape)
	solid.set_meta("object_name", "electrical box")
	add_child(solid)
	set_process(not repaired and not Engine.is_editor_hint())

## --- Wires (the puzzle is played on these meshes; electrical_box_panel.gd drives them) ---
## Box-local positions: the wires lie in the plane z = WIRE_Z; rows run down from ROWS_TOP.
const WIRE_Z := 0.07
const ROWS_TOP := 0.25
const LEFT_X := -0.195
const SOCKET_X := 0.17
const WIRE_RADIUS := 0.011
## Wire i hangs from left row _left[i] and belongs in right row _right[i].
var _left: Array = []
var _right: Array = []
var _connected: Array = []
var _tips: Array = []
var _wire_nodes: Array = []
var _socket_materials: Array = []
var _light: OmniLight3D

func row_y(row: int) -> float:
	var n := palette().size()
	return ROWS_TOP - 2.0 * ROWS_TOP * (row + 0.5) / n

func anchor(i: int) -> Vector3:
	return Vector3(LEFT_X, row_y(_left[i]), WIRE_Z)

func rest(i: int) -> Vector3:
	return anchor(i) + Vector3(0.085, -0.022 if _left[i] % 2 == 0 else -0.04, 0.012)

func socket(row: int) -> Vector3:
	return Vector3(SOCKET_X, row_y(row), WIRE_Z)

func tip(i: int) -> Vector3:
	return _tips[i]

## New puzzle order: wire i hangs from left row left[i] and belongs in right row right[i];
## every wire loose at rest.
func arrange(left: Array, right: Array) -> void:
	_left = left.duplicate()
	_right = right.duplicate()
	_connected = []
	_tips = []
	for i in _left.size():
		_connected.append(false)
		_tips.append(Vector3.ZERO)
	for i in _left.size():
		_tips[i] = rest(i)
	_refresh_interior()

## Every wire back to its loose rest (leaving without finishing).
func reset_wires() -> void:
	if repaired:
		return
	for i in _connected.size():
		_connected[i] = false
		_tips[i] = rest(i)
	_refresh_interior()

## Moves wire i's loose end (box-local).
func set_tip(i: int, point: Vector3) -> void:
	_tips[i] = point
	_place_wire(i)

## Wire i goes into its socket: snapped, with a green glow.
func connect_wire(i: int) -> void:
	_connected[i] = true
	_tips[i] = socket(_right[i])
	_place_wire(i)
	flash_socket(_right[i], true)

## A short glow in a socket: green (a wire went in, then a steady soft glow) or red (wrong).
func flash_socket(row: int, good: bool) -> void:
	if row < 0 or row >= _socket_materials.size() or _socket_materials[row] == null:
		return
	var material: StandardMaterial3D = _socket_materials[row]
	material.emission = Color("6cff8a") if good else Color("ff4a3a")
	var tween := create_tween()
	tween.tween_property(material, "emission_energy_multiplier", 3.0, 0.06)
	tween.tween_property(material, "emission_energy_multiplier", 0.9 if good else 0.0, 0.4)

## A small work light inside the box while it is open for the puzzle.
func set_work_light(on: bool) -> void:
	if _light != null and is_instance_valid(_light):
		_light.visible = on

func _place_wire(i: int) -> void:
	if i >= _wire_nodes.size():
		return
	var wire: Node3D = _wire_nodes[i]
	var a := anchor(i)
	var b: Vector3 = _tips[i]
	var rod: MeshInstance3D = wire.get_node("Rod")
	var axis := b - a
	var length := maxf(axis.length(), 0.001)
	axis /= length
	var side := axis.cross(Vector3(0, 0, 1))
	side = side.normalized() if side.length() > 0.001 else Vector3.RIGHT
	rod.basis = Basis(side, axis * length, side.cross(axis))
	rod.position = (a + b) * 0.5
	var end: Node3D = wire.get_node("End")
	end.position = b
	end.basis = Basis(side, axis, side.cross(axis))
	end.visible = not _connected[i]

## Builds the wires, terminals and sockets for the current order (default: palette order on
## the left, reversed on the right; all in once repaired).
func _refresh_interior() -> void:
	if _interior == null or not is_instance_valid(_interior):
		return
	var wires := palette()
	var n := wires.size()
	if _left.size() != n:
		_left = range(n)
		_right = range(n)
		_right.reverse()
		_connected = []
		_tips = []
		for i in n:
			_connected.append(false)
			_tips.append(Vector3.ZERO)
		for i in n:
			_tips[i] = rest(i)
	if repaired:
		for i in n:
			_connected[i] = true
			_tips[i] = socket(_right[i])
	for child in _interior.get_children():
		_interior.remove_child(child)
		child.free()
	_wire_nodes = []
	_socket_materials = []
	var unit := CylinderMesh.new()
	unit.top_radius = WIRE_RADIUS
	unit.bottom_radius = WIRE_RADIUS
	unit.height = 1.0
	unit.radial_segments = 10
	unit.rings = 1
	for row in n:
		_socket_materials.append(null)
	for i in n:
		var color: Color = wires[i].color
		# Left terminal: a coloured plate with its symbol, on the strip.
		var plate := _box(_interior, Vector3(LEFT_X - 0.03, row_y(_left[i]), WIRE_Z - 0.012), Vector3(0.05, 0.042, 0.014), color)
		_token(plate, wires[i].symbol, Vector3(0, 0, 0.008))
		# The wire: insulation rod and a copper ferrule on its loose end.
		var wire := Node3D.new()
		wire.name = "Wire %d" % i
		_interior.add_child(wire)
		var rod := MeshInstance3D.new()
		rod.name = "Rod"
		rod.mesh = unit
		rod.material_override = _material(color)
		wire.add_child(rod)
		var end := Node3D.new()
		end.name = "End"
		wire.add_child(end)
		var ferrule := MeshInstance3D.new()
		var sleeve := CylinderMesh.new()
		sleeve.top_radius = WIRE_RADIUS * 0.75
		sleeve.bottom_radius = WIRE_RADIUS * 1.05
		sleeve.height = 0.02
		sleeve.radial_segments = 10
		ferrule.mesh = sleeve
		ferrule.material_override = _material(Color("c8743a"))
		end.add_child(ferrule)
		_wire_nodes.append(wire)
		_place_wire(i)
		# Its socket on the right: a plate with the same colour and symbol, and a ring hole.
		var row: int = _right[i]
		var socket_plate := _box(_interior, Vector3(SOCKET_X + 0.045, row_y(row), WIRE_Z - 0.012), Vector3(0.05, 0.042, 0.014), color)
		_token(socket_plate, wires[i].symbol, Vector3(0, 0, 0.008))
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.011
		torus.outer_radius = 0.019
		torus.rings = 16
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = _material(Color("3a3d42"))
		_interior.add_child(ring)
		ring.position = socket(row) - Vector3(0, 0, 0.006)
		ring.rotation.x = PI * 0.5
		var hole := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.011
		disc.bottom_radius = 0.011
		disc.height = 0.004
		disc.radial_segments = 14
		hole.mesh = disc
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color("15171a")
		glow.emission_enabled = true
		glow.emission = Color("6cff8a")
		glow.emission_energy_multiplier = 0.9 if _connected[i] else 0.0
		hole.material_override = glow
		_interior.add_child(hole)
		hole.position = socket(row) - Vector3(0, 0, 0.01)
		hole.rotation.x = PI * 0.5
		_socket_materials[row] = glow
	if _light == null or not is_instance_valid(_light):
		_light = OmniLight3D.new()
		_light.name = "WorkLight"
		_light.light_color = Color("fff1d6")
		_light.light_energy = 0.9
		_light.omni_range = 0.7
		_light.shadow_enabled = false
		_light.visible = false
		_interior.get_parent().add_child(_light)
		_light.position = Vector3(0, 0.12, DEPTH + 0.12)

## A small dark symbol on a terminal plate, so the colours can be told apart without colour
## vision (as in the reference picture).
func _token(plate: Node3D, symbol: String, at: Vector3) -> void:
	var ink := Color("15171a")
	var s := 0.022
	match symbol:
		"triangle", "star":
			for flip in ([0.0] if symbol == "triangle" else [0.0, PI]):
				var mesh := MeshInstance3D.new()
				var prism := PrismMesh.new()
				prism.size = Vector3(s, s * 0.9, 0.003)
				mesh.mesh = prism
				mesh.material_override = _material(ink)
				plate.add_child(mesh)
				mesh.rotation.z = flip
				# A star is two triangles on the same centroid (a prism is centred on its box, a
				# sixth of its height above the centroid).
				mesh.position = at + (Vector3(0, s * 0.9 / 6.0, 0).rotated(Vector3.FORWARD, -flip) if symbol == "star" else Vector3.ZERO)
		"circle":
			var mesh := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = s * 0.28
			torus.outer_radius = s * 0.45
			torus.rings = 16
			torus.ring_segments = 6
			mesh.mesh = torus
			mesh.material_override = _material(ink)
			plate.add_child(mesh)
			mesh.position = at
			mesh.rotation.x = PI * 0.5
			mesh.scale = Vector3(1, 0.2, 1)
		"cross":
			for angle in [PI * 0.25, -PI * 0.25]:
				var bar := _box(plate, at, Vector3(s * 1.1, s * 0.22, 0.003), ink)
				bar.rotation.z = angle
		"square":
			_box(plate, at, Vector3(s * 0.8, s * 0.8, 0.003), ink)
		"diamond":
			var diamond := _box(plate, at, Vector3(s * 0.65, s * 0.65, 0.003), ink)
			diamond.rotation.z = PI * 0.25

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

static func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html(true)
	if not _materials.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.72
		result.metallic = 0.08
		_materials[key] = result
	return _materials[key]
