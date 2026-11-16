extends SceneTree
## 28 Oct 2026: airport terminal interior. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/airport-interior-20261028/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func clear_at(space: PhysicsDirectSpaceState3D,terminal: Node3D,p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,terminal.to_global(p+Vector3(0,.95+.1,0)))
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
    var terminal: Node3D=town.get_node("Airport/Terminal")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(terminal.has_node("Interior") and terminal.get_meta("venue")=="airport","interior built and tagged")
    for n in ["Foundation","WestWall","EastWall","RearWall","FrontPier","FrontPier2","DoorHeader","Roof"]:
        check(terminal.has_node(n),"shell kept: "+n)
    check(is_equal_approx((terminal.get_node("WestWall") as Node3D).position.x,-17.0) and is_equal_approx((terminal.get_node("RearWall") as Node3D).position.z,9.0),"footprint unchanged")
    check(town.has_node("Vehicles/Turboprop") and town.has_node("Airport/ControlTower"),"aircraft and tower kept")
    # Every new airport word is in words.json and tagged inside the terminal, pickable and inside the walls.
    var words: Dictionary=preload("res://scripts/learning/word_data.gd").load_all()
    var tagged:={}
    for node in terminal.get_node("Interior").find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): tagged[String(node.get_meta("word_key"))]=node
    for word in ["airport","passport","boarding pass","suitcase","luggage cart","check-in counter","metal detector","flight board","baggage claim","x ray machine","conveyor belt","scale","tray","seat","coffee maker","cup","menu","table","chair","counter","cash register","shelf","backpack","sunglasses","computer","screen","desk","door","bathroom"]:
        check(words["vocabulary"].has(word),"word in words.json: "+word)
        check(tagged.has(word),"tagged in terminal: "+word)
        if not tagged.has(word): continue
        var node: Node3D=tagged[word]
        check(node.find_children("*","CollisionObject3D",true,false).size()>0,"pickable: "+word)
        var p: Vector3=terminal.to_local(node.global_position)
        check(absf(p.x)<16.9 and absf(p.z)<8.9,"inside walls: "+word)
    for word in ["passport","boarding pass","suitcase","luggage cart","check-in counter","metal detector","flight board"]:
        check(words["categories"].get(word,"")=="Travel","Travel category: "+word)
    # Walkable routes: entry, aisle, each zone, and into the gate only through the detector.
    var open_spots:={"door":Vector3(0,0,-8.4),"entry":Vector3(0,0,-6.0),"aisle":Vector3(0,0,-2.0),"beside the board":Vector3(-2.6,0,-.4),"shop":Vector3(-10.0,0,-5.6),"cafe":Vector3(-11.0,0,-2.4),"check-in queue":Vector3(-10.7,0,5.3),"security queue":Vector3(-2.0,0,3.0),"lane entry":Vector3(.2,0,4.7),"through detector":Vector3(3.4,0,4.7),"security gap":Vector3(5.5,0,4.7),"gate corridor":Vector3(9.0,0,4.1),"gate desk front":Vector3(12.6,0,6.4),"boarding door":Vector3(9.0,0,8.2),"baggage claim":Vector3(11.0,0,-6.6),"restrooms":Vector3(16.0,0,-1.2),"carts":Vector3(14.4,0,-7.5)}
    for label in open_spots:
        check(clear_at(space,terminal,open_spots[label]),"walkable: "+label)
    var solids:={"check-in counter":Vector3(-10.7,0,6.7),"x-ray machine":Vector3(.6,0,5.95),"carousel":Vector3(11.0,0,-4.2),"gate glass (x)":Vector3(5.5,0,2.5),"gate glass (z)":Vector3(11.0,0,1.0),"flight board":Vector3(0,0,-.4),"seat row":Vector3(3.4,0,-4.45),"information desk":Vector3(-3.3,0,-5.6),"lane rail":Vector3(4.6,0,3.92)}
    for label in solids:
        check(not clear_at(space,terminal,solids[label]),"solid: "+label)
    # No way into the gate except the security gap.
    var blocked_routes:=0
    for z in [1.5,2.5,3.5,6.0,7.0,8.4]:
        if not clear_at(space,terminal,Vector3(5.5,0,z)): blocked_routes+=1
    check(blocked_routes==6,"gate partition closed except the security gap (%d/6)"%blocked_routes)
    var seats:=0
    for seat in game.seating.seats:
        if terminal.is_ancestor_of(seat.node) and String(seat.node.get_meta("word_key",""))=="seat": seats+=1
    # 35 since 6 Nov 2026: the three waiting rows right of the door made way for the flight
    # game's information desk (user request); 50 before.
    check(seats>=35,"terminal seats sittable (%d)"%seats)
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in terminal.find_children("*","Label3D",true,false):
        # Flight-game poster cards (5 Nov 2026) are live Lexicon labels, not fixed signs.
        if label.has_meta("interior_label"): continue
        var english:String=label.get_meta("sign_english",label.text)
        check(english.is_valid_int() or english.length()<=2 or table.has(english),"sign translated: "+english)
    print("airport interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
