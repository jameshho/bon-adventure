extends SceneTree
## Storefront redesign views (1 Nov 2026), one oblique street view per redesigned front.
## godot --path . --resolution 1200x800 --script res://docs/evidence/exterior-redesign-20261101/capture.gd -- [--before]
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var phase: String="before" if OS.get_cmdline_user_args().has("--before") else "after"
    var folder: String="res://docs/evidence/exterior-redesign-20261101/"+phase
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera); camera.current=true
    camera.fov=55.0; camera.far=900.0
    var facades: Node3D=game.apartment.get_node("Map facades")
    # Facade nodes keep pre-compact town coordinates: every shop front faces −Z there.
    for title in ["CLOTHING","ELECTRONICS","BAKERY _ CAFE","FURNITURE","SPORTS","SCHOOL","SUPERMARKET","POLICE STATION"]:
        var facade: Node3D=facades.get_node(title)
        var b: AABB=facade.get_meta("facade_bounds")
        var w: float=maxf(b.size.x,12.0)
        var c:=b.get_center()
        camera.global_position=facade.to_global(Vector3(c.x+w*.45,4.5+w*.12,b.position.z-w*1.05-4))
        camera.look_at(facade.to_global(Vector3(c.x,b.position.y*.55,b.position.z+2)))
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+title.to_lower().replace(" _ ","-").replace(" ","-")+".png")
    print("STOREFRONT CAPTURE: ",phase)
    quit()
