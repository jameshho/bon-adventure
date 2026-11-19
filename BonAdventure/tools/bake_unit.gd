extends SceneTree
## One-building bake (docs/guides/MODULAR_TOWN.md, "Changing a building"): applies the steps of a
## building's own script that its unit scene does not have yet, then saves only that unit.
##   godot --headless --path . --script res://tools/bake_unit.gd -- police [restaurants ...]
## `base` names the base world (scenes/town/base.scn: garden, zoo, roads, vehicles, map/layout
## data) with its own script scripts/buildings/base.gd; it can be baked alone or with units:
##   godot --headless --path . --script res://tools/bake_unit.gd -- base [police ...]
## The whole modular town loads (every unit, whatever dev_focus.txt says), so references between
## buildings resolve and a step can look at its neighbours; only the named scenes are written.
## Review a bake with tools/compare_scenes.gd (copy the scene first).
##
## Own script, optional: scripts/buildings/<unit>.gd (unit names: data/buildings.json)
##   extends RefCounted
##   const STEPS := ["add_bench", ...]          # applied in this order, each exactly once
##   func add_bench(town: Node3D, game) -> void # town = Main's Apartment, scale 1.3, town coords
## Applied step names are kept in the scene's `applied_steps` meta, so a step never runs
## twice; never rename or remove a step that was baked. With no new steps a scene is simply
## re-saved (a round trip, used to check this tool).
## Base steps may also change the layout data in game.reference_layout (sites, site_bounds,
## roads, entries, details, spawn_point): it is saved as the base's `baked_layout` meta.
## Nodes that scripts build at runtime (ownerless when the town has loaded) are not saved: a
## scene that kept them would get them twice at the next load. Nodes the steps add are kept.
## What a plain scene save would lose, and how it is kept (as in the one-time full bake of
## 6 Nov 2026, now deleted; see git history for tools/bake_modular_town.gd):
##   door states            -> `door_state` meta, restored by Main
##   sign translation       -> labels go back to their source text; translated at load
##   reference layout       -> `baked_layout` meta on the base, restored by reference_world_layout
##   node refs in metadata  -> `<meta>__ref(s)` town-relative paths + `node_refs` list
##   runtime groups         -> re-added as persistent groups
##   generated meshes       -> character sculpts, costumes, tree/bush models are rebuilt by their
##                             own scripts at load, so their generated output is not saved
## Materials: before saving, identical materials are routed through the shared palette
## (tools/material_palette.gd, materials/palette/<hash>.tres), so a look is stored once.
## Meshes: then exact copies in the scene are pointed at one mesh (tools/mesh_share.gd, 17 Nov 2026),
## so the scene and the GPU hold it once.
const SignLanguage = preload("res://scripts/world/sign_language.gd")
const ModularTown = preload("res://scripts/world/modular_town.gd")
const MaterialPalette = preload("res://tools/material_palette.gd")
const MeshShare = preload("res://tools/mesh_share.gd")
const BUILDINGS := "res://scripts/buildings/"
## Name of the base world (scenes/town/base.scn, own script scripts/buildings/base.gd).
const BASE := "base"
const RUNTIME_GROUPS := ["translated_signs"]
var town: Node3D
var old_owner: Node
var report := {}
var unit_indices := {}
var palette := MaterialPalette.new()
var mesh_share := MeshShare.new()

func _initialize() -> void:
    run_units.call_deferred()

func count(key: String, amount := 1) -> void:
    report[key] = report.get(key, 0) + amount

func unit_path(key: String) -> String:
    return ModularTown.FOLDER + key + "." + ModularTown.EXTENSION

## The `applied_steps` meta of a saved scene's root, read without instancing it (the base has
## about 16,000 nodes).
func saved_steps(path: String) -> Array:
    if not ResourceLoader.exists(path):
        return []   # a new unit: its first bake writes the scene (its steps build its parts)
    var state: SceneState = (load(path) as PackedScene).get_state()
    for i in state.get_node_property_count(0):
        if state.get_node_property_name(0, i) == "metadata/applied_steps":
            return Array(state.get_node_property_value(0, i))
    return []

## Part name -> `unit_index` of each part saved in a unit scene: a re-saved part keeps its place
## (the loader re-inserts parts in index order, so a part's index read back from the loaded town
## would drift with every bake that splits all units).
func saved_indices(path: String) -> Dictionary:
    var indices := {}
    if not ResourceLoader.exists(path):
        return indices
    var state: SceneState = (load(path) as PackedScene).get_state()
    for i in range(1, state.get_node_count()):
        if String(state.get_node_path(i, true)) != ".":
            continue
        for j in state.get_node_property_count(i):
            if state.get_node_property_name(i, j) == "metadata/unit_index":
                indices[String(state.get_node_name(i))] = state.get_node_property_value(i, j)
    return indices

func run_units() -> void:
    var keys := Array(OS.get_cmdline_user_args())
    var units: Dictionary = ModularTown.registry()
    if keys.is_empty() or keys.any(func(key): return key != BASE and not units.has(key)):
        printerr("BAKE UNIT: name units from data/buildings.json (or base) after --, e.g.  -- police")
        quit(1)
        return
    var with_base := keys.has(BASE)
    keys.erase(BASE)
    OS.set_environment("VT_FOCUS", "all")
    var applied := {}
    for key in keys + ([BASE] if with_base else []):
        applied[key] = saved_steps(unit_path(key))
    for key in (units.keys() if with_base else keys):
        unit_indices[key] = saved_indices(unit_path(key))
    var game = load("res://scenes/main.tscn").instantiate()
    game.set_meta("bake_world_only", true)
    root.add_child(game)
    game.set_process(false)
    town = game.apartment
    old_owner = town
    # The loader gives every saved node an owner, so what is ownerless now was built by a script
    # at runtime (and is built again at every load): recorded before the steps add their nodes.
    var runtime_built := ownerless(town)
    for key in ([BASE] if with_base else []) + keys:
        var own_path: String = BUILDINGS + key + ".gd"
        if not ResourceLoader.exists(own_path):
            continue
        var own = load(own_path).new()
        for step in own.STEPS:
            if applied[key].has(step):
                continue
            print("BAKE UNIT: ", key, ": ", step)
            own.call(step, town, game)
            applied[key].append(step)
            count("steps")
    # Let nodes the steps queue_free()d go before anything is saved.
    for i in 3:
        await process_frame
    keep_doors(game)
    keep_signs()
    if with_base:
        # Node paths: taken while every unit is still in the town.
        town.set_meta("baked_layout", game.reference_layout.bake_state())
        for meta in ["reference_map_sites", "reference_map_details", "translated_signs", "loaded_units"]:
            town.remove_meta(meta)
        strip_generated(town)
    else:
        for key in keys:
            for part_path in units[key].parts:
                var part: Node = town.get_node_or_null(NodePath(part_path))
                if part != null:
                    strip_generated(part)
    # The town keeps running until the process exits: scripts whose runtime-built children are
    # dropped here (the crabs' Body mesh) would touch freed nodes in their next _process
    # ("previously freed" errors after "BAKE UNIT: done", 7 Nov 2026). Main's root is not saved.
    game.process_mode = Node.PROCESS_MODE_DISABLED
    drop_runtime_built(runtime_built)
    # With the base, every unit leaves the town (it must not be saved in the base too); only
    # the named ones are saved.
    var holders := {}
    for key in (units.keys() if with_base else keys):
        holders[key] = split_unit(key, units[key].parts)
    for key in keys:
        keep_viewport_textures(holders[key])
    for key in keys:
        holders[key].set_meta("node_refs", convert_refs(holders[key], true))
        holders[key].set_meta("applied_steps", applied[key])
    var failed := 0
    for key in keys:
        failed += save(holders[key], unit_path(key))
    if with_base:
        keep_viewport_textures(town)
        town.set_meta("node_refs", convert_refs(town, false))
        town.set_meta("modular_town", true)
        town.set_meta("applied_steps", applied[BASE])
        # Main instances base.scn; saved as an instance of itself it would not load.
        town.scene_file_path = ""
        failed += save(town, unit_path(BASE))
    # The unit holders are outside the tree: free them, or Godot reports them leaked at exit.
    for key in holders:
        holders[key].free()
    report.merge(palette.counts)
    report.merge(mesh_share.counts)
    print("BAKE UNIT: report ", report)
    print("BAKE UNIT: ", "done" if failed == 0 else str(failed) + " failed")
    quit(0 if failed == 0 else 1)

## Topmost nodes under `top` without an owner.
func ownerless(top: Node) -> Array:
    var found: Array = []
    for child in top.get_children():
        if child.owner == null:
            found.append(child)
        else:
            found.append_array(ownerless(child))
    return found

## Frees the runtime-built nodes recorded before the steps (a script builds them again at load).
## One that holds saved nodes (a script moved them under it) is kept and reported.
func drop_runtime_built(nodes: Array) -> void:
    for node in nodes:
        if not is_instance_valid(node) or not node.is_inside_tree():
            continue
        if node.find_children("*", "", true, false).any(func(child): return child.owner == old_owner):
            printerr("BAKE: kept runtime-built ", town.get_path_to(node), ": it holds saved nodes")
            count("runtime-built kept")
            continue
        node.get_parent().remove_child(node)
        node.free()
        count("runtime-built dropped")

func keep_doors(game) -> void:
    for node in game.doors:
        if is_instance_valid(node):
            var state: Dictionary = game.doors[node].duplicate(true)
            state["open"] = false
            node.set_meta("door_state", state)
            count("doors")

func keep_signs() -> void:
    for label in town.find_children("*", "Label3D", true, false):
        if not label.is_in_group(SignLanguage.GROUP):
            continue
        label.text = label.get_meta("sign_source", label.get_meta("sign_english"))
        label.font_size = int(label.get_meta("sign_font_size"))
        # World signs (world_sign.gd) keep their base pixel size in the scene.
        if label.has_meta("sign_pixel_size"):
            label.pixel_size = float(label.get_meta("sign_pixel_size"))
        # Sizes as authored, before the web's shared label sizes (sign_language.gd _set_size()).
        elif label.has_meta("sign_pixel_base"):
            label.pixel_size = float(label.get_meta("sign_pixel_base"))
            label.outline_size = int(label.get_meta("sign_outline_base", label.outline_size))
        for meta in ["sign_english", "sign_spanish", "sign_font_size", "sign_source", "sign_kind",
                "sign_pixel_base", "sign_outline_base"]:
            label.remove_meta(meta)
        label.remove_from_group(SignLanguage.GROUP)
        count("signs")

## Output that scripts rebuild in _ready is not saved (it would be saved twice and bloat files).
func strip_generated(node: Node) -> void:
    var script: Script = node.get_script()
    var path: String = script.resource_path if script != null else ""
    if path.ends_with("plush_costume.gd"):
        for child in node.get_children():
            node.remove_child(child)
            child.free()
            count("costume pieces")
        return
    if path.ends_with("hospital_elevator.gd") or path.ends_with("crab.gd"):
        # They build their parts in _ready; keep only parts that come from a prefab, and parts
        # another pass hung on the elevator car (re-attached by hospital_elevator.gd _ready).
        node.set_process(false)
        node.set_physics_process(false)
        if path.ends_with("crab.gd"):
            # Saved where it was loaded (the centre of its wander line), not where it scuttled.
            node.position = node.home
        for kept in node.find_children("*", "", true, false):
            if kept.has_meta("ride_with_car") and kept.get_parent() != node:
                var local: Transform3D = kept.transform
                kept.get_parent().remove_child(kept)
                node.add_child(kept)
                kept.transform = local
        for child in node.get_children():
            if child.has_meta("ride_with_car"):
                continue
            if child.owner == null or child.owner == old_owner:
                node.remove_child(child)
                child.free()
                count("self-built parts")
    if path.ends_with("vehicle_door.gd"):
        # A saved door leaf is reused by VehicleDoors.install() instead of re-splitting the body.
        # A scene may mark a leaf as not a boarding door (box truck passenger and cargo doors).
        if not node.has_meta("boarding_door"):
            node.set_meta("boarding_door", true)
    if path.ends_with("glass_window.gd"):
        # Shared window component (docs/guides/WINDOWS.md): its glass and frame are rebuilt at load.
        for child in node.get_children():
            if child.has_meta("glass_window_part"):
                node.remove_child(child)
                child.free()
                count("window parts")
    if path in ["res://scripts/world/door.gd", "res://scripts/world/double_door.gd", "res://scripts/world/sliding_door.gd"]:
        # Shared door components (docs/guides/DOORS.md): frame, leaves and handles are rebuilt at load.
        for child in node.get_children():
            if child.has_meta("door_part"):
                node.remove_child(child)
                child.free()
                count("door parts")
    if path.ends_with("library_book.gd"):
        # Reusable book (scenes/props/book.tscn): model, cover title and pick area rebuilt at load.
        for child in node.get_children():
            if child.has_meta("library_book_part"):
                node.remove_child(child)
                child.free()
                count("book parts")
    if path.ends_with("tree_species.gd") or path.ends_with("bush_species.gd"):
        for child in node.get_children():
            if child.has_meta("tree_species_part") or child.has_meta("bush_species_part"):
                node.remove_child(child)
                child.free()
                count("plant parts")
    if node is MeshInstance3D and node.mesh is ArrayMesh and node.mesh.resource_path == "" and generated_by_character(node):
        node.mesh = null
        count("character meshes")
    for child in node.get_children():
        strip_generated(child)

func generated_by_character(node: Node) -> bool:
    var parent := node.get_parent()
    while parent != null and parent != town:
        var script: Script = parent.get_script()
        if script != null and script.resource_path.begins_with("res://scripts/characters/"):
            return true
        parent = parent.get_parent()
    return false

func split_unit(key: String, parts: Array) -> Node3D:
    var holder := Node3D.new()
    holder.name = key
    holder.set_meta("modular_unit", key)
    for part_path in parts:
        var part: Node3D = town.get_node_or_null(NodePath(part_path))
        if part == null:
            printerr("BAKE: unit ", key, " has no part ", part_path)
            count("missing parts")
            continue
        var parent := part.get_parent()
        var stored := ModularTown.town_transform(town, part)
        part.set_meta("unit_parent", String(town.get_path_to(parent)))
        part.set_meta("unit_name", String(part.name))
        var stored_name := String(part_path).replace("/", "__")
        part.set_meta("unit_index", unit_indices.get(key, {}).get(stored_name, part.get_index()))
        parent.remove_child(part)
        part.name = stored_name
        holder.add_child(part)
        part.transform = stored
    return holder

## Metadata holding nodes becomes town-relative paths; returns the holders' paths.
func convert_refs(top: Node, is_unit: bool) -> Array:
    var holders: Array = []
    for node in [top] + top.find_children("*", "", true, false):
        var changed := false
        for meta in node.get_meta_list():
            var value = node.get_meta(meta)
            if value is Array and value.any(func(item): return typeof(item) == TYPE_OBJECT and not is_instance_valid(item)):
                value = value.filter(func(item): return is_instance_valid(item))
                count("refs to dropped nodes")
            elif typeof(value) == TYPE_OBJECT and not is_instance_valid(value):
                # A runtime-built node, dropped: its script links it again at load.
                node.remove_meta(meta)
                count("refs to dropped nodes")
                continue
            if value is Node:
                node.set_meta(String(meta) + "__ref", town_path(value))
                node.remove_meta(meta)
                changed = true
            elif value is Array and not value.is_empty() and value.all(func(item): return item is Node):
                node.set_meta(String(meta) + "__refs", value.map(func(item): return town_path(item)))
                node.remove_meta(meta)
                changed = true
        if changed:
            holders.append(town_path(node) if not is_unit else unit_town_path(top, node))
            count("node refs")
    return holders

## A node's path in the assembled town (parts are stored under their unit holder).
func town_path(node: Node) -> NodePath:
    var unit_part := node
    while unit_part != null and unit_part.get_parent() != null and not unit_part.get_parent().has_meta("modular_unit"):
        unit_part = unit_part.get_parent()
    if unit_part != null and unit_part.get_parent() != null and unit_part.get_parent().has_meta("modular_unit"):
        var rest := String(unit_part.get_path_to(node))
        var base: String = unit_part.get_meta("unit_parent") + "/" + unit_part.get_meta("unit_name")
        if base.begins_with("./"): base = base.substr(2)
        if base.begins_with("."): base = base.substr(1).lstrip("/")
        return NodePath(base if rest == "." else base + "/" + rest)
    return town.get_path_to(node)

func unit_town_path(_top: Node, node: Node) -> NodePath:
    return town_path(node)

func prepare(node: Node, top: Node) -> void:
    if node != top:
        if node.owner == null or node.owner == old_owner or not top.is_ancestor_of(node.owner) and node.owner != top:
            node.owner = top
        if node.scene_file_path != "" and node.owner == top:
            top.set_editable_instance(node, true)
    for group in node.get_groups():
        if String(group).begins_with("_") or RUNTIME_GROUPS.has(String(group)):
            continue
        node.remove_from_group(group)
        node.add_to_group(group, true)
    for child in node.get_children():
        prepare(child, top)

## A prefab instance whose own nodes were moved elsewhere by a startup pass (e.g. the school's
## retained desks) cannot be saved as an instance: it would come back with those nodes
## missing. Such instances are saved as plain nodes.
func flatten_broken(top: Node) -> void:
    while true:
        var broken := {}
        for node in top.find_children("*", "", true, false):
            var owner_node: Node = node.owner
            if owner_node == null or owner_node == top or owner_node == old_owner:
                continue
            var parent := node.get_parent()
            if parent != owner_node and parent.owner != owner_node:
                mark_broken(broken, owner_node, top)
        # Instances (nested ones too) that lost one of their own prefab nodes (deleted by a
        # pass): a scene cannot record a deleted instance node, so it would come back.
        for node in top.find_children("*", "", true, false):
            if node.scene_file_path == "" or broken.has(node):
                continue
            var state: SceneState = load(node.scene_file_path).get_state()
            for i in state.get_node_count():
                if not node.has_node(state.get_node_path(i)):
                    mark_broken(broken, node, top)
                    break
        if broken.is_empty():
            return
        var all_nodes := top.find_children("*", "", true, false)
        for node in all_nodes:
            if broken.has(node.owner):
                node.owner = top
        for owner_node in broken:
            owner_node.scene_file_path = ""
            owner_node.owner = top
            count("flattened instances")

## Sprites showing a SubViewport (e.g. the restaurant posters' icon sheets) hold the viewport's
## runtime texture, which a scene cannot save: keep a `viewport_texture` link (converted like any
## node ref); modular_town.gd gives the sprite the viewport's texture again at load.
func keep_viewport_textures(top: Node) -> void:
    var viewports := {}
    for view in top.find_children("*", "SubViewport", true, false):
        viewports[view.get_texture()] = view
    for sprite in top.find_children("*", "Sprite3D", true, false):
        if sprite.texture is ViewportTexture and viewports.has(sprite.texture):
            sprite.set_meta("viewport_texture", viewports[sprite.texture])
            sprite.texture = null
            count("viewport textures")

## An instance nested in another prefab can only be saved as plain nodes if the prefabs that
## contain it are too.
func mark_broken(broken: Dictionary, node: Node, top: Node) -> void:
    while node != null and node != top and node != old_owner:
        if node.scene_file_path != "":
            broken[node] = true
        node = node.owner

func save(top: Node, path: String) -> int:
    flatten_broken(top)
    prepare(top, top)
    palette.apply(top)
    mesh_share.apply(top)
    var packed := PackedScene.new()
    var error := packed.pack(top)
    if error == OK:
        error = ResourceSaver.save(packed, path)
    print("BAKE: ", path, " ", error_string(error), " (", top.find_children("*", "", true, false).size(), " nodes)")
    return 0 if error == OK else 1
