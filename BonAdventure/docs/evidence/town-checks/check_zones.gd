extends SceneTree
## Use an isolated project/user directory. Does not study words or save progress.
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures += 1
        print("FAIL: ",message)
func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var zones = game.zones
    check(not zones.overlay_enabled and zones.walls.get_child_count()==0,"off by default; lazy geometry")
    # 5 Nov 2026: the warehouse zone (between the moved school and the airport) makes 26.
    check(zones.zones.size()==26,"26 named zones")
    for spec in [["farm",Vector3(66,0,80)],["zoo",Vector3(-78,0,105)],["playground",Vector3(62,0,178)],["church",Vector3(-79,0,175)],["gazebo",Vector3(-95,0,151)],["central_park",Vector3(0,0,140)],["town_road",Vector3(0,0,65)],["coast",Vector3(175,0,170)],["fine_dining",Vector3(-37,0,34)],["burger",Vector3(-88,0,34)],["taqueria",Vector3(-61,0,34)],["police",Vector3(-140,0,80)],["airport",Vector3(-165,0,200)],["control_tower",Vector3(-71,0,249)],["warehouse",Vector3(-35,0,235)],["school",Vector3(10,0,230)]]:
        check(zones.resolve_local(spec[1])==spec[0],"sample "+spec[0])
    for id in ["farm","zoo","playground","church","gazebo"]:
        var p=zones.by_id[id].label
        check(not zones.contains(Vector2(p[0],p[1]),zones.by_id.central_park),"explicit park cutout "+id)
    for y in [-2,0,6,12,20,1000]:
        check(zones.resolve_local(Vector3(56,y,240))=="hospital","hospital all heights "+str(y))
    for x in [41.99,42.01,89.99,90.01]:
        check(zones.resolve_local(Vector3(x,0,95))==("farm" if x>42 and x<90 else "central_park"),"farm edge "+str(x))
    for spec in [["Buildings/Hospital","hospital"],["Buildings/School","school"],["Buildings/FurnitureStore","furniture"],["Buildings/SportsStore","sports"],["Buildings/BakeryCafe","bakery"],["Buildings/ElectronicsStore","electronics"],["Buildings/ClothingStore","clothing"],["RelocatedSites/Library","library"],["RelocatedSites/Supermarket","supermarket"],["RelocatedSites/Bank","bank"],["RelocatedSites/Police","police"],["Restaurants/Pizza","fine_dining"],["Restaurants/Burger","burger"],["Restaurants/Cafe","taqueria"]]:
        var bounds: AABB=game.reference_layout.bounds(game.apartment.get_node(spec[0]))
        for i in range(8): check(zones.resolve_local(bounds.get_endpoint(i))==spec[1],"building envelope "+spec[0]+" corner "+str(i))
    for x in range(-200,201,5):
        for z in range(0,301,5):
            check(zones.by_id.has(zones.resolve_local(Vector3(x,0,z))),"total resolution")
    await physics_frame
    var before: int = game.find_children("*","CollisionObject3D",true,false).size()
    var query := PhysicsRayQueryParameters3D.create(game.apartment.to_global(Vector3(42,30,95)),game.apartment.to_global(Vector3(42,-3,95)))
    var hit_before: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
    var event := InputEventKey.new()
    event.physical_keycode=KEY_B
    event.pressed=true
    zones._unhandled_input(event)
    check(zones.overlay_enabled,"B enables walls")
    check(zones.walls.find_children("*","CollisionObject3D",true,false).is_empty(),"no collision bodies or picking areas")
    check(before==game.find_children("*","CollisionObject3D",true,false).size(),"physics inventory unchanged")
    var hit_after: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
    check(hit_before.get("rid")==hit_after.get("rid"),"same ray target with walls enabled")
    event.echo=true
    zones._unhandled_input(event)
    check(zones.overlay_enabled,"key repeat ignored")
    event.echo=false
    zones._unhandled_input(event)
    check(not zones.overlay_enabled,"B disables walls")
    var original := InputMap.action_get_events("toggle_zone_walls")
    InputMap.action_erase_events("toggle_zone_walls")
    var remap := InputEventKey.new()
    remap.physical_keycode=KEY_V
    InputMap.action_add_event("toggle_zone_walls",remap)
    zones._unhandled_input(event)
    check(not zones.overlay_enabled,"old binding ignored after remap")
    remap.pressed=true
    zones._unhandled_input(remap)
    check(zones.overlay_enabled,"remapped action works")
    InputMap.action_erase_events("toggle_zone_walls")
    for old in original: InputMap.action_add_event("toggle_zone_walls",old)
    zones.set_overlay(false)
    print("ZONES: ",checks," checks; ",failures," failures")
    quit(1 if failures else 0)
