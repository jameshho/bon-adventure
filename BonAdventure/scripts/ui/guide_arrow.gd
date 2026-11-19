extends Control
## The guide arrow (wayfinding, user 18 Nov 2026; docs/guides/MINIGAMES.md#town-map-and-guide-arrow):
## "Go there" on the town map (town_map_panel.gd) or in the minigame picker (game_launcher.gd)
## sets a target; a small card under the place line in the top left then shows an arrow pointing
## the way (relative to the camera, so "up" is straight ahead on screen), the place's name and
## the distance in metres, and a ✕ to stop. It clears itself on arrival (a toast says so), when
## the target game starts, or with ✕.
##
## Cost: nothing while no target is set (not processing). With a target, one vector sum a frame;
## the arrow redraws only when its angle moves by more than a degree and the text only when the
## metres change. Targets come from data/town_map.json (baked by tools/bake_town_map.gd) or from
## a live NPC node; nothing scans the town.
const UiText := preload("res://scripts/language/ui_text.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const DATA := "res://data/town_map.json"
## Metres (world, flat) at which the player has arrived.
const ARRIVE := 7.0

static var _data: Dictionary

var main
var card: PanelContainer
var dial: Control
var name_label: Label
var metres_label: Label
var stop_button: Button
## The target: a world point, a node that may move (an NPC; its position wins while valid), the
## shown name, and the game id ("" for a building).
var target_point := Vector3.INF
var target_node: Node3D
var target_name := ""
var target_game := ""
var _angle := INF
var _metres := -1
var _factor := 1.0

static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(DATA):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if parsed is Dictionary:
			_data = parsed
	return _data

func setup(game) -> void:
	main = game
	name = "GuideArrow"
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = BonStyle.theme()
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(line)
	dial = Control.new()
	dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dial.draw.connect(_draw_dial)
	line.add_child(dial)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	line.add_child(words)
	name_label = Label.new()
	metres_label = Label.new()
	for label in [name_label, metres_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(label)
	metres_label.add_theme_color_override("font_color", BonStyle.INK_SOFT)
	stop_button = Button.new()
	stop_button.name = "Stop guide"
	stop_button.focus_mode = Control.FOCUS_NONE
	stop_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stop_button.icon = UiIcons.texture("close", 64)
	stop_button.expand_icon = true
	stop_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stop_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stop_button.pressed.connect(stop)
	line.add_child(stop_button)
	visible = false
	set_process(false)
	get_viewport().size_changed.connect(_layout)
	_layout()

## Town point [x, z] (data/town_map.json) to a world point at ground level.
func town_to_world(at: Array) -> Vector3:
	return main.apartment.to_global(Vector3(float(at[0]), 0.0, float(at[1])))

## Guides to a building (a place entry of data/town_map.json: {name, at, door}).
func go_to_place(place: Dictionary) -> void:
	_start(town_to_world(place.at), null, UiText.t("places." + str(place.name)), "")

## Guides to minigame `id`: its NPC (or box) when its building is loaded, else the baked spot.
func go_to_game(id: String) -> void:
	var node: Node3D = null
	var session: Object = Board.shared().session(id)
	if session != null:
		var host = session.get("host")
		if host != null and host.get("npc") is Node3D:
			node = host.npc
	if node == null and id == "electrical_box":
		# The nearest box, as the game opens.
		var best := INF
		for box in get_tree().get_nodes_in_group(preload("res://scripts/world/electrical_box.gd").GROUP):
			var d: float = (box as Node3D).global_position.distance_to(main.player.global_position)
			if d < best:
				best = d
				node = box
	var at: Variant = data().get("games", {}).get(id)
	var point: Vector3 = node.global_position if node != null else (town_to_world(at) if at is Array else Vector3.INF)
	if point == Vector3.INF:
		return
	_start(point, node, UiText.t("games." + id), id)

func _start(point: Vector3, node: Node3D, title: String, game_id: String) -> void:
	target_point = point
	target_node = node
	target_name = title
	target_game = game_id
	name_label.text = title
	_angle = INF
	_metres = -1
	visible = true
	set_process(true)
	_layout()

func stop() -> void:
	target_point = Vector3.INF
	target_node = null
	target_game = ""
	visible = false
	set_process(false)

func active() -> bool:
	return target_point != Vector3.INF

func _process(_delta: float) -> void:
	if is_instance_valid(target_node):
		target_point = target_node.global_position
	var player: Node3D = main.player
	var from: Vector3 = player.get_meta("map_position", player.global_position)
	var to := target_point - from
	to.y = 0.0
	var metres := roundi(to.length())
	# The target game started (from the picker, or by talking to its NPC): the guide is done.
	if target_game != "" and Board.shared().running_id == target_game:
		stop()
		return
	if to.length() < ARRIVE:
		main.hud.flash_quest_message(UiText.t("map.arrived", {"place": target_name}))
		stop()
		return
	# Hidden (not stopped) while a minigame or a game panel hides the HUD.
	card.visible = not main.hud.game_buttons_hidden()
	if not card.visible:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var ahead := -camera.global_basis.z
	ahead.y = 0.0
	if ahead.length_squared() < 0.0001:
		ahead = camera.global_basis.y
		ahead.y = 0.0
	# Screen angle: 0 = straight ahead (up), positive = to the right.
	var angle := atan2(ahead.cross(to).y * -1.0, ahead.dot(to))
	if absf(angle - _angle) > 0.017:
		_angle = angle
		dial.queue_redraw()
	if metres != _metres:
		_metres = metres
		metres_label.text = UiText.t("map.metres", {"n": metres})

func _draw_dial() -> void:
	var r := dial.size.x * 0.5
	var c := dial.size * 0.5
	dial.draw_circle(c, r, BonStyle.GREEN_BOTTOM)
	dial.draw_arc(c, r - 1.5 * _factor, 0, TAU, 40, BonStyle.RIM, 3.0 * _factor, true)
	if _angle == INF:
		return
	var up := Vector2(0, -1).rotated(_angle)
	var side := Vector2(-up.y, up.x)
	var tip := c + up * r * 0.62
	var tail := c - up * r * 0.5
	dial.draw_colored_polygon(PackedVector2Array([tip, c + side * r * 0.42 - up * r * 0.05, c + side * r * 0.16, tail + side * r * 0.16, tail - side * r * 0.16, c - side * r * 0.16, c - side * r * 0.42 - up * r * 0.05]), Color.WHITE)

## Under the place line (top left; the minimap's corner while it is off), scaled like the HUD.
func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	_factor = clampf(minf(view.y / 800.0, view.x / 1100.0), 0.5, 3.0)
	var f := _factor
	card.add_theme_stylebox_override("panel", BonStyle.flat(BonStyle.SKY_TOP, roundi(26 * f), maxi(2, roundi(4 * f))))
	(card.get_child(0) as HBoxContainer).add_theme_constant_override("separation", roundi(12 * f))
	var side := maxf(64.0 * f, 44.0)
	dial.custom_minimum_size = Vector2(side, side)
	name_label.add_theme_font_size_override("font_size", roundi(22 * f))
	metres_label.add_theme_font_size_override("font_size", roundi(18 * f))
	var tap := maxf(52.0 * f, 44.0)
	stop_button.custom_minimum_size = Vector2(tap, tap)
	stop_button.add_theme_constant_override("icon_max_width", roundi(tap * 0.45))
	card.size = Vector2.ZERO
	var room_label: Control = main.hud.room_label
	position = Vector2(16.0, room_label.position.y + room_label.size.y + 34.0 * f)
	dial.queue_redraw()
