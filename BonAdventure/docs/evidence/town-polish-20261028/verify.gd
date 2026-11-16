extends SceneTree
## Sunken home pool, raised loop-road sidewalks and the taquería (28 Oct 2026).
## godot --headless --path . --script res://docs/evidence/town-polish-20261028/verify.gd
var failures:=0
var game
func _initialize(): run.call_deferred()
func check(ok: bool,label: String):
    if not ok:
        failures+=1
        print("FAIL: ",label)
func walk(from: Vector3,to: Vector3,frames: int) -> Dictionary:
    # Holds W with the camera yawed toward the target; returns end pose and peak height.
    var p=game.player
    var town: Node3D=game.apartment
    p.global_position=town.to_global(from)
    p.velocity=Vector3.ZERO
    var dir: Vector3=town.to_global(to)-town.to_global(from)
    var yaw:=atan2(-dir.x,-dir.z)
    p.camera_rig.rotation.y=yaw
    p.camera_yaw=yaw
    var key:=InputEventKey.new()
    key.physical_keycode=KEY_W
    key.keycode=KEY_W
    key.pressed=true
    Input.parse_input_event(key)
    var top:=-INF
    for i in range(frames):
        await physics_frame
        top=maxf(top,town.to_local(p.global_position).y)
    key.pressed=false
    Input.parse_input_event(key)
    for i in range(5): await physics_frame
    return {"end":town.to_local(p.global_position),"top":top}
func run():
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var town: Node3D=game.apartment
    var home: Node3D=town.get_node("RelocatedSites/Home")
    await physics_frame
    await physics_frame
    var space=game.player.get_world_3d().direct_space_state
    # Pool: basin floor under the opening, solid terrace ground beside it.
    for spec in [[-8.0,-1.75],[-4.0,-1.75],[0.0,-1.35],[4.0,-.95]]:
        var top: Vector3=home.to_global(Vector3(spec[0],3,-12.8))
        var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(top,top-Vector3(0,10,0)))
        check(not hit.is_empty() and hit.collider.get_parent().name=="Pool basin","pool floor below x="+str(spec[0]))
        if not hit.is_empty(): check(absf(home.to_local(hit.position).y-spec[1])<.06,"pool depth at x="+str(spec[0]))
    var beside: Vector3=home.to_global(Vector3(-1,3,-6))
    var ground=space.intersect_ray(PhysicsRayQueryParameters3D.create(beside,beside-Vector3(0,10,0)))
    check(not ground.is_empty() and String(ground.collider.get_parent().name)=="Natural town terrain","terrace ground stays solid")
    var terrain: MeshInstance3D=town.get_node("Natural town terrain")
    check(terrain.mesh.get_surface_count()==2,"terrain opening is a second surface; minimap outline untouched")
    check(home.get_node("Swimming pool").get_meta("word_key","")=="swimming pool","pool word")
    var out: Dictionary=await walk(town.to_local(home.to_global(Vector3(-6,-1.6,-11))),town.to_local(home.to_global(Vector3(12,0,-11))),600)
    var end: Vector3=home.to_local(town.to_global(out.end))
    check(end.x>7.2 and end.y>-.1,"walks up the pool steps and out")
    # Sidewalks: step from the road onto the curb and onto the lawn, and back.
    check(town.get_node_or_null("Loop road curbs")!=null,"curbs exist")
    var sidewalks: MeshInstance3D=town.get_node("Loop road sidewalks")
    check(sidewalks.find_children("*","StaticBody3D",false,false).size()==1,"sidewalk collision")
    var points: PackedVector3Array=town.get_node("Curving neighborhood road").get_meta("reference_road_points")
    for idx in [12,75,110]:
        var a: Vector3=points[idx]
        var t: Vector3=(points[idx+1]-points[idx-1]).normalized()
        var side:=Vector3(-t.z,0,t.x)
        for s in [-1.0,1.0]:
            var off: Dictionary=await walk(a+Vector3(0,.3,0),a+side*s*14+Vector3(0,.3,0),150)
            check(Vector2(off.end.x-a.x,off.end.z-a.z).length()>9.0,"road to lawn at "+str(idx)+"/"+str(s))
            check(off.top>.15,"stands on the raised sidewalk at "+str(idx)+"/"+str(s))
            var on: Dictionary=await walk(a+side*s*11+Vector3(0,.3,0),a+Vector3(0,.3,0),150)
            check(Vector2(on.end.x-a.x,on.end.z-a.z).length()<3.0,"lawn to road at "+str(idx)+"/"+str(s))
    # Taquería: every new restaurant word is placed and known to the dictionaries.
    var room: Node3D=town.get_node_or_null("Restaurants/Cafe/Taqueria")
    check(room!=null,"taqueria built")
    var found:={}
    if room:
        for n in room.find_children("*","Node3D",true,false):
            var w:=str(n.get_meta("word_key",""))
            if w!="": found[w]=true
    for w in ["restaurant","waiter","taco","tortilla","burrito","quesadilla","nachos","guacamole","salsa","avocado","lime","beans","corn","chili pepper","onion","cactus","piñata","tablecloth","swimming pool"]:
        check(game.vocabulary.has(w) and game.vocabulary_categories.has(w),"dictionaries have "+w)
        if not w in ["restaurant","swimming pool"]: check(found.has(w),"taqueria places "+w)
    for w in found: check(game.vocabulary.has(w),"known key "+w)
    var facade=town.get_node_or_null("Map facades/TAQUERÍA")
    check(facade!=null and facade.get_meta("exterior_word","")=="restaurant","TAQUERÍA facade teaches restaurant")
    print("TOWN POLISH failures: ",failures)
    quit(1 if failures>0 else 0)
