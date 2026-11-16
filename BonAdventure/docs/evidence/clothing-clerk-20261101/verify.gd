extends SceneTree
## 1 Nov 2026: clothing store clerk (cat plush, boutique apron, *cashier*) and shopper
## (lion plush, *person*) replace the deleted cashier.tscn figures; checkout moved to the
## rear-right counter; stray site-layer items tidied. Run with the README's isolated user
## directory (Main saves progress):
## godot --headless --path . --script res://docs/evidence/clothing-clerk-20261101/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
# Player capsule (world units) standing on store-local floor point p.
func clear_at(space: PhysicsDirectSpaceState3D,store: Node3D,p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,store.to_global(p+Vector3(0,.95+.105,0)))
    return space.intersect_shape(query,1).is_empty()
func box_clear(space: PhysicsDirectSpaceState3D,xform: Transform3D,size: Vector3) -> bool:
    var box:=BoxShape3D.new()
    box.size=size
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=box
    query.transform=xform
    return space.intersect_shape(query,1).is_empty()
func run() -> void:
    check(not ResourceLoader.exists("res://scenes/characters/cashier.tscn"),"cashier.tscn deleted")
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var town: Node3D=game.apartment
    var store: Node3D=town.get_node("Buildings/ClothingStore")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var interaction:=preload("res://scripts/player/interaction_controller.gd")
    check(not town.has_node("People/Cashier"),"old cashier figure gone")
    check(not town.get_node("People").get_children().any(func(c): return c.scene_file_path.ends_with("cashier.tscn")),"no cashier.tscn instance left in People")
    # [node, species scene, word, outfit ("" = none), store-local floor spot]
    for spec in [["CatCashier","cat_plush","cashier","clothing_shopkeeper",Vector3(3.4,.105,6.3)],["LionShopper","lion_plush","person","",Vector3(-1.55,.105,-2.1)]]:
        var npc: Node3D=store.get_node_or_null("Interior/"+spec[0])
        check(npc!=null,spec[0]+" exists")
        if npc==null: continue
        check(npc.scene_file_path.ends_with(spec[1]+".tscn"),spec[0]+" is a "+spec[1])
        check(game.vocabulary.has(spec[2]) and String(npc.get_meta("word_key",""))==spec[2],spec[0]+" teaches "+spec[2])
        var costume: Node=npc.get_node_or_null("Costume")
        if spec[3]=="": check(costume==null,spec[0]+" wears no outfit")
        else: check(costume!=null and String(costume.get("outfit"))==spec[3],spec[0]+" wears "+spec[3])
        check(npc.global_basis.get_scale().is_equal_approx(Vector3.ONE),spec[0]+" is BonBon-sized (world scale 1)")
        var area: Node=npc.get_node_or_null("StudyArea")
        check(area!=null and interaction.vocabulary_target(area,town)==npc,spec[0]+" click resolves to its word")
        var spot: Vector3=store.to_global(spec[4])
        check(Vector2(npc.global_position.x-spot.x,npc.global_position.z-spot.z).length()<.01,spec[0]+" stands on its spot")
        var body:=Transform3D(npc.global_basis.orthonormalized(),npc.global_position+Vector3(0,.8,0))
        check(box_clear(space,body,Vector3(1.2,1.0,1.0)),spec[0]+" does not stand inside a fixture or wall")
    var clerk: Node3D=store.get_node_or_null("Interior/CatCashier")
    if clerk: check((clerk.global_basis.z*-1).dot(store.global_basis.z.normalized()*-1)>.99,"clerk faces the door (−Z local)")
    # Checkout: solid counter, customer side reachable from the right lane, staff way open.
    check(not clear_at(space,store,Vector3(3.4,0,5.25)),"checkout counter is solid")
    check(clear_at(space,store,Vector3(4.0,0,4.5)),"customer spot in front of the counter")
    check(clear_at(space,store,Vector3(4.9,0,6.0)),"staff way behind the counter at the wall end")
    for z in range(-6,5):
        check(clear_at(space,store,Vector3(4.2,0,z)) or absf(z+3.35)<1.2 or absf(z-3.35)<1.2,"right lane z=%d (window stages excepted)"%z)
    for x in [-1.4,1.4]:
        for z in range(-6,6):
            check(clear_at(space,store,Vector3(x,0,z)),"centre lane x=%s z=%d"%[x,z])
    check(not clear_at(space,store,Vector3(-2.7,0,-3.0)) and not clear_at(space,store,Vector3(2.7,0,-3.0)),"gondolas are solid")
    # Learning roots unchanged on the table tops.
    var displays: Node3D=store.get_node("LearningDisplays")
    for title in ["Shirt","Jacket","Sweater","Coat","Pants","Jeans","Shorts","Dress","Skirt","Shoes","Sneakers","Boots","Hat","Belt","Scarf","Handbag","Sunglasses"]:
        var node: Node3D=displays.get_node_or_null(title)
        check(node!=null and node.position.y>.9 and node.position.y<1.2 and absf(node.position.x)<4.2,"root on its table: "+title)
    check(displays.has_node("Shirt/Sleeve_3"),"shirt keeps its sleeve (sleeve)")
    # Site-layer strays.
    var site: Node3D=town.get_node("RelocatedSites/Clothing")
    check(not site.has_node("Sleeve_3"),"stray floating sleeve removed")
    check(not site.has_node("RACK upgrade sign") and not site.has_node("CLOTHES RACK upgrade sign"),"orphan rack captions removed")
    var plaque: Node3D=site.get_node_or_null("Fitting Room plaque")
    check(plaque!=null and String(plaque.get_meta("word_key",""))=="fitting room","fitting-room plaque kept")
    if plaque:
        var p:=store.to_local(plaque.global_position)
        check(p.x<-5.0 and p.x>-5.27 and p.z>4.5 and p.z<7.2,"plaque on the left wall beside the cabins")
    for title in ["Hanger","Hanger2","Hanger3","Hanger4","Mannequin"]:
        check(site.has_node(title),"site word root kept: "+title)
    var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sign_translations.json"))
    for label in store.get_node("Interior").find_children("*","Label3D",true,false):
        var english:String=label.get_meta("sign_english",label.text)
        check(table.has(english),"sign translated: "+english)
    print("CLOTHING CLERK: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
