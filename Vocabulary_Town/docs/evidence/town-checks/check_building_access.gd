extends SceneTree
## Building access (7 Nov 2026): the parts of the six retired October snapshot checks
## (building dimensions, school / supermarket / café-bank exteriors, market interior, school
## partition) that no other check covers, without stored fingerprints:
## - the door registry holds every saved door_state of the loaded town;
## - the approved school (24 x 18, single story, 4.6 m) and supermarket (26 x 26) dimensions;
## - entrance and main aisle walk paths of the school, supermarket, café and bank (player
##   capsule clear and floor underneath);
## - each school and supermarket word can be picked with the real interaction controller from a
##   clear nearby spot, and the market's picks open the dictionary card.
## Facade obstacles are covered by check_map_facades.gd; the classroom by grammar-class verify.
## Uses Main, which can save progress: run with an isolated HOME (README), VT_FOCUS=all.
const Interactable := preload("res://scripts/core/interactable.gd")
var checks := 0
var failures := 0
var game
var town: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func clear_at(world: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = game.player.get_node("PlayerCollision").shape
	query.transform = Transform3D(Basis.IDENTITY, world + Vector3.UP * 1.16)
	query.exclude = [game.player.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

## Walk line a -> b in `frame` coordinates, sampled every 0.25 m: one label per failing line.
func route(frame: Node3D, a: Vector3, b: Vector3, label: String) -> void:
	var count := ceili(a.distance_to(b) / .25)
	var blocked: Array = []
	var unsupported: Array = []
	for i in range(count + 1):
		var p := a.lerp(b, float(i) / maxi(count, 1))
		var world := frame.to_global(p)
		if not clear_at(world): blocked.append(p)
		var ray := PhysicsRayQueryParameters3D.create(world + Vector3.UP * .4, world - Vector3.UP * .5)
		ray.exclude = [game.player.get_rid()]
		if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): unsupported.append(p)
	check(blocked.is_empty(), "walk path clear: %s %s" % [label, str(blocked.slice(0, 3))])
	check(unsupported.is_empty(), "walk path supported: %s %s" % [label, str(unsupported.slice(0, 3))])

func doors_check() -> void:
	var saved: Array = []
	for node in [town] + town.find_children("*", "Node3D", true, false):
		if node.has_meta("door_state"): saved.append(node)
	check(saved.size() > 0, "town has saved doors")
	var missing: Array = saved.filter(func(node): return not game.doors.has(node))
	check(missing.is_empty(), "door registry holds every saved door %s" % [missing.slice(0, 3).map(func(n): return str(town.get_path_to(n)))])
	var stray: Array = game.doors.keys().filter(func(node): return not is_instance_valid(node) or not node.is_inside_tree())
	check(stray.is_empty(), "door registry has no freed or detached doors")
	print("BUILDING ACCESS: ", saved.size(), " saved doors, ", game.doors.size(), " registered")

func dimensions_check() -> void:
	# Approved resize (25 Oct 2026, TOWN_DESIGN_BRIEF.md); town coordinates.
	var school: Node3D = town.get_node("Buildings/School")
	var floor_box: AABB = game.reference_layout.bounds(school.get_node("ApprovedShell/Floor"))
	check(floor_box.size.is_equal_approx(Vector3(24, .2, 18)), "school 24 x 18 floor")
	# The school moved 10 units west (+X) on 5 Nov 2026 (approved, warehouse room): axis x = 10.
	check(floor_box.position.is_equal_approx(Vector3(-2, -.2, 221)), "school front and axis retained")
	check(not school.has_node("Floor2") and not school.has_node("LearningWing") and not school.has_node("StairRoof"), "school single story")
	check(is_equal_approx(game.reference_layout.bounds(school.get_node("MainRoof")).position.y, 4.6), "school 4.6 clear height")
	var market: Node3D = town.get_node("RelocatedSites/Supermarket")
	var foundation: AABB = game.reference_layout.bounds(market.get_node("Expanded foundation"))
	check(foundation.size.is_equal_approx(Vector3(26, .2, 26)), "market 26 x 26 floor")
	check(foundation.position.is_equal_approx(Vector3(-159, -.2, 113)), "market retained front and axis")
	var walls := AABB()
	for key in ["Supermarket left wall", "Supermarket right wall", "Supermarket back wall", "Supermarket front pier", "Supermarket front pier2"]:
		var b: AABB = game.reference_layout.bounds(market.get_node(key))
		walls = b if walls == AABB() else walls.merge(b)
	check(walls.size.is_equal_approx(Vector3(26, 5.8, 26)), "market exact external wall envelope")
	check(is_equal_approx(game.reference_layout.bounds(market.get_node("Supermarket roof")).position.y - .1, 5.71), "market clear height above finished floor")

func paths_check() -> void:
	# Town coordinates; school axis x = 10 since 5 Nov 2026. Lines end where approved fittings
	# begin (school rear divider at z 230, café front counter at x 142).
	route(town, Vector3(10, .1, 200), Vector3(10, .1, 229), "school parking, entrance and open front half")
	route(town, Vector3(1, .1, 223.4), Vector3(19, .1, 223.4), "school front crossing")
	for x in [8.7, 11.3]: route(town, Vector3(x, .1, 223), Vector3(x, .1, 234.6), "school rear side access x=%s" % x)
	route(town, Vector3(-118, .1, 126), Vector3(-132, .1, 126), "market approach and entrance")
	route(town, Vector3(118, .1, 166), Vector3(141, .1, 166), "cafe approach and interior")
	route(town, Vector3(118, .1, 108), Vector3(134.5, .1, 108), "bank approach and lobby")
	# Supermarket-local coordinates (as the retired market interior check).
	var market: Node3D = town.get_node("RelocatedSites/Supermarket")
	route(market, Vector3(-33, .1, 32), Vector3(-33, .1, 42), "market entrance spine")
	for z in [42, 52.7]: route(market, Vector3(-44.5, .1, z), Vector3(-22, .1, z), "market cross aisle z=%s" % z)
	for x in [-37.7, -28.3]: route(market, Vector3(x, .1, 42), Vector3(x, .1, 55), "market connecting aisle x=%s" % x)
	route(market, Vector3(-44.5, .1, 55), Vector3(-21.5, .1, 55), "market fresh counters")

## True when the real controller aims at `node` from some clear spot within 3.5 m (nearest
## spots first), looking at its first collision shape.
func pickable(node: Node3D) -> bool:
	var shapes: Array = node.find_children("*", "CollisionShape3D", true, false)
	if shapes.is_empty(): return false
	var target: Vector3 = shapes[0].global_position
	var spots: Array = []
	for ix in range(-7, 8):
		for iz in range(-7, 8):
			var offset := Vector3(ix * .5, 0, iz * .5)
			if offset.length() >= .9 and offset.length() <= 3.5: spots.append(offset)
	spots.sort_custom(func(a, b): return a.length() < b.length())
	for offset in spots:
		var spot: Vector3 = town.to_local(target) + offset
		spot.y = .1
		var world := town.to_global(spot)
		if not clear_at(world): continue
		game.player.global_position = world
		game.camera.global_position = world + Vector3.UP * 1.65
		game.camera.look_at(target)
		game.interaction.pointer_position = root.get_visible_rect().size / 2
		if game.interaction.aimed_object() == node: return true
	return false

func is_character(node: Node) -> bool:
	while node != null and node != town:
		if node.scene_file_path.begins_with("res://scenes/characters/"): return true
		node = node.get_parent()
	return false

func words_check() -> void:
	game.interaction.word_studied.disconnect(game._on_word_studied)
	game.camera.reparent(game)
	var groups := {
		"school": [town.get_node("Buildings/School/RetainedLearningObjects")],
		"market": [town.get_node("RelocatedSites/Supermarket"), town.get_node("Buildings/MarketDisplays")],
	}
	var market: Node3D = town.get_node("RelocatedSites/Supermarket")
	for group in groups:
		var results := {}
		for parent in groups[group]:
			for node in parent.find_children("*", "Node3D", true, false):
				if not node.has_meta("word_key") or str(node.get_meta("word_key")) in ["roof", "floor", "wall"]: continue
				# Interactables (seats, doors, ...) are not words since 12 Nov 2026 (user): a click uses them.
				if Interactable.find_for(node, town) != null: continue
				# Front windows, sign and mat sit under the SUPERMARKET map facade, which shows the
				# exterior word (check_map_facades.gd); only words inside the shell are tested here.
				if group == "market" and market.to_local(node.global_position).z < 34.3: continue
				var key: String = game.vocabulary_aliases.get(str(node.get_meta("word_key")), str(node.get_meta("word_key")))
				check(game.vocabulary.has(key), "%s word in dictionary: %s" % [group, key])
				if not results.has(key): results[key] = false
				if results[key] or node.find_children("*", "CollisionShape3D", true, false).is_empty(): continue
				if pickable(node):
					results[key] = true
					# Characters open their dialogue instead of the dictionary card.
					if group == "market" and not is_character(node):
						# Any click closes an open card first (user, 14 Nov 2026), so close the last one.
						game.interaction.clear_card()
						game.interaction.selected = null
						game.interaction.click()
						check(game.hud.is_card_visible() and game.hud.current_spanish == game.vocabulary[key], "market dictionary card " + key)
		for key in results: check(results[key], "%s word pickable from a clear spot: %s" % [group, key])
		print("BUILDING ACCESS: ", results.size(), " ", group, " words")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	town = game.apartment
	doors_check()
	dimensions_check()
	await physics_frame
	await physics_frame
	paths_check()
	words_check()
	print("BUILDING ACCESS: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
