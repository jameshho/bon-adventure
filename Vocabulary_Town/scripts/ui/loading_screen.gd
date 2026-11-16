extends CanvasLayer
## The loading screen while the town builds (PWA restructure phase 3, user decision 12 Nov
## 2026): a few pre-made shots of the town (NPCs, animals; tools/capture_app_art.gd) cross-fade
## with a slow zoom, over a thin progress bar. Cheap on purpose: pictures, no 3D. Main's
## loading_progress drives set_progress(); finish() fades it out and frees it.
## The welcome tutorial's cutscene (tutorial.gd, 12 Nov 2026) shows the same pictures with a
## title instead of the bar (show_title()).
const SHOTS := ["res://assets/ui/app/shot_1.webp", "res://assets/ui/app/shot_2.webp", "res://assets/ui/app/shot_3.webp", "res://assets/ui/app/shot_4.webp"]
const SHOT_SECONDS := 2.6
const FADE_SECONDS := 0.7
const ZOOM := 0.06
const Lexicon := preload("res://scripts/language/lexicon.gd")
const BuildStamp := preload("res://scripts/core/build_stamp.gd")
const FILL := Color("142a38")
const EDGE := Color("7abfb3")
const BAR := Color("3fae5a")
const GOLD := Color("fff1c5")

var _root: Control
var _shots: Array[TextureRect] = []
var _time := 0.0
var _progress := 0.0
var _shown := 0.0
var _track: ColorRect
var _bar: ColorRect
var _label: Label
var _title := false
## "Last update on 11-15 at 19:25", bottom right (user, 15 Nov 2026; build_stamp.gd); none when
## the game runs from the project, and none over the tutorial's title cutscene.
var _stamp: Label

func _init() -> void:
	name = "LoadingScreen"
	layer = 100
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var back := ColorRect.new()
	back.color = FILL.darkened(0.3)
	back.anchor_right = 1.0
	back.anchor_bottom = 1.0
	_root.add_child(back)
	for path in SHOTS:
		if not ResourceLoader.exists(path):
			continue
		var shot := TextureRect.new()
		shot.texture = load(path)
		shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		shot.anchor_right = 1.0
		shot.anchor_bottom = 1.0
		shot.modulate.a = 0.0
		_root.add_child(shot)
		_shots.append(shot)
	_track = ColorRect.new()
	_track.color = Color(FILL, 0.85)
	_root.add_child(_track)
	_bar = ColorRect.new()
	_bar.color = BAR
	_root.add_child(_bar)
	_label = Label.new()
	_label.text = Lexicon.shared().phrase("app.loading", Lexicon.shared().native)
	_label.add_theme_color_override("font_color", GOLD)
	_label.add_theme_color_override("font_outline_color", FILL)
	_root.add_child(_label)
	_stamp = Label.new()
	_stamp.text = BuildStamp.line(Lexicon.shared().native)
	_stamp.visible = _stamp.text != ""
	_stamp.add_theme_color_override("font_color", Color(GOLD, 0.8))
	_stamp.add_theme_color_override("font_outline_color", FILL)
	_root.add_child(_stamp)
	for node in [_track, _bar, _label, _stamp]:
		node.z_index = 2

## Title mode: `text` large over the pictures, no progress bar.
func show_title(text: String) -> void:
	_title = true
	_label.text = text
	_track.visible = false
	_bar.visible = false
	_stamp.visible = false

## Replaces the line over the bar (app.gd's warm-up: "Getting everything ready…").
func set_text(text: String) -> void:
	_label.text = text

func set_progress(fraction: float) -> void:
	_progress = clampf(fraction, 0.0, 1.0)

## Fades out, then frees itself.
func finish() -> void:
	_progress = 1.0
	var fade := create_tween()
	fade.tween_property(_root, "modulate:a", 0.0, 0.6)
	fade.tween_callback(queue_free)

func _process(delta: float) -> void:
	_time += delta
	_shown = move_toward(_shown, _progress, delta * 1.5)
	var screen := _root.get_viewport_rect().size
	var f := clampf(minf(screen.y / 800.0, screen.x / 1100.0), 0.6, 3.0)
	# Each shot holds SHOT_SECONDS and fades in over the one before, zooming in slowly.
	var count := _shots.size()
	if count > 0:
		var current := int(_time / SHOT_SECONDS) % count
		var into := fmod(_time, SHOT_SECONDS)
		var previous := (current - 1 + count) % count
		for i in count:
			var shot := _shots[i]
			var age := -1.0
			if i == current:
				age = into
				shot.modulate.a = clampf(into / FADE_SECONDS, 0.0, 1.0)
			elif i == previous and _time >= SHOT_SECONDS:
				age = into + SHOT_SECONDS
				shot.modulate.a = 1.0
			else:
				shot.modulate.a = 0.0
			shot.z_index = 1 if i == current else 0
			shot.pivot_offset = screen * 0.5
			shot.scale = Vector2.ONE * (1.0 + ZOOM * clampf(age / (SHOT_SECONDS + FADE_SECONDS), 0.0, 1.0))
	var width := screen.x * 0.5
	var height := 14.0 * f
	_track.position = Vector2((screen.x - width) * 0.5, screen.y - 70.0 * f)
	_track.size = Vector2(width, height)
	_bar.position = _track.position
	_bar.size = Vector2(width * _shown, height)
	_label.add_theme_font_size_override("font_size", roundi((54 if _title else 26) * f))
	_label.add_theme_constant_override("outline_size", roundi((14 if _title else 8) * f))
	_label.position = Vector2((screen.x - _label.get_minimum_size().x) * 0.5, screen.y * 0.72 if _title else _track.position.y - 46.0 * f)
	_label.size = _label.get_minimum_size()
	if _stamp.visible:
		_stamp.add_theme_font_size_override("font_size", roundi(18 * f))
		_stamp.add_theme_constant_override("outline_size", roundi(5 * f))
		_stamp.size = _stamp.get_minimum_size()
		_stamp.position = screen - _stamp.size - Vector2(14.0, 10.0) * f
