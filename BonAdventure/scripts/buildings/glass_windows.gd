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

