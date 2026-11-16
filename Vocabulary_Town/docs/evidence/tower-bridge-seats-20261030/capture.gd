extends SceneTree
## 30 Oct 2026: tower stair walls / empty level / ladder / hatch, elevator doors, swivel seat, bridge perches.
## godot --path <isolated project> --resolution 1400x900 --script res://docs/evidence/tower-bridge-seats-20261030/capture.gd -- [output_dir]
## Use the README's isolated user directory; the script only reads saves.
func _initialize(): run.call_deferred()
func key(code: int,pressed: bool) -> void:
    var e:=InputEventKey.new()
    e.physical_keycode=code
    e.keycode=code
    e.pressed=pressed
    Input.parse_input_event(e)
func shot(camera: Camera3D,frame: Node3D,spec: Array,out: String) -> void:
    camera.global_position=frame.to_global(spec[1])
    camera.look_at(frame.to_global(spec[2]),Vector3.UP)
    camera.fov=spec[3]
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out+"/"+spec[0]+".png")
func run():
    var out:="res://docs/evidence/tower-bridge-seats-20261030"
    for a in OS.get_cmdline_user_args(): out=a
    DirAccess.make_dir_recursive_absolute(out)
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.interaction.set_physics_process(false)
    game.hud.hide()
    var town: Node3D=game.apartment
    var room: Node3D=town.get_node("Airport/ControlTower/Interior")
    var camera:=Camera3D.new()
    game.add_child(camera)
    camera.current=true
    var player=game.player
    player.global_position=room.to_global(Vector3(0,-50,0))
    player.set_physics_process(false)
    for spec in [
        ["stairs_ground",Vector3(-3.0,1.7,-3.6),Vector3(-1.6,2.6,1.2),75.0],
        ["stairs_level2",Vector3(-.2,7.2,-3.2),Vector3(-1.4,7.6,1.0),75.0],
        ["empty_level",Vector3(3.2,18.2,-3.5),Vector3(-2.0,18.0,2.0),80.0],
        ["empty_level_ladder",Vector3(.5,18.0,-.5),Vector3(-3.8,19.6,-.5),80.0],
        ["hatch_from_above",Vector3(-1.2,23.8,1.6),Vector3(-3.4,22.0,-.5),75.0],
        ["lift_door_tower",Vector3(2.3,1.7,-1.6),Vector3(2.3,1.8,.8),60.0],
    ]: await shot(camera,room,spec,out)
    var hospital_lift: Node3D=town.get_node("Buildings/Hospital/Elevator")
    await shot(camera,hospital_lift,["lift_door_hospital",Vector3(0,1.7,-hospital_lift.hd()-3.0),Vector3(0,1.8,-hospital_lift.hd()),60.0],out)
    # Player on the ladder, mid-climb.
    var ladder: Node3D=room.get_node("Ladder")
    player.set_physics_process(true)
    player.global_position=ladder.to_global(Vector3(0,.05,.5))
    for i in range(10): await physics_frame
    key(KEY_W,true)
    for i in range(70): await physics_frame
    key(KEY_W,false)
    await shot(camera,room,["ladder_climb",Vector3(2.2,room.to_local(player.global_position).y+1.2,-2.0),room.to_local(player.global_position)+Vector3(0,.8,0),60.0],out)
    # Seated, swivelled.
    var seat: Dictionary={}
    for s in game.seating.seats:
        if s.node.get_meta("swivel",false) and room.is_ancestor_of(s.node) and room.to_local(s.node.global_position).y>21.0 and room.to_local(s.node.global_position).z<-3.0: seat=s; break
    game.seating.refresh(seat)
    player.global_position=seat.point
    player.seated=true
    player.sit_transition=false
    player.sit_blend=1.0
    game.seating.current=seat
    key(KEY_A,true)
    for i in range(45): await physics_frame
    key(KEY_A,false)
    for i in range(10): await physics_frame
    await shot(camera,room,["swivel_seat",room.to_local(player.global_position)+Vector3(1.8,1.1,3.2),room.to_local(player.global_position)+Vector3(0,.5,0),55.0],out)
    player.seated=false
    # Bridge perches: player on a handrail, a chain and a lamp globe.
    var garden: Node3D=town.get_node("PublicGarden")
    var rails:=garden.find_children("Bridge handrail walk*","Node3D",false,false)
    var chains:=garden.find_children("Bridge suspension chain walk*","Node3D",false,false)
    var pads:=garden.find_children("Bridge lamp globe pad*","Node3D",false,false)
    for spec in [["bridge_rail",rails[rails.size()/2]],["bridge_chain",chains[chains.size()/3]],["bridge_lamp",pads[0]]]:
        var target: Node3D=spec[1]
        player.global_position=target.global_position+Vector3(0,.8,0)
        player.velocity=Vector3.ZERO
        for i in range(60): await physics_frame
        var p: Vector3=player.global_position
        camera.global_position=p+Vector3(4.5,1.6,-4.5)
        camera.look_at(p+Vector3(0,.8,0),Vector3.UP)
        camera.fov=55
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out+"/"+spec[0]+".png")
    print("TOWER CAPTURE done")
    quit()
