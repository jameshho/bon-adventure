extends Control
## Map text is in the native language: titles stay English lookup keys (places.*), translated
## when drawn (UI Stage 3).
const UiText := preload("res://scripts/language/ui_text.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
# Cached 2D projection of the actual town meshes. No second 3D render pass.
var full_map := false
var MAP_SIZE := Vector2(208,208)
var ZOOM := 2.4
var world: Node3D
var player: Node3D
var surfaces: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var label_rects: Array[Rect2] = []
var map_position := Vector2.ZERO
var map_yaw := 0.0
var elapsed := 0.0

## Called on a click or tap on the minimap (Main: open the full map; 10 Nov 2026).
var on_tap: Callable

## The minimap's side for a window of `view` px: 268 px at 1100 x 800, scaled like the other
## HUD parts (was a fixed 208 px; user, 10 Nov 2026: slightly bigger), never under 208.
static func side_for(view: Vector2) -> float:
    var f: float = BonStyle.factor(view)
    return roundf(clampf(268.0 * f, 208.0, 420.0))

func setup(town: Node3D, explorer: Node3D) -> void:
    world = town
    player = explorer
    name = "TownMinimap"
    position = Vector2(16,16)
    size = MAP_SIZE
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE if full_map else Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    rebuild()
    update_pose()

## Where the player is shown: the real warehouse while they play in its copy
## (warehouse_session.gd sets the player's "map_position").
func tracked_position() -> Vector3:
    return player.get_meta("map_position", player.global_position)

func point2(p: Vector3) -> Vector2:
    return Vector2(p.x,p.z)

func update_pose() -> void:
    if full_map:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        position=Vector2(30,60)
        size=get_viewport_rect().size-Vector2(60,120)
        MAP_SIZE=size
        ZOOM=minf(size.x/200.0,size.y/210.0)
        map_position=Vector2(0,75)
        if world.has_meta("reference_map_bounds"):
            var bounds: Rect2=world.get_meta("reference_map_bounds")
            ZOOM=minf((size.x-90)/bounds.size.x,(size.y-80)/bounds.size.y)
            map_position=bounds.get_center()
        map_yaw=0
        return
    var side := side_for(get_viewport_rect().size)
    if MAP_SIZE.x != side:
        MAP_SIZE = Vector2(side, side)
        size = MAP_SIZE
        ZOOM = 2.4 * side / 208.0
    map_position = point2(world.to_local(tracked_position()))
    var forward: Vector3 = world.global_basis.inverse() * -player.global_basis.z
    map_yaw = atan2(-forward.x,-forward.z)

func project(point: Vector2) -> Vector2:
    var offset := point-map_position
    if full_map:
        offset.y = -offset.y # Northern civic district is +Z.
        if world.get_meta("reference_west_positive_x",false): offset.x=-offset.x
    else: offset = offset.rotated(map_yaw)
    return MAP_SIZE * .5 + offset*ZOOM

func footprint(node: Node3D) -> PackedVector2Array:
    var low := Vector2(INF,INF)
    var high := Vector2(-INF,-INF)
    var meshes: Array = node.find_children("*","MeshInstance3D",true,false)
    if node is MeshInstance3D: meshes.append(node)
    for mesh in meshes:
        if not mesh.mesh: continue
        var bounds: AABB = mesh.get_aabb()
        for i in range(8):
            var point := point2(node.to_local(mesh.to_global(bounds.get_endpoint(i))))
            low = low.min(point)
            high = high.max(point)
    if not low.is_finite(): return PackedVector2Array()
    return PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])

# Call after structural mesh edits. Building transforms are read live, so relocating
# an existing building does not require a separate map-coordinate edit.
func rebuild() -> void:
    surfaces.clear()
    landmarks.clear()
    labels.clear()
    for node in world.find_children("*","MeshInstance3D",true,false):
        if not node.mesh: continue
        var label := str(node.name)
        var filled: bool = node.get_meta("map_kind","")=="fill" or label in ["Coastal shallows","Island beaches","Natural town terrain","Central Park meadow","Pond pebble shore","Park pond","Playground safety surface"]
        var ribbon: bool = node.get_meta("map_kind","")=="ribbon" or label.begins_with("Winding park path") or label.begins_with("Road center marking") or label in ["Curving neighborhood road","Loop road sidewalks","Shop promenade","Civic promenade","Bakery approach"]
        if not filled and not ribbon: continue
        var arrays: Array = node.mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var points := PackedVector2Array()
        var width := 1.0
        if ribbon and node.has_meta("map_ribbon_points"):
            # Swept meshes (raised sidewalks) publish their centerline instead of pairs.
            width = node.get_meta("map_ribbon_width")
            for p in node.get_meta("map_ribbon_points"): points.append(point2(world.to_local(node.to_global(p))))
        elif ribbon:
            width = vertices[0].distance_to(vertices[1])
            for i in range(0,vertices.size()-1,2):
                points.append(point2(world.to_local(node.to_global((vertices[i]+vertices[i+1])*.5))))
        else:
            for vertex in vertices: points.append(point2(world.to_local(node.to_global(vertex))))
        var color: Color = node.material_override.albedo_color if node.material_override is StandardMaterial3D else node.get_meta("map_color",Color("456c63"))
        var height := world.to_local(node.to_global(vertices[0])).y
        surfaces.append({"points":points,"fill":filled,"width":width,"color":color,"height":height})
    surfaces.sort_custom(func(a,b): return a.height<b.height)
    if world.has_meta("reference_map_sites"):
        for entry in world.get_meta("reference_map_sites"):
            if entry.get("label_only",false):
                var outline := footprint(entry.node)
                if not outline.is_empty(): labels.append({"text":entry.title,"node":entry.node,"center":(outline[0]+outline[2])*.5})
            else: add_landmark(entry.node,entry.color,entry.title)
        for node in world.get_meta("reference_map_details"):
            # Garden flowers, rail segments, and foliage are not map landmarks.
            if node.get_parent().name == "PublicGarden" and not node.has_meta("word_key") and not str(node.name).begins_with("Garden specimen") and not str(node.name).begins_with("Garden grove"):
                continue
            add_landmark(node,Color("c4a27a"))
        labels.append_array(world.get_meta("reference_map_labels"))
    else:
        # Paths and small structures were omitted by the old surface-only pass.
        for node in world.get_children():
            var title := str(node.name)
            if title.begins_with("Pond bridge plank") or title.begins_with("Pedestrian crossing") or title in ["Front path", "Driveway", "Beach access path", "Market walkway", "Library path", "Bank path", "Station front path", "Gazebo deck", "Gazebo roof", "Garage roof"]:
                add_landmark(node, Color("c4a27a") if title.begins_with("Pond bridge") else Color("e6d7b8"))
        # Each unit's second part is its building shell (data/buildings.json).
        var building_names := {
            "home":"HOME", "school":"SCHOOL", "hospital":"HOSPITAL",
            "clothing":"CLOTHING", "electronics":"ELECTRONICS",
            "sports":"SPORTS", "furniture":"FURNITURE", "bakery":"BAKERY / CAFE"
        }
        for key in building_names:
            var node := ModularTown.building(world, key, 1)
            if node: add_landmark(node, Color("f2dbc0"), building_names[key])
        for title in ["Supermarket", "Library", "Bank", "Police Station", "Chapel"]:
            var roof := world.get_node_or_null(title + " roof")
            if roof: add_landmark(roof, Color("d5dfba"), title.to_upper())
        var helipad := ModularTown.building(world, "hospital", 1, "HospitalHelipad/LandingDeck")
        if helipad: add_landmark(helipad, Color("759a94"), "HELIPAD")
        var zoo := world.get_node_or_null("ParkZoo")
        if zoo:
            for node in zoo.get_children():
                if str(node.name).ends_with(" lawn"):
                    add_landmark(node, Color("cab880"), "WILD ANIMALS" if str(node.name).contains("SALVAJES") else "FARM ANIMALS")
        for data in [["CENTRAL PARK",Vector2(0,51)], ["POND / BRIDGE",Vector2(19,68)], ["GAZEBO",Vector2(-15,72)], ["PLAYGROUND",Vector2(12,79)], ["SOUTH BEACH",Vector2(3,-16)], ["WEST BEACH",Vector2(-78,57)], ["EAST BEACH",Vector2(77,73)]]:
            labels.append({"text":data[0], "point":data[1]})
    queue_redraw()

func _process(delta: float) -> void:
    if not is_visible_in_tree() or not is_instance_valid(player) or not is_instance_valid(world): return
    elapsed += delta
    if elapsed < 1.0/30.0: return
    elapsed = 0
    var previous_position := map_position
    var previous_yaw := map_yaw
    var previous_size := size
    update_pose()
    var player_position := point2(world.to_local(tracked_position()))
    var player_yaw := player.rotation.y
    if previous_position.distance_squared_to(map_position) > 0.0001 or absf(previous_yaw-map_yaw) > 0.001 or previous_size != size or player_position.distance_squared_to(last_player_position) > 0.0001 or absf(player_yaw-last_player_yaw) > 0.001 or full_map != last_full_map:
        queue_redraw()
        last_player_position = player_position
        last_player_yaw = player_yaw
        last_full_map = full_map

var last_player_position := Vector2.INF
var last_player_yaw := INF
var last_full_map := false

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,MAP_SIZE),Color("4f9eae"))
    for surface in surfaces:
        var polygon := PackedVector2Array()
        for p in surface.points: polygon.append(project(p))
        if polygon.size() < (3 if surface.fill else 2): continue
        if not on_map(polygon, surface.width*ZOOM): continue
        if surface.fill: draw_colored_polygon(polygon,surface.color)
        else: draw_polyline(polygon,surface.color,surface.width*ZOOM,true)
    for landmark in landmarks:
        if not is_instance_valid(landmark.node): continue
        var polygon := PackedVector2Array()
        for p in landmark.points:
            polygon.append(project(point2(world.to_local(landmark.node.to_global(Vector3(p.x,0,p.y))))))
        if polygon.size()>2 and on_map(polygon, 2.0):
            draw_colored_polygon(polygon,landmark.color)
            polygon.append(polygon[0])
            draw_polyline(polygon,Color("566d69"),1.3,true)
    if full_map: draw_labels()
    var center := project(point2(world.to_local(tracked_position()))) if full_map else MAP_SIZE*.5
    var forward: Vector3 = world.global_basis.inverse() * -player.global_basis.z
    var heading := (project(point2(world.to_local(tracked_position()))+point2(forward))-center).normalized()
    var side := Vector2(-heading.y,heading.x)
    draw_circle(center,10,Color("203a48"))
    draw_colored_polygon(PackedVector2Array([center+heading*9,center-heading*7+side*6,center-heading*4,center-heading*7-side*6]),Color("fff8de"))
    if full_map:
        var font := ThemeDB.fallback_font
        draw_string(font,Vector2(18,26),UiText.t("map.title").to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("253f4c"))
        draw_string(font,Vector2(18,MAP_SIZE.y-16),UiText.t("map.legend"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("253f4c"))
        draw_string(font,Vector2(MAP_SIZE.x-42,27),UiText.t("map.north"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("253f4c"))
        draw_line(Vector2(MAP_SIZE.x-36,55),Vector2(MAP_SIZE.x-36,34),Color("253f4c"),2,true)
        draw_colored_polygon(PackedVector2Array([Vector2(MAP_SIZE.x-36,32),Vector2(MAP_SIZE.x-41,41),Vector2(MAP_SIZE.x-31,41)]),Color("253f4c"))
    draw_rect(Rect2(Vector2.ONE,MAP_SIZE-Vector2.ONE*2),Color("fff1d6"),false,2)

func on_map(polygon: PackedVector2Array, margin: float) -> bool:
    var bounds := Rect2(polygon[0],Vector2.ZERO)
    for point in polygon: bounds = bounds.expand(point)
    return bounds.grow(margin).intersects(Rect2(Vector2.ZERO,MAP_SIZE))

func add_landmark(node: Node3D, color: Color, title := "") -> void:
    var points := footprint(node)
    if points.is_empty(): return
    landmarks.append({"node":node,"points":points,"color":color})
    if title != "": labels.append({"text":title,"node":node,"center":(points[0]+points[2])*.5})

# Labels follow their structures and remain upright in the north-up atlas.
# Leader lines and a light backing keep neighboring shop names readable.
func draw_labels() -> void:
    var font := ThemeDB.fallback_font
    label_rects.clear()
    for label in labels:
        var anchor: Vector2 = label.get("point",Vector2.ZERO)
        if label.has("node"):
            if not is_instance_valid(label.node): continue
            var local: Vector2 = label.center
            anchor = point2(world.to_local(label.node.to_global(Vector3(local.x,0,local.y))))
        var location := project(anchor)
        var text := UiText.named("places", str(label.text)).to_upper()
        var text_size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
        var badge_size := text_size+Vector2(10,8)
        var badge := Rect2(location-badge_size*.5,badge_size)
        var best_score := INF
        var offsets: Array[Vector2] = []
        for y in range(-4,5):
            for x in range(-3,4): offsets.append(Vector2(x*60,y*24))
        for offset in offsets:
            var candidate := Rect2(location+offset-badge_size*.5,badge_size)
            candidate.position = candidate.position.clamp(Vector2(8,62),MAP_SIZE-badge_size-Vector2(8,42))
            var score: float = location.distance_to(candidate.get_center())
            for other in label_rects:
                if candidate.grow(3).intersects(other): score += 10000
            if score < best_score:
                best_score = score
                badge = candidate
        label_rects.append(badge)
        if location.distance_to(badge.get_center()) > 12:
            draw_line(location,badge.get_center(),Color("566d69"),1,true)
            draw_circle(location,2.5,Color("253f4c"))
        draw_style_box(label_style(),badge)
        draw_string(font,badge.position+Vector2(5,4+font.get_ascent(12)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("253f4c"))

var cached_label_style: StyleBoxFlat
func label_style() -> StyleBoxFlat:
    if cached_label_style == null:
        cached_label_style = StyleBoxFlat.new()
        cached_label_style.bg_color = Color("fff5deed")
        cached_label_style.set_corner_radius_all(3)
    return cached_label_style

func _gui_input(event: InputEvent) -> void:
    if full_map or not on_tap.is_valid():
        return
    var released: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) \
            or (event is InputEventScreenTouch and not event.pressed)
    if released:
        accept_event()
        on_tap.call()
