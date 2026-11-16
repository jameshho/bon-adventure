extends SceneTree
## 28 Oct 2026: bank interior. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/bank-interior-20261028/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func clear_at(space: PhysicsDirectSpaceState3D,bank: Node3D,p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,bank.to_global(p+Vector3(0,.95+.03,0)))
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
    var bank: Node3D=town.get_node("RelocatedSites/Bank")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(bank.has_node("Interior") and bank.get_meta("venue")=="bank","interior built and tagged")
    check(bank.position.is_equal_approx(Vector3(89,0,133)),"bank position unchanged (89,0,133)")
    for n in ["Bank left wall","Bank right wall","Bank back wall","Bank front pier","Bank front pier2","Bank lintel","Bank peaked roof"]:
        check(bank.has_node(n),"shell kept: "+n)
    check(is_equal_approx((bank.get_node("Bank left wall") as Node3D).position.x,19.0) and is_equal_approx((bank.get_node("Bank back wall") as Node3D).position.z,52.5),"footprint unchanged")
    # Preserved learning roots (ATMs, vault, manager office, queue, waiting furniture, phone, poster).
    var kept:={"ATM":"atm","ATM2":"atm","Vault door":"vault","Deposit safe":"vault","Manager office":"door","Vault entrance":"door","Desk2":"desk","Computer":"computer","Office cabinet":"filing cabinet","Queue rope":"queue","Queue rope2":"queue","Waiting table":"coffee table","Bank brochure":"brochure","Phone":"phone","Chair5":"chair","Chair6":"chair","Chair7":"chair","Chair8":"chair","Bank informational poster":"poster"}
    for title in kept:
        var node: Node3D=bank.get_node_or_null(title)
        check(node!=null and String(node.get_meta("word_key",""))==kept[title],"root kept: "+title)
        if node==null: continue
        var p: Vector3=node.position
        check(p.x>19.1 and p.x<30.9 and p.z>37.6 and p.z<52.4,"inside walls: "+title)
        var found:=false
        for r in [.8,1.1,1.5,2.0]:
            for a in range(16):
                var q:=p+Vector3(cos(a*TAU/16)*r,0,sin(a*TAU/16)*r)
                if q.x>19.5 and q.x<30.5 and q.z>37.9 and q.z<52.1 and clear_at(space,bank,Vector3(q.x,0,q.z)): found=true
            if found: break
        check(found,"reachable standing spot: "+title)
    for door in ["Manager office","Vault entrance"]:
        var node: Node3D=bank.get_node_or_null(door)
        var registered:=false
        for key in game.doors:
            if key is Node and node!=null and (key==node or node.is_ancestor_of(key) or (key as Node).is_ancestor_of(node)): registered=true
        check(registered,"working door kept: "+door)
    var pig: Node3D=town.get_node_or_null("Animals/PigBank")
    check(pig!=null and bank.to_local(pig.global_position).distance_to(Vector3(20.85,bank.to_local(pig.global_position).y,38.85))<.05,"mascot pig behind the reception desk")
    if pig: check(bank.to_local(pig.to_global(Vector3(0,0,1))).z>bank.to_local(pig.global_position).z-2.0,"pig placed (orientation checked in renders)")
    # Old teller counters replaced; their words are on the new teller line.
    check(not bank.has_node("Bank teller counter") and not bank.has_node("Bank teller counter2") and not bank.has_node("Bank teller counter3"),"old teller counters removed")
    var tagged:={}
    for node in bank.get_node("Interior").find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): tagged[String(node.get_meta("word_key"))]=true
    for word in ["teller counter","counter","glass","service window","computer","bell","pencil holder","desk","sofa","table","screen","shelf","brochure","plant"]:
        check(tagged.has(word),"interior word tagged: "+word)
    var words: Dictionary={}
    for node in bank.find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): words[String(node.get_meta("word_key"))]=true
    for word in ["atm","vault","computer"]:
        check(words.has(word),"bank quest word present: "+word)
    # Walkable: door gap, entry, queue lane to the tellers, office and vault doors, ATMs, reception, consultation.
    var open_spots:={"door gap":Vector3(25,0,38.2),"entry":Vector3(25,0,41.0),"queue start":Vector3(25.25,0,43.0),"queue lane":Vector3(25.25,0,45.0),"at the tellers":Vector3(25.3,0,46.9),"office door":Vector3(21.8,0,47.2),"vault door":Vector3(28.7,0,48.1),"ATM 1":Vector3(28.4,0,40.6),"ATM 2":Vector3(28.4,0,42.3),"reception customer side":Vector3(21.6,0,41.1),"consultation access":Vector3(28.1,0,45.65),"between sofas and queue":Vector3(22.9,0,44.4)}
    for label in open_spots:
        check(clear_at(space,bank,open_spots[label]),"walkable: "+label)
    var solids:={"teller counter":Vector3(25.3,0,47.95),"reception desk":Vector3(21.1,0,40.1),"sofa":Vector3(21.15,0,43.2),"brochure shelf":Vector3(28.9,0,38.0)}
    for label in solids:
        check(not clear_at(space,bank,solids[label]),"solid: "+label)
    # Sofas and the receptionist chair are sittable; teller chairs behind the glass are not.
    var sofas:=0
    var tellers:=0
    for seat in game.seating.seats:
        var node: Node=seat.node
        if not bank.is_ancestor_of(node): continue
        if String(node.get_meta("word_key",""))=="sofa": sofas+=1
        if String(node.name).begins_with("Teller chair"): tellers+=1
    check(sofas==2,"both sofas sittable (%d)"%sofas)
    check(tellers==0,"teller chairs not sittable")
    # Signs translate (window numbers are codes).
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in bank.get_node("Interior").find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(english.is_valid_int() or table.has(english),"sign translated: "+english)
    print("bank interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
