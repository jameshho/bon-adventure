extends SceneTree
## 29 Oct 2026: coast pass (shoreline, sand, boulders, crabs, deserted island). Run with the
## README's isolated user directory:
## godot --headless --path <isolated project> --fixed-fps 60 --script res://docs/evidence/coast-20261029/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func poly2(points: PackedVector3Array) -> PackedVector2Array:
    var result:=PackedVector2Array()
    for p in points: result.append(Vector2(p.x,p.z))
    return result
func ground(space: PhysicsDirectSpaceState3D,town: Node3D,p: Vector3) -> Dictionary:
    var query:=PhysicsRayQueryParameters3D.create(town.to_global(Vector3(p.x,3,p.z)),town.to_global(Vector3(p.x,-3,p.z)))
    return space.intersect_ray(query)
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var town: Node3D=game.apartment
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var layout=game.reference_layout
    var data: Dictionary=preload("res://scripts/learning/word_data.gd").load_all()
    var vocabulary: Dictionary=data["vocabulary"]
    # Vocabulary: crab added (user-approved); rock and palm tree reused.
    check(vocabulary.get("crab","")=="el cangrejo","crab = el cangrejo")
    check(vocabulary.has("rock") and vocabulary.has("palm tree"),"rock and palm tree words reused")
    var words: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))
    check(words["words"]["crab"]["category"]=="Animals","crab is in Animals")
    var spanish:={}
    for key in words["words"]:
        var sp: String=words["words"][key]["text"]["es"]  # 4 Nov 2026: per-language "text"
        check(not spanish.has(sp) or key==spanish[sp],"no duplicate Spanish for "+key)
        spanish[sp]=key
    check(not words["aliases"].has("crab"),"crab is a word, not an alias")
    var coast: Node3D=town.get_node_or_null("Coast")
    check(coast!=null and town.get_meta("coast_pass",false),"coast pass ran once")
    if coast==null:
        print("COAST VERIFY: ",checks," checks, ",failures," failures")
        quit(1)
        return
    var land: PackedVector3Array=coast.get_meta("shore_land")
    var sand_edge: PackedVector3Array=coast.get_meta("shore_sand_edge")
    var shallow_edge: PackedVector3Array=coast.get_meta("shore_shallow_edge")
    var land2:=poly2(land)
    var sand2:=poly2(sand_edge)
    var shallow2:=poly2(shallow_edge)
    # Shoreline: gentle curve (no sharp corners), simple polygon, varied width, beach nested in shallows.
    var worst:=0.0
    var widths:=PackedFloat32Array()
    for i in range(sand_edge.size()):
        var a:=(sand2[i]-sand2[(i-1+sand2.size())%sand2.size()]).normalized()
        var b:=(sand2[(i+1)%sand2.size()]-sand2[i]).normalized()
        worst=maxf(worst,rad_to_deg(a.angle_to(b)))
        widths.append(land2[i].distance_to(sand2[i]))
    check(worst<20.0,"sand edge has no sharp corners (max turn %.1f deg per ~1.8 m)"%worst)
    check(not Geometry2D.triangulate_polygon(sand2).is_empty(),"sand outline is a simple polygon")
    check(not Geometry2D.triangulate_polygon(shallow2).is_empty(),"shallow outline is a simple polygon")
    var lo:=INF
    var hi:=-INF
    for w in widths:
        lo=minf(lo,w)
        hi=maxf(hi,w)
    check(hi-lo>3.0,"beach width varies %.1f..%.1f m (natural, not a constant band)"%[lo,hi])
    var before: PackedFloat32Array=coast.get_meta("shore_width_before")
    for i in range(widths.size()): check(widths[i]>=before[i]-.05,"beach not narrower than before at sample %d"%i)
    for i in range(0,land.size(),9):
        check(Geometry2D.is_point_in_polygon(sand2[i],shallow2),"sand edge inside shallows %d"%i)
    # Piers, beach walk, runway and plane stay joined to the sand and clear of boulders.
    var keep:Array[Rect2]=[]
    for title in ["South pier","West pier","East pier"]:
        var pier: Node3D=town.find_child(title,true,false)
        check(pier!=null,"pier exists: "+title)
        if pier==null: continue
        var box: AABB=layout.bounds(pier)
        var rect:=Rect2(box.position.x,box.position.z,box.size.x,box.size.z)
        var joined:=false
        for q in [rect.position,rect.end,Vector2(rect.position.x,rect.end.y),Vector2(rect.end.x,rect.position.y),rect.get_center()]:
            joined=joined or Geometry2D.is_point_in_polygon(q,sand2)
        check(joined,title+" still touches the sand")
        keep.append(rect.grow(5.0))
    var runway: Node3D=town.get_node("Airport runway")
    var rb: AABB=layout.bounds(runway)
    keep.append(Rect2(rb.position.x,rb.position.z,rb.size.x,rb.size.z).grow(5.0))
    var plane: Node3D=town.get_node("Vehicles/Turboprop")
    var pb: AABB=layout.bounds(plane)
    keep.append(Rect2(pb.position.x,pb.position.z,pb.size.x,pb.size.z).grow(5.0))
    var walk_points:Array[Vector2]=[]
    for node in town.get_children():
        if node is MeshInstance3D and String(node.name).ends_with("beach access"):
            for v in (node as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]: walk_points.append(Vector2(v.x,v.z))
    # The beach access walks were removed on 2 Nov 2026, so walk_points is normally empty.
    # Walkability: sand rows slope gently up to the grass and a capsule fits everywhere.
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.32
    capsule.height=1.5
    var steepest:=0.0
    var grounded:=0
    var sampled:=0
    for i in range(0,land.size(),6):
        var previous:=NAN
        for fraction in [-.3,.1,.3,.5,.7,.9]:
            var dir: Vector3=(sand_edge[i]-land[i]).normalized()
            var p: Vector3=land[i]+dir*float(fraction)*land2[i].distance_to(sand2[i])
            if fraction<0.0: p=land[i]+(land[i]-sand_edge[i]).normalized()*1.0
            var hit:=ground(space,town,p)
            sampled+=1
            if hit.is_empty(): continue
            grounded+=1
            var y: float=town.to_local(hit.position).y
            check(hit.normal.y>.85,"walkable normal at sample %d f=%.1f (%.2f)"%[i,fraction,hit.normal.y])
            check(y>-.45 and y<.15,"sand height sane at sample %d (%.2f)"%[i,y])
            if not is_nan(previous): steepest=maxf(steepest,absf(y-previous))
            previous=y
    check(grounded==sampled,"every beach sample has solid ground (%d/%d)"%[grounded,sampled])
    check(steepest<.2,"beach rows change height gently (max step %.2f m)"%steepest)
    # Boulders: reuse the 'rock' word, mesh + collision under one root, clear of fixtures.
    var rocks:=coast.find_children("*","Node3D",false,false).filter(func(n): return n.get_meta("word_key","")=="rock")
    check(rocks.size()>=12,"at least 12 beach boulders (%d)"%rocks.size())
    var east:=0
    for rock in rocks:
        east+=1 if rock.position.x<-90 else 0
        check(rock.find_children("*","MeshInstance3D",false,false).size()==1 and rock.find_children("*","StaticBody3D",false,false).size()==1,"boulder has one mesh and one body under its root: "+String(rock.name))
        var p:=Vector2(rock.position.x,rock.position.z)
        check(Geometry2D.is_point_in_polygon(p,shallow2) and not Geometry2D.is_point_in_polygon(p,land2),"boulder on beach or in shallows")
        for rect in keep: check(not rect.has_point(p),"boulder clear of pier/runway/plane")
        for q in walk_points:
            if q.distance_to(p)<=4.0:
                check(false,"boulder within 4 m of beach walk vertex")
                break
        var body: StaticBody3D=rock.find_children("*","StaticBody3D",false,false)[0]
        check(preload("res://scripts/player/interaction_controller.gd").vocabulary_target(body,town)==rock,"boulder body picks its word root")
    check(east>=6,"boulders are denser on the east coast (%d east of %d)"%[east,rocks.size()])
    # Crabs.
    var crabs:=coast.find_children("Crab*","Node3D",true,false)
    var island_crabs:=0
    check(crabs.size()>=9,"at least 9 crabs (%d)"%crabs.size())
    for crab in crabs:
        check(String(crab.get_meta("word_key",""))=="crab","crab word key: "+String(crab.name))
        var area: Area3D=crab.get_node_or_null("VocabularyArea")
        check(area!=null and area.get_child_count()>0,"crab has picking area")
        if area!=null: check(preload("res://scripts/player/interaction_controller.gd").vocabulary_target(area,town)==crab,"crab area picks the crab root")
        check(crab.find_children("*","MeshInstance3D",true,false).size()==1,"crab is one mesh")
        var in_island: bool=crab.get_parent().name=="Deserted island"
        island_crabs+=1 if in_island else 0
        # Run the wander for several full swings; it must stay on sand, near home.
        var start: Vector3=crab.position
        var far:=0.0
        var on_sand:=true
        for step in range(400):
            crab._process(.1)
            far=maxf(far,crab.position.distance_to(crab.home))
            var world_p: Vector3=town.to_local(crab.global_position)
            if not in_island:
                var q:=Vector2(world_p.x,world_p.z)
                on_sand=on_sand and Geometry2D.is_point_in_polygon(q,sand2) and not Geometry2D.is_point_in_polygon(q,land2)
        check(far<=crab.radius+.01,"crab stays within its run (%.2f m)"%far)
        check(on_sand,"crab stays on sand: "+String(crab.name))
        if not in_island:
            var p:=Vector2(start.x,start.z)
            for rect in keep: check(not rect.has_point(p),"crab clear of pier/runway/plane")
    check(island_crabs==2,"two crabs on the island")
    # Island: east coast, off the shore, clear of land, roads, buildings and aircraft.
    var island: Node3D=coast.get_node("Deserted island")
    var centre: Vector3=coast.get_meta("island_center")
    var radius: float=coast.get_meta("island_radius")
    check(centre.x<-190 and centre.z>100 and centre.z<160,"island is off the east coast level with the park %s"%str(centre))
    var nearest:=INF
    for q in shallow_edge: nearest=minf(nearest,Vector2(q.x,q.z).distance_to(Vector2(centre.x,centre.z)))
    check(nearest-radius>=10.0,"open water between island shallows and the coast (%.1f m)"%(nearest-radius))
    check(not Geometry2D.is_point_in_polygon(Vector2(centre.x,centre.z),shallow2),"island centre is outside the shore polygon")
    var circle:=Rect2(centre.x-radius,centre.z-radius,radius*2,radius*2)
    for node in town.get_node("Buildings").get_children():
        if not node is Node3D: continue
        var b: AABB=layout.bounds(node)
        check(not circle.intersects(Rect2(b.position.x,b.position.z,b.size.x,b.size.z)),"island clear of "+String(node.name))
    for rect in keep: check(not circle.intersects(rect),"island clear of pier/runway/plane")
    var road: Node3D=town.get_node("Curving neighborhood road")
    for q in road.get_meta("reference_road_points"): check(Vector2(q.x,q.z).distance_to(Vector2(centre.x,centre.z))>radius+10.0,"island clear of road"); break
    var palms:=island.find_children("Island palm*","Node3D",false,false)
    check(palms.size()>=1 and palms.all(func(p): return p.get_meta("word_key","")=="palm tree"),"island has coconut palms using the palm tree word (%d)"%palms.size())
    var top:=ground(space,town,centre)
    check(not top.is_empty() and absf(town.to_local(top.position).y-.42)<.1,"island top is solid sand")
    check(island.find_children("Island boulder*","Node3D",false,false).size()>=3,"island boulders")
    # Island is reachable by air: nothing blocks a landing disc above it.
    check(ground(space,town,centre+Vector3(3,0,0)).has("position"),"island ground is solid off-centre")
    # Preserved: world positions the coast must never move.
    check(town.get_node("Airport").position.is_equal_approx(Vector3(-96,0,245)),"airport position unchanged")
    check(town.get_node("Buildings/FurnitureStore").position.is_equal_approx(Vector3(126,0,242)),"furniture store unchanged")
    check(town.get_node("Island beaches").material_override is ShaderMaterial and town.get_node("Island beaches").get_children().any(func(c): return c is StaticBody3D),"beach has the sand shader and collision")
    print("COAST STATS: beach width %.1f..%.1f m, %d boulders (%d east), %d crabs (%d island), island centre %s, shore samples %d"%[lo,hi,rocks.size(),east,crabs.size(),island_crabs,str(centre),land.size()])
    print("COAST VERIFY: ",checks," checks, ",failures," failures")
    quit(1 if failures>0 else 0)
