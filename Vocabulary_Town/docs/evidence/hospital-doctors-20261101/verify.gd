extends SceneTree
## 1 Nov 2026: three ward doctors (BonBon's pig, a cat and a beagle in the doctor outfit)
## beside the reception sheep doctor. Run with the README's isolated user directory
## (Main saves progress): godot --headless --path . --script res://docs/evidence/hospital-doctors-20261101/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
# Room-local bounds of every visible mesh under `node` (town units).
func local_bounds(room: Node3D,node: Node3D) -> AABB:
    var to_room:=room.global_transform.affine_inverse()
    var meshes:=node.find_children("*","MeshInstance3D",true,false)
    if node is MeshInstance3D: meshes.append(node)
    var bounds:=AABB()
    var first:=true
    for mesh in meshes:
        if not mesh.is_visible_in_tree(): continue
        var box: AABB=mesh.get_aabb()
        for i in range(8):
            var p: Vector3=to_room*(mesh.global_transform*box.get_endpoint(i))
            if first: bounds=AABB(p,Vector3.ZERO)
            else: bounds=bounds.expand(p)
            first=false
    return bounds
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    var hospital: Node3D=town.get_node("Buildings/Hospital")
    await physics_frame
    await physics_frame
    var interaction:=preload("res://scripts/player/interaction_controller.gd")
    var sheep: Node3D=hospital.get_node_or_null("Floor1/Room1/SheepDoctor")
    check(sheep!=null and sheep.scene_file_path.ends_with("sheep_plush.tscn") and String(sheep.get_meta("word_key",""))=="doctor","reception sheep doctor is unchanged")
    check(sheep!=null and sheep.global_basis.get_scale().is_equal_approx(Vector3.ONE),"reception sheep doctor keeps world scale 1")
    # [node name, room, species scene]
    var doctors:=[
        ["BonBonDoctor","Floor1/Room3","pig_plush"],
        ["CatDoctor","Floor2/Room3","cat_plush"],
        ["BeagleDoctor","Floor3/Room1","beagle_plush"],
    ]
    var species:={}
    for spec in doctors:
        var room: Node3D=hospital.get_node(spec[1])
        var npc: Node3D=room.get_node_or_null(spec[0])
        check(npc!=null,spec[0]+" exists in "+spec[1])
        if npc==null: continue
        check(hospital.find_children(spec[0],"",true,false).size()==1,spec[0]+" name is unique in the hospital")
        check(npc.scene_file_path.ends_with(spec[2]+".tscn"),spec[0]+" is a "+spec[2])
        species[spec[2]]=true
        check(String(npc.get_meta("word_key",""))=="doctor",spec[0]+" teaches doctor")
        var costume: Node=npc.get_node_or_null("Costume")
        check(costume!=null and String(costume.get("outfit"))=="doctor",spec[0]+" wears the doctor outfit")
        check(npc.global_basis.get_scale().is_equal_approx(Vector3.ONE),spec[0]+" is BonBon-sized (world scale 1)")
        var area: Node=npc.get_node_or_null("StudyArea")
        check(area!=null and interaction.vocabulary_target(area,town)==npc,spec[0]+" click resolves to its word")
        # Body bounds, costume excluded (it never moves a plush): on the floor, inside the
        # room, clear of the doorway lane and of every fixture standing in the room.
        var body:=AABB()
        var first:=true
        for part in npc.get_children():
            if part is Node3D and part.name!="Costume" and part.name!="StudyArea":
                var b:=local_bounds(room,part)
                if b.size==Vector3.ZERO: continue
                body=b if first else body.merge(b)
                first=false
        print(spec[0]," room-local body ",body.position," .. ",body.end)
        check(absf(body.position.y)<.04,spec[0]+" stands on the floor (lowest point %.3f)" % body.position.y)
        check(body.position.x>-3.3 and body.end.x<3.3 and body.position.z>-3.6 and body.end.z<3.6,spec[0]+" stays inside its room")
        # Doorway at local x -3.5; BonBon (1.9 world = 1.46 town wide) walks in along |z|<0.9.
        check(not body.intersects(AABB(Vector3(-3.6,0,-.9),Vector3(2.6,3,1.8))),spec[0]+" leaves the doorway lane clear")
        var hits:=[]
        for item in room.get_children():
            if item==npc or not item is Node3D: continue
            var b:=local_bounds(room,item)
            if b.size==Vector3.ZERO or b.end.y<.1: continue
            if body.grow(-.03).intersects(b): hits.append(str(item.name))
        check(hits.is_empty(),spec[0]+" overlaps no furniture "+str(hits))
    check(species.size()==3 and not species.has("sheep_plush"),"three different species, none a sheep")
    check(hospital.find_children("*Doctor","",true,false).size()==4,"hospital has exactly four plush doctors")
    print("HOSPITAL DOCTORS: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
