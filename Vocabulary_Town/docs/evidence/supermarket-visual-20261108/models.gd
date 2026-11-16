extends SceneTree
## Product model sheet (8 Nov 2026): every grocery kind and variant from
## scripts/buildings/supermarket_products.gd on a plain floor, without loading the town.
## godot --path . --resolution 1400x900 --script res://docs/evidence/supermarket-visual-20261108/models.gd
## Writes models-<page>.png into this folder only. Graphics required.
const Products = preload("res://scripts/buildings/supermarket_products.gd")
const PAGES := {
	"fruit": ["apple", "orange", "lemon", "lime", "pear", "peach", "cherry", "strawberry", "grapes", "banana", "pineapple", "mango", "coconut", "watermelon", "avocado"],
	"vegetables": ["tomato", "carrot", "broccoli", "potato", "lettuce", "onion", "garlic", "corn", "chili pepper", "mushroom", "cucumber", "bell pepper"],
	"pantry": ["cereal", "rice", "beans", "flour", "sugar", "pasta", "tortilla", "oil", "salt", "pepper", "honey", "jam", "salsa", "olive", "jar", "can", "tuna", "soup", "coffee", "tea", "cookie", "snack"],
	"fresh": ["milk", "yogurt", "butter", "cheese", "eggs", "ham", "sausage", "salad", "chicken", "meat", "steak", "fish", "shrimp", "bread", "baguette", "croissant", "cake", "cupcake", "donut"],
	"drinks-home": ["water bottle", "soda", "juice", "soap", "sponge", "detergent", "toothbrush", "toothpaste", "shampoo", "toilet paper", "chocolate", "candy"],
}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var products := Products.new()
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("e9e3d3")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff4df")
	environment.environment.ambient_light_energy = .55
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-1.0, -.5, 0)
	sun.light_energy = .9
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(40, 40)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("e9e3d3")
	floor_mesh.material_override = floor_material
	world.add_child(floor_mesh)
	var camera := Camera3D.new()
	camera.fov = 40
	world.add_child(camera)
	camera.current = true
	for page in PAGES:
		var holder := Node3D.new()
		world.add_child(holder)
		var kinds: Array = PAGES[page]
		var columns := 6
		for k in kinds.size():
			var kind: String = kinds[k]
			var cell := Vector3((k % columns - (columns - 1) * .5) * .9, 0, (k / columns) * .9)
			var count := products.variants(kind)
			for v in count:
				var unit := MeshInstance3D.new()
				unit.mesh = products.model(kind, v)
				var grow := products.goods_scale(kind)
				unit.transform = Transform3D(Basis.from_scale(Vector3.ONE * grow), cell + Vector3((v - (count - 1) * .5) * minf(.75 / count, .3), 0, 0))
				holder.add_child(unit)
			var label := Label3D.new()
			label.text = "%s (%d)" % [kind, count]
			label.font_size = 40
			label.pixel_size = .0022
			label.modulate = Color("293e40")
			label.outline_size = 0
			label.rotation.y = PI
			label.position = cell + Vector3(0, .02, -.33)
			label.rotation.x = 0
			holder.add_child(label)
		var rows := ceili(kinds.size() / float(columns))
		var centre := Vector3(0, 0, (rows - 1) * .45)
		camera.position = centre + Vector3(0, 1.0 + rows * .32, -1.1 - rows * .42)
		camera.look_at(centre + Vector3(0, .1, 0))
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/supermarket-visual-20261108/models-%s.png" % page)
		holder.free()
	print("MODEL SHEET done")
	quit()
