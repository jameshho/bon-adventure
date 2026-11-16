extends SceneTree
## 1 Nov 2026: electronics store refresh. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/electronics-interior-20261101/verify.gd
## Player-sized means BonBon's capsule (radius 0.76 m, height 2.2 m); the store is scaled 1.3.
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const STEP := .25
var failures:=0
var checks:=0
var game
var store: Node3D
var space: PhysicsDirectSpaceState3D
var capsule:=CapsuleShape3D.new()
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
## BonBon standing with her feet on the store floor at store-local (x, z).
func clear_at(x: float,z: float) -> bool:
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,store.to_global(Vector3(x,.11,z))+Vector3(0,1.1,0))
    query.exclude=[game.player.get_rid()]
    return space.intersect_shape(query,1).is_empty()
func local(p: Vector3) -> Vector3:
    return store.global_transform.affine_inverse()*p
## Store-frame AABB of every mesh under a root (batched meshes are hidden but still count).
func bounds(node: Node3D) -> AABB:
    var lo:=Vector3.ONE*1e9
    var hi:=-lo
    for m in node.find_children("*","MeshInstance3D",true,false):
        var a: AABB=(m as MeshInstance3D).get_aabb()
        for i in 8:
            var q:=local((m as MeshInstance3D).global_transform*a.get_endpoint(i))
            lo=lo.min(q)
            hi=hi.max(q)
    return AABB(lo,hi-lo)
func pick_centres(node: Node3D) -> Array:
    var out:=[]
    # Pick colliders: Area3Ds, or a solid word box's own StaticBody (tagged "word").
    for area in node.find_children("*","CollisionObject3D",true,false):
        if not (area is Area3D or area.has_meta("word")): continue
        for holder in area.get_children():
            if holder is CollisionShape3D and holder.shape is BoxShape3D: out.append(holder.global_position)
    return out
func run() -> void:
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    capsule.radius=.76
    capsule.height=2.2
    var town: Node3D=game.apartment
    store=town.get_node("Buildings/ElectronicsStore")
    space=game.get_world_3d().direct_space_state
    var site: Node3D=town.get_node_or_null("RelocatedSites/Electronics")
    # Shell, door and tags.
    check(store.has_node("Interior") and store.get_meta("venue","")=="electronics","interior built and tagged")
    check(store.get_meta("reference_site","")=="Electronics","reference site metadata kept")
    for n in ["FrontWallLeft","FrontWallRight","FrontHeader","RearWall","FlatRoof","WindowPane","WindowPane_4","DoorJamb","DoorJamb_2","DoorStep","RoomPlaque","LearningDisplays"]:
        check(store.has_node(n),"shell node kept: "+n)
    check(String(store.get_node("DoorStep").get_meta("word_key",""))=="entrance","door step keeps its entrance word")
    var basis_scale:=store.global_transform.basis.get_scale()
    check(basis_scale.is_equal_approx(Vector3.ONE*1.3),"store scale unchanged (1.3)")
    # Every assigned word: [parent, root name, key, kind]. kind: table/floor/wall/hang.
    var displays: Node3D=store.get_node("LearningDisplays")
    var interior: Node3D=store.get_node("Interior")
    var words:=[
        [displays,"Television","television","on"],[displays,"Computer","computer","on"],
        [displays,"Laptop","laptop","on"],[displays,"Smartphone","smartphone","on"],
        [displays,"Tablet","tablet","on"],[displays,"Keyboard","keyboard","on"],
        [displays,"Mouse","mouse","on"],[displays,"Game_Controller","game controller","on"],
        [displays,"Washing_Machine","washing machine","on"],[displays,"Dryer","dryer","on"],
        [displays,"Refrigerator","refrigerator","on"],[displays,"Microwave","microwave","on"],
        [displays,"Headphones","headphones","on"],[displays,"Speaker","speaker","on"],
        [displays,"Camera","camera","on"],[displays,"Fan","fan","on"],
        [interior,"Checkout counter","checkout counter","on"],[interior,"Cash register","cash register","on"],
        [interior,"Shopping bag","shopping bag","on"],
        [site,"Smartwatch","smartwatch","on"],[site,"Game Console","game console","on"],
        [site,"Electronics plaque","electronics","wall"],[site,"Gaming plaque","gaming","wall"],
        [site,"Tech plaque","tech","hang"],
    ]
    var vocabulary: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))["words"]
    # Reachable floor from the doorway: flood fill of clear BonBon positions inside the walls.
    var cells:={}
    var start:=Vector2i(0,roundi(-7.0/STEP))
    check(clear_at(0,-7.0),"BonBon fits just inside the door")
    var queue:=[start]
    cells[start]=true
    while not queue.is_empty():
        var c: Vector2i=queue.pop_back()
        for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
            var n: Vector2i=c+d
            if cells.has(n) or absf(n.x*STEP)>5.4 or n.y*STEP< -7.4 or n.y*STEP>7.4: continue
            if clear_at(n.x*STEP,n.y*STEP):
                cells[n]=true
                queue.append(n)
    print("reachable cells: ",cells.size())
    for x in [-1.2,0,1.2]:
        for z in [-7.5,-8.2,-9.0]:
            check(clear_at(x,z),"door gap/step clear x=%s z=%s"%[x,z])
    for k in range(-28,25):
        check(cells.has(Vector2i(0,k)),"centre aisle reachable z=%.2f"%(k*STEP))
    for spec in words:
        var parent: Node3D=spec[0]
        var node: Node3D=parent.get_node_or_null(spec[1]) if parent else null
        check(node!=null,"root kept: "+spec[1])
        if node==null: continue
        check(String(node.get_meta("word_key",""))==spec[2] and vocabulary.has(spec[2]),"word key kept: %s = %s"%[spec[1],spec[2]])
        var b:=bounds(node)
        check(b.size.x<9 and b.position.x>-5.66 and b.end.x<5.66 and b.position.z>-7.6 and b.end.z<7.6 and b.end.y<5.25,"inside the room: "+spec[1])
        var centres:=pick_centres(node)
        check(not centres.is_empty(),"has a pick area: "+spec[1])
        if centres.is_empty(): continue
        var fit:=false
        for c in centres:
            if b.grow(.05).has_point(local(c)): fit=true
        check(fit,"pick area sits on the model: "+spec[1])
        # Supported: something solid directly under the model (signs: mounted on a wall or hung).
        if spec[3]=="on":
            var under:=PhysicsRayQueryParameters3D.create(store.to_global(Vector3(b.get_center().x,b.position.y+.04,b.get_center().z)),store.to_global(Vector3(b.get_center().x,b.position.y-.6,b.get_center().z)))
            var own:=[]
            for body in node.find_children("*","CollisionObject3D",true,false): own.append(body.get_rid())
            if node is CollisionObject3D: own.append(node.get_rid())
            under.exclude=own
            var hit:=space.intersect_ray(under)
            var gap:=99.0
            if not hit.is_empty(): gap=b.position.y-local(hit.position).y
            check(gap<.07 and gap>-.07,"resting on a surface (gap %.3f): %s"%[gap,spec[1]])
        elif spec[3]=="wall":
            var to_wall:=minf(5.64-absf(b.get_center().x),7.6-absf(b.get_center().z))
            check(to_wall<.15,"mounted on a wall: "+spec[1])
        # Reachable and pickable: from some reachable BonBon spot within interaction range, an eye
        # ray to the pick centre resolves to this root.
        var picked:=false
        var nearest:=99.0
        for c in cells:
            var p:=Vector3(c.x*STEP,0,c.y*STEP)
            var flat:=Vector2(clampf(p.x,b.position.x,b.end.x)-p.x,clampf(p.z,b.position.z,b.end.z)-p.z).length()
            nearest=minf(nearest,flat)
            if flat>2.4 or picked: continue
            var eye:=store.to_global(Vector3(p.x,.11,p.z))+Vector3(0,1.8,0)
            for target in centres:
                if eye.distance_to(target)>Interaction.INTERACT_DISTANCE: continue
                var ray:=PhysicsRayQueryParameters3D.create(eye,target+(target-eye).normalized()*.05)
                ray.collide_with_areas=true
                ray.exclude=[game.player.get_rid()]
                var hit:=space.intersect_ray(ray)
                if not hit.is_empty() and Interaction.vocabulary_target(hit.collider,town)==node: picked=true
        check(nearest<1.3,"reachable within 1.3 store units (%.2f): %s"%[nearest,spec[1]])
        check(picked,"pickable from a reachable spot: "+spec[1])
    # Department routes: BonBon can stand in front of each display.
    for spot in [[-1.6,-3.3,"computers"],[-1.6,1.8,"phones"],[1.6,1.8,"audio"],[1.6,-3.3,"cameras"],[-4.2,-6.0,"televisions"],[-4.2,0,"accessories"],[-4.2,6.0,"gaming"],[0,6.0,"home theatre"],[3.8,-5.6,"appliances"],[4.0,0,"small appliances"],[3.9,4.7,"checkout"]]:
        check(cells.has(Vector2i(roundi(spot[0]/STEP),roundi(spot[1]/STEP))),"route from door to "+spot[2])
    # Fixtures are solid.
    for p in [Vector3(-2.6,0,-3.3),Vector3(-2.6,0,1.8),Vector3(2.6,0,1.8),Vector3(2.6,0,-3.3),Vector3(3.9,0,5.9),Vector3(0,0,6.6),Vector3(-4.9,0,6.0),Vector3(-4.9,0,-6.0),Vector3(-4.9,0,0),Vector3(4.9,0,0),Vector3(4.6,0,-3.0)]:
        check(not clear_at(p.x,p.z),"fixture is solid at %s"%p)
    # No untagged look-alikes of word objects, no old fixtures.
    for n in interior.get_children():
        var title:=String(n.name)
        check(not (title.begins_with("Game console") or title.begins_with("Headset") or title.begins_with("Coffee maker") or title.begins_with("Gondola")),"no old decor/look-alike: "+title)
    check(not displays.get_children().any(func(c): return String(c.name).begins_with("Display")),"old display tables removed")
    # Signs translate (prices are numbers and stay as they are).
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    var labels:=interior.find_children("*","Label3D",true,false)
    for t in ["ELECTRONICS upgrade sign","GAMING upgrade sign","TECH upgrade sign"]:
        if site and site.has_node(t): labels.append(site.get_node(t))
    var prices:=0
    for label in labels:
        var english:String=label.get_meta("sign_english",label.text)
        if english.begins_with("$"):
            prices+=1
            continue
        check(table.has(english),"sign translated: "+english)
    check(prices>=20,"price tags present (%d)"%prices)
    print("electronics refresh checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
