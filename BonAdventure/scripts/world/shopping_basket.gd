@tool
extends Node3D
## Reusable hand-held shopping basket (13 Nov 2026, docs/guides/HAND_HOLD.md): one red supermarket
## basket (the look of the stacked baskets in supermarket_products.gd _fit_basket()) with its two
## handles raised and meeting over the middle, the way it is carried. Word *basket*; holds as
## hand_hold.gd profile "basket". The model and pick area are built at load (never saved), the
## mesh shared by every basket. Frame: base centre at the origin, long side along X (0.66),
## 0.45 deep, rim at 0.23, handle grip at about 0.43.
##
## Shopping with it (user, 14 Nov 2026; the welcome tutorial's shop and the supermarket's order
## game): `give(node)` puts a new basket in the player's hand (hand_hold.gd), `show_items()`
## fills it with a small model of each picked product, and `take_back(node)` removes it again.

const Art := preload("res://scripts/buildings/supermarket_products.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const SCENE := "res://scenes/props/shopping_basket.tscn"
const PART_META := "shopping_basket_part"
## Meta of a basket handed out by give(): take_back() removes only such a basket.
const GIVEN_META := "given_basket"
const RIM := .23
const GRIP := .43
## Contents: the biggest side of each item's model, the floor height and the slots (3 across,
## 2 deep, two layers: at most 12 items show).
const ITEM_SIZE := .15
const FLOOR := .045
const SLOTS_X := [-.18, 0.0, .18]
const SLOTS_Z := [-.085, .085]

static var _mesh: ArrayMesh
static var _products
## Word key -> the mesh that shows it in the basket (remember()).
var _models: Dictionary = {}
var _contents: Node3D

## Hands the player a new, empty basket (whatever the hand held is put back first); returns it,
## or the basket already given if the player carries one. Null without a player.
static func give(from: Node) -> Node3D:
	var hand = HandHold.of_player(from)
	if hand == null:
		return null
	if hand.is_holding():
		if hand.held.has_meta(GIVEN_META):
			return hand.held
		hand.release()
	var basket: Node3D = load(SCENE).instantiate()
	basket.set_meta(GIVEN_META, true)
	# Its kind by name: _ready() sets the hold_kind meta only once it is in the tree.
	hand.hold(basket, "basket")
	return basket

## The basket given by give() that the player carries now, or null.
static func carried(from: Node) -> Node3D:
	var hand = HandHold.of_player(from)
	if hand != null and hand.is_holding() and hand.held.has_meta(GIVEN_META):
		return hand.held
	return null

## Takes the given basket out of the player's hand and frees it (nothing when none is carried).
static func take_back(from: Node) -> void:
	var basket := carried(from)
	if basket == null:
		return
	var item: Node3D = HandHold.of_player(from).release()
	if item != null:
		item.queue_free()

## Learns how word `key` looks in the basket from a picked object `source` (a store product
## group or any word root): the store's product model when there is one, else its first mesh.
func remember(key: String, source: Node3D) -> void:
	if _models.has(key):
		return
	if Art.FOOT.has(key):
		if _products == null:
			_products = Art.new()
		_models[key] = _products.model(key)
		return
	if source == null:
		return
	for node in [source] + source.find_children("*", "MeshInstance3D", true, false):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			_models[key] = (node as MeshInstance3D).mesh
			return

## Shows `counts` (word key -> how many) in the basket, each item a small model on its floor.
## Keys with no store model that were never remembered are left out.
func show_items(counts: Dictionary) -> void:
	if _contents == null or not is_instance_valid(_contents):
		_contents = Node3D.new()
		_contents.name = "Contents"
		add_child(_contents)
	for child in _contents.get_children():
		_contents.remove_child(child)
		child.queue_free()
	var slot := 0
	for key in counts:
		if not _models.has(key):
			remember(str(key), null)
		var mesh: Mesh = _models.get(key)
		if mesh == null:
			continue
		for i in int(counts[key]):
			if slot >= SLOTS_X.size() * SLOTS_Z.size() * 2:
				return
			var box := mesh.get_aabb()
			var grow := ITEM_SIZE / maxf(.001, maxf(box.size.x, maxf(box.size.y, box.size.z)))
			var item := MeshInstance3D.new()
			item.name = "%s %d" % [key, i + 1]
			item.mesh = mesh
			var layer := slot / (SLOTS_X.size() * SLOTS_Z.size())
			var cell := slot % (SLOTS_X.size() * SLOTS_Z.size())
			var turn := Basis(Vector3.UP, .7 * slot)
			var at := Vector3(SLOTS_X[cell % SLOTS_X.size()], FLOOR + layer * ITEM_SIZE * .7, SLOTS_Z[cell / SLOTS_X.size()])
			item.transform = Transform3D(turn.scaled(Vector3.ONE * grow), at - turn * (Vector3(box.get_center().x, box.position.y, box.get_center().z) * grow))
			_contents.add_child(item)
			slot += 1

## How many item models the basket shows now.
func item_count() -> int:
	return _contents.get_child_count() if _contents != null and is_instance_valid(_contents) else 0

func _ready() -> void:
	if not has_meta("word_key"):
		set_meta("word_key", "basket")
	set_meta("learning_object", true)
	set_meta("hold_kind", "basket")
	for child in get_children():
		if child.has_meta(PART_META):
			remove_child(child)
			child.free()
	var model := MeshInstance3D.new()
	model.name = "Model"
	model.set_meta(PART_META, true)
	model.mesh = mesh()
	add_child(model)
	var area := Area3D.new()
	area.name = "Interaction"
	area.set_meta(PART_META, true)
	area.collision_layer = 2
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.7, GRIP + .03, .48)
	shape.shape = box
	shape.position = Vector3(0, (GRIP + .03) * .5, 0)
	area.add_child(shape)
	add_child(area)

static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var kit = Art.new()
	var red := Art.RED
	kit.begin()
	kit.bx(Vector3(0, .03, 0), Vector3(.56, .02, .36), kit.darker(red, .1), Art.SATIN)
	for s in [-1, 1]:
		kit.bx(Vector3(0, .13, s * .195), Vector3(.62, .2, .016), red, Art.SATIN, Vector3(s * -.15, 0, 0))
		kit.bx(Vector3(s * .295, .13, 0), Vector3(.016, .2, .4), red, Art.SATIN, Vector3(0, 0, s * .15))
		kit.bx(Vector3(0, RIM, s * .212), Vector3(.66, .02, .03), kit.lighter(red, .12), Art.SATIN)
		kit.bx(Vector3(s * .312, RIM, 0), Vector3(.03, .02, .45), kit.lighter(red, .12), Art.SATIN)
		for j in 6:
			kit.bx(Vector3(-.225 + j * .09, .16, s * .207), Vector3(.05, .05, .004), "8e1f1a", Art.MATTE, Vector3(s * -.15, 0, 0))
		for j in 3:
			kit.bx(Vector3(s * .307, .16, -.11 + j * .11), Vector3(.004, .05, .06), "8e1f1a", Art.MATTE, Vector3(0, 0, s * .15))
	# Two handles, raised from the long sides and meeting over the middle, with a grip sleeve.
	for dx in [-.13, .13]:
		for s in [-1, 1]:
			kit.rod(Vector3(dx, RIM, s * .21), Vector3(dx, GRIP, s * .025), .02, Art.CHARCOAL, Art.SATIN)
	kit.rod(Vector3(-.13, GRIP, 0), Vector3(.13, GRIP, 0), .045, Art.CHARCOAL, Art.SATIN, 10)
	kit.bx(Vector3(0, RIM - .07, -.21), Vector3(.18, .06, .004), Art.WHITE, Art.MATTE, Vector3(.15, 0, 0))
	kit.bx(Vector3(0, RIM - .07, -.2125), Vector3(.1, .015, .002), Art.NAVY, Art.MATTE, Vector3(.15, 0, 0))
	_mesh = kit.finish("Shopping basket (carried)")
	return _mesh
