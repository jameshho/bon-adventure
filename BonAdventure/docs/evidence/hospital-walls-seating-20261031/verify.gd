extends SceneTree
## Hospital walls and seating (31 Oct 2026): BonBon-sized sheep doctor over the lowered
## reception ledge, room/shared wall skins, sofas (one seat per cushion) and wheelchairs
## as seats. One Main load checks, then renders the views. Run on an isolated copy:
## godot --path . --resolution 1200x900 --script res://docs/evidence/hospital-walls-seating-20261031/verify.gd
const BONBON_HEIGHT := 2.239191
var failures := 0
func _initialize(): run.call_deferred()
func check(condition: bool, message: String) -> void:
    if not condition: failures += 1
    print("PASS: " if condition else "FAIL: ", message)

func height(node: Node3D) -> Vector2:
    var low := INF
    var high := -INF
    for mesh in node.find_children("*","MeshInstance3D",true,false):
        if "Costume" in str(node.get_path_to(mesh)) or not mesh.is_visible_in_tree(): continue
        var box: AABB=mesh.global_transform*mesh.get_aabb()
        low=minf(low,box.position.y); high=maxf(high,box.end.y)
    return Vector2(low,high)

func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder := "res://docs/evidence/hospital-walls-seating-20261031"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    await physics_frame
    var town: Node3D=game.apartment
    var hospital: Node3D=town.get_node("Buildings/Hospital")
    var doctor: Node3D=hospital.get_node("Floor1/Room1/SheepDoctor")
    var span := height(doctor)
    var bonbon := height(game.player)
    var ledge: Node3D=hospital.get_node("Floor1/Room1/DeskLedge")
    print("doctor height ",span.y-span.x," BonBon ",bonbon.y-bonbon.x," ledge ",ledge.global_position.y-hospital.get_node("Floor1/Room1").global_position.y)
    check(absf(doctor.global_basis.get_scale().y-1.0)<.01,"sheep doctor has world scale 1 like other plush characters")
    check(span.y-span.x<BONBON_HEIGHT*1.1,"sheep doctor is no taller than BonBon (+10%)")
    check(span.y>ledge.global_position.y+.5,"sheep doctor's head and shoulders clear the lowered ledge")
    check(hospital.find_children("WallSkin*","MeshInstance3D",true,false).size()>150,"wall skins present")
    var sofa_seats := 0
    var wheelchair_seats := 0
    for seat in game.seating.seats:
        if not hospital.is_ancestor_of(seat.node): continue
        if seat.label=="sofa": sofa_seats+=1
        if seat.label=="wheelchair": wheelchair_seats+=1
    print("hospital sofa seats ",sofa_seats," wheelchair seats ",wheelchair_seats)
    check(sofa_seats>=9 and sofa_seats%3==0,"hospital sofas give three seats each")
    check(wheelchair_seats>=1,"hospital wheelchairs are seats")
    # Sit on the waiting room's window sofa (Floor1/Room4) and on a floor-3 wheelchair.
    var shots := []
    for spec in [["Floor1/Room4","sofa","sit-sofa"],["Floor3/Room3","wheelchair","sit-wheelchair"]]:
        var parent: Node3D=hospital.get_node(spec[0])
        var target: Dictionary={}
        for seat in game.seating.seats:
            if seat.label==spec[1] and parent.is_ancestor_of(seat.node): target=seat; break
        check(not target.is_empty(),spec[1]+" seat in "+spec[0])
        if target.is_empty(): continue
        game.player.global_position=target.point+target.forward*1.4+Vector3.UP*.1
        for i in range(3): await physics_frame
        check(game.seating.try_sit(),"BonBon sits on the "+spec[1])
        for i in range(60): await physics_frame
        check(game.player.seated and game.player.global_position.distance_to(target.point)<.8,"BonBon is seated on the "+spec[1])
        shots.append([spec[2],target.point+target.forward*3.2+Vector3.UP*1.6,target.point+Vector3.UP*.5])
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        await capture(game,shots[-1])
        game.seating.stand()
        for i in range(40): await physics_frame
    print("HOSPITAL WALLS SEATING CHECK: ",failures," failures")
    game.player.hide()
    for spec in [
        ["reception-doctor",Vector3(5.5,1.8,-11.4),Vector3(5.3,1.2,-5.6)],
        ["reception-walls",Vector3(4,2.4,-5.0),Vector3(7.5,1.8,-11.5)],
        ["waiting-room-walls",Vector3(-2.6,2.7,-11.7),Vector3(-6.4,1.2,-6.2)],
        ["floor1-hall",Vector3(0,1.9,-11.2),Vector3(0,1.2,8)],
        ["pharmacy-walls",Vector3(3,2.2,6),Vector3(14,1.6,10)],
        ["floor2-room-walls",Vector3(2.5,5.6+2.2,-5),Vector3(8.5,5.6+1.4,-11.5)]
    ]:
        await capture(game,[spec[0],hospital.to_global(spec[1]),hospital.to_global(spec[2])])
    quit(0 if failures==0 else 1)

func capture(game, spec: Array) -> void:
    game.hud.hide()
    var camera: Camera3D=game.get_node_or_null("VerifyCamera")
    if camera==null:
        camera=Camera3D.new(); camera.name="VerifyCamera"; camera.fov=68.0
        game.add_child(camera)
    camera.current=true
    camera.global_position=spec[1]
    camera.look_at(spec[2])
    for i in range(5): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/hospital-walls-seating-20261031/"+spec[0]+".png")
