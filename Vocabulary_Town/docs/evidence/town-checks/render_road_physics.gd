extends SceneTree
# Captures actual garage exit and driving; overwrites docs/road-*.png only.
var game
var car
var camera: Camera3D
func _initialize(): run.call_deferred()
func advance(seconds: float,gas: float,steer: float,brake: bool) -> void:
    for i in range(roundi(seconds*60)):
        car.drive_step(1.0/60,gas,steer,1 if brake else 0)
        game.player._physics_process(1.0/60)
func capture(title: String) -> void:
    camera.global_position=car.global_position+Vector3(9,7,11)
    camera.look_at(car.global_position+Vector3.UP)
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/town-checks/road-"+title+".png")
func run():
    root.size=Vector2i(1400,1000)
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    for v in game.driveable_vehicles: v.set_physics_process(false)
    car=game.apartment.get_node("Vehicles/Car")
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=17
    game.add_child(camera)
    camera.current=true
    await physics_frame
    await physics_frame
    game.player.global_position=car.global_position-car.global_basis.z.normalized()*2.4
    await capture("garage")
    game.toggle_vehicle()
    print("GARAGE boarding=",game.active_vehicle==car)
    var start: Vector3=car.global_position
    advance(2.4,1,0,false)
    print("GARAGE driven distance=",car.global_position.distance_to(start)," speed=",car.current_speed)
    await capture("driveway")
    advance(1.4,.5,.6,false)
    await capture("turn")
    advance(3,0,0,true)
    game.toggle_vehicle()
    print("DRIVING stopped=",absf(car.current_speed)<.1," on foot=",game.player.riding_vehicle==null)
    await capture("parked")
    quit()
