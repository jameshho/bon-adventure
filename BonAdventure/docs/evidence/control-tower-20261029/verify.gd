extends SceneTree
## 29 Oct 2026: airport control tower. Run with the README's isolated user directory:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/control-tower-20261029/verify.gd
var failures:=0
var checks:=0
var game
var tower: Node3D
var room: Node3D
var space: PhysicsDirectSpaceState3D
const LV:=[0.0,5.5,11.0,16.5,22.0]
const MID:=11.0
const TOP:=22.0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
## True when the real player capsule (world radius .76, height 2.2) fits at tower-local p (feet).
func clear_at(p: Vector3) -> bool:
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.76
    capsule.height=2.2
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,room.to_global(p+Vector3(0,.2,0))+Vector3(0,1.15,0))
    query.collision_mask=1
    return space.intersect_shape(query,1).is_empty()
func make_walker(p: Vector3) -> CharacterBody3D:
    var body:=CharacterBody3D.new()
    var shape:=CollisionShape3D.new()
    var capsule:=CapsuleShape3D.new()
    capsule.radius=.76
    capsule.height=2.2
    shape.shape=capsule
    shape.position=Vector3(0,1.1,0)
    body.add_child(shape)
    body.floor_snap_length=.3
    body.collision_layer=0
    body.collision_mask=1
    game.add_child(body)
    body.global_position=room.to_global(p)
    return body
## Walk along tower-local waypoints at walking speed; returns true when the last one is reached.
func walk(body: CharacterBody3D,points: Array) -> bool:
    for wp in points:
        var target: Vector3=room.to_global(wp)
        for frame in range(600):
            var d:=target-body.global_position
            d.y=0
            if d.length()<.3: break
            body.velocity.x=d.normalized().x*6.0
            body.velocity.z=d.normalized().z*6.0
            body.velocity.y-=30.0/60.0
            body.move_and_slide()
            await physics_frame
        if (target-body.global_position).slide(Vector3.UP).length()>=.5: return false
    return true
## One physics frame of a standing player (the real controller moves every frame).
func ride(body: CharacterBody3D) -> void:
    body.velocity.x=0
    body.velocity.z=0
    body.velocity.y-=30.0/60.0
    body.move_and_slide()
    await physics_frame
func local_y(body: CharacterBody3D) -> float:
    return room.to_local(body.global_position).y

func run() -> void:
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for i in range(3): await physics_frame
    var town: Node3D=game.apartment
    tower=town.get_node("Airport/ControlTower")
    room=tower.get_node_or_null("Interior")
    space=game.get_world_3d().direct_space_state
    check(room!=null and tower.get_meta("venue","")=="control_tower","interior built and tagged")
    if room==null:
        print("TOWER VERIFY: ",checks," checks, ",failures," failures")
        quit(1)
        return
    # The old solid boxes are gone (no meshes, no collision bodies).
    check(tower.mesh==null and (town.get_node("Airport/TowerCabin") as MeshInstance3D).mesh==null,"old shaft/cabin boxes replaced")
    check(tower.find_children("Body","StaticBody3D",false,false).is_empty(),"old solid shaft collision removed")
    # Footprint and neighbours.
    var layout=game.reference_layout
    var tb: AABB=layout.bounds(tower)
    # The tower proper excludes the entrance path and step laid in front of the door.
    var shell:=AABB()
    var first:=true
    # Since 12 Nov 2026 the control room's observation deck and roof overhang the zone high above
    # the ground (user; docs/evidence/tower-deck-20261112/verify.gd checks their air space): the zone
    # check measures the tower below the cabin floor slab (room y 21.6).
    var slab_bottom: float=town.to_local(room.to_global(Vector3(0,21.6,0))).y
    for m in tower.find_children("*","MeshInstance3D",true,false):
        if String(m.get_parent().name).begins_with("Entrance"): continue
        var mb: AABB=layout.bounds(m)
        if mb.position.y>=slab_bottom-.01: continue
        shell=mb if first else shell.merge(mb)
        first=false
    var full_height: float=tb.size.y
    tb=shell
    check(tb.position.x>=-77.01 and tb.end.x<=-64.99 and tb.position.z>=242.99 and tb.end.z<=255.01,"tower below the cabin inside the control_tower zone (-77..-65, 243..255): %s"%str(tb))
    var terminal: AABB=layout.bounds(town.get_node("Airport/Terminal"))
    var gap:=tb.position.x-terminal.end.x
    check(gap>=0.0 or tb.end.x<=terminal.position.x or tb.position.z>=terminal.end.z or tb.end.z<=terminal.position.z,"tower does not overlap the terminal (gap %.2f)"%gap)
    check(full_height<=36.0 and full_height>=28.0,"height %.1f within plan"%full_height)
    var shaft_half:=0.0
    for n in room.find_children("Tower wall","Node3D",false,false): shaft_half=maxf(shaft_half,absf(n.position.x))
    check(shaft_half<4.5,"shaft is the narrow part (outer half %.2f)"%(shaft_half+.15))
    # Words: only existing keys, each pickable.
    var vocabulary: Dictionary=preload("res://scripts/learning/word_data.gd").load_all()["vocabulary"]
    var tagged:={}
    var counts:={}
    for node in room.find_children("*","Node3D",true,false):
        if node.has_meta("word_key"):
            var key:=String(node.get_meta("word_key"))
            tagged[key]=node
            counts[key]=int(counts.get(key,0))+1
            check(vocabulary.has(key),"tagged key is an existing word: "+key)
            check(node.find_children("*","CollisionObject3D",true,false).size()>0,"pickable: %s %s"%[key,node.name])
    for key in ["computer","keyboard","mouse","headphones","headset","microphone","phone","radio","notebook","clipboard","lamp","cup","desk","office chair","flight board","radar","stairs","elevator","world map"]:
        check(tagged.has(key),"tower holds word: "+key)
    check(int(counts.get("computer",0))>=8,"several monitors/computers (%d)"%int(counts.get("computer",0)))
    check(int(counts.get("office chair",0))>=9,"office chairs (%d)"%int(counts.get("office chair",0)))
    check(int(counts.get("headphones",0))+int(counts.get("headset",0))>=8 and int(counts.get("microphone",0))>=6,"headsets/headphones and microphones")
    check(int(counts.get("stairs",0))==3,"three stair roots (0, 5.5, 11; the last flight was removed 30 Oct 2026) tagged stairs (%d)"%int(counts.get("stairs",0)))
    check(not tagged.has("walkie-talkie") and not tagged.has("control desk"),"no walkie-talkie or control desk word")
    var lift_node: Node3D=room.get_node("Elevator")
    check(lift_node.script.resource_path.ends_with("hospital_elevator.gd"),"tower uses the shared hospital elevator script")
    check(lift_node.landing_doors.size()==3 and lift_node.landing_buttons.size()==3 and lift_node.cabin_buttons.size()==3,"outer landing door, call button and cabin button for each of the three stops")
    # Picking: a ray into each tagged object finds its word root through a layer-2 area.
    var picked:=0
    for key in tagged:
        var node: Node3D=tagged[key]
        var area: Area3D=node.find_child("Interaction",true,false) as Area3D
        if area==null:
            var any:=node.find_children("*","Area3D",true,false)
            if any.is_empty(): continue
            area=any[0]
        var center:=area.global_position+Vector3(0,.0,0)
        for shape in area.get_children():
            if shape is CollisionShape3D: center=shape.global_position
        var query:=PhysicsRayQueryParameters3D.create(center+Vector3(0,3,0),center-Vector3(0,3,0),2)
        query.collide_with_areas=true
        query.collide_with_bodies=false
        var hit:=space.intersect_ray(query)
        if not hit.is_empty():
            var cursor: Node=hit.collider
            while cursor and not cursor.has_meta("word_key"): cursor=cursor.get_parent()
            if cursor and String(cursor.get_meta("word_key"))!="": picked+=1
    check(picked>=tagged.size()-1,"%d of %d word types resolvable by pointer ray"%[picked,tagged.size()])
    # 360-degree glazing: glass on all four cabin faces.
    var faces:={"S":false,"N":false,"E":false,"W":false}
    # Panes are box meshes or, since the 12 Nov 2026 window migration, shared window components.
    for n in room.find_children("*","Node3D",false,false):
        if n.get_meta("part","")!="Cabin glass": continue
        if absf(n.position.z)>5 and n.position.z<0: faces["S"]=true
        if absf(n.position.z)>5 and n.position.z>0: faces["N"]=true
        if absf(n.position.x)>5 and n.position.x<0: faces["W"]=true
        if absf(n.position.x)>5 and n.position.x>0: faces["E"]=true
    check(faces.values().all(func(v): return v),"control room glazed on all four sides")
    # Discreet entrance: one narrow side door, no canopy or sign; standing spots on every level.
    check(room.find_children("*","Label3D",false,false).size()<=4,"no entrance sign or big lobby signage")
    for z in range(-9,-3):
        check(clear_at(Vector3(-3.05,0,z)),"side door path z=%d"%z)
    for spec in [["ground by lift",Vector3(2.3,0,-.2)],["stair foot",Vector3(-3.2,0,-3.2)],["landing strip L1",Vector3(0,LV[1],-3.2)],["landing strip L3",Vector3(0,LV[3],-3.2)],
            ["lift landing, radar level",Vector3(2.3,MID,-.2)],["radar room door",Vector3(2.55,MID,-.9)],["radar room inside",Vector3(2.3,MID,-1.8)],["stair top at the control room",Vector3(-1.4,TOP,-3.0)],
            ["control room by lift",Vector3(2.3,TOP,-.2)],["control centre",Vector3(1.2,TOP,-1.0)],["south desk aisle",Vector3(1.2,TOP,-2.8)],["north strip",Vector3(0,TOP,4.6)]]:
        check(clear_at(spec[1]),"standing spot free: "+spec[0])
    # Open shaft: no floor between the landing strips (the void is guarded, not filled).
    var down:=PhysicsRayQueryParameters3D.create(room.to_global(Vector3(0,MID+1.0,2.6)),room.to_global(Vector3(0,-1.0,2.6)),1)
    # Since 10 Nov 2026 the widened lift shaft fills this spot (user: fill the alcove beside the
    # lift; airport.gd widen_tower_elevator): the ray ignores the elevator's own car and walls.
    down.exclude=room.get_node("Elevator").find_children("*","CollisionObject3D",true,false).map(func(b): return b.get_rid())
    var floor_hit:=space.intersect_ray(down)
    check(not floor_hit.is_empty() and room.to_local(floor_hit.position).y<1.0,"intermediate levels are not filled: a ray from the radar level falls to the ground floor")
    # Real walking up all four storeys and back down.
    var body:=make_walker(Vector3(-3.2,0,-3.3))
    for i in range(10): await physics_frame
    var ok:=true
    for l in range(3):
        var base: float=LV[l]
        ok=await walk(body,[Vector3(-3.2,base,-3.1),Vector3(-3.2,base,-2.0),Vector3(-3.2,base,0.8),Vector3(-3.2,base,2.6),Vector3(-1.4,base,2.6),Vector3(-1.4,base,0.5),Vector3(-1.4,base,-2.2),Vector3(-1.4,base,-3.1)])
        check(ok and absf(local_y(body)-LV[l+1])<.45,"stair carries the player up from y=%.1f to y=%.1f (now %.2f)"%[base,LV[l+1],local_y(body)])
        if not ok: break
    for l in [2,1,0]:
        var base: float=LV[l]
        ok=await walk(body,[Vector3(-1.4,base,-3.1),Vector3(-1.4,base,-2.0),Vector3(-1.4,base,0.5),Vector3(-1.4,base,2.6),Vector3(-3.2,base,2.6),Vector3(-3.2,base,0.5),Vector3(-3.2,base,-2.0),Vector3(-3.2,base,-3.1)])
        check(ok and absf(local_y(body)-base)<.45,"stair carries the player down to y=%.1f (now %.2f)"%[base,local_y(body)])
        if not ok: break
    body.free()
    # Elevator: walk in at the lobby, ride to the control room, step out, ride back.
    var lift: Node3D=room.get_node("Elevator")
    var rider:=make_walker(Vector3(2.3,0,-1.0))
    lift.player=rider
    for i in range(10): await physics_frame
    ok=await walk(rider,[Vector3(2.3,0,.6),Vector3(2.3,0,2.3)])
    check(ok and lift.inside_car(),"player can enter the open cabin")
    lift.call_elevator(2)
    for frame in range(1800):
        await ride(rider)
        if lift.current_floor==2 and lift.state==lift.State.OPEN: break
    check(lift.current_floor==2 and lift.state==lift.State.OPEN,"elevator reaches the control room and opens")
    check(absf(local_y(rider)-TOP)<.45 and lift.inside_car(),"rider travelled with the cabin (y=%.2f)"%local_y(rider))
    ok=await walk(rider,[Vector3(2.3,TOP,.5),Vector3(2.3,TOP,-1.0)])
    check(ok and absf(local_y(rider)-TOP)<.45,"player steps out onto the control room floor")
    ok=await walk(rider,[Vector3(2.3,TOP,.6),Vector3(2.3,TOP,2.3)])
    lift.call_elevator(1)
    for frame in range(1800):
        await ride(rider)
        if lift.current_floor==1 and lift.state==lift.State.OPEN: break
    check(lift.current_floor==1 and absf(local_y(rider)-MID)<.45,"elevator carries the player to the radar deck (y=%.2f)"%local_y(rider))
    lift.call_elevator(0)
    for frame in range(1800):
        await ride(rider)
        if lift.current_floor==0 and lift.state==lift.State.OPEN: break
    check(lift.current_floor==0 and absf(local_y(rider)-LV[0])<.45,"elevator returns to the lobby (y=%.2f)"%local_y(rider))
    rider.free()
    print("TOWER VERIFY: ",checks," checks, ",failures," failures")
    quit(1 if failures>0 else 0)
