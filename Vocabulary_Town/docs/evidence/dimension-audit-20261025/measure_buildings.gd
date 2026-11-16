extends SceneTree
func _initialize(): run.call_deferred()
func vec(v: Vector3): return [snappedf(v.x,.001),snappedf(v.y,.001),snappedf(v.z,.001)]
func box(a: AABB): return {"min":vec(a.position),"size":vec(a.size)}
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    var town=game.apartment
    var result={"player_scale":vec(game.player.global_basis.get_scale()),"player_capsule_radius":game.player.get_node("PlayerCollision").shape.radius,"player_capsule_height":game.player.get_node("PlayerCollision").shape.height,"buildings":[],"surroundings":[]}
    for facade in town.get_node("Map facades").get_children():
        var source=str(facade.get_meta("source_building",""))
        if source=="":
            if facade.name=="HOME": source="RelocatedSites/Home"
            else: continue
        var b=town.get_node(source)
        var frame: Transform3D=Transform3D(facade.basis.orthonormalized(),Vector3.ZERO)
        var item={"name":str(facade.name),"path":source,"basis_x":vec(frame.basis.x),"basis_z":vec(frame.basis.z),"bounds":box(game.reference_layout.bounds(b)),"architecture":[],"props":[]}
        var seen={}
        for node in b.find_children("*","Node3D",true,false):
            if node is MeshInstance3D and node.mesh:
                var title=(str(node.name)+" "+str(node.get_parent().name)).to_lower()
                if ["wall","floor","slab","roof","foundation","ceiling","pier","partition","header","lintel","left","right","rear","front","side"].any(func(w): return w in title):
                    var a: AABB=frame.affine_inverse()*town.global_transform.affine_inverse()*node.global_transform*node.get_aabb()
                    if a.size.x*a.size.z>4 or a.size.y>2:
                        item.architecture.append({"path":str(b.get_path_to(node)),"frame_bounds":box(a),"town_bounds":box(town.global_transform.affine_inverse()*node.global_transform*node.get_aabb())})
            if node.has_meta("word_key"):
                var key=str(node.get_meta("word_key"))
                if not seen.has(key):
                    seen[key]=true
                    item.props.append({"key":key,"bounds":box(game.reference_layout.bounds(node))})
        result.buildings.append(item)
    for node in town.get_children():
        var title=str(node.name).to_lower()
        if ["parking","drive","coast","road","sidewalk","runway","taxiway"].any(func(w): return w in title) and node is Node3D:
            result.surroundings.append({"name":str(node.name),"bounds":box(game.reference_layout.bounds(node))})
    for path in ["Airport","Barn","ParkZoo","PublicGarden","RelocatedSites/Home","RelocatedSites/Gazebo","RelocatedSites/Playground"]:
        result.surroundings.append({"name":path,"bounds":box(game.reference_layout.bounds(town.get_node(path)))})
    result["special_objects"]=[]
    for node in town.find_children("*","Node3D",true,false):
        if str(node.name)=="HospitalBed" or str(node.name) in ["Turboprop","Helicopter"]:
            result.special_objects.append({"path":str(node.get_path()),"bounds":box(game.reference_layout.bounds(node))})
    result["player_visual_bounds"]=box(game.reference_layout.bounds(game.player.get_node("Visual")))
    result["ground_samples"]=[]
    await physics_frame
    await physics_frame
    for x in [-159.0,-133.0,125.3,143.3,-12.0,12.0]:
        var zs=[113.0,126.0,139.0] if x< -100 else ([130.0,137.0,144.0] if x>100 else [221.0,239.0])
        for z in zs:
            var q=PhysicsRayQueryParameters3D.create(town.to_global(Vector3(x,40,z)),town.to_global(Vector3(x,-5,z)))
            var hit=game.get_world_3d().direct_space_state.intersect_ray(q)
            result.ground_samples.append({"x":x,"z":z,"hit":str(hit.collider.get_path()) if hit else "NONE","height_world":hit.position.y if hit else -999})
    var f=FileAccess.open("res://docs/evidence/dimension-audit-20261025/building-measurements.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(result,"  "))
    print("MEASURED ",result.buildings.size()," buildings; player scale ",result.player_scale)
    quit()
