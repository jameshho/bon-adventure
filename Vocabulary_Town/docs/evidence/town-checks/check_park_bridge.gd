extends SceneTree
func _initialize(): call_deferred("run")
func run():
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    var body=CharacterBody3D.new()
    var shape=CollisionShape3D.new()
    var capsule=CapsuleShape3D.new()
    capsule.radius=0.25
    capsule.height=1.7
    shape.shape=capsule
    shape.position.y=0.86
    body.add_child(shape)
    game.apartment.add_child(body)
    body.position=Vector3(3,0.2,68)
    body.floor_snap_length=0.4
    for i in range(540):
        await physics_frame
        body.velocity=Vector3(4*1.3,body.velocity.y-20*body.get_physics_process_delta_time(),0)
        body.move_and_slide()
        if body.position.x>31:break
    print("BRIDGE WALK: end ",body.position," success=",body.position.x>31)
    quit(0 if body.position.x>31 else 1)
