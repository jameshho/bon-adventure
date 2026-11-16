extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok:
        failures+=1
        print("FAIL: ",message)
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var town: Node3D=game.apartment
    var garden=town.get_node_or_null("PublicGarden")
    check(garden!=null,"garden created")
    if garden==null: quit(1); return
    for path in ["RelocatedSites/Library","ParkZoo/ZooEntranceGate","ParkZoo/FarmEntranceGate","Buildings/School","Buildings/Hospital","RelocatedSites/Playground","RelocatedSites/Gazebo","RelocatedSites/Chapel","WashingtonStatue","Barn","ParkZoo/Fish","ParkZoo/Turtle"]:
        check(town.has_node(path),"preserved "+path)
    check(not town.has_node("RelocatedSites/Pond/Fountain"),"fountain removed")
    var fountains:=0
    var topiary:=0
    for node in garden.get_children():
        if String(node.name).begins_with("Monument fountain"):
            fountains+=1
            var p: Vector3=town.to_local(node.global_position)
            check(p.x>53 and absf(p.z-139)>8,"fountains flank west entrance")
            check(node.has_node("Rounded granite rim") and node.has_node("Fountain water"),"complete fountain basin")
            check(node.find_children("*","StaticBody3D",true,false).size()>=5,"solid fountain basin and centerpiece")
        if String(node.name).begins_with("Promenade topiary"):
            topiary+=1
            check(node.get_meta("word_key","")=="shrub" and node.has_node("StudyArea"),"topiary retains shrub vocabulary picking")
    check(fountains==2,"two entrance-side fountains")
    # 28 = public_garden.gd YEW_SPOTS (pass deleted 6 Nov 2026).
    check(topiary==28,"sheared yews line the monument walks")
    for parent in [garden,town.get_node("Trees"),town]:
        for node in parent.get_children():
            if not node is Node3D or not "tree" in String(node.name).to_lower(): continue
            var p: Vector3=town.to_local(node.global_position)
            for center in [Vector2(77,125),Vector2(77,153)]:
                check(Vector2(p.x,p.z).distance_to(center)>=8,"tree clears fountain "+String(node.name))
    var statue=town.get_node("WashingtonStatue")
    var horse_direction: Vector3=statue.get_node("Washington horse head").global_position-statue.get_node("Washington bronze horse body").global_position
    check(horse_direction.dot(game.reference_layout.world_point(Vector3(-1,0,0)))>1,"Washington horse faces west away from pond")
    for n in garden.get_children():
        if n.has_meta("word_key"):
            check(game.vocabulary.has(n.get_meta("word_key")),"known word "+str(n.get_meta("word_key")))
    var curves: Array=garden.get_meta("walking_paths")
    var names: Array=garden.get_meta("walking_path_names",[])
    check(names.size()==curves.size(),"named runtime trail metadata matches geometry")
    var closed_loops := 0
    for curve in curves:
        if curve[0].distance_to(curve[-1])<.1: closed_loops+=1
        for p in curve:
            var canonical: Vector3=game.reference_layout.world_point(p)
            check(canonical.x>= -100 and canonical.x<=108 and canonical.z>=35 and canonical.z<=220,"central trails stay inside main road")
    check(closed_loops==4,"island, lagoon and two fountain loops")
    # Monument trails join cleanly: no two walks run side by side (shared or wedge-shaped
    # stretches). Crossings and T-joins stay under 7.5 units within 2.4 of each other.
    # Scope: canonical x < -2 (statue garden); older east-bank overlaps are not covered.
    for a in range(curves.size()):
        for b in range(curves.size()):
            if a==b: continue
            var stretch := 0.0
            for i in range(1,curves[a].size()):
                var p: Vector3=curves[a][i]
                var q:=Vector2(p.x,p.z)
                var near := INF
                for j in range(1,curves[b].size()):
                    near=minf(near,q.distance_to(Geometry2D.get_closest_point_to_segment(q,Vector2(curves[b][j-1].x,curves[b][j-1].z),Vector2(curves[b][j].x,curves[b][j].z))))
                stretch=stretch+p.distance_to(curves[a][i-1]) if near<2.4 else 0.0
                if stretch>7.5 and game.reference_layout.world_point(p).x< -2:
                    check(false,"overlapping trails "+str(names[a])+" / "+str(names[b])+" near "+str(game.reference_layout.world_point(p)))
                    break
    var relief=load("res://docs/evidence/town-checks/park_ground.gd").new(town)
    # Compare junctions at their actual terrain elevation, not the former flat datum.
    # Shared loop junctions must remain paved, including both bridge mouths.
    for pair in [[-91,139],[-53,166],[-53,112],[-28,139],[-9,139],[49,139],[9,91],[27,182]]:
        var junction: Vector3=game.reference_layout.world_point(Vector3(pair[0],0,pair[1]))
        junction.y=relief.height_at(junction)
        var touching := 0
        for curve in curves:
            var nearest := INF
            for p in curve: nearest=minf(nearest,p.distance_to(junction))
            if nearest<2.0: touching+=1
        check(touching>=2,"connected trail junction "+str(pair))
    await physics_frame
    await physics_frame
    var capsule=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.9
    var query=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.collide_with_areas=false
    var samples := 0
    for curve in garden.get_meta("walking_paths"):
        for i in range(0,curve.size(),5):
            var p: Vector3=curve[i]
            var canonical=game.reference_layout.world_point(p)
            check(not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),garden.get_meta("lagoon_polygon")),"path over lagoon "+str(canonical))
            var tangent: Vector3=(curve[mini(i+1,curve.size()-1)]-curve[maxi(i-1,0)]).normalized()
            var side:=Vector3(-tangent.z,0,tangent.x)
            for offset in [-.7,0.0,.7]:
                query.transform=Transform3D(Basis.IDENTITY,town.to_global(p+side*offset+Vector3(0,1.08,0)))
                var hits=game.get_world_3d().direct_space_state.intersect_shape(query,4)
                check(hits.is_empty(),"path blocked "+str(canonical)+" offset "+str(offset)+(" by "+str(hits[0].collider.get_path()) if not hits.is_empty() else ""))
                samples+=1
    # Walk in both directions across the complete arched deck without jumping.
    for direction in [1,-1]:
        var body=CharacterBody3D.new()
        var shape=CollisionShape3D.new()
        shape.shape=capsule
        shape.position.y=1.0
        body.add_child(shape)
        town.add_child(body)
        var start: float=-5 if direction==1 else 45
        body.position=game.reference_layout.world_point(Vector3(start,.13,139))
        body.floor_snap_length=.5
        for frame in range(850):
            await physics_frame
            body.velocity=Vector3(-direction*6,body.velocity.y-24.0/60.0,0)
            body.move_and_slide()
            var x: float=game.reference_layout.world_point(body.position).x
            if (direction==1 and x>44) or (direction==-1 and x< -4): break
        var finish: float=game.reference_layout.world_point(body.position).x
        check(finish>44 if direction==1 else finish< -4,"bridge walk direction "+str(direction)+" ended "+str(body.position))
        body.free()
    for x in [-9.0,49.0]:
        for direction in [1,-1]:
            var body=CharacterBody3D.new()
            var shape=CollisionShape3D.new()
            shape.shape=capsule
            shape.position.y=1.0
            body.add_child(shape)
            town.add_child(body)
            body.position=game.reference_layout.world_point(Vector3(x,.12,133 if direction==1 else 145))
            body.floor_snap_length=.5
            for frame in range(200):
                await physics_frame
                body.velocity=Vector3(0,body.velocity.y-24.0/60.0,direction*6)
                body.move_and_slide()
                if (direction==1 and body.position.z>145) or (direction==-1 and body.position.z<133):break
            check(body.position.z>145 if direction==1 else body.position.z<133,"shore junction walking x="+str(x)+" direction="+str(direction))
            body.free()
    # The lowered lagoon is wadeable: walk under the span between the piers both ways.
    var water: Node3D=garden.get_node("Public Garden lagoon")
    check(water.position.y< -.3,"lagoon surface lowered below the shoreline rim")
    for x in [20.0,24.0]:
        for direction in [1,-1]:
            var body=CharacterBody3D.new()
            var shape=CollisionShape3D.new()
            shape.shape=capsule
            shape.position.y=1.0
            body.add_child(shape)
            town.add_child(body)
            body.position=game.reference_layout.world_point(Vector3(x,.12,131 if direction==1 else 147))
            body.floor_snap_length=.5
            for frame in range(300):
                await physics_frame
                body.velocity=Vector3(0,body.velocity.y-24.0/60.0,direction*6)
                body.move_and_slide()
                if (direction==1 and body.position.z>147) or (direction==-1 and body.position.z<131):break
            check(body.position.z>147 if direction==1 else body.position.z<131,"wade under bridge x="+str(x)+" direction="+str(direction)+" ended "+str(body.position))
            check(body.position.y> -1.2,"wading stays on the lagoon bed")
            body.free()
    # Dock entry must also be accessible without jumping over the deck lip.
    var dock_body=CharacterBody3D.new()
    var dock_shape=CollisionShape3D.new()
    dock_shape.shape=capsule
    dock_shape.position.y=1.0
    dock_body.add_child(dock_shape)
    town.add_child(dock_body)
    dock_body.position=game.reference_layout.world_point(Vector3(50,.12,127))
    dock_body.floor_snap_length=.5
    for frame in range(150):
        await physics_frame
        dock_body.velocity=Vector3(5,dock_body.velocity.y-24.0/60.0,0)
        dock_body.move_and_slide()
        if dock_body.position.x> -42:break
    check(dock_body.position.x> -42,"walkable dock gangway")
    dock_body.free()
    print("PUBLIC GARDEN: ",failures," failures; ",samples," path samples; bridge crossed and waded under in both directions")
    quit(1 if failures else 0)
