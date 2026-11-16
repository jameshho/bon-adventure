extends SceneTree
## 1 Nov 2026: Alta Cocina Italian remodel (kitchen wing, terrace, food words) and plush
## staff replacing the deleted cook model. Run with the README's isolated user directory
## (Main saves progress): godot --headless --path . --script res://docs/evidence/alta-cocina-20261101/verify.gd
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
        if n.has_meta("word_key"): found[String(n.get_meta("word_key"))]=true
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
    await physics_frame
    await physics_frame
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var fine: Node3D=town.get_node("Restaurants/Pizza")
    # --- the cook model is gone everywhere
    check(not ResourceLoader.exists("res://scenes/characters/cook.tscn"),"cook.tscn deleted")
    var stale:=town.find_children("*","Node3D",true,false).filter(func(n): return n.scene_file_path.ends_with("cook.tscn"))
    check(stale.is_empty(),"no cook-model instances remain (%d)"%stale.size())
    # --- plush staff: [node name, parent, species scene, word, outfit]
    var interaction:=preload("res://scripts/player/interaction_controller.gd")
    var staff:=[
        ["BeagleWaiter",fine,"beagle_plush","waiter","waiter"],
        ["BeagleBartender",fine,"beagle_plush","waiter","waiter"],
        ["BearChef",fine,"bear_plush","cook","chef"],
        ["CrocodileCook",town.get_node("Restaurants/Cafe"),"crocodile_plush","cook","chef"],
        ["CatWaiter",town.get_node("Restaurants/Cafe"),"cat_plush","waiter","waiter"],
        ["LionChef",town.get_node("Restaurants/Burger"),"lion_plush","cook","chef"],
        ["GoldenCashier",town.get_node("Restaurants/Burger"),"golden_plush","cashier","shopkeeper"],
        ["SamoyedCook",town.get_node("People"),"samoyed_plush","cook","chef"],
    ]
    for spec in staff:
        var npc: Node3D=(spec[1] as Node3D).find_child(spec[0],true,false)
        check(npc!=null,spec[0]+" exists")
        if npc==null: continue
        check(npc.scene_file_path.ends_with(spec[2]+".tscn"),spec[0]+" is a "+spec[2])
        check(String(npc.get_meta("word_key",""))==spec[3] and game.vocabulary.has(spec[3]),spec[0]+" teaches "+spec[3])
        var costume: Node=npc.get_node_or_null("Costume")
        check(costume!=null and String(costume.get("outfit"))==spec[4],spec[0]+" wears "+spec[4])
        check(npc.global_basis.get_scale().is_equal_approx(Vector3.ONE),spec[0]+" is BonBon-sized (world scale 1)")
        var area: Node=npc.get_node_or_null("StudyArea")
        check(area!=null and interaction.vocabulary_target(area,town)==npc,spec[0]+" click resolves to its word")
    check(town.get_node("People/SamoyedCook").get_meta("reference_site","")=="Bakery","bakery cook moves with the bakery")
    # Waiters face the room: the host waiter looks toward the door (shell −Z).
    var host: Node3D=fine.find_child("BeagleWaiter",true,false)
    if host: check((fine.global_basis.inverse()*-host.global_basis.z).normalized().z< -.9,"host waiter faces the entrance")
    # --- vocabulary placed in the restaurant
    var found:=words_under(fine)
    for key in ["pasta","lasagna","meatballs","pizza","steak","salad","soup","dessert","ice cream","bread","olive","wine","cheese","grapes","garlic","basil","mushroom","tomato","oil","cake","oven","stove","pot","refrigerator","sink","jar","plant","flower","basket","bowl","waiter","cook","table","chair","plate","menu"]:
        check(found.has(key),"Alta Cocina teaches "+key)
        check(game.vocabulary.has(key),"vocabulary has "+key)
    var facade: Node3D=town.get_node("Map facades/FINE DINING")
    check(words_under(facade).has("coffee"),"terrace teaches coffee")
    # --- kitchen wing: behind the dining room, inside the fine-dining zone, shell width unchanged
    var roof: Node3D=fine.find_child("KitchenRoof",true,false)
    check(roof!=null,"kitchen roof exists")
    var zones: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/zones.json"))
    var zone: Array=[]
    for z in zones["zones"]:
        if z["id"]=="fine_dining": zone=z["polygons"][0]
    var poly:=PackedVector2Array()
    for p in zone: poly.append(Vector2(p[0],p[1]))
    for corner in [Vector3(-1.25,0,7.9),Vector3(15,0,7.9),Vector3(-1.25,0,16.3),Vector3(15,0,16.3)]:
        var t:=town.to_local(fine.to_global(corner))
        check(Geometry2D.is_point_in_polygon(Vector2(t.x,t.z),poly),"kitchen corner %s inside the fine_dining zone"%corner)
    var bounds: AABB=game.reference_layout.bounds(fine)
    check(is_equal_approx(snappedf(bounds.size.x,.1),30.6),"building width still 30.6")
    # Walkable route from the door to the kitchen and the chef (capsule probes every ~.7).
    var pts:=[Vector3(0,0,-9.6),Vector3(0,0,.6),Vector3(8.6,0,.6),Vector3(8.6,0,6.4),Vector3(13.1,0,6.4),Vector3(13.1,0,9.3),Vector3(10,0,9.3),Vector3(10,0,12.6)]
    for i in range(pts.size()-1):
        var steps:=int(pts[i].distance_to(pts[i+1])/.7)+1
        for s in range(steps+1):
            var local: Vector3=pts[i].lerp(pts[i+1],float(s)/steps)+Vector3(0,.08,0)
            check(clear_at(game,space,town.to_local(fine.to_global(local))),"kitchen route blocked near "+str(local))
    check(not clear_at(game,space,town.to_local(fine.to_global(Vector3(7,.08,11.2)))),"probe detects the prep island")
    check(not clear_at(game,space,town.to_local(fine.to_global(Vector3(5.5,.08,7.9)))),"pass wall below the opening is solid")
    print("ALTA COCINA: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
