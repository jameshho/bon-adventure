extends SceneTree
## Supermarket refit views (2 Nov 2026); graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/supermarket-20261102/capture.gd [-- prefix]
## Writes PNGs into this folder only (Main may save progress: use an isolated user dir).
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/supermarket-20261102"
    var args:=OS.get_cmdline_user_args()
    var prefix:=(args[0]+"-") if args.size()>0 else ""
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var market: Node3D=game.apartment.get_node("RelocatedSites/Supermarket")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, eye, target]: market-local (door x -35.8..-30.2 on the z=34.25 front wall,
    # +X is the left-hand side on entering, rear wall z=59.75).
    var views:=[
        ["entrance",Vector3(-33,2.3,34.8),Vector3(-33,1.0,50)],
        ["checkout",Vector3(-33.5,2.2,42.5),Vector3(-39.5,1.0,36.5)],
        ["fruit",Vector3(-31.5,2.2,40.5),Vector3(-22,1.0,48)],
        ["vegetables",Vector3(-29,2.0,40.8),Vector3(-34,1.0,45)],
        ["pantry",Vector3(-41.3,2.0,41.8),Vector3(-41.3,1.0,52)],
        ["dairy",Vector3(-33,2.0,45.8),Vector3(-33,1.2,50.5)],
        ["rear",Vector3(-33,2.3,51.5),Vector3(-33,1.2,59)],
        ["drinks",Vector3(-29.5,2.1,41.5),Vector3(-22,1.0,36)],
    ]
    for spec in views:
        camera.global_position=market.to_global(spec[1])
        camera.look_at(market.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+prefix+spec[0]+".png")
    # Cut-away plan: hide the roof, ceiling and overhead signs.
    for node in market.find_children("*","GeometryInstance3D",true,false):
        if market.to_local(node.global_position).y>3.0: node.visible=false
    for node in game.apartment.get_node("StaticRenderBatches").get_children(): node.visible=false
    for node in market.find_children("*","MeshInstance3D",true,false):
        if market.to_local(node.global_position).y<=3.0: node.visible=true
    for node in game.apartment.get_node("Buildings/MarketDisplays").find_children("*","MeshInstance3D",true,false): node.visible=true
    camera.global_position=market.to_global(Vector3(-33,30,44))
    camera.look_at(market.to_global(Vector3(-33,0,47.2)))
    camera.fov=50.0
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(folder+"/"+prefix+"cutaway.png")
    print("SUPERMARKET CAPTURE done")
    quit()
