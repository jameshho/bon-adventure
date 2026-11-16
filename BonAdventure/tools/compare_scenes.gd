extends SceneTree
## Compares two saved scenes node by node, e.g. a town scene before and after a bake
## (docs/guides/MODULAR_TOWN.md, "Changing a building"):
##   cp scenes/town/base.scn /tmp/base-before.scn   # before baking
##   godot --headless --path . --script res://tools/compare_scenes.gd -- /tmp/base-before.scn res://scenes/town/base.scn
## Both scenes are instanced without entering the tree (no _ready runs), so this compares what
## is saved. Per node path: class, transform, script, groups, meta keys and (plain-data) meta
## values; every material the node stores (its own properties and meshes) by exact content
## (MaterialPalette.look(), so a material moved into the shared palette compares equal); plus the
## root's `applied_steps`. Also prints how many StandardMaterial3D/ORMMaterial3D objects each
## scene holds: stored in the scene vs shared files. Ends with one summary line:
##   COMPARE: <before> nodes vs <after> nodes, <n> differences
## Exit code 0 when the scenes match, 1 when they differ.
const SHOWN := 40
const MaterialPalette = preload("res://tools/material_palette.gd")
var material_counts := {}

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        printerr("COMPARE: pass two scenes after --, e.g.  -- before.scn after.scn")
        quit(2)
        return
    var before := dump(args[0])
    var after := dump(args[1])
    if before.is_empty() or after.is_empty():
        quit(2)
        return
    var differences: Array = []
    for path in before:
        if not after.has(path):
            differences.append("only before: " + path)
    for path in after:
        if not before.has(path):
            differences.append("only after:  " + path)
            continue
        for field in after[path]:
            if not same(before[path].get(field), after[path][field]):
                differences.append("changed %s %s: %s -> %s" % [path, field, short(before[path].get(field)), short(after[path][field])])
    for line in differences.slice(0, SHOWN):
        print("  ", line)
    if differences.size() > SHOWN:
        print("  ... and ", differences.size() - SHOWN, " more")
    for which in [args[0], args[1]]:
        var counted: Dictionary = material_counts[which]
        print("COMPARE: materials in %s: %d stored in the scene, %d shared palette files, %d from other files (prefabs)" % [which, counted.scene, counted.palette, counted.file])
    print("COMPARE: applied_steps ", before["."].steps, " -> ", after["."].steps)
    print("COMPARE: ", before.size(), " nodes vs ", after.size(), " nodes, ", differences.size(), " differences")
    quit(0 if differences.is_empty() else 1)

## path -> {class, transform, script, groups, metas, steps (root only)}
func dump(path: String) -> Dictionary:
    var packed := load(path) as PackedScene
    if packed == null:
        printerr("COMPARE: cannot load ", path)
        return {}
    var top := packed.instantiate()
    var result := {}
    var distinct := {}
    for node in [top] + top.find_children("*", "", true, false):
        var entry := {
            "class": node.get_class(),
            "script": node.get_script().resource_path if node.get_script() != null else "",
            "groups": Array(node.get_groups()).map(func(group): return String(group)),
            "metas": {},
        }
        entry.groups.sort()
        if node is Node3D:
            entry["transform"] = node.transform
        var found: Array = []
        MaterialPalette.materials_of(node, {}, found)
        var looks: Array = []
        for item in found:
            var where: String = item[1] if item[0] == node else item[0].get_class() + "." + item[1]
            looks.append(where + ": " + str(MaterialPalette.look(item[2], false).hash()))
            if item[2].get_class() in MaterialPalette.CLASSES:
                distinct[item[2]] = true
        if not looks.is_empty():
            entry["materials"] = looks
        for meta in node.get_meta_list():
            var value = node.get_meta(meta)
            # Objects are compared by type only (their ids differ between instances).
            entry.metas[String(meta)] = value.get_class() if typeof(value) == TYPE_OBJECT and value != null else var_to_str(value).hash()
        if node == top:
            entry["steps"] = node.get_meta("applied_steps", [])
            entry.metas.erase("applied_steps")
        result[String(top.get_path_to(node))] = entry
    top.free()
    var counted := {"scene": 0, "palette": 0, "file": 0}
    for material in distinct:
        var source: String = material.resource_path.get_slice("::", 0)
        var key := "palette" if source.begins_with(MaterialPalette.FOLDER) else "scene" if source == "" or source == path else "file"
        counted[key] += 1
    material_counts[path] = counted
    return result

func same(a, b) -> bool:
    if a is Transform3D and b is Transform3D:
        return a.is_equal_approx(b)
    return typeof(a) == typeof(b) and a == b

func short(value) -> String:
    var text := str(value)
    return text if text.length() <= 160 else text.substr(0, 157) + "..."
