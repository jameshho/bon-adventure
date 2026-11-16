extends SceneTree
## Warehouse redesign (user, 14 Nov 2026; docs/guides/WAREHOUSE.md#redesign-14-nov-2026), the town copy:
## the 30 x 14.5 footprint, site/zone/map data, the reception inside the footprint at the east
## end (glass sliding entrance and ramp, Paty at the desk, the hall door), the low divider, the
## left section's shelf / table / cabinet and nothing else in the hall, two loading bays (the
## truck at bay A, bay B empty, a clear corridor to the lot), the scale and ruler on the counter,
## the trolley outside, every former warehouse word still in town, the picks and posters, and a
## standing-player capsule walking from the lot through both doors and around the hall.
## Replaces docs/evidence/warehouse-20261105/verify.gd (the old 30 x 29 layout). Uses Main, which saves
## progress: run with an isolated HOME (README). Report a VT_FOCUS run as focused.
##   python3 tools/run_checks.py --only warehouse
const Picking := preload("res://scripts/player/interaction_controller.gd")
const Warehouse := preload("res://scripts/world/warehouse.gd")
## Every word an object of the warehouse taught before the redesign (scenes/town/warehouse.scn
## at 0117c1e, poster cards aside): each still needs an object somewhere in town.
const FORMER_WORDS := ["warehouse", "window", "door", "plant", "cardboard box", "truck", "wheel", "boss", "ceiling light", "reception desk", "computer", "phone", "package", "clipboard", "office chair", "employee", "chair", "shelf", "table", "ruler", "scale", "cabinet", "conveyor belt", "crate", "apple", "banana", "container", "bottle", "trolley"]
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

## Hall-local standing points (y ignored) from the lot through the open entrance, the reception
## and the open hall door, around both sections of the hall and to each station. Shared with
## verify_game.gd (the minigame copy).
static func walk_path() -> Array:
	var path: Array = []
	var e := Warehouse.ENTRANCE_X
	for z in [-4.0, -2.5, -1.0, -.3, .15, .6, 1.2]:
		path.append(Vector3(e, 0, z))
	for p in [Vector3(-11.5, 0, 2.4), Vector3(-10.3, 0, 3.6), Vector3(-9.2, 0, 3.6), Vector3(-8.15, 0, 3.6), Vector3(-7.0, 0, 3.6)]:
		path.append(p)
	# The reception: in front of the desk, by the waiting chairs, by the posters.
	for p in [Vector3(-11.5, 0, 8.9), Vector3(-13.0, 0, 7.0), Vector3(-9.6, 0, 7.0), Vector3(-9.6, 0, 12.0)]:
		path.append(p)
	# The right (east) section, the divider opening, the left (west) section.
	for x in [-6.0, -2.0, 1.5]:
		for z in [1.8, 7.0, 12.6]:
			path.append(Vector3(x, 0, z))
	for z in [5.6, 7.0, 8.4]:
		path.append(Vector3(Warehouse.DIVIDER_X, 0, z))
	for p in [Vector3(5.0, 0, 3.0), Vector3(5.0, 0, 7.0), Vector3(5.0, 0, 11.0), Vector3(12.2, 0, 3.0), Vector3(12.2, 0, 9.0)]:
		path.append(p)
	# Stations: in front of the shelf, both long sides and the west end of the table, the
	# cabinet (room for its open doors), in front of the wall bay.
	var shelf := Warehouse.SHELF_AT
	for dx in [-1.3, 0.0, 1.3]:
		path.append(Vector3(shelf.x + dx, 0, shelf.z - Warehouse.RACK_DEPTH * .5 - .75))
	var table := Warehouse.WORK_TABLE
	var half := Warehouse.WORK_TABLE_SIZE * .5
	for p in [Vector3(table.x, 0, table.z - half.y - .65), Vector3(table.x, 0, table.z + half.y + .65), Vector3(table.x + half.x + .65, 0, table.z)]:
		path.append(p)
	path.append(Vector3(Warehouse.CABINET_AT.x, 0, Warehouse.CABINET_AT.z - 1.7))
	path.append(Vector3(12.3, 0, 6.6))
	return path

## The colliders a standing player touches at hall-local point p of `wh` (the ground under p
## found with a ray; the capsule is the player's own, in world size, lifted 5 cm).
static func touching(space: PhysicsDirectSpaceState3D, wh: Node3D, player: Node3D, p: Vector3, exclude: Array[RID]) -> Array:
	var collision := player.get_node("PlayerCollision") as CollisionShape3D
	var shape := collision.shape as CapsuleShape3D
	var grow: float = collision.global_basis.get_scale().x
	var capsule := CapsuleShape3D.new()
	capsule.radius = shape.radius * grow
	capsule.height = shape.height * grow
	var top := wh.to_global(Vector3(p.x, 2.2, p.z))
	var ray := PhysicsRayQueryParameters3D.create(top, wh.to_global(Vector3(p.x, -1.0, p.z)))
	ray.exclude = exclude
	var hit := space.intersect_ray(ray)
	var ground: Vector3 = hit.position if not hit.is_empty() else wh.to_global(Vector3(p.x, 0, p.z))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), ground + Vector3(0, capsule.height * .5 + .05, 0))
	query.exclude = exclude
	query.collide_with_areas = false
	return space.intersect_shape(query, 4).map(func(r): return r.collider)

## Bodies in a hall-local box (corners a, b).
static func in_box(space: PhysicsDirectSpaceState3D, wh: Node3D, a: Vector3, b: Vector3, exclude: Array[RID]) -> Array:
	var grow: float = wh.global_basis.get_scale().x
	var box := BoxShape3D.new()
	box.size = (b - a).abs() * grow
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(wh.global_basis.orthonormalized(), wh.to_global((a + b) * .5))
	query.exclude = exclude
	query.collide_with_areas = false
	return space.intersect_shape(query, 8).map(func(r): return r.collider)

static func names(nodes: Array) -> Array:
	return nodes.map(func(n): return String(n.get_parent().name) + "/" + String(n.name) if n is Node else str(n))

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
	check(wh.position.is_equal_approx(Warehouse.SITE), "warehouse at its site " + str(wh.position))
	# The footprint: 30 wide (x -15..15), 14.5 deep (z 0..14.5), from the walls themselves.
	var shell := AABB()
	var first := true
	for node in wh.get_node("Architecture").get_children():
		var title := String(node.name)
		if (title.begins_with("Warehouse") or title.begins_with("Reception")) and title.contains("wall") and node is Node3D:
			var box: AABB = layout.bounds(node)
			shell = box if first else shell.merge(box)
			first = false
	var local := AABB(shell.position - wh.position, shell.size)
	check(absf(local.position.x + 15) < .05 and absf(local.end.x - 15) < .05 and absf(local.position.z) < .05 and absf(local.end.z - 14.5) < .05, "walls span x -15..15, z 0..14.5: " + str(local))
	var school: AABB = layout.bounds(town.get_node("Buildings/School"))
	var tower: AABB = layout.bounds(town.get_node("Airport/ControlTower"))
	check(school.position.x - (wh.position.x + 15) > 15, "school/warehouse gap over 15")
	check((wh.position.x - 15) - tower.end.x > 10, "warehouse/tower gap over 10")
	# Site bounds and the zone (both still reach z 253 behind: the free land is ground).
	var b: AABB = layout.site_bounds.get("Warehouse", AABB())
	check(b.has_point(Vector3(-35, 1, 228)) and b.position.x <= -50 and b.end.x >= -20 and b.end.z >= 235.3, "site bounds hold the building: " + str(b))
	check(layout.site_at(Vector3(-35, 1, 228)) == "Warehouse", "room name Warehouse")
	check(layout.site_at(wh.to_global(Vector3(-11.5, 1, 7))) == "Warehouse" or layout.site_at(Vector3(-46.5, 1, 228)) == "Warehouse", "room name in the reception")
	check(game.zones.resolve_local(Vector3(-35, 0, 228)) == "warehouse" and game.zones.resolve_local(Vector3(-35, 0, 246)) == "warehouse", "warehouse zone over the building and the land behind it")
	check(town.get_node_or_null("Warehouse parking") != null and town.get_node_or_null("Warehouse parking drive") != null, "lot and drive")
	var mapped := false
	for entry in town.get_meta("reference_map_sites"):
		if entry.node == wh: mapped = true
	check(mapped, "map entry")
	# Doors: the glass sliding entrance in the reception front, the hinged hall door in the
	# partition.
	var entrance: Node3D = wh.get_node("Architecture/Warehouse entrance door")
	var hall_door: Node3D = wh.get_node("Architecture/Warehouse hall door")
	check(game.doors.has(entrance) and game.doors[entrance].type == "slide" and absf(entrance.position.x - Warehouse.ENTRANCE_X) < .01 and entrance.position.x < Warehouse.RX, "entrance: registered sliding door in the reception front")
	check(game.doors.has(hall_door) and game.doors[hall_door].type == "hinge" and absf(hall_door.position.x - (Warehouse.RX - Warehouse.T * .5)) < .01, "hall door: registered hinged door in the partition")
	var ramp: Node3D = wh.get_node_or_null("Architecture/Warehouse entrance ramp")
	check(ramp != null and absf(ramp.position.x - Warehouse.ENTRANCE_X) < .01 and ramp.position.z < 0, "entrance ramp in front of the entrance")
	# Reception at the east end, inside the footprint: desk, Paty, counter scale and ruler.
	var rec: Node3D = wh.get_node("Reception")
	var paty: Node3D = rec.get_node_or_null("Receptionist")
	var desk_top: Node3D = rec.get_node_or_null("Reception desk top")
	check(paty != null and desk_top != null, "Paty and the desk")
	if paty != null and desk_top != null:
		var at := wh.to_local(paty.global_position)
		check(at.x > -Warehouse.HW and at.x < Warehouse.RX - Warehouse.T and at.z > 0 and at.z < Warehouse.HALL_Z1, "Paty inside the reception: " + str(at))
		var facing := wh.global_basis.inverse() * -paty.global_basis.z
		check(Vector2(facing.x, facing.z).normalized().dot(Vector2(0, -1)) > .9, "Paty faces the entrance (south): " + str(facing))
		check(wh.to_local(paty.get_meta("seat_point")).distance_to(at) < 1.0, "Paty's seat point moved with her")
		var top: AABB = layout.bounds(desk_top)
		for title in ["Counter scale", "Counter ruler"]:
			var thing: Node3D = rec.get_node_or_null(title)
			var c: Vector3 = layout.bounds(thing).get_center() if thing != null else Vector3.INF
			check(thing != null and c.x > top.position.x and c.x < top.end.x and c.z > top.position.z and c.z < top.end.z and absf(layout.bounds(thing).position.y - top.end.y) < .03, title + " on the counter")
	for child in rec.get_children():
		if child is Node3D and not child is Light3D:
			var p := (child as Node3D).position
			if p != Vector3.ZERO:
				check(p.x > -Warehouse.HW and p.x < Warehouse.RX and p.z > 0 and p.z < Warehouse.HALL_Z1, "reception part %s inside the reception %s" % [child.name, p])
	check(not paty.has_meta("character_name"), "Paty's click teaches a word, not a name card")
	# The hall: a low divider with a wide opening; left section: one shelf (two levels), one
	# table, the cabinet; nothing else with a word.
	var dividers: Array = wh.get_node("Architecture").get_children().filter(func(n): return String(n.name).begins_with("Hall divider wall"))
	check(dividers.size() == 2 and Warehouse.DIVIDER_OPENING.y - Warehouse.DIVIDER_OPENING.x >= 4.0 and Warehouse.DIVIDER_H < 1.5, "low divider in two parts with a %.1f wide opening" % (Warehouse.DIVIDER_OPENING.y - Warehouse.DIVIDER_OPENING.x))
	var hall_words := {}
	for node in wh.get_node("Hall").find_children("*", "", true, false):
		if node.has_meta("word_key"):
			var key := str(node.get_meta("word_key"))
			hall_words[key] = int(hall_words.get(key, 0)) + 1
			check(wh.to_local((node as Node3D).global_position).x > Warehouse.DIVIDER_X, node.name + " in the left section")
	check(hall_words == {"shelf": 2, "table": 1, "cabinet": 1}, "hall: one shelf (2 levels), one table, the cabinet: " + str(hall_words))
	check(Warehouse.RACK_LEVELS.size() == 2 and Warehouse.SHELF_SLOTS.size() == 3, "shelf: 2 levels x 3 places")
	check(wh.find_child("Conveyor belt", true, false) == null and wh.find_child("Floor scale", true, false) == null and wh.find_child("Rack A shelf 0", true, false) == null, "conveyor, floor scale and racks A-C gone")
	# Two loading bays outside: roll-up doors, jambs, bollards, one apron; the truck at bay A.
	var arch: Node3D = wh.get_node("Architecture")
	check(arch.get_node_or_null("Roll-up door A") != null and arch.get_node_or_null("Roll-up door B") != null and arch.get_node_or_null("Roll-up door C") == null, "exactly two roll-up doors")
	var ext: Node3D = wh.get_node("Exterior")
	var count := func(prefix: String) -> int: return ext.get_children().filter(func(n): return String(n.name).begins_with(prefix)).size()
	check(count.call("Roll-up door jamb") == 4 and count.call("Bollard cap") == 3 and count.call("Loading apron") == 1 and count.call("Loading bay marking") == 6, "jambs 4, bollards 3, one apron, bay markings 6")
	var truck: Node3D = ext.get_node_or_null("Delivery truck")
	var bay_a: Array = Warehouse.LOADING_DOORS[0]
	var bay_b: Array = Warehouse.LOADING_DOORS[1]
	if truck != null:
		var tb: AABB = layout.bounds(truck)
		var tl := AABB(tb.position - wh.position, tb.size)
		check(absf(tl.get_center().x - (bay_a[0] + bay_a[1]) * .5) < .4 and tl.end.z < .05 and tl.end.z > -.8, "truck backed up to bay A: " + str(tl))
		check(truck.has_meta("driveable_vehicle") and truck.get_meta("driveable_vehicle"), "the truck is still a DriveableVehicle")
	var space: PhysicsDirectSpaceState3D = wh.get_world_3d().direct_space_state
	var exclude: Array[RID] = [game.player.get_rid()]
	var in_b := in_box(space, wh, Vector3(bay_b[0], .3, -5.8), Vector3(bay_b[1], 3.5, -.4), exclude)
	check(in_b.is_empty(), "bay B empty: " + str(names(in_b)))
	var ahead := in_box(space, wh, Vector3(bay_a[0] - .3, .3, -16.0), Vector3(bay_a[1] + .3, 3.5, -8.4), exclude)
	check(ahead.is_empty(), "corridor from bay A to the lot clear: " + str(names(ahead)))
	var ahead_b := in_box(space, wh, Vector3(bay_b[0] - .3, .3, -16.0), Vector3(bay_b[1] + .3, 3.5, -5.8), exclude)
	check(ahead_b.is_empty(), "corridor from bay B to the lot clear: " + str(names(ahead_b)))
	var ramon: Node3D = ext.get_node_or_null("Ramon")
	var rp := wh.to_local(ramon.global_position) if ramon != null else Vector3.INF
	check(ramon != null and (rp.x < bay_a[0] - 1.0 or rp.x > bay_b[1] + 1.0) and rp.z < 0, "Ramón outside, clear of the bays: " + str(rp))
	# Every word the warehouse taught still has an object in town.
	var found := {}
	for node in town.find_children("*", "", true, false):
		for meta in ["word_key", "exterior_word"]:
			if node.has_meta(meta):
				found[str(node.get_meta(meta))] = true
	var missing: Array = FORMER_WORDS.filter(func(w): return not found.has(w))
	check(missing.is_empty(), "every former warehouse word has an object in town: missing " + str(missing))
	# Picks through the real picking rule.
	var picks := {"Architecture/Warehouse rear wall": "warehouse", "Architecture/Reception front wall": "warehouse", "Architecture/Warehouse entrance door": "door", "Architecture/Warehouse hall door": "door", "Exterior/Cardboard box": "cardboard box", "Exterior/Platform cart": "trolley", "Exterior/Container": "container", "Hall/Shelf level 1": "shelf", "Hall/Work table": "table", "Hall/Supply cabinet": "cabinet", "Reception/Counter scale": "scale", "Reception/Counter ruler": "ruler", "Exterior/Delivery truck": "truck", "Exterior/Ramon": "boss", "Reception/Receptionist": "employee", "Reception/Package": "package"}
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
	# Walking: the closed doors block; open, a standing player gets from the lot through both
	# doors and around the hall.
	check(not touching(space, wh, game.player, Vector3(Warehouse.ENTRANCE_X, 0, .15), exclude).is_empty(), "closed entrance blocks")
	check(not touching(space, wh, game.player, Vector3(Warehouse.RX - Warehouse.T * .5, 0, Warehouse.HALL_DOOR_Z), exclude).is_empty(), "closed hall door blocks")
	entrance.position = game.doors[entrance].origin + game.doors[entrance].shift
	hall_door.rotation.y = float(game.doors[hall_door].angle)
	await physics_frame
	await physics_frame
	var stuck := []
	for p in walk_path():
		var hits := touching(space, wh, game.player, p, exclude)
		if not hits.is_empty():
			stuck.append([p, names(hits)])
	check(stuck.is_empty(), "open doors: a standing player walks lot -> entrance -> reception -> hall door -> both sections and each station: " + str(stuck))
	print("warehouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
