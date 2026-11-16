extends SceneTree
## 1 Nov 2026 library refresh: dictionary and atlas on the west-wall reference table, map on
## the wall above, returns bin by the desk, wainscot, story ledge. Run with the README's
## isolated user directory (Main saves progress):
## godot --headless --path . --script res://docs/evidence/library-refresh-20261101/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
## Library-local bounds of every mesh under `node`.
func bounds(library: Node3D,node: Node3D) -> AABB:
    var out:=AABB()
    var first:=true
    for mesh in node.find_children("*","MeshInstance3D",true,false):
        var box: AABB=library.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
        out=box if first else out.merge(box)
        first=false
    return out
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var library: Node3D=game.apartment.get_node("RelocatedSites/Library")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var words: Dictionary=preload("res://scripts/learning/word_data.gd").load_all().vocabulary
    check(library.has_node("LibraryRefresh"),"refresh built once")
    # --- word roots keep their names and keys, sit on the table and answer a pick ray
    var table:=AABB(Vector3(-20.78,.86,38.8),Vector3(.75,1,2.8))
    for spec in [["Dictionary","dictionary"],["Atlas","atlas"]]:
        var node: Node3D=library.get_node(spec[0])
        check(str(node.get_meta("word_key",""))==spec[1] and words.has(spec[1]),spec[0]+" word key")
        var box:=bounds(library,node)
        check(box.position.y>=.86 and table.encloses(AABB(box.position,box.size*Vector3(1,0,1))),spec[0]+" rests on the reference table "+str(box))
        var target: Vector3=library.to_global(box.get_center())
        var query:=PhysicsRayQueryParameters3D.create(library.to_global(Vector3(-18.9,1.55,box.get_center().z)),target)
        query.collide_with_areas=true
        var hit:=space.intersect_ray(query)
        var word:=""
        if hit: word=str(hit.collider.get_meta("word",""))
        check(word==spec[1],spec[0]+" picked by a ray from the aisle (got '%s')"%word)
    var map: Node3D=library.get_node("World_Map")
    var map_box:=bounds(library,map)
    check(str(map.get_meta("word_key",""))=="map" and map_box.position.x>-20.9 and map_box.end.x<-20.7 and map_box.position.y>1.4,"map hangs on the west wall "+str(map_box))
    check(not map.has_node("Footprint") and not map.has_node("Stand_11"),"map easel stand removed")
    var bin:=bounds(library,library.get_node("Book Bin"))
    for title in ["Book Bin2","Book Bin3","Book Bin4","Book Bin5"]: bin=bin.merge(bounds(library,library.get_node(title)))
    check(bin.position.y<.06 and bin.position.y>.0 and bin.get_center().distance_to(Vector3(-13.1,.27,50.55))<.1,"book bin on the floor by the desk "+str(bin))
    # --- signs: placards and new boards translate
    var texts:={}
    for label in library.find_children("*","Label3D",true,false): texts[label.text]=true
    for text in ["DICCIONARIO","ATLAS","MAPA","CONSULTA","DEVOLUCIONES"]: check(texts.has(text),"sign reads "+text)
    # --- player-sized capsule routes (library-local; the site is scaled 1.3 in town)
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.3
    capsule.height=1.6
    var shape:=PhysicsShapeQueryParameters3D.new()
    shape.shape=capsule
    shape.collide_with_areas=false
    for route in [[Vector2(-15,38.2),Vector2(-15,49.9),"entrance spine"],[Vector2(-15,38.6),Vector2(-19.3,39.6),"door to reference table"],
            [Vector2(-19.3,38.9),Vector2(-19.3,41.4),"along the reference table"],[Vector2(-19.5,47),Vector2(-10.5,47),"rear cross aisle"],
            [Vector2(-15,49.6),Vector2(-13.1,49.6),"returns bin"],[Vector2(-9.75,38.7),Vector2(-9.75,41.3),"story ledge"]]:
        var blocked:=""
        for i in range(41):
            var p: Vector2=route[0].lerp(route[1],i/40.0)
            shape.transform=Transform3D(library.global_basis.orthonormalized(),library.to_global(Vector3(p.x,1.0,p.y)))
            var hits:=space.intersect_shape(shape,1)
            if not hits.is_empty():
                blocked="%s at %s"%[hits[0].collider.get_parent().name,p]
                break
        check(blocked=="","route "+route[2]+" clear "+blocked)
    print("LIBRARY REFRESH: %d checks, %d failures"%[checks,failures])
    quit(1 if failures else 0)
