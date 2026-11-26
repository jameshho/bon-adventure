extends RefCounted
## Snaps a building's colours to the game palette (P3-22, decision D14: tried 25 Nov 2026, shown
## as before/after; scripts/core/game_palette.gd, docs/guides/MODULAR_TOWN.md "Material palette").
## Used by a step in the building's own script:
##   preload("res://scripts/buildings/palette_snap.gd").snap(town, "<unit>")
## Every plain colour (opaque, untextured, no emission) the unit's own parts store that lies
## within LIMIT (OKLab) of a palette colour becomes that colour. Word roots of the "Building
## Parts" category (wall, roof, floor...) are recoloured with the building; their keys stay.
## Left as they are: other word roots (everything under them), instanced prefabs and characters, glass,
## lights and textured surfaces, and colours further than LIMIT from the palette (listed by
## tools/palette_report.gd). Found materials are never changed in place (they are shared):
## each one gets one recoloured copy, which the bake routes back into materials/palette/.
const MaterialPalette = preload("res://tools/material_palette.gd")
const ModularTown = preload("res://scripts/world/modular_town.gd")
const LIMIT := 0.06
const SHELL_CATEGORIES := ["Building Parts"]
static var _shell_words := {}

## A word root the snap may recolour (a part of the building itself, not a thing to learn by its colour).
static func shell_word(key: String) -> bool:
	if _shell_words.is_empty():
		var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json")).words
		for word in words:
			if words[word].get("category", "") in SHELL_CATEGORIES:
				_shell_words[word] = true
		_shell_words[""] = false
	return _shell_words.get(key, false)

## Returns {"recoloured": surfaces changed, "colours": distinct colours changed, "kept": far colours}.
static func snap(town: Node3D, unit: String, limit := LIMIT) -> Dictionary:
	var targets := MaterialPalette.palette_targets()
	var state := {"copies": {}, "targets": targets, "limit": limit, "recoloured": 0, "kept": {}}
	var parts: Array = ModularTown.registry()[unit].parts
	for index in parts.size():
		var part := ModularTown.building(town, unit, index)
		if part != null:
			_walk(part, part, state)
	var result := {"recoloured": state.recoloured, "colours": state.copies.size(), "kept": state.kept.size()}
	print("PALETTE SNAP %s: %s" % [unit, result])
	return result

static func _walk(node: Node, part: Node, state: Dictionary) -> void:
	if node.has_meta("word_key") and not shell_word(str(node.get_meta("word_key"))):
		return
	if node != part and node.scene_file_path != "":
		return
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi := node as MeshInstance3D
		if mi.material_override != null:
			var swapped = _copy(mi.material_override, state)
			if swapped != null:
				mi.material_override = swapped
				state.recoloured += 1
		else:
			for surface in mi.mesh.get_surface_count():
				var material: Material = mi.get_surface_override_material(surface)
				if material == null:
					material = mi.mesh.surface_get_material(surface)
				var swapped = _copy(material, state)
				if swapped != null:
					mi.set_surface_override_material(surface, swapped)
					state.recoloured += 1
	elif node is CSGBox3D:
		var swapped = _copy((node as CSGBox3D).material, state)
		if swapped != null:
			(node as CSGBox3D).material = swapped
			state.recoloured += 1
	for child in node.get_children():
		_walk(child, part, state)

## The recoloured copy of `material`, or null when it stays.
static func _copy(material: Material, state: Dictionary):
	if not material is BaseMaterial3D or material.get_class() not in MaterialPalette.CLASSES:
		return null
	var m := material as BaseMaterial3D
	if m.albedo_texture != null or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or m.emission_enabled:
		return null
	var path := m.resource_path
	if not (path == "" or path.begins_with(MaterialPalette.FOLDER) or path.begins_with("res://scenes/town/")):
		return null
	if state.copies.has(m):
		return state.copies[m]
	var best := MaterialPalette.nearest(m.albedo_color, state.targets)
	if best[2] > state.limit:
		state.kept[m.albedo_color.to_html(false)] = true
		return null
	var target: Color = best[1]
	target.a = m.albedo_color.a
	if target.is_equal_approx(m.albedo_color):
		return null
	var copy := m.duplicate() as BaseMaterial3D
	copy.albedo_color = target
	state.copies[m] = copy
	return copy
