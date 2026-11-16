extends HBoxContainer
## A minigame session's progress (user decision, 4 Nov 2026): a bar plus "7/20". The
## minigame panels put it in their top row, left of the translate bubble; it is hidden when
## the activity has no target (data/activities.json "progress": 0). Only rounds answered
## right the first time count (scripts/learning/activity_board.gd).
## Use: bar.set_progress(done, target); bar.apply_scale(window factor).
const EDGE := Color("7abfb3")
const FILL := Color("3fae5a")
const TRACK := Color("0c1c27")
const GOLD := Color("fff1c5")

var done := 0
var target := 0
## False hides the "7/20" count (a panel whose title already says "Task 3 of 10").
var show_count := true
var _bar: Control
var _label: Label
var _factor := 1.0

func _init() -> void:
	name = "Progress"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar = Control.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_label = Label.new()
	_label.add_theme_color_override("font_color", GOLD)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false

func set_progress(value: int, goal: int) -> void:
	done = clampi(value, 0, maxi(goal, 0))
	target = goal
	visible = goal > 0
	_label.text = "%d/%d" % [done, target]
	_label.visible = show_count
	_bar.queue_redraw()

func apply_scale(factor: float) -> void:
	_factor = factor
	add_theme_constant_override("separation", roundi(10 * factor))
	_bar.custom_minimum_size = Vector2(180, 18) * factor
	_label.add_theme_font_size_override("font_size", roundi(24 * factor))
	_label.custom_minimum_size = Vector2(70 * factor, 0)
	_bar.queue_redraw()

func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, _bar.size)
	var style := StyleBoxFlat.new()
	style.bg_color = TRACK
	style.border_color = EDGE
	style.set_border_width_all(maxi(1, roundi(2 * _factor)))
	style.set_corner_radius_all(roundi(rect.size.y / 2.0))
	_bar.draw_style_box(style, rect)
	if target <= 0 or done <= 0:
		return
	var inset := 3.0 * _factor
	var inner := rect.grow(-inset)
	inner.size.x *= float(done) / float(target)
	var fill := StyleBoxFlat.new()
	fill.bg_color = FILL
	fill.set_corner_radius_all(roundi(inner.size.y / 2.0))
	_bar.draw_style_box(fill, inner)
