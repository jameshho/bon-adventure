extends RefCounted
## Shared material palette for the modular town (docs/guides/MODULAR_TOWN.md, "Material palette").
## Before a unit or the base is saved, tools/bake_unit.gd routes its materials through here:
## every StandardMaterial3D / ORMMaterial3D that the town scene stores itself (not a prefab's or
## another file's) and that has an identical twin anywhere in the town becomes one shared file,
##   res://materials/palette/<hash>.tres   (hash = first 16 hex of SHA-256 of `look()`)
## so a look is stored once instead of once per scene file.
## Left unshared: materials marked `resource_local_to_scene`, materials with a texture or
## next_pass that is not itself a file (or a palette material), and every other class.
## Runtime rule: palette materials are shared by every scene that uses the look, so code that
## changes a material it found on a node must duplicate() it first (evidence_props.gd does).
const FOLDER := "res://materials/palette/"
const CLASSES := ["StandardMaterial3D", "ORMMaterial3D"]
## Content key -> palette material, for this run.
var by_look := {}
var counts := {}

## Exact content of a material: class plus every stored property (resource_name and metadata
## included), objects by file path, nested materials by their own look. "" = cannot be shared.
## strict = false (compare_scenes.gd): never "", built-in objects other than these materials
## are named by class.
static func look(material: Material, strict := true) -> String:
	var parts := [material.get_class()]
	for property in material.get_property_list():
		var name: String = property.name
		if property.usage & PROPERTY_USAGE_STORAGE == 0 or name in ["resource_path", "resource_local_to_scene", "resource_scene_unique_id"]:
			continue
		var value = material.get(name)
		if typeof(value) == TYPE_OBJECT and value != null:
			if value is Material and value.get_class() in CLASSES and not built_in(value) and not value.resource_path.begins_with(FOLDER):
				value = "file:" + value.resource_path
			elif value is Material and value.get_class() in CLASSES:
				var inner := look(value, strict)
				if inner == "":
					return ""
				value = "{" + inner + "}"
			elif value is Resource and not built_in(value):
				value = "file:" + value.resource_path
			elif strict:
				return ""
			else:
				value = "<" + value.get_class() + ">"
		parts.append(name + "=" + var_to_str(value))
	return "\n".join(parts)

static func built_in(resource: Resource) -> bool:
	return resource.resource_path == "" or resource.resource_path.contains("::")

## Saved by the town scene being baked (not a prefab's sub-resource or a file of its own).
static func town_owned(resource: Resource) -> bool:
	var path := resource.resource_path
	return path == "" or path.contains("::") and path.get_slice("::", 0).begins_with("res://scenes/town/")

static func file_for(key: String) -> String:
	return FOLDER + key.sha256_text().substr(0, 16) + ".tres"

func count(key: String, amount := 1) -> void:
	counts[key] = counts.get(key, 0) + amount

## The palette material for `material`, or `material` itself when it stays unshared.
func shared(material: Material) -> Material:
	if material == null or material.resource_path.begins_with(FOLDER):
		return material
	if not material.get_class() in CLASSES or material.resource_local_to_scene or not town_owned(material):
		return material
	# A nested material is shared first, so the palette file refers to it instead of a copy.
	var next: Material = material.next_pass
	if next != null:
		var shared_next := shared(next)
		if shared_next != next:
			material.next_pass = shared_next
	var key := look(material)
	if key == "":
		count("materials left unshared")
		return material
	if by_look.has(key):
		count("materials shared")
		return by_look[key]
	var path := file_for(key)
	var result: Material
	if ResourceLoader.exists(path):
		result = load(path)
		if look(result) != key:
			push_error("PALETTE: %s holds a different look (hash clash); left unshared" % path)
			count("hash clashes")
			return material
	else:
		result = material.duplicate()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
		var error := ResourceSaver.save(result, path)
		if error != OK:
			push_error("PALETTE: cannot save %s: %s" % [path, error_string(error)])
			count("save errors")
			return material
		# The scene then refers to the file instead of embedding a copy.
		result.take_over_path(path)
		count("palette files written")
	by_look[key] = result
	count("materials shared")
	return result

## Routes every material the scene under `top` stores through the palette: node properties
## (material_override, surface overrides, CSG/particle materials) and the town's own meshes.
func apply(top: Node) -> void:
	var visited := {}
	for node in [top] + top.find_children("*", "", true, false):
		route(node, visited)

## Every material the scene under `top` stores (node properties and the town's own meshes,
## visited once each): [owner object, property or surface, material]. Used by compare_scenes.gd.
static func materials_of(object: Object, visited: Dictionary, found: Array) -> void:
	if object is ArrayMesh:
		for surface in object.get_surface_count():
			if object.surface_get_material(surface) != null:
				found.append([object, "surface %d" % surface, object.surface_get_material(surface)])
	for property in object.get_property_list():
		if property.type != TYPE_OBJECT or property.usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		var value = object.get(property.name)
		if value is Material:
			found.append([object, property.name, value])
		elif value is Resource and not value is Script and not visited.has(value):
			visited[value] = true
			materials_of(value, visited, found)

func route(object: Object, visited: Dictionary) -> void:
	if object is ArrayMesh:
		for surface in object.get_surface_count():
			var material: Material = object.surface_get_material(surface)
			var swapped := shared(material)
			if swapped != material:
				object.surface_set_material(surface, swapped)
	for property in object.get_property_list():
		if property.type != TYPE_OBJECT or property.usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		var value = object.get(property.name)
		if value is Material:
			if object is Material and property.name == "next_pass":
				continue
			var swapped := shared(value)
			if swapped != value:
				object.set(property.name, swapped)
		elif value is Resource and not value is Script and town_owned(value) and not visited.has(value):
			visited[value] = true
			route(value, visited)
