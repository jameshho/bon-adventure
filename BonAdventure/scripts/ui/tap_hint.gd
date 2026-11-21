extends Control
## "Click (or tap) this": a pulsing ring round a 3D object with a mouse pointer (keyboard and
## mouse) or a fingertip (touch) pressing on it, following the object on screen (user, 21 Nov
## 2026: the welcome tutorial's apple, shown when the player has not clicked it; reusable for
## anything a player should click). Drawn only, never takes a click (mouse_filter IGNORE), and
## has no words. Same look as the tutorial's control cues (tutorial_cue.gd, BonStyle colours);
## sized with the window (money_panel.gd: min(height / 800, width / 1100)).
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const INK := BonStyle.INK
const GLOW := BonStyle.GREEN_BOTTOM
const RIM := BonStyle.RIM

## The object pointed at (null: nothing drawn), its point above its origin (metres) and the
## pointer kind.
var target: Node3D
var lift := 0.0
var touch := false

func _init() -> void:
	name = "TapHint"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Points at `node` (`up` metres above its origin); `on_touch` draws a fingertip, not a mouse.
func point_at(node: Node3D, on_touch: bool, up := 0.0) -> void:
	target = node
	touch = on_touch
	lift = up
	queue_redraw()

func clear() -> void:
	target = null
	queue_redraw()

func is_showing() -> bool:
	return is_instance_valid(target)

func _process(_delta: float) -> void:
	if target != null:
		queue_redraw()

func _scale() -> float:
	var screen := get_viewport_rect().size
	return clampf(minf(screen.y / 800.0, screen.x / 1100.0), 0.6, 3.0)

func _draw() -> void:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return
	var camera := get_viewport().get_camera_3d()
	var point := target.global_position + Vector3.UP * lift
	if camera == null or camera.is_position_behind(point):
		return
	var at := camera.unproject_position(point)
	var f := _scale()
	var t := Time.get_ticks_msec() / 1000.0
	# The ring swells and fades out, again and again (a "press here" ripple).
	var phase := fmod(t * 1.2, 1.0)
	var radius := lerpf(26.0, 64.0, phase) * f
	draw_arc(at, radius, 0.0, TAU, 48, Color(GLOW, 1.0 - phase), maxf(3.0, 6.0 * f), true)
	draw_arc(at, 26.0 * f, 0.0, TAU, 48, Color(RIM, 0.95), maxf(3.0, 5.0 * f), true)
	# The pointer presses down on the spot and lifts off.
	var press := absf(sin(t * 3.0))
	var tip := at + Vector2(10.0, 10.0) * f + Vector2(1.0, 1.0) * press * 18.0 * f
	if touch:
		draw_circle(tip, 22.0 * f, Color(GLOW, 0.9))
		draw_arc(tip, 30.0 * f, 0.0, TAU, 40, Color(RIM, 0.9), maxf(2.0, 4.0 * f), true)
	else:
		# A mouse pointer: white arrow with a dark teal outline, its tip on the spot.
		var s := 1.6 * f
		var arrow := PackedVector2Array([Vector2(0, 0), Vector2(0, 30), Vector2(8, 23), Vector2(14, 36), Vector2(20, 33), Vector2(14, 21), Vector2(24, 21)])
		for i in arrow.size():
			arrow[i] = tip + arrow[i] * s
		draw_colored_polygon(arrow, RIM)
		var outline := arrow.duplicate()
		outline.append(arrow[0])
		draw_polyline(outline, INK, maxf(2.0, 3.0 * f), true)
