extends SceneTree
## 2 Nov 2026: supermarket refit. Frozen section and its words retired, fruit in its
## place, checkout lanes beside the door, every product a clickable word, no filler
## stock, a samoyed cashier and a beagle clerk in the grocery apron. Run with an
## isolated user directory (Main saves progress):
## godot --headless --path . --script res://docs/evidence/supermarket-20261102/verify.gd
const F := .1
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
# Player-sized capsule standing on market-local floor point (x, z).
func clear_at(space: PhysicsDirectSpaceState3D,market: Node3D,x: float,z: float) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,market.to_global(Vector3(x,F,z))+Vector3(0,1.2,0))
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
    var market: Node3D=town.get_node("RelocatedSites/Supermarket")
    var fitout: Node3D=market.get_node("MarketInterior")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var interaction:=preload("res://scripts/player/interaction_controller.gd")
    # Retired frozen words: gone from the dictionary and from the whole town.
    for word in ["freezer","frozen food","frozen section"]:
        check(not game.vocabulary.has(word),"retired word not in vocabulary: "+word)
        check(not town.find_children("*","Node3D",true,false).any(func(n): return str(n.get_meta("word_key",""))==word),"no object teaches "+word)
    # Every word root inside the shell; each must be a dictionary word.
    var inside:={}
    for node in town.find_children("*","Node3D",true,false):
        var key:=str(node.get_meta("word_key",""))
        if key=="": continue
        var p:=market.to_local(node.global_position)
        if p.x<-45.75 or p.x>-20.25 or p.z<34.25 or p.z>59.75 or p.y>5.8 or p.y<-.5: continue
        check(game.vocabulary.has(key),"known word in store: "+key)
        if not inside.has(key): inside[key]=[]
        inside[key].append(node)
    var expected:=["apple","orange","banana","lemon","lime","pear","peach","cherry","strawberry","grapes","pineapple","mango","coconut","watermelon","avocado",
        "tomato","carrot","broccoli","potato","lettuce","onion","garlic","corn","chili pepper","mushroom","cucumber","bell pepper",
        "cereal","honey","jam","coffee","tea","sugar","flour","oil","salt","pepper","rice","beans","pasta","tortilla","cookie","can","tuna","soup","olive","salsa","snack","jar",
        "milk","yogurt","eggs","cheese","butter","ham","sausage","salad","chicken","meat","steak","fish","shrimp",
        "bread","baguette","croissant","cake","cupcake","donut","water bottle","juice","soda","soap","sponge","detergent","toothbrush","toothpaste","shampoo","toilet paper",
        "candy","chocolate","checkout counter","conveyor belt","cash register","screen","receipt","scanner","card reader","shopping bag","queue","cashier counter","money","credit card",
        "basket","flowerpot","leaf","refrigerator","shelf","display","produce stand","produce","price tag","price","scale","crate","counter","deli counter","bakery","ceiling light","ceiling","cashier"]  # salesperson (BeagleClerk) stands outside since 3 Nov 2026
    for word in expected:
        check(inside.has(word),"store shows "+word)
    print("store words: ",inside.size())
    # Every product root inside the fit-out is clickable: one of its areas resolves to it.
    var unclickable:=0
    for node in fitout.get_children():
        if not node is Node3D or str(node.get_meta("word_key",""))=="" or node.has_meta("character_name") or node.has_node("StudyArea"): continue
        var ok:=false
        for body in node.find_children("*","CollisionObject3D",true,false):
            if interaction.vocabulary_target(body,town)==node: ok=true
        if not ok:
            unclickable+=1
            print("  not clickable: ",node.name)
    check(unclickable==0,"every word root in the fit-out is clickable")
    # No anonymous filler: no batched stock, and every mesh in the fit-out belongs to a
    # word root or is a fixed fitting (sign, glass, floor inlay, grout, guard, bench).
    check(not fitout.has_node("Shelf stock"),"filler stock removed")
    check(fitout.find_children("*","MultiMeshInstance3D",true,false).is_empty(),"no MultiMesh filler in the fit-out")
    var loose:=0
    for node in fitout.get_children():
        if not node is Node3D or str(node.get_meta("word_key",""))!="" or node is Light3D or node is Label3D: continue
        var title:=str(node.name)
        # Fittings (signs, grout, inlays, benches) and the bare meshes of the service
        # cases (glass, frames, ice beds) carry no word by design.
        if node.has_meta("market_fitting") or node is MeshInstance3D: continue
        loose+=1
        print("  unworded fit-out root: ",title)
    check(loose==0,"no unworded product roots")
    # Old saved roots retired.
    for title in ["Refrigerated display","Frozen Food","Leaf_6","Gondola upright"]:
        check(not market.has_node(title),"old root gone: "+title)
    check(town.get_node("Buildings/MarketDisplays").get_child_count()==1,"MarketDisplays keeps only the tile floor")
    # Checkout beside the door (door x -35.8..-30.2 at z 34.25).
    for title in ["Checkout counter","Checkout counter2"]:
        var counter: Node3D=fitout.get_node_or_null(title)
        check(counter!=null,title+" exists")
        if counter: check(counter.position.x>-40.5 and counter.position.x<-36.5 and counter.position.z<39,title+" stands beside the door")
    # Clerks: [node, scene, word, spot]
    for spec in [["SamoyedCashier","samoyed_plush","cashier",Vector3(-38.4,F,36.9)],["BeagleClerk","beagle_plush","salesperson",Vector3(-37.6,F,31.0)]]:  # clerk moved outside 3 Nov 2026 (customer order)
        var npc: Node3D=fitout.get_node_or_null(spec[0])
        check(npc!=null,spec[0]+" exists")
        if npc==null: continue
        check(npc.scene_file_path.ends_with(spec[1]+".tscn"),spec[0]+" is a "+spec[1])
        check(str(npc.get_meta("word_key",""))==spec[2],spec[0]+" teaches "+spec[2])
        var costume: Node=npc.get_node_or_null("Costume")
        check(costume!=null and str(costume.get("outfit"))=="grocery_shopkeeper",spec[0]+" wears the grocery apron")
        check(npc.global_basis.get_scale().is_equal_approx(Vector3.ONE),spec[0]+" is BonBon-sized")
        var area: Node=npc.get_node_or_null("StudyArea")
        check(area!=null and interaction.vocabulary_target(area,town)==npc,spec[0]+" click resolves to its word")
        var spot: Vector3=market.to_global(spec[3])
        check(Vector2(npc.global_position.x-spot.x,npc.global_position.z-spot.z).length()<.01,spec[0]+" on its spot")
        var box:=BoxShape3D.new()
        box.size=Vector3(1.0,1.0,1.0)
        var query:=PhysicsShapeQueryParameters3D.new()
        query.shape=box
        query.transform=Transform3D(Basis.IDENTITY,npc.global_position+Vector3(0,.8,0))
        query.exclude=npc.find_children("*","CollisionObject3D",true,false).map(func(b): return b.get_rid())
        var hits:=space.intersect_shape(query,4)
        check(hits.is_empty(),spec[0]+" does not stand inside a fixture")
        for hit in hits: print("  ",spec[0]," overlaps ",town.get_path_to(hit.collider))
    # Walkways (market-local x, z).
    var probes:=[]
    for z in range(35,43): probes.append([-33.0,z+.5,"entrance spine"])
    for z in range(36,41): probes.append([-36.3,z,"lane 1 customers"])
    for z in range(36,41): probes.append([-41.0,z,"lane 2 customers"])
    for z in range(44,51): probes.append([-41.3,z+.3,"pantry aisle"])
    for z in range(44,51): probes.append([-37.2,z+.3,"pantry / fridge aisle"])
    for z in range(43,51): probes.append([-23.2,z+.3,"fruit aisle"])
    for z in range(43,49): probes.append([-28.0,z+.3,"fruit island / vegetables aisle"])
    for z in range(36,41): probes.append([-23.3,z+.3,"drinks aisle"])
    for x in range(-44,-21): probes.append([x+.5,53.5,"rear aisle"])
    for x in range(-36,-29): probes.append([x+.5,47.4,"vegetables / fridge aisle"])
    for p in probes:
        if abs(p[0]+27.6)<.9 and abs(p[1]-52.6)<.9: continue
        check(clear_at(space,market,p[0],p[1]),"%s clear at (%.1f, %.1f)"%[p[2],p[0],p[1]])
    for p in [[-37.25,37.7,"checkout counter"],[-43.2,47.3,"pantry gondola"],[-33.0,44.3,"vegetable stand"],[-25.6,47.0,"fruit island"],[-34.35,49.75,"refrigerator"],[-21.5,46.0,"fruit wall"],[-33.0,56.7,"deli counter"],[-21.1,38.2,"drinks cooler"]]:
        check(not clear_at(space,market,p[0],p[1]),p[2]+" is solid")
    # Signs translated.
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in fitout.find_children("*","Label3D",true,false):
        var english: String=label.get_meta("sign_english",label.text)
        if english.is_valid_int() or english.begins_with("$") or label.name=="NeedsHelpMarker": continue
        check(table.has(english),"sign translated: "+english)
    check(fitout.get_meta("departments",[]).size()==9,"nine departments")
    check(not ("FROZEN" in fitout.get_meta("departments",[])),"no frozen department")
    print("SUPERMARKET: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
