extends SceneTree
## Farm barn rebuild (1 Nov 2026): gambrel shell, hayloft, ladder and barn words; the ladder
## turned to face the door and the paddock shelter/trough rebuilt the same day. Drives Main
## with real key events (W, S). Main saves progress: run with an isolated user directory (README).
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/barn-20261101/verify.gd
const BARN = preload("res://scripts/buildings/barn.gd")
var failures:=0
var checks:=0
var game
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    print(("PASS: " if ok else "FAIL: ")+label)
    if not ok: failures+=1
func key(code: Key,pressed: bool) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=pressed
    Input.parse_input_event(event)
func run() -> void:
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    for i in range(10): await physics_frame
    var town: Node3D=game.apartment
    var site: Node3D=town.get_node("Barn")
    var building: Node3D=site.get_node("Barn")
    var barn: Node3D=building.get_node_or_null("Barn interior")
    check(barn!=null,"barn interior built")
    # --- old shell replaced; foundation, site and footprint kept
    for title in BARN.OLD_SHELL: check(building.get_node_or_null(title)==null,"old "+title+" removed")
    for title in ["GableLeft","GableRight"]: check(site.get_node_or_null(title)==null,"old "+title+" removed")
    var foundation: MeshInstance3D=building.get_node("Foundation")
    check((foundation.mesh as BoxMesh).size.is_equal_approx(Vector3(12,.1,9)),"12 × 9 foundation kept")
    check(not site.get_node("FarmSign").visible,"old floating FARM label hidden")
    var roof: MeshInstance3D=building.get_node_or_null("MainRoof")
    check(roof!=null,"slate MainRoof for the map facade")
    if roof:
        var box: AABB=roof.get_aabb()
        print("roof local ",box)
        check(box.end.y>10.6 and box.end.y<10.8,"gambrel ridge at %.2f (walls 5.0 → eave 6.0, ridge 10.5)"%box.end.y)
    check(town.get_node_or_null("Map facades/FARM BARN")!=null,"map facade entry kept")
    var labels: Array=barn.find_children("Barn sign lettering","Label3D",true,false)
    check(labels.size()==1 and String(labels[0].text) in ["FARM BARN","GRANERO"],"FARM BARN sign over the doors")
    # --- words
    var words:={}
    for node in building.find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): words[String(node.get_meta("word_key"))]=words.get(String(node.get_meta("word_key")),0)+1
    print("barn words ",words)
    for word in ["hay","rake","shovel","broom","wheelbarrow","bucket","barrel","watering can","ladder","crate","shelf","lamp"]:
        check(words.has(word) and game.vocabulary.has(word),"teaches "+word)
    for node in building.find_children("*","Node3D",true,false):
        if node.get_meta("word_key","")=="wheelbarrow":
            game.interaction.show_word(node)
            check(game.hud.current_spanish==game.vocabulary["wheelbarrow"],"study card shows "+str(game.hud.current_spanish))
            break
    check(barn.find_children("*","OmniLight3D",true,false).size()==4,"four pendant lamp lights")
    # --- floors: ground planks, loft deck, open notch, roof over it all
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    for spec in [["ground floor",Vector3(-2.5,9,-2.5),BARN.FLOOR],["doorway",Vector3(0,9,-4.2),BARN.FLOOR],["loft west",Vector3(-3,9,2.8),BARN.LOFT],["loft east",Vector3(3.5,9,2.0),BARN.LOFT],["loft lane",Vector3(0,9,3),BARN.LOFT],["ladder notch",Vector3(0,9,1.2),BARN.FLOOR],["notch back",Vector3(0,9,BARN.NOTCH_Z-.1),BARN.FLOOR],["loft past notch",Vector3(0,9,BARN.NOTCH_Z+.2),BARN.LOFT]]:
        var from: Vector3=barn.to_global(spec[1])
        var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+Vector3.DOWN*30))
        var y: float=barn.to_local(hit.position).y if not hit.is_empty() else -1.0
        check(absf(y-spec[2])<.06,"%s floor at %.2f (expected %.2f)"%[spec[0],y,spec[2]])
    for x in [-5.0,-2.0,.5,3.0]:
        var sky: Vector3=barn.to_global(Vector3(x,30,0))
        var top:=space.intersect_ray(PhysicsRayQueryParameters3D.create(sky,sky+Vector3.DOWN*40))
        var y: float=barn.to_local(top.position).y if not top.is_empty() else -1.0
        check(y>BARN.EAVE+.5,"roof closes the top at x %.1f (hit %.2f)"%[x,y])
    # --- ladder at the back of the notch, facing the door (+Z south into the notch)
    var ladder: Node3D=barn.get_node("Barn ladder")
    var facing: Vector3=barn.global_basis.inverse()*ladder.global_basis.z
    check(ladder.is_in_group("ladders") and is_equal_approx(float(ladder.get_meta("ladder_height")),BARN.LOFT-BARN.FLOOR),"ladder contract: group and ladder_height %.2f"%float(ladder.get_meta("ladder_height")))
    check(facing.z<-.99 and ladder.position.z>BARN.LOFT_Z and ladder.position.z<BARN.NOTCH_Z,"ladder faces the door from the back of the notch (+Z %s, z %.2f)"%[facing,ladder.position.z])
    check(ladder.get_meta("ladder_exit","")=="forward","ladder steps off forward onto the loft")
    # --- the doorway and the route to the ladder are clear for BonBon
    var body: CapsuleShape3D=game.player.get_node("PlayerCollision").shape
    var blocked:=0
    for i in range(29):
        var p:=Vector3(0,BARN.FLOOR,lerpf(-6.0,ladder.position.z-.45,i/28.0))
        var probe:=PhysicsShapeQueryParameters3D.new()
        probe.shape=body
        probe.transform=Transform3D(Basis.IDENTITY,barn.to_global(p)+Vector3.UP*(body.height*.5+.08))
        probe.exclude=[game.player.get_rid()]
        if not space.intersect_shape(probe,1).is_empty(): blocked+=1
    check(blocked==0,"doorway to ladder route clear (%d blocked)"%blocked)
    # --- hold W from inside the doorway: walk in, grab the ladder, climb, step off on the loft
    var walker=game.player
    walker.global_position=barn.to_global(Vector3(0,BARN.FLOOR+.05,-3.8))
    walker.velocity=Vector3.ZERO
    var heading: Vector3=barn.to_global(Vector3(0,0,1))-barn.to_global(Vector3.ZERO)
    walker.camera_yaw=atan2(-heading.x,-heading.z)
    walker.camera_rig.rotation.y=walker.camera_yaw
    for i in range(10): await physics_frame
    key(KEY_W,true)
    var climbed:=false
    var faced_loft:=true
    var clinging:=0
    var highest:=-INF
    for i in range(600):
        await physics_frame
        if walker.ladder_node!=null:
            climbed=true
            clinging+=1
            # BonBon's front is her −Z; once turned (~20 frames) she faces north, into the loft.
            var front: Vector3=barn.global_basis.inverse()*(-walker.global_basis.z)
            if clinging>20 and front.z<.7: faced_loft=false
        highest=maxf(highest,barn.to_local(walker.global_position).y)
    key(KEY_W,false)
    for i in range(30): await physics_frame
    var up: Vector3=barn.to_local(walker.global_position)
    print("climb end ",up," highest ",highest)
    check(climbed,"W at the ladder starts climbing")
    check(faced_loft,"climbs facing the ladder and the loft, back to the door")
    check(absf(up.y-BARN.LOFT)<.1 and up.z>BARN.NOTCH_Z,"ends standing on the loft (y %.2f, z %.2f)"%[up.y,up.z])
    # --- hold S on the loft: walk back into the notch and drop to the ground floor
    key(KEY_S,true)
    for i in range(300):
        await physics_frame
        if barn.to_local(walker.global_position).y<.5: break
    key(KEY_S,false)
    for i in range(30): await physics_frame
    var down: Vector3=barn.to_local(walker.global_position)
    print("drop end ",down)
    check(absf(down.y-BARN.FLOOR)<.1 and absf(down.z)<BARN.IN_Z,"drops back through the notch to the ground floor (y %.2f, z %.2f)"%[down.y,down.z])
    # --- paddock: the shelter roof on four posts, the trough on skids
    var zoo: Node3D=town.get_node("ParkZoo")
    var shelter: Node3D=zoo.get_node("Shelter roof")
    check(shelter.get_meta("word_key","")=="shelter","shelter roof keeps its word")
    var under:=0
    for k in ["","2","3","4"]:
        var post: Node3D=zoo.get_node_or_null("Shelter post"+k)
        if post==null: continue
        var head: Vector3=shelter.to_local(post.to_global(Vector3(0,1.35,0)))
        print("shelter post",k," head in roof frame ",head)
        if absf(head.x)<1.8 and absf(head.z)<1.3 and absf(head.y)<.15: under+=1
    check(under==4,"four posts carry the shelter roof (%d)"%under)
    check(zoo.find_children("Shelter back plank*","Node3D",false,false).size()==4,"plank back wall")
    var trough: Node3D=zoo.get_node("Water trough")
    var ground:=space.intersect_ray(PhysicsRayQueryParameters3D.create(trough.to_global(Vector3(0,-.32,0)),trough.to_global(Vector3(0,-3,0))))
    var lift: float=trough.to_global(Vector3(0,-.3,0)).y-ground.position.y if not ground.is_empty() else -1.0
    check(lift>.04 and zoo.find_children("Trough skid*","Node3D",false,false).size()==2,"trough raised %.2f on two skids"%lift)
    check(zoo.get_node("Water surface").to_global(Vector3.ZERO).y>trough.to_global(Vector3(0,.29,0)).y,"water surface on top of the trough")
    check(building.find_children("Barn interior","Node3D",false,false).size()==1,"one barn interior")
    print("BARN VERIFY: ",checks," checks, ",failures," failures")
    quit(0 if failures==0 else 1)
