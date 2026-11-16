extends SceneTree
## Police station entrance and crocodile police officer views; isolated copy, graphics required.
## godot --path . --resolution 1200x800 --script res://docs/evidence/police-officer-20261101/capture.gd
func _initialize(): run.call_deferred()
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/police-officer-20261101"
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var station: Node3D=game.apartment.get_node("RelocatedSites/Police")
    var npc: Node3D=game.apartment.get_node("People/CrocodilePoliceOfficer")
    var car: Node3D=game.apartment.get_node("Vehicles/Police_Car")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    camera.fov=65.0
    camera.far=900.0
    # [name, eye, target]: global positions; station-local (model) units via to_global.
    for spec in [
        ["entrance",station.to_global(Vector3(43,2.4,24)),station.to_global(Vector3(44.5,1.6,37.5))],
        ["officer",station.to_global(Vector3(45.2,1.3,32.2)),npc.global_position+Vector3(0,1.0,0)],
        ["officer-side",station.to_global(Vector3(41.5,1.2,33.4)),npc.global_position+Vector3(0,.9,0)],
        ["aerial",station.to_global(Vector3(43,18,18)),station.to_global(Vector3(43,0,36))],
        ["car-and-officer",npc.global_position.lerp(car.global_position,.5)+Vector3(0,14,0)+(station.global_basis*Vector3(0,0,-9)),npc.global_position.lerp(car.global_position,.5)],
    ]:
        camera.global_position=spec[1]
        camera.look_at(spec[2])
        for i in range(8): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+spec[0]+".png")
    print("POLICE OFFICER CAPTURE done")
    quit()
