extends Control
## The electrical box close-up (user request, 9 Nov 2026; docs/guides/ELECTRICAL_BOX.md), opened by
## scripts/learning/electrical_box_session.gd once the camera has glided up to the open box.
## The puzzle is played on the box itself, in 3D (user, 9 Nov 2026: "less cartoony, make it
## 3d"): this panel is a transparent layer over the window that turns the pointer into a ray
## onto the box's wire plane and moves the real wire meshes (scripts/world/electrical_box.gd
## arrange() / set_tip() / connect_wire()). Each wire hangs from a left terminal (colour plate
## and symbol); the matching sockets on the right are in another random order. Drag a wire's
## copper end onto the socket of its colour: it snaps in and the socket glows green; any other
## drop flashes red there and the wire springs back. All in: "Electrical Box Repaired!" and
## `solved`; the session then closes everything.
##
## On screen only a slim bar at the bottom (title, how-to, ✕) and the success card, in the
## HUD's own style (day_clock.gd: dark teal fill, teal / gold edges, cream text).
## - Full window; while visible Main locks the player (minigame_wiring.gd PANELS, locks flag) and Esc
##   emits close_requested through the popup stack, as the ✕ does.
## - Scales with min(window height / 800, window width / 1100) like money_panel.gd; grabbing and
##   dropping are measured on screen with finger-sized radii; touch works through mouse
##   emulation.
const UiText := preload("res://scripts/language/ui_text.gd")

signal close_requested
signal solved
## Sound hooks (scripts/core/sound.gd, later).
signal wire_connected(index: int)
signal wire_rejected(index: int)

const DESIGN := Vector2(1100, 800)
## The HUD's colours (scripts/ui/day_clock.gd).
const BonStyle := preload("res://scripts/ui/bon_style.gd")
# UI art style (18 Nov 2026, docs/guides/UI_STYLE.md): a soft blue bar with a white rim, dark teal
# words, green on hover.
const FILL := Color(0.875, 0.953, 0.957, 0.96)
const EDGE := BonStyle.RIM
const GOLD := BonStyle.INK
const INK := BonStyle.INK
const TEAL := BonStyle.GREEN_BOTTOM
const GOOD := BonStyle.GREEN_BOTTOM
## Seconds: fade in/out, a wire springing back.
const FADE := 0.22
const RETURN := 0.28
## Screen radii (design pixels): grabbing a wire end, dropping on a socket.
const GRAB := 48.0
const DROP := 60.0

## [{"color", "symbol", "left", "right", "connected"}]: left/right are row indices.
var wires: Array = []
## The box being repaired and the close-up camera (set by the session).
var box: Node3D
var camera: Camera3D
var _alpha := 0.0
var _fade_to := 0.0
var _drag := -1
var _grab_offset := Vector2.ZERO
## Wire index -> {"from": Vector3 (box-local), "t": float} while it springs back.
var _returning := {}
var _solved := false
var _solved_t := 0.0
var _rng := RandomNumberGenerator.new()
var _font: Font
var _close_button: Button
var _k := 1.0
var _bar := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_font = BonStyle.font(700)
	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	add_child(_close_button)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_fit_window)
	_fit_window()

## Shows the (still transparent) layer for these wires in a new random order and lays them out
## on the box; the session fades the bar in with show_puzzle() once the camera arrives.
func begin(palette: Array, target: Node3D = null) -> void:
	box = target
	_rng.randomize()
	wires.clear()
	var n := palette.size()
	var left := range(n)
	var right := range(n)
	_shuffle(left)
	_shuffle(right)
	# Never every wire straight across (nothing to do).
	if n > 1:
		var same := true
		for i in n:
			if left[i] != right[i]:
				same = false
		if same:
			var first = right[0]
			right.remove_at(0)
			right.append(first)
	for i in n:
		wires.append({"color": palette[i].color, "symbol": palette[i].symbol, "left": left[i], "right": right[i], "connected": false})
	if is_instance_valid(box):
		box.arrange(left, right)
	_drag = -1
	_returning.clear()
	_solved = false
	_solved_t = 0.0
	_alpha = 0.0
	_fade_to = 0.0
	modulate.a = 0.0
	_close_button.disabled = true
	visible = true
	_fit_window()

func show_puzzle() -> void:
	_fade_to = 1.0
	_close_button.disabled = false

func hide_puzzle() -> void:
	_fade_to = 0.0
	_drag = -1
	_close_button.disabled = true

## The session is done (camera back): the layer goes away and the player is unlocked.
func finish() -> void:
	visible = false
	box = null
	camera = null

## Interface text only, read from UiText when drawn: nothing else to re-render.
func refresh_display() -> void:
	queue_redraw()

func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap

# --- Layout -----------------------------------------------------------------------------

func _fit_window() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_layout()

func _layout() -> void:
	_k = minf(size.y / DESIGN.y, size.x / DESIGN.x)
	var w := minf(size.x - 32 * _k, 760 * _k)
	var h := 64 * _k
	_bar = Rect2(Vector2((size.x - w) * 0.5, size.y - h - 18 * _k), Vector2(w, h))
	var button := 52 * _k
	_close_button.size = Vector2(button, button)
	_close_button.position = Vector2(_bar.end.x - button - 6 * _k, _bar.position.y + (h - button) * 0.5)
	_close_button.add_theme_font_size_override("font_size", int(24 * _k))
	for kind in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		# A cream round ✕, like the money panel's (user's mockup, 18 Nov 2026).
		style.bg_color = Color("fbf1e1") if kind != "hover" else Color("fff8ee")
		if kind == "pressed":
			style.bg_color = Color("f1e2c8")
		style.anti_aliasing = true
		style.border_color = EDGE
		style.set_border_width_all(maxi(3, int(4 * _k)))
		style.set_corner_radius_all(int(button * 0.5))
		_close_button.add_theme_stylebox_override(kind, style)
	_close_button.add_theme_color_override("font_color", INK)
	_close_button.add_theme_color_override("font_hover_color", INK)
	queue_redraw()

# --- The box in screen space --------------------------------------------------------------

func _ready_to_play() -> bool:
	return is_instance_valid(box) and is_instance_valid(camera) and _fade_to >= 1.0 and not _solved

## A box-local point on screen.
func _screen(local: Vector3) -> Vector2:
	return camera.unproject_position(box.to_global(local))

## The pointer on the box's wire plane (box-local), or null when the ray misses it.
func _on_plane(point: Vector2) -> Variant:
	var plane := Plane(box.facing(), box.to_global(Vector3(0, 0, box.WIRE_Z)))
	var hit: Variant = plane.intersects_ray(camera.project_ray_origin(point), camera.project_ray_normal(point))
	if hit == null:
		return null
	var local: Vector3 = box.to_local(hit)
	# Kept inside the box, just in front of the sockets.
	local.x = clampf(local.x, -box.WIDTH * 0.5 + 0.04, box.WIDTH * 0.5 - 0.04)
	local.y = clampf(local.y, -box.HEIGHT * 0.5 + 0.04, box.HEIGHT * 0.5 - 0.04)
	local.z = box.WIRE_Z + 0.015
	return local

# --- Input ------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	accept_event()
	if not _ready_to_play():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = _wire_at(event.position)
			if _drag >= 0:
				_returning.erase(_drag)
				_grab_offset = _screen(box.tip(_drag)) - event.position
		elif _drag >= 0:
			_drop(_drag, event.position + _grab_offset)
			_drag = -1
	elif event is InputEventMouseMotion and _drag >= 0:
		# The end follows the finger; the grab offset shrinks so it ends right under it.
		_grab_offset = _grab_offset.lerp(Vector2.ZERO, 0.25)
		var local: Variant = _on_plane(event.position + _grab_offset)
		if local != null:
			box.set_tip(_drag, local)

## The loose wire whose end (or insulation) is under `point` on screen; -1: none.
func _wire_at(point: Vector2) -> int:
	var best := -1
	var best_distance := GRAB * _k
	for i in wires.size():
		if wires[i].connected:
			continue
		var end := _screen(box.tip(i))
		var start := _screen(box.anchor(i))
		var distance := minf(point.distance_to(end), Geometry2D.get_closest_point_to_segment(point, start, end).distance_to(point) + 10 * _k)
		if distance < best_distance:
			best = i
			best_distance = distance
	return best

## Drops wire i at screen point `point`: into its own socket, or back to rest.
func _drop(i: int, point: Vector2) -> void:
	var row := -1
	var nearest := DROP * _k
	for r in wires.size():
		var distance := point.distance_to(_screen(box.socket(r)))
		if distance < nearest and not _row_taken(r):
			row = r
			nearest = distance
	if row == wires[i].right:
		wires[i].connected = true
		box.connect_wire(i)
		wire_connected.emit(i)
		if wires.all(func(wire: Dictionary) -> bool: return wire.connected):
			_solved = true
			_solved_t = 0.0
			solved.emit()
		return
	if row >= 0:
		box.flash_socket(row, false)
		wire_rejected.emit(i)
	_returning[i] = {"from": box.tip(i), "t": 0.0}

## Drops wire i on right row `row`, as a drop at that socket on screen (used by the checks).
func drop_on_row(i: int, row: int) -> void:
	_drop(i, _screen(box.socket(row)))

func _row_taken(row: int) -> bool:
	return wires.any(func(wire: Dictionary) -> bool: return wire.connected and wire.right == row)

func _process(delta: float) -> void:
	if not visible:
		return
	if not is_equal_approx(_alpha, _fade_to):
		_alpha = move_toward(_alpha, _fade_to, delta / FADE)
		modulate.a = _alpha
	for i in _returning.keys():
		_returning[i].t += delta
		var t: float = clampf(_returning[i].t / RETURN, 0.0, 1.0)
		if is_instance_valid(box):
			box.set_tip(i, (_returning[i].from as Vector3).lerp(box.rest(i), ease(t, 0.35)))
		if t >= 1.0:
			_returning.erase(i)
	if _solved:
		_solved_t += delta
		queue_redraw()

# --- Drawing ----------------------------------------------------------------------------

func _draw() -> void:
	_draw_bar()
	if _solved:
		_draw_success()

## Bottom bar: the box's status lamp, the title and how-to line, and the ✕.
func _draw_bar() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = EDGE
	style.set_border_width_all(maxi(3, int(4 * _k)))
	style.set_corner_radius_all(int(_bar.size.y * 0.5))
	style.shadow_color = Color(0.1, 0.27, 0.32, 0.25)
	style.shadow_size = int(8 * _k)
	draw_style_box(style, _bar)
	var lamp := _bar.position + Vector2(_bar.size.y * 0.5, _bar.size.y * 0.5)
	draw_circle(lamp, 9 * _k, GOOD if _solved else Color("ff5a4a"))
	var x := lamp.x + 22 * _k
	var room := _close_button.position.x - x - 12 * _k
	var title := UiText.t("electrical_box.title")
	draw_string(_font, Vector2(x, _bar.position.y + 27 * _k), title, HORIZONTAL_ALIGNMENT_LEFT, room, int(20 * _k), GOLD)
	var how := UiText.t("electrical_box.how_to")
	var how_size := int(17 * _k)
	var wide := _font.get_string_size(how, HORIZONTAL_ALIGNMENT_LEFT, -1, how_size).x
	if wide > room:
		how_size = maxi(9, int(how_size * room / wide))
	draw_string(_font, Vector2(x, _bar.position.y + 50 * _k), how, HORIZONTAL_ALIGNMENT_LEFT, room, how_size, BonStyle.INK_SOFT)

## "Electrical Box Repaired!" in a HUD card over the upper part of the view.
func _draw_success() -> void:
	var text := UiText.t("electrical_box.repaired")
	var t := clampf(_solved_t / 0.3, 0.0, 1.0)
	var font_size := int(34 * _k)
	var text_w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var card_size := Vector2(text_w + 96 * _k, 76 * _k)
	var at := Vector2((size.x - card_size.x) * 0.5, size.y * 0.035 - 16 * _k * (1.0 - t))
	var card := Rect2(at, card_size)
	var style := StyleBoxFlat.new()
	# "Repaired!" in a cream pill with a green tick (the money panel's request pill).
	style.bg_color = Color(Color("fbf1e1"), t)
	style.border_color = Color(EDGE, t)
	style.set_border_width_all(maxi(3, int(4 * _k)))
	style.set_corner_radius_all(int(card_size.y * 0.5))
	style.shadow_color = Color(0.1, 0.27, 0.32, 0.25 * t)
	style.shadow_size = int(10 * _k)
	draw_style_box(style, card)
	var mark := card.position + Vector2(34 * _k, card_size.y * 0.5)
	draw_circle(mark, 14 * _k, Color(GOOD, t))
	draw_polyline(PackedVector2Array([mark + Vector2(-7, 0) * _k, mark + Vector2(-2, 6) * _k, mark + Vector2(8, -6) * _k]), Color(Color.WHITE, t), 3 * _k, true)
	draw_string(_font, Vector2(card.position.x + 58 * _k, card.position.y + card_size.y * 0.5 + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, t))
