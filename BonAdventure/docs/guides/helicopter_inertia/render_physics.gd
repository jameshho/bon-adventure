extends SceneTree
# Renders the actual replacement physics trajectory; overwrites only rotor-*.png.
var game
var heli
var camera: Camera3D
func _initialize(): run.call_deferred()
func capture(title: String) -> void:
    camera.global_position=heli.global_position+Vector3(13,7,-18)
    camera.look_at(heli.global_position+Vector3.UP*2)
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/guides/helicopter_inertia/rotor-"+title+".png")
func advance(seconds: float,gas: float,steering: float,lift: float,assist: bool) -> void:
    for i in range(roundi(seconds*60)):
        heli.drive_step(1.0/60,gas,steering,lift,assist)
        heli.update_rotors(1.0/60)
        game.player._physics_process(1.0/60)
func run():
    root.size=Vector2i(1400,1000)
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    heli=game.apartment.get_node("Buildings/Hospital/HospitalHelipad/Helicopter")
    heli.set_process(false)
    heli.set_physics_process(false)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=24
    game.add_child(camera)
    camera.current=true
    await physics_frame
    await physics_frame
    game.player.global_position=heli.global_position+Vector3(3,.05,0)
    await capture("parked")
    game.toggle_vehicle()
    advance(3,0,0,0,true)
    advance(4,0,0,1,true)
    await capture("takeoff")
    advance(1.5,.6,.5,0,false)
    await capture("banked")
    advance(5,0,0,0,true)
    advance(12,0,0,-.35,true)
    print("VISUAL LANDING grounded=",heli.ground_contact()," speed=",heli.current_speed)
    await capture("landing")
    if heli.ground_contact():
        game.toggle_vehicle()
        print("VISUAL EXIT on foot=",game.player.riding_vehicle==null)
    quit()
