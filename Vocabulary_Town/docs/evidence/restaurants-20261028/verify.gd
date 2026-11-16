extends SceneTree
## 28 Oct 2026: police station moved south of the supermarket; fine dining and Pizza and Burger.
## Run with the README's isolated user directory (Main saves progress).
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func words_under(node: Node) -> Dictionary:
    var found:={}
    for n in node.find_children("*","Node3D",true,false):
        if n.has_meta("word_key"): found[String(n.get_meta("word_key"))]=found.get(String(n.get_meta("word_key")),0)+1
    return found
func clear_at(game,space: PhysicsDirectSpaceState3D,point: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,game.apartment.to_global(point+Vector3(0,.95,0)))
    return space.intersect_shape(query,1).is_empty()
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    var layout=game.reference_layout
    await physics_frame
    await physics_frame
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    # --- police station
    var police: Node3D=town.get_node("RelocatedSites/Police")
    var pb: AABB=layout.bounds(police)
    var market: AABB=layout.bounds(town.get_node("RelocatedSites/Supermarket"))
    # The 28 Oct police interior adds one `Interior` node; the 144 original children remain.
    check(police.get_children().filter(func(c): return c.name!="Interior").size()==144,"police interior/exterior children preserved (144)")
    check(pb.get_center().x<-135 and pb.get_center().x>-160 and pb.get_center().z>70 and pb.get_center().z<95,"police is on the east side south of the supermarket")
    check(not Rect2(pb.position.x,pb.position.z,pb.size.x,pb.size.z).intersects(Rect2(market.position.x,market.position.z,market.size.x,market.size.z)),"police does not overlap supermarket")
    check(pb.end.x<-120.3 and pb.position.z>73 and pb.end.z<101,"police clear of the loop sidewalk and supermarket lot")
    var car: Node3D=town.get_node("Vehicles/Police_Car")
    var pad: AABB=layout.bounds(town.get_node("Police parking"))
    check(Rect2(pad.position.x,pad.position.z,pad.size.x,pad.size.z).grow(.5).has_point(Vector2(car.position.x,car.position.z)),"police car parks on the police pad")
    check(pad.end.x>-122 and pad.end.x<-119,"police pad meets the east sidewalk")
    check(town.has_node("Police entrance connection") and town.has_node("Police parking drive"),"police entrance walk and parking drive rebuilt")
    check(clear_at(game,space,Vector3(-128,0,80)),"police approach lane (x -128, z 80) is clear")
    # --- restaurants
    var fine: Node3D=town.get_node("Restaurants/Pizza")
    var burger: Node3D=town.get_node("Restaurants/Burger")
    var taco: Node3D=town.get_node("Restaurants/Cafe")
    check(fine.get_meta("venue")=="fine_dining" and burger.get_meta("venue")=="pizza_and_burger","venue metadata")
    var fb: AABB=layout.bounds(fine)
    var bb: AABB=layout.bounds(burger)
    var tb: AABB=layout.bounds(taco)
    var pbx: AABB=layout.bounds(police)
    for pair in [[fb,bb],[fb,tb],[bb,tb],[bb,pbx],[fb,pbx]]:
        var a: AABB=pair[0]
        var b: AABB=pair[1]
        check(not Rect2(a.position.x,a.position.z,a.size.x,a.size.z).intersects(Rect2(b.position.x,b.position.z,b.size.x,b.size.z)),"no footprint overlap")
    check(is_equal_approx(snappedf(fb.size.x,.1),30.6),"fine dining roof width 30.6")
    check(bb.size.x>30 and bb.size.z>18,"Pizza and Burger L footprint")
    var found:=words_under(fine)
    for key in ["table","chair","plate","fork","knife","glass","napkin","candle","tablecloth","menu","bottle","wine","stool","bench","lamp","tray","waiter","painting","counter","ceiling"]:
        check(found.has(key),"fine dining teaches "+key)
    var pizza_words:=words_under(burger)
    for key in ["pizza","hamburger","french fries","soda","oven","cash register","cashier","refrigerator","menu","table","chair","tray","stove","counter","shelf","bench","ceiling"]:
        check(pizza_words.has(key),"Pizza and Burger teaches "+key)
    for dict in [found,pizza_words]:
        for key in dict: check(game.vocabulary.has(key),"vocabulary has "+key)
    # Signs
    var translations: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    check(translations.get("PIZZA AND BURGER","")=="PIZZA Y HAMBURGUESAS" and translations.get("FINE DINING","")=="ALTA COCINA","sign translations")
    var lettering:=[]
    for label in town.get_node("Map facades").find_children("*","Label3D",true,false): lettering.append(String(label.text))
    check("PIZZA AND BURGER" in lettering or "PIZZA Y HAMBURGUESAS" in lettering,"Pizza and Burger sign on the facade")
    check("FINE DINING" in lettering or "ALTA COCINA" in lettering,"Fine dining sign on the facade")
    # Walkable routes: door → interior destinations, capsule probes every ~.7 units.
    var routes:={
        "fine dining":[fine,[Vector3(0,0,-9.6),Vector3(0,0,-6),Vector3(0,0,-2),Vector3(0,0,1),Vector3(-2.2,0,2.8),Vector3(-2.2,0,5.5)]],
        "fine dining windows":[fine,[Vector3(0,0,-3),Vector3(6.8,0,-2.5),Vector3(10.9,0,-2.2)]],
        "pizza and burger":[burger,[Vector3(3,0,-9.6),Vector3(3,0,-6.5),Vector3(2,0,-3),Vector3(-3,0,-1.5),Vector3(-8,0,-.3),Vector3(-12,0,-.3)]],
        "pizza patio":[burger,[Vector3(3,0,-3),Vector3(3,0,-1.2),Vector3(8,0,-.5)]],
    }
    for title in routes:
        var shell: Node3D=routes[title][0]
        var pts: Array=routes[title][1]
        for i in range(pts.size()-1):
            var steps:=int(pts[i].distance_to(pts[i+1])/.7)+1
            for s in range(steps+1):
                var local: Vector3=pts[i].lerp(pts[i+1],float(s)/steps)+Vector3(0,.08,0)
                check(clear_at(game,space,town.to_local(shell.to_global(local))),title+" path blocked near "+str(local))
    # The probe must also be able to fail: solid furniture blocks the capsule.
    check(not clear_at(game,space,town.to_local(fine.to_global(Vector3(3.6,.08,3.3)))),"probe detects the round table")
    check(not clear_at(game,space,town.to_local(burger.to_global(Vector3(-8,.08,1.55)))),"probe detects the service counter")
    # Entrances at ground level: rays through each door at chest height must not hit walls.
    for spec in [[fine,0.0],[burger,3.0]]:
        var shell: Node3D=spec[0]
        var q:=PhysicsRayQueryParameters3D.create(shell.to_global(Vector3(spec[1],1.0,-10.5)),shell.to_global(Vector3(spec[1],1.0,-4.0)))
        check(space.intersect_ray(q).is_empty(),"clear entrance ray "+shell.name)
    # Pre-existing venue unaffected
    check(taco.has_node("Taqueria"),"taquería interior retained")
    print("RESTAURANTS: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
