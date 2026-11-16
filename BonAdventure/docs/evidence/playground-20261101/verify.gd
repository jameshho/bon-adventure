extends SceneTree
## Playground rebuild and rideable swings (1 Nov 2026). Drives Main through real key
## events (E, W, S). Main saves progress: run with an isolated user directory (README).
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/playground-20261101/verify.gd
var failures:=0
var checks:=0
var game
var swing: Node3D
const DECK_TOP := 2.3
var seat: Node3D
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
func tap(code: Key) -> void:
    key(code,true)
    for i in range(3): await physics_frame
    key(code,false)
    await physics_frame
## Largest angle reached over `seconds` (seconds of physics at 60 Hz).
func peak(seconds: float) -> float:
    var best:=0.0
    for i in range(int(seconds*60)):
        await physics_frame
        best=maxf(best,absf(swing.angle))
    return best
## Seconds between successive forward zero crossings of the free swing (one full swing).
func period() -> float:
    var crossings:=[]
    var previous: float=swing.angle
    for i in range(10*60):
        await physics_frame
        if previous<0.0 and swing.angle>=0.0: crossings.append(i)
        previous=swing.angle
        if crossings.size()==3: break
    return (crossings[2]-crossings[0])/120.0 if crossings.size()==3 else -1.0
## Rider stays on the seat: same offset and orientation in seat space every frame.
var worst_offset:=0.0
var worst_basis:=0.0
var worst_jerk:=0.0
var last_speed:=0.0
func track() -> void:
    if not game.player.seated or game.player.sit_transition: return
    var frame: Transform3D=seat.global_transform.orthonormalized()
    worst_offset=maxf(worst_offset,game.player.global_position.distance_to(frame*swing.rider_offset))
    worst_basis=maxf(worst_basis,(game.player.global_basis.y-frame.basis.y).length())
    worst_jerk=maxf(worst_jerk,absf(swing.speed-last_speed))
    last_speed=swing.speed
## Pump in time: W as the seat starts forward, S as it starts back.
func pump(seconds: float, timed := true) -> void:
    var previous: float=swing.speed
    last_speed=swing.speed
    for i in range(int(seconds*60)):
        await physics_frame
        track()
        if previous<=0.0 and swing.speed>0.0: await tap(KEY_W if timed else KEY_S)
        elif previous>=0.0 and swing.speed<0.0: await tap(KEY_S if timed else KEY_W)
        else:
            previous=swing.speed
            continue
        # tap() spent four frames; resume the per-frame comparisons from here.
        previous=swing.speed
        last_speed=swing.speed
func run() -> void:
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    for i in range(10): await physics_frame
    var town: Node3D=game.apartment
    var site: Node3D=town.get_node("RelocatedSites/Playground")
    var kit: Node3D=site.get_node_or_null("Playground equipment")
    check(kit!=null,"playground equipment built")
    # --- old equipment replaced; neighbouring sandbox, tent and ball kept
    for title in ["Play tower","Playground slide","Swing beam","Swing seat","Swing support"]:
        check(site.get_node_or_null(title)==null,"old "+title+" removed")
    for title in ["Sandbox","Sand","Play Tent","Playground ball"]:
        check(site.get_node_or_null(title)!=null,title+" kept")
    var words:={}
    for node in kit.find_children("*","Node3D",true,false):
        if node.has_meta("word_key"): words[String(node.get_meta("word_key"))]=words.get(String(node.get_meta("word_key")),0)+1
    for word in ["playground","slide","seat","swing","seesaw","merry-go-round","monkey bars","bridge","stairs"]:
        check(words.has(word) and game.vocabulary.has(word),"teaches "+word)
    check(words.get("playground",0)==2 and words.get("seat",0)==2,"two towers and two swing seats")
    # --- pad inside the playground zone (town X 40…84, Z 163…194), larger than the old oval
    var pad: MeshInstance3D=kit.get_node("Playground safety surface")
    var box: AABB=town.global_transform.affine_inverse()*pad.global_transform*pad.get_aabb()
    print("pad town rect ",box)
    check(box.position.x>40 and box.end.x<84 and box.position.z>163 and box.end.z<194,"pad inside the playground zone")
    check(box.size.x*box.size.z*1.69>851.0,"pad area %.0f m² exceeds the old oval's 851 m²"%(box.size.x*box.size.z*1.69))
    # --- walk surfaces: BonBon lands on the bridge, the deck and the slide instead of falling through
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    for spec in [["bridge middle",Vector3(0,5,6.8),1.9],["west deck",Vector3(5.5,5,6.8),2.2],["stairs midway",Vector3(8.5,5,6.8),1.1],["slide middle",Vector3(-5.5,5,2.6),1.2],["merry-go-round",Vector3(-9,5,-5.5),.35]]:
        var from: Vector3=kit.to_global(spec[1])
        var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+Vector3.DOWN*10))
        var y: float=hit.position.y-kit.global_position.y if not hit.is_empty() else -1.0
        check(absf(y-spec[2])<.15,"%s floor at %.2f (expected %.2f)"%[spec[0],y,spec[2]])
    # --- the bridge fits BonBon: 25 cm spare each side of her body, and she walks across it
    var body: CapsuleShape3D=game.player.get_node("PlayerCollision").shape
    var roomy:=CapsuleShape3D.new()
    roomy.radius=body.radius+.25
    roomy.height=body.height+.5
    var crowded:=0
    for x in [4.25,3.0,1.5,0.0,-1.5,-3.0,-4.25]:
        var from: Vector3=kit.to_global(Vector3(x,5,6.8))
        var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+Vector3.DOWN*10))
        var probe:=PhysicsShapeQueryParameters3D.new()
        probe.shape=roomy
        probe.transform=Transform3D(Basis.IDENTITY,hit.position+Vector3.UP*(roomy.height*.5+.3))
        probe.exclude=[game.player.get_rid()]
        if not space.intersect_shape(probe,1).is_empty(): crowded+=1
    check(crowded==0,"bridge clear for BonBon plus 25 cm each side (%d blocked spots)"%crowded)
    var walker=game.player
    walker.global_position=kit.to_global(Vector3(5.5,DECK_TOP,6.8))
    walker.velocity=Vector3.ZERO
    var heading: Vector3=kit.to_global(Vector3(-5.5,0,6.8))-kit.to_global(Vector3(5.5,0,6.8))
    walker.camera_yaw=atan2(-heading.x,-heading.z)
    walker.camera_rig.rotation.y=walker.camera_yaw
    for i in range(10): await physics_frame
    key(KEY_W,true)
    var lowest:=INF
    var drift:=0.0
    for i in range(240):
        await physics_frame
        var at: Vector3=kit.to_local(walker.global_position)
        lowest=minf(lowest,at.y)
        drift=maxf(drift,absf(at.z-6.8))
    key(KEY_W,false)
    for i in range(10): await physics_frame
    var end: Vector3=kit.to_local(walker.global_position)
    print("bridge walk end ",end," lowest ",lowest," drift ",drift)
    check(end.x<-4.3 and lowest>1.6 and drift<.3,"walks across the bridge to the east deck (x %.2f, lowest %.2f, drift %.2f)"%[end.x,lowest,drift])
    # --- swings registered as seats
    # The seesaw's two ends are seats too (1 Nov 2026 fix batch); count only the swings.
    var swings: Array=game.seating.seats.filter(func(s): return kit.is_ancestor_of(s.node) and s.label=="swing")
    check(swings.size()==2,"two swing seats registered (%d)"%swings.size())
    check(game.seating.seats.filter(func(s): return kit.is_ancestor_of(s.node) and s.label=="seesaw").size()==2,"two seesaw seats registered")
    seat=swings[0].node
    swing=seat.get_meta("playground_swing")
    check(swing.is_physics_processing() and not seat.has_meta("render_batched"),"swing keeps its own draw (not render-batched)")
    # --- E sits: approach from the front
    var player=game.player
    check(player.controls_enabled,"controls enabled")
    player.global_position=seat.global_position+Vector3(0,-.6,-1.7)
    player.velocity=Vector3.ZERO
    for i in range(20): await physics_frame
    await tap(KEY_E)
    for i in range(50): await physics_frame
    check(player.seated and game.seating.current.get("node")==seat,"E sits on the swing")
    check(game.hud.seating_hint.text.contains("W / S"),"seated hint: "+game.hud.seating_hint.text)
    # --- holding W does not pump: one kick only
    key(KEY_W,true)
    var held:=await peak(8.0)
    key(KEY_W,false)
    check(held>.05 and held<.35,"holding W gives a single kick (peak %.2f rad)"%held)
    await peak(1.0)
    # --- timed W / S presses build momentum gradually
    var start_peak:=await peak(3.0)
    await pump(4.0)
    var early:=await peak(2.7)
    await pump(10.0)
    var built:=await peak(2.7)
    print("peaks: start %.2f, after 4 s pumping %.2f, after 14 s %.2f"%[start_peak,early,built])
    check(early>start_peak+.1,"momentum builds with timed presses (%.2f → %.2f)"%[start_peak,early])
    check(built>early and built>.7,"keeps building to a high swing (%.2f rad)"%built)
    check(built<swing.MAX_ANGLE+.15,"never swings over the top (%.2f rad)"%built)
    check(worst_offset<.002 and worst_basis<.002,"rider locked to the seat (offset %.4f m, tilt %.4f)"%[worst_offset,worst_basis])
    check(worst_jerk<.15,"smooth: largest per-frame change in angular speed %.3f rad/s"%worst_jerk)
    # --- mistimed presses take energy out
    var before:=await peak(2.7)
    await pump(6.0,false)
    var mistimed:=await peak(2.7)
    check(mistimed<before*.7,"mistimed presses slow the swing (%.2f → %.2f)"%[before,mistimed])
    # --- no input: natural slowdown, at the playground pace (~2.6 s per swing)
    await pump(8.0)
    var swing_time:=await period()
    check(swing_time>2.4 and swing_time<2.9,"one full swing takes %.2f s (was 3.6 s)"%swing_time)
    var high:=await peak(2.7)
    await peak(8.0)
    var later:=await peak(2.7)
    check(later<high*.8 and later>high*.2,"slows naturally without input (%.2f → %.2f in ~12 s)"%[high,later])
    # --- rider clearance: BonBon's meshes never touch the frame, the other swing or the ground
    var frame_boxes:=[]
    for node in kit.get_node("Swing set").find_children("*","MeshInstance3D",true,false):
        if swing.is_ancestor_of(node): continue
        frame_boxes.append((node.global_transform*node.get_aabb()).abs())
    var clipped:=0
    for i in range(int(2.7*60)):
        await physics_frame
        for mesh in player.get_node("Visual").find_children("*","MeshInstance3D",true,false):
            if not mesh.is_visible_in_tree(): continue
            var b: AABB=(mesh.global_transform*mesh.get_aabb()).abs()
            if b.size.x<.1 or b.size.y<.1 or b.size.z<.1: continue
            b=b.grow(-.03)
            if b.position.y<kit.global_position.y+.05: clipped+=1
            for f in frame_boxes:
                if b.intersects(f): clipped+=1
    check(clipped==0,"BonBon clears the frame, the other swing and the ground (%d contacts)"%clipped)
    # --- E while swinging: brakes, then stands once stopped
    await pump(5.0)
    var moving:=absf(swing.angle)+absf(swing.speed)
    await tap(KEY_E)
    check(player.seated and swing.braking,"E while swinging brakes first (motion %.2f)"%moving)
    var frames:=0
    while player.seated and frames<600:
        await physics_frame
        frames+=1
    for i in range(40): await physics_frame
    check(not player.seated,"stood up after braking (%.1f s)"%(frames/60.0))
    check(frames<360,"braking stops the swing within 6 s")
    check(absf(player.rotation.x)<.001 and absf(player.rotation.z)<.001,"stands level")
    check(player.global_position.y<kit.global_position.y+.5 and player.global_position.y>kit.global_position.y-.1,"standing on the ground (y %.2f)"%(player.global_position.y-kit.global_position.y))
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=player.get_node("PlayerCollision").shape
    query.transform=player.get_node("PlayerCollision").global_transform
    query.exclude=[player.get_rid()]
    check(space.intersect_shape(query,1).is_empty(),"exit spot is clear")
    check(swing.rider==null,"swing released")
    # --- sit and get off again at rest: immediate
    for i in range(30): await physics_frame
    await tap(KEY_E)
    for i in range(50): await physics_frame
    check(player.seated,"sits again")
    await tap(KEY_E)
    for i in range(50): await physics_frame
    check(not player.seated,"E at rest gets off straight away")
    # --- walk forward after getting off: controls restored
    var p0: Vector3=player.global_position
    key(KEY_W,true)
    for i in range(40): await physics_frame
    key(KEY_W,false)
    check(player.global_position.distance_to(p0)>1.0,"walks after leaving the swing")
    print("PLAYGROUND VERIFY: %d checks, %d failures"%[checks,failures])
    quit(1 if failures>0 else 0)
