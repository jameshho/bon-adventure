extends SceneTree
## Streets polish (28 Oct 2026): drives/walks off the road, whole streetlights, no
## loose parts, and the car climbing curbs. godot --headless --path . --script res://docs/evidence/streets-20261028/verify.gd
func _initialize(): run.call_deferred()
var failures:=0
func check(ok: bool,label: String):
    if not ok:
        failures+=1
        print("FAIL: ",label)
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var town: Node3D=game.apartment
    var road: Node3D=town.get_node("Curving neighborhood road")
    var pts: PackedVector3Array=road.get_meta("reference_road_points")
    var centre:=func(q: Vector2) -> float:
        var best:=INF
        for i in range(1,pts.size()): best=minf(best,q.distance_to(Geometry2D.get_closest_point_to_segment(q,Vector2(pts[i-1].x,pts[i-1].z),Vector2(pts[i].x,pts[i].z))))
        return best
    var lights:=0
    for n in town.get_children():
        var t:=String(n.name)
        if t.begins_with("Streetlight") and n.get_meta("word_key","")=="streetlight": lights+=1
        if n.get_meta("refined_driveway",false):
            var c: PackedVector3Array=n.get_meta("reference_road_points")
            check(centre.call(Vector2(c[0].x,c[0].z))>4.9,"drive starts at road edge: "+t+" "+str(snappedf(centre.call(Vector2(c[0].x,c[0].z)),.1)))
        if t.ends_with("entrance connection"):
            var v: PackedVector3Array=(n as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            var nearest:=INF
            for p in v: nearest=minf(nearest,centre.call(Vector2(p.x,p.z)))
            check(nearest>5.6,"walk stays off the road: "+t+" "+str(snappedf(nearest,.1)))
    print("streetlights ",lights," traffic ",town.get_node_or_null("Traffic light")!=null)
    check(lights>=10,"streetlights placed")
    for n in town.find_children("*","Node3D",true,false):
        var t:=String(n.name)
        check(not t.begins_with("Lamp banner"),"banner removed "+t)
        if t.begins_with("Streetlight") and n.get_parent()!=town and not String(n.get_parent().name).begins_with("Streetlight"): check(false,"loose streetlight part "+str(town.get_path_to(n)))
    game.set_process(false)
    game.player.set_physics_process(false)
    for vehicle in game.driveable_vehicles:
        vehicle.set_physics_process(false)
        vehicle.set_process(false)
    await physics_frame
    await physics_frame
    var car=town.get_node("Vehicles/Car")
    var results:=[]
    for spec in [[75,1.0],[110,-1.0],[30,1.0]]:
        var i: int=spec[0]
        var a: Vector3=pts[i]
        var t: Vector3=(pts[i+1]-pts[i-1]).normalized()
        var side: Vector3=Vector3(-t.z,0,t.x)*float(spec[1])
        # Car models face -X: point local -X along `side`.
        var basis:=Basis(Vector3.UP,atan2(-side.z,side.x)+PI).scaled(Vector3.ONE*1.3)
        car.global_transform=Transform3D(basis,town.to_global(a+side*1.5+Vector3(0,.5,0)))
        car.road_physics.reset()
        car.road_physics.has_parked_pose=false
        car.current_speed=0
        car.occupied=true
        for k in range(30): car.drive_step(1.0/60,0,0,1)
        var start: Vector3=town.to_local(car.global_position)
        for k in range(240): car.drive_step(1.0/60,1,0,0)
        var end: Vector3=town.to_local(car.global_position)
        var d:=Vector2(end.x-a.x,end.z-a.z).length()
        check(d>8.5,"car crosses the curb at "+str(i))
        results.append("curb idx "+str(i)+": from "+str(snappedf(Vector2(start.x-a.x,start.z-a.z).length(),.1))+" to "+str(snappedf(d,.1))+" off centre, y "+str(snappedf(end.y,.01))+", speed "+str(snappedf(car.current_speed,.1)))
    car.occupied=false
    for r in results: print("DRIVE ",r)
    print("STREETS failures: ",failures)
    quit(1 if failures>0 else 0)
