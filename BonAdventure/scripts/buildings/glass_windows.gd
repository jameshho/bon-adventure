extends RefCounted
## Moves a building's window glass to the shared window component (user request, 12 Nov 2026;
## docs/guides/WINDOWS.md): each glass pane (a box MeshInstance3D) is replaced by an instance of
## scenes/props/window.tscn of the same size, place and facing. Used by the `glass_windows` step
## of each listed unit:
##   preload("res://scripts/buildings/glass_windows.gd").migrate(town, "<unit>")
## Kept: the pane's parent (word roots, doors and their metadata), the pane's own name (auto
## names "@...@" become "Glass"), metas and groups, and its children (collision bodies move to the
## window, so walls and windows block as before). Frames, sills and mullions are left as they are
## (frame_visible stays false). An arched pane (a rectangle with a cylinder disc on its top edge)
## becomes one ARCH window and the disc is removed, so the overlap is not tinted twice.
## Left alone: emissive panes (light panels that stand in for windows), the police lineup's one-way
## glass, display-case and fridge glass, vehicles and products.

const WINDOW := preload("res://scenes/props/window.tscn")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const GlassWindow := preload("res://scripts/world/glass_window.gd")

## Pane names (trailing digits and "_N" dropped; a mesh named "Visual" or auto-named takes its
## parent's name) that are window glass, per unit.
const PANES := {
	"airport": ["Gate glass", "Door window", "Tower window glass", "Cabin glass", "Blue glazing"],
	"warehouse": ["Reception window", "Hall door window"],
	"school": ["Entry-area window glass"],
	"sports": ["Shop window glazing"],
	"bakery": ["Cafe display glazing"],
	"electronics": ["WindowPane", "Shop window glazing"],
	"bank": ["Bank window", "Window pane", "Bank broad glazing"],
	"barn": ["Window glass"],
	"library": ["Library window", "Window pane", "Blue glazing"],
	"restaurants": ["Window pane", "Kitchen window", "Front glass", "East glass", "Back door window", "Door glass left", "Door glass right", "Blue glazing"],
	"police": ["Police Station window", "Window pane", "Shop window glazing"],
	"supermarket": ["Supermarket window", "Window pane", "Wide storefront glazing"],
	"clothing": ["WindowPane", "Shop window glazing"],
}
## Panes with a room or the outdoors behind them (town path prefixes; the 12 Nov 2026 views in
## docs/evidence/windows-20261112/ and docs/guides/WINDOWS.md). Every other pane sits on a solid wall: a map facade
## in front of the front wall, a window in front of an interior lining, a barn wall or a door leaf.
## Those are drawn with the shared opaque glass (see_through = false), so they show no blank wall.
const SEE_THROUGH := [
	"Airport/Terminal/Interior/Gate glass", "Airport/ControlTower/Interior/Tower window glass",
	"Airport/ControlTower/Interior/Cabin glass", "Warehouse/Architecture/Reception window",
	"Buildings/ElectronicsStore/WindowPane", "Buildings/ClothingStore/WindowPane",
	"Restaurants/Pizza/Window pane", "Restaurants/Burger/Front glass", "Restaurants/Burger/East glass",
	"Map facades/PIZZA AND BURGER/Door glass",
]
## Parts of a unit that are never searched (vehicles and goods that happen to have panes).
const SKIP := ["SchoolBus", "Delivery truck", "Train", "LearningDisplays", "Drinks fridge", "Model"]


## Replaces the unit's panes; returns the new windows.
static func migrate(town: Node3D, unit: String) -> Array:
	var names: Array = PANES.get(unit, [])
	var made := []
	for part in ModularTown.registry()[unit].parts:
		var root := town.get_node_or_null(NodePath(part))
		if root == null:
			continue
		for pane in panes(root, names):
			var window := replace(pane, see_through(str(town.get_path_to(pane))))
			if window != null:
				made.append(window)
	if made.is_empty():
		push_error("glass_windows: no panes found in " + unit)
	print("glass_windows %s: %d windows" % [unit, made.size()])
	return made


## Second pass (step `glass_windows_2`): see-through panes the name list missed because they are
## auto-named straight under a room (the old transparent glass look: a thin box with alpha). Display
## cases, fridges and coolers, the teller glass and the police one-way glass are left alone.
const LEFTOVER_SKIP := ["fridge", "cooler", "Case", "Teller", "Lineup", "MarketInterior", "shelf"]

static func migrate_leftovers(town: Node3D, unit: String) -> Array:
	var made := []
	for part in ModularTown.registry()[unit].parts:
		var root := town.get_node_or_null(NodePath(part))
		if root == null:
			continue
		for mesh in root.find_children("*", "MeshInstance3D", true, false):
			if mesh.has_meta(GlassWindow.PART_META) or not mesh.mesh is BoxMesh:
				continue
			var mat := mesh.material_override as BaseMaterial3D
			var size: Vector3 = mesh.mesh.size
			var path := str(town.get_path_to(mesh))
			if mat == null or mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED or mat.albedo_color.a >= 1.0 \
					or minf(size.x, minf(size.y, size.z)) >= 0.12 or maxf(size.x, maxf(size.y, size.z)) <= 0.4:
				continue
			if LEFTOVER_SKIP.any(func(word: String) -> bool: return path.contains(word)):
				continue
			made.append(replace(mesh, true))
	print("glass_windows_2 %s: %d windows" % [unit, made.size()])
	return made


static func see_through(path: String) -> bool:
	for prefix in SEE_THROUGH:
		if path.begins_with(prefix):
			return true
	return false


## Box glass meshes under `root` whose pane name is listed.
static func panes(root: Node, names: Array) -> Array:
	var found := []
	var pending: Array = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if String(node.name) in SKIP or node.get_script() == GlassWindow:
			continue
		if node is MeshInstance3D and node.mesh is BoxMesh and pane_name(node) in names and not _emissive(node):
			found.append(node)
		pending.append_array(node.get_children())
	return found


## A pane's name for the lists: its own, or its holder's when the mesh is auto-named or "Visual".
static func pane_name(mesh: Node) -> String:
	var title := String(mesh.name)
	if title == "Visual" or title.begins_with("@"):
		title = String(mesh.get_parent().name)
	var cut := RegEx.create_from_string("(_\\d+|\\d+)$")
	return cut.sub(title, "")


static func _emissive(mesh: MeshInstance3D) -> bool:
	var mat := mesh.material_override as BaseMaterial3D
	return mat != null and mat.emission_enabled


## The window that replaces `pane` (same place; glass in its local XY plane, thinnest side on Z).
static func replace(pane: MeshInstance3D, see_through := true) -> Node3D:
	var parent := pane.get_parent()
	var size: Vector3 = (pane.mesh as BoxMesh).size * pane.transform.basis.get_scale()
	var basis := pane.transform.basis.orthonormalized()
	var w := size.x
	var h := size.y
	var t := size.z
	if size.x <= size.y and size.x <= size.z:
		basis = basis * Basis(Vector3.UP, PI * 0.5)   # local X (width) runs along the old -Z
		w = size.z
		t = size.x
	elif size.y < size.z:
		basis = basis * Basis(Vector3.RIGHT, PI * 0.5)   # local Y (height) runs along the old Z
		h = size.z
		t = size.y
	var window: Node3D = WINDOW.instantiate()
	window.name = "Glass" if String(pane.name).begins_with("@") else String(pane.name)
	window.transform = Transform3D(basis, pane.transform.origin)
	window.width = w
	window.height = h
	window.thickness = t
	window.see_through = see_through
	var arch := _arch_disc(pane, w, h) if pane.is_inside_tree() else null
	if arch != null:
		window.shape = GlassWindow.Shape.ARCH
	for key in pane.get_meta_list():
		window.set_meta(key, pane.get_meta(key))
	for group in pane.get_groups():
		if not String(group).begins_with("_"):
			window.add_to_group(group, true)
	var owner := pane.owner
	var index := pane.get_index()
	var name := window.name
	# Removing a node clears owners that stop being its ancestors: note them, restore after.
	var owners := {}
	for node in pane.find_children("*", "", true, false):
		owners[node] = node.owner
	var children := pane.get_children()
	parent.remove_child(pane)
	parent.add_child(window)
	parent.move_child(window, index)
	window.name = name
	window.owner = owner
	for child in children:
		var pose: Transform3D = pane.transform * child.transform
		pane.remove_child(child)
		window.add_child(child)
		child.transform = window.transform.affine_inverse() * pose
	for node in owners:
		node.owner = owners[node]
	pane.free()
	if arch != null:
		arch.get_parent().remove_child(arch)
		arch.free()
	return window


## The cylinder disc over an arched pane: a CylinderMesh near the pane, as wide as it, centred on its
## top edge (Alta Cocina and its facade). Returns the node to remove (its holder when auto-named).
static func _arch_disc(pane: MeshInstance3D, w: float, h: float) -> Node3D:
	var top := pane.global_transform * Vector3(0, (pane.mesh as BoxMesh).size.y * 0.5, 0)
	var holder := pane.get_parent()
	var area := holder.get_parent() if String(pane.name).begins_with("@") else holder
	for node in area.find_children("*", "MeshInstance3D", true, false):
		var mesh := node.mesh as CylinderMesh
		if mesh == null or not is_equal_approx(mesh.top_radius, w * 0.5) or node.global_position.distance_to(top) > 0.05:
			continue
		var parent: Node = node.get_parent()
		return parent if String(node.name).begins_with("@") and parent != area else node
	return null


## Real windows (user, 18 Nov 2026; docs/guides/WINDOWS.md "Real windows"). Adds a window with a
## frame preset at `centre` (town coordinates, the middle of the wall's depth), its +Z facing
## `outward` (the outdoors side, `outside = FRONT`), under `parent`, then opens the wall:
## - every wall layer that spans the whole opening (a BoxMesh: wall, pier, facade skin, painted
##   lining) gets a hole: its mesh becomes up to four boxes around it (one ArrayMesh on the same
##   node, same material, so collisions, metas and owners stay; the wall's collision is unchanged,
##   so the glass still blocks);
## - every part lying inside the opening (within MARGIN along the wall, `reach` in front of or
##   behind it: old panes and windows,
##   panels, frames, sills, mullions, painted window views) is removed; if one was a clickable
##   word (e.g. "window"), the new window becomes that word, with a thin click body in the opening;
## - parts that only partly overlap the opening are left alone and reported.
## `look` sets the window's exports (width, height, frame_style, frame_accent, wall_depth, bars, name).
## Returns {"window", "cut": [paths], "removed": [paths], "partial": [paths], "word"}.
## Old window parts lie within this much of the opening, along the wall (bases and piers beside
## a window reach further and stay).
const MARGIN := 0.25

static func real_window(town: Node3D, unit: String, parent: Node3D, centre: Vector3, outward: Vector3,
		look: Dictionary, reach := 0.4) -> Dictionary:
	var window: Node3D = WINDOW.instantiate()
	var title := String(look.get("name", "Window"))
	for key in look:
		if key != "name":
			window.set(key, look[key])
	window.outside = GlassWindow.Outside.FRONT
	var z := outward.normalized()
	var basis := Basis(Vector3.UP.cross(z).normalized(), Vector3.UP, z)
	window.transform = parent.global_transform.affine_inverse() * town.global_transform * Transform3D(basis, centre)
	parent.add_child(window)
	window.name = title
	var size: Vector2 = window.opening_size()
	var frame: float = (size.x - window.width) * 0.5
	var hole := Rect2(-size.x * 0.5, -window.height * 0.5 - frame, size.x, size.y)
	var depth: float = window.wall_depth * 0.5
	var to_window := window.global_transform.affine_inverse()
	var result := {"window": window, "cut": [], "removed": [], "partial": []}
	var doomed := {}
	for part in ModularTown.registry()[unit].parts:
		var root := town.get_node_or_null(NodePath(part))
		if root == null:
			continue
		for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null or window.is_ancestor_of(mesh):
				continue
			var box: AABB = to_window * mesh.global_transform * mesh.get_aabb()
			if box.end.z < -depth - reach or box.position.z > depth + reach:
				continue
			var flat := Rect2(box.position.x, box.position.y, box.size.x, box.size.y)
			if not flat.intersects(hole.grow(-0.01)):
				continue
			var path := str(town.get_path_to(mesh))
			# A wall layer reaches well past the opening (a frame around the old pane does not).
			if flat.encloses(hole.grow(0.2)) and box.size.z < window.wall_depth + 0.1:
				if _cut(mesh, window, hole):
					result.cut.append(path)
				else:
					result.partial.append(path + " (not a box)")
			elif hole.grow(MARGIN).encloses(flat) and box.position.z > -depth - reach and box.end.z < depth + reach:
				doomed[mesh.get_parent() if mesh.has_meta(GlassWindow.PART_META) else mesh] = true
			else:
				result.partial.append(path)
	# A holder left with nothing else to draw goes too (with its collision bodies); never a part root.
	var tops := {}
	for node: Node in doomed:
		var top := node
		while not _is_part_root(town, unit, top.get_parent()) and _only(top.get_parent(), doomed):
			top = top.get_parent()
		tops[top] = true
	var removed := []
	for top: Node in tops:
		if not tops.keys().any(func(other: Node) -> bool: return other != top and other.is_ancestor_of(top)):
			removed.append(top)
	var word := ""
	for top: Node in removed:
		for node in [top] + top.find_children("*", "", true, false):
			for key in ["word_key", "word"]:
				if word == "" and node.has_meta(key):
					word = str(node.get_meta(key))
		result.removed.append(str(town.get_path_to(top)))
		top.get_parent().remove_child(top)
		top.free()
	result.word = word
	if word != "":
		# Still a clickable word (as Main.box makes one): the root's word_key and a thin body
		# over the glass, in the wall's opening.
		window.set_meta("word_key", word)
		var body := StaticBody3D.new()
		body.name = "Click"
		body.set_meta("object_name", title)
		body.set_meta("root", window)
		body.set_meta("word", word)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(size.x, size.y, 0.06)
		shape.shape = box
		shape.position = Vector3(0, hole.get_center().y, 0)
		body.add_child(shape)
		window.add_child(body)
	return result


static func _is_part_root(town: Node3D, unit: String, node: Node) -> bool:
	if node == null or node == town:
		return true
	for part in ModularTown.registry()[unit].parts:
		if town.get_node_or_null(NodePath(part)) == node:
			return true
	return false


## True when everything `holder` draws is in `doomed` (collision bodies and empty nodes don't count).
static func _only(holder: Node, doomed: Dictionary) -> bool:
	for child in holder.find_children("*", "", true, false):
		if not (child is VisualInstance3D):
			continue
		var node: Node = child
		var gone := false
		while node != holder:
			if doomed.has(node):
				gone = true
				break
			node = node.get_parent()
		if not gone:
			return false
	return true


## Replaces a box wall's mesh by up to four boxes around the hole (`hole` in the window's XY).
static func _cut(mesh: MeshInstance3D, window: Node3D, hole: Rect2) -> bool:
	var box := mesh.mesh as BoxMesh
	if box == null:
		return false
	var to_mesh := mesh.global_transform.affine_inverse() * window.global_transform
	var cut: AABB = to_mesh * AABB(Vector3(hole.position.x, hole.position.y, -50), Vector3(hole.size.x, hole.size.y, 100))
	var half := box.size * 0.5
	# The wall's thin axis runs through the hole; of the other two, the one nearest the window's
	# up direction is vertical.
	var thin := 0
	for i in range(3):
		if box.size[i] < box.size[thin]:
			thin = i
	var up := (mesh.global_transform.basis.inverse() * window.global_transform.basis.y).normalized()
	var others := [0, 1, 2].filter(func(i: int) -> bool: return i != thin)
	var v: int = others[0] if absf(up[others[0]]) > absf(up[others[1]]) else others[1]
	var h: int = others[1] if v == others[0] else others[0]
	var h0 := clampf(cut.position[h], -half[h], half[h])
	var h1 := clampf(cut.end[h], -half[h], half[h])
	var v0 := clampf(cut.position[v], -half[v], half[v])
	var v1 := clampf(cut.end[v], -half[v], half[v])
	# Below, above, and the two sides: [h from, h to, v from, v to].
	var pieces := [[-half[h], half[h], -half[v], v0], [-half[h], half[h], v1, half[v]],
		[-half[h], h0, v0, v1], [h1, half[h], v0, v1]]
	var st := SurfaceTool.new()
	var any := false
	for piece in pieces:
		if piece[1] - piece[0] < 0.002 or piece[3] - piece[2] < 0.002:
			continue
		var size := box.size
		size[h] = piece[1] - piece[0]
		size[v] = piece[3] - piece[2]
		var at := Vector3.ZERO
		at[h] = (piece[0] + piece[1]) * 0.5
		at[v] = (piece[2] + piece[3]) * 0.5
		var part := BoxMesh.new()
		part.size = size
		st.append_from(part, 0, Transform3D(Basis.IDENTITY, at))
		any = true
	if not any:
		return false
	var out := st.commit()
	if box.material != null:
		out.surface_set_material(0, box.material)
	out.resource_name = "%s with window" % mesh.name
	mesh.mesh = out
	return true

