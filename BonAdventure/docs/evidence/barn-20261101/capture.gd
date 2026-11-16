extends SceneTree
## Farm barn views (1 Nov 2026). Uses Main, which saves progress: run with an isolated user
## directory (README). Camera points are in the barn's own frame (town units, door on −Z).
## godot --path . --resolution 1200x800 --script res://docs/evidence/barn-20261101/capture.gd
## The first views went to after/; since the ladder was turned and the paddock shelter rebuilt
## (same day) they go to turned/, with the ladder and paddock views added.
func _initialize(): run.call_deferred()
func shot(camera: Camera3D,from: Vector3,at: Vector3,file: String) -> void:
    camera.global_position=from
    camera.look_at(at)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(file)
func run():
    if DisplayServer.get_name()=="headless": quit(1); return
    var folder:="res://docs/evidence/barn-20261101/turned"
    DirAccess.make_dir_recursive_absolute(folder)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
    game.hud.hide()
    var camera:=Camera3D.new()
    game.add_child(camera); camera.current=true
    camera.fov=60.0; camera.far=900.0
    var barn: Node3D=game.apartment.get_node("Barn/Barn/Barn interior")
    var at:=func(x: float,y: float,z: float) -> Vector3: return barn.to_global(Vector3(x,y,z))
    await shot(camera,at.call(-6,7,-22),at.call(0,4.5,0),folder+"/front.png")
    await shot(camera,at.call(-16,14,-16),at.call(0,4,0),folder+"/aerial.png")
    await shot(camera,at.call(12,6,15),at.call(0,4,0),folder+"/rear.png")
    # BonBon standing on the loft beside the ladder notch.
    game.player.global_position=at.call(-1.4,3.0,2.6)
    game.player.rotation.y=barn.global_rotation.y+PI
    await shot(camera,at.call(0,2.2,-4.0),at.call(0,2.4,2.0),folder+"/interior.png")
    await shot(camera,at.call(-4.5,1.7,-3.6),at.call(2.5,1.6,2.5),folder+"/interior-left.png")
    await shot(camera,at.call(4.5,1.8,-3.4),at.call(-3.0,1.5,1.0),folder+"/interior-right.png")
    await shot(camera,at.call(1.4,1.6,-1.0),at.call(0,2.4,1.2),folder+"/ladder.png")
    await shot(camera,at.call(0,5.4,-1.5),at.call(0,3.2,3.5),folder+"/loft.png")
    await shot(camera,at.call(3.5,4.6,1.3),at.call(-2.0,2.0,-3.0),folder+"/from-loft.png")
    await shot(camera,at.call(-2.2,1.6,-1.0),at.call(-5.8,1.4,-.9),folder+"/tools.png")
    # The turned ladder seen from the doorway, and BonBon clinging to it.
    await shot(camera,at.call(.9,1.7,-3.6),at.call(0,2.2,1.9),folder+"/ladder-from-door.png")
    game.player.global_position=at.call(0,1.4,1.4)
    game.player.rotation.y=barn.global_rotation.y+PI
    await shot(camera,at.call(-1.6,2.4,-1.6),at.call(0,2.0,1.6),folder+"/ladder-climb.png")
    await shot(camera,at.call(1.2,4.6,4.0),at.call(0,2.6,1.2),folder+"/ladder-head.png")
    game.player.global_position=at.call(0,-20,0)
    # Paddock: the shelter on four posts with its plank back wall, and the trough on skids.
    var roof: Node3D=game.apartment.get_node("ParkZoo/Shelter roof")
    var yard:=func(x: float,y: float,z: float) -> Vector3: return roof.to_global(Vector3(x,y,z))
    await shot(camera,yard.call(-3,1.2,-9),yard.call(0,-1.4,-1),folder+"/paddock-shelter.png")
    await shot(camera,yard.call(7,2.5,4),yard.call(0,-1.6,-1),folder+"/paddock-side.png")
    await shot(camera,yard.call(0,6,-16),yard.call(0,-2,0),folder+"/paddock-wide.png")
    print("BARN CAPTURE done")
    quit()
