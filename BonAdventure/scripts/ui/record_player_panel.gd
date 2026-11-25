extends Control
## The record player panel (user request, 25 Nov 2026; guide docs/guides/COMPONENTS.md "Record
## player"). E at a record player (scripts/world/record_player.gd use()) opens it: a temporary
## camera glides from the player's view to a close-up of the turntable, as the elevator floor
## picker does (elevator_floor_picker.gd), and a card on the left lists every music track of
## data/sounds.json (sound.gd track_names()) by its title (phrases record_player.song_<track>).
## - A song: plays it (sound.gd pick_record(): it stays the town's music after games) and the
##   record on the platter changes (the arm lifts, the label swaps, the needle drops).
## - ◀ / ▶: the previous / next song; the big green button stops or plays the record again; a
##   tap or click on the turntable itself does the same.
## - The ✕ or Esc (the popup stack: minigame_wiring.gd PANELS "close_requested", which also locks
##   the player while this is visible): the camera glides back; the music keeps playing.
## Built with BonStyle (docs/guides/UI_STYLE.md); scales with the window factor; touch works
## through mouse emulation.
const UiText := preload("res://scripts/language/ui_text.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const Sound := preload("res://scripts/core/sound.gd")
const RecordPlayer := preload("res://scripts/world/record_player.gd")

signal close_requested
## Sound hooks (scripts/core/sound.gd, later).
signal opened(record_player: Node3D)
signal song_chosen(track: String)
signal closed(record_player: Node3D)

## Record players find the panel in this group (record_player.gd use()).
const GROUP := "record_player_panel"
const FADE := 0.18
const ZOOM_SECONDS := 0.7
const RETURN_SECONDS := 0.5
## Share of the glide after which the player model is hidden (she may stand in the view).
const HIDE_PLAYER_AT := 0.55
## Design sizes (1100 × 800, times the window factor).
const ROW := Vector2(380, 56)
const MARGIN := 24.0

## Main (player, camera, HUD): set by minigame_wiring.gd.
var main
## The record player whose close-up is open, and the close-up camera.
var record: Node3D
var camera: Camera3D
## "" (closed), "opening", "open" or "closing".
var state := ""
var _tween: Tween
var _alpha := 0.0
var _fade_to := 0.0
var _player_was_visible := true
var _f := 1.0
var _card: PanelContainer
var _icons := {}

func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	theme = BonStyle.theme()
	close_requested.connect(close)
	# The minimap, clock and help would show through the close-up (as the elevator picker).
	visibility_changed.connect(func() -> void:
		if main != null and main.hud != null:
			main.hud.hide_for_game(visible, "record_player"))
	get_viewport().size_changed.connect(_fit_window)
	_fit_window()

## Opens the close-up on `player`'s turntable. False when it cannot open now.
func open(player: Node3D) -> bool:
	if state != "" or player == null or main == null or main.player == null:
		return false
	if main.player.seated or is_instance_valid(main.active_vehicle) or not main.player.controls_enabled:
		return false
	record = player
	state = "opening"
	get_parent().move_child(self, -1)
	main.interaction.clear_card()
	var from: Camera3D = main.player.camera
	camera = Camera3D.new()
	camera.name = "RecordPlayerCamera"
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
	visible = true
	_fit_window()
	_glide(from.global_transform, ZOOM_SECONDS, _on_arrived, false)
	opened.emit(record)
	return true

## The ✕ or Esc: the camera glides back (the record keeps playing).
func close() -> void:
	if state == "" or state == "closing":
		return
	state = "closing"
	_fade_to = 0.0
	main.player.visible = _player_was_visible
	if not is_instance_valid(camera):
		_on_returned()
		return
	_glide(camera.global_transform, RETURN_SECONDS, _on_returned, true)

func is_open() -> bool:
	return state != ""

## The songs, in catalogue order (every music track).
func tracks() -> Array:
	var sound = Sound.shared()
	return sound.track_names() if sound != null else RecordPlayer.LABELS.keys()

## The song on the platter.
func selected() -> String:
	return str(record.track) if is_instance_valid(record) else ""

func is_playing() -> bool:
	return is_instance_valid(record) and bool(record.playing)

## Plays `track` (a tap on its row, ◀ / ▶; also used by the checks).
func choose(track: String) -> void:
	if state != "open" or not is_instance_valid(record) or not track in tracks():
		return
	var sound = Sound.shared()
	if sound != null:
		sound.pick_record(track)
	record.show_track(track, true)
	song_chosen.emit(track)
	_rebuild.call_deferred()

## Stops the record, or plays it again (the green button, a tap on the turntable).
func toggle() -> void:
	if state != "open" or not is_instance_valid(record):
		return
	if is_playing():
		var sound = Sound.shared()
		if sound != null:
			sound.pick_record("")
		record.show_track(selected(), false)
		_rebuild.call_deferred()
	else:
		choose(selected())

## The previous (-1) or next (+1) song, round the list.
func step(direction: int) -> void:
	var list := tracks()
	if list.is_empty():
		return
	var at := maxi(0, list.find(selected()))
	choose(str(list[posmod(at + direction, list.size())]))

## A song's title in the native language.
static func title_of(track: String) -> String:
	var id := "record_player.song_" + track
	return UiText.t(id) if UiText.has(id) else track.capitalize()

## Interface text only: rebuilt in the new language.
func refresh_display() -> void:
	if visible:
		_rebuild()

# --- Camera -----------------------------------------------------------------------------------

func _view() -> Transform3D:
	var view := get_viewport_rect().size
	# The card is on the left (the HUD's EN and Settings stay top right): the turntable right of centre.
	return record.view_transform(camera.fov, view.x / maxf(view.y, 1.0), 0.36, -0.19)

func _glide(from: Transform3D, seconds: float, done: Callable, returning: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_place_camera.bind(from, returning), 0.0, 1.0, seconds)
	_tween.tween_callback(done)

func _place_camera(t: float, from: Transform3D, returning: bool) -> void:
	if not is_instance_valid(camera):
		return
	if not returning and not is_instance_valid(record):
		return
	var target: Transform3D = main.player.camera.global_transform if returning else _view()
	camera.global_transform = from.interpolate_with(target, t)
	if not returning and t >= HIDE_PLAYER_AT:
		main.player.visible = false

func _on_arrived() -> void:
	if state != "opening":
		return
	state = "open"
	_fade_to = 1.0
	_rebuild()

func _on_returned() -> void:
	if is_instance_valid(main.player.camera):
		main.player.camera.make_current()
	if is_instance_valid(camera):
		camera.queue_free()
	camera = null
	var player := record
	record = null
	state = ""
	visible = false
	if _card != null:
		_card.queue_free()
		_card = null
	closed.emit(player)

func _process(delta: float) -> void:
	if not visible:
		return
	if state != "closing" and state != "" and not is_instance_valid(record):
		close()
		return
	if not is_equal_approx(_alpha, _fade_to):
		_alpha = move_toward(_alpha, _fade_to, delta / FADE)
		modulate.a = _alpha

# --- Taps on the turntable --------------------------------------------------------------------

## Screen rect of the turntable's top (empty while closed).
func turntable_rect() -> Rect2:
	if not is_instance_valid(record) or not is_instance_valid(camera):
		return Rect2()
	var rect := Rect2()
	var first := true
	for corner in record.plinth_corners():
		var p: Vector2 = camera.unproject_position(corner)
		if first:
			rect = Rect2(p, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(p)
	return rect

func _gui_input(event: InputEvent) -> void:
	accept_event()
	if state == "open" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if turntable_rect().has_point(event.position):
			toggle()

# --- The card ---------------------------------------------------------------------------------

func _fit_window() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	var f := BonStyle.factor(size, 0.5)
	if not is_equal_approx(f, _f) or _card == null:
		_f = f
		if visible and state == "open":
			_rebuild()
	_place_card()

func _place_card() -> void:
	if _card == null:
		return
	_card.reset_size()
	var card_size := _card.get_combined_minimum_size()
	_card.size = card_size
	_card.position = Vector2(MARGIN * _f, maxf(8.0, (size.y - card_size.y) * 0.5))

func _rebuild() -> void:
	if _card != null:
		_card.queue_free()
		_card = null
	if state != "open" or not is_instance_valid(record):
		return
	var f := _f
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", roundi(8 * f))
	# Header: the title and the cream ✕.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", roundi(12 * f))
	var title := BonStyle.label(UiText.t("record_player.title"), 34, BonStyle.INK, f, 700, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := BonStyle.button("", "minor", "close", f, 26, Vector2(60, 60))
	close_button.name = "Close"
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)
	content.add_child(header)
	var line := UiText.t("record_player.now_playing", {"song": title_of(selected())}) if is_playing() else UiText.t("record_player.stopped")
	var status := BonStyle.label(line, 22, BonStyle.INK_SOFT, f, 600, HORIZONTAL_ALIGNMENT_LEFT)
	status.name = "Status"
	content.add_child(status)
	# One pill per song: the playing (or stopped) record is green with a tick.
	var songs := VBoxContainer.new()
	songs.name = "Songs"
	songs.add_theme_constant_override("separation", roundi(6 * f))
	for track in tracks():
		var row := BonStyle.choice(_disc_icon(str(track)), title_of(str(track)), str(track) == selected(), f, ROW)
		row.name = "Song_" + str(track)
		for child in row.get_children():
			for label in child.get_children():
				if label is Label:
					label.add_theme_font_size_override("font_size", roundi(26 * f))
		row.pressed.connect(choose.bind(str(track)))
		songs.add_child(row)
	content.add_child(songs)
	# ◀  ▶/⏸  ▶
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", roundi(16 * f))
	var back := BonStyle.button("", "soft", "arrow_left", f, 30, Vector2(88, 72))
	back.name = "Previous"
	back.pressed.connect(step.bind(-1))
	var play := BonStyle.button("", "primary", "pause" if is_playing() else "play", f, 34, Vector2(124, 72))
	play.name = "PlayPause"
	play.pressed.connect(toggle)
	var forward := BonStyle.button("", "soft", "arrow_right", f, 30, Vector2(88, 72))
	forward.name = "Next"
	forward.pressed.connect(step.bind(1))
	for button in [back, play, forward]:
		controls.add_child(button)
	content.add_child(controls)
	_card = BonStyle.card(content, f, false)
	_card.name = "Card"
	add_child(_card)
	_place_card()

## A small record in the song's label colour (its row's picture).
func _disc_icon(track: String) -> Texture2D:
	if _icons.has(track):
		return _icons[track]
	var label := RecordPlayer.label_color(track).to_html(false)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">'
	svg += '<circle cx="32" cy="32" r="29" fill="#1d1d22" stroke="#fffdf7" stroke-width="3"/>'
	svg += '<circle cx="32" cy="32" r="22" fill="none" stroke="#3a3a44" stroke-width="1.5"/>'
	svg += '<circle cx="32" cy="32" r="17" fill="none" stroke="#3a3a44" stroke-width="1.5"/>'
	svg += '<circle cx="32" cy="32" r="11" fill="#%s"/><circle cx="32" cy="32" r="2.5" fill="#fdf4e3"/></svg>' % label
	var image := Image.new()
	image.load_svg_from_string(svg, 2.0)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_icons[track] = texture
	return texture
