extends RefCounted
## Library own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## library unit (scenes/town/library.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- library
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "category_shelves", "glass_windows", "big_books", "return_cart", "cart_frame", "cart_spot", "six_categories", "new_titles", "rear_display", "cosy_room"]

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "library")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "library", 2)

# =============================================================================================
# category_shelves (11 Nov 2026, user request; docs/guides/TOWN_DESIGN_BRIEF.md "Library category
# shelves"): the six old bookcases and the FICTION / DISCOVER signs give way to SIX category
# bookcases, four on each side wall, each with a coloured header (emblem + name), a back panel
# and shelf lips in its colour and books with a spine sticker in that colour. Random gaps are
# left in the rows (marked by "Gap ..." nodes) so returned books can be shelved later; the
# 1 Nov book bin becomes a return shelf (a book-drop cabinet under a three-tier face-out rack)
# holding the user's 18 picture books to sort, three per category (BOOKS; each its own word root
# with a matching gap on its category bookcase); the computer desks move to the rear wall; Rosa
# the librarian (samoyed plush) stands by the return shelf and offers the shelving mission
# (scripts/learning/library_session.gd; mechanics later).
#
# Library source frame (the site is scaled 1.3 and turned in town): inner walls x -20.885
# (west, left on entering) / -9.115 (east), glazed front z 37.7, rear wall z 52.385, door x -15,
# floor top 0.04, ceiling 5.23.
# =============================================================================================

const Art := preload("res://scripts/buildings/supermarket_products.gd")
const FIGURE_LAYER: int = preload("res://scripts/characters/house_characters.gd").FIGURE_LAYER

const WEST := -20.885
const EAST := -9.115
const REAR := 52.385
const F := .04
## Bookcase: length along the wall, depth, carcass height; shelf surfaces (base board and three
## shelves, above F); the header board rests on top. Until 12 Nov 2026 2.58 high with five rows;
## since step big_books (books 50 % larger) 2.78 high with four rows 0.64 apart.
const CASE_LEN := 2.4
const CASE_DEPTH := .5
const CASE_HEIGHT := 2.78
const TIERS := [.14, .78, 1.42, 2.06]
const HEADER := Vector2(2.2, .46)
## Centres of the four bookcases along each side wall (front to back).
const CASE_Z := [43.45, 45.9, 48.35, 50.8]
## Categories (six since 16 Nov 2026, user: easier for 7-year-olds; Space, Geography, History and
## Stories were dropped, Travel and Nature added; 17 Nov 2026, user: Animals, Sports, Music, Food,
## Vehicles, Plants, each in the colour of the category it replaces, so no book fits two shelves):
## west wall front to back (three), then east wall back to front (three), all in the front three
## CASE_Z slots. id, sign text (English source, translated by data/sign_translations.json), colour,
## vocabulary word (data/words.json; the header is that word's object, step new_titles).
const CATEGORIES := [
	["animals", "ANIMALS", "4e8f3a", "animal"],
	["sports", "SPORTS", "d4572a", "sport"],
	["music", "MUSIC", "b2437e", "music"],
	["food", "FOOD", "c98d14", "food"],
	["vehicles", "VEHICLES", "2f6fb5", "vehicle"],
	["plants", "PLANTS", "3f9a6a", "plant"],
]
const WOOD := "b8783f"
const WOOD_DARK := "7f5130"
const CREAM := "f6efdf"
const GOLD := "d8b85a"
## Shelved book colours (user, 11 Nov 2026: fewer, thicker, plain books, "something like" a
## reference of chunky toy-like bookcases): each category its own family of shades, all from one
## soft palette; no stickers, bands or lying books.
const BOOK_SHADES := {
	"animals": ["5a9a44", "72ad4f", "95c467", "bcd98f", "4d8a3e", "a9bf62"],
	"sports": ["cf532a", "e5744a", "ef986a", "f5c39b", "bb412e", "e09c39"],
	"music": ["ad417b", "cb6899", "e094b9", "f0c1d7", "964d9b", "dc7787"],
	"food": ["cc951b", "e3b13d", "f0cc6b", "f6e2a4", "d5873a", "bfa045"],
	"vehicles": ["2f6fb5", "4a88c8", "78a8dc", "a9c6ea", "3d5fa8", "5aa0b8"],
	"plants": ["3f9a6a", "58b07e", "86c99e", "b6dfc0", "6aa14a", "d68aa0"],
}
## The bookcases' warm, toy-like wood (the reference's orange frames).
const CASE_WOOD := "d99448"
const CASE_WOOD_DARK := "b8733a"
const CASE_BACK := "c8823f"
const CASE_SHELF := "e6a85c"
## The return shelf (book drop: word "book bin", the 1 Nov returns bin's word) and Rosa beside it;
## (-13.2, 49.5) until 12 Nov 2026, when the wider four-tier rack for the larger books moved 0.3 east.
const RACK := Vector3(-12.9, F, 49.55)
## The 18 picture books to sort (titles chosen by the user, 11, 16 and 17 Nov 2026), three per
## category; English source text, translated like signs (data/sign_translations.json).
const BOOKS := {
	"animals": ["Dogs", "Cats", "Elephants"],
	"sports": ["Soccer", "Basketball", "Tennis"],
	"music": ["Guitar", "Piano", "Drums"],
	"food": ["Pizza", "Cookies", "Cake"],
	"vehicles": ["Cars", "Trains", "Airplanes"],
	"plants": ["Flowers", "Trees", "Cactus"],
}
## Each title's vocabulary word (data/words.json; 17 Nov 2026, user: the book topics and the
## category names are tracked words). The display's and the cart's books carry it as word_key, and
## Library Helper records it (scripts/learning/library_session.gd; tools/vocabulary_report.gd).
const BOOK_WORDS := {
	"Dogs": "dog", "Cats": "cat", "Elephants": "elephant",
	"Soccer": "soccer", "Basketball": "basketball", "Tennis": "tennis",
	"Guitar": "guitar", "Piano": "piano", "Drums": "drum",
	"Pizza": "pizza", "Cookies": "cookie", "Cake": "cake",
	"Cars": "car", "Trains": "train", "Airplanes": "airplane",
	"Flowers": "flower", "Trees": "tree", "Cactus": "cactus",
}
## The reusable book (scenes/props/book.tscn): sizes of shelved and picture books, the plain
## shelf-book look and the picture-book covers (12 Nov 2026).
const Book := preload("res://scripts/world/library_book.gd")
const BOOK_SCENE := preload("res://scenes/props/book.tscn")
const LIBRARIAN := "Librarian"
const LIBRARIAN_SPOT := Vector3(-15.9, F, 49.75)
## Computer desks and their chairs move from the middle (z 47.4 ... 49.4) to the rear wall.
const COMPUTER_SHIFT := Vector3(0, 0, 2.95)

var g
var site: Node3D
var art
var rng := RandomNumberGenerator.new()

func category_shelves(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	if site == null:
		push_error("library: site not found")
		return
	art = Art.new()
	rng.seed = 20261111
	_clear_old()
	_move_computers()
	var shelves := Node3D.new()
	shelves.name = "CategoryShelves"
	site.add_child(shelves)
	_cases_and_returns(shelves)
	_prints(shelves)
	_librarian()
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "library", 3)

## The six bookcases with their gaps and the return shelf with the 18 picture books (drawn with
## the current sizes: since 12 Nov 2026 the larger books, step big_books).
func _cases_and_returns(shelves: Node3D) -> void:
	# The 18 picture books to sort first: each one's thickness and home shelf, so the shelf
	# leaves a gap that fits it.
	var plan := {}
	for category in CATEGORIES:
		var homes: Array = []
		for title in BOOKS[category[0]]:
			homes.append({"title": title, "t": rng.randf_range(Book.PICTURE_THICKNESS.x, Book.PICTURE_THICKNESS.y), "row": rng.randi_range(0, TIERS.size() - 1)})
		plan[category[0]] = homes
	for i in CATEGORIES.size():
		var west := i < 3
		var z: float = CASE_Z[i] if west else CASE_Z[5 - i]
		_bookcase(shelves, CATEGORIES[i], west, z, plan[CATEGORIES[i][0]])
	_return_shelf(shelves, plan)

# =============================================================================================
# big_books (12 Nov 2026, user request; docs/guides/TOWN_DESIGN_BRIEF.md "Library books 50 % larger"):
# the shelved books grow 50 % taller and proportionately wider (0.165-0.225 thick, 0.5-0.6
# tall, 0.45 deep), so each bookcase is 0.2 taller with four rows instead of five; the 18 picture
# books on the return shelf become the same size (0.45 x 0.54 covers, 0.165-0.2 thick) and are instances
# of the reusable book scene (scenes/props/book.tscn) for the shelving minigame; the return shelf
# becomes a wider four-tier rack, six books a tier. The bookcases, gaps and return shelf are built
# again (new random gaps and order); names, words and metas stay as in category_shelves.
# =============================================================================================
func big_books(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	var shelves: Node3D = site.get_node_or_null("CategoryShelves") if site != null else null
	if shelves == null:
		push_error("library: category shelves not found")
		return
	art = Art.new()
	rng.seed = 20261112
	for child in shelves.get_children():
		var title := String(child.name)
		if title.begins_with("Bookcase ") or title in ["Book drop", "Return shelf"]:
			shelves.remove_child(child)
			child.free()
	_cases_and_returns(shelves)
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "library", 4)

## Six categories of three books (16 Nov 2026): the shelves are rebuilt from the current
## CATEGORIES and BOOKS, three bookcases a wall.
func six_categories(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	var shelves: Node3D = site.get_node_or_null("CategoryShelves") if site != null else null
	if shelves == null:
		push_error("library: category shelves not found")
		return
	art = Art.new()
	rng.seed = 20261116
	for child in shelves.get_children():
		var title := String(child.name)
		if title.begins_with("Bookcase ") or title in ["Book drop", "Return shelf", "New books shelf"]:
			shelves.remove_child(child)
			child.free()
	_cases_and_returns(shelves)
	# The rack is the NEW BOOKS display again (steps return_cart and cart_frame).
	var rack := shelves.get_node_or_null("Return shelf")
	if rack != null:
		rack.name = "New books shelf"
		var header := rack.get_node_or_null("RETURNS header") as Label3D
		if header != null:
			header.name = "NEW BOOKS header"
			header.text = "NEW BOOKS"
			for meta in ["sign_source", "sign_english"]:
				if header.has_meta(meta):
					header.set_meta(meta, "NEW BOOKS")
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "library", 5)

# ---------------------------------------------------------------- clearing

## Removes the six bookcases (frames, shelved books, spine bands), the FICTION / DISCOVER boards
## and the 1 Nov book bin with its books and label; things hung on or standing in front of the
## side walls where the new bookcases go (trailing plants, a framed print) also go, but not the
## wainscot behind them.
func _clear_old() -> void:
	var doomed: Array = []
	for child in site.get_children():
		var title := String(child.name)
		for prefix in ["Bookcase", "Shelved book", "Book spine band", "FICTION ", "DISCOVER ", "Book Bin"]:
			if title.begins_with(prefix):
				doomed.append(child)
				break
	var refresh := site.get_node_or_null("LibraryRefresh")
	var zones: Array = []
	for wall_x in [WEST, EAST]:
		var x0: float = wall_x if wall_x < -15 else wall_x - CASE_DEPTH - .05
		zones.append(AABB(Vector3(x0, 0, CASE_Z[0] - CASE_LEN * .5 - .05), Vector3(CASE_DEPTH + .05, 3.6, CASE_Z[3] - CASE_Z[0] + CASE_LEN + .1)))
	var bin_zone := AABB(Vector3(-13.55, 0, 50.15), Vector3(.9, .7, .8))
	for holder in [site, refresh]:
		if holder == null:
			continue
		for child in holder.get_children():
			if not child is Node3D or doomed.has(child):
				continue
			var p: Vector3 = child.position
			if holder == refresh and bin_zone.has_point(p):
				doomed.append(child)
				continue
			# The 1 Nov trailing plants hung from the old bookcase tops (leaves up to 0.7 out).
			if holder == refresh and p.y > 2.5 and p.y < 3.6 and (p.x < WEST + 1.0 or p.x > EAST - 1.0) and p.z > 42.0:
				doomed.append(child)
				continue
			for zone in zones:
				var wall_x: float = WEST if zone.position.x < -15 else EAST
				var wainscot: bool = p.y < 1.1 and absf(p.x - wall_x) < .07
				if zone.has_point(p) and not wainscot and String(child.name).find("wall") < 0:
					doomed.append(child)
					break
	for node in doomed:
		node.get_parent().remove_child(node)
		node.free()

## The two computer desks (desk, legs, monitor, keyboard, chair) slide back against the rear
## wall; the east planter, where the fourth east bookcase goes, moves between the west desk
## and the help desk.
func _move_computers() -> void:
	var zones := [AABB(Vector3(-19.5, 0, 47.2), Vector3(2.1, 2.0, 2.3)), AABB(Vector3(-12.5, 0, 47.2), Vector3(2.1, 2.0, 2.3))]
	for child in site.get_children():
		if not child is Node3D:
			continue
		for zone in zones:
			if zone.has_point(child.position):
				child.position += COMPUTER_SHIFT
				break
	for title in ["Terracotta planter2", "Planter soil2", "Planter foliage4", "Planter foliage5", "Planter foliage6"]:
		var part := site.get_node_or_null(title) as Node3D
		if part != null:
			part.position += Vector3(-17.0 - -9.9, 0, 52.05 - 50.0)

# ---------------------------------------------------------------- helpers

func mesh_of(title: String, draw: Callable) -> ArrayMesh:
	art.begin()
	draw.call()
	return art.finish(title)

func _group(parent: Node3D, title: String, p := Vector3.ZERO, yaw := 0.0) -> Node3D:
	var node := Node3D.new()
	node.name = title
	parent.add_child(node, true)
	node.position = p
	node.rotation.y = yaw
	return node

## A word root drawn with the mesh kit: the word, the mesh and pick areas (layer 2, like the
## vocabulary prefabs); `picks` lists AABBs, empty = the whole mesh.
func item(parent: Node3D, title: String, word: String, mesh: ArrayMesh, p: Vector3, yaw: float, picks: Array = []) -> Node3D:
	var root := _group(parent, title, p, yaw)
	root.set_meta("word_key", word)
	root.set_meta("learning_object", true)
	var view := MeshInstance3D.new()
	view.name = "Model"
	view.mesh = mesh
	root.add_child(view)
	if picks.is_empty():
		picks = [mesh.get_aabb().grow(.01)]
	for k in picks.size():
		pick_area(root, picks[k], "Interaction" if k == 0 else "Interaction%d" % (k + 1))
	return root

func pick_area(root: Node3D, bounds: AABB, title := "Interaction") -> void:
	var area := Area3D.new()
	area.name = title
	area.collision_layer = 2
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = bounds.size
	shape.shape = cube
	shape.position = bounds.get_center()
	area.add_child(shape)
	root.add_child(area)

## A body that stops the player only (FIGURE_LAYER), so the pointer reaches what is on and in it.
func blocker(root: Node3D, bounds: AABB) -> void:
	var body := StaticBody3D.new()
	body.name = "Blocker"
	body.collision_layer = FIGURE_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = bounds.size
	shape.shape = cube
	shape.position = bounds.get_center()
	body.add_child(shape)
	root.add_child(body)

## A sign Label3D (English source text; sign_language.gd translates it at load) facing -Z.
func label(parent: Node3D, title: String, text: String, p: Vector3, height: float, tint: String) -> Label3D:
	var sign := Label3D.new()
	sign.name = title
	sign.text = text
	sign.font_size = 64
	sign.pixel_size = height / 64.0
	sign.outline_size = 8
	sign.outline_modulate = Color(Color(tint).darkened(.55), .8)
	sign.modulate = Color(CREAM)
	sign.position = p
	sign.rotation.y = PI
	parent.add_child(sign)
	return sign

# ---------------------------------------------------------------- bookcases

## One category bookcase on a side wall. Local frame: origin on the floor at the front centre,
## length along x, front -Z facing the room, back against the wall at +Z = CASE_DEPTH.
func _bookcase(parent: Node3D, category: Array, west: bool, z: float, homes: Array) -> Node3D:
	var id: String = category[0]
	var tint: String = category[2]
	var x: float = WEST + CASE_DEPTH if west else EAST - CASE_DEPTH
	var yaw: float = -PI / 2 if west else PI / 2
	var half := CASE_LEN * .5
	var frame := item(parent, "Bookcase " + id.capitalize(), "bookshelf", _carcass_mesh(id, tint), Vector3(x, F, z), yaw, [
		AABB(Vector3(-half, 0, CASE_DEPTH - .06), Vector3(CASE_LEN, CASE_HEIGHT, .06)),
		AABB(Vector3(-half, CASE_HEIGHT - .06, -.06), Vector3(CASE_LEN, HEADER.y + .14, CASE_DEPTH + .06)),
		AABB(Vector3(-half, 0, 0), Vector3(.06, CASE_HEIGHT, CASE_DEPTH)),
		AABB(Vector3(half - .06, 0, 0), Vector3(.06, CASE_HEIGHT, CASE_DEPTH)),
	])
	frame.set_meta("library_category", id)
	blocker(frame, AABB(Vector3(-half, 0, 0), Vector3(CASE_LEN, CASE_HEIGHT + HEADER.y, CASE_DEPTH)))
	label(frame, category[1] + " sign", category[1], Vector3(-.17, CASE_HEIGHT + .06 + HEADER.y * .5, -.005), .24, tint)
	var gaps := _group(frame, "Gaps")
	for row in TIERS.size():
		_book_row(frame, gaps, id, row, homes)
	return frame

func _carcass_mesh(id: String, tint: String) -> ArrayMesh:
	var half := CASE_LEN * .5
	var face := Vector3(PI / 2, 0, 0)
	return mesh_of("Library bookcase " + id, func() -> void:
		# Back panel, thick rounded sides, plinth and top in the warm toy-like wood.
		art.bx(Vector3(0, CASE_HEIGHT * .5, CASE_DEPTH - .02), Vector3(CASE_LEN - .04, CASE_HEIGHT, .04), CASE_BACK)
		for sx in [-1.0, 1.0]:
			art.bx(Vector3(sx * (half - .05), (CASE_HEIGHT - .05) * .5, CASE_DEPTH * .5), Vector3(.1, CASE_HEIGHT - .05, CASE_DEPTH), CASE_WOOD, Art.SATIN)
			art.cyl(Vector3(sx * (half - .05), CASE_HEIGHT - .05, CASE_DEPTH * .5), Vector3(.1, CASE_DEPTH, .1), CASE_WOOD, Art.SATIN, Vector3(PI / 2, 0, 0), 12)
		art.bx(Vector3(0, .06, CASE_DEPTH * .5 - .01), Vector3(CASE_LEN - .02, .12, CASE_DEPTH - .02), CASE_WOOD_DARK, Art.SATIN)
		art.bx(Vector3(0, CASE_HEIGHT - .05, CASE_DEPTH * .5), Vector3(CASE_LEN - .1, .1, CASE_DEPTH), CASE_WOOD, Art.SATIN)
		# Chunky shelves with a rounded front edge.
		for y in TIERS:
			art.bx(Vector3(0, y - .025, CASE_DEPTH * .5), Vector3(CASE_LEN - .18, .05, CASE_DEPTH - .04), CASE_SHELF, Art.SATIN)
			art.cyl(Vector3(0, y - .025, .0), Vector3(.05, CASE_LEN - .18, .05), CASE_SHELF, Art.SATIN, Vector3(0, 0, PI / 2), 10)
		# Header: a rounded pill in the category colour on a darker rim, with a round bump behind
		# the cream emblem disc on the left (the reference's cloud-topped signs).
		var hy: float = CASE_HEIGHT + .06 + HEADER.y * .5
		var disc := Vector3(HEADER.x * .5 - .3, hy + .04, 0)
		var straight: float = HEADER.x - HEADER.y
		art.bx(Vector3(0, hy, .06), Vector3(straight, HEADER.y + .07, .05), CASE_WOOD_DARK, Art.SATIN)
		art.bx(Vector3(0, hy, .025), Vector3(straight, HEADER.y, .03), tint, Art.SATIN)
		for sx in [-1.0, 1.0]:
			art.cyl(Vector3(sx * straight * .5, hy, .06), Vector3(HEADER.y + .07, .05, HEADER.y + .07), CASE_WOOD_DARK, Art.SATIN, face, 20)
			art.cyl(Vector3(sx * straight * .5, hy, .025), Vector3(HEADER.y, .03, HEADER.y), tint, Art.SATIN, face, 20)
		art.cyl(disc + Vector3(0, 0, .06), Vector3(.64, .05, .64), CASE_WOOD_DARK, Art.SATIN, face, 24)
		art.cyl(disc + Vector3(0, 0, .025), Vector3(.57, .03, .57), tint, Art.SATIN, face, 24)
		art.cyl(disc + Vector3(0, 0, .005), Vector3(.42, .03, .42), CREAM, Art.MATTE, face, 20)
		art.ring(disc + Vector3(0, 0, -.008), Vector3(.44, .025, .44), GOLD, Art.SATIN, face, .88, 20)
		_emblem(id, disc + Vector3(0, 0, -.015)))

## A small 3D picture of the category in front of the header's disc (facing -Z, about .3 wide).
func _emblem(id: String, c: Vector3) -> void:
	var face := Vector3(PI / 2, 0, 0)
	match id:
		"animals":
			var paw := "6b4528"
			art.ball(c + Vector3(0, -.04, -.01), Vector3(.15, .12, .04), paw)
			for k in 4:
				var a: float = deg_to_rad(-60.0 + k * 40.0)
				art.ball(c + Vector3(sin(a) * .1, .03 + cos(a) * .06, -.01), Vector3(.055, .065, .035), paw)
		"sports":
			art.ball(c + Vector3(0, 0, -.01), Vector3(.23, .23, .1), "f7f5ee")
			art.cyl(c + Vector3(0, 0, -.06), Vector3(.07, .01, .07), "2a2a2a", Art.MATTE, face, 5)
			for k in 5:
				var a: float = TAU * k / 5.0
				art.cyl(c + Vector3(sin(a) * .085, cos(a) * .085, -.05), Vector3(.045, .01, .045), "2a2a2a", Art.MATTE, face, 5)
		"art":
			art.ball(c + Vector3(0, -.01, -.01), Vector3(.28, .2, .03), "d9b07a")
			art.ball(c + Vector3(.07, -.05, -.02), Vector3(.045, .04, .02), CREAM)
			var paints := ["d9534a", "f2c231", "3f7fd0", "4e8f3a", "b2437e"]
			for k in paints.size():
				var a: float = deg_to_rad(150.0 - k * 38.0)
				art.ball(c + Vector3(cos(a) * .09 - .02, sin(a) * .055, -.03), Vector3(.04, .035, .02), paints[k])
			art.cyl(c + Vector3(.02, .03, -.04), Vector3(.018, .26, .018), "8a5a2e", Art.MATTE, Vector3(0, 0, -.9), 6)
		"cooking":
			var pot := "c0563b"
			art.cyl(c + Vector3(0, -.03, -.01), Vector3(.2, .13, .08), pot, Art.SATIN, Vector3.ZERO, 14)
			art.bx(c + Vector3(-.125, -.0, -.01), Vector3(.05, .02, .03), "5a5a5a")
			art.bx(c + Vector3(.125, -.0, -.01), Vector3(.05, .02, .03), "5a5a5a")
			art.dome(c + Vector3(0, .035, -.01), Vector3(.21, .06, .085), "d9d9d9", Art.METAL)
			art.ball(c + Vector3(0, .07, -.01), Vector3(.03, .03, .03), "5a5a5a")
			for k in 3:
				art.ball(c + Vector3(-.05 + k * .05, .12 + (k % 2) * .02, -.01), Vector3(.03, .045, .015), "ffffff")
		"travel":
			art.bx(c + Vector3(0, -.03, -.01), Vector3(.28, .09, .06), "d9534a", Art.SATIN)
			art.bx(c + Vector3(-.01, .045, -.01), Vector3(.15, .07, .05), "d9534a", Art.SATIN)
			art.bx(c + Vector3(-.01, .045, -.04), Vector3(.12, .045, .01), "a9d6ee")
			for sx in [-.085, .085]:
				art.cyl(c + Vector3(sx, -.085, -.04), Vector3(.075, .03, .075), "2a2a2a", Art.MATTE, face, 14)
		"music":
			var ink := "4a2a6a"
			art.ball(c + Vector3(-.06, -.07, -.02), Vector3(.085, .06, .04), ink)
			art.ball(c + Vector3(.07, -.05, -.02), Vector3(.085, .06, .04), ink)
			art.bx(c + Vector3(-.02, .0, -.02), Vector3(.018, .15, .02), ink)
			art.bx(c + Vector3(.11, .02, -.02), Vector3(.018, .15, .02), ink)
			art.bx(c + Vector3(.045, .085, -.02), Vector3(.15, .035, .02), ink, Art.MATTE, Vector3(0, 0, .15))
		"food":
			art.ball(c + Vector3(0, -.025, -.01), Vector3(.2, .18, .08), "d9534a")
			art.ball(c + Vector3(-.045, .01, -.05), Vector3(.05, .04, .02), "f08a7a")
			art.bx(c + Vector3(.0, .08, -.02), Vector3(.018, .05, .02), "6b4528")
			art.ball(c + Vector3(.045, .09, -.02), Vector3(.07, .035, .02), "4e8f3a", Art.SATIN, Vector3(0, 0, -.4))
		"vehicles":
			_emblem("travel", c)
		"plants":
			art.cyl(c + Vector3(0, -.08, -.01), Vector3(.13, .08, .1), "c0703a", Art.SATIN, Vector3.ZERO, 12, .8)
			art.bx(c + Vector3(0, -.03, -.01), Vector3(.02, .1, .02), "3f8f3a")
			for k in 3:
				var a: float = deg_to_rad(-40.0 + k * 40.0)
				art.ball(c + Vector3(sin(a) * .07, .03 + cos(a) * .05, -.02), Vector3(.075, .045, .03), "4e9e3a", Art.SATIN, Vector3(0, 0, -a))
		"nature":
			var stem := "4e8f3a"
			art.bx(c + Vector3(0, -.06, -.01), Vector3(.02, .15, .02), stem)
			for k in 5:
				var a: float = TAU * k / 5.0
				art.ball(c + Vector3(sin(a) * .07, .05 + cos(a) * .07, -.02), Vector3(.075, .075, .03), "f08aa8")
			art.ball(c + Vector3(0, .05, -.035), Vector3(.06, .06, .03), "f2c231")

## One shelved book's colour: a shade from its category's family (BOOK_SHADES).
func _book_tint(id: String) -> String:
	var shades: Array = BOOK_SHADES[id]
	return shades[rng.randi_range(0, shades.size() - 1)]

## One shelf of books with random gaps. Books are one word root per shelf ("book"), with a pick
## area over each run of books between gaps. Each gap gets a "Gap <category> <n>" node (on the
## shelf, centred in the gap, spine side -Z) with metas library_category and gap_width; on the
## shelves `homes` name (row), a gap fits that picture book (meta return_book: its root's name).
func _book_row(frame: Node3D, gaps: Node3D, id: String, row: int, homes: Array) -> void:
	var y: float = TIERS[row]
	var room_h: float = (TIERS[row + 1] - TIERS[row] - .045) if row + 1 < TIERS.size() else CASE_HEIGHT - .06 - y - .04
	var start := -CASE_LEN * .5 + .075
	var end := CASE_LEN * .5 - .075
	var thin := Book.THICKNESS_RANGE.x
	var thick := Book.THICKNESS_RANGE.y
	# x: centre, y: width, z: 1 + index in `homes` for a picture book's home gap, else 0.
	var spaces: Array = []
	for k in homes.size():
		if int(homes[k].row) != row:
			continue
		var w: float = float(homes[k].t) + .035
		var placed := false
		for attempt in 200:
			if placed:
				break
			var c := rng.randf_range(-CASE_LEN * .5 + .35, CASE_LEN * .5 - .35)
			var clash := false
			for other in spaces:
				if absf(other.x - c) < (other.y + w) * .5 + .2:
					clash = true
			if not clash:
				spaces.append(Vector3(c, w, 1.0 + k))
				placed = true
		if not placed:
			push_error("library: no home gap for " + str(homes[k].title))
	# One or two random gaps (wider than a book) on most shelves.
	var gap_count := spaces.size() + (0 if rng.randf() < .2 else (1 if rng.randf() < .7 else 2))
	var tries := 0
	while spaces.size() < gap_count and tries < 20:
		tries += 1
		var w := rng.randf_range(thin * 1.2, thick * 1.15)
		var c := rng.randf_range(start + .25 + w * .5, end - .25 - w * .5)
		var clash := false
		for s in spaces:
			if absf(s.x - c) < (s.y + w) * .5 + .3:
				clash = true
		if not clash:
			spaces.append(Vector3(c, w, 0.0))
	spaces.sort_custom(func(a, b): return a.x < b.x)
	var runs: Array = []
	var x := start
	for s in spaces:
		runs.append(Vector2(x, s.x - s.y * .5))
		x = s.x + s.y * .5
	runs.append(Vector2(x, end))
	var state := {"tallest": 0.0}
	var last := {"tint": ""}
	var mesh := mesh_of("Library books " + id, func() -> void:
		for run in runs:
			var bx: float = run.x
			while true:
				var w := rng.randf_range(thin, thick)
				if bx + w > run.y:
					if run.y - bx >= thin * .65:
						w = run.y - bx - .006
					else:
						break
				var h := minf(rng.randf_range(Book.HEIGHT_RANGE.x, Book.HEIGHT_RANGE.y), room_h - .01)
				state.tallest = maxf(state.tallest, h)
				var tint := _book_tint(id)
				while tint == last.tint:
					tint = _book_tint(id)
				last.tint = tint
				Book.draw_plain(art, Vector3(bx + w * .5, y, .008), Vector3(w, h, Book.DEPTH), tint)
				bx += w + .006)
	var picks: Array = []
	for run in runs:
		if run.y - run.x > .03:
			picks.append(AABB(Vector3(run.x, y, .0), Vector3(run.y - run.x, float(state.tallest) + .01, Book.DEPTH + .01)))
	var books := item(frame, "Books %d" % (row + 1), "book", mesh, Vector3.ZERO, 0.0, picks)
	books.set_meta("library_category", id)
	for s in spaces:
		var gap := _gap(gaps, id, Vector3(s.x, y, .008), s.y)
		if s.z > 0:
			var home: Dictionary = homes[int(s.z) - 1]
			gap.set_meta("return_book", "Book " + str(home.title))
			home["gap"] = String(gap.name)

func _gap(gaps: Node3D, id: String, p: Vector3, width: float) -> Node3D:
	var marker := _group(gaps, "Gap %s %d" % [id.capitalize(), gaps.get_child_count() + 1], p)
	marker.set_meta("library_category", id)
	marker.set_meta("gap_width", snappedf(width, .001))
	return marker

# ---------------------------------------------------------------- return shelf and picture books

## The return shelf (the user's "return shelf", 11 Nov 2026; four tiers since 12 Nov 2026): a
## green book-drop cabinet ("Book drop", word "book bin", the 1 Nov returns bin's word, with a
## brass slot) under a four-tier face-out rack ("Return shelf", word "shelf") topped by a RETURNS
## board. The 18 picture books to sort stand on it, six a tier, covers out, in a shuffled order.
## Each is an instance of the reusable book scene (scenes/props/book.tscn, the same size as the
## shelved books) and its own "book" word root "Book <title>" (metas return_book,
## library_category, book_title = the English title, home_gap = its gap's name on the category
## bookcase); book frame: base centre at the origin, cover facing -Z, spine at +X, so a book
## shelved spine-out turns -90 deg about Y.
func _return_shelf(parent: Node3D, plan: Dictionary) -> void:
	var per_tier := 6
	var slot: float = Book.PICTURE.x + .035
	var width: float = per_tier * slot + .11
	var depth := .8
	var zc := .06
	var base := .3
	var top := 2.95
	var lean := .18
	var tier_y := func(k: int) -> float: return base + .03 + k * .59
	var tier_z := func(k: int) -> float: return -.32 + k * .13
	var drop := item(parent, "Book drop", "book bin", mesh_of("Library book drop", func() -> void:
		art.bx(Vector3(0, .03, zc), Vector3(width - .02, .06, depth - .02), WOOD_DARK)
		art.bx(Vector3(0, base * .5 + .03, zc), Vector3(width, base - .06, depth), "2f6b4f", Art.SATIN)
		art.bx(Vector3(0, base, zc), Vector3(width + .04, .03, depth + .04), WOOD)
		var front := zc - depth * .5
		art.bx(Vector3(-.7, .17, front - .004), Vector3(.5, .07, .01), "c9a24a", Art.METAL)
		art.bx(Vector3(-.7, .17, front - .009), Vector3(.42, .022, .006), "1d2a24")
		art.bx(Vector3(.5, .17, front - .003), Vector3(.9, .14, .008), CREAM)), RACK, 0.0)
	label(drop, "RETURNS sign", "RETURNS", Vector3(.5, .17, zc - depth * .5 - .009), .09, "2f6b4f")
	var back: float = float(tier_z.call(3)) + .37
	var rack := item(parent, "Return shelf", "shelf", mesh_of("Library return shelf", func() -> void:
		for sx in [-1.0, 1.0]:
			art.bx(Vector3(sx * (width * .5 - .03), (base + top) * .5, zc), Vector3(.05, top - base, depth - .04), WOOD)
		for k in 4:
			var y: float = tier_y.call(k)
			var z: float = tier_z.call(k)
			art.bx(Vector3(0, y - .015, z + .18), Vector3(width - .1, .03, .36), WOOD)
			art.bx(Vector3(0, y + .02, z + .01), Vector3(width - .1, .06, .02), WOOD_DARK)
			art.bx(Vector3(0, y + .27, z + .375), Vector3(width - .1, .54, .02), "efe6d2")
		# The RETURNS header board between the sides.
		art.bx(Vector3(0, top - .14, back + .02), Vector3(width - .06, .26, .04), "2f6b4f", Art.SATIN)
		art.bx(Vector3(0, top - .255, back - .002), Vector3(width - .06, .025, .01), GOLD, Art.SATIN)), RACK, 0.0, [
		AABB(Vector3(-width * .5, base, zc - depth * .5), Vector3(.06, top - base, depth)),
		AABB(Vector3(width * .5 - .06, base, zc - depth * .5), Vector3(.06, top - base, depth)),
		AABB(Vector3(-width * .5, top - .28, back - .02), Vector3(width, .28, .08)),
	])
	label(rack, "RETURNS header", "RETURNS", Vector3(0, top - .135, back - .005), .15, "2f6b4f")
	blocker(drop, AABB(Vector3(-width * .5, 0, zc - depth * .5), Vector3(width, top, depth)))
	var books := _group(rack, "ReturnBooks")
	var all: Array = []
	for category in CATEGORIES:
		for home in plan[category[0]]:
			all.append([category, home])
	for i in all.size():
		var j := rng.randi_range(i, all.size() - 1)
		var swap: Array = all[i]
		all[i] = all[j]
		all[j] = swap
	for i in all.size():
		var category: Array = all[i][0]
		var home: Dictionary = all[i][1]
		var k := i / per_tier
		var t: float = home.t
		var title: String = home.title
		var book: Node3D = BOOK_SCENE.instantiate()
		book.name = "Book " + title
		book.title = title
		book.size = Vector3(Book.PICTURE.x, Book.PICTURE.y, t)
		book.spine_color = Color(category[2])
		book.set_meta("return_book", true)
		book.set_meta("library_category", category[0])
		book.set_meta("book_title", title)
		book.set_meta("home_gap", str(home.get("gap", "")))
		books.add_child(book)
		# Leaning back on the tier, its front edge behind the lip.
		book.position = Vector3(-width * .5 + .055 + (i % per_tier + .5) * slot, float(tier_y.call(k)) + .002 + t * .5 * sin(lean), float(tier_z.call(k)) + .035 + t * .5)
		book.rotation.x = lean

# ---------------------------------------------------------------- wall prints and Rosa

## Two framed prints (word "painting") on the rear wall above the computer desks, replacing the
## side-wall print now behind a bookcase.
func _prints(parent: Node3D) -> void:
	var scenes := [["5aa0c8", "f2c231", "4e8f3a"], ["e8833a", "2f3f86", "f7f5ee"]]
	for k in 2:
		var colors: Array = scenes[k]
		var mesh := mesh_of("Library print", func() -> void:
			art.bx(Vector3(0, 0, .02), Vector3(1.0, .72, .04), WOOD_DARK)
			art.bx(Vector3(0, 0, .0), Vector3(.88, .6, .01), CREAM)
			art.bx(Vector3(0, .08, -.006), Vector3(.72, .3, .006), colors[0])
			art.bx(Vector3(0, -.13, -.006), Vector3(.72, .16, .006), colors[2])
			art.ball(Vector3(.2, .14, -.01), Vector3(.12, .12, .01), colors[1]))
		item(parent, "Framed print %d" % (k + 1), "painting", mesh, Vector3(-18.5 if k == 0 else -11.5, 2.35, REAR - .045), 0.0)

## Rosa the librarian: the samoyed plush in the librarian outfit, standing in front of the help
## desk beside the return shelf, facing the entrance. Talking to her offers the mission
## (scripts/learning/library_session.gd finds her by name).
func _librarian() -> void:
	var characters = preload("res://scripts/characters/house_characters.gd").new()
	var look := (site.global_basis * Vector3(.25, 0, -1)).normalized()
	characters.worker("res://scenes/characters/samoyed_plush.tscn", "librarian", "dog", site, LIBRARIAN, site.to_global(LIBRARIAN_SPOT), look)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "library")


# =============================================================================================
# return_cart (13 Nov 2026, user request; docs/guides/TOWN_DESIGN_BRIEF.md "Library return cart and
# book-sorting game"): the return shelf becomes the NEW BOOKS display (same rack, books and
# metas; only its header and node name change), and a rolling return cart ("Return cart", word
# "trolley") stands at Rosa's right. The cart is empty in the scene: the sorting game
# (scripts/learning/library_session.gd) puts 3-6 copies of the display's books on its six slots
# ("Return cart/Slots/Slot <n>": tier base points, books lean back CART_LEAN like on the rack).
# =============================================================================================

## Cart centre on the floor (library source frame), front -Z towards the entrance, length along X.
const CART := Vector3(-17.5, F, 49.3)
const CART_LEN := 1.6
const CART_DEPTH := .72
## Two stepped tiers, three face-out books each: shelf height and front edge (z) per tier.
const CART_TIERS := [Vector2(.42, -.2), Vector2(1.0, -.02)]
const CART_LEAN := .18
const CART_GREEN := "2f6b4f"
const CART_METAL := "c3cbd1"

func return_cart(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	var shelves: Node3D = site.get_node_or_null("CategoryShelves") if site != null else null
	if shelves == null:
		push_error("library: category shelves not found")
		return
	art = Art.new()
	var rack := shelves.get_node_or_null("Return shelf")
	if rack != null:
		rack.name = "New books shelf"
		var header := rack.get_node_or_null("RETURNS header") as Label3D
		if header != null:
			header.name = "NEW BOOKS header"
			header.text = "NEW BOOKS"
	_cart(shelves)

## The rolling return cart: a green frame on four casters with a push handle at the east end,
## two stepped wooden tiers with cream backs, and a RETURNS plate on the front apron. Picks on
## the frame only, so a click on a book names the book.
func _cart(parent: Node3D) -> void:
	var half := CART_LEN * .5
	var hd := CART_DEPTH * .5
	var mesh := _cart_mesh(false)
	var cart := item(parent, "Return cart", "trolley", mesh, CART, 0.0, [
		AABB(Vector3(-half, 0, -hd), Vector3(.06, 1.65, CART_DEPTH)),
		AABB(Vector3(half - .06, 0, -hd), Vector3(.25, 1.65, CART_DEPTH)),
		AABB(Vector3(-half, 0, -hd), Vector3(CART_LEN, .4, CART_DEPTH)),
	])
	label(cart, "RETURNS plate", "RETURNS", Vector3(0, .335, -hd + .005), .06, CART_GREEN)
	blocker(cart, AABB(Vector3(-half, 0, -hd), Vector3(CART_LEN + .22, 1.65, CART_DEPTH)))
	var slots := _group(cart, "Slots")
	var slot := Book.PICTURE.x + .04
	var n := 0
	for tier in CART_TIERS:
		for i in 3:
			n += 1
			_group(slots, "Slot %d" % n, Vector3((i - 1) * slot, float(tier.x) + .002, float(tier.y) + .035))

## The cart's look; `open_ends` (step cart_frame): each end is an open frame (corner posts, rails,
## a low kick panel) instead of a solid board, so the books show from the side.
func _cart_mesh(open_ends: bool) -> ArrayMesh:
	var half := CART_LEN * .5
	var hd := CART_DEPTH * .5
	var inner := CART_LEN - .1
	return mesh_of("Library return cart", func() -> void:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var w := Vector3(sx * (half - .14), 0, sz * (hd - .1))
				art.cyl(w + Vector3(0, .075, 0), Vector3(.15, .05, .15), "3a4044", Art.SATIN, Vector3(PI / 2, 0, 0), 14)
				art.cyl(w + Vector3(0, .075, 0), Vector3(.06, .056, .06), CART_METAL, Art.METAL, Vector3(PI / 2, 0, 0), 10)
				art.bx(w + Vector3(0, .17, 0), Vector3(.05, .09, .07), CART_METAL, Art.METAL)
				if open_ends:
					art.bx(Vector3(sx * (half - .03), .95, sz * (hd - .03)), Vector3(.05, 1.4, .05), CART_GREEN, Art.SATIN)
			var ex: float = sx * (half - .03)
			if open_ends:
				art.bx(Vector3(ex, 1.625, 0), Vector3(.05, .05, CART_DEPTH), CART_GREEN, Art.SATIN)
				art.bx(Vector3(ex, .36, 0), Vector3(.045, .22, CART_DEPTH - .06), CART_GREEN, Art.SATIN)
				for tier in CART_TIERS:
					art.bx(Vector3(ex, float(tier.x) + .03, 0), Vector3(.04, .04, CART_DEPTH - .06), CART_GREEN, Art.SATIN)
			else:
				art.bx(Vector3(ex, .95, 0), Vector3(.05, 1.4, CART_DEPTH), CART_GREEN, Art.SATIN)
		art.bx(Vector3(0, .245, 0), Vector3(CART_LEN - .02, .05, CART_DEPTH - .02), CART_GREEN, Art.SATIN)
		# Front apron under the lower tier, with a cream plate for the RETURNS label.
		art.bx(Vector3(0, .335, -hd + .03), Vector3(inner, .13, .03), CART_GREEN, Art.SATIN)
		art.bx(Vector3(0, .335, -hd + .012), Vector3(.62, .085, .01), CREAM)
		for tier in CART_TIERS:
			var y: float = tier.x
			var z: float = tier.y
			art.bx(Vector3(0, y - .015, z + .17), Vector3(inner, .03, .36), WOOD)
			art.bx(Vector3(0, y + .02, z + .005), Vector3(inner, .06, .02), WOOD_DARK)
			art.bx(Vector3(0, y + .3, z + .36), Vector3(inner, .58, .02), "efe6d2")
		# Push handle at the east (+X) end.
		for sz in [-1.0, 1.0]:
			art.bx(Vector3(half + .07, 1.3, sz * .22), Vector3(.14, .035, .035), CART_METAL, Art.METAL)
		art.cyl(Vector3(half + .15, 1.3, 0), Vector3(.05, .52, .05), "3a4044", Art.SATIN, Vector3(PI / 2, 0, 0), 12))

## cart_frame (13 Nov 2026, after the first renders): the cart's ends become open frames, and the
## display's header really reads NEW BOOKS (return_cart changed only the label's text, and the
## bake restores a translated sign from its `sign_source` meta, so it was saved as RETURNS).
func cart_frame(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	var shelves: Node3D = site.get_node_or_null("CategoryShelves") if site != null else null
	if shelves == null:
		push_error("library: category shelves not found")
		return
	art = Art.new()
	var header := shelves.get_node_or_null("New books shelf/NEW BOOKS header") as Label3D
	if header != null:
		header.text = "NEW BOOKS"
		for meta in ["sign_source", "sign_english"]:
			if header.has_meta(meta):
				header.set_meta(meta, "NEW BOOKS")
	var model := shelves.get_node_or_null("Return cart/Model") as MeshInstance3D
	if model != null:
		model.mesh = _cart_mesh(true)

## cart_spot (13 Nov 2026, after the route check): the cart at CART stood in the walk to the west
## computer desk (route (-18.5, 50) -> (-17, 49)); it rolls 1.05 forward to CART_SPOT, front-right
## of Rosa, clear of that route, the rear cross aisle (z 47) and the entrance spine (x -15).
const CART_SPOT := Vector3(-17.5, F, 48.25)

func cart_spot(town: Node3D, _game) -> void:
	var cart := town.get_node_or_null("RelocatedSites/Library/CategoryShelves/Return cart") as Node3D
	if cart == null:
		push_error("library: return cart not found")
		return
	cart.position = CART_SPOT



# =============================================================================================
# new_titles (17 Nov 2026, user; docs/guides/TOWN_DESIGN_BRIEF.md "Library return cart and
# book-sorting game"): the bookcases, drop and NEW BOOKS display are built again from the current
# CATEGORIES and BOOKS (Animals, Sports, Music, Food, Vehicles, Plants; distinct titles so no book
# fits two shelves). Each header becomes its category's word root ("Header <Category>", word from
# CATEGORIES; the bookcase keeps "bookshelf" without the header's pick), and each display book
# carries its topic word (BOOK_WORDS) instead of "book". Every bookcase keeps a home gap that fits
# each of its three picture books, so a full cart can always be shelved.
# =============================================================================================
func new_titles(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	var shelves: Node3D = site.get_node_or_null("CategoryShelves") if site != null else null
	if shelves == null:
		push_error("library: category shelves not found")
		return
	art = Art.new()
	rng.seed = 20261117
	for child in shelves.get_children():
		var title := String(child.name)
		if title.begins_with("Bookcase ") or title in ["Book drop", "Return shelf", "New books shelf"]:
			shelves.remove_child(child)
			child.free()
	_cases_and_returns(shelves)
	var rack := shelves.get_node_or_null("Return shelf")
	if rack != null:
		rack.name = "New books shelf"
		var header := rack.get_node_or_null("RETURNS header") as Label3D
		if header != null:
			header.name = "NEW BOOKS header"
			header.text = "NEW BOOKS"
			for meta in ["sign_source", "sign_english"]:
				header.set_meta(meta, "NEW BOOKS")
		for book in rack.get_node("ReturnBooks").get_children():
			book.set_meta("word_key", BOOK_WORDS[str(book.get_meta("book_title"))])
	for category in CATEGORIES:
		var frame := shelves.get_node_or_null("Bookcase " + String(category[0]).capitalize()) as Node3D
		if frame == null:
			continue
		var pick := frame.get_node_or_null("Interaction2")
		if pick != null:
			frame.remove_child(pick)
			pick.free()
		var head := _group(frame, "Header " + String(category[0]).capitalize())
		head.set_meta("word_key", category[3])
		head.set_meta("learning_object", true)
		pick_area(head, AABB(Vector3(-HEADER.x * .5 - .12, CASE_HEIGHT + .02, -.09), Vector3(HEADER.x + .24, HEADER.y + .16, .2)))
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "library", 6)

# =============================================================================================
# rear_display (17 Nov 2026, user's marked-up top view): the two computer desks at the rear
# corners go (desks, chairs, monitors, keyboards); the NEW BOOKS display (with its book drop)
# moves back against the rear wall at DISPLAY_SPOT, east of the help desk; Rosa and the return
# cart stay beside it (ROSA_SPOT, CART_SPOT_2) with clear walks round them. The east framed print,
# which the display would hide, moves to the west end of the rear wall.
# =============================================================================================
const DISPLAY_SPOT := Vector3(-12.3, F, 51.885)
const ROSA_SPOT := Vector3(-14.5, F, 49.9)
const CART_SPOT_2 := Vector3(-16.9, F, 49.25)
## Where the computer desks and their chairs stood (library source frame, x and z).
const DESK_ZONES := [Rect2(-19.7, 50.1, 2.4, 2.3), Rect2(-12.7, 50.1, 2.4, 2.3)]

func rear_display(town: Node3D, _game) -> void:
	site = town.get_node_or_null("RelocatedSites/Library")
	var shelves: Node3D = site.get_node_or_null("CategoryShelves") if site != null else null
	if shelves == null:
		push_error("library: category shelves not found")
		return
	var doomed: Array = []
	for child in site.get_children():
		if not child is Node3D or child.position.y > 2.0:
			continue
		for zone in DESK_ZONES:
			if zone.has_point(Vector2(child.position.x, child.position.z)):
				doomed.append(child)
				break
	for node in doomed:
		site.remove_child(node)
		node.free()
	var rack := shelves.get_node_or_null("New books shelf") as Node3D
	var drop := shelves.get_node_or_null("Book drop") as Node3D
	if rack == null or drop == null:
		push_error("library: NEW BOOKS display not found")
		return
	var shift := DISPLAY_SPOT - rack.position
	rack.position += shift
	drop.position += shift
	var cart := shelves.get_node_or_null("Return cart") as Node3D
	if cart != null:
		cart.position = CART_SPOT_2
	var rosa := site.get_node_or_null(LIBRARIAN) as Node3D
	if rosa != null:
		rosa.position = ROSA_SPOT
	var print2 := shelves.get_node_or_null("Framed print 2") as Node3D
	if print2 != null:
		print2.position.x = -20.0

# =============================================================================================
# cosy_room (17 Nov 2026, user: the room looked sparse; make it warm, chunky and toy-like like the
# bookcases): a kids' reading corner on a round rug in the STORY CORNER (floor cushions, a floor
# lamp), striped rugs under the two reading tables, the indoor flower patch in a raised wooden
# planter, big potted plants in the rear corners where the desks stood, flag bunting along the rear
# and side walls and a picture poster on the rear wall. Lamps are drawn (pale shades), not lit:
# no extra lights (performance first, web target). Everything is mesh-kit word roots under
# "CosyRoom" with blockers on what stands up.
# =============================================================================================
const RUG_WARM := ["e8a25a", "f3d7a6", "d9784a"]
const CUSHION_TINTS := ["e8687a", "f2c231", "5aa0c8", "7cc35a"]

func cosy_room(town: Node3D, game) -> void:
	g = game
	site = town.get_node_or_null("RelocatedSites/Library")
	if site == null:
		push_error("library: site not found")
		return
	art = Art.new()
	var room := _group(site, "CosyRoom")
	# Reading corner (front east, the STORY CORNER): round rug, floor cushions, floor lamp, plant.
	var corner := Vector3(-11.3, F, 40.1)
	item(room, "Reading corner rug", "rug", mesh_of("Library round rug", func() -> void:
		art.cyl(Vector3(0, .006, 0), Vector3(2.9, .012, 2.9), "d9784a", Art.MATTE, Vector3.ZERO, 32)
		art.cyl(Vector3(0, .012, 0), Vector3(2.6, .012, 2.6), "f3d7a6", Art.MATTE, Vector3.ZERO, 32)
		art.ring(Vector3(0, .02, 0), Vector3(1.9, .006, 1.9), "e8a25a", Art.MATTE, Vector3.ZERO, .82, 32)
		art.cyl(Vector3(0, .02, 0), Vector3(.9, .006, .9), "f2c231", Art.MATTE, Vector3.ZERO, 24)), corner, 0.0,
		[AABB(Vector3(-1.45, 0, -1.45), Vector3(2.9, .04, 2.9))])
	var spots := [Vector3(-11.3, F, 39.05), Vector3(-12.5, F, 41.05), Vector3(-10.05, F, 39.55), Vector3(-11.15, F, 41.35)]
	for k in spots.size():
		var tint: String = CUSHION_TINTS[k]
		var cushion := item(room, "Floor cushion %d" % (k + 1), "cushion", mesh_of("Library floor cushion " + tint, func() -> void:
			art.ball(Vector3(0, .15, 0), Vector3(.7, .3, .7), tint, Art.SATIN, Vector3.ZERO, 16)
			art.ball(Vector3(0, .29, 0), Vector3(.14, .04, .14), art.darker(tint), Art.SATIN, Vector3.ZERO, 10)), spots[k], k * .7)
		blocker(cushion, AABB(Vector3(-.3, 0, -.3), Vector3(.6, .3, .6)))
	_floor_lamp(room, "Reading corner lamp", Vector3(-9.75, F, 41.95))
	_big_plant(room, "Reading corner plant", Vector3(-9.75, F, 38.3), .8)
	# Striped rugs under the reading tables.
	for k in 2:
		var x: float = -18.0 if k == 0 else -12.0
		var tints: Array = [["5aa0c8", "a9d6ee", "f3ead6"], ["d4572a", "f0b87a", "f3ead6"]][k]
		item(room, "Reading table rug %d" % (k + 1), "rug", mesh_of("Library table rug %d" % k, func() -> void:
			art.bx(Vector3(0, .006, 0), Vector3(2.7, .012, 3.9), tints[0])
			for j in 5:
				art.bx(Vector3(0, .013, -1.6 + j * .8), Vector3(2.45, .006, .4), tints[1 + j % 2])
			for sx in [-1.0, 1.0]:
				for j in 9:
					art.ball(Vector3(sx * 1.38, .01, -1.8 + j * .45), Vector3(.06, .02, .12), tints[0], Art.MATTE, Vector3.ZERO, 6)), Vector3(x, F, 44.5), 0.0,
			[AABB(Vector3(-1.35, 0, -1.95), Vector3(2.7, .03, 3.9))])
	# The indoor flower patch in a raised wooden planter (the blossoms rise with it).
	var bed := site.get_node_or_null("Flower bed3") as Node3D
	var planter_at := Vector3(-17.92, F, 39.22)
	if bed != null:
		site.remove_child(bed)
		bed.free()
	for child in site.get_children():
		if child is Node3D and String(child.name).begins_with("Flower blossom") and absf(child.position.z - 39.2) < .4 and child.position.x < -16.5:
			child.position.y += .42
	var planter := item(room, "Flower planter", "planter", mesh_of("Library flower planter", func() -> void:
		art.bx(Vector3(0, .2, 0), Vector3(1.85, .4, .6), CASE_WOOD, Art.SATIN)
		art.bx(Vector3(0, .41, 0), Vector3(1.95, .05, .7), CASE_SHELF, Art.SATIN)
		art.bx(Vector3(0, .425, 0), Vector3(1.75, .03, .5), "6b4a2b")
		for k in 7:
			art.ball(Vector3(-.78 + k * .26, .47, (k % 2) * .12 - .06), Vector3(.22, .1, .16), "58b24a", Art.SATIN, Vector3.ZERO, 8)), planter_at, 0.0,
		[AABB(Vector3(-.98, 0, -.35), Vector3(1.96, .45, .7))])
	blocker(planter, AABB(Vector3(-.98, 0, -.35), Vector3(1.96, .6, .7)))
	# Big potted plants in the rear corners, a floor lamp beside the west one.
	_big_plant(room, "Rear corner plant", Vector3(-20.15, F, 51.65), 1.2)
	_big_plant(room, "Rear east plant", Vector3(-10.05, F, 51.75), 1.0)
	_floor_lamp(room, "Rear corner lamp", Vector3(-19.1, F, 51.85))
	# Bunting along the rear wall (above the clock) and the two side walls (above the bookcases).
	_bunting(room, "Rear bunting", Vector3(-20.6, 4.85, REAR - .06), Vector3(-9.4, 4.85, REAR - .06), .3)
	_bunting(room, "West bunting", Vector3(WEST + .06, 4.35, 38.4), Vector3(WEST + .06, 4.35, 51.8), .35)
	_bunting(room, "East bunting", Vector3(EAST - .06, 4.35, 38.4), Vector3(EAST - .06, 4.35, 51.8), .35)
	# A picture poster on the rear wall (an open book with stars: no text to translate).
	item(room, "Reading poster", "poster", mesh_of("Library reading poster", func() -> void:
		art.bx(Vector3(0, 0, .01), Vector3(.82, 1.0, .02), "2f6b4f", Art.SATIN)
		art.bx(Vector3(0, 0, -.002), Vector3(.72, .9, .01), "fdf3dc")
		art.bx(Vector3(0, .2, -.009), Vector3(.62, .42, .006), "a9d6ee")
		for sx in [-1.0, 1.0]:
			art.bx(Vector3(sx * .15, -.12, -.012), Vector3(.28, .2, .01), "f6efdf", Art.MATTE, Vector3(0, 0, sx * -.18))
			art.bx(Vector3(sx * .15, -.12, -.008), Vector3(.3, .22, .006), "d9534a", Art.MATTE, Vector3(0, 0, sx * -.18))
		for st in [Vector3(-.18, .28, .07), Vector3(.05, .34, .09), Vector3(.2, .2, .06), Vector3(-.03, .12, .05)]:
			art.cyl(Vector3(st.x, st.y, -.016), Vector3(st.z, .006, st.z), "f2c231", Art.MATTE, Vector3(PI / 2, 0, 0), 5)), Vector3(-17.0, 2.5, REAR - .03), 0.0)

## A tall potted plant: a chunky terracotta pot and a round bush of leaves, `h` metres high.
func _big_plant(parent: Node3D, title: String, p: Vector3, h: float) -> void:
	var pot := item(parent, title + " pot", "flowerpot", mesh_of("Library big pot", func() -> void:
		art.cyl(Vector3(0, .22, 0), Vector3(.52, .44, .52), "c0703a", Art.SATIN, Vector3.ZERO, 16, .8)
		art.cyl(Vector3(0, .45, 0), Vector3(.56, .06, .56), "d9824a", Art.SATIN, Vector3.ZERO, 16)
		art.cyl(Vector3(0, .47, 0), Vector3(.46, .02, .46), "6b4a2b", Art.MATTE, Vector3.ZERO, 12)), p, 0.0)
	blocker(pot, AABB(Vector3(-.3, 0, -.3), Vector3(.6, h, .6)))
	item(parent, title, "plant", mesh_of("Library big plant %.1f" % h, func() -> void:
		art.cyl(Vector3(0, .45 + (h - .5) * .3, 0), Vector3(.05, (h - .5) * .6, .05), "6b4a2b", Art.MATTE, Vector3.ZERO, 6)
		for k in 7:
			var a := TAU * k / 7.0
			var r := .18 if k % 2 == 0 else .12
			art.ball(Vector3(sin(a) * r, h - .25 + (k % 3) * .08, cos(a) * r), Vector3(.34, .28, .34), "4e9e3a" if k % 2 else "6ab04a", Art.SATIN, Vector3.ZERO, 10)
		art.ball(Vector3(0, h - .08, 0), Vector3(.36, .3, .36), "58b24a", Art.SATIN, Vector3.ZERO, 10)), p, .4)

## A chunky floor lamp with a pale warm shade (drawn only; it adds no light).
func _floor_lamp(parent: Node3D, title: String, p: Vector3) -> void:
	var lamp := item(parent, title, "floor lamp", mesh_of("Library floor lamp", func() -> void:
		art.cyl(Vector3(0, .03, 0), Vector3(.42, .06, .42), CASE_WOOD_DARK, Art.SATIN, Vector3.ZERO, 16)
		art.cyl(Vector3(0, .8, 0), Vector3(.06, 1.5, .06), CASE_WOOD, Art.SATIN, Vector3.ZERO, 8)
		art.cyl(Vector3(0, 1.62, 0), Vector3(.5, .36, .5), "fff1cf", Art.MATTE, Vector3.ZERO, 16, .62)
		art.ring(Vector3(0, 1.45, 0), Vector3(.52, .03, .52), GOLD, Art.SATIN, Vector3.ZERO, .9, 16)), p, 0.0)
	blocker(lamp, AABB(Vector3(-.22, 0, -.22), Vector3(.44, 1.8, .44)))

## A string of triangular felt flags sagging from `a` to `b` (`sag` metres at the middle).
func _bunting(parent: Node3D, title: String, a: Vector3, b: Vector3, sag: float) -> void:
	var length := a.distance_to(b)
	var count := int(length / .42)
	var dir := (b - a).normalized()
	var yaw := atan2(-dir.z, dir.x)
	var tints := ["e8687a", "f2c231", "5aa0c8", "7cc35a", "d9784a"]
	var mesh := mesh_of(title, func() -> void:
		for k in count + 1:
			var t := float(k) / count
			var x := (t - .5) * length
			var y := -sag * 4.0 * t * (1.0 - t)
			if k < count:
				var t2 := float(k + 1) / count
				var y2 := -sag * 4.0 * t2 * (1.0 - t2)
				art.bx(Vector3(x + length / count * .5, (y + y2) * .5, 0), Vector3(length / count + .01, .012, .012), "8a5a2e", Art.MATTE, Vector3(0, 0, atan2(y2 - y, length / count)))
				art.prism(Vector3(x + length / count * .5, (y + y2) * .5 - .13, 0), Vector3(.26, .24, .01), tints[k % tints.size()], Art.MATTE, Vector3(0, 0, PI)))
	item(parent, title, "flag", mesh, (a + b) * .5, yaw)
