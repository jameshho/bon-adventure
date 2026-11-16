extends RefCounted
## Supermarket own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## supermarket unit (scenes/town/supermarket.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- supermarket
## Never rename or remove a baked step (add a new one that undoes it).
## Record: docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket product art — 8 November 2026".
const STEPS := ["product_models", "fixture_finish", "checkout_props", "seafood_ice", "surface_gaps", "coplanar_gaps", "coplanar_gaps_2", "coplanar_envelope", "glass_windows", "tutorial_fruit", "world_signs"]
const Products = preload("res://scripts/buildings/supermarket_products.gd")
const WorldSign = preload("res://scripts/world/world_sign.gd")
const INTERIOR := "RelocatedSites/Supermarket/MarketInterior"

## Rebuild every product group with the shared product models (supermarket_products.gd).
## A group is a word root holding only product meshes and one pick Area3D (built by the
## 2 Nov 2026 goods()); its name, word_key, transform and pick area are kept, only the meshes
## are replaced. Fixtures that share a product word (the candy racks) are left alone.
func product_models(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var products := Products.new()
	var groups := 0
	var units := 0
	for root in interior.get_children():
		if not root.has_meta("word_key") or not Products.FOOT.has(str(root.get_meta("word_key"))):
			continue
		if str(root.name).begins_with("Candy rack"):
			continue
		var areas := root.get_children().filter(func(child): return child is Area3D)
		var others := root.get_children().filter(func(child): return not child is Area3D and not child is MeshInstance3D)
		if areas.size() != 1 or not others.is_empty():
			push_error("supermarket product_models: unexpected group " + str(root.name))
			continue
		units += products.restock(root)
		groups += 1
	print("SUPERMARKET product_models: %d groups, %d units" % [groups, units])

## Lighter refrigerator backs so dairy and deli goods read against them, a price tag per bay
## on the gondola price channels, and a department pictogram on each wall band.
func fixture_finish(town: Node3D, game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var recoloured := 0
	for title in ["Refrigerator", "Refrigerator2"]:
		for child in interior.get_node(title).get_children():
			var mesh := child as MeshInstance3D
			if mesh != null and mesh.material_override is BaseMaterial3D \
					and (mesh.material_override as BaseMaterial3D).albedo_color.is_equal_approx(Color("496f78")):
				mesh.material_override = game.material_for(Color("dce9ea"))
				recoloured += 1
	var products := Products.new()
	for spec in [["Pantry gondola", 7.4, 5, 4], ["Pantry gondola2", 7.4, 5, 4], ["Household gondola", 4.4, 3, 3]]:
		var tags := MeshInstance3D.new()
		tags.name = "Shelf price tags"
		tags.mesh = products.shelf_tags(spec[1], spec[2], spec[3])
		interior.get_node(spec[0]).add_child(tags)
	# A cream pictogram on each department wall band (bands: 2 Nov 2026 MARKET_ACCENTS).
	for spec in [["FRUIT", "apple", "5e9a4f", Vector3(-20.30, 2.72, 47.0), PI / 2],
			["PANTRY", "jar", "d08a3a", Vector3(-45.70, 2.62, 47.2), -PI / 2],
			["SEAFOOD", "fish", "3f7fb0", Vector3(-42.25, 2.62, 59.71), 0.0],
			["MEAT", "drumstick", "b5473f", Vector3(-33.0, 2.62, 59.71), 0.0],
			["BAKERY", "bread", "c9954a", Vector3(-23.75, 2.62, 59.71), 0.0]]:
		var icon := MeshInstance3D.new()
		icon.name = spec[0] + " pictogram"
		icon.mesh = products.pictogram(spec[1], spec[2])
		icon.transform = Transform3D(Basis(Vector3.UP, spec[4]).scaled(Vector3.ONE * 1.8), spec[3])
		icon.set_meta("market_fitting", true)
		interior.add_child(icon)
	print("SUPERMARKET fixture_finish: %d fridge backs recoloured, 3 gondolas tagged, 5 pictograms" % recoloured)

## Carts, baskets and checkout props remodelled (8 Nov 2026) with the shared fittings in
## supermarket_products.gd: each root keeps its name, word_key, transform and pick/collision
## body; only its meshes are replaced by one merged model. Counters and candy racks are kept.
## [root, fitting, side]: side is the x direction of that lane's customers.
const FITTINGS := [
	["Shopping basket", "basket", 1], ["Shopping basket2", "basket", 1],
	["Conveyor belt", "conveyor belt", 1], ["Conveyor belt2", "conveyor belt", 1],
	["Barcode scanner", "scanner", 1], ["Barcode scanner2", "scanner", -1],
	["Cash register", "cash register", 1], ["Cash register2", "cash register", -1],
	["Register screen", "screen", 1], ["Register screen2", "screen", -1],
	["Card reader", "card reader", 1], ["Card reader2", "card reader", -1],
	["Receipt", "receipt", 1], ["Receipt2", "receipt", 1],
	["Shopping bag", "shopping bag", 1], ["Shopping bag2", "shopping bag", -1],
	["Queue", "queue", 1], ["Money", "money", 1], ["Credit card", "credit card", 1],
]

func checkout_props(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var site: Node3D = town.get_node("RelocatedSites/Supermarket")
	var products := Products.new()
	var count := 0
	for spec in FITTINGS:
		_refit(interior.get_node(spec[0]), products.fitting(spec[1], spec[2]))
		count += 1
	for cart in ["Shopping cart basket", "Shopping cart basket2"]:
		_refit(site.get_node(cart), products.fitting("cart"))
		count += 1
	for k in 8:
		_refit(site.get_node("Cart wheel" + ("" if k == 0 else str(k + 1))), products.fitting("caster"))
		count += 1
	print("SUPERMARKET checkout_props: %d roots remodelled" % count)

func _refit(root: Node3D, mesh: ArrayMesh) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			root.remove_child(child)
			child.free()
	var model := MeshInstance3D.new()
	model.name = str(root.name) + " model"
	model.mesh = mesh
	root.add_child(model)

## Crushed ice with lemon and parsley on the two seafood slabs (2 Nov 2026 slabs 2.7 x .72,
## top y 1.19). The slabs stay; the ice is decoration (market_fitting), not a word.
func seafood_ice(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var products := Products.new()
	for x in [-43.8, -41.0]:
		var ice := MeshInstance3D.new()
		ice.name = "Crushed ice"
		ice.mesh = products.crushed_ice(Vector2(2.66, .7), "seafood %s" % x)
		ice.position = Vector3(x, 1.19, 56.62)
		ice.set_meta("market_fitting", true)
		interior.add_child(ice, true)
	print("SUPERMARKET seafood_ice: 2 slabs")

## Flicker fix (8 Nov 2026): faces of different colours that lay in one plane z-fought.
## Refrigerators: the light back panel, the dark plinth, the canopy and the end posts all ended
## on the rear plane z 50.6 (seen from the deli aisle), and plinth and posts shared the front
## plane z 49.6. The back panel now stops 5 mm short of the rear, the plinth sits between the
## posts and the posts stop under the canopy. Service counters: the dark kick strip shared the
## counter front z 56.15 and now stands 4 mm proud of it. Only box transforms change.
func surface_gaps(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var moved := 0
	for title in ["Refrigerator", "Refrigerator2"]:
		for child in interior.get_node(title).get_children():
			var mesh := child as MeshInstance3D
			if mesh == null or not mesh.mesh is BoxMesh:
				continue
			var box := _box_in(interior, mesh)
			match _colour(mesh):
				"dce9ea":  # back panel
					_trim_face(interior, mesh, Vector3.BACK, .005)
					moved += 1
				"37474f":  # plinth, 3 cm into each end post
					_trim_face(interior, mesh, Vector3.LEFT, .03)
					_trim_face(interior, mesh, Vector3.RIGHT, .03)
					moved += 1
				"b6d5d9":  # end posts reach 2.5 inside the canopy (2.425..2.675); the divider is shorter
					if box.position.y < .15 and box.end.y > 2.45:
						_trim_face(interior, mesh, Vector3.UP, box.end.y - 2.425)
						moved += 1
	for title in ["Deli Counter", "Seafood counter", "Bakery counter"]:
		for child in interior.get_node(title).get_children():
			var mesh := child as MeshInstance3D
			if mesh != null and mesh.mesh is BoxMesh and _colour(mesh) == "2f4560":
				_shift(interior, mesh, Vector3(0, 0, -.004))
				moved += 1
	print("SUPERMARKET surface_gaps: %d boxes moved" % moved)

func _colour(mesh: MeshInstance3D) -> String:
	var material := mesh.material_override as BaseMaterial3D
	return material.albedo_color.to_html(false) if material != null else ""

## Transform from a node's space to the interior's (works before the town is in the tree).
func _to_interior(interior: Node3D, node: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while node != interior:
		if node is Node3D:
			xf = (node as Node3D).transform * xf
		node = node.get_parent()
	return xf

func _box_in(interior: Node3D, mesh: MeshInstance3D) -> AABB:
	return _to_interior(interior, mesh) * mesh.mesh.get_aabb()

## Move the box face that points along interior axis `side` inwards by `amount` metres.
func _trim_face(interior: Node3D, mesh: MeshInstance3D, side: Vector3, amount: float) -> void:
	var basis := _to_interior(interior, mesh).basis
	var axis := 0
	for a in 3:
		if absf(basis[a].normalized().dot(side)) > absf(basis[axis].normalized().dot(side)):
			axis = a
	var length := basis[axis].length() * (mesh.mesh as BoxMesh).size[axis]
	var direction := signf(basis[axis].dot(side))
	var grow := Vector3.ONE
	grow[axis] = (length - amount) / length
	var offset := Vector3.ZERO
	offset[axis] = -direction * amount * .5 / basis[axis].length()
	mesh.transform = mesh.transform * Transform3D(Basis.from_scale(grow), offset)

## Move a box by an interior-space offset.
func _shift(interior: Node3D, mesh: MeshInstance3D, offset: Vector3) -> void:
	var parent := _to_interior(interior, mesh.get_parent())
	mesh.position += parent.basis.inverse() * offset

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "supermarket")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "supermarket", 2)

## The first coplanar pass raised the back wall's top 5 mm, off the approved 26 x 5.8 x 26 wall
## envelope (check_building_access.gd). The wall goes back to its exact height; the approved shell
## is now protected in coplanar_gaps.gd, so a third pass moves the faces it fights instead.
func coplanar_envelope(town: Node3D, _game) -> void:
	var wall: MeshInstance3D = town.get_node("RelocatedSites/Supermarket/Supermarket back wall").find_children("*", "MeshInstance3D", true, false)[0]
	var scale := wall.global_transform.basis.y.length()
	var box := (wall.mesh as BoxMesh).duplicate() as BoxMesh
	box.size.y -= .005 / scale
	wall.mesh = box
	wall.transform = wall.transform * Transform3D(Basis.IDENTITY, Vector3(0, -.0025 / scale, 0))
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "supermarket", 3)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "supermarket")

## The welcome tutorial's fruit (user, 13 Nov 2026: "move the apple and banana to spots where
## they're really easy to see, make them a bit bigger, and make them look better"): a round table
## just inside the door, right of the walk in from the entrance (x about -33), with a basket of
## four big glossy apples (word apple) and a bunch of bananas (word banana) on a cream cloth
## (models: supermarket_products.gd "Featured fruit"). Two new word roots, each with one pick
## area like the shelf groups, so the tutorial's cart (tutorial_shop.gd) and the shop game pick
## them the same way; the fruit wall and produce stand keep their own apples and bananas. The
## table is solid; the fruit is decoration only for collisions (pick areas).
const FRUIT_TABLE := Vector3(-30.2, .1, 38.4)
func tutorial_fruit(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var table := Node3D.new()
	table.name = "Fruit table"
	table.set_meta("market_fitting", true)
	interior.add_child(table)
	table.position = FRUIT_TABLE
	var top_mesh := MeshInstance3D.new()
	top_mesh.name = "Fruit table model"
	top_mesh.mesh = Products.fruit_table()
	table.add_child(top_mesh)
	var body := StaticBody3D.new()
	body.name = "Fruit table body"
	table.add_child(body)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = Products.FEATURE_TABLE_RADIUS
	cylinder.height = Products.FEATURE_TABLE_TOP
	shape.shape = cylinder
	shape.position.y = Products.FEATURE_TABLE_TOP / 2
	body.add_child(shape)
	var top: float = FRUIT_TABLE.y + Products.FEATURE_TABLE_TOP
	_featured(interior, "Featured apples", "apple", Vector3(FRUIT_TABLE.x - .26, top, FRUIT_TABLE.z),
		[Products.fruit_basket(), Products.featured_apples()], Vector3(.8, .6, .8))
	_featured(interior, "Featured bananas", "banana", Vector3(FRUIT_TABLE.x + .36, top, FRUIT_TABLE.z - .02),
		[Products.featured_bananas()], Vector3(.42, .34, .86))
	print("SUPERMARKET tutorial_fruit: fruit table at %s" % FRUIT_TABLE)

## A featured word root: its models and one pick area of `pick` (w, h, d) resting on the surface.
func _featured(interior: Node3D, title: String, word: String, at: Vector3, meshes: Array, pick: Vector3) -> void:
	var root := Node3D.new()
	root.name = title
	root.set_meta("word_key", word)
	interior.add_child(root)
	root.position = at
	for mesh in meshes:
		var model := MeshInstance3D.new()
		model.name = str(mesh.resource_name)
		model.mesh = mesh
		root.add_child(model)
	var area := Area3D.new()
	area.name = "Pick"
	area.collision_mask = 0
	root.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = pick
	shape.shape = box
	shape.position.y = pick.y / 2
	area.add_child(shape)

## Sign readability (16 Nov 2026, docs/guides/BUILDING_DESIGN_BLUEPRINT.md#sign-readability):
## every sign label of the three supermarket parts becomes a world sign (world_sign.gd) with a
## reading distance in metres. Department bands are read across the hall, so their letters grow
## to its middle (18 m); the lane OPEN tags grow to fit their bigger lettering in every language.
## [English text, reading distance, board colour or "" (the mesh behind the label), lines,
## optional letter height in metres (PRODUCE: two lines must fit its 0.62 m board)]
const SIGN_READ := [
	["CHECKOUT", 18.0, "", 1], ["DRINKS & HOME", 18.0, "", 1], ["FRUIT", 18.0, "", 1],
	["VEGETABLES", 18.0, "", 1], ["PANTRY", 18.0, "", 1], ["REFRIGERATED", 18.0, "", 1],
	["SEAFOOD", 18.0, "", 1], ["MEAT", 18.0, "", 1], ["BAKERY", 18.0, "", 1],
	["1", 10.0, "2b5a8c", 1], ["2", 10.0, "2b5a8c", 1], ["OPEN", 5.0, "7bd88f", 1],
	["PRODUCE", 6.0, "", 2, 0.2], ["$1.50", 6.0, "87664c", 1], ["MARKET", 8.0, "", 1],
	["SUPERMARKET", 15.0, "2b5a8c", 1], ["ENTRANCE", 15.0, "", 1], ["CARTS", 10.0, "", 1],
]
## Free margin each side of the lettering: boards over 2 m wide / small tags and cubes.
const SIGN_MARGIN := 0.3
const SMALL_MARGIN := 0.04

func world_signs(town: Node3D, _game) -> void:
	var specs := {}
	for row in SIGN_READ:
		specs[row[0]] = row
	var done := 0
	var boards := 0
	for part in ["RelocatedSites/Supermarket", "Buildings/MarketDisplays", "Map facades/SUPERMARKET"]:
		if not town.has_node(part):
			continue
		var root := town.get_node(part)
		for label: Label3D in root.find_children("*", "Label3D", true, false):
			var english := str(label.get_meta("sign_english", label.text))
			if not specs.has(english):
				push_error("supermarket world_signs: no reading distance for " + english)
				continue
			var row: Array = specs[english]
			# A given colour picks the board among overlapping meshes (the lane tag under its cube).
			var colour := Color(row[2]) if row[2] != "" else Color(0, 0, 0, 0)
			var board := WorldSign.board_behind(label, root, 0.25, 12.0, colour)
			var spec := {"read": row[1], "max_lines": row[3]}
			if row.size() > 4:
				spec.em = row[4]
			spec.board = colour if row[2] != "" else WorldSign.board_colour(board, Color("2b5a8c"))
			if board != null:
				var wide := WorldSign.free_width(board, label, 0.0) > 2.0
				spec.fit_width = WorldSign.free_width(board, label, SIGN_MARGIN if wide else SMALL_MARGIN)
			WorldSign.restyle(label, spec)
			if english == "OPEN" and board != null:
				var texts := ["OPEN"]
				for lang in ["es", "zh"]:
					texts.append(WorldSign.SignLanguage.say("OPEN", lang))
				if WorldSign.fit_board(board, label, SMALL_MARGIN, texts):
					boards += 1
				label.set_meta("sign_fit_width", WorldSign.free_width(board, label, SMALL_MARGIN))
			done += 1
	print("SUPERMARKET world_signs: %d labels, %d tags grown" % [done, boards])
