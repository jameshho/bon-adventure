extends SceneTree
## 28 Oct 2026: police station interior. Updated 6 Nov 2026 for the enlarged 20 x 22 station
## (docs/evidence/police-detective-20261106/PROMPT.md): spots are police_interior.gd design
## coordinates, mapped into the station by mirror_point(). Isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/police-interior-20261028/verify.gd
const Interior:=preload("res://scripts/buildings/police.gd")
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func clear_at(space: PhysicsDirectSpaceState3D,station: Node3D,p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,station.to_global(Interior.mirror_point(p)+Vector3(0,.95+.06,0)))
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
    var station: Node3D=town.get_node("RelocatedSites/Police")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    check(station.has_node("Interior") and station.get_meta("venue")=="police","interior built and tagged")
    check(station.position.is_equal_approx(Vector3(-101.5,0,37)),"station position unchanged")
    check(is_equal_approx((station.get_node("Police Station left wall") as Node3D).position.x,33.0) and is_equal_approx((station.get_node("Police Station back wall") as Node3D).position.z,59.5),"footprint 20 x 22 (x 33..53, z 37.5..59.5)")
    var kept:={"Police reception":"reception desk","Reception monitor":"computer","Desk phone":"phone","Officer workstation surface":"desk","Police monitor":"computer","Radio":"radio","Case report":"report","Chair9":"chair","Chair10":"chair","Chair11":"chair","Chair12":"chair","Chair14":"chair","Chair15":"chair","Information display":"bulletin board","Evidence board":"bulletin board","Police badge":"badge","Interview table surface":"table","Records cabinet":"filing cabinet","Records cabinet2":"filing cabinet","Records cabinet3":"filing cabinet","File drawer face":"drawer","Locker label":"label","Cell bench":"bench","First aid box":"first aid kit","Interview room":"door","Holding cell":"door"}
    for title in kept:
        # Since 3 Nov 2026 the locker label hangs on its locker door (a child of the hinge).
        var node: Node3D=station.get_node_or_null(title)
        if node==null: node=station.find_child(title,true,false) as Node3D
        check(node!=null and String(node.get_meta("word_key",""))==kept[title],"root kept: "+title)
        if node==null: continue
        var p: Vector3=Interior.mirror_point(station.to_local(node.global_position))
        check(p.x>33.1 and p.x<52.9 and p.z>37.6 and p.z<59.4,"inside walls: "+title)
        var found:=false
        for r in [.8,1.1,1.5,2.0]:
            for a in range(16):
                var q:=p+Vector3(cos(a*TAU/16)*r,0,sin(a*TAU/16)*r)
                if q.x>33.4 and q.x<52.6 and q.z>37.9 and q.z<59.1 and clear_at(space,station,Vector3(q.x,0,q.z)): found=true
            if found: break
        check(found,"reachable standing spot: "+title)
    for door in ["Interview room","Holding cell","Lineup room door"]:
        var node: Node3D=station.get_node_or_null(door)
        var registered:=false
        for key in game.doors:
            if key is Node and node!=null and (key==node or node.is_ancestor_of(key) or (key as Node).is_ancestor_of(node)): registered=true
        check(registered,"working door kept: "+door)
    # Records cabinets now stand in the equipment alcove; the pig works the reception desk.
    for k in ["Records cabinet","Records cabinet2","Records cabinet3"]:
        var p: Vector3=Interior.mirror_point((station.get_node(k) as Node3D).position)
        check(p.x>Interior.INTERVIEW_RIGHT and p.x<Interior.RECORDS_RIGHT and p.z>Interior.ROW,"cabinet in equipment alcove: "+k)
    var tagged:={}
    for node in station.get_node("Interior").find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): tagged[String(node.get_meta("word_key"))]=true
    for word in ["map","coffee maker","cup","shelf","toilet"]:
        check(tagged.has(word),"interior word tagged: "+word)
    var open_spots:={"door gap":Vector3(43,0,38.2),"entry":Vector3(43,0,41.0),"lobby":Vector3(43,0,45.5),"lobby rear":Vector3(43,0,49.0),"before the rear rooms":Vector3(43,0,51.0),"interview door":Vector3(34.47,0,50.9),"cell door":Vector3(43.7,0,50.9),"waiting chairs":Vector3(47.7,0,39.2),"reception customers":Vector3(49.0,0,41.6),"poster viewing":Vector3(51.0,0,46.0),"coffee counter":Vector3(51.6,0,47.2),"inside interview":Vector3(34.5,0,53.0),"inside cell":Vector3(43.7,0,53.2),"lineup viewing":Vector3(49.0,0,53.4),"evidence counter, lobby side":Vector3(40.6,0,43.5),"inside evidence room":Vector3(38.3,0,46.2),"corridor":Vector3(37.0,0,49.5)}
    for label in open_spots:
        check(clear_at(space,station,open_spots[label]),"walkable: "+label)
    var solids:={"reception desk":Vector3(50.6,0,41.6),"interview front wall":Vector3(37.2,0,52.0),"steel shelving":Vector3(41.2,0,54.6),"lockers":Vector3(39.55,0,59.05),"coffee cabinet":Vector3(52.58,0,49.5),"evidence counter":Vector3(39.4,0,43.5),"lineup front wall":Vector3(48.0,0,52.0),"lineup door, closed":Vector3(51.7,0,52.0)}
    # 8 Nov 2026 lobby rearrangement (police.gd lobby_layout): the second workstation and its
    # OFFICERS sign are gone; the lineup front wall has a dark window; the reception backs onto the wall.
    for gone in ["Officer workstation surface2","Police monitor2","Chair13","OFFICERS upgrade sign"]:
        check(station.find_child(gone,true,false)==null,"removed: "+gone)
    # The reception stands 1.7 out from the side wall with the beagle officer behind it, facing the
    # lobby; every chair is one modelled mesh (legs included) and the separate back boxes are gone.
    var officer:=station.get_node_or_null("ReceptionOfficer") as Node3D
    check(officer!=null and String(officer.get_meta("word_key",""))=="police officer","reception officer: police officer")
    if officer!=null:
        var desk_x: float=(station.get_node("Police reception") as Node3D).position.x
        check(officer.position.x<desk_x-1.0 and officer.position.x>33.5 and officer.global_basis.z.dot(station.global_basis.x)<-.9,"reception officer behind the desk, facing the lobby")
    for chair in ["Chair9","Chair10","Chair11","Chair12","Chair14","Chair15"]:
        var node:=station.get_node_or_null(chair) as Node3D
        var mesh:MeshInstance3D=null
        if node!=null:
            for child in node.get_children():
                if child is MeshInstance3D: mesh=child
        check(mesh!=null and mesh.mesh!=null and mesh.mesh.get_aabb().position.y<-.44,"chair has legs to the floor: "+chair)
    check(station.find_child("Chair back*",true,false)==null,"old chair back boxes gone")
    var window_node:=station.get_node_or_null("Lineup observation window")
    check(window_node!=null and String(window_node.get_meta("word_key",""))=="window","lineup window tagged: window")
    var poster:=station.get_node_or_null("Interior/Police poster appearance") as Node3D
    check(poster!=null and Interior.mirror_point(poster.position).x>52.7 and absf(poster.position.z-46.0)<.1,"word poster on the lobby side wall")
    for label in solids:
        check(not clear_at(space,station,solids[label]),"solid: "+label)
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in station.find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(english.is_valid_int() or table.has(english) or english.ends_with("• E") or english==String(label.get_meta("sign_spanish",english)),"sign readable: "+english)
    print("police interior checks: ",checks," failures: ",failures)
    quit(1 if failures>0 else 0)
