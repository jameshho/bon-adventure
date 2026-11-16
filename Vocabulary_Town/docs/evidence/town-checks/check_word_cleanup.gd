extends SceneTree
## Word clean-up of 28 October 2026: retired objects gone, body words only on the
## anatomy model, home kitchen/bathroom items and room signs, standable trees/clouds.
## godot --headless --path . --script res://docs/evidence/town-checks/check_word_cleanup.gd
func _initialize(): run.call_deferred()
var failures:=0
func check(ok: bool,label: String):
    if not ok:
        failures+=1
        print("FAIL: ",label)
func land(game,above: Vector3) -> float:
    var p=game.player
    p.global_position=above
    p.velocity=Vector3.ZERO
    for i in range(180): await physics_frame
    return p.global_position.y
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var town: Node3D=game.apartment
    var words: Dictionary=preload("res://scripts/learning/word_data.gd").load_all()
    var hospital: Node3D=town.get_node("RelocatedSites/Hospital")
    for n in town.find_children("*","Node3D",true,false):
        var k:=str(n.get_meta("word_key",""))
        if k=="": continue
        check(not k in words.removed_with_objects,"retired object remains: "+str(town.get_path_to(n)))
        check(words.vocabulary.has(k) or words.aliases.has(k),"unknown key "+k+" at "+str(town.get_path_to(n)))
        if k in ["arm","head","torso","foot","hand","nose","leg"]: check(hospital.is_ancestor_of(n),"body word off the anatomy model: "+str(town.get_path_to(n)))
    var home: Node3D=town.get_node("RelocatedSites/Home")
    var found:={}
    for n in home.find_children("*","Node3D",true,false):
        var k:=str(n.get_meta("word_key",""))
        if k!="": found[k]=found.get(k,0)+1
    for w in ["faucet","oven","frying pan","cup","salt","pepper","oil","tea","juice","towel","toothbrush","toilet paper","shampoo","perfume","bedroom","bathroom","kitchen","living room","garage","yard","garden"]:
        check(found.has(w),"home has "+w)
    # Handles were reparented into the cabinetry (Godot may rename them there).
    check(home.find_children("Cabinet handle*","",false,false).is_empty() and home.get_node("Kitchen cabinetry").get_child_count()>=6,"handles are part of the kitchen cabinetry")
    await physics_frame
    await physics_frame
    # Stand on trees and clouds.
    var platforms: Node3D=town.get_node("Tree crown platforms")
    print("tree platforms ",platforms.get_child_count())
    var tested:={}
    for body in platforms.get_children():
        var species:=str(body.get_meta("word"))
        if tested.has(species): continue
        tested[species]=true
        var top: Vector3=body.global_position
        var y: float=await land(game,top+Vector3(0,3,0))
        check(absf(y-(top.y+.2*town.global_basis.get_scale().y))<.6,"stands on "+species+" (y "+str(snappedf(y,.01))+" vs top "+str(snappedf(top.y,.01))+")")
    var cloud: Node3D=null
    for n in town.get_children(): if String(n.name).begins_with("Cloud puff"): cloud=n; break
    var cy: float=await land(game,cloud.global_position+Vector3(0,8,0))
    check(cy>cloud.global_position.y-1,"stands on a cloud (y "+str(snappedf(cy,.1))+" vs "+str(snappedf(cloud.global_position.y,.1))+")")
    print("WORD CLEANUP failures: ",failures)
    quit(1 if failures>0 else 0)
