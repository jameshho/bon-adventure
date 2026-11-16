extends SceneTree
## Clothing store clerk and interior refresh views (1 Nov 2026); graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/clothing-clerk-20261101/capture.gd [-- prefix]
## Writes PNGs into this folder only (Main may save progress: use the README's isolated copy).
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/clothing-clerk-20261101"
    var args:=OS.get_cmdline_user_args()
    var prefix:=(args[0]+"-") if args.size()>0 else ""
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var store: Node3D=game.apartment.get_node("Buildings/ClothingStore")
    var old: Node3D=game.apartment.get_node_or_null("People/Cashier")
    if old: print("old cashier store-local: ",store.to_local(old.global_position))
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, eye, target]: store-local coordinates (door on −Z at x=0, back wall z=7.31).
    var views:=[
        ["entrance",Vector3(0,2.3,-7.0),Vector3(0,1.0,3.5)],
        ["checkout",Vector3(1.0,2.0,1.0),Vector3(3.8,1.1,6.2)],
        ["left",Vector3(1.2,2.2,-6.0),Vector3(-4.0,1.0,1.5)],
        ["right",Vector3(-1.2,2.2,-6.0),Vector3(4.0,1.0,1.5)],
        ["rear",Vector3(0,2.4,5.0),Vector3(0,1.0,-6.0)],
    ]
    for spec in views:
        camera.global_position=store.to_global(spec[1])
        camera.look_at(store.to_global(spec[2]))
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+prefix+spec[0]+".png")
    # Cut-away aerial: hide everything above the walls' sill line except the interior.
    for node in store.find_children("*","MeshInstance3D",true,false):
        if "Interior" in str(store.get_path_to(node)): continue
        if node.global_position.y-store.global_position.y>3.6: node.visible=false
    for node in store.find_children("*Roof*","Node3D",true,false): node.visible=false
    camera.global_position=store.to_global(Vector3(-9,17,-15))
    camera.look_at(store.to_global(Vector3(0,0,1)))
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(folder+"/"+prefix+"aerial.png")
    print("CLOTHING CLERK CAPTURE done")
    quit()
