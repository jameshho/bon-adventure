extends SceneTree
## Lagoon Bridge views (28 Oct 2026); graphics required.
## godot --path . --resolution 1100x750 --script res://docs/evidence/bridge-20261028/capture.gd -- --shots=/abs/folder --tag=after
func _initialize(): run.call_deferred()
func run():
    var shots:=""
    var tag:="view"
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--shots="): shots=a.trim_prefix("--shots=")
        if a.begins_with("--tag="): tag=a.trim_prefix("--tag=")
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.hide()
    var town: Node3D=game.apartment
    var deck: MeshInstance3D=town.get_node("PublicGarden/Public Garden arched bridge")
    var box: AABB=town.global_transform.affine_inverse()*deck.global_transform*deck.get_aabb()
    var c:=box.get_center()
    var long:=Vector3(1,0,0) if box.size.x>box.size.z else Vector3(0,0,1)
    var across:=Vector3(0,0,1) if long.x>0 else Vector3(1,0,0)
    print("bridge centre ",c," size ",box.size)
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=60.0
    for spec in [["side",c-across*26+long*-6+Vector3(0,-1.2,0),c+Vector3(0,-.5,0)],["angle",c-across*14+long*-24+Vector3(0,.2,0),c+long*-6+Vector3(0,1,0)],["close",c-across*7+long*-13+Vector3(0,.8,0),c+long*-11+Vector3(0,2.5,0)],["deck",c+long*-20+Vector3(0,4.5,0),c+long*6+Vector3(0,2.5,0)]]:
        camera.global_position=town.to_global(spec[1])
        camera.look_at(town.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(shots+"/bridge-"+tag+"-"+spec[0]+".png")
    quit()
