extends SceneTree
## 29 Oct 2026: control tower renders (exterior, lobby, stairs, radar deck, control room, plan cutaways).
## godot --path . --resolution 1400x900 --script res://docs/evidence/control-tower-20261029/capture.gd -- [output_dir]
## Use the README's isolated user directory; the script only reads saves.
func _initialize(): run.call_deferred()
func run():
    var out:="res://docs/evidence/control-tower-20261029"
    for a in OS.get_cmdline_user_args(): out=a
    DirAccess.make_dir_recursive_absolute(out)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var tower: Node3D=game.apartment.get_node("Airport/ControlTower/Interior")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    # [name, camera (tower-local), target, fov/size, orthographic, hide roof/cabin/levels above]
    for spec in [
        ["exterior",Vector3(-16,13,-30),Vector3(0,13,0),55.0,false,0],
        ["exterior_far",Vector3(-50,22,-55),Vector3(-6,14,2),50.0,false,0],
        ["exterior_door",Vector3(-6,2.0,-9),Vector3(-3.0,1.4,-4.2),65.0,false,0],
        ["exterior_back",Vector3(22,16,30),Vector3(0,14,0),55.0,false,0],
        ["cabin_close",Vector3(-12,24,-16),Vector3(0,23,0),60.0,false,0],
        ["ground_inside",Vector3(0.5,1.7,-3.4),Vector3(-1.0,2.6,1.0),90.0,false,0],
        ["ground_lift",Vector3(-0.2,1.7,-3.4),Vector3(2.8,1.6,2.0),75.0,false,0],
        ["lift_doors",Vector3(2.3,1.7,-2.6),Vector3(2.3,1.8,.8),70.0,false,0],
        ["shaft_up",Vector3(0.0,1.7,-1.0),Vector3(-1.0,14.0,1.5),80.0,false,0],
        ["stair_flight",Vector3(-3.0,7.0,-3.4),Vector3(-3.0,9.0,3.0),80.0,false,0],
        ["landing_strip",Vector3(1.0,12.7,-0.2),Vector3(-1.5,12.0,-3.0),85.0,false,0],
        ["radar_room",Vector3(2.5,12.7,-1.5),Vector3(2.4,12.0,-3.4),80.0,false,0],
        ["radar_room_door",Vector3(1.5,12.6,0.2),Vector3(2.6,12.0,-2.0),80.0,false,0],
        ["control_south",Vector3(0.5,23.8,-0.5),Vector3(0,22.9,-5.0),85.0,false,0],
        ["control_east",Vector3(-0.5,23.8,-1.0),Vector3(5.0,22.9,-2.5),85.0,false,0],
        ["control_north",Vector3(1.0,23.9,0.0),Vector3(-2.6,22.9,5.2),85.0,false,0],
        ["control_core",Vector3(-2.0,23.8,-4.0),Vector3(2.5,23.0,1.5),85.0,false,0],
        ["control_view",Vector3(0,23.5,-1.0),Vector3(0,23.5,-9),95.0,false,0],
        ["plan_control",Vector3(0,45,0),Vector3(0,0,0),15.0,true,3],
    ]:
        var hide_above: int=spec[5]
        # Plan views hide the roof, cabin shell and upper slabs so each floor is visible.
        var hidden:=[]
        if hide_above>0:
            for n in tower.find_children("*","Node3D",false,false):
                var y: float=n.position.y
                var nm:=String(n.name)
                var cut: float=[0.0,5.4,11.0,99.0][hide_above]
                if hide_above==3: cut=99.0
                if (hide_above<3 and y>cut and not nm.begins_with("Floor slab") or (hide_above<3 and nm.begins_with("Floor slab") and y>cut-.3)) or (hide_above==3 and (nm.begins_with("Cabin") or nm.begins_with("Ceiling") or nm.begins_with("Roof") or nm.begins_with("Faceted") or nm=="Mast" or nm.begins_with("Light panel") or nm.begins_with("Antenna") or nm.begins_with("Beacon") or nm.begins_with("Corner lamp") or nm.begins_with("Rail"))):
                    if n is Node3D and n.visible: n.hide(); hidden.append(n)
            if hide_above<3:
                for n in tower.find_children("Elevator","Node3D",false,false): pass
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL if spec[4] else Camera3D.PROJECTION_PERSPECTIVE
        camera.size=spec[3]; camera.fov=spec[3]
        camera.global_position=tower.to_global(spec[1])
        camera.look_at(tower.to_global(spec[2]),Vector3.UP if not spec[4] else Vector3(0,0,1))
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out+"/"+spec[0]+".png")
        for n in hidden: n.show()
    print("TOWER CAPTURE done")
    quit()
