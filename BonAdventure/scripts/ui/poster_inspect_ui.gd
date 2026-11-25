extends Control
## Close-up of a vocabulary poster (user, 24 Nov 2026: "some boards are too small; when I click
## on those boards, open an interface to inspect them zoomed in", instead of the word card).
## A click or tap on a word of a poster (school, airport, restaurant, warehouse, police, mystery
## house: a node named "... poster ..." or "... menu board" holding word cards) glides a copy of the
## whole poster in front of the camera with object_inspector.gd (fit "face": it fills the screen),
## the world dimmed behind it and the game buttons hidden. Taps wait until it has zoomed in
## (OPTIONS.seconds). Then a tap on one of its words
## shows that word's card (and studies it, as a plain word click does; any tap closes the card),
## a tap off the poster or the ✕, Esc or E closes and the copy glides back to the wall. Player movement is off while it is open
## (Main.sync_player_controls). The poster on the wall is never moved (it may be statically
## batched, render_culling.gd): the copy is made and freed here.

const Inspector := preload("res://scripts/player/object_inspector.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")

## Share of the view the poster's face fills (room left for the ✕ and the top-right buttons).
const FILL := .8
## The copy sits this close to the camera, scaled down, so walls beside the player never cut it.
const DISTANCE := .7
const OPTIONS := {"tilt": 0.0, "fill": FILL, "fit": "face", "distance": DISTANCE, "seconds": .4, "gentle": true}
## A node whose name says it is a poster or a menu board (case-insensitive) and that holds at
## least this many word cards is a poster.
const MIN_WORDS := 2

var main: Node
var hud
var inspector: Node
var close_button: Button
## The poster on the wall being inspected (hidden meanwhile) and its copy on the stage.
var _poster: Node3D
var _copy: Node3D
## When the glide in ends (Time ticks, ms): taps before it do nothing (user, 24 Nov 2026: no word
## card until the poster has zoomed in; a double click, or one tap seen as touch and mouse, would
## otherwise open a card at once).
var _ready_at := 0

func setup(game: Node) -> void:
	main = game
	hud = game.hud
	name = "PosterInspect"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.ui_root.add_child(self)
	inspector = Inspector.new()
	inspector.name = "PosterInspector"
	add_child(inspector)
	inspector.closed.connect(_on_closed)
	close_button = Button.new()
	close_button.name = "Close poster button"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.icon = UiIcons.texture("close", 128)
	close_button.expand_icon = true
	close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_button.tooltip_text = "Close"
	hud.style_corner_button(close_button)
	close_button.pressed.connect(close)
	close_button.visible = false
	add_child(close_button)
	game.popups.watch(close_button, close)
	# While open, E closes and a click or tap comes here (interaction_controller.gd claims).
	game.interaction.claim("poster", inspecting, close, _click)
	game.interaction.poster_hook = open_for
	get_viewport().size_changed.connect(_layout)
	_layout()

func inspecting() -> bool:
	return inspector.is_open()

## The poster has finished gliding in: its words can be tapped.
func zoomed_in() -> bool:
	return inspecting() and Time.get_ticks_msec() >= _ready_at

## The poster a word card belongs to, or null.
static func poster_of(word: Node) -> Node3D:
	if word == null or not (word.get_parent() is Node3D):
		return null
	var parent := word.get_parent() as Node3D
	var title := String(parent.name).to_lower()
	if not ("poster" in title or "menu board" in title):
		return null
	var words := 0
	for child in parent.get_children():
		if str(child.get_meta("word_key", "")) != "":
			words += 1
	return parent if words >= MIN_WORDS else null

## The interaction controller's hook for a clicked word: true when it was on a poster (the
## close-up opens instead of the word card).
func open_for(word: Node3D) -> bool:
	var poster := poster_of(word)
	if poster == null:
		return false
	open(poster)
	return true

func open(poster: Node3D) -> void:
	if inspector.is_open() or (main.hold_ui != null and main.hold_ui.inspecting()):
		return
	main.interaction.clear_card()
	_copy = _copy_of(poster)
	poster.get_parent().add_child(_copy)
	_copy.transform = poster.transform
	# The side the player stands on is the front (posters are built facing either way).
	var options := OPTIONS.duplicate()
	var from_player: Vector3 = poster.global_transform.affine_inverse() * main.player.global_position
	options["yaw"] = 180.0 if from_player.z < 0.0 else 0.0
	if not inspector.open(_copy, main.camera, options):
		_copy.queue_free()
		_copy = null
		return
	_poster = poster
	_ready_at = Time.get_ticks_msec() + int(float(OPTIONS.seconds) * 1000.0)
	poster.visible = false
	close_button.visible = true
	hud.hide_for_game(true, "poster")
	main.sync_player_controls()

func close() -> void:
	main.interaction.clear_card()
	inspector.close(.3)

func _on_closed(item: Node3D) -> void:
	if is_instance_valid(_poster):
		_poster.visible = true
	_poster = null
	if is_instance_valid(item):
		item.queue_free()
	_copy = null
	close_button.visible = false
	hud.hide_for_game(false, "poster")
	main.sync_player_controls()

## A click or tap while open: an open word card closes ("Tap anywhere to close"), else a word
## shows its card and a tap off the poster closes the close-up.
func _click() -> void:
	if not is_instance_valid(_copy) or not zoomed_in():
		return
	if hud.is_card_visible():
		main.interaction.clear_card()
		return
	var at: Vector2 = main.interaction.pointer_position
	var view: Camera3D = main.camera
	var word := _word_at(at, view)
	if word != null:
		main.interaction.show_word(word)
	elif not _screen_rect(_copy, view).has_point(at):
		close()

## The smallest word card of the copy under the screen point `at`.
func _word_at(at: Vector2, view: Camera3D) -> Node3D:
	var best: Node3D = null
	var best_area := INF
	for child in _copy.get_children():
		if not (child is Node3D) or str(child.get_meta("word_key", "")) == "":
			continue
		var rect := _screen_rect(child, view)
		if rect.has_point(at) and rect.get_area() < best_area:
			best = child
			best_area = rect.get_area()
	return best

## Where `node`'s bounding box shows on screen.
static func _screen_rect(node: Node3D, view: Camera3D) -> Rect2:
	var box: AABB = HandHold.local_bounds(node)
	var rect := Rect2()
	for i in 8:
		var point := view.unproject_position(node.global_transform * box.get_endpoint(i))
		rect = Rect2(point, Vector2.ZERO) if i == 0 else rect.expand(point)
	return rect

## A copy of the poster for the stage: every part drawn (batched originals are hidden), no
## picking areas, no distance fade, and the restaurant posters' icon sheets shared rather than
## rendered again.
static func _copy_of(poster: Node3D) -> Node3D:
	var copy := poster.duplicate() as Node3D
	copy.name = String(poster.name) + " (close-up)"
	_prepare(poster, copy)
	return copy

static func _prepare(original: Node, copy: Node) -> void:
	if copy is Node3D:
		(copy as Node3D).visible = (original as Node3D).visible or original.has_meta("render_batched")
		copy.remove_meta("render_batched")
	if copy is GeometryInstance3D:
		(copy as GeometryInstance3D).visibility_range_end = 0.0
		(copy as GeometryInstance3D).visibility_range_begin = 0.0
	if copy is Sprite3D and original is Sprite3D:
		(copy as Sprite3D).texture = (original as Sprite3D).texture
	if copy is CollisionObject3D:
		(copy as CollisionObject3D).collision_layer = 0
		(copy as CollisionObject3D).collision_mask = 0
		if copy is Area3D:
			(copy as Area3D).monitorable = false
			(copy as Area3D).monitoring = false
	var count := mini(original.get_child_count(), copy.get_child_count())
	for i in count:
		_prepare(original.get_child(i), copy.get_child(i))
	# A SubViewport copy would render its sheet a second time; the sprites share the original's.
	for child in copy.get_children():
		if child is SubViewport:
			copy.remove_child(child)
			child.free()

## The ✕: where the held item's Inspect button sits (hold_inspect_ui.gd), left of jump.
func _layout() -> void:
	var slot: Rect2 = hud.bottom_slot(1)
	var gap: float = hud.bottom_slot(0).position.x - slot.end.x
	var jump: Rect2 = hud.jump_slot()
	var rect := Rect2(Vector2(jump.position.x - gap - slot.size.x, jump.end.y - slot.size.y), slot.size)
	hud.size_corner_button(close_button, rect)
