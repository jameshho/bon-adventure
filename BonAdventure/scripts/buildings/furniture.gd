extends RefCounted
## Furniture store own script (docs/guides/MODULAR_TOWN.md, "Changing a building"); the store is saved
## in scenes/town/furniture.scn. Store-local frame (Buildings/FurnitureStore, scale 1.3): walls
## x = +-12, front z -14.5 (door gap |x| < 1.8), rear z 11.5, floor top y .03 (Y0). Seen from
## the door, +X is on the LEFT. Rooms: living (x < -4.6, front), bedroom and dining (x < -4.4,
## middle and rear), dining, office and lighting (x > 4.7); the centre spine holds two seating
## islands and the salesperson.
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- furniture
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["showroom_tidy", "coplanar_gaps", "coplanar_gaps_2", "shop_row_style"]

const Y0 := .03
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER

var g
var store: Node3D
var room: Node3D

## 9 Nov 2026 (docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"). The furniture prefabs got
## product-art models (tools/build_furniture_props.gd); this step fits the store to them:
## 1. the sofa cushions, bed pillows and blanket sat inside the old sofa and mattress, so the
##    pointer could not reach them; they now rest on the new seat and mattress;
## 2. the living-room rug grows so both armchairs stand on it;
## 3. the centre islands get a rug each and the lone chair joins the head of the dining table
##    (seating vignettes instead of scattered pieces);
## 4. the bedroom divider teaches "divider" like the living-room one;
## 5. the 28 Oct builder turned the vocabulary prefabs as if their fronts were +Z (they are -Z),
##    so chairs faced away from the tables, the sofa and armchairs away from the coffee table,
##    and the TV, wardrobe, nightstands, dresser, mirror, desks and bookshelves faced the wall;
##    every placed prefab except the bed and its pillows turns half a turn.
func showroom_tidy(town: Node3D, game) -> void:
	g = game
	store = town.get_node_or_null("Buildings/FurnitureStore")
	if store == null:
		push_error("furniture: store not found")
		return
	room = store.get_node("Interior")
	# 5. Fronts to the room (done first: the lone chair below is placed afterwards).
	var turned: Array = []
	for node in store.get_children() + room.get_children():
		var file := str(node.scene_file_path)
		if not file.begins_with("res://scenes/props/vocabulary/") or file.get_file().get_basename() in ["bed", "pillow"]:
			continue
		node.rotation.y = wrapf(node.rotation.y + PI, -PI, PI)
		turned.append(file.get_file().get_basename())
	print("furniture: turned %d prefabs to face the room: %s" % [turned.size(), ", ".join(turned)])
	# 1. Cushions lean on the sofa's back cushions (the sofa now faces -X, the TV; back at +X).
	for z in [-10.15, -8.45]:
		var cushion := _word_at(room, "cushion", Vector3(-5.45, .62, z))
		if cushion:
			cushion.position = Vector3(-5.58, Y0 + .6 + .2, z)
	# Pillows by the headboard (bed head toward -X), side by side on the mattress (top Y0+.66).
	var pillows := [store.get_node_or_null("Pillow"), _word_at(room, "pillow", Vector3(-11.3, Y0 + .62, 1.1))]
	var pillow_z := [.05, .95]
	for k in 2:
		var pillow: Node3D = pillows[k]
		if pillow == null:
			push_error("furniture: pillow %d not found" % k)
			continue
		pillow.position = Vector3(-11.42, Y0 + .66, pillow_z[k])
		pillow.scale = Vector3.ONE * .8
	var blanket := _word_at(room, "blanket", Vector3(-9.85, Y0 + .6, .5))
	if blanket:
		blanket.position.y = Y0 + .66 + .05
	# 2. Living rug: 6 x 7.4 so both armchairs (z -12.6 and -6.0) stand on it.
	var old_rug := room.get_node_or_null("Living rug")
	if old_rug:
		var at: Vector3 = old_rug.position
		room.remove_child(old_rug)
		old_rug.free()
		rug("Living rug", Vector3(at.x, 0, -9.3), Vector2(6.0, 7.4), "b8a68a", "8c7a5c")
	# 3. Centre islands: a reading corner (two armchairs, side table, red ottoman) and a seating
	# sampler (ottoman, stool, bench), each on its own rug; the lone chair heads the dining table.
	rug("Island rug", Vector3(-3.1, 0, -8.85), Vector2(2.4, 7.2), "c9d6dc", "6f8a96")
	rug("Seating rug", Vector3(3.2, 0, -9.7), Vector2(2.4, 5.4), "d8c8a8", "9c8460")
	var lone := store.get_node_or_null("Chair")
	if lone:
		lone.position = Vector3(6.3, Y0, -10.2)
		lone.rotation = Vector3(0, -PI / 2, 0)
	# 4. The bedroom divider is a word like the living-room divider.
	var divider := room.get_node_or_null("Bedroom divider")
	if divider:
		divider.set_meta("word_key", "divider")
		divider.set_meta("learning_object", true)
		if divider.find_children("*", "CollisionObject3D", true, false).is_empty():
			_pick_area(divider, Vector3(.16, 2.8, 5.0))

## The child of `parent` with word `word` nearest to `p` (within 0.3), or null.
func _word_at(parent: Node3D, word: String, p: Vector3) -> Node3D:
	var best: Node3D = null
	var gap := .3
	for child in parent.get_children():
		if child is Node3D and str(child.get_meta("word_key", "")) == word and child.position.distance_to(p) < gap:
			gap = child.position.distance_to(p)
			best = child
	if best == null:
		push_error("furniture: no %s near %s" % [word, p])
	return best

## A rug (as the 28 Oct builder drew them): a border and a field, picked by a thin area.
func rug(title: String, p: Vector3, size: Vector2, tint: String, border: String) -> void:
	var node := Node3D.new()
	node.name = title
	node.position = Vector3(p.x, Y0, p.z)
	node.set_meta("word_key", "rug")
	node.set_meta("learning_object", true)
	for part in [[.02, Vector3(size.x, .03, size.y), border], [.04, Vector3(size.x - .4, .03, size.y - .4), tint]]:
		var mesh := MeshInstance3D.new()
		mesh.mesh = g.shared_box_mesh(part[1])
		mesh.material_override = g.material_for(Color(part[2]))
		mesh.position = Vector3(0, part[0], 0)
		node.add_child(mesh)
	_pick_area(node, Vector3(size.x, .1, size.y), Vector3(0, .05, 0))
	room.add_child(node)

func _pick_area(node: Node3D, size: Vector3, at := Vector3.ZERO) -> void:
	var area := Area3D.new()
	area.name = "Interaction"
	area.collision_layer = 2
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	area.add_child(shape)
	node.add_child(area)

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "furniture")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "furniture", 2)


## Game palette and shop row (user, 18 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Game palette and
## shop row"): the storefront recoloured by role from scripts/core/game_palette.gd, accent "teal".
func shop_row_style(town: Node3D, game) -> void:
	var ShopRow := preload("res://scripts/buildings/shop_row.gd")
	print("shop_row furniture: ", ShopRow.restyle(town, game, "furniture"))
