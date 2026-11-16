extends SceneTree
## 29 Oct 2026: coast renders (overview, shoreline, sand, boulders, crab, island).
## godot --path <isolated project> --resolution 1400x900 --script res://docs/evidence/coast-20261029/capture.gd -- [output_dir]
## Use the README's isolated user directory; the script only reads saves.
func _initialize(): run.call_deferred()
func run():
    var out:="res://docs/evidence/coast-20261029"
    for a in OS.get_cmdline_user_args(): out=a
    DirAccess.make_dir_recursive_absolute(out)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town: Node3D=game.apartment
    var coast: Node3D=town.get_node("Coast")
    var centre: Vector3=coast.get_meta("island_center")
    var island: Node3D=coast.get_node("Deserted island")
    var edge: PackedVector3Array=coast.get_meta("shore_sand_edge")
    var land: PackedVector3Array=coast.get_meta("shore_land")
    var boulder: Node3D=coast.get_node("Beach boulder")
    var crab: Node3D=null
    for c in coast.get_children():
        if c.name.begins_with("Crab"): crab=c; break
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    # East shoreline sample level with the island, looking back from the water.
    var best:=0
    for i in range(land.size()):
        if land[i].x<-90 and absf(land[i].z-centre.z)<absf(land[best].z-centre.z): best=i
    var shore:=edge[best]
    var inward:=(land[best]-edge[best]).normalized()
    var specs:=[
        ["overview",Vector3(-60,520,150),Vector3(-60,0,150),520.0,true,false],
        ["island_aerial",centre+Vector3(12,9,14),centre+Vector3(0,1,0),62.0,false,false],
        ["island_water",centre+Vector3(-14,1.8,-2),centre+Vector3(0,2.4,0),70.0,false,false],
        ["island_from_shore",shore+inward*4+Vector3(0,2.2,0),centre+Vector3(0,2,0),55.0,false,false],
        ["shoreline_wide",shore+inward*14+Vector3(0,12,0)+Vector3(0,0,-34),shore+Vector3(0,0,8),70.0,false,false],
        ["beach_sand",shore+inward*3.4+Vector3(0,1.6,0)+Vector3(0,0,-4),shore+inward*4.5+Vector3(0,0,9),75.0,false,false],
        ["sand_close",shore+inward*3.5+Vector3(0,.7,0),shore+inward*3.5+Vector3(0,0,3),75.0,false,false],
        ["boulders",boulder.position+inward*-5+Vector3(0,2.4,5),boulder.position+Vector3(0,.5,0),65.0,false,false],
        ["crab",town.to_local(crab.global_position)+Vector3(.5,.7,1.5),town.to_local(crab.global_position)+Vector3(0,.15,0),50.0,false,false],
    ]
    var env: Environment=game.get_viewport().world_3d.environment
    for spec in specs:
        var top: bool=spec[4]
        if env!=null: env.fog_enabled=not top
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if top else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=spec[3]; camera.fov=spec[3]
        camera.global_position=town.to_global(spec[1])
        camera.look_at(town.to_global(spec[2]),Vector3(0,0,1) if top else Vector3.UP)
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out+"/"+spec[0]+".png")
    print("COAST CAPTURE done")
    quit()
