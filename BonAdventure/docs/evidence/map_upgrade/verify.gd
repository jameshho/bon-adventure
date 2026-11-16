extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
    print("PASS " if ok else "FAIL ",message)
    if not ok: failures.append(message)
func _initialize(): run.call_deferred()
func run():
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for v in game.driveable_vehicles: v.set_physics_process(false)
    var atlas=game.hud.map_overlay.get_node("TownMinimap")
    var titles: Array = atlas.labels.map(func(label): return label.text)
    for title in ["HOME","SCHOOL","HOSPITAL","HELIPAD","CLOTHING","ELECTRONICS","SPORTS","FURNITURE","BAKERY / CAFE","SUPERMARKET","LIBRARY","BANK","POLICE STATION","CHAPEL","WILD ANIMALS","FARM ANIMALS","CENTRAL PARK","POND / BRIDGE","GAZEBO","PLAYGROUND","SOUTH BEACH","WEST BEACH","EAST BEACH"]:
        check(titles.has(title),"Map labels "+title)
    check(atlas.project(Vector2(0,150)).y < atlas.project(Vector2(0,0)).y,"Northern district is at the top")
    var library=game.apartment.get_node("Library roof")
    var label=atlas.labels.filter(func(item): return item.text=="LIBRARY")[0]
    check(label.node==library,"Building labels use actual scene nodes")
    var land=game.apartment.get_node("Natural town terrain")
    var land_vertices: PackedVector3Array=land.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    check(atlas.surfaces.any(func(item): return item.fill and item.points.size()==land_vertices.size()),"Coastline preserves every mesh outline vertex")
    check(atlas.landmarks.any(func(item): return str(item.node.name).begins_with("Pond bridge plank")),"Bridge structure is drawn")
    check(atlas.landmarks.any(func(item): return item.node.name=="Gazebo roof"),"Gazebo structure is drawn")
    var landmark_count: int=atlas.landmarks.size()
    atlas.rebuild()
    check(atlas.landmarks.size()==landmark_count,"Map rebuild does not duplicate structures")
    var cloud_count=0
    var low_cloud_sign=false
    for node in game.apartment.get_children():
        if str(node.name).begins_with("Cloud puff"):
            cloud_count+=1
            check(node.position.y>20,"Cloud remains in sky: "+str(node.name))
        if node is Label3D and node.text.begins_with("CLOUD WALK"): low_cloud_sign=true
    check(not low_cloud_sign,"Low cloud sign removed")
    check(cloud_count==20,"Five low cloud puffs removed; twenty sky puffs retained")
    check(not titles.has("LOW CLOUD"),"Low cloud map label removed")
    game.hud.toggle_map()
    check(game.hud.is_map_open() and not game.hud.quest_panel.visible,"Opening the map hides the quest panel")
    if DisplayServer.get_name()!="headless":
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var normal_overlaps := 0
        for i in range(atlas.label_rects.size()):
            for j in range(i):
                if atlas.label_rects[i].intersects(atlas.label_rects[j]): normal_overlaps += 1
        check(normal_overlaps==0,"Normal map labels do not overlap")
        root.get_texture().get_image().save_png("res://docs/evidence/map_upgrade/full_map.png")
        root.size=Vector2i(900,700)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var overlapping := 0
        for i in range(atlas.label_rects.size()):
            for j in range(i):
                if atlas.label_rects[i].intersects(atlas.label_rects[j]): overlapping += 1
        check(overlapping==0,"Compact map labels do not overlap")
        root.get_texture().get_image().save_png("res://docs/evidence/map_upgrade/full_map_compact.png")
    print("MAP UPGRADE: ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
