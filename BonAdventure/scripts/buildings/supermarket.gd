extends RefCounted
## Supermarket own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## supermarket unit (scenes/town/supermarket.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- supermarket
## Never rename or remove a baked step (add a new one that undoes it).
## Record: docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket product art — 8 November 2026".
const STEPS := ["product_models", "fixture_finish", "checkout_props", "seafood_ice", "surface_gaps", "coplanar_gaps", "coplanar_gaps_2", "coplanar_envelope", "glass_windows", "tutorial_fruit", "world_signs", "clear_sections"]
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
