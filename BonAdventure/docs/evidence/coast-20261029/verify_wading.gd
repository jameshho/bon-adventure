extends SceneTree
## 30 Oct 2026: wading seabed off the beaches. Run with the README's isolated user directory:
## godot --headless --path <isolated project> --fixed-fps 60 --script res://docs/evidence/coast-20261029/verify_wading.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var town: Node3D=game.apartment
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var coast: Node3D=town.get_node("Coast")
    check(coast.get_node_or_null("Coastal seabed")!=null,"seabed body exists")
    var land: PackedVector3Array=coast.get_meta("shore_land")
    var sand: PackedVector3Array=coast.get_meta("shore_sand_edge")
    var shallow: PackedVector3Array=coast.get_meta("shore_shallow_edge")
    var n:=mini(land.size(),mini(sand.size(),shallow.size()))
    var tested:=0
    var worst_slope:=0.0
    var worst_step:=0.0
    var deepest_walk:=0.0
    var min_walkable_gap:=999.0
    for i in range(0,n,maxi(1,n/24)):
        var dir:=Vector3(shallow[i].x-land[i].x,0,shallow[i].z-land[i].z).normalized()
        var p0:=Vector3(land[i].x,0,land[i].z)
        var span:=Vector2(shallow[i].x-land[i].x,shallow[i].z-land[i].z).length()
        var prev:=NAN
        var last_ground:=-99.0
        var d:=span-8.0
        var found_edge_end:=-1.0
        while d<=span+14.0:
            var q:=p0+dir*d
            var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(town.to_global(Vector3(q.x,3,q.z)),town.to_global(Vector3(q.x,-12,q.z))))
            if hit.is_empty():
                if found_edge_end<0.0: found_edge_end=d
                prev=NAN
            else:
                var y: float=town.to_local(hit.position).y
                if not is_nan(prev):
                    var dy:=absf(y-prev)
                    worst_step=maxf(worst_step,dy)
                    if y<-3.0 or prev<-3.0: pass
                    worst_slope=maxf(worst_slope,rad_to_deg(atan(dy/.25)))
                prev=y
                last_ground=d
                if y>-1.8: deepest_walk=minf(deepest_walk,y)
            d+=.25
        tested+=1
        check(last_ground>span+6.0,"shore %d: seabed reaches %.1f m beyond the shallow edge"%[i,last_ground-span])
        check(last_ground<span+13.5,"shore %d: seabed ends (%.1f m beyond edge)"%[i,last_ground-span])
    print("tested ",tested," shore points; max sampled slope %.1f deg, max step %.2f m, deepest wade %.2f"%[worst_slope,worst_step,deepest_walk])
    check(worst_step<1.2,"no abrupt height change before the drop-off (%.2f)"%worst_step)
    check(deepest_walk>-1.8,"wading depth stays shallow (%.2f)"%deepest_walk)
    print("WADING VERIFY: ",checks," checks, ",failures," failures")
    quit(1 if failures>0 else 0)
