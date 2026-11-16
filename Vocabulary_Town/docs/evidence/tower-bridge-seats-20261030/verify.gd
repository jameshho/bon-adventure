extends SceneTree
## 30 Oct 2026: tower stair walls, shortened stair + ladder + empty level, flush elevator doors,
## swivel seats, standable bridge rails/chains/lamps. Run with the README's isolated user directory:
## godot --headless --path <isolated project> --fixed-fps 60 --script res://docs/evidence/tower-bridge-seats-20261030/verify.gd
var failures:=0
var checks:=0
func _initialize(): run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("FAIL: ",label)
func ray(game,from: Vector3,to: Vector3) -> Dictionary:
    return game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to))
func key(code: int,pressed: bool) -> void:
    var e:=InputEventKey.new()
    e.physical_keycode=code
    e.keycode=code
    e.pressed=pressed
    Input.parse_input_event(e)
func run() -> void:
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.interaction.set_physics_process(false)
    await physics_frame
    await physics_frame
    var town: Node3D=game.apartment
    var tower: Node3D=town.get_node("Airport/ControlTower")
    var room: Node3D=tower.get_node("Interior")
    # --- tower: stairs end at 16.5, walls around the stair, empty level, hatch, ladder ---
    var treads:=room.find_children("Stair tread*","Node3D",true,false)
    var top_tread:=-INF
    for t in treads: top_tread=maxf(top_tread,t.position.y+t.get_parent().position.y+t.get_child(0).mesh.size.y/2.0 if t.get_child_count()>0 and t.get_child(0) is MeshInstance3D else -INF)
    check(room.find_children("*","Node3D",false,false).filter(func(n): return n.get_meta("word_key","")=="stairs").size()==3,"three stair flight pairs (0, 5.5, 11)")
    check(top_tread<=16.51,"no stair tread above the empty level (%.2f)"%top_tread)
    for title in ["Stair wall east","Stair wall north"]:
        var walls:=room.find_children(title+"*","Node3D",false,false)
        check(walls.size()>=1,title+" exists")
        for w in walls: check(w.find_children("*","StaticBody3D",false,false).size()==1 or w is StaticBody3D or w.get_child_count()>1,title+" has collision")
    var east: Node3D=room.find_children("Stair wall east*","Node3D",false,false)[0]
    check(east.position.x>-.7 and east.position.x<-.5,"east wall sits on the stair's open east side")
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var floor_hit:=ray(game,room.to_global(Vector3(0,18,-3.2)),room.to_global(Vector3(0,10,-3.2)))
    check(not floor_hit.is_empty() and absf(room.to_local(floor_hit.position).y-16.5)<.05,"empty level has a solid full floor at 16.5")
    var floor_far:=ray(game,room.to_global(Vector3(-3.3,18,3.0)),room.to_global(Vector3(-3.3,10,3.0)))
    check(not floor_far.is_empty() and absf(room.to_local(floor_far.position).y-16.5)<.05,"empty level floor reaches the north-west corner")
    var hole_hit:=ray(game,room.to_global(Vector3(-3.3,24,-.5)),room.to_global(Vector3(-3.3,10,-.5)))
    check(not hole_hit.is_empty() and absf(room.to_local(hole_hit.position).y-16.5)<.05,"control-room hatch is open straight down to the empty level")
    var slab_hit:=ray(game,room.to_global(Vector3(-1.0,24,-.5)),room.to_global(Vector3(-1.0,10,-.5)))
    check(not slab_hit.is_empty() and room.to_local(slab_hit.position).y>21.9,"control-room floor is solid away from the hatch")
    var lad: Node3D=room.get_node_or_null("Ladder")
    check(lad!=null and lad.is_in_group("ladders") and is_equal_approx(float(lad.get_meta("ladder_height")),5.5),"ladder in group with 5.5 rise")
    if lad!=null: check(lad.get_child_count()>=25,"ladder has two rails, rungs and brackets (%d parts)"%lad.get_child_count())
    check(room.find_children("Opening guard*","StaticBody3D",false,false).size()==2,"guards around the stair opening on the empty level")
    # Climb from the foot to the control room with W, then back down with S.
    var player=game.player
    player.global_position=lad.to_global(Vector3(0,.05,.9))
    player.velocity=Vector3.ZERO
    for i in range(20): await physics_frame
    var start_y: float=room.to_local(player.global_position).y
    check(absf(start_y-16.5)<.3,"player stands on the empty level at the ladder foot (%.2f)"%start_y)
    key(KEY_W,true)
    player.global_position=lad.to_global(Vector3(0,.05,.5))
    var peak:=-INF
    var grabbed:=false
    for i in range(600):
        await physics_frame
        peak=maxf(peak,room.to_local(player.global_position).y)
        grabbed=grabbed or player.ladder_node!=null
    key(KEY_W,false)
    for i in range(60): await physics_frame
    var end:=room.to_local(player.global_position)
    check(grabbed,"holding W at the foot grabs the ladder")
    check(peak>=21.9,"climbing reaches the control-room floor (peak %.2f)"%peak)
    check(absf(end.y-22.0)<.35 and end.x>-2.55,"player ends standing on the control-room floor beside the hatch (%s)"%str(end))
    player.global_position=lad.to_global(Vector3(0,3.0,.45))
    player.velocity=Vector3.ZERO
    key(KEY_S,true)
    var low:=INF
    for i in range(400):
        await physics_frame
        low=minf(low,room.to_local(player.global_position).y)
    key(KEY_S,false)
    check(low<=16.7,"holding S climbs back down to the empty level (low %.2f)"%low)
    # --- elevators: nothing but a thin trim proud of the shaft wall ---
    var lifts:=town.find_children("*","Node3D",true,false).filter(func(n): return n.get_script()!=null and String(n.get_script().resource_path).ends_with("hospital_elevator.gd"))
    check(lifts.size()>=2,"hospital and tower elevators found (%d)"%lifts.size())
    for lift in lifts:
        var worst:=0.0
        for child in lift.get_children():
            var title:=String(child.name)
            if not (title.begins_with("Landing") or title.begins_with("Button") or title.begins_with("CallLamp")): continue
            var mesh:=child.get_child(0) as MeshInstance3D if child.get_child_count()>0 else null
            if mesh==null or not mesh.mesh is BoxMesh: continue
            var depth: float=(mesh.mesh as BoxMesh).size.z
            # Outer face of the front wall is .09 beyond the shaft line.
            worst=maxf(worst,(-lift.hd()-.09)-(child.position.z-depth/2.0))
        check(worst<=.065,"%s landing trim protrudes at most %.2f from the shaft face"%[lift.get_path(),worst])
    # --- seats: swivel ---
    var seats: Array=game.seating.seats
    var swivel:=seats.filter(func(s): return is_instance_valid(s.node) and s.node.get_meta("swivel",false))
    var chairs:=swivel.filter(func(s): return String(s.node.get_meta("word_key",""))=="office chair")
    var stools:=swivel.filter(func(s): return String(s.node.get_meta("word_key",""))!="office chair" and s.node.has_meta("sit_forward"))
    check(chairs.size()>=8,"swivel office chairs registered as seats (%d)"%chairs.size())
    check(stools.size()==8,"eight swivel bar stools registered as seats (%d)"%stools.size())
    var in_tower:=chairs.filter(func(s): return tower.is_ancestor_of(s.node))
    check(in_tower.size()>=8,"tower chairs are seats (%d)"%in_tower.size())
    for s in chairs.slice(0,3)+stools.slice(0,2):
        var seat: Dictionary=s
        var node: Node3D=seat.node
        game.seating.refresh(seat)
        var floor_y: float=ray(game,seat.point+Vector3(0,.2,0),seat.point-Vector3(0,3,0)).get("position",seat.point).y
        check(seat.point.y-floor_y>.35 and seat.point.y-floor_y<1.2,"seat height above the floor for %s (%.2f)"%[node.name,seat.point.y-floor_y])
    var seat: Dictionary=in_tower[0]
    var chair: Node3D=seat.node
    var before:=chair.rotation.y
    player.global_position=seat.point
    player.seated=true
    player.sit_transition=false
    game.seating.current=seat
    key(KEY_A,true)
    for i in range(30): await physics_frame
    key(KEY_A,false)
    check(absf(angle_difference(before,chair.rotation.y))>.8,"A swivels the chair (%.2f rad)"%angle_difference(before,chair.rotation.y))
    check(absf(angle_difference(player.rotation.y,atan2(-seat.forward.x,-seat.forward.z)))<.05,"the player turns with the chair")
    var after_a:=chair.rotation.y
    key(KEY_D,true)
    for i in range(30): await physics_frame
    key(KEY_D,false)
    check(angle_difference(chair.rotation.y,after_a)>.8,"D swivels back")
    player.seated=false
    game.seating.current={}
    # --- bridge: handrails, chains and lamp globes are solid and standable ---
    var garden: Node3D=town.get_node("PublicGarden")
    var walks:=garden.find_children("Bridge handrail walk*","Node3D",false,false)
    var chain_walks:=garden.find_children("Bridge suspension chain walk*","Node3D",false,false)
    var pads:=garden.find_children("Bridge lamp globe pad*","Node3D",false,false)
    check(walks.size()>=80,"handrail walks along both rails (%d)"%walks.size())
    check(chain_walks.size()>=100,"suspension chain walks (%d)"%chain_walks.size())
    check(pads.size()==8,"a standing pad in each of eight lamp globes (%d)"%pads.size())
    for group in [walks,chain_walks,pads]:
        var misses:=0
        for n in group:
            var p: Vector3=n.global_position
            var hit:=ray(game,p+Vector3(0,.6,0),p-Vector3(0,.6,0))
            if hit.is_empty(): misses+=1
        check(misses==0,"every walk piece is solid from above (%d misses)"%misses)
    var rail_mid: Node3D=walks[walks.size()/2]
    var rail_hit:=ray(game,rail_mid.global_position+Vector3(0,.5,0),rail_mid.global_position-Vector3(0,.5,0))
    var pad_hit:=ray(game,pads[0].global_position+Vector3(0,1,0),pads[0].global_position-Vector3(0,1,0))
    check(not pad_hit.is_empty() and pad_hit.position.y<pads[0].global_position.y+.2,"lamp pad top is the first surface (%s)"%str(pad_hit.get("position","none")))
    # A grounded player capsule can rest on a rail: drop it from above and let it settle.
    player.global_position=rail_mid.global_position+Vector3(0,1.2,0)
    player.velocity=Vector3.ZERO
    for i in range(90): await physics_frame
    check(player.is_on_floor() and player.global_position.y>rail_mid.global_position.y-.1,"player rests on top of the handrail (y %.2f vs rail %.2f)"%[player.global_position.y,rail_mid.global_position.y])
    var chain_mid: Node3D=chain_walks[chain_walks.size()/3]
    player.global_position=chain_mid.global_position+Vector3(0,1.2,0)
    player.velocity=Vector3.ZERO
    for i in range(90): await physics_frame
    check(player.global_position.y>chain_mid.global_position.y-.3,"player does not fall through a suspension chain (y %.2f vs chain %.2f)"%[player.global_position.y,chain_mid.global_position.y])
    player.global_position=pads[0].global_position+Vector3(0,.6,0)
    player.velocity=Vector3.ZERO
    for i in range(90): await physics_frame
    check(player.global_position.y>pads[0].global_position.y-.1,"player rests on a lamp globe (y %.2f vs pad %.2f)"%[player.global_position.y,pads[0].global_position.y])
    print("TOWER/BRIDGE/SEATS VERIFY: ",checks," checks, ",failures," failures")
    quit(1 if failures>0 else 0)
