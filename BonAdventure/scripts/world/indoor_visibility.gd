extends Node
## Indoor visibility, "hide far, keep near" (user decision, 14 Nov 2026): while the player is
## inside a building, only that building, its yard and the street right outside (KEEP_MARGIN
## around the building's box) are drawn; other buildings and the far town are hidden until the
## player steps out. A big phone speed-up: from the home bedroom the whole town drew behind the
## walls. Rules and measurements: docs/guides/performance/README.md ("Indoor visibility").
##
## - What is hidden: whole objects, never single props. An object is a building unit part
##   (data/buildings.json, e.g. "RelocatedSites/Library"; People/* parts are skipped) or a
##   base-world node of at most CHUNK_MAX metres: a top-level child of the town, else one of its
##   children (or grandchildren) found by splitting a bigger one. Static batches (render_culling's
##   StaticRenderBatches and Unit_<key> containers, the garden's RenderBatches) hold pieces of
##   many objects: each hidden original ("render_batched") is matched to its batch instance by
##   material, mesh and position, linking objects and batches. Objects whose box reaches the keep
##   box (XZ) stay, and so does everything linked to them, object to batch to object, so a kept
##   object never loses a batched piece (a tree its canopy, a bridge its towers, a building a
##   wall) and a hidden one leaves none behind. Batches holding pieces of no object (huge or deep
##   nodes) are never hidden. Animals and vehicles (movers) are judged by their position, again
##   at every check; characters, terrain, roads and anything else are never touched. Collision,
##   word areas, doors and minimap geometry are unchanged (only `visible` changes, and only on
##   nodes visible at setup; only what this hid is shown again).
## - When: every CHECK_INTERVAL seconds, five rays (a roof overhead and walls on 3 of 4 sides,
##   as day_night.gd) decide indoors; the building is the smallest unit-part box around the
##   player. Hiding waits for HIDE_AFTER_CHECKS indoor checks in a row (after entering); within
##   DOOR_REVEAL metres of a door that leads outside, with an entrance in reach
##   (_opening_near(): shop entrances have no door), while driving or flying (noclip), or
##   outside a unit building, everything is drawn, so the town is back when the doorway is
##   reached, never after stepping out. Doors leading outside are found once per door with up
##   rays beside it (no roof on one side).
## - Cost: batch indexing and object boxes are measured over the first frames after loading
##   within SCAN_BUDGET_USEC per frame (again for a unit added later by Main.add_unit:
##   unit_added); nothing hides before that is done. Visibility changes are spread over frames
##   within TOGGLE_BUDGET_USEC (more when revealing).
## Hooked once from main.gd after the render trim; read-only use of main's doors, player,
## apartment, active_vehicle.

const ModularTown := preload("res://scripts/world/modular_town.gd")

const CHECK_INTERVAL := 0.25
const HIDE_AFTER_CHECKS := 2
## Metres kept around the player's building: its yard and the street right outside.
const KEEP_MARGIN := 22.0
## Within this distance (XZ) of a door that leads outside, everything is drawn.
const DOOR_REVEAL := 4.0
## Distances at which the player looks for open air through an entrance (_opening_near()).
const OPENING_RADII: Array[float] = [2.0, 4.0, 6.0]
const OPENING_HEIGHT := 0.6
## A clear way out of the building's box within this distance counts as an entrance in reach.
const EXIT_REACH := 8.0
const ROOF_RAY := 30.0
const WALL_REACH := 40.0
const SCAN_BUDGET_USEC := 1500
const TOGGLE_BUDGET_USEC := 2000
const REVEAL_BUDGET_USEC := 8000
## Largest base-world object (longest box side, metres); bigger nodes are split into children.
const CHUNK_MAX := 60.0
## How many levels below a top-level town node an object may be (deeper nodes are never hidden).
const MAX_SPLIT_DEPTH := 3
## Top-level nodes never split into objects (batch containers, characters).
const SKIPPED_ROOTS: Array[String] = ["StaticRenderBatches", "People"]
## Half size of the box a moving object (animal, vehicle) is judged by, around its position.
const MOVER_REACH := 8.0
const MOVER_SCENE_DIRS: Array[String] = ["res://scenes/animals/", "res://scenes/props/vehicles/"]

var _game: Node3D
var _town: Node3D
## Chunks (objects and batches): {"node", "box": AABB (world), "ready", "hidden", "want",
## "part" (a unit part: a building), "batch", "mover", "links": Array of chunk indices,
## "claims" (an object's batch index -> pieces in it), "claimed" (a batch's pieces owned)}.
var _chunks: Array = []
var _movers: Array = []
var _seen_containers := {}
var _part_paths := {}
## Piece key [material id, mesh id, Vector3i position] -> batch chunk index.
var _pieces := {}
## Work over frames, first in first out: ["batch", index, next instance] or
## ["object", node, depth, stack, chunk index or -1, box, linked batches].
var _jobs: Array = []
var _timer := 0.0
var _inside_checks := 0
var _hiding := false
var _keep := AABB()
var _cursor := 0
var _dirty := false
## Door node instance id -> {"centre": Vector3, "outside": bool}.
var _doors := {}
var _ray := PhysicsRayQueryParameters3D.new()


func setup(game: Node3D) -> void:
	_game = game
	_town = game.apartment
	name = "IndoorVisibility"
	var units := ModularTown.registry()
	var parent_roots := {}
	for key in units:
		for path in units[key].parts:
			_part_paths[str(path)] = true
			if str(path).contains("/"):
				parent_roots[str(path).get_slice("/", 0)] = true
	_add_batches()
	var loaded = _town.get_meta("loaded_units", null)
	for key in units:
		if loaded == null or (loaded as Array).has(key):
			_add_unit_parts(units[key].parts)
	for child in _town.get_children():
		if not child is Node3D or str(child.name) in SKIPPED_ROOTS or _part_paths.has(str(child.name)):
			continue
		if parent_roots.has(str(child.name)):
			for grandchild in child.get_children():
				if grandchild is Node3D and not _part_paths.has(str(_town.get_path_to(grandchild))):
					_add_object(grandchild, 1)
		else:
			_add_object(child, 0)
	if game.has_signal("unit_added"):
		game.unit_added.connect(_on_unit_added)


## Number of chunks hidden right now (checks and the perf probe).
func hidden_count() -> int:
	var count := 0
	for chunk in _chunks:
		if chunk.hidden:
			count += 1
	return count


## Whether the far town is hidden now (the player is inside a building).
func is_hiding() -> bool:
	return _hiding


func _on_unit_added(key: String) -> void:
	_add_batches()
	var units := ModularTown.registry()
	if units.has(key):
		_add_unit_parts(units[key].parts)


func _add_unit_parts(paths: Array) -> void:
	for path in paths:
		if str(path).begins_with("People/"):
			continue
		var node := _town.get_node_or_null(NodePath(path)) as Node3D
		if node == null:
			continue
		# A unit added later may fill a site pivot that was already measured: measure it again.
		var index := -1
		for i in _chunks.size():
			if _chunks[i].node == node:
				index = i
		if index >= 0:
			_unlink(index)
		_jobs.append(["object", node, 0, [node], index, AABB(), {}, true])


func _add_object(node: Node3D, depth: int) -> void:
	# A merged original (hidden by the batching) still links its batch to an object, but is
	# never shown; anything else hidden at setup belongs to someone else and is left alone.
	if (not node.visible and not node.has_meta("render_batched")) or node.name == "RenderBatches":
		return
	var path := node.scene_file_path
	var mover := (node is PhysicsBody3D and not node is StaticBody3D) or node.is_processing() \
		or node.is_physics_processing()
	for dir in MOVER_SCENE_DIRS:
		mover = mover or path.begins_with(dir)
	if mover:
		var chunk := _new_chunk(node)
		chunk.mover = true
		chunk.ready = true
		_chunks.append(chunk)
		_movers.append(chunk)
		return
	_jobs.append(["object", node, depth, [node], -1, AABB(), {}, false])


func _new_chunk(node: Node3D) -> Dictionary:
	return {"node": node, "box": AABB(), "ready": false, "hidden": false, "want": false, "part": false,
		"toggle": node.visible,
		"batch": false, "mover": false, "links": [], "claims": {}, "claimed": 0}


func _add_batches() -> void:
	var holders: Array = []
	var static_batches := _town.get_node_or_null("StaticRenderBatches")
	if static_batches != null:
		holders.append(static_batches)
		for child in static_batches.get_children():
			if not child is MultiMeshInstance3D:
				holders.append(child)
	var garden := _town.get_node_or_null("PublicGarden/RenderBatches")
	if garden != null:
		holders.append(garden)
	for holder in holders:
		var id: int = holder.get_instance_id()
		if _seen_containers.has(id):
			continue
		_seen_containers[id] = true
		for batch in holder.get_children():
			if batch is MultiMeshInstance3D and batch.visible and batch.multimesh != null:
				var chunk := _new_chunk(batch)
				chunk.batch = true
				chunk.ready = true
				chunk.box = batch.global_transform * batch.get_aabb()
				_chunks.append(chunk)
				_jobs.append(["batch", _chunks.size() - 1, 0])


static func _piece_key(material: Material, mesh: Mesh, origin: Vector3) -> Array:
	return [material.get_instance_id() if material != null else 0,
		mesh.get_instance_id() if material == null and mesh != null else 0,
		Vector3i((origin * 50.0).round())]


func _process(delta: float) -> void:
	if _town == null or not is_instance_valid(_town):
		return
	if not _jobs.is_empty():
		_work()
	_timer += delta
	if _timer >= CHECK_INTERVAL:
		_timer = 0.0
		_check()
	if _cursor < _chunks.size():
		_apply_step()


# Indexes batch instances and measures objects (box, linked batches) within the frame budget.
func _work() -> void:
	var start := Time.get_ticks_usec()
	while not _jobs.is_empty() and Time.get_ticks_usec() - start < SCAN_BUDGET_USEC:
		var job: Array = _jobs[0]
		if job[0] == "batch":
			var chunk: Dictionary = _chunks[job[1]]
			var batch: MultiMeshInstance3D = chunk.node
			if not is_instance_valid(batch):
				_jobs.pop_front()
				continue
			var instances := batch.multimesh
			var end := mini(job[2] + 400, instances.instance_count)
			var pose := batch.global_transform
			for i in range(job[2], end):
				_pieces[_piece_key(batch.material_override, instances.mesh, (pose * instances.get_instance_transform(i)).origin)] = job[1]
			job[2] = end
			if end >= instances.instance_count:
				_jobs.pop_front()
			continue
		if _scan_object(job):
			_jobs.pop_front()
			_finish_object(job)


# One slice of an object's subtree: box and batched originals. True when the subtree is done.
func _scan_object(job: Array) -> bool:
	var stack: Array = job[3]
	var steps := 0
	while not stack.is_empty() and steps < 200:
		steps += 1
		var item: Variant = stack.pop_back()
		# Staged loading frees and puts back nodes (plush characters) while this runs.
		if not is_instance_valid(item):
			continue
		var node: Node = item
		if node is GeometryInstance3D:
			var box: AABB = node.global_transform * node.get_aabb()
			if box.size != Vector3.ZERO:
				job[5] = box if job[5].size == Vector3.ZERO else job[5].merge(box)
			if node.has_meta("render_batched"):
				var mesh: Mesh = node.mesh if node is MeshInstance3D else null
				var key := _piece_key(node.material_override, mesh, node.global_position)
				if _pieces.has(key):
					job[6][_pieces[key]] = int(job[6].get(_pieces[key], 0)) + 1
		stack.append_array(node.get_children())
	return stack.is_empty()


# A measured object: too big (and not a unit part) -> its children are objects instead.
func _finish_object(job: Array) -> void:
	if not is_instance_valid(job[1]):
		return
	var node: Node3D = job[1]
	var box: AABB = job[5]
	var is_part: bool = job[7]
	if not is_part and box.get_longest_axis_size() > CHUNK_MAX:
		if job[2] < MAX_SPLIT_DEPTH:
			for child in node.get_children():
				if child is Node3D:
					_add_object(child, job[2] + 1)
		return
	var index: int = job[4]
	if index < 0:
		_chunks.append(_new_chunk(node))
		index = _chunks.size() - 1
	var chunk: Dictionary = _chunks[index]
	chunk.box = box
	chunk.part = is_part
	chunk.ready = box.size != Vector3.ZERO
	chunk.claims = job[6]
	for batch_index in job[6]:
		chunk.links.append(batch_index)
		_chunks[batch_index].links.append(index)
		_chunks[batch_index].claimed += job[6][batch_index]
	_dirty = true


func _unlink(index: int) -> void:
	var chunk: Dictionary = _chunks[index]
	for other in chunk.links:
		_chunks[other].links.erase(index)
		_chunks[other].claimed -= int(chunk.claims.get(other, 0))
	chunk.links.clear()
	chunk.claims = {}


func _check() -> void:
	var keep := AABB()
	var player: Node3D = _game.player
	if is_instance_valid(player) and player.is_inside_tree() and _indoors(player):
		var building := _building_at(player.global_position)
		if building.size != Vector3.ZERO and not _near_exit(player.global_position, building) \
				and not _opening_near(player, building):
			keep = building.grow(KEEP_MARGIN)
	_inside_checks = _inside_checks + 1 if keep.size != Vector3.ZERO else 0
	var hide := _inside_checks >= HIDE_AFTER_CHECKS
	# Hiding starts, and is decided again, only once every object is measured; showing never waits.
	if hide and not _jobs.is_empty():
		return
	if hide == _hiding and not _dirty and (not hide or keep.is_equal_approx(_keep)):
		# Animals and vehicles may have moved toward (or away from) the kept area.
		if _hiding and _cursor >= _chunks.size():
			for chunk in _movers:
				chunk.want = not _touches(_mover_box(chunk))
				_apply(chunk)
		return
	_hiding = hide
	_keep = keep if hide else AABB()
	_dirty = false
	_decide()
	_cursor = 0


func _touches(box: AABB) -> bool:
	return not (box.end.x < _keep.position.x or box.position.x > _keep.end.x \
		or box.end.z < _keep.position.z or box.position.z > _keep.end.z)


func _mover_box(chunk: Dictionary) -> AABB:
	var node: Node3D = chunk.node
	if not is_instance_valid(node):
		return AABB()
	return AABB(node.global_position - Vector3.ONE * MOVER_REACH, Vector3.ONE * MOVER_REACH * 2.0)


# Sets each chunk's "want" (hidden) for the current keep box: kept = objects reaching it, batches
# with pieces of no object, and everything linked to those, transitively.
func _decide() -> void:
	if not _hiding:
		for chunk in _chunks:
			chunk.want = false
		return
	var kept := {}
	var queue: Array = []
	for i in _chunks.size():
		var chunk: Dictionary = _chunks[i]
		var seed := false
		if chunk.mover:
			seed = _touches(_mover_box(chunk))
		elif chunk.batch:
			# A batch with a piece no object owns (a huge or deep node) is never hidden.
			var batch: MultiMeshInstance3D = chunk.node
			seed = not is_instance_valid(batch) or chunk.claimed < batch.multimesh.instance_count
		else:
			seed = not chunk.ready or _touches(chunk.box)
		if seed:
			kept[i] = true
			queue.append(i)
	while not queue.is_empty():
		var i: int = queue.pop_back()
		for other in _chunks[i].links:
			if not kept.has(other):
				kept[other] = true
				queue.append(other)
	for i in _chunks.size():
		_chunks[i].want = not kept.has(i)


func _apply(chunk: Dictionary) -> void:
	var node: Node3D = chunk.node
	if not is_instance_valid(node):
		return
	var hide: bool = _hiding and chunk.want
	if hide != chunk.hidden and chunk.toggle:
		chunk.hidden = hide
		node.visible = not hide


# Brings chunk visibility in line with the decision, a slice per frame.
func _apply_step() -> void:
	var start := Time.get_ticks_usec()
	var budget := TOGGLE_BUDGET_USEC if _hiding else REVEAL_BUDGET_USEC
	while _cursor < _chunks.size() and Time.get_ticks_usec() - start < budget:
		_cursor += 1
		_apply(_chunks[_cursor - 1])


# Indoors = a static roof overhead and static walls on at least 3 of 4 sides; never while
# driving or flying through walls.
func _indoors(player: Node3D) -> bool:
	if is_instance_valid(_game.get("active_vehicle")) or player.get("noclip_enabled"):
		return false
	var space := player.get_world_3d().direct_space_state
	var from := player.global_position + Vector3.UP * 1.6
	_ray.exclude = [player.get_rid()] if player is CollisionObject3D else []
	if not _solid(space, from, from + Vector3.UP * ROOF_RAY):
		return false
	var walls := 0
	for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		if _solid(space, from, from + side * WALL_REACH):
			walls += 1
	return walls >= 3


func _solid(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	_ray.from = from
	_ray.to = to
	var hit := space.intersect_ray(_ray)
	return not hit.is_empty() and hit.collider is StaticBody3D


# Whether an entrance is in reach in one of 8 directions: a ray at OPENING_HEIGHT (under window
# sills: glass panes have no collision) is clear until it leaves the building's box within
# EXIT_REACH metres (out through a doorway and under its canopy), or reaches a spot within
# OPENING_RADII with no roof above (a courtyard). At most 8 + 24 short rays; walls and closed
# doors stop the first ray.
func _opening_near(player: Node3D, building: AABB) -> bool:
	var space := player.get_world_3d().direct_space_state
	var from := player.global_position + Vector3.UP * OPENING_HEIGHT
	_ray.exclude = [player.get_rid()] if player is CollisionObject3D else []
	var reach: float = OPENING_RADII[OPENING_RADII.size() - 1]
	for i in 8:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, i * PI / 4.0)
		var exit := _box_exit(from, direction, building) + 0.5
		var length := maxf(reach, exit) if exit <= EXIT_REACH else reach
		_ray.from = from
		_ray.to = from + direction * length
		var hit := space.intersect_ray(_ray)
		var clear := length if hit.is_empty() else from.distance_to(hit.position) - 0.3
		if exit <= EXIT_REACH and clear >= exit:
			return true
		for radius in OPENING_RADII:
			if radius > clear:
				break
			var spot := from + direction * radius
			if not _solid(space, spot, spot + Vector3.UP * ROOF_RAY):
				return true
	return false


# Distance (XZ) from `from` along `direction` to where it leaves `box`.
static func _box_exit(from: Vector3, direction: Vector3, box: AABB) -> float:
	var exit := INF
	if direction.x > 0.001:
		exit = minf(exit, (box.end.x - from.x) / direction.x)
	elif direction.x < -0.001:
		exit = minf(exit, (box.position.x - from.x) / direction.x)
	if direction.z > 0.001:
		exit = minf(exit, (box.end.z - from.z) / direction.z)
	elif direction.z < -0.001:
		exit = minf(exit, (box.position.z - from.z) / direction.z)
	return exit


# The smallest measured unit-part box (XZ area) around `point` that rises above its head (flat
# parts such as a forecourt or sign never count as the building).
func _building_at(point: Vector3) -> AABB:
	var best := AABB()
	var best_area := INF
	for chunk in _chunks:
		if not chunk.part or not chunk.ready:
			continue
		var box: AABB = chunk.box
		if point.x < box.position.x or point.x > box.end.x or point.z < box.position.z or point.z > box.end.z \
				or point.y < box.position.y - 1.0 or point.y + 2.0 > box.end.y:
			continue
		var area := box.size.x * box.size.z
		if area < best_area:
			best_area = area
			best = box
	return best


# Whether `point` is within DOOR_REVEAL of a door of `building` that leads outside.
func _near_exit(point: Vector3, building: AABB) -> bool:
	var area := building.grow(1.0)
	for door in _game.doors:
		if not is_instance_valid(door) or not door is Node3D \
				or str(_game.doors[door].get("type", "")) == "curtain":
			continue
		var info := _door_info(door)
		var centre: Vector3 = info.centre
		if not area.has_point(centre):
			continue
		if not info.has("outside"):
			info.outside = _leads_outside(door, centre)
		if info.outside and Vector2(centre.x - point.x, centre.z - point.z).length() <= DOOR_REVEAL:
			return true
	return false


func _door_info(door: Node3D) -> Dictionary:
	var id := door.get_instance_id()
	if not _doors.has(id):
		var box := AABB()
		var meshes: Array = door.find_children("*", "GeometryInstance3D", true, false)
		if door is GeometryInstance3D:
			meshes.append(door)
		for mesh in meshes:
			var part: AABB = mesh.global_transform * mesh.get_aabb()
			box = part if box.size == Vector3.ZERO else box.merge(part)
		_doors[id] = {"centre": box.get_center() if box.size != Vector3.ZERO else door.global_position}
	return _doors[id]


# A door leads outside when a spot beside it (1.5 or 3 m away, any side) has no roof above.
func _leads_outside(door: Node3D, centre: Vector3) -> bool:
	var space := door.get_world_3d().direct_space_state
	_ray.exclude = []
	for distance in [1.5, 3.0]:
		for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			var spot: Vector3 = centre + side * distance
			if not _solid(space, spot, spot + Vector3.UP * ROOF_RAY):
				return true
	return false
