extends Node
## Product pictures for the customer-order list and cart (8 Nov 2026; customer order deferred
## item 1, docs/guides/TOWN_DESIGN_BRIEF.md). Each supermarket product's 3D model
## (scripts/buildings/supermarket_products.gd) is drawn once at runtime into a small transparent
## picture and kept for the session, so a picture always matches the model on the shelf and the
## project ships no image files for it. picture() returns null until the picture is ready and
## `finished` is emitted then. Without a renderer (headless runs) nothing is drawn.
const Products := preload("res://scripts/buildings/supermarket_products.gd")
const WordPictures := preload("res://scripts/ui/word_pictures.gd")
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
	var model := MeshInstance3D.new()
	model.mesh = _products.model(key, 0)
	# Lit and framed like the journal's word pictures (word_pictures.gd draw()).
	var texture: Texture2D = await WordPictures.draw(self, [model], model.mesh.get_aabb(), SIZE)
	_pending.erase(key)
	if texture == null:
		return
	_done[key] = texture
	finished.emit(key, texture)
