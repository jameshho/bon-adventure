extends Node3D
## The in-world interaction icons (12 Nov 2026, user): the one "E" badge pinned to the focused
## interactable, and the pooled discovery icons (the gold "!" over an NPC offering a game, moved
## here from npc_presence.gd; a subtle dot over a pastime station). UI art style (18 Nov 2026,
## docs/guides/UI_STYLE.md): soft blue disc, white rim, dark teal Fredoka "E". Constant on-screen size (fixed_size), always drawn on
## top, one shared texture per icon kind, nodes pooled; no shaders, no per-object processing.
## Owned and driven by interaction_controller.gd (focus pass); guide:
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system.

const BonStyle := preload("res://scripts/ui/bon_style.gd")
const FILL := Color("e9f7f8")
const EDGE := BonStyle.RIM
const RING := BonStyle.INK_SOFT
const INK := BonStyle.INK
## World size of the badge quad at fixed_size: about 4.5 % of the view height at 70°.
const BADGE_SIZE := 0.064
const DOT_SIZE := 0.026
## Tap / click radius around the badge's centre, in pixels at the reference window
## (scaled by min(h / 800, w / 1100), like money_panel.gd): a finger-sized target.
const TAP_RADIUS := 34.0
const BANG_BOB := 0.08

var badge: Sprite3D
var _badge_text: Label3D
var _disc: ImageTexture
var _dot: ImageTexture
## Pools: index -> node; the first `_bang_used` / `_dot_used` are in use.
var _bangs: Array[Label3D] = []
var _dots: Array[Sprite3D] = []
## World points of the "!" icons in use (they bob).
var _bang_points: Array[Vector3] = []
var _time := 0.0

func _ready() -> void:
	name = "InteractIcons"
	top_level = true
	_disc = _disc_texture(96, FILL, EDGE, 5.0)
	_dot = _disc_texture(32, EDGE, RING, 3.0, 0.85)
	badge = Sprite3D.new()
	badge.name = "EBadge"
	badge.texture = _disc
	_icon_flags(badge)
	badge.pixel_size = BADGE_SIZE / 96.0
	badge.render_priority = 10
	add_child(badge)
	_badge_text = Label3D.new()
	_badge_text.text = "E"
	_badge_text.font_size = 64
	_badge_text.outline_size = 0
	_badge_text.modulate = INK
	_badge_text.font = BonStyle.font(700)
	_badge_text.pixel_size = BADGE_SIZE * 0.62 / 64.0
	_badge_text.fixed_size = true
	_badge_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_badge_text.no_depth_test = true
	_badge_text.render_priority = 11
	_badge_text.outline_render_priority = 10
	badge.add_child(_badge_text)
	badge.visible = false
	set_process(false)

static func _icon_flags(sprite: Sprite3D) -> void:
	sprite.fixed_size = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.shaded = false
	sprite.double_sided = false

## A disc with an edge ring, drawn once (antialiased by distance).
static func _disc_texture(size: int, fill: Color, edge: Color, edge_px: float, alpha := 1.0) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var cover := clampf(r - d, 0.0, 1.0)
			if cover <= 0.0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var color := edge if d > r - edge_px else fill
			color.a = cover * alpha
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func show_badge(at: Vector3) -> void:
	badge.global_position = at
	badge.visible = true

func hide_badge() -> void:
	badge.visible = false

## The badge's screen centre and tap radius (pixels), or an empty Dictionary when hidden.
func badge_hit_area(camera: Camera3D) -> Dictionary:
	if not badge.visible or camera == null or camera.is_position_behind(badge.global_position):
		return {}
	var view := camera.get_viewport().get_visible_rect().size
	var scale_ui := minf(view.y / 800.0, view.x / 1100.0)
	return {"center": camera.unproject_position(badge.global_position), "radius": maxf(TAP_RADIUS * scale_ui, 22.0)}

## Places the discovery icons for this pass: `bangs` and `dots` are world points.
func set_icons(bangs: Array[Vector3], dots: Array[Vector3]) -> void:
	_bang_points = bangs
	while _bangs.size() < bangs.size():
		_bangs.append(_make_bang())
	for i in _bangs.size():
		_bangs[i].visible = i < bangs.size()
	while _dots.size() < dots.size():
		_dots.append(_make_dot())
	for i in _dots.size():
		_dots[i].visible = i < dots.size()
		if i < dots.size():
			_dots[i].global_position = dots[i]
	set_process(not bangs.is_empty())
	_place_bangs()

func _process(delta: float) -> void:
	_time += delta
	_place_bangs()

func _place_bangs() -> void:
	for i in _bang_points.size():
		_bangs[i].global_position = _bang_points[i] + Vector3(0, BANG_BOB * sin(_time * 2.0), 0)

## The gold "!" (as npc_presence.gd drew it until 12 Nov 2026).
func _make_bang() -> Label3D:
	var bang := Label3D.new()
	bang.name = "NeedsHelpMarker"
	bang.text = "!"
	bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bang.font_size = 140
	bang.pixel_size = 0.006
	bang.outline_size = 36
	bang.modulate = Color("ffd24a")
	bang.outline_modulate = Color("8a2b1c")
	bang.no_depth_test = true
	bang.visible = false
	add_child(bang)
	return bang

func _make_dot() -> Sprite3D:
	var dot := Sprite3D.new()
	dot.name = "StationDot"
	dot.texture = _dot
	_icon_flags(dot)
	dot.pixel_size = DOT_SIZE / 32.0
	dot.render_priority = 5
	dot.visible = false
	add_child(dot)
	return dot

## Where an NPC's "!" and "E" sit: just above the highest visible part, in NPC-local units
## (as npc_presence.gd measured its marker until 12 Nov 2026).
static func head_height(npc: Node3D) -> float:
	var top := 0.0
	for mesh_instance in npc.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh != null:
			top = maxf(top, (mesh_instance.global_transform * mesh_instance.mesh.get_aabb()).end.y)
	return maxf(top - npc.global_position.y, 0.8) / maxf(npc.global_basis.get_scale().y, 0.001) + 0.45

## The middle of `node`'s meshes in its own local space (a door leaf, a cabinet): where the badge
## of a plain object goes. `fallback` when it has no mesh.
static func local_center(node: Node3D, fallback := Vector3(0, 1.0, 0)) -> Vector3:
	var bounds := AABB()
	var first := true
	var to_local := node.global_transform.affine_inverse()
	for mesh_instance in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		if mesh_instance.mesh == null:
			continue
		var box: AABB = (to_local * mesh_instance.global_transform) * mesh_instance.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return fallback if first else bounds.get_center()

## How many "!" icons show now (checks).
func bang_count() -> int:
	return _bang_points.size()
