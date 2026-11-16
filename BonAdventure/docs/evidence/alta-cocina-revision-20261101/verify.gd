extends SceneTree
## 1 Nov 2026 revision of Alta Cocina: clear entrance, reference booths and plain tables,
## quatrefoil floor, 6.5 ceiling, hipped roofs, motorcycle in a car stall. Run with the
## README's isolated user directory (Main saves progress):
## godot --headless --path . --script res://docs/evidence/alta-cocina-revision-20261101/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func named(node: Node,prefix: String) -> Array:
    return node.find_children(prefix+"*","Node3D",true,false)
## Parts are reparented into the shell, so repeated titles get generated names; count the
## box meshes of one exact size instead.
func boxes(node: Node,size: Vector3) -> int:
    return node.find_children("*","MeshInstance3D",true,false).filter(func(m): return m.mesh is BoxMesh and m.mesh.size.is_equal_approx(size)).size()
func clear_at(game,space: PhysicsDirectSpaceState3D,point: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,game.apartment.to_global(point+Vector3(0,.95,0)))
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
    var fine: Node3D=town.get_node("Restaurants/Pizza")
    var facade: Node3D=town.get_node("Map facades/FINE DINING")
    # --- entrance: no mesh of the shell or facade fills the doorway (|x| < 1.7, y .2…3.3)
    var doorway:=AABB(Vector3(-1.6,.2,-8.6),Vector3(3.2,3.1,1.1))
    var blocking:=[]
    for holder in [fine,facade]:
        for mesh in holder.find_children("*","MeshInstance3D",true,false):
            if mesh.mesh==null: continue
            var box: AABB=mesh.get_aabb()
            var local:=AABB(fine.to_local(mesh.to_global(box.position)),Vector3.ZERO)
            for i in range(8): local=local.expand(fine.to_local(mesh.to_global(box.get_endpoint(i))))
            # Render batches (unnamed @Node3D parents) merge many props into one large AABB.
            if String(mesh.get_parent().name).begins_with("@"): continue
            if local.intersects(doorway) and local.size.y>.3: blocking.append(String(mesh.get_parent().name))
    check(blocking.is_empty(),"doorway clear of meshes: "+str(blocking))
    check(boxes(fine,Vector3(.2,1.7,.06))==0 and boxes(fine,Vector3(.2,1.3,.06))==0,"slat dividers removed")
    # --- booths and tables after the reference
    # Batching may merge the decorative parts; the solid shells keep their own nodes.
    check(boxes(fine,Vector3(.6,.44,2.4))==6 and boxes(fine,Vector3(.16,1.3,2.4))==6,"three enlarged booths with cream shells (%d, %d)"%[boxes(fine,Vector3(.6,.44,2.4)),boxes(fine,Vector3(.16,1.3,2.4))])
    # Each bench offers its outer (aisle-end) place, facing across the table.
    var booth_seats: Array=game.seating.seats.filter(func(s): return fine.is_ancestor_of(s.node) and s.node.has_meta("sit_position") and String(s.label)=="bench")
    check(booth_seats.size()==6,"six booth seats registered (%d)"%booth_seats.size())
    for seat in booth_seats:
        var p: Vector3=fine.to_local(seat.point)
        var f: Vector3=(fine.global_basis.inverse()*seat.forward).normalized()
        var table_z: float=[-6.3,-3.6,-.9].reduce(func(a,b): return b if absf(b-p.z)<absf(a-p.z) else a)
        check(p.x>-12.9 and p.x<-12.4 and f.z*signf(table_z-p.z)>.95,"booth seat at the aisle end, facing the table (%s)"%p)
    check(boxes(fine,Vector3(1.22,.02,1.22))==0 and named(fine,"Round tablecloth").size()==1,"square tables are plain wood; round table keeps its cloth")
    var words:={}
    for n in fine.find_children("*","Node3D",true,false):
        if n.has_meta("word_key"): words[String(n.get_meta("word_key"))]=true
    for key in ["tablecloth","table","bench","chair","ceiling"]:
        check(words.has(key),"Alta Cocina still teaches "+key)
    # Each booth's open end is reachable from the room.
    for z in [-6.3,-3.6,-.9]:
        check(clear_at(game,space,town.to_local(fine.to_global(Vector3(-11.6,.08,z)))),"booth aisle clear at z %s"%z)
    # --- floor and ceiling
    check(named(fine,"Floor diamond").is_empty() and fine.find_child("Quatrefoil tile floor",true,false)!=null,"quatrefoil floor replaces the marble")
    var ceiling: Node3D=fine.find_child("Ceiling",true,false)
    check(ceiling!=null and is_equal_approx(snappedf(fine.to_local(ceiling.global_position).y,.01),6.47),"ceiling raised to 6.5")
    var bounds: AABB=game.reference_layout.bounds(fine)
    check(is_equal_approx(snappedf(bounds.size.x,.1),30.6),"building width still 30.6")
    # --- roofs
    for title in ["Dining hip roof","Kitchen hip roof"]:
        var roof: MeshInstance3D=facade.find_child(title,true,false)
        check(roof!=null and roof.mesh!=null and roof.mesh.get_surface_count()==1,title+" built")
    # --- motorcycle: on the restaurant lot, inside a striped stall, off the door aisle
    var bike: Node3D=town.get_node("Vehicles/Motorcycle")
    var lot: AABB=game.reference_layout.bounds(town.get_node("Restaurant parking")).abs()
    var at:=town.to_local(bike.global_position)
    check(Rect2(lot.position.x,lot.position.z,lot.size.x,lot.size.z).grow(-.5).has_point(Vector2(at.x,at.z)),"motorcycle stands on the restaurant lot")
    var door:=town.to_local(fine.to_global(Vector3(0,0,-8.2)))
    check(Vector2(at.x-door.x,at.z-door.z).length()>5.0,"motorcycle clear of the entrance")
    var stripes:=[]
    for node in town.get_children():
        if String(node.name).begins_with("Parking bay stripe") and lot.grow(.2).has_point(node.position): stripes.append(node.position.x)
    var nearest:=INF
    for x in stripes: nearest=minf(nearest,absf(x-at.x))
    check(nearest>1.0 and nearest<2.0,"motorcycle centred between stall stripes (nearest %.2f)"%nearest)
    check(bike.global_basis.y.dot(Vector3.UP)>.99,"motorcycle upright")
    print("ALTA COCINA REVISION: ",failures," failures; ",checks," checks")
    quit(0 if failures==0 else 1)
