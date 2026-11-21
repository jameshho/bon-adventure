extends SceneTree
## Boards the north-east road-side car, drives and holds D through a turn with the real chase
## camera; writes turn-*.png into this folder only.
var game
var car
func _initialize(): run.call_deferred()
func advance(seconds: float,gas: float,steer: float) -> void:
    for i in range(roundi(seconds*60)):
        car.drive_step(1.0/60,gas,steer,0)
        game.player._physics_process(1.0/60)
        await physics_frame
func shot(title: String) -> void:
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/evidence/car-driving-20261121/turn-"+title+".png")
    print("SHOT ",title," speed=",snappedf(car.current_speed,.1)," yaw=",snappedf(car.road_physics.yaw_velocity,.01)," cam_yaw=",snappedf(game.player.camera_yaw,.01))
func run():
    root.size=Vector2i(1400,900)
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    for v in game.driveable_vehicles:
        v.set_physics_process(false)
        if v.name=="Road-side car (north east)": car=v
    for i in 3: await physics_frame
    game.player.global_position=car.boarding_step_point()+Vector3.UP*.1
    print("BOARD ",game.board_vehicle(car)," occupied=",car.occupied)
    game.player.camera_yaw+=1.2 # start looking from the side: the chase camera must swing behind
    await advance(2.2,0,0) # door sequence
    await shot("1-start")
    await advance(2.5,1,0)
    await shot("2-straight")
    await advance(1.0,.6,1)
    await shot("3-turning")
    await advance(1.2,.6,1)
    await shot("4-turned")
    quit(0)
