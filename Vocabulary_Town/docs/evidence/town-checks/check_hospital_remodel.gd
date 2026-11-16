extends SceneTree
var game
var hospital: Node3D
var lift
var failures: Array[String] = []
var checks := 0
const ROOF_Y := 16.925
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)
        push_error(message)
func _initialize(): run.call_deferred()
func tick() -> void:
    await physics_frame
    game.player.velocity.x = 0
    game.player.velocity.z = 0
    game.player.velocity.y = -.2 if game.player.is_on_floor() else game.player.velocity.y-22.0/60.0
    game.player.move_and_slide()
func walk_to(p: Vector3) -> void:
    var target := hospital.to_global(p)
    for i in range(500):
        await physics_frame
        var offset: Vector3 = target-game.player.global_position
        offset.y=0
        if offset.length()<.1: return
        var move := offset.normalized()*minf(4,offset.length()*30)
        game.player.velocity.x=move.x
        game.player.velocity.z=move.z
        game.player.velocity.y = -.2 if game.player.is_on_floor() else game.player.velocity.y-22.0/60.0
        game.player.move_and_slide()
    for j in range(game.player.get_slide_collision_count()): print("BLOCKER ",game.player.get_slide_collision(j).get_collider().get_path())
    check(false,"Walk blocked toward "+str(p)+" at "+str(hospital.to_local(game.player.global_position)))
## Elevator-local point in hospital coordinates; the elevator faces the hall since 27 Oct 2026.
func lift_point(local: Vector3) -> Vector3:
    return hospital.to_local(lift.to_global(local))
func ride(destination: int) -> void:
    var key := InputEventKey.new()
    key.physical_keycode = KEY_1+destination
    key.keycode = KEY_1+destination
    key.pressed = true
    Input.parse_input_event(key)
    var reached := false
    for i in range(1000):
        await tick()
        if lift.current_floor==destination and lift.state==lift.State.OPEN:
            reached=true
            break
        if lift.state==lift.State.MOVING:
            check(is_zero_approx(lift.door_fraction),"Doors closed during movement")
    check(reached,"Elevator arrived at "+str(destination+1))
    var p := hospital.to_local(game.player.global_position)
    check(absf(p.y-lift.floor_ys[destination])<.2,"Player carried to stop "+str(destination+1)+" actual="+str(p))
## Hinged door registered by Main from the prefab's door_state; Main's _process is off here.
func set_door(door: Node3D, open: bool) -> void:
    check(game.doors.has(door),"Door registered: "+str(door.name))
    game.doors[door]["open"]=open
    door.rotation.y=float(game.doors[door]["angle"]) if open else 0.0
    await physics_frame
    await physics_frame
func blocked(from: Vector3, to: Vector3) -> bool:
    var q:=PhysicsRayQueryParameters3D.create(hospital.to_global(from),hospital.to_global(to))
    q.exclude=[game.player.get_rid()]
    return not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
func run() -> void:
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    game.interaction.word_studied.disconnect(game._on_word_studied)
    game.hud.hide()
    hospital=game.apartment.get_node("Buildings/Hospital")
    lift=hospital.get_node("Elevator")
    await physics_frame
    await physics_frame
    check(hospital.has_meta("remodeled"),"Remodeled prefab active in Main")
    check(hospital.has_node("HospitalHelipad/Helicopter"),"Existing helicopter retained")
    # 'floor' left the list on 7 Nov 2026: its only hospital node was the rear extension floor,
    # removed by the approved three-floor remodel (Oct 2026); home and school still teach it.
    var required := ['bed rail','blanket','book','chair','computer','crutches','examination bed','hospital bed','iv stand','mattress','medical monitor','pillow','planter','stand','stethoscope','thermometer','treatment table','walker','wheel','wheelchair']
    var keys: Array[String] = []
    for n in hospital.find_children("*","Node3D",true,false):
        if n.has_meta("word_key"):
            var key := str(n.get_meta("word_key"))
            if key not in keys:keys.append(key)
    for key in required:check(key in keys,"Hospital retains word "+key)
    if not "--capture-only" in OS.get_cmdline_user_args():
        game.player.global_position=hospital.to_global(Vector3(0,.1,-13.5))
        game.player.velocity=Vector3.ZERO
        await walk_to(Vector3(0,0,-3.5))
        for floor_index in range(3):
            # Front rooms, back rooms (one room deeper since 27 Oct 2026) and both lounge sides.
            for z in [-8.35,16.05]:
                await walk_to(Vector3(0,0,z))
                for x in [3.5,-3.5]:
                    await walk_to(Vector3(x,0,z))
                    await walk_to(Vector3(0,0,z))
            await walk_to(Vector3(0,0,6))
            # Floor 1's stair-side lounge is the pharmacy (31 Oct 2026), entered by its door.
            for x in ([-4.5] if floor_index==0 else [4.5,-4.5]):
                await walk_to(Vector3(x,0,6))
                await walk_to(Vector3(0,0,6))
            if floor_index==0:
                var door: Node3D=hospital.get_node("Floor1/Pharmacy/PharmacyDoor")
                check(blocked(Vector3(.5,1.2,6),Vector3(3.5,1.2,6)),"Closed pharmacy door blocks the doorway")
                check(blocked(Vector3(.5,1.2,9.5),Vector3(3.5,1.2,9.5)),"Pharmacy shopfront glass is solid")
                await set_door(door,true)
                check(not blocked(Vector3(.5,1.2,6),Vector3(3.5,1.2,6)),"Open pharmacy door clears the doorway")
                for p in [Vector3(3.5,0,6),Vector3(6,0,8.6),Vector3(10.5,0,9.6),Vector3(13.6,0,9.6),Vector3(6,0,8.6),Vector3(3.5,0,6),Vector3(0,0,6)]:
                    await walk_to(p)
                check(blocked(Vector3(5.7,.6,9.2),Vector3(5.7,.6,11.5)),"Pharmacy counter is solid")
                await set_door(door,false)
            else:
                # The glass wall between lounge and annex is gone on floors 2 and 3.
                check(not blocked(Vector3(6,3,8.35),Vector3(12,3,8.35)),"Lounge opens into annex on floor "+str(floor_index+1))
                for p in [Vector3(0,0,6.6),Vector3(12,0,6.6),Vector3(12,0,9),Vector3(12,0,6.6),Vector3(0,0,6.6),Vector3(0,0,6)]:
                    await walk_to(p)
            await walk_to(Vector3(0,0,3.45))
            await walk_to(Vector3(12.5,0,3.45))
            check(absf(hospital.to_local(game.player.global_position).y-floor_index*5.6)<.2,"Annex gallery accessible on floor "+str(floor_index+1))
            await walk_to(Vector3(0,0,3.45))
            await walk_to(Vector3(0,0,-3.4))
            await walk_to(Vector3(3.5,0,-3.15))
            await walk_to(Vector3(3.5,0,.3))
            await walk_to(Vector3(14.7,0,.3))
            var top: float=(floor_index+1)*5.6 if floor_index<2 else ROOF_Y
            check(absf(hospital.to_local(game.player.global_position).y-top)<.2,"Stair ascent "+str(floor_index+2))
            if floor_index<2:
                await walk_to(Vector3(14.7,0,3.45))
                await walk_to(Vector3(0,0,3.45))
                await walk_to(Vector3(0,0,-3.4))
            else:
                # Roof (31 Oct 2026): the stair house door opens onto the annex roof.
                await walk_to(Vector3(14.6,0,1.6))
                var roof_door: Node3D=hospital.get_node("Azotea/RoofDoor")
                check(blocked(Vector3(14.6,ROOF_Y+1.2,1.8),Vector3(14.6,ROOF_Y+1.2,3.8)),"Closed roof door blocks the stair house")
                await set_door(roof_door,true)
                # Out past the rooftop vents and round the rear roof.
                for p in [Vector3(14.6,0,4.2),Vector3(12,0,9),Vector3(-7.6,0,9),Vector3(-7.6,0,15),Vector3(7,0,15),Vector3(12,0,9)]:
                    await walk_to(p)
                    check(absf(hospital.to_local(game.player.global_position).y-ROOF_Y)<.2,"Walkable roof at "+str(p))
                # The rear ramp climbs onto the helipad deck.
                await walk_to(Vector3(2.7,0,8.6))
                await walk_to(Vector3(2.7,0,3.8))
                check(absf(hospital.to_local(game.player.global_position).y-ROOF_Y-.28)<.1,"Rear ramp reaches the helipad deck")
                await walk_to(Vector3(2.7,0,8.6))
                # Parapet stops a walk off the roof edge.
                await walk_to(Vector3(-7.6,0,15))
                game.player.global_position=hospital.to_global(Vector3(-8.4,ROOF_Y+.1,15))
                for i in range(40):
                    await physics_frame
                    game.player.velocity=hospital.global_basis*Vector3(-4,0,0)+Vector3(0,-.2,0)
                    game.player.move_and_slide()
                check(hospital.to_local(game.player.global_position).x>-9.0 and absf(hospital.to_local(game.player.global_position).y-ROOF_Y)<.2,"Parapet keeps the player on the roof")
                for p in [Vector3(-7.6,0,9),Vector3(12,0,9),Vector3(14.6,0,4.2),Vector3(14.6,0,1.6),Vector3(14.7,0,.3),Vector3(3.5,0,.3)]:
                    await walk_to(p)
                check(absf(hospital.to_local(game.player.global_position).y-11.2)<.2,"Stair descent from the roof")
                await set_door(roof_door,false)
                await walk_to(Vector3(3.5,0,-3.15))
                await walk_to(Vector3(0,0,-3.4))
        for floor_index in range(2):
            await walk_to(Vector3(0,0,3.45))
            await walk_to(Vector3(14.7,0,3.45))
            await walk_to(Vector3(14.7,0,.3))
            await walk_to(Vector3(3.5,0,.3))
            check(absf(hospital.to_local(game.player.global_position).y-(1-floor_index)*5.6)<.2,"Stair descent "+str(2-floor_index))
            await walk_to(Vector3(3.5,0,-3.15))
            await walk_to(Vector3(0,0,-3.15))
        await walk_to(Vector3(0,0,-3.4))
        # Stand inside the doorway obstruction zone (local z > -3.5).
        await walk_to(lift_point(Vector3(0,0,-3.4)))
        # Someone in the doorway holds the car open; since 10 Nov 2026 the call is kept (not
        # dropped) and the car leaves DEPART_DELAY s after the doorway clears.
        lift.call_elevator(1)
        for i in range(int((lift.DEPART_DELAY+1.0)*60)):await tick()
        check(lift.state==lift.State.WAITING and is_equal_approx(lift.door_fraction,1.0) and lift.current_floor==0,"Obstructed doorway holds the doors open")
        await walk_to(lift_point(Vector3.ZERO))
        var held := false
        for i in range(900):
            await tick()
            if lift.current_floor==1 and lift.state==lift.State.OPEN:
                held=true
                break
        check(held,"Held call leaves once the doorway is clear")
        var button_camera := Camera3D.new()
        lift.car.add_child(button_camera)
        button_camera.position=Vector3(0,1.7,-1.7)
        button_camera.look_at(lift.car.get_node("Button2").global_position)
        button_camera.current=true
        # The click ray-casts through the interaction controller's camera (12 Nov 2026).
        game.interaction.camera=button_camera
        await process_frame
        var click := InputEventMouseButton.new()
        click.button_index=MOUSE_BUTTON_LEFT
        click.pressed=true
        click.position=button_camera.unproject_position(lift.car.get_node("Button2").global_position)
        Input.parse_input_event(click)
        Input.flush_buffered_events()
        await process_frame
        check(lift.target_floor==2 and lift.state==lift.State.WAITING,"Physical floor-selection button click")
        game.interaction.camera=game.camera
        button_camera.queue_free()
        game.camera.current=true
        # Four stops since 31 Oct 2026: floors 1-3 and the roof (clear of the helipad deck).
        check(lift.floors()==4 and lift.stop_title(3)=="AZOTEA","Elevator serves the roof")
        for destination in [3,2,1,0]:
            await ride(destination)
            await walk_to(lift_point(Vector3(0,0,-3.5)))
            check(absf(hospital.to_local(game.player.global_position).y-lift.floor_ys[destination])<.2,"Exit at stop "+str(destination+1))
            if destination==3:
                # The west ramp leads from the lift onto the helipad deck.
                await walk_to(Vector3(-6,0,0))
                check(absf(hospital.to_local(game.player.global_position).y-ROOF_Y-.28)<.1,"West ramp reaches the helipad deck")
                await walk_to(lift_point(Vector3(0,0,-3.5)))
            await walk_to(lift_point(Vector3(0,0,-3.5)))
            await walk_to(lift_point(Vector3.ZERO))
        # Empty car remote call and closed door at absent landing.
        await walk_to(lift_point(Vector3(0,0,-3.5)))
        await walk_to(Vector3(0,0,-3.5))
        lift.call_elevator(2)
        for i in range(650):await tick()
        check(lift.current_floor==2,"Remote call moves empty cabin")
        await walk_to(lift_point(Vector3(0,0,-3.5)))
        var door_shape: CollisionShape3D=lift.landing_doors[0].get_child(0).get_child(1)
        check(not door_shape.disabled and absf(lift.landing_doors[0].get_child(0).position.x+lift.leaf*.25)<.01 and absf(lift.landing_doors[0].get_child(2).position.x+lift.leaf*.75)<.01,"Absent cabin landing locked by collision (both panels of each side closed)")
        var call_key := InputEventKey.new()
        call_key.physical_keycode=KEY_E
        call_key.keycode=KEY_E
        call_key.pressed=true
        Input.parse_input_event(call_key)
        for i in range(650):await tick()
        check(lift.current_floor==0 and lift.state==lift.State.OPEN,"Hall call retrieves elevator")
        await walk_to(Vector3(0,0,-3.5))
        # The rear wing is gone; the hall now ends at a closed rear wall.
        check(not hospital.has_node("LearningWing"),"Former rear wing removed")
    if "--capture" in OS.get_cmdline_user_args():await capture()
    print("HOSPITAL REMODEL: ",checks," checks; ",failures.size()," failures")
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
func capture() -> void:
    root.size=Vector2i(1440,1100)
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    game.player.hide()
    var camera:=Camera3D.new()
    hospital.add_child(camera)
    camera.current=true
    DirAccess.make_dir_recursive_absolute("res://docs/evidence/hospital-remodel")
    # Inspection cutaways hide upper storeys/roof and high wall meshes, not geometry edits.
    var meshes=hospital.find_children("*","MeshInstance3D",true,false)
    var saved: Dictionary={}
    for m in meshes:saved[m]=m.visible
    var facades: Node3D=game.apartment.get_node("Map facades")
    facades.hide()
    var overlay := CanvasLayer.new()
    root.add_child(overlay)
    var labels := ["Room 1 · Reception","Room 2 · Emergency","Room 3 · Examination","Waiting room"]
    var all_labels := [labels,["Patient room 201","Patient room 202","Intensive care","Operating room"],["Imaging","Laboratory","Physical therapy","Doctors’ office"]]
    for floor_index in range(3):
        # Park the actual cabin at the pictured landing for a readable floor cutaway.
        lift.car.position.y=floor_index*5.6
        lift.current_floor=floor_index
        lift.target_floor=floor_index
        lift.state=lift.State.OPEN
        lift.door_fraction=1.0
        lift.update_doors()
        var cut_walls := Node3D.new()
        hospital.add_child(cut_walls)
        for m in meshes:
            m.visible=saved[m]
            var bounds: AABB=(hospital.global_transform.affine_inverse()*m.global_transform)*m.get_aabb()
            if bounds.position.y>floor_index*5.6+3.9 or bounds.end.y<floor_index*5.6-.25:m.hide()
            if bounds.size.y>3.5:
                m.hide()
                if bounds.position.y>=floor_index*5.6-.1 and bounds.position.y<floor_index*5.6+.1:
                    lift.box(cut_walls,"CutWall",Vector3(bounds.get_center().x,floor_index*5.6+.15,bounds.get_center().z),Vector3(bounds.size.x,.3,bounds.size.z),Color("a8bbb5"),false)
            if "Tread" in str(m.name) or "Nosing" in str(m.name) or "Rail" in str(m.name) or "Guard" in str(m.name) or "HalfLanding" in str(m.name) or "SolidStep" in str(m.name) or "StepEdge" in str(m.name) or "StairPost" in str(m.name) or "StairHandrail" in str(m.name):
                if bounds.position.y>=(floor_index-1)*5.6 and bounds.end.y<=floor_index*5.6+6.8:m.visible=saved[m]
            if lift.car.is_ancestor_of(m) and bounds.position.y>=floor_index*5.6+3.3:m.hide()
        for l in hospital.find_children("*","Label3D",true,false):
            var y: float=hospital.to_local(l.global_position).y
            l.visible=y>floor_index*5.6 and y<floor_index*5.6+5.4
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=47
        camera.position=Vector3(3.5,floor_index*5.6+50,3.85)
        camera.look_at(hospital.to_global(Vector3(3.5,floor_index*5.6,3.85)),Vector3(0,0,1))
        hospital.get_node("HospitalHelipad").hide()
        # English annotations identify rooms in the rendered cutaway; gameplay signs remain Spanish.
        var annotations := [[all_labels[floor_index][0],Vector3(5.5,0,-10.8)],[all_labels[floor_index][1],Vector3(5.5,0,18.5)],[all_labels[floor_index][2],Vector3(-5.5,0,18.5)],["Lounge",Vector3(0,0,8.35)],[all_labels[floor_index][3],Vector3(-5.5,0,-10.8)],["Stairs",Vector3(5.5,0,-3.3)],["Lift lobby",Vector3(-5.5,0,0)],["Elevator",Vector3(-11.6,0,0)],["Pharmacy" if floor_index==0 else "Open gallery",Vector3(12.5,0,7)],["FRONT ENTRANCE" if floor_index==0 else "FRONT",Vector3(0,0,-13.3)]]
        for annotation in annotations:
            var tag := Label.new()
            overlay.add_child(tag)
            tag.text=annotation[0]
            tag.add_theme_font_size_override("font_size",20)
            tag.add_theme_color_override("font_color",Color("163a40"))
            tag.add_theme_color_override("font_outline_color",Color("f5f2e8"))
            tag.add_theme_constant_override("outline_size",5)
            tag.position=camera.unproject_position(hospital.to_global(annotation[1]+Vector3(0,floor_index*5.6,0)))-Vector2(tag.get_minimum_size().x/2,10)
        var heading := Label.new()
        overlay.add_child(heading)
        heading.text="HOSPITAL / FLOOR "+str(floor_index+1)+"     ·     GODOT RENDERED CUTAWAY"
        heading.position=Vector2(35,25)
        heading.add_theme_font_size_override("font_size",26)
        heading.add_theme_color_override("font_color",Color("163a40"))
        # +X is screen-left when looking into this building from its front.
        for i in range(8):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/hospital-remodel/floor"+str(floor_index+1)+".png")
        cut_walls.free()
        for tag in overlay.get_children():tag.free()
    lift.car.position.y=0
    lift.current_floor=0
    lift.target_floor=0
    lift.update_doors()
    overlay.queue_free()
    facades.show()
    hospital.get_node("HospitalHelipad").show()
    for m in meshes:m.visible=saved[m]
    for l in hospital.find_children("*","Label3D",true,false):l.show()
    camera.projection=Camera3D.PROJECTION_PERSPECTIVE
    camera.fov=85
    for view in [["stairs",Vector3(2.5,2,.3),Vector3(11,5,.3)],["elevator",Vector3(-.6,1.8,0),Vector3(-9,1.7,0)],["entrance",Vector3(0,2,-11.7),Vector3(0,2,-2)]]:
        camera.position=view[1]
        camera.look_at(hospital.to_global(view[2]))
        for i in range(8):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/evidence/hospital-remodel/"+view[0]+".png")
