extends Node
## Word pictures for the journal and the results screen (user decision, 23 Nov 2026: the in-world
## word card stays text-only because the object is right there; pictures go where the object is
## not, the journal and review screens). Each picture is the word's own object in the town, drawn
## once at runtime into a small transparent picture, so it matches what the player clicked and the
## project ships no image files (product_pictures.gd does the same for the supermarket and shares
## draw() below). Guide: docs/guides/ARCHITECTURE_REVIEW_PART1.md#word-pictures.
##
## Sources: area_vocabulary.gd `targets` (word key -> the town nodes that carry it, interactables
## included). Only the target's own meshes are copied (no scripts run, nothing in the town is
## touched); a target with more than MAX_PARTS meshes or longer than MAX_EXTENT (a building, a
## room) has no picture. Words of NO_PICTURE_CATEGORIES never get one: not nouns, or (Places &
## Rooms) nouns whose town object is the place's name sign, a blank board without its text
## (Label3D is never copied: it would give the word away). Words marked "picture": false in
## data/words.json (a blank board, a plain slab or disc, a body-chart blob; user, 23 Nov 2026)
## have none either.
## Cost: no download; pictures are drawn on demand (newest request first, AT_ONCE at a time) and
## at most MAX_PICTURES are kept (64 KB each). Without a renderer (headless runs) nothing is drawn;
## while the window draws no frames (hidden), drawing waits.
##
##   WordPictures.shared().fill(texture_rect, key)   # shows the picture now or when it is drawn
const SIZE := 128
const MAX_PICTURES := 200
const MAX_PARTS := 300
## Nodes looked at per target before giving up (a whole building).
const MAX_NODES := 3000
const MAX_EXTENT := 24.0
const AT_ONCE := 2
## Requests waiting beyond this many (scrolled past) are dropped, oldest first.
const MAX_QUEUE := 24
const NO_PICTURE_CATEGORIES := ["Time & Directions", "Colors & Descriptions", "Actions", "Places & Rooms"]
## Seen from the front (-Z), a little from above and the left (product_pictures.gd's view).
const VIEW := Vector3(-0.35, 0.55, -1.0)

signal finished(key: String, texture: Texture2D)

## A WeakRef, so no static reference to the node outlives it (Godot's exit abort, see
## docs/guides/FINAL_VERIFICATION.md: a static singleton holding objects at exit).
static var _shared: WeakRef

## key -> Array of Node3D (area_vocabulary.targets, the same dictionary, so staged units count).
var targets: Dictionary = {}
var categories: Dictionary = {}
## key -> true for words.json "picture": false.
var no_picture: Dictionary = {}
## key -> Texture2D; the most recently used last (oldest dropped first).
var _done: Dictionary = {}
var _failed: Dictionary = {}
var _queue: Array[String] = []
## Words being drawn now (asking again does not draw them twice).
var _drawing: Dictionary = {}
var _busy := 0
## key -> Array of WeakRef to TextureRects waiting for it.
var _waiting: Dictionary = {}

static func shared():
	return _shared.get_ref() if _shared != null else null

func setup(new_targets: Dictionary, new_categories: Dictionary, new_no_picture: Dictionary = {}) -> void:
	targets = new_targets
	categories = new_categories
	no_picture = new_no_picture

func _enter_tree() -> void:
	_shared = weakref(self)

func _exit_tree() -> void:
	if _shared != null and _shared.get_ref() == self:
		_shared = null

func has_picture(key: String) -> bool:
	if _done.has(key):
		return true
	if _failed.has(key) or no_picture.has(key) or NO_PICTURE_CATEGORIES.has(str(categories.get(key, ""))):
		return false
	for target in targets.get(key, []):
		if is_instance_valid(target):
			return true
	return false

## The picture, or null while it is being drawn (then `finished` follows) or when there is none.
func picture(key: String) -> Texture2D:
	if _done.has(key):
		var texture: Texture2D = _done[key]
		_done.erase(key)
		_done[key] = texture
		return texture
	if has_picture(key) and not _drawing.has(key) and is_inside_tree() and DisplayServer.get_name() != "headless":
		_queue.erase(key)
		_queue.append(key)
		while _queue.size() > MAX_QUEUE:
			_queue.pop_front()
		_pump()
	return null

## Shows `key`'s picture in `rect` now, or when it is drawn (unless the rect shows another word
## by then, as pooled journal rows do). Returns whether the word has a picture.
func fill(rect: TextureRect, key: String) -> bool:
	rect.set_meta("picture_key", key)
	rect.texture = picture(key)
	if rect.texture == null and has_picture(key):
		if not _waiting.has(key):
			_waiting[key] = []
		_waiting[key].append(weakref(rect))
	return has_picture(key)

func _pump() -> void:
	while _busy < AT_ONCE and not _queue.is_empty():
		var key: String = _queue.pop_back()
		_busy += 1
		_drawing[key] = true
		_draw_word(key)

func _draw_word(key: String) -> void:
	var texture: Texture2D = null
	var parts: Dictionary = {}
	for target in targets.get(key, []):
		if is_instance_valid(target):
			parts = gather(target)
			if not parts.is_empty():
				break
	if parts.is_empty():
		_failed[key] = true
	else:
		texture = await draw(self, parts.nodes, parts.bounds, SIZE)
		if texture == null:
			_failed[key] = true
		else:
			_done[key] = texture
			while _done.size() > MAX_PICTURES:
				_done.erase(_done.keys()[0])
	for ref in _waiting.get(key, []):
		var rect: TextureRect = ref.get_ref()
		if rect != null and str(rect.get_meta("picture_key", "")) == key:
			rect.texture = texture
	_waiting.erase(key)
	_drawing.erase(key)
	if texture != null:
		finished.emit(key, texture)
	_busy -= 1
	_pump()

## Copies of the meshes under `target`, placed relative to it: {"nodes": [...], "bounds": AABB},
## or {} when it has none or is too big (a building or a room). Hidden parts are left out, except
## originals the render batchers hid (their copy is drawn elsewhere); batch copies are skipped.
static func gather(target: Node3D) -> Dictionary:
	var origin := target.global_transform.affine_inverse()
	var nodes: Array = []
	var bounds := AABB()
	var stack: Array = [target]
	var seen := 0
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		seen += 1
		if seen > MAX_NODES:
			return _drop(nodes)
		if node != target and node is Node3D and not node.visible and not node.has_meta("render_batched"):
			continue
		if node.has_meta("leaf_merge") or node is Label3D:
			continue
		var copy: GeometryInstance3D = null
		var box := AABB()
		if node is MeshInstance3D and node.mesh != null:
			var mesh_copy := MeshInstance3D.new()
			mesh_copy.mesh = node.mesh
			for i in node.get_surface_override_material_count():
				mesh_copy.set_surface_override_material(i, node.get_surface_override_material(i))
			copy = mesh_copy
			box = node.mesh.get_aabb()
		elif node is MultiMeshInstance3D and node.multimesh != null:
			var many := MultiMeshInstance3D.new()
			many.multimesh = node.multimesh
			copy = many
			box = node.multimesh.get_aabb()
		elif node is SpriteBase3D and node.get_child_count() == 0:
			copy = node.duplicate(0)
			box = node.get_aabb()
		if copy != null:
			copy.material_override = node.material_override
			copy.transform = origin * (node as Node3D).global_transform
			var placed: AABB = copy.transform * box
			bounds = placed if nodes.is_empty() else bounds.merge(placed)
			nodes.append(copy)
			if nodes.size() > MAX_PARTS:
				return _drop(nodes)
		for child in node.get_children():
			stack.append(child)
	if nodes.is_empty() or bounds.size.length() < 0.001 \
			or maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)) > MAX_EXTENT:
		return _drop(nodes)
	return {"nodes": nodes, "bounds": bounds}

static func _drop(nodes: Array) -> Dictionary:
	for node in nodes:
		node.free()
	return {}

## Draws `nodes` (new, parentless GeometryInstance3Ds that fit `bounds`) into a transparent
## size × size picture, under `host` for two frames. Returns null when nothing was drawn.
static func draw(host: Node, nodes: Array, bounds: AABB, size: int) -> Texture2D:
	var view := SubViewport.new()
	view.size = Vector2i(size, size)
	view.transparent_bg = true
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(view)
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
	for node in nodes:
		view.add_child(node)
	var centre := bounds.get_center()
	var reach := bounds.size.length()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = reach * 0.92
	view.add_child(camera)
	camera.position = centre + VIEW.normalized() * (reach * 2.0 + 0.2)
	camera.look_at(centre)
	camera.near = 0.01
	camera.far = reach * 6.0 + 1.0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image() if is_instance_valid(view) else null
	if is_instance_valid(view):
		view.queue_free()
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
