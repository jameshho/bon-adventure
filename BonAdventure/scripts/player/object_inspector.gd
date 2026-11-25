extends Node
## Close-up inspection of an object (user request, 13 Nov 2026; docs/guides/HAND_HOLD.md#inspecting).
## open(item, camera) glides the object from where it is to a stage in front of the camera,
## sized to fill part of the view, with a soft dark backdrop behind it (an in-world look, not a
## 2D screen); close() glides it back to the exact place and parent it came from. It knows
## nothing about hands or buttons: scripts/ui/hold_inspect_ui.gd opens it for the held item.
##
## Today it only zooms in and out. Later interactions plug in without changing this file:
##  - `stage` is the node the object sits on: turn it to rotate the object;
##  - add_mode(mode): an object with optional begin(inspector), input(event) -> bool (true =
##    used), process(delta) and end(inspector) runs while an inspection is open (e.g. drag to
##    rotate, open a book's cover);
##  - the object may define on_inspect_begin(inspector) / on_inspect_end(inspector).
## Options (open): yaw and tilt (degrees, how the object faces the camera; yaw 180 shows its -Z
## side, its "front"), fill (share of the view height), seconds (glide time), gentle (ease in
## and out instead of a quick start: a slower, natural lift, e.g. picking up a book to read it),
## fit ("sphere", the default: the bounding sphere fills `fill` of the view height; "face": a flat
## object's front, its local x × y box, fills `fill` of the view height or width, whichever is
## reached first: a wall poster, poster_inspect_ui.gd, 24 Nov 2026), distance (0, the default: the
## object keeps its size and sits as far away as it needs; above 0: it sits this far in front of
## the camera, scaled down to fill the same share, so a big object stays in front of nearby walls).

signal opened(item: Node3D)
signal closed(item: Node3D)

const DEFAULTS := {"yaw": 180.0, "tilt": 10.0, "fill": .72, "seconds": .35, "gentle": false, "fit": "sphere", "distance": 0.0}
## How much the backdrop dims the world (material alpha; fades in and out with the glide).
const BACKDROP_ALPHA := .55

var item: Node3D
var camera: Camera3D
## The object's seat in front of the camera; its child `stage` holds the object.
var anchor: Node3D
var stage: Node3D
var modes: Array = []
var _backdrop: MeshInstance3D
var _from_parent: Node
var _from_index := -1
var _from_local := Transform3D.IDENTITY
var _tween: Tween
var _closing := false

func is_open() -> bool:
	return item != null and is_instance_valid(item)

func add_mode(mode: Object) -> void:
	if not modes.has(mode):
		modes.append(mode)

func remove_mode(mode: Object) -> void:
	modes.erase(mode)

## Starts inspecting `target` in front of `view`. False when one is already open.
func open(target: Node3D, view: Camera3D, options := {}) -> bool:
	if is_open() or target == null or view == null:
		return false
	var o := DEFAULTS.duplicate()
	o.merge(options, true)
	item = target
	camera = view
	_closing = false
	_from_parent = target.get_parent()
	_from_index = target.get_index()
	_from_local = target.transform
	var start := target.global_transform
	# The stage: in front of the camera, far enough that the object's bounding sphere fills
	# `fill` of the view height.
	var box: AABB = preload("res://scripts/player/hand_hold.gd").local_bounds(target)
	var size := box.size * target.global_basis.get_scale()
	var radius := size.length() * .5
	var half_view := tan(deg_to_rad(view.fov) * .5)
	var distance := radius / (float(o.fill) * half_view)
	if str(o.fit) == "face":
		var rect := view.get_viewport().get_visible_rect().size if view.get_viewport() != null else Vector2(16, 9)
		var aspect := rect.x / maxf(rect.y, 1.0)
		distance = maxf(size.y * .5 / (float(o.fill) * half_view), size.x * .5 / (float(o.fill) * half_view * aspect)) + size.z * .5
	# A fixed distance: the object shrinks by the same ratio (its box and radius with it).
	var shrink := 1.0
	if float(o.distance) > 0.0 and distance > float(o.distance):
		shrink = float(o.distance) / distance
		distance = float(o.distance)
		radius *= shrink
	anchor = Node3D.new()
	anchor.name = "InspectAnchor"
	view.add_child(anchor)
	anchor.position = Vector3(0, 0, -maxf(distance, view.near + radius + .05))
	stage = Node3D.new()
	stage.name = "Stage"
	anchor.add_child(stage)
	stage.basis = Basis(Vector3.RIGHT, deg_to_rad(o.tilt)) * Basis(Vector3.UP, deg_to_rad(o.yaw))
	_backdrop = _make_backdrop(view, distance + radius + .1)
	anchor.add_child(_backdrop)
	# Reparent keeping the object where it is, then glide it to the stage centre.
	_from_parent.remove_child(target)
	stage.add_child(target)
	target.global_transform = start
	var scale := target.basis.get_scale() * shrink
	var centre := box.get_center() * scale
	var goal_basis := Basis.from_scale(scale)
	var goal := Transform3D(goal_basis, -centre)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if bool(o.gentle):
		# Eases in and out, like lifting something up to read it (no snap at the start).
		_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(target, "transform", goal, float(o.seconds))
	_tween.parallel().tween_property(_backdrop.mesh.material, "albedo_color:a", BACKDROP_ALPHA, float(o.seconds)).from(0.0)
	for mode in modes:
		if mode.has_method("begin"):
			mode.begin(self)
	if target.has_method("on_inspect_begin"):
		target.on_inspect_begin(self)
	opened.emit(target)
	return true

## Glides the object back where it came from and ends the inspection.
func close(seconds := .3) -> void:
	if not is_open() or _closing:
		return
	_closing = true
	for mode in modes:
		if mode.has_method("end"):
			mode.end(self)
	if item.has_method("on_inspect_end"):
		item.on_inspect_end(self)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_start_close = item.global_transform
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_glide_home, 0.0, 1.0, seconds)
	_tween.parallel().tween_property(_backdrop.mesh.material, "albedo_color:a", 0.0, seconds)
	_tween.finished.connect(_finish_close)

## Ends the inspection at once (no glide): the object is back where it came from now, e.g.
## because a game is taking it out of the hand.
func close_now() -> void:
	if not is_open():
		return
	if not _closing:
		_closing = true
		for mode in modes:
			if mode.has_method("end"):
				mode.end(self)
		if item.has_method("on_inspect_end"):
			item.on_inspect_end(self)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_finish_close()

## Where the object was when closing began, to its home (followed live: the hand may move).
var _start_close := Transform3D.IDENTITY

func _glide_home(t: float) -> void:
	if is_open():
		item.global_transform = _start_close.interpolate_with(_home_global(), t)

func _home_global() -> Transform3D:
	if _from_parent is Node3D and is_instance_valid(_from_parent):
		return (_from_parent as Node3D).global_transform * _from_local
	return _from_local

func _finish_close() -> void:
	if not is_open():
		return
	var target := item
	target.get_parent().remove_child(target)
	if is_instance_valid(_from_parent):
		_from_parent.add_child(target)
		_from_parent.move_child(target, mini(_from_index, _from_parent.get_child_count() - 1))
	target.transform = _from_local
	if anchor != null and is_instance_valid(anchor):
		anchor.queue_free()
	anchor = null
	stage = null
	item = null
	_closing = false
	closed.emit(target)

## Forwards input to the modes while open (hold_inspect_ui.gd calls it); true when one used it.
func handle_input(event: InputEvent) -> bool:
	if not is_open():
		return false
	for mode in modes:
		if mode.has_method("input") and mode.input(event):
			return true
	return false

func _process(delta: float) -> void:
	if is_open() and not _closing:
		for mode in modes:
			if mode.has_method("process"):
				mode.process(delta)

## A dark, soft-edged card behind the object that dims the world while inspecting.
func _make_backdrop(view: Camera3D, depth: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	var height := 2.0 * depth * tan(deg_to_rad(view.fov) * .5) * 1.6
	var aspect := 2.0
	var viewport := view.get_viewport()
	if viewport != null:
		var rect := viewport.get_visible_rect().size
		aspect = rect.x / maxf(rect.y, 1.0)
	quad.size = Vector2(height * aspect, height)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.06, 0.08, 0.12, 0.0)
	material.no_depth_test = false
	material.disable_receive_shadows = true
	quad.material = material
	var backdrop := MeshInstance3D.new()
	backdrop.name = "Backdrop"
	backdrop.mesh = quad
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	backdrop.position = Vector3(0, 0, -(depth - absf(anchor.position.z)))
	return backdrop
