extends RefCounted
## Bakery / Café own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## bakery unit (scenes/town/bakery.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- bakery
## Never rename or remove a baked step (add a new one that undoes it).
## Record: docs/guides/TOWN_DESIGN_BRIEF.md "Supermarket product art — 8 November 2026" (reuse).
const STEPS := ["shop_products", "coplanar_gaps", "coplanar_gaps_2", "glass_windows"]
const Products = preload("res://scripts/buildings/supermarket_products.gd")
const INTERIOR := "Buildings/BakeryCafe/Interior"
## Plain bottles in the drinks fridge by colour, and the three drink words, as product models.
const DRINKS := {"f5f5f2": ["milk", 0], "f29a4b": ["juice", 0], "9fd17a": ["juice", 1], "f7d36b": ["soda", 1], "f2a2ae": ["soda", 0]}
const WORD_DRINKS := {"milk": ["milk", 0], "juice": ["juice", 1], "water": ["water bottle", 0]}

## The supermarket's product models (supermarket_products.gd) reused in the café (8 Nov 2026):
## the 20 plain cylinder drinks in the fridge (interior x 5.15..5.95, z 10.1) become milk,
## juice, soda and water bottles, and the three ball loaves on the bread rack's bottom shelf
## (x 3.47..4.31, shelf top y .40) become loaves. Only meshes change: every node, word root,
## pick area and position is kept (the shared vocabulary prefabs are not touched).
func shop_products(town: Node3D, _game) -> void:
	var interior: Node3D = town.get_node(INTERIOR)
	var products := Products.new()
	var drinks := 0
	var loaves := 0
	for holder in interior.get_children():
		if not holder is Node3D:
			continue
		for child in holder.get_children():
			var mesh := child as MeshInstance3D
			if mesh == null or not mesh.material_override is BaseMaterial3D:
				continue
			var tint := (mesh.material_override as BaseMaterial3D).albedo_color.to_html(false)
			var at: Vector3 = (holder as Node3D).transform * mesh.position
			if mesh.mesh is CylinderMesh and absf(at.x - 5.55) < .5 and absf(at.z - 10.1) < .1 \
					and is_equal_approx((mesh.mesh as CylinderMesh).height, .22):
				var spec = WORD_DRINKS.get(str(holder.get_meta("word_key", "")), DRINKS.get(tint))
				if spec == null:
					continue
				mesh.mesh = products.model(spec[0], spec[1])
				mesh.material_override = null
				mesh.position.y -= .11
				drinks += 1
			elif mesh.mesh is SphereMesh and tint == "c98a45" and absf(at.x - 3.89) < .5 \
					and absf(at.z - 10.56) < .1 and absf(at.y - .5) < .05:
				mesh.mesh = products.model("bread", loaves % 3)
				mesh.material_override = null
				mesh.basis = Basis(Vector3.UP, PI / 2).scaled(Vector3.ONE * 2.2)
				mesh.position.y -= at.y - .40
				loaves += 1
	print("BAKERY shop_products: %d drinks, %d loaves" % [drinks, loaves])

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "bakery")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "bakery", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "bakery")
