extends RefCounted
## Base world own script (docs/guides/MODULAR_TOWN.md, "Changing the base world"): code steps for
## everything that is not a building unit, saved in scenes/town/base.scn: ground, roads,
## garden, zoo, trees, vehicles, coast, street furniture, and the layout data on the base
## (game.reference_layout: sites, site_bounds, roads, entries, details, spawn_point).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- base
##   const STEPS := ["add_bench", ...]          # applied in this order, each exactly once
##   func add_bench(town: Node3D, game) -> void # town = Main's Apartment, scale 1.3, town coords
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["solid_roofs", "remove_bird", "tulip_beds", "plaza_fountains", "bronze_statue", "statue_blueprint", "statue_traced", "statue_traced_refit", "statue_reference", "statue_reference_finish", "statue_angular_portrait", "statue_temple_hair", "statue_hair_relief_fit", "statue_single_bronze", "bench_placement", "statue_patina", "statue_patina_warm", "toy_scooter", "toy_scooter_full_size", "statue_town_bronze", "mystery_house_site", "coplanar_gaps", "coplanar_gaps_2", "lion_blueprint_display", "lion_clay_display", "lion_clay_face_rework", "lion_clay_ears_fit", "lion_clay_eyes_mane", "lion_clay_ears_mane_two_layers", "giraffe_clay_display", "giraffe_clay_colours", "giraffe_clay_refine", "elephant_clay_display", "red_panda_clay_display", "elephant_clay_colours", "panda_clay_display", "cow_clay_display", "gorilla_clay_display", "panda_clay_face", "gorilla_clay_refine", "cow_clay_colours_eyes", "deer_clay_display", "cow_clay_muzzle", "gorilla_clay_eyelids", "deer_clay_eyes_ears", "cow_clay_lower_lip", "cow_clay_muzzle_reverted", "kangaroo_clay_display", "lion_clay_second_pass", "lion_crawl_display", "lion_crawl_colours", "lion_mix_display", "lion_temp_marks", "lion_temp_marks_lower", "rhino_clay_display", "zebra_clay_display", "lion_clay_roams", "lion_designs_removed", "black_bear_clay_display", "black_bear_clay_front_row", "black_bear_clay_soles", "flamingo_clay_display", "flamingo_clay_colours", "black_bear_cub_beside_bear", "black_bear_cub_clear_of_zebra", "flamingo_clay_back_feathers", "black_bear_cub_body", "golden_retriever_clay_display", "black_bear_cub_body_reverted", "black_bear_adult_clay_display", "black_bears_front_row_pair", "black_bear_cub_baby", "black_bear_cub_young_face", "golden_retriever_clay_coat", "duck_clay_display", "black_bear_cub_lighter_fur", "pig_clay_display", "clay_animals_roam", "clay_animals_spacing", "animals_bigger", "zoo_zones", "chapel_old_outline", "home_expansion_ground", "home_side_pad_trim", "statue_word", "clay_animals_unpacked", "parked_vehicles", "warehouse_entrance_walk", "spawn_clear_car", "clay_meshes_external", "pig_clay_walks", "clay_animals_walk", "rooster_clay_display", "capybara_clay_display", "tiger_clay_walks", "monkey_clay_display", "horse_clay_walks", "capybara_clay_walks", "chick_clay_display", "tutorial_lot_clear", "fish_under_water", "zoo_plaza_benches_removed", "zoo_welcome_sign_removed", "zoo_food_booth", "hen_clay_display", "zoo_food_booth_sign_fit"]
const Plaza = preload("res://scripts/buildings/monument_plaza.gd")

## Collision for the decorative gazebo roof cap (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, ["Map facades/GAZEBO/Faceted roof cap"])

## The word "bird" was removed from the game (user request, 8 Nov 2026): the zoo's bird goes
## with its word entry, model scene and grammar example.
func remove_bird(town: Node3D, _game) -> void:
	var bird := town.get_node_or_null("ParkZoo/Bird")
	if bird:
		bird.get_parent().remove_child(bird)
		bird.free()

## Washington monument plaza art (user reference image, 8 Nov 2026; scripts/buildings/
## monument_plaza.gd): raised tulip lens beds and tulip borders replace the ball flowers and
## tropical crowns; stone baluster fountains with a bowl, spilling streams and a bronze child
## with a bird; a smooth bronze horse and rider with pedestal panel mouldings.
func tulip_beds(town: Node3D, _game) -> void:
	Plaza.tulip_beds(town)

func plaza_fountains(town: Node3D, _game) -> void:
	Plaza.plaza_fountains(town)

func bronze_statue(town: Node3D, _game) -> void:
	Plaza.bronze_statue(town)

## Washington statue to the user's "Character Blueprint" (8 Nov 2026; monument_plaza.gd):
## chunky olive-bronze horse and rider with gilt trim on a bronze plate, cream stone pedestal.
func statue_blueprint(town: Node3D, _game) -> void:
	Plaza.statue_blueprint(town)

## Second pass on the blueprint (8 Nov 2026, user: "does not look like it"): the statue is
## re-traced from the blueprint's side view (rider, head carriage, proportions) and stands on a
## wide stone cap; replaces the `statue_blueprint` figure.
func statue_traced(town: Node3D, _game) -> void:
	Plaza.statue_traced(town)

## Traced statue touch-up (8 Nov 2026): shorter horse ears so the rider's face shows, a smooth
## chest, softer bronze sheen. Rebuilds only the bronze mesh.
func statue_traced_refit(town: Node3D, _game) -> void:
	Plaza.traced_bronze(town.get_node("WashingtonStatue"))

## Refine the bronze and pedestal from the sculptural portrait supplied 8 November 2026.
func statue_reference(town: Node3D, _game) -> void:
	Plaza.statue_reference(town)

## Floating park signs removed (user request, 8 Nov 2026): the two bare sign posts and the green
## "Central Park sign" board beside the lake path.
func remove_park_signs(town: Node3D, _game) -> void:
	for sign_name in ["Park sign post", "Park sign post2", "Central Park sign"]:
		var node := town.get_node_or_null(sign_name)
		if node:
			node.get_parent().remove_child(node)
			node.free()

## Render follow-up: seat the facial relief and expose the corner pilasters.
func statue_reference_finish(town: Node3D, _game) -> void:
	Plaza.statue_reference(town)

## User follow-up: angular head and textured wig curls, 8 November 2026.
func statue_angular_portrait(town: Node3D, _game) -> void:
	Plaza.statue_reference(town)

## User follow-up: uniform bronze portrait, temple hair, wider and shorter face.
func statue_temple_hair(town: Node3D, _game) -> void:
	Plaza.statue_reference(town)

## Close-up correction: fit strand relief to the curved hair surfaces.
func statue_hair_relief_fit(town: Node3D, _game) -> void:
	Plaza.statue_reference(town)

## User: remove the different colour across the entire statue, 9 November 2026.
func statue_single_bronze(town: Node3D, _game) -> void:
	Plaza.uniform_statue_bronze(town)

## Bench audit (user, 9 Nov 2026: "check if they are at an odd position ... fix them"). Town
## coordinates; ground heights measured with downward rays on the rolling park ground
## (docs/guides/FINAL_VERIFICATION.md, "Bench placement audit"):
## - park benches 5-8 and 25-28 (and Picnic table2 beside them) were sunk 0.3-0.5 m into the
##   raised park ground: lifted onto it;
## - garden bench 1 stood in the middle of the lagoon walk: moved onto the lawn, facing the water;
## - garden bench 4 straddled the zoo fence: moved to the lawn strip outside it, facing the walk;
## - garden benches 5 and 6 were inside the roped tulip lawns of the monument plaza, out of
##   reach: moved to the edges of the plaza walk, facing each other across it;
## - the bus stop bench was a bare seat plank inside a planting bed: given legs and a back
##   and moved beside the bus stop sign, facing the road.
## - removed (user, 9 Nov 2026): garden bench 2 on the slope north of the lagoon, and park bench
##   9-12 standing alone in a lawn facing a building wall.
func bench_placement(town: Node3D, game) -> void:
	for n in ["Park bench5", "Park bench6", "Park bench7", "Park bench8"]:
		town.get_node(n).position.y += 0.31
	for n in ["Park bench25", "Park bench26", "Park bench27", "Park bench28", "Picnic table2", "Picnic table legs3", "Picnic table legs4"]:
		town.get_node(n).position.y += 0.46
	_garden_bench(town, "", Vector3(7.75, 0.03, 106.3), 90.0)
	_garden_bench(town, "4", Vector3(-52.8, -0.035, 120.0), -90.0)
	_garden_bench(town, "5", Vector3(34.0, 0.12, 137.25), 180.0)
	_garden_bench(town, "6", Vector3(34.0, 0.14, 140.95), 0.0)
	for path in ["PublicGarden/Garden bench seat2", "PublicGarden/Garden bench back2", "PublicGarden/Garden bench leg3",
			"PublicGarden/Garden bench leg4", "Park bench9", "Park bench10", "Park bench11", "Park bench12"]:
		var node := town.get_node(path)
		node.get_parent().remove_child(node)
		node.free()
	var bench: Node3D = town.get_node("Bus stop bench")
	bench.position = Vector3(37.4, 0.52, 190.0)
	var plank: MeshInstance3D = bench.find_children("*", "MeshInstance3D", false, false)[0]
	var tint: Color = plank.material_override.albedo_color if plank.material_override is StandardMaterial3D else Color("a67f5b")
	for part in [["Bus stop bench back", Vector3(0, 0.38, -0.2), Vector3(1.8, 0.6, 0.1)],
			["Bus stop bench leg", Vector3(-0.75, -0.29, 0), Vector3(0.1, 0.46, 0.4)],
			["Bus stop bench leg2", Vector3(0.75, -0.29, 0), Vector3(0.1, 0.46, 0.4)]]:
		var node: Node3D = game.box(part[0], bench.position + part[1], part[2], tint, "", true)
		node.reparent(bench)

## Places a public-garden bench (seat, back 0.3 m behind it, legs 0.8 m to the sides) with its seat
## centre at `at` (x, z; y = ground), turned `degrees` about Y (0 faces -Z, like the originals).
func _garden_bench(town: Node3D, suffix: String, at: Vector3, degrees: float) -> void:
	var garden: Node3D = town.get_node("PublicGarden")
	var legs := ["", "2"] if suffix == "" else [str(int(suffix)*2-1), str(int(suffix)*2)]
	var turn := Basis(Vector3.UP, deg_to_rad(degrees))
	var parts := [["Garden bench seat"+suffix, Vector3(0, 0.55, 0)], ["Garden bench back"+suffix, Vector3(0, 0.95, 0.3)],
		["Garden bench leg"+legs[0], Vector3(0.8, 0.25, 0)], ["Garden bench leg"+legs[1], Vector3(-0.8, 0.25, 0)]]
	for part in parts:
		var node: Node3D = garden.get_node(part[0])
		var offset: Vector3 = turn*part[1]
		node.position = Vector3(at.x+offset.x, at.y+offset.y, at.z+offset.z)
		node.rotation.y = deg_to_rad(degrees)

## Cast-bronze finish from the user's Boston photograph (9 Nov 2026, "the color and the texture
## is a little off"): dark glossy bronze with continuous green-grey patina streaks, still one
## material for the whole statue (monument_plaza.gd, patina_bronze_material()).
func statue_patina(town: Node3D, _game) -> void:
	Plaza.patina_statue_bronze(town)


## Patina finish in town light (9 Nov 2026): brighter, warmer bronze and less metal so the
## statue reads brown rather than black and stops mirroring the blue sky.
func statue_patina_warm(town: Node3D, _game) -> void:
	Plaza.patina_statue_bronze(town)

## The restaurant-lot motorcycle becomes the toy-like scooter BonBon rides visibly (user, 9 Nov 2026;
## docs/guides/ZOO_VEHICLE_IMPLEMENTATION.md#scooter-and-rider--9-november-2026): an instance of scooter.tscn replaces the
## old motorcycle.tscn instance at the same path, transform and metas (word "motorcycle",
## zone override Vehicles/Motorcycle -> fine_dining).
func toy_scooter(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("Vehicles/Motorcycle")
	var scooter: Node3D = load("res://scenes/props/vehicles/scooter.tscn").instantiate()
	var parent := old.get_parent()
	var index := old.get_index()
	for meta in old.get_meta_list():
		scooter.set_meta(meta, old.get_meta(meta))
	var placed := old.transform
	parent.remove_child(old)
	old.free()
	scooter.name = "Motorcycle"
	parent.add_child(scooter)
	parent.move_child(scooter, index)
	scooter.transform = placed
	scooter.owner = town

## Same day (user): BonBon rides at her full size on a scooter scaled up around her, sitting on the
## cushion with her paws where she stands. The bake keeps its own copy of every scooter part, so
## a changed scooter.tscn is placed again (same path, transform and metas).
func toy_scooter_full_size(town: Node3D, game) -> void:
	toy_scooter(town, game)

## Statue finish in the town's style (user, 9 Nov 2026): one plain, non-metallic dark olive bronze
## replaces the triplanar patina of `statue_patina` / `statue_patina_warm` (monument_plaza.gd).
func statue_town_bronze(town: Node3D, _game) -> void:
	Plaza.town_statue_bronze(town)

## The Mystery House's plot south of the bank (9 Nov 2026; scripts/buildings/mystery.gd): a site
## bound, so the HUD names the place "Mystery House" (places.mystery_house), and its map label.
## Bake the mystery unit before this step (it needs the MysteryHouse node).
func mystery_house_site(town: Node3D, game) -> void:
	var house: Node3D = town.get_node_or_null("MysteryHouse")
	if house == null:
		push_error("base.gd mystery_house_site: the mystery unit is not baked or not loaded")
		return
	var layout = game.reference_layout
	# Town X 110..146 (front path to the rear wall), Z 68..96 (garden beds included).
	layout.site_bounds["MysteryHouse"] = AABB(Vector3(110.0, -0.5, 68.0), Vector3(36.0, 18.0, 28.0))
	layout.entries.append({"node": house, "title": "MYSTERY HOUSE", "color": Color(0.949, 0.8588, 0.7529)})

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "base")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "base", 2)

## The old flat-roofed chapel's runtime outline (eaves at 4.2 m and corner posts, saved as
## top-level "Building outline" pieces) ran across the rebuilt chapel's CHAPEL sign and walls
## (user, 12 Nov 2026; scripts/buildings/chapel.gd step `rebuild`). Removes the eight pieces on the
## chapel's footprint: eave41..44 and corner41..44.
func chapel_old_outline(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Chapel")
	for kind in ["eave", "corner"]:
		for n in range(41, 45):
			var piece := town.get_node_or_null("Building outline %s%d" % [kind, n]) as Node3D
			if piece == null:
				push_error("base.gd chapel_old_outline: Building outline %s%d not found" % [kind, n])
				continue
			var at := site.to_local(piece.global_position)
			if at.x < 40.0 or at.x > 53.0 or at.z < 68.0 or at.z > 82.0:
				push_error("base.gd chapel_old_outline: %s is not on the chapel (%s)" % [piece.name, at])
				continue
			town.remove_child(piece)
			piece.free()

## Separate static study of the user's lion turnaround (10 Nov 2026); existing zoo animals stay intact.
func lion_blueprint_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/lion_blueprint.scn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-82.5, 0.10, 121.5)
	model.rotation.y = PI
	# Match the species display height (1.95 town units), not the house mascot scale.
	model.scale = Vector3.ONE * (1.95 / 2.55)
	model.owner = town

## Second, independent build of the same lion turnaround for comparison (user, 10 Nov 2026):
## scenes/animals/lion_clay.scn (scripts/characters/lion_clay.gd, smooth clay field meshes),
## static with a box footprint, mirrored across the wild-animal gate walk from
## LionBlueprintDisplay and facing the gate like it. No word, no wandering.
func lion_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/lion_clay.scn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-73.5, 0.12, 121.5)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay lion's meshes in base.scn, so a rebuilt lion_clay.scn only reaches the
## zoo through a step: face rework against the blueprint (user, 11 Nov 2026) swaps the saved
## display for the rebuilt scene, keeping its name and place.
func lion_clay_face_rework(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/LionClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/lion_clay.scn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Clay lion ears fitted to the blueprint's front view (user, 11 Nov 2026): same swap of the saved
## display for the rebuilt scene.
func lion_clay_ears_fit(town: Node3D, game) -> void:
	lion_clay_face_rework(town, game)

## Clay lion eyes and mane reworked against the user's high-res front view (11 Nov 2026): same
## swap of the saved display for the rebuilt scene.
func lion_clay_eyes_mane(town: Node3D, game) -> void:
	lion_clay_face_rework(town, game)

## Ears set back into the mane and the mane rebuilt as two layers (11 Nov 2026).
func lion_clay_ears_mane_two_layers(town: Node3D, game) -> void:
	lion_clay_face_rework(town, game)

## Whole clay lion re-measured against the sheet (user, 11 Nov 2026: eyes, face, mane lobes,
## body, legs, tail tuft): same swap of the saved display for the rebuilt scene.
func lion_clay_second_pass(town: Node3D, game) -> void:
	lion_clay_face_rework(town, game)

## Third, independent build of the user's lion turnaround (11 Nov 2026, reviewed by the user
## before placing): scenes/animals/lion_crawl.tscn (scripts/characters/lion_crawl.gd). Static with
## a box footprint, on the centre line inside the wild-animal gate, behind the two earlier lion
## displays and facing the gate like them. No word, no wandering. The bake stores its meshes in
## base.scn: a rebuilt lion_crawl.tscn reaches the zoo only through a later swap step.
func lion_crawl_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/lion_crawl.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-78.0, 0.12, 119.2)
	model.rotation.y = PI
	model.owner = town

## Crawl lion colours darkened for town sunlight (user, 11 Nov 2026: cream, muzzle, mane and
## ear pink washed out in daylight): swaps the saved display for the rebuilt scene, keeping its
## name and place.
func lion_crawl_colours(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/LionCrawlDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/lion_crawl.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Combined lion (user, 11 Nov 2026, reviewed before placing): the crawl lion's mane, body, paws,
## tail and ears with the clay lion's face, scenes/animals/lion_mix.tscn
## (scripts/characters/lion_mix.gd). Static with a box footprint, on the lawn beside the clay
## lion and facing the gate like it. No word, no wandering.
func lion_mix_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/lion_mix.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-68.5, 0.12, 122.8)
	model.rotation.y = PI
	model.owner = town

## TEMPORARY (user, 11 Nov 2026: "a temporary mark on each lion so I can tell them apart and
## direct my agent"): a big coloured number floating over each of the four lion displays, always
## turned to the camera. 1 = LionBlueprintDisplay, 2 = LionClayDisplay, 3 = LionCrawlDisplay,
## 4 = LionMixDisplay. Text meshes, not Label3D, so the sign translation leaves them alone.
## Remove with a later step that frees ParkZoo/TempLionMark1..4.
func lion_temp_marks(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var marks := [["LionBlueprintDisplay", Color("e53935")], ["LionClayDisplay", Color("1e88e5")],
		["LionCrawlDisplay", Color("2e9d48")], ["LionMixDisplay", Color("8e24aa")]]
	for i in marks.size():
		var lion: Node3D = zoo.get_node(marks[i][0])
		var text := TextMesh.new()
		text.text = str(i + 1)
		text.font_size = 160
		text.pixel_size = 0.01
		text.depth = 0.08
		var mat := StandardMaterial3D.new()
		mat.albedo_color = marks[i][1]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.billboard_keep_scale = true
		var mark := MeshInstance3D.new()
		mark.name = "TempLionMark%d" % (i + 1)
		mark.mesh = text
		mark.material_override = mat
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mark.set_meta("temporary", true)
		zoo.add_child(mark)
		mark.position = lion.position + Vector3(0, 3.0, 0)
		mark.owner = town

## TEMPORARY marks lowered to just above each mane (they floated 3 units up and, seen from
## above, looked attached to the animals behind).
func lion_temp_marks_lower(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var lions := ["LionBlueprintDisplay", "LionClayDisplay", "LionCrawlDisplay", "LionMixDisplay"]
	for i in lions.size():
		var mark: Node3D = zoo.get_node("TempLionMark%d" % (i + 1))
		mark.position = (zoo.get_node(lions[i]) as Node3D).position + Vector3(0, 2.5, 0)

## Static study of the user's giraffe turnaround (11 Nov 2026): scenes/animals/giraffe_clay.tscn
## (scripts/characters/giraffe_clay.gd), on the wild-animal lawn behind the two lion displays and
## facing the gate like them, at the zoo giraffe's display height. No word, no wandering; the
## existing zoo giraffe stays as it is.
func giraffe_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/giraffe_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-78.0, 0.12, 113.0)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay giraffe's meshes in base.scn, so a rebuilt giraffe_clay.tscn only
## reaches the zoo through a step: colours deepened for the town's daylight (11 Nov 2026) swaps
## the saved display for the rebuilt scene, keeping its name and place.
func giraffe_clay_colours(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/GiraffeClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/giraffe_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Clay giraffe refined against the sheet (user, 11 Nov 2026: crisper patch edges, shorter
## muzzle, legs tapering straight into the hooves; then eyes reworked from the sheet's close-ups:
## round with a white sliver, winged lid line and lashes, one catch-light): same swap of the saved display.
func giraffe_clay_refine(town: Node3D, game) -> void:
	giraffe_clay_colours(town, game)

## Static study of the user's cow turnaround (11 Nov 2026): scenes/animals/cow_clay.tscn
## (scripts/characters/cow_clay.gd), on the wild-animal lawn east of the other clay displays and facing
## the gate like them, at the zoo cow's display height (1.55). No word, no wandering; the farm's cow
## stays as it is.
func cow_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/cow_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-65.0, 0.12, 116.0)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay cow's meshes in base.scn, so a rebuilt cow_clay.tscn only reaches the
## zoo through a step: colours deepened for the town's daylight, muzzle lowered clear of the eyes
## and cleaner iris edges (11 Nov 2026) swap the saved display for the rebuilt scene, keeping its
## name and place.
func cow_clay_colours_eyes(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/CowClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/cow_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Clay cow's muzzle reshaped against the sheet (user, 11 Nov 2026: rounder, slimmer lower lip,
## drawn mouth line that dips and turns up into the smile): same swap of the saved display.
func cow_clay_muzzle(town: Node3D, game) -> void:
	cow_clay_colours_eyes(town, game)

## Lower lip brought forward and the mouth line darkened (11 Nov 2026); a parallel bake had
## already applied `cow_clay_muzzle` with the build before that tweak. Same swap.
func cow_clay_lower_lip(town: Node3D, game) -> void:
	cow_clay_colours_eyes(town, game)

## Muzzle put back as it was before `cow_clay_muzzle` (user, 11 Nov 2026: "revert to the
## previous version") and the smile lines on the cheeks removed. Same swap.
func cow_clay_muzzle_reverted(town: Node3D, game) -> void:
	cow_clay_colours_eyes(town, game)

## Static study of the user's elephant turnaround (11 Nov 2026): scenes/animals/elephant_clay.tscn
## (scripts/characters/elephant_clay.gd), on the wild-animal lawn beside the clay giraffe and
## facing the gate like it, at the zoo elephant's display height. No word, no wandering; the
## existing zoo elephant stays as it is. A rebuilt prefab needs a swap step like the giraffe's.
func elephant_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/elephant_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-70.5, 0.12, 112.5)
	model.rotation.y = PI
	model.owner = town

## Static study of the user's red panda turnaround (11 Nov 2026): scenes/animals/red_panda_clay.tscn
## (scripts/characters/red_panda_clay.gd), on the wild-animal lawn between the clay lion and the
## clay giraffe, turned toward the gate walk, 0.9 town units tall. No word, no wandering.
func red_panda_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/red_panda_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-74.5, 0.12, 117.5)
	model.rotation.y = PI - 0.5
	model.owner = town

## Clay elephant colours deepened for the town's daylight (11 Nov 2026): swaps the saved display
## for the rebuilt scene, keeping its name and place.
func elephant_clay_colours(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/ElephantClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/elephant_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Static study of the user's panda turnaround (11 Nov 2026): scenes/animals/panda_clay.tscn
## (scripts/characters/panda_clay.gd), on the wild-animal lawn on the far side of the clay
## giraffe from the elephant and red panda displays, facing the gate like them, 1.6 town units
## tall. No word, no wandering.
func panda_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/panda_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-85.5, 0.12, 115.5)
	model.rotation.y = PI
	model.owner = town

## Static study of the user's gorilla turnaround (11 Nov 2026): scenes/animals/gorilla_clay.tscn
## (scripts/characters/gorilla_clay.gd), on the wild-animal lawn left of the clay giraffe (seen
## from the gate) and facing the gate like it, 2.1 town units tall on its knuckles. No word, no
## wandering. A rebuilt prefab needs a swap step like the giraffe's.
func gorilla_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/gorilla_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-82.3, 0.12, 111.0)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay gorilla's meshes in base.scn, so a rebuilt gorilla_clay.tscn only
## reaches the zoo through a step: eyelids moved to the matte face mesh and colours cooled for
## the town's daylight (11 Nov 2026) swaps the saved display, keeping its name and place.
func gorilla_clay_refine(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/GorillaClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/gorilla_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Clay gorilla eyes end under the lid line, so no white shows outside it (user, 11 Nov 2026):
## same swap of the saved display for the rebuilt scene.
func gorilla_clay_eyelids(town: Node3D, game) -> void:
	gorilla_clay_refine(town, game)

## The bake stores the clay panda's meshes in base.scn, so a rebuilt panda_clay.tscn only reaches
## the zoo through a step: matte eye rims and a smooth one-piece nose (11 Nov 2026) swap the
## saved display for the rebuilt scene, keeping its name and place.
func panda_clay_face(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/PandaClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/panda_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Static study of the user's deer turnaround (11 Nov 2026): scenes/animals/deer_clay.tscn
## (scripts/characters/deer_clay.gd), on the wild-animal lawn between the clay lion and the clay
## cow and facing the gate like them, 2.0 town units to the antler tips. No word, no wandering.
func deer_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/deer_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-69.5, 0.12, 119.0)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay deer's meshes in base.scn, so a rebuilt deer_clay.tscn only reaches
## the zoo through a step: eyes and ears reworked against the sheet's close-ups (user, 11 Nov
## 2026) swaps the saved display for the rebuilt scene, keeping its name and place.
func deer_clay_eyes_ears(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/DeerClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/deer_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Static study of the user's kangaroo turnaround (11 Nov 2026): scenes/animals/kangaroo_clay.tscn
## (scripts/characters/kangaroo_clay.gd), on the wild-animal lawn west of the visitor walk,
## behind the blueprint lion and facing the gate like the other displays. No word, no wandering.
## The bake stores its meshes in base.scn, so a later rebuild of the prefab needs a swap step
## (see giraffe_clay_colours).
func kangaroo_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/kangaroo_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-81.5, 0.12, 117.5)
	model.rotation.y = PI
	model.owner = town

## Static study of the user's rhino turnaround (approved 11 Nov 2026): scenes/animals/rhino_clay.tscn
## (scripts/characters/rhino_clay.gd), on the wild-animal lawn behind the clay giraffe and
## elephant and facing the gate like them, as built (about 1.95 town units to the ear tips). No
## word, no wandering. A rebuilt prefab needs a swap step like the giraffe's.
func rhino_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/rhino_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-75.0, 0.12, 108.0)
	model.rotation.y = PI
	model.owner = town

## Static study of the user's zebra turnaround (approved 11 Nov 2026): scenes/animals/zebra_clay.tscn
## (scripts/characters/zebra_clay.gd), on the wild-animal lawn south-east of the other clay
## displays (between the clay cow and the clay rhino's row) and facing the gate like them, as
## built (1.7 town units). No word, no wandering. A rebuilt prefab needs a swap step like the
## giraffe's.
func zebra_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/zebra_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-65.0, 0.12, 110.5)
	model.rotation.y = PI
	model.owner = town

## Lion design finalised (user, 11 Nov 2026): the roaming zoo lion ParkZoo/Lion takes the clay
## lion's body (#2, scenes/animals/lion_clay.scn). Same name, home, facing, word, picking area
## and park_animals.gd wandering; scaled to the species display height (1.95 town units) with
## its soles where the old lion's were. The clay model faces -Z, so it turns half round inside
## the wanderer (authored animals face +Z); its Footprint body is switched off, or the wander
## probe would hit the lion itself. The other designs went next (`lion_designs_removed`).
func lion_clay_roams(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var old: Node3D = zoo.get_node("Lion")
	var home: Vector3 = old.get("home") if old.get("home") is Vector3 and old.get("home") != Vector3.ZERO else old.position
	var old_bounds: AABB = old.call("_visible_bounds")
	var sole_y: float = home.y + old_bounds.position.y * old.scale.y
	var basis_y: float = old.rotation.y
	var index := old.get_index()
	zoo.remove_child(old)
	old.free()
	var lion := Node3D.new()
	lion.name = "Lion"
	lion.set_script(preload("res://scripts/world/park_animals.gd"))
	lion.set_meta("word_key", "lion")
	var model: Node3D = load("res://scenes/animals/lion_clay.scn").instantiate()
	model.name = "ClayLion"
	model.rotation.y = PI
	lion.add_child(model)
	var footprint := model.get_node("Footprint") as CollisionObject3D
	footprint.collision_layer = 0
	footprint.collision_mask = 0
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var part: AABB = model.transform * mesh.transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	var size := 1.95 / box.size.y
	var area := Area3D.new()
	area.name = "VocabularyArea"
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = box.size
	shape.shape = bounds
	shape.position = box.get_center()
	area.add_child(shape)
	lion.add_child(area)
	lion.scale = Vector3.ONE * size
	lion.position = Vector3(home.x, sole_y - box.position.y * size, home.z)
	lion.rotation.y = basis_y
	lion.set_meta("display_size", box.size * size)
	zoo.add_child(lion)
	zoo.move_child(lion, index)
	lion.set("home", lion.position)
	for node: Node in [lion, model, area, shape]:
		node.owner = town
	print("LION CLAY ROAMS: scale %.4f position %s size %s" % [size, lion.position, box.size * size])

## Lion design settled (user, 11 Nov 2026, after the in-game check of `lion_clay_roams`): the four
## numbered study displays and their temporary numbers leave the zoo. Their prefabs, sources and
## build tools (lion_blueprint, lion_crawl, lion_mix) and the old prefab scenes/animals/lion.tscn
## were deleted the same day, so the baked steps above that load them never run again.
## lion_clay.scn stays: ParkZoo/Lion instances it.
func lion_designs_removed(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	for name in ["LionBlueprintDisplay", "LionClayDisplay", "LionCrawlDisplay", "LionMixDisplay",
			"TempLionMark1", "TempLionMark2", "TempLionMark3", "TempLionMark4"]:
		var node := zoo.get_node(name)
		zoo.remove_child(node)
		node.free()

## Static study of the user's black bear turnaround (11 Nov 2026): scenes/animals/black_bear_clay.tscn
## (scripts/characters/black_bear_clay.gd), on the wild-animal lawn in the clay rhino's row,
## between it and the clay zebra, facing the gate like them, 1.5 town units to the ear tops. No
## word, no wandering. A rebuilt prefab needs a swap step like the giraffe's.
func black_bear_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/black_bear_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-70.0, 0.12, 108.0)
	model.rotation.y = PI
	model.owner = town

## The clay black bear moves to the front of the lawn, where the clay lion study stood until
## `lion_designs_removed` (11 Nov 2026: its first place was crowded by the clay elephant and lay
## in the roaming bear's path), and takes the rebuilt prefab (straight legs, smaller paws).
func black_bear_clay_front_row(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/BlackBearClayDisplay")
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/black_bear_clay.tscn").instantiate()
	zoo.add_child(model)
	model.position = Vector3(-73.5, 0.12, 121.5)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay bear's meshes in base.scn, so a rebuilt black_bear_clay.tscn only
## reaches the zoo through a step: the leg cores of `black_bear_clay_front_row` reached below
## the soles (11 Nov 2026); this swaps the saved display for the rebuilt scene, keeping its place.
func black_bear_clay_soles(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/BlackBearClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/black_bear_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Static study of the user's flamingo turnaround (11 Nov 2026): scenes/animals/flamingo_clay.tscn
## (scripts/characters/flamingo_clay.gd), on the open east side of the wild-animal lawn (6.5 units
## east of the clay cow, 4.5 from the east fence) and facing the gate like the other displays, as
## built (1.4 town units). No word, no wandering. A rebuilt prefab needs a swap step like the
## giraffe's.
func flamingo_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/flamingo_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-58.5, 0.12, 117.0)
	model.rotation.y = PI
	model.owner = town

## The bake stores the clay flamingo's meshes in base.scn, so a rebuilt flamingo_clay.tscn only
## reaches the zoo through a step: the first colours washed out to pale peach in daylight
## (11 Nov 2026); this swaps the saved display for the rebuilt scene, keeping its place.
func flamingo_clay_colours(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/FlamingoClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/flamingo_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## The clay black bear is a cub (user, 11 Nov 2026): the display is renamed
## ParkZoo/BlackBearCubClayDisplay and moves beside the roaming zoo bear's home, 2.6 town units
## to its side, still facing the gate. Size unchanged (user: hold off).
func black_bear_cub_beside_bear(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var cub: Node3D = zoo.get_node("BlackBearClayDisplay")
	var bear: Node3D = zoo.get_node("Bear")
	var home: Vector3 = bear.get("home") if bear.get("home") is Vector3 and bear.get("home") != Vector3.ZERO else bear.position
	cub.name = "BlackBearCubClayDisplay"
	cub.position = Vector3(home.x + 2.6, 0.12, home.z)
	print("BLACK BEAR CUB: bear home %s, cub %s" % [home, cub.position])

## `black_bear_cub_beside_bear` put the cub on the clay zebra (-65.0, 110.5); the clay elephant
## stands on the bear's other side, so the cub goes just behind the bear's home instead
## (11 Nov 2026), 3.2 town units from it and clear of the zebra, elephant and rhino.
func black_bear_cub_clear_of_zebra(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var bear: Node3D = zoo.get_node("Bear")
	var home: Vector3 = bear.get("home") if bear.get("home") is Vector3 and bear.get("home") != Vector3.ZERO else bear.position
	var cub: Node3D = zoo.get_node("BlackBearCubClayDisplay")
	cub.position = Vector3(home.x, 0.12, home.z - 3.2)
	print("BLACK BEAR CUB: bear home %s, cub %s" % [home, cub.position])

## Painted rows of feathers on the clay flamingo's back and a straightened tail (user asked to
## refine the feathers, 11 Nov 2026). Same swap as `flamingo_clay_colours`.
func flamingo_clay_back_feathers(town: Node3D, game) -> void:
	flamingo_clay_colours(town, game)

## Clay bear cub's body reshaped against the sheet (user, 11 Nov 2026: pear-shaped torso, round
## shoulders and hips, tapering legs, flat-soled paws; head and face untouched). The bake stores
## its meshes in base.scn, so the saved display is swapped for the rebuilt scene, keeping its
## name and place.
func black_bear_cub_body(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/BlackBearCubClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/black_bear_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Static study of the user's golden retriever turnaround (11 Nov 2026, approved after the ninth
## pass): scenes/animals/golden_retriever_clay.tscn (scripts/characters/golden_retriever_clay.gd),
## at the front of the wild-animal lawn between the clay kangaroo and the clay red panda, facing
## the gate like them, 0.8 town units tall (the zoo dog's height). No word, no wandering; the
## meadow's dog stays as it is. A rebuilt prefab needs a swap step like the gorilla's.
func golden_retriever_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/golden_retriever_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-78.0, 0.12, 120.0)
	model.rotation.y = PI
	model.owner = town

## The cub's body goes back to how it was before `black_bear_cub_body` (user, 11 Nov 2026: the
## body changes were meant for the adult bear). Same swap of the saved display.
func black_bear_cub_body_reverted(town: Node3D, game) -> void:
	black_bear_cub_body(town, game)

## Adult clay black bear (user, 11 Nov 2026): scenes/animals/black_bear_adult_clay.tscn
## (scripts/characters/black_bear_adult_clay.gd: the cub's head on a reshaped body, 2.1 town
## units to the ear tops), 2.9 town units to the cub's right-hand side as seen from the gate so
## the two can be compared, facing the gate like it. No word, no wandering. A rebuilt prefab
## needs a swap step like `black_bear_cub_body`.
func black_bear_adult_clay_display(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var cub: Node3D = zoo.get_node("BlackBearCubClayDisplay")
	var model: Node3D = load("res://scenes/animals/black_bear_adult_clay.tscn").instantiate()
	zoo.add_child(model)
	model.position = cub.position + Vector3(-2.9, 0, 0)
	model.rotation = cub.rotation
	model.owner = town
	print("BLACK BEAR ADULT: cub %s, adult %s" % [cub.position, model.position])

## Both clay black bears move to the open front of the wild-animal lawn, where the lion studies
## stood until `lion_designs_removed`, side by side for comparison (user, 11 Nov 2026): behind
## the roaming bear's home the zebra, the elephant and the bear itself hid them. Adult on the
## left as seen from the gate, cub 3 town units to its right, both facing the gate.
func black_bears_front_row_pair(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	(zoo.get_node("BlackBearAdultClayDisplay") as Node3D).position = Vector3(-72.5, 0.12, 122.0)
	(zoo.get_node("BlackBearCubClayDisplay") as Node3D).position = Vector3(-69.5, 0.12, 122.0)

## The cub gets baby proportions (user, 11 Nov 2026): the same head on a shorter, smaller body
## with shorter legs (`_body_squash` in black_bear_clay.gd). Same swap of the saved display.
func black_bear_cub_baby(town: Node3D, game) -> void:
	black_bear_cub_body(town, game)

## The cub gets a younger face (user, 11 Nov 2026): bigger eyes set a little lower and wider,
## bigger ears, a shorter muzzle (`_face_youth` in black_bear_clay.gd; the adult keeps the
## sheet's face). Same swap of the saved display.
func black_bear_cub_young_face(town: Node3D, game) -> void:
	black_bear_cub_body(town, game)

## The bake stores the clay retriever's meshes in base.scn, so a rebuilt prefab only reaches the
## zoo through a step: coat deepened for the town's daylight (user, 11 Nov 2026: it read pale
## and yellow there) swaps the saved display for the rebuilt scene, keeping its name and place.
func golden_retriever_clay_coat(town: Node3D, _game) -> void:
	var old: Node3D = town.get_node("ParkZoo/GoldenRetrieverClayDisplay")
	var place := old.transform
	var zoo := old.get_parent()
	zoo.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/golden_retriever_clay.tscn").instantiate()
	zoo.add_child(model)
	model.transform = place
	model.owner = town

## Static study of the user's duck turnaround (11 Nov 2026, approved after the bill passes):
## scenes/animals/duck_clay.tscn (scripts/characters/duck_clay.gd), at the front of the
## wild-animal lawn between the clay cow and the clay flamingo, facing the gate like them,
## 0.45 town units tall (the zoo duck's height). No word, no wandering; the zoo's own ducks stay
## as they are. A rebuilt prefab needs a swap step like the gorilla's.
func duck_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/duck_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-62.0, 0.12, 119.5)
	model.rotation.y = PI
	model.owner = town

## The cub's fur becomes a lighter black (user, 11 Nov 2026; `_fur` in black_bear_clay.gd, the
## adult keeps the sheet's colour). Same swap of the saved display.
func black_bear_cub_lighter_fur(town: Node3D, game) -> void:
	black_bear_cub_body(town, game)

## Static study of the user's black and white pig turnaround (11 Nov 2026, approved after the
## head, eye and body passes): scenes/animals/pig_clay.tscn (scripts/characters/pig_clay.gd), at
## the front of the wild-animal lawn between the clay deer and the clay duck, in front of the
## clay cow, facing the gate like them, 0.95 town units tall (the zoo pig's height). No word,
## no wandering; the zoo's own pigs stay as they are. A rebuilt prefab needs a swap step like
## the gorilla's.
func pig_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/pig_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-65.5, 0.12, 120.5)
	model.rotation.y = PI
	model.owner = town

## The clay animals join the zoo (user, 11 Nov 2026), set up like the clay lion in `lion_clay_roams`:
## each becomes a wandering ParkZoo animal with a word, a fitted VocabularyArea and its species
## display height from park_animals.gd ANIMAL_HEIGHTS (the small-animal minimum still applies).
## Seven take the place of the old animal of their species (same node name, home, facing, child
## index and word; the old model and the static clay copy go): giraffe, adult black bear (Bear),
## elephant, cow, pig, duck and golden retriever (Dog). Nine new species roam from where their
## static display stood, facing the gate as before, with new words: panda, red panda, gorilla,
## deer, kangaroo, rhinoceros, zebra, bear cub and flamingo. The old prefabs in scenes/animals/
## stay on disk (the legacy park_zoo.tscn and its check use them); a rebuilt clay prefab reaches
## the zoo through the instance, with no swap step.
const CLAY_REPLACEMENTS := {"Giraffe": ["giraffe", "GiraffeClayDisplay"],
	"Bear": ["black_bear_adult", "BlackBearAdultClayDisplay"], "Elephant": ["elephant", "ElephantClayDisplay"],
	"Cow": ["cow", "CowClayDisplay"], "Pig": ["pig", "PigClayDisplay"], "Duck": ["duck", "DuckClayDisplay"],
	"Dog": ["golden_retriever", "GoldenRetrieverClayDisplay"]}
const CLAY_NEW_SPECIES := {"Panda": ["panda", "PandaClayDisplay", "panda"],
	"Red Panda": ["red_panda", "RedPandaClayDisplay", "red panda"], "Gorilla": ["gorilla", "GorillaClayDisplay", "gorilla"],
	"Deer": ["deer", "DeerClayDisplay", "deer"], "Kangaroo": ["kangaroo", "KangarooClayDisplay", "kangaroo"],
	"Rhinoceros": ["rhino", "RhinoClayDisplay", "rhinoceros"], "Zebra": ["zebra", "ZebraClayDisplay", "zebra"],
	"Bear Cub": ["black_bear", "BlackBearCubClayDisplay", "bear cub"], "Flamingo": ["flamingo", "FlamingoClayDisplay", "flamingo"]}

func clay_animals_roam(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	for name: String in CLAY_REPLACEMENTS:
		var old: Node3D = zoo.get_node(name)
		var home: Vector3 = old.get("home") if old.get("home") is Vector3 and old.get("home") != Vector3.ZERO else old.position
		var sole_y: float = home.y + (old.call("_visible_bounds") as AABB).position.y * old.scale.y
		var place := Vector3(home.x, sole_y, home.z)
		_clay_roamer(zoo, name, str(old.get_meta("word_key")), CLAY_REPLACEMENTS[name][0], place, old.rotation.y, old.get_index(), [old, zoo.get_node(CLAY_REPLACEMENTS[name][1])])
	for name: String in CLAY_NEW_SPECIES:
		var spec: Array = CLAY_NEW_SPECIES[name]
		var display: Node3D = zoo.get_node(spec[1])
		# The display turns the -Z-facing model; inside the wanderer the model is already half round.
		_clay_roamer(zoo, name, spec[2], spec[0], display.position, wrapf(display.rotation.y + PI, -PI, PI), display.get_index(), [display])

## One wandering clay animal: root `name` (park_animals.gd, word meta), child model turned half
## round (the clay models face -Z, wanderers +Z) with its Footprint body off (the wander probe
## would hit the animal itself), a VocabularyArea fitted to the visible meshes, uniform scale to
## the species height, the model's ground (local y 0) at `place`. `replaced` nodes are freed.
func _clay_roamer(zoo: Node3D, name: String, word: String, prefab: String, place: Vector3, facing: float, index: int, replaced: Array) -> void:
	var Animals = preload("res://scripts/world/park_animals.gd")
	for node: Node in replaced:
		zoo.remove_child(node)
		node.free()
	var animal := Node3D.new()
	animal.name = name
	animal.set_script(Animals)
	animal.set_meta("word_key", word)
	var model: Node3D = load("res://scenes/animals/%s_clay.tscn" % prefab).instantiate()
	model.name = "Clay" + name.replace(" ", "")
	model.rotation.y = PI
	animal.add_child(model)
	var footprint := model.get_node("Footprint") as CollisionObject3D
	footprint.collision_layer = 0
	footprint.collision_mask = 0
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if not mesh.visible or mesh.mesh == null:
			continue
		var part: AABB = model.transform * _local_to(model, mesh) * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	var height: float = maxf(Animals.ANIMAL_HEIGHTS[name], Animals.MIN_ANIMAL_WORLD_HEIGHT / zoo.global_basis.get_scale().y)
	var size := height / box.size.y
	var area := Area3D.new()
	area.name = "VocabularyArea"
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = box.size
	shape.shape = bounds
	shape.position = box.get_center()
	area.add_child(shape)
	animal.add_child(area)
	animal.scale = Vector3.ONE * size
	animal.position = place
	animal.rotation.y = facing
	animal.set_meta("display_size", box.size * size)
	zoo.add_child(animal)
	zoo.move_child(animal, mini(index, zoo.get_child_count() - 1))
	animal.set("home", animal.position)
	for node: Node in [animal, model, area, shape]:
		node.owner = zoo.get_parent()
	print("CLAY ROAMS: %s (%s) scale %.4f position %s size %s" % [name, word, size, animal.position, box.size * size])

## Wanderers keep their footprints apart, and the deer and bear cub displays stood on the
## tiger's home, so after `clay_animals_roam` none of the three could move (11 Nov 2026, found by
## docs/evidence/clay-zoo-20261111/check.gd). The deer moves to the open east side of the wild-animal lawn,
## the cub beside its mother (the adult Bear), and the zebra a little clear of the Bear.
func clay_animals_spacing(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	for move in [["Deer", Vector2(-60.5, 104.0)], ["Bear Cub", Vector2(-71.5, 113.5)], ["Zebra", Vector2(-62.5, 109.0)]]:
		var animal: Node3D = zoo.get_node(move[0])
		animal.position = Vector3(move[1].x, animal.position.y, move[1].y)
		animal.set("home", animal.position)

## All zoo, farm and meadow animals bigger (user, 11 Nov 2026): every ParkZoo animal named in
## park_animals.gd ANIMAL_HEIGHTS is rescaled uniformly to its display_height() (species height
## or minimum, times DISPLAY_SCALE 1.25; the rhinoceros and gorilla also got higher species
## heights and the bear cub a lower one), about its home, soles kept at the same level. Its
## VocabularyArea scales with it. Fish and turtle (SMALL_ANIMAL_LENGTHS) and the coast crabs
## are not changed.
func animals_bigger(town: Node3D, _game) -> void:
	var Animals = preload("res://scripts/world/park_animals.gd")
	var zoo: Node3D = town.get_node("ParkZoo")
	for key: String in Animals.ANIMAL_HEIGHTS:
		var animal: Node3D = zoo.get_node(key)
		var home: Vector3 = animal.get("home") if animal.get("home") is Vector3 and animal.get("home") != Vector3.ZERO else animal.position
		var box: AABB = animal.call("_visible_bounds")
		var sole_y: float = home.y + box.position.y * animal.scale.y
		var factor: float = Animals.display_height(key, zoo.global_basis.get_scale().y) / (box.size.y * animal.scale.y)
		animal.scale *= factor
		animal.position = Vector3(home.x, sole_y - box.position.y * animal.scale.y, home.z)
		animal.set("home", animal.position)
		if animal.has_meta("display_size"):
			animal.set_meta("display_size", box.size * animal.scale)
		print("ANIMALS BIGGER: %s x%.3f height %.3f" % [key, factor, box.size.y * animal.scale.y])

## Themed zones from the user's zoo design (12 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md, "Zoo zones").
## The wild-animal lawn (x -102..-54, z 84..126, gate at x -78 on the z 126 side) splits into four
## fenced zones around a cross path with a cherry-tree plaza; a ZOO arch frames the gate and
## replaces the WILD ANIMALS board. Each zone fence has a 2-unit walk-in gap on the cross path,
## because animals are studied from within 8 m (interaction_controller.gd INTERACT_DISTANCE);
## the animals keep to their zone through park_animals.gd ZOO_LAWNS (the zone ground meshes,
## direct ParkZoo children). Scenery is plain boxes, spheres and cylinders (merged at runtime by
## render_culling.gd) plus the species tree/bush prefabs; the two waterfalls share one shader.
const ZOO_ZONES := {
	"SAVANNA": [Rect2(-101.6, 84.6, 21.0, 16.8), Color("c9c67c")],
	"FOREST": [Rect2(-75.4, 84.6, 21.0, 16.8), Color("86ab62")],
	"BAMBOO GROVE": [Rect2(-101.6, 106.6, 21.0, 15.9), Color("97c264")],
	"WILDLIFE PLAINS": [Rect2(-75.4, 106.6, 21.0, 15.9), Color("a9c46e")]}
## Animal homes (zoo-local x, z) by zone: savanna, forest, bamboo grove, wildlife plains.
const ZONE_HOMES := {
	"Giraffe": Vector2(-94.0, 89.0), "Rhinoceros": Vector2(-86.0, 95.0), "Deer": Vector2(-84.5, 89.5),
	"Kangaroo": Vector2(-96.5, 93.5), "Zebra": Vector2(-91.0, 97.0),
	"Bear": Vector2(-64.0, 93.0), "Bear Cub": Vector2(-58.5, 96.0), "Gorilla": Vector2(-70.5, 96.0),
	"Panda": Vector2(-94.0, 116.0), "Red Panda": Vector2(-86.0, 116.0), "Monkey": Vector2(-83.0, 119.5),
	"Elephant": Vector2(-66.0, 114.5), "Lion": Vector2(-72.0, 119.0), "Tiger": Vector2(-59.5, 119.0),
	"Flamingo": Vector2(-58.5, 111.0), "Snake": Vector2(-71.5, 110.5)}
const ZOO_PATH := Color("dfc3ab")
const ZOO_ROCKS := [Color("a29d96"), Color("b8b2a9"), Color("8f8a84")]
static var _zz_units := {}
static var _zz_falls: ShaderMaterial

func zoo_zones(town: Node3D, game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var root := Node3D.new()
	root.name = "ZooZones"
	zoo.add_child(root)
	var rail := zoo.get_node("Fence rail") as MeshInstance3D
	var wood: Color = rail.material_override.albedo_color if rail.material_override is StandardMaterial3D else Color("c8955c")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261112
	# Old pieces the design replaces: the WILD ANIMALS board over the gate, the savanna trough.
	for node in zoo.get_children():
		if node.name in ["Habitat sign", "Water trough2", "Water surface2"] or (node is Label3D
				and absf(node.position.x + 78.0) < 1.0 and absf(node.position.z - 126.24) < .5):
			zoo.remove_child(node)
			node.free()
	# Zone grounds (ParkZoo children, read as habitats), cross path and plaza.
	for title: String in ZOO_ZONES:
		var rect: Rect2 = ZOO_ZONES[title][0]
		var ground := _zz_part(zoo, "Zone ground " + title, "box", Vector3(rect.get_center().x, .13, rect.get_center().y), Vector3(rect.size.x, .01, rect.size.y), ZOO_ZONES[title][1], game)
		ground.name = "Zone ground " + title
	_zz_part(root, "Zoo path", "box", Vector3(-78.0, .14, 105.05), Vector3(4.0, .02, 41.9), ZOO_PATH, game)
	_zz_part(root, "Zoo cross path", "box", Vector3(-78.0, .14, 104.0), Vector3(47.68, .02, 4.0), ZOO_PATH, game)
	var layout = preload("res://scripts/world/natural_town_layout.gd").new()
	layout.game = game
	_zz_oval(layout, root, "Zoo plaza", Vector3(-78.0, .16, 104.0), 5.6, 5.6, Color("e8d0bb"))
	# Zone fences: the west zones, then the same lines mirrored about the path (x -> -156 - x).
	var west := [[Vector2(-101.84, 101.4), Vector2(-96.5, 101.4)], [Vector2(-94.5, 101.4), Vector2(-83.0, 101.4)],
		[Vector2(-83.0, 101.4), Vector2(-80.6, 99.0)], [Vector2(-80.6, 99.0), Vector2(-80.6, 84.0)],
		[Vector2(-101.84, 106.6), Vector2(-90.0, 106.6)], [Vector2(-88.0, 106.6), Vector2(-83.0, 106.6)],
		[Vector2(-83.0, 106.6), Vector2(-80.6, 109.0)], [Vector2(-80.6, 109.0), Vector2(-80.6, 122.5)],
		[Vector2(-80.6, 122.5), Vector2(-101.84, 122.5)]]
	for line in west:
		_zz_fence(root, game, line[0], line[1], wood)
		_zz_fence(root, game, Vector2(-156.0 - line[0].x, line[0].y), Vector2(-156.0 - line[1].x, line[1].y), wood)
	_zz_sign(root, game, "SAVANNA", Vector2(-88.0, 101.9))
	_zz_sign(root, game, "FOREST", Vector2(-68.0, 101.9))
	_zz_sign(root, game, "BAMBOO GROVE", Vector2(-92.0, 123.0))
	_zz_sign(root, game, "WILDLIFE PLAINS", Vector2(-64.0, 123.0))
	# Plaza: round planter with a cherry tree and roses, two benches facing the gate (removed by
	# zoo_plaza_benches_removed, 23 Nov 2026), four lamps.
	_zz_part(root, "Plaza planter", "cylinder", Vector3(-78.0, .36, 104.0), Vector3(5.0, .4, 5.0), Color("d8ccb8"), game)
	_zz_part(root, "Plaza planter grass", "cylinder", Vector3(-78.0, .38, 104.0), Vector3(4.6, .44, 4.6), Color("7aa84f"), game)
	_zz_solid(root, "Plaza planter solid", Vector3(-78.0, .4, 104.0), Vector3(5.0, .5, 5.0), 0.0, true)
	_zz_plant(root, "cherry_tree", Vector2(-78.0, 104.0), .6, .85)
	for i in range(8):
		var a := TAU * i / 8.0 + .2
		_zz_plant(root, "rose_bush", Vector2(-78.0 + cos(a) * 1.75, 104.0 + sin(a) * 1.75), .6, .6, a, i % 3)
	var before := town.get_child_count()
	layout.bench(Vector3(-79.95, .16, 108.7), PI)
	layout.bench(Vector3(-76.05, .16, 108.7), PI)
	for node in town.get_children().slice(before):
		node.reparent(root)
	for at in [Vector2(-80.3, 110.4), Vector2(-75.7, 110.4), Vector2(-80.3, 97.6), Vector2(-75.7, 97.6)]:
		_zz_lamp(root, game, at)
	# Entrance: cream pillars with paw plaques and lanterns, a wooden arch with the ZOO board,
	# rose planters beside the pillars (the side openings stay walkable), roses along the fronts.
	for side in [-1.0, 1.0]:
		var x: float = -78.0 + side * 2.5
		_zz_part(root, "Zoo arch plinth", "box", Vector3(x, .15, 126.0), Vector3(1.15, .3, 1.15), Color("d6c6aa"), game)
		_zz_part(root, "Zoo arch pillar", "box", Vector3(x, 1.5, 126.0), Vector3(.9, 2.7, .9), Color("efe4cf"), game)
		_zz_part(root, "Zoo arch cap", "box", Vector3(x, 2.9, 126.0), Vector3(1.05, .16, 1.05), Color("d6c6aa"), game)
		for face in [-1.0, 1.0]:
			_zz_part(root, "Zoo arch paw", "box", Vector3(x, 1.7, 126.0 + face * .465), Vector3(.46, .46, .03), Color("8a5f3c"), game)
		_zz_part(root, "Zoo arch lantern", "box", Vector3(-78.0 + side * 2.75, 3.12, 126.0), Vector3(.16, .28, .16), Color("3d3a36"), game)
		_zz_part(root, "Streetlight lamp", "sphere", Vector3(-78.0 + side * 2.75, 3.4, 126.0), Vector3(.34, .38, .34), Color("ffe6a8"), game)
		_zz_solid(root, "Zoo arch pillar solid", Vector3(x, 1.5, 126.0), Vector3(.9, 3.0, .9))
		var bed: float = -78.0 + side * 4.2
		_zz_part(root, "Zoo flower planter", "box", Vector3(bed, .2, 126.0), Vector3(2.2, .4, .9), Color("cdbb9c"), game)
		_zz_solid(root, "Zoo flower planter solid", Vector3(bed, .2, 126.0), Vector3(2.2, .4, .9))
		for k in range(3):
			_zz_plant(root, "rose_bush", Vector2(bed - .7 + .7 * k, 126.0), .4, .7, k * 1.3, k)
	var arch := []
	for i in range(9):
		var t := i / 8.0
		arch.append(Vector2(-80.3 + 4.6 * t, 2.85 + sin(PI * t)))
	for i in range(8):
		var a: Vector2 = arch[i]
		var b: Vector2 = arch[i + 1]
		var segment := _zz_part(root, "Zoo arch beam", "box", Vector3((a.x + b.x) * .5, (a.y + b.y) * .5, 126.0), Vector3(a.distance_to(b) + .06, .32, .5), Color("8a5a36"), game)
		segment.rotation.z = atan2(b.y - a.y, b.x - a.x)
	_zz_part(root, "Zoo arch board", "box", Vector3(-78.0, 3.5, 126.32), Vector3(3.0, .75, .1), Color("f3ead8"), game)
	_zz_label(root, "Zoo arch name", "THE ZOO", Vector3(-78.0, 3.5, 126.38), .5, Color("6b4226"), Color("f3ead8"))
	for at in [Vector2(-98.0, 123.6), Vector2(-85.0, 123.6), Vector2(-71.0, 123.6), Vector2(-57.5, 123.6)]:
		_zz_plant(root, "shrub", at, .135, .8, rng.randf() * TAU, rng.randi() % 3)
	for at in [Vector2(-95.5, 123.7), Vector2(-88.5, 123.7), Vector2(-67.5, 123.7), Vector2(-60.5, 123.7)]:
		_zz_plant(root, "rose_bush", at, .135, .8, rng.randf() * TAU, rng.randi() % 3)
	_zz_savanna(root, game, layout, rng)
	_zz_forest(root, game, rng)
	_zz_bamboo(root, game, rng)
	_zz_plains(root, game, layout, rng)
	# Animals to their zones, facing the visitors (+Z); soles on the zone ground.
	for name: String in ZONE_HOMES:
		var animal: Node3D = zoo.get_node(name)
		animal.position = Vector3(ZONE_HOMES[name].x, animal.position.y + .015, ZONE_HOMES[name].y)
		animal.rotation.y = 0.0
		animal.set("home", animal.position)
	print("ZOO ZONES: %d scenery nodes, %d animals placed" % [root.find_children("*", "", true, false).size(), ZONE_HOMES.size()])

## Savanna: two flat-crowned trees (oaks, low), the rock cave at the back, a pond with a
## waterfall at the front-west corner, grass tufts and rocks.
func _zz_savanna(root: Node3D, game, layout, rng: RandomNumberGenerator) -> void:
	for at in [Vector2(-99.3, 87.2), Vector2(-82.6, 86.4)]:
		_zz_plant(root, "oak", at, .135, .5, rng.randf() * TAU, 0)
	for rock in [[Vector3(-89.4, .9, 85.9), Vector3(3.0, 2.6, 2.6)], [Vector3(-85.9, 1.0, 85.7), Vector3(3.2, 3.0, 2.6)],
			[Vector3(-87.6, 1.9, 86.0), Vector3(2.8, 2.2, 2.2)]]:
		_zz_part(root, "Zoo cave rock", "sphere", rock[0], rock[1], ZOO_ROCKS[rng.randi() % 3], game, rng.randf() * TAU)
	_zz_part(root, "Zoo cave mouth", "sphere", Vector3(-87.6, .55, 87.1), Vector3(1.4, 1.6, .5), Color("3a332d"), game)
	_zz_solid(root, "Zoo cave solid", Vector3(-87.6, .8, 85.8), Vector3(5.2, 1.6, 2.4))
	_zz_pond(root, game, layout, Vector3(-98.4, .155, 98.8), 2.7, 2.1, rng)
	_zz_waterfall(root, game, Vector2(-99.6, 96.3), 1.1, 1.8, rng)
	for at in [Vector2(-90.0, 92.0), Vector2(-97.5, 90.0), Vector2(-83.5, 93.0), Vector2(-92.5, 100.3)]:
		_zz_rocks(root, game, at, 2, .9, rng)
	for at in [Vector2(-96.0, 86.2), Vector2(-90.5, 93.6), Vector2(-83.0, 91.0), Vector2(-94.5, 99.2), Vector2(-87.8, 100.4), Vector2(-100.6, 91.5)]:
		_zz_plant(root, "fern", at, .135, .8, rng.randf() * TAU, rng.randi() % 3)

## Forest: pines along the back, an oak, a fallen log, a stump, roses and ferns.
func _zz_forest(root: Node3D, game, rng: RandomNumberGenerator) -> void:
	for x in [-73.8, -70.0, -66.4, -62.5, -58.6, -55.6]:
		_zz_plant(root, "pine", Vector2(x, 85.9 + rng.randf_range(-.3, .3)), .135, rng.randf_range(.5, .62), rng.randf() * TAU, rng.randi() % 3)
	_zz_plant(root, "oak", Vector2(-56.2, 90.2), .135, .45, rng.randf() * TAU, 1)
	var log_node := _zz_part(root, "Forest log", "cylinder", Vector3(-62.0, .45, 100.0), Vector3(.64, 2.2, .64), Color("7a5236"), game)
	log_node.rotation.z = PI * .5
	var log_end := _zz_part(root, "Forest log end", "cylinder", Vector3(-60.88, .45, 100.0), Vector3(.5, .03, .5), Color("c79c6b"), game)
	log_end.rotation.z = PI * .5
	_zz_solid(root, "Forest log solid", Vector3(-62.0, .45, 100.0), Vector3(2.2, .64, .64))
	_zz_part(root, "Forest stump", "cylinder", Vector3(-73.6, .4, 89.0), Vector3(.9, .55, .9), Color("7a5236"), game)
	_zz_solid(root, "Forest stump solid", Vector3(-73.6, .4, 89.0), Vector3(.9, .55, .9), 0.0, true)
	for at in [Vector2(-74.6, 94.0), Vector2(-74.6, 91.4), Vector2(-55.2, 100.6), Vector2(-68.0, 100.7)]:
		_zz_plant(root, "rose_bush", at, .135, .8, rng.randf() * TAU, rng.randi() % 3)
	for at in [Vector2(-60.2, 87.8), Vector2(-71.5, 88.6), Vector2(-66.5, 99.9)]:
		_zz_plant(root, "fern", at, .135, .9, rng.randf() * TAU, rng.randi() % 3)
	_zz_rocks(root, game, Vector2(-55.6, 93.0), 3, 1.0, rng)

## Bamboo grove: dense stalks along the back and the west fence (clear of the walk-in gap and
## the animals' ranges), a wooden platform for the red panda, rocks and ferns.
func _zz_bamboo(root: Node3D, game, rng: RandomNumberGenerator) -> void:
	var spots := []
	for row in [107.2, 108.2, 109.1]:
		var x := -101.1
		while x < -81.8:
			if x < -91.3 or x > -86.7:
				spots.append(Vector2(x + rng.randf_range(-.15, .15), row + rng.randf_range(-.2, .2)))
			x += rng.randf_range(.5, .8)
	for column in [-101.1, -100.2]:
		var z := 110.0
		while z < 122.0:
			spots.append(Vector2(column + rng.randf_range(-.15, .15), z))
			z += rng.randf_range(.5, .8)
	var greens := [Color("9fc64e"), Color("8bb843"), Color("b0cf5e")]
	var leaves := [Color("6fa83a"), Color("7fb847"), Color("5f9a33")]
	for at: Vector2 in spots:
		var h := rng.randf_range(2.8, 4.4)
		_zz_part(root, "Bamboo stalk", "cylinder", Vector3(at.x, .13 + h * .5, at.y), Vector3(.13, h, .13), greens[rng.randi() % 3], game)
		# Upright leaf tufts: one crowning the stalk, two smaller ones on alternate sides lower down.
		var side := rng.randf() * TAU
		_zz_part(root, "Bamboo leaves", "sphere", Vector3(at.x, .13 + h - .15, at.y), Vector3(.5, .85, .5) * rng.randf_range(.85, 1.15), leaves[rng.randi() % 3], game, side)
		for k in range(2):
			var a := side + PI * k
			_zz_part(root, "Bamboo leaves", "sphere", Vector3(at.x + cos(a) * .22, .13 + h * (.72 - .17 * k), at.y + sin(a) * .22),
				Vector3(.42, .55, .3), leaves[rng.randi() % 3], game, -a)
	# Red panda platform (top 0.85).
	_zz_part(root, "Bamboo platform top", "box", Vector3(-84.6, .8, 112.0), Vector3(2.4, .1, 1.1), Color("a0714a"), game)
	for leg in [Vector2(-1.05, -.4), Vector2(1.05, -.4), Vector2(-1.05, .4), Vector2(1.05, .4)]:
		_zz_part(root, "Bamboo platform leg", "box", Vector3(-84.6 + leg.x, .45, 112.0 + leg.y), Vector3(.14, .65, .14), Color("8a5f3c"), game)
	_zz_solid(root, "Bamboo platform solid", Vector3(-84.6, .5, 112.0), Vector3(2.4, .7, 1.1))
	_zz_rocks(root, game, Vector2(-98.8, 121.0), 3, 1.2, rng)
	_zz_rocks(root, game, Vector2(-90.5, 121.4), 2, .8, rng)
	for at in [Vector2(-97.5, 111.0), Vector2(-82.0, 121.6), Vector2(-91.0, 110.8)]:
		_zz_plant(root, "fern", at, .135, 1.0, rng.randf() * TAU, rng.randi() % 3)

## Wildlife plains: pond with a waterfall at the back-east corner (the flamingo wades there),
## rocks, ferns, shrubs and roses along the fences.
func _zz_plains(root: Node3D, game, layout, rng: RandomNumberGenerator) -> void:
	_zz_pond(root, game, layout, Vector3(-58.8, .155, 110.5), 3.0, 2.1, rng)
	_zz_waterfall(root, game, Vector2(-57.4, 107.5), 1.1, 1.7, rng)
	for at in [Vector2(-74.0, 121.3), Vector2(-62.5, 108.0), Vector2(-74.2, 108.4)]:
		_zz_rocks(root, game, at, 2, 1.0, rng)
	for at in [Vector2(-55.3, 121.5), Vector2(-55.3, 116.0), Vector2(-69.8, 107.4), Vector2(-74.6, 114.5)]:
		_zz_plant(root, "fern", at, .135, 1.1, rng.randf() * TAU, rng.randi() % 3)
	for at in [Vector2(-74.6, 117.5), Vector2(-66.0, 121.8)]:
		_zz_plant(root, "shrub", at, .135, .9, rng.randf() * TAU, rng.randi() % 3)
	for at in [Vector2(-74.6, 111.5), Vector2(-62.0, 121.9)]:
		_zz_plant(root, "rose_bush", at, .135, .8, rng.randf() * TAU, rng.randi() % 3)

## One visible part under `parent`: a shared box mesh, or a unit sphere/cylinder scaled to `size`.
func _zz_part(parent: Node3D, label: String, kind: String, pos: Vector3, size: Vector3, tint: Color, game, turn := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	if kind == "box":
		node.mesh = game.shared_box_mesh(size)
	else:
		if not _zz_units.has(kind):
			var unit: PrimitiveMesh
			if kind == "sphere":
				unit = SphereMesh.new()
				unit.radius = .5
				unit.height = 1.0
				unit.radial_segments = 14
				unit.rings = 7
			else:
				unit = CylinderMesh.new()
				unit.top_radius = .5
				unit.bottom_radius = .5
				unit.height = 1.0
				unit.radial_segments = 12
			_zz_units[kind] = unit
		node.mesh = _zz_units[kind]
		node.scale = size
	node.position = pos
	node.rotation.y = turn
	node.material_override = game.material_for(tint)
	parent.add_child(node, true)
	return node

## Invisible movement collision (box, or an upright cylinder of the box's x/y size).
func _zz_solid(parent: Node3D, label: String, pos: Vector3, size: Vector3, turn := 0.0, upright := false) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.rotation.y = turn
	var shape := CollisionShape3D.new()
	if upright:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = size.x * .5
		cylinder.height = size.y
		shape.shape = cylinder
	else:
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
	body.add_child(shape)
	parent.add_child(body, true)

## Zone fence from a to b (zoo-local x, z): two rails, posts about every 2.5 units, one solid.
func _zz_fence(parent: Node3D, game, a: Vector2, b: Vector2, wood: Color) -> void:
	var d := b - a
	var turn := atan2(-d.y, d.x)
	var mid := (a + b) * .5
	for h in [.49, .99]:
		_zz_part(parent, "Zone fence rail", "box", Vector3(mid.x, h, mid.y), Vector3(d.length(), .1, .1), wood, game, turn)
	var posts := maxi(1, ceili(d.length() / 2.5))
	for i in range(posts + 1):
		var p := a + d * (float(i) / posts)
		_zz_part(parent, "Zone fence post", "box", Vector3(p.x, .6, p.y), Vector3(.16, 1.2, .16), wood.darkened(.12), game, turn)
	_zz_solid(parent, "Zone fence solid", Vector3(mid.x, .55, mid.y), Vector3(d.length(), 1.1, .24), turn)

## Zone name board on two posts, facing the visitors (+Z); English source text, translated at load.
func _zz_sign(parent: Node3D, game, text: String, at: Vector2) -> void:
	var width := 3.6
	_zz_part(parent, "Zone sign board", "box", Vector3(at.x, 1.3, at.y), Vector3(width, .78, .1), Color("6b4a2f"), game)
	for side in [-1.0, 1.0]:
		_zz_part(parent, "Zone sign post", "box", Vector3(at.x + side * (width * .5 - .3), .6, at.y - .1), Vector3(.12, 1.2, .12), Color("5a3d26"), game)
	_zz_label(parent, "Zone sign " + text, text, Vector3(at.x, 1.3, at.y + .065), .42, Color("fff3d6"), Color("3b2614"))

func _zz_label(parent: Node3D, label: String, text: String, pos: Vector3, height: float, tint: Color, outline: Color) -> void:
	var sign := Label3D.new()
	sign.name = label
	sign.text = text
	sign.font_size = 64
	sign.pixel_size = height / 64.0
	sign.outline_size = 10
	sign.outline_modulate = outline
	sign.modulate = tint
	sign.position = pos
	parent.add_child(sign, true)

## Lamp post with a globe named like the street lamps, so day_night.gd lights it at night.
func _zz_lamp(parent: Node3D, game, at: Vector2) -> void:
	_zz_part(parent, "Zoo lamp post", "cylinder", Vector3(at.x, 1.4, at.y), Vector3(.14, 2.6, .14), Color("3d3a36"), game)
	_zz_part(parent, "Zoo lamp cap", "box", Vector3(at.x, 3.0, at.y), Vector3(.36, .08, .36), Color("3d3a36"), game)
	_zz_part(parent, "Streetlight lamp", "sphere", Vector3(at.x, 2.8, at.y), Vector3(.32, .36, .32), Color("ffe6a8"), game)

func _zz_rocks(parent: Node3D, game, at: Vector2, count: int, size: float, rng: RandomNumberGenerator) -> void:
	for i in range(count):
		var s := size * rng.randf_range(.6, 1.0)
		var off := Vector2(rng.randf_range(-.6, .6), rng.randf_range(-.6, .6)) * size
		_zz_part(parent, "Zoo rock", "sphere", Vector3(at.x + off.x, .13 + s * .22, at.y + off.y), Vector3(s, s * .7, s * .85), ZOO_ROCKS[rng.randi() % 3], game, rng.randf() * TAU)

func _zz_plant(parent: Node3D, scene: String, at: Vector2, y: float, size: float, turn := 0.0, profile := -1) -> void:
	var node: Node3D = load("res://scenes/props/nature/species/%s.tscn" % scene).instantiate()
	node.position = Vector3(at.x, y, at.y)
	node.scale = Vector3.ONE * size
	node.rotation.y = turn
	if profile >= 0:
		node.set("profile", profile)
	parent.add_child(node, true)

## Flat water oval (no collision: animals may wade) with a ring of small rim rocks.
func _zz_pond(parent: Node3D, game, layout, centre: Vector3, rx: float, rz: float, rng: RandomNumberGenerator) -> void:
	_zz_oval(layout, parent, "Zoo pond", centre, rx, rz, Color("79c3dc"))
	for i in range(14):
		var a := TAU * i / 14.0 + rng.randf_range(-.1, .1)
		var s := rng.randf_range(.35, .6)
		_zz_part(parent, "Zoo pond rock", "sphere", Vector3(centre.x + cos(a) * (rx + .1), .15, centre.z + sin(a) * (rz + .1)), Vector3(s, s * .55, s * .8), ZOO_ROCKS[i % 3], game, a)

func _zz_oval(layout, parent: Node3D, label: String, centre: Vector3, rx: float, rz: float, tint: Color) -> void:
	var points := PackedVector3Array()
	var outline := PackedVector2Array()
	for i in range(40):
		var a := TAU * i / 40.0
		points.append(centre + Vector3(cos(a) * rx, 0, sin(a) * rz))
		outline.append(Vector2(points[i].x, points[i].z))
	var node: MeshInstance3D = layout.surface(label, points, Geometry2D.triangulate_polygon(outline), tint)
	node.reparent(parent)

## Rock pile with a falling-water sheet facing +Z (scrolling stripes, one shared shader) and foam.
func _zz_waterfall(parent: Node3D, game, at: Vector2, width: float, height: float, rng: RandomNumberGenerator) -> void:
	for i in range(4):
		var s := Vector3(rng.randf_range(1.1, 1.5), height * rng.randf_range(.8, 1.2), 1.4)
		_zz_part(parent, "Waterfall rock", "sphere", Vector3(at.x + (i - 1.5) * .75, s.y * .45, at.y - .55), s, ZOO_ROCKS[i % 3], game, rng.randf() * TAU)
	_zz_part(parent, "Waterfall rock", "sphere", Vector3(at.x, height + .1, at.y - .6), Vector3(1.6, .7, 1.2), ZOO_ROCKS[1], game)
	if _zz_falls == null:
		var shader := Shader.new()
		shader.code = "shader_type spatial;\nrender_mode cull_disabled;\nvoid fragment() {\n\tfloat s = fract(UV.y * 3.0 - TIME * 1.1 + sin(UV.x * 18.0) * 0.07);\n\tALBEDO = mix(vec3(0.42, 0.74, 0.9), vec3(0.93, 0.98, 1.0), smoothstep(0.55, 0.95, s));\n\tROUGHNESS = 0.2;\n}\n"
		_zz_falls = ShaderMaterial.new()
		_zz_falls.shader = shader
	var sheet := MeshInstance3D.new()
	sheet.name = "Waterfall"
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	sheet.mesh = quad
	sheet.material_override = _zz_falls
	sheet.position = Vector3(at.x, .15 + height * .5, at.y + .2)
	parent.add_child(sheet, true)
	for i in range(3):
		_zz_part(parent, "Waterfall foam", "sphere", Vector3(at.x + (i - 1) * .4, .17, at.y + .45), Vector3(.55, .16, .45), Color("eef8fb"), game)
	_zz_solid(parent, "Waterfall solid", Vector3(at.x, .8, at.y - .55), Vector3(3.0, 1.6, 1.4))

## Transform of `node` in `ancestor`'s space, out of the tree.
func _local_to(ancestor: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node
	while current != ancestor and current != null:
		result = (current as Node3D).transform * result
		current = current.get_parent()
	return result

## Bigger home (12 Nov 2026, home step `house_expansion`, scripts/buildings/home_expansion.gd): the
## pool moved POOL_SHIFT east, so the ground is cut under its new opening (the old opening is
## covered by the home's solid terrace slabs, hot tub and guest-suite floor); the Home site bounds
## grow east to the new wing (town x -11.72..26.72).
func home_expansion_ground(town: Node3D, game) -> void:
	var home: Node3D = town.get_node_or_null("RelocatedSites/Home")
	if home == null:
		push_error("base.gd home_expansion_ground: the home unit is not loaded")
		return
	var r: Rect2 = preload("res://scripts/buildings/home_expansion.gd").POOL_OPENING
	var corners := PackedVector3Array([Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y)])
	var changed: int = preload("res://scripts/buildings/ground_cut.gd").cut_layers(town, home, corners)
	var bounds: AABB = game.reference_layout.site_bounds["Home"]
	bounds.size.x = 26.72 - bounds.position.x
	game.reference_layout.site_bounds["Home"] = bounds
	print("home_expansion_ground: cut %d ground meshes; Home bounds %s" % [changed, bounds])

## A 5 x 2 grey street pad that led up to the old home's west side (town x -15..-10, z -0.87..1.13)
## now runs 0.9 under the guest-suite bathroom's outer wall and shows as a dark slab on its tiled
## floor (13 Nov 2026): shorten it to stop at the wall's outside face (x -11.09).
func home_side_pad_trim(town: Node3D, game) -> void:
	var home: Node3D = town.get_node_or_null("RelocatedSites/Home")
	var street: Node3D = town.get_node_or_null("Street")
	if home == null or street == null:
		push_error("base.gd home_side_pad_trim: the home unit or the street is not loaded")
		return
	var inv: Transform3D = home.global_transform.affine_inverse()
	var stop := -11.09
	var count := 0
	for mesh in street.find_children("*", "MeshInstance3D", true, false):
		var local: Transform3D = inv * (mesh as MeshInstance3D).global_transform
		var box: AABB = local * (mesh as MeshInstance3D).get_aabb()
		if not (box.size.y < .1 and absf(box.size.x - 5.0) < .1 and absf(box.size.z - 2.0) < .1): continue
		if not (absf(box.position.x + 15.0) < .1 and absf(box.position.z + .87) < .1): continue
		var k := (stop - box.position.x) / box.size.x
		var squeeze := Transform3D(Basis.from_scale(Vector3(k, 1, 1)), Vector3(box.position.x * (1.0 - k), 0, 0))
		(mesh as MeshInstance3D).global_transform = home.global_transform * squeeze * local
		count += 1
	print("home_side_pad_trim: trimmed %d pad(s) to x %.2f" % [count, stop])

## The Washington statue becomes the word "statue" (12 Nov 2026, PWA restructure phase 6: the
## welcome tutorial teaches it): the word on its root, so a click anywhere on the horse, rider
## or pedestal shows the card. Words already on its parts are listed (they would win a click).
func statue_word(town: Node3D, _game) -> void:
	var statue: Node3D = town.get_node("WashingtonStatue")
	statue.set_meta("word_key", "statue")
	for part in statue.find_children("*", "Node3D", true, false):
		if part.has_meta("word_key"):
			print("statue_word: %s keeps its word '%s'" % [statue.get_path_to(part), part.get_meta("word_key")])

## Clay zoo animals saved as plain nodes, not instances of scenes/animals/*_clay.* (13 Nov 2026,
## user: smaller web download). base.scn already stores each one's meshes and materials (the
## colour steps swap them in), so loading the clay scene only to replace its meshes cost the web
## pack 33 MB; tools/deploy_web.py leaves those files out (export_presets.cfg exclude_filter) and
## refuses a build whose town scenes still name one. A later step that places a clay scene must
## call unpack_clay_animals() too. Same nodes, names, transforms, meshes and Footprint bodies.
func clay_animals_unpacked(town: Node3D, _game) -> void:
	unpack_clay_animals(town)

static func unpack_clay_animals(town: Node3D) -> void:
	var count := 0
	for node in town.get_node("ParkZoo").find_children("*", "", true, false):
		var source: String = node.scene_file_path
		if not (source.begins_with("res://scenes/animals/") and source.get_file().get_basename().ends_with("_clay")):
			continue
		node.scene_file_path = ""
		for part in node.find_children("*", "", true, false):
			part.owner = town
		count += 1
		print("clay_animals_unpacked: %s (was %s)" % [town.get_path_to(node), source.get_file()])
	print("clay_animals_unpacked: %d clay animal(s) stored as plain nodes" % count)

## Parked vehicles (user, 14 Nov 2026; docs/guides/ZOO_VEHICLE_IMPLEMENTATION.md#more-parked-vehicles--14-november-2026):
## every front parking lot has at least one car and one motorcycle (the police car and the airport
## taxi count as the car there), plus five vehicles
## parked by the loop road. Each is a real DriveableVehicle prefab under Vehicles/, so Main
## registers it like the others. Lot spots are the painted bays next to each lot's entrance
## aisle (nose in toward the end line), found free of bodies, figures and other vehicles by a
## scratch scan (docs/evidence/town-checks/check_vehicle_arcade.gd checks them); road spots sit 4 town units off the centre line in the
## travel direction, away from crossings and drives. Positions are each body's centre (town
## coordinates); cars take one of a few paints (shared materials) so the lots don't all match.
const PARKED_VEHICLES := [
	# [name, prefab, body centre (town), yaw degrees, paint]
	["Parked car (hospital)", "car", Vector3(61.5, 0.055, 211.5), 90, "red"],
	["Parked motorcycle (hospital)", "motorcycle", Vector3(50.5, 0.055, 211.5), 90, ""],
	["Parked car (school)", "car", Vector3(15.5, 0.055, 213.5), 90, "silver"],
	["Parked motorcycle (school)", "motorcycle", Vector3(4.5, 0.055, 213.5), 90, ""],
	["Parked car (east delivery)", "car", Vector3(-127.5, 0.055, 123.5), 0, "white"],
	["Parked motorcycle (east delivery)", "motorcycle", Vector3(-127.5, 0.055, 106.5), 0, ""],
	["Parked motorcycle (police)", "motorcycle", Vector3(-128.0, 0.055, 79.5), 0, ""],
	["Parked motorcycle (airport)", "motorcycle", Vector3(-82.5, 0.055, 222.5), 90, ""],
	["Parked car (furniture)", "car", Vector3(131.5, 0.1, 219.5), 90, "green"],
	["Parked motorcycle (furniture)", "motorcycle", Vector3(120.5, 0.1, 219.5), 90, ""],
	["Parked car (sports)", "car", Vector3(101.5, 0.1, 223.5), 90, ""],
	["Parked motorcycle (sports)", "motorcycle", Vector3(90.5, 0.1, 223.5), 90, ""],
	["Parked car (bakery)", "car", Vector3(120.5, 0.1, 160.5), 180, "red"],
	["Parked motorcycle (bakery)", "motorcycle", Vector3(120.5, 0.1, 171.5), 180, ""],
	["Parked car (electronics)", "car", Vector3(119.5, 0.1, 131.5), 180, "black"],
	["Parked motorcycle (electronics)", "motorcycle", Vector3(119.5, 0.1, 142.5), 180, ""],
	["Parked car (bank)", "car", Vector3(120.5, 0.1, 102.5), 180, "silver"],
	["Parked motorcycle (bank)", "motorcycle", Vector3(120.5, 0.1, 113.5), 180, ""],
	["Parked car (clothing)", "car", Vector3(-124.5, 0.1, 169.5), 0, "white"],
	["Parked motorcycle (clothing)", "motorcycle", Vector3(-124.5, 0.1, 158.5), 0, ""],
	["Parked car (restaurants)", "car", Vector3(-50.5, 0.1, 47.5), -90, "green"],
	["Parked motorcycle (restaurants)", "motorcycle", Vector3(-39.5, 0.1, 47.5), -90, ""],
	["Parked car (library)", "car", Vector3(45.5, 0.1, 47.5), -90, "red"],
	["Parked motorcycle (library)", "motorcycle", Vector3(56.5, 0.1, 47.5), -90, ""],
	# Warehouse lot: the two west bays of the west group (warehouse-local x 11.5 and 5.5), clear of
	# the truck corridors from loading bays A and B (local x -8.2..2.6 with the apron), the drive
	# (local x -3.4..3.4) and the walk to the entrance (local x -12.2); redesign of 14 Nov 2026.
	["Parked car (warehouse)", "car", Vector3(-23.5, 0.06, 212.5), 90, "silver"],
	["Parked motorcycle (warehouse)", "motorcycle", Vector3(-29.5, 0.06, 212.5), 90, ""],
	["Road-side car (north east)", "car", Vector3(82.5, 0.06, 196.0), 0, "white"],
	["Road-side car (north west)", "car", Vector3(-55.5, 0.06, 196.0), 0, "black"],
	["Road-side car (west)", "car", Vector3(-108.0, 0.06, 106.38), -90, "silver"],
	["Road-side car (south)", "car", Vector3(-31.5, 0.06, 69.0), 180, ""],
	["Road-side motorcycle (east)", "motorcycle", Vector3(99.0, 0.06, 151.16), 90, ""],
]
## Car paints (car.tscn is "Blue metallic paint"; "" keeps it).
const PARKED_PAINTS := {"red": Color(0.66, 0.13, 0.12), "silver": Color(0.62, 0.64, 0.66), "white": Color(0.9, 0.9, 0.87), "green": Color(0.2, 0.4, 0.3), "black": Color(0.09, 0.1, 0.11)}

func parked_vehicles(town: Node3D, _game) -> void:
	var parent: Node3D = town.get_node("Vehicles")
	var paints := {}
	for spec in PARKED_VEHICLES:
		var vehicle: Node3D = load("res://scenes/props/vehicles/%s.tscn" % spec[1]).instantiate()
		vehicle.name = spec[0]
		# The body's centre (its StudyArea boxes, model units) goes on the spot.
		var bounds := AABB()
		var first := true
		for collider in vehicle.get_node("StudyArea").get_children():
			if collider is CollisionShape3D and collider.shape is BoxShape3D:
				var box: AABB = collider.transform * AABB(-collider.shape.size * 0.5, collider.shape.size)
				bounds = box if first else bounds.merge(box)
				first = false
		var basis := Basis(Vector3.UP, deg_to_rad(spec[3]))
		var centre: Vector3 = bounds.get_center()
		var spot: Vector3 = spec[2] - basis * Vector3(centre.x, 0, centre.z)
		vehicle.transform = parent.transform.affine_inverse() * Transform3D(basis, spot)
		# Paint before it enters the tree: _ready cuts the door shells from the painted body.
		if spec[4] != "":
			if not paints.has(spec[4]):
				var paint: StandardMaterial3D = null
				for mesh in vehicle.find_children("*", "MeshInstance3D", true, false):
					if mesh.material_override != null and mesh.material_override.resource_name == "Blue metallic paint":
						paint = mesh.material_override.duplicate()
						break
				paint.albedo_color = PARKED_PAINTS[spec[4]]
				paint.resource_name = String(spec[4]).capitalize() + " metallic paint"
				paints[spec[4]] = paint
			for mesh in vehicle.find_children("*", "MeshInstance3D", true, false):
				if mesh.material_override != null and mesh.material_override.resource_name == "Blue metallic paint":
					mesh.material_override = paints[spec[4]]
			# The lower body is a CSG shape painted through its own material.
			for shape in vehicle.find_children("*", "CSGShape3D", true, false):
				if shape.material != null and shape.material.resource_name == "Blue metallic paint":
					shape.material = paints[spec[4]]
		parent.add_child(vehicle)
		vehicle.owner = town
	print("parked_vehicles: %d vehicles added under Vehicles" % PARKED_VEHICLES.size())

## The walk from the warehouse lot to the entrance (map ribbon "Warehouse entrance connection",
## town x -36.6..-33.4) led to the old entrance at warehouse-local x 0, now loading bay B's apron.
## The warehouse redesign (14 Nov 2026, scripts/world/warehouse.gd ENTRANCE_X) put the glass
## entrance at local x -12.2 (town -47.2, the Warehouse root at town x -35, +X west), so the walk
## moves 12.2 east: straight from the lot's north edge to the entrance, between the canopy posts,
## clear of the loading apron and the truck corridors (local x -8.2..2.6).
const WAREHOUSE_WALK_SHIFT := -12.2

func warehouse_entrance_walk(town: Node3D, _game) -> void:
	var walk: MeshInstance3D = town.get_node("Warehouse entrance connection")
	var source: ArrayMesh = walk.mesh
	var moved := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			vertices[i].x += WAREHOUSE_WALK_SHIFT
		arrays[Mesh.ARRAY_VERTEX] = vertices
		moved.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays)
		moved.surface_set_material(surface, source.surface_get_material(surface))
	walk.mesh = moved
	print("warehouse_entrance_walk: ", walk.get_aabb())


## The east delivery lot's parked car stood 2 m (at its door) from the player's default start on
## the supermarket walk (main.gd spawn_position()), so the first E or tap boarded it (found by the
## touch-controls check, 14 Nov 2026). It moves one bay south in the same row: its door is then
## 5.6 m away, past the 5.2 m boarding reach (vehicle_controls.gd BOARD_DISTANCE); the next bays
## south are on the lot's drive or taken by the truck.
func spawn_clear_car(town: Node3D, _game) -> void:
	var car := town.get_node("Vehicles/Parked car (east delivery)") as Node3D
	var parent := car.get_parent() as Node3D
	var place := parent.transform * car.transform  # town frame, as in parked_vehicles()
	place.origin.z -= 3.4                         # town units: one bay
	car.transform = parent.transform.affine_inverse() * place

## Lighter clay zoo animals (16 Nov 2026, docs/guides/ANIMAL_SYSTEM.md#clay-file-sizes-16-nov-2026):
## the clay builds now write each part's mesh to its own compressed file
## (tools/clay_save.gd, scenes/animals/clay_meshes/<animal>/<part>.res: compressed vertex
## attributes, distance LODs). Each zoo model (`ParkZoo/<Name>/Clay<Name>`, plain nodes since
## `clay_animals_unpacked`) takes those meshes in place of the copies base.scn embedded, part by
## part by name; nodes, transforms, materials and bodies stay. base.scn then names the mesh files,
## so a rebuilt clay animal reaches the zoo without a new step.
func clay_meshes_external(town: Node3D, _game) -> void:
	var zoo: Node3D = town.get_node("ParkZoo")
	var animals := {"Lion": "lion"}
	for name: String in CLAY_REPLACEMENTS:
		animals[name] = CLAY_REPLACEMENTS[name][0]
	for name: String in CLAY_NEW_SPECIES:
		animals[name] = CLAY_NEW_SPECIES[name][0]
	for name: String in animals:
		var model: Node3D = zoo.get_node("%s/Clay%s" % [name, name.replace(" ", "")])
		var path := "res://scenes/animals/%s_clay.tscn" % animals[name]
		if not ResourceLoader.exists(path):
			path = path.get_basename() + ".scn"
		var source: Node3D = load(path).instantiate()
		var swapped := 0
		for part: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
			var target := model.get_node(source.get_path_to(part)) as MeshInstance3D
			assert(target != null and part.mesh.resource_path.begins_with("res://scenes/animals/clay_meshes/"))
			target.mesh = part.mesh
			swapped += 1
		source.free()
		print("clay_meshes_external: %s takes %d part meshes from %s" % [town.get_path_to(model), swapped, path.get_file()])

## The zoo pig walks with moving legs (user, 16 Nov 2026, approving the pilot in
## docs/guides/ANIMAL_SYSTEM.md#clay-animal-animation-pilot-16-nov-2026): its static clay model
## `ParkZoo/Pig/ClayPig` is replaced by the skinned rig scenes/animals/pig_clay_rigged.scn (same
## model space, name and transform; Footprint body off as in _clay_roamer). The rig stays an
## instance, so a rebuilt rig (tools/build_pig_clay_rig.gd) reaches the zoo without a new step; it
## is not a `*_clay` scene, so unpack_clay_animals() and the web export filter leave it alone.
## Its ClayAnimator walks it from park_animals.gd's movement; Main's clay_life blinks it.
func pig_clay_walks(town: Node3D, _game) -> void:
	_clay_walker(town, "Pig", "pig")

## Every other clay zoo animal walks too (user, 16 Nov 2026: "can you do it to all the other
## animals?"): the same swap as `pig_clay_walks` for the lion and the clay animals of
## `clay_animals_roam`, each to its rig scenes/animals/<prefab>_clay_rigged.scn (built by
## tools/build_<prefab>_clay_rig.gd; record in docs/guides/ANIMAL_SYSTEM.md).
func clay_animals_walk(town: Node3D, _game) -> void:
	var animals := {"Lion": "lion"}
	for name: String in CLAY_REPLACEMENTS:
		animals[name] = CLAY_REPLACEMENTS[name][0]
	for name: String in CLAY_NEW_SPECIES:
		animals[name] = CLAY_NEW_SPECIES[name][0]
	animals.erase("Pig")
	for name: String in animals:
		_clay_walker(town, name, animals[name])

## The approved clay tiger (user, 17 Nov 2026: "rig it first then replace the zoo tiger", the
## same height as the zoo tiger) takes the place of the wandering ParkZoo/Tiger, the last wild
## animal still built from pieces: same name, home in Wildlife Plains, facing, child index, word
## and park_animals.gd wandering, with its soles at the old tiger's level. Its model is the rig
## scenes/animals/tiger_clay_rigged.scn (tools/build_tiger_clay_rig.gd), so it walks and blinks
## like the other clay animals. _clay_roamer sizes it to the species height; the zoo shows every
## animal DISPLAY_SCALE bigger (animals_bigger), so it is brought to that here.
func tiger_clay_walks(town: Node3D, _game) -> void:
	var Animals = preload("res://scripts/world/park_animals.gd")
	var zoo: Node3D = town.get_node("ParkZoo")
	var old: Node3D = zoo.get_node("Tiger")
	var home: Vector3 = old.get("home") if old.get("home") is Vector3 and old.get("home") != Vector3.ZERO else old.position
	var old_box: AABB = old.call("_visible_bounds")
	var sole_y: float = home.y + old_box.position.y * old.scale.y
	print("TIGER CLAY WALKS: old tiger height %.3f, soles at %.3f" % [old_box.size.y * old.scale.y, sole_y])
	_clay_roamer(zoo, "Tiger", str(old.get_meta("word_key")), "tiger", Vector3(home.x, sole_y, home.z), old.rotation.y, old.get_index(), [old])
	var animal: Node3D = zoo.get_node("Tiger")
	var box: AABB = animal.call("_visible_bounds")
	var factor: float = Animals.display_height("Tiger", zoo.global_basis.get_scale().y) / (box.size.y * animal.scale.y)
	animal.scale *= factor
	animal.position = Vector3(home.x, sole_y - box.position.y * animal.scale.y, home.z)
	animal.set("home", animal.position)
	animal.set_meta("display_size", box.size * animal.scale)
	_clay_walker(town, "Tiger", "tiger")
	print("TIGER CLAY WALKS: height %.3f at %s" % [box.size.y * animal.scale.y, animal.position])

## The approved clay horse (user, 17 Nov 2026: "rig it and then replace the zoo horse", at the
## zoo horse's size, 2.4 town units: its species height times DISPLAY_SCALE) takes the place of
## the wandering ParkZoo/Horse on the farm, which was built from pieces: same name, home,
## facing, child index, word and park_animals.gd wandering, with its soles at the old horse's
## level. Its model is the rig scenes/animals/horse_clay_rigged.scn
## (tools/build_horse_clay_rig.gd), so it trots and blinks like the other clay animals. The same
## steps as `tiger_clay_walks`.
func horse_clay_walks(town: Node3D, _game) -> void:
	var Animals = preload("res://scripts/world/park_animals.gd")
	var zoo: Node3D = town.get_node("ParkZoo")
	var old: Node3D = zoo.get_node("Horse")
	var home: Vector3 = old.get("home") if old.get("home") is Vector3 and old.get("home") != Vector3.ZERO else old.position
	var old_box: AABB = old.call("_visible_bounds")
	var sole_y: float = home.y + old_box.position.y * old.scale.y
	print("HORSE CLAY WALKS: old horse height %.3f, soles at %.3f" % [old_box.size.y * old.scale.y, sole_y])
	_clay_roamer(zoo, "Horse", str(old.get_meta("word_key")), "horse", Vector3(home.x, sole_y, home.z), old.rotation.y, old.get_index(), [old])
	var animal: Node3D = zoo.get_node("Horse")
	var box: AABB = animal.call("_visible_bounds")
	var factor: float = Animals.display_height("Horse", zoo.global_basis.get_scale().y) / (box.size.y * animal.scale.y)
	animal.scale *= factor
	animal.position = Vector3(home.x, sole_y - box.position.y * animal.scale.y, home.z)
	animal.set("home", animal.position)
	animal.set_meta("display_size", box.size * animal.scale)
	_clay_walker(town, "Horse", "horse")
	print("HORSE CLAY WALKS: height %.3f at %s" % [box.size.y * animal.scale.y, animal.position])

## The clay capybara walks and blinks (user, 17 Nov 2026: "rig the capybara so it walks and
## blinks"; home: Wildlife Plains; a study word, `capybara`, added to data/words.json the same
## day). The still display ParkZoo/CapybaraClayDisplay on the strip inside the gate goes; a
## wandering ParkZoo/Capybara takes its place in Wildlife Plains, in the open front of the zone
## between the lion's and the tiger's homes, facing the gate, with its soles at the level of the
## zone's other animals. Its model is the rig scenes/animals/capybara_clay_rigged.scn
## (tools/build_capybara_clay_rig.gd). Shown at the species height times DISPLAY_SCALE like every
## zoo animal (about 0.975: park_animals.gd ANIMAL_HEIGHTS "Capybara"). The same steps as
## `tiger_clay_walks`.
func capybara_clay_walks(town: Node3D, _game) -> void:
	var Animals = preload("res://scripts/world/park_animals.gd")
	var zoo: Node3D = town.get_node("ParkZoo")
	var old: Node3D = zoo.get_node("CapybaraClayDisplay")
	var index := old.get_index()
	var tiger: Node3D = zoo.get_node("Tiger")
	var tiger_box: AABB = tiger.call("_visible_bounds")
	var sole_y: float = tiger.position.y + tiger_box.position.y * tiger.scale.y
	var home := Vector3(-67.8, sole_y, 120.0)
	_clay_roamer(zoo, "Capybara", "capybara", "capybara", home, 0.0, index, [old])
	var animal: Node3D = zoo.get_node("Capybara")
	var box: AABB = animal.call("_visible_bounds")
	var factor: float = Animals.display_height("Capybara", zoo.global_basis.get_scale().y) / (box.size.y * animal.scale.y)
	animal.scale *= factor
	animal.position = Vector3(home.x, sole_y - box.position.y * animal.scale.y, home.z)
	animal.set("home", animal.position)
	animal.set_meta("display_size", box.size * animal.scale)
	_clay_walker(town, "Capybara", "capybara")
	print("CAPYBARA CLAY WALKS: height %.3f at %s, soles at %.3f" % [box.size.y * animal.scale.y, animal.position, sole_y])

## Replaces ParkZoo/<name>/Clay<Name>, a static clay model, with an instance of its skinned rig
## (same model space, so the same name and transform; Footprint body off as in _clay_roamer).
## The rig stays an instance and names its mesh files, so base.scn grows only by the overrides.
func _clay_walker(town: Node3D, name: String, prefab: String) -> void:
	var animal: Node3D = town.get_node("ParkZoo/" + name)
	var model_name := "Clay" + name.replace(" ", "")
	var old: Node3D = animal.get_node(model_name)
	var before: AABB = animal.call("_visible_bounds")
	var place := old.transform
	var index := old.get_index()
	animal.remove_child(old)
	old.free()
	var model: Node3D = load("res://scenes/animals/%s_clay_rigged.scn" % prefab).instantiate()
	model.name = model_name
	model.transform = place
	var footprint := model.get_node("Footprint") as CollisionObject3D
	footprint.collision_layer = 0
	footprint.collision_mask = 0
	animal.add_child(model)
	animal.move_child(model, index)
	model.owner = town
	print("clay walker %s: bounds %s -> %s" % [name, before, animal.call("_visible_bounds")])

## Static study of the user's rooster turnaround (approved 17 Nov 2026):
## scenes/animals/rooster_clay.tscn (scripts/characters/rooster_clay.gd), a new display on the
## farm lawn, right of the path from the farm gate and in front of the hen's home, facing the
## gate, 0.6 town units to the top of the comb (as built; user's choice). No word, no wandering,
## no animation; the farm's own animals stay as they are. Stored as plain nodes
## (unpack_clay_animals), because the web export leaves the clay prefab scenes out.
func rooster_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/rooster_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(72.5, 0.12, 103.5)
	model.rotation.y = PI
	model.owner = town
	unpack_clay_animals(town)

## Static study of the user's capybara turnaround (approved 17 Nov 2026 after the rebuild as
## lofted masses): scenes/animals/capybara_clay.tscn (scripts/characters/capybara_clay.gd), a new
## display on the wild-animal lawn (user's choice), on the grass strip just inside the gate,
## east of the gate walk and in front of the WILDLIFE PLAINS fence (outside the zones, so no
## wanderer meets its footprint), turned to face the gate, 0.95 town units to the top of the
## head (the zoo pig's height; user's choice). No word, no wandering, no animation. Stored as
## plain nodes (unpack_clay_animals), because the web export leaves the clay prefab scenes out.
func capybara_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/capybara_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-72.8, 0.12, 124.4)
	var to_gate := Vector3(-78.0, 0.12, 126.0) - model.position
	model.rotation.y = atan2(-to_gate.x, -to_gate.z)
	model.owner = town
	unpack_clay_animals(town)

## Static study of the user's monkey turnaround (approved 17 Nov 2026 after the head was rebuilt
## as one lofted mass): scenes/animals/monkey_clay.tscn (scripts/characters/monkey_clay.gd), a
## new display on the grass strip just inside the zoo gate, west of the gate walk and in front of
## the BAMBOO GROVE fence (the zoo monkey's zone; the capybara's spot mirrored across the walk,
## outside the zones, so no wanderer meets its footprint), turned to face the gate, 0.85 town
## units to the top of the tuft (the zoo monkey's species height, park_animals.gd). The zoo's
## own Monkey stays as it is. No word, no wandering, no animation. Stored as plain nodes
## (unpack_clay_animals), because the web export leaves the clay prefab scenes out.
func monkey_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/monkey_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(-83.2, 0.12, 124.4)
	var to_gate := Vector3(-78.0, 0.12, 126.0) - model.position
	model.rotation.y = atan2(-to_gate.x, -to_gate.z)
	model.owner = town
	unpack_clay_animals(town)

## Static study of the user's chick turnaround (approved 18 Nov 2026 after the head, body, crown
## and wings were rebuilt): scenes/animals/chick_clay.tscn (scripts/characters/chick_clay.gd), a
## new display on the farm lawn beside the clay rooster (user's choice), 0.8 town units toward
## the farm gate from it and a little forward, facing the gate like the rooster, 0.4 town units
## to the top of the crown feathers (as built; user's choice). No word, no wandering, no
## animation; the farm's own animals stay as they are. Stored as plain nodes
## (unpack_clay_animals), because the web export leaves the clay prefab scenes out.
func chick_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/chick_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(71.7, 0.12, 103.8)
	model.rotation.y = PI
	model.owner = town
	unpack_clay_animals(town)

## The clay hen (approved 24 Nov 2026): the clay rooster tweaked toward the user's hen
## turnaround, scenes/animals/hen_clay.tscn (scripts/characters/hen_clay.gd). One display on the
## farm lawn with the clay rooster and chick, 0.8 town units past the chick on the same row (the
## chick's spacing from the rooster), facing the gate like them, 0.5 town units to the top of the
## comb (as built). No word, no wandering, no animation; the farm's own hens stay as they are.
## Stored as plain nodes (unpack_clay_animals), because the web export leaves the clay prefab
## scenes out.
func hen_clay_display(town: Node3D, _game) -> void:
	var model: Node3D = load("res://scenes/animals/hen_clay.tscn").instantiate()
	town.get_node("ParkZoo").add_child(model)
	model.position = Vector3(70.9, 0.12, 103.6)
	model.rotation.y = PI
	model.owner = town
	unpack_clay_animals(town)

## The supermarket's parking lot, where the welcome tutorial's market act starts (user, 18 Nov
## 2026): the white car moves south (to the player's right, clear of the store entrance): three
## bays from its first spot (spawn_clear_car already moved it one), since the next one is on the
## lot's drive (4.4 town units needed, 3 there); the delivery
## truck (Vehicles/Truck, a pickup) parks in the warehouse lot's west bay, half a unit west of the
## motorcycle's spot to clear the truck corridors,
## and every red motorcycle (motorcycle.tscn: the parked ones of parked_vehicles) leaves the map.
## BonBon's teal scooter (Vehicles/Motorcycle, scooter.tscn) stays: it is the town's motorcycle now.
const TRUCK_BAY := Vector3(-29.0, 0.06, 212.5)
const TRUCK_YAW := 90.0

func tutorial_lot_clear(town: Node3D, _game) -> void:
	var vehicles := town.get_node("Vehicles") as Node3D
	var car := vehicles.get_node("Parked car (east delivery)") as Node3D
	var place := vehicles.transform * car.transform
	place.origin.z -= 10.2
	car.transform = vehicles.transform.affine_inverse() * place
	# The truck's body centre goes on the bay the warehouse motorcycle used (as parked_vehicles()).
	var truck := vehicles.get_node("Truck") as Node3D
	var bounds := AABB()
	var first := true
	for collider in truck.get_node("StudyArea").get_children():
		if collider is CollisionShape3D and collider.shape is BoxShape3D:
			var box: AABB = collider.transform * AABB(-collider.shape.size * 0.5, collider.shape.size)
			bounds = box if first else bounds.merge(box)
			first = false
	var turn := Basis(Vector3.UP, deg_to_rad(TRUCK_YAW))
	var scale := (vehicles.transform * truck.transform).basis.get_scale()
	var centre := bounds.get_center() * scale
	# Its height above the ground stays; the lot is TRUCK_BAY.y above the old road spot.
	var spot := Vector3(TRUCK_BAY.x, (vehicles.transform * truck.transform).origin.y + TRUCK_BAY.y, TRUCK_BAY.z) - turn * Vector3(centre.x, 0, centre.z)
	truck.transform = vehicles.transform.affine_inverse() * Transform3D(turn.scaled(scale), spot)
	var removed := 0
	for vehicle in vehicles.get_children():
		if vehicle.scene_file_path == "res://scenes/props/vehicles/motorcycle.tscn":
			vehicles.remove_child(vehicle)
			vehicle.free()
			removed += 1
	print("tutorial_lot_clear: car moved, truck parked at the warehouse, %d motorcycles removed" % removed)

## The lagoon fish swims under the water (user, 23 Nov 2026): it sat on the surface and looked
## like an obstacle in the swan boat's way. Its highest point (dorsal fin) goes FISH_DIVE below the
## lagoon surface; the translucent lagoon shader (garden_water.gdshader) shows it through the water.
## The bed is 0.88 world units deep and the fish 1.01 tall, so the bottom of its belly sinks a
## little into the bed. Meta `figure_blocker` false keeps house_characters.gd solidify_figures()
## from giving it the solid FigureBlocker box that stopped the boat; its wander probe
## (park_animals.gd) now runs under the boat's hull, so neither stops the other.
const FISH_DIVE := 0.03

func fish_under_water(town: Node3D, _game) -> void:
	var fish := town.get_node("ParkZoo/Fish") as Node3D
	var water := town.get_node("PublicGarden/Public Garden lagoon") as MeshInstance3D
	var surface_y: float = (water.global_transform * water.get_aabb()).end.y
	var top_y := -INF
	for mesh: MeshInstance3D in fish.find_children("*", "MeshInstance3D", true, false):
		top_y = maxf(top_y, (mesh.global_transform * mesh.get_aabb()).end.y)
	var drop: float = (top_y - surface_y + FISH_DIVE) / fish.get_parent().global_basis.get_scale().y
	fish.position.y -= drop
	fish.set("home", fish.position)
	fish.set_meta("figure_blocker", false)
	print("fish_under_water: lowered %.3f (zoo units), top %.3f below the surface" % [drop, FISH_DIVE])

## The zoo plaza's two benches (zoo_zones, north of the cherry-tree planter) are removed (user,
## 23 Nov 2026). Each is four "Park bench*" boxes under ParkZoo/ZooZones; their colliders go with them.
func zoo_plaza_benches_removed(town: Node3D, _game) -> void:
	var root := town.get_node("ParkZoo/ZooZones")
	var removed := 0
	for node in root.get_children():
		if String(node.name).begins_with("Park bench") and node is Node3D \
				and absf(node.position.z - 108.7) < 1.0 and absf(node.position.x + 78.0) < 3.5:
			root.remove_child(node)
			node.free()
			removed += 1
	assert(removed == 8, "zoo_plaza_benches_removed: expected 8 bench parts, found %d" % removed)
	print("zoo_plaza_benches_removed: removed %d bench parts" % removed)

## The green "THE ZOO" welcome board on two posts outside the zoo, west of the entrance arch
## (user, 23 Nov 2026: remove it; the arch's own "THE ZOO" board names the zoo and keeps the
## sign_translations entry in use): the board, its label and both posts.
func zoo_welcome_sign_removed(town: Node3D, _game) -> void:
	var root := town.get_node("ParkZoo")
	var centre := Vector3(-87.0, 2.8, 129.0)
	var removed := 0
	for node in root.get_children():
		var title := String(node.name)
		# The board's own label is the only Label3D this close to it.
		var hit := title == "Zoo welcome" or title.begins_with("Welcome post") or node is Label3D
		if hit and node is Node3D and Vector2(node.position.x - centre.x, node.position.z - centre.z).length() < 3.0:
			root.remove_child(node)
			node.free()
			removed += 1
	assert(removed == 4, "zoo_welcome_sign_removed: expected 4 sign parts, found %d" % removed)
	print("zoo_welcome_sign_removed: removed %d sign parts" % removed)

## The zoo food booth (Feeding Time!, user design 24 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md,
## "Zoo food booth and Feeding Time"): a small kiosk on the grass strip just inside the gate, west
## of the path in front of Wildlife Plains (zoo-local = town coordinates), its counter facing the
## path (-X). On the counter: a stack of paper bags ("Paper bags", the till's basket rack,
## data/shops.json store "zoo") and five open crates, one per food word (meat, apple, fish,
## carrot, bamboo), each a word root with its pick area, showing the supermarket's product
## models. A striped awning on four posts and an ANIMAL FOOD board (WorldSign). Nico stands
## behind the counter (a registry NPC, data/npcs.json nico, made at load, never baked).
## The zoo's footprint, fences, gate and planters are unchanged.
const BOOTH_FRONT := -75.35
const BOOTH_BACK := -73.0
const BOOTH_Z := Vector2(122.9, 125.45)
const BOOTH_FOODS := ["meat", "apple", "fish", "carrot", "bamboo"]

func zoo_food_booth(town: Node3D, game) -> void:
	var Art = preload("res://scripts/buildings/supermarket_products.gd")
	var Basket = preload("res://scripts/world/shopping_basket.gd")
	var WorldSign = preload("res://scripts/world/world_sign.gd")
	var zoo: Node3D = town.get_node("ParkZoo")
	var ground := .12
	# Nothing of the zoo may stand where the booth goes (the lawn and zone grounds lie under it).
	var area := Rect2(BOOTH_FRONT - .3, BOOTH_Z.x, BOOTH_BACK - BOOTH_FRONT + .6, BOOTH_Z.y - BOOTH_Z.x)
	for node in zoo.find_children("*", "Node3D", true, false):
		var title := String(node.name)
		var local := zoo.to_local(node.global_position)
		if node is VisualInstance3D and not title.ends_with("lawn") and not title.begins_with("Zone ground") \
				and area.has_point(Vector2(local.x, local.z)):
			print("zoo_food_booth: in the way: %s at %s" % [zoo.get_path_to(node), zoo.to_local(node.global_position)])
	var root := Node3D.new()
	root.name = "ZooFoodBooth"
	zoo.add_child(root)
	var wood := Color("b5834f")
	var dark := Color("7a5232")
	var cream := Color("f3ead8")
	var green := Color("5f8f3a")
	var length := BOOTH_Z.y - BOOTH_Z.x
	var mid_z := (BOOTH_Z.x + BOOTH_Z.y) * .5
	# Counter: a wooden box with a cream band and a top slab overhanging the front.
	var top := ground + 1.0
	var counter_x := BOOTH_FRONT + .35
	_zz_part(root, "Booth counter", "box", Vector3(counter_x, (ground + top) * .5, mid_z), Vector3(.7, top - ground, length), wood, game)
	_zz_part(root, "Booth counter band", "box", Vector3(BOOTH_FRONT - .005, ground + .62, mid_z), Vector3(.02, .18, length - .1), green, game)
	_zz_part(root, "Booth counter top", "box", Vector3(counter_x - .05, top + .03, mid_z), Vector3(.86, .06, length + .1), Color("d9b07a"), game)
	_zz_solid(root, "Booth counter solid", Vector3(counter_x, ground + .6, mid_z), Vector3(.75, 1.2, length + .05))
	# Four posts and a back rail; a striped awning sloping down to the front.
	var roof_low := ground + 2.75
	var roof_high := ground + 3.15
	for x in [BOOTH_FRONT + .05, BOOTH_BACK - .05]:
		for z in [BOOTH_Z.x + .05, BOOTH_Z.y - .05]:
			var height: float = (roof_low if x < counter_x else roof_high) - ground
			_zz_part(root, "Booth post", "box", Vector3(x, ground + height * .5, z), Vector3(.1, height, .1), dark, game)
			_zz_solid(root, "Booth post solid", Vector3(x, ground + height * .5, z), Vector3(.14, height, .14))
	_zz_part(root, "Booth back rail", "box", Vector3(BOOTH_BACK - .05, ground + 1.0, mid_z), Vector3(.06, .08, length - .1), dark, game)
	_zz_solid(root, "Booth back solid", Vector3(BOOTH_BACK - .05, ground + 1.0, mid_z), Vector3(.12, 2.0, length - .1))
	for side in [-1.0, 1.0]:
		var z: float = BOOTH_Z.x + .05 if side < 0 else BOOTH_Z.y - .05
		_zz_solid(root, "Booth side solid", Vector3((counter_x + BOOTH_BACK) * .5, ground + 1.0, z), Vector3(BOOTH_BACK - counter_x, 2.0, .12))
	var depth := BOOTH_BACK - BOOTH_FRONT + .6
	var slope := atan2(roof_high - roof_low, BOOTH_BACK - BOOTH_FRONT)
	var stripes := 7
	for k in stripes:
		var z := BOOTH_Z.x - .15 + (length + .3) * (k + .5) / stripes
		var strip := _zz_part(root, "Booth awning", "box", Vector3((BOOTH_FRONT + BOOTH_BACK) * .5 - .15, (roof_low + roof_high) * .5 + .05, z),
				Vector3(depth / cos(slope), .05, (length + .3) / stripes), green if k % 2 == 0 else cream, game)
		strip.rotation.z = slope
	# The scalloped front edge of the awning.
	for k in stripes:
		var z := BOOTH_Z.x - .15 + (length + .3) * (k + .5) / stripes
		_zz_part(root, "Booth awning flap", "box", Vector3(BOOTH_FRONT - .45, roof_low - .06, z), Vector3(.03, .22, (length + .3) / stripes - .02), green if k % 2 == 0 else cream, game)
	# The board above the awning's front edge, lettered ANIMAL FOOD (translated at load).
	_zz_part(root, "Booth board", "box", Vector3(BOOTH_FRONT - .3, roof_low + .42, mid_z), Vector3(.06, .5, 2.1), cream, game)
	var label := WorldSign.make(root, "Booth sign", "ANIMAL FOOD", Vector3(BOOTH_FRONT - .34, roof_low + .42, mid_z), {"read": 9.0, "colour": Color("4f3a22"), "board": cream, "fit_width": 2.0})
	label.rotation.y = -PI / 2.0
	# The paper bags (the till's basket rack): a stack of folded bags and one standing open.
	var art = Art.new()
	var slots := []
	for i in 6:
		slots.append(BOOTH_Z.x + .25 + (length - .5) * i / 5.0)
	var bags := Node3D.new()
	bags.name = "Paper bags"
	bags.position = Vector3(counter_x - .05, top + .06, slots[0])
	root.add_child(bags)
	for i in 4:
		_zz_part(bags, "Folded bag", "box", Vector3(.05, .012 + i * .022, 0), Vector3(.22, .02, .32), Color("c9a477").darkened(.04 * (i % 2)), game)
	var open := MeshInstance3D.new()
	open.name = "Open bag"
	open.mesh = Basket.bag_mesh()
	open.position = Vector3(-.1, .1, 0)
	open.rotation.y = PI / 2.0
	open.scale = Vector3.ONE * 1.1
	bags.add_child(open)
	_pick_area(bags, Vector3(0, .25, 0), Vector3(.5, .55, .45))
	# The food crates, one word each.
	for i in BOOTH_FOODS.size():
		var key: String = BOOTH_FOODS[i]
		var crate := Node3D.new()
		crate.name = "Booth food " + key
		crate.position = Vector3(counter_x - .08, top + .06, slots[i + 1])
		crate.set_meta("word_key", key)
		crate.set_meta("learning_object", true)
		root.add_child(crate)
		_zz_part(crate, "Crate floor", "box", Vector3(0, .01, 0), Vector3(.36, .02, .36), Color("c8955c"), game)
		for side in [-1.0, 1.0]:
			_zz_part(crate, "Crate side", "box", Vector3(side * .17, .07, 0), Vector3(.02, .12, .36), Color("c8955c"), game)
			_zz_part(crate, "Crate side", "box", Vector3(0, .07, side * .17), Vector3(.36, .12, .02), Color("b07a45"), game)
		var mesh: ArrayMesh = art.model(key)
		var box := mesh.get_aabb()
		var grow := .17 / maxf(.001, maxf(box.size.x, maxf(box.size.y, box.size.z)))
		var spots := [Vector3(-.07, 0, -.07), Vector3(.07, 0, .06), Vector3(-.05, 0, .08), Vector3(.06, .05, -.05)]
		for j in spots.size():
			var item := MeshInstance3D.new()
			item.name = "%s %d" % [key, j + 1]
			item.mesh = mesh
			var turn := Basis(Vector3.UP, .9 * j + .3)
			var at: Vector3 = spots[j] + Vector3(0, .03 + j / 3 * .04, 0)
			item.transform = Transform3D(turn.scaled(Vector3.ONE * grow), at - turn * (Vector3(box.get_center().x, box.position.y, box.get_center().z) * grow))
			crate.add_child(item)
		_pick_area(crate, Vector3(0, .12, 0), Vector3(.38, .26, .38))
	print("zoo_food_booth: counter %.2f..%.2f x, %.2f..%.2f z; %d crates and the paper bags" % [BOOTH_FRONT, counter_x + .35, BOOTH_Z.x, BOOTH_Z.y, BOOTH_FOODS.size()])

## The booth board fits ANIMAL FOOD in every language (25 Nov 2026, check world_signs: English
## 2.09 m and COMIDA PARA ANIMALES 3.64 m over a 2.0 m fit width). zoo_food_booth gave the fit
## width in town units (the 2.1-unit board), but WorldSign takes world metres (town x 1.3): the
## board is 2.73 m wide, so the free width is 2.5 m. The sign keeps its 9 m letter height and may
## wrap to two lines (COMIDA PARA / ANIMALES); the board grows to two lines' height, its bottom
## edge staying on the awning's front edge. docs/guides/BUILDING_DESIGN_BLUEPRINT.md#sign-readability.
const BOOTH_BOARD_HEIGHT := .8

func zoo_food_booth_sign_fit(town: Node3D, game) -> void:
	var WorldSign = preload("res://scripts/world/world_sign.gd")
	var root: Node3D = town.get_node("ParkZoo/ZooFoodBooth")
	var board: MeshInstance3D = root.get_node("Booth board")
	var label: Label3D = root.get_node("Booth sign")
	var scale := label.global_transform.basis.get_scale().y
	var size: Vector3 = board.mesh.size
	var low := board.position.y - size.y * .5
	board.mesh = game.shared_box_mesh(Vector3(size.x, BOOTH_BOARD_HEIGHT, size.z))
	board.position.y = low + BOOTH_BOARD_HEIGHT * .5
	label.position.y = board.position.y
	var fit := (size.z - .16) * scale
	WorldSign.restyle(label, {"read": 9.0, "board": Color("f3ead8"), "fit_width": fit, "max_lines": 2})
	print("zoo_food_booth_sign_fit: board %.2f x %.2f m, sign em %.2f m, fit %.2f m, 2 lines" % [size.z * scale, BOOTH_BOARD_HEIGHT * scale, WorldSign.em_of(label), fit])

## A pick area (layer 2, as the basket's) so a click or a tap names the object.
func _pick_area(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = "Pick area"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	parent.add_child(area)

