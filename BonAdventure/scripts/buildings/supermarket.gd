extends RefCounted
## Supermarket own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## supermarket unit (scenes/town/supermarket.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- supermarket
## Never rename or remove a baked step (add a new one that undoes it).
## Record: docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket product art — 8 November 2026".
const STEPS := ["product_models", "fixture_finish", "checkout_props", "seafood_ice", "surface_gaps", "coplanar_gaps", "coplanar_gaps_2", "coplanar_envelope", "glass_windows", "tutorial_fruit", "world_signs", "clear_sections", "compact_layout", "clay_products"]
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

## Clear sections (17 Nov 2026, user: "make sure the player can easily find the object they are
## looking for as long as they know the word, so the section name should be clear"; record:
## docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket sections — 17 November 2026"). One word, one
## section:
## - PANTRY becomes SNACKS. Each gondola face holds one snack (the gondola by the left wall,
##   x -43.2: chocolate on its wall face, candy on its aisle face; the one by the vegetables,
##   x -39.4: cookies on the aisle face, crackers on its vegetable face) and the end caps
##   chocolate and cookies. The pantry goods and the chip bags
##   (word snack) leave the store; the groups keep their pick areas and are restocked.
## - The produce stand keeps only the big fruit (watermelon, pineapple, coconut); the mango,
##   apple, orange, banana and peach bins there are refilled with those three. Those small
##   fruits stay on the fruit wall.
## - The second fridge's ham, sausage and chicken (also at the meat & deli counter) become dairy.
## - The drinks cooler and the home goods gondola trade places: the cooler now stands where the
##   gondola stood, its front to the store, and the gondola stands against the right wall (x -20.1) with
##   its one open face holding all six home goods (the wall face's groups go). Its toilet paper
##   end cap moves with it.
## - Coffee (iced coffee bottles) fills the cooler's top shelf.
const SNACK_FACES := {-43.5: "chocolate", -42.9: "candy", -39.7: "cookie", -39.1: "cracker"}
const SNACK_ENDCAPS := {"snack": "chocolate", "jar": "cookie"}
const PANTRY_WORDS := ["cereal", "honey", "jam", "coffee", "tea", "sugar", "flour", "oil", "salt",
	"pepper", "rice", "beans", "pasta", "tortilla", "can", "tuna", "soup", "olive", "salsa"]
const STAND_REFILL := {"Mango display2": "watermelon", "Apple display3": "coconut",
	"Orange display3": "watermelon", "Banana display2": "pineapple", "Peach display2": "coconut"}
const FRIDGE_REFILL := {"Ham display": "yogurt", "Sausage display": "butter", "Chicken display": "milk",
	"Ham display2": "eggs", "Sausage display2": "yogurt"}
## Cooler: its box centre moves from x -20.7575 to the gondola's old centre -25.6. Gondola: from
## centre -25.6 to 2 cm off the east wall's inner face (x -20.25; the cooler stood flush there).
const COOLER_SHIFT := Vector3(-25.6 + 20.7575, 0, 0)
const GONDOLA_SHIFT := Vector3(-20.25 - .02 - .5605 + 25.6, 0, 0)
const COOLER_PARTS := ["Drinks cooler", "water bottle", "juice", "soda"]
## The gondola's open face (x -25.9 before the move): [z of its bay, level y] -> word.
const HOME_FACE := {"Soap display3": "toothbrush", "Sponge display3": "toothpaste",
	"Detergent display3": "shampoo", "Soap display2": "soap", "Sponge display2": "sponge",
	"Detergent display2": "shampoo", "Soap display": "detergent", "Sponge display": "detergent",
	"Detergent display": "detergent"}

func clear_sections(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var products := Products.new()
	var removed := 0
	var restocked := 0
	# Snacks: pantry goods on the gondola faces and the end caps become snacks.
	var rekey := {}
	for root in interior.get_children():
		var kind := str(root.get_meta("word_key", ""))
		if not root is Node3D or not str(root.name).contains("display"):
			continue
		var face := ""
		for x in SNACK_FACES:
			if absf((root as Node3D).position.x - x) < .05:
				face = SNACK_FACES[x]
		if kind in PANTRY_WORDS and face != "":
			rekey[root] = face
		elif SNACK_ENDCAPS.has(kind):
			rekey[root] = SNACK_ENDCAPS[kind]
	for name in STAND_REFILL:
		rekey[interior.get_node(name)] = STAND_REFILL[name]
	for name in FRIDGE_REFILL:
		rekey[interior.get_node(name)] = FRIDGE_REFILL[name]
	# Home goods: the gondola's wall face goes; its open face takes all six goods.
	for root in interior.get_children():
		if str(root.get_meta("word_key", "")) in ["toothbrush", "toothpaste", "shampoo"] \
				and str(root.name).contains("display") and not root is Area3D:
			interior.remove_child(root)
			root.free()
			removed += 1
	for name in HOME_FACE:
		rekey[interior.get_node(name)] = HOME_FACE[name]
	# Coffee on the cooler's top shelf.
	for name in ["Water Bottle display4", "Juice display4", "Soda display4"]:
		rekey[interior.get_node(name)] = "coffee"
	# Give every rekeyed group a temporary name, then its word's next free display name.
	for root in rekey:
		root.name = "Restock " + str(root.get_instance_id())
	for root in rekey:
		var kind: String = rekey[root]
		var title := kind.capitalize() + " display"
		var n := 1
		while interior.has_node(title + ("" if n == 1 else str(n))):
			n += 1
		root.name = title + ("" if n == 1 else str(n))
		root.set_meta("word_key", kind)
		_fit_pick(root, products, kind)
		products.restock(root)
		restocked += 1
	# Swap the cooler and the home goods gondola (whole roots: fixtures, goods, price tags).
	var moved := 0
	for root in interior.get_children():
		if not root is Node3D:
			continue
		var kind := str(root.get_meta("word_key", ""))
		var title := str(root.name)
		if title == "Drinks cooler" or (kind in ["water bottle", "juice", "soda", "coffee"] and title.contains("display")):
			(root as Node3D).position += COOLER_SHIFT
			moved += 1
		elif title in ["Household gondola", "Household endcap"] or (title.contains("display") and kind in
				["soap", "sponge", "detergent", "toothbrush", "toothpaste", "shampoo", "toilet paper"]):
			(root as Node3D).position += GONDOLA_SHIFT
			moved += 1
	# The PANTRY band reads SNACKS, with a wrapped-sweet pictogram.
	for label: Label3D in interior.find_children("*", "Label3D", false, false):
		if str(label.get_meta("sign_english", label.text)) == "PANTRY":
			label.text = "SNACKS"
			for meta in ["sign_source", "sign_english"]:
				if label.has_meta(meta):
					label.set_meta(meta, "SNACKS")
			if str(label.name) == "PANTRY label":
				label.name = "SNACKS label"
	var icon := interior.get_node("PANTRY pictogram") as MeshInstance3D
	icon.name = "SNACKS pictogram"
	icon.mesh = products.pictogram("candy", "d08a3a")
	if restocked != 106 or removed != 9:
		push_error("supermarket clear_sections: expected 106 groups restocked and 9 removed")
	print("SUPERMARKET clear_sections: %d groups restocked, %d removed, %d roots moved" % [restocked, removed, moved])

## A group's pick box was sized for its old product (a tuna tin is 5 cm tall, a cracker box 19):
## it gets the new product's height (its unit height grown by goods_scale, as restock() uses it,
## plus the 2 cm margin; at most 0.42 m, under the next shelf) and keeps its bottom, width and depth.
func _fit_pick(root: Node3D, products, kind: String) -> void:
	for area in root.get_children():
		if not area is Area3D:
			continue
		var shape := area.get_child(0) as CollisionShape3D
		var box := (shape.shape as BoxShape3D).duplicate() as BoxShape3D
		var height := minf(Products.FOOT[kind].z * products.goods_scale(kind) + .02, .42)
		shape.position.y += (height - box.size.y) * .5
		box.size.y = height
		shape.shape = box

## Compact layout (18 Nov 2026, user-approved "staff wall" and "cold wall on left"; the snacks
## section was far too big for its four words and the fridges stood mid-floor). Seen from the door
## (front z 34.2, looking +Z) the left wall is x -20.25 and the right wall x -45.75.
## - Staff wall: a solid interior wall (store wall finish, a closed staff-only door, no
##   interaction) across the hall with its shop face at z 53.3; the seafood, meat and bakery
##   counters (same order), their back benches, signs and wall bands all come 6.45 forward (the old
##   wall face was z 59.75), keeping the 1.62 staff gap the bread rack is picked from.
##   The back row of ceiling lights moves to z 50 over the counters.
## - Cold wall on the left: the drinks cooler goes back against the left wall at the front (the
##   17 Nov swap undone), the two REFRIGERATED fridges stand turned behind it in one run along the
##   same wall, facing into the store. Their signs hang turned along the wall, lower (y 3.25) than
##   the others; DRINKS & HOME reads DRINKS; FRUIT hangs higher (y 4.0) so it never hides them. The left wall band turns cold blue over the run (its apple pictogram goes).
## - Fruit: the produce stand (big fruit) keeps its two middle bays and stands by the door between
##   the fruit table and the cooler; the fruit wall becomes a two-sided island behind it (bays 1-2
##   face the door, bays 3-4 the counters; bay 5 held only second apples, oranges and grapes and
##   goes). The vegetable stand stays where it was.
## - Right side behind the checkouts: one SNACKS gondola of three bays (its door-side face holds
##   chocolate over candy, the other cookies over crackers; the groups keep their pick areas) and the
##   home goods gondola with its toilet paper end cap against the right wall, under a new HOME sign
##   (HOGAR, 家居). The second gondola, both pantry end caps and their goods leave the store.
## - Floor inlays and the right wall band (no pictogram) follow their sections.
## Shop floor: x -45.75..-20.25, z 34.2..53.3; fixtures stop by z 47.45, 2.2 in front of the counters.
const STAFF_WALL_Z := 53.3
const COUNTER_DZ := -6.45
const BENCH_DZ := -6.45
const STAFF_DOOR_X := -37.7
const COOLER_WORDS := ["water bottle", "juice", "soda", "coffee"]
const HOME_WORDS := ["soap", "sponge", "detergent", "toothbrush", "toothpaste", "shampoo", "toilet paper"]
const SNACK_WORDS := ["chocolate", "candy", "cookie", "cracker"]
## Fridge centres: 2 cm off the left wall, the first 3 cm behind the cooler, 2 cm between them.
const FRIDGE_X := -20.77
const FRIDGE_FRONT_Z := 42.79
const FRIDGE_BACK_Z := 45.87
const PRODUCE_DZ := -8.5
const FRUIT_ISLAND := Vector2(-25.25, 45.2)
const SNACK_AT := Vector2(-39.4, 45.22)
const HOME_AT := Vector2(-45.75 + .02 + .5605, 45.23)

func compact_layout(town: Node3D, game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var before := _words(interior)
	var products := Products.new()
	var dropped := 0
	# Every group is gathered from the 17 Nov state before anything moves.
	var back := _roots(interior, func(n: Node3D) -> bool: return n.position.z >= 55.0)
	var cooler := _roots(interior, func(n: Node3D) -> bool: return str(n.name) == "Drinks cooler" \
			or (str(n.name).contains("display") and str(n.get_meta("word_key", "")) in COOLER_WORDS))
	var home := _roots(interior, func(n: Node3D) -> bool: return str(n.name) in ["Household gondola", "Household endcap"] \
			or (str(n.name).contains("display") and str(n.get_meta("word_key", "")) in HOME_WORDS))
	var fridge_front := _roots(interior, func(n: Node3D) -> bool: return _in(n, -32.8, -29.65, 49.4, 50.75, 0, 3))
	var fridge_back := _roots(interior, func(n: Node3D) -> bool: return _in(n, -35.95, -32.8, 49.4, 50.75, 0, 3))
	var stand_root: Node3D = interior.get_node("Produce Stand")
	var stand := _roots(interior, func(n: Node3D) -> bool: return _in(n, -26.5, -24.7, 42.5, 51.5, 0, 3))
	var wall_root: Node3D = interior.get_node("Fruit wall display")
	var fruit := _roots(interior, func(n: Node3D) -> bool: return n != wall_root and _in(n, -22.1, -20.4, 42.5, 51.5, 0, 3))
	var snacks := _roots(interior, func(n: Node3D) -> bool: return str(n.name).contains("display") \
			and str(n.get_meta("word_key", "")) in SNACK_WORDS and _in(n, -44.0, -38.5, 43.0, 51.2, 0, 3))
	var cold_sign := _roots(interior, func(n: Node3D) -> bool: return _in(n, -35.6, -30.0, 48.75, 49.05, 3, 5))
	var drinks_sign := _roots(interior, func(n: Node3D) -> bool: return _in(n, -26.2, -20.6, 38.45, 38.75, 3, 5))
	var fruit_sign := _roots(interior, func(n: Node3D) -> bool: return _in(n, -25.6, -21.0, 46.85, 47.15, 3, 5))
	var snack_sign := _roots(interior, func(n: Node3D) -> bool: return _in(n, -43.6, -39.0, 42.45, 42.75, 3, 5))
	var counts := [back.size(), cooler.size(), home.size(), fridge_front.size(), fridge_back.size(), stand.size(),
		fruit.size(), snacks.size(), cold_sign.size(), drinks_sign.size(), fruit_sign.size(), snack_sign.size()]
	print("SUPERMARKET compact_layout gathered: back, cooler, home, fridges, stand, fruit, snacks, signs = %s" % [counts])

	# 1. Staff wall.
	for node: Node3D in back:
		node.position.z += COUNTER_DZ if node.position.z < 58.5 else BENCH_DZ
	for node in interior.get_children():
		if node is Node3D and (node is Light3D or str(node.get_meta("word_key", "")) == "ceiling light") \
				and (node as Node3D).position.z > 54.0:
			(node as Node3D).position.z = 50.0
	_staff_wall(interior, game)
	for title in ["SEAFOOD floor inlay", "MEAT floor inlay", "BAKERY floor inlay"]:
		var inlay: Node3D = interior.get_node(title)
		var box := _inlay_box(inlay)
		_resize(inlay, box.position.x, box.end.x, 48.75, STAFF_WALL_Z - .05)

	# 2. Cold wall on the left.
	for node: Node3D in cooler:
		node.position -= COOLER_SHIFT
	_carry(fridge_front, Vector3(-31.25, 0, 50.1), PI / 2, Vector3(FRIDGE_X, 0, FRIDGE_FRONT_Z))
	_carry(fridge_back, Vector3(-34.35, 0, 50.1), PI / 2, Vector3(FRIDGE_X, 0, FRIDGE_BACK_Z))
	_carry(cold_sign, Vector3(-32.8, 0, 48.9), PI / 2, Vector3(-21.5, 0, (FRIDGE_FRONT_Z + FRIDGE_BACK_Z) / 2))
	_carry(drinks_sign, Vector3(-23.4, 0, 38.6), PI / 2, Vector3(-21.5, 0, 38.2))
	_relabel(drinks_sign, "DRINKS")
	# The wall signs hang just above the cooler and fridges, FRUIT higher than the others: seen from
	# eye height the nearer FRUIT sign then always passes above them instead of hiding them.
	_hang(cold_sign, 3.25)
	_hang(drinks_sign, 3.25)
	_hang(fruit_sign, 4.0)
	interior.get_node("DRINKS & HOME department sign").name = "DRINKS department sign"
	interior.get_node("DRINKS & HOME label").name = "DRINKS label"
	var drinks_inlay: Node3D = interior.get_node("DRINKS & HOME floor inlay")
	drinks_inlay.name = "DRINKS floor inlay"
	_resize(drinks_inlay, -23.5, -20.4, 34.8, 41.25)
	_resize(interior.get_node("REFRIGERATED floor inlay"), -23.5, -20.4, 41.25, 47.6)
	var band: Node3D = interior.get_node("FRUIT wall band")
	band.name = "COLD wall band"
	_resize_band(band, 35.4, 47.2)
	for mesh in band.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = game.material_for(Color("6fa3c7"))
	dropped += _drop([interior.get_node("FRUIT pictogram"), interior.get_node("SNACKS pictogram")])

	# 3. Fruit: the produce stand by the door, the fruit wall a two-sided island behind it.
	var stand_z := stand_root.position.z
	for node: Node3D in stand.duplicate():
		var rel := node.position.z - stand_z
		if node != stand_root and absf(rel) > 2.0 and absf(rel) < 3.2:
			stand.erase(node)
			dropped += _drop([node])
		elif rel < -2.0:
			node.position.z += 1.75
		elif rel > 2.0:
			node.position.z -= 1.75
	_shorten(stand_root, 7.0, -1.75, 1.75)
	for node: Node3D in stand:
		node.position.z += PRODUCE_DZ
	var wall_at := Vector3(wall_root.position.x, 0, wall_root.position.z)
	var part_b := wall_root.duplicate() as Node3D
	part_b.name = "Fruit wall display2"
	interior.add_child(part_b)
	_shorten(wall_root, 8.75, -4.375, -.875)
	_shorten(part_b, 8.75, -.875, 2.625)
	# Back panels (local x .85) 2 cm apart along the island's middle; A faces the door, B the counters.
	var to_a := Vector3(FRUIT_ISLAND.x - 2.625, 0, FRUIT_ISLAND.y - .86)
	var to_b := Vector3(FRUIT_ISLAND.x - .875, 0, FRUIT_ISLAND.y + .86)
	var face_a := [wall_root]
	var face_b := [part_b]
	for node: Node3D in fruit:
		var rel := node.position.z - wall_at.z
		if rel < -.875:
			face_a.append(node)
		elif rel < 2.625:
			face_b.append(node)
		else:
			dropped += _drop([node])
	_carry(face_a, wall_at, -PI / 2, to_a)
	_carry(face_b, wall_at, PI / 2, to_b)
	_carry(fruit_sign, Vector3(-23.3, 0, 47.0), 0.0, Vector3(-25.4, 0, 42.2))
	_resize(interior.get_node("FRUIT floor inlay"), -28.0, -23.5, 35.4, 47.6)

	# 4. Right side: one three-bay SNACKS gondola, the home goods against the right wall.
	var gondola: Node3D = interior.get_node("Pantry gondola")
	var g1 := Vector3(-43.2, 0, 47.3)
	var g2 := Vector3(-39.4, 0, 47.3)
	var snack_face := [gondola]
	for node: Node3D in snacks:
		var p := node.position
		var top := p.y > 1.0
		var keep := absf(p.z - 47.3) < 2.0
		if keep and top and absf(p.x + 43.5) < .05:          # chocolate stays on the door-side face
			snack_face.append(node)
		elif keep and not top and absf(p.x + 42.9) < .05:    # candy turns to under the chocolate
			_carry([node], g1, PI, g1)
			snack_face.append(node)
		elif keep and top and absf(p.x + 39.7) < .05:        # cookies turn onto the other face
			_carry([node], g2, PI, g1)
			snack_face.append(node)
		elif keep and not top and absf(p.x + 39.1) < .05:    # crackers move across under them
			_carry([node], g2, 0.0, g1)
			snack_face.append(node)
		else:
			dropped += _drop([node])
	_shorten(gondola, 7.4, -2.22, 2.22, true)
	(gondola.get_node("Shelf price tags") as MeshInstance3D).mesh = products.shelf_tags(4.44, 3, 4)
	_carry(snack_face, g1, 0.0, Vector3(SNACK_AT.x, 0, SNACK_AT.y))
	dropped += _drop([interior.get_node("Pantry gondola2"), interior.get_node("Pantry endcap"), interior.get_node("Pantry endcap2")])
	var household: Node3D = interior.get_node("Household gondola")
	_carry(home, Vector3(household.position.x, 0, household.position.z), PI, Vector3(HOME_AT.x, 0, HOME_AT.y))
	# HOME sign: a copy of the SNACKS sign turned along the right wall over the home goods.
	var home_sign := []
	for node: Node3D in snack_sign:
		var copy := node.duplicate() as Node3D
		if str(node.name) == "PANTRY department sign":
			copy.name = "HOME department sign"
		elif str(node.name) == "SNACKS label":
			copy.name = "HOME label"
		interior.add_child(copy, true)
		home_sign.append(copy)
	_relabel(home_sign, "HOME")
	_carry(home_sign, Vector3(-41.3, 0, 42.6), -PI / 2, Vector3(-44.4, 0, 45.0))
	_carry(snack_sign, Vector3(-41.3, 0, 42.6), 0.0, Vector3(SNACK_AT.x, 0, 43.6))
	interior.get_node("PANTRY department sign").name = "SNACKS department sign"
	var snack_inlay: Node3D = interior.get_node("PANTRY floor inlay")
	snack_inlay.name = "SNACKS floor inlay"
	_resize(snack_inlay, -45.6, -37.8, 42.3, 47.6)
	var home_band: Node3D = interior.get_node("PANTRY wall band")
	home_band.name = "HOME wall band"
	_resize_band(home_band, 42.5, 47.4)

	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "supermarket", 4)
	var after := _words(interior)
	for word in before:
		if not after.has(word):
			push_error("supermarket compact_layout: word %s left the store" % word)
	print("SUPERMARKET compact_layout: %d roots removed, %d words before, %d after" % [dropped, before.size(), after.size()])
	for title in ["Drinks cooler", "Refrigerator2", "Refrigerator", "Produce Stand", "Fruit wall display", "Fruit wall display2",
			"Vegetable stand", "Pantry gondola", "Household gondola", "Household endcap", "Seafood counter", "Deli Counter",
			"Bakery counter", "Seafood back bench", "Staff wall"]:
		var box := _bounds(interior, interior.get_node(title))
		print("SUPERMARKET compact_layout %s: x %.2f..%.2f z %.2f..%.2f" % [title, box.position.x, box.end.x, box.position.z, box.end.z])

## The new wall across the hall with a closed staff door (decoration: no interaction, one solid body).
func _staff_wall(interior: Node3D, game) -> void:
	var wall := Node3D.new()
	wall.name = "Staff wall"
	wall.set_meta("market_fitting", true)
	interior.add_child(wall)
	wall.position = Vector3(-33.0, 0, STAFF_WALL_Z)
	var x := STAFF_DOOR_X + 33.0
	_part(wall, game, "Staff wall panel", Vector3(0, 2.87, .1), Vector3(25.5, 5.74, .2), "eadfcd", true)
	_part(wall, game, "Staff wall skirting", Vector3(0, .16, -.01), Vector3(25.5, .12, .02), "cdbf9f")
	_part(wall, game, "Staff door leaf", Vector3(x, 1.21, -.025), Vector3(1.08, 2.22, .05), "c7cdd2")
	_part(wall, game, "Staff door jamb", Vector3(x - .58, 1.25, -.04), Vector3(.08, 2.3, .08), "2b5a8c")
	_part(wall, game, "Staff door jamb2", Vector3(x + .58, 1.25, -.04), Vector3(.08, 2.3, .08), "2b5a8c")
	_part(wall, game, "Staff door head", Vector3(x, 2.36, -.04), Vector3(1.24, .08, .08), "2b5a8c")
	_part(wall, game, "Staff door kick plate", Vector3(x, .26, -.055), Vector3(.98, .26, .01), "8a949c")
	_part(wall, game, "Staff door push plate", Vector3(x - .38, 1.15, -.055), Vector3(.12, .3, .01), "b9c0c6")
	_disc(wall, game, "Staff door window", Vector3(x, 1.62, -.056), .17, "33414c")
	_disc(wall, game, "Staff only plaque", Vector3(x, 2.07, -.056), .11, "c0392b")
	_part(wall, game, "Staff only bar", Vector3(x, 2.07, -.064), Vector3(.13, .03, .004), "f6f0e4")

func _part(parent: Node3D, game, title: String, at: Vector3, size: Vector3, colour: String, solid := false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = game.material_for(Color(colour))
	mesh.position = at
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = title + " body"
		body.position = at
		parent.add_child(body)
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)

## A flat disc on the wall's face (its axis along -Z).
func _disc(parent: Node3D, game, title: String, at: Vector3, radius: float, colour: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = .01
	disc.radial_segments = 24
	mesh.mesh = disc
	mesh.material_override = game.material_for(Color(colour))
	mesh.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), at)
	parent.add_child(mesh)

## Interior roots a layout move may carry (not the floor grout, the floor inlays, lights or ceiling).
func _roots(interior: Node3D, test: Callable) -> Array:
	var out := []
	for node in interior.get_children():
		if not node is Node3D or node is Light3D:
			continue
		var title := str(node.name)
		if title.contains("floor inlay") or title in ["Floor grout", "Interior ceiling finish"]:
			continue
		var at: Vector3 = (node as Node3D).position
		if (at.y < .2 and not node.has_meta("word_key")) or at.y >= 5.0:
			continue
		if test.call(node):
			out.append(node)
	return out

func _in(node: Node3D, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float) -> bool:
	var p := node.position
	return p.x >= x0 and p.x <= x1 and p.z >= z0 and p.z <= z1 and p.y >= y0 and p.y <= y1

## Turns nodes about the vertical through `from` and puts that point at `to` (interior space).
func _carry(nodes: Array, from: Vector3, turn: float, to: Vector3) -> void:
	var move := Transform3D(Basis(Vector3.UP, turn), to) * Transform3D(Basis.IDENTITY, -from)
	for node: Node3D in nodes:
		node.transform = move * node.transform

## Cuts a fixture built of boxes along its local z down to the part between lo and hi: boxes that
## run its whole `length` (meshes and collision shapes) are shortened and centred there, shorter
## pieces outside are removed, or with `ends` its two end panels move to lo and hi.
func _shorten(root: Node3D, length: float, lo: float, hi: float, ends := false) -> void:
	var cut := length - (hi - lo)
	for child in root.get_children():
		var box: Resource = null
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			box = (child as MeshInstance3D).mesh
		elif child is CollisionObject3D and child.get_child_count() == 1 and child.get_child(0) is CollisionShape3D \
				and (child.get_child(0) as CollisionShape3D).shape is BoxShape3D:
			box = (child.get_child(0) as CollisionShape3D).shape
		if box == null:
			continue
		var z: float = (child as Node3D).position.z
		if box.size.z >= length - .2:
			box = box.duplicate()
			box.size.z -= cut
			if child is MeshInstance3D:
				(child as MeshInstance3D).mesh = box
			else:
				(child.get_child(0) as CollisionShape3D).shape = box
			(child as Node3D).position.z = (lo + hi) / 2
		elif z < lo - .02 or z > hi + .02:
			if ends and absf(absf(z) - length / 2) < .05:
				(child as Node3D).position.z = hi if z > 0 else lo
			else:
				root.remove_child(child)
				child.free()

## A floor inlay's box in interior space.
func _inlay_box(inlay: Node3D) -> AABB:
	var mesh := inlay.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	return _box_in(inlay.get_parent(), mesh)

## Floor inlay to the interior rectangle x0..x1, z0..z1 (its height and colour kept).
func _resize(inlay: Node3D, x0: float, x1: float, z0: float, z1: float) -> void:
	var mesh := inlay.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var box := (mesh.mesh as BoxMesh).duplicate() as BoxMesh
	box.size.x = absf(x1 - x0)
	box.size.z = absf(z1 - z0)
	mesh.mesh = box
	inlay.position.x = (x0 + x1) / 2 - mesh.position.x
	inlay.position.z = (z0 + z1) / 2 - mesh.position.z

## Side wall band to run from z0 to z1 (its height and wall plane kept).
func _resize_band(band: Node3D, z0: float, z1: float) -> void:
	var mesh := band.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var box := (mesh.mesh as BoxMesh).duplicate() as BoxMesh
	box.size.z = z1 - z0
	mesh.mesh = box
	band.position.z = (z0 + z1) / 2 - mesh.position.z

## Hangs a sign (board, labels, rods; boards 0.65 high at y 3.65) at board centre height `y`; its
## rods (centres above 4.3) are cut or lengthened to still reach the ceiling at y 5.545.
func _hang(nodes: Array, y: float) -> void:
	var dy := y - 3.65
	for node: Node3D in nodes:
		if node.position.y < 4.3:
			node.position.y += dy
			continue
		var bottom := y + .325
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			var shape := mesh.mesh.duplicate()
			if shape is BoxMesh:
				(shape as BoxMesh).size.y = 5.545 - bottom
			elif shape is CylinderMesh:
				(shape as CylinderMesh).height = 5.545 - bottom
			mesh.mesh = shape
			mesh.position.y = 0.0
		node.position.y = (bottom + 5.545) / 2

func _relabel(nodes: Array, english: String) -> void:
	for label in nodes:
		if not label is Label3D:
			continue
		label.text = english
		for meta in ["sign_source", "sign_english"]:
			if label.has_meta(meta):
				label.set_meta(meta, english)
		if label.has_meta("sign_spanish"):
			label.set_meta("sign_spanish", WorldSign.SignLanguage.say(english, "es"))

func _drop(nodes: Array) -> int:
	for node: Node in nodes:
		node.get_parent().remove_child(node)
		node.free()
	return nodes.size()

func _words(interior: Node3D) -> Dictionary:
	var words := {}
	for node in interior.get_children():
		if node.has_meta("word_key"):
			words[str(node.get_meta("word_key"))] = true
	return words

## A root's meshes' box in interior space.
func _bounds(interior: Node3D, root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		var part := _box_in(interior, mesh)
		box = part if first else box.merge(part)
		first = false
	return box

## Clay-toy products, 18 Nov 2026 (docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket compact redesign"):
## refills every product group with the redrawn models, each at least the old coconut's size.
func clay_products(town: Node3D, _game) -> void:
	Products.new().restock_all(town.get_node(INTERIOR))
