extends SceneTree
## Product gallery for the clay-toy rework and size rule (18 Nov 2026): every grocery kind and
## variant at its displayed size on a plain floor, before and after, then close-ups of mock product
## groups restocked by each library's own restock() (real pick-box sizes from the market).
## Graphics required; isolated HOME (writes nothing outside this folder):
##   git show HEAD:BonAdventure/scripts/buildings/supermarket_products.gd > <scratch>/before.gd
##   HOME=<scratch>/home godot --path . --resolution 1280x800 --script res://docs/evidence/supermarket-products-20261118/gallery.gd -- <scratch>/before.gd
## Without the argument only the "after" images are drawn. Writes <before|after>-<page>.png and
## <before|after>-close-<n>.png here. Each overview cell has a dark floor square the size of the
## old coconut (.29 market units); the post at the left is the player's height (2.24 m / 1.3).
const Products = preload("res://scripts/buildings/supermarket_products.gd")
const OUT := "res://docs/evidence/supermarket-products-20261118/"
const OLD_COCONUT := .29
const PLAYER := 2.24 / 1.3
const PAGES := {
	"fruit": ["apple", "orange", "lemon", "lime", "pear", "peach", "cherry", "strawberry", "grapes", "banana", "pineapple", "mango", "coconut", "watermelon", "avocado"],
	"vegetables": ["tomato", "carrot", "broccoli", "potato", "lettuce", "onion", "garlic", "corn", "chili pepper", "mushroom", "cucumber", "bell pepper"],
	"pantry": ["cereal", "rice", "beans", "flour", "sugar", "pasta", "tortilla", "oil", "salt", "pepper", "honey", "jam", "salsa", "olive", "jar", "can", "tuna", "soup"],
	"snacks-drinks": ["cookie", "cracker", "snack", "chocolate", "candy", "tea", "coffee", "water bottle", "juice", "soda", "coconut"],
	"fresh": ["milk", "yogurt", "butter", "cheese", "eggs", "salad", "ham", "sausage", "chicken", "meat", "steak", "fish", "shrimp", "coconut"],
	"bakery-home": ["bread", "baguette", "croissant", "cake", "cupcake", "donut", "soap", "sponge", "detergent", "toothbrush", "toothpaste", "shampoo", "toilet paper", "coconut"],
}
## Close-ups: [kind, pick width, height, depth, pad] as in the baked market (widths capped).
const CLOSE := [
	[["ham", 1.1, .09, .6, 0.0], ["sausage", 1.1, .1, .6, 0.0], ["chicken", 1.1, .11, .6, 0.0]],
	[["meat", 1.1, .08, .6, 0.0], ["steak", 1.1, .07, .6, 0.0], ["fish", 1.3, .11, .6, 0.0]],
	[["shrimp", 1.3, .17, .6, 0.0], ["eggs", 1.36, .13, .7, .25], ["yogurt", 1.36, .13, .7, .25]],
	[["butter", 1.36, .08, .7, .25], ["cheese", 1.36, .12, .7, .25], ["cake", 1.4, .2, .6, 0.0]],
	[["bread", 1.4, .18, .4, 0.0], ["croissant", 1.4, .1, .6, 0.0], ["donut", 1.4, .1, .6, 0.0]],
	[["cupcake", 1.4, .15, .6, 0.0], ["candy", 1.4, .19, .42, 0.0], ["chocolate", 1.4, .22, .42, 0.0]],
	[["cookie", 1.4, .08, .42, 0.0], ["cracker", 1.4, .32, .42, 0.0], ["soap", 1.39, .08, .42, 0.0]],
	[["sponge", 1.39, .1, .42, 0.0], ["toothbrush", 1.39, .28, .42, 0.0], ["toothpaste", 1.39, .09, .42, 0.0]],
	[["shampoo", 1.39, .32, .42, 0.0], ["detergent", 1.39, .36, .42, 0.0], ["toilet paper", 1.0, .18, .4, 0.0]],
	[["cherry", 1.4, .27, .5, 0.0], ["strawberry", 1.4, .3, .5, 0.0], ["garlic", .92, .33, .86, 0.0]],
	[["lime", 1.4, .33, .5, 0.0], ["mushroom", .92, .27, .86, 0.0], ["chili pepper", .92, .11, .86, 0.0]],
]

var camera: Camera3D
var world: Node3D

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("gallery.gd needs graphics")
		quit(1)
		return
	var libraries := {"after": Products.new()}
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var script := GDScript.new()
		script.source_code = FileAccess.get_file_as_string(args[0])
		if script.reload() == OK:
			libraries = {"before": script.new(), "after": libraries["after"]}
	_stage()
	for label in libraries:
		var products = libraries[label]
		for page in PAGES:
			var holder := _overview(products, PAGES[page])
			await _shoot("%s%s-%s.png" % [OUT, label, page])
			holder.free()
		for n in CLOSE.size():
			var holder := _close(products, CLOSE[n])
			await _shoot("%s%s-close-%d.png" % [OUT, label, n + 1])
			holder.free()
	quit()

func _stage() -> void:
	world = Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("e9e3d3")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff4df")
	environment.environment.ambient_light_energy = .45
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-1.0, -.5, 0)
	sun.light_energy = .75
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(60, 60)
	floor_mesh.material_override = _flat("e9e3d3")
	world.add_child(floor_mesh)
	camera = Camera3D.new()
	camera.fov = 40
	world.add_child(camera)
	camera.current = true

func _flat(tint: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint)
	material.roughness = .9
	return material

func _label(parent: Node3D, text: String, at: Vector3, size := 40) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = .0022
	label.modulate = Color("293e40")
	label.outline_size = 0
	label.rotation = Vector3(0, PI, 0)
	label.position = at
	parent.add_child(label)

func _box(parent: Node3D, size: Vector3, at: Vector3, tint: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = size
	mesh.material_override = _flat(tint)
	mesh.position = at
	parent.add_child(mesh)

## Every variant of each kind at its displayed size, six cells to a row, front toward the camera.
func _overview(products, kinds: Array) -> Node3D:
	var holder := Node3D.new()
	world.add_child(holder)
	var columns := 6
	var pitch := 1.0
	for k in kinds.size():
		var kind: String = kinds[k]
		var cell := Vector3(-(k % columns - (columns - 1) * .5) * pitch, 0, -(k / columns) * pitch)
		_box(holder, Vector3(OLD_COCONUT, .004, OLD_COCONUT), cell + Vector3(0, .002, 0), "a8977a")
		var count: int = products.variants(kind)
		var grow: float = products.goods_scale(kind)
		var widest := 0.0
		for v in count:
			widest = maxf(widest, products.model(kind, v).get_aabb().size.x * grow)
		var gap := minf(widest + .03, .9 / count) if count > 1 else 0.0
		for v in count:
			var unit := MeshInstance3D.new()
			unit.mesh = products.model(kind, v)
			unit.transform = Transform3D(Basis.from_scale(Vector3.ONE * grow), cell + Vector3(-(v - (count - 1) * .5) * gap, .004, 0))
			holder.add_child(unit)
		var size: Vector3 = products.model(kind, 0).get_aabb().size * grow
		_label(holder, "%s  %.2f" % [kind, maxf(size.x, maxf(size.y, size.z))], cell + Vector3(0, .03, -.33))
	var rows := ceili(kinds.size() / float(columns))
	# The player's height beside the first row.
	var post := Vector3((columns * .5 + .1) * pitch, 0, -(rows - 1) * pitch)
	_box(holder, Vector3(.06, PLAYER, .06), post + Vector3(0, PLAYER * .5, 0), "5e9a4f")
	_box(holder, Vector3(.3, .02, .06), post + Vector3(0, PLAYER, 0), "5e9a4f")
	_label(holder, "player", post + Vector3(0, .03, -.2), 32)
	var centre := Vector3(.3, 0, -(rows - 1) * pitch * .5)
	camera.fov = 38
	camera.position = centre + Vector3(0, 3.1 + rows * .25, -4.5 - rows * .3)
	camera.look_at(centre + Vector3(0, .3, .2))
	return holder

## Mock product groups (a root with word_key and one pick Area3D) on counters, restocked by the
## library's own restock(); the pick boxes are drawn as thin outlines on the counter top.
func _close(products, groups: Array) -> Node3D:
	var holder := Node3D.new()
	world.add_child(holder)
	var total := 0.0
	for spec in groups:
		total += float(spec[1]) + .3
	var x := total * .5
	for spec in groups:
		var w: float = minf(spec[1], 1.15)
		var h: float = spec[2]
		var d: float = spec[3]
		var pad: float = spec[4]
		var centre := Vector3(x - w * .5 - .15, .8, (d + pad) * .5)
		x -= w + .3
		_box(holder, Vector3(w + .12, .8, d + pad + .12), Vector3(centre.x, .4, centre.z), "b9c4c6")
		var group := Node3D.new()
		group.name = "%s display" % str(spec[0]).capitalize()
		group.set_meta("word_key", spec[0])
		group.position = centre + Vector3(0, 0, -pad * .5)
		var area := Area3D.new()
		area.position = Vector3(0, 0, pad * .5)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(w + .02, h + .02, d + .02 + pad)
		shape.shape = box
		shape.position = Vector3(0, (h + .02) * .5, 0)
		area.add_child(shape)
		group.add_child(area)
		holder.add_child(group)
		var units: int = products.restock(group)
		var grown: Vector3 = (shape.shape as BoxShape3D).size
		# Pick box outline (front and back edges) and the kind, units and box height.
		for z in [-grown.z * .5, grown.z * .5]:
			_box(holder, Vector3(grown.x, .006, .01), group.position + Vector3(0, .003, pad * .5 + z), "e8b04b")
		_label(holder, "%s  x%d  pick h %.2f" % [spec[0], units, grown.y - .02], Vector3(centre.x, .7, -.07), 34)
	camera.fov = 45
	camera.position = Vector3(0, 2.15, -.45 - total * .42)
	camera.look_at(Vector3(0, .78, .38))
	return holder

func _shoot(path: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("GALLERY wrote ", path)
