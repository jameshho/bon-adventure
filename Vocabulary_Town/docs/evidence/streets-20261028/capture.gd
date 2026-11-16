extends SceneTree
## Street views; graphics required. godot --path . --resolution 1200x800 --script res://docs/evidence/streets-20261028/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var shots:="res://docs/evidence/streets-20261028"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    var town: Node3D=game.apartment
    var road: Node3D=town.get_node("Curving neighborhood road")
    var pts: PackedVector3Array=road.get_meta("reference_road_points")
    game.player.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    var bank: Vector3=town.to_local(town.get_node("RelocatedSites/Bank").global_position)
    var sports: Vector3=town.to_local(town.get_node("Buildings/SportsStore").global_position)
    var c0: Array=town.get_meta("loop_crossings")[3]
    var p0: Vector3=c0[0]
    var near_sports:=pts[0]
    for q in pts: if Vector2(q.x-sports.x,q.z-sports.z).length()<Vector2(near_sports.x-sports.x,near_sports.z-sports.z).length(): near_sports=q
    var views:=[
        ["street-east",Vector3(103,2.2,bank.z-28),Vector3(103,1,bank.z+30)],
        ["street-top-sports",near_sports+Vector3(0,28,-14),near_sports+Vector3(0,0,1)],
        ["street-crossing",p0+Vector3(-9,2.6,-6),p0+Vector3(0,.1,0)],
        ["street-north",Vector3(20,2.4,200),Vector3(-20,1.5,200)],
        ["street-high",Vector3(-30,35,30),Vector3(0,0,120)],
    ]
    for spec in views:
        camera.global_position=town.to_global(spec[1])
        camera.look_at(town.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(shots+"/"+spec[0]+".png")
    quit()
