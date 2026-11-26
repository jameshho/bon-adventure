@tool
extends Node3D
## A record player on its own low walnut stand (user request, 25 Nov 2026; guide
## docs/guides/COMPONENTS.md "Record player"): E, a click or a tap opens the record player panel
## (scripts/ui/record_player_panel.gd, group "record_player_panel"): the camera glides to a
## close-up of the turntable and a card lists every music track of data/sounds.json, so the
## player picks, stops and skips the background music (sound.gd pick_record()).
## The disc spins while music is asked for and shows the playing track's label colour; changing
## the song lifts the tone arm, slows the disc, swaps the label and drops the needle again.
## Reusable: drop scenes/props/record_player.tscn anywhere (its back against a wall, front +Z).
##
## The model is built at load from code (as electrical_box.gd does), so a unit scene saves only
## the root. Sizes are town units (the town has scale 1.3). Origin: the floor under the middle of
## the stand. Silent itself: needle_down / needle_up are the hooks for sounds (sound.gd).
const Interactable := preload("res://scripts/core/interactable.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const Sound := preload("res://scripts/core/sound.gd")

signal needle_down(track: String)
signal needle_up

const GROUP := "record_players"
## The stand: walnut top at STAND_TOP, cabinet on four tapered legs.
const STAND_SIZE := Vector3(0.95, 0.0, 0.58)
const STAND_TOP := 0.86
const LEG_HEIGHT := 0.2
## The turntable's plinth on the stand (width, height, depth).
const PLINTH := Vector3(0.74, 0.1, 0.52)
## Platter centre (x, z on the plinth) and the record's radius.
const PLATTER_AT := Vector2(-0.08, 0.0)
const RECORD_RADIUS := 0.19
const LABEL_RADIUS := 0.066
## Tone arm: pivot (x, z on the plinth), length to the stylus, and its yaw when playing (the
## needle on the record's outer grooves; 0 = resting along the plinth's right side).
const ARM_PIVOT := Vector2(0.25, -0.16)
const ARM_LENGTH := 0.32
const ARM_PLAY := deg_to_rad(38.0)
const ARM_LIFT := deg_to_rad(7.0)
## 33⅓ rpm, and how fast the disc spins up and down (radians per second²).
const SPIN := TAU * 33.333 / 60.0
const SPIN_ACCEL := 4.5
## Each track's label colour (a sleeve of that colour stands in the shelf); others: LABEL_OTHER.
const LABELS := {
	"town": Color("f2a65a"), "loading": Color("b9a3e3"), "quiz": Color("6cc3e8"),
	"errands": Color("8fd067"), "mystery": Color("8a63b8"), "focus": Color("5fbfa8"),
	"outdoors": Color("e8c547"),
}
const LABEL_OTHER := Color("e98a8a")
const WALNUT := Color("8a5a33")
const WALNUT_DARK := Color("5e3b20")
const WALNUT_LIGHT := Color("a8744a")
const BRASS := Color("c9a55a")
const SILVER := Color("c8ccd0")

## The track on the platter (shown even when stopped) and whether it plays.
var track := "town"
var playing := false
var _spin := 0.0
var _disc: Node3D
var _arm: Node3D
var _label_material: StandardMaterial3D
var _lamp_material: StandardMaterial3D
var _arm_tween: Tween
## Set while a record change runs (the arm away): the music state is applied when it lands.
var _changing := false
var _sound
static var _materials := {}

func _ready() -> void:
	add_to_group(GROUP)
	# Moving parts: never merged into the static render batches (render_culling.gd).
	set_meta("keep_own_draw", true)
	_build()
	if Engine.is_editor_hint():
		return
	Interactable.attach(self, {
		"kind": Interactable.Kind.USE,
		"prompt_distance": 2.4,
		"needs_facing": false,
		"on_point": func(from: Vector3) -> Vector3:
			var p := global_position
			return Vector3(p.x, from.y, p.z) if (from - p).dot(facing()) > 0.0 else Vector3.INF,
		"on_badge": func() -> Vector3: return to_global(Vector3(0, STAND_TOP + PLINTH.y + 0.35, 0)),
	})
	_hook_sound.call_deferred()

## The sound service (App or Main adds it, maybe after this unit loads): follow its music.
func _hook_sound() -> void:
	_sound = Sound.shared()
	if _sound == null or not is_instance_valid(_sound):
		_sound = null
		return
	if not _sound.music_changed.is_connected(_on_music_changed):
		_sound.music_changed.connect(_on_music_changed)
	_on_music_changed(_sound.music_wanted())

func _exit_tree() -> void:
	if _sound != null and is_instance_valid(_sound) and _sound.music_changed.is_connected(_on_music_changed):
		_sound.music_changed.disconnect(_on_music_changed)

func _on_music_changed(wanted: String) -> void:
	show_track(wanted, wanted != "")

## While a game runs, E says "finish the other task first" (interactable.gd reason line).
func can_interact() -> Variant:
	return "common.finish_first" if Board.shared().blocker("") != "" else true

## Its interactable's use (E, a click or a tap): opens the panel. True when it opened.
func use() -> bool:
	for panel in get_tree().get_nodes_in_group("record_player_panel"):
		if panel.has_method("open"):
			return panel.open(self)
	return false

func facing() -> Vector3:
	return (global_transform.basis * Vector3(0, 0, 1)).normalized()

## The middle of the record (world space).
func record_center() -> Vector3:
	return to_global(Vector3(PLATTER_AT.x, STAND_TOP + PLINTH.y + 0.03, PLATTER_AT.y))

## Corners of the plinth's top (world space), for the panel's tap target.
func plinth_corners() -> Array:
	var y := STAND_TOP + PLINTH.y
	var out := []
	for x in [-0.5, 0.5]:
		for z in [-0.5, 0.5]:
			out.append(to_global(Vector3(x * PLINTH.x, y, z * PLINTH.z)))
	return out

## Close-up camera: from the front, looking down at the turntable at about 48°, so the plinth is
## `fill` of the view's width; the turntable sits `shift` of the view's width left of centre
## (negative: right of it, beside a card on the left). `aspect`: viewport width / height.
func view_transform(fov: float, aspect: float, fill := 0.36, shift := 0.0) -> Transform3D:
	var scale_x := global_transform.basis.get_scale().x
	var half_h := tan(deg_to_rad(fov) * 0.5)
	var half_w := half_h * maxf(aspect, 0.5)
	var distance := PLINTH.x * scale_x / (fill * 2.0 * half_w)
	var centre := to_global(Vector3(0.02, STAND_TOP + PLINTH.y, 0.0))
	var back := (facing() * cos(deg_to_rad(48.0)) + Vector3.UP * sin(deg_to_rad(48.0))).normalized()
	var from := centre + back * distance
	var look := Transform3D(Basis(), from).looking_at(centre, Vector3.UP)
	var right: Vector3 = look.basis.x
	var shift_by := right * (shift * 2.0 * half_w * distance)
	return Transform3D(look.basis, from + shift_by)

## Shows `name` on the platter, spinning when `play`. A different record, while the arm is on
## it, first lifts the arm (needle_up), slows the disc, swaps the label and drops it again.
func show_track(name: String, play: bool) -> void:
	if name == "":
		play = false
		name = track
	if name == track and play == playing and not _changing:
		return
	if Engine.is_editor_hint() or not is_inside_tree():
		track = name
		playing = play
		_paint_label()
		return
	var swap := name != track and (playing or _changing)
	track = name
	playing = play
	if swap:
		_changing = true
		_move_arm(0.0, true, func() -> void:
			_paint_label()
			_changing = false
			if playing:
				_move_arm(ARM_PLAY, false, func() -> void: needle_down.emit(track)))
		needle_up.emit()
		return
	_paint_label()
	if _changing:
		return
	if play:
		_move_arm(ARM_PLAY, false, func() -> void: needle_down.emit(track))
	else:
		needle_up.emit()
		_move_arm(0.0, false, Callable())

## Swings the arm to `yaw` (0 = rest), lifted on the way; `slow` waits for the disc to stop.
func _move_arm(yaw: float, slow: bool, done: Callable) -> void:
	if _arm_tween != null and _arm_tween.is_valid():
		_arm_tween.kill()
	var lift: Node3D = _arm.get_node("Lift")
	_arm_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arm_tween.tween_property(lift, "rotation:x", -ARM_LIFT, 0.25)
	_arm_tween.tween_property(_arm, "rotation:y", -yaw, 0.7)
	if slow:
		_arm_tween.tween_interval(0.5)
	_arm_tween.tween_property(lift, "rotation:x", 0.0 if yaw > 0.0 else -ARM_LIFT * 0.3, 0.3)
	if done.is_valid():
		_arm_tween.tween_callback(done)

## The disc turns while the needle is down (eases up and down; the label shows the turning).
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _disc == null:
		return
	if _sound == null and Sound.shared() != null:
		_hook_sound()
	var target := SPIN if playing and not _changing else 0.0
	_spin = move_toward(_spin, target, SPIN_ACCEL * delta)
	if _spin > 0.0:
		_disc.rotate_y(-_spin * delta)
	if _lamp_material != null:
		var on := playing and not _changing
		_lamp_material.emission_energy_multiplier = 1.6 if on else 0.0
		_lamp_material.albedo_color = Color("7be06a") if on else Color("43514a")

static func label_color(name: String) -> Color:
	return LABELS.get(name, LABEL_OTHER)

func _paint_label() -> void:
	if _label_material != null:
		_label_material.albedo_color = label_color(track)

# --- Model -----------------------------------------------------------------------------------

func _build() -> void:
	for child in [get_node_or_null("Model"), get_node_or_null("Solid")]:
		if child != null:
			remove_child(child)
			child.free()
	var model := Node3D.new()
	model.name = "Model"
	add_child(model)
	_build_stand(model)
	_build_turntable(model)
	# One solid for picking and blocking: the stand and the turntable on it.
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var high := STAND_TOP + PLINTH.y + 0.06
	box.size = Vector3(STAND_SIZE.x, high, STAND_SIZE.z)
	shape.shape = box
	shape.position = Vector3(0, high * 0.5, 0)
	solid.add_child(shape)
	solid.set_meta("object_name", "record player")
	add_child(solid)
	_paint_label()
	if _arm != null:
		_arm.rotation.y = -ARM_PLAY if playing else 0.0

func _build_stand(model: Node3D) -> void:
	var w := STAND_SIZE.x
	var d := STAND_SIZE.z
	var top := STAND_TOP
	var low := LEG_HEIGHT
	var body_h := top - 0.04 - low
	var mid := low + body_h * 0.5
	# Top slab with a darker edge band, then the cabinet: bottom, back, two sides, a divider.
	_box(model, Vector3(0, top - 0.02, 0), Vector3(w, 0.04, d), WALNUT_LIGHT)
	_box(model, Vector3(0, top - 0.045, 0), Vector3(w - 0.02, 0.012, d - 0.02), WALNUT_DARK)
	_box(model, Vector3(0, low + 0.015, 0), Vector3(w - 0.04, 0.03, d - 0.04), WALNUT)
	_box(model, Vector3(0, mid, -d * 0.5 + 0.035), Vector3(w - 0.04, body_h, 0.02), WALNUT_DARK)
	for side in [-1, 1]:
		_box(model, Vector3(side * (w * 0.5 - 0.035), mid, 0), Vector3(0.03, body_h, d - 0.04), WALNUT)
	_box(model, Vector3(0.06, mid, 0), Vector3(0.025, body_h, d - 0.06), WALNUT)
	# Left: an open shelf of record sleeves, one per track colour, leaning a little.
	var sleeves := LABELS.values()
	for i in sleeves.size():
		var x := -w * 0.5 + 0.08 + i * 0.055
		var sleeve := _box(model, Vector3(x, low + 0.03 + 0.17, 0.01), Vector3(0.022, 0.34, 0.34), (sleeves[i] as Color).lerp(Color("f3ead8"), 0.15))
		sleeve.rotation.z = deg_to_rad(-9.0)
	# Right: a door with a round brass knob and two slim grooves.
	var door_w := w * 0.5 - 0.1
	var door_x := 0.06 + 0.0125 + door_w * 0.5 + 0.005
	_box(model, Vector3(door_x, mid, d * 0.5 - 0.03), Vector3(door_w, body_h - 0.02, 0.025), WALNUT_LIGHT)
	for g in [-1, 1]:
		_box(model, Vector3(door_x, mid + g * body_h * 0.28, d * 0.5 - 0.016), Vector3(door_w - 0.06, 0.008, 0.004), WALNUT_DARK)
	_cylinder(model, Vector3(door_x - door_w * 0.32, mid, d * 0.5 - 0.005), 0.018, 0.018, 0.03, BRASS, Vector3(PI * 0.5, 0, 0))
	# Four tapered legs, set in from the corners.
	for x in [-1, 1]:
		for z in [-1, 1]:
			_cylinder(model, Vector3(x * (w * 0.5 - 0.08), low * 0.5, z * (d * 0.5 - 0.08)), 0.026, 0.016, low, WALNUT_DARK)

func _build_turntable(model: Node3D) -> void:
	var base := STAND_TOP
	var table := Node3D.new()
	table.name = "Turntable"
	model.add_child(table)
	table.position = Vector3(0, base, 0)
	var h := PLINTH.y
	# Plinth: warm wood with a cream top deck, on four small feet.
	for x in [-1, 1]:
		for z in [-1, 1]:
			_cylinder(table, Vector3(x * (PLINTH.x * 0.5 - 0.05), 0.008, z * (PLINTH.z * 0.5 - 0.05)), 0.022, 0.022, 0.016, Color("3a3a3a"))
	_box(table, Vector3(0, 0.016 + (h - 0.016) * 0.5, 0), Vector3(PLINTH.x, h - 0.016, PLINTH.z), WALNUT_LIGHT)
	_box(table, Vector3(0, h + 0.003, 0), Vector3(PLINTH.x - 0.03, 0.006, PLINTH.z - 0.03), Color("f1e6d2"))
	var top := h + 0.006
	# Platter (brushed metal rim) and the spinning record on it.
	var px := PLATTER_AT.x
	var pz := PLATTER_AT.y
	_cylinder(table, Vector3(px, top + 0.012, pz), RECORD_RADIUS + 0.012, RECORD_RADIUS + 0.012, 0.024, SILVER)
	_disc = Node3D.new()
	_disc.name = "Disc"
	table.add_child(_disc)
	_disc.position = Vector3(px, top + 0.024, pz)
	_cylinder(_disc, Vector3(0, 0.004, 0), RECORD_RADIUS, RECORD_RADIUS, 0.008, Color("1d1d22"), Vector3.ZERO, 48, 0.3)
	# Grooves: three faint rings, so the vinyl reads as a record.
	for r in [0.17, 0.135, 0.1]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.004
		torus.outer_radius = r
		torus.rings = 40
		torus.ring_segments = 4
		ring.mesh = torus
		ring.scale = Vector3(1, 0.15, 1)
		ring.material_override = _material(Color("34343c"), 0.35)
		_disc.add_child(ring)
		ring.position = Vector3(0, 0.0085, 0)
	var label := _cylinder(_disc, Vector3(0, 0.0092, 0), LABEL_RADIUS, LABEL_RADIUS, 0.0016, Color.WHITE)
	_label_material = StandardMaterial3D.new()
	_label_material.roughness = 0.8
	label.material_override = _label_material
	# A cream stripe and dot on the label show the turning.
	_box(_disc, Vector3(0, 0.0104, LABEL_RADIUS * 0.5), Vector3(0.012, 0.0012, LABEL_RADIUS * 0.75), Color("fdf4e3"))
	_cylinder(_disc, Vector3(LABEL_RADIUS * 0.55, 0.0104, -LABEL_RADIUS * 0.3), 0.009, 0.009, 0.0012, Color("fdf4e3"))
	_cylinder(_disc, Vector3(0, 0.02, 0), 0.006, 0.006, 0.024, SILVER)
	# Tone arm: a post at the pivot, the arm along +Z (yaw 0 = resting) with a headshell and a
	# counterweight behind the pivot, and a rest post beside it.
	var pivot := Vector3(ARM_PIVOT.x, top, ARM_PIVOT.y)
	_cylinder(table, pivot + Vector3(0, 0.012, 0), 0.034, 0.038, 0.024, Color("3a3d42"))
	_cylinder(table, pivot + Vector3(0, 0.045, 0), 0.012, 0.012, 0.05, SILVER)
	_arm = Node3D.new()
	_arm.name = "ToneArm"
	table.add_child(_arm)
	_arm.position = pivot + Vector3(0, 0.068, 0)
	var lift := Node3D.new()
	lift.name = "Lift"
	_arm.add_child(lift)
	lift.rotation.x = -ARM_LIFT * 0.3
	_cylinder(lift, Vector3(0, 0, ARM_LENGTH * 0.5 - 0.02), 0.0065, 0.0065, ARM_LENGTH - 0.04, SILVER, Vector3(PI * 0.5, 0, 0))
	_cylinder(lift, Vector3(0, 0, -0.055), 0.022, 0.022, 0.04, Color("3a3d42"), Vector3(PI * 0.5, 0, 0))
	var head := _box(lift, Vector3(0, -0.012, ARM_LENGTH - 0.012), Vector3(0.03, 0.014, 0.05), Color("2c2e33"))
	head.rotation.y = deg_to_rad(-18.0)
	_box(lift, Vector3(0, -0.028, ARM_LENGTH), Vector3(0.008, 0.02, 0.008), BRASS)
	_cylinder(table, Vector3(ARM_PIVOT.x, top + 0.025, ARM_PIVOT.y + ARM_LENGTH - 0.07), 0.008, 0.008, 0.05, Color("3a3d42"))
	_arm.rotation.y = 0.0
	# Front: speed knob, a start button and the "on" lamp.
	var front := PLINTH.z * 0.5
	_cylinder(table, Vector3(0.19, h * 0.55, front + 0.008), 0.024, 0.024, 0.016, SILVER, Vector3(PI * 0.5, 0, 0))
	_cylinder(table, Vector3(0.27, h * 0.55, front + 0.006), 0.016, 0.016, 0.012, Color("3a3d42"), Vector3(PI * 0.5, 0, 0))
	var lamp := _cylinder(table, Vector3(0.12, h * 0.55, front + 0.004), 0.008, 0.008, 0.008, Color("43514a"), Vector3(PI * 0.5, 0, 0))
	_lamp_material = StandardMaterial3D.new()
	_lamp_material.albedo_color = Color("43514a")
	_lamp_material.emission_enabled = true
	_lamp_material.emission = Color("7be06a")
	_lamp_material.emission_energy_multiplier = 0.0
	lamp.material_override = _lamp_material

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func _cylinder(parent: Node3D, pos: Vector3, top_r: float, bottom_r: float, height: float, color: Color, turn := Vector3.ZERO, sides := 20, rough := 0.7) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = top_r
	shape.bottom_radius = bottom_r
	shape.height = height
	shape.radial_segments = sides
	shape.rings = 1
	mesh.mesh = shape
	mesh.material_override = _material(color, rough)
	parent.add_child(mesh)
	mesh.position = pos
	mesh.rotation = turn
	return mesh

static func _material(color: Color, rough := 0.7) -> StandardMaterial3D:
	var key := "%s/%.2f" % [color.to_html(true), rough]
	if not _materials.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = rough
		_materials[key] = result
	return _materials[key]
