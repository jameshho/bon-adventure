extends Node3D
## Inspection only: no physics, learning, quest, or save ownership.
const DATA_PATH := "res://data/zones.json"
var zones: Array = []
var by_id: Dictionary = {}
var town: Node3D
var player: Node3D
var walls: Node3D
var status: Label
signal overlay_changed(enabled: bool)
var overlay_enabled := false
var wall_base := -0.15
var wall_height := 5.0

func setup(world: Node3D, explorer: Node3D) -> void:
    town = world
    player = explorer
    name = "TownZones"
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    wall_base = data.wall_base
    wall_height = data.wall_height
    for source in data.zones:
        var zone: Dictionary = source.duplicate(true)
        var polygons: Array[PackedVector2Array] = []
        for points in source.polygons:
            var polygon := PackedVector2Array()
            for p in points: polygon.append(Vector2(p[0],p[1]))
            polygons.append(polygon)
        zone.order = zones.size()
        zone.polygons = polygons
        zones.append(zone)
        by_id[zone.id] = zone
    # Stable file order breaks equal-priority ties, including shared edges.
    zones.sort_custom(func(a,b): return a.priority > b.priority if a.priority != b.priority else a.order < b.order)
    walls = Node3D.new()
    walls.name = "ZoneWalls"
    add_child(walls)
    var canvas := CanvasLayer.new()
    canvas.layer = 20
    add_child(canvas)
    status = Label.new()
    status.position = Vector2(240,12)
    status.add_theme_font_size_override("font_size",22)
    status.add_theme_color_override("font_shadow_color",Color.BLACK)
    status.add_theme_constant_override("shadow_offset_x",2)
    status.add_theme_constant_override("shadow_offset_y",2)
    status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(status)
    set_overlay(false)

func inside_outline(point: Vector2, zone: Dictionary) -> bool:
    for polygon in zone.polygons:
        if Geometry2D.is_point_in_polygon(point,polygon): return true
    return false

func contains(point: Vector2, zone: Dictionary) -> bool:
    if not zone.get("fallback",false) and not inside_outline(point,zone): return false
    for excluded in zone.exclude:
        # Exclusions are raw footprints, deliberately independent of priority.
        if inside_outline(point,by_id[excluded]): return false
    return true

func resolve_local(point: Vector3) -> String:
    var flat := Vector2(point.x,point.z)
    for zone in zones:
        if contains(flat,zone): return zone.id
    # Flying/swimming beyond the island still has exactly one resolved zone.
    return "coast"

func resolve_global(point: Vector3) -> String:
    return resolve_local(town.to_local(point))

func set_overlay(enabled: bool) -> void:
    overlay_enabled = enabled
    overlay_changed.emit(enabled)
    if enabled and walls.get_child_count() == 0: build_walls()
    walls.visible = enabled
    status.visible = enabled
    set_process(enabled)
    if enabled: _process(0)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_zone_walls") and not event.is_echo():
        set_overlay(not overlay_enabled)
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    var id := resolve_global(player.global_position)
    var binding := "Zone walls"
    var events := InputMap.action_get_events("toggle_zone_walls")
    if not events.is_empty(): binding = events[0].as_text()
    status.text = preload("res://scripts/language/ui_text.gd").t("hud.zone_status", {"zone": preload("res://scripts/language/ui_text.gd").named("places", str(by_id[id].name)), "key": binding})
    status.modulate = Color(by_id[id].color)

func build_walls() -> void:
    for zone in zones:
        var mesh := ImmediateMesh.new()
        var count := 0
        for polygon in zone.polygons:
            for i in range(polygon.size()):
                var a: Vector2 = polygon[i]
                var b: Vector2 = polygon[(i+1)%polygon.size()]
                var steps := maxi(1,ceili(a.distance_to(b)/0.5))
                var normal := (b-a).normalized().orthogonal()*0.03
                for j in range(steps):
                    var start := a.lerp(b,float(j)/steps)
                    var end := a.lerp(b,float(j+1)/steps)
                    var mid := (start+end)*0.5
                    var left := resolve_local(Vector3(mid.x+normal.x,0,mid.y+normal.y))
                    var right := resolve_local(Vector3(mid.x-normal.x,0,mid.y-normal.y))
                    # Hide internal polygon joins and boundaries buried by higher priorities.
                    if left == right or (left != zone.id and right != zone.id): continue
                    if count == 0: mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
                    var v0 := Vector3(start.x,wall_base,start.y)
                    var v1 := Vector3(end.x,wall_base,end.y)
                    var up := Vector3.UP*wall_height
                    for v in [v0,v1,v1+up,v0,v1+up,v0+up]: mesh.surface_add_vertex(v)
                    # A narrow horizontal cap keeps the boundary visible from above.
                    var side := Vector3(normal.x,0,normal.y)*5.0
                    for v in [v0+up-side,v1+up-side,v1+up+side,v0+up-side,v1+up+side,v0+up+side]: mesh.surface_add_vertex(v)
                    count += 1
        if count > 0:
            mesh.surface_end()
            var instance := MeshInstance3D.new()
            instance.name = zone.id+" boundary"
            instance.mesh = mesh
            instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            var material := StandardMaterial3D.new()
            material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            material.disable_fog = true
            material.cull_mode = BaseMaterial3D.CULL_DISABLED
            material.albedo_color = Color(zone.color,0.38)
            instance.material_override = material
            walls.add_child(instance)
        var label := Label3D.new()
        label.name = zone.id+" label"
        label.text = zone.get("display_label",zone.name)
        label.position = Vector3(zone.label[0],wall_base+wall_height+1,zone.label[1])
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.font_size = 48
        label.pixel_size = 0.025
        label.modulate = Color(zone.color)
        label.outline_modulate = Color("152030")
        label.outline_size = 12
        label.no_depth_test = true
        walls.add_child(label)
