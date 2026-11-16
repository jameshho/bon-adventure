extends Node
## Product pictures for the customer-order list and cart (8 Nov 2026; customer order deferred
## item 1, docs/guides/TOWN_DESIGN_BRIEF.md). Each supermarket product's 3D model
## (scripts/buildings/supermarket_products.gd) is drawn once at runtime into a small transparent
## picture and kept for the session, so a picture always matches the model on the shelf and the
## project ships no image files for it. picture() returns null until the picture is ready and
## `finished` is emitted then. Without a renderer (headless runs) nothing is drawn.
const Products := preload("res://scripts/buildings/supermarket_products.gd")
const SIZE := 128

signal finished(key: String, texture: Texture2D)

var _products := Products.new()
var _done := {}
var _pending := {}

static func has_picture(key: String) -> bool:
	return Products.FOOT.has(key)

func picture(key: String) -> Texture2D:
	if _done.has(key):
		return _done[key]
	if has_picture(key) and not _pending.has(key) and is_inside_tree() \
			and DisplayServer.get_name() != "headless":
		_pending[key] = true
		_render(key)
	return null

func _render(key: String) -> void:
	var view := SubViewport.new()
	view.size = Vector2i(SIZE, SIZE)
	view.transparent_bg = true
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff4df")
	environment.environment.ambient_light_energy = 0.7
	view.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, -0.6, 0.0)
	sun.light_energy = 0.9
	view.add_child(sun)
	var model := MeshInstance3D.new()
	model.mesh = _products.model(key, 0)
	view.add_child(model)
	# Seen from the front (-Z), a little from above and the left, filling the picture.
	var bounds := model.mesh.get_aabb()
	var centre := bounds.get_center()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = bounds.size.length() * 0.92
	view.add_child(camera)
	camera.position = centre + Vector3(-0.35, 0.55, -1.0).normalized() * (bounds.size.length() * 2.0 + 0.2)
	camera.look_at(centre)
	camera.near = 0.01
	camera.far = bounds.size.length() * 6.0 + 1.0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image() if is_instance_valid(view) else null
	view.queue_free()
	_pending.erase(key)
	if image == null or image.is_empty():
		return
	var texture := ImageTexture.create_from_image(image)
	_done[key] = texture
	finished.emit(key, texture)
