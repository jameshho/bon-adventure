extends SceneTree
var failures:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String) -> void:
    if not ok:
        failures+=1
        print("FAIL: ",message)
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    var town: Node3D=game.apartment
    var facades: Node3D=town.get_node("Map facades")
    # 19 since the control tower revision (user, 29 Oct 2026: discreet entrance, no sign) removed its front.
    check(facades.get_child_count()==19,"seventeen building fronts plus home and gazebo")
    # Only the approved Alta Cocina terrace (bistro tables under FINE DINING) may be solid, plus
    # the roof and canopy collision (RoofSolid, 7 Nov 2026, scripts/buildings/roof_solids.gd),
    # which must stay above head height (2.4 m) so doors and streets keep their clearance.
    var roof_solids: Array=facades.find_children("RoofSolid","StaticBody3D",true,false)
    var solid: Array=facades.find_children("*","StaticBody3D",true,false).filter(func(body): return not str(facades.get_path_to(body)).begins_with("FINE DINING/") and not roof_solids.has(body))
    check(solid.is_empty(),"facade additions leave physical door and street clearances unchanged %s"%[solid.map(func(body): return str(facades.get_path_to(body)))])
    var low: Array=[]
    for body in roof_solids:
        for shape in body.find_children("*","CollisionShape3D",false,false):
            var box: AABB=town.global_transform.affine_inverse()*shape.global_transform*shape.shape.get_debug_mesh().get_aabb()
            if box.position.y<2.4: low.append("%s %.2f"%[facades.get_path_to(body),box.position.y])
    check(not roof_solids.is_empty() and low.is_empty(),"roof and canopy collision stays above head height %s"%[low])
    await physics_frame
    await physics_frame
    var picked:=0
    for front in facades.get_children():
        if not front.has_meta("exterior_word"): continue
        var bounds: AABB=front.get_meta("facade_bounds")
        var aim:=Vector3(bounds.get_center().x+bounds.size.x*.29,2.1,bounds.position.z-.25)
        # facade_bounds is authored before compact placement; the facade carries
        # that final transform. Town alone would probe the old site/orientation.
        var query:=PhysicsRayQueryParameters3D.create(front.to_global(aim+Vector3(0,0,-4)),front.to_global(aim+Vector3(0,0,1)))
        query.collide_with_areas=true
        var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
        # The game picks the first ancestor with exterior_word (interaction_controller.gd aimed_object()),
        # so a building's own exterior pick body showing the same word counts (7 Nov 2026).
        var shown := ""
        var surface: Node=hit.collider if not hit.is_empty() else null
        while surface!=null and surface!=town:
            if surface.has_meta("exterior_word"): shown=str(surface.get_meta("exterior_word")); break
            surface=surface.get_parent()
        var picked_front: bool=not hit.is_empty() and (front.is_ancestor_of(hit.collider) or shown==str(front.get_meta("exterior_word")))
        check(picked_front,"street ray picks new facade "+front.name)
        if not picked_front:
            print("  ",front.name," ray hit: ",town.get_path_to(hit.collider) if not hit.is_empty() else "nothing")
        check(game.vocabulary.has(front.get_meta("exterior_word")),"canonical exterior word "+front.name)
        picked+=1
    # The minimap is hidden since 14 Nov 2026 (Features.MINIMAP; README "Hidden features").
    if preload("res://scripts/core/features.gd").MINIMAP:
        var map=game.hud.ui_root.get_node_or_null("TownMinimap")
        check(map!=null,"minimap found")
        if map!=null:
            map.rebuild()
            check(not map.surfaces.is_empty(),"minimap rebuild")
    print("MAP FACADES: ",failures," failures; ",facades.get_child_count()," building fronts; ",picked," vocabulary facade rays")
    quit(0 if failures==0 else 1)
