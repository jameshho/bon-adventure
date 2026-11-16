extends Control
## Radar Patrol screen (pastime, 9 Nov 2026; docs/guides/RADAR_PATROL.md). Opened by a click or E on
## either radar in the airport control tower (scripts/objects/radar_console.gd). A square
## green arcade screen with a large circular radar (about 85% of it), a rotating sweep,
## pixel planes and UFOs, and a compact score box. The rules live in
## scripts/learning/radar_patrol_game.gd; this panel draws them and turns taps into radar
## points. English arcade text in every language (user decision, 9 Nov 2026).
##
## - Full window; while visible it swallows keys except Esc (Main's popup stack emits
##   close_requested) and Main locks the player (minigame_wiring.gd PANELS, locks flag).
## - Best score, best combo and most UFOs destroyed in one game are saved in user://radar_patrol.json.
## - Bottom corners: pause (left) and ✕ (right), sized for a finger.
const Game := preload("res://scripts/learning/radar_patrol_game.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
## Best scores, in the active profile (save_store.gd).
const SAVE_FILE := "radar_patrol.json"
const SaveStore := preload("res://scripts/core/save_store.gd")

signal close_requested

const BG := Color("06140b")
const SCREEN := Color("0a2a15")
const SCREEN_DEEP := Color("061d0e")
const LINE := Color("3fbf5a")
const BRIGHT := Color("a8ff9a")
const GLOW := Color("7dff6e")
const AMBER := Color("ffd24a")
const DANGER := Color("ff5a4a")

## Pixel art, drawn one square per character. Plane faces +x (rotated to its heading).
const PLANE := [
	".....##.....",
	".....###....",
	"#....###....",
	"##...####...",
	"############",
	"############",
	"##...####...",
	"#....###....",
	".....###....",
	".....##.....",
]
const UFO := [
	"....ooooo....",
	"...ooaaaoo...",
	"...oaeaeao...",
	".###########.",
	"#############",
	"#l##l###l##l#",
	".###########.",
	"...##...##...",
]
const UFO_COLORS := {"o": Color(0.75, 1.0, 0.75, 0.55), "a": Color("c8ff5a"), "e": Color("0b2a12"), "#": Color("9cf28c"), "l": Color("ffe36a")}

enum State { READY, PLAYING, PAUSED, CRASH, OVER }

var game := Game.new()
var state := State.READY
var best := 0
var best_combo := 0
var new_best := false
## Most UFOs destroyed in one game (shown under BEST on the game-over screen; user, 9 Nov 2026).
var best_kills := 0
var new_best_kills := false
var _crash_timer := 0.0
var _clock := 0.0
var _effects: Array = []
var _stars: Array = []
var _font: Font
var _square := Rect2()
var _centre := Vector2.ZERO
var _radius := 1.0
var _pause_button: Button
var _close_button: Button
var _again_button: Button
var _leave_button: Button

func _ready() -> void:
	# Not in the "radar_patrol" group: only the session answers a radar (radar_console.gd).
	# Top-left anchors: _fit_window() sizes the panel to the window itself.
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	visible = false
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "SF Mono", "Consolas", "DejaVu Sans Mono", "Courier New", "monospace"])
	mono.font_weight = 700
	# Browsers have no system fonts: the built-in font (with its Chinese fallback, cjk_font.gd).
	mono.fallbacks = [ThemeDB.fallback_font]
	_font = mono
	var stars_rng := RandomNumberGenerator.new()
	stars_rng.seed = 41
	for i in 9:
		_stars.append(Vector2.from_angle(stars_rng.randf() * TAU) * stars_rng.randf_range(0.25, 0.9))
	_pause_button = _round_button("II", _toggle_pause)
	_close_button = _round_button("✕", func() -> void: close_requested.emit())
	_again_button = _wide_button("PLAY AGAIN", start)
	_leave_button = _wide_button("LEAVE", func() -> void: close_requested.emit())
	close_requested.connect(close)
	resized.connect(_layout)
	# The HUD parent has no size of its own: fill the window (as the other game panels do).
	get_viewport().size_changed.connect(_fit_window)
	_load_best()
	_fit_window()

## Opens the screen at the "tap to start" card (called by radar_console.gd through the group).
func open_game() -> void:
	if visible:
		return
	game.reset()
	state = State.READY
	_effects.clear()
	visible = true
	_fit_window()
	queue_redraw()

func close() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
	visible = false

func start() -> void:
	game.reset()
	_effects.clear()
	new_best = false
	new_best_kills = false
	state = State.PLAYING
	_layout()

## English only: nothing to re-render on a language change (minigame_wiring.gd calls it).
func refresh_display() -> void:
	pass

func _toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
	elif state == State.PAUSED:
		state = State.PLAYING
	_layout()

func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	if state == State.PLAYING:
		game.step(minf(delta, 0.05))
		_take_events()
		if game.over:
			state = State.CRASH
			_crash_timer = 1.4
			if game.score > best:
				best = game.score
				new_best = true
			best_combo = maxi(best_combo, game.best_combo)
			if game.kills > best_kills:
				best_kills = game.kills
				new_best_kills = true
			_save_best()
	elif state == State.CRASH:
		_crash_timer -= delta
		if _crash_timer <= 0.0:
			state = State.OVER
			_layout()
	for effect in _effects:
		effect["age"] += delta
	_effects = _effects.filter(func(e): return e["age"] < e["life"])
	queue_redraw()

func _take_events() -> void:
	for event in game.events:
		var life: float = {"pop": 0.8, "miss": 0.35, "friendly": 0.9, "escape": 1.1, "crash": 1.0e9}.get(event["kind"], 0.6)
		_effects.append({"kind": event["kind"], "pos": event["pos"], "text": event["text"], "age": 0.0, "life": life})
	game.events.clear()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_SPACE, KEY_ENTER, KEY_P]:
			if state == State.READY and key.keycode != KEY_P:
				start()
			elif state == State.OVER and key.keycode != KEY_P:
				start()
			elif state in [State.PLAYING, State.PAUSED]:
				_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	var press: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not press:
		return
	accept_event()
	var at: Vector2 = (event as InputEventMouseButton).position
	match state:
		State.READY:
			if _square.has_point(at):
				start()
		State.PAUSED:
			_toggle_pause()
		State.PLAYING:
			# Finger-friendly reach (about a fingertip, 30 px) that grows on small screens
			# (user, 15 Nov 2026: was 18 px, 0.03-0.08).
			var slop := clampf(30.0 / _radius, 0.06, 0.14)
			game.tap((at - _centre) / _radius, slop)
			_take_events()

# --- Layout -----------------------------------------------------------------------------

func _fit_window() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_layout()

func _layout() -> void:
	var side := minf(size.x, size.y) * 0.95
	_square = Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	_centre = _square.position + Vector2(side * 0.5, side * 0.535)
	_radius = side * 0.425
	var k := side / 800.0
	var corner := side * 0.085
	for button in [_pause_button, _close_button]:
		button.size = Vector2(corner, corner)
		button.add_theme_font_size_override("font_size", int(26 * k))
	_pause_button.position = _square.position + Vector2(side * 0.025, side * 0.975 - corner)
	_close_button.position = _square.position + Vector2(side * 0.975 - corner, side * 0.975 - corner)
	_pause_button.text = "▶" if state == State.PAUSED else "II"
	_pause_button.visible = state in [State.PLAYING, State.PAUSED]
	var wide := Vector2(side * 0.3, side * 0.085)
	for button in [_again_button, _leave_button]:
		button.size = wide
		button.add_theme_font_size_override("font_size", int(26 * k))
		button.visible = state == State.OVER
	_again_button.position = _centre + Vector2(-wide.x - side * 0.015, side * 0.18)
	_leave_button.position = _centre + Vector2(side * 0.015, side * 0.18)
	for button in [_pause_button, _close_button, _again_button, _leave_button]:
		_style(button, button.size.y * (0.5 if button in [_pause_button, _close_button] else 0.18))

func _round_button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	add_child(button)
	return button

func _wide_button(label: String, action: Callable) -> Button:
	return _round_button(label, action)

func _style(button: Button, corner_radius: float) -> void:
	for kind in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.1, 0.35, 0.16, 0.85) if kind == "normal" else (Color(0.16, 0.5, 0.22, 0.95) if kind == "hover" else Color(0.25, 0.65, 0.3))
		box.border_color = BRIGHT if kind != "normal" else LINE
		box.set_border_width_all(maxi(2, int(button.size.y * 0.05)))
		box.set_corner_radius_all(int(corner_radius))
		box.shadow_color = Color(GLOW, 0.25)
		box.shadow_size = int(button.size.y * 0.12)
		button.add_theme_stylebox_override(kind, box)
	button.add_theme_font_override("font", _font)
	button.add_theme_color_override("font_color", BRIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

# --- Drawing ----------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.82))
	var side := _square.size.x
	var k := side / 800.0
	_draw_frame(k)
	_draw_radar(k)
	_draw_entities(k)
	_draw_effects(k)
	_draw_header(k)
	_draw_cards(k)
	# Scanlines over the whole screen.
	var y := _square.position.y
	var step := maxf(3.0, 3.0 * k)
	while y < _square.end.y:
		draw_line(Vector2(_square.position.x, y), Vector2(_square.end.x, y), Color(0, 0, 0, 0.09), 1.0)
		y += step

func _draw_frame(k: float) -> void:
	var outer := StyleBoxFlat.new()
	outer.bg_color = BG
	outer.border_color = Color("2c7a3f")
	outer.set_border_width_all(int(4 * k) + 1)
	outer.set_corner_radius_all(int(22 * k))
	outer.shadow_color = Color(GLOW, 0.18)
	outer.shadow_size = int(18 * k)
	draw_style_box(outer, _square)
	var inner := StyleBoxFlat.new()
	inner.bg_color = SCREEN_DEEP
	inner.border_color = Color("1d5a2c")
	inner.set_border_width_all(int(2 * k) + 1)
	inner.set_corner_radius_all(int(16 * k))
	draw_style_box(inner, _square.grow(-10 * k))

func _draw_radar(k: float) -> void:
	var c := _centre
	var r := _radius
	# Bezel: soft glow, thick bright ring, thin inner ring.
	for i in 6:
		draw_arc(c, r * 1.07 + i * 3 * k, 0, TAU, 128, Color(GLOW, 0.05 - i * 0.007), 6 * k)
	draw_circle(c, r * 1.065, Color("0f3d1d"))
	draw_arc(c, r * 1.065, 0, TAU, 160, Color("5fd86a"), 5 * k)
	draw_arc(c, r * 1.035, 0, TAU, 160, Color("2f9a45"), 3 * k)
	# Screen: dark green, slightly lighter towards the middle.
	draw_circle(c, r, SCREEN)
	for i in 8:
		draw_circle(c, r * (1.0 - i * 0.11), Color(0.2, 0.6, 0.25, 0.025))
	# Square grid, clipped to the circle.
	var cells := 8
	for i in range(1, cells):
		var d := -r + 2.0 * r * i / cells
		var half := sqrt(maxf(r * r - d * d, 0.0))
		draw_line(c + Vector2(d, -half), c + Vector2(d, half), Color(LINE, 0.13), 1.0)
		draw_line(c + Vector2(-half, d), c + Vector2(half, d), Color(LINE, 0.13), 1.0)
	# Range rings, spokes and the crosshair.
	for i in range(1, 5):
		draw_arc(c, r * i / 5.0 + r * 0.04, 0, TAU, 128, Color(LINE, 0.55), 1.6 * k + 0.5)
	for i in 12:
		var dir := Vector2.from_angle(i * TAU / 12.0)
		draw_line(c + dir * r * 0.08, c + dir * r, Color(LINE, 0.22 if i % 3 else 0.6), (2.0 if i % 3 == 0 else 1.0) * k + 0.4)
	# Bearing ticks on the rim.
	for i in 72:
		var dir := Vector2.from_angle(i * TAU / 72.0)
		var length := (0.06 if i % 6 == 0 else 0.025) * r
		draw_line(c + dir * (r - length), c + dir * r, Color(BRIGHT, 0.7 if i % 6 == 0 else 0.35), (2.5 if i % 6 == 0 else 1.2) * k)
	# Faint static blips.
	for star in _stars:
		var s := 4.0 * k
		draw_rect(Rect2(c + star * r - Vector2(s, s) * 0.5, Vector2(s, s)), Color(GLOW, 0.4))
	# Sweep: a fading wedge behind a bright line.
	var lead := _sweep_angle()
	var span := 0.95
	var parts := 28
	for i in parts:
		var a0 := lead - span * (1.0 - float(i) / parts)
		var a1 := lead - span * (1.0 - float(i + 1) / parts)
		var alpha0 := 0.42 * pow(float(i) / parts, 2.2)
		var alpha1 := 0.42 * pow(float(i + 1) / parts, 2.2)
		draw_polygon(PackedVector2Array([c, c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a1) * r]),
			PackedColorArray([Color(GLOW, alpha1 * 0.6), Color(GLOW, alpha0), Color(GLOW, alpha1)]))
	var tip := c + Vector2.from_angle(lead) * r
	draw_line(c, tip, Color(GLOW, 0.35), 7 * k)
	draw_line(c, tip, BRIGHT, 2.5 * k)
	# Hub.
	draw_circle(c, 15 * k, Color(GLOW, 0.25))
	draw_circle(c, 10 * k, Color("0f3d1d"))
	draw_arc(c, 10 * k, 0, TAU, 32, BRIGHT, 3 * k)
	draw_circle(c, 4.5 * k, BRIGHT)

func _sweep_angle() -> float:
	return fposmod(_clock * 1.7 - PI * 0.25, TAU)

## How freshly the sweep passed a radar point: 1 just after, fading to 0.
func _swept(p: Vector2) -> float:
	var behind := fposmod(_sweep_angle() - p.angle(), TAU)
	return clampf(1.0 - behind / 2.2, 0.0, 1.0)

## Planes and UFOs drawn bigger, easier to see and tap: 20% over the first build (user, 9 Nov
## 2026), then 40% more (user, 15 Nov 2026: tapping a UFO on a phone needed extreme precision);
## the hit circles in radar_patrol_game.gd grew to match.
const CRAFT_SCALE := 1.68

func _draw_entities(k: float) -> void:
	var px := 4.2 * k * CRAFT_SCALE
	var c := k * CRAFT_SCALE
	for entity in game.entities:
		var p: Vector2 = entity["pos"]
		if p.length() > 1.0:
			continue
		var at := _centre + p * _radius
		var dir: Vector2 = entity["vel"].normalized()
		var lit: float = _swept(p)
		# Dotted trail behind.
		for i in range(1, 7):
			var dot: Vector2 = p - dir * (0.03 + i * 0.03)
			if dot.length() > 1.0:
				break
			var s := (4.0 - i * 0.35) * k
			draw_rect(Rect2(_centre + dot * _radius - Vector2(s, s) * 0.5, Vector2(s, s)), Color(GLOW, 0.55 - i * 0.07))
		var flash: float = entity["flash"]
		if entity["kind"] == "plane":
			draw_circle(at, 22 * c, Color(GLOW, 0.06 + 0.12 * lit))
			draw_arc(at, 30 * c, 0, TAU, 40, Color(LINE, 0.45), 1.5 * k)
			var tint := DANGER if flash > 0.0 and int(flash * 10) % 2 == 0 else Color(0.93, 1.0, 0.93)
			_sprite(PLANE, at, px, dir.angle(), {"#": tint})
		else:
			var threat: bool = game.threat(entity)
			draw_circle(at, 26 * c, Color(GLOW, 0.08 + 0.16 * lit))
			var colors: Dictionary = UFO_COLORS.duplicate()
			if int(_clock * 4.0 + entity["id"]) % 2 == 0:
				colors["l"] = Color("fff7c0")
			_sprite(UFO, at + Vector2(0, sin(_clock * 5.0 + entity["id"]) * 1.5 * k), px, 0.0, colors)
			if threat:
				_brackets(at, 30 * c, AMBER if int(_clock * 6.0) % 2 == 0 else DANGER, 3 * k)

func _sprite(rows: Array, at: Vector2, px: float, angle: float, colors: Dictionary) -> void:
	var w: int = rows[0].length()
	var h: int = rows.size()
	draw_set_transform(at, angle, Vector2.ONE)
	var origin := -Vector2(w, h) * px * 0.5
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch: String = row[x]
			if ch == ".":
				continue
			draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px + 0.6, px + 0.6)), colors.get(ch, colors.get("#", Color.WHITE)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _brackets(at: Vector2, half: float, color: Color, width: float) -> void:
	var arm := half * 0.42
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner := at + Vector2(sx, sy) * half
			draw_line(corner, corner - Vector2(sx * arm, 0), color, width)
			draw_line(corner, corner - Vector2(0, sy * arm), color, width)

func _draw_effects(k: float) -> void:
	for effect in _effects:
		var t: float = effect["age"] / effect["life"]
		var at: Vector2 = _centre + effect["pos"] * _radius
		match effect["kind"]:
			"pop":
				draw_arc(at, (12 + 40 * t) * k, 0, TAU, 32, Color(BRIGHT, 1.0 - t), 3 * k)
				for i in 8:
					var d := Vector2.from_angle(i * TAU / 8.0 + 0.3) * (10 + 46 * t) * k
					var s := 5 * k * (1.0 - t)
					draw_rect(Rect2(at + d - Vector2(s, s) * 0.5, Vector2(s, s)), Color(AMBER if i % 2 else BRIGHT, 1.0 - t))
				_text(effect["text"], at + Vector2(0, -26 * k - 30 * t * k), 22 * k, Color(AMBER, 1.0 - t * t), HORIZONTAL_ALIGNMENT_CENTER)
			"miss":
				draw_arc(at, (6 + 16 * t) * k, 0, TAU, 20, Color(LINE, 0.7 * (1.0 - t)), 2 * k)
			"friendly":
				draw_arc(at, (16 + 20 * t) * k, 0, TAU, 32, Color(DANGER, 1.0 - t), 3 * k)
				_text("FRIENDLY " + str(effect["text"]), at + Vector2(0, -30 * k - 20 * t * k), 20 * k, Color(DANGER, 1.0 - t * t), HORIZONTAL_ALIGNMENT_CENTER)
			"escape":
				_text("ESCAPED", at - effect["pos"].normalized() * 40 * k, 18 * k, Color(AMBER, 1.0 - t), HORIZONTAL_ALIGNMENT_CENTER)
			"crash":
				# Rings burst once; the pixel fire keeps flickering behind the game-over banner.
				var burst := minf(float(effect["age"]) / 1.6, 1.0)
				for ring_index in 3:
					var ring := clampf(burst * 1.6 - ring_index * 0.2, 0.0, 1.0)
					draw_arc(at, (10 + 120 * ring) * k, 0, TAU, 48, Color(DANGER if ring_index != 1 else AMBER, 1.0 - ring), (6 - ring_index) * k)
				var flicker := 0.85 + 0.15 * sin(_clock * 23.0)
				draw_circle(at, 30 * k * flicker, Color(1.0, 0.55, 0.12, 0.75))
				draw_circle(at, 16 * k * flicker, Color(1.0, 0.92, 0.55, 0.9))
				var sparks := RandomNumberGenerator.new()
				sparks.seed = int(_clock * 12.0)
				for spark in 16:
					var d := Vector2.from_angle(sparks.randf() * TAU) * sparks.randf_range(14, 48) * k
					var s := sparks.randf_range(3, 7) * k
					draw_rect(Rect2(at + d - Vector2(s, s) * 0.5, Vector2(s, s)), Color(AMBER if spark % 2 else Color(1.0, 0.5, 0.1)))

func _draw_header(k: float) -> void:
	var origin := _square.position + Vector2(34, 34) * k
	# Crosshair icon.
	var icon := origin + Vector2(18, 20) * k
	draw_arc(icon, 15 * k, 0, TAU, 32, BRIGHT, 3 * k)
	draw_line(icon - Vector2(22, 0) * k, icon + Vector2(22, 0) * k, BRIGHT, 2.5 * k)
	draw_line(icon - Vector2(0, 22) * k, icon + Vector2(0, 22) * k, BRIGHT, 2.5 * k)
	draw_line(icon + Vector2(-7, 7) * k, icon + Vector2(8, -8) * k, AMBER, 2.5 * k)
	_text(UiText.t("games.radar_patrol").to_upper(), origin + Vector2(50, 32) * k, 34 * k, BRIGHT)
	_text("AIRPORT ARCADE  ///", origin + Vector2(52, 56) * k, 13 * k, Color(LINE, 0.95))
	# Score box.
	var box := Rect2(_square.end.x - 218 * k - 30 * k, _square.position.y + 26 * k, 218 * k, 78 * k)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.16, 0.08, 0.9)
	style.border_color = BRIGHT
	style.set_border_width_all(int(3 * k) + 1)
	style.set_corner_radius_all(int(12 * k))
	style.shadow_color = Color(GLOW, 0.2)
	style.shadow_size = int(8 * k)
	draw_style_box(style, box)
	_text("SCORE", box.position + Vector2(18, 24) * k, 15 * k, Color(BRIGHT, 0.8))
	_text(_format(game.score), box.position + Vector2(box.size.x - 16 * k, 64 * k), 36 * k, BRIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	# Best and combo under the box.
	_text("BEST " + _format(maxi(best, game.score)), Vector2(box.end.x, box.end.y + 22 * k), 14 * k, Color(LINE, 0.95), HORIZONTAL_ALIGNMENT_RIGHT)
	if game.combo > 1 and state == State.PLAYING:
		var pulse := 1.0 + 0.08 * sin(_clock * 10.0)
		_text("COMBO x%d" % game.combo, Vector2(box.end.x, box.end.y + 46 * k), 20 * k * pulse, AMBER, HORIZONTAL_ALIGNMENT_RIGHT)

func _draw_cards(k: float) -> void:
	var c := _centre
	match state:
		State.READY:
			_card(Rect2(c - Vector2(250, 120) * k, Vector2(500, 240) * k), k)
			_text(UiText.t("games.radar_patrol").to_upper(), c + Vector2(0, -62) * k, 30 * k, BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
			_text("Tap UFOs to destroy them", c + Vector2(0, -24) * k, 17 * k, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
			_text("Don't hit friendly planes", c + Vector2(0, 2) * k, 17 * k, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
			_text("A UFO touching a plane ends the game", c + Vector2(0, 28) * k, 17 * k, AMBER, HORIZONTAL_ALIGNMENT_CENTER)
			if int(_clock * 2.0) % 2 == 0:
				_text("TAP TO START", c + Vector2(0, 82) * k, 26 * k, BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
		State.PAUSED:
			_card(Rect2(c - Vector2(180, 60) * k, Vector2(360, 120) * k), k)
			_text("PAUSED", c + Vector2(0, -6) * k, 32 * k, BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
			_text("tap to resume", c + Vector2(0, 30) * k, 16 * k, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		State.OVER:
			# Game-over banner (user reference, 9 Nov 2026): a chamfered plate across the radar's
			# middle, GAME OVER!, a divider, FINAL SCORE; the frozen scene stays visible around it.
			_banner(Rect2(c - Vector2(300, 82) * k, Vector2(600, 172) * k), k)
			_text("GAME OVER!", c + Vector2(0, -20) * k, 56 * k, BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
			draw_line(c + Vector2(-220, -2) * k, c + Vector2(220, -2) * k, Color(LINE, 0.9), 2 * k)
			draw_line(c + Vector2(-180, 26) * k, c + Vector2(-120, 26) * k, Color(LINE, 0.9), 2 * k)
			draw_line(c + Vector2(120, 26) * k, c + Vector2(180, 26) * k, Color(LINE, 0.9), 2 * k)
			_text("FINAL SCORE", c + Vector2(0, 32) * k, 18 * k, Color(BRIGHT, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
			_text(_format(game.score), c + Vector2(0, 78) * k, 46 * k, Color("e6ffd8"), HORIZONTAL_ALIGNMENT_CENTER)
			# Below the banner: best and stats, then the buttons (_layout()).
			var line := "UFOS %d  ·  BEST COMBO x%d  ·  TIME %d:%02d" % [game.kills, game.best_combo, int(game.time) / 60, int(game.time) % 60]
			_text(line, c + Vector2(0, 116) * k, 14 * k, Color(BRIGHT, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
			var blink := AMBER if int(_clock * 4.0) % 2 == 0 else Color.WHITE
			if new_best:
				_text("NEW BEST!", c + Vector2(0, -128) * k, 26 * k, blink, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				_text("BEST " + _format(best), c + Vector2(0, -128) * k, 18 * k, Color(LINE, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
			# Under BEST: the most UFOs destroyed in one game (user, 9 Nov 2026).
			if new_best_kills:
				_text("NEW RECORD: %d UFOS!" % best_kills, c + Vector2(0, -100) * k, 18 * k, blink, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				_text("MOST UFOS %d" % best_kills, c + Vector2(0, -100) * k, 18 * k, Color(LINE, 1.0), HORIZONTAL_ALIGNMENT_CENTER)

## The chamfered game-over plate with small side marks.
func _banner(rect: Rect2, k: float) -> void:
	var cut := 34 * k
	var a := rect.position
	var b := rect.end
	var outline := PackedVector2Array([Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut),
		Vector2(b.x, b.y - cut), Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y), Vector2(a.x, b.y - cut), Vector2(a.x, a.y + cut)])
	draw_colored_polygon(outline, Color(0.02, 0.1, 0.05, 0.92))
	var closed: PackedVector2Array = outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color(GLOW, 0.25), 9 * k)
	draw_polyline(closed, BRIGHT, 3 * k)
	for side in [-1.0, 1.0]:
		var x: float = (a.x + 14 * k) if side < 0 else (b.x - 14 * k)
		for i in 2:
			var dx: float = -side * i * 7 * k
			draw_line(Vector2(x + dx, rect.get_center().y - 16 * k), Vector2(x + dx, rect.get_center().y + 16 * k), Color(LINE, 0.9), 2.5 * k)

func _card(rect: Rect2, k: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.1, 0.05, 0.9)
	style.border_color = BRIGHT
	style.set_border_width_all(int(3 * k) + 1)
	style.set_corner_radius_all(int(14 * k))
	style.shadow_color = Color(GLOW, 0.25)
	style.shadow_size = int(14 * k)
	draw_style_box(style, rect)

func _text(text: String, at: Vector2, font_size: float, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var px := maxi(8, int(font_size))
	var width := -1.0
	var pos := at
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		width = 1200.0
		pos.x -= width * (0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0)
	draw_string(_font, pos + Vector2(0, 2), text, align, width, px, Color(0, 0, 0, color.a * 0.6))
	draw_string(_font, pos, text, align, width, px, color)

static func _format(n: int) -> String:
	var digits := "%06d" % n
	return digits.substr(0, digits.length() - 3) + "," + digits.substr(digits.length() - 3)

# --- Best score -------------------------------------------------------------------------

func _load_best() -> void:
	var data = SaveStore.read_json(SaveStore.path(SAVE_FILE))
	if data is Dictionary:
		best = int(data.get("best", 0))
		best_combo = int(data.get("best_combo", 0))
		best_kills = int(data.get("best_kills", 0))

func _save_best() -> void:
	SaveStore.write_json(SaveStore.path(SAVE_FILE), {"best": best, "best_combo": best_combo, "best_kills": best_kills})
