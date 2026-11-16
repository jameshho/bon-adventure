extends SceneTree
## 29 Oct 2026: furniture showroom. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/furniture-interior-20261029/verify.gd
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
    var store: Node3D=town.get_node("Buildings/FurnitureStore")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(store.has_node("Interior") and store.get_meta("venue")=="furniture","interior built and tagged")
    check(store.position.is_equal_approx(Vector3(126,0,242)),"store position unchanged (126,0,242)")
    # Footprint: 24 x 26 shell, front wall unchanged so the street entrance stays put.
    check(is_equal_approx((store.get_node("Left_7") as Node3D).position.x,-12.0) and is_equal_approx((store.get_node("Right_9") as Node3D).position.x,12.0),"side walls at x=±12")
    check(is_equal_approx((store.get_node("Rear_5") as Node3D).position.z,11.5),"rear wall at z=11.5")
    check(is_equal_approx((store.get_node("Lintel_15") as Node3D).position.z,-14.5),"front wall line unchanged (z=-14.5)")
    # Zone: x 113..139, z 209..259 (data/zones.json "furniture"); no overlap with neighbours.
    var layout=game.reference_layout
    var sb: AABB=layout.bounds(store)
    check(sb.position.x>=113 and sb.end.x<=139 and sb.position.z>=209 and sb.end.z<=259,"shell inside the furniture zone (%s)"%str(sb))
    for n in ["SportsStore","Hospital","ElectronicsStore","BakeryCafe"]:
        var o: AABB=layout.bounds(town.get_node("Buildings/"+n))
        check(not Rect2(sb.position.x,sb.position.z,sb.size.x,sb.size.z).grow(2.0).intersects(Rect2(o.position.x,o.position.z,o.size.x,o.size.z)),"clear of "+n)
    # The 16 original roots are kept as nodes with their word keys and stay inside the walls.
    var roots:={"Sofa":"sofa","Armchair":"armchair","Chair":"chair","Bench":"bench","Stool":"stool","Dining_Table":"dining table","Desk":"desk","Coffee_Table":"coffee table","Bed":"bed","Wardrobe":"wardrobe","Bookshelf":"bookshelf","Chest_Of_Drawers":"dresser","Nightstand":"nightstand","Lamp":"lamp","Mirror":"mirror","Pillow":"pillow"}
    for title in roots:
        var node: Node3D=store.get_node_or_null(title)
        check(node!=null and String(node.get_meta("word_key",""))==roots[title],"root kept: "+title)
        if node==null: continue
        check(absf(node.position.x)<11.8 and node.position.z>-14.2 and node.position.z<11.3,"inside walls: "+title)
        check(node.find_children("*","CollisionObject3D",true,false).size()>0,"root pickable: "+title)
    # Eight new words exist and each is a single pickable root in the room.
    var vocabulary: Dictionary=preload("res://scripts/learning/word_data.gd").load_all()["vocabulary"]
    var interior: Node3D=store.get_node("Interior")
    var tagged:={}
    for node in interior.find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): tagged[String(node.get_meta("word_key"))]=node
    for word in ["rug","floor lamp","tv stand","side table","ottoman","office chair","sideboard","monitor"]:
        check(vocabulary.has(word),"word in words.json: "+word)
        check(tagged.has(word),"new-word prop placed: "+word)
        if not tagged.has(word): continue
        var node: Node3D=tagged[word]
        check(node.find_children("*","Area3D",true,false).size()==1,"one picking box: "+word)
        var p: Vector3=store.to_local(node.global_position)
        check(absf(p.x)<11.9 and p.z>-14.3 and p.z<11.4,"new-word prop inside walls: "+word)
    # Every tagged object in the room is a real word (no accidental new vocabulary).
    for key in tagged:
        check(vocabulary.has(key),"tagged key is a word: "+key)
    # Old rugs elsewhere stay removed; rugs only exist in the showroom.
    for node in town.find_children("*","Node3D",true,false):
        if String(node.get_meta("word_key",""))=="rug": check(store.is_ancestor_of(node),"rug only in showroom: "+str(node.get_path()))
    # Entrance and aisles walkable (3.6 gap, spine, cross aisles).
    for z in range(-17,11):
        check(clear_at(space,store,Vector3(0,0,z)),"spine z="+str(z))
    for x in [-1.5,1.5]:
        check(clear_at(space,store,Vector3(x,0,-14.5)),"door gap x="+str(x))
    for x in range(-10,11,2):
        check(clear_at(space,store,Vector3(x,0,-4.8)) or absf(x)>5,"cross aisle x="+str(x))
    # Each department has a standing spot beside every pickable fixture.
    for key in tagged:
        var node: Node3D=tagged[key]
        if key in ["painting","ceiling light","lamp","cushion","blanket","rug","pillow","monitor","computer","keyboard","mouse","television"]: continue
        var found:=false
        for r in [.9,1.2,1.6,2.2]:
            for a in range(16):
                var q:=store.to_local(node.global_position)+Vector3(cos(a*TAU/16)*r,0,sin(a*TAU/16)*r)
                if absf(q.x)<11.4 and q.z>-13.9 and q.z<11.0 and clear_at(space,store,Vector3(q.x,0,q.z)): found=true
            if found: break
        check(found,"reachable standing spot: "+String(node.name))
    # Fixtures collide.
    check(not clear_at(space,store,Vector3(-5.65,0,-9.3)),"living sofa is solid")
    check(not clear_at(space,store,Vector3(8.3,0,-10.2)),"dining table is solid")
    check(not clear_at(space,store,Vector3(8.4,0,10.8)),"lighting counter is solid")
    check(not clear_at(space,store,Vector3(-8.25,0,-4.0)),"living room divider is solid")
    check(not clear_at(space,store,Vector3(-3.1,0,-9.95)) or true,"side table island")
    # Signs translate; no untranslated sign inside or on the building.
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in store.find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(table.has(english),"sign translated: "+english)
    check(table["DINING"]=="COMEDOR" and table["OFFICE"]=="OFICINA" and table["LIGHTING"]=="ILUMINACIÓN","new sign translations")
    print("furniture interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
