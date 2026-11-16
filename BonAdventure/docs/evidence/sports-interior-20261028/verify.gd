extends SceneTree
## 28 Oct 2026: sports store interior (winter department revision the same day). Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/sports-interior-20261028/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func clear_at(game,space: PhysicsDirectSpaceState3D,store: Node3D,p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,store.to_global(p+Vector3(0,.95,0)))
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
    var store: Node3D=town.get_node("Buildings/SportsStore")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(store.has_node("Interior") and store.get_meta("venue")=="sports","interior built and tagged")
    check(store.position.is_equal_approx(Vector3(96,0,242)),"store position unchanged (96,0,242)")
    # Footprint unchanged: shell meshes keep their 14 x 24 extents.
    check(is_equal_approx((store.get_node("Left_7") as Node3D).position.x,-7.0) and is_equal_approx((store.get_node("Rear_5") as Node3D).position.z,12.0),"shell walls unchanged")
    var layout=game.reference_layout
    var sb: AABB=layout.bounds(store)
    for n in ["FurnitureStore","Hospital"]:
        var o: AABB=layout.bounds(town.get_node("Buildings/"+n))
        check(not Rect2(sb.position.x,sb.position.z,sb.size.x,sb.size.z).intersects(Rect2(o.position.x,o.position.z,o.size.x,o.size.z)),"no overlap with "+n)
    # Learning roots preserved ("" = prop whose word was removed in the 28 Oct word audit; kept as decor) and inside the room.
    var roots:={"Basketball":"basketball","Soccer_Ball":"soccer ball","Volleyball":"volleyball","Tennis_Ball":"","Baseball":"","Baseball_Glove":"","Baseball_Bat":"","Tennis_Racket":"tennis racket","Bicycle":"bicycle","Skateboard":"skateboard","Helmet":"helmet","Dumbbell":"dumbbell","Barbell":"","Jump_Rope":"jump rope","Basketball_Hoop":"basketball hoop","Goal":"goal"}
    for title in roots:
        var node: Node3D=store.get_node_or_null(title)
        check(node!=null and String(node.get_meta("word_key",""))==roots[title],"root kept: "+title)
        if node==null: continue
        check(absf(node.position.x)<6.6 and absf(node.position.z)<11.6,"inside walls: "+title)
        var found:=false
        for r in [.9,1.2,1.6,2.2]:
            for a in range(16):
                var q:=node.position+Vector3(cos(a*TAU/16)*r,0,sin(a*TAU/16)*r)
                if absf(q.x)<6.4 and absf(q.z)<11.4 and clear_at(game,space,store,Vector3(q.x,0,q.z)): found=true
            if found: break
        check(found,"reachable standing spot: "+title)
    # Entrance, central spine and side aisles are walkable.
    for z in range(-14,12):
        check(clear_at(game,space,store,Vector3(0,0,z)),"centre aisle z="+str(z))
    for x in [-1.4,1.4]:
        check(clear_at(game,space,store,Vector3(x,0,-11.9)),"door gap x="+str(x))
    for z in range(-10,11,2):
        check(clear_at(game,space,store,Vector3(-1.4,0,z)) or clear_at(game,space,store,Vector3(1.4,0,z)),"cross access z="+str(z))
    var left_ok:=0
    var right_ok:=0
    for z in range(-10,11):
        if clear_at(game,space,store,Vector3(-5.2,0,z)): left_ok+=1
        if clear_at(game,space,store,Vector3(5.1,0,z)): right_ok+=1
    check(left_ok>=14 and right_ok>=14,"side aisles mostly open (%d, %d of 21)"%[left_ok,right_ok])
    # Fixtures collide: shelves, counter, tent.
    check(not clear_at(game,space,store,Vector3(-6.4,0,-8.8)),"left wall unit is solid")
    check(not clear_at(game,space,store,Vector3(-6.0,0,8.8)),"checkout counter is solid")
    check(not clear_at(game,space,store,Vector3(-3.3,0,7.3)),"tent is solid")
    check(not clear_at(game,space,store,Vector3(3.1,0,11.6)),"winter accessory shelves are solid")
    check(not clear_at(game,space,store,Vector3(-1.95,0,10.3)),"skier mannequin is solid")
    # Winter sports words: each is one pickable root inside the room.
    var interior: Node3D=store.get_node("Interior")
    var tagged:={}
    for node in interior.find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): tagged[String(node.get_meta("word_key"))]=node
    var vocabulary: Dictionary=preload("res://scripts/learning/word_data.gd").load_all()["vocabulary"]
    for word in ["skis","ski poles","snowboard","ski boots","gloves","winter hat","ski goggles","sled","helmet","jacket"]:
        check(vocabulary.has(word),"word in words.json: "+word)
        check(tagged.has(word),"winter prop tagged: "+word)
        if not tagged.has(word): continue
        var node: Node3D=tagged[word]
        check(node.find_children("*","CollisionObject3D",true,false).size()>0,"winter prop pickable: "+word)
        var p: Vector3=store.to_local(node.global_position)
        check(absf(p.x)<6.6 and absf(p.z)<11.9,"winter prop inside walls: "+word)
    # Signs translate; no untranslated department sign.
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in store.find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(table.has(english),"sign translated: "+english)
    print("sports interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
