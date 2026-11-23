extends RefCounted

# Places the named plush NPCs listed in data/house_characters.json around the Home
# zone in simple static poses. They live under Main (unscaled, like the player BonBon),
# carry `character_name` metadata so a click shows their name, and never count as
# vocabulary study. Edit the JSON to rename or move them. Each has a permanent unique
# `id` (node name and `character_id` metadata); names are display text only, so two
# characters may look alike and share a name.

const DATA := "res://data/house_characters.json"
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const DIRECTIONS := {"+x": Vector3.RIGHT, "-x": Vector3.LEFT, "+z": Vector3.BACK, "-z": Vector3.FORWARD}
# How far a body settles into the cushion, mattress or floor it rests on.
const SINK := 0.03
# Seated pose (any plush: they all share Torso, Foot and Foot_2): the paws swing forward
# from under the body so the soles face out, the body leans back and sinks into the seat.
const SIT_LEG_SWING := 1.35
const SIT_RECLINE := 0.12
const SIT_SINK := 0.07
# Characters and animals are solid (1 Nov 2026): solidify_figures() gives each one a box
# body on FIGURE_LAYER, which only the player's mask includes, so picking, vehicles, the
# camera and the animals' own obstacle probes (mask 1) behave as before.
const FIGURE_LAYER := 256
const FIGURE_DIRS := ["res://scenes/characters/", "res://scenes/animals/"]
const FIGURE_SCRIPTS := ["res://scripts/world/park_animals.gd", "res://scripts/world/crab.gd"]
# The box covers this share of a figure's width and depth (paws, ears and tails overhang).
const BLOCKER_SPREAD := 0.8

func build(game) -> Node3D:
	var root := Node3D.new()
	root.name = "HouseCharacters"
	game.add_child(root)
	var apartment: Node3D = game.apartment
	var turn := apartment.global_basis.orthonormalized()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var ids := {}
	var bedtime := Bedtime.new()
	bedtime.name = "Bedtime"
	bedtime.game = game
	bedtime.placer = self
	for spec in data["characters"]:
		var id := str(spec.get("id", ""))
		if not id.is_valid_identifier() or id != id.to_lower() or ids.has(id):
			push_error("house_characters.json: missing, invalid or duplicate id '%s' (%s)" % [id, spec.get("name", "")])
			continue
		ids[id] = true
		# "in_house": false keeps a character (still an avatar and tutorial stand-in) out of the house.
		if not bool(spec.get("in_house", true)):
			continue
		var npc: Node3D = load(str(spec["scene"])).instantiate()
		npc.name = id
		npc.set_meta("character_id", id)
		npc.set_meta("character_name", str(spec["name"]))
		npc.set_meta("character_species", str(spec["species"]))
		root.add_child(npc)
		# facing is an axis name, or an [x, z] vector for seats angled toward a table or view.
		var facing: Vector3
		if spec["facing"] is Array:
			facing = Vector3(float(spec["facing"][0]), 0, float(spec["facing"][1])).normalized()
		else:
			facing = DIRECTIONS[str(spec["facing"])]
		var pose := Basis.looking_at(facing, Vector3.UP)
		var rest_feet := {}
		for foot_name in ["Foot", "Foot_2"]:
			if npc.has_node(foot_name):
				rest_feet[foot_name] = (npc.get_node(foot_name) as Node3D).transform
		if str(spec["pose"]) == "sit":
			_sit(npc)
			pose = pose * Basis(Vector3.RIGHT, SIT_RECLINE)
			# Against a backrest the tail tucks away behind the body instead of poking through.
			if spec.has("back"):
				for tail in npc.find_children("Tail*", "MeshInstance3D", false, false):
					tail.visible = false
		elif str(spec["pose"]) == "lie":
			# On its back: the head points along `facing` and the face looks up.
			# The tail would poke down through the bed or lounger, so it stays tucked away.
			pose = Basis(facing.cross(Vector3.DOWN), facing, Vector3.DOWN)
			for tail in npc.find_children("Tail*", "MeshInstance3D", false, false):
				tail.visible = false
		var spot: Array = spec["position"]
		npc.global_transform = Transform3D(turn * pose, apartment.to_global(Vector3(spot[0], spot[1], spot[2])))
		# Rest the body on its surface: the lowest point (tails excluded, they tuck
		# behind or under) touches the seat, mattress or pool floor.
		var surface := npc.global_position.y
		var sink := SIT_SINK if str(spec["pose"]) == "sit" else SINK
		npc.global_position.y += surface - sink + _extent(npc, Vector3.DOWN)
		# `back` is a point on the backrest's front face: slide the body back until it rests there.
		if spec.has("back"):
			var away := (turn * -facing).normalized()
			var rest := apartment.to_global(Vector3(float(spec["back"][0]), spot[1], float(spec["back"][1])))
			npc.global_position += away * (rest.dot(away) + SINK - _extent(npc, away))
		# Optional outfit (data/plush_costumes.json), dressed after placement so it
		# never changes how the plush sits or rests against a backrest.
		if spec.has("costume"):
			PlushCostume.dress(npc, str(spec["costume"]))
		# The seat or bed contact point: seating_controller.gd treats that seat as taken.
		if str(spec["pose"]) in ["sit", "lie"]:
			npc.set_meta("seat_point", apartment.to_global(Vector3(spot[0], spot[1], spot[2])))
		if str(spec["pose"]) == "sit":
			bedtime.add(npc, rest_feet)
	root.add_child(bedtime)
	return root

## The plush scene of a character id ("" when unknown); also the profiles' avatars.
static func scene_of(id: String) -> String:
	return str(spec_of(id).get("scene", ""))

## A character's entry in data/house_characters.json ({} when unknown).
static func spec_of(id: String) -> Dictionary:
	for spec in _characters():
		if str(spec.get("id", "")) == id:
			return spec
	return {}

## The display name of a character id ("" when unknown).
static func name_of(id: String) -> String:
	return str(spec_of(id).get("name", ""))

## Every character id, in data order (the welcome tutorial picks stand-ins in this order).
static func ids() -> Array:
	return _characters().map(func(spec) -> String: return str(spec.get("id", "")))

static func _characters() -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return data.get("characters", []) if data is Dictionary else []

# Every visible character and animal outside the player and vehicles joins group
# "figures" and gets a FigureBlocker. Run once the world, its characters and the area
# vocabulary index exist (seating_controller.gd setup), so word zones are unchanged.
# `root`: only below it (a unit added later by the app's staged loading, 13 Nov 2026).
static func solidify_figures(game, root: Node = null) -> int:
	var count := 0
	var pending: Array[Node] = [game if root == null else root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node == game.player or node is DriveableVehicle:
			continue
		if node != game and node is Node3D and _is_figure(node):
			if node.is_visible_in_tree():
				node.add_to_group("figures")
				if fit_blocker(node):
					count += 1
			continue
		pending.append_array(node.get_children())
	return count

static func _is_figure(node: Node3D) -> bool:
	if node.has_meta("character_name"):
		return true
	for folder in FIGURE_DIRS:
		if node.scene_file_path.begins_with(folder):
			return true
	var script: Script = node.get_script()
	if script != null and script.resource_path in FIGURE_SCRIPTS:
		return true
	var parent := node.get_parent()
	return parent != null and str(parent.name) in ["People", "Animals"] and str(node.get_meta("word_key", "")) != ""

# Box the figure's visible meshes in its own space (it moves, scales and turns with the
# figure). Called again after a pose change. Figures that already own a solid body (the
# giant BonBon mascot's SolidBody) are left as they are, and so are figures with meta
# `figure_blocker` false (the lagoon fish under the water, which the swan boat passes over).
static func fit_blocker(node: Node3D) -> bool:
	if not node.get_meta("figure_blocker", true):
		return false
	var body := node.get_node_or_null("FigureBlocker") as StaticBody3D
	if body == null:
		for child in node.get_children():
			if child is StaticBody3D and child.collision_layer != 0:
				return false
	var inverse := node.global_transform.affine_inverse()
	var bounds := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.visible:
			continue
		var box: AABB = inverse * mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if first or bounds.size.y < .05:
		return false
	if body == null:
		body = StaticBody3D.new()
		body.name = "FigureBlocker"
		body.collision_layer = FIGURE_LAYER
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.shape = BoxShape3D.new()
		body.add_child(collision)
		node.add_child(body)
	var shape := body.get_child(0) as CollisionShape3D
	(shape.shape as BoxShape3D).size = Vector3(bounds.size.x * BLOCKER_SPREAD, bounds.size.y, bounds.size.z * BLOCKER_SPREAD)
	shape.position = bounds.get_center()
	return true

# A plush at work in town (waiters, cooks and the cashier replaced the old cook model,
# 1 Nov 2026). Instanced under `parent` (it moves with that building), it teaches `word`
# when clicked. Like the sheep doctor it is BonBon-sized (world scale 1), looks along
# `facing` and rests its lowest point on `spot` (global coordinates). An empty `outfit`
# leaves the plush undressed (the clothing-store shopper).
func worker(scene: String, outfit: String, word: String, parent: Node3D, title: String, spot: Vector3, facing: Vector3) -> Node3D:
	var npc: Node3D = load(scene).instantiate()
	npc.name = title
	parent.add_child(npc)
	npc.set_meta("word_key", word)
	npc.global_transform = Transform3D(Basis.looking_at(Vector3(facing.x, 0, facing.z).normalized(), Vector3.UP), spot)
	npc.global_position.y += spot.y + _extent(npc, Vector3.DOWN)
	if outfit != "":
		PlushCostume.dress(npc, outfit)
	return npc

# A plush seated at a seat that is not a Home seat (the Alta Cocina customer, 6 Nov 2026):
# the same seated pose as the house characters (paws forward, slight recline, tail tucked),
# its base resting on `seat` (global) and its back against `back` (a global point on the
# backrest face), looking along `facing`. Not dressed; the caller sets word and name metas.
func seated(scene: String, parent: Node3D, title: String, seat: Vector3, facing: Vector3, back: Vector3) -> Node3D:
	var npc: Node3D = load(scene).instantiate()
	npc.name = title
	parent.add_child(npc)
	_sit(npc)
	var look := Vector3(facing.x, 0, facing.z).normalized()
	npc.global_transform = Transform3D(Basis.looking_at(look, Vector3.UP) * Basis(Vector3.RIGHT, SIT_RECLINE), seat)
	for tail in npc.find_children("Tail*", "MeshInstance3D", false, false):
		tail.visible = false
	npc.global_position.y += seat.y - SIT_SINK + _extent(npc, Vector3.DOWN)
	var away := -look
	npc.global_position += away * (back.dot(away) + SINK - _extent(npc, away))
	return npc

# Farthest any visible body vertex (tails excluded, they tuck behind or under; costumes
# excluded, they never move a plush) reaches along `direction`.
func _extent(npc: Node3D, direction: Vector3) -> float:
	var farthest := -INF
	for mesh in npc.find_children("*", "MeshInstance3D", true, false):
		var path := str(npc.get_path_to(mesh))
		if "Tail" in path or "Costume" in path or not mesh.is_visible_in_tree():
			continue
		for point in _vertices(mesh, mesh.global_transform):
			farthest = maxf(farthest, point.dot(direction))
	return farthest

func _vertices(mesh: MeshInstance3D, to_space: Transform3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for surface in range(mesh.mesh.get_surface_count()):
		for vertex in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			points.append(to_space * vertex)
	return points

# Seated legs: each paw turns forward about its own center, rests at seat level with the
# body's base, and pokes out past the belly by about half its depth. Works in npc space.
func _sit(npc: Node3D) -> void:
	var to_npc := npc.global_transform.affine_inverse()
	var torso := PackedVector3Array()
	for mesh in npc.get_node("Torso").find_children("*", "MeshInstance3D", true, false):
		torso.append_array(_vertices(mesh, to_npc * mesh.global_transform))
	var seat_y := INF
	for point in torso:
		seat_y = minf(seat_y, point.y)
	var swing := Basis(Vector3.RIGHT, SIT_LEG_SWING)
	for foot_name in ["Foot", "Foot_2"]:
		var foot := npc.get_node_or_null(foot_name) as Node3D
		if foot == null:
			continue
		var paw := PackedVector3Array()
		for mesh in foot.find_children("*", "MeshInstance3D", true, false):
			paw.append_array(_vertices(mesh, to_npc * mesh.global_transform))
		var bounds := AABB(paw[0], Vector3.ZERO)
		for point in paw:
			bounds = bounds.expand(point)
		var center := bounds.get_center()
		var turned := Transform3D(swing, swing * -center) * bounds
		var y := seat_y + .02 - turned.position.y
		var front := INF
		for point in torso:
			if absf(point.y - y) < turned.size.y * .5 and absf(point.x - center.x) < .15:
				front = minf(front, point.z)
		if front == INF:
			continue
		var z := front + turned.size.z * .5 - turned.end.z
		# The recline lifts whatever is in front of the hips; start the paws that much lower.
		y += z * sin(SIT_RECLINE)
		foot.transform = Transform3D(swing, Vector3(center.x, y, z) - swing * center) * foot.transform

# Bedtime (1 Nov 2026): now and then a seated house character naps in a free Home bed (any
# word "bed" under RelocatedSites/Home) on its back, eyes shut, breathing slowly, and later
# returns to its own seat. It moves only while the learner is neither close to nor looking
# at either place, never takes the bed or seat the learner is using, and its seat_point
# follows it so seating_controller.gd keeps both the seat and the bed marked as taken.
class Bedtime extends Node:
	const AWAKE := Vector2(80.0, 220.0)
	const ASLEEP := Vector2(45.0, 110.0)
	const RETRY := 8.0
	const UNSEEN_DISTANCE := 9.0
	const VIEW_DISTANCE := 30.0
	var game
	var placer
	var sleepers: Array[Dictionary] = []
	var beds: Array = []
	var searched := false
	var rng := RandomNumberGenerator.new()
	var tick := 1.0
	var clock := 0.0

	func _init() -> void:
		rng.seed = 1101

	func add(npc: Node3D, rest_feet: Dictionary) -> void:
		var sit_feet := {}
		for foot in rest_feet:
			sit_feet[foot] = (npc.get_node(foot) as Node3D).transform
		var parts := {}
		for path in ["Torso"]:
			var part := npc.get_node_or_null(path) as Node3D
			if part != null:
				parts[path] = [part, part.scale]
		var tails := {}
		for tail in npc.find_children("Tail*", "MeshInstance3D", false, false):
			tails[tail] = tail.visible
		sleepers.append({"npc": npc, "seat": npc.global_transform, "seat_point": npc.get_meta("seat_point", npc.global_position),
			"sit_feet": sit_feet, "rest_feet": rest_feet, "parts": parts, "tails": tails, "bed": {},
			"phase": rng.randf() * TAU, "timer": rng.randf_range(AWAKE.x * .4, AWAKE.y)})

	func _process(delta: float) -> void:
		clock += delta
		for sleeper in sleepers:
			if not sleeper.bed.is_empty():
				breathe(sleeper)
		tick -= delta
		if tick > 0.0:
			return
		tick = 1.0
		var seating = game.get("seating")
		if seating == null or not is_instance_valid(game.player):
			return
		if not searched:
			searched = true
			var home: Node = preload("res://scripts/world/modular_town.gd").building(game.apartment, "home")
			for seat in seating.seats:
				if seat.get("bed", false) and home != null and home.is_ancestor_of(seat.node):
					beds.append(seat)
		if beds.is_empty():
			return
		for sleeper in sleepers:
			if not is_instance_valid(sleeper.npc):
				continue
			sleeper.timer -= 1.0
			if sleeper.timer > 0.0:
				continue
			if sleeper.bed.is_empty():
				lie_down(sleeper, seating)
			else:
				get_up(sleeper, seating)

	func unseen(points: Array) -> bool:
		var camera: Camera3D = game.camera
		for point in points:
			if game.player.global_position.distance_to(point) < UNSEEN_DISTANCE:
				return false
			if camera != null and camera.global_position.distance_to(point) < VIEW_DISTANCE and camera.is_position_in_frustum(point):
				return false
		return true

	func lie_down(sleeper: Dictionary, seating) -> void:
		sleeper.timer = RETRY
		var free: Array = []
		for bed in beds:
			if is_instance_valid(bed.node) and seating.occupant(bed) == null and not seating.player_at(bed.point, 1.6):
				free.append(bed)
		if free.is_empty():
			return
		var bed: Dictionary = free[rng.randi() % free.size()]
		seating.refresh(bed)
		if not unseen([sleeper.seat_point, bed.point]):
			return
		var npc: Node3D = sleeper.npc
		for foot in sleeper.rest_feet:
			(npc.get_node(foot) as Node3D).transform = sleeper.rest_feet[foot]
		for tail in sleeper.tails:
			tail.visible = false
		# Eyes belong to plush_life.gd: held shut, so no blinker opens them.
		PlushLife.hold_eyes(npc, true)
		# On its back like the "lie" pose: head toward the headboard, face up, the lowest
		# point sunk into the mattress and the body centred along the bed.
		var head: Vector3 = -bed.forward
		head.y = 0.0
		head = head.normalized()
		npc.global_transform = Transform3D(Basis(head.cross(Vector3.DOWN), head, Vector3.DOWN), bed.point)
		var surface := npc.global_position.y
		npc.global_position.y += surface - SINK + placer._extent(npc, Vector3.DOWN)
		var ahead: float = placer._extent(npc, head) - bed.point.dot(head)
		var behind: float = placer._extent(npc, -head) + bed.point.dot(head)
		npc.global_position += head * (behind - ahead) * 0.5
		npc.set_meta("seat_point", bed.point)
		placer.fit_blocker(npc)
		sleeper.bed = bed
		sleeper.timer = rng.randf_range(ASLEEP.x, ASLEEP.y)

	## Every sleeper back to its seat at once, seen or not (the welcome tutorial needs the beds free,
	## tutorial.gd _set_naps()).
	func wake_all(seating) -> void:
		for sleeper in sleepers:
			if is_instance_valid(sleeper.npc) and not sleeper.bed.is_empty():
				get_up(sleeper, seating, true)

	func get_up(sleeper: Dictionary, seating, force := false) -> void:
		sleeper.timer = RETRY
		if not force and (seating.player_at(sleeper.seat_point, 1.0) or not unseen([sleeper.seat_point, sleeper.bed.point])):
			return
		var npc: Node3D = sleeper.npc
		npc.global_transform = sleeper.seat
		for foot in sleeper.sit_feet:
			(npc.get_node(foot) as Node3D).transform = sleeper.sit_feet[foot]
		for tail in sleeper.tails:
			tail.visible = sleeper.tails[tail]
		for path in sleeper.parts:
			sleeper.parts[path][0].scale = sleeper.parts[path][1]
		PlushLife.hold_eyes(npc, false)
		npc.set_meta("seat_point", sleeper.seat_point)
		placer.fit_blocker(npc)
		sleeper.bed = {}
		sleeper.timer = rng.randf_range(AWAKE.x, AWAKE.y)

	# A slow breath swells the body's width and depth (not its length), about every 4 s.
	func breathe(sleeper: Dictionary) -> void:
		if not sleeper.parts.has("Torso"):
			return
		var breath := sin(clock * 1.6 + sleeper.phase)
		var torso: Array = sleeper.parts["Torso"]
		torso[0].scale = PlushLife.breath_scale(torso[1], breath)
