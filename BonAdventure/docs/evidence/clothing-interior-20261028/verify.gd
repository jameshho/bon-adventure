extends SceneTree
## 28 Oct 2026: clothing store interior. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/clothing-interior-20261028/verify.gd
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
    query.transform=Transform3D(Basis.IDENTITY,store.to_global(p+Vector3(0,.95+.105,0)))
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
    var store: Node3D=town.get_node("Buildings/ClothingStore")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(store.has_node("Interior") and store.get_meta("venue")=="clothing","interior built and tagged")
    check(store.position.is_equal_approx(Vector3(-137,0,164)),"store position unchanged (-137,0,164)")
    check(store.has_node("FrontWallLeft") and store.has_node("RearWall") and store.has_node("FlatRoof") and store.has_node("WindowPane_4"),"shell, roof and windows preserved")
    var layout=game.reference_layout
    var sb: AABB=layout.bounds(store)
    check(absf(sb.size.x-17.105)<.2 and absf(sb.size.z-11.8)<.2,"footprint unchanged")
    for n in ["BakeryCafe","ElectronicsStore"]:
        var o: AABB=layout.bounds(town.get_node("Buildings/"+n))
        check(not Rect2(sb.position.x,sb.position.z,sb.size.x,sb.size.z).intersects(Rect2(o.position.x,o.position.z,o.size.x,o.size.z)),"no overlap with "+n)
    var displays: Node3D=store.get_node("LearningDisplays")
    var words:={"Shirt":"shirt","Jacket":"jacket","Sweater":"sweater","Coat":"coat","Pants":"pants","Jeans":"jeans","Shorts":"shorts","Dress":"dress","Skirt":"skirt","Shoes":"shoes","Sneakers":"sneakers","Boots":"boots","Hat":"hat","Belt":"belt","Scarf":"scarf","Handbag":"handbag","Sunglasses":"sunglasses"}
    for title in words:
        var node: Node3D=displays.get_node_or_null(title)
        check(node!=null and String(node.get_meta("word_key",""))==words[title],"root kept: "+title)
        if node==null: continue
        check(absf(node.position.x)<4.2 and absf(node.position.z)<6.6,"inside walls: "+title)
        var found:=false
        for r in [.9,1.2,1.6,2.2]:
            for a in range(16):
                var q:=node.position+Vector3(cos(a*TAU/16)*r,0,sin(a*TAU/16)*r)
                if absf(q.x)<4.9 and absf(q.z)<7 and clear_at(space,store,Vector3(q.x,0,q.z)): found=true
            if found: break
        check(found,"reachable standing spot: "+title)
        # Taught by the old tables: nothing may float or sit inside the floor.
        check(node.position.y>.9 and node.position.y<1.2,"on a table top: "+title)
    check(not displays.get_children().any(func(c): return String(c.name).begins_with("Display")),"old display tables removed")
    check(not store.get_node("InteriorDetails").has_node("Try-on bench"),"old try-on bench removed")
    # Door gap, central lanes (the glass case sits on x=0), cross access, side lanes.
    for x in [-1.4,1.4]:
        for z in [-8.5,-7.8,-7.0]:
            check(clear_at(space,store,Vector3(x,0,z)),"door gap/entry x=%s z=%s"%[x,z])
    for x in [-1.4,1.4]:
        for z in range(-6,6):
            check(clear_at(space,store,Vector3(x,0,z)),"centre lane x=%s z=%d"%[x,z])
    check(clear_at(space,store,Vector3(0,0,-6.0)) and clear_at(space,store,Vector3(0,0,-1.0)),"centre line open at front")
    var left_ok:=0
    var right_ok:=0
    for z in range(-6,6):
        if clear_at(space,store,Vector3(-4.2,0,z)): left_ok+=1
        if clear_at(space,store,Vector3(4.2,0,z)): right_ok+=1
    check(left_ok>=7 and right_ok>=7,"side lanes mostly open (%d, %d of 12; stages sit under the windows)"%[left_ok,right_ok])
    for z in [-4.0,-1.0,1.0,4.0]:
        check(clear_at(space,store,Vector3(-1.4,0,z)) and clear_at(space,store,Vector3(1.4,0,z)),"fitting-room approach lane z=%s"%z)
    # Fixtures collide.
    check(not clear_at(space,store,Vector3(0,0,2.4)),"accessories case is solid")
    # The counter moved to face the shop on 1 Nov 2026 (clothing-clerk-20261101).
    check(not clear_at(space,store,Vector3(3.4,0,5.25)),"checkout counter is solid")
    check(not clear_at(space,store,Vector3(0,0,6.6)),"fitting rooms are solid")
    check(not clear_at(space,store,Vector3(-2.7,0,-3.0)) and not clear_at(space,store,Vector3(2.7,0,-3.0)),"gondolas are solid")
    check(not clear_at(space,store,Vector3(-4.9,0,-3.35)),"window stage is solid")
    # Signs translate.
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in store.get_node("Interior").find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(table.has(english),"sign translated: "+english)
    print("clothing interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
