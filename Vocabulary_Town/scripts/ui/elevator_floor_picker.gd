extends Control
## The elevator floor picker (user request, 14 Nov 2026; docs/guides/HOSPITAL_THREE_FLOORS.md "Floor
## picker"). E at the cabin panel of an elevator (hospital_elevator.gd open_floor_picker(): the
## panel's interactable, or E while a cabin button is aimed at) opens it: a temporary camera glides
## from the player's view to a close-up of the real 3D panel, as the electrical box does
## (electrical_box_session.gd), and this transparent layer turns taps and clicks into presses of
## the panel's own ElevatorCallButtons. Their screen targets are the buttons' 1.5× pick boxes.
## - A floor button: pressed through ElevatorCallButton.press() (the elevator's call_elevator()),
##   then the picker closes and the camera glides back.
## - Anywhere outside the panel, the ✕ or Esc (the popup stack: minigame_wiring.gd PANELS
##   "close_requested", which also locks the player while this is visible): closes it.
## - The car may move while it is open (a queued stop): the close-up follows the panel.
## On screen only a slim bar at the bottom (title elevator.choose_floor and the ✕) in the HUD's
## style (electrical_box_panel.gd); scales with min(window height / 800, width / 1100); touch
## works through mouse emulation.
const UiText := preload("res://scripts/language/ui_text.gd")

signal close_requested
## Sound hooks (scripts/core/sound.gd, later).
signal opened(elevator: Node3D)
signal floor_chosen(floor_index: int)
signal closed(elevator: Node3D)

## Elevators find the picker in this group (hospital_elevator.gd open_floor_picker()).
const GROUP := "elevator_floor_picker"
const DESIGN := Vector2(1100, 800)
## The HUD's colours (scripts/ui/day_clock.gd, as electrical_box_panel.gd).
const FILL := Color(0.07, 0.14, 0.19, 0.92)
const EDGE := Color("7abfb3")
const GOLD := Color("e7c27c")
const INK := Color("fff6e6")
const TEAL := Color("a9d5c6")
const FADE := 0.18
## Camera glide in and back (a little quicker than the electrical box: no door to open).
const ZOOM_SECONDS := 0.6
const RETURN_SECONDS := 0.5
## Share of the glide after which the player model is hidden (she may stand in front of the panel).
const HIDE_PLAYER_AT := 0.55
## Screen margin (design pixels) round the panel that still counts as "on the panel".
const PANEL_MARGIN := 14.0

## Main (player, camera, HUD): set by minigame_wiring.gd.
var main
## The elevator whose panel is open (hospital_elevator.gd) and the close-up camera.
var elevator: Node3D
var camera: Camera3D
## "" (closed), "opening", "open" or "closing".
var state := ""
var _tween: Tween
var _alpha := 0.0
var _fade_to := 0.0
var _player_was_visible := true
var _font: Font
var _close_button: Button
var _k := 1.0
var _bar := Rect2()

func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_font = get_theme_default_font()
	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	add_child(_close_button)
	close_requested.connect(close)
	# The minimap, clock and help would show through the close-up (as electrical_box_session.gd).
	visibility_changed.connect(func() -> void:
		if main != null and main.hud != null:
			main.hud.hide_for_game(visible, "elevator_picker"))
	resized.connect(_layout)
	get_viewport().size_changed.connect(_fit_window)
	_fit_window()

## Opens the picker on `lift`'s cabin panel. False when it cannot open now.
func open(lift: Node3D) -> bool:
	if state != "" or lift == null or main == null or main.player == null:
		return false
	if main.player.seated or is_instance_valid(main.active_vehicle) or not main.player.controls_enabled:
		return false
	elevator = lift
	state = "opening"
	get_parent().move_child(self, -1)
	main.interaction.clear_card()
	var from: Camera3D = main.player.camera
	camera = Camera3D.new()
	camera.name = "ElevatorPickerCamera"
	camera.fov = from.fov
	camera.near = minf(from.near, 0.05)
	camera.far = from.far
	camera.cull_mask = from.cull_mask
	camera.attributes = from.attributes
	camera.environment = from.environment
	main.add_child(camera)
	camera.global_transform = from.global_transform
	camera.make_current()
	_player_was_visible = main.player.visible
	_alpha = 0.0
	_fade_to = 0.0
	modulate.a = 0.0
	_close_button.disabled = true
	visible = true
	_fit_window()
	_glide(from.global_transform, ZOOM_SECONDS, _on_arrived, false)
	opened.emit(elevator)
	return true

## Esc, the ✕, a click outside the panel or a chosen floor: the camera glides back.
func close() -> void:
	if state == "" or state == "closing":
		return
	state = "closing"
	_fade_to = 0.0
	_close_button.disabled = true
	main.player.visible = _player_was_visible
	if not is_instance_valid(camera):
		_on_returned()
		return
	_glide(camera.global_transform, RETURN_SECONDS, _on_returned, true)

## Presses floor `i` on the open panel (a tap on its button; also used by the checks).
func choose(i: int) -> void:
	if state != "open" or not is_instance_valid(elevator) or i < 0 or i >= elevator.cabin_buttons.size():
		return
	# The button's own path: lights it and calls the car (a press at the car's floor does nothing).
	elevator.cabin_buttons[i].press()
	floor_chosen.emit(i)
	close()

func is_open() -> bool:
	return state != ""

## Interface text only, read from UiText when drawn.
func refresh_display() -> void:
	queue_redraw()

# --- Camera -----------------------------------------------------------------------------

func _view() -> Transform3D:
	return elevator.panel_view_transform(camera.fov)

func _glide(from: Transform3D, seconds: float, done: Callable, returning: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_place_camera.bind(from, returning), 0.0, 1.0, seconds)
	_tween.tween_callback(done)

func _place_camera(t: float, from: Transform3D, returning: bool) -> void:
	if not is_instance_valid(camera):
		return
	if not returning and not is_instance_valid(elevator):
		return
	# Both ends are live: the panel rides the car, the player camera follows the player.
	var target: Transform3D = main.player.camera.global_transform if returning else _view()
	camera.global_transform = from.interpolate_with(target, t)
	if not returning and t >= HIDE_PLAYER_AT:
		main.player.visible = false

func _on_arrived() -> void:
	if state != "opening":
		return
	state = "open"
	_fade_to = 1.0
	_close_button.disabled = false

func _on_returned() -> void:
	if is_instance_valid(main.player.camera):
		main.player.camera.make_current()
	if is_instance_valid(camera):
		camera.queue_free()
	camera = null
	var lift := elevator
	elevator = null
	state = ""
	visible = false
	closed.emit(lift)

func _process(delta: float) -> void:
	if not visible:
		return
	if state != "closing" and state != "" and not is_instance_valid(elevator):
		close()
		return
	# Open: the close-up stays on the panel while the car moves.
	if state == "open" and is_instance_valid(camera):
		camera.global_transform = _view()
	if not is_equal_approx(_alpha, _fade_to):
		_alpha = move_toward(_alpha, _fade_to, delta / FADE)
		modulate.a = _alpha
	queue_redraw()

# --- The panel on screen ----------------------------------------------------------------

## Screen rect of a cabin button's pick box (its 1.5× hit area), or an empty rect.
func button_rect(i: int) -> Rect2:
	if not is_instance_valid(elevator) or not is_instance_valid(camera):
		return Rect2()
	var b: Node3D = elevator.cabin_buttons[i]
	var half: Vector2 = b.pick_extent() * 0.5
	return _screen_rect(b, [Vector3(-half.x, -half.y, 0.03), Vector3(half.x, half.y, 0.03)])

## Screen rect of the whole cabin panel, with a small margin.
func panel_rect() -> Rect2:
	if not is_instance_valid(elevator) or not is_instance_valid(camera):
		return Rect2()
	var panel: Node3D = elevator.cabin_panel
	var half: Vector2 = elevator.panel_size() * 0.5
	var rect := _screen_rect(panel, [Vector3(-half.x, -half.y, 0), Vector3(half.x, half.y, 0)])
	for i in elevator.cabin_buttons.size():
		rect = rect.merge(button_rect(i))
	return rect.grow(PANEL_MARGIN * _k)

func _screen_rect(node: Node3D, corners: Array) -> Rect2:
	var a: Vector2 = camera.unproject_position(node.to_global(corners[0]))
	var b: Vector2 = camera.unproject_position(node.to_global(corners[1]))
	return Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (a - b).abs())

## The floor whose button is under `point` (-1: none); the nearest centre wins.
func floor_at(point: Vector2) -> int:
	var best := -1
	var best_distance := INF
	if not is_instance_valid(elevator):
		return best
	for i in elevator.cabin_buttons.size():
		var rect := button_rect(i)
		if rect.has_point(point) and point.distance_to(rect.get_center()) < best_distance:
			best = i
			best_distance = point.distance_to(rect.get_center())
	return best

## A tap or click at `point`: a floor button presses it, outside the panel closes, on the panel
## between buttons nothing happens.
func tap(point: Vector2) -> void:
	if state != "open":
		return
	var i := floor_at(point)
	if i >= 0:
		choose(i)
	elif not panel_rect().has_point(point):
		close()

func _gui_input(event: InputEvent) -> void:
	accept_event()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tap(event.position)

# --- Layout and drawing -----------------------------------------------------------------

func _fit_window() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_layout()

func _layout() -> void:
	_k = minf(size.y / DESIGN.y, size.x / DESIGN.x)
	var w := minf(size.x - 32 * _k, 520 * _k)
	var h := 64 * _k
	_bar = Rect2(Vector2((size.x - w) * 0.5, size.y - h - 18 * _k), Vector2(w, h))
	var button := 52 * _k
	_close_button.size = Vector2(button, button)
	_close_button.position = Vector2(_bar.end.x - button - 6 * _k, _bar.position.y + (h - button) * 0.5)
	_close_button.add_theme_font_size_override("font_size", int(24 * _k))
	for kind in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1d3a4c") if kind != "hover" else Color("1d3a4c").lightened(0.12)
		style.border_color = TEAL if kind == "hover" else EDGE
		style.set_border_width_all(maxi(2, int(2 * _k)))
		style.set_corner_radius_all(int(button * 0.5))
		_close_button.add_theme_stylebox_override(kind, style)
	_close_button.add_theme_color_override("font_color", INK)
	_close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	queue_redraw()

func _draw() -> void:
	# A soft ring round every floor button: each is a big, clearly separate target.
	if state == "open" and is_instance_valid(elevator):
		for i in elevator.cabin_buttons.size():
			var rect := button_rect(i)
			if rect.size.x <= 0.0:
				continue
			var radius := minf(rect.size.x, rect.size.y) * 0.42
			draw_arc(rect.get_center(), radius, 0.0, TAU, 48, Color(TEAL, 0.75), maxf(2.0, 3.0 * _k), true)
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = EDGE
	style.set_border_width_all(maxi(2, int(2 * _k)))
	style.set_corner_radius_all(int(_bar.size.y * 0.5))
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = int(8 * _k)
	draw_style_box(style, _bar)
	var x := _bar.position.x + 28 * _k
	var room := _close_button.position.x - x - 12 * _k
	var title := UiText.t("elevator.choose_floor")
	var title_size := int(24 * _k)
	var wide := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	if wide > room:
		title_size = maxi(10, int(title_size * room / wide))
	draw_string(_font, Vector2(x, _bar.get_center().y + title_size * 0.35), title, HORIZONTAL_ALIGNMENT_LEFT, room, title_size, GOLD)
