extends SceneTree
## Run in an isolated test copy (README); --capture also writes review PNGs.
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func bounds(n: Node3D) -> AABB:
    var box:=AABB()
    var first:=true
    for m in n.find_children("*","MeshInstance3D",true,false):
        if not m.is_visible_in_tree() or m.mesh==null: continue
        var b: AABB=n.global_transform.affine_inverse()*m.global_transform*m.get_aabb()
        box=b if first else box.merge(b)
        first=false
    return box
func run():
    root.size=Vector2i(1400,900)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.player.set_physics_process(false)
    game.hud.hide()
    var animals: Array=[]
    for n in game.apartment.find_children("*","Node3D",true,false):
        if n.scene_file_path.begins_with("res://scenes/animals/"):
            animals.append(n)
            n.set_process(false)
    for i in range(3): await physics_frame
    var bonbon=game.player.get_node("Visual/BonBon")
    var lh: float=bounds(bonbon).size.y*bonbon.global_basis.get_scale().y
    var report={"BonBon":{"height":lh},"animals":[]}
    for n in animals:
        var box:=bounds(n)
        var height: float=box.size.y*n.global_basis.get_scale().y
        check(height>=1.014-.00001,"Minimum height: "+str(n.get_path()))
        var area=n.get_node_or_null("VocabularyArea")
        check(area!=null,"Picking area: "+str(n.name))
        var shape: CollisionShape3D=area.get_child(0)
        check(shape.shape is BoxShape3D and shape.shape.size.distance_to(box.size)<.001,"Fitted picking: "+str(n.name))
        var target: Vector3=shape.global_position
        var ray:=PhysicsRayQueryParameters3D.create(target+Vector3(0,10,0),target)
        ray.collide_with_areas=true
        ray.collide_with_bodies=false
        var hit=game.get_world_3d().direct_space_state.intersect_ray(ray)
        check(not hit.is_empty() and hit.collider==area,"Ray picking: "+str(n.name))
        report.animals.append({"name":str(n.name),"path":str(n.get_path()),"height":height,"size":str(box.size*n.global_basis.get_scale()),"scale":str(n.scale),"relative_bonbon":height/lh})
    var movers:=get_nodes_in_group("wandering_animals")
    var excursions: Dictionary={}
    var states: Dictionary={}
    for n in movers: excursions[n]=0.0; states[n]={}
    var started:=Time.get_ticks_usec()
    # Two simulated minutes, 60 Hz, including real physics-space obstacle queries.
    for i in range(7200):
        for n in movers:
            n._process(1.0/60)
            check(n.inside(n.position),"Containment: "+str(n.name))
            var d:=Vector2(n.position.x-n.home.x,n.position.z-n.home.z).length()
            excursions[n]=maxf(excursions[n],d)
            states[n][n.state]=true
    report["movement_ms_per_frame"]=float(Time.get_ticks_usec()-started)/7200.0/1000.0
    report["movement"]=[]
    for n in movers:
        check(excursions[n]>.25,"Animal can roam: "+str(n.name))
        check(states[n].has("walking") and (states[n].has("idle") or states[n].has("resting")),"Walk and pause: "+str(n.name))
        check(not n.inside(n.home+Vector3(n.radius+1,0,0)),"Outside home radius rejected")
        report.movement.append({"name":str(n.name),"excursion":excursions[n],"states":states[n].keys(),"probes":n.probe_count})
    # Add a physical obstacle at one animal's proposed route; verify sweep rejection.
    var sample=movers[0]
    sample.position=sample.home
    var obstacle:=StaticBody3D.new()
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new()
    shape.size=Vector3(.3,4,4)
    collision.shape=shape
    obstacle.add_child(collision)
    root.add_child(obstacle)
    obstacle.global_position=sample.global_position+Vector3(sample.footprint*1.3+.15,1,0)
    await physics_frame
    await physics_frame
    check(not sample._clear_step(sample.position+Vector3(.5,0,0)),"Obstacle sweep rejects blocked route")
    obstacle.free()
    for n in movers:
        n.position=n.home
        n.rotation.y=0
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/animals-review")
    var file:=FileAccess.open("res://docs/evidence/animals-review/measurements.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("ANIMALS: ",animals.size()," measured, ",movers.size()," walkers; ",failures.size()," failures; mean movement/check ms/frame ",report.movement_ms_per_frame)
    if "--capture" in OS.get_cmdline_user_args():
        var camera:=Camera3D.new()
        game.apartment.add_child(camera)
        camera.current=true
        camera.fov=55
        for view in [["zoo",Vector3(-78,30,151),Vector3(-78,1,108)],["farm",Vector3(66,24,130),Vector3(66,1,92)]]:
            camera.position=view[1]
            camera.look_at(game.apartment.to_global(view[2]))
            game.player.global_position=game.apartment.to_global(view[2]+Vector3(0,0,7))
            for i in range(8): await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://docs/evidence/animals-review/"+view[0]+".png")
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        for enabled in [false,true,false,true]:
            for n in movers: n.set_process(enabled)
            for i in range(20): await process_frame
            var times: Array[float]=[]
            for i in range(90):
                var start:=Time.get_ticks_usec()
                await process_frame
                times.append(float(Time.get_ticks_usec()-start)/1000.0)
            times.sort()
            print("RENDER BENCH movement=",enabled," median_ms=",times[45]," p95_ms=",times[85])
    game.free()
    quit(0 if failures.is_empty() else 1)
