extends SceneTree
## Warehouse Phases 1–3 (5 Nov 2026): hall equipment (Phase 3); word objects and posters (Phase 2); site, school move, zones, doors and a clear walking path
## from the lot through the entrance and the reception into the hall. Uses Main, which saves
## progress: run with an isolated HOME (README). Report a VT_FOCUS run as focused.
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/warehouse-20261105/verify.gd
const Picking := preload("res://scripts/player/interaction_controller.gd")
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## True when a standing-player capsule at local point p touches anything but the floor.
func blocked(space: PhysicsDirectSpaceState3D, wh: Node3D, p: Vector3, exclude: Array[RID]) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = .35
	shape.height = 1.3
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), wh.to_global(p + Vector3(0, .15 + .65 + .08, 0)))
	query.exclude = exclude
	query.collide_with_areas = false
	return not space.intersect_shape(query, 4).is_empty()

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var town: Node3D = game.apartment
	var layout = game.reference_layout
	var wh: Node3D = town.get_node_or_null("Warehouse")
	check(wh != null, "warehouse built")
	if wh == null:
		print("warehouse: %d checks, %d failures" % [checks, failures]); quit(1); return
	var b: AABB = layout.site_bounds.get("Warehouse", AABB())
	check(b.position.x > -51 and b.end.x < -19 and b.position.z > 214, "warehouse footprint x -50..-20 (with apron to the lot): " + str(b))
	var school: AABB = layout.bounds(town.get_node("Buildings/School"))
	check(absf(school.get_center().x - 10.0) < .5, "school moved to x 10: " + str(school.get_center()))
	var hospital: AABB = layout.bounds(town.get_node("Buildings/Hospital"))
	var tower: AABB = layout.bounds(town.get_node("Airport/ControlTower"))
	check(hospital.position.x - school.end.x > 15, "hospital/school gap over 15")
	check(school.position.x - (wh.position.x + 15) > 15, "school/warehouse gap over 15")
	check((wh.position.x - 15) - tower.end.x > 10, "warehouse/tower gap over 10")
	check(layout.site_at(Vector3(-35, 1, 236)) == "Warehouse", "room name Warehouse")
	check(game.zones.resolve_local(Vector3(-35, 0, 236)) == "warehouse", "warehouse zone")
	check(game.zones.resolve_local(Vector3(10, 0, 230)) == "school", "school zone moved")
	var lot := town.get_node_or_null("Warehouse parking")
	check(lot != null and town.get_node_or_null("Warehouse parking drive") != null, "lot and drive")
	var mapped := false
	for entry in town.get_meta("reference_map_sites"):
		if entry.node == wh: mapped = true
	check(mapped, "map entry")
	var entrance: Node3D = wh.get_node("Architecture/Warehouse entrance door")
	var hall_door: Node3D = wh.get_node("Architecture/Warehouse hall door")
	check(game.doors.has(entrance) and game.doors[entrance].type == "slide", "entrance is a registered sliding door")
	check(game.doors.has(hall_door) and game.doors[hall_door].type == "hinge", "hall door is a registered hinged door")
	check(wh.get_node_or_null("Reception/Receptionist") != null, "receptionist seated in reception")
	# Phase 2: every word object resolves to its word through the real picking rule.
	var picks := {"Architecture/Warehouse rear wall": "warehouse", "Architecture/Reception front wall": "warehouse", "Architecture/Warehouse entrance door": "door", "Exterior/Cardboard box": "cardboard box", "Hall/Platform cart": "trolley", "Hall/Rack A shelf 0": "shelf", "Hall/Rack C shelf 2": "shelf", "Hall/Work table": "table", "Hall/Measuring table": "table", "Hall/Ruler": "ruler", "Hall/Floor scale": "scale", "Hall/Supply cabinet": "cabinet", "Hall/Conveyor belt": "conveyor belt", "Hall/Container": "container", "Hall/Crate": "crate", "Exterior/Delivery truck": "truck", "Exterior/Ramon": "boss", "Reception/Receptionist": "employee", "Reception/Package": "package"}
	for path in picks:
		var node: Node = wh.get_node_or_null(path)
		var key := ""
		if node != null:
			var bodies := node.find_children("*", "CollisionObject3D", true, false)
			if not bodies.is_empty():
				var target: Node3D = Picking.vocabulary_target(bodies[0], town)
				if target != null: key = str(target.get_meta("exterior_word", target.get_meta("word_key", "")))
		check(key == picks[path], "%s picks as %s (got '%s')" % [path, picks[path], key])
	var lexicon = preload("res://scripts/language/lexicon.gd").shared()
	for spec in [["Reception/Warehouse poster verbs", 22], ["Reception/Warehouse poster positions", 14], ["Reception/Warehouse poster colors sizes", 8]]:
		var poster: Node = wh.get_node_or_null(spec[0])
		var keys := []
		if poster != null:
			for card in poster.get_children():
				var word := str(card.get_meta("word_key", ""))
				if word != "" and lexicon.has_word(word): keys.append(word)
		check(keys.size() == spec[1], "%s: %d word cards known to the lexicon (got %d)" % [spec[0], spec[1], keys.size()])
	# Phase 3: rack letters, floor areas in the shown language, a lit scale readout.
	var letters := []
	for node in wh.get_node("Hall").get_children():
		if node is Label3D and node.text in ["A", "B", "C"]: letters.append(node.text)
	letters.sort()
	check(letters == ["A", "A", "B", "B", "C", "C"], "racks A, B and C lettered, on the rack and on the floor " + str(letters))
	var areas := []
	for node in wh.get_node("Hall").get_children():
		if node is Label3D and String(node.name).begins_with("Floor area label"): areas.append(node.text)
	check(areas.size() == 2 and areas[0] != "" and areas[1] != "", "IN / OUT floor areas labelled " + str(areas))
	check(wh.get_node_or_null("Hall/Scale readout") != null, "scale readout")
	check(not wh.get_node("Reception/Receptionist").has_meta("character_name"), "Paty's click teaches a word, not a name card")
	var space: PhysicsDirectSpaceState3D = wh.get_world_3d().direct_space_state
	var exclude: Array[RID] = [game.player.get_rid()]
	check(not blocked(space, wh, Vector3(-2.2, 0, -1.6), exclude) and not blocked(space, wh, Vector3(0, 0, -1.6), exclude), "walk in front of the entrance clear beside Ramón")
	check(blocked(space, wh, Vector3(0, 0, .15), exclude), "closed entrance blocks")
	check(blocked(space, wh, Vector3(0, 0, 7.15), exclude), "closed hall door blocks")
	entrance.position = game.doors[entrance].origin + game.doors[entrance].shift
	hall_door.rotation.y = float(game.doors[hall_door].angle)
	await physics_frame
	await physics_frame
	var path: Array[Vector3] = []
	for z in range(-5, 0): path.append(Vector3(0, 0, z))
	for i in range(0, 15): path.append(Vector3(0, 0, i * .5))
	for z in range(8, 27): path.append(Vector3(0, 0, z))
	for x in range(-13, 14): path.append(Vector3(x, 0, 18))
	# Phase 3: a standing place in front of each rack, the cabinet, the scale, both tables and in each floor area.
	for p in [Vector3(9, 0, 26), Vector3(3.5, 0, 26), Vector3(-3.5, 0, 26), Vector3(-8.5, 0, 26.8), Vector3(8, 0, 14.0), Vector3(4.5, 0, 10.8), Vector3(11, 0, 10.9), Vector3(-10.5, 0, 10), Vector3(-3, 0, 10)]: path.append(p)
	var stuck := []
	for p in path:
		if blocked(space, wh, p, exclude): stuck.append(p)
	check(stuck.is_empty(), "open doors: clear walk lot → reception → hall, across the hall and to each station " + str(stuck))
	print("warehouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
