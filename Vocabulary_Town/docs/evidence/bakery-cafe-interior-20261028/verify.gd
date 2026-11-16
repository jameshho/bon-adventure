extends SceneTree
## 28 Oct 2026: café and bakery interior. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/bakery-cafe-interior-20261028/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func clear_at(space: PhysicsDirectSpaceState3D,store: Node3D,p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,store.to_global(p+Vector3(0,.95+.05,0)))
    return space.intersect_shape(query,1).is_empty()
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var town: Node3D=game.apartment
    var store: Node3D=town.get_node("Buildings/BakeryCafe")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(store.has_node("Interior") and store.get_meta("venue")=="bakery_cafe","interior built and tagged")
    check(store.position.is_equal_approx(Vector3(137,0,166)),"store position unchanged (137,0,166)")
    check(store.has_node("FrontLeft_11") and store.has_node("Rear_5") and store.has_node("Roof_18") and store.has_node("Lintel_15") and store.has_node("SignBoard_19"),"shell, roof and sign preserved")
    var layout=game.reference_layout
    var sb: AABB=layout.bounds(store)
    check(absf(sb.size.x-25.15)<.2 and absf(sb.size.z-14.3)<.2,"footprint unchanged (%.2f × %.2f)"%[sb.size.x,sb.size.z])
    for n in ["ElectronicsStore","FurnitureStore"]:
        var o: AABB=layout.bounds(town.get_node("Buildings/"+n))
        check(not Rect2(sb.position.x,sb.position.z,sb.size.x,sb.size.z).intersects(Rect2(o.position.x,o.position.z,o.size.x,o.size.z)),"no overlap with "+n)
    var words:={"Bread":"bread","Baguette":"baguette","Croissant":"croissant","Cake":"cake","Donut":"donut","Cookie":"cookie","Coffee_Machine":"coffee maker","Teapot":"teapot","Cup":"cup","Bowl":"bowl","Plate":"plate","Spoon":"spoon","Knife":"knife","Rolling_Pin":"rolling pin","Whisk":"whisk","Apron":"apron","Everyday_Coffee":"coffee","Everyday_Breakfast":"breakfast","Everyday_Lunch":"lunch","Everyday_Dinner":"dinner","Everyday_Menu":"menu","Everyday_Bill":"bill","Everyday_Food":"food"}
    for title in words:
        var node: Node3D=store.get_node_or_null(title)
        check(node!=null and String(node.get_meta("word_key",""))==words[title],"root kept: "+title)
        if node==null: continue
        check(absf(node.position.x)<6.9 and absf(node.position.z)<10.9 and node.position.y>0,"inside walls: "+title)
        var found:=false
        for r in [.9,1.2,1.6,2.2]:
            for a in range(16):
                var q:=node.position+Vector3(cos(a*TAU/16)*r,0,sin(a*TAU/16)*r)
                if absf(q.x)<6.5 and absf(q.z)<10.5 and clear_at(space,store,Vector3(q.x,0,q.z)): found=true
            if found: break
        check(found,"reachable standing spot: "+title)
    for title in ["Bread","Croissant","Coffee_Machine","Cup"]:
        check(store.get_node(title).has_node("Interaction") or store.get_node(title).find_children("*","Area3D",true,false).size()>0,"still pickable: "+title)
    var site: Node3D=town.get_node("RelocatedSites/Bakery")
    for title in ["Bowl2","Soup","Cupcake paper","Cookie"]:
        var q: Vector3=store.to_local(site.get_node(title).global_position)
        check(q.y>.75 and q.y<1.9 and absf(q.x)<6.9 and absf(q.z)<10.9 and not (absf(q.x)<1.3 and q.z<5),"relocated item on a fixture, out of the aisle: %s %s"%[title,q])
    var cook: Vector3=store.to_local(town.get_node("People/SamoyedCook").global_position)
    check(cook.z>6.6 and cook.z<10 and absf(cook.x)<1.4,"cook behind the register, not in the doorway: %s"%cook)
    check(not store.get_children().any(func(c): return String(c.name).begins_with("Display") or String(c.name).begins_with("EverydayVocabulary") or String(c.name) in ["Section476","Section484"]),"old display tables, shelves and labels removed")
    # Door gap, centre aisle to the register, staff gap and work area.
    for x in [-1.2,0,1.2]:
        for z in [-11.6,-10.6,-9.8]:
            check(clear_at(space,store,Vector3(x,0,z)),"door gap/entry x=%s z=%s"%[x,z])
    for x in [-.9,0,.9]:
        for z in range(-9,5):
            check(clear_at(space,store,Vector3(x,0,z)),"centre aisle x=%s z=%d"%[x,z])
    for z in [5.4,6.0,6.6,7.5]:
        check(clear_at(space,store,Vector3(2.0,0,z)),"staff gap z=%s"%z)
    for x in [-5.5,-3,-.5]:
        check(clear_at(space,store,Vector3(x,0,8.3)),"work area behind counter x=%s"%x)
    for p in [Vector3(-5.6,0,-6),Vector3(3.6,0,7.8),Vector3(4.0,0,.8),Vector3(5.0,0,9.0)]:
        check(clear_at(space,store,p),"open floor at %s"%p)
    # Fixtures collide.
    for p in [Vector3(-3,0,6),Vector3(-3,0,10.5),Vector3(3.7,0,10.5),Vector3(5.55,0,10.5),Vector3(6.6,0,8.2),Vector3(-6.5,0,-6.6),Vector3(-3.6,0,-4.6),Vector3(6.0,0,-1.4)]:
        check(not clear_at(space,store,p),"fixture solid at %s"%p)
    var seats:=store.get_node("Interior").find_children("*","Node3D",true,false).filter(func(n): return n.get_meta("sit_enabled",false))
    check(seats.size()==24,"sittable seats: %d (20 chairs + 4 booth benches)"%seats.size())
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in store.get_node("Interior").find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(table.has(english),"sign translated: "+english)
        check(label.is_visible_in_tree(),"sign visible: "+english)
    print("bakery cafe interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
