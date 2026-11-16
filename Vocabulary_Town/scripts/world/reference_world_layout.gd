extends RefCounted
## Town layout data at runtime: site pivots and bounds, roads, map entries and details, read
## from the base world's `baked_layout` meta (scenes/town/base.scn) by restore() and written
## back by bake_state() when tools/bake_unit.gd saves the base. The startup
## pass that once relocated the old town into this layout (build(), bind() and their helpers)
## was deleted on 6 Nov 2026; see git history and docs/MODULAR_TOWN.md.
const ModularTown := preload("res://scripts/world/modular_town.gd")
var game
var town: Node3D
var data: Dictionary
var sites: Dictionary = {}
var pivots: Dictionary = {}
var site_bounds: Dictionary = {}
var roads: Array[Dictionary] = []
var entries: Array[Dictionary] = []
var details: Array[Node3D] = []
var spawn_point := Vector3.ZERO

## Reads the baked layout back. Units that are not loaded (dev focus) keep an empty site pivot
## (`pivots`, keyed by site name); their map entries and details are skipped. To find a
## building itself use ModularTown.building(), which returns null for an absent unit.
func restore(scene) -> void:
    game=scene
    town=game.apartment
    data=JSON.parse_string(FileAccess.get_file_as_string("res://data/reference_layout.json"))
    var state: Dictionary=town.get_meta("baked_layout")
    spawn_point=state.spawn_point
    for key in state.sites:
        sites[key]=state.sites[key].duplicate()
        var pivot: Node3D=town.get_node_or_null("RelocatedSites/"+key)
        if pivot==null:
            pivot=Node3D.new()
            pivot.name=key
            # ModularTown.add_unit() replaces it when the unit arrives later (staged loading).
            pivot.set_meta("unit_placeholder",true)
            pivot.transform=sites[key].pose
            town.get_node("RelocatedSites").add_child(pivot)
        pivots[key]=pivot
    site_bounds=state.site_bounds.duplicate()
    for road in state.roads: roads.append(road)
    for saved in state.entries:
        var node: Node=town.get_node_or_null(saved.node)
        if node==null: continue
        var entry: Dictionary=saved.duplicate()
        entry.node=node
        entries.append(entry)
    for path in state.details:
        var node: Node=town.get_node_or_null(path)
        if node is Node3D: details.append(node)
    _blur_pick()
    town.set_meta("reference_map_sites",entries)
    town.set_meta("reference_map_details",details)

## A unit added after restore() (the app's staged loading, 13 Nov 2026): its site pivot,
## map entries and details join the layout, as restore() would have read them.
func add_unit() -> void:
    var state: Dictionary=town.get_meta("baked_layout")
    for key in sites:
        var pivot: Node3D=town.get_node_or_null("RelocatedSites/"+key)
        if pivot!=null: pivots[key]=pivot
    # Entries that pointed at a replaced stand-in pivot go; the unit's own nodes come back below.
    entries.assign(entries.filter(func(entry): return is_instance_valid(entry.node)))
    details.assign(details.filter(func(node): return is_instance_valid(node)))
    var known := {}
    for entry in entries: known[entry.node]=true
    for saved in state.entries:
        var node: Node=town.get_node_or_null(saved.node)
        if node==null or known.has(node): continue
        var entry: Dictionary=saved.duplicate()
        entry.node=node
        entries.append(entry)
    for path in state.details:
        var node: Node=town.get_node_or_null(path)
        if node is Node3D and not details.has(node): details.append(node)
    _blur_pick()
    town.set_meta("reference_map_sites",entries)
    town.set_meta("reference_map_details",details)

func _blur_pick() -> void:
    var blur: Node3D=ModularTown.building(town,"hospital",1,"HospitalHelipad/Helicopter/MainRotor/RotorMotionBlur")
    if blur: add_pick(blur)

## The layout as plain data for the base world's `baked_layout` meta (written by
## tools/bake_unit.gd when it saves the base, so base steps can change sites, roads and map
## entries). Nodes become town paths; restore() reads it back.
func bake_state() -> Dictionary:
    var state := {"spawn_point":spawn_point,"sites":{},"site_bounds":site_bounds.duplicate(),"roads":roads.duplicate(true),"entries":[],"details":[]}
    for key in sites: state.sites[key]=sites[key].duplicate()
    for entry in entries:
        if not is_instance_valid(entry.node): continue
        var saved: Dictionary=entry.duplicate()
        saved.node=town.get_path_to(entry.node)
        state.entries.append(saved)
    for node in details:
        if is_instance_valid(node): state.details.append(town.get_path_to(node))
    return state

## A pick area on each mesh of `n` that has no collision yet (the helicopter's rotor blur).
func add_pick(n: Node3D) -> void:
    var meshes: Array = [n] if n is MeshInstance3D else n.find_children("*","MeshInstance3D",true,false)
    for mesh in meshes:
        if mesh.mesh==null: continue
        if not mesh.find_children("*","CollisionObject3D",true,false).is_empty(): continue
        var area := Area3D.new()
        area.name = "VocabularyPick"
        area.monitoring = false
        area.monitorable = false
        var shape := CollisionShape3D.new()
        shape.shape = mesh.mesh.create_convex_shape()
        area.add_child(shape)
        mesh.add_child(area)

# Canonical reference coordinates use image-right as +X. From the home's +Z-facing
# entrance, west/left is world +X. Move whole sites without mirroring their interiors.
func world_point(point: Vector3) -> Vector3:
    return Vector3(-point.x,point.y,point.z) if town.get_meta("reference_west_positive_x",false) else point

func bounds(node: Node3D) -> AABB:
    var result := AABB()
    var first := true
    var meshes: Array = node.find_children("*","MeshInstance3D",true,false)
    if node is MeshInstance3D: meshes.append(node)
    for mesh in meshes:
        if mesh.mesh == null: continue
        var box: AABB = mesh.get_aabb()
        for i in range(8):
            var point: Vector3 = town.to_local(mesh.to_global(box.get_endpoint(i)))
            if first:
                result = AABB(point,Vector3.ZERO)
                first = false
            else: result = result.expand(point)
    if first: result = AABB(town.to_local(node.global_position),Vector3.ZERO)
    return result

func point2(point: Vector3) -> Vector2:
    return Vector2(point.x,point.z)

func site_at(point: Vector3) -> String:
    for key in site_bounds:
        var b: AABB=site_bounds[key]
        if Rect2(b.position.x-1,b.position.z-1,b.size.x+2,b.size.z+2).has_point(point2(point)): return key
    return ""

func location_name(point: Vector3, site: String) -> String:
    # The building may be absent (dev focus): its plot is still a site, so these may be null.
    var school: Node=ModularTown.building(town,"school",1)
    var hospital: Node=ModularTown.building(town,"hospital",1)
    if site=="School" and school!=null and school.get_meta("approved_dimensions",false):
        return "School"
    if site=="Hospital" and hospital!=null and hospital.get_meta("remodeled",false):
        if point.y>16.5: return "Hospital · Roof · Helipad"
        var floor_index := clampi(int((point.y+.1)/5.6),0,2)
        return "Hospital · Floor "+str(floor_index+1)+[" · Reception & Emergency"," · Patient Rooms, ICU & Surgery"," · Imaging, Laboratory & Therapy"][floor_index]
    if site in ["Hospital","School"]:
        return site+" · Floor "+str(clampi(int(point.y/5.4)+1,1,3))
    if site!="": return str(sites[site].label if sites.has(site) else site).capitalize()
    if town.get_meta("compact_layout",false):
        if Rect2(-104,73,199,119).has_point(point2(point)): return "Central Park"
        if point.z<10: return "South Beach"
        if point.x>157: return "West Beach"
        if point.x< -171: return "East Beach"
        return "Town roads"
    if point.z<0: return "South Beach"
    if point.x > 157: return "West Beach"
    if point.x < -171: return "East Beach"
    if point.z>230 and point.x< -43: return "Airport"
    if point.x< -123 and point.z<103: return "Restaurants"
    if point.x>-90 and point.x<90 and point.z>40 and point.z<220: return "Central Park"
    return "Town roads"
