extends RefCounted
## Shop row restyle (user, 18 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Game palette and shop
## row"): the bakery, clothing, electronics, sports and furniture stores share one storefront
## (base band, cream wall, pillars, sign band, frames, sills, awnings, flower box, wall lamps) and
## differ only by one accent family of scripts/core/game_palette.gd. Only exterior surfaces are
## recoloured; geometry is kept, except the sports store's new window awnings. Used by step
## `shop_row_style` of each of the five own scripts.
const Palette := preload("res://scripts/core/game_palette.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")

const ACCENT := {"bakery": "coral", "clothing": "rose", "electronics": "sky", "sports": "meadow", "furniture": "teal"}

## Exterior nodes of the shell parts (Buildings/...), by name prefix; the rest is the interior.
const SHELL := {
	"wall": ["FrontWallLeft", "FrontWallRight", "FrontHeader", "AboveWindow", "BelowWindow",
		"ExteriorSidePier", "RearWall", "FrontLeft_11", "FrontRight_13", "Left_7", "Right_9",
		"Rear_5", "Lintel_15", "Corner pier"],
	"deep": ["Fascia", "FlatRoof", "Roof_18", "Parapet front", "Parapet rear", "Parapet side",
		"Door header", "Door post", "Sign border"],
	"trim": ["DoorJamb", "WindowSill", "ShopSignPanel", "SignBoard_19", "Parapet underline"],
	"stone": ["DoorStep"],
}

## Facade parts (Map facades/...): role by the (lower-case) name of the piece. Unnamed copies of a
## piece (the second window, the other awning) take the name of the named piece with the same
## mesh and colour. Checked in order; the first match wins.
const FACADE := [
	["lamp glass", ""], ["glass", ""], ["glazing", ""], ["soil", ""], ["leaves", ""],
	["flower box", "planter"], ["flower", ""],
	["lamp", "iron"],
	["icon screen", "ink"], ["icon", "trim"], ["emblem", "trim"], ["steam", "trim"],
	["cup", "trim"], ["saucer", "trim"], ["hanger", "trim"],
	["awning", "stripe"], ["valance", "stripe"], ["canopy", "main"],
	["sill", "trim"], ["gable trim", "trim"], ["coping", "trim"], ["sign face", "trim"],
	["plinth", "stone"], ["stone base", "stone"], ["planter", "stone"],
	["groove", "wood_dark"], ["cladding", "wood"],
	["plaster", "wall"], ["skin", "wall"],
	["frame", "deep"], ["mullion", "deep"], ["pilaster", "deep"], ["reveal", "deep"],
	["sign band", "deep"], ["sign backing", "deep"], ["parapet", "deep"], ["roof edge", "deep"],
	["hood", "deep"], ["corner finish", "deep"], ["jamb", "deep"], ["trim band", "deep"],
]

## Pieces of a facade that carry no useful name (the gables and logos on the facade root), by
## their colour before the restyle.
const FACADE_COLOURS := {
	"c4574f": "main",   # clothing gable
	"b5473a": "main",   # bakery gable
	"e8b53f": "light",  # sports mountain logo
	"f6efe4": "trim",   # sports logo snow cap, clothing awning stripes
	"f4f1ea": "trim",   # electronics awning stripes
	"eee5d4": "trim",   # bakery awning stripes and emblem
}

## The unit's storefront part (Map facades/...).
static func facade_of(town: Node3D, unit: String) -> Node3D:
	for path in ModularTown.registry()[unit].parts:
		if str(path).begins_with("Map facades/"):
			return town.get_node_or_null(NodePath(path))
	return null

static func colour(unit: String, role: String) -> Color:
	var family: String = ACCENT[unit]
	match role:
		"wall": return Palette.WALL_CREAM
		"trim", "stripe_light": return Palette.TRIM
		"stone": return Palette.STONE
		"iron": return Palette.IRON
		"ink": return Palette.INK
		"wood", "planter": return Palette.WOOD
		"wood_dark": return Palette.WOOD_DARK
		"light": return Palette.accent(family, 0)
		"main", "stripe": return Palette.accent(family, 1)
		"deep": return Palette.accent(family, 2)
	return Color.MAGENTA

static func restyle(town: Node3D, game, unit: String) -> Dictionary:
	var counts := {"recoloured": 0, "kept": 0}
	var shell := ModularTown.building(town, unit, 1)
	var facade := facade_of(town, unit)
	if shell == null or facade == null:
		push_error("shop_row: %s not loaded" % unit)
		return counts
	for role in SHELL:
		for prefix in SHELL[role]:
			for node in shell.find_children(prefix + "*", "", true, false):
				for mesh in _meshes(node):
					_paint(mesh, colour(unit, role), game, counts)
	# Facade: name each unnamed copy after its named twin (same mesh and colour).
	var meshes := _meshes(facade)
	var twins := {}
	for mesh in meshes:
		var label := _label(mesh, facade)
		if label != "":
			twins[_key(mesh)] = label
	for mesh in meshes:
		var label := _label(mesh, facade)
		if label == "":
			label = twins.get(_key(mesh), "")
		var role := _role(label.to_lower(), mesh)
		if role == "":
			var hex := _hex(mesh)
			role = FACADE_COLOURS.get(hex, "")
		if role == "":
			counts.kept += 1
			continue
		if role == "stripe" and _hex(mesh) in FACADE_COLOURS and FACADE_COLOURS[_hex(mesh)] == "trim":
			role = "stripe_light"
		if role == "planter" and (mesh.mesh as BoxMesh) != null and (mesh.mesh as BoxMesh).size.y < .45:
			counts.kept += 1   # the soil, not the box
			continue
		_paint(mesh, colour(unit, role), game, counts)
	return counts

static func _role(label: String, mesh: MeshInstance3D) -> String:
	for rule in FACADE:
		if label.contains(rule[0]):
			return rule[1]
	return ""

## The nearest named node between the mesh and the part ("" when all are unnamed).
static func _label(mesh: Node, part: Node) -> String:
	var node := mesh
	while node != null and node != part:
		if not str(node.name).begins_with("@"):
			return str(node.name)
		node = node.get_parent()
	return ""

static func _key(mesh: MeshInstance3D) -> String:
	return "%d:%s" % [mesh.mesh.get_instance_id(), _hex(mesh)]

static func _hex(mesh: MeshInstance3D) -> String:
	var mat := mesh.material_override as StandardMaterial3D
	return mat.albedo_color.to_html(false) if mat != null else ""

## Plain single-colour meshes only: no glass, no lit lamps, nothing inside an instanced scene
## (windows, doors, prefabs keep their own materials).
static func _meshes(root: Node) -> Array:
	var found := []
	var all: Array = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		all.append(root)
	for mesh: MeshInstance3D in all:
		if mesh.mesh == null or mesh.mesh.get_surface_count() != 1:
			continue
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or mat.emission_enabled:
			continue
		var inside_scene := false
		var node: Node = mesh
		while node != null and node != root.get_parent():
			if node != mesh and node.scene_file_path != "":
				inside_scene = true
				break
			node = node.get_parent()
		if not inside_scene:
			found.append(mesh)
	return found

static func _paint(mesh: MeshInstance3D, color: Color, game, counts: Dictionary) -> void:
	if (mesh.material_override as StandardMaterial3D).albedo_color.is_equal_approx(color):
		return
	var old := mesh.material_override as StandardMaterial3D
	var mat: StandardMaterial3D = game.material_for(color)
	# One-sided pieces (the gables are single triangles) keep drawing both faces.
	if old.cull_mode != mat.cull_mode:
		mat = mat.duplicate()
		mat.cull_mode = old.cull_mode
	mesh.material_override = mat
	counts.recoloured += 1

## Striped awnings over the sports store's two shop windows, built like the clothing store's: 0.4
## wide stripes (main / trim) 1.1 deep, tilted 16 degrees (outer edge down), 0.17 above the frame
## and 0.59 in front of it, with a 0.3 valance 1.12 out. Call after restyle() (frames by name or
## by their named twin).
static func add_awnings(town: Node3D, game, unit: String) -> int:
	var shell := ModularTown.building(town, unit, 1)
	var facade := facade_of(town, unit)
	var mat := shell.find_child("Entry mat", true, false) as Node3D
	var centre := Vector3.ZERO
	var n := 0
	for m in shell.find_children("*", "MeshInstance3D", true, false):
		centre += m.global_position
		n += 1
	centre /= maxf(n, 1)
	var out := mat.global_position - centre
	out.y = 0.0
	out = out.normalized()
	var meshes := _meshes(facade)
	var twins := {}
	for mesh in meshes:
		if _label(mesh, facade) != "":
			twins[_key(mesh)] = _label(mesh, facade)
	var added := 0
	for mesh in meshes:
		var box := mesh.mesh as BoxMesh
		var label: String = _label(mesh, facade)
		if label == "":
			label = twins.get(_key(mesh), "")
		if box == null or not label.to_lower().contains("window frame"):
			continue
		if box.size.y < 1.8 or maxf(box.size.x, box.size.z) < 1.8:
			continue
		var wide_x := box.size.x > box.size.z
		var local_out: Vector3 = mesh.global_transform.basis.inverse() * out
		var dir := Vector3(0, 0, signf(local_out.z)) if wide_x else Vector3(signf(local_out.x), 0, 0)
		var across := Vector3(1, 0, 0) if wide_x else Vector3(0, 0, 1)
		var tilt := Vector3(-16.0 * dir.z, 0, 0) if wide_x else Vector3(0, 0, -16.0 * dir.x)
		var width: float = (box.size.x if wide_x else box.size.z) + .3
		var top: float = box.size.y / 2.0
		var awning := Node3D.new()
		awning.name = "Striped awning"
		facade.add_child(awning, true)
		awning.global_transform = mesh.global_transform
		var stripes := roundi(width / .4)
		for i in stripes:
			var along: float = (i - (stripes - 1) / 2.0) * .4
			var tint := colour(unit, "main") if i % 2 == 0 else colour(unit, "trim")
			for piece in [[Vector3(.4, .08, 1.1), top + .173, .589, true], [Vector3(.4, .3, .05), top - .129, 1.117, false]]:
				var size: Vector3 = piece[0] if wide_x else Vector3(piece[0].z, piece[0].y, piece[0].x)
				var part: Node3D = game.box("Awning stripe" if piece[3] else "Awning valance", Vector3.ZERO, size, tint, "", false)
				part.reparent(awning, false)
				part.position = across * along + Vector3(0, piece[1], 0) + dir * piece[2]
				if piece[3]:
					part.rotation_degrees = tilt
				added += 1
	return added
