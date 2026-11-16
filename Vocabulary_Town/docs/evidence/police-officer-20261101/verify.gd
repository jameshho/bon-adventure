extends SceneTree
## 1 Nov 2026: the blocky police officer is retired; a crocodile plush in the police
## uniform waits beside the station entrance and teaches "police officer".
## Updated 6 Nov 2026: the crocodile works INSIDE the enlarged station (lineup game) and a cat
## officer works the evidence counter; both teach "police officer". Since 8 Nov a beagle
## receptionist in the lobby teaches it too. Run with the
## README's isolated user directory (Main saves progress):
## godot --headless --path . --script res://docs/evidence/police-officer-20261101/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
# True when no solid collides with a box of `size` at global `xform` (world units).
func box_clear(space: PhysicsDirectSpaceState3D,xform: Transform3D,size: Vector3,own: Node=null) -> bool:
    var box:=BoxShape3D.new()
    box.size=size
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=box
    query.transform=xform
    if own!=null:
        var rids: Array[RID]=[]
        for body in own.find_children("*","CollisionObject3D",true,false): rids.append(body.get_rid())
        query.exclude=rids
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
    var interaction:=preload("res://scripts/player/interaction_controller.gd")
    check(game.vocabulary.has("police officer"),"police officer is a word")
    var teachers:=[]
    var old:=[]
    for node in town.find_children("*","Node3D",true,false):
        if node.scene_file_path.ends_with("police_officer.tscn"): old.append(town.get_path_to(node))
        if String(node.get_meta("word_key",""))=="police officer": teachers.append(node)
    check(old.is_empty(),"old officer retired "+str(old))
    var npc: Node3D=town.get_node_or_null("People/CrocodilePoliceOfficer")
    check(npc!=null,"crocodile police officer exists in People")
    var cat: Node3D=town.get_node_or_null("People/CatEvidenceOfficer")
    # 8 Nov 2026: the beagle receptionist (police.gd step reception_officer_chairs) is a third officer.
    var receptionist: Node3D=town.get_node_or_null("RelocatedSites/Police/ReceptionOfficer")
    if teachers.size()!=3:
        print("  police officer roots: ",teachers.map(func(t): return str(town.get_path_to(t))))
    check(teachers.size()==3 and teachers.has(npc) and teachers.has(cat) and teachers.has(receptionist),"three police officer word roots: the crocodile, the cat and the beagle receptionist")
    if npc==null:
        print("POLICE OFFICER: ",failures," failures; ",checks," checks")
        quit(1)
        return
    check(npc.scene_file_path.ends_with("crocodile_plush.tscn"),"officer is the crocodile plush")
    var costume: Node=npc.get_node_or_null("Costume")
    check(costume!=null and String(costume.get("outfit"))=="police","officer wears the police outfit")
    check(costume!=null and costume.find_child("Cap*",true,false)!=null and costume.find_child("Badge*",true,false)!=null,"uniform has cap and badge")
    check(npc.global_basis.get_scale().is_equal_approx(Vector3.ONE),"officer is BonBon-sized (world scale 1)")
    var area: Node=npc.get_node_or_null("StudyArea")
    check(area!=null and interaction.vocabulary_target(area,town)==npc,"click resolves to police officer")
    # Placement: inside, in the lobby in front of the holding cell and lineup room.
    var station: Node3D=town.get_node("RelocatedSites/Police")
    var Interior=preload("res://scripts/buildings/police.gd")
    var spot: Vector3=station.to_global(Interior.mirror_point(Interior.LINEUP_OFFICER_SPOT))
    check(Vector2(npc.global_position.x-spot.x,npc.global_position.z-spot.z).length()<.01,"officer stands on its spot (moved with the site)")
    var local:=station.to_local(npc.global_position)
    check(local.z>37.62 and local.z<Interior.ROW and local.x>Interior.LEFT and local.x<Interior.RIGHT,"officer is inside the lobby")
    var toward_door:=(station.global_basis*Vector3(0,0,-1)).normalized()
    check((-npc.global_basis.z).normalized().dot(toward_door)>.98,"officer faces the lobby and the door")
    var body:=Transform3D(npc.global_basis.orthonormalized(),npc.global_position+Vector3(0,.8,0))
    check(box_clear(space,body,Vector3(.8,1.0,.8),npc),"officer does not stand inside a fixture or wall")
    # Door corridor: the world-space lane straight out of the door stays free of solids.
    var door:=station.to_global(Vector3(43,0,35.0))
    var lane:=Transform3D(station.global_basis.orthonormalized(),door+Vector3(0,1.0,0))
    check(box_clear(space,lane,Vector3(2.4,1.6,3.0)),"door approach lane is clear")
    var car: Node3D=town.get_node_or_null("Vehicles/Police_Car")
    check(car!=null and car.global_position.distance_to(npc.global_position)>5.0,"police car is well clear of the officer")
    print("POLICE OFFICER: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
