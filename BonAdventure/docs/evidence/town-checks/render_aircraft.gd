extends SceneTree
# Graphical Godot; overwrites the four current aircraft preview PNGs only.
func _initialize(): run.call_deferred()
func capture(camera: Camera3D,plane: Node3D,title: String,offset: Vector3,target: Vector3,size: float) -> void:
    camera.size=size
    camera.global_position=plane.to_global(offset)
    camera.look_at(plane.to_global(target))
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/town-checks/aircraft-"+title+".png")
func run():
    root.size=Vector2i(1400,1000)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var plane=game.apartment.get_node("Vehicles/Turboprop")
    plane.set_physics_process(false)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    game.add_child(camera)
    camera.current=true
    game.player.global_position=plane.to_global(Vector3(-2.5,.1,-1.1))
    await physics_frame
    await capture(camera,plane,"parked",Vector3(-15,10,-18),Vector3(0,1.5,0),25)
    game.toggle_vehicle()
    plane.boarding_progress=.45
    game.player.animate_aircraft_pilot(.016)
    await capture(camera,plane,"boarding",Vector3(-6,4,-6),Vector3(-.7,1.9,-1),9)
    plane.boarding_progress=1
    game.player.animate_aircraft_pilot(.016)
    await capture(camera,plane,"cockpit",Vector3(-4,3.5,-5),Vector3(-.25,2,-1.25),6)
    plane.global_position+=Vector3.UP*55
    plane.rotate_object_local(Vector3.BACK,-.3)
    plane.engine_power=1
    plane.airspeed=35
    plane.landed=false
    game.player.animate_aircraft_pilot(.016)
    await capture(camera,plane,"flight",Vector3(-16,9,15),Vector3(0,1,0),28)
    quit()
