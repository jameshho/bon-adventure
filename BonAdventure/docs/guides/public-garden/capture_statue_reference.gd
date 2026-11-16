extends SceneTree
## Washington monument close views and rider portrait views.
## Usage: godot --path . --resolution 1200x800 --script res://docs/guides/public-garden/capture_statue_reference.gd -- <tag> <absolute folder> [portrait]
## Town-local coordinates (+X west, +Z north); the statue stands at (53,0,139).
func _initialize(): run.call_deferred()
func run():
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town=game.apartment
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=60
    var args=OS.get_cmdline_user_args()
    var tag=args[0]
    var folder=args[1]
    var statue=town.get_node("WashingtonStatue")
    assert(statue.has_node("Reference corner pilasters"))
    assert(statue.get_node("Bronze horse and rider").mesh.get_surface_count()==1)
    assert(statue.has_node("Plaque") and statue.has_node("Pedestal"))
    var finish=statue.get_node("Bronze horse and rider").material_override
    assert(not finish.vertex_color_use_as_albedo)
    # 9 Nov 2026 (statue_town_bronze, replaces statue_patina): one plain, non-metallic bronze
    # colour like every other town prop; no textures.
    assert(finish.albedo_texture==null and finish.roughness_texture==null and finish.metallic==0.0)
    assert(finish.albedo_color.is_equal_approx(Color("5c5236")))
    print("Uniform bronze material (town bronze): passed")
    print("Statue checks: bronze mesh, corner pilasters, plaque and pedestal present")
    var wide_views = [["three",Vector3(62,7.5,128.5),Vector3(53,4.7,139)],["side",Vector3(53,7,123),Vector3(53,4.8,139)],["front",Vector3(69,6.5,139),Vector3(53,4.7,139)],["close",Vector3(59,9,132),Vector3(53,6.7,139)]]
    for spec in ([] if args.size()>2 and args[2]=="portrait" else wide_views):
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[0]=="plan" else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=72
        camera.global_position=town.to_global(spec[1])
        camera.look_at(town.to_global(spec[2]),Vector3(0,0,1) if spec[0]=="plan" else Vector3.UP)
        for i in range(12): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/monument-"+tag+"-"+spec[0]+".png")
    for spec in [["portrait",Vector3(3.2,8.4,3.2)],["hair",Vector3(-3,8.3,2.5)]]:
        camera.global_position=statue.to_global(spec[1])
        camera.look_at(statue.to_global(Vector3(-0.12,7.91,0)),Vector3.UP)
        camera.fov=30
        for i in range(12): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/monument-"+tag+"-"+spec[0]+".png")
    quit()
