extends RefCounted
## Runtime render-cost trim, applied once after the world is built and batched.
## - Web build: 3D at CSS pixel size on high-density screens (apply_web_3d_scale).
## - No sun shadows (one graphics setting since 23 Nov 2026, below).
## - Script-built spheres/cylinders drop Godot's 64-segment default to a budget
##   scaled by their world radius.
## - Small static props (largest AABB side under SMALL_PROP_SIZE) stop casting sun
##   shadows and are hidden beyond SMALL_PROP_RANGE metres; other props under
##   RANGED_MAX_SIZE are hidden once they shrink below ~1/SIZE_RANGE_RATIO radians.
## - Vehicles, animals, characters and other moving objects are sized as a whole:
##   their silhouette parts hide under ~1/OBJECT_RANGE_RATIO radians, small details
##   sooner; plush characters beyond PLUSH_RANGE (they live indoors).
## - Remaining static meshes are merged into MultiMeshes per cell/material/settings;
##   boxes, spheres and straight cylinders are normalised to shared unit meshes,
##   and only pieces lit by the same local lights (at most the per-object limit)
##   share a batch. The renderer's per-frame light cap (32 of 124 lights) already
##   drops some interior lights; merging can change which ones, see the docs.
## - One graphics setting (user, 23 Nov 2026: one consistent look that works on a phone; the
##   Low / High choice of 14 Nov 2026 and everything only High used were removed). apply_view()
##   at startup: no sun shadows, a VIEW_DISTANCE camera far with depth fog hiding the cut
##   (day_night.gd set_view_distance(); flying raises it with height, vehicle_controls.gd
##   update_flight_view()), the short visibility ranges above (up to SHORT_RANGE) times
##   RANGE_SHARE, heavy meshes to HEAVY_RANGE, MSAA 2x (since 17 Nov 2026), screen-space AA and
##   TAA off and, on the web, 3D at WEB_PIXEL_SHARE of the CSS pixel size but at least
##   WEB_MIN_LINES lines. The perf readout (perf_readout.gd: ?perf=1, F3, Settings) shows the cost.
## - Web build (14 Nov 2026, WebGL context loss): Label3D font sizes share a few
##   steps (share_label_sizes()), so far fewer glyph atlases sit in GPU memory.
## - Door leaves (17 Nov 2026): each door in Main.doors moves as one node, so its own static meshes
##   (slab, panels, mouldings, handles: 35 per home door) are merged into one mesh per material
##   under the door node (merge_door_leaves()); the frames around them were already batched.
## Nodes, collision, word areas, door metadata and interior roots are untouched;
## merged originals are only hidden, so the minimap still reads them (meta "render_batch" names
## each one's batch instance: show_batched() hides a merged prop's copies for a while). Animals,
## characters, vehicles, the player, doors, processing/swivel nodes and the
## toggled Home roof are never merged. Rules: docs/guides/performance/README.md; measured
## in docs/guides/FINAL_VERIFICATION.md ("render trim").

const SMALL_PROP_SIZE := 1.0
const SMALL_PROP_RANGE := 60.0
const MID_PROP_SIZE := 3.0
const MID_PROP_RANGE := 70.0
const SIZE_RANGE_RATIO := 60.0
const OBJECT_RANGE_RATIO := 100.0
const DETAIL_PART_SHARE := 0.3
const DETAIL_RANGE_SHARE := 0.4
const RANGED_MAX_SIZE := 10.0
const PLUSH_RANGE := 45.0
## The view (see the header): measured in docs/guides/performance/README.md ("Graphics tiers",
## all of it then called Low).
const VIEW_DISTANCE := 130.0
const RANGE_SHARE := 0.45
## Only the short ranges are shortened (small props, details, plush characters: up to this);
## larger pieces (building parts sized by SIZE_RANGE_RATIO) keep theirs and fade in the fog.
const SHORT_RANGE := 80.0
## A ranged object is never hidden nearer than this (plush characters stay to 20 m, not 45 x share).
const MIN_RANGE := 20.0
## A single mesh of at least HEAVY_TRIANGLES (the clay zoo animals, 60k-300k each) hides beyond
## HEAVY_RANGE even when it has no range of its own.
const HEAVY_TRIANGLES := 30000
const HEAVY_RANGE := 40.0
const WEB_PIXEL_SHARE := 0.8
const WEB_MIN_3D_SCALE := 0.25
## On the web the 3D is never drawn with fewer lines than this on the screen's short side
## (17 Nov 2026, user: on an iPhone 0.8 of the CSS size was only ~310 lines, so signs were
## unreadable and edges broke up). A laptop already draws about this many.
const WEB_MIN_LINES := 720.0
## 3D multisampling (17 Nov 2026, user: broken edges on road lines, cars and buildings on an
## iPhone). Road markings, signs and floor lines are plain-coloured geometry, so MSAA, not texture
## filtering, smooths them. 2x cost 17 MB of video memory at 1560 x 720 (4x: 34 MB) and no draw
## calls (docs/guides/performance/README.md "Graphics tiers"). Viewport.MSAA_DISABLED turns it off.
const MSAA := Viewport.MSAA_2X
## Web: every font size + outline pair a Label3D uses gets its own glyph atlas on the GPU (0.5-2 MB
## each); the full town's 765 labels used 87 pairs (measured 14 Nov 2026, docs/guides/performance/README.md
## "GPU memory on the web"). share_label_sizes() moves each label up to the next LABEL_SIZES step
## (a size above the last is kept), with pixel_size scaled down so the text keeps its size in the
## world, and rounds the scaled outline to LABEL_OUTLINE_STEP.
const LABEL_SIZES: Array[int] = [24, 32, 48, 64, 96, 128]
const LABEL_OUTLINE_STEP := 2
const MIN_SEGMENTS := 16
const MAX_SEGMENTS := 32
const BATCH_CELL := 24.0
const MID_ROOTS: Array[String] = ["Buildings", "RelocatedSites", "Restaurants", "Airport"]
# Vehicle prefabs are skipped wherever they are parked (e.g. Subi under RelocatedSites).
const SKIPPED_SCENE_DIRS: Array[String] = ["res://scenes/animals/", "res://scenes/characters/", "res://scenes/props/vehicles/"]
const SKIPPED_ROOTS: Array[String] = ["Vehicles", "People"]
# Toggled at runtime by Main (lifted while the learner is under it).
const UNBATCHED_NAMES: Array[String] = ["Home roof"]

var affected := 0
var simplified := 0
var merged := 0
var batches := 0
var leaf_merged := 0
var leaf_meshes := 0
var _radii := {}
var _unit_box := BoxMesh.new()
var _unit_meshes := {}
var _light_cells := {}
var _max_lights := 8
var _triangle_counts := {}

const PerfReadout := preload("res://scripts/ui/perf_readout.gd")


## Web build only (9 Nov 2026, user decision): the 3D world renders below the screen's full pixel
## density (Retina 2x drew 4x the pixels and halved the frame rate on an M5); the HUD and text stay
## sharp. WEB_PIXEL_SHARE of the CSS pixel size, at least WEB_MIN_LINES lines, never below
## WEB_MIN_3D_SCALE.
static func apply_web_3d_scale(viewport: Viewport) -> void:
	if not OS.has_feature("web"):
		return
	var density := DisplayServer.screen_get_scale()
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	var scale := WEB_PIXEL_SHARE / maxf(density, 1.0)
	var size := viewport.get_visible_rect().size
	var short_side := minf(size.x, size.y)
	if short_side > 0.0:
		scale = maxf(scale, WEB_MIN_LINES / short_side)
	viewport.scaling_3d_scale = clampf(scale, WEB_MIN_3D_SCALE, 1.0)


func build(game: Node3D) -> void:
	# The browser's pixel density can change (zoom, another screen): follow it on resize.
	var viewport := game.get_viewport()
	apply_web_3d_scale(viewport)
	if OS.has_feature("web"):
		viewport.size_changed.connect(apply_web_3d_scale.bind(viewport))
	for child in game.apartment.get_children():
		if child.name in SKIPPED_ROOTS:
			for item in child.get_children():
				_range_object(item, 0.0)
			continue
		_trim(child, child.name in MID_ROOTS)
	_apply_segments()
	_batch(game.apartment, game.doors)
	merge_door_leaves(game.apartment, game.doors)
	if OS.has_feature("web"):
		share_label_sizes(game)
	print("Render culling: %d props trimmed, %d round meshes simplified, %d meshes in %d static batches, %d door-leaf meshes in %d" % [affected, simplified, merged, batches, leaf_merged, leaf_meshes])
	_apply_ranges(_note_ranged(game.apartment))
	apply_view(game)
	PerfReadout.attach(game)


## The one graphics setting (see the header) for the camera, the viewport and the fog.
static func apply_view(game: Node3D) -> void:
	var viewport := game.get_viewport()
	var camera: Camera3D = game.player.camera if game.get("player") != null else null
	if camera != null:
		camera.far = VIEW_DISTANCE
	viewport.msaa_3d = MSAA
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = false
	if game.get("day_night") != null:
		game.day_night.set_view_distance(VIEW_DISTANCE)
	apply_web_3d_scale(viewport)


# Every ranged mesh/batch and every heavy mesh under `root` not yet seen, marked (meta
# "range_trimmed") so a later unit never shortens one twice.
func _note_ranged(root: Node) -> Array[GeometryInstance3D]:
	var found: Array[GeometryInstance3D] = []
	var nodes := root.find_children("*", "GeometryInstance3D", true, false)
	if root is GeometryInstance3D:
		nodes.append(root)
	for node: GeometryInstance3D in nodes:
		if node.has_meta("range_trimmed"):
			continue
		var heavy := node is MeshInstance3D and _triangles((node as MeshInstance3D).mesh) >= HEAVY_TRIANGLES
		if node.visibility_range_end > 0.0 or heavy:
			node.set_meta("range_trimmed", true)
			node.set_meta("heavy_mesh", heavy)
			found.append(node)
	return found


func _triangles(mesh: Mesh) -> int:
	# Only imported/built ArrayMeshes can be that heavy; primitives are budgeted by _apply_segments().
	if not mesh is ArrayMesh:
		return 0
	if not _triangle_counts.has(mesh):
		var array_mesh := mesh as ArrayMesh
		var count := 0
		for i in range(array_mesh.get_surface_count()):
			var indices: int = array_mesh.surface_get_array_index_len(i)
			count += (indices if indices > 0 else array_mesh.surface_get_array_len(i)) / 3
		_triangle_counts[mesh] = count
	return _triangle_counts[mesh]


# Shortens the short visibility ranges (RANGE_SHARE, up to SHORT_RANGE) and hides heavy meshes
# beyond HEAVY_RANGE.
func _apply_ranges(nodes: Array[GeometryInstance3D]) -> void:
	for node in nodes:
		if not is_instance_valid(node):
			continue
		var range_end := node.visibility_range_end
		if range_end > 0.0 and range_end <= SHORT_RANGE:
			range_end = minf(range_end, maxf(MIN_RANGE, range_end * RANGE_SHARE))
		if node.get_meta("heavy_mesh", false):
			range_end = HEAVY_RANGE if range_end == 0.0 else minf(range_end, HEAVY_RANGE)
		node.visibility_range_end = range_end


## A unit added after build() (the app's staged loading, 13 Nov 2026): its parts get the same
## trim, round-mesh budget and static batches (in their own container under StaticRenderBatches).
func add_parts(game: Node3D, parts: Array, key: String) -> void:
	var town: Node3D = game.apartment
	var roots: Array = []
	for part in parts:
		var top: Node = part
		while top.get_parent() != town and top.get_parent() != null:
			top = top.get_parent()
		if top.name in SKIPPED_ROOTS:
			_range_object(part, 0.0)
			continue
		_trim(part, top.name in MID_ROOTS)
		roots.append(part)
	_apply_segments()
	for part in parts:
		for light in part.find_children("*", "Light3D", true, false):
			_index_light(light)
	var groups := {}
	var pending: Array = roots.duplicate()
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if _dynamic(node, game.doors):
			continue
		if node is MeshInstance3D:
			_collect(node as MeshInstance3D, town, groups)
		pending.append_array(node.get_children())
	var holder := town.get_node_or_null("StaticRenderBatches")
	if holder == null:
		return
	var container := Node3D.new()
	container.name = "Unit_" + key
	holder.add_child(container)
	_make_batches(groups, container)
	town.set_meta("static_batched_mesh_count", merged)
	for part in roots:
		if is_instance_valid(part):
			merge_door_leaves(part, game.doors)
	# The unit's ranges are trimmed as the rest of the town's.
	var found: Array[GeometryInstance3D] = _note_ranged(container)
	for part in parts:
		if is_instance_valid(part):
			found.append_array(_note_ranged(part))
	_apply_ranges(found)
	if OS.has_feature("web"):
		for part in parts:
			if is_instance_valid(part):
				share_label_sizes(part)


## Moves every Label3D under `root` to a shared font size (LABEL_SIZES; same size in the world)
## and drops the glyph atlases of the sizes it left, so only the shared ones stay on the GPU. A
## dropped size that 2D text still uses is simply drawn again into a new atlas. Returns the
## number of labels changed.
static func share_label_sizes(root: Node) -> int:
	var left := {}
	var used := {}
	var changed := 0
	for label: Label3D in root.find_children("*", "Label3D", true, false):
		var font: Font = label.font if label.font != null else ThemeDB.fallback_font
		var size := label.font_size
		var step := size
		for candidate in LABEL_SIZES:
			if candidate >= size:
				step = candidate
				break
		if step != size and size > 0:
			left[[font, Vector2i(size, label.outline_size)]] = true
			var ratio := float(step) / float(size)
			label.pixel_size /= ratio
			# live_labels.gd puts this pixel size back when the display language changes.
			if label.has_meta("lexicon_pixel"):
				label.set_meta("lexicon_pixel", float(label.get_meta("lexicon_pixel")) / ratio)
			label.font_size = step
			if label.outline_size > 0:
				label.outline_size = maxi(LABEL_OUTLINE_STEP, roundi(label.outline_size * ratio / LABEL_OUTLINE_STEP) * LABEL_OUTLINE_STEP)
			changed += 1
		used[[font, Vector2i(label.font_size, label.outline_size)]] = true
	for entry in left:
		if not used.has(entry):
			_drop_size_cache(entry[0], entry[1])
	return changed


# Removes one size's glyph cache from a font, its base font and their fallbacks.
static func _drop_size_cache(font: Font, size: Vector2i) -> void:
	var pending: Array = [font]
	var seen := {}
	while not pending.is_empty():
		var item = pending.pop_back()
		if item == null or seen.has(item):
			continue
		seen[item] = true
		if item is FontVariation:
			pending.append((item as FontVariation).base_font)
		if item is FontFile:
			var file := item as FontFile
			for cache in range(file.get_cache_count()):
				if file.get_size_cache_list(cache).has(size):
					file.remove_size_cache(cache, size)
		pending.append_array(item.fallbacks)


func _trim(node: Node, mid_tier: bool) -> void:
	if node is CharacterBody3D:
		return
	if _skipped_scene(node) or node.is_processing() or node.is_physics_processing():
		_range_object(node, PLUSH_RANGE if node.scene_file_path.ends_with("_plush.tscn") else 0.0)
		return
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		_note_radius(mesh_node)
		if mesh_node.mesh != null and mesh_node.visible and mesh_node.visibility_range_end == 0.0:
			var size := mesh_node.get_aabb().size * mesh_node.global_transform.basis.get_scale()
			var largest := maxf(size.x, maxf(size.y, size.z))
			if largest < SMALL_PROP_SIZE and mesh_node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mesh_node.visibility_range_end = SMALL_PROP_RANGE
				affected += 1
			elif mid_tier and largest < MID_PROP_SIZE:
				mesh_node.visibility_range_end = MID_PROP_RANGE
				affected += 1
			elif largest < RANGED_MAX_SIZE:
				mesh_node.visibility_range_end = maxf(SMALL_PROP_RANGE, largest * SIZE_RANGE_RATIO)
				affected += 1
	for child in node.get_children():
		_trim(child, mid_tier)


# Vehicles, animals, characters and other moving objects keep their shadows and
# segments; each whole object is hidden together once it is tiny on screen
# (beyond fixed_range when given).
func _range_object(node: Node, fixed_range: float) -> void:
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	if fixed_range > 0.0:
		for mesh_node in meshes:
			if mesh_node.mesh != null and mesh_node.visibility_range_end == 0.0:
				mesh_node.visibility_range_end = fixed_range
				affected += 1
		return
	var bounds := AABB()
	var first := true
	for mesh_node in meshes:
		if mesh_node.mesh == null:
			continue
		var box: AABB = mesh_node.global_transform * mesh_node.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var largest := bounds.get_longest_axis_size()
	if first or largest >= RANGED_MAX_SIZE:
		return
	var range_end := maxf(SMALL_PROP_RANGE, largest * OBJECT_RANGE_RATIO)
	# Small details (wheels, eyes, trim) go first; the silhouette stays to range_end.
	for mesh_node in meshes:
		if mesh_node.mesh == null or mesh_node.visibility_range_end != 0.0:
			continue
		var part: float = (mesh_node.global_transform * mesh_node.get_aabb()).get_longest_axis_size()
		mesh_node.visibility_range_end = range_end if part >= largest * DETAIL_PART_SHARE \
			else maxf(SMALL_PROP_RANGE, range_end * DETAIL_RANGE_SHARE)
		affected += 1


# Shared meshes keep enough segments for their largest use.
func _note_radius(mesh_node: MeshInstance3D) -> void:
	var mesh := mesh_node.mesh
	if not (mesh is SphereMesh or mesh is CylinderMesh):
		return
	var scale := mesh_node.global_transform.basis.get_scale()
	var radius: float = mesh.radius if mesh is SphereMesh else maxf(mesh.top_radius, mesh.bottom_radius)
	radius *= maxf(scale.x, scale.z)
	_radii[mesh] = maxf(_radii.get(mesh, 0.0), radius)


func _apply_segments() -> void:
	for mesh in _radii:
		var segments := clampi(snappedi(12.0 + _radii[mesh] * 32.0, 4), MIN_SEGMENTS, MAX_SEGMENTS)
		if mesh.radial_segments <= segments:
			continue
		mesh.radial_segments = segments
		if mesh is SphereMesh:
			mesh.rings = mini(mesh.rings, segments / 2)
		simplified += 1


func _batch(town: Node3D, doors: Dictionary) -> void:
	if town.has_node("StaticRenderBatches"):
		return
	_index_lights(town)
	var groups := {}
	var pending: Array = []
	for child in town.get_children():
		if not child.name in SKIPPED_ROOTS:
			pending.append(child)
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if _dynamic(node, doors):
			continue
		if node is MeshInstance3D:
			_collect(node as MeshInstance3D, town, groups)
		pending.append_array(node.get_children())
	var container := Node3D.new()
	container.name = "StaticRenderBatches"
	town.add_child(container)
	_make_batches(groups, container)
	town.set_meta("static_batched_mesh_count", merged)


func _make_batches(groups: Dictionary, container: Node3D) -> void:
	for key in groups:
		var entry: Dictionary = groups[key]
		if entry.poses.size() < 2:
			continue
		# Centre the batch on its contents: visibility range is measured from there.
		var centre := Vector3.ZERO
		for pose in entry.poses:
			centre += pose.origin
		centre /= entry.poses.size()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = entry.mesh
		instances.instance_count = entry.poses.size()
		for i in range(entry.poses.size()):
			var pose: Transform3D = entry.poses[i]
			instances.set_instance_transform(i, Transform3D(pose.basis, pose.origin - centre))
		var batch := MultiMeshInstance3D.new()
		batch.position = centre
		batch.multimesh = instances
		batch.material_override = entry.material
		batch.cast_shadow = entry.source.cast_shadow
		batch.visibility_range_end = entry.source.visibility_range_end
		container.add_child(batch)
		for i in range(entry.nodes.size()):
			var source: Node = entry.nodes[i]
			source.hide()
			source.set_meta("render_batched", true)
			# Where its copy is drawn, so show_batched() can take it out and put it back.
			source.set_meta("render_batch", [batch, i])
		merged += entry.nodes.size()
		batches += 1


## Door leaves (17 Nov 2026): a door in Main.doors (hinge or slide; door_animator.gd) turns or
## slides as one node, so the static batches leave all of it out (about 35 meshes per home door:
## slab, panels, mouldings, hinges, handles). Its own plain meshes are merged into one mesh per
## material, shadow, range and layers, a child of the door node ("Merged leaf", meta
## "leaf_merge"), so they still move with it. Originals are hidden and tagged "render_batched" as
## in the static batches (the badge, the minimap and interaction_controller._shown() still read
## them). Left alone: curtains, doors that process, nested doors, anything processing, with
## keep_own_draw or a word_key below the door, vehicle/animal/character scenes, transparent or
## shader materials, skinned meshes, per-node transparency/overlays. Once per door (meta
## "leaf_merged"). Returns the number of meshes merged.
func merge_door_leaves(root: Node, doors: Dictionary) -> int:
	var count := 0
	for door in doors:
		if not is_instance_valid(door) or not door is Node3D or door.has_meta("leaf_merged"):
			continue
		if door != root and not root.is_ancestor_of(door):
			continue
		if str(doors[door].get("type", "")) == "curtain" or door.is_processing() or door.is_physics_processing():
			continue
		if _under_skipped(door):
			continue
		door.set_meta("leaf_merged", true)
		count += _merge_leaf(door, doors)
	return count


func _under_skipped(node: Node) -> bool:
	var walk := node
	while walk != null:
		if _skipped_scene(walk) or (walk.get_parent() != null and str(walk.name) in SKIPPED_ROOTS):
			return true
		walk = walk.get_parent()
	return false


func _merge_leaf(door: Node3D, doors: Dictionary) -> int:
	var groups := {}
	var pending: Array = door.get_children()
	var to_door := door.global_transform.affine_inverse()
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if doors.has(node) or node.is_processing() or node.is_physics_processing() \
				or node.has_meta("keep_own_draw") or node.has_meta("word_key") or _skipped_scene(node) \
				or (node is Node3D and not (node as Node3D).visible):
			continue
		if node is MeshInstance3D:
			_collect_leaf(node as MeshInstance3D, to_door, groups)
		pending.append_array(node.get_children())
	var count := 0
	for key in groups:
		var entry: Dictionary = groups[key]
		if entry.nodes.size() < 2:
			continue
		var mesh := ArrayMesh.new()
		for surface_key in entry.surfaces:
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, entry.surfaces[surface_key])
			mesh.surface_set_material(mesh.get_surface_count() - 1, surface_key[0])
		var leaf := MeshInstance3D.new()
		leaf.name = "Merged leaf"
		leaf.mesh = mesh
		leaf.cast_shadow = key[0]
		leaf.visibility_range_end = key[1]
		leaf.layers = key[2]
		leaf.set_meta("leaf_merge", true)
		door.add_child(leaf)
		for source: MeshInstance3D in entry.nodes:
			source.hide()
			source.set_meta("render_batched", true)
		count += entry.nodes.size()
		leaf_meshes += 1
	leaf_merged += count
	return count


# Adds a leaf mesh's surfaces, in door space, to the group of its shadow/range/layers setting
# (one surface per material and vertex format), or leaves it out when it cannot merge.
func _collect_leaf(node: MeshInstance3D, to_door: Transform3D, groups: Dictionary) -> void:
	var mesh := node.mesh
	if mesh == null or node.skin != null or node.material_overlay != null or node.transparency != 0.0 \
			or mesh is ImmediateMesh:
		return
	var materials: Array = []
	for s in range(mesh.get_surface_count()):
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return
		var material: Material = node.material_override
		if material == null and s < node.get_surface_override_material_count():
			material = node.get_surface_override_material(s)
		if material == null:
			material = mesh.surface_get_material(s)
		if material != null and (not material is BaseMaterial3D \
				or (material as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
			return
		materials.append(material)
	var pose := to_door * node.global_transform
	var normal_basis := pose.basis.inverse().transposed()
	var mirrored := pose.basis.determinant() < 0.0
	var key := [node.cast_shadow, node.visibility_range_end, node.layers]
	if not groups.has(key):
		groups[key] = {"surfaces": {}, "nodes": []}
	var entry: Dictionary = groups[key]
	for s in range(mesh.get_surface_count()):
		var source: Array = mesh.surface_get_arrays(s)
		var vertices: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
		if vertices.is_empty() or source[Mesh.ARRAY_BONES] != null:
			continue
		var has_uv: bool = source[Mesh.ARRAY_TEX_UV] != null
		var has_color: bool = source[Mesh.ARRAY_COLOR] != null
		var has_tangent: bool = source[Mesh.ARRAY_TANGENT] != null
		# A surface per material and vertex format (a material with no UVs never mixes with one that has them).
		var surface_key := [materials[s], has_uv, has_color, has_tangent]
		if not entry.surfaces.has(surface_key):
			var empty: Array = []
			empty.resize(Mesh.ARRAY_MAX)
			empty[Mesh.ARRAY_VERTEX] = PackedVector3Array()
			empty[Mesh.ARRAY_NORMAL] = PackedVector3Array()
			empty[Mesh.ARRAY_INDEX] = PackedInt32Array()
			if has_uv: empty[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
			if has_color: empty[Mesh.ARRAY_COLOR] = PackedColorArray()
			if has_tangent: empty[Mesh.ARRAY_TANGENT] = PackedFloat32Array()
			entry.surfaces[surface_key] = empty
		var target: Array = entry.surfaces[surface_key]
		var base: int = (target[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var out_vertices: PackedVector3Array = target[Mesh.ARRAY_VERTEX]
		var out_normals: PackedVector3Array = target[Mesh.ARRAY_NORMAL]
		var normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL] if source[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		for i in vertices.size():
			out_vertices.append(pose * vertices[i])
			out_normals.append((normal_basis * normals[i]).normalized() if i < normals.size() else Vector3.UP)
		target[Mesh.ARRAY_VERTEX] = out_vertices
		target[Mesh.ARRAY_NORMAL] = out_normals
		if has_uv:
			var uvs: PackedVector2Array = target[Mesh.ARRAY_TEX_UV]
			uvs.append_array(source[Mesh.ARRAY_TEX_UV])
			target[Mesh.ARRAY_TEX_UV] = uvs
		if has_color:
			var colors: PackedColorArray = target[Mesh.ARRAY_COLOR]
			colors.append_array(source[Mesh.ARRAY_COLOR])
			target[Mesh.ARRAY_COLOR] = colors
		if has_tangent:
			var tangents: PackedFloat32Array = target[Mesh.ARRAY_TANGENT]
			var from: PackedFloat32Array = source[Mesh.ARRAY_TANGENT]
			for i in range(0, from.size(), 4):
				var t := (pose.basis * Vector3(from[i], from[i + 1], from[i + 2])).normalized()
				tangents.append_array([t.x, t.y, t.z, -from[i + 3] if mirrored else from[i + 3]])
			target[Mesh.ARRAY_TANGENT] = tangents
		var indices: PackedInt32Array = target[Mesh.ARRAY_INDEX]
		var from_indices: PackedInt32Array = source[Mesh.ARRAY_INDEX] if source[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var corner_count: int = from_indices.size() if not from_indices.is_empty() else vertices.size()
		for i in range(0, corner_count - 2, 3):
			var a: int = from_indices[i] if not from_indices.is_empty() else i
			var b: int = from_indices[i + 1] if not from_indices.is_empty() else i + 1
			var c: int = from_indices[i + 2] if not from_indices.is_empty() else i + 2
			# A mirrored pose turns the triangles inside out: keep their winding facing out.
			if mirrored:
				indices.append_array([base + a, base + c, base + b])
			else:
				indices.append_array([base + a, base + b, base + c])
		target[Mesh.ARRAY_INDEX] = indices
	entry.nodes.append(node)


# Anything that moves, toggles or animates keeps its own draw. Pickable meshes may
# merge: interaction_controller shows a "render_batched" original while highlighted.
# A prop that only moves when used (the shower curtain, 12 Nov 2026) sets meta
# "keep_own_draw" on its root.
## Hides (on = false) or shows again the batched copies of every merged mesh under `root` (meta
## "render_batch": [batch, index]): the copy shrinks to nothing and comes back at its pose. For
## code that hides a static prop for a while (the welcome tutorial's mahjong table, 14 Nov 2026);
## hiding the prop's node alone leaves its merged copy drawn.
static func show_batched(root: Node, on: bool) -> void:
	var nodes: Array = root.find_children("*", "MeshInstance3D", true, false)
	nodes.append(root)
	for node in nodes:
		if not node.has_meta("render_batch"):
			continue
		var entry: Array = node.get_meta("render_batch")
		var batch := entry[0] as MultiMeshInstance3D
		if not is_instance_valid(batch):
			continue
		var index := int(entry[1])
		if not node.has_meta("render_batch_pose"):
			node.set_meta("render_batch_pose", batch.multimesh.get_instance_transform(index))
		var pose: Transform3D = node.get_meta("render_batch_pose")
		batch.multimesh.set_instance_transform(index, pose if on else Transform3D(Basis.from_scale(Vector3.ZERO), pose.origin))


func _dynamic(node: Node, doors: Dictionary) -> bool:
	return (node is PhysicsBody3D and not node is StaticBody3D) \
		or node.is_processing() or node.is_physics_processing() \
		or _skipped_scene(node) \
		or doors.has(node) \
		or node.has_meta("swivel") \
		or node.has_meta("keep_own_draw") \
		or str(node.name) in UNBATCHED_NAMES \
		or node is MultiMeshInstance3D


func _collect(node: MeshInstance3D, town: Node3D, groups: Dictionary) -> void:
	var mesh := node.mesh
	if mesh == null or not node.visible or not node.is_visible_in_tree() or node.material_overlay != null \
			or node.skin != null or node.transparency != 0.0 or mesh is ImmediateMesh:
		return
	for i in range(node.get_surface_override_material_count()):
		if node.get_surface_override_material(i) != null:
			return
	# Batches only share pieces lit by exactly the same local lights, and pieces
	# reached by more than the renderer's per-object limit stay unmerged, so each
	# batch is shaded with the lights its pieces had.
	var lights := _lights_touching(node.global_transform * node.get_aabb())
	if lights.size() > _max_lights:
		return
	var pose: Transform3D = town.global_transform.affine_inverse() * node.global_transform
	# Same-coloured boxes, spheres and straight cylinders of any size share unit meshes.
	if node.material_override != null:
		var unit := _unit_mesh(mesh)
		if unit != null:
			pose.basis = pose.basis.scaled_local(_unit_scale(mesh))
			mesh = unit
	# Distance-culled groups use smaller cells so whole batches pop near the right range.
	var cell_size := BATCH_CELL if node.visibility_range_end == 0.0 else minf(BATCH_CELL, node.visibility_range_end * 0.2)
	var cell := Vector2i(floori(pose.origin.x / cell_size), floori(pose.origin.z / cell_size))
	var key := [cell, node.material_override, mesh, node.cast_shadow, node.visibility_range_end, lights]
	if not groups.has(key):
		groups[key] = {"mesh": mesh, "material": node.material_override, "source": node, "poses": [], "nodes": []}
	groups[key].poses.append(pose)
	groups[key].nodes.append(node)


func _index_lights(town: Node3D) -> void:
	_max_lights = ProjectSettings.get_setting("rendering/limits/opengl/max_lights_per_object", 8)
	for light in town.get_tree().root.find_children("*", "Light3D", true, false):
		_index_light(light)


func _index_light(light: Light3D) -> void:
	if light is DirectionalLight3D or not light.is_visible_in_tree():
		return
	var reach: float = light.omni_range if light is OmniLight3D else light.spot_range
	var centre: Vector3 = light.global_position
	for x in range(floori((centre.x - reach) / BATCH_CELL), floori((centre.x + reach) / BATCH_CELL) + 1):
		for z in range(floori((centre.z - reach) / BATCH_CELL), floori((centre.z + reach) / BATCH_CELL) + 1):
			var cell := Vector2i(x, z)
			if not _light_cells.has(cell):
				_light_cells[cell] = []
			_light_cells[cell].append(light)


# Sorted instance ids of the omni/spot lights whose range reaches the box.
func _lights_touching(box: AABB) -> Array:
	var found := {}
	for x in range(floori(box.position.x / BATCH_CELL), floori(box.end.x / BATCH_CELL) + 1):
		for z in range(floori(box.position.z / BATCH_CELL), floori(box.end.z / BATCH_CELL) + 1):
			for light in _light_cells.get(Vector2i(x, z), []):
				var reach: float = light.omni_range if light is OmniLight3D else light.spot_range
				var centre: Vector3 = light.global_position
				var nearest := centre.clamp(box.position, box.end)
				if nearest.distance_to(centre) <= reach:
					found[light.get_instance_id()] = true
	var ids := found.keys()
	ids.sort()
	return ids


func _unit_mesh(mesh: Mesh) -> Mesh:
	if mesh is BoxMesh:
		if mesh.subdivide_width != 0 or mesh.subdivide_height != 0 or mesh.subdivide_depth != 0:
			return null
		return _unit_box
	var key: Array
	if mesh is SphereMesh and not mesh.is_hemisphere and is_equal_approx(mesh.height, mesh.radius * 2.0):
		key = ["sphere", mesh.radial_segments, mesh.rings]
	elif mesh is CylinderMesh and is_equal_approx(mesh.top_radius, mesh.bottom_radius) and mesh.rings == 4 \
			and mesh.cap_top and mesh.cap_bottom:
		key = ["cylinder", mesh.radial_segments]
	else:
		return null
	if not _unit_meshes.has(key):
		var unit: PrimitiveMesh
		if mesh is SphereMesh:
			unit = SphereMesh.new()
			unit.radius = 1.0
			unit.height = 2.0
			unit.rings = mesh.rings
		else:
			unit = CylinderMesh.new()
			unit.top_radius = 1.0
			unit.bottom_radius = 1.0
			unit.height = 1.0
		unit.radial_segments = mesh.radial_segments
		_unit_meshes[key] = unit
	return _unit_meshes[key]


func _unit_scale(mesh: Mesh) -> Vector3:
	if mesh is BoxMesh:
		return mesh.size
	if mesh is SphereMesh:
		return Vector3.ONE * mesh.radius
	return Vector3(mesh.top_radius, mesh.height, mesh.top_radius)


func _skipped_scene(node: Node) -> bool:
	var path := node.scene_file_path
	if path == "":
		return false
	for dir in SKIPPED_SCENE_DIRS:
		if path.begins_with(dir):
			return true
	return false
