extends SceneTree
## Clay monkey and sheep roam, and a flock round the hen house (user, 25 Nov 2026: "update the
## monkey and sheep, and place few chicken and chick around the hen house, have them move
## naturally"): base step `monkey_sheep_clay_roam` (scripts/buildings/base.gd), barn step
## `hen_house_flock` (scripts/buildings/barn.gd) and the unrigged gait (park_animals.gd GAITS).
## Checks: ParkZoo/Monkey and ParkZoo/Sheep are the clay models (word, size, wandering) and the
## still monkey display is gone; the hen house has 8 hens, a rooster and 5 chicks, all wandering
## in the hen yard; after some seconds of play they have moved, the gait has moved their models,
## every bird is still in the yard and each chick is near its hen (headless only). With a window
## it takes pictures instead of the movement checks.
##   HOME=<scratch> VT_SPAWN=none VT_NEARBY=0 godot --headless --fixed-fps 60 --path . --script res://docs/evidence/farm-flock-20261125/verify.gd
##   HOME=<scratch> VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1200x800 --audio-driver Dummy \
##     --script res://docs/evidence/farm-flock-20261125/verify.gd
## Writes no saves of its own (an isolated HOME keeps the game's).
const OUT := "res://docs/evidence/farm-flock-20261125"
const HenHouse := preload("res://scripts/world/hen_house.gd")
const Animals := preload("res://scripts/world/park_animals.gd")
const Barn := preload("res://scripts/buildings/barn.gd")

var checks := 0
var failures := 0
var game
var ap: Node3D
var camera: Camera3D

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func town(x: float, y: float, z: float) -> Vector3:
	return ap.to_global(Vector3(x, y, z))

func run() -> void:
	var graphics := DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await physics_frame
	for key in game.pending_units.duplicate():
		await game.add_unit(key)
	for i in 10: await physics_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(11 * 60.0)
	ap = game.apartment
	var zoo: Node3D = ap.get_node("ParkZoo")
	for spec in [["Monkey", "monkey"], ["Sheep", "sheep"]]:
		var animal: Node3D = zoo.get_node_or_null(spec[0])
		check(animal != null and animal.has_node("Clay" + spec[0]), "ParkZoo/%s is the clay %s" % spec)
		if animal == null:
			continue
		check(str(animal.get_meta("word_key", "")) == spec[1], "%s keeps the word %s" % spec)
		check(animal.is_in_group("wandering_animals"), "%s wanders" % spec[0])
		# Measured at rest: the gait may be mid-hop or mid-peck.
		var body: Node3D = animal.get("_body")
		if body != null:
			body.transform = animal.get("_body_rest")
		var h: float = (animal.call("_visible_bounds") as AABB).size.y * animal.scale.y
		var want: float = Animals.display_height(spec[0], zoo.global_basis.get_scale().y)
		check(absf(h - want) < .02, "%s %.3f tall (display height %.3f)" % [spec[0], h, want])
		check(animal.get("_body") != null, "%s has the unrigged gait" % spec[0])
	check(zoo.get_node_or_null("MonkeyClayDisplay") == null, "the still monkey display is gone")
	var house: Node3D = ap.get_node("Barn/Hen house")
	var birds: Array = house.get_node("Hens").get_children()
	var hens := birds.filter(func(b): return str(b.name).begins_with("Hen "))
	var chicks := birds.filter(func(b): return str(b.name).begins_with("Chick "))
	check(hens.size() == 8, "8 hens (%d)" % hens.size())
	check(chicks.size() == 5, "5 chicks (%d)" % chicks.size())
	check(house.get_node("Hens").has_node("Rooster"), "a rooster")
	check(birds.all(func(b): return b.is_in_group("wandering_animals")), "every bird wanders")
	check(birds.all(func(b): return b.get("_body") != null), "every bird has the unrigged gait")
	check(hens.all(func(b): return str(b.get_meta("word_key", "")) == "hen"), "every hen has the word hen")
	check(chicks.all(func(b): return b.get("_leader") != null), "every chick follows a hen")
	var start := {}
	var rests := {}
	for b in birds + [zoo.get_node("Monkey"), zoo.get_node("Sheep")]:
		start[b] = b.position
		rests[b] = b.get("_body_rest")
	var posed := {}
	var farthest := {}
	if graphics:
		await _shot(town(79.5, 6.5, 88.5), town(79.5, .3, 77.5), "yard")
	# Headless runs the 40 s of play and the movement checks; a window (often throttled in the
	# background) takes the pictures over 12 s and skips them.
	var seconds := 12 if graphics else 40
	for second in seconds:
		for i in 60: await process_frame
		for b in start:
			farthest[b] = maxf(farthest.get(b, 0.0), b.position.distance_to(start[b]))
			var body: Node3D = b.get("_body")
			if body != null and not body.transform.is_equal_approx(rests[b]):
				posed[b] = true
		if graphics and second == 3:
			await _shot(town(75.5, 2.4, 84.0), town(75.8, .3, 78.5), "chicks")
		if graphics and second == 6:
			var s: Node3D = zoo.get_node("Sheep")
			var sp: Vector3 = zoo.to_global(s.position)
			await _shot(sp + Vector3(2.6, 1.8, -2.6), sp + Vector3(0, .6, 0), "sheep")
		if graphics and second == 9:
			var m: Node3D = zoo.get_node("Monkey")
			var mp: Vector3 = zoo.to_global(m.position)
			await _shot(mp + Vector3(2.0, 1.6, -2.4), mp + Vector3(0, .5, 0), "monkey")
	if graphics:
		await _shot(town(79.5, 6.5, 88.5), town(79.5, .3, 77.5), "yard-later")
		print("FARM FLOCK: %d checks, %d failures (pictures only; movement checked headless)" % [checks, failures])
		quit(1 if failures > 0 else 0)
		return
	var moved := start.keys().filter(func(b): return farthest[b] > .3)
	print("farthest from start: ", ", ".join(start.keys().map(func(b): return "%s %.2f" % [b.name, farthest[b]])))
	for b in start.keys().filter(func(b): return farthest[b] <= .3):
		_why_stuck(b)
	check(moved.size() >= start.size() - 2, "%d of %d animals went more than 0.3 from their start in 40 s" % [moved.size(), start.size()])
	check(posed.size() >= start.size() - 2, "%d of %d models were posed by the gait" % [posed.size(), start.size()])
	var yard: Rect2 = HenHouse.HEN_YARD
	check(birds.all(func(b): return yard.has_point(Vector2(b.position.x, b.position.z))), "every bird is in the hen yard")
	for c in chicks:
		var hen: Node3D = c.get("_leader")
		var gap := Vector2(c.position.x - hen.position.x, c.position.z - hen.position.z).length()
		check(gap < 4.0, "%s is %.2f from %s" % [c.name, gap, hen.name])
	print("FARM FLOCK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _shot(from: Vector3, at: Vector3, file: String) -> void:
	if camera == null:
		camera = Camera3D.new()
		game.add_child(camera)
		camera.fov = 60.0
		camera.far = 900.0
	camera.current = true
	camera.global_position = from
	camera.look_at(at)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + file + ".png")
	camera.current = false

## What keeps an animal from stepping: its habitat, and what its wander probe meets where it stands.
func _why_stuck(b: Node3D) -> void:
	var q: PhysicsShapeQueryParameters3D = b.get("_query")
	var parent := b.get_parent() as Node3D
	q.transform = Transform3D(Basis.IDENTITY, parent.to_global(b.position + Vector3(0, b.get("_foot_y") + .4, 0)))
	q.motion = Vector3.ZERO
	var hits: Array = b.get_world_3d().direct_space_state.intersect_shape(q, 4)
	var names: Array = hits.map(func(h): return str(ap.get_path_to(h.collider)) if ap.is_ancestor_of(h.collider) else str(h.collider.name))
	var near: Array = []
	for other in b.get_tree().get_nodes_in_group("wandering_animals"):
		if other != b and other.get_parent() == parent and Vector2(other.position.x - b.position.x, other.position.z - b.position.z).length() < b.footprint + other.footprint + .1:
			near.append(str(other.name))
	print("STUCK %s at %s: footprint %.2f, habitat %s, in habitat %s, probe hits %s, crowded by %s" % [b.name, b.position, b.footprint, b.habitat, b.habitat.has_point(Vector2(b.position.x, b.position.z)), names, near])
