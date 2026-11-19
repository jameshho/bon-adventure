extends Control
## The town map (wayfinding, user 18 Nov 2026; docs/guides/MINIGAMES.md#town-map-and-guide-arrow),
## opened with M or the map corner button. It replaced the live map drawn from the town's meshes
## (town_minimap.gd, switched off on 14 Nov 2026 for speed): the picture is baked once by
## tools/bake_town_map.gd (assets/maps/town_map.png, loaded only while the map is open) and the
## names, entrances and minigame spots come from data/town_map.json.
##
## Left: the picture, each building's name in a small pill, a "you are here" dot with the view's
## direction (moved 5 times a second while open). A tap anywhere on the picture picks the nearest
## place. Right: the picked place, its minigames (a tap guides to that game) and a green
## "Go there", which starts the guide arrow (guide_arrow.gd) and closes the map; "Stop guide"
## while one runs; ✕ (and M, Esc, moving) closes.
const UiText := preload("res://scripts/language/ui_text.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const GuideArrow := preload("res://scripts/ui/guide_arrow.gd")
const IMAGE := "res://assets/maps/town_map.png"
## How often the "you are here" dot moves while the map is open.
const DOT_SECONDS := 0.2

var main
var hud
var guide
var card: PanelContainer
var map_view: Control
var side: VBoxContainer
var title_label: Label
var place_title: Label
var place_hint: Label
var games_box: VBoxContainer
var go_button: Button
var stop_button: Button
var close_button: Button
var picture: Texture2D
## data/town_map.json: frame, places, games.
var frame: Dictionary
var places: Array = []
## Place index -> game ids nearest that place.
var games_at: Dictionary = {}
var picked := -1
## Where the picture is drawn in map_view, and each label's pill (map_view pixels).
var _shown := Rect2()
var _pills: Array = []
var _dot := Vector2.INF
var _heading := Vector2.UP
var _timer := 0.0
var _factor := 1.0
var _press_at := Vector2.INF

func setup(game, arrow) -> void:
	main = game
	hud = game.hud
	guide = arrow
	name = "TownMap"
	theme = BonStyle.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var data: Dictionary = GuideArrow.data()
	frame = data.get("frame", {})
	places = data.get("places", [])
	var games: Dictionary = data.get("games", {})
	for id in games:
		var at := Vector2(float(games[id][0]), float(games[id][1]))
		var best := -1
		var best_d := INF
		for i in range(places.size()):
			var d := at.distance_to(Vector2(float(places[i].door[0]), float(places[i].door[1])))
			if d < best_d:
				best_d = d
				best = i
		if best >= 0:
			if not games_at.has(best):
				games_at[best] = []
			games_at[best].append(str(id))
	card = PanelContainer.new()
	card.name = "Map card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)
	var row := HBoxContainer.new()
	card.add_child(row)
	map_view = Control.new()
	map_view.name = "Map picture"
	map_view.mouse_filter = Control.MOUSE_FILTER_STOP
	map_view.clip_contents = true
	map_view.draw.connect(_draw_map)
	map_view.gui_input.connect(_map_input)
	row.add_child(map_view)
	side = VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	var head := HBoxContainer.new()
	side.add_child(head)
	title_label = Label.new()
	title_label.name = "Map title"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(title_label)
	close_button = Button.new()
	close_button.name = "Close map"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.icon = UiIcons.texture("close", 64)
	close_button.expand_icon = true
	close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_button.pressed.connect(func() -> void: if hud.is_map_open(): hud.toggle_map())
	head.add_child(close_button)
	place_title = Label.new()
	place_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(place_title)
	place_hint = Label.new()
	place_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place_hint.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	side.add_child(place_hint)
	games_box = VBoxContainer.new()
	side.add_child(games_box)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)
	stop_button = Button.new()
	stop_button.name = "Stop guide"
	stop_button.pressed.connect(func() -> void:
		guide.stop()
		_refresh_side())
	side.add_child(stop_button)
	go_button = Button.new()
	go_button.name = "Go there"
	go_button.pressed.connect(func() -> void:
		if picked >= 0:
			guide.go_to_place(places[picked])
			if hud.is_map_open():
				hud.toggle_map())
	side.add_child(go_button)
	visible = false
	set_process(false)
	hud.map_overlay.visibility_changed.connect(_on_overlay)
	get_viewport().size_changed.connect(func() -> void: if visible: _layout())

func _on_overlay() -> void:
	if hud.map_overlay.visible:
		open()
	else:
		close()

func open() -> void:
	# The picture is loaded only while the map shows (no memory or upload cost otherwise).
	if picture == null and ResourceLoader.exists(IMAGE):
		picture = load(IMAGE)
	visible = true
	set_process(true)
	_timer = 0.0
	_update_dot()
	refresh_display()

func close() -> void:
	visible = false
	set_process(false)
	picture = null
	map_view.queue_redraw()

## Texts in the native language (on open and after a language change).
func refresh_display() -> void:
	title_label.text = UiText.t("help.map")
	close_button.tooltip_text = UiText.t("help.map") + " (M)"
	go_button.text = UiText.t("map.go")
	stop_button.text = UiText.t("map.stop")
	_layout()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DOT_SECONDS:
		_timer = 0.0
		_update_dot()

# --- Town coordinates and the picture -----------------------------------------------------------

## Town point (x, z) to a 0-1 position on the picture (north up, west left).
func uv(x: float, z: float) -> Vector2:
	return Vector2((float(frame.west) - x) / (float(frame.west) - float(frame.east)), (float(frame.north) - z) / (float(frame.north) - float(frame.south)))

func to_view(x: float, z: float) -> Vector2:
	return _shown.position + uv(x, z) * _shown.size

func _update_dot() -> void:
	if frame.is_empty():
		return
	var player: Node3D = main.player
	var at: Vector3 = main.apartment.to_local(player.get_meta("map_position", player.global_position))
	var dot := to_view(at.x, at.z)
	var camera := get_viewport().get_camera_3d()
	var heading := _heading
	if camera != null:
		var ahead: Vector3 = main.apartment.global_basis.inverse() * -camera.global_basis.z
		var flat := Vector2(-ahead.x, -ahead.z)
		if flat.length_squared() > 0.0001:
			heading = flat.normalized()
	if dot.distance_to(_dot) > 0.5 or heading.angle_to(_heading) > 0.03:
		_dot = dot
		_heading = heading
		map_view.queue_redraw()

func _place_pills() -> void:
	_pills.clear()
	var font := BonStyle.font(600)
	var size := maxi(11, roundi(15 * _factor))
	var taken: Array = []
	for i in range(places.size()):
		var p: Dictionary = places[i]
		var at := to_view(float(p.door[0]), float(p.door[1]))
		var text := UiText.t("places." + str(p.name))
		var box := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size) + Vector2(14, 6) * maxf(_factor, 0.6)
		var best := Rect2(at - Vector2(box.x * 0.5, box.y + 6.0 * _factor), box)
		var best_score := INF
		for offset in [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -2), Vector2(0, 2), Vector2(1.2, -1), Vector2(-1.2, -1), Vector2(1.2, 1), Vector2(-1.2, 1)]:
			var centre: Vector2 = at + Vector2(offset.x * (box.x * 0.5 + 8.0 * _factor), offset.y * (box.y * 0.5 + 6.0 * _factor))
			var rect := Rect2(centre - box * 0.5, box)
			rect.position = rect.position.clamp(_shown.position, _shown.end - box)
			var score: float = centre.distance_to(at)
			for other in taken:
				if rect.grow(2).intersects(other):
					score += 1000.0
			if score < best_score:
				best_score = score
				best = rect
		taken.append(best)
		_pills.append({"rect": best, "text": text, "at": at})

func _draw_map() -> void:
	map_view.draw_rect(Rect2(Vector2.ZERO, map_view.size), BonStyle.SKY_BOTTOM)
	if picture != null:
		map_view.draw_texture_rect(picture, _shown, false)
	var font := BonStyle.font(600)
	var size := maxi(11, roundi(15 * _factor))
	for i in range(_pills.size()):
		var pill: Dictionary = _pills[i]
		var on := i == picked
		map_view.draw_circle(pill.at, maxf(4.0 * _factor, 3.0), BonStyle.GREEN_BOTTOM if on else BonStyle.INK)
		var look: StyleBoxFlat = BonStyle.flat(BonStyle.GREEN_BOTTOM if on else BonStyle.CREAM, roundi(pill.rect.size.y * 0.5), maxi(1, roundi(2 * _factor)), false)
		map_view.draw_style_box(look, pill.rect)
		var base: Vector2 = pill.rect.position + Vector2((pill.rect.size.x - font.get_string_size(pill.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) * 0.5, (pill.rect.size.y - font.get_height(size)) * 0.5 + font.get_ascent(size))
		map_view.draw_string(font, base, pill.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE if on else BonStyle.INK)
	if _dot != Vector2.INF and _shown.grow(8).has_point(_dot):
		var r := maxf(11.0 * _factor, 8.0)
		var ahead := _heading
		var across := Vector2(-ahead.y, ahead.x)
		map_view.draw_circle(_dot, r * 1.6, Color(BonStyle.CORAL_BOTTOM, 0.25))
		map_view.draw_circle(_dot, r, BonStyle.CORAL_BOTTOM)
		map_view.draw_arc(_dot, r, 0, TAU, 32, Color.WHITE, maxf(2.5 * _factor, 2.0), true)
		map_view.draw_colored_polygon(PackedVector2Array([_dot + ahead * r * 0.7, _dot - ahead * r * 0.45 + across * r * 0.5, _dot - ahead * r * 0.15, _dot - ahead * r * 0.45 - across * r * 0.5]), Color.WHITE)

## A tap (a press and release that hardly moved) picks the place nearest it.
func _map_input(event: InputEvent) -> void:
	var pressed := false
	var released := false
	var at := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
		at = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		released = not event.pressed
		at = map_view.get_global_transform_with_canvas().affine_inverse() * event.position
	else:
		return
	map_view.accept_event()
	if pressed:
		_press_at = at
		return
	if released and _press_at != Vector2.INF and at.distance_to(_press_at) < 24.0 * maxf(_factor, 1.0):
		pick_nearest(at)
	_press_at = Vector2.INF

func pick_nearest(at: Vector2) -> void:
	var best := -1
	var best_d := INF
	for i in range(_pills.size()):
		# A tap on a name pill picks it; otherwise the nearest entrance dot.
		var d: float = 0.0 if (_pills[i].rect as Rect2).grow(6).has_point(at) else at.distance_to(_pills[i].at)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0 and best_d < 120.0 * _factor:
		pick(best)

func pick(index: int) -> void:
	picked = index
	_refresh_side()
	map_view.queue_redraw()

func _refresh_side() -> void:
	var f := _factor
	for child in games_box.get_children():
		games_box.remove_child(child)
		child.queue_free()
	stop_button.visible = guide.active()
	go_button.visible = picked >= 0
	if picked < 0:
		place_title.text = ""
		place_title.visible = false
		place_hint.text = UiText.t("map.pick")
		return
	place_title.visible = true
	var p: Dictionary = places[picked]
	place_title.text = UiText.t("places." + str(p.name))
	var ids: Array = games_at.get(picked, [])
	place_hint.text = UiText.t("map.games_here") if not ids.is_empty() else ""
	for id in ids:
		var chip := Button.new()
		chip.name = "Game " + str(id)
		chip.text = UiText.t("games." + str(id))
		chip.focus_mode = Control.FOCUS_NONE
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chip.icon = UiIcons.texture(str(main.game_launcher.ICONS.get(id, "play")) if main.game_launcher != null else "play", 64)
		chip.expand_icon = true
		BonStyle.style_button(chip, "soft", f, 20.0)
		chip.add_theme_constant_override("icon_max_width", roundi(28 * f))
		chip.custom_minimum_size = Vector2(0, maxf(56.0 * f, 44.0))
		chip.pressed.connect(func() -> void:
			guide.go_to_game(str(id))
			if hud.is_map_open():
				hud.toggle_map())
		games_box.add_child(chip)

## Scaled like money_panel.gd: a card almost the window's height, the picture at its natural
## shape on the left, the side column on the right.
func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	_factor = clampf(minf(view.y / 800.0, view.x / 1100.0), 0.5, 3.0)
	var f := _factor
	size = view
	var pad := roundf(16 * f)
	var look: StyleBoxFlat = BonStyle.flat(BonStyle.SKY, roundi(30 * f), maxi(3, roundi(5 * f)))
	look.set_content_margin_all(pad)
	card.add_theme_stylebox_override("panel", look)
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", roundi(16 * f))
	side.add_theme_constant_override("separation", roundi(10 * f))
	games_box.add_theme_constant_override("separation", roundi(8 * f))
	var side_width := clampf(300.0 * f, 200.0, 480.0)
	var height := view.y - 2.0 * maxf(12.0, 20.0 * f) - 2.0 * pad
	var pixels: Array = frame.get("pixels", [1, 1])
	var aspect := float(pixels[0]) / float(pixels[1])
	var map_width := minf(height * aspect, view.x - 2.0 * maxf(12.0, 20.0 * f) - 2.0 * pad - side_width - 16.0 * f)
	var map_height := minf(height, map_width / aspect)
	map_view.custom_minimum_size = Vector2(map_width, height)
	_shown = Rect2(Vector2(0.0, (height - map_height) * 0.5), Vector2(map_width, map_height))
	side.custom_minimum_size = Vector2(side_width, 0)
	title_label.add_theme_font_size_override("font_size", roundi(30 * f))
	place_title.add_theme_font_size_override("font_size", roundi(28 * f))
	place_title.add_theme_color_override("font_color", BonStyle.INK)
	place_hint.add_theme_font_size_override("font_size", roundi(18 * f))
	var tap := maxf(56.0 * f, 44.0)
	close_button.custom_minimum_size = Vector2(tap, tap)
	close_button.add_theme_constant_override("icon_max_width", roundi(tap * 0.45))
	BonStyle.style_button(close_button, "soft", f)
	BonStyle.style_button(go_button, "primary", f, 26.0)
	BonStyle.style_button(stop_button, "minor", f, 22.0)
	go_button.custom_minimum_size = Vector2(0, maxf(72.0 * f, 52.0))
	stop_button.custom_minimum_size = Vector2(0, maxf(60.0 * f, 48.0))
	card.size = Vector2.ZERO
	card.reset_size()
	var card_size := card.get_combined_minimum_size()
	card.size = card_size
	card.position = ((view - card_size) * 0.5).round()
	_place_pills()
	_update_dot()
	_refresh_side()
	map_view.queue_redraw()
